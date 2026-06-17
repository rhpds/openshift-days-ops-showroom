#!/bin/bash
set -euo pipefail

echo "Exposing weather app services..."
for svc in weather-frontend weather-api weather-backend weather-cache weather-db; do
  oc expose deployment/$svc --port=8080 -n debug-lab 2>/dev/null || true
  oc create route edge $svc --service=$svc --port=8080 -n debug-lab 2>/dev/null || true
done
oc create route edge weather-proxy --service=weather-proxy --port=8080 -n debug-lab 2>/dev/null || true

echo ""
echo "The Weather App: https://$(oc get route weather-frontend -n debug-lab -o jsonpath='{.spec.host}')"
