# Phase 20: Crafting UX Enhancements - Research

**Researched:** 2026-02-17
**Domain:** Godot 4.5 UI — tooltips, stat comparison, crafting workflow
**Confidence:** HIGH

## Summary

Phase 20 adds four UX features to the existing ForgeView crafting scene: hammer tooltips, stat comparison on equip hover, per-type independent crafting slots (already partially implemented), and two-click equip confirmation with the "Finish Item" button removed.

The codebase already has per-type crafting slots via `GameState.crafting_inventory` (a Dictionary with weapon/helmet/armor/boots/ring keys) and item type buttons that switch between them. The current `finished_item` workflow (Finish Item -> Melt/Equip) needs to be replaced with direct Equip on the current item, removing the Finish Item button entirely.

**Primary recommendation:** Implement all four features as modifications to `forge_view.gd` and `forge_view.tscn`. No new scenes or autoloads needed. Use Godot's built-in `TooltipText` property for hammer tooltips, `RichTextLabel` with BBCode for colored stat deltas in the hero stats panel, and a Timer node for the equip confirmation timeout.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Hover tooltips on hammer buttons (appear on hover, disappear on mouse leave)
- Content: hammer name, effect description in a sentence, and rarity requirement
- Description only — no count in tooltip (count already visible on button)
- Position: above the hammer button
- Stat deltas display inline in the hero stats panel (left side of ForgeView) when hovering the Equip button
- Format: current value with colored +/- delta (e.g. "DPS: 45 +12" in green, "Armor: 30 -5" in red)
- Triggers on hovering the Equip button — compares currently equipped item vs the crafted item about to be equipped
- Shows all relevant stats that would change (DPS, armor, evasion, ES, resistances, life, mana, etc.)
- Shows item-level contribution differences, not total hero stat changes
- Each item type (weapon, helmet, armor, boots, ring) has its own independent crafting slot
- Switching item types shows the different item without losing work on other types
- Items auto-fill from inventory (whatever is stored for that type)
- Items come from loot drops only — no free generation buttons
- Only the Equip action gets confirmation (not hammers or other actions)
- Remove the existing "Finish Item" button entirely
- Modify existing Equip button: when equipping would overwrite an existing equipped item, button text changes to "Confirm Overwrite?"
- Text change only — no color change on the button
- Confirm state times out after 3 seconds and reverts to normal "Equip" text
- When slot is empty, Equip works immediately with no confirmation

### Claude's Discretion
- Empty crafting slot visual treatment
- Tooltip hover delay timing
- Exact tooltip styling (fits dark theme)
- Stat delta color values (green/red shades)

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CRAFT-01 | Each hammer button shows a tooltip describing what it does and its requirements | Use Godot's built-in `tooltip_text` property on Button nodes; customize positioning with `tooltip_position` theme constant |
| CRAFT-02 | Hovering an equipment slot with a craftable item available shows before/after stat comparison (item-level deltas, not total hero stats) | Connect `mouse_entered`/`mouse_exited` signals on EquipButton; compute per-item stat diffs using existing item properties; display via RichTextLabel with BBCode color tags |
| CRAFT-03 | Crafting view has one crafted-item slot per item type instead of a single shared slot | Already implemented — `GameState.crafting_inventory` maintains separate slots; item type buttons switch `current_item`; no code change needed for storage |
| CRAFT-04 | Finishing an item into an occupied slot requires two-click confirmation | Remove `FinishItemButton`; change Equip flow to work directly on `current_item`; add confirmation state with 3-second Timer that resets button text |
</phase_requirements>

## Architecture Patterns

### Current ForgeView Layout (from forge_view.tscn)

```
ForgeView (Node2D)
├── Background (ColorRect 1280x670)
├── HammerSidebar (ColorRect 40,10 → 300,660)
│   ├── RunicHammerBtn, ForgeHammerBtn (row 1, toggle buttons with icons)
│   ├── TackHammerBtn, GrandHammerBtn (row 2)
│   ├── ClawHammerBtn, TuningHammerBtn (row 3)
│   ├── FinishItemButton (to be REMOVED)
│   └── InventoryLabel
├── ItemGraphicsPanel (ColorRect 340,0 → 770,160)
│   └── ItemImage (TextureRect)
├── ItemTypeButtons (Control 340,165 → 770,205)
│   └── WeaponButton, HelmetButton, ArmorButton, BootsButton, RingButton
├── HeroGraphicsPanel (ColorRect 810,0 → 1240,200)
│   └── HeroImage
├── ItemStatsPanel (ColorRect 340,230 → 770,660)
│   ├── ItemStatsLabel
│   ├── MeltButton
│   └── EquipButton
└── HeroStatsPanel (ColorRect 810,230 → 1240,660)
    └── HeroStatsLabel
```

