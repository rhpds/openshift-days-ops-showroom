---
name: create-lab
description: Guide you through creating a single Red Hat Showroom workshop module from reference materials (URLs, files, docs, or text) with business storytelling and proper AsciiDoc formatting.
---

---
context: main
model: sonnet
hooks:
  PreToolUse:
    - .claude/hooks/validate-paths.sh
---

# Lab Module Generator

Guide you through creating a single Red Hat Showroom workshop module from reference materials (URLs, files, docs, or text) with business storytelling and proper AsciiDoc formatting.

## When to Use

**Use this skill when you want to**:
- Create a new workshop module from scratch
- Convert documentation into hands-on lab format
- Add a module to an existing workshop
- Transform technical content into engaging learning experience

**Don't use this for**:
- Creating demo content → use `/create-demo`
- Converting to blog posts → use `/blog-generate`
- Reviewing existing content → use `/verify-content`

## Shared Rules

**IMPORTANT**: This skill follows shared contracts defined in `.claude/docs/SKILL-COMMON-RULES.md`:
- Version pinning or attribute placeholders (REQUIRED)
- Reference enforcement (REQUIRED)
- Attribute file location (REQUIRED)
- Image path conventions (REQUIRED)
- Navigation update expectations (REQUIRED)
- Failure-mode behavior (stop if cannot proceed safely)

See SKILL-COMMON-RULES.md for complete details.

## Arguments (Optional)

This skill supports optional command-line arguments for faster workflows.

**Usage Examples**:
```bash
/create-lab                                    # Interactive mode (asks all questions)
/create-lab <directory>                        # Specify target directory
/create-lab <directory> --new                  # Create new lab in directory
/create-lab <directory> --continue <module>    # Continue from specific module
```

**Parameters**:
- `<directory>` - Target directory for module files
  - Example: `/create-lab content/modules/ROOT/pages/`
  - If not provided, defaults to `content/modules/ROOT/pages/`
- `--new` - Flag to create new lab (generates index + overview + details + module-01)
- `--continue <module-path>` - Continue from specified previous module
  - Example: `/create-lab content/modules/ROOT/pages/ --continue content/modules/ROOT/pages/03-module-01-intro.adoc`
  - Reads previous module to detect story continuity

**How Arguments Work**:
- Arguments skip certain questions (faster workflow)
- You can still use interactive mode by calling `/create-lab` with no arguments
- Arguments are validated before use

## Workflow

**CRITICAL RULES**

### 1. Ask Questions SEQUENTIALLY

- Ask ONE question or ONE group of related questions at a time
- WAIT for user's answer before proceeding
- If user chooses "Yes, help me create new catalog" in Step 2.5, you MUST complete the ENTIRE AgV workflow before proceeding to Step 3
- Do NOT ask questions from multiple steps together
- Do NOT skip workflows based on incomplete answers

### 2. File Generation Order (First Module ONLY)

**If this is the FIRST module of a NEW lab, you MUST generate files in this EXACT order:**

1. **index.adoc** - Learner landing page (NOT facilitator guide)
2. **01-overview.adoc** - Business scenario and learning objectives
3. **02-details.adoc** - Technical requirements and setup
4. **03-module-01-*.adoc** - First hands-on module

**NEVER skip index/overview/details for first module!**

**File naming convention**:
- index.adoc (no number prefix)
- 01-overview.adoc
- 02-details.adoc
- 03-module-01-*.adoc
- 04-module-02-*.adoc
- 05-module-03-*.adoc
- etc.

**If continuing existing lab**:
- Detect next file number from existing modules
- Generate: 0X-module-YY-*.adoc (where X = next sequential file number)
- Example: If existing has 03-module-01, 04-module-02, next is 05-module-03
- Skip index/overview/details (already exist)

### 3. Manage Output Tokens

- **NEVER output full module content** - Use Write tool to create files
- **Show brief confirmations only** - "✅ Created: filename (X lines)"
- **Keep total output under 5000 tokens** - Summaries, not content
- **Files are written, not displayed** - User reviews with their editor
- **Token limit**: Claude Code has 32000 token output limit - stay well below it

**Example of WRONG approach**:
```
❌ Asking all at once:
1. Module file name?
2. Do you need AgV help? [1/2/3/4]
3. UserInfo variables?
4. Learning objective?
5. Number of exercises?
```

**Example of CORRECT approach**:
```
✅ Ask sequentially:
Step 2.5: Do you need AgV help? [1/2/3/4]
[WAIT for answer]
[If answer is 3, complete ENTIRE AgV workflow]
[If answer is 1 or 2, proceed to Step 3]

Step 3.1: Module file name?
[WAIT for answer]

Step 3.2: Reference materials?
[WAIT for answer]

etc.
```

---

### Step 0: Parse Arguments (If Provided)

**Check if user invoked skill with arguments**.

**Pattern 1: `/create-lab <directory> --new`**
```
Parsing arguments: "<directory> --new"

✓ Target directory: <directory>
✓ Mode: Create new lab
✓ Will generate: index.adoc → 01-overview → 02-details → 03-module-01

Validating directory...
[Check if directory exists, create if needed]

Skipping: Step 1 (mode already known: NEW lab)
Proceeding to: Step 2 (Plan Overall Lab Story)
```

**Pattern 2: `/create-lab <directory> --continue <module-path>`**
```
Parsing arguments: "<directory> --continue <module-path>"

✓ Target directory: <directory>
✓ Mode: Continue existing lab
✓ Previous module: <module-path>

Validating directory...
[Check if directory exists]

Reading previous module: <module-path>
[Extract story, company, progression]

Skipping: Step 1 (mode already known: CONTINUE)
Skipping: Step 2 (story detected from previous module)
Proceeding to: Step 3 (Module-Specific Details)
```

