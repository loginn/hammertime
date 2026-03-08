# Phase 43: Inventory Rework -- Research

## Requirements Addressed

| REQ-ID | Description |
|--------|-------------|
| INV-01 | 5 crafting benches (one per equipment slot), each holds max 1 item |
| INV-02 | Player selects which bench to craft on via slot tabs (existing UI pattern) |
| INV-03 | Drops for a slot are discarded if bench already occupied |
| INV-04 | ForgeView shows 5 bench slots instead of 10-item arrays per slot |
| INV-05 | Save format simplified (1 item per slot instead of inventory arrays) |

---

## 1. Current Inventory System (GameState)

**File:** `autoloads/game_state.gd`

### Data Structure (line 9)
```gdscript
var crafting_inventory: Dictionary = {}
```
Each key is a slot name (`"weapon"`, `"helmet"`, `"armor"`, `"boots"`, `"ring"`) mapping to an `Array` of `Item` objects.

### Initialization -- `initialize_fresh_game()` (lines 68-78)
```gdscript
crafting_inventory = {
    "weapon": [],
    "helmet": [],
    "armor": [],
    "boots": [],
    "ring": [],
}
crafting_inventory["weapon"] = [LightSword.new()]
```

### Prestige Reset -- `_wipe_run_state()` (lines 108-117)
Identical pattern: creates empty arrays for all 5 slots, then puts a `LightSword.new()` in the weapon array.

### What Needs to Change
- **Type:** `Dictionary` of `Array` -> `Dictionary` of nullable `Item` (or `null`).
- **Initialization:** `crafting_inventory["weapon"] = LightSword.new()` instead of wrapping in array.
- **All other slots:** `null` instead of `[]`.
- Both `initialize_fresh_game()` (line 68-78) and `_wipe_run_state()` (line 108-117) must be updated identically.

### Risk: LOW
Simple structural change. Both methods have identical logic, so changes are symmetric.

---

## 2. ForgeView Inventory Management

**File:** `scenes/forge_view.gd` (1057 lines)

### All Array Access Points

| Line(s) | Function | Current Logic | Change Needed |
|---------|----------|---------------|---------------|
| 172-194 | `_ready()` | Iterates slot arrays with `.is_empty()`, calls `get_best_item()` | Check `!= null` instead of `.is_empty()`. Remove `get_best_item()` -- just use the item directly. |
| 354 | `_on_item_type_selected()` | `GameState.crafting_inventory[item_type].is_empty()` | `GameState.crafting_inventory[item_type] == null` |
| 383-396 | `update_slot_button_labels()` | Shows `"Slot (N/10)"` using `.size()` | Show just slot name (e.g., `"Weapon"`). Disable if `null`. |
| 399-409 | `update_current_item()` | Gets best item from array via `get_best_item()` | Direct assignment: `current_item = GameState.crafting_inventory[selected_type]` |
| 445-471 | `_on_melt_pressed()` | Finds item in array via `.find()`, calls `.remove_at()` | Set `GameState.crafting_inventory[slot_name] = null` |
| 474-515 | `_on_equip_pressed()` | Finds item in array via `.find()`, calls `.remove_at()` | Set `GameState.crafting_inventory[slot_name] = null` |
| 532-546 | `add_item_to_inventory()` | Appends to array with 10-item cap check | Check if slot is `null`; if occupied, discard silently. If empty, assign directly. |
| 581-591 | `get_best_item()` | Iterates array to find highest-tier item | **Remove entirely** or trivially return the single item (just `return GameState.crafting_inventory[slot_name]`). |
| 597-622 | `update_inventory_display()` | Iterates arrays, calls `get_best_item()` | Check `!= null` instead of `.is_empty()`. Use item directly. |

### Melt Confirmation
Per CONTEXT.md: melt uses two-click confirmation with 3-second timer reset, matching the equip confirmation pattern. The equip confirmation pattern already exists (lines 64-66, 164-170, 474-520). A `melt_confirm_pending` flag and `melt_timer` need to be added, mirroring the equip pattern.

### Empty Bench Display
Per CONTEXT.md: `item_stats_label.text = "No item on bench"` when slot is empty. This is already partially handled at line 633 (`"No item on crafting bench"`). Just update the text.

### What Needs to Change
- Replace all `.is_empty()` checks with `== null` checks.
- Replace all `slot_array` local variables (Array type) with nullable Item variables.
- Remove `get_best_item()` function or reduce to a one-liner.
- Simplify `add_item_to_inventory()` from array-append-with-cap to null-check-and-assign.
- Add melt two-click confirmation (new `melt_confirm_pending`, `melt_timer`).
- Simplify `update_slot_button_labels()` to show just slot name, disable empty slots.

