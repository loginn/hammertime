# Roadmap: v1.11 Fix Hammers

## Overview

Three phases deliver the complete PoE currency hammer set. Phase 1 corrects the three broken hammer behaviors and adds the three missing currencies — all model logic. Phase 2 updates the forge UI to expose all 8 base hammers with correct tooltips. Phase 3 wires everything into the game: drop tables, save format, and integration tests.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Hammer Models** - Fix 3 mismatched hammer behaviors and add 3 new currency models (completed 2026-04-11)
- [ ] **Phase 2: Forge UI** - Expose all 8 base hammers with correct tooltips in forge view
- [ ] **Phase 3: Integration** - Wire drop table, save format, and integration tests

## Phase Details

### Phase 1: Hammer Models
**Goal**: All 8 base hammer currency models behave exactly as a PoE player expects
**Depends on**: Nothing (first phase)
**Requirements**: FIX-01, FIX-02, FIX-03, NEW-01, NEW-02, NEW-03
**Success Criteria** (what must be TRUE):
  1. Augment Hammer adds 1 mod to a Magic item that has room and rejects items that are full
  2. Chaos Hammer rerolls all mods on a Rare item with 4-6 new random mods
  3. Exalt Hammer adds 1 mod to a Rare item that has room and rejects full Rare items
  4. Alchemy Hammer converts a Normal item to Rare with 4-6 random mods
  5. Divine Hammer rerolls mod values within their tier ranges without changing which mods are present
  6. Annulment Hammer removes 1 random mod from a Magic or Rare item
**Plans**: 2 plans
- [x] 01-01-PLAN.md — Rename 3 existing mislabeled currency classes (ForgeHammer→AlchemyHammer, TuningHammer→DivineHammer, ClawHammer→AnnulmentHammer) and rewire forge_view.gd + scene tree nodes + live-doc references [NEW-01, NEW-02, NEW-03]
- [x] 01-02-PLAN.md — Create 3 new currency classes (AugmentHammer, ChaosHammer, ExaltHammer) and repoint augment/chaos/exalt keys in forge_view.gd currencies dict [FIX-01, FIX-02, FIX-03]

### Phase 2: Forge UI
**Goal**: The forge view shows all 8 base hammer buttons with tooltips that accurately describe each hammer's behavior
**Depends on**: Phase 1
**Requirements**: UI-01
**Success Criteria** (what must be TRUE):
  1. Forge view displays 8 base hammer buttons (Transmute, Augment, Alchemy, Alteration, Regal, Chaos, Exalt, Divine, Annulment) alongside the 5 tag hammers
  2. Each base hammer button tooltip correctly describes the currency's PoE behavior (item type requirement, what changes)
  3. New hammer buttons are greyed out when the player has zero of that currency
**Plans**: 1 plan
- [x] 02-01-PLAN.md — Rarity-grouped 3×4 grid, strip PNG icons, remove dead hammer_icons dict, structural verification [UI-01] (pending human smoke check)

### Phase 3: Integration
**Goal**: New currencies appear in drops, persist across saves, and all 8 hammer behaviors are verified by the test suite
**Depends on**: Phase 2
**Requirements**: INT-01, INT-02, INT-03
**Success Criteria** (what must be TRUE):
  1. Alchemy, Divine, and Annulment hammers drop from monster packs with area gating consistent with other currencies
  2. A save file round-trip preserves Alchemy, Divine, and Annulment currency counts correctly
  3. Save format version is bumped and old saves migrate or start fresh without crashing
  4. Integration test suite passes with tests covering all 8 base hammer behaviors (apply success, apply failure/rejection)
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Hammer Models | 2/2 | Complete   | 2026-04-11 |
| 2. Forge UI | 1/1 | Plan complete (smoke check pending) | 2026-04-12 |
| 3. Integration | 2/3 | In Progress|  |
