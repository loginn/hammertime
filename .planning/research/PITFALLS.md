# Pitfalls Research

**Domain:** Godot 4.5 ARPG Refactoring
**Researched:** 2026-02-14
**Confidence:** HIGH

## Critical Pitfalls

Mistakes that cause rewrites or major issues during refactoring.

### Pitfall 1: Moving Files Breaks Scene References and UIDs

**What goes wrong:**
Moving .gd or .tscn files to new folders causes all path-based references to break. Scene instances, preload() calls, and get_node() paths all fail silently or throw errors. The game appears to load but scripts don't attach, nodes are missing, or scenes fail to instantiate.

**Why it happens:**
Godot 4.x uses both UIDs and file paths for references. While UIDs were introduced in Godot 4.0, support wasn't completely finished — many file types don't benefit from the UID system entirely. When moving files outside the editor, .uid files don't move with scripts, breaking references. Even moving within the editor can cause cache desynchronization in Godot 4.2-4.5.

**Consequences:**
- Broken scene references ("Can't load script" errors)
- Missing node attachments in scenes
- "Invalid UID, using text path instead" warnings in console
- Scenes load but script logic doesn't execute
- Hours debugging "why did this stop working?"
- Potential data loss if changes not caught before commit

**Prevention:**
- **ALWAYS move files using Godot editor's FileSystem dock** (right-click → Move To / Rename), never via external file manager
- After moving files in Godot 4.4+, re-save all affected scenes to regenerate UID references
- When moving files externally (git operations), move .uid files alongside .gd files
- Before major reorganization, commit to git so you can restore if references break
- Test immediately after each file move — don't move multiple files then test
- Use "Find in Files" to search for old paths before assuming move succeeded
- Close external editors before refactoring to prevent auto-save conflicts

**Detection:**
- "Invalid UID, using text path instead" warnings in console
- Output panel shows "Resource not found: res://old_path.gd" errors
- Scenes show missing script icon (red broken script icon in scene tree)
- Nodes appear in tree but properties are missing
- "Cannot preload resource" errors
- Run scene (F5) and check for immediate errors

**Phase to address:**
Phase 1: Project Structure Setup — establish folder structure BEFORE writing new code, move all files once, verify, then continue.

---

### Pitfall 2: Renaming Classes Breaks class_name and preload() References

**What goes wrong:**
Renaming a script that uses class_name causes "Could not resolve script" errors. All preload("res://old_name.gd") statements break. Autoloads fail to load. The project requires full reload to detect changes, and even then references may stay broken.

**Why it happens:**
GDScript's class_name creates a global identifier that other scripts reference. Renaming the file doesn't update these references automatically. **Godot 4.5 changed autoload behavior** — script files are no longer automatically renamed to PascalCase, creating mismatches between expected and actual class names. preload() uses compile-time path resolution, so renaming requires manual updates across all files.

**Consequences:**
- "Class X not found" errors
- Type hints showing as invalid in editor
- Autoload singleton returns null
- "Identifier not declared in current scope" for previously working class names
- Game won't start ("Autoload 'Tag' could not be loaded")

**Prevention:**
- **Search entire project** for class name before renaming: "Find in Files" for old class name
- Update all class_name declarations, preload() calls, and type hints in order
- For autoloads in Godot 4.5+, verify the actual file naming matches expected class name
- Check Project → Project Settings → Autoload after renaming any autoload file
- Prefer @export var references over preload() where possible — they don't break on rename
- Use class_name only for types that truly need global access
- Consider not using class_name for small, internal classes
- Run game (F5) immediately after renaming autoloads to catch early

**Detection:**
- "Class X not found" errors
- Type hints showing as invalid in editor
- Autoload singleton returns null
- "Identifier not declared in current scope" for previously working class names
- Black screen / game doesn't initialize
- Output panel shows resource loading errors for autoloads

**Phase to address:**
Phase 2: Data Model Migration — when creating new Resource-based classes, establish naming conventions and avoid mid-phase renames.

---

### Pitfall 3: get_node() Paths Break When Restructuring Scene Hierarchy

**What goes wrong:**
Hardcoded get_node() paths like `get_node("../HeroView")` or `$"../../ButtonControl/ImplicitHammer"` break when scene structure changes. The code worked before refactoring, now nodes are null and features stop working. **Current codebase uses extensive get_node() with relative paths** (see crafting_view.gd lines 26, 34-36, 38-54).

