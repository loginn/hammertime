# Phase 40: Prestige UI — Research

**Researched:** 2026-03-06
**Phase Goal:** Player can see their prestige status at all times, understand exactly what a prestige costs and rewards, view the full 7-level unlock table, and trigger prestige through a confirmation flow that lists everything that resets

## Executive Summary

Phase 40 adds a dedicated Prestige tab (4th tab in the tab bar) containing a prestige status display, a 7-level unlock table, a "what resets" list, and a two-click prestige trigger button with fade-to-black transition. The tab bar also gets a "P{N}" badge that doubles as the tab button, hidden at P0 and shown once the player can first afford prestige or has already prestiged. All backend logic (PrestigeManager, GameState, GameEvents) is already complete from Phase 35 — this phase is purely UI.

## Existing Patterns

### Tab System

`main_view.gd` manages three views via `show_view(view_name: String)`:
- Three `@onready` references: `forge_view`, `gameplay_view`, `settings_view`
- Three tab buttons: `forge_tab`, `combat_tab`, `settings_tab` (children of `TabBar` ColorRect)
- `show_view()` hides all three views, then shows the selected one. The active tab button is `disabled = true` (visual indicator), others are `disabled = false`.
- Special handling: `combat_ui` (a CanvasLayer) gets explicit visibility sync since CanvasLayers don't inherit parent visibility.
- Keyboard shortcuts: KEY_1 = forge, KEY_2 = combat, KEY_TAB toggles forge/combat. No shortcut for settings.
- `settings_view.reset_state()` is called when navigating away from settings.

**Adding a 4th tab requires:**
1. New `@onready var prestige_view` reference and `@onready var prestige_tab` button reference
2. `prestige_tab.pressed.connect(_on_prestige_tab_pressed)` in `_ready()`
3. New `"prestige"` case in `show_view()` match block — show prestige_view, set prestige_tab disabled, enable other three
4. All existing cases must also set `prestige_tab.disabled = false`
5. PrestigeView scene instanced in `ContentArea` in `main.tscn`
6. PrestigeTab button added to `TabBar` in `main.tscn`

**Tab bar layout in main.tscn:**
- ForgeTab: x=10 to x=130 (120px wide)
- CombatTab: x=140 to x=260 (120px wide)
- SettingsTab: x=1150 to x=1270 (right-aligned, 120px wide)
- Tab bar height: 50px
- A prestige tab could sit at ~x=270 to ~x=330 (narrower since "P3" is short text), or right-aligned near settings

### View Architecture

`settings_view.tscn` + `settings_view.gd` is the simplest view:
- **Scene**: Root `Node2D` with script. Background `ColorRect` (1280x670, dark, mouse_filter=2 to pass clicks through). Child nodes are Labels, Buttons, and a TextEdit — all positioned via absolute offsets.
- **Script**: `extends Node2D`. Declares a `signal new_game_started()`. `@onready` references for all interactive nodes. `_ready()` connects button signals. Business logic in handler functions. `reset_state()` function for cleanup when navigating away.
- **Content area**: Views occupy 1280x670 (full width, below 50px tab bar). The ContentArea node is at position Vector2(0, 50).

**Pattern for new prestige_view:**
- `scenes/prestige_view.tscn`: Root Node2D, script, background ColorRect 1280x670
- `scenes/prestige_view.gd`: extends Node2D, signal for prestige-triggered reload, @onready refs, connect buttons in _ready(), reset_state() for cleanup

### Two-Click Confirmation

`forge_view.gd` equip confirmation pattern (lines 63-66, 473-519):
- State: `var equip_confirm_pending: bool = false`
- Timer: `var equip_timer: Timer` — created in `_ready()` as `Timer.new()`, one_shot=true, wait_time=3.0, timeout connected to reset callback
- First click: sets `equip_confirm_pending = true`, changes button text to "Confirm Overwrite?", starts timer
- Second click: executes action, resets state
- Timer timeout: resets `equip_confirm_pending = false`, restores original button text
- Multiple places reset the state (switching items, melting, selecting currency)

