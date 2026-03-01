# Phase 39: Tag-Targeted Currencies - Research

**Researched:** 2026-03-01
**Domain:** GDScript / Godot 4.5 — Currency system extension, drop table integration, forge UI expansion, toast notifications
**Confidence:** HIGH (all findings from direct source inspection)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Guaranteed Affix Logic**
- At least 1 matching-tag affix guaranteed (roll all 4-6 randomly, then if none matched, replace one with a matching affix)
- Tag matching uses existing `Tag.FIRE`, `Tag.DEFENSE`, etc. constants — an affix matches if its `tags` array contains the hammer's tag
- Tag hammers respect item tier's affix floor (e.g., tier 8 item + Fire Hammer = fire affix from T29-32 only)
- If no matching affix exists for the item+tag combo, block application entirely via `can_apply()` returning false — no currency consumed

**Drop Rates & Area Gating**
- All 5 tag hammer types unlock simultaneously at Prestige 1 (no progressive area unlock)
- Rare drop rate: 5-10% per pack (roughly 1 per 10-20 packs)
- Random equal chance among all 5 tag types when a drop occurs
- Drop quantity: mostly 1, small chance (10-20%) of 2 at higher areas

**Forge UI Layout**
- Tag hammer buttons in a separate section below standard hammers, visual separator (gap/line) between sections, no header text
- Section completely hidden before P1 (not grayed out, fully absent)
- Button labels: "Fire Hammer (3)" — name + count, matching existing standard hammer button style

**No-Valid-Mods Feedback**
- Reactive error: button stays clickable, shows toast/popup notification on failed click ("No fire-tagged mods available for this item")
- Auto-dismisses after 2-3 seconds
- Same Normal-rarity requirement as Forge Hammer — "already Rare" is a different reactive toast than "no valid mods"
- Both error types are reactive toasts, no preventive disabling

### Claude's Discretion
- Toast notification implementation (reuse existing system if one exists, or create minimal one)
- Exact drop rate within 5-10% range
- Exact chance threshold for quantity 2 drops
- Visual separator style between standard and tag hammer sections

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| TAG-01 | Fire Hammer transforms Normal item to Rare, guaranteeing at least one fire-tagged affix | TagHammer GDScript class with `can_apply()` + `_do_apply()` override; tag filter on `add_prefix/add_suffix`; guarantee step post-roll |
| TAG-02 | Cold Hammer transforms Normal item to Rare, guaranteeing at least one cold-tagged affix | Same class pattern, `Tag.COLD` constant |
| TAG-03 | Lightning Hammer transforms Normal item to Rare, guaranteeing at least one lightning-tagged affix | Same class pattern, `Tag.LIGHTNING` constant |
| TAG-04 | Defense Hammer transforms Normal item to Rare, guaranteeing at least one defense-tagged affix | Same class pattern, `Tag.DEFENSE` constant |
| TAG-05 | Physical Hammer transforms Normal item to Rare, guaranteeing at least one physical-tagged affix | Same class pattern, `Tag.PHYSICAL` constant |
| TAG-06 | Tag hammers show "no valid mods" feedback when no matching affixes are available | `save_toast.gd` shows `show_toast()` pattern; reuse for inline error toasts in forge_view |
| TAG-07 | Tag hammers are only available after Prestige 1 | `GameState.prestige_level >= 1` gate; `hide()` on `TagHammerSection` node in `forge_view.gd` |
| TAG-08 | Tag hammer currencies drop from packs after reaching Prestige 1 | `LootTable.roll_pack_currency_drop()` extension; `GameEvents.tag_currency_dropped` signal already declared |
</phase_requirements>

---

## Summary

Phase 39 adds five tag hammer currencies (Fire, Cold, Lightning, Defense, Physical) that transform Normal items to Rare with at least one guaranteed matching-tag affix. The codebase already has every scaffold needed: `GameState.tag_currency_counts` initialized and saved, `GameEvents.tag_currency_dropped` signal declared, `PrestigeManager.TAG_TYPES` and `_grant_random_tag_currency()` implemented, and `SaveManager` already serializes/deserializes tag currencies. The work in this phase is connecting these stubs into working game features.

