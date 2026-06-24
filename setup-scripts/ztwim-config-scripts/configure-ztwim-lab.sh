#!/usr/bin/env bash
# Workshop ZTWIM install aligned with Roadshow-ZTWIM scripts/00-install-ztwim-operator.sh
# Installs the operator from OperatorHub and configures SPIRE components.
set -euo pipefail

OPERATOR_NAMESPACE="${OPERATOR_NAMESPACE:-openshift-zero-trust-workload-identity-manager}"
INSTALL_MODE="${1:-full}"

log() { echo "[ztwim-lab] $*"; }
err() { echo "[ztwim-lab] ERROR: $*" >&2; exit 1; }

require_oc() {
  oc whoami >/dev/null 2>&1 || err "Not logged into OpenShift"
  oc auth can-i create subscriptions --all-namespaces >/dev/null 2>&1 \
    || err "cluster-admin privileges required"
}

detect_cluster_config() {
  CLUSTER_DOMAIN="$(oc get ingresses.config/cluster -o jsonpath='{.spec.domain}')"
  [[ -n "${CLUSTER_DOMAIN}" ]] || err "Failed to detect cluster domain"
  TRUST_DOMAIN="${CLUSTER_DOMAIN}"
  CLUSTER_NAME="$(oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}' | cut -d'-' -f1)"
  CLUSTER_NAME="${CLUSTER_NAME:-cluster}"
  export CLUSTER_DOMAIN TRUST_DOMAIN CLUSTER_NAME
  log "Cluster domain: ${CLUSTER_DOMAIN}"
  log "Trust domain: ${TRUST_DOMAIN}"
}

operator_csv_ready() {
  local csv
  csv="$(oc get csv -n "${OPERATOR_NAMESPACE}" \
    -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null \
    | grep -E 'zero-trust-workload-identity-manager|zerotrust' | head -1)"
  [[ -n "${csv}" ]] \
    && [[ "$(oc get csv "${csv}" -n "${OPERATOR_NAMESPACE}" -o jsonpath='{.status.phase}')" == "Succeeded" ]]
}

install_operator() {
  if operator_csv_ready; then
    log "ZTWIM operator CSV already Succeeded; skipping operator install"
    return 0
  fi

  if oc get subscription openshift-zero-trust-workload-identity-manager -n "${OPERATOR_NAMESPACE}" >/dev/null 2>&1; then
    log "Operator subscription already exists; continuing"
  fi

  oc create namespace "${OPERATOR_NAMESPACE}" --dry-run=client -o yaml | oc apply -f -

  oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: zero-trust-workload-identity-manager
  namespace: ${OPERATOR_NAMESPACE}
spec:
  targetNamespaces:
  - ${OPERATOR_NAMESPACE}
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-zero-trust-workload-identity-manager
  namespace: ${OPERATOR_NAMESPACE}
spec:
  channel: stable-v1
  installPlanApproval: Automatic
  name: openshift-zero-trust-workload-identity-manager
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

  log "Waiting for operator CSV (up to 15 minutes)..."
  elapsed=0
  while [[ "${elapsed}" -lt 900 ]]; do
    csv="$(oc get subscription openshift-zero-trust-workload-identity-manager \
      -n "${OPERATOR_NAMESPACE}" -o jsonpath='{.status.currentCSV}' 2>/dev/null || true)"
    if [[ -n "${csv}" ]] && [[ "$(oc get csv "${csv}" -n "${OPERATOR_NAMESPACE}" -o jsonpath='{.status.phase}')" == "Succeeded" ]]; then
      log "Operator installed: ${csv}"
      return 0
    fi
    sleep 10
    elapsed=$((elapsed + 10))
  done
  err "Timed out waiting for operator CSV"
}

configure_spire() {
  oc apply -f - <<EOF
apiVersion: operator.openshift.io/v1alpha1
kind: ZeroTrustWorkloadIdentityManager
metadata:
  name: cluster
spec:
  trustDomain: ${TRUST_DOMAIN}
  clusterName: ${CLUSTER_NAME}
  bundleConfigMap: spire-bundle
---
apiVersion: operator.openshift.io/v1alpha1
kind: SpireServer
metadata:
  name: cluster
spec:
  caSubject:
    commonName: redhat.com
    country: US
    organization: Red Hat
  persistence:
    size: 5Gi
    accessMode: ReadWriteOnce
  datastore:
    databaseType: sqlite3
    connectionString: /run/spire/data/datastore.sqlite3
  jwtIssuer: https://spire-spiffe-oidc-discovery-provider.${CLUSTER_DOMAIN}
---
apiVersion: operator.openshift.io/v1alpha1
kind: SpireAgent
metadata:
  name: cluster
spec:
  nodeAttestor:
    k8sPSATEnabled: "true"
  workloadAttestors:
    k8sEnabled: "true"
    workloadAttestorsVerification:
      type: auto
---
apiVersion: operator.openshift.io/v1alpha1
kind: SpiffeCSIDriver
metadata:
  name: cluster
spec:
  agentSocketPath: /run/spire/agent-sockets
---
apiVersion: operator.openshift.io/v1alpha1
kind: SpireOIDCDiscoveryProvider
metadata:
  name: cluster
spec:
  jwtIssuer: https://spire-spiffe-oidc-discovery-provider.${CLUSTER_DOMAIN}
  managedRoute: "true"
EOF
}

wait_for_ready() {
  log "Waiting for SPIRE server..."
  oc wait --for=condition=Ready pod -l app.kubernetes.io/name=spire-server \
    -n "${OPERATOR_NAMESPACE}" --timeout=300s

  for component in spire-agent spire-spiffe-csi-driver; do
    log "Waiting for ${component} DaemonSet..."
    elapsed=0
    while [[ "${elapsed}" -lt 300 ]]; do
      ready="$(oc get daemonset -n "${OPERATOR_NAMESPACE}" -l "app.kubernetes.io/name=${component}" \
        -o jsonpath='{.items[0].status.numberReady}' 2>/dev/null || echo 0)"
      desired="$(oc get daemonset -n "${OPERATOR_NAMESPACE}" -l "app.kubernetes.io/name=${component}" \
        -o jsonpath='{.items[0].status.desiredNumberScheduled}' 2>/dev/null || echo 0)"
      if [[ "${ready}" -gt 0 ]] && [[ "${ready}" == "${desired}" ]]; then
        log "${component} ready (${ready}/${desired})"
        break
      fi
      sleep 5
      elapsed=$((elapsed + 5))
    done
  done
}

verify_installation() {
  oc get pods -n "${OPERATOR_NAMESPACE}"
  oc get csidriver csi.spiffe.io
  oc get crd clusterspiffeids.spire.spiffe.io
}

main() {
  require_oc
  detect_cluster_config

  if [[ "${INSTALL_MODE}" == "spire-only" ]]; then
    operator_csv_ready || err "ZTWIM operator CSV not Succeeded; install the operator first"
    log "Configuring SPIRE components only (operator assumed pre-installed)..."
    configure_spire
    wait_for_ready
    verify_installation
    log "SPIRE configuration complete."
    log "Next: ./configure-ztwim-postgresql-lab.sh"
    return 0
  fi

  install_operator
  configure_spire
  wait_for_ready
  verify_installation
  log "ZTWIM lab setup complete."
  log "Next: ./configure-ztwim-postgresql-lab.sh"
}

if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
  echo "Usage: $0 [full|spire-only]"
  echo "  full       Install operator (if needed) and configure SPIRE (default)"
  echo "  spire-only Configure SPIRE when operator CSV is already Succeeded"
  exit 0
fi

main
