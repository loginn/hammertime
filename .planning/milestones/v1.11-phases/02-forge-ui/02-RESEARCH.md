# Phase 2: Forge UI — Research

**Researched:** 2026-04-12
**Domain:** Godot 4 scene file editing (forge_view.tscn / forge_view.gd); visual polish of a manually-positioned button grid
**Confidence:** HIGH — all findings are from direct source inspection (scene file, GDScript, CONTEXT.md, verification docs)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Phase 2 is a polish + verify + close pass, not a rebuild. The pull-forward (commit 9634221) already landed all 9 base buttons, correct tooltips, and grey-out. What remains is visual cleanup + verification.
- **D-02:** 1 plan for this phase. Small atomic tasks covering: scene layout edit, icon strip, any dead-code cleanup, then verify.
- **D-03:** Remove `icon = ExtResource(...)` from all 6 base hammer buttons in `forge_view.tscn` that reference legacy PNGs (RunicHammerBtn, AlchemyHammerBtn, TackHammerBtn, GrandHammerBtn, AnnulmentHammerBtn, DivineHammerBtn).
- **D-04:** 2-letter codes already set in `hammer_codes` dict and applied in `_ready()`. No code change needed for text overlay — only the scene-tree icon lines.
- **D-05:** Asset PNG files stay on disk untouched.
- **D-06:** `hammer_icons` dict becomes dead code after D-03. Planner must grep for usage and remove if no longer referenced; if referenced, leave in place with comment.
- **D-07:** Tag hammers are untouched. Do not adopt 2-letter codes for tag hammers.
- **D-08 / D-09:** 9 base hammer buttons ordered by rarity progression. 4 groups: Normal (TR, AL), Magic (AU, AT, RG), Rare (CH, EX), Any-modded (DI, AN).
- **D-10:** TagHammerSection stays below base hammer grid; offset_top may need adjustment if grid height changes.
- **D-11:** 3-col × 4-row grid. Row 1: TR AL [empty]. Row 2: AU AT RG. Row 3: CH EX [empty]. Row 4: DI AN [empty].
- **D-12:** Keep 45×45 button size, 55px spacing. Do not redesign.
- **D-13:** HammerSidebar is 260px wide × 710px tall. Sidebar resize not needed. Verify tag section still fits within 710px.
- **D-14:** CountLabel children stay attached to buttons; move with parent. No CountLabel styling changes.
- **D-15:** Accept default Godot `button.disabled` behavior. No custom opacity/desaturation.
- **D-16:** If UAT surfaces inadequate greying, defer as follow-up idea.
- **D-17:** Run gsd-verifier after code changes. No runtime UAT required for Phase 2.
- **D-18:** Verification passes when: (a) exactly 9 base button nodes in rarity order, (b) none have `icon = ExtResource(...)`, (c) `hammer_descriptions` has all 9 keys with PoE-correct copy, (d) `button.disabled = (count <= 0)` still present, (e) Godot editor loads scene without parse errors, (f) one manual smoke check.

### Claude's Discretion

- Exact pixel offsets for the new 3×4 grid — pick values that preserve 45×45 button size and roughly 10-15px gutter
- Whether to keep `TagHammerSection`'s `offset_top` untouched or shift it
- Whether to delete dead `hammer_icons` dict entries entirely or leave a comment trail
- Exact verbiage for inline comments documenting the rarity grouping

### Deferred Ideas (OUT OF SCOPE)

- New icon art for Augment/Chaos/Exalt
- Rename PNG asset files
- Stronger disabled visual state (opacity/desaturation)
- Tag hammer 2-letter treatment
- Visual group separators (horizontal rules / labels between rarity rows)
- Runtime UAT of the 3 Phase 2 success criteria
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| UI-01 | Forge view shows 8 base hammer buttons (+ 5 tag hammers) with correct tooltips | Already structurally landed by pull-forward (commit 9634221); this phase closes visual consistency gaps (icon strip, grid reorder) to bring the scene to the state UI-01 intends |
</phase_requirements>

---

## Current State

### forge_view.tscn — 9 Base Hammer Button Nodes (Lines 40–254)

