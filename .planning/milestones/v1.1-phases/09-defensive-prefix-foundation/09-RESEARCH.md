# Phase 9: Defensive Prefix Foundation - Research

**Researched:** 2026-02-15
**Domain:** GDScript affix system extension, tag-based filtering, tier scaling, defensive stat calculations
**Confidence:** HIGH

## Summary

Phase 9 adds defensive prefix affixes (armor, evasion, energy shield) to non-weapon items using the existing ItemAffixes and StatCalculator patterns. The codebase already has all necessary infrastructure: tag-based affix filtering (Item.has_valid_tag()), tier scaling (Affix._init() tier calculation), and flat stat aggregation (StatCalculator.calculate_flat_stat()). User decisions lock in tag-based defense typing, T1=best tier convention, 30+ tier depth, and display-only treatment (no visual distinction).

**Primary recommendation:** Extend ItemAffixes.prefixes array with 6 defensive affixes (flat armor, %armor, flat evasion, %evasion, flat ES, %ES), add percentage stat calculation to StatCalculator, expand Tag.StatType enum for new stat types, and extend item display methods to show defensive stats in Hero View defense section. Follow existing weapon prefix pattern exactly.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Defense distribution:**
- Defense type is tied to base item type, not item slot (e.g., leather armor = evasion, mage robe = energy shield)
- Current basic items (basic armor, basic boots, basic helmet) all roll armor prefixes (flat armor + % armor) since they represent simple physical protection
- Rings get NO defensive prefixes — they are accessory slots, not armor
- Tag system must be designed to support future base types mapping to different defense types

**Value ranges & scaling:**
- Defensive prefixes follow the existing tier system: tiers gated by item level (from area level), with higher-rank tiers weighted rarer
- Tier numbering: T1 = best (highest values, hardest to roll), T30 = worst (lowest values, easiest to roll) — players immediately know quality
- Target 30+ tiers for defensive prefixes to support idle game bulk-crafting depth
- Both flat and percentage-based defenses available from tier 1 (no tier-gating % defenses)
- Tier details (tier number, ranges) shown on a toggle — clean default view, detailed on demand

