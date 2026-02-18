# Phase 23: Damage Range Data Model - Research

**Researched:** 2026-02-18
**Domain:** GDScript data model — Weapon, Affix, MonsterPack, PackGenerator
**Confidence:** HIGH

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| DMG-01 | Weapon base damage expressed as min-max range per weapon type | Weapon.gd has single `base_damage: int`; must split to `base_damage_min`/`base_damage_max` with `base_damage` as computed average property for backward compat |
| DMG-02 | Flat damage affixes store add_min and add_max values rolled from element-specific tier ranges at item creation | Affix._init() rolls single `value`; needs four template fields (dmg_min_lo/dmg_min_hi/dmg_max_lo/dmg_max_hi) plus rolled results (add_min/add_max); Affixes.from_affix() and serialization must carry all six fields |
| DMG-03 | Element-specific variance ratios define spread between min and max (Physical tight, Cold moderate, Fire wide, Lightning extreme) | Variance constants confirmed from project STATE.md and prior research; goes in a new `ElementVariance` constant class or in PackGenerator; used when initializing affix templates AND when creating MonsterPack ranges |
| DMG-04 | Monster pack damage expressed as min-max range with variance based on pack element type | MonsterPack has single `damage: float`; must add `damage_min: float` and `damage_max: float`; PackGenerator.create_pack() computes them from element variance constants; backward-compat `damage` field can stay or be removed |
</phase_requirements>

---

## Summary

Phase 23 is a pure data model phase. It introduces min-max range fields to three data structures — `Weapon`, `Affix` (flat damage templates only), and `MonsterPack` — and defines element variance constants that link element type to spread ratio. No combat rolling or UI display changes are in scope; those are Phases 25 and 26 respectively. The goal is that when Phase 23 ships, every relevant data structure carries the range information, and the Tuning Hammer reads from immutable template bounds rather than mutable rolled values.

The codebase already has a strong foundation. `Affix` has `min_value`/`max_value` for tier scaling, `to_dict()`/`from_dict()` for serialization, and a `reroll()` method that currently uses those same fields. The critical design decision (already locked in STATE.md) is that flat damage affixes need **six new fields**: four template bounds (`dmg_min_lo`, `dmg_min_hi`, `dmg_max_lo`, `dmg_max_hi`) and two rolled results (`add_min`, `add_max`). The template bounds are written once at item creation and never changed; `reroll()` reads from them. The prior `min_value`/`max_value`/`value` fields remain intact for non-damage affixes.

The user has already decided: no save migration, no SAVE_VERSION bump. This is a fresh-saves-only milestone boundary. That decision eliminates Pitfall 1 (save migration corruption) as a concern and allows the new fields to be added without a migration stub. Existing saves are abandoned; the planner should not add any migration code.

**Primary recommendation:** Add fields to three files in strict order — (1) define element variance constants in a dedicated location, (2) extend Weapon, (3) extend Affix with the 4+2 field schema plus serialization, (4) extend MonsterPack and PackGenerator. All four changes are data-model only; StatCalculator and CombatEngine are not touched in this phase.

---

## Standard Stack

This phase uses no external libraries. All tools are Godot 4 built-ins.

### Core

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| GDScript | Godot 4.5 | All implementation | Project language |
| Resource | Godot 4.5 | Base class for Affix, Weapon, MonsterPack | Already established in codebase |
| randi_range() | Godot 4.5 | Roll add_min/add_max at item creation | Existing pattern in affix.gd:38 |
| Vector2i | Godot 4.5 | Optional: return min/max pairs from helpers | Established in research ARCHITECTURE.md |
| Dictionary | Godot 4.5 | Serialization in to_dict()/from_dict() | Existing save format |

### No External Libraries Needed

This phase is pure data model surgery. No new dependencies.

---

## Architecture Patterns

### File Change Map

Exactly four files need changes in Phase 23:

```
models/
├── items/
│   ├── weapon.gd          # Add base_damage_min, base_damage_max; base_damage as computed property
│   └── light_sword.gd     # Update _init() to use range values instead of single base_damage
├── affixes/
│   └── affix.gd           # Add dmg_min_lo/hi, dmg_max_lo/hi, add_min, add_max; update reroll(), to_dict(), from_dict()
├── monsters/
│   ├── monster_pack.gd    # Add damage_min: float, damage_max: float
│   └── pack_generator.gd  # Read element variance to compute damage_min/max in create_pack()
autoloads/
└── item_affixes.gd        # Update flat damage affix definitions to include variance-derived bounds
```

