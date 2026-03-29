---
phase: 56-difficulty-starter-kit
verified: 2026-03-28T00:00:00Z
status: passed
score: 9/9 must-haves verified
re_verification: false
---

# Phase 56: Difficulty & Starter Kit Verification Report

**Phase Goal:** Fresh P0 heroes can engage with the crafting loop from zone 1 — starter items in stash, starter hammers, and tuned Forest difficulty.
**Verified:** 2026-03-28
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths (from ROADMAP.md Success Criteria + Plan must_haves)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | A fresh P0 hero clears zone 1 Forest packs without dying | VERIFIED | Forest monster base_hp/damage reduced ~50% (Bear: 20.0/3.5, Golem: 26.0/2.0); BIOME_STAT_RATIOS[25]=2.81; Group 42 tests confirm values |
| 2 | A new game starts with a starter weapon and armor in the stash | VERIFIED | `initialize_fresh_game()` calls `_place_starter_kit(null)` at line 136; places Broadsword + IronPlate; Group 43 confirms stash["weapon"][0] is Broadsword, stash["armor"][0] is IronPlate |
| 3 | A new game starts with 2 Transmute Hammers and 2 Augment Hammers | VERIFIED | `currency_counts = {"transmute": 2, "augment": 2, ...}` in `initialize_fresh_game()` (lines 124-131) and `_wipe_run_state()` (lines 171-178) |
| 4 | Early Forest pack HP/damage tuned so starter gear is sufficient | VERIFIED | All 6 Forest monster types at target values in biome_config.gd lines 64-69; avg HP 15.67 vs original 27.0 |
| 5 | Post-prestige archetype selection places archetype-matched starter items | VERIFIED | `main_view._on_hero_card_selected()` calls `GameState._place_starter_kit(hero)` at line 285; Group 44 tests STR/DEX/INT archetypes |
| 6 | STR gets Broadsword+IronPlate, DEX gets Dagger+LeatherVest, INT gets Wand+SilkRobe | VERIFIED | `_place_starter_kit()` match block lines 99-108; confirmed by Group 44 assertions |
| 7 | All runtime currency keys use PoE names (transmute, augment, alteration, regal, chaos, exalt) | VERIFIED | Zero old keys ("runic", "forge", "tack", "grand", "claw", "tuning") found in any of the 6 affected files excluding asset paths and comments |
| 8 | _wipe_run_state does NOT place starter kit (items placed after archetype selection, not during wipe) | VERIFIED | `_wipe_run_state()` (lines 153-188) contains no call to `_place_starter_kit` |
| 9 | Integration test groups 42-44 exercise all three work streams | VERIFIED | Groups registered in `_run_all_groups()` (lines 52-54); Group 42 verifies Forest stats, Group 43 fresh game currencies+items, Group 44 all 3 archetype kits |

**Score:** 9/9 truths verified

---

### Required Artifacts

