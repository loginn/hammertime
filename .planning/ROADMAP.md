# Roadmap: Hammertime v0.1

## Overview

Refactor the Hammertime codebase from a flat, inconsistently structured prototype into clean Godot 4.5 architecture. The work follows strict dependency order -- format and organize first, then migrate data models to Resources, then unify scattered calculation logic, then wire up signal-based communication. The game must remain fully functional after every phase.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3, 4): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation** - Format all code, establish folder structure, move files
- [x] **Phase 2: Data Model Migration** - Migrate Item/Affix classes to Resource, create GameState/GameEvents autoloads
- [ ] **Phase 3: Unified Calculations** - Consolidate stat calculation, separate tag system, standardize item interface
- [ ] **Phase 4: Signal-Based Communication** - Replace get_node() wiring with signals, enforce call down/signal up

## Phase Details

### Phase 1: Foundation
**Goal**: The codebase has consistent formatting, proper naming, and an organized folder structure -- ready for structural refactoring
**Depends on**: Nothing (first phase)
**Requirements**: STYLE-01, STYLE-02, STYLE-03, ORG-01, ORG-02, ORG-03
**Success Criteria** (what must be TRUE):
  1. Running gdformat on any .gd file produces no changes (all files already formatted)
  2. Every .gd and .tscn file uses snake_case naming (no PascalCase files, no spaces in filenames)
  3. All function signatures in the codebase have return type hints
  4. Project files live in feature-based folders (models/, scenes/, autoloads/, utils/) with nothing left in root except project.godot and supporting config
  5. The game launches and plays identically to before the reorganization (F5 test passes)
**Plans:** 2 plans

**NOTE**: File moves (ORG-02, ORG-03) must be done via Godot Editor's FileSystem dock to preserve scene references. Claude cannot move files from terminal -- the user must perform moves in the editor. Plans should provide clear move-by-move instructions for the user to follow.

Plans:
- [x] 01-01-PLAN.md -- Format all GDScript with gdformat and add return type hints to every function
- [x] 01-02-PLAN.md -- Rename files to snake_case, create folder structure, move files via Godot Editor

### Phase 2: Data Model Migration
**Goal**: All game data classes extend Resource instead of Node, with GameState and GameEvents autoloads as the backbone for state management and cross-scene communication
**Depends on**: Phase 1
**Requirements**: DATA-01, DATA-02, DATA-03, DATA-04
**Success Criteria** (what must be TRUE):
  1. Item, Weapon, Armor, Helmet, Boots, and Ring classes all extend Resource (not Node)
  2. Affix and Implicit classes extend Resource (not Node)
  3. GameState autoload holds a single Hero instance accessible from any script via GameState.hero
  4. GameEvents autoload defines core signals (equipment_changed, item_crafted, area_cleared) usable from any script
  5. The game launches and all existing functionality works identically (equipping, crafting, area clearing)
**Plans:** 2 plans

Plans:
- [x] 02-01-PLAN.md -- Convert Affix, Implicit, Item, and all Item subclasses from Node to Resource
- [x] 02-02-PLAN.md -- Create GameState/GameEvents autoloads, convert Hero to Resource, wire views to GameState.hero

### Phase 3: Unified Calculations
**Goal**: A single stat calculation system handles all item types, with clean tag separation between affix filtering and damage routing
**Depends on**: Phase 2
**Requirements**: CALC-01, CALC-02, CALC-03, CALC-04
**Success Criteria** (what must be TRUE):
  1. One unified stat calculation replaces the duplicate compute_dps() implementations in weapon.gd and ring.gd -- only one source of DPS truth exists
  2. Tags are separated into AffixTag (controls which affixes can roll on which items) and StatType (routes values into damage calculations) with no overlap in responsibilities
  3. Every item type (Weapon, Helmet, Armor, Boots, Ring) implements the same update_value() interface for stat recalculation
  4. DPS calculation produces consistent results regardless of which item type contributes the stats (multiplicative vs additive inconsistencies resolved)
**Plans:** 2 plans

Plans:
- [ ] 03-01-PLAN.md -- Create StatType enum, StatCalculator class, and wire stat_types into all affix definitions
- [ ] 03-02-PLAN.md -- Refactor all item types to delegate calculations to StatCalculator, remove duplicate compute_dps()

### Phase 4: Signal-Based Communication
**Goal**: Views communicate through signals instead of direct node references, following Godot's call-down/signal-up pattern
**Depends on**: Phase 3
**Requirements**: VIEW-01, VIEW-02, VIEW-03
**Success Criteria** (what must be TRUE):
  1. No view uses get_node() to reference a sibling view -- all cross-view communication goes through signals (GameEvents or parent coordinator)
  2. Parent-to-child communication uses direct method calls; child-to-parent communication uses signals (call down, signal up pattern verified)
  3. All node references use @onready var caching -- no repeated get_node() calls inside methods
  4. The game launches and all UI updates work identically (hero stats update when equipping, crafting view reflects inventory changes, gameplay view responds to area clearing)
**Plans**: TBD

Plans:
- [ ] 04-01: TBD
- [ ] 04-02: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 2/2 | ✓ Complete | 2026-02-14 |
| 2. Data Model Migration | 2/2 | ✓ Complete | 2026-02-15 |
| 3. Unified Calculations | 0/2 | Planned | - |
| 4. Signal-Based Communication | 0/0 | Not started | - |

---
*Roadmap created: 2026-02-14*
*Milestone: v0.1 Code Cleanup & Architecture*
