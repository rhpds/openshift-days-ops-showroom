# Using Showroom Skills in Cursor

This directory contains setup and documentation for using the Showroom content generation skills in Cursor IDE with Claude.

## Quick Start

### 1. Cursor Already Configured! ✅

The `.cursor/rules/` directory is automatically loaded by Cursor. You don't need to do anything special - just open this repository in Cursor and start using the skills.

### 2. Simple Commands

In Cursor chat (Cmd+L or Ctrl+L), just say:

**Create a workshop module:**
```
create lab module
```

**Create a demo module:**
```
create demo module
```

**Verify content quality:**
```
verify content
```

That's it! Claude will read the skill files and guide you through the workflow.

---

## Available Skills

### Lab Module Generation

**What it does**: Creates Red Hat Showroom workshop modules with hands-on exercises, step-by-step instructions, and proper AsciiDoc formatting.

**When to use**:
- Creating a new workshop from scratch
- Adding a module to an existing workshop
- Converting documentation into hands-on lab format

**Commands to trigger**:
- "create lab module"
- "lab-module"
- "generate workshop module"
- "create workshop"
- "new lab"

**What you'll get**:
- For NEW lab: `index.adoc` + `01-overview.adoc` + `02-details.adoc` + `03-module-01-*.adoc`
- For EXISTING lab: `0X-module-YY-*.adoc` (next module only)

---

### Demo Module Generation

**What it does**: Creates presenter-led demo content using Know/Show structure for sales engineers and technical demonstrations.

**When to use**:
- Creating business-focused demos for executives
- Sales engineering demonstrations
- Presenter-led technical showcases

**Commands to trigger**:
- "create demo module"
- "demo-module"
- "generate demo"
- "create demo"
- "presenter-led demo"

**What you'll get**:
- Know sections (business context, value propositions)
- Show sections (presenter instructions, what to demonstrate)

---

### Content Verification

**What it does**: Verifies workshop/demo content quality against Red Hat standards.

**When to use**:
- After creating new content
- Before submitting for review
- Quality checking existing modules

**Commands to trigger**:
- "verify content"
- "check quality"
- "review module"

---

## How It Works

### Behind the Scenes

1. **`.cursor/rules/` directory** (Project Rules)
   - Automatically loaded by Cursor when you open this repo
   - Contains skill invocation rules and critical guidelines
   - Structured format with metadata for each skill
   - Tells Claude which skill to use based on your command

2. **Skill files** (in `.claude/skills/`)
   - `lab-module/SKILL.md` - Workshop module generator workflow
   - `demo-module/SKILL.md` - Demo content generator workflow
   - `verify-content/SKILL.md` - Content verification workflow

3. **Shared rules** (in `.claude/docs/`)
   - `SKILL-COMMON-RULES.md` - Common contracts all skills follow

4. **Verification prompts** (in `.claude/prompts/`)
   - Quality standards, style guides, accessibility requirements

### What Happens When You Use a Skill

```
You: "create lab module"
    ↓
Cursor reads .cursor/rules/lab-module/RULE.md
    ↓
Claude loads .claude/skills/lab-module/SKILL.md
    ↓
Claude asks questions ONE AT A TIME
    ↓
You answer each question
    ↓
Claude generates files using Write tool
    ↓
Shows brief summary (NOT full content)
    ↓
You review files in your editor
```

---

## Important Rules (Automatic in Cursor)

These are enforced automatically by `.cursor/rules/showroom-standards/`:

### ✅ Sequential Questioning
Claude asks ONE question at a time and waits for your answer. Won't ask all questions at once.

### ✅ Token Management
Claude writes files directly (using Write tool) and shows only brief summaries. You won't see hundreds of lines of content in chat.

### ✅ File Generation Order
For NEW labs: `index.adoc` → `01-overview.adoc` → `02-details.adoc` → `03-module-01-*.adoc`

### ✅ File Naming
Consistent numbering: `index.adoc`, `01-overview.adoc`, `02-details.adoc`, `03-module-01-*.adoc`, `04-module-02-*.adoc`

### ✅ External Links
All links open in new tab using `^` caret: `link:https://example.com[Text^]`

