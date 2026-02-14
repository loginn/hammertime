# Phase 1: Foundation - Research

**Researched:** 2026-02-14
**Domain:** Godot 4.6 GDScript code formatting, file organization, and project refactoring
**Confidence:** HIGH

## Summary

Phase 1 prepares a Godot 4.6 project for structural refactoring by establishing consistent code style, proper naming conventions, and organized folder structure. The phase focuses on three core activities: (1) automated code formatting with gdformat, (2) file and class renaming to follow Godot 4's snake_case convention, and (3) reorganizing 21 GDScript files from project root into feature-based folders.

**Critical constraint:** File moves MUST be performed in Godot Editor's FileSystem dock, not via command line, to preserve scene references and autoload paths. Godot 4.6's UID system handles resource references automatically when files are moved within the editor, but string-based paths in code and autoload entries in project.godot require manual updates.

**Primary recommendation:** Use gdformat for automated style fixes, commit before every file move operation, and verify game launch (F5 test) after each reorganization step to catch broken references immediately.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| gdformat | 4.x (gdtoolkit) | GDScript code formatter | Official GDQuest-endorsed tool, follows Godot style guide exactly |
| Godot Editor | 4.6 | File move operations | Only tool that preserves UID-based scene references during moves |
| git | Any | Version control safety net | Essential - formatting and moves can break references, need rollback capability |

### Installation

**gdformat (Python-based):**
```bash
pip3 install "gdtoolkit==4.*"
# or with pipx for isolated installation
pipx install "gdtoolkit==4.*"
```

**Verification:**
```bash
gdformat --version
```

## Architecture Patterns

### Recommended Project Structure

Godot 4 best practice favors **feature-based organization** over type-based for maintainability:

```
hammertime/
├── models/                 # Data classes (Item, Weapon, Armor, Hero, etc.)
│   ├── items/
│   │   ├── item.gd
│   │   ├── weapon.gd
│   │   ├── armor.gd
│   │   ├── helmet.gd
│   │   ├── boots.gd
│   │   └── ring.gd
│   ├── affixes/
│   │   ├── affix.gd
│   │   └── implicit.gd
│   ├── hero.gd
│   └── tag.gd
├── scenes/                 # Scene files and their view scripts
│   ├── main.tscn
│   ├── main_view.gd
│   ├── hero_view.tscn
│   ├── hero_view.gd
│   ├── gameplay_view.tscn
│   ├── gameplay_view.gd
│   ├── crafting_view.gd
│   ├── item_view.gd
│   └── node_2d.tscn
├── autoloads/              # Singleton scripts (autoload in project.godot)
│   ├── item_affixes.gd
│   └── tag.gd (if autoload, otherwise in models/)
├── utils/                  # Helper scripts, dev tools
│   └── (future utilities)
├── project.godot
├── export_presets.cfg
└── .editorconfig
```

**Rationale:** Feature-based keeps related files together, reduces cognitive load, scales better as projects grow.

### Pattern 1: File Naming Convention (Godot 4 Standard)

**What:** All files use snake_case naming, no PascalCase, no spaces
**When to use:** Always - required for cross-platform compatibility
**Why:** Windows/macOS use case-insensitive filesystems; Linux uses case-sensitive. Godot's PCK export is case-sensitive. Mixing cases causes runtime errors after export.

**Current issues in project:**
- `Tag.gd` → should be `tag.gd` (if not autoload) or `tag_list.gd`
- `Gameplay view.tscn` → should be `gameplay_view.tscn`
- `Hero view.tscn` → should be `hero_view.tscn`

**Example:**
```
WRONG: PlayerInventory.gd, Weapon System.tscn, Item-Factory.gd
RIGHT: player_inventory.gd, weapon_system.tscn, item_factory.gd
```

### Pattern 2: Return Type Hints on All Functions

**What:** Every function declares return type using `-> Type` syntax
**When to use:** Always - part of STYLE-03 requirement
**Example:**

```gdscript
# WRONG: No return type hint
func calculate_dps():
    return total_dps

# RIGHT: Explicit return type
func calculate_dps() -> float:
    return total_dps

# WRONG: Missing void annotation
func update_stats():
    calculate_dps()
    calculate_defense()

# RIGHT: Void explicitly declared
func update_stats() -> void:
    calculate_dps()
    calculate_defense()
```

