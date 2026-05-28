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

vault_ready() {
  oc get pods -n "${NAMESPACE}" -l "app.kubernetes.io/name=vault,component=server" \
    -o jsonpath='{.items[0].status.phase}' 2>/dev/null | grep -q Running
}

print_access_info() {
  log ""
  log "========================================================="
  log "Vault deployment summary"
  log "========================================================="
  oc get pods,svc,route -n "${NAMESPACE}" 2>/dev/null || true
  log ""
  local route_host
  route_host="$(oc get route -n "${NAMESPACE}" -l "app.kubernetes.io/name=vault" \
    -o jsonpath='{.items[0].spec.host}' 2>/dev/null || true)"
  if [[ -n "${route_host}" ]]; then
    log "Vault UI (OpenShift route): https://${route_host}/"
  else
    log "Port-forward UI: oc port-forward svc/${RELEASE} -n ${NAMESPACE} 8200:8200"
    log "Then open: http://127.0.0.1:8200/"
  fi
  log ""
  log "Dev mode root token (lab only): root"
  log "CLI: export VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=root  # after port-forward"
  log "Docs: https://developer.hashicorp.com/vault/docs/platform/k8s/helm"
}

main() {
  check_prereqs

  if vault_ready; then
    log "Vault server already running in namespace ${NAMESPACE}"
    print_access_info
    exit 0
  fi

  log "Creating namespace ${NAMESPACE}..."
  oc create namespace "${NAMESPACE}" --dry-run=client -o yaml | oc apply -f -

  log "Adding Helm repo ${HELM_REPO_URL}..."
  helm_repo_ready

  log "Installing ${CHART} (release: ${RELEASE})..."
  helm upgrade --install "${RELEASE}" "${CHART}" \
    --namespace "${NAMESPACE}" \
    --values "${VALUES_FILE}" \
    --wait \
    --timeout 10m

  log "Waiting for Vault server pod..."
  oc wait --for=condition=Ready pod \
    -l "app.kubernetes.io/name=vault,component=server" \
    -n "${NAMESPACE}" \
    --timeout=300s

  print_access_info
  log "Done."
}

main "$@"
