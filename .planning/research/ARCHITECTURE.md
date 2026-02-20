# Architecture Research

**Domain:** Prestige meta-progression, item tier gating, 32-level affix tiers, and tag-targeted crafting currencies — integration with existing Hammertime v1.6 architecture
**Researched:** 2026-02-20
**Confidence:** HIGH (based on direct codebase analysis of all affected files)

---

## System Overview

Four new systems integrate with the existing architecture. None require replacing existing autoloads. One new autoload (`PrestigeManager`) is added. Existing models change in constrained, backward-compatible ways.

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                             Scene Layer                                       │
│  ┌───────────────────────────────┐  ┌─────────────────────────────────────┐  │
│  │  scenes/forge_view.gd         │  │  scenes/gameplay_view.gd            │  │
│  │  (MODIFIED)                   │  │  (MODIFIED — item tier drop logic)  │  │
│  │  - New prestige UI panel      │  │  - Roll item tier on drop           │  │
│  │  - Show unlocked tier range   │  │  - Pass tier to loot_table          │  │
│  │  - New tag-hammer buttons     │  │                                     │  │
│  └────────────┬──────────────────┘  └──────────────┬──────────────────────┘  │
│               │                                    │                          │
├───────────────┼────────────────────────────────────┼──────────────────────────┤
│               │             Autoload Layer          │                          │
│  ┌────────────▼──────────────────────────────────▼──────────────────────┐    │
│  │  autoloads/game_state.gd (MODIFIED)                                   │    │
│  │  + prestige_level: int                                                │    │
│  │  + max_item_tier_unlocked: int                                        │    │
│  │  + tag_currency_counts: Dictionary                                    │    │
│  └────────────────────────────────────────────────────────────────────────┘   │
│                                                                                │
│  ┌────────────────────────────────────────────────────────────────────────┐   │
│  │  autoloads/prestige_manager.gd (NEW AUTOLOAD)                          │   │
│  │  - can_prestige() → bool                                               │   │
│  │  - get_prestige_cost() → Dictionary                                    │   │
│  │  - execute_prestige()                                                  │   │
│  │  - get_item_tier_range() → Vector2i                                    │   │
│  │  - get_affix_tier_range(item_tier) → Vector2i                          │   │
│  └────────────────────────────────────────────────────────────────────────┘   │
│                                                                                │
│  ┌────────────────────────────────────────────────────────────────────────┐   │
│  │  autoloads/save_manager.gd (MODIFIED)                                  │   │
│  │  - SAVE_VERSION = 3                                                    │   │
│  │  - _migrate_v2_to_v3(): adds prestige fields                           │   │
│  │  - _build_save_data(): includes prestige_level, max_item_tier          │   │
│  │  - _restore_state(): restores prestige fields                          │   │
│  └────────────────────────────────────────────────────────────────────────┘   │
│                                                                                │
├────────────────────────────────────────────────────────────────────────────────┤
│                             Model Layer                                        │
│  ┌──────────────┐  ┌───────────────────┐  ┌──────────────────────────────┐   │
│  │  models/     │  │  models/affixes/  │  │  models/currencies/          │   │
│  │  items/      │  │  affix.gd         │  │  tag_hammer.gd (NEW)         │   │
│  │  item.gd     │  │  (MODIFIED)       │  │  fire_hammer.gd  (NEW)       │   │
│  │  (MODIFIED   │  │  - tier_range max │  │  cold_hammer.gd  (NEW)       │   │
│  │  item_tier   │  │    expanded 8→32  │  │  lightning_hammer.gd (NEW)   │   │
│  │  field)      │  │  - tier maps to   │  │  defense_hammer.gd (NEW)     │   │
│  └──────────────┘  │    item_tier gate │  └──────────────────────────────┘   │
│                    └───────────────────┘                                       │
│  ┌──────────────────────────────────────────────────────────────────────────┐ │
│  │  models/loot/loot_table.gd (MODIFIED)                                    │ │
│  │  - roll_item_tier(area_level, prestige_level) → int                      │ │
│  │  - Weighted by area_level within unlocked [1..max_tier] range            │ │
│  └──────────────────────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────────────────┘
```

---

## Component Responsibilities

| Component | Responsibility | Status |
|-----------|---------------|--------|
| `autoloads/prestige_manager.gd` | Prestige gating logic, cost table, execute reset, tier mapping | NEW |
| `autoloads/game_state.gd` | Hold `prestige_level`, `max_item_tier_unlocked`, `tag_currency_counts` | MODIFIED |
| `autoloads/save_manager.gd` | Save/load prestige fields, v2→v3 migration | MODIFIED |
| `autoloads/item_affixes.gd` | Affix template pool; tier_range max changes 8→32 for new affixes | MODIFIED |
| `models/items/item.gd` | Add `item_tier` field (1-8); serialize/deserialize it | MODIFIED |
| `models/affixes/affix.gd` | No structural change; tier_range.y changes per affix template | UNCHANGED |
| `models/currencies/tag_hammer.gd` | Abstract base for tag-targeted hammers | NEW |
| `models/currencies/fire_hammer.gd` (etc.) | One subclass per targeted tag | NEW |
| `models/loot/loot_table.gd` | Add `roll_item_tier()` weighted by area_level + prestige | MODIFIED |
| `scenes/forge_view.gd` | Prestige UI panel, tag-hammer buttons, tier display | MODIFIED |
| `scenes/gameplay_view.gd` | Pass prestige state into item drop tier rolls | MODIFIED |

---

## Integration Point 1: PrestigeManager Autoload (NEW)

`PrestigeManager` is the single authority on prestige rules. It holds no mutable state itself — all state lives in `GameState`. This keeps save/load simple: GameState already persists everything.

```gdscript
# autoloads/prestige_manager.gd
extends Node

# 7 prestige levels total: 0 = fresh game, 1-7 = prestige states
const MAX_PRESTIGE_LEVEL: int = 7

