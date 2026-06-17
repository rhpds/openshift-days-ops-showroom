#!/usr/bin/env bash
# Remove Vault Helm release from the cluster.
set -euo pipefail

NAMESPACE="${VAULT_NAMESPACE:-vault}"
RELEASE="${VAULT_HELM_RELEASE:-vault}"

echo "[VAULT] Uninstalling Helm release ${RELEASE} from ${NAMESPACE}..."
if command -v helm >/dev/null 2>&1; then
  helm uninstall "${RELEASE}" -n "${NAMESPACE}" --ignore-not-found 2>/dev/null || true
fi

echo "[VAULT] Deleting namespace ${NAMESPACE} (if present)..."
oc delete namespace "${NAMESPACE}" --ignore-not-found --timeout=120s 2>/dev/null || true

echo "[VAULT] Uninstall complete."
