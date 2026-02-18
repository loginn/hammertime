# Pitfalls Research

**Domain:** Hammertime — Adding Per-Slot Multi-Item Inventory to Existing Single-Item Crafting System
**Researched:** 2026-02-18
**Confidence:** HIGH — Based on direct codebase analysis (all file paths verified against actual source)

---

## Critical Pitfalls

### Pitfall 1: Save Migration Silently Loads `null` Instead of Empty Array — Crafting Inventory Appears Broken

**What goes wrong:**
`save_manager.gd:84-90` serializes `crafting_inventory` as a dictionary keyed by slot type with a single `Item.to_dict()` value per slot:
```gdscript
for type_name in GameState.crafting_inventory:
    var item = GameState.crafting_inventory[type_name]
    if item != null:
        crafting_inv[type_name] = item.to_dict()
    else:
        crafting_inv[type_name] = null
```
After the inventory rework, each slot holds an `Array[Item]` instead of a single `Item`. When v1 saves are loaded without migration, `_restore_state()` at `save_manager.gd:129-137` reads `item_data = saved_crafting[type_name]`, finds a `Dictionary` (the old single-item dict), and tries to pass it to the array handler. If the migration is absent or partial, either the old item is silently dropped (empty array loaded) or a type mismatch causes a silent failure where `GameState.crafting_inventory["weapon"]` is `null` instead of `[]`, crashing the first time `crafting_inventory["weapon"].append(item)` is called.

The migration stub at `save_manager.gd:159-170` is currently empty (`# Future migrations go here`). SAVE_VERSION is 1. There is no v1-to-v2 migration written yet.

**Why it happens:**
The shape of `crafting_inventory` values changes from `Dictionary | null` to `Array[Dictionary]`. Any code that reads a v1 save and assumes the new shape (array) will either silently produce `null` or crash. The empty migration stub creates false confidence that a migration path exists.

**How to avoid:**
1. Bump `SAVE_VERSION` to 2 before merging any inventory schema changes — this is a prerequisite, not an afterthought
2. Write `_migrate_v1_to_v2(data: Dictionary)` that iterates `crafting_inventory` and wraps each non-null item dict in a single-element array: `data["crafting_inventory"][type] = [item_dict]` if item was not null, else `[]`
3. The migration must also handle `crafting_bench_item`: in v2, the bench item is a reference into the array (an index), not a separate serialized copy — old saves should set bench_item_index to 0 if a slot item existed, or -1 if null
4. Write a fixture test: save a v1 JSON manually, run `_restore_state()` through migration, assert each slot is an Array of length 0 or 1
5. New saves (v2) must not serialize `crafting_bench_item` as a full item copy — they must serialize an index. Failing to update `_build_save_data()` alongside `_restore_state()` causes the bench item to be double-stored: once in the array and once in the old key, and on next load both are restored independently

**Warning signs:**
- All crafting slots appear empty after loading an old save despite the file containing item data
- GDScript type error: `Invalid get index '0' (on base: 'Nil')` when ForgeView tries to access `crafting_inventory["weapon"][0]`
- New game works correctly but loading an existing save fails to populate any crafting items
- `crafting_bench_item` in save is a full dict but the array slot is also populated with the same item — bench item counted twice toward the 10-item cap

**Phase to address:**
Phase 1 (Save Migration) — Write and test migration before changing `GameState.crafting_inventory` type. Do not land array-based inventory code until a v1 save fixture can be loaded cleanly.

---

### Pitfall 2: Bench Item Is a Reference to Array Element — Crafting Modifies the Array Item In-Place Without Knowing It

**What goes wrong:**
The new design says the crafting bench is a "view into inventory." In GDScript, `Resource` objects are reference types. When `ForgeView.current_item` is set to `GameState.crafting_inventory["weapon"][selected_index]`, both variables point to the same object in memory. Applying a hammer (`selected_currency.apply(current_item)` at `forge_view.gd:227`) mutates the resource through `current_item`. Since `current_item` is a reference into the array, the inventory item is modified in-place — which is exactly the intended behavior.

The pitfall is the **inverse**: code that creates a copy instead of a reference. If any path does `current_item = GameState.crafting_inventory["weapon"][i].duplicate()`, modifications to `current_item` do NOT update the inventory. After crafting, the display shows the modified item but the array still holds the pre-craft version. On next load (or on equip), the pre-craft state is restored. The player's crafting work is silently lost.

GDScript's `Resource.duplicate()` is deep by default — it is commonly reached for when "getting an item from inventory" sounds like it should not mutate. But for this architecture, mutation-by-reference is the contract.

