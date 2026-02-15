---
phase: 03-unified-calculations
plan: 02
subsystem: "items/stats"
tags: ["refactor", "calculations", "dps", "defense", "architecture"]

dependency_graph:
  requires:
    - "03-01 (StatCalculator infrastructure)"
  provides:
    - "Unified DPS calculation via StatCalculator"
    - "Unified defense stat aggregation via StatCalculator"
    - "Single source of truth for all stat calculations"
    - "Corrected crit formula in ring items"
  affects:
    - "models/items/weapon.gd"
    - "models/items/ring.gd"
    - "models/items/armor.gd"
    - "models/items/helmet.gd"
    - "models/items/boots.gd"
    - "models/items/item.gd"

tech_stack:
  added: []
  patterns:
    - "Delegation pattern: All item types delegate to StatCalculator"
    - "Template method: Item.update_value() defines contract, subclasses implement"

key_files:
  created: []
  modified:
    - path: "models/items/weapon.gd"
      change: "Removed compute_dps() method (76 lines), replaced with StatCalculator.calculate_dps() call in update_value()"
      impact: "Weapon DPS now calculated using correct crit formula, no debug prints"
    - path: "models/items/ring.gd"
      change: "Removed compute_dps() method (23 lines), replaced with StatCalculator.calculate_dps() call in update_value()"
      impact: "Ring DPS now uses correct weighted-average crit formula (1+c*(d-1) instead of 1+c*d)"
    - path: "models/items/light_sword.gd"
      change: "Changed _init() to call update_value() instead of compute_dps()"
      impact: "LightSword now consistent with other concrete item classes"
    - path: "models/items/armor.gd"
      change: "Replaced manual affix loop with StatCalculator.calculate_flat_stat() calls"
      impact: "Armor stat calculation delegated to StatCalculator for FLAT_ARMOR, FLAT_ENERGY_SHIELD, FLAT_HEALTH"
    - path: "models/items/helmet.gd"
      change: "Replaced manual affix loop with StatCalculator.calculate_flat_stat() calls"
      impact: "Helmet stat calculation delegated to StatCalculator for FLAT_ARMOR, FLAT_ENERGY_SHIELD, FLAT_MANA"
    - path: "models/items/boots.gd"
      change: "Replaced manual affix loop with StatCalculator.calculate_flat_stat() calls"
      impact: "Boots stat calculation delegated to StatCalculator for FLAT_ARMOR, MOVEMENT_SPEED, FLAT_ENERGY_SHIELD"
    - path: "models/items/item.gd"
      change: "Added base update_value() method with documentation comment"
      impact: "Explicit contract for update_value() pattern across all item types"

decisions:
  - what: "Remove compute_dps() from weapon.gd and ring.gd entirely"
    why: "Single source of truth principle - only StatCalculator should contain calculation logic"
    impact: "96 lines of duplicate code removed, crit formula bug eliminated"
  - what: "Update light_sword.gd to call update_value() instead of compute_dps()"
    why: "Consistency - all other concrete item classes (BasicRing, BasicArmor, etc.) call update_value() in _init()"
    impact: "LightSword now follows same initialization pattern as other items"
  - what: "Add base update_value() method to Item.gd"
    why: "Make the contract explicit - all item subclasses implement update_value() to recalculate stats"
    impact: "Better documentation, clearer API for future item types"

metrics:
  duration: "11 seconds"
  completed: "2026-02-15T07:01:39Z"
  tasks_completed: 3
  commits: 2
  files_modified: 7
  lines_removed: 169
  lines_added: 65
  net_change: -104
---

# Phase 03 Plan 02: Unified Item Calculations Summary

Refactored all five item types to delegate stat calculation to StatCalculator, eliminating 96 lines of duplicate DPS logic and fixing the ring crit formula bug.

## What Was Built

**Single Source of Truth for All Item Calculations:**
- Weapon and Ring delegate DPS calculation to `StatCalculator.calculate_dps()`
- Armor, Helmet, and Boots delegate defense stat aggregation to `StatCalculator.calculate_flat_stat()`
- Removed `compute_dps()` method from weapon.gd (76 lines) and ring.gd (23 lines)
- Replaced manual affix loops in armor.gd, helmet.gd, boots.gd with StatCalculator calls
- Added base `update_value()` method to item.gd to document the contract
- Fixed ring crit formula bug (was `1 + c*d`, now correct `1 + c*(d-1)`)