**Benefits:**
- GDScript detects type errors without running code
- Better autocompletion in editor
- Self-documenting code
- Catches bugs at compile time

### Pattern 3: File Move Workflow (Godot Editor)

**What:** Step-by-step process for moving files safely
**When to use:** For ORG-02 and ORG-03 requirements (moving 21+ files)

**Workflow:**
1. **Before any moves:** Commit current state to git
2. **In Godot Editor FileSystem dock:** Right-click file → "Move/Rename"
3. **Select destination folder** in dialog
4. **Godot auto-updates:** Scene references via UID system
5. **Manual update required:**
   - Autoload paths in project.godot (string-based)
   - String literals in code (e.g., `load("res://item.gd")`)
6. **Test immediately:** Press F5 to launch game, verify no errors
7. **Commit if successful:** Lock in working state

**Never use:** Terminal commands like `mv`, `git mv`, or file manager - these bypass Godot's dependency tracking.

### Anti-Patterns to Avoid

- **Moving files outside Godot Editor:** Breaks UID references, desynchronizes cache, causes "missing dependencies" errors
- **Batch moving many files without testing:** Hard to debug which move broke references - move in small groups
- **Forgetting to commit .uid files:** UIDs work locally but break when project is cloned elsewhere
- **Renaming autoloads without updating project.godot:** Causes instant crash on launch with cryptic errors
- **Using PascalCase class_name with different filename:** `class_name PlayerInventory` in `player_inventory.gd` works, but `PlayerInventory.gd` violates Godot 4 convention

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Code formatting | Manual style enforcement | gdformat | Handles spacing, indentation, line breaking automatically; ensures consistency across 21 files |
| Dependency tracking during moves | Custom script to update paths | Godot Editor FileSystem dock | Built-in UID system tracks resources; custom solutions miss edge cases (scene inheritance, preloads) |
| Return type hint enforcement | Manual code review | gdformat + GDScript warnings | gdformat doesn't add type hints, but enabling warnings (`untyped_declaration`) flags missing hints |
| Snake_case validation | Linter rules | Manual review + bulk rename | No standard linter enforces filename casing; must verify manually or write custom EditorScript |

**Key insight:** Godot's editor tools are deeply integrated with the resource system (UID tracking, import system, autoload registry). Command-line alternatives can't replicate this integration safely. Trust the editor for file operations; use command-line tools only for content manipulation (formatting, linting).

## Common Pitfalls

### Pitfall 1: gdformat Breaking Exotic Syntax

**What goes wrong:** gdformat fails or produces invalid output on advanced GDScript patterns (e.g., variable definitions in match patterns)
**Why it happens:** gdformat's parser doesn't support 100% of GDScript syntax; edge cases exist
**How to avoid:**
- Run `gdformat --check .` first to identify problematic files
- Review formatted output before committing
- Use gdformatrc to exclude files if needed: `gdformat --dump-default-config > .gdformatrc`
**Warning signs:** Syntax errors after formatting, gdformat command exits with non-zero code

### Pitfall 2: Forgetting to Update project.godot After Moving Autoloads

**What goes wrong:** Game crashes on launch with "Cannot find autoload" error
**Why it happens:** Autoload paths in project.godot are string-based, not UID-tracked; Godot doesn't auto-update them
**How to avoid:**
1. Before moving autoload files: Note current paths in project.godot `[autoload]` section
2. After move: Open project.godot, update paths manually
3. Test immediately with F5
**Warning signs:** Error console shows "Failed to load autoload" on game start

**Current project autoloads (from project.godot):**
```ini
[autoload]
ItemAffixes="*res://item_affixes.gd"
Tag="*res://Tag.gd"
```

**After moving to autoloads/ folder, must update to:**
```ini
[autoload]
ItemAffixes="*res://autoloads/item_affixes.gd"
Tag="*res://autoloads/tag.gd"
```

### Pitfall 3: Case-Sensitivity Issues Hidden Until Export

**What goes wrong:** Game works in editor but breaks after export with "File not found" errors
**Why it happens:** Development often happens on case-insensitive filesystems (Windows/macOS), but Godot's PCK export is case-sensitive
**How to avoid:**
- Enforce snake_case for ALL files and folders from the start
- Test on Linux if possible (case-sensitive filesystem)
- Review export logs for path mismatches
**Warning signs:** Export succeeds but exported game fails to load resources

