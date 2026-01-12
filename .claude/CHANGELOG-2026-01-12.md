# Changelog - January 12, 2026

## Summary

- **NEW SKILL**: `/generate-agv-description` - Generate AgnosticV catalog descriptions
- Critical AsciiDoc formatting fixes to prevent text running together in rendered content
- All images now required to be clickable for better user experience

---

## Key Changes

### 0. NEW SKILL: `/generate-agv-description` (ADDED)

**What It Does**:
Creates properly formatted `description.adoc` files for AgnosticV catalog entries that appear in the Red Hat Demo Platform UI.

**Smart Features**:
- Auto-detects Showroom content in current directory
- Extracts module structure, technologies, and agenda from your content
- Pulls author info from git config
- **Auto-detects GitHub Pages URL from git remote** (converts repo URL to GitHub Pages format)
- Suggests technologies found in guide content
- Auto-generates agenda from module titles
- Preview before writing
- Optional: Commit to git

**Usage**:
```bash
# Navigate to Showroom repo
cd ~/work/code/showroom-ai-ml-lab

# Run skill
/generate-agv-description

# Skill auto-detects Showroom and suggests content
```

**Output Structure**:
1. Brief overview (2-3 sentences) - appears on RHDP catalog tile
2. Warnings (optional) - GPU requirements, etc.
3. Link to rendered Showroom guide
4. Featured Technology and Products (with versions)
5. Detailed overview/agenda (optional)
6. Authors and contact information

