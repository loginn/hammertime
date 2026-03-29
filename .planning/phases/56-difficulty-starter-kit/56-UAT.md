---
status: partial
phase: 56-difficulty-starter-kit
source: [56-01-SUMMARY.md, 56-02-SUMMARY.md]
started: 2026-03-29T00:00:00Z
updated: 2026-03-29T00:06:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Currency Names in Forge View
expected: Open the Forge. The currency labels/buttons should show the new PoE-style names: Transmute, Augment, Alteration, Regal, Chaos, Exalt (not the old names like Runic, Forge, Tack, Grand, Claw, Tuning).
result: issue
reported: "The augment is missing, the tooltips are wrong. Chaos is also missing."
severity: major

### 2. Fresh Game Starter Currencies
expected: Start a fresh new game (or check your currency counts at the very beginning). You should have exactly 2 Transmute and 2 Augment hammers. All other currencies (Alteration, Regal, Chaos, Exalt) should be 0.
result: issue
reported: "I have 2 transmutes (with the wrong name) and 2 forges (alchemy). No augments."
severity: major

### 3. Fresh Game Starter Items in Stash
expected: On a fresh game, check your stash. You should see a Broadsword (weapon) and an Iron Plate (armor) already placed there as starter gear.
result: issue
reported: "I see a rusty plate, not an iron plate."
severity: minor

### 4. Post-Prestige Starter Kit Matches Archetype
expected: After a prestige wipe, select a hero archetype. The starter items placed in your stash should match the archetype: STR hero gets Broadsword + Iron Plate, DEX hero gets Dagger + Leather Vest, INT hero gets Wand + Silk Robe. Currency resets to 2 Transmute + 2 Augment.
result: blocked
blocked_by: other
reason: "New game starts with an assassin instead of an adventurer. Can't get enough hammers to reach prestige because dying too much."

### 5. Forest Zone 1 Survivability
expected: Enter Forest zone 1 with blank (unmodified) starter gear. Your hero should be able to survive and kill monsters — they should not be instantly overwhelming. Forest monsters should feel noticeably easier than before the patch.
result: pass

### 6. Prestige Cost Labels
expected: Open the Prestige view. The prestige cost descriptions should reference "Augment" hammers (not "Forge" hammers).
result: blocked
blocked_by: other
reason: "Cannot reach prestige view — dying too much to accumulate enough hammers."

## Summary

total: 6
passed: 1
issues: 3
pending: 0
skipped: 0
blocked: 2

## Gaps

- truth: "Forge view shows all 6 currency names with correct PoE labels and tooltips"
  status: failed
  reason: "User reported: The augment is missing, the tooltips are wrong. Chaos is also missing."
  severity: major
  test: 1
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""

- truth: "Fresh game starts with exactly 2 Transmute and 2 Augment hammers"
  status: failed
  reason: "User reported: I have 2 transmutes (with the wrong name) and 2 forges (alchemy). No augments."
  severity: major
  test: 2
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""

- truth: "Fresh game starter armor is Iron Plate"
  status: failed
  reason: "User reported: I see a rusty plate, not an iron plate."
  severity: minor
  test: 3
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""
