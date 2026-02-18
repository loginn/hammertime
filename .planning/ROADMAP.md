# Roadmap: Hammertime

## Milestones

- ✅ **v0.1 Code Cleanup & Architecture** — Phases 1-4 (shipped 2026-02-15)
- ✅ **v1.0 Crafting Overhaul** — Phases 5-8 (shipped 2026-02-15)
- ✅ **v1.1 Content & Balance** — Phases 9-12 (shipped 2026-02-16)
- ✅ **v1.2 Pack-Based Mapping** — Phases 13-17 (shipped 2026-02-17)
- ✅ **v1.3 Save/Load & Polish** — Phases 18-22 (shipped 2026-02-18)
- 🚧 **v1.4 Damage Ranges** — Phases 23-26 (in progress)

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

### 🚧 v1.4 Damage Ranges (In Progress)

**Milestone Goal:** Replace flat damage values with min-max ranges for weapons, monsters, and affixes, giving each element a distinct variance identity and updating UI to display ranges.

**No save migration:** User chose fresh saves only. Existing saves are not supported across this milestone boundary.

- [ ] **Phase 23: Damage Range Data Model** — Add min/max range fields to Weapon, Affix templates, and MonsterPack with element-specific variance constants
- [ ] **Phase 24: Stat Calculation and Hero Range Caching** — Dual-accumulator DPS math in StatCalculator and per-element min/max totals on Hero
- [ ] **Phase 25: Per-Hit Combat Rolling** — CombatEngine rolls hero damage per-element independently and monster pack rolls per-hit from its range
- [ ] **Phase 26: UI Range Display** — Weapon and affix tooltips show X-to-Y ranges, DPS uses range averages, item comparison uses DPS, pack info shows name and element

## Phase Details

### Phase 23: Damage Range Data Model
**Goal**: Weapons, affixes, and monster packs all express damage as min-max ranges with element-specific variance
**Depends on**: Phase 22 (v1.3 complete)
**Requirements**: DMG-01, DMG-02, DMG-03, DMG-04
**Success Criteria** (what must be TRUE):
  1. Every weapon type has base_damage_min and base_damage_max fields; base_damage returns their average for backward compatibility
  2. Every flat damage affix template has four range fields (dmg_min_lo, dmg_min_hi, dmg_max_lo, dmg_max_hi) and rolls add_min/add_max at item creation from those bounds
  3. Element variance constants exist for Physical, Fire, Cold, and Lightning defining the spread ratio for each element; Lightning has the widest spread and Physical the tightest
  4. MonsterPack has damage_min and damage_max fields populated by PackGenerator using the element variance constants
  5. Tuning Hammer re-roll reads from template bounds (not previously rolled values), so repeated re-rolls never collapse the range
**Plans:** 1/2 plans executed
Plans:
- [ ] 23-01-PLAN.md — Weapon base damage range fields and element variance constants
- [ ] 23-02-PLAN.md — Affix six-field damage range schema and MonsterPack damage ranges

### Phase 24: Stat Calculation and Hero Range Caching
**Goal**: StatCalculator accumulates per-element min and max independently, and Hero caches the totals for combat use
**Depends on**: Phase 23
**Requirements**: STAT-01
**Success Criteria** (what must be TRUE):
  1. StatCalculator.calculate_damage_range() returns a per-element breakdown of total_min and total_max for hero equipment
  2. Percentage damage modifiers (e.g., +10% fire damage) scale both the min and max ends independently — a 10-20 fire affix with +10% fire mod produces 11-22, not 15-15
  3. Hero exposes total_damage_min and total_damage_max per element, populated after equip and recalculated on load (not serialized)
  4. DPS display value uses (min+max)/2 averaged across all elements — the displayed number is stable and comparable between items
**Plans**: TBD

### Phase 25: Per-Hit Combat Rolling
**Goal**: Every hero and monster attack rolls actual damage from the range rather than using a deterministic per-hit value
**Depends on**: Phase 24
**Requirements**: CMB-01, CMB-02
**Success Criteria** (what must be TRUE):
  1. Hero attacks roll physical base damage independently from each elemental flat affix; element-specific percentage modifiers apply per-element before summing; the result is a single rolled hit value passed to DefenseCalculator
  2. Ten consecutive hero hits against the same pack show nonzero variance (no two hits are identical unless the range is degenerate)
  3. Monster pack attacks roll per-hit from the pack's damage_min/damage_max range before the defense pipeline; the DefenseCalculator interface is unchanged
  4. Lightning-element monster packs show noticeably wider hit variance than Physical-element packs at the same area level
**Plans**: TBD

### Phase 26: UI Range Display
**Goal**: Players see X-to-Y damage ranges on weapon tooltips and affix descriptions, and DPS values are computed from range averages
**Depends on**: Phase 25
**Requirements**: DISP-01, DISP-02, DISP-03, DISP-04
**Success Criteria** (what must be TRUE):
  1. Weapon item tooltip shows "Damage: X to Y" instead of a single number; the displayed range matches base_damage_min/max
  2. Flat damage affix descriptions show "Adds X to Y [Element] Damage" using the rolled add_min/add_max values
  3. DPS shown in hero stats and item comparison uses the average-of-ranges formula across all elements with modifiers applied; it matches the value used by is_item_better() for weapon comparison
  4. UI labels do not overflow at 1280x720 with the longest realistic lightning affix string
  5. Gameplay view displays the current pack's name and damage element type during combat
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
| 23. Damage Range Data Model | 1/2 | In Progress|  | - |
| 24. Stat Calculation and Hero Range Caching | v1.4 | 0/? | Not started | - |
| 25. Per-Hit Combat Rolling | v1.4 | 0/? | Not started | - |
| 26. UI Range Display | v1.4 | 0/? | Not started | - |

---
*Roadmap created: 2026-02-14*
*Last updated: 2026-02-18 — Phase 23 planned (2 plans)*
