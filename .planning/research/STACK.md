# Stack Research

**Domain:** Godot 4.5 ARPG Project Organization & Code Refactoring
**Researched:** 2026-02-14
**Confidence:** HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Godot Engine | 4.5 | Game engine | Already validated. Scene-based architecture encourages modular organization. Built-in refactoring tools (move/rename) maintain reference integrity. |
| GDScript | 4.5 | Primary language | First-class Godot language with static typing support. Official style guide well-documented. Gradual typing allows incremental refactoring. |
| .tres format | N/A | Development resources | Text-based format enables version control diffs. Auto-converts to binary .res on export. Essential for tracking resource changes during refactoring. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| godot-gdscript-toolkit | 4.2.2+ | Linting and formatting | Install via pip (`pip install gdtoolkit`). Use `gdlint` for style enforcement, `gdformat` for auto-formatting during refactor. |
| GDScript Formatter (GDQuest) | Latest | Fast code formatting | Alternative to gdformat. Rust-based, formats in milliseconds. Available as Godot 4 addon or standalone binary. Better for large codebases. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| gdlint | Style guide enforcement | Enforces official GDScript style guide. Configurable via `gdlint:ignore` comments. Catches naming violations before commit. |
| gdformat | Code auto-formatting | Reorders code sections automatically (signals → enums → variables → functions). Uncompromising formatter reduces bike-shedding. |
| Godot Editor File Operations | Safe refactoring | CRITICAL: Always move/rename files in editor, never via filesystem. Editor updates .tscn references automatically. Breaking this causes broken scenes. |

## Installation

```bash
# GDScript Toolkit (recommended for command-line workflow)
pip install gdtoolkit

# Check installation
gdlint --version
gdformat --version

# Format single file
gdformat path/to/script.gd

# Lint entire project
gdlint --recursive ./

# GDScript Formatter (alternative, faster for large projects)
# Download from: https://github.com/GDQuest/GDScript-formatter
# Or install as Godot addon from Asset Library
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| gdformat (Python) | GDScript Formatter (Rust) | Use Rust version when formatting speed matters (format-on-save, 100+ files). Both enforce official style guide identically. |
| snake_case files | PascalCase files | NEVER in Godot 4. Godot 3 used PascalCase; Godot 4 convention changed to snake_case. Only C# scripts use PascalCase. |
| Folder-per-feature | Folder-per-type | Use type-based folders (scripts/, scenes/, assets/) only for very small projects (<10 scenes). Feature-based scales better. |
| .tres resources | .res resources | NEVER use .res during development. Binary format breaks version control diffs. Godot auto-converts .tres → .res on export. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Files in project root | Creates clutter. Currently 21 .gd files flat in root. Hard to navigate in 6 months. | Feature-based folders: `items/`, `ui/`, `autoloads/`, `data/` |
| Spaces in file names | "Gameplay view.tscn" causes CLI issues, shell escaping problems. Cross-platform fragility. | Underscores: `gameplay_view.tscn` |
| Manual file moving | Breaks scene references. Godot uses absolute res:// paths internally. Filesystem moves don't update .tscn files. | Always use Godot editor's Move/Rename tools |
| Mixed PascalCase/snake_case | "Tag.gd" vs "item_affixes.gd". Inconsistent casing harder to remember. | Enforce snake_case everywhere except C# scripts |
| String typing where possible | `var item = get_item()` loses type information for autocomplete. | `var item := get_item()` or `var item: Item = get_item()` |

## Stack Patterns by Variant

**For refactoring existing code:**
- Start with non-breaking changes: run `gdformat` on all files, commit
- Organize files into folders: use editor's "Move To" feature per file
- Rename files to snake_case: editor updates all .tscn references automatically
- Add type hints incrementally: new code first, then refactor hot paths

**For static typing adoption:**
- Use type inference (`:=`) where right-hand side is obvious: `var speed := 5.0`
- Explicit types when method returns Variant or unclear: `var data: Dictionary = parse_json()`
- Add return type annotations to all functions: `func get_item() -> Item:`
- Enable "Untyped Declaration" warning in Project Settings → Editor → GDScript

**For folder organization (small project <50 scripts):**
```
res://
├── autoloads/         # Global services (Tag, ItemAffixes)
├── items/             # Item classes and item-related logic
│   ├── base/          # Base classes (item.gd, weapon.gd, armor.gd)
│   ├── weapons/       # Weapon implementations (light_sword.gd)
│   ├── armor/         # Armor implementations (basic_armor.gd)
│   └── accessories/   # Rings, amulets
├── ui/                # UI scenes and scripts
│   ├── hero_view/     # Hero screen (hero_view.tscn, hero_view.gd)
│   ├── crafting_view/ # Crafting screen
│   └── gameplay_view/ # Gameplay screen
├── data/              # Data-only scripts (affix.gd, implicit.gd)
├── scenes/            # Top-level scenes (main.tscn)
└── assets/            # Art, audio (if any)
```

**For folder organization (large project >50 scripts):**
```
res://
├── autoloads/
├── core/              # Core systems
│   ├── items/         # Item system
│   ├── combat/        # Combat calculations
│   └── progression/   # Hero leveling, area difficulty
├── features/          # Feature-complete modules
│   ├── hero/          # Hero feature (UI + logic)
│   │   ├── hero_view.tscn
│   │   ├── hero_view.gd
│   │   └── hero.gd
│   ├── crafting/      # Crafting feature
│   └── gameplay/      # Gameplay loop feature
├── shared/            # Shared utilities
│   ├── ui/            # Reusable UI components
│   └── utils/         # Helper functions
└── scenes/            # Application entry points
    └── main.tscn
