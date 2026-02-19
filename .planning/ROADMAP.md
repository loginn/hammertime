# Roadmap: Hammertime

## Milestones

- ✅ **v0.1 Code Cleanup & Architecture** — Phases 1-4 (shipped 2026-02-15)
- ✅ **v1.0 Crafting Overhaul** — Phases 5-8 (shipped 2026-02-15)
- ✅ **v1.1 Content & Balance** — Phases 9-12 (shipped 2026-02-16)
- ✅ **v1.2 Pack-Based Mapping** — Phases 13-17 (shipped 2026-02-17)
- ✅ **v1.3 Save/Load & Polish** — Phases 18-22 (shipped 2026-02-18)
- ✅ **v1.4 Damage Ranges** — Phases 23-26 (shipped 2026-02-18)
- ✅ **v1.5 Inventory Rework** — Phases 27-30 (shipped 2026-02-19)
- 🚧 **v1.6 Tech Debt Cleanup** — Phases 31-34 (in progress)

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

### 🚧 v1.6 Tech Debt Cleanup (In Progress)

**Milestone Goal:** Clean repo hygiene and rebalance progression — compress biomes to ~25 levels each, retune all scaling, and make crafting the sole source of item mods.

## Phase Details

### Phase 31: Repo Hygiene
**Goal**: The repository is clean — no stale temp files tracked and .gitignore prevents future accidents
**Depends on**: Nothing (first phase of milestone)
**Requirements**: REPO-01, REPO-02
**Success Criteria** (what must be TRUE):
  1. Running `git status` shows no .tmp files tracked or staged
  2. The .gitignore file contains `*.tmp` and newly created .tmp files are not picked up by `git status`
  3. The root directory contains no .tmp files (removed from disk and git history)
**Plans**: 1 plan
- [ ] 31-01-PLAN.md — Remove .tmp files from git tracking/disk and update .gitignore

### Phase 32: Biome Compression and Difficulty Scaling
**Goal**: The 4 biomes span levels 1-100+ compressed to ~25 levels each, with difficulty scaling at ~10% per level so endgame feels meaningfully harder than the start
**Depends on**: Phase 31
**Requirements**: PROG-01, PROG-02
**Success Criteria** (what must be TRUE):
  1. Dark Forest packs appear at level 25, Cursed Woods at level 50, Shadow Realm at level 75
  2. A level 75 pack is noticeably harder than a level 1 pack (difficulty multiplier reflects ~10% compounding per level)
  3. Biome transitions feel natural — monsters in each biome are clearly more threatening than the previous
**Plans**: 1 plan
- [ ] 32-01-PLAN.md — Compress biome boundaries and redesign difficulty curve with boss wall / relief / ramp-back

### Phase 33: Loot Table Rebalance
**Goal**: Currency gates, drop counts, and item rarity all reflect the compressed 25-level biome structure — items always drop Normal, and currency unlocks arrive at the right biome thresholds
**Depends on**: Phase 32
**Requirements**: PROG-03, PROG-04, PROG-05, PROG-07
**Success Criteria** (what must be TRUE):
  1. Forge Hammer currency starts dropping at area 25, Grand at 50, Claw and Tuning at 75
  2. A newly unlocked currency type ramps up over ~12 levels before reaching full drop rates
  3. Item drop counts feel meaningful across the compressed range (not front-loaded or flat)
  4. Every item that drops has 0 affixes (Normal rarity) — the player must use hammers to add mods
**Plans**: TBD

### Phase 34: Biome Preview Currency
**Goal**: Players receive occasional rare currency drops from the next biome as a teaser for upcoming content, appearing at roughly 1 drop per 50 packs in the current biome
**Depends on**: Phase 33
**Requirements**: PROG-06
**Success Criteria** (what must be TRUE):
  1. While clearing packs in one biome, the player occasionally receives a currency type that is gated to the next biome
  2. Preview drops are rare enough to feel special — approximately 1 occurrence per 50 packs on average
  3. Receiving a preview currency creates anticipation for the next biome without disrupting current progression balance
**Plans**: TBD

## Progress

**Execution Order:** 31 → 32 → 33 → 34

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 31. Repo Hygiene | 1/1 | Complete    | 2026-02-19 |
| 32. Biome Compression and Difficulty Scaling | 1/1 | Complete   | 2026-02-19 |
| 33. Loot Table Rebalance | 0/TBD | Not started | - |
| 34. Biome Preview Currency | 0/TBD | Not started | - |

---
*Roadmap created: 2026-02-14*
*Last updated: 2026-02-19 — v1.6 Tech Debt Cleanup roadmap added (phases 31-34)*
