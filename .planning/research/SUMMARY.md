# Project Research Summary

**Project:** Hammertime v1.3 — Save/Load, UI Layout, Crafting UX, Balance Tuning
**Domain:** Godot 4.5 Idle ARPG Enhancement
**Researched:** 2026-02-17
**Confidence:** HIGH

## Executive Summary

This milestone enhances an existing Godot 4.5 Resource-based idle ARPG with persistence, improved UX, and early-game balance. The recommended approach leverages Godot's native Resource serialization (ResourceSaver/ResourceLoader) for hero data and binary serialization (FileAccess.store_var) for currencies. The existing Resource-based architecture (Hero, Item, Affix classes) integrates cleanly with save systems, but requires custom deep-copy logic due to Godot's limitation with nested Resource arrays.

The UI restructure converts from tab-based view switching to side-by-side hero/crafting layout using HBoxContainer with PanelContainer wrappers. This matches ARPG UX patterns (Path of Exile, Diablo) where players need simultaneous visibility of equipment and crafting inventory. The change requires careful CanvasLayer visibility management, as CanvasLayers don't inherit parent visibility and can create invisible input-blocking bugs. Crafting UX improvements focus on before/after stat comparison panels showing item-level contribution deltas, not total hero stats, to prevent confusion.

The primary risk is save data corruption from shallow Resource duplication. Godot's Resource.duplicate(true) does NOT deep copy Resources inside Arrays or Dictionaries, meaning Hero.equipped_items with nested Item → Affix arrays will share references between save and runtime state. This requires custom deep-copy implementation before any save serialization. Secondary risks include integer division truncation in balance formulas and anchor/container positioning conflicts during UI restructure. All risks have documented prevention strategies with high-confidence sources.

## Key Findings

### Recommended Stack

