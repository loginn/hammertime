---
phase: 33-loot-table-rebalance
verified: 2026-02-19T16:00:00Z
status: passed
score: 13/13 must-haves verified
re_verification:
  previous_status: passed
  previous_score: 8/8
  previous_coverage: "Only covered 33-01 (loot table rebalance). 33-02 (hero health fixes, difficulty curve) was absent."
  gaps_closed:
    - "Hero FLAT_HEALTH double-counting fix (33-02 must-haves now verified)"
    - "Hero health sync to max_health (33-02 must-haves now verified)"
    - "Global PERCENT_HEALTH pass (33-02 must-haves now verified)"
    - "Difficulty curve reduction: GROWTH_RATE 0.07, boss walls +10/20/40% (33-02 must-haves now verified)"
  gaps_remaining: []
  regressions: []
---

# Phase 33: Loot Table Rebalance Verification Report

**Phase Goal:** Currency gates, drop counts, and item rarity all reflect the compressed 25-level biome structure — items always drop Normal, and currency unlocks arrive at the right biome thresholds. Additionally, gap closure fixes: hero health calculation (FLAT_HEALTH double-count, PERCENT_HEALTH global pass, health sync) and difficulty curve reduction (GROWTH_RATE 0.07, boss walls +10/+20/+40%).
**Verified:** 2026-02-19T16:00:00Z
**Status:** PASSED
**Re-verification:** Yes — previous VERIFICATION.md existed but covered only 33-01; this report covers both plans.

---

## Scope Note

The previous VERIFICATION.md (score 8/8) was accurate for 33-01 and has not regressed. This verification adds full coverage of 33-02 (hero health and difficulty) and confirms 33-01 items remain intact. Total must-haves across both plans: 13.

---

## Goal Achievement

### Observable Truths

| #  | Truth | Status | Evidence |
|----|-------|--------|----------|
| 1  | Forge Hammer starts at area 25, Grand at 50, Claw and Tuning at 75 | VERIFIED | `CURRENCY_AREA_GATES` in `loot_table.gd:17-24`: forge=25, grand=50, claw=75, tuning=75 |
| 2  | A newly unlocked currency ramps from low initial rate up to full rate over ~12 levels | VERIFIED | `_calculate_currency_chance` at `loot_table.gd:34-49`: `ramp_duration=12`, `sqrt(ramp_progress)` curve |
| 3  | Earlier currencies persist at full rate when new currencies unlock — no phase-out | VERIFIED | No phase-out logic exists. Only `area_level < unlock_level` gates; older currencies always pass this check |
| 4  | At full rate, currency drops occur roughly once per 3-5 packs | VERIFIED | `pack_currency_rules` at `loot_table.gd:64-71`: runic/tack/forge=0.25 (~1/4 packs), grand/claw/tuning=0.20 (~1/5 packs) |
| 5  | Items drop from individual pack kills, not from map completion | VERIFIED | `combat_engine.gd:150-151`: `roll_pack_item_drop()` called in `_on_pack_killed`. `_on_map_completed` has zero item drop logic |
| 6  | Most packs drop nothing — roughly 1-3 items total per map (8-15 packs) | VERIFIED | `PACK_ITEM_DROP_CHANCE = 0.18` at `loot_table.gd:28`. Expected: 8*0.18=1.4 to 15*0.18=2.7 items |
| 7  | Every item that drops has 0 affixes (Normal rarity) | VERIFIED | `get_random_item_base()` at `gameplay_view.gd:274-279`: creates item with no rarity/mod logic. `roll_rarity` and `spawn_item_with_mods` absent from all active `.gd` files |
| 8  | Map completion no longer awards items — only area progression continues | VERIFIED | `_on_map_completed` at `combat_engine.gd:172-184`: only restores HP/ES, increments level, auto-starts next map. No `items_dropped` emission |
| 9  | Hero max_health reflects base 100 + armor-slot base_health + weapon/ring FLAT_HEALTH from suffixes only (no double-counting from armor slots) | VERIFIED | `calculate_defense()` at `hero.gd:176-259`: armor loop (lines 189-208) reads `base_health` only. FLAT_HEALTH suffix loop (lines 230-238) scoped exclusively to `["weapon", "ring"]` |
| 10 | Hero health syncs to max_health after any stat recalculation | VERIFIED | `update_stats()` at `hero.gd:91-99`: `health = max_health` on line 99, executed after `calculate_defense()` on every equip/unequip/init |
| 11 | FLAT_ARMOR from weapon/ring suffixes is added once; armor-slot FLAT_ARMOR is not double-counted | VERIFIED | All-slots loop (lines 211-225) processes only resistance stat types. FLAT_ARMOR only in weapon/ring loop (lines 230-238). No FLAT_ARMOR check for helmet/armor/boots anywhere |
| 12 | Boss wall difficulty spikes use +10/+20/+40% bonuses (not the former +15/+35/+60%) | VERIFIED | `pack_generator.gd:64-66`: `boss_bonus = 0.10`, `0.20`, `0.40` with in-code comments "Was 0.15/0.35/0.60". No `1.0 + 0.60` anywhere in the file |
| 13 | GROWTH_RATE is 0.07 and relief dip calculations use 0.40 peak | VERIFIED | `pack_generator.gd:10`: `GROWTH_RATE: float = 0.07`. Lines 53 and 77: `peak_base * (1.0 + 0.40) * 0.70`. No `1.0 + 0.60` exists in any active file |

