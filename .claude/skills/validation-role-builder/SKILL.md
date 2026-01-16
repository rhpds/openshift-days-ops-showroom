# Validation Role Builder Skill

You are assisting with creating validation roles for Red Hat Demo Platform (RHDP) workshops and demos. This skill follows a **collaborative pattern** where the user runs commands manually and shares output with you.

## Workflow Overview

This skill helps you:
1. Set up repository locations
2. Guide user to discover deployed components (they run commands)
3. Analyze component output from user
4. Generate complete validation role code
5. Update AgnosticV configuration
6. Guide testing and create commits

**IMPORTANT**: User prefers to SSH to bastion and run commands manually. You provide the commands, they run them and share output.

## Phase 1: Initial Setup

### Step 1.1: Get Local Clone Path

Ask first question:
```
I'll help you create a validation role. Where are your repositories cloned locally?

Base path: (default: ~/work/code/)
```

Use Glob tool to verify:
- `{base_path}/agnosticv` exists
- If doesn't exist, ask for exact AgnosticV path

### Step 1.2: Get Workshop Information

Ask second question:
```
Which workshop are you adding validation for?

1. Workshop name: (e.g., aap-multiinstance-workshop)
2. AgnosticV config path: (e.g., agd_v2/aap-multiinstance-workshop)
```

### Step 1.3: Read AgnosticV common.yaml

Read the workshop's common.yaml to discover:
```
{base_path}/agnosticv/{agnosticv_config_path}/common.yaml
```

Extract:
- Collection names from `workloads:` section
- Repository URLs from `agd_v2_collections:` or `collections:` section (if present)
- GitOps repositories from `gitops_repos:` section (if present)

Identify which collection should contain the validation role by analyzing existing workloads.

### Step 1.4: Confirm Automation Method and Locate Repositories

Ask user:
```
Found the following in common.yaml:

Collections/Workloads:
- {collection_name_1}.ocp4_workload_example1
- {collection_name_2}.ocp4_workload_example2

{If GitOps repos found:}
GitOps Repositories:
- {gitops_repo_1}
- {gitops_repo_2}

Questions:
1. Which collection should I add the validation role to?
   (default: first collection with ocp4_workload_ roles)

2. Is all automation done with workloads, or also with GitOps?
   - Workloads only
   - GitOps only
   - Both workloads and GitOps
```

### Step 1.5: Verify/Locate Collection Repository

Use Glob tool to check if collection exists at expected path:
```
{base_path}/{collection_name}/
```

**If found:** Confirm with user: "Found collection at {path}. Is this correct?"

**If not found:** Ask user:
```
Collection {collection_name} not found at {base_path}/{collection_name}.

Options:
1. Clone it to {base_path} from common.yaml URL: {collection_repo_url}
2. Clone it to a different location (I'll ask where)
3. It's already cloned somewhere else (provide the path)
4. Clone from a different URL
```

If user chooses option 1, use Bash tool to clone:
```bash
cd {base_path}
git clone {collection_repo_url}
```

If user chooses option 2, ask: "Where should I clone it?" then clone to that path.

If user chooses option 3, ask for path and verify.

If user chooses option 4, ask for URL and location, then clone.

### Step 1.6: Verify/Locate GitOps Repositories (if applicable)

If GitOps is used, repeat the same process for each GitOps repository:
- Check if exists at `{base_path}/{gitops_repo_name}`
- If not found, offer to clone or ask for path

**Note:** If GitOps is used, validation should check resources deployed by GitOps as well as workloads.

## Phase 2: Manual Component Discovery

### Step 2.1: Tell User to Login to Bastion

Tell user:
```
Now let's discover the deployed components.

Please login to your bastion host now.

Let me know when you're logged in, then I'll give you commands to run step by step.
```

### Step 2.2: Discover User Namespaces

Provide first command:
```
First, let's find user namespaces:

oc get namespaces -o name | grep -E 'user[0-9]'

Paste the output when ready.
```

