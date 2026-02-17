---
phase: 16-drop-system-split
plan: 02
subsystem: loot-system
tags: [item-drops, map-completion, death-penalty, drop-split, signal-wiring]

dependency_graph:
  requires:
    - phase: 16-drop-system-split
      provides: Per-pack currency drops via LootTable.roll_pack_currency_drop in CombatEngine
  provides:
    - LootTable.get_map_item_count() for 1-3 area-scaled item drops
    - GameEvents.items_dropped signal for map completion item drops
    - Signal-driven item creation in gameplay_view via _on_items_dropped
    - Complete removal of old per-area-clear drop code from gameplay_view
    - Death penalty enforced by architecture (no items on death path)
  affects: [drop-system, phase-17, gameplay-loop, crafting-view]

tech_stack:
  added: []
  patterns: [signal-driven-drops, architecture-enforced-penalty]

key_files:
  created: []
  modified:
    - models/loot/loot_table.gd
    - models/combat/combat_engine.gd
    - scenes/gameplay_view.gd
    - autoloads/game_events.gd

key_decisions:
  - "Item count 1-3 with log interpolation: 99% for 1 at area 1, 60% for 2 at area 300"
  - "items_dropped emitted BEFORE area_level increment so receivers get correct completed level"
  - "Death penalty enforced by architecture — _on_hero_died never calls items_dropped"
  - "Old get_item_drop_count and roll_currency_drops marked DEPRECATED, not deleted"
  - "gameplay_view._on_map_completed stripped to area_cleared + display only"
  - "Per-pack currency forwarded to crafting_view via _on_currency_dropped -> currencies_found"

patterns_established:
  - "Pattern 1: CombatEngine emits drop signals, gameplay_view handles item creation — separation of concerns"
  - "Pattern 2: Death penalty by architecture (code path exclusion) not by flag checking"
  - "Pattern 3: Deprecation comments on replaced methods for backward compatibility"

duration: 4min
completed: 2026-02-17
---

# Phase 16 Plan 02: Map Completion Item Drops + Death Penalty Summary

**Map completion drops 1-3 items via signal, old per-clear drops removed, death penalty enforced by architecture**

## Performance

- **Duration:** 4 min
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- LootTable.get_map_item_count() returns 1-3 items with logarithmic area scaling
- CombatEngine._on_map_completed() emits items_dropped signal (not on death)
- gameplay_view._on_items_dropped creates items using existing get_random_item_base
- gameplay_view._on_currency_dropped forwards per-pack currency to crafting_view
- Old per-area-clear drop code completely removed from gameplay_view._on_map_completed
- Old LootTable methods marked DEPRECATED for drop_simulator compatibility
- Death penalty enforced: hero_died path never emits items_dropped

## Task Commits

1. **Task 1: Add get_map_item_count() and items_dropped signal** - `60741ec` (feat)
2. **Task 2: Wire item drops, remove old code, enforce death penalty** - `cd9e351` (feat)

## Files Created/Modified
- `models/loot/loot_table.gd` - Added get_map_item_count(), deprecated old methods
- `models/combat/combat_engine.gd` - Added items_dropped emission in _on_map_completed, death comments
- `scenes/gameplay_view.gd` - Added _on_items_dropped/_on_currency_dropped handlers, removed old drop code
- `autoloads/game_events.gd` - Added items_dropped signal

## Decisions Made
- Used logarithmic progress curve (log(1 + area/50)) for smooth item count scaling
- Emitted items_dropped BEFORE incrementing area_level so the signal carries the correct completed level
- Kept deprecated methods rather than deleting to avoid breaking drop_simulator tool
- Forwarded per-pack currency through gameplay_view's currencies_found signal to maintain crafting_view update chain

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Drop system split complete: packs drop currency, map completion drops items
- Death penalty working: currency kept, items forfeited
- All 4 phase success criteria addressed
- Ready for Phase 17: UI and Combat Feedback

---
*Phase: 16-drop-system-split*
*Completed: 2026-02-17*