# Prestige costs by level (what you must spend to reach that level)
# Level 1 cost: affordable at Shadow Realm entry (~area 75)
# Each subsequent cost escalates significantly
const PRESTIGE_COSTS: Array[Dictionary] = [
    {},                                         # [0] = no cost (start state)
    {"grand": 50, "claw": 25, "tuning": 10},   # [1] cost to reach prestige 1
    {"grand": 100, "claw": 60, "tuning": 25},  # [2]
    {"grand": 200, "claw": 120, "tuning": 50}, # [3]
    {"grand": 350, "claw": 200, "tuning": 80}, # [4]
    {"grand": 500, "claw": 300, "tuning": 120},# [5]
    {"grand": 700, "claw": 450, "tuning": 160},# [6]
    {"grand": 1000, "claw": 650, "tuning": 200},# [7]
]

# Item tier unlocked per prestige level
# Prestige 0: tiers 1 only (weakest items)
# Prestige 7: all 8 tiers
const ITEM_TIERS_BY_PRESTIGE: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8]

## Returns whether the player currently meets requirements to prestige.
func can_prestige() -> bool:
    var next_level: int = GameState.prestige_level + 1
    if next_level > MAX_PRESTIGE_LEVEL:
        return false
    var cost: Dictionary = PRESTIGE_COSTS[next_level]
    for currency_type in cost:
        var have: int = GameState.currency_counts.get(currency_type, 0)
        if have < cost[currency_type]:
            return false
    return true

## Returns the cost to reach the next prestige level.
func get_prestige_cost() -> Dictionary:
    var next_level: int = GameState.prestige_level + 1
    if next_level > MAX_PRESTIGE_LEVEL:
        return {}
    return PRESTIGE_COSTS[next_level]

## Executes a prestige reset. Spends currencies, wipes transient state, increments prestige.
## Caller must have already verified can_prestige() == true.
func execute_prestige() -> void:
    var next_level: int = GameState.prestige_level + 1
    var cost: Dictionary = PRESTIGE_COSTS[next_level]

    # Spend currencies
    for currency_type in cost:
        GameState.currency_counts[currency_type] -= cost[currency_type]

    # Increment prestige level and unlock next item tier
    GameState.prestige_level = next_level
    GameState.max_item_tier_unlocked = ITEM_TIERS_BY_PRESTIGE[next_level]

    # Reset transient game state (area, gear, inventory)
    _wipe_run_state()

    # Emit event for UI refresh and save trigger
    GameEvents.prestige_completed.emit(next_level)

## Wipes area progress, equipped gear, and crafting inventory.
## Prestige_level and max_item_tier_unlocked are NOT wiped — they survive prestige.
func _wipe_run_state() -> void:
    # Reset hero (new instance, clears all equipped items and stats)
    GameState.hero = Hero.new()
    GameState.hero.equipped_items = {
        "weapon": null, "helmet": null,
        "armor": null, "boots": null, "ring": null
    }

    # Reset crafting inventory to empty arrays
    for slot in GameState.crafting_inventory:
        GameState.crafting_inventory[slot] = []

    # Give starter weapon for the new run
    GameState.crafting_inventory["weapon"] = [LightSword.new()]
    GameState.crafting_bench_type = "weapon"

    # Reset area progress to beginning
    GameState.area_level = 1
    GameState.max_unlocked_level = 1

    # Reset ALL currencies to zero (fresh run economy)
    # Tag currencies also reset
    for key in GameState.currency_counts:
        GameState.currency_counts[key] = 0
    for key in GameState.tag_currency_counts:
        GameState.tag_currency_counts[key] = 0
    # Give 1 runic to start
    GameState.currency_counts["runic"] = 1

## Returns the item tier range available at current prestige level.
func get_item_tier_range() -> Vector2i:
    return Vector2i(1, GameState.max_item_tier_unlocked)

## Returns the affix tier_range for an item of a given item_tier.
## 4 affix tiers per item tier, ascending item tier = higher affix tiers available.
## item_tier 1: affixes roll in tiers 29-32 (weakest)
## item_tier 8: affixes roll in tiers 1-32 (full range)
func get_affix_tier_range(item_tier: int) -> Vector2i:
    # Each item tier unlocks 4 additional affix tiers at the "good" end.
    # Tier 1 is best (highest value), tier 32 is weakest.
    # item_tier 1 → affix tiers 29-32 (very weak)
    # item_tier 2 → affix tiers 25-32
    # ...
    # item_tier 8 → affix tiers 1-32 (full range)
    var best_affix_tier: int = 32 - (item_tier - 1) * 4
    return Vector2i(best_affix_tier, 32)
```

**Why a new autoload vs method on GameState:** GameState is a data container. Business logic (prestige rules, cost tables, tier mapping) belongs in a domain service. PrestigeManager follows the same pattern as StatCalculator — pure logic, reads GameState, writes GameState. Zero UI dependencies.

**Autoload order in project.godot:** PrestigeManager must be registered AFTER GameState (it reads GameState on every call). Add after GameState entry.

---

## Integration Point 2: GameState — New Fields

Three new fields added to `game_state.gd`. All are initialized in `initialize_fresh_game()` and included in save/load.

```gdscript
# autoloads/game_state.gd (ADDITIONS ONLY — no existing lines change)

# Prestige state — survives prestige reset
var prestige_level: int = 0
var max_item_tier_unlocked: int = 1