One new constant location is needed. Two options:

**Option A (recommended):** Add `ElementVariance` constants directly to `PackGenerator` as static consts, since PackGenerator is already the only consumer at this phase. When Phase 25 needs them for combat rolling, they can be referenced from `PackGenerator.ELEMENT_VARIANCE`.

**Option B:** Create a new `models/combat/element_variance.gd` static class. Cleaner long-term if multiple files need the constants, but adds a file for a single dictionary.

Use Option A for Phase 23. If Phase 25 finds it inconvenient, it can be refactored then.

### Pattern 1: Weapon Base Damage Range

**What:** Split single `base_damage: int` into min/max pair; keep `base_damage` as a computed property that returns the average for backward compatibility with `StatCalculator.calculate_dps()` and `forge_view.gd` references.

**When to use:** Any Weapon subclass definition.

```gdscript
# models/items/weapon.gd — MODIFIED
class_name Weapon extends Item

var base_damage_min: int = 0
var base_damage_max: int = 0
# Computed property — backward compat for StatCalculator and display code
var base_damage: int:
    get: return (base_damage_min + base_damage_max) / 2

var base_damage_type: String
var base_speed: int
var dps: float
# ... rest unchanged
```

```gdscript
# models/items/light_sword.gd — MODIFIED
func _init() -> void:
    self.rarity = Rarity.NORMAL
    self.item_name = "Light Sword"
    self.tier = 8
    self.valid_tags = [Tag.PHYSICAL, Tag.ATTACK, Tag.CRITICAL, Tag.WEAPON]
    self.base_damage_type = Tag.PHYSICAL
    self.implicit = Implicit.new(
        "Attack Speed", Affix.AffixType.IMPLICIT, 2, 5, [Tag.SPEED, Tag.ATTACK], [Tag.StatType.INCREASED_SPEED]
    )
    # Physical: tight spread per variance ratios (1:1.5)
    self.base_damage_min = 8
    self.base_damage_max = 12
    self.base_speed = 1
    self.base_attack_speed = 1.8
    self.update_value()
```

**Note:** `Weapon.update_value()` calls `StatCalculator.calculate_dps(self.base_damage, ...)`. Since `base_damage` is now a computed property returning `(min + max) / 2`, this call site requires **no change** in Phase 23. The signature change to StatCalculator is deferred to Phase 24.

### Pattern 2: Affix Damage Range Schema (Six-Field Extension)

**What:** Add four immutable template fields and two mutable rolled fields. Template fields are set at construction. Rolled fields are set at item creation (Affixes.from_affix()) and re-set by reroll(). The template fields must be carried through serialization.

**Critical distinction:** `min_value`/`max_value`/`value` are NOT repurposed. They continue to serve non-damage affixes (defense, resistance, crit, etc.) exactly as before. The six new fields are only meaningful for affixes with `Tag.StatType.FLAT_DAMAGE` in their `stat_types`.

```gdscript
# models/affixes/affix.gd — ADD FIELDS (at class level, after existing fields)

# Template bounds for flat damage affixes — NEVER changed after construction
# Scaled by tier formula at init time, just like min_value/max_value
var dmg_min_lo: int = 0   # Lowest possible add_min for this tier
var dmg_min_hi: int = 0   # Highest possible add_min for this tier
var dmg_max_lo: int = 0   # Lowest possible add_max for this tier
var dmg_max_hi: int = 0   # Highest possible add_max for this tier

# Rolled results — set at item creation, re-rolled by Tuning Hammer
var add_min: int = 0      # Rolled minimum damage contribution per hit
var add_max: int = 0      # Rolled maximum damage contribution per hit
```