### Pitfall 4: Renaming Files Without Testing Between Changes

**What goes wrong:** After renaming multiple files, game won't launch; unclear which rename broke references
**Why it happens:** Scene files, preloads, and get_node() paths may reference old names; errors compound
**How to avoid:**
- Rename one file (or small group) at a time
- Press F5 after each rename to verify game still launches
- Commit working state before next rename
**Warning signs:** Cascade of "cannot load" errors in console

### Pitfall 5: Running gdformat Without Version Control

**What goes wrong:** gdformat modifies files in-place; if formatting breaks code, no way to recover original
**Why it happens:** gdformat is "uncompromising" - limited configuration, aggressive reformatting
**How to avoid:**
- **Always commit before running gdformat**
- Review changes with `git diff` before committing formatted code
- Use `gdformat --check .` first to preview what would change
**Warning signs:** Massive diff in git showing unexpected changes

## Code Examples

### Example 1: Running gdformat on Entire Project

```bash
# 1. Commit current state first
git add .
git commit -m "chore: save state before formatting"

# 2. Check what would change (dry run)
gdformat --check .

# 3. Format all .gd files
gdformat .

# 4. Review changes
git diff

# 5. If good, commit formatted code
git add .
git commit -m "style: format all GDScript with gdformat"

# 6. If bad, rollback
git restore .
```

### Example 2: Adding Return Type Hints (Manual)

**Before:**
```gdscript
# item.gd - missing return types
func display():
    print("\n----")
    print("name: %s" % self.item_name)

func get_display_text():
    var output = ""
    output += "----\n"
    return output

func is_affix_on_item(affix: Affix):
    for prefix in self.prefixes:
        if affix.affix_name == prefix.affix_name:
            return true
    return false
```

**After:**
```gdscript
# item.gd - with return types
func display() -> void:
    print("\n----")
    print("name: %s" % self.item_name)

func get_display_text() -> String:
    var output = ""
    output += "----\n"
    return output

func is_affix_on_item(affix: Affix) -> bool:
    for prefix in self.prefixes:
        if affix.affix_name == prefix.affix_name:
            return true
    return false
```

### Example 3: Moving Files in Godot Editor (Step-by-Step)

**Scenario:** Move `item.gd` from root to `models/items/`

1. **In Godot Editor:**
   - FileSystem dock → right-click `item.gd`
   - Select "Move/Rename..."
   - Navigate to `res://models/items/`
   - Click "Move"

2. **Godot auto-updates:**
   - Scene files referencing `item.gd` via UID (no action needed)
   - Preload statements using `const Item = preload("res://item.gd")` still work (UID system)

3. **Manual updates needed:**
   - Check for string-based loads: `load("res://item.gd")` → `load("res://models/items/item.gd")`
   - If Item is autoloaded: Update project.godot path

4. **Test:**
   - Press F5
   - Verify game launches
   - Test item creation/equipping

5. **Commit:**
   ```bash
   git add .
   git commit -m "refactor: move item.gd to models/items/"
   ```

### Example 4: Renaming Files to snake_case

**Scenario:** Rename `Tag.gd` → `tag.gd`

**In Godot Editor:**
1. Right-click `Tag.gd` → "Move/Rename..."
2. Change name to `tag.gd` (same folder)
3. Click "Rename"

**Update autoload in project.godot:**
```ini
# Before
Tag="*res://Tag.gd"

# After
Tag="*res://tag.gd"
```

**Note:** The autoload name can stay `Tag` (PascalCase) - it's accessed as `Tag.PHYSICAL` in code. Only the filename must be snake_case.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| PascalCase filenames (Godot 3 era) | snake_case filenames | Godot 4.0 style guide | Cross-platform compatibility, official recommendation |
| Manual path updates after moves | UID-based references | Godot 4.0 (expanded in 4.4) | Files can be moved safely; editor auto-updates scene references |
| Separate .import files for UIDs | Dedicated .uid files | Godot 4.4 | Scripts and shaders now benefit from UID system (previously only resources) |
| gdformat 3.x (Godot 3) | gdformat 4.x | gdtoolkit 4.0 release | Parser updated for Godot 4 syntax (typed arrays, new keywords) |

