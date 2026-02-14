# Requirements: Hammertime

**Defined:** 2026-02-14
**Core Value:** The crafting loop must feel rewarding — finding items, using hammers to shape them, and equipping the result to push further into harder content.

## v1.0 Requirements

Requirements for the Crafting Overhaul milestone. Each maps to roadmap phases.

### Item Rarity

- [ ] **RARITY-01**: Items have a rarity tier (Normal, Magic, Rare)
- [ ] **RARITY-02**: Normal items have 0 explicit mods (implicit only)
- [ ] **RARITY-03**: Magic items can have up to 1 prefix and 1 suffix
- [ ] **RARITY-04**: Rare items can have up to 3 prefixes and 3 suffixes
- [ ] **RARITY-05**: Item rarity is visually distinguished (Normal=white, Magic=blue, Rare=yellow)
- [ ] **RARITY-06**: Item display shows current mod count vs maximum (e.g., "Prefixes: 2/3")

### Crafting Currencies

- [ ] **CRAFT-01**: Runic Hammer upgrades a Normal item to Magic (adds 1-2 random mods)
- [ ] **CRAFT-02**: Forge Hammer upgrades a Normal item to Rare (adds 4-6 random mods)
- [ ] **CRAFT-03**: Tack Hammer adds a random mod to a Magic item (respects 1+1 limit)
- [ ] **CRAFT-04**: Grand Hammer adds a random mod to a Rare item (respects 3+3 limit)
- [ ] **CRAFT-05**: Claw Hammer removes a random mod without changing item rarity
- [ ] **CRAFT-06**: Tuning Hammer rerolls all explicit mod values within their tier ranges
- [ ] **CRAFT-07**: Each currency validates item rarity and mod count before application
- [ ] **CRAFT-08**: Invalid currency use shows a clear error message explaining why
- [ ] **CRAFT-09**: Currency is only consumed after successful application

### Drop System

- [ ] **DROP-01**: Area difficulty influences item rarity drop weights (harder areas = rarer items)
- [ ] **DROP-02**: All 6 hammer types drop from area clearing
- [ ] **DROP-03**: Dropped items spawn with mods appropriate to their rarity

### UI

- [ ] **UI-01**: Crafting view shows 6 currency buttons replacing old 3 hammer buttons
- [ ] **UI-02**: Player selects a currency then clicks an item to apply
- [ ] **UI-03**: Currency counts are displayed for each hammer type
- [ ] **UI-04**: Old 3-hammer system is fully removed

## Future Requirements

Deferred to future milestones. Tracked but not in current roadmap.

### Polish

- **POLISH-01**: Advanced crafting feedback UI (before/after preview, highlight changes)
- **POLISH-02**: Rarity-specific visual effects (glow, particles, sound)
- **POLISH-03**: Smart currency suggestions (highlight usable currencies for selected item)
- **POLISH-04**: Crafting history/undo (1-step undo for Claw Hammer)

### Economy

- **ECON-01**: Item melting/recycling system
- **ECON-02**: Currency exchange/conversion between hammer types
- **ECON-03**: Currency drop rate balancing based on observed progression pacing

### Meta

- **META-01**: Crafting achievements/milestones
- **META-02**: Hammer upgrade tiers (e.g., "Blessed Tuning Hammer")

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Unique items | Deferred to future milestone — adds complexity without core loop value |
| Chaos Orb / full item reroll | Deliberate design choice — forces incremental crafting, not gambling |
| Rarity downgrade currencies | No clear use case — Claw Hammer removes mods without downgrading |
| Deterministic crafting (choose exact mod) | Eliminates gameplay loop — RNG is the core engagement driver |
| Metamod/block crafting | Too complex for idle game genre |
| Complex rarity tiers (Exalted/Fractured) | Inappropriate for simplified 3-tier system |
| Drag-and-drop crafting UI | Select-and-click is sufficient for current scope |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| RARITY-01 | - | Pending |
| RARITY-02 | - | Pending |
| RARITY-03 | - | Pending |
| RARITY-04 | - | Pending |
| RARITY-05 | - | Pending |
| RARITY-06 | - | Pending |
| CRAFT-01 | - | Pending |
| CRAFT-02 | - | Pending |
| CRAFT-03 | - | Pending |
| CRAFT-04 | - | Pending |
| CRAFT-05 | - | Pending |
| CRAFT-06 | - | Pending |
| CRAFT-07 | - | Pending |
| CRAFT-08 | - | Pending |
| CRAFT-09 | - | Pending |
| DROP-01 | - | Pending |
| DROP-02 | - | Pending |
| DROP-03 | - | Pending |
| UI-01 | - | Pending |
| UI-02 | - | Pending |
| UI-03 | - | Pending |
| UI-04 | - | Pending |

**Coverage:**
- v1.0 requirements: 22 total
- Mapped to phases: 0
- Unmapped: 22

---
*Requirements defined: 2026-02-14*
*Last updated: 2026-02-14 after initial definition*
