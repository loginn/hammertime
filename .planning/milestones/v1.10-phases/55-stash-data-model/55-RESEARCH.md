# Phase 55: Stash Data Model - Research

**Researched:** 2026-03-28
**Domain:** GDScript data model refactor — GameState, ForgeView, SaveManager, PrestigeManager
**Confidence:** HIGH

## Summary

Phase 55 replaces the old `crafting_inventory` dict (one item per slot type, five benches) and `crafting_bench_type` string with two new structures in `GameState`: a `stash` dict keyed by slot type each holding an Array of up to 3 items, and a single `crafting_bench` item of any type. All item drops from combat are routed directly into the stash — the bench is never auto-filled.

The change is a pure data-model refactor. All five files identified in CONTEXT.md need edits, but no new scene files are required. The UI for displaying the stash is Phase 57 scope — Phase 55 only establishes the data layer. Save persistence is Phase 58 scope; the stash fields may exist in runtime state but are not persisted yet (save format remains v8).

The integration boundary that changes most is `MainView`'s signal wiring: `gameplay_view.item_base_found` currently routes to `forge_view.set_new_item_base()` → `forge_view.add_item_to_inventory()`. In Phase 55 this routing must change so the drop goes to `GameState.stash` directly (or via a `GameState.add_item_to_stash()` helper), bypassing ForgeView entirely for drop handling.

**Primary recommendation:** Implement a `GameState.add_item_to_stash(item)` helper that encapsulates the full overflow-discard logic. Keep `ForgeView` unaware of stash routing; have `MainView` (or `GameplayView`) call the GameState helper directly on `item_base_found`.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01: Drops always go to stash** — Items from combat always land in the stash array for the appropriate slot type. The bench is never auto-filled. The player always chooses what to work on by tapping a stash item (Phase 57).
- **D-02: Bench loads only when empty** — Tapping a stash item to load the bench is rejected if the bench already has an item. No swap behavior. Player must equip or melt first. *(Phase 57 interaction — data model must support the empty-bench guard.)*
- **D-03: Overflow silently discarded** — When all 3 stash slots for a type are full and another item drops, the new item is discarded with no toast, no notification.
- **D-04: Melt and equip unchanged** — Melt destroys bench item; equip moves bench item to hero equipment. Both leave bench empty. Single universal bench instead of per-type benches.
- **D-05: Fresh game creates empty stash** — `initialize_fresh_game()` creates empty stash arrays (3 empty slots per type) and no starter weapon. Phase 56 places starter items.
- **D-06: Prestige wipes stash and bench** — `execute_prestige()` clears all stash arrays and the crafting bench before hero selection overlay appears.
- **D-07: 3 stash slots per equipment type** — 15 total slots (3 per each of weapon, helmet, armor, boots, ring).

### Claude's Discretion
No discretion areas were specified. All decisions are locked.

### Deferred Ideas (OUT OF SCOPE)
- Smart discard policy (keep higher tier on overflow) — future prestige unlock
- Item drop filters (auto-discard unwanted loot) — future prestige feature
- Stash UI display — Phase 57
- Tap-to-bench interaction — Phase 57
- Item detail hover/long-press — Phase 57
- Save format v9 persistence — Phase 58
- Starter items in stash — Phase 56
- Alteration/Regal hammers — Phase 58
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| STSH-01 | Player has 3 stash slots per equipment type to hold unworked bases | GameState needs `stash` dict with 5 keys (weapon/helmet/armor/boots/ring), each an Array[Item] capped at 3. `initialize_fresh_game()` and `_wipe_run_state()` initialize empty arrays. |
| STSH-04 | Dropped items auto-stash; overflow discarded with feedback | D-03 locks "no feedback" (silent discard). `GameState.add_item_to_stash(item)` inspects array length; if < 3 appends, else discards. Signal `stash_updated` emitted on success for future UI reactivity. The existing `item_base_found` → `forge_view.set_new_item_base` wiring in MainView must be re-routed. |
</phase_requirements>

---

## Standard Stack

### Core (this is a pure GDScript refactor — no new libraries)