**Why it happens:**
Node paths are position-dependent. Moving nodes to different parents, renaming nodes, or changing hierarchy depth invalidates all relative paths. Godot has no automatic refactoring for node paths. The distinction between absolute and relative paths isn't obvious.

**Consequences:**
- "Node not found" errors after scene restructuring
- Null reference errors in previously working code
- Features work in one scene configuration but break when duplicated
- Error messages mention node paths with multiple `../` segments
- NullReferenceException spam in Output panel

**Prevention:**
- **Replace relative paths with @export NodePath variables** — they update automatically when nodes move/rename in scene tree
- Use unique names with %NodeName syntax (less brittle than paths, though still breaks on rename)
- Prefer signal connections over direct node references
- Use groups for finding related nodes: `get_tree().get_nodes_in_group("crafting_buttons")`
- When get_node() is necessary, add null checks: `get_node_or_null()` with fallback logic
- Use @onready for internal children: `@onready var stats_label = $StatsLabel`
- Document which scripts reference which node paths
- Search codebase for `$NodeName` references when renaming nodes

**Detection:**
- "Node not found" errors after scene restructuring
- Null reference errors in previously working code
- Features work in one scene configuration but break when duplicated
- Error messages mention node paths with multiple `../` segments

**Phase to address:**
Phase 3: Decouple Views — when separating UI logic, establish signal-based communication patterns BEFORE moving nodes.

---

### Pitfall 4: Extending Node for Data Objects (Current Anti-Pattern)

**What goes wrong:**
Data classes extend Node when they should extend Resource. **Every Item, Affix, Weapon, Ring in current codebase is a Node** (`class_name Item extends Node`). This adds unnecessary scene tree overhead, prevents proper serialization, makes data non-portable, and confuses "is this logic or data?"

**Why it happens:**
First-time Godot users assume "everything extends Node" because scene nodes do. The distinction between Node (logic, scene tree) and Resource (data, serializable) isn't obvious. Copy-paste from examples that use Nodes.

**Consequences:**
- High memory usage, slow scene instantiation (100+ items in scene tree)
- Can't save/load game state properly (.tres files can't be created)
- Data stored in autoloads instead of .tres files
- Difficulty serializing inventory/equipment state
- Confusion about lifecycle (_ready() called on data objects?)
- Can't edit item stats in inspector as resources

