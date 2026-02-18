# Project Research Summary

**Project:** Hammertime — Damage Range System (v1.4 Milestone)
**Domain:** Godot 4.5 Idle ARPG — Min/Max Damage Ranges for Weapons, Monsters, and Affixes
**Researched:** 2026-02-18
**Confidence:** HIGH

## Executive Summary

This milestone replaces the existing flat scalar damage model with per-element min-max damage ranges across weapons, flat damage affixes, and monster packs. This is a well-documented ARPG convention (Diablo 2/4, Path of Exile, Guild Wars 2 all use this pattern), and the existing codebase already has the core infrastructure in place: `randi_range()` is already used in 7 files, `Affix` already serializes `min_value` and `max_value`, and `CombatEngine` already performs a per-hit crit roll using `randf()`. The changes are additive and surgical rather than architectural overhauls — no new files are required.

The recommended approach is a layered build: save migration first (before any schema change can corrupt existing saves), then data model (Weapon and Affix fields), then stat calculator refactor (dual-accumulator math), then combat engine per-hit rolling, and finally UI display. The single most critical constraint is that stat aggregation must maintain two separate accumulators (min and max) through the entire pipeline; collapsing to an average too early is the most common failure mode and silently produces wrong combat output even when the tooltip looks correct.

The primary risk is save migration: existing saves store flat damage affixes with a single `value` integer. Adding range fields without bumping `SAVE_VERSION` and writing a v1-to-v2 migration will cause existing saves to load with zero flat damage silently — no crash, just wrong numbers. This migration must be written before any Affix schema changes are merged. A secondary design risk is the lightning variance ratio: if set too aggressively (PoE-style "1 to 1000"), the idle game's lack of counterplay mechanics will produce statistically unfair deaths that players cannot avoid. Variance ratios must be modeled against survivability before coding affix templates.

## Key Findings

### Recommended Stack

The engine, language, renderer, and data model are already validated and unchanged for this milestone (Godot 4.5, GDScript, mobile renderer, Resource-based model). No new dependencies, plugins, or version upgrades are needed. All RNG is handled by GDScript global builtins (`randi_range()`, `randf_range()`) that are already in production use across 7 files in the project.

**Core technologies:**
- `randi_range(min, max)` / `randf_range(min, max)`: Per-hit damage rolling — global GDScript builtins, already proven across `affix.gd`, `forge_hammer.gd`, `loot_table.gd`, `defense_calculator.gd`; 1.25-4x faster than `randi() % range` equivalent
- Two flat int/float properties (`damage_min`, `damage_max`): Range storage pattern — matches existing `Affix.min_value`/`max_value` convention; serializes cleanly with existing `to_dict()`/`from_dict()` pattern
- `StatCalculator.calculate_damage_range()` (new static method): Aggregate total damage range — returns `Vector2i(total_min, total_max)` for combat rolling and UI display
- `ELEMENT_VARIANCE` constants dictionary in `PackGenerator`: Element-specific spread ratios — Physical tight, Lightning extreme; centralized lookup by element string

**Do not add:** `RandomNumberGenerator` class instances (adds state management; globals are identical output and already proven), `Vector2i` as a Resource property (no serialization precedent; Affix uses two flat properties), separate `DamageRangeCalculator` class (splits from StatCalculator), or float affix values (existing affixes use `int` throughout).

### Expected Features

**Must have (table stakes) — v1.4 scope:**
- Weapon base damage as min-max range — every ARPG expresses weapon damage as "X-Y"; a single scalar reads as a prototype
- Per-hit damage rolling in CombatEngine — per-hit variance is what makes combat feel alive vs. pure expected-value math
- Flat damage affixes storing add_min / add_max — rolled per-hit at combat time, not at item generation; ARPG standard "Adds X to Y"
- DPS display using average `(min+max)/2` — players need a stable number for gear comparison; confirmed by Diablo 4 and Guild Wars 2
- Item tooltips show "X to Y" damage range — both floor and ceiling communicate weapon identity
- Element-specific variance ratios — Lightning is "spiky and extreme" (PoE: "1 to 1000"); Physical is consistent; genre convention
- Monster damage ranges — static scalar `pack.damage` reads as unpolished; roll per-hit from range in `_on_pack_attack()`

