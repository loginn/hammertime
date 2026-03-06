# Phase 36: Save Format v3 - Context

**Gathered:** 2026-02-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Save format v3: persist prestige_level, max_item_tier_unlocked, and tag_currency_counts through save/load. Auto-save on prestige completion. Old v2 saves are NOT migrated.

</domain>

<decisions>
## Implementation Decisions

### Migration behavior
- No v2-to-v3 migration path. If save version < 3, delete the old save file and start a fresh game automatically
- Silent handling — no toast or in-game message about migration. Just delete and fresh start
- The existing _migrate_v1_to_v2 code can be removed or left as dead code (Claude's discretion)
- No validation/clamping on prestige field values — trust the data, consistent with how other save fields are handled

### Auto-save timing
- Claude's discretion on exact timing (before wipe vs after full prestige cycle)

### Save string export
- Claude's discretion on whether prestige fields are included in HT1 export format (they should be for completeness)

### Claude's Discretion
- Auto-save timing relative to prestige wipe sequence
- Whether to clean up old migration code or leave it
- Prestige field inclusion in export/import save strings
- Any defensive coding around save field parsing

</decisions>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 36-save-format-v3*
*Context gathered: 2026-02-20*
