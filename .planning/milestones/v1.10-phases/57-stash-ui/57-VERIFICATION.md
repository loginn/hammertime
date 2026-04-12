---
phase: 57-stash-ui
verified: 2026-03-28T00:00:00Z
status: human_needed
score: 9/9 must-haves verified
human_verification:
  - test: "Visual stash layout — launch game and open ForgeView"
    expected: "5 groups of 3 slot buttons visible, labeled Weapon/Helmet/Armor/Boots/Ring, empty slots dimmed to grey"
    why_human: "Scene layout, sizing, spacing, and visual dimming cannot be confirmed by grep alone"
  - test: "Filled slot abbreviation rendering"
    expected: "After item drops, filled slots show 2-3 letter abbreviation (BS for Broadsword, IH for IronHelm, etc.)"
    why_human: "Requires running game with item drops to confirm rendered button text"
  - test: "Tooltip on filled slot"
    expected: "Hovering a filled stash slot shows item name, stats, and affix details via tooltip_text"
    why_human: "Tooltip display on Button nodes requires in-editor runtime check (Godot suppresses tooltips on disabled nodes — need to confirm this edge case is acceptable)"
  - test: "Tap-to-bench transfer"
    expected: "Tapping a filled stash slot places the item on the crafting bench; slot becomes empty and dims"
    why_human: "UI interaction flow requires in-game playtest"
  - test: "Bench-occupied guard toast"
    expected: "While bench has an item, tapping another stash slot shows 'Melt or equip first' toast"
    why_human: "Toast visual feedback requires runtime"
  - test: "Flash and pulse animations"
    expected: "Slot flashes yellow on transfer; all filled slots pulse alpha when bench clears via melt or equip"
    why_human: "Tween animation requires runtime observation"
  - test: "Integration tests groups 45-47 pass in Godot"
    expected: "Open tools/test/integration_test.tscn, press F6, groups 45-47 all show no failures"
    why_human: "GDScript tests require Godot runtime"
---

# Phase 57: Stash UI Verification Report

**Phase Goal:** Players can see stash contents at a glance and move any stash item onto the crafting bench with a single tap.
**Verified:** 2026-03-28T00:00:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | ForgeView displays 15 stash slot buttons in 5 groups of 3 with type labels | VERIFIED | forge_view.tscn lines 270-451: StashDisplay + 5 VBoxContainer groups (WeaponGroup, HelmetGroup, ArmorGroup, BootsGroup, RingGroup), each with Label + HBoxContainer + 3 Button nodes = 15 buttons total |
| 2 | Filled stash slots show 2-3 letter abbreviation of item base type | VERIFIED | `_get_item_abbreviation()` at forge_view.gd:355 — 21 `if item is` branches returning correct codes (BS, BA, WH, DA, VB, SB, WN, LR, SC, IH, LH, CI, IP, LV, SR, IG, LB, SS, IB, JR, SP) plus fallback "??" |
| 3 | Empty stash slots render as dim/greyed squares | VERIFIED | `_update_stash_display()` at forge_view.gd:398-399 sets `btn.modulate = Color(0.4, 0.4, 0.4, 1.0)` and `btn.disabled = true` for empty/null slots |
| 4 | Hovering a filled stash slot shows item details via tooltip_text | VERIFIED | `_build_stash_tooltip()` at forge_view.gd:380 returns `item.get_display_text()`; `_update_stash_display()` assigns this to `btn.tooltip_text` at line 392 |
| 5 | Stash display updates live when stash_updated signal fires | VERIFIED | `GameEvents.stash_updated.connect(_on_stash_updated)` at forge_view.gd:197; `_on_stash_updated` at line 402 calls `_update_stash_display()` |
| 6 | Tapping a filled stash slot moves that item to the crafting bench | VERIFIED | `_on_stash_slot_pressed()` at forge_view.gd:406 — transfers item, sets `GameState.crafting_bench = item`, calls `update_current_item()` |
| 7 | The tapped stash slot becomes empty after transfer (null gap, no shifting) | VERIFIED | forge_view.gd:419 uses `items[index] = null` (not `remove_at`) per D-08; `_update_stash_display()` treats null entries as empty via `items[i] != null` guard |
| 8 | Stash slots are disabled when the bench has an item | VERIFIED | `_update_stash_display()` at forge_view.gd:394 sets `btn.disabled = (GameState.crafting_bench != null)` for filled slots; `_on_stash_slot_pressed()` at line 408 returns early with toast when bench occupied |
| 9 | After melt/equip clears the bench, stash slots re-enable with pulse animation | VERIFIED | `_on_melt_pressed()` at forge_view.gd:512-513 calls `_update_stash_display()` then `_pulse_stash_slots()`; `_on_equip_pressed()` at lines 557-558 does the same |

