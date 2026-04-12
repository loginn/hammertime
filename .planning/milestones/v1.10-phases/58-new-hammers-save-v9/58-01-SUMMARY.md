---
phase: 58-new-hammers-save-v9
plan: 01
subsystem: crafting
tags: [gdscript, currency, crafting, alteration, regal, poe-style, integration-tests]

# Dependency graph
requires:
  - phase: 57-stash-ui
    provides: Stash UI and universal bench used during crafting
  - phase: 56-difficulty-starter-kit
    provides: Currency key renames (alteration/regal) and starter kit foundation
provides:
  - TackHammer (Alteration): clears all mods on Magic items and rerolls 1-2 new mods
  - GrandHammer (Regal): upgrades Magic to Rare by adding exactly one mod
  - Updated forge_view tooltips for alteration and regal
  - Integration test groups 48-49 covering CRFT-01 and CRFT-02 behaviors
affects: [forge_view, save-v9, requirements-CRFT-01, requirements-CRFT-02]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Alteration pattern: clear all mods, reroll 1-2 (identical distribution to RunicHammer)"
    - "Regal pattern: set rarity=RARE then add exactly one mod"

key-files:
  created: []
  modified:
    - models/currencies/tack_hammer.gd
    - models/currencies/grand_hammer.gd
    - scenes/forge_view.gd
    - tools/test/integration_test.gd

key-decisions:
  - "TackHammer (Alteration) rejects on Normal and Rare; no room-for-mods check needed since clear() always makes room"
  - "GrandHammer (Regal) rejects on Normal and Rare; adds exactly one mod after setting RARE rarity"
  - "currency_name strings updated to PoE conventions: Alteration Hammer and Regal Hammer"

patterns-established:
  - "Alteration reroll: prefixes.clear() + suffixes.clear() + add 1-2 mods with 70/30 distribution"
  - "Regal upgrade: rarity = RARE first, then add_prefix/add_suffix with random fallback"

requirements-completed: [CRFT-01, CRFT-02]

# Metrics
duration: 8min
completed: 2026-03-29
---

# Phase 58 Plan 01: New Hammers (Alteration + Regal) Summary

**Alteration Hammer rerolls all mods on Magic items (1-2 new mods, stays Magic) and Regal Hammer upgrades Magic to Rare by adding one mod — with forge_view tooltips and integration tests (groups 48-49)**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-03-29T00:39:47Z
- **Completed:** 2026-03-29T00:47:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- TackHammer (Alteration Hammer) rewritten: clears all prefixes/suffixes and rerolls 1-2 new mods with 70/30 distribution; rejected on Normal and Rare with clear error message
- GrandHammer (Regal Hammer) rewritten: upgrades Magic to Rare by setting rarity=RARE then adding exactly one mod; rejected on Normal and Rare with clear error message
- forge_view.gd tooltips updated: alteration says "Rerolls all mods on a magic item", regal says "Upgrades a magic item to rare by adding one mod"
- Integration test groups 48-49 added covering all accept/reject cases for both hammers

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite TackHammer (Alteration) and GrandHammer (Regal) + update forge_view tooltips** - `c17868b` (feat)
2. **Task 2: Integration tests for Alteration and Regal hammers (groups 48-49)** - `c3a0262` (test)

## Files Created/Modified
- `models/currencies/tack_hammer.gd` - Rewritten as Alteration Hammer: clears mods, rerolls 1-2, Magic-only gate
- `models/currencies/grand_hammer.gd` - Rewritten as Regal Hammer: sets RARE, adds one mod, Magic-only gate
- `scenes/forge_view.gd` - Updated hammer_descriptions for alteration and regal keys
- `tools/test/integration_test.gd` - Groups 48-49 added with 3 test cases each (Normal reject, Magic accept, Rare reject)

## Decisions Made
- TackHammer `can_apply` checks only `item.rarity == Item.Rarity.MAGIC` (no room-for-mods check) — clear() always makes room, so the check is unnecessary and would create confusing behavior
- GrandHammer `can_apply` checks only `item.rarity == Item.Rarity.MAGIC` — aligns with PoE convention where Regal is the Magic-to-Rare step
- currency_name updated to "Alteration Hammer" and "Regal Hammer" to match PoE naming conventions

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- CRFT-01 and CRFT-02 complete; Alteration and Regal hammers are functional with correct PoE-style behaviors
- Phase 58 Plan 02 (save format v9) can now proceed — crafting_inventory compat shims from Phase 55 are ready to be removed

---
*Phase: 58-new-hammers-save-v9*
*Completed: 2026-03-29*
