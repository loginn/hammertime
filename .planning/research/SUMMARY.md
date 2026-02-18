# Project Research Summary

**Project:** Hammertime — Per-Slot Multi-Item Inventory System (v1.5)
**Domain:** Godot 4.5 Idle ARPG — Replacing single-item crafting slots with per-slot arrays (10 items per slot)
**Researched:** 2026-02-18
**Confidence:** HIGH

## Executive Summary

This milestone replaces a single-item-per-slot crafting inventory with a 10-item-per-slot array model. The change is surgical: only 3 files require modification (`game_state.gd`, `save_manager.gd`, `forge_view.gd`), no new autoloads or scenes are needed, and all item data model code (`item.gd`, `hero.gd`, `loot_table.gd`) remains untouched. The core data change — `crafting_inventory` values from `Item | null` to `Array[Item]` — cascades through drop routing, melt/equip flows, display, and serialization. The build order is strict: save migration must be written first, then data model, then logic, then display.

The recommended approach follows established idle ARPG conventions: silent overflow discard at cap, best-item auto-selected for the crafting bench, equip destroys the old equipped item (does not return it to inventory), and the x/10 counter is the sole overflow signal. These conventions are validated against NGU Idle, Melvor Idle, and AFK Journey. All GDScript patterns required (typed arrays, `Array.erase()`, `sort_custom`, JSON round-trip via `to_dict()`/`create_from_dict()`) are already in production use in the codebase; no new APIs or dependencies are introduced.

The primary risk is save format migration. The existing `SAVE_VERSION = 1` format stores a single item dict per slot; the new v2 format stores an array of item dicts per slot. An incomplete migration creates either silent data loss (all crafting items missing after load) or a crash (`Invalid get index '0' on base: 'Nil'`). The mitigation is strict: write `_migrate_v1_to_v2()` and update `_restore_state()` atomically, test with a hand-crafted v1 fixture before touching any other code, and remove the orphaned `crafting_bench_item` field from `GameState` in the same commit.

## Key Findings

### Recommended Stack

No new technologies are introduced. The stack is Godot 4.5 / GDScript with the existing `Dictionary`-of-`Array` pattern for `GameState.crafting_inventory`, and the existing `Item.to_dict()` / `Item.create_from_dict()` JSON serialization contract extended to iterate arrays per slot. All array methods used (`append`, `erase`, `size`, `duplicate`, `sort_custom`) are Godot 4.0+ globals already present in the codebase.

**Core technologies:**
- **GDScript `Array`** — slot inventory container — `append()`, `erase()`, `size()` are O(1) or O(n) for n=10; no external library needed
- **`Dictionary` of `Array`** — keeps the existing `crafting_inventory` key structure; all call sites change minimally from single-item access to array access
- **`JSON.stringify` / `JSON.parse_string`** — already in `save_manager.gd`; `Array[Dictionary]` serializes natively to JSON array without new infrastructure
- **Save version bump to 2** — `_migrate_v1_to_v2()` wraps single-item dicts in arrays, converts nulls to empty arrays, drops the orphaned `crafting_bench_item` key

**Do not add:** External inventory plugins, SQLite, `ResourceSaver` / `.tres` files, `VBoxContainer` + preloaded scene rows for the item list, or `Node`-based item slots. The feature is ~50 lines of GDScript using only built-in types.

### Expected Features

**Must have (table stakes — v1.5 milestone):**
- **Array per slot (10 items max)** — `crafting_inventory[type]` becomes `Array[Item]`; 10-item cap enforced at a single add point via `SLOT_CAPACITY` constant
- **Append on drop, discard on full** — `add_item_to_inventory()` appends if `size < 10`, silently returns if full; the `is_item_better()` auto-replace logic is removed entirely from the drop path
- **Best/highest-tier item auto-selected for bench** — `_load_bench_item()` picks highest DPS (weapon/ring) or highest tier (armor slots) from the array; bench does not auto-switch when the player already has an item being crafted
- **Melt and equip remove from array** — `Array.erase(current_item)` by object reference; `_load_bench_item()` called after to show next-best item
- **x/10 counter per slot** — label updates on every add/melt/equip; reads directly from `array.size()`, never cached
- **Save/load array serialization** — `_build_save_data()` serializes array of dicts; `_restore_state()` rebuilds arrays; v1 migration wraps single items in arrays
- **Slot button disabled when array empty** — guard changes from `!= null` to `.size() > 0`; fresh game starter weapon grant requires the same fix