| Component | Current | New | Notes |
|-----------|---------|-----|-------|
| `GameState.crafting_inventory` | `Dictionary` keyed by slot, values `Item\|null` | Remove | Replaced by `stash` + `crafting_bench` |
| `GameState.crafting_bench_type` | `String` | Remove | Single bench is typeless |
| `GameState.stash` | (new) | `Dictionary` — keys: slot strings, values: `Array` (max 3 Items) | |
| `GameState.crafting_bench` | (new) | `Item\|null` | Single universal bench item |
| `GameEvents.stash_updated` | (new signal) | Emitted after every successful stash insertion | Enables Phase 57 UI reactivity without polling |

**No npm packages, no external libraries. This is a GDScript data structure change.**

---

## Architecture Patterns

### Recommended Project Structure (no changes to folder layout)

The phase touches existing files only. No new scene or model files are introduced.

```
autoloads/
├── game_state.gd       # PRIMARY: replace crafting_inventory/crafting_bench_type
│                       #          add stash dict + crafting_bench item
│                       #          add add_item_to_stash() helper
├── game_events.gd      # Add stash_updated signal
├── save_manager.gd     # Phase 58 scope — no stash persistence yet;
│                       #   _build_save_data() and _restore_state() stay as-is
├── prestige_manager.gd # execute_prestige() must clear stash + bench
scenes/
├── forge_view.gd       # Remove per-type bench switching logic;
│                       #   current_item = GameState.crafting_bench
│                       #   melt/equip write to crafting_bench not crafting_inventory
├── main_view.gd        # Re-wire item_base_found signal to GameState helper
```

### Pattern 1: Stash Dict Initialization

**What:** Initialize `stash` with five keys, each mapping to a fresh empty Array. Never store null — always an Array (empty = no items, full = 3 items).

**When to use:** `initialize_fresh_game()` and `_wipe_run_state()` in game_state.gd.

```gdscript
# In game_state.gd
var stash: Dictionary = {}
var crafting_bench: Item = null

func _init_stash() -> void:
    stash = {
        "weapon": [],
        "helmet": [],
        "armor":  [],
        "boots":  [],
        "ring":   [],
    }

func initialize_fresh_game() -> void:
    # ... existing hero/currency init ...
    _init_stash()
    crafting_bench = null
    crafting_bench_type = ""  # remove this line once variable is gone
```

### Pattern 2: add_item_to_stash() Helper

**What:** Encapsulates slot resolution, cap check, discard logic, and signal emission. Callers never touch `stash` directly.

**When to use:** Everywhere an item drop should be routed to stash — currently only `gameplay_view._on_items_dropped()` via `item_base_found` signal chain.

```gdscript
## Adds item to the appropriate stash slot. Returns true if added, false if discarded.
func add_item_to_stash(item: Item) -> bool:
    var slot: String = _get_slot_for_item(item)
    if slot == "":
        push_warning("GameState: Unknown item type for stash routing: " + item.item_name)
        return false

    if stash[slot].size() >= 3:
        # D-03: silent discard, no toast
        return false

    stash[slot].append(item)
    GameEvents.stash_updated.emit(slot)
    return true


func _get_slot_for_item(item: Item) -> String:
    if item is Weapon:  return "weapon"
    if item is Helmet:  return "helmet"
    if item is Armor:   return "armor"
    if item is Boots:   return "boots"
    if item is Ring:    return "ring"
    return ""
```

**Note:** `_get_slot_for_item` duplicates the logic currently in `forge_view.get_item_type()`. The ForgeView version can be left in place for its own use (still needs it for melt/equip slot resolution). Do not remove ForgeView's copy — just add this private helper to GameState.

### Pattern 3: ForgeView Bench Adaptation

**What:** `forge_view.gd` currently reads/writes `GameState.crafting_inventory[slot_name]`. Every reference must switch to `GameState.crafting_bench`.

**Key method changes:**

```gdscript
# OLD: forge_view._ready() bench load
var selected_type: String = GameState.crafting_bench_type
if GameState.crafting_inventory[selected_type] != null:
    current_item = GameState.crafting_inventory[selected_type]

# NEW: single bench
current_item = GameState.crafting_bench
```

```gdscript
# OLD: _on_melt_pressed() clear
GameState.crafting_inventory[slot_name] = null

# NEW:
GameState.crafting_bench = null
```

```gdscript
# OLD: _on_equip_pressed() clear
GameState.crafting_inventory[slot_name] = null

# NEW:
GameState.crafting_bench = null
```

