# Phase 39: Tag-Targeted Currencies - Research

**Researched:** 2026-03-01
**Domain:** GDScript / Godot 4 — currency class hierarchy, forge UI wiring, loot table drop integration
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Guaranteed Affix Logic**
- At least 1 matching-tag affix guaranteed (roll all 4-6 randomly, then if none matched, replace one with a matching affix)
- Tag matching uses existing `Tag.FIRE`, `Tag.DEFENSE`, etc. constants — an affix matches if its `tags` array contains the hammer's tag
- Tag hammers respect item tier's affix floor (e.g., tier 8 item + Fire Hammer = fire affix from T29-32 only)
- If no matching affix exists for the item+tag combo, block application entirely via `can_apply()` returning false — no currency consumed

**Affix Tag Corrections (pre-phase prep)**
- %Fire Damage, %Cold Damage, %Lightning Damage: added their specific element tags (were only ELEMENTAL)
- %Elemental Damage: stays ELEMENTAL only (generic, no specific element hammer matches it)
- Fire/Cold/Lightning Resistance: added matching element tags
- All Resistances: stays `[DEFENSE, WEAPON]` only — no element tags (generic defensive)
- Flat Armor, %Armor (prefix), Armor (suffix): added `Tag.PHYSICAL`
- Attack Speed: added `Tag.PHYSICAL` (physical attacks use speed)
- Evasion: stays `[DEFENSE, EVASION]` only — no PHYSICAL (evasion is generic defense)
- Crit Chance, Crit Damage: no PHYSICAL added (spells can crit too)

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
| TAG-01 | Fire Hammer transforms Normal item to Rare, guaranteeing at least one fire-tagged affix | `ForgeHammer._do_apply()` is the template; affix tag-filter logic uses `affix.tags` array; `Affixes.from_affix()` applies tier floor |
| TAG-02 | Cold Hammer transforms Normal item to Rare, guaranteeing at least one cold-tagged affix | Same pattern as TAG-01 with `Tag.COLD` constant |
| TAG-03 | Lightning Hammer transforms Normal item to Rare, guaranteeing at least one lightning-tagged affix | Same pattern as TAG-01 with `Tag.LIGHTNING` constant |
| TAG-04 | Defense Hammer transforms Normal item to Rare, guaranteeing at least one defense-tagged affix | Same pattern as TAG-01 with `Tag.DEFENSE` constant |
| TAG-05 | Physical Hammer transforms Normal item to Rare, guaranteeing at least one physical-tagged affix | Same pattern as TAG-01 with `Tag.PHYSICAL` constant |
| TAG-06 | Tag hammers show "no valid mods" feedback when no matching affixes are available | `save_toast.gd` has a reusable `show_toast()` pattern; needs a toast node in `forge_view.tscn` |
| TAG-07 | Tag hammers are only available after Prestige 1 | `GameState.prestige_level` controls visibility of the tag hammer container node in scene |
| TAG-08 | Tag hammer currencies drop from packs after reaching Prestige 1 | `LootTable.roll_pack_currency_drop()` is extended; `GameEvents.tag_currency_dropped` signal already exists; `combat_engine.gd` `_on_pack_killed()` is the integration point |
</phase_requirements>

---

## Summary

Phase 39 implements five tag hammers (Fire, Cold, Lightning, Defense, Physical) as Prestige 1 post-gate currencies. All infrastructure is already in place: `tag_currency_counts` exists on `GameState`, `tag_currency_dropped` signal exists on `GameEvents`, `SaveManager` already serializes/deserializes tag currencies, and `PrestigeManager` already has `TAG_TYPES` and `_grant_random_tag_currency()`. The work is additive: create 5 new currency classes, extend the loot table drop path, wire 5 new buttons in `forge_view.gd` and `forge_view.tscn`, and add a toast notification for error feedback.

The most technically interesting piece is the guaranteed-tag affix logic in `_do_apply()`. The decision is: roll 4-6 affixes normally (reusing `Item.add_prefix()` / `add_suffix()`), then check if any rolled affix matches the hammer's tag. If none does, pick one of the rolled affixes at random and replace it with a tag-matching affix (chosen from the valid pool for this item slot + tier floor, filtered further to only those with the hammer's tag).

