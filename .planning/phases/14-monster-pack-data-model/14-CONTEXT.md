# Phase 14: Monster Pack Data Model - Context

**Gathered:** 2026-02-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Monster packs exist as Resources with HP, damage, and elemental damage types that scale with area level. This phase creates the data model (Resources, configurations, scaling formulas) that the combat loop (Phase 15) will consume. No combat mechanics — just the data structures and generation logic.

</domain>

<decisions>
## Implementation Decisions

### Pack Identity
- Named monster types, not generic stat bundles — each biome has a pool of 5-6 named types
- Each type has gameplay-relevant differences: own base HP, base damage, and attack speed
- Claude designs thematic monster types to fit each biome's identity (Forest = natural beasts, Shadow Realm = eldritch horrors, etc.)
- Examples: Bears = high base HP, slower attacks; Imps = low base HP, fast attacks

### Scaling Curves
- Gentle exponential scaling (~5-8% per level) for both HP and damage
- HP and damage scale at the same rate — packs get proportionally tougher and harder-hitting together
- Smooth curve across biomes — no extra difficulty spike at biome transitions (levels 100, 200, 300)
- Per-type base stats (HP, damage, attack speed) are scaled by area level multiplier, not flat modifiers on a shared formula

### Biome Elemental Distribution
- Each biome declares a primary element in its config (biomes are alpha placeholders, destined to be replaced)
- Current biomes: Forest (1-99), Dark Forest (100-199), Cursed Woods (200-299), Shadow Realm (300+)
- Element assignment to specific biomes is not locked — Claude assigns what fits, easy to swap later
- Within a biome: ~40% weight for primary element, ~60% weighted random across remaining elements
- Physical is NOT guaranteed in the off-element mix — some late-game biomes could be pure elemental
- Distribution is weighted random, not exact — natural variation per map
- Each individual pack deals a single element (no mixed damage per pack)

### Pack Count & Map Structure
- 8-15 packs per map (long runs, more currency from kills, map completion feels earned)
- Same pack count range across all biomes — consistent map length
- All packs within a map are roughly equal difficulty based on area level — no escalation or random spikes
- A "pack" is an abstract combat unit — not defined as 1 or many monsters. Just HP, damage, element, attack speed. UI can flavor it later (Phase 17)

### Claude's Discretion
- Specific monster type names and themes per biome
- Exact exponential growth rate within the 5-8% range
- Base stat values for each monster type
- Biome-to-element assignments (alpha placeholder biomes)
- How pack generation selects from the weighted pool

</decisions>

<specifics>
## Specific Ideas

- Pack types should have base stats that get affected by area level, not modifiers on a shared formula — "Bears should have higher base HP, maybe lower attack speed"
- Biomes are alpha and will be replaced in the future — design the element mapping to be easy to reconfigure
- The 40/60 elemental split forces balanced defenses — players can't trivialize a biome by stacking one resistance

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 14-monster-pack-data-model*
*Context gathered: 2026-02-16*