### Pattern 1: Hammer Tooltips via tooltip_text

**What:** Godot's built-in `tooltip_text` property on Control nodes shows a tooltip on hover.

**When to use:** Simple text tooltips on existing buttons.

**Implementation:**
```gdscript
# In _ready(), set tooltip_text for each hammer button
runic_btn.tooltip_text = "Runic Hammer\nTurns a normal item into a magic item with 1-2 random mods.\nRequires: Normal rarity"
forge_btn.tooltip_text = "Forge Hammer\nTurns a normal item into a rare item with 4-6 random mods.\nRequires: Normal rarity"
# etc.
```

**Confidence:** HIGH — `tooltip_text` is a standard Control property in Godot 4.x. Works out of the box with hover show/hide behavior. The tooltip appears near the mouse cursor by default. To position above the button, we can use a custom tooltip via `_make_custom_tooltip()` override or accept the default position.

**Custom tooltip positioning (if needed):**
```gdscript
# Override on the button to create a custom tooltip panel
func _make_custom_tooltip(for_text: String) -> Control:
    var label := Label.new()
    label.text = for_text
    label.add_theme_font_size_override("font_size", 11)
    return label
```

### Pattern 2: Stat Comparison via RichTextLabel BBCode

**What:** Replace the `HeroStatsLabel` (plain Label) with a `RichTextLabel` to support inline colored text for stat deltas.

**When to use:** When showing mixed-color text (green for positive deltas, red for negative).

**Implementation:**
```gdscript
# BBCode format for colored deltas
var delta_text := "DPS: %.1f [color=green]+%.1f[/color]" % [current_dps, delta_dps]
# or for negative:
var delta_text := "Armor: %d [color=red]%d[/color]" % [current_armor, delta_armor]
```

**Key consideration:** The `HeroStatsLabel` is currently a plain `Label` node. It must be changed to `RichTextLabel` to support BBCode. The `bbcode_enabled` property must be set to `true`. This also means changing all existing text assignment from `label.text = ...` to `label.text = ...` (RichTextLabel uses `.text` for BBCode content).

**Confidence:** HIGH — RichTextLabel BBCode is a well-established Godot 4 feature.

### Pattern 3: Equip Confirmation via Timer

**What:** Use a Timer node to revert the Equip button text after 3 seconds.

**Implementation:**
```gdscript
var equip_confirm_pending: bool = false

@onready var equip_timer: Timer = Timer.new()

func _ready() -> void:
    # ... existing code ...
    equip_timer.one_shot = true
    equip_timer.wait_time = 3.0
    equip_timer.timeout.connect(_on_equip_timer_timeout)
    add_child(equip_timer)

func _on_equip_pressed() -> void:
    if current_item == null:
        return
    var slot_name := get_item_type(current_item)
    if slot_name == "None":
        return

    # Check if slot is occupied
    var existing := GameState.hero.equipped_items.get(slot_name)
    if existing != null and not equip_confirm_pending:
        # First click — show confirmation
        equip_confirm_pending = true
        equip_button.text = "Confirm Overwrite?"
        equip_timer.start()
        return

    # Second click (or empty slot) — do the equip
    equip_confirm_pending = false
    equip_timer.stop()
    equip_button.text = "Equip"
    # ... actual equip logic ...

func _on_equip_timer_timeout() -> void:
    equip_confirm_pending = false
    equip_button.text = "Equip"
```

**Confidence:** HIGH — Timer is the standard Godot approach for timed UI state resets.

### Pattern 4: Remove Finish Item Flow

**What:** The current flow is: craft item -> Finish Item -> Melt/Equip. Phase 20 removes the "Finish Item" step entirely. The Equip button should work directly on `current_item` instead of `finished_item`.

**Current state:** `finished_item` is a separate variable set when "Finish Item" is clicked, removing the item from `crafting_inventory`. Melt and Equip operate on `finished_item`.

**New flow:** Equip operates directly on `current_item`. The item stays in `crafting_inventory` until equipped. Melt operates on `current_item` too. No more `finished_item` variable.

