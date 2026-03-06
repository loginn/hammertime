# Phase 35: Prestige Foundation - Context

**Gathered:** 2026-02-20
**Status:** Ready for planning

<domain>
## Phase Boundary

PrestigeManager autoload, GameState prestige fields, and core prestige execution logic. This is the data backbone — all later prestige phases (save format, affix expansion, item tiers, tag hammers, prestige UI) build on the structures defined here. No UI in this phase.

</domain>

<decisions>
## Implementation Decisions

### Prestige cost curve
- P1 costs 100 Forge Hammers — this is the only real prestige cost for now
- P2–P7 get unreachable stub values in PRESTIGE_COSTS table (e.g., 999999) so they're impossible to hit until costs are tuned
- Costs are paid in standard currencies (not a dedicated prestige currency)
- Each prestige level has its own specific currency subset (P1 = Forge Hammers only; other levels TBD)

### Reset scope boundaries
- _wipe_run_state() resets exactly 4 categories: area level, hero equipment, crafting inventory, and standard currencies
- Tag currencies are also wiped on prestige (they're a run currency, not a meta currency)
- prestige_level and max_item_tier_unlocked survive resets
- After wipe, player gets the default starting state (same as a fresh game) plus 1 random tag-targeted hammer added as a currency count
- No extra Forge Hammers or gear beyond the default start

### Tag currency drop model
- All 5 tag types (fire, cold, lightning, defense, physical) available from P1
- Random chance per pack (not guaranteed) — rarer than Forge Hammer drops since tag hammers are a better currency
- Variable quantity: 1–3 per drop when it occurs
- Uniform random tag type selection (no area weighting)
- Drop chance scales with area level — higher areas have better tag currency drop rates
- tag_currency_dropped signal fires once per pack with bundled Dictionary (e.g., {fire: 2, cold: 1})
- Data model should support gating future currency types behind different prestige levels (even though all 5 tag currencies unlock at P1 for now)

### Claude's Discretion
- Exact placeholder values for P2–P7 costs
- Base drop chance percentage and area scaling formula for tag currencies
- Default starting state composition (whatever a fresh game currently provides)
- Internal structure of PRESTIGE_COSTS table and ITEM_TIERS_BY_PRESTIGE array

</decisions>

<specifics>
## Specific Ideas

- Tag currencies should be rarer than Forge Hammers — they're an overall better currency
- Future prestige levels will gate additional currency types beyond tags (design the data model to accommodate this)
- P1 is the only prestige that should be practically achievable in current build

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 35-prestige-foundation*
*Context gathered: 2026-02-20*
