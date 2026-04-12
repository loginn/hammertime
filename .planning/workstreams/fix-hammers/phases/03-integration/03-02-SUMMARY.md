---
phase: 03-integration
plan: 02
subsystem: persistence
tags: [save-format, version-bump, gdscript, godot4]

# Dependency graph
requires:
  - phase: 01-hammer-models
    provides: "currency_counts dict seeded with all 9 keys (alchemy/divine/annulment = 0) in game_state.gd:97-107"
  - phase: 02-forge-ui
    provides: "Phase 2 complete; Phase 3 integration is unblocked"
provides:
  - "SAVE_VERSION constant = 10 in autoloads/save_manager.gd"
  - "v9 (and earlier) saves trigger delete-and-fresh on next load"
  - "v10 saves include alchemy/divine/annulment keys automatically via .duplicate()"
affects:
  - "03-03-PLAN: Group 50 updated to assert save_data['version'] == 10"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Single constant bump as save-format migration signal — delete-and-fresh policy requires no additional code"

key-files:
  created: []
  modified:
    - "autoloads/save_manager.gd"

key-decisions:
  - "D-07: SAVE_VERSION bumped 9→10 via single constant change on line 4 — no migration code needed"
  - "D-08: Delete-and-fresh policy on lines 61-65 handles v9→v10 transparently (9 < 10); no branch modifications"
  - "D-09: currency_counts already seeded with all 9 keys from Phase 1 pull-forward; .duplicate() picks them up automatically; no save-path code changes"
  - "D-11: No rollback path for v10→v9 downgrade — one-way bump"

patterns-established:
  - "Pattern: Save version bump is cosmetic (one constant) when serialization is key-agnostic (.duplicate()) and policy is delete-and-fresh"

requirements-completed: [INT-02]

# Metrics
duration: 2min
completed: 2026-04-12
---

# Phase 03 Plan 02: Save Version Bump Summary

**SAVE_VERSION constant bumped from 9 to 10 in save_manager.gd — one-line change; delete-and-fresh policy and key-agnostic .duplicate() serialization handle v10 without any additional code**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-04-12T00:55:33Z
- **Completed:** 2026-04-12T00:57:00Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- `SAVE_VERSION` constant updated from 9 to 10 on line 4 of `autoloads/save_manager.gd`
- Any existing v9 (or earlier) save file will trigger the delete-and-fresh branch on next load (`saved_version < SAVE_VERSION` — 9 < 10 is true)
- v10 saves automatically include alchemy/divine/annulment currency counts because `GameState.currency_counts` already has all 9 keys (Phase 1 pull-forward) and `_build_save_data()` calls `.duplicate()` on the full dict
- No migration code added — consistent with project policy (D-08) and past save-format bump precedent

## Task Commits

1. **Task 1: Bump SAVE_VERSION constant from 9 to 10** - `13de793` (chore)

**Plan metadata:** (in final docs commit)

## Files Created/Modified
- `autoloads/save_manager.gd` — line 4: `const SAVE_VERSION = 9` → `const SAVE_VERSION = 10`

## Git Diff (exact change)

```diff
-const SAVE_VERSION = 9
+const SAVE_VERSION = 10
```

One line changed. All other 300 lines in the file are untouched.

## Decisions Made

Followed plan as specified. All decisions pre-locked in CONTEXT.md D-07 through D-11:
- D-07: Single constant bump — confirmed correct
- D-08: Delete-and-fresh policy already operative (`saved_version < SAVE_VERSION` at line 62) — not modified
- D-09: No key-seeding or migration functions needed — `game_state.gd:97-107` already has all 9 keys
- D-11: No rollback path added

## Why No Migration Code Is Needed

The Phase 1 pull-forward added `"alchemy": 0`, `"divine": 0`, `"annulment": 0` to the `currency_counts` dict initialization in `game_state.gd`. Because `_build_save_data()` serializes currencies via `GameState.currency_counts.duplicate()`, the new keys flow through to the save file automatically on any fresh v10 save. On load, `_restore_state()` uses `for currency_type in saved_currencies: GameState.currency_counts[currency_type] = ...` — a key-iteration loop that is forward-compatible with any new keys. The only semantic effect of the bump is forcing the delete-and-fresh branch to reject v9 saves, which is the correct behavior (a v9 save predates the new currencies and would restore without them).

## Acceptance Criteria Results

| Check | Expected | Result |
|-------|----------|--------|
| `grep -c 'const SAVE_VERSION = 10'` | 1 | 1 |
| `grep -c 'const SAVE_VERSION = 9'` | 0 | 0 |
| `grep -n 'const SAVE_VERSION'` | line 4 only | line 4 |
| `grep -n 'saved_version < SAVE_VERSION'` | 1 match | line 62 |
| `grep -c 'func _build_save_data'` | 1 | 1 |
| `grep -c 'func _restore_state'` | 1 | 1 |
| `grep -c '^func '` baseline vs after | 17 | 17 |
| git diff | exactly 1 line changed | confirmed |

## Deviations from Plan

None — plan executed exactly as written. Single integer literal changed on line 4.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- SAVE_VERSION = 10 is now live in the codebase
- Plan 03-03 (Wave 2) can proceed: Group 50 assertion `save_data["version"] == 10` will pass, and the new currency round-trip assertions (alchemy/divine/annulment) will exercise the forward-compatible serialization path
- Runtime verification deferred to Plan 03-03: user runs `tools/test/integration_test.tscn` via F6 in Godot editor once all Wave 2 work lands (D-25)

---
*Phase: 03-integration*
*Completed: 2026-04-12*
