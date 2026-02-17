---
status: complete
phase: 19-side-by-side-layout
source: [19-01-SUMMARY.md, 19-02-SUMMARY.md]
started: 2026-02-17T18:00:00Z
updated: 2026-02-17T18:05:00Z
---

## Current Test

[testing complete]

## Tests

### 1. The Forge layout displays
expected: Open the game. You should see "The Forge" view by default with top tab bar, hammer sidebar on left, item/hero graphics and stats panels on the right in a side-by-side layout. Dark theme throughout.
result: issue
reported: "Hammers are not using the right icons from the asset folder. Text is too large + too much whitespace. it goes outside the viewport"
severity: major

### 2. Tab bar navigation
expected: Click the "Combat" tab — gameplay/combat view should appear full-width. Click "Settings" — settings view should appear. Click "The Forge" — returns to the side-by-side forge layout. Active tab should be visually distinct (disabled state).
result: issue
reported: "The combat view has the adventure text misplaced. Remove that text. Rename the combat tab to adventure instead"
severity: minor

### 3. Keyboard shortcuts
expected: Press "1" to switch to The Forge, "2" for Combat, "3" for Settings. Press TAB to cycle through views in order. Each shortcut should switch the view immediately.
result: issue
reported: "Settings does not need a shortcut"
severity: minor

### 4. Item type buttons
expected: In The Forge view, below the item image area you should see 5 equal-width buttons: Weapon, Helmet, Armor, Boots, Ring. Clicking one should select that item type for crafting.
result: issue
reported: "Selection works, remove the gap between buttons because it makes the hero stats flicker when between item stats and hero stats in between 2 buttons which is uncomfortable."
severity: minor

### 5. Craft and Melt workflow
expected: Select a hammer and apply it to create/modify an item. When a finished item exists, Melt and Equip buttons should be enabled at the bottom of Item Stats. Click Melt — the item should be destroyed and the crafting slot freed for a new craft.
result: issue
reported: "Melt works. Item colors are gone though, rares are no longer yellow, magic items are no longer blue."
severity: major

### 6. Craft and Equip workflow
expected: Craft a finished item. Click Equip — the item should equip to the hero's slot. Hero Stats panel should update immediately with the new equipment stats. If a slot was already occupied, old item is replaced (destroyed).
result: pass

### 7. Type hover comparison
expected: Hover over one of the item type buttons (e.g., Helmet). The Hero Stats panel should swap to show the currently equipped item of that type for comparison. Moving the mouse away should restore the normal hero stats display.
result: skipped
reason: Can't test — level 1 too hard to get multiple equipped items. Phase 22 addresses level 1 balance.

### 8. Cross-view signal wiring
expected: Switch to Combat tab, clear an area. Loot drops (currencies and/or item bases) should flow back when you return to The Forge — currency counts on hammer buttons update, and any dropped item base appears in the crafting slot.
result: pass

### 9. Settings view
expected: Click Settings tab. Should see a full-screen view (not a popup) with Save Game and New Game buttons. Clicking New Game should show "Are you sure?" confirmation — requires a second click to actually reset.
result: pass

### 10. Viewport size
expected: The game window should be 1280x720 pixels. All panels should fit without overlap or content being cut off at the edges.
result: issue
reported: "1280x720 is right, the bottom and top areas have weird colors though. See Wireframe/view issue 1.png — strips at top and bottom of viewport are a different gray than the dark content background."
severity: cosmetic

## Summary

total: 10
passed: 3
issues: 6
pending: 0
skipped: 1

## Gaps

- truth: "The Forge layout displays correctly with hammer sidebar, item/hero panels, dark theme, all within 1280x720 viewport"
  status: failed
  reason: "User reported: Hammers are not using the right icons from the asset folder. Text is too large + too much whitespace. it goes outside the viewport"
  severity: major
  test: 1
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""

- truth: "Keyboard shortcuts switch views: 1=Forge, 2=Combat, TAB cycles"
  status: failed
  reason: "User reported: Settings does not need a shortcut"
  severity: minor
  test: 3
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""

- truth: "Item type buttons display below item image with no flickering when hovering between buttons"
  status: failed
  reason: "User reported: Selection works, remove the gap between buttons because it makes the hero stats flicker when between item stats and hero stats in between 2 buttons which is uncomfortable."
  severity: minor
  test: 4
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""

- truth: "Crafted items display rarity colors (blue for magic, yellow for rare) in item stats text"
  status: failed
  reason: "User reported: Melt works. Item colors are gone though, rares are no longer yellow, magic items are no longer blue."
  severity: major
  test: 5
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""

- truth: "Combat tab switches to full-width gameplay view with correct layout and tab named appropriately"
  status: failed
  reason: "User reported: The combat view has the adventure text misplaced. Remove that text. Rename the combat tab to adventure instead"
  severity: minor
  test: 2
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""

- truth: "Viewport background color is consistent — no color mismatches at top/bottom edges"
  status: failed
  reason: "User reported: 1280x720 is right, the bottom and top areas have weird colors though. Strips at top and bottom of viewport are a different gray than the dark content background."
  severity: cosmetic
  test: 10
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""
