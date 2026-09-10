#!/bin/bash
# Cleanup script for Module 14 - ACM Multi-Cluster Management
# Removes resources created during the module without touching pre-existing infrastructure
set -euo pipefail

echo "=== Cleaning up ACM module resources ==="

# 1. Delete the GDPR policies, placement, and binding
echo "Removing EMEA compliance policies..."
oc delete placementbinding binding-emea-namespace-compliance -n policies --ignore-not-found
oc delete placement placement-policy-emea-namespace-compliance -n policies --ignore-not-found
oc delete policy policy-emea-namespace-compliance -n policies --ignore-not-found

# 2. Delete the ApplicationSet (this also removes deployed apps from managed clusters)
echo "Removing skupper-patient-demo ApplicationSet..."
oc delete applicationset skupper-patient-demo -n openshift-gitops --ignore-not-found

# 3. Delete the ArgoCD server registration and its placement
echo "Removing ArgoCD global server registration..."
oc delete gitopscluster openshift-gitops-global -n openshift-gitops --ignore-not-found
oc delete placement openshift-gitops-global-placement -n openshift-gitops --ignore-not-found
oc delete placement skupper-patient-demo-placement -n openshift-gitops --ignore-not-found

# 4. Delete the lab VM (NOT rhel-webserver which is pre-existing)
echo "Removing lab VM..."
oc delete vm rhel9-lab-vm -n default --ignore-not-found --wait=false

# 5. Delete the HCP EMEA cluster (this takes a few minutes)
echo "Removing hcp-emea hosted cluster (this may take several minutes)..."
oc delete hostedcluster hcp-emea -n clusters --ignore-not-found --wait=false

echo "=== ACM module cleanup initiated ==="
echo "Note: The hcp-emea cluster deletion runs in the background."
echo "The clusters-hcp-emea namespace will be removed automatically once the cluster is fully deleted."
