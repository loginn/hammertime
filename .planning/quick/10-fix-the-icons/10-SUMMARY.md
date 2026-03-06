# Quick Task 10: Fix the icons in the crafting view — Summary

**Completed:** 2026-03-06

## Problem

Hammer buttons in the forge sidebar used text-based buttons with tiny/invisible icons. The wireframe design (Wireframe/Hero view.png) calls for icon-only square tiles with count overlays.

## Changes

- **`scenes/forge_view.tscn`:** Replaced 110x65 text buttons with 90x90 icon-only square buttons in a 2-column grid. Each button has a child `CountLabel` (bottom-right, black text with white outline, font size 13). Tag hammer section repositioned below main grid and switched from VBoxContainer to Control with manual layout.
- **`scenes/forge_view.gd`:** `update_currency_button_states()` now updates the `CountLabel` child instead of button text. Tooltips show full hammer name, count, and description on hover. Added `hammer_descriptions` dictionary for tooltip content. Removed static tooltip assignments from `_ready()`.

## Result

Hammer sidebar now matches the wireframe: large icon tiles, count overlay on bottom-right, name + description on hover.
