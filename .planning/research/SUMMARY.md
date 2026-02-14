# Project Research Summary

**Project:** Hammertime ARPG - Code Cleanup & Architecture (v0.1)
**Domain:** Godot 4.5 ARPG Idle Game Refactoring
**Researched:** 2026-02-14
**Confidence:** HIGH

## Executive Summary

This project refactors an existing Godot 4.5 ARPG idle game codebase to establish professional architecture and maintainability. The codebase exhibits common first-project issues: 21 .gd files flat in project root, mixed naming conventions (Tag.gd vs item_affixes.gd), duplicate logic across item types (compute_dps() in both weapon.gd and ring.gd), and the anti-pattern of extending Node for pure data objects. The user is new to Godot, making clear structure and best-practice patterns critical for long-term success.

The recommended approach follows Godot 4.5 official conventions: feature-based folder organization, Resource-based data models (not Nodes), signal-based UI communication ("call down, signal up"), and incremental refactoring with continuous testing. The stack is validated (Godot 4.5, GDScript, text-based resources) and requires only tooling additions (gdformat for standardization, possibly GdUnit4 for testing safety). Critical systems to establish: unified stat calculation eliminating duplicate compute_dps() implementations, tag system separation of concerns (affix filtering vs damage calculation), and Model-View separation with GameState autoload as single source of truth.

The primary risk is breaking scene references during file reorganization — Godot 4.5's UID system is partial, and moving files outside the editor destroys .tscn dependencies. Mitigation: **always move files within Godot editor**, test after each change (F5 takes 5 seconds), commit incrementally, and never refactor more than one concern at a time. Secondary risks include signal spaghetti from over-correction of tight coupling, and over-engineering patterns unnecessary for idle game scope. The refactoring must be incremental (format → organize → migrate data model → extract shared logic) to maintain working game state throughout.

## Key Findings

### Recommended Stack

The existing stack (Godot 4.5, GDScript, text-based .tscn/.tres files) is solid and requires no changes. Add development tooling for consistency and safety during refactoring.

**Core technologies:**
- **Godot 4.5** (game engine) — Already validated. Scene-based architecture encourages modular organization. Editor's Move/Rename tools maintain reference integrity when used correctly.
- **GDScript with static typing** (primary language) — Gradual typing allows incremental type hint adoption. Focus on function signatures first, internal variables second.
- **gdformat/gdlint** (formatting/linting) — Enforces official GDScript style guide. Run on all 21 .gd files as first refactoring step to establish baseline consistency.

**Critical tooling to add:**
- `gdformat` for code standardization (uncompromising formatter, run once on entire codebase)
- Consider GdUnit4 for test safety net during refactoring (prevents regressions)

**Folder structure pattern** (small project <50 scripts):
```
res://
├── autoloads/         # GameState, GameEvents, ItemRegistry (rename from ItemAffixes)
├── models/            # Data classes as Resources (hero/, items/, affixes/)
├── scenes/            # Views by feature (hero/, crafting/, gameplay/, main/)
├── utils/             # Constants (rename Tag.gd to constants.gd)
```

### Expected Features

This is a refactoring milestone, not a new-feature milestone. "Features" here are refactoring patterns that establish maintainable architecture.

**Must have (table stakes for completion):**
- **Directory Organization** — Group by feature/domain, not flat root. Foundational for all other work.
- **Unified Stat Calculation System** — Eliminate duplicate compute_dps() in weapon.gd and ring.gd. Primary goal of this milestone.
- **Tag System Separation** — Split dual-purpose Tag.gd into AffixTag (eligibility) and StatType (calculation routing). Clear single-responsibility.
- **Standardized Item Interface** — Define abstract update_value() contract in Item base class.
- **Signal-Based UI Updates** — Break tight coupling between views using "call down, signal up" pattern.

