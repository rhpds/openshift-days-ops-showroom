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

**CRITICAL FORMATTING RULES (Added 23:45 EST):**
- ❌ **NEVER** start overview with "This workshop", "This demo", "This hands-on lab", or "This lab"
- ✅ **ALWAYS** start with the main product/technology name
- ❌ **NEVER** use the word "workshop" anywhere in catalog descriptions
- ✅ Use "lab", "demo", "instructor-led", or "self-paced learning" instead
- 🔍 **Always ask:** Is this a Lab or Demo? (even if auto-detected)

**Example Fix**:
```
Before: "This lab demonstrates building a RAG-based chatbot using Red Hat OpenShift AI..."
After:  "Red Hat OpenShift AI with LiteMaaS provides enterprise-grade model serving for RAG-based chatbots..."
```

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

**Last Updated**: January 13, 2026 (09:30 EST)
**Repository**: showroom_template_nookbag (main branch)
**Status**: ✅ Committed

---

## Latest Fix #1 (January 13, 00:10 EST)

**Verification Output Format - ONLY Summary Table at End**

**Problem**: Verification was adding action items or recommendations after the summary table.

**Fix**: Added explicit instructions to both verification prompts:
- **DO NOT add anything after the summary table**
- NO action items after table
- NO next steps after table
- NO recommendations after table
- **The summary table is the FINAL OUTPUT** - stop immediately after the table

**Files Updated**:
```
.claude/prompts/enhanced_verification_workshop.txt   (+2 lines)
.claude/prompts/enhanced_verification_demo.txt       (+2 lines)
```

**Output Format (Now Enforced)**:
1. Detailed issue sections FIRST (top of output)
2. Summary table LAST (bottom of output)
3. **NOTHING after summary table**

**Commit**: `9b5aa06` - "Fix verification output: ONLY summary table at end, no action items"

---

## Latest Fix #2 (January 13, 09:30 EST)

**Remove Score Outputs from All Verification Prompts**

**Problem**: Verification was outputting unwanted "Detailed Scores by Category" table and overall_score/dimension_scores in JSON responses.

**Fix**: Removed all score-related output from 5 verification prompts:
1. `verify_accessibility_compliance_workshop.txt` - Removed `overall_score` and `dimension_scores`
2. `verify_accessibility_compliance_demo.txt` - Removed `overall_score` and `dimension_scores`
3. `verify_content_quality.txt` - Removed `overall_score` and `dimension_scores`
4. `verify_technical_accuracy_workshop.txt` - Removed `overall_score` and `dimension_scores`
5. `verify_technical_accuracy_demo.txt` - Removed `overall_score`, `dimension_scores`, and `content_pattern_analysis`

**Files Updated**:
```
.claude/prompts/verify_accessibility_compliance_workshop.txt   (-9 lines)
.claude/prompts/verify_accessibility_compliance_demo.txt       (-9 lines)
.claude/prompts/verify_content_quality.txt                     (-10 lines)
.claude/prompts/verify_technical_accuracy_workshop.txt         (-9 lines)
.claude/prompts/verify_technical_accuracy_demo.txt             (-44 lines)
.claude/skills/verify-content/SKILL.md                         (+55 lines, -16 lines)
```

**verify-content SKILL.md Updated**:
- Updated "Output Format" section to show detailed sections FIRST, summary table LAST
- Added example showing proper output structure with specific issue counts
- Removed old format showing summary table at top

**New JSON Response Format**:
```json
{
  "strengths": [...],
  "issues": [...],
  "recommendations": [...]
}
```

**Old Format (Removed)**:
```json
{
  "overall_score": 85,
  "dimension_scores": {
    "technical_accuracy": 8,
    ...
  },
  "strengths": [...],
  ...
}
```

**Why This Matters**:
- Cleaner output focused on actionable issues
- No confusing score tables
- Detailed sections come first for easy navigation
- Summary table at end provides quick overview
- Strengths after summary is acceptable

**Commit**: `05195d8` - "Remove score outputs from all verification prompts"

---

## Latest Fix #3 (January 13, 14:30 EST)

**Add Prompt Location Detection - Choose Which Prompts to Use**

**Problem**: Users couldn't choose which verification prompts to use when multiple sets existed (repo-specific, global, or template).

**What Was Added**:

Added **Step 0: Detect and Select Verification Prompts** to verify-content SKILL.md:

