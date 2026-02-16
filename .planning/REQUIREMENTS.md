# Requirements: Hammertime

**Defined:** 2026-02-16
**Core Value:** The crafting loop must feel rewarding — finding items, using hammers to shape them, and equipping the result to push further into harder content.

## v1.2 Requirements

Requirements for pack-based mapping milestone. Each maps to roadmap phases.

### Monster Packs

- [ ] **PACK-01**: Monster packs have HP, damage, and elemental damage type (physical/fire/cold/lightning)
- [ ] **PACK-02**: Maps contain a random number of packs within a range per biome
- [ ] **PACK-03**: Biomes have damage type distributions (Forest = mostly physical, Shadow Realm = mostly elemental)
- [ ] **PACK-04**: Pack HP and damage scale with area level

### Combat

- [ ] **COMBAT-01**: Hero fights monster packs sequentially in idle auto-combat
- [ ] **COMBAT-02**: Hero attacks pack and pack attacks hero back each combat tick
- [ ] **COMBAT-03**: Hero can die (HP reaches 0) ending the current map run
- [ ] **COMBAT-04**: Death loses map progress but keeps currency earned from killed packs
- [ ] **COMBAT-05**: Hero revives and can start a new map after death
- [ ] **COMBAT-06**: Completing all packs in a map advances to the next map

### Defense

- [ ] **DEF-01**: Armor reduces physical damage using diminishing returns formula
- [ ] **DEF-02**: Evasion provides dodge chance with diminishing returns (capped at 75%)
- [ ] **DEF-03**: Elemental resistances reduce elemental damage (capped at 75%)
- [ ] **DEF-04**: Energy shield acts as buffer HP (absorbs damage before life)
- [ ] **DEF-05**: Energy shield recharges a percentage of total ES between pack fights

### Drops

- [ ] **DROP-01**: Monster packs drop currency when killed
- [ ] **DROP-02**: Map completion drops items
- [ ] **DROP-03**: Currency earned from packs is kept on hero death

### UI

- [ ] **UI-01**: Gameplay view shows pack-based combat instead of time-based clearing
- [ ] **UI-02**: Pack HP and hero HP visible during combat
- [ ] **UI-03**: Pack progress shown (e.g., "3/7 packs cleared")

## Future Requirements

Deferred to future release. Tracked but not in current roadmap.

### Totem System

- **TOTEM-01**: Totem pieces drop from packs and maps
- **TOTEM-02**: Totem has slots for pieces with effects on maps
- **TOTEM-03**: Totem pieces improve loot but make packs stronger (risk/reward)
- **TOTEM-04**: Favor accumulates from killing packs
- **TOTEM-05**: Activate totem in burst early game, sustain endgame

### Combat Polish

- **POLISH-01**: Energy shield recharge rate modifiers via affixes
- **POLISH-02**: Evasion entropy system (pseudo-random, prevent streaks)
- **POLISH-03**: Elemental status effects (fire ignites, cold chills, lightning shocks)
- **POLISH-04**: Elemental damage preview before entering biome
- **POLISH-05**: Visible damage breakdown in combat log

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Real-time combat with player timing | Fundamentally conflicts with idle genre |
| Per-monster loot drops | Item explosion in idle game = inventory nightmare |
| 100% damage immunity | Removes challenge; 75% resistance cap is ARPG standard |
| Complex elemental interactions (fire melts ice, etc.) | Massive complexity for questionable value |
| Revive/retry mechanic with penalty | Encourages "throw bodies at it" gameplay |
| Totem system | Deferred to v1.3+ — builds on pack-based mapping |
| Save/load system | Not yet scoped |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| PACK-01 | Phase 14 | Pending |
| PACK-02 | Phase 14 | Pending |
| PACK-03 | Phase 14 | Pending |
| PACK-04 | Phase 14 | Pending |
| COMBAT-01 | Phase 15 | Pending |
| COMBAT-02 | Phase 15 | Pending |
| COMBAT-03 | Phase 15 | Pending |
| COMBAT-04 | Phase 16 | Pending |
| COMBAT-05 | Phase 15 | Pending |
| COMBAT-06 | Phase 15 | Pending |
| DEF-01 | Phase 13 | Pending |
| DEF-02 | Phase 13 | Pending |
| DEF-03 | Phase 13 | Pending |
| DEF-04 | Phase 13 | Pending |
| DEF-05 | Phase 13 | Pending |
| DROP-01 | Phase 16 | Pending |
| DROP-02 | Phase 16 | Pending |
| DROP-03 | Phase 16 | Pending |
| UI-01 | Phase 17 | Pending |
| UI-02 | Phase 17 | Pending |
| UI-03 | Phase 17 | Pending |

**Coverage:**
- v1.2 requirements: 21 total
- Mapped to phases: 21
- Unmapped: 0

**Coverage validation:** 100% ✓

---
*Requirements defined: 2026-02-16*
*Last updated: 2026-02-16 after roadmap creation*