**Deprecated/outdated:**
- **PascalCase file naming:** Still works but violates Godot 4 style guide; causes issues on case-sensitive filesystems
- **gdtoolkit 3.x:** Only supports Godot 3 syntax; will fail on Godot 4 code (e.g., `Array[Type]` syntax)
- **Moving files via OS file manager:** Pre-Godot 4, this was fragile; Godot 4's UID system makes editor-based moves much safer, but bypassing editor still dangerous

## Open Questions

1. **Should autoload scripts stay in root or move to autoloads/ folder?**
   - What we know: Either works; moving requires updating project.godot paths
   - What's unclear: Project-specific preference - does user want all autoloads grouped or distributed by feature?
   - Recommendation: Move to autoloads/ for consistency with feature-based structure, but flag as user decision

2. **How to handle class_name declarations after renaming files?**
   - What we know: `class_name Tag_List` in `tag.gd` is valid; class name and filename can differ
   - What's unclear: Should class_name be updated to match filename? (e.g., `class_name Tag_List` vs `class_name TagList`)
   - Recommendation: Keep existing class_name unless user prefers alignment; Godot doesn't enforce matching

3. **What's the boundary between models/ and scenes/?**
   - What we know: Models = data classes; Scenes = nodes with scene files
   - What's unclear: Item hierarchy extends Node, not Resource - are they models or scenes?
   - Recommendation: Current Item classes are data-focused despite extending Node; Phase 2 migrates to Resource, so treat as models now

## Sources

### Primary (HIGH confidence)

- [Official Godot 4 GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html) - Naming conventions, code style
- [Godot 4 Project Organization Best Practices](https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html) - Folder structure recommendations
- [gdformat Documentation (Scony/godot-gdscript-toolkit)](https://github.com/Scony/godot-gdscript-toolkit/wiki/4.-Formatter) - Installation, usage, configuration
- [Godot 4 FileSystem Documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/filesystem.html) - UID system, file references
- [UID Changes Coming to Godot 4.4](https://godotengine.org/article/uid-changes-coming-to-godot-4-4/) - UID system evolution

### Secondary (MEDIUM confidence)

- [GDQuest GDScript Formatter Tutorial](https://www.gdquest.com/tutorial/godot/gdscript/gdscript-formatter/) - Practical gdformat usage
- [GDQuest Godot GDScript Guidelines](https://gdquest.gitbook.io/gdquests-guidelines/godot-gdscript-guidelines) - Community best practices
- [Using Type Hints with Godot's GDScript (GDQuest)](https://www.gdquest.com/tutorial/godot/gdscript/typed-gdscript/) - Return type hints
- [GitHub: godot-architecture-organization-advice](https://github.com/abmarnie/godot-architecture-organization-advice) - Architecture patterns
- [Godot 4 Command Line Tutorial](https://docs.godotengine.org/en/4.4/tutorials/editor/command_line_tutorial.html) - Testing and headless mode

### Tertiary (LOW confidence - community discussions)

- [Forum: Folder structure for large game in Godot 4.5](https://forum.godotengine.org/t/folder-structure-for-large-game-in-godot-4-5/119115) - Anecdotal structure advice
- [Forum: Should I use PascalCase or snake_case for folders?](https://forum.godotengine.org/t/should-i-use-pascalcase-or-snake-case-for-folders-in-my-project/12496) - Community debate
- [GitHub Issue: Moving files doesn't remap paths #14900](https://github.com/godotengine/godot/issues/14900) - Historical context

## Metadata

**Confidence breakdown:**
- **Standard stack:** HIGH - gdformat and Godot Editor are officially documented, widely used
- **Architecture:** HIGH - Godot 4 docs explicitly recommend snake_case and feature-based structure
- **Pitfalls:** MEDIUM-HIGH - Based on official docs (autoload updates, UID system) and verified community reports (formatting issues, case sensitivity)
- **File move workflow:** HIGH - UID system behavior documented in Godot 4.4+ articles and official docs

**Research date:** 2026-02-14
**Valid until:** March 2026 (30 days) - Stable domain; Godot 4.6 unlikely to change core file system or style guide before next major version

**Notes for planner:**
- Current project has 21 .gd files in root, 4 .tscn files (1 with space in name)
- Files already use class_name declarations; no changes needed there
- Autoloads defined: ItemAffixes, Tag - both need path updates after move
- Return type hints partially present (hero.gd has many, item.gd missing some)
- gdformat not yet installed - plan must include installation step
- No existing folder structure - models/, scenes/, autoloads/ must be created
