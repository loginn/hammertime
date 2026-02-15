# Architecture Integration: v1.1 Content & Balance

**Domain:** ARPG crafting idle game (Godot 4.5 GDScript)
**Researched:** 2026-02-15
**Confidence:** HIGH

## Executive Summary

The v1.1 milestone adds defensive prefixes, expanded affixes, currency area gating, and drop rate rebalancing to an existing tag-based affix system. **All four features integrate cleanly through extension, not modification.** The existing architecture already supports these features through its tag-filtering system (ItemAffixes), area-aware drop generation (LootTable), and Resource-based data model. No architectural changes required — only data additions and parameter tuning.

**Key Integration Points:**
1. **Defensive Prefixes:** Add to ItemAffixes.prefixes[] with new tags (Tag.ARMOR, Tag.ENERGY_SHIELD, Tag.JEWELRY)
2. **Expanded Suffixes:** Add to ItemAffixes.suffixes[] (unlimited expansion)
3. **Currency Area Gating:** Add min_area_level field to Currency Resources, enforce in LootTable.roll_currency_drops()
4. **Drop Rate Rebalancing:** Tune RARITY_WEIGHTS and currency_rules dictionaries in LootTable

**Build Order:** Defensive Prefixes → Expanded Suffixes → Currency Gating → Drop Rebalancing (each feature independent)

## System Overview

### Current Architecture (v1.0)

```
┌─────────────────────────────────────────────────────────────┐
│                      UI Layer (Scenes)                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                   │
│  │ Hero     │  │ Crafting │  │ Gameplay │                   │
│  │ View     │  │ View     │  │ View     │                   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘                   │
│       │ signals     │              │                         │
├───────┴─────────────┴──────────────┴─────────────────────────┤
│                   Autoloads (Singletons)                     │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐             │
│  │ GameState  │  │ GameEvents │  │ItemAffixes │             │
│  │ (Hero+inv) │  │ (signals)  │  │ (defs)     │             │
│  └────┬───────┘  └────────────┘  └────┬───────┘             │
├───────┴──────────────────────────────────┴───────────────────┤
│                   Data Layer (Resources)                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │ Item     │  │ Affix    │  │ Currency │  │ LootTable│     │
│  │ (base)   │  │ (data)   │  │ (behav.) │  │ (drops)  │     │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘     │
└─────────────────────────────────────────────────────────────┘
```

### v1.1 Integration Points

```
┌─────────────────────────────────────────────────────────────┐
│                    NEW: Defensive Stats                      │
│  Armor/Evasion/Block prefixes for helmet/armor/boots/ring   │
│                           ↓                                  │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ ItemAffixes.prefixes[] — ADD defensive definitions    │  │
│  │ Tag constants — ADD JEWELRY, keep ARMOR/ES existing   │  │
│  │ Item.valid_tags[] — ALREADY contains required tags    │  │
│  └────────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                  NEW: Expanded Suffix Pool                   │
│           More variety in suffix affixes available          │
│                           ↓                                  │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ ItemAffixes.suffixes[] — ADD new definitions          │  │
│  │ StatCalculator — ADD methods for new stat types       │  │
│  └────────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                NEW: Currency Area Gating                     │
│      Rare hammers don't drop until specific areas           │
│                           ↓                                  │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ Currency.min_area_level — ADD field (default 1)       │  │
│  │ LootTable.roll_currency_drops() — ADD gating logic    │  │
│  │ GameState.current_area_level — ADD field              │  │
│  └────────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                  NEW: Drop Rate Rebalancing                  │
│       Rare items harder, advanced currencies rarer          │
│                           ↓                                  │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ LootTable.RARITY_WEIGHTS — MODIFY weights             │  │
│  │ LootTable.currency_rules — MODIFY chances/quantities  │  │
│  └────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Integration Analysis

### 1. Defensive Prefixes

**Current State:**
- 9 prefixes in ItemAffixes.prefixes[], ALL have Tag.WEAPON
- Item.add_prefix() filters by has_valid_tag(affix) — checks affix.tags[] against item.valid_tags[]
- Non-weapon items (Helmet, Armor, Boots, Ring) have valid_tags but NO matching prefixes

**Integration Method:** **EXTEND** ItemAffixes.prefixes[] with new definitions

**Required Changes:**

| Component | Change Type | Detail |
|-----------|-------------|--------|
| ItemAffixes.prefixes[] | ADD | New Affix definitions with Tag.ARMOR, Tag.ENERGY_SHIELD, Tag.JEWELRY |
| Tag.gd constants | VERIFY | Tag.ARMOR, Tag.ENERGY_SHIELD already exist (lines 17-18) |
| Tag.gd constants | ADD | Tag.JEWELRY for ring-specific prefixes |
| Tag.StatType enum | ADD | INCREASED_ARMOR, INCREASED_ENERGY_SHIELD, BLOCK_CHANCE, DODGE_CHANCE |
| StatCalculator | ADD | calculate_defense() method for aggregating defense multipliers |
| Armor/Helmet/Boots/Ring | MODIFY | update_value() calls StatCalculator.calculate_defense() |

**Data Flow:**
```
1. Item.add_prefix() called (existing method)
   ↓
