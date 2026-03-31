---
created: "2026-03-31T12:31:35.811Z"
title: Consolidate item type registration
area: models
files:
  - models/items/item.gd:91-133
  - models/items/item.gd:74-82
  - scenes/gameplay_view.gd:412-419
  - scenes/forge_view.gd:357-378
  - autoloads/game_state.gd:230-236
---

## Problem

Adding a new item type requires updating 5+ locations across the codebase:

1. `Item.create_from_dict()` match block (item.gd:91-133)
2. `Item.ITEM_TYPE_STRINGS` dictionary (item.gd:74-82)
3. `gameplay_view.gd` bases dictionary for the drop pool (line 412-419)
4. `forge_view.gd` `_get_item_abbreviation()` for stash display (line 357-378)
5. `game_state.gd` `_get_slot_for_item()` for slot routing (line 230-236)

Missing any registration point causes silent failures — items not dropping, not deserializing, or showing "??" in stash.

## Solution

Consider a registry pattern where item classes self-register, or at minimum consolidate the scattered registrations into a single dictionary/config that all consumers reference. Each item subclass could expose its own metadata (type string, abbreviation, slot, drop pool inclusion) so adding a new type is a single-file change.
