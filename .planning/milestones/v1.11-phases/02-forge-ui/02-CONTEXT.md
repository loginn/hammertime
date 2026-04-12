# Phase 2: Forge UI - Context

**Gathered:** 2026-04-12
**Status:** Ready for planning

<domain>
## Phase Boundary

The forge view exposes all 9 base hammer buttons (Transmute + 8 PoE hammers) alongside the 5 tag hammers, each with an accurate PoE-behavior tooltip and a greyed-out state when the player has zero of that currency. This phase is a **polish + verify + close** pass: most of the mechanical work was already pulled forward in commit `9634221` ("feat(forge): pull phase 2 UI forward"). What remains is visual consistency cleanup (strip PNG icons in favor of 2-letter codes), a rarity-grouped layout, and running verification against the 3 ROADMAP success criteria.

**In scope:**
- `scenes/forge_view.tscn` — reposition the 9 base hammer buttons into a 3-col × 4-row rarity-grouped grid; remove `icon = ExtResource(...)` lines from the 6 buttons that currently have PNG icons
- `scenes/forge_view.gd` — remove the now-dead `hammer_icons` dict (or its base-hammer entries) if it's no longer referenced anywhere
- Verification of the 3 ROADMAP success criteria (buttons present, tooltips correct, greyed when zero)

**Out of scope:**
- Tag hammer visuals (they work correctly as "Fire (0)" text buttons — leave them)
- Drop-table wiring, save format, integration tests (all Phase 3)
- Renaming the 6 legacy PNG asset files (`forge_hammer.png`, `claw_hammer.png`, `tuning_hammer.png`, etc.) — deferred in Phase 1 RESEARCH; this phase removes their use from the forge UI so the filename mismatch is no longer user-visible, but the files stay on disk
- New icon art for Augment/Chaos/Exalt — explicitly chosen against in favor of the unified 2-letter treatment
- Stronger disabled visuals (opacity / desaturation) — accept Godot default
- Button reordering beyond the rarity-grouped 3×4 grid specified below
- Any Phase 3 work (drop table, save format, integration tests)

</domain>

<decisions>
## Implementation Decisions

### Scope & Closure
- **D-01:** Phase 2 is a **polish + verify + close** pass, not a rebuild. The pull-forward in commit `9634221` already landed the three ROADMAP success criteria (all 9 base buttons present, correct tooltips, grey-out when zero). The remaining work is visual cleanup + running gsd-verifier + shipping.
- **D-02:** **1 plan** for this phase. Small, atomic tasks covering: scene layout edit, icon strip, any dead-code cleanup, then verify. No sub-plans, no multi-wave orchestration.

### Icon Treatment (Unified 2-Letter Codes)
- **D-03:** **Remove `icon = ExtResource(...)` from all 6 base hammer buttons in `forge_view.tscn`** that currently reference legacy PNGs (Runic, Alchemy, Tack, Grand, Annulment, Divine). The buttons become pure 2-letter code buttons — consistent with the 3 new hammers (Augment, Chaos, Exalt) which already use text-only.
- **D-04:** The 2-letter codes are already set in `scenes/forge_view.gd:107-122` (`hammer_codes` dict) and applied at `_ready()` line 164-165 (`btn.text = hammer_codes[currency_type]`). No code change needed for the text overlay itself — only the scene-tree icon lines.
- **D-05:** Asset PNG files stay on disk untouched. We don't delete `assets/forge_hammer.png` / `assets/claw_hammer.png` / `assets/tuning_hammer.png` etc. — they may be reused later (e.g., stash icons or future art pass) and removing them risks breaking references we haven't audited.
- **D-06:** The `hammer_icons` dict in `forge_view.gd:96-103` becomes dead code after D-03. Planner should grep for its usage and remove it if no longer referenced. If it IS referenced somewhere outside base hammer buttons (e.g., tooltip previews, stash icons), leave the dict in place and annotate with a comment explaining the residual use.
- **D-07:** **Tag hammers are untouched.** Tag hammer buttons use full-word text ("Fire (0)", "Cold (0)", etc.) and are visually distinct from base hammers — that's acceptable and signals "tag hammers are a different system." Do not adopt 2-letter codes for tag hammers in this phase.

