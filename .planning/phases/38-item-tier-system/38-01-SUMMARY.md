---
phase: 38-item-tier-system
plan: 01
subsystem: gameplay
tags: [item-tier, loot-table, affixes, crafting, prestige, save-load, gdscript]

# Dependency graph
requires:
  - phase: 37-affix-tier-expansion
    provides: All 27 affixes with Vector2i(1, 32) tier_range; SAVE_VERSION 4
  - phase: 35-prestige-foundation
    provides: GameState.max_item_tier_unlocked, GameState.prestige_level, PrestigeManager.ITEM_TIERS_BY_PRESTIGE
provides:
  - Area-weighted item tier rolling via LootTable.roll_item_tier()
  - Affix tier floor constraint at crafting time via Affixes.from_affix(template, floor)
  - Item._get_affix_tier_floor() computes (tier-1)*4+1 floor for add_prefix/add_suffix
  - Tier restoration in create_from_dict() for save/load round-trip
  - Conditional tier label "T{n}" in forge stats panel at P1+
affects:
  - 39-tag-currencies
  - 40-prestige-balance
  - 41-verification

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Bell-curve weighted tier selection: Gaussian weights centered on biome-aligned home areas per tier"
    - "Affix floor constraint: applied at construction time in from_affix(), not stored on item — template tier_range never mutated"
    - "Prestige gate pattern: GameState.prestige_level >= 1 check for post-prestige UI features"

key-files:
  created: []
  modified:
    - models/loot/loot_table.gd
    - autoloads/item_affixes.gd
    - models/items/item.gd
    - scenes/gameplay_view.gd
    - scenes/forge_view.gd

key-decisions:
  - "Affix tier floor applied at construction in from_affix(), not stored on item — consistent with prior decision in STATE.md"
  - "TIER_WEIGHT_SIGMA=25.0 aligns tier home centers to biome midpoints (T8=12, T7=37, T6=62, T5=87)"
  - "0.01 weight floor prevents any tier from having 0 chance even far from its home area"
  - "reroll_affix() intentionally untouched — Tuning Hammer rerolls within original affix tier bounds"
  - "Tier display gate is prestige_level >= 1 (not max_item_tier_unlocked < 8) — display tied to having prestiged"
  - "No SAVE_VERSION bump needed — item.tier already serialized in to_dict(); create_from_dict default 8 is backward-compatible"

patterns-established:
  - "Item tier floor formula: (tier-1)*4+1 — T8=29, T7=25, T6=21, T5=17, T4=13, T3=9, T2=5, T1=1"
  - "LootTable static helpers: pure functions with no state — area_level and max_tier_unlocked passed as params"

requirements-completed: [TIER-01, TIER-02, TIER-03]

# Metrics
duration: 8min
completed: 2026-03-01
---

# Phase 38 Plan 01: Item Tier System Summary

**Area-weighted item tier rolling (Gaussian bell curve), affix tier floor constraint at crafting time via from_affix(floor), tier save/load restoration, and conditional forge tier label at P1+**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-03-01T13:45:01Z
- **Completed:** 2026-03-01T13:53:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- LootTable.roll_item_tier() implements Gaussian-weighted tier selection; P0 fast-path always returns 8
- Affixes.from_affix() extended with optional affix_tier_floor param — clamps effective_range.x without mutating template
- Item._get_affix_tier_floor() computes floor from item tier; wired into add_prefix/add_suffix
- create_from_dict() restores item.tier from save data with default 8 for backward compat
- Forge stats panel shows " — T{n}" label after first prestige (prestige_level >= 1 gate)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add roll_item_tier(), wire affix tier floor, assign tier at drop, restore on load** - `14b7c41` (feat)
2. **Task 2: Add conditional tier label to forge stats panel** - `6157471` (feat)

## Files Created/Modified

- `models/loot/loot_table.gd` - Added TIER_WEIGHT_SIGMA const, _tier_home_center(), roll_item_tier() static functions
- `autoloads/item_affixes.gd` - Extended from_affix() with optional affix_tier_floor param; uses effective_range to avoid mutating template
- `models/items/item.gd` - Added _get_affix_tier_floor() helper; wired floor into add_prefix/add_suffix; restored tier in create_from_dict()
- `scenes/gameplay_view.gd` - get_random_item_base() assigns rolled tier via LootTable.roll_item_tier()
- `scenes/forge_view.gd` - get_item_stats_text() appends tier label at P1+

## Decisions Made

- Affix tier floor applied at construction time in from_affix(), consistent with prior architectural decision (not stored on item)
- Gaussian sigma=25.0 chosen to align tier home areas with biome midpoints; 0.01 weight floor ensures all unlocked tiers can drop anywhere
- reroll_affix() intentionally left untouched — Tuning Hammer rerolls within the affix's stored min_value/max_value bounds, unaffected by item tier
- Tier label gates on prestige_level >= 1 (not max_item_tier_unlocked) — per locked decision: display is tied to having prestiged
- No SAVE_VERSION bump — item.tier was already serialized in to_dict() since v1; default 8 on restore is safe for all existing saves

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Item tier system complete — every dropped item carries a tier value gating affix quality
- Phase 39 (Tag Currencies) can proceed; item tier does not interact with tag currency drop rates
- Phase 40 (Prestige Balance) has data needed to tune tier probability curves if bell-curve sigma needs adjustment
- Verification: At P0 all drops are tier 8; at P1+ higher areas produce better tiers more frequently; forge stats show tier label only after first prestige

## Self-Check: PASSED

- models/loot/loot_table.gd: FOUND
- autoloads/item_affixes.gd: FOUND
- models/items/item.gd: FOUND
- scenes/gameplay_view.gd: FOUND
- scenes/forge_view.gd: FOUND
- .planning/phases/38-item-tier-system/38-01-SUMMARY.md: FOUND
- Commit 14b7c41: FOUND
- Commit 6157471: FOUND

---
*Phase: 38-item-tier-system*
*Completed: 2026-03-01*