`settings_view.gd` has a simpler variant (no timer):
- `_new_game_confirming: bool = false`
- First click: set true, change text to "Are you sure?"
- Second click: execute delete + initialize + save + emit signal
- `reset_state()` resets the bool and text

**For prestige button:** Use the timer variant (3s timeout), button text "Upgrade your forge" -> "Reset progress?" -> execute_prestige().

### Scene Reload

`settings_view.gd` `_on_new_game_pressed()`:
1. Calls `SaveManager.delete_save()`, `GameState.initialize_fresh_game()`, `SaveManager.save_game()`
2. Emits `new_game_started` signal

`main_view.gd` `_on_new_game_started()`:
1. Connected in `_ready()`: `settings_view.new_game_started.connect(_on_new_game_started)`
2. Handler: `get_tree().reload_current_scene()`

**For prestige reload:**
- prestige_view emits a signal (e.g., `prestige_triggered`)
- main_view connects to it and calls `get_tree().reload_current_scene()`
- Before emitting: `PrestigeManager.execute_prestige()` (which internally calls `_wipe_run_state()`), then `SaveManager.save_game()` (prestige auto-save per SAVE-02), then emit signal
- Note: `execute_prestige()` already emits `GameEvents.prestige_completed` — but we need the scene reload to happen AFTER the fade transition, so the prestige_view controls timing

## Technical Approach

### Prestige View Scene

**Node tree for `prestige_view.tscn`:**
```
PrestigeView (Node2D, script)
  Background (ColorRect, 1280x670, dark)
  TitleLabel (Label, "Prestige", centered)
  StatusSection (VBoxContainer or manual Labels)
    CurrentLevelLabel ("Current Prestige: P{N}")
    NextCostLabel ("Next: 100 Forge Hammers" or "Max Prestige Reached")
    NextRewardLabel ("Unlocks: Item Tier 7")
  UnlockTable (VBoxContainer)
    Row1..Row7 (HBoxContainer children with Labels)
  ResetListLabel (Label, static text listing what resets)
  PrestigeButton (Button, "Upgrade your forge")
  PrestigeTimer (created in script, not in scene)
```

**Layout within 1280x670:**
- Title at top, centered
- Status section: left-center area, ~y=80
- Unlock table: center area, ~y=180, 7 rows
- Reset list: below table, ~y=480
- Prestige button: bottom area, ~y=580, centered, prominent

### Tab Bar Integration

**P badge/tab button:**
- Add a Button node to TabBar in `main.tscn`, positioned after CombatTab (e.g., x=270) or near SettingsTab
- Text: "P{N}" where N is `GameState.prestige_level`
- Starts hidden (`visible = false`)

**Visibility gating logic (in main_view.gd):**
- In `_ready()`: check if prestige tab should be visible
  - Show if `GameState.prestige_level > 0` (already prestiged) OR `PrestigeManager.can_prestige()` (can afford first prestige)
  - Once shown, never re-hide (set a flag or just never call hide again)
- Connect to `GameEvents.prestige_completed` to update badge text
- Connect to currency signals to check `can_prestige()` threshold for first reveal
- The tab must also update dynamically when currencies change (player farms enough forge hammers to afford P1)

**Dynamic reveal approach:**
- `main_view.gd` stores `var prestige_tab_revealed: bool = false`
- On currency changes (`GameEvents.currency_dropped`), check `if not prestige_tab_revealed and (GameState.prestige_level > 0 or PrestigeManager.can_prestige()): _reveal_prestige_tab()`
- `_reveal_prestige_tab()` sets `prestige_tab.visible = true`, `prestige_tab_revealed = true`

**Badge text update:**
- `prestige_tab.text = "P" + str(GameState.prestige_level)` — update in `_ready()` and after prestige_completed

### Unlock Table