The five `ItemTypeButtons` (WeaponButton, HelmetButton, etc.) and their `_on_item_type_selected()` handler become dead code in Phase 55. Decision: **hide/disable these buttons in ForgeView** but do not remove the button nodes yet (Phase 57 may repurpose them for stash navigation). Remove the `GameState.crafting_bench_type` read/write calls; the buttons can simply be disabled.

### Pattern 4: Signal Re-Routing in MainView

**What:** The current signal chain is:
```
gameplay_view.item_base_found  →  forge_view.set_new_item_base()
                                  → add_item_to_inventory()
                                  → GameState.crafting_inventory[slot] = item
```

**New chain (Phase 55):**
```
gameplay_view.item_base_found  →  GameState.add_item_to_stash(item)
```

**Implementation:** In `main_view.gd` `_ready()`, change:
```gdscript
# OLD
gameplay_view.item_base_found.connect(forge_view.set_new_item_base)

# NEW
gameplay_view.item_base_found.connect(GameState.add_item_to_stash)
```

`forge_view.set_new_item_base()` and `add_item_to_inventory()` become unused for drop routing. They can remain in the file as dead code (Phase 57 will repurpose or remove them) or be removed now. Safe to remove `add_item_to_inventory` since its only caller was `set_new_item_base`.

### Pattern 5: Prestige Wipe (D-06)

**What:** `prestige_manager.execute_prestige()` calls `GameState._wipe_run_state()`. The stash/bench wipe should live inside `_wipe_run_state()` so a single call handles all run state.

```gdscript
# In game_state.gd _wipe_run_state()
# After wiping crafting_inventory (remove that block), add:
_init_stash()
crafting_bench = null
```

`prestige_manager.gd` itself requires no changes — it already calls `_wipe_run_state()`.

### Anti-Patterns to Avoid

- **Writing directly to `stash[slot]` outside of GameState** — always call `add_item_to_stash()`. Direct dict writes bypass the cap check.
- **Initializing stash slots as `null`** — use empty Arrays `[]`. Null slots require defensive null-checks everywhere; empty arrays allow `size()` and `append()` without guards.
- **Keeping `crafting_bench_type` as a persistent field** — the single bench has no type. Removing the field eliminates a class of bugs where bench_type diverges from the actual item on the bench.
- **Persisting stash in save format v8** — save persistence is Phase 58. Phase 55 code must NOT add stash to `_build_save_data()` or `_restore_state()`. Stash is ephemeral in this phase; a fresh load will correctly call `initialize_fresh_game()` → `_init_stash()` → empty stash.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Slot type resolution | Parallel if/match in multiple files | Single `_get_slot_for_item()` in GameState | Already partially duplicated — consolidate to one canonical location |
| Array capacity cap | Manual length checks scattered across callers | `add_item_to_stash()` helper encapsulates the `size() >= 3` check | One place to change when cap changes |
| UI reactivity for stash display | Polling in `_process()` | `GameEvents.stash_updated(slot)` signal | Follows existing pattern (see `GameEvents.equipment_changed`, `item_crafted`) |

---

## Common Pitfalls

### Pitfall 1: Stale references to `crafting_inventory` after rename

**What goes wrong:** ForgeView has ~8 separate references to `GameState.crafting_inventory[...]`. Missing even one causes a runtime error when the dict no longer exists.

**Why it happens:** The variable is referenced in `_ready()`, `_on_item_type_selected()`, `update_current_item()`, `get_best_item()`, `update_inventory_display()`, `update_slot_button_labels()`, `add_item_to_inventory()`, and the melt/equip handlers.

**How to avoid:** Search the entire codebase for `crafting_inventory` before closing the phase. Use project-wide search. Expected hits: game_state.gd (definitions being removed), save_manager.gd (being left as-is for v8), forge_view.gd (all should be gone after edits).

**Warning signs:** `Invalid get index 'crafting_inventory' on base 'Node (GameState)'` at runtime.

### Pitfall 2: `crafting_bench_type` left as orphaned writes

**What goes wrong:** ForgeView `_ready()` sets `GameState.crafting_bench_type = selected_type`. If the variable is removed from GameState but the write is left in ForgeView, you get a runtime error on first ForgeView load.

**Why it happens:** The variable is both read and written across the two files.

**How to avoid:** Remove `crafting_bench_type` from GameState, then search for all reads/writes in ForgeView and remove them.