**Files Added**:
- `.claude/skills/generate-agv-description/SKILL.md` (new skill)
- Updated: `CLAUDE-SKILLS-GUIDE.adoc` (added skill #5 documentation)

**Integration with Workflow**:
1. `/create-lab` or `/create-demo` - Create content
2. `/verify-content` - Verify quality
3. `/generate-agv-description` - Generate catalog description ← NEW
4. Copy to AgV catalog directory
5. Test in RHDP Integration
6. Create PR

---

### 1. AsciiDoc List Formatting Rules (CRITICAL FIX)

**Problem**: Lists without proper blank lines cause text to run together when rendered in Showroom, making content unreadable.

**What Changed**:
- Added mandatory blank line requirements for all lists
- Updated verification prompts to actively scan for formatting violations
- Fixed demo template with proper spacing
- Added comprehensive examples in SKILL-COMMON-RULES.md

**Required blank lines**:
1. **Blank line BEFORE every list**
2. **Blank line AFTER every list** (before next content)
3. **Blank line after bold text or headings before lists**

**Before (broken rendering)**:
```asciidoc
**Benefits:**
* Cost reduction
* Faster deployment
Next section...
```

**After (correct rendering)**:
```asciidoc
**Benefits:**

* Cost reduction
* Faster deployment

Next section...
```

**Impact**:
- Prevents unprofessional rendering issues
- Improves readability for learners and presenters
- Reduces support burden from formatting confusion
- Maintains Red Hat brand quality standards

---

### 2. Clickable Images Requirement (ALL IMAGES)

**Problem**: Images in workshops/demos were not clickable, forcing users to lose their place to see details.

**What Changed**:
- ALL images must now include `link=self,window=blank`
- Updated both create-lab and create-demo skills with requirement
- Fixed all example code to show correct syntax
- Made it explicit in SKILL-COMMON-RULES.md

**Required syntax**:
```asciidoc
image::diagram.png[Description,link=self,window=blank,width=700,title="My Diagram"]
```

**Optional - Center alignment**:
```asciidoc
image::architecture.png[Architecture,link=self,window=blank,align="center",width=800,title="System Architecture"]
```

**Impact**:
- Learners can click images to see full resolution
- Opens in new tab - doesn't lose place in workshop
- Better user experience for detailed screenshots
- Consistent with team feedback from Nate Stephany

---

### 3. Verification Enhancements

**What Changed**:
- Both verification prompts now actively scan for list formatting issues
- Specific violations checked:
  - Bold text (`**Text:**`) immediately followed by list markers
  - Colons immediately followed by lists
  - Lists without blank lines before/after
  - Lists directly followed by paragraphs
- Detailed before/after examples in error reports
- Business/learning impact explanations

**Files Updated**:
- `.claude/prompts/enhanced_verification_demo.txt` (lines 160-232)
- `.claude/prompts/enhanced_verification_workshop.txt` (lines 170-244)

---

### 4. Template Fixes

**Demo Template** (.claude/templates/demo/02-details.adoc):
- Added blank lines after all section headings
- Fixed blank lines around all lists
- Fixed typos:
  - "introduct" → "introduce"
  - "interationss" → "interactions"

**Workshop Templates**:
- Verified all templates already have correct formatting
- No changes needed

---

## Files Changed

**New Skill**:
```
.claude/skills/generate-agv-description/SKILL.md                (new file, 358 lines)
```

**Documentation**:
```
CLAUDE-SKILLS-GUIDE.adoc                                        (+108 lines - added skill #5)
.claude/CHANGELOG-2026-01-12.md                                 (+57 lines - new skill entry)
.claude/docs/SKILL-COMMON-RULES.md                              (+93 lines - section 4 added)
.claude/prompts/enhanced_verification_demo.txt                  (+72 lines)
.claude/prompts/enhanced_verification_workshop.txt              (+74 lines)
```

**Skills**:
```
.claude/skills/create-lab/SKILL.md                              (+11, -6)
.claude/skills/create-demo/SKILL.md                             (+10, -5)
```

**Templates**:
```
.claude/templates/demo/02-details.adoc                          (+9, -3)
```

**Total**: 9 files changed, 792 insertions(+), 14 deletions(-)

---

## What This Means For Content Creators

### When Creating New Content

**Using /create-lab or /create-demo**:
- Skills automatically generate properly formatted lists
- All images will be clickable by default
- No action needed - it's built in

### When Verifying Existing Content

**Using /verify-content**:
Now checks for:
- ✅ Blank lines before/after all lists
- ✅ Blank lines after bold headings before lists
- ✅ All images include `link=self,window=blank`
- ⚠️ Provides specific fix instructions with examples

### When Fixing Existing Content

**List Formatting**:
1. Find lists in your content
2. Ensure blank line before first item
3. Ensure blank line after last item
4. Ensure blank line after bold headings

**Image Links**:
1. Find all `image::` macros
2. Add `link=self,window=blank` after alt text
3. Verify in Showroom preview

---

## Common Violations and Fixes

### Violation 1: Missing Blank Line Before List

❌ **WRONG**:
```asciidoc
Follow these steps:
. Step 1
. Step 2
```

✅ **CORRECT**:
```asciidoc
Follow these steps:

. Step 1
. Step 2
```

---

### Violation 2: Missing Blank Line After Bold Heading

❌ **WRONG**:
```asciidoc
**Prerequisites:**
* OpenShift installed
* Admin access
```

✅ **CORRECT**:
```asciidoc
**Prerequisites:**

* OpenShift installed
* Admin access
```

---

### Violation 3: Missing Blank Line After List

❌ **WRONG**:
```asciidoc
* First item
* Second item
Next section starts here
```

✅ **CORRECT**:
```asciidoc
* First item
* Second item

Next section starts here
```

---

### Violation 4: Non-Clickable Images

❌ **WRONG**:
```asciidoc
image::diagram.png[My Diagram,width=700,title="Architecture"]
```

✅ **CORRECT**:
```asciidoc
image::diagram.png[My Diagram,link=self,window=blank,width=700,title="Architecture"]
```

---

## Migration Guide

### For Existing Workshops/Demos

If you have content created before today:

1. **Run /verify-content** on your existing modules
2. Review formatting issues reported
3. Fix list formatting:
   - Add blank lines before/after lists
   - Add blank lines after headings
4. Fix image links:
   - Add `link=self,window=blank` to all images
5. Test rendering in Showroom preview
6. Commit changes

### For New Content

All new content automatically follows these standards - no action needed!

---

## Technical Details

### Verification Scanning Logic

The verification agents now use pattern matching to detect:
- `\*\*.*:\*` - Bold text immediately followed by list marker
- `:\n\.` or `:\n\*` - Colon immediately followed by list
- `\*.*\n[A-Z]` - List item followed by paragraph (no blank line)
- `image::[^\[]*\[[^\]]*\]` without `link=self,window=blank`

### AsciiDoc Rendering Behavior

AsciiDoc processors require blank lines to:
- Delimit block boundaries
- Separate lists from surrounding content
- Properly parse list markers vs plain text

Without blank lines, the renderer treats list markers as inline text, causing formatting collapse.

---

## References

**SKILL-COMMON-RULES.md Section 4**: Complete AsciiDoc list formatting guide
**SKILL-COMMON-RULES.md Section 5**: Image path conventions and clickable images
**Team Feedback**: Nate Stephany - clickable images requirement

---

**Last Updated**: January 12, 2026
**Repository**: showroom_template_nookbag (main branch)
**Status**: ✅ Committed
