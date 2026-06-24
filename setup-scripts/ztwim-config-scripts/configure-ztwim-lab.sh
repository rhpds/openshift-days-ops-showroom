#!/usr/bin/env bash
# Configure the ZTWIM platform for the workshop lab.
# - Uses pre-installed operator when CSV is already Succeeded (showroom default)
# - Applies SPIRE custom resources when missing
# - Waits for workloads and verifies the platform is ready before exiting
#
# Upstream alignment: Roadshow-ZTWIM scripts/00-install-ztwim-operator.sh
set -euo pipefail

OPERATOR_NAMESPACE="${OPERATOR_NAMESPACE:-zero-trust-workload-identity-manager}"
LEGACY_OPERATOR_NAMESPACE="openshift-zero-trust-workload-identity-manager"
SUBSCRIPTION_NAME="${ZTWIM_SUBSCRIPTION_NAME:-openshift-zero-trust-workload-identity-manager}"
PACKAGE_NAME="${ZTWIM_PACKAGE:-zero-trust-workload-identity-manager}"
INSTALL_MODE="${1:-setup}"

log() { echo "[ztwim-platform] $*"; }
err() { echo "[ztwim-platform] ERROR: $*" >&2; exit 1; }

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

operator_csv_name() {
  oc get csv -n "${OPERATOR_NAMESPACE}" \
    -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null \
    | grep -E '^zero-trust-workload-identity-manager\.' | head -1
}

operator_csv_phase() {
  local csv
  csv="$(operator_csv_name)"
  [[ -n "${csv}" ]] || return 1
  oc get csv "${csv}" -n "${OPERATOR_NAMESPACE}" -o jsonpath='{.status.phase}'
}

operator_csv_ready() {
  [[ "$(operator_csv_phase 2>/dev/null || echo "")" == "Succeeded" ]]
}

operator_csv_phase_in() {
  local ns="$1" csv
  csv="$(oc get csv -n "${ns}" \
    -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null \
    | grep -E '^zero-trust-workload-identity-manager\.' | head -1)"
  [[ -n "${csv}" ]] || return 1
  oc get csv "${csv}" -n "${ns}" -o jsonpath='{.status.phase}'
}

cleanup_legacy_operator_namespace() {
  if ! oc get namespace "${LEGACY_OPERATOR_NAMESPACE}" >/dev/null 2>&1; then
    return 0
  fi

  local phase
  phase="$(operator_csv_phase_in "${LEGACY_OPERATOR_NAMESPACE}" 2>/dev/null || echo "missing")"
  if [[ "${phase}" == "Succeeded" ]]; then
    log "WARNING: ZTWIM operator is installed in unsupported namespace ${LEGACY_OPERATOR_NAMESPACE}."
    log "         Red Hat supports only zero-trust-workload-identity-manager (not openshift-*)."
    return 0
  fi

  if [[ "${phase}" != "missing" ]]; then
    log "Removing failed ZTWIM install from unsupported namespace ${LEGACY_OPERATOR_NAMESPACE} (phase: ${phase})..."
    oc delete subscription "${SUBSCRIPTION_NAME}" -n "${LEGACY_OPERATOR_NAMESPACE}" --ignore-not-found --timeout=120s 2>/dev/null || true
    oc delete csv -n "${LEGACY_OPERATOR_NAMESPACE}" \
      -l operators.coreos.com/"${PACKAGE_NAME}"."${LEGACY_OPERATOR_NAMESPACE}" \
      --ignore-not-found --timeout=120s 2>/dev/null || true
    oc delete installplan -n "${LEGACY_OPERATOR_NAMESPACE}" --all --ignore-not-found --timeout=120s 2>/dev/null || true
  fi
}

recover_failed_operator() {
  local csv phase
  csv="$(operator_csv_name)"
  [[ -n "${csv}" ]] || return 0
  phase="$(operator_csv_phase)"
  if [[ "${phase}" == "Failed" ]] || [[ "${phase}" == "Replacing" ]]; then
    log "ZTWIM operator CSV ${csv} is ${phase}; deleting to trigger OLM reinstall..."
    oc get csv "${csv}" -n "${OPERATOR_NAMESPACE}" \
      -o jsonpath='{.status.message}{"\n"}' 2>/dev/null | sed 's/^/[ztwim-platform]   /' || true
    oc delete csv "${csv}" -n "${OPERATOR_NAMESPACE}" --timeout=120s 2>/dev/null || true
    oc delete installplan -n "${OPERATOR_NAMESPACE}" --all --ignore-not-found --timeout=120s 2>/dev/null || true
    if oc get subscription "${SUBSCRIPTION_NAME}" -n "${OPERATOR_NAMESPACE}" >/dev/null 2>&1; then
      oc patch subscription "${SUBSCRIPTION_NAME}" -n "${OPERATOR_NAMESPACE}" --type merge \
        -p '{"spec":{"startingCSV":"","installPlanApproval":"Automatic"}}' 2>/dev/null || true
    fi
  fi
}