2. ItemAffixes.prefixes filtered by has_valid_tag() (existing logic)
   ↓
3. NEW defensive prefixes now match non-weapon items
   ↓
4. Affix added to item.prefixes[] (existing)
   ↓
5. Item.update_value() called → StatCalculator.calculate_defense() (NEW)
   ↓
6. Defense stats recalculated with new affixes
```

**No Breaking Changes:**
- Existing weapon prefixes still work (Tag.WEAPON filtering unchanged)
- Item.add_prefix() already supports tag filtering
- Armor/Helmet/Boots already have total_defense field (line 6 in armor.gd)

### 2. Expanded Suffixes

**Current State:**
- 15 suffixes in ItemAffixes.suffixes[]
- 7 have stat_types[] defined (routed to StatCalculator)
- 8 have empty stat_types[] (display-only, not calculated)

**Integration Method:** **EXTEND** ItemAffixes.suffixes[]

**Required Changes:**

| Component | Change Type | Detail |
|-----------|-------------|--------|
| ItemAffixes.suffixes[] | ADD | New suffix definitions with appropriate tags |
| Tag.StatType enum | ADD | New stat types as needed (e.g., LIFE_REGEN, ELEMENTAL_RESIST) |
| StatCalculator | ADD | Methods for new stat types if they affect DPS/defense |

**Design Decision: Display vs Calculated Stats**

**Current pattern:**
- stat_types[] NOT EMPTY → StatCalculator handles aggregation
- stat_types[] EMPTY → Display-only (shown in tooltip, not calculated)

**For v1.1 expanded suffixes:**
- **Defensive stats** (resistances, regen, etc.) → Add stat_types[], implement in StatCalculator
- **Flavor stats** (item quantity, rarity, etc.) → Leave stat_types[] empty, display-only until mapping milestone

**No Breaking Changes:**
- Item.add_suffix() already supports unlimited suffix types
- Empty stat_types[] is valid (8 existing suffixes use this pattern)

### 3. Currency Area Gating

**Current State:**
- LootTable.roll_currency_drops() has flat probability per currency type
- No area-level awareness for WHICH currencies can drop
- Area level only affects QUANTITY (bonus_drops = area_level - 1)

**Integration Method:** **EXTEND** Currency with min_area_level, **MODIFY** LootTable gating logic

**Required Changes:**

| Component | Change Type | Detail |
|-----------|-------------|--------|
| Currency base class | ADD | var min_area_level: int = 1 field |
| RunicHammer, etc. | SET | Override min_area_level in _init() (Runic: 1, Forge: 2, Grand: 3, Claw: 4) |
| GameState | ADD | var current_area_level: int = 1 field |
| GameplayView | MODIFY | Set GameState.current_area_level when area changes |
| LootTable.roll_currency_drops() | MODIFY | Add area_level gating before probability roll |

**Recommended Gating Logic:**

```gdscript
# In LootTable.roll_currency_drops(area_level: int)