| Artifact | Status | Details |
|----------|--------|---------|
| `autoloads/game_state.gd` | VERIFIED | Contains `"transmute": 2` and `"augment": 2` in both `initialize_fresh_game()` and `_wipe_run_state()`; contains `func _place_starter_kit(archetype: HeroArchetype) -> void:` at line 92; calls `_place_starter_kit(null)` at line 136 |
| `autoloads/prestige_manager.gd` | VERIFIED | Contains `"augment": 100` and `"augment": 999999` for all 7 prestige levels; no old `"forge"` keys |
| `models/loot/loot_table.gd` | VERIFIED | `CURRENCY_AREA_GATES` uses `"transmute"`, `"augment"`, `"alteration"`, `"regal"`, `"chaos"`, `"exalt"`; `pack_currency_rules` likewise; no old keys |
| `scenes/forge_view.gd` | VERIFIED | `"transmute": RunicHammer.new()`, `"augment": ForgeHammer.new()` etc. in all 4 dicts; preload paths still reference original asset filenames (`runic_hammer.png`, `forge_hammer.png`); GDScript class names unchanged |
| `scenes/prestige_view.gd` | VERIFIED | Line 39: `"Next: " + str(cost["augment"]) + " Augment Hammers"`; line 111: `str(PrestigeManager.PRESTIGE_COSTS[level]["augment"]) + " Augment"`; no `"Forge Hammers"` strings |
| `models/monsters/biome_config.gd` | VERIFIED | All 6 Forest monster types at tuned values: Bear(20.0/3.5), Wolf(14.0/3.0), Boar(18.0/4.0), Spider(9.0/3.5), Sprite(7.0/2.5), Golem(26.0/2.0) |
| `models/monsters/pack_generator.gd` | VERIFIED | `BIOME_STAT_RATIOS[25] = 2.81`; comment reads "Forest avg HP: (20+14+18+9+7+26)/6 = 15.67" |
| `scenes/main_view.gd` | VERIFIED | `_on_hero_card_selected()` calls `GameState._place_starter_kit(hero)` at line 285; view name strings ("forge") unchanged |
| `tools/test/integration_test.gd` | VERIFIED | `func _group_42_forest_difficulty_tuning()` at line 2127, `func _group_43_starter_kit_fresh_game()` at line 2153, `func _group_44_starter_kit_post_prestige()` at line 2182; all three registered in `_run_all_groups()` |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `scenes/forge_view.gd` | `autoloads/game_state.gd` | `currency_counts["transmute"]` lookup | VERIFIED | forge_view keys "transmute"/"augment" etc. match game_state currency_counts keys exactly |
| `autoloads/prestige_manager.gd` | `autoloads/game_state.gd` | `spend_currency` uses same key names | VERIFIED | Both use `"augment"` as prestige cost key; no old "forge" keys remain |
| `models/loot/loot_table.gd` | `autoloads/game_state.gd` | `add_currencies` uses same key names | VERIFIED | loot_table drop keys match game_state currency_counts keys |
| `scenes/main_view.gd` | `autoloads/game_state.gd` | `_on_hero_card_selected` calls `_place_starter_kit` | VERIFIED | Line 285: `GameState._place_starter_kit(hero)` |
| `autoloads/game_state.gd` | `autoloads/game_state.gd` | `initialize_fresh_game` calls `_place_starter_kit(null)` | VERIFIED | Line 136: `_place_starter_kit(null)  # P0 default: STR items` |
| `autoloads/game_state.gd` | `models/items/*.gd` | `_place_starter_kit` instantiates archetype-matched items | VERIFIED | `Broadsword.new(8)`, `Dagger.new(8)`, `Wand.new(8)`, `IronPlate.new(8)`, `LeatherVest.new(8)`, `SilkRobe.new(8)` all present in match block |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| DIFF-01 | 56-02-PLAN.md | Fresh P0 hero survives Forest packs consistently with starter gear | SATISFIED | Forest monster HP/damage ~50% reduction in biome_config.gd; BIOME_STAT_RATIOS[25]=2.81; Group 42 tests verify stats |
| DIFF-03 | 56-01-PLAN.md, 56-02-PLAN.md | Fresh hero starts with starter weapon + armor in stash, plus 2 Transmute and 2 Augment hammers | SATISFIED | `_place_starter_kit(null)` in `initialize_fresh_game()`; currency_counts initialized with `"transmute": 2, "augment": 2`; Groups 43-44 verify |

No orphaned requirements found. Both DIFF-01 and DIFF-03 are mapped to Phase 56 in REQUIREMENTS.md and claimed in plan frontmatter.

---

### Anti-Patterns Found

None detected. Full scan of all modified files:

- No old currency key strings ("runic", "forge", "tack", "grand", "claw", "tuning") in any affected file outside comments and asset preload paths
- No TODO/FIXME/placeholder comments in modified functions
- No stub return values (empty arrays, null returns) in `_place_starter_kit()` — all branches instantiate real items
- `_wipe_run_state()` correctly does NOT call `_place_starter_kit()` (that is intentional, not a gap)
- `main_view.gd` forge view name strings ("forge") are view identifiers, not currency keys — correctly left unchanged
- Test deviation from plan (REGISTRY keys "str_hit"/"dex_hit"/"int_hit" not "knight"/"ranger"/"sorcerer") was self-corrected in 346da5d

---

### Human Verification Required

#### 1. Zone 1 Forest survival feel

**Test:** Start a new game, enter zone 1 Forest, clear 10-15 packs with the starter Broadsword equipped
**Expected:** Hero survives all packs; HP does not drop to zero; combat feels appropriately challenging but winnable
**Why human:** The math model (18.9 DPS vs avg 15.67 HP, ~5 dmg/pack, 75 dmg total vs 105 effective HP) checks out analytically, but actual Godot combat simulation depends on speed ratios, hit timing, and pack size variance that grep cannot verify

#### 2. Post-prestige archetype selection flow

**Test:** Complete a prestige, select DEX archetype from the hero selection overlay, then open stash
**Expected:** Stash contains one Dagger and one LeatherVest (Normal rarity, no affixes); two saves occur (archetype save + starter kit save)
**Why human:** The double `SaveManager.save_game()` call path in `_on_hero_card_selected` needs runtime verification to confirm the second save does not clobber the first, and that the overlay dismiss animation completes cleanly

---

### Commit Verification

All four commits cited in summaries confirmed in git log:
- `b058d8d` — feat(56-01): rename all 6 currency keys to PoE conventions and update starter counts
- `a46e29f` — feat(56-02): add _place_starter_kit() and wire into initialization + archetype selection
- `0673297` — feat(56-02): tune Forest difficulty and update BIOME_STAT_RATIOS
- `346da5d` — test(56-02): add integration test groups 42-44 for difficulty and starter kit

---

_Verified: 2026-03-28_
_Verifier: Claude (gsd-verifier)_
