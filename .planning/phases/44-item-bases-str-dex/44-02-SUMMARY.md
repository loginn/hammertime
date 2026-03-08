# Plan 02 Summary: Serialization, Drop Generation, Game State & Save Version

**Phase:** 44 — Item Bases (STR & DEX)
**Plan:** 02
**Status:** Complete
**Date:** 2026-03-06

## Tasks Completed

1. **44-02-01: Update item.gd serialization registry** — Removed 5 legacy item types (LightSword, BasicArmor, BasicHelmet, BasicBoots, BasicRing) from ITEM_TYPE_STRINGS and create_from_dict. The 18 new item bases added in plan 01 are now the sole serialization targets. Tier pre-extraction was already implemented in plan 01.

2. **44-02-02: Rewrite drop generation with slot-first-then-archetype logic** — Replaced flat 5-item array with slot-first selection (20% per slot), then random archetype within slot. Weapons have 6 bases (3 STR + 3 DEX), non-weapon slots have 3 bases each. Tier is rolled before construction and passed to the constructor.

3. **44-02-03: Update starter weapon and save version** — Changed starter weapon from LightSword.new() to Broadsword.new(8) in both initialize_fresh_game() and _wipe_run_state(). Bumped SAVE_VERSION from 5 to 6 (breaking change, old saves auto-wiped).

## Deviations

- **Rule 2 (Missing Critical):** Updated integration_test.gd to replace all LightSword references with Broadsword. Without this, 5 tests would have failed (starter weapon checks, tier/affix floor tests, tag hammer gating test).

## Commits

| Commit | Description |
|--------|-------------|
| 94627ab | feat(44-02): remove legacy item types from serialization registry |
| f8e5f67 | feat(44-02): rewrite drop generation with slot-first-then-archetype logic |
| 45560d2 | feat(44-02): update starter weapon to Broadsword T8 and bump save to v6 |

## Files Modified

- `models/items/item.gd` — Removed legacy types from ITEM_TYPE_STRINGS and create_from_dict
- `scenes/gameplay_view.gd` — Rewrote get_random_item_base() with slot-first logic
- `autoloads/game_state.gd` — Starter weapon changed to Broadsword.new(8)
- `autoloads/save_manager.gd` — SAVE_VERSION bumped to 6
- `tools/test/integration_test.gd` — Updated LightSword references to Broadsword

## Verification Notes

- All 18 item types have serialization match arms with tier pre-extraction
- Drop generation covers all 5 slots with equal weight, multiple archetypes per slot
- Starter weapon is Broadsword T8 in both fresh game and prestige reset paths
- Save version 6 ensures old saves are cleanly wiped on load