# Tag-targeted currency counts (separate dict for clean save migration)
# Keys match tag hammer names: "fire", "cold", "lightning", "defense"
var tag_currency_counts: Dictionary = {}
```

In `initialize_fresh_game()`, add initialization after existing currency initialization:

```gdscript
# game_state.gd — inside initialize_fresh_game()
prestige_level = 0
max_item_tier_unlocked = 1
tag_currency_counts = {
    "fire": 0,
    "cold": 0,
    "lightning": 0,
    "defense": 0,
}
```

**Why `tag_currency_counts` is separate from `currency_counts`:** Tag hammers unlock at prestige 1 and are a distinct game mechanic. Keeping them in a separate dict allows:
- Clean v2→v3 migration (just add the new key)
- `_wipe_run_state()` to zero both dicts independently
- LootTable to gate tag currency drops separately from base currencies
- ForgeView to render two button groups without mixing

**What does NOT change in GameState:** `currency_counts` dict keys stay as-is ("runic", "forge", "tack", "grand", "claw", "tuning"). All existing functionality reads this dict — no refactor needed.

---

## Integration Point 3: Item Model — `item_tier` Field

`Item.tier` already exists but currently stores the item base tier (always 8 for all existing item types — LightSword, BasicArmor, etc.). This is a collision: `tier` has been used loosely.

**Decision:** Rename the item-tier concept to `item_tier` to avoid ambiguity. The existing `tier` field on Affix stays unchanged (it is the rolled affix quality tier). The `item.tier` field was previously set to 8 on all item types and used only for `is_item_better()` comparison — this becomes `item_tier` with values 1-8 where 8 was previously hardcoded.

```gdscript
# models/items/item.gd — add field
var item_tier: int = 1  # 1-8 where 8 is weakest (matches prior convention)
```

Update `to_dict()` and `create_from_dict()` to serialize/deserialize `item_tier`.

In `to_dict()`:
```gdscript
return {
    # ... existing fields ...
    "item_tier": item_tier,
}
```

In `create_from_dict()`:
```gdscript
item.item_tier = int(data.get("item_tier", 8))  # default 8 = weakest (existing items)
```

**Existing item subclasses** (LightSword, BasicArmor, etc.) currently set `self.tier = 8`. Change these to `self.item_tier = 8`. The `tier` field can be deprecated/removed from Item base class but this is a safe follow-up; for now both can coexist.

**`is_item_better()` in ForgeView** currently compares `item.tier`. Update to compare `item.item_tier` for armor slots. No behavioral change — the comparison logic is identical.

---

## Integration Point 4: Affix Tier Range Expansion (8 → 32)

The `Affix.tier_range` field already exists as `Vector2i`. Currently set to `Vector2i(1, 8)` for weapon affixes and `Vector2i(1, 30)` for defensive affixes.

**The change:** Expand to 32 tiers. Affix construction in `item_affixes.gd` sets the tier_range per affix template. No structural change to `Affix` is needed — only the constant values in the template definitions change.

```gdscript
# models/affixes/affix.gd — NO STRUCTURAL CHANGE NEEDED
# tier_range: Vector2i already supports any max value
```

In `item_affixes.gd`, update all `Vector2i(1, 8)` to `Vector2i(1, 32)` and all `Vector2i(1, 30)` to `Vector2i(1, 32)`. The existing scaling formula in `Affix._init()` is:

```gdscript
self.min_value = p_min * (tier_range.y + 1 - tier)
self.max_value = p_max * (tier_range.y + 1 - tier)
```

With `tier_range.y = 32`, tier 1 (best) gives a multiplier of 32, tier 32 (worst) gives multiplier of 1. The `base_min` and `base_max` values in each affix template must be retuned to maintain reasonable value ranges at tier 32. This is a balance pass, not a structural change.

**Critical:** The `Affix.from_dict()` already reads `tier_range_x` and `tier_range_y` from save data. Existing saves with `tier_range.y = 8` will load affixes that rolled tier 1-8. These are valid and will continue to work — they just won't have access to the new tiers 9-32 until re-crafted. No migration needed for existing affixes.

**Affix tier selection during add_prefix/add_suffix:** Currently `Affix._init()` calls `randi_range(tier_range.x, tier_range.y)` to pick a tier. With PrestigeManager providing `get_affix_tier_range(item_tier)`, the item must constrain which tier range to use when adding affixes.

This requires `Item.add_prefix()` and `Item.add_suffix()` to pass the item's tier-constrained affix range to the affix constructor:

```gdscript
# models/items/item.gd — add_prefix() MODIFIED
func add_prefix() -> bool:
    # ... existing validation unchanged ...
    var affix_tier_range: Vector2i = PrestigeManager.get_affix_tier_range(item_tier)
    var new_prefix: Affix = valid_prefixes.pick_random()
    if new_prefix != null:
        # Clone with constrained tier range
        var constrained := Affix.new(
            new_prefix.affix_name,
            new_prefix.type,
            new_prefix.base_min,
            new_prefix.base_max,
            new_prefix.tags,
            new_prefix.stat_types,
            affix_tier_range,    # <-- CONSTRAINED, not template's full range
            new_prefix.base_dmg_min_lo,
            new_prefix.base_dmg_min_hi,
            new_prefix.base_dmg_max_lo,
            new_prefix.base_dmg_max_hi
        )
        self.prefixes.append(constrained)
        return true
    return false
```

The same change applies to `add_suffix()`. The template's `tier_range` (1-32 full range) is ignored; the item's tier determines which affix tiers it can access.

**This replaces the `Affixes.from_affix()` call** in `add_prefix`/`add_suffix`. Instead of cloning with `Affixes.from_affix(template)`, construct a new Affix with the constrained range. `Affixes.from_affix()` can remain as-is for other callers.

---

## Integration Point 5: Item Drop Tier Selection

`LootTable` must roll which item tier drops. The roll is weighted by area_level within the unlocked range.

```gdscript
# models/loot/loot_table.gd — NEW STATIC METHOD
## Rolls an item tier for a drop.
## Higher area levels within each tier's range give higher-tier items.
## Returns int in range [1, max_item_tier_unlocked].
static func roll_item_tier(area_level: int, max_item_tier_unlocked: int) -> int:
    if max_item_tier_unlocked <= 1:
        return 1

    # Build weights: higher item tiers have smaller weights at low area levels
    # Each item tier is "in season" for a 25-level band, centered on biome boundaries
    # item_tier 1: area 1-24 (Forest)
    # item_tier 2: area 25-49 (Dark Forest) — and so on
    # With 8 item tiers and ~25 levels per tier band, area 200+ = tier 8 at max prestige
    var weights: Array[float] = []
    for tier in range(1, max_item_tier_unlocked + 1):
        var tier_center: float = float(tier) * 25.0 - 12.5
        var distance: float = abs(float(area_level) - tier_center)
        # Gaussian-like weight: closer to tier center = higher chance
        var weight: float = maxf(0.1, 1.0 - distance / 50.0)
        weights.append(weight)

    # Weighted random pick
    var total: float = 0.0
    for w in weights:
        total += w
    var roll: float = randf() * total
    var cumulative: float = 0.0
    for i in range(weights.size()):
        cumulative += weights[i]
        if roll <= cumulative:
            return i + 1  # tiers are 1-indexed

    return max_item_tier_unlocked
