---
phase: quick-6
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - models/combat/combat_engine.gd
  - scenes/gameplay_view.gd
autonomous: true
requirements: [QUICK-6]

must_haves:
  truths:
    - "When player clicks Stop Combat, hero HP restores to max_health"
    - "When player clicks Stop Combat, hero ES restores to total_energy_shield"
    - "When player switches away from the combat tab during active combat, combat stops and hero HP/ES are fully restored"
    - "When combat ends naturally (map complete or hero death), existing behavior is unchanged"
  artifacts:
    - path: "models/combat/combat_engine.gd"
      provides: "HP/ES restoration in stop_combat()"
      contains: "health = max_health"
    - path: "scenes/gameplay_view.gd"
      provides: "Stop combat on tab leave via _on_combat_stopped handler"
  key_links:
    - from: "models/combat/combat_engine.gd"
      to: "models/hero.gd"
      via: "stop_combat restores hero HP and ES before emitting combat_stopped"
      pattern: "GameState\\.hero\\.health = GameState\\.hero\\.max_health"
    - from: "scenes/gameplay_view.gd"
      to: "models/combat/combat_engine.gd"
      via: "stop_combat_and_restore called when leaving combat tab"
      pattern: "combat_engine\\.stop_combat"
---

<objective>
Restore hero HP and energy shield to maximum when combat stops.

Purpose: Currently when the player stops combat (via button or tab switch), the hero retains whatever damaged HP/ES they had. The hero should return to full health and full energy shield whenever combat ends by player action.

Output: Modified combat_engine.gd and gameplay_view.gd
</objective>

<execution_context>
@/home/travelboi/.claude/get-shit-done/workflows/execute-plan.md
@/home/travelboi/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@models/combat/combat_engine.gd
@models/hero.gd
@scenes/gameplay_view.gd
@scenes/main_view.gd
</context>

<tasks>

<task type="auto">
  <name>Task 1: Restore HP/ES on combat stop and tab leave</name>
  <files>models/combat/combat_engine.gd, scenes/gameplay_view.gd</files>
  <action>
In `models/combat/combat_engine.gd`, modify `stop_combat()` (currently lines 46-49) to restore hero HP and ES to max before emitting the signal:

```gdscript
func stop_combat() -> void:
    _stop_timers()
    state = State.IDLE
    # Restore hero to full HP and ES when combat is stopped by player
    GameState.hero.health = GameState.hero.max_health
    GameState.hero.current_energy_shield = float(GameState.hero.total_energy_shield)
    GameEvents.combat_stopped.emit()
```

This is the same pattern already used in `_on_map_completed()` (lines 167-168) and `Hero.revive()` (lines 68-71).

In `scenes/gameplay_view.gd`, modify `_on_start_combat_pressed()` to handle the button-stop case (this already calls `combat_engine.stop_combat()` so the HP/ES restore happens via the engine change above — no change needed here).

However, we also need to handle the case where the player leaves the combat tab while combat is active. Add a public method that main_view.gd can call, OR handle it within gameplay_view itself. The simplest approach: override `_notification()` in gameplay_view.gd to detect when visibility changes, and stop combat if it becomes invisible while combat is active:

Add to `scenes/gameplay_view.gd` after the `_ready()` function:

```gdscript
func _notification(what: int) -> void:
    if what == NOTIFICATION_VISIBILITY_CHANGED:
        if not visible and is_combat_active:
            is_combat_active = false
            combat_engine.stop_combat()
            start_clearing_button.text = "Start Combat"
```

This catches all cases: tab switching via button clicks, keyboard shortcuts (1/2/Tab), and settings tab. The `stop_combat()` call triggers the HP/ES restore we added above.

NOTE: Do NOT use `visibility_changed` signal on Node2D — use `_notification(NOTIFICATION_VISIBILITY_CHANGED)` which works on Node2D.
  </action>
  <verify>
  1. Launch game, start combat, let hero take damage (HP < max), click Stop Combat — hero HP and ES should show max values in the UI.
  2. Start combat again, let hero take damage, press keyboard "1" to switch to forge tab, then press "2" to return — combat should be stopped and hero HP/ES at max.
  3. Start combat, let it run through map completion — verify auto-advance still works (existing behavior unchanged since _on_map_completed already restores HP/ES).
  4. Start combat, let hero die — verify auto-retry still works (existing behavior unchanged since revive() already restores HP/ES).
  </verify>
  <done>
  - Clicking "Stop Combat" restores hero to full HP and full ES
  - Switching tabs away from combat while combat is active stops combat and restores hero to full HP and full ES
  - Map completion and hero death auto-retry behavior remain unchanged
  - UI correctly reflects restored HP/ES values after combat stops
  </done>
</task>

</tasks>

<verification>
- stop_combat() in combat_engine.gd contains `GameState.hero.health = GameState.hero.max_health` and `GameState.hero.current_energy_shield = float(GameState.hero.total_energy_shield)` before `GameEvents.combat_stopped.emit()`
- gameplay_view.gd contains `_notification` handler that stops combat when visibility is lost during active combat
- Existing _on_map_completed and _on_hero_died paths are not modified
</verification>

<success_criteria>
Hero HP and ES are restored to maximum whenever combat stops by player action (button or tab switch). Existing combat loop behavior (map completion, death/retry) is unaffected.
</success_criteria>

<output>
After completion, create `.planning/quick/6-on-stopping-combat-hero-should-go-back-t/6-SUMMARY.md`
</output>
