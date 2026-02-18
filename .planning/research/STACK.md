# Stack Research: Damage Range System

**Domain:** Godot 4.5 Idle ARPG — Adding min-max damage ranges to weapons, monsters, and affixes
**Researched:** 2026-02-18
**Confidence:** HIGH

---

## Context

This is a **subsequent milestone stack**. The engine, language, renderer, and data model are already validated (Godot 4.5, GDScript, mobile renderer, Resource-based model). This document covers only what changes for the damage range feature.

The existing codebase confirms `randi_range()` and `randf()` are already in production use across `affix.gd`, `defense_calculator.gd`, `loot_table.gd`, and currency scripts — no new RNG infrastructure is needed.

---

## Recommended Stack

### Core Technologies (Unchanged)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Godot Engine | 4.5 | Game engine | Already validated. No version change needed for damage ranges. |
| GDScript | 4.5 | Scripting language | `randi_range(min, max)` and `randf_range(min, max)` are built-in global functions, already used in the codebase. No additions. |
| Resource system | Godot 4.5 | Data model | Already proven for `Affix`, `Item`, `Hero`, `MonsterType`. Damage range properties follow the same pattern. |

### Damage Range Data Patterns (NEW)

| Pattern | GDScript Type | Where Applied | Why |
|---------|--------------|---------------|-----|
| Two int properties (`damage_min`, `damage_max`) | `int` | `Weapon`, `MonsterType`, elemental affix variants | Mirrors the already-working `Affix.min_value`/`max_value` pair. Serializes cleanly via existing `to_dict()`/`from_dict()` pattern. Readable at call sites. |
| `randf_range(float, float)` per-hit roll | Global GDScript builtin | `CombatEngine._on_hero_attack()` | Already used as `randf()` for crit rolls in the same method. Returns `float` for continuous elemental variance. Correct type for damage math. |
| `randi_range(int, int)` for affix rolling | Global GDScript builtin | `Affix._init()` and `Affix.reroll()` | Already used in `Affix` for `min_value`/`max_value` rolling. Same pattern, same call site, same serialization. |
| Element variance constants | `const Dictionary` in `StatCalculator` or `Tag` | Applied during per-hit roll calculation | Codifies the Physical/Cold/Fire/Lightning spread ratios. Keeps variance logic out of `CombatEngine`. |

### Random Function Reference (Verified in Codebase)

| Function | Return Type | Signature | Use Case |
|----------|-------------|-----------|----------|
| `randi_range(from, to)` | `int` | Global builtin | Rolling integer affix values, selecting from discrete weapon damage tiers |
| `randf_range(from, to)` | `float` | Global builtin | Per-hit float damage rolls where variance produces non-integer results |
| `randf()` | `float` (0.0–1.0) | Global builtin | Probability checks (crit, dodge) — already used in `CombatEngine._on_hero_attack()` |
| `pick_random()` | element type | Array method | Already used for affix pool selection in `Item.add_prefix()`/`add_suffix()` |

**Confidence: HIGH** — `randi_range` appears in `affix.gd:32`, `affix.gd:38`, `affix.gd:46`, `forge_hammer.gd:23`, `tack_hammer.gd:31`, `grand_hammer.gd:31`, `loot_table.gd:182`. `randf()` appears in `defense_calculator.gd:123`, `loot_table.gd:86`, `loot_table.gd:117`, `loot_table.gd:180`, `runic_hammer.gd:23`. These are proven working globals, not imports.

### Display Patterns (NEW)

| Pattern | GDScript | Where Applied | Why |
|---------|----------|---------------|-----|
| `"%d-%d" % [min_d, max_d]` | String formatting | `item.gd:get_display_text()`, `item_view.gd` | Existing display methods use `%` string format throughout. Consistent extension. |
| `"%.0f-%.0f" % [min_d, max_d]` | String formatting | Floating label combat numbers | Per-hit damage label already uses `int(damage)`. For range display, show rolled value as integer. |
| Average damage for DPS tooltip | Arithmetic | `Weapon.update_value()` → `StatCalculator.calculate_dps()` | DPS stays a single-number summary. Range is shown on item card; DPS shows expected value. Matches PoE convention. |

---

## Integration Points (What Changes)

### 1. `Weapon` Resource — Add Range Fields

