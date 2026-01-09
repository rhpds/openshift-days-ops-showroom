---
name: create-demo
description: Guide you through creating a Red Hat Showroom demo module using the Know/Show structure for presenter-led demonstrations.
---

---
context: main
model: sonnet
hooks:
  PreToolUse:
    - .claude/hooks/validate-paths.sh
---

# Demo Module Generator

Guide you through creating a Red Hat Showroom demo module using the Know/Show structure for presenter-led demonstrations.

## When to Use

**Use this skill when you want to**:
- Create presenter-led demo content
- Transform technical documentation into business-focused demos
- Add a module to an existing demo
- Create content for sales engineers or field demonstrations

**Don't use this for**:
- Hands-on workshop content → use `/create-lab`
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

## Know/Show Structure

Demos use a different format than workshops:

- **Know sections**: Business context, customer pain points, value propositions, why this matters
- **Show sections**: Step-by-step presenter instructions, what to demonstrate, expected outcomes

This separates what presenters need to **understand** (business value) from what they need to **do** (technical demonstration).

## Arguments (Optional)

This skill supports optional command-line arguments for faster workflows.

**Usage Examples**:
```bash
/create-demo                                   # Interactive mode (asks all questions)
/create-demo <directory>                       # Specify target directory
/create-demo <directory> --new                 # Create new demo in directory
/create-demo <directory> --continue <module>   # Continue from specific module
```

**Parameters**:
- `<directory>` - Target directory for demo files
  - Example: `/create-demo content/modules/ROOT/pages/`
  - If not provided, defaults to `content/modules/ROOT/pages/`
- `--new` - Flag to create new demo (generates index + overview + details + module-01)
- `--continue <module-path>` - Continue from specified previous demo module
  - Example: `/create-demo content/modules/ROOT/pages/ --continue content/modules/ROOT/pages/03-module-01-intro.adoc`
  - Reads previous module to detect story continuity

**How Arguments Work**:
- Arguments skip certain questions (faster workflow)
- You can still use interactive mode by calling `/create-demo` with no arguments
- Arguments are validated before use

## Workflow

**CRITICAL RULES**

### 1. Ask Questions SEQUENTIALLY

- Ask ONE question or ONE group of related questions at a time
- WAIT for user's answer before proceeding
- If user chooses "Yes, help me create new catalog" in Step 2.5, you MUST complete the ENTIRE AgV workflow before proceeding to Step 3
- Do NOT ask questions from multiple steps together
- Do NOT skip workflows based on incomplete answers

### 2. Manage Output Tokens

- **NEVER output full demo content** - Use Write tool to create files
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
4. Presentation objective?
5. Number of demos?
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

**Pattern 1: `/create-demo <directory> --new`**
```
Parsing arguments: "<directory> --new"

✓ Target directory: <directory>
✓ Mode: Create new demo
✓ Will generate: index.adoc → 01-overview → 02-details → 03-module-01

Validating directory...
[Check if directory exists, create if needed]

Skipping: Step 1 (mode already known: NEW demo)
Proceeding to: Step 2 (Plan Overall Demo Story)
```

**Pattern 2: `/create-demo <directory> --continue <module-path>`**
```
Parsing arguments: "<directory> --continue <module-path>"

✓ Target directory: <directory>
✓ Mode: Continue existing demo
✓ Previous module: <module-path>

Validating directory...
[Check if directory exists]

Reading previous module: <module-path>
[Extract story, business context, progression]

Skipping: Step 1 (mode already known: CONTINUE)
Skipping: Step 2 (story detected from previous module)
Proceeding to: Step 3 (Module-Specific Details)
```

**Pattern 3: `/create-demo <directory>`**
```
Parsing arguments: "<directory>"

✓ Target directory: <directory>

Validating directory...
[Check if directory exists]

Skipping: Target directory question
Proceeding to: Step 1 (still need to ask: new vs continue)
```

**Pattern 4: `/create-demo` (no arguments)**
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

