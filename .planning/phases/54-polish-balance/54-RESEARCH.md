# Phase 54: Polish & Balance - Research

**Researched:** 2026-03-27
**Domain:** GDScript UI display — RichTextLabel BBCode coloring, stat panel text construction
**Confidence:** HIGH

## Summary

Phase 54 is a focused UI polish task with a single deliverable: inject a hero title + passive bonus block into `forge_view.gd`'s `update_hero_stats_display()` before the existing "Offense:" section. All supporting infrastructure already exists: `HeroArchetype.format_bonuses()`, `HeroArchetype.BONUS_LABELS`, per-hero `.color` fields, `GameState.hero_archetype` null-check, and a `RichTextLabel` that already accepts BBCode (proven by `[color=...]` usage in `format_stat_delta()`).

The balance decision is locked: all bonus magnitudes stay at current values (D-06, D-07). The verification decision is locked: no new integration tests, Groups 37-39 already cover the math (D-08). The only implementation work is the stat panel display and a manual eyeball pass.

**Primary recommendation:** Prepend a BBCode color-tagged hero title block to `hero_stats_label.text` at the top of the default-view branch in `update_hero_stats_display()`, guarded by `GameState.hero_archetype != null`.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Hero title + passive bonuses appear as a header block BEFORE the Offense section. Layout order: Hero title → Passive bonuses → Offense → Defense.
- **D-02:** Hero title line (e.g., "The Berserker") displayed in the hero's archetype color (red for STR, green for DEX, blue for INT). Bonus value lines stay white.
- **D-03:** Bonus lines use a "Passive:" section label with indented `format_bonuses()` output beneath:
  ```
  The Berserker
  Passive:
    +25% Attack Damage
    +25% Physical Damage

  Offense:
  ...
  ```
- **D-04:** Classless Adventurer (null archetype) shows no hero title or passive section — stat panel starts directly at Offense as it does today.
- **D-05:** During stat comparison mode (equip hover), the hero bonus section stays static — bonuses are gear-independent and don't need delta display.
- **D-06:** Current bonus magnitudes locked as-is. No adjustments in this phase:
  - Channel bonuses (attack_damage_more, spell_damage_more): 25%
  - General bonus (damage_more, DEX): 15%
  - Element bonuses (fire/cold/lightning/physical_damage_more): 25%
  - DoT chance bonuses (bleed/poison/burn_chance_more): 20%
  - DoT damage bonuses (bleed/poison/burn_damage_more): 15%
- **D-07:** Balance tuning deferred to a future balance pass based on playtesting.
- **D-08:** No new integration test groups. Existing Group 37 (bonus math for all 9 heroes), Group 38 (save persistence), and Group 39 (selection UI) already satisfy the success criterion.
- **D-09:** Stat panel display verified by manual eyeball, not automated tests.
- **D-10:** Phase is complete when existing tests pass and stat panel visually shows correct hero bonuses.

### Claude's Discretion
- Exact font size for hero title vs passive lines (consistent with existing stat panel)
- Spacing between hero section and Offense section
- How to inject color into the RichTextLabel or Label (BBCode vs theme override)

### Deferred Ideas (OUT OF SCOPE)
- Balance tuning of bonus magnitudes — future balance pass based on playtesting
- Prestige-level-gated hero pool (P1 basic, P3+ full roster) — future requirement
- Hero cosmetic effects — future scope
</user_constraints>

---

## Standard Stack

### Core (already present — no new dependencies)

| Asset | Location | Purpose | Status |
|-------|----------|---------|--------|
| `HeroArchetype` | `models/hero_archetype.gd` | REGISTRY, BONUS_LABELS, format_bonuses(), color per hero | Already implemented |
| `GameState.hero_archetype` | `autoloads/game_state.gd` | Nullable hero reference; null = Classless Adventurer | Already implemented |
| `forge_view.gd` | `scenes/forge_view.gd` | `update_hero_stats_display()` — target for modification | Already implemented |
| `hero_stats_label` | `$HeroStatsPanel/HeroStatsLabel` | `RichTextLabel` — already BBCode-capable | Already in scene |

