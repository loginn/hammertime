# Requirements: Hammertime

**Defined:** 2026-02-20
**Core Value:** The crafting loop must feel rewarding — finding items, using hammers to shape them, and equipping the result to push further into harder content.

## v1.7 Requirements

Requirements for Meta-Progression milestone. Each maps to roadmap phases.

### Prestige System

- [x] **PRES-01**: Player can prestige by spending required currency amounts (scaling per prestige level)
- [x] **PRES-02**: Prestige triggers full reset of area level, hero equipment, crafting inventory, and standard currencies
- [x] **PRES-03**: Prestige level and item tier unlocks persist across resets
- [ ] **PRES-04**: Player sees confirmation dialog showing cost, reward, and what resets before committing
- [x] **PRES-05**: Game supports 7 total prestige levels (P1 through P7)
- [x] **PRES-06**: Each prestige level unlocks the next better item tier (P1→tier 7, P2→tier 6, ..., P7→tier 1)

### Item Tier System

- [x] **TIER-01**: Items have an item_tier field (1-8) that gates which affix tiers can roll
- [x] **TIER-02**: Item tier drops are weighted by area level (higher areas favor better tiers within prestige-unlocked range)
- [x] **TIER-03**: Item tier constrains affix tier range during crafting (tier 8 = affix tiers 29-32, tier 7 = 25-32, etc.)

### Affix Tier Expansion

- [x] **AFFIX-01**: Affix tiers expand from 8 to 32 levels (4 affix tiers per item tier band)
- [x] **AFFIX-02**: Affix quality normalization helper enables correct cross-range tier comparison
### Tag-Targeted Currencies

- [ ] **TAG-01**: Fire Hammer transforms Normal item to Rare (like Forge Hammer), guaranteeing at least one fire-tagged affix
- [ ] **TAG-02**: Cold Hammer transforms Normal item to Rare (like Forge Hammer), guaranteeing at least one cold-tagged affix
- [ ] **TAG-03**: Lightning Hammer transforms Normal item to Rare (like Forge Hammer), guaranteeing at least one lightning-tagged affix
- [ ] **TAG-04**: Defense Hammer transforms Normal item to Rare (like Forge Hammer), guaranteeing at least one defense-tagged affix
- [ ] **TAG-05**: Physical Hammer transforms Normal item to Rare (like Forge Hammer), guaranteeing at least one physical-tagged affix
- [ ] **TAG-06**: Tag hammers show "no valid mods" feedback when no matching affixes are available
- [ ] **TAG-07**: Tag hammers are only available after Prestige 1
- [ ] **TAG-08**: Tag hammer currencies drop from packs after reaching Prestige 1

### Save & Persistence

- [x] **SAVE-01**: Save format v3 stores prestige level, item tier unlocks, and tag currency counts
- [x] **SAVE-02**: Prestige completion triggers auto-save

### Prestige UI

- [ ] **PUI-01**: Player can see their current prestige level at all times
- [ ] **PUI-02**: Player can see prestige cost and what the next prestige unlocks
- [ ] **PUI-03**: Player can see an unlock table showing all 7 prestige levels and their rewards
- [ ] **PUI-04**: Tag hammer buttons appear in crafting view after Prestige 1
- [ ] **PUI-05**: Prestige confirmation shows cost, reward, and complete reset list

## Future Requirements

Deferred to future milestones. Tracked but not in current roadmap.

### Hero Archetypes

- **HERO-01**: Player can choose from 3 hero archetypes (Melee, Ranged, Spell)
- **HERO-02**: Each archetype has distinct base stats and attack patterns
- **HERO-03**: Archetypes benefit from different mod affinities (spell damage, projectile mods, attack mods)

### Advanced Crafting Currencies

- **CRAFT-01**: Stat-targeted hammers add specific stat type affixes
- **CRAFT-02**: Outcome-locking hammers protect existing mods while rerolling others

### Loot Filtering

- **FILT-01**: Player can set item drop filters for unwanted loot

### Totem Progression

- **TOTEM-01**: Totem progression system (forge god shrine, slottable pieces, favor mechanic)

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| v2 save migration | User decision: breaking existing saves is acceptable |
| Stat-targeted hammers | Future prestige unlock (P2+) |
| Outcome-locking hammers | Future prestige unlock (P3+) |
| Hero archetypes | Future milestone — layer on prestige |
| Prestige-exclusive biome | Future milestone |
| Post-prestige drop rate bonus | Only if playtesting reveals need |
| Gear persisting through prestige | Defeats full-reset emotional arc |
| Partial prestige resets | Undermine psychological impact |
| Chaos-style full affix rerolls | Excluded by existing design |
| Visual item tier indicators in slot list | Mobile viewport constraint |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status  |
|-------------|-------|---------|
| PRES-01     | 35    | Complete |
| PRES-02     | 35    | Complete |
| PRES-03     | 35    | Complete |
| PRES-04     | 40    | Pending |
| PRES-05     | 35    | Complete |
| PRES-06     | 35    | Complete |
| TIER-01     | 38    | Complete |
| TIER-02     | 38    | Complete |
| TIER-03     | 38    | Complete |
| AFFIX-01    | 37    | Complete |
| AFFIX-02    | 37    | Complete |
| TAG-01      | 39    | Pending |
| TAG-02      | 39    | Pending |
| TAG-03      | 39    | Pending |
| TAG-04      | 39    | Pending |
| TAG-05      | 39    | Pending |
| TAG-06      | 39    | Pending |
| TAG-07      | 39    | Pending |
| TAG-08      | 39    | Pending |
| SAVE-01     | 36    | Complete |
| SAVE-02     | 36    | Complete |
| PUI-01      | 40    | Pending |
| PUI-02      | 40    | Pending |
| PUI-03      | 40    | Pending |
| PUI-04      | 40    | Pending |
| PUI-05      | 40    | Pending |

**Coverage:**
- v1.7 requirements: 23 total
- Mapped to phases: 23
- Unmapped: 0

---
*Requirements defined: 2026-02-20*
*Last updated: 2026-02-20 — traceability populated (phases 35-41)*
