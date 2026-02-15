# Phase 3: Unified Calculations - Research

**Researched:** 2026-02-15
**Domain:** Stat calculation systems, modifier application order, tag-based routing
**Confidence:** HIGH

## Summary

Phase 3 consolidates duplicate stat calculation logic and resolves formula inconsistencies between weapon.gd and ring.gd. The codebase currently has two different critical strike formulas producing different results, inconsistent handling of flat vs percentage modifiers, and no clear separation between tags used for affix filtering (which items can roll which affixes) versus tags used for calculation routing (how affix values affect stats).

The standard approach in RPG stat systems follows a strict order of operations: flat modifiers first, then additive (increased/reduced) modifiers summed together, then multiplicative (more/less) modifiers applied separately. The current codebase violates this in multiple places - weapon.gd applies speed before crit, ring.gd applies speed after crit, and the crit formulas themselves differ mathematically.

Godot's Resource-based architecture (already implemented in Phase 2) enables a clean separation: AffixTag constants control eligibility (Item.has_valid_tag() checks), while a new StatType system routes values into the calculation pipeline. The existing update_value() interface across all item types provides the foundation for unified behavior.

**Primary recommendation:** Create a central StatCalculator class that implements order-of-operations correctly, separate AffixTag from StatType enums, and refactor all items to delegate calculation to the shared system.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Godot Engine | 4.5 | Game engine and scripting runtime | Already in use, Resources established in Phase 2 |
| GDScript | 2.0 | Primary scripting language | Native to Godot 4, type hints established in Phase 1 |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| gdformat | Latest | Code formatting | Already used (Phase 1 requirement) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Central calculator | Strategy pattern per damage type | Overcomplicated for 5 item types - premature abstraction per REQUIREMENTS.md line 88 |
| String constants | Enums for tags | Already using string constants in Tag autoload - changing now adds risk with no benefit |
| Composition | Modifier pipeline system | Explicitly out of scope (REQUIREMENTS.md line 87) - unify first, formalize later |

**Installation:**
No external dependencies - pure GDScript refactoring.

## Architecture Patterns

### Recommended Project Structure
```
models/
├── items/              # Item subclasses (existing)
│   ├── item.gd        # Base class with unified update_value()
│   ├── weapon.gd
│   ├── ring.gd
│   ├── armor.gd
│   ├── helmet.gd
│   └── boots.gd
├── affixes/           # Affix classes (existing)
│   ├── affix.gd
│   └── implicit.gd
└── stats/             # NEW - calculation system
    └── stat_calculator.gd   # Unified calculation logic
autoloads/
├── tag.gd             # SPLIT into two enums: AffixTag and StatType
├── game_state.gd      # (existing)
└── game_events.gd     # (existing)
```

