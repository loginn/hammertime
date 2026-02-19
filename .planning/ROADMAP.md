# Roadmap: Hammertime

## Milestones

- ✅ **v0.1 Code Cleanup & Architecture** — Phases 1-4 (shipped 2026-02-15)
- ✅ **v1.0 Crafting Overhaul** — Phases 5-8 (shipped 2026-02-15)
- ✅ **v1.1 Content & Balance** — Phases 9-12 (shipped 2026-02-16)
- ✅ **v1.2 Pack-Based Mapping** — Phases 13-17 (shipped 2026-02-17)
- ✅ **v1.3 Save/Load & Polish** — Phases 18-22 (shipped 2026-02-18)
- ✅ **v1.4 Damage Ranges** — Phases 23-26 (shipped 2026-02-18)
- 🚧 **v1.5 Inventory Rework** — Phases 27-30 (in progress)

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

<details>
<summary>✅ v1.2 Pack-Based Mapping (Phases 13-17) — SHIPPED 2026-02-17</summary>

- [x] Phase 13: Defensive Stat Foundation (2/2 plans) — completed 2026-02-16
- [x] Phase 14: Monster Pack Data Model (2/2 plans) — completed 2026-02-16
- [x] Phase 15: Pack-Based Combat Loop (2/2 plans) — completed 2026-02-16
- [x] Phase 16: Drop System Split (2/2 plans) — completed 2026-02-17
- [x] Phase 17: UI and Combat Feedback (3/3 plans) — completed 2026-02-17

Full details: `.planning/milestones/v1.2-ROADMAP.md`

</details>

<details>
<summary>✅ v1.3 Save/Load & Polish (Phases 18-22) — SHIPPED 2026-02-18</summary>

- [x] Phase 18: Save/Load Foundation (2/2 plans) — completed 2026-02-17
- [x] Phase 19: Side-by-Side Layout (4/4 plans) — completed 2026-02-17
- [x] Phase 20: Crafting UX Enhancements (3/3 plans) — completed 2026-02-18
- [x] Phase 21: Save Import/Export (1/1 plan) — completed 2026-02-18
- [x] Phase 22: Balance & Polish (1/1 plan) — completed 2026-02-18

Full details: `.planning/milestones/v1.3-ROADMAP.md`

</details>

<details>
<summary>✅ v1.4 Damage Ranges (Phases 23-26) — SHIPPED 2026-02-18</summary>

- [x] Phase 23: Damage Range Data Model (2/2 plans) — completed 2026-02-18
- [x] Phase 24: Stat Calculation and Hero Range Caching (2/2 + 1 gap closure) — completed 2026-02-18
- [x] Phase 25: Per-Hit Combat Rolling (1/1 plan) — completed 2026-02-18
- [x] Phase 26: UI Range Display (2/2 plans) — completed 2026-02-18

Full details: `.planning/milestones/v1.4-ROADMAP.md`

</details>

### 🚧 v1.5 Inventory Rework (In Progress)

**Milestone Goal:** Replace single-item crafting slots with per-slot inventory arrays (10 items each), giving players a stash of bases to craft on and meaningful equip/melt decisions.

- [x] **Phase 27: Save Format Migration** - Bump save version to 2 and implement v1→v2 migration for per-slot arrays (completed 2026-02-18)
- [x] **Phase 28: GameState Data Model and Drop Flow** - Reshape crafting_inventory to arrays, enforce 10-item cap at drop (completed 2026-02-19)
- [ ] **Phase 29: ForgeView Logic** - Bench selection, melt, and equip against per-slot arrays
- [ ] **Phase 30: Display and Counter** - x/10 slot counter and guarded slot buttons in crafting view

## Phase Details

### Phase 27: Save Format Migration
**Goal**: Save/load correctly handles the v2 per-slot array format and migrates any existing v1 saves without data loss
**Depends on**: Phase 26 (v1.4 complete)
**Requirements**: SAVE-01
**Success Criteria** (what must be TRUE):
  1. Loading a hand-crafted v1 save produces per-slot arrays with the correct item count in each slot
  2. Loading a v2 save round-trips all items in all slots without loss or duplication
  3. The orphaned `crafting_bench_item` key is absent from both written saves and migrated saves
  4. A fresh game save (version 2) loads back to empty arrays for all five slots
**Plans**: 1 plan
- [ ] 27-01-PLAN.md — v2 save format with per-slot arrays, v1 migration, orphaned key removal

