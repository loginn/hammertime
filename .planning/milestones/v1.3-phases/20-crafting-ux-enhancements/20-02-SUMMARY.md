---
phase: 20-crafting-ux-enhancements
plan: 02
subsystem: ui-forge-view
tags: [ui, crafting, stat-comparison, bbcode, richtextlabel]
dependency-graph:
  requires: [phase-20-01-tooltips-equip-confirmation]
  provides: [equip-hover-stat-comparison, colored-stat-deltas, resistance-comparison]
  affects: [crafting-workflow, equip-decision-ux]
tech-stack:
  added: []
  patterns: [RichTextLabel-BBCode-coloring, format_stat_delta-helpers, suffix-stat-summing]
key-files:
  created: []
  modified:
    - scenes/forge_view.gd
    - scenes/forge_view.tscn
decisions:
  - decision: "Use RichTextLabel with bbcode_enabled for colored stat deltas"
    rationale: "BBCode [color] tags allow inline green/red coloring without multiple Label nodes"
  - decision: "Default weapon/ring crit values of 5.0/150.0 for empty slot comparison"
    rationale: "Matches hero base stats so empty slot comparison shows meaningful deltas"
  - decision: "Resistance comparison sums suffix stat_types rather than using hero totals"
    rationale: "Shows item-level contribution difference per CONTEXT.md decision, not total hero stat change"
requirements-completed:
  - CRAFT-02
metrics:
  duration: 90
  completed: 2026-02-17
---

# Phase 20 Plan 02: Stat Comparison Display on Equip Hover Summary

**One-liner:** Added equip button hover stat comparison with green/red BBCode-colored deltas for all item types, showing crafted vs equipped item-level differences including DPS, defense, and elemental resistances.

## What Changed

### HeroStatsLabel Conversion (Task 1)
- Converted `HeroStatsLabel` from `Label` to `RichTextLabel` in `forge_view.tscn`
- Enabled `bbcode_enabled = true` and `scroll_active = false`
- Changed `@onready` type from `Label` to `RichTextLabel` in `forge_view.gd`
- Added `equip_hover_active` state variable
- Connected `mouse_entered`/`mouse_exited` signals on equip button in `_ready()`

### Stat Comparison Logic (Task 2)
- Added `format_stat_delta()` for float stat formatting with green/red BBCode color tags
- Added `format_stat_delta_int()` for integer stat formatting with green/red BBCode color tags
- Added `get_stat_comparison_text()` with per-type stat comparison:
  - Weapon: DPS, Base Damage, Crit Chance, Crit Damage
  - Ring: DPS, Crit Chance, Crit Damage
  - Armor: Armor, Evasion, Energy Shield, Health
  - Helmet: Armor, Evasion, Energy Shield, Health, Mana
  - Boots: Armor, Evasion, Energy Shield, Movement Speed, Health
- Added `_get_resistance_comparison_text()` for elemental resistance deltas across all item types
- Added `_sum_suffix_stat()` helper to extract resistance values from item suffixes
- Updated `update_hero_stats_display()` to check `equip_hover_active` first, before item type hover and default hero stats

## Deviations from Plan

None - plan executed exactly as written.

## Commits

| Hash | Message |
|------|---------|
| ac2e950 | feat(20-02): add stat comparison display on equip hover with colored deltas |

## Files Changed

**Modified (2):**
- scenes/forge_view.gd
- scenes/forge_view.tscn

## Self-Check

### Modified Files
- scenes/forge_view.gd: FOUND
- scenes/forge_view.tscn: FOUND

### Commits
- ac2e950: FOUND

### Verification
- get_stat_comparison_text in forge_view.gd: 2 matches (PASS)
- format_stat_delta in forge_view.gd: 28 matches (PASS)
- equip_hover_active in forge_view.gd: 4 matches (PASS)
- [color=#55ff55] in forge_view.gd: 2 matches (PASS)
- [color=#ff5555] in forge_view.gd: 2 matches (PASS)
- _sum_suffix_stat in forge_view.gd: 9 matches (PASS)
- RichTextLabel in forge_view.tscn: 1 match (PASS)
- bbcode_enabled in forge_view.tscn: 1 match (PASS)

## Self-Check: PASSED
