# Phase 45: Affix Pool Expansion - Research

## Research Summary

Phase 45 adds 14 new affixes to the rollable pool: 2 spell damage prefixes (flat + %), 1 cast speed suffix, 1 chaos resistance suffix, 3 flat DoT damage prefixes (bleed/poison/burn), 3 DoT chance suffixes (bleed/poison/burn), 3 %DoT damage suffixes, and 1 generic %DoT damage prefix. The existing tag.gd StatType enum already has BLEED_DAMAGE, POISON_DAMAGE, BURN_DAMAGE, FLAT_SPELL_DAMAGE, INCREASED_SPELL_DAMAGE, INCREASED_CAST_SPEED, and CHAOS_RESISTANCE from Phase 42, but three new stat types (BLEED_CHANCE, POISON_CHANCE, BURN_CHANCE) must be added. AFF-04 (Evade suffix) is dropped per user decision. The main risk is that affix.gd's damage range rolling is hardcoded to check `FLAT_DAMAGE` only -- flat spell damage and flat DoT prefixes using range-based params will need the check broadened.

## Existing Affix Patterns

### Constructor Signature

```gdscript
Affix.new(
    p_name: String,
    p_type: AffixType,        # PREFIX or SUFFIX
    p_min: int,               # base_min (scalar value floor)
    p_max: int,               # base_max (scalar value ceiling)
    p_tags: Array[String],    # tag constants for filtering
    p_stat_types: Array[int], # StatType enum values
    p_tier_range: Vector2i,   # always Vector2i(1, 32) currently
    p_dmg_min_lo: int = 0,   # flat damage range params (optional)
    p_dmg_min_hi: int = 0,
    p_dmg_max_lo: int = 0,
    p_dmg_max_hi: int = 0
)
```

### Existing Prefixes (18 total)

| Name | base_min | base_max | Tags | StatType | Damage Range Params |
|------|----------|----------|------|----------|-------------------|
| Physical Damage | 2 | 10 | PHYSICAL, FLAT, WEAPON | FLAT_DAMAGE | 3, 5, 7, 10 |
| %Physical Damage | 2 | 10 | PHYSICAL, PERCENTAGE, WEAPON | INCREASED_DAMAGE | - |
| %Elemental Damage | 2 | 10 | ELEMENTAL, WEAPON | INCREASED_DAMAGE | - |
| %Cold Damage | 2 | 10 | ELEMENTAL, COLD, WEAPON | INCREASED_DAMAGE | - |
| %Fire Damage | 2 | 10 | ELEMENTAL, FIRE, WEAPON | INCREASED_DAMAGE | - |
| %Lightning Damage | 2 | 10 | ELEMENTAL, LIGHTNING, WEAPON | INCREASED_DAMAGE | - |
| Lightning Damage | 2 | 10 | ELEMENTAL, LIGHTNING, WEAPON | FLAT_DAMAGE | 1, 3, 8, 16 |
| Fire Damage | 2 | 10 | ELEMENTAL, FIRE, WEAPON | FLAT_DAMAGE | 2, 4, 8, 14 |
| Cold Damage | 2 | 10 | ELEMENTAL, COLD, WEAPON | FLAT_DAMAGE | 2, 5, 7, 12 |
| Flat Armor | 2 | 5 | DEFENSE, PHYSICAL, ARMOR | FLAT_ARMOR | - |
| %Armor | 1 | 3 | DEFENSE, PHYSICAL, ARMOR | PERCENT_ARMOR | - |
| Evasion | 2 | 5 | DEFENSE, EVASION | FLAT_EVASION | - |
| %Evasion | 1 | 3 | DEFENSE, EVASION | PERCENT_EVASION | - |
| Energy Shield | 3 | 6 | DEFENSE, ENERGY_SHIELD | FLAT_ENERGY_SHIELD | - |
| %Energy Shield | 1 | 3 | DEFENSE, ENERGY_SHIELD | PERCENT_ENERGY_SHIELD | - |
| Health | 3 | 8 | DEFENSE, UTILITY | FLAT_HEALTH | - |
| %Health | 1 | 3 | DEFENSE, UTILITY | PERCENT_HEALTH | - |
| Mana | 2 | 6 | DEFENSE, MANA, UTILITY | FLAT_MANA | - |

