# Project State: Hammertime

**Updated:** 2026-02-18
**Milestone:** v1.5 Inventory Rework

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-18)

**Core value:** The crafting loop must feel rewarding — finding items, using hammers to shape them, and equipping the result to push further into harder content.

**Current focus:** Phase 27 — Save Format Migration

**Architecture:** Godot 4.5 GDScript, feature-based folders (models/, scenes/, autoloads/, utils/), Resource-based data model, signal-based communication via GameEvents, JSON save/load via SaveManager autoload.

## Current Position

Phase: 27 of 30 (Save Format Migration)
Plan: — (not yet planned)
Status: Ready to plan
Last activity: 2026-02-18 — v1.5 roadmap created, phases 27-30 defined

Progress: [░░░░░░░░░░] 0% (milestone v1.5)

## Performance Metrics

**Milestone v1.4 (shipped 2026-02-18):**
- Phases: 4 (23-26) | Plans: 7 | Requirements: 11/11 | Timeline: 1 day

**Milestone v1.3 (shipped 2026-02-18):**
- Phases: 5 (18-22) | Plans: 11 | Requirements: 13/13 | Timeline: 2 days

## Accumulated Context

### Decisions

All decisions logged in PROJECT.md Key Decisions table.

Recent decisions affecting v1.5:
- Migration-before-schema: write `_migrate_v1_to_v2()` and `_restore_state()` together before touching `_build_save_data()`
- No save migration needed for external players (fresh saves only); v1→v2 migration still needed for dev saves
- `crafting_bench_item` confirmed orphaned in GameState — remove entirely in Phase 28
- `is_item_better()` guard must be deleted from the drop path (Phase 28); keep in stat comparison display
- x/10 counter display uses existing `inventory_label` Label node (not ItemList) — minimal scope

### Pending Todos

- [ ] Add item drop filter for unwanted loot (FILT-01, FILT-02, FILT-03 — deferred to future)
- [ ] Rebalance early progression difficulty curve

### Blockers/Concerns

None.

## Session Continuity

Last session: 2026-02-18
Stopped at: Roadmap created for v1.5. Phase 27 ready to plan.
Resume file: None

---
*State initialized: 2026-02-15*
*Last updated: 2026-02-18 — v1.5 roadmap created, ready to plan Phase 27*
