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
        cpu: "1"
        memory: 4Gi
      requests:
        cpu: "1"
        memory: 4Gi                    # Guaranteed QoS prevents OOM killer targeting collectors
  serviceAccount:
    name: collector
  outputs:
  - name: default-lokistack
    type: lokiStack
    lokiStack:
      authentication:
        token:
          from: serviceAccount         # authenticates to Loki using the SA token
      target:
        name: logging-loki             # the LokiStack we created above
        namespace: openshift-logging
    tls:
      ca:
        key: service-ca.crt
        configMapName: logging-loki-gateway-ca-bundle
  pipelines:
  - name: default-logstore
    inputRefs:
    - application                      # logs from user workloads
    - infrastructure                   # logs from OpenShift components
    - audit                            # Kubernetes API audit logs
    outputRefs:
    - default-lokistack
EOF