**Should have (v1.x polish after validation):**
- **x/10 visual urgency at cap** — color or style change when counter reaches 10/10 to signal active discard
- **Drop notification on full slot** — non-blocking indicator when a drop is silently discarded; only if playtesting reveals players miss overflow

**Defer (v2+):**
- **Slot capacity upgrade** — expand beyond 10 via progression unlock; only if item variety grows significantly
- **Loot filter** — not warranted until item type count exceeds 5 or player builds require selective dropping
- **Item browsing in bench** — view all items in a slot rather than just the best; only if best-first heuristic fails players regularly

**Anti-features to exclude:**
- Return old equipped item to inventory on equip — breaks inventory cap bounds and contradicts idle genre behavior; equip destroys the old item
- Auto-equip best item when slot fills — removes the craft decision; keep the explicit equip button
- Per-item drop notification toast — spam for an idle game; x/10 counter is sufficient feedback

### Architecture Approach

The architecture is deliberately minimal: a data-shape change in `GameState` cascades through `SaveManager` (serialization) and `ForgeView` (all logic and display). No new scenes, autoloads, signals, or external components are required. `GameState` holds the ground truth array per slot; `ForgeView` owns all inventory mutation logic and keeps `current_item` as a direct reference into the array — not a copy. The bench item is derived state computed by `_load_bench_item()`, not a separately stored field. `GameState.crafting_bench_item` is a confirmed-orphaned field (never assigned after initialization) and must be removed in this milestone.

**Major components:**
1. **`autoloads/game_state.gd`** (modified) — `crafting_inventory` values `null` → `[]`; `initialize_fresh_game()` initializes empty arrays; `crafting_bench_item` field removed
2. **`autoloads/save_manager.gd`** (modified) — `_migrate_v1_to_v2()` wraps single items in arrays; `_build_save_data()` serializes arrays; `_restore_state()` deserializes arrays; `SAVE_VERSION` bumped to 2
3. **`scenes/forge_view.gd`** (modified — largest surface area) — `add_item_to_inventory()` rewrites drop logic; `_load_bench_item()` added as new private function; `_on_melt_pressed()` / `_on_equip_pressed()` erase from array; `update_inventory_display()` shows x/N counter format; all null-vs-empty guards updated
4. **All other files** (unchanged) — `item.gd`, `hero.gd`, `loot_table.gd`, `gameplay_view.gd`, `main_view.gd`, `game_events.gd` — signal wiring and item serialization are stable

**Key patterns:**
- Array-as-slot-inventory with `SLOT_CAPACITY` constant — enforced at single add point only
- Best-item selection at bench-load time only (not on every frame or every drop)
- Erase-by-reference (`Array.erase(current_item)`) — no index tracking required
- Migration-before-schema: write and test `_restore_state()` for v2 format before changing `_build_save_data()`

### Critical Pitfalls

1. **Save migration written without updating `_restore_state()`** — if `_build_save_data()` is updated to write arrays before `_restore_state()` can read them, any existing save crashes on load with no data recovery. Mitigation: update restore path and migration atomically; test with a hand-crafted v1 fixture before any other change.

2. **Null-vs-empty guard breaks fresh game** — `crafting_inventory["weapon"] != null` is always true for an empty array; the starter weapon is never granted and the bench crashes with `Invalid get index 'item_name' on base 'Array'`. Mitigation: globally replace all null checks on inventory slots with `.size() > 0`; grep every `crafting_inventory.get(` and `crafting_inventory[` access site.

3. **`is_item_better()` guard left in `add_item_to_inventory()`** — the old comparison guard prevents the array from ever growing past 1 item per slot. Mitigation: delete the `is_item_better()` guard from the drop path in the same commit as the array rewrite; do not leave both code paths live simultaneously.