const CURRENCY_CONFIGS = {
    "runic": {"class": RunicHammer, "chance": 0.7, "min_qty": 1, "max_qty": 2},
    "forge": {"class": ForgeHammer, "chance": 0.3, "min_qty": 1, "max_qty": 1},
    "tack": {"class": TackHammer, "chance": 0.5, "min_qty": 1, "max_qty": 2},
    "grand": {"class": GrandHammer, "chance": 0.2, "min_qty": 1, "max_qty": 1},
    "claw": {"class": ClawHammer, "chance": 0.4, "min_qty": 1, "max_qty": 2},
    "tuning": {"class": TuningHammer, "chance": 0.4, "min_qty": 1, "max_qty": 2},
}

for currency_name in CURRENCY_CONFIGS:
    var config = CURRENCY_CONFIGS[currency_name]
    var currency_instance = config["class"].new()

    # AREA GATING: Skip if area too low
    if area_level < currency_instance.min_area_level:
        continue

    # Existing probability logic
    if randf() < config["chance"]:
        var quantity = randi_range(config["min_qty"], config["max_qty"])
        drops[currency_name] = quantity
```

**Ramping Drop Chance (Optional Enhancement):**

For "low initial drop chance ramping up" requirement:

```gdscript
# After gating check, before probability roll:
var adjusted_chance = config["chance"]

# Ramp up chance if just unlocked (within 2 levels of min_area_level)
var levels_past_unlock = area_level - currency_instance.min_area_level
if levels_past_unlock >= 0 and levels_past_unlock <= 2:
    # Start at 20% of base chance, ramp to 100% over 2 levels
    var ramp_multiplier = 0.2 + (levels_past_unlock / 2.0) * 0.8
    adjusted_chance *= ramp_multiplier

if randf() < adjusted_chance:
    # ... award currency
```

**No Breaking Changes:**
- Existing currency_rules structure can be replaced with CURRENCY_CONFIGS
- min_area_level defaults to 1 (no change for areas 1+)

### 4. Drop Rate Rebalancing

**Current State:**
- RARITY_WEIGHTS: Area 1 has 80% normal, 18% magic, 2% rare
- currency_rules: Runic 70%, Tack 50%, Tuning 40%, Claw 40%, Forge 30%, Grand 20%

**Integration Method:** **MODIFY** existing constants

**Required Changes:**

| Component | Change Type | Detail |
|-----------|-------------|--------|
| LootTable.RARITY_WEIGHTS | MODIFY | Reduce rare% at low levels, increase magic% gap |
| LootTable.currency_rules | MODIFY | Reduce advanced currency chances |

**Recommended Tuning:**

```gdscript
# BEFORE (v1.0):
const RARITY_WEIGHTS = {
    1: { NORMAL: 80, MAGIC: 18, RARE: 2 },   # 2% rare at area 1
    2: { NORMAL: 50, MAGIC: 40, RARE: 10 },  # 10% rare at area 2
    3: { NORMAL: 20, MAGIC: 45, RARE: 35 },
    4: { NORMAL: 5, MAGIC: 30, RARE: 65 },
}

# AFTER (v1.1 — rare items harder to find):
const RARITY_WEIGHTS = {
    1: { NORMAL: 90, MAGIC: 10, RARE: 0 },   # No rares at area 1
    2: { NORMAL: 70, MAGIC: 25, RARE: 5 },   # 5% rare at area 2 (was 10%)
    3: { NORMAL: 40, MAGIC: 40, RARE: 20 },  # 20% rare at area 3 (was 35%)
    4: { NORMAL: 10, MAGIC: 35, RARE: 55 },  # 55% rare at area 4 (was 65%)
    5: { NORMAL: 5, MAGIC: 30, RARE: 65 },   # Endgame unchanged
}
```

```gdscript
# BEFORE (v1.0):
var currency_rules = {
    "runic": {"chance": 0.7, "min_qty": 1, "max_qty": 2},
    "forge": {"chance": 0.3, "min_qty": 1, "max_qty": 1},
    "grand": {"chance": 0.2, "min_qty": 1, "max_qty": 1},
}

