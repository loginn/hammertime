# Phase 51: Stat Integration - Context

**Gathered:** 2026-03-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire archetype passive bonuses into Hero.update_stats() as multiplicative "more" modifiers applied after equipment aggregation. Remove the is_spell_user toggle and derive spell mode from archetype. No UI changes, no save format changes, no balance tuning.

Requirements: PASS-01, PASS-02

</domain>

<decisions>
## Implementation Decisions

### is_spell_user Transition
- **D-01:** Remove the settings_view.gd spell mode toggle entirely. No manual override exists.
- **D-02:** `is_spell_user` is derived from archetype at runtime: if `hero_archetype != null`, `is_spell_user = hero_archetype.spell_user`. If null (classless Adventurer), `is_spell_user = false` always.
- **D-03:** Classless Adventurer (P0, no archetype) is always attack mode. Spell weapons still calculate spell stats but CombatEngine never starts spell timer for classless.
- **D-04:** Save format: stop writing `is_spell_user` to save data. On load, derive from archetype if present; if no archetype, default to false. Backward-compat: old saves with `is_spell_user` field are ignored (value derived, not restored). Full save format cleanup deferred to Phase 52.

### "More" Modifier Application Point
- **D-05:** Element-specific bonuses (e.g., `fire_damage_more: 0.25`) apply per-element to damage_ranges min/max AFTER equipment aggregation in `calculate_damage_ranges()` and `calculate_spell_damage_ranges()`. This means fire_damage_more scales fire hits AND fire DoT base damage.
- **D-06:** Channel bonuses (`attack_damage_more`, `spell_damage_more`) apply to ALL elements in their respective range dictionaries after equipment aggregation.
- **D-07:** DEX's `damage_more` (general) applies to BOTH attack damage_ranges AND spell_damage_ranges. Semantically correct even though DEX heroes don't use spells.
- **D-08:** DoT bonuses (`bleed_chance_more`, `bleed_damage_more`, etc.) apply multiplicatively on final totals after affix aggregation in `calculate_dot_stats()`. Chance bonuses multiply total_X_chance; damage bonuses add to total_X_damage_pct (converted to percentage).
- **D-09:** `physical_damage_more` (Hit subvariant bonus) applies to the "physical" element in damage_ranges, same as element-specific bonuses.

### Classless Adventurer Behavior
- **D-10:** When `GameState.hero_archetype == null`, skip all bonus application silently. Single null check, no logging, no placeholder values.
- **D-11:** No UI changes in Phase 51. Stats change numerically when archetype is set, but no labels, tooltips, or indicators. All UI deferred to Phase 53.

### Claude's Discretion
- Exact placement of bonus application code within each calculate_* function (inline vs helper)
- Whether to cache the passive_bonuses dictionary or read from GameState.hero_archetype each call
- Integration test structure for verifying bonus math

</decisions>

<specifics>
## Specific Ideas

- Focused builds (matching hero + matching gear + matching tag hammers) should feel multiplicatively powerful — the "more" system stacks on top of additive equipment
- The Arcanist (INT/hit) gets physical_damage_more applied to spell damage ranges (physical element), reinforcing the "arcane force" fantasy
- CombatEngine should require zero changes — it reads pre-computed damage ranges that already include bonuses

</specifics>

<canonical_refs>
## Canonical References

### Requirements
- `.planning/REQUIREMENTS.md` — PASS-01 (passive bonus application), PASS-02 (bonus stacking rules)

### Prior Phase Context
- `.planning/phases/50-data-foundation/50-CONTEXT.md` — D-03 through D-09: bonus values, two-layer system, spell_user authority, element mappings
- `.planning/phases/50-data-foundation/50-RESEARCH.md` — Architecture analysis, registry structure, integration points

### Research
- `.planning/research/SUMMARY.md` — Architecture approach, bonus system design
- `.planning/research/PITFALLS.md` — Pitfall 7: is_spell_user conflict resolution, bonus scaling risks

### Existing Patterns
- `models/hero.gd` — update_stats() pipeline: crit → ranges → spell ranges → DPS → spell DPS → defense → DoT
- `models/hero_archetype.gd` — REGISTRY with passive_bonuses dictionaries, from_id(), generate_choices()
- `autoloads/game_state.gd` — hero_archetype nullable field
- `scenes/settings_view.gd` — Current spell mode toggle (to be removed)
- `autoloads/save_manager.gd` — is_spell_user save/load (to be changed)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `HeroArchetype.passive_bonuses` dictionary: keys like `attack_damage_more`, `fire_damage_more`, `bleed_chance_more` — ready to iterate
- `GameState.hero_archetype` nullable field: already wired from Phase 50
- `StatCalculator.calculate_damage_range()` / `calculate_spell_damage_range()`: return per-element dictionaries that bonus application can post-process

### Established Patterns
- `update_stats()` order: `calculate_crit_stats() → calculate_damage_ranges() → calculate_spell_damage_ranges() → calculate_dps() → calculate_spell_dps() → calculate_defense() → calculate_dot_stats()` — bonuses inject at end of ranges and dot_stats functions
- Per-element dictionary iteration: `for element in damage_ranges:` pattern already used in DPS calculation
- DoT stat aggregation: `total_bleed_chance`, `total_bleed_damage_pct` etc. are summed from affixes then used in `calculate_dot_dps()` — bonus multiplication goes between aggregation and DPS calc

### Integration Points
- `Hero.calculate_damage_ranges()` — append bonus multiplication after weapon+ring loop
- `Hero.calculate_spell_damage_ranges()` — same pattern for spell channel
- `Hero.calculate_dot_stats()` — multiply chance/damage totals before `calculate_dot_dps()` call
- `Hero.is_spell_user` — change from stored property to derived getter
- `scenes/settings_view.gd` — remove spell mode toggle UI and signal handler
- `autoloads/save_manager.gd` — stop writing is_spell_user, keep reading for backward compat

</code_context>

<deferred>
## Deferred Ideas

- Save format v8 with hero_archetype_id — Phase 52
- Hero name/title display in UI — Phase 53
- Bonus magnitude indicators in stat panel — Phase 53
- Balance tuning of bonus values — Phase 54
- Prestige-level-gated hero pool — Future requirement

</deferred>

---

*Phase: 51-stat-integration*
*Context gathered: 2026-03-25*