```gdscript
# models/affixes/affix.gd — _init() extension
# After existing tier/min_value/max_value/value setup:
# Roll damage range if this is a flat damage affix
# (dmg_min_lo etc. are set from _init parameters p_dmg_min_lo ... p_dmg_max_hi)
if Tag.StatType.FLAT_DAMAGE in self.stat_types:
    self.add_min = randi_range(self.dmg_min_lo, self.dmg_min_hi)
    self.add_max = randi_range(self.dmg_max_lo, self.dmg_max_hi)
    # Guard: ensure add_min <= add_max
    if self.add_min > self.add_max:
        var tmp = self.add_min
        self.add_min = self.add_max
        self.add_max = tmp
```

**Extending _init() signature:** The cleanest approach is to add optional parameters at the end of `_init()`:

```gdscript
func _init(
    p_name: String = "",
    p_type: AffixType = AffixType.PREFIX,
    p_min: int = 0,
    p_max: int = 0,
    p_tags: Array[String] = [],
    p_stat_types: Array[int] = [],
    p_tier_range: Vector2i = Vector2i(1, 8),
    # NEW — optional damage range template bounds (only meaningful for FLAT_DAMAGE affixes)
    p_dmg_min_lo: int = 0,
    p_dmg_min_hi: int = 0,
    p_dmg_max_lo: int = 0,
    p_dmg_max_hi: int = 0
) -> void:
```

All existing `Affix.new(...)` call sites in `item_affixes.gd` pass the first seven arguments only; new optional parameters default to 0 and are harmless for non-damage affixes. **This means no other call sites break.**

### Pattern 3: reroll() for Flat Damage Affixes

**What:** Override reroll behavior for damage range affixes to read template bounds, not rolled values. The existing `reroll()` for non-damage affixes remains unchanged.

```gdscript
# models/affixes/affix.gd — reroll() MODIFIED
func reroll() -> void:
    if Tag.StatType.FLAT_DAMAGE in self.stat_types and (dmg_min_lo > 0 or dmg_max_hi > 0):
        # Damage range affix: re-roll from TEMPLATE bounds (never collapsed)
        self.add_min = randi_range(self.dmg_min_lo, self.dmg_min_hi)
        self.add_max = randi_range(self.dmg_max_lo, self.dmg_max_hi)
        if self.add_min > self.add_max:
            var tmp = self.add_min
            self.add_min = self.add_max
            self.add_max = tmp
    else:
        # Non-damage affix: existing scalar reroll unchanged
        self.value = randi_range(self.min_value, self.max_value)
    print("reroll add_min=%d add_max=%d value=%d" % [add_min, add_max, value])
```

### Pattern 4: Affix Serialization Extension

**What:** Add all six new fields to `to_dict()` and `from_dict()`. Since there is no save migration (fresh saves only), old saves are not loaded; `from_dict()` default fallbacks are only needed for defensive coding, not migration.

```gdscript
# models/affixes/affix.gd — to_dict() EXTENDED
func to_dict() -> Dictionary:
    return {
        "affix_name": affix_name,
        "type": int(type),
        "value": value,
        "tier": tier,
        "tags": Array(tags),
        "stat_types": Array(stat_types),
        "tier_range_x": tier_range.x,
        "tier_range_y": tier_range.y,
        "base_min": base_min,
        "base_max": base_max,
        "min_value": min_value,
        "max_value": max_value,
        # NEW damage range fields
        "dmg_min_lo": dmg_min_lo,
        "dmg_min_hi": dmg_min_hi,
        "dmg_max_lo": dmg_max_lo,
        "dmg_max_hi": dmg_max_hi,
        "add_min": add_min,
        "add_max": add_max,
    }
```

```gdscript
# models/affixes/affix.gd — from_dict() EXTENDED
# After existing field restoration, add:
affix.dmg_min_lo = int(data.get("dmg_min_lo", 0))
affix.dmg_min_hi = int(data.get("dmg_min_hi", 0))
affix.dmg_max_lo = int(data.get("dmg_max_lo", 0))
affix.dmg_max_hi = int(data.get("dmg_max_hi", 0))
affix.add_min = int(data.get("add_min", 0))
affix.add_max = int(data.get("add_max", 0))
```

### Pattern 5: Element Variance Constants

**What:** Define variance spread ratios for each element. The ratio describes how wide the min-max range is relative to the average value.

**Locked decision (from STATE.md):** Physical 1:1.5, Cold 1:2, Fire 1:2.5, Lightning 1:4.

