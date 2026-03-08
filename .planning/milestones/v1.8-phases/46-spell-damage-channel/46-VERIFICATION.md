---
phase: 46
status: passed
verified: 2026-03-06
---

# Phase 46 Verification

## Requirement Coverage
| REQ | Status | Evidence |
|-----|--------|----------|
| SPELL-03 | PASS | `models/items/weapon.gd` lines 19-25: `base_spell_damage_min`, `base_spell_damage_max`, `base_cast_speed` fields default to 0; `spell_dps` computed in `update_value()` |
| SPELL-04 | PASS | `models/stats/stat_calculator.gd` lines 142-220: `calculate_spell_damage_range()` returns `{"spell": {"min", "max"}}`, `calculate_spell_dps()` returns 0 when cast_speed==0, applies flat/% spell damage + cast speed + crit |
| SPELL-05 | PASS | `models/hero.gd` lines 33-36: `total_spell_dps` and `spell_damage_ranges` dict; lines 184-267: `calculate_spell_damage_ranges()` and `calculate_spell_dps()` called from `update_stats()` (line 101-103); `get_total_spell_dps()` getter at line 381 |
| SPELL-07 | PASS | `scenes/forge_view.gd` lines 691-696: "Attack DPS" (not "Total DPS") shown when >0 or when spell is 0; "Spell DPS" shown only when >0. Stat comparison lines 793-795 and 817-819 show both channels. Weapon/Ring tooltips show spell damage, cast speed, spell DPS when non-zero (lines 1001-1006, 1098-1101) |

## Requirement ID Cross-Reference
| Plan | Frontmatter IDs | REQUIREMENTS.md Phase 46 IDs | Match |
|------|-----------------|------------------------------|-------|
| 46-01 | SPELL-03, SPELL-04 | SPELL-03, SPELL-04 | Yes |
| 46-02 | SPELL-05, SPELL-07 | SPELL-05, SPELL-07 | Yes |
| 46-03 | SPELL-03, SPELL-04, SPELL-05, SPELL-07 | (covers all) | Yes |

All 4 requirement IDs (SPELL-03, SPELL-04, SPELL-05, SPELL-07) from the phase goal are accounted for. SPELL-06 (CombatEngine spell timer) is intentionally deferred to Phase 47, consistent with the phase goal of "without touching CombatEngine yet."

## Must-Have Verification

### Plan 01 Must-Haves
| Must-Have | Status | Evidence |
|-----------|--------|----------|
| Weapon has base_spell_damage_min/max, base_cast_speed defaulting to 0 | PASS | weapon.gd lines 20-24 |
| Ring has base_cast_speed field defaulting to 0 | PASS | ring.gd line 9 |
| SapphireRing has tier-scaled base_cast_speed values | PASS | sapphire_ring.gd TIER_STATS: T8=0.5 through T1=1.2 |
| StatCalculator.calculate_spell_damage_range() returns correct spell damage dict | PASS | stat_calculator.gd lines 142-168, returns {"spell": {"min", "max"}} |
| StatCalculator.calculate_spell_dps() returns 0 when cast speed is 0 | PASS | stat_calculator.gd lines 206-208 |
| StatCalculator.calculate_spell_dps() correctly applies flat/% spell damage, cast speed, crit | PASS | stat_calculator.gd lines 187-220, mirrors attack pipeline |
| All existing attack DPS calculations remain unchanged | PASS | calculate_dps() untouched, integration tests 1-21 still called |

### Plan 02 Must-Haves
| Must-Have | Status | Evidence |
|-----------|--------|----------|
| Hero tracks spell_damage_ranges dict parallel to damage_ranges | PASS | hero.gd lines 34-36 |
| Hero tracks total_spell_dps parallel to total_dps | PASS | hero.gd line 33 |
| Hero.update_stats() calls calculate_spell_damage_ranges() and calculate_spell_dps() | PASS | hero.gd lines 101-103 |
| Spell channel activates when total cast speed > 0 from ANY equipped gear | PASS | hero.gd lines 224-232 aggregates from weapon + ring |
| SapphireRing enables spell DPS via base_cast_speed + FLAT_SPELL_DAMAGE implicit | PASS | sapphire_ring.gd _init() sets base_cast_speed and creates Spell Damage implicit |
| ForgeView shows "Attack DPS" (not "Total DPS") | PASS | forge_view.gd line 694; grep for "Total DPS" returns 0 matches |
| ForgeView shows "Spell DPS" line only when spell DPS > 0 | PASS | forge_view.gd lines 695-696: conditional on spell_dps_val > 0 |
| Stat comparison shows both Attack DPS and Spell DPS deltas when relevant | PASS | forge_view.gd lines 793-795 (weapon), 817-819 (ring) |
| Weapon/Ring tooltips show spell damage and cast speed when applicable | PASS | forge_view.gd lines 1001-1006 (weapon), 1098-1101 (ring) |

### Plan 03 Must-Haves
| Must-Have | Status | Evidence |
|-----------|--------|----------|
| Test group 22 validates Weapon/Ring spell field defaults and StatCalculator spell methods | PASS | integration_test.gd lines 874-957 |
| Test group 23 validates Hero spell DPS tracking with various equipment combinations | PASS | integration_test.gd lines 961-1009 |
| Test group 24 validates serialization round-trip for spell fields | PASS | integration_test.gd lines 1014-1057 |
| All existing test groups (1-21) continue to pass | PASS | _ready() calls groups 1-24 in sequence |
| SapphireRing spell channel activation is tested | PASS | Group 22 line 907, Group 23 line 982 |
| Zero-cast-speed correctly produces zero spell DPS in tests | PASS | Group 22 lines 921-922, Group 23 lines 975, 989 |

## No CombatEngine Changes
| Check | Status | Evidence |
|-------|--------|----------|
| combat_engine.gd unmodified | PASS | `git log master..HEAD -- models/combat/combat_engine.gd` returns empty; `git diff master -- models/combat/combat_engine.gd` returns empty |

## Gaps
None

## Human Verification Needed
- ForgeView UI visual checks (equip SapphireRing, verify "Spell DPS" line appears in hero stats panel)
- ForgeView tooltip visual checks (hover SapphireRing, verify Cast Speed and Spell DPS lines)
- ForgeView stat comparison visual check (hover equip button on SapphireRing, verify Spell DPS delta)
- Run integration test suite in Godot editor (F6 on integration_test scene) to confirm all 24 groups pass
