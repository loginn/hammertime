# Requirements: v1.9 Heroes

## v1.9 Requirements

### Hero Data & Identity
- [x] **HERO-01**: 9 hero roster — 3 archetypes (STR/DEX/INT) × 3 subvariants each (hit, DoT, elemental)
- [x] **HERO-02**: HeroArchetype Resource with id, archetype, name, passive_bonuses dict, const registry in code
- [x] **HERO-03**: Each hero has a proper name and title (e.g., "Fiona, Fire Sorceress") with color identity

### Passive Bonus System
- [x] **PASS-01**: Multiplicative "more" bonuses applied after gear stacking in Hero.update_stats()
- [x] **PASS-02**: DoT subvariant heroes get +20% bleed/poison/burn chance bonus to bootstrap viability
- [x] **PASS-03**: Hero bonus visible as separate line in ForgeView stat panel

### Prestige Selection
- [x] **SEL-01**: 3-card draft on prestige — 1 STR, 1 DEX, 1 INT drawn randomly, pick one
- [x] **SEL-02**: P0 plays as classless Adventurer (no hero, no passive). First selection at P1
- [x] **SEL-03**: Selection overlay UI blocks gameplay post-prestige until hero is picked (1280x720)

### Save & Persistence
- [x] **SAVE-01**: Save format v8 with hero_archetype_id. Old saves trigger new game (breaking change)

## Future Requirements

- Prestige-level-gated hero pool (P1 basic, P3+ full roster)
- Hero bonus scaling with prestige level
- Defensive hero variants
- Dual-bonus heroes
- Hero-specific item affixes
- Ascendancy trees
- Hero cosmetic effects
- Hero-weighted item drops

## Out of Scope

- Skill trees per hero — scope explosion, contradicts idle simplicity
- Active abilities — contradicts idle auto-combat
- Hero-exclusive items — restricts existing 21-base pool
- Permanent hero progression across prestiges — destroys prestige tension
- Additive hero bonuses — scale poorly in idle exponential context

## Traceability

| REQ-ID | Phase | Plan | Status |
|--------|-------|------|--------|
| HERO-01 | 50 | — | not started |
| HERO-02 | 50 | — | not started |
| HERO-03 | 50 | — | not started |
| PASS-01 | 51 | — | not started |
| PASS-02 | 51 | — | not started |
| PASS-03 | 54 | — | not started |
| SEL-01 | 53 | — | not started |
| SEL-02 | 53 | — | not started |
| SEL-03 | 53 | — | not started |
| SAVE-01 | 52 | — | not started |

---
*Requirements defined: 2026-03-09*
*Milestone: v1.9 Heroes*
