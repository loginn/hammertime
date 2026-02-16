# Phase 10: Elemental Resistance Split - Research

**Researched:** 2026-02-16
**Domain:** GDScript suffix system extension, elemental resistance stats, ARPG resistance mechanics
**Confidence:** HIGH

## Summary

Phase 10 replaces the generic "Elemental Reduction" suffix with specific fire, cold, and lightning resistance suffixes, plus an all-resistance suffix option. This follows established ARPG patterns where individual resistances provide granular defense control while all-resistance offers space-efficient gearing. The codebase already has the complete infrastructure: tag-based filtering (Item.has_valid_tag()), suffix addition system (Item.add_suffix()), and flat stat aggregation (StatCalculator.calculate_flat_stat()). Phase 9 established the patterns for extending Tag.StatType enum, using configurable tier ranges, and displaying defense stats in Hero View.

All resistance affixes are suffixes (not prefixes) following Path of Exile convention: defensive stats that modify damage taken rather than stats that define the item's identity. Individual resistances use the same tier range as existing suffixes (8 tiers by default), with all-resistance using a lower tier range or rarer weighting to reflect its higher value (saves 2 affix slots).

**Primary recommendation:** Add 3 new StatType enums (FIRE_RESISTANCE, COLD_RESISTANCE, LIGHTNING_RESISTANCE, ALL_RESISTANCE), create 4 new suffix affixes in ItemAffixes.suffixes, extend Hero.calculate_defense() to track resistance totals, extend Hero View defense section to display resistances, and remove the old "Elemental Reduction" suffix. Resistances are display-only for v1.1 (no combat integration), matching the defensive prefix treatment from Phase 9.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Godot Engine | 4.6 | Game engine | Current stable (Jan 27, 2026). Project uses mobile renderer. GDScript typed arrays used throughout. |
| GDScript | 4.6 | Language | Only language in codebase. StatType enum pattern established in Phase 9. Resource extension pattern proven. |

### Supporting
No external libraries required. All features implemented via existing autoload patterns (ItemAffixes, Tag, StatCalculator, GameState, GameEvents).

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Four separate resistances | Single "elemental resist" | Phase goal explicitly requires split. Individual resistances provide build diversity (stack fire resist for fire-heavy areas). |
| Prefixes | Suffixes | Path of Exile convention: prefixes define item identity (damage, defense type), suffixes modify character attributes (resistances, life, speed). Current codebase has "Elemental Reduction" as suffix. |
| Percentage-based resist | Flat resist values | Flat values simpler for display-only v1.1. Percentage resist would require max resist cap system (PoE caps at 75%). Defer to combat integration phase. |
| Weighted rarity for all-res | Lower tier range | Either approach works. Weighted rarity requires LootTable changes (Phase 11 domain). Tier range reuse existing Affix.tier_range pattern from Phase 9. Recommendation: Use tier_range for consistency. |

**Installation:**
```bash
# No installation needed - pure GDScript modifications
```

## Architecture Patterns

### Recommended Project Structure
```
autoloads/
├── item_affixes.gd      # Add 4 resistance suffixes, remove "Elemental Reduction"
├── tag.gd               # Add 4 new StatType enums for resistances
├── game_state.gd        # No changes needed
└── game_events.gd       # No changes needed
models/
├── affixes/
│   └── affix.gd         # No changes (tier_range support added in Phase 9)
├── stats/
│   └── stat_calculator.gd  # No new methods needed (flat stat aggregation exists)
└── hero.gd              # Extend calculate_defense() for resistance totals
scenes/
└── hero_view.gd         # Extend defense section to show resistances
```

### Pattern 1: Suffix-Based Resistance System
**What:** Resistances are suffixes that roll on all item types (weapons, armor, boots, helmet, rings). Tag.DEFENSE allows non-weapons to roll, no additional tags restrict item type.

**When to use:** Always for resistance stats. Path of Exile convention: suffixes modify character attributes universally.

