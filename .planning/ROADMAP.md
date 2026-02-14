# Roadmap: Hammertime

## Overview

This roadmap delivers the v1.0 Crafting Overhaul: replacing the basic 3-hammer system with a PoE-inspired rarity tier system (Normal/Magic/Rare) and 6 themed crafting hammers. The work progresses from rarity data model, through currency mechanics and UI integration, to drop system wiring -- each phase delivering a testable vertical slice of the crafting loop.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Rarity Foundation** - Item rarity tiers with mod limits and visual distinction
- [ ] **Phase 2: Currency Mechanics** - Six crafting hammers with validation and error handling
- [ ] **Phase 3: Crafting UI Overhaul** - New 6-button currency UI replacing old 3-hammer system
- [ ] **Phase 4: Drop System Integration** - Rarity-weighted item drops and currency rewards from areas

## Phase Details

### Phase 1: Rarity Foundation
**Goal**: Items have meaningful rarity tiers that determine their crafting potential and are visually distinguishable
**Depends on**: Nothing (first phase)
**Requirements**: RARITY-01, RARITY-02, RARITY-03, RARITY-04, RARITY-05, RARITY-06
**Success Criteria** (what must be TRUE):
  1. Every item in the game has a rarity (Normal, Magic, or Rare) and it is visible in the UI via color coding (white, blue, yellow)
  2. Normal items display only their implicit mod with no explicit mods
  3. Magic items enforce a maximum of 1 prefix and 1 suffix; attempting to exceed this is blocked
  4. Rare items enforce a maximum of 3 prefixes and 3 suffixes; attempting to exceed this is blocked
  5. Item tooltips show current mod count versus maximum for the item's rarity (e.g., "Prefixes: 2/3")
**Plans**: TBD

Plans:
- [ ] 01-01: TBD
- [ ] 01-02: TBD

### Phase 2: Currency Mechanics
**Goal**: Six crafting hammers can modify items according to rarity rules, with clear validation and feedback
**Depends on**: Phase 1
**Requirements**: CRAFT-01, CRAFT-02, CRAFT-03, CRAFT-04, CRAFT-05, CRAFT-06, CRAFT-07, CRAFT-08, CRAFT-09
**Success Criteria** (what must be TRUE):
  1. Runic Hammer upgrades a Normal item to Magic (adding 1-2 random mods) and Forge Hammer upgrades a Normal item to Rare (adding 4-6 random mods)
  2. Tack Hammer adds a random mod to a Magic item and Grand Hammer adds a random mod to a Rare item, both respecting their rarity's mod limits
  3. Claw Hammer removes a random explicit mod from any item without changing its rarity tier
  4. Tuning Hammer rerolls all explicit mod values within their tier ranges without adding or removing mods
  5. Using a currency on an invalid target (wrong rarity, full mods) shows a clear error message and does not consume the currency
**Plans**: TBD

Plans:
- [ ] 02-01: TBD
- [ ] 02-02: TBD
- [ ] 02-03: TBD

### Phase 3: Crafting UI Overhaul
**Goal**: Players interact with the new currency system through an intuitive select-and-click interface
**Depends on**: Phase 2
**Requirements**: UI-01, UI-02, UI-03, UI-04
**Success Criteria** (what must be TRUE):
  1. Crafting view displays 6 currency buttons (Runic, Forge, Tack, Grand, Claw, Tuning) where the old 3 hammer buttons used to be
  2. Player can select a currency button, then click an inventory item to apply that currency's effect
  3. Each currency button shows the player's current count of that hammer type
  4. The old 3-hammer system (implicit/prefix/suffix hammers) is completely removed with no remnants in UI or code
**Plans**: TBD

Plans:
- [ ] 03-01: TBD
- [ ] 03-02: TBD

### Phase 4: Drop System Integration
**Goal**: Area clearing rewards players with rarity-appropriate items and all 6 hammer types
**Depends on**: Phase 1, Phase 2
**Requirements**: DROP-01, DROP-02, DROP-03
**Success Criteria** (what must be TRUE):
  1. Harder areas drop higher-rarity items more frequently (e.g., Shadow Realm drops more Rare items than Forest)
  2. All 6 hammer types can drop from area clearing, feeding the currency inventory
  3. Dropped items spawn with mods appropriate to their rarity (Normal has 0 explicit, Magic has 1-2, Rare has 4-6)
**Plans**: TBD

Plans:
- [ ] 04-01: TBD
- [ ] 04-02: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Rarity Foundation | 0/TBD | Not started | - |
| 2. Currency Mechanics | 0/TBD | Not started | - |
| 3. Crafting UI Overhaul | 0/TBD | Not started | - |
| 4. Drop System Integration | 0/TBD | Not started | - |