**Score:** 13/13 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `models/loot/loot_table.gd` | Currency gates at 25/50/75, 12-level sqrt ramp, per-pack item drop logic, Normal-only drop | VERIFIED | 100 lines. Contains `CURRENCY_AREA_GATES`, `PACK_ITEM_DROP_CHANCE=0.18`, `_calculate_currency_chance` with `ramp_duration=12` and `sqrt(ramp_progress)`, `roll_pack_item_drop()`. Dead functions (`roll_rarity`, `spawn_item_with_mods`, `get_map_item_count`) absent from file |
| `models/combat/combat_engine.gd` | Per-pack item drops via signal, map completion drops removed | VERIFIED | `_on_pack_killed` (lines 150-151) calls `LootTable.roll_pack_item_drop()` and emits `items_dropped`. `_on_map_completed` (lines 172-184) has no item drop logic |
| `scenes/gameplay_view.gd` | Item creation handler for per-pack drops, Normal-only item factory | VERIFIED | `_on_items_dropped` connected at line 54, handler at line 185. `get_random_item_base()` (lines 274-279) creates items with no rarity logic |
| `autoloads/game_events.gd` | Updated items_dropped signal — single area_level param | VERIFIED | `signal items_dropped(area_level: int)` at line 19. No `item_count` parameter |
| `models/hero.gd` | Fixed calculate_defense() with no double-counting, health sync in update_stats() | VERIFIED | 374 lines. `calculate_defense()` (lines 176-259) correctly splits suffix loops by category. `update_stats()` (lines 91-99): `health = max_health` at line 99. Global `PERCENT_HEALTH` pass via `StatCalculator.calculate_percentage_stat` at lines 249-251 |
| `models/monsters/pack_generator.gd` | Reduced GROWTH_RATE=0.07 and boss wall bonuses +10/20/40% | VERIFIED | 193 lines. `GROWTH_RATE = 0.07` at line 10. Boss wall match (lines 63-67): 0.10/0.20/0.40. Relief dip (lines 53, 77): `(1.0 + 0.40)`. No `0.60` value anywhere in file |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `models/combat/combat_engine.gd` | `models/loot/loot_table.gd` | `LootTable.roll_pack_item_drop()` in `_on_pack_killed` | WIRED | Line 150: `if LootTable.roll_pack_item_drop():` |
| `models/combat/combat_engine.gd` | `autoloads/game_events.gd` | `GameEvents.items_dropped.emit` on pack kill | WIRED | Line 151: `GameEvents.items_dropped.emit(GameState.area_level)` inside `_on_pack_killed`, not `_on_map_completed` |
| `scenes/gameplay_view.gd` | `autoloads/game_events.gd` | `GameEvents.items_dropped.connect` for per-pack item creation | WIRED | Line 54: `GameEvents.items_dropped.connect(_on_items_dropped)` |
| `models/hero.gd` | armor item base stats | `armor_item.base_health` read in armor slot loop (already includes item-level FLAT_HEALTH) | WIRED | Line 207: `total_health += armor_item.base_health` — reads baked value; no additional FLAT_HEALTH suffix loop for these slots |
| `models/hero.gd` | `models/stats/stat_calculator.gd` | `calculate_percentage_stat` for global PERCENT_HEALTH pass | WIRED | Lines 249-251: `StatCalculator.calculate_percentage_stat(float(total_health), all_percent_health_affixes, Tag.StatType.PERCENT_HEALTH)` |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|---------|
| PROG-03 | 33-01-PLAN | Currency area gates moved to match new biome boundaries (Forge at 25, Grand at 50, Claw/Tuning at 75) | SATISFIED | `CURRENCY_AREA_GATES` in `loot_table.gd:17-24`: forge=25, grand=50, claw=75, tuning=75 |
| PROG-04 | 33-01-PLAN | Currency unlock ramp duration scaled to ~12 levels | SATISFIED | `_calculate_currency_chance` default `ramp_duration=12` with `sqrt(ramp_progress)` curve at `loot_table.gd:34-49` |
| PROG-05 | 33-01-PLAN | Item drop count formula rescaled for compressed level range | SATISFIED | `PACK_ITEM_DROP_CHANCE=0.18` constant per-pack at `loot_table.gd:28`, targeting 1-3 items per 8-15 pack map |
| PROG-07 | 33-01-PLAN, 33-02-PLAN | All items drop at Normal rarity (0 affixes) | SATISFIED | `get_random_item_base()` at `gameplay_view.gd:274-279` creates items with no mod logic. `roll_rarity`, `spawn_item_with_mods`, `get_map_item_count` confirmed absent from all active `.gd` files (grep returns only planning docs) |

