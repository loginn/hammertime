# Project Research Summary

**Project:** Hammertime v1.7 — Meta-Progression, Item Tiers, Affix Tier Expansion, Tag-Targeted Currencies
**Domain:** Godot 4.5 Idle ARPG — Prestige Reset Loop on existing v1.6 codebase
**Researched:** 2026-02-20
**Confidence:** HIGH

## Executive Summary

Hammertime v1.7 adds a prestige meta-progression loop to a well-established Godot 4.5 GDScript codebase. The recommended approach treats the four feature areas (prestige system, item tier gating, affix tier expansion 8->32, tag-targeted currencies) as clean extensions to existing architectural seams rather than replacements. Every required extension point already exists: `GameState` holds run state, `SaveManager` has a version-gated migration chain, `Affix.tier_range` is already a `Vector2i` that accepts any max value, and `Currency._do_apply()` is a template method ready for new subclasses. The core technical recommendation is to introduce one new autoload (`PrestigeManager`) as a stateless domain service — consistent with the existing `StatCalculator`/`DefenseCalculator` pattern — and to increment the save format from v2 to v3 with additive-only migration.

The recommended build sequence is data-shape first, persistence second, logic third, UI last. The critical dependency chain is: `PrestigeManager` autoload -> `GameState` new fields -> `Item.item_tier` field -> `Item.add_prefix/suffix` using `PrestigeManager.get_affix_tier_range()`. Save migration (`SaveManager` v2->v3) can be developed in parallel with that chain and must be completed before any prestige gameplay code ships. The `LootTable` item tier rolling and tag hammer currency subclasses follow after those foundations, with `ForgeView` UI wiring last as the integration layer.

The top risks are: (1) accidentally calling `initialize_fresh_game()` from the prestige path, which silently nukes prestige-persistent state; (2) shipping the affix tier expansion without normalizing tier-as-quality comparisons, making old and new items incomparable; and (3) setting the tag hammer drop rate or cost wrong relative to existing Runic/Forge expected value, causing the new hammers to either obsolete the old ones or be ignored entirely. All three risks have explicit prevention patterns documented in the research and can be caught with targeted verification tests before each phase ships.

---

## Key Findings

### Recommended Stack

The full technology stack is unchanged from v1.6. Godot 4.5, GDScript, and the existing JSON-via-`SaveManager` persistence model are all in production and require no version changes. The four new feature areas map to existing GDScript built-ins: `Dictionary.get(key, default)` for safe prestige field access, `Array[Affix]` explicit for-loops (not `Array.filter()` which returns untyped arrays in Godot 4), `pick_random()` already used in `Item.add_prefix()`, and `Vector2i(x, y)` already the type for `Affix.tier_range`. No new dependencies, no engine version change, no new serialization format.

