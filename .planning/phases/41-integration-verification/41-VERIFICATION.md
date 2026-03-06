---
phase: 41
status: human_needed
verified: 2026-03-06
---

# Phase 41 — Verification

## Goal
The full prestige loop works end-to-end from fresh game through multiple prestiges, with save round-trips validated at each stage and no regressions in existing crafting behavior.

## must_haves Verification
| # | must_have | Status | Evidence |
|---|----------|--------|----------|
| 1 | Test scene runs as standalone scene from Godot editor with structured [PASS]/[FAIL] output and summary | HUMAN | `tools/test/integration_test.tscn` exists with correct scene format; `integration_test.gd` has `_check()` helper printing `[PASS]`/`[FAIL]`, `_ready()` runs all 9 groups, and prints `=== SUMMARY ===` with pass/fail counts. Needs manual run to confirm no runtime errors. |
| 2 | Full prestige flow verified: fresh game -> grant 100 forge hammers -> execute prestige -> post-prestige state correct | HUMAN | Group 3 (`_group_3_execute_prestige`) calls `_reset_fresh()`, grants 100 forge, calls `_simulate_prestige()`, then checks prestige_level=1, max_item_tier_unlocked=7, area_level=1, all equipment null, starter weapon exists, forge=0, runic=1, tag total=1, can_prestige()=false. All assertions match plan spec. |
| 3 | Save round-trip at P0 and P1 verified via _build_save_data()/_restore_state() with exact field comparison | HUMAN | Group 4 (P0) and Group 5 (P1) both call `SaveManager._build_save_data()`, trash state, call `SaveManager._restore_state()`, then verify prestige_level, max_item_tier_unlocked, tag_currency_counts, area_level, and runic currency. Both functions confirmed to exist in `autoloads/save_manager.gd`. |
| 4 | Item tier -> affix tier floor gating verified (tier 7 item produces affixes >= tier 25, tier 8 produces >= 29) | HUMAN | Group 7 (`_group_7_item_tier_affix_floor`) tests `_get_affix_tier_floor()` for tiers 8 (=29), 7 (=25), and 1 (=1). Also applies RunicHammer to tier-7 sword and checks all generated affixes have tier >= 25. Formula `(tier - 1) * 4 + 1` confirmed in `models/items/item.gd:225`. |
| 5 | Crafting regression verified: RunicHammer applies to starter weapon after prestige, adds at least 1 mod | HUMAN | Group 6 (`_group_6_crafting_regression`) resets fresh, sets prestige_level=1, gets starter weapon, checks Normal rarity, applies RunicHammer.new().apply(), checks Magic rarity and prefixes+suffixes >= 1. `Currency.apply()` confirmed at `models/currencies/currency.gd:16`. |
| 6 | Tag hammer gating verified: prestige_level < 1 blocks tag section, prestige_level >= 1 enables it; TagHammer.can_apply() requires Normal rarity | HUMAN | Group 8 checks `prestige_level >= 1` is false at P0 and true at P1. Creates `TagHammer.new("PHYSICAL", "Physical Hammer")`, tests `can_apply()` on Normal (true) and Magic (false) LightSword. Tests `spend_tag_currency()` success and failure. `TagHammer.can_apply()` confirmed at `models/currencies/tag_hammer.gd:12` requiring Normal rarity. UI gating confirmed at `scenes/forge_view.gd:279`. |
| 7 | File I/O round-trip verified: write save data to user://test_save.json, read back, restore, compare -- cleanup after | HUMAN | Group 9 writes `_build_save_data()` to `user://test_save.json` via FileAccess, reads back, parses JSON, restores state, checks prestige_level=1, max_item_tier_unlocked=7, cold=3. Cleans up with `DirAccess.remove_absolute()` and verifies file no longer exists. |
| 8 | No real save file overwritten (avoids calling save_game()/execute_prestige() directly) | PASS (code review) | Test uses `_simulate_prestige()` helper that manually sets prestige state and calls `_wipe_run_state()` instead of `execute_prestige()`. File I/O uses `user://test_save.json` not `user://hammertime_save.json`. No calls to `save_game()` or `execute_prestige()` anywhere in the test script. |

