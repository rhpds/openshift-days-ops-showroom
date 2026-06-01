# FAM (File Activity Monitoring) Setup

This setup enables file activity monitoring on the SecuredCluster, submits FAM policies to RHACS via the API, applies a **long-running exec runner Deployment** (`rhacs-fam-exec-runner`) aimed at the payment-processor workload, and documents how to trigger violations manually.

## Prerequisites

- OpenShift cluster with RHACS (ACS) installed
- `oc` logged in
- `ROX_API_TOKEN` set (from basic-setup or RHACS UI → Platform Configuration → Integrations → API Token)
- `jq` installed
- Namespace/project for the demo app (default **`payments`**) and deployment **`mastercard-processor`** if you want the automated runner loop and one-shot exec to succeed

## Quick Start

```bash
# Set credentials (if not in ~/.bashrc)
export ROX_API_TOKEN='your-api-token'
# ROX_CENTRAL_ADDRESS is auto-detected from cluster route

# Run the install script
./install.sh
```

**`install.sh`** rewrites **`fam-cron-exec-target.yaml`** on the fly to match **`FAM_EXEC_NAMESPACE`**, **`FAM_EXEC_WORKLOAD`**, and **`TARGET_NAMESPACE`** on the Deployment, then **`oc apply`**. It also runs a **one-shot** **`oc exec`** when the workload exists (step 4).

- Skip applying the runner Deployment: `FAM_SKIP_CRONJOB=1 ./install.sh`
- Skip the one-shot exec only: `FAM_SKIP_WORKLOAD_EXEC=1 ./install.sh`
- Other workload/NS: `FAM_EXEC_NAMESPACE=myproject FAM_EXEC_WORKLOAD=deployment/myapp ./install.sh`
- Multi-container pods: `FAM_EXEC_CONTAINER=app ./install.sh`

For **`verify-all-setup.sh`**, **`Deployment/rhacs-fam-exec-runner`** is expected in **`payments`** by default; override with **`FAM_CRON_NAMESPACE`**.

## What It Does

1. **Enables file activity monitoring** – Patches the SecuredCluster so `fileActivityMonitoring.mode` is `Enabled`.
2. **Submits FAM policies** – Creates or updates:
   - `fam-basic-node-monitoring` – monitors `/etc/passwd` for node-level modifications (NODE_EVENT)
   - `fam-basic-deploy-monitoring` – monitors deployments for changes to `/etc/passwd`
3. **Applies the exec runner Deployment** – **`fam-cron-exec-target.yaml`**: ServiceAccount, Role, RoleBinding, and **`rhacs-fam-exec-runner`**, which loops: **`oc exec`** into **`deployment/mastercard-processor`** (defaults), **`touch /etc/passwd`**, then sleeps **`FAM_LOOP_SLEEP_SEC`** (default **600**). Failures are logged and the pod stays Running (no CrashLoop from denied `touch`). Override interval: **`FAM_LOOP_SLEEP_SEC=300 ./install.sh`**. Legacy **`CronJob/rhacs-fam-exec-trigger`** is deleted on apply if present.
4. **One-shot `oc exec`** – Same target as above, once at install time, if the deployment exists.

## Trigger violations (run after install)

**Node-level** FAM:

```bash
# 1. Start a debug session on a worker node
oc debug node/<worker-node-name>

# 2. Inside the debug pod, run:
chroot /host
touch /etc/passwd    # Triggers fam-basic-node-monitoring
```

## Note on Policy-as-Code

These policies use `eventSource: NODE_EVENT` (node-level) or `DEPLOYMENT_EVENT` (deployment-level). The SecurityPolicy CR only supports `NOT_APPLICABLE`, `DEPLOYMENT_EVENT`, and `AUDIT_LOG_EVENT`. Policies that rely on node-level file activity must be submitted via the RHACS API (as this script does).

## Files

| File | Description |
|------|-------------|
| `fam-basic-node-monitoring.json` | FAM policy for node events (submitted via API) |
| `fam-basic-deploy-monitoring.json` | FAM policy for deployment events (submitted via API) |
| `fam-cron-exec-target.yaml` | Template for SA + RBAC + Deployment **`rhacs-fam-exec-runner`** (applied by **`install.sh`**, with NS/workload substituted from **`FAM_EXEC_*`**) |
| `install.sh` | Main script – SecuredCluster patch, policies, exec runner Deployment, optional one-shot exec |

## View violations

In RHACS UI: **Violations** → filter by **fam-basic-deploy-monitoring** or **fam-basic-node-monitoring**

### Renaming from older demos

If you previously installed policies named `fim-basic-*`, those remain in Central until removed. This repo now ships **`fam-basic-*`** policy names and files; run `install.sh` to create or update the new policies.

If you still have **`CronJob/rhacs-fam-trigger`** in **`default`** from an older **`fam-cron-alert`** flow, remove it when you no longer need it:

`oc delete cronjob rhacs-fam-trigger -n default --ignore-not-found`

If an older install left **`CronJob/rhacs-fam-exec-trigger`** in **`payments`**, **`install.sh`** removes it automatically; you can also run:

`oc delete cronjob rhacs-fam-exec-trigger -n payments --ignore-not-found`