**Why it happens:**
GDScript developers familiar with value types (Dictionary, Array) expect `.duplicate()` as defensive programming. Resources are reference types but look like structured data objects, creating a conceptual mismatch. Any helper function that returns an item "from the inventory" and uses `.duplicate()` internally will silently break the reference contract.

**How to avoid:**
1. Document the reference contract explicitly at the top of `forge_view.gd`: "current_item is a direct reference to the inventory array element — never duplicate it"
2. When setting `current_item`, always write: `current_item = GameState.crafting_inventory[type][index]` — never `current_item = GameState.crafting_inventory[type][index].duplicate()`
3. Add an assertion or debug print after any hammer apply: verify `GameState.crafting_inventory[type][index].rarity == current_item.rarity` — if they diverge, a duplicate was made somewhere
4. The save trigger (`item_crafted` signal at `forge_view.gd:391`) already fires after craft — add a save-and-reload test: craft an item, save, reload, verify the crafted state is preserved in the array

**Warning signs:**
- Crafting an item changes the display correctly, but loading the save restores the pre-craft version
- The item stats display shows the crafted item but the save file JSON still shows the original item
- Items in the array appear to "reset" their rarity to Normal after any game event that re-reads them
- A crafted item looks correct in the bench but appears unmodified when next opened after switching item type tabs

**Phase to address:**
Phase 2 (GameState Inventory Model) — When converting `crafting_inventory` from `Item | null` to `Array[Item]`, document the reference contract in code comments. Verify with a post-craft save-load cycle.

---

### Pitfall 3: Drop Flow Replaces `is_item_better()` Auto-Replace — Old Items Silently Discarded Without Player Choice

**What goes wrong:**
The current `forge_view.gd:420-434` `add_item_to_inventory()` calls `is_item_better()` to decide whether to replace the existing slot item:
```gdscript
var existing_item: Item = GameState.crafting_inventory[item_type]
if existing_item == null or is_item_better(item, existing_item):
    GameState.crafting_inventory[item_type] = item
```
The new design removes this auto-replace logic entirely. Drops go into the array up to capacity; overflow is silently discarded. This requires a new drop handler path. The pitfall is partial migration: the old `is_item_better()` call is left in place alongside the new array append, creating two code paths where only one should run. Result: items either get auto-replaced AND appended (duplicated into array at index 0 and appended) or the old path short-circuits the new path and the array never grows beyond 1 item.

The wiring is at `main_view.gd:25`: `gameplay_view.item_base_found.connect(forge_view.set_new_item_base)`, and `forge_view.set_new_item_base()` calls `add_item_to_inventory()`. This entire call chain must be rerouted.

**Why it happens:**
The old `add_item_to_inventory()` is the single entry point for drops. When converting to arrays, developers often add the array logic inside this method without removing the old `is_item_better()` guard. The guard is still true/false but now gates array append instead of single-item replace — a logic error that only manifests when the array has more than one item.

**How to avoid:**
1. Delete `is_item_better()` from ForgeView entirely or move it to dead code before the milestone completes — its presence tempts future accidental reuse
2. Rewrite `add_item_to_inventory()` with an explicit new contract: "append to array if len < 10, otherwise discard; no replacement logic"
3. Add a debug log on discard: `print("Item discarded (full slot): ", item.item_name)` — this helps verify the discard path works without player confusion during development
4. Preserve `_defensive_score()` separately from `is_item_better()` if it is needed for the bench item selection logic (picking which array item to show on bench load)

**Warning signs:**
- Slots never accumulate more than 1 item regardless of how many maps are cleared
- Items are being appended AND placed at index 0 (array contains duplicate of the "best" item at two indices)
- The x/10 counter always shows 1/10 or resets to 1/10 after a new drop
- `is_item_better()` console print fires during drop events in the new system

**Phase to address:**
Phase 2 (Drop Flow Change) — When rewriting `add_item_to_inventory()`, remove the old comparison guard in the same commit. Do not leave both code paths live for any period.

---

### Pitfall 4: Equip Deletes Array Item at Wrong Index — Current Item Index Stale After Inventory Mutation

**What goes wrong:**
The new equip flow: the bench shows `crafting_inventory["weapon"][current_index]`. When equip is pressed, `current_item` (a reference to that array element) goes to the hero, and the item must be removed from the array. The removal is `crafting_inventory["weapon"].remove_at(current_index)`. After removal, `current_index` is now stale — the item that was at `current_index + 1` is now at `current_index`, but ForgeView still holds `current_index` pointing at the new item (if the array is non-empty) or an out-of-bounds index (if the array is now empty).

