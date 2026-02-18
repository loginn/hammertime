# Architecture Research

**Domain:** Damage Range System — Integration with Existing ARPG Crafting Architecture
**Researched:** 2026-02-18
**Confidence:** HIGH (based on direct codebase analysis)

---

## System Overview

This document maps how min-max damage ranges integrate into the existing Hammertime architecture. The existing system uses single-value `affix.value` integers throughout. The new system introduces damage ranges (min-max) for weapons, monsters, and flat damage affixes, with per-element variance and per-hit rolling in combat.

```
┌─────────────────────────────────────────────────────────────────┐
│                     Scene Layer                                  │
│  ┌──────────────┐  ┌───────────────┐  ┌────────────────────┐   │
│  │  forge_view  │  │ gameplay_view │  │ floating_label     │   │
│  │ (affix fmt)  │  │ (hit display) │  │ (shows range roll) │   │
│  └──────┬───────┘  └──────┬────────┘  └──────────┬─────────┘   │
│         │                 │                       │             │
├─────────┴─────────────────┴───────────────────────┴─────────────┤
│                     Combat Layer                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ CombatEngine._on_hero_attack()                              │  │
│  │  damage_per_hit = roll_damage_range() / attack_speed       │  │  ← MODIFIED
│  │  (was: hero.total_dps / hero_attack_speed)                 │  │
│  └────────────────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ PackGenerator.create_pack()                                 │  │
│  │  pack.damage_min, pack.damage_max = scaled range           │  │  ← MODIFIED
│  └────────────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│                     Stat Calculator Layer                         │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ StatCalculator                                              │  │
│  │  calculate_dps(base_min, base_max, ...) → avg DPS float    │  │  ← MODIFIED
│  │  calculate_damage_range(base_min, base_max, affixes)       │  │  ← NEW
│  │    → Vector2i(total_min, total_max)                        │  │
│  └────────────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│                     Data Layer (Resources)                        │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐   │
│  │ Weapon           │  │ Affix (flat dmg) │  │ MonsterPack  │   │
│  │ base_damage_min  │  │ damage_min: int  │  │ damage_min   │   │  ← MODIFIED
│  │ base_damage_max  │  │ damage_max: int  │  │ damage_max   │   │
│  └──────────────────┘  └──────────────────┘  └──────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Integration Point 1: Affix — Where Min-Max Values Live

### Current State

`Affix` already has `min_value` and `max_value` (int) — but these represent the **rolled stat value bounds** (e.g., "+5 to +20 flat damage for this tier"), not a **damage range delivered per hit**. The single `value` field is what gets summed into DPS.

```gdscript
# affix.gd (EXISTING)
var min_value: int  # Lower bound for this tier's rolled value
var max_value: int  # Upper bound for this tier's rolled value
var value: int      # The rolled result — used by StatCalculator
```

### Required Change

Flat damage affixes (those with `Tag.StatType.FLAT_DAMAGE`) need to express a per-hit damage range, not a single integer. The range is the actual damage spread delivered each hit after the affix rolls.

**Option A (Recommended): Reuse existing fields with semantic clarity**

The existing `min_value` / `max_value` on Affix already contain the correct data for range-typed flat damage affixes — they are the lower and upper bounds of what the affix contributes. The `value` field currently holds the single rolled result (used in DPS average). No new fields needed on Affix for flat damage affixes; the convention just changes:

- DPS calculation uses average: `(min_value + max_value) / 2.0` instead of `value`
- Per-hit combat rolls from `randi_range(min_value, max_value)` instead of using `value`

**Option B: Add explicit range fields**

Add `damage_min: int` and `damage_max: int` to Affix specifically for FLAT_DAMAGE affixes. Clearer intent, but adds fields to every Affix even when irrelevant.

**Recommendation: Option A** — the existing `min_value`/`max_value` are the correct semantic fields for damage range. They are already serialized. No schema change, no migration needed. The `value` field becomes "the average for DPS display" and per-hit combat rolls from the min/max pair.

**Confidence: HIGH** — Affix already serializes `min_value` and `max_value` in `to_dict()` / `from_dict()`. No save format change required for this integration point.

---

## Integration Point 2: Weapon — Base Damage Range

### Current State

```gdscript
# weapon.gd (EXISTING)
var base_damage: int        # Single value — both DPS average and hit value
var base_damage_type: String
```

### Required Change

Replace `base_damage: int` with a min/max pair:

```gdscript
# weapon.gd (MODIFIED)
var base_damage_min: int    # Minimum base weapon hit
var base_damage_max: int    # Maximum base weapon hit
# base_damage preserved as property for backward compat, returns average:
var base_damage: int:
    get: return (base_damage_min + base_damage_max) / 2
