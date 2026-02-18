# Stack Research: Per-Slot Multi-Item Inventory System

**Domain:** Godot 4.5 Idle ARPG — Adding per-slot inventory arrays (10 items per slot) to existing single-item crafting system
**Researched:** 2026-02-18
**Confidence:** HIGH (all patterns verified against existing codebase and official Godot documentation)

---

## Context

This is a **subsequent milestone stack**. Godot 4.5, GDScript, mobile renderer, and the Resource-based data model are already validated. This document covers only what changes or is added for the per-slot inventory system.

The existing architecture to understand before touching anything:

- `GameState.crafting_inventory` is a `Dictionary` keyed by slot string (`"weapon"`, `"helmet"`, etc.) with a single `Item` or `null` per slot
- `SaveManager._build_save_data()` serializes that dict as `{slot: item.to_dict()}` — one item per slot
- `ForgeView.add_item_to_inventory()` is the current drop entry point — it replaces the slot if `is_item_better()`, discards otherwise
- `Item.to_dict()` / `Item.create_from_dict()` is the proven JSON serialization pattern — it is the pattern to extend

---

## Recommended Stack

### Core Technologies (Unchanged)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Godot Engine | 4.5 | Game engine | Already in production. No version change needed. |
| GDScript | 4.5 | Scripting language | All built-in array and container methods used below are 4.x globals or class methods already in use. |
| Resource system | 4.5 | Data model (`Item`, `Hero`, `Affix`) | `Item.to_dict()` / `Item.create_from_dict()` is the proven round-trip pattern. Extend it, do not replace it. |
| JSON via `JSON.stringify` / `JSON.parse_string` | 4.5 | Save file format | Already in `SaveManager`. Arrays of dictionaries serialize natively — no format change required. |

### GDScript Patterns for Per-Slot Arrays (NEW)

#### 1. Typed Array Declaration

Use `Array[Item]` typed arrays in `GameState` for slot inventories. Typed arrays give compile-time checks but serialize to plain `Array` when passed through JSON — this is fine because `SaveManager` already manually iterates and calls `to_dict()` / `create_from_dict()` per item. The type annotation is for code clarity and editor autocomplete, not for JSON round-trip.

```gdscript
# In game_state.gd — replaces the single-Item Dictionary
var slot_inventories: Dictionary = {
    "weapon": [],   # Array[Item], max 10
    "helmet": [],
    "armor":  [],
    "boots":  [],
    "ring":   [],
}
```

**Why Dictionary of Arrays, not a nested typed array:** The existing `crafting_inventory` is a `Dictionary` keyed by slot string. Keeping the same key structure means all call sites that do `GameState.crafting_inventory.get(slot_name)` change minimally — just index into the array instead of referencing the single value. The switch from `Dictionary` to a new variable name (`slot_inventories`) also makes the breaking change explicit and searchable.

#### 2. Array Bounds Check Pattern

The 10-item cap must be enforced at the single add point (the new `add_item_to_slot()` function). Never scatter the cap check across callers.

```gdscript
# game_state.gd or forge_view.gd — single authoritative add function
const SLOT_CAPACITY: int = 10

func add_item_to_slot(item: Item) -> bool:
    var slot: String = _get_slot_for_item(item)
    var inv: Array = slot_inventories[slot]
    if inv.size() >= SLOT_CAPACITY:
        return false   # Drop silently — inventory full
    inv.append(item)
    return true
```

**Why `const` not a magic number:** The constant is referenced by UI code (`"%d/%d" % [inv.size(), SLOT_CAPACITY]`). Keeping it in one place (either `GameState` or a shared autoload constant block) prevents the UI and logic from drifting.

#### 3. Highest-Tier Auto-Selection for Crafting Bench

The bench always shows the item with the highest comparison value in the slot. This is a pure sort + pick-first operation.

```gdscript
# Get the "best" item for the crafting bench view
func get_best_item_for_slot(slot: String) -> Item:
    var inv: Array = slot_inventories.get(slot, [])
    if inv.is_empty():
        return null
    # Sort descending by the same metric used in the old is_item_better()
    var sorted := inv.duplicate()
    sorted.sort_custom(func(a, b): return _item_sort_value(a) > _item_sort_value(b))
    return sorted[0]

func _item_sort_value(item: Item) -> float:
    if item is Weapon or item is Ring:
        return item.dps
    return float(item.tier)
```