### Button Order (Rarity Progression)
- **D-08:** The 9 base hammer buttons are ordered by **rarity progression** — which rarity the currency primarily targets. Order within each group is canonical PoE:
  - **Group 1 — Normal-input (2):** Transmute (TR), Alchemy (AL)
  - **Group 2 — Magic-input (3):** Augment (AU), Alteration (AT), Regal (RG)
  - **Group 3 — Rare-input (2):** Chaos (CH), Exalt (EX)
  - **Group 4 — Any modded item (2):** Divine (DI), Annulment (AN)
- **D-09:** Rationale for the Group 4 placement: Divine and Annulment work on any modded item (Magic or Rare). Rather than forcing them into one rarity group, they form their own "post-craft utility" group at the bottom — the hammers a player reaches for after they've already built the item up.
- **D-10:** Tag hammer section (`TagHammerSection`) stays below the base hammer grid, unchanged. Its offset_top in the scene may need adjustment if the base-hammer grid height changes — planner to recompute.

### Grid Layout (3×4, Rows by Group)
- **D-11:** **3-column × 4-row grid**, rows correspond to rarity groups:
  ```
  Row 1:  TR   AL   [empty]     ← Normal-input
  Row 2:  AU   AT   RG          ← Magic-input
  Row 3:  CH   EX   [empty]     ← Rare-input
  Row 4:  DI   AN   [empty]     ← Any modded
  ```
  Three empty cells (row 1 col 3, row 3 col 3, row 4 col 3). The empty cells are intentional — they visually reinforce the rarity group boundaries and keep the grid rectangular.
- **D-12:** Button size stays 45×45 px matching the current scene (current buttons use `offset_right = offset_left + 45; offset_bottom = offset_top + 45`). Keep the existing spacing (55 px between button centers both horizontal and vertical — current scene uses 70-15=55 horizontal step, 70-15=55 vertical step). Do not redesign button size or spacing in this phase.
- **D-13:** HammerSidebar total size: the current sidebar is 260px wide × 710px tall (`offset_left=40, offset_right=300, offset_top=10, offset_bottom=720`). A 3-col grid fits within 260px width (3 × 55 + padding). A 4-row grid is taller than the current 4-row layout — planner may need to shift `TagHammerSection`'s offset_top down by one row height. Verify tag section still fits within the 710px sidebar height.
- **D-14:** CountLabel children stay attached to their button nodes and move with them. No changes to CountLabel styling (11px font, black text with white outline, bottom-right alignment).

### Disabled Visual State
- **D-15:** Accept **default Godot `button.disabled`** behavior for zero-currency buttons. No opacity override, no desaturation, no custom stylebox. The current code at `forge_view.gd:379` (`button.disabled = (count <= 0)`) is sufficient.
- **D-16:** If UAT surfaces that default greying isn't distinguishable enough, add a Deferred idea to layer opacity/desaturation in a follow-up phase. Do not preemptively add it here.

### Verification Strategy
- **D-17:** After code changes, run `gsd-verifier` against the 3 ROADMAP success criteria structurally (scene tree has 9 buttons, tooltips match expected strings, disabled binding present). No runtime UAT is required for Phase 2 on its own because the behavioral UAT already happened in Phase 1 (`01-HUMAN-UAT.md`, 7/7 pass) and covered the same buttons/tooltips.
- **D-18:** Phase 2 verification passes when: (a) `forge_view.tscn` has exactly 9 base hammer button nodes in the rarity-grouped order, (b) none of the 9 have `icon = ExtResource(...)` lines, (c) `hammer_descriptions` dict has all 9 expected keys with PoE-correct copy, (d) `button.disabled = (count <= 0)` still fires in `update_currency_button_states()`, (e) Godot editor loads the scene without parse errors, (f) one manual smoke-check that all 9 buttons visually display their 2-letter code and grey out correctly.

### Claude's Discretion
- Exact pixel offsets for the new 3×4 grid — pick values that preserve 45×45 button size and roughly 10-15px gutter between cells
- Whether to keep `TagHammerSection`'s `offset_top` untouched (if sidebar has room) or shift it down
- Whether to delete dead `hammer_icons` dict entries entirely or leave a comment trail
- Exact verbiage for any new inline comments documenting the rarity grouping

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & Requirements
- `.planning/workstreams/fix-hammers/ROADMAP.md` §"Phase 2: Forge UI" — goal, success criteria, UI-01 mapping
- `.planning/workstreams/fix-hammers/REQUIREMENTS.md` §UI-01 — "Forge view shows 8 base hammer buttons (+ 5 tag hammers) with correct tooltips"
- `.planning/workstreams/fix-hammers/PROJECT.md` — milestone intent and scope boundaries