### Existing Suffixes (9 active + 9 disabled stubs)

| Name | base_min | base_max | Tags | StatType |
|------|----------|----------|------|----------|
| Attack Speed | 2 | 10 | SPEED, ATTACK, PHYSICAL, WEAPON | INCREASED_SPEED |
| Life | 2 | 10 | DEFENSE, WEAPON | FLAT_HEALTH |
| Armor | 2 | 10 | DEFENSE, PHYSICAL, WEAPON | FLAT_ARMOR |
| Fire Resistance | 1 | 3 | DEFENSE, FIRE, WEAPON | FIRE_RESISTANCE |
| Cold Resistance | 1 | 3 | DEFENSE, COLD, WEAPON | COLD_RESISTANCE |
| Lightning Resistance | 1 | 3 | DEFENSE, LIGHTNING, WEAPON | LIGHTNING_RESISTANCE |
| All Resistances | 1 | 3 | DEFENSE, WEAPON | ALL_RESISTANCE |
| Critical Strike Chance | 2 | 10 | CRITICAL | CRIT_CHANCE |
| Critical Strike Damage | 2 | 10 | CRITICAL | CRIT_DAMAGE |

### Value Range Patterns

- Offensive scalars: base_min=2, base_max=10
- Resistance scalars: base_min=1, base_max=3
- Defensive scalars: base_min=2-3, base_max=5-8
- Flat damage ranges follow element identity (physical tight 3-5/7-10, lightning wide 1-3/8-16)
- All affixes use Vector2i(1, 32) tier range

## Current StatType Enum

### Already Present (from Phase 42)

```
FLAT_DAMAGE, INCREASED_DAMAGE, INCREASED_SPEED, CRIT_CHANCE, CRIT_DAMAGE,
FLAT_ARMOR, FLAT_ENERGY_SHIELD, FLAT_HEALTH, FLAT_MANA, MOVEMENT_SPEED,
PERCENT_ARMOR, PERCENT_EVASION, PERCENT_ENERGY_SHIELD, PERCENT_HEALTH,
FLAT_EVASION, FIRE_RESISTANCE, COLD_RESISTANCE, LIGHTNING_RESISTANCE,
ALL_RESISTANCE, FLAT_SPELL_DAMAGE, INCREASED_SPELL_DAMAGE,
INCREASED_CAST_SPEED, BLEED_DAMAGE, POISON_DAMAGE, BURN_DAMAGE,
CHAOS_RESISTANCE
```

### Needs Adding

- `BLEED_CHANCE` -- for bleed chance suffix
- `POISON_CHANCE` -- for poison chance suffix
- `BURN_CHANCE` -- for burn chance suffix

## Disabled Stubs Analysis

Lines 243-255 of `autoloads/item_affixes.gd`:

```gdscript
#Affix.new("Cast Speed", Affix.AffixType.SUFFIX, 2, 10, [Tag.MAGIC], []),
#Affix.new("Damage over time", Affix.AffixType.SUFFIX, 2, 10, [Tag.DOT, Tag.WEAPON], []),
#Affix.new("Bleed Damage", Affix.AffixType.SUFFIX, 2, 10, [Tag.DOT, Tag.PHYSICAL, Tag.WEAPON], []),
#Affix.new("Sigil", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE, Tag.MAGIC], []),
#Affix.new("Evade", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE, Tag.WEAPON], []),
#Affix.new("Physical Reduction", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE, Tag.WEAPON], []),
#Affix.new("Magical Reduction", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE, Tag.WEAPON], []),
#Affix.new("Dodge Chance", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE, Tag.WEAPON], []),
#Affix.new("Dmg Suppression Chance", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE, Tag.WEAPON], []),
```

