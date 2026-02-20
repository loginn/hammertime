# Phase 36: Save Format v3 - Research

**Researched:** 2026-02-20
**Domain:** GDScript SaveManager, JSON persistence, Godot 4.5 file I/O, save versioning
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Migration behavior:**
- No v2-to-v3 migration path. If save version < 3, delete the old save file and start a fresh game automatically
- Silent handling — no toast or in-game message about migration. Just delete and fresh start
- The existing _migrate_v1_to_v2 code can be removed or left as dead code (Claude's discretion)
- No validation/clamping on prestige field values — trust the data, consistent with how other save fields are handled

### Claude's Discretion

- Auto-save timing relative to prestige wipe sequence
- Whether to clean up old migration code or leave it
- Prestige field inclusion in export/import save strings
- Any defensive coding around save field parsing

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SAVE-01 | Save format v3 stores prestige level, item tier unlocks, and tag currency counts | Bump SAVE_VERSION to 3; add prestige_level, max_item_tier_unlocked, tag_currency_counts to _build_save_data(); restore them in _restore_state() with .get() defaults |
| SAVE-02 | Prestige completion triggers auto-save | Connect to GameEvents.prestige_completed in SaveManager._ready(); call save_game() (or _trigger_save()) from handler |
</phase_requirements>

## Summary

Phase 36 is a focused SaveManager extension. Three new fields from Phase 35 (prestige_level, max_item_tier_unlocked, tag_currency_counts) must be written to the JSON save file and restored on load. SAVE_VERSION bumps from 2 to 3. The migration policy is delete-and-fresh-start for any save with version < 3 — no data migration.

The existing SaveManager patterns are clear and consistent. `_build_save_data()` reads from GameState and builds a flat dictionary; `_restore_state()` reads with `.get(key, default)` for resilience; `_migrate_save()` currently handles v1→v2 via a specific migration function. For v3, instead of a migration function, any save with version < 3 triggers `delete_save()` and returns false from `load_game()`. This starts a fresh game silently.

Auto-save on prestige completion is straightforward: SaveManager connects to `GameEvents.prestige_completed` in `_ready()` and calls `save_game()` directly (not the debounced `_trigger_save()`). The timing decision (before vs after wipe) matters: `execute_prestige()` in PrestigeManager runs the full sequence (spend → advance prestige → wipe → grant bonus → emit signal). By the time `prestige_completed` fires, the new prestige state is already set and run state is already wiped. Saving at this moment captures the correct post-prestige snapshot.

**Primary recommendation:** Bump SAVE_VERSION to 3, replace `_migrate_save()` with a delete-and-return-false path for version < 3, add the three prestige fields to `_build_save_data()` and `_restore_state()`, and connect `prestige_completed` to a direct `save_game()` call in `_ready()`.

## Standard Stack

### Core
| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| GDScript | Godot 4.5 | Implementation language | Project constraint — no alternatives |
| `JSON.stringify` / `JSON.parse_string` | Godot 4.5 | Save serialization | Already used in SaveManager; no change |
| `FileAccess` | Godot 4.5 | File read/write | Already used in SaveManager; no change |
| `DirAccess.remove_absolute` | Godot 4.5 | Delete stale save file | Already used in `delete_save()` method |
| `Dictionary.get(key, default)` | GDScript | Resilient field read | Existing pattern in `_restore_state()` for all fields |

### Supporting
| Component | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| `GameEvents.prestige_completed` signal | Phase 35 | Trigger auto-save after prestige | Connect in SaveManager._ready(), save immediately in handler |
| `save_game()` (direct call) | existing | Save on prestige completion | Called directly (not debounced) because prestige is a user-initiated singular event, not a rapid-fire trigger |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Delete-on-old-version | v2→v3 migration function | Migration adds complexity; user decision explicitly allows breaking old saves; deletion is simpler and eliminates edge cases |
| Direct `save_game()` on prestige | Debounced `_trigger_save()` | `_trigger_save()` is correct for rapid-fire events (area cleared, item crafted); prestige is once-per-session, direct call is fine and ensures the save completes before any subsequent operation |
| Separate `prestige_save` function | Reuse existing `save_game()` | `save_game()` already saves full state; no customization needed |

## Architecture Patterns

### Files Modified (Phase 36 scope)
```
autoloads/
└── save_manager.gd    # ONLY file changed in this phase
```
No other files touch save format. GameState.gd, PrestigeManager.gd, and GameEvents.gd are already correct from Phase 35.

### Pattern 1: SAVE_VERSION Bump
**What:** Increment `SAVE_VERSION` constant from 2 to 3. This is the single source of truth for the current format.
**Current state:** `const SAVE_VERSION = 2` at top of save_manager.gd
**New state:** `const SAVE_VERSION = 3`

### Pattern 2: Delete-and-Fresh-Start for Old Saves
**What:** Replace the v1→v2 migration call chain with a delete-and-return-false path. Any save with `version < 3` is deleted, and `load_game()` returns false, causing GameState._ready() to start fresh.
**Current `_migrate_save()` behavior:** Checks version, calls `_migrate_v1_to_v2()` if needed, sets version to current.
**New `_migrate_save()` behavior:** If `saved_version < SAVE_VERSION` (i.e., < 3), call `delete_save()` and return an empty Dictionary as sentinel, OR handle the deletion in `load_game()` before calling `_migrate_save()`.

The cleanest approach: handle the version check in `load_game()` directly after parsing JSON, before calling `_migrate_save()`. If `data["version"] < SAVE_VERSION`, call `delete_save()` and return false. This keeps the deletion path explicit:

```gdscript
## Loads game state from the JSON save file. Returns true on success.
func load_game() -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        return false

    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        push_warning("SaveManager: Failed to open save file for reading: " + str(FileAccess.get_open_error()))
        return false

    var json_text := file.get_as_text()
    var parsed = JSON.parse_string(json_text)

    if parsed == null or not (parsed is Dictionary):
        push_warning("SaveManager: Save file contains invalid JSON")
        return false

    var data: Dictionary = parsed

    # v3 migration policy: delete old saves and start fresh (no migration path)
    var saved_version: int = int(data.get("version", 1))
    if saved_version < SAVE_VERSION:
        push_warning("SaveManager: Outdated save (v%d), deleting and starting fresh" % saved_version)
        delete_save()
        return false

    return _restore_state(data)
```

Note: `_migrate_save()` can be removed entirely or left as dead code. The `_migrate_v1_to_v2()` function becomes unreachable if `_migrate_save()` is removed.

### Pattern 3: Prestige Fields in _build_save_data()
**What:** Add three keys to the save dictionary. They sit alongside existing top-level keys.
**Where:** In `_build_save_data()`, after the existing `area_level` key.

```gdscript
return {
    "version": SAVE_VERSION,
    "timestamp": Time.get_unix_time_from_system(),
    "hero_equipment": hero_equipment,
    "currencies": GameState.currency_counts.duplicate(),
    "crafting_inventory": crafting_inv,
    "crafting_bench_type": GameState.crafting_bench_type,
    "max_unlocked_level": GameState.max_unlocked_level,
    "area_level": GameState.area_level,
    # v3 prestige fields
    "prestige_level": GameState.prestige_level,
    "max_item_tier_unlocked": GameState.max_item_tier_unlocked,
    "tag_currency_counts": GameState.tag_currency_counts.duplicate(),
}
```

`tag_currency_counts.duplicate()` follows the same pattern as `currency_counts.duplicate()` — shallow copy prevents live reference issues.

### Pattern 4: Prestige Fields in _restore_state()
**What:** Read three new keys from the save dictionary using `.get(key, default)` for resilience. Add after the existing area progress restoration.
**Defaults:** `prestige_level` defaults to 0, `max_item_tier_unlocked` defaults to 8 (P0 baseline), `tag_currency_counts` defaults to `{}`.

```gdscript
# Restore prestige state (v3)
GameState.prestige_level = int(data.get("prestige_level", 0))
GameState.max_item_tier_unlocked = int(data.get("max_item_tier_unlocked", 8))

# Restore tag currencies
var saved_tag_currencies: Dictionary = data.get("tag_currency_counts", {})
for tag_type in saved_tag_currencies:
    GameState.tag_currency_counts[tag_type] = int(saved_tag_currencies[tag_type])
```

No validation/clamping per user decision. Trust the data, same as `currency_counts` restoration.

### Pattern 5: Auto-Save on Prestige
**What:** Connect to `GameEvents.prestige_completed` in `SaveManager._ready()` and call `save_game()` directly.
**Timing:** `prestige_completed` fires at the end of `execute_prestige()` in PrestigeManager. By this point: prestige_level is advanced, max_item_tier_unlocked is updated, run state is wiped, bonus tag hammer is granted. The save captures the correct post-prestige snapshot.
**Implementation:** Add one connection in `_ready()` and one handler method:

```gdscript
func _ready() -> void:
    # ... existing connections ...
    GameEvents.prestige_completed.connect(_on_prestige_completed)


func _on_prestige_completed(_new_level: int) -> void:
    save_game()
```

**Why direct `save_game()` not `_trigger_save()`:** `_trigger_save()` is debounced (deferred frame). Prestige is a singular, high-stakes event. Saving directly ensures the file is written immediately, before any other operation that might follow. The debounce exists to prevent save spam from rapid events (area cleared, item crafted); prestige doesn't have that problem.

### Pattern 6: Export String — Include Prestige Fields
**What:** `export_save_string()` calls `_build_save_data()`, so prestige fields are automatically included once `_build_save_data()` is updated. No separate change needed.
**Import:** `import_save_string()` calls `_migrate_save()` then `_restore_state()`. With the new load_game() approach, import_save_string() still calls its own version check (`int(data.get("version", 0)) > SAVE_VERSION` for newer-version rejection). The v < 3 case in import: the import function should also reject old-version saves. The simplest approach: if `saved_version < SAVE_VERSION`, return an error (the player is trying to import a v2 save into a v3 game). Existing behavior returns `{"success": false, "error": "newer_version"}` for newer saves; add a parallel check for older saves.

### Anti-Patterns to Avoid
- **Migrating v2 to v3 data:** User decision is explicit — delete and fresh start. Do not attempt to synthesize `prestige_level = 0` as a migration; just delete.
- **Calling `_trigger_save()` for prestige auto-save:** The deferred save works but is less clear. Direct `save_game()` is more explicit for a singular event.
- **Adding prestige fields to the v1→v2 migration function:** That migration path is dead (version < 3 → delete). No point updating it.
- **Duplicating the tag_currency_counts by reference:** `Dictionary.duplicate()` (shallow) is correct here since tag_currency_counts values are integers, not nested objects. Matches `currency_counts.duplicate()` pattern.
- **Using a nested "prestige" sub-dictionary in save data:** The existing save format is flat top-level keys. Keep prestige fields at the same level as "currencies", "area_level", etc. for consistency.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| File deletion | Custom file removal | `DirAccess.remove_absolute(SAVE_PATH)` | Already used in `delete_save()`; works correctly in Godot 4.5 |
| Save serialization | Custom binary format | `JSON.stringify()` | Already the project pattern; JSON is readable and debuggable |
| Signal connection for auto-save | Polling or timer-based check | `GameEvents.prestige_completed.connect(...)` | Existing event bus; consistent with item_crafted, area_cleared pattern |

**Key insight:** Every operation needed in Phase 36 already exists in SaveManager. This phase is extending existing methods, not building new infrastructure.

## Common Pitfalls

### Pitfall 1: Incorrect Version Check Direction
**What goes wrong:** Checking `saved_version != SAVE_VERSION` instead of `saved_version < SAVE_VERSION`. A version 4 save loaded in a version 3 game would be deleted instead of rejected.
**Why it happens:** Conflating "wrong version" with "old version".
**How to avoid:** Use `saved_version < SAVE_VERSION` for the delete path. The import_save_string() already handles `saved_version > SAVE_VERSION` via the "newer_version" error.
**Warning signs:** A future SAVE_VERSION bump would silently delete saves from a newer game version.

### Pitfall 2: Missing .duplicate() on tag_currency_counts
**What goes wrong:** `_build_save_data()` stores a live reference to `GameState.tag_currency_counts`. If the dictionary is mutated after `_build_save_data()` returns but before `JSON.stringify()` completes (unlikely in GDScript but bad practice), the save could include unexpected data.
**Why it happens:** Forgetting to follow the `currency_counts.duplicate()` pattern.
**How to avoid:** Always call `.duplicate()` on dictionaries stored by reference in save data. Matches existing pattern.

### Pitfall 3: _restore_state() Doesn't Reset tag_currency_counts Before Restoring
**What goes wrong:** If `GameState.tag_currency_counts` already has values (e.g., from initialize_fresh_game or a previous load attempt), and the save only contains a subset of tag types, the old values persist alongside the restored ones.
**Why it happens:** The `currency_counts` restoration loops over `saved_currencies` keys and assigns into the existing dict without clearing it first. For `currency_counts`, the keys are fixed and always present, so overwriting works. For `tag_currency_counts`, keys are dynamic — a save might have `{fire: 2}` but the GameState dict might have leftover `{cold: 1}` from a previous session.
**How to avoid:** Either clear `GameState.tag_currency_counts = {}` before restoring, or assign the whole dict at once. Simplest: assign directly from the saved dict (with int() conversion per value):
```gdscript
GameState.tag_currency_counts = {}
var saved_tag_currencies: Dictionary = data.get("tag_currency_counts", {})
for tag_type in saved_tag_currencies:
    GameState.tag_currency_counts[tag_type] = int(saved_tag_currencies[tag_type])
```
**Warning signs:** Tag currency counts accumulate across load/reload cycles.

### Pitfall 4: Auto-Save Fires Before Prestige State is Committed
**What goes wrong:** If save happens inside execute_prestige() before the prestige fields are set (e.g., saved right before the wipe but after currencies are spent), the save would capture an intermediate broken state.
**Why it happens:** Misplacing the save call in the prestige sequence.
**How to avoid:** Connect to `GameEvents.prestige_completed`, which fires at the END of execute_prestige() after prestige_level, max_item_tier_unlocked, _wipe_run_state(), and _grant_random_tag_currency() have all completed. The signal is the natural "all done" marker.
**Warning signs:** Saved file has old prestige_level or old run state alongside new run state.

### Pitfall 5: import_save_string() Doesn't Handle Old Version Saves
**What goes wrong:** A player tries to import a v2 save string into a v3 game. The current import flow calls `_migrate_save()` then `_restore_state()`. With `_migrate_save()` removed, there's no migration; `_restore_state()` runs on v2 data without prestige fields, which is fine (defaults to 0/8/{}). But the imported v2 save now gets written to disk as v3 (save_game() is called in import_save_string()). This is actually acceptable behavior — the import effectively upgrades the save with default prestige values.
**Alternative concern:** If the import intentionally rejects old saves, add a version check in import_save_string() similar to the newer-version check.
**Recommendation:** Allow v2 import to succeed (defaults fill in), since the user explicitly chose to import. This is more user-friendly than rejection. Document this as expected behavior.

## Code Examples

### Updated save_manager.gd — Complete Change Set

```gdscript
# CHANGE 1: Bump SAVE_VERSION
const SAVE_VERSION = 3  # was 2

# CHANGE 2: Connect prestige auto-save in _ready()
func _ready() -> void:
    # Auto-save timer
    auto_save_timer = Timer.new()
    auto_save_timer.wait_time = AUTO_SAVE_INTERVAL
    auto_save_timer.one_shot = false
    auto_save_timer.timeout.connect(_on_auto_save)
    add_child(auto_save_timer)
    auto_save_timer.start()

    # Event-driven save triggers
    GameEvents.item_crafted.connect(_on_save_trigger)
    GameEvents.equipment_changed.connect(_on_equipment_save_trigger)
    GameEvents.area_cleared.connect(_on_area_save_trigger)
    GameEvents.prestige_completed.connect(_on_prestige_completed)  # NEW


# CHANGE 3: Add prestige handler
func _on_prestige_completed(_new_level: int) -> void:
    save_game()


# CHANGE 4: Updated load_game() — delete old saves instead of migrating
func load_game() -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        return false

    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        push_warning("SaveManager: Failed to open save file for reading: " + str(FileAccess.get_open_error()))
        return false

    var json_text := file.get_as_text()
    var parsed = JSON.parse_string(json_text)

    if parsed == null or not (parsed is Dictionary):
        push_warning("SaveManager: Save file contains invalid JSON")
        return false

    var data: Dictionary = parsed

    # v3 migration policy: delete outdated saves, start fresh (no migration)
    var saved_version: int = int(data.get("version", 1))
    if saved_version < SAVE_VERSION:
        push_warning("SaveManager: Outdated save (v%d), deleting and starting fresh" % saved_version)
        delete_save()
        return false

    return _restore_state(data)


# CHANGE 5: Updated _build_save_data() — add prestige fields
func _build_save_data() -> Dictionary:
    var hero_equipment := {}
    for slot in ["weapon", "helmet", "armor", "boots", "ring"]:
        var item = GameState.hero.equipped_items.get(slot)
        if item != null:
            hero_equipment[slot] = item.to_dict()
        else:
            hero_equipment[slot] = null

    var crafting_inv := {}
    for type_name in GameState.crafting_inventory:
        var slot_array: Array = GameState.crafting_inventory[type_name]
        var items_data: Array = []
        for item in slot_array:
            items_data.append(item.to_dict())
        crafting_inv[type_name] = items_data

    return {
        "version": SAVE_VERSION,
        "timestamp": Time.get_unix_time_from_system(),
        "hero_equipment": hero_equipment,
        "currencies": GameState.currency_counts.duplicate(),
        "crafting_inventory": crafting_inv,
        "crafting_bench_type": GameState.crafting_bench_type,
        "max_unlocked_level": GameState.max_unlocked_level,
        "area_level": GameState.area_level,
        # v3 prestige fields
        "prestige_level": GameState.prestige_level,
        "max_item_tier_unlocked": GameState.max_item_tier_unlocked,
        "tag_currency_counts": GameState.tag_currency_counts.duplicate(),
    }


# CHANGE 6: Updated _restore_state() — restore prestige fields
func _restore_state(data: Dictionary) -> bool:
    # ... existing equipment, currency, crafting, area_level restoration ...

    # Restore prestige state (v3)
    GameState.prestige_level = int(data.get("prestige_level", 0))
    GameState.max_item_tier_unlocked = int(data.get("max_item_tier_unlocked", 8))

    # Restore tag currencies (clear first to avoid stale keys)
    GameState.tag_currency_counts = {}
    var saved_tag_currencies: Dictionary = data.get("tag_currency_counts", {})
    for tag_type in saved_tag_currencies:
        GameState.tag_currency_counts[tag_type] = int(saved_tag_currencies[tag_type])

    # Recalculate all derived hero stats from restored equipment
    GameState.hero.update_stats()

    return true
```

### What to Remove / Leave Dead

The `_migrate_save()` and `_migrate_v1_to_v2()` functions become unreachable once `load_game()` handles the version check directly. Claude's discretion: either remove them (cleaner) or leave them (safer — no risk of removal breakage). Recommendation: remove both, since the version check is now in `load_game()` and the functions serve no purpose.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| SAVE_VERSION = 2, _migrate_v1_to_v2() | SAVE_VERSION = 3, delete-and-fresh for old saves | Phase 36 | No migration complexity; old saves are cleanly discarded |
| No prestige fields in save | prestige_level, max_item_tier_unlocked, tag_currency_counts persisted | Phase 36 | Prestige progress survives game restarts |
| No prestige auto-save | save_game() called on prestige_completed signal | Phase 36 | Prestige progress never lost due to crash after prestige |

## Open Questions

1. **Should _migrate_save() and _migrate_v1_to_v2() be removed or left as dead code?**
   - What we know: Claude's discretion per CONTEXT.md. The functions become unreachable once load_game() handles old-version deletion.
   - What's unclear: Whether removing them could cause any downstream issue (they are not called from anywhere outside SaveManager).
   - Recommendation: Remove both functions for cleanliness. GDScript has no linker concerns; dead code is just noise.

2. **Should import_save_string() reject or accept v2 save strings?**
   - What we know: Claude's discretion on prestige field inclusion in export/import format. A v2 import string lacks prestige fields.
   - What's unclear: What user behavior is expected. A v2 import string likely comes from before Phase 36 was shipped.
   - Recommendation: Allow v2 import strings to succeed. `_restore_state()` uses `.get(key, default)` which provides 0/8/{} for missing prestige fields. The import_save_string() version check only rejects _newer_ versions (the existing `> SAVE_VERSION` check). Old import strings get sane defaults, which is better than an opaque error.

3. **Is `_on_prestige_completed` calling `save_game()` directly thread-safe?**
   - What we know: Godot 4.5 signals fire synchronously on the main thread by default. `execute_prestige()` runs on the main thread. The signal fires inline, so `save_game()` is called synchronously before execute_prestige() returns.
   - Recommendation: No issue. Direct call is fine. If future code calls execute_prestige() from a thread, revisit. Not a concern for this phase.

## Sources

### Primary (HIGH confidence)
- Direct codebase inspection — `autoloads/save_manager.gd` — complete file read; all existing methods verified
- Direct codebase inspection — `autoloads/game_state.gd` — prestige_level, max_item_tier_unlocked, tag_currency_counts fields confirmed present from Phase 35
- Direct codebase inspection — `autoloads/game_events.gd` — prestige_completed signal confirmed present from Phase 35
- Direct codebase inspection — `autoloads/prestige_manager.gd` — execute_prestige() signal emission order confirmed
- `.planning/phases/36-save-format-v3/36-CONTEXT.md` — locked user decisions on migration behavior, auto-save timing, export/import
- `.planning/STATE.md` — key constraint: "v2 save migration: breaking existing saves is acceptable (user decision); v3 migration is additive-only"
- `.planning/REQUIREMENTS.md` — SAVE-01 and SAVE-02 definitions

### Secondary (MEDIUM confidence)
- Phase 35 RESEARCH.md — patterns for GameState extension; confirmed prestige fields architecture
- Phase 35 PLAN.md — confirmed execute_prestige() signal ordering (emit prestige_completed last, after all state updates)

### Tertiary (LOW confidence)
- None — all research conducted against local codebase and planning documents

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all components are existing SaveManager patterns; no new libraries
- Architecture: HIGH — _build_save_data() and _restore_state() patterns are directly observable in existing code; changes are additive
- Migration approach: HIGH — user decision is explicit (delete, not migrate); delete_save() already exists and works
- Auto-save timing: HIGH — prestige_completed signal fires after full execute_prestige() sequence; GameEvents.prestige_completed confirmed from Phase 35
- Pitfalls: HIGH — tag_currency_counts reset-before-restore derived from observing dynamic-key dict behavior; version check direction from explicit user decision analysis

**Research date:** 2026-02-20
**Valid until:** 2026-03-20 (stable — Godot 4.5 file I/O and JSON patterns don't change; valid until next milestone)
