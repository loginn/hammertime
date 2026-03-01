# Roadmap: Hammertime

## Milestones

- ✅ **v0.1 Code Cleanup & Architecture** — Phases 1-4 (shipped 2026-02-15)
- ✅ **v1.0 Crafting Overhaul** — Phases 5-8 (shipped 2026-02-15)
- ✅ **v1.1 Content & Balance** — Phases 9-12 (shipped 2026-02-16)
- ✅ **v1.2 Pack-Based Mapping** — Phases 13-17 (shipped 2026-02-17)
- ✅ **v1.3 Save/Load & Polish** — Phases 18-22 (shipped 2026-02-18)
- ✅ **v1.4 Damage Ranges** — Phases 23-26 (shipped 2026-02-18)
- ✅ **v1.5 Inventory Rework** — Phases 27-30 (shipped 2026-02-19)
- ✅ **v1.6 Tech Debt Cleanup** — Phases 31-34 (shipped 2026-02-20)
- 🚧 **v1.7 Meta-Progression** — Phases 35-41 (in progress)

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

<details>
<summary>✅ v1.5 Inventory Rework (Phases 27-30) — SHIPPED 2026-02-19</summary>

- [x] Phase 27: Save Format Migration (1/1 plan) — completed 2026-02-18
- [x] Phase 28: GameState Data Model and Drop Flow (1/1 plan) — completed 2026-02-19
- [x] Phase 29: ForgeView Logic (1/1 plan) — completed 2026-02-19
- [x] Phase 30: Display and Counter (1/1 plan) — completed 2026-02-19

Full details: `.planning/milestones/v1.5-ROADMAP.md`

</details>

<details>
<summary>✅ v1.6 Tech Debt Cleanup (Phases 31-34) — SHIPPED 2026-02-20</summary>

- [x] Phase 31: Repo Hygiene (1/1 plan) — completed 2026-02-19
- [x] Phase 32: Biome Compression and Difficulty Scaling (1/1 plan) — completed 2026-02-19
- [x] Phase 33: Loot Table Rebalance (2/2 plans) — completed 2026-02-19
- [x] Phase 34: Biome Preview Currency (1/1 plan) — completed 2026-02-19

Full details: `.planning/milestones/v1.6-ROADMAP.md`

</details>

### 🚧 v1.7 Meta-Progression (In Progress)

**Milestone Goal:** Add a prestige reset loop with currency-gated tier progression, expanded affix tiers (8→32), and tag-targeted crafting currencies. Every prestige level unlocks better item tiers; 32 affix tiers create a visible, granular upgrade path; tag hammers (available at Prestige 1) guarantee affixes with specific element or defense tags.

## Phase Details

### Phase 35: Prestige Foundation
**Goal**: PrestigeManager autoload and GameState prestige fields exist, giving all later phases a stable prestige data model to build on
**Depends on**: Phase 34
**Requirements**: PRES-01, PRES-02, PRES-03, PRES-05, PRES-06
**Success Criteria** (what must be TRUE):
  1. PrestigeManager autoload is registered with PRESTIGE_COSTS table, ITEM_TIERS_BY_PRESTIGE array, and MAX_PRESTIGE_LEVEL = 7 constants
  2. GameState has prestige_level, max_item_tier_unlocked, and tag_currency_counts fields that survive across sessions
  3. _wipe_run_state() resets area level, hero equipment, crafting inventory, and standard currencies without touching prestige_level or max_item_tier_unlocked
  4. GameEvents has prestige_completed(new_level: int) and tag_currency_dropped(drops: Dictionary) signals
  5. Calling execute_prestige() from P0 results in prestige_level == 1 and max_item_tier_unlocked reflecting P1 unlock
**Plans**: 1 plan

Plans:
- [ ] 35-01-PLAN.md — PrestigeManager autoload + GameState prestige fields + GameEvents signals + project.godot registration

### Phase 36: Save Format v3
**Goal**: Game saves correctly store and restore prestige state so old saves load cleanly and prestige progress never disappears
**Depends on**: Phase 35
**Requirements**: SAVE-01, SAVE-02
**Success Criteria** (what must be TRUE):
  1. SAVE_VERSION is 3; a v2 save file loads without error and prestige_level defaults to 0
  2. prestige_level, max_item_tier_unlocked, and tag currency counts round-trip correctly through save/load
  3. Completing a prestige triggers an auto-save before the reset clears run state
**Plans**: 1 plan

Plans:
- [ ] 36-01-PLAN.md — Save format v3: prestige field persistence + delete-on-old-version + prestige auto-save

### Phase 37: Affix Tier Expansion
**Goal**: All affixes support 32 tiers with quality-normalized comparison so high-tier items from later prestiges are meaningfully better
**Depends on**: Phase 35
**Requirements**: AFFIX-01, AFFIX-02
**Success Criteria** (what must be TRUE):
  1. Every affix in item_affixes.gd has tier_range expanded to Vector2i(1, 32) with retuned base_min/base_max values
  2. affix.quality() returns a normalized float (0.0→1.0) enabling correct comparison between affixes from different tier ranges
**Plans**: TBD

Plans:
- [ ] 37-01: Affix quality normalization + tier range expansion to 32

