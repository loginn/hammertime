---
phase: 07-drop-integration
plan: 02
subsystem: drop-system
tags: [currency, loot, drops, gameplay, crafting]
dependency-graph:
  requires:
    - "06-02: All 6 currency types implemented"
    - "07-01: LootTable with rarity-weighted item drops"
  provides:
    - "Currency drop system with 6 hammer types"
    - "GameState currency inventory tracking"
    - "Crafting view currency display"
  affects:
    - "scenes/gameplay_view.gd: give_hammer_rewards() now drops 6 currencies"
    - "scenes/crafting_view.gd: Displays all 6 currency counts"
    - "autoloads/game_state.gd: Tracks currency inventory"
tech-stack:
  added:
    - "Currency drop table in LootTable"
    - "GameState currency tracking"
  patterns:
    - "Independent drop chances per currency type"
    - "Area-level scaling via bonus drops"
    - "Temporary mapping to old 3-button crafting system"
key-files:
  created: []
  modified:
    - path: "models/loot/loot_table.gd"
      lines: 44
      purpose: "Added roll_currency_drops() with per-currency chances and area bonuses"
    - path: "autoloads/game_state.gd"
      lines: 30
      purpose: "Added currency_counts dict with add_currencies() and spend_currency()"
    - path: "scenes/gameplay_view.gd"
      lines: 13
      purpose: "Replaced hammers_found signal with currencies_found, integrated currency drops"
    - path: "scenes/crafting_view.gd"
      lines: 32
      purpose: "Added on_currencies_found(), currency display, mapped to old buttons"
    - path: "scenes/main_view.gd"
      lines: 1
      purpose: "Updated signal connection to currencies_found"
decisions:
  - "Each currency has independent drop chance (not mutually exclusive)"
  - "Area bonus drops add to currencies that already dropped (richer rewards in harder areas)"
  - "Guarantee 1 runic hammer if no currencies drop (prevent empty clears)"
  - "Map currencies to old 3-button system as temporary bridge (Phase 8 will add 6 new buttons)"
  - "Display all 6 currency counts in crafting inventory (full visibility)"
  - "Start hammer_counts at 0 instead of 10 (no free hammers)"
metrics:
  duration: 132
  completed: "2026-02-15T10:14:38Z"
---

# Phase 07 Plan 02: Currency Drops Summary

All 6 hammer types drop from area clearing with appropriate rates, tracked in GameState, and displayed in crafting view.

## What Was Built

Replaced the old 3-hammer drop system with drops for all 6 currency types. Currency counts are tracked in GameState and displayed in the crafting view. Old 3-button crafting system still works via temporary mapping.

### Task 1: Add currency drop tables to LootTable and currency tracking to GameState
**Commit:** 324aef5
**Status:** Complete

**Extended LootTable** with `roll_currency_drops(area_level: int) -> Dictionary`:

Per-currency drop chances (independent rolls):
- **Runic:** 70% chance, 1-2 quantity (most common)
- **Forge:** 30% chance, 1 quantity
- **Tack:** 50% chance, 1-2 quantity
- **Grand:** 20% chance, 1 quantity (rarest)
- **Claw:** 40% chance, 1-2 quantity
- **Tuning:** 40% chance, 1-2 quantity

**Area level scaling:** `(area_level - 1)` bonus drops distributed randomly to currencies that already dropped. This makes higher-level areas more rewarding.

**Safety net:** If no currencies drop at all, guarantee 1 runic hammer (basic currency).

**Extended GameState** with currency tracking:
- `currency_counts` dictionary initialized with all 6 types at 0
- `add_currencies(drops: Dictionary)` - adds dropped currencies to inventory
- `spend_currency(currency_type: String) -> bool` - spends one currency, returns success

All functions have explicit return type hints.

**Files modified:**
- `models/loot/loot_table.gd` (+44 lines)
- `autoloads/game_state.gd` (+30 lines)

### Task 2: Wire currency drops into gameplay_view and display in crafting_view
**Commit:** 8af22eb
**Status:** Complete

**Updated gameplay_view.gd:**
- Replaced `hammers_found` signal with `currencies_found(drops: Dictionary)`
- Replaced `give_hammer_rewards()` implementation:
  - Calls `LootTable.roll_currency_drops(area_level)`
  - Stores in GameState via `GameState.add_currencies(drops)`
  - Prints drop breakdown to console
  - Emits `currencies_found` signal

