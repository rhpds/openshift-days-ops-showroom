#!/usr/bin/env bash
# Workshop Vault configuration aligned with:
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

echo "[vault-lab] Creating read-policy..."
vault_cmd policy write read-policy - <<'EOF'
path "secret*" {
  capabilities = ["read"]
}
EOF

echo "[vault-lab] Enabling Kubernetes auth (if needed)..."
vault_cmd auth enable kubernetes 2>/dev/null || true

echo "[vault-lab] Configuring Kubernetes auth..."
oc exec -n vault "${VAULT_POD}" -- sh -ec 'vault write auth/kubernetes/config \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  kubernetes_host="https://kubernetes.default.svc:443"'

echo "[vault-lab] Creating Kubernetes auth role vault-role..."
vault_cmd write auth/kubernetes/role/vault-role \
  bound_service_account_names=vault-serviceaccount \
  bound_service_account_namespaces=vault \
  policies=read-policy \
  ttl=1h

echo "[vault-lab] Enabling KV secrets engine at secret/ (if needed)..."
vault_cmd secrets enable -path=secret kv-v2 2>/dev/null || true

echo "[vault-lab] Writing workshop secrets..."
vault_cmd kv put secret/login pattoken=workshop-pattoken-abc123
vault_cmd kv put secret/my-first-secret username=workshop-user password=workshop-password

echo "[vault-lab] Secrets in Vault:"
vault_cmd kv list secret

echo "[vault-lab] Done."
