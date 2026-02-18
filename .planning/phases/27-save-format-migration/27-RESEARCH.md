# Phase 27: Save Format Migration - Research

**Researched:** 2026-02-18
**Domain:** Godot 4.5 GDScript JSON save/load migration
**Confidence:** HIGH

## Summary

Phase 27 converts the save format from v1 (single-item-per-slot) to v2 (per-slot arrays of up to 10 items). The migration is straightforward: each v1 slot value (a single item dict or null) wraps into a 1-element array or empty array respectively. The orphaned `crafting_bench_item` key must be stripped from both written and migrated saves.

The existing `SaveManager` already has a version-based migration skeleton (`_migrate_save` with commented-out `_migrate_v1_to_v2`), a `SAVE_VERSION` constant, and clean `_build_save_data()`/`_restore_state()` methods. The changes are mechanical: bump the constant, implement the migration function, update the build/restore methods to work with arrays, and strip the orphaned key.

**Primary recommendation:** Implement migration-before-schema as decided: write `_migrate_v1_to_v2()` first, then update `_build_save_data()` and `_restore_state()` to use arrays, then strip `crafting_bench_item` from the save path.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Each v1 single-item slot wraps into a 1-element array in v2 (e.g., weapon slot with a sword becomes `[sword]`)
- Empty/null v1 slots become empty arrays `[]` — every slot always has an array key
- All five crafting slots (weapon, helmet, chest, gloves, boots) follow the identical migration pattern
- Equipped items remain as separate fields — slot arrays are inventory/stash only, not equipment
- No backward compatibility needed — there are no external players
- Old v1 saves can be broken without concern
- One-way migration only; no need to support writing v1 format
- If a save fails to load or migrate, reset to fresh game state
- No graceful fallback, retry logic, or partial recovery needed
- Simple approach: load works or state resets

### Claude's Discretion
- Save version detection mechanism (version field, format sniffing, etc.)
- Internal structure of `_migrate_v1_to_v2()` and `_restore_state()` methods
- Whether to log migration events or silently proceed
- Exact key naming for the new per-slot arrays in save data

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SAVE-01 | Save/load supports per-slot inventory arrays in the save format | Migration function wraps v1 single items into arrays; _build_save_data() writes arrays; _restore_state() reads arrays; orphaned key stripped |
</phase_requirements>

## Architecture Patterns

### Current Save Structure (v1)

The existing code in `autoloads/save_manager.gd`:

```gdscript
const SAVE_VERSION = 1

# _build_save_data() produces:
{
    "version": 1,
    "timestamp": <unix_time>,
    "hero_equipment": { "weapon": <item_dict|null>, ... },
    "currencies": { "runic": N, ... },
    "crafting_inventory": { "weapon": <item_dict|null>, "helmet": ..., ... },
    "crafting_bench_item": <item_dict|null>,
    "crafting_bench_type": "weapon",
    "max_unlocked_level": N,
    "area_level": N,
}
```

### Target Save Structure (v2)

```gdscript
const SAVE_VERSION = 2

# _build_save_data() produces:
{
    "version": 2,
    "timestamp": <unix_time>,
    "hero_equipment": { "weapon": <item_dict|null>, ... },   # UNCHANGED
    "currencies": { "runic": N, ... },                        # UNCHANGED
    "crafting_inventory": {
        "weapon": [<item_dict>, ...],       # Array of 0-10 items
        "helmet": [],                        # Empty = no items
        "armor": [],
        "boots": [],
        "ring": [],
    },
    # "crafting_bench_item" — REMOVED (orphaned)
    "crafting_bench_type": "weapon",                          # UNCHANGED
    "max_unlocked_level": N,                                  # UNCHANGED
    "area_level": N,                                          # UNCHANGED
}
```

### Slot Name Mapping Note

**IMPORTANT:** The CONTEXT.md mentions "chest" and "gloves" as slot names, but the actual codebase uses "armor" and "boots" throughout (`game_state.gd` line 62-68, `save_manager.gd` line 77, line 113). The five canonical slot names in the code are: `weapon`, `helmet`, `armor`, `boots`, `ring`. Plans must use these actual code names, not the CONTEXT.md abstractions.

### Pattern 1: Migration-Before-Schema

**What:** Write `_migrate_v1_to_v2()` first, then update `_build_save_data()` and `_restore_state()`.
**Why:** The migration function transforms old data into the new shape. Once that works, the build/restore methods only need to handle the v2 shape. This avoids the complexity of methods that handle both formats.