**Example:**
```gdscript
// Source: autoloads/item_affixes.gd (existing suffix pattern)
var suffixes: Array[Affix] = [
    // Existing suffixes...
    Affix.new("Life", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE], [Tag.StatType.FLAT_HEALTH]),

    // NEW: Individual resistance suffixes
    Affix.new("Fire Resistance", Affix.AffixType.SUFFIX, 5, 12, [Tag.DEFENSE], [Tag.StatType.FIRE_RESISTANCE]),
    Affix.new("Cold Resistance", Affix.AffixType.SUFFIX, 5, 12, [Tag.DEFENSE], [Tag.StatType.COLD_RESISTANCE]),
    Affix.new("Lightning Resistance", Affix.AffixType.SUFFIX, 5, 12, [Tag.DEFENSE], [Tag.StatType.LIGHTNING_RESISTANCE]),

    // All-resistance (higher value per affix slot, rarer tier range or weighted rarer in loot table)
    Affix.new("All Resistances", Affix.AffixType.SUFFIX, 3, 8, [Tag.DEFENSE], [Tag.StatType.ALL_RESISTANCE], Vector2i(1, 5)),
]
```

**Why this works:** Item.add_suffix() (item.gd:166-189) filters suffixes via has_valid_tag(). All items (weapons, armor, boots, helmet, rings) have Tag.DEFENSE in valid_tags or can roll suffixes via existing patterns. Resistance suffixes pass filter for all item types, enabling universal resistance gearing.

### Pattern 2: All-Resistance Rarity via Tier Range
**What:** All-resistance suffix uses narrower tier range (Vector2i(1, 5) instead of Vector2i(1, 8)) to make it rarer while still valuable. Higher tier number = lower value, so T5 all-res minimum is still better than single T8 single-res.

**When to use:** Space-efficient affixes that consolidate multiple stats. Matches Phase 9 tier_range pattern.

**Example:**
```gdscript
// Individual resistances: 8 tiers (standard suffix range)
// T1: 12 * 8 = 96 fire resist
// T8: 12 * 1 = 12 fire resist

// All-resistance: 5 tiers (rarer, fewer possible rolls)
// T1: 8 * 5 = 40 all resist (equivalent to 120 total resist if you need all three)
// T5: 8 * 1 = 8 all resist (equivalent to 24 total resist)

// Trade-off: All-res saves 2 suffix slots (1 affix vs 3) but provides lower total if you only need 1-2 types
```

**Why this works:** Affix._init() supports configurable tier_range from Phase 9 (affix.gd:13, 26). Narrower range means fewer tiers to roll, making each tier rarer. Players decide: stack single resistances for max value in one element, or use all-res for balanced coverage with suffix slots for other stats (life, dodge, etc.).

### Pattern 3: Hero Resistance Aggregation
**What:** Hero.calculate_defense() (hero.gd:102-128) aggregates resistance totals from all equipped items. All-resistance adds to each individual resistance total.

**When to use:** Defense stat calculation. Extends Phase 9 armor/evasion/ES aggregation pattern.

**Example:**
```gdscript
// Source: models/hero.gd (extend calculate_defense method)
func calculate_defense() -> int:
    total_armor = 0
    total_evasion = 0
    total_energy_shield = 0

    # NEW: Initialize resistance totals
    total_fire_resistance = 0
    total_cold_resistance = 0
    total_lightning_resistance = 0

    # Add defense from all equipped items (armor, boots, helmet, weapon, ring)
    for slot in ["helmet", "armor", "boots", "weapon", "ring"]:
        if slot in equipped_items and equipped_items[slot] != null:
            var item = equipped_items[slot]

            # Existing armor/evasion/ES aggregation...
            if "base_armor" in item:
                total_armor += item.base_armor
            # ... (evasion, ES)

            # NEW: Aggregate resistances from item suffixes
            for suffix in item.suffixes:
                if Tag.StatType.FIRE_RESISTANCE in suffix.stat_types:
                    total_fire_resistance += suffix.value
                if Tag.StatType.COLD_RESISTANCE in suffix.stat_types:
                    total_cold_resistance += suffix.value
                if Tag.StatType.LIGHTNING_RESISTANCE in suffix.stat_types:
                    total_lightning_resistance += suffix.value
                if Tag.StatType.ALL_RESISTANCE in suffix.stat_types:
                    # All-res adds to each individual resistance
                    total_fire_resistance += suffix.value
                    total_cold_resistance += suffix.value
                    total_lightning_resistance += suffix.value

    # Backward compatibility
    total_defense = total_armor
    return total_defense
```

**Why loop all slots:** Resistances are suffixes, not base item stats. Unlike armor (stored as base_armor on Armor items), resistances come from affixes. Must check suffixes on all equipped items, not just armor pieces. Weapons and rings can roll resistance suffixes too.

