#!/bin/bash
# Prepare VM for live migration on mixed Intel/AMD clusters
# Detects CPU vendor and pins the VM to the vendor with 2+ nodes

VM_NODE=$(oc get vmi rhel9-vm -n vm-demo -o jsonpath='{.status.nodeName}')
CURRENT_VENDOR=$(oc get node "$VM_NODE" -o jsonpath='{.metadata.labels}' 2>/dev/null | grep -q 'cpu-vendor.node.kubevirt.io/Intel' && echo Intel || echo AMD)
INTEL_COUNT=$(oc get nodes -l cpu-vendor.node.kubevirt.io/Intel=true --no-headers 2>/dev/null | wc -l | tr -d ' ')
AMD_COUNT=$(oc get nodes -l cpu-vendor.node.kubevirt.io/AMD=true --no-headers 2>/dev/null | wc -l | tr -d ' ')

# Pick the vendor with 2+ nodes so migration has a target
if [ "$INTEL_COUNT" -ge 2 ]; then VENDOR="Intel"
elif [ "$AMD_COUNT" -ge 2 ]; then VENDOR="AMD"
else VENDOR="$CURRENT_VENDOR"; fi

echo "Cluster has $INTEL_COUNT Intel and $AMD_COUNT AMD nodes"
echo "VM is currently on $CURRENT_VENDOR node, pinning to $VENDOR"

if [ "$CURRENT_VENDOR" != "$VENDOR" ]; then
  echo "VM is on $CURRENT_VENDOR node - moving to $VENDOR..."
  oc patch vm rhel9-vm -n vm-demo --type=merge -p "{\"spec\":{\"runStrategy\":\"Halted\"}}"
  ELAPSED=0
  until [ "$(oc get vm rhel9-vm -n vm-demo -o jsonpath='{.status.printableStatus}')" = "Stopped" ]; do
    sleep 5; ELAPSED=$((ELAPSED+5))
    [ $ELAPSED -ge 120 ] && echo "ERROR: Timed out waiting for VM to stop" && break
  done
  oc patch vm rhel9-vm -n vm-demo --type=merge -p "{\"spec\":{\"template\":{\"spec\":{\"nodeSelector\":{\"cpu-vendor.node.kubevirt.io/${VENDOR}\":\"true\"}}}}}"
  oc patch vm rhel9-vm -n vm-demo --type=merge -p '{"spec":{"runStrategy":"Always"}}'
  ELAPSED=0
  until oc get vmi rhel9-vm -n vm-demo 2>/dev/null | grep -q Running; do
    sleep 10; ELAPSED=$((ELAPSED+10))
    [ $ELAPSED -ge 180 ] && echo "ERROR: Timed out waiting for VM to start" && break
  done
  echo "VM moved to $VENDOR node"
else
  echo "VM already on $VENDOR node - no move needed"
fi

oc get vmi rhel9-vm -n vm-demo -o jsonpath='Ready - Node: {.status.nodeName}' && echo ""