**Updated crafting_view.gd:**
- Replaced `add_hammers()` with `on_currencies_found(drops: Dictionary)`
- Maps currencies to old 3-button system for backward compatibility:
  - **Implicit button:** Tuning + Claw hammers
  - **Prefix button:** Runic + Tack + Forge hammers
  - **Suffix button:** Runic + Grand + Forge hammers
- Added currency display section to `update_inventory_display()`:
  - Shows all 6 currency types from `GameState.currency_counts`
  - Format: "Runic Hammer: X", "Forge Hammer: X", etc.
- Changed `hammer_counts` starting values from 10 to 0 (no free hammers)

**Updated main_view.gd:**
- Changed signal connection from `hammers_found` to `currencies_found`

**Files modified:**
- `scenes/gameplay_view.gd` (+13 lines, -9 lines)
- `scenes/crafting_view.gd` (+32 lines, -27 lines)
- `scenes/main_view.gd` (+1 line, -1 line)

## Success Criteria Met

- [x] All 6 hammer types drop from area clearing
- [x] Drop rates vary: Runic most common (70%), Grand rarest (20%)
- [x] Higher area levels produce bonus drops (area_level - 1 extra drops)
- [x] Currency counts tracked in GameState.currency_counts
- [x] Currency counts displayed in crafting view (all 6 types visible)
- [x] Old 3-button crafting still functions via temporary mapping
- [x] All GDScript functions have explicit return type hints
- [x] DROP-02 requirement satisfied: Hammers drop from enemies

## Deviations from Plan

None - plan executed exactly as written.

## Requirements Satisfied

**DROP-02:** Hammers drop from enemies as loot
- All 6 currency types drop independently on area clear
- Drop rates scale with area level via bonus drops
- Currency inventory tracked persistently in GameState

## Technical Details

**Currency drop system:**
- Each currency has independent drop chance (not mutually exclusive)
- Quantities determined by randi_range for each currency type
- Area bonus = (area_level - 1) extra drops added to random currencies that already dropped
- Guarantees at least 1 runic hammer if no currencies drop (safety net)
- Returns dictionary with only non-zero entries

**GameState integration:**
- Centralized currency tracking in autoload
- add_currencies() iterates drops dict and adds to currency_counts
- spend_currency() validates and decrements, returns success boolean
- Currency counts persist across gameplay sessions (as long as GameState lives)

**Crafting view bridge:**
- on_currencies_found() maps to old hammer_counts for 3-button compatibility
- Runic hammers counted for both prefix AND suffix (most versatile)
- Forge hammers counted for both prefix AND suffix (upgrade hammers)
- Display shows raw currency counts from GameState (full transparency)

**Why temporary mapping:**
Phase 8 will replace the 3-button crafting UI with a 6-button UI that directly uses each currency type. This temporary mapping keeps the old buttons working while the full currency system is in place.

## Next Steps

Phase 8 (UI Migration) will:
- Replace 3 crafting buttons with 6 currency-specific buttons
- Remove the temporary currency-to-hammer mapping
- Add proper currency consumption using Currency.apply() pattern
- Complete the v1.0 Crafting Overhaul milestone

## Self-Check

**Created files verification:**
None (only modified existing files)

**Modified files verification:**
```bash
[ -f "models/loot/loot_table.gd" ] && echo "FOUND: models/loot/loot_table.gd" || echo "MISSING"
[ -f "autoloads/game_state.gd" ] && echo "FOUND: autoloads/game_state.gd" || echo "MISSING"
[ -f "scenes/gameplay_view.gd" ] && echo "FOUND: scenes/gameplay_view.gd" || echo "MISSING"
[ -f "scenes/crafting_view.gd" ] && echo "FOUND: scenes/crafting_view.gd" || echo "MISSING"
[ -f "scenes/main_view.gd" ] && echo "FOUND: scenes/main_view.gd" || echo "MISSING"
```

**Commits verification:**
```bash
git log --oneline --all | grep -q "324aef5" && echo "FOUND: 324aef5" || echo "MISSING"
git log --oneline --all | grep -q "8af22eb" && echo "FOUND: 8af22eb" || echo "MISSING"
```

## Self-Check: PASSED

All claimed files exist and all commits are present in git history.
