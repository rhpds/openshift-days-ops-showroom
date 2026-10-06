#!/bin/bash
set -euo pipefail

cat <<EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: rhbk
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: rhbk
  namespace: rhbk
spec:
  targetNamespaces:
  - rhbk
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: rhbk-operator
  namespace: rhbk
spec:
  channel: stable-v26
  installPlanApproval: Automatic
  name: rhbk-operator
  # rhbk-operator is not in the live redhat-operators index;
  # only available in the pinned snapshot catalog.
  source: redhat-operators-snapshot
  sourceNamespace: openshift-marketplace
EOF

echo "Waiting for RHBK operator..."
until oc get csv -n rhbk 2>/dev/null | grep rhbk-operator | grep -q Succeeded; do sleep 10; done
echo "Waiting for Keycloak CRD..."
until oc get crd keycloaks.k8s.keycloak.org 2>/dev/null | grep -q keycloaks; do sleep 5; done
echo "RHBK operator ready"