### Risk: MEDIUM
This is the largest file to change (14 array-access points). Logic simplification is straightforward, but easy to miss one spot. Melt confirmation is new code but follows an existing pattern exactly.

---

## 3. Save/Load Serialization

**File:** `autoloads/save_manager.gd`

### Current Save Version (line 4)
```gdscript
const SAVE_VERSION = 4
```

### Build Save Data -- `_build_save_data()` (lines 91-97)
```gdscript
var crafting_inv := {}
for type_name in GameState.crafting_inventory:
    var slot_array: Array = GameState.crafting_inventory[type_name]
    var items_data: Array = []
    for item in slot_array:
        items_data.append(item.to_dict())
    crafting_inv[type_name] = items_data
```
Currently serializes each slot as an array of item dicts.

### Restore State -- `_restore_state()` (lines 136-146)
```gdscript
var saved_crafting: Dictionary = data.get("crafting_inventory", {})
for slot_name in ["weapon", "helmet", "armor", "boots", "ring"]:
    var slot_data = saved_crafting.get(slot_name, [])
    var items_array: Array = []
    if slot_data is Array:
        for item_data in slot_data:
            if item_data is Dictionary:
                var item = Item.create_from_dict(item_data)
                if item != null:
                    items_array.append(item)
    GameState.crafting_inventory[slot_name] = items_array
```

### What Needs to Change
- **Version bump:** `SAVE_VERSION = 4` -> `SAVE_VERSION = 5`
- **Build:** Each slot serializes as either `item.to_dict()` (dict) or `null` (JSON null).
- **Restore:** Each slot deserializes as either `Item.create_from_dict(slot_data)` or `null`.
- **Old save handling:** Already handled -- line 62-65 deletes saves with `saved_version < SAVE_VERSION`.

### Save Format Change
**Before (v4):**
```json
{
  "crafting_inventory": {
    "weapon": [{"item_type": "LightSword", ...}],
    "helmet": [],
    ...
  }
}
```

**After (v5):**
```json
{
  "crafting_inventory": {
    "weapon": {"item_type": "LightSword", ...},
    "helmet": null,
    ...
  }
}
```

### Risk: LOW
The old-save deletion policy means no migration code needed. The serialization change is a simplification (less code).

---

## 4. Drop Flow

### Signal Chain
1. `CombatEngine` calls `LootTable.roll_pack_item_drop()` -- on success emits `GameEvents.items_dropped.emit(level)` (`models/combat/combat_engine.gd:150-151`)
2. `GameplayView._on_items_dropped()` calls `get_random_item_base()`, emits `item_base_found` signal (`scenes/gameplay_view.gd:185-189`)
3. `main_view.gd:40` connects: `gameplay_view.item_base_found.connect(forge_view.set_new_item_base)`
4. `ForgeView.set_new_item_base()` calls `add_item_to_inventory()` (`scenes/forge_view.gd:549-551`)
5. `ForgeView.add_item_to_inventory()` checks cap and appends to array (`scenes/forge_view.gd:532-546`)

### Drop Rate
Each pack kill has one `roll_pack_item_drop()` check, producing at most 1 item per pack. The CONTEXT.md mentions "multi-item drops (1-3 per map clear)" but the current code produces one item per pack kill (multiple packs per map). The signal fires once per qualifying pack, with one item per fire.

### What Needs to Change
- `add_item_to_inventory()` (the single entry point): Change from 10-item-cap array append to null-check-and-discard.
- `set_new_item_base()` calls `add_item_to_inventory()` -- no change needed to this wrapper.
- No changes needed in `gameplay_view.gd`, `main_view.gd`, or `combat_engine.gd`.

### Risk: LOW
Single function change at the insertion point. The discard is silent (no toast, per CONTEXT.md), so no new UI work.

---

## 5. Prestige Reset

**File:** `autoloads/game_state.gd`, function `_wipe_run_state()` (lines 95-133)

Lines 108-117 initialize crafting inventory identically to `initialize_fresh_game()`:
```gdscript
crafting_inventory = {
    "weapon": [],
    "helmet": [],
    "armor": [],
    "boots": [],
    "ring": [],
}
crafting_inventory["weapon"] = [LightSword.new()]
```

### What Needs to Change
Same as `initialize_fresh_game()` -- use nullable items instead of arrays.

### Risk: LOW
Symmetric change. Already has test coverage (integration_test.gd Group 3).

---

## 6. Integration Test Coverage

**File:** `tools/test/integration_test.gd`

### Inventory-Related Tests

| Line(s) | Test | Current Assertion | Change Needed |
|---------|------|-------------------|---------------|
| 71 | Group 1 | `GameState.crafting_inventory["weapon"].size() >= 1` | `GameState.crafting_inventory["weapon"] != null` |
| 75 | Group 1 | `GameState.crafting_inventory["weapon"][0] is LightSword` | `GameState.crafting_inventory["weapon"] is LightSword` |
| 119-120 | Group 3 | Same pattern (size check + index 0) | Same change |
| 201 | Group 6 | `GameState.crafting_inventory["weapon"][0]` | `GameState.crafting_inventory["weapon"]` |