**Prevention:**
- **Use Resource for data-only classes**: stats, configurations, item definitions
- Use Node for logic that participates in scene tree: UI controllers, game managers
- Resource advantages: automatic serialization, .tres files, inspector editing, no _ready() confusion
- **Migration path**: Create parallel Resource classes, test, then replace Node versions (don't change in place)
- Resources can't have _process() or children — if you need that, it's logic, not data
- Create ItemData extends Resource first, keep Item extends Node wrapper temporarily
- Gradually migrate code to use ItemData, remove Node wrapper only after all references updated

**Detection:**
- Data classes with no _ready(), _process(), or children
- Classes that never add_child() or get added to scene tree
- Data stored in autoloads instead of .tres files
- Difficulty saving/loading game state

**Phase to address:**
Phase 2: Data Model Migration — critical foundation. Must happen before logic refactoring. Do this migration in its own branch/milestone, not during other refactoring.

---

### Pitfall 5: Duplicated Logic Across Similar Classes

**What goes wrong:**
**weapon.gd and ring.gd both have compute_dps() with different implementations** (lines 18-64 in weapon.gd vs. 13-35 in ring.gd). Fixing bugs requires updating multiple files. Critical strike calculation differs between them. Adding new damage types requires editing both.

**Why it happens:**
Copy-paste development. Each item type started as a copy of another. No shared interface or composition pattern. Flat file structure makes duplication easy — everything's in root, grab any file as template.

**Consequences:**
- Bug fixes multiply across files
- Inconsistent behavior between similar items (weapon vs ring crit calculation)
- Adding new damage types requires editing 2+ files
- Can't reuse damage calculation logic
- Testing requires checking multiple implementations

**Prevention:**
- **Extract shared behavior into composition components** (DamageCalculator, AffixProcessor)
- Create interface/contract for items that deal damage
- Use inheritance only for "is-a" relationships, composition for "has-a"
- When copying code, immediately ask "can this be shared?"
- Single source of truth for game formulas

**Detection:**
- Similar method names across multiple classes (compute_dps appears in 2+ files)
- Bug fixes that need to be applied to multiple files
- Inconsistent behavior between similar items (weapon vs ring crit calculation)
- Comments like "// Same as weapon but for rings"

**Phase to address:**
Phase 4: Shared Systems — after data model is stable, extract calculation logic into reusable systems.

---

### Pitfall 6: Refactoring Too Much At Once

**What goes wrong:**
Attempting to "fix everything" in one big rewrite: move all files, rename all classes, change data model, restructure scenes, add new patterns. Something breaks. Now debugging a maze of simultaneous changes with no way to isolate the cause. Game stops working. Can't identify which change broke what.

**Why it happens:**
Excitement about "doing it right." Seeing all the problems at once makes incremental improvement feel too slow. Underestimating complexity of refactoring in Godot (no automated refactoring tools). Not having tests to catch regressions.

**Consequences:**
- Can't identify which change broke what
- Multiple hours of refactoring without working game state
- Git diff showing changes in 10+ files
- Can't remember what worked before current session
- Fixing one bug reveals three more
- Temptation to "start over" instead of debugging
- May need to revert entire session's work

**Prevention:**
- **One refactor per commit**: move files OR rename classes OR restructure data, never all three
- Test after each change before proceeding (press F5, takes 5 seconds)
- Keep game running after every step
- Use git branches for experiments
- Write tests before refactoring (GUT or GdUnit4)
- **Incremental pattern**: choose one behavior → write test → refactor → verify → next behavior
- When stuck, revert and try smaller step
- Small commits throughout refactoring

**Detection:**
- Multiple hours of refactoring without testing
- Git diff showing changes in 10+ files
- Can't remember what worked before current session
- Fixing one bug reveals three more
- Temptation to "start over" instead of debugging

**Phase to address:**
Meta-phase guidance — applies to ALL phases. Each phase should enforce incremental changes.

---

### Pitfall 7: Signal Spaghetti Replacing get_node() Spaghetti

**What goes wrong:**
Attempting to "fix tight coupling" by connecting signals everywhere. Now tracking signal flow requires opening 3-4 files. Signals bubble through multiple layers (child emits → parent re-emits → grandparent re-emits). Debugging which connection fired is harder than tracing get_node() calls.

**Why it happens:**
Overreaction to "direct references are bad" advice. Misunderstanding when signals help vs. when they add complexity. No clear signal architecture. Every communication becomes a signal because "signals are the Godot way." Thinking signals are always better than direct calls.

**Consequences:**
- Debugging becomes harder (can't cmd+click to signal handlers)
- Execution order unclear (signal handlers run in connection order)
- More verbose code for no benefit
- "Signal already connected" errors if not careful
- Multiple unintended side effects from one signal emission
- Spending more time in debugger than editor
- "Why isn't this signal firing?" questions

**Prevention:**
- **Signals for events, references for structure**: Use signals for one-time events (`took_damage`, `item_finished`), direct references for stable relationships
- Use direct calls for parent → child communication (`$ChildNode.do_thing()`)
- Use signals for child → parent communication (`signal thing_done`)
- Use signals for distant/cross-scene communication (event bus)
- **Avoid signal bubbling** — don't re-emit child signals through multiple parent layers
- Use @export for stable parent-child references instead of signals
- Consider global Events singleton for truly cross-tree communication
- Limit connections per signal to 1-2 listeners
- Keep signal scope minimal (connect in same script when possible)
- Document signal flow in comments: "emits → CraftingView.on_item_crafted → HeroView updates"

**Detection:**
- Signals connected in 3+ places for single event
- Parent nodes with multiple `child.signal.connect(func(): parent_signal.emit())` patterns
- Difficulty answering "what happens when I press this button?"
- grep-ing for signal name shows 10+ connection points
- "This signal should fire but isn't" debugging sessions

**Phase to address:**
Phase 3: Decouple Views — when establishing communication patterns between views, define signal policy.

---

### Pitfall 8: Over-Engineering a Simple Idle Game

**What goes wrong:**
Implementing complex architecture patterns unnecessary for idle game scope: elaborate state machines, ECS architecture, extensive abstraction layers, plugin systems. Development slows to crawl. Simple features require touching 5 classes. Code harder to understand than before.

**Why it happens:**
Applying patterns from large-scale game development to small project. Following "best practices" without considering context. Excitement about learning new patterns. First project over-engineering (learning experience).

**Consequences:**
- More architecture code than game code
- Can't explain system without drawing diagrams
- New team member (or future you) can't understand code flow
- "Just" adding a stat takes 3+ file changes
- Documentation needed to explain how to add basic features
- Development velocity drops

**Prevention:**
- **Prefer clarity over cleverness** — if a simple solution works, use it
- Ask "does this complexity solve a problem we have?" before adding abstraction
- YAGNI (You Aren't Gonna Need It) — don't build for hypothetical future features
- For idle game scope: direct references often fine, simple inheritance sufficient, flat structures acceptable
- Save complex patterns for when pain is obvious (100+ items? then abstraction helps)
- Incremental complexity: start simple, add patterns when pain emerges

**Detection:**
- More architecture code than game code
- Can't explain system without drawing diagrams
- New team member (or future you) can't understand code flow
- "Just" adding a stat takes 3+ file changes
- Documentation needed to explain how to add basic features

**Phase to address:**
Phase 1: Project Structure Setup — set scope boundaries and complexity budget at start.

---

### Pitfall 9: Breaking Scene Inheritance Chains

**What goes wrong:**
Moving a parent scene but not child scenes, or vice versa, creates broken inheritance chains. If `item.tscn` extends `base_item.tscn` and you move only one, the parent reference breaks.

**Why it happens:**
Not understanding Godot's scene inheritance system. Thinking files are independent when they have parent-child relationships.

**Consequences:**
- Child scenes lose inherited properties
- "Resource not found" cascade errors
- Have to manually reconnect scene inheritance
- Data in child scenes may be reset to defaults
- Properties show default values instead of inherited values

**Prevention:**
- Before moving files, check Dependencies tab in Godot Editor (right-click file → Show in File System → Dependencies)
- Move related scenes together (parent and all children)
- Test each moved scene individually (double-click to open, verify no errors)
- Keep a backup commit before major reorganization
- Understand local vs inherited properties, make changes in base scene

**Detection:**
- Scene opens but shows "Couldn't load resource" warnings
- Properties show default values instead of inherited values
- Inspector shows broken scene inheritance icon

**Phase to address:**
Phase 1: Project Structure Setup — verify scene relationships before moving files.

---

## Moderate Pitfalls

### Pitfall 10: Circular Dependencies Between Scenes

**What goes wrong:**
HeroView needs CraftingView reference, CraftingView needs HeroView reference → circular dependency, can't instantiate either. **Current codebase has this**: crafting_view.gd lines 34-36 gets HeroView reference, and they communicate bidirectionally.

**Why it happens:**
Siblings trying to communicate directly without going through parent coordinator.

**Prevention:**
Use event bus or parent scene to coordinate. Siblings shouldn't reference each other directly. Use signals to parent, parent calls methods on siblings.

### Pitfall 11: Inconsistent snake_case Adoption

**What goes wrong:**
Partially converting to snake_case ("fixed 10 files, will do rest later") creates inconsistent codebase harder to navigate than original.

**Prevention:**
Use gdformat on ALL files at once. Commit as single "standardize formatting" change. Don't do piecemeal. Accept gdformat is "uncompromising formatter" (like Black for Python).

### Pitfall 12: Adding Type Hints That Break Duck Typing

**What goes wrong:**
`func process_item(item: Weapon)` breaks when you later need to pass Armor. Overly specific types reduce flexibility.

**Prevention:**
Use base class types (`item: Item`) or interfaces where possible. Only specify concrete types when truly required. Start with base class types, narrow only when needed.

### Pitfall 13: Not Testing After Each Refactor Step

**What goes wrong:**
Make 5 changes, game breaks, don't know which change caused it.

**Prevention:**
Test game after EACH file move, rename, or structural change. Takes 5 seconds to press F5. Saves hours of debugging. Read Output panel after every refactor step.

### Pitfall 14: Forgetting to Update UI Node Paths

**What goes wrong:**
Refactor renames `$StatsLabel` to `$CharacterStats/StatsLabel`. Code still references `$StatsLabel` → null reference error.

**Prevention:**
Use @onready variables (`@onready var stats_label = $StatsLabel`). When refactoring UI, search codebase for `$StatsLabel` references.

### Pitfall 15: Breaking Relative Scene Paths

**What goes wrong:**
Scene A references "../textures/sprite.png". Move Scene A to new folder, relative path breaks.

**Prevention:**
Use `res://` absolute paths for all resources. Relative paths are fragile.

---

## Minor Pitfalls

### Pitfall 16: Overusing @export for Internal References

**What goes wrong:**
`@export var damage_label: Label` exposes internal UI structure in inspector, inviting manual misconfiguration.

**Prevention:**
Use @export only for cross-scene references. Use @onready for internal children: `@onready var damage_label = $DamageLabel`.

### Pitfall 17: Not Committing Before Refactoring

**What goes wrong:**
Break something during refactoring, can't easily revert.

**Prevention:**
Commit working state before starting any refactoring session. Small commits throughout refactoring.

### Pitfall 18: Assuming gdformat Preserves All Formatting

**What goes wrong:**
gdformat reorders code sections (signals, then enums, then vars, then functions). Custom organization lost.

**Prevention:**
Understand gdformat is "uncompromising formatter" (like Black for Python). Accept its ordering or don't use it.

### Pitfall 19: Not Reading Editor Output Panel

**What goes wrong:**
Make change, game "seems fine", but Output panel shows 20 warnings about missing resources or deprecated calls. Warnings become errors later.

**Prevention:**
After every refactor step, read Output panel. Clean output panel = successful refactor.

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| All files in root folder | No thinking about organization, fast prototyping | Can't find files, naming conflicts, difficult refactoring | First 2-3 days of prototype only |
| Duplicating code instead of extracting | Faster than designing proper abstraction | Bug fixes multiply, inconsistent behavior | Never in production code |
| get_node() with hard paths | Simple, direct, no setup needed | Breaks on scene changes, tight coupling | Small single-scene prototypes |
| Node instead of Resource for data | Familiar pattern, works immediately | Can't save/load properly, performance overhead | Learning phase only (switch before adding features) |
| Skipping null checks on node references | Less verbose code | Random crashes when scenes change | Never (always use get_node_or_null) |
| No tests during refactoring | Faster initial refactoring | No safety net, regressions hide until play test | Never for working features |
| Global state via autoloads | Easy cross-scene communication | Tight coupling, difficult to test | Truly global game state only (score, player profile) |

## Integration Gotchas

Common mistakes when working with Godot 4.5 systems.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| UID System (4.4+) | Moving files externally without .uid files | Move files in Godot editor, or move .uid alongside .gd |
| Scene Inheritance | Modifying inherited scenes then wondering why changes don't propagate | Understand local vs inherited properties, make changes in base scene |
| Autoloads (4.5) | Expecting PascalCase conversion (changed in 4.5!) | Verify autoload singleton names match actual file naming |
| Resource Files | Editing .tres in text editor | Use Godot inspector for .tres editing to maintain format |
| preload() | Using preload() with dynamic paths | Use load() for runtime paths, preload() only for compile-time constants |
| Signals | Connecting to freed nodes | Check is_connected() before emit, or use one-shot connections |
| Node Unique Names | Using % syntax then renaming node | % references name not path, rename breaks them too |

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Extending Node for every data object | High memory usage, slow scene instantiation | Use Resource for data, Node only for logic | 100+ items in scene tree |
| get_tree() calls in _process() | Frame rate drops | Cache tree reference in _ready() | >30 calls per frame |
| Recalculating DPS every frame | Performance degradation | Calculate only when stats change, cache result | Per-frame for 20+ items |
| Multiple get_node() for same node | Lookup overhead | @onready var cached_node = get_node() | 10+ lookups per frame |
| Duplicating complex scenes | Instantiation lag | Use simpler scenes, object pooling if needed | 50+ simultaneous instances |

## UX Pitfalls

Common user experience mistakes in idle/crafting games.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| No undo for crafting mistakes | Frustration after accidental hammer use | Confirm expensive operations, or allow undo |
| Lost items when inventory full | Progress loss, negative surprise | Prevent adding items when full, clear feedback |
| Invisible stat changes | Can't tell if hammer did anything | Highlight changed values, show before/after |
| No feedback on why action failed | Confusion ("why can't I add this affix?") | Error messages: "Item already has 3 prefixes" |
| Finishing item with hammers remaining | Regret, feeling of waste | Warn if unused hammers, show hammer count prominently |

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **File Organization:** Files moved to folders — verify scene references still work after project reload
- [ ] **Class Renaming:** Class renamed — search entire project for old name in preload(), type hints, autoloads
- [ ] **Scene Restructuring:** Nodes rearranged — test all get_node() paths, check for null reference errors
- [ ] **Data Model Changes:** Resource classes created — verify saving/loading works, inspector shows properties
- [ ] **Signal Refactoring:** Signals added for decoupling — confirm all connections established, test disconnection on free
- [ ] **Code Extraction:** Shared logic moved to new file — ensure all call sites updated, no orphaned code
- [ ] **UID Migration:** Upgraded to 4.4+ — re-save all scenes and resources to regenerate UIDs
- [ ] **Testing Added:** Tests written for refactored code — verify tests actually run and pass
- [ ] **Autoload Updates:** Autoload renamed — check Project Settings → Autoload, verify paths updated
- [ ] **Output Panel Clean:** No warnings in Output panel after refactor

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Broken scene references from file move | MEDIUM | 1. Revert git commit. 2. Move files one at a time via editor. 3. Test after each move. 4. Re-save scenes if using 4.4+. |
| class_name rename broke preloads | LOW | 1. Use "Find in Files" for old class name. 2. Update all references. 3. Reload project. 4. Verify no "class not found" errors. |
| get_node() paths broken | LOW | 1. Add null checks: get_node_or_null(). 2. Find correct new paths via scene tree. 3. Update all paths. 4. Consider replacing with @export. |
| Node/Resource confusion | HIGH | 1. Create new Resource version alongside. 2. Migrate data. 3. Test new version. 4. Remove Node version. 5. Update all references. |
| Signal spaghetti | MEDIUM | 1. Document current flow. 2. Identify unnecessary re-emits. 3. Replace simple signal chains with direct references. 4. Keep signals only for events. |
| Over-engineered system | HIGH | 1. Identify core feature. 2. Extract to simple version in new file. 3. Test simple version. 4. Replace complex system. 5. Delete unused abstractions. |
| Big refactor broke everything | VERY HIGH | 1. Revert git to last working state. 2. Write tests for current behavior. 3. Make ONE change. 4. Test. 5. Commit. 6. Repeat incrementally. |
| Broken autoload | LOW | 1. Project → Project Settings → Autoload. 2. Update paths. 3. Close/reopen project. |
| Broken scene inheritance | MEDIUM | 1. Open child scene. 2. Scene → "Change Scene Root Node". 3. Re-inherit from parent. 4. Reset overridden properties. |

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Moving files breaks references | Phase 1: Project Structure | All scenes load without errors, scripts attach to nodes |
| Renaming classes breaks preload | Phase 2: Data Model Migration | Project loads without "class not found" errors |
| get_node() paths break | Phase 3: Decouple Views | Features work after scene restructuring |
| Node for data objects | Phase 2: Data Model Migration | All data classes extend Resource, .tres files exist |
| Duplicated logic | Phase 4: Shared Systems | Single compute_dps implementation used by all items |
| Refactoring too much at once | ALL PHASES | Each commit keeps game functional, tests pass |
| Signal spaghetti | Phase 3: Decouple Views | Can trace any event flow in max 2 files |
| Over-engineering | Phase 1: Project Structure | Team member can understand any system in <10 minutes |
| Breaking scene inheritance | Phase 1: Project Structure | All child scenes maintain inherited properties |

## Godot 4.5 Specific Gotchas

Version-specific issues for this project.

**UID System Limitations:**
- UID support in 4.0-4.5 is partial — not all file types fully supported
- Must re-save scenes in 4.4+ to generate UIDs for moved files
- .uid files must move with scripts when using external tools
- "Invalid UID, using text path instead" warnings indicate incomplete UID coverage

**Autoload Changes (4.5):**
- Godot 4.5 stopped auto-converting autoload script names to PascalCase
- Projects upgrading from 4.4 may have mismatched class_name expectations
- Verify autoload singleton names match actual file naming
- Check Project Settings → Autoload after any autoload file rename

**Node Unique Names:**
- % syntax introduced for unique names, but renaming still breaks references
- Not a silver bullet for node path stability
- Still requires manual updates when node is renamed

**Refactoring Tool Gaps:**
- No automated refactoring for class renames, file moves, or node paths
- Must manually find and update all references
- "Find in Files" is primary refactoring tool
- Third-party IDE support (VS Code, etc.) doesn't understand scene structure

**Testing Support:**
- GUT 9.x and GdUnit4 available for unit testing
- Scene testing possible but requires setup
- No built-in test framework — must install addon
- Mocking and stubbing supported but not automatic

## Warning Signs

**Red flags during refactoring:**

1. **"Game was working, now nothing loads"** → Likely moved files outside editor or broke scene inheritance
2. **"This signal should fire but isn't"** → Signal connection order issue or over-refactored signals
3. **"Error in 30 different files after one change"** → Broke fundamental type (Node → Resource without migration)
4. **"Can't find what I'm looking for"** → Inconsistent naming (some snake_case, some PascalCase)
5. **"This worked yesterday"** → Didn't commit before refactoring, can't revert
6. **"NullReferenceException spam in Output"** → Broke node paths, @onready variables not updated

**Green flags (refactoring is going well):**

1. Game runs after each small change
2. Output panel is clean (no warnings)
3. Can easily find files by feature
4. Code follows consistent style
5. Changes committed incrementally
6. Can test scenes independently

## Sources

**Official Godot Documentation:**
- [Godot 4 Best Practices](https://docs.godotengine.org/en/stable/tutorials/best_practices/index.html)
- [When and how to avoid using nodes for everything](https://docs.godotengine.org/en/stable/getting_started/workflow/best_practices/node_alternatives.html)
- [TSCN file format (4.4)](https://docs.godotengine.org/en/4.4/contributing/development/file_formats/tscn.html)
- [UID changes coming to Godot 4.4](https://godotengine.org/article/uid-changes-coming-to-godot-4-4/)
- [Godot 4.6 Release Notes](https://godotengine.org/releases/4.6/)

**GitHub Issues:**
- [Godot 4 Beta 8 Refactoring Scenes breaks dependencies #70130](https://github.com/godotengine/godot/issues/70130)
- [Moving resource into folder breaks scene #69260](https://github.com/godotengine/godot/issues/69260)
- [Changing script name after preload() breaks #92007](https://github.com/godotengine/godot/issues/92007)
- [Autoload naming broken in 4.5 #110908](https://github.com/godotengine/godot/issues/110908)
- [Using class_name reference doesn't work with preload #55615](https://github.com/godotengine/godot/issues/55615)

**Community Resources:**
- [GDQuest: Best practices with Godot signals](https://www.gdquest.com/tutorial/godot/best-practices/signals/)
- [GDQuest: Design patterns in Godot](https://www.gdquest.com/tutorial/godot/design-patterns/intro-to-design-patterns/)
- [Go, Go, Godot: GDScript refactoring exercise](https://www.gogogodot.io/refactoring-in-godot/)
- [Godot 4.6 Complete Guide 2026](https://www.live-laugh-love.world/blog/godot-46-complete-guide-2026/)
- [Medium: Securely Refactoring a Skater State Machine in Godot](https://medium.com/@kpicaza/securely-refactoring-a-skater-state-machine-in-godot-with-tests-6c862bc8081f)
- [Godot Forum: How to reference nodes robustly?](https://forum.godotengine.org/t/how-to-reference-nodes-robustly/60071)
- [Godot Forum: How to properly refactor class name, .gd and .tscn](https://forum.godotengine.org/t/how-to-properly-refactor-a-class-name-gd-and-tscn-in-godot/115118)

**Testing Frameworks:**
- [GdUnit4 GitHub](https://github.com/MikeSchulze/gdUnit4)
- [GUT (Godot Unit Test) GitHub](https://github.com/bitwes/Gut)

**Current Project Analysis:**
- Examined 21 .gd files in project root
- Identified Node-based data objects (Item, Weapon, Ring)
- Found duplicated compute_dps() in weapon.gd and ring.gd
- Observed get_node() paths in crafting_view.gd (lines 26, 34-54)
- Confirmed flat file structure with no folder organization

---

*Pitfalls research for: Godot 4.5 ARPG Refactoring*
*Researched: 2026-02-14*
*Confidence: HIGH — sourced from official docs, GitHub issues, community best practices, and direct codebase analysis*