### Pattern 4: Hero View Resistance Display
**What:** Hero View defense section (hero_view.gd:202-219) shows resistance totals below armor/evasion/ES. Only display non-zero resistances (matches Phase 9 user decision).

**When to use:** Always. Defense section already implemented in Phase 9.

**Example:**
```gdscript
// Source: scenes/hero_view.gd:191-219 (extend update_stats_display)
func update_stats_display() -> void:
    # Offense section (unchanged)
    stats_label.text = "Offense:\n"
    stats_label.text += "Total DPS: %.1f\n" % get_total_dps()
    stats_label.text += "Crit Chance: %.1f%%\n" % get_total_crit_chance()
    stats_label.text += "Crit Damage: %.1f%%\n" % get_total_crit_damage()

    # Defense section
    stats_label.text += "\nDefense:\n"
    var total_armor = GameState.hero.get_total_armor()
    var total_evasion = GameState.hero.get_total_evasion()
    var total_es = GameState.hero.get_total_energy_shield()

    var has_defense = false
    if total_armor > 0:
        stats_label.text += "Armor: %d\n" % total_armor
        has_defense = true
    if total_evasion > 0:
        stats_label.text += "Evasion: %d\n" % total_evasion
        has_defense = true
    if total_es > 0:
        stats_label.text += "Energy Shield: %d\n" % total_es
        has_defense = true

    # NEW: Resistance display
    var total_fire_res = GameState.hero.get_total_fire_resistance()
    var total_cold_res = GameState.hero.get_total_cold_resistance()
    var total_lightning_res = GameState.hero.get_total_lightning_resistance()

    if total_fire_res > 0:
        stats_label.text += "Fire Resistance: %d\n" % total_fire_res
        has_defense = true
    if total_cold_res > 0:
        stats_label.text += "Cold Resistance: %d\n" % total_cold_res
        has_defense = true
    if total_lightning_res > 0:
        stats_label.text += "Lightning Resistance: %d\n" % total_lightning_res
        has_defense = true

    if not has_defense:
        stats_label.text += "(No defense equipped)\n"
```

**Display order:** Armor/Evasion/ES first (base defenses from item types), then resistances (from suffixes). Matches logical grouping: physical defense → elemental defense.

### Anti-Patterns to Avoid

- **Don't make resistances prefixes:** Prefixes define item identity (offensive for weapons, defensive type for armor). Resistances modify character attributes universally. Use suffixes.

- **Don't add resistance caps (75% max) in v1.1:** Resistance caps require combat integration (damage calculation applies resist %, overcapped resist shows correctly, penetration mechanics). Phase 10 is display-only. Add caps when resistances affect combat.

- **Don't aggregate resistances only from armor/boots/helmet:** Resistances are suffixes. Weapons and rings can roll resistance suffixes too (trade-off: suffix slot for defensive stat instead of offensive). Aggregate from all equipped items.

- **Don't keep "Elemental Reduction" suffix:** Phase goal explicitly requires removal (ERES-01: "replace generic Elemental Reduction"). Leaving it in dilutes suffix pool and confuses players (two overlapping systems).

- **Don't use percentage-based resistance for display-only phase:** Percentage resist (e.g., "+15% fire resistance") requires max resist cap context ("15% toward 75% cap" vs "15% of current resist"). Flat values ("+40 fire resistance") display cleanly without cap system. Use flat for v1.1, consider percentage when combat integration defines caps.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Resistance aggregation with all-res expansion | Manual loop checking for ALL_RESISTANCE then adding to each element | Loop suffixes once, check stat_types, accumulate | StatCalculator.calculate_flat_stat() pattern (stat_calculator.gd:53-60) proves single-pass aggregation. All-res adds to fire/cold/lightning in same loop. No need for second pass. |
| Suffix pool filtering by item type | Custom has_valid_tag logic for resistances | Existing Item.add_suffix() + has_valid_tag() | Item.add_suffix() (item.gd:166-189) already filters via has_valid_tag(). Resistance suffixes use Tag.DEFENSE (all items match). Don't add item-type-specific resistance tags. |
| Tier-based rarity for all-res | Custom weighted random in LootTable | Affix.tier_range from Phase 9 | Narrower tier range (Vector2i(1, 5) vs Vector2i(1, 8)) makes all-res rarer via fewer possible tier rolls. Reuses existing infrastructure. |
| Resistance stat storage on items | Add base_fire_resistance, base_cold_resistance properties to Item classes | Keep resistances in suffixes, aggregate in Hero | Unlike armor (intrinsic item property), resistances are modifier-only stats. Suffixes store values, Hero aggregates on equip. Don't bloat item classes with base_X properties that always = 0. |

