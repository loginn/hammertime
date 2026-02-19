# Project State: Hammertime

**Updated:** 2026-02-19
**Milestone:** v1.6 Tech Debt Cleanup (in progress)

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-19)

**Core value:** The crafting loop must feel rewarding — finding items, using hammers to shape them, and equipping the result to push further into harder content.
**Current focus:** Phase 34 — Biome Preview Currency

**Architecture:** Godot 4.5 GDScript, feature-based folders (models/, scenes/, autoloads/, utils/), Resource-based data model, signal-based communication via GameEvents, JSON save/load via SaveManager autoload.

## Current Position

Phase: 34 of 34 (Biome Preview Currency)
Plan: 1 of 1 in current phase (complete)
Status: Phase 34 complete — milestone v1.6 Tech Debt Cleanup complete
Last activity: 2026-02-19 - Completed Phase 34 Plan 01: Currency gate threshold shift for biome preview

Progress: [██████████] 100% (milestone v1.6)

## Performance Metrics

**Phase 34 (in progress → complete 2026-02-19):**
- Plans: 1 | Tasks: 1 | Files: 1 | Duration: 1 min

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
- [Phase 34-biome-preview-currency]: Currency gates shifted 10 levels before biome boundaries (forge 25->15, grand 50->40, claw/tuning 75->65); reused Phase 33 sqrt ramp — purely threshold change

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
| 9 | Rename original_base_xxx to base_xxx and base_xxx to computed_xxx; remove BasicArmor/BasicHelmet FLAT_ARMOR implicits | 2026-02-19 | ac58cda | [9-rename-original-base-xxx-to-base-xxx-and](./quick/9-rename-original-base-xxx-to-base-xxx-and/) |

## Session Continuity

Last session: 2026-02-19
Stopped at: Completed 34-biome-preview-currency-01-PLAN.md
Resume file: .planning/phases/34-biome-preview-currency/34-01-SUMMARY.md

---
*State initialized: 2026-02-15*
*Last updated: 2026-02-19 — Phase 34 complete (biome preview currency gates shifted)*