```

**Element-specific variance** is a property of the **weapon type definition** (LightSword, etc.), not a field on Weapon base class. Each concrete weapon class sets the ratio:

```gdscript
# light_sword.gd (MODIFIED)
func _init() -> void:
    self.base_damage_min = 8    # Physical: tight spread (8-12, ratio ~0.67)
    self.base_damage_max = 12
    # Lightning weapon example: 4-18 (ratio ~0.22) — much wider
```

The variance ratio lives in the concrete item class, not a generic `variance_factor` field. This keeps it explicit and designer-readable.

### Save Format Impact

`weapon.to_dict()` inherits from `item.to_dict()`, which doesn't directly serialize `base_damage`. The weapon's `base_damage` is used transiently for DPS calculation. Affixes (the rolling parts) are already serialized. However:

- `base_damage_min` and `base_damage_max` must be added to weapon serialization if weapons can have variable base ranges (e.g., found items). For fixed base ranges (defined per class like LightSword), they can be reconstructed from `_init()` — **no serialization needed**.
- For variable-base weapons in the future, add `base_damage_min`/`base_damage_max` to `Item.to_dict()` and `create_from_dict()`.

**Save version bump required: YES** — but only if base damage range is not always reconstructible from item type. For now (fixed base ranges per class), no save schema change.

---

## Integration Point 3: StatCalculator — Aggregating Ranges vs Flat Values

### Current State

```gdscript
# stat_calculator.gd (EXISTING)
static func calculate_dps(base_damage: float, base_speed: float, affixes: Array, ...) -> float:
    var damage := base_damage
    for affix: Affix in affixes:
        if Tag.StatType.FLAT_DAMAGE in affix.stat_types:
            damage += affix.value      # Single value summed
    # ... rest of calculation
```

### Required Changes

**New method: `calculate_damage_range()`**

```gdscript
# stat_calculator.gd (NEW METHOD)
## Aggregates min and max damage from base weapon range + flat damage affixes.
## Returns Vector2i(total_min, total_max).
## Used for: UI display, per-hit combat rolling.
static func calculate_damage_range(
    base_min: int,
    base_max: int,
    affixes: Array
) -> Vector2i:
    var total_min := base_min
    var total_max := base_max

    for affix: Affix in affixes:
        if Tag.StatType.FLAT_DAMAGE in affix.stat_types:
            total_min += affix.min_value   # Add lower bound
            total_max += affix.max_value   # Add upper bound

    return Vector2i(total_min, total_max)
```

**Modified method: `calculate_dps()` signature**

```gdscript
# stat_calculator.gd (MODIFIED)
static func calculate_dps(
    base_min: int,        # was: base_damage: float
    base_max: int,        # NEW
    base_speed: float,
    affixes: Array,
    base_crit_chance: float = 5.0,
    base_crit_damage: float = 150.0
) -> float:
    # DPS uses average damage for expected-value calculation
    var damage := float(base_min + base_max) / 2.0   # was: base_damage

    for affix: Affix in affixes:
        if Tag.StatType.FLAT_DAMAGE in affix.stat_types:
            damage += float(affix.min_value + affix.max_value) / 2.0  # was: affix.value
    # ... rest unchanged