4. **`crafting_bench_item` dangling reference causes ghost items** — `GameState.crafting_bench_item` is confirmed orphaned state (never assigned anywhere except initialization); if left in place after the array conversion, melt/equip can create ghost items that reappear on reload. Mitigation: remove the field entirely in the same commit as the data shape change.

5. **x/10 counter fires on every currency drop** — `update_inventory_display()` is currently called from `on_currencies_found()`, which fires on every pack kill. With array-based display this rebuilds all 5 slot counters per currency event even when no inventory changed. Mitigation: remove `update_inventory_display()` from the currency handler; only call it on array mutations.

## Implications for Roadmap

The dependency structure is strict and dictates a 4-phase build order with a final verification pass. The data model must stabilize before save/load, the save format must be stable before inventory logic, and the logic must be stable before display. Each phase has a clear gate that must pass before the next begins.

### Phase 1: Save Format Migration

**Rationale:** Save migration is the highest-risk change and the only change that can corrupt player data. Writing and testing migration before anything else ensures the restoration path exists for any save created during development. This is the "migration-before-schema" pattern identified in ARCHITECTURE.md as a critical-path requirement.

**Delivers:** `SAVE_VERSION` bumped to 2; `_migrate_v1_to_v2()` implemented (wraps single-item dicts in arrays, converts nulls to `[]`, drops `crafting_bench_item` key); `_restore_state()` updated to read array format; `crafting_bench_index` decision made (persist or document as "restores to index 0 / best item on load")

**Addresses:** Save/load preserves full slot inventories (table stakes); v1 save string import compatibility

**Avoids:** Pitfall 1 (v1 save loads empty arrays), Pitfall 6 (`crafting_bench_item` dangling reference), Pitfall 7 (`_restore_state()` reads wrong format)

**Gate:** Load a hand-crafted v1 JSON fixture through `load_game()`; assert each slot is an `Array` with the correct item count.

### Phase 2: GameState Data Shape and Drop Flow

**Rationale:** `GameState.crafting_inventory` is the root dependency for all other components. Until it holds arrays, ForgeView cannot be updated and no tests run against real data. Removing `crafting_bench_item` and fixing null-vs-empty guards must happen here — leaving them active after Phase 1 creates false-green tests.

**Delivers:** `crafting_inventory` values are `[]` arrays; `initialize_fresh_game()` initializes empty arrays; `crafting_bench_item` field removed from GameState; `add_item_to_inventory()` rewritten (append + cap check, `is_item_better()` guard removed); all null-check access sites replaced with `.size() > 0`; `SLOT_CAPACITY` constant added

**Addresses:** Per-slot array storage, append-on-drop, silent discard at cap; fresh game starter weapon grant

**Avoids:** Pitfall 3 (`is_item_better()` guard left in drop path), Pitfall 8 (null-vs-empty breaks fresh game), Pitfall 2 (bench reference accidentally duplicated — document the reference contract in code comments)

**Gate:** New game grants starter weapon; 11 drops of the same item type produces exactly 10 items in the slot array.

### Phase 3: ForgeView Logic — Bench Selection, Melt, Equip

**Rationale:** With the data shape stable and save/load correct, the interaction logic can be built. All three operations (bench load, melt, equip) share the same array removal contract and must be implemented together to share `_remove_from_inventory()` helper logic and consistent `current_item` clearing. Equip confirmation state reset on item navigation must be included here.

**Delivers:** `_load_bench_item()` (best-item picker: highest DPS for weapon/ring, highest tier for armor slots); `_on_melt_pressed()` removes from array then loads next-best; `_on_equip_pressed()` removes from array then loads next-best; `_on_item_type_selected()` guards on empty array; `equip_confirm_pending` reset on any navigation; `current_item` cleared before array mutation in both melt and equip paths

**Addresses:** Best/highest-tier item on bench, melt removes from array, equip removes from array (all table stakes)

**Avoids:** Pitfall 4 (equip removes at stale index), Pitfall 9 (equip confirmation persists across item navigation), Pitfall 12 (ghost item on bench after melt)

**Gate:** Fill a slot with 3 items; equip the middle item; verify 2 remain in the array, bench shows one of them, equip confirmation resets on slot navigation.

