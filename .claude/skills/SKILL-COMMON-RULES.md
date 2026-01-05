# Skill Common Rules

**Version**: 1.0
**Last Updated**: 2026-01-03

## Purpose

This document defines shared contracts and rules used by all Showroom authoring skills (`/lab-module`, `/demo-module`, `/blog-generate`). These rules prevent drift and ensure consistency across skills.

## Shared Contracts

### 1. Version Pinning or Attribute Placeholders (REQUIRED)

**Rule**: Every module must handle versions explicitly.

**For first module of a lab/demo**:
- Ask: OpenShift version, product versions, cluster type, access level
- If provided: Use in content with attributes (e.g., `{ocp_version}`, `{pipelines_version}`)
- If NOT provided: Use attribute placeholders and avoid version-specific CLI/UI steps

**For subsequent modules**:
- Auto-detect from previous module
- Inherit version scope

**Example**:
```asciidoc
// Good - uses attribute
This lab is tested on OpenShift {ocp_version} with Pipelines {pipelines_version}.

// Bad - hardcoded version (unless explicitly provided by user)
This lab requires OpenShift 4.16.2 with Pipelines 1.14.
```

**Why**: Prevents "works on my cluster" modules that break in other environments.

---

### 2. Reference Enforcement (REQUIRED)

**Rule**: Every non-trivial claim must be backed by provided references or marked for follow-up.

**Pattern**:
- When making technical claim: Check if reference supports it
- If yes: Continue
- If no: Mark clearly: `**Reference needed**: <claim>`

**Mandatory References Section**:
Every lab/demo module must end with:
```asciidoc
== References

* link:https://docs.openshift.com/...[OpenShift Pipelines documentation] - Pipeline syntax and examples
* link:https://tekton.dev/...[Tekton documentation] - Task definitions
```

**Conflicting References**:
- If references conflict, call out the conflict
- Choose based on version relevance
- Note the decision in module comments

**Why**: Technical accuracy and traceability.

---

### 3. Attribute File Location (REQUIRED)

**Rule**: All reusable variables go in a shared attributes file.

**Location**: `content/modules/ROOT/partials/_attributes.adoc`

**Standard Attributes**:
```asciidoc
:console_url: {openshift_console_url}
:api_url: {openshift_api_url}
:user: {user_name}
:password: {user_password}
:namespace: {project_namespace}
:admin_user: {cluster_admin_user}
:bastion_host: {bastion_public_hostname}
:git_repo: {git_repository_url}
:registry_url: {container_registry_url}
:ocp_version: {openshift_version}
```

**If value unknown**:
- Keep as `{attribute}` placeholder
- List in "Attributes Needed" section at end of module

**Include in every module**:
```asciidoc
include::partial$_attributes.adoc[]
```

**Why**: Makes labs reusable across environments.

---

### 4. Image Path Conventions (REQUIRED)

**Rule**: Strict path conventions for all images.

**Path**: `content/modules/ROOT/images/<module-slug>/`

**Example**:
- Module: `module-01-pipelines-intro.adoc`
- Images: `content/modules/ROOT/images/pipelines-intro/`

**NOT**: `assets/images/` or `images/` at root

**AsciiDoc Syntax** (REQUIRED):
```asciidoc
image::pipelines-intro/pipeline-execution-1.png[Tekton pipeline showing three tasks executing in sequence,width=700,title="Pipeline Execution in Progress"]
```

**Required for every image**:
1. **Meaningful alt text** (accessibility)
2. **Width guidance** (500-800px typical)
3. **Descriptive filename** (no `image1.png`)

**Placeholders**:
If image doesn't exist yet:
```asciidoc
// TODO: Add screenshot
image::pipelines-intro/create-task-screenshot.png[OpenShift console showing task creation form,width=600,title="Creating a Tekton Task"]
```

**Assets Needed List**:
```asciidoc
== Assets Needed

. `pipeline-execution-1.png` - Screenshot of pipeline running in OpenShift console
. `task-definition.png` - YAML editor showing task definition
```

**Why**: Accessibility, organization, maintainability.

---

### 5. Navigation Update Expectations (REQUIRED for /lab-module and /demo-module)

**Rule**: nav.adoc update is REQUIRED. Modules won't appear in Showroom without it.

