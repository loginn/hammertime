---
created: "2026-03-31T12:31:35.811Z"
title: Reduce item class duplication
area: models
files:
  - models/items/armor.gd:14-51
  - models/items/helmet.gd:16-59
  - models/items/boots.gd:16-59
  - models/items/item.gd:203-235
  - models/items/ring.gd:24-48
  - scenes/forge_view.gd:776-909
  - scenes/forge_view.gd:996-1133
---

## Problem

Significant code duplication across item classes identified in codebase quality audit:

1. **`update_value()`** is near-identical in Armor, Helmet, and Boots — all three compute flat_armor, flat_evasion, flat_energy_shield, flat_health using StatCalculator, then apply percentage modifiers. Only difference: Helmet adds computed_mana, Boots adds computed_movement_speed.

2. **`get_display_text()`** is duplicated across 5 classes (Item base, Armor, Helmet, Boots, Ring) with near-identical structure.

3. **Per-type branches in forge_view.gd** — `get_stat_comparison_text()` (lines 776-909) and `get_item_stats_text()` (lines 996-1133) have separate branches for each item type. Armor/Helmet/Boots branches are nearly identical. ~300 lines of branching that grows linearly with item types.

## Solution

- Extract shared defense stat computation from `update_value()` into a base class method. Subclasses override only for their unique stat (mana, movement speed).
- Consolidate `get_display_text()` into a single polymorphic method in `Item` base class that queries subclass-specific stats.
- Add `get_comparable_stats() -> Dictionary` and `get_stats_text() -> String` polymorphic methods to each item type, then format generically in forge_view.gd.
