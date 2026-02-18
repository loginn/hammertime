---
phase: 27-save-format-migration
status: passed
score: 4/4
verified: 2026-02-18
---

# Phase 27: Save Format Migration - Verification

## Phase Goal
Save/load correctly handles the v2 per-slot array format and migrates any existing v1 saves without data loss

## Must-Have Truths

### 1. Loading a hand-crafted v1 save produces per-slot arrays with the correct item count in each slot
**Status:** PASSED
**Evidence:**
- `_migrate_save()` (line 150-160) detects `saved_version < 2` and calls `_migrate_v1_to_v2()`
- `_migrate_v1_to_v2()` (line 163-178) wraps each v1 single-item dict into `[item_data]` and null/missing into `[]`
- All 5 canonical slots handled: weapon, helmet, armor, boots, ring

### 2. Loading a v2 save round-trips all items in all slots without loss or duplication
**Status:** PASSED
**Evidence:**
- `_build_save_data()` writes `[item.to_dict()]` for present items, `[]` for null slots (lines 84-90)
- `_restore_state()` reads `slot_data[0]` from array and deserializes via `Item.create_from_dict()` (lines 124-135)
- `_migrate_save()` correctly skips migration for v2 saves (`saved_version < 2` is false)
- Complete round-trip: item -> `[item.to_dict()]` -> JSON -> load -> `slot_data[0]` -> `Item.create_from_dict()` -> item

### 3. The orphaned crafting_bench_item key is absent from both written saves and migrated saves
**Status:** PASSED
**Evidence:**
- `_build_save_data()` return dict (lines 92-101): `crafting_bench_item` key absent
- `_migrate_v1_to_v2()` line 176: `data.erase("crafting_bench_item")` strips from migrated saves
- `_restore_state()`: no `crafting_bench_item` restoration code present
- grep confirms: no write of "crafting_bench_item" to save dict anywhere in save_manager.gd

### 4. A fresh game save (version 2) loads back to empty arrays for all five slots
**Status:** PASSED
**Evidence:**
- Fresh game: `GameState.crafting_inventory` = `{"weapon": null, ...}` (from `initialize_fresh_game()`)
- `_build_save_data()`: null items produce `[]` for each slot
- Save writes: `"version": 2, "crafting_inventory": {"weapon": [], "helmet": [], ...}`
- Load: `_restore_state()` reads empty arrays and sets null for each GameState slot
- SAVE_VERSION constant is 2

## Requirement Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| SAVE-01 | PASSED | Save writes arrays, load reads arrays, migration converts v1 to v2 arrays |

## Artifact Verification

| Artifact | Status | Evidence |
|----------|--------|---------|
| autoloads/save_manager.gd | PRESENT | Contains `_migrate_v1_to_v2`, SAVE_VERSION=2, array build/restore |

## Key Link Verification

| Link | Status | Evidence |
|------|--------|---------|
| _migrate_save -> _migrate_v1_to_v2 | WIRED | Line 156-157: `if saved_version < 2: data = _migrate_v1_to_v2(data)` |
| _build_save_data -> GameState.crafting_inventory | WIRED | Line 88: `[item.to_dict()]` wraps items into arrays |
| _restore_state -> GameState.crafting_inventory | WIRED | Line 129-131: `slot_data[0]` extracts first item from array |

## Human Verification Items

1. **Fresh start test:** Delete save file, launch game, play until first save triggers, verify save file contains v2 format with empty arrays
2. **Existing save migration:** If a v1 save exists, launch game and verify it loads without errors and gameplay works normally

## Result

**Score:** 4/4 must-have truths verified
**Status:** PASSED
**Recommendation:** Phase goal achieved. Ready to proceed to Phase 28.