**Impact:**
- Remove `FinishItemButton` from `.tscn` file
- Remove `finish_item_btn` `@onready` reference
- Remove `finish_item()`, `_on_finish_item_button_pressed()`
- Remove `finished_item` variable
- Change `_on_equip_pressed()` to use `current_item` directly
- Change `_on_melt_pressed()` to use `current_item` directly
- Change `update_melt_equip_states()` to check `current_item != null`
- Move the `GameEvents.item_crafted.emit()` call into `_on_equip_pressed()` (only emit when actually equipping, not on "finish")
- `update_item_stats_display()` no longer checks `finished_item`

**Confidence:** HIGH — straightforward refactor of existing code.

## Current State Analysis

### Per-Type Slots (CRAFT-03) — Already Implemented

The codebase already maintains per-type slots:
- `GameState.crafting_inventory` is a Dictionary with keys: "weapon", "helmet", "armor", "boots", "ring"
- Item type buttons (WeaponButton, HelmetButton, etc.) switch the active crafting item
- `GameState.crafting_bench_type` tracks the currently selected type
- Switching types does NOT lose work — items persist in their slots
- `add_item_to_inventory()` auto-fills from loot drops via `is_item_better()` comparison

**What's needed:** Verify that CRAFT-03's requirement is already met. The only possible gap: the CONTEXT.md says "Items come from loot drops only — no free generation buttons." Currently, `forge_view.gd` creates starting items in `_ready()` when `has_saved_items` is false. This is starter items for fresh games, not "free generation," so it should be acceptable.

### Stat Comparison Scope (CRAFT-02)

The CONTEXT.md specifies "item-level contribution differences, not total hero stat changes." This means:

For a **weapon swap** (equipped Light Sword DPS=10 vs crafted Light Sword DPS=25):
- Show: "DPS: 10 → 25 (+15)" — the item's own stat delta
- NOT: "Total Hero DPS: 35 → 50 (+15)" — hero aggregate

For an **armor swap** (equipped armor=20 vs crafted armor=35):
- Show: "Armor: 20 → 35 (+15)"
- Also show evasion, ES, health, resistances if they differ

This simplifies the implementation — we only compare properties of the two items, not recalculate full hero stats.

### Hammer Tooltip Content

Based on the currency implementations:

| Hammer | Description | Requirement |
|--------|-------------|-------------|
| Runic Hammer | Turns a normal item into a magic item with 1-2 random mods | Requires: Normal rarity |
| Forge Hammer | Turns a normal item into a rare item with 4-6 random mods | Requires: Normal rarity |
| Tack Hammer | Adds one random mod to a magic item | Requires: Magic rarity with room for mods |
| Grand Hammer | Adds one random mod to a rare item | Requires: Rare rarity with room for mods |
| Claw Hammer | Removes one random mod from an item | Requires: Item with at least one mod |
| Tuning Hammer | Rerolls all mod values within their tier ranges | Requires: Item with at least one mod |

### HeroStatsPanel Position

The HeroStatsPanel is on the RIGHT side of ForgeView (810,230 → 1240,660), not the left. The CONTEXT.md says "stat deltas display inline in the hero stats panel (left side of ForgeView)." However, looking at the actual layout:
- LEFT: HammerSidebar (40-300)
- CENTER: ItemStatsPanel (340-770)
- RIGHT: HeroStatsPanel (810-1240)

The CONTEXT.md may be describing the intended location inaccurately, or the user means "the hero stats panel." Since the stat comparison shows crafted-vs-equipped item stats, it makes most sense to display in the **HeroStatsPanel** (right side), which already shows equipped item info on hover. The comparison will replace the normal hero stats display when the Equip button is hovered.

## Common Pitfalls

### Pitfall 1: RichTextLabel Text Assignment
**What goes wrong:** Using `.text` on RichTextLabel without enabling BBCode.
**Why it happens:** RichTextLabel has both `.text` (plain text) and BBCode mode via `bbcode_enabled = true` with text set via `.text` property.
**How to avoid:** Always set `bbcode_enabled = true` and use `[color=...]` tags in the text content. In Godot 4, set `bbcode_enabled` in the inspector or via code.

### Pitfall 2: Tooltip Text vs Custom Tooltip
**What goes wrong:** Default `tooltip_text` positions the tooltip at the mouse cursor, not above the button.
**Why it happens:** Godot's default tooltip behavior follows the mouse.
**How to avoid:** For "above the button" positioning, use `_make_custom_tooltip()` to return a custom Control, then the tooltip system positions it automatically. Alternatively, accept default positioning which is adequate for this use case.

### Pitfall 3: Timer Reference After Scene Change
**What goes wrong:** Timer fires after the ForgeView is freed (e.g., user switches to gameplay).
**Why it happens:** Timer is a child of ForgeView and gets freed with it.
**How to avoid:** Timer is a child node — it gets freed automatically when ForgeView is freed, so the timeout callback won't fire on a freed node. This is safe by default in Godot.