```gdscript
# Step 1: Migration function (transforms v1 → v2 shape)
func _migrate_v1_to_v2(data: Dictionary) -> Dictionary:
    var old_inv: Dictionary = data.get("crafting_inventory", {})
    var new_inv := {}
    for slot in ["weapon", "helmet", "armor", "boots", "ring"]:
        var item_data = old_inv.get(slot)
        if item_data != null and item_data is Dictionary:
            new_inv[slot] = [item_data]
        else:
            new_inv[slot] = []
    data["crafting_inventory"] = new_inv
    data.erase("crafting_bench_item")  # Strip orphaned key
    return data
```

### Pattern 2: Array Serialization in Build/Restore

**What:** `_build_save_data()` serializes each slot as an array of item dicts. `_restore_state()` deserializes arrays back.

```gdscript
# _build_save_data() — crafting inventory section
var crafting_inv := {}
for slot_name in GameState.crafting_inventory:
    var items_array: Array = GameState.crafting_inventory[slot_name]
    var serialized := []
    for item in items_array:
        if item != null:
            serialized.append(item.to_dict())
    crafting_inv[slot_name] = serialized

# _restore_state() — crafting inventory section
var saved_crafting: Dictionary = data.get("crafting_inventory", {})
for slot_name in ["weapon", "helmet", "armor", "boots", "ring"]:
    var slot_data: Array = saved_crafting.get(slot_name, [])
    var items: Array = []
    for item_data in slot_data:
        if item_data is Dictionary:
            var item := Item.create_from_dict(item_data)
            if item != null:
                items.append(item)
    GameState.crafting_inventory[slot_name] = items
```

### Pattern 3: Orphaned Key Removal

**What:** `crafting_bench_item` is confirmed orphaned in GameState (exists at `game_state.gd:10` and `save_manager.gd:92-94,102,140-144`). In this phase, strip it from the save format only. The GameState field removal happens in Phase 28.

**Why this split:** Phase 27 owns the save format. Phase 28 owns the GameState data model. Removing the field from GameState before the data model rework would break ForgeView references.

```gdscript
# In _build_save_data(): simply don't include "crafting_bench_item" in the output dict
# In _migrate_v1_to_v2(): data.erase("crafting_bench_item")
# In _restore_state(): remove the bench item restoration block
```

### Anti-Patterns to Avoid
- **Dual-format restore:** Don't make `_restore_state()` handle both single-item and array formats. Migration happens first, restore only sees v2.
- **Partial migration:** Don't migrate some slots but not others. All five slots must be arrays after migration.
- **Keeping orphaned keys:** Don't leave `crafting_bench_item` in v2 saves "just in case." It's confirmed orphaned.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Version detection | Custom format sniffing | Existing `data.get("version", 1)` pattern | Already in `_migrate_save()` — just uncomment and extend |
| Item deserialization | Custom dict-to-item | Existing `Item.create_from_dict()` | Already handles all 5 item types with full affix restoration |

**Key insight:** The existing save system already has all the primitives needed. The migration is purely structural (wrapping values in arrays, removing a key).

## Common Pitfalls

### Pitfall 1: GameState.crafting_inventory Type Mismatch
**What goes wrong:** After updating `_restore_state()` to populate arrays, the rest of the codebase still expects `crafting_inventory["weapon"]` to be `Item` or `null`, not `Array`.
**Why it happens:** Phase 27 changes the save format but Phase 28 changes the data model.
**How to avoid:** Phase 27 must NOT change `GameState.crafting_inventory` type. The `_restore_state()` method should still populate single items into GameState (take the first item from the array). The array format lives only in the save file for now.
**Warning signs:** ForgeView crashes on load because it calls `.to_dict()` on an Array.

**CRITICAL REALIZATION:** This means `_restore_state()` in Phase 27 needs to bridge the gap: read arrays from save data, but write single items (first element or null) into GameState.crafting_inventory. The full array-based GameState comes in Phase 28.

### Pitfall 2: crafting_bench_item Reference in _restore_state
**What goes wrong:** Removing the bench item restoration from `_restore_state()` breaks loading of v1 saves where the bench had an item.
**Why it happens:** v1 saves contain `crafting_bench_item` data that gets migrated away.
**How to avoid:** `_migrate_v1_to_v2()` strips `crafting_bench_item` from the data dict. `_restore_state()` no longer needs to handle it. But GameState still has the field — it just stays null after load (which is fine since ForgeView reads from crafting_inventory, not bench_item directly).

### Pitfall 3: Empty Array vs Missing Key
**What goes wrong:** A save with a missing slot key (e.g., old save without "ring") causes errors during restore.
**Why it happens:** Relying on dict keys existing instead of defaulting.
**How to avoid:** Always use `.get(slot, [])` with empty array default in `_restore_state()`.

