#!/usr/bin/env bash
# Deploy HashiCorp Vault on OpenShift using the official Helm chart.
# Chart repo: https://helm.releases.hashicorp.com (hashicorp/vault)
# Documentation: https://developer.hashicorp.com/vault/docs/platform/k8s/helm
#
# Prerequisites: Helm 3.6+, Kubernetes/OpenShift 1.29+, oc logged in with project admin
# Optional: cert-manager operator for a route TLS cert matching the Vault hostname

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="${VAULT_NAMESPACE:-vault}"
RELEASE="${VAULT_HELM_RELEASE:-vault}"
CHART="${VAULT_CHART:-hashicorp/vault}"
VALUES_FILE="${VAULT_VALUES_FILE:-${SCRIPT_DIR}/vault-values-openshift-lab.yaml}"
ISSUER_MANIFEST="${VAULT_ISSUER_MANIFEST:-${SCRIPT_DIR}/vault-cert-manager-issuer.yaml}"
HELM_REPO_NAME="${VAULT_HELM_REPO_NAME:-hashicorp}"
HELM_REPO_URL="${VAULT_HELM_REPO_URL:-https://helm.releases.hashicorp.com}"
HELM_VERSION="${HELM_VERSION:-v3.16.3}"
HELM_INSTALL_DIR="${HELM_INSTALL_DIR:-${HOME}/.local/bin}"
CERT_ISSUER="${VAULT_CERT_ISSUER:-vault-lab-issuer}"
CERT_ISSUER_KIND="${VAULT_CERT_ISSUER_KIND:-ClusterIssuer}"
USE_CERT_MANAGER="${VAULT_USE_CERT_MANAGER:-auto}"

log() { echo "[VAULT] $*"; }
warn() { echo "[VAULT] WARNING: $*" >&2; }
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
  # OpenShift cluster domain is usually already "apps.<cluster>.<tld>" — do not prepend "apps." again.
  if [[ "${domain}" == apps.* ]]; then
    echo "vault.${domain}"
  else
    echo "vault.apps.${domain}"
  fi
}

current_route_host() {
  oc get route "${RELEASE}" -n "${NAMESPACE}" -o jsonpath='{.spec.host}' 2>/dev/null || true
}

route_host_ok() {
  local host expected
  host="$(current_route_host)"
  expected="$(vault_route_host)"
  [[ -n "${host}" && "${host}" == "${expected}" ]]
}

cert_manager_available() {
  oc get crd certificates.cert-manager.io >/dev/null 2>&1
}

should_use_cert_manager() {
  case "${USE_CERT_MANAGER}" in
    true|yes|1) cert_manager_available ;;
    false|no|0) return 1 ;;
    auto|*) cert_manager_available ;;
  esac
}

ensure_cert_issuer() {
  if oc get clusterissuer "${CERT_ISSUER}" >/dev/null 2>&1; then
    log "Using ClusterIssuer ${CERT_ISSUER}"
    return 0
  fi
  if [[ -f "${ISSUER_MANIFEST}" ]]; then
    log "Creating ClusterIssuer ${CERT_ISSUER} (self-signed, workshop use)..."
    oc apply -f "${ISSUER_MANIFEST}"
    return 0
  fi
  die "ClusterIssuer ${CERT_ISSUER} not found and ${ISSUER_MANIFEST} is missing"
}

route_has_cert_manager_cert() {
  local ann
  ann="$(oc get route "${RELEASE}" -n "${NAMESPACE}" \
    -o jsonpath='{.metadata.annotations.cert-manager\.io/issuer}' 2>/dev/null || true)"
  [[ -n "${ann}" ]]
}

configure_cert_manager_route() {
  should_use_cert_manager || {
    warn "cert-manager not available; route uses the cluster ingress wildcard certificate"
    return 0
  }

  ensure_cert_issuer

  log "Requesting route certificate from cert-manager (${CERT_ISSUER})..."
  oc annotate route "${RELEASE}" -n "${NAMESPACE}" \
    cert-manager.io/issuer="${CERT_ISSUER}" \
    cert-manager.io/issuer-kind="${CERT_ISSUER_KIND}" \
    --overwrite

  local elapsed=0
  while [[ "${elapsed}" -lt 180 ]]; do
    if oc get route "${RELEASE}" -n "${NAMESPACE}" \
      -o jsonpath='{.status.tls.certificate}' 2>/dev/null | grep -q .; then
      log "Route TLS certificate issued by cert-manager"
      return 0
    fi
    sleep 5
    elapsed=$((elapsed + 5))
  done
  warn "Timed out waiting for cert-manager to populate route TLS (check: oc describe route ${RELEASE} -n ${NAMESPACE})"
}

vault_ready() {
  oc get pods -n "${NAMESPACE}" -l "app.kubernetes.io/name=vault,component=server" \
    -o jsonpath='{.items[0].status.phase}' 2>/dev/null | grep -q Running \
    && route_host_ok \
    && { ! should_use_cert_manager || route_has_cert_manager_cert; }
}

helm_install_vault() {
  local route_host helm_args=()
  route_host="$(vault_route_host)"
  log "OpenShift Route host: ${route_host}"

  helm_args=(
    upgrade --install "${RELEASE}" "${CHART}"
    --namespace "${NAMESPACE}"
    --values "${VALUES_FILE}"
    --set-string "server.route.host=${route_host}"
  )

  if should_use_cert_manager; then
    ensure_cert_issuer
    helm_args+=(
      --set-string "server.route.annotations.cert-manager\.io/issuer=${CERT_ISSUER}"
      --set-string "server.route.annotations.cert-manager\.io/issuer-kind=${CERT_ISSUER_KIND}"
    )
  fi

  helm_args+=(--wait --timeout 10m)
  helm "${helm_args[@]}"
}

print_access_info() {
  log ""
  log "========================================================="
  log "Vault deployment summary"
  log "========================================================="
  oc get pods,svc,route -n "${NAMESPACE}" 2>/dev/null || true
  if should_use_cert_manager; then
    oc get certificate,clusterissuer "${CERT_ISSUER}" 2>/dev/null || true
  fi
  log ""
  local route_host
  route_host="$(current_route_host)"
  if [[ -n "${route_host}" && "${route_host}" != "chart-example.local" ]]; then
    log "Vault UI: https://${route_host}/"
    log "Health: curl -ks \"https://${route_host}/v1/sys/health\" | head -3"
    if should_use_cert_manager; then
      log "TLS: cert-manager issuer ${CERT_ISSUER} (self-signed — trust the CA or use browser exception)"
    else
      log "TLS: cluster ingress wildcard (*.apps.<cluster-domain>)"
    fi
  else
    log "Port-forward: oc port-forward svc/${RELEASE} -n ${NAMESPACE} 8200:8200"
    log "UI: http://127.0.0.1:8200/"
  fi
  log ""
  log "Dev mode token (lab only): root"
  log "CLI: export VAULT_ADDR=\"https://${route_host}\" VAULT_TOKEN=root"
}

main() {
  check_prereqs

  if vault_ready; then
    log "Vault is already running with route https://$(vault_route_host)/"
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

  configure_cert_manager_route

  print_access_info
  log "Done."
}

main "$@"