**Display-only treatment:**
- No visual distinction for "display only" stats — show defensive stats normally (no gray text, no labels)
- Hero View gets a separate defense section (not mixed with offense stats)
- Hero View defense section shows aggregate totals from all equipped items
- Only show non-zero defense types in Hero View (don't show Armor: 0, Evasion: 0 etc.)

**Affix pool balance:**
- Rare armor items (3 prefix slots) can stack multiple defensive prefixes (e.g., flat armor + % armor on same piece)
- Also adding utility prefixes: +Life, +Mana, +% Life for non-weapon items

### Claude's Discretion

- Specific flat/% armor value ranges per tier (calibrate against existing offensive values)
- Whether +Life, +Mana, +% Life roll on weapons or non-weapons only
- Tier toggle UI implementation details
- Tag taxonomy naming conventions

### Deferred Ideas (OUT OF SCOPE)

- Multiple base types per slot (leather armor, mage robe, etc.) — future phase for expanding base item variety
- Expand existing offensive affix tiers to 30+ (currently 8 tiers) — separate task to align offensive with new defensive tier depth
- Advanced mod info toggle UI (showing tier numbers, value ranges) — could be its own UI enhancement phase
</user_constraints>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Godot Engine | 4.6 | Game engine | Current stable (Jan 27, 2026). Project already uses mobile renderer mode. GDScript array iteration optimizations benefit affix pool filtering. |
| GDScript | 4.6 | Language | Only language in codebase. Typed arrays (Array[Affix]) used throughout. Resource extension pattern established. |

### Supporting
No external libraries required. All features implemented via existing autoload patterns (ItemAffixes, Tag, StatCalculator, GameState).

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Custom tier calculation | Loot table plugin (Lootie) | Project already has working tier system in Affix._init(). Plugin adds complexity for zero benefit. |
| Dictionary-based stat types | String constants | StatType enum provides type safety and IDE autocomplete. Existing codebase uses enums consistently (tag.gd:22-33). |
| Hero View extension | New defense-specific UI | Hero View already displays stats from equipped items. Separate UI duplicates responsibility. |

**Installation:**
```bash
# No installation needed - pure GDScript modifications
```

## Architecture Patterns

### Recommended Project Structure
```
autoloads/
├── item_affixes.gd      # Add defensive prefixes here
├── tag.gd               # Add new StatType enums here
├── game_state.gd        # No changes needed
└── game_events.gd       # No changes needed
models/
├── affixes/
│   └── affix.gd         # Modify tier calculation for 30+ tiers
├── stats/
│   └── stat_calculator.gd  # Add percentage stat calculation
└── items/
    ├── item.gd          # No changes to core logic
    ├── armor.gd         # Extend update_value() for %armor
    ├── boots.gd         # Extend update_value() for %armor
    └── helmet.gd        # Extend update_value() for %armor
scenes/
└── hero_view.gd         # Add defense section to stats display
```

### Pattern 1: Tag-Based Defense Type Filtering
**What:** Items declare valid tags (Tag.ARMOR, Tag.EVASION, Tag.ENERGY_SHIELD), affixes declare tags, Item.has_valid_tag() filters affix pool.

**When to use:** Always. Existing pattern for weapon affixes (Item.add_prefix(), item.gd:133-137).

**Example:**
```gdscript
// Source: models/items/basic_armor.gd:8
self.valid_tags = [Tag.DEFENSE, Tag.ARMOR, Tag.ENERGY_SHIELD]

// Source: autoloads/item_affixes.gd:56 (existing Life suffix)
Affix.new("Life", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE], [Tag.StatType.FLAT_HEALTH])

// Pattern for new defensive prefixes:
Affix.new("Armored", Affix.AffixType.PREFIX, 5, 15, [Tag.DEFENSE, Tag.ARMOR], [Tag.StatType.FLAT_ARMOR])
Affix.new("Evasive", Affix.AffixType.PREFIX, 3, 12, [Tag.DEFENSE, Tag.EVASION], [Tag.StatType.FLAT_EVASION])
Affix.new("Warded", Affix.AffixType.PREFIX, 4, 14, [Tag.DEFENSE, Tag.ENERGY_SHIELD], [Tag.StatType.FLAT_ENERGY_SHIELD])
```

**Why this works:** Item.add_prefix() (item.gd:140-163) already calls has_valid_tag() to filter ItemAffixes.prefixes. Basic armor has Tag.ARMOR in valid_tags, so "Armored" prefix passes filter. Future leather armor base would use Tag.EVASION instead.

### Pattern 2: Tier-Based Value Scaling
**What:** Affix._init() receives min/max base values, calculates tier-adjusted values using formula: `actual_value = base_value * (max_tier + 1 - current_tier)`.

**When to use:** All affixes. Existing implementation in Affix._init() (affix.gd:28-31).

**Example:**
```gdscript
// Source: models/affixes/affix.gd:25-31
func _init(p_name, p_type, p_min, p_max, p_tags, p_stat_types):
    self.tier = randi_range(1, 8)  # Current: 8 tiers
    # Tier 1 is highest, so higher tier numbers = lower values
    self.min_value = p_min * (9 - tier)
    self.max_value = p_max * (9 - tier)
    self.value = randi_range(self.min_value, self.max_value)

// For 30-tier system:
self.tier = randi_range(1, 30)
self.min_value = p_min * (31 - tier)  # T1: p_min * 30, T30: p_min * 1
self.max_value = p_max * (31 - tier)  # T1: p_max * 30, T30: p_max * 1

// Example: Flat armor prefix with base 5-15
// T1:  5 * 30 = 150 to 15 * 30 = 450 armor
// T15: 5 * 16 =  80 to 15 * 16 = 240 armor
// T30: 5 * 1  =   5 to 15 * 1  =  15 armor
```

**Critical:** Current tier calculation hardcodes `randi_range(1, 8)`. Changing to 30 tiers affects ALL affixes (offensive and defensive). User decision: defensive prefixes use 30 tiers, offensive prefixes stay at 8 tiers for v1.1. This requires per-affix tier range configuration.

**Recommended solution:** Add tier_range property to Affix:
```gdscript
var tier_range: Vector2i = Vector2i(1, 8)  # Default to existing 8 tiers

func _init(p_name, p_type, p_min, p_max, p_tags, p_stat_types, p_tier_range = Vector2i(1, 8)):
    self.tier_range = p_tier_range
    self.tier = randi_range(tier_range.x, tier_range.y)
    var tier_multiplier = (tier_range.y + 1) - tier
    self.min_value = p_min * tier_multiplier
    self.max_value = p_max * tier_multiplier
```

### Pattern 3: Dual Stat Calculation (Flat + Percentage)
**What:** StatCalculator.calculate_flat_stat() sums flat additions, new calculate_percentage_stat() multiplies base values. Defense items call both in update_value().

**When to use:** Armor/Boots/Helmet update_value() methods.

**Example:**
```gdscript
// Source: models/stats/stat_calculator.gd:53-60 (existing flat calculation)
static func calculate_flat_stat(affixes: Array, stat_type: int) -> float:
    var total := 0.0
    for affix: Affix in affixes:
        if stat_type in affix.stat_types:
            total += affix.value
    return total

// New: Percentage stat calculation
static func calculate_percentage_stat(base_value: float, affixes: Array, stat_type: int) -> float:
    var additive_mult := 0.0
    for affix: Affix in affixes:
        if stat_type in affix.stat_types:
            additive_mult += affix.value / 100.0
    return base_value * (1.0 + additive_mult)

// Usage in Armor.update_value():
var all_affixes := self.prefixes + self.suffixes
all_affixes.append(self.implicit)

# Step 1: Add flat armor
var flat_armor = StatCalculator.calculate_flat_stat(all_affixes, Tag.StatType.FLAT_ARMOR)
self.base_armor = self.original_base_armor + int(flat_armor)

# Step 2: Apply %armor to base (including flat additions)
self.base_armor = int(StatCalculator.calculate_percentage_stat(
    self.base_armor,
    all_affixes,
    Tag.StatType.PERCENT_ARMOR
))
```

**Why this order:** Matches DPS calculation (StatCalculator.calculate_dps(), stat_calculator.gd:9-50). Flat additions apply first, then percentage multipliers. This prevents percentage affixes from scaling themselves.

### Pattern 4: Hero View Defense Section
**What:** Hero View already displays total_dps, total_crit_chance, total_crit_damage (hero_view.gd:191-201). Add parallel defense section showing total_armor, total_evasion, total_energy_shield.

**When to use:** Always. Hero.calculate_defense() already aggregates total_defense from armor/boots/helmet (hero.gd:99-112).

**Example:**
```gdscript
// Source: scenes/hero_view.gd:191-201 (existing offense stats)
func update_stats_display() -> void:
    stats_label.text = "Hero Stats:\n"
    stats_label.text += "Total DPS: %.1f\n" % get_total_dps()
    stats_label.text += "Crit Chance: %.1f%%\n" % get_total_crit_chance()
    stats_label.text += "Crit Damage: %.1f%%\n" % get_total_crit_damage()
    stats_label.text += "Defense: %d" % get_total_defense()

// Extend to separate defense section:
func update_stats_display() -> void:
    # Offense section
    stats_label.text = "Offense:\n"
    stats_label.text += "Total DPS: %.1f\n" % get_total_dps()
    stats_label.text += "Crit Chance: %.1f%%\n" % get_total_crit_chance()
    stats_label.text += "Crit Damage: %.1f%%\n" % get_total_crit_damage()

    # Defense section (user decision: only show non-zero)
    stats_label.text += "\nDefense:\n"
    var total_armor = GameState.hero.get_total_armor()
    var total_evasion = GameState.hero.get_total_evasion()
    var total_es = GameState.hero.get_total_energy_shield()

    if total_armor > 0:
        stats_label.text += "Armor: %d\n" % total_armor
    if total_evasion > 0:
        stats_label.text += "Evasion: %d\n" % total_evasion
    if total_es > 0:
        stats_label.text += "Energy Shield: %d\n" % total_es
```

**Hero model extension:**
```gdscript
// In models/hero.gd - extend calculate_defense()
func calculate_defense() -> void:
    total_armor = 0
    total_evasion = 0
    total_energy_shield = 0

    for slot in ["helmet", "armor", "boots"]:
        if slot in equipped_items and equipped_items[slot] != null:
            var item = equipped_items[slot]
            if "base_armor" in item:
                total_armor += item.base_armor
            if "base_evasion" in item:
                total_evasion += item.base_evasion
            if "base_energy_shield" in item:
                total_energy_shield += item.base_energy_shield
```

### Anti-Patterns to Avoid

- **Don't mix defense types in Hero View total_defense:** Current code aggregates all defense into single total_defense int (hero.gd:101-111). This loses armor/evasion/ES distinction. User decision requires separate totals.

- **Don't hardcode tier ranges:** Current Affix._init() uses `randi_range(1, 8)` directly (affix.gd:25). Defensive prefixes need 30 tiers. Make tier range configurable per affix, not global.

- **Don't add percentage stats to StatCalculator.calculate_dps():** DPS calculation already has INCREASED_DAMAGE percentage handling (stat_calculator.gd:26-31). Defensive percentage stats need separate method to avoid conflating offense/defense calculations.

- **Don't create new autoloads:** Four autoloads (ItemAffixes, Tag, GameEvents, GameState) are sufficient. All new affixes fit in ItemAffixes, all new stat types fit in Tag.StatType enum.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Weighted random affix selection | Custom probability system | Existing Item.add_prefix() + Array.pick_random() | Item.add_prefix() already filters valid affixes via has_valid_tag(), then uses pick_random() (item.gd:157). Random selection is uniform across filtered pool. Tier rarity comes from tier roll probability (randi_range gives equal chance to each tier, but tier 1 is rarest drop via loot table weighting). |
| Tier-to-value mapping | Manual tier arrays | Affix._init() formula: value = base * (max_tier + 1 - tier) | Formula auto-scales to any tier count. Changing tier count doesn't require updating lookup tables. Current implementation (affix.gd:28-31) already proven. |
| Defense stat aggregation | Manual property summation | StatCalculator.calculate_flat_stat() | Already used for FLAT_ARMOR, FLAT_HEALTH in Armor.update_value() (armor.gd:16-27). Extend to new stat types, don't duplicate logic. |
| Display conditional logic | if/else chains for stat types | Dictionary-driven display | If showing many stat types conditionally (armor, evasion, ES, health, mana), use Dictionary of {stat_name: value} and iterate, filtering non-zero. Cleaner than 6+ if statements. |

**Key insight:** Godot's typed arrays (Array[Affix]) + built-in pick_random() + enum-based filtering compose into robust affix system. Don't replace with "smarter" weighted selection—uniform random across valid pool is correct design.

## Common Pitfalls

### Pitfall 1: Tier Scaling Creates Excessive Value Ranges
**What goes wrong:** With 30 tiers, T1 = base * 30, T30 = base * 1. If base is 5-15, T1 rolls 150-450 and T30 rolls 5-15. Late-game players only want T1, making 29 tiers junk.

**Why it happens:** Linear scaling doesn't compress well across 30 tiers. Offensive affixes use 8 tiers, so spread is manageable (T1 = base * 8, T8 = base * 1).

**How to avoid:**
1. **Lower base values:** If offensive prefix uses base 2-10, defensive could use base 1-3. This keeps T1 defensive (30-90) comparable to T1 offensive (16-80).
2. **Logarithmic tier multiplier:** Instead of linear (31 - tier), use sqrt(31 - tier) to compress range. T1 = base * sqrt(30) ≈ base * 5.5, T30 = base * 1.
3. **User decision override:** User specified "calibrate against existing offensive values." Check existing T1 weapon DPS impact (weapon with T1 flat damage adds ~80 damage, becomes ~400 DPS after speed/crit). Defensive T1 should provide equivalent survivability (e.g., 300 armor = ~30% physical reduction in typical ARPG math).

**Warning signs:** If 90% of crafted items are immediately discarded because only T1-T5 are viable, tier spread is too wide.

**Recommendation:** Start with base 2-5 for flat defensive stats, monitor drop distribution, tune in Phase 12 rebalancing.

### Pitfall 2: Percentage Defense Stacking Creates Exponential Scaling
**What goes wrong:** Rare item with 3 prefix slots can roll: +100 flat armor, +50% armor, +50% armor. If %armor applies multiplicatively, final armor = 100 * 1.5 * 1.5 = 225. If additively, 100 * (1 + 0.5 + 0.5) = 200.

**Why it happens:** StatCalculator.calculate_dps() uses additive percentage multipliers (stat_calculator.gd:26-31): all INCREASED_DAMAGE affixes sum, then apply once. If defensive %armor uses same pattern, it's additive. If naive implementation multiplies each affix separately, it's exponential.

**How to avoid:** Follow DPS pattern exactly. Sum all percentage modifiers, apply once:
```gdscript
var additive_armor_mult := 0.0
for affix in affixes:
    if Tag.StatType.PERCENT_ARMOR in affix.stat_types:
        additive_armor_mult += affix.value / 100.0
base_armor *= (1.0 + additive_armor_mult)
```

**Warning signs:** Rare items with 2-3 %armor prefixes become immortal. Defensive stats grow faster than enemy damage.

**Recommendation:** Use additive percentage stacking for all defense types (armor, evasion, ES). Matches Path of Exile's "increased" modifier behavior.

### Pitfall 3: Ring Defense Lockout Empties Affix Pool
**What goes wrong:** User decision: "Rings get NO defensive prefixes." If ItemAffixes.prefixes only contains defensive prefixes, Ring.add_prefix() finds zero valid affixes, returns false.

**Why it happens:** Ring.valid_tags excludes Tag.DEFENSE (ring.gd doesn't set this tag). If all prefixes require Tag.DEFENSE, has_valid_tag() rejects them all (item.gd:133-137).

**How to avoid:**
1. **Keep offensive prefixes:** Don't remove existing weapon prefixes (Physical Damage, %Physical Damage, etc.). Rings can roll these.
2. **Tag taxonomy:** Use mutually exclusive tags. Weapon prefixes get Tag.WEAPON, defensive prefixes get Tag.DEFENSE, utility prefixes get Tag.UTILITY. Rings set valid_tags = [Tag.WEAPON, Tag.UTILITY], never Tag.DEFENSE.
3. **Test affix pools:** After adding defensive prefixes, verify each item type has >0 valid prefixes. Ring should match ~9 weapon prefixes, Helmet should match ~6 defensive + ~3 utility.

**Warning signs:** Ring.add_prefix() returns false, print shows "No valid prefixes available for this item" (item.gd:154).

**Recommendation:** Audit ItemAffixes.prefixes after adding defensive affixes. Count valid affixes per item type. Minimum 5 valid prefixes per type to avoid empty pools.

### Pitfall 4: Display Toggle Shows Incorrect Tier Ranges
**What goes wrong:** Tier toggle UI displays "T15 range: 80-240" but actual T15 roll was 120. Player expects 80-240, sees 120, assumes bug.

**Why it happens:** Affix stores final rolled value, not min/max range. Tier range must be recalculated from tier number + base values, but base values aren't stored on Affix instance (affix.gd only stores min_value/max_value after tier scaling).

**How to avoid:**
1. **Store base values on Affix:** Add `var base_min: int` and `var base_max: int` to Affix. Set in _init() before tier scaling. Then tier toggle can recalculate: `display_range = (base_min to base_max) * (31 - tier)`.
2. **Alternative: Store on template:** ItemAffixes.prefixes are templates. When creating Affix copy (Affixes.from_affix()), pass base values as constructor args.

**Warning signs:** Tier toggle shows "Range: 0-0" or incorrect values.

**Recommendation:** Add base_min/base_max properties to Affix. Populate in _init() before tier scaling. Tier toggle reads these.

### Pitfall 5: Hero View Defense Section Shows Zero for Empty Slots
**What goes wrong:** User decision: "Only show non-zero defense types." But if helmet slot is empty, get_total_armor() returns 0, shouldn't display "Armor: 0", but should display if boots/armor have armor.

**Why it happens:** Conditional display checks total, not whether any item contributes. If all items are unequipped, total_armor = 0, correctly hidden. If helmet is empty but armor has +50 armor, total_armor = 50, correctly shown. Edge case: boots have +50 evasion, total_evasion = 50 (show), total_armor = 0 (hide). This works as intended.

**How to avoid:** Not actually a pitfall—user decision is correct. Only show non-zero totals. Zero total means no items with that defense type equipped.

**Warning signs:** None. This is correct behavior.

**Recommendation:** Implement as specified. No special handling needed.

## Code Examples

Verified patterns from existing codebase and recommended extensions:

### Adding Defensive Prefixes to ItemAffixes
```gdscript
// Source: autoloads/item_affixes.gd (extend prefixes array)
var prefixes: Array[Affix] = [
    // ... existing weapon prefixes (Physical Damage, etc.) ...

    // Flat armor (30 tiers, base 2-5)
    Affix.new(
        "Armored",
        Affix.AffixType.PREFIX,
        2,  // base_min
        5,  // base_max
        [Tag.DEFENSE, Tag.ARMOR],
        [Tag.StatType.FLAT_ARMOR],
        Vector2i(1, 30)  // tier_range (new parameter)
    ),

    // Percentage armor (30 tiers, base 1-3 for %)
    Affix.new(
        "Reinforced",
        Affix.AffixType.PREFIX,
        1,
        3,
        [Tag.DEFENSE, Tag.ARMOR],
        [Tag.StatType.PERCENT_ARMOR],
        Vector2i(1, 30)
    ),

    // Flat evasion
    Affix.new(
        "Evasive",
        Affix.AffixType.PREFIX,
        2,
        5,
        [Tag.DEFENSE, Tag.EVASION],
        [Tag.StatType.FLAT_EVASION],
        Vector2i(1, 30)
    ),

    // Percentage evasion
    Affix.new(
        "Swift",
        Affix.AffixType.PREFIX,
        1,
        3,
        [Tag.DEFENSE, Tag.EVASION],
        [Tag.StatType.PERCENT_EVASION],
        Vector2i(1, 30)
    ),

    // Flat energy shield
    Affix.new(
        "Warded",
        Affix.AffixType.PREFIX,
        3,
        6,
        [Tag.DEFENSE, Tag.ENERGY_SHIELD],
        [Tag.StatType.FLAT_ENERGY_SHIELD],
        Vector2i(1, 30)
    ),

    // Percentage energy shield
    Affix.new(
        "Arcane",
        Affix.AffixType.PREFIX,
        1,
        3,
        [Tag.DEFENSE, Tag.ENERGY_SHIELD],
        [Tag.StatType.PERCENT_ENERGY_SHIELD],
        Vector2i(1, 30)
    ),

    // Utility prefixes (user decision: Claude's discretion on weapon eligibility)
    // Recommendation: Non-weapons only to preserve weapon prefix identity
    Affix.new(
        "Healthy",
        Affix.AffixType.PREFIX,
        3,
        8,
        [Tag.DEFENSE, Tag.UTILITY],
        [Tag.StatType.FLAT_HEALTH],
        Vector2i(1, 30)
    ),

    Affix.new(
        "Vital",
        Affix.AffixType.PREFIX,
        1,
        3,
        [Tag.DEFENSE, Tag.UTILITY],
        [Tag.StatType.PERCENT_HEALTH],
        Vector2i(1, 30)
    ),

    Affix.new(
        "Mana",
        Affix.AffixType.PREFIX,
        2,
        6,
        [Tag.DEFENSE, Tag.UTILITY, Tag.MANA],
        [Tag.StatType.FLAT_MANA],
        Vector2i(1, 30)
    ),
]
```

### Extending Tag.StatType Enum
```gdscript
// Source: autoloads/tag.gd:22-33 (add new enum values)
enum StatType {
    // Existing offense stats
    FLAT_DAMAGE,
    INCREASED_DAMAGE,
    INCREASED_SPEED,
    CRIT_CHANCE,
    CRIT_DAMAGE,

    // Existing flat defense stats (already in use)
    FLAT_ARMOR,
    FLAT_ENERGY_SHIELD,
    FLAT_HEALTH,
    FLAT_MANA,
    MOVEMENT_SPEED,

    // NEW: Percentage defense stats
    PERCENT_ARMOR,
    PERCENT_EVASION,
    PERCENT_ENERGY_SHIELD,
    PERCENT_HEALTH,

    // NEW: Flat evasion (currently missing)
    FLAT_EVASION,
}
```

### Adding Percentage Stat Calculation to StatCalculator
```gdscript
// Source: models/stats/stat_calculator.gd (add after calculate_flat_stat)
## Calculates percentage-based stat modifiers using additive stacking.
## All "increased X%" affixes for a stat type are summed, then applied once.
## Matches INCREASED_DAMAGE pattern from calculate_dps().
##
## Example: base_armor=100, two +50% armor affixes
## Result: 100 * (1.0 + 0.5 + 0.5) = 200
static func calculate_percentage_stat(base_value: float, affixes: Array, stat_type: int) -> float:
    var additive_mult := 0.0
    for affix: Affix in affixes:
        if stat_type in affix.stat_types:
            additive_mult += affix.value / 100.0
    return base_value * (1.0 + additive_mult)
```

### Extending Armor.update_value() for Flat + Percentage Defense
```gdscript
// Source: models/items/armor.gd:12-28 (replace update_value method)
func update_value() -> void:
    var all_affixes := self.prefixes + self.suffixes
    all_affixes.append(self.implicit)

    # Step 1: Flat armor additions
    var flat_armor = StatCalculator.calculate_flat_stat(all_affixes, Tag.StatType.FLAT_ARMOR)
    self.base_armor = self.original_base_armor + int(flat_armor)

    # Step 2: Percentage armor multiplier (applied to base + flat)
    self.base_armor = int(StatCalculator.calculate_percentage_stat(
        self.base_armor,
        all_affixes,
        Tag.StatType.PERCENT_ARMOR
    ))

    # Repeat for evasion
    var flat_evasion = StatCalculator.calculate_flat_stat(all_affixes, Tag.StatType.FLAT_EVASION)
    self.base_evasion = self.original_base_evasion + int(flat_evasion)
    self.base_evasion = int(StatCalculator.calculate_percentage_stat(
        self.base_evasion,
        all_affixes,
        Tag.StatType.PERCENT_EVASION
    ))

    # Repeat for energy shield
    var flat_es = StatCalculator.calculate_flat_stat(all_affixes, Tag.StatType.FLAT_ENERGY_SHIELD)
    self.base_energy_shield = self.original_base_energy_shield + int(flat_es)
    self.base_energy_shield = int(StatCalculator.calculate_percentage_stat(
        self.base_energy_shield,
        all_affixes,
        Tag.StatType.PERCENT_ENERGY_SHIELD
    ))

    # Health (existing, no changes needed)
    self.base_health = (
        self.original_base_health
        + int(StatCalculator.calculate_flat_stat(all_affixes, Tag.StatType.FLAT_HEALTH))
    )

    # Add percentage health if utility prefix included
    self.base_health = int(StatCalculator.calculate_percentage_stat(
        self.base_health,
        all_affixes,
        Tag.StatType.PERCENT_HEALTH
    ))

    # Total defense = armor only (user decision: current basic items are armor bases)
    self.total_defense = self.base_armor
```

### Extending Hero Model for Separate Defense Totals
```gdscript
// Source: models/hero.gd:99-112 (replace calculate_defense method)
func calculate_defense() -> void:
    """Calculate separate defense totals by type"""
    total_armor = 0
    total_evasion = 0
    total_energy_shield = 0

    # Add defense from armor pieces
    for slot in ["helmet", "armor", "boots"]:
        if slot in equipped_items and equipped_items[slot] != null:
            var item = equipped_items[slot]

            # Aggregate armor
            if "base_armor" in item:
                total_armor += item.base_armor

            # Aggregate evasion
            if "base_evasion" in item:
                total_evasion += item.base_evasion

            # Aggregate energy shield
            if "base_energy_shield" in item:
                total_energy_shield += item.base_energy_shield

    # Backward compatibility: total_defense = armor for now
    total_defense = total_armor

# Add getter methods
func get_total_armor() -> int:
    return total_armor

func get_total_evasion() -> int:
    return total_evasion

func get_total_energy_shield() -> int:
    return total_energy_shield
```

### Updating Hero View Defense Display
```gdscript
// Source: scenes/hero_view.gd:191-201 (replace update_stats_display method)
func update_stats_display() -> void:
    var total_dps = get_total_dps()
    var total_crit_chance = get_total_crit_chance()
    var total_crit_damage = get_total_crit_damage()

    # Offense section
    stats_label.text = "Offense:\n"
    stats_label.text += "Total DPS: %.1f\n" % total_dps
    stats_label.text += "Crit Chance: %.1f%%\n" % total_crit_chance
    stats_label.text += "Crit Damage: %.1f%%\n" % total_crit_damage

    # Defense section (user decision: only show non-zero)
    stats_label.text += "\nDefense:\n"
    var total_armor = GameState.hero.get_total_armor()
    var total_evasion = GameState.hero.get_total_evasion()
    var total_es = GameState.hero.get_total_energy_shield()

    if total_armor > 0:
        stats_label.text += "Armor: %d\n" % total_armor
    if total_evasion > 0:
        stats_label.text += "Evasion: %d\n" % total_evasion
    if total_es > 0:
        stats_label.text += "Energy Shield: %d\n" % total_es

    # If no defense stats, show placeholder
    if total_armor == 0 and total_evasion == 0 and total_es == 0:
        stats_label.text += "(No defense equipped)\n"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single "Defense" stat type | Separate armor/evasion/energy shield | Path of Exile 2 (2024) | Enables build diversity. Pure armor stacks for physical mitigation, pure evasion for dodge chance, hybrid for layered defense. |
| Hardcoded tier ranges per affix | Configurable tier range parameter | Never (recommendation for this project) | Allows different affix types to use different tier depths (30 for defensive, 8 for offensive) without code duplication. |
| Multiplicative %stat stacking | Additive %stat stacking ("increased") | Path of Exile 1 (2013) | Prevents exponential scaling. Three +50% armor affixes = +150% total, not +237.5% (1.5^3). |
| Gray text for non-functional stats | Normal display for all stats | User decision (this project) | Cleaner UI. Stats show what they contribute, combat integration comes later. |

**Deprecated/outdated:**
- **Tier 1 = worst convention:** Some older ARPGs used T1 as lowest tier. Current standard (Path of Exile, Last Epoch) uses T1 = best. User decision locked this in.
- **Defense stat merging:** Early ARPGs (Diablo 2) merged all defense into one "Defense" value. Modern ARPGs separate by type for mechanical depth.

## Open Questions

1. **Should existing offensive affixes expand to 30 tiers now or later?**
   - What we know: Current offensive affixes use 8 tiers (affix.gd:25). User decision deferred "expand offensive to 30+ tiers" to separate task.
   - What's unclear: If offensive stays 8 tiers and defensive uses 30 tiers, players perceive defensive crafting as "deeper." Is this desired asymmetry or temporary state?
   - Recommendation: Ship defensive at 30 tiers, offensive at 8 tiers for v1.1. If playtest shows tier depth imbalance causes confusion, Phase 13 can align offensive tiers to 30.

2. **Should utility prefixes (+Life, +Mana, +%Life) roll on weapons?**
   - What we know: User decision grants Claude's discretion. Weapon prefixes currently focus on damage (Physical Damage, %Physical Damage, Elemental variants).
   - What's unclear: Does adding +Life prefix to weapon pool dilute offensive identity? Or does it create interesting "tank weapon" build option?
   - Recommendation: Non-weapons only. Weapons remain pure offense (damage/crit affixes), armor/boots/helmet get defensive + utility prefixes. Ring gets offensive prefixes (damage/crit) + no defense (per user decision). This creates clear item type identities: weapon = offense, armor = defense, ring = bonus offense.

3. **What are the base values for original_base_evasion on current items?**
   - What we know: BasicArmor has original_base_armor = 15, original_base_energy_shield = 0 (basic_armor.gd:9-10). Boots/Helmet have similar.
   - What's unclear: Current items don't define original_base_evasion property. If adding FLAT_EVASION stat type, what's the base?
   - Recommendation: All current basic items have original_base_evasion = 0 (they're armor bases, not evasion). Future "leather boots" base would have original_base_armor = 0, original_base_evasion = 20. For v1.1, only armor prefixes roll on current items.

## Sources

### Primary (HIGH confidence)
- Existing codebase (Godot 4.6 GDScript project):
  - `models/affixes/affix.gd` - Tier calculation formula (lines 25-31)
  - `autoloads/item_affixes.gd` - Affix array pattern (lines 3-78)
  - `models/items/item.gd` - Tag-based filtering (lines 133-137, 140-163)
  - `models/stats/stat_calculator.gd` - Flat stat aggregation (lines 53-60), additive percentage pattern (lines 26-31)
  - `models/hero.gd` - Defense aggregation pattern (lines 99-112)
  - `scenes/hero_view.gd` - Stats display pattern (lines 191-201)

### Secondary (MEDIUM confidence)
- [Weighted Random Selection With Godot](http://kehomsforge.com/tutorials/single/weighted-random-selection-godot/) - Validated GDScript random selection patterns
- [Path of Exile Modifier System](https://www.poewiki.net/wiki/Modifier) - Tier 1 = best convention, additive "increased" modifier stacking
- [Path of Exile 2 Defense Guide (2026)](https://www.pathofexile.com/forum/view-thread/3694893) - Armor/Evasion/Energy Shield as separate defense types
- [Godot 4.6 Features Guide (2026)](https://www.live-laugh-love.world/blog/godot-46-features-complete-guide-2026/) - GDScript array iteration optimizations

### Tertiary (LOW confidence)
- [Idle Game Design Principles](https://ericguan.substack.com/p/idle-game-design-principles) - General idle game progression patterns (no specific tier depth recommendations)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Existing Godot 4.6 project with all necessary patterns proven
- Architecture: HIGH - Tag-based filtering, tier scaling, stat aggregation all currently implemented
- Pitfalls: MEDIUM - Tier scaling math verified, percentage stacking verified via DPS pattern, display logic straightforward. Tag pool emptying risk identified from codebase inspection.
- Value ranges: MEDIUM - Base values (2-5 for flat, 1-3 for %) are recommendations. Need playtesting validation in Phase 12.

**Research date:** 2026-02-15
**Valid until:** 60 days (stable patterns, Godot 4.6 confirmed as current stable, no fast-moving dependencies)

---

*Research complete. Ready for planning.*