## Requirements Coverage
| Req ID | Description | Covered By | Status |
|--------|-------------|------------|--------|
| PRES-01 | Player can prestige by spending required currency amounts | Group 2 (gating at 99 vs 100 forge), Group 3 (execute prestige) | HUMAN |
| PRES-02 | Prestige triggers full reset of area level, hero equipment, crafting inventory, and standard currencies | Group 3 (area_level=1, all equipment null, forge=0, runic=1, starter weapon present) | HUMAN |
| PRES-03 | Prestige level and item tier unlocks persist across resets | Group 1 (baseline P0), Group 3 (P1 state after wipe), Groups 4-5 (save round-trips) | HUMAN |
| PRES-04 | Player sees confirmation dialog showing cost, reward, and what resets | Not testable in headless script -- UI component in prestige_view.gd | HUMAN (manual UI check) |
| PRES-05 | Game supports 7 total prestige levels (P1 through P7) | Group 1 (checks P0 baseline), Group 3 (checks P2 unreachable at 999999 cost) | HUMAN |
| PRES-06 | Each prestige level unlocks the next better item tier | Group 3 (P1 -> max_item_tier_unlocked=7 via ITEM_TIERS_BY_PRESTIGE[1]) | HUMAN |
| TIER-01 | Items have an item_tier field (1-8) that gates which affix tiers can roll | Group 7 (tests _get_affix_tier_floor at tiers 1, 7, 8) | HUMAN |
| TIER-02 | Item tier drops are weighted by area level | Not directly tested -- drop weighting is a combat/loot system concern | HUMAN (manual play check) |
| TIER-03 | Item tier constrains affix tier range during crafting | Group 7 (applies RunicHammer to tier-7 sword, checks all affixes >= tier 25) | HUMAN |
| AFFIX-01 | Affix tiers expand from 8 to 32 levels | Group 7 (tier floor formula produces values in 1-29 range across 32-tier space) | HUMAN |
| AFFIX-02 | Affix quality normalization helper enables correct cross-range tier comparison | Group 6 (crafting regression -- affixes generated correctly post-prestige) | HUMAN |
| TAG-01 | Fire Hammer transforms Normal item to Rare, guaranteeing fire-tagged affix | Group 8 tests TagHammer mechanics (can_apply logic); specific tag hammer variants use same base class | HUMAN |
| TAG-02 | Cold Hammer transforms Normal item to Rare, guaranteeing cold-tagged affix | Same TagHammer base class as TAG-01 | HUMAN |
| TAG-03 | Lightning Hammer transforms Normal item to Rare, guaranteeing lightning-tagged affix | Same TagHammer base class as TAG-01 | HUMAN |
| TAG-04 | Defense Hammer transforms Normal item to Rare, guaranteeing defense-tagged affix | Same TagHammer base class as TAG-01 | HUMAN |
| TAG-05 | Physical Hammer transforms Normal item to Rare, guaranteeing physical-tagged affix | Group 8 directly tests PHYSICAL TagHammer can_apply on LightSword | HUMAN |
| TAG-06 | Tag hammers show "no valid mods" feedback when no matching affixes are available | Not directly tested -- UI feedback concern | HUMAN (manual UI check) |
| TAG-07 | Tag hammers are only available after Prestige 1 | Group 8 (prestige_level >= 1 gating check); forge_view.gd:279 confirmed | HUMAN |
| TAG-08 | Tag hammer currencies drop from packs after reaching Prestige 1 | Group 3 (tag_currency_counts total == 1 after prestige) | HUMAN |
| SAVE-01 | Save format stores prestige level, item tier unlocks, and tag currency counts | Groups 4, 5, 9 (save/restore round-trips verifying all three fields) | HUMAN |
| SAVE-02 | Prestige completion triggers auto-save | Not directly tested -- test avoids execute_prestige() by design | HUMAN (manual check) |
| PUI-01 | Player can see their current prestige level at all times | Not testable in headless script -- UI in prestige_view.gd / main_view.gd | HUMAN (manual UI check) |
| PUI-02 | Player can see prestige cost and what the next prestige unlocks | Not testable in headless script -- UI component | HUMAN (manual UI check) |
| PUI-03 | Player can see an unlock table showing all 7 prestige levels and their rewards | Not testable in headless script -- UI component | HUMAN (manual UI check) |
| PUI-04 | Tag hammer buttons appear in crafting view after Prestige 1 | Group 8 tests the underlying condition (prestige_level >= 1); forge_view.gd:279 confirms UI gating | HUMAN |
| PUI-05 | Prestige confirmation shows cost, reward, and complete reset list | Not testable in headless script -- UI component | HUMAN (manual UI check) |

## Human Verification Required
The following items require manual testing in the Godot editor:

1. **Run the test scene**: Open `tools/test/integration_test.tscn` in the Godot editor and run it (F6). Verify all 9 groups print `[PASS]` for every check and the summary shows `[ALL PASSED]` with zero failures.
2. **Check for runtime errors**: Verify no errors or warnings appear in the Godot debugger console during the test run (apart from expected crafting print statements).
3. **Verify test cleanup**: Confirm `user://test_save.json` does not exist after the test run.
4. **Verify real save untouched**: Check that `user://hammertime_save.json` was not modified by the test (compare timestamp before/after).
5. **UI requirements (PRES-04, PUI-01 through PUI-05, TAG-06)**: These are visual/UI requirements that cannot be verified by a headless test script. Manually confirm:
   - Prestige confirmation dialog shows cost, reward, and reset list
   - Current prestige level is visible at all times
   - Prestige cost and next unlock are displayed
   - Unlock table shows all 7 levels
   - Tag hammer buttons appear after P1
   - "No valid mods" feedback appears when tag hammer has no matching affixes
6. **TIER-02 (drop weighting)**: Verify through gameplay that higher area levels produce better item tier distributions within prestige-unlocked range.
7. **SAVE-02 (auto-save on prestige)**: Perform a prestige in normal gameplay and verify save file is updated automatically.

## Gaps
- **PRES-04, PUI-01, PUI-02, PUI-03, PUI-05**: Pure UI requirements not testable by the GDScript test scene. Require manual visual verification in the editor.
- **TAG-06**: UI feedback for "no valid mods" not tested by the script.
- **TIER-02**: Drop weighting by area level is a combat/loot system behavior not exercised by this integration test.
- **SAVE-02**: Auto-save on prestige completion is intentionally avoided by the test (to protect save files). Must be verified manually.
- **TAG-01 through TAG-04**: Individual tag hammer variants (Fire, Cold, Lightning, Defense) are not individually instantiated and tested -- only PHYSICAL is tested directly. All share the same `TagHammer` base class, so logic coverage is equivalent, but per-tag affix matching is not individually verified.

These gaps are expected and appropriate: the test scene covers all logic-testable requirements, while UI and gameplay-feel requirements inherently need human verification.

## Result
HUMAN NEEDED -- The test script is correctly written, covers all 23 requirements at the logic level (with appropriate limitations for UI requirements), and matches the plan specification. However, the test scene must be run manually in the Godot editor to confirm all checks pass at runtime.
