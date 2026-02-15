---
status: complete
phase: 08-ui-migration
source: [08-01-SUMMARY.md]
started: 2026-02-15T12:00:00Z
updated: 2026-02-15T12:30:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Six currency buttons visible in crafting view
expected: Open the game. Navigate to the crafting view. You should see 6 vertically stacked buttons: Runic Hammer, Forge Hammer, Tack Hammer, Grand Hammer, Claw Hammer, and Tuning Hammer. Each shows "(0)" count initially. The old Implicit/Prefix/Suffix buttons should be gone.
result: pass

### 2. Currency counts update after area clearing
expected: Clear an area (e.g., Forest). Return to crafting view. Button text should update to show earned counts (e.g., "Runic Hammer (2)"). Buttons with count > 0 should be enabled (not grayed out).
result: pass

### 3. Select currency and apply to item
expected: With currencies available, toggle one of the currency buttons (e.g., Runic Hammer). It should stay pressed/highlighted. Click on a valid item. The currency effect should apply (e.g., Runic upgrades a Normal item to Magic with mods). The currency count on the button should decrease by 1.
result: pass

### 4. Invalid currency use shows error
expected: Try applying a currency to an invalid target (e.g., Runic Hammer on a Magic item, or Tack Hammer on a Normal item). The currency should NOT be consumed. An error message should print explaining why it can't be applied.
result: pass

### 5. Button disables when count reaches zero
expected: Use a currency until its count reaches 0. The button should become disabled (grayed out/unclickable). If that currency was selected, it should auto-deselect.
result: pass

### 6. Finish Item resets selection
expected: With a currency selected, click the Finish Item button. The currency selection should clear (no button toggled). Currency counts should refresh on the buttons.
result: pass

## Summary

total: 6
passed: 6
issues: 0
pending: 0
skipped: 0

## Gaps

[none]

## Notes

Issues fixed during testing (not counted as gaps):
- hero_view.gd:8 dead @onready reference to nonexistent LastCraftedLabel node (removed)
- ItemTypeButtons overlapping InventoryPanel at y=220 (moved to y=410)
- Duplicate currency counts in inventory panel text (removed, buttons are authoritative)
- Added debug_hammers flag to GameState for testing with 999 currencies

Pre-existing issues observed (not Phase 8 scope):
- Helmets have no prefix affixes (all prefixes are Tag.WEAPON only), so Forge Hammer produces max 3 suffixes instead of 4-6 total mods
- Light Sword button regenerates a free weapon; other item types do not