The critical discovery from source analysis is the **tag hammer applicability matrix**: Fire, Cold, and Lightning hammers are blocked on armor, helmet, and boots (those item types have no elemental tag affixes). Defense Hammer works on all five item types. Physical Hammer is blocked on armor, helmet, and boots. This means `can_apply()` must check tag availability against both the item's `valid_tags` AND the hammer's target tag before returning true. The "no valid mods" toast path will be triggered frequently by players trying elemental hammers on armor pieces — getting this feedback right is important.

The toast notification system already exists in `save_toast.gd` as a `show_toast(message, color)` method. For forge error messages, the planner should either wire forge_view.gd to call the existing save_toast node, or add a second inline toast control to forge_view — the decision is at Claude's discretion.

**Primary recommendation:** Implement `TagHammer` as a single parameterized class (takes a `tag_name: String` in `_init`), add all five instances to `forge_view.gd`'s `currencies` dict and a new `tag_hammer_section` VBoxContainer (hidden before P1), extend `LootTable.roll_pack_currency_drop()` with a single P1-gated tag roll block that picks one of 5 types, and handle tag currency spend/add with two new helpers on `GameState`.

---

## Standard Stack

### Core
| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| `Currency` base class | existing | Template method: `can_apply()` / `_do_apply()` | All currency types extend this |
| `ForgeHammer` | existing | Normal→Rare with 4-6 mods | Tag hammers are ForgeHammer + guaranteed-tag constraint |
| `GameState.tag_currency_counts` | existing | Per-type inventory dict | Already initialized, saved, wiped on prestige |
| `ItemAffixes.from_affix()` | existing | Creates affix with tier floor applied | Already respects `_get_affix_tier_floor()` |
| `LootTable` static class | existing | All pack currency drop logic lives here | Consistent with all other currency drops |
| `save_toast.gd` | existing | `show_toast(msg, color)` — Label + Tween pattern | Reuse for forge error messages |

### Supporting
| Component | Purpose | When to Use |
|-----------|---------|-------------|
| `PrestigeManager.TAG_TYPES` | Canonical list of 5 tag strings | Source of truth for drop type selection |
| `GameEvents.tag_currency_dropped` | Signal for tag currency drop events | Emit alongside `GameEvents.currency_dropped` |
| `Tag.FIRE`, `Tag.COLD`, `Tag.LIGHTNING`, `Tag.DEFENSE`, `Tag.PHYSICAL` | Tag constants for matching | Use these exact strings; they match affix `.tags` arrays |

---

## Architecture Patterns

### Recommended File Structure
```
models/currencies/
  tag_hammer.gd          # Single class, parameterized by tag_name
autoloads/
  game_state.gd          # Add spend_tag_currency() + add_tag_currencies() helpers
  loot_table.gd          # Add tag hammer drop logic
scenes/
  forge_view.gd          # Add tag section node refs + button wiring
  forge_view.tscn        # Add TagHammerSection VBoxContainer + 5 buttons
```

### Pattern 1: Single Parameterized TagHammer Class
**What:** One `TagHammer` class that accepts a `tag_name` string at init. All five tag hammers are instances of this class.
**When to use:** All tag hammers share identical logic except the tag they filter on.