Wait for user output. Analyze namespace pattern (e.g., `user1-aap`, `namespace/user1-aap-instance`).

### Step 2.3: Check Sample User Namespace

Based on output from 2.2, ask user:
```
Now let's check what's in the first user namespace. Run:

oc get all,routes -n {first_user_namespace}

Paste the output.
```

Wait for output. Identify pod patterns, deployments, routes.

### Step 2.4: Check Pod Labels

Ask user:
```
Let's see pod labels to understand naming patterns:

oc get pods -n {first_user_namespace} --show-labels

Paste the output.
```

Wait for output. Note pod name patterns (e.g., `automation-controller-*`, `aap-instance-*`).

### Step 2.5: Check for Keycloak

Ask user:
```
Check if Keycloak is deployed:

oc get namespaces -o name | grep keycloak

Paste the output (or say "none" if empty).
```

If user reports a namespace, follow up:
```
Get Keycloak pods:

oc get pods -n {keycloak_namespace}

Paste the output.
```

### Step 2.6: Check for Showroom

Ask user:
```
Check if Showroom is deployed:

oc get namespaces -o name | grep showroom

Paste the output (or say "none" if empty).
```

If user reports namespaces, follow up:
```
Get resources in first Showroom namespace:

oc get all,routes -n {first_showroom_namespace}

Paste the output.
```

### Step 2.7: Check for CRDs (Optional)

Ask user:
```
Check for AAP custom resources:

oc get automationcontroller --all-namespaces

Paste the output (or say "none" if not found).
```

If needed, also check EDA:
```
oc get eda --all-namespaces
```

### Step 2.8: Analyze All Output

When user provides output, analyze it to identify:
- Namespace patterns (e.g., `user1-aap-instance`, `showroom-abc-user1`)
- Pod name patterns (e.g., pods starting with `automation-controller`, `showroom`)
- Route names
- Custom resources (AutomationController, EDA)
- Shared components (Keycloak namespace)

Document findings and confirm with user:
```
Based on the output, I found these components:

Per-User Components:
- AAP instances in namespaces: user{N}-{pattern}
- Showroom in namespaces: showroom-*-user{N}
- Pods: {pattern}

Shared Components:
- Keycloak namespace: {name}

Does this look correct?
```

## Phase 3: Create Validation Role

### Step 3.1: Ask About Collection Repository

Ask user:
```
Where should I push the new validation role?

1. Collection repo URL: (e.g., https://github.com/rhpds/rhpds.aap_self_service_portal)
2. Default branch name: (default: main)
```

### Step 3.2: Create Collection Branch

Use Bash tool to create branch:
```bash
cd {collection_path}
git checkout {default_branch}
git pull origin {default_branch}
git checkout -b add-{workshop_name}-validation
```

Tell user: "Created branch add-{workshop_name}-validation in collection repository"

### Step 3.3: Generate Role Name

Based on workshop name, create role name:
```
ocp4_workload_{workshop_name}_validation
```

Example: `ocp4_workload_aap_multiinstance_validation`

### Step 3.4: Create Role Structure

Use Write tool to create:
```
{collection_path}/roles/ocp4_workload_{workshop_name}_validation/
├── defaults/
│   └── main.yml
├── tasks/
│   ├── main.yml
│   ├── check_keycloak.yml (if applicable)
│   ├── check_aap_operator.yml (if applicable)
│   ├── check_aap_instances.yml (if applicable)
│   ├── check_single_aap_instance.yml (if applicable)
│   ├── check_self_service_portals.yml (if applicable)
│   ├── check_single_ssap.yml (if applicable)
│   ├── check_showroom_instances.yml (if applicable)
│   ├── check_single_showroom.yml (if applicable)
│   └── generate_report.yml
├── meta/
│   └── main.yml
└── README.md
```

### Step 3.5: Generate defaults/main.yml

