#!/bin/bash
# Setup Red Hat build of Keycloak (RHBK) for OpenShift OIDC Authentication
# Creates realm, users, groups, and OIDC client configuration

set -e

echo "=== Keycloak OIDC Setup Script (RHBK) ==="

# Get Keycloak credentials - RHBK uses keycloak-initial-admin secret
KEYCLOAK_URL="https://$(oc get route keycloak -n rhbk -o jsonpath='{.spec.host}')"
ADMIN_USER=$(oc get secret keycloak-initial-admin -n rhbk -o jsonpath='{.data.username}' | base64 -d)
ADMIN_PASS=$(oc get secret keycloak-initial-admin -n rhbk -o jsonpath='{.data.password}' | base64 -d)

echo "Keycloak URL: $KEYCLOAK_URL"
echo "Admin User: $ADMIN_USER"

# Get admin token - RHBK v26 has no /auth prefix
echo "Getting admin token..."
TOKEN=$(curl -sk -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "username=${ADMIN_USER}" \
  --data-urlencode "password=${ADMIN_PASS}" \
  --data-urlencode "grant_type=password" \
  --data-urlencode "client_id=admin-cli" | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))")

if [ -z "$TOKEN" ]; then
  echo "ERROR: Failed to get admin token"
  exit 1
fi
echo "Got admin token"

# Create OpenShift realm
echo "Creating OpenShift realm..."
curl -sk -X POST "${KEYCLOAK_URL}/admin/realms" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "realm": "OpenShift",
    "enabled": true,
    "registrationAllowed": false,
    "loginWithEmailAllowed": false,
    "duplicateEmailsAllowed": false,
    "resetPasswordAllowed": false,
    "editUsernameAllowed": false,
    "bruteForceProtected": true
  }' || echo "(realm may already exist)"

# Refresh token
sleep 2
TOKEN=$(curl -sk -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "username=${ADMIN_USER}" \
  --data-urlencode "password=${ADMIN_PASS}" \
  --data-urlencode "grant_type=password" \
  --data-urlencode "client_id=admin-cli" | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))")

# Create groups
echo "Creating groups..."
for GROUP in ocp-admins ocp-developers ocp-viewers; do
  curl -sk -X POST "${KEYCLOAK_URL}/admin/realms/OpenShift/groups" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"$GROUP\"}" || echo "(group $GROUP may already exist)"
done

# Get group IDs
echo "Getting group IDs..."
ADMIN_GROUP_ID=$(curl -sk "${KEYCLOAK_URL}/admin/realms/OpenShift/groups?search=ocp-admins" \
  -H "Authorization: Bearer $TOKEN" | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")
DEV_GROUP_ID=$(curl -sk "${KEYCLOAK_URL}/admin/realms/OpenShift/groups?search=ocp-developers" \
  -H "Authorization: Bearer $TOKEN" | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")
VIEWER_GROUP_ID=$(curl -sk "${KEYCLOAK_URL}/admin/realms/OpenShift/groups?search=ocp-viewers" \
  -H "Authorization: Bearer $TOKEN" | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")

echo "Group IDs: admins=$ADMIN_GROUP_ID, devs=$DEV_GROUP_ID, viewers=$VIEWER_GROUP_ID"

# Create users and assign to groups
echo "Creating users..."
PASSWORD="OpenShift123!"

create_user() {
  local USERNAME=$1
  local FIRSTNAME=$2
  local GROUP_ID=$3

  # Create user without credentials (RHBK v26 requires separate password reset)
  curl -sk -X POST "${KEYCLOAK_URL}/admin/realms/OpenShift/users" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"username\": \"$USERNAME\",
      \"enabled\": true,
      \"firstName\": \"$FIRSTNAME\",
      \"lastName\": \"User\",
      \"email\": \"${USERNAME}@example.com\",
      \"emailVerified\": true
    }" || echo "(user $USERNAME may already exist)"

  # Get user ID
  local USER_ID=$(curl -sk "${KEYCLOAK_URL}/admin/realms/OpenShift/users?username=$USERNAME" \
    -H "Authorization: Bearer $TOKEN" | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")

  if [ -n "$USER_ID" ]; then
    # Set password
    curl -sk -X PUT "${KEYCLOAK_URL}/admin/realms/OpenShift/users/$USER_ID/reset-password" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"type\":\"password\",\"value\":\"$PASSWORD\",\"temporary\":false}"

    # Add user to group
    curl -sk -X PUT "${KEYCLOAK_URL}/admin/realms/OpenShift/users/$USER_ID/groups/$GROUP_ID" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" -d '{}'
    echo "Created user $USERNAME and added to group"
  fi
}

create_user "admin1" "Admin" "$ADMIN_GROUP_ID"
create_user "developer1" "Developer" "$DEV_GROUP_ID"
create_user "viewer1" "Viewer" "$VIEWER_GROUP_ID"

# Get OpenShift OAuth callback URL
OAUTH_CALLBACK="https://$(oc get route oauth-openshift -n openshift-authentication -o jsonpath='{.spec.host}')/oauth2callback/rhbk"

# Create OIDC client
echo "Creating OIDC client..."
curl -sk -X POST "${KEYCLOAK_URL}/admin/realms/OpenShift/clients" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"clientId\": \"openshift\",
    \"enabled\": true,
    \"protocol\": \"openid-connect\",
    \"publicClient\": false,
    \"secret\": \"openshift-client-secret\",
    \"redirectUris\": [\"$OAUTH_CALLBACK\"],
    \"webOrigins\": [\"+\"],
    \"standardFlowEnabled\": true,
    \"directAccessGrantsEnabled\": true
  }" || echo "(client may already exist)"

# Add groups protocol mapper
echo "Adding groups protocol mapper..."
CLIENT_UUID=$(curl -sk "${KEYCLOAK_URL}/admin/realms/OpenShift/clients?clientId=openshift" \
  -H "Authorization: Bearer $TOKEN" | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")

curl -sk -X POST "${KEYCLOAK_URL}/admin/realms/OpenShift/clients/$CLIENT_UUID/protocol-mappers/models" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "groups",
    "protocol": "openid-connect",
    "protocolMapper": "oidc-group-membership-mapper",
    "consentRequired": false,
    "config": {
      "full.path": "false",
      "id.token.claim": "true",
      "access.token.claim": "true",
      "claim.name": "groups",
      "userinfo.token.claim": "true"
    }
  }' || echo "(mapper may already exist)"

# Set short session timeouts so logout works cleanly in the workshop
echo "Configuring session timeouts..."
curl -sk -X PUT "${KEYCLOAK_URL}/admin/realms/OpenShift" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"ssoSessionIdleTimeout":60,"ssoSessionMaxLifespan":300}'

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Created in Keycloak:"
echo "  - Realm: OpenShift"
echo "  - Users: admin1, developer1, viewer1"
echo "  - Password: $PASSWORD"
echo "  - Groups: ocp-admins, ocp-developers, ocp-viewers"
echo "  - OIDC Client: openshift"
echo "  - Client Secret: openshift-client-secret"
echo ""
echo "OAuth Callback URL: $OAUTH_CALLBACK"
echo ""