If the UI does not reset `current_index` after equip, the next navigation action (pressing the weapon slot button again) calls `crafting_inventory["weapon"][current_index]` on a shorter array. At best, this shows the wrong item. At worst, it crashes with an out-of-bounds access if `current_index == old_array.size() - 1`.

The existing equip code at `forge_view.gd:388-403` sets `current_item = null` and `crafting_inventory[slot_name] = null` — a clean two-step that works for single items. The array equivalent needs three steps: remove from array, reset index, then update display. If step 2 (reset index) is forgotten, the display may flash the correct state but the internal index is wrong for the next operation.

**Why it happens:**
The single-item flow has no "index" concept — nulling the slot is unambiguous. Arrays introduce index state that must be kept consistent with the array length. Developers naturally copy the null-assignment pattern without realizing the index must also be managed.

**How to avoid:**
1. Centralize array mutation into a `_remove_from_inventory(slot: String, index: int)` helper that removes the element AND resets the active index to `min(index, new_array.size() - 1)` or -1 if empty
2. Call this helper from both equip and melt paths — they both remove an item from the array at an index
3. After any mutation, always call `update_current_item()` to re-derive `current_item` from the (now-updated) index
4. Add an assertion before any array access: `assert(current_index >= 0 and current_index < crafting_inventory[type].size())`

**Warning signs:**
- Equipping an item from a multi-item slot shows the wrong item in the crafting panel afterwards
- GDScript error: `Index X out of size Y` in forge_view.gd when accessing the crafting inventory array after equip
- Melting the last item in a slot leaves the bench showing a "ghost" item with stale data
- The x/10 counter decrements correctly but the displayed item does not update

**Phase to address:**
Phase 3 (Equip and Melt Flow) — Implement `_remove_from_inventory()` helper before wiring equip and melt buttons. Test: fill a slot with 3 items, equip the middle one, verify the remaining 2 are intact and the bench shows one of them.

---

### Pitfall 5: x/10 Counter Desynchronizes from Array Length — Multiple Update Paths Miss One

**What goes wrong:**
The x/10 counter display must reflect `crafting_inventory[slot].size()`. In the current codebase, `update_inventory_display()` at `forge_view.gd:478` is called from: `add_item_to_inventory()`, `_on_melt_pressed()`, `_on_equip_pressed()`, and `on_currencies_found()`. After converting to arrays, this display must also reflect the correct count in response to:
- A drop landing in the array (counter increments)
- A melt removing from the array (counter decrements)
- An equip removing from the array (counter decrements)
- A save load restoring the array (counter reflects restored size)

The classic desync pitfall: one of these call sites calls `update_inventory_display()` on a stale copy of the array before the removal is committed. For example, if `_on_equip_pressed()` calls `update_inventory_display()` before calling `_remove_from_inventory()`, the counter shows the old count (still 3) after equipping an item. The player sees "3/10" when the slot has 2 items.

The problem compounds because the display function reads from `GameState.crafting_inventory` (the array), not from a cached local count. If the removal is committed to the array first, the display is correct. If the display call precedes the removal, it shows stale data.

**Why it happens:**
The existing display call order in `_on_equip_pressed()` at `forge_view.gd:398-403` is:
1. `update_hero_stats_display()`
2. `update_item_stats_display()`
3. `update_melt_equip_states()`
4. `update_inventory_display()`
5. `equipment_changed.emit()`

The inventory mutation (`GameState.crafting_inventory[slot_name] = null`) happens at line 395 — BEFORE all the display updates. This ordering works for single-item. Array removal with a helper function could inadvertently re-order the mutation and the display call if the helper returns before the display call runs.

**How to avoid:**
1. Establish a strict rule: always mutate the array first, then call all display updates
2. Put all display updates in a single `_refresh_all_displays()` call at the end of each action handler — eliminates the risk of partial updates
3. Test each action in isolation: drop an item, verify counter; melt an item, verify counter; equip, verify counter; load a save, verify counter. All four paths must produce correct results

**Warning signs:**
- Counter shows N but the slot visually lists N-1 items
- Equipping or melting does not decrement the counter until the next drop
- Counter is correct after reload but wrong during the same session
- x/10 counter goes negative (more items removed than counter thinks exist)

**Phase to address:**
Phase 3 (Equip and Melt Flow) and Phase 4 (UI Counter Display) — Verify counter update call order in every mutation path. Add counter-to-array-size assertion in debug builds.

---

### Pitfall 6: `crafting_bench_item` in GameState Becomes a Dangling Reference After Melt or Equip

**What goes wrong:**
`GameState.crafting_bench_item` currently holds a direct reference to the item on the bench. In the new system, the bench item is always `crafting_inventory[type][current_index]`. If `GameState.crafting_bench_item` is kept as a separate variable (either for save persistence or for other code to read the bench item), it becomes a dangling reference after melt or equip.

