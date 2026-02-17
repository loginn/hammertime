---
phase: 19-side-by-side-layout
plan: 02
subsystem: ui-main-navigation
tags: [ui, navigation, tab-bar, settings, signal-wiring]
dependency-graph:
  requires: [19-01-forge-view, game-state, game-events, save-manager]
  provides: [top-tab-bar, settings-tab-view, 3-view-navigation, cross-view-signals]
  affects: [main-scene, navigation-flow, settings-workflow, combat-visibility]
tech-stack:
  added: []
  patterns: [tab-bar-navigation, canvas-layer-sync, view-reset-on-leave]
key-files:
  created:
    - scenes/settings_view.tscn
    - scenes/settings_view.gd
  modified:
    - scenes/main.tscn
    - scenes/main_view.gd
    - scenes/gameplay_view.tscn
decisions:
  - decision: "Use disabled button state for active tab indicator instead of custom styling"
    rationale: "Matches existing pattern from old NavigationPanel, simple and clear"
  - decision: "Settings is a full-screen tab view, not a modal overlay"
    rationale: "Per CONTEXT.md: Settings replaces the modal PanelContainer pattern with a proper tab"
requirements-completed:
  - LAYOUT-02
metrics:
  duration: 45
  completed: 2026-02-17
---

# Phase 19 Plan 02: MainView Tab Bar and View Wiring Summary

**One-liner:** Rebuilt MainView with top tab bar navigation (The Forge, Combat, Settings), replaced bottom NavigationPanel and modal settings, wired all cross-view signals.

## What Changed

### SettingsView (scenes/settings_view.tscn + settings_view.gd)
Created full-screen settings view replacing the modal PanelContainer settings_menu:
- Dark background (#1a1a1a) matching ForgeView theme
- Centered Save Game and New Game buttons
- Double-confirm New Game (first click = "Are you sure?", second click = wipe + restart)
- `reset_state()` method called when navigating away from Settings tab
- Version label at bottom ("Hammertime v1.3")

### GameplayView (scenes/gameplay_view.tscn)
- Updated Background ColorRect from 1200x600 to 1280x670 for new viewport dimensions

### MainView Scene (scenes/main.tscn)
Replaced entire structure:
- **Removed:** NavigationPanel (bottom bar), CraftingButton, HeroButton, GameplayButton, SettingsButton, HelpLabel
- **Removed:** CraftingView instance, HeroView instance, SettingsMenu instance
- **Added:** TabBar (ColorRect at y=0, h=40, dark #2b2b2b)
  - ForgeTab (x=10, "The Forge") — left-aligned
  - CombatTab (x=140, "Combat") — left-aligned
  - SettingsTab (x=1150, "Settings") — right-aligned
- **Added:** ContentArea (Node2D at y=50) containing ForgeView, GameplayView, SettingsView instances
- **Preserved:** OverlayLayer (CanvasLayer layer=10) with SaveToast

### MainView Script (scenes/main_view.gd)
Rewrote from 104 lines to 97 lines:
- 3 views (forge, combat, settings) instead of 3 views + modal
- Tab button connections: forge_tab, combat_tab, settings_tab
- Cross-view signal wiring:
  - `forge_view.equipment_changed` -> `gameplay_view.refresh_clearing_speed`
  - `gameplay_view.item_base_found` -> `forge_view.set_new_item_base`
  - `gameplay_view.currencies_found` -> `forge_view.on_currencies_found`
- CanvasLayer visibility sync preserved for CombatUI
- Keyboard shortcuts: KEY_1=Forge, KEY_2=Combat, KEY_3=Settings, TAB cycles
- `settings_view.reset_state()` called when navigating away from settings
- Default view: "forge"

## Deviations from Plan

None - plan executed exactly as written.

## Commits

| Hash | Message |
|------|---------|
| bcbbfd4 | feat(19-02): create SettingsView and update GameplayView for 1280x720 viewport |
| ae7b526 | feat(19-02): rebuild MainView with top tab bar and wire all views |

## Files Changed

**Created (2):**
- scenes/settings_view.tscn
- scenes/settings_view.gd

**Modified (3):**
- scenes/main.tscn
- scenes/main_view.gd
- scenes/gameplay_view.tscn

## Self-Check

### Created Files
- scenes/settings_view.tscn: FOUND
- scenes/settings_view.gd: FOUND

### Modified Files
- scenes/main.tscn: FOUND
- scenes/main_view.gd: FOUND
- scenes/gameplay_view.tscn: FOUND

### Commits
- bcbbfd4: FOUND
- ae7b526: FOUND

## Self-Check: PASSED