### Step 1: Determine Context (First Module vs Continuation)

**SKIP THIS STEP IF**:
- User provided `--new` flag in arguments (already know: NEW demo)
- User provided `--continue <module>` in arguments (already know: EXISTING demo)

**CRITICAL: DO NOT read any files or make assumptions before asking this question!**

**First, ask the user**:

```
Q: Is this the first module of a new demo, or continuing an existing demo?

Options:
1. First module of a NEW demo
2. Continuing an EXISTING demo
3. Something else (please describe)

Your choice? [1/2/3]
```

**ONLY AFTER user answers, proceed based on their response.**

**If continuing existing demo**:
- Provide path to previous module (I'll read and auto-detect the story)

### Step 2: Plan Overall Demo Story (if first module)

If this is the first module, I'll gather the big picture:

**IMPORTANT**: Ask these as **open-ended questions** where users type their answers. Do NOT provide multiple choice options.

1. **Demo overview**:
   - What's the overall message of this demo?
   - Example: "Show how OpenShift accelerates application deployment for enterprises"

2. **Target audience**:
   - Who will see this demo?
   - Example: "C-level, Sales engineers, Technical managers, Partners"
   - What are their business priorities?
   - Example: "Cost reduction, faster time-to-market, competitive advantage"

3. **Business transformation story**:
   - What's the customer challenge you're solving?
   - What's the current state pain?
   - What's the desired future state?

4. **Customer scenario**:
   - What company/industry should we use?
   - Example: "RetailCo", "FinanceCorp", "TechSolutions" or custom
   - Specific business challenge driving urgency?

5. **Key metrics to showcase**:
   - What quantifiable improvements to highlight?
   - Example: "6 weeks → 5 minutes deployment time"

6. **Estimated demo duration**:
   - How long should complete demo take?
   - Example: "15min, 30min, 45min"

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

### Step 2.5: AgnosticV Configuration Assistance (OPTIONAL)

**IMPORTANT**: This is **optional** assistance. First ask if user needs help.

**⚠️ ADVANCED USERS / RHDP DEVELOPERS ONLY**

AgnosticV catalog configuration is for:
- Red Hat Demo Platform (RHDP) developers
- Advanced users who need to provision RHDP environments
- Teams deploying to demo.redhat.com or integration.demo.redhat.com

**Most content creators can skip this** - AgV is only needed if you're provisioning infrastructure for your demo.

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
Q: Do you know of an existing catalog that could be a good base for your demo?

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
- Extract keywords from Step 2 (demo abstract, technology)
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
   1. agd_v2/ (Recommended - most demos)
   2. openshift_cnv/ (For CNV-based infrastructure)

   Your choice? [1/2]
   ```

5. **Demo-specific defaults**:
   - Multi-user: Dedicated (recommended for presenter-led demos)
   - Authentication: Keycloak (recommended)
   - Category: Demos
   - Infrastructure: SNO for dedicated, CNV for demo workshops
   - Showroom: Auto-selected based on config type

6. **Workload selection** - Based on demo abstract and technology keywords

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
- Use placeholder attributes in demo content
- Proceed directly to Step 3

---

### Step 3: Gather Module-Specific Details

Now for this specific module:

1. **Module file name**:
   - Module file name (e.g., "03-demo-intro.adoc", "04-platform-demo.adoc")
   - Files go directly in `content/modules/ROOT/pages/`
   - Pattern: `[number]-[topic-name].adoc`

2. **Reference materials** (optional but recommended):
   - URLs to Red Hat product documentation
   - Marketing materials, solution briefs
   - Local files (Markdown, AsciiDoc, PDF)
   - Pasted content
   - **Better references = better business value extraction**
   - If not provided: Generate from templates and common value propositions

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
- `openshift_cluster_console_url` → For showing presenter where to log in
- `openshift_api_server_url` → For API demonstrations
- `openshift_cluster_admin_username` → For admin access demos
- `openshift_cluster_admin_password` → For demo credentials
- `gitea_console_url` → For Git server demos
- `gitea_admin_username`, `gitea_admin_password` → For Gitea access
- Custom workload-specific variables → Product-specific endpoints

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

**Result**: I'll use these in Show sections for precise presenter instructions with actual URLs and credentials.

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
- Save to `content/modules/ROOT/assets/images/`
- Use business-context names: `retail-transformation-architecture.png`
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

### Step 7: Read Templates and Verification Criteria (BEFORE Generating)

**CRITICAL: I MUST read all these files BEFORE generating content to ensure output meets all standards.**

**Templates to read:**
- `.claude/templates/demo/03-module-01.adoc`
- `.claude/templates/demo/01-overview.adoc`

**Verification criteria to read and apply DURING generation:**
1. `.claude/prompts/enhanced_verification_demo.txt` - Complete demo quality checklist
2. `.claude/prompts/redhat_style_guide_validation.txt` - Red Hat style rules
3. `.claude/prompts/verify_technical_accuracy_demo.txt` - Technical accuracy for demos
4. `.claude/prompts/verify_accessibility_compliance_demo.txt` - Accessibility requirements
5. `.claude/prompts/verify_content_quality.txt` - Content quality standards

**How I use these:**
- Read ALL verification prompts BEFORE generating
- Apply criteria WHILE generating content
- Generate content that ALREADY passes all checks
- No separate validation step needed - content is validated during creation

### Step 8: Generate Demo Module (Using Verification Criteria)

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

**CRITICAL: Manage Output Tokens to Prevent Overflow**

**Token Management Rules**:
1. **Write files using Write tool** - Don't output full file contents to user
2. **Show brief confirmations only** - "✅ Created: file.adoc (X lines)"
3. **Provide summary at end** - List what was created, not the full content
4. **Never output entire demo content** - Files are already written
5. **Keep total output under 5000 tokens** - Brief summaries only

**Output Format**:

```
✅ Demo Module Generation Complete

**Files Created**:
- content/modules/ROOT/pages/demo-01-platform-value.adoc (312 lines)
- content/modules/ROOT/nav.adoc (updated)

**Demo Structure**:
- Know sections: 4 (business context, pain points, value props, ROI)
- Show sections: 3 (technical demonstrations)
- Presenter tips: 8
- Business metrics: 5 quantified benefits
- Troubleshooting scenarios: 4

**Assets**:
- Diagrams needed: 3 placeholders (architecture, before/after, ROI chart)
- Screenshots needed: 2 placeholders (UI demonstrations)
- Dynamic attributes used: {openshift_console_url}, {demo_app_url}

**Presenter Notes**:
- Estimated presentation time: 25 minutes
- Business talking points included in each Know section
- Technical demo scripts in each Show section
- Pause points for questions marked

**Next Steps**:
1. Review demo: content/modules/ROOT/pages/demo-01-platform-value.adoc
2. Prepare diagrams for business context sections
3. Capture screenshots for technical demonstrations
4. Practice demo flow and timing
5. Run: verify-content to check quality
6. Create next module: create-demo (continuing existing demo)

**Note**: All files have been written. Use your editor to review them.
```

**What NOT to do**:
- ❌ Don't show full demo content in response
- ❌ Don't output the entire file you just created
- ❌ Don't paste hundreds of lines of generated AsciiDoc
- ❌ Don't include long example sections in output

**What TO do**:
- ✅ Write files using Write tool
- ✅ Show brief "Created: filename (X lines)" confirmations
- ✅ Provide structured summary
- ✅ Give clear next steps for presenters
- ✅ Keep output concise (under 5000 tokens)

### Step 12: Offer to Generate Conclusion Module (Optional)

**After delivering all demo modules, ask if user wants a conclusion module:**

```
Q: Would you like me to generate a conclusion module to wrap up the demo?

This adds a final module that:
- Summarizes key business value demonstrated
- Recaps ROI and competitive advantages
- Provides clear call-to-action for audience
- Lists next steps (workshops, POC, technical sessions)

Options:
1. Yes, generate conclusion module
2. No, I'll create it later
3. No, demo is complete without it

Your choice? [1/2/3]
```

**If user chooses option 1 (Yes)**:

1. Detect highest module number (e.g., if last module is 05-module-03, conclusion will be 06-conclusion.adoc)
2. Generate conclusion module using the embedded template below
3. Customize the template with Know/Show structure:
   - File: `0X-conclusion.adoc` (where X = next sequential number)
   - **Know**: Business impact recap, ROI summary, competitive advantages
   - **Show**: Demo capabilities recap, technical highlights
   - Next steps: Workshops, POC, deep dives
   - Call to action for decision makers and technical teams
   - Q&A guidance with common questions
4. Update nav.adoc with conclusion entry at the end
5. Provide brief confirmation

**Embedded Demo Conclusion Template**:
```asciidoc
= Demo Conclusion and Next Steps

*Presenter Note*: Use this concluding section to wrap up the demonstration, reinforce key messages, and provide clear next steps for the audience.

== Summary

=== Know

**Business Impact Recap**

You've just seen how {{ product_name }} addresses the critical business challenges we discussed:

* **{{ business_challenge_1 }}**: Solved with {{ solution_1 }}
* **{{ business_challenge_2 }}**: Solved with {{ solution_2 }}
* **{{ business_challenge_3 }}**: Solved with {{ solution_3 }}

**ROI and Value**

The solution demonstrated today delivers:

* {{ roi_metric_1 }} - {{ benefit_1 }}
* {{ roi_metric_2 }} - {{ benefit_2 }}
* {{ roi_metric_3 }} - {{ benefit_3 }}

**Competitive Advantages**

What sets this apart:

. {{ differentiator_1 }}
. {{ differentiator_2 }}
. {{ differentiator_3 }}

=== Show

**What We Demonstrated**

In this demo, you saw:

. ✅ {{ demo_capability_1 }}
. ✅ {{ demo_capability_2 }}
. ✅ {{ demo_capability_3 }}
. ✅ {{ demo_capability_4 }}

**Key Technical Highlights**

The most impressive technical capabilities:

* **{{ technical_highlight_1 }}**: {{ why_it_matters_1 }}
* **{{ technical_highlight_2 }}**: {{ why_it_matters_2 }}
* **{{ technical_highlight_3 }}**: {{ why_it_matters_3 }}

== Next Steps for Your Organization

=== Immediate Actions

Help your audience get started:

. **Try It Yourself**: {{ workshop_url }} - Hands-on workshop based on this demo
. **Request POC**: {{ poc_contact }} - Proof of concept in your environment
. **Schedule Deep Dive**: {{ schedule_url }} - Technical architecture session

=== Recommended Path

**Phase 1: Evaluate** (Weeks 1-2)::
* Attend hands-on workshop
* Review technical documentation
* Assess fit for your use cases

**Phase 2: Pilot** (Weeks 3-6)::
* Deploy proof of concept
* Test with representative workloads
* Measure performance and ROI

**Phase 3: Production** (Months 2-3)::
* Roll out to production environment
* Train teams
* Scale across organization

=== Resources

**Documentation**:

* link:{{ product_docs_url }}[{{ product_name }} Documentation^]
* link:{{ architecture_guide_url }}[Architecture Guide^]
* link:{{ best_practices_url }}[Best Practices^]

**Workshops and Training**:

* link:{{ workshop_url }}[Hands-on Workshop^] - Based on this demo
* link:{{ training_url }}[{{ product_name }} Training^]

**Support and Community**:

* link:{{ community_url }}[Community Forums^]
* link:{{ support_url }}[Enterprise Support^]
* link:{{ blog_url }}[Technical Blog^]

== Call to Action

*Presenter Guidance*: Tailor this section based on your audience (technical vs executive, evaluation vs purchase stage).

=== For Technical Teams

**Ready to build?**

. Access the hands-on workshop: {{ workshop_url }}
. Clone the demo repository: {{ demo_repo_url }}
. Join the community: {{ community_url }}

=== For Decision Makers

**Ready to transform your operations?**

. Schedule a custom demo: {{ custom_demo_url }}
. Request ROI analysis: {{ roi_analysis_contact }}
. Speak with an architect: {{ architect_contact }}

== Questions and Discussion

*Presenter Note*: Leave 5-10 minutes for Q&A. Common questions and answers:

**Q: How long does deployment take?**::
A: {{ deployment_time }} with our guided process. Proof of concept can be running in {{ poc_time }}.

**Q: What's the learning curve?**::
A: {{ learning_curve }}. Workshop participants are productive within {{ productivity_time }}.

**Q: Integration with existing tools?**::
A: {{ integration_summary }}. We support {{ integration_list }}.

**Q: Support and SLAs?**::
A: {{ support_summary }}. Enterprise support includes {{ sla_details }}.

== Presenter Action Items

*For Sales Engineers / Solution Architects*: Follow these steps after the demo:

=== Immediate Follow-up (Within 24 hours)

. **Send Demo Recording**: Email recording link with key timestamps
. **Share Resources**: Send links to documentation, workshop, and trial access
. **Schedule Next Meeting**: Book follow-up for deeper technical discussion or POC planning
. **Internal Notes**: Log demo feedback, questions asked, and objections in CRM

=== Within One Week

. **Proposal or ROI Analysis**: Send customized proposal based on their requirements
. **Technical Deep Dive**: Offer architecture review session with specialist
. **POC Proposal**: Outline proof-of-concept scope, timeline, and success criteria
. **Connect with Product Team**: Loop in product specialists if needed

=== Qualification Checkpoints

Based on this demo, assess:

* **Budget**: Do they have budget allocated or need justification?
* **Timeline**: When do they need to make a decision?
* **Authority**: Who else needs to be involved in the decision?
* **Need**: Is this a critical priority or nice-to-have?

== Thank You

Thank you for your time and attention. We're excited to help you {{ primary_value_proposition }}.

**Contact Information**:

* Sales: {{ sales_contact }}
* Technical: {{ technical_contact }}
* Support: {{ support_contact }}

---

**Demo**: {{ demo_name }} +
**Presented**: {localdate} +
**Platform**: Red Hat Showroom
```

**Conclusion Module Naming**:
- File: `0X-conclusion.adoc` (sequential number, e.g., 06-conclusion.adoc)
- Title: `= Demo Conclusion and Next Steps`
- Nav entry: `* xref:0X-conclusion.adoc[Conclusion and Next Steps]`

**Content to Include**:
- ✅ **Know**: Business impact recap, ROI metrics, competitive advantages
- ✅ **Show**: Demo capabilities summary, technical highlights
- ✅ "Next Steps for Your Organization" - Evaluation path, pilot, production
- ✅ "Resources" - Documentation, workshops, community
- ✅ "Call to Action" - Tailored for technical teams vs decision makers
- ✅ "Q&A Guidance" - Common questions with suggested answers
- ✅ "Thank You" - Contact information and closing

**If user chooses option 2 or 3**:
- Skip conclusion generation
- Note in summary that user can add conclusion later using the template

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
- ✓ External links with `^` to open in new tab
- ✓ Dynamic variables as placeholders (not replaced with actual values)
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
- `.claude/templates/demo/03-module-01.adoc`
- `.claude/templates/demo/01-overview.adoc`

**Agents invoked**:
- `workshop-reviewer` - Validates structure
- `style-enforcer` - Applies Red Hat style

**Files created**:
- Demo module: `content/modules/ROOT/pages/<module-file>.adoc`
- Assets: `content/modules/ROOT/assets/images/`

**Files modified** (with permission):
- `content/modules/ROOT/nav.adoc` - Adds navigation entry