For example: melt path sets `GameState.crafting_inventory["weapon"].remove_at(i)`. If `GameState.crafting_bench_item` still points to the removed `Item` resource, Godot does not null it automatically — GDScript Resource references do not become `null` when the array no longer holds them. The variable still holds the Resource object in memory, it just is no longer "in the inventory." Any code that reads `GameState.crafting_bench_item` after melt gets the melted item's data — a ghost item.

This is especially subtle with save: if `_build_save_data()` serializes `GameState.crafting_bench_item` separately (as it currently does at `save_manager.gd:92-95`), it will save the melted item's data. On reload, the bench item is restored from save even though it should have been destroyed.

**Why it happens:**
The v1 codebase has two sources of truth for the bench: `GameState.crafting_bench_item` (the item itself) and `GameState.crafting_bench_type` (which slot is active). In the new design, the bench is derived state — it is always `crafting_inventory[bench_type][bench_index]`. Keeping `crafting_bench_item` as a separate GameState variable is a v1 artifact that must either be removed or converted to a computed property.

**How to avoid:**
1. Remove `GameState.crafting_bench_item` as a standalone variable. Replace with a computed getter: `GameState.get_bench_item() -> Item` that returns `crafting_inventory[crafting_bench_type][crafting_bench_index]` if the array is non-empty, else `null`
2. Replace `crafting_bench_item` in `_build_save_data()` with `crafting_bench_index` (an integer) per slot — or do not save the index at all (on load, default to index 0 or the first available item)
3. Any code that previously read `GameState.crafting_bench_item` must be updated to call the getter or access the array directly

**Warning signs:**
- After melting an item, the bench display still shows the melted item's stats
- The save file contains `crafting_bench_item` data for an item that no longer exists in the crafting inventory array
- On reload, a phantom item appears in the bench that is not in any inventory slot
- Applying a hammer to the bench item after melt appears to succeed (no null check triggers) but the item has no effect because it is orphaned

**Phase to address:**
Phase 1 (Save Migration) and Phase 2 (GameState Inventory Model) — Remove `crafting_bench_item` as a standalone field in the same commit that converts the inventory to arrays. Do not leave it as a legacy field "to be removed later."

---

### Pitfall 7: Save Format Change Without Export String Version Prefix Update — Imported Old Strings Corrupt New Saves

**What goes wrong:**
The export string format at `save_manager.gd:177-182` uses the prefix `HT1:` hardcoded as a string literal. The format version embedded in the save data (`"version": 1`) is separate from the export string prefix. When the inventory schema changes to v2, the import flow at `save_manager.gd:221-226` runs `_migrate_save(data)` which calls the migration logic. This is correct for the JSON payload.

However, if the export string prefix remains `HT1:` for both v1 and v2 saves, a player who shares a v1 save string with a v2 player will have it successfully decoded (the `HT1:` prefix check passes), migrated (migration runs), and loaded. This is the intended behavior.

The pitfall is the reverse: a v1 player receives a v2 save string from a v2 player. The `HT1:` prefix passes. The JSON is decoded. `int(data.get("version", 0))` returns 2. The check at `save_manager.gd:221` is `if int(data.get("version", 0)) > SAVE_VERSION: return {"success": false, "error": "newer_version"}`. If a v1 game (SAVE_VERSION=1) receives a v2 string, it correctly rejects it. This path is already handled.

The actual pitfall is within v2: if `_migrate_v1_to_v2()` is only invoked for `saved_version < 2`, but the export string from a v1 game passed through the old HT1: encoder and was NOT bumped to v2 before sharing — the recipient runs migration, but the shared string already contains the old format AND the version field is still 1, so migration fires correctly. This is fine.

The real risk is developers bumping SAVE_VERSION to 2 but forgetting to update `_restore_state()` to handle the new array format. The migration runs and transforms the data, but if `_restore_state()` still reads `crafting_inventory[type]` as a single item dict (v1 assumption), the migrated array is interpreted as a single item and crashes or silently drops all but the first item.

**Why it happens:**
SAVE_VERSION bump and `_restore_state()` changes must be made atomically. The migration transforms data, but `_restore_state()` must read the post-migration format. These two changes are in the same file but are not enforced by any compiler check — a developer can bump the version and write the migration without updating the restore path.

**How to avoid:**
1. Write `_restore_state()` to handle the v2 format before writing `_migrate_v1_to_v2()` — test restore with a hand-crafted v2 fixture first
2. Use a single migration + restore integration test: start with v1 JSON fixture, call `load_game()`, verify all slots are correctly populated as arrays
3. The export string `HT1:` prefix is fine to keep as-is — the save version inside the JSON payload is the authority for migration routing, not the string prefix

