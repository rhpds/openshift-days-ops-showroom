#!/usr/bin/env bash
# Remove all Secrets Management workshop resources:
#   - External Secrets Operator (Helm + external-secrets namespace)
#   - Vault Secrets App, ESO demo workloads, and Vault (Helm + vault namespace)
#   - Workshop ClusterIssuer (if cert-manager was used)
#
# Usage: ./cleanup-vault-lab.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_NAMESPACE="${VAULT_NAMESPACE:-vault}"
ESO_NAMESPACE="${ESO_NAMESPACE:-external-secrets}"
ESO_RELEASE="${ESO_HELM_RELEASE:-external-secrets}"
CERT_ISSUER="${VAULT_CERT_ISSUER:-vault-lab-issuer}"

log() { echo "[vault-lab-cleanup] $*"; }
warn() { echo "[vault-lab-cleanup] WARNING: $*" >&2; }

command -v oc >/dev/null 2>&1 || { echo "[vault-lab-cleanup] ERROR: oc not found in PATH" >&2; exit 1; }

log "Uninstalling External Secrets Operator (Helm release: ${ESO_RELEASE})..."
if command -v helm >/dev/null 2>&1; then
  helm uninstall "${ESO_RELEASE}" -n "${ESO_NAMESPACE}" --ignore-not-found 2>/dev/null || true
else
  warn "helm not found; skipping ESO Helm uninstall"
fi

log "Deleting namespace ${ESO_NAMESPACE}..."
oc delete namespace "${ESO_NAMESPACE}" --ignore-not-found --timeout=120s 2>/dev/null || true

log "Uninstalling Vault..."
"${SCRIPT_DIR}/uninstall-vault.sh"

log "Removing ClusterIssuer ${CERT_ISSUER} (workshop cert-manager issuer, if present)..."
oc delete clusterissuer "${CERT_ISSUER}" --ignore-not-found 2>/dev/null || true

log "Verifying cleanup..."
remaining_ns="$(oc get namespace "${VAULT_NAMESPACE}" "${ESO_NAMESPACE}" --ignore-not-found -o name 2>/dev/null || true)"
if [[ -n "${remaining_ns}" ]]; then
  warn "Namespaces still present (may be terminating):"
  echo "${remaining_ns}"
else
  log "Namespaces ${VAULT_NAMESPACE} and ${ESO_NAMESPACE} removed."
fi

if command -v helm >/dev/null 2>&1; then
  if helm list -A 2>/dev/null | grep -qE 'vault|external-secrets'; then
    warn "Helm releases may still be present:"
    helm list -A 2>/dev/null | grep -E 'vault|external-secrets' || true
  else
    log "No vault or external-secrets Helm releases found."
  fi
fi

log "Done."