The toast system does not yet exist in `forge_view` — `save_toast.gd` is a Label-based toast that lives on the main scene, not inside the forge view. The simplest approach is to add a Label node directly inside `forge_view.tscn` and implement the same tween-based fade pattern that `save_toast.gd` uses. Reusing `save_toast.gd` is not appropriate because it is wired to save-specific signals; a local forge toast Label is the correct minimal implementation.

**Primary recommendation:** Create a single `TagHammer` base class parameterized by `tag` and `display_name`; instantiate five instances. All five share identical logic — only the `tag` constant differs.

---

## Standard Stack

### Core
| Component | File | Purpose | Status |
|-----------|------|---------|--------|
| Currency base class | `models/currencies/currency.gd` | `can_apply()` / `_do_apply()` template method | Already exists |
| ForgeHammer | `models/currencies/forge_hammer.gd` | Normal→Rare, 4-6 mods logic | Already exists — template for tag hammers |
| GameState.tag_currency_counts | `autoloads/game_state.gd` | Tag currency inventory dict | Already exists and initialized |
| GameEvents.tag_currency_dropped | `autoloads/game_events.gd` | Drop signal | Already declared |
| SaveManager | `autoloads/save_manager.gd` | tag_currency_counts serialized in v4 | Already complete |
| PrestigeManager.TAG_TYPES | `autoloads/prestige_manager.gd` | ["fire","cold","lightning","defense","physical"] | Already exists |
| LootTable.roll_pack_currency_drop() | `models/loot/loot_table.gd` | Per-pack drop roller | Needs tag drop extension |
| forge_view.gd | `scenes/forge_view.gd` | Currency button wiring | Needs 5 new buttons + tag spend logic |
| forge_view.tscn | `scenes/forge_view.tscn` | Scene nodes | Needs TagHammerSection container + 5 buttons + separator + toast label |

### New Files Needed
| File | Purpose |
|------|---------|
| `models/currencies/tag_hammer.gd` | Single parameterized class for all 5 tag hammer types |

---

## Architecture Patterns

### Recommended File Structure
```
models/currencies/
├── currency.gd          # Base (unchanged)
├── forge_hammer.gd      # Normal→Rare (unchanged — tag hammer copies its logic)
└── tag_hammer.gd        # NEW: parameterized tag hammer (handles all 5 types)
```

### Pattern 1: Parameterized Currency Class

All 5 tag hammers share identical logic. The only difference is which tag constant they target and what display name they use. Use a single class with constructor parameters instead of 5 separate files.

```gdscript
# models/currencies/tag_hammer.gd
class_name TagHammer extends Currency

var required_tag: String  # e.g. Tag.FIRE

func _init(p_tag: String, p_name: String) -> void:
    required_tag = p_tag
    currency_name = p_name


func can_apply(item: Item) -> bool:
    if item.rarity != Item.Rarity.NORMAL:
        return false
    # Check there is at least one valid affix (prefix or suffix) with the required tag
    return _has_any_matching_affix(item)


func get_error_message(item: Item) -> String:
    if item.rarity != Item.Rarity.NORMAL:
        return currency_name + " can only be used on Normal items"
    if not _has_any_matching_affix(item):
        return "No " + required_tag.to_lower() + "-tagged mods available for this item"
    return ""


func _do_apply(item: Item) -> void:
    item.rarity = Item.Rarity.RARE

    # Roll 4-6 affixes normally (reuses item's existing add_prefix/add_suffix)
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

    # Guarantee: if no rolled affix has required_tag, replace one with a matching affix
    if not _has_matching_affix_on_item(item):
        _replace_random_affix_with_tagged(item)

    item.update_value()


func _has_any_matching_affix(item: Item) -> bool:
    var floor_val := item._get_affix_tier_floor()
    for prefix in ItemAffixes.prefixes:
        if required_tag in prefix.tags and item.has_valid_tag(prefix):
            return true
    for suffix in ItemAffixes.suffixes:
        if required_tag in suffix.tags and item.has_valid_tag(suffix):
            return true
    return false


func _has_matching_affix_on_item(item: Item) -> bool:
    for affix in item.prefixes:
        if required_tag in affix.tags:
            return true
    for affix in item.suffixes:
        if required_tag in affix.tags:
            return true
    return false


func _replace_random_affix_with_tagged(item: Item) -> void:
    # Collect all affixes currently on item as candidates for replacement
    var all_affixes: Array[Affix] = []
    all_affixes.append_array(item.prefixes)
    all_affixes.append_array(item.suffixes)
    if all_affixes.is_empty():
        return

    # Find a valid tagged replacement (filter by item's valid_tags AND required_tag AND tier)
    var floor_val := item._get_affix_tier_floor()
    var tagged_pool: Array[Affix] = []
    for template in ItemAffixes.prefixes:
        if required_tag in template.tags and item.has_valid_tag(template) and not item.is_affix_on_item(template):
            tagged_pool.append(template)
    for template in ItemAffixes.suffixes:
        if required_tag in template.tags and item.has_valid_tag(template) and not item.is_affix_on_item(template):
            tagged_pool.append(template)

    if tagged_pool.is_empty():
        return  # can_apply() guards this — should not happen in practice

    var replacement_template: Affix = tagged_pool.pick_random()
    var replacement: Affix = Affixes.from_affix(replacement_template, floor_val)

    # Replace a random existing affix (respects prefix/suffix type)
    var victim: Affix = all_affixes.pick_random()
    if victim in item.prefixes:
        var idx := item.prefixes.find(victim)
        # Only replace with same type; if template is suffix, pick a suffix victim instead
        if replacement_template.is_prefix():
            item.prefixes[idx] = replacement
        else:
            # Replacement is a suffix but victim is a prefix — find a suffix victim instead
            if item.suffixes.is_empty():
                item.prefixes[idx] = replacement  # fallback
            else:
                var suffix_victim_idx := randi_range(0, item.suffixes.size() - 1)
                item.suffixes[suffix_victim_idx] = replacement
    else:
        var idx := item.suffixes.find(victim)
        if not replacement_template.is_prefix():
            item.suffixes[idx] = replacement
        else:
            # Replacement is a prefix but victim is a suffix — find a prefix victim instead
            if item.prefixes.is_empty():
                item.suffixes[idx] = replacement  # fallback
            else:
                var prefix_victim_idx := randi_range(0, item.prefixes.size() - 1)
                item.prefixes[prefix_victim_idx] = replacement
```