**What to do**:
1. Read existing `content/modules/ROOT/nav.adoc`
2. Maintain sequential ordering of modules
3. Keep `index.adoc` at top if exists
4. Add new module in correct position based on module number

**Pattern**:
```asciidoc
* xref:index.adoc[Home]

* xref:module-01-intro.adoc[Module 1: Introduction]
** xref:module-01-intro.adoc#exercise-1[Exercise 1: Setup]
** xref:module-01-intro.adoc#exercise-2[Exercise 2: First Pipeline]

* xref:module-02-advanced.adoc[Module 2: Advanced Topics]  ← NEW MODULE
** xref:module-02-advanced.adoc#exercise-1[Exercise 1: Git Integration]
```

**Conflict Handling**:
- If module number conflicts with existing file, warn user
- Suggest next available number
- Do NOT overwrite without confirmation

**Why**: Without nav entry, module is invisible in Showroom.

---

## Failure-Mode Behavior

**Rule**: When skill cannot safely proceed, STOP and list blocking issues instead of producing partial content.

### Blocking Conditions

**Missing References**:
- User didn't provide any reference materials
- All provided URLs are inaccessible
- **Action**: Stop and ask for valid references

**Conflicting Versions**:
- References mention different incompatible versions (e.g., OpenShift 4.12 vs 4.16 with breaking changes)
- **Action**: Stop, call out conflict, ask user which version to target

**Incomplete Story for Continuation**:
- User says "continuing existing lab" but:
  - Cannot provide previous module path
  - Cannot paste previous module content
  - Won't answer story recap questions
- **Action**: Stop and explain: "I need previous module context to continue the story"

**Invalid File Paths**:
- User provides non-existent AgnosticV catalog path
- **Action**: Stop, list what was searched, ask for correction

**Navigation Conflicts**:
- Module number already exists in nav.adoc
- User doesn't confirm overwrite or renumber
- **Action**: Stop and list available module numbers

### Failure Response Pattern

```markdown
❌ **Cannot proceed safely**

**Blocking issue**: [specific problem]

**What I need**:
1. [specific fix 1]
2. [specific fix 2]

**Or**: Would you like to proceed with [fallback option]?
```

**Why**: Preserves trust. Partial/guessed content is worse than no content.

---

## Explicit Non-Goals

### What Skills Are NOT Responsible For

**All skills** (`/lab-module`, `/demo-module`, `/blog-generate`):
- ❌ **Provisioning automation**: Skills generate content, not infrastructure
- ❌ **Exact UI pixel accuracy**: Screenshots are placeholders with descriptions
- ❌ **Real-time version checking**: Use provided references, not live docs
- ❌ **Multi-language translation**: English only
- ❌ **Video script generation**: Text-based content only

**`/lab-module` and `/demo-module` specifically**:
- ❌ **Roadmap positioning**: Don't make claims about future product direction
- ❌ **Competitive analysis**: Don't compare to other vendors unless in references
- ❌ **Performance benchmarking**: Don't invent metrics
- ❌ **SLA guarantees**: Don't promise uptime or support levels

**`/blog-generate` specifically**:
- ❌ **SEO keyword stuffing**: Natural language only
- ❌ **Social media posts**: Blog content only, not tweets/LinkedIn
- ❌ **Press release format**: Marketing blog ≠ official PR
- ❌ **Lead generation forms**: Content only, not CTA implementation

**Why**: Prevents scope creep and sets clear expectations.

---

## AgnosticV Configuration Assistance (Shared Contract)

**Applies to**: `/lab-module` and `/demo-module` skills

Both lab and demo skills provide intelligent AgnosticV (AgV) configuration assistance to help users find existing catalogs or create new ones following agd_v2 best practices.

### Workflow Timing

**When**: Step 2.5 - After overall story planning (Step 2), before module-specific details (Step 3)

**Conditional**: Only triggered if:
1. User needs a deployed environment (not documentation-only)
2. User doesn't already have an AgV catalog configured

### Access Check Protocol

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

Your workshop/demo can still be deployed via RHDP, but AgV catalog creation requires access.

**Recommendation:**

Contact RHDP developers to help create your AgV catalog.

**What I can suggest for reuse:**

