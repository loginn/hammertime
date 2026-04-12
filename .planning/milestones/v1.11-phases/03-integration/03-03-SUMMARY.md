---
phase: 03-integration
plan: 03
subsystem: testing
tags: [gdscript, godot, integration-tests, currency-hammers, save-format]

# Dependency graph
requires:
  - phase: 03-01
    provides: loot table with alchemy/divine/annulment drop entries (area-gated)
  - phase: 03-02
    provides: SAVE_VERSION = 10 constant used in Group 50 version assertion
provides:
  - "Group 50 renamed to _group_50_save_v10_round_trip with v10 assertion and 3 new currency round-trip checks"
  - "7 new test groups (51-57) covering all previously-untested base hammer behaviors"
  - "Complete integration test suite for all 8 base hammer apply/reject invariants"
affects: [03-verification, phase-03-gate]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "_check() non-aborting accumulator used exclusively in new groups (not assert())"
    - "3-sub-test shape per group: rejection / success / edge"
    - "Inline item construction: Broadsword.new(8) with manual rarity/prefix/suffix setup"
    - "Inline currency instantiation per group: RunicHammer.new() etc (no fixture sharing)"
    - "Invariant-only assertions: counts, rarities — never specific affix names or roll values"
    - "Divine mod-name preservation: capture names_before/after arrays, assert equality"

key-files:
  created: []
  modified:
    - tools/test/integration_test.gd

key-decisions:
  - "New groups 51-57 use _check() not assert() — matches non-aborting harness contract (assert() aborts on failure, _check() accumulates)"
  - "Alchemy and Chaos mod-count tolerates pool exhaustion: >= 1 not >= 4 (Pitfall 5)"
  - "Divine edge test captures affix_name arrays before and after apply(), asserts equality (Pitfall 4)"
  - "v8 rejection assertion relabeled to 50y (was 50u) to avoid label collision with new 50u/v/w/x cycle"
  - "Second mini-cycle added inside Group 50 for alchemy/divine/annulment: set → _build_save_data → initialize_fresh_game → _restore_state → assert"
  - "Groups 48/49 left unchanged (they use assert() but are working; converting is out of scope)"

patterns-established:
  - "Pattern: Divine mod-name preservation test — store names in Array[String] before apply, compare after"
  - "Pattern: Full-slot edge tests — add max mods (1+1 for Magic, 3+3 for Rare) then assert can_apply is false"
  - "Pattern: Empty-rarity edge tests — clear prefixes/suffixes, set rarity, assert rejection or acceptance"

requirements-completed: [INT-02, INT-03]

# Metrics
duration: 35min
completed: 2026-04-12
---

# Phase 03 Plan 03: Integration Tests (Group 50 Update + Groups 51-57) Summary

**Group 50 updated to SAVE_VERSION 10 with 3 new currency round-trips; 7 new hammer test groups (Transmute through Annulment) added using _check()-only invariant assertions**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-04-12T (session start)
- **Completed:** 2026-04-12
- **Tasks:** 3
- **Files modified:** 1

## Accomplishments

- Renamed `_group_50_save_v9_round_trip` to `_group_50_save_v10_round_trip` in all 6 locations (function declaration, header comment, inline print, version assertion, print marker, dispatch call)
- Added second mini-cycle inside Group 50 asserting alchemy/divine/annulment currency counts round-trip through save/restore (labels 50v/50w/50x); v8 rejection relabeled 50y
- Implemented 7 complete test groups (51-57) each with 3 sub-tests (rejection / success / edge), all using `_check()` exclusively — assert() count unchanged at 15 (Groups 48/49 only)
- Dispatch list in `_ready()` wired with all 8 groups (50-57) in numeric order

## Group Summary

