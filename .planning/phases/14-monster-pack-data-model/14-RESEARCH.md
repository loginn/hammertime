# Phase 14: Monster Pack Data Model - Research

**Researched:** 2026-02-16
**Domain:** Godot 4.5 Resource-based data modeling for monster packs with scaling
**Confidence:** HIGH

## Summary

Phase 14 creates the data model for monster packs -- Resource classes that hold HP, damage, attack speed, and elemental damage type, plus the biome configuration and scaling logic that generates them. The existing codebase already uses `extends Resource` as its core data pattern (Item, Hero, Affix, Currency), so monster packs follow the same approach. No external libraries needed -- this is pure GDScript Resource design with exponential scaling math.

The key technical challenges are: (1) designing a clean Resource hierarchy for pack types vs pack instances, (2) implementing biome-specific weighted elemental distribution, and (3) wiring area-level scaling with per-type base stats. All of this is straightforward Godot 4.5 GDScript.

**Primary recommendation:** Create a `MonsterType` Resource (base stats template), a `MonsterPack` Resource (scaled instance), a `BiomeConfig` Resource (element weights, pack count range, type pool), and a `PackGenerator` static utility that produces packs for a given area level and biome.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Pack Identity:**
- Named monster types, not generic stat bundles -- each biome has a pool of 5-6 named types
- Each type has gameplay-relevant differences: own base HP, base damage, and attack speed
- Claude designs thematic monster types to fit each biome's identity (Forest = natural beasts, Shadow Realm = eldritch horrors, etc.)
- Examples: Bears = high base HP, slower attacks; Imps = low base HP, fast attacks

**Scaling Curves:**
- Gentle exponential scaling (~5-8% per level) for both HP and damage
- HP and damage scale at the same rate -- packs get proportionally tougher and harder-hitting together
- Smooth curve across biomes -- no extra difficulty spike at biome transitions (levels 100, 200, 300)
- Per-type base stats (HP, damage, attack speed) are scaled by area level multiplier, not flat modifiers on a shared formula

**Biome Elemental Distribution:**
- Each biome declares a primary element in its config (biomes are alpha placeholders, destined to be replaced)
- Current biomes: Forest (1-99), Dark Forest (100-199), Cursed Woods (200-299), Shadow Realm (300+)
- Element assignment to specific biomes is not locked -- Claude assigns what fits, easy to swap later
- Within a biome: ~40% weight for primary element, ~60% weighted random across remaining elements
- Physical is NOT guaranteed in the off-element mix -- some late-game biomes could be pure elemental
- Distribution is weighted random, not exact -- natural variation per map
- Each individual pack deals a single element (no mixed damage per pack)

**Pack Count & Map Structure:**
- 8-15 packs per map (long runs, more currency from kills, map completion feels earned)
- Same pack count range across all biomes -- consistent map length
- All packs within a map are roughly equal difficulty based on area level -- no escalation or random spikes
- A "pack" is an abstract combat unit -- not defined as 1 or many monsters. Just HP, damage, element, attack speed. UI can flavor it later (Phase 17)

### Claude's Discretion
- Specific monster type names and themes per biome
- Exact exponential growth rate within the 5-8% range
- Base stat values for each monster type
- Biome-to-element assignments (alpha placeholder biomes)
- How pack generation selects from the weighted pool

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Godot 4.5 GDScript | 4.5 | Game framework | Project standard |
| Resource (extends Resource) | built-in | Data model base class | Used by Item, Hero, Affix, Currency -- project pattern |
| RefCounted (extends RefCounted) | built-in | Static utility classes | Used by StatCalculator, DefenseCalculator -- project pattern |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| randf() / randi_range() | built-in | Random generation | Pack count rolls, element selection, weighted pool picks |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Resource-based configs | JSON/external files | Resources are type-safe and integrate with Godot editor; JSON adds parsing overhead for no benefit |
| Static utility class | Autoload singleton | Project already uses static `RefCounted` for calculators (StatCalculator, DefenseCalculator); keep consistent |

## Architecture Patterns

### Recommended Project Structure
```
models/
├── monsters/
│   ├── monster_type.gd        # MonsterType Resource (base stat template)
│   ├── monster_pack.gd        # MonsterPack Resource (scaled instance)
│   ├── biome_config.gd        # BiomeConfig Resource (biome settings)
│   └── pack_generator.gd      # PackGenerator static utility
```

### Pattern 1: Resource Template + Scaled Instance
**What:** Separate the "type definition" (MonsterType -- immutable base stats) from the "runtime instance" (MonsterPack -- scaled stats for a specific area level). MonsterType is a template; MonsterPack is what combat consumes.
**When to use:** When base data is reused across many instances with level-dependent modifications.
**Example:**
```gdscript
# MonsterType -- template (never modified at runtime)
class_name MonsterType extends Resource
var type_name: String
var base_hp: float
var base_damage: float
var base_attack_speed: float  # attacks per second

# MonsterPack -- scaled instance (created per map, consumed by combat)
class_name MonsterPack extends Resource
var pack_name: String
var hp: float           # scaled from base_hp
var max_hp: float       # same as hp at creation
var damage: float       # scaled from base_damage
var attack_speed: float # from monster type (not scaled)
var element: String     # "physical", "fire", "cold", "lightning"
```