All required APIs are built into Godot 4.5 — no external dependencies. The two-file save approach separates Hero Resources (user://savegame.tres) from currency Dictionary (user://currencies.sav) because ResourceSaver handles nested Item → Affix references automatically, while binary serialization is faster for simple primitives. The split also optimizes for update frequency: Hero changes on equipment swap (infrequent), currencies change on every craft (frequent).

**Core technologies:**
- **ResourceSaver/ResourceLoader (Godot 4.5)**: Save/load Hero with equipment — native support for Resource references, preserves nested Item/Affix structure, static typing maintained
- **FileAccess.store_var() (Godot 4.5)**: Save currency Dictionary — fast binary serialization, compact format, no manual deserialization required
- **HBoxContainer (Godot 4.5)**: Side-by-side hero/crafting layout — default choice for fixed horizontal split without draggable complexity
- **Tween (create_tween)**: Crafting feedback animations — smooth property changes for button presses, stat updates, currency pulses
- **PanelContainer (Godot 4.5)**: Visually separated sections — background panels for hero/crafting with single-child constraint
- **CACHE_MODE_IGNORE flag**: Prevent stale cached Resources — critical for nested resources in Godot 4.5, forces fresh load with current instances

**Critical integration note:** CACHE_MODE_IGNORE is mandatory when loading save files: `ResourceLoader.load("user://savegame.tres", "", ResourceLoader.CACHE_MODE_IGNORE)` prevents Godot from returning stale cached versions with broken nested resource references.

### Expected Features

**Must have (table stakes):**
- **Auto-save system** — idle games run in background; players expect zero loss on crash/close (20-30 min intervals + significant events)
- **User data directory persistence** — Godot's user:// path handles platform-specific folders automatically
- **Side-by-side equipment/crafting UI** — switching views is tedious; ARPGs show equipment + inventory together (reduces clicks, improves crafting workflow)
- **Before/after stat comparison** — ARPGs (Diablo 4, PoE) show stat deltas when modifying items; critical for informed crafting decisions
- **Hammer tooltips** — players need to know what currency does before using it; missing from current implementation
- **Starter gear (weapon + armor)** — fresh heroes shouldn't fight naked; tutorial expects success
- **Level 1 balance tuning** — reduce monster damage/HP so first area is accessible; idle games need easy beginnings
- **Stat overflow fix** — ScrollContainer wraps stat labels so long affix lists don't break viewport

**Should have (competitive):**
- **Crafting audio/visual feedback** — satisfying feedback loop; low effort, high impact (sound effects for success/failure, color flashes)
- **Save format versioning** — updates shouldn't corrupt saves; critical for live games (use version field in save data)
- **Item-level stat comparison** — show equipped item stats vs crafted item stats side-by-side; prevents "why did DPS only go up X?" confusion

**Defer (v2+):**
- **Export/import save strings** — community build sharing; low-effort differentiator but not essential for single-player MVP
- **Cloud save sync** — cross-device play is premium feature; requires backend infrastructure (massive overkill for offline game)
- **Crafting preview mode** — "try before you buy" simulation; unique feature but adds complexity (deep copy overhead)
- **Multiple save slots** — players want to test builds; standard in ARPGs but not critical for idle game MVP
- **Drag-and-drop equipping** — more satisfying than click; nice-to-have but click-to-equip already implemented and works

### Architecture Approach

The milestone integrates with existing Resource-based architecture rather than replacing it. All game data already extends Resource (Hero, Item, Affix, Currency classes), making ResourceSaver the natural choice for persistence. The save system uses a two-layer approach: SaveData Resource wraps Hero + currency Dictionary, then SaveManager singleton handles deep-copy logic and ResourceSaver/Loader operations.

**Major components:**
1. **SaveData Resource (new)** — container for all persistent state with exported properties for editor inspection (hero_data: Hero, currency_counts: Dictionary, save_version: int, save_timestamp: int)
2. **SaveManager Singleton (new)** — autoload that handles save_game()/load_game() with custom deep-copy logic for Hero.equipped_items (manual array iteration to avoid Resource.duplicate() limitation)
3. **SideBySideContainer (scene restructure)** — HBoxContainer replaces tab navigation; wraps HeroView + CraftingView in PanelContainers for 50/50 split with 10px separation (595px × 600px each)
4. **StatComparisonPanel (new)** — shows item-level stat deltas when hovering equipment slots with last_crafted_item available (calculates contribution, not total hero stats)

**Integration pattern:** Existing signal flow remains intact (crafting_view.item_finished → hero_view.set_last_crafted_item). After load, SaveManager emits GameEvents.equipment_changed("all", null) to trigger UI refresh across all views. No new cross-view signals needed.

### Critical Pitfalls

1. **Resource.duplicate() doesn't deep copy Arrays of Resources** — Item has prefixes: Array[Affix] and suffixes: Array[Affix]. When Hero saves equipped items, duplicate(true) does NOT duplicate subresources in arrays, creating reference-sharing between save and runtime state. Solution: implement custom Item.deep_duplicate() that manually iterates arrays and calls Affix.new() for each element. Test by modifying loaded item's affix, reloading save, verifying affix unchanged.

2. **CanvasLayer visibility doesn't inherit from parent Node2D** — GameplayView's CombatUI (CanvasLayer) doesn't inherit visibility from parent. Currently handled with explicit sync at main_view.gd:86. Side-by-side layout with multiple views visible simultaneously requires explicit CanvasLayer.visible = parent_view.visible for each layer, otherwise invisible-but-active UI elements block clicks and trigger hover effects. Test by hiding gameplay view, verifying combat UI also hidden.

3. **Control anchor positioning breaks when switching to Container layout** — Current UI uses manual anchor positioning (main.tscn lines 20-47). Converting to Container-based layout while keeping anchor properties causes Containers to compute size as 0x0. Solution: set all anchors to 0, all offsets to 0, use Container properties (size_flags_horizontal, custom_minimum_size) instead. Test at 1200×700 viewport before testing responsive behavior.

4. **Integer division truncation in combat math pipeline** — GDScript performs integer division when both operands are integers. In DefenseCalculator.calculate_armor_reduction(), explicit float() casts prevent this, but new balance formulas may introduce truncation. Example: 8 / 10 * 25 = 0 (8/10 truncates to 0) vs float(8) / 10 * 25 = 20. Solution: always cast first operand to float or use .0 literals. Test with unit test comparing float vs int calculations.

5. **Save data schema changes break existing saves without migration** — Adding new properties to Hero/Item/Affix (e.g., item_level: int) breaks existing saves. ResourceLoader sets missing properties to default values (0, null), not _init() values. Loaded items have tier_range = Vector2i(0, 0) instead of Vector2i(1, 8), causing division by zero in formulas. Solution: implement save version tracking from day one (const SAVE_VERSION = 1), store version in save file header, create migrate_v1_to_v2() functions. Test by saving as v1, adding property, loading as v2, verifying migration ran.

## Implications for Roadmap

Based on research, suggested phase structure with 4 phases addressing dependencies and pitfalls:

### Phase 1: Save/Load Foundation
**Rationale:** Independent of UI changes; establishes persistence layer first. Must implement deep-copy logic before any save serialization to avoid corruption pitfall.

**Delivers:**
- SaveData Resource with version tracking
- SaveManager autoload with custom deep-copy methods (Hero, Item, Affix arrays)
- Save/Load buttons in main_view with success/failure feedback
- Auto-save timer (every 5 minutes + on significant events)

**Addresses:**
- Auto-save system (table stakes feature)
- User data directory persistence (table stakes)
- Save format versioning (should-have)

**Avoids:**
- Pitfall #1 (Resource.duplicate() shallow copy) — custom deep-copy implementation
- Pitfall #5 (schema changes break saves) — version tracking from start
- Pitfall #6 (null handling inconsistency) — standardize Dictionary.get(slot, null) pattern

**Technical details:**
- Two-file approach: user://savegame.tres (Hero Resource), user://currencies.sav (binary Dictionary)
- CACHE_MODE_IGNORE flag required: ResourceLoader.load("user://savegame.tres", "", ResourceLoader.CACHE_MODE_IGNORE)
- Deep copy pattern: _deep_copy_hero() → _deep_copy_item() → _deep_copy_affix() with manual array iteration

### Phase 2: Side-by-Side UI Layout
**Rationale:** Requires scene restructuring; do before adding comparison UI to avoid repositioning twice. Depends on Phase 1 being complete so save buttons are already in navigation panel.

**Delivers:**
- HBoxContainer in main.tscn wrapping HeroView + CraftingView
- PanelContainer wrappers for visual separation (595px × 600px each)
- Updated main_view.gd with 2-mode toggle (side-by-side vs gameplay)
- Responsive layout adjustments for hero_view.tscn and crafting_view.tscn
- CanvasLayer visibility sync system

**Addresses:**
- Side-by-side equipment/crafting UI (table stakes)
- Equipment slot visibility while crafting (table stakes)
- Visual slot states (already exists, needs layout integration)

**Avoids:**
- Pitfall #2 (CanvasLayer visibility doesn't inherit) — explicit visibility sync for all CanvasLayers
- Pitfall #3 (anchor/container conflict) — reset all anchors to 0, use Container properties
- Pitfall #7 (signal flow breaks with concurrent views) — refactor signal handlers to be state-query-free

**Technical details:**
- Scene tree: MainView → SideBySideContainer (HBoxContainer) → [PanelContainer → HeroView, PanelContainer → CraftingView]
- Layout calculations: 1200px width - 10px separation = 595px per panel
- Size flags: Expand Fill + stretch_ratio: 1 on both PanelContainers for equal split
- Navigation changes: remove Crafting/Hero buttons, keep Adventure + Save/Load

### Phase 3: Crafting UX — Stat Comparison
**Rationale:** Depends on side-by-side layout (comparison panel positioning assumes new layout dimensions). Implements before/after comparison feature flagged as table stakes.

**Delivers:**
- StatComparisonPanel scene (PanelContainer with RichTextLabel)
- Integration with hero_view hover signals (mouse_entered/mouse_exited)
- Item-level stat delta calculations (DPS, armor, evasion, ES)
- Color-coded feedback (green for improvements, red for downgrades)

**Addresses:**
- Before/after stat comparison (table stakes)
- Item-level comparison preventing confusion (should-have)

**Avoids:**
- Pitfall #4 (integer division) — ensure all delta calculations use float
- Anti-pattern: showing total hero stats vs item contribution (confusing to users)

**Technical details:**
- Comparison shows item contribution delta, not total hero stats
- Format: "DPS: +50" (new weapon 100 DPS - old weapon 50 DPS)
- Triggered on hover when last_crafted_item available and can_equip_item() returns true
- Uses RichTextLabel for color markup: [color=green]+X[/color]

### Phase 4: Balance Tuning + Polish
**Rationale:** All systems in place; final phase tunes difficulty and adds feedback polish. Requires spreadsheet modeling before implementation to avoid cascade pitfall.

**Delivers:**
- Starter gear generation (basic weapon tier 0, basic armor tier 0)
- Level 1 monster damage/HP reduction (30-50% damage, 20-30% HP)
- Hammer drop rate increase for first area (2x multiplier)
- Balance validation spreadsheet with formulas
- Crafting audio/visual feedback (Tween animations, sound effects)
- Hammer tooltips system
- Stat overflow fix (ScrollContainer wrapper)

**Addresses:**
- Starter gear (table stakes)
- Level 1 balance tuning (table stakes)
- Stat overflow fix (table stakes)
- Crafting audio/visual feedback (should-have)
- Hammer tooltips (table stakes)

**Avoids:**
- Pitfall #8 (balance cascades not modeled) — spreadsheet first, then tune
- Pitfall #4 (integer division in new formulas) — validate float precision

**Technical details:**
- Balance spreadsheet columns: Raw Damage | Armor | Armor Reduction % | Effective HP Multiplier | Time to Die
- Invariant: level 1 hero (50 armor assumed) survives 20 seconds vs level 1 monster
- Tween patterns: modulate flash (green success, red failure), scale pulse for currency changes
- ScrollContainer setup: wrap stats_label, enable vertical scroll only, autowrap_mode: AUTOWRAP_WORD_SMART

### Phase Ordering Rationale

- **Phase 1 → Phase 2 dependency:** Save/Load must complete first so Save/Load buttons exist before navigation panel restructure
- **Phase 2 → Phase 3 dependency:** Comparison panel positioning requires side-by-side layout dimensions (595px width constraint)
- **Phase 1-3 → Phase 4 independence:** Balance tuning and polish can run in parallel with earlier phases during testing, but formulas need validation after stat calculation infrastructure stabilizes
- **Pitfall prevention ordering:** Deep-copy implementation (Phase 1) before any save serialization prevents corruption; Container restructure (Phase 2) before adding new UI elements prevents repositioning work
- **Feature grouping logic:** Persistence (Phase 1) is foundational infrastructure; UI restructure (Phase 2) is structural change affecting all views; stat comparison (Phase 3) is UX enhancement requiring new structure; balance (Phase 4) is content tuning requiring stable systems

### Research Flags

Phases with standard patterns (skip research-phase):
- **Phase 1 (Save/Load):** Well-documented Godot 4.5 patterns; GDQuest Library provides verified implementation examples; deep-copy workaround is known issue with documented solutions
- **Phase 2 (UI Layout):** Standard Container usage; Godot documentation covers HBoxContainer, PanelContainer extensively; CanvasLayer visibility sync is documented pattern
- **Phase 3 (Stat Comparison):** Simple UI panel with hover signals (already implemented in codebase); stat calculation is straightforward delta math
- **Phase 4 (Balance Tuning):** Spreadsheet modeling is standard game design practice; no novel research needed, just formula validation

Phases NOT needing deeper research during planning:
- All phases use existing Godot 4.5 built-in APIs (no external libraries)
- All pitfalls have documented solutions with high-confidence sources
- Architecture patterns are established (Resource-based save, Container-based layout, signal-based communication)
- No novel algorithms or complex integrations required

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All recommendations based on Godot 4.5 official documentation and GDQuest Library verified patterns; no external dependencies; Resource serialization is native Godot feature |
| Features | MEDIUM | Table stakes features validated against ARPG genre conventions (PoE, Diablo, Last Epoch); idle game patterns from multiple sources (Idle Wizard, NGU IDLE); some features inferred from domain norms rather than explicit Hammertime requirements |
| Architecture | HIGH | Integration patterns verified with existing codebase analysis (game_state.gd, hero_view.gd, crafting_view.gd); Resource.duplicate() limitation confirmed by GitHub issue #74918; Container patterns from official Godot tutorials |
| Pitfalls | HIGH | All 8 pitfalls sourced from official Godot documentation, GitHub issues, or verified community patterns; each has concrete prevention strategy and verification test; codebase analysis confirms susceptibility to identified issues |

**Overall confidence:** HIGH

All technical recommendations use Godot 4.5 built-in APIs with official documentation. Resource serialization patterns verified by GDQuest Library (high-authority Godot education source). Pitfall prevention strategies sourced from GitHub issues and community post-mortems. Feature priorities inferred from genre conventions rather than explicit requirements, but table stakes features match idle ARPG standards.

### Gaps to Address

**Gap: Exact balance target metrics not defined**
- Research identified balance tuning patterns and spreadsheet methodology, but specific targets (e.g., "level 1 hero should survive X seconds") are assumptions
- **Mitigation:** Phase 4 planning defines concrete balance targets based on playtest data from Phases 1-3; spreadsheet models multiple scenarios to identify acceptable ranges

**Gap: Audio asset sourcing not researched**
- Crafting feedback feature includes sound effects, but research didn't identify specific free/paid libraries compatible with Godot
- **Mitigation:** Phase 4 planning includes audio asset research; if not resolved, visual-only feedback (Tween animations) is acceptable MVP (sound effects are polish, not core UX)

**Gap: Save file size at scale unknown**
- Research assumes 5-10 items per save (5 equipped + crafting inventory), but long-term save size with 100+ items not validated
- **Mitigation:** Not relevant for v1.3 milestone (no item stash planned); defer to future milestone if inventory expansion added

**Gap: Mobile/web export behavior for user:// path**
- Research confirms user:// works for desktop export, but mobile/web specifics not verified
- **Mitigation:** Not relevant for current desktop-only scope; if mobile export added later, Godot documentation covers platform-specific paths

## Sources

### Primary (HIGH confidence)
- [Saving and Loading Games in Godot 4 (with resources) | GDQuest Library](https://www.gdquest.com/library/save_game_godot4/) — Resource save/load patterns, deep-copy workaround
- [ResourceSaver — Godot Engine (stable) documentation](https://docs.godotengine.org/en/stable/classes/class_resourcesaver.html) — Official API reference
- [ResourceLoader — Godot Engine (stable) documentation](https://docs.godotengine.org/en/stable/classes/class_resourceloader.html) — CACHE_MODE_IGNORE flag documentation
- [Using Containers — Godot Engine (stable) documentation](https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html) — Container layout patterns
- [HBoxContainer — Godot Engine (4.5) documentation](https://docs.godotengine.org/en/4.5/classes/class_hboxcontainer.html) — Size flags and stretch ratios
- [Resource.duplicate(true) doesn't duplicate subresources in Arrays/Dictionaries](https://github.com/godotengine/godot/issues/74918) — GitHub issue confirming limitation
- [Duplicate Godot custom resources deeply, for real](https://simondalvai.org/blog/godot-duplicate-resources/) — Custom deep-copy implementation pattern
- [Tween — Godot Engine (4.5) documentation](https://docs.godotengine.org/en/4.5/classes/class_tween.html) — Animation API for crafting feedback

### Secondary (MEDIUM confidence)
- [Game UI Database - Weapon Comparison Pickup](https://www.gameuidatabase.com/index.php?scrn=154) — ARPG item comparison UX patterns
- [Idle Wizard Auto-Save Discussion](https://steamcommunity.com/app/992070/discussions/0/2247803885929795897/) — Idle game save frequency patterns (20-30 min intervals)
- [Balancing Tips: How We Managed Math on Idle Idol](https://www.gamedeveloper.com/design/balancing-tips-how-we-managed-math-on-idle-idol) — Balance spreadsheet methodology
- [Overview of Godot UI containers | GDQuest](https://school.gdquest.com/courses/learn_2d_gamedev_godot_4/start_a_dialogue/all_the_containers) — Container usage examples
- [CanvasLayer — Godot Engine (stable) documentation](https://docs.godotengine.org/en/stable/tutorials/2d/canvas_layers.html) — Visibility inheritance behavior

### Tertiary (LOW confidence)
- [Path of Exile Interface Design](https://interfaceingame.com/games/path-of-exile/) — ARPG UI conventions (inferred patterns, not explicit requirements)
- [BOOM Library: Modern UI Sound Effects](https://www.boomlibrary.com/sound-effects/modern-ui/) — Audio asset example (not vetted for Godot compatibility)

---
*Research completed: 2026-02-17*
*Ready for roadmap: yes*
