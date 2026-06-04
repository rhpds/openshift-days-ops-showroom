#!/bin/bash
set -euo pipefail

# Extract S3 credentials from the bucket claim
ACCESS_KEY=$(oc get secret loki-bucket -n openshift-logging -o jsonpath='{.data.AWS_ACCESS_KEY_ID}' | base64 -d)
SECRET_KEY=$(oc get secret loki-bucket -n openshift-logging -o jsonpath='{.data.AWS_SECRET_ACCESS_KEY}' | base64 -d)
BUCKET_NAME=$(oc get configmap loki-bucket -n openshift-logging -o jsonpath='{.data.BUCKET_NAME}')
BUCKET_HOST=$(oc get configmap loki-bucket -n openshift-logging -o jsonpath='{.data.BUCKET_HOST}')
DEFAULT_SC=$(oc get sc -o jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}')

echo "Bucket: $BUCKET_NAME | Host: $BUCKET_HOST | SC: $DEFAULT_SC"

# Create CA cert so Loki can trust the NooBaa S3 endpoint's TLS certificate
oc get secret noobaa-s3-serving-cert -n openshift-storage \
  -o jsonpath='{.data.tls\.crt}' | base64 -d > /tmp/noobaa-ca.crt
oc create configmap loki-s3-ca -n openshift-logging \
  --from-file=service-ca.crt=/tmp/noobaa-ca.crt

# Create the S3 credentials secret and deploy LokiStack
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: lokistack-dev-s3
  namespace: openshift-logging
stringData:
  access_key_id: ${ACCESS_KEY}
  access_key_secret: ${SECRET_KEY}
  bucketnames: ${BUCKET_NAME}
  endpoint: https://${BUCKET_HOST}
  region: ""
---
apiVersion: loki.grafana.com/v1
kind: LokiStack
metadata:
  name: logging-loki
  namespace: openshift-logging
spec:
  managementState: Managed
  size: 1x.extra-small              # smallest size - scale up for production
  replication:
    factor: 1                        # single replica - matches compact cluster sizing
  storage:
    schemas:
    - effectiveDate: '2024-10-01'
      version: v13
    secret:
      name: lokistack-dev-s3        # S3 credentials from the bucket claim
      type: s3
    tls:
      caName: loki-s3-ca            # CA cert for NooBaa's S3 endpoint
  storageClassName: ${DEFAULT_SC}    # uses the cluster's default storage class
  template:
    compactor:
      replicas: 1
    distributor:
      replicas: 1
    gateway:
      replicas: 1
    indexGateway:
      replicas: 1
    ingester:
      replicas: 1
    querier:
      replicas: 1
    queryFrontend:
      replicas: 1
  limits:
    global:
      ingestion:
        ingestionRate: 16            # MB/sec - default 2 is too low for busy clusters
        ingestionBurstSize: 32       # MB - must exceed largest single push request
  tenants:
    mode: openshift-logging          # multi-tenant: separates app, infra, and audit logs
EOF