```gdscript
# models/currencies/tag_hammer.gd
class_name TagHammer extends Currency

var tag_name: String  # e.g. "FIRE"


func _init(p_tag_name: String) -> void:
    tag_name = p_tag_name
    currency_name = p_tag_name.capitalize() + " Hammer"


func can_apply(item: Item) -> bool:
    if item.rarity != Item.Rarity.NORMAL:
        return false
    return _has_matching_affixes(item)


func get_error_message(item: Item) -> String:
    if item.rarity != Item.Rarity.NORMAL:
        return currency_name + " can only be used on Normal items"
    if not _has_matching_affixes(item):
        return "No " + tag_name.to_lower() + "-tagged mods available for this item"
    return ""


func _do_apply(item: Item) -> void:
    item.rarity = Item.Rarity.RARE

    var mod_count := randi_range(4, 6)
    for i in range(mod_count):
        var choose_prefix := randi_range(0, 1) == 0
        if choose_prefix:
            if not item.add_prefix():
                if not item.add_suffix():
                    break
        else:
            if not item.add_suffix():
                if not item.add_prefix():
                    break

    # Guarantee: if no matching-tag affix landed, replace slot[0] prefix or suffix
    _guarantee_tag_affix(item)

    item.update_value()


func _has_matching_affixes(item: Item) -> bool:
    # Check if any prefix or suffix valid for this item also has our tag
    for prefix in ItemAffixes.prefixes:
        if item.has_valid_tag(prefix) and tag_name in prefix.tags:
            return true
    for suffix in ItemAffixes.suffixes:
        if item.has_valid_tag(suffix) and tag_name in suffix.tags:
            return true
    return false


func _guarantee_tag_affix(item: Item) -> void:
    # Check if any existing affix already has the tag
    for affix in item.prefixes + item.suffixes:
        if tag_name in affix.tags:
            return  # Already satisfied

    # None found — build candidate pool (valid for item AND has our tag)
    var floor_val := item._get_affix_tier_floor()

    var tag_prefixes: Array[Affix] = []
    for template in ItemAffixes.prefixes:
        if item.has_valid_tag(template) and tag_name in template.tags:
            tag_prefixes.append(Affixes.from_affix(template, floor_val))

    var tag_suffixes: Array[Affix] = []
    for template in ItemAffixes.suffixes:
        if item.has_valid_tag(template) and tag_name in template.tags:
            tag_suffixes.append(Affixes.from_affix(template, floor_val))

    # Replace: prefer prefix slot if candidates exist, else suffix slot
    if not tag_prefixes.is_empty() and not item.prefixes.is_empty():
        item.prefixes[0] = tag_prefixes.pick_random()
    elif not tag_suffixes.is_empty() and not item.suffixes.is_empty():
        item.suffixes[0] = tag_suffixes.pick_random()
```

### Pattern 2: Tag Currency Spend/Add in GameState
**What:** Two helpers on `GameState` mirroring `spend_currency()` and `add_currencies()` but operating on `tag_currency_counts`.
**When to use:** All forge_view tag currency spending and drop-system additions.

```gdscript
# In autoloads/game_state.gd — add these two functions:

func spend_tag_currency(tag_type: String) -> bool:
    if tag_type not in tag_currency_counts:
        return false
    if tag_currency_counts[tag_type] <= 0:
        return false
    tag_currency_counts[tag_type] -= 1
    return true


func add_tag_currencies(drops: Dictionary) -> void:
    for tag_type in drops:
        if tag_type not in tag_currency_counts:
            tag_currency_counts[tag_type] = 0
        tag_currency_counts[tag_type] += drops[tag_type]
```

### Pattern 3: LootTable Tag Drop Extension
**What:** Add a single block inside `roll_pack_currency_drop()` after the standard currency loop that, when P1 is reached, rolls for one tag hammer type.
**When to use:** P1-gated, quantity 1 mostly (10-20% chance of 2).

```gdscript
# In models/loot/loot_table.gd — extend roll_pack_currency_drop():
# Add after the standard currency loop:

# Tag hammer drops — gated at prestige_level >= 1
# (Cannot read prestige_level directly in static; pass it as param or use GameState)
if GameState.prestige_level >= 1:
    var tag_drop_chance: float = 0.07 * pack_difficulty_bonus  # 7% — midpoint of 5-10%
    if randf() < tag_drop_chance:
        var tag_type: String = PrestigeManager.TAG_TYPES.pick_random()
        var qty: int = 1
        if randf() < 0.15:  # 15% chance of 2 (midpoint of 10-20%)
            qty = 2
        var tag_drops: Dictionary = {tag_type: qty}
        GameState.add_tag_currencies(tag_drops)
        GameEvents.tag_currency_dropped.emit(tag_drops)
```

