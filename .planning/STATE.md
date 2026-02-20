# Project State: Hammertime

**Updated:** 2026-02-20
**Milestone:** v1.7 Meta-Progression

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-20)

**Core value:** The crafting loop must feel rewarding — finding items, using hammers to shape them, and equipping the result to push further into harder content.
**Current focus:** Phase 35 — Prestige Foundation

**Architecture:** Godot 4.5 GDScript, feature-based folders (models/, scenes/, autoloads/, utils/), Resource-based data model, signal-based communication via GameEvents, JSON save/load via SaveManager autoload.

## Current Position

Phase: 35 of 41 (Prestige Foundation)
Plan: 0 of TBD in current phase
Status: Ready to plan
Last activity: 2026-02-20 — v1.7 roadmap created (phases 35-41)

Progress: [████████░░] 80% (8 milestones complete, v1.7 starting)

## Performance Metrics

**Milestone v1.6 (shipped 2026-02-20):**
- Phases: 4 (31-34) | Plans: 5 | Tasks: 9 | Requirements: 9/9 | Timeline: 1 day

**Milestone v1.5 (shipped 2026-02-19):**
- Phases: 4 (27-30) | Plans: 4 | Requirements: 9/9 | Timeline: 1 day

**Milestone v1.4 (shipped 2026-02-18):**
- Phases: 4 (23-26) | Plans: 7 | Requirements: 11/11 | Timeline: 1 day

**Milestone v1.3 (shipped 2026-02-18):**
- Phases: 5 (18-22) | Plans: 11 | Requirements: 13/13 | Timeline: 2 days

## Accumulated Context

### Decisions

All decisions logged in PROJECT.md Key Decisions table.

Key v1.7 constraints (from research):
- _wipe_run_state() must be separate from initialize_fresh_game() — never call the latter from the prestige path
- tag_currency_counts lives as a separate dictionary on GameState (not merged into currency_counts)
- Affix tier constraint applied at construction time in add_prefix/add_suffix, not stored on item
- v2 save migration: breaking old saves is acceptable (user decision); v3 migration is additive-only

### Pending Todos

- [ ] Add item drop filter for unwanted loot (FILT-01 — deferred to future)
- [ ] Fix the icons in the crafting view
- [ ] Add large number formatting with suffix notation

### Blockers/Concerns

- Phase 37 (Affix Tier Expansion): base_min/base_max retuning requires a balance pass — verify pre-prestige floor within 10% of v1.6 before shipping
- Phase 39 (Tag Currencies): expected-value calculation vs Runic/Forge needed before setting drop rates — count tag distribution in item_affixes.gd per item slot first
- Phase 41 (Verification): requires a hand-crafted v2 fixture JSON for migration testing — build artifact before declaring migration correct

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 7 | Handle untracked / unstaged files | 2026-02-19 | 2648f05 | [7-handle-untracked-unstaged-files](./quick/7-handle-untracked-unstaged-files/) |
| 8 | Audit and fix affix pipeline (disable 9 dead mods, fix FLAT_HEALTH/FLAT_ARMOR aggregation) | 2026-02-19 | 5b29755 | [8-audit-and-fix-affix-pipeline-to-ensure-a](./quick/8-audit-and-fix-affix-pipeline-to-ensure-a/) |
| 9 | Rename original_base_xxx to base_xxx and base_xxx to computed_xxx; remove BasicArmor/BasicHelmet FLAT_ARMOR implicits | 2026-02-19 | ac58cda | [9-rename-original-base-xxx-to-base-xxx-and](./quick/9-rename-original-base-xxx-to-base-xxx-and/) |

## Session Continuity

Last session: 2026-02-20
Stopped at: v1.7 roadmap created — Phase 35 ready to plan
Resume file: None

---
*State initialized: 2026-02-15*
*Last updated: 2026-02-20 — v1.7 Meta-Progression roadmap written (phases 35-41, 7 phases, 24 requirements)*