| Group | Hammer | Rejection test | Success test | Edge test |
|-------|--------|----------------|--------------|-----------|
| 51 | RunicHammer (Transmute) | Magic item rejected | Normal → Magic (1-2 mods) | Second Transmute on already-Magic rejected |
| 52 | AugmentHammer | Normal item rejected | Magic+room → +1 mod (exact count) | Full Magic (1+1) rejected |
| 53 | AlchemyHammer | Magic item rejected | Normal → Rare (>=1 mod, pool-exhaustion safe) | Rare item rejected |
| 54 | ChaosHammer | Normal item rejected | Rare reroll (>=1 mod, pool-exhaustion safe) | Empty Rare accepted, gains mods |
| 55 | ExaltHammer | Magic item rejected | Rare+room → +1 mod (exact count) | Full Rare (3+3) rejected |
| 56 | DivineHammer | 0-mod Normal rejected | Magic with mods rerolled, rarity preserved | names_before == names_after (mod-name preservation) |
| 57 | AnnulmentHammer | 0-mod Normal rejected | Magic (1+1) → mod count -1 exact | Empty Magic rejected |

## Task Commits

Each task was committed atomically:

1. **Task 1: Update Group 50 (rename + v10 + new currency round-trip) and wire dispatch list** - `7353df1` (feat)
2. **Task 2: Implement Groups 51-54 (Transmute, Augment, Alchemy, Chaos)** - `95c622e` (feat)
3. **Task 3: Implement Groups 55-57 (Exalt, Divine with name-preservation, Annulment)** - `8de883e` (feat)

## Files Created/Modified

- `tools/test/integration_test.gd` — Renamed Group 50 (6 locations), added second save cycle for 3 new currencies, updated dispatch list (+8 calls), added 7 new full test groups (Groups 51-57)

## Decisions Made

- Used `_check()` exclusively in new groups — Groups 48/49 use `assert()` which aborts on failure; new groups must use the non-aborting accumulator so the suite continues past a single failure
- Alchemy and Chaos edge tests assert `mod_count >= 1` not `>= 4` — pool exhaustion on Tier 8 Broadsword with limited affix pool can produce fewer than 4 mods
- Divine edge test captures `affix_name` arrays before and after `apply()` and asserts equality — does NOT assert on roll values which may or may not change by RNG
- Second mini-cycle for Group 50 new currencies uses a fresh `save_data2` dict to avoid touching the first cycle's assertions (additive, not invasive)

## Deviations from Plan

None — plan executed exactly as written.

## Structural Verification Results

```
_group_50_save_v10_round_trip occurrences: 2  (declaration + dispatch)
_group_50_save_v9_round_trip occurrences:  0  (fully removed)
save_data["version"] == 10 assertion:      1
50v/50w/50x labels:                        1 each
_group_5[1-7]_ function declarations:      7
"Group 5[1-7]: * — PASSED" markers:        7
assert( count (baseline unchanged):        15
names_before == names_after:               1  (Divine edge test, Pitfall 4)
mod_count >= 4:                            0  (Pitfall 5 respected)
```

## Known Stubs

None — all 7 stub bodies from Task 1 were fully replaced in Tasks 2 and 3.

## Manual Verification Gate (PENDING)

Per D-25, the integration test harness is NOT CLI-runnable. User must:
1. Open Godot editor
2. Open `tools/test/integration_test.tscn`
3. Press F6
4. Confirm no FAILED lines
5. Confirm all 7 new PASSED markers appear (Groups 51-57)
6. Confirm `Group 50: Save v10 round-trip — PASSED` (NOT v9)

This manual gate is a **phase gate** (required for `/gsd:verify-work`), not a plan gate. This SUMMARY is complete pending that user verification step per the plan's output spec.

## Issues Encountered

None.

## Next Phase Readiness

- Phase 3 Integration is now structurally complete — all 3 plans (03-01 loot table, 03-02 save bump, 03-03 test groups) are committed
- Phase verification step: run `tools/test/integration_test.tscn` via F6 and confirm all groups pass
- After manual verification, Phase 3 is complete and the fix-hammers milestone (v1.11) is done

---
*Phase: 03-integration*
*Completed: 2026-04-12*