Create with toggles for each component found:
```yaml
---
# User configuration
ocp4_workload_{workshop_name}_validation_num_users: 1
ocp4_workload_{workshop_name}_validation_user_prefix: "user"

# Component-specific validation toggles
ocp4_workload_{workshop_name}_validation_check_keycloak: true
ocp4_workload_{workshop_name}_validation_check_operators: true
# ... etc for each component

# Component-specific settings (from discovery)
ocp4_workload_{workshop_name}_validation_showroom_deployment_name: "showroom"

# HTTP check configuration
ocp4_workload_{workshop_name}_validation_http_validate_certs: false
ocp4_workload_{workshop_name}_validation_http_timeout: 10
ocp4_workload_{workshop_name}_validation_http_success_codes: [200, 301, 302]
```

### Step 3.6: Generate Component Check Tasks

For each component, create check tasks following the **RHADS validation pattern**:

**Pattern 1: Per-User Components (AAP Instance, SSAP, Showroom)**

Use namespace auto-discovery:
```yaml
# Auto-discover namespace by pattern
- name: Discover {component} namespace for {{ _user }}
  kubernetes.core.k8s_info:
    api_version: v1
    kind: Namespace
  register: _all_namespaces
  ignore_errors: true

- name: Find {component} namespace matching user pattern
  ansible.builtin.set_fact:
    _namespace: "{{ _all_namespaces.resources | map(attribute='metadata.name') | select('match', '^{pattern}-.*-' ~ _user ~ '$') | first | default('') }}"

# Get all pods in namespace (no label selectors)
- name: Get all pods in {{ _namespace }}
  kubernetes.core.k8s_info:
    api_version: v1
    kind: Pod
    namespace: "{{ _namespace }}"
  register: _pods
  ignore_errors: true
  when: _namespace != ''

# Count by name pattern
- name: Count pods by name pattern
  ansible.builtin.set_fact:
    _pods_running: >-
      {{
        _pods.resources | default([]) |
        selectattr('metadata.name', 'search', '{name_pattern}') |
        selectattr('status.phase', 'equalto', 'Running') |
        list | length | int
        if (_namespace != '' and _pods is defined and not _pods.skipped | default(false))
        else 0
      }}
```

**Pattern 2: Shared Components (Keycloak, Operators)**

Direct namespace reference:
```yaml
# Get all pods in namespace
- name: Get all pods in {{ _namespace }}
  kubernetes.core.k8s_info:
    api_version: v1
    kind: Pod
    namespace: "{{ _namespace }}"
  register: _pods
  ignore_errors: true

# Count by name pattern
- name: Count {component} pods by name pattern
  ansible.builtin.set_fact:
    _component_pods_running: >-
      {{
        _pods.resources | default([]) |
        selectattr('metadata.name', 'search', '{pattern}') |
        selectattr('status.phase', 'equalto', 'Running') |
        list | length | int
      }}
```

**Pattern 3: Route Checks**

Get all routes (no name filter):
```yaml
- name: Check routes in {{ _namespace }}
  kubernetes.core.k8s_info:
    api_version: route.openshift.io/v1
    kind: Route
    namespace: "{{ _namespace }}"
  register: _routes
  ignore_errors: true
  when: _namespace != ''

- name: Extract route hostname
  ansible.builtin.set_fact:
    _route_host: >-
      {{
        (_routes.resources | default([]) | first).spec.host | default('')
        if (_routes.resources | default([]) | length > 0)
        else ''
      }}
    _route_exists: "{{ _namespace != '' and _routes is defined and not _routes.skipped | default(false) and (_routes.resources | default([]) | length > 0) }}"
```

**Key Principles:**
- Always use `| int` when setting counter variables
- No `| int` needed in comparisons (already integers)
- Always handle missing namespaces gracefully (`when: _namespace != ''`)
- No label selectors - use name pattern matching
- All validation results stored in consistent format

### Step 3.7: Generate generate_report.yml