**Warning signs:**
- Loading a v2 save (freshly created) works correctly but importing a shared save string from a v2 game fails
- `_restore_state()` succeeds for new games but fails silently for migrated v1 saves (arrays have 0 items instead of the expected migrated content)
- Version 1 games can import version 2 strings without error (should be rejected by the `newer_version` check)
- After import, the bench shows the first inventory item correctly but all other array slots are empty

**Phase to address:**
Phase 1 (Save Migration) — Write migration and restore together, test both paths before moving on to any other phase.

---

### Pitfall 8: `ForgeView._ready()` Starting Item Logic Breaks When Inventory Is an Empty Array

**What goes wrong:**
`forge_view.gd:135-145` checks for saved items:
```gdscript
for type_name in inventory_types:
    if GameState.crafting_inventory.get(type_name) != null:
        has_saved_items = true
        break
```
After the rework, `GameState.crafting_inventory["weapon"]` is always an Array (never null). An empty array is truthy in GDScript — `if [] != null` is always `true`. The `has_saved_items` check will always be true even for a fresh game, preventing the starter weapon from being granted. New players start with no weapon and no way to craft anything.

The same pattern appears in the "fallback to first available item" logic at `forge_view.gd:149-158`:
```gdscript
if GameState.crafting_inventory.get(selected_type) != null:
    current_item = GameState.crafting_inventory[selected_type]
```
After rework, this always succeeds (array is not null), so `current_item` is set to an Array instead of an Item. The first call to `current_item.item_name` crashes with `Invalid get index 'item_name' on base 'Array'`.

**Why it happens:**
The null check was the correct guard for single-item-or-null inventory. Arrays break this idiom. `[] != null` is true, so all null-guard checks that gate on "is there something in this slot" become permanently true for arrays.

**How to avoid:**
1. Replace all null checks on inventory slots with size checks: `GameState.crafting_inventory.get(type_name, []).size() > 0`
2. The starter weapon grant check becomes: `has_saved_items = GameState.crafting_inventory.values().any(func(arr): return arr.size() > 0)`
3. The current item fallback becomes: `current_item = crafting_inventory[type][0] if crafting_inventory[type].size() > 0 else null`
4. Grep the entire codebase for `crafting_inventory.get(` and `crafting_inventory[` after the rework — every access site must be audited for the null-vs-empty distinction

**Warning signs:**
- Fresh game starts with no items and no way to get them (starter weapon never granted)
- GDScript error: `Invalid get index 'item_name' on base 'Array'` in forge_view.gd
- The bench is blank on a fresh game but the "has items" check shows true
- Hammer buttons are enabled even though no item is on the bench

**Phase to address:**
Phase 2 (GameState Inventory Model) — When converting the inventory type, immediately audit all access sites. The null-check idiom must be globally replaced before ForgeView can run.

---

## Moderate Pitfalls

### Pitfall 9: Two-Click Equip Confirmation State Persists Across Slot Switches

**What goes wrong:**
`forge_view.gd:49-50`:
```gdscript
var equip_confirm_pending: bool = false
var equip_timer: Timer
```
The equip confirmation is per-bench-item, not per-slot. In the new multi-item system, the player can navigate between items within a slot (or between slots) while confirmation is pending. The confirmation state was set for weapon[0] but the player navigates to weapon[1]. Pressing Equip on weapon[1] while `equip_confirm_pending` is true triggers the "confirm" path — equipping weapon[1] without asking for confirmation, despite weapon[1] being a different item than what confirmation was set for.

**How to avoid:**
Reset `equip_confirm_pending = false` and stop the equip timer in `_on_item_type_selected()`, in the new index-navigation handlers, and in any code path that changes `current_item`. The existing code already resets on type change (`forge_view.gd:264-268`) — extend this to index changes.

**Warning signs:**
- Pressing "Next Item" in a slot and immediately pressing Equip equips without showing "Confirm Overwrite?"
- Equip confirmation persists after switching between weapon slot and helmet slot

**Phase to address:**
Phase 3 (Equip and Melt Flow) — When adding index navigation, reset confirmation state on every navigation event.

---

### Pitfall 10: `crafting_bench_type` Save Key Becomes Ambiguous When Bench Needs Both Type and Index

**What goes wrong:**
`GameState.crafting_bench_type: String = "weapon"` persists which slot type is active. In the new system, the bench also needs to remember which index within the slot is active. If `crafting_bench_index` is not persisted, after a save-load cycle the bench always opens at index 0, potentially showing a different item than what the player was crafting on before save. This is not a crash but a subtle user experience issue: the player was halfway through crafting on item at index 3, saved, reloaded, now the bench shows a fresh item at index 0.

