---
status: partial
phase: 53-selection-ui
source: [53-01-SUMMARY.md, 53-VERIFICATION.md]
started: 2026-03-27T12:00:00Z
updated: 2026-03-27T12:05:00Z
---

## Current Test

[testing paused — 8 items outstanding]
blocked_reason: Early game balance is off, cannot reach prestige to test hero selection flow

## Tests

### 1. Hero Selection Overlay Appears After Prestige
expected: Start a game at P0. Earn enough Forge Hammers to prestige. Execute prestige. After fade-to-black and scene reload, a full-screen overlay appears showing 3 hero cards (one STR/red, one DEX/green, one INT/blue) with a "Choose Your Hero" header. Tab bar and all views blocked behind overlay.
result: [pending]

### 2. Card Content and Layout
expected: Each card shows: archetype + subvariant label (e.g., "STR - Hit"), hero title (e.g., "The Berserker"), and passive bonus lines in "+N% Label" format (e.g., "+25% Attack Damage"). Cards have colored left borders matching hero colors (red for STR, green for DEX, blue for INT). 3 cards arranged in a horizontal row.
result: [pending]

### 3. Single-Click Hero Selection
expected: Click any hero card. The hero is immediately selected — no confirmation dialog. The overlay fades out over ~0.3 seconds, revealing the Forge view underneath. No double-click or second tap needed.
result: [pending]

### 4. Selected Hero Active After Pick
expected: After picking a hero, check the Forge view stat panel. Stats should reflect the chosen hero's passive bonuses (e.g., picking The Berserker should show higher attack damage). The Adventure tab should work normally — combat uses the selected hero's bonuses.
result: [pending]

### 5. Save Persistence After Selection
expected: After picking a hero, close and reopen the game (or export/import save string). The chosen hero should still be active — no selection overlay reappears. Stats remain correct.
result: [pending]

### 6. P0 Players Never See Overlay
expected: Start a fresh new game (P0). The hero selection overlay should NOT appear. Player begins as classless Adventurer with no hero bonuses. Normal gameplay starts immediately on the Forge tab.
result: [pending]

### 7. New Overlay on Re-Prestige
expected: After playing with a selected hero, prestige again (P2). After the fade and reload, a NEW set of 3 hero cards appears (may be different subvariants than before since selection is random). Pick a new hero — old hero bonuses are replaced by the new hero's bonuses.
result: [pending]

### 8. Input Blocking During Overlay
expected: While the overlay is visible, try clicking on areas where tab bar buttons or the forge view would be. Nothing should respond — the overlay blocks all input to underlying views. Only the hero cards should be clickable.
result: [pending]

## Summary

total: 8
passed: 0
issues: 0
pending: 8
skipped: 0
blocked: 0

## Gaps

[none yet]