| # | Node Name | Scene Line | offset_left | offset_top | offset_right | offset_bottom | Has icon? | icon ExtResource |
|---|-----------|-----------|------------|-----------|-------------|--------------|-----------|-----------------|
| 1 | RunicHammerBtn | 40 | 15 | 15 | 60 | 60 | YES | `"4_runic"` (runic_hammer.png) |
| 2 | AlchemyHammerBtn | 64 | 70 | 15 | 115 | 60 | YES | `"5_forge"` (forge_hammer.png) |
| 3 | TackHammerBtn | 88 | 15 | 70 | 60 | 115 | YES | `"6_tack"` (tack_hammer.png) |
| 4 | GrandHammerBtn | 112 | 70 | 70 | 115 | 115 | YES | `"7_grand"` (grand_hammer.png) |
| 5 | AnnulmentHammerBtn | 136 | 15 | 125 | 60 | 170 | YES | `"8_claw"` (claw_hammer.png) |
| 6 | DivineHammerBtn | 160 | 70 | 125 | 115 | 170 | YES | `"9_tuning"` (tuning_hammer.png) |
| 7 | AugmentHammerBtn | 184 | 15 | 180 | 60 | 225 | NO | — |
| 8 | ChaosHammerBtn | 208 | 70 | 180 | 115 | 225 | NO | — |
| 9 | ExaltHammerBtn | 232 | 15 | 235 | 60 | 280 | NO | — |

**Current layout pattern:** 2 columns (x=15 and x=70), 5 rows (y=15, 70, 125, 180, 235). Column step = 55px. Row step = 55px. Button size = 45×45px. Each button with `icon` also has `expand_icon = true`.

**The 3 text-only buttons** (Augment, Chaos, Exalt) already have `text = "AU"/"CH"/"EX"` and `theme_override_font_sizes/font_size = 14` set in the scene. The 6 icon buttons do NOT have these — the text is set at runtime by `_ready()` via `hammer_codes`. After stripping icons, the 6 legacy buttons will display their 2-letter codes from `_ready()` only, with no font size override in the scene. This is acceptable (the tag-button comparison confirms runtime text works fine).

**Rarity-mapping mismatch in current layout:** Buttons are not grouped by rarity. Current order is: TR, AL (row 1), AT, RG (row 2), AN, DI (row 3), AU, CH (row 4), EX (row 5). The rarity groups are scrambled. D-11 reorders them.

### TagHammerSection (Line 256)

```
offset_left = 15, offset_top = 290, offset_right = 205, offset_bottom = 710
visible = false
```

- Occupies 290px → 710px (420px tall) when visible.
- Bottom of current base-hammer grid (ExaltHammerBtn): `offset_bottom = 280`.
- Gap between grid bottom (280) and TagHammerSection top (290) = 10px.

### forge_view.gd — Key Dicts and Functions

**hammer_icons dict (lines 96–103):** 6 entries — transmute, alchemy, alteration, regal, annulment, divine — all pointing to PNG assets via `preload()`. Note: `augment`, `chaos`, `exalt` are NOT in this dict (those 3 already text-only).

**hammer_codes dict (lines 107–122):** 14 entries (9 base + 5 tag). Complete, correct.

**hammer_descriptions dict (lines 78–93):** 14 entries (9 base + 5 tag). Complete, PoE-accurate. Already rewritten by Phase 2 pull-forward. DO NOT MODIFY.

**`update_currency_button_states()` (lines 371–410):** `button.disabled = (count <= 0)` at line 379. `button.icon` is NOT set anywhere in this function (the old v1.3 code set it there, but the current code does not). The function only sets `button.disabled`, `count_label.text`, and `button.tooltip_text`.

**`_ready()` (lines 125–245):** Sets `btn.text = hammer_codes[currency_type]` for ALL 14 buttons (line 164–165). This is what displays "TR"/"AL"/etc. on the 6 icon buttons at runtime — but the PNG icon is also rendered underneath, causing the "fighting" visual.

### ext_resource Header Block

The scene header declares 9 ext_resource entries (lines 3–11):

```
id="1_forge"    → forge_view.gd (Script — must keep)
id="2_sword"    → sword2.png (used elsewhere in scene — must keep)
id="3_hero"     → hero.png (used elsewhere — must keep)
id="4_runic"    → runic_hammer.png (only used on RunicHammerBtn icon= line)
id="5_forge"    → forge_hammer.png (only used on AlchemyHammerBtn icon= line)
id="6_tack"     → tack_hammer.png (only used on TackHammerBtn icon= line)
id="7_grand"    → grand_hammer.png (only used on GrandHammerBtn icon= line)
id="8_claw"     → claw_hammer.png (only used on AnnulmentHammerBtn icon= line)
id="9_tuning"   → tuning_hammer.png (only used on DivineHammerBtn icon= line)
```