```

**Aggregation rules:**

| Affix Type | Min Contribution | Max Contribution |
|------------|-----------------|-----------------|
| FLAT_DAMAGE | `affix.min_value` | `affix.max_value` |
| INCREASED_DAMAGE | Applied to both min and max proportionally | Same |
| CRIT_CHANCE / CRIT_DAMAGE | Flat additions (unchanged) | Unchanged |

**Increased damage multiplier** applies identically to both min and max — it scales the range uniformly, preserving relative spread:

```gdscript
# After flat additions:
total_min *= (1.0 + additive_damage_mult)
total_max *= (1.0 + additive_damage_mult)
```

---

## Integration Point 4: CombatEngine — Per-Hit Rolling from Ranges

### Current State

```gdscript
# combat_engine.gd — _on_hero_attack() (EXISTING)
var damage_per_hit := hero.total_dps / hero_attack_speed
var is_crit := randf() < (hero.total_crit_chance / 100.0)
if is_crit:
    damage_per_hit *= (hero.total_crit_damage / 100.0)
```

`total_dps` is pre-calculated average DPS. Dividing by attack speed gives expected-value damage per hit — no per-hit variance.

### Required Changes

**Hero needs to expose damage range** alongside `total_dps`. The cleanest integration: add `total_damage_min: float` and `total_damage_max: float` to `Hero`, updated by `calculate_dps()` calls, mirroring how `total_dps` is maintained.

```gdscript
# hero.gd (ADD FIELDS)
var total_damage_min: float = 0.0    # Per-hit minimum (before crit)
var total_damage_max: float = 0.0    # Per-hit maximum (before crit)
```

```gdscript
# hero.gd — calculate_dps() (MODIFIED)
func calculate_dps() -> float:
    total_dps = 0.0
    total_damage_min = 0.0
    total_damage_max = 0.0

    if "weapon" in equipped_items and equipped_items["weapon"] is Weapon:
        var weapon: Weapon = equipped_items["weapon"]
        total_dps += weapon.dps
        # NEW: track per-hit range
        var range := weapon.get_damage_range()     # Vector2i
        total_damage_min += float(range.x) / weapon.base_attack_speed
        total_damage_max += float(range.y) / weapon.base_attack_speed

    # ... ring handling same pattern
```

**CombatEngine per-hit roll:**

```gdscript
# combat_engine.gd — _on_hero_attack() (MODIFIED)
var rolled_damage := randf_range(hero.total_damage_min, hero.total_damage_max)

var is_crit := randf() < (hero.total_crit_chance / 100.0)
if is_crit:
    rolled_damage *= (hero.total_crit_damage / 100.0)

pack.take_damage(rolled_damage)
GameEvents.hero_attacked.emit(rolled_damage, is_crit)
```

This eliminates the `total_dps / hero_attack_speed` path for hero attacks. `total_dps` is retained as a display-only average — it still appears in Hero Stats and forge_view comparison panels.

### MonsterPack — Range for Incoming Damage

```gdscript
# monster_pack.gd (ADD FIELDS)
var damage_min: float = 0.0    # was: only damage: float
var damage_max: float = 0.0
```

`PackGenerator.create_pack()` sets both:

```gdscript
# pack_generator.gd — create_pack() (MODIFIED)
var element_variance := _get_element_variance(element)   # NEW helper
pack.damage_min = monster_type.base_damage * multiplier * (1.0 - element_variance)
pack.damage_max = monster_type.base_damage * multiplier * (1.0 + element_variance)
pack.damage = pack.damage_min  # backward compat — DefenseCalculator uses pack.damage
```

**CombatEngine pack attack** rolls from range before passing to DefenseCalculator:

```gdscript
# combat_engine.gd — _on_pack_attack() (MODIFIED)
var rolled_pack_damage := randf_range(pack.damage_min, pack.damage_max)

var result := DefenseCalculator.calculate_damage_taken(
    rolled_pack_damage,     # was: pack.damage
    pack.element,
    ...
)
```

**Element variance table** (drives `_get_element_variance()`):

| Element | Variance | Example (base 10) | Result Range |
|---------|----------|-------------------|--------------|
| physical | 0.10 | 10 | 9–11 |
| cold | 0.20 | 10 | 8–12 |
| fire | 0.30 | 10 | 7–13 |
| lightning | 0.50 | 10 | 5–15 |

---

## Integration Point 5: Weapon.update_value() — DPS and Range Cache

### Current State

```gdscript
# weapon.gd (EXISTING)
func update_value() -> void:
    var all_affixes := self.prefixes + self.suffixes
    all_affixes.append(self.implicit)
    self.dps = StatCalculator.calculate_dps(
        self.base_damage, self.base_speed, all_affixes, self.crit_chance, self.crit_damage
    )
