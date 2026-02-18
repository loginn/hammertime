---
status: complete
phase: 24-stat-calculation-and-hero-range-caching
source: 24-01-SUMMARY.md, 24-02-SUMMARY.md
started: 2026-02-18T12:00:00Z
updated: 2026-02-18T12:10:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Hero DPS Updates on Weapon Equip
expected: Equip a weapon on your hero. The DPS stat should update to reflect the weapon's damage ranges (per-element min/max averages multiplied by speed and crit). Changing to a different weapon should change DPS accordingly.
result: pass

### 2. DPS-Based Weapon Comparison in Forge
expected: In the forge view, when viewing a weapon drop or crafted weapon, the comparison indicator (better/worse) should be based on DPS difference against your currently equipped weapon, not just item tier.
result: pass

### 3. DPS-Based Ring Comparison in Forge
expected: In the forge view, when viewing a ring, the comparison indicator should also use DPS-based comparison (same as weapons), not tier comparison.
result: pass

### 4. Tier-Based Comparison for Armor/Helmet/Boots
expected: In the forge view, when viewing armor, helmet, or boots, the comparison indicator should use tier comparison (not DPS). These item types don't have DPS fields.
result: issue
reported: "can we do comparison per defensive stat ? Evasion, HP, Armor, ES, Resistances"
severity: major

### 5. Damage Ranges Recalculate After Save/Load
expected: Save your game, then load it back. Your hero's DPS should be the same as before saving — damage ranges are recalculated from equipment on load, not stored in the save file.
result: pass

## Summary

total: 5
passed: 4
issues: 1
pending: 0
skipped: 0

## Gaps

- truth: "Armor/Helmet/Boots comparison uses meaningful per-stat comparison"
  status: failed
  reason: "User reported: can we do comparison per defensive stat ? Evasion, HP, Armor, ES, Resistances"
  severity: major
  test: 4
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""