These ratios mean: for a target average damage value `avg`, the range is:
- Physical: `min = avg * 2/2.5 = avg * 0.8`, `max = avg * 1.2` (spread: min is 0.8x avg, max is 1.2x avg)

The simpler implementation used in prior research (ARCHITECTURE.md): define a `variance` constant per element where `damage_min = base * (1 - variance)` and `damage_max = base * (1 + variance)`.

Mapping the locked decisions to this symmetric formula:
- Physical 1:1.5 ratio — if min=1, max=1.5, avg=1.25. Expressed as variance: min = avg*(1-v), max = avg*(1+v). Solving: 1/(1+v) = 0.67 → v ≈ 0.2. But the locked ratios are min:max, so: Physical min:max = 1:1.5, variance centered = 0.2.
- The project STATE.md ratios are directly usable: store min multiplier and max multiplier per element.

```gdscript
# models/monsters/pack_generator.gd — ADD CONSTANTS
# Element variance: multipliers applied to base_damage * level_multiplier
# Ratios from STATE.md: Physical 1:1.5, Cold 1:2, Fire 1:2.5, Lightning 1:4
# To convert: if ratio is lo:hi, then min_mult = 2*lo/(lo+hi), max_mult = 2*hi/(lo+hi)
const ELEMENT_VARIANCE: Dictionary = {
    "physical": {"min_mult": 0.80, "max_mult": 1.20},  # 1:1.5 → avg preserved
    "cold":     {"min_mult": 0.67, "max_mult": 1.33},  # 1:2 → avg preserved
    "fire":     {"min_mult": 0.57, "max_mult": 1.43},  # 1:2.5 → avg preserved
    "lightning": {"min_mult": 0.40, "max_mult": 1.60},  # 1:4 → avg preserved
}
```

**Math verification:** For Physical at base=10: min=8, max=12, avg=10. Ratio 8:12 = 1:1.5. Correct.
For Lightning at base=10: min=4, max=16, avg=10. Ratio 4:16 = 1:4. Correct.

**Note:** The locked ratios from STATE.md say "validate against survivability before finalizing." The planner should include a verification step that checks monster kill times at each difficulty tier, but the constants above match the locked decisions exactly.

### Pattern 6: MonsterPack Range Fields

**What:** Add `damage_min` and `damage_max` to MonsterPack. The existing `damage: float` field remains for backward compatibility (CombatEngine currently reads `pack.damage`; that is changed in Phase 25, not Phase 23).

```gdscript
# models/monsters/monster_pack.gd — ADD FIELDS
var damage_min: float = 0.0   # NEW
var damage_max: float = 0.0   # NEW
# damage: float remains (Phase 25 will switch CombatEngine to use min/max)
```

```gdscript
# models/monsters/pack_generator.gd — create_pack() MODIFIED
static func create_pack(
    monster_type: MonsterType, area_level: int, element: String, biome: BiomeConfig = null
) -> MonsterPack:
    var multiplier := get_level_multiplier(area_level)
    var pack := MonsterPack.new()
    pack.pack_name = monster_type.type_name
    pack.hp = monster_type.base_hp * multiplier
    pack.max_hp = pack.hp
    pack.attack_speed = monster_type.base_attack_speed
    pack.element = element

    # Compute damage range using element variance constants
    var scaled_base := monster_type.base_damage * multiplier
    var variance := ELEMENT_VARIANCE.get(element, ELEMENT_VARIANCE["physical"])
    pack.damage_min = scaled_base * variance["min_mult"]
    pack.damage_max = scaled_base * variance["max_mult"]
    # Backward compat: existing damage field = average of range
    pack.damage = (pack.damage_min + pack.damage_max) / 2.0

    # ... difficulty_bonus logic unchanged
    return pack
```

### Pattern 7: Affix Template Definitions in item_affixes.gd

**What:** Update flat damage affix definitions to pass element-specific damage range bounds. The bounds follow the same locked variance ratios. The `Affix._init()` will roll `add_min`/`add_max` from these bounds during construction.

Flat damage affixes in `item_affixes.gd` currently use `base_min=2, base_max=10` for all types. These become the `p_min`/`p_max` (tier scaling), but now also need the four damage bounds.