**Why sort-and-pick vs linear max scan:** Both are O(n) for n=10. Sort is clearer to read and makes it trivial to display items in tier order later if the UI expands to show all 10.

**Why duplicate() before sort:** `Array.sort_custom()` sorts in place. Sorting the live inventory array would mutate state. Sorting a shallow duplicate leaves the inventory order stable (FIFO drop order) while bench shows best-first.

#### 4. Item Removal Pattern

Melt removes by reference, not by index. Use `Array.erase(item)` — it removes the first matching reference. For n=10 this is safe and the correct semantic ("destroy this specific item object").

```gdscript
func remove_item_from_slot(slot: String, item: Item) -> void:
    slot_inventories[slot].erase(item)
    # No index needed — erase by object reference
```

**Why not `remove_at(index)`:** Indices are unstable if items can be added or removed asynchronously (though they cannot in this single-threaded GDScript game). More importantly, the UI selection state tracks the `Item` object reference, not its position in the array. Erasing by reference keeps the UI and data model in sync without translating between index systems.

---

### UI Pattern: `ItemList` Node (NEW)

For the inventory UI showing x/10 counters and selectable items per slot tab.

| Node | Purpose | Why |
|------|---------|-----|
| `ItemList` | Built-in Godot control node displaying a vertical scrollable list of text + icon items | Has `add_item(text)`, `clear()`, `set_item_metadata(index, variant)`, `get_item_metadata(index)`, `item_selected(index)` signal. Stores the `Item` object reference as metadata, so selection resolves back to the data model without a parallel array. |
| `Label` (x/10 counter) | Displays current slot count | Simple `"%d/%d" % [count, SLOT_CAPACITY]` text update on every inventory change. No separate node type needed. |
| Tab or Button group | Slot type selector (weapon / helmet / armor / boots / ring) | Same pattern as existing `_on_item_type_selected()` in `ForgeView` — reuse or minimally extend. |

#### ItemList Usage Pattern

```gdscript
# Rebuild the list whenever inventory changes (called after add, melt, equip)
func _refresh_slot_list(slot: String) -> void:
    item_list.clear()
    var inv: Array = GameState.slot_inventories.get(slot, [])
    for item in inv:
        var label: String = item.item_name + " (" + _rarity_name(item) + ")"
        item_list.add_item(label)
        item_list.set_item_metadata(item_list.get_item_count() - 1, item)
    slot_counter_label.text = "%d/%d" % [inv.size(), GameState.SLOT_CAPACITY]
```

**Why `ItemList` over `VBoxContainer` + instantiated scenes:** `ItemList` is a single built-in node with selection, scrolling, and metadata storage. A `VBoxContainer` + preloaded scene approach would require managing child node lifecycle (add/remove children, connect signals on each child, track selected child). For a list of simple text entries with associated data, `ItemList` eliminates that overhead entirely. The customization limit (text + icon only, no arbitrary child UI) is fine for a list of item names.

**Why full rebuild (`clear()` then re-add) vs incremental update:** For n=10, clear-and-rebuild is O(10) and eliminates all stale-state bugs from partial updates. Incremental updates (insert at index, remove at index) require tracking list position against array position and break easily when items are reordered. At this scale, clear-and-rebuild is the correct choice.

**Key ItemList signals:**
- `item_selected(index: int)` — use `get_item_metadata(index)` to recover the `Item` reference. This drives the crafting bench display.
- `item_activated(index: int)` — double-click to equip (optional pattern, same metadata lookup).

---

### Serialization Pattern for Arrays of Items (EXTENDED from existing)

The existing `SaveManager._build_save_data()` iterates slots and calls `item.to_dict()`. Extend to iterate the array per slot.

#### Save (build_save_data)

```gdscript
# Replace the single-item crafting_inventory block
var slot_inv_data: Dictionary = {}
for slot in ["weapon", "helmet", "armor", "boots", "ring"]:
    var item_array: Array = GameState.slot_inventories.get(slot, [])
    var dict_array: Array = []
    for item in item_array:
        dict_array.append(item.to_dict())
    slot_inv_data[slot] = dict_array   # Array of dicts, never null

return {
    "version": SAVE_VERSION,           # Bump to 2 to trigger migration
    "slot_inventories": slot_inv_data, # NEW key
    # ... other fields unchanged
}
```

#### Load (restore_state)

