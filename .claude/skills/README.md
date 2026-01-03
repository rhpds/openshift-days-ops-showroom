# Claude Skills for Showroom Lab Authoring

**Version**: 1.1
**Last Updated**: 2026-01-03
**Branch**: feature/claude-skills

## Overview

This directory contains Claude skills for authoring Red Hat Showroom workshop and demo content. The skills provide a guided, iterative workflow that ensures production-quality, consistent output.

## Shared Contracts

**All skills follow shared contracts defined in `SKILL-COMMON-RULES.md`**:

- **Version pinning or attribute placeholders** - Prevents "works on my cluster" modules
- **Reference enforcement** - Every claim backed by references or marked "Reference needed"
- **Attribute file location** - Reusable variables in `_attributes.adoc`
- **Image path conventions** - Strict paths for accessibility and organization
- **Navigation update expectations** - nav.adoc updates required (lab/demo skills)
- **Failure-mode behavior** - Skills stop if cannot proceed safely, no partial/guessed content
- **Explicit non-goals** - Clear boundaries prevent scope creep

See `SKILL-COMMON-RULES.md` for complete details.

### Skill-Specific Enhancements

**`/lab-module`**:
- **Learning Outcomes Checkpoint** - Confirms pedagogical understanding (not just technical validation)
- 3-5 bullet outcomes tied to original learning objective
- Helps reviewers, instructors, and makes blog transformation cleaner

**`/demo-module`**:
- **Optional Visual Cues** - Lightweight slide/diagram guidance without forcing asset creation
- Helps presenters prepare without making demos depend on assets

**`/blog-generate`**:
- **Source Traceability** (REQUIRED) - Attribution at end of every blog
- Prevents over-claiming and clarifies authoritative docs vs narrative content
- Platform-specific patterns (Red Hat Developer, internal, marketing)

## Available Skills

### `/lab-module` - Workshop Module Generator
Creates hands-on workshop modules with progressive learning flow.

**Invoke with**: `/lab-module`

**What it does**:
- Plans overall lab story (first module) or continues existing narrative
- Extracts AgnosticD UserInfo variables from AgnosticV catalogs
- Generates complete modules with exercises, verification, troubleshooting
- Validates with agents and quality gates
- Updates nav.adoc automatically

**Output**: `content/modules/ROOT/pages/module-0X-<slug>.adoc`

---

### `/demo-module` - Demo Content Generator
Creates presenter-led demo content using Know/Show structure.

**Invoke with**: `/demo-module`

**What it does**:
- Plans overall demo story with business value propositions
- Creates Know sections (business context) and Show sections (presenter actions)
- Includes talk tracks, Q&A, and metrics highlights
- Validates and updates nav.adoc

**Output**: `content/modules/ROOT/pages/module-0X-<slug>.adoc`

---

### `/blog-generate` - Content Transformation
Transforms completed lab/demo modules into blog posts.

**Invoke with**: `/blog-generate`

**What it does**:
- Converts lab modules → developer tutorials
- Converts demo modules → product announcements
- Supports: Red Hat Developer blog, internal blogs, marketing format
- Adjusts tone and depth based on platform

**Output**: `blog-posts/<topic-slug>.md`

---

## Key Features

### 1. Overall Story Planning (First Module)
When creating the first module of a lab/demo, skills gather the complete story:

**Lab Planning**:
- Overall lab goal and learning journey
- Target audience and experience level
- Company/business scenario
- Module breakdown recommendation (progressive flow)
- Version and environment scope

**Demo Planning**:
- Overall message and value proposition
- Target audience business priorities
- Business transformation story
- Key metrics to showcase
- Demo segment breakdown

### 2. Story Continuity (Subsequent Modules)
When creating modules 2+:
- Reads previous module to auto-detect story
- Continues company scenario seamlessly
- References previous accomplishments
- Builds toward overall goals

**Fallback**: If previous module unavailable, asks for story recap (company, topics covered, skills gained, current state)

### 3. AgnosticV Integration
Both lab and demo skills can:
- Read AgnosticV catalog items (`~/work/code/agnosticv/`)
- Extract workload roles from AgnosticD v2 and v1
- Find `agnosticd_user_info` variables
- Map to Showroom attributes: `{openshift_console_url}`, `{user}`, `{password}`, etc.

### 4. Production-Quality Guardrails

#### Version Pinning
- First module asks: OpenShift version, product versions, cluster type, access level
- Uses attribute placeholders if not provided: `{ocp_version}`, `{pipelines_version}`
- Avoids version-specific CLI/UI steps without attributes