The design is: the existing `min_value`/`max_value` tier scaling still governs the overall "power level" of the affix, and the four `dmg_*` fields encode the variance within that power. One clean approach: derive `dmg_*` from `min_value`/`max_value` using element variance. Set them at construction time from the p_dmg_* parameters.

Example for Physical Damage affix (tier 1 = highest power):
- Physical variance ratio 1:1.5
- `p_min=2, p_max=10` → at tier 1 (`tier = tier_range.y + 1 - 1 = tier_range.y`), `min_value = p_min * tier_range.y`, `max_value = p_max * tier_range.y`
- For 8-tier range: at tier 1: `min_value=16, max_value=80`
- Physical damage add_min/add_max represent the per-hit contribution, not the tier scaling

The simplest workable approach: treat the existing `p_min` as the target minimum value for add_min, and `p_max` as the target for add_max, then apply variance ratio to derive the two bounds for each. Or specify the four bounds directly in the affix definition.

**Recommended for Phase 23:** Specify the four bounds directly in the affix constructor for flat damage affixes. This makes the designer's intent explicit. The values should be tuned so that higher-element affixes have wider spreads while keeping average damage equivalent across elements at the same tier.

```gdscript
# autoloads/item_affixes.gd — Physical Damage affix (existing + new bounds)
Affix.new(
    "Physical Damage",
    Affix.AffixType.PREFIX,
    2,          # p_min (tier scaling unchanged)
    10,         # p_max (tier scaling unchanged)
    [Tag.PHYSICAL, Tag.FLAT, Tag.WEAPON],
    [Tag.StatType.FLAT_DAMAGE],
    Vector2i(1, 8),  # tier_range (unchanged)
    # NEW: damage range template bounds (Physical: tight 1:1.5 ratio)
    # add_min rolls from [3, 5], add_max rolls from [7, 10]
    3, 5, 7, 10
),

# Lightning Damage affix (existing + new wide bounds)
Affix.new(
    "Lightning Damage",
    Affix.AffixType.PREFIX,
    2,
    10,
    [Tag.ELEMENTAL, Tag.LIGHTNING, Tag.WEAPON],
    [Tag.StatType.FLAT_DAMAGE],
    Vector2i(1, 8),
    # NEW: damage range template bounds (Lightning: extreme 1:4 ratio)
    # add_min rolls from [1, 3], add_max rolls from [7, 15]
    1, 3, 7, 15
),
```

**Note on balance:** The exact bound values (1, 3, 7, 15 etc.) are design parameters requiring tuning. The planner should flag these as "validate against gameplay feel" rather than locking them. The constraint is: average of (add_min + add_max)/2 should be roughly equal across elements at the same tier.

### Anti-Patterns to Avoid

- **Repurposing min_value/max_value as damage range:** These fields already mean "tier-scaled stat bounds for the single scalar value." Reusing them for damage range bounds destroys non-damage affixes and breaks the Tuning Hammer re-roll. See Pitfall 3 in prior research.
- **Rolling add_min/add_max at reroll time from rolled values:** The reroll must read `dmg_min_lo`/`dmg_min_hi` (template), not `add_min`/`add_max` (already-rolled). If the template bounds are lost, range collapses.
- **Touching StatCalculator in Phase 23:** StatCalculator changes are Phase 24's responsibility. Phase 23 adds fields only; it does not change how DPS is computed. The existing `calculate_dps(self.base_damage, ...)` call in Weapon.update_value() still works because `base_damage` returns the average.
- **Touching CombatEngine in Phase 23:** Per-hit rolling is Phase 25. CombatEngine still reads `pack.damage` (not `pack.damage_min/max`) after Phase 23 ships.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Random integer in range | Custom linear interpolation | `randi_range(lo, hi)` | Built-in Godot function; already used in affix.gd:38 |
| Float random for MonsterPack ranges | Custom float random | `randf_range(min, max)` (Phase 25) | Godot built-in; cleaner than casting int range |
| Min/max pair storage | Custom struct | `Vector2i` or Dictionary | Vector2i already used in tier_range; consistent |

---

## Common Pitfalls

### Pitfall 1: Repurposing min_value/max_value Breaks Tuning Hammer

