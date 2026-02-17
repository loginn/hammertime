# Phase 13: Defensive Stat Foundation - Research

**Researched:** 2026-02-16
**Domain:** ARPG defensive stat calculations (armor, evasion, resistances, energy shield)
**Confidence:** HIGH

## Summary

Phase 13 implements four defense layers that process incoming damage in sequence: Evasion (dodge check) -> Resistances (elemental reduction) -> Armor (physical reduction) -> ES/Life split. The codebase already has stat aggregation infrastructure (StatCalculator, Tag.StatType enums, Hero.calculate_defense()) and affix definitions for all defensive stats. What's missing is the actual damage reduction calculation layer -- the formulas that convert raw stat values into damage mitigation.

The existing `gameplay_view.gd` has a basic `calculate_monster_damage()` using `armor / (armor + 100)` which is close to the PoE formula but needs to be generalized into a proper defense calculation pipeline that handles all four defense types, supports the 50% ES bypass model, and respects the user's specified defense application order.

**Primary recommendation:** Create a `DefenseCalculator` static class (similar to `StatCalculator`) that takes incoming damage parameters and hero defense stats, runs the full mitigation pipeline, and returns a `DamageResult` dictionary with final life/ES damage, dodge result, and breakdown for future UI display.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Armor uses **diminishing returns** formula (PoE-style) -- effective against small hits, less effective against large hits
- Armor has a **soft cap via formula** -- no hard cap, diminishing returns naturally prevent reaching 100%
- Elemental resistances cap at **75% effective** but **over-capping is allowed** in stats -- gear can give >75%, effective is clamped
- All defenses use diminishing returns scaling (armor and evasion both)
- **Pure RNG** dodge -- each attack independently rolls against evasion chance. No entropy tracking
- Evasion **only dodges attacks, not spells** -- packs will be attack-based or spell-based (Phase 14 defines this)
- Spell dodge is a **separate future mod** -- not part of this phase's evasion system
- Evasion dodge chance **capped at 75%** (matches resistance cap)
- Evasion uses **diminishing returns** scaling like armor
- ES is NOT blue life -- it has a distinct identity as the **only leechable defense**
- **50% bypass model**: incoming damage (after armor/resistances) splits -- 50% to ES, 50% directly to life
- ES **recharges 33% of max ES between pack fights** (fixed percentage)
- Damage reduction order: **Evasion -> Resistances -> Armor -> ES/Life split**
- **Clear defense gaps**: evasion doesn't dodge spells, armor doesn't reduce elemental
- Defense types are **gear-limited**: armor bases roll armor mods, mage robes roll ES mods
- **Zero base defense** -- naked hero has no armor, evasion, or ES

### Claude's Discretion
- Specific diminishing returns formula constants (tuning)
- When defenses feel impactful in area progression (early vs late scaling)
- ES recharge timing implementation details
- Defense calculation code architecture

### Deferred Ideas (OUT OF SCOPE)
- Spell dodge chance mod
- ES leech mechanic
- ES bypass reduction mods ("Max ES bypass +10%")
- ES recharge rate mods
- Hybrid gear bases (armor+evasion, armor+ES)
- Visual prefix/suffix separation in UI
</user_constraints>

## Standard Stack

### Core
| Component | Location | Purpose | Why Standard |
|-----------|----------|---------|--------------|
| StatCalculator | models/stats/stat_calculator.gd | Stat aggregation (flat + percentage) | Already used by all item types |
| Tag.StatType | autoloads/tag.gd | Enum for all stat types | All affixes reference these |
| Hero | models/hero.gd | Equipment + stat totals | Has all defense stat properties already |

### New Components
| Component | Location | Purpose |
|-----------|----------|---------|
| DefenseCalculator | models/stats/defense_calculator.gd | Damage reduction pipeline |

### No External Dependencies
This phase is pure GDScript math. No libraries, no Godot plugins. All formulas are implemented as static functions.

## Architecture Patterns

### Recommended: Static Calculator Class
Following the existing StatCalculator pattern, create DefenseCalculator as a static utility class:

```gdscript
class_name DefenseCalculator extends RefCounted

# Full damage pipeline: evasion -> resistances -> armor -> ES/life split
static func calculate_damage_taken(
    raw_damage: float,
    damage_type: String,  # "physical", "fire", "cold", "lightning"
    is_spell: bool,
    hero_armor: int,
    hero_evasion: int,
    hero_energy_shield: int,
    hero_fire_res: int,
    hero_cold_res: int,
    hero_lightning_res: int,
    current_es: float
) -> Dictionary:
    # Returns: { "life_damage": float, "es_damage": float, "dodged": bool, "breakdown": Dictionary }
    pass
```

### Pattern 1: PoE-Style Armor Formula (Diminishing Returns)
**What:** `damage_reduction = armor / (armor + K * raw_damage)` where K is a constant
**PoE uses K=5:** armor / (armor + 5 * raw_damage)
**Recommended K=5:** This is the industry standard. At K=5:
- 100 armor vs 10 damage: 100/(100+50) = 66.7% reduction
- 100 armor vs 100 damage: 100/(100+500) = 16.7% reduction
- 500 armor vs 100 damage: 500/(500+500) = 50% reduction

**Why this works:** Higher armor always helps, but never trivializes large hits. Players intuitively understand "armor is better against small hits."

```gdscript
static func calculate_armor_reduction(armor: int, raw_physical_damage: float) -> float:
    if armor <= 0 or raw_physical_damage <= 0.0:
        return 0.0
    return float(armor) / (float(armor) + 5.0 * raw_physical_damage)
```

### Pattern 2: Evasion Diminishing Returns (Hyperbolic)
**What:** Convert raw evasion stat into dodge chance with diminishing returns, capped at 75%
**Formula:** `dodge_chance = evasion / (evasion + K)` where K controls the curve
**Recommended K=200:** At K=200:
- 50 evasion: 50/(50+200) = 20% dodge
- 100 evasion: 100/(100+200) = 33% dodge
- 200 evasion: 200/(200+200) = 50% dodge
- 600 evasion: 600/(600+200) = 75% dodge (hits cap)

```gdscript
static func calculate_dodge_chance(evasion: int) -> float:
    if evasion <= 0:
        return 0.0
    var raw_chance := float(evasion) / (float(evasion) + 200.0)
    return minf(raw_chance, 0.75)  # 75% cap
```

### Pattern 3: Resistance Clamping (Simple)
**What:** Resistances reduce elemental damage by their percentage, capped at 75%
**Formula:** `effective_res = min(total_res, 75)` then `damage * (1 - effective_res/100)`
**Over-cap stored:** Hero tracks raw total (can exceed 75), effective clamped at application

```gdscript
static func calculate_resistance_reduction(resistance: int) -> float:
    var effective := mini(resistance, 75)
    return float(effective) / 100.0  # Returns 0.0 to 0.75
```

### Pattern 4: ES Bypass Split (50/50)
**What:** After armor/resistance reduction, remaining damage splits: 50% to ES, 50% to life
**If ES depleted mid-hit:** overflow goes to life

```gdscript
static func apply_es_split(
    mitigated_damage: float, current_es: float
) -> Dictionary:
    var es_portion := mitigated_damage * 0.5
    var life_portion := mitigated_damage * 0.5

    # If ES can't absorb its portion, overflow to life
    if es_portion > current_es:
        var overflow := es_portion - current_es
        es_portion = current_es
        life_portion += overflow

    return { "es_damage": es_portion, "life_damage": life_portion }
```

### Pattern 5: ES Recharge Between Fights
**What:** 33% of max ES regenerated between pack fights
**Implementation:** Simple method on Hero, called by combat system between packs

```gdscript
func recharge_energy_shield() -> void:
    var recharge_amount := float(total_energy_shield) * 0.33
    current_energy_shield = minf(current_energy_shield + recharge_amount, float(total_energy_shield))
```

### Anti-Patterns to Avoid
- **Single "defense" number:** The current `total_defense = total_armor` conflation must be replaced with distinct per-type totals feeding into the calculator
- **Hardcoded damage type assumptions:** `calculate_monster_damage()` currently assumes all damage is physical. Must support elemental types for Phase 14+
- **Defense calculations in gameplay_view.gd:** Move all damage math out of the scene script into DefenseCalculator. Gameplay view should only call the calculator
- **Modifying Hero.take_damage() to include defense logic:** Defense calculation is separate from HP subtraction. Calculator computes, Hero applies

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Diminishing returns curve | Custom exponential formula | Hyperbolic `x/(x+K)` | Standard ARPG formula, well-understood, tunable via K |
| Defense application order | Ad-hoc if/else chain | Pipeline function with clear stages | Each stage is independently testable and the order is documented |
| ES overflow handling | Separate life/ES damage paths | Single split function with overflow | Edge case handling (ES depleted mid-hit) is tricky to get right |