Based on your workshop/demo "{{ workshop_demo_name }}" with technologies {{ tech_keywords }},
I recommend these existing catalogs as a good base:

1. **{{ suggested_catalog_1 }}** (Best match)
   - Display name: "{{ catalog_1_name }}"
   - Technologies: {{ catalog_1_tech }}
   - Category: {{ catalog_1_category }}

2. **{{ suggested_catalog_2 }}** (Alternative)
   - Display name: "{{ catalog_2_name }}"
   - Technologies: {{ catalog_2_tech }}

**Share this with RHDP developers** when requesting AgV catalog creation.

For now, I'll continue with placeholder attributes in your workshop/demo content:
- {openshift_console_url}
- {user}, {password}
- {openshift_api_url}

→ Proceeding to Step 3: Module-Specific Details
```

**If ACCESS confirmed (default or provided path):**
- Continue to catalog search workflow ↓

### User-Suggested Catalog Search (Q3)

**Before automatic keyword search**, ask user:

**Q3**: "Do you think there's an existing catalog that could be a good base for this workshop/demo?"

**Options:**
- "Yes, I know of one" → Continue to Q3a
- "No" or "Not sure" → Skip to keyword recommendations

**If user answers "Yes":**

**Q3a**: "What's the catalog display name or slug?"

**Examples:**
- Display name: "Agentic AI on OpenShift", "OpenShift Pipelines Workshop"
- Catalog slug: "agentic-ai-openshift", "ocp-pipelines-workshop"

### Display Name Search Specification

**Search algorithm** when user provides catalog suggestion:

1. **Search locations:**
   - `__meta__.catalog.display_name` field in `common.yaml` (partial match, case-insensitive)
   - Catalog directory slug in `agd_v2/` (partial match)
   - `__meta__.catalog.keywords` array (exact keyword match)
   - `__meta__.catalog.category` field (partial match)

2. **Scoring system:**
   - Display name match: **50 points**
   - Catalog slug match: **40 points**
   - Keyword match: **10 points each**
   - Category match: **5 points**

3. **Return top 5 results** sorted by score descending

4. **Show for each result:**
   - Display name and score
   - Catalog slug
   - Category (Workshops, Demos, etc.)
   - Multi-user: Yes/No (and user range if applicable)
   - Infrastructure type (CNV, SNO, AWS)
   - Key workloads (first 5)
   - OpenShift version requirement
   - Path (e.g., agd_v2/catalog-slug)

5. **User options:**
   - Use catalog #X as-is → Extract UserInfo, go to Step 3
   - Create new catalog based on #X → Copy structure, continue to creation workflow
   - See details for catalog #Y → Show full workload list
   - Go back to keyword search → Fallback to keyword recommendations

**If no results found:**
```
No catalogs found matching "{{ user_input }}".

Try:
- Different spelling or keywords
- Catalog slug instead of display name
- Let me search by technology keywords from your workshop/demo plan