**What goes wrong:** If the implementation reuses `min_value` as "rolled min damage" and `max_value` as "rolled max damage," then `reroll()` (which calls `randi_range(self.min_value, self.max_value)`) rolls the NEW damage_max from a range of `[old_damage_min, old_damage_max]`. After one re-roll, max can collapse toward min and never recover — the range silently degrades toward zero variance.

**Why it happens:** Temptation to avoid adding new fields by repurposing existing ones.

**How to avoid:** Add the six new fields (`dmg_min_lo`, `dmg_min_hi`, `dmg_max_lo`, `dmg_max_hi`, `add_min`, `add_max`). Keep `min_value`/`max_value`/`value` untouched.

**Warning signs:** After 10 Tuning Hammer applications, `add_max` equals `add_min`; range has collapsed.

### Pitfall 2: base_damage Property Breaks if Both Fields are Zero

**What goes wrong:** The computed property `base_damage: int: get: return (base_damage_min + base_damage_max) / 2` returns 0 if both are uninitialized. Any weapon that fails to set the new fields silently shows 0 DPS.

**Why it happens:** If only `LightSword` is updated but other weapon subclasses exist, they inherit the property returning 0.

**How to avoid:** Set default values for `base_damage_min` and `base_damage_max` in `weapon.gd` to reasonable fallbacks (e.g., same as old `base_damage`), or add an assertion in `update_value()`.

**Warning signs:** DPS shows 0 or extremely low values for weapons that were working before.

### Pitfall 3: add_min > add_max After Rolling

**What goes wrong:** `randi_range(dmg_min_lo, dmg_min_hi)` and `randi_range(dmg_max_lo, dmg_max_hi)` are independent rolls. If the template bounds are badly configured (e.g., `dmg_min_hi > dmg_max_lo`), it is statistically possible to roll `add_min > add_max`.

**Why it happens:** Bad template bounds in item_affixes.gd, especially at high tiers where tier scaling pushes min_value up.

**How to avoid:** Add a guard after rolling: `if add_min > add_max: swap them`. Also: design bounds so `dmg_min_hi < dmg_max_lo` always (no overlap). Assert this in debug builds.

**Warning signs:** Affix displays negative range (add_max < add_min); combat takes negative damage from affix.

### Pitfall 4: PackGenerator debug_generate() Prints Old Single-Damage Format

**What goes wrong:** `PackGenerator.debug_generate()` at line 101 prints `pack.damage` in the format string. After adding min/max, this still compiles but shows only the average, making it hard to verify the range was set.

**Why it happens:** Debug method not updated alongside data model.

**How to avoid:** Update the debug print format to show `"DMG: %.1f-%.1f"` using `pack.damage_min` and `pack.damage_max`.

**Warning signs:** Debug output shows round numbers for all elements — suggests single-value output rather than range.

### Pitfall 5: Affixes.from_affix() Does Not Copy New Fields

**What goes wrong:** `Affixes.from_affix(template)` in `item_affixes.gd` creates a copy of a template affix to place on an item. Currently it calls `Affix.new()` with the same 7 parameters. If the four new `dmg_*` parameters are not passed through, the copy has zero bounds and rolls `add_min = add_max = 0`. Every item created gets 0-0 flat damage range.

**Why it happens:** `from_affix()` is a copy constructor that must be updated to pass all parameters.

**How to avoid:** Update `Affixes.from_affix()` to pass `template.dmg_min_lo`, `template.dmg_min_hi`, `template.dmg_max_lo`, `template.dmg_max_hi` as the last four arguments to `Affix.new()`.

**Warning signs:** Items placed in the crafting bench show 0 flat damage contribution despite having a "Physical Damage" prefix.

---

## Code Examples

### Weapon.gd Final Shape (Phase 23)

