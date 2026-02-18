# Architecture Research

**Domain:** Per-slot multi-item inventory system — integration with existing Hammertime ARPG architecture
**Researched:** 2026-02-18
**Confidence:** HIGH (based on direct codebase analysis of all affected files)

---

## System Overview

The v1.5 inventory rework replaces one key data shape: `crafting_inventory` values change from a single `Item` reference to an `Array[Item]`. Every component that touches `crafting_inventory` must be updated. No new autoloads, no new scenes. Two helpers (selection logic, best-item picker) get promoted into new standalone functions. The rest is plumbing.

```
┌──────────────────────────────────────────────────────────────────────┐
│                        Scene Layer                                    │
│  ┌───────────────────────────────────────────────────────────────┐   │
│  │  scenes/forge_view.gd   (MODIFIED — largest surface area)     │   │
│  │  - item type buttons → slot selection (unchanged concept)     │   │
│  │  - item_image click → apply currency to bench_item (unchanged)│   │
│  │  - inventory display → x/N counters + highest-tier name       │   │
│  │  - equip → remove item from slot array, place on hero         │   │
│  │  - melt  → remove item from slot array, destroy               │   │
│  │  - current_item still tracks the single item on bench         │   │
│  └──────────────┬────────────────────────────────────────────────┘   │
│                 │ reads/writes                                        │
├─────────────────┼────────────────────────────────────────────────────┤
│                 │              Autoload Layer                         │
│  ┌──────────────▼────────────┐   ┌───────────────────────────────┐   │
│  │  autoloads/game_state.gd  │   │  autoloads/save_manager.gd    │   │
│  │  (MODIFIED)               │   │  (MODIFIED)                   │   │
│  │  crafting_inventory:      │   │  - _build_save_data():        │   │
│  │    Dictionary[String,     │   │    serialize arrays           │   │
│  │    Array[Item]]  ← CHANGE │   │  - _restore_state():         │   │
│  │  crafting_bench_type:     │   │    deserialize arrays         │   │
│  │    String (unchanged)     │   │  - _migrate_save(): v1→v2    │   │
│  └──────────────┬────────────┘   └───────────────────────────────┘   │
│                 │                                                     │
├─────────────────┼────────────────────────────────────────────────────┤
│                 │              Drop System                            │
│  ┌──────────────▼────────────────────────────────────────────────┐   │
│  │  scenes/gameplay_view.gd (MODIFIED — drop routing only)       │   │
│  │  - item_base_found signal wired by main_view to forge_view    │   │
│  │  - _on_items_dropped() generates items → emits item_base_found│   │
│  │  - No change to combat, currency, or display logic            │   │
│  └───────────────────────────────────────────────────────────────┘   │
│                                                                       │
├───────────────────────────────────────────────────────────────────────┤
│                 Data Layer (Resources — UNCHANGED)                    │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌──────────┐  │
│  │  Item   │  │ Weapon  │  │ Helmet  │  │  Armor  │  │  Boots   │  │
│  │ (base)  │  │  Ring   │  │         │  │         │  │          │  │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘  └──────────┘  │
│  - to_dict() / create_from_dict() unchanged                          │
│  - Item class identity (is Weapon, is Helmet etc.) unchanged          │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Component Boundaries: New vs Modified vs Unchanged

### Modified Components

| File | What Changes | Specific Changes |
|------|-------------|-----------------|
| `autoloads/game_state.gd` | Data shape | `crafting_inventory` values: `Item` → `Array[Item]`; `crafting_bench_item` removed (was already unused in save); `initialize_fresh_game()` initializes arrays |
| `autoloads/save_manager.gd` | Serialize + migrate | `_build_save_data()` serializes arrays; `_restore_state()` deserializes arrays; `_migrate_save()` converts v1 single-item format to v2 array format; bump `SAVE_VERSION` to 2 |
| `scenes/forge_view.gd` | Inventory logic + display | `add_item_to_inventory()` appends to array with cap check; `_on_melt_pressed()` removes from array; `_on_equip_pressed()` removes from array; `update_inventory_display()` shows x/N format; `_load_bench_item()` picks highest-tier item from slot array |
| `scenes/main_view.gd` | None (signal wiring unchanged) | No change required — `item_base_found` signal wiring stays the same |

### New Components

No new files are required. The helpers needed (best-item selection, slot-capacity check) live as private functions inside `forge_view.gd`, which already owns inventory management logic.

### Unchanged Components

| File | Reason |
|------|--------|
| `models/items/item.gd` | `to_dict()` / `create_from_dict()` unchanged — serializes a single item |
| `models/items/*.gd` (all item subclasses) | No structural changes |
| `models/hero.gd` | Equipment slots untouched; `equip_item()` / `update_stats()` unchanged |
| `models/loot/loot_table.gd` | Drop generation unchanged |
| `models/stats/stat_calculator.gd` | Stat calculation unchanged |
| `models/stats/defense_calculator.gd` | Damage mitigation unchanged |
| `models/combat/combat_engine.gd` | Combat logic unchanged |
| `autoloads/game_events.gd` | No new signals needed; `equipment_changed` still fires on equip |
| `autoloads/item_affixes.gd` | Affix pool unchanged |
| `autoloads/tag.gd` | Tag definitions unchanged |
| `scenes/gameplay_view.gd` | Drop generation is identical — emits `item_base_found` per item; routing to forge unchanged |

---

## Integration Point 1: GameState — Data Shape Change

### Current State

```gdscript
# game_state.gd (CURRENT)
var crafting_inventory: Dictionary = {}
var crafting_bench_item: Item = null   # separate bench state
var crafting_bench_type: String = "weapon"

# initialize_fresh_game()
crafting_inventory = {
    "weapon": null,
    "helmet": null,
    "armor": null,
    "boots": null,
    "ring": null,
}
crafting_bench_item = null
```

### Required Change

```gdscript
# game_state.gd (MODIFIED)
var crafting_inventory: Dictionary = {}
# crafting_bench_item removed — bench item lives in ForgeView.current_item only
var crafting_bench_type: String = "weapon"

# initialize_fresh_game()
crafting_inventory = {
    "weapon": [],
    "helmet": [],
    "armor": [],
    "boots": [],
    "ring": [],
}
# crafting_bench_item = null  ← REMOVE THIS LINE
```

`crafting_bench_item` on GameState has been unused since direct equip/melt was implemented (ForgeView tracks `current_item` locally). Remove it to avoid confusion. `SaveManager` currently serializes it as `bench_item_data` — this field gets dropped in v2 save format.

**Confidence: HIGH** — `crafting_bench_item` is set to `null` in `_build_save_data()` at line 93 only if `GameState.crafting_bench_item != null` — and `GameState.crafting_bench_item` is never assigned anywhere except `initialize_fresh_game()` (null) and `_restore_state()` (re-null on restore). The field is orphaned state.

---

## Integration Point 2: ForgeView — Inventory Management Logic

This is the largest surface area. ForgeView manages all inventory interactions. The concept map:

| Old concept | New concept |
|-------------|------------|
| `crafting_inventory[slot]` = one `Item` or `null` | `crafting_inventory[slot]` = `Array[Item]` (0..N items) |
| `add_item_to_inventory()`: replace if better | `add_item_to_inventory()`: append if under cap, drop if full |
| `_on_melt_pressed()`: null out slot | `_on_melt_pressed()`: erase `current_item` from slot array |
| `_on_equip_pressed()`: null out slot | `_on_equip_pressed()`: erase `current_item` from slot array |
| `update_current_item()`: load from single slot | `_load_bench_item()`: pick highest-tier/DPS item from array |
| `_on_item_type_selected()`: show item if slot non-null | `_on_item_type_selected()`: show item if slot non-empty |
| inventory display: "Weapon: LightSword (Normal)" | inventory display: "Weapon (3/10): LightSword (Normal)" |

### Key Function Changes

**`add_item_to_inventory()` — no auto-replacement, cap-gated append:**

```gdscript
# forge_view.gd (MODIFIED)
const SLOT_CAPACITY: int = 10

func add_item_to_inventory(item: Item) -> void:
    var item_type: String = get_item_type(item)
    if item_type == "None":
        return

    var slot: Array = GameState.crafting_inventory[item_type]
    if slot.size() >= SLOT_CAPACITY:
        # Silently discard — slot is full
        return

    LootTable.spawn_item_with_mods(item, item.rarity)  # if not already modded
    slot.append(item)
    update_inventory_display()
    # Auto-select if bench is currently empty for this slot type
    if current_item == null and GameState.crafting_bench_type == item_type:
        _load_bench_item(item_type)
```

Note: `gameplay_view._on_items_dropped()` already calls `LootTable.spawn_item_with_mods()` before emitting the signal, so `add_item_to_inventory()` receives an already-modded item. No double-modding issue.

**`_load_bench_item()` — select highest-tier item for the slot:**

```gdscript
# forge_view.gd (NEW PRIVATE FUNCTION)
func _load_bench_item(slot_type: String) -> void:
    var slot: Array = GameState.crafting_inventory.get(slot_type, [])
    if slot.is_empty():
        current_item = null
        return

    # For damage slots (weapon, ring): pick highest DPS
    # For defense slots (helmet, armor, boots): pick highest tier
    var best: Item = slot[0]
    for item: Item in slot:
        if best is Weapon or best is Ring:
            if item.dps > best.dps:
                best = item
        else:
            if item.tier > best.tier:
                best = item
    current_item = best
```

**`_on_melt_pressed()` — erase from array:**

```gdscript
# forge_view.gd (MODIFIED)
func _on_melt_pressed() -> void:
    if current_item == null:
        return
    var slot_name: String = get_item_type(current_item)
    if slot_name == "None":
        return

    var slot: Array = GameState.crafting_inventory[slot_name]
    slot.erase(current_item)
    current_item = null

    _load_bench_item(slot_name)  # pick next-best item for bench
    update_item_stats_display()
    update_melt_equip_states()
    update_inventory_display()
```

**`_on_equip_pressed()` — erase from array, old equipped item deleted:**

```gdscript
# forge_view.gd (MODIFIED)
func _on_equip_pressed() -> void:
    if current_item == null:
        return
    var slot_name: String = get_item_type(current_item)
    if slot_name == "None":
        return

    var existing: Item = GameState.hero.equipped_items.get(slot_name)
    if existing != null and not equip_confirm_pending:
        equip_confirm_pending = true
        equip_button.text = "Confirm Overwrite?"
        equip_timer.start()
        return

    equip_confirm_pending = false
    equip_timer.stop()
    equip_button.text = "Equip"

    # Equip: old equipped item is destroyed (not returned to inventory)
    GameState.hero.equip_item(current_item, slot_name)
    GameEvents.equipment_changed.emit(slot_name, current_item)
    GameEvents.item_crafted.emit(current_item)

    # Remove from inventory array
    GameState.crafting_inventory[slot_name].erase(current_item)
    current_item = null

    _load_bench_item(slot_name)  # load next-best for bench
    update_hero_stats_display()
    update_item_stats_display()
    update_melt_equip_states()
    update_inventory_display()
    equipment_changed.emit()
```

**`_on_item_type_selected()` — guard on empty array:**

```gdscript
# forge_view.gd (MODIFIED)
func _on_item_type_selected(item_type: String) -> void:
    equip_confirm_pending = false
    if equip_timer != null:
        equip_timer.stop()
    equip_button.text = "Equip"

    # Guard: no items in this slot
    var slot: Array = GameState.crafting_inventory.get(item_type, [])
    if slot.is_empty():
        print("No ", item_type, " in inventory - selection ignored")
        return

    GameState.crafting_bench_type = item_type
    _load_bench_item(item_type)
    update_item_type_button_states()
    update_item_stats_display()
    update_melt_equip_states()
```

**`update_inventory_display()` — x/N counter format:**

```gdscript
# forge_view.gd (MODIFIED)
func update_inventory_display() -> void:
    if inventory_label == null:
        return

    var display_text: String = "Crafting Inventory:\n\n"

    for item_type in inventory_types:
        var slot: Array = GameState.crafting_inventory.get(item_type, [])
        var type_name: String = item_type.capitalize()
        var count: int = slot.size()

        display_text += "%s (%d/%d)" % [type_name, count, SLOT_CAPACITY]
        if count > 0:
            # Show the current bench item name, or best item name
            var display_item: Item = current_item if (
                current_item != null and get_item_type(current_item) == item_type
            ) else null
            if display_item == null:
                display_item = slot[0]  # fallback to first
            var rarity_name: String = "Normal"
            match display_item.rarity:
                Item.Rarity.MAGIC: rarity_name = "Magic"
                Item.Rarity.RARE:  rarity_name = "Rare"
            display_text += ": " + display_item.item_name + " (" + rarity_name + ")"
        display_text += "\n"

    inventory_label.text = display_text
```

**`_ready()` initialization — starting item goes into array, no saved items check:**

```gdscript
# forge_view.gd (MODIFIED)
func _ready() -> void:
    # ... (all button/signal wiring unchanged) ...

    # Load crafting inventory from GameState
    var has_saved_items := false
    for type_name in inventory_types:
        if not GameState.crafting_inventory.get(type_name, []).is_empty():
            has_saved_items = true
            break

    if not has_saved_items:
        var starting_weapon := LightSword.new()
        add_item_to_inventory(starting_weapon)

    # Set bench from saved type or first available
    var selected_type: String = GameState.crafting_bench_type
    var slot: Array = GameState.crafting_inventory.get(selected_type, [])
    if slot.is_empty():
        selected_type = ""
        for type_name in inventory_types:
            if not GameState.crafting_inventory.get(type_name, []).is_empty():
                selected_type = type_name
                break
    if selected_type != "":
        GameState.crafting_bench_type = selected_type
        _load_bench_item(selected_type)
    else:
        current_item = null

    # ... (update_* calls unchanged) ...
```

---

## Integration Point 3: SaveManager — Array Serialization and Migration

### What Must Change

The save format changes from a dict of single item dictionaries to a dict of arrays of item dictionaries.

**Old format (v1) — `crafting_inventory`:**
```json
"crafting_inventory": {
  "weapon": { "item_type": "LightSword", "tier": 3, ... },
  "helmet": null,
  "armor":  null,
  "boots":  null,
  "ring":   null
},
"crafting_bench_item": null
```

**New format (v2) — `crafting_inventory`:**
```json
"crafting_inventory": {
  "weapon": [
    { "item_type": "LightSword", "tier": 3, ... },
    { "item_type": "LightSword", "tier": 5, ... }
  ],
  "helmet": [],
  "armor":  [],
  "boots":  [],
  "ring":   []
}
```

`crafting_bench_item` is dropped entirely from v2 format. `crafting_bench_type` is preserved unchanged.

### `_build_save_data()` — serialize arrays:

```gdscript
# save_manager.gd (MODIFIED)
var crafting_inv := {}
for type_name in GameState.crafting_inventory:
    var slot: Array = GameState.crafting_inventory[type_name]
    var serialized_slot: Array = []
    for item in slot:
        if item != null:
            serialized_slot.append(item.to_dict())
    crafting_inv[type_name] = serialized_slot

return {
    "version": SAVE_VERSION,   # now 2
    "timestamp": Time.get_unix_time_from_system(),
    "hero_equipment": hero_equipment,
    "currencies": GameState.currency_counts.duplicate(),
    "crafting_inventory": crafting_inv,
    # "crafting_bench_item" dropped
    "crafting_bench_type": GameState.crafting_bench_type,
    "max_unlocked_level": GameState.max_unlocked_level,
    "area_level": GameState.area_level,
}
```

### `_restore_state()` — deserialize arrays:

```gdscript
# save_manager.gd (MODIFIED)
var saved_crafting: Dictionary = data.get("crafting_inventory", {})
for type_name in saved_crafting:
    var raw_slot = saved_crafting[type_name]
    var restored_slot: Array = []
    if raw_slot is Array:
        for item_data in raw_slot:
            if item_data is Dictionary:
                var item := Item.create_from_dict(item_data)
                if item != null:
                    restored_slot.append(item)
    elif raw_slot is Dictionary:
        # Shouldn't happen post-migration but guard gracefully
        var item := Item.create_from_dict(raw_slot)
        if item != null:
            restored_slot.append(item)
    GameState.crafting_inventory[type_name] = restored_slot

# crafting_bench_item restore removed
GameState.crafting_bench_type = str(data.get("crafting_bench_type", "weapon"))
```

### `_migrate_save()` — v1 to v2:

```gdscript
# save_manager.gd (MODIFIED)
const SAVE_VERSION = 2   # bumped from 1

func _migrate_save(data: Dictionary) -> Dictionary:
    var saved_version: int = int(data.get("version", 1))

    if saved_version < 2:
        print("SaveManager: Migrating save from v%d to v2" % saved_version)
        data = _migrate_v1_to_v2(data)

    data["version"] = SAVE_VERSION
    return data

func _migrate_v1_to_v2(data: Dictionary) -> Dictionary:
    # Convert crafting_inventory from single-item to array format
    var old_inv: Dictionary = data.get("crafting_inventory", {})
    var new_inv: Dictionary = {}
    for type_name in old_inv:
        var old_item = old_inv[type_name]
        if old_item is Dictionary:
            new_inv[type_name] = [old_item]  # wrap single item in array
        else:
            new_inv[type_name] = []          # null → empty array
    data["crafting_inventory"] = new_inv

    # Drop crafting_bench_item (was always null in practice)
    data.erase("crafting_bench_item")

    return data
```

**Confidence: HIGH** — `_migrate_save()` stub already exists at `save_manager.gd:159` with the exact comment placeholder shown in the file. `SAVE_VERSION = 1` is line 4. The migration pattern is established.

---

## Integration Point 4: Drop Flow — LootTable to Inventory Array

### Current Drop Flow

```
gameplay_view._on_items_dropped(level, count)
    → for i in range(count):
        item_base = get_random_item_base(level)  # creates + mods item
        item_bases_collected.append(item_base)
        item_base_found.emit(item_base)
    ↓ (wired by main_view)
forge_view.set_new_item_base(item_base)
    → add_item_to_inventory(item_base)
        → existing item replaced if new is better
```

### New Drop Flow

```
gameplay_view._on_items_dropped(level, count)
    → (UNCHANGED — same code)
    item_base_found.emit(item_base)
    ↓ (wired by main_view — UNCHANGED)
forge_view.set_new_item_base(item_base)
    → add_item_to_inventory(item_base)
        → append to slot array if under cap
        → silently discard if at cap
```

`gameplay_view.gd` requires zero changes. `main_view.gd` signal wiring requires zero changes. Only `add_item_to_inventory()` in `forge_view.gd` changes behavior.

The existing `is_item_better()` function in `forge_view.gd` is no longer used for drop routing (drops always append now). It remains useful only for the equip comparison display (`get_stat_comparison_text()` and `update_hero_stats_display()` contexts) — but the function itself can stay as-is since those paths still use it for UI display. Alternatively, it can be renamed to make purpose clear. No behavior change required.

---

## Integration Point 5: ForgeView Starting Item — Fresh Game Guard

The existing `_ready()` guard checks `crafting_inventory.get(type_name) != null` for each slot. After the change, the guard must check `.is_empty()` on the array. The logic is otherwise identical.

Starting weapon adds via `add_item_to_inventory()` which now appends to the array. The `LightSword.new()` creation does not call `spawn_item_with_mods` — it was always created without mods (Normal rarity, no affixes), and that behavior is unchanged.

---

## Data Flow Diagrams

### Flow 1: Item Drop → Inventory Array

```
[map_completed signal → gameplay_view._on_map_completed()]
    ↓
[GameEvents.items_dropped.emit(level, count)]
    ↓
[gameplay_view._on_items_dropped(level, count)]
    for each item:
        item_base = get_random_item_base(level)   # creates + mods via LootTable
        item_base_found.emit(item_base)
    ↓ (wired by main_view.gd — UNCHANGED)
[forge_view.set_new_item_base(item_base)]
    ↓
[forge_view.add_item_to_inventory(item)]
    slot = GameState.crafting_inventory[item_type]  # Array
    if slot.size() >= SLOT_CAPACITY:
        return   # discard silently
    slot.append(item)
    if current_item == null:
        _load_bench_item(item_type)   # auto-select if bench empty
    update_inventory_display()
```

### Flow 2: Player Selects Slot → Bench Loads Best Item

```
[Player clicks WeaponButton]
    ↓
[forge_view._on_item_type_selected("weapon")]
    slot = GameState.crafting_inventory["weapon"]
    if slot.is_empty(): return
    GameState.crafting_bench_type = "weapon"
    _load_bench_item("weapon")
        → iterate slot array
        → pick highest DPS (weapon/ring) or highest tier (armor slots)
        → current_item = best
    update_item_type_button_states()
    update_item_stats_display()
    update_melt_equip_states()
```

### Flow 3: Player Equips Bench Item

```
[Player clicks Equip]
    ↓
[forge_view._on_equip_pressed()]
    existing = GameState.hero.equipped_items.get(slot_name)
    if existing != null and not confirmed:
        → show "Confirm Overwrite?" (unchanged behavior)
        return
    GameState.hero.equip_item(current_item, slot_name)   # old equipped DELETED
    GameEvents.equipment_changed.emit(slot_name, current_item)
    GameState.crafting_inventory[slot_name].erase(current_item)
    current_item = null
    _load_bench_item(slot_name)   # load next-best item for bench
    update_hero_stats_display()
    update_item_stats_display()
    update_inventory_display()
```

### Flow 4: Save / Load Round-Trip

```
[SaveManager._build_save_data()]
    for each slot in crafting_inventory:
        serialize Array[Item] → Array[Dict]
    write "version": 2, "crafting_inventory": {...arrays...}

[SaveManager.load_game()]
    parse JSON
    _migrate_save(data):
        if version < 2:
            wrap single-item dicts in arrays
            erase "crafting_bench_item"
    _restore_state(data):
        for each slot:
            deserialize Array[Dict] → Array[Item]
            GameState.crafting_inventory[slot] = restored array
        crafting_bench_type restored (unchanged)

[forge_view._ready()]
    reads GameState.crafting_inventory[type] arrays
    sets current_item via _load_bench_item()
```

---

## Architectural Patterns

### Pattern 1: Array-as-Slot-Inventory with Const Capacity

**What:** Each slot holds an `Array[Item]` with a compile-time capacity constant. All write paths check `slot.size() >= SLOT_CAPACITY` before appending. No dedicated Inventory class needed.

**When to use:** When the inventory structure is simple (same capacity per slot, no slot metadata) and all access is through one owner (ForgeView). A dedicated class would add indirection with no benefit at this scale.

**Why not Dictionary-of-Item:** The previous single-item-per-slot model stored `null` as absence. Arrays express "zero items" naturally — no null checks, no ambiguity between "slot exists but empty" and "slot doesn't exist."

**Example:**
```gdscript
# GameState — slots are always initialized as empty arrays:
crafting_inventory = {
    "weapon": [],
    "helmet": [],
    "armor":  [],
    "boots":  [],
    "ring":   [],
}

# ForgeView write guard:
const SLOT_CAPACITY: int = 10
var slot: Array = GameState.crafting_inventory[item_type]
if slot.size() >= SLOT_CAPACITY:
    return  # drop the item
slot.append(item)
```

### Pattern 2: Best-Item Selection at Bench Load Time

**What:** The "bench item" is the item currently selected for crafting. It is chosen from the slot array at load time (`_load_bench_item()`), not on every frame. The selection criteria match the existing `is_item_better()` logic: DPS for weapon/ring, tier for armor slots.

**When to use:** Whenever there are multiple items in a slot and the UI needs to show one. Selection is deferred until the slot is activated (tab switch, drop received into empty slot).

**Why not auto-select on every item added:** If the player is crafting an item on the bench and a new drop arrives in the same slot, the bench item should not silently switch. Only switch when bench is null (slot was empty).

**Example:**
```gdscript
func _load_bench_item(slot_type: String) -> void:
    var slot: Array = GameState.crafting_inventory.get(slot_type, [])
    if slot.is_empty():
        current_item = null
        return
    var best: Item = slot[0]
    for item: Item in slot:
        if best is Weapon or best is Ring:
            if item.dps > best.dps:
                best = item
        else:
            if item.tier > best.tier:
                best = item
    current_item = best
```

### Pattern 3: Erase-by-Reference for Array Item Removal

**What:** `Array.erase(item)` removes the first element that matches the reference. Since Items are Resource objects and the same reference is used throughout (ForgeView holds the same object that's in the array), this is safe and requires no index tracking.

**When to use:** When the item reference is available at removal time (which it always is — `current_item` is the reference we want to erase).

**Why not index-based removal:** Index tracking introduces state that can go stale if items are added or removed from other paths. Reference-based erase is O(n) on the array but n is at most 10, making it negligible.

**Example:**
```gdscript
# current_item is the reference to the Item object in the array:
GameState.crafting_inventory[slot_name].erase(current_item)
current_item = null
```

### Pattern 4: Migration-Before-Schema: Write Migration Before Changing Format

**What:** `_migrate_v1_to_v2()` in `save_manager.gd` must be written and tested before any `crafting_inventory` format changes are made to `_build_save_data()` or `_restore_state()`. This means the migration runs on v1 saves to produce v2 format before the restore path reads them.

**Why this order:** If `_restore_state()` is changed to expect arrays before migration is written, any existing save file will fail to load. The window between those two changes is a save-corruption risk even in development.

**Example migration:**
```gdscript
func _migrate_v1_to_v2(data: Dictionary) -> Dictionary:
    var old_inv: Dictionary = data.get("crafting_inventory", {})
    var new_inv: Dictionary = {}
    for type_name in old_inv:
        var old_item = old_inv[type_name]
        if old_item is Dictionary:
            new_inv[type_name] = [old_item]
        else:
            new_inv[type_name] = []
    data["crafting_inventory"] = new_inv
    data.erase("crafting_bench_item")
    return data
```

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Auto-Replacing Bench Item on Every Drop

**What people do:** Call `_load_bench_item()` every time `add_item_to_inventory()` is called, unconditionally refreshing the bench.

**Why it's wrong:** If the player has a crafted item on the bench with rare mods applied and a new drop arrives in the same slot, the bench switches away from their work-in-progress. This is disorienting and could cause accidental hammer application to the wrong item.

**Do this instead:** Only call `_load_bench_item()` when `current_item == null` (bench was empty). When a new item arrives and the bench already has an item for that slot, just update `inventory_display` and let the player manually switch if they want to.

### Anti-Pattern 2: Returning Old Equipped Item to Inventory on Equip

**What people do:** When equipping a bench item that replaces an existing equipped item, push the old equipped item back into the slot array.

**Why it's wrong:** The v1.5 design explicitly specifies "equip commits: old equipped item deleted, not returned." Returning it creates unbounded inventory growth (equip-unequip cycles fill the slot) and complicates the equip flow. The two-click confirmation already protects against accidental overwrites.

**Do this instead:** `GameState.hero.equip_item(current_item, slot_name)` already overwrites the dict reference. The old item's memory is freed by GDScript's reference counting. No return path needed.

### Anti-Pattern 3: Storing Inventory Arrays as Typed Array[Item] on GameState

**What people do:** Use `var crafting_inventory: Dictionary[String, Array[Item]]` or typed slot properties.

**Why it's wrong:** Godot 4.x Dictionary does not support generic type parameters in GDScript at this time. Using `Array[Item]` as a value type in an untyped Dictionary causes type erasure and potentially runtime errors when assigning. The existing code uses untyped Dictionary values throughout (`item = GameState.crafting_inventory[slot]`).

**Do this instead:** Keep `crafting_inventory: Dictionary` with untyped values, but document and enforce via code comments that each value is an `Array` of `Item`. Cast locally when needed: `var slot: Array = GameState.crafting_inventory[item_type]`.

### Anti-Pattern 4: Serializing `current_item` or Bench Selection Index

**What people do:** Save `current_item` reference or its index in the slot array to restore bench state exactly on load.

**Why it's wrong:** `current_item` is a transient UI state. The item reference is not stable across save/load (new object instances are created by `create_from_dict()`). Trying to restore by index is fragile if array order changes. `crafting_bench_type` (which slot was selected) is sufficient and already saved.

**Do this instead:** On load, restore `crafting_bench_type` from save (already done), then call `_load_bench_item(crafting_bench_type)` which picks the best item automatically. Players accept that the highest-tier item is pre-selected after loading.

### Anti-Pattern 5: Adding an Inventory Signal to GameEvents

**What people do:** Add `signal inventory_changed(slot: String)` to `game_events.gd` to propagate inventory updates across scenes.

**Why it's wrong:** Nothing outside `forge_view.gd` needs to react to inventory changes. `gameplay_view.gd` does not display inventory. `save_manager.gd` reads `GameState.crafting_inventory` directly at save time (event-driven by `item_crafted` and `equipment_changed`, both of which are already wired). Adding a new signal creates public surface area for a private concern.

**Do this instead:** Keep all inventory update calls (`update_inventory_display()`, `update_melt_equip_states()`) inside `forge_view.gd`. This is already the pattern for all existing inventory display calls.

---

## Build Order and Phase Dependencies

Dependencies flow data-model-first, then persistence, then UI. The UI cannot be tested until GameState holds the right shape; save/load cannot be tested until the shape is right and the migration exists.

```
Phase 1: GameState data shape change (prerequisite for everything)
    Files: autoloads/game_state.gd
    Changes:
      - crafting_inventory values: null → []
      - initialize_fresh_game(): initialize arrays not nulls
      - crafting_bench_item: remove field
    Gate: ForgeView._ready() can read arrays without crashing

Phase 2: SaveManager — migration first, then serialization
    Files: autoloads/save_manager.gd
    CRITICAL: Write _migrate_v1_to_v2() BEFORE changing _build_save_data()
    Changes:
      - SAVE_VERSION = 2
      - _migrate_v1_to_v2(): wrap single items in arrays, drop bench_item key
      - _build_save_data(): serialize Array[Item] → Array[Dict]
      - _restore_state(): deserialize Array[Dict] → Array[Item]
    Gate: Load an existing v1 save file and verify items survive migration

Phase 3: ForgeView core logic (depends on Phase 1)
    Files: scenes/forge_view.gd
    Changes:
      - SLOT_CAPACITY constant
      - add_item_to_inventory(): append with cap check
      - _load_bench_item(): best-item picker (NEW private function)
      - _on_item_type_selected(): guard on empty array
      - _on_melt_pressed(): erase from array
      - _on_equip_pressed(): erase from array
      - update_current_item(): replaced by _load_bench_item()
      - _ready(): fresh-game guard uses is_empty()
    Gate: Can add items, melt items, equip items without crashing

Phase 4: ForgeView display (depends on Phase 3)
    Files: scenes/forge_view.gd
    Changes:
      - update_inventory_display(): x/N counter format
    Gate: Inventory panel shows correct counts; label does not overflow

Phase 5: Integration verification
    - New game: starts with 1 weapon, inventory shows "Weapon (1/10)"
    - Drop received: weapon slot increases to 2/10
    - Drop at cap (10): additional drop silently discarded, count stays 10/10
    - Melt: count decreases, bench loads next-best item
    - Equip: count decreases, old equipped item gone, bench loads next-best
    - Save/load round-trip: all arrays survive, crafting_bench_type restored
    - V1 save migration: single items promoted to arrays with no data loss
```

**Critical path:** Phase 1 → Phase 2 (migration written) → Phase 3 → Phase 4 → Phase 5

Phase 2 migration must be written before Phase 3 is merged, because Phase 3 changes `_restore_state()` which must work with both v1 (migrated) and v2 saves.

---

## Save Format Versioning

| Version | Crafting Inventory Format | `crafting_bench_item` |
|---------|--------------------------|----------------------|
| v1 (current) | `{"weapon": {item_dict} or null, ...}` | present (always null in practice) |
| v2 (new) | `{"weapon": [{item_dict}, ...], ...}` (empty arrays for empty slots) | absent |

**Existing saves:** When `SAVE_VERSION = 2` ships, any v1 save is migrated automatically on first load. The v1 → v2 migration wraps non-null single item dicts in `[...]` arrays and converts nulls to `[]`. Item data within the dicts is unchanged — all the affix fields, tier, rarity, etc. survive exactly. DPS and stats recalculate from affixes as they always have.

**Export strings:** `export_save_string()` calls `_build_save_data()` which will now produce v2 format. Old export strings (v1) can still be imported — `import_save_string()` calls `_migrate_save()` which handles v1 → v2 conversion. Existing import/export flow requires no change beyond the save_manager modifications above.

---

## Sources

- Direct codebase analysis: `autoloads/game_state.gd`, `autoloads/save_manager.gd`, `scenes/forge_view.gd`, `scenes/gameplay_view.gd`, `scenes/main_view.gd`, `models/hero.gd`, `models/items/item.gd`, `autoloads/game_events.gd`
- `save_manager.gd:159` — `_migrate_save()` stub confirmed, placeholder comment already present
- `save_manager.gd:4` — `SAVE_VERSION = 1` confirmed as current baseline
- `game_state.gd:9-10` — `crafting_bench_item` and `crafting_inventory` field declarations
- `forge_view.gd:420-434` — `add_item_to_inventory()` current implementation confirms single-item replacement logic
- `forge_view.gd:465-472` — `is_item_better()` DPS vs tier logic confirmed; reusable for `_load_bench_item()`
- `gameplay_view.gd:185-189` — `_on_items_dropped()` already calls `LootTable.spawn_item_with_mods()` before emitting; no double-modding risk
- `main_view.gd:25-26` — Signal wiring `item_base_found` → `forge_view.set_new_item_base` confirmed; unchanged

---
*Architecture research for: Hammertime v1.5 — Per-slot multi-item inventory rework*
*Researched: 2026-02-18*
*Confidence: HIGH — based on direct code analysis of all 8 affected files*