### Phase 4: Display — x/10 Counter and UI Polish

**Rationale:** Display is the final layer and depends on the logic layer being correct. The x/10 counter only makes sense once add/melt/equip produce correct array state. Auditing `update_inventory_display()` call sites (removing it from the currency handler) belongs here as a display-layer concern.

**Delivers:** `update_inventory_display()` shows x/N counter format per slot (e.g., "Weapon (3/10): LightSword (Normal)"); counter updates on every add/melt/equip; `update_inventory_display()` removed from `on_currencies_found()`; slot type button states reflect empty vs non-empty arrays

**Addresses:** x/10 counter display, slot button disabled when array empty (table stakes)

**Avoids:** Pitfall 5 (x/10 counter desync from array length), Pitfall 11 (`update_inventory_display()` fires on every currency drop)

**Gate:** Counter is correct after drop, melt, equip, and save-load; counter does not update during currency-only pack kills; `ItemList` vs label-based display decision confirmed and implemented.

### Phase 5: Integration Verification

**Rationale:** A cross-cutting verification pass to confirm all 4 phases interact correctly end-to-end. The v1 migration path, save round-trip, multi-item slot interaction, and export string import need testing with real game scenarios before the milestone closes.

**Delivers:** Full "Looks Done But Isn't" checklist from PITFALLS.md verified; v1 save string import confirmed; export string round-trip confirmed; `is_item_better()` usage audited in non-drop contexts (stat comparison display) to confirm it is safe to keep or needs renaming

**Gate:** All checklist items pass — new game, 11-drop cap test, equip from multi-item slot, melt last item in slot, save/load round-trip, v1 fixture import via export string.

### Phase Ordering Rationale

- **Save migration first (not last):** The most counterintuitive but most important ordering decision. If any code that writes v2-format data is committed before the migration exists, a developer loading an existing save during development will silently lose all test data with no recovery path. Writing migration first means every save from that point is correctly handled.
- **Data model before logic before display:** Standard dependency order. Logic cannot be written without knowing the data shape. Display cannot be written without knowing what the logic produces.
- **Melt, equip, and bench selection in one phase:** These three operations share removal helper logic and must all reset `current_item` consistently. Splitting them risks one operation leaving stale state that breaks another.
- **Currency display fix in display phase:** It is a performance and correctness concern for the display layer, not a data correctness concern. Fixing it in Phase 4 avoids churn during the logic phase.

### Research Flags

All phases in this milestone have standard, well-documented patterns. No phase requires a `/gsd:research-phase` call.

- **Phase 1 (Save Migration):** Migration stub already exists at `save_manager.gd:159`; v1 format is fully documented; v2 format is fully specified in ARCHITECTURE.md with production-ready GDScript. Implement directly.
- **Phase 2 (GameState + Drop Flow):** All changes are mechanical substitutions — null → [], size checks, `is_item_better()` removal. No design ambiguity.
- **Phase 3 (ForgeView Logic):** All function signatures and complete implementations specified in ARCHITECTURE.md with verified GDScript code. Implement from the spec.
- **Phase 4 (Display):** `update_inventory_display()` rewrite fully specified. One gap: confirm `ItemList` vs. existing `Label` node as the display target — this is a 10-minute decision, not a research question.
- **Phase 5 (Integration):** Verification only against the PITFALLS.md checklist.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All patterns verified against existing codebase; `Array`, `Dictionary`, JSON serialization confirmed as Godot 4.0+ stable APIs already in production use |
| Features | HIGH | Table stakes confirmed via codebase analysis; idle ARPG genre conventions (silent discard, best-item-on-bench, equip-destroys-old) validated against NGU Idle, Melvor Idle, AFK Journey (MEDIUM confidence for genre sources, sufficient for design decisions) |
| Architecture | HIGH | Based on direct analysis of all 8 affected files with specific line numbers verified; all code snippets are production-ready GDScript drawn from the existing implementation patterns |
| Pitfalls | HIGH | All 12 pitfalls grounded in specific file paths and line numbers from direct codebase analysis; all are verified real failure modes in the existing code structure, not theoretical risks |

