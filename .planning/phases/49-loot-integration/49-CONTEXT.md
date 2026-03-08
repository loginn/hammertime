# Phase 49: Loot & Integration - Context

**Gathered:** 2026-03-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Final integration pass for v1.8 milestone. Wire all 21 item bases into the drop pool, bump save version to invalidate old saves, and confirm multi-channel DPS and archetype systems work end-to-end.

</domain>

<decisions>
## Implementation Decisions

### Drop Pool (LOOT-01)
- Already shipped in Phase 44 — all 21 bases are in `gameplay_view.gd:get_random_item_base()` with slot-first-then-archetype distribution
- No further work needed; verify during integration testing

### Save Version Bump (LOOT-02)
- Bump SAVE_VERSION from 6 to 7
- Old saves (< 7) wiped on load, fresh game starts — established pattern
- No save format changes — current v6 structure already handles all 21 item types, spell mode, DoT stats
- Version bump only, no format audit

### Item Comparison (LOOT-03)
- **Dropped.** Keep tier-only comparison (`is_item_better()` uses tier)
- Players can judge DPS themselves from the stat panel
- Combined DPS comparison adds complexity without clear player value in an idle game

### Archetype Labels (LOOT-04)
- **Dropped.** Item names are self-documenting (Dagger = DEX, Wand = INT, Broadsword = STR)
- No archetype text labels, no color-coding
- Archetype identity exists in code (valid_tags) but doesn't need UI exposure

### Claude's Discretion
- Integration test scope and coverage for verifying LOOT-01 is complete
- Whether any cleanup of Phase 42-48 loose ends should be bundled

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `gameplay_view.gd:get_random_item_base()`: Already contains all 21 bases with slot-first-then-archetype logic
- `save_manager.gd`: SAVE_VERSION constant at line 4, wipe-on-old-version pattern established
- `forge_view.gd:is_item_better()`: Tier-only comparison, no changes needed
- `hero.gd:get_total_dot_dps()`: DoT DPS aggregation exists for display purposes

### Established Patterns
- Save version bump: change constant, old saves auto-wiped (no migration code needed)
- Drop pool: slot array selection in get_random_item_base(), each slot has array of base classes

### Integration Points
- `save_manager.gd:4` — SAVE_VERSION constant (6 → 7)
- `gameplay_view.gd:404-424` — Drop pool (verify complete, no changes expected)

</code_context>

<specifics>
## Specific Ideas

No specific requirements — phase is primarily verification and a save version bump. Most integration work was completed incrementally in Phases 42-48.

</specifics>

<deferred>
## Deferred Ideas

- Archetype color-coding on item names — revisit when loot filter or hero archetype systems are built
- Combined DPS item comparison — revisit if players report confusion about which items are better

</deferred>

---

*Phase: 49-loot-integration*
*Context gathered: 2026-03-08*