**Phase 45 actions on stubs:**
- **Cast Speed**: Replace stub with proper implementation (tags change from [MAGIC] to [SPEED], stat_type = INCREASED_CAST_SPEED)
- **Bleed Damage**: Replace stub with expanded bleed affixes (flat prefix + chance suffix + % suffix)
- **Damage over time**: Replace with generic %DoT prefix
- **Evade**: DROPPED per user decision (AFF-04 dropped)
- **Sigil, Physical Reduction, Magical Reduction, Dodge Chance, Dmg Suppression Chance**: Leave disabled (future phases)

## Tag Filtering Mechanism

From `models/items/item.gd` line 248-252:

```gdscript
func has_valid_tag(affix: Affix) -> bool:
    for tag in self.valid_tags:
        if tag in affix.tags:
            return true
    return false
```

**Logic: OR-match.** An item can roll an affix if ANY ONE of the item's `valid_tags` appears in the affix's `tags` array. This means:
- An affix with tags [SPELL, FLAT, WEAPON] is rollable by any item that has SPELL OR FLAT OR WEAPON in its valid_tags
- An affix with tags [PHYSICAL] only rolls on items that have PHYSICAL in valid_tags

### Item Valid Tags Summary

| Item | valid_tags | Can Roll SPELL? | Can Roll PHYSICAL? | Can Roll CHAOS? | Can Roll FIRE? |
|------|------------|-----------------|-------------------|----------------|----------------|
| Broadsword | STR, PHYSICAL, ATTACK, ARMOR, ELEMENTAL, WEAPON | No | Yes | No | No |
| Battleaxe | STR, PHYSICAL, ATTACK, ARMOR, ELEMENTAL, WEAPON | No | Yes | No | No |
| Warhammer | STR, PHYSICAL, ATTACK, ARMOR, ELEMENTAL, WEAPON | No | Yes | No | No |
| Dagger | DEX, PHYSICAL, ATTACK, CRITICAL, EVASION, ELEMENTAL, WEAPON, CHAOS | No | Yes | Yes | No |
| VenomBlade | DEX, PHYSICAL, ATTACK, CRITICAL, EVASION, ELEMENTAL, WEAPON, CHAOS | No | Yes | Yes | No |
| Shortbow | DEX, PHYSICAL, ATTACK, CRITICAL, EVASION, ELEMENTAL, WEAPON, CHAOS | No | Yes | Yes | No |
| SapphireRing | INT, SPELL, SPEED, WEAPON | Yes | No | No | No |
| IronBand | STR, ATTACK, CRITICAL, SPEED, WEAPON | No | No | No | No |
| JadeRing | DEX, ATTACK, CRITICAL, SPEED, WEAPON, CHAOS | No | No | Yes | No |
| IronPlate | STR, DEFENSE, ARMOR | No | No | No | No |
| LeatherVest | DEX, DEFENSE, EVASION | No | No | No | No |
| SilkRobe | INT, DEFENSE, ENERGY_SHIELD | No | No | No | No |
| IronHelm | STR, DEFENSE, ARMOR | No | No | No | No |
| LeatherHood | DEX, DEFENSE, EVASION | No | No | No | No |
| Circlet | INT, DEFENSE, ENERGY_SHIELD | No | No | No | No |
| IronGreaves | STR, DEFENSE, ARMOR | No | No | No | No |
| LeatherBoots | DEX, DEFENSE, EVASION | No | No | No | No |
| SilkSlippers | INT, DEFENSE, ENERGY_SHIELD | No | No | No | No |

**Key observations for new affixes:**
- Spell damage affixes (tags include SPELL) will only roll on SapphireRing (only item with SPELL tag)
- Bleed affixes (tags include PHYSICAL) will roll on STR weapons + DEX weapons (both have PHYSICAL)
- Poison affixes (tags include CHAOS) will roll on DEX weapons + JadeRing (have CHAOS)
- Burn affixes (tags include FIRE) -- NO current item has FIRE in valid_tags. This is a gating problem.
- Cast Speed (tags [SPEED]) rolls on IronBand, JadeRing, SapphireRing (all have SPEED)
- Chaos Resistance (tags [DEFENSE, CHAOS, WEAPON]) rolls on items with DEFENSE or CHAOS or WEAPON