```

## Version Compatibility

| Tool | Godot Version | Notes |
|------|---------------|-------|
| godot-gdscript-toolkit 4.2.2+ | Godot 4.0+ | Parses Godot 4 GDScript syntax. NOT compatible with Godot 3. |
| GDScript Formatter (Rust) | Godot 4.0+ | Godot 4-specific. Separate version exists for Godot 3. |
| Static typing with `:=` | Godot 3.1+ | Type inference added in 3.1, improved in 4.0. |
| Editor Move/Rename tools | All versions | Works in Godot 3 and 4, but Godot 4 has better UX. |

## Current Project Assessment

**Existing state (needs refactoring):**
- ✗ 21 .gd files flat in project root → organize by feature
- ✗ Scene files with spaces: "Gameplay view.tscn" → rename to snake_case
- ✗ Mixed casing: "Tag.gd" vs "item_affixes.gd" → enforce snake_case
- ✗ No linting/formatting configured → add gdformat
- ✗ Inconsistent type hints → add gradually
- ✓ Using .tscn (text scenes) for version control (correct)
- ✓ Limited autoloads (Tag, ItemAffixes) for read-only data (correct)
- ✓ Godot 4.5 with Mobile renderer (validated stack)

**Recommended refactoring order:**
1. **Format all code** (low risk): Run `gdformat` on all .gd files, commit
2. **Rename scene files** (low risk): Remove spaces, use snake_case
3. **Create folder structure** (medium risk): Move files via editor
4. **Rename script files** (medium risk): Update to snake_case convention
5. **Add type hints** (low risk): Gradual, start with return types
6. **Refactor Node items to Resources** (high risk): Defer to future milestone

**Good decisions to keep:**
- Autoloads limited to read-only services (Tag for enums, ItemAffixes for data lookup)
- Text-based scenes (.tscn) and resources (.tres) for version control
- GDScript-only (no C# mixing reduces complexity for first Godot project)

## Migration Paths

### From Flat Root to Organized Folders

**Phase 1: Prepare** (prevents breakage)
1. Commit current working state
2. Close all open scenes in editor
3. Ensure no external file editors are watching project

**Phase 2: Create Structure** (safe operations)
```bash
# Create folders in Godot editor's FileSystem dock
# Right-click → New Folder
autoloads/
items/
  base/
  weapons/
  armor/
  accessories/
ui/
  hero_view/
  crafting_view/
  gameplay_view/
data/
scenes/
```

**Phase 3: Move Files** (ONLY via Godot editor)
1. Right-click file → "Move To"
2. Select destination folder
3. Confirm (editor updates all references)
4. Verify no broken dependencies (check Output panel for errors)

**Phase 4: Rename Files** (ONLY via Godot editor)
1. Right-click "Gameplay view.tscn" → Rename → "gameplay_view.tscn"
2. Right-click "Tag.gd" → Rename → "tag.gd"
3. Update project.godot autoload paths manually:
```gdscript
# Before
ItemAffixes="*res://item_affixes.gd"
Tag="*res://Tag.gd"

# After
ItemAffixes="*res://autoloads/item_affixes.gd"
Tag="*res://autoloads/tag.gd"
```

**Phase 5: Verify**
1. Run game (F5)
2. Test all three views (Hero, Crafting, Gameplay)
3. Check for "Resource not found" errors in Output
4. Commit if successful

### From No Types to Typed GDScript

**Strategy: Gradual, non-breaking adoption**

1. **Enable warnings** (no code changes yet)
```gdscript
# Project → Project Settings → Debug → GDScript
# Enable: UNTYPED_DECLARATION, UNSAFE_METHOD_ACCESS
```

2. **Add return types** (low risk, high value)
```gdscript
# Before
func get_max_prefixes():
    return 3

