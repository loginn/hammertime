# Roadmap: Hammertime

## Milestones

- ✅ **v0.1 Code Cleanup & Architecture** — Phases 1-4 (shipped 2026-02-15)
- ✅ **v1.0 Crafting Overhaul** — Phases 5-8 (shipped 2026-02-15)
- ✅ **v1.1 Content & Balance** — Phases 9-12 (shipped 2026-02-16)
- ✅ **v1.2 Pack-Based Mapping** — Phases 13-17 (shipped 2026-02-17)
- 🚧 **v1.3 Save/Load & Polish** — Phases 18-22 (in progress)

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

### 🚧 v1.3 Save/Load & Polish (In Progress)

**Milestone Goal:** Persist full game state across sessions and fix UX pain points — side-by-side hero/crafting layout, item safety, stats overflow, crafting feedback, and level 1 balance.

- [ ] **Phase 18: Save/Load Foundation** - Implement core persistence with auto-save and version tracking
- [ ] **Phase 19: Side-by-Side Layout** - Restructure UI to show hero equipment and crafting simultaneously
- [ ] **Phase 20: Crafting UX Enhancements** - Add tooltips, stat comparison, per-type slots, and safety confirmations
- [ ] **Phase 21: Save Import/Export** - Enable save string export and import for backup/sharing
- [ ] **Phase 22: Balance & Polish** - Tune level 1 difficulty, add starter gear, fix stat overflow

## Phase Details

### Phase 18: Save/Load Foundation
**Goal**: Player game state persists across sessions with automatic saving and version tracking for future compatibility
**Depends on**: Nothing (first phase of v1.3)
**Requirements**: SAVE-01, SAVE-02, SAVE-03
**Success Criteria** (what must be TRUE):
  1. Player closes and reopens the game, their hero equipment, currencies, area progress, and crafting inventory are restored exactly as they were
  2. Game automatically saves every 5 minutes and after item crafting, area completion, or item equipping events
  3. Save file includes version number that supports future migration when game schema changes
  4. Loading a save from an earlier session restores hero stats and DPS calculations correctly
**Plans**: 2 plans

Plans:
- [ ] 18-01-PLAN.md — Core save/load infrastructure (serialization, SaveManager, state centralization)
- [ ] 18-02-PLAN.md — Auto-save, event triggers, toast UI, settings menu, startup flow

### Phase 19: Side-by-Side Layout
**Goal**: Hero equipment and crafting views display simultaneously so players can craft while viewing their gear
**Depends on**: Phase 18 (save/load buttons need integration with new navigation)
**Requirements**: LAYOUT-01, LAYOUT-02
**Success Criteria** (what must be TRUE):
  1. Hero equipment displays on the left half and crafting inventory displays on the right half of the same screen
  2. Player can view equipped gear and crafting inventory without switching tabs
  3. Gameplay/combat view remains a separate full-width screen toggled from the side-by-side view
  4. Layout fits within 1200x700 viewport with proper spacing and no overlapping elements
**Plans**: TBD

Plans:
- [ ] 19-01: TBD
- [ ] 19-02: TBD

### Phase 20: Crafting UX Enhancements
**Goal**: Crafting workflow provides clear feedback through tooltips, stat comparisons, dedicated slots, and safety confirmations
**Depends on**: Phase 19 (stat comparison panel positioning requires side-by-side layout dimensions)
**Requirements**: CRAFT-01, CRAFT-02, CRAFT-03, CRAFT-04
**Success Criteria** (what must be TRUE):
  1. Hovering any hammer button shows a tooltip describing what the hammer does and its rarity requirements
  2. Hovering an equipment slot with a craftable item available shows before/after stat comparison with color-coded deltas (DPS, armor, evasion, ES)
  3. Crafting view has separate item slots for weapon, helmet, armor, boots, and ring instead of one shared slot
  4. Finishing an item into an occupied slot requires two clicks (first click changes button to "Confirm Overwrite?", second click completes)
  5. Stat comparison shows item-level contribution differences, not total hero stat changes
**Plans**: TBD

Plans:
- [ ] 20-01: TBD
- [ ] 20-02: TBD

### Phase 21: Save Import/Export
**Goal**: Players can export their save as a string and import save strings to restore or share game state
**Depends on**: Phase 18 (builds on core save/load infrastructure)
**Requirements**: SAVE-04
**Success Criteria** (what must be TRUE):
  1. Player can click an "Export Save" button and receive a copyable save string representing their full game state
  2. Player can paste a save string into an "Import Save" field and restore that exact game state
  3. Save string export/import preserves all hero equipment, currencies, area progress, and crafting inventory
  4. Invalid save strings show clear error messages instead of corrupting game state
**Plans**: TBD

Plans:
- [ ] 21-01: TBD

### Phase 22: Balance & Polish
**Goal**: Fresh heroes can survive level 1 content and UI provides polished feedback
**Depends on**: Phases 18-20 (tuning requires stable systems)
**Requirements**: BAL-01, BAL-02, UI-01
**Success Criteria** (what must be TRUE):
  1. New game starts with 1 Runic Hammer and 1 weapon base item so player can craft their first weapon
  2. Fresh hero with tier 1 crafted weapon and armor survives at least 3 packs in level 1 area
  3. Level 1 monsters deal reduced damage and have reduced HP compared to previous balance (30-50% damage reduction)
  4. Hero View stat panels fit within viewport without scrolling or text overflow
  5. All stat labels are readable with properly sized text and whitespace
**Plans**: TBD

Plans:
- [ ] 22-01: TBD
- [ ] 22-02: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 18 → 19 → 20 → 21 → 22

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
| 18. Save/Load Foundation | v1.3 | 0/2 | Planned | - |
| 19. Side-by-Side Layout | v1.3 | 0/0 | Not started | - |
| 20. Crafting UX Enhancements | v1.3 | 0/0 | Not started | - |
| 21. Save Import/Export | v1.3 | 0/0 | Not started | - |
| 22. Balance & Polish | v1.3 | 0/0 | Not started | - |

---
*Roadmap created: 2026-02-14*
*Last updated: 2026-02-17 — v1.3 roadmap added*
