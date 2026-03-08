---
phase: 45
plan: 01
status: complete
started: 2026-03-06
completed: 2026-03-06
---

# Plan 45-01 Summary

## What Was Built
Added 3 DoT chance StatTypes (BLEED_CHANCE, POISON_CHANCE, BURN_CHANCE) to tag.gd, then added 14 new affixes (6 prefixes + 8 suffixes) to item_affixes.gd, replacing the Cast Speed, Damage over time, and Bleed Damage disabled stubs with proper implementations.

## Tasks Completed
| # | Task | Status | Commit |
|---|------|--------|--------|
| 1 | Add DoT Chance StatTypes to tag.gd | done | f3061a0 |
| 2 | Add 6 New Prefixes to item_affixes.gd | done | 26fefda |
| 3 | Add 8 New Suffixes and Replace Disabled Stubs | done | c8a2996 |

## Key Files
### Created
- (none)

### Modified
- autoloads/tag.gd
- autoloads/item_affixes.gd

## Deviations
None

## Self-Check: PASSED
- [x] BLEED_CHANCE, POISON_CHANCE, BURN_CHANCE exist in Tag.StatType enum
- [x] 6 new prefixes added: Spell Damage, %Spell Damage, Bleed Damage, Poison Damage, Burn Damage, %DoT Damage
- [x] 8 new suffixes added: Cast Speed, Chaos Resistance, Bleed Chance, %Bleed Damage, Poison Chance, %Poison Damage, Burn Chance, %Burn Damage
- [x] Disabled stubs for Cast Speed, Damage over time, and Bleed Damage are replaced (not duplicated)
- [x] Evade suffix remains disabled (AFF-04 dropped per user decision)
- [x] All new affixes use Vector2i(1, 32) tier range
- [x] Flat spell/DoT damage prefixes include damage range params (dmg_min_lo/hi, dmg_max_lo/hi)