**No new packages, no new files, no new autoloads required.**

### BBCode in RichTextLabel (Godot 4)

The `hero_stats_label` is already typed as `RichTextLabel` (line 33 of forge_view.gd). The existing `format_stat_delta()` function already uses `[color=#55ff55]...[/color]` BBCode successfully, confirming BBCode is enabled on this node.

**Approach for hero title coloring:** Embed the archetype color as a hex string in BBCode:

```gdscript
# Source: existing forge_view.gd format_stat_delta pattern (lines 754, 756)
var hex: String = archetype.color.to_html(false)
hero_stats_label.text += "[color=#%s]%s[/color]\n" % [hex, archetype.title]
```

`Color.to_html(false)` returns a 6-digit hex string without alpha — compatible with BBCode `[color=#RRGGBB]` syntax. (HIGH confidence — direct observation from codebase.)

## Architecture Patterns

### Target Function Structure

`update_hero_stats_display()` (forge_view.gd, lines 657-746) has three branches:
1. Equip hover active → `get_stat_comparison_text()` — return early (hero section unchanged per D-05)
2. Item type hover active → show equipped item — return early (no hero section needed)
3. **Default view** — this is the only branch requiring modification

The modification inserts a hero block at the top of branch 3, before line 690 (`hero_stats_label.text = "Hero Stats:\n\nOffense:\n"`).

### Recommended Implementation Pattern

```gdscript
# In update_hero_stats_display(), default view branch, BEFORE existing "Hero Stats:" line
var archetype: HeroArchetype = GameState.hero_archetype

# Initialize text — hero header or plain header
if archetype != null:
    var hex: String = archetype.color.to_html(false)
    hero_stats_label.text = "[color=#%s]%s[/color]\n" % [hex, archetype.title]
    hero_stats_label.text += "Passive:\n"
    for line in HeroArchetype.format_bonuses(archetype.passive_bonuses):
        hero_stats_label.text += "  %s\n" % line
    hero_stats_label.text += "\n"
else:
    hero_stats_label.text = ""

# Existing Offense block follows — replace old initialization line:
# OLD: hero_stats_label.text = "Hero Stats:\n\nOffense:\n"
hero_stats_label.text += "Offense:\n"
```

The "Hero Stats:\n\n" prefix from the old initialization becomes redundant once the hero block acts as a header. The Offense section label alone is sufficient context.

### What Does NOT Change

- Equip-hover branch: returns early before hero block — hero section naturally static per D-05
- Item-hover branch: returns early before hero block — no hero section shown in hover mode
- `hero_stats_label.modulate` reset to `Color.WHITE` at line 687 stays in place — BBCode color tags take precedence over modulate for the tagged text
- `format_bonuses()` is a static method — call as `HeroArchetype.format_bonuses(archetype.passive_bonuses)` without instance

### Anti-Patterns to Avoid

- **Using `modulate` for hero title color:** `hero_stats_label.modulate` tints the entire label. Already reset to WHITE at line 687. Use BBCode `[color=...]` per archetype.color instead.
- **Checking `archetype.archetype` enum for color:** The `.color` field is already the resolved `Color` per hero — don't re-derive from archetype enum.
- **Calling `format_bonuses()` as instance method:** It's `static func` — must call via `HeroArchetype.format_bonuses(...)`.
- **Omitting blank line between hero section and Offense:** The `\n` after passive lines provides visual breathing room matching D-03 layout spec.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Bonus label strings | Custom label map | `HeroArchetype.BONUS_LABELS` | Already maps all 13 keys; built in Phase 53 |
| Bonus line formatting | Custom `+%d%%` logic | `HeroArchetype.format_bonuses()` | Already rounds to int, prefixes `+`, handles all bonus types |
| Hero color lookup | Enum switch statement | `archetype.color` field | Resolved per-instance in `from_id()` |
| BBCode color string | Custom converter | `Color.to_html(false)` | Built-in Godot method, returns 6-digit hex |

