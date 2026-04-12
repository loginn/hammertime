# Phase 57: Stash UI - Research

**Researched:** 2026-03-28
**Domain:** Godot 4 GDScript UI — Button-based stash display, signal wiring, tween animations, tooltip_text
**Confidence:** HIGH

## Summary

Phase 57 is a pure UI phase. All data plumbing was completed in Phase 55 (`GameState.stash`, `add_item_to_stash()`, `GameEvents.stash_updated`). The implementation task is to repurpose the 5 hidden ItemTypeButtons nodes in ForgeView into 15 individual stash slot buttons (3 per equipment type), wire them to game state, and handle the tap-to-bench transfer plus tooltip display.

The codebase already has all required patterns: `tooltip_text` on Button nodes (hammer buttons), `_show_forge_error()` tween toast, `pressed.connect()` wiring in `_ready()`, and the `_update_currency_display()` refresh idiom. No new infrastructure is needed — this phase extends what is already in `forge_view.gd`.

The key architectural decision (D-08) is that items do not shift when a slot empties. Each of the 15 slots is a fixed positional slot that maps to `stash[slot_type][index]` (where index is 0, 1, or 2). This simplifies the mapping: button at position `(slot_type, i)` always reads `GameState.stash[slot_type][i]`.

**Primary recommendation:** Replace the 5 ItemTypeButtons + their Container with 15 Button nodes arranged in 5 groups of 3 in `forge_view.tscn`, then wire them in `forge_view.gd` following the same connect/refresh pattern used for currency buttons.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Horizontal row of 15 slots in the ItemTypeButtons area, with visual gaps between each slot type group
- **D-02:** Each group of 3 slots has a label above it (Weapon, Helmet, Armor, Boots, Ring)
- **D-03:** Filled slots show 2-3 letter abbreviations of the item base type (e.g. BS for Broadsword, DA for Dagger, WN for Wand)
- **D-04:** Empty slots render as dim/greyed squares; filled slots use normal button styling with no special rarity or full-stash indicators
- **D-05:** Stash slot buttons are disabled (greyed out) while the crafting bench has an item; toast via existing ForgeErrorToast if somehow tapped ("Melt or equip first")
- **D-06:** Bench must be empty to load from stash — no swap behavior
- **D-07:** On successful tap, stash slot briefly highlights/flashes as the item transfers to bench
- **D-08:** Removing an item from a stash slot leaves an empty gap — remaining items do not shift to fill it
- **D-09:** After equip or melt empties the bench, stash slots re-enable with a subtle pulse animation to draw attention
- **D-10:** Stash display updates live via `stash_updated` signal, even while on Forge tab during combat
- **D-11:** Hovering/long-pressing a stash item shows details via Godot's built-in `tooltip_text` property — plain text, auto show/hide, no custom popup