When the 6 `icon = ExtResource(...)` lines are stripped from the button nodes, ext_resource IDs `4_runic` through `9_tuning` become unreferenced. Godot 4 .tscn format does NOT require removing unused ext_resource declarations — the file will load cleanly. However, leaving them creates dead-reference clutter. The executor should also strip the 6 `ext_resource` header lines (ids 4–9) for cleanliness, since D-05 says PNGs stay on disk but nothing prevents removing their scene-file declarations.

**IMPORTANT:** Removing an ext_resource header line is safe only if no other node in the scene references that ID. A quick grep confirms: `id="4_runic"` through `id="9_tuning"` appear only on lines 6–11 (declarations) and once each on lines 47, 71, 95, 119, 143, 167 (the `icon = ExtResource(...)` lines on the 6 buttons). No other nodes in the scene use these IDs.

---

## Gap Analysis

CONTEXT.md leaves these open (delegated to Claude's Discretion):

| Gap | Status After Research |
|-----|----------------------|
| Exact pixel offsets for 3×4 grid | **Resolved** — see Concrete Values below |
| TagHammerSection offset_top: keep or shift | **Resolved** — recommend keeping at 290 (rationale below) |
| hammer_icons dict: delete entirely or comment | **Resolved** — delete entirely (zero live read-sites) |
| ext_resource header lines 6–11: strip or keep | **Resolved** — strip (no other references; cleaner file) |
| Whether 6 legacy buttons need font_size = 14 set in scene | **Resolved** — not needed; runtime `_ready()` text already works without it (tag buttons have no font_size override either) |

---

## Proposed Implementation Approach

This phase has 1 plan, ~4 atomic tasks:

### Task 1: Reposition all 9 base hammer buttons into 3×4 rarity-grouped grid

Edit `scenes/forge_view.tscn`. For each of the 9 button node blocks, update `offset_left`, `offset_top`, `offset_right`, `offset_bottom` to the new grid positions (see Concrete Values). Node order in the file should also be reordered to match reading order (TR, AL, AU, AT, RG, CH, EX, DI, AN) — this aids future readability but does NOT affect runtime because Godot uses node names, not file order.

CountLabel children come along automatically — their coordinates are relative to their parent button and do not change.

### Task 2: Strip icon lines from 6 legacy buttons + remove dead ext_resource headers

For each of the 6 icon buttons (RunicHammerBtn, AlchemyHammerBtn, TackHammerBtn, GrandHammerBtn, AnnulmentHammerBtn, DivineHammerBtn), remove:
- `icon = ExtResource("X_name")`
- `expand_icon = true`

Also remove the 6 `ext_resource` header lines (ids 4–9, lines 6–11) from the top of the file.

No other scene properties change. `toggle_mode = true` is preserved on all buttons.

### Task 3: Delete hammer_icons dict from forge_view.gd

Remove lines 95–103 (the `# Hammer icon textures` comment and the `hammer_icons` dict block). Confirmed zero read-sites in any live `.gd` file (grep audit below).

### Task 4: Structural verification (D-18 checklist)

Run the grep checks documented in the Validation Architecture section. Confirm Godot editor loads the scene without parse errors (manual check). Run one smoke-check confirming buttons display 2-letter codes and grey out.

---

## Concrete Values

### 3×4 Grid Pixel Offsets

**Grid parameters (matching existing scene conventions):**
- Button size: 45×45 px (unchanged)
- Column step: 55px (unchanged — verified from current scene: col B offset_left=70 minus col A offset_left=15 = 55)
- Row step: 55px (unchanged — verified from current scene: row 2 offset_top=70 minus row 1 offset_top=15 = 55)
- Grid origin: x=15, y=15 (unchanged — matches current row 1 / col A)

**Column x positions:**
| Col | offset_left | offset_right |
|-----|------------|-------------|
| 0 (A) | 15 | 60 |
| 1 (B) | 70 | 115 |
| 2 (C) | 125 | 170 |

**Row y positions:**
| Row | offset_top | offset_bottom | Rarity group |
|-----|-----------|--------------|-------------|
| 0 | 15 | 60 | Normal-input |
| 1 | 70 | 115 | Magic-input |
| 2 | 125 | 170 | Rare-input |
| 3 | 180 | 225 | Any-modded |

**Per-button final offsets:**

| Button | Key | Row | Col | offset_left | offset_top | offset_right | offset_bottom |
|--------|-----|-----|-----|------------|-----------|-------------|--------------|
| RunicHammerBtn | transmute | 0 | 0 | 15 | 15 | 60 | 60 |
| AlchemyHammerBtn | alchemy | 0 | 1 | 70 | 15 | 115 | 60 |
| [empty] | — | 0 | 2 | — | — | — | — |
| AugmentHammerBtn | augment | 1 | 0 | 15 | 70 | 60 | 115 |
| TackHammerBtn | alteration | 1 | 1 | 70 | 70 | 115 | 115 |
| GrandHammerBtn | regal | 1 | 2 | 125 | 70 | 170 | 115 |
| ChaosHammerBtn | chaos | 2 | 0 | 15 | 125 | 60 | 170 |
| ExaltHammerBtn | exalt | 2 | 1 | 70 | 125 | 115 | 170 |
| [empty] | — | 2 | 2 | — | — | — | — |
| DivineHammerBtn | divine | 3 | 0 | 15 | 180 | 60 | 225 |
| AnnulmentHammerBtn | annulment | 3 | 1 | 70 | 180 | 115 | 225 |
| [empty] | — | 3 | 2 | — | — | — | — |

**Grid bottom:** Row 3 offset_bottom = 225px.

### TagHammerSection offset_top: KEEP AT 290

Recommendation: leave `TagHammerSection.offset_top = 290` unchanged.

Rationale:
- New base grid bottom = 225px. TagHammerSection top = 290px. Gap = 65px. This is comfortable whitespace that visually separates the base hammer grid from the tag section.
- The previous layout had only a 10px gap (old grid bottom=280, tag section top=290). The new layout actually increases the gap without any change to the tag section.
- The tag section is `visible = false` until prestige — most players never see it alongside the base hammer grid. Optimizing this gap is low-value.
- The tag section content fits within its 420px allocation (offset_top=290 to offset_bottom=710). No overflow risk.
- Changing offset_top = 290 to something smaller risks the tag section overlapping base hammer buttons if the base grid ever grows in a future phase.

**Decision: Keep `TagHammerSection.offset_top = 290`. No change.**

### hammer_icons Dict

**Verdict: DELETE ENTIRELY.**

Grep audit result: `hammer_icons` appears in exactly 1 live `.gd` file — `scenes/forge_view.gd:96` (the dict declaration). No read-sites exist anywhere in live code. All other mentions are in `.planning/` historical archives, which is expected and correct.

The dict is dead code as of the pull-forward. Remove lines 95–103:
```gdscript
# Hammer icon textures (existing 6 — new hammers use 2-letter code placeholders)
var hammer_icons: Dictionary = {
    "transmute": preload("res://assets/runic_hammer.png"),
    "alchemy": preload("res://assets/forge_hammer.png"),
    "alteration": preload("res://assets/tack_hammer.png"),
    "regal": preload("res://assets/grand_hammer.png"),
    "annulment": preload("res://assets/claw_hammer.png"),
    "divine": preload("res://assets/tuning_hammer.png")
}
```

No comment trail needed — the dict purpose is already documented in Phase 1 historical docs, and leaving a stub or tombstone comment in production code adds noise.

---

## Risks & Unknowns

### Risk 1: Node reordering in .tscn breaks nothing at runtime (CONFIDENCE: HIGH — no risk)

Godot resolves node references by name (`$HammerSidebar/RunicHammerBtn`), not by order in the .tscn file. Reordering button node blocks within the file is safe. The `@onready` vars in `forge_view.gd:7–16` use name-based paths and are unaffected.

### Risk 2: Removing ext_resource header lines that still have references elsewhere

**Mitigated:** Grepped for `"4_runic"`, `"5_forge"`, `"6_tack"`, `"7_grand"`, `"8_claw"`, `"9_tuning"` — each appears exactly twice: once in the header declaration and once on its button's `icon =` line. After stripping the `icon =` lines, the headers become unreferenced. Godot 4 tolerates unused ext_resource declarations, but stripping them is cleaner and removes potential confusion. Executor must verify no OTHER ext_resource uses the numeric portion of these IDs (e.g., confirm `ExtResource("4_runic")` doesn't appear anywhere else in the file before removing).