## Common Pitfalls

### Pitfall 1: BBCode disabled on the node
**What goes wrong:** `[color=...]` tags appear as literal text instead of coloring.
**Why it happens:** `RichTextLabel` requires `bbcode_enabled = true` in the Inspector. Setting `.text` instead of `.bbcode_text` may bypass BBCode parsing depending on Godot version.
**How to avoid:** The existing codebase uses `.text` property with BBCode strings (lines 754-756 in `format_stat_delta`), and it works in production. This confirms BBCode is enabled on this node. No change needed.
**Warning signs:** If title shows as `[color=#C0392B]The Berserker[/color]` literally in the panel.

### Pitfall 2: `hero_stats_label.text = ...` clobbers the hero block
**What goes wrong:** The hero block is set, then overwritten by a later `hero_stats_label.text = "..."` assignment.
**Why it happens:** The existing code uses `hero_stats_label.text = "Hero Stats:\n\nOffense:\n"` as an initializer (line 690). If the hero block is added but this line is left unchanged, it erases the hero section.
**How to avoid:** Replace the initializer line with `hero_stats_label.text += "Offense:\n"` (append instead of assign) after the hero block is written. Or initialize `hero_stats_label.text = ""` before the hero block and make all subsequent writes `+=`.

### Pitfall 3: Forgetting `hero_stats_label.modulate` reset interaction
**What goes wrong:** The white modulate reset at line 687 is applied before the hero block, which is correct. But if the block is placed AFTER line 687 the modulate is still WHITE, which is fine — BBCode color overrides per-text, not per-modulate.
**Why it happens:** Confusion between modulate (whole-label tint) and BBCode color (per-text range).
**How to avoid:** Leave the modulate reset at line 687 in place. BBCode color inside the text string handles hero title color independently.

### Pitfall 4: Static method call syntax
**What goes wrong:** `archetype.format_bonuses(...)` raises a GDScript warning about calling a static method on an instance.
**Why it happens:** `format_bonuses` is declared `static func`.
**How to avoid:** Always call as `HeroArchetype.format_bonuses(archetype.passive_bonuses)`.

## Code Examples

### Hero block insertion (complete, verified against existing codebase)

```gdscript
# Source: forge_view.gd update_hero_stats_display() — default view branch
# Replace lines 683-690 with:

# Reset color to white for default view
hero_stats_label.modulate = Color.WHITE

# Hero section (null archetype = Classless Adventurer, no section shown)
var archetype: HeroArchetype = GameState.hero_archetype
if archetype != null:
    var hex: String = archetype.color.to_html(false)
    hero_stats_label.text = "[color=#%s]%s[/color]\n" % [hex, archetype.title]
    hero_stats_label.text += "Passive:\n"
    for line in HeroArchetype.format_bonuses(archetype.passive_bonuses):
        hero_stats_label.text += "  %s\n" % line
    hero_stats_label.text += "\n"
else:
    hero_stats_label.text = ""

# Offense section (was: hero_stats_label.text = "Hero Stats:\n\nOffense:\n")
hero_stats_label.text += "Offense:\n"
```

### Expected output for str_hit (The Berserker)

```
[deep red] The Berserker [/color]
Passive:
  +25% Attack Damage
  +25% Physical Damage

Offense:
Attack DPS: ...
...
```

### Expected output for null archetype (Classless Adventurer)

```
Offense:
Attack DPS: ...
...
```

### format_bonuses() output format (source: hero_archetype.gd line 144)

```gdscript
# static func format_bonuses(bonuses: Dictionary) -> Array[String]
# For {"attack_damage_more": 0.25, "physical_damage_more": 0.25}
# Returns: ["+25% Attack Damage", "+25% Physical Damage"]
```

