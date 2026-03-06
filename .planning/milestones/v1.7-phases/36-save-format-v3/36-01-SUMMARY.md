---
phase: 36-save-format-v3
plan: 01
subsystem: database
tags: [gdscript, godot, save-format, json, prestige, persistence]

# Dependency graph
requires:
  - phase: 35-prestige-foundation
    provides: prestige_level, max_item_tier_unlocked, tag_currency_counts on GameState; prestige_completed signal on GameEvents
provides:
  - SaveManager v3 format with prestige field persistence (prestige_level, max_item_tier_unlocked, tag_currency_counts)
  - Delete-on-old-version migration policy for saves with version < 3
  - Prestige auto-save via prestige_completed signal (direct save_game() call)
affects: [37-affix-tier-expansion, 38-prestige-ui, 39-tag-currencies, 41-verification]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Delete-on-old-version: load_game() checks saved_version < SAVE_VERSION, calls delete_save() and returns false"
    - "Prestige auto-save: connect to GameEvents.prestige_completed in _ready(), call save_game() directly (not debounced)"
    - "tag_currency_counts cleared to {} before restoring to avoid stale dynamic keys from previous session"

key-files:
  created: []
  modified:
    - autoloads/save_manager.gd

key-decisions:
  - "v2 saves deleted on load (no migration path) — user decision; delete_save() + return false in load_game()"
  - "Dead migration code (_migrate_save, _migrate_v1_to_v2) removed for cleanliness"
  - "v2 import strings accepted with default prestige values (0, 8, {}) — more user-friendly than rejection"
  - "Prestige auto-save uses direct save_game() not debounced _trigger_save() — singular high-stakes event"
  - "tag_currency_counts uses .duplicate() in _build_save_data() matching currency_counts pattern"

patterns-established:
  - "Pattern: Delete-on-old-version replaces migration — any save version < SAVE_VERSION is deleted and fresh game starts"
  - "Pattern: Dynamic-key dictionaries (tag_currency_counts) must be cleared to {} before restoring in _restore_state()"

requirements-completed: [SAVE-01, SAVE-02]

# Metrics
duration: 2min
completed: 2026-02-20
---

# Phase 36 Plan 01: Save Format v3 Summary

**SaveManager bumped to v3 with prestige field persistence (prestige_level, max_item_tier_unlocked, tag_currency_counts) and delete-on-old-version policy replacing migration chain**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-20T04:18:31Z
- **Completed:** 2026-02-20T04:20:34Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- SAVE_VERSION bumped from 2 to 3; load_game() deletes saves with version < 3 and returns false (fresh game)
- Three prestige fields added to _build_save_data() and _restore_state(): prestige_level (default 0), max_item_tier_unlocked (default 8), tag_currency_counts (default {})
- Dead migration code (_migrate_save, _migrate_v1_to_v2) removed; import_save_string() now calls _restore_state() directly with v2 strings getting default prestige values
- GameEvents.prestige_completed connected in _ready(); _on_prestige_completed() calls save_game() directly for immediate post-prestige capture

## Task Commits

Each task was committed atomically:

1. **Task 1 + Task 2: Upgrade save format to v3 with prestige fields and prestige auto-save** - `8c53ee7` (feat)

Note: Both tasks modified the same file and were written together; committed as a single atomic change covering all plan requirements.

**Plan metadata:** (see final commit below)

## Files Created/Modified

- `autoloads/save_manager.gd` - Bumped SAVE_VERSION to 3; added delete-on-old-version in load_game(); added prestige fields to _build_save_data() and _restore_state(); removed dead migration functions; added prestige_completed signal connection and _on_prestige_completed() handler

## Decisions Made

- Removed dead migration functions (_migrate_save, _migrate_v1_to_v2) per research recommendation — cleaner than leaving unreachable code
- Allowed v2 import strings to succeed with default prestige values — more user-friendly than rejection; _restore_state() defaults handle missing fields gracefully
- Used direct save_game() in prestige handler (not debounced _trigger_save()) — prestige is a singular high-stakes event, not a rapid-fire trigger

## Deviations from Plan

None - plan executed exactly as written. Both tasks were implemented together since they modify the same file; all specified changes applied cleanly.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- SaveManager v3 complete; prestige state survives game restarts
- Phase 37 (Affix Tier Expansion) can begin immediately — save format now persists max_item_tier_unlocked
- Phase 39 (Tag Currencies) can rely on tag_currency_counts persistence
- Phase 41 (Verification) note: build a hand-crafted v2 fixture JSON to test the delete-on-old-version behavior specifically

## Self-Check: PASSED

- `autoloads/save_manager.gd` — FOUND
- `.planning/phases/36-save-format-v3/36-01-SUMMARY.md` — FOUND
- Commit `8c53ee7` — FOUND

---
*Phase: 36-save-format-v3*
*Completed: 2026-02-20*
