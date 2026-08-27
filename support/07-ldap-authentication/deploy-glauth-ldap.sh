#!/bin/bash
set -euo pipefail

NAMESPACE="glauth"
CERT_DIR="$HOME/support/glauth-tls"
APPS_DOMAIN=$(oc get ingresses.config/cluster -o jsonpath='{.spec.domain}')
ROUTE_HOST="glauth-glauth.$APPS_DOMAIN"

oc new-project "$NAMESPACE" >/dev/null 2>&1 || oc project "$NAMESPACE" >/dev/null

mkdir -p "$CERT_DIR"
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout "$CERT_DIR/tls.key" -out "$CERT_DIR/tls.crt" -days 365 \
  -subj "/CN=glauth.$NAMESPACE.svc.cluster.local" \
  -addext "subjectAltName=DNS:glauth.$NAMESPACE.svc.cluster.local,DNS:glauth,DNS:glauth.$NAMESPACE.svc,DNS:$ROUTE_HOST" \
  >/dev/null 2>&1

oc create secret tls glauth-tls \
  --cert="$CERT_DIR/tls.crt" --key="$CERT_DIR/tls.key" \
  -n "$NAMESPACE" --dry-run=client -o yaml | oc apply -f -

cat <<'EOF' | oc create configmap glauth-config -n "$NAMESPACE" --dry-run=client -o yaml --from-file=glauth.cfg=/dev/stdin | oc apply -f -
debug = false

[ldap]
  enabled = false

[ldaps]
  enabled = true
  listen = "0.0.0.0:3894"
  cert = "/certs/tls.crt"
  key = "/certs/tls.key"

[backend]
  datastore = "config"
  baseDN = "dc=openshiftworkshop,dc=com"

[behaviors]
  IgnoreCapabilities = true
  LimitFailedBinds = true
  NumberOfFailedBinds = 3
  PeriodOfFailedBinds = 10
  BlockFailedBindsFor = 60
  PruneSourceTableEvery = 600
  PruneSourcesOlderThan = 600

#################
# Bind/service account - used by OpenShift's OAuth LDAP IdP to search the directory.
[[users]]
  name = "openshiftworkshop"
  uidnumber = 5000
  primarygroup = 5500
  passsha256 = "7f5a7badda66733f9fb67df7b5eda3bd9c1e4f8b4dbdd672cf890a18affe6535" # b1ndP^ssword

#################
# Workshop users - all share the password Op#nSh1ft
[[users]]
  name = "normaluser1"
  mail = "normaluser1@example.com"
  uidnumber = 5001
  primarygroup = 5501
  othergroups = [5502]
  passsha256 = "6f67f2665beb9289a0dc3f016d9abb54a517f0d58831f50b7f6150c04a9afd3e" # Op#nSh1ft

[[users]]
  name = "teamuser1"
  mail = "teamuser1@example.com"
  uidnumber = 5002
  primarygroup = 5501
  othergroups = [5502, 5504]
  passsha256 = "6f67f2665beb9289a0dc3f016d9abb54a517f0d58831f50b7f6150c04a9afd3e" # Op#nSh1ft

[[users]]
  name = "teamuser2"
  mail = "teamuser2@example.com"
  uidnumber = 5003
  primarygroup = 5501
  othergroups = [5502, 5504]
  passsha256 = "6f67f2665beb9289a0dc3f016d9abb54a517f0d58831f50b7f6150c04a9afd3e" # Op#nSh1ft

[[users]]
  name = "fancyuser1"
  mail = "fancyuser1@example.com"
  uidnumber = 5004
  primarygroup = 5501
  othergroups = [5503]
  passsha256 = "6f67f2665beb9289a0dc3f016d9abb54a517f0d58831f50b7f6150c04a9afd3e" # Op#nSh1ft

[[users]]
  name = "fancyuser2"
  mail = "fancyuser2@example.com"
  uidnumber = 5005
  primarygroup = 5501
  othergroups = [5503]
  passsha256 = "6f67f2665beb9289a0dc3f016d9abb54a517f0d58831f50b7f6150c04a9afd3e" # Op#nSh1ft

#################
# Groups - gid numbers match the othergroups/primarygroup references above.
[[groups]]
  name = "svcaccts"
  gidnumber = 5500

[[groups]]
  name = "ose-user"
  gidnumber = 5501

[[groups]]
  name = "ose-normal-dev"
  gidnumber = 5502

[[groups]]
  name = "ose-fancy-dev"
  gidnumber = 5503

[[groups]]
  name = "ose-teamed-app"
  gidnumber = 5504
EOF

cat <<EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: glauth
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: glauth
  template:
    metadata:
      labels:
        app: glauth
    spec:
      containers:
        - name: glauth
          image: docker.io/glauth/glauth:latest
          command: ["/app/glauth"]
          args: ["-c", "/config/glauth.cfg"]
          ports:
            - containerPort: 3894
              name: ldaps
          volumeMounts:
            - name: config
              mountPath: /config
            - name: tls
              mountPath: /certs
      volumes:
        - name: config
          configMap:
            name: glauth-config
        - name: tls
          secret:
            secretName: glauth-tls
---
apiVersion: v1
kind: Service
metadata:
  name: glauth
  namespace: $NAMESPACE
spec:
  selector:
    app: glauth
  ports:
    - name: ldaps
      port: 636
      targetPort: 3894
EOF

oc create route passthrough glauth --service=glauth --port=ldaps \
  --hostname="$ROUTE_HOST" -n "$NAMESPACE" --dry-run=client -o yaml | oc apply -f -

echo "Waiting for glauth to be ready..."
oc rollout status deployment/glauth -n "$NAMESPACE" --timeout=120s
echo "glauth LDAP server is running at ldaps://glauth.$NAMESPACE.svc.cluster.local:636 (in-cluster) and ldaps://$ROUTE_HOST:443 (external, for client-side tools like 'oc adm groups sync')"