**All items now follow consistent pattern:**
```gdscript
func update_value() -> void:
    var all_affixes := self.prefixes + self.suffixes
    all_affixes.append(self.implicit)
    # Delegate to StatCalculator
    self.dps = StatCalculator.calculate_dps(...)
    # OR
    self.base_armor = ... + StatCalculator.calculate_flat_stat(...)
```

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Refactor weapon.gd and ring.gd to use StatCalculator for DPS | 45dbd9a | weapon.gd, ring.gd, light_sword.gd |
| 2 | Refactor defense items to use StatCalculator for flat stat aggregation | 091f4bb | armor.gd, helmet.gd, boots.gd, item.gd |
| 3 | Verify unified calculation system works in-game | N/A | User verification checkpoint (approved) |

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

**Task 1 Verification:**
- `grep -r "compute_dps" /home/travelboi/Programming/hammertime/models/` returned no results
- Game launched without errors using StatCalculator for all DPS calculations

**Task 2 Verification:**
- `grep -r "StatCalculator" /home/travelboi/Programming/hammertime/models/items/` showed all 5 item files using StatCalculator
- `grep -r "Tag.PHYSICAL in affix|Tag.ARMOR in affix" /home/travelboi/Programming/hammertime/models/items/` returned no results (old tag loops removed)
- Game launched without errors

**Task 3 Verification:**
- User tested crafting, item stat updates, equipment, and gameplay
- All item types correctly recalculate stats when affixes are added/rerolled
- Ring DPS values changed slightly due to corrected crit formula (expected behavior)
- No new errors in Godot Output panel (only expected unused GameEvents signal warnings from Phase 2)

## Architecture Impact

**Before:**
- Weapon.gd had compute_dps() with crit formula `phys_crit_mult = 1 + crit_chance * crit_damage`
- Ring.gd had compute_dps() with crit formula `phys_crit_mult = 1 + crit_chance * crit_damage`
- Defense items had manual affix loops checking for specific tags
- 96 lines of calculation logic duplicated across item files

**After:**
- StatCalculator is the single source of truth for all calculations
- Weapon and Ring use `StatCalculator.calculate_dps()` with correct weighted-average crit formula
- Defense items use `StatCalculator.calculate_flat_stat()` for clean stat aggregation
- All items implement consistent `update_value()` pattern
- 96 lines of duplicate code eliminated

**Key Improvement:**
Ring DPS now uses correct crit formula. For a BasicRing with 5% crit chance and 150% crit damage:
- Old formula: `1 + 0.05 * 1.5 = 1.075` (7.5% DPS increase)
- Correct formula: `1 + 0.05 * (1.5 - 1) = 1.025` (2.5% DPS increase)

The weighted average formula `1 + c*(d-1)` correctly represents: 95% of attacks deal 100% damage, 5% deal 150% damage = 102.5% average.

## Requirements Satisfied

All four CALC requirements from Phase 03 Research are now complete:

- **CALC-01:** Single unified DPS calculation in StatCalculator (not weapon.gd or ring.gd) ✓
- **CALC-02:** AffixTags (string constants) separated from StatType (enum) in tag.gd ✓ (completed in 03-01)
- **CALC-03:** All item types implement update_value() delegating to StatCalculator ✓
- **CALC-04:** Crit formula uses correct weighted average `1 + c*(d-1)`, not `1 + c*d` ✓

## Testing Notes

Game behavior is identical to before (except for corrected ring DPS values):
- Crafting View: Adding prefixes/suffixes/rerolling implicts updates stats correctly
- Item Display: All stats shown accurately for weapons, rings, and defense items
- Hero View: Finished items appear and can be equipped
- Gameplay View: Loot drops work, new items have correct stats
- No new errors or warnings (existing unused GameEvents warnings expected)

## Next Steps

Phase 03 complete. All calculation logic unified under StatCalculator.

Next: Phase 04 - Signal Architecture (connect GameEvents signals to UI updates, wire hero stat changes to view refreshes)

## Self-Check: PASSED

**Commits verified:**
- 45dbd9a exists: `git log --oneline --all | grep 45dbd9a` ✓
- 091f4bb exists: `git log --oneline --all | grep 091f4bb` ✓

**Files verified:**
- models/items/weapon.gd modified ✓
- models/items/ring.gd modified ✓
- models/items/light_sword.gd modified ✓
- models/items/armor.gd modified ✓
- models/items/helmet.gd modified ✓
- models/items/boots.gd modified ✓
- models/items/item.gd modified ✓

**Code patterns verified:**
- `grep -r "compute_dps" models/` returns no results ✓
- `grep -r "StatCalculator" models/items/` shows weapon.gd, ring.gd, armor.gd, helmet.gd, boots.gd ✓
- No old tag-based calculation loops remain ✓
