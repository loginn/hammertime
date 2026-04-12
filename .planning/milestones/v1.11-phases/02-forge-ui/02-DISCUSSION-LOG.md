# Phase 2: Forge UI - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-12
**Phase:** 02-forge-ui
**Areas discussed:** Scope, Icon art, Button layout order, Grid shape + disabled visuals

---

## Opening Context

Phase 2's 3 ROADMAP success criteria (9 base hammer buttons, correct PoE tooltips, grey-out when zero) were substantially pulled forward in commit `9634221` ("feat(forge): pull phase 2 UI forward + add F1/F2 debug shortcuts + 2-letter placeholders"). Phase 1 verification (`01-VERIFICATION.md`) confirmed the pull-forward is clean and does not regress Phase 1's structural contracts. The discussion focused on what polish remains and whether Phase 2 should close as-is or do a deliberate cleanup pass.

---

## Area Selection

**Question:** "Phase 2's 3 ROADMAP success criteria are already met by the pulled-forward UI work. Which areas do you want to discuss?"

| Option | Description | Selected |
|--------|-------------|----------|
| Scope: what's left to do | Pin down whether Phase 2 is polish + verify + close or needs real implementation work | ✓ |
| Icon art for AU/CH/EX | Currently placeholder 2-letter text; options for icons | ✓ |
| Button layout order | Current scene order = legacy 6 + 3 appended; PoE-natural alternative | ✓ |
| Grid shape + disabled visuals | 9 buttons in 2×5 grid leaves Exalt orphan; disabled state strength | ✓ |

**User's choice:** All four — full polish discussion.

---

## Scope

**Question:** "Given the pull-forward, what's Phase 2's actual scope?"

| Option | Description | Selected |
|--------|-------------|----------|
| Polish + verify + close | Harden rough edges (icons/layout/disabled visuals) and run verification; 1 plan | ✓ |
| Verify-only (close as shipped) | Call Phase 2 done; no code changes; defer polish | |
| Full polish pass | Proper UI pass with new icons, reorder, disabled tightening, 3×3; 1-2 plans | |
| Minimal correctness only | Only fix actively-broken items; skip cosmetic polish | |

**User's choice:** Polish + verify + close
**Notes:** Balances effort against the fact that the criteria are already met. One small plan to land visual consistency + run verification.

---

## Icons

**Question:** "How should Augment/Chaos/Exalt visually differ from the 6 hammers that have art?"

| Option | Description | Selected |
|--------|-------------|----------|
| 2-letter for all 9 (consistent) | Strip PNG icons from all 9 base buttons; pure 2-letter code treatment across the row | ✓ |
| Keep current mix | 6 PNG+text, 3 text-only; zero churn but visually inconsistent | |
| Reuse+tint existing PNGs | Recolor existing art for new hammers via Godot modulate | |
| Create new art | Make 3 new PNGs matching existing style | |

**User's choice:** 2-letter for all 9 (consistent)
**Notes:** Eliminates the "faded PNG + 2-letter overlay fighting each other" visual noise on the 6 legacy buttons. PNG files stay on disk (may be reused later); only the `icon = ExtResource(...)` scene-tree lines get stripped.

---

## Order

**Question:** "What order should the 9 base hammer buttons appear in?"

| Option | Description | Selected |
|--------|-------------|----------|
| PoE crafting arc | Transmute → Augment → Alchemy → Alteration → Regal → Chaos → Exalt → Divine → Annulment | |
| Rarity progression | Normal-input → Magic-input → Rare-input → Any modded; layout teaches the rarity system | ✓ |
| Keep current | Legacy 6 + 3 appended; zero churn | |
| Alphabetical | Predictable but breaks usage arcs | |

**User's choice:** Rarity progression
**Notes:** Groups: Normal-input (Transmute, Alchemy) → Magic-input (Augment, Alteration, Regal) → Rare-input (Chaos, Exalt) → Any modded item (Divine, Annulment). Layout doubles as a self-documenting tutorial for new players.

---

## Grid shape

**Question:** "How should the 9 buttons be arranged? (Rarity-ordered content: TR/AL | AU/AT/RG | CH/EX | DI/AN)"

| Option | Description | Selected |
|--------|-------------|----------|
| 3×3 grid, rows by group | Rows correspond to rarity groups with trailing empty cells | ✓ |
| 3×3 linear fill | Rows fill sequentially, group boundaries blurred | |
| 2×5 with group gaps | Vertical spacer rows between groups; taller sidebar | |
| 1×9 vertical list | Single column stack | |

**User's choice:** 3×3 grid, rows by group (in practice a 3-col × 4-row grid since the 4th "Any modded" group needs its own row). Three trailing empty cells visually reinforce group boundaries.
**Notes:** Final layout:
```
Row 1:  TR   AL   [empty]     ← Normal-input
Row 2:  AU   AT   RG          ← Magic-input
Row 3:  CH   EX   [empty]     ← Rare-input
Row 4:  DI   AN   [empty]     ← Any modded
```

---

## Disabled look

**Question:** "How strong should the 'zero currency' visual be?"

| Option | Description | Selected |
|--------|-------------|----------|
| Default Godot greying | button.disabled only; zero code | ✓ |
| Disabled + dim opacity | Modulate alpha ~0.4 for obvious 'off' | |
| Disabled + desaturated label | Dark grey label color; shape stays crisp | |

**User's choice:** Default Godot greying
**Notes:** Ship default behavior. If UAT later shows it's not distinguishable, layer extras as a follow-up. Don't preemptively over-engineer.

---

## Claude's Discretion

- Exact pixel offsets for the new 3×4 grid (preserve 45×45 button size, ~10-15px gutters)
- Whether TagHammerSection's offset_top needs shifting (depends on recomputed grid height)
- Whether to delete the dead `hammer_icons` dict entries entirely or leave them with a comment
- Inline comment verbiage for the rarity grouping

## Deferred Ideas

- New icon art for Augment/Chaos/Exalt (future milestone)
- Rename PNG asset files to match class names (made moot by icon-strip; low-priority cleanup)
- Stronger disabled visuals (opacity or desaturation) — revisit only if UAT flags it
- Tag hammer 2-letter treatment (changes subsystem framing; deferred)
- Visual group separators (empty cells already separate — add only if grouping isn't obvious)
- Stash slot icons (out of scope — different subsystem)
