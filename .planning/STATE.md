# Project State: Hammertime

**Updated:** 2026-02-19
**Milestone:** v1.6 Tech Debt Cleanup (in progress)

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-19)

**Core value:** The crafting loop must feel rewarding — finding items, using hammers to shape them, and equipping the result to push further into harder content.
**Current focus:** Phase 32 — Biome Compression and Difficulty Scaling

**Architecture:** Godot 4.5 GDScript, feature-based folders (models/, scenes/, autoloads/, utils/), Resource-based data model, signal-based communication via GameEvents, JSON save/load via SaveManager autoload.

## Current Position

Phase: 33 of 34 (Loot Table Rebalance)
Plan: 2 of 2 in current phase (complete)
Status: Phase 33 complete (both plans) — ready for Phase 34
Last activity: 2026-02-19 - Completed Phase 33 Plan 02: Hero health fixes and difficulty reduction

Progress: [████░░░░░░] 40% (milestone v1.6)

## Performance Metrics

**Phase 33 (in progress → complete 2026-02-19):**
- Plans: 2 | Tasks: 4 | Files: 6 | Duration: 4 min

**Phase 32 (in progress → complete 2026-02-19):**
- Plans: 1 | Tasks: 2 | Files: 2 | Duration: 3 min

**Milestone v1.5 (shipped 2026-02-19):**
- Phases: 4 (27-30) | Plans: 4 | Requirements: 9/9 | Timeline: 1 day

**Milestone v1.4 (shipped 2026-02-18):**
- Phases: 4 (23-26) | Plans: 7 | Requirements: 11/11 | Timeline: 1 day

**Milestone v1.3 (shipped 2026-02-18):**
- Phases: 5 (18-22) | Plans: 11 | Requirements: 13/13 | Timeline: 2 days

## Accumulated Context

### Decisions

All decisions logged in PROJECT.md Key Decisions table.
- [Phase 33-loot-table-rebalance]: Currency gates at 25/50/75 (biome boundaries); sqrt ramp curve over 12 levels; area_multiplier removed; items drop per-pack at 18% as Normal-only
- [Phase 32-biome-compression-and-difficulty-scaling]: Biomes compressed 4x: Forest 1-24, Dark Forest 25-49, Cursed Woods 50-74, Shadow Realm 75+
- [Phase 32-biome-compression-and-difficulty-scaling]: GROWTH_RATE raised from 0.06 to 0.10; boss walls +15/35/60% at last 3 levels of each biome; relief dip uses stat ratios; quadratic ramp-back over 8 levels
- [Phase 33-loot-table-rebalance]: FLAT_HEALTH/FLAT_ARMOR suffix split: weapon/ring only; armor slots bake via update_value()
- [Phase 33-loot-table-rebalance]: GROWTH_RATE reduced 0.10->0.07; boss walls +15/35/60% -> +10/20/40% for zone 20-25 progressability

### Pending Todos

- [ ] Add item drop filter for unwanted loot (FILT-01, FILT-02, FILT-03 — deferred to future)
- [ ] Add prestige meta-progression system
- [ ] Fix the icons in the crafting view
- [ ] Add large number formatting with suffix notation

### Blockers/Concerns

None.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 7 | Handle untracked / unstaged files | 2026-02-19 | 2648f05 | [7-handle-untracked-unstaged-files](./quick/7-handle-untracked-unstaged-files/) |
| 8 | Audit and fix affix pipeline (disable 9 dead mods, fix FLAT_HEALTH/FLAT_ARMOR aggregation) | 2026-02-19 | 5b29755 | [8-audit-and-fix-affix-pipeline-to-ensure-a](./quick/8-audit-and-fix-affix-pipeline-to-ensure-a/) |

## Session Continuity

Last session: 2026-02-19
Stopped at: Completed Phase 33 Plan 02 (hero health fixes and difficulty reduction)
Resume file: .planning/phases/33-loot-table-rebalance/33-02-SUMMARY.md

---
*State initialized: 2026-02-15*
*Last updated: 2026-02-19 — Phase 33 Plan 02 complete (hero health fixes and difficulty reduction)*