```gdscript
var slot_inv_data: Dictionary = data.get("slot_inventories", {})
for slot in ["weapon", "helmet", "armor", "boots", "ring"]:
    GameState.slot_inventories[slot] = []
    var dict_array: Array = slot_inv_data.get(slot, [])
    for item_dict in dict_array:
        if item_dict is Dictionary:
            var item := Item.create_from_dict(item_dict)
            if item != null:
                GameState.slot_inventories[slot].append(item)
```

#### Save Version Migration

The save format change from `crafting_inventory` (single item) to `slot_inventories` (array) is a breaking change. Bump `SAVE_VERSION` from 1 to 2 and add a migration function:

```gdscript
# _migrate_v1_to_v2(data: Dictionary) -> Dictionary
func _migrate_v1_to_v2(data: Dictionary) -> Dictionary:
    # Old key: "crafting_inventory" -> {"weapon": {item_dict}, ...}
    # New key: "slot_inventories"   -> {"weapon": [{item_dict}], ...}
    var old_crafting: Dictionary = data.get("crafting_inventory", {})
    var new_inv: Dictionary = {}
    for slot in ["weapon", "helmet", "armor", "boots", "ring"]:
        var old_item = old_crafting.get(slot)
        if old_item != null and old_item is Dictionary:
            new_inv[slot] = [old_item]   # Wrap single item in array
        else:
            new_inv[slot] = []
    data["slot_inventories"] = new_inv
    data.erase("crafting_inventory")
    # Migrate bench item: if crafting_bench_item exists, add it to the correct slot array
    var bench_item_data = data.get("crafting_bench_item")
    if bench_item_data != null and bench_item_data is Dictionary:
        var slot := str(data.get("crafting_bench_type", "weapon"))
        if slot in new_inv:
            new_inv[slot].append(bench_item_data)
        data.erase("crafting_bench_item")
    return data
```

**Why version bump, not silent field detection:** The existing `_migrate_save()` function has the version-gated migration pattern already (`if saved_version < 2`). Using it keeps migration logic in one place and makes save compat explicit. Silent detection (`data.has("crafting_inventory")`) works but is fragile if both keys ever coexist during development.

**Confidence: HIGH** — `JSON.stringify` natively serializes `Array` of `Dictionary` as a JSON array. This is the same type that `JSON.parse_string` produces on load. The existing per-item `to_dict()` / `create_from_dict()` round-trip is already proven (verified in `save_manager.gd`). No new serialization infrastructure is needed.

---

### Signal Additions (NEW)

The existing `GameEvents` autoload should gain one new signal for inventory array changes. The existing `equipment_changed` signal is sufficient for the equip flow.

```gdscript
# game_events.gd — ADD
signal inventory_changed(slot: String)   # Emitted after any add/remove to a slot
```

**Why one signal, not separate `item_added` / `item_removed`:** The UI response to both events is identical: rebuild the `ItemList` for the affected slot and update the counter. One signal with a slot argument is sufficient and matches the granularity already used by `equipment_changed(slot, item)`.

**Why not reuse `item_crafted`:** `item_crafted` is connected to `SaveManager._on_save_trigger`. Reusing it for inventory mutations would double-trigger saves on every drop. The new `inventory_changed` signal should connect to the save trigger separately (or SaveManager can connect to it as well — the debounce in `_trigger_save()` prevents duplicate saves in the same frame).

---

## What NOT to Add

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| External inventory plugins (GodotDynamicInventorySystem, etc.) | The project has zero external dependencies by design. The feature is 50 lines of GDScript. | Native `Array`, `Dictionary`, `ItemList` — all built-in |
| SQLite or file-per-item saves | Massive over-engineering for 50 items max total (5 slots × 10). JSON round-trip is <1ms. | Extend existing `SaveManager` JSON pattern |
| `ResourceSaver.save()` / `.tres` files | Would require switching from the existing JSON save format. Breaks export/import string system (`HT1:base64:md5`). | Keep JSON, extend `to_dict()` / `create_from_dict()` |
| `var_to_bytes()` / `store_var()` for typed arrays | Loading typed arrays via `get_var()` returns an untyped `Array` — a known Godot 4 issue. Requires a cast loop anyway. | Manual `for item in array: dict_array.append(item.to_dict())` already handles this cleanly |
| `Node`-based item slots (one Node per inventory slot) | Godot nodes have lifecycle overhead (tree enter/exit, signal connection). Inventory slots are pure data. | `Dictionary` of `Array` in `GameState` autoload |
| `VBoxContainer` + preloaded scene rows for the 10-item list | 10 child node instances, per-child signal management, layout recalculation on every add/remove. Correct for complex item rows (icons, multi-button). Overkill for a simple selectable name list. | `ItemList` with `set_item_metadata()` — single node, built-in selection, built-in scroll |
| Stacked signal chains for drop → forge → inventory | Current flow: `gameplay_view` emits `item_base_found`, `main_view` routes it to `forge_view.set_new_item_base()`. This direct scene-to-scene wiring works fine for the current scope. | Keep existing signal routing. `set_new_item_base()` becomes the entry point for `add_item_to_slot()`. |
| Auto-equip on drop | The milestone spec says items go to inventory, not auto-replace. `is_item_better()` logic is removed from the drop path. | Manual equip button from inventory selection |

