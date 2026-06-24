#!/usr/bin/env bash
# Configure the ZTWIM platform for the PostgreSQL SPIFFE mTLS workshop lab.
# 1. Discover what is already deployed on the cluster
# 2. Apply only what is missing for the lab example
# 3. Verify the platform is ready before exiting
#
# Upstream alignment: Roadshow-ZTWIM scripts/00-install-ztwim-operator.sh
set -euo pipefail

DEFAULT_OPERATOR_NAMESPACE="openshift-zero-trust-workload-identity-manager"
OPERATOR_NAMESPACE="${OPERATOR_NAMESPACE:-}"
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

namespace_has_operator_artifacts() {
  local ns="$1"
  oc get namespace "${ns}" >/dev/null 2>&1 || return 1
  oc get subscription -n "${ns}" 2>/dev/null | grep -qE 'zero-trust|openshift-zero-trust' && return 0
  oc get csv -n "${ns}" 2>/dev/null | grep -q 'zero-trust-workload-identity-manager' && return 0
  oc get pods -n "${ns}" --no-headers 2>/dev/null \
    | grep -qE 'controller-manager|zero-trust-workload-identity-manager' && return 0
  return 1
}

detect_operator_namespace() {
  if [[ -n "${OPERATOR_NAMESPACE}" ]]; then
    log "Operator namespace: ${OPERATOR_NAMESPACE} (from environment)"
    return 0
  fi

  local ns
  for ns in "${DEFAULT_OPERATOR_NAMESPACE}" zero-trust-workload-identity-manager; do
    if namespace_has_operator_artifacts "${ns}"; then
      OPERATOR_NAMESPACE="${ns}"
      log "Operator namespace: ${OPERATOR_NAMESPACE} (detected)"
      return 0
    fi
  done

  OPERATOR_NAMESPACE="${DEFAULT_OPERATOR_NAMESPACE}"
  log "Operator namespace: ${OPERATOR_NAMESPACE} (default)"
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

operator_controller_ready() {
  local ready
  ready="$(oc get pods -n "${OPERATOR_NAMESPACE}" \
    -l app.kubernetes.io/name=zero-trust-workload-identity-manager \
    -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true)"
  if [[ "${ready}" == "True" ]]; then
    return 0
  fi
  oc get pods -n "${OPERATOR_NAMESPACE}" --no-headers 2>/dev/null \
    | grep -E 'controller-manager' | grep -q 'Running'
}

operator_subscription_exists() {
  oc get subscription "${SUBSCRIPTION_NAME}" -n "${OPERATOR_NAMESPACE}" >/dev/null 2>&1
}

operator_usable() {
  operator_csv_ready || operator_controller_ready
}

spire_crs_exist() {
  local count
  count="$(oc get zerotrustworkloadidentitymanager,spireserver,spireagent,spiffecsidriver,spireoidcdiscoveryprovider \
    -n "${OPERATOR_NAMESPACE}" --no-headers 2>/dev/null | wc -l | tr -d ' ')"
  [[ "${count}" -ge 5 ]]
}

remove_misplaced_spire_crs() {
  local count
  count="$(oc get zerotrustworkloadidentitymanager,spireserver,spireagent,spiffecsidriver,spireoidcdiscoveryprovider \
    -n default --no-headers 2>/dev/null | wc -l | tr -d ' ')"
  if [[ "${count}" -gt 0 ]]; then
    log "Removing SPIRE custom resources from default namespace (belong in ${OPERATOR_NAMESPACE})..."
    oc delete zerotrustworkloadidentitymanager,spireserver,spireagent,spiffecsidriver,spireoidcdiscoveryprovider \
      cluster -n default --ignore-not-found --timeout=120s 2>/dev/null || true
  fi
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

survey_platform() {
  log "=== Deployed state (PostgreSQL SPIFFE lab prerequisites) ==="

  if operator_csv_ready; then
    log "  operator CSV: Succeeded ($(operator_csv_name))"
  elif operator_controller_ready; then
    log "  operator CSV: $(operator_csv_phase 2>/dev/null || echo missing) (controller running)"
  elif operator_subscription_exists; then
    log "  operator: subscription present, controller not ready yet"
  else
    log "  operator: not found in ${OPERATOR_NAMESPACE}"
  fi

  if spire_crs_exist; then
    log "  SPIRE custom resources: present"
  else
    log "  SPIRE custom resources: missing"
  fi

  if spire_server_ready; then
    log "  SPIRE server: ready (2/2)"
  else
    log "  SPIRE server: not ready"
  fi

  if daemonset_ready spire-agent; then
    log "  SPIRE agents: ready"
  else
    log "  SPIRE agents: not ready"
  fi

  if daemonset_ready spire-spiffe-csi-driver; then
    log "  SPIFFE CSI driver: ready"
  else
    log "  SPIFFE CSI driver: not ready"
  fi

  if csi_driver_registered; then
    log "  CSI driver csi.spiffe.io: registered"
  else
    log "  CSI driver csi.spiffe.io: not registered"
  fi

  if clusterspiffeid_crd_exists; then
    log "  ClusterSPIFFEID CRD: present"
  else
    log "  ClusterSPIFFEID CRD: missing"
  fi
}

check_platform_ready() {
  local failures=0

  log "=== Readiness check ==="

  if operator_csv_ready; then
    log "  [OK] ZTWIM operator CSV Succeeded"
  elif operator_controller_ready; then
    local phase
    phase="$(operator_csv_phase 2>/dev/null || echo "missing")"
    log "  [OK] ZTWIM operator controller running (CSV phase: ${phase})"
  else
    local phase
    phase="$(operator_csv_phase 2>/dev/null || echo "missing")"
    log "  [FAIL] ZTWIM operator not ready (CSV phase: ${phase})"
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

  return "${failures}"
}

print_platform_status() {
  oc get csv -n "${OPERATOR_NAMESPACE}" 2>/dev/null | grep -E 'zero-trust|NAME' || true
  oc get zerotrustworkloadidentitymanager,spireserver,spireagent,spiffecsidriver,spireoidcdiscoveryprovider \
    -n "${OPERATOR_NAMESPACE}" 2>/dev/null || true
  oc get pods -n "${OPERATOR_NAMESPACE}" 2>/dev/null || true
  oc get csidriver csi.spiffe.io 2>/dev/null || true
}

ensure_operator_subscription() {
  oc create namespace "${OPERATOR_NAMESPACE}" --dry-run=client -o yaml | oc apply -f -

  if ! oc get operatorgroup zero-trust-workload-identity-manager -n "${OPERATOR_NAMESPACE}" >/dev/null 2>&1; then
    log "Creating OperatorGroup..."
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

  if ! operator_subscription_exists; then
    log "Creating operator subscription..."
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
  fi
}

wait_for_operator() {
  if operator_usable; then
    return 0
  fi

  if operator_subscription_exists; then
    log "Waiting for operator controller in ${OPERATOR_NAMESPACE} (up to 5 minutes)..."
    local elapsed=0
    while [[ "${elapsed}" -lt 300 ]]; do
      if operator_usable; then
        local phase
        phase="$(operator_csv_phase 2>/dev/null || echo "missing")"
        log "Operator is usable (CSV phase: ${phase})"
        return 0
      fi
      sleep 10
      elapsed=$((elapsed + 10))
      if [[ $((elapsed % 30)) -eq 0 ]]; then
        log "  still waiting (${elapsed}s)..."
      fi
    done
    err "Operator controller did not become ready within 5 minutes"
  fi

  ensure_operator_subscription
  log "Waiting for operator install in ${OPERATOR_NAMESPACE} (up to 15 minutes)..."
  local elapsed=0 phase last_phase=""
  while [[ "${elapsed}" -lt 900 ]]; do
    if operator_usable; then
      local csv_phase
      csv_phase="$(operator_csv_phase 2>/dev/null || echo "missing")"
      log "Operator is usable (CSV phase: ${csv_phase})"
      return 0
    fi
    phase="$(operator_csv_phase 2>/dev/null || echo "pending")"
    if [[ "${phase}" != "${last_phase}" ]] || [[ $((elapsed % 60)) -eq 0 ]]; then
      log "  operator CSV phase: ${phase} (${elapsed}s elapsed)"
      last_phase="${phase}"
    fi
    sleep 10
    elapsed=$((elapsed + 10))
  done
  err "Timed out waiting for ZTWIM operator"
}

configure_spire() {
  log "Applying SPIRE custom resources for the PostgreSQL SPIFFE lab..."
  oc apply -f - <<EOF
apiVersion: operator.openshift.io/v1alpha1
kind: ZeroTrustWorkloadIdentityManager
metadata:
  name: cluster
  namespace: ${OPERATOR_NAMESPACE}
spec:
  trustDomain: ${TRUST_DOMAIN}
  clusterName: ${CLUSTER_NAME}
  bundleConfigMap: spire-bundle
---
apiVersion: operator.openshift.io/v1alpha1
kind: SpireServer
metadata:
  name: cluster
  namespace: ${OPERATOR_NAMESPACE}
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
  namespace: ${OPERATOR_NAMESPACE}
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
  namespace: ${OPERATOR_NAMESPACE}
spec:
  agentSocketPath: /run/spire/agent-sockets
---
apiVersion: operator.openshift.io/v1alpha1
kind: SpireOIDCDiscoveryProvider
metadata:
  name: cluster
  namespace: ${OPERATOR_NAMESPACE}
spec:
  jwtIssuer: https://spire-spiffe-oidc-discovery-provider.${CLUSTER_DOMAIN}
  managedRoute: "true"
EOF
}

wait_for_spire_server() {
  log "Waiting for SPIRE server pod..."
  local elapsed=0
  while [[ "${elapsed}" -lt 300 ]]; do
    if spire_server_ready; then
      log "SPIRE server ready (2/2)"
      return 0
    fi
    local count
    count="$(oc get pods -n "${OPERATOR_NAMESPACE}" -l app.kubernetes.io/name=spire-server \
      --no-headers 2>/dev/null | wc -l | tr -d ' ')"
    if [[ "${count}" -gt 0 ]]; then
      oc wait --for=condition=Ready pod -l app.kubernetes.io/name=spire-server \
        -n "${OPERATOR_NAMESPACE}" --timeout=60s 2>/dev/null || true
    elif [[ $((elapsed % 30)) -eq 0 ]]; then
      log "  waiting for SPIRE server pod to appear (${elapsed}s)..."
    fi
    sleep 5
    elapsed=$((elapsed + 5))
  done
  err "SPIRE server did not become ready within 5 minutes"
}

wait_for_workloads() {
  if ! spire_server_ready; then
    wait_for_spire_server
  else
    log "SPIRE server already ready"
  fi

  for component in spire-agent spire-spiffe-csi-driver; do
    if daemonset_ready "${component}"; then
      log "${component} already ready"
      continue
    fi
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
      if [[ $((elapsed % 30)) -eq 0 ]] && [[ "${elapsed}" -gt 0 ]]; then
        log "  waiting for ${component} (${elapsed}s)..."
      fi
      sleep 5
      elapsed=$((elapsed + 5))
    done
    daemonset_ready "${component}" || err "${component} did not become ready within 5 minutes"
  done
}

ensure_lab_platform() {
  if ! operator_usable; then
    log "Operator not ready — installing or waiting for existing subscription..."
    wait_for_operator
  else
    log "Operator already usable — skipping install"
  fi

  if ! spire_crs_exist; then
    remove_misplaced_spire_crs
    configure_spire
  else
    log "SPIRE custom resources already present — skipping apply"
  fi

  if ! spire_server_ready || ! daemonset_ready spire-agent || ! daemonset_ready spire-spiffe-csi-driver; then
    wait_for_workloads
  else
    log "SPIRE workloads already ready — skipping wait"
  fi
}

setup_platform() {
  require_oc
  detect_cluster_config
  detect_operator_namespace
  survey_platform

  if check_platform_ready; then
    log "ZTWIM platform is ready for the PostgreSQL SPIFFE lab."
    log "Next: ./configure-ztwim-postgresql-lab.sh deploy"
    return 0
  fi

  log "Configuring missing components..."
  ensure_lab_platform

  if ! check_platform_ready; then
    log "Platform status after configuration:"
    print_platform_status
    err "ZTWIM platform is not ready for the PostgreSQL SPIFFE lab"
  fi

  log "ZTWIM platform is ready for the PostgreSQL SPIFFE lab."
  print_platform_status
  log "Next: ./configure-ztwim-postgresql-lab.sh deploy"
}

verify_only() {
  require_oc
  detect_cluster_config
  detect_operator_namespace
  survey_platform
  if check_platform_ready; then
    log "ZTWIM platform is ready for the PostgreSQL SPIFFE lab."
    return 0
  fi
  log "Platform status:"
  print_platform_status
  err "ZTWIM platform is not ready for the PostgreSQL SPIFFE lab"
}

usage() {
  cat <<EOF
Usage: $0 [setup|check]

  setup  Discover deployed state, configure gaps, verify readiness (default)
  check  Survey and verify readiness only; exit non-zero if not ready

Environment:
  OPERATOR_NAMESPACE       Operator namespace (auto-detected when unset)
  ZTWIM_PACKAGE            OLM package name (default: zero-trust-workload-identity-manager)
  ZTWIM_SUBSCRIPTION_NAME  Subscription name (default: openshift-zero-trust-workload-identity-manager)
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