**How to avoid:**
Add `crafting_bench_index: int = 0` to `GameState` and persist it in `_build_save_data()`. Alternatively, decide not to persist the index (always restore to index 0 on load) and document this as an intentional design choice. Either is valid, but the decision must be made explicitly — silent restoration to a wrong item is worse than explicit "restores to first item on load" behavior.

**Warning signs:**
- Player reports "my crafting progress disappeared" — item was mid-craft at index 3, reload shows index 0
- The bench type is correctly restored but the item shown is not the one that was being crafted

**Phase to address:**
Phase 1 (Save Migration) — Decide whether to persist the bench index when designing the v2 save format. Include the field (or document its absence) before any restore logic is written.

---

### Pitfall 11: `on_currencies_found()` Calls `update_inventory_display()` — Triggers Counter Refresh On Every Pack Kill

**What goes wrong:**
`forge_view.gd:443-447`:
```gdscript
func on_currencies_found(drops: Dictionary) -> void:
    print("Currencies received: ", drops)
    update_inventory_display()
    update_currency_button_states()
```
This fires on every pack kill that drops currency. `update_inventory_display()` is cheap for a single item per slot (5 labels). For 5 slots x up to 10 items each, this function rebuilds the display for 50 potential items on every currency drop event. In deep combat (8-15 packs per map, several maps per minute), this refresh runs dozens of times per minute for a display that did not change (no items dropped, only currency).

This is not a crash but a performance trap that grows with inventory size.

**How to avoid:**
Split currency display refresh from inventory item display refresh. `on_currencies_found()` only needs `update_currency_button_states()` — the item display does not change when currency drops. Remove the `update_inventory_display()` call from the currency handler. Only call `update_inventory_display()` when the inventory arrays actually change (drop adding item, melt, equip).

**Warning signs:**
- ForgeView label flickers or stutters during heavy combat even though no items drop
- Performance profiler shows `update_inventory_display()` in hot path during pack-kill events

**Phase to address:**
Phase 4 (UI Counter Display) — When implementing the x/10 counter display, audit all call sites of `update_inventory_display()` and remove any that fire without an array mutation.

---

### Pitfall 12: Bench Item Hover Stat Comparison Reads From Array Index That May Have Changed

**What goes wrong:**
`forge_view.gd:620-622`:
```gdscript
func get_stat_comparison_text() -> String:
    if current_item == null:
        return ""
    var slot_name: String = get_item_type(current_item)
```
The stat comparison reads from `current_item`, which is a reference into the array. If the array is mutated (an item melted at a lower index) while the hover is active, `current_item` reference is still valid (it points to the Resource object in memory) but the index is stale. The comparison text is still correct (it reads from the item object, not the index). This is actually safe.

The pitfall is the reverse path: if `get_item_type(current_item)` is called and `current_item` is the stale reference from a melted item, `get_item_type()` uses `is` checks that work on any Resource — even orphaned ones. The comparison text will show the orphaned item's stats against the hero's equipped item, showing a "comparison" for an item that no longer exists in the inventory. The player may click "Equip" on this ghost item. The equip handler reads `current_item` and calls `hero.equip_item(current_item, slot_name)` — the hero will equip the already-melted item with no crash, since the Resource object is still in memory.

**How to avoid:**
Always set `current_item = null` immediately in the melt handler before any display refresh. This ensures any display code that checks `current_item != null` will bail out cleanly. The reference is cleared before any render of the stale comparison text can trigger.

**Warning signs:**
- After melting an item, the stat comparison panel shows the melted item's stats on equip hover
- Equip button is still enabled after melt (melt_equip_states not updated correctly)
- A melted item appears on the hero after the player clicks Equip following a melt action

**Phase to address:**
Phase 3 (Equip and Melt Flow) — Clear `current_item = null` as the first line of `_on_melt_pressed()` before any array mutation or display update. Match existing pattern at `forge_view.gd:355`.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Keep `is_item_better()` and add array check around it | Minimal code change for drop flow | Array never fills past 1 item per slot; entire inventory rework is cosmetic only | Never |
| Keep `crafting_bench_item` as separate GameState var | No GameState refactor needed | Dangling reference after melt/equip; phantom items on reload | Never |
| Null check for empty inventory instead of size check | Works for current code that returns null | Fresh game never grants starter weapon; array slots always appear non-empty | Never |
| Skip persisting `crafting_bench_index` | Simpler save format | Player loses bench position on every save-load; invisible UX regression | Acceptable if documented intentionally |
| Call `update_inventory_display()` from `on_currencies_found()` | Guaranteed display consistency | Performance cost on every pack kill for unchanged item data | Acceptable for MVP, address before endgame balance |
| Save `crafting_bench_item` as a full item copy alongside the array | No restore logic change for bench item | Bench item double-counted: once in array (for 10-cap), once as orphan bench copy | Never |

