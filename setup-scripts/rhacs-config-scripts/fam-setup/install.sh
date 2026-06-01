#!/bin/bash

# Script: install.sh (fam-setup)
# Description: Enable file activity monitoring on SecuredCluster, submit FAM policies to ACS via API,
#              apply fam-cron-exec-target.yaml (Deployment with a sleep loop: oc exec → touch /etc/passwd
#              on an interval), and optionally run a one-shot oc exec for an immediate demo.
# Requires: ROX_CENTRAL_ADDRESS (or auto-detect), ROX_API_TOKEN, oc logged in, jq
#
# Optional env:
#   FAM_SKIP_CRONJOB=1        — do not apply the exec CronJob manifest
#   FAM_SKIP_WORKLOAD_EXEC=1  — do not run one-shot oc exec into the demo workload
#   FAM_SKIP_INITIAL_ROLLOUT_WAIT=1 — do not wait for rhacs-fam-exec-runner Deployment after apply
#   FAM_LOOP_SLEEP_SEC        — seconds between touch attempts in the runner pod (default 600)
#   FAM_SKIP_VIOLATION_WAIT=1 — do not poll RHACS for a deploy FAM violation (groups API + fallbacks)
#   FAM_REQUIRE_VIOLATION=1   — exit non-zero if no alert for the deploy policy before wait timeout
#   FAM_POST_POLICY_SLEEP_SEC — sleep after policies before triggers (default 15; sensor/policy propagation)
#   FAM_VIOLATION_WAIT_SEC    — max time to poll APIs (default 420)
#   FAM_VIOLATION_POLL_SEC    — interval between polls (default 15)
#   FAM_DEPLOY_POLICY_NAME    — policy to check via API (default fam-basic-deploy-monitoring)
#   FAM_INITIAL_ROLLOUT_TIMEOUT_SEC — oc rollout status for rhacs-fam-exec-runner (default 180)
#   FAM_EXEC_NAMESPACE        — default payments (also rewrites the runner manifest on apply)
#   FAM_EXEC_WORKLOAD         — default deployment/mastercard-processor
#   FAM_EXEC_CONTAINER        — optional -c name for multi-container pods
#   FAM_LOOP_SLEEP_SEC        — optional; sets Deployment env (default in YAML: 600)

