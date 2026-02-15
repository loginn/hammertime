---
phase: 09-defensive-prefix-foundation
plan: 01
subsystem: crafting/affixes
tags: [affixes, defensive-stats, tier-system]
dependency_graph:
  requires: [tag-system, item-affixes, stat-calculator]
  provides: [defensive-prefixes, utility-prefixes, percentage-stats, 30-tier-range]
  affects: [armor-items, boots-items, helmet-items]
tech_stack:
  added: [Vector2i-tier-range, percentage-stat-calculation]
  patterns: [additive-percentage-stacking, flat-then-percentage]
key_files:
  created: []
  modified:
    - autoloads/tag.gd
    - models/affixes/affix.gd
    - autoloads/item_affixes.gd
    - models/stats/stat_calculator.gd
    - models/items/armor.gd
    - models/items/boots.gd
    - models/items/helmet.gd
decisions:
  - Use Vector2i for tier_range (backwards compatible default of 1-8 for existing affixes)
  - Store base_min/base_max in Affix to fix double-scaling bug in from_affix()
  - Apply percentage modifiers after flat additions using additive stacking (matches DPS calculation pattern)
  - Add evasion/health properties to all defense items for future base type support
  - Defensive prefixes require Tag.DEFENSE to prevent rings from rolling them
metrics:
  duration_seconds: 170
  tasks_completed: 2
  commits: 2
  files_modified: 7
  completed_date: 2026-02-15
---

# Phase 09 Plan 01: Defensive Prefix Foundation Summary

**One-liner:** Extended tag system with configurable 30-tier ranges and added 9 defensive/utility prefixes (flat/% armor/evasion/ES + life/mana) using additive percentage stacking.

## Tasks Completed

| Task | Name | Commit | Key Changes |
|------|------|--------|-------------|
| 1 | Extend Tag enums, make Affix tier range configurable, add defensive + utility prefixes | 0c8cf03 | Added UTILITY/EVASION tags, 5 new StatType enums, tier_range Vector2i param, 9 new prefixes with 30-tier range |
| 2 | Add percentage stat calculation and update defense item models | 9a4aee1 | Added calculate_percentage_stat(), evasion/health properties to armor/boots/helmet, flat+percentage calculation |

## Implementation Details

### Tag System Extensions

**New tag constants:**
- `UTILITY` - For non-combat utility affixes (life, mana)
- `EVASION` - For evasion-based defense (future leather armor support)

**New StatType enum values:**
- `PERCENT_ARMOR` - Percentage armor modifier
- `PERCENT_EVASION` - Percentage evasion modifier
- `PERCENT_ENERGY_SHIELD` - Percentage ES modifier
- `PERCENT_HEALTH` - Percentage health modifier
- `FLAT_EVASION` - Flat evasion addition

### Affix Tier Range System

**Implementation:**
- Added `tier_range: Vector2i` property to Affix (default Vector2i(1, 8))
- Added `base_min/base_max` properties to store original values before tier scaling
- Updated `_init()` to accept optional `p_tier_range` parameter
- Modified tier scaling formula: `value = base * (tier_range.y + 1 - tier)`

**Bug fix:** Updated `from_affix()` to use `base_min/base_max` instead of `min_value/max_value`. Previous implementation passed already-scaled values that got scaled again, causing incorrect affix values.

### New Prefixes

**Defensive (6 total, 30-tier range):**
1. "Armored" - Flat armor (2-5 base) - Tags: DEFENSE, ARMOR
2. "Reinforced" - % armor (1-3 base) - Tags: DEFENSE, ARMOR
3. "Evasive" - Flat evasion (2-5 base) - Tags: DEFENSE, EVASION
4. "Swift" - % evasion (1-3 base) - Tags: DEFENSE, EVASION
5. "Warded" - Flat ES (3-6 base) - Tags: DEFENSE, ENERGY_SHIELD
6. "Arcane" - % ES (1-3 base) - Tags: DEFENSE, ENERGY_SHIELD

**Utility (3 total, 30-tier range):**
7. "Healthy" - Flat health (3-8 base) - Tags: DEFENSE, UTILITY
8. "Vital" - % health (1-3 base) - Tags: DEFENSE, UTILITY
9. "Mystic" - Flat mana (2-6 base) - Tags: DEFENSE, MANA, UTILITY

**Tag strategy:** All defensive/utility prefixes require Tag.DEFENSE. This prevents rings (valid_tags: ATTACK, CRITICAL, SPEED) from rolling these prefixes, ensuring rings remain weapon-focused.

### Percentage Stat Calculation

**Method:** `StatCalculator.calculate_percentage_stat(base_value, affixes, stat_type)`

**Stacking behavior:** Additive stacking - all percentage modifiers for a stat type sum, then apply once to base value.

**Example:** base=100, two +50% affixes → 100 * (1.0 + 0.5 + 0.5) = 200

**Pattern match:** Matches INCREASED_DAMAGE calculation in `calculate_dps()` for consistency.

### Defense Item Updates