# AFTER (v1.1 — advanced currencies rarer):
var currency_rules = {
    "runic": {"chance": 0.6, "min_qty": 1, "max_qty": 2},  # -10%
    "forge": {"chance": 0.2, "min_qty": 1, "max_qty": 1},  # -33% (0.3 → 0.2)
    "grand": {"chance": 0.1, "min_qty": 1, "max_qty": 1},  # -50% (0.2 → 0.1)
    "claw": {"chance": 0.25, "min_qty": 1, "max_qty": 1},  # -37.5% (0.4 → 0.25)
    "tuning": {"chance": 0.25, "min_qty": 1, "max_qty": 1},# -37.5% (0.4 → 0.25)
}
```

**No Breaking Changes:**
- Same data structure, different values
- Areas 1-4 already implemented

## Data Flow Changes

### Affix Selection (Defensive Prefixes)

**BEFORE (v1.0):**
```
Item.add_prefix()
  ↓
Filter ItemAffixes.prefixes by has_valid_tag()
  ↓
Non-weapon items: valid_prefixes = [] (no matches)
  ↓
Return false (cannot add prefix)
```

**AFTER (v1.1):**
```
Item.add_prefix()
  ↓
Filter ItemAffixes.prefixes by has_valid_tag()
  ↓
Non-weapon items: valid_prefixes = [defensive options] (NEW matches)
  ↓
Pick random, add to item.prefixes[]
  ↓
Item.update_value() → StatCalculator.calculate_defense() (NEW)
```

### Currency Drop Generation (Area Gating)

**BEFORE (v1.0):**
```
LootTable.roll_currency_drops(area_level)
  ↓
For each currency type:
  Roll probability → award if successful
  ↓
Add (area_level - 1) bonus drops
```

**AFTER (v1.1):**
```
LootTable.roll_currency_drops(area_level)
  ↓
For each currency type:
  Check currency.min_area_level ≤ area_level (NEW gating)
    ↓ (skip if too low)
  Apply ramp multiplier if just unlocked (NEW)
    ↓
  Roll adjusted probability → award if successful
  ↓
Add (area_level - 1) bonus drops (unchanged)
```

## Component Changes Summary

### NEW Components

**None.** All features integrate through existing components.

### MODIFIED Components

| Component | Modification | Reason |
|-----------|--------------|--------|
| ItemAffixes.gd | Add defensive prefix definitions, expanded suffix definitions | Core feature: defensive prefixes + expanded affixes |
| Tag.gd | Add Tag.JEWELRY constant, add StatType entries | Support new prefix tags and stat routing |
| StatCalculator.gd | Add calculate_defense() method | Aggregate defense multipliers (same pattern as calculate_dps) |
| Currency.gd | Add var min_area_level: int = 1 | Enable area gating per currency type |
| RunicHammer.gd, etc. | Set min_area_level in _init() | Define unlock areas (Runic: 1, Forge: 2, Grand: 3, Claw: 4) |
| LootTable.gd | Add area gating logic to roll_currency_drops(), modify RARITY_WEIGHTS and currency_rules | Currency gating + drop rebalancing |
| GameState.gd | Add var current_area_level: int = 1 | Track current area for currency gating |
| Armor/Helmet/Boots/Ring.gd | Call StatCalculator.calculate_defense() in update_value() | Apply defensive prefix effects |

### UNCHANGED Components (Key)

| Component | Why Unchanged |
|-----------|---------------|
| Item.gd | add_prefix()/add_suffix() already support tag filtering |
| Affix.gd | Data structure supports any tags/stat_types |
| GameEvents.gd | No new signals needed |
| All UI views | Display already reads item.total_defense, item.prefixes[] |

## Build Order

### Recommended Sequence

1. **Defensive Prefixes** (1-2 hours)
   - Add Tag.JEWELRY constant
   - Add StatType entries (INCREASED_ARMOR, etc.)
   - Add defensive prefix definitions to ItemAffixes.prefixes[]
   - Add StatCalculator.calculate_defense()
   - Modify Armor/Helmet/Boots/Ring.update_value()
   - **Test:** Craft non-weapon items, verify defensive prefixes appear

2. **Expanded Suffixes** (30 min - 1 hour)
   - Add new suffix definitions to ItemAffixes.suffixes[]
   - Add StatType entries if needed
   - Add StatCalculator methods if stats are calculated (not display-only)
   - **Test:** Verify new suffixes appear on all item types

3. **Currency Area Gating** (1-2 hours)
   - Add Currency.min_area_level field
   - Set min_area_level in each Currency subclass _init()
   - Add GameState.current_area_level field
   - Modify GameplayView to set current_area_level on area change
   - Modify LootTable.roll_currency_drops() with gating logic
   - **Test:** Clear area 1, verify no Grand/Claw/Forge drops; clear area 3, verify Grand drops

4. **Drop Rate Rebalancing** (15-30 min)
   - Modify LootTable.RARITY_WEIGHTS
   - Modify LootTable.currency_rules
   - **Test:** Clear each area 20 times, log drop counts, verify new distributions

**Dependencies:**
- None between features (fully independent)
- Within Defensive Prefixes: Tag constants → ItemAffixes definitions → StatCalculator → Item subclasses
- Within Currency Gating: Currency.min_area_level → GameState.current_area_level → LootTable logic

## Testing Integration Points

### Per-Feature Tests

**Defensive Prefixes:**
```gdscript
# Test non-weapon items can receive defensive prefixes
var helmet = BasicHelmet.new()
helmet.rarity = Item.Rarity.RARE
helmet.add_prefix()  # Should succeed with defensive prefix
assert(helmet.prefixes.size() > 0)
assert(Tag.ARMOR in helmet.prefixes[0].tags or Tag.ENERGY_SHIELD in helmet.prefixes[0].tags)

