#!/bin/bash
# Cleanup script for Module 12 - Developer Hub
# Reverts the Backstage CR plugin configuration and removes created resources

echo "Cleaning up Developer Hub resources..."

# Revert the Backstage CR to remove plugin configuration
oc patch backstage developer-hub -n backstage --type=merge -p '{
  "spec": {
    "application": {
      "dynamicPluginsConfigMapName": null,
      "extraEnvs": null
    }
  }
}' 2>/dev/null || true

# Remove the service account, token, and plugin configmap
oc delete sa rhdh-kubernetes-plugin -n backstage --ignore-not-found
oc delete secret rhdh-kubernetes-plugin-token -n backstage --ignore-not-found
oc delete configmap dynamic-plugins-rhdh -n backstage --ignore-not-found

# Wait for the rollout to complete
oc rollout status deployment/backstage-developer-hub -n backstage --timeout=300s 2>/dev/null || true

echo "Cleanup complete"