### Pattern 2: Forge View — Tag Currency Spend Path

The existing `update_item()` handler in `forge_view.gd` calls `GameState.spend_currency(selected_currency_type)` which only looks in `currency_counts`. Tag currencies live in `tag_currency_counts`. The handler must be extended to check the right dictionary:

```gdscript
# In forge_view.gd update_item() — replace the spend_currency call with:
func _spend_selected_currency() -> bool:
    if selected_currency_type in GameState.currency_counts:
        return GameState.spend_currency(selected_currency_type)
    # Tag currency path
    var count: int = GameState.tag_currency_counts.get(selected_currency_type, 0)
    if count <= 0:
        return false
    GameState.tag_currency_counts[selected_currency_type] -= 1
    return true
```

Alternatively, add `spend_tag_currency(type)` to `GameState` following the existing `spend_currency()` pattern. Either approach works; adding it to `GameState` is cleaner separation.

### Pattern 3: Tag Hammer Buttons — Wiring in forge_view.gd

Five new buttons follow the exact same pattern as standard hammer buttons. The `currencies` dict and `currency_buttons` dict both get 5 new entries:

```gdscript
# In forge_view.gd (additions to existing dictionaries)
var currencies: Dictionary = {
    # ... existing 6 entries ...
    "fire": TagHammer.new(Tag.FIRE, "Fire Hammer"),
    "cold": TagHammer.new(Tag.COLD, "Cold Hammer"),
    "lightning": TagHammer.new(Tag.LIGHTNING, "Lightning Hammer"),
    "defense": TagHammer.new(Tag.DEFENSE, "Defense Hammer"),
    "physical": TagHammer.new(Tag.PHYSICAL, "Physical Hammer"),
}
```

### Pattern 4: Prestige 1 Gate — Container Visibility

The tag hammer buttons live inside a dedicated container node in `forge_view.tscn` (e.g., `HammerSidebar/TagHammerSection`). Visibility is set in `_ready()` and on any relevant signal:

```gdscript
# In forge_view.gd _ready():
_update_tag_section_visibility()

# Called wherever prestige might change (prestige_completed signal):
func _update_tag_section_visibility() -> void:
    tag_hammer_section.visible = (GameState.prestige_level >= 1)
```

`GameEvents.prestige_completed` can be connected to trigger this refresh if prestige can happen during a play session.

### Pattern 5: Error Toast in Forge View