---

## Integration Points (What Changes vs. What Stays)

### Changes

| Location | Current | After |
|----------|---------|-------|
| `GameState.crafting_inventory` | `Dictionary` of `Item \| null` | Replaced by `GameState.slot_inventories`: `Dictionary` of `Array` |
| `GameState.crafting_bench_item` | Single `Item \| null` | Removed — bench item is derived from `slot_inventories` at display time |
| `SaveManager._build_save_data()` | Serializes single item per slot | Serializes `Array` of `to_dict()` per slot |
| `SaveManager._restore_state()` | Restores single item per slot | Restores `Array`, appends `create_from_dict()` results |
| `SaveManager.SAVE_VERSION` | 1 | 2 (triggers migration path) |
| `ForgeView.add_item_to_inventory()` | Replaces slot if `is_item_better()`, discards if not | Appends to slot array if under capacity; returns bool for full-slot feedback |
| `ForgeView._on_melt_pressed()` | Sets slot to null | Calls `Array.erase(current_item)` |
| `ForgeView._on_equip_pressed()` | Equips and sets slot to null | Equips and calls `Array.erase(current_item)` — old item in hero slot is destroyed (not returned) |
| `ForgeView.update_inventory_display()` | Label-based text summary | `ItemList` rebuild + counter label per slot |

### Stays the Same

| What | Why Unchanged |
|------|--------------|
| `Item.to_dict()` / `Item.create_from_dict()` | The per-item serialization contract is not changing. |
| `Hero.equip_item(item, slot)` | Equip logic is correct — slot gets the item, hero stats update. |
| `GameEvents.equipment_changed` | Still emitted when hero's equipped item changes. |
| `ForgeView` equip confirmation timer | The confirm-overwrite flow remains valid (old item is destroyed). |
| `StatCalculator` / `DefenseCalculator` | Not touched by inventory changes. |
| `SaveManager` export/import string format | `HT1:base64:md5` envelope is unchanged. Inner JSON gains a new key. |
| `gameplay_view.item_base_found` signal | The signal interface is unchanged — drops still flow through it. |

---

## Version Compatibility

| API | Godot Version | Notes |
|-----|--------------|-------|
| `Array.append(item)` | 4.0+ | Global Array method. Already used in `item.gd` for prefixes/suffixes arrays. |
| `Array.erase(item)` | 4.0+ | Removes first matching reference. O(n) for n=10, correct semantic. |
| `Array.size()` | 4.0+ | Already used throughout codebase. |
| `Array.duplicate()` | 4.0+ | Shallow copy for sort. Already used in `hero.gd` for affix arrays. |
| `Array.sort_custom(callable)` | 4.0+ | Lambda callable syntax (`func(a, b): ...`) is Godot 4.0+. Already used in `loot_table.gd`. |
| `ItemList.add_item(text)` | 4.0+ | Built-in Control node. No import needed. |
| `ItemList.set_item_metadata(idx, variant)` | 4.0+ | Stores any Variant (including Resource references). |
| `ItemList.get_item_metadata(idx)` | 4.0+ | Retrieves the stored Variant. Cast to `Item` at call site. |
| `ItemList.item_selected` signal | 4.0+ | Emits `index: int`. Use with `get_item_metadata(index)` for data. |
| `JSON.stringify(array)` | 4.0+ | Natively serializes `Array[Dictionary]` to JSON array. Already used in `SaveManager`. |
| `JSON.parse_string(text)` | 4.0+ | Returns `Array` when JSON root is an array, `Dictionary` otherwise. Already used. |
| `Dictionary` of `Array` | 4.0+ | Standard GDScript. No version constraint. |
| Typed arrays (`Array[Item]`) | 4.0+ | Type annotation only — does not affect runtime JSON serialization. |

