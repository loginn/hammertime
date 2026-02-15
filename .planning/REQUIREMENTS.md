# Requirements: Hammertime

**Defined:** 2026-02-15
**Core Value:** The crafting loop must feel rewarding -- finding items, using hammers to shape them, and equipping the result to push further into harder content.

## v1.0 Requirements

Requirements for the Crafting Overhaul milestone. Replaces the basic 3-hammer system with rarity tiers and 6 themed crafting hammers.

### Item Rarity

- [ ] **RARITY-01**: Items have a rarity tier (Normal, Magic, Rare)
- [ ] **RARITY-02**: Normal items have 0 explicit mods (implicit only)
- [ ] **RARITY-03**: Magic items can have up to 1 prefix and 1 suffix
- [ ] **RARITY-04**: Rare items can have up to 3 prefixes and 3 suffixes
- [ ] **RARITY-05**: Item rarity is visually distinguished (Normal=white, Magic=blue, Rare=yellow)
- [ ] **RARITY-06**: Item display shows current mod count vs maximum

### Crafting Currencies

- [ ] **CRAFT-01**: Runic Hammer upgrades Normal to Magic (1-2 random mods)
- [ ] **CRAFT-02**: Forge Hammer upgrades Normal to Rare (4-6 random mods)
- [ ] **CRAFT-03**: Tack Hammer adds random mod to Magic (1+1 limit)
- [ ] **CRAFT-04**: Grand Hammer adds random mod to Rare (3+3 limit)
- [ ] **CRAFT-05**: Claw Hammer removes random mod without changing rarity
- [ ] **CRAFT-06**: Tuning Hammer rerolls all mod values within tier ranges
- [ ] **CRAFT-07**: Currency validates rarity and mod count before application
- [ ] **CRAFT-08**: Invalid use shows clear error message
- [ ] **CRAFT-09**: Currency consumed only after successful application

### Drop System

- [ ] **DROP-01**: Area difficulty influences item rarity drop weights
- [ ] **DROP-02**: All 6 hammer types drop from area clearing
- [ ] **DROP-03**: Dropped items spawn with rarity-appropriate mods

### UI

- [ ] **UI-01**: 6 currency buttons replacing old 3 hammer buttons
- [ ] **UI-02**: Select currency, click item to apply
- [ ] **UI-03**: Currency counts displayed per hammer type
- [ ] **UI-04**: Old 3-hammer system fully removed

## Future Requirements

Deferred to future milestones.

### Unique Items

- **UNIQ-01**: Unique item tier with fixed mods and special effects
- **UNIQ-02**: Unique items cannot be crafted, only found

### Salvage System

- **SALV-01**: Items can be melted/salvaged for crafting materials
- **SALV-02**: Salvage value scales with item rarity and mod count

## Out of Scope

| Feature | Reason |
|---------|--------|
| Unique items | Defer to future milestone -- rarity system first |
| Item melting/salvage | Future feature -- not needed for crafting overhaul |
| Chaos-style full reroll | Design choice: no full rerolls, craft carefully or equip as-is |
| Drag-and-drop crafting UI | Select-and-click is sufficient |
| Save/load system | Resource model enables it, but not v1.0 scope |
| Testing framework | Nice to have but not blocking |

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
*Requirements defined: 2026-02-15*
*Last updated: 2026-02-15 after initial definition*
