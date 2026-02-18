---
phase: quick-2
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - scenes/gameplay_view.tscn
  - scenes/gameplay_view.gd
autonomous: true
requirements: [QUICK-2]

must_haves:
  truths:
    - "HP bars do not overlap with Start Combat / Next Area buttons"
    - "HP bars, pack HP bars, pack progress, and combat state label are properly spaced below buttons"
    - "Floating damage text appears above HP bars, not on top of buttons"
  artifacts:
    - path: "scenes/gameplay_view.tscn"
      provides: "Repositioned combat UI elements"
      contains: "offset_top"
    - path: "scenes/gameplay_view.gd"
      provides: "Updated floating text spawn positions"
      contains: "hero_damage_pos"
  key_links:
    - from: "scenes/gameplay_view.tscn"
      to: "scenes/gameplay_view.gd"
      via: "Node references and spawn positions must match new layout"
      pattern: "damage_pos.*Vector2"
---

<objective>
Fix the Adventure tab UI overlap where HP bars render on top of the Start Combat / Next Area buttons.

Purpose: The CombatUI uses a CanvasLayer (absolute screen coordinates) while the buttons are inside a Node2D offset by ContentArea (y=50). The HP bar containers at y=180 absolute overlap with buttons at y=150-200 absolute. All CombatUI elements need to shift down to clear the buttons.

Output: Properly spaced Adventure tab with buttons clearly separated from HP bars below them.
</objective>

<execution_context>
@/home/travelboi/.claude/get-shit-done/workflows/execute-plan.md
@/home/travelboi/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@scenes/gameplay_view.tscn
@scenes/gameplay_view.gd
@scenes/main.tscn
</context>

<tasks>

<task type="auto">
  <name>Task 1: Reposition CombatUI elements below buttons in gameplay_view.tscn and update floating text positions in gameplay_view.gd</name>
  <files>scenes/gameplay_view.tscn, scenes/gameplay_view.gd</files>
  <action>
The root cause: GameplayView is inside ContentArea (position y=50 in main.tscn). The buttons (StartClearingButton, NextAreaButton) are Node2D children, so they render at absolute y = 50 + 100 = 150 to 50 + 150 = 200. But CombatUI is a CanvasLayer (layer=1), which uses ABSOLUTE screen coordinates. HeroHealthContainer at offset_top=180 overlaps with buttons ending at y=200.

In `scenes/gameplay_view.tscn`, shift ALL CombatUI/UIRoot children down by 40px to clear the buttons:

1. **HeroHealthContainer**: Change offset_top from 180 to 220, offset_bottom from 210 to 250
2. **PackHealthContainer**: Change offset_top from 180 to 220, offset_bottom from 210 to 250
3. **PackProgressContainer**: Change offset_top from 230 to 270, offset_bottom from 255 to 295
4. **CombatStateLabel**: Change offset_top from 275 to 315, offset_bottom from 305 to 345

In `scenes/gameplay_view.gd`, update the floating text spawn positions to stay above the new HP bar positions:

5. **hero_damage_pos**: Change from Vector2(125.0, 160.0) to Vector2(125.0, 200.0)
6. **pack_damage_pos**: Change from Vector2(450.0, 160.0) to Vector2(450.0, 200.0)

This gives 20px clearance below buttons (absolute y=200) to HP bars (absolute y=220).
  </action>
  <verify>
Open the game, switch to Adventure tab, and visually confirm:
- The "Start Combat" and "Next Area" buttons are clearly visible with no HP bar overlap
- Click "Start Combat" — hero HP bar appears below buttons with clear separation
- Pack HP bar, pack progress bar, and combat state label are all below buttons
- Floating damage numbers appear above the HP bars, not on top of buttons
  </verify>
  <done>
All CombatUI elements (HP bars, labels, progress bars) render below the Start Combat / Next Area buttons with clear visual separation. No overlapping UI elements in the Adventure tab.
  </done>
</task>

</tasks>

<verification>
- Launch game, navigate to Adventure tab
- Verify area label, buttons, and HP bars are vertically stacked with no overlap
- Start combat and verify all dynamic elements (pack HP, progress, floating text) appear in correct positions below buttons
</verification>

<success_criteria>
- HP bars do not overlap with buttons at any point during gameplay
- All combat UI elements are clearly readable and properly spaced
- Floating damage text spawns above HP bars, not over buttons
</success_criteria>

<output>
After completion, create `.planning/quick/2-adventure-tab-ui-has-overlaps-move-hp-ba/2-SUMMARY.md`
</output>
