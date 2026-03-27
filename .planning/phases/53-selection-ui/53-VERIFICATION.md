---
phase: 53-selection-ui
verified: 2026-03-27T00:00:00Z
status: human_needed
score: 5/5 must-haves verified
human_verification:
  - test: "Visual overlay appearance after prestige to P1"
    expected: "3-card overlay covers full screen, header reads 'Choose Your Hero', each card has colored left border (red/green/blue) with archetype label, hero title, and bonus percentages"
    why_human: "Programmatic UI rendering cannot be verified statically — need to confirm PanelContainer StyleBoxFlat border renders as intended at 1280x720"
  - test: "Overlay blocks all background input (SEL-03)"
    expected: "Clicking on the area behind the cards does nothing — forge/combat tabs remain unresponsive while overlay is visible"
    why_human: "mouse_filter STOP on bg ColorRect is present in code, but layering correctness on $OverlayLayer depends on scene tree z-order that cannot be confirmed without runtime"
  - test: "Card click dismisses overlay with 0.3s fade"
    expected: "Clicking any card causes the overlay to fade from visible to invisible over approximately 0.3 seconds, then disappear completely"
    why_human: "Tween animation timing is runtime behavior"
  - test: "Hero archetype persists across save/reload"
    expected: "After picking a hero and restarting the game, no overlay appears and the selected hero is still active"
    why_human: "SaveManager.save_game() call is present, but end-to-end save round-trip for hero_archetype_id requires runtime verification"
  - test: "P0 never sees the overlay"
    expected: "Starting the game fresh (prestige_level == 0), no overlay appears at all"
    why_human: "Logic guard is verified in code, but full scene load behavior should be confirmed once"
---

# Phase 53: Selection UI Verification Report

**Phase Goal:** Build the 3-card hero selection overlay that appears after prestige and blocks gameplay until a hero is picked.
**Verified:** 2026-03-27
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | After prestige to P1+, a 3-card overlay appears showing one STR, one DEX, one INT hero | VERIFIED | `_show_hero_selection()` calls `HeroArchetype.generate_choices()` which returns exactly 3 heroes (1 per archetype). Check guard `GameState.prestige_level >= 1 and GameState.hero_archetype == null` confirmed at `main_view.gd:59`. |
| 2 | Each card shows archetype label, hero title, and formatted passive bonuses as percentages | VERIFIED | `_build_hero_card()` in `main_view.gd:217-267` builds arch_label (e.g. "STR - Hit"), title_label (`hero.title`), and iterates `HeroArchetype.format_bonuses(hero.passive_bonuses)` to create bonus label nodes. `format_bonuses()` confirmed at `hero_archetype.gd:139-145`. |
| 3 | Clicking a card selects that hero, dismisses the overlay with 0.3s fade, and persists via auto-save | VERIFIED | `_on_hero_card_selected()` at `main_view.gd:270-290` sets `GameState.hero_archetype = hero`, calls `update_stats()`, `SaveManager.save_game()`, emits `hero_selected`, and tweens `modulate:a` to `0.0` over `0.3` seconds. Double-click guard via null check on `_hero_overlay`. |
| 4 | P0 players never see the selection overlay | VERIFIED | Guard condition at `main_view.gd:59`: `GameState.prestige_level >= 1 and GameState.hero_archetype == null` — prestige_level 0 evaluates false on `>= 1`. Group 39 test "P0 with null archetype: overlay NOT triggered" covers this logic path. |
| 5 | Overlay blocks all input to underlying views until a hero is picked | VERIFIED (code-level) | `bg` ColorRect at `main_view.gd:185` has `mouse_filter = Control.MOUSE_FILTER_STOP`. Card PanelContainers also have `MOUSE_FILTER_STOP` at line 220. Runtime blocking behavior requires human verification. |