**Orphaned requirements check:** REQUIREMENTS.md Traceability table maps PROG-03, PROG-04, PROG-05, PROG-07 to Phase 33. Both 33-01-PLAN and 33-02-PLAN list all four IDs in their `requirements:` frontmatter. No orphaned requirements. PROG-06 is correctly deferred to Phase 34.

**Note on 33-02 requirements field:** 33-02-PLAN lists `requirements: [PROG-03, PROG-04, PROG-05, PROG-07]` — a copy of the 33-01 list. The gap closure work (hero health, difficulty curve) does not map to any v1.6 requirement ID. This is accurate — the health and difficulty fixes were UAT-driven correctness work, not formal requirements deliverables.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `scenes/gameplay_view.gd` | 185 | `_on_items_dropped(completed_level: int)` — `completed_level` parameter received but never read inside the function body | Info | GDScript convention for intentionally unused params is `_completed_level`. No functional impact; `get_random_item_base()` correctly creates Normal items without using the level |
| `models/loot/loot_table.gd` | 3-14 | `RARITY_ANCHORS` const retained with legacy comment | Info | 33-01-PLAN Task 2 Step B said to remove it; SUMMARY documents deliberate retention. Grep confirms no active `.gd` file references it in a call path — dead data only. Not a blocker |

No blocker or warning anti-patterns found.

---

### Human Verification Required

#### 1. Currency Drop Feel at Biome Boundary (Area 25)

**Test:** Run maps at area 24, then advance to area 25. Kill packs at both levels and observe Forge Hammer drops.
**Expected:** Forge Hammer does not drop at area 24. At area 25 it appears at noticeably lower-than-full rate (~29% of 0.25 = ~7% effective chance per pack). By area 37 it should feel about as frequent as runic/tack.
**Why human:** The sqrt ramp curve produces correct numbers but the subjective "immediate but low" feel requires play observation.

#### 2. Item Drop Frequency Per Map

**Test:** Run 5-10 full maps (all packs cleared). Count item drops per map.
**Expected:** Roughly 1-3 items per map on average. Very few maps yield 0 or 4+ items.
**Why human:** Probabilistic outcome — code is correct at 18% per pack, but actual play feel requires direct observation.

#### 3. Normal Rarity Confirmation in UI

**Test:** Pick up items that drop during combat. Inspect them in the Forge view.
**Expected:** All dropped items show Normal rarity (white name color, 0 affixes). No Magic or Rare items appear from drops.
**Why human:** Visual rarity display must be confirmed through the UI.

#### 4. Hero Health Scaling Feels Correct Post-Fix

**Test:** Equip a helmet with a FLAT_HEALTH suffix, note max_health. Then equip a weapon with a FLAT_HEALTH suffix, note max_health again. Unequip both and confirm return to base.
**Expected:** Each piece contributes its health once with no inflation. Hero health equals max_health immediately after each equip/unequip action.
**Why human:** The fix prevents double-counting; correctness with specific item values and the visual display requires in-game observation.

#### 5. Zone 20-25 Progressability

**Test:** Start a run with moderate gear (a few items hammered to Magic). Progress through zones 20-24 into zone 25.
**Expected:** The zone 22-24 boss wall (+10/+20/+40% spike) is noticeable but surmountable. Zone 25 (relief dip) feels like reduced pressure compared to zone 24. No impassable wall with reasonable gear.
**Why human:** "Surmountable with reasonable gear" is subjective. The difficulty numbers are correct in code; the feel requires play.

---

### Regression Check (33-01 Items)

All 8 truths from the previous VERIFICATION.md were re-confirmed against the current codebase. No regressions detected:

- `CURRENCY_AREA_GATES`: forge=25, grand=50, claw/tuning=75 — unchanged
- `_calculate_currency_chance`: ramp_duration=12, sqrt curve — unchanged
- `PACK_ITEM_DROP_CHANCE=0.18` — unchanged
- `roll_pack_item_drop()`: present, returns bool — unchanged
- `_on_pack_killed` emits `items_dropped`; `_on_map_completed` does not — unchanged
- `roll_rarity`, `spawn_item_with_mods`, `get_map_item_count`: absent from all active `.gd` files — confirmed
- `signal items_dropped(area_level: int)`: no `item_count` param — unchanged
- `_on_items_dropped` connected; `get_random_item_base()` returns Normal items — unchanged

---

### Gaps Summary

No gaps. All 13 must-have truths are verified across both plans. All 6 artifacts pass existence, substantive content, and wiring checks. All 5 key links are confirmed wired in active code. All 4 requirement IDs (PROG-03, PROG-04, PROG-05, PROG-07) are satisfied with direct code evidence.

**Notable non-blocking items (unchanged from previous verification):**

1. `RARITY_ANCHORS` dict retained with legacy comment in `loot_table.gd` — dead data, no active references.
2. `completed_level` parameter in `_on_items_dropped(completed_level: int)` is never used — cosmetic code smell only.

---

_Verified: 2026-02-19T16:00:00Z_
_Verifier: Claude (gsd-verifier)_
