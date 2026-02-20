# Phase 34: Biome Preview Currency - Context

**Gathered:** 2026-02-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Move existing currency gates down by 10 levels so players receive next-biome currencies as a teaser while still in the current biome. This is NOT a new drop system — it reuses the existing currency gate and 12-level sqrt ramp from Phase 33, just with shifted thresholds.

</domain>

<decisions>
## Implementation Decisions

### Which currencies preview
- Any currency gated to the next biome can appear (random selection from all next-biome currencies)
- Quantity per drop: small random amount (1-3 units)
- Preview currencies are usable immediately in the forge — no restriction based on biome progress

### Drop distribution
- Shift all currency gates down by exactly 10 levels:
  - Forge Hammer: 25 → 15
  - Grand: 50 → 40
  - Claw/Tuning: 75 → 65
- The existing 12-level sqrt ramp curve handles the gradual increase naturally — very rare at first, reaching full drop rates by the original gate level
- No new preview drop system needed — this is purely a gate threshold change

### Drop presentation
- No visual distinction — preview currency drops look identical to normal currency drops
- Same drop UI, same inventory behavior

### Last biome handling
- Shadow Realm (75+) has no next biome — no special handling needed
- All currencies are already unlocked by then

### Claude's Discretion
- Exact ramp curve behavior in the 10-level preview window (existing sqrt ramp should handle it)

</decisions>

<specifics>
## Specific Ideas

- "This is really just moving the gating down, it doesn't need a new system of preview" — implementation should be a simple threshold change in the existing currency gate config

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 34-biome-preview-currency*
*Context gathered: 2026-02-19*