**CRITICAL: Burn affix accessibility.** Burn affixes with tag FIRE will not be rollable on any current item because no item has FIRE in its valid_tags. STR weapons have ELEMENTAL but not FIRE. Options:
1. Use ELEMENTAL tag instead of FIRE for burn (but then all elemental items get burn)
2. Add FIRE to INT weapon valid_tags when INT weapons ship in Phase 47
3. Accept that burn affixes are "pre-wired" and inaccessible until Phase 47

Per CONTEXT.md: "DoT affixes are pre-wired -- they roll on items and show stats, but the actual DoT tick mechanics are implemented in Phase 48." This suggests option 3 is acceptable -- burn affixes exist in the pool but no current item can roll them until INT weapons arrive.

## New Affixes Specification

### New Prefixes (5 total)

**1. Flat Spell Damage** (AFF-01)
```gdscript
Affix.new(
    "Spell Damage",
    Affix.AffixType.PREFIX,
    2, 10,
    [Tag.SPELL, Tag.FLAT, Tag.WEAPON],
    [Tag.StatType.FLAT_SPELL_DAMAGE],
    Vector2i(1, 32),
    3, 5, 7, 10  # matches physical damage parity
)
```

**2. %Spell Damage** (AFF-02)
```gdscript
Affix.new(
    "%Spell Damage",
    Affix.AffixType.PREFIX,
    2, 10,
    [Tag.SPELL, Tag.PERCENTAGE, Tag.WEAPON],
    [Tag.StatType.INCREASED_SPELL_DAMAGE],
    Vector2i(1, 32)
)
```

**3. Flat Bleed Damage** (AFF-05, DoT prefix)
```gdscript
Affix.new(
    "Bleed Damage",
    Affix.AffixType.PREFIX,
    2, 10,
    [Tag.DOT, Tag.PHYSICAL, Tag.WEAPON],
    [Tag.StatType.BLEED_DAMAGE],
    Vector2i(1, 32),
    2, 3, 4, 6  # lower than direct damage: DoT is supplemental
)
```

**4. Flat Poison Damage** (AFF-05, DoT prefix)
```gdscript
Affix.new(
    "Poison Damage",
    Affix.AffixType.PREFIX,
    2, 10,
    [Tag.DOT, Tag.CHAOS, Tag.WEAPON],
    [Tag.StatType.POISON_DAMAGE],
    Vector2i(1, 32),
    2, 3, 4, 6
)
```

**5. Flat Burn Damage** (AFF-05, DoT prefix)
```gdscript
Affix.new(
    "Burn Damage",
    Affix.AffixType.PREFIX,
    2, 10,
    [Tag.DOT, Tag.FIRE, Tag.WEAPON],
    [Tag.StatType.BURN_DAMAGE],
    Vector2i(1, 32),
    2, 3, 4, 6
)
```

**6. %DoT Damage** (AFF-05, generic DoT prefix)
```gdscript
Affix.new(
    "%DoT Damage",
    Affix.AffixType.PREFIX,
    2, 10,
    [Tag.DOT, Tag.WEAPON],
    [Tag.StatType.BLEED_DAMAGE, Tag.StatType.POISON_DAMAGE, Tag.StatType.BURN_DAMAGE],
    Vector2i(1, 32)
)
```
Note: Generic %DoT may need a single new stat type (e.g., INCREASED_DOT_DAMAGE) or use multiple stat_types. Since this is pre-wired and the DoT system ships in Phase 48, the exact stat aggregation pattern can be decided then. Using all three DoT stat types as a placeholder is one approach; adding a new generic INCREASED_DOT_DAMAGE stat type is cleaner.

### New Suffixes (7 total)

**1. Cast Speed** (AFF-03)
```gdscript
Affix.new(
    "Cast Speed",
    Affix.AffixType.SUFFIX,
    2, 10,
    [Tag.SPEED],
    [Tag.StatType.INCREASED_CAST_SPEED],
    Vector2i(1, 32)
)
```