**Should have (competitive, post-v1.4):**
- Element variance hint in tooltip ("High variance" / "Consistent") — makes the variance system legible without numeric inspection
- Per-element DPS breakdown in Hero View (Physical/Fire/Cold/Lightning separately)
- Min/Max DPS shown alongside average DPS on hero stats panel

**Defer (v2+):**
- Lucky/Unlucky damage rolls (PoE mechanic) — only valuable if status ailments are added; otherwise pure complexity
- Damage range visualization (histogram/bar) — heavy UI investment for minimal idle-game return

### Architecture Approach

All changes are modifications to existing files — no new components required. The architecture follows a layered pattern: data model resources (Weapon, Affix, MonsterPack) hold range fields, StatCalculator aggregates them with dual accumulators, Hero caches the totals, and CombatEngine performs the actual per-hit rolls. The DefenseCalculator interface is completely unchanged — it receives a single pre-rolled float, preserving clean separation of concerns.

**Major components and their changes:**
1. **Affix** — `min_value`/`max_value` reinterpreted as damage range boundaries for FLAT_DAMAGE affixes; separate template fields (`dmg_min_lo`, `dmg_min_hi`, `dmg_max_lo`, `dmg_max_hi`) needed for re-roll correctness; `value` becomes avg for DPS display only
2. **Weapon** — `base_damage: int` splits to `base_damage_min` + `base_damage_max`; `base_damage` becomes a computed average property for backward compat; `update_value()` caches `damage_range: Vector2i`
3. **StatCalculator** — new `calculate_damage_range()` static method returning `Vector2i`; `calculate_dps()` updated to use dual accumulators (`total_min` and `total_max` accumulated independently, percentage multipliers applied to each end)
4. **Hero** — adds `total_damage_min: float` and `total_damage_max: float` populated by `calculate_dps()`; not serialized (recalculated after load)
5. **CombatEngine** — hero attack replaces `total_dps / attack_speed` with `randf_range(total_damage_min, total_damage_max)`; pack attack rolls from `pack.damage_min/max` before passing to DefenseCalculator
6. **MonsterPack / PackGenerator** — `damage: float` extended to `damage_min` + `damage_max`; element variance applied in `PackGenerator._get_element_variance(element)` helper; MonsterType unchanged
7. **SaveManager** — SAVE_VERSION bumped to 2; `_migrate_v1_to_v2()` converts old `value` to degenerate `[value, value]` range preserving all existing DPS
8. **forge_view** — weapon shows "Damage: X-Y"; flat damage affixes show "Adds X to Y"; hero stats adds "Hit Range: X-Y"; `is_item_better()` switches to DPS comparison for weapons

**Build order (critical path):** Affix template convention → Weapon fields → StatCalculator → Weapon.update_value() → Hero fields → CombatEngine → UI display. MonsterPack changes are parallel to the critical path.

### Critical Pitfalls

1. **Save migration skipped — existing saves load with 0 flat damage silently** — Write `_migrate_v1_to_v2()` before changing any Affix fields; bump `SAVE_VERSION` to 2; convert old `value` to degenerate `[value, value]` range; validate with a v1 fixture save (DPS must be identical after migration)

2. **Stat aggregation collapses range too early (percentage multipliers applied to average)** — Run two separate accumulator loops through all aggregation steps; apply multipliers to each independently; verify: base 10-20 with "+100% damage" must show 20-40, not 30-30

3. **Affix Tuning Hammer re-rolls corrupt range (rolled fields used as template)** — Add distinct template fields (`dmg_min_lo`, `dmg_min_hi`, `dmg_max_lo`, `dmg_max_hi`) separate from rolled result fields; reroll always uses template bounds, not current rolled values; test with 20 consecutive re-rolls and assert max never collapses toward min

