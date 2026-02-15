# Roadmap: Hammertime

## Milestones

- ✅ **v0.1 Code Cleanup & Architecture** — Phases 1-4 (shipped 2026-02-15)
- 🚧 **v1.0 Crafting Overhaul** — Phases 5-8 (in progress)

## Phases

<details>
<summary>✅ v0.1 Code Cleanup & Architecture (Phases 1-4) — SHIPPED 2026-02-15</summary>

- [x] Phase 1: Foundation (2/2 plans) — completed 2026-02-14
- [x] Phase 2: Data Model Migration (2/2 plans) — completed 2026-02-15
- [x] Phase 3: Unified Calculations (2/2 plans) — completed 2026-02-15
- [x] Phase 4: Signal-Based Communication (2/2 plans) — completed 2026-02-15

Full details: `.planning/milestones/v0.1-ROADMAP.md`

</details>

---

### Phase 5: Item Rarity System

**Goal:** Items have rarity tiers that control affix capacity

**Dependencies:** v0.1 complete (Resource-based Item model, unified calculations)

**Requirements:** RARITY-01, RARITY-02, RARITY-03, RARITY-04, RARITY-05

**Success Criteria:**
1. Every item has a rarity tier (Normal, Magic, or Rare) stored in its data model
2. Normal items prevent explicit mod addition (implicit-only items work)
3. Magic items enforce 1 prefix + 1 suffix maximum
4. Rare items enforce 3 prefix + 3 suffix maximum
5. Item display shows visual rarity distinction (white/blue/yellow)

**Plans:** 2 plans

Plans:
- [x] 05-01-PLAN.md -- Rarity data model and mod limit enforcement
- [x] 05-02-PLAN.md -- Rarity display colors and clean Normal drops

**Status:** ✓ Complete (2026-02-15)

---

### Phase 6: Currency Behaviors

**Goal:** Six hammer types modify items according to rarity rules

**Dependencies:** Phase 5 (rarity system must exist to validate against)

**Requirements:** CRAFT-01, CRAFT-02, CRAFT-03, CRAFT-04, CRAFT-05, CRAFT-06, CRAFT-07, CRAFT-08, CRAFT-09

**Success Criteria:**
1. Runic Hammer upgrades Normal to Magic with 1-2 random mods
2. Forge Hammer upgrades Normal to Rare with 4-6 random mods
3. Tack Hammer adds mod to Magic item respecting 1+1 limit
4. Grand Hammer adds mod to Rare item respecting 3+3 limit
5. Claw Hammer removes random mod without changing rarity
6. Tuning Hammer rerolls all mod values within tier ranges
7. Invalid uses (wrong rarity, mod limit reached) show error and prevent consumption

**Plans:** 2 plans

Plans:
- [x] 06-01-PLAN.md -- Base Currency Resource + Runic/Forge upgrade hammers
- [x] 06-02-PLAN.md -- Tack/Grand/Claw/Tuning modifier hammers

**Status:** ✓ Complete (2026-02-15)

---

### Phase 7: Drop Integration

**Goal:** Area difficulty influences rarity distribution in drops

**Dependencies:** Phase 5 (rarity system), Phase 6 (currency types to drop)

**Requirements:** DROP-01, DROP-02, DROP-03

**Success Criteria:**
1. Clearing Forest drops mostly Normal items with rare Magic
2. Clearing Shadow Realm drops mostly Rare items with some Magic
3. All 6 hammer types drop from area clearing with appropriate rates
4. Dropped items spawn with rarity-appropriate mod counts (Normal=0, Magic=1-2, Rare=4-6)

**Plans:** 2 plans

Plans:
- [x] 07-01-PLAN.md -- Rarity-weighted item drops (LootTable + gameplay integration)
- [x] 07-02-PLAN.md -- Currency drops from area clearing (6 hammer types)

**Status:** ✓ Complete (2026-02-15)

---

### Phase 8: UI Migration

**Goal:** Crafting UI uses 6 currency buttons replacing old 3-hammer system

**Dependencies:** Phase 6 (currency behaviors must exist to apply), Phase 7 (drops provide currencies)

**Requirements:** UI-01, UI-02, UI-03, UI-04

**Success Criteria:**
1. Crafting view displays 6 currency buttons (Runic, Forge, Tack, Grand, Claw, Tuning)
2. User can select currency, then click item to apply
3. Currency counts display correctly per hammer type
4. Old 3-hammer buttons and logic completely removed from codebase

**Status:** Pending

---

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v0.1 | 2/2 | ✓ Complete | 2026-02-14 |
| 2. Data Model Migration | v0.1 | 2/2 | ✓ Complete | 2026-02-15 |
| 3. Unified Calculations | v0.1 | 2/2 | ✓ Complete | 2026-02-15 |
| 4. Signal-Based Communication | v0.1 | 2/2 | ✓ Complete | 2026-02-15 |
| 5. Item Rarity System | v1.0 | 2/2 | ✓ Complete | 2026-02-15 |
| 6. Currency Behaviors | v1.0 | 2/2 | ✓ Complete | 2026-02-15 |
| 7. Drop Integration | v1.0 | 2/2 | ✓ Complete | 2026-02-15 |
| 8. UI Migration | v1.0 | 0/? | Pending | - |

---
*Roadmap created: 2026-02-14*
*Last updated: 2026-02-15 (Phase 7 complete: 2/2 plans)*