### Phase 1 Handoff Documents (establish what's already done)
- `.planning/workstreams/fix-hammers/phases/01-hammer-models/01-CONTEXT.md` §D-05 (literal PoE class names), §D-10 (Phase 1→2 gap risk), §"Deferred Ideas" (asset rename, tooltip polish)
- `.planning/workstreams/fix-hammers/phases/01-hammer-models/01-VERIFICATION.md` §"Regression Check (Phase 2 UI Pull-Forward)" — confirms the pull-forward state and lists what the pull-forward landed
- `.planning/workstreams/fix-hammers/phases/01-hammer-models/01-02-SUMMARY.md` §"Handoff Note to Phase 2 (Forge UI)" — lists the three remaining concerns flagged for this phase (tooltip copy, hammer_icons staleness, currency_counts seeding — notes (1) and (3) already done by pull-forward)

### Code Under Modification
- `scenes/forge_view.tscn` lines 40-254 — the 9 base hammer button definitions and CountLabel children. All button offsets will be rewritten by this phase. The icon `ExtResource` lines on the 6 legacy buttons (40, 64, 88, 112, 136, 160) are the ones to strip.
- `scenes/forge_view.tscn` lines 256+ — `TagHammerSection` — may need offset_top shift if base-hammer grid resizes
- `scenes/forge_view.gd:7-24` — `@onready` button var refs (no change; node paths stay `$HammerSidebar/*HammerBtn`)
- `scenes/forge_view.gd:78-93` — `hammer_descriptions` dict (**no change** — already correct from pull-forward)
- `scenes/forge_view.gd:96-103` — `hammer_icons` dict (likely deletable after D-03/D-06)
- `scenes/forge_view.gd:107-122` — `hammer_codes` dict (no change — already correct)
- `scenes/forge_view.gd:127-142` — `currency_buttons` mapping (no change)
- `scenes/forge_view.gd:162-165` — `_ready` loop that sets `btn.text = hammer_codes[currency_type]` (no change)
- `scenes/forge_view.gd:371-400` — `update_currency_button_states()` (no change — already greys out on count==0)

### Currency Classes (reference only — no modification)
- `models/currencies/augment_hammer.gd`, `chaos_hammer.gd`, `exalt_hammer.gd` — Phase 1 created, untouched here
- `models/currencies/alchemy_hammer.gd`, `divine_hammer.gd`, `annulment_hammer.gd` — Phase 1 renamed, untouched here
- `models/currencies/runic_hammer.gd`, `tack_hammer.gd`, `grand_hammer.gd`, `tag_hammer.gd` — untouched

### Codebase Conventions
- `.planning/codebase/CONVENTIONS.md` — GDScript conventions, tab indentation, Godot 4.5 patterns (reference only; no updates expected)
- `.planning/codebase/ARCHITECTURE.md` — scene hierarchy context (reference only)

### Not to touch
- `autoloads/game_state.gd` currency_counts seeding — already done by pull-forward
- Any `models/currencies/*.gd` file — Phase 1 completed these
- Tag hammer buttons / TagHammerSection visibility logic — works correctly
- `.planning/milestones/**` historical archives

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`hammer_codes` dict** (`forge_view.gd:107-122`) — already populated with all 14 entries (9 base + 5 tag); already applied as `btn.text` in `_ready()` line 164. This phase just needs to stop fighting it by also having icons underneath.
- **`hammer_descriptions` dict** (`forge_view.gd:78-93`) — correct PoE-accurate tooltip copy for all 9 base hammers + 5 tag hammers. Already wired into `button.tooltip_text` at line 384 via `update_currency_button_states()`. **Do not modify.**
- **`update_currency_button_states()`** (`forge_view.gd:371-400`) — single source of truth for button enable/disable and CountLabel updates. Fires `button.disabled = (count <= 0)` — the D-15 decision relies on this as-is.
- **F1/F2 debug shortcuts** (`forge_view.gd:334-349`) — grant 1000 of each base/tag currency. Useful for UAT smoke testing the disabled→enabled transition without farming.

### Established Patterns
- **CountLabel child nodes** — every Button has a CountLabel child with consistent styling (11px font, black-on-white outline, bottom-right aligned). When moving buttons, CountLabel comes along as a child. Do not detach/reattach CountLabels.
- **Button node naming** — node names follow `<Name>HammerBtn` convention (RunicHammerBtn, AlchemyHammerBtn, etc.). `@onready` vars at `forge_view.gd:7-16` depend on these exact paths. **Do not rename button nodes** in this phase — only move/reorder them. Renaming would cascade into the `@onready` block.
- **toggle_mode = true** on every base hammer button — required for the "click to select currency, click again to deselect" flow at `_on_currency_selected()` line 251. Preserve on all moved buttons.
- **`expand_icon = true`** — used on the 6 buttons that currently have PNG icons so Godot stretches the PNG to fill the button. After D-03 strips the icon, this property becomes no-op and can optionally be removed for cleanliness.