ensure_operator_subscription() {
  oc create namespace "${OPERATOR_NAMESPACE}" --dry-run=client -o yaml | oc apply -f -

  if ! oc get operatorgroup zero-trust-workload-identity-manager -n "${OPERATOR_NAMESPACE}" >/dev/null 2>&1; then
    oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: zero-trust-workload-identity-manager
  namespace: ${OPERATOR_NAMESPACE}
spec:
  targetNamespaces:
  - ${OPERATOR_NAMESPACE}
EOF
  fi

  if ! oc get subscription "${SUBSCRIPTION_NAME}" -n "${OPERATOR_NAMESPACE}" >/dev/null 2>&1; then
    log "Creating ZTWIM operator subscription..."
    oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ${SUBSCRIPTION_NAME}
  namespace: ${OPERATOR_NAMESPACE}
spec:
  channel: stable-v1
  installPlanApproval: Automatic
  name: ${PACKAGE_NAME}
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF
  else
    log "ZTWIM operator subscription already exists"
  fi
}

wait_for_operator_csv() {
  log "Waiting for ZTWIM operator CSV to reach Succeeded (up to 15 minutes)..."
  local elapsed=0 phase last_phase=""
  while [[ "${elapsed}" -lt 900 ]]; do
    if operator_csv_ready; then
      log "Operator installed: $(operator_csv_name)"
      return 0
    fi
    phase="$(operator_csv_phase 2>/dev/null || echo "pending")"
    if [[ "${phase}" == "Failed" ]]; then
      recover_failed_operator
    elif [[ "${phase}" != "${last_phase}" ]] || [[ $((elapsed % 60)) -eq 0 ]]; then
      log "  operator CSV phase: ${phase} (${elapsed}s elapsed)"
      last_phase="${phase}"
    fi
    sleep 10
    elapsed=$((elapsed + 10))
  done
  phase="$(operator_csv_phase 2>/dev/null || echo "missing")"
  log "Final operator CSV phase: ${phase}"
  oc get csv,subscription,installplan -n "${OPERATOR_NAMESPACE}" 2>/dev/null \
    | grep -E 'zero-trust|NAME' || true
  err "Timed out waiting for ZTWIM operator CSV"
}

spire_crs_exist() {
  local count
  count="$(oc get zerotrustworkloadidentitymanager,spireserver,spireagent,spiffecsidriver,spireoidcdiscoveryprovider \
    -n "${OPERATOR_NAMESPACE}" --no-headers 2>/dev/null | wc -l | tr -d ' ')"
  [[ "${count}" -ge 5 ]]
}

daemonset_ready() {
  local component="$1"
  local ready desired
  ready="$(oc get daemonset -n "${OPERATOR_NAMESPACE}" -l "app.kubernetes.io/name=${component}" \
    -o jsonpath='{.items[0].status.numberReady}' 2>/dev/null || echo 0)"
  desired="$(oc get daemonset -n "${OPERATOR_NAMESPACE}" -l "app.kubernetes.io/name=${component}" \
    -o jsonpath='{.items[0].status.desiredNumberScheduled}' 2>/dev/null || echo 0)"
  [[ "${ready}" -gt 0 ]] && [[ "${ready}" == "${desired}" ]]
}

spire_server_ready() {
  local ready
  ready="$(oc get pods -n "${OPERATOR_NAMESPACE}" -l app.kubernetes.io/name=spire-server \
    -o jsonpath='{.items[0].status.containerStatuses[*].ready}' 2>/dev/null || true)"
  [[ "${ready}" == "true true" ]]
}

csi_driver_registered() {
  oc get csidriver csi.spiffe.io >/dev/null 2>&1
}

clusterspiffeid_crd_exists() {
  oc get crd clusterspiffeids.spire.spiffe.io >/dev/null 2>&1
}

check_platform_ready() {
  local failures=0

  log "Checking ZTWIM platform readiness..."

  if operator_csv_ready; then
    log "  [OK] ZTWIM operator CSV Succeeded"
  else
    local phase
    phase="$(operator_csv_phase 2>/dev/null || echo "missing")"
    log "  [FAIL] ZTWIM operator CSV not Succeeded (phase: ${phase})"
    failures=$((failures + 1))
  fi

  if spire_crs_exist; then
    log "  [OK] SPIRE custom resources present"
  else
    log "  [FAIL] SPIRE custom resources missing"
    failures=$((failures + 1))
  fi

  if spire_server_ready; then
    log "  [OK] SPIRE server pod ready (2/2)"
  else
    log "  [FAIL] SPIRE server pod not ready"
    failures=$((failures + 1))
  fi

  if daemonset_ready spire-agent; then
    log "  [OK] SPIRE agents ready"
  else
    log "  [FAIL] SPIRE agents not ready"
    failures=$((failures + 1))
  fi

  if daemonset_ready spire-spiffe-csi-driver; then
    log "  [OK] SPIFFE CSI driver DaemonSet ready"
  else
    log "  [FAIL] SPIFFE CSI driver DaemonSet not ready"
    failures=$((failures + 1))
  fi

  if csi_driver_registered; then
    log "  [OK] CSI driver csi.spiffe.io registered"
  else
    log "  [FAIL] CSI driver csi.spiffe.io not registered"
    failures=$((failures + 1))
  fi

  if clusterspiffeid_crd_exists; then
    log "  [OK] ClusterSPIFFEID CRD exists"
  else
    log "  [FAIL] ClusterSPIFFEID CRD missing"
    failures=$((failures + 1))
  fi

  log "Trust domain: ${TRUST_DOMAIN}"
  return "${failures}"
}