# Test defensive stats are calculated
helmet.update_value()
assert(helmet.total_defense > helmet.original_base_armor)  # Affixes increased defense
```

**Currency Area Gating:**
```gdscript
# Test Grand Hammer doesn't drop in area 1
GameState.current_area_level = 1
var drops = LootTable.roll_currency_drops(1)
assert(not drops.has("grand"))

# Test Grand Hammer can drop in area 3
GameState.current_area_level = 3
drops = LootTable.roll_currency_drops(3)
# May or may not drop (probability), but should be in pool
# Run 100 times, verify Grand appears at least once
```

**Drop Rebalancing:**
```gdscript
# Test rare items are harder to find in early areas
var rare_count = 0
for i in range(100):
    var rarity = LootTable.roll_rarity(1)
    if rarity == Item.Rarity.RARE:
        rare_count += 1
assert(rare_count == 0)  # Should be 0% at area 1 with new weights
```

### Cross-Feature Integration Tests

```gdscript
# Test defensive prefix on rare helmet from area 3 drop
var helmet = LootTable.spawn_item_with_mods(BasicHelmet.new(), LootTable.roll_rarity(3))
# Helmet may have defensive prefix if rare
if helmet.rarity == Item.Rarity.RARE and helmet.prefixes.size() > 0:
    # Verify defensive prefix works
    var has_defensive = false
    for prefix in helmet.prefixes:
        if Tag.ARMOR in prefix.tags or Tag.ENERGY_SHIELD in prefix.tags:
            has_defensive = true
            break
    # At least one defensive prefix should exist with new pool
```

## Architectural Patterns (Reused)

### Pattern 1: Tag-Based Filtering (EXISTING, EXTENDED)

**What:** Affixes have tags[], items have valid_tags[]. Filtering matches tags to determine eligible affixes.

**Already Implemented:**
```gdscript
# Item.gd, line 133-137
func has_valid_tag(affix: Affix) -> bool:
    for tag in self.valid_tags:
        if tag in affix.tags:
            return true
    return false
