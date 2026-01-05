# Demo Module Generator

Guide you through creating a Red Hat Showroom demo module using the Know/Show structure for presenter-led demonstrations.

## When to Use

**Use this skill when you want to**:
- Create presenter-led demo content
- Transform technical documentation into business-focused demos
- Add a module to an existing demo
- Create content for sales engineers or field demonstrations

**Don't use this for**:
- Hands-on workshop content → use `/lab-module`
- Converting to blog posts → use `/blog-generate`
- Reviewing existing content → use workshop-reviewer agent

## Shared Rules

**IMPORTANT**: This skill follows shared contracts defined in `.claude/skills/SKILL-COMMON-RULES.md`:
- Version pinning or attribute placeholders (REQUIRED)
- Reference enforcement (REQUIRED)
- Attribute file location (REQUIRED)
- Image path conventions (REQUIRED)
- Navigation update expectations (REQUIRED)
- Failure-mode behavior (stop if cannot proceed safely)

See SKILL-COMMON-RULES.md for complete details.

## Know/Show Structure

Demos use a different format than workshops:

- **Know sections**: Business context, customer pain points, value propositions, why this matters
- **Show sections**: Step-by-step presenter instructions, what to demonstrate, expected outcomes

This separates what presenters need to **understand** (business value) from what they need to **do** (technical demonstration).

## Workflow

### Step 1: Determine Context (First Module vs Continuation)