### Risk 3: The 6 legacy buttons have no `font_size` override in the scene

The 3 text-only buttons (Augment, Chaos, Exalt) have `theme_override_font_sizes/font_size = 14` set in the scene. After stripping icons, the 6 legacy buttons will NOT have this override — their 2-letter text (set by `_ready()`) will use the default theme font size instead of 14px. This may cause slight visual inconsistency between the 6 formerly-icon buttons and the 3 always-text buttons.

**Assessment:** LOW risk. The `_ready()` loop applies `btn.text = hammer_codes[currency_type]` to ALL 14 buttons uniformly, and the tag buttons have no font size override either. The default Godot button font size is typically 16px in Godot 4 default theme, which is close enough to 14px to be imperceptible. If visual consistency is needed, the executor can optionally add `theme_override_font_sizes/font_size = 14` to each of the 6 buttons during the icon-strip task.

**Recommendation:** Add `theme_override_font_sizes/font_size = 14` to all 6 stripped buttons during Task 2 to match the 3 existing text-only buttons. This is a 6-line addition with zero risk.

### Risk 4: Godot .tscn parse error if ext_resource removal is incomplete

If the executor removes an ext_resource header line but misses one `icon = ExtResource(...)` read-site (or vice versa), Godot will throw a parse error. The mitigation is to remove both the header AND the read-site atomically, and verify with: `grep -c "ExtResource" scenes/forge_view.tscn` before and after (should drop by 6 × 2 = 12 occurrences if all 6 header + 6 icon lines are removed, but ids 1–3 remain for script/textures, so net result should be 3 ExtResource occurrences remaining).