---

## Integration Gotchas

| Integration Point | Common Mistake | Correct Approach |
|------------------|----------------|------------------|
| `GameState.crafting_inventory` type change | Access with null check (`!= null`) | Access with size check (`.size() > 0`) — arrays are never null |
| `crafting_bench_item` removal | Leave as backward-compat var and also maintain array | Remove and replace with computed getter derived from array + index |
| Drop handler `add_item_to_inventory()` | Add array append inside existing `is_item_better()` guard | Rewrite entire function: delete guard, append if size < 10, else discard |
| Equip flow `crafting_inventory[slot] = null` | Directly null the slot (old pattern) | `_remove_from_inventory(slot, index)` that removes and resets index state |
| Melt flow `crafting_inventory[slot] = null` | Same as equip — null the slot | Same `_remove_from_inventory()` helper; clear `current_item` first |
| Save `_build_save_data()` for arrays | Serialize the array as-is; bench item stays as v1 key | Serialize array of dicts per slot; replace bench_item with bench_index |
| `_restore_state()` array path | Use same `Item.create_from_dict()` call as v1 | Iterate array of dicts, call `create_from_dict()` for each, build array |
| Export string import of v1 saves | Accept all `HT1:` strings as v2 | Check `data["version"]` and run migration before `_restore_state()` |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| `update_inventory_display()` on every currency drop | Label flicker during combat, CPU hot spot | Only call on array mutations (drop/melt/equip), not on currency events | Endgame with 8-15 packs/map and high clear speed |
| Rebuilding all 5 slot displays when only 1 changes | Unnecessary work per action | Pass `dirty_slot` parameter and only rebuild affected slot | All slot counts > 3 items (noticeable at 50+ items total) |
| Array `size()` called multiple times in same render loop | Minor — GDScript O(1) | Not a real concern at 10-item max — array size is bounded | Not applicable at 10-item cap |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Silent discard when slot is full (overflow dropped) | Player clears a hard map, gets nothing, never knows why | Log to console at minimum; future: "Slot full — item discarded" toast |
| Bench always opens at index 0 after reload | Player mid-craft on a specific item loses their place | Persist `crafting_bench_index` per slot in save data |
| No indication of which item in slot is on bench | Player confused about which of their 5 weapons they are crafting on | Show item number in bench display: "Weapon 3/7" |
| Equipping from a non-0 index does not update which index is "current" | After equip, bench jumps to a random item or crashes | Always reset index to `clamp(old_index, 0, new_size - 1)` after equip |
| x/10 counter goes stale during rapid drops | Player sees 5/10 but slot actually has 7 after fast map clear | Ensure `update_inventory_display()` fires after each individual `add_item_to_inventory()` call, not batched |

---

## "Looks Done But Isn't" Checklist