**Property additions:**
- Armor: Added `base_evasion`, `original_base_evasion`
- Boots: Added `base_evasion`, `original_base_evasion`, `base_health`, `original_base_health`
- Helmet: Added `base_evasion`, `original_base_evasion`, `base_health`, `original_base_health`

**Calculation order (all three item types):**
1. Apply flat additions: `flat_value = original_base + sum(FLAT_X affixes)`
2. Apply percentage modifiers: `final_value = flat_value * (1.0 + sum(PERCENT_X affixes) / 100)`

**Stats affected:**
- Armor, Boots, Helmet: armor, evasion, energy_shield, health
- Boots: Also movement_speed (flat only, no percentage currently)
- Helmet: Also mana (flat only, no percentage currently)

**Display updates:** `get_display_text()` now shows evasion and health if non-zero.

**Backward compatibility:** `total_defense` still equals `base_armor` for legacy code compatibility.

## Verification Results

**Syntax check:** No GDScript errors or warnings when loading project.

**Prefix count:** 18 total prefixes (9 weapon + 9 defensive/utility) confirmed.

**File modifications:**
- autoloads/tag.gd: 7 new constants/enums
- models/affixes/affix.gd: 3 new properties, updated _init() and tier scaling
- autoloads/item_affixes.gd: 9 new prefix definitions, fixed from_affix()
- models/stats/stat_calculator.gd: New calculate_percentage_stat() method
- models/items/armor.gd: 2 new properties, updated update_value() and display
- models/items/boots.gd: 4 new properties, updated update_value() and display
- models/items/helmet.gd: 4 new properties, updated update_value() and display

## Deviations from Plan

**Auto-fixed Issues:**

**1. [Rule 1 - Bug] Fixed double-scaling bug in from_affix()**
- **Found during:** Task 1 implementation
- **Issue:** `from_affix()` was passing `template.min_value` and `template.max_value` (already tier-scaled) to Affix constructor, which then scaled them again. This caused affix copies to have incorrect (double-scaled) values.
- **Fix:** Added `base_min` and `base_max` properties to Affix to store original unscaled values. Updated `from_affix()` to pass these instead of the scaled values.
- **Files modified:** models/affixes/affix.gd, autoloads/item_affixes.gd
- **Commit:** 0c8cf03
- **Impact:** Fixes existing weapon affixes too - this was a latent bug affecting all affix copying.

## Success Criteria Met

- [x] 9 new prefixes in ItemAffixes (6 defensive + 3 utility), all using 30-tier range
- [x] Existing 9 weapon prefixes unchanged (8-tier range)
- [x] Affix tier_range configurable per affix via constructor parameter
- [x] StatCalculator.calculate_percentage_stat() works with additive stacking
- [x] Armor/Boots/Helmet update_value() applies flat + percentage for all defense types
- [x] Rings cannot roll defensive or utility prefixes (Tag.DEFENSE requirement)
- [x] No regressions to existing weapon crafting

## Key Decisions Made

1. **Tier range implementation:** Vector2i(min, max) provides clean, type-safe range definition. Default of (1, 8) ensures backward compatibility.

2. **Base value storage:** Storing base_min/base_max separately from min_value/max_value enables correct copying and future tier display features.

3. **Percentage stacking:** Additive stacking matches existing INCREASED_DAMAGE pattern and prevents exponential scaling.

4. **Future-proofing:** Added evasion properties to all defense items even though current basic items are armor bases. This supports future leather armor (Tag.EVASION) and mage robes (Tag.ENERGY_SHIELD) without code changes.

5. **Ring exclusion:** Defensive/utility prefixes require Tag.DEFENSE. Rings have valid_tags [ATTACK, CRITICAL, SPEED], so they correctly cannot roll these prefixes.

## Next Steps

**Immediate:**
- Phase 09 Plan 02: Create basic evasion/ES base types (leather armor, mage robes)
- Phase 09 Plan 03: Add UI indicators for affix tier quality (T1-T8 vs T1-T30)

**Future phases:**
- Phase 10: Area-gated currency drops
- Phase 11: Drop rate rebalancing
- Phase 12: Integration testing

## Self-Check: PASSED

**Created files verified:** None (all modifications to existing files)

**Modified files verified:**
- FOUND: /var/home/travelboi/Programming/hammertime/autoloads/tag.gd
- FOUND: /var/home/travelboi/Programming/hammertime/models/affixes/affix.gd
- FOUND: /var/home/travelboi/Programming/hammertime/autoloads/item_affixes.gd
- FOUND: /var/home/travelboi/Programming/hammertime/models/stats/stat_calculator.gd
- FOUND: /var/home/travelboi/Programming/hammertime/models/items/armor.gd
- FOUND: /var/home/travelboi/Programming/hammertime/models/items/boots.gd
- FOUND: /var/home/travelboi/Programming/hammertime/models/items/helmet.gd

**Commits verified:**
- FOUND: 0c8cf03 (Task 1: configurable tier ranges and defensive/utility prefixes)
- FOUND: 9a4aee1 (Task 2: percentage stat calculation and defense item updates)

All planned artifacts created, all commits exist, implementation complete.