### Claude's Discretion
- Exact abbreviation codes for all 21 item base types (as long as they're 2-3 letters and unambiguous within each slot type)
- Animation timing for highlight flash and pulse effects
- Exact positioning of stash row within ForgeView layout

### Deferred Ideas (OUT OF SCOPE)
- Item drop filter for unwanted loot (future prestige feature)
- Save slot for work-in-progress item (conflicts with single-bench design)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| STSH-02 | Stash displays as letter-icon squares (W for wand, S for sword, etc.) in ForgeView | 15 Button nodes in scene, abbreviation dict in forge_view.gd, `_update_stash_display()` refresh pattern |
| STSH-03 | Player can tap a stash item to move it onto the crafting bench (item cannot be returned to stash) | `pressed.connect()` on each slot button → set `GameState.crafting_bench`, remove from stash array, call `update_current_item()` |
| STSH-05 | Player can hover/long-press a stash item to see full item details (name, rarity, affixes) | `Button.tooltip_text` — already used on all 11 hammer buttons; build text from `item.get_display_text()` or inline formatter |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Godot 4 Button node | 4.x (project version) | Stash slot interactive element | Already used for all hammer and item-type buttons in ForgeView |
| Godot 4 HBoxContainer / Control | 4.x | Layout for 15-slot row with 5 groups | Standard Godot layout; existing ItemTypeButtons uses Control with manual offsets |
| Godot 4 Tween | 4.x | Flash highlight + pulse animation | Already used in `_show_forge_error()` tween pattern |
| Godot 4 tooltip_text | 4.x | Hover item detail popup | Already used on all 11 hammer buttons |

No new dependencies. All required nodes and APIs are already in use in the project.

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `tooltip_text` (D-11) | Custom Panel popup | Custom popup is more flexible but far more code; D-11 locks tooltip_text |
| Fixed positional slots (D-08) | Shifting/packing layout | Shifting is simpler visually but conflicts with D-08; fixed slots make index mapping trivial |
| Scene nodes for slots | Programmatic Button creation | Programmatic is possible but harder to position in editor; scene nodes match existing project pattern |

## Architecture Patterns

### Recommended Project Structure
No new files needed. All changes are in:
```
scenes/
├── forge_view.tscn   # Replace ItemTypeButtons subtree with 5-group stash layout
└── forge_view.gd     # Add stash wiring, _update_stash_display(), _on_stash_slot_pressed()
```

### Pattern 1: Fixed Slot Index Mapping
**What:** Each of 15 buttons maps to a deterministic `(slot_type, index)` pair. Index 0-2 within each slot type group. When the stash array for that type has fewer than 3 items, slots at index >= size are empty.
**When to use:** Always — D-08 mandates no shifting.
**Example:**
```gdscript
# Source: derived from existing GameState.stash structure
# stash["weapon"] is Array capped at 3 items, indices 0-2 may be null/missing

func _update_stash_display() -> void:
    for slot_type in stash_slot_buttons:  # Dict keyed by slot type string
        var items: Array = GameState.stash.get(slot_type, [])
        for i in range(3):
            var btn: Button = stash_slot_buttons[slot_type][i]
            var has_item: bool = i < items.size()
            if has_item:
                var item: Item = items[i]
                btn.text = ITEM_ABBREVIATIONS[item.get_class()]  # or instanceof check
                btn.tooltip_text = _build_stash_tooltip(item)
                btn.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Normal
                btn.disabled = (GameState.crafting_bench != null)
            else:
                btn.text = ""
                btn.tooltip_text = ""
                btn.modulate = Color(0.4, 0.4, 0.4, 1.0)  # Dim/greyed
                btn.disabled = true
```

### Pattern 2: Tap-to-Bench Transfer
**What:** When a filled stash slot is tapped, remove item from stash array, place on `GameState.crafting_bench`, refresh all displays.
**When to use:** `_on_stash_slot_pressed(slot_type, index)`.
**Example:**
```gdscript
# Source: derived from existing _on_equip_pressed() pattern in forge_view.gd
func _on_stash_slot_pressed(slot_type: String, index: int) -> void:
    if GameState.crafting_bench != null:
        _show_forge_error("Melt or equip first")
        return
    var items: Array = GameState.stash[slot_type]
    if index >= items.size():
        return  # Empty slot tapped (shouldn't happen if disabled, but guard)
    var item: Item = items[index]
    items.remove_at(index)
    GameState.crafting_bench = item
    current_item = item
    _flash_stash_slot(slot_type, index)
    update_current_item()
    update_stash_display()
    update_melt_equip_states()
    update_inventory_display()
```

### Pattern 3: Signal-Driven Refresh
**What:** Connect `GameEvents.stash_updated` in `_ready()` to call `_update_stash_display()`. This covers live updates during combat (D-10).
**When to use:** `_ready()` wiring, same as `GameEvents.tag_currency_dropped.connect(...)`.
**Example:**
```gdscript
# Source: forge_view.gd line 134 — existing signal connect pattern
GameEvents.stash_updated.connect(_on_stash_updated)

func _on_stash_updated(_slot: String) -> void:
    _update_stash_display()
```

### Pattern 4: Tween Flash + Pulse
**What:** On successful transfer, briefly highlight the slot. On bench clear (melt/equip), pulse all enabled stash slots.
**When to use:** D-07 (flash on transfer), D-09 (pulse when bench empties).
**Example:**
```gdscript
# Source: forge_view.gd _show_forge_error() tween pattern (lines 301-308)

func _flash_stash_slot(slot_type: String, index: int) -> void:
    var btn: Button = stash_slot_buttons[slot_type][index]
    var tween := create_tween()
    tween.tween_property(btn, "modulate", Color(1.0, 1.0, 0.3, 1.0), 0.08)
    tween.tween_property(btn, "modulate", Color(0.4, 0.4, 0.4, 1.0), 0.25)
    # Ends dim (slot is now empty)

func _pulse_stash_slots() -> void:
    # Called from _on_melt_pressed and _on_equip_pressed after bench clears
    for slot_type in stash_slot_buttons:
        for i in range(3):
            var btn: Button = stash_slot_buttons[slot_type][i]
            if not btn.disabled:
                var tween := create_tween()
                tween.tween_property(btn, "modulate:a", 0.4, 0.15)
                tween.tween_property(btn, "modulate:a", 1.0, 0.15)
```

### Pattern 5: Bench-State Gating
**What:** All filled stash slot buttons are disabled when `GameState.crafting_bench != null`. Re-enable (and pulse) when bench becomes empty. This is checked on every `_update_stash_display()` call.
**When to use:** Called from every display refresh path.

### Pattern 6: Abbreviation Dictionary
**What:** A const dict in `forge_view.gd` mapping GDScript class_name strings to 2-3 letter abbreviations. Used by `_update_stash_display()` to set button text.
**When to use:** Building slot button text for filled slots (D-03).

Recommended abbreviation table (Claude's Discretion — all unambiguous within their slot type):

| Class | Slot | Abbreviation | Rationale |
|-------|------|-------------|-----------|
| Broadsword | weapon | BS | Broadsword |
| Battleaxe | weapon | BA | Battleaxe |
| Warhammer | weapon | WH | Warhammer |
| Dagger | weapon | DA | Dagger |
| VenomBlade | weapon | VB | Venom Blade |
| Shortbow | weapon | SB | Shortbow |
| Wand | weapon | WN | Wand (WA conflicts with WArhammer) |
| LightningRod | weapon | LR | Lightning Rod |
| Sceptre | weapon | SC | Sceptre |
| IronHelm | helmet | IH | Iron Helm |
| LeatherHood | helmet | LH | Leather Hood |
| Circlet | helmet | CI | Circlet |
| IronPlate | armor | IP | Iron Plate |
| LeatherVest | armor | LV | Leather Vest |
| SilkRobe | armor | SR | Silk Robe |
| IronGreaves | boots | IG | Iron Greaves |
| LeatherBoots | boots | LB | Leather Boots |
| SilkSlippers | boots | SS | Silk Slippers |
| IronBand | ring | IB | Iron Band |
| JadeRing | ring | JR | Jade Ring |
| SapphireRing | ring | SP | Sapphire Ring (SA conflicts with SApphire vs other; SP for Sapphire) |

Note: Uniqueness is required within each slot type group, not globally. All abbreviations above are unique within their group.

### Pattern 7: Tooltip Text Builder
**What:** Build a plain-text string from an Item for `tooltip_text`. Reuse `item.get_display_text()` which already formats name + implicit + prefixes + suffixes — or write a cleaner formatter without the `----` separator lines.
**When to use:** Setting `btn.tooltip_text` in `_update_stash_display()`.
**Example:**
```gdscript
# item.get_display_text() exists in item.gd lines 203-235
# Output: "----\nname: ...\ndps: ...\nimplicit: ...\nprefixes: ...\nsuffixes: ...\n----\n"
# For tooltip, trim the separators or use as-is — both work with tooltip_text
func _build_stash_tooltip(item: Item) -> String:
    return item.get_display_text()  # Simplest; or build a cleaner version
```

### Anti-Patterns to Avoid
- **Shifting stash items:** D-08 explicitly forbids it. Index 0 always means the first item added, not "first non-null item."
- **Custom popup nodes:** D-11 mandates `tooltip_text`. Do not create Panel/PanelContainer children.
- **Storing button references in Array:** Use a nested Dictionary `{ slot_type: [btn0, btn1, btn2] }` for O(1) lookup by slot type and index.
- **Re-creating buttons dynamically:** Build all 15 buttons in the scene, not in code. The scene approach is consistent with how hammer buttons work.
- **Modifying the stash Array in-place without `remove_at`:** GDScript Arrays are reference types — `items.remove_at(index)` on `GameState.stash[slot_type]` mutates the canonical state correctly.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Hover tooltips | Custom Panel popup with show/hide logic | `Button.tooltip_text` | D-11 mandates this; Godot handles show/hide, positioning, auto-hide automatically |
| Toast for invalid tap | New toast system | `_show_forge_error()` tween (already in ForgeView) | Already handles text, color, fade-out; reuse exactly |
| Tween animations | Manual `_process()` interpolation | `create_tween()` | Already used in `_show_forge_error()`; Godot Tweens are the standard approach |
| Item description text | Custom formatter | `item.get_display_text()` | Method already exists on Item base class (item.gd:203) |

## Common Pitfalls

### Pitfall 1: Forgetting to Disconnect/Reconnect Signals on Scene Reloads
**What goes wrong:** If `stash_updated` is connected in `_ready()` and the scene is reloaded (e.g., tab switch), duplicate connections can fire the handler multiple times.
**Why it happens:** Godot `signal.connect()` does not deduplicate by default.
**How to avoid:** Use `GameEvents.stash_updated.connect(_on_stash_updated)` only once in `_ready()`. If the scene can be freed and re-instantiated, consider `connect(..., CONNECT_ONE_SHOT)` or check `is_connected()` first. For ForgeView which persists, a single connect in `_ready()` is fine.
**Warning signs:** Stash display updating 2x or 3x per stash change.

### Pitfall 2: Stash Array Mutation Race with Display
**What goes wrong:** `items.remove_at(index)` is called, then `_update_stash_display()` is called, but `stash_updated` signal also triggers `_update_stash_display()` because `add_item_to_stash()` emits it. However, for the tap-to-bench path, the signal is NOT emitted (we're removing, not adding).
**Why it happens:** `GameState.add_item_to_stash()` emits `stash_updated`, but direct array mutation (`stash["weapon"].remove_at(0)`) does not. The ForgeView must emit or call refresh itself after removal.
**How to avoid:** After `stash[slot].remove_at(index)`, call `_update_stash_display()` explicitly in `_on_stash_slot_pressed()`. Do not rely on the signal being emitted.

### Pitfall 3: Button Disabled State Out of Sync with Bench State
**What goes wrong:** Player melts bench item, but stash buttons remain greyed out because `_update_stash_display()` is not called from the melt/equip path.
**Why it happens:** The existing `_on_melt_pressed()` and `_on_equip_pressed()` call `update_inventory_display()` and `update_melt_equip_states()` but have no stash refresh call (stash didn't exist when they were written).
**How to avoid:** Add `_update_stash_display()` and `_pulse_stash_slots()` calls at the end of the bench-clearing branches of `_on_melt_pressed()` and `_on_equip_pressed()`.

### Pitfall 4: Scene Tree Structure — ItemTypeButtons Must Be Replaced Not Hidden
**What goes wrong:** Phase 55 hid the 5 ItemTypeButtons. Phase 57 needs 15 buttons. Simply unhiding the 5 type-select buttons gives the wrong behavior and count.
**Why it happens:** The original 5 buttons were for selecting which slot type is on the bench. The new 15 buttons are per-stash-slot. Different purpose.
**How to avoid:** Replace the `ItemTypeButtons` Control and its 5 children in the .tscn with a new `StashDisplay` Control containing 5 `HBoxContainer`/`VBoxContainer` groups. Delete the old `weapon_type_btn` etc. `@onready` references and the old connect calls for them in `_ready()`. Add new `@onready` wiring for the 15 new buttons.

### Pitfall 5: Class Name vs get_class() Behavior
**What goes wrong:** Using `item.get_class()` returns "Resource" or the GDScript class_name, which may differ from the expected string if the class hierarchy is traversed incorrectly.
**Why it happens:** In Godot 4, `get_class()` returns the Godot built-in class, not the GDScript class_name. For custom class_name types, use `is` keyword or `item.get_script().resource_path` parsing.
**How to avoid:** Use the `is` keyword for instance checks in the abbreviation lookup:
```gdscript
const ITEM_ABBREVIATIONS: Dictionary = {}  # Don't use class name strings

func _get_item_abbreviation(item: Item) -> String:
    if item is Broadsword: return "BS"
    if item is Battleaxe: return "BA"
    # ... etc
    return "??"
```
Alternatively, add a method `get_abbreviation() -> String` to each item class and override it. The `is` approach avoids all class-name string fragility.

### Pitfall 6: Tooltip_text Does Not Work on Disabled Buttons
**What goes wrong:** Empty stash slots set `btn.disabled = true`. Players hovering disabled buttons see no tooltip (expected) but filled slots that are temporarily disabled (bench occupied, D-05) also show no tooltip.
**Why it happens:** Godot's built-in tooltip is suppressed when a Control is disabled.
**How to avoid:** For filled-but-disabled slots, set `tooltip_text` on the parent container or use `mouse_filter = MOUSE_FILTER_PASS` on the button. Alternatively: only disable the click behavior (override `_gui_input`) rather than using `disabled = true` on filled slots. Simplest approach: since D-04 says no rarity indicators and D-05 says disabled = greyed, accept that tooltips on disabled filled slots won't show (feature gap), or use a `mouse_entered` + Label approach only for filled slots when bench is occupied. The simplest resolution that matches D-11: set `disabled = true` on empty slots, but for filled slots when bench is occupied, use `mouse_filter = MOUSE_FILTER_STOP` (still clickable for focus) + leave tooltip_text set. **Recommendation:** Test in editor before committing to the disable approach.

## Code Examples

### Existing ForgeView `_show_forge_error()` (reuse verbatim)
```gdscript
# Source: forge_view.gd lines 301-308
func _show_forge_error(message: String) -> void:
    forge_error_toast.text = message
    forge_error_toast.modulate = Color(1.0, 0.4, 0.4, 1.0)
    forge_error_toast.visible = true
    var tween := create_tween()
    tween.tween_interval(2.0)
    tween.tween_property(forge_error_toast, "modulate:a", 0.0, 0.5)
    tween.tween_callback(func(): forge_error_toast.visible = false)
```

### Existing GameState.stash Structure
```gdscript
# Source: autoloads/game_state.gd lines 79-86 and 223-234
# stash is { "weapon": Array, "helmet": Array, "armor": Array, "boots": Array, "ring": Array }
# Each Array is capped at 3 items. Arrays may have 0, 1, 2, or 3 Items.
# Index 0 = first item added. Items are NOT shifted on removal (D-08).
# add_item_to_stash(item) appends and emits stash_updated(slot)
# There is no remove_from_stash() — ForgeView must mutate directly: stash[slot].remove_at(index)
```

### Existing Item.get_display_text() (use for tooltip)
```gdscript
# Source: item.gd lines 203-235
# Returns multiline plain text with name, dps/defense, implicit, prefixes, suffixes
# Suitable for tooltip_text as-is (Godot auto-wraps tooltips)
# Example output for a Magic Broadsword:
# "----\nname: Iron Broadsword\ndps: 18.0\nimplicit:\n\t...\nprefixes:\n\t...\nsuffixes:\n\t...\n----\n"
```

### Scene Layout for New StashDisplay (tscn snippet)
```
[node name="StashDisplay" type="HBoxContainer" parent="."]
# Replace ItemTypeButtons node. 5 children, one per slot type.
# Each child: VBoxContainer with Label (type name) + HBoxContainer (3 Button nodes)

[node name="WeaponGroup" type="VBoxContainer" parent="StashDisplay"]
[node name="WeaponLabel" type="Label" parent="StashDisplay/WeaponGroup"]
text = "Weapon"
[node name="WeaponSlots" type="HBoxContainer" parent="StashDisplay/WeaponGroup"]
[node name="WeaponSlot0" type="Button" parent="StashDisplay/WeaponGroup/WeaponSlots"]
[node name="WeaponSlot1" type="Button" parent="StashDisplay/WeaponGroup/WeaponSlots"]
[node name="WeaponSlot2" type="Button" parent="StashDisplay/WeaponGroup/WeaponSlots"]
# ... repeat for Helmet, Armor, Boots, Ring groups
```

### @onready Pattern for 15 Buttons (forge_view.gd)
```gdscript
# Replace old weapon_type_btn, helmet_type_btn, etc. @onready vars with:
@onready var stash_slots: Dictionary = {}  # Populated in _ready()

# In _ready(), after adding child nodes or referencing them:
stash_slots = {
    "weapon": [
        $StashDisplay/WeaponGroup/WeaponSlots/WeaponSlot0,
        $StashDisplay/WeaponGroup/WeaponSlots/WeaponSlot1,
        $StashDisplay/WeaponGroup/WeaponSlots/WeaponSlot2,
    ],
    "helmet": [...],
    "armor": [...],
    "boots": [...],
    "ring": [...],
}
# Wire each button:
for slot_type in stash_slots:
    for i in range(3):
        stash_slots[slot_type][i].pressed.connect(_on_stash_slot_pressed.bind(slot_type, i))
```

## Integration Points Summary

| Touch Point | File | What Changes |
|-------------|------|--------------|
| Scene tree | `forge_view.tscn` | Replace ItemTypeButtons subtree with StashDisplay (HBoxContainer with 5 groups of VBox + 3 Buttons + Label) |
| @onready refs | `forge_view.gd` | Remove 5 old `*_type_btn` refs; add `stash_slots` dict |
| `_ready()` | `forge_view.gd` | Remove old ItemTypeButton hide/disable block (lines 187-198); add stash slot connects + stash_updated signal connect |
| Stash refresh | `forge_view.gd` | New `_update_stash_display()` function |
| Tap handler | `forge_view.gd` | New `_on_stash_slot_pressed(slot_type, index)` function |
| Bench clear | `forge_view.gd` | Add `_update_stash_display()` + `_pulse_stash_slots()` calls inside `_on_melt_pressed()` and `_on_equip_pressed()` bench-clear branches |
| Dead code | `forge_view.gd` | `update_item_type_button_states()` and `update_slot_button_labels()` and `_on_item_type_selected()` — already no-ops; can stay or be removed |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Godot integration test (custom runner) |
| Config file | `tools/test/integration_test.tscn` — run with F6 in editor |
| Quick run command | Open `tools/test/integration_test.tscn` in Godot editor, press F6, observe console |
| Full suite command | Same — all groups run sequentially in `_ready()` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| STSH-02 | Stash slots display correct abbreviations for filled items; empty slots dim | unit | `_group_45_stash_ui_display()` in integration_test.gd | ❌ Wave 0 |
| STSH-03 | Tapping filled slot moves item to crafting bench; slot becomes empty | unit | `_group_46_stash_tap_to_bench()` in integration_test.gd | ❌ Wave 0 |
| STSH-05 | tooltip_text set on filled slots with item details | unit | `_group_47_stash_tooltip_text()` in integration_test.gd | ❌ Wave 0 |

Note: D-07 (flash animation), D-09 (pulse animation), and visual greying (D-04) are human-verifiable only — no automated test coverage needed for animation timing.

### Sampling Rate
- **Per task commit:** Run integration_test.tscn in Godot editor, verify new groups pass
- **Per wave merge:** Full integration_test suite (all 44+ groups) green
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `tools/test/integration_test.gd` — add `_group_45_stash_ui_display()`, `_group_46_stash_tap_to_bench()`, `_group_47_stash_tooltip_text()` — these test the data-layer behavior (stash array mutation, bench assignment, tooltip text content) without requiring a live scene

## Sources

### Primary (HIGH confidence)
- `autoloads/game_state.gd` — stash dict structure, add_item_to_stash(), stash_updated emit
- `autoloads/game_events.gd` — stash_updated signal definition
- `scenes/forge_view.gd` — existing button patterns, _show_forge_error(), update_currency_button_states() refresh idiom, ItemTypeButtons insertion point (lines 187-198)
- `scenes/forge_view.tscn` — ItemTypeButtons node tree (lines 270-321), position offsets
- `models/items/item.gd` — get_display_text(), class structure for instanceof checks
- All item class files — verified item_name patterns and class_name for abbreviation table

### Secondary (MEDIUM confidence)
- Godot 4 docs (tooltip_text behavior on disabled Controls) — standard Godot behavior, verified by existing hammer button usage in project

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already in use in the project, no new dependencies
- Architecture patterns: HIGH — all patterns derived directly from existing forge_view.gd code
- Pitfalls: HIGH — identified from direct code inspection of the integration points
- Abbreviation table: HIGH (Claude's Discretion) — all abbreviations verified unique within their slot groups against actual class names

**Research date:** 2026-03-28
**Valid until:** 2026-04-28 (stable domain — Godot 4 project, no external dependencies)
