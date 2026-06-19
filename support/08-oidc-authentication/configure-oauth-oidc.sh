#!/bin/bash
set -euo pipefail

KEYCLOAK_URL=$(oc get route keycloak -n rhbk -o jsonpath='{.spec.host}')

GEN=$(oc get deployment oauth-openshift -n openshift-authentication -o jsonpath='{.metadata.generation}')

cat <<EOF | oc apply -f -
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
  - name: rhbk
    mappingMethod: claim
    type: OpenID
    openID:
      clientID: openshift
      clientSecret:
        name: rhbk-client-secret
      issuer: https://${KEYCLOAK_URL}/realms/OpenShift
      claims:
        preferredUsername:
        - preferred_username
        name:
        - name
        email:
        - email
        groups:
        - groups
      extraScopes:
      - email
      - profile
EOF

echo "Waiting for OAuth pods to restart with new config..."
ELAPSED=0
until [ "$(oc get deployment oauth-openshift -n openshift-authentication -o jsonpath='{.metadata.generation}')" -gt "$GEN" ] 2>/dev/null; do
  sleep 2; ELAPSED=$((ELAPSED+2))
  [ $ELAPSED -ge 60 ] && echo "Warning: OAuth operator slow to pick up config change" && break
done

oc rollout status deployment/oauth-openshift -n openshift-authentication --timeout=120s

ELAPSED=0
until [ "$(oc get pods -n openshift-authentication -l app=oauth-openshift --no-headers 2>/dev/null | grep -c '1/1.*Running')" -ge 3 ]; do
  sleep 5; ELAPSED=$((ELAPSED+5))
  [ $ELAPSED -ge 180 ] && echo "ERROR: Timed out waiting for OAuth pods" && break
done
echo "OAuth is live with rhbk provider - reload the console to see the new login option"