**Pattern 3: `/create-lab <directory>`**
```
Parsing arguments: "<directory>"

✓ Target directory: <directory>

Validating directory...
[Check if directory exists]

Skipping: Target directory question
Proceeding to: Step 1 (still need to ask: new vs continue)
```

**Pattern 4: `/create-lab` (no arguments)**
```
No arguments provided.

Using interactive mode.
Target directory: Will use default (content/modules/ROOT/pages/)

Proceeding to: Step 1 (Determine Context)
```

**Argument Validation**:
- If directory doesn't exist, ask user: "Directory not found. Create it? [Yes/No]"
- If `--continue` but module path invalid, fall back to asking for story recap
- All arguments are optional - skill always works in interactive mode

---

### Step 1: Determine Context (New Lab vs Existing Lab)

**SKIP THIS STEP IF**:
- User provided `--new` flag in arguments (already know: NEW lab)
- User provided `--continue <module>` in arguments (already know: EXISTING lab)

**CRITICAL: DO NOT read any files or make assumptions before asking this question!**

**First, ask the user**:

```
Q: Are you creating a new lab or adding to an existing lab?

Options:
1. Creating a NEW lab (I'll generate: index.adoc → 01-overview → 02-details → 03-module-01)
2. Adding to an EXISTING lab (I'll detect next number and generate: 0X-module-YY only)
3. Something else (please describe)

Your choice? [1/2/3]
```

**ONLY AFTER user answers, proceed based on their response.**

**If option 1 (NEW lab)**:
- Generate ALL workshop files: index.adoc, 01-overview.adoc, 02-details.adoc, 03-module-01-*.adoc
- Proceed to Step 2 (Plan Overall Lab Story)

**If option 2 (EXISTING lab)**:
- Detect next file number from existing modules
- Generate ONLY next module: 0X-module-YY-*.adoc
- Skip Step 2 (already have overall story)
- Ask for previous module path or story recap