```

In `gameplay_view.gd`, update item drop creation to set `item_tier`:

```gdscript
# scenes/gameplay_view.gd — inside _on_items_dropped() or item creation path
var dropped_item: Item = get_random_item_base(area_level)
dropped_item.item_tier = LootTable.roll_item_tier(
    GameState.area_level,
    GameState.max_item_tier_unlocked
)
item_base_found.emit(dropped_item)
```

---

## Integration Point 6: Tag-Targeted Currencies

Tag hammers are a new currency subclass hierarchy. One abstract base, four concrete subclasses for launch.

```gdscript
# models/currencies/tag_hammer.gd — ABSTRACT BASE (NEW)
class_name TagHammer extends Currency

var required_tag: String = ""

## Validates item is Magic or Rare AND has room for at least one more mod.
## Subclasses may add additional checks.
func can_apply(item: Item) -> bool:
    if item.rarity == Item.Rarity.NORMAL:
        return false
    var has_room: bool = (
        item.prefixes.size() < item.max_prefixes() or
        item.suffixes.size() < item.max_suffixes()
    )
    if not has_room:
        return false
    return true

func get_error_message(item: Item) -> String:
    if item.rarity == Item.Rarity.NORMAL:
        return currency_name + " requires a Magic or Rare item"
    var has_room: bool = (
        item.prefixes.size() < item.max_prefixes() or
        item.suffixes.size() < item.max_suffixes()
    )
    if not has_room:
        return "Item already has maximum mods"
    return ""

## Adds one mod guaranteed to have the required_tag.
func _do_apply(item: Item) -> void:
    # Build pools filtered to required_tag
    var valid_prefixes: Array[Affix] = []
    var valid_suffixes: Array[Affix] = []

    for prefix in ItemAffixes.prefixes:
        if required_tag in prefix.tags and item.has_valid_tag(prefix) and not item.is_affix_on_item(prefix):
            if item.prefixes.size() < item.max_prefixes():
                valid_prefixes.append(prefix)

    for suffix in ItemAffixes.suffixes:
        if required_tag in suffix.tags and item.has_valid_tag(suffix) and not item.is_affix_on_item(suffix):
            if item.suffixes.size() < item.max_suffixes():
                valid_suffixes.append(suffix)

    var all_valid: Array[Affix] = valid_prefixes.duplicate()
    all_valid.append_array(valid_suffixes)

    if all_valid.is_empty():
        # No matching tag mod available for this item — do nothing
        # Note: can_apply() should catch this case before _do_apply() is called
        return

    var chosen: Affix = all_valid.pick_random()
    var affix_tier_range: Vector2i = PrestigeManager.get_affix_tier_range(item.item_tier)
    var new_affix := Affix.new(
        chosen.affix_name, chosen.type,
        chosen.base_min, chosen.base_max,
        chosen.tags, chosen.stat_types,
        affix_tier_range,
        chosen.base_dmg_min_lo, chosen.base_dmg_min_hi,
        chosen.base_dmg_max_lo, chosen.base_dmg_max_hi
    )

    if chosen.is_prefix():
        item.prefixes.append(new_affix)
    else:
        item.suffixes.append(new_affix)

    item.update_value()
```

```gdscript
# models/currencies/fire_hammer.gd (NEW — one file per tag)
class_name FireHammer extends TagHammer

func _init() -> void:
    currency_name = "Fire Hammer"
    required_tag = Tag.FIRE

# cold_hammer.gd: required_tag = Tag.COLD
# lightning_hammer.gd: required_tag = Tag.LIGHTNING
# defense_hammer.gd: required_tag = Tag.DEFENSE
```

**Note on `can_apply` for TagHammer:** The base `can_apply()` checks rarity and space. A subtlety: if the item has no affixes with the `required_tag` in its valid pool AND all remaining slots are for that type, the hammer would succeed `can_apply()` but silently do nothing in `_do_apply()`. Add a pool-check to `can_apply()` for a cleaner UX:

```gdscript
# tag_hammer.gd — enhanced can_apply()
func can_apply(item: Item) -> bool:
    if item.rarity == Item.Rarity.NORMAL:
        return false
    # Check if any tagged mod is available for this item
    for prefix in ItemAffixes.prefixes:
        if required_tag in prefix.tags and item.has_valid_tag(prefix) and not item.is_affix_on_item(prefix):
            if item.prefixes.size() < item.max_prefixes():
                return true
    for suffix in ItemAffixes.suffixes:
        if required_tag in suffix.tags and item.has_valid_tag(suffix) and not item.is_affix_on_item(suffix):
            if item.suffixes.size() < item.max_suffixes():
                return true
    return false
```

**Integration with GameState:** Tag hammer counts are stored in `tag_currency_counts` (separate dict). ForgeView calls `GameState.tag_currency_counts[tag_key]` for display and `GameState.spend_tag_currency(tag_key)` for spending.

Add `spend_tag_currency()` to `game_state.gd`:
```gdscript
func spend_tag_currency(tag_key: String) -> bool:
    if tag_key not in tag_currency_counts:
        return false
    if tag_currency_counts[tag_key] <= 0:
        return false
    tag_currency_counts[tag_key] -= 1
    return true