`save_toast.gd` is a Label subclass with `show_toast(message, color)` using `create_tween()`. The same pattern applies to a forge-local error toast. The toast label sits inside `forge_view.tscn` and is managed entirely in `forge_view.gd`:

```gdscript
# forge_view.gd — forge error toast
@onready var forge_error_toast: Label = $ForgeErrorToast

func _show_forge_error(message: String) -> void:
    forge_error_toast.text = message
    forge_error_toast.modulate = Color(1.0, 0.4, 0.4, 1.0)
    forge_error_toast.visible = true
    var tween := create_tween()
    tween.tween_interval(2.0)   # Hold for 2 seconds
    tween.tween_property(forge_error_toast, "modulate:a", 0.0, 0.5)  # Fade 0.5s
    tween.tween_callback(func(): forge_error_toast.visible = false)
```

Error toast triggered in `update_item()` where `can_apply()` fails:
```gdscript
if not selected_currency.can_apply(current_item):
    var msg := selected_currency.get_error_message(current_item)
    if msg != "":
        _show_forge_error(msg)
    return
```

### Pattern 6: LootTable — Tag Drop Integration

Tag currencies drop in `LootTable.roll_pack_currency_drop()`. The cleanest approach is a second pass after existing currency rolling, gated on `GameState.prestige_level >= 1`:

```gdscript
# At end of LootTable.roll_pack_currency_drop() — add tag currency section:
static func roll_pack_tag_currency_drop(area_level: int) -> Dictionary:
    if GameState.prestige_level < 1:
        return {}

    var drops: Dictionary = {}
    # ~7.5% per pack — middle of 5-10% range per user decision
    var base_chance: float = 0.075
    if randf() < base_chance:
        var tag_types := PrestigeManager.TAG_TYPES
        var chosen: String = tag_types[randi() % tag_types.size()]
        # Small chance of 2 at higher areas (15% threshold at area >= 50)
        var qty := 1
        if area_level >= 50 and randf() < 0.15:
            qty = 2
        drops[chosen] = qty
    return drops
```

Called from `CombatEngine._on_pack_killed()` alongside existing currency drops:

```gdscript
# In combat_engine.gd _on_pack_killed():
var tag_drops := LootTable.roll_pack_tag_currency_drop(GameState.area_level)
if not tag_drops.is_empty():
    for tag_type in tag_drops:
        if tag_type not in GameState.tag_currency_counts:
            GameState.tag_currency_counts[tag_type] = 0
        GameState.tag_currency_counts[tag_type] += tag_drops[tag_type]
    GameEvents.tag_currency_dropped.emit(tag_drops)
```

`forge_view.gd` connects `GameEvents.tag_currency_dropped` to refresh tag button states.

### Pattern 7: update_currency_button_states() Extension

Tag buttons read from `tag_currency_counts` not `currency_counts`:

```gdscript
func update_currency_button_states() -> void:
    # Existing: standard currency buttons
    for currency_type in ["runic", "forge", "tack", "grand", "claw", "tuning"]:
        var count: int = GameState.currency_counts.get(currency_type, 0)
        var button: Button = currency_buttons[currency_type]
        button.disabled = (count <= 0)
        button.text = currencies[currency_type].currency_name + " (" + str(count) + ")"
        button.icon = hammer_icons.get(currency_type)

    # New: tag currency buttons (only visible when prestige >= 1 anyway)
    for tag_type in ["fire", "cold", "lightning", "defense", "physical"]:
        var count: int = GameState.tag_currency_counts.get(tag_type, 0)
        var button: Button = currency_buttons[tag_type]
        button.disabled = (count <= 0)
        button.text = currencies[tag_type].currency_name + " (" + str(count) + ")"
        button.icon = hammer_icons.get(tag_type, null)

    # Deselect if selected tag currency is now 0
    if selected_currency_type in ["fire", "cold", "lightning", "defense", "physical"]:
        if GameState.tag_currency_counts.get(selected_currency_type, 0) <= 0:
            selected_currency = null
            selected_currency_type = ""
            for btn_type in currency_buttons:
                currency_buttons[btn_type].button_pressed = false
```

