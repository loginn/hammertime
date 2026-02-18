---
created: 2026-02-18T13:46:30.643Z
title: Add item drop filter for unwanted loot
area: general
files:
  - models/loot/loot_table.gd
  - scenes/gameplay_view.gd
  - scenes/forge_view.gd
  - autoloads/game_state.gd
---

## Problem

Players accumulate item drops they don't want. As progression continues, most drops are irrelevant (wrong base type, low rarity, etc.). There's no way to automatically ignore unwanted items, forcing players to manually deal with every drop. This slows down the idle loop and makes farming feel tedious instead of rewarding.

## Solution

Add a loot filter system that lets players define which items to keep and which to auto-discard:
- Filter by item type (e.g., only keep weapons and rings)
- Filter by rarity (e.g., ignore Normal items)
- Possibly filter by base type or tier threshold
- UI toggle in settings or a dedicated filter panel
- Filtered items are silently discarded on drop (never enter inventory)
- Filter should be saveable as part of game state