### Pattern 1: Unified Stat Calculator (Composition)
**What:** Central calculation class that all items delegate to, implementing correct order of operations
**When to use:** When multiple classes share calculation logic but differ in base stats
**Example:**
```gdscript
# models/stats/stat_calculator.gd
class_name StatCalculator extends RefCounted

static func calculate_dps(base_damage: int, base_speed: int, affixes: Array[Affix], base_crit_chance: float = 5.0, base_crit_damage: float = 150.0) -> float:
	# Order of operations: base -> flat -> additive -> multiplicative -> final modifiers
	var damage := float(base_damage)
	var speed := float(base_speed)
	var crit_chance := base_crit_chance
	var crit_damage := base_crit_damage

	# Step 1: Flat damage additions
	for affix: Affix in affixes:
		if StatType.FLAT_DAMAGE in affix.stat_types:
			damage += affix.value

	# Step 2: Additive damage multipliers (sum all "increased" modifiers)
	var additive_damage_mult := 0.0
	for affix: Affix in affixes:
		if StatType.INCREASED_DAMAGE in affix.stat_types:
			additive_damage_mult += affix.value / 100.0
	damage *= (1.0 + additive_damage_mult)

	# Step 3: Multiplicative damage (apply each "more" separately)
	for affix: Affix in affixes:
		if StatType.MORE_DAMAGE in affix.stat_types:
			damage *= (1.0 + affix.value / 100.0)

	# Step 4: Attack speed (additive)
	var additive_speed_mult := 0.0
	for affix: Affix in affixes:
		if StatType.INCREASED_SPEED in affix.stat_types:
			additive_speed_mult += affix.value / 100.0
	speed *= (1.0 + additive_speed_mult)

	# Step 5: Crit modifiers (flat additions)
	for affix: Affix in affixes:
		if StatType.CRIT_CHANCE in affix.stat_types:
			crit_chance += affix.value
		if StatType.CRIT_DAMAGE in affix.stat_types:
			crit_damage += affix.value

	# Step 6: Calculate final DPS (damage * speed * crit_multiplier)
	var base_dps := damage * speed
	var crit_multiplier := calculate_crit_multiplier(crit_chance, crit_damage)
	return base_dps * crit_multiplier

static func calculate_crit_multiplier(crit_chance: float, crit_damage: float) -> float:
	# Correct formula: weighted average of non-crit and crit hits
	# non_crit_portion + crit_portion = (1-c) + c*d = 1 + c*(d-1)
	# Where c = crit_chance/100, d = crit_damage/100
	var c := crit_chance / 100.0
	var d := crit_damage / 100.0
	return 1.0 + c * (d - 1.0)
```

**Item usage:**
```gdscript
# weapon.gd
func update_value() -> void:
	var all_affixes := self.prefixes + self.suffixes
	all_affixes.append(self.implicit)
	self.dps = StatCalculator.calculate_dps(
		self.base_damage,
		self.base_speed,
		all_affixes,
		self.crit_chance,
		self.crit_damage
	)
```

### Pattern 2: Tag Separation (AffixTag vs StatType)
**What:** Split Tag autoload into two distinct enums - one for affix filtering, one for calculation routing
**When to use:** When the same tag serves two different purposes causing confusion
**Example:**
```gdscript
# autoloads/tag.gd
class_name Tag_List extends Node

# AffixTag: Controls which affixes can roll on which items
# Used by: Item.has_valid_tag(), ItemAffixes filtering
const WEAPON = "WEAPON"
const ARMOR = "ARMOR"
const DEFENSE = "DEFENSE"
const PHYSICAL = "PHYSICAL"  # "Physical damage affixes can roll on this item"
const ELEMENTAL = "ELEMENTAL"
const CRITICAL = "CRITICAL"  # "Crit affixes can roll on this item"

# StatType: Routes affix values into calculations
# Used by: StatCalculator to determine how to apply affix.value
enum StatType {
	FLAT_DAMAGE,           # Adds to base damage
	INCREASED_DAMAGE,      # Additive % damage (summed with other increased)
	MORE_DAMAGE,           # Multiplicative % damage (applied separately)
	INCREASED_SPEED,       # Additive % attack speed
	CRIT_CHANCE,           # Flat crit chance addition
	CRIT_DAMAGE,           # Flat crit damage addition
	FLAT_ARMOR,            # Defense stats
	INCREASED_ARMOR,
	FLAT_ENERGY_SHIELD,
	FLAT_HEALTH,
	FLAT_MANA,
	MOVEMENT_SPEED
}
```

**Migration strategy:**
```gdscript
# affix.gd changes
class_name Affix extends Resource

var tags: Array[String]           # AffixTags - for filtering
var stat_types: Array[int]        # StatTypes - for calculation routing

# Example affix definitions:
# "+10 Physical Damage" affix:
#   tags = [Tag.PHYSICAL, Tag.WEAPON]  -> can roll on physical weapon items
#   stat_types = [StatType.FLAT_DAMAGE]  -> adds to damage as flat modifier

# "15% Increased Physical Damage" affix:
#   tags = [Tag.PHYSICAL, Tag.WEAPON]  -> can roll on physical weapon items
#   stat_types = [StatType.INCREASED_DAMAGE]  -> multiplies damage additively
```