### Risk 5: CountLabel offset_right = 38 with 45-wide button

Each CountLabel has `offset_right = 38` which gives 38px width inside a 45px-wide button, and `horizontal_alignment = 2` (right-align). This means the count text is right-aligned at 38px (7px from right edge). This is already working in production and does not change.

---

## Validation Architecture

Config check: `workflow.nyquist_validation` key is absent from `.planning/config.json` — treating as enabled.

### What CAN Be Tested Programmatically (grep-based structural checks)

These checks run in < 5 seconds and require no Godot runtime:

| Check | Command | Expected Result | Verifies |
|-------|---------|-----------------|---------|
| 9 base button nodes exist in scene | `grep -c "HammerBtn" scenes/forge_view.tscn` | 14 (9 base + 5 tag) | D-18(a) |
| No icon ExtResource on base buttons | `grep -n "icon = ExtResource" scenes/forge_view.tscn` | 0 matches | D-18(b) |
| No expand_icon lines | `grep -n "expand_icon = true" scenes/forge_view.tscn` | 0 matches | D-18(b) cleanup |
| hammer_descriptions has all 9 base keys | `grep -c '"transmute"\|"augment"\|"alchemy"\|"alteration"\|"regal"\|"chaos"\|"exalt"\|"divine"\|"annulment"' scenes/forge_view.gd` | at least 9 (appears in multiple dicts) | D-18(c) |
| disabled binding still present | `grep -n "button.disabled = (count <= 0)" scenes/forge_view.gd` | line ~379 | D-18(d) |
| hammer_icons dict removed | `grep -n "hammer_icons" scenes/forge_view.gd` | 0 matches | D-06 |
| Rarity order: TR first in scene | `grep -n "RunicHammerBtn" scenes/forge_view.tscn` | Before AlchemyHammerBtn line | D-11 order |
| Rarity order: AU in row 2 (offset_top = 70) | `grep -A3 "AugmentHammerBtn" scenes/forge_view.tscn \| grep "offset_top"` | `offset_top = 70.0` | D-11 concrete |
| RG in col 3 (offset_left = 125) | `grep -A3 "GrandHammerBtn" scenes/forge_view.tscn \| grep "offset_left"` | `offset_left = 125.0` | D-11 concrete |
| TagHammerSection offset_top unchanged | `grep -A3 "TagHammerSection" scenes/forge_view.tscn \| grep "offset_top"` | `offset_top = 290.0` | no regression |
| Dead ext_resource headers removed | `grep -c "ext_resource" scenes/forge_view.tscn` | 3 (script, sword, hero) | cleanup |

