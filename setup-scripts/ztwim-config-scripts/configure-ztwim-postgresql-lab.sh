#!/usr/bin/env bash
# Deploy PostgreSQL SPIFFE mTLS demo aligned with Roadshow-ZTWIM deploy/*.yaml
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { echo "[ztwim-postgresql-lab] $*"; }

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