```

### Required Change

```gdscript
# weapon.gd (MODIFIED)
var damage_range: Vector2i = Vector2i(0, 0)  # Cached per-hit range (NEW)

func update_value() -> void:
    var all_affixes := self.prefixes + self.suffixes
    all_affixes.append(self.implicit)

    self.damage_range = StatCalculator.calculate_damage_range(
        self.base_damage_min, self.base_damage_max, all_affixes
    )
    self.dps = StatCalculator.calculate_dps(
        self.base_damage_min, self.base_damage_max,
        self.base_speed, all_affixes, self.crit_chance, self.crit_damage
    )

func get_damage_range() -> Vector2i:
    return damage_range
```

---

## Integration Point 6: UI — Displaying Ranges

### forge_view.gd — Item Stats Text

`get_item_stats_text()` currently shows `"Base Damage: %d" % weapon.base_damage`. Must change to range format:

```gdscript
# forge_view.gd — get_item_stats_text() (MODIFIED)
# Before:
stats_text += "Base Damage: %d\n" % weapon.base_damage

# After:
var dr := weapon.damage_range
stats_text += "Damage: %d-%d\n" % [dr.x, dr.y]
stats_text += "DPS: %.1f\n" % weapon.dps      # unchanged — avg DPS for comparison
```

Flat damage affixes in the prefix list now also show range:

```gdscript
# forge_view.gd — prefix display (MODIFIED)
for prefix in weapon.prefixes:
    if Tag.StatType.FLAT_DAMAGE in prefix.stat_types:
        stats_text += "%s: %d-%d\n" % [prefix.affix_name, prefix.min_value, prefix.max_value]
    else:
        stats_text += "%s: %d\n" % [prefix.affix_name, prefix.value]
```

### gameplay_view.gd — Floating Damage Labels

No change required. `_spawn_floating_text()` already receives a rolled per-hit value (int). The combat engine will now supply a rolled value from a range rather than a flat DPS-derived value. The floating label format is unchanged.

### Hero Stats Panel (forge_view.gd update_hero_stats_display)

```gdscript
# forge_view.gd — update_hero_stats_display() (MODIFIED)
# After DPS line:
hero_stats_label.text += "Total DPS: %.1f\n" % hero.get_total_dps()
# NEW range line:
hero_stats_label.text += "Hit Range: %d-%d\n" % [int(hero.total_damage_min), int(hero.total_damage_max)]
```

---

## Integration Point 7: Save Format

### What Changes

**Affix serialization (NO CHANGE NEEDED):** `min_value` and `max_value` are already in `Affix.to_dict()` and `Affix.from_dict()`. If flat damage affixes reuse these fields for damage range, nothing new needs to be serialized.

**Weapon serialization (MINOR CHANGE):** If `base_damage_min` / `base_damage_max` are fixed per class (LightSword always 8-12), they do not need serialization — `_init()` reconstructs them. If future weapons can have randomized base ranges, add to `Item.to_dict()`:

```gdscript
# item.to_dict() (ADD IF NEEDED)
"base_damage_min": base_damage_min if "base_damage_min" in self else 0,
"base_damage_max": base_damage_max if "base_damage_max" in self else 0,
```

**MonsterPack:** Not serialized. Generated fresh each combat. No save change.

**Hero cached ranges (total_damage_min, total_damage_max):** Not serialized. Recalculated by `Hero.update_stats()` after load, same as `total_dps`. No save change.

### Save Version

**Recommendation: bump SAVE_VERSION to 2 in save_manager.gd** when base_damage_min/max are added to weapon serialization. Add migration in `_migrate_save()`:

```gdscript
# save_manager.gd (MIGRATION)
if saved_version < 2:
    # Migrate weapons: base_damage_min/max missing → derive from existing base_damage
    # (backward compat: old saves only have single base_damage on Item)
    data = _migrate_v1_to_v2(data)
