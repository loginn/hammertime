# Quick Task 10: Fix the icons in the crafting view — Summary

**Completed:** 2026-03-06

## Problem

5 of the 6 hammer currency buttons in `forge_view.tscn` were missing `theme_override_constants/icon_max_width = 32`. Only `RunicHammerBtn` had it. The 216x216 PNG icons rendered as tiny dots or were invisible on the other buttons because `expand_icon = true` without a max width constraint doesn't properly scale large icons down.

## Changes

- **`scenes/forge_view.tscn`:** Added `theme_override_constants/icon_max_width = 32` to ForgeHammerBtn, TackHammerBtn, GrandHammerBtn, ClawHammerBtn, and TuningHammerBtn.

## Result

All 6 hammer buttons now consistently display their icons at 32px width, matching the RunicHammerBtn that was already working correctly.