**2. Chaos Resistance** (bonus, not in original AFF scope)
```gdscript
Affix.new(
    "Chaos Resistance",
    Affix.AffixType.SUFFIX,
    1, 3,
    [Tag.DEFENSE, Tag.CHAOS, Tag.WEAPON],
    [Tag.StatType.CHAOS_RESISTANCE],
    Vector2i(1, 32)
)
```

**3. Bleed Chance** (AFF-05, DoT suffix)
```gdscript
Affix.new(
    "Bleed Chance",
    Affix.AffixType.SUFFIX,
    3, 10,
    [Tag.DOT, Tag.PHYSICAL, Tag.WEAPON],
    [Tag.StatType.BLEED_CHANCE],
    Vector2i(1, 32)
)
```

**4. %Bleed Damage** (AFF-05, DoT suffix)
```gdscript
Affix.new(
    "%Bleed Damage",
    Affix.AffixType.SUFFIX,
    2, 10,
    [Tag.DOT, Tag.PHYSICAL, Tag.WEAPON],
    [Tag.StatType.BLEED_DAMAGE],
    Vector2i(1, 32)
)
```

**5. Poison Chance** (AFF-05, DoT suffix)
```gdscript
Affix.new(
    "Poison Chance",
    Affix.AffixType.SUFFIX,
    3, 10,
    [Tag.DOT, Tag.CHAOS, Tag.WEAPON],
    [Tag.StatType.POISON_CHANCE],
    Vector2i(1, 32)
)
```

**6. %Poison Damage** (AFF-05, DoT suffix)
```gdscript
Affix.new(
    "%Poison Damage",
    Affix.AffixType.SUFFIX,
    2, 10,
    [Tag.DOT, Tag.CHAOS, Tag.WEAPON],
    [Tag.StatType.POISON_DAMAGE],
    Vector2i(1, 32)
)
```

**7. Burn Chance** (AFF-05, DoT suffix)
```gdscript
Affix.new(
    "Burn Chance",
    Affix.AffixType.SUFFIX,
    3, 10,
    [Tag.DOT, Tag.FIRE, Tag.WEAPON],
    [Tag.StatType.BURN_CHANCE],
    Vector2i(1, 32)
)
```

**8. %Burn Damage** (AFF-05, DoT suffix)
```gdscript
Affix.new(
    "%Burn Damage",
    Affix.AffixType.SUFFIX,
    2, 10,
    [Tag.DOT, Tag.FIRE, Tag.WEAPON],
    [Tag.StatType.BURN_DAMAGE],
    Vector2i(1, 32)
)
```

### Total New: 6 prefixes + 8 suffixes = 14 affixes

## Validation Architecture

### Existing Test Structure

Single integration test file: `tools/test/integration_test.gd` (run via F6 in Godot editor).

**Test pattern:**
- Groups numbered sequentially (`_group_1_...`, `_group_2_...`, etc.)
- Currently 15 groups (groups 1-15)
- Helper `_check(condition, description)` prints PASS/FAIL
- Summary at end with pass/fail counts
- No external framework -- pure GDScript

**Relevant existing test groups:**
- Group 13: `_group_13_valid_tags_affix_gating` -- tests has_valid_tag for existing affixes
- Group 6: `_group_6_crafting_regression` -- tests RunicHammer affix application

### New Tests Needed

- **Group 16: New affix pool validation** -- verify all 14 new affixes exist in prefixes/suffixes arrays with correct stat types and tags
- **Group 17: Spell damage affix gating** -- SapphireRing can roll spell affixes, Broadsword cannot
- **Group 18: DoT affix gating** -- STR weapons roll bleed, DEX weapons roll poison, burn has no valid item yet
- **Group 19: Cast speed / chaos resistance accessibility** -- rings with SPEED tag can roll cast speed, items with DEFENSE/CHAOS/WEAPON can roll chaos resist
- **Group 20: Flat spell/DoT damage range rolling** -- verify affixes with damage range params actually roll add_min/add_max values (requires affix.gd fix)
- **Group 21: New StatType enum values** -- verify BLEED_CHANCE, POISON_CHANCE, BURN_CHANCE exist in enum

