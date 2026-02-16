---
phase: 09-defensive-prefix-foundation
plan: 03
subsystem: currencies-items
tags: [gap-closure, uat-fix, currency-design, stat-architecture]
dependency_graph:
  requires: [09-01, 09-02]
  provides: [balanced-mod-distribution, implicit-stat-flow]
  affects: [runic-hammer, tack-hammer, loot-table, armor-items, weapon-items, ring-items]
tech_stack:
  added: []
  patterns: [weighted-random, implicit-stat-types]
key_files:
  created: []
  modified:
    - models/currencies/runic_hammer.gd
    - models/loot/loot_table.gd
    - models/items/basic_armor.gd
    - models/items/basic_helmet.gd
    - models/items/basic_boots.gd
    - models/items/light_sword.gd
    - models/items/basic_ring.gd
decisions:
  - Weighted 70/30 distribution for Magic mod count makes TackHammer meaningful on majority of items
  - Zero hardcoded base stats forces all base values through implicit->StatCalculator path
  - Consistency fix: added stat_types to weapon and ring implicits for uniform architecture
metrics:
  duration: 115s
  completed: 2026-02-16
---

# Phase 09 Plan 03: Gap Closure Summary

**One-liner:** Fixed Runic Hammer mod count bias (70% single-mod) and removed hardcoded armor base stats to make implicits the sole source of base values flowing through StatCalculator.

## Overview

This plan addressed two critical UAT gaps discovered during v1.1 playtesting:

1. **Runic Hammer mod count distribution** - Previously 50/50 for 1-2 mods, making TackHammer useless 50% of the time. Now biased 70% toward 1 mod, giving TackHammer meaningful utility on majority of items.

2. **Armor base stat architecture** - Armor items had dual stat sources (hardcoded `original_base_armor` + implicit with empty `stat_types`). User saw 46 armor when expecting ~25 because implicit value wasn't flowing through StatCalculator. Fixed by zeroing hardcoded bases and adding stat_types to all implicits.

## Tasks Completed

### Task 1: Bias Runic Hammer and loot table Magic mod count toward 1 mod

**Files:** `models/currencies/runic_hammer.gd`, `models/loot/loot_table.gd`

**Changes:**
- Replaced `randi_range(1, 2)` with weighted roll: `1 if randf() < 0.7 else 2`
- Applied to both RunicHammer currency (line 23) and Magic item drops in LootTable (line 210)
- Rare items unchanged (still use `randi_range(4, 6)`)
- TackHammer unchanged (already adds exactly 1 mod with proper slot checking)

**Result:** Runic Hammer produces 1-mod Magic items ~70% of the time and 2-mod items ~30%. TackHammer can now add the second mod on ~70% of Runic-crafted items, making it a meaningful progression step.

**Commit:** c2851a1

---

### Task 2: Remove hardcoded base stats from armor items and add stat_types to implicits

**Files:** `models/items/basic_armor.gd`, `models/items/basic_helmet.gd`, `models/items/basic_boots.gd`, `models/items/light_sword.gd`, `models/items/basic_ring.gd`

**Changes:**

**BasicArmor:**
- `original_base_armor`: 15 → 0
- `base_armor`: 15 → 0
- Implicit: Added `[Tag.StatType.FLAT_ARMOR]` as 6th argument
- Result: Base armor of 3-8 comes entirely from implicit at tier 8

**BasicHelmet:**
- `original_base_armor`: 10 → 0
- `base_armor`: 10 → 0
- Implicit: Added `[Tag.StatType.FLAT_ARMOR]` as 6th argument
- Result: Base armor of 2-5 comes entirely from implicit at tier 8

**BasicBoots:**
- `original_base_armor`: 8 → 0
- `base_armor`: 8 → 0
- Implicit: Added `[Tag.StatType.MOVEMENT_SPEED]` as 6th argument
- Result: Base armor of 0 (boots get armor only from affixes), movement speed from implicit

**LightSword (consistency fix):**
- Implicit: Added `[Tag.StatType.INCREASED_SPEED]` as 6th argument
- Result: Attack speed implicit now flows through StatCalculator.calculate_dps()

**BasicRing (consistency fix):**
- Implicit: Added `[Tag.StatType.CRIT_CHANCE]` as 6th argument
- Result: Crit chance implicit now flows through calculate_dps()

**Calculation logic unchanged:**
- No modifications to armor.gd, helmet.gd, boots.gd, weapon.gd, or stat_calculator.gd
- Existing `update_value()` methods already compute: `original_base_X + calculate_flat_stat(all_affixes, FLAT_X)`
- With `original_base_X` now 0, flat total comes entirely from implicits and affixes
- Percentage modifiers apply on top as before

**Result:** Armor stat display math now makes intuitive sense. Example: BasicArmor with implicit=20 and %Armor prefix=27 shows 25 armor (int(20 * 1.27)), not 46.

**Commit:** 94d0482

---

## Deviations from Plan

None - plan executed exactly as written.

## Verification

**Task 1 Verification:**
- Confirmed runic_hammer.gd line 23 uses `randf() < 0.7` pattern
- Confirmed loot_table.gd line 210 (Magic branch) uses same pattern
- Confirmed loot_table.gd line 232 (Rare branch) still uses `randi_range(4, 6)`
- Confirmed tack_hammer.gd unchanged

**Task 2 Verification:**
- Confirmed all 3 armor items have `original_base_armor=0` and `base_armor=0`
- Confirmed all 3 armor items have proper `stat_types` in implicits
- Confirmed LightSword and BasicRing implicits have proper `stat_types`
- Confirmed no changes to calculation logic files (armor.gd, helmet.gd, boots.gd, weapon.gd, stat_calculator.gd)

**Stat calculation trace (BasicArmor with implicit=20, %Armor=27):**
1. `flat_armor = 0 + 20` (from implicit via FLAT_ARMOR stat_type)
2. `base_armor = int(20 * 1.27) = int(25.4) = 25`
3. User expectation met: implicit 20 + 27% = ~25

## Self-Check

Verifying all claimed artifacts exist:

**Files modified:**
- models/currencies/runic_hammer.gd: Modified
- models/loot/loot_table.gd: Modified
- models/items/basic_armor.gd: Modified
- models/items/basic_helmet.gd: Modified
- models/items/basic_boots.gd: Modified
- models/items/light_sword.gd: Modified
- models/items/basic_ring.gd: Modified

**Commits:**
- c2851a1: Exists
- 94d0482: Exists

## Self-Check: PASSED

All files and commits verified.

## Impact

**User-facing:**
- TackHammer now useful on ~70% of Runic Hammer'd items (was 50%)
- Armor stat display now shows intuitive math (implicit + % = expected total)
- No more confusing "46 armor when expecting 25" scenarios

**Technical:**
- Mod count distribution pattern reusable for future currencies
- Implicit stat_types architecture now consistent across all item types
- Base stat calculation flow simplified (single source of truth)

**Next Steps:**
- Playtest to validate currency feel with new distribution
- Monitor for any edge cases in stat calculation
- Consider similar implicit architecture for future item types

## Success Criteria Met

- [x] Runic Hammer mod_count uses weighted 70/30 roll (not randi_range)
- [x] LootTable Magic spawn uses same weighted 70/30 roll
- [x] All 3 basic armor items have original_base_armor=0 and implicit with stat_types
- [x] LightSword and BasicRing implicits have proper stat_types
- [x] No calculation logic files (armor.gd, helmet.gd, boots.gd, weapon.gd, stat_calculator.gd) were modified
- [x] Both UAT gaps resolved