### Pattern 3: Standardized Item Interface
**What:** All item subclasses implement update_value() consistently, delegating to appropriate calculator
**When to use:** When subclasses need identical behavior with different inputs
**Example:**
```gdscript
# item.gd - base class defines contract
class_name Item extends Resource

func update_value() -> void:
	# Default no-op - subclasses override
	pass

# weapon.gd
func update_value() -> void:
	var all_affixes := self.prefixes + self.suffixes
	all_affixes.append(self.implicit)
	self.dps = StatCalculator.calculate_dps(
		self.base_damage, self.base_speed, all_affixes,
		self.crit_chance, self.crit_damage
	)

# armor.gd
func update_value() -> void:
	var all_affixes := self.prefixes + self.suffixes
	all_affixes.append(self.implicit)
	self.base_armor = self.original_base_armor + StatCalculator.calculate_flat_stat(
		all_affixes, StatType.FLAT_ARMOR
	)
	self.base_energy_shield = self.original_base_energy_shield + StatCalculator.calculate_flat_stat(
		all_affixes, StatType.FLAT_ENERGY_SHIELD
	)
	self.total_defense = self.base_armor  # Simple for now
```

### Anti-Patterns to Avoid
- **String parsing in calculations:** Current code checks `if "Chance" in affix.affix_name` (weapon.gd line 66) - fragile and breaks if names change. Use stat_types instead.
- **Inconsistent formula implementations:** weapon.gd and ring.gd have different crit formulas - choose one correct implementation and share it.
- **Mixing concerns in tags:** Current Tag constants serve both filtering AND calculation routing - causes confusion about what PHYSICAL means in context.
- **Order-of-operations violations:** Applying speed before vs after crit produces different results - establish one correct order and enforce it.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Modifier order of operations | Custom per-item calculation chains | Standard flat -> additive -> multiplicative pipeline | Industry standard pattern, prevents balance issues, easier to reason about |
| Critical strike DPS formula | Different formulas per item type | Single weighted-average formula: `1 + crit_chance/100 * (crit_damage/100 - 1)` | Mathematically correct expected value calculation |
| Stat aggregation | Loop through affixes in each item | Central StatCalculator.calculate_flat_stat() helper | Eliminates duplication, single source of truth |
| Tag checking logic | if-chains with string comparisons | Enum-based StatType routing | Type-safe, refactor-friendly, IDE autocomplete |

**Key insight:** Stat calculation bugs are extremely hard to debug when the logic is scattered across multiple files. Every RPG that grows beyond prototype scale eventually centralizes this logic. The current codebase is at that threshold - two DPS implementations already diverged, adding more item types will make it unmaintainable.

## Common Pitfalls

### Pitfall 1: Order of Operations Inconsistency
**What goes wrong:** Different items apply the same modifiers in different orders, producing inconsistent results. weapon.gd multiplies damage by speed at line 79 before applying crit, ring.gd multiplies by speed at line 37 after crit.
**Why it happens:** Each implementation was written independently without a shared specification for calculation order.
**How to avoid:** Define a strict order in StatCalculator and enforce it for all items: base -> flat -> additive -> multiplicative -> final. Document the order in code comments.
**Warning signs:** Two items with identical stats showing different DPS values. Test case: create weapon and ring with same base_damage, base_speed, and affixes - they should calculate identically.

### Pitfall 2: Critical Strike Formula Confusion
**What goes wrong:** weapon.gd uses weighted average formula (correct), ring.gd uses simplified approximation (incorrect for expected DPS). With 5% crit chance and 150% crit damage on 100 base DPS: weapon calculates 102.5 (correct), ring calculates 107.5 (wrong).
**Why it happens:** Crit calculations are non-intuitive. The simplified formula `1 + crit_chance * crit_damage` is a common mistake - it doesn't account for the fact that crit chance replaces normal hits, not adds to them.
**How to avoid:** Use the mathematically correct formula: `1 + (crit_chance/100) * (crit_damage/100 - 1)`. This represents the weighted average of non-crit hits (100% damage) and crit hits (crit_damage% damage).
**Warning signs:** DPS values seem too high when crit is involved. Crit chance above 100% doesn't break the formula (in real systems it should cap at 100%).

