#!/usr/bin/env bash
# Deploy or remove the PostgreSQL SPIFFE mTLS lab workloads.
# Upstream alignment: Roadshow-ZTWIM deploy/*.yaml
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTION="${1:-deploy}"

log() { echo "[ztwim-postgresql-lab] $*"; }
err() { echo "[ztwim-postgresql-lab] ERROR: $*" >&2; exit 1; }

usage() {
  cat <<EOF
Usage: $0 [deploy|cleanup]

  deploy   Verify ZTWIM platform, deploy PostgreSQL server and client, wait for Ready (default)
  cleanup  Remove PostgreSQL lab namespaces and workloads (ZTWIM platform is left in place)
EOF
}

grant_scc() {
  local ns="$1" sa="$2"
  oc label namespace "${ns}" \
    security.openshift.io/scc.podSecurityLabelSync=false \
    pod-security.kubernetes.io/enforce=privileged \
    pod-security.kubernetes.io/audit=privileged \
    pod-security.kubernetes.io/warn=privileged \
    --overwrite
  oc adm policy add-scc-to-user anyuid -z "${sa}" -n "${ns}"
}

deploy_lab() {
  log "Verifying ZTWIM platform is ready..."
  "${SCRIPT_DIR}/configure-ztwim-lab.sh" check

  log "Deploying PostgreSQL server with SPIFFE integration..."
  oc apply -f "${SCRIPT_DIR}/demo-postgresql-spiffe.yaml"
  grant_scc postgresql-spiffe postgresql-spiffe

  log "Deploying PostgreSQL client with SPIFFE integration..."
  oc apply -f "${SCRIPT_DIR}/demo-postgresql-spiffe-client.yaml"
  grant_scc postgresql-spiffe-client postgresql-spiffe-client

  log "Waiting for pods to become Ready..."
  oc wait --for=condition=Ready pod -l app=postgresql-spiffe -n postgresql-spiffe --timeout=300s
  oc wait --for=condition=Ready pod -l app=postgresql-spiffe-client -n postgresql-spiffe-client --timeout=300s

  oc get pods -n postgresql-spiffe
  oc get pods -n postgresql-spiffe-client
  log "PostgreSQL SPIFFE lab deployed."
}

cleanup_lab() {
  log "Removing PostgreSQL SPIFFE lab workloads..."
  oc delete -f "${SCRIPT_DIR}/demo-postgresql-spiffe-client.yaml" --ignore-not-found --timeout=120s 2>/dev/null || true
  oc delete -f "${SCRIPT_DIR}/demo-postgresql-spiffe.yaml" --ignore-not-found --timeout=120s 2>/dev/null || true
  oc delete project postgresql-spiffe postgresql-spiffe-client --ignore-not-found --timeout=120s 2>/dev/null || true
  log "PostgreSQL SPIFFE lab removed. ZTWIM platform was not changed."
}

case "${ACTION}" in
  deploy|"")
    deploy_lab
    ;;
  cleanup|uninstall|remove)
    cleanup_lab
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    err "Unknown action: ${ACTION}. Run $0 --help"
    ;;
esac
