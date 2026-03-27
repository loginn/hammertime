---
phase: 52-save-persistence
verified: 2026-03-27T08:53:44Z
status: passed
score: 6/6 must-haves verified
re_verification: false
---

# Phase 52: Save Persistence Verification Report

**Phase Goal:** Bump save format to v8 with hero_archetype_id persistence; old saves (v7 and below) trigger a fresh new game.
**Verified:** 2026-03-27T08:53:44Z
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Saving a game with a hero archetype writes hero_archetype_id to the save file | VERIFIED | `save_manager.gd:113` — `"hero_archetype_id": GameState.hero_archetype.id if GameState.hero_archetype != null else null` |
| 2 | Loading a v8 save restores the correct hero archetype on GameState | VERIFIED | `save_manager.gd:164-168` — `HeroArchetype.from_id(saved_archetype_id)` in `_restore_state()` |
| 3 | Loading a v7 save deletes the file and starts fresh (no crash, no corruption) | VERIFIED | `save_manager.gd:62-65` — `if saved_version < SAVE_VERSION: delete_save(); return false` |
| 4 | Importing a pre-v8 string returns success:false with error outdated_version | VERIFIED | `save_manager.gd:229-230` — `if import_version < SAVE_VERSION: return {"success": false, "error": "outdated_version"}` |
| 5 | Classless Adventurer (null archetype) round-trips correctly through save/load | VERIFIED | `save_manager.gd:113` writes null; `save_manager.gd:167-168` restores null in else branch; test 38.4 and 38.7 cover this |
| 6 | Prestige wipe nulls hero_archetype so next prestige forces re-selection | VERIFIED | `game_state.gd:132-133` — `# 6. Hero archetype -- wiped to force re-selection on prestige (D-07)` / `hero_archetype = null` |

**Score:** 6/6 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `autoloads/save_manager.gd` | v8 save format with hero_archetype_id field, strict import version check | VERIFIED | `SAVE_VERSION = 8` (line 4); `hero_archetype_id` in build (line 113) and restore (lines 163-168); `outdated_version` rejection (lines 229-230) |
| `autoloads/game_state.gd` | hero_archetype null-out in `_wipe_run_state()` | VERIFIED | Line 133: `hero_archetype = null` with comment `# 6. Hero archetype -- wiped to force re-selection on prestige (D-07)` |
| `tools/test/integration_test.gd` | Group 38 save persistence tests | VERIFIED | `_group_38_save_persistence()` defined at line 1918, called at line 48 in `_run_all_tests()`; 12 assertions covering all 6 truths |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `save_manager.gd:_build_save_data()` | `GameState.hero_archetype` | `hero_archetype_id` field in save dict | WIRED | Line 113: `"hero_archetype_id": GameState.hero_archetype.id if GameState.hero_archetype != null else null` |
| `save_manager.gd:_restore_state()` | `HeroArchetype.from_id()` | deserialization of hero_archetype_id string | WIRED | Line 166: `GameState.hero_archetype = HeroArchetype.from_id(saved_archetype_id)` |
| `save_manager.gd:import_save_string()` | `SAVE_VERSION` | strict version rejection for old imports | WIRED | Lines 225-230: newer_version and outdated_version both checked before `_restore_state` call |
| `game_state.gd:_wipe_run_state()` | `hero_archetype` | null assignment for prestige reset | WIRED | Line 133: `hero_archetype = null` — final step before `hero.update_stats()` |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| SAVE-01 | 52-01-PLAN.md | Save format v8 with hero_archetype_id. Old saves trigger new game (breaking change) | SATISFIED | All four sub-behaviors implemented: v8 format written and read, old file-load triggers `delete_save()`, old import strings return `outdated_version`, null archetype handled correctly |

**Note:** REQUIREMENTS.md checkbox on line 21 shows `[x]` (completed) correctly. The tracker table on line 55 still shows `not started` — this is a stale table entry. The checkbox is authoritative per project convention; the table is a minor inconsistency but does not block verification.

---

### Anti-Patterns Found

None. No TODO/FIXME/PLACEHOLDER comments, no stub return values, no empty implementations found in any of the three modified files.

---

### Human Verification Required

#### 1. Save/Load Round-Trip in Running Game

**Test:** Start the game, select a hero archetype (e.g., str_hit), play through one area, exit and re-launch. Confirm the archetype is still active on reload.
**Expected:** Hero archetype persists across game sessions without re-selection being required.
**Why human:** Requires running the Godot editor and verifying runtime behavior; integration tests confirm the logic but not the full engine save-file I/O path.

#### 2. Old Save File Handling in Running Game

**Test:** Manually create or rename a v7-format save file at `user://hammertime_save.json`, then launch the game.
**Expected:** Game detects outdated save, deletes it silently, and starts a fresh game without crash or error dialog.
**Why human:** The delete-on-load path (`load_game()` lines 62-65) is programmatically verified by the version constant and code inspection, but runtime file-system behavior in Godot's user:// path requires live testing.

#### 3. Prestige Flow Re-Selection

**Test:** Complete a prestige with a hero archetype selected, observe that post-prestige the archetype selection screen (phase 53, not yet built) or null state is presented.
**Expected:** `hero_archetype` is null after prestige, forcing re-selection in the next phase.
**Why human:** Phase 53 (archetype selection UI) is not yet implemented; the null assignment is verified but the downstream UX cannot be tested until phase 53 ships.

---

## Gaps Summary

No gaps. All 6 must-have truths are VERIFIED. All 3 required artifacts exist, are substantive, and are correctly wired. All 4 key links are active. SAVE-01 is satisfied.

The only outstanding items are human-verification tests for runtime behavior, which cannot block the phase — the automated evidence is complete and unambiguous.

---

_Verified: 2026-03-27T08:53:44Z_
_Verifier: Claude (gsd-verifier)_