#### Reference Enforcement
- Every claim backed by references or marked `**Reference needed**: <claim>`
- Mandatory "References" section at end of module
- Handles conflicting references (chooses by version relevance)

#### Standard Output Contract
- File naming: `module-0X-<slug>.adoc`
- Title convention: `= Module X: <Title>`
- Conflict detection: suggests next available number
- Nav.adoc: reads existing, maintains sequential ordering

#### Attribute Extraction
- Creates/updates `content/modules/ROOT/partials/_attributes.adoc`
- Standard attributes: console_url, api_url, user, password, namespace, etc.
- Unknown values: kept as `{attribute}` and listed in "Attributes Needed"
- Makes labs reusable across environments

#### Mandatory Sections
Every module includes:
- **Verification checkpoints**: Expected output with success indicators
- **Troubleshooting**: Top 3 failure modes with solutions
- **References**: Links to all sources used
- **Optional Cleanup**: Reset instructions if state changes

#### Asset Management
- Images: `content/modules/ROOT/images/<module-slug>/`
- Required: meaningful alt text, width, descriptive filename
- Placeholders marked and listed in "Assets Needed"

#### Quality Gates
Run before delivery (even without agents):
1. AsciiDoc sanity checks (code blocks, includes, attributes)
2. Navigation checks (nav.adoc updated, sequential numbering)
3. Instruction clarity (reasons, copy/pasteable commands, expected outputs)
4. Module sizing (20-40 min target, 1-2 major outcomes, flag if >50 min)

### 5. Demo-Specific: Talk Track Separation
Demo modules require structured Show sections:
- **What I say**: Talk track for presenter
- **What I do**: Step-by-step actions
- **What they should notice**: Value callouts and metrics
- **If asked**: Common Q&A

Labs do NOT include talk tracks (for hands-on learners, not presenters).

---

## Usage Workflows

### Workflow 1: Create New Lab from Scratch

```
Step 1: Invoke /lab-module

Step 2: Answer "First module or continuing?" → First module

Step 3: Provide overall lab story:
- Lab goal: "Learn to build CI/CD pipelines with OpenShift Pipelines"
- Audience: Intermediate developers
- Learning journey: Create tasks, integrate Git, deploy via pipelines
- Scenario: "DevOps Corp" struggling with slow deployments
- Duration: 90 minutes
- Versions: OpenShift 4.16, Pipelines 1.14

Step 4: Skill recommends 3-module flow → Accept or adjust

Step 5: Provide module details:
- File name: module-01-pipelines-intro.adoc
- AgnosticV catalog: (optional)
- References: https://docs.openshift.com/pipelines/1.14/
- Learning objective: "Create and execute first Tekton pipeline"
- Technology: OpenShift Pipelines
- Exercises: 3
- Diagrams: (optional)

Step 6: Skill generates module with:
- DevOps Corp story
- 3 exercises with verification
- Troubleshooting section
- References
- nav.adoc updated

Output: content/modules/ROOT/pages/module-01-pipelines-intro.adoc
```

### Workflow 2: Continue Existing Lab

```
Step 1: Invoke /lab-module

Step 2: Answer "First module or continuing?" → Continuing

Step 3: Provide previous module path:
- content/modules/ROOT/pages/module-01-pipelines-intro.adoc

Step 4: Skill auto-detects:
- Company: DevOps Corp
- Scenario: Deployment transformation
- Completed: Pipeline fundamentals
- Next: Git integration (suggested)

Step 5: Provide module 2 details:
- File name: module-02-git-integration.adoc
- References: https://docs.openshift.com/pipelines/.../triggers
- Learning objective: "Automate pipelines via Git webhooks"
- Exercises: 3

Step 6: Skill generates module continuing DevOps Corp story

Output: content/modules/ROOT/pages/module-02-git-integration.adoc
```

### Workflow 3: Create Demo with AgnosticV

```
Step 1: Invoke /demo-module

Step 2: Answer "First module or continuing?" → First module

Step 3: Provide overall demo story:
- Message: "Show OpenShift value for C-level"
- Audience: CTOs evaluating platform modernization
- Business priorities: Cost reduction, faster delivery
- Scenario: "RetailCo" facing Black Friday deadline
- Metrics: 8 weeks → 10 min deployments, 80% cost reduction
- Duration: 30 minutes

Step 4: Skill recommends 2-module flow → Accept

Step 5: Provide module details:
- File name: module-01-platform-value.adoc
- AgnosticV catalog: ocp4_workload_demo
- References: https://www.redhat.com/.../openshift
- Demo parts: 3
- Diagrams: ~/diagrams/retail-platform.png

Step 6: Skill extracts AgnosticV variables and generates demo with:
- RetailCo story
- Know/Show structure
- Talk tracks and Q&A
- Metrics throughout

Output: content/modules/ROOT/pages/module-01-platform-value.adoc
```