## Common Pitfalls

### Pitfall 1: Integer Truncation in Defense Calculations
**What goes wrong:** Using `int` division for armor reduction gives 0 for small armor values
**Why it happens:** GDScript integer division truncates. `50 / 300 = 0` not `0.166`
**How to avoid:** Cast to float before division: `float(armor) / (float(armor) + 5.0 * damage)`
**Warning signs:** Armor having no effect at low values

### Pitfall 2: Defense Stacking Order Bugs
**What goes wrong:** Applying armor to elemental damage or resistances to physical damage
**Why it happens:** Not checking damage_type before applying each defense
**How to avoid:** Pipeline function that routes damage_type to correct reducer
**Warning signs:** Physical-only armor reducing fire damage

### Pitfall 3: ES Overflow Rounding
**What goes wrong:** Player takes more/less total damage than intended due to rounding in ES split
**Why it happens:** Splitting damage 50/50 then rounding each half independently
**How to avoid:** Calculate ES portion first, life gets the remainder: `life = total - es_actually_absorbed`
**Warning signs:** Tiny HP discrepancies over many hits

### Pitfall 4: Negative Damage After Reduction
**What goes wrong:** High defense + low damage = negative damage = healing
**Why it happens:** Not clamping final damage to minimum 0 (or 1 if minimum-damage rule applies)
**How to avoid:** `max(0.0, damage_after_reduction)` at each stage
**Warning signs:** Hero gaining HP from weak monsters

### Pitfall 5: Evasion Checked Against Spells
**What goes wrong:** Spells being dodged when they shouldn't be
**Why it happens:** Not passing `is_spell` flag through the pipeline
**How to avoid:** DefenseCalculator pipeline skips evasion check when `is_spell == true`
**Warning signs:** All damage types being dodgeable

## Code Examples

### Full Defense Pipeline
```gdscript
static func calculate_damage_taken(
    raw_damage: float,
    damage_type: String,
    is_spell: bool,
    hero_armor: int,
    hero_evasion: int,
    hero_energy_shield: int,
    hero_fire_res: int,
    hero_cold_res: int,
    hero_lightning_res: int,
    current_es: float
) -> Dictionary:
    var result := {
        "dodged": false,
        "life_damage": 0.0,
        "es_damage": 0.0,
    }

    # Stage 1: Evasion (attacks only, not spells)
    if not is_spell and hero_evasion > 0:
        var dodge_chance := calculate_dodge_chance(hero_evasion)
        if randf() < dodge_chance:
            result["dodged"] = true
            return result

    var damage := raw_damage

    # Stage 2: Resistances (elemental damage only)
    if damage_type in ["fire", "cold", "lightning"]:
        var resistance := 0
        match damage_type:
            "fire": resistance = hero_fire_res
            "cold": resistance = hero_cold_res
            "lightning": resistance = hero_lightning_res
        var reduction := calculate_resistance_reduction(resistance)
        damage *= (1.0 - reduction)

    # Stage 3: Armor (physical damage only)
    if damage_type == "physical" and hero_armor > 0:
        var armor_reduction := calculate_armor_reduction(hero_armor, damage)
        damage *= (1.0 - armor_reduction)

    # Ensure non-negative
    damage = maxf(0.0, damage)

    # Stage 4: ES/Life split
    if current_es > 0.0 and hero_energy_shield > 0:
        var split := apply_es_split(damage, current_es)
        result["life_damage"] = split["life_damage"]
        result["es_damage"] = split["es_damage"]
    else:
        result["life_damage"] = damage

    return result
```