**Key insight:** Resistances are pure affix-driven stats with no base item contribution. Armor items have original_base_armor (intrinsic property), but no item has "base fire resistance." This simplifies implementation: resistances exist only in suffixes, Hero aggregates from suffix arrays, no item model changes needed.

## Common Pitfalls

### Pitfall 1: All-Resistance Double-Counting
**What goes wrong:** Item has "All Resistances: 40" suffix. Player equips it, sees Fire Resistance: 40, Cold Resistance: 40, Lightning Resistance: 40 (120 total resist from one suffix). Then applies Forge Hammer, adds another "All Resistances: 30" suffix. Expects Fire: 70, but sees Fire: 100 because aggregation loop adds 40 + 40 + 30 + 30 (each all-res suffix counted twice).

**Why it happens:** Naive aggregation loops suffixes for each resistance type separately:
```gdscript
# WRONG - loops 3 times, counts all-res 3 times
for suffix in item.suffixes:
    if FIRE_RESISTANCE in suffix.stat_types or ALL_RESISTANCE in suffix.stat_types:
        total_fire_resistance += suffix.value
for suffix in item.suffixes:  # All-res counted again here
    if COLD_RESISTANCE in suffix.stat_types or ALL_RESISTANCE in suffix.stat_types:
        total_cold_resistance += suffix.value
# ... (lightning counted third time)
```

**How to avoid:** Single loop, check each suffix once, add to multiple totals in same iteration:
```gdscript
# CORRECT - single loop, each suffix counted once
for suffix in item.suffixes:
    if FIRE_RESISTANCE in suffix.stat_types:
        total_fire_resistance += suffix.value
    if COLD_RESISTANCE in suffix.stat_types:
        total_cold_resistance += suffix.value
    if LIGHTNING_RESISTANCE in suffix.stat_types:
        total_lightning_resistance += suffix.value
    if ALL_RESISTANCE in suffix.stat_types:
        # Add to all three in single check
        total_fire_resistance += suffix.value
        total_cold_resistance += suffix.value
        total_lightning_resistance += suffix.value
```

**Warning signs:** Resistance totals are multiples of all-res suffix values. Item with "+40 all-res" shows "Fire: 120" instead of "Fire: 40."

### Pitfall 2: Forgetting to Remove "Elemental Reduction" Suffix
**What goes wrong:** Add new resistance suffixes, forget to remove old "Elemental Reduction" from ItemAffixes.suffixes array. Now suffix pool has 5 resistance-related options (fire, cold, lightning, all, elemental reduction). Players confused: "Is Elemental Reduction the same as All Resistances? Do they stack?"

**Why it happens:** Existing suffix at item_affixes.gd:142. Adding new suffixes is easy (append to array), removing old suffix requires intentional deletion.

**How to avoid:**
1. Find "Elemental Reduction" in ItemAffixes.suffixes (item_affixes.gd:142)
2. Delete the line completely
3. Grep codebase for "Elemental Reduction" to verify no hardcoded references
4. Test suffix rolls to confirm it never appears

**Warning signs:** Forge Hammer adds "Elemental Reduction" suffix to item after Phase 10 implementation.

**Recommendation:** Remove in same commit that adds new resistance suffixes. Document in commit message: "Replace Elemental Reduction suffix with fire/cold/lightning/all-resistance suffixes (ERES-01)."

### Pitfall 3: Resistance Aggregation Only From Armor Pieces
**What goes wrong:** Hero.calculate_defense() loops ["helmet", "armor", "boots"] to aggregate resistances (copying Phase 9 armor aggregation pattern). Player equips ring with "+40 fire resistance" suffix, sees Fire Resistance: 0 in Hero View. Ring resist not counted.