```gdscript
# Source: direct codebase analysis of models/items/weapon.gd
class_name Weapon extends Item

var base_damage_min: int = 0
var base_damage_max: int = 0
# Computed property: backward compat — callers that read base_damage get the average
var base_damage: int:
    get: return (base_damage_min + base_damage_max) / 2

var base_damage_type: String
var base_speed: int
var dps: float
var phys_dps: int
var bleed_dps: int
var lightning_dps: int
var cold_dps: int
var fire_dps: int
var crit_chance: float = 5.0
var crit_damage: float = 150.0
var base_attack_speed: float = 1.0


func update_value() -> void:
    var all_affixes := self.prefixes + self.suffixes
    all_affixes.append(self.implicit)
    # base_damage computed property returns average — StatCalculator unchanged in Phase 23
    self.dps = StatCalculator.calculate_dps(
        self.base_damage, self.base_speed, all_affixes, self.crit_chance, self.crit_damage
    )
```

### Variance Constant Math Verification

```gdscript
# Locked ratios from STATE.md: Physical 1:1.5, Cold 1:2, Fire 1:2.5, Lightning 1:4
# Symmetric variance formula: min = avg * min_mult, max = avg * max_mult
# where min_mult + max_mult = 2.0 (average preserved)
#
# Physical 1:1.5 → min/(min+max) = 1/2.5, so min = base * 0.8, max = base * 1.2
#   Check: 8 to 12 at base=10. Ratio 8:12 = 1:1.5. Correct.
# Cold 1:2 → min = base * 2/3 = 0.667x, max = base * 4/3 = 1.333x
#   Check: 6.7 to 13.3 at base=10. Ratio 6.7:13.3 = 1:2. Correct.
# Fire 1:2.5 → min = base * 2/3.5 = 0.571x, max = base * 5/3.5 = 1.429x
#   Check: 5.7 to 14.3 at base=10. Ratio 5.7:14.3 = 1:2.5. Correct.
# Lightning 1:4 → min = base * 2/5 = 0.4x, max = base * 8/5 = 1.6x
#   Check: 4 to 16 at base=10. Ratio 4:16 = 1:4. Correct.

const ELEMENT_VARIANCE: Dictionary = {
    "physical": {"min_mult": 0.80, "max_mult": 1.20},
    "cold":     {"min_mult": 0.667, "max_mult": 1.333},
    "fire":     {"min_mult": 0.571, "max_mult": 1.429},
    "lightning": {"min_mult": 0.40, "max_mult": 1.60},
}
```

### MonsterPack Range Population

```gdscript
# Source: analysis of models/monsters/pack_generator.gd — create_pack()
# Phase 23 adds damage_min/damage_max; CombatEngine still reads pack.damage until Phase 25

static func create_pack(
    monster_type: MonsterType, area_level: int, element: String, biome: BiomeConfig = null
) -> MonsterPack:
    var multiplier := get_level_multiplier(area_level)
    var pack := MonsterPack.new()
    pack.pack_name = monster_type.type_name
    pack.hp = monster_type.base_hp * multiplier
    pack.max_hp = pack.hp
    pack.attack_speed = monster_type.base_attack_speed
    pack.element = element

    var scaled_base := monster_type.base_damage * multiplier
    var variance := ELEMENT_VARIANCE.get(element, ELEMENT_VARIANCE["physical"])
    pack.damage_min = scaled_base * variance["min_mult"]
    pack.damage_max = scaled_base * variance["max_mult"]
    pack.damage = (pack.damage_min + pack.damage_max) / 2.0  # backward compat

    if biome != null and biome.monster_types.size() > 0:
        var avg_hp := 0.0
        for mt in biome.monster_types:
            avg_hp += mt.base_hp
        avg_hp /= float(biome.monster_types.size())
        pack.difficulty_bonus = 1.5 if monster_type.base_hp > avg_hp else 1.0

    return pack
```

### Affix from_affix() Copy with New Fields

```gdscript
# Source: analysis of autoloads/item_affixes.gd — from_affix()
# MUST pass damage range template bounds so rolled item has correct bounds

static func from_affix(template: Affix) -> Affix:
    var affix_copy = Affix.new(
        template.affix_name,
        template.type,
        template.base_min,
        template.base_max,
        template.tags,
        template.stat_types,
        template.tier_range,
        # NEW: pass damage range template bounds
        template.dmg_min_lo,
        template.dmg_min_hi,
        template.dmg_max_lo,
        template.dmg_max_hi
    )
    return affix_copy
```

---

## State of the Art

