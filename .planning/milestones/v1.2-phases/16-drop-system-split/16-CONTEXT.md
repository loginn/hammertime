# Phase 16: Drop System Split - Context

**Gathered:** 2026-02-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Split the reward loop so packs drop currency on kill and map completion drops items. Death preserves currency earned from cleared packs but forfeits item drops. The existing `roll_currency_drops()` area-clear trigger is removed — packs become the sole source of currency.

</domain>

<decisions>
## Implementation Decisions

### Currency from packs
- Packs are the **sole source** of currency — existing area-clear currency drops are removed entirely
- Currency types are **weighted by area level** — higher areas drop higher-tier currencies more often
- **Area gating applies to drops** — currencies only drop from packs if the area meets the currency's minimum area requirement (Phase 11 gates)
- Quantity per pack is **chance-based (0-2)** — each pack has a chance to drop 0, 1, or 2 currencies, adding variance
- **Higher area packs drop more currency** — currency drop rates scale with area level to incentivize pushing
- **Harder packs drop more** — pack difficulty (HP/damage) influences drop rates, not elemental type (elemental packs are not inherently harder)

### Item drops on map completion
- Map completion awards **1-3 items** with area-scaled distribution:
  - Area 1: ~99% chance for 1 item
  - Area 300: ~60% chance for 2, ~20% for 1, ~20% for 3
  - Smooth scaling between anchors
- **Both rarity and item level scale with area** — higher areas give better rarity chances AND higher item levels
- Item generation reuses existing `roll_rarity()` and `spawn_item_with_mods()` — only the quantity curve changes

### Death penalty
- Death **restarts the same area** — hero keeps trying the same area level until they clear it
- Death **keeps currency from fully cleared packs** — only packs killed before death count (no partial credit for the pack you died fighting)
- **No additional death penalty** — losing item drops IS the penalty, currency kept is the consolation
- Map **generates new random packs** on retry — every run feels different

### Risk-reward tension
- **No bonus for full clears** beyond item drops — items are the reward, currency farming is the consolation
- Both tensions emerge naturally: "do I have the gear?" and "should I push or farm?" — no need to engineer either specifically
- The split creates a natural loop: farm currency from safe areas to craft gear, push harder areas for better items

### Claude's Discretion
- Exact currency quantity distribution curves per area level
- How to adapt `roll_currency_drops()` for per-pack triggering vs the current per-clear bulk roll
- Pack difficulty classification for drop rate bonuses
- Transition of existing loot_table.gd — what stays, what gets removed, what gets refactored

</decisions>

<specifics>
## Specific Ideas

- Existing `roll_currency_drops()` fires on area clear — this moves to per-pack-kill with adjusted quantities
- The bonus_drops logarithmic scaling in loot_table.gd may need rethinking for per-pack context
- `get_item_drop_count()` is replaced with the new 1-3 area-scaled distribution
- Guarantee of "at least 1 runic" may shift from per-clear to per-map or per-death context

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 16-drop-system-split*
*Context gathered: 2026-02-17*