Create report generation with type-safe counters:
```yaml
---
# Count validation results by status
- name: Count total components
  ansible.builtin.set_fact:
    _validation_total: "{{ _validation_results | length | int }}"

- name: Count healthy components
  ansible.builtin.set_fact:
    _validation_healthy: >-
      {{
        _validation_results |
        selectattr('status', 'equalto', 'healthy') |
        list | length | int
      }}

- name: Count degraded components
  ansible.builtin.set_fact:
    _validation_degraded: >-
      {{
        _validation_results |
        selectattr('status', 'equalto', 'degraded') |
        list | length | int
      }}

- name: Count failed components
  ansible.builtin.set_fact:
    _validation_failed: >-
      {{
        _validation_results |
        selectattr('status', 'equalto', 'failed') |
        list | length | int
      }}

# Determine overall status (no | int needed - already integers)
- name: Determine overall validation status
  ansible.builtin.set_fact:
    _validation_status: >-
      {{
        'FAILED' if _validation_failed > 0
        else 'DEGRADED' if _validation_degraded > 0
        else 'HEALTHY'
      }}

# Generate summary report
- name: Generate validation summary
  ansible.builtin.set_fact:
    _validation_summary: |
      {Workshop Name} Validation Report
      ================================================

      Overall Status: {{ _validation_status }}

      Components Summary:
      - Total: {{ _validation_total }}
      - Healthy: {{ _validation_healthy }}
      - Degraded: {{ _validation_degraded }}
      - Failed: {{ _validation_failed }}

      {% if _validation_issues | length > 0 %}
      Issues Detected:
      {% for issue in _validation_issues %}
      - {{ issue }}
      {% endfor %}
      {% else %}
      Issues: None - All components healthy!
      {% endif %}

      Component Details:
      {% for result in _validation_results %}

      {{ result.component }} ({{ result.namespace }}):
        Status: {{ result.status | upper }}
      {% for key, value in result.details.items() %}
        {{ key }}: {{ value }}
      {% endfor %}
      {% endfor %}

# Save to agnosticd_user_info
- name: Save validation results to user info
  {collection_name}.agnosticd_user_info:
    data:
      validation_status: "{{ _validation_status }}"
      validation_total: "{{ _validation_total }}"
      validation_healthy: "{{ _validation_healthy }}"
      validation_degraded: "{{ _validation_degraded }}"
      validation_failed: "{{ _validation_failed }}"
      validation_issues: "{{ _validation_issues | join(', ') if _validation_issues | length > 0 else 'None' }}"
      validation_summary: "{{ _validation_summary }}"
```

### Step 3.8: Check for agnosticd_user_info Plugin

Read the collection to see if it has the plugin:
```
{collection_path}/plugins/modules/agnosticd_user_info.py
{collection_path}/plugins/action/agnosticd_user_info.py
```

If not found, tell user:
```
The collection needs the agnosticd_user_info plugin to save validation results.

Note: agnosticd.core is NOT available on Ansible Galaxy, so we need to copy the plugin
files directly into this collection.

Source: AAP collection has the plugin files
I can copy from: ~/work/code/rhpds.aap_self_service_portal/plugins/

Should I copy it?
```

If user says yes, use Bash to copy both files:
```bash
mkdir -p {collection_path}/plugins/modules
mkdir -p {collection_path}/plugins/action
cp ~/work/code/rhpds.aap_self_service_portal/plugins/modules/agnosticd_user_info.py {collection_path}/plugins/modules/
cp ~/work/code/rhpds.aap_self_service_portal/plugins/action/agnosticd_user_info.py {collection_path}/plugins/action/
```

Verify files were copied:
- plugins/modules/agnosticd_user_info.py
- plugins/action/agnosticd_user_info.py

### Step 3.9: Create Test Playbook

Create test playbook in collection:
```yaml
---
# playbooks/validate_{workshop_name}.yml
- name: Test {Workshop Name} Validation
  hosts: localhost
  connection: local
  gather_facts: false

  tasks:
    - name: Run validation role
      ansible.builtin.include_role:
        name: {collection_name}.ocp4_workload_{workshop_name}_validation
```