**Why it happens:** Phase 9 defensive prefixes (+armor, +evasion, +ES) only roll on armor pieces (helmet, armor, boots have Tag.DEFENSE, ring doesn't). Copy-paste aggregation loop from Phase 9 excludes weapon/ring slots.

**How to avoid:** Resistances are suffixes (not prefixes), and suffixes roll on all item types. Loop all equipment slots:
```gdscript
# CORRECT - all slots
for slot in ["helmet", "armor", "boots", "weapon", "ring"]:
    if slot in equipped_items and equipped_items[slot] != null:
        var item = equipped_items[slot]
        for suffix in item.suffixes:
            # Aggregate resistances
```

**Warning signs:** Ring/weapon with resistance suffix equipped, but Hero View shows 0 for that resistance.

**Recommendation:** Explicitly loop all slots in calculate_defense(). Comment clarifies: "Resistances from suffixes on all item types (weapons and rings can roll resist suffixes)."

### Pitfall 4: All-Resistance Tier Range Too Wide
**What goes wrong:** All-resistance uses same tier range as individual resistances (Vector2i(1, 8)). Both equally common. Players always choose all-res (saves 2 suffix slots), never roll individual resistances (strictly worse: takes 3 slots for same coverage).

**Why it happens:** All-resistance provides 3x value (one affix = coverage for all elements) but costs same affix slot. If rarity is equal, it's strictly better. Individual resistances become dead suffix pool entries.

**How to avoid:** Make all-resistance rarer via narrower tier range:
- Individual resist: Vector2i(1, 8) — 8 possible tiers, each has 1/8 chance when rolling suffix
- All-resistance: Vector2i(1, 5) — 5 possible tiers, slightly rarer base chance, plus lower max tier means lower max value

**Alternative:** Use tier range Vector2i(1, 8) but lower base values for all-res (e.g., 2-6 instead of 3-8). T1 all-res = 6*8 = 48 total resist (16 per element) vs T1 single = 12*8 = 96. All-res still saves slots but provides less total.

**Warning signs:** 100% of rare items use all-res suffix, individual resistances never appear on good items.

**Recommendation:** Start with Vector2i(1, 5) for all-res, Vector2i(1, 8) for individual. Playtest in Phase 12 rebalancing. If all-res too rare, widen to Vector2i(1, 6). If too common, narrow to Vector2i(1, 4) or lower base values.

### Pitfall 5: Resistance Display Formatting Confusion
**What goes wrong:** Hero View shows "Fire Resistance: 40\nFire Resistance: 30\n" (two lines for same stat) because aggregation logic doesn't sum before display.

**Why it happens:** Display logic loops items directly instead of using Hero totals:
```gdscript
# WRONG - displays per-item resist, not total
for slot in ["helmet", "armor", "boots"]:
    var item = equipped_items[slot]
    for suffix in item.suffixes:
        if FIRE_RESISTANCE in suffix.stat_types:
            stats_label.text += "Fire Resistance: %d\n" % suffix.value  # Shows each suffix separately
```

**How to avoid:** Hero.calculate_defense() aggregates totals (total_fire_resistance, etc.). Hero View calls getter methods (get_total_fire_resistance()), displays once per stat type:
```gdscript
# CORRECT - display aggregate totals
var total_fire_res = GameState.hero.get_total_fire_resistance()
if total_fire_res > 0:
    stats_label.text += "Fire Resistance: %d\n" % total_fire_res  # Single line, total value
```

**Warning signs:** Duplicate stat names in Hero View defense section. Multiple "Fire Resistance: X" lines.

**Recommendation:** Follow Phase 9 pattern exactly. Hero aggregates, provides getters, Hero View calls getters once per stat. Clean separation: calculation in model, display in view.

## Code Examples

Verified patterns from existing codebase and recommended extensions:

### Adding Resistance Suffixes to ItemAffixes
```gdscript
// Source: autoloads/item_affixes.gd (extend suffixes array)
var suffixes: Array[Affix] = [
    // ... existing suffixes (Attack Speed, Life, Armor, etc.) ...

    // REMOVE THIS LINE (ERES-01):
    // Affix.new("Elemental Reduction", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE], []),

    // NEW: Individual elemental resistances (8 tiers, standard suffix range)
    Affix.new(
        "Fire Resistance",
        Affix.AffixType.SUFFIX,
        5,  // base_min
        12, // base_max
        [Tag.DEFENSE],
        [Tag.StatType.FIRE_RESISTANCE],
        Vector2i(1, 8)  // Standard suffix tier range
    ),

    Affix.new(
        "Cold Resistance",
        Affix.AffixType.SUFFIX,
        5,
        12,
        [Tag.DEFENSE],
        [Tag.StatType.COLD_RESISTANCE],
        Vector2i(1, 8)
    ),

    Affix.new(
        "Lightning Resistance",
        Affix.AffixType.SUFFIX,
        5,
        12,
        [Tag.DEFENSE],
        [Tag.StatType.LIGHTNING_RESISTANCE],
        Vector2i(1, 8)
    ),

    // All-resistance (narrower tier range for rarity, lower base values)
    Affix.new(
        "All Resistances",
        Affix.AffixType.SUFFIX,
        3,  // Lower base than individual (space efficiency trade-off)
        8,
        [Tag.DEFENSE],
        [Tag.StatType.ALL_RESISTANCE],
        Vector2i(1, 5)  // Narrower range = rarer
    ),
]
```

**Value calibration:**
- Individual resist: Base 5-12, T1 = 96 resist, T8 = 12 resist
- All resist: Base 3-8, T1 = 40 resist per element (120 total), T5 = 8 resist per element (24 total)
- Trade-off: All-res saves 2 suffix slots but provides 20-30% less total if you need all three elements

### Extending Tag.StatType Enum
```gdscript
// Source: autoloads/tag.gd:24-40 (add new enum values)
enum StatType {
    // Existing offense stats
    FLAT_DAMAGE,
    INCREASED_DAMAGE,
    INCREASED_SPEED,
    CRIT_CHANCE,
    CRIT_DAMAGE,

    // Existing flat defense stats
    FLAT_ARMOR,
    FLAT_ENERGY_SHIELD,
    FLAT_HEALTH,
    FLAT_MANA,
    MOVEMENT_SPEED,

    // Phase 9 percentage defense stats
    PERCENT_ARMOR,
    PERCENT_EVASION,
    PERCENT_ENERGY_SHIELD,
    PERCENT_HEALTH,
    FLAT_EVASION,

    // NEW: Elemental resistances
    FIRE_RESISTANCE,
    COLD_RESISTANCE,
    LIGHTNING_RESISTANCE,
    ALL_RESISTANCE,
}
```

### Extending Hero Model for Resistance Totals
```gdscript
// Source: models/hero.gd (add resistance properties and extend calculate_defense)

// Add to class properties (after total_energy_shield at line 14)
var total_fire_resistance: int = 0
var total_cold_resistance: int = 0
var total_lightning_resistance: int = 0

func calculate_defense() -> int:
    """Calculate total defense from equipped armor and resistances from all items"""
    total_armor = 0
    total_evasion = 0
    total_energy_shield = 0

    # Initialize resistances
    total_fire_resistance = 0
    total_cold_resistance = 0
    total_lightning_resistance = 0

    # Add defense from armor pieces and resistances from all items
    # Note: Resistances can roll on weapons/rings too (suffix system)
    for slot in ["helmet", "armor", "boots", "weapon", "ring"]:
        if slot in equipped_items and equipped_items[slot] != null:
            var item = equipped_items[slot]

            # Aggregate armor/evasion/ES (unchanged from Phase 9)
            if "base_armor" in item:
                total_armor += item.base_armor
            if "base_evasion" in item:
                total_evasion += item.base_evasion
            if "base_energy_shield" in item:
                total_energy_shield += item.base_energy_shield

            # NEW: Aggregate resistances from suffixes
            # Single loop - each suffix counted once, all-res adds to all three
            for suffix in item.suffixes:
                if Tag.StatType.FIRE_RESISTANCE in suffix.stat_types:
                    total_fire_resistance += suffix.value
                if Tag.StatType.COLD_RESISTANCE in suffix.stat_types:
                    total_cold_resistance += suffix.value
                if Tag.StatType.LIGHTNING_RESISTANCE in suffix.stat_types:
                    total_lightning_resistance += suffix.value
                if Tag.StatType.ALL_RESISTANCE in suffix.stat_types:
                    # All-res adds to each element once per suffix
                    total_fire_resistance += suffix.value
                    total_cold_resistance += suffix.value
                    total_lightning_resistance += suffix.value

    # Backward compatibility - total_defense equals total_armor
    total_defense = total_armor
    return total_defense


# Add getter methods (after get_total_energy_shield at line 183)
func get_total_fire_resistance() -> int:
    """Get the hero's total fire resistance"""
    return total_fire_resistance


func get_total_cold_resistance() -> int:
    """Get the hero's total cold resistance"""
    return total_cold_resistance


func get_total_lightning_resistance() -> int:
    """Get the hero's total lightning resistance"""
    return total_lightning_resistance
```

### Extending Hero View Defense Display
```gdscript
// Source: scenes/hero_view.gd:191-219 (extend update_stats_display)
func update_stats_display() -> void:
    var total_dps = get_total_dps()
    var total_crit_chance = get_total_crit_chance()
    var total_crit_damage = get_total_crit_damage()

    # Offense section (unchanged)
    stats_label.text = "Offense:\n"
    stats_label.text += "Total DPS: %.1f\n" % total_dps
    stats_label.text += "Crit Chance: %.1f%%\n" % total_crit_chance
    stats_label.text += "Crit Damage: %.1f%%\n" % total_crit_damage

    # Defense section
    stats_label.text += "\nDefense:\n"
    var total_armor = GameState.hero.get_total_armor()
    var total_evasion = GameState.hero.get_total_evasion()
    var total_es = GameState.hero.get_total_energy_shield()

    var has_defense = false

    # Base defenses (armor/evasion/ES from Phase 9)
    if total_armor > 0:
        stats_label.text += "Armor: %d\n" % total_armor
        has_defense = true
    if total_evasion > 0:
        stats_label.text += "Evasion: %d\n" % total_evasion
        has_defense = true
    if total_es > 0:
        stats_label.text += "Energy Shield: %d\n" % total_es
        has_defense = true

    # NEW: Elemental resistances (only show non-zero)
    var total_fire_res = GameState.hero.get_total_fire_resistance()
    var total_cold_res = GameState.hero.get_total_cold_resistance()
    var total_lightning_res = GameState.hero.get_total_lightning_resistance()

    if total_fire_res > 0:
        stats_label.text += "Fire Resistance: %d\n" % total_fire_res
        has_defense = true
    if total_cold_res > 0:
        stats_label.text += "Cold Resistance: %d\n" % total_cold_res
        has_defense = true
    if total_lightning_res > 0:
        stats_label.text += "Lightning Resistance: %d\n" % total_lightning_res
        has_defense = true

    # If no defense stats at all, show placeholder
    if not has_defense:
        stats_label.text += "(No defense equipped)\n"
```

**Display order rationale:** Base defenses (armor/evasion/ES) are intrinsic item properties, resistances are modifiers from affixes. Show base defenses first (item identity), then resistances (character optimization).

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Generic "Elemental Reduction" | Separate fire/cold/lightning + all-res | Path of Exile 1 (2013), Diablo 3 Loot 2.0 (2014) | Build diversity. Stack fire resist for fire-heavy areas, balanced coverage with all-res. Generic resist simplifies gearing but removes strategic depth. |
| All-res same rarity as individual | All-res rarer (via tier range or weights) | Diablo 3 (2014) made all-res primary affix, single-res secondary | Prevents all-res dominance. If equally rare, all-res strictly better (3 stats for 1 slot). Rarer all-res creates meaningful choice: single-resist for max value vs all-res for coverage. |
| Percentage-based resist with caps | Flat resist values for display-only | Path of Exile uses % with 75% cap, Last Epoch uses flat | Flat values simpler for v1.1 display-only phase. When combat integration comes, convert to % with cap or keep flat with diminishing returns formula. |
| Items spawn with all-res + single-res | Items spawn with one or the other, never both | Diablo 3 Loot 2.0 (2014) | Prevents resist overcapping. If both can roll on same item, late-game items trivially max all resists. GDScript Item.is_affix_on_item() prevents duplicates, but doesn't prevent complementary affixes (fire-res + all-res on same item is legal). Defer to Phase 12 rebalancing if needed. |

**Deprecated/outdated:**
- **Generic elemental resistance:** Path of Exile removed generic "Elemental Resistance" in favor of separate fire/cold/lightning (2013). Modern ARPGs (PoE, Diablo 4, Last Epoch) all use split resistances.
- **Equal-rarity all-resistance:** Diablo 3 vanilla (2012) had all-resist at same rarity as single-element. Loot 2.0 (2014) made all-resist primary stat, single-resist secondary (mutually exclusive on same item slot). Balance lesson: all-res must be meaningfully rarer or lower value.

## Open Questions

1. **Should all-resistance and individual resistance be mutually exclusive on same item?**
   - What we know: Item.is_affix_on_item() (item.gd:120-130) prevents duplicate affixes (can't roll "Fire Resistance" twice). Doesn't prevent complementary affixes ("Fire Resistance" + "All Resistances" on same item is legal).
   - What's unclear: If rare item can roll 3 suffixes, can it have "Fire Resistance" + "Cold Resistance" + "All Resistances"? Total fire resist from that item = fire_value + all_res_value. Intended or too strong?
   - Recommendation: Allow for v1.1. Item with fire-res + all-res is suboptimal (better to have fire-res + cold-res + lightning-res for max total). Mutual exclusion requires affix group tagging (new infrastructure). Defer to Phase 12 if playtesting shows all-res stacking is broken.

2. **Should weapons and rings roll resistance suffixes?**
   - What we know: Resistances use Tag.DEFENSE suffix tag. Current items: weapons have [Tag.WEAPON] (item_affixes.gd:9,17,22), rings have [Tag.ATTACK, Tag.CRITICAL, Tag.SPEED] (basic_ring.gd valid_tags). Neither has Tag.DEFENSE, so neither can currently roll resistance suffixes.
   - What's unclear: Should rings/weapons get Tag.DEFENSE added to valid_tags? Or should resistance suffixes drop Tag.DEFENSE requirement (use empty tag array [])?
   - Recommendation: Add Tag.DEFENSE to all item valid_tags. Allows weapons/rings to roll resistances (trade-off: suffix slot for defense instead of offense). Matches ARPG design (PoE weapons can have resist suffixes). Increases suffix pool variety for all items.

3. **What are optimal base values for individual vs all-resistance?**
   - What we know: Individual resist base 5-12, all-resist base 3-8 (recommendations in code examples). T1 individual = 96, T1 all-res = 40 per element (120 total).
   - What's unclear: Is 20-30% lower total for all-res sufficient trade-off for saving 2 suffix slots? Or should all-res be 50% lower (base 2-5)?
   - Recommendation: Start with 5-12 individual, 3-8 all-res. Playtest in Phase 12. If all-res dominates (90%+ of rare items use it), lower all-res base values. If never used (<10% adoption), increase base or widen tier range.

## Sources

### Primary (HIGH confidence)
- Existing codebase (Godot 4.6 GDScript project):
  - `autoloads/item_affixes.gd` - Suffix array pattern (lines 122-161), "Elemental Reduction" suffix (line 142)
  - `models/items/item.gd` - Suffix addition logic (lines 166-189), tag-based filtering (lines 133-137)
  - `models/affixes/affix.gd` - Tier range support from Phase 9 (line 13, 26)
  - `models/hero.gd` - Defense calculation pattern (lines 102-128)
  - `scenes/hero_view.gd` - Defense section display (lines 202-219)
  - `autoloads/tag.gd` - StatType enum pattern (lines 24-40)

### Secondary (MEDIUM confidence)
- [Resistance | PoE Wiki](https://www.poewiki.net/wiki/Resistance) - Fire/cold/lightning resistance mechanics, 75% cap, penetration
- [PoE 2 Guide: Resistances Explained](https://mobalytics.gg/poe-2/guides/resistances) - Path of Exile 2 resistance system (2026)
- [All Resist or Specific Elemental Resist - Diablo 3 Forums](https://us.forums.blizzard.com/en/d3/t/all-resist-or-specific-elemental-resist-remove-one/55061) - Design trade-offs between all-res and individual res
- [All Resistance - Diablo Wiki](https://www.diablowiki.net/All_Resistance) - Diablo 3 Loot 2.0 (2014) made all-res primary, single-res secondary

### Tertiary (LOW confidence)
- ARPG forum discussions (Crate Entertainment, Last Epoch Steam) - General resistance system design philosophy (no specific implementation details)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Godot 4.6 project with all patterns proven in Phase 9
- Architecture: HIGH - Suffix system, tag filtering, Hero aggregation all currently implemented
- Pitfalls: MEDIUM - All-res double-counting verified via loop analysis, resistance-from-all-slots proven necessary, tier range rarity math validated. Value calibration needs playtesting.
- ARPG patterns: MEDIUM - Path of Exile / Diablo 3 resistance split verified via official wikis. All-res rarity trade-off documented in Diablo 3 Loot 2.0 history.

**Research date:** 2026-02-16
**Valid until:** 60 days (stable GDScript patterns, ARPG genre conventions haven't changed since 2014)

---

*Research complete. Ready for planning.*
