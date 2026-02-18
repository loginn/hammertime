---
status: complete
phase: 22-balance-polish
source: [22-01-SUMMARY.md]
started: 2026-02-18T02:00:00Z
updated: 2026-02-18T02:25:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Starter Runic Hammer
expected: Starting a new game gives the player exactly 1 Runic Hammer. No other hammers present (no 999 of each — debug mode is off).
result: pass

### 2. Forest Monster Survivability
expected: A fresh hero with a tier 1 crafted weapon (use the starter Runic Hammer to craft) can survive at least 3 monster packs in the Forest (level 1) area. Monsters should feel noticeably easier than before — less damage taken per hit, monsters die faster.
result: issue
reported: "No monsters are still way too strong, divide base monster health by 2. Also hero life/es should reset between maps. Also the hero should only have access to 1 light sword and should clear maps to get the new items."
severity: major

### 3. No Debug Hammer Flood
expected: On fresh game start, currency counts show only 1 Runic Hammer. You should NOT see 999 Tack Hammers, 999 Claw Hammers, etc. The debug flood is gone.
result: pass

### 4. Stat Panel Readability
expected: In the Hero/Forge view, all stat labels (DPS, Armor, Evasion, Energy Shield, resistances) are readable with properly sized text. No text overflow, no clipping, no scrollbar needed.
result: issue
reported: "Readability is fine. Health mods don't seem to apply. Hero stats should include health and ES as well. Also item type button hover shows equipped item text without rarity color — all areas that describe an item's stats should call get_rarity_color()."
severity: major

### 5. Monster Attack Speeds Preserved
expected: In Forest combat, faster monsters (Spiders, Sprites) still attack noticeably faster than slower ones (Wolves, Bears). The speed feels the same — only damage and HP changed.
result: skipped
reason: No indication of what packs are being fought — can't distinguish monster types

## Summary

total: 5
passed: 2
issues: 2
pending: 0
skipped: 1

## Gaps

- truth: "Fresh hero with tier 1 crafted weapon survives at least 3 packs in Forest"
  status: failed
  reason: "User reported: No monsters are still way too strong, divide base monster health by 2. Also hero life/es should reset between maps. Also the hero should only have access to 1 light sword and should clear maps to get the new items."
  severity: major
  test: 2
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""

- truth: "Hero stats panel shows all relevant stats including health and ES, health mods apply correctly"
  status: failed
  reason: "User reported: Health mods don't seem to apply. Hero stats should include health and ES. Item type button hover shows equipped item text without rarity color — all areas describing item stats should use get_rarity_color()."
  severity: major
  test: 4
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""

- truth: "All areas displaying item stats use rarity color via get_rarity_color()"
  status: failed
  reason: "User reported: When hovering item type buttons, equipped items text doesn't have the right color. All areas that describe an item's stats should call get_rarity_color()."
  severity: cosmetic
  test: 4
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""