### Pattern 2: Config-Driven Biome Definitions
**What:** Each biome is a BiomeConfig that declares its level range, primary element, element weights, and available monster type pool. Matches how the project already handles area tiers in `gameplay_view.gd` (level thresholds at 100/200/300).
**When to use:** When biome configuration needs to be easy to reconfigure (user decision: alpha biomes, destined to be replaced).
**Example:**
```gdscript
class_name BiomeConfig extends Resource
var biome_name: String
var level_min: int
var level_max: int       # -1 for uncapped (Shadow Realm)
var primary_element: String
var element_weights: Dictionary  # {"physical": 0.4, "fire": 0.2, ...}
var monster_types: Array[MonsterType]
```

### Pattern 3: Static Generator (like LootTable)
**What:** A static utility class that generates packs for a given area level, following the same pattern as `LootTable` (static functions, no instance state). Takes area level, returns Array of MonsterPack.
**When to use:** For stateless generation logic that produces Resources.
**Example:**
```gdscript
class_name PackGenerator extends RefCounted

static func generate_packs(area_level: int) -> Array[MonsterPack]:
    var biome := get_biome_for_level(area_level)
    var pack_count := randi_range(8, 15)
    var packs: Array[MonsterPack] = []
    for i in range(pack_count):
        var monster_type := pick_random_type(biome)
        var element := roll_element(biome)
        var pack := create_pack(monster_type, area_level, element)
        packs.append(pack)
    return packs
```

### Anti-Patterns to Avoid
- **Shared mutable MonsterType:** Never modify MonsterType at runtime -- always create MonsterPack instances with scaled values. MonsterType is a template.
- **Flat scaling modifiers on shared formula:** User explicitly decided against this -- per-type base stats get multiplied by area level multiplier.
- **Difficulty spikes at biome transitions:** User explicitly decided smooth curves, no jumps at 100/200/300.
- **Mixed damage per pack:** Each pack deals a SINGLE element. No splitting damage across types.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Exponential scaling | Custom curve fitting | Simple `base * pow(1 + rate, level - 1)` | Standard compound growth formula; well-understood behavior |
| Weighted random selection | Manual probability bucketing | Godot's built-in weighted random pattern (accumulate weights, roll, walk) | Already used in LootTable.roll_rarity() -- same pattern |
| Biome level detection | New biome detection system | Extend existing `update_area_difficulty()` pattern from gameplay_view.gd | Already maps level ranges to biome names |

**Key insight:** The project already has working patterns for weighted random (LootTable), static generators (LootTable, StatCalculator), Resource-based data (Item, Hero), and level-to-biome mapping (gameplay_view). Phase 14 follows these exact patterns with monster-specific data.

## Common Pitfalls

### Pitfall 1: Exponential Overflow at High Levels
**What goes wrong:** `pow(1.07, 300)` = ~7,612 multiplier. If base HP is 100, that's 761,200 HP at level 300. Numbers may get unwieldy.
**Why it happens:** Exponential growth compounds aggressively over 300 levels.
**How to avoid:** Choose rate carefully. At 6% per level: `pow(1.06, 299)` = ~42,012x. At 5%: ~17,292x. At 7%: ~97,177x. The user's 5-8% range gives dramatically different results at high levels. Pick a rate that produces sensible numbers given the hero's DPS at equivalent levels. Consider using `pow(1.06, level - 1)` as the sweet spot.
**Warning signs:** Pack HP or damage exceeding millions at level 300.

### Pitfall 2: Attack Speed as Direct Value vs Multiplier
**What goes wrong:** Treating attack_speed as both "attacks per combat tick" and "attacks per second" inconsistently.
**Why it happens:** Combat loop (Phase 15) will interpret attack_speed; if the data model doesn't define units clearly, combat will have to guess.
**How to avoid:** Define attack_speed as "attacks per second" in MonsterType. Phase 15 uses this to determine how often the pack deals damage. Document the unit in the property comment.
**Warning signs:** Combat producing nonsensical damage rates.

### Pitfall 3: Biome Config Duplication with gameplay_view
**What goes wrong:** Biome level thresholds defined in two places (gameplay_view.gd and BiomeConfig) that can drift out of sync.
**Why it happens:** gameplay_view already has `update_area_difficulty()` with hardcoded level thresholds.
**How to avoid:** BiomeConfig becomes the single source of truth for biome data. Phase 15 or later should refactor gameplay_view to read from BiomeConfig instead of hardcoded thresholds. For Phase 14, just ensure BiomeConfig uses the same ranges (1-99, 100-199, 200-299, 300+).
**Warning signs:** Forest appearing at level 150 in one system and Dark Forest in another.