### Pitfall 3: Flat vs Percentage Modifier Confusion
**What goes wrong:** weapon.gd correctly distinguishes FLAT (adds value) from PERCENTAGE (multiplies by value/100), but ring.gd treats all modifiers as flat additions (line 26-28). This causes percentage modifiers to apply incorrectly.
**Why it happens:** Tags serve dual purposes (filtering AND calculation routing) with no clear specification of which is which.
**How to avoid:** Separate AffixTag (filtering) from StatType (calculation). PHYSICAL is an AffixTag meaning "this is a physical damage affix", while FLAT_DAMAGE and INCREASED_DAMAGE are StatTypes indicating how to apply the value.
**Warning signs:** A "50% increased physical damage" affix adding 50 to DPS instead of multiplying by 1.5. Check affix application by logging before/after values.

### Pitfall 4: Breaking Changes to Affix Data
**What goes wrong:** Adding stat_types array to Affix class risks breaking existing .tres resource files that only have tags defined.
**Why it happens:** Godot's resource loader expects all properties to be serialized. Adding a new required property breaks deserialization of old files.
**How to avoid:** Initialize stat_types with default value in _init: `var stat_types: Array[int] = []`. During migration, populate stat_types from tags using a mapping function. Verify all basic_*.gd concrete items still instantiate correctly.
**Warning signs:** Errors on game launch about missing properties. Items showing null affixes. Resource loader warnings in console.

### Pitfall 5: String-Based Tag Checking Fragility
**What goes wrong:** Current code uses `if "Chance" in affix.affix_name` (weapon.gd line 66) to distinguish crit chance from crit damage. Renaming an affix breaks calculation silently.
**Why it happens:** No explicit metadata on affixes for what stat they modify, so code infers from name strings.
**How to avoid:** Use stat_types enum to explicitly declare what each affix modifies. `if StatType.CRIT_CHANCE in affix.stat_types` is refactor-safe and clear.
**Warning signs:** Renaming an affix causes DPS to change. Adding new affixes requires updating multiple if-chains across item classes.

### Pitfall 6: Defense Item Calculations Left Inconsistent
**What goes wrong:** armor.gd, helmet.gd, and boots.gd use simple flat addition (armor.gd line 23: `total_armor += affix.value`) with no support for percentage modifiers. If you later add "10% increased armor" affixes, they'll be treated as flat +10 armor.
**Why it happens:** Defense items were simpler prototypes and never got the same calculation complexity as weapons.
**How to avoid:** Even though defense items currently only use flat stats, route them through StatCalculator.calculate_flat_stat() or equivalent so the infrastructure is ready for percentage modifiers. Consistency prevents future bugs.
**Warning signs:** Defense items and damage items have completely different calculation code paths. Adding a new stat type requires touching different code for each item category.

## Code Examples

### Standard Modifier Application Order
```gdscript
# Source: Industry standard pattern (Path of Exile, Diablo 3)
# Verified via: https://www.pathofexile.com/forum/view-thread/892570
# Pattern: flat -> additive -> multiplicative

static func apply_modifiers(base_value: float, affixes: Array[Affix], flat_type: int, additive_type: int, mult_type: int) -> float:
	var result := base_value

	# Step 1: Flat additions
	for affix in affixes:
		if flat_type in affix.stat_types:
			result += affix.value

	# Step 2: Additive multipliers (summed together)
	var additive_sum := 0.0
	for affix in affixes:
		if additive_type in affix.stat_types:
			additive_sum += affix.value / 100.0
	result *= (1.0 + additive_sum)

	# Step 3: Multiplicative multipliers (applied separately)
	for affix in affixes:
		if mult_type in affix.stat_types:
			result *= (1.0 + affix.value / 100.0)

	return result
```