**Score:** 5/5 truths verified at code level

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `models/hero_archetype.gd` | BONUS_LABELS const and format_bonuses() static method | VERIFIED | `const BONUS_LABELS: Dictionary` at line 123 with exactly 13 entries. `static func format_bonuses(...)` at line 139. Both substantive and wired. |
| `scenes/main_view.gd` | Hero selection overlay construction and detection logic | VERIFIED | `_show_hero_selection()` at line 170, `_build_hero_card()` at line 217, `_on_hero_card_selected()` at line 270, detection guard at line 59. All substantive (not stubs). |
| `tools/test/integration_test.gd` | Group 39 selection UI tests | VERIFIED | `_group_39_selection_ui()` at line 1974, called from `_ready()` at line 49. 17 test cases covering format_bonuses, BONUS_LABELS coverage, generate_choices, P0/P1 detection logic, and selection assignment. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `scenes/main_view.gd` | `models/hero_archetype.gd` | `HeroArchetype.generate_choices()` | WIRED | Line 173: `var choices := HeroArchetype.generate_choices()`. Line 254: `HeroArchetype.format_bonuses(hero.passive_bonuses)`. Both calls present and used. |
| `scenes/main_view.gd` | `autoloads/game_state.gd` | `GameState.prestige_level >= 1` detection | WIRED | Line 59: `if GameState.prestige_level >= 1 and GameState.hero_archetype == null`. Condition drives overlay show/hide. |
| `scenes/main_view.gd` | `autoloads/game_state.gd` | `GameState.hero_archetype = hero` assignment | WIRED | Line 278: `GameState.hero_archetype = hero` inside `_on_hero_card_selected()`. Followed by `GameState.hero.update_stats()`. |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| SEL-01 | 53-01-PLAN.md | 3-card draft on prestige — 1 STR, 1 DEX, 1 INT drawn randomly, pick one | SATISFIED | `generate_choices()` returns exactly 3, one per archetype. Overlay shows on P1+. Group 39 test "generate_choices: one per archetype (STR/DEX/INT)" covers this. |
| SEL-02 | 53-01-PLAN.md | P0 plays as classless Adventurer (no hero, no passive). First selection at P1 | SATISFIED | `GameState.hero_archetype = null` by default. Overlay guard `prestige_level >= 1` prevents P0 exposure. Group 39 tests "P0 with null archetype: overlay NOT triggered" and "P1 with set archetype: overlay NOT triggered". |
| SEL-03 | 53-01-PLAN.md | Selection overlay UI blocks gameplay post-prestige until hero is picked (1280x720) | SATISFIED (code) | `MOUSE_FILTER_STOP` on both bg ColorRect and each card PanelContainer. Overlay added to `$OverlayLayer`. Runtime behavior needs human confirmation. |

**Note on traceability table in REQUIREMENTS.md:** The `[x]` checkmarks on SEL-01, SEL-02, SEL-03 in the requirements list (lines 16-18) correctly reflect completion. The traceability table at lines 52-54 still shows "not started" — this is a documentation staleness issue in REQUIREMENTS.md, not a code gap. The checkmarks are authoritative.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None | — | — | — | — |

No TODOs, FIXMEs, placeholders, empty return stubs, or stub indicators found in any of the three modified files.

### Human Verification Required

#### 1. Visual Overlay Rendering

**Test:** Start the game with `prestige_level = 1` and `hero_archetype = null` (or prestige to P1 naturally). Observe the overlay.
**Expected:** Full-screen semi-transparent black overlay appears with header "Choose Your Hero" and 3 cards. Each card has a colored left border (red for STR, green for DEX, blue for INT), the archetype label (e.g. "STR - Hit"), the hero title (e.g. "The Berserker"), and bonus lines like "+25% Attack Damage".
**Why human:** Programmatic Godot UI layout cannot be visually confirmed without running the engine.

#### 2. Input Blocking (SEL-03)

**Test:** With the overlay visible, try clicking forge/combat tabs and clicking between cards.
**Expected:** All clicks behind the overlay are absorbed — no tab switching, no background interaction.
**Why human:** Scene tree z-order and CanvasLayer behavior with `MOUSE_FILTER_STOP` must be confirmed at runtime.

#### 3. Card Click Fade and Dismiss

**Test:** Click any hero card.
**Expected:** Overlay fades out smoothly over ~0.3 seconds and disappears. The forge view is revealed underneath and the game is fully playable.
**Why human:** Tween animation and scene state after queue_free cannot be verified statically.

#### 4. Save and Reload Persistence

**Test:** Pick a hero at P1, close the game, reopen it.
**Expected:** No overlay appears on reload. The selected hero archetype is active (passive bonuses apply).
**Why human:** SaveManager.save_game() is called in code, but the full save round-trip for hero_archetype_id must be confirmed in a real session.

#### 5. New Prestige Shows Fresh Overlay

**Test:** After picking a hero at P1, prestige again to P2.
**Expected:** A fresh overlay appears with a new random set of 3 heroes (one per archetype).
**Why human:** `_wipe_run_state()` nulls `hero_archetype` on prestige — this triggers the P1+ with null check on scene reload. Needs runtime confirmation.

### Gaps Summary

No code gaps found. All artifacts exist, are substantive (not stubs), and are fully wired to each other and to GameState/GameEvents. The five human verification items are standard runtime/visual checks that cannot be resolved statically — they are not code deficiencies.

The traceability table in REQUIREMENTS.md has stale "not started" entries for SEL-01/02/03 but the `[x]` checkmarks above the table correctly reflect phase 53 completion. This is a minor documentation inconsistency.

---

_Verified: 2026-03-27_
_Verifier: Claude (gsd-verifier)_
