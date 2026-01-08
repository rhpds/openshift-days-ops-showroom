# Cursor Setup Guide for Your Team

## 1-Minute Setup

Your team can start using the skills in Cursor right now. Here's what they need to do:

### Step 1: Clone the Repository

```bash
git clone https://github.com/rhpds/showroom_template_nookbag.git
cd showroom_template_nookbag
```

### Step 2: Open in Cursor

```bash
cursor .
```

**That's it!** The `.cursor/rules/` directory is already in the repository and will be loaded automatically.

---

## Using the Skills

### Open Cursor Chat

Press `Cmd+L` (Mac) or `Ctrl+L` (Windows/Linux)

### Say Simple Commands

**Create a workshop module:**
```
create lab module
```

**Create a demo module:**
```
create demo module
```

**Verify content:**
```
verify content
```

Claude will guide you through the workflow, asking questions one at a time.

---

## What to Expect

### Example Workflow

```
You: create lab module

Claude: Are you creating a new lab or adding to an existing lab?

Options:
1. Creating a NEW lab (I'll generate: index.adoc → 01-overview → 02-details → 03-module-01)
2. Adding to an EXISTING lab (I'll detect next number and generate: 0X-module-YY only)
3. Something else (please describe)

Your choice? [1/2/3]

You: 1

Claude: Great! Let me gather the overall story first.

What's the overall goal of this lab?

You: Teach developers how to build AI applications on OpenShift AI

Claude: Perfect! Who is this lab for?

[... continues asking questions one at a time ...]

Claude: ✅ Workshop Generation Complete

**Files Created**:
- content/modules/ROOT/pages/index.adoc (32 lines) - Learner landing page
- content/modules/ROOT/pages/01-overview.adoc (85 lines) - Business scenario
- content/modules/ROOT/pages/02-details.adoc (67 lines) - Technical details
- content/modules/ROOT/pages/03-module-01-intro.adoc (234 lines) - First hands-on module
- content/modules/ROOT/nav.adoc (updated)

**Note**: All files have been written. Use your editor to review them.
```

---

## Common Questions

### Q: Do I need API keys?

**A**: No! If you have Cursor, you already have access to Claude. The skills work with Cursor's built-in Claude model.

### Q: Do I need to install anything?

**A**: No! Just clone the repo and open in Cursor. The `.cursorrules` file is already configured.

### Q: Can I use this with Cursor Pro or Cursor Free?

**A**: Works with any Cursor plan that includes Claude access (Pro plan recommended for best experience).

### Q: What if the skill doesn't trigger?

**A**: Be explicit in Cursor chat:
```
Read .claude/skills/lab-module/SKILL.md and follow all instructions
to create a workshop module. Ask questions one at a time.
```

### Q: Where are the files created?

**A**: In `content/modules/ROOT/pages/` directory. You can open them in Cursor to review/edit.

---

## Tips for Best Experience

### 1. Answer Questions One at a Time

Claude will ask questions sequentially. Answer each one before it asks the next.

### 2. Files Written Automatically

You won't see the full file content in chat. Claude writes files and shows brief summaries. Review files in your editor.

### 3. Use Explicit Commands

If auto-detection doesn't work, be explicit:
- "create lab module" (clear)
- "make a module" (might not trigger)

### 4. Have Reference Materials Ready

Skills work better with references:
- URLs to Red Hat documentation
- Local files (Markdown, AsciiDoc, PDFs)
- Existing examples

---

## Team Quick Start Checklist

Share this with your team:

- [ ] Clone repository: `git clone https://github.com/rhpds/showroom_template_nookbag.git`
- [ ] Open in Cursor: `cursor .`
- [ ] Open Cursor chat: `Cmd+L` or `Ctrl+L`
- [ ] Say: `create lab module` or `create demo module`
- [ ] Answer questions one at a time
- [ ] Review generated files in your editor

**That's it!** No installation, no API keys, just Cursor + this repo.

---

## Need Help?

- **Documentation**: See `cursor-setup/README.md` for detailed guide
- **Quick Guide**: See `CLAUDE-SKILLS-CURSOR.adoc` in repository root
- **User Guide**: See `CLAUDE-SKILLS-GUIDE.adoc` in repository root
- **Issues**: Contact Prakhar Srivastava or RHDP team

---

## Sharing with Team

Send this to your team:

```
Hi team,

We now have automated workshop/demo content generation in Cursor!

Setup (1 minute):
1. Clone: git clone https://github.com/rhpds/showroom_template_nookbag.git
2. Open in Cursor: cursor .
3. Open chat (Cmd+L) and say: "create lab module"

That's it! Claude will guide you through creating professional Red Hat workshop content.

Full guide: cursor-setup/README.md in the repo

Questions? Ask me or check the documentation.
```

---

**Your team is ready to use the skills in Cursor!** 🚀