Search again or proceed to keyword recommendations? [Search again/Keywords]
```

### Keyword-Based Catalog Recommendations (Fallback)

**When triggered:**
- User answered "No/Not sure" to Q3
- User-suggested search found no results
- User chose "Go back to keyword search"

**Algorithm:**
1. Extract technology keywords from Step 2 (overall story planning)
   - Examples: AI, pipelines, GitOps, platform value, automation
2. Search catalog display names and slugs in `agd_v2/`
3. Analyze workload lists in `common.yaml`
4. Score by relevance to workshop/demo tech stack
5. Show top 3-5 matches

**Show for each:**
- Display name and match score (with star rating)
- Multi-user support
- Category
- Key workloads
- Infrastructure type
- Best use case description

**Options:**
- Use one of these catalogs: [Enter 1, 2, or 3]
- View workloads in detail: [Enter catalog name]
- Create new catalog instead: [Enter 'new']
- Skip AgV for now: [Enter 'skip']

### Multi-user vs Dedicated Rules

**Default recommendations:**

**Labs** (`/lab-module`):
- **Recommend: Multi-user**
- Rationale: Hands-on workshops with 5-50 attendees, cost-effective, one cluster with multiple user accounts (user1...userN)
- Infrastructure: CNV with autoscaling
- Authentication: htpasswd for multi-user

**Demos** (`/demo-module`):
- **Recommend: Dedicated**
- Rationale: Presenter-led demonstrations, executive/sales demos, consistent experience, single presenter control
- Infrastructure: CNV or AWS (if GPU)
- Authentication: Keycloak for demos

**Special Cases (Always Dedicated):**
- Non-OpenShift workloads (VMs, edge, Windows)
- GPU-accelerated workloads
- Executive demos (C-level, pre-sales briefings)
- Single deep-dive scenarios

### Infrastructure Selection Rules

**CNV (Container-Native Virtualization)** - DEFAULT for most labs/demos:
- ✓ Fast provisioning (10-15 mins)
- ✓ Cost-effective
- ✓ Supports multi-user (up to 64Gi/32 cores per worker)
- ✓ Best for: Standard OpenShift workloads
- ✓ Autoscaling support
- **When to use:** Default choice for OpenShift-based labs and demos

**SNO (Single Node OpenShift)**:
- ✓ Faster provisioning (5-10 mins)
- ✓ Lightweight workloads
- ✓ Single-user scenarios
- ✓ Edge computing demos
- **When to use:** Quick platform overviews, edge scenarios, lightweight demos

**AWS (Cloud-Specific)**:
- ✓ GPU acceleration (NVIDIA, g6.4xlarge instances)
- ✓ Large memory requirements (>128Gi)
- ✓ Cloud-native service integration (S3, ELB, etc.)
- ⚠️ Slower provisioning (30-45 mins)
- ⚠️ Higher cost - reserve for GPU needs
- **When to use:** AI/ML workloads requiring GPU, large memory footprint, cloud services

### Collection Recommendation Mappings

**Always include:**
- `agnosticd.core_workloads` - Authentication (htpasswd for multi-user, Keycloak for demos), base OpenShift capabilities

**AI/ML keywords** (ai, ml, openshift-ai, models, llm, rag):
- `agnosticd.ai_workloads` - OpenShift AI operator, GPU operator, OLS (OpenShift Lightspeed)
- `rhpds.litellm_virtual_keys` (optional) - LiteLLM proxy for model access, virtual API key management

**DevOps/GitOps keywords** (pipeline, gitops, tekton, argo):
- Core workloads already include:
  - `ocp4_workload_pipelines` (OpenShift Pipelines / Tekton)
  - `ocp4_workload_openshift_gitops` (Argo CD)
  - `ocp4_workload_gitea_operator` (Git server for labs)

**Workshop/Demo Content Delivery:**
- `agnosticd.showroom` - Workshop content platform, terminal integration, Know/Show structure support (for demos), multi-user UI

### Git Workflow Requirements (CRITICAL)

**Pre-creation steps** (REQUIRED before creating catalog files):

1. **Navigate to AgnosticV repo:**
   ```bash
   cd ~/work/code/agnosticv
   ```

2. **Switch to main branch:**
   ```bash
   git checkout main
   ```

3. **Pull latest changes:**
   ```bash
   git pull origin main
   ```

4. **Create new branch:**
   ```bash
   git checkout -b {{ catalog_slug }}
   ```

**Branch Naming Convention** (CRITICAL):

**Pattern:** `<catalog-slug>` or `<catalog-slug>-<variant>`

**IMPORTANT:** NO "feature/" prefix per AgV convention

**Examples:**
- ✓ `ocp-pipelines-workshop`
- ✓ `agentic-ai-summit-2025`
- ✓ `openshift-ai-gpu-aws`
- ✗ `feature/ocp-pipelines-workshop` (DON'T USE)
- ✗ `feature/ai-demo` (DON'T USE)

**Validation:**
- Lowercase only
- Hyphens for word separation
- No underscores, no slashes (except directory separator)
- Descriptive and matches catalog slug

**Post-creation steps:**

1. **Review changes:**
   ```bash
   git status
   git diff
   ```

2. **Add catalog files:**
   ```bash
   git add agd_v2/{{ catalog_slug }}/
   ```

3. **Commit with descriptive message:**
   ```bash
   git commit -m "Add {{ catalog_display_name }} catalog

   - Multi-user: {{ multiuser }}
   - Infrastructure: {{ infra_type }}
   - Collections: {{ collections_list }}
   - Target: {{ workshop_type }}"
   ```

4. **Push branch:**
   ```bash
   git push -u origin {{ catalog_slug }}
   ```

5. **Next steps guidance:**
   - Test locally: `agnosticv_cli --config agd_v2/{{ catalog_slug }}/dev.yaml`
   - Open PR when ready for production deployment
   - Tag RHDP developers for review: @psrivast @tyrell @juliano

### AgV Directory Selection

**Recommended directories:**

1. **agd_v2/** - DEFAULT, most workshops/demos
2. **enterprise/** - Red Hat internal only
3. **summit-2025/** - Event-specific, time-bound
4. **ansiblebu/** - Ansible Automation Platform focus

**Ask user:** "Which directory? [1-4 or custom path]"

**Suggested path:** `agd_v2/{{ suggested_slug }}`

### AgnosticD v2 Pattern Enforcement

**Rule:** Creation workflow generates **agd_v2 patterns ONLY**

**What this means:**
- Use modern AgV includes (#include statements)
- Use component-based structure (cluster, workloads, metadata)
- Use `__meta__.catalog` section for display name, keywords, category
- Use `requirements.collections` for explicit collection dependencies
- Generate `common.yaml`, `description.adoc`, `dev.yaml` only

**Can still READ AgDv1 catalogs:**
- For UserInfo variable extraction
- For reference when user suggests existing catalog
- But **never generate AgDv1 patterns** for new configs

### Config File Generation

**Files to create** in `agd_v2/{{ catalog_slug }}/`:

1. **common.yaml** - Main configuration
   - AgnosticV includes (#include statements)
   - Cluster configuration (CNV pools, SNO, or AWS)
   - Requirements (collections list)
   - Workload list with variables
   - Authentication setup (htpasswd multi-user or Keycloak)
   - Showroom integration (if selected)
   - Metadata (`__meta__.catalog` section with display_name, keywords, category)

2. **description.adoc** - Catalog description
   - Workshop/demo title
   - Brief description
   - Multi-user information (if applicable)
   - Showroom link (if applicable)

3. **dev.yaml** - Development overrides
   - Purpose: development
   - SCM ref override for testing

### UserInfo Variable Extraction

**When user selects existing catalog:**

1. **Read catalog configuration:**
   - Location: `~/work/code/agnosticv/agd_v2/{{ catalog_slug }}/common.yaml`
   - Parse workload list

2. **Identify workload roles:**
   - AgnosticD v2: `~/work/code/agnosticd-v2/`
   - AgnosticD v1: `~/work/code/agnosticd/` (legacy)
   - Read workload roles referenced in common.yaml

3. **Extract `agnosticd_user_info` variables:**
   - Search for `agnosticd_user_info` tasks in workload roles
   - Extract variables from `data:` sections
   - Map to Showroom attributes

**Common variables:**
- `openshift_console_url` → `{openshift_console_url}`
- `openshift_api_url` → `{openshift_api_url}`
- `user_name` → `{user}`
- `user_password` → `{password}`
- `bastion_public_hostname` → `{bastion_public_hostname}`
- Custom workload-specific variables

**Result:** Use these as Showroom attributes in generated lab/demo content

### Summary and Transition

**After AgV assistance completes:**

```
✓ AgV Configuration Complete