4. **CombatEngine never updated — tooltip shows range but every hit is identical** — After each data layer change, verify `CombatEngine._on_hero_attack()` uses `randi_range(total_damage_min, total_damage_max)` not the old `total_dps / speed`; test: 10 consecutive hits must show nonzero variance

5. **Lightning variance ratio causes unfair idle-game deaths** — Define variance ratios on paper before coding: Physical 1:1.5 (10-15), Cold 1:2 (8-16), Fire 1:2.5 (6-15), Lightning 1:4 (5-20); model survivability as mean + 2-sigma not mean alone; simulate 100 fights vs lightning pack before finalizing ratios

6. **UI label overflow clips damage range strings** — Switch `item_stats_label` from Label to RichTextLabel with autowrap, or use abbreviated "Phys Dmg: 10-45" format; test at 1280x720 with longest possible lightning affix string before connecting live data

7. **`is_item_better()` discards high-DPS high-variance weapons** — Replace `new_item.tier > existing_item.tier` with `new_item.dps > existing_item.dps` for weapons and rings; tier comparison is no longer monotonically correct once base rolls vary

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Save Migration Foundation
**Rationale:** Migration must precede all Affix schema changes. Writing it last is a recovery-cost HIGH pitfall — if deployed without migration, player saves load with zero flat damage and cannot be recovered after the fact. This is a non-negotiable first step.
**Delivers:** `SAVE_VERSION` bumped to 2; `_migrate_v1_to_v2()` implemented in `save_manager.gd`; Affix template field structure defined (4 fields); migration verified against a v1 fixture save with DPS assertion
**Addresses:** Pitfall 1 (silent save corruption), Pitfall 3 (Affix template field structure established here before rolling)
**Avoids:** Needing a third SAVE_VERSION bump if Affix schema is restructured mid-implementation

### Phase 2: Data Model — Weapon, Affix, and Element Variance
**Rationale:** All downstream code (StatCalculator, CombatEngine, UI) depends on `base_damage_min`/`base_damage_max` on Weapon and the range field convention on Affix being stable. Build data model before consumers.
**Delivers:** Weapon with `base_damage_min`/`base_damage_max` and computed `base_damage` property; Affix with template fields and rolled result fields; `LightSword._init()` updated; all affix pool definitions in `item_affixes.gd` updated with element-appropriate spreads; element variance ratios defined as constants; Tuning Hammer `reroll()` updated to use template fields
**Addresses:** Weapon base damage range (table stakes), element-specific variance ratios (table stakes), affix "Adds X to Y" data model (table stakes)
**Avoids:** Pitfall 3 (range collapse on re-roll), Pitfall 5 (lightning balance — ratios validated on paper here before encoding)

### Phase 3: StatCalculator — Dual-Accumulator DPS and Range Aggregation
**Rationale:** StatCalculator is the math core. Getting the dual-accumulator wrong breaks all display and balance. Implement and verify in isolation before wiring into combat.
**Delivers:** `StatCalculator.calculate_damage_range()` returning `Vector2i`; `calculate_dps()` with dual-accumulator pattern accepting `base_min`/`base_max`; `Weapon.update_value()` updated; DPS formula verified via simulation (10,000-hit average within 2% of sheet DPS)
**Implements:** Average-for-DPS / Roll-for-Combat pattern; Range Propagation via Min/Max Pair Accumulation; element multipliers scale both ends proportionally
**Avoids:** Pitfall 2 (wrong DPS representative value), Pitfall 6 (percentage multipliers collapsing range)

### Phase 4: Monster Pack Ranges (Parallel Track)
**Rationale:** MonsterPack range changes are independent of the hero/weapon critical path. Can be built after Phase 2 without waiting for Phases 3, 5. Touches only `monster_pack.gd`, `pack_generator.gd`, and `combat_engine._on_pack_attack()`.
**Delivers:** `MonsterPack.damage_min`/`damage_max`; `PackGenerator._get_element_variance()` helper with element lookup table; `_on_pack_attack()` rolls per-hit from range before passing to DefenseCalculator
**Addresses:** Monster damage range (table stakes)
**Avoids:** Anti-pattern of adding variance inside DefenseCalculator (variance stays in PackGenerator; DefenseCalculator interface unchanged)

