---
name: demo-module
description: Guide you through creating a Red Hat Showroom demo module using the Know/Show structure for presenter-led demonstrations.
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
- Hands-on workshop content → use `/lab-module`
- Converting to blog posts → use `/blog-generate`
- Reviewing existing content → use workshop-reviewer agent

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

## Workflow

### Step 1: Determine Context (First Module vs Continuation)

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

### Step 2.5: AgnosticV Configuration Assistance (OPTIONAL)

**IMPORTANT**: This is **optional** assistance. First ask if user needs help.

**Initial question:**
```
Q: Do you need help with AgnosticV catalog configuration?

Options:
1. No, already set up → Skip to Step 3
2. No, I'll handle it myself → Skip to Step 3
3. Yes, help me find existing catalog
4. Yes, help me create new catalog
5. What's AgnosticV?

Your choice? [1/2/3/4/5]
```

**If user needs help (options 3-4):**

See `.claude/docs/SKILL-COMMON-RULES.md` section "AgnosticV Configuration Assistance" for complete workflow including:
- Access check protocol
- User-suggested catalog search
- Keyword-based recommendations
- Workload selection assistant
- Catalog creation workflow
- UserInfo variable extraction

**Demo-specific defaults** (when creating new catalog):
- Multi-user: Dedicated (recommended for presenter-led demos)
- Authentication: Keycloak (recommended)
- Category: Demos
- Infrastructure: SNO for dedicated demos, CNV for demo workshops
- Showroom: ocp4_workload_showroom (for OCP-based)

**If user doesn't need help (options 1-2):**
- Use placeholder attributes in demo content
- Proceed directly to Step 3

---

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