**Core technologies:**
- **Godot 4.5 / GDScript:** Already in production. No change. `@abstract` annotation (new in 4.5) is NOT recommended — keep the existing template-method pattern with `pass` in base `_do_apply()`.
- **Resource system (Item, Affix, Hero, Currency):** No changes to the class hierarchy. Add fields, not classes.
- **JSON via `SaveManager`:** Increment to SAVE_VERSION = 3. Migration is additive-only (new prestige keys injected with safe defaults). The `HT1:base64:md5` export string format is unchanged — the inner JSON gains new keys.
- **GDScript explicit for-loops for typed arrays:** `Array.filter()` returns untyped `Array` in Godot 4 (confirmed via GitHub issue #82538). All affix filtering must use explicit typed for-loops, which is already the pattern in `Item.add_prefix()`.

### Expected Features

**Must have (table stakes):**
- **Prestige currency grant on reset** — Every idle prestige system awards persistent currency; without it the loop breaks
- **Full run reset on prestige** — Area level, hero equipment, crafting inventory, and all standard currencies reset; prestige level and tier unlocks survive
- **Visible prestige cost and unlock summary before commit** — Players must see what they gain AND what they lose before pressing the button
- **Permanent unlock that persists across resets** — Item tier ceiling increases per prestige level; this is the core reward
- **Confirmation dialog** — Two-step prestige: consequence summary then confirm button
- **Prestige level display** — Players need to always know their prestige level

**Should have (competitive differentiators):**
- **Item tier gating as prestige reward** — 8 item tiers; prestige level unlocks the ceiling (P0=T1, P1=T2, ..., P7=T8). Qualitative reward rather than a multiplier.
- **32-tier affix system** — 4 affix tiers per item tier band; creates granular visible upgrade paths. Affix tier 1 = best, tier 32 = weakest (matching existing convention).
- **Tag-targeted crafting hammers at Prestige 1** — FireHammer, ColdHammer, LightningHammer, DefenseHammer. Guaranteed element tag with tier still random within item tier's allowed range. Same design leap as PoE2 Omens, simplified for idle context.
- **Area-level-weighted item tier drops** — Low areas favor lower tiers within unlocked range; high areas favor the ceiling. Uses the sqrt/gaussian ramp pattern already in `LootTable`.
- **Prestige unlock table display** — All 7 prestige levels listed with unlocks; current highlighted, future shown as locked.

**Defer (v2+):**
- Stat-targeted hammers (out of scope per PROJECT.md)
- Outcome-locking hammers (out of scope per PROJECT.md)
- Hero archetypes (explicitly deferred to post-prestige milestone)
- Prestige-exclusive biome (future milestone)
- Post-prestige drop rate bonus (only if playtesting reveals re-progression feels too slow)

**Anti-features (explicitly excluded):**
- Gear persisting through prestige — defeats the power-rush emotional arc
- Partial prestige resets — undermine the full-reset psychological impact
- Chaos-style full affix rerolls on prestige items — excluded in existing design
- Visual item tier indicators in inventory slot list — mobile viewport constraint

### Architecture Approach

The architecture introduces one new autoload (`PrestigeManager`) as a stateless domain service following the `StatCalculator`/`DefenseCalculator` pattern. It holds cost tables, tier mappings, and reset execution logic but holds no mutable state — all state lives in `GameState`. Tag currencies are kept in a separate `tag_currency_counts` dictionary on `GameState` rather than merged into `currency_counts`, which prevents the existing currency loops (debug override, drop gating, display) from needing prestige-awareness special-casing. The affix tier constraint is applied at construction time inside `Item.add_prefix/suffix` using `PrestigeManager.get_affix_tier_range(item.item_tier)` — a derived value, not stored redundantly on the item.

**Major components:**
1. **`autoloads/prestige_manager.gd` (NEW)** — `PRESTIGE_COSTS` array, `ITEM_TIERS_BY_PRESTIGE` array, `can_prestige()`, `execute_prestige()`, `_wipe_run_state()`, `get_affix_tier_range(item_tier)`. Pure logic; zero UI dependency.
2. **`autoloads/game_state.gd` (MODIFIED)** — Adds `prestige_level: int`, `max_item_tier_unlocked: int`, `tag_currency_counts: Dictionary`. `initialize_fresh_game()` updated. `spend_tag_currency()` added.
3. **`autoloads/save_manager.gd` (MODIFIED)** — SAVE_VERSION = 3; `_migrate_v2_to_v3()` injects prestige field defaults; `_build_save_data()` and `_restore_state()` updated; `prestige_completed` signal connected.
4. **`autoloads/item_affixes.gd` (MODIFIED)** — All `Vector2i(1, 8)` weapon affix tier ranges expanded to `Vector2i(1, 32)`. `base_min`/`base_max` values retuned for 32-tier balance.
5. **`models/items/item.gd` (MODIFIED)** — Adds `item_tier: int = 1` field. `add_prefix()`/`add_suffix()` use `PrestigeManager.get_affix_tier_range(item_tier)` to constrain affix construction. `to_dict()`/`create_from_dict()` updated.
6. **`models/currencies/tag_hammer.gd` + 4 subclasses (NEW)** — `TagHammer extends Currency` with `required_tag: String`. `can_apply()` checks rarity, slot availability, AND tag pool availability. `_do_apply()` filters `ItemAffixes` by tag and constructs affix with item-tier-constrained range.
7. **`models/loot/loot_table.gd` (MODIFIED)** — `roll_item_tier(area_level, max_item_tier_unlocked)` static method with gaussian-like area band weighting. Tag currency drops added, gated on `GameState.prestige_level >= 1`.
8. **`scenes/forge_view.gd` (MODIFIED)** — Prestige UI panel (cost, unlock table, confirm button). Tag hammer button row visible only at `prestige_level >= 1`.
9. **`autoloads/game_events.gd` (MODIFIED)** — `prestige_completed(new_level: int)` and `tag_currency_dropped(drops: Dictionary)` signals added.

**Unchanged (confirmed):** `Affix` class structure, `Currency` template method, `StatCalculator`, `DefenseCalculator`, `CombatEngine`, `BiomeConfig`, `PackGenerator`, `Hero.update_stats()`, all existing hammer subclasses, all existing `GameEvents` signals.

### Critical Pitfalls

1. **Prestige wipes prestige-persistent state via `initialize_fresh_game()`** — `PrestigeManager._wipe_run_state()` must be a distinct function that only clears the RESETS list (area, gear, inventory, currencies). `initialize_fresh_game()` must NEVER be called from the prestige path. Write the RESETS/PERSISTS table as a comment block at the top of `_wipe_run_state()` before writing any code. Add a post-prestige assertion: `prestige_level == old_level + 1`.

2. **Save migration v2->v3 omits prestige field defaults, corrupting old saves** — Write `_migrate_v2_to_v3()` first, before touching `_build_save_data()` or `_restore_state()`. Inject `"prestige_level": 0`, `"max_item_tier_unlocked": 1`, `"tag_currencies": {all zeros}` as defaults. Test with a hand-crafted v2 fixture JSON — assert `prestige_level == 0` and all items load correctly.

3. **Affix tier expansion breaks cross-range tier comparisons** — Before expanding tier ranges, add a `quality() -> float` normalizer to `affix.gd`: `(tier_range.y + 1 - tier) / float(tier_range.y)`. Replace all direct `affix.tier` quality comparisons with `affix.quality()`. Old 8-tier saved affixes and new 32-tier affixes will then compare correctly regardless of range.

4. **Tag hammers either obsolete existing hammers or are never worth using** — Calculate expected Runic hammer rolls needed to hit the target tag before setting tag hammer cost/rarity. Tag hammers guarantee the tag; tier is still random within item-tier-allowed range. Drop rate must be lower than Runic/Forge.

5. **Item tier expansion lowers the pre-prestige floor, making existing player gear feel worse** — Before shipping: create v1.6 and v1.7 pre-prestige items with the same affix at equivalent tier positions; values must be within 10% of each other. The expansion adds ceiling, not lowers floor.

---

## Implications for Roadmap

Based on the architecture research's explicit build order (Phases A through L) and the pitfall-to-phase mapping, the following phase structure is recommended:

### Phase 1: Foundation — PrestigeManager + GameState + Signals

**Rationale:** All subsequent phases depend on `PrestigeManager` (provides tier mappings and prestige logic) and the `GameState` new fields (`prestige_level`, `max_item_tier_unlocked`, `tag_currency_counts`). These have zero UI dependencies and are unit-testable in isolation. Signals must exist before any scene wires handlers. Writing `_wipe_run_state()` here with an explicit RESETS/PERSISTS table comment block prevents Pitfall 1 from ever manifesting.
**Delivers:** `PrestigeManager` autoload with full cost table and tier mappings; `GameState` prestige fields; `GameEvents` new signals; `initialize_fresh_game()` updated; `spend_tag_currency()` added; `MAX_PRESTIGE_LEVEL` defined as a data constant.
**Addresses:** Prestige system core, table stakes (prestige level persist, full reset scope defined).
**Avoids:** Pitfall 1 (prestige wipes prestige data), Pitfall 13 (ceiling hard-coded rather than constant).

### Phase 2: Save Migration v3 (Parallel-safe with Phase 1)

**Rationale:** Save migration must be written and tested before any gameplay code is built on the new prestige fields. Writing it first ensures old player saves load correctly from day one of development, not as a last-minute fix. This phase can run in parallel with Phase 1 since both only add new fields to existing structures.
**Delivers:** `SAVE_VERSION = 3`; `_migrate_v2_to_v3()` with all prestige field defaults; `_build_save_data()` and `_restore_state()` updated; `prestige_completed` signal connected to auto-save trigger; v2 fixture test confirmed.
**Avoids:** Pitfall 2 (migration omits prestige defaults).

### Phase 3: Affix Tier Expansion (8 -> 32) + Quality Normalization

**Rationale:** The `item_tier` field and affix tier constraint in Phase 4 depend on the 32-tier system being in place. Expanding tiers before adding the item tier constraint prevents a window where items can roll any affix tier regardless of item quality. Quality normalization (`affix.quality()`) must land before the expansion ships to prevent cross-range comparison bugs. A balance pass on `base_min`/`base_max` values is part of this phase.
**Delivers:** `affix.quality() -> float` helper on `affix.gd`; all `item_affixes.gd` tier ranges expanded to `Vector2i(1, 32)`; `base_min`/`base_max` values retuned; affix display updated to `tier/max_tier` format; v1.6 vs v1.7 value floor comparison verified within 10%.
**Avoids:** Pitfall 3 (tier comparison broken after expansion), Pitfall 6 (pre-prestige floor lowered), Pitfall 11 (tier display context lost after expansion).

### Phase 4: Item Tier System — Drop Rolling + Affix Constraint

**Rationale:** With `PrestigeManager` and 32-tier affixes in place, item tier can be wired end-to-end. This is the critical path phase that ties prestige level to actual gameplay power — items are now qualitatively different across prestige levels, not just quantitatively scaled.
**Delivers:** `Item.item_tier` field with serialization (default 8 for old saves); `LootTable.roll_item_tier()` with area-level gaussian weighting; `Item.add_prefix/suffix` using constrained affix construction via `PrestigeManager.get_affix_tier_range(item_tier)`; `gameplay_view` item drop creation sets `item_tier`; `is_item_better()` updated for `item_tier` field name.
**Avoids:** Pitfall 9 (tag hammers bypass item tier constraint — constraint is in `add_prefix/suffix` which tag hammers also call).

### Phase 5: Tag-Targeted Currency Subclasses

**Rationale:** Tag hammers depend on `PrestigeManager.get_affix_tier_range()` (Phase 1) and the constrained affix rolling in `Item.add_prefix/suffix` (Phase 4). New files only — no modification to existing currency classes. `can_apply()` must be complete (rarity + slot availability + tag pool check) before wiring to UI. Expected-value calculation vs. Runic/Forge is a prerequisite to setting drop rates.
**Delivers:** `tag_hammer.gd` abstract base; `fire_hammer.gd`, `cold_hammer.gd`, `lightning_hammer.gd`, `defense_hammer.gd`; tag currency drop rules in `LootTable` gated on `prestige_level >= 1`; expected-value calculation vs. Runic/Forge documented before drop rates are set.
**Avoids:** Pitfall 4 (tag hammers too strong or too narrow), Pitfall 12 (`can_apply()` incomplete — full three-condition check required).

### Phase 6: Prestige UI + Integration

**Rationale:** UI is the integration layer and depends on all mechanics being functional. The confirmation dialog must show cost, reward, AND what resets before shipping. Tag hammer buttons gate on `GameState.prestige_level >= 1` — a display concern, not a currency class concern.
**Delivers:** Prestige panel in `ForgeView` (prestige level, cost display, unlock table, confirm button); tag hammer button row visible at `prestige_level >= 1`; post-prestige consequence summary overlay; prestige progress indicator in main UI; two-step confirmation flow matching the existing equip confirmation pattern.
**Avoids:** Pitfall 7 (reset scope ambiguity — confirmation dialog explicitly lists what resets), Pitfall 8 (UI hides cost or benefit — all three elements required before trigger fires).

### Phase 7: Integration Verification

**Rationale:** All six preceding phases touch different parts of the codebase. End-to-end verification before milestone sign-off catches integration bugs that unit tests in isolation cannot. The PITFALLS.md "Looks Done But Isn't" checklist provides 12 specific verification conditions.
**Delivers:** Full prestige flow validated (fresh game -> prestige 1 -> post-prestige item drops at new tier -> tag hammers available -> prestige 2); save round-trip verified at each stage; v2 save migration verified with fixture file; affix value floor verified against v1.6 baseline; all 12 checklist items passed.
**Addresses:** All 13 pitfall verification conditions.

### Phase Ordering Rationale

- **Foundation before persistence:** `PrestigeManager` and `GameState` fields must exist before `SaveManager` can reference them in `_build_save_data()`.
- **Migration before gameplay:** Phase 2 (save migration) is explicitly safe in parallel with Phase 1 and must be done before Phase 3 starts modifying how items are built — any gameplay change that produces new data formats must have a migration path ready.
- **Tier expansion before item tier gating:** Phase 3 expands the affix tier range to 32 before Phase 4 adds the constraint that limits which tiers an item can access. This prevents a window where all items accidentally access tiers 1-32 with no gating.
- **Currency logic before UI:** Phases 1-5 build mechanics; Phase 6 wires UI. This follows the existing project pattern — `ForgeView` is a display layer over `GameState`/`Currency`/`LootTable` logic.
- **Pitfall avoidance embedded in phase scope:** Each phase's deliverables include the specific anti-corruption guard identified in pitfall research (RESETS/PERSISTS table, `quality()` normalization, expected-value calculation for tag hammer balance).

### Research Flags

Phases needing deeper research or pre-implementation analysis during planning:
- **Phase 3 (Affix Tier Expansion):** The `base_min`/`base_max` retuning for 32 tiers is a balance pass. The research documents the formula (`value = base_max * (tier_range.y + 1 - tier)`) but the specific base values need derivation from a target power curve. Plan time for a balance pass before implementation.
- **Phase 5 (Tag-Targeted Currencies):** The expected-value calculation (how many Runic rolls to hit the target tag without the hammer) requires counting tag composition of `item_affixes.gd` prefixes per item type. This is a pre-implementation data audit, not a code question.
- **Phase 7 (Integration Verification):** The v2 fixture test requires constructing a hand-crafted JSON save file accurately representing the current v2 save schema. Build this artifact before declaring migration correct.

Phases with well-documented patterns (standard implementation, skip research-phase):
- **Phase 1 (PrestigeManager):** Follows the exact `StatCalculator` pattern already in the codebase. No external research needed.
- **Phase 2 (Save Migration):** The v1->v2 migration chain is already in `save_manager.gd`. Phase 2 adds one link to an established chain.
- **Phase 4 (Item Tier System):** All methods and data flow specified in ARCHITECTURE.md with production-ready GDScript. Implement from spec.
- **Phase 6 (Prestige UI):** The tab-based view pattern is established (`ForgeView`, `GameplayView`, `SettingsView`). No new UI architecture.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All patterns verified against existing codebase. No external dependencies. GDScript built-ins confirmed against Godot 4.5 API. One known constraint: `Array.filter()` returns untyped arrays — use for-loops (GitHub issue #82538 confirmed). |
| Features | MEDIUM | Table-stakes list (ARPG idle conventions) is MEDIUM — multiple community sources agree but not official specs. ARPG affix tier patterns are HIGH — Last Epoch official dev posts. Tag-targeted crafting design is MEDIUM — PoE2 community analysis. |
| Architecture | HIGH | Based on direct analysis of all affected source files. Component boundaries, data flow diagrams, and build order all derived from reading the actual code. Autoload order dependency (PrestigeManager after GameState) confirmed. |
| Pitfalls | HIGH | All 8 critical pitfalls grounded in specific file paths and line numbers in the existing codebase. Balance pitfalls (tag hammer tuning, prestige cost curve) are MEDIUM — based on ARPG design literature with no Hammertime-specific playtest data. |

**Overall confidence:** HIGH

### Gaps to Address

- **Tag hammer balance numbers:** The expected-value calculation (Runic rolls to target tag) requires counting tag distribution in `item_affixes.gd` per item slot. This calculation must be done before setting tag hammer drop rates. Research identified the formula; the data audit is the open step.
- **Affix base value retuning:** The research confirms the formula for 32-tier scaling and documents that tier-1 values will be ~4x higher in the new system (by design — prestige players earn stronger items). The specific `base_min`/`base_max` values in `item_affixes.gd` need a balance pass to ensure (a) tier-32 values are not zero or negative, and (b) the pre-prestige floor matches v1.6 within 10%.
- **Prestige cost curve calibration:** The architecture research provides starting cost values (`{"grand": 50, "claw": 25, "tuning": 10}` for P0->P1, escalating). The feature research identifies the target session-time model (P1 achievable in 2-4 hours, P7 in 5-10 sessions). These must be reconciled against actual `LootTable` drop rates for `grand`/`claw`/`tuning`. A simulation or playtest estimate is needed before finalizing the cost table.
- **`_wipe_run_state()` vs `initialize_fresh_game()` sync risk:** `initialize_fresh_game()` cannot call `PrestigeManager._wipe_run_state()` due to circular dependency at init time. The resolution is to inline the wipe in `initialize_fresh_game()` and keep it synchronized with `_wipe_run_state()` manually. This is a maintenance risk — document the invariant with a comment at both sites.

---

## Sources

### Primary (HIGH confidence — direct codebase analysis)

- `/var/home/travelboi/Programming/hammertime/autoloads/game_state.gd` — `initialize_fresh_game()`, `currency_counts`, `spend_currency()` — prestige reset extension points
- `/var/home/travelboi/Programming/hammertime/autoloads/save_manager.gd` — `_migrate_save()` chain, `_build_save_data()`, `_restore_state()`, `SAVE_VERSION` — v3 migration pattern
- `/var/home/travelboi/Programming/hammertime/models/affixes/affix.gd` — `tier_range: Vector2i`, constructor scaling formula, `to_dict()`/`from_dict()`
- `/var/home/travelboi/Programming/hammertime/autoloads/item_affixes.gd` — Template definitions with `Vector2i(1, 8)` (offense) and `Vector2i(1, 30)` (defense) confirmed
- `/var/home/travelboi/Programming/hammertime/models/items/item.gd` — `add_prefix()`, `add_suffix()`, `has_valid_tag()`, `is_affix_on_item()` — tag-targeted extension points
- `/var/home/travelboi/Programming/hammertime/models/currencies/runic_hammer.gd` — Template method pattern confirmed: `can_apply()` -> `_do_apply()`
- `/var/home/travelboi/Programming/hammertime/models/loot/loot_table.gd` — `roll_pack_currency_drop()`, `CURRENCY_AREA_GATES`, `_calculate_currency_chance()`
- `/var/home/travelboi/Programming/hammertime/autoloads/tag.gd` — `Tag.FIRE`, `Tag.COLD`, `Tag.LIGHTNING`, `Tag.DEFENSE` string constants confirmed
- `/var/home/travelboi/Programming/hammertime/.planning/PROJECT.md` — v1.7 feature targets: 7 prestige levels, 8 item tiers, 32 affix tiers, tag-targeted hammers at prestige 1

### Secondary (MEDIUM confidence)

- [Introducing Tier 6 and 7 Item Affixes — Last Epoch Dev Blog](https://forum.lastepoch.com/t/introducing-tier-6-and-7-item-affixes/22279) — Granular tier design rationale; cliff vs. ramp player feedback documented
- [The Math of Idle Games, Part III — Kongregate Blog](https://blog.kongregate.com/the-math-of-idle-games-part-iii/) — Prestige currency models (since-reset vs. lifetime); cost curve math
- [PoE 2 Deterministic Crafting — AOEAH](https://www.aoeah.com/news/4116--poe-2-03-guaranteed-mods-crafting-guide--how-to-craft-bis-gear-jewels-rings-weapon-armor) — Tag-family targeted mod addition design
- [Revolution Idle Prestige Guide](https://tap-guides.com/2025/10/24/revolution-idle-prestige-guide/) — Cost balance; persistent upgrade patterns
- [Save game best practices — Meta Horizon docs](https://developers.meta.com/horizon/documentation/unity/ps-save-game-best-practices/) — Chain migrations, version flags, defaults for new fields
- [Array.filter() returns untyped Array — GitHub #82538](https://github.com/godotengine/godot/issues/82538) — Confirmed known issue; use explicit for-loops

### Tertiary (LOW confidence — design inferences)

- Weighted gaussian drop table for item tier (`roll_item_tier` formula) — Original design; the weighted accumulation pattern is verified against `PackGenerator.roll_element()` but specific weight values are design choices requiring playtest validation.
- Prestige cost table starting values in `PrestigeManager` — Reasonable starting point from architecture research; must be calibrated against actual currency drop rates before launch.

---
*Research completed: 2026-02-20*
*Ready for roadmap: yes*