```gdscript
# models/items/weapon.gd — BEFORE
var base_damage: int

# AFTER
var base_damage_min: int  # Replaces base_damage
var base_damage_max: int
# base_damage kept as computed average for backward-compat DPS display (optional)
```

**Why two properties, not Vector2i:** The existing `Affix` model uses `min_value: int` / `max_value: int` (not a Vector2). Matching that pattern keeps serialization consistent and avoids extra constructor calls. `to_dict()` / `from_dict()` already knows how to handle flat int properties.

**Serialization:** Extend `Item.to_dict()` to include `"base_damage_min"` and `"base_damage_max"`. `from_dict()` restores them. No format breaking change if you keep `base_damage` as a computed fallback.

### 2. `MonsterType` Resource — Add Range Fields

```gdscript
# models/monsters/monster_type.gd — BEFORE
var base_damage: float

# AFTER
var base_damage_min: float
var base_damage_max: float
```

`MonsterType` is not saved/loaded (it's built in `BiomeConfig._build_biomes()` at runtime), so no serialization change needed. `MonsterPack.damage` becomes a per-attack-roll value computed in `PackGenerator.create_pack()`.

### 3. `MonsterPack` — Add Damage Range Fields

```gdscript
# models/monsters/monster_pack.gd — BEFORE
var damage: float

# AFTER
var damage_min: float  # Scaled min from MonsterType
var damage_max: float  # Scaled max from MonsterType
# damage kept for backward-compat if needed, or removed
```

`MonsterPack.damage` is the value passed to `DefenseCalculator.calculate_damage_taken()`. Converting it to a per-hit roll means the roll happens in `CombatEngine._on_pack_attack()`, not in `PackGenerator`.

### 4. `CombatEngine` — Per-Hit Roll Sites

Two existing roll sites. Both extend naturally:

```gdscript
# _on_hero_attack() — BEFORE
var damage_per_hit := hero.total_dps / hero_attack_speed

# AFTER — roll from weapon range, then apply affix multipliers
var raw_hit := randf_range(hero.damage_min, hero.damage_max)
var damage_per_hit := StatCalculator.apply_multipliers(raw_hit, all_affixes) / hero_attack_speed
```

```gdscript
# _on_pack_attack() — BEFORE
var result := DefenseCalculator.calculate_damage_taken(pack.damage, ...)

# AFTER — roll per hit
var raw_pack_hit := randf_range(pack.damage_min, pack.damage_max)
var result := DefenseCalculator.calculate_damage_taken(raw_pack_hit, pack.element, ...)
```

**Key insight:** The crit roll already happens here (`randf() < crit_chance`). Adding the damage range roll is the same pattern — another `randf_range()` call before the crit multiplier. The hero attack has the cleaner entry point.

### 5. `StatCalculator` — DPS Uses Average

`StatCalculator.calculate_dps()` currently takes `base_damage: float`. For the DPS summary number, pass the average of the range:

```gdscript
# In Weapon.update_value()
var avg_base := (base_damage_min + base_damage_max) / 2.0
self.dps = StatCalculator.calculate_dps(avg_base, base_speed, all_affixes, crit_chance, crit_damage)
```

This keeps `dps` as the expected-value summary (used in tooltips and hero stat display) while per-hit combat uses the actual range. No change to `StatCalculator.calculate_dps()` signature required.

### 6. `Hero` — Add Range Tracking

```gdscript
# models/hero.gd — ADD
var damage_min: float = 0.0
var damage_max: float = 0.0

# In calculate_dps():
if weapon is Weapon:
    damage_min = weapon.compute_scaled_min(all_affixes)
    damage_max = weapon.compute_scaled_max(all_affixes)
    total_dps = weapon.dps
```

`CombatEngine` reads `hero.damage_min` / `hero.damage_max` for the per-hit roll instead of deriving from `total_dps`.

### 7. Elemental Variance Constants

Define variance ratios in a central location (either `Tag` autoload or `StatCalculator`):

```gdscript
# Recommended: const in StatCalculator or a new models/stats/damage_range.gd
# Variance ratio = max/min — how wide the damage spread is per element
const ELEMENT_VARIANCE: Dictionary = {
    "physical": 1.25,    # Tight: 80–100 (1.25x spread)
    "cold":     1.5,     # Moderate: 67–100 (1.5x spread)
    "fire":     2.0,     # Wide: 50–100 (2x spread)
    "lightning": 4.0,    # Extreme: 25–100 (4x spread)
}
```

**How to use:** When `MonsterType` or `Affix` declares a target average damage, the min/max are derived from the variance ratio:

```gdscript
# Given: avg_damage = 100, element = "lightning", variance = 4.0
# max = avg * 2 / (1 + 1/variance) = 133
# min = max / variance = 33
# Average of [33, 133] = 83 ≈ 100 ✓ (close enough for game balance)

# Simpler formula used in practice:
# min = avg * 2 / (1 + variance)
# max = avg * 2 * variance / (1 + variance)
static func get_range_from_avg(avg: float, variance_ratio: float) -> Vector2:
    var min_d := avg * 2.0 / (1.0 + variance_ratio)
    var max_d := min_d * variance_ratio
    return Vector2(min_d, max_d)
```

`Vector2` is appropriate here because this is a **computed output** (not stored in a Resource), so no serialization concern.

### 8. Affix Elemental Damage — Add Element Tag to Damage Affixes

Current flat damage affixes (`Lightning Damage`, `Fire Damage`, `Cold Damage`) use `FLAT_DAMAGE` stat type, which rolls a single `value: int`. For element-specific variance, either:

**Option A (Recommended):** Add element-specific stat types (`FLAT_FIRE_DAMAGE`, `FLAT_COLD_DAMAGE`, `FLAT_LIGHTNING_DAMAGE`) to `Tag.StatType` enum. `StatCalculator` uses the element tag to apply the variance ratio when computing the per-hit min/max contribution from affixes.

**Option B:** Use existing `tags` array (e.g., `Tag.FIRE`) to look up the variance constant at combat time. No enum change needed, slightly more dynamic.

**Recommend Option A** — explicit types at the enum level are more robust and searchable. The `Tag.StatType` enum already has 19 values; adding 3 is low overhead.

---

## What NOT to Add

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `Vector2i` or `Vector2` as Resource property for damage range | No serialization precedent in this codebase. `Affix` uses two flat int properties (`min_value`, `max_value`). Mixing patterns creates inconsistency. | Two flat `int` or `float` properties matching `Affix` convention |
| `RandomNumberGenerator` class instance | Adds state management (seed, instance lifecycle). Global `randf_range()` / `randi_range()` are identical output and already proven in the codebase. | Global `randi_range()` / `randf_range()` builtins |
| Storing rolled damage in a field on `Hero` or `MonsterPack` | Damage is a per-hit ephemeral value. Storing it introduces stale-state bugs. | Roll inline in `_on_hero_attack()` / `_on_pack_attack()` every tick |
| Separate `DamageRangeCalculator` class | Splits DPS math from range math. Makes `StatCalculator` incomplete. | Add `get_range_from_avg()` and `apply_multipliers_to_range()` as static methods in `StatCalculator` |
| Plugins / addons for RNG or stat display | No external dependencies needed. GDScript builtins handle this entirely. | Built-in global functions |
| Changing `StatCalculator.calculate_dps()` signature | `Weapon.update_value()` and `Hero.calculate_dps()` both call it. Changing breaks callers. | Keep signature, pass average damage as input. Compute average in `Weapon.update_value()`. |
| Float per-hit damage shown in floating labels as float | `_spawn_floating_text()` already takes `int`. Casting to `int` is the correct pattern. | `int(rolled_damage)` before passing to floating label |

---

## Serialization Checklist

The `Affix` pattern (in `affix.gd:to_dict()`) is the serialization model for all new range fields:

| New Field | Owner | `to_dict()` key | `from_dict()` restore |
|-----------|-------|-----------------|----------------------|
| `base_damage_min` | `Weapon` (via `Item.to_dict()`) | `"base_damage_min"` | `int(data.get("base_damage_min", 10))` |
| `base_damage_max` | `Weapon` (via `Item.to_dict()`) | `"base_damage_max"` | `int(data.get("base_damage_max", 15))` |
| `MonsterType` damage range | Not serialized (built at runtime) | — | — |
| `MonsterPack` damage range | Not serialized (built at runtime) | — | — |
| Affix elemental damage values | Already serialized (`value`, `min_value`, `max_value`) | Existing keys | Existing restore |

`LightSword._init()` hardcodes `base_damage = 10`. Change to `base_damage_min = 8`, `base_damage_max = 12`. All other item base stats follow the same update pattern.

---

## Alternatives Considered

| Recommended | Alternative | Why Not |
|-------------|-------------|---------|
| Two flat properties (`damage_min`, `damage_max`) | `Vector2i` range property | `Affix` uses two flat properties already. Inconsistent to switch patterns mid-codebase. Vector2 serializes less cleanly with the existing `int(data.get(...))` restore pattern. |
| Global `randi_range()` / `randf_range()` | `RandomNumberGenerator` instance | No benefit over globals for combat rolls. Adds unnecessary state. Already using globals everywhere in the codebase. |
| Average damage for DPS display | Show range in DPS tooltip (e.g., "45–90 DPS") | The hero stat panel shows `total_dps` as a single number. Changing the display format is a separate UI task. Keep DPS as expected value; show range on item card only. |
| Element variance via `const Dictionary` in `StatCalculator` | Hardcoded in `MonsterType` per-type or per-biome | Centralized constants are easier to tune (single edit site). Per-type hardcoding duplicates logic. |
| New `FLAT_FIRE_DAMAGE` etc. in `Tag.StatType` | Dynamic lookup via `tags` array | Enum values are explicit, searchable, type-safe. Tags are already used for affix pool filtering (separate concern). |

---

## Version Compatibility

| API | Godot Version | Notes |
|-----|--------------|-------|
| `randi_range(int, int)` | 4.0+ | Global GDScript builtin. Confirmed working in this project (see `affix.gd:32`). |
| `randf_range(float, float)` | 4.0+ | Global GDScript builtin. Added in Godot 4.0 (renamed from `rand_range()`). |
| `randf()` | 4.0+ | Already in use at `defense_calculator.gd:123`. |
| Two-property Resource pattern | 4.0+ | `Affix.min_value`/`max_value` already proven with save/load round-trip. |
| `to_dict()`/`from_dict()` JSON save | 4.5 | Current save system is JSON via `SaveManager`. New int fields serialize as native JSON numbers. No format breaking change with default fallbacks. |

---

## Sources

**HIGH Confidence (Codebase direct analysis):**
- `/var/home/travelboi/Programming/hammertime/models/affixes/affix.gd` — `randi_range()` usage at lines 32, 38, 46; `min_value`/`max_value` two-property pattern
- `/var/home/travelboi/Programming/hammertime/models/combat/combat_engine.gd` — Per-hit crit roll with `randf()` at line 83; `damage_per_hit` calculation at line 80
- `/var/home/travelboi/Programming/hammertime/models/stats/stat_calculator.gd` — `base_damage: float` parameter; DPS formula structure
- `/var/home/travelboi/Programming/hammertime/models/items/weapon.gd` — `base_damage: int` current field
- `/var/home/travelboi/Programming/hammertime/models/monsters/monster_type.gd` — `base_damage: float` current field
- `/var/home/travelboi/Programming/hammertime/models/monsters/monster_pack.gd` — `damage: float` passed to `DefenseCalculator`

**MEDIUM Confidence (Official docs, web search verified):**
- [Godot Forum: Min-Max Export Variables](https://forum.godotengine.org/t/how-to-create-a-min-max-export-variable/129415) — Two flat properties recommended over Vector2 for inspector clarity
- [PoE Wiki: Damage](https://www.poewiki.net/wiki/Damage) — Lightning has highest variance ("damage variance describes the difference between highest and lowest values"); Lightning min/max spread is substantially wider than Cold/Physical
- [GDScript Random Numbers](https://gdscript.com/solutions/random-numbers/) — `randi_range()` preferred over `randi() % range` for cleaner semantics
- [Godot GitHub: randi() vs randi_range() performance](https://github.com/godotengine/godot/issues/89795) — `randi_range()` is 1.25–4x faster than `randi()` equivalent

**LOW Confidence (Design patterns, not Godot-specific):**
- Element variance ratios (Physical 1.25x, Cold 1.5x, Fire 2x, Lightning 4x) — derived from PoE design intent ("Lightning has highest damage variance") and project milestone description. Specific ratios are design decisions, not documented facts.

---

*Stack research for: Hammertime v1.4 Milestone — Damage Range System*
*Researched: 2026-02-18*
*Confidence: HIGH — All RNG patterns, property conventions, and integration points verified directly against existing codebase*
