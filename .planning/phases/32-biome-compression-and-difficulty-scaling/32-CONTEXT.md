# Phase 32: Biome Compression and Difficulty Scaling - Context

**Gathered:** 2026-02-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Compress the 4 biomes from ~100 levels each (Forest 1-99, Dark Forest 100-199, Cursed Woods 200-299, Shadow Realm 300+) down to ~25 levels each (Forest 1-24, Dark Forest 25-49, Cursed Woods 50-74, Shadow Realm 75+). Retune difficulty scaling from 6% to ~10% per level so endgame feels meaningfully harder than the start. Loot table rebalancing is Phase 33; preview currency is Phase 34.

</domain>

<decisions>
## Implementation Decisions

### Biome transition feel
- Last 2-3 levels of each biome ramp up as a "boss wall" — difficulty spikes above the normal 10% curve
- Boss wall pattern applies to ALL biomes, including Forest (levels ~22-24 ramp up before Dark Forest)
- First level of the new biome is an actual difficulty DROP below the boss wall — noticeably easier, "new chapter" feeling
- The relief is real: level 25 should be genuinely easier than level 24 (not just slower growth)
- Takes 5-10 levels into the new biome before difficulty ramps back past the boss wall level — half the biome is easier territory to explore new monsters

### Endgame scaling (75+)
- Shadow Realm scales infinitely with 10% compounding — no cap, no tapering
- No boss wall pattern repeats within Shadow Realm — just smooth 10% exponential after level 75
- Prestige/endgame loop deferred to v2 milestone

### Growth rate shape
- Flat 10% base growth rate across all biomes — compounding itself makes later content harder
- Boss wall ramp is EXTRA on top of the base 10% (not averaged into it)
- Lower peak multiplier at biome starts is acceptable — 1,083x at level 75 is fine, game is shorter and tighter
- Curve-driven difficulty (the formula handles everything) — no separate base stat jumps at biome transitions
- Curve dip at biome transitions must account for higher base stats of new biome monsters — relief must still feel real despite inherently stronger monsters
- Elemental identity per biome stays as-is (Forest=physical, Dark Forest=fire, Cursed Woods=cold, Shadow Realm=lightning)
- Attack speed stays fixed (not level-scaled) — future map mods will handle speed variation

### Monster identity
- Monster rosters per biome stay exactly as they are — same creatures, same composition
- Base stat differences between biomes stay (Shadow Realm monsters are inherently tougher than Forest monsters)
- Within-biome variety stays (Sprites are squishy, Golems are tanky — that spread is part of the fun)

### Claude's Discretion
- Exact boss wall multiplier values for the last 2-3 levels
- Exact relief dip magnitude at biome starts (must account for base stat jump)
- How the 5-10 level ramp-back curve is shaped
- Any base stat fine-tuning needed to make the curve + base stats interaction feel right

</decisions>

<specifics>
## Specific Ideas

- Boss wall → relief → ramp creates a rhythm: push through hard content, get rewarded with a breather in new territory, then it ramps up again
- "New chapter" feel when entering a biome — you're facing stronger monsters but the curve gives you room to explore before it gets serious
- The game should feel tighter and more compressed — fewer filler levels, every level matters

</specifics>

<deferred>
## Deferred Ideas

- Prestige meta-progression system — v2 milestone, kicked in when infinite scaling gets too extreme
- Map mods and monster identity system — future feature for attack speed variation and pack modifiers
- Loot table rebalancing for compressed ranges — Phase 33
- Biome preview currency drops — Phase 34

</deferred>

---

*Phase: 32-biome-compression-and-difficulty-scaling*
*Context gathered: 2026-02-19*