## Implementation Risk

### CRITICAL: Flat Damage Range Rolling Hardcoded to FLAT_DAMAGE

**File:** `models/affixes/affix.gd` lines 73 and 88

The `_init()` and `reroll()` methods only trigger damage range rolling when `Tag.StatType.FLAT_DAMAGE in self.stat_types`:

```gdscript
if Tag.StatType.FLAT_DAMAGE in self.stat_types and (dmg_min_hi > 0 or dmg_max_hi > 0):
```

New flat affixes (Flat Spell Damage with FLAT_SPELL_DAMAGE, Flat Bleed/Poison/Burn with BLEED_DAMAGE/POISON_DAMAGE/BURN_DAMAGE) pass damage range params but use different stat types. **They will NOT roll add_min/add_max values.** The condition must be broadened.

**Fix options:**
1. Change the check to `(dmg_min_hi > 0 or dmg_max_hi > 0)` only (remove stat type gate entirely -- if damage range params are provided, roll them)
2. Add all new flat stat types to the condition: `Tag.StatType.FLAT_DAMAGE in ... or Tag.StatType.FLAT_SPELL_DAMAGE in ... or Tag.StatType.BLEED_DAMAGE in ...`

**Option 1 is cleanest** -- any affix with damage range params should roll ranges regardless of stat type.

### MODERATE: forge_view.gd Display Logic

`scenes/forge_view.gd` line 933 also hardcodes `FLAT_DAMAGE` check for the "Adds X to Y Damage" display format. New flat spell/DoT affixes will display as "Name: value" instead of "Adds X to Y Type Damage". The `_format_affix_line()` and `_get_affix_element_name()` functions need updating to handle FLAT_SPELL_DAMAGE, BLEED_DAMAGE, POISON_DAMAGE, BURN_DAMAGE.

### MODERATE: stat_calculator.gd Only Handles Attack Damage

`models/stats/stat_calculator.gd` `calculate_damage_range()` only processes FLAT_DAMAGE and INCREASED_DAMAGE. Spell and DoT stat types are not aggregated anywhere yet. Per CONTEXT.md, this is expected -- DoT affixes are "pre-wired" and the actual mechanics ship in Phase 48 (DoT) and Phase 46 (spell damage). No changes needed to stat_calculator for this phase.

### LOW: Burn Affix Inaccessibility

No current item has FIRE in valid_tags. Burn affixes will exist in the pool but be unrollable until INT weapons ship in Phase 47. This is acceptable per "pre-wired" design intent.

### LOW: hero.gd Stat Aggregation

hero.gd does not aggregate the new stat types. Per CONTEXT.md line 94: "hero.gd: May need stat aggregation for new stat types (or defer to Phase 48)." Since affixes are pre-wired, deferring aggregation is acceptable.

## Files Modified

### Must Change

| File | Change |
|------|--------|
| `autoloads/tag.gd` | Add BLEED_CHANCE, POISON_CHANCE, BURN_CHANCE to StatType enum |
| `autoloads/item_affixes.gd` | Add 6 new prefixes, 8 new suffixes; remove/replace relevant disabled stubs |
| `models/affixes/affix.gd` | Broaden flat damage range check from FLAT_DAMAGE-only to any affix with damage range params |
| `scenes/forge_view.gd` | Update `_format_affix_line()` and `_get_affix_element_name()` for new flat damage stat types |
| `tools/test/integration_test.gd` | Add test groups 16-21 for new affixes |

### No Change Needed

| File | Reason |
|------|--------|
| `models/stats/stat_calculator.gd` | Spell/DoT stat aggregation deferred to Phase 46/48 |
| `models/hero.gd` | Stat aggregation deferred to Phase 48 |
| `models/items/*.gd` | No valid_tags changes needed this phase; items get new affix access through existing tags |

---

*Research completed: 2026-03-06*
*Phase: 45-affix-pool-expansion*
