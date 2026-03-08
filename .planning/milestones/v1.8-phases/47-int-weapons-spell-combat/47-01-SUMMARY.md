---
phase: 47-int-weapons-spell-combat
plan: 01
subsystem: items, combat
tags: [gdscript, weapons, spell-damage, int-archetype, stat-calculator]

requires:
  - phase: 46-spell-damage-channel
    provides: spell damage pipeline (StatCalculator.calculate_spell_damage_range, Hero spell DPS)
provides:
  - 3 INT weapon bases (Wand, LightningRod, Sceptre) with 8 tiers each
  - Per-element spell damage types (spell_fire, spell_lightning)
  - Multi-element spell damage pipeline in StatCalculator and Hero
affects: [47-int-weapons-spell-combat, affix-pool, combat-engine]

tech-stack:
  added: []
  patterns:
    - "Per-element spell damage routing via stat_type (not tags) to avoid collision with attack affixes"
    - "INT weapon pattern: small physical attack stats + primary spell damage channel"

key-files:
  created:
    - models/items/wand.gd
    - models/items/lightning_rod.gd
    - models/items/sceptre.gd
  modified:
    - autoloads/tag.gd
    - models/stats/stat_calculator.gd
    - models/hero.gd
    - models/items/item.gd
    - scenes/gameplay_view.gd

key-decisions:
  - "Spell damage element routing uses stat_types (FLAT_SPELL_FIRE_DAMAGE, FLAT_SPELL_LIGHTNING_DAMAGE) not tags, preventing collision with attack flat damage affixes that share element tags"

patterns-established:
  - "INT weapon base pattern: valid_tags=[INT, SPELL, ELEMENTAL, ENERGY_SHIELD, WEAPON], small physical attack stats, primary spell damage channel with cast_speed"

requirements-completed: [BASE-04]

duration: 3min
completed: 2026-03-07
---

# Phase 47 Plan 01: INT Weapon Bases & Spell Stat Types Summary

**3 INT weapon bases (Wand/LightningRod/Sceptre) with per-element spell damage routing via FLAT_SPELL_FIRE_DAMAGE and FLAT_SPELL_LIGHTNING_DAMAGE stat types**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-07T18:32:56Z
- **Completed:** 2026-03-07T18:35:32Z
- **Tasks:** 7
- **Files modified:** 8

## Accomplishments
- Added FLAT_SPELL_LIGHTNING_DAMAGE and FLAT_SPELL_FIRE_DAMAGE stat types to the StatType enum
- Extended StatCalculator.calculate_spell_damage_range() to return three spell elements (spell, spell_fire, spell_lightning) with stat_type-based routing
- Extended Hero spell_damage_ranges to track all three spell elements, with calculate_spell_dps() summing across all
- Created Wand (fast caster, 1.2 cast speed, generic spell implicit), LightningRod (medium 1.0, lightning implicit), Sceptre (slow 0.8, fire implicit)
- Registered all 3 INT weapons in ITEM_TYPE_STRINGS, create_from_dict(), and the gameplay_view drop pool

## Task Commits

Each task was committed atomically:

1. **Task 1: Add spell element stat types to tag.gd** - `178a65d` (feat)
2. **Task 2: Extend StatCalculator for per-element spell damage** - `2bf61a2` (feat)
3. **Task 3: Extend Hero spell damage tracking for multiple elements** - `99b0fe7` (feat)
4. **Task 4: Create Wand weapon class** - `904bd3d` (feat)
5. **Task 5: Create LightningRod weapon class** - `533f7f4` (feat)
6. **Task 6: Create Sceptre weapon class** - `1220764` (feat)
7. **Task 7: Register INT weapons in item system and drop pool** - `0b62730` (feat)

## Files Created/Modified
- `autoloads/tag.gd` - Added FLAT_SPELL_LIGHTNING_DAMAGE, FLAT_SPELL_FIRE_DAMAGE to StatType enum
- `models/stats/stat_calculator.gd` - Multi-element spell damage calculation with stat_type routing
- `models/hero.gd` - Multi-element spell_damage_ranges and summing spell DPS across elements
- `models/items/wand.gd` - Wand INT weapon (fast caster, generic spell implicit)
- `models/items/lightning_rod.gd` - LightningRod INT weapon (medium caster, lightning spell implicit)
- `models/items/sceptre.gd` - Sceptre INT weapon (slow caster, fire spell implicit)
- `models/items/item.gd` - Registry entries for all 3 INT weapons (21 total types)
- `scenes/gameplay_view.gd` - Added INT weapons to drop pool (9 weapon bases)

## Decisions Made
- Spell damage element routing uses stat_types rather than tags to prevent collision with attack flat damage affixes that share element tags (e.g., a fire attack affix with Tag.FIRE would incorrectly route to spell_fire if we used tag-based routing)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- INT weapon bases complete with per-element spell damage pipeline
- Ready for Plan 02 (INT spell affix pool and crafting integration)

---
*Phase: 47-int-weapons-spell-combat*
*Completed: 2026-03-07*
