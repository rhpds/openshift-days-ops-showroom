#!/bin/bash
#
# Enable file activity monitoring (FAM) on RHACS SecuredCluster and submit FAM policies via API.
#
# Requires: ROX_API_TOKEN, oc logged in, jq
# Optional: ROX_CENTRAL_ADDRESS (auto-detected from central route if unset)
#           RHACS_NAMESPACE (default: stackrox)
#           FAM_SKIP_RUNNER=1 — skip applying the exec runner Deployment

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
FAM_POLICIES=(
    "${SCRIPT_DIR}/fam-basic-node-monitoring.json"
    "${SCRIPT_DIR}/fam-basic-deploy-monitoring.json"
)
FAM_RUNNER_MANIFEST="${SCRIPT_DIR}/fam-cron-exec-target.yaml"
RHACS_NAMESPACE="${RHACS_NAMESPACE:-stackrox}"
FAM_EXEC_NAMESPACE="${FAM_EXEC_NAMESPACE:-payments}"
FAM_EXEC_WORKLOAD="${FAM_EXEC_WORKLOAD:-deployment/mastercard-processor}"

get_central_url() {
    if [ -n "${ROX_CENTRAL_ADDRESS:-}" ]; then
        echo "${ROX_CENTRAL_ADDRESS}"
        return 0
    fi
    local url
    url=$(oc get route central -n "${RHACS_NAMESPACE}" -o jsonpath='https://{.spec.host}' 2>/dev/null || echo "")
    [ -n "${url}" ] && echo "${url}"
}

submit_policy() {
    local policy_file="$1"
    local policy_name policy_json existing_id response http_code body

    policy_name=$(jq -r '.policies[0].name' "${policy_file}")
    policy_json=$(jq '.policies[0] | del(.id, .lastUpdated)' "${policy_file}")

    existing_id=$(curl -k -s -H "Authorization: Bearer ${ROX_API_TOKEN}" \
        "${API_BASE}/policies" | jq -r --arg name "${policy_name}" \
        '.policies[] | select(.name==$name) | .id' 2>/dev/null || echo "")

    if [ -n "${existing_id}" ]; then
        print_info "Updating policy '${policy_name}' (id: ${existing_id})..."
        response=$(curl -k -s -w "\n%{http_code}" -X PUT \
            -H "Authorization: Bearer ${ROX_API_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "$(echo "${policy_json}" | jq --arg id "${existing_id}" '. + {id: $id}')" \
            "${API_BASE}/policies/${existing_id}")
    else
        print_info "Creating policy '${policy_name}'..."
        response=$(curl -k -s -w "\n%{http_code}" -X POST \
            -H "Authorization: Bearer ${ROX_API_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "${policy_json}" \
            "${API_BASE}/policies")
    fi

    http_code=$(echo "${response}" | tail -n1)
    body=$(echo "${response}" | sed '$d')
    if [ "${http_code}" != "200" ] && [ "${http_code}" != "201" ]; then
        print_error "Failed to submit policy '${policy_name}' (HTTP ${http_code})"
        print_error "Response: ${body:0:300}"
        exit 1
    fi
    print_info "✓ ${policy_name} submitted"
}

# Prerequisites
if ! oc whoami &>/dev/null; then
    print_error "Not connected to OpenShift. Run: oc login"
    exit 1
fi

if [ -z "${ROX_API_TOKEN:-}" ]; then
    print_error "ROX_API_TOKEN is required. Set it: export ROX_API_TOKEN='your-token'"
    exit 1
fi

if ! command -v jq &>/dev/null; then
    print_error "jq is required. Install: dnf install jq / brew install jq"
    exit 1
fi

for policy_file in "${FAM_POLICIES[@]}"; do
    if [ ! -f "${policy_file}" ]; then
        print_error "FAM policy file not found: ${policy_file}"
        exit 1
    fi
done

CENTRAL_URL=$(get_central_url) || {
    print_error "Could not determine ROX_CENTRAL_ADDRESS. Set it or ensure the RHACS central route exists."
    exit 1
}
API_BASE="${CENTRAL_URL}/v1"

# Step 1: Enable FAM on SecuredCluster
print_step "1. Enabling file activity monitoring on SecuredCluster..."

SC_NAME=$(oc get securedcluster -n "${RHACS_NAMESPACE}" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -z "${SC_NAME}" ]; then
    print_error "No SecuredCluster found in ${RHACS_NAMESPACE}"
    exit 1
fi

oc patch securedcluster "${SC_NAME}" -n "${RHACS_NAMESPACE}" --type=merge \
    -p '{"spec":{"perNode":{"fileActivityMonitoring":{"mode":"Enabled"}}}}'

FAM_MODE=$(oc get securedcluster "${SC_NAME}" -n "${RHACS_NAMESPACE}" \
    -o jsonpath='{.spec.perNode.fileActivityMonitoring.mode}' 2>/dev/null || echo "")
if [ "${FAM_MODE}" != "Enabled" ]; then
    print_error "Patch verification failed: fileActivityMonitoring.mode is '${FAM_MODE}', expected 'Enabled'"
    exit 1
fi
print_info "✓ File activity monitoring enabled"
echo ""

# Step 2: Submit FAM policies
print_step "2. Submitting FAM policies to RHACS..."
for policy_file in "${FAM_POLICIES[@]}"; do
    submit_policy "${policy_file}"
done
echo ""

# Step 3: Apply exec runner (optional; requires target namespace)
print_step "3. Applying FAM exec runner Deployment..."

if [ "${FAM_SKIP_RUNNER:-0}" = "1" ]; then
    print_info "Skipping (FAM_SKIP_RUNNER=1)"
elif [ ! -f "${FAM_RUNNER_MANIFEST}" ]; then
    print_warn "Runner manifest not found: ${FAM_RUNNER_MANIFEST}"
elif ! oc get namespace "${FAM_EXEC_NAMESPACE}" &>/dev/null; then
    print_warn "Namespace '${FAM_EXEC_NAMESPACE}' not found — skipping exec runner."
    print_warn "Deploy your apps first, then re-run: FAM_SKIP_RUNNER=0 ./install.sh"
else
    oc delete cronjob rhacs-fam-exec-trigger -n "${FAM_EXEC_NAMESPACE}" --ignore-not-found &>/dev/null || true
    sed \
        -e "s/namespace: payments/namespace: ${FAM_EXEC_NAMESPACE}/g" \
        -e "s#value: \"deployment/mastercard-processor\"#value: \"${FAM_EXEC_WORKLOAD}\"#g" \
        -e "s#value: \"payments\"#value: \"${FAM_EXEC_NAMESPACE}\"#g" \
        "${FAM_RUNNER_MANIFEST}" | oc apply -f -
    print_info "✓ Deployment rhacs-fam-exec-runner applied in ${FAM_EXEC_NAMESPACE}"
fi
echo ""

# Next steps
WORKER_NODE=$(oc get nodes -l node-role.kubernetes.io/worker \
    -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || \
    oc get nodes -o jsonpath='{.items[1].metadata.name}' 2>/dev/null || echo "<worker-node>")

print_step "FAM setup complete"
echo ""
print_info "View violations in RHACS: Violations → filter by fam-basic-deploy-monitoring or fam-basic-node-monitoring"
print_info "To trigger node-level FAM manually:"
echo ""
echo "  oc debug node/${WORKER_NODE}"
echo "  chroot /host"
echo "  touch /etc/passwd"
echo ""