**Overall confidence: HIGH**

### Gaps to Address

- **`crafting_bench_index` persistence decision (resolve in Phase 1):** Two options: (a) persist a per-slot bench index in save data so the player's exact bench position survives reload, or (b) always restore to the best item (index 0 after sort) and document this explicitly. Neither is wrong; the gap is that no decision has been made. Resolve before writing `_build_save_data()`.

- **`ItemList` vs. label-based display (resolve in Phase 4):** STACK.md recommends `ItemList` for a navigable 10-item selectable list. ARCHITECTURE.md's `update_inventory_display()` implementation uses the existing `inventory_label` (a `Label` node) with a text block showing x/N counts. If the x/N counter text format is sufficient, the existing label stays and the display rewrite is minimal. If selectable item rows are desired, scope expands. Confirm before Phase 4 begins.

- **`is_item_better()` in non-drop contexts (resolve in Phase 2):** The function is currently also used in `get_stat_comparison_text()` and hero stats display for the equip comparison UI. PITFALLS.md recommends deleting it from the drop path but not necessarily from comparison display. Confirm whether it stays (possibly renamed) or is split into separate concerns.

## Sources

### Primary (HIGH confidence — direct codebase analysis)
- `autoloads/save_manager.gd` — `_build_save_data()`, `_restore_state()`, `SAVE_VERSION = 1`, `_migrate_save()` stub at line 159, export/import string format
- `autoloads/game_state.gd` — `crafting_inventory` Dictionary structure; `crafting_bench_item` confirmed orphaned (never assigned after initialization); `initialize_fresh_game()` slot initialization
- `scenes/forge_view.gd` — `add_item_to_inventory()`, `is_item_better()`, `_on_melt_pressed()`, `_on_equip_pressed()`, `update_inventory_display()`, `on_currencies_found()` — all primary change sites with line numbers verified
- `models/items/item.gd` — `to_dict()` / `create_from_dict()` proven round-trip; `Array[Affix]` typed array already in production
- `scenes/main_view.gd` — signal wiring `item_base_found` → `forge_view.set_new_item_base` confirmed unchanged
- `autoloads/game_events.gd` — existing signal declarations; no new signals needed for this milestone
- `scenes/gameplay_view.gd` — `_on_items_dropped()` confirmed to call `LootTable.spawn_item_with_mods()` before emitting; no double-modding risk on drop

### Secondary (MEDIUM confidence — community and official documentation)
- [Godot Engine — ItemList class reference](https://docs.godotengine.org/en/stable/classes/class_itemlist.html) — `add_item`, `clear`, `set_item_metadata`, `get_item_metadata`, `item_selected` signal confirmed
- [NGU Idle Inventory Wiki](https://ngu-idle.fandom.com/wiki/Inventory) — silent discard on full inventory confirmed as idle ARPG standard
- [Melvor Idle General Discussions (Steam)](https://steamcommunity.com/app/1267910/discussions/0/3828665107790112513/) — cap-as-signal behavior; player expectations for overflow handling documented
- [Evolution of Idle RPG Systems — Pocket Gamer](https://www.pocketgamer.biz/game-analysis-the-evolution-of-idle-rpg-systems/) — AFK Journey's archetype-based gear organization as genre convergence point; equip-destroys-old as idle-appropriate behavior
- [Godot Forum — How to save an array of Resources with JSON](https://forum.godotengine.org/t/how-to-save-an-array-of-resources-with-json/3258) — confirms manual `to_dict()` iteration pattern; no automatic Resource serialization in Godot 4

### Tertiary (supporting context)
- `.planning/PROJECT.md` — v1.5 Inventory Rework requirements (milestone scope authority)
- `.planning/debug/forge-view-is-item-better-tier-comparison.md` — `is_item_better()` diagnostic; confirms function behavior and the tier-comparison logic being reused for bench selection
- `.planning/phases/24-stat-calculation-and-hero-range-caching/24-UAT.md` — Phase 24 context; existing defensive stat comparison gap noted but does not affect this milestone scope

---
*Research completed: 2026-02-18*
*Ready for roadmap: yes*
