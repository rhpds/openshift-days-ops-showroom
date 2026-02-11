# Module Selection Flow - How It Works

This document explains how the modular workshop selection system works end-to-end, from the RHDP deployment form to the student seeing modules in the showroom navigation.

There are two deployment variants (v1 sandbox/AWS and v2 agd_v2/CNV) that share the same showroom content but use different deployers. Both follow the same flow.

## Testing Status

**V1 (Sandbox / AWS):** Tested and working. Multiple test deployments completed successfully across all workload combinations (all-on, individual workloads solo, ACM+Virt combo). Module selection correctly controls both operator deployment and nav visibility. Two deploys initially failed due to an ODF worker node race condition which has since been fixed.

**V2 (agd_v2 / CNV):** Not yet tested on a live deployment. The approach is set up in https://github.com/rhpds/agnosticv/pull/24925 using CNV pool clusters instead of AWS. The same module selection flow applies but with an additional HCP checkbox and a `managed-hcp` cluster that gets created on KubeVirt when ACM is enabled. This removes all AWS dependencies — the cluster, storage, and HCP all run on the CNV infrastructure already available in RHDP.

---

## V1 Flow (Sandbox / AWS)

### Step 1: User selects modules on RHDP deployment form

Checkboxes are defined as catalog parameters in the AgnosticV catalog YAML.

**File:** https://github.com/rhpds/agnosticv/blob/master/sandboxes-gpte/OCP4_ACM_ACS_OPS_WKSP/dev.yaml (catalog parameters section)

```yaml
- name: module_enable_virt
  formGroup: Advanced Topics
  formLabel: Virtualization - OpenShift Virtualization with VMs (30-35 min)
  openAPIV3Schema:
    type: boolean
    default: true
```

Each parameter creates a checkbox on the RHDP ordering page. When ticked, `module_enable_virt=true` becomes an Ansible variable passed to the deployer.

### Step 2: Ansible builds the workload list dynamically

Based on which checkboxes were ticked, Ansible builds a list of workloads to deploy. Only the selected modules get their operators installed.

**File:** https://github.com/rhpds/agnosticv/blob/master/sandboxes-gpte/OCP4_ACM_ACS_OPS_WKSP/dev.yaml (infra_workloads section)

```yaml
infra_workloads: >-
  {{
    _base_workloads +
    (_virt_workloads if module_enable_virt | default(true) | bool else []) +
    (_acm_workloads if module_enable_acm | default(true) | bool else []) +
    (_hcp_workloads if (module_enable_acm | bool) and (module_enable_virt | bool) else []) +
    (_backup_workloads if module_enable_backup | default(true) | bool else []) +
    (_devhub_workloads if module_enable_devhub | default(true) | bool else []) +
    (_ols_workloads if module_enable_ols | default(true) | bool else []) +
    (_security_workloads if module_enable_security | default(true) | bool else [])
  | unique | list }}
```

If `module_enable_virt` is `true`, `_virt_workloads` (which contains `ocp4_workload_kubevirt`) gets added. If `false`, it's skipped. The `| unique` filter prevents duplicates when a workload appears in multiple groups.

### Step 3: The deployer runs the workloads

**Deployer repo:** https://github.com/jnewsome97/agnosticd-ops-showroom (branch: `development`)

Ansible provisions a fresh AWS cluster, then runs each workload in `infra_workloads` as an Ansible role. The ops_track role (`ocp4-workload-days-ops-track`) is the main orchestrator that handles the showroom variable injection.

### Step 4: ops_track renders module variables into a shell template

The ops_track workload takes all the `module_enable_*` Ansible variables and renders them into a shell-compatible template.

**File:** https://github.com/jnewsome97/agnosticd-ops-showroom/blob/development/ansible/roles/ocp4-workload-days-ops-track/files/workshop-settings.j2