### Correct Critical Strike DPS Formula
```gdscript
# Source: Probability theory - expected value calculation
# Formula: E[damage] = P(non-crit)*damage_non_crit + P(crit)*damage_crit
#                    = (1-c)*1 + c*d  (normalized to base damage)
#                    = 1 - c + c*d
#                    = 1 + c*(d-1)
# Where: c = crit_chance/100, d = crit_damage/100

static func calculate_crit_multiplier(crit_chance: float, crit_damage: float) -> float:
	var c := crit_chance / 100.0
	var d := crit_damage / 100.0
	return 1.0 + c * (d - 1.0)

# Test cases:
# - 0% crit, 150% crit_damage -> 1.0 (no change)
# - 100% crit, 150% crit_damage -> 1.5 (always crits at 150%)
# - 5% crit, 150% crit_damage -> 1.025 (2.5% DPS increase)
# - 50% crit, 200% crit_damage -> 1.5 (50% DPS increase)
```

### Tag Migration Pattern
```gdscript
# Migration helper to populate stat_types from legacy tags
static func migrate_affix_tags_to_stat_types(affix: Affix) -> void:
	if affix.stat_types.size() > 0:
		return  # Already migrated

	# Map old tag combinations to new stat types
	if Tag.PHYSICAL in affix.tags and Tag.FLAT in affix.tags:
		affix.stat_types.append(StatType.FLAT_DAMAGE)

	if Tag.PHYSICAL in affix.tags and Tag.PERCENTAGE in affix.tags:
		affix.stat_types.append(StatType.INCREASED_DAMAGE)

	if Tag.SPEED in affix.tags:
		affix.stat_types.append(StatType.INCREASED_SPEED)

	if Tag.CRITICAL in affix.tags:
		if "Chance" in affix.affix_name:
			affix.stat_types.append(StatType.CRIT_CHANCE)
		elif "Damage" in affix.affix_name:
			affix.stat_types.append(StatType.CRIT_DAMAGE)

	if Tag.ARMOR in affix.tags:
		affix.stat_types.append(StatType.FLAT_ARMOR)

	# Add more mappings as needed...
```

## Current State Analysis

### Existing Calculations Inventory

**weapon.gd (lines 20-96):**
- Handles: flat physical damage, % physical damage, attack speed, crit chance, crit damage
- Formula: (damage + flat) * (1 + percentage/100) * speed * crit_multiplier
- Crit formula: weighted average (CORRECT)
- Tag checks: PHYSICAL+FLAT, PHYSICAL+PERCENTAGE, SPEED, CRITICAL+"Chance", CRITICAL+"Damage"

**ring.gd (lines 15-37):**
- Handles: attack damage (flat only), speed (flat only), crit chance, crit damage
- Formula: (damage + flat) * (speed + flat) * crit_multiplier
- Crit formula: simplified approximation (INCORRECT)
- Tag checks: ATTACK, SPEED, CRITICAL+"Chance", CRITICAL+"Damage"

**armor.gd (lines 12-34):**
- Handles: armor, energy_shield, health (all flat addition only)
- Formula: original_base + sum(affix.value for matching tags)
- Tag checks: ARMOR, ENERGY_SHIELD, DEFENSE+"Health"

**helmet.gd (lines 12-34):**
- Handles: armor, energy_shield, mana (all flat addition only)
- Formula: original_base + sum(affix.value for matching tags)
- Tag checks: ARMOR, ENERGY_SHIELD, MANA

**boots.gd (lines 12-34):**
- Handles: armor, movement_speed, energy_shield (all flat addition only)
- Formula: original_base + sum(affix.value for matching tags)
- Tag checks: ARMOR, SPEED or MOVEMENT, ENERGY_SHIELD

