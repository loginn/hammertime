---
phase: 19-side-by-side-layout
plan: 03
subsystem: ui
tags: [forge-view, layout, icons, rarity-colors, gap-closure]

dependency_graph:
  requires: [LAYOUT-01]
  provides: [UAT-01-fix, UAT-04-fix, UAT-05-fix, UAT-10-partial-fix]
  affects: [scenes/forge_view.tscn, scenes/forge_view.gd]

tech_stack:
  added:
    - Hammer icon textures (6 PNG assets)
    - Rarity color modulation in item stats display
  patterns:
    - ExtResource icon assignment for UI buttons
    - Theme override for font size consistency
    - Zero-gap button positioning for hover stability

key_files:
  created: []
  modified:
    - path: scenes/forge_view.tscn
      changes: "Added 6 hammer icon ext_resources, icon properties on all hammer buttons, font_size=11 theme overrides on all labels/buttons, closed item type button gaps to 0px, fixed Background height to 670px, adjusted HammerSidebar and InventoryLabel offsets"
    - path: scenes/forge_view.gd
      changes: "Added hammer_icons dictionary with preloaded textures, updated update_currency_button_states() to set button.icon, restored rarity color in update_item_stats_display() using get_rarity_color()"

decisions:
  - decision: "Use theme_override_font_sizes/font_size = 11 for all UI text"
    rationale: "Prevents text overflow in 1280x670 viewport while maintaining readability"
    alternatives: ["Resize panels", "Use auto-wrapping"]
    outcome: "✓ Good - clean layout with no overflow"

  - decision: "Set item type buttons to exactly 86px width with contiguous positions"
    rationale: "Eliminates gaps that cause hover flicker"
    alternatives: ["Use HBoxContainer with no spacing", "Add mouse_filter to parent"]
    outcome: "✓ Good - stable button hover states"

  - decision: "Restore rarity color via modulate property"
    rationale: "Maintains visual feedback from old crafting_view, signals item quality at a glance"
    alternatives: ["Color-code background", "Add rarity text prefix"]
    outcome: "✓ Good - matches existing Item.get_rarity_color() design"

metrics:
  duration_minutes: 3
  completed_date: 2026-02-17
  tasks_completed: 2
  commits: 2
  files_modified: 2
  lines_added: 65
  lines_removed: 10
---

# Phase 19 Plan 03: ForgeView Visual Fixes Summary

**One-liner:** Hammer button icons with left-aligned text, font-size 11px UI, zero-gap item type buttons preventing hover flicker, and rarity color modulation for magic/rare items.

## What Was Built

Fixed 4 UAT visual issues in ForgeView:

1. **Hammer Icons (UAT-01)** - All 6 hammer buttons now display their corresponding icon from assets/ folder alongside text, using ExtResource references and icon_alignment = 0 (left-align).

2. **Text Overflow (UAT-04)** - Reduced all font sizes to 11px via theme_override_font_sizes/font_size, adjusted InventoryLabel height (310-550 instead of 320-650), and set Background height to 670px to match content area.

3. **Item Type Button Gaps (UAT-05)** - Closed all gaps between the 5 item type buttons by setting contiguous positions (0-86, 86-172, 172-258, 258-344, 344-430), each button exactly 86px wide.

4. **Rarity Colors (UAT-10 partial)** - Restored magic/rare item color display by setting item_stats_label.modulate to item.get_rarity_color() (blue for Magic, yellow for Rare, white for Normal).

## Technical Implementation

### Task 1: ForgeView Scene Layout

**File:** `scenes/forge_view.tscn`

**Changes:**
- Added 6 ext_resource entries for hammer PNG assets (runic, forge, tack, grand, claw, tuning)
- Added `icon`, `icon_alignment = 0`, and `expand_icon = true` properties to all 6 hammer buttons
- Added `theme_override_font_sizes/font_size = 11` to:
  - All 6 hammer buttons
  - FinishItemButton
  - InventoryLabel
  - ItemStatsLabel
  - HeroStatsLabel
  - MeltButton, EquipButton
  - All 5 item type buttons
- Fixed HammerSidebar offset_top from 0 to 10 (small padding)
- Shrunk InventoryLabel (offset_top 320→310, offset_bottom 650→550)
- Closed item type button gaps:
  - WeaponButton: 0-86px
  - HelmetButton: 86-172px
  - ArmorButton: 172-258px
  - BootsButton: 258-344px
  - RingButton: 344-430px
- Fixed Background offset_bottom from 660 to 670

**Commit:** `32f3090`

### Task 2: Rarity Colors and Icon Setup

**File:** `scenes/forge_view.gd`

**Changes:**
- Added `hammer_icons` dictionary at line 55 with preload() calls for all 6 hammer textures
- Updated `update_currency_button_states()` to set `button.icon = hammer_icons.get(currency_type)` (line 227)
- Restored rarity color in `update_item_stats_display()`:
  - `finished_item` branch: `item_stats_label.modulate = finished_item.get_rarity_color()` (line 468)
  - `current_item` branch: `item_stats_label.modulate = current_item.get_rarity_color()` (line 471)
  - Empty branch: `item_stats_label.modulate = Color.WHITE` (line 474)

**Commit:** `9547fcd`

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

1. **Ext_resources:** 6 hammer icon ext_resources present in forge_view.tscn (lines 5-10)
2. **Icon properties:** All 6 hammer buttons have `icon = ExtResource("N_name")` assignments
3. **Font sizes:** 17 instances of `theme_override_font_sizes/font_size = 11` across all labels and buttons
4. **Button positions:** Item type buttons have contiguous positions with zero gaps (verified via grep)
5. **Background height:** offset_bottom = 670 (line 17)
6. **Rarity color calls:** 2 instances of `get_rarity_color()` in forge_view.gd (lines 468, 471)
7. **Hammer icons dictionary:** Defined at line 55 with 6 preload entries
8. **Icon assignment:** button.icon set at line 227 in update_currency_button_states()

## UAT Coverage

This plan addresses 4 UAT issues:

| UAT Test | Issue | Status |
|----------|-------|--------|
| UAT-01 | Hammer buttons missing icons | ✓ Fixed |
| UAT-04 | Text overflow in ForgeView | ✓ Fixed |
| UAT-05 | Item type button hover flicker | ✓ Fixed |
| UAT-10 | Rarity colors missing | ⚠ Partial (ForgeView only) |

**Note:** UAT-10 is marked partial because GameplayView may also need rarity color restoration. This plan focused on ForgeView per the gap closure scope.

## Files Changed

- `scenes/forge_view.tscn` - Scene layout with icons, font sizes, button positions, background height
- `scenes/forge_view.gd` - Hammer icon dictionary, icon assignment in button updates, rarity color modulation

## Self-Check

### Created Files
None (gap closure plan - only modified existing files).

### Modified Files
```bash
FOUND: /var/home/travelboi/Programming/hammertime/scenes/forge_view.tscn
FOUND: /var/home/travelboi/Programming/hammertime/scenes/forge_view.gd
```

### Commits
```bash
FOUND: 32f3090 (feat(19-03): add hammer icons, reduce font sizes, close button gaps, fix layout)
FOUND: 9547fcd (feat(19-03): add rarity colors and hammer icons to ForgeView script)
```

## Self-Check: PASSED

All claimed files exist, all commits verified, all verification criteria met.
