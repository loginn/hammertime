# Phase 27: Save Format Migration - Context

**Gathered:** 2026-02-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Bump save version to v2 and implement v1-to-v2 migration for per-slot inventory arrays. Save/load must correctly handle the new array format and migrate any existing v1 saves. The orphaned `crafting_bench_item` key must be absent from written and migrated saves. Fresh game saves write v2 format with empty arrays for all slots.

</domain>

<decisions>
## Implementation Decisions

### Item mapping rules
- Each v1 single-item slot wraps into a 1-element array in v2 (e.g., weapon slot with a sword becomes `[sword]`)
- Empty/null v1 slots become empty arrays `[]` — every slot always has an array key
- All five crafting slots (weapon, helmet, chest, gloves, boots) follow the identical migration pattern
- Equipped items remain as separate fields — slot arrays are inventory/stash only, not equipment

### Backward compatibility
- No backward compatibility needed — there are no external players
- Old v1 saves can be broken without concern
- One-way migration only; no need to support writing v1 format

### Migration error handling
- If a save fails to load or migrate, reset to fresh game state
- No graceful fallback, retry logic, or partial recovery needed
- Simple approach: load works or state resets

### Claude's Discretion
- Save version detection mechanism (version field, format sniffing, etc.)
- Internal structure of `_migrate_v1_to_v2()` and `_restore_state()` methods
- Whether to log migration events or silently proceed
- Exact key naming for the new per-slot arrays in save data

</decisions>

<specifics>
## Specific Ideas

- Migration-before-schema approach already decided: write `_migrate_v1_to_v2()` and `_restore_state()` together before touching `_build_save_data()` (from STATE.md)
- `crafting_bench_item` confirmed orphaned — strip from saves in this phase, remove from GameState in Phase 28

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 27-save-format-migration*
*Context gathered: 2026-02-18*
