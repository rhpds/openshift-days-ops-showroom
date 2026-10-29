#!/bin/bash
set -euo pipefail

cat <<EOF | oc apply -f -
apiVersion: observability.openshift.io/v1
kind: ClusterLogForwarder
metadata:
  name: collector
  namespace: openshift-logging
spec:
  collector:
    resources:
      limits:
        memory: 10Gi                 # default 2Gi is too low for busy clusters; 8Gi still OOMs repeatably
      requests:
        cpu: 500m
        memory: 256Mi
  serviceAccount:
    name: collector
  outputs:
  - name: default-lokistack
    type: lokiStack
    lokiStack:
      authentication:
        token:
          from: serviceAccount       # authenticates to Loki using the SA token
      target:
        name: logging-loki           # the LokiStack we created above
        namespace: openshift-logging
    tls:
      ca:
        key: service-ca.crt
        configMapName: logging-loki-gateway-ca-bundle
  pipelines:
  - name: default-logstore
    inputRefs:
    - application                    # logs from user workloads
    - infrastructure                 # logs from OpenShift components
    - audit                          # Kubernetes API audit logs
    outputRefs:
    - default-lokistack
EOF