**Selected catalog:** {{ catalog_name }}

**Next:**
- I'll extract UserInfo variables from this catalog's workloads
- Use these variables as Showroom attributes in your workshop/demo modules
- Example variables available:
  - {openshift_console_url}
  - {user}, {password}
  - {openshift_api_url}
  - [workload-specific variables]

→ Proceeding to Step 3: Module-Specific Details
```

---

## Skill-Specific Rules

### `/lab-module` - Workshop Module Generator

**Learning Outcomes Checkpoint** (REQUIRED):

Every module must include a "Learning Outcomes" section that confirms pedagogical understanding, not just technical validation.

**Pattern**:
```asciidoc
== Learning Outcomes

By completing this module, you should now understand:

* ✓ How Tekton tasks encapsulate reusable CI/CD steps
* ✓ The relationship between tasks, pipelines, and pipeline runs
* ✓ How to troubleshoot failed pipeline executions using logs and status
* ✓ When to use sequential vs parallel task execution patterns
```

**Guidelines**:
- 3-5 bullet outcomes
- Tied back to original learning objective
- Focus on understanding ("understand how X works") not just doing ("created X")
- Use outcomes later for blog transformation

**Why**: Helps reviewers, instructors, and makes blog generation cleaner.

---

### `/demo-module` - Demo Content Generator

**Slide or Diagram Cue** (OPTIONAL but RECOMMENDED):

Add lightweight visual cues without forcing asset creation.

**Pattern**:
```asciidoc
=== Show

