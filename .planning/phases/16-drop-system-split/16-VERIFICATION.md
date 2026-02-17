---
phase: 16-drop-system-split
status: passed
verified: 2026-02-17
score: 4/4
---

# Phase 16: Drop System Split - Verification

## Phase Goal
Packs drop currency when killed, map completion drops items, death keeps currency earned

## Must-Have Verification

### 1. Each pack killed adds currency to hero's inventory immediately
**Status:** PASSED
**Evidence:** `CombatEngine._on_pack_killed()` calls `LootTable.roll_pack_currency_drop(area_level, killed_pack.difficulty_bonus)` then `GameState.add_currencies(drops)` — currency is added to inventory immediately on pack death, before advancing to next pack.
**Files:** `models/combat/combat_engine.gd:134-136`, `models/loot/loot_table.gd:147-179`

### 2. Map completion (all packs cleared) awards item drops
**Status:** PASSED
**Evidence:** `CombatEngine._on_map_completed()` calls `LootTable.get_map_item_count(area_level)` then `GameEvents.items_dropped.emit(area_level, item_count)`. `gameplay_view._on_items_dropped()` creates items via `get_random_item_base()` using `LootTable.roll_rarity()` and `spawn_item_with_mods()`.
**Files:** `models/combat/combat_engine.gd:159-161`, `scenes/gameplay_view.gd:105-110`

### 3. Hero death ends the current map without item drops but keeps all currency earned from killed packs
**Status:** PASSED
**Evidence:** `_on_hero_died()` does NOT emit `items_dropped` — only `hero_died` signal. Currency is already in `GameState.currency_counts` from per-pack `add_currencies()` calls. No clawback mechanism exists. Old `gameplay_view._on_map_completed` drop code completely removed.
**Files:** `models/combat/combat_engine.gd:175-182`, `scenes/gameplay_view.gd:92-95`

### 4. Currency earned from partial progress is visible and preserved through death
**Status:** PASSED
**Evidence:** `run_currency_earned` dictionary accumulates per-pack drops in CombatEngine (for UI display in Phase 17). Actual currency stored in `GameState.currency_counts` via immediate `add_currencies()` — persists through death since no removal code exists.
**Files:** `models/combat/combat_engine.gd:16,37,193-199`, `autoloads/game_state.gd:33-36`

## Requirements Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| DROP-01: Packs drop currency when killed | PASSED | roll_pack_currency_drop called in _on_pack_killed |
| DROP-02: Map completion drops items | PASSED | get_map_item_count + items_dropped signal |
| DROP-03: Currency kept on hero death | PASSED | No clawback, currency added immediately per-pack |
| COMBAT-04: Death loses map but keeps currency | PASSED | Death path has no item emission, currency persists |

## Score: 4/4 must-haves verified