**No new test files needed.** These are ad-hoc grep commands in the verification step — not a persistent test suite. The project has no existing GDScript test infrastructure for UI scenes.

### What CANNOT Be Tested Without Running Godot

- Actual visual rendering of 2-letter text on buttons
- That tooltip text displays on hover (tooltip_text is a property but display requires runtime)
- That the disabled greying is visually distinguishable
- That buttons respond to clicks correctly after reorder

### Manual Smoke Check Scope (D-18(f))

Per D-17/D-18, one manual smoke check is required. Scope:

1. Open Godot editor — confirm scene loads without parse errors (F1 in editor or via Project > Open Scene)
2. Play the scene (F5 or run ForgeView in isolation)
3. Press F1 (debug shortcut) — confirm all 9 base buttons show their 2-letter codes and are enabled
4. Verify buttons show in rarity-grouped order: TR/AL row, AU/AT/RG row, CH/EX row, DI/AN row
5. Start fresh (no F1) — confirm all 9 base buttons are greyed out (zero currency)
6. Hover one button — confirm tooltip shows currency name, count, and PoE behavior description

This smoke check covers D-18(e) and D-18(f). No save-state changes needed.

### Framework Summary

| Property | Value |
|----------|-------|
| Framework | None (grep-based structural checks + manual smoke) |
| Config file | None |
| Quick structural checks | `grep -c "icon = ExtResource" scenes/forge_view.tscn` (expect 0) |
| Full structural suite | All grep checks in table above |
| Phase gate | All greps green + manual smoke pass before gsd-verifier |

---

## Sources

### Primary (HIGH confidence — direct source inspection)

- `scenes/forge_view.tscn` lines 1–335 — complete button inventory, current offsets, ext_resource IDs
- `scenes/forge_view.gd` lines 1–412 — hammer_icons dict, hammer_codes dict, hammer_descriptions dict, `_ready()`, `update_currency_button_states()`
- `.planning/workstreams/fix-hammers/phases/02-forge-ui/02-CONTEXT.md` — locked decisions D-01 through D-18
- `.planning/workstreams/fix-hammers/phases/01-hammer-models/01-VERIFICATION.md` — pull-forward regression check, confirmed current scene state
- `.planning/workstreams/fix-hammers/phases/01-hammer-models/01-02-SUMMARY.md` — handoff notes

### Secondary (HIGH confidence — grep audit)

- `grep "hammer_icons" **` across entire repo (all file types) — confirmed 1 live `.gd` reference (the dict declaration), all others in `.planning/` archives

---

## RESEARCH COMPLETE

**Confidence:** HIGH — all findings from direct source file inspection. No inference or estimation.

### Key Findings

1. **6 buttons have `icon = ExtResource(...)` lines** (RunicHammerBtn, AlchemyHammerBtn, TackHammerBtn, GrandHammerBtn, AnnulmentHammerBtn, DivineHammerBtn) — each also has `expand_icon = true`. Both lines must be stripped per D-03.

2. **hammer_icons dict has ZERO live read-sites** — only the dict declaration at `forge_view.gd:96` references it in all live `.gd` files. Safe to delete entirely.

3. **Exact new grid positions computed** — all 9 buttons fit in a 3-col × 4-row grid using the existing 55px step; the rightmost column (x=125) adds one new column that is currently unused. Grid bottom = y=225, well below the TagHammerSection top = 290 (65px gap).

4. **TagHammerSection: no change needed** — current offset_top=290 gives a comfortable 65px gap above the new grid bottom at y=225. Leave unchanged.

5. **ext_resource header IDs 4–9** (6 PNG entries) are only referenced by the 6 `icon = ExtResource(...)` lines being stripped. Both the headers and the read-sites should be removed together to keep the scene file clean.

6. **Optional improvement:** Add `theme_override_font_sizes/font_size = 14` to the 6 stripped buttons to visually match the 3 existing text-only buttons (AugmentHammerBtn, ChaosHammerBtn, ExaltHammerBtn already have this in the scene).

### Ready for Planning

All information needed to write atomic task `<action>` blocks is present. The planner can copy exact offset values from the Concrete Values table and exact grep patterns from the Validation Architecture table.
