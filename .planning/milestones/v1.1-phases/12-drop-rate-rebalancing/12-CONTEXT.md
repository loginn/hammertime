# Phase 12: Drop Rate Rebalancing - Context

**Gathered:** 2026-02-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Tune item rarity weights, currency drop chances, and item drop quantities across the expanded area level range (1-300+). All content (defensive prefixes, elemental resistances, currency gating) is in place from Phases 9-11 — this phase adjusts numerical values so rewards scale appropriately with area difficulty.

</domain>

<decisions>
## Implementation Decisions

### Early game scarcity
- Rare items at area 1: approximately 1 per 50 clears (down from current ~1 per 10)
- Magic items also rarer in early areas (e.g. 1 per 10-15, down from ~1 per 5-6)
- Every clear guarantees at least 1 item drop (never zero items)
- Every clear guarantees at least 1 currency drop (steady hammer flow from the start)

### Late game rewards
- Rare items at area 300: approximately 1 per 5 clears (generous endgame)
- Advanced currencies (Grand, Claw, Tuning) still feel rare even at area 300 — every drop is meaningful
- Magic items become the dominant drop type at area 300 — normal items become uncommon
- Higher areas drop more items total per clear (volume reward on top of quality improvement)
- Max item drops at area 300: 4-5 items per clear (up from 1 guaranteed at area 1)

### Progression curve shape
- Smooth logarithmic curve — rapid early improvement that tapers into slow progression
- Meta progression (prestige system) will resolve the late-game taper in a future milestone
- Mild bumps at tier boundaries (100/200/300) on top of the smooth curve — reaching a new area tier feels rewarding
- Both item quantity and rarity weights scale with area level (double reward for progression)

### Tuning methodology
- Playtest-driven validation — play the game, note what feels wrong, adjust numbers based on experience
- Budget 2-3 iteration passes: first pass with initial values, then 1-2 refinement passes
- Drop simulator from Phase 11 available as reference but primary validation is through play

### Claude's Discretion
- Exact formula coefficients for the logarithmic curve
- Specific rarity weight values at each area level
- How to implement the mild tier-boundary bumps (additive bonus vs multiplicative)
- Item quantity scaling formula (floor vs fractional with RNG)
- How magic/rare weight distributions shift along the curve

</decisions>

<specifics>
## Specific Ideas

- Logarithmic curve should eventually taper into very slow progression — this will be resolved through meta progression (prestige) in a future milestone, not through infinite drop scaling
- Currency gating from Phase 11 already handles unlock boundaries — this phase only tunes the rates within those gates
- Endgame should feel like a loot shower (4-5 items, mostly magic, occasional rare) without making individual rares feel cheap

</specifics>

<deferred>
## Deferred Ideas

- Meta progression / prestige system to resolve late-game taper — future milestone
- Inventory management for higher drop volumes (stash, auto-sell, filters) — future milestone

</deferred>

---

*Phase: 12-drop-rate-rebalancing*
*Context gathered: 2026-02-16*