## Validation Architecture

`workflow.nyquist_validation` is not set in config.json — treat as enabled.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Godot integration test (custom runner in `tools/test/integration_test.gd`) |
| Config file | None — run as standalone scene in Godot editor (F6) |
| Quick run command | Open `tools/test/integration_test.gd` as main scene, press F6, read console output |
| Full suite command | Same — all 39 groups run sequentially in `_ready()` |

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Automated Command | Coverage |
|--------|----------|-----------|-------------------|----------|
| PASS-03 | Hero bonus visible in ForgeView stat panel | Manual visual | N/A — D-09: eyeball verification | Not automated |
| PASS-03 (math) | Hero bonuses applied correctly | Automated | Run integration_test.gd — Group 37 | Already exists (Group 37) |
| PASS-03 (null) | Classless Adventurer shows no hero section | Manual visual | N/A | Eyeball during dev |

### Sampling Rate

- **Per task commit:** Run integration_test.gd (F6), confirm Groups 37-39 all pass
- **Phase gate:** Groups 37-39 green + manual eyeball of stat panel for 2-3 heroes before `/gsd:verify-work`

### Wave 0 Gaps

None — existing test infrastructure (Groups 37-39) covers all phase requirements. No new test files needed per D-08.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| No hero section in stat panel | Hero title + passive block before Offense | Phase 54 (this phase) | PASS-03 satisfied |
| `hero_stats_label.text = "Hero Stats:\n\nOffense:\n"` | Conditional hero block + `+= "Offense:\n"` | Phase 54 | Classless shows clean Offense header |

## Open Questions

1. **"Hero Stats:" label removal**
   - What we know: Current code initializes with `"Hero Stats:\n\nOffense:\n"`. The hero title block (e.g., "The Berserker") makes "Hero Stats:" redundant.
   - What's unclear: Whether to keep "Hero Stats:" for classless (null archetype) or drop it entirely.
   - Recommendation: Drop "Hero Stats:" entirely — the section headers "Offense:" and "Defense:" are self-explanatory, and classless Adventurer needs no panel header. Consistent with the character-sheet feel described in CONTEXT.md specifics. Claude's discretion.

2. **Spacing between passive lines and Offense header**
   - What we know: D-03 shows a blank line between the passive block and "Offense:". The `\n` after the last passive line achieves this.
   - What's unclear: Whether two newlines look better than one in the 1280x720 viewport.
   - Recommendation: Single blank line (`\n` after passive block before `Offense:\n`). Adjust by eyeball during manual verification.

## Sources

### Primary (HIGH confidence)
- `scenes/forge_view.gd` lines 33, 657-746, 748-757 — direct code inspection; `hero_stats_label` type, `update_hero_stats_display()` structure, BBCode usage in `format_stat_delta()`
- `models/hero_archetype.gd` lines 1-178 — full file; REGISTRY, BONUS_LABELS, `format_bonuses()`, `from_id()`, all 9 heroes with colors and bonuses
- `tools/test/integration_test.gd` lines 1710-1916 — Group 37 full text; confirms all 9 hero math already tested
- `.planning/phases/54-polish-balance/54-CONTEXT.md` — all decisions D-01 through D-10

### Secondary (MEDIUM confidence)
- `.planning/REQUIREMENTS.md` — PASS-03 requirement traceability
- `.planning/STATE.md` — project architecture and phase history

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all assets are existing, inspected directly in codebase
- Architecture: HIGH — insertion point is precisely identified (forge_view.gd line 690), pattern is derived from existing BBCode usage in the same file
- Pitfalls: HIGH — derived from direct code inspection, not speculation
- Validation: HIGH — test groups 37-39 confirmed to exist and cover hero bonus math

**Research date:** 2026-03-27
**Valid until:** Stable — no external dependencies, all findings from project source code
