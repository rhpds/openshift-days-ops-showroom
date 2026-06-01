#!/usr/bin/env bash
# Configure Vault Kubernetes auth for the my-vault-app workshop deployment.
set -euo pipefail

export VAULT_ADDR="${VAULT_ADDR:-$(oc get route vault -n vault -o jsonpath='https://{.spec.host}')}"
export VAULT_TOKEN="${VAULT_TOKEN:-root}"
export VAULT_SKIP_VERIFY="${VAULT_SKIP_VERIFY:-true}"

VAULT_POD="${VAULT_POD:-$(oc get pod -n vault -l app.kubernetes.io/name=vault,component=server -o jsonpath='{.items[0].metadata.name}')}"
vault_cmd() {
  if command -v vault >/dev/null 2>&1; then
    vault "$@"
  else
    oc exec -n vault "${VAULT_POD}" -- env VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN="${VAULT_TOKEN}" vault "$@"
  fi
}

echo "[vault-k8s-chain] Enabling Kubernetes auth (if needed)..."
vault_cmd auth enable kubernetes 2>/dev/null || true

echo "[vault-k8s-chain] Configuring Kubernetes auth..."
oc exec -n vault "${VAULT_POD}" -- sh -ec 'vault write auth/kubernetes/config \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  kubernetes_host="https://kubernetes.default.svc:443"'

echo "[vault-k8s-chain] Writing policy for Kubernetes secrets engine creds..."
vault_cmd policy write my-vault-app-k8s-chain - <<'EOF'
path "kubernetes/creds/my-vault-app-role" {
  capabilities = ["create", "update"]
}
EOF

echo "[vault-k8s-chain] Binding policy to my-vault-app service account..."
vault_cmd write auth/kubernetes/role/my-vault-app \
  bound_service_account_names=my-vault-app \
  bound_service_account_namespaces=my-vault-app-namespace \
  policies=my-vault-app-k8s-chain \
  ttl=1h

echo "[vault-k8s-chain] Done."