| Old Approach | Current Approach | Changed In | Impact |
|--------------|------------------|------------|--------|
| `base_damage: int` single scalar | `base_damage_min`/`base_damage_max` + computed `base_damage` property | Phase 23 | Weapon now expresses a range; DPS display unchanged in Phase 23 |
| `affix.value` single rolled int for flat damage | `add_min`/`add_max` rolled from template bounds; `value` still used for non-damage affixes | Phase 23 | Enables per-hit rolling in Phase 25; Tuning Hammer reads template bounds |
| `pack.damage` single float | `damage_min`/`damage_max` + average `damage` for backward compat | Phase 23 | MonsterPack ready for per-hit rolling in Phase 25 |
| No element variance distinction | ELEMENT_VARIANCE constants in PackGenerator | Phase 23 | All downstream phases use these constants |

**Not changed in Phase 23 (deferred):**
- `StatCalculator.calculate_dps()` signature — still takes single `base_damage: float` (Phase 24)
- `CombatEngine` per-hit rolling — still uses `pack.damage` and `hero.total_dps / speed` (Phase 25)
- UI tooltip display — still shows single values (Phase 26)
- `Hero.total_damage_min`/`total_damage_max` — new fields added in Phase 24

---

## Open Questions

1. **Exact affix template bounds in item_affixes.gd**
   - What we know: Four flat damage affixes need `dmg_*` bounds; variance ratios are locked from STATE.md
   - What's unclear: Exact numeric values for each affix's bounds at each tier step; balance requires gameplay validation
   - Recommendation: Planner should define placeholder reasonable values (e.g., Physical: lo=(3,5) hi=(7,10)) and flag them as "validate against gameplay feel during Phase 25 verification"

2. **Where to locate ELEMENT_VARIANCE constants**
   - What we know: PackGenerator needs them; Phase 25 CombatEngine will also need them; Phase 24 StatCalculator may need them
   - What's unclear: Whether a single location is sufficient or whether they should be in a dedicated constants file
   - Recommendation: Start in PackGenerator (Option A). Refactor to dedicated file only if Phase 25 creates awkward imports. This avoids premature abstraction.

3. **Whether `Affix._init()` parameter count (11 params) is unwieldy**
   - What we know: GDScript supports up to 15+ parameters; all existing call sites use positional args
   - What's unclear: Whether item_affixes.gd's human-readability degrades meaningfully with 4 extra params
   - Recommendation: Accept the 11-param signature for Phase 23. Consider a builder pattern if more fields are added in future phases.

---

## Sources

### Primary (HIGH confidence)

- Direct codebase analysis — `models/items/weapon.gd`, `models/affixes/affix.gd`, `autoloads/item_affixes.gd`, `models/monsters/monster_pack.gd`, `models/monsters/pack_generator.gd`, `autoloads/save_manager.gd`, `models/currencies/tuning_hammer.gd` — all read directly for this research
- `.planning/STATE.md` — locked decisions: variance ratios, no save migration, affix field naming (dmg_min_lo etc., add_min/add_max)
- `.planning/REQUIREMENTS.md` — requirement text and out-of-scope list
- `.planning/ROADMAP.md` — phase success criteria and downstream phase boundaries
- `.planning/research/PITFALLS.md` — eight pitfalls with root causes; all read directly
- `.planning/research/ARCHITECTURE.md` — integration point analysis for all six data layer changes
- `.planning/research/FEATURES.md` — ARPG convention reference; variance ratio derivation

### Secondary (MEDIUM confidence)

- `.planning/research/SUMMARY.md` — cross-reference of findings from prior research session
- `.planning/research/STACK.md` — element variance implementation approach from prior research

---

## Metadata

**Confidence breakdown:**
- Weapon field changes: HIGH — weapon.gd read directly; computed property pattern well established in GDScript
- Affix six-field schema: HIGH — affix.gd read directly; field naming locked in STATE.md; reroll() behavior clear from source
- Element variance constants: HIGH — ratios locked in STATE.md; math verified above
- MonsterPack/PackGenerator changes: HIGH — both files read directly; change is additive with one new field
- Affix template bounds (exact numeric values): LOW — design parameters requiring gameplay validation

**Research date:** 2026-02-18
**Valid until:** 2026-03-20 (stable codebase; no external dependencies)