set -euo pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
print_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
print_step() { echo -e "${BLUE}[STEP]${NC} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_RHACS_DEMO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck disable=SC1090
source "${_RHACS_DEMO_ROOT}/setup-rerun-hint.sh"
setup_rerun_register "${BASH_SOURCE[0]}" "$@"
FAM_POLICIES=(
    "${SCRIPT_DIR}/fam-basic-node-monitoring.json"
    "${SCRIPT_DIR}/fam-basic-deploy-monitoring.json"
)
FAM_CRON_MANIFEST="${SCRIPT_DIR}/fam-cron-exec-target.yaml"
RHACS_NAMESPACE="${RHACS_NAMESPACE:-stackrox}"
FAM_EXEC_NAMESPACE="${FAM_EXEC_NAMESPACE:-payments}"
FAM_EXEC_WORKLOAD="${FAM_EXEC_WORKLOAD:-deployment/mastercard-processor}"
FAM_EXEC_CONTAINER="${FAM_EXEC_CONTAINER:-}"
FAM_DEPLOY_POLICY_NAME="${FAM_DEPLOY_POLICY_NAME:-fam-basic-deploy-monitoring}"

# Get Central URL
get_central_url() {
    if [ -n "${ROX_CENTRAL_ADDRESS:-}" ]; then
        echo "${ROX_CENTRAL_ADDRESS}"
        return 0
    fi
    local url
    url=$(oc get route central -n "${RHACS_NAMESPACE}" -o jsonpath='https://{.spec.host}' 2>/dev/null || echo "")
    if [ -n "${url}" ]; then
        echo "${url}"
        return 0
    fi
    return 1
}

# Check prerequisites
if ! oc whoami &>/dev/null; then
    print_error "Not connected to OpenShift cluster. Run: oc login"
    setup_rerun_hint_print
    exit 1
fi

for policy_file in "${FAM_POLICIES[@]}"; do
    if [ ! -f "${policy_file}" ]; then
        print_error "FAM policy file not found: ${policy_file}"
        setup_rerun_hint_print
        exit 1
    fi
done

if [ ! -f "${FAM_CRON_MANIFEST}" ]; then
    print_error "FAM CronJob manifest not found: ${FAM_CRON_MANIFEST}"
    setup_rerun_hint_print
    exit 1
fi

if [ -z "${ROX_API_TOKEN:-}" ]; then
    print_error "ROX_API_TOKEN is required. Set it: export ROX_API_TOKEN='your-token'"
    setup_rerun_hint_print
    exit 1
fi

if ! command -v jq &>/dev/null; then
    print_error "jq is required. Install: dnf install jq / brew install jq"
    setup_rerun_hint_print
    exit 1
fi

CENTRAL_URL=$(get_central_url) || {
    print_error "Could not determine ROX_CENTRAL_ADDRESS. Set it or ensure RHACS route exists."
    setup_rerun_hint_print
    exit 1
}

API_BASE="${CENTRAL_URL}/v1"

# Violations are alerts. Check grouped counts via:
#   GET ${CENTRAL_URL}/v1/alerts/summary/groups?query=Policy:"<policy-name>"
# Example host (replace with your route / ROX_CENTRAL_ADDRESS):
#   https://central-stackrox.apps.cluster-7drtp.dynamic.redhatworkshops.io/v1/alerts/summary/groups?query=Policy:%22fam-basic-deploy-monitoring%22
# Response: { "alertsByPolicies": [ { "policy": { "name": "..." }, "numAlerts": "..." } ] }

# Fetch GET /v1/alerts/summary/groups; optional second arg "noquery" skips Policy filter (retry path).
_alerts_summary_groups_body() {
    local policy="$1"
    local mode="${2:-query}"
    local response http_code body
    if [ "${mode}" = "query" ]; then
        local search_q="Policy:\"${policy}\""
        response=$(curl -k -s -w "\n%{http_code}" -G "${API_BASE}/alerts/summary/groups" \
            -H "Authorization: Bearer ${ROX_API_TOKEN}" \
            --data-urlencode "query=${search_q}" 2>/dev/null) || return 1
    else
        response=$(curl -k -s -w "\n%{http_code}" -G "${API_BASE}/alerts/summary/groups" \
            -H "Authorization: Bearer ${ROX_API_TOKEN}" 2>/dev/null) || return 1
    fi
    http_code=$(echo "${response}" | tail -n1)
    body=$(echo "${response}" | sed '$d')
    if [ "${http_code}" != "200" ]; then
        return 1
    fi
    printf '%s' "${body}"
}

# Prefer GET /v1/alerts/summary/groups with Policy query; then same URL without query; then alertscount; then list alerts.
alert_count_from_groups() {
    local policy="$1"
    local body=""
    body=$(_alerts_summary_groups_body "${policy}" "query" 2>/dev/null) || body=""
    if [ -z "${body}" ]; then
        body=$(_alerts_summary_groups_body "${policy}" "noquery" 2>/dev/null) || body=""
    fi
    if [ -z "${body}" ]; then
        return 1
    fi
    echo "${body}" | jq -r --arg p "${policy}" '
      ((.alertsByPolicies // .alerts_by_policies // [])
        | map(select(.policy.name == $p))
        | .[0]
        | (.numAlerts // .num_alerts)
      )
      // 0
      | if type == "string" then tonumber else . end
    ' 2>/dev/null || echo "0"
}

alert_count_for_policy() {
    local policy="$1"
    local query="Policy:\"${policy}\""
    local response http_code body
    response=$(curl -k -s -w "\n%{http_code}" -G "${API_BASE}/alertscount" \
        -H "Authorization: Bearer ${ROX_API_TOKEN}" \
        --data-urlencode "query=${query}" 2>/dev/null) || return 1
    http_code=$(echo "${response}" | tail -n1)
    body=$(echo "${response}" | sed '$d')
    if [ "${http_code}" != "200" ]; then
        return 1
    fi
    echo "${body}" | jq -r '.count // 0' 2>/dev/null || echo "0"
}

# Fallback: list alerts with Policy search query + pagination cap.
alert_count_fallback_list() {
    local policy="$1"
    local search_q="Policy:\"${policy}\""
    local response http_code body
    response=$(curl -k -s -w "\n%{http_code}" -G "${API_BASE}/alerts" \
        -H "Authorization: Bearer ${ROX_API_TOKEN}" \
        --data-urlencode "query=${search_q}" \
        --data-urlencode "pagination.limit=100" 2>/dev/null) || return 1
    http_code=$(echo "${response}" | tail -n1)
    body=$(echo "${response}" | sed '$d')
    if [ "${http_code}" != "200" ]; then
        return 1
    fi
    echo "${body}" | jq -r --arg p "${policy}" '[.alerts[]? | select(.policy.name == $p)] | length' 2>/dev/null || echo "0"
}

fam_deploy_violation_count() {
    local policy="$1"
    local c
    c=$(alert_count_from_groups "${policy}" 2>/dev/null | tr -d '\n\r ') || c=""
    if [ -z "${c}" ] || ! [[ "${c}" =~ ^[0-9]+$ ]]; then
        c=$(alert_count_for_policy "${policy}" 2>/dev/null | tr -d '\n\r ') || c=""
    fi
    if [ -z "${c}" ] || ! [[ "${c}" =~ ^[0-9]+$ ]]; then
        c=$(alert_count_fallback_list "${policy}" 2>/dev/null | tr -d '\n\r ') || c="0"
    fi
    echo "${c:-0}"
}

#================================================================
# Step 1: Enable file activity monitoring on SecuredCluster
#================================================================
print_step "1. Enabling file activity monitoring on SecuredCluster..."

SC_NAME=$(oc get securedcluster -n "${RHACS_NAMESPACE}" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -z "${SC_NAME}" ]; then
    print_error "No SecuredCluster found in ${RHACS_NAMESPACE}"
    setup_rerun_hint_print
    exit 1
fi

print_info "Patching SecuredCluster ${SC_NAME}..."
if ! oc patch securedcluster "${SC_NAME}" \
    -n "${RHACS_NAMESPACE}" \
    --type=merge \
    -p '{"spec":{"perNode":{"fileActivityMonitoring":{"mode":"Enabled"}}}}' 2>/dev/null; then
    print_error "Failed to patch SecuredCluster"
    setup_rerun_hint_print
    exit 1
fi

# Verify patch was applied
FAM_MODE=$(oc get securedcluster "${SC_NAME}" -n "${RHACS_NAMESPACE}" -o jsonpath='{.spec.perNode.fileActivityMonitoring.mode}' 2>/dev/null || echo "")
if [ "${FAM_MODE}" != "Enabled" ]; then
    print_error "Patch verification failed: fileActivityMonitoring.mode is '${FAM_MODE}', expected 'Enabled'"
    setup_rerun_hint_print
    exit 1
fi
print_info "✓ File activity monitoring enabled (verified)"
echo ""

#================================================================
# Step 2: Submit FAM policies to ACS via API
#================================================================
print_step "2. Submitting file activity monitoring policies to ACS via API..."

for policy_file in "${FAM_POLICIES[@]}"; do
    policy_name=$(jq -r '.policies[0].name' "${policy_file}")
    POLICY_JSON=$(jq '.policies[0] | del(.id, .lastUpdated)' "${policy_file}")

    existing_id=$(curl -k -s -H "Authorization: Bearer ${ROX_API_TOKEN}" "${API_BASE}/policies" | jq -r --arg name "${policy_name}" '.policies[] | select(.name==$name) | .id' 2>/dev/null || echo "")

    if [ -n "${existing_id}" ]; then
        print_info "Policy '${policy_name}' already exists (id: ${existing_id}), updating..."
        response=$(curl -k -s -w "\n%{http_code}" -X PUT \
            -H "Authorization: Bearer ${ROX_API_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "$(echo "${POLICY_JSON}" | jq --arg id "${existing_id}" '. + {id: $id}')" \
            "${API_BASE}/policies/${existing_id}" 2>&1)
    else
        print_info "Creating policy '${policy_name}'..."
        response=$(curl -k -s -w "\n%{http_code}" -X POST \
            -H "Authorization: Bearer ${ROX_API_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "${POLICY_JSON}" \
            "${API_BASE}/policies" 2>&1)
    fi

    http_code=$(echo "${response}" | tail -n1)
    body=$(echo "${response}" | sed '$d')

    if [ "${http_code}" != "200" ] && [ "${http_code}" != "201" ]; then
        print_error "Failed to submit policy '${policy_name}' (HTTP ${http_code})"
        print_error "Response: ${body:0:300}"
        setup_rerun_hint_print
        exit 1
    fi
    print_info "✓ ${policy_name} submitted"
done

if [ "${FAM_SKIP_POST_POLICY_SLEEP:-0}" != "1" ]; then
    _sleep="${FAM_POST_POLICY_SLEEP_SEC:-15}"
    print_info "Waiting ${_sleep}s for policy/sensor propagation before FAM triggers..."
    sleep "${_sleep}"
fi
echo ""

#================================================================
# Step 3: Deployment — loop: oc exec into target workload → touch /etc/passwd, then sleep
#================================================================
print_step "3. Applying FAM exec runner Deployment (${FAM_CRON_MANIFEST##*/})..."

if [ "${FAM_SKIP_CRONJOB:-0}" = "1" ]; then
    print_info "Skipping (FAM_SKIP_CRONJOB=1)"
else
    # Remove legacy CronJob from older installs so only the Deployment runs.
    oc delete cronjob rhacs-fam-exec-trigger -n "${FAM_EXEC_NAMESPACE}" --ignore-not-found &>/dev/null || true

    # Rewrite placeholders in the checked-in manifest to match FAM_EXEC_* (defaults: payments / mastercard-processor)
    if ! sed \
        -e "s/namespace: payments/namespace: ${FAM_EXEC_NAMESPACE}/g" \
        -e "s#value: \"deployment/mastercard-processor\"#value: \"${FAM_EXEC_WORKLOAD}\"#g" \
        -e "s#value: \"payments\"#value: \"${FAM_EXEC_NAMESPACE}\"#g" \
        "${FAM_CRON_MANIFEST}" | oc apply -f -; then
        print_error "Failed to apply FAM exec runner (is namespace ${FAM_EXEC_NAMESPACE} present? image pull ok?)"
        setup_rerun_hint_print
        exit 1
    fi
    if [ -n "${FAM_EXEC_CONTAINER}" ]; then
        if oc set env "deployment/rhacs-fam-exec-runner" -n "${FAM_EXEC_NAMESPACE}" \
            "TARGET_CONTAINER=${FAM_EXEC_CONTAINER}" --overwrite &>/dev/null; then
            print_info "✓ Deployment env TARGET_CONTAINER=${FAM_EXEC_CONTAINER}"
        else
            print_warn "Could not patch Deployment TARGET_CONTAINER — set manually if needed"
        fi
    fi
    if [ -n "${FAM_LOOP_SLEEP_SEC:-}" ]; then
        if oc set env "deployment/rhacs-fam-exec-runner" -n "${FAM_EXEC_NAMESPACE}" \
            "FAM_LOOP_SLEEP_SEC=${FAM_LOOP_SLEEP_SEC}" --overwrite &>/dev/null; then
            print_info "✓ Deployment env FAM_LOOP_SLEEP_SEC=${FAM_LOOP_SLEEP_SEC}"
        fi
    fi
    print_info "✓ Deployment rhacs-fam-exec-runner in ${FAM_EXEC_NAMESPACE} (loop → oc exec ${FAM_EXEC_WORKLOAD} -- touch /etc/passwd; sleep FAM_LOOP_SLEEP_SEC)"

    if [ "${FAM_SKIP_INITIAL_ROLLOUT_WAIT:-0}" != "1" ]; then
        _ijt="${FAM_INITIAL_ROLLOUT_TIMEOUT_SEC:-180}"
        print_info "Waiting for rollout (timeout ${_ijt}s)..."
        if oc rollout status "deployment/rhacs-fam-exec-runner" -n "${FAM_EXEC_NAMESPACE}" --timeout="${_ijt}s" &>/dev/null; then
            print_info "✓ rhacs-fam-exec-runner rollout complete"
        else
            print_warn "Deployment rhacs-fam-exec-runner not ready within ${_ijt}s — check: oc describe deployment/rhacs-fam-exec-runner -n ${FAM_EXEC_NAMESPACE}; oc logs -n ${FAM_EXEC_NAMESPACE} -l app.kubernetes.io/name=rhacs-fam-exec-runner --tail=50"
        fi
    fi
fi
echo ""

#================================================================
# Step 4: One-shot oc exec — touch /etc/passwd inside target workload (deploy FAM demo)
#================================================================
print_step "4. FAM demo workload: oc exec → touch /etc/passwd (fam-basic-deploy-monitoring)..."

if [ "${FAM_SKIP_WORKLOAD_EXEC:-0}" = "1" ]; then
    print_info "Skipping (FAM_SKIP_WORKLOAD_EXEC=1)"
else
    if ! oc get "${FAM_EXEC_WORKLOAD}" -n "${FAM_EXEC_NAMESPACE}" &>/dev/null; then
        print_warn "Resource not found: ${FAM_EXEC_WORKLOAD} in ${FAM_EXEC_NAMESPACE} — skipping oc exec"
        print_warn "Set FAM_EXEC_NAMESPACE / FAM_EXEC_WORKLOAD or deploy your app first."
    else
        print_info "Running oc exec into ${FAM_EXEC_WORKLOAD} (ns ${FAM_EXEC_NAMESPACE}) ..."
        if [ -n "${FAM_EXEC_CONTAINER}" ]; then
            oc_cmd=(oc exec -n "${FAM_EXEC_NAMESPACE}" "${FAM_EXEC_WORKLOAD}" -c "${FAM_EXEC_CONTAINER}" -- touch /etc/passwd)
        else
            oc_cmd=(oc exec -n "${FAM_EXEC_NAMESPACE}" "${FAM_EXEC_WORKLOAD}" -- touch /etc/passwd)
        fi
        if "${oc_cmd[@]}"; then
            print_info "✓ touch completed inside workload (check RHACS: fam-basic-deploy-monitoring)"
        else
            print_warn "oc exec failed (permissions, read-only FS, or default container) — run manually or set FAM_EXEC_CONTAINER"
        fi
    fi
fi
echo ""

#================================================================
# Step 5: Verify deploy FAM violation via API (GET /v1/alerts/summary/groups → alertsByPolicies / numAlerts; fallbacks: alertscount, list alerts)
#================================================================
print_step "5. Verifying policy violation (RHACS API: alerts/summary/groups for ${FAM_DEPLOY_POLICY_NAME})..."

if [ "${FAM_SKIP_VIOLATION_WAIT:-0}" = "1" ]; then
    print_info "Skipping (FAM_SKIP_VIOLATION_WAIT=1)"
else
    _deadline="${FAM_VIOLATION_WAIT_SEC:-420}"
    _every="${FAM_VIOLATION_POLL_SEC:-15}"
    _start=$(date +%s)
    _seen=0
    while true; do
        _count=$(fam_deploy_violation_count "${FAM_DEPLOY_POLICY_NAME}")
        _count=${_count:-0}
        if [ "${_count}" -ge 1 ] 2>/dev/null; then
            print_info "✓ At least one active alert/violation for policy '${FAM_DEPLOY_POLICY_NAME}' (numAlerts=${_count})"
            print_info "  API: GET ${CENTRAL_URL}/v1/alerts/summary/groups?query=Policy:%22${FAM_DEPLOY_POLICY_NAME}%22 → check alertsByPolicies[].numAlerts"
            _seen=1
            break
        fi
        _now=$(date +%s)
        if [ $((_now - _start)) -ge "${_deadline}" ]; then
            break
        fi
        print_info "  No alert yet for '${FAM_DEPLOY_POLICY_NAME}' (count=${_count:-0}); polling every ${_every}s (max ${_deadline}s total)..."
        sleep "${_every}"
    done
    if [ "${_seen}" != "1" ]; then
        print_warn "Timed out waiting for violation (policy '${FAM_DEPLOY_POLICY_NAME}'). FAM can lag after first exec — check RHACS Violations UI, or:"
        print_warn "  curl -k -G \"${CENTRAL_URL}/v1/alerts/summary/groups\" -H \"Authorization: Bearer \${ROX_API_TOKEN}\" --data-urlencode 'query=Policy:\"${FAM_DEPLOY_POLICY_NAME}\"' | jq '.alertsByPolicies[] | select(.policy.name==\"${FAM_DEPLOY_POLICY_NAME}\")'"
        if [ "${FAM_REQUIRE_VIOLATION:-0}" = "1" ]; then
            print_error "FAM_REQUIRE_VIOLATION=1 but no matching alert was observed."
            setup_rerun_hint_print
            exit 1
        fi
    fi
fi
echo ""

#================================================================
# Next steps: Trigger FAM violations (run manually after install)
#================================================================
WORKER_NODE=$(oc get nodes -l node-role.kubernetes.io/worker -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || \
    oc get nodes -o jsonpath='{.items[1].metadata.name}' 2>/dev/null || echo "worker-0")

print_step "File activity monitoring (FAM) setup complete"
echo ""
print_info "Deployment rhacs-fam-exec-runner (unless skipped) loops: oc exec into ${FAM_EXEC_WORKLOAD} (${FAM_EXEC_NAMESPACE}), then sleeps FAM_LOOP_SLEEP_SEC (default 600s)."
print_info "Step 4 runs one immediate oc exec when that workload exists (override with FAM_EXEC_* env)."
print_info "Step 5 polls GET ${CENTRAL_URL}/v1/alerts/summary/groups?query=Policy:%22${FAM_DEPLOY_POLICY_NAME}%22 (alertsByPolicies / numAlerts), then alertscount / alerts if needed."
print_info "To trigger node-level FAM manually, run these commands:"
echo ""
echo "  1. Debug a worker node (detected: ${WORKER_NODE}):"
echo "       oc debug node/${WORKER_NODE}"
echo ""
echo "  2. In the debug shell, chroot to the host:"
echo "       chroot /host"
echo ""
echo "  3. Trigger a monitored path change:"
echo "       touch /etc/passwd"
echo ""
echo "  4. RHACS UI: Violations → filter by policy fam-basic-node-monitoring"
echo ""
echo "  5. Exit: run exit twice (leave chroot, then leave the debug pod)"
echo ""
