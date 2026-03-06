---
phase: 40
status: human_needed
verified: 2026-03-06
---

# Phase 40: Prestige UI -- Verification

## Goal Achievement
The phase goal is met in code. The prestige view scene exists with a 7-level unlock table, prestige status display, cost/reward info, static reset list, and a two-click confirmation flow. The tab bar integrates a "P{N}" badge with dynamic reveal logic, and prestige triggers a 0.5s fade-to-black before scene reload. All six requirements (PRES-04, PUI-01 through PUI-05) are addressed in the implementation.

## Must-Have Verification

### Plan 01 Must-Haves

| # | Must-Have | Status | Evidence |
|---|-----------|--------|----------|
| 1 | prestige_view.tscn exists with Background, status labels, UnlockTable, ResetListLabel, PrestigeButton | PASS | scenes/prestige_view.tscn lines 8-105: Background ColorRect 1280x670, CurrentLevelLabel, NextInfoLabel, NextRewardLabel, TableHeader, UnlockTable VBoxContainer, ResetListLabel, PrestigeButton |
| 2 | 7-row unlock table with correct tier values from ITEM_TIERS_BY_PRESTIGE | PASS | scenes/prestige_view.gd lines 57-124: loops range(1, MAX_PRESTIGE_LEVEL + 1) = 7 rows, tier text from ITEM_TIERS_BY_PRESTIGE[level] |
| 3 | Completed levels show checkmark, current shows arrow, future shows lock/dash | PASS | scenes/prestige_view.gd lines 74-79: completed = "\u2713", next = ">", future = "-"; row modulate: green/white/grey at lines 117-122 |
| 4 | P1 row shows "Tag Hammers" reward | PASS | scenes/prestige_view.gd lines 100-103: level == 1 sets "Tag Hammers", else "-" |
| 5 | Future costs show "???" | PASS | scenes/prestige_view.gd lines 110-113: state "future" sets cost_label.text = "???" |
| 6 | "Upgrade your forge" button text | PASS | scenes/prestige_view.tscn line 105 default text; scenes/prestige_view.gd line 134 sets it in _update_button_state |
| 7 | First click changes to "Reset progress?" | PASS | scenes/prestige_view.gd line 142: prestige_button.text = "Reset progress?" |
| 8 | Timer resets after 3 seconds | PASS | scenes/prestige_view.gd lines 22 (wait_time=3.0), 156-158 (_on_prestige_timer_timeout resets prestige_confirm_pending and calls _update_button_state) |
| 9 | Button disabled when can't afford | PASS | scenes/prestige_view.gd line 132: prestige_button.disabled = not PrestigeManager.can_prestige() |
| 10 | Static reset list visible | PASS | scenes/prestige_view.tscn lines 89-98: ResetListLabel with text "Prestige resets:\nArea progress, Equipment, Inventory,\nCurrencies, Tag Currencies" |
| 11 | prestige_triggered signal emitted | PASS | scenes/prestige_view.gd line 153: prestige_triggered.emit() after execute_prestige() + save_game() |

### Plan 02 Must-Haves

| # | Must-Have | Status | Evidence |
|---|-----------|--------|----------|
| 1 | P badge in tab bar shows "P{N}" | PASS | scenes/main_view.gd line 36: prestige_tab.text = "P" + str(GameState.prestige_level); also line 135 on reveal |
| 2 | Badge hidden at P0 | PASS | scenes/main.tscn line 38: visible = false; main_view.gd line 132: only reveals when prestige_level > 0 or can_prestige() |
| 3 | Badge appears when can_prestige() first returns true | PASS | scenes/main_view.gd lines 129-135: _check_prestige_tab_reveal checks can_prestige(), connected to currency_dropped signal at line 32 |
| 4 | Badge stays permanent once shown | PASS | scenes/main_view.gd line 130-131: prestige_tab_revealed flag checked first, never reset to false |
| 5 | show_view("prestige") works correctly | PASS | scenes/main_view.gd lines 114-120: prestige case shows prestige_view, manages all 4 tab disabled states, calls _update_display() |
| 6 | Fade to black 0.5s tween | PASS | scenes/main_view.gd lines 140-147: tween_property fade_rect color:a to 1.0 over 0.5s |
| 7 | Scene reload after fade | PASS | scenes/main_view.gd lines 147, 150-151: tween_callback to _do_prestige_reload which calls reload_current_scene() |
| 8 | Input blocked during fade | PASS | scenes/main_view.gd line 142: fade_rect.mouse_filter = 0 (STOP); FadeRect covers full 1280x720 in OverlayLayer at layer 10 |
| 9 | PUI-04 still works (tag section) | PASS | scenes/forge_view.gd line 279: tag_hammer_section.visible = (GameState.prestige_level >= 1), connected to prestige_completed signal |

## Requirement Coverage

| Req | Status | Evidence |
|-----|--------|----------|
| PRES-04 | PASS | Two-click confirmation flow (prestige_view.gd lines 137-147), static reset list in scene (prestige_view.tscn lines 89-98), cost shown in next_info_label, reward shown in next_reward_label |
| PUI-01 | PASS | Prestige tab badge "P{N}" visible in tab bar (main_view.gd lines 36, 132-135); visible at all times once revealed; at P0 before affording, prestige level is 0 so nothing meaningful to show (acceptable per plan spec) |
| PUI-02 | PASS | NextInfoLabel shows "Next: X Forge Hammers" cost, NextRewardLabel shows "Unlocks: Item Tier Y" (prestige_view.gd lines 38-46) |
| PUI-03 | PASS | 7-row unlock table built dynamically with level, tier, reward, cost columns and state indicators (prestige_view.gd lines 52-124) |
| PUI-04 | PASS | Tag hammer buttons gated on prestige_level >= 1 in forge_view.gd line 279; pre-satisfied by Phase 39, unchanged |
| PUI-05 | PASS | Prestige view shows cost (next_info_label), reward (next_reward_label), and static reset list (ResetListLabel) all visible together |

## Human Verification Needed

The following items require manual testing in Godot since they involve runtime behavior:

1. **Scene loads without errors** -- prestige_view.tscn parses correctly and all @onready node references resolve
2. **Unlock table renders correctly** -- 7 rows with proper column alignment, colors (green/white/grey), and status icons
3. **Two-click confirmation flow** -- first click shows "Reset progress?", 3-second timer resets text, second click within window triggers prestige
4. **Fade transition** -- 0.5s fade to black is visually smooth and input is properly blocked during transition
5. **Scene reload** -- after fade completes, scene reloads with updated prestige state
6. **Tab reveal** -- prestige tab appears when 100 forge hammers accumulated at P0, stays visible permanently
7. **Badge text update** -- after prestige, tab shows updated "P{N}" text on reload
8. **Button disabled state** -- button correctly reflects affordability as currency counts change

## Gaps

None. All planned must-haves and requirements are implemented in the code as specified.

## Summary

Phase 40 implementation matches the plans precisely. The prestige_view scene and script implement the full 7-level unlock table, status display, cost/reward info, static reset list, and two-click confirmation flow. The main scene and script integrate the prestige tab with dynamic reveal, 4-tab management, and fade-to-black transition with scene reload. All six requirements (PRES-04, PUI-01 through PUI-05) are covered. Status is "human_needed" because runtime behavior (visual rendering, tween animation, scene reload) cannot be verified from code alone.