**Detection Priority:**
1. **Current Git Repo**: `.claude/prompts/` in current repository (highest priority)
2. **Global Home**: `~/.claude/prompts/` (user's global settings)
3. **Template Fallback**: `showroom_template_nookbag/.claude/prompts/` (source of truth)

**How It Works:**

1. Checks current directory for git repo: `git rev-parse --show-toplevel`
2. Checks for local `.claude/prompts/`: `ls [repo-root]/.claude/prompts/*.txt`
3. Checks global home directory: `ls ~/.claude/prompts/*.txt`
4. Checks template fallback: `ls ~/work/code/showroom_template_nookbag/.claude/prompts/*.txt`
5. If multiple locations found, asks user which to use
6. Shows which prompts will be used before running verification

**Example Prompt Selection Dialog:**
```
🔍 Found verification prompts in multiple locations:

1. Current repo: /Users/psrivast/work/showroom-content/aap-selfserv-intro-showroom/.claude/prompts/
   └─ Last updated: 13 Jan 16:01 (10 prompts)

2. Global home: ~/.claude/prompts/
   └─ Last updated: 13 Jan 14:47 (10 prompts)

3. Template (source): ~/work/code/showroom_template_nookbag/.claude/prompts/
   └─ Last updated: 13 Jan 16:04 (10 prompts)

Which prompts should I use for verification?

Options:
1. Current repo (use repo-specific prompts) - Recommended if customized
2. Global home (use your personal defaults)
3. Template (use latest from source of truth)

Your choice: [1/2/3]
```

**New Section Added:**

Added "Prompt Location Strategy" section explaining:
- Why multiple prompt locations exist
- When to use repo-specific vs global prompts
- How to update prompts from template
- When to customize prompts in repo

**Files Updated:**
```
.claude/skills/verify-content/SKILL.md  (+200 lines - added Step 0 and strategy section)
```

**Why This Matters:**
- Allows repo-specific verification rules for special projects
- Users can choose between customized and standard prompts
- Transparency about which prompts are being used
- Easy to update from template when new rules are released

**Commit**: `497c03f` - "Add prompt location detection to verify-content skill"

**Synced to:**
- `~/.claude/skills/verify-content/SKILL.md`
- All 5 showroom-content repositories

---

## Latest Fix #4 (January 13, 15:00 EST)

**STOP After Strengths Section - No Extra Summaries**

**Problem**: After strengths section, verification was adding unwanted extra text:
- "⏺ Verification Complete! 🎉"
- "Overall Assessment: This is a high-quality workshop (85/100)"
- "Quick Stats"
- "Top 3 Critical Fixes Needed"

**What Was Fixed**:

Added explicit **STOP IMMEDIATELY** instructions to Step 4 in verify-content SKILL.md:

**CRITICAL OUTPUT RULES:**
- Summary table comes LAST, not first
- Detailed sections are at the TOP
- **STOP IMMEDIATELY after strengths section**
- **DO NOT add any additional summaries, assessments, or recaps**
- **NO "Overall Assessment", NO "Quick Stats", NO "Top 3 Fixes"**
- **NO text after strengths - that's the END of output**

The output must end with the strengths section. Nothing comes after it.

**Added to Examples:**

Both Example 1 and Example 2 now end with:
```markdown
✅ Strengths Worth Highlighting

Your module excels in these areas:
1. Clear Step-by-Step Instructions
2. Proper AsciiDoc Formatting
3. Strong Technical Content

[END OF VERIFICATION OUTPUT - NOTHING AFTER THIS]
```

**Clean Output Structure (Enforced):**
1. ✅ Detailed issue sections FIRST (top of output)
2. ✅ Summary table in MIDDLE
3. ✅ Strengths section LAST (bottom of output)
4. ❌ **NOTHING after strengths** - verification ends here

**Files Updated:**
```
.claude/skills/verify-content/SKILL.md  (+12 lines - added STOP rules and END markers)
```

**Why This Matters:**
- Clean, professional output without redundant summaries
- No confusing "Overall Assessment" scores after we removed scores
- Clear end point for verification output
- Easier to read and act on findings

**Commit**: `e1976e5` - "Fix verification output: STOP after strengths section"

**Synced to:**
- `~/.claude/skills/verify-content/SKILL.md`
- All 5 showroom-content repositories

---

**Repository Status**: showroom_template_nookbag (main branch)
**All Fixes Complete**: ✅
**Documentation Updated**: January 13, 2026 (15:00 EST)
