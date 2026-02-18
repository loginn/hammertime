---
status: resolved
trigger: "Investigate why the entire gameplay UI is not rendering in a Godot 4.5 GDScript game"
created: 2026-02-17T00:00:00Z
updated: 2026-02-17T00:01:00Z
symptoms_prefilled: true
goal: find_root_cause_only
---

## Current Focus

hypothesis: TWO root causes — CanvasLayer visibility independence + mouse_filter blocking
test: Traced scene structure, node properties, Godot engine behavior
expecting: Confirmed
next_action: Return diagnosis

## Symptoms

expected: Combat UI bars (HP, pack HP, progress), state labels, and tab buttons should all be visible and interactive
actual: No UI elements visible at all. Tab buttons don't respond to clicks. Keyboard shortcuts DO work. Combat logic runs fine.
errors: None reported
reproduction: Launch game, observe gameplay view - no bars, no labels, no working buttons
started: After Phase 17 rewrote gameplay_view.gd and gameplay_view.tscn

## Eliminated

- hypothesis: Node path references broken (@onready vars don't match .tscn)
  evidence: All @onready paths in gameplay_view.gd exactly match the node paths in gameplay_view.tscn (e.g., $CombatUI/UIRoot/HeroHealthContainer/HeroHPBar matches the scene tree)
  timestamp: 2026-02-17T00:00:30Z

- hypothesis: Scene file corruption / inconsistent node definitions
  evidence: .tscn file is well-formed with consistent parent references and valid ext_resource declarations
  timestamp: 2026-02-17T00:00:30Z

- hypothesis: Bars created programmatically but never added to scene tree
  evidence: Bars exist as nodes in .tscn file; _setup_bar_styles() only applies StyleBoxFlat overrides to existing nodes, doesn't create bars
  timestamp: 2026-02-17T00:00:30Z

- hypothesis: Tab button signals disconnected in main_view.gd
  evidence: main_view.gd _ready() correctly connects crafting_button.pressed, hero_button.pressed, gameplay_button.pressed. Signal connections are fine — the issue is mouse events never reach the buttons.
  timestamp: 2026-02-17T00:00:45Z

## Evidence

- timestamp: 2026-02-17T00:00:20Z
  checked: gameplay_view.tscn scene structure
  found: CombatUI is a CanvasLayer (layer=1) containing UIRoot (Control, anchors_preset=15 = full rect) with all combat UI bars as children
  implication: CanvasLayer renders independently from parent Node2D visibility

- timestamp: 2026-02-17T00:00:25Z
  checked: main_view.gd show_view() function
  found: show_view() sets gameplay_view.visible = false/true to toggle views. This only affects CanvasItem children, NOT CanvasLayer children (CanvasLayer does not inherit parent visibility - Godot issue #84912)
  implication: CombatUI CanvasLayer and its UIRoot are ALWAYS rendered and ALWAYS process input, regardless of which tab is active

- timestamp: 2026-02-17T00:00:30Z
  checked: UIRoot mouse_filter property in gameplay_view.tscn
  found: UIRoot has NO mouse_filter specified, defaulting to MOUSE_FILTER_STOP (0). Only FloatingTextContainer has mouse_filter=2 (IGNORE). UIRoot is a full-screen Control on CanvasLayer 1.
  implication: UIRoot intercepts ALL mouse clicks before they reach NavigationPanel buttons (on default layer 0). This is why tab buttons don't work but keyboard shortcuts do.

- timestamp: 2026-02-17T00:00:35Z
  checked: NavigationPanel position in main.tscn
  found: NavigationPanel is a ColorRect on the default canvas layer (layer 0), positioned at y=600..700. CombatUI UIRoot is on CanvasLayer 1 (rendered above layer 0) and covers the full viewport.
  implication: CanvasLayer 1 processes input before layer 0, so UIRoot eats all clicks

- timestamp: 2026-02-17T00:00:40Z
  checked: GameplayView Background ColorRect positioning
  found: Background has anchors_preset=15 (anchor_right=1.0, anchor_bottom=1.0) but parent is Node2D. Node2D has no size concept, so anchor multipliers resolve against 0. All offsets are 0, making Background a zero-size rect.
  implication: The green background of gameplay view is invisible (zero size)

- timestamp: 2026-02-17T00:00:45Z
  checked: Combat UI container visibility logic in update_display()
  found: hero_health_container.visible = combat_started_once (initially false), pack_health_container/pack_progress_container visible only during combat. CombatStateLabel ("Ready to fight.") is always visible under UIRoot.
  implication: CombatStateLabel should be visible even before combat starts, suggesting the label IS rendered but may not be perceived by user due to small size, or CanvasLayer rendering context issue

## Resolution

root_cause: |
  TWO interconnected root causes:

  ROOT CAUSE 1 (Tab buttons broken): The CombatUI CanvasLayer in gameplay_view.tscn contains a full-screen UIRoot Control (anchors_preset=15) on CanvasLayer layer=1. This UIRoot has the default mouse_filter=MOUSE_FILTER_STOP, which intercepts ALL mouse click events across the entire viewport. Because CanvasLayer does not inherit visibility from its parent Node2D (known Godot engine behavior, issue #84912), the UIRoot is ALWAYS active regardless of which view is shown. Since layer 1 processes input before layer 0, the NavigationPanel buttons never receive mouse clicks. Keyboard shortcuts bypass this because they use _input() directly.

  ROOT CAUSE 2 (UI elements invisible): The GameplayView root node is Node2D, but several Control children (Background ColorRect, Title Label) use anchor-based positioning (anchors_preset=15, anchor_top=1.0, etc.). Node2D has no size concept, so anchor multipliers resolve to 0, making anchor-dependent Controls zero-sized or positioned at (0,0) regardless of their intended layout. The CanvasLayer children should theoretically render (anchors resolve against viewport under CanvasLayer), but the lack of visible background and mispositioned title contribute to the perception of "nothing rendering." Additionally, most combat UI containers start hidden (combat_started_once=false) until combat begins, and the user cannot start combat because the Start Combat button click is intercepted by UIRoot.

fix:
verification:
files_changed: []