### Phase 28: GameState Data Model and Drop Flow
**Goal**: Items drop into per-slot inventory arrays with silent overflow discard enforced at a single add point
**Depends on**: Phase 27
**Requirements**: INV-01, INV-02
**Success Criteria** (what must be TRUE):
  1. Killing a pack that drops a weapon adds the weapon to the weapon slot array
  2. Dropping an 11th item into a full slot (10 items) is silently discarded — the slot remains at 10
  3. Starting a new game grants the starter weapon into the weapon slot array (not a null slot)
  4. The `crafting_bench_item` field is removed from GameState and no call site references it
**Plans**: 1 plan
- [ ] 28-01-PLAN.md — Reshape inventory to arrays, enforce 10-item cap, remove crafting_bench_item, complete SaveManager bridge

### Phase 29: ForgeView Logic
**Goal**: The crafting bench shows the highest-tier item from the selected slot, and melt and equip both correctly remove the item from the slot array
**Depends on**: Phase 28
**Requirements**: BENCH-01, BENCH-02, INV-03, EQUIP-01, EQUIP-02
**Success Criteria** (what must be TRUE):
  1. Clicking a slot button loads the highest-tier item (highest DPS for weapon/ring, highest tier for armor slots) onto the bench
  2. The bench item remains in the slot array while being crafted — hammers applied to it persist in the array
  3. Melting the bench item removes it from the slot array and loads the next-best item onto the bench
  4. Equipping the bench item moves it to the hero's equipment slot; the previously equipped item is deleted (not returned)
  5. Equip confirmation state resets when navigating to a different slot
**Plans**: TBD

### Phase 30: Display and Counter
**Goal**: Each slot button shows an accurate x/10 fill counter that updates on every inventory mutation
**Depends on**: Phase 29
**Requirements**: DISP-01
**Success Criteria** (what must be TRUE):
  1. Each slot button label shows "SlotName (N/10)" where N reflects the current array size
  2. The counter updates after a drop, a melt, and an equip without requiring a reload
  3. The counter does not update during currency-only pack kills (only on array mutations)
  4. A slot button with zero items is disabled; a slot with items is enabled
**Plans**: TBD

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
| 8. UI Migration | v1.0 | 1/1 | ✓ Complete | 2026-02-15 |
| 9. Defensive Prefix Foundation | v1.1 | 3/3 | ✓ Complete | 2026-02-16 |
| 10. Elemental Resistance Split | v1.1 | 1/1 | ✓ Complete | 2026-02-16 |
| 11. Currency Area Gating | v1.1 | 2/2 | ✓ Complete | 2026-02-16 |
| 12. Drop Rate Rebalancing | v1.1 | 1/1 | ✓ Complete | 2026-02-16 |
| 13. Defensive Stat Foundation | v1.2 | 2/2 | ✓ Complete | 2026-02-16 |
| 14. Monster Pack Data Model | v1.2 | 2/2 | ✓ Complete | 2026-02-16 |
| 15. Pack-Based Combat Loop | v1.2 | 2/2 | ✓ Complete | 2026-02-16 |
| 16. Drop System Split | v1.2 | 2/2 | ✓ Complete | 2026-02-17 |
| 17. UI and Combat Feedback | v1.2 | 3/3 | ✓ Complete | 2026-02-17 |
| 18. Save/Load Foundation | v1.3 | 2/2 | ✓ Complete | 2026-02-17 |
| 19. Side-by-Side Layout | v1.3 | 4/4 | ✓ Complete | 2026-02-17 |
| 20. Crafting UX Enhancements | v1.3 | 3/3 | ✓ Complete | 2026-02-18 |
| 21. Save Import/Export | v1.3 | 1/1 | ✓ Complete | 2026-02-18 |
| 22. Balance & Polish | v1.3 | 1/1 | ✓ Complete | 2026-02-18 |
| 23. Damage Range Data Model | v1.4 | 2/2 | ✓ Complete | 2026-02-18 |
| 24. Stat Calculation and Hero Range Caching | v1.4 | 2/2 + 1 gap | ✓ Complete | 2026-02-18 |
| 25. Per-Hit Combat Rolling | v1.4 | 1/1 | ✓ Complete | 2026-02-18 |
| 26. UI Range Display | v1.4 | 2/2 | ✓ Complete | 2026-02-18 |
| 27. Save Format Migration | 1/1 | Complete    | 2026-02-18 | - |
| 28. GameState Data Model and Drop Flow | 1/1 | Complete    | 2026-02-19 | - |
| 29. ForgeView Logic | v1.5 | 0/? | Not started | - |
| 30. Display and Counter | v1.5 | 0/? | Not started | - |

---
*Roadmap created: 2026-02-14*
*Last updated: 2026-02-18 — v1.5 Inventory Rework roadmap added (Phases 27-30)*
