#!/usr/bin/env bash
# Install Zero Trust Workload Identity Manager from the OpenShift OperatorHub catalog
# (Red Hat Operators — channel stable-v1, version 1.0.1).
# Same outcome as installing from the console: Ecosystem → Operators → OperatorHub.
#
# Upstream: https://github.com/openshift/zero-trust-workload-identity-manager

set -euo pipefail

NAMESPACE="${ZTWIM_NAMESPACE:-zero-trust-workload-identity-manager}"
CHANNEL="${ZTWIM_CHANNEL:-stable-v1}"
PACKAGE="${ZTWIM_PACKAGE:-zero-trust-workload-identity-manager}"
SOURCE="${ZTWIM_CATALOG_SOURCE:-redhat-operators}"
SOURCE_NS="${ZTWIM_CATALOG_NAMESPACE:-openshift-marketplace}"
APPROVAL="${ZTWIM_INSTALL_PLAN_APPROVAL:-Automatic}"
APPLY_SAMPLES="${ZTWIM_APPLY_SAMPLES:-false}"
WORKDIR="${ZTWIM_WORKDIR:-/tmp/zero-trust-workload-identity-manager}"
REPO_URL="${ZTWIM_REPO_URL:-https://github.com/openshift/zero-trust-workload-identity-manager.git}"
REF="${ZTWIM_REF:-main}"

log() { echo "[ZTWIM] $*"; }

csv_succeeded() {
  local csv
  csv="$(oc get csv -n "${NAMESPACE}" \
    -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null \
    | grep -E 'zero-trust-workload-identity-manager|zerotrust' | head -1)"
  [[ -n "${csv}" ]] || return 1
  [[ "$(oc get csv "${csv}" -n "${NAMESPACE}" -o jsonpath='{.status.phase}')" == "Succeeded" ]]
}

apply_samples() {
  [[ "${APPLY_SAMPLES}" == "true" ]] || return 0
  if [[ ! -d "${WORKDIR}/config/samples" ]]; then
    log "Cloning samples from ${REPO_URL}..."
    git clone --depth 1 --branch "${REF}" "${REPO_URL}" "${WORKDIR}" 2>/dev/null \
      || git clone --depth 1 "${REPO_URL}" "${WORKDIR}"
  fi
  log "Applying sample SPIFFE/SPIRE CRs..."
  oc apply -k "${WORKDIR}/config/samples/"
}

if csv_succeeded; then
  log "Operator already installed (CSV Succeeded)."
  apply_samples
  oc get csv,pods -n "${NAMESPACE}"
  exit 0
fi

log "Creating namespace ${NAMESPACE} (if needed)..."
oc create namespace "${NAMESPACE}" --dry-run=client -o yaml | oc apply -f -

log "Subscribing to ${PACKAGE} (${CHANNEL}) from ${SOURCE}..."
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: zero-trust-workload-identity-manager
  namespace: ${NAMESPACE}
spec: {}
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ${PACKAGE}
  namespace: ${NAMESPACE}
spec:
  channel: ${CHANNEL}
  installPlanApproval: ${APPROVAL}
  name: ${PACKAGE}
  source: ${SOURCE}
  sourceNamespace: ${SOURCE_NS}
EOF

log "Waiting for operator CSV to reach Succeeded (up to 15 minutes)..."
elapsed=0
while [[ "${elapsed}" -lt 900 ]]; do
  if csv_succeeded; then
    log "Operator installed successfully."
    apply_samples
    oc get csv,pods -n "${NAMESPACE}"
    exit 0
  fi
  sleep 15
  elapsed=$((elapsed + 15))
done

echo "[ZTWIM] ERROR: Timed out. Check: oc get sub,csv,installplan -n ${NAMESPACE}" >&2
exit 1