### Step 3.10: Commit and Push Validation Role

Use Bash tool to commit and push the validation role:
```bash
cd {collection_path}
git add roles/ocp4_workload_{workshop_name}_validation/
git add playbooks/validate_{workshop_name}.yml
git add plugins/ (if added)
git commit -m "Add validation role for {workshop_name}

Components validated:
{list components discovered in Phase 2}

Features:
- Auto-discovery of namespaces
- Per-user component checks
- HTTP endpoint validation
- Detailed health reporting
- Integration with agnosticd_user_info"

git push origin add-{workshop_name}-validation
```

Tell user: "Validation role committed and pushed to branch: add-{workshop_name}-validation"

## Phase 4: Update AgnosticV Configuration

### Step 4.1: Create AgnosticV Branch

Use Bash tool:
```bash
cd {agv_repo_path}
git checkout master
git pull origin master
git checkout -b add-{workshop_name}-validation
```

### Step 4.2: Update common.yaml

Read the existing common.yaml, then update to add validation workload:
```yaml
workloads:
  # ... existing workloads
  - {collection_name}.ocp4_workload_{workshop_name}_validation
```

Add configuration variables:
```yaml
# -------------------------------------------------------------------
# Workload: ocp4_workload_{workshop_name}_validation
# -------------------------------------------------------------------
ocp4_workload_{workshop_name}_validation_num_users: "{{ num_users | default(1) }}"
ocp4_workload_{workshop_name}_validation_user_prefix: "{{ user_prefix | default('user') }}"
```

**Note:**
- Only add essential variables to common.yaml (num_users, user_prefix)
- Component-specific toggles stay in role defaults/main.yml, not in AgnosticV
- Validation runs unconditionally - no `_enabled` flag needed

### Step 4.3: Update common.yaml to Use Collection Branch

Update the collection reference in common.yaml to use the branch for integration testing:
```yaml
# Use collection from branch for testing
agd_v2_collections:
  - name: {collection_name}
    source: {collection_repo_url}
    version: add-{workshop_name}-validation  # Branch name instead of main/version tag
```

This allows AgnosticV to pull the validation role from the branch during testing.

**Important:** After the collection PR is merged, revert this to use the released version.

### Step 4.4: Update info-message-template.adoc

Read existing template, then add validation section at the bottom:
```asciidoc
ifdef::validation_status[]

== Workshop Environment Validation Report

[%autowidth.stretch,width=80%,cols="a,a",options="header"]
|===
2+| Environment Health Check Summary
| Overall Status | *{validation_status}*
| Total Components | {validation_total}
| Healthy | {validation_healthy}
| Degraded | {validation_degraded}
| Failed | {validation_failed}
|===

=== Issues Detected

ifeval::["{validation_issues}" != "None"]
[source,text]
----
{validation_issues}
----
endif::[]

ifeval::["{validation_issues}" == "None"]
[source,text]
----
No issues detected - all components are healthy!
----
endif::[]

[TIP]
====
*Status Levels:*

* *HEALTHY* - All components are running and accessible
* *DEGRADED* - Some components have partial issues (e.g., not all pods ready, HTTP not accessible)
* *FAILED* - Critical components are missing or not running
====

[%collapsible]
.Click to view detailed component breakdown
====
{validation_summary}
====

endif::[]
```

**Important Pattern Notes:**
- Title `.Click to view...` comes AFTER `[%collapsible]`, not before
- Variable `{validation_summary}` goes directly inside `====` delimiters
- NO `[source,text]` wrapper around the variable
- This pattern is proven to work in PR 24572 (MCP workshop)

### Step 4.5: Commit AgnosticV Changes

Use Bash tool:
```bash
cd {agv_repo_path}
git add agd_v2/{workshop_config_path}/
git commit -m "Add validation role for {workshop_name}

Integrates {collection_name}.ocp4_workload_{workshop_name}_validation
to provide health checks for deployed workshop components.

Validation includes:
{list of components discovered}

Results displayed in catalog info page with detailed breakdown."

git push origin add-{workshop_name}-validation
```

