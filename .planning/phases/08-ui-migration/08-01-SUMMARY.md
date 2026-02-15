---
phase: 08-ui-migration
plan: 01
subsystem: ui-crafting
tags: [ui, currency-system, crafting, button-migration]
dependency-graph:
  requires: [phase-07-drop-integration, currency-models, game-state]
  provides: [currency-button-ui, direct-currency-application]
  affects: [crafting-view, scene-layout]
tech-stack:
  added: []
  patterns: [currency-selection, validation-before-consumption, button-state-management]
key-files:
  created: []
  modified:
    - scenes/node_2d.tscn
    - scenes/crafting_view.gd
decisions: []
metrics:
  duration: 190
  completed: 2026-02-15
---

# Phase 08 Plan 01: Currency Button Migration Summary

**One-liner:** Replaced legacy 3-hammer button system with 6 direct currency buttons using Currency.apply() validation pattern and GameState inventory.

## Overview

Successfully migrated the crafting UI from the legacy 3-button hammer system (Implicit/Prefix/Suffix) to 6 currency-specific buttons (Runic, Forge, Tack, Grand, Claw, Tuning). This completes the v1.0 Crafting Overhaul by connecting the UI directly to the currency system implemented in Phases 6-7.

The migration eliminates all temporary mapping logic and establishes the Currency.apply() pattern as the standard interface for item modification.

## What Changed

### Scene Structure (node_2d.tscn)

**Removed:**
- ImplicitHammer button
- AddPrefixHammer button
- AddSuffixHammer button

**Added:**
- RunicHammerBtn (y=0, 150x50)
- ForgeHammerBtn (y=55, 150x50)
- TackHammerBtn (y=110, 150x50)
- GrandHammerBtn (y=165, 150x50)
- ClawHammerBtn (y=220, 150x50)
- TuningHammerBtn (y=275, 150x50)
- Moved FinishItemButton to y=340

All buttons are toggle_mode with initial "(0)" counts.

### Crafting Logic (crafting_view.gd)

**Removed:**
- `enum button { NONE, IMPLICIT, PREFIX, SUFFIX }`
- `var button_pressed: button`
- `var hammer_counts: Dictionary`
- `ImplicitHammer_toggled()`, `AddPrefixHammer_toggled()`, `AddSuffixHammer_toggled()`
- Temporary `on_currencies_found()` mapping logic (runic+tack+forge → prefix, etc.)
- `update_hammer_button_states()`

**Added:**
- `var currencies: Dictionary` - Currency instances for all 6 types
- `var selected_currency: Currency` - Currently selected currency
- `var selected_currency_type: String` - Type key for GameState lookup
- `var currency_buttons: Dictionary` - Button references mapped by type
- `_on_currency_selected(currency_type: String)` - Unified selection handler
- `update_currency_button_states()` - Reflects GameState.currency_counts on buttons

**Updated:**
- `update_item()` - Now uses Currency.can_apply() validation, Currency.apply() for effects, GameState.spend_currency() for consumption
- `finish_item()` - Clears selected_currency and calls update_currency_button_states()
- `on_currencies_found()` - Simplified to just call update_currency_button_states() (counts already in GameState)
- `_ready()` - Initializes currency_buttons mapping and connects new button signals

### Signal Chain (main_view.gd)

**No changes required** - The existing signal connection `gameplay_view.currencies_found.connect(crafting_view.on_currencies_found)` continues to work. The handler's implementation changed but the interface remains compatible.

## Implementation Details

### Currency Selection Pattern

```gdscript
func _on_currency_selected(currency_type: String) -> void:
    var button = currency_buttons[currency_type]

    if button.button_pressed:
        selected_currency = currencies[currency_type]
        selected_currency_type = currency_type
        # Untoggle others
    else:
        selected_currency = null
        selected_currency_type = ""
```

Single handler for all 6 buttons using bind() for type discrimination.

### Currency Application Flow

```gdscript
func update_item(event: InputEvent) -> void:
    # Guards
    if selected_currency == null: return
    if current_item == null: return

    # Validation (does NOT consume)
    if not selected_currency.can_apply(current_item):
        print(selected_currency.get_error_message(current_item))
        return

    # Consumption check
    if not GameState.spend_currency(selected_currency_type):
        print("No " + selected_currency.currency_name + " remaining!")
        return

    # Apply effect (guaranteed success)
    selected_currency.apply(current_item)

    # Update UI
    update_label()
    update_currency_button_states()
```

This enforces CRAFT-09 (consume only on success) at the UI layer.

### Button State Management

```gdscript
func update_currency_button_states() -> void:
    for currency_type in currency_buttons:
        var count = GameState.currency_counts.get(currency_type, 0)
        var button = currency_buttons[currency_type]

        button.disabled = (count <= 0)
        button.text = currencies[currency_type].currency_name + " (" + str(count) + ")"

    # Auto-deselect if count reaches 0
    if selected_currency != null:
        var selected_count = GameState.currency_counts.get(selected_currency_type, 0)
        if selected_count <= 0:
            selected_currency = null
            selected_currency_type = ""
```

Single source of truth: GameState.currency_counts. Buttons reflect inventory state.

## Verification Results

All verification checks passed:

✅ Scene has exactly 6 currency buttons (RunicHammerBtn through TuningHammerBtn)
✅ Zero references to old ImplicitHammer/AddPrefixHammer/AddSuffixHammer in scenes
✅ Zero references to hammer_counts or button enum in scripts
✅ crafting_view.gd uses Currency.apply() for item modification
✅ crafting_view.gd uses GameState.spend_currency() for consumption
✅ crafting_view.gd uses Currency.get_error_message() for validation feedback
✅ All 6 currency counts display on buttons from GameState.currency_counts
✅ Signal chain intact: gameplay_view.currencies_found → crafting_view.on_currencies_found → update_currency_button_states()
✅ All functions have explicit return type hints (maintained from v0.1)

## Requirements Satisfied

### UI-01: Six Currency-Specific Buttons
✅ All 6 hammers have dedicated toggle buttons (Runic, Forge, Tack, Grand, Claw, Tuning)

### UI-02: Apply Currency via Button Selection
✅ Select currency button → click item → Currency.apply() called

### UI-03: Display Currency Counts
✅ Button text shows "Currency Name (N)" from GameState.currency_counts

### UI-04: Remove Old 3-Button System
✅ Enum, hammer_counts, old toggle handlers, and temporary mapping completely removed

## Deviations from Plan

None - plan executed exactly as written.

## Commits

| Hash    | Message                                                  |
| ------- | -------------------------------------------------------- |
| 1636e27 | feat(08-01): replace 3 hammer buttons with 6 currency buttons |

## Files Changed

**Modified (2):**
- scenes/node_2d.tscn (scene layout)
- scenes/crafting_view.gd (currency selection and application logic)

## Key Outcomes

1. **UI directly coupled to currency system** - No abstraction layers or mapping logic between UI and model
2. **Currency.apply() as standard interface** - All item modification goes through the same validation/application pattern
3. **GameState as single source of truth** - Currency counts read directly from GameState.currency_counts
4. **Validation before consumption** - can_apply() checked before spend_currency(), enforcing CRAFT-09
5. **Zero legacy code** - Old 3-hammer system completely removed from codebase

## Self-Check

### Created Files
None - this was a migration task modifying existing files only.

### Modified Files
✅ FOUND: scenes/node_2d.tscn
✅ FOUND: scenes/crafting_view.gd

### Commits
✅ FOUND: 1636e27

## Self-Check: PASSED

All files and commits verified present.