### Risk: LOW
4 assertions to update. All follow the same pattern: remove array indexing.

---

## 7. All Touchpoints (grep "crafting_inventory")

Excluding worktree duplicates:

| File | Lines | Context |
|------|-------|---------|
| `autoloads/game_state.gd` | 9, 69-77, 109-117 | Declaration, init, prestige reset |
| `autoloads/save_manager.gd` | 92-97, 104, 136-146 | Serialize, save key, deserialize |
| `scenes/forge_view.gd` | 175, 184, 190, 354, 394, 402, 453, 502, 540, 584, 604 | 11 access points |
| `tools/test/integration_test.gd` | 71, 75, 119-120, 201 | 4 test assertions |

**Total: 4 files, ~25 code locations.**

No other `.gd` files reference `crafting_inventory`.

---

## 8. Additional Considerations

### `crafting_bench_type` (GameState line 10)
This `String` tracks which slot tab is selected. No structural change needed -- it already stores just `"weapon"`, `"helmet"`, etc. Works identically with single-item slots.

### Item Display When Bench Is Empty
Per CONTEXT.md: `item_stats_label` shows "No item on bench". Already partially handled (forge_view.gd:633 shows "No item on crafting bench"). Update text to match decision.

### Disabled Empty Slots
Per CONTEXT.md: Empty bench slots are disabled (greyed out, unclickable). `update_slot_button_labels()` already has `btn.disabled = (count == 0)` at line 396. Change to `btn.disabled = (GameState.crafting_inventory[slot_name] == null)`.

### Auto-Select on Item Type Switch
`_on_item_type_selected()` at line 346 currently ignores selection if array is empty. With single-item model, ignore if `null`. Same logic, different check.

### Melt Two-Click Confirmation Pattern
Equip confirmation uses:
- `equip_confirm_pending: bool` (line 64)
- `equip_timer: Timer` (line 65, created in `_ready()` at lines 165-170)
- `_on_equip_timer_timeout()` (line 518-520)
- First click sets pending + shows "Confirm Overwrite?", second click executes

Melt confirmation should mirror this exactly:
- `melt_confirm_pending: bool`
- `melt_timer: Timer` (3-second timeout)
- `_on_melt_timer_timeout()` resets pending state
- First click shows "Confirm Melt?", second click executes

### Forge Error Toast
Currently `add_item_to_inventory` prints to console when slot is full. Per CONTEXT.md, discard is silent (no toast, no feedback). The existing print statement should be kept for debugging but no UI feedback added.

---

## Validation Architecture

### Unit-Level Checks (Integration Test Updates)
1. **Fresh game:** `GameState.crafting_inventory["weapon"]` is a `LightSword` instance (not null, not an array).
2. **Fresh game:** All other slots are `null`.
3. **Prestige reset:** Same assertions as fresh game.
4. **Save round-trip:** Build save data, trash state, restore, verify weapon slot has item and other slots are null.
5. **Crafting regression:** Access `GameState.crafting_inventory["weapon"]` directly (no array index).

### Functional Verification (Manual or Automated)
1. **Drop acceptance:** Start fresh game, clear maps until a weapon drops. Verify weapon bench now has the new item (starter weapon was melted/equipped first).
2. **Drop discard:** With an item on bench, observe subsequent drops for that slot are silently discarded (console print confirms "discarding").
3. **Melt flow:** Select occupied bench, click Melt, verify "Confirm Melt?" appears, click again within 3s, verify bench clears.
4. **Melt timeout:** Click Melt once, wait 3s, verify button resets to "Melt".
5. **Equip flow:** Select occupied bench, click Equip, verify two-click confirmation still works, verify bench clears after equip.
6. **Slot tab display:** All 5 slot tabs show just the slot name (no count). Empty slots are greyed out/disabled.
7. **Empty bench display:** Selecting a slot with no item shows "No item on bench" in stats panel.
8. **Save/load:** Save game with items on some benches, reload, verify bench contents persist.
9. **Old save handling:** Place a v4 save file, load game, verify it wipes and starts fresh (v5).
10. **Prestige cycle:** Execute prestige, verify all benches reset (weapon gets starter, rest null).

### Regression Checks
- Crafting (applying hammers) still works on bench items.
- Equip stat comparison still works on hover.
- Hero stats update correctly after equip.
- Currency button states update after crafting/equip.
- Settings view "New Game" still resets inventory properly (calls `initialize_fresh_game()`).
- Import/export save strings work with new format.

---

## RESEARCH COMPLETE
