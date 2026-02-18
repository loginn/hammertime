---
phase: quick-4
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - "(75 deleted files staged via git rm)"
  - "(~20 untracked .gd.uid files added)"
  - "(untracked assets/, Wireframe/, .planning/config.json, .planning/debug/resolved/ added)"
  - "scenes/gameplay_view.gd (revert whitespace change)"
autonomous: true
requirements: []
must_haves:
  truths:
    - "git status shows a clean working tree after commit"
    - "No orphan root-level .gd, .gd.uid, .tscn, .jpg files remain in git index"
    - "All Godot .gd.uid files in proper directories are tracked"
    - "All asset images are tracked"
    - "Planning docs for completed phases 09-12 are removed from git"
  artifacts: []
  key_links: []
---

<objective>
Clean up all orphan files in the git working tree. There are 75 files deleted from disk but still tracked by git (root-level legacy scripts moved/replaced long ago, old planning docs), plus ~20 untracked files that should be tracked (Godot .gd.uid files, asset images, planning config). Also revert an accidental trailing-whitespace-only change to scenes/gameplay_view.gd.

Purpose: Get to a clean git status so v1.4 development starts from a clean state.
Output: Single commit with all cleanup staged and committed.
</objective>

<execution_context>
@/home/travelboi/.claude/get-shit-done/workflows/execute-plan.md
@/home/travelboi/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Stage all deleted files, add untracked files, revert whitespace change, and commit</name>
  <files>All 75 deleted files, all untracked .gd.uid/asset/planning files, scenes/gameplay_view.gd</files>
  <action>
This is a git housekeeping task. All files are already deleted from disk or already exist on disk untracked. No code changes needed.

Step 1 - Revert the accidental whitespace change:
```
git checkout -- scenes/gameplay_view.gd
```
This file only has a trailing tab added to one line. Revert it.

Step 2 - Stage all 75 deleted files for removal from git index:
```
git rm $(git ls-files --deleted)
```
This stages all files that git tracks but no longer exist on disk. These fall into 3 categories:
- Root-level legacy GDScript files (.gd, .gd.uid) that were moved into models/, scenes/, etc. long ago
- Root-level legacy scene files (.tscn) and assets (sword.jpg) replaced by proper structure
- Planning docs for phases 09-12 and v1.1-MILESTONE-AUDIT.md that were deleted
- A debug file moved to resolved/ subfolder

Step 3 - Add all untracked files that should be tracked:
```
git add .planning/config.json
git add .planning/debug/resolved/
git add Wireframe/
git add assets/
git add autoloads/*.gd.uid
git add models/**/*.gd.uid
git add scenes/*.gd.uid
git add tools/*.gd.uid  (if exists)
```
These are:
- .planning/config.json - GSD planning config
- .planning/debug/resolved/ - resolved debug session docs
- Wireframe/ - wireframe reference images
- assets/*.png and *.import - hammer and hero artwork
- Various .gd.uid files - Godot 4.5 UID tracking files for scripts already in git

Step 4 - Verify clean state and commit:
```
git status
```
Should show only staged changes (deletions + additions), no unstaged modifications, minimal untracked files.

Then commit with message: "chore: clean up orphan legacy files and track new assets"

IMPORTANT: Do NOT delete any files from disk. All deletions already happened. This task only updates git's index to match reality.
  </action>
  <verify>
Run `git status` after commit. Working tree should be clean (no unstaged deletions, no untracked .gd.uid or asset files). The only acceptable untracked items would be user-specific files like .godot/ cache.
  </verify>
  <done>git status shows clean working tree. All 75 orphan deletions are committed. All untracked .gd.uid, asset, and planning files are now tracked. No accidental whitespace changes remain.</done>
</task>

</tasks>

<verification>
- `git status` shows clean working tree (no ` D` deletions, no `??` for project files)
- `git log -1 --stat` shows the cleanup commit with expected file counts
- `ls *.gd *.tscn *.jpg 2>/dev/null` in project root returns nothing (no root-level orphans)
</verification>

<success_criteria>
Clean git working tree with all orphan legacy files removed from tracking, all new assets and UID files added to tracking, and no spurious modifications.
</success_criteria>

<output>
After completion, create `.planning/quick/4-fix-the-orphan-legacy-files-delete-if-us/4-SUMMARY.md`
</output>