```bash
MODULE_ENABLE_VIRT={{ module_enable_virt | default(true) | string | lower }}
MODULE_ENABLE_ACM={{ module_enable_acm | default(true) | string | lower }}
MODULE_ENABLE_BACKUP={{ module_enable_backup | default(true) | string | lower }}
MODULE_ENABLE_LDAP={{ module_enable_ldap | default(true) | string | lower }}
MODULE_ENABLE_OIDC={{ module_enable_oidc | default(true) | string | lower }}
MODULE_ENABLE_OBSERVABILITY={{ module_enable_observability | default(true) | string | lower }}
```

This converts Ansible variables into `KEY=value` pairs. The rendered output looks like `MODULE_ENABLE_VIRT=true` or `MODULE_ENABLE_VIRT=false`.

### Step 5: ops_track creates a ConfigMap and patches the showroom pod

The rendered template is parsed into key-value pairs, stored as a Kubernetes ConfigMap, and then mounted as environment variables in the showroom pod.

**File:** https://github.com/jnewsome97/agnosticd-ops-showroom/blob/development/ansible/roles/ocp4-workload-days-ops-track/tasks/workload.yml (lines ~699-771)

```yaml
# Parse template into key-value pairs
- name: Parse workshop settings into individual variables for ConfigMap
  set_fact:
    workshop_vars: >-
      {%- set result = {} -%}
      {%- for key, value in workshop_settings_content.content | b64decode | regex_findall('([A-Z_]+)=(.*)') -%}
      {%- set _ = result.update({key: value}) -%}
      {%- endfor -%}
      {{ result }}

# Create ConfigMap with all MODULE_ENABLE_* variables
- name: Create ConfigMap with individual environment variables
  kubernetes.core.k8s:
    definition:
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: workshop-vars
        namespace: "{{ showroom_namespace }}"
      data: "{{ workshop_vars }}"

# Patch all 3 containers in the showroom pod to mount the ConfigMap as env vars
- name: Patch Showroom deployment to inject workshop environment variables
  shell: |
    oc patch deployment showroom -n {{ showroom_namespace }} --type=json -p='[{
      "op": "add",
      "path": "/spec/template/spec/containers/0/envFrom",
      "value": [{"configMapRef": {"name": "workshop-vars"}}]
    }]'
```

The pod restarts with the new environment variables available to all containers.

### Step 6: ops_track exec's inject-env-vars.sh inside the showroom pod

After the pod restarts with the ConfigMap-based env vars, the ops_track workload runs the injection script inside the pod.