### Phase 38: Item Tier System
**Goal**: Dropped items carry an item_tier field that gates which affix tiers can roll, and area level weights drops toward better tiers within the prestige-unlocked ceiling
**Depends on**: Phase 37
**Requirements**: TIER-01, TIER-02, TIER-03
**Success Criteria** (what must be TRUE):
  1. Every dropped item has an item_tier value between 1 and max_item_tier_unlocked
  2. Items dropped in higher areas within the same prestige skew toward higher item tiers (verified by seeing more tier 7-8 drops in Shadow Realm vs Forest at P0)
  3. Crafting a mod onto a tier-8 item rolls only affix tiers 29-32; crafting onto a tier-1 item rolls from all 32 tiers
**Plans**: TBD

Plans:
- [ ] 38-01: Item.item_tier field + LootTable weighted tier rolling + affix constraint in add_prefix/suffix

### Phase 39: Tag-Targeted Currencies
**Goal**: Five tag hammers (Fire, Cold, Lightning, Defense, Physical) are available after Prestige 1, transform Normal items to Rare with at least one guaranteed matching-tag affix, and drop from packs at appropriate rates
**Depends on**: Phase 38
**Requirements**: TAG-01, TAG-02, TAG-03, TAG-04, TAG-05, TAG-06, TAG-07, TAG-08
**Success Criteria** (what must be TRUE):
  1. Applying a Fire Hammer to a Normal item produces a Rare item with 4-6 mods where at least one mod has the Fire tag
  2. Applying any tag hammer to an item with no valid mods for that tag shows a "no valid mods" message and consumes no currency
  3. Tag hammer buttons do not appear in the crafting view before Prestige 1
  4. After reaching Prestige 1, tag hammer currency drops from monster packs
  5. All five tag hammers (Fire, Cold, Lightning, Defense, Physical) work correctly on each applicable item slot
**Plans**: TBD

Plans:
- [ ] 39-01: TagHammer base class + five subclasses
- [ ] 39-02: Tag currency drops in LootTable + prestige-gating

### Phase 40: Prestige UI
**Goal**: Player can see their prestige status at all times, understand exactly what a prestige costs and rewards, view the full 7-level unlock table, and trigger prestige through a confirmation flow that lists everything that resets
**Depends on**: Phase 39
**Requirements**: PRES-04, PUI-01, PUI-02, PUI-03, PUI-04, PUI-05
**Success Criteria** (what must be TRUE):
  1. Current prestige level is visible in the main UI without navigating to any tab
  2. Player can see prestige cost (currency amounts) and the next unlock (item tier) before triggering prestige
  3. A full unlock table shows all 7 prestige levels with their item tier rewards; current level is highlighted, future levels show as locked
  4. The prestige confirmation dialog lists the exact cost, the unlock gained, and a complete list of what resets
  5. Tag hammer buttons appear in the crafting view after reaching Prestige 1 and are absent before it
**Plans**: TBD

Plans:
- [ ] 40-01: Prestige panel in ForgeView (status, cost, unlock table, confirm flow)
- [ ] 40-02: Tag hammer button row + prestige level display in main UI

### Phase 41: Integration Verification
**Goal**: The full prestige loop works end-to-end from fresh game through multiple prestiges, with save round-trips validated at each stage and no regressions in existing crafting behavior
**Depends on**: Phase 40
**Requirements**: (all 23 v1.7 requirements verified)
**Success Criteria** (what must be TRUE):
  1. Full prestige flow completes without error: fresh game → reach prestige threshold → confirm prestige → post-prestige state correct (prestige_level+1, gear/inventory/area cleared, tag hammers now available)
  2. Save round-trip at each prestige level (P0 through P2 minimum) restores prestige_level, max_item_tier_unlocked, and tag currency counts exactly
  3. A hand-crafted v2 save fixture loads correctly under v3 migration with prestige_level == 0 and all items intact
**Plans**: TBD

Plans:
- [ ] 41-01: End-to-end prestige loop verification + v2 migration fixture test

## Progress

| Phase             | Milestone | Plans Complete | Status      | Completed  |
|-------------------|-----------|----------------|-------------|------------|
| 1-4               | v0.1      | 8/8            | Complete    | 2026-02-15 |
| 5-8               | v1.0      | 7/7            | Complete    | 2026-02-15 |
| 9-12              | v1.1      | 7/7            | Complete    | 2026-02-16 |
| 13-17             | v1.2      | 11/11          | Complete    | 2026-02-17 |
| 18-22             | v1.3      | 11/11          | Complete    | 2026-02-18 |
| 23-26             | v1.4      | 7/7            | Complete    | 2026-02-18 |
| 27-30             | v1.5      | 4/4            | Complete    | 2026-02-19 |
| 31-34             | v1.6      | 5/5            | Complete    | 2026-02-20 |
| 35. Prestige Foundation    | 1/1 | Complete    | 2026-02-20 | -          |
| 36. Save Format v3         | 1/1 | Complete    | 2026-02-20 | -          |
| 37. Affix Tier Expansion   | 1/1 | Complete   | 2026-03-01 | -          |
| 38. Item Tier System       | v1.7 | 0/1       | Not started | -          |
| 39. Tag-Targeted Currencies| v1.7 | 0/2       | Not started | -          |
| 40. Prestige UI            | v1.7 | 0/2       | Not started | -          |
| 41. Integration Verification | v1.7 | 0/1     | Not started | -          |

---
*Roadmap created: 2026-02-14*
*Last updated: 2026-02-20 — v1.7 Meta-Progression roadmap added (phases 35-41)*
