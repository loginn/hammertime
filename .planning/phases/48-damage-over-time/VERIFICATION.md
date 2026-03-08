---
phase: 48
status: passed
score: 18/18
verified: 2026-03-08
---

# Phase 48 — Verification

## Goal
Add DoT system (bleed, poison, burn) with CombatEngine tick processing and UI feedback.

## Must-Have Verification

| # | Must-Have | Plan | Status | Evidence |
|---|----------|------|--------|----------|
| 1 | All six DoT stat types exist in tag.gd StatType enum | 01 | ✓ | Pre-existing from Phase 45 (AFF-05), confirmed by Group 30 tests |
| 2 | Hero aggregates DoT stats from equipment | 01 | ✓ | hero.gd:514 `calculate_dot_stats()`, vars at lines 24-35 |
| 3 | Hero calculates total_dot_dps respecting attack-mode vs spell-mode | 01 | ✓ | hero.gd:576 `calculate_dot_dps()`, bleed/poison attack-only, burn spell-only |
| 4 | Bleed procs from attack hits with max 8 stacks, replace closest to expiry | 01 | ✓ | combat_engine.gd:133 bleed proc, monster_pack.gd:39 `apply_dot` with 8-stack cap |
| 5 | Poison procs with unlimited stacks, chance overflow, crit +100% | 01 | ✓ | combat_engine.gd:137-155 poison proc with overflow logic |
| 6 | Burn procs from spell hits only with single-stack refresh | 01 | ✓ | combat_engine.gd:195 burn proc in spell hit handler, monster_pack.gd max 1 stack |
| 7 | DoT tick timer fires every 1 second | 01 | ✓ | combat_engine.gd:42-46 Timer with wait_time=1.0 connected to `_on_dot_tick` |
| 8 | Pack DoTs clear on kill; hero DoTs clear on death; all clear on stop | 01 | ✓ | combat_engine.gd:69-72 stop, :255-256 pack kill, :317-318 hero death |
| 9 | GameEvents signals emit for dot_applied, dot_ticked, dot_expired | 01 | ✓ | game_events.gd:35-37 three signals defined |
| 10 | Pack-applied DoTs on hero with element-based auto-proc | 01 | ✓ | combat_engine.gd:241 hero.apply_dot in _on_pack_attack |
| 11 | DefenseCalculator.calculate_dot_damage_taken() with resistance-only path | 02 | ✓ | defense_calculator.gd:97-122 static method, no evasion/armor |
| 12 | Hero tracks total_chaos_resistance from CHAOS_RESISTANCE suffixes | 02 | ✓ | hero.gd:18,309,349,465-467 |
| 13 | DoT DPS displays in hero stats panel (hidden when 0) | 02 | ✓ | forge_view.gd:697-699 conditional display |
| 14 | Chaos resistance displays in defense section (hidden when 0) | 02 | ✓ | forge_view.gd:739-741 conditional display |
| 15 | DoT accumulator and status labels in gameplay_view | 03 | ✓ | gameplay_view.gd:28-31 @onready refs, gameplay_view.tscn:87,95,130,138 Label nodes |
| 16 | DoT UI resets on pack kill, combat stop, hero death | 03 | ✓ | gameplay_view.gd signal handlers + cleanup code |
| 17 | Warhammer implicit correctly named "Bleed Damage" | 03 | ✓ | warhammer.gd:37 "Bleed Damage" |
| 18 | Integration tests cover all 7 DOT requirements across groups 30-34 | 03 | ✓ | integration_test.gd Groups 30-34 present |

## Requirement Coverage

| Req ID | Description | Plan | Verified | Evidence |
|--------|-------------|------|----------|----------|
| DOT-01 | DoT StatTypes in tag.gd | 01, 03 | ✓ | Pre-existing from P45; Group 30 tests verify existence |
| DOT-02 | DoT tick system in CombatEngine | 01, 03 | ✓ | combat_engine.gd:357 `_on_dot_tick`, :42-46 timer setup; Group 31+33 tests |
| DOT-03 | Bleed affix (physical DoT, STR) | 01, 03 | ✓ | combat_engine.gd:133 bleed proc, monster_pack.gd stacking; Group 31 tests |
| DOT-04 | Poison affix (DEX) | 01, 03 | ✓ | combat_engine.gd:137-155 poison proc with overflow; Group 31 tests |
| DOT-05 | Burn affix (fire DoT, INT) | 01, 03 | ✓ | combat_engine.gd:195 burn proc in spell handler; Group 31 tests |
| DOT-06 | DoT damage shown in combat UI | 03 | ✓ | gameplay_view.gd:214-260 signal handlers, .tscn Label nodes; Group 34 tests |
| DOT-07 | DoT defense interaction | 02, 03 | ✓ | defense_calculator.gd:97-122 resistance-only path; Group 32 tests |

## Human Verification Items
- Visually confirm DoT accumulator labels appear and fade correctly during combat (2s hold + 1s fade)
- Visually confirm DoT status text shows correct stack counts ("BLEED x3", "POISON x7", "BURN")
- Play-test with bleed/poison/burn weapons to confirm DoTs proc and deal visible tick damage
- Verify DoT DPS line appears in forge hero stats panel when equipping DoT-stat weapons

## Gaps
None

## Verdict
Phase 48 is fully implemented. All 7 DOT requirements (DOT-01 through DOT-07) are verified in code. The DoT engine spans 4 core files (game_events.gd, monster_pack.gd, hero.gd, combat_engine.gd), defense integration in defense_calculator.gd, UI feedback in gameplay_view.gd/tscn and forge_view.gd, and comprehensive integration tests in Groups 30-34. All plan frontmatter requirement IDs are accounted for in REQUIREMENTS.md. Status: PASSED.
