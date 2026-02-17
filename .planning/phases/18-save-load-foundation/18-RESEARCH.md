# Phase 18: Save/Load Foundation - Research

**Researched:** 2026-02-17
**Domain:** Godot 4.x game state persistence (FileAccess, JSON, user:// path)
**Confidence:** HIGH

## Summary

Hammertime's save/load implementation is straightforward because the game state is small and well-centralized. All mutable state lives in two places: `GameState` (hero equipment, currency counts) and `CraftingView` (crafting inventory, bench contents). The combat engine tracks `area_level` and `max_unlocked_level` which also need persisting.

The recommended approach is JSON-based serialization using `FileAccess` to `user://hammertime_save.json`. While Godot's `ResourceSaver`/`ResourceLoader` or `store_var()`/`get_var()` are options, JSON is the best fit here because Phase 21 requires export/import as copyable strings — JSON is human-readable, base64-encodable, and universally parseable. This also future-proofs for potential web export or external tooling.

**Primary recommendation:** Create a `SaveManager` autoload with `to_dict()`/`from_dict()` serialization methods on game objects, JSON file I/O via `FileAccess`, a `Timer`-based auto-save, and event-driven saves triggered through `GameEvents` signals.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Auto-save + manual save button
- Manual save button lives in a settings/menu area (gear icon or similar), not on the main game screen
- Auto-save shows a brief toast/indicator (1-2 seconds, then fades) — e.g., small "Saved" text
- Manual save shows the same brief toast — consistent feedback, no special treatment
- New Game option also lives in the same settings/menu
- Auto-load last save on launch — no title screen or menu
- If no save exists (first launch), start a fresh game immediately — no welcome screen
- Assume loading is instant — no loading indicator needed (save data is small)
- If save is corrupted/fails to load: start fresh game + warning toast ("Save could not be loaded")
- **Saved:** Hero equipment, currencies, crafting inventory, crafting bench contents, highest area unlocked
- **Not saved:** Mid-combat state (combat restarts from beginning of area on load), derived stats (recalculated from equipment on load)
- Stats are derived from equipment on load — single source of truth, no redundant stat storage
- Area progress tracked as highest area unlocked (all previous areas available)
- Crafting bench state persists — whatever's on the bench stays across sessions
- New Game requires double confirmation (first click -> "Are you sure?", second click -> wipes save)
- New Game immediately auto-saves the fresh state to disk
- Auto-save failure shows a simple "Save failed" toast — no advice, no gameplay blocking
- Corrupted save on load -> fresh game + warning (covered in startup flow above)

### Claude's Discretion
- Save file format and location (JSON, Godot resource, user:// path)
- Save version schema design
- Auto-save timer implementation
- Toast/indicator visual design and positioning
- Settings menu layout and styling

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SAVE-01 | Player's full game state persists across sessions (hero equipment, currencies, area progress, crafting inventory) | JSON serialization of game objects via to_dict()/from_dict() pattern; FileAccess to user:// path |
| SAVE-02 | Game auto-saves every 5 minutes and on significant events (item crafted, area completed, item equipped) | Timer node in SaveManager autoload + GameEvents signal connections |
| SAVE-03 | Save format includes version tracking for future migration compatibility | Version field in save JSON root; migration function array pattern |
</phase_requirements>

## Standard Stack

### Core
| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| FileAccess | Godot 4.x built-in | File I/O for reading/writing save data | Official Godot API; handles user:// path resolution across platforms |
| JSON | Godot 4.x built-in | Serialization format | Human-readable, base64-encodable for Phase 21 export/import, universal |
| Timer | Godot 4.x built-in | Auto-save interval timing | Built-in node, integrates with scene tree, pausable |

### Supporting
| Component | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| GameEvents (existing autoload) | Project | Signal bus for save triggers | Connect item_crafted, equipment_changed, area_cleared signals to auto-save |
| var2str/str2var | Godot 4.x built-in | NOT used — JSON preferred | Would be simpler but doesn't support Phase 21 export strings |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| JSON + FileAccess | ResourceSaver/ResourceLoader | Resources require @export annotations on all persisted vars; current data model uses plain vars; would require significant refactor for no benefit |
| JSON + FileAccess | store_var/get_var (binary) | More compact but not human-readable; Phase 21 needs string export which requires JSON anyway |
| JSON + FileAccess | ConfigFile | Only supports flat key/value; can't represent nested item/affix structures cleanly |

## Architecture Patterns

### Recommended Project Structure
```
autoloads/
├── save_manager.gd      # NEW: SaveManager autoload (save/load/auto-save)
├── game_state.gd         # MODIFIED: Add to_dict()/from_dict(), auto-load on _ready()
├── game_events.gd        # MODIFIED: Add save_completed signal
scenes/
├── main_view.gd          # MODIFIED: Add settings menu button, toast display
├── save_toast.tscn        # NEW: Small "Saved" indicator scene
├── save_toast.gd          # NEW: Toast fade-in/fade-out logic
├── settings_menu.tscn     # NEW: Settings panel (Save, New Game)
├── settings_menu.gd       # NEW: Settings menu logic
```

### Pattern 1: Centralized SaveManager Autoload
**What:** Single autoload responsible for all save/load operations. Game objects implement `to_dict()` and `from_dict()` for serialization. SaveManager orchestrates gathering and restoring state.
**When to use:** Always — this is the core pattern.
**Example:**
```gdscript
# autoloads/save_manager.gd
extends Node

const SAVE_PATH = "user://hammertime_save.json"
const SAVE_VERSION = 1
const AUTO_SAVE_INTERVAL = 300.0  # 5 minutes

var auto_save_timer: Timer

func _ready() -> void:
    auto_save_timer = Timer.new()
    auto_save_timer.wait_time = AUTO_SAVE_INTERVAL
    auto_save_timer.one_shot = false
    auto_save_timer.timeout.connect(_on_auto_save)
    add_child(auto_save_timer)
    auto_save_timer.start()

    # Connect event-driven saves
    GameEvents.item_crafted.connect(_on_save_trigger)
    GameEvents.equipment_changed.connect(_on_equipment_save_trigger)
    GameEvents.area_cleared.connect(_on_area_save_trigger)

func save_game() -> bool:
    var save_data := {
        "version": SAVE_VERSION,
        "timestamp": Time.get_unix_time_from_system(),
        "hero": _serialize_hero(),
        "currencies": GameState.currency_counts.duplicate(),
        "crafting_inventory": _serialize_crafting_inventory(),
        "crafting_bench": _serialize_crafting_bench(),
        "area_progress": _serialize_area_progress(),
    }
    var json_string := JSON.stringify(save_data, "\t")
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        push_warning("Save failed: " + str(FileAccess.get_open_error()))
        return false
    file.store_string(json_string)
    return true

func load_game() -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        return false
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return false
    var json_string := file.get_as_text()
    var parsed = JSON.parse_string(json_string)
    if parsed == null or not parsed is Dictionary:
        return false
    # Migrate if needed
    parsed = _migrate_save(parsed)
    # Restore state
    _deserialize_hero(parsed.get("hero", {}))
    _restore_currencies(parsed.get("currencies", {}))
    _restore_crafting_inventory(parsed.get("crafting_inventory", {}))
    _restore_crafting_bench(parsed.get("crafting_bench", {}))
    _restore_area_progress(parsed.get("area_progress", {}))
    return true
```

### Pattern 2: Object-Level Serialization (to_dict/from_dict)
**What:** Each game object knows how to serialize/deserialize itself. SaveManager calls these methods.
**When to use:** For every persisted object (Item, Affix, Hero equipment slots).
**Example:**
```gdscript
# In Affix class — add serialization
func to_dict() -> Dictionary:
    return {
        "affix_name": affix_name,
        "type": type,  # enum int value
        "value": value,
        "tier": tier,
        "tags": tags,
        "stat_types": stat_types,
        "tier_range_x": tier_range.x,
        "tier_range_y": tier_range.y,
        "base_min": base_min,
        "base_max": base_max,
        "min_value": min_value,
        "max_value": max_value,
    }

static func from_dict(data: Dictionary) -> Affix:
    var affix := Affix.new(
        data.get("affix_name", ""),
        data.get("type", AffixType.PREFIX),
        data.get("base_min", 0),
        data.get("base_max", 0),
        data.get("tags", []),
        data.get("stat_types", []),
        Vector2i(data.get("tier_range_x", 1), data.get("tier_range_y", 8))
    )
    # Override the randomized values with saved values
    affix.value = data.get("value", 0)
    affix.tier = data.get("tier", 1)
    affix.min_value = data.get("min_value", 0)
    affix.max_value = data.get("max_value", 0)
    return affix
```

### Pattern 3: Item Type Registry for Deserialization
**What:** A mapping from item type string to constructor, so the loader can recreate the correct subclass.
**When to use:** When deserializing items — need to know which class to instantiate.
**Example:**
```gdscript
# In SaveManager or a dedicated registry
const ITEM_TYPES := {
    "LightSword": LightSword,
    "BasicHelmet": BasicHelmet,
    "BasicArmor": BasicArmor,
    "BasicBoots": BasicBoots,
    "BasicRing": BasicRing,
}

func _deserialize_item(data: Dictionary) -> Item:
    var item_type: String = data.get("item_type", "")
    if item_type not in ITEM_TYPES:
        push_warning("Unknown item type: " + item_type)
        return null
    var item: Item = ITEM_TYPES[item_type].new()
    # Restore rarity, affixes, etc. from data
    item.rarity = data.get("rarity", Item.Rarity.NORMAL)
    # ... restore affixes
    return item
```

### Pattern 4: Version Migration Chain
**What:** Array of migration functions, one per version bump. On load, apply all migrations between saved version and current version sequentially.
**When to use:** When save format changes in future phases.
**Example:**
```gdscript
const SAVE_VERSION = 1

# Future: add migration functions here
# var migrations = [_migrate_v1_to_v2, _migrate_v2_to_v3]
var migrations: Array[Callable] = []

func _migrate_save(data: Dictionary) -> Dictionary:
    var saved_version: int = data.get("version", 1)
    while saved_version < SAVE_VERSION:
        if saved_version - 1 < migrations.size():
            data = migrations[saved_version - 1].call(data)
        saved_version += 1
    data["version"] = SAVE_VERSION
    return data
```

### Anti-Patterns to Avoid
- **Saving derived stats:** Hero DPS, defense totals, etc. are calculated from equipment. Saving them creates dual sources of truth. Recalculate on load via `hero.update_stats()`.
- **Saving object references:** Items in equipped_items are object references. Serialize the data, not the object. On load, create new instances from the serialized data.
- **Saving mid-combat state:** Combat is transient. On load, combat restarts fresh. Don't persist timer states, pack HP, or fight progress.
- **Using ResourceSaver for saves:** Current data model uses plain `var` declarations (not `@export`). ResourceSaver requires `@export` for persistence. Refactoring all models to use `@export` would be a large, risky change for no benefit.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| File path resolution | Manual OS-specific paths | `user://` prefix with FileAccess | Godot handles platform-specific user data paths automatically |
| JSON parsing | Manual string parsing | `JSON.parse_string()` / `JSON.stringify()` | Built-in, handles edge cases, returns null on failure |
| Timer management | Manual delta accumulation | `Timer` node | Built-in, pausable, signal-based, integrates with scene tree |
| Type-safe dictionary access | Unchecked `dict["key"]` | `dict.get("key", default)` | Prevents crashes on missing keys in corrupted/old saves |

**Key insight:** Godot's built-in `FileAccess`, `JSON`, and `Timer` cover 100% of what's needed. No external libraries or complex patterns required.

## Common Pitfalls

### Pitfall 1: Affix Randomization on Deserialize
**What goes wrong:** `Affix._init()` randomizes tier and value. If you create an Affix from saved data, the constructor re-randomizes, losing the saved values.
**Why it happens:** The `_init()` function in Affix calls `randi_range()` for tier and value.
**How to avoid:** After calling `Affix.new()` with the template params, immediately overwrite `tier`, `value`, `min_value`, `max_value` with saved values.
**Warning signs:** Loaded items have different stats than when saved.

### Pitfall 2: Item Subclass Identity Lost
**What goes wrong:** Saving an item as generic `Item` data loses the subclass identity (LightSword, BasicArmor, etc.). On load, you don't know which class to instantiate.
**Why it happens:** JSON doesn't preserve GDScript class information.
**How to avoid:** Save an `item_type` field (e.g., "LightSword") alongside item data. Use a registry/factory to map type strings back to constructors.
**Warning signs:** All loaded items are generic Items or wrong types.

### Pitfall 3: Typed Array Casting from JSON
**What goes wrong:** JSON arrays come back as untyped `Array`. Assigning directly to `Array[Affix]` causes type errors.
**Why it happens:** Godot 4's JSON parser returns generic Variant types. `Array[Affix]` is a typed array.
**How to avoid:** Build typed arrays manually: iterate parsed array, create Affix instances, append to new `Array[Affix]`.
**Warning signs:** Runtime type errors on load.

### Pitfall 4: Auto-Save During State Transition
**What goes wrong:** Auto-save fires while game state is being modified (e.g., mid-equip, mid-craft), saving inconsistent state.
**Why it happens:** Event-driven saves trigger immediately on signal.
**How to avoid:** Use `call_deferred("save_game")` for event-driven saves, so save happens after the current frame's operations complete.
**Warning signs:** Loaded save has partially-applied changes.

### Pitfall 5: FileAccess.open Returns Null
**What goes wrong:** `FileAccess.open()` returns null if the file can't be opened (permissions, disk full, etc.). Calling methods on null crashes.
**Why it happens:** No error checking after open.
**How to avoid:** Always check `if file == null` after `FileAccess.open()`. Use `FileAccess.get_open_error()` for diagnostics.
**Warning signs:** Game crashes on save/load on certain platforms.

### Pitfall 6: Enum Values as JSON Keys
**What goes wrong:** Enum values (like `Item.Rarity.NORMAL`) serialize as integers in JSON. If enum order changes in a future update, saved values map to wrong rarities.
**Why it happens:** Enums are just named integers in GDScript.
**How to avoid:** Save enum values as their integer representation (stable) OR as strings (readable). Document which approach is used. Since Item.Rarity values are unlikely to change, integers are fine with version tracking.
**Warning signs:** Items load with wrong rarity after code changes.

## Code Examples

### Complete Item Serialization
```gdscript
# Item.to_dict() — base class handles common fields
func to_dict() -> Dictionary:
    var data := {
        "item_type": get_item_type_string(),
        "item_name": item_name,
        "tier": tier,
        "rarity": rarity,  # int enum value
        "implicit": implicit.to_dict() if implicit else null,
        "prefixes": [],
        "suffixes": [],
    }
    for prefix in prefixes:
        data["prefixes"].append(prefix.to_dict())
    for suffix in suffixes:
        data["suffixes"].append(suffix.to_dict())
    return data

func get_item_type_string() -> String:
    # Override in subclasses
    return "Item"

# Item.from_dict() — static factory
static func create_from_dict(data: Dictionary) -> Item:
    var item_type: String = data.get("item_type", "")
    var item: Item = SaveManager.create_item_by_type(item_type)
    if item == null:
        return null
    item.rarity = data.get("rarity", Rarity.NORMAL)
    # Restore implicit
    var implicit_data = data.get("implicit")
    if implicit_data:
        item.implicit = Implicit.from_dict(implicit_data)
    # Restore prefixes
    item.prefixes.clear()
    for prefix_data in data.get("prefixes", []):
        item.prefixes.append(Affix.from_dict(prefix_data))
    # Restore suffixes
    item.suffixes.clear()
    for suffix_data in data.get("suffixes", []):
        item.suffixes.append(Affix.from_dict(suffix_data))
    # Recalculate derived stats
    item.update_value()
    return item
```

### Auto-Save with Debounce
```gdscript
# Prevent rapid-fire saves from multiple signals
var _save_pending := false

func _on_save_trigger(_arg = null) -> void:
    if not _save_pending:
        _save_pending = true
        call_deferred("_deferred_save")

func _on_equipment_save_trigger(_slot: String, _item: Item) -> void:
    _on_save_trigger()

func _on_area_save_trigger(_level: int) -> void:
    _on_save_trigger()

func _deferred_save() -> void:
    _save_pending = false
    var success := save_game()
    if success:
        GameEvents.save_completed.emit()  # Toast listens to this
    else:
        GameEvents.save_failed.emit()
```

### Toast Notification
```gdscript
# scenes/save_toast.gd
extends Label

func show_toast(message: String = "Saved") -> void:
    text = message
    modulate.a = 1.0
    visible = true
    var tween := create_tween()
    tween.tween_interval(1.0)  # Hold for 1 second
    tween.tween_property(self, "modulate:a", 0.0, 0.5)  # Fade over 0.5s
    tween.tween_callback(func(): visible = false)
```

### Startup Flow
```gdscript
# In GameState._ready() or SaveManager._ready()
func _ready() -> void:
    # Auto-load on launch
    var loaded := SaveManager.load_game()
    if not loaded:
        if FileAccess.file_exists(SaveManager.SAVE_PATH):
            # File exists but failed to load — corrupted
            _show_warning_toast("Save could not be loaded")
        # Start fresh game (either first launch or corrupted save)
        _initialize_fresh_game()
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Godot 3 `File` class | Godot 4 `FileAccess` static methods | Godot 4.0 | `File.new()` replaced by `FileAccess.open()` — static factory pattern |
| `parse_json()` / `to_json()` | `JSON.parse_string()` / `JSON.stringify()` | Godot 4.0 | Global functions removed, use JSON class methods |
| `File.open()` returns error code | `FileAccess.open()` returns null on error | Godot 4.0 | Check null instead of error code; use `FileAccess.get_open_error()` |

**Deprecated/outdated:**
- `parse_json()` global function: Removed in Godot 4, use `JSON.parse_string()`
- `to_json()` global function: Removed in Godot 4, use `JSON.stringify()`
- `File` class: Renamed to `FileAccess` in Godot 4

## Open Questions

1. **Crafting bench access from SaveManager**
   - What we know: `crafting_view.gd` holds `current_item` and `crafting_inventory` as instance variables. SaveManager needs access to serialize/restore these.
   - What's unclear: Best way to access crafting_view state from an autoload (it's a scene node, not an autoload).
   - Recommendation: Either (a) move crafting inventory state to GameState autoload (cleanest for persistence), or (b) have SaveManager find the crafting_view node at save time. Option (a) is recommended — it makes state ownership clear.

2. **CombatEngine area_level access**
   - What we know: `combat_engine.area_level` and `max_unlocked_level` need saving. CombatEngine is a child of GameplayView scene.
   - What's unclear: How to access these from SaveManager autoload.
   - Recommendation: Move `area_level` and `max_unlocked_level` to GameState (they're game progress, not combat-specific). CombatEngine reads from GameState.

## Sources

### Primary (HIGH confidence)
- Godot 4 official documentation — FileAccess, JSON, Timer classes
- Project codebase analysis — full read of all 39 GDScript files

### Secondary (MEDIUM confidence)
- [GDQuest — Save game formats](https://www.gdquest.com/tutorial/godot/best-practices/save-game-formats/) — format comparison and decision framework
- [KidsCanCode — Godot 4 File I/O](https://kidscancode.org/godot_recipes/4.x/basics/file_io/index.html) — FileAccess patterns and Resource-based saving
- [Godot official — Saving games](https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html) — official saving tutorial

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Godot built-in APIs, well-documented
- Architecture: HIGH — patterns derived from codebase analysis + established Godot patterns
- Pitfalls: HIGH — identified from actual codebase issues (Affix randomization, typed arrays)

**Research date:** 2026-02-17
**Valid until:** 2026-03-17 (stable domain, no fast-moving dependencies)