---

## Alternatives Considered

| Recommended | Alternative | Why Not |
|-------------|-------------|---------|
| `ItemList` with `set_item_metadata` | `VBoxContainer` + preloaded `item_row.tscn` scenes | `VBoxContainer` is correct when rows need complex layout (icon + multiple buttons). For a 10-item name list, `ItemList` eliminates all child node lifecycle management. |
| `Array.erase(item)` by reference | `Array.remove_at(index)` | Index-based removal requires the UI to track list position. Reference-based removal works with any ordering and is stable if items are resorted. |
| Clear-and-rebuild `ItemList` on every change | Incremental insert/remove on `ItemList` | Clear-rebuild is O(10) and eliminates stale-state bugs. For n=10, performance difference is immeasurable. |
| `slot_inventories` as new `Dictionary` var | Repurpose `crafting_inventory` in place | Renaming makes the breaking change explicit and searchable. Easier to grep for migration completeness. |
| Manual `to_dict()` / `create_from_dict()` loop for arrays | Plugin (godot-improved-json, godot-object-serializer) | The existing manual pattern already works and is proven. Adding a plugin for a 10-line serialization loop is not justified. |
| Save version bump + migration function | Silent schema detection (`data.has("slot_inventories")`) | Version-gated migration is the existing pattern in `_migrate_save()`. Explicit is better — prevents ambiguous states during development. |

---

## Sources

**HIGH Confidence (Direct codebase analysis):**
- `/var/home/travelboi/Programming/hammertime/autoloads/save_manager.gd` — `_build_save_data()` and `_restore_state()` patterns; debounced save trigger; `SAVE_VERSION` migration gate
- `/var/home/travelboi/Programming/hammertime/autoloads/game_state.gd` — `crafting_inventory` Dictionary structure; `initialize_fresh_game()` slot initialization
- `/var/home/travelboi/Programming/hammertime/scenes/forge_view.gd` — `add_item_to_inventory()`, `is_item_better()`, `_on_melt_pressed()`, `_on_equip_pressed()` — all primary change sites
- `/var/home/travelboi/Programming/hammertime/models/items/item.gd` — `to_dict()` / `create_from_dict()` proven round-trip; `Array[Affix]` typed array already in production
- `/var/home/travelboi/Programming/hammertime/scenes/main_view.gd` — `item_base_found` signal routing from gameplay to forge
- `/var/home/travelboi/Programming/hammertime/autoloads/game_events.gd` — existing signal declarations; `equipment_changed`, `item_crafted` save triggers

**MEDIUM Confidence (Official Godot docs, verified via web):**
- [Godot Engine — ItemList class reference](https://docs.godotengine.org/en/stable/classes/class_itemlist.html) — `add_item`, `clear`, `set_item_metadata`, `get_item_metadata`, `item_selected` signal confirmed
- [GameDev Academy — ItemList Complete Guide](https://gamedevacademy.org/itemlist-in-godot-complete-guide/) — `set_item_metadata` pattern for binding data objects to list entries
- [Godot Forum — How to save an array of Resources with JSON](https://forum.godotengine.org/t/how-to-save-an-array-of-resources-with-json/3258) — Confirms: convert Resource to Dictionary manually, iterate array, no automatic serialization for custom Resource objects
- [Godot 4.5.1 release notes](https://godotengine.org/article/maintenance-release-godot-4-5-1/) — No changes to JSON, Array, or Resource serialization in this version
- [Godot Forum — Issues with saving an array of items](https://forum.godotengine.org/t/issues-with-saving-an-array-of-items/46056) — Confirms parameterless `_init()` requirement (already satisfied by project's `Item.new()` pattern)

**LOW Confidence (Single source, not verified against official docs):**
- `Array.sort_custom()` tween interaction issue [GitHub #114974](https://github.com/godotengine/godot/issues/114974) — VBoxContainer position recalculation on child add. Not applicable to `ItemList` (which manages layout internally).

---

*Stack research for: Hammertime — Per-Slot Multi-Item Inventory System*
*Researched: 2026-02-18*
*Confidence: HIGH — All array patterns, serialization patterns, and ItemList API verified against existing codebase and official documentation*
