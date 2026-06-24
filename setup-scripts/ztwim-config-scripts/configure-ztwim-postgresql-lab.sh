#!/usr/bin/env bash
# Deploy or remove the PostgreSQL SPIFFE mTLS lab workloads.
# 1. Ensure ZTWIM platform is ready
# 2. Discover existing lab workloads
# 3. Deploy only what is missing
# 4. Verify server and client pods are ready
#
# Upstream alignment: Roadshow-ZTWIM deploy/*.yaml
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTION="${1:-deploy}"

SERVER_NS="postgresql-spiffe"
CLIENT_NS="postgresql-spiffe-client"

log() { echo "[ztwim-postgresql-lab] $*"; }
err() { echo "[ztwim-postgresql-lab] ERROR: $*" >&2; exit 1; }

usage() {
  cat <<EOF
Usage: $0 [deploy|cleanup]

  deploy   Ensure platform is ready, deploy lab workloads if needed, verify (default)
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

prepare_namespace() {
  local ns="$1" sa="$2"
  oc create namespace "${ns}" --dry-run=client -o yaml | oc apply -f -
  grant_scc "${ns}" "${sa}"
}

server_deployed() {
  oc get deployment postgresql-spiffe -n "${SERVER_NS}" >/dev/null 2>&1
}

client_deployed() {
  oc get deployment postgresql-spiffe-client -n "${CLIENT_NS}" >/dev/null 2>&1
}

pod_ready() {
  local ns="$1" label="$2"
  oc get pods -n "${ns}" -l "app=${label}" --no-headers 2>/dev/null \
    | grep -qE '2/2[[:space:]]+Running'
}

survey_lab() {
  log "=== Deployed state (PostgreSQL SPIFFE lab) ==="
  if server_deployed; then
    if pod_ready "${SERVER_NS}" postgresql-spiffe; then
      log "  PostgreSQL server: deployed and ready (2/2)"
    else
      log "  PostgreSQL server: deployed, not ready yet"
    fi
  else
    log "  PostgreSQL server: not deployed"
  fi

  if client_deployed; then
    if pod_ready "${CLIENT_NS}" postgresql-spiffe-client; then
      log "  PostgreSQL client: deployed and ready (2/2)"
    else
      log "  PostgreSQL client: deployed, not ready yet"
    fi
  else
    log "  PostgreSQL client: not deployed"
  fi
}

check_lab_ready() {
  local failures=0

  log "=== Readiness check ==="

  if server_deployed && pod_ready "${SERVER_NS}" postgresql-spiffe; then
    log "  [OK] PostgreSQL server pod ready (2/2)"
  else
    log "  [FAIL] PostgreSQL server pod not ready"
    failures=$((failures + 1))
  fi

  if client_deployed && pod_ready "${CLIENT_NS}" postgresql-spiffe-client; then
    log "  [OK] PostgreSQL client pod ready (2/2)"
  else
    log "  [FAIL] PostgreSQL client pod not ready"
    failures=$((failures + 1))
  fi

  return "${failures}"
}

deploy_lab() {
  log "Ensuring ZTWIM platform is ready..."
  "${SCRIPT_DIR}/configure-ztwim-lab.sh" setup

  survey_lab

  if check_lab_ready; then
    log "PostgreSQL SPIFFE lab is already deployed and ready."
    oc get pods -n "${SERVER_NS}"
    oc get pods -n "${CLIENT_NS}"
    return 0
  fi

  if ! server_deployed; then
    log "Deploying PostgreSQL server with SPIFFE integration..."
    prepare_namespace "${SERVER_NS}" postgresql-spiffe
    oc apply -f "${SCRIPT_DIR}/demo-postgresql-spiffe.yaml"
  else
    log "PostgreSQL server already deployed — skipping apply"
  fi

  if ! client_deployed; then
    log "Deploying PostgreSQL client with SPIFFE integration..."
    prepare_namespace "${CLIENT_NS}" postgresql-spiffe-client
    oc apply -f "${SCRIPT_DIR}/demo-postgresql-spiffe-client.yaml"
  else
    log "PostgreSQL client already deployed — skipping apply"
  fi

  log "Waiting for pods to become Ready..."
  oc wait --for=condition=Ready pod -l app=postgresql-spiffe -n "${SERVER_NS}" --timeout=300s
  oc wait --for=condition=Ready pod -l app=postgresql-spiffe-client -n "${CLIENT_NS}" --timeout=300s

  if ! check_lab_ready; then
    oc get pods -n "${SERVER_NS}" || true
    oc get pods -n "${CLIENT_NS}" || true
    err "PostgreSQL SPIFFE lab readiness check failed"
  fi

  oc get pods -n "${SERVER_NS}"
  oc get pods -n "${CLIENT_NS}"
  log "PostgreSQL SPIFFE lab is ready."
}

cleanup_lab() {
  log "Removing PostgreSQL SPIFFE lab workloads..."
  oc delete -f "${SCRIPT_DIR}/demo-postgresql-spiffe-client.yaml" --ignore-not-found --timeout=120s 2>/dev/null || true
  oc delete -f "${SCRIPT_DIR}/demo-postgresql-spiffe.yaml" --ignore-not-found --timeout=120s 2>/dev/null || true
  oc delete project "${SERVER_NS}" "${CLIENT_NS}" --ignore-not-found --timeout=120s 2>/dev/null || true
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