**Note on static vs instance:** `LootTable` uses `static func roll_pack_currency_drop()`. Accessing `GameState` from a static func in Godot 4 works because autoloads are global singletons — `GameState.prestige_level` is valid inside a static func.

### Pattern 4: Forge UI Tag Section
**What:** A `VBoxContainer` (or `ColorRect` + children) added below `TuningHammerBtn` in `forge_view.tscn`. In `forge_view.gd`, shown/hidden based on `GameState.prestige_level >= 1`.
**When to use:** `_ready()` and any time prestige state changes.

```gdscript
# In forge_view.gd:
@onready var tag_hammer_section: Control = $HammerSidebar/TagHammerSection
@onready var fire_hammer_btn: Button = $HammerSidebar/TagHammerSection/FireHammerBtn
@onready var cold_hammer_btn: Button = $HammerSidebar/TagHammerSection/ColdHammerBtn
@onready var lightning_hammer_btn: Button = $HammerSidebar/TagHammerSection/LightningHammerBtn
@onready var defense_hammer_btn: Button = $HammerSidebar/TagHammerSection/DefenseHammerBtn
@onready var physical_hammer_btn: Button = $HammerSidebar/TagHammerSection/PhysicalHammerBtn

var tag_currencies: Dictionary = {
    "fire": TagHammer.new("FIRE"),
    "cold": TagHammer.new("COLD"),
    "lightning": TagHammer.new("LIGHTNING"),
    "defense": TagHammer.new("DEFENSE"),
    "physical": TagHammer.new("PHYSICAL"),
}
var tag_currency_buttons: Dictionary = {}  # populated in _ready()

func _ready() -> void:
    # ... existing setup ...
    tag_currency_buttons = {
        "fire": fire_hammer_btn,
        "cold": cold_hammer_btn,
        "lightning": lightning_hammer_btn,
        "defense": defense_hammer_btn,
        "physical": physical_hammer_btn,
    }
    for tag_type in tag_currency_buttons:
        tag_currency_buttons[tag_type].pressed.connect(_on_tag_currency_selected.bind(tag_type))

    # Show/hide tag section based on prestige
    tag_hammer_section.visible = (GameState.prestige_level >= 1)

    # Connect prestige signal to reveal section
    GameEvents.prestige_completed.connect(_on_prestige_completed)
```

