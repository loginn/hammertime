---
phase: 15-pack-based-combat-loop
plan: 02
subsystem: gameplay-loop
tags: [combat-integration, gameplay-view, pack-combat, signal-wiring, scene-update]

dependency_graph:
  requires:
    - phase: 15-pack-based-combat-loop
      provides: CombatEngine with state machine and dual attack timers
  provides:
    - CombatEngine-driven gameplay_view replacing timer-based clearing
    - Pack-by-pack combat display (pack name, element, HP, progress)
    - GameEvents signal connections for all 7 combat events
    - Temporary map completion drops (items + currency) until Phase 16
  affects: [drop-system, combat-ui, phase-16, phase-17]

tech_stack:
  added: []
  patterns: [signal-driven-display-updates, thin-controller-pattern]

key_files:
  created: []
  modified:
    - scenes/gameplay_view.gd
    - scenes/gameplay_view.tscn

key_decisions:
  - "Kept refresh_clearing_speed() as thin wrapper (just update_display) for main_view compatibility"
  - "Item and currency drops fire on map completion temporarily — Phase 16 will split to per-pack currency"
  - "get_random_item_base() takes level parameter now for correct rarity scaling at completed level"
  - "BiomeConfig.get_biome_for_level() used for area name instead of manual threshold checks"

patterns_established:
  - "Pattern 1: gameplay_view as thin controller — delegates combat to CombatEngine, only handles display"
  - "Pattern 2: All display updates flow through GameEvents signal handlers calling update_display()"
  - "Pattern 3: Existing drop systems preserved via GameEvents.area_cleared.emit on map completion"

duration: 4min
completed: 2026-02-16
---

# Phase 15 Plan 02: Wire CombatEngine into Gameplay View Summary

**Gameplay view replaced timer-based clearing with CombatEngine-driven pack combat showing pack name, element, HP, and progress (X of Y)**

## Performance

- **Duration:** 4 min
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Replaced entire timer-based clearing system with CombatEngine delegation
- Removed ClearingTimer from scene, added CombatEngine as child node
- Connected all 7 GameEvents combat signals for display updates
- Display shows current pack name, element type, HP, and progress (Pack X of Y)
- Hero HP and ES visible during combat
- Start/Stop button toggles combat via CombatEngine
- Temporary item and currency drops on map completion preserved
- GameEvents.area_cleared still emitted for existing system compatibility
- 304 lines of old timer code removed, replaced with 106 lines of clean delegation

## Task Commits

1. **Task 1: Replace timer-based clearing with CombatEngine in gameplay_view** - `f3fb1f3` (feat)
2. **Task 2: Verify combat loop integration end-to-end** - verified inline (all grep checks passed)

## Files Created/Modified
- `scenes/gameplay_view.gd` - Complete rewrite: CombatEngine delegation, signal handlers, pack combat display
- `scenes/gameplay_view.tscn` - Removed ClearingTimer, added CombatEngine node with script reference

## Decisions Made
- Kept refresh_clearing_speed() method name for backward compatibility with main_view.gd connection — now just calls update_display()
- Temporary drops on map completion (items + currency) preserved until Phase 16 splits the drop system
- get_random_item_base() now takes area level parameter for correct rarity scaling
- Area name derived from BiomeConfig.get_biome_for_level() instead of manual threshold checks — single source of truth

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All 5 phase success criteria met:
  1. Hero auto-attacks current pack, pack attacks back each combat tick
  2. Pack HP 0 -> hero moves to next pack
  3. Hero HP 0 -> combat stops, hero marked dead
  4. Hero revives and can start new map after death
  5. All packs cleared -> hero advances to next map
- Combat loop ready for Phase 16 drop system split
- Display ready for Phase 17 UI and combat feedback enhancements

---
*Phase: 15-pack-based-combat-loop*
*Completed: 2026-02-16*