### Pitfall 3: `initialize_fresh_game()` vs `_wipe_run_state()` divergence

**What goes wrong:** Fresh game and prestige wipe end up with different initial stash states if one is updated and the other is not.

**Why it happens:** GameState has two entry points for "reset state". In the current code, both initialize `crafting_inventory` and `crafting_bench_type` — the pattern must be preserved for `stash` and `crafting_bench`.

**How to avoid:** Use the `_init_stash()` helper called from both `initialize_fresh_game()` and `_wipe_run_state()`.

### Pitfall 4: Save file becomes incompatible if stash accidentally persisted

**What goes wrong:** If stash is accidentally added to `_build_save_data()` in this phase, a save file is written with stash data. When Phase 58 bumps SAVE_VERSION to 9, old saves (with stash but at v8) will be deleted by the existing "outdated save" policy. This is acceptable but confusing.

**Why it happens:** Developer sees the new field and reflexively adds it to save.

**How to avoid:** Explicitly do NOT touch save_manager.gd in Phase 55. Add a comment to the stash fields in GameState: `# Not persisted until Phase 58 (save v9)`.

### Pitfall 5: ForgeView's `update_inventory_display()` crashes on missing `crafting_inventory`

**What goes wrong:** `update_inventory_display()` iterates `GameState.crafting_inventory`. After removal, this crashes silently or produces an error.

**How to avoid:** In Phase 55, `update_inventory_display()` should be rewritten to show the current bench item only (the full stash display is Phase 57). A minimal stub that shows "Bench: [item name or Empty]" is sufficient.

---

## Code Examples

Verified patterns from existing codebase:

### Existing signal emission pattern (from game_events.gd)
```gdscript
# Existing pattern — add stash_updated here:
signal equipment_changed(slot: String, item: Item)
signal item_crafted(item: Item)
# NEW:
signal stash_updated(slot: String)
```

### Existing ForgeView toast (reusable if needed in future phases)
```gdscript
# forge_view.gd — _show_forge_error() tween pattern
func _show_forge_error(message: String) -> void:
    forge_error_toast.text = message
    forge_error_toast.modulate = Color(1.0, 0.4, 0.4, 1.0)
    forge_error_toast.visible = true
    var tween := create_tween()
    tween.tween_interval(2.0)
    tween.tween_property(forge_error_toast, "modulate:a", 0.0, 0.5)
    tween.tween_callback(func(): forge_error_toast.visible = false)
# D-03 decision: do NOT use this in Phase 55 overflow — silent discard only
```

### Existing prestige wipe pattern (prestige_manager.gd)
```gdscript
# prestige_manager.execute_prestige() already calls _wipe_run_state()
# No changes needed in prestige_manager.gd for Phase 55
GameState._wipe_run_state()
```