### Pattern 5: Toast Error Feedback
**What:** Reuse `save_toast.gd`'s `show_toast()` method OR add a second `Label` node in forge_view that mimics the same Tween pattern.
**Decision area (Claude's discretion):** The existing save_toast is in `main.tscn`'s node tree. To call it from `forge_view.gd`, either:
- Option A: Expose `SaveToast` as an autoload (invasive change)
- Option B: Add a second `Label` node directly to `forge_view.tscn` with the same Tween pattern (localized, minimal)
- **Recommend Option B**: A `ForgeErrorToast` Label in `forge_view.tscn` with a `show_forge_error(msg)` helper in `forge_view.gd`.

```gdscript
# In forge_view.gd:
@onready var forge_error_toast: Label = $ForgeErrorToast

func show_forge_error(message: String) -> void:
    forge_error_toast.text = message
    forge_error_toast.modulate = Color(1.0, 0.4, 0.4, 1.0)  # Red for error
    forge_error_toast.visible = true
    var tween := create_tween()
    tween.tween_interval(2.0)       # Hold 2 seconds
    tween.tween_property(forge_error_toast, "modulate:a", 0.0, 0.5)
    tween.tween_callback(func(): forge_error_toast.visible = false)
```

### Pattern 6: forge_view Tag Currency Application
**What:** The existing `update_item()` function dispatches by `selected_currency_type`. Tag currencies need a parallel path that calls `spend_tag_currency()` instead of `spend_currency()`.

```gdscript
func _on_tag_currency_selected(tag_type: String) -> void:
    var button := tag_currency_buttons[tag_type]
    if button.button_pressed:
        selected_currency = tag_currencies[tag_type]
        selected_currency_type = "tag_" + tag_type  # Prefix to distinguish from standard
        # Deselect all other buttons
        for other in currency_buttons:
            currency_buttons[other].button_pressed = false
        for other in tag_currency_buttons:
            if other != tag_type:
                tag_currency_buttons[other].button_pressed = false
    else:
        selected_currency = null
        selected_currency_type = ""

# Modify update_item() to detect tag currency:
func update_item(event: InputEvent) -> void:
    # ... existing guards ...
    if not selected_currency.can_apply(current_item):
        show_forge_error(selected_currency.get_error_message(current_item))
        return

    var spent: bool
    if selected_currency_type.begins_with("tag_"):
        var tag_key := selected_currency_type.substr(4)  # strip "tag_"
        spent = GameState.spend_tag_currency(tag_key)
    else:
        spent = GameState.spend_currency(selected_currency_type)

    if not spent:
        show_forge_error("No " + selected_currency.currency_name + " remaining!")
        return

    selected_currency.apply(current_item)
    update_item_stats_display()
    update_currency_button_states()
    update_tag_currency_button_states()
```

### Anti-Patterns to Avoid
- **Calling `apply()` before `can_apply()`** in forge_view for tag currencies: The base `Currency.apply()` already calls `can_apply()` internally, but forge_view checks it explicitly first to show an error message — maintain this pattern.
- **Merging tag_currency_counts into currency_counts**: State.md decision: they stay separate. Don't unify them.
- **Disabling tag hammer buttons preventively**: Locked decision says buttons stay clickable; show toast on failed click. Do not `button.disabled = (count <= 0)` for tag buttons when the issue is "no valid mods" — only disable for zero-count.
- **Calling `initialize_fresh_game()` instead of `_wipe_run_state()`**: Already handled by PrestigeManager, but don't replicate the prestige path incorrectly.
- **Using `static func` for drop logic that references `GameState`**: Works in Godot 4 since autoloads are global, but avoid adding GameState reads inside `_calculate_currency_chance()` (keep that pure). Only add GameState.prestige_level read in `roll_pack_currency_drop()` directly.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Affix tier floor on guaranteed affix | Custom tier range calculation | `Affixes.from_affix(template, floor_val)` | Already handles `max(template.tier_range.x, floor)` correctly |
| Tag-affix availability check | Custom iteration with string comparisons | `item.has_valid_tag(affix)` + check `tag_name in affix.tags` | `has_valid_tag` already checks item's valid_tags against affix.tags |
| Tag currency persistence | New save fields | `GameState.tag_currency_counts` + `SaveManager` | Already serialized in `_build_save_data()` / `_restore_state()` |
| Prestige-gated UI visibility | Custom prestige level check per button | `tag_hammer_section.visible = (GameState.prestige_level >= 1)` | One node hide/show covers all 5 buttons |
| Toast notifications | Custom dialog/popup system | Tween-based Label (same as `save_toast.gd`) | Already proven pattern in the codebase |

---

## Common Pitfalls

### Pitfall 1: Tag Hammer Blocked on Wrong Item Types
**What goes wrong:** Player clicks Fire Hammer on a BasicArmor and expects a fire-tagged affix. BasicArmor has `valid_tags = [DEFENSE, ARMOR, ENERGY_SHIELD]` — none of these match FIRE in any affix's tag list. The application must be blocked entirely.
**Why it happens:** The tag matching is two-dimensional: affix must be valid FOR the item type AND contain the hammer's tag. Checking only the hammer tag without the item's valid_tags allows non-existent affixes.
**How to avoid:** `_has_matching_affixes()` must cross-check BOTH `item.has_valid_tag(affix)` AND `tag_name in affix.tags`. The analysis table below documents exactly which hammers are blocked per slot.
**Warning signs:** Test each of the 25 combinations (5 hammers × 5 item types) in the verification phase.

**CRITICAL APPLICABILITY MATRIX (from source analysis):**

| Hammer | LightSword | BasicArmor | BasicHelmet | BasicBoots | BasicRing |
|--------|-----------|------------|-------------|------------|-----------|
| Fire | YES (1 pfx) | BLOCKED | BLOCKED | BLOCKED | YES (1 pfx) |
| Cold | YES (1 pfx) | BLOCKED | BLOCKED | BLOCKED | YES (1 pfx) |
| Lightning | YES (1 pfx) | BLOCKED | BLOCKED | BLOCKED | YES (1 pfx) |
| Defense | YES (6 sfx) | YES (15) | YES (15) | YES (15) | YES (6 sfx) |
| Physical | YES (2 pfx) | BLOCKED | BLOCKED | BLOCKED | YES (2 pfx) |

**Note on Defense + Weapon:** Defense Hammer can apply to LightSword/BasicRing because those items have `Tag.DEFENSE` in their valid_tags via weapon suffixes (Life, Armor, Fire/Cold/Lightning Resistance all have `[Tag.DEFENSE, Tag.WEAPON]` tags, and the item's `Tag.WEAPON` or `Tag.ATTACK` valid tag intersects with `Tag.WEAPON` in the suffix).

Wait — re-examining: The Defense Hammer checks `tag_name in affix.tags` where tag_name = "DEFENSE". Looking at the suffix affixes: `Life`, `Armor`, `Fire Resistance`, etc. all have `[Tag.DEFENSE, Tag.WEAPON]`. The item's `has_valid_tag(affix)` checks if any of the item's `valid_tags` appears in `affix.tags`. For LightSword with `valid_tags = [PHYSICAL, ATTACK, CRITICAL, WEAPON]`, `WEAPON` is in affix.tags `[DEFENSE, WEAPON]` → match. AND `DEFENSE` is in affix.tags → Defense Hammer match. So Defense Hammer DOES work on LightSword/BasicRing via weapon-tagged suffixes.

### Pitfall 2: "No valid mods" vs "already Rare" Error Messages
**What goes wrong:** Both error states show a toast but must have different messages. Using `get_error_message()` uniformly handles this since `TagHammer.get_error_message()` checks rarity first.
**Why it happens:** `can_apply()` returns `false` for two distinct reasons. The caller (forge_view) must distinguish them for the error message — use `get_error_message()` which handles ordering.
**How to avoid:** Always call `get_error_message(current_item)` and pass its result to `show_forge_error()`. Never hardcode the message in forge_view.

### Pitfall 3: Tag Section Visibility Not Updating After Prestige
**What goes wrong:** Tag hammer section remains hidden if prestige completes while forge_view is open.
**Why it happens:** `_ready()` sets visibility once; `prestige_completed` signal fires during gameplay but forge_view may still be active.
**How to avoid:** Connect `GameEvents.prestige_completed` in forge_view._ready() and call `tag_hammer_section.visible = true` in the handler.

### Pitfall 4: Deselection Logic for Mixed Button Sets
**What goes wrong:** Player selects a standard hammer, then a tag hammer — the standard hammer button remains visually toggled.
**Why it happens:** The existing `_on_currency_selected` only iterates `currency_buttons` when deselecting; it doesn't know about `tag_currency_buttons`.
**How to avoid:** In `_on_tag_currency_selected`, deselect all `currency_buttons` too. In `_on_currency_selected`, deselect all `tag_currency_buttons` too. Both button maps must be cross-deselected.

### Pitfall 5: `_guarantee_tag_affix` Replacing Wrong Slot
**What goes wrong:** The guarantee step picks a random tag-affix but finds the item has 0 prefixes (all rolls went to suffixes), then tries `item.prefixes[0]` and crashes.
**Why it happens:** Random mod rolling might produce 0 prefixes + 4-6 suffixes or vice versa.
**How to avoid:** Check slot is non-empty before replacing: prefer prefix if tag candidates exist AND item.prefixes is non-empty; else suffix if non-empty. If both are empty (shouldn't happen but guard), skip replacement.

### Pitfall 6: Static Function GameState Access
**What goes wrong:** Accessing `GameState.prestige_level` from the static `LootTable.roll_pack_currency_drop()` fails with "Cannot access non-static member" — but it won't, because GameState is a Node autoload, not a class method.
**Why it happens:** Confusion between static class methods (which can't access `self`) and autoload singletons (which are globally accessible).
**How to avoid:** `GameState` (the autoload node singleton) is always accessible anywhere in GDScript, even from `static func`. Confirmed by the existing pattern where `static func roll_item_tier()` could be called with `GameState.area_level` from outside. This is safe.

---

## Code Examples

### Checking Tag Availability (Critical Correct Pattern)
```gdscript
# Correct: cross-checks item validity AND tag presence
func _has_matching_affixes(item: Item) -> bool:
    for prefix in ItemAffixes.prefixes:
        if item.has_valid_tag(prefix) and tag_name in prefix.tags:
            return true
    for suffix in ItemAffixes.suffixes:
        if item.has_valid_tag(suffix) and tag_name in suffix.tags:
            return true
    return false

# item.has_valid_tag() from item.gd (line 216-220):
# func has_valid_tag(affix: Affix) -> bool:
#     for tag in self.valid_tags:
#         if tag in affix.tags:
#             return true
#     return false
```

### Forge View Tag Currency Update
```gdscript
func update_tag_currency_button_states() -> void:
    tag_hammer_section.visible = (GameState.prestige_level >= 1)
    for tag_type in tag_currency_buttons:
        var count: int = GameState.tag_currency_counts.get(tag_type, 0)
        var button: Button = tag_currency_buttons[tag_type]
        button.disabled = (count <= 0)
        button.text = tag_currencies[tag_type].currency_name + " (" + str(count) + ")"
    # Deselect if selected tag currency hits 0
    if selected_currency_type.begins_with("tag_"):
        var key := selected_currency_type.substr(4)
        if GameState.tag_currency_counts.get(key, 0) <= 0:
            selected_currency = null
            selected_currency_type = ""
            for btn in tag_currency_buttons.values():
                btn.button_pressed = false
```

### forge_view.gd `_on_tag_currency_dropped` Handler
```gdscript
func on_tag_currencies_found(drops: Dictionary) -> void:
    # Called from main_view when tag_currency_dropped fires
    update_tag_currency_button_states()
```

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|-----------------|--------|
| Hardcoded currency types in `currencies` dict | Parameterized `TagHammer` class | 5 tag hammers = 1 class, not 5 files |
| Direct `spend_currency()` for all currencies | `spend_tag_currency()` for tag types | Keeps tag counts separate from standard counts |
| Single currency loop in `roll_pack_currency_drop()` | Extended loop with P1-gated tag block | Consistent with existing gate pattern |

**No deprecated patterns apply** — this phase only adds new code to existing extension points.

---

## Open Questions

1. **main_view.gd wiring for tag_currency_dropped signal**
   - What we know: `gameplay_view.gd` handles `currency_dropped` and emits `currencies_found` to `forge_view`. The `tag_currency_dropped` signal exists in GameEvents but is not yet connected anywhere.
   - What's unclear: Whether main_view.gd routes tag currency to forge_view the same way, or if forge_view listens to GameEvents directly.
   - Recommendation: Read `main_view.gd` during planning. Most likely: add `GameEvents.tag_currency_dropped.connect(_on_tag_currency_dropped)` directly in `forge_view._ready()` to avoid adding another signal relay hop.

2. **forge_view.tscn pixel coordinates for tag section**
   - What we know: Standard buttons end at `offset_bottom = 230` (TuningHammerBtn). InventoryLabel starts at `offset_top = 260`. HammerSidebar is 650px tall total.
   - What's unclear: Optimal layout — 5 tag buttons need ~75px each = 375px total which overflows the 260-650 range (390px). May need smaller buttons or a 2-column layout matching existing standard buttons.
   - Recommendation: Use same 2-column layout as existing (pairs: Fire/Cold, Lightning/Defense, Physical centered), at ~65px height each = 3 rows = ~195px. Fits within available 390px including separator gap.

---

## Sources

### Primary (HIGH confidence)
- `/c/Users/vince/Documents/GitHub/hammertime/.claude/worktrees/suspicious-sinoussi/models/currencies/forge_hammer.gd` — ForgeHammer implementation template
- `/c/Users/vince/Documents/GitHub/hammertime/.claude/worktrees/suspicious-sinoussi/models/currencies/currency.gd` — Currency base class template method
- `/c/Users/vince/Documents/GitHub/hammertime/.claude/worktrees/suspicious-sinoussi/autoloads/game_state.gd` — tag_currency_counts, spend_currency, add_currencies patterns
- `/c/Users/vince/Documents/GitHub/hammertime/.claude/worktrees/suspicious-sinoussi/autoloads/prestige_manager.gd` — TAG_TYPES, _grant_random_tag_currency
- `/c/Users/vince/Documents/GitHub/hammertime/.claude/worktrees/suspicious-sinoussi/autoloads/game_events.gd` — tag_currency_dropped signal
- `/c/Users/vince/Documents/GitHub/hammertime/.claude/worktrees/suspicious-sinoussi/autoloads/item_affixes.gd` — full affix pool with tags
- `/c/Users/vince/Documents/GitHub/hammertime/.claude/worktrees/suspicious-sinoussi/autoloads/tag.gd` — Tag constants (FIRE, COLD, LIGHTNING, DEFENSE, PHYSICAL)
- `/c/Users/vince/Documents/GitHub/hammertime/.claude/worktrees/suspicious-sinoussi/models/items/item.gd` — has_valid_tag(), _get_affix_tier_floor(), add_prefix/add_suffix
- `/c/Users/vince/Documents/GitHub/hammertime/.claude/worktrees/suspicious-sinoussi/models/items/basic_*.gd` — all 5 item type valid_tags arrays
- `/c/Users/vince/Documents/GitHub/hammertime/.claude/worktrees/suspicious-sinoussi/models/loot/loot_table.gd` — roll_pack_currency_drop, _calculate_currency_chance
- `/c/Users/vince/Documents/GitHub/hammertime/.claude/worktrees/suspicious-sinoussi/scenes/forge_view.gd` — full forge UI pattern (currencies dict, button wiring, update_currency_button_states)
- `/c/Users/vince/Documents/GitHub/hammertime/.claude/worktrees/suspicious-sinoussi/scenes/forge_view.tscn` — node layout and button positions
- `/c/Users/vince/Documents/GitHub/hammertime/.claude/worktrees/suspicious-sinoussi/scenes/save_toast.gd` — show_toast pattern (reuse for forge errors)
- `/c/Users/vince/Documents/GitHub/hammertime/.claude/worktrees/suspicious-sinoussi/autoloads/save_manager.gd` — confirmed tag_currency_counts already serialized/deserialized
- `/c/Users/vince/Documents/GitHub/hammertime/.claude/worktrees/suspicious-sinoussi/models/combat/combat_engine.gd` — _on_pack_killed drop emission sequence
- `/c/Users/vince/Documents/GitHub/hammertime/.claude/worktrees/suspicious-sinoussi/scenes/gameplay_view.gd` — _on_currency_dropped handler (for main_view wiring reference)
- Node.js analysis script (inline) — confirmed exact applicability matrix for all 25 hammer×item combinations

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all components inspected directly from source files
- Architecture patterns: HIGH — patterns derived directly from existing code structures
- Applicability matrix: HIGH — computed programmatically from actual affix tag arrays and item valid_tags
- Pitfalls: HIGH — derived from actual code structure (static/autoload, slot indexing, button state management)

**Research date:** 2026-03-01
**Valid until:** 2026-04-01 (stable codebase — no external dependencies)
