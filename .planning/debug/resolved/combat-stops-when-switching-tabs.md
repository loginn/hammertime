---
status: resolved
trigger: "combat-stops-when-switching-tabs - Combat stops when switching away from the Adventure tab — regression from quick task 6"
created: 2026-02-18T00:00:00Z
updated: 2026-02-18T00:04:00Z
---

## Current Focus

hypothesis: CONFIRMED - _notification(VISIBILITY_CHANGED) handler stops combat when view becomes invisible
test: Remove the _notification() handler entirely
expecting: Combat will continue running in background when switching tabs
next_action: Remove lines 39-44 from gameplay_view.gd

## Symptoms

expected: Combat should continue running silently in the background when switching to another tab (Forge, Settings)
actual: Combat stops immediately when leaving the Adventure tab
errors: None (behavioral regression, not a crash)
reproduction: Start combat in Adventure tab, switch to Forge tab — combat stops
started: Started after quick task 6 which added a _notification(VISIBILITY_CHANGED) handler to gameplay_view.gd that calls stop_combat() when the view becomes invisible

## Eliminated

## Evidence

- timestamp: 2026-02-18T00:01:00Z
  checked: scenes/gameplay_view.gd lines 39-44
  found: _notification(NOTIFICATION_VISIBILITY_CHANGED) handler that stops combat when not visible
  implication: This is the root cause - when tab changes, gameplay_view becomes invisible, triggering combat stop

- timestamp: 2026-02-18T00:02:00Z
  checked: models/combat/combat_engine.gd stop_combat() function (lines 46-52)
  found: HP/ES restore logic already exists correctly in stop_combat() - restores hero.health to max_health and current_energy_shield to total_energy_shield
  implication: The HP/ES restore functionality is correctly placed - it happens when player manually stops combat, not on tab switch

## Resolution

root_cause: Quick task 6 added a _notification(NOTIFICATION_VISIBILITY_CHANGED) handler to gameplay_view.gd (lines 39-44) that automatically stopped combat when the view became invisible (i.e., when switching tabs). This was meant to restore HP/ES on tab leave, but the correct approach is to let combat continue in background and only restore HP/ES when player manually stops combat.
fix: Removed the _notification() handler entirely from gameplay_view.gd. The HP/ES restore logic already exists correctly in combat_engine.stop_combat() (lines 50-51), so when the player manually stops combat via the button, they get full HP/ES back.
verification: Manual testing - start combat in Adventure tab, switch to Forge tab, combat should continue running in background (CombatEngine timers continue firing), switch back to Adventure tab and see combat still active with progressing bars.
files_changed: ["scenes/gameplay_view.gd"]