## Phase 5: Testing on Bastion

### Step 5.1: Guide User Through Complete Test Setup

Tell user step by step:

**Step 1: SSH to bastion**
```
SSH to bastion:

ssh {bastion_user}@{bastion_host}
```

**Step 2: Clone collection repo**
```
Clone the collection repository using HTTPS URL:

cd ~/
git clone {collection_repo_https_url}
cd {collection_name}
git checkout add-{workshop_name}-validation

Paste output or say "done".
```

**Note:** Use HTTPS URL for bastion (e.g., https://github.com/org/repo.git), not SSH format.

**Step 3: Create virtual environment**
```
Create Python virtual environment:

python3 -m venv venv
source venv/bin/activate

Say "done" when ready.
```

**Step 4: Install pip packages**
```
Install required Python packages:

pip install --upgrade pip
pip install ansible kubernetes openshift jmespath

Paste output or say "done".
```

**Step 5: Install related collections**
```
Install required Ansible collections:

ansible-galaxy collection install kubernetes.core
ansible-galaxy collection install ansible.posix

Paste output or say "done".
```

**Step 6: Setup agnosticd_user_info plugin**

If the collection includes the plugin files (plugins/modules/agnosticd_user_info.py):
```
The collection already has the agnosticd_user_info plugin copied. No additional setup needed.
```

If the collection does NOT have the plugin files:
```
The validation role needs agnosticd.core for the agnosticd_user_info plugin.

Option 1 - Install agnosticd.core from git:
ansible-galaxy collection install git+https://github.com/redhat-cop/agnosticd.git#/ansible/agnosticd-core/

Option 2 - Copy plugin files to the collection (if you have them locally):
mkdir -p plugins/modules plugins/action
cp ~/work/code/rhpds.aap_self_service_portal/plugins/modules/agnosticd_user_info.py plugins/modules/
cp ~/work/code/rhpds.aap_self_service_portal/plugins/action/agnosticd_user_info.py plugins/action/

Which option do you prefer?
```

**Step 7: Build the collection**
```
Build the collection from source:

ansible-galaxy collection build
ansible-galaxy collection install {collection_name}-*.tar.gz --force

Paste output or say "done".
```

**Step 8: Run the test playbook**
```
Run the validation test:

ansible-playbook playbooks/validate_{workshop_name}.yml

Paste the FULL output.
```

### Step 5.2: Analyze Test Results

When user provides output, analyze:
- All components detected correctly?
- Correct status (HEALTHY/DEGRADED/FAILED)?
- Accurate pod counts and route URLs?
- Meaningful issue messages?

### Step 5.3: Iterate on Feedback

If user reports issues:
- Adjust namespace patterns
- Fix pod name patterns
- Update health criteria
- Re-generate affected files
- Commit changes to collection branch

Then tell user:
```
I've updated the validation role. Please pull the latest changes and test again:

cd ~/{collection_name}
git pull origin add-{workshop_name}-validation
ansible-galaxy collection build
ansible-galaxy collection install {collection_name}-*.tar.gz --force
ansible-playbook playbooks/validate_{workshop_name}.yml

Paste the output.
```

Repeat testing until validation works correctly.

## Phase 6: Final Deliverables

### Step 6.1: Create Pull Requests

**Prerequisites:** Ensure user has completed Phase 5 and tested the validation role manually on bastion with successful results.

Ask user to confirm:
```
Have you completed testing the validation role on bastion?
Did all validation checks pass correctly?
```

Wait for user confirmation.

Then tell user:
```
Great! Testing complete. Ready to create pull requests.

Should I create PRs using gh CLI?
```

If yes, use Bash tool:
```bash
# Create Collection PR
cd {collection_path}
gh pr create --title "Add validation role for {workshop_name}" \
  --body "## Summary
Adds validation role for {workshop_name} workshop.

## Components Validated
{list components}

## Features
- Auto-discovery of namespaces
- Per-user component checks
- HTTP endpoint validation
- Detailed health reporting
- Integration with agnosticd_user_info

## Testing
Tested on deployed environment with {num_users} users.
All components detected and validated successfully."

# Create AgnosticV PR
cd {agv_repo_path}
gh pr create --title "Add validation for {workshop_name}" \
  --body "## Summary
Integrates {collection_name}.ocp4_workload_{workshop_name}_validation.

## Changes
- Updated common.yaml with validation workload
- Added validation report section to info-message-template.adoc

## Validation Results
Displays health check summary in catalog info page."
```

If no, tell user:
```
Create PRs manually:

1. Collection repository PR:
   - Repository: {collection_repo_url}
   - Branch: add-{workshop_name}-validation → {default_branch}
   - Files: roles/ocp4_workload_{workshop_name}_validation/, playbooks/

2. AgnosticV repository PR:
   - Repository: agnosticv
   - Branch: add-{workshop_name}-validation → master
   - Files: agd_v2/{workshop_config_path}/common.yaml, info-message-template.adoc
```

### Step 6.2: Update AgnosticV to Use Released Collection

After collection PR is merged, tell user:
```
Once the collection PR is merged, we need to update AgnosticV to stop using the branch and use the released version.

Should I remove the branch reference from common.yaml?
```

If yes, read the AgnosticV common.yaml and DELETE the `agd_v2_collections` section that was added in Step 4.3:
```yaml
# DELETE this entire section:
agd_v2_collections:
  - name: {collection_name}
    source: {collection_repo_url}
    version: add-{workshop_name}-validation
```

**Important:**
- KEEP the validation workload in the workloads list
- ONLY remove the `agd_v2_collections` override
- This allows AgnosticV to use the released collection version from Galaxy or default source

Commit and push to AgnosticV branch with message:
```bash
git commit -m "Remove collection branch reference - use released version"
git push origin add-{workshop_name}-validation
```

### Step 6.3: Summary

Provide final summary:
```
✅ Validation role created: ocp4_workload_{workshop_name}_validation

Repositories:
- Collection: {collection_repo_url} (branch: add-{workshop_name}-validation)
- AgnosticV: agnosticv (branch: add-{workshop_name}-validation)

Files created:
- roles/ocp4_workload_{workshop_name}_validation/ (complete role)
- playbooks/validate_{workshop_name}.yml (test playbook)
- README.md (documentation)

Next steps:
1. Wait for PR approvals
2. Merge collection PR first
3. Then merge AgnosticV PR
4. Validation will run automatically on workshop deployments
```

## Important Patterns and Best Practices

### Boolean Values in AgnosticV common.yaml

**Note:** Validation role does NOT use boolean flags in AgnosticV - it runs unconditionally as a normal workload.

However, if you need to add other boolean values to AgnosticV for different purposes:

✅ DO: Use `| bool` filter for boolean values in AgnosticV
```yaml
ocp4_workload_example_feature_enabled: "{{ true | bool }}"
```

❌ DON'T: Use plain true/false without filter
```yaml
ocp4_workload_example_feature_enabled: true  # Will fail in AgnosticV
```

**Why:** AgnosticV requires Jinja2 template format with `| bool` filter for proper boolean handling.

### Type Safety
✅ DO: Add `| int` when setting counter variables
```yaml
_count: "{{ list | length | int }}"
```

✅ DO: Remove `| int` from comparisons (already integer)
```yaml
if _count > 0  # Correct
```

❌ DON'T: Compare strings to integers
```yaml
if _count | int > 0  # Unnecessary, _count already int
```

### Namespace Discovery
✅ DO: Auto-discover namespaces by pattern
```yaml
_namespace: "{{ all_namespaces | select('match', pattern) | first | default('') }}"
```

❌ DON'T: Hardcode namespace patterns
```yaml
_namespace: "showroom-{{ guid }}-{{ pool }}-{{ user }}"  # Too rigid
```

### Pod Counting
✅ DO: Get all pods, filter by name pattern
```yaml
- Get all pods in namespace
- Filter by name: selectattr('metadata.name', 'search', 'pattern')
```

❌ DON'T: Use label selectors (may not match actual labels)
```yaml
label_selectors:
  - app=myapp  # Fragile - actual label may differ
```

### Route Discovery
✅ DO: Get all routes in namespace
```yaml
- Get all routes (no name filter)
- Use first route found
```

❌ DON'T: Assume route name matches deployment
```yaml
name: "{{ deployment_name }}"  # May not match actual route
```

### Error Handling
✅ DO: Handle missing resources gracefully
```yaml
when: _namespace != ''
if resources is defined and not resources.skipped
ignore_errors: true
```

✅ DO: Provide specific, actionable error messages
```yaml
"user1 Showroom: namespace not found (expected pattern: showroom-*-user1)"
```

## Reference Examples

### Working Validation Roles

Check these for reference patterns:
- `/Users/psrivast/work/code/rhpds.aap_self_service_portal/roles/ocp4_workload_aap_multiinstance_validation/`
- `/Users/psrivast/work/code/rhpds.build-secured-dev-workflows/roles/rhads_validation/`

### Working Info Templates

Check this for reference:
- `/Users/psrivast/work/code/agnosticv/agd_v2/aap-multiinstance-workshop/info-message-template.adoc`

## Skill Invocation Summary

When user invokes this skill, follow this complete flow:

### Phase 1: Initial Setup (2 questions + auto-discovery)
1. Ask for local clone path (default: ~/work/code/)
2. Ask for workshop name and AgnosticV config path
3. Read common.yaml to discover collections, GitOps repos
4. Ask which collection to use and confirm automation method (workloads/GitOps/both)
5. Verify collection exists or clone it (offer options: clone to base_path, clone elsewhere, already cloned, different URL)
6. Verify GitOps repos exist or clone them (if applicable)

### Phase 2: Component Discovery (step-by-step commands)
1. Tell user to login to bastion
2. Provide ONE command at a time to discover components
3. Wait for output after each command
4. Analyze all outputs and confirm component identification

### Phase 3: Create Validation Role
1. Ask for collection repository URL and default branch
2. Create collection branch: add-{workshop_name}-validation
3. Generate role name and structure
4. Generate defaults/main.yml with component-specific settings
5. Generate component check tasks (Keycloak, AAP, Showroom, etc.)
6. Generate generate_report.yml with type-safe counters
7. Check for agnosticd_user_info plugin (copy if needed - agnosticd.core not on Galaxy)
8. Create test playbook: playbooks/validate_{workshop_name}.yml
9. Commit and push validation role to collection branch

### Phase 4: Update AgnosticV Configuration
1. Pull master and create AgnosticV branch
2. Update common.yaml to add validation workload (with essential variables: num_users, user_prefix)
3. Update common.yaml to use collection branch for integration testing
4. Update info-message-template.adoc with validation report section
5. Commit and push AgnosticV changes

### Phase 5: Testing on Bastion (8 steps)
1. SSH to bastion
2. Clone collection repository (using HTTPS URL)
3. Create Python virtual environment
4. Install pip packages (ansible, kubernetes, openshift, jmespath)
5. Install Ansible collections (kubernetes.core, ansible.posix)
6. Setup agnosticd_user_info plugin (install agnosticd.core from git OR copy plugin files)
7. Build and install collection
8. Run test playbook

Analyze results, iterate on fixes if needed, repeat testing.

### Phase 6: Final Deliverables
1. Confirm testing completed successfully on bastion
2. Create PRs (using gh CLI or provide manual instructions)
3. Update AgnosticV to use released collection after merge
4. Provide final summary with next steps

After completion:
- Collection branch: add-{workshop_name}-validation (pushed)
- AgnosticV branch: add-{workshop_name}-validation (pushed)
- Both ready for PR creation
- Validation tested and working on deployed environment