### Recommended Project Structure
```
models/currencies/
├── currency.gd              # Base (unchanged)
├── forge_hammer.gd          # Normal→Rare (unchanged)
├── runic_hammer.gd          # (unchanged)
├── [other existing]         # (unchanged)
└── tag_hammer.gd            # NEW — single class for all 5 tag types

scenes/
├── forge_view.tscn          # Add: TagHammerSection container, 5 buttons, separator, toast label
└── forge_view.gd            # Extend: tag currencies dict, button wiring, visibility gate, toast

models/loot/
└── loot_table.gd            # Extend: roll_pack_tag_currency_drop() static method

models/combat/
└── combat_engine.gd         # Extend: _on_pack_killed() calls tag drop roller, emits signal
```

### Anti-Patterns to Avoid
- **Five separate TagHammer classes:** Creates 5 near-identical files that diverge over time. Use one parameterized class.
- **Merging tag_currency_counts into currency_counts:** The GameState comment explicitly separates them. `spend_currency()` and `add_currencies()` only touch `currency_counts`; tag currencies must use their own path.
- **Hiding tag buttons with `disabled = true`:** User decision says fully absent, not grayed out. Use `visible = false` on the container node.
- **Calling `item.add_prefix()` / `item.add_suffix()` from replacement logic:** These methods filter by `item.valid_tags`, not by hammer tag. The replacement must directly access `ItemAffixes.prefixes` / `.suffixes`, filter by required_tag, then call `Affixes.from_affix()` directly.
- **Calling `can_apply()` inside `_do_apply()`:** The `Currency.apply()` template method already calls `can_apply()` first. Don't double-check.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Affix tier floor | Manual clamp | `Affixes.from_affix(template, floor_val)` | Already implemented in Phase 38 — applies `maxi(template.tier_range.x, floor)` |
| Affix duplication check | Manual name comparison | `item.is_affix_on_item(template)` | Already exists and handles prefix/suffix correctly |
| Item's valid-tag filter | Manual `valid_tags` check | `item.has_valid_tag(affix)` | Already exists, loops over `item.valid_tags` vs `affix.tags` |
| Tier floor calculation | Custom math | `item._get_affix_tier_floor()` | Already exists: `(item.tier - 1) * 4 + 1` |
| Toast fade animation | Custom tween | Same tween pattern as `save_toast.gd` | Tween is already proven — copy the exact `create_tween()` + `tween_interval` + `tween_property` chain |
| Tag type list | Hardcoded strings | `PrestigeManager.TAG_TYPES` | ["fire","cold","lightning","defense","physical"] already defined |

**Key insight:** The affix selection pipeline (`has_valid_tag` + `is_affix_on_item` + `from_affix`) already exists and handles every constraint the tag hammers need. The tag hammer's only addition is a second filter step: `required_tag in affix.tags`.

---

## Common Pitfalls

### Pitfall 1: Replacement Affix Violates Prefix/Suffix Type
**What goes wrong:** `_replace_random_affix_with_tagged()` picks a suffix template but replaces a prefix slot, causing item to have an illegal suffix in `item.prefixes` or vice versa.
**Why it happens:** Prefix/suffix type is tracked on the `Affix.type` field. If the victim and replacement have different types, the item data becomes inconsistent.
**How to avoid:** Match replacement type to victim type — if victim is a prefix, only look for tagged prefixes in the replacement pool. If victim is a suffix, only look for tagged suffixes. Fall back to the other type only if no matching type is in the tagged pool, and replace a different victim of the correct type.
**Warning signs:** Items where `item.prefixes` contains an `Affix` with `type == SUFFIX` — visible in debug display.

### Pitfall 2: can_apply() False Negative on Item with No Tag-Matching Affixes
**What goes wrong:** `_has_any_matching_affix()` filters by both `item.has_valid_tag(affix)` AND `required_tag in affix.tags`. If the item slot (e.g., Ring) has no valid affixes tagged with PHYSICAL, the hammer correctly blocks. But if the logic is wrong (e.g., checking item.valid_tags against the hammer tag instead of affix.tags), it may incorrectly block or allow.
**Why it happens:** Two separate filtering concerns (item-slot compatibility and hammer-tag requirement) are both in play simultaneously.
**How to avoid:** Verify logic: for each template in `ItemAffixes.prefixes` / `.suffixes`, both `item.has_valid_tag(template)` AND `required_tag in template.tags` must be true. These are independent checks — neither implies the other.
**Warning signs:** A Physical Hammer incorrectly blocks on a weapon (weapons have Physical affixes). A Fire Hammer incorrectly allows on a ring (if rings have no fire affixes).

