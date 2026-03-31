---
created: "2026-03-31T12:31:35.811Z"
title: Replace string slot keys with SlotType enum
area: models
files:
  - autoloads/game_state.gd:230-236
  - scenes/forge_view.gd:608-621
  - models/hero.gd
  - autoloads/save_manager.gd
  - scenes/gameplay_view.gd
---

## Problem

Equipment slots are identified by string keys (`"weapon"`, `"helmet"`, `"armor"`, `"boots"`, `"ring"`) used in 10+ locations across GameState, Hero, SaveManager, ForgeView, and GameplayView. A typo in any slot string causes silent failures with no compile-time protection. Tests use the same strings so typos would propagate undetected.

Additionally, `_get_slot_for_item()` in game_state.gd and `get_item_type()` in forge_view.gd duplicate the same slot-type mapping logic.

## Solution

Create a `SlotType` enum (e.g., in Item or its own file) and replace all string-based slot references. Consolidate the duplicate slot-mapping functions into a single method. This gives compile-time safety and a single source of truth for valid slots.