```

---

## Component Boundaries: New vs Modified

### New Components

| File | Type | Purpose |
|------|------|---------|
| None | — | No new files required. All changes are modifications to existing files. |

### Modified Components

| File | Change Type | Specific Changes |
|------|-------------|-----------------|
| `models/affixes/affix.gd` | Semantic | `min_value`/`max_value` now serve as damage range for FLAT_DAMAGE affixes; `value` becomes avg for DPS display only |
| `models/items/weapon.gd` | Fields + method | `base_damage` → `base_damage_min` + `base_damage_max`; add `damage_range: Vector2i`; update `update_value()` |
| `models/items/light_sword.gd` | Init values | Set `base_damage_min` / `base_damage_max` instead of `base_damage` |
| `models/monsters/monster_pack.gd` | Fields | Add `damage_min: float` + `damage_max: float` alongside existing `damage: float` |
| `models/monsters/pack_generator.gd` | create_pack() | Set `damage_min`/`damage_max` from element variance; add `_get_element_variance()` helper |
| `models/monsters/monster_type.gd` | No change | `base_damage` stays single — PackGenerator applies variance per element |
| `models/stats/stat_calculator.gd` | New method + modified signature | Add `calculate_damage_range()` returning Vector2i; change `calculate_dps()` to accept `base_min`/`base_max` |
| `models/hero.gd` | Fields + calculate_dps() | Add `total_damage_min`/`total_damage_max` floats; update `calculate_dps()` to populate them |
| `models/combat/combat_engine.gd` | _on_hero_attack(), _on_pack_attack() | Hero attack rolls `randf_range(total_damage_min, total_damage_max)`; pack attack rolls from pack range before passing to DefenseCalculator |
| `autoloads/save_manager.gd` | Version + migration | Bump `SAVE_VERSION` to 2; add `_migrate_v1_to_v2()` if base ranges serialized |
| `scenes/forge_view.gd` | Display strings | Weapon shows "Damage: X-Y"; flat damage affixes show min-max; hero stats show Hit Range |

### Unchanged Components

| File | Reason Unchanged |
|------|-----------------|
| `models/stats/defense_calculator.gd` | Receives rolled float damage — no change to interface |
| `models/items/item.gd` | `to_dict()` / `create_from_dict()` — affix serialization unchanged |
| `models/affixes/implicit.gd` | Extends Affix — inherits range fields |
| `autoloads/item_affixes.gd` | Affix pool definitions — adjust base_min/base_max values per element but no structural change |
| `autoloads/game_events.gd` | Signal signatures unchanged |
| `autoloads/game_state.gd` | No structural change |
| `scenes/gameplay_view.gd` | Floating label receives rolled int — no change |
| `models/loot/loot_table.gd` | Drop system unaffected |
| `models/monsters/biome_config.gd` | BiomeConfig doesn't store damage — PackGenerator handles it |

---

## Data Flow: Damage Range Through the System

### Flow 1: Weapon Created / Affix Added

```
[LightSword._init()]
    base_damage_min = 8, base_damage_max = 12
         ↓
[weapon.update_value()]
    damage_range = StatCalculator.calculate_damage_range(8, 12, affixes)
    dps = StatCalculator.calculate_dps(8, 12, base_speed, affixes, ...)
         ↓
[forge_view.get_item_stats_text()]
    "Damage: 10-18"  (after flat affix min_value/max_value added)
    "DPS: 14.0"      (average × speed × crit multiplier)
```

### Flow 2: Hero Equips Weapon → Stats Update

```
[hero.equip_item(weapon, "weapon")]
    hero.update_stats()
         ↓
[hero.calculate_dps()]
    total_dps = weapon.dps
    total_damage_min = weapon.damage_range.x / weapon.base_attack_speed
    total_damage_max = weapon.damage_range.y / weapon.base_attack_speed
         ↓
[forge_view.update_hero_stats_display()]
    "Total DPS: 25.2"
    "Hit Range: 9-17"   ← NEW display
```

### Flow 3: Per-Hit Combat Roll (Hero Attacks)

```
[hero_attack_timer.timeout → CombatEngine._on_hero_attack()]
    rolled_damage = randf_range(hero.total_damage_min, hero.total_damage_max)
         ↓
[crit roll]
    if randf() < crit_chance:
        rolled_damage *= (crit_damage / 100.0)
         ↓
[pack.take_damage(rolled_damage)]
[GameEvents.hero_attacked.emit(rolled_damage, is_crit)]
         ↓
