---
status: resolved
trigger: "Stash UI in ForgeView does not clearly separate its 15 slots into 5 groups of 3"
created: 2026-03-31T00:00:00Z
updated: 2026-03-31T00:00:00Z
---

## Current Focus

hypothesis: StashDisplay uses manually-positioned VBoxContainer groups with only 10px gaps and no visual separators, making groups blend together
test: measured pixel offsets between groups in .tscn
expecting: small gaps with no separators or background differentiation
next_action: return diagnosis

## Symptoms

expected: 15 stash slots visually organized into 5 clearly distinct groups (Weapon, Helmet, Armor, Boots, Ring), each with 3 slots and a label
actual: Slots appear as a mostly continuous row with tiny gaps; groups are not clearly separated
errors: (none - visual/UX issue)
reproduction: Open ForgeView, look at StashDisplay area
started: Since Phase 57 initial implementation

## Eliminated

(none needed - root cause confirmed on first analysis)

## Evidence

- timestamp: 2026-03-31
  checked: forge_view.tscn StashDisplay node tree (lines 270-456)
  found: StashDisplay is a plain Control (not HBoxContainer). Five VBoxContainer groups are manually positioned with offsets. Each group is ~86px wide. Gaps between groups are only 10px (WeaponGroup ends at x=86, HelmetGroup starts at x=96; gap=10px. Same pattern for all groups).
  implication: 10px gap between groups is too small to create clear visual separation, especially with 28x28 buttons that nearly fill each group's width.

- timestamp: 2026-03-31
  checked: forge_view.tscn StashDisplay for separators, backgrounds, or margins
  found: No visual separators (no HSeparator, VSeparator, or ColorRect dividers between groups). No background color differentiation per group. The parent StashDisplay has no theme or style. Labels exist (font_size=9) but are very small.
  implication: The only visual cue separating groups is a tiny 10px gap and a small label. No borders, no background colors, no separator lines.

- timestamp: 2026-03-31
  checked: forge_view.gd _update_stash_display() (lines 384-399)
  found: Pure data update logic - sets button text, tooltip, modulate, disabled state. No layout or spacing logic. Empty slots get modulate Color(0.4, 0.4, 0.4, 1.0) which dims them but does not help group separation.
  implication: The GD script has no bearing on the layout problem. This is purely a .tscn scene structure issue.

## Resolution

root_cause: The StashDisplay in forge_view.tscn has three compounding layout problems that prevent clear group separation: (1) Groups are manually positioned with only 10px gaps between them (e.g., WeaponGroup ends at x=86, HelmetGroup starts at x=96), which is too narrow to read as a visual boundary. (2) There are zero visual separators between groups -- no VSeparator nodes, no ColorRect dividers, no per-group background colors. (3) The group labels use font_size=9, which is very small and hard to read as group headers. The only cue that groups exist is a barely-perceptible 10px gap and a tiny label.
fix: (diagnosis only - not applied)
verification: (diagnosis only)
files_changed: []
