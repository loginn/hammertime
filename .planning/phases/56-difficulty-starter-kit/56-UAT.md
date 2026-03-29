---
status: diagnosed
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
  root_cause: "Currency model classes still have old currency_name values. ForgeHammer='Forge Hammer' (should be Augment), ClawHammer='Claw Hammer' (should be Chaos), RunicHammer='Runic Hammer' (should be Transmute), etc. forge_view.gd line 323 uses currency_name for tooltip text."
  artifacts:
    - path: "models/currencies/forge_hammer.gd"
      issue: "currency_name = 'Forge Hammer' should be 'Augment Hammer'"
    - path: "models/currencies/claw_hammer.gd"
      issue: "currency_name = 'Claw Hammer' should be 'Chaos Hammer'"
    - path: "models/currencies/runic_hammer.gd"
      issue: "currency_name = 'Runic Hammer' should be 'Transmute Hammer'"
    - path: "models/currencies/tack_hammer.gd"
      issue: "currency_name still uses old convention"
    - path: "models/currencies/grand_hammer.gd"
      issue: "currency_name still uses old convention"
    - path: "models/currencies/tuning_hammer.gd"
      issue: "currency_name still uses old convention"
  missing:
    - "Update currency_name in all 6 hammer model classes to PoE names"
  debug_session: ""

- truth: "Fresh game starts with exactly 2 Transmute and 2 Augment hammers"
  status: failed
  reason: "User reported: I have 2 transmutes (with the wrong name) and 2 forges (alchemy). No augments."
  severity: major
  test: 2
  root_cause: "Same root cause as test 1 — currency_name display strings in hammer model classes were not updated. ForgeHammer.currency_name='Forge Hammer' displays as 'Forge' instead of 'Augment'. Counts are correct (2+2) but labels are wrong."
  artifacts:
    - path: "models/currencies/forge_hammer.gd"
      issue: "currency_name = 'Forge Hammer' displays as 'Forge' instead of 'Augment'"
    - path: "models/currencies/runic_hammer.gd"
      issue: "currency_name = 'Runic Hammer' displays as 'Runic' instead of 'Transmute'"
  missing:
    - "Same fix as test 1 — update currency_name in hammer model classes"
  debug_session: ""

- truth: "Fresh game starter armor is Iron Plate"
  status: failed
  reason: "User reported: I see a rusty plate, not an iron plate."
  severity: minor
  test: 3
  root_cause: "IronPlate TIER_NAMES dict maps tier 8 to 'Rusty Plate'. _place_starter_kit() creates IronPlate.new(8) which resolves to 'Rusty Plate'. Iron Plate is tier 7."
  artifacts:
    - path: "models/items/iron_plate.gd"
      issue: "TIER_NAMES[8] = 'Rusty Plate', tier 7 = 'Iron Plate'"
    - path: "autoloads/game_state.gd"
      issue: "_place_starter_kit() uses IronPlate.new(8) — should use tier 7 for Iron Plate"
  missing:
    - "Change _place_starter_kit() to use IronPlate.new(7) or accept that tier 8 = Rusty Plate is correct and update expectations"
  debug_session: ""
