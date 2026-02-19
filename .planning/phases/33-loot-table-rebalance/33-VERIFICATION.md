---
phase: 33-loot-table-rebalance
verified: 2026-02-19T14:30:00Z
status: passed
score: 8/8 must-haves verified
re_verification: false
---

# Phase 33: Loot Table Rebalance Verification Report

**Phase Goal:** Currency gates, drop counts, and item rarity all reflect the compressed 25-level biome structure — items always drop Normal, and currency unlocks arrive at the right biome thresholds
**Verified:** 2026-02-19T14:30:00Z
**Status:** PASSED
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #  | Truth                                                                                                            | Status     | Evidence                                                                                              |
|----|------------------------------------------------------------------------------------------------------------------|------------|-------------------------------------------------------------------------------------------------------|
| 1  | Forge Hammer starts at area 25, Grand at 50, Claw and Tuning at 75                                              | VERIFIED  | `CURRENCY_AREA_GATES` in `loot_table.gd:17-24`: forge=25, grand=50, claw=75, tuning=75               |
| 2  | A newly unlocked currency ramps from low initial rate up to full rate over ~12 levels                            | VERIFIED  | `_calculate_currency_chance` at `loot_table.gd:34-49`: `ramp_duration=12`, `sqrt(ramp_progress)` curve |
| 3  | Earlier currencies persist at full rate when new currencies unlock — no phase-out                                 | VERIFIED  | No phase-out logic exists. Only `area_level < unlock_level` gates; older currencies always pass this |
| 4  | At full rate, currency drops occur roughly once per 3-5 packs                                                    | VERIFIED  | `pack_currency_rules` at `loot_table.gd:64-71`: runic/tack/forge=0.25 (~1/4 packs), grand/claw/tuning=0.20 (~1/5 packs) |
| 5  | Items drop from individual pack kills, not from map completion                                                   | VERIFIED  | `combat_engine.gd:149-151`: `roll_pack_item_drop()` called in `_on_pack_killed`. `_on_map_completed` has zero item drop logic |
| 6  | Most packs drop nothing — roughly 1-3 items total per map (8-15 packs)                                          | VERIFIED  | `PACK_ITEM_DROP_CHANCE = 0.18` at `loot_table.gd:28`. Expected: 8*0.18=1.4 to 15*0.18=2.7 items     |
| 7  | Every item that drops has 0 affixes (Normal rarity)                                                              | VERIFIED  | `get_random_item_base()` at `gameplay_view.gd:274-279`: creates item with no rarity/mod logic. `roll_rarity` and `spawn_item_with_mods` removed |
| 8  | Map completion no longer awards items — only area progression continues                                          | VERIFIED  | `_on_map_completed` at `combat_engine.gd:172-184`: only restores HP/ES, increments level, auto-starts next map. No `items_dropped` emission |

**Score:** 8/8 truths verified

---

### Required Artifacts

| Artifact                              | Expected                                                    | Status    | Details                                                                                          |
|---------------------------------------|-------------------------------------------------------------|-----------|--------------------------------------------------------------------------------------------------|
| `models/loot/loot_table.gd`          | Currency gates at 25/50/75, 12-level ramp, per-pack item drop logic, Normal-only drop | VERIFIED | Contains `CURRENCY_AREA_GATES`, `PACK_ITEM_DROP_CHANCE=0.18`, `_calculate_currency_chance` with sqrt curve, `roll_pack_item_drop()` |
| `models/combat/combat_engine.gd`     | Per-pack item drops via signal, map completion drops removed | VERIFIED  | `_on_pack_killed` calls `LootTable.roll_pack_item_drop()` and emits `items_dropped`. `_on_map_completed` has no item drop logic |
| `scenes/gameplay_view.gd`            | Item creation handler for per-pack drops, Normal-only item factory | VERIFIED | `_on_items_dropped` connected at line 54, handler at line 185. `get_random_item_base()` creates items with no rarity logic |
| `autoloads/game_events.gd`           | Updated items_dropped signal for per-pack use               | VERIFIED  | `signal items_dropped(area_level: int)` at line 19 — single param, no `item_count`             |

---

### Key Link Verification

| From                          | To                            | Via                                              | Status   | Details                                                      |
|-------------------------------|-------------------------------|--------------------------------------------------|----------|--------------------------------------------------------------|
| `models/combat/combat_engine.gd` | `models/loot/loot_table.gd` | `LootTable.roll_pack_item_drop()` in `_on_pack_killed` | WIRED | Found at `combat_engine.gd:150`: `if LootTable.roll_pack_item_drop()` |
| `models/combat/combat_engine.gd` | `autoloads/game_events.gd`   | `GameEvents.items_dropped.emit` on pack kill     | WIRED    | Found at `combat_engine.gd:151`: `GameEvents.items_dropped.emit(GameState.area_level)` — inside `_on_pack_killed`, not `_on_map_completed` |
| `scenes/gameplay_view.gd`     | `autoloads/game_events.gd`   | `GameEvents.items_dropped.connect` for per-pack item creation | WIRED | Found at `gameplay_view.gd:54`: `GameEvents.items_dropped.connect(_on_items_dropped)` |