**Should have (architectural improvements):**
- **Modifier Pipeline Architecture** — Formalize order-of-operations (flat → increased → more) once unified calculation works.
- **Strategy Pattern for Damage Types** — Use strategy objects instead of tag-checking if-chains. Defer until 3+ damage types exist.
- **Event Bus Singleton** — Centralize signal routing via GameEvents autoload for distant communication.

**Defer (v2+ - advanced patterns):**
- **Resource-Based Item Data** — Major migration from Node to Resource. High complexity, enables data-driven design.
- **Composition Over Inheritance** — Component-based capabilities. Current 5 item types don't justify complexity.
- **Reactive Stat Dependencies** — Automatic recalculation. Current manual update_stats() works fine.

### Architecture Approach

Establish Model-View separation with GameState autoload as single source of truth. Views are Nodes that display and interact. Models are Resources (for serialization) or RefCounted classes (runtime only) that contain business logic. Communication follows "call down, signal up" — parents call child methods directly, children emit signals up to parents. Siblings coordinate through parent or GameEvents bus for distant communication.

**Major components:**
1. **GameState autoload** — Owns Hero instance, provides single source of truth for game state. All views reference GameState.hero instead of passing references manually.
2. **GameEvents autoload** — Event bus for cross-scene signals (equipment_changed, item_crafted, area_cleared). Decouples distant nodes.
3. **Model layer (Resources)** — Item, Weapon, Armor, Ring, Affix classes extend Resource (not Node). Enables serialization, inspector editing, lightweight data storage.
4. **View layer (Scenes)** — HeroView, CraftingView, GameplayView display model state. Subscribe to model.changed signals, update UI on changes.
5. **Shared Systems** — StatCalculator for unified DPS calculation. Called by all item types, centralizes ARPG formulas.

**Data flow pattern:**
```
User clicks slot in HeroView
    ↓
GameState.hero.equip_item(item, slot)  # Model update
    ↓
Hero emits changed signal
    ↓
HeroView._on_hero_changed() updates UI
    ↓
GameEvents.equipment_changed.emit(hero)  # Notify distant listeners
    ↓
GameplayView receives signal, updates clearing speed
```

**Critical architectural decisions:**
- **Resource vs Node**: Use Resource for data (items, stats), Node for behavior (UI, logic that needs scene tree). Current codebase uses Node for data — must migrate.
- **Autoload limits**: Only GameState (shared state), GameEvents (event bus), ItemRegistry (read-only data). Never put game logic or mutable state in autoloads.
- **Feature-based folders**: Co-locate scenes/scripts by feature (scenes/hero/, scenes/crafting/), not by type (scripts/, scenes/). Easier to reason about scope.

### Critical Pitfalls

1. **Moving files breaks scene references** — Godot 4.5's UID system is partial. Moving files outside editor destroys .tscn dependencies. **Prevention**: Always move files within Godot editor's FileSystem dock (right-click → Move To). Test after each move (F5). Commit before reorganization.

2. **Renaming classes breaks class_name and preload()** — Search entire project for old name before renaming. Update class_name declarations, preload() calls, type hints, and autoload paths in sequence. Godot 4.5 changed autoload naming (no auto-PascalCase conversion).

3. **get_node() paths break during restructuring** — Current codebase uses extensive relative paths (crafting_view.gd lines 26, 34-54). **Prevention**: Replace with @export NodePath variables or @onready caching. Prefer signals over direct node references.

4. **Extending Node for data objects** — Current Item, Weapon, Ring, Affix all extend Node. Should extend Resource. Causes high memory overhead, prevents serialization, confuses data vs logic. **Prevention**: Migrate to Resource-based models before other refactoring.

5. **Refactoring too much at once** — Making multiple simultaneous changes (move files AND rename classes AND restructure data) makes debugging impossible. **Prevention**: One refactor per commit. Test after each change. Incremental: format → organize → migrate → extract.

## Implications for Roadmap

Based on research, refactoring must follow strict dependency order to maintain working game state throughout. The architecture requires foundation layers before UI decoupling can succeed.

