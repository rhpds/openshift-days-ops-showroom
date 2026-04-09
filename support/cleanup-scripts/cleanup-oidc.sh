#!/bin/bash
# Cleanup script for Module 08 - OIDC Authentication
# Restores OAuth to htpasswd only, removes Keycloak and OIDC resources

echo "Cleaning up OIDC resources..."

# Restore OAuth to htpasswd only
cat <<'EOF' | oc apply -f -
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: htpasswd
    mappingMethod: claim
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpasswd
EOF

# Delete client secret and OIDC users/groups
oc delete secret rhbk-client-secret -n openshift-config --ignore-not-found
oc delete user developer1 admin1 viewer1 --ignore-not-found
oc delete group ocp-admins ocp-developers ocp-viewers --ignore-not-found

# Delete RHBK namespace, projects, and wait for OAuth rollout in the background
(
  oc delete namespace rhbk --ignore-not-found
  oc delete project app-development app-production --ignore-not-found
  oc rollout status deployment/oauth-openshift -n openshift-authentication --timeout=120s
) &>/dev/null &

echo "Cleanup running in background — you can continue to the next module"