**If continuing existing lab**:
- Option 1: Provide path to previous module (I'll read and auto-detect story)
- Option 2: If previous module not available, I'll ask for story recap:
  - Company name and scenario
  - What was completed in previous modules
  - Current learning state
  - What comes next in progression

**Fallback behavior**:
- If user says "continuing" but cannot provide previous module content or workspace access:
  - Ask user to paste content of last module (or key sections)
  - OR ask short "Story Recap" questions:
    1. Company/scenario name?
    2. What topics were covered in previous modules?
    3. What skills have learners gained so far?
    4. What's the current state in the story?
  - This prevents broken continuity

### Step 2: Plan Overall Lab Story (if first module)

If this is the first module, I'll gather the big picture:

**IMPORTANT**: Ask these as **open-ended questions** where users type their answers. Do NOT provide multiple choice options.

1. **Lab overview**:
   - What's the overall goal of this lab?
   - Example: "Learn to build and deploy AI/ML workloads on OpenShift AI"

2. **Target audience**:
   - Who is this lab for?
   - Example: "Developers, Architects, SREs, Data Scientists"
   - What's their experience level?
   - Example: "Beginner, Intermediate, Advanced"

3. **Learning journey**:
   - What should learners know by the end?
   - What skills will they gain?

4. **Story/scenario**:
   - What company/business scenario should we use?
   - Example: "ACME Corp" or custom company
   - What's the business challenge driving this?

5. **Estimated duration**:
   - How long should the complete lab take?
   - Example: "30min, 1hr, 2hr"

6. **Version and environment scope** (REQUIRED):
   - OpenShift version?
   - Example: "4.18, 4.20" or use placeholder `{ocp_version}`
   - Product versions?
   - Example: "OpenShift Pipelines 1.12, OpenShift AI 2.8" or use placeholders
   - Cluster type?
   - Example: "SNO or multinode"
   - Access level?
   - Example: "admin only, or multi-user with keycloak/htpasswd"
   - If not provided:
     - Use attribute placeholders: `{ocp_version}`, `{pipelines_version}`
     - Avoid version-specific CLI/UI steps
     - Note in module: "Tested on OpenShift {ocp_version}"

**Then I'll recommend**:
- Suggested module breakdown (how many modules, what each covers)
- Progressive learning flow (foundational → intermediate → advanced)
- Story arc across modules
- Key milestones and checkpoints

**You can**:
- Accept the recommended flow
- Adjust module count and topics
- Change the progression

### Step 2.5: AgnosticV Configuration Assistance (OPTIONAL)

**IMPORTANT**: This is **optional** assistance. First ask if user needs help.

**⚠️ ADVANCED USERS / RHDP DEVELOPERS ONLY**

AgnosticV catalog configuration is for:
- Red Hat Demo Platform (RHDP) developers
- Advanced users who need to provision RHDP environments
- Teams deploying to demo.redhat.com or integration.demo.redhat.com

**Most content creators can skip this** - AgV is only needed if you're provisioning infrastructure for your workshop/demo.

**Initial question:**
```
Q: Do you need help with AgnosticV catalog configuration?

⚠️  Note: This is for RHDP developers/advanced users only.
    Most content creators can skip this (choose option 1 or 2).

Options:
1. No, already set up → Skip to Step 3
2. No, I'll handle it myself → Skip to Step 3
3. Yes, help me create new catalog → Continue ↓
4. What's AgnosticV? → Explain

Your choice? [1/2/3/4]
```

**If user chooses option 3 (YES to AgV help):**

**Step A: Get AgV Directory Path (REQUIRED)**

```
Q: What is your AgnosticV repository directory path? (REQUIRED)

This directory is my reference library for:
- Searching existing catalogs by name or keywords
- Learning catalog patterns and structures
- Copying/basing new catalogs on existing ones
- Understanding workload configurations

Example: /Users/username/work/code/agnosticv/

Your AgV path: [Enter full path]
```

**Why REQUIRED**: The AgV directory IS the reference material for all catalog work.

**Step B: Ask if User Knows Similar Catalog (Recommended)**

```
Q: Do you know of an existing catalog that could be a good base for your workshop?

Providing a catalog name helps me:
- Find the closest match faster
- Show you exactly what's available
- Use it as a template if creating new

Options:
- Yes, I know one → Enter display name or slug
- No / Not sure → I'll search by keywords
```

**If YES (user knows catalog name)**:
- Ask: "What's the catalog display name or slug?"
- Examples: "Agentic AI on OpenShift" or "agentic-ai-openshift"
- Search AgV directory by display name and slug
- Show top matches with full details
- Options: Use as-is / Create new based on this / See similar

**If NO/Not sure**:
- Extract keywords from Step 2 (workshop abstract, technology)
- Search AgV directory by keywords
- Show top 3-5 recommendations

**Step C: Complete AgV Workflow**

See `.claude/docs/SKILL-COMMON-RULES.md` section "AgnosticV Configuration Assistance" for complete details.

**If creating new catalog, I'll ask:**

1. **Git workflow** - Pull main, create branch (BEFORE generating files):
   ```
   Q: Preparing git workflow...

   Running in AgV directory:
   1. git checkout main
   2. git pull origin main
   3. git checkout -b {{ catalog_slug }}
   ```

2. **UUID Generation** (REQUIRED BEFORE file creation):
   ```
   Q: Please generate a unique UUID for this catalog.

   Run one of these commands:

   macOS/Linux:
     uuidgen

   OR

   Python (any platform):
     python3 -c 'import uuid; print(uuid.uuid4())'

   Paste the generated UUID here: [paste UUID]
   ```

   **Validation**: Must be standard UUID format (XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX)
   **Example**: `5ac92190-6f0d-4c0e-a9bd-3b20dd3c816f`
   **NOT valid**: `gitops-openshift-2026-01` (this is not a UUID!)

3. **Showroom Repository Detection** (REQUIRED for showroom content):
   ```
   Q: Detecting showroom repository from current directory...

   Running: git -C $(pwd) remote get-url origin

   Found: {{ git_remote_url }}

   {% if SSH format %}
   Converting SSH to HTTPS:
     SSH:   git@github.com:rhpds/showroom-name.git
     HTTPS: https://github.com/rhpds/showroom-name.git
   {% endif %}

   Using showroom repo: {{ https_url }}
   Confirm this is correct? [Yes/No/Enter different URL]
   ```

   **If no git remote found**:
   ```
   ⚠️ No git remote found in current directory.

   Please provide your showroom repository URL (HTTPS format):
   Example: https://github.com/rhpds/showroom-agentic-ai-llamastack.git

   Your showroom repo URL: [Enter URL]
   ```

4. **AgV Directory Selection**:
   ```
   Q: Which directory should I create the catalog in?

   Options:
   1. agd_v2/ (Recommended - most workshops/demos)
   2. openshift_cnv/ (For CNV-based infrastructure)

   Your choice? [1/2]
   ```

5. **Lab-specific defaults**:
   - Multi-user: Recommended (5-50 users)
   - Authentication: Keycloak (recommended) or htpasswd
   - Category: Workshops
   - Infrastructure: CNV with autoscaling
   - Showroom: Auto-selected based on config type

6. **Workload selection** - Based on workshop abstract and technology keywords

7. **Generate catalog files** - Using UUID and showroom repo URL collected above

8. **Testing confirmation** - Ask user to test in RHDP Integration before proceeding

**Step D: AgV Testing Confirmation (REQUIRED if creating new)**

```
Q: Have you tested the AgV catalog in RHDP Integration?

Options:
1. Yes, tested and working → Proceed to Step 3
2. No, I'll test it first → Pause workflow
3. Skip testing (not recommended) → Proceed with warning

Your choice? [1/2/3]
```

**CRITICAL**: Do NOT proceed to Step 3 until AgV workflow is complete or user confirms skip.

**If user chooses option 1 or 2 (NO AgV help):**
- Use placeholder attributes in module content
- Proceed directly to Step 3

---

### Step 3: Gather Module-Specific Details

Now for this specific module:

1. **Module file name and numbering**:
   - **Naming convention**: `0X-module-YY-<slug>.adoc` (e.g., `03-module-01-pipelines-intro.adoc`)
   - **Title convention**: `= Module X: <Title>` (e.g., `= Module 1: Pipeline Fundamentals`)
   - Files go in `content/modules/ROOT/pages/`
   - **Number prefix**: 03 for first module, 04 for second, etc. (after 01-overview, 02-details)
   - **Conflict detection**: If file exists, suggest next available number
   - **Warning**: Don't overwrite existing modules without confirmation

2. **Reference materials** (optional but recommended):
   - URLs to Red Hat product documentation
   - Local file paths (Markdown, AsciiDoc, text, PDF)
   - Pasted content
   - **Better references = better content quality**
   - If not provided: Generate from templates and common patterns

3. **UserInfo variables** (optional, for accurate showroom content):
   - If not already provided in Step 2.5, **I must ask the user:**

   ```
   Q: Do you have access to a deployed environment on demo.redhat.com or integration.demo.redhat.com?

   If YES (RECOMMENDED - easiest and most accurate):
   Please share the UserInfo variables from your deployed service:

   1. Login to https://demo.redhat.com (or integration.demo.redhat.com)
   2. Go to "My services" → Your service
   3. Click "Details" tab
   4. Expand "Advanced settings" section
   5. Copy and paste the output here

   This provides exact variable NAMES like:
   - openshift_cluster_console_url
   - openshift_cluster_admin_username
   - gitea_console_url
   - [custom workload variables]

   CRITICAL: I will use these to know WHICH variables exist, NOT to replace them with actual values!
   Variables will stay as placeholders: {openshift_cluster_console_url}
   Showroom replaces these at runtime with actual deployment values.

   If NO:
   Q: Would you like to use placeholder attributes for now?

   If YES:
   I'll use placeholders: {openshift_console_url}, {user}, {password}
   You can update these later when you get Advanced settings.

   If NO (RHDP internal team only):
   I can extract variables from AgnosticV repository if you have it cloned locally.
   This requires AgV path and catalog name.
   Note: Less reliable than Advanced settings.
   ```

4. **Main learning objective**:
   - Example: "Create and run a CI/CD pipeline with Tekton"

5. **Business scenario**:
   - Auto-detect from previous module (if exists)
   - Or ask for company name (default: ACME Corp)

6. **Technology/product focus**:
   - Example: "OpenShift Pipelines", "Podman"

7. **Number of exercises**:
   - Recommended: 2-3

8. **Diagrams, screenshots, or code blocks** (optional):
   - Do you have diagrams, screenshots, or code examples to include?
   - If yes: Provide file paths or paste content
   - I'll save them to `content/modules/ROOT/assets/images/`
   - And reference them properly in AsciiDoc

### Step 4: Get UserInfo Variables (if applicable)

If UserInfo variables weren't already provided in Step 2.5 or Step 3, I'll ask for them now.

**RECOMMENDED: Get from Deployed Environment (Primary Method)**

I'll ask: "Do you have access to a deployed environment on demo.redhat.com or integration.demo.redhat.com?"

**If YES** (recommended):
```
Please share the UserInfo variables from your deployed service:

1. Login to https://integration.demo.redhat.com (or demo.redhat.com)
2. Go to "My services" → Find your service
3. Click on "Details" tab
4. Expand "Advanced settings" section
5. Copy and paste the output here
```

This shows all available variables like:
- `openshift_cluster_console_url`
- `openshift_api_server_url`
- `openshift_cluster_admin_username`
- `openshift_cluster_admin_password`
- `gitea_console_url`
- `gitea_admin_username`
- `gitea_admin_password`
- Custom workload-specific variables

**If NO** (fallback):
I'll use common placeholder variables:
- `{openshift_console_url}`
- `{openshift_api_url}`
- `{user}`
- `{password}`
- `{bastion_public_hostname}`

**Alternative**: Clone collections from AgV catalog
- Read `common.yaml` from user-provided AgV path
- Clone collections from any repository (agnosticd, rhpds, etc.)
- Read workload roles to find `agnosticd_user_info` tasks
- Extract variables from `data:` sections
- Note: Less reliable than deployed environment output

**Map to Showroom attributes**:
```asciidoc
{openshift_cluster_console_url}
{openshift_api_server_url}
{openshift_cluster_admin_username}
{gitea_console_url}
{{ custom_variable }}
```

**CRITICAL: DO NOT Replace Variables with Actual Values**:
- ALWAYS keep variables as placeholders: `{openshift_console_url}`
- NEVER replace with actual values like `https://console-openshift-console.apps.cluster-abc123.abc123.example.opentlc.com`
- Showroom will replace these at runtime with actual deployment values
- Each deployment gets different URLs - variables MUST stay dynamic
- Example in module content:
  ```asciidoc
  . Navigate to the OpenShift Console at {openshift_cluster_console_url}
  . Login with username: {openshift_cluster_admin_username}
  . Password: {openshift_cluster_admin_password}
  ```

**What UserInfo variables are for**:
- Understanding WHICH variables are available
- Learning the correct variable names
- Seeing what endpoints/tools exist in the environment
- NOT for hardcoding actual values in content

### Step 5: Handle Diagrams, Screenshots, and Code Blocks (if provided)

If you provided visual assets or code:

**For images (diagrams, screenshots)**:

**Path convention**:
- All images go in: `content/modules/ROOT/assets/images/`

**Required for every image**:
1. **Meaningful alt text** (for accessibility)
2. **Width guidance** (500-800px typical)
3. **Descriptive filename** (no generic names like "image1.png")

**AsciiDoc syntax** (REQUIRED):
```asciidoc
image::pipeline-execution-1.png[Tekton pipeline showing three tasks executing in sequence,width=700,title="Pipeline Execution in Progress"]
```

**Placeholders**:
- If real image doesn't exist yet: Insert placeholder and add to "Assets Needed" list
- Example placeholder:
  ```asciidoc
  // TODO: Add screenshot
  image::create-task-screenshot.png[OpenShift console showing task creation form,width=600,title="Creating a Tekton Task"]
  ```

**Assets Needed list**:
At end of module, include:
```asciidoc
== Assets Needed

. `pipeline-execution-1.png` - Screenshot of pipeline running in OpenShift console
. `task-definition.png` - YAML editor showing task definition
```

**For code blocks**:
- If you provide code snippets: Format them in AsciiDoc
- Detect language (bash, yaml, python, etc.)
- Add proper syntax highlighting:
  ```asciidoc
  [source,bash]
  ----
  oc create deployment my-app --image=myimage:latest
  ----
  ```

**Recommended image naming**:
- Architecture diagrams: `architecture-overview.png`, `deployment-flow.png`
- UI screenshots: `console-project-view.png`, `dashboard-metrics.png`
- Command outputs: `oc-get-pods-output.png`, `build-logs.png`
- Step-by-step: `step-1-create-task.png`, `step-2-run-pipeline.png`

### Step 6: Fetch and Analyze References

Based on your references, I'll:
- Fetch URLs with WebFetch
- Read local files (supports PDF)
- Extract procedures, commands, concepts
- Identify hands-on opportunities
- Combine with AgnosticV variables (if provided)
- Integrate provided code blocks and diagrams

**Reference Enforcement**:
- Every non-trivial claim must be backed by provided references
- If not backed by reference, mark clearly: `**Reference needed**: <claim>`
- Track which reference supports which section
- If references conflict:
  - Call out the conflict
  - Choose based on version relevance
  - Note the decision in module

**References Used Section**:
- Add at end of each module: "## References"
- List all references used with purpose:
  ```asciidoc
  == References

  * link:https://docs.openshift.com/...[OpenShift Pipelines documentation^] - Pipeline syntax and examples
  * link:https://tekton.dev/...[Tekton documentation^] - Task definitions
  ```

**IMPORTANT: External Link Format**:
- ALL external links MUST use `^` caret to open in new tab
- Format: `link:https://example.com[Link Text^]`
- The `^` ensures users don't lose their place in the workshop
- Internal xrefs (module navigation) should NOT use `^`
- Examples:
  - External: `link:https://docs.redhat.com/...[Red Hat Documentation^]`
  - Internal: `xref:03-module-02-next.adoc[Next Module]` (no caret)

### Step 7: Read Templates and Verification Criteria (BEFORE Generating)

**CRITICAL: I MUST read all these files BEFORE generating content to ensure output meets all standards.**

**Templates to read:**
- `.claude/templates/workshop/templates/00-index-learner.adoc` - Learner-facing index template
- `.claude/templates/workshop/templates/03-module-01.adoc` - Module template
- `.claude/templates/workshop/example/00-index.adoc` - Example index (but write for LEARNERS, not facilitators)
- `.claude/templates/workshop/example/01-overview.adoc` - Example overview
- `.claude/templates/workshop/example/02-details.adoc` - Example details
- `.claude/templates/workshop/example/03-module-01.adoc` - Example module

**Verification criteria to read and apply DURING generation:**
1. `.claude/prompts/enhanced_verification_workshop.txt` - Complete quality checklist
2. `.claude/prompts/redhat_style_guide_validation.txt` - Red Hat style rules
3. `.claude/prompts/verify_workshop_structure.txt` - Structure requirements
4. `.claude/prompts/verify_technical_accuracy_workshop.txt` - Technical accuracy standards
5. `.claude/prompts/verify_accessibility_compliance_workshop.txt` - Accessibility requirements
6. `.claude/prompts/verify_content_quality.txt` - Content quality standards

**How I use these:**
- Read ALL verification prompts BEFORE generating
- Apply criteria WHILE generating content
- Generate content that ALREADY passes all checks
- No separate validation step needed - content is validated during creation

### Step 8: Generate Files (Using Verification Criteria)

**CRITICAL: If this is the FIRST module of a NEW lab, generate files in this order:**

#### Step 8.1: Generate index.adoc (First Module Only)

**Purpose**: Learner-facing landing page - NOT a facilitator guide

**Content**:
```asciidoc
= {{ Workshop Title }}

Welcome to the {{ workshop name }} workshop!

== What you'll learn

In this workshop, you will:

* {{ Learning objective 1 }}
* {{ Learning objective 2 }}
* {{ Learning objective 3 }}
* {{ Learning objective 4 }}

== Who this is for

This workshop is designed for {{ target audience }} who want to {{ main goal }}.

== Prerequisites

Before starting this workshop, you should have:

* {{ Prerequisite 1 }}
* {{ Prerequisite 2 }}
* Access to {{ environment/tools }}

== Workshop environment

{{ Brief description of the lab environment }}

* OpenShift cluster: {openshift_console_url}
* Login credentials will be provided

== Let's get started!

Click on the next section to begin the workshop.
```

**What NOT to do**:
- ❌ Don't copy facilitator guide template from workshop/templates/00-index.adoc
- ❌ Don't include facilitator instructions
- ❌ Don't write "This guide helps workshop facilitators..."

**What TO do**:
- ✅ Write for LEARNERS, not facilitators
- ✅ Simple welcome and what they'll learn
- ✅ Prerequisites and environment info
- ✅ Encouragement to get started

#### Step 8.2: Generate 01-overview.adoc (First Module Only)

**Purpose**: Business scenario and learning objectives

**Content**: See workshop/example/01-overview.adoc for pattern
- Business scenario/story
- Detailed learning objectives
- Expected outcomes
- Estimated time

#### Step 8.3: Generate 02-details.adoc (First Module Only)

**Purpose**: Technical requirements and setup

**Content**: See workshop/example/02-details.adoc for pattern
- Module timing breakdown
- Technical requirements
- Environment details
- Authors/contact

#### Step 8.4: Generate 03-module-01-*.adoc (Always)

I'll create a complete module with:

**Required Structure**:
- Learning objectives (3-4 items)
- Business introduction with scenario
- 2-3 progressive exercises
- Step-by-step instructions with commands
- **Verification checkpoints** (REQUIRED - see below)
- Image placeholders
- **Troubleshooting section** (REQUIRED - see below)
- **Learning outcomes checkpoint** (REQUIRED - see below)
- Module summary
- **References section** (REQUIRED)

**Mandatory: Verification Checkpoints**:
Each major step must include:
```asciidoc
=== Verify

Run the following to confirm success:

[source,bash]
----
oc get pods
----

Expected output:
----
NAME                     READY   STATUS    RESTARTS   AGE
my-app-xxxxx-xxxxx      1/1     Running   0          2m
----

✓ Pod status is "Running"
✓ READY shows 1/1
```

**Mandatory: Troubleshooting Section**:
Every module must include:
```asciidoc
== Troubleshooting

**Issue**: Pod stuck in "ImagePullBackOff"
**Solution**:
. Check image name: `oc describe pod <pod-name>`
. Verify registry credentials
. Common fix: `oc set image-lookup <deployment>`

**Issue**: Permission denied errors
**Solution**:
. Verify you're in correct project: `oc project`
. Check RBAC: `oc whoami` and `oc auth can-i create pods`

**Issue**: Command not found
**Solution**:
. Verify OpenShift CLI installed: `oc version`
. Expected version: {ocp_version}
```

**Mandatory: Learning Outcomes Checkpoint**:
Every module must include a learning confirmation (not just technical validation):
```asciidoc
== Learning Outcomes

By completing this module, you should now understand:

* ✓ How Tekton tasks encapsulate reusable CI/CD steps
* ✓ The relationship between tasks, pipelines, and pipeline runs
* ✓ How to troubleshoot failed pipeline executions using logs and status
* ✓ When to use sequential vs parallel task execution patterns
```

**Guidelines**:
- 3-5 bullet outcomes tied to original learning objective
- Focus on understanding ("understand how X works") not just doing ("created X")
- Use outcomes later for blog transformation
- Helps reviewers, instructors, and people skimming modules

**Optional but Recommended: Cleanup**:
If module changes shared state:
```asciidoc
== Cleanup (Optional)

To reset your environment:

[source,bash]
----
oc delete project my-project
----
```

**Quality**:
- Valid AsciiDoc syntax
- Proper Red Hat product names
- Sentence case headlines
- Second-person narrative
- Code blocks with syntax highlighting

### Step 9: Final Quality Check

**Since verification criteria were applied during generation (Step 7-8), the module should already meet all standards.**

**Quick final checks:**

1. **AsciiDoc Syntax**:
   - ✓ All code blocks have proper syntax: `[source,bash]`
   - ✓ No broken includes
   - ✓ All attributes defined
   - ✓ External links use `^` caret to open in new tab

2. **Completeness**:
   - ✓ All required sections present (see Step 8)
   - ✓ Verification checkpoints after major steps
   - ✓ Troubleshooting section with 3+ scenarios
   - ✓ Learning outcomes section
   - ✓ References section

3. **Navigation**:
   - ✓ nav.adoc will be updated in Step 10

**Note:** Content was generated using verification prompts from Step 7, so it should already comply with:
- Red Hat style guide
- Workshop structure standards
- Technical accuracy requirements
- Accessibility standards
- Content quality standards

### Step 10: Update Navigation (REQUIRED)

I'll automatically update `content/modules/ROOT/nav.adoc` - this is REQUIRED for the module to appear in the Showroom sidebar.

**Navigation Rules**:
1. **Read existing nav.adoc first** - don't overwrite existing entries
2. **Keep index.adoc at top** if it exists
3. **Maintain sequential ordering** of modules
4. **Add new module in correct position** based on module number

**What I'll add**:
```asciidoc
* xref:index.adoc[Home]

* xref:03-module-01-intro.adoc[Module 1: Introduction]
** xref:03-module-01-intro.adoc#exercise-1[Exercise 1: Setup]
** xref:03-module-01-intro.adoc#exercise-2[Exercise 2: First Pipeline]

* xref:04-module-02-advanced.adoc[Module 2: Advanced Topics]  ← NEW MODULE
** xref:04-module-02-advanced.adoc#exercise-1[Exercise 1: Git Integration]
** xref:04-module-02-advanced.adoc#exercise-2[Exercise 2: Triggers]
```

**Conflict handling**:
- If module number conflicts with existing file, warn user
- Suggest next available number
- Do NOT overwrite without confirmation

**Note**: Without this nav.adoc entry, your module won't be accessible in Showroom!

### Step 11: Deliver

**CRITICAL: Manage Output Tokens to Prevent Overflow**

**Token Management Rules**:
1. **Write files using Write tool** - Don't output full file contents to user
2. **Show brief confirmations only** - "✅ Created: file.adoc (X lines)"
3. **Provide summary at end** - List what was created, not the full content
4. **Never output entire module content** - Files are already written
5. **Keep total output under 5000 tokens** - Brief summaries only

**Output Format for FIRST module**:

```
✅ Workshop Generation Complete

**Files Created**:
- content/modules/ROOT/pages/index.adoc (32 lines) - Learner landing page
- content/modules/ROOT/pages/01-overview.adoc (85 lines) - Business scenario
- content/modules/ROOT/pages/02-details.adoc (67 lines) - Technical details
- content/modules/ROOT/pages/03-module-01-intro.adoc (234 lines) - First hands-on module
- content/modules/ROOT/nav.adoc (updated)
```

**Output Format for CONTINUATION modules**:

```
✅ Module Generation Complete

**Files Created**:
- content/modules/ROOT/pages/04-module-02-advanced.adoc (198 lines)
- content/modules/ROOT/nav.adoc (updated)

**Module Structure**:
- Learning objectives: 4 items
- Exercises: 3
- Verification checkpoints: 3
- Troubleshooting scenarios: 5
- Learning outcomes: 4 items

**Assets**:
- Images needed: 2 placeholders (see module for TODO comments)
- Dynamic attributes used: {openshift_console_url}, {user}, {password}

**Next Steps**:
1. Review module: content/modules/ROOT/pages/04-module-02-advanced.adoc
2. Capture screenshots for placeholder images
3. Test commands in your environment
4. Run: verify-content to check quality
5. Create next module: create-lab (continuing existing lab)

**Note**: All files have been written. Use your editor to review them.
```

**What NOT to do**:
- ❌ Don't show full module content in response
- ❌ Don't output the entire file you just created
- ❌ Don't paste hundreds of lines of generated AsciiDoc
- ❌ Don't include long example sections in output

**What TO do**:
- ✅ Write files using Write tool
- ✅ Show brief "Created: filename (X lines)" confirmations
- ✅ Provide structured summary
- ✅ Give clear next steps
- ✅ Keep output concise (under 5000 tokens)

### Step 12: Offer to Generate Conclusion Module (Optional)

**After delivering all modules, ask if user wants a conclusion module:**

```
Q: Would you like me to generate a conclusion module to wrap up the workshop?

This adds a final module that:
- Summarizes what learners accomplished
- Lists key takeaways
- Provides next steps and resources
- Suggests related workshops and certification paths

Options:
1. Yes, generate conclusion module
2. No, I'll create it later
3. No, workshop is complete without it

Your choice? [1/2/3]
```

**If user chooses option 1 (Yes)**:

1. Detect highest module number (e.g., if last module is 07-module-05, conclusion will be 08-conclusion.adoc)
2. Generate conclusion module using the embedded template below
3. Customize the template by:
   - Extracting all learning outcomes from previous modules
   - Listing 3-5 key takeaways from the workshop
   - Providing next steps (related workshops, docs, practice projects)
4. Update nav.adoc with conclusion entry at the end
5. Provide brief confirmation

**Embedded Conclusion Template**:
```asciidoc
= Conclusion and Next Steps

Congratulations! You've completed the {{ workshop_name }} workshop.

== What You've Learned

Throughout this workshop, you've gained hands-on experience with:

* ✅ {{ learning_outcome_1 }}
* ✅ {{ learning_outcome_2 }}
* ✅ {{ learning_outcome_3 }}
* ✅ {{ learning_outcome_4 }}

You now have the skills to {{ primary_capability }}.

== Key Takeaways

The most important concepts to remember:

. **{{ key_concept_1 }}**: {{ brief_explanation_1 }}
. **{{ key_concept_2 }}**: {{ brief_explanation_2 }}
. **{{ key_concept_3 }}**: {{ brief_explanation_3 }}

== Next Steps

Ready to continue your journey? Here are some recommended next steps:

=== Recommended Workshops

Explore related workshops to expand your skills:

* link:{{ related_workshop_1_url }}[{{ related_workshop_1_name }}^] - {{ related_workshop_1_description }}
* link:{{ related_workshop_2_url }}[{{ related_workshop_2_name }}^] - {{ related_workshop_2_description }}

=== Documentation and Resources

Deepen your knowledge with these resources:

* link:{{ docs_url_1 }}[{{ product_name }} Official Documentation^]
* link:{{ docs_url_2 }}[{{ feature_name }} Guide^]
* link:{{ community_url }}[{{ product_name }} Community^]

=== Practice Projects

Put your new skills to work:

. **{{ project_idea_1 }}**: {{ project_description_1 }}
. **{{ project_idea_2 }}**: {{ project_description_2 }}
. **{{ project_idea_3 }}**: {{ project_description_3 }}

== Share Your Feedback

Help us improve this workshop:

* What did you find most valuable?
* What could be improved?
* What topics would you like to see covered in future workshops?

Contact us: {{ feedback_contact }}

== Thank You!

Thank you for participating in this workshop. We hope you found it valuable and informative.

Keep building, keep learning! 🚀

---

**Workshop**: {{ workshop_name }} +
**Completed**: {localdate} +
**Platform**: Red Hat Showroom
```

**Conclusion Module Naming**:
- File: `0X-conclusion.adoc` (sequential number, e.g., 08-conclusion.adoc)
- Title: `= Conclusion and Next Steps`
- Nav entry: `* xref:0X-conclusion.adoc[Conclusion and Next Steps]`

**Content to Include**:
- ✅ "What You've Learned" - Extract from all module learning outcomes
- ✅ "Key Takeaways" - 3-5 most important concepts
- ✅ "Next Steps" - Related workshops, documentation, practice projects
- ✅ "Thank You" - Closing message

**If user chooses option 2 or 3**:
- Skip conclusion generation
- Note in summary that user can add conclusion later using the template

## Example Usage

### Example 1: Create First Module with Overall Story Planning

```
User: Create a lab about OpenShift Pipelines for developers

Skill: Great! Since this is a new lab, let me gather the overall story first.

**Overall Lab Planning:**

Q: Is this the first module or continuing existing lab?
A: First module of a new lab

Q: What's the overall goal of this lab?
A: "Teach developers how to build and deploy cloud-native CI/CD pipelines using OpenShift Pipelines"

Q: Target audience?
A: Intermediate developers familiar with containers and Kubernetes

Q: What should learners know by the end?
A: - Create Tekton tasks and pipelines
   - Integrate with Git repositories
   - Deploy applications via automated pipelines
   - Troubleshoot pipeline failures

Q: Company/business scenario?
A: "DevOps Corp" - A company struggling with slow, manual deployment processes

Q: Estimated total duration?
A: 90 minutes

**Recommended Module Flow:**

Based on your goals, I recommend 3 modules:

Module 1: Pipeline Fundamentals (30 min)
- Introduce Tekton concepts
- Create first task
- Run simple pipeline
- Story: DevOps Corp's current manual deployment pain

Module 2: Git Integration & Automation (30 min)
- Connect pipelines to Git
- Trigger on commits
- Build from source
- Story: Enabling developer self-service

Module 3: Production Pipelines (30 min)
- Multi-stage pipelines (dev, test, prod)
- Pipeline parameters and workspaces
- Monitoring and troubleshooting
- Story: Full automation, reduced deployment time

Does this flow work for you, or would you like adjustments?

User: Perfect! Let's start with Module 1.

Skill: Excellent! Now let me gather details for Module 1...

Q1: Module file name? → "03-pipelines-intro.adoc"
Q2: AgnosticV catalog item? → None
Q3: Reference materials? → https://docs.openshift.com/pipelines/1.12/
Q4: Learning objective? → "Create and execute your first Tekton pipeline"
Q5: Business scenario? → "DevOps Corp" (using overall story)
Q6: Technology? → "OpenShift Pipelines / Tekton"
Q7: Exercise count? → 3
Q8: Diagrams/code? → No, not yet

[Generates Module 1 with DevOps Corp story]
[Sets up story arc for modules 2 and 3]

✓ Created: content/modules/ROOT/pages/03-pipelines-intro.adoc
✓ Story established: DevOps Corp's deployment transformation
✓ Module flow documented for next modules
✓ Ready for Module 2 (will auto-continue story)
```

### Example 2: Continue Existing Lab (Auto-Detect Story)

```
User: Create Module 2 for the OpenShift Pipelines lab

Skill: Let me check if this continues an existing lab...

Q: Is this first module or continuing?
A: Continuing existing lab

Q: Path to previous module?
A: content/modules/ROOT/pages/03-pipelines-intro.adoc

[Reads previous module]
→ Detected story: "DevOps Corp deployment transformation"
→ Detected company: "DevOps Corp"
→ Detected progression: Module 1 covered fundamentals
→ Next logical step: Git integration

I'll continue the DevOps Corp story. Now for Module 2 details...

Q1: Module file name? → "04-pipelines-git.adoc"
Q2: AgnosticV catalog item? → None
Q3: Reference materials? → https://docs.openshift.com/pipelines/.../triggers
Q4: Learning objective? → "Automate pipeline execution via Git webhooks"
Q5: Technology? → "OpenShift Pipelines / Tekton Triggers"
Q6: Exercise count? → 3
Q7: Diagrams/code? → No

[Generates Module 2]
- Continues DevOps Corp narrative
- References accomplishments from Module 1
- Builds toward Module 3's production pipeline

✓ Created: content/modules/ROOT/pages/04-pipelines-git.adoc
✓ Story continuity maintained from Module 1
✓ Ready for Module 3 (final module in recommended flow)
```

### Example 3: Create Module from Red Hat Docs

```
User: Create Module 1 for OpenShift Pipelines using:
      https://docs.openshift.com/pipelines/1.12/

Skill: I'll create that module. Let me ask a few questions...
       [asks if first module or continuing]
       [if first: asks overall story questions]
       [asks module-specific questions]
       [generates module with scenario]
       [validates with agents]

✓ Created: content/modules/ROOT/pages/03-pipelines-intro.adoc
✓ 3 exercises: Create task, Define pipeline, Run pipeline
✓ Screenshot guide provided
✓ Ready to add to nav.adoc
```

### Example 2: Create Module with AgnosticV Integration

```
User: Create Module 1 for Red Hat OpenShift AI demo

Skill: Let me gather information...

Q1: Module file name? → "03-rhods-intro.adoc"
Q2: AgnosticV catalog item? → "ocp4_workload_rhods_demo"
Q3: Reference materials? → https://docs.redhat.com/en/documentation/red_hat_openshift_ai/
Q4: Learning objective? → "Deploy and test AI/ML workloads on OpenShift AI"
Q5: Business scenario? → ACME Corp (first module)
Q6: Technology focus? → "Red Hat OpenShift AI"
Q7: Exercise count? → 3

[Reads AgnosticV catalog]
→ Found: ~/work/code/agnosticv/catalogs/ocp4_workload_rhods_demo/common.yaml
→ Workloads: rhpds.rhods_demo.ocp4_workload_rhods_demo

[Reads AgnosticD workload]
→ Location: ~/work/code/agnosticd-v2/collections/ansible_collections/rhpds/rhods_demo/
→ Extracted UserInfo variables:
  - openshift_console_url
  - rhods_dashboard_url
  - user_name
  - user_password

[Generates module with:]
- Variables mapped to Showroom attributes:
  * {openshift_console_url}
  * {rhods_dashboard_url}
  * {user}
  * {password}
- Commands using these variables
- Example: "Log into OpenShift Console at {openshift_console_url}"

✓ Created: content/modules/ROOT/pages/03-rhods-intro.adoc
✓ AgnosticV variables integrated
✓ 3 exercises with dynamic variables
✓ Screenshot guide provided
```

### Example 3: Create Module with Diagrams and Code Blocks

```
User: Create Module 1 for container security. I have an architecture diagram
      and some example Dockerfiles.

Skill: Great! Let me ask some questions...

Q1: Module file name? → "03-security-intro.adoc"
Q2: AgnosticV catalog item? → None
Q3: Reference materials? → https://docs.redhat.com/en/documentation/...
Q4: Learning objective? → "Implement container security best practices"
Q5: Business scenario? → ACME Corp
Q6: Technology? → "Container security, Podman, OpenShift"
Q7: Exercise count? → 3
Q8: Diagrams/screenshots/code? → Yes, I have:
    - Architecture diagram: ~/diagrams/security-architecture.png
    - Code: Secure Dockerfile examples (paste below)

User provides:
```dockerfile
FROM registry.redhat.io/ubi9/ubi-minimal:latest
USER 1001
WORKDIR /app
COPY --chown=1001:0 app.jar .
RUN chmod 440 app.jar
CMD ["java", "-jar", "app.jar"]
```

Skill: Perfect! Processing...

[Copies diagram to assets/images/]
→ Saved: content/modules/ROOT/assets/images/security-architecture.png

[Formats code blocks with syntax highlighting]
→ Integrated Dockerfile examples in exercises

[Generates module with:]
- Architecture diagram referenced:
  image::security-architecture.png[align="center",width=800,title="Container Security Architecture"]

- Code blocks formatted:
  [source,dockerfile]
  ----
  FROM registry.redhat.io/ubi9/ubi-minimal:latest
  USER 1001
  ...
  ----

- Exercise flow integrates the diagram and code naturally

✓ Created: content/modules/ROOT/pages/03-security-intro.adoc
✓ Diagram saved and referenced: security-architecture.png
✓ Code blocks integrated with syntax highlighting
✓ Screenshot guide for additional captures needed
```

## Tips for Best Results

- **Specific objectives**: "Build and deploy container with persistent storage" vs "Learn containers"
- **Multiple references**: More context = better content
- **Continue scenarios**: Reference previous module for narrative continuity
- **Test commands**: Always verify in real environment

## Quality Standards

Every module will have:
- ✓ Valid AsciiDoc syntax
- ✓ 3-4 clear learning objectives
- ✓ Business context introduction
- ✓ Progressive exercises (foundational → advanced)
- ✓ Verification steps
- ✓ Module summary
- ✓ Image placeholders
- ✓ External links with `^` to open in new tab
- ✓ Red Hat style compliance
