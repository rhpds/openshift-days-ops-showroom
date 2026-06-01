#!/usr/bin/env bash
# Remove ZTWIM sample CRs and uninstall the operator subscription (keeps CSV cleanup to OLM).
set -euo pipefail

NAMESPACE="${ZTWIM_NAMESPACE:-zero-trust-workload-identity-manager}"
WORKDIR="${ZTWIM_WORKDIR:-/tmp/zero-trust-workload-identity-manager}"

echo "[ZTWIM] Deleting sample CRs (if clone exists)..."
if [[ -d "${WORKDIR}/config/samples" ]]; then
  oc delete -k "${WORKDIR}/config/samples/" --ignore-not-found --timeout=120s 2>/dev/null || true
fi

echo "[ZTWIM] Removing subscription and CSV in ${NAMESPACE}..."
oc delete subscription zero-trust-workload-identity-manager -n "${NAMESPACE}" --ignore-not-found --timeout=120s || true
oc delete csv -n "${NAMESPACE}" -l operators.coreos.com/zero-trust-workload-identity-manager.zero-trust-workload-identity-manager --ignore-not-found --timeout=120s 2>/dev/null || true
oc delete csv -n "${NAMESPACE}" --all --ignore-not-found --timeout=120s 2>/dev/null || true

echo "[ZTWIM] Uninstall complete. Namespace ${NAMESPACE} was not deleted (remove manually if desired)."