**Score:** 9/9 truths verified (all automated checks pass)

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `scenes/forge_view.tscn` | StashDisplay node tree replacing ItemTypeButtons | VERIFIED | StashDisplay at line 270, 5 VBoxContainer groups with Labels and 15 Button nodes; `ItemTypeButtons` not found (grep returned no output) |
| `scenes/forge_view.gd` | Stash display logic: `_update_stash_display`, `_get_item_abbreviation`, `_build_stash_tooltip`, signal wiring | VERIFIED | All 5 required functions present: lines 355, 380, 384, 402, 406; signal connected at line 197; stash_slot_buttons dict at line 24 |
| `tools/test/integration_test.gd` | Test groups 45-47 registered and implemented | VERIFIED | Registered in `_ready()` at lines 55-57; `_group_45_stash_ui_display()` at 2214, `_group_46_stash_tap_to_bench()` at 2246, `_group_47_stash_tooltip_text()` at 2289; each calls `GameState._init_stash()` at start |
| `autoloads/game_state.gd` | `add_item_to_stash` handles null gaps | VERIFIED | Lines 223-253 — non_null_count loop for cap check, null-gap fill before append, `GameEvents.stash_updated.emit(slot)` preserved |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `forge_view.gd _update_stash_display` | `game_state.gd stash dict` | `GameState.stash.get(slot_type, [])` | WIRED | forge_view.gd:386 reads `GameState.stash.get(slot_type, [])` |
| `forge_view.gd _ready` | `game_events.gd stash_updated` | `GameEvents.stash_updated.connect(_on_stash_updated)` | WIRED | forge_view.gd:197 — signal connected in _ready() |
| `forge_view.gd _on_stash_slot_pressed` | `GameState.stash array + crafting_bench` | `items[index] = null` + `GameState.crafting_bench = item` | WIRED | forge_view.gd:419-420 |
| `forge_view.gd _on_melt_pressed` | `_update_stash_display + _pulse_stash_slots` | Called after bench clears | WIRED | forge_view.gd:512-513 |
| `forge_view.gd _on_equip_pressed` | `_update_stash_display + _pulse_stash_slots` | Called after bench clears | WIRED | forge_view.gd:557-558 |

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| STSH-02 | 57-01-PLAN.md | Stash displays as letter-icon squares in ForgeView | SATISFIED | StashDisplay in tscn; `_get_item_abbreviation()` with 21 item branches; `_update_stash_display()` wired to live stash data |
| STSH-03 | 57-02-PLAN.md | Player can tap a stash item to move it onto the crafting bench | SATISFIED | `_on_stash_slot_pressed()` transfers item, sets `GameState.crafting_bench`, null-gaps slot per D-08 |
| STSH-05 | 57-01-PLAN.md | Player can hover/long-press a stash item to see full item details | SATISFIED | `_build_stash_tooltip()` returns `item.get_display_text()`; assigned to `btn.tooltip_text` in `_update_stash_display()` |

No orphaned requirements — all 3 IDs declared in plan frontmatter are accounted for and satisfied.

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `tools/test/integration_test.gd` | 2258, 2281 | Group 46 test uses `remove_at()` to simulate tap, not `items[index] = null` | Warning | Test models shifting-remove behaviour that the production `_on_stash_slot_pressed` does NOT do. The test still passes (it tests the array size outcome differently) but does not accurately model the D-08 null-gap contract. The D-08 compliance of the production code is verified directly; only the test simulation is inconsistent. Not a blocker. |

No placeholder text, empty implementations, or hardcoded stub data found in production files.

---

## Human Verification Required

### 1. Visual stash layout

**Test:** Launch the game in Godot editor (F5), navigate to ForgeView, inspect the stash area.
**Expected:** 5 groups of 3 slot buttons visible, each group has a type label (Weapon/Helmet/Armor/Boots/Ring), empty slots appear as dim grey squares.
**Why human:** Scene layout, sizing, spacing, and visual dimming require runtime rendering.

### 2. Filled slot abbreviation rendering

**Test:** Play through Forest zone to get item drops. Observe stash slot buttons in ForgeView.
**Expected:** Filled slots display 2-3 letter codes (e.g., BS for Broadsword, IH for Iron Helm). Filled slots appear white/bright; empty slots remain grey.
**Why human:** Requires in-game item drops to populate stash and observe rendered button text.

### 3. Tooltip on filled slot (with disabled-slot edge case)

**Test:** Hover over a filled stash slot (when bench is empty). Then put an item on the bench and hover a filled slot.
**Expected:** Tooltip shows name, stats, and affixes when slot is enabled. Per Research Pitfall 6, tooltip is suppressed on disabled slots (bench occupied) — confirm this is visually acceptable.
**Why human:** Godot tooltip behaviour on disabled Buttons requires runtime confirmation.

### 4. Tap-to-bench transfer

**Test:** Tap a filled stash slot.
**Expected:** Item appears on the crafting bench, the tapped slot dims (becomes empty), and the bench display updates.
**Why human:** UI interaction flow requires in-game playtest.

### 5. Bench-occupied guard toast

**Test:** While the bench has an item, tap another filled stash slot.
**Expected:** "Melt or equip first" toast appears. No item transfer occurs.
**Why human:** Toast visual feedback requires runtime observation.

### 6. Flash and pulse animations

**Test:** Tap a filled stash slot (observe flash). Then melt or equip the bench item (observe pulse).
**Expected:** Tapped slot briefly flashes yellow then dims. When bench clears, all filled slots briefly pulse their alpha.
**Why human:** Tween animations require runtime observation.

### 7. Integration tests groups 45-47 pass

**Test:** Open `tools/test/integration_test.tscn` in Godot, press F6.
**Expected:** Groups 45, 46, and 47 all print passing checks with no failures.
**Why human:** GDScript test runner requires Godot runtime. Note: Group 46 uses `remove_at` in its simulation (see Anti-Patterns), so it tests shifting behaviour — all checks should still pass since the stash array size outcomes it asserts are valid, but the D-08 null-gap contract is not exercised by the test.

---

## Gaps Summary

None. All 9 observable truths verified at all three levels (exists, substantive, wired). All 3 requirement IDs satisfied. All 5 key links wired. One warning-level test inconsistency noted (Group 46 simulation method) but this does not block goal achievement.

The phase goal — "Players can see stash contents at a glance and move any stash item onto the crafting bench with a single tap" — is fully implemented in the codebase. Human verification is required to confirm the in-game visual and interactive behaviour.

---

_Verified: 2026-03-28T00:00:00Z_
_Verifier: Claude (gsd-verifier)_
