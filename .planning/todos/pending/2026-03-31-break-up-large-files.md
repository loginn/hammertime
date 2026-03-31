---
created: "2026-03-31T12:31:35.811Z"
title: Break up large files
area: general
files:
  - scenes/forge_view.gd
  - models/hero.gd
  - tools/test/integration_test.gd
---

## Problem

Three files are oversized and doing too much, identified in codebase quality audit:

1. **`scenes/forge_view.gd` (1133 lines)** — handles currency selection, item crafting, stash display, equip/melt flow, hero stat comparison, item stats display, and resistance comparison. Any forge feature change requires reading the entire file.

2. **`models/hero.gd` (744 lines)** — combines 30+ instance variables, damage calculation, defense calculation, DoT processing, spell damage, and equipment management. `calculate_damage_ranges()` alone is 58 lines.

3. **`tools/test/integration_test.gd` (2485 lines)** — all 50 test groups in a single file with no way to run individual groups.

## Solution

- **forge_view.gd**: Extract stat comparison/display (~300 lines) into a utility. Extract stash display logic into its own script.
- **hero.gd**: Delegate more calculations to StatCalculator. Hero should store state and delegate math.
- **integration_test.gd**: Split into per-feature test files, or adopt GdUnit4 for proper test infrastructure with test selection.
