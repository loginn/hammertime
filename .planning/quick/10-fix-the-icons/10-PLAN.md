# Quick Task 10: Fix the icons in the crafting view

## Task 1: Add missing icon_max_width to hammer buttons

**Files:** `scenes/forge_view.tscn`
**Action:** Add `theme_override_constants/icon_max_width = 32` to the 5 hammer buttons missing it (ForgeHammerBtn, TackHammerBtn, GrandHammerBtn, ClawHammerBtn, TuningHammerBtn). RunicHammerBtn already has it.
**Verify:** All 6 hammer buttons have consistent `icon_max_width = 32`
**Done:** Icons display at correct 32px size instead of being tiny/missing
