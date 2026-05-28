#!/usr/bin/env bash
# Deploy HashiCorp Vault on OpenShift using the official Helm chart.
# Chart repo: https://helm.releases.hashicorp.com (hashicorp/vault)
# Documentation: https://developer.hashicorp.com/vault/docs/platform/k8s/helm
#
# Prerequisites: Helm 3.6+, Kubernetes/OpenShift 1.29+, oc logged in with project admin

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="${VAULT_NAMESPACE:-vault}"
RELEASE="${VAULT_HELM_RELEASE:-vault}"
CHART="${VAULT_CHART:-hashicorp/vault}"
VALUES_FILE="${VAULT_VALUES_FILE:-${SCRIPT_DIR}/vault-values-openshift-lab.yaml}"
HELM_REPO_NAME="${VAULT_HELM_REPO_NAME:-hashicorp}"
HELM_REPO_URL="${VAULT_HELM_REPO_URL:-https://helm.releases.hashicorp.com}"
HELM_VERSION="${HELM_VERSION:-v3.16.3}"
HELM_INSTALL_DIR="${HELM_INSTALL_DIR:-${HOME}/.local/bin}"

log() { echo "[VAULT] $*"; }
die() { echo "[VAULT] ERROR: $*" >&2; exit 1; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

ensure_helm() {
  if command_exists helm && helm version --short 2>/dev/null | grep -q '^v3'; then
    return 0
  fi

  local os arch tarball dest
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"
  case "${arch}" in
    x86_64) arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    *) die "Unsupported architecture for Helm install: ${arch}" ;;
  esac

  mkdir -p "${HELM_INSTALL_DIR}"
  dest="${HELM_INSTALL_DIR}/helm"
  tarball="helm-${HELM_VERSION}-${os}-${arch}.tar.gz"

  log "Helm not found; installing ${HELM_VERSION} to ${dest}..."
  curl -fsSL "https://get.helm.sh/${tarball}" -o "/tmp/${tarball}"
  tar -xzf "/tmp/${tarball}" -C /tmp
  mv -f "/tmp/${os}-${arch}/helm" "${dest}"
  chmod +x "${dest}"
  rm -rf "/tmp/${tarball}" "/tmp/${os}-${arch}"

  export PATH="${HELM_INSTALL_DIR}:${PATH}"
  command_exists helm || die "Helm install failed"
  log "Helm installed: $(helm version --short)"
}

check_prereqs() {
  command_exists oc || die "oc not found in PATH"
  oc whoami >/dev/null 2>&1 || die "Not logged in to OpenShift (run oc login)"
  command_exists curl || die "curl not found in PATH (required to install Helm)"
  ensure_helm
  [[ -f "${VALUES_FILE}" ]] || die "Values file not found: ${VALUES_FILE}"
  log "Using values: ${VALUES_FILE}"
}

helm_repo_ready() {
  helm repo add "${HELM_REPO_NAME}" "${HELM_REPO_URL}" 2>/dev/null || true
  helm repo update "${HELM_REPO_NAME}"
}

cluster_ingress_domain() {
  oc get ingresses.config/cluster -o jsonpath='{.spec.domain}' 2>/dev/null
}

vault_route_host() {
  if [[ -n "${VAULT_ROUTE_HOST:-}" ]]; then
    echo "${VAULT_ROUTE_HOST}"
    return
  fi
  local domain
  domain="$(cluster_ingress_domain)"
  [[ -n "${domain}" ]] || die "Could not read cluster ingress domain (oc get ingresses.config/cluster)"
  echo "vault.apps.${domain}"
}

route_host_ok() {
  local host
  host="$(oc get route "${RELEASE}" -n "${NAMESPACE}" -o jsonpath='{.spec.host}' 2>/dev/null || true)"
  [[ -n "${host}" && "${host}" != "chart-example.local" ]]
}

vault_ready() {
  oc get pods -n "${NAMESPACE}" -l "app.kubernetes.io/name=vault,component=server" \
    -o jsonpath='{.items[0].status.phase}' 2>/dev/null | grep -q Running \
    && route_host_ok
}

helm_install_vault() {
  local route_host
  route_host="$(vault_route_host)"
  log "OpenShift Route host: ${route_host}"
  helm upgrade --install "${RELEASE}" "${CHART}" \
    --namespace "${NAMESPACE}" \
    --values "${VALUES_FILE}" \
    --set-string "server.route.host=${route_host}" \
    --wait \
    --timeout 10m
}

print_access_info() {
  log ""
  log "========================================================="
  log "Vault deployment summary"
  log "========================================================="
  oc get pods,svc,route -n "${NAMESPACE}" 2>/dev/null || true
  log ""
  local route_host
  route_host="$(oc get route "${RELEASE}" -n "${NAMESPACE}" \
    -o jsonpath='{.spec.host}' 2>/dev/null || true)"
  if [[ -n "${route_host}" && "${route_host}" != "chart-example.local" ]]; then
    log "Vault UI (OpenShift route): https://${route_host}/"
    log "Health check: curl -ks \"https://${route_host}/v1/sys/health\" | head -3"
  else
    log "Port-forward UI: oc port-forward svc/${RELEASE} -n ${NAMESPACE} 8200:8200"
    log "Then open: http://127.0.0.1:8200/"
  fi
  log ""
  log "Dev mode root token (lab only): root"
  log "CLI (via route): export VAULT_ADDR=\"https://${route_host}\" VAULT_TOKEN=root"
  log "Docs: https://developer.hashicorp.com/vault/docs/platform/k8s/helm"
}

main() {
  check_prereqs

  if vault_ready; then
    log "Vault is already running with a valid route in namespace ${NAMESPACE}"
    print_access_info
    exit 0
  fi

  log "Creating namespace ${NAMESPACE}..."
  oc create namespace "${NAMESPACE}" --dry-run=client -o yaml | oc apply -f -

  log "Adding Helm repo ${HELM_REPO_URL}..."
  helm_repo_ready

  log "Installing ${CHART} (release: ${RELEASE})..."
  helm_install_vault

  log "Waiting for Vault server pod..."
  oc wait --for=condition=Ready pod \
    -l "app.kubernetes.io/name=vault,component=server" \
    -n "${NAMESPACE}" \
    --timeout=300s

  print_access_info
  log "Done."
}

main "$@"
