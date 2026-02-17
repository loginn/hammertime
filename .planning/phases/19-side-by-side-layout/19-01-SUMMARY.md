---
phase: 19-side-by-side-layout
plan: 01
subsystem: ui-forge-view
tags: [ui, layout, crafting, hero, forge-view]
dependency-graph:
  requires: [phase-18-save-load, game-state, game-events, currency-models, item-models]
  provides: [forge-view-scene, forge-view-script, viewport-1280x720, melt-equip-actions]
  affects: [crafting-workflow, hero-stats-display, item-equipping]
tech-stack:
  added: []
  patterns: [merged-view-pattern, melt-equip-workflow, type-hover-comparison]
key-files:
  created:
    - scenes/forge_view.tscn
    - scenes/forge_view.gd
  modified:
    - project.godot
decisions:
  - decision: "Use Button nodes with toggle_mode for hammer sidebar instead of TextureRect+Button combos"
    rationale: "Matches existing crafting_view pattern, simpler implementation, text shows name+count directly"
  - decision: "Finished items require explicit Melt or Equip action before new craft can begin"
    rationale: "Per CONTEXT.md: player must choose Melt or Equip, no auto-equip flow"
requirements-completed:
  - LAYOUT-01
metrics:
  duration: 178
  completed: 2026-02-17
---

# Phase 19 Plan 01: ForgeView Scene and Script Summary

**One-liner:** Created unified ForgeView scene with side-by-side hero/crafting layout and merged logic script with Melt/Equip workflow, plus viewport update to 1280x720.

## What Changed

### Viewport (project.godot)
- Updated from 1200x700 to 1280x720 (standard 16:9 ratio)

### ForgeView Scene (scenes/forge_view.tscn)
Created new scene with dark theme (#1a1a1a background, #333 panels):
- **HammerSidebar** (40,0 — 260x660): 6 toggle buttons in 2-column grid, FinishItemButton, InventoryLabel
- **ItemGraphicsPanel** (340,0 — 430x160): sword2.png placeholder
- **ItemTypeButtons** (340,165 — 430x40): 5 equal-width buttons (weapon/helmet/armor/boots/ring)
- **HeroGraphicsPanel** (810,0 — 430x200): hero.png placeholder
- **ItemStatsPanel** (340,230 — 430x430): ItemStatsLabel + MeltButton + EquipButton
- **HeroStatsPanel** (810,230 — 430x430): HeroStatsLabel

### ForgeView Script (scenes/forge_view.gd)
Merged crafting_view.gd (384 lines) and hero_view.gd (428 lines) into forge_view.gd (653 lines):

**From crafting_view.gd:**
- Currency selection, application, button state management
- Item type selection with crafting bench switching
- Inventory management and display
- Finish item workflow

**From hero_view.gd:**
- Hero stats display (offense + defense)
- Item stats text formatting for all 5 item types
- Equipment slot interaction (replaced with Melt/Equip buttons)

**New functionality:**
- `_on_melt_pressed()`: destroys finished item, frees crafting slot
- `_on_equip_pressed()`: equips to hero slot (old item destroyed, no swap-back)
- `update_melt_equip_states()`: enables/disables Melt/Equip based on finished_item
- `_on_type_hover_entered/exited()`: hovering item type button shows equipped item for comparison
- `equipment_changed` signal for MainView to wire to GameplayView

**Exposed interface for MainView:**
- Signal: `equipment_changed()` — for gameplay_view.refresh_clearing_speed
- Method: `set_new_item_base(item_base: Item)` — for gameplay_view.item_base_found
- Method: `on_currencies_found(drops: Dictionary)` — for gameplay_view.currencies_found

## Deviations from Plan

None - plan executed exactly as written.

## Commits

| Hash | Message |
|------|---------|
| ce6a593 | feat(19-01): update viewport to 1280x720 and create ForgeView scene |
| fc0437d | feat(19-01): create ForgeView script merging crafting and hero logic |

## Files Changed

**Created (2):**
- scenes/forge_view.tscn
- scenes/forge_view.gd

**Modified (1):**
- project.godot

## Self-Check

### Created Files
- scenes/forge_view.tscn: FOUND
- scenes/forge_view.gd: FOUND

### Commits
- ce6a593: FOUND
- fc0437d: FOUND

## Self-Check: PASSED