### Pitfall 4: Weighted Element Roll Producing Invalid Results
**What goes wrong:** Element weights don't sum to 1.0, or a biome has no physical weight but physical gets selected.
**Why it happens:** Manual weight configuration with no validation.
**How to avoid:** Normalize weights at generation time (divide each weight by sum of all weights). This makes the system robust to config changes. Always validate that at least one element has weight > 0.
**Warning signs:** Elements appearing at wrong frequencies during testing.

## Code Examples

### Exponential Scaling Formula
```gdscript
# Compound growth: base * (1 + rate)^(level - 1)
# At level 1, multiplier = 1.0 (no scaling)
# At level 100, multiplier = pow(1.06, 99) = ~321x
# At level 300, multiplier = pow(1.06, 299) = ~42,012x
static func get_level_multiplier(area_level: int) -> float:
    var growth_rate := 0.06  # 6% per level
    return pow(1.0 + growth_rate, area_level - 1)
```

### Weighted Element Selection (follows LootTable pattern)
```gdscript
static func roll_element(biome: BiomeConfig) -> String:
    var total_weight := 0.0
    for element in biome.element_weights:
        total_weight += biome.element_weights[element]

    var roll := randf() * total_weight
    var accumulated := 0.0
    for element in biome.element_weights:
        accumulated += biome.element_weights[element]
        if roll < accumulated:
            return element

    # Fallback (should never reach)
    return biome.primary_element
```

### Pack Generation
```gdscript
static func generate_packs(area_level: int) -> Array[MonsterPack]:
    var biome := get_biome_for_level(area_level)
    var pack_count := randi_range(8, 15)
    var multiplier := get_level_multiplier(area_level)
    var packs: Array[MonsterPack] = []

    for i in range(pack_count):
        var monster_type: MonsterType = biome.monster_types.pick_random()
        var element := roll_element(biome)

        var pack := MonsterPack.new()
        pack.pack_name = monster_type.type_name
        pack.hp = monster_type.base_hp * multiplier
        pack.max_hp = pack.hp
        pack.damage = monster_type.base_damage * multiplier
        pack.attack_speed = monster_type.base_attack_speed
        pack.element = element
        packs.append(pack)

    return packs
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hardcoded area difficulty multiplier | Per-type Resource scaling | Phase 14 | Replaces linear `1.0 + (level - 1) * 0.02` with exponential per-type scaling |
| Generic "monster damage" in gameplay_view | Named pack types with specific stats | Phase 14 | Enables meaningful combat variety |
| Physical-only damage | Elemental damage types per pack | Phase 14 | Defense stats (from Phase 13) become meaningful |

**Current state to be replaced:**
- `gameplay_view.gd` line 233: `var base_monster_damage := 10.0 * area_difficulty_multiplier` -- flat linear scaling, no elemental types
- `gameplay_view.gd` line 285: `area_difficulty_multiplier = 1.0 + (area_level - 1) * 0.02` -- linear 2% per level, not exponential

## Open Questions

1. **What hero DPS looks like at level 300?**
   - What we know: Hero damage comes from weapon DPS + affixes, currently no level-based scaling on hero side
   - What's unclear: Whether pack HP at `base * pow(1.06, 299)` will be clearable in reasonable time
   - Recommendation: Start with 6% growth rate, tune after Phase 15 implements combat loop. Base stats for types should produce packs that a well-geared hero can clear in 2-5 seconds at equivalent area level.

2. **Should attack_speed scale with area level?**
   - What we know: User said HP and damage scale at the same rate. Attack speed not mentioned for scaling.
   - What's unclear: Whether faster attacks at higher levels is desired
   - Recommendation: Keep attack_speed as a fixed per-type stat (not scaled). This preserves type identity (fast imps stay fast, slow bears stay slow). Difficulty already scales via HP and damage.

## Sources

### Primary (HIGH confidence)
- Codebase analysis: `models/items/item.gd`, `models/hero.gd`, `models/stats/defense_calculator.gd`, `models/stats/stat_calculator.gd`, `models/loot/loot_table.gd` -- established Resource patterns, static utility patterns, weighted random patterns
- Codebase analysis: `scenes/gameplay_view.gd` -- current area/biome system, damage calculation, existing combat flow
- Codebase analysis: `autoloads/tag.gd` -- existing element/damage type constants

### Secondary (MEDIUM confidence)
- Exponential scaling math: standard compound growth formula, well-established game design pattern

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Using existing project patterns (Resource, RefCounted, static utility)
- Architecture: HIGH - Direct extension of established codebase patterns (Item, LootTable, DefenseCalculator)
- Pitfalls: HIGH - Identified from codebase analysis (scaling math, biome duplication, weight normalization)

**Research date:** 2026-02-16
**Valid until:** 2026-03-16 (stable domain, no external dependencies)
