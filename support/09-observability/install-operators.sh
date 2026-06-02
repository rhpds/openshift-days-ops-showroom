#!/bin/bash
set -euo pipefail

oc create namespace openshift-logging 2>/dev/null || true
oc create namespace openshift-operators-redhat 2>/dev/null || true

# Create OperatorGroups only if they don't already exist (manual install may have created them)
if ! oc get operatorgroup -n openshift-logging --no-headers 2>/dev/null | grep -q .; then
  oc apply -f - <<OGEOF
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: openshift-logging
  namespace: openshift-logging
spec:
  targetNamespaces:
    - openshift-logging
OGEOF
fi

if ! oc get operatorgroup -n openshift-operators-redhat --no-headers 2>/dev/null | grep -q .; then
  oc apply -f - <<OGEOF
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: openshift-operators-redhat
  namespace: openshift-operators-redhat
spec: {}
OGEOF
fi

# Install Loki operator if not already installed (manual console install may have done this)
if ! oc get sub loki-operator -n openshift-operators-redhat 2>/dev/null | grep -q loki; then
  oc apply -f - <<LOKIEOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: loki-operator
  namespace: openshift-operators-redhat
spec:
  channel: stable-6.2
  installPlanApproval: Automatic
  name: loki-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
LOKIEOF
fi

cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: cluster-logging
  namespace: openshift-logging
spec:
  channel: stable-6.2
  installPlanApproval: Automatic
  name: cluster-logging
  source: redhat-operators
  sourceNamespace: openshift-marketplace
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: cluster-observability-operator
  namespace: openshift-operators
spec:
  channel: stable
  installPlanApproval: Automatic
  name: cluster-observability-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: tempo-product
  namespace: openshift-operators
spec:
  channel: stable
  installPlanApproval: Automatic
  name: tempo-product
  source: redhat-operators
  sourceNamespace: openshift-marketplace
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: opentelemetry-product
  namespace: openshift-operators
spec:
  channel: stable
  installPlanApproval: Automatic
  name: opentelemetry-product
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF
echo "Logging, COO, Tempo, and OpenTelemetry subscriptions created"

echo "Waiting for all 5 operators (this may take a few minutes)..."
TIMEOUT=600; ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
  READY=0
  oc get csv -n openshift-operators-redhat --no-headers 2>/dev/null | grep "^loki-operator" | grep -q "Succeeded" && READY=$((READY+1))
  oc get csv -n openshift-logging --no-headers 2>/dev/null | grep "^cluster-logging" | grep -q "Succeeded" && READY=$((READY+1))
  oc get csv -n openshift-operators --no-headers 2>/dev/null | grep "^cluster-observability" | grep -q "Succeeded" && READY=$((READY+1))
  oc get csv -n openshift-operators --no-headers 2>/dev/null | grep "^tempo-operator" | grep -q "Succeeded" && READY=$((READY+1))
  oc get csv -n openshift-operators --no-headers 2>/dev/null | grep "^opentelemetry-operator" | grep -q "Succeeded" && READY=$((READY+1))
  echo "  ${READY}/5 operators ready"
  [ $READY -eq 5 ] && break
  sleep 15; ELAPSED=$((ELAPSED+15))
done
[ $READY -eq 5 ] && echo "All operators installed" || echo "ERROR: Timed out - check Ecosystem -> Installed Operators"