### ✅ Dynamic Variables
Variables stay as placeholders: `{openshift_cluster_console_url}` (never replaced with actual values)

### ✅ AgV Catalog Exact Copy
When using reference catalog, creates EXACT copy - only modifies UUID, name, slug, and showroom URL

---

## Example Usage

### Creating Your First Lab Module

1. Open this repository in Cursor
2. Open Cursor chat (Cmd+L / Ctrl+L)
3. Say: `create lab module`
4. Claude asks: "Are you creating a new lab or adding to an existing lab?"
5. Answer: `new lab`
6. Claude asks next question (one at a time)
7. Continue answering questions
8. Claude generates all files and shows summary

### Adding a Module to Existing Lab

1. In Cursor chat: `create lab module`
2. Answer: `existing lab`
3. Provide path to previous module (or story recap)
4. Answer questions sequentially
5. Claude generates next module only

### Creating a Demo

1. In Cursor chat: `create demo module`
2. Answer questions about business scenario, audience, technology
3. Claude generates Know/Show structured demo content

---

## Differences from Claude Code CLI

This Cursor setup provides the same workflow as Claude Code CLI skills, with these differences:

| Feature | Claude Code CLI | Cursor |
|---------|----------------|--------|
| Skill invocation | `/skills`, `lab-module` | "create lab module" in chat |
| Skills menu | ✅ `/skills` command | ❌ Use specific commands |
| Workflow | Identical | Identical |
| File generation | Identical | Identical |
| Quality checks | Identical | Identical |

**The workflow is the same** - just the invocation method differs.

---

## Troubleshooting

### "Claude isn't following the skill"

**Solution**: Make sure you're saying one of the trigger commands:
- "create lab module" (not just "create module")
- "create demo module" (not just "demo")

Or be more explicit:
```
Read .claude/skills/lab-module/SKILL.md and follow ALL instructions
to create a workshop module. Ask questions one at a time.
```

### "Getting too much output in chat"

**Reminder to Claude**:
```
Remember to use Write tool for files and show only brief summaries.
Follow token management rules from .cursor/rules/showroom-standards/.
```

### "Questions asked all at once"

**Reminder to Claude**:
```
Remember to ask ONE question at a time and WAIT for my answer.
Follow sequential questioning rule from .cursor/rules/showroom-standards/.
```

### "Variables replaced with actual values"

**Reminder to Claude**:
```
Keep all variables as {placeholders}. Do NOT replace with actual values.
Follow the dynamic variables rule from .cursor/rules/showroom-standards/.
```

---

## Getting Help

### Documentation

- **Quick Guide**: This file (README.md)
- **User Guide**: `CLAUDE-SKILLS-GUIDE.adoc` (in repository root)
- **Developer Guide**: `.claude/INTERNAL-DEVELOPER-GUIDE.adoc` (detailed technical docs)
- **Shared Rules**: `.claude/docs/SKILL-COMMON-RULES.md` (common contracts)

### Support

- **RHDP Team**: Contact Prakhar Srivastava (Manager, Technical Marketing)
- **Issues**: https://github.com/rhpds/showroom_template_nookbag/issues

---

## For Developers/Maintainers

### Modifying Skills

Skills are defined in `.claude/skills/*/SKILL.md`. To modify a skill:

1. Edit the SKILL.md file
2. Update `.cursor/rules/*/RULE.md` if adding new trigger commands
3. Test in Cursor
4. Commit changes

### Adding New Skills

1. Create `.claude/skills/new-skill-name/SKILL.md`
2. Create `.cursor/rules/new-skill-name/RULE.md` with trigger commands
3. Update this README with skill documentation
4. Test and commit

---

## Quick Reference Commands

Copy-paste these into Cursor chat:

```bash
# Create new lab (generates index + overview + details + module-01)
create lab module

# Add module to existing lab
create lab module

# Create demo content
create demo module

# Verify content quality
verify content

# Force skill to load (if auto-detection fails)
Read .claude/skills/lab-module/SKILL.md and follow all instructions
to create a workshop module. Ask questions one at a time.
```

---

**Ready to create content!** Just say "create lab module" or "create demo module" in Cursor chat.