```

**Tag hammer unlock:** Tag hammers are gated behind prestige 1. ForgeView checks `GameState.prestige_level >= 1` before showing tag hammer buttons.

---

## Integration Point 7: Save Format v3

Save format increments from v2 to v3. Migration is additive only — no existing fields change shape.

```gdscript
# autoloads/save_manager.gd
const SAVE_VERSION = 3  # bumped from 2

func _migrate_save(data: Dictionary) -> Dictionary:
    var saved_version: int = int(data.get("version", 1))
    if saved_version < 2:
        data = _migrate_v1_to_v2(data)
    if saved_version < 3:
        data = _migrate_v2_to_v3(data)
    data["version"] = SAVE_VERSION
    return data

## Migrates v2 save data to v3 (adds prestige fields with safe defaults).
func _migrate_v2_to_v3(data: Dictionary) -> Dictionary:
    # Add prestige fields that didn't exist in v2
    if not data.has("prestige_level"):
        data["prestige_level"] = 0
    if not data.has("max_item_tier_unlocked"):
        data["max_item_tier_unlocked"] = 1
    if not data.has("tag_currencies"):
        data["tag_currencies"] = {"fire": 0, "cold": 0, "lightning": 0, "defense": 0}
    return data
```

In `_build_save_data()`, add to the return dictionary:
```gdscript
"prestige_level": GameState.prestige_level,
"max_item_tier_unlocked": GameState.max_item_tier_unlocked,
"tag_currencies": GameState.tag_currency_counts.duplicate(),
```

In `_restore_state()`, add:
```gdscript
GameState.prestige_level = int(data.get("prestige_level", 0))
GameState.max_item_tier_unlocked = int(data.get("max_item_tier_unlocked", 1))
var saved_tag_currencies: Dictionary = data.get("tag_currencies", {})
for key in saved_tag_currencies:
    GameState.tag_currency_counts[key] = int(saved_tag_currencies[key])
```

Add save trigger for prestige in `_ready()`:
```gdscript
GameEvents.prestige_completed.connect(_on_save_trigger)
```

---

## Integration Point 8: GameEvents — New Signals

```gdscript
# autoloads/game_events.gd — add:
signal prestige_completed(new_level: int)    # fires after execute_prestige()
signal tag_currency_dropped(drops: Dictionary)  # fires from LootTable roll at prestige 1+
```

`prestige_completed` triggers:
- SaveManager auto-save
- ForgeView UI refresh (prestige panel update, unlock display)
- GameplayView reset to area 1

---

## Data Flow Diagrams

### Flow 1: Prestige Reset

```
[Player clicks Prestige button in ForgeView]
    ↓
[ForgeView checks PrestigeManager.can_prestige()]
    if false: show error label (missing currency or max prestige)
    if true: show confirm dialog
    ↓ (confirmed)
[PrestigeManager.execute_prestige()]
    → spend currencies from GameState.currency_counts
    → increment GameState.prestige_level
    → set GameState.max_item_tier_unlocked
    → _wipe_run_state():
        GameState.hero = Hero.new()
        GameState.crafting_inventory = {all empty arrays + starter weapon}
        GameState.area_level = 1
        GameState.max_unlocked_level = 1
        ALL currencies zeroed (currency_counts + tag_currency_counts)
        GameState.currency_counts["runic"] = 1
    → GameEvents.prestige_completed.emit(new_level)
    ↓
[SaveManager._on_save_trigger() → save_game()]
    → v3 format written with new prestige_level
    ↓
[ForgeView._on_prestige_completed()]
    → update prestige panel (level, cost, unlock display)
    → refresh all inventory displays (now empty)
    → load starter weapon to bench
    ↓
[GameplayView reset — driven by area_level = 1 in GameState]
    CombatEngine stopped if running (fire stop signal or check on next clear)
```

### Flow 2: Item Drop with Tier Selection

```
[CombatEngine kills pack → LootTable.roll_pack_item_drop() → true]
    ↓
[gameplay_view._on_pack_killed → drop generation]
    item_base = get_random_item_base(area_level)     # existing logic
    item_base.item_tier = LootTable.roll_item_tier(
        GameState.area_level,
        GameState.max_item_tier_unlocked
    )
    item_base_found.emit(item_base)
    ↓ (wired by main_view — unchanged)
[forge_view.set_new_item_base(item_base)]
    → add_item_to_inventory(item_base)
    → update_inventory_display()
```

### Flow 3: Crafting with Tier-Constrained Affix Roll

```
[Player applies currency to bench item]
    ↓
[ForgeView._on_currency_applied()]
    → currency.apply(current_item)  # template method unchanged
    ↓
[Currency._do_apply(item)]
    → item.add_prefix() or item.add_suffix()
    ↓
[Item.add_prefix()]
    → valid_prefixes = filter by has_valid_tag
    → chosen = pick_random
    → affix_tier_range = PrestigeManager.get_affix_tier_range(item.item_tier)
    → new_affix = Affix.new(..., affix_tier_range)
    → item.prefixes.append(new_affix)
    → item.update_value()
```

### Flow 4: Tag Hammer Application

```
[Player selects Fire Hammer, clicks bench item]
    ↓
[ForgeView._on_tag_currency_applied("fire")]
    → if not GameState.spend_tag_currency("fire"): return
    → hammer = FireHammer.new()
    → if not hammer.can_apply(current_item):
        GameState.tag_currency_counts["fire"] += 1  # refund
        show error label
        return
    → hammer._do_apply(current_item)
        → filter ItemAffixes by Tag.FIRE + item.has_valid_tag
        → pick random from merged prefix+suffix pool
        → roll with PrestigeManager.get_affix_tier_range(item.item_tier)
        → append to item.prefixes or item.suffixes
        → item.update_value()
    → update_item_stats_display()
    → GameEvents.item_crafted.emit(current_item)  # triggers save