```

**v1.1 Extension:**
```gdscript
# ItemAffixes.gd — NEW defensive prefix
Affix.new(
    "Armor",
    Affix.AffixType.PREFIX,
    5,
    20,
    [Tag.ARMOR, Tag.DEFENSE],  # Tag.ARMOR matches Helmet/Armor/Boots valid_tags
    [Tag.StatType.INCREASED_ARMOR]
)
```

**Why this works:** Helmet/Armor/Boots already have Tag.ARMOR in valid_tags (set during item creation). Adding prefixes with Tag.ARMOR makes them eligible for selection.

### Pattern 2: Template Method (Currency) (EXISTING, EXTENDED)

**What:** Base Currency.apply() enforces validation, subclasses override _do_apply() for behavior.

**Already Implemented:**
```gdscript
# Currency.gd, lines 12-21
func apply(item: Item) -> bool:
    if not can_apply(item):
        return false
    _do_apply(item)
    return true
```

**v1.1 Extension:**
```gdscript
# Grand Hammer with area gating
class_name GrandHammer extends Currency

var min_area_level: int = 3  # NEW field

func can_apply(item: Item) -> bool:
    return item.rarity == Item.Rarity.MAGIC and item.prefixes.size() < 1
    # Area gating enforced in LootTable, not here
    # (Currency doesn't know GameState.current_area_level)

func _do_apply(item: Item) -> void:
    if item.add_prefix():
        item.update_value()
```

**Why this works:** Area gating is a drop restriction, not an application restriction. LootTable.roll_currency_drops() checks min_area_level BEFORE awarding currency. Once awarded, Currency.apply() works as before.

### Pattern 3: Static Utility (LootTable) (EXISTING, MODIFIED)

**What:** LootTable provides static methods for drop generation. No instance required.

**Already Implemented:**
```gdscript
# LootTable.gd, line 53
static func roll_currency_drops(area_level: int) -> Dictionary:
```

**v1.1 Modification:**
```gdscript
# Add gating logic while preserving static pattern
static func roll_currency_drops(area_level: int) -> Dictionary:
    var drops: Dictionary = {}

    for currency_name in CURRENCY_CONFIGS:
        var currency_class = CURRENCY_CONFIGS[currency_name]["class"]
        var temp_instance = currency_class.new()  # Temporary for min_area_level check

        if area_level < temp_instance.min_area_level:
            continue  # Area gating

        # Existing probability logic...
```

**Trade-off:** Creates temporary Currency instances for min_area_level check. Alternative would be hardcoding area requirements in LootTable, but that duplicates data (min_area_level would exist in two places).

**Recommendation:** Use temporary instances. GDScript object creation is cheap, and it keeps area requirements defined in Currency subclasses (single source of truth).

## Anti-Patterns to Avoid

### Anti-Pattern 1: Hardcoding Area Requirements in LootTable

**What people might do:**
```gdscript
# LootTable.gd — WRONG
const AREA_REQUIREMENTS = {
    "runic": 1,
    "forge": 2,
    "grand": 3,
    "claw": 4,
}

static func roll_currency_drops(area_level: int) -> Dictionary:
    for currency_name in currency_rules:
        if area_level < AREA_REQUIREMENTS[currency_name]:
            continue
```

**Why it's wrong:**
- Duplicates min_area_level data (Currency subclass AND LootTable)
- If Currency.min_area_level changes, LootTable must also change
- Violates single source of truth

**Do this instead:**
```gdscript
# Get min_area_level from Currency subclass (authoritative source)
var currency_class = CURRENCY_CONFIGS[currency_name]["class"]
var temp = currency_class.new()
if area_level < temp.min_area_level:
    continue
```

### Anti-Pattern 2: Adding Defensive Stats to StatCalculator.calculate_dps()

**What people might do:**
```gdscript
# StatCalculator.gd — WRONG
static func calculate_dps(...):
    # ... existing DPS logic

    # Add armor calculation here
    var armor = base_armor
    for affix in affixes:
        if Tag.StatType.INCREASED_ARMOR in affix.stat_types:
            armor *= (1.0 + affix.value / 100.0)
    return dps  # But armor isn't part of DPS!
```

**Why it's wrong:**
- DPS and defense are separate concerns
- Defense items don't have dps field
- Breaks single responsibility principle

**Do this instead:**
```gdscript
# StatCalculator.gd — CORRECT (separate method)
static func calculate_defense(base_armor: float, affixes: Array) -> float:
    var armor = base_armor
    for affix in affixes:
        if Tag.StatType.INCREASED_ARMOR in affix.stat_types:
            armor *= (1.0 + affix.value / 100.0)
    return armor

