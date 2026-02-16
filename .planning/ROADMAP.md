# Roadmap: Hammertime

## Milestones

- ✅ **v0.1 Code Cleanup & Architecture** — Phases 1-4 (shipped 2026-02-15)
- ✅ **v1.0 Crafting Overhaul** — Phases 5-8 (shipped 2026-02-15)
- ✅ **v1.1 Content & Balance** — Phases 9-12 (shipped 2026-02-16)
- 🚧 **v1.2 Pack-Based Mapping** — Phases 13-17 (in progress)

## Phases

<details>
<summary>✅ v0.1 Code Cleanup & Architecture (Phases 1-4) — SHIPPED 2026-02-15</summary>

- [x] Phase 1: Foundation (2/2 plans) — completed 2026-02-14
- [x] Phase 2: Data Model Migration (2/2 plans) — completed 2026-02-15
- [x] Phase 3: Unified Calculations (2/2 plans) — completed 2026-02-15
- [x] Phase 4: Signal-Based Communication (2/2 plans) — completed 2026-02-15

Full details: `.planning/milestones/v0.1-ROADMAP.md`

</details>

<details>
<summary>✅ v1.0 Crafting Overhaul (Phases 5-8) — SHIPPED 2026-02-15</summary>

- [x] Phase 5: Item Rarity System (2/2 plans) — completed 2026-02-15
- [x] Phase 6: Currency Behaviors (2/2 plans) — completed 2026-02-15
- [x] Phase 7: Drop Integration (2/2 plans) — completed 2026-02-15
- [x] Phase 8: UI Migration (1/1 plan) — completed 2026-02-15

Full details: `.planning/milestones/v1.0-ROADMAP.md`

</details>

<details>
<summary>✅ v1.1 Content & Balance (Phases 9-12) — SHIPPED 2026-02-16</summary>

- [x] Phase 9: Defensive Prefix Foundation (3/3 plans) — completed 2026-02-16
- [x] Phase 10: Elemental Resistance Split (1/1 plan) — completed 2026-02-16
- [x] Phase 11: Currency Area Gating (2/2 plans) — completed 2026-02-16
- [x] Phase 12: Drop Rate Rebalancing (1/1 plan) — completed 2026-02-16

Full details: `.planning/milestones/v1.1-ROADMAP.md`

</details>

### 🚧 v1.2 Pack-Based Mapping (In Progress)

**Milestone Goal:** Replace time-based area clearing with pack-based map runs, adding real combat stakes and defensive stat integration.

**Phase Numbering:**
- Integer phases (13-17): Planned milestone work
- Decimal phases (13.1, 13.2): Urgent insertions (marked with INSERTED)

- [x] **Phase 13: Defensive Stat Foundation** - Armor, evasion, resistance, and energy shield calculations (completed 2026-02-16)
- [ ] **Phase 14: Monster Pack Data Model** - Pack Resources with HP, damage, elemental types
- [ ] **Phase 15: Pack-Based Combat Loop** - Sequential idle auto-combat with death mechanics
- [ ] **Phase 16: Drop System Split** - Packs drop currency, maps drop items
- [ ] **Phase 17: UI and Combat Feedback** - Combat state display and pack progress

## Phase Details

### Phase 13: Defensive Stat Foundation
**Goal**: Defensive stats (armor, evasion, resistances, energy shield) reduce incoming damage through proven ARPG formulas
**Depends on**: Phase 12 (v1.1 complete)
**Requirements**: DEF-01, DEF-02, DEF-03, DEF-04, DEF-05
**Success Criteria** (what must be TRUE):
  1. Hero with armor takes less physical damage than hero without armor
  2. Hero with evasion has a chance to dodge attacks (visible in combat feedback)
  3. Hero with elemental resistances takes less fire/cold/lightning damage (capped at 75%)
  4. Hero with energy shield absorbs damage to ES before losing life HP
  5. Hero's energy shield recharges a percentage of total ES between pack fights
**Plans**: 2 plans

Plans:
- [ ] 13-01-PLAN.md — DefenseCalculator + Hero ES tracking
- [ ] 13-02-PLAN.md — Wire defense into gameplay loop + ES display