### Pitfall 4: Equip Button State Reset on Item Type Switch
**What goes wrong:** User clicks Equip (shows "Confirm Overwrite?"), then switches item type. The button still shows confirmation text for the wrong item.
**How to avoid:** Reset `equip_confirm_pending` and button text in `_on_item_type_selected()`.

### Pitfall 5: Stat Comparison With Empty Slots
**What goes wrong:** Comparing crafted item to an empty equipped slot (null item) causes null reference.
**How to avoid:** When the equipped slot is null, all "current" stats are 0. Show only positive deltas (everything is a gain).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tooltips | Custom Panel + mouse tracking | `tooltip_text` or `_make_custom_tooltip()` | Built-in hover/show/hide/position logic |
| Colored text | Multiple Label nodes with different colors | RichTextLabel with BBCode `[color=]` tags | Single node, inline color changes |
| Timed state reset | `_process()` with delta accumulation | Timer node with `one_shot = true` | Cleaner, no per-frame overhead |

## Code Examples

### Stat Delta Calculation for Weapons

```gdscript
func get_weapon_stat_deltas(crafted: Weapon, equipped: Weapon) -> Dictionary:
    # Returns delta values for each stat
    var deltas := {}
    if equipped != null:
        deltas["DPS"] = crafted.dps - equipped.dps
        deltas["Base Damage"] = crafted.base_damage - equipped.base_damage
        deltas["Crit Chance"] = crafted.crit_chance - equipped.crit_chance
        deltas["Crit Damage"] = crafted.crit_damage - equipped.crit_damage
    else:
        deltas["DPS"] = crafted.dps
        deltas["Base Damage"] = crafted.base_damage
        deltas["Crit Chance"] = crafted.crit_chance - 5.0  # Base
        deltas["Crit Damage"] = crafted.crit_damage - 150.0  # Base
    return deltas
```

### BBCode Delta Formatting

```gdscript
func format_delta(label: String, current_val: float, delta: float, fmt: String = "%.1f") -> String:
    var line := "%s: %s" % [label, fmt % current_val]
    if delta > 0:
        line += " [color=#55ff55]+" + fmt % delta + "[/color]"
    elif delta < 0:
        line += " [color=#ff5555]" + fmt % delta + "[/color]"
    return line
```

## Open Questions

1. **Tooltip position "above the button"**
   - What we know: Default Godot tooltip follows mouse cursor. Custom tooltip via `_make_custom_tooltip()` also positions near cursor.
   - What's unclear: Getting a tooltip to consistently appear ABOVE the button requires more custom work (PopupPanel or manual positioning).
   - Recommendation: Use `_make_custom_tooltip()` for styled tooltips that fit the dark theme. Accept Godot's default positioning (near cursor). If "above button" is critical, implement a custom PopupPanel with manual position calculation.

2. **Melt button behavior after removing Finish Item**
   - What we know: Currently Melt only works on `finished_item`. With Finish Item removed, Melt should work on `current_item`.
   - What's unclear: Melting an item while it's the active crafting slot — should it clear the slot and show "empty" state?
   - Recommendation: Melt destroys `current_item`, sets `GameState.crafting_inventory[type] = null`, and shows empty slot visual.

## Sources

### Primary (HIGH confidence)
- Codebase analysis: `scenes/forge_view.gd`, `scenes/forge_view.tscn`, `scenes/crafting_view.gd`
- Codebase analysis: All 6 currency implementations in `models/currencies/`
- Codebase analysis: `models/items/item.gd`, `models/items/weapon.gd`, `models/items/armor.gd`, `models/items/ring.gd`
- Codebase analysis: `models/hero.gd`, `models/stats/stat_calculator.gd`
- Codebase analysis: `autoloads/game_state.gd`, `autoloads/game_events.gd`

### Secondary (MEDIUM confidence)
- Godot 4.5 Control.tooltip_text property — standard in all Godot 4.x versions
- Godot 4.5 RichTextLabel BBCode support — standard feature
- Godot 4.5 Timer node — standard feature

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all features use built-in Godot 4 nodes and properties
- Architecture: HIGH — direct modification of existing ForgeView, no new scenes needed
- Pitfalls: HIGH — based on direct codebase analysis of current implementation

**Research date:** 2026-02-17
**Valid until:** 2026-03-17 (stable Godot 4.x features, unlikely to change)
