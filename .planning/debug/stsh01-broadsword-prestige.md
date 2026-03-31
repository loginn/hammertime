---
status: diagnosed
trigger: "STSH-01 integration test expects Broadsword in stash after prestige, but Phase 55 removed starter weapon from _wipe_run_state"
created: 2026-03-29T00:00:00Z
updated: 2026-03-29T00:00:00Z
---

## Current Focus

hypothesis: _wipe_run_state() no longer calls _place_starter_kit(), so stash is empty after prestige, but test still asserts Broadsword exists
test: read _wipe_run_state and the test assertion
expecting: _wipe_run_state has no _place_starter_kit call; test asserts stash["weapon"][0] is Broadsword
next_action: return diagnosis

## Symptoms

expected: Integration test group 3 (prestige P0->P1) passes
actual: Assertion fails — `GameState.stash["weapon"][0] is Broadsword` returns false because weapon slot is empty after prestige
errors: _check fails on "starter weapon (Broadsword) in stash after prestige"
reproduction: Run integration test group 3
started: After Phase 55 changes removed starter weapon provisioning from _wipe_run_state

## Eliminated

(none needed — root cause confirmed on first hypothesis)

## Evidence

- timestamp: 2026-03-29
  checked: game_state.gd _wipe_run_state() (lines 126-155)
  found: _wipe_run_state calls _init_stash() and sets crafting_bench=null, but does NOT call _place_starter_kit(). Stash is left empty.
  implication: After prestige, weapon stash slot is empty — no Broadsword.

- timestamp: 2026-03-29
  checked: game_state.gd initialize_fresh_game() (lines 87-121)
  found: initialize_fresh_game() DOES call _place_starter_kit(null) at line 109, which places Broadsword+IronPlate. But _wipe_run_state (used by prestige) does not.
  implication: Fresh game gets starter items; prestige does not. This is the Phase 55 intentional change — Phase 56 handles starter provisioning via archetype selection.

- timestamp: 2026-03-29
  checked: integration_test.gd _simulate_prestige() (lines 86-99)
  found: Calls GameState._wipe_run_state() directly. Does NOT call _place_starter_kit().
  implication: Test correctly simulates the prestige path, which no longer provisions starter items.

- timestamp: 2026-03-29
  checked: integration_test.gd group 3 assertion (lines 159-162)
  found: Asserts `GameState.stash["weapon"][0] is Broadsword` — expects starter weapon after prestige
  implication: This assertion is stale. After Phase 55, weapon stash is empty post-prestige.

- timestamp: 2026-03-29
  checked: integration_test.gd group 1 (lines 112-118)
  found: Group 1 also asserts starter weapon exists and is Broadsword — but group 1 uses _reset_fresh() which calls initialize_fresh_game(), which DOES place starter items. Group 1 is fine.
  implication: Only group 3 (post-prestige) is affected.

## Resolution

root_cause: Phase 55 intentionally removed starter weapon provisioning from _wipe_run_state() (prestige path). The _place_starter_kit() call only exists in initialize_fresh_game() (new game path). The integration test group 3 still asserts a Broadsword exists in the weapon stash after prestige, but that slot is now empty by design — Phase 56 handles starter item provisioning after archetype selection.
fix: (research only — not applied)
verification: (research only)
files_changed: []