---

### Requirements Coverage

| Requirement | Source Plan | Description                                                          | Status    | Evidence                                                                    |
|-------------|-------------|----------------------------------------------------------------------|-----------|-----------------------------------------------------------------------------|
| PROG-03     | 33-01-PLAN  | Currency area gates moved to match new biome boundaries (Forge at 25, Grand at 50, Claw/Tuning at 75) | SATISFIED | `CURRENCY_AREA_GATES` in `loot_table.gd`: forge=25, grand=50, claw=75, tuning=75 |
| PROG-04     | 33-01-PLAN  | Currency unlock ramp duration scaled to ~12 levels                   | SATISFIED | `_calculate_currency_chance` default `ramp_duration=12` with `sqrt(ramp_progress)` curve |
| PROG-05     | 33-01-PLAN  | Item drop count formula rescaled for compressed level range          | SATISFIED | `PACK_ITEM_DROP_CHANCE=0.18` constant per-pack (no area scaling), targeting 1-3 items per 8-15 pack map |
| PROG-07     | 33-01-PLAN  | All items drop at Normal rarity (0 affixes)                          | SATISFIED | `get_random_item_base()` creates items with no mod logic; `roll_rarity`, `spawn_item_with_mods`, `get_map_item_count` all removed |

No orphaned requirements: REQUIREMENTS.md traceability table maps PROG-03, PROG-04, PROG-05, PROG-07 to Phase 33. All four are claimed by 33-01-PLAN. Coverage complete.

---

### Anti-Patterns Found

| File                              | Line | Pattern               | Severity | Impact                                                                                     |
|-----------------------------------|------|-----------------------|----------|--------------------------------------------------------------------------------------------|
| `scenes/gameplay_view.gd`         | 185  | Unused parameter `completed_level` in `_on_items_dropped(completed_level: int)` | Info | Parameter receives `area_level` from signal but is never read in the function body. Cosmetic dead code — no functional impact. `get_random_item_base()` correctly creates Normal items without using the level. |
| `models/loot/loot_table.gd`       | 3-14 | `RARITY_ANCHORS` const retained | Info | Plan Task 2 Step B said to remove it; SUMMARY notes it was kept with a "legacy" comment as a deliberate deviation. No active code references it anywhere in the codebase — it is dead data, not dead logic. Not a blocker. |

No blocker or warning anti-patterns found.

---

### Human Verification Required

#### 1. Currency Drop Feel at Biome Boundary

**Test:** Start a run at area 24 (last Forest level). Kill several packs. Note which currencies drop. Advance to area 25. Kill packs and observe Forge Hammer drops appearing.
**Expected:** Forge Hammer does not drop at area 24. At area 25 it appears at a noticeably lower-than-full rate (~29% of 0.25 = ~7% effective chance). By area 37 (25+12) it should feel about as frequent as runic/tack.
**Why human:** The sqrt ramp curve produces correct numbers but the subjective "immediate but low" feel requires playing through the boundary.

#### 2. Item Drop Frequency Per Map

**Test:** Run 5-10 full maps (all packs cleared). Count item drops per map.
**Expected:** Roughly 1-3 items per map on average. Very few maps should yield 0 or 4+ items.
**Why human:** Probabilistic outcome — code is correct at 18% per pack, but actual play feel and whether it feels rewarding requires direct observation.

#### 3. Normal Rarity Confirmation in UI

**Test:** Pick up items that drop during combat. Inspect them in the Forge view.
**Expected:** All dropped items show Normal rarity (white name color, 0 affixes). No Magic or Rare items appear from drops.
**Why human:** Visual rarity display and absence of affixes must be confirmed through the UI, not just from code inspection.

---

### Gaps Summary

No gaps. All 8 must-have truths are verified. All 4 artifacts pass existence, substantive content, and wiring checks. All 3 key links are confirmed wired in active code. All 4 requirement IDs (PROG-03, PROG-04, PROG-05, PROG-07) are satisfied with direct evidence.

**Notable deviation from plan (non-blocking):** Plan Task 2 Step B instructed removing `RARITY_ANCHORS`. The SUMMARY documents a deliberate choice to retain it with a legacy comment. Since no code anywhere references `RARITY_ANCHORS` in an active call path, this is dead data — its presence does not affect any truth or requirement.

**Minor code smell (non-blocking):** The `completed_level` parameter in `_on_items_dropped(completed_level: int)` is accepted from the signal but never used. Renaming it to `_completed_level` (GDScript convention for intentionally ignored params) would be cleaner, but this does not affect behavior.

---

_Verified: 2026-02-19T14:30:00Z_
_Verifier: Claude (gsd-verifier)_