**File:** Same [workload.yml](https://github.com/jnewsome97/agnosticd-ops-showroom/blob/development/ansible/roles/ocp4-workload-days-ops-track/tasks/workload.yml) (line ~899)

```yaml
- name: Inject workshop environment variables into antora.yml
  shell: |
    oc exec deployment/showroom -n {{ showroom_namespace }} -c content -- bash -c '
    if [ -x /showroom/repo/.workshop/inject-env-vars.sh ]; then
      /showroom/repo/.workshop/inject-env-vars.sh
    else
      echo "ERROR: injection script not found or not executable"
      exit 1
    fi'
```

### Step 7: inject-env-vars.sh reads env vars and writes Antora attributes

The script reads the `MODULE_ENABLE_*` environment variables (set by the ConfigMap) and writes them as AsciiDoc attributes into the Antora site configuration file.

**File:** https://github.com/jnewsome97/openshift-days-ops-track-showroom-v2/blob/main/.workshop/inject-env-vars.sh

```bash
# Read environment variables (set by ConfigMap)
ATTRS=""
ATTRS="${ATTRS}    module_enable_virt: '${MODULE_ENABLE_VIRT:-true}'"
ATTRS="${ATTRS}    module_enable_acm: '${MODULE_ENABLE_ACM:-true}'"
ATTRS="${ATTRS}    module_enable_backup: '${MODULE_ENABLE_BACKUP:-true}'"

# Overwrite the asciidoc attributes section in default-site.yml
echo "asciidoc:" >> "$SITE_FILE"
echo "  attributes:" >> "$SITE_FILE"
echo -n "$ATTRS" >> "$SITE_FILE"
```

This writes attributes like `module_enable_virt: 'true'` or `module_enable_virt: 'false'` into: https://github.com/jnewsome97/openshift-days-ops-track-showroom-v2/blob/main/default-site.yml

### Step 8: Antora rebuilds and nav.adoc shows/hides modules

After the attributes are written, Antora rebuilds the workshop site. The navigation file uses `ifeval` conditionals to show or hide modules based on the attribute values.

**File:** https://github.com/jnewsome97/openshift-days-ops-track-showroom-v2/blob/main/content/modules/ROOT/nav.adoc

```asciidoc
ifeval::["{module_enable_virt}" == "true"]
* xref:virtualization.adoc[Virtualization]
endif::[]

ifeval::["{module_enable_acm}" == "true"]
.ACM - Multi-Cluster Management
* xref:acm-multicluster.adoc[ACM Overview & Fleet Management]
endif::[]
```

If the attribute is `true`, the module appears in the navigation. If `false`, it's hidden. The student only sees the modules that were selected on the deployment form.

---

## V2 Flow (agd_v2 / CNV)

### Step 1: User selects modules on RHDP deployment form

Same concept as v1 but with 19 checkboxes (v1 has 18). The extra checkbox is for HCP as a standalone module.

**File:** https://github.com/rhpds/agnosticv/blob/add-openshift-days-ops-track-cnv-only/agd_v2/openshift-days-ops-track-cnv/common.yaml (catalog parameters section)

```yaml
- name: module_enable_hcp
  formGroup: Advanced Topics
  formLabel: Advanced Architecture - Hosted Control Planes (40-45 min)
  openAPIV3Schema:
    type: boolean
    default: true

- name: module_enable_acm
  formGroup: Advanced Topics
  formLabel: Multi-Cluster - ACM, Fleet Management (40-45 min)
  openAPIV3Schema:
    type: boolean
    default: true
```

### Step 2: Ansible builds the workload list dynamically

**File:** Same [common.yaml](https://github.com/rhpds/agnosticv/blob/add-openshift-days-ops-track-cnv-only/agd_v2/openshift-days-ops-track-cnv/common.yaml) (workloads section)

```yaml
workloads: >-
  {{
    _base_workloads +
    (_virt_workloads if module_enable_virt | default(true) | bool else []) +
    (_hcp_workloads if (module_enable_hcp | default(true) | bool) or (module_enable_acm | default(true) | bool) else []) +
    (_acm_workloads if module_enable_acm | default(true) | bool else []) +
    (_backup_workloads if module_enable_backup | default(true) | bool else []) +
    (_devhub_workloads if module_enable_devhub | default(true) | bool else []) +
    (_ols_workloads if module_enable_ols | default(true) | bool else []) +
    (_security_workloads if module_enable_security | default(true) | bool else [])
  | unique | list }}
```

Key differences from v1:
- Uses `workloads` instead of `infra_workloads`
- HCP workloads deploy when HCP **or** ACM is checked (either checkbox triggers the shared infrastructure)
- ACM workloads include `ocp4_workload_create_hcp_cluster` which creates a managed HCP cluster

### Step 3: The deployer runs the workloads

**Deployer repo:** https://github.com/rhpds/openshift-days-roadshow-automation (Ansible collection)

Roles are referenced using collection namespacing:
```yaml
# v1 style (old Ansible roles)
- ocp4-workload-days-ops-track

# v2 style (collection-based)
- openshift_days.ops_track.ocp4_workload_days_ops_track
```

The cluster comes from a CNV pool (pre-built, no AWS install needed).

### Step 4: ops_track renders module variables into a shell template

**File:** https://github.com/rhpds/openshift-days-roadshow-automation/blob/main/ops_track/roles/ocp4_workload_days_ops_track/files/workshop-settings.j2

```bash
MODULE_ENABLE_VIRT={{ module_enable_virt | default(true) | string | lower }}
MODULE_ENABLE_HCP={{ module_enable_hcp | default(true) | string | lower }}
MODULE_ENABLE_ACM={{ module_enable_acm | default(true) | string | lower }}
```

Same format as v1 but includes `MODULE_ENABLE_HCP` (the extra parameter).

### Step 5: ops_track creates a ConfigMap and patches the showroom pod

**File:** https://github.com/rhpds/openshift-days-roadshow-automation/blob/main/ops_track/roles/ocp4_workload_days_ops_track/tasks/workload.yml

Same logic as v1 - creates `workshop-vars` ConfigMap, patches showroom deployment with `envFrom`.

### Steps 6-8: Identical to v1

From this point on, both versions use the exact same shared files in the showroom content repo:

- **Step 6:** ops_track exec's https://github.com/jnewsome97/openshift-days-ops-track-showroom-v2/blob/main/.workshop/inject-env-vars.sh inside the showroom pod
- **Step 7:** Script reads env vars and writes attributes to https://github.com/jnewsome97/openshift-days-ops-track-showroom-v2/blob/main/default-site.yml
- **Step 8:** https://github.com/jnewsome97/openshift-days-ops-track-showroom-v2/blob/main/content/modules/ROOT/nav.adoc uses `ifeval` conditionals to show/hide modules

### V2 Extra: managed-hcp cluster creation

When ACM is checked, v2 runs an additional workload that creates a Hosted Control Plane cluster on KubeVirt. This gives the ACM module a second cluster to manage.

**File:** https://github.com/rhpds/openshift-days-roadshow-automation/tree/main/ops_track/roles/ocp4_workload_create_hcp_cluster

```yaml
- name: Create HostedCluster
  kubernetes.core.k8s:
    state: present
    template: hostedcluster.yaml.j2

- name: Wait for HostedCluster to become available
  kubernetes.core.k8s_info:
    api_version: hypershift.openshift.io/v1beta1
    kind: HostedCluster
    name: "{{ ocp4_workload_create_hcp_cluster_name }}"
    namespace: "{{ ocp4_workload_create_hcp_cluster_namespace }}"
  register: r_hosted_cluster
  retries: 60
  delay: 10
  until: ... Available == True
```

This provisions a `managed-hcp` cluster (~3-5 min) that auto-registers in ACM. V1 doesn't do this because MetalLB LoadBalancer IPs don't work on AWS networking.

---

## Key Differences Between V1 and V2

| | V1 (Sandbox / AWS) | V2 (agd_v2 / CNV) |
|--|-------------------|-------------------|
| Cluster | Fresh AWS install (~45 min) | CNV pool pre-built (~5 min) |
| Deployer | https://github.com/jnewsome97/agnosticd-ops-showroom | https://github.com/rhpds/openshift-days-roadshow-automation |
| Workload variable | `infra_workloads` | `workloads` |
| Role format | `ocp4-workload-days-ops-track` | `openshift_days.ops_track.ocp4_workload_days_ops_track` |
| HCP checkbox | No (HCP tied to ACM+Virt) | Yes (separate checkbox) |
| managed-hcp cluster | No (AWS networking issue) | Yes (KubeVirt) |
| Module count | 18 checkboxes | 19 checkboxes |
| Showroom content | https://github.com/jnewsome97/openshift-days-ops-track-showroom-v2 | Same repo |
| inject-env-vars.sh | Same script | Same script |
| nav.adoc | Same file | Same file |

---

## All Repos Involved

| Repo | Purpose |
|------|---------|
| https://github.com/jnewsome97/openshift-days-ops-track-showroom-v2 | Workshop content, nav.adoc, inject-env-vars.sh, default-site.yml |
| https://github.com/rhpds/openshift-days-roadshow-automation | V2 workload collection (ops_track roles) |
| https://github.com/jnewsome97/agnosticd-ops-showroom | V1 deployer (old Ansible roles) |
| https://github.com/rhpds/agnosticv/pull/24925 | V2 catalog item (CNV variant) |
| https://github.com/rhpds/agnosticv/pull/24972 | V1 catalog item (sandbox variant) |
| https://github.com/jnewsome97/rhdp_showroom_theme_execute | Showroom theme with execute button |
| https://github.com/rhpds/sovereign_cloud | prepare_hcp workload (used by v2) |
