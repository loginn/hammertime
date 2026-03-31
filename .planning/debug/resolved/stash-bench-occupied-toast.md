---
status: resolved
trigger: "Melt or equip first error toast does not appear when tapping stash slot while crafting bench is occupied"
created: 2026-03-31T00:00:00Z
updated: 2026-03-31T00:00:00Z
---

## Current Focus

hypothesis: Stash slot buttons are disabled when bench is occupied, preventing pressed signal from firing, so _on_stash_slot_pressed guard and toast are never reached
test: Read _update_stash_display and confirm btn.disabled = true when crafting_bench != null
expecting: Disabled buttons suppress pressed signal, making the toast code dead
next_action: return diagnosis

## Symptoms

expected: Tapping a stash slot while bench has an item shows "Melt or equip first" error toast
actual: No toast appears; button appears disabled/unresponsive
errors: (none — silent failure)
reproduction: Place item on bench, tap any populated stash slot
started: Since Phase 57 implementation

## Eliminated

(none — root cause confirmed on first hypothesis)

## Evidence

- timestamp: 2026-03-31
  checked: forge_view.gd _on_stash_slot_pressed() (lines 406-410)
  found: Guard checks GameState.crafting_bench != null and calls _show_forge_error("Melt or equip first"). The function and toast system both work correctly.
  implication: The toast code is correct but may not be reachable.

- timestamp: 2026-03-31
  checked: forge_view.gd _update_stash_display() (lines 384-399)
  found: Line 394 sets btn.disabled = (GameState.crafting_bench != null) for every populated stash slot. Disabled Godot buttons do NOT emit the pressed signal.
  implication: When bench is occupied, buttons are disabled BEFORE user can tap them. The pressed signal never fires, so _on_stash_slot_pressed is never called, and the toast is never shown.

- timestamp: 2026-03-31
  checked: forge_view.gd _show_forge_error() (lines 300-307)
  found: Function correctly sets forge_error_toast text, modulate with alpha=1, visible=true, and animates fade-out. Implementation is sound.
  implication: Toast system works; it is simply never invoked for this case.

## Resolution

root_cause: _update_stash_display() at line 394 disables stash slot buttons when crafting_bench is occupied (btn.disabled = true). Disabled Godot buttons do not emit the pressed signal. This prevents _on_stash_slot_pressed from ever being called, making the bench-occupied guard and _show_forge_error("Melt or equip first") toast unreachable dead code.
fix: (diagnosis only — not applied)
verification: (diagnosis only)
files_changed: []