```

Note: Tag hammer application follows the SAME pattern as `ForgeView._on_currency_applied()` — the template method enforces spend-before-apply. The only difference is reading from `tag_currency_counts` instead of `currency_counts`.

### Flow 5: Save v2 → v3 Migration

```
[SaveManager.load_game() on existing v2 save]
    parse JSON
    _migrate_save(data):
        saved_version = 2
        skip _migrate_v1_to_v2 (not needed)
        _migrate_v2_to_v3(data):
            data["prestige_level"] = 0       (fresh start)
            data["max_item_tier_unlocked"] = 1
            data["tag_currencies"] = {all zeroes}
    _restore_state(data):
        prestige_level restored as 0
        max_item_tier_unlocked restored as 1
        tag_currency_counts restored as all-zero
        [all existing fields unchanged]
```

Existing v2 saves load as prestige_level=0, which is correct — pre-prestige players start at level 0.

---

## Architectural Patterns

### Pattern 1: PrestigeManager as Stateless Domain Service

**What:** PrestigeManager is an autoload that reads/writes `GameState` but holds no mutable state itself. It is a pure logic container: cost tables, tier mappings, execution flow.

**When to use:** When business rules are complex enough to warrant isolation but the state they operate on already has a home. StatCalculator and DefenseCalculator follow this same pattern.

**Trade-offs:** Autoload overhead is trivial (Node in the tree). The alternative — putting prestige logic in GameState — blurs the line between "what data exists" and "what rules govern it."

**Example:**
```gdscript
# All callers:
PrestigeManager.can_prestige()                           # pure query
PrestigeManager.execute_prestige()                       # mutates GameState
PrestigeManager.get_affix_tier_range(item.item_tier)     # pure mapping
```

### Pattern 2: Constrained Affix Tier Range at Construction Time

**What:** The `item_tier` on an item determines which affix tier range is legal. The constraint is applied at Affix construction time (inside `add_prefix` / `add_suffix`), not stored on the template. Every new affix rolls within `[best_affix_tier, 32]` determined by `PrestigeManager.get_affix_tier_range(item_tier)`.

**When to use:** Any time rolled values must be bounded by item context (item level, area level, player level). The pattern avoids storing the constraint redundantly on each affix; it is derived from `item.item_tier` at roll time.

**Trade-offs:** Affix templates keep their full tier_range (1-32). The item context narrows it. This means `Affixes.from_affix()` is no longer used inside `add_prefix/suffix` — the construction path is now explicit. `from_affix()` can remain for other uses (e.g., tests, tool scripts).

### Pattern 3: Separate Dictionary for New Currency Type

**What:** `tag_currency_counts` is a new Dictionary field on GameState, parallel to `currency_counts`. It is not merged into `currency_counts`.

**When to use:** When new currencies have distinct unlock timing (prestige 1), distinct display groups (separate button row), and distinct drop sources (LootTable tag-currency roll). Merging would require checking currency type on every display update and every drop-gate check.

**Trade-offs:** Two dicts to zero in `_wipe_run_state()`, two dicts in save/load. This is mechanical duplication but each is 4-6 keys — no meaningful complexity cost.

### Pattern 4: `_wipe_run_state()` Isolated Reset Method

**What:** The prestige reset logic lives in `PrestigeManager._wipe_run_state()`, not scattered across `GameState.initialize_fresh_game()` and `execute_prestige()`. It resets exactly the transient fields (area, gear, inventory, currencies) without touching prestige fields.

**When to use:** When "new game" and "prestige reset" have overlapping but not identical semantics. `initialize_fresh_game()` in GameState resets everything including prestige. `_wipe_run_state()` resets the run, preserving prestige.

**Trade-offs:** Two reset paths to maintain. Risk: if a new transient field is added to GameState, it must be added to both. Mitigation: `initialize_fresh_game()` calls `_wipe_run_state()` internally, then additionally resets prestige fields:

```gdscript
# game_state.gd — MODIFIED initialize_fresh_game()
func initialize_fresh_game() -> void:
    # Reset prestige state first (PrestigeManager._wipe_run_state will NOT touch these)
    prestige_level = 0
    max_item_tier_unlocked = 1
    # Then do the run reset (shared with prestige path)
    # NOTE: can't call PrestigeManager here (circular dep) — inline the wipe
    hero = Hero.new()
    hero.equipped_items = {"weapon": null, "helmet": null, "armor": null, "boots": null, "ring": null}
    currency_counts = {"runic": 1, "forge": 0, "tack": 0, "grand": 0, "claw": 0, "tuning": 0}
    tag_currency_counts = {"fire": 0, "cold": 0, "lightning": 0, "defense": 0}
    crafting_inventory = {"weapon": [LightSword.new()], "helmet": [], "armor": [], "boots": [], "ring": []}
    crafting_bench_type = "weapon"
    max_unlocked_level = 1
    area_level = 1
    save_was_corrupted = false
