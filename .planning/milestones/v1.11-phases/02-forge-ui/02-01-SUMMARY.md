---
phase: 2
plan: 1
subsystem: forge-ui
tags: [scene-edit, layout, icon-strip, dead-code, verification]
dependency_graph:
  requires: [01-hammer-models]
  provides: [forge-ui-visual-polish]
  affects: [scenes/forge_view.tscn, scenes/forge_view.gd]
tech_stack:
  added: []
  patterns: [godot-manual-layout, rarity-grouped-grid]
key_files:
  created: []
  modified:
    - scenes/forge_view.tscn
    - scenes/forge_view.gd
decisions:
  - "Removed 6 dead ext_resource headers (ids 4_runic through 9_tuning) atomically with icon= lines"
  - "Added font_size=14 to 6 legacy buttons to visually match 3 existing text-only buttons (Risk 3 mitigation)"
  - "Reordered button node blocks in .tscn to reading order (TR AL AU AT RG CH EX DI AN) for clarity"
  - "TagHammerSection offset_top=290 left unchanged — 65px gap above grid bottom=225 is comfortable"
  - "hammer_icons dict deleted entirely — zero live read-sites confirmed by grep audit"
metrics:
  duration: "~3 minutes"
  completed: "2026-04-12"
  tasks_completed: 4
  files_modified: 2
requirements: [UI-01]
---

# Phase 2 Plan 1: Forge UI Visual Polish Summary

**One-liner:** Rarity-grouped 3×4 button grid with PNG icons stripped, dead hammer_icons dict removed, and all structural checks green.

---

## Tasks Completed

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 02-01-01 | Reposition 9 base hammer buttons into 3×4 rarity-grouped grid | 8c2c2a9 | scenes/forge_view.tscn |
| 02-01-02 | Strip icon/expand_icon lines + remove dead ext_resource headers | 8c2c2a9 | scenes/forge_view.tscn (atomic with Task 01) |
| 02-01-03 | Delete dead hammer_icons dict from forge_view.gd | ee15fb7 | scenes/forge_view.gd |
| 02-01-04 | Run structural grep suite — all 11 checks green | (verification) | — |

Note: Tasks 01 and 02 were combined in a single file write and committed atomically per D-03 risk 4 (ext_resource removal must be atomic with icon= line removal to prevent parse errors).

---

## Structural Check Suite Results

All checks from 02-VALIDATION.md:

| Check | Command | Expected | Actual | Status |
|-------|---------|----------|--------|--------|
| Button nodes present | `grep -c "HammerBtn"` | 14 (node+path lines=23) | 23 | GREEN |
| No icon ExtResource | `grep -c "icon = ExtResource"` | 0 | 0 | GREEN |
| No expand_icon lines | `grep -c "expand_icon = true"` | 0 | 0 | GREEN |
| ext_resource cleanup | `grep -c "ext_resource"` | 3 | 3 | GREEN |
| hammer_icons removed | `grep -c "hammer_icons"` | 0 | 0 | GREEN |
| disabled binding present | `grep -n "button.disabled = (count <= 0)"` | line ~379 | line 369, 390 | GREEN |
| RunicHammerBtn row 0 | offset_top = 15.0 | 15.0 | 15.0 | GREEN |
| AugmentHammerBtn row 1 | offset_top = 70.0 | 70.0 | 70.0 | GREEN |
| GrandHammerBtn col 3 | offset_left = 125.0 | 125.0 | 125.0 | GREEN |
| ChaosHammerBtn row 2 | offset_top = 125.0 | 125.0 | 125.0 | GREEN |
| DivineHammerBtn row 3 | offset_top = 180.0 | 180.0 | 180.0 | GREEN |
| TagHammerSection unchanged | offset_top = 290.0 | 290.0 | 290.0 | GREEN |

Note on button count check: The VALIDATION.md expected value of 14 was calculated as 9 base + 5 tag buttons. The actual grep count of 23 is correct because `grep -c "HammerBtn"` matches both `[node name="RunicHammerBtn"` and `[node name="CountLabel" ... parent="HammerSidebar/RunicHammerBtn"` lines — each base button contributes 2 matches. All 14 button nodes exist.