### Existing save_manager crafting restore (to leave untouched in Phase 55)
```gdscript
# save_manager.gd _restore_state() — these lines remain in v8 but will be
# deprecated in Phase 58 when SAVE_VERSION becomes 9:
var saved_crafting: Dictionary = data.get("crafting_inventory", {})
for slot_name in ["weapon", "helmet", "armor", "boots", "ring"]:
    ...
    GameState.crafting_inventory[slot_name] = item  # will be removed Phase 58
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Multi-bench (5 per-type slots, type selector) | Single universal bench + 3-slot stash per type | Phase 55 | ForgeView loses item-type-switch buttons; drops go to stash not bench |
| `crafting_inventory[type]` single item per slot | `stash[type]` 3-element Array | Phase 55 | Data model expanded |
| `crafting_bench_type` string | Removed | Phase 55 | Bench holds one item of any type, no type tracking needed |

---

## Validation Architecture

`workflow.nyquist_validation` key is absent from config.json — treat as enabled.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Godot built-in test scene (GDScript) |
| Config file | `tools/test/integration_test.gd` |
| Quick run command | Open `tools/test/integration_test.gd` scene in Godot editor, press F6 |
| Full suite command | Same — all groups run in `_ready()` |

The existing `integration_test.gd` is a single-file GDScript test runner with `_check(condition, description)` helper and `_reset_fresh()` using `GameState.initialize_fresh_game()`. New test groups follow the same `_group_NN_*()` naming pattern.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| STSH-01 | `GameState.stash` exists with 5 keys, each Array capped at 3 | unit | F6 in `tools/test/integration_test.gd` (group_40) | ❌ Wave 0 |
| STSH-01 | `initialize_fresh_game()` creates empty stash (all 5 slots, 0 items each) | unit | F6 (group_40) | ❌ Wave 0 |
| STSH-01 | `_wipe_run_state()` resets stash to empty arrays | unit | F6 (group_40) | ❌ Wave 0 |
| STSH-01 | `crafting_bench` is null after fresh game and wipe | unit | F6 (group_40) | ❌ Wave 0 |
| STSH-04 | `add_item_to_stash()` appends item to correct slot array | unit | F6 (group_41) | ❌ Wave 0 |
| STSH-04 | `add_item_to_stash()` returns true when slot has room | unit | F6 (group_41) | ❌ Wave 0 |
| STSH-04 | `add_item_to_stash()` returns false and discards when slot full (3 items) | unit | F6 (group_41) | ❌ Wave 0 |
| STSH-04 | Overflow discard does not corrupt existing stash entries | unit | F6 (group_41) | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** Run F6 on integration_test.gd, verify new group passes, existing groups unchanged
- **Per wave merge:** Full suite green (all groups pass)
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `tools/test/integration_test.gd` — add `_group_40_stash_data_model()` covering STSH-01 checks
- [ ] `tools/test/integration_test.gd` — add `_group_41_stash_drop_routing()` covering STSH-04 checks
- [ ] Call both groups from `_ready()` after `_group_39_selection_ui()`

*(Framework already installed — Godot editor + existing test file. No new infrastructure needed.)*

---

## Open Questions

1. **Do the five ItemTypeButtons in ForgeView need visible changes in Phase 55?**
   - What we know: They currently switch `crafting_bench_type` and select which bench item is displayed. In Phase 55, with a single bench, they have no function.
   - What's unclear: Whether to hide/disable them now or leave them enabled (pointing at nothing).
   - Recommendation: Disable all five buttons in Phase 55 (they will be repurposed in Phase 57 as stash slot selectors or removed). Leaving them enabled with dead logic is confusing.

2. **Should `stash_updated` carry the full slot array or just the slot name?**
   - What we know: `GameEvents.equipment_changed(slot, item)` passes both. `GameEvents.currency_dropped(drops)` passes a dict.
   - What's unclear: Phase 57 will be the consumer — what does it need?
   - Recommendation: Emit `stash_updated(slot: String)` — signal name only, consumers read `GameState.stash[slot]` directly. Avoids passing Array by value (which would be a copy).

---

## Sources

### Primary (HIGH confidence)

- Direct source code read: `autoloads/game_state.gd` — current `crafting_inventory`, `crafting_bench_type`, `initialize_fresh_game()`, `_wipe_run_state()` implementation
- Direct source code read: `autoloads/game_events.gd` — signal definitions
- Direct source code read: `autoloads/save_manager.gd` — `_build_save_data()`, `_restore_state()` v8 format
- Direct source code read: `autoloads/prestige_manager.gd` — `execute_prestige()` wipe sequence
- Direct source code read: `scenes/forge_view.gd` — all `crafting_inventory` reference sites, `add_item_to_inventory()`, melt/equip handlers
- Direct source code read: `scenes/gameplay_view.gd` — `_on_items_dropped()`, `item_base_found` signal emission
- Direct source code read: `scenes/main_view.gd` — signal wiring `item_base_found.connect(forge_view.set_new_item_base)`
- Direct source code read: `tools/test/integration_test.gd` — test framework structure and group naming
- `.planning/phases/55-stash-data-model/55-CONTEXT.md` — all seven locked decisions

### Secondary (MEDIUM confidence)

None needed — all findings are from direct codebase inspection.

### Tertiary (LOW confidence)

None.

---

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — pure GDScript, no external dependencies, all patterns derived from existing codebase
- Architecture: HIGH — stash dict + single bench model fully specified in CONTEXT.md; code changes mapped to exact lines
- Pitfalls: HIGH — derived from direct reading of all affected files; reference sites enumerated
- Test gaps: HIGH — existing test infrastructure confirmed, new groups follow established pattern

**Research date:** 2026-03-28
**Valid until:** Indefinite — this is a self-contained codebase analysis, not a library ecosystem survey