### Pitfall 3: Tag Currency Spend Uses Wrong Dictionary
**What goes wrong:** Calling `GameState.spend_currency("fire")` looks in `currency_counts` and fails silently (returns false because "fire" is not a key), so the currency is never consumed, making tag hammers free.
**Why it happens:** `spend_currency()` only reads `currency_counts`, not `tag_currency_counts`.
**How to avoid:** Tag currencies need their own spend path. Either add `GameState.spend_tag_currency(type)` or inline the dict read in `forge_view.gd`. Never route tag keys through `spend_currency()`.
**Warning signs:** Tag hammer applies but `tag_currency_counts["fire"]` never decreases.

### Pitfall 4: Tag Buttons Visible Before P1 Due to Scene Load Order
**What goes wrong:** `_update_tag_section_visibility()` reads `GameState.prestige_level` in `_ready()`, but `GameState._ready()` loads from save — if scene order means `forge_view._ready()` fires before `GameState` loads save data, prestige level reads 0 even for a P1 player.
**Why it happens:** Godot autoload initialization order. GameState autoloads before scene nodes, so by the time `forge_view._ready()` runs, `SaveManager.load_game()` has already been called in `GameState._ready()`. This should be safe, but verify the autoload order in Project Settings.
**How to avoid:** Autoloads run in order listed in Project Settings. As long as GameState is listed before scenes load, `prestige_level` will be correct. Verify autoload order includes: GameEvents → GameState → SaveManager → PrestigeManager (this is the apparent order from the codebase).
**Warning signs:** P1 player sees no tag buttons on game launch, but buttons appear after any state change.

### Pitfall 5: Tag Currency Drops Not Triggering UI Refresh
**What goes wrong:** `GameEvents.tag_currency_dropped` emits, but `forge_view.gd` never connected to it, so tag button counts remain stale.
**Why it happens:** The existing `currency_dropped` signal is connected via `gameplay_view.currencies_found.connect(forge_view.on_currencies_found)` in `main_view.gd`. Tag drops go through a different signal.
**How to avoid:** Connect `GameEvents.tag_currency_dropped` in `forge_view._ready()` (directly, not via gameplay_view relay, since forge_view can connect global signals directly). Handler calls `update_currency_button_states()`.
**Warning signs:** Tag button shows "Fire Hammer (0)" even after a drop.

### Pitfall 6: Guaranteed-Tag Replace Steps Break Item Mod Count
**What goes wrong:** `_do_apply()` calls `add_prefix()` / `add_suffix()` to roll 4-6 mods, then `_replace_random_affix_with_tagged()` replaces one — but the replacement may fail silently (empty tagged pool), leaving the item with 0 tag-matching affixes despite `can_apply()` having returned true.
**Why it happens:** The pool check in `can_apply()` (`_has_any_matching_affix`) considers the item pre-modification with no existing affixes. After normal rolling, `is_affix_on_item()` exclusions may have exhausted the tag pool, making replacement impossible.
**How to avoid:** In `_replace_random_affix_with_tagged()`, the dedup check `not item.is_affix_on_item(template)` may be too strict when the pool is tiny. Since we're replacing (not adding), we're allowed to pick a template that IS already on the item if it's the only tagged option — we'd just be rerolling its value. Or: skip the `is_affix_on_item` dedup in the replacement pool, since we're replacing anyway. The locked decision says this should not happen (can_apply blocks), but the replace step needs a fallback that doesn't silently fail.
**Warning signs:** Guaranteed tag requirement fails even after successful application.

---

## Code Examples

### Affix Tag Structure (Verified in item_affixes.gd)

```gdscript
# Fire Resistance suffix — has both DEFENSE and FIRE tags (post Phase 39 prep)
Affix.new(
    "Fire Resistance",
    Affix.AffixType.SUFFIX,
    1, 3,
    [Tag.DEFENSE, Tag.FIRE, Tag.WEAPON],  # FIRE tag present — matches Fire Hammer
    [Tag.StatType.FIRE_RESISTANCE],
    Vector2i(1, 32)
)

# All Resistances suffix — has DEFENSE and WEAPON only (no element tags — correct)
Affix.new(
    "All Resistances",
    Affix.AffixType.SUFFIX,
    1, 3,
    [Tag.DEFENSE, Tag.WEAPON],  # No FIRE/COLD/LIGHTNING — Fire Hammer ignores this
    [Tag.StatType.ALL_RESISTANCE],
    Vector2i(1, 32)
)

# Flat Armor prefix — has DEFENSE and PHYSICAL tags
Affix.new(
    "Flat Armor",
    Affix.AffixType.PREFIX,
    2, 5,
    [Tag.DEFENSE, Tag.PHYSICAL, Tag.ARMOR],  # PHYSICAL tag — matches Physical Hammer
    [Tag.StatType.FLAT_ARMOR],
    Vector2i(1, 32)
)
```

