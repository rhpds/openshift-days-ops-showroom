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

## Know/Show Structure

Demos use a different format than workshops:

- **Know sections**: Business context, customer pain points, value propositions, why this matters
- **Show sections**: Step-by-step presenter instructions, what to demonstrate, expected outcomes

This separates what presenters need to **understand** (business value) from what they need to **do** (technical demonstration).

## Workflow

### Step 1: Gather Requirements

I'll ask you these key questions:

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

### Step 2: Extract AgnosticV UserInfo Variables (if applicable)

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

### Step 3: Handle Diagrams, Screenshots, and Demo Scripts (if provided)

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

### Step 4: Fetch and Analyze References

Based on your references, I'll:
- Fetch URLs and extract technical capabilities
- Read local files
- Identify business value propositions
- Extract metrics and quantifiable benefits
- Map technical features to business outcomes
- Combine with AgnosticV variables (if provided)
- Integrate provided diagrams and screenshots strategically

### Step 5: Read Demo Templates

I'll read these before generating:
- `content/modules/ROOT/pages/demo/03-module-01.adoc`
- `content/modules/ROOT/pages/demo/01-overview.adoc`
- `.claude/prompts/redhat_style_guide_validation.txt`

### Step 4: Generate Demo Module

I'll create a module with Know/Show structure:

**For each demo part**:

**Know Section**:
- Business challenge explanation
- Current state vs desired state
- Quantified pain points
- Stakeholder impact
- Value proposition

**Show Section**:
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

### Step 5: Validate

I'll automatically run:
- **workshop-reviewer** agent: Validates structure
- **style-enforcer** agent: Applies Red Hat style standards
- Verify Know/Show balance and business focus

### Step 6: Update Navigation

I'll ask if you want me to add the module to `content/modules/ROOT/nav.adoc`.

### Step 7: Deliver

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

```
User: Create demo Module 1 for OpenShift using:
      https://docs.openshift.com/container-platform/4.14/

Skill: I'll create that demo module. Let me ask questions...

Q1: Demo name? → "openshift-platform-value"
Q2: Module number? → 03 (Module 1)
Q3: Target audience? → "Sales engineers presenting to C-level"
Q4: Business scenario? → "RetailCo needs faster time-to-market"
Q5: Technology focus? → "OpenShift Container Platform"
Q6: Number of parts? → 3
Q7: Key metrics? → "6 weeks → 5 minutes deployment time"

[Generates module with:]
- Part 1: Self-service developer platform
- Part 2: Automated CI/CD pipelines
- Part 3: Business continuity and scaling
- Each part has Know (business context) + Show (demo steps)
- Business value callouts throughout

✓ Created: content/modules/ROOT/pages/03-platform-demo.adoc
✓ Presenter notes included
✓ Screenshot guide provided
```

### Example 2: Create Demo with Architecture Diagrams

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