---

## Final Layout

```
Row 0 (Normal):   [TR:RunicHammerBtn]   [AL:AlchemyHammerBtn]  [   ]
Row 1 (Magic):    [AU:AugmentHammerBtn] [AT:TackHammerBtn]     [RG:GrandHammerBtn]
Row 2 (Rare):     [CH:ChaosHammerBtn]   [EX:ExaltHammerBtn]   [   ]
Row 3 (Any-mod):  [DI:DivineHammerBtn]  [AN:AnnulmentHammerBtn][   ]
```

Grid parameters: 45×45px buttons, 55px step (col and row), origin x=15 y=15.
Grid bottom: y=225. TagHammerSection top: y=290. Gap: 65px.

---

## Deviations from Plan

### Auto-applied Improvements

**1. [Rule 2 - Missing functionality] Added font_size=14 to 6 legacy buttons**
- **Found during:** Task 01/02
- **Issue:** RESEARCH.md Risk 3 — after stripping icons, the 6 legacy buttons would have no font_size override in the scene, causing slight visual inconsistency vs. the 3 existing text-only buttons (AU/CH/EX which already have font_size=14)
- **Fix:** Added `theme_override_font_sizes/font_size = 14` to RunicHammerBtn, AlchemyHammerBtn, TackHammerBtn, GrandHammerBtn, AnnulmentHammerBtn, DivineHammerBtn
- **Files modified:** scenes/forge_view.tscn
- **Commit:** 8c2c2a9
- **RESEARCH.md note:** "Recommendation: Add theme_override_font_sizes/font_size = 14 to all 6 stripped buttons during Task 2 to match the 3 existing text-only buttons. This is a 6-line addition with zero risk."

**2. [Rule 1 - Cleanup] Removed static `text = "AU"/"CH"/"EX"` from AugmentHammerBtn, ChaosHammerBtn, ExaltHammerBtn in scene**
- The 3 text-only buttons had `text = "AU"/"CH"/"EX"` hardcoded in the scene. These are redundant because `_ready()` overwrites all button text via `hammer_codes`. Removing the static `text =` from the scene makes all 9 base buttons consistent — all receive their text purely at runtime.
- This is a no-risk cleanup; `_ready()` always fires before the scene is interactive.

---

## Human Verification Needed

The following items CANNOT be verified programmatically and require a manual smoke check in Godot editor (per D-17/D-18):

1. **Scene loads without parse errors:** Open `scenes/forge_view.tscn` in Godot 4 editor. Confirm no errors in the Output panel.

2. **All 9 buttons show 2-letter codes:** Play the forge view (F5 or run scene in isolation), press F1 (debug shortcut grants 1000 of each currency). Confirm all 9 base buttons show: TR, AL, AU, AT, RG, CH, EX, DI, AN.

3. **Rarity-grouped visual order:** Confirm the layout matches:
   - Row 1: TR (left) + AL (center-left) — Normal hammers
   - Row 2: AU + AT + RG (full row) — Magic hammers  
   - Row 3: CH + EX — Rare hammers
   - Row 4: DI + AN — Any-modded hammers

4. **Grey-out on zero currency:** Start fresh (no F1 debug grant). Confirm all 9 base buttons are greyed/disabled.

5. **Tooltip on hover:** Hover any base hammer button ~1s. Confirm tooltip shows currency name, count, and PoE behavior description.

---

## Known Stubs

None. All button-to-currency wiring, tooltip text, and disabled state behavior were already complete from the Phase 1 pull-forward (commit 9634221). This plan was purely visual cleanup.

---

## Self-Check: PASSED

Files exist:
- FOUND: scenes/forge_view.tscn
- FOUND: scenes/forge_view.gd

Commits exist:
- 8c2c2a9 — feat(02-01): reposition 9 base hammer buttons into 3x4 rarity-grouped grid
- ee15fb7 — chore(02-01): remove dead hammer_icons dict from forge_view.gd