print_platform_status() {
  oc get csv -n "${OPERATOR_NAMESPACE}" 2>/dev/null | grep -E 'zero-trust|NAME' || true
  oc get zerotrustworkloadidentitymanager,spireserver,spireagent,spiffecsidriver,spireoidcdiscoveryprovider \
    -n "${OPERATOR_NAMESPACE}" 2>/dev/null || true
  oc get pods -n "${OPERATOR_NAMESPACE}" 2>/dev/null || true
  oc get csidriver csi.spiffe.io 2>/dev/null || true
}

install_operator() {
  if operator_csv_ready; then
    log "ZTWIM operator CSV already Succeeded; skipping operator install"
    return 0
  fi

  recover_failed_operator
  ensure_operator_subscription
  wait_for_operator_csv
}

configure_spire() {
  log "Applying SPIRE custom resources..."
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

wait_for_workloads() {
  log "Waiting for SPIRE server pod..."
  oc wait --for=condition=Ready pod -l app.kubernetes.io/name=spire-server \
    -n "${OPERATOR_NAMESPACE}" --timeout=300s

  for component in spire-agent spire-spiffe-csi-driver; do
    log "Waiting for ${component} DaemonSet..."
    local elapsed=0
    while [[ "${elapsed}" -lt 300 ]]; do
      if daemonset_ready "${component}"; then
        local ready desired
        ready="$(oc get daemonset -n "${OPERATOR_NAMESPACE}" -l "app.kubernetes.io/name=${component}" \
          -o jsonpath='{.items[0].status.numberReady}')"
        desired="$(oc get daemonset -n "${OPERATOR_NAMESPACE}" -l "app.kubernetes.io/name=${component}" \
          -o jsonpath='{.items[0].status.desiredNumberScheduled}')"
        log "${component} ready (${ready}/${desired})"
        break
      fi
      sleep 5
      elapsed=$((elapsed + 5))
    done
    daemonset_ready "${component}" || err "${component} did not become ready within 5 minutes"
  done
}

setup_platform() {
  require_oc
  detect_cluster_config
  cleanup_legacy_operator_namespace

  if check_platform_ready; then
    log "ZTWIM platform is already ready."
    print_platform_status
    log "Next: ./configure-ztwim-postgresql-lab.sh deploy"
    return 0
  fi

  log "ZTWIM platform is not ready; configuring..."

  install_operator
  operator_csv_ready || err "ZTWIM operator is required before SPIRE configuration"

  if ! spire_crs_exist; then
    configure_spire
  else
    log "SPIRE custom resources already exist; skipping apply"
  fi

  wait_for_workloads

  if ! check_platform_ready; then
    log "Platform status after configuration:"
    print_platform_status
    local csv
    csv="$(operator_csv_name)"
    if [[ -n "${csv}" ]]; then
      log "Operator CSV details:"
      oc describe csv "${csv}" -n "${OPERATOR_NAMESPACE}" 2>/dev/null | tail -25 || true
    fi
    err "ZTWIM platform readiness check failed"
  fi

  log "ZTWIM platform is ready."
  print_platform_status
  log "Next: ./configure-ztwim-postgresql-lab.sh deploy"
}

verify_only() {
  require_oc
  detect_cluster_config
  if check_platform_ready; then
    log "ZTWIM platform is ready."
    print_platform_status
    return 0
  fi
  log "Platform status:"
  print_platform_status
  err "ZTWIM platform is not ready"
}

usage() {
  cat <<EOF
Usage: $0 [setup|check]

  setup  Configure SPIRE (if needed), wait for workloads, verify readiness (default)
  check  Verify platform readiness only; exit non-zero if not ready

Environment:
  OPERATOR_NAMESPACE  Default: zero-trust-workload-identity-manager
  ZTWIM_PACKAGE         OLM package name (default: zero-trust-workload-identity-manager)
  ZTWIM_SUBSCRIPTION_NAME  Subscription metadata name (default: openshift-zero-trust-workload-identity-manager)
EOF
}

case "${INSTALL_MODE}" in
  setup|"")
    setup_platform
    ;;
  check|verify)
    verify_only
    ;;
  -h|--help|help)
    usage
    ;;
  spire-only)
    log "Note: 'spire-only' is deprecated; use default 'setup' mode instead"
    setup_platform
    ;;
  *)
    err "Unknown mode: ${INSTALL_MODE}. Run $0 --help"
    ;;
esac
