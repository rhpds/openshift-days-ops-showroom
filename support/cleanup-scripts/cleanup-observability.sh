#!/bin/bash
# Cleanup script for Module 09 - Observability & Logging
# Removes alerting rules, tracing stack, and logging stack

echo "Cleaning up observability resources..."

# Remove the custom alerting rule
oc delete prometheusrule ops-track-alerts -n openshift-monitoring --ignore-not-found

# Remove the tracing stack
(
  oc delete opentelemetrycollector otel -n tracing-system --ignore-not-found
  oc delete uiplugin distributed-tracing --ignore-not-found
  oc delete tempomonolithic sample -n tracing-system --ignore-not-found
  oc delete clusterrolebinding tempomonolithic-traces-reader tempomonolithic-traces-write --ignore-not-found
  oc delete clusterrole tempomonolithic-traces-reader tempomonolithic-traces-write --ignore-not-found
  oc delete sa otel-collector -n tracing-system --ignore-not-found
  oc delete namespace tracing-system --ignore-not-found --wait=false
) &>/dev/null &

# Remove the logging stack
(
  oc delete clusterlogforwarder collector -n openshift-logging --ignore-not-found
  oc delete uiplugin logging --ignore-not-found
  oc delete lokistack logging-loki -n openshift-logging --ignore-not-found
  oc delete obc loki-bucket -n openshift-logging --ignore-not-found
  oc delete secret lokistack-dev-s3 -n openshift-logging --ignore-not-found
  oc delete configmap loki-s3-ca -n openshift-logging --ignore-not-found
  oc delete sa collector -n openshift-logging --ignore-not-found
) &>/dev/null &

echo "Cleanup running in background — you can continue to the next module"
