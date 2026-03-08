---
phase: 48
plan: 03
title: "DoT UI & Integration Tests"
status: complete
started: 2026-03-08
completed: 2026-03-08
---

# Plan 03: DoT UI & Integration Tests — Summary

## What Was Built
Added DoT combat UI feedback (accumulator labels showing running damage totals, status text showing active DoT types with stack counts) to the gameplay view. Fixed Warhammer implicit naming inconsistency. Added comprehensive integration tests covering all 7 DOT requirements across Groups 30-34.

## Key Decisions
- DoT accumulator labels positioned below HP bars with small font, fade out after 2s hold + 1s fade when all DoTs expire
- Status text displays active DoT types in fixed order (BLEED, POISON, BURN) with stack counts > 1
- Integration tests verify DoT stat types, stacking mechanics, defense interaction, DPS calculation, and signal existence via source code inspection for forge_view

## Key Files
### Created
- `.planning/phases/48-damage-over-time/48-03-SUMMARY.md`: This summary

### Modified
- `scenes/gameplay_view.gd`: Added DoT signal handlers, accumulator/status labels, fade tweens, UI reset on combat stop/pack kill/hero death
- `scenes/gameplay_view.tscn`: Added 4 Label nodes (PackDotAccumulator, HeroDotAccumulator, PackDotStatus, HeroDotStatus)
- `models/items/warhammer.gd`: Renamed implicit from "Bleed Chance" to "Bleed Damage" to match BLEED_DAMAGE stat type
- `tools/test/integration_test.gd`: Added Groups 30-34 (DoT stat types, proc logic, defense interaction, DPS calculation, signal verification)

## Self-Check
PASSED — All 5 tasks completed and committed. Verification commands confirm DoT signal references (10 matches >= 8), Warhammer implicit renamed, and all 5 test groups present.

## Issues
None
