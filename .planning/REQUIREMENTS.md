# Requirements: Hammertime

**Defined:** 2026-02-14
**Core Value:** The crafting loop must feel rewarding -- finding items, using hammers to shape them, and equipping the result to push further into harder content.

## v0.1 Requirements

Requirements for the Code Cleanup & Architecture milestone.

### Code Style

- [ ] **STYLE-01**: All GDScript files are formatted with gdformat (consistent style)
- [ ] **STYLE-02**: All files and classes follow snake_case naming convention (Godot 4 standard)
- [ ] **STYLE-03**: Function signatures have return type hints

### File Organization

- [ ] **ORG-01**: Project uses feature-based folder structure (models/, scenes/, autoloads/, utils/)
- [ ] **ORG-02**: All .gd and .tscn files are moved from root to appropriate folders
- [ ] **ORG-03**: File moves preserve all scene references (done via Godot Editor)

### Data Model

- [ ] **DATA-01**: Item, Weapon, Armor, Helmet, Boots, Ring classes extend Resource instead of Node
- [ ] **DATA-02**: Affix and Implicit classes extend Resource instead of Node
- [ ] **DATA-03**: GameState autoload exists as single source of truth for Hero instance
- [ ] **DATA-04**: GameEvents autoload exists as event bus for cross-scene signals

### Stat Calculations

- [ ] **CALC-01**: Single unified stat calculation system replaces duplicate compute_dps() in weapon.gd and ring.gd
- [ ] **CALC-02**: Tag system is separated into AffixTag (affix filtering/eligibility) and StatType (damage calculation routing)
- [ ] **CALC-03**: All item types use a standardized update_value() interface
- [ ] **CALC-04**: Damage calculation inconsistencies are resolved (multiplicative vs additive, crit formula differences)

### View Communication

- [ ] **VIEW-01**: Views use signals instead of direct get_node() calls for cross-view communication
- [ ] **VIEW-02**: Parent-child communication follows "call down, signal up" pattern
- [ ] **VIEW-03**: Node references use @onready caching instead of repeated get_node() calls

## v1.0 Requirements (Deferred)

Preserved from v1.0 Crafting Overhaul planning. Will be re-scoped after v0.1 completes.

### Item Rarity

- **RARITY-01**: Items have a rarity tier (Normal, Magic, Rare)
- **RARITY-02**: Normal items have 0 explicit mods (implicit only)
- **RARITY-03**: Magic items can have up to 1 prefix and 1 suffix
- **RARITY-04**: Rare items can have up to 3 prefixes and 3 suffixes
- **RARITY-05**: Item rarity is visually distinguished (Normal=white, Magic=blue, Rare=yellow)
- **RARITY-06**: Item display shows current mod count vs maximum

### Crafting Currencies

- **CRAFT-01**: Runic Hammer upgrades Normal to Magic (1-2 random mods)
- **CRAFT-02**: Forge Hammer upgrades Normal to Rare (4-6 random mods)
- **CRAFT-03**: Tack Hammer adds random mod to Magic (1+1 limit)
- **CRAFT-04**: Grand Hammer adds random mod to Rare (3+3 limit)
- **CRAFT-05**: Claw Hammer removes random mod without changing rarity
- **CRAFT-06**: Tuning Hammer rerolls all mod values within tier ranges
- **CRAFT-07**: Currency validates rarity and mod count before application
- **CRAFT-08**: Invalid use shows clear error message
- **CRAFT-09**: Currency consumed only after successful application

### Drop System

- **DROP-01**: Area difficulty influences item rarity drop weights
- **DROP-02**: All 6 hammer types drop from area clearing
- **DROP-03**: Dropped items spawn with rarity-appropriate mods

### UI

- **UI-01**: 6 currency buttons replacing old 3 hammer buttons
- **UI-02**: Select currency, click item to apply
- **UI-03**: Currency counts displayed per hammer type
- **UI-04**: Old 3-hammer system fully removed

## Out of Scope

| Feature | Reason |
|---------|--------|
| New gameplay features | This is cleanup only -- no new mechanics |
| Save/load system | Resource migration enables it, but implementation deferred |
| Testing framework (GdUnit4) | Nice to have but not blocking -- can add later |
| Modifier pipeline (flat/increased/more) | Over-engineering for current scope -- unify first, formalize later |
| Composition over inheritance | Current 5 item types don't justify the complexity |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| STYLE-01 | Phase 1 | Pending |
| STYLE-02 | Phase 1 | Pending |
| STYLE-03 | Phase 1 | Pending |
| ORG-01 | Phase 1 | Pending |
| ORG-02 | Phase 1 | Pending |
| ORG-03 | Phase 1 | Pending |
| DATA-01 | Phase 2 | Pending |
| DATA-02 | Phase 2 | Pending |
| DATA-03 | Phase 2 | Pending |
| DATA-04 | Phase 2 | Pending |
| CALC-01 | Phase 3 | Pending |
| CALC-02 | Phase 3 | Pending |
| CALC-03 | Phase 3 | Pending |
| CALC-04 | Phase 3 | Pending |
| VIEW-01 | Phase 4 | Pending |
| VIEW-02 | Phase 4 | Pending |
| VIEW-03 | Phase 4 | Pending |

**Coverage:**
- v0.1 requirements: 17 total
- Mapped to phases: 17
- Unmapped: 0

---
*Requirements defined: 2026-02-14*
*Last updated: 2026-02-14 after roadmap creation*