# After
func get_max_prefixes() -> int:
    return 3
```

3. **Use type inference** (quick wins)
```gdscript
# Before
var speed = 5.0
var items = []

# After
var speed := 5.0
var items: Array[Item] = []
```

4. **Add parameter types** (catches bugs)
```gdscript
# Before
func add_prefix(affix):
    prefixes.append(affix)

# After
func add_prefix(affix: Affix) -> void:
    prefixes.append(affix)
```

5. **Type exported variables** (better inspector UX)
```gdscript
# Before
@export var max_health = 100

# After
@export var max_health: int = 100
```

## Architectural Decisions

### Why Feature-Based Folders?

**Problem:** Type-based folders (scripts/, scenes/, resources/) create split-brain:
- To understand "Hero" feature, must open scripts/hero_view.gd AND scenes/hero_view.tscn AND resources/hero_stats.tres
- Files related to one feature scattered across 3+ folders
- Hard to delete features cleanly (files left behind in multiple folders)

**Solution:** Co-locate related files in feature folders:
```
ui/hero_view/
├── hero_view.tscn      # Scene
├── hero_view.gd        # Script attached to scene
└── hero_portrait.png   # Exclusive asset
```

**Benefits:**
- One folder contains everything for one feature
- Delete folder = delete entire feature
- Easier to reason about scope and dependencies
- Aligns with Godot's scene-as-composition philosophy

### Why snake_case for Files?

**Official Godot 4 convention changed from Godot 3:**
- Godot 3: PascalCase files (Enemy.gd, PlayerController.gd)
- Godot 4: snake_case files (enemy.gd, player_controller.gd)

**Rationale:**
- GDScript uses snake_case for functions/variables (Python-inspired)
- C++ core uses snake_case for file names
- Cross-platform: some filesystems are case-insensitive (macOS/Windows)
- Consistency: match function_name style with file_name style

**Exception:** C# scripts use PascalCase (Enemy.cs) to follow .NET conventions

### Why Limit Autoloads?

**Current autoloads:**
- `Tag.gd` - Enum definitions (read-only) ✓
- `ItemAffixes.gd` - Affix data lookup (read-only) ✓

**Good use cases for autoloads:**
- Read-only data (constants, enums, lookup tables)
- Stateless services (logging, analytics)
- Truly global services (audio manager, save system)

**Bad use cases (avoid):**
- Game state (player inventory, current area) → belongs in scene tree
- Mutable shared data → creates hidden dependencies, hard to debug
- "Convenience" singletons → lazy design, couples code tightly

**Why current autoloads are correct:**
- Tag.gd is pure enum definitions (no state)
- ItemAffixes.gd is read-only data provider (loads once, queries many times)
- Neither creates hidden mutation or state management issues

## Sources

- [Project organization — Godot Engine (4.5) documentation](https://docs.godotengine.org/en/4.5/tutorials/best_practices/project_organization.html) — Official folder structure conventions (HIGH confidence)
- [GDScript style guide — Godot Engine (stable) documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html) — Official naming and formatting rules (HIGH confidence)
- [Scene organization — Godot Engine (stable) documentation](https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html) — Architecture patterns (HIGH confidence)
- [Autoloads versus internal nodes — Godot Engine (stable) documentation](https://docs.godotengine.org/en/stable/tutorials/best_practices/autoloads_versus_internal_nodes.html) — When to use autoloads (HIGH confidence)
- [Static typing in GDScript — Godot Engine (stable) documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html) — Type system conventions (HIGH confidence)
- [GDQuest GDScript Guidelines](https://gdquest.gitbook.io/gdquests-guidelines/godot-gdscript-guidelines) — Community best practices, file organization (MEDIUM confidence)
- [godot-gdscript-toolkit on GitHub](https://github.com/Scony/godot-gdscript-toolkit) — gdlint and gdformat tool documentation (HIGH confidence)
- [GDScript Formatter by GDQuest](https://github.com/GDQuest/GDScript-formatter) — Alternative fast formatter (HIGH confidence)
- [Godot Forum: tres vs res file format](https://forum.godotengine.org/t/fileformat-differences-tres-res-scn-material-etc/80006) — Community explanation (MEDIUM confidence)
- [Godot Forum: Folder structure for large game](https://forum.godotengine.org/t/folder-structure-for-large-game-in-godot-4-5/119115) — Real-world patterns (LOW confidence)

---
*Stack research for: Hammertime ARPG - Code Organization & Refactoring*
*Researched: 2026-02-14*
*Confidence: HIGH — All core recommendations from Godot 4.5 official documentation*