### Scene Node Layout for Tag Section (forge_view.tscn additions)

```
HammerSidebar (existing ColorRect)
├── RunicHammerBtn          # existing at y=15
├── ForgeHammerBtn          # existing at y=15
├── TackHammerBtn           # existing at y=90
├── GrandHammerBtn          # existing at y=90
├── ClawHammerBtn           # existing at y=165
├── TuningHammerBtn         # existing at y=165
├── TagHammerSeparator      # NEW: ColorRect separator at y=240, thin horizontal line
├── TagHammerSection        # NEW: Container node (Control or Node2D), visibility-gated
│   ├── FireHammerBtn       # Button at y=248 in section
│   ├── ColdHammerBtn       # Button at y=318 in section
│   ├── LightningHammerBtn  # Button at y=388 in section (label: "Lightning Hammer" may need smaller font)
│   ├── DefenseHammerBtn    # Button at y=458 in section
│   └── PhysicalHammerBtn   # Button at y=528 in section
└── InventoryLabel          # existing — pushed lower or stays at y=260 (overlap risk: check y bounds)
```

Note: Current `InventoryLabel` is at `offset_top = 260.0`. Tag buttons need ~75px each × 5 = 375px. The sidebar is 650px tall (y=10 to y=660). Standard buttons end at y=230. Inventory label would need to move to y=620+ or be repositioned. The planner should decide the exact layout — this is noted as a layout constraint.

### Existing Toast Pattern (from save_toast.gd — reuse in forge_view.gd)

```gdscript
func show_toast(message: String, color: Color = Color.WHITE) -> void:
    text = message
    modulate = Color(color.r, color.g, color.b, 1.0)
    visible = true
    var tween := create_tween()
    tween.tween_interval(1.0)
    tween.tween_property(self, "modulate:a", 0.0, 0.5)
    tween.tween_callback(func(): visible = false)
```

For forge errors, use 2.0s hold instead of 1.0s (2-3s per user decision).

### LootTable Tag Drop (verified integration point)

```gdscript
# In combat_engine.gd _on_pack_killed() — after existing currency drops:
var tag_drops := LootTable.roll_pack_tag_currency_drop(GameState.area_level)
if not tag_drops.is_empty():
    for tag_type in tag_drops:
        if tag_type not in GameState.tag_currency_counts:
            GameState.tag_currency_counts[tag_type] = 0
        GameState.tag_currency_counts[tag_type] += tag_drops[tag_type]
    GameEvents.tag_currency_dropped.emit(tag_drops)
```

---

## Tag Coverage Analysis

Based on reading `item_affixes.gd` — which affixes match which tag hammers, by item slot. (Item slot compatibility via `item.valid_tags`; confirmed from item subclass files implied by CONTEXT.)

| Tag | Matching Affixes (post-prep) | Item Slots With Coverage |
|-----|------------------------------|--------------------------|
| FIRE | %Fire Damage (prefix), Fire Damage (prefix), Fire Resistance (suffix) | Weapon (WEAPON tag), Ring (WEAPON tag) — armor/helmet/boots lack WEAPON-tagged fire affixes unless they also have fire resistance |
| COLD | %Cold Damage (prefix), Cold Damage (prefix), Cold Resistance (suffix) | Weapon, Ring |
| LIGHTNING | %Lightning Damage (prefix), Lightning Damage (prefix), Lightning Resistance (suffix) | Weapon, Ring |
| DEFENSE | Flat Armor (PREFIX), %Armor (PREFIX), Evasion (PREFIX), %Evasion (PREFIX), Energy Shield (PREFIX), %Energy Shield (PREFIX), Health (PREFIX), %Health (PREFIX), Mana (PREFIX), Attack Speed (has PHYSICAL not DEFENSE — excluded from DEFENSE hammer), Life (suffix), Armor (suffix), Fire/Cold/Lightning Resistance (suffix), All Resistances (suffix) | All slots (defense affixes are broad) |
| PHYSICAL | Physical Damage (prefix), %Physical Damage (prefix), Flat Armor (prefix), %Armor (prefix), Armor (suffix), Attack Speed (suffix) | Weapon (damage), Armor/Helmet/Boots (armor affixes if slot has ARMOR tag) |

