#!/bin/bash
# Setup Keycloak for OpenShift OIDC Authentication
# Creates realm, users, groups, and OIDC client configuration

set -e

echo "=== Keycloak OIDC Setup Script ==="

# Get Keycloak credentials
KEYCLOAK_URL="https://$(oc get route keycloak -n rhsso -o jsonpath='{.spec.host}')"
ADMIN_USER=$(oc get secret credential-rhsso -n rhsso -o jsonpath='{.data.ADMIN_USERNAME}' | base64 -d)
ADMIN_PASS=$(oc get secret credential-rhsso -n rhsso -o jsonpath='{.data.ADMIN_PASSWORD}' | base64 -d)

echo "Keycloak URL: $KEYCLOAK_URL"
echo "Admin User: $ADMIN_USER"

# Get admin token
echo "Getting admin token..."
TOKEN=$(curl -sk -X POST "${KEYCLOAK_URL}/auth/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=${ADMIN_USER}" \
  -d "password=${ADMIN_PASS}" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "ERROR: Failed to get admin token"
  exit 1
fi
echo "Got admin token"

# Create OpenShift realm
echo "Creating openshift realm..."
curl -sk -X POST "${KEYCLOAK_URL}/auth/admin/realms" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "realm": "openshift",
    "enabled": true,
    "registrationAllowed": false,
    "loginWithEmailAllowed": false,
    "duplicateEmailsAllowed": false,
    "resetPasswordAllowed": false,
    "editUsernameAllowed": false,
    "bruteForceProtected": true
  }' || echo "(realm may already exist)"

# Refresh token for new realm operations
sleep 2
TOKEN=$(curl -sk -X POST "${KEYCLOAK_URL}/auth/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=${ADMIN_USER}" \
  -d "password=${ADMIN_PASS}" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token')

# Create groups
echo "Creating groups..."
for GROUP in ocp-admins ocp-developers ocp-viewers; do
  curl -sk -X POST "${KEYCLOAK_URL}/auth/admin/realms/openshift/groups" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"$GROUP\"}" || echo "(group $GROUP may already exist)"
done

# Get group IDs
echo "Getting group IDs..."
ADMIN_GROUP_ID=$(curl -sk "${KEYCLOAK_URL}/auth/admin/realms/openshift/groups?search=ocp-admins" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.[0].id')
DEV_GROUP_ID=$(curl -sk "${KEYCLOAK_URL}/auth/admin/realms/openshift/groups?search=ocp-developers" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.[0].id')
VIEWER_GROUP_ID=$(curl -sk "${KEYCLOAK_URL}/auth/admin/realms/openshift/groups?search=ocp-viewers" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.[0].id')

echo "Group IDs: admins=$ADMIN_GROUP_ID, devs=$DEV_GROUP_ID, viewers=$VIEWER_GROUP_ID"

# Create users
echo "Creating users..."
PASSWORD="OpenShift123!"

create_user() {
  local USERNAME=$1
  local GROUP_ID=$2

  # Create user
  curl -sk -X POST "${KEYCLOAK_URL}/auth/admin/realms/openshift/users" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"username\": \"$USERNAME\",
      \"enabled\": true,
      \"emailVerified\": true,
      \"credentials\": [{
        \"type\": \"password\",
        \"value\": \"$PASSWORD\",
        \"temporary\": false
      }]
    }" || echo "(user $USERNAME may already exist)"

  # Get user ID
  USER_ID=$(curl -sk "${KEYCLOAK_URL}/auth/admin/realms/openshift/users?username=$USERNAME" \
    -H "Authorization: Bearer $TOKEN" | jq -r '.[0].id')

  if [ -n "$USER_ID" ] && [ "$USER_ID" != "null" ]; then
    # Add user to group
    curl -sk -X PUT "${KEYCLOAK_URL}/auth/admin/realms/openshift/users/$USER_ID/groups/$GROUP_ID" \
      -H "Authorization: Bearer $TOKEN"
    echo "Created user $USERNAME and added to group"
  fi
}

create_user "admin1" "$ADMIN_GROUP_ID"
create_user "developer1" "$DEV_GROUP_ID"
create_user "viewer1" "$VIEWER_GROUP_ID"

# Get OpenShift OAuth callback URL
OAUTH_CALLBACK="https://$(oc get route oauth-openshift -n openshift-authentication -o jsonpath='{.spec.host}')/oauth2callback/rhsso"

# Create OIDC client
echo "Creating OIDC client..."
curl -sk -X POST "${KEYCLOAK_URL}/auth/admin/realms/openshift/clients" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"clientId\": \"openshift-cluster\",
    \"enabled\": true,
    \"protocol\": \"openid-connect\",
    \"publicClient\": false,
    \"secret\": \"openshift-client-secret\",
    \"redirectUris\": [\"$OAUTH_CALLBACK\"],
    \"webOrigins\": [\"+\"],
    \"standardFlowEnabled\": true,
    \"directAccessGrantsEnabled\": true,
    \"protocolMappers\": [{
      \"name\": \"groups\",
      \"protocol\": \"openid-connect\",
      \"protocolMapper\": \"oidc-group-membership-mapper\",
      \"consentRequired\": false,
      \"config\": {
        \"full.path\": \"false\",
        \"id.token.claim\": \"true\",
        \"access.token.claim\": \"true\",
        \"claim.name\": \"groups\",
        \"userinfo.token.claim\": \"true\"
      }
    }]
  }" || echo "(client may already exist)"

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Created in Keycloak:"
echo "  - Realm: openshift"
echo "  - Users: admin1, developer1, viewer1"
echo "  - Password: $PASSWORD"
echo "  - Groups: ocp-admins, ocp-developers, ocp-viewers"
echo "  - OIDC Client: openshift-cluster"
echo "  - Client Secret: openshift-client-secret"
echo ""
echo "OAuth Callback URL: $OAUTH_CALLBACK"
echo ""