### Phase 14: Monster Pack Data Model
**Goal**: Monster packs exist as Resources with HP, damage, and elemental damage types that scale with area level
**Depends on**: Phase 13
**Requirements**: PACK-01, PACK-02, PACK-03, PACK-04
**Success Criteria** (what must be TRUE):
  1. Maps contain a random number of packs within a configured range per biome
  2. Packs have HP pools that scale with area level (higher areas = tougher packs)
  3. Packs deal damage that scales with area level (higher areas = harder hits)
  4. Forest biome packs deal mostly physical damage while Shadow Realm packs deal mostly elemental damage
  5. Each pack has a specific elemental damage type (physical/fire/cold/lightning)
**Plans**: 2 plans

Plans:
- [ ] 14-01-PLAN.md — MonsterType, MonsterPack, BiomeConfig Resources
- [ ] 14-02-PLAN.md — PackGenerator with scaling and element selection

### Phase 15: Pack-Based Combat Loop
**Goal**: Hero fights monster packs sequentially in idle auto-combat where both hero and packs can die
**Depends on**: Phase 14
**Requirements**: COMBAT-01, COMBAT-02, COMBAT-03, COMBAT-05, COMBAT-06
**Success Criteria** (what must be TRUE):
  1. Hero automatically attacks the current pack and pack attacks hero back each combat tick
  2. When pack HP reaches 0, hero moves to the next pack
  3. When hero HP reaches 0, combat stops and hero is marked as dead
  4. After hero dies, hero can revive and start a new map run
  5. When all packs in a map are cleared, hero advances to the next map
**Plans**: TBD

Plans:
- [ ] 15-01: TBD

### Phase 16: Drop System Split
**Goal**: Packs drop currency when killed, map completion drops items, death keeps currency earned
**Depends on**: Phase 15
**Requirements**: DROP-01, DROP-02, DROP-03, COMBAT-04
**Success Criteria** (what must be TRUE):
  1. Each pack killed adds currency to hero's inventory immediately
  2. Map completion (all packs cleared) awards item drops
  3. Hero death ends the current map without item drops but keeps all currency earned from killed packs
  4. Currency earned from partial progress is visible and preserved through death
**Plans**: TBD

Plans:
- [ ] 16-01: TBD

### Phase 17: UI and Combat Feedback
**Goal**: Players can observe pack-based combat state, HP changes, and progression through the map
**Depends on**: Phase 16
**Requirements**: UI-01, UI-02, UI-03
**Success Criteria** (what must be TRUE):
  1. Gameplay view displays pack-based combat instead of time-based progress bar
  2. Current pack HP and hero HP are visible and update during combat
  3. Pack progress is shown clearly (e.g., "Pack 3 of 7 cleared")
  4. Combat state changes are visible (fighting, pack transition, death, map complete)
**Plans**: TBD

Plans:
- [ ] 17-01: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 13 → 14 → 15 → 16 → 17

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v0.1 | 2/2 | ✓ Complete | 2026-02-14 |
| 2. Data Model Migration | v0.1 | 2/2 | ✓ Complete | 2026-02-15 |
| 3. Unified Calculations | v0.1 | 2/2 | ✓ Complete | 2026-02-15 |
| 4. Signal-Based Communication | v0.1 | 2/2 | ✓ Complete | 2026-02-15 |
| 5. Item Rarity System | v1.0 | 2/2 | ✓ Complete | 2026-02-15 |
| 6. Currency Behaviors | v1.0 | 2/2 | ✓ Complete | 2026-02-15 |
| 7. Drop Integration | v1.0 | 2/2 | ✓ Complete | 2026-02-15 |
| 8. UI Migration | v1.0 | 1/1 | ✓ Complete | 2026-02-15 |
| 9. Defensive Prefix Foundation | v1.1 | 3/3 | ✓ Complete | 2026-02-16 |
| 10. Elemental Resistance Split | v1.1 | 1/1 | ✓ Complete | 2026-02-16 |
| 11. Currency Area Gating | v1.1 | 2/2 | ✓ Complete | 2026-02-16 |
| 12. Drop Rate Rebalancing | v1.1 | 1/1 | ✓ Complete | 2026-02-16 |
| 13. Defensive Stat Foundation | v1.2 | Complete    | 2026-02-16 | - |
| 14. Monster Pack Data Model | v1.2 | 0/2 | Planned | - |
| 15. Pack-Based Combat Loop | v1.2 | 0/? | Not started | - |
| 16. Drop System Split | v1.2 | 0/? | Not started | - |
| 17. UI and Combat Feedback | v1.2 | 0/? | Not started | - |

---
*Roadmap created: 2026-02-14*
*Last updated: 2026-02-16 (v1.2 milestone roadmap created)*
