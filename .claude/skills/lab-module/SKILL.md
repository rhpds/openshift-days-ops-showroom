---
name: lab-module
description: Guide you through creating a single Red Hat Showroom workshop module from reference materials (URLs, files, docs, or text) with business storytelling and proper AsciiDoc formatting.
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
- Creating demo content → use `/demo-module`
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

## Workflow

### Step 1: Determine Context (First Module vs Continuation)

**CRITICAL: DO NOT read any files or make assumptions before asking this question!**

**First, ask the user**:

```
Q: Is this the first module of a new lab, or continuing an existing lab?

Options:
1. First module of a NEW lab
2. Continuing an EXISTING lab
3. Something else (please describe)

Your choice? [1/2/3]
```

**ONLY AFTER user answers, proceed based on their response.**

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

1. **Lab overview**:
   - What's the overall goal of this lab?
   - Example: "Learn to build and deploy AI/ML workloads on OpenShift AI"

2. **Target audience**:
   - Who is this lab for? (Developers, Architects, SREs, Data Scientists, etc.)
   - Experience level? (Beginner, Intermediate, Advanced)

3. **Learning journey**:
   - What should learners know by the end?
   - What skills will they gain?

4. **Story/scenario**:
   - What company/business scenario should we use?
   - What's the business challenge driving this?
   - Default: "ACME Corp" or custom company

5. **Estimated duration**:
   - How long should the complete lab take? (30min, 1hr, 2hr, etc.)

6. **Version and environment scope** (REQUIRED):
   - OpenShift version? (e.g., 4.14, 4.15, 4.16)
   - Product versions? (e.g., OpenShift Pipelines 1.12, OpenShift AI 2.8)
   - Cluster type? (AgnosticV catalog, RHDP, local, etc.)
   - Access level? (admin, developer/non-admin)
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

**Lab-specific defaults** (when creating new catalog):
- Multi-user: Recommended (5-50 users)
- Authentication: Keycloak (recommended) or htpasswd
- Category: Workshops
- Infrastructure: CNV with autoscaling
- Showroom: ocp4_workload_showroom (for OCP-based)

**If user doesn't need help (options 1-2):**
- Use placeholder attributes in module content
- Proceed directly to Step 3

---

### Step 3: Gather Module-Specific Details

Now for this specific module:

1. **Module file name and numbering**:
   - **Naming convention**: `module-0X-<slug>.adoc` (e.g., `module-01-pipelines-intro.adoc`)
   - **Title convention**: `= Module X: <Title>` (e.g., `= Module 1: Pipeline Fundamentals`)
   - Files go in `content/modules/ROOT/pages/`
   - **Conflict detection**: If file exists, suggest next available number
   - **Warning**: Don't overwrite existing modules without confirmation

2. **AgnosticV catalog item** (optional but recommended):
   - Is this based on an AgnosticV catalog item?
   - If yes: Provide catalog item name (e.g., "ocp4_workload_rhods_demo")
   - Default AgnosticV path: `~/work/code/agnosticv/`
   - I'll read the catalog item to extract UserInfo variables

3. **Reference materials**:
   - URLs to Red Hat docs
   - Local file paths (Markdown, AsciiDoc, text, PDF)
   - Or paste content directly

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
- Common variables:
  - `bastion_public_hostname`
  - `openshift_console_url`
  - `openshift_api_url`
  - `user_name`, `user_password`
  - Custom workload-specific variables

**Map to Showroom attributes**:
```asciidoc
{bastion_public_hostname}
{openshift_console_url}
{user}
{password}
{{ custom_variable }}
```

**Example extraction**:
```yaml
# From workload role tasks/main.yml
- name: Save cluster info
  agnosticd.core.agnosticd_user_info:
    data:
      openshift_console_url: "{{ r_openshift_console_url }}"
      openshift_api_url: "{{ r_openshift_api_url }}"
      bastion_public_hostname: "{{ hostvars['bastion']['public_dns_name'] }}"
```

**Result**: I'll use these as Showroom variables in the generated module.

**Formalize Attribute Extraction**:
- Create or update: `content/modules/ROOT/partials/_attributes.adoc`
- Standard attributes to extract/define:
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
- If value unknown, keep as `{attribute}` and list in "Attributes Needed"
- Include attributes file in module:
  ```asciidoc
  include::partial$_attributes.adoc[]
  ```

### Step 5: Handle Diagrams, Screenshots, and Code Blocks (if provided)

If you provided visual assets or code:

**For images (diagrams, screenshots)** - STRICT RULES:

**Path convention** (ENFORCED):
- All images go under: `content/modules/ROOT/images/<module-slug>/`
- Example: `content/modules/ROOT/images/pipelines-intro/pipeline-execution-1.png`
- NOT in `assets/images/` - use `images/` directly

**Required for every image**:
1. **Meaningful alt text** (for accessibility)
2. **Width guidance** (500-800px typical)
3. **Descriptive filename** (no generic names like "image1.png")

**AsciiDoc syntax** (REQUIRED):
```asciidoc
image::pipelines-intro/pipeline-execution-1.png[Tekton pipeline showing three tasks executing in sequence,width=700,title="Pipeline Execution in Progress"]
```

**Placeholders**:
- If real image doesn't exist yet: Insert placeholder and add to "Assets Needed" list
- Example placeholder:
  ```asciidoc
  // TODO: Add screenshot
  image::pipelines-intro/create-task-screenshot.png[OpenShift console showing task creation form,width=600,title="Creating a Tekton Task"]
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

**For architecture diagrams**:
- Save to assets/images/ with descriptive names
- Reference with appropriate width (700-800px for diagrams)
- Add meaningful alt text and titles

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

  * link:https://docs.openshift.com/...[OpenShift Pipelines documentation] - Pipeline syntax and examples
  * link:https://tekton.dev/...[Tekton documentation] - Task definitions
  ```

### Step 7: Read Templates

I'll always read these before generating:
- `content/modules/ROOT/pages/workshop/templates/03-module-01.adoc`
- `content/modules/ROOT/pages/workshop/example/03-module-01.adoc`
- `.claude/prompts/redhat_style_guide_validation.txt`

### Step 8: Generate Module

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

### Step 9: Validate and Quality Gates

**Agent Validation**:
- **workshop-reviewer** agent: Validates structure and pedagogy
- **style-enforcer** agent: Applies Red Hat style standards

**Quality Gates** (run even if agents unavailable):

1. **AsciiDoc Sanity Checks**:
   - ✓ All code blocks have proper syntax: `[source,bash]`
   - ✓ No broken includes
   - ✓ All attributes are defined or listed in "Attributes Needed"
   - ✓ Image paths follow convention
   - ✓ No unclosed blocks

2. **Navigation Check**:
   - ✓ nav.adoc contains the new module
   - ✓ Module numbering is sequential
   - ✓ All xrefs are valid

3. **Instruction Clarity Checks**:
   - ✓ Each step has a clear reason ("why this matters")
   - ✓ Commands are copy/pasteable (no placeholders in commands without explanation)
   - ✓ Expected output shown for verification steps
   - ✓ Verification checkpoints present for each major step
   - ✓ Troubleshooting section covers top 3 failure modes

4. **Module Sizing Check**:
   - ✓ Module targets 20-40 minutes (based on exercise count and complexity)
   - ✓ Module has 1-2 major outcomes, not 5
   - ✓ If module is too large (>50 min estimated), flag for split
   - ✓ Each module builds one clear capability

**If quality gates fail**:
- List specific issues
- Suggest fixes
- Allow user to proceed anyway or regenerate

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

* xref:module-01-intro.adoc[Module 1: Introduction]
** xref:module-01-intro.adoc#exercise-1[Exercise 1: Setup]
** xref:module-01-intro.adoc#exercise-2[Exercise 2: First Pipeline]

* xref:module-02-advanced.adoc[Module 2: Advanced Topics]  ← NEW MODULE
** xref:module-02-advanced.adoc#exercise-1[Exercise 1: Git Integration]
** xref:module-02-advanced.adoc#exercise-2[Exercise 2: Triggers]
```

**Conflict handling**:
- If module number conflicts with existing file, warn user
- Suggest next available number
- Do NOT overwrite without confirmation

**Note**: Without this nav.adoc entry, your module won't be accessible in Showroom!

### Step 11: Deliver

You'll get:

**Generated files**:
- Complete module file at `content/modules/ROOT/pages/<module-file>.adoc`
- Images saved to `content/modules/ROOT/assets/images/` (if provided)
- Proper AsciiDoc references for all assets

**Documentation**:
- Screenshot capture guide (for images you still need to capture)
- Navigation xref snippet
- Review checklist
- Next module suggestions

**Asset summary**:
- List of images included with references
- List of images still needed (placeholders)
- Code blocks integrated with syntax highlighting

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
- ✓ Red Hat style compliance