### Identified Inconsistencies

| Issue | Location | Impact | Solution |
|-------|----------|--------|----------|
| Two different crit formulas | weapon.gd L82-85 vs ring.gd L36 | Ring calculates 5% higher DPS than weapon with same stats | Standardize on weapon's weighted average formula |
| Speed applied at different stages | weapon.gd L79 (before crit) vs ring.gd L37 (after crit) | Same speed modifier produces different final DPS | Apply speed before crit consistently |
| Inconsistent tag checking | weapon.gd checks PHYSICAL+FLAT vs ring.gd checks ATTACK | Adding new damage types requires different code per item | Use StatType enum instead of tag combinations |
| String parsing for crit types | weapon.gd L66, L72 check affix name | Renaming affixes breaks calculation | Add stat_types to Affix class |
| No percentage support in defense items | armor/helmet/boots only add flat values | Can't add "% increased armor" affixes | Route through StatCalculator with additive support |

### Test Scenarios for Validation

After refactoring, these test cases must pass:

```gdscript
# Test 1: Identical stats should produce identical DPS
var weapon = LightSword.new()  # base_damage: 10, base_speed: 2
var ring = BasicRing.new()     # base_damage: 10, base_speed: 2
weapon.update_value()
ring.update_value()
assert(absf(weapon.dps - ring.dps) < 0.01, "Weapon and ring with same stats should have same DPS")

# Test 2: Critical strike math check
# Formula: 1 + crit_chance/100 * (crit_damage/100 - 1)
# 5% crit, 150% crit damage: 1 + 0.05 * (1.5 - 1) = 1.025
var base_dps = 100.0
var expected = base_dps * 1.025  # 102.5
var actual = StatCalculator.calculate_dps(10, 10, [], 5.0, 150.0)
assert(absf(actual - expected) < 0.01, "Crit multiplier calculation incorrect")

# Test 3: Modifier order independence
# Adding modifiers in different orders should produce same result
var affixes_order1 = [speed_affix, damage_affix, crit_affix]
var affixes_order2 = [crit_affix, speed_affix, damage_affix]
var dps1 = StatCalculator.calculate_dps(10, 2, affixes_order1)
var dps2 = StatCalculator.calculate_dps(10, 2, affixes_order2)
assert(absf(dps1 - dps2) < 0.01, "Modifier order should not affect result")
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Each item implements own calculation | Shared StatCalculator utility class | Industry standard since ~2010 | Single source of truth, easier testing, formula bugs fixed once |
| String tag combinations for routing | Explicit StatType enum | Modern game engines (Unreal GameplayTags, Unity ScriptableObjects) | Type-safe, refactor-friendly, IDE support |
| String parsing for affix types | Metadata-driven stat routing | Common in data-driven design since 2015+ | Name changes don't break logic, internationalization-friendly |
| Simplified crit formula (incorrect) | Weighted average formula | Always correct in probability theory | Accurate DPS calculations for balancing |

**Deprecated/outdated:**
- Checking affix names with string contains - use stat_types metadata
- Duplicate calculation methods across item types - use shared calculator
- Tags serving dual purposes - separate filtering (AffixTag) from routing (StatType)

## Open Questions

1. **Should defense items support percentage modifiers now or later?**
   - What we know: Current affixes are all flat (armor.gd L23: `total_armor += affix.value`)
   - What's unclear: Will v0.1 need "% increased armor" affixes, or can it wait until v1.0?
   - Recommendation: Add StatType infrastructure now (LOW effort), populate affixes later. Prevents having to refactor defense items twice.

2. **Should StatType be an enum or string constants like AffixTag?**
   - What we know: Tag autoload uses string constants (tag.gd L3-20). Enums offer type safety but string constants match existing pattern.
   - What's unclear: Is consistency with current pattern more valuable than type safety?
   - Recommendation: Use enum for StatType (type safety + IDE autocomplete) but keep AffixTag as strings (already working, no benefit to changing). Mixed approach is acceptable when reasons differ.

3. **What happens to existing .tres affix files when adding stat_types property?**
   - What we know: Affix._init() has defaults for all parameters (Phase 2 decision, 02-01-PLAN.md)
   - What's unclear: Will Godot's resource loader automatically initialize stat_types = [] or fail?
   - Recommendation: Test by adding the property, launching game, and checking console. If errors, write migration script. Likely safe due to default parameters.

4. **Should compute_dps() be removed entirely or kept as a thin wrapper?**
   - What we know: weapon.gd and ring.gd both have compute_dps() methods. Removing breaks any external code calling them.
   - What's unclear: Is anything besides update_value() calling compute_dps()? Need to grep codebase.
   - Recommendation: Keep as thin wrapper initially: `func compute_dps() -> float: return StatCalculator.calculate_dps(...)`. Can deprecate later if unused.

5. **How to handle damage types beyond physical (fire, cold, lightning)?**
   - What we know: weapon.gd declares phys_dps, bleed_dps, lightning_dps, cold_dps, fire_dps but never populates them
   - What's unclear: Is elemental damage planned for v0.1 or deferred to v1.0?
   - Recommendation: Ignore elemental damage for Phase 3. Focus on unifying existing calculations. Elemental can be added to StatCalculator later without breaking the pattern.

## Sources

### Primary (HIGH confidence)
- Current codebase analysis: weapon.gd, ring.gd, armor.gd, helmet.gd, boots.gd, item.gd, affix.gd, tag.gd
- Godot official documentation: [Singletons (Autoload)](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html), [Resources](https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html)
- Phase 2 decisions: .planning/phases/02-data-model-migration/02-01-PLAN.md, 02-02-PLAN.md
- REQUIREMENTS.md: Lines 31-34 (CALC-01 through CALC-04)

### Secondary (MEDIUM confidence)
- [Stat modifier calculation order best practices](https://github.com/meredoth/Stat-System) - Unity implementation showing flat -> additive -> multiplicative pattern
- [Path of Exile modifier discussion](https://www.pathofexile.com/forum/view-thread/892570) - Industry example of "increased" (additive) vs "more" (multiplicative)
- [How to Deal with Modifiable Stats in RPGs](https://refreshertowelgames.wordpress.com/2024/02/17/how-to-comfortably-deal-with-modifiable-stats/) - Order of operations explanation
- [Godot Strategy Pattern tutorial](https://www.gdquest.com/tutorial/godot/design-patterns/strategy/) - GDQuest's pattern guide
- [Top Game Development Patterns in Godot](https://www.manuelsanchezdev.com/blog/game-development-patterns) - Strategy pattern applications

### Tertiary (LOW confidence)
- [Modular Stat/Attribute System for Godot 4](https://medium.com/@minoqi/modular-stat-attribute-system-tutorial-for-godot-4-0bac1c5062ce) - Tutorial reference (paywalled, couldn't verify)
- [GameplayTags vs Enums discussion](https://tomlooman.com/unreal-engine-gameplaytags-data-driven-design/) - Unreal Engine pattern (different engine but relevant concepts)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - existing Godot 4.5 codebase, no external dependencies
- Architecture: HIGH - patterns verified in codebase and official Godot docs, stat order verified via industry sources
- Pitfalls: HIGH - identified by direct code analysis, specific line numbers and test cases provided
- Stat calculation formulas: HIGH - mathematical correctness verified via probability theory and cross-referenced with industry implementations

**Research date:** 2026-02-15
**Valid until:** 2026-03-15 (30 days - stable domain, Godot patterns don't change rapidly)

**Assumptions:**
- v0.1 scope remains code cleanup only (no new gameplay features)
- Modifier pipeline formalization deferred to post-v0.1 (per REQUIREMENTS.md line 87)
- All items continue using Resource pattern established in Phase 2
- gdformat and type hints standards from Phase 1 continue
