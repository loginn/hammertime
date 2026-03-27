# Phase 54: Polish & Balance - Context

**Gathered:** 2026-03-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Display hero bonuses in ForgeView stat panel as a labeled section, verify all 9 heroes across damage channels, and lock current bonus magnitudes. No new test groups — existing Group 37-39 coverage is sufficient.

Requirements: PASS-03

</domain>

<decisions>
## Implementation Decisions

### Stat Panel Bonus Display
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

### Balance Tuning
- **D-06:** Current bonus magnitudes locked as-is. No adjustments in this phase:
  - Channel bonuses (attack_damage_more, spell_damage_more): 25%
  - General bonus (damage_more, DEX): 15%
  - Element bonuses (fire/cold/lightning/physical_damage_more): 25%
  - DoT chance bonuses (bleed/poison/burn_chance_more): 20%
  - DoT damage bonuses (bleed/poison/burn_damage_more): 15%
- **D-07:** Balance tuning deferred to a future balance pass based on playtesting.

### Verification
- **D-08:** No new integration test groups. Existing Group 37 (bonus math for all 9 heroes), Group 38 (save persistence), and Group 39 (selection UI) already satisfy the success criterion.
- **D-09:** Stat panel display verified by manual eyeball, not automated tests.
- **D-10:** Phase is complete when existing tests pass and stat panel visually shows correct hero bonuses.

### Claude's Discretion
- Exact font size for hero title vs passive lines (consistent with existing stat panel)
- Spacing between hero section and Offense section
- How to inject color into the RichTextLabel or Label (BBCode vs theme override)

</decisions>

<specifics>
## Specific Ideas

- The hero section should feel like a character sheet header — name at top, passives below, then your gear stats
- Use `HeroArchetype.format_bonuses()` directly — it already produces the right format from Phase 53
- Keep the "Passive:" label to distinguish hero bonuses from gear-derived stats

</specifics>

<canonical_refs>
## Canonical References

### Requirements
- `.planning/REQUIREMENTS.md` — PASS-03 (hero bonus visible as separate line in ForgeView stat panel)

### Prior Phase Context
- `.planning/phases/50-data-foundation/50-CONTEXT.md` — D-03 through D-06: bonus values, hero colors
- `.planning/phases/51-stat-integration/51-CONTEXT.md` — D-05 through D-09: bonus application order and math
- `.planning/phases/53-selection-ui/53-CONTEXT.md` — D-15/D-16: BONUS_LABELS and format_bonuses()

### Existing Code
- `scenes/forge_view.gd` — `update_hero_stats_display()` builds stat panel text (lines 657-746)
- `models/hero_archetype.gd` — REGISTRY, BONUS_LABELS, format_bonuses(), hero colors
- `autoloads/game_state.gd` — hero_archetype nullable field
- `tools/test/integration_test.gd` — Groups 37-39 cover hero bonus math, save, selection

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `HeroArchetype.format_bonuses()`: Returns `Array[String]` of formatted bonus lines — call directly for display
- `HeroArchetype.BONUS_LABELS`: Maps all 13 bonus keys to display strings
- `HeroArchetype.color` field: Per-hero color (red/green/blue) ready for title coloring

### Established Patterns
- `update_hero_stats_display()` builds stat text by appending to `hero_stats_label.text` — hero section prepends before existing Offense block
- Non-zero filtering: defense stats only show when > 0 — hero section uses null archetype check
- Font size 11 throughout ForgeView for 1280x720 viewport fit

### Integration Points
- `forge_view.gd update_hero_stats_display()` — prepend hero title + passive lines before "Offense:\n"
- `GameState.hero_archetype` — null check gates entire hero section
- `HeroArchetype.format_bonuses(archetype.passive_bonuses)` — produces display-ready strings

</code_context>

<deferred>
## Deferred Ideas

- Balance tuning of bonus magnitudes — future balance pass based on playtesting
- Prestige-level-gated hero pool (P1 basic, P3+ full roster) — future requirement
- Hero cosmetic effects — future scope

</deferred>

---

*Phase: 54-polish-balance*
*Context gathered: 2026-03-27*