### Integration Points
- `HammerSidebar` ColorRect (`forge_view.tscn:33-38`) is the parent container for both base hammer buttons and `TagHammerSection`. All 9 base hammer buttons are siblings of `TagHammerSection` under `HammerSidebar`.
- `TagHammerSection.offset_top` currently 290 — if the base-hammer grid grows taller than 280px (current: ~280 = 5 rows × 55px + padding; new: 4 rows × 55px + padding ≈ 235px), tag section may **move up** or stay put. Planner to confirm on pixel recount.
- `_update_tag_section_visibility()` at `forge_view.gd:327` only toggles `tag_hammer_section.visible` based on prestige level — its layout offset is scene-defined and not touched at runtime. Moving `TagHammerSection` in the scene is safe.
- The sidebar is NOT a Godot `Container` (it's a `ColorRect` with manually-positioned children). All button positions are absolute offsets; reordering requires editing pixel coordinates directly. No GridContainer or VBoxContainer autolayout to lean on.

### Sidebar Space Budget
- HammerSidebar: 260px wide × 710px tall
- Base hammer grid (new): 4 rows × 55px + top padding 15px = ~235px
- Tag section (existing): ~420px (5 tag hammer buttons at ~90px each, separator, etc.)
- Total: ~655px — fits within 710px with slack. No sidebar resize needed.

</code_context>

<specifics>
## Specific Ideas

- **"The PNG icons and the 2-letter codes are fighting each other."** Currently the 6 legacy buttons show a faded PNG with "TR"/"AL"/etc. overlaid on top — visually noisy. Stripping the icons yields clean text-only buttons and eliminates the inconsistency with the 3 new text-only hammers. This is the core visual insight driving D-03.
- **Rarity rows double as a PoE crafting tutorial.** A new player scanning the sidebar sees "Row 1 = things you use on Normal items, Row 2 = things you use on Magic items, Row 3 = things you use on Rare items, Row 4 = things that touch existing mods regardless of rarity." The layout is self-documenting.
- **Don't over-invest in disabled visuals until someone complains.** The user preference is default Godot greying. If UAT later shows it's not distinguishable, add opacity/desaturation as a follow-up polish — not prematurely.
- **Transmute-with-Alchemy pairing is deliberate.** Both hammers operate on Normal items and represent "first touch" crafting. Grouping them in Row 1 signals that a player's starter loadout (2× Transmute + 2× Augment from v1.10) naturally progresses into Alchemy drops.

</specifics>

<deferred>
## Deferred Ideas

- **New icon art for Augment/Chaos/Exalt** — not happening in this milestone. Could be a visual polish phase later (maybe bundled with a "hammer icon refresh" that also updates the 6 existing PNGs).
- **Rename PNG asset files** to match class names (`forge_hammer.png` → `alchemy_hammer.png` etc.) — deferred per Phase 1 RESEARCH and made moot by D-03 (icons removed from UI). Could still happen later as a cleanup pass; low priority.
- **Stronger disabled visual state** (opacity or desaturation on zero-currency buttons) — revisit only if UAT flags it. Placeholder approach: modulate alpha ~0.4 on disabled or apply a grayscale shader.
- **Tag hammer 2-letter treatment** — would fully unify the sidebar visuals but changes tag hammer identity from "named section" to "just another row." Deferred; tag hammers read as a distinct subsystem today and that framing is valuable.
- **Visual group separators** (horizontal rule or label between rarity rows) — the empty cells already separate groups visually. Add only if UAT says the grouping isn't obvious enough.
- **Runtime UAT** of the 3 Phase 2 success criteria — not required because Phase 1 UAT (`01-HUMAN-UAT.md`, 7/7 pass) already validated the behavior through these exact buttons. Structural verification + one manual smoke check suffices per D-17/D-18.
- **Stash slot icons** (letter-icon display for stashed items — W for weapon, S for sword, etc.) — out of scope; that's stash UI, not forge hammer UI.

</deferred>

---

*Phase: 02-forge-ui*
*Context gathered: 2026-04-12*