### Hero Integration
```gdscript
# In Hero class - new properties
var current_energy_shield: float = 0.0

# Updated take_damage to accept pre-calculated split
func apply_damage(life_damage: float, es_damage: float) -> void:
    current_energy_shield = maxf(0.0, current_energy_shield - es_damage)
    health -= life_damage
    health = maxf(0.0, health)
    if health <= 0:
        die()

func recharge_energy_shield() -> void:
    var recharge := float(total_energy_shield) * 0.33
    current_energy_shield = minf(current_energy_shield + recharge, float(total_energy_shield))
```

## State of the Art

| Old Approach (Current Code) | New Approach (Phase 13) | Impact |
|-----------------------------|-------------------------|--------|
| `armor / (armor + 100)` in gameplay_view | `armor / (armor + 5 * raw_damage)` in DefenseCalculator | Armor effectiveness now scales with hit size (PoE-style) |
| `total_defense = total_armor` | Distinct armor/evasion/ES/resistance totals | Each defense type has unique mitigation behavior |
| No evasion mechanic | Dodge chance with 75% cap | New defense layer for attack avoidance |
| No ES mechanic | 50/50 damage split with recharge | New sustain mechanic replacing life-only model |
| All damage treated as physical | Damage type routing (physical/fire/cold/lightning) | Foundation for Phase 14 elemental pack damage |
| Defense calc in scene script | Static DefenseCalculator class | Testable, reusable, decoupled from UI |

## Open Questions

1. **Minimum damage per hit**
   - What we know: Current code uses `max(1.0, damage_after_defense)` -- ensures minimum 1 damage
   - What's unclear: Should this apply after ES split? Can a hit deal 0 to life if ES absorbs it all?
   - Recommendation: Minimum 1 damage applies to the pre-split total, not to each portion individually. A hit that deals 1 total damage splits to 0.5 ES + 0.5 life (rounds to 1 life, 0 ES for simplicity)

2. **Hero.current_energy_shield initialization**
   - What we know: Hero starts with 0 ES (zero base defense). ES comes entirely from gear
   - What's unclear: When should current_es be set to max_es? On equip? On first area entry?
   - Recommendation: Set current_es = total_es in `update_stats()` after recalculating equipment. Player always has full ES when changing gear

3. **Damage type for current gameplay_view**
   - What we know: Current system has no damage_type or is_spell concept
   - What's unclear: What damage type should current monsters deal before Phase 14?
   - Recommendation: Default all current damage to `"physical"` + `is_spell = false`. Phase 14 introduces varied types

## Sources

### Primary (HIGH confidence)
- [Path of Exile Wiki - Armour](https://pathofexile.fandom.com/wiki/Armour) - Exact formula: `DR = armor / (armor + 5 * raw_damage)`, 90% cap, diminishing returns behavior
- [Path of Exile Wiki - Energy Shield](https://pathofexile.fandom.com/wiki/Energy_shield) - ES absorption order, recharge mechanics (20% per second base, 2s delay)

### Secondary (MEDIUM confidence)
- [GameDev.net - Accuracy and Dodge](https://www.gamedev.net/forums/topic/685930-the-simplest-but-most-effective-and-intuitive-way-to-implement-accuracy-and-dodge-chance-in-an-rpg/) - Hyperbolic diminishing returns pattern for dodge chance
- [PoE Wiki - Damage Reduction](https://www.poewiki.net/wiki/Damage_reduction) - Physical damage reduction cap at 90%

### Design Notes
- K=5 for armor formula is the PoE standard. The existing code's K=0.01 (armor/(armor+100)) was a simpler approximation without hit-size scaling
- K=200 for evasion is a tuning recommendation to make the 50% dodge mark achievable with moderate gear investment (~200 total evasion from 3 slots)
- 75% caps on evasion and resistances are locked user decisions matching ARPG conventions

## Metadata

**Confidence breakdown:**
- Armor formula: HIGH - Verified against PoE wiki, well-documented industry standard
- Evasion formula: HIGH - Standard hyperbolic diminishing returns, user locked pure RNG + 75% cap
- Resistance formula: HIGH - Simple clamped percentage, standard ARPG mechanic
- ES split model: MEDIUM - Custom 50% bypass is user's design choice, not a standard pattern. Implementation is straightforward but edge cases (ES depleted mid-hit) need testing
- Code architecture: HIGH - Follows established StatCalculator pattern in this codebase

**Research date:** 2026-02-16
**Valid until:** 2026-03-16 (stable domain, formulas don't change)
