---
phase: quick-3
plan: 01
subsystem: loot
tags: [cleanup, dead-code, loot-table, drop-simulator]

requires:
  - phase: 16-currency-combat-drops
    provides: "roll_pack_currency_drop replacing roll_currency_drops"
  - phase: 19-forge-view-layout
    provides: "ForgeView replacing hero_view and crafting_view"
provides:
  - "Clean LootTable with only active methods (no deprecated code)"
  - "Removed tools/ directory and drop_simulator"
  - "Removed orphaned hero_view, crafting_view, node_2d.tscn"
affects: []

tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified:
    - models/loot/loot_table.gd

key-decisions:
  - "Removed tools/ directory entirely since drop_simulator was the only file"
  - "Updated architecture line in STATE.md to remove tools/ from folder list"

patterns-established: []

requirements-completed: [CLEANUP-01]

duration: 2min
completed: 2026-02-18
---

# Quick Task 3: Remove Deprecated Loot Tables and Simulator Tool

**Deleted drop_simulator tool, 2 deprecated LootTable methods (80 lines), and 6 orphaned legacy view files (1,179 lines) -- zero impact on active game code**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-18T08:54:43Z
- **Completed:** 2026-02-18T08:57:12Z
- **Tasks:** 3
- **Files modified:** 10 (8 deleted, 2 edited)

## Accomplishments
- Deleted 8 dead files: drop_simulator tool (dev-only), hero_view.gd/.tscn, crafting_view.gd, node_2d.tscn, and associated .uid files
- Removed 2 deprecated static methods from LootTable (get_item_drop_count, roll_currency_drops) -- 80 lines of dead code
- Cleared both known issues from STATE.md and the drop_simulator known gap from MILESTONES.md v1.2 section
- Removed empty tools/ directory and updated architecture description

## Task Commits

Each task was committed atomically:

1. **Task 1: Delete drop simulator and orphaned legacy files** - `0314701` (chore)
2. **Task 2: Remove deprecated methods from LootTable** - `a3938b6` (refactor)
3. **Task 3: Update planning docs to clear known issues** - `12e3a8c` (docs)

## Files Created/Modified
- `tools/drop_simulator.gd` - DELETED (dev-only simulator using deprecated methods)
- `tools/drop_simulator.gd.uid` - DELETED (untracked uid file)
- `scenes/hero_view.gd` - DELETED (old hero equipment view, replaced by ForgeView)
- `scenes/hero_view.gd.uid` - DELETED (uid file)
- `scenes/hero_view.tscn` - DELETED (old hero scene)
- `scenes/crafting_view.gd` - DELETED (old crafting view, replaced by ForgeView)
- `scenes/crafting_view.gd.uid` - DELETED (uid file)
- `scenes/node_2d.tscn` - DELETED (old crafting scene)
- `models/loot/loot_table.gd` - Removed 2 deprecated methods (322 -> 242 lines)
- `.planning/STATE.md` - Cleared known issues, added quick task #3
- `.planning/MILESTONES.md` - Removed drop_simulator known gap from v1.2

## Decisions Made
- Removed tools/ directory entirely since drop_simulator.gd was the only tracked file
- Updated STATE.md architecture line to remove tools/ from folder list since it no longer exists

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Verification Results

1. **Game code integrity**: All LootTable calls in active code use only active methods (roll_rarity, spawn_item_with_mods, roll_pack_currency_drop, get_map_item_count)
2. **No dangling references**: Zero matches for deleted files in any .gd/.tscn/.cfg files
3. **No DEPRECATED markers**: LootTable contains zero deprecated comments
4. **Dead files removed**: All 8 target files confirmed deleted from filesystem

## Self-Check: PASSED

- 3-SUMMARY.md: FOUND
- loot_table.gd: FOUND (modified)
- drop_simulator.gd: CONFIRMED DELETED
- hero_view.gd: CONFIRMED DELETED
- crafting_view.gd: CONFIRMED DELETED
- Commit 0314701: FOUND
- Commit a3938b6: FOUND
- Commit 12e3a8c: FOUND

---
*Quick Task: 3*
*Completed: 2026-02-18*
