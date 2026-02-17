# Phase 17: UI and Combat Feedback - Context

**Gathered:** 2026-02-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Display pack-based combat state so the player can observe HP changes, pack progress, and combat events. This phase adds visual feedback to the existing combat engine — no new game mechanics, just making existing state visible.

</domain>

<decisions>
## Implementation Decisions

### HP Display
- Health bar + numbers for both hero and pack (current/max overlaid on bar)
- Energy shield shown as stacked overlay on top of HP bar (blue over red, Path of Exile style)
- Pack HP uses the same bar+numbers style as hero HP — consistent treatment

### Pack Progress
- Progress bar that fills as packs are cleared
- Pack count overlaid on the bar itself ("3/7" format)
- Area level and biome name always visible during map runs
- Bar updates with instant jump when a pack is killed (snappy, not animated)

### Combat Feedback
- Floating damage numbers pop up and fade near the target (ARPG style)
- Crits get distinct treatment: bigger numbers in a different color
- Evasion shows "DODGE" floating text when hero evades an attack
- Damage numbers are uniform color regardless of element type (no elemental color-coding)

### State Transitions
- Death: inline state change in the combat area, not a full overlay
- Map complete: auto-advance seamlessly to next map with minimal fanfare
- Pack-to-pack: brief visual pause (~half second) so player notices pack change
- After death: auto-retry after a short delay (2-3 seconds), no button needed

### Claude's Discretion
- HP bar positioning/layout within the gameplay view
- Exact colors and sizing for HP bars, floating numbers, and crit styling
- Floating number animation (direction, fade speed, drift)
- Death state visual treatment (what "inline state change" looks like specifically)
- ES recharge visual feedback during pack transitions

</decisions>

<specifics>
## Specific Ideas

- ES overlay on HP bar inspired by Path of Exile's blue-over-red shield display
- Pack progress bar should feel like a dungeon clear tracker — filling up as you go
- Combat should feel idle/auto but with enough visual feedback to be satisfying to watch

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 17-ui-and-combat-feedback*
*Context gathered: 2026-02-17*