### Phase 5: Hero Range Fields and CombatEngine Per-Hit Rolling
**Rationale:** Hero acts as the caching layer between Weapon data and CombatEngine. CombatEngine depends on `hero.total_damage_min/max` being populated by `calculate_dps()`. This is the phase where per-hit variance becomes visible in combat.
**Delivers:** `Hero.total_damage_min`/`total_damage_max` populated by `calculate_dps()`; `CombatEngine._on_hero_attack()` replaced with `randf_range(total_damage_min, total_damage_max)` roll; integration verified by watching 10 consecutive hits and asserting nonzero standard deviation
**Addresses:** Per-hit rolling (table stakes)
**Avoids:** Pitfall 4 (combat still using deterministic `total_dps / attack_speed` after UI appears correct)

### Phase 6: UI Display — Range Strings and Item Comparison Fix
**Rationale:** UI is the last layer; all data must be correct before display. The `is_item_better()` fix must ship alongside display so players do not lose better drops during the transition window.
**Delivers:** `forge_view` weapon shows "Damage: X-Y"; flat damage affixes display "Adds X to Y"; hero stats shows "Hit Range: X-Y"; `is_item_better()` uses DPS comparison for weapons and rings; Label nodes switched to RichTextLabel with autowrap; tested at 1280x720 with longest lightning affix string
**Addresses:** Item tooltip display, DPS average display, hero stat panel range — all v1.4 table-stakes features
**Avoids:** Pitfall 7 (label overflow), Pitfall 8 (auto-discard of better high-variance weapon)

### Phase Ordering Rationale

- Save migration before schema changes is non-negotiable; this ordering prevents unrecoverable player save corruption
- Data model before math: StatCalculator cannot compute ranges until Weapon and Affix expose them
- Math before combat: CombatEngine needs `Hero.total_damage_min/max` which StatCalculator must populate
- Monster ranges (Phase 4) are parallel to the hero critical path and can execute after Phase 2 without blocking Phases 3, 5
- UI last: display strings are cosmetic; broken display does not corrupt data, but broken math corrupts display invisibly
- The Affix template field structure must be finalized in Phase 1 (migration schema) before Phase 2 adds those fields — these two phases should be tightly coordinated or merged into one atomic commit

### Research Flags

Phases with standard patterns (skip additional research-phase):
- **Phase 1 (Save Migration):** Migration hook already exists in `save_manager.gd:159`; v1-to-v2 degenerate-range migration is straightforward; no novel research needed
- **Phase 4 (Monster Pack Ranges):** Simple data model extension; single call site in CombatEngine; element variance table is a design decision, not a research question
- **Phase 6 (UI Display):** Standard GDScript string formatting; Label-to-RichTextLabel switch is documented; `is_item_better()` is a one-line fix

Phases that benefit from pre-plan review before execution:
- **Phase 2 (Affix Data Model):** The Tuning Hammer re-roll template field structure (4 fields vs 2) is the trickiest design decision in the milestone. Specify the exact field names, serialization keys, and tier-scaling formula before coding begins.
- **Phase 3 (StatCalculator):** The dual-accumulator math should be spec'd with test vectors on paper before implementation to catch Pitfall 6 early. Include a verification simulation (10,000 hits) in the phase plan.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All RNG patterns verified directly against 7 codebase files; no new technology; Godot 4.5 stable API confirmed |
| Features | HIGH | PoE Wiki, Diablo 2/4 docs, Guild Wars 2 Wiki all confirm table stakes; per-hit rolling and "Adds X to Y" are genre constants across 4 independent references |
| Architecture | HIGH | Based on direct code analysis of all 10 modified files; data flow traced end-to-end through 4 distinct flows; build order validated by dependency graph |
| Pitfalls | HIGH | 7 of 8 pitfalls identified via direct codebase analysis (not speculation); save migration confirmed against live `save_manager.gd:159`; Affix re-roll issue confirmed at `affix.gd:36-47` |