**Optional visual**: Before/after pipeline deployment diagram

* Log into OpenShift Console at {console_url}
* Navigate to Developer perspective
...
```

**Cue Examples**:
- "Optional visual: Architecture diagram showing component relationships"
- "Optional slide: Customer pain points - 6-8 week deployment cycles"
- "Optional visual: Before/after comparison of manual vs automated workflow"

**Guidelines**:
- Always mark as "Optional visual:" or "Optional slide:"
- Don't make demo depend on it
- Helps presenters prepare assets if they want

**Why**: Keeps demos tight without forcing assets. Helps presentation preparation.

---

### `/blog-generate` - Content Transformation

**Source Traceability** (REQUIRED):

Every generated blog must include attribution to prevent over-claiming and confusion.

**Pattern for Red Hat Developer Blog**:
```markdown
---

**About this tutorial**: This post is based on a hands-on workshop created for Red Hat field demonstrations. [Try the full lab on Red Hat Showroom](https://showroom.example.com/...).
```

**Pattern for Internal Blogs**:
```markdown
---

**Source**: Adapted from the "OpenShift Pipelines" demo used in customer technical briefings.
```

**Pattern for Marketing Blogs**:
```markdown
---

**About**: This article is based on technical demonstrations shown at Red Hat Summit and customer events.
```

**Rules**:
- Always include a short "Based on" or "Derived from" note
- Link to full lab if publishing externally
- Use "adapted from" or "based on" language, not "official documentation"
- Place at end of blog post, before tags/metadata

**Why**: Avoids accidental over-claiming, clarifies authoritative docs vs narrative content.

---

## Quality Gate Integration

All skills must pass these gates before delivering content:

**1. AsciiDoc Sanity Checks**:
- ✓ All code blocks have proper syntax: `[source,bash]`
- ✓ No broken includes
- ✓ All attributes defined or listed in "Attributes Needed"
- ✓ Image paths follow convention
- ✓ No unclosed blocks

**2. Navigation Check** (lab/demo only):
- ✓ nav.adoc contains the new module
- ✓ Module numbering is sequential
- ✓ All xrefs are valid

**3. Instruction Clarity Checks**:
- ✓ Each step has a clear reason ("why this matters")
- ✓ Commands are copy/pasteable (no unexplained placeholders)
- ✓ Expected output shown for verification steps
- ✓ Learning outcomes present (lab/demo)
- ✓ Source traceability present (blog)

**4. Module Sizing Check** (lab/demo only):
- ✓ Module targets 20-40 minutes
- ✓ Module has 1-2 major outcomes, not 5
- ✓ If module >50 min estimated, flag for split

**If gates fail**: List specific issues, suggest fixes, allow user to proceed anyway or regenerate.

---

## Shared Templates and Resources

All skills reference these files:

**Templates**:
- `content/modules/ROOT/pages/workshop/templates/03-module-01.adoc`
- `content/modules/ROOT/pages/demo/03-module-01.adoc`
- `content/modules/ROOT/pages/workshop/templates/README-TEMPLATE-GUIDE.adoc`

**Style Guides**:
- `.claude/prompts/redhat_style_guide_validation.txt`
- `.claude/prompts/enhanced_verification_workshop.txt`

**Agents**:
- `workshop-reviewer` - Validates structure and pedagogy
- `style-enforcer` - Applies Red Hat style standards
- `researcher` - Validates reference URLs
- `content-converter` - Converts formats
- `technical-editor` - Refines blog tone

---

## Update Protocol

When updating these rules:

1. Update this file first
2. Update all 3 skill files to reference changes
3. Update `.claude/skills/README.md` to document changes
4. Commit with message: "Update shared skill rules: [what changed]"

---

**Last Updated**: 2026-01-03
**Maintained By**: Red Hat Technical Marketing