### Phase 1: Foundation Setup
**Rationale:** Establish baseline consistency and folder structure before code changes. Non-breaking changes reduce risk.

**Delivers:**
- All code formatted via gdformat (standardized style)
- Feature-based folder structure created
- Files moved to appropriate folders (via Godot editor only)
- Scene files renamed to snake_case (remove spaces from "Gameplay view.tscn")

**Addresses:** Directory Organization (FEATURES.md table stakes), inconsistent naming (STACK.md assessment)

**Avoids:** Pitfall #1 (file move breaking references) by using editor's Move tool and testing after each change

**Research flags:** Standard patterns, no additional research needed. Follow STACK.md folder structure recommendations.

---

### Phase 2: Data Model Migration
**Rationale:** Must happen before UI refactoring. Changing Item from Node to Resource while also refactoring signals creates debugging nightmare. Foundation for all subsequent work.

**Delivers:**
- Item, Weapon, Armor, Ring, Affix classes extend Resource (not Node)
- GameState autoload created with hero instance
- GameEvents autoload created with core signals
- ItemRegistry autoload (renamed from ItemAffixes)
- .tres resource files for item definitions

**Uses:** Godot Resource system (STACK.md architectural decisions)

**Implements:** Model layer (ARCHITECTURE.md component #3)

**Avoids:** Pitfall #4 (Node for data objects) by migrating all data to Resources. Pitfall #2 (class renaming) by establishing final names during migration.

**Research flags:** Standard Resource patterns from official docs. May need research-phase if custom serialization required for save/load system.

---

### Phase 3: Unified Calculations
**Rationale:** Core value of this milestone. Once data model is stable (Resources), extract duplicate logic safely. Dependencies clear: both weapon.gd and ring.gd must be Resources before shared calculation can reference them polymorphically.

**Delivers:**
- StatCalculator system for unified DPS calculation
- Single compute_dps() implementation replacing duplicates in weapon.gd/ring.gd
- Tag system separation (AffixTag for filtering, StatType for calculations)
- Standardized Item.update_value() interface across all item types

**Addresses:** Unified Stat Calculation, Tag System Separation, Standardized Item Interface (all FEATURES.md P1 priorities)

**Avoids:** Pitfall #5 (duplicated logic) by centralizing formulas. Pitfall #6 (refactoring too much) by focusing only on calculations, not UI.

**Research flags:** Modifier pipeline order-of-operations may need research-phase if ARPG calculation patterns unclear. Otherwise standard refactoring.

---

### Phase 4: Signal-Based Communication
**Rationale:** UI decoupling depends on stable data model (Phase 2) and clear calculation ownership (Phase 3). Signals connect model changes to UI updates.

**Delivers:**
- Hero emits stats_updated and health_changed signals
- Views listen to model changes instead of polling
- Sibling communication through MainView coordinator or GameEvents
- @onready caching replaces repeated get_node() calls

**Addresses:** Signal-Based UI Updates (FEATURES.md P1 priority)

**Implements:** "Call down, signal up" pattern (ARCHITECTURE.md Pattern #2)

**Avoids:** Pitfall #3 (get_node() paths break) by replacing with signals. Pitfall #7 (signal spaghetti) by using direct calls for parent→child, signals only for child→parent and distant communication.

**Research flags:** Standard Godot signal patterns. No additional research needed beyond ARCHITECTURE.md examples.

---

### Phase Ordering Rationale

**Why this order:**
1. **Format/organize first** — Non-breaking changes establish baseline. Can't effectively refactor spaghetti code that's also inconsistently formatted.
2. **Data model before logic** — Changing Item from Node to Resource while also extracting shared calculations creates impossible debugging scenario. Data foundation must be stable.
3. **Calculations before UI** — Unified stat system must exist before UI can reliably listen to stat changes. Can't signal "stats changed" when stat calculation is still duplicated and inconsistent.
4. **Signals last** — UI decoupling requires stable models to reference and stable calculation results to display. Attempting signal refactoring with moving targets causes signal spaghetti.

**How this avoids pitfalls:**
- Incremental commits (each phase has working game state) prevents Pitfall #6 (refactoring too much)
- Phase boundaries enforce testing points — can't proceed to Phase 2 until Phase 1 files load correctly
- Data model migration isolated in Phase 2 prevents mixing concerns (Pitfall #5)
- UI changes deferred to Phase 4 prevent breaking get_node() paths mid-refactor (Pitfall #3)

### Research Flags

**Phases needing potential research:**
- **Phase 2 (Data Model):** May need research-phase if save/load serialization patterns unclear. Custom Resource serialization for game state persistence.
- **Phase 3 (Calculations):** May need research-phase for ARPG modifier pipeline patterns (flat → increased → more order-of-operations) if extending beyond basic DPS.

**Phases with standard patterns (skip research-phase):**
- **Phase 1 (Foundation):** Well-documented file organization and formatting. Follow STACK.md directly.
- **Phase 4 (Signals):** Godot signal patterns are standard. ARCHITECTURE.md provides sufficient examples and decision framework.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All recommendations from Godot 4.5 official documentation. Existing stack validated. No technology changes needed. |
| Features | HIGH | Refactoring patterns well-established in community. Table stakes features (organization, signal-based UI) have clear implementations. Priority ordering matches dependency analysis. |
| Architecture | HIGH | Model-View separation, Resource-based data, signal communication all official Godot best practices. Pattern examples verified against official docs and GDQuest guidelines. |
| Pitfalls | HIGH | Sourced from official docs, GitHub issues tracking real bugs, community post-mortems. Pitfalls #1-4 directly observed in current codebase or documented in Godot 4.5 issue tracker. |

**Overall confidence:** HIGH

Research draws from Godot 4.5 official documentation (scene organization, signals, resources, autoloads), verified GitHub issues (UID system limitations, autoload naming changes), and established community resources (GDQuest, KidsCanCode, GodotTutorials). All core recommendations traceable to authoritative sources. Current codebase analyzed directly to confirm anti-patterns and duplication.

### Gaps to Address

**Minor gaps requiring validation during implementation:**

1. **Save/load serialization patterns** — Research confirms Resources support serialization, but specific implementation for hero equipment state, crafting hammers, and area progress may need experimentation. Consider adding save/load as Phase 2 acceptance criteria to validate Resource migration.

2. **ARPG modifier order-of-operations** — Research identifies industry-standard pattern (flat → increased → more from Path of Exile), but implementation details for tag-to-modifier conversion need working prototype. Consider Phase 3 research-phase spike if extending beyond basic DPS.

3. **Testing framework setup** — GdUnit4 and GUT identified as options, but no research on setup complexity or integration with existing project. If tests are added (recommended for refactoring safety), allocate setup time in Phase 1 or pre-Phase 1 spike.

4. **Node unique names (% syntax) reliability** — Research notes % syntax still breaks on renames. If using unique names in Phase 4, validate behavior in Godot 4.5 specifically.

**How to handle during planning:**
- Add save/load spike to Phase 2 (Data Model Migration) — 2-4 hours to validate ResourceSaver.save() with equipped items
- Add ARPG calculation research-phase to Phase 3 if modifier pipeline is implemented (defer if not)
- Testing framework decision: make during Phase 1 planning. If adding tests, allocate 4-6 hours for GdUnit4 setup and first test cases.
- Document % syntax behavior if using unique names — add to Phase 4 acceptance criteria

**Confidence remains HIGH** despite minor gaps — all gaps have clear investigation paths and don't affect core architectural recommendations.

## Sources

### Primary (HIGH confidence)

**Official Godot 4.5 Documentation:**
- [Project organization](https://docs.godotengine.org/en/4.5/tutorials/best_practices/project_organization.html) — Folder structure conventions
- [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html) — Naming, formatting rules
- [Scene organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html) — Architecture patterns
- [Autoloads versus internal nodes](https://docs.godotengine.org/en/stable/tutorials/best_practices/autoloads_versus_internal_nodes.html) — When to use autoloads
- [Static typing in GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html) — Type system conventions
- [Resources](https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html) — Resource-based data patterns
- [Using signals](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html) — Signal patterns

**GitHub Issues (Godot 4.5 specific):**
- [Godot #70130](https://github.com/godotengine/godot/issues/70130) — Refactoring scenes breaks dependencies
- [Godot #69260](https://github.com/godotengine/godot/issues/69260) — Moving resources breaks scenes
- [Godot #110908](https://github.com/godotengine/godot/issues/110908) — Autoload naming broken in 4.5
- [UID changes in Godot 4.4](https://godotengine.org/article/uid-changes-coming-to-godot-4-4/) — UID system limitations

### Secondary (MEDIUM confidence)

**Community Best Practices:**
- [GDQuest GDScript Guidelines](https://gdquest.gitbook.io/gdquests-guidelines/godot-gdscript-guidelines) — Community conventions
- [Best practices with Godot signals - GDQuest](https://www.gdquest.com/tutorial/godot/best-practices/signals/) — Signal patterns
- [Event bus singleton - GDQuest](https://www.gdquest.com/tutorial/godot/design-patterns/event-bus-singleton/) — Event bus implementation
- [Node communication (the right way) - Godot 4 Recipes](https://kidscancode.org/godot_recipes/4.x/basics/node_communication/) — Communication patterns
- [When to Node, Resource, and Class in Godot](https://backat50ft.substack.com/p/when-to-node-resource-and-class-in) — Node vs Resource guidance
- [MVC in Godot - Rads and Relics](https://radsandrelics.com/posts/godot-mvc/) — Model-View-Controller patterns

**Stat System Architecture:**
- [Modular Stat/Attribute System Tutorial for Godot 4](https://medium.com/@minoqi/modular-stat-attribute-system-tutorial-for-godot-4-0bac1c5062ce) — Modifier pipeline patterns
- [Godot Tactics RPG – 09. Stats](https://theliquidfire.com/2024/10/10/godot-tactics-rpg-09-stats/) — Stat calculation approaches
- [EnhancedStat addon - GitHub](https://github.com/Zennyth/EnhancedStat) — Existing stat system reference

**Refactoring Practices:**
- [GDScript refactoring exercise - Go, Go, Godot!](https://www.gogogodot.io/refactoring-in-godot/) — Practical refactoring walkthrough
- [My Thresholds for Refactoring](https://coffeebraingames.wordpress.com/2017/11/06/my-thresholds-for-refactoring/) — When to refactor guidelines
- [Refactoring: the Way to Perfection](https://www.gamedeveloper.com/programming/refactoring-the-way-to-perfection-) — Refactoring strategies

### Tertiary (LOW confidence)

**Anti-Pattern References:**
- [The God Class Intervention](https://www.wayline.io/blog/god-class-intervention-avoiding-anti-pattern) — God object anti-pattern
- [Software Anti-Patterns](https://www.bairesdev.com/blog/software-anti-patterns/) — General anti-patterns
- [Catalogue of Game-Specific Anti-Patterns](https://dl.acm.org/doi/abs/10.1145/3511430.3511436) — Academic anti-pattern research

**Current Codebase Analysis:**
- Direct examination of 21 .gd files in project root
- Identified Node-based data objects (Item, Weapon, Ring extend Node)
- Found duplicate compute_dps() in weapon.gd (lines 18-64) and ring.gd (lines 13-35)
- Observed get_node() paths in crafting_view.gd (lines 26, 34-54)
- Confirmed flat file structure with spaces in filenames ("Gameplay view.tscn")

---

*Research completed: 2026-02-14*
*Ready for roadmap: yes*
