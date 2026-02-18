# Plan 18-02 Summary: Auto-save, Event Triggers, Toast UI, Settings Menu, Startup Flow

## What was done

### Task 1: Auto-save timer and event-driven save triggers
- Added `AUTO_SAVE_INTERVAL = 300.0` (5 minutes) constant and Timer-based auto-save to SaveManager
- Connected event-driven save triggers: `item_crafted`, `equipment_changed`, `area_cleared`
- Implemented debounced save with `_save_pending` flag and `call_deferred("_deferred_save")` to prevent duplicate saves within same frame
- Added `save_completed` and `save_failed` signals to GameEvents
- `_deferred_save()` emits appropriate signal after save attempt

### Task 2: Save toast, settings menu, startup flow, and New Game
- Created `scenes/save_toast.tscn` + `save_toast.gd` — Label-based toast anchored top-right, connects to save_completed/save_failed signals, shows message with 1s hold + 0.5s fade-out tween
- Toast checks `GameState.save_was_corrupted` on `_ready()` for startup corruption warning
- Created `scenes/settings_menu.tscn` + `settings_menu.gd` — PanelContainer with VBoxContainer containing Settings title, Save Game, New Game (double-confirm), and Close buttons
- New Game first click changes text to "Are you sure?", second click wipes save and resets
- Added `OverlayLayer` CanvasLayer (layer 10) to `scenes/main.tscn` with SaveToast and SettingsMenu as children for rendering above all views
- Added Settings button to NavigationPanel (right-aligned)
- Connected settings_button.pressed to settings_menu.open_menu() in main_view.gd
- Connected settings_menu.new_game_started to `get_tree().reload_current_scene()` for full reset

## Files modified
- `autoloads/save_manager.gd` — added auto-save timer, event-driven triggers, debounce logic
- `autoloads/game_events.gd` — added save_completed, save_failed signals
- `scenes/save_toast.gd` — NEW: toast notification script
- `scenes/save_toast.tscn` — NEW: toast notification scene
- `scenes/settings_menu.gd` — NEW: settings menu logic
- `scenes/settings_menu.tscn` — NEW: settings menu scene
- `scenes/main_view.gd` — added settings button and menu wiring
- `scenes/main.tscn` — added SettingsButton, OverlayLayer, SaveToast, SettingsMenu

## Commit
`03ed737` — feat: add auto-save, event triggers, toast UI, settings menu, and startup flow
