# Claude Skills Changelog - January 9, 2026

## Summary

Updated Claude Code skills for Red Hat Showroom content generation to be more interactive, conversational, and user-friendly.

## Changes Made

### 1. Fixed "First Module" Wording in create-demo

**Before:**
```
Q: Is this the first module of a new demo, or continuing an existing demo?

Options:
1. First module of a NEW demo
2. Continuing an EXISTING demo
```

**After:**
```
Q: Are you creating a new demo or continuing an existing one?

Options:
1. 🆕 Creating a NEW demo (I'll help you plan the whole story)
2. ➡️  Continuing an EXISTING demo (I'll pick up where you left off)
```

**Rationale:** "First module of a NEW demo" was redundant - if it's a new demo, we're obviously creating the first module.

### 2. Made Questions More Interactive

**Before:**
- Dry bullet points
- Technical language
- "Q:" prefix
- "Your choice? [1/2/3]"

**After:**
- Friendly conversational tone
- Emojis for visual guidance
- Welcome messages ("Let's get started! I'll help you create amazing demo content.")
- "What's your situation? [1/2/3]"
- Question blocks with context and examples

**Example - Lab Planning Questions:**
```
**Question 1 - What Should We Call This?**:
```
What's the name of your workshop?

Example: "Building AI/ML Workloads on OpenShift AI"

I'll use this to set up your lab title and generate a clean URL-friendly slug.

Your lab name:

[After user provides title, I'll suggest a slug like "building-ai-ml-workloads-openshift-ai"]
```
```

### 3. Simplified AgnosticV Question

**Before:** 4 options
```
Options:
1. No, already set up → Skip to Step 3
2. No, I'll handle it myself → Skip to Step 3
3. Yes, help me create new catalog → Continue ↓
4. What's AgnosticV? → Explain

Your choice? [1/2/3/4]
```

**After:** 3 options
```
1. ⏭️  Skip this (I'll handle it or it's already set up)
2. 🆘 Yes, help me create a new catalog
3. ❓ What's AgnosticV? (explain it to me)

What's your situation? [1/2/3]
```

**Rationale:** "Already set up" and "I'll handle it myself" both mean "skip this" - combined them into one option.

### 4. Added Target Directory Question to Interactive Mode

**Issue:** Directory argument support existed (`/create-lab <directory>`) but interactive mode didn't ask for it.

**Added:** Step 1.5 in both create-lab and create-demo skills
```
### Step 1.5: Ask for Target Directory (if not provided as argument)

**SKIP THIS STEP IF**: User provided `<directory>` as argument

**Ask the user**:
```
Where should I create the lab/demo files?

Default location: content/modules/ROOT/pages/

Press Enter to use default, or type a different path:
```

**Validation**:
- If directory doesn't exist, ask: "Directory not found. Create it? [Yes/No]"
- If Yes, create the directory
- If No, ask again for directory
```

**Commits:**
- nookbag: `b7dfd75` - "Add target directory question to interactive mode (Step 1.5)"
- maas: `f351bf0` - "Add target directory question to interactive mode (Step 1.5)"

### 5. Created User-Facing Documentation

**Created:** `CLAUDE-SKILLS-GUIDE.adoc` (466 lines)
- Quick start for Claude Code CLI and Cursor IDE
- All 4 skills with usage examples (/create-lab, /create-demo, /verify-content, /blog-generate)
- Interactive workflow explanations
- Common workflows (new workshop, add modules, create demos)
- Pro tips for content creators
- AgV integration guide (advanced users)
- Quality standards and troubleshooting

**Updated:** `.claude/INTERNAL-DEVELOPER-GUIDE.adoc`
- Added Step 1.5 to workflow documentation
- Expanded workflow from 8 to 12 steps
- Added January 9, 2026 version history entry
- Changed CLAUDE-SKILLS-GUIDE.md reference to .adoc

**Commits:**
- nookbag: `4a2fbcf` - "Add user-facing quick start guide and update internal docs"
- maas: `23e20cc` - "Update user-facing guide with interactive questions and comprehensive examples"

## Files Updated

### Repositories Synced

1. **showroom_template_nookbag** (master template repo)
   - `.claude/skills/create-demo/SKILL.md`
   - `.claude/skills/create-lab/SKILL.md`
   - Commits:
     - `1f775d1` - "Fix create-demo wording: new demo instead of first module"
     - `d449627` - "Make skill questions more interactive and conversational"
     - `77fe0d9` - "Simplify AgV question: combine 'already set up' and 'handle myself' options"

2. **maas-usage-examples** (production repo)
   - `.claude/skills/create-demo/SKILL.md`
   - `.claude/skills/create-lab/SKILL.md`
   - Commits:
     - `3c937e4` - "Fix create-demo wording: new demo instead of first module"
     - `4cecb20` - "Make skill questions more interactive and conversational"
     - `d0ed73d` - "Simplify AgV question: combine 'already set up' and 'handle myself' options"

3. **~/.claude/** (global Claude configuration)
   - Synced entire `.claude/` directory from nookbag
   - 63 files transferred including:
     - 4 skills (blog-generate, create-demo, create-lab, verify-content)
     - 22 templates (demo/, workshop/)
     - 8 agents
     - 10 verification prompts
     - Documentation (SKILL-COMMON-RULES.md, INTERNAL-DEVELOPER-GUIDE.adoc)
   - Added user-facing documentation:
     - CLAUDE-SKILLS-GUIDE.adoc (466 lines)
     - Updated INTERNAL-DEVELOPER-GUIDE.adoc (with Step 1.5 and version history)

## Impact

- **Better user experience:** More welcoming and conversational
- **Clearer options:** No redundant choices
- **Faster workflows:** Less cognitive load to understand what to choose
- **Consistent across repos:** All production repos use same interactive style

## Previous Work Today

Earlier today (before these changes):
- Added lab name configuration (Step 2.1) to update site.yml and antora.yml
- Moved templates from `content/modules/ROOT/pages/` to `.claude/templates/` to fix dev mode
- Embedded conclusion templates in skills (removed external file dependencies)
- Removed certification sections (not applicable for internal RHDP)
- Added Sales Engineer/Solution Architect action items to demo conclusions

## Testing

All changes automatically work in both:
- ✅ Claude Code CLI
- ✅ Cursor IDE (rules are thin wrappers that execute full `.claude/skills/` files)

## Notes

- Global ~/.claude is NOT a git repo (intentional - contains session history and cache)
- Project-level .claude directories ARE tracked in git (nookbag, maas, etc.)
- Sync strategy: nookbag is master → copy to production repos → rsync to ~/.claude