**Critical finding:** The CONTEXT.md note states affix tags were updated. The current `item_affixes.gd` already reflects these updates. No affix tag corrections are needed in this phase — they are already done.

**Potential edge case:** Rings (`BasicRing`) — their `valid_tags` needs verification. If rings only have `[Tag.WEAPON]`, they can receive fire/cold/lightning/physical damage affixes and fire/cold/lightning resistance. Defense Hammer on a ring would match `Life` (suffix) and resistance suffixes. Physical Hammer on a ring would match `Physical Damage`, `%Physical Damage` prefixes. Coverage appears adequate for all 5 hammers on all item slots, but the planner should verify `BasicRing.valid_tags` explicitly.

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Currency classes per type (5 files) | Single parameterized TagHammer class | Simpler maintenance |
| Separate spend path per currency source | Unified check with dictionary routing | `spend_currency()` already exists — extend or bypass |
| Area-gate system via CURRENCY_AREA_GATES | Prestige gate: simpler `prestige_level >= 1` check | Tag hammers do NOT use the ramp system — P1 is a hard gate |

---

## Open Questions

1. **Inventory Label layout conflict**
   - What we know: `InventoryLabel` is at `offset_top = 260` inside HammerSidebar (650px tall). 5 tag buttons at ~70px each need ~350px below standard buttons (y=230).
   - What's unclear: Does the planner want to push InventoryLabel down (or off-screen), or are tag buttons placed differently (outside HammerSidebar, in a new container)?
   - Recommendation: Move `InventoryLabel` outside `HammerSidebar` into a separate panel, or scroll the sidebar. Alternatively, accept the tag section overlapping if tag counts are small buttons.

2. **BasicRing valid_tags**
   - What we know: Ring items are LightSword/BasicRing subclasses. Item.valid_tags is set in each subclass.
   - What's unclear: Ring's exact `valid_tags` array — whether it includes tags that cover Physical Hammer affixes beyond %Physical Damage.
   - Recommendation: Read `models/items/basic_ring.gd` in the planning phase and verify coverage for all 5 hammers.

3. **Tag hammer icon assets**
   - What we know: Standard hammers use preloaded PNG assets from `res://assets/`. Tag hammers reference `hammer_icons.get(currency_type, null)` — returns null if key absent.
   - What's unclear: Whether new icon assets will be created or existing ones reused/tinted.
   - Recommendation: Reuse `forge_hammer.png` with no icon (null icon) for tag hammer buttons in the first pass. The CONTEXT specifies "matching existing standard hammer button style" — a placeholder icon or no icon is acceptable.

---

## Sources

### Primary (HIGH confidence)
- Direct code reading of `forge_hammer.gd`, `currency.gd`, `item.gd`, `item_affixes.gd`, `tag.gd` — verified current API
- Direct code reading of `game_state.gd`, `prestige_manager.gd`, `game_events.gd` — confirmed all scaffolding exists
- Direct code reading of `loot_table.gd`, `combat_engine.gd` — confirmed integration points
- Direct code reading of `forge_view.gd`, `forge_view.tscn` — confirmed UI structure and button wiring pattern
- Direct code reading of `save_manager.gd` — confirmed `tag_currency_counts` already serialized/deserialized
- Direct code reading of `save_toast.gd` — confirmed reusable toast tween pattern

### Secondary (MEDIUM confidence)
- CONTEXT.md decisions section — user-locked architecture choices
- STATE.md accumulated context — confirms decisions from phases 35-38

### Tertiary (LOW confidence)
- Assumed `BasicRing.valid_tags` covers weapon-type affixes based on gameplay context; unverified by direct read of `basic_ring.gd`

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — entire codebase read directly
- Architecture: HIGH — all integration points identified with exact file/line context
- Pitfalls: HIGH for type-mismatch and dictionary routing issues (verified from code); MEDIUM for layout conflict (estimates based on tscn pixel values)
- Tag coverage: HIGH for confirmed affixes; MEDIUM for ring slot edge case

**Research date:** 2026-03-01
**Valid until:** 2026-04-01 (stable codebase, no external dependencies)