### Workflow 4: Transform to Blog

```
Step 1: Complete lab modules 1-3

Step 2: Invoke /blog-generate

Step 3: Select source modules:
- module-01-pipelines-intro.adoc
- module-02-git-integration.adoc
- module-03-production.adoc

Step 4: Choose target:
- Platform: Red Hat Developer blog
- Type: Technical tutorial
- Depth: Highly technical
- Word count: 1500-2000
- Code samples: Yes

Step 5: Skill transforms:
- Exercises → narrative flow
- Keeps technical depth
- Adds intro hook and CTAs
- Links to full Showroom lab

Output: blog-posts/openshift-pipelines-tutorial.md
```

---

## File Structure Created by Skills

```
content/modules/ROOT/
├── pages/
│   ├── index.adoc
│   ├── module-01-intro.adoc          # Created by /lab-module
│   ├── module-02-advanced.adoc       # Created by /lab-module
│   └── module-03-demo.adoc           # Created by /demo-module
├── images/
│   ├── intro/                        # Created by /lab-module
│   │   ├── pipeline-execution-1.png
│   │   └── task-definition.png
│   └── demo/                         # Created by /demo-module
│       └── architecture-overview.png
├── partials/
│   └── _attributes.adoc              # Created/updated by skills
└── nav.adoc                          # Updated by all skills

blog-posts/
└── openshift-pipelines-tutorial.md   # Created by /blog-generate
```

---

## Production Readiness: 10 Critical Gaps Addressed

### Gap #1: Continuing Module Input Contract
**Problem**: Ambiguous "reads previous module"
**Solution**: Clear fallbacks - paste content OR story recap questions
**Impact**: Prevents broken continuity

### Gap #2: Version Pinning and Scope Guardrails
**Problem**: "Works on my cluster" modules
**Solution**: Ask versions in first module, use attribute placeholders if missing
**Impact**: Prevents version-specific breakage

### Gap #3: Reference Enforcement
**Problem**: Unsupported claims, no citations
**Solution**: Back claims with references or mark "Reference needed", mandatory References section
**Impact**: Technical accuracy and traceability

### Gap #4: Standard Output Contract
**Problem**: Inconsistent file naming, nav chaos
**Solution**: Strict naming conventions, conflict detection, sequential nav ordering
**Impact**: Deterministic, predictable output

### Gap #5: Formalize Attribute Extraction
**Problem**: Hard-coded values, not reusable
**Solution**: Create _attributes.adoc with standard attributes, list unknowns
**Impact**: Labs reusable across environments

### Gap #6: Mandatory Verification and Troubleshooting
**Problem**: Docs not labs, learners get stuck
**Solution**: Required verification checkpoints and troubleshooting (top 3 issues) in every module
**Impact**: Difference between doc and lab, enables success

### Gap #7: Diagram Path and Alt-Text Rules
**Problem**: Images in wrong places, no accessibility
**Solution**: Strict path convention, required alt text and width, "Assets Needed" list
**Impact**: Accessibility and organization

### Gap #8: Quality Gates Before Delivery
**Problem**: Broken modules shipped
**Solution**: 4-tier validation (AsciiDoc, nav, clarity, sizing) before delivery
**Impact**: Catches errors early

### Gap #9: Demo Talk Track Separation
**Problem**: Demos become labs accidentally
**Solution**: Required structure - What I say / What I do / What they notice / If asked
**Impact**: Clear presenter guidance, labs stay hands-on

### Gap #10: Module Sizing Rules
**Problem**: Modules too large, overwhelming
**Solution**: 20-40 min target, 1-2 outcomes, flag if >50 min
**Impact**: Maintains focus, prevents overwhelm

---

## Quality Standards

### Every Generated Module Includes:
- ✓ Learning objectives (3-4 specific items)
- ✓ Business introduction with scenario
- ✓ Progressive exercises (2-3)
- ✓ Verification checkpoints with expected output
- ✓ Troubleshooting section (top 3 issues)
- ✓ Module summary with key takeaways
- ✓ References section with links
- ✓ Valid AsciiDoc syntax
- ✓ Proper Red Hat product names
- ✓ Sentence case headlines
- ✓ Image placeholders with alt text
- ✓ Optional cleanup section