```

---

## New vs Modified vs Unchanged Components

### New Components

| File | Purpose |
|------|---------|
| `autoloads/prestige_manager.gd` | Prestige rules, cost table, tier mappings, reset execution |
| `models/currencies/tag_hammer.gd` | Abstract base for tag-targeted currency application |
| `models/currencies/fire_hammer.gd` | Guarantees FIRE-tagged affix on apply |
| `models/currencies/cold_hammer.gd` | Guarantees COLD-tagged affix on apply |
| `models/currencies/lightning_hammer.gd` | Guarantees LIGHTNING-tagged affix on apply |
| `models/currencies/defense_hammer.gd` | Guarantees DEFENSE-tagged affix on apply |

### Modified Components

| File | What Changes |
|------|-------------|
| `autoloads/game_state.gd` | + `prestige_level`, `max_item_tier_unlocked`, `tag_currency_counts` fields; + `spend_tag_currency()`; `initialize_fresh_game()` updated |
| `autoloads/save_manager.gd` | `SAVE_VERSION = 3`; + `_migrate_v2_to_v3()`; `_build_save_data()` includes prestige fields; `_restore_state()` restores prestige fields; `prestige_completed` signal connected |
| `autoloads/game_events.gd` | + `prestige_completed` signal; + `tag_currency_dropped` signal |
| `autoloads/item_affixes.gd` | All `tier_range` maxes updated from 8 or 30 → 32; `base_min`/`base_max` values retuned for 32-tier balance |
| `models/items/item.gd` | + `item_tier: int` field; `to_dict()` and `create_from_dict()` updated; `add_prefix()`/`add_suffix()` use `PrestigeManager.get_affix_tier_range(item_tier)` instead of `Affixes.from_affix()` |
| `models/loot/loot_table.gd` | + `roll_item_tier(area_level, max_item_tier_unlocked)` method; + tag currency drop rules gated on prestige |
| `scenes/forge_view.gd` | + Prestige UI panel; + tag hammer button row (prestige 1+); `is_item_better()` updated for `item_tier` field name |
| `scenes/gameplay_view.gd` | Item drop creation sets `item_tier` from `LootTable.roll_item_tier()` |

### Unchanged Components

| File | Reason |
|------|--------|
| `models/affixes/affix.gd` | Structural unchanged; `tier_range` already supports any Vector2i |
| `models/currencies/currency.gd` | Template method pattern unchanged; TagHammer inherits it |
| `models/currencies/runic_hammer.gd` | Unchanged |
| `models/currencies/forge_hammer.gd` | Unchanged |
| `models/currencies/tack_hammer.gd` | Unchanged |
| `models/currencies/grand_hammer.gd` | Unchanged |
| `models/currencies/claw_hammer.gd` | Unchanged |
| `models/currencies/tuning_hammer.gd` | Unchanged |
| `models/hero.gd` | No change needed; `equip_item()`, `update_stats()` unchanged |
| `models/stats/stat_calculator.gd` | No change; affix stat_types unchanged |
| `models/stats/defense_calculator.gd` | No change |
| `models/combat/combat_engine.gd` | No change; area reset is GameState field, not CombatEngine responsibility |
| `models/monsters/biome_config.gd` | No change; biome boundaries unchanged |
| `models/monsters/pack_generator.gd` | No change |
| `models/items/weapon.gd` | Unchanged (item_tier field added to base Item) |
| `models/items/armor.gd` | Unchanged |
| `models/items/helmet.gd` | Unchanged |
| `models/items/boots.gd` | Unchanged |
| `models/items/ring.gd` | Unchanged |
| `scenes/main_view.gd` | No new signal wiring needed for prestige (ForgeView handles its own panel) |
| `scenes/settings_view.gd` | Unchanged |
| `scenes/item_view.gd` | Unchanged |

---

## Anti-Patterns

### Anti-Pattern 1: Storing Prestige Logic in GameState

**What people do:** Put `can_prestige()`, `get_prestige_cost()`, and `execute_prestige()` directly in `game_state.gd`.

**Why it's wrong:** GameState is a data container with a single responsibility: hold the current run state. Business rules (cost tables, tier mappings) belong in domain services. Mixing them makes GameState a God Object. The existing pattern — StatCalculator, DefenseCalculator as separate singletons — already demonstrates the correct approach.

**Do this instead:** `PrestigeManager` as a separate autoload. GameState holds the fields; PrestigeManager holds the rules.

### Anti-Pattern 2: Merging Tag Currencies into `currency_counts`

**What people do:** Add `"fire"`, `"cold"`, `"lightning"`, `"defense"` keys directly to the existing `currency_counts` dictionary.

**Why it's wrong:** The existing `currency_counts` dict is iterated in multiple places (`add_currencies()`, `_build_save_data()`, the debug override loop). Adding tag currencies there would cause tag hammers to drop at area 1 through the existing LootTable logic (which iterates `currency_counts` keys), appear in the base hammer button row, and be affected by `debug_hammers` override. The unlock-at-prestige-1 gate would require special-casing every loop.

**Do this instead:** `tag_currency_counts` as a separate dict. Drop gating and button display are independent from base currencies.

### Anti-Pattern 3: Wiping Prestige State During Prestige Reset

**What people do:** Call `GameState.initialize_fresh_game()` inside `execute_prestige()`.

**Why it's wrong:** `initialize_fresh_game()` resets `prestige_level = 0` and `max_item_tier_unlocked = 1`. Calling it during prestige would immediately undo the prestige increment just made.

**Do this instead:** `PrestigeManager._wipe_run_state()` resets only transient fields. `initialize_fresh_game()` remains for "New Game" flows that genuinely restart everything including prestige.

### Anti-Pattern 4: Storing `affix_tier_range` Constraint on the Item

**What people do:** Add a field like `var affix_tier_max: int` to `Item` and read it during `add_prefix()`/`add_suffix()`.

**Why it's wrong:** The constraint is fully derivable from `item_tier` via `PrestigeManager.get_affix_tier_range()`. Storing it redundantly on Item creates a sync problem — if the prestige mapping changes, the stored field is stale. Derived values should be derived, not stored.

**Do this instead:** `item.item_tier` is the single source of truth. `PrestigeManager.get_affix_tier_range(item.item_tier)` derives the constraint at use time.

### Anti-Pattern 5: Blocking Currency Application on Prestige Check in Currency Classes

**What people do:** Add `if GameState.prestige_level < 1: return false` inside `TagHammer.can_apply()`.

**Why it's wrong:** The prestige gate is a UI concern (hide the button), not a crafting rule. The currency class should express "does this currency logically apply to this item?" not "is the player allowed to have this?" The button simply does not render at prestige 0, so the check is never reached.

**Do this instead:** ForgeView gates button visibility on `GameState.prestige_level >= 1`. The currency class itself contains only intrinsic applicability rules.

---

## Build Order and Phase Dependencies

Dependencies are: data shape first, persistence second, logic third, UI last.

```
Phase A: PrestigeManager autoload — core rules, no UI dependency
    Files: autoloads/prestige_manager.gd (NEW)
    Content: PRESTIGE_COSTS, ITEM_TIERS_BY_PRESTIGE, can_prestige(),
             execute_prestige() (calls _wipe_run_state internally),
             get_affix_tier_range(), get_item_tier_range()
    Gate: Unit testable with debug script — can_prestige returns correct bool