**Structure: VBoxContainer with 7 rows, each an HBoxContainer.**

Each row contains 4-5 Labels:
1. Status indicator: checkmark for completed, arrow for current, lock for future
2. Level: "P1", "P2", etc.
3. Item tier unlock: "Tier 7", "Tier 6", etc. (from `ITEM_TIERS_BY_PRESTIGE`)
4. Reward text: P1 shows "Tag Hammers", others show tier-only for now
5. Cost: show actual cost for next level only, "???" for future levels, actual cost for completed levels

**Row state styling:**
- Completed (level < prestige_level): green/dimmed text, checkmark
- Current (level == prestige_level + 1 AND can_prestige): highlighted, arrow, show cost
- Next (level == prestige_level + 1 AND !can_prestige): normal text, show cost
- Future (level > prestige_level + 1): grey/locked text, "???" for cost

**Implementation:** Build rows dynamically in `_ready()` or a `_build_unlock_table()` function by iterating 1..7 and comparing against `GameState.prestige_level`. This avoids hardcoding 7 row scenes.

### Confirmation Flow

```
State: prestige_confirm_pending: bool = false
Timer: prestige_timer (Timer, one_shot, wait_time=3.0)

_on_prestige_pressed():
  if not PrestigeManager.can_prestige():
    return  # button should be disabled, but guard anyway
  if not prestige_confirm_pending:
    prestige_confirm_pending = true
    prestige_button.text = "Reset progress?"
    prestige_timer.start()
  else:
    prestige_confirm_pending = false
    prestige_timer.stop()
    _execute_prestige_with_fade()
```

Button disabled state: `prestige_button.disabled = not PrestigeManager.can_prestige()`. Updated when view becomes visible and on currency change signals.

### Fade Transition

**Approach: ColorRect overlay + Tween**

A full-screen ColorRect (1280x720) at Color(0, 0, 0, 0) (transparent black). On prestige trigger:
1. Create tween: `var tween = create_tween()`
2. Fade in: `tween.tween_property(fade_rect, "color:a", 1.0, 0.5)` — 0.5s to opaque black
3. On complete: `tween.tween_callback(_do_prestige_reload)`

**Where it lives:** Best placed in `main.tscn` OverlayLayer (CanvasLayer at layer 10, already exists for SaveToast). This ensures it covers all views including the tab bar. The prestige_view emits a signal, main_view handles the fade + reload.

Alternative: Place in prestige_view.tscn. But since it needs to cover the tab bar (layer 0), it would need its own CanvasLayer. The main.tscn OverlayLayer approach is cleaner.

**Recommended:** Add a `FadeRect` (ColorRect, 1280x720, Color(0,0,0,0), visible=false, mouse_filter=IGNORE) to `OverlayLayer` in `main.tscn`. main_view.gd handles fade logic triggered by prestige_view signal.

### Post-Prestige Reload

**Signal flow:**
1. prestige_view: user confirms prestige -> emits `prestige_triggered` signal
2. main_view: connected handler `_on_prestige_triggered()`:
   a. `PrestigeManager.execute_prestige()` — wipes state, emits `GameEvents.prestige_completed`
   b. `SaveManager.save_game()` — prestige auto-save
   c. Start fade tween on FadeRect
   d. Tween callback: `get_tree().reload_current_scene()`

**Alternative ordering consideration:** execute_prestige() could be called in prestige_view before emitting the signal. This keeps the prestige_view responsible for the action and main_view only handles the visual transition + reload. Either works, but keeping execute_prestige() in prestige_view is more consistent with settings_view calling delete_save/initialize_fresh_game before emitting new_game_started.

**Revised flow:**
1. prestige_view `_execute_prestige_with_fade()`:
   a. `PrestigeManager.execute_prestige()`
   b. `SaveManager.save_game()`
   c. Emit `prestige_triggered` signal
2. main_view `_on_prestige_triggered()`:
   a. Fade tween
   b. `get_tree().reload_current_scene()`