**Overall confidence:** HIGH

### Gaps to Address

- **Element variance ratios are design decisions, not facts:** The specific ratios (Physical 1:1.5, Lightning 1:4) are informed by PoE/Diablo conventions and survivability modeling but are not externally validated for Hammertime's combat pacing. Validate by simulating 100 fights per element after Phase 5 before finalizing Phase 6.

- **Affix pool values in `item_affixes.gd` not fully specified:** Research documents that all affix templates need element-appropriate spreads but does not enumerate exact values for all 7 hammer types across all tiers. Phase 2 must include an explicit balance pass on affix `dmg_min_lo`/`dmg_max_hi` values.

- **Ring comparison in `is_item_better()`:** The pitfall identifies the bug for weapons; ring comparison logic was not fully analyzed. Phase 6 should audit both weapon and ring paths.

- **Variable vs fixed base weapon ranges:** Research assumes LightSword base ranges are fixed per class (reconstructible from `_init()`, no serialization needed). If future weapons have randomized base ranges, `Item.to_dict()` must serialize `base_damage_min`/`max`. Confirm this assumption holds before Phase 1.

## Sources

### Primary (HIGH confidence — direct codebase analysis)
- `models/affixes/affix.gd` — `randi_range()` at lines 32, 38, 46; `min_value`/`max_value` serialization; `to_dict()`/`from_dict()` save pattern; `reroll()` at line 46
- `models/combat/combat_engine.gd` — Per-hit crit roll at line 83; `damage_per_hit` calculation at line 80
- `models/stats/stat_calculator.gd` — `base_damage: float` parameter; DPS accumulator loop at lines 22-30
- `models/items/weapon.gd` — `base_damage: int` field; `update_value()` call to StatCalculator
- `models/monsters/monster_pack.gd` — `damage: float` scalar field
- `models/monsters/pack_generator.gd` — `create_pack()` damage assignment
- `autoloads/save_manager.gd` — `SAVE_VERSION = 1`; `_migrate_save()` stub at line 159
- `scenes/forge_view.gd` — `is_item_better()` at line 466; stat display string patterns; Label node types

### Secondary (HIGH confidence — official game documentation)
- [PoE Wiki: Damage](https://www.poewiki.net/wiki/Damage) — Per-hit rolling confirmed; lightning variance identity documented
- [PoE Wiki: Flat Damage](https://www.poewiki.net/wiki/Flat_damage) — "Adds X to Y" format; DPS = (min+max)/2 formula
- [Diablo Wiki: Lightning Damage](https://diablo.fandom.com/wiki/Lightning_(Damage)) — Extreme variance identity: "1 to 2000" documented explicitly
- [Diablo 4: DPS Calculation](https://www.diablowiki.net/Damage_Per_Second) — `avg(min, max) * attacks/sec` formula confirmed
- [Guild Wars 2: Damage Calculation](https://wiki.guildwars2.com/wiki/Damage_calculation) — Midpoint-of-range for tooltip DPS; per-hit random draw confirmed

### Tertiary (MEDIUM confidence)
- [Godot Forum: Min-Max Export Variables](https://forum.godotengine.org/t/how-to-create-a-min-max-export-variable/129415) — Two flat properties preferred over Vector2 for inspector clarity
- [Godot Issue #89795: randi() vs randi_range() performance](https://github.com/godotengine/godot/issues/89795) — `randi_range()` 1.25-4x faster
- [Last Epoch: Damage Variance Explained](https://maxroll.gg/last-epoch/resources/damage-explained) — Idle-game variance survivability modeling
- [You Smack the Rat for ??? Damage — Margaris](https://jmargaris.substack.com/p/you-smack-the-rat-for-damage) — Variance design fairness in idle games

---
*Research completed: 2026-02-18*
*Ready for roadmap: yes*
