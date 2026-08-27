#!/bin/bash
set -euo pipefail

cat <<EOF > $HOME/support/oauth-cluster.yaml
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
  - name: ldap                    # name shown on console login page
    mappingMethod: claim           # first identity provider to claim a username wins
    type: LDAP
    ldap:
      attributes:
        id: [dn]                   # LDAP field used as unique user ID
        email: [mail]
        name: [cn]                 # display name
        preferredUsername: [uid]    # what they type at the login prompt
      bindDN: "cn=openshiftworkshop,ou=svcaccts,ou=users,dc=openshiftworkshop,dc=com"
      bindPassword:
        name: ldap-secret          # references the Secret created earlier
      ca:
        name: ca-config-map        # CA cert to validate LDAP server's TLS
      insecure: false              # always false in production - validates TLS
      url: "ldaps://glauth.glauth.svc.cluster.local/ou=users,dc=openshiftworkshop,dc=com?uid?sub?(memberOf=ou=ose-user,ou=groups,dc=openshiftworkshop,dc=com)"
  tokenConfig:
    accessTokenMaxAgeSeconds: 86400  # tokens valid for 24 hours
EOF

echo "Applying OAuth configuration..."
oc apply -f $HOME/support/oauth-cluster.yaml
echo "OAuth configuration applied successfully"