# Armor.gd — call appropriate method
func update_value() -> void:
    self.base_armor = StatCalculator.calculate_defense(
        self.original_base_armor,
        self.prefixes + self.suffixes + [self.implicit]
    )
```

### Anti-Pattern 3: Creating New Autoloads for v1.1 Features

**What people might do:**
- Create DefensiveAffixes.gd autoload for defensive prefixes
- Create CurrencyGating.gd autoload for area restrictions

**Why it's wrong:**
- ItemAffixes already exists for affix definitions
- LootTable already handles drop logic
- Creates unnecessary singletons

**Do this instead:**
- Add defensive prefixes to existing ItemAffixes.prefixes[]
- Add gating logic to existing LootTable.roll_currency_drops()

## Risk Assessment

### Low Risk

**Defensive Prefixes:**
- Risk: Existing weapon prefixes break
- Mitigation: Tag filtering unchanged. Weapon items still match Tag.WEAPON, non-weapon items now match Tag.ARMOR/JEWELRY
- Test: Verify weapon prefixes still work after adding defensive prefixes

**Expanded Suffixes:**
- Risk: Minimal — suffix pool is already heterogeneous (15 types with different tags)
- Mitigation: Follow existing pattern (some have stat_types, some don't)

### Medium Risk

**Currency Area Gating:**
- Risk: Off-by-one errors in area_level comparisons (< vs <=)
- Mitigation: Use clear inequality (area_level < min_area_level means "not unlocked yet")
- Test: Boundary testing (area 2 with min_area_level=2 should allow drops)

**Drop Rate Rebalancing:**
- Risk: Over-tuning makes progression too slow/fast
- Mitigation: Start conservative (small adjustments), playtest, iterate
- Test: Log drop counts over 100 area clears, measure actual vs intended distribution

### High Risk

**None.** All changes are additive or parameter tuning. No core architecture modifications.

## Performance Considerations

### Temporary Currency Instance Creation

**Impact:** LootTable.roll_currency_drops() creates 6 temporary Currency instances per call (one per currency type for min_area_level check).

**Frequency:** Once per area clear (not per frame).

**Cost:** Negligible. GDScript object instantiation is ~microseconds. Area clears happen every few seconds.

**Optimization (if needed):** Cache min_area_level in static dictionary:

```gdscript
# LootTable.gd
const CURRENCY_MIN_LEVELS = {
    "runic": 1,
    "forge": 2,
    "tack": 1,
    "grand": 3,
    "claw": 4,
    "tuning": 1,
}

# Use in roll_currency_drops() instead of temp instances
if area_level < CURRENCY_MIN_LEVELS[currency_name]:
    continue
```

**Trade-off:** Duplicates data (anti-pattern 1), but eliminates object creation. Only optimize if profiling shows bottleneck (unlikely).

## Sources

**Project Codebase Analysis:**
- `/var/home/travelboi/Programming/hammertime/autoloads/tag.gd` — Tag constants and StatType enum
- `/var/home/travelboi/Programming/hammertime/autoloads/item_affixes.gd` — Affix definitions and filtering
- `/var/home/travelboi/Programming/hammertime/models/items/item.gd` — Tag-based affix selection (add_prefix/add_suffix)
- `/var/home/travelboi/Programming/hammertime/models/loot/loot_table.gd` — Drop generation and rarity weights
- `/var/home/travelboi/Programming/hammertime/models/currencies/currency.gd` — Template method pattern
- `/var/home/travelboi/Programming/hammertime/models/stats/stat_calculator.gd` — Stat aggregation patterns
- `/var/home/travelboi/Programming/hammertime/.planning/PROJECT.md` — v1.1 requirements and constraints

**Architecture Patterns:**
- Existing codebase patterns (tag filtering, template method, static utilities)
- Godot 4.5 Resource system (no external sources needed — built-in engine feature)

---
*Architecture integration research for: Hammertime v1.1 Content & Balance*
*Researched: 2026-02-15*
*Confidence: HIGH (all integration points verified in existing codebase)*