Phase B: GameState new fields — required before save or any UI
    Files: autoloads/game_state.gd (MODIFIED)
    Changes: + prestige_level, max_item_tier_unlocked, tag_currency_counts
             + spend_tag_currency()
             initialize_fresh_game() updated
    Gate: Fresh game initializes without crash; fields accessible

Phase C: GameEvents new signals — required before ForgeView wires handlers
    Files: autoloads/game_events.gd (MODIFIED)
    Changes: + prestige_completed, tag_currency_dropped
    Gate: Can emit signals without crash

Phase D: Item.item_tier field — required before LootTable or affixes
    Files: models/items/item.gd (MODIFIED)
    Changes: + item_tier field, to_dict/create_from_dict updated
    Gate: create_from_dict() loads existing saves without crash (defaults item_tier = 8)

Phase E: SaveManager v2→v3 migration — WRITE MIGRATION BEFORE changing save format
    Files: autoloads/save_manager.gd (MODIFIED)
    CRITICAL: Write _migrate_v2_to_v3() FIRST, then update _build_save_data/_restore_state
    Changes: SAVE_VERSION = 3, migration, prestige fields in save/load
    Gate: Existing v2 save file loads without error, prestige_level = 0 after load

Phase F: Affix tier range expansion — can run parallel with E
    Files: autoloads/item_affixes.gd (MODIFIED)
    Changes: All tier_range maxes → 32, base_min/base_max retuned for balance
    Gate: Items can be crafted without value overflow; tier 32 affixes have >0 value

Phase G: Item.add_prefix/suffix use PrestigeManager tier range
    Files: models/items/item.gd (MODIFIED) — add_prefix(), add_suffix()
    Depends on: Phase A (PrestigeManager), Phase D (item_tier field), Phase F (tier 32 range)
    Changes: Replace Affixes.from_affix() with explicit constrained Affix.new()
    Gate: Items crafted with item_tier=1 get only weak affixes; item_tier=8 gets any tier

Phase H: LootTable item tier rolling
    Files: models/loot/loot_table.gd (MODIFIED)
    Depends on: Phase A (max_item_tier_unlocked accessor), Phase B (GameState fields)
    Changes: + roll_item_tier() static method
    Gate: roll_item_tier(1, 1) always returns 1; roll_item_tier(75, 8) skews toward tier 4-6

Phase I: gameplay_view.gd item drop sets item_tier
    Files: scenes/gameplay_view.gd (MODIFIED)
    Depends on: Phase H (roll_item_tier)
    Changes: Dropped items have item_tier set from LootTable.roll_item_tier()
    Gate: Dropped items have item_tier > 1 at area 25+ with prestige 2+

Phase J: New currency subclasses — tag hammers
    Files: models/currencies/tag_hammer.gd + 4 subclasses (NEW)
    Depends on: Phase A (PrestigeManager.get_affix_tier_range), Phase G (constrained rolls)
    Changes: New files, no modification to existing currency classes
    Gate: FireHammer().apply(magic_weapon) adds a FIRE-tagged affix

Phase K: ForgeView prestige UI + tag hammer buttons
    Files: scenes/forge_view.gd (MODIFIED)
    Depends on: Phase A, B, C, J
    Changes: Prestige panel (cost display, trigger button, unlock display),
             tag hammer button row visible at prestige_level >= 1
    Gate: Full prestige flow works in-game; tag hammers available after prestige 1

Phase L: Integration verification
    - Fresh game: prestige_level=0, max_item_tier_unlocked=1, no tag hammers visible
    - Items drop with item_tier=1 (only unlocked tier)
    - Prestige 1 cost check gates trigger button correctly
    - execute_prestige(): currencies spent, wipe executed, prestige_level=1, save written
    - After prestige: tag hammer buttons visible, item_tier=2 drops appear
    - Affix rolls on tier-2 items use range [25,32] only
    - Save/load round-trip: all prestige fields survive
    - V2 save migration: loads cleanly as prestige_level=0
```

**Critical path:** A → B → D → G (affixes must use PrestigeManager which needs GameState fields)
**Parallel track:** E (SaveManager) can be developed alongside B-D
**Last:** K (UI) is the integration layer; all mechanics must work before wiring UI

---

## Save Format Versioning

| Version | New Fields | Migration |
|---------|-----------|-----------|
| v1 | (original) | wrap single items in arrays |
| v2 | per-slot arrays | (baseline for v1.5) |
| v3 | `prestige_level`, `max_item_tier_unlocked`, `tag_currencies` | add with defaults (0, 1, all-zero dict) |

v3 migration is additive-only. No existing field changes shape. A v2 player's save loads as `prestige_level = 0` — the correct "no prestige yet" state. Export strings (HT1: format) go through the same migration on import; no prefix change needed.

---

## Sources

- Direct codebase analysis: all files in `autoloads/`, `models/`, `scenes/` — confirmed current implementation
- `autoloads/save_manager.gd:4` — `SAVE_VERSION = 2`, existing migration chain pattern confirmed
- `models/affixes/affix.gd:13` — `tier_range: Vector2i = Vector2i(1, 8)` — confirmed expandable
- `models/items/item.gd:15` — `var tier: int` confirmed existing field (rename to item_tier)
- `models/currencies/currency.gd` — template method pattern confirmed for TagHammer inheritance
- `autoloads/item_affixes.gd:12` — `Vector2i(1, 8)` weapon affixes, `Vector2i(1, 30)` defensive affixes
- `autoloads/game_events.gd` — all existing signals confirmed; addition points clear
- `.planning/PROJECT.md` — v1.7 target features confirmed: 7 prestige levels, 8 item tiers, 32 affix tiers, tag-targeted hammers unlocked at prestige 1

---
*Architecture research for: Hammertime v1.7 — Prestige meta-progression, item tier gating, 32-level affix tiers, tag-targeted currencies*
*Researched: 2026-02-20*
*Confidence: HIGH — based on direct code analysis of all affected files in the existing codebase*