### Quality Gate Checklist:
- ✓ Code blocks have proper syntax
- ✓ No broken includes
- ✓ All attributes defined or listed
- ✓ Image paths follow convention
- ✓ nav.adoc updated correctly
- ✓ Module numbering sequential
- ✓ Commands are copy/pasteable
- ✓ Expected outputs shown
- ✓ Module sized appropriately (20-40 min)
- ✓ 1-2 major outcomes (not 5+)

---

## Integration with Existing Repo

### Agents (`.claude/agents/`)
Skills invoke these automatically:
- `workshop-reviewer`: Validates structure and pedagogy
- `style-enforcer`: Applies Red Hat style standards
- `researcher`: Validates reference URLs
- `content-converter`: Converts formats
- `technical-editor`: Refines blog tone
- `accessibility-checker`: Validates accessibility

### Prompts (`.claude/prompts/`)
Skills read these before generating:
- `redhat_style_guide_validation.txt`: Red Hat corporate style
- `enhanced_verification_workshop.txt`: Workshop quality checks
- `verify_workshop_structure.txt`: Pedagogical structure
- `verify_technical_accuracy_workshop.txt`: Technical accuracy

### Templates (`.../workshop/templates/`)
Skills use these as base:
- `03-module-01.adoc`: Module template with placeholders
- `README-TEMPLATE-GUIDE.adoc`: Formatting patterns

---

## Tips for Best Results

### For Labs:
- **Specific objectives**: "Build and deploy with persistent storage" vs "Learn containers"
- **Multiple references**: More context = better content
- **Continue scenarios**: Reference previous module for narrative continuity
- **Test commands**: Always verify in real environment

### For Demos:
- **Specific metrics**: "8 weeks → 10 minutes" not "faster"
- **Real scenarios**: Base on actual customer challenges
- **Visual emphasis**: Demos need more screenshots than labs
- **Business language**: Executives care about outcomes, not features

### General:
- Provide good references (official Red Hat docs preferred)
- Be specific about versions (prevents "works on my cluster")
- Reuse company scenarios across modules (consistency)
- Review and iterate (skill creates foundation, you refine)

---

## Troubleshooting

**Issue**: Skill can't find previous module
**Solution**: Provide full path or paste module content when prompted

**Issue**: AgnosticV variables not extracted
**Solution**: Verify catalog path `~/work/code/agnosticv/` and catalog item name

**Issue**: Quality gates failing
**Solution**: Review specific issues listed, accept suggested fixes or regenerate

**Issue**: Module numbering conflict
**Solution**: Skill will suggest next available number, confirm or override

**Issue**: nav.adoc not updating
**Solution**: Check file permissions, skill will warn if update fails

---

## Future Enhancements (Potential)

- `/lab-init`: Initialize complete lab structure (00-index, 01-overview, 02-details)
- `/lab-review`: Comprehensive quality review across all modules
- `/module-enhance`: Add storytelling to existing plain modules
- `/screenshot-guide`: Generate detailed screenshot capture guide
- `/lab-publish`: Prepare for Showroom deployment (validate all files, check nav)

---

## References

- **Showroom-rhads**: https://github.com/rhpds/showroom-rhads (reference implementation)
- **AgnosticV**: https://github.com/rhpds/agnosticv (catalog definitions)
- **AgnosticD v2**: https://github.com/agnosticd/ (workload roles)
- **Red Hat Showroom**: Internal documentation for Antora structure

---

## Commit History

- `49a2735` - Initial skills creation
- `9494ab9` - AgnosticV integration + path fixes
- `e4c5d90` - Diagram/screenshot/code handling
- `7e3cc08` - Story planning + nav.adoc required
- `24789f5` - Production gaps (all 10 critical guardrails)
- `d04f048` - README documentation
- `3982fb4` - Markdown default format for blogs
- `[pending]` - SKILL-COMMON-RULES.md + production hardening (learning outcomes, visual cues, source traceability)

---

## Support

For issues or enhancements:
1. Test skills in new Claude session
2. Review this README for workflows
3. Check commit messages for implementation details
4. Open issue at: https://github.com/rhpds/showroom_template_nookbag/issues

---

**Last Updated**: 2026-01-03
**Status**: Production-ready with comprehensive guardrails
**Maintainer**: Prakhar Srivastava (Red Hat)
