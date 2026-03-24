# Phase 50: Data Foundation - Context

**Gathered:** 2026-03-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Create the HeroArchetype Resource with all 9 hero definitions and wire up GameState/GameEvents infrastructure. No stat integration, no UI, no save format changes — just the data model and signals.

Requirements: HERO-01, HERO-02, HERO-03

</domain>

<decisions>
## Implementation Decisions

### Hero Identity Style
- **D-01:** Archetypal titles only, no proper names. Format: "The [Role]" (e.g., "The Berserker")
- **D-02:** Colors follow genre convention — STR red, DEX green, INT blue. All 3 subvariants within an archetype share the same color range.

### Draft Hero Roster

| ID | Archetype | Subvariant | Title | Color |
|----|-----------|-----------|-------|-------|
| str_hit | STR | Hit | The Berserker | Red |
| str_dot | STR | DoT | The Reaver | Red |
| str_elem | STR | Elemental | The Fire Knight | Red |
| dex_hit | DEX | Hit | The Assassin | Green |
| dex_dot | DEX | DoT | The Plague Hunter | Green |
| dex_elem | DEX | Elemental | The Frost Ranger | Green |
| int_hit | INT | Hit | The Arcanist | Blue |
| int_dot | INT | DoT | The Warlock | Blue |
| int_elem | INT | Elemental | The Storm Mage | Blue |

### Passive Bonus Schema
- **D-03:** Two-layer bonus system — archetype channel bonus + subvariant specialty bonus, both multiplicative "more" modifiers.
- **D-04:** Channel bonuses by archetype:
  - STR: `attack_damage_more: 0.25` (boosts attack channel)
  - INT: `spell_damage_more: 0.25` (boosts spell channel)
  - DEX: `damage_more: 0.15` (general, both channels, smaller to compensate for flexibility)
- **D-05:** Subvariant bonuses:
  - Hit: `physical_damage_more: 0.25`
  - DoT: `{type}_chance_more: 0.20, {type}_damage_more: 0.15` (STR=bleed, DEX=poison, INT=burn)
  - Elemental: `{element}_damage_more: 0.25` (STR=fire, DEX=cold, INT=lightning)
- **D-06:** All values are draft starting points — tuning happens in Phase 54.

### Spell User Authority
- **D-07:** INT heroes set `spell_user: true` on the archetype data. Hero archetype becomes the authority for spell mode, overriding weapon-driven logic. STR/DEX heroes are `spell_user: false`.
- **D-08:** The Arcanist (INT/hit) is a physical-spell fantasy — arcane force / gravity magic flavor.

### Element Mapping (Cross-Archetype)
- **D-09:** Elemental subvariant element assignments are deliberately cross-archetype:
  - STR elemental → fire
  - DEX elemental → cold
  - INT elemental → lightning

### Claude's Discretion
- Exact color hex values within the archetype color range
- Internal field naming conventions on the Resource
- Registry data structure (dict-of-dicts vs array with lookup)
- `generate_choices()` implementation details (random selection strategy)

</decisions>

<specifics>
## Specific Ideas

- INT hit (Arcanist) as "gravity spell" / arcane force flavor — physical damage through spells
- Titles should be concise and evocative, fitting idle game simplicity
- Bonus stacking: focused builds (matching hero + matching gear + matching tag hammers) should feel powerful

</specifics>

<canonical_refs>
## Canonical References

### Requirements
- `.planning/REQUIREMENTS.md` — HERO-01 (9 hero roster), HERO-02 (HeroArchetype Resource spec), HERO-03 (names/titles/colors)

### Research
- `.planning/research/SUMMARY.md` — Architecture approach, recommended stack, pitfall analysis
- `.planning/research/ARCHITECTURE.md` — Component breakdown, integration points
- `.planning/research/FEATURES.md` — Feature expectations, genre precedent
- `.planning/research/PITFALLS.md` — Critical risks (bonus scaling, DoT interaction, save migration)

### Existing Patterns
- `models/items/item.gd` — Resource pattern with static registry, `to_dict()`/`from_dict()` serialization
- `models/currencies/currency.gd` — Simple Resource subclass pattern
- `autoloads/game_events.gd` — Signal hub pattern
- `autoloads/game_state.gd` — Central state with nullable fields

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Resource` base class pattern: all data models (Item, Affix, Currency) extend Resource with serialization methods
- `Tag.StatType` enum: existing stat type system for affixes — hero bonus keys are deliberately separate strings to prevent mixing additive/multiplicative systems

### Established Patterns
- Static const registries: `Item.ITEM_TYPE_STRINGS`, `PrestigeManager.PRESTIGE_COSTS`, `PrestigeManager.ITEM_TIERS_BY_PRESTIGE` — data lives in code
- Factory methods: `Item.create_from_dict()` with match statement for type dispatch
- Signal pattern: one signal per event on GameEvents autoload, no parameters beyond what consumers need

### Integration Points
- `GameState.hero_archetype` — new nullable field, defaults null (classless Adventurer at P0)
- `GameEvents` — two new signals: `hero_selection_needed` (emitted post-prestige when archetype is null), `hero_selected(archetype: HeroArchetype)`
- `PrestigeManager.execute_prestige()` — downstream consumer: after wipe, checks if hero selection needed

</code_context>

<deferred>
## Deferred Ideas

- Stat integration (apply bonuses in Hero.update_stats()) — Phase 51
- Save format v8 with hero_archetype_id — Phase 52
- Selection UI (3-card overlay) — Phase 53
- Balance tuning of bonus magnitudes — Phase 54
- Prestige-level-gated hero pool — Future requirement
- Hero bonus scaling with prestige level — Future requirement

</deferred>

---

*Phase: 50-data-foundation*
*Context gathered: 2026-03-24*