## Validation Architecture

### Dimension 8: Verification Strategy

| Requirement | Verification |
|---|---|
| **PUI-01** (prestige level visible at all times) | P badge in tab bar shows "P{N}" and is visible when prestige_level > 0. At P0 before affording prestige, badge is hidden (acceptable — no prestige to show). |
| **PUI-02** (see cost and next unlock) | Prestige view shows "Next: {cost}" and "Unlocks: Item Tier {N}" labels. Verified by reading label text at P0 with 100+ forge hammers. |
| **PUI-03** (7-level unlock table) | VBoxContainer with 7 rows, each showing level/tier/reward/cost. Verified by visual inspection at various prestige levels. |
| **PUI-04** (tag hammer buttons after P1) | Already implemented in Phase 39 (`_update_tag_section_visibility()` gates on prestige_level >= 1). This requirement is already met — verify it still works. |
| **PUI-05** (confirmation shows cost, reward, reset list) | Prestige view shows cost in status section, reward in next-unlock label, static reset list label. Two-click confirm ensures player sees all info before committing. |
| **PRES-04** (confirmation dialog) | Two-click "Upgrade your forge" -> "Reset progress?" pattern with 3s timer. Reset list always visible in the view. |

## Key Risks

1. **Tab bar crowding**: Adding a 4th button to the tab bar at 1280px width. ForgeTab and CombatTab occupy x=10-260 (left), SettingsTab is at x=1150-1270 (right). There's ~890px of gap. A prestige tab at x=270-340 fits easily, but the dynamic show/hide means layout doesn't shift — just appears.

2. **show_view() disabled state management**: Every case in the match block must set all 4 tab buttons. Missing one would leave a button stuck in disabled state. The pattern is straightforward but the 4th button adds to each case.

3. **CanvasLayer visibility for fade**: The FadeRect in OverlayLayer doesn't need special visibility sync since it's a ColorRect inside a CanvasLayer that stays visible. Just need to ensure mouse_filter = IGNORE so it doesn't block input before fading.

4. **Scene reload timing**: The tween must complete before reload_current_scene() is called. Using tween_callback ensures this. But if the tween is interrupted (e.g., by input), the reload might not fire. Setting FadeRect mouse_filter to STOP during fade prevents interaction.

5. **PUI-04 already done**: Tag hammer button visibility was implemented in Phase 39. This phase just needs to not regress it. No new work needed for PUI-04.

6. **Currency signal for tab reveal**: Need to connect to the right signal to detect when player can first afford prestige. `GameEvents.currency_dropped` fires per-pack. forge_view's `on_currencies_found()` is a local signal. main_view already receives `gameplay_view.currencies_found` — could piggyback on that, or connect directly to `GameEvents.currency_dropped`.

## Implementation Estimate

**2 plans recommended** (matching roadmap):

**Plan 40-01: Prestige View + Confirmation Flow**
- Create `prestige_view.tscn` and `prestige_view.gd`
- Unlock table (7 rows, dynamic state indicators)
- Status section (current level, next cost, next reward)
- Reset list (static label)
- Two-click prestige button with timer
- Execute prestige + save on confirm
- Emit signal for main_view to handle reload
- ~4 tasks: scene creation, unlock table logic, confirmation flow, prestige execution

**Plan 40-02: Tab Integration + Fade Transition + Reload**
- Add PrestigeTab button to TabBar in main.tscn
- Add PrestigeView instance to ContentArea in main.tscn
- Add FadeRect to OverlayLayer in main.tscn
- Update main_view.gd: 4th tab in show_view(), prestige_tab reveal logic, prestige_triggered handler, fade tween, reload
- Update prestige_tab text on prestige_completed
- ~3 tasks: main.tscn nodes, main_view.gd tab logic, fade + reload flow

---
*Research completed: 2026-03-06*
*Phase: 40-prestige-ui*