- [ ] **Save Migration:** SAVE_VERSION bumped to 2 and `_migrate_v1_to_v2()` implemented? Load a v1 fixture save and verify all slots are Arrays with correct items — check `save_manager.gd:6`
- [ ] **Save Migration:** `_restore_state()` reads arrays, not single items? Verify with a freshly created v2 save (round-trip: save → read file → load → verify)
- [ ] **Bench Reference:** Crafting an item and saving immediately shows crafted state in the save file JSON? (Confirms reference is not a duplicate — `forge_view.gd:227`)
- [ ] **Drop Flow:** After 11 items of one type, only 10 are in the slot (overflow discarded)? Verify by checking array size after 11 drops to same slot type
- [ ] **Equip Flow:** After equipping item at index 3 from a 5-item slot, the bench shows index 3 (now the old index 4) or index 2 — not a crash? (Pitfall 4)
- [ ] **Melt Flow:** After melting the last item in a slot, the bench shows null state (no item), not a ghost from the melted item? (Pitfall 6 / 12)
- [ ] **x/10 Counter:** Counter updates immediately after drop, melt, and equip — not just on next frame or next event? (Pitfall 5)
- [ ] **Fresh Game:** New game (no save) grants starter weapon? The `has_saved_items` check must use `.size() > 0`, not `!= null` — `forge_view.gd:135`
- [ ] **Array Null Check Audit:** Grepped for all `crafting_inventory.get(` and `crafting_inventory[` — all use size checks? (Pitfall 8)
- [ ] **Equip Confirmation Reset:** Navigating between items in a slot resets `equip_confirm_pending = false`? (Pitfall 9)
- [ ] **crafting_bench_item Removal:** GameState no longer has `crafting_bench_item` as a top-level var? (Pitfall 6)
- [ ] **Export String:** HT1 import of a v1 string migrates correctly to v2 format? Test by creating a v1 save string manually and importing into a v2 game

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Missing save migration (v1 loads with empty arrays) | MEDIUM | 1. Write migration immediately 2. Bump SAVE_VERSION to 2 3. Test with v1 fixture 4. Cannot recover player saves already corrupted by a botched partial migration — require new game or restore from exported string |
| Bench reference is a duplicate (craft changes lost on reload) | LOW | 1. Find and remove all `.duplicate()` calls on inventory items 2. No save impact — DPS/rarity are re-derived from item fields which ARE stored |
| Array index out of bounds after equip/melt | LOW | 1. Add `_remove_from_inventory()` helper 2. Add clamp on index after removal 3. No save impact |
| `crafting_bench_item` dangling reference causing ghost items | MEDIUM | 1. Remove `crafting_bench_item` from GameState 2. Bump SAVE_VERSION again (to 3) if ghost items were already saved 3. Migration v2→v3 must discard the orphaned bench_item key |
| Null check breaks fresh game starter weapon grant | LOW | 1. Replace null check with size check at `forge_view.gd:137` 2. No save impact — fresh game has no save file to migrate |
| x/10 counter desync | LOW | 1. Audit all `update_inventory_display()` call sites 2. Ensure display reads directly from array size, not a cached counter variable |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| v1 save loads empty arrays instead of migrated items (Pitfall 1) | Phase 1: Save Migration | Load a v1 fixture; assert each slot is `Array` with correct item count |
| Bench reference is a duplicate — craft lost on reload (Pitfall 2) | Phase 2: GameState Inventory Model | Craft an item, save, reload; assert crafted rarity persists in save JSON |
| Drop flow still uses `is_item_better()` guard (Pitfall 3) | Phase 2: Drop Flow Change | Drop 11 items of same type; assert slot has exactly 10 |
| Equip removes at stale index (Pitfall 4) | Phase 3: Equip and Melt Flow | Equip middle item from 3-item slot; assert remaining 2 are correct |
| x/10 counter desync (Pitfall 5) | Phase 4: UI Counter Display | Perform drop, melt, equip in sequence; assert counter == array.size() after each |
| `crafting_bench_item` dangling reference (Pitfall 6) | Phase 2: GameState Inventory Model | Melt an item; assert bench shows null and save file has no orphaned bench_item |
| `_restore_state()` reads v1 format for v2 saves (Pitfall 7) | Phase 1: Save Migration | Round-trip new v2 save; assert all slots restored as arrays |
| Null-vs-empty breaks fresh game starter weapon (Pitfall 8) | Phase 2: GameState Inventory Model | Start new game; assert weapon slot has 1 item (the starter weapon) |
| Equip confirmation persists across item navigation (Pitfall 9) | Phase 3: Equip and Melt Flow | Set confirm pending, navigate to next item, press Equip; assert confirmation dialog shown again |
| Bench index not persisted — wrong item shown after reload (Pitfall 10) | Phase 1: Save Migration | Craft on item at index 2, save, reload; assert bench index restores to 2 (or document as index-0 behavior) |
| `update_inventory_display()` fires on every currency drop (Pitfall 11) | Phase 4: UI Counter Display | Profile combat with 10-item slots; assert display rebuild not in hot path |
| Ghost item on bench after melt (Pitfall 12) | Phase 3: Equip and Melt Flow | Melt only item in slot; assert bench shows empty state, equip button disabled |

---

## Sources

- Codebase analysis: `autoloads/save_manager.gd`, `autoloads/game_state.gd`, `autoloads/game_events.gd`, `scenes/forge_view.gd`, `scenes/main_view.gd`, `models/hero.gd`, `models/items/item.gd`
- Milestone context: `.planning/PROJECT.md` (v1.5 Inventory Rework requirements)
- Debug record: `.planning/debug/forge-view-is-item-better-tier-comparison.md` (is_item_better() diagnosis)
- Phase 24 UAT: `.planning/phases/24-stat-calculation-and-hero-range-caching/24-UAT.md` (existing gap: defensive stat comparison)
- GDScript resource reference semantics: Godot 4 documentation — Resource objects are reference-counted, not value-copied; `duplicate()` is explicit

---
*Pitfalls research for: Hammertime — Per-Slot Multi-Item Inventory Rework (v1.5)*
*Researched: 2026-02-18*
*Confidence: HIGH — All pitfalls grounded in direct codebase analysis with specific file paths and line numbers verified*
