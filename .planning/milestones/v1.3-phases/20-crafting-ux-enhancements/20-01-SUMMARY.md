---
phase: 20-crafting-ux-enhancements
plan: 01
subsystem: ui-forge-view
tags: [ui, crafting, tooltips, equip-confirmation, ux]
dependency-graph:
  requires: [phase-19-forge-view, currency-models]
  provides: [hammer-tooltips, direct-equip-flow, equip-confirmation, finish-item-removed]
  affects: [crafting-workflow, equip-safety]
tech-stack:
  added: []
  patterns: [tooltip_text-property, timer-confirmation-reset, direct-current-item-equip]
key-files:
  created: []
  modified:
    - scenes/forge_view.gd
    - scenes/forge_view.tscn
decisions:
  - decision: "Use Godot built-in tooltip_text property for hammer tooltips"
    rationale: "Simplest approach — hover/show/hide behavior is automatic, positions near cursor"
  - decision: "Equip and Melt operate directly on current_item, removing intermediate finished_item state"
    rationale: "Streamlines workflow — no more Finish Item step before equipping"
  - decision: "Equip confirmation uses Timer with 3-second timeout for auto-reset"
    rationale: "Standard Godot pattern, no per-frame overhead, cleaner than _process delta tracking"
requirements-completed:
  - CRAFT-01
  - CRAFT-03
  - CRAFT-04
metrics:
  duration: 120
  completed: 2026-02-17
---

# Phase 20 Plan 01: Hammer Tooltips, Finish Item Removal, Equip Confirmation Summary

**One-liner:** Added hammer tooltips with descriptions/requirements, removed Finish Item workflow for direct equip/melt, and implemented two-click equip confirmation with 3-second timeout.

## What Changed

### Hammer Tooltips (CRAFT-01)
- Set `tooltip_text` on all 6 hammer buttons in `_ready()` with natural-language descriptions
- Format: hammer name, effect description sentence, rarity requirement
- Uses Godot's built-in tooltip system (shows on hover, hides on mouse leave)

### Finish Item Removal (part of CRAFT-04)
- Removed `FinishItemButton` node from `forge_view.tscn`
- Removed `finish_item_btn` @onready reference, `finish_item()` function, `_on_finish_item_button_pressed()` handler
- Removed `finished_item` variable entirely
- Shifted InventoryLabel up to fill the gap (offset_top 310 -> 260)

### Direct Equip/Melt on current_item (part of CRAFT-04)
- `_on_equip_pressed()` now works on `current_item` directly instead of `finished_item`
- `_on_melt_pressed()` now works on `current_item` directly, clears crafting inventory slot
- `update_melt_equip_states()` checks `current_item != null` instead of `finished_item`
- `update_item_stats_display()` simplified to only check `current_item`

### Two-Click Equip Confirmation (CRAFT-04)
- Added `equip_confirm_pending` bool and `equip_timer` Timer (3-second one_shot)
- First click on Equip when slot is occupied: sets button text to "Confirm Overwrite?", starts timer
- Second click: completes the equip, resets state
- Timer timeout: resets button text to "Equip"
- Switching item types, selecting currency, or melting all reset confirmation state

### Per-Type Slots (CRAFT-03)
- Already implemented in Phase 19 via `GameState.crafting_inventory` dictionary
- Verified: switching types preserves items, items come from drops only

## Deviations from Plan

None - plan executed exactly as written.

## Commits

| Hash | Message |
|------|---------|
| ab65c6a | feat(20-01): add hammer tooltips, remove finish item, add equip confirmation |

## Files Changed

**Modified (2):**
- scenes/forge_view.gd
- scenes/forge_view.tscn

## Self-Check

### Modified Files
- scenes/forge_view.gd: FOUND
- scenes/forge_view.tscn: FOUND

### Commits
- ab65c6a: FOUND

### Verification
- FinishItemButton in forge_view.gd: 0 matches (PASS)
- finished_item in forge_view.gd: 0 matches (PASS)
- tooltip_text in forge_view.gd: 6 matches (PASS)
- FinishItemButton in forge_view.tscn: 0 matches (PASS)
- equip_confirm_pending in forge_view.gd: 9 matches (PASS)
- Confirm Overwrite in forge_view.gd: 1 match (PASS)

## Self-Check: PASSED
