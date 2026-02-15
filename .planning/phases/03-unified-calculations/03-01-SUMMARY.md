---
phase: 03-unified-calculations
plan: 01
subsystem: stat-calculation
tags: [infrastructure, enum, calculator, affixes]
dependency_graph:
  requires: [02-data-model-migration]
  provides: [stat-type-enum, stat-calculator, affix-stat-types]
  affects: [item-calculations]
tech_stack:
  added: [StatCalculator]
  patterns: [static-utility-class, weighted-average-formula]
key_files:
  created:
    - models/stats/stat_calculator.gd
  modified:
    - autoloads/tag.gd
    - models/affixes/affix.gd
    - autoloads/item_affixes.gd
decisions:
  - "StatType enum uses 10 entries (no MORE_DAMAGE, INCREASED_ARMOR, or elemental damage types - deferred per research)"
  - "Affix.stat_types typed as Array[int] to hold StatType enum values"
  - "p_stat_types parameter placed last in Affix._init() for backward compatibility with existing Implicit.new() calls"
  - "StatCalculator uses untyped Array parameter (not Array[Affix]) to handle GDScript array concatenation behavior"
  - "Weighted-average crit formula: 1 + (c/100) * (d/100 - 1) for mathematically correct expected value"
  - "15 affixes legitimately have empty stat_types (exist for filtering but not used in calculations)"
metrics:
  duration: 2 minutes
  tasks_completed: 2
  files_created: 1
  files_modified: 3
  commits: 2
  completed_date: 2026-02-15
---

# Phase 03 Plan 01: Unified Calculation Infrastructure Summary

**One-liner:** Created StatType enum (10 entries), StatCalculator class with weighted-average crit formula, and populated stat_types on all 24 affix definitions without changing any existing item behavior.

## Objective

Establish the unified calculation infrastructure (StatType enum, StatCalculator class, stat_types property) that Plan 02 will wire into all item types. This plan created all new code and data without modifying existing calculation paths -- the game continues to work identically using the old calculation code in weapon.gd, ring.gd, armor.gd, helmet.gd, and boots.gd.

## Tasks Completed

### Task 1: Add StatType enum to tag.gd and stat_types property to Affix

**Commit:** d0745dc

**Files modified:**
- autoloads/tag.gd
- models/affixes/affix.gd
- autoloads/item_affixes.gd

**What was done:**
- Added StatType enum to tag.gd with 10 entries: FLAT_DAMAGE, INCREASED_DAMAGE, INCREASED_SPEED, CRIT_CHANCE, CRIT_DAMAGE, FLAT_ARMOR, FLAT_ENERGY_SHIELD, FLAT_HEALTH, FLAT_MANA, MOVEMENT_SPEED
- Added stat_types property to Affix class with default []
- Updated Affix._init() to accept p_stat_types parameter as last argument (maintains backward compatibility)
- Populated all 24 affix definitions in item_affixes.gd with stat_types:
  - 9 affixes with specific StatType values (Physical Damage, %Physical Damage, Attack Speed, Life, Armor, Critical Strike Chance, Critical Strike Damage)
  - 15 affixes with empty arrays (legitimately not used in stat calculations - exist for filtering only)
- Updated Affixes.from_affix() to copy stat_types to new instances
- Existing AffixTag string constants (PHYSICAL, ELEMENTAL, WEAPON, DEFENSE, etc.) remain unchanged

### Task 2: Create StatCalculator class with unified DPS and defense calculations

**Commit:** 34349a4

**Files created:**
- models/stats/stat_calculator.gd

**What was done:**
- Created StatCalculator RefCounted utility class with static methods
- Implemented calculate_dps() with correct order of operations: base → flat damage → additive damage% → speed → crit multiplier
- Implemented calculate_flat_stat() for defense item stat aggregation
- Used weighted-average crit formula: 1 + (crit_chance/100) * (crit_damage/100 - 1) for mathematically correct expected value calculation
- Added _calculate_crit_multiplier() private helper method with test case documentation
- No print statements (pure calculation utility with no side effects)

## Verification Results

**Verification method:** Code review and syntax validation (Godot not accessible from command line)

**Results:**
- All modified files pass gdformat validation
- StatType enum has 10 entries in tag.gd
- StatCalculator has calculate_dps() and calculate_flat_stat() methods
- All 24 affix definitions have stat_types populated (9 with values, 15 with empty arrays)
- Affixes.from_affix() copies stat_types to new instances
- Existing AffixTag string constants remain unchanged in tag.gd

**No behavioral changes:** The game continues to work identically because no existing calculation paths were modified. The old calculation code in weapon.gd, ring.gd, armor.gd, helmet.gd, and boots.gd remains untouched and in use.

## Deviations from Plan

None - plan executed exactly as written.

## Key Decisions

1. **StatType enum minimal scope:** Only 10 entries (FLAT_DAMAGE, INCREASED_DAMAGE, INCREASED_SPEED, CRIT_CHANCE, CRIT_DAMAGE, FLAT_ARMOR, FLAT_ENERGY_SHIELD, FLAT_HEALTH, FLAT_MANA, MOVEMENT_SPEED). No MORE_DAMAGE, INCREASED_ARMOR, or elemental damage StatTypes -- deferred per research findings.

2. **Backward compatibility in Affix._init():** Placed p_stat_types as the last parameter to maintain compatibility with existing Implicit.new() calls in basic_*.gd and light_sword.gd files that don't pass stat_types.

3. **Untyped Array parameter in StatCalculator:** Used `affixes: Array` instead of `Array[Affix]` because GDScript array concatenation sometimes returns untyped Array. Type safety maintained via loop variable `affix: Affix`.

4. **Weighted-average crit formula:** Implemented mathematically correct expected-value calculation: `1 + (c/100) * (d/100 - 1)` instead of the incorrect formula in existing weapon.gd code. The old formula in weapon.gd applies crit twice (once to damage, once via weighted average), which will be fixed when Plan 02 wires in StatCalculator.

5. **Empty stat_types are legitimate:** 15 affixes have empty stat_types arrays because they exist for affix filtering (can roll on items) but are not used in stat calculations. This is correct behavior, not missing data.

## Impact Assessment

**Code changes:**
- 1 file created (stat_calculator.gd)
- 3 files modified (tag.gd, affix.gd, item_affixes.gd)
- 81 lines added/modified in affixes and tag infrastructure

**Runtime impact:**
- None - no existing behavior changed
- New infrastructure exists but is not yet used by any items
- Old calculation paths in weapon.gd, ring.gd, armor.gd, helmet.gd, boots.gd remain active

**Next steps:**
- Plan 02 will wire StatCalculator into all item types (weapon, ring, armor, helmet, boots)
- Plan 02 will replace old calculation code with StatCalculator.calculate_dps() and StatCalculator.calculate_flat_stat() calls
- Plan 02 will fix the double-crit bug in weapon.gd by using the correct weighted-average formula

## Self-Check: PASSED

**Files created verification:**
```
FOUND: models/stats/stat_calculator.gd
```

**Commits verification:**
```
FOUND: d0745dc (Task 1)
FOUND: 34349a4 (Task 2)
```

All claimed files and commits exist and contain expected content.