[gameplay_view._on_hero_attacked(damage, is_crit)]
    _spawn_floating_text(pack_damage_pos, int(damage), is_crit)
```

### Flow 4: Per-Hit Combat Roll (Monster Attacks)

```
[pack_attack_timer.timeout → CombatEngine._on_pack_attack()]
    rolled_pack_damage = randf_range(pack.damage_min, pack.damage_max)
         ↓
[DefenseCalculator.calculate_damage_taken(rolled_pack_damage, pack.element, ...)]
    → result: {dodged, life_damage, es_damage}
         ↓
[hero.apply_damage(result.life_damage, result.es_damage)]
[GameEvents.pack_attacked.emit(result)]
```

### Flow 5: Save / Load Round-Trip

```
[Affix.to_dict()]  — min_value, max_value already serialized (no change)
[Weapon.to_dict()] — if base ranges are fixed per class: not needed
                     if base ranges are variable: add base_damage_min/max
[Hero.calculate_dps()] called after load → total_damage_min/max recalculated
```

---

## Architectural Patterns

### Pattern 1: Average-for-DPS, Roll-for-Combat

**What:** `StatCalculator.calculate_dps()` uses `(min + max) / 2` for the DPS average shown in UI. `CombatEngine` rolls `randf_range(min, max)` per hit.

**Why:** DPS is an expected-value metric — the correct formula uses average damage. Combat gives variance and tactile feel. These are separate use cases and should use separate code paths.

**Anti-pattern to avoid:** Do not pass a rolled value into `calculate_dps()`. DPS must always use average damage — it is a planning metric, not a combat metric.

### Pattern 2: Range Propagation via Min/Max Pair Accumulation

**What:** Each layer accumulates `total_min` and `total_max` independently. Multiplicative modifiers (INCREASED_DAMAGE) scale both ends proportionally. Result is Vector2i handed to the next layer.

**Why:** Preserves spread. If you collapse to a single value anywhere in the pipeline, you lose the variance the feature is adding.

**Example accumulation:**
```
Base weapon: 8-12
+ Flat affix min_value=4, max_value=8  →  12-20
× INCREASED_DAMAGE 50%                 →  18-30
```

### Pattern 3: Element Variance at Pack Generation, Not in DefenseCalculator

**What:** Variance factor is applied in `PackGenerator.create_pack()` when setting `damage_min`/`damage_max`. `DefenseCalculator` receives a single pre-rolled float — unchanged interface.

**Why:** DefenseCalculator's contract is "given raw damage, apply mitigation stages." Adding variance inside it would break separation of concerns and make DefenseCalculator harder to reason about (it already has four stages).

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Collapsing Range to Single Value Too Early

**What people do:** Store `(min + max) / 2` as the affix value immediately on creation, then use that single value everywhere.

**Why it's wrong:** UI cannot show "12-20" if the range was collapsed to "16". Per-hit combat cannot roll variance. The range information is lost before it can be used.

**Do this instead:** Keep `min_value` and `max_value` as the canonical fields for FLAT_DAMAGE affixes. Compute average only when needed for DPS (in StatCalculator). Roll per-hit only in CombatEngine.

### Anti-Pattern 2: Adding Variance to DefenseCalculator

**What people do:** "Lightning does more variable damage, so let's make DefenseCalculator roll variance when element is lightning."

**Why it's wrong:** DefenseCalculator is downstream of rolling. It receives a specific damage number and applies mitigation math. Adding RNG inside it makes it stateful and harder to test. It also breaks the "evasion happens before mitigation" pipeline.

**Do this instead:** Roll in CombatEngine before calling DefenseCalculator. Pack attack code: `rolled = randf_range(pack.damage_min, pack.damage_max)` → pass rolled value to DefenseCalculator.

### Anti-Pattern 3: Storing total_damage_min/max in Save Data

**What people do:** Serialize `hero.total_damage_min` and `hero.total_damage_max` to avoid recalculating.

**Why it's wrong:** These are derived values, computed from equipped items + affixes. Saving them creates a second source of truth. On load, if an affix was changed or the formula adjusted, the saved cached value becomes stale.

**Do this instead:** Do not serialize `total_damage_min` / `total_damage_max`. They recalculate in `hero.update_stats()` which is already called after load in `_restore_state()`.

### Anti-Pattern 4: Per-Element Variance in MonsterType

**What people do:** Add `damage_variance: float` to MonsterType so each monster has its own variance regardless of element.

**Why it's wrong:** The milestone requirement is element-specific variance (Lightning is extreme, Physical is tight). Variance is a property of the damage element, not the monster species. Goblins hitting with lightning should have the same spread as bears hitting with lightning.

**Do this instead:** Keep variance in `PackGenerator._get_element_variance(element: String) -> float`. It is a lookup table by element string. MonsterType stays clean.

---

## Build Order and Dependencies

Dependencies flow bottom-up. Build data model first, then calculator, then combat, then UI last.

```
Step 1: Affix (semantic clarity only)
    No code change — min_value/max_value already exist and are serialized.
    Document the convention: FLAT_DAMAGE affixes use min_value/max_value as damage range.
    Adjust affix pool definitions in item_affixes.gd to set element-appropriate spreads.