### Pitfall 4: Import/Export Path Forgotten
**What goes wrong:** `export_save_string()` and `import_save_string()` use `_build_save_data()` and `_migrate_save()` respectively. They automatically pick up changes.
**Why it happens:** Forgetting to verify the import/export path works with v2.
**How to avoid:** Verify that import_save_string's flow (`_migrate_save` → `_restore_state`) handles both v1 and v2 import strings correctly.

## Code Examples

### Complete _migrate_v1_to_v2 Implementation

```gdscript
## Migrates v1 save data to v2 format (per-slot inventory arrays).
func _migrate_v1_to_v2(data: Dictionary) -> Dictionary:
    # Wrap single-item slots into arrays
    var old_inv: Dictionary = data.get("crafting_inventory", {})
    var new_inv := {}
    for slot in ["weapon", "helmet", "armor", "boots", "ring"]:
        var item_data = old_inv.get(slot)
        if item_data != null and item_data is Dictionary:
            new_inv[slot] = [item_data]
        else:
            new_inv[slot] = []
    data["crafting_inventory"] = new_inv

    # Strip orphaned crafting_bench_item
    data.erase("crafting_bench_item")

    return data
```

### Updated _migrate_save

```gdscript
func _migrate_save(data: Dictionary) -> Dictionary:
    var saved_version: int = int(data.get("version", 1))

    if saved_version < SAVE_VERSION:
        print("SaveManager: Migrating save from v%d to v%d" % [saved_version, SAVE_VERSION])

    if saved_version < 2:
        data = _migrate_v1_to_v2(data)

    data["version"] = SAVE_VERSION
    return data
```

### Updated _build_save_data (crafting_inventory section)

```gdscript
# Phase 27: Write arrays to save file, but GameState still holds single items
var crafting_inv := {}
for type_name in GameState.crafting_inventory:
    var item = GameState.crafting_inventory[type_name]
    if item != null:
        crafting_inv[type_name] = [item.to_dict()]
    else:
        crafting_inv[type_name] = []

# Return dict WITHOUT crafting_bench_item key
```

### Updated _restore_state (crafting_inventory section)

```gdscript
# Phase 27: Read arrays from save, but populate GameState with single items
var saved_crafting: Dictionary = data.get("crafting_inventory", {})
for slot_name in ["weapon", "helmet", "armor", "boots", "ring"]:
    var slot_data = saved_crafting.get(slot_name, [])
    if slot_data is Array and not slot_data.is_empty():
        var first_item_data = slot_data[0]
        if first_item_data is Dictionary:
            GameState.crafting_inventory[slot_name] = Item.create_from_dict(first_item_data)
        else:
            GameState.crafting_inventory[slot_name] = null
    else:
        GameState.crafting_inventory[slot_name] = null

# Skip crafting_bench_item restoration entirely
# GameState.crafting_bench_item stays null (default from initialize_fresh_game)
```

## Scope Boundary

### Phase 27 Does:
- Bump `SAVE_VERSION` to 2
- Implement `_migrate_v1_to_v2()`
- Update `_build_save_data()` to write array format (wrapping single items)
- Update `_restore_state()` to read array format (extracting first item)
- Strip `crafting_bench_item` from save output and migration
- Remove `crafting_bench_item` restoration from `_restore_state()`

### Phase 27 Does NOT:
- Change `GameState.crafting_inventory` type (stays `Dictionary` of `Item|null`)
- Change `GameState.crafting_bench_item` field (stays, just unused in save)
- Change ForgeView or any UI code
- Add 10-item cap logic
- Change how items are added to inventory

## Open Questions

1. **crafting_bench_type persistence**
   - What we know: `crafting_bench_type` is saved and restored. It tracks which slot tab is selected.
   - What's unclear: Should this persist in v2? It references the bench which is being reworked.
   - Recommendation: Keep it — it's harmless and Phase 29 will decide its fate.

## Sources

### Primary (HIGH confidence)
- Direct codebase inspection: `autoloads/save_manager.gd` (273 lines, complete save system)
- Direct codebase inspection: `autoloads/game_state.gd` (98 lines, state management)
- Direct codebase inspection: `models/items/item.gd` (269 lines, serialization via `to_dict()`/`create_from_dict()`)
- Phase 27 CONTEXT.md (user decisions)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — existing Godot JSON save/load, no new libraries needed
- Architecture: HIGH — extending existing migration skeleton already in codebase
- Pitfalls: HIGH — identified from direct code inspection of all call sites

**Research date:** 2026-02-18
**Valid until:** 2026-03-18 (stable — internal game project)
