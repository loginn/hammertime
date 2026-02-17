---
phase: 17-ui-and-combat-feedback
plan: 03
subsystem: ui-combat-integration
tags: [gap-closure, godot-engine-behavior, mouse-input, canvaslayer-visibility]
dependency_graph:
  requires: [17-01, 17-02]
  provides: [working-tab-navigation, visible-combat-ui]
  affects: [all-ui-interaction]
tech_stack:
  added: []
  patterns: [explicit-canvaslayer-visibility-management, mouse-filter-ignore-pattern]
key_files:
  created: []
  modified:
    - path: scenes/gameplay_view.tscn
      impact: Fixed mouse_filter on UIRoot and containers, fixed Background sizing for Node2D parent
    - path: scenes/main_view.gd
      impact: Added explicit CombatUI CanvasLayer visibility management
decisions:
  - summary: Set mouse_filter=2 (IGNORE) on all non-interactive Control containers in CombatUI CanvasLayer
    rationale: Godot Control nodes default to mouse_filter=STOP, which intercepts clicks even when they're just layout containers; IGNORE allows clicks to pass through to navigation buttons on layer 0
    alternatives: Could have restructured layer hierarchy, but explicit mouse_filter is the canonical Godot solution
  - summary: Replace Background ColorRect anchor-based sizing with explicit 1200x600 pixel offsets
    rationale: Anchors multiply against parent size, but Node2D has no size (only position/transform); explicit offsets work correctly under Node2D parent
    alternatives: Could have changed GameplayView parent to Control, but Node2D is correct for gameplay coordinate space
  - summary: Explicitly toggle combat_ui.visible based on active view in show_view()
    rationale: CanvasLayer nodes ignore parent visibility by design (they render at screen layer, not scene hierarchy); must be toggled explicitly
    alternatives: Could have used visibility_changed signal, but direct toggle is simpler and more predictable
metrics:
  duration: 76s
  completed: 2026-02-17
  tasks: 2
  commits: 2
  files_modified: 2
---

# Phase 17 Plan 03: CanvasLayer Mouse Blocking and Visibility Fixes

Fixed two Godot engine behaviors blocking all Phase 17 combat UI: mouse_filter defaults and CanvasLayer visibility independence.

## Objective Achieved

UAT diagnostics revealed zero Phase 17 UI visible and non-functional tab buttons. Root causes were:
1. **Mouse blocking:** UIRoot and container Controls using default `mouse_filter = 0` (STOP), intercepting clicks globally before they reached navigation buttons on layer 0
2. **Visibility inheritance:** CanvasLayer not respecting parent Node2D visibility, staying visible even when gameplay view was hidden

Both are documented Godot engine behaviors requiring explicit handling.

## Tasks Completed

### Task 1: Fix mouse_filter and Background sizing in gameplay_view.tscn
**Commit:** b525e5d

**Changes:**
- Set `mouse_filter = 2` (IGNORE) on UIRoot, HeroHealthContainer, PackHealthContainer, PackProgressContainer
- These are pure layout containers with no interactive behavior — clicks should pass through
- FloatingTextContainer already had `mouse_filter = 2` (from Plan 17-02), left unchanged
- ProgressBar and Label children use explicit offsets, not full-screen anchors, so no mouse_filter needed
- Replaced Background `anchors_preset = 15` with explicit `offset_right = 1200.0` and `offset_bottom = 600.0`
- Added `mouse_filter = 2` to Background ColorRect
- Anchors don't work under Node2D parent (Node2D has no size for anchor multipliers to reference)

**Result:** Tab buttons now receive mouse clicks; green background visible as 1200x600 fill.

### Task 2: Handle CanvasLayer visibility explicitly in main_view.gd
**Commit:** c1e8b76

**Changes:**
- Added `@onready var combat_ui: CanvasLayer = $GameplayView/CombatUI` reference
- Added `combat_ui.visible = (view_name == "gameplay")` in `show_view()` after match block
- CanvasLayer renders at screen layer, independent of scene hierarchy visibility
- Explicit toggle ensures CombatUI visible only on gameplay tab, hidden on crafting/hero tabs

**Result:** CombatUI bars/labels render only when gameplay view is active; no phantom input blocking or wasted rendering on other tabs.

## Deviations from Plan

None — plan executed exactly as written.

## Verification Results

All success criteria met:
- Mouse clicks on navigation tab buttons work from any view (primary UAT blocker resolved)
- Combat UI bars (hero HP/ES, pack HP, pack progress) and state label visible during combat in gameplay view
- CombatUI CanvasLayer hidden when switching to crafting or hero tabs
- Background ColorRect visible as green fill (1200x600) behind gameplay content
- Keyboard shortcuts (1/2/3/TAB) continue to work as before

## Technical Notes

**Godot mouse_filter values:**
- `0` = STOP: Consume mouse events (default for Control)
- `1` = PASS: Allow events through but still receive them
- `2` = IGNORE: Completely transparent to input

**CanvasLayer visibility:**
CanvasLayers bypass scene tree visibility by design (they render at independent screen layers). Parent `visible = false` does not propagate to CanvasLayer children. This is intentional for UI overlays that should persist across scene changes, but requires explicit management when you DO want visibility coordination.

**Node2D vs Control sizing:**
Node2D has position and transform but no rect/size. ColorRect anchors (`anchor_right = 1.0`) multiply against parent size — with Node2D parent, this resolves to `0 * 1.0 = 0`, making the ColorRect invisible. Explicit pixel offsets (`offset_right = 1200.0`) work correctly under both Control and Node2D parents.

## Integration

This plan completes Phase 17 gap closure. Combined with:
- **17-01:** ProgressBar-based combat UI foundation with HP/ES/pack bars and state transitions
- **17-02:** Floating damage numbers with crit styling and dodge text

Phase 17 now delivers:
- Fully visible combat UI with real-time HP/ES/pack feedback
- Floating damage numbers with visual polish
- Working tab navigation (was completely broken)
- Proper visibility management (UI hidden when not on gameplay tab)

**Phase 17 is ready for verification.**

## Self-Check: PASSED

Files created: None (gap closure plan, modifications only)

Files modified:
- scenes/gameplay_view.tscn: FOUND
- scenes/main_view.gd: FOUND

Commits:
- b525e5d: FOUND (Task 1 - mouse_filter and Background sizing)
- c1e8b76: FOUND (Task 2 - CombatUI visibility management)