Step 2: Weapon (base damage range fields)
    Depends on: Affix convention established (Step 1)
    Changes:
    - weapon.gd: base_damage_min + base_damage_max fields; base_damage computed property
    - weapon.gd: add damage_range: Vector2i field
    - light_sword.gd: set base_damage_min/max in _init()

Step 3: StatCalculator (new method + modified signature)
    Depends on: Weapon fields in place (Step 2)
    Changes:
    - Add calculate_damage_range(base_min, base_max, affixes) → Vector2i
    - Modify calculate_dps() to accept base_min + base_max, use average internally

Step 4: Weapon.update_value() (uses new StatCalculator)
    Depends on: StatCalculator updated (Step 3)
    Changes:
    - weapon.gd: call calculate_damage_range() and cache result
    - weapon.gd: call calculate_dps() with new signature

Step 5: MonsterPack + PackGenerator (monster damage ranges)
    Depends on: Nothing from Steps 1-4 (independent data model change)
    Changes:
    - monster_pack.gd: add damage_min + damage_max
    - pack_generator.gd: set damage_min/max from element variance table

Step 6: Hero (total_damage_min/max fields)
    Depends on: Weapon.get_damage_range() available (Step 4)
    Changes:
    - hero.gd: add total_damage_min + total_damage_max
    - hero.gd: calculate_dps() populates both from weapon damage_range

Step 7: CombatEngine (per-hit rolling)
    Depends on: Hero fields (Step 6), MonsterPack fields (Step 5)
    Changes:
    - _on_hero_attack(): roll from hero.total_damage_min/max
    - _on_pack_attack(): roll from pack.damage_min/max before DefenseCalculator

Step 8: Save format (if needed)
    Depends on: All model changes (Steps 1-6)
    Changes:
    - Only if base_damage_min/max are variable (not reconstructible from class _init)
    - Bump SAVE_VERSION + add migration

Step 9: UI (display ranges)
    Depends on: All model changes (Steps 1-6)
    Changes:
    - forge_view.gd: weapon shows "Damage: X-Y", flat affixes show min-max
    - forge_view.gd: hero stats shows "Hit Range: X-Y"
```

**Critical path:** Steps 1 → 2 → 3 → 4 → 6 → 7 → 9

Steps 5 and 8 are parallel to the critical path (monster damage range can be done anytime before Step 7; save format after all models).

---

## Sources

- Direct codebase analysis: `models/affixes/affix.gd`, `models/stats/stat_calculator.gd`, `models/combat/combat_engine.gd`, `models/items/weapon.gd`, `models/monsters/monster_pack.gd`, `models/monsters/pack_generator.gd`, `models/hero.gd`, `autoloads/save_manager.gd`, `scenes/forge_view.gd`
- Existing save format: `Affix.to_dict()` confirms `min_value`/`max_value` already serialized (line 58-63 of affix.gd)
- `SAVE_VERSION = 1` in `save_manager.gd` — current save schema baseline for migration planning

---
*Architecture research for: Hammertime — Damage Range System integration*
*Researched: 2026-02-18*
*Confidence: HIGH — based on direct code analysis of all relevant files*