**First, I'll ask**:
- Is this the first module of a new demo, or continuing an existing demo?
- If continuing: Provide path to previous module (I'll auto-detect the story)

### Step 2: Plan Overall Demo Story (if first module)

If this is the first module, I'll gather the big picture:

1. **Demo overview**:
   - What's the overall message of this demo?
   - Example: "Show how OpenShift accelerates application deployment for enterprises"

2. **Target audience**:
   - Who will see this demo? (C-level, Sales engineers, Technical managers, Partners)
   - Their business priorities? (Cost reduction, faster time-to-market, competitive advantage)

3. **Business transformation story**:
   - What's the customer challenge you're solving?
   - What's the current state pain?
   - What's the desired future state?

4. **Customer scenario**:
   - What company/industry should we use?
   - Default: "RetailCo", "FinanceCorp", "TechSolutions" or custom
   - Specific business challenge driving urgency?

5. **Key metrics to showcase**:
   - What quantifiable improvements to highlight?
   - Example: "6 weeks → 5 minutes deployment time"

6. **Estimated demo duration**:
   - How long should complete demo take? (15min, 30min, 45min)

**Then I'll recommend**:
- Suggested module/section breakdown
- Know/Show structure for each section
- Business narrative arc across modules
- Key proof points and "wow moments"
- Competitive differentiators to emphasize

**You can**:
- Accept the recommended flow
- Adjust sections and messaging
- Change business emphasis

### Step 2.5: AgnosticV Configuration Assistance

Now that we have the overall demo story, let's determine if this demo needs AgnosticV integration.

**What is AgnosticV?**
AgnosticV (AgV) defines catalog items in Red Hat Demo Platform (RHDP) that provision demo environments. If your demo needs a live OpenShift cluster or infrastructure, you'll likely need an AgV catalog.

#### Access Check

**Ask for AgnosticV path:**

```
Q: Do you have access to the AgnosticV repository? If yes, provide the directory path:

Example paths:
- ~/work/code/agnosticv/
- ~/projects/agnosticv/
- /path/to/agnosticv/

Your AgV path: [Enter path or 'skip' if you don't have access]
```

**If user provides valid path:**
- Use that path for catalog search and creation
- Continue to catalog search workflow ↓

**If user doesn't have access ('skip' or invalid path):**

```
ℹ️ **No AgnosticV Access**

Your demo can still be deployed via RHDP, but AgV catalog creation requires access.

**Recommendation:**

Contact RHDP developers to help create your AgV catalog.

**What I can suggest for reuse:**

Based on your demo "{{ demo_name }}" with technologies {{ tech_keywords }},
I recommend these existing catalogs as a good base:

1. **{{ suggested_catalog_1 }}** (Best match)
   - Display name: "{{ catalog_1_name }}"
   - Technologies: {{ catalog_1_tech }}
   - Category: {{ catalog_1_category }}

2. **{{ suggested_catalog_2 }}** (Alternative)
   - Display name: "{{ catalog_2_name }}"
   - Technologies: {{ catalog_2_tech }}

**Share this with RHDP developers** when requesting AgV catalog creation.

For now, I'll continue with placeholder attributes in your demo content:
- {openshift_console_url}
- {user}, {password}
- {openshift_api_url}

→ Proceeding to Step 3: Module-Specific Details
```

**If ACCESS confirmed (default or provided path):**

#### AgnosticV Decision Flow

**Q1: Does this demo need a deployed environment?**
- "No, it's presentation slides only" → Skip AgV, proceed to Step 3
- "Yes, it needs OpenShift/infrastructure" → Continue ↓

**Q2: Do you already have an AgnosticV catalog for this demo?**
- "Yes, catalog name: [name]" → Use existing, extract variables, proceed to Step 3
- "No, but help me find one" → Show Recommendations ↓
- "No, I need to create one" → Creation Workflow ↓
- "I'm not sure" → Show Recommendations ↓

#### Q3: User-Suggested Catalog Search (NEW)

**Before automatic keyword search, I'll ask:**

**Q3: Do you think there's an existing catalog that could be a good base for this demo?**

**Options:**
- "Yes, I know of one" → Continue to Q3a ↓
- "No" or "Not sure" → Skip to Keyword Recommendations ↓

**If user answers "Yes" to Q3:**

**Q3a: What's the catalog display name or slug?**

Examples:
- Display name: "Agentic AI on OpenShift", "OpenShift AI Executive Demo"
- Catalog slug: "agentic-ai-openshift", "openshift-ai-executive"

**I'll search AgV catalogs by:**
1. `__meta__.catalog.display_name` (partial match, case-insensitive)
2. Catalog directory slug (partial match)
3. Keywords in `__meta__.catalog.keywords`
4. Category match

**Scoring:**
- Display name match: 50 points
- Catalog slug match: 40 points
- Keyword match: 10 points each
- Category match: 5 points

**If found, I'll show:**
```markdown
**Search Results for "{{ user_input }}":**

Found {{ count }} catalog(s):

1. **"Agentic AI on OpenShift"** (65 points ⭐⭐⭐)
   - Catalog slug: agentic-ai-openshift
   - Category: Workshops
   - Multi-user: Yes (5-40 users)
   - Infrastructure: CNV multi-node (16 cores, 64Gi per worker)
   - Key workloads:
     - rhpds.litellm_virtual_keys.ocp4_workload_litellm_virtual_keys
     - agnosticd.ai_workloads.ocp4_workload_openshift_ai
     - agnosticd.core_workloads.ocp4_workload_pipelines
   - OpenShift: 4.18+
   - Path: agd_v2/agentic-ai-openshift

2. **"Summit 2025 AI Demo"** (25 points ⭐⭐)
   - Catalog slug: summit-2025-ai-demo
   [Similar details...]

**Options:**
1. Use catalog #1 as-is
2. Create new catalog based on #1 structure
3. See details for catalog #2
4. Go back to keyword search

Your choice? [1/2/3/4]
```

**If user chooses "Use catalog #1 as-is":**
→ Extract UserInfo variables from this catalog
→ Proceed to Step 3 with catalog context

**If user chooses "Create new based on #1":**
→ Copy structure from chosen catalog
→ Proceed to Creation Workflow ↓

**If user chooses "Go back to keyword search":**
→ Proceed to Keyword Recommendations ↓

**If NO results found:**
```markdown
No catalogs found matching "{{ user_input }}".

**Try:**
- Different spelling or keywords
- Catalog slug instead of display name
- Let me search by technology keywords from your demo plan

Search again or proceed to keyword recommendations? [Search again/Keywords]
```

#### Keyword-Based Catalog Recommendations

**If user chose "No/Not sure" to Q3, or requested keyword search:**

I'll search existing agd_v2 catalogs based on:
- Technology keywords from your demo plan ({{ tech_keywords }})
- Business value propositions ({{ value_props }})
- Demo vs Workshop type

**Recommendation Algorithm:**
1. Extract keywords from Step 2 (AI, pipelines, platform value, etc.)
2. Search catalog display names and slugs
3. Analyze workload lists in `common.yaml`
4. Score by relevance
5. Show top 3-5 matches

**Example Output:**
```markdown
**Recommended AgnosticV Catalogs:**

Based on "{{ demo_name }}" with technologies: {{ tech_list }}

1. **openshift-ai-executive-demo** (Match score: 40 ⭐⭐⭐)
   - Multi-user: No (dedicated for demos)
   - Category: Demos
   - Key workloads: openshift_ai, litellm, gpu_operator
   - Infrastructure: AWS with GPU (g6.4xlarge)
   - Best for: Executive/sales AI demonstrations

2. **agentic-ai-openshift** (Match score: 30 ⭐⭐)
   - Multi-user: Yes (can be used for demos too)
   - Category: Workshops
   - Key workloads: litellm_virtual_keys, openshift_ai, pipelines
   - Infrastructure: CNV multi-node
   - Best for: Technical deep-dive demos

3. **summit-2025-platform-value** (Match score: 20 ⭐⭐)
   - Multi-user: No (dedicated)
   - Category: Demos
   - Key workloads: minimal setup, pre-configured apps
   - Infrastructure: CNV
   - Best for: Quick platform overviews

**Options:**
- Use one of these catalogs: [Enter 1, 2, or 3]
- View workloads in detail: [Enter catalog name]
- Create new catalog instead: [Enter 'new']
- Skip AgV for now: [Enter 'skip']

Your choice?
```

**If user selects existing catalog:**
→ Extract UserInfo variables
→ Proceed to Step 3

**If user selects "Create new":**
→ Proceed to Creation Workflow ↓

#### AgV Catalog Creation Workflow

**If user chose "create new" or none matched:**

##### Step 1: Multi-user vs Dedicated Guidance

```markdown
**Catalog Type Recommendation**

Q: Should this be multi-user or dedicated?

**Dedicated** (Recommended for Demos):
✓ Presenter-led demonstrations
✓ Executive/sales demos
✓ Consistent demo experience
✓ Pre-configured environments
✓ Single presenter control

Example: "OpenShift AI CTO Demo"
→ One dedicated cluster per demo instance

**Multi-user** (For Demo Workshops):
✓ Hands-on demo sessions with audience participation
✓ Interactive workshops with 5-20 participants
✓ Cost-effective for larger groups
✓ Good for partner enablement

Example: "Partner Technical Enablement Demo"
→ One cluster with multiple user accounts

**Special Cases (Always Dedicated):**
- Executive demos (C-level, sales)
- Pre-sales technical briefings
- Non-OpenShift workloads (VMs, edge)
- GPU-accelerated demos

**Your demo:**
- Type: {{ demo_type }} (Presenter-led)
- Audience: {{ target_audience }}
- Expected instances: {{ instance_count }}

**Recommendation:** Dedicated

Is this correct? [Yes/No/Customize]
```

##### Step 2: Infrastructure Pattern Selection

```markdown
**Infrastructure Recommendation**

Based on your demo requirements:

**Recommended: {{ recommended_infra }}**

**CNV (Container-Native Virtualization)** ← Default for most demos
✓ Fast provisioning (10-15 mins)
✓ Cost-effective
✓ Sufficient for standard OpenShift demos
✓ Predictable performance

**SNO (Single Node OpenShift)**
✓ Fastest provisioning (5-10 mins)
✓ Lightweight demos
✓ Edge computing scenarios
✓ Quick platform overviews

**AWS (GPU/Cloud-Specific)**
✓ GPU acceleration (NVIDIA) for AI demos
✓ Large memory for model training
✓ Cloud-native service integration (S3, etc.)
⚠️ Slower provisioning (30-45 mins)
⚠️ Higher cost, reserve for GPU needs

**Your needs:**
- Technology stack: {{ tech_stack }}
- GPU required: {{ gpu_needed }}
- Demo type: {{ demo_type }}
- Memory requirements: {{ memory_needs }}

**Recommendation:** {{ recommended_infra }}

Proceed? [Yes/Customize]
```

**[Steps 3-7 are identical to lab-module.md: Collection Selection, Directory Selection, Git Workflow, Config Generation, Post-Creation Git]**

##### Step 3: Collection Selection

```markdown
**Required Collections for AgV Config**

Based on "{{ tech_stack }}":

**Always include:**
✓ agnosticd.core_workloads
  - Authentication (Keycloak for demos)
  - Base OpenShift capabilities

{% if 'ai' in tech_keywords or 'ml' in tech_keywords %}
**AI/ML Collections:**
✓ agnosticd.ai_workloads
  - OpenShift AI operator
  - GPU operator (if needed)
  - OLS (OpenShift Lightspeed)

{% if 'llm' in tech_keywords or 'model' in tech_keywords %}
✓ rhpds.litellm_virtual_keys (recommended for AI demos)
  - LiteLLM proxy for model access
  - Pre-configured API keys
{% endif %}
{% endif %}

{% if 'pipeline' in tech_keywords or 'gitops' in tech_keywords %}
**DevOps/GitOps Collections:**
✓ Core workloads include:
  - ocp4_workload_pipelines
  - ocp4_workload_openshift_gitops
  - ocp4_workload_gitea_operator
{% endif %}

**Demo Content Delivery:**
✓ agnosticd.showroom
  - Demo content platform
  - Know/Show structure support
  - Presenter terminal

Include these collections? [Yes/Customize]
```

##### Step 4: Directory Selection

```markdown
**Where to create this catalog?**

Recommended AgnosticV directories:

1. **agd_v2/** ← Default, most workshops/demos
2. **enterprise/** (Red Hat internal only)
3. **summit-2025/** (Event-specific, time-bound)
4. **ansiblebu/** (Ansible Automation Platform focus)

**Your demo:** {{ demo_name }}
**Suggested:** agd_v2/{{ suggested_slug }}

Which directory? [1-4 or custom path]
```

##### Step 5: Git Workflow (CRITICAL)

```markdown
**Git Setup Before Creating Catalog**

To ensure we're working with the latest AgnosticV:

**Pre-creation steps:**

1. **Switch to main branch:**
   ```bash
   cd ~/work/code/agnosticv
   git checkout main
   ```

2. **Pull latest changes:**
   ```bash
   git pull origin main
   ```

3. **Create new branch:**
   ```bash
   git checkout -b {{ catalog_slug }}
   ```

   **Branch name:** {{ catalog_slug }}
   **IMPORTANT:** No "feature/" prefix per AgV convention

   **Examples:**
   - ✓ `openshift-ai-executive-demo`
   - ✓ `platform-value-summit-2025`
   - ✗ `feature/ai-demo` (DON'T USE)

4. **Create catalog directory:**
   ```bash
   mkdir -p agd_v2/{{ catalog_slug }}
   ```

Ready to proceed? [Yes/Customize branch name/Skip git setup]
```

##### Step 6: Generate AgV Config Files

```markdown
**Creating AgnosticV Catalog Configuration**

I'll create these files following agd_v2 best practices:

📁 ~/work/code/agnosticv/{{ directory }}/{{ catalog_slug }}/
├── common.yaml          # Main configuration
├── description.adoc     # Catalog description
└── dev.yaml            # Development overrides

**Configuration summary:**
- Display name: "{{ suggested_display_name }}" (you can customize)
- Type: {{ multiuser_type }} (Dedicated for demos)
- Infrastructure: {{ infra_type }}
- Collections: {{ collections_list }}
- Workloads: {{ workloads_list }}
- Users: {{ 'Single presenter' if dedicated else user_range }}
- OpenShift: {{ ocp_version }}
- UUID: Will generate using `uuidgen` command

**Display Name Suggestion:**

Based on your demo "{{ demo_name }}", I suggest:

**Display name:** "{{ suggested_display_name }}"

Examples:
- "OpenShift Platform Value Executive Demo"
- "AI Model Serving with OpenShift AI"
- "Edge Computing with MicroShift"

Customize? [Use suggested/Enter custom name]

**common.yaml will include:**

1. **Header comments:**
   - Catalog name
   - Catalog item description

2. **AgnosticV includes:**
   ```yaml
   #include /includes/agd-v2-mapping.yaml
   #include /includes/sandbox-api.yaml
   #include /includes/catalog-icon-openshift.yaml
   #include /includes/terms-of-service.yaml
   ```

3. **Mandatory variables:**
   ```yaml
   tag: main
   ```

4. **Cluster configuration:**

   **RECOMMENDED: OpenShift with Pools** (`config: openshift-workloads` - components):
   ```yaml
   config: openshift-workloads  # RECOMMENDED - uses existing OCP pools
   cloud_provider: none
   software_to_deploy: none

   # Connect to existing pool via API
   clusters:
   - default:
       api_url: "{{ openshift_api_url }}"
       api_token: "{{ openshift_cluster_admin_token }}"

   # Demos typically don't need scaling (dedicated cluster)
   # Optional: enable if demo needs worker scaling
   # openshift_cnv_scale_cluster: true
   ```

   **Available Pools** (referenced by API - SNO 4.20 default for demos):
   - OpenShift 4.20: SNO (RECOMMENDED for dedicated demos)
   - OpenShift 4.20: Multi-node (if demo requires multi-node architecture)
   - OpenShift 4.18: SNO and Multi-node (legacy support)

   **Alternative: OpenShift Direct Provisioning** (`config: openshift-cluster` - NO pools):
   ```yaml
   cloud_provider: openshift_cnv  # or aws for GPU demos
   cloud_provider_version: main
   config: openshift-cluster  # Provisions new cluster, not pool-based

   # For CNV direct provisioning
   openshift_cnv_set_sandbox_provision_data: true
   cluster_size: sno  # Dedicated for demos
   host_ocp4_installer_version: "4.20"

   # For AWS GPU demos
   # cloud_provider: aws
   # control_plane_instance_type: g6.4xlarge  # NVIDIA GPU
   ```

   **For Non-OpenShift VM-based Workloads** (`config: cloud-vms-base`):
   ```yaml
   cloud_provider: openshift_cnv
   cloud_provider_version: main
   config: cloud-vms-base  # Non-OpenShift VMs (AAP, RHEL demos)

   # Individual VM instances
   bastion_instance_image: rhel-9.5
   bastion_cores: 2
   bastion_memory: 4Gi

   controller_instance_image: aap-2.6-2-ceh-20251103
   # ... additional VMs
   ```

   **Config Types Summary:**
   - **`config: openshift-workloads`** → RECOMMENDED - Uses existing OCP pools (components)
   - **`config: openshift-cluster`** → Legacy - Provisions new OCP cluster (no pools)
   - **`config: cloud-vms-base`** → Non-OpenShift VMs (AAP, RHEL demos)

5. **Requirements (collections):**
   ```yaml
   requirements_content:
     collections:
     - name: https://github.com/agnosticd/core_workloads.git
       type: git
       version: "{{ tag }}"
     # ... other collections based on selection
   ```

6. **Workloads list:**
   ```yaml
   workloads:
   - agnosticd.core_workloads.ocp4_workload_authentication_keycloak  # For demos
   - agnosticd.showroom.ocp4_workload_showroom
   # ... other workloads
   ```

7. **Metadata (__meta__):**
   ```yaml
   __meta__:
     asset_uuid: {{ generated_uuid }}  # From `uuidgen` command
     owners:
       maintainer:
       - name: {{ your_name }}
         email: {{ your_email }}
     anarchy:
       namespace: babylon-anarchy-7
     deployer:
       scm_url: https://github.com/agnosticd/agnosticd-v2
       scm_ref: main
       execution_environment:
         image: quay.io/agnosticd/ee-multicloud:chained-2025-10-09
         pull: missing
     catalog:
       namespace: babylon-catalog-{{ stage | default('?') }}
       display_name: {{ display_name }}
       category: Demos
       keywords:
       - openshift
       - {{ tech_keywords }}
       labels:
         Product: Red_Hat_OpenShift_Container_Platform
   ```

**I'll generate UUID by running:**
```bash
uuidgen
```

**description.adoc will include:**

Following existing AgV format:

```asciidoc
Catalog Item for *{{ display_name }}*

*Product(s):*

* Red Hat OpenShift Container Platform
* {{ additional_products }}

== Specifications

* Deployer: AgnosticD V2
* Dedicated cluster for presenter-led demonstration
* Cluster version: {{ ocp_version }}
* Authentication enabled (Keycloak for demos)
* Certificates enabled on Ingress controllers
{% if showroom %}
* Demo content platform: Showroom (Know/Show structure)
{% endif %}

== Supporting Materials

*Provisioning time:* Typically, ~{{ estimated_time }} min
{% if showroom %}
*Demo URL:* Available in provisioning email
{% endif %}
```

**dev.yaml will include:**
```yaml
---
purpose: development
# SCM ref override for development/testing
```

Generate files now? [Yes/Review plan first]
```

##### Step 7: Post-Creation Git Workflow

```markdown
**Commit Your New Catalog**

Files created:
- agd_v2/{{ catalog_slug }}/common.yaml ({{ line_count }} lines)
- agd_v2/{{ catalog_slug }}/description.adoc
- agd_v2/{{ catalog_slug }}/dev.yaml

**Commit workflow:**

1. **Review changes:**
   ```bash
   cd ~/work/code/agnosticv
   git status
   git diff
   ```

2. **Add files:**
   ```bash
   git add agd_v2/{{ catalog_slug }}/
   ```

3. **Commit:**
   ```bash
   git commit -m "Add {{ catalog_display_name }} catalog

   - Multi-user: {{ multiuser }}
   - Infrastructure: {{ infra_type }}
   - Collections: {{ collections_list }}
   - Target: Demo (presenter-led)"
   ```

4. **Push branch:**
   ```bash
   git push -u origin {{ catalog_slug }}
   ```

**Next steps:**
1. Test locally: `agnosticv_cli --config agd_v2/{{ catalog_slug }}/dev.yaml`
2. Open PR when ready for production deployment
3. Tag RHDP developers for review: @psrivast @tyrell @juliano

Create commit now? [Yes/I'll do it manually]
```

#### Summary and Next Steps

**After AgV assistance completes:**

```
✓ AgV Configuration Complete

**Selected catalog:** {{ catalog_name }}

**Next:**
- I'll extract UserInfo variables from this catalog's workloads
- Use these variables in your Know/Show demo content
- Example variables available:
  - {openshift_console_url}
  - {user}, {password}
  - {openshift_api_url}
  - [workload-specific variables for demos]

**Note for demos:** Variables support your Know/Show structure with presenter guidance

→ Proceeding to Step 3: Module-Specific Details
```

### Step 3: Gather Module-Specific Details

Now for this specific module:

1. **Module file name**:
   - Module file name (e.g., "03-demo-intro.adoc", "04-platform-demo.adoc")
   - Files go directly in `content/modules/ROOT/pages/`
   - Pattern: `[number]-[topic-name].adoc`

2. **AgnosticV catalog item** (optional but recommended):
   - Is this based on an AgnosticV catalog item?
   - If yes: Provide catalog item name (e.g., "ocp4_workload_rhods_demo")
   - Default AgnosticV path: `~/work/code/agnosticv/`
   - I'll read the catalog item to extract UserInfo variables

3. **Reference materials**:
   - URLs to Red Hat docs
   - Local files (Markdown, AsciiDoc, PDF)
   - Or paste content directly

4. **Target audience**:
   - Sales engineers, C-level executives, technical managers, developers

5. **Business scenario/challenge**:
   - Auto-detect from previous module (if exists)
   - Or ask for customer scenario (e.g., "RetailCo needs faster deployments")

6. **Technology/product focus**:
   - Example: "OpenShift", "Ansible Automation Platform"

7. **Number of demo parts**:
   - Recommended: 2-4 parts (each with Know/Show sections)

8. **Key metrics/business value**:
   - Example: "Reduce deployment time from 6 weeks to 5 minutes"

9. **Diagrams, screenshots, or demo scripts** (optional):
   - Do you have architecture diagrams, demo screenshots, or scripts?
   - If yes: Provide file paths or paste content
   - I'll save them to `content/modules/ROOT/assets/images/`
   - And reference them properly in Show sections

### Step 4: Extract AgnosticV UserInfo Variables (if applicable)

If you provided an AgnosticV catalog item, I'll:

**Read AgnosticV catalog configuration**:
- Location: `~/work/code/agnosticv/`
- Find catalog item directory: `catalogs/<item-name>/`
- Read `common.yaml` for workload list and variables

**Identify workload roles from AgnosticD**:
- AgnosticD v2: `~/work/code/agnosticd-v2/`
- AgnosticD v1: `~/work/code/agnosticd/`
- Read workload roles referenced in common.yaml

**Extract UserInfo variables**:
- Search for `agnosticd_user_info` tasks in workload roles
- Extract variables from `data:` sections
- Map to Showroom attributes for demo content

**Common demo variables**:
- `openshift_console_url` → For showing presenter where to log in
- `api_url`, `dashboard_url` → For product-specific UIs
- `user_name`, `user_password` → For demo credentials
- Custom workload variables → Product-specific endpoints

**Result**: I'll use these in Show sections for precise presenter instructions.

### Step 5: Handle Diagrams, Screenshots, and Demo Scripts (if provided)

If you provided visual assets or scripts:

**For presenter screenshots**:
- Save to `content/modules/ROOT/assets/images/`
- Use descriptive names showing what presenters will see
- Reference in Show sections with proper context:
  ```asciidoc
  image::console-developer-view.png[align="center",width=700,title="Developer Perspective - What Presenters Will See"]
  ```

**For architecture diagrams**:
- Save with business-context names: `retail-transformation-architecture.png`
- Reference in Know sections to show business value
- Use larger width (700-800px) for visibility during presentations

**For demo scripts or commands**:
- Format in code blocks with syntax highlighting
- Add presenter notes about what to emphasize:
  ```asciidoc
  [source,bash]
  ----
  oc new-app https://github.com/example/nodejs-ex
  ----

  [NOTE]
  ====
  **Presenter Tip:** Emphasize how this single command eliminates 3-5 days of manual setup.
  ====
  ```

**For before/after comparisons**:
- Save both images: `before-manual-deployment.png`, `after-automated-deployment.png`
- Use side-by-side or sequential placement
- Highlight business transformation visually

**Recommended image naming for demos**:
- Business context: `customer-challenge-overview.png`, `transformation-roadmap.png`
- UI walkthroughs: `step-1-login-console.png`, `step-2-create-project.png`
- Results: `deployment-success.png`, `metrics-dashboard.png`
- Comparisons: `before-state.png`, `after-state.png`

### Step 6: Fetch and Analyze References

Based on your references, I'll:
- Fetch URLs and extract technical capabilities
- Read local files
- Identify business value propositions
- Extract metrics and quantifiable benefits
- Map technical features to business outcomes
- Combine with AgnosticV variables (if provided)
- Integrate provided diagrams and screenshots strategically

### Step 7: Read Demo Templates

I'll read these before generating:
- `content/modules/ROOT/pages/demo/03-module-01.adoc`
- `content/modules/ROOT/pages/demo/01-overview.adoc`
- `.claude/prompts/redhat_style_guide_validation.txt`

### Step 8: Generate Demo Module

I'll create a module with Know/Show structure:

**CRITICAL: Demo Talk Track Separation**:
Demo modules MUST separate presenter guidance from technical steps:

**Required structure** for each Show section:
```asciidoc
=== Show

**What I say**:
"We're seeing companies like yours struggle with 6-8 week deployment cycles. Let me show you how OpenShift reduces that to minutes."

**What I do**:
. Log into OpenShift Console at {console_url}
. Navigate to Developer perspective
. Click "+Add" → "Import from Git"

**What they should notice**:
✓ No complex setup screens
✓ Self-service interface
✓ **Metric highlight**: "This used to take 6 weeks, watch what happens..."

**If asked**:
Q: "Does this work with our existing Git repos?"
A: "Yes, OpenShift supports GitHub, GitLab, Bitbucket, and private Git servers."

Q: "What about security scanning?"
A: "Built-in. I'll show that in part 2."
```

**Labs should NOT include talk tracks** - labs are for hands-on learners, not presenters.

**For each demo part**:

**Know Section**:
- Business challenge explanation
- Current state vs desired state
- Quantified pain points
- Stakeholder impact
- Value proposition

**Show Section**:
- **Optional visual cues** (recommended but not required)
- Step-by-step presenter instructions
- Specific commands and UI interactions
- Expected screens/outputs
- Image placeholders for key moments
- Business value callouts during demo
- Troubleshooting hints

**Example Structure**:
```asciidoc
== Part 1 — Accelerating Application Deployment

=== Know
_Customer challenge: Deployment cycles take 6-8 weeks, blocking critical business initiatives._

**Business Impact:**
* Development teams wait 6-8 weeks for platform provisioning
* Black Friday deadline in 4 weeks is at risk
* Manual processes cause errors and rework
* Competition is shipping features faster

**Value Proposition:**
OpenShift reduces deployment time from weeks to minutes through self-service developer platforms and automated CI/CD pipelines.

=== Show

**Optional visual**: Before/after deployment timeline diagram showing 6-8 weeks vs 2 minutes

* Log into OpenShift Console at {openshift_console_url}
  * Username: {user}
  * Password: {password}

* Navigate to Developer perspective → +Add

* Select "Import from Git" and enter:
  * Git Repo: `https://github.com/example/nodejs-ex`
  * Application name: `retail-checkout`
  * Deployment: Create automatically

* Click "Create" and observe:
  * Build starts automatically
  * Container image is built
  * Application deploys in ~2 minutes

image::deployment-progress.png[align="center",width=700,title="Deployment in Progress"]

* **Business Value Callout**: "What used to take your team 6-8 weeks just happened in 2 minutes. Developers can now deploy independently without waiting for infrastructure teams."

* Show the running application:
  * Click the route URL
  * Demonstrate the live application
  * Highlight the automatic scaling capability

* Connect to business outcome:
  "This self-service capability means your development team can meet the 4-week Black Friday deadline and ship updates daily instead of quarterly."
```

**Optional Visual Cues** (Recommended):

Add lightweight visual guidance without forcing asset creation:

```asciidoc
=== Show

**Optional visual**: Architecture diagram showing component relationships
**Optional slide**: Customer pain points - 6-8 week deployment cycles
**Optional visual**: Before/after comparison of manual vs automated workflow

[...presenter actions follow...]
```

**Cue Examples**:
- "Optional visual: Architecture diagram showing component relationships"
- "Optional slide: Customer pain points - 6-8 week deployment cycles"
- "Optional visual: Before/after comparison of manual vs automated workflow"
- "Optional diagram: Pipeline flow from commit to production"

**Guidelines**:
- Always mark as "Optional visual:" or "Optional slide:"
- Don't make demo depend on it
- Helps presenters prepare assets if they want
- Keeps demos tight without forcing asset creation

### Step 9: Validate

I'll automatically run:
- **workshop-reviewer** agent: Validates structure
- **style-enforcer** agent: Applies Red Hat style standards
- Verify Know/Show balance and business focus

### Step 10: Update Navigation (REQUIRED)

I'll automatically add the module to `content/modules/ROOT/nav.adoc` - this is REQUIRED for the module to appear in the Showroom sidebar.

**What I'll add**:
```asciidoc
* xref:<module-file>[<Module Number>. <Module Title>]
** xref:<module-file>#part-1[Part 1: <Title>]
** xref:<module-file>#part-2[Part 2: <Title>]
```

**Note**: Without this nav.adoc entry, your demo won't be accessible in Showroom!

### Step 11: Deliver

You'll get:

**Generated files**:
- Complete demo module at `content/modules/ROOT/pages/<module-file>.adoc`
- Images saved to `content/modules/ROOT/assets/images/` (if provided)
- Proper AsciiDoc references for all visual assets

**Presenter documentation**:
- Screenshot capture guide (for images you still need to capture)
- Navigation xref snippet
- Presenter notes and tips
- Business talking points for each section
- Next module suggestions

**Asset summary**:
- List of diagrams/screenshots included with references
- List of images still needed (placeholders for you to capture)
- Demo scripts formatted with presenter tips
- Before/after comparisons properly placed

## Example Usage

### Example 1: Create First Demo Module with Overall Story Planning

```
User: Create a demo showing OpenShift value for C-level executives

Skill: Excellent! Since this is a new demo, let me gather the overall story first.

**Overall Demo Planning:**

Q: Is this the first module or continuing existing demo?
A: First module of a new demo

Q: What's the overall message?
A: "Show how OpenShift reduces time-to-market and operational costs for enterprises"

Q: Target audience?
A: C-level executives (CTO, CIO) evaluating platform modernization

Q: What are their business priorities?
A: - Reduce operational costs
   - Faster feature delivery to stay competitive
   - Risk mitigation (security, compliance)

Q: Business transformation story?
A: Current state: Manual deployments take 6-8 weeks, blocking business initiatives
   Desired state: Self-service platform enabling daily deployments

Q: Customer scenario?
A: "RetailCo" - Retail company facing Black Friday deadline with current 10-week deployment cycles

Q: Key metrics to showcase?
A: - 8 weeks → 10 minutes deployment time
   - 80% reduction in infrastructure costs
   - 95% reduction in security vulnerabilities

Q: Demo duration?
A: 30 minutes total

**Recommended Demo Flow:**

Based on your goals, I recommend 2 modules:

Module 1: Platform Value & Developer Experience (15 min)
- Know: RetailCo's deployment challenge, business impact
- Show: Self-service deployment demonstration
- Proof point: 8 weeks → 10 minutes
- Story: Developer empowerment, IT team efficiency

Module 2: Business Continuity & ROI (15 min)
- Know: Cost structure, security posture improvements
- Show: Auto-scaling, built-in security scanning
- Proof point: 80% cost reduction, 95% fewer vulnerabilities
- Story: Strategic platform investment ROI

Does this flow work for you, or adjustments needed?

User: Perfect! Create Module 1.

Skill: Great! Now let me gather details for Module 1...

Q1: Module file name? → "03-platform-value.adoc"
Q2: AgnosticV catalog item? → "ocp4_workload_demo"
Q3: Reference materials? → https://www.redhat.com/en/technologies/cloud-computing/openshift
Q4: Target audience details? → C-level (using overall)
Q5: Business scenario? → "RetailCo" (using overall story)
Q6: Technology? → "OpenShift Container Platform"
Q7: Demo parts? → 3
Q8: Key metrics? → "8 weeks → 10 minutes" (using overall)
Q9: Diagrams? → Architecture diagram: ~/diagrams/retail-platform.png

[Generates Module 1 with RetailCo story]
[Sets up story arc for Module 2]

✓ Created: content/modules/ROOT/pages/03-platform-value.adoc
✓ Story established: RetailCo's platform modernization journey
✓ Business metrics integrated throughout
✓ Module flow documented for Module 2
✓ Ready for Module 2 (will auto-continue story)
```

### Example 2: Basic Demo Creation

```
User: Create demo Module 1 for OpenShift using:
      https://docs.openshift.com/container-platform/4.14/

Skill: I'll create that demo module. Let me ask questions...
       [asks if first module or continuing]
       [if first: asks overall story questions]
       [asks module-specific questions]
       [generates module with business story]
       [validates with agents]

✓ Created: content/modules/ROOT/pages/03-platform-demo.adoc
✓ Presenter notes included
✓ Screenshot guide provided
✓ Navigation updated
```

### Example 3: Create Demo with Architecture Diagrams

```
User: Create demo for OpenShift AI value proposition. I have:
      - Architecture diagram: ~/diagrams/ai-platform-architecture.png
      - Before/after workflow diagrams

Skill: Excellent! Let me gather details...

Q1: Module file name? → "03-ai-platform-demo.adoc"
Q2: AgnosticV catalog item? → "ocp4_workload_rhods_demo"
Q3: Reference materials? → https://www.redhat.com/en/technologies/cloud-computing/openshift/openshift-ai
Q4: Target audience? → C-level executives
Q5: Business scenario? → "TechCorp needs faster AI model deployment"
Q6: Technology? → "Red Hat OpenShift AI"
Q7: Demo parts? → 3
Q8: Key metrics? → "Weeks to hours for model deployment"
Q9: Diagrams/screenshots? → Yes:
    - Architecture: ~/diagrams/ai-platform-architecture.png
    - Before workflow: ~/diagrams/before-manual-ml.png
    - After workflow: ~/diagrams/after-automated-ml.png

Skill: Perfect! Processing diagrams and creating demo...

[Saves diagrams to assets/images/]
→ ai-platform-architecture.png
→ before-manual-ml.png
→ after-automated-ml.png

[Generates demo with:]
- Part 1 Know section includes architecture diagram
- Part 1 Show section references the architecture
- Part 2 Know section uses before/after comparison
- Each diagram has business-focused captions
- Presenter tips for discussing diagrams

Example output:
```asciidoc
== Part 1 — AI Platform Overview

=== Know
_TechCorp's data scientists wait weeks for infrastructure, delaying critical AI initiatives._

image::ai-platform-architecture.png[align="center",width=800,title="Red Hat OpenShift AI Platform Architecture"]

**Current Challenge:**
* 2-3 weeks to provision ML infrastructure
* Manual environment setup prone to errors
* Inconsistent tooling across teams

=== Show
* Show the architecture diagram and explain:
  "This is how OpenShift AI eliminates infrastructure delays..."

* Log into OpenShift AI Dashboard at {rhods_dashboard_url}

[NOTE]
====
**Presenter Tip:** Point to the architecture diagram as you navigate the UI.
Show how the platform maps to the architectural components.
====
```

✓ Created: content/modules/ROOT/pages/03-ai-platform-demo.adoc
✓ 3 diagrams saved and referenced appropriately
✓ Before/after comparison integrated in Know section
✓ Presenter notes tied to visual elements
```

## Know Section Best Practices

Good Know sections include:

**Business Challenge**:
- Specific customer pain point
- Current state with metrics
- Why it matters now (urgency)

**Current vs Desired State**:
- "Now: 6-8 week deployment cycles"
- "Goal: Deploy multiple times per day"

**Stakeholder Impact**:
- Who cares: "VP Engineering, Product Managers"
- Why: "Missing market windows, losing to competitors"

**Value Proposition**:
- Clear benefit statement
- Quantified outcome
- Business language, not tech jargon

## Show Section Best Practices

Good Show sections include:

**Clear Instructions**:
- Numbered steps
- Specific UI elements ("Click Developer perspective")
- Exact field values to enter

**Expected Outcomes**:
- What presenters should see
- Screenshots of key moments
- Success indicators

**Business Callouts**:
- Connect each technical step to business value
- Use phrases like "This eliminates..." or "This reduces..."
- Quantify where possible

**Presenter Tips**:
- Common questions to expect
- Troubleshooting hints
- Pacing suggestions

## Tips for Best Results

- **Specific metrics**: "6 weeks → 5 minutes" not "faster deployments"
- **Real scenarios**: Base on actual customer challenges
- **Visual emphasis**: Demos need more screenshots than workshops
- **Business language**: Executives care about outcomes, not features
- **Story arc**: Build narrative across parts

## Quality Standards

Every demo module will have:
- ✓ Know/Show structure for each part
- ✓ Business context before technical steps
- ✓ Quantified metrics and value propositions
- ✓ Clear presenter instructions
- ✓ Image placeholders with descriptions
- ✓ Business value callouts during Show
- ✓ Target audience appropriate language
- ✓ Red Hat style compliance

## Common Demo Patterns

**Executive Audience**:
- More Know, less Show
- Focus on business outcomes
- High-level demonstrations
- Emphasize strategic value

**Technical Audience**:
- Balanced Know/Show
- Show depth and capabilities
- Include architecture discussions
- Technical credibility focus

**Sales Engineers**:
- Detailed Show sections
- Competitive differentiators
- Objection handling
- ROI calculations

## Integration Notes

**Templates used**:
- `content/modules/ROOT/pages/demo/03-module-01.adoc`
- `content/modules/ROOT/pages/demo/01-overview.adoc`

**Agents invoked**:
- `workshop-reviewer` - Validates structure
- `style-enforcer` - Applies Red Hat style

**Files created**:
- Demo module: `content/modules/ROOT/pages/<module-file>.adoc`
- Assets: `content/modules/ROOT/assets/images/`

**Files modified** (with permission):
- `content/modules/ROOT/nav.adoc` - Adds navigation entry
