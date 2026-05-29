#!/usr/bin/env bash
# Teardown ZTWIM workshop resources aligned with Roadshow-ZTWIM lab cleanup.
# Set ZTWIM_FULL_UNINSTALL=true to also remove SPIRE CRs and the operator.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPERATOR_NAMESPACE="${OPERATOR_NAMESPACE:-openshift-zero-trust-workload-identity-manager}"
FULL_UNINSTALL="${ZTWIM_FULL_UNINSTALL:-false}"

log() { echo "[ztwim-lab] $*"; }

log "Removing PostgreSQL SPIFFE demo workloads..."
oc delete -f "${SCRIPT_DIR}/demo-postgresql-spiffe-client.yaml" --ignore-not-found --timeout=120s 2>/dev/null || true
oc delete -f "${SCRIPT_DIR}/demo-postgresql-spiffe.yaml" --ignore-not-found --timeout=120s 2>/dev/null || true
oc delete project postgresql-spiffe postgresql-spiffe-client --ignore-not-found --timeout=120s 2>/dev/null || true

if [[ "${FULL_UNINSTALL}" == "true" ]]; then
  log "Removing SPIRE custom resources..."
  oc delete spireoidcdiscoveryprovider cluster --ignore-not-found --timeout=120s 2>/dev/null || true
  oc delete spiffecsidriver cluster --ignore-not-found --timeout=120s 2>/dev/null || true
  oc delete spireagent cluster --ignore-not-found --timeout=120s 2>/dev/null || true
  oc delete spireserver cluster --ignore-not-found --timeout=120s 2>/dev/null || true
  oc delete zerotrustworkloadidentitymanager cluster --ignore-not-found --timeout=120s 2>/dev/null || true

  log "Removing operator subscription..."
  oc delete subscription openshift-zero-trust-workload-identity-manager \
    -n "${OPERATOR_NAMESPACE}" --ignore-not-found --timeout=120s 2>/dev/null || true
  oc delete csv -n "${OPERATOR_NAMESPACE}" --all --ignore-not-found --timeout=120s 2>/dev/null || true
  oc delete project "${OPERATOR_NAMESPACE}" --ignore-not-found --timeout=120s 2>/dev/null || true
fi

log "Uninstall complete."
