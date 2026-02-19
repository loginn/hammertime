# Phase 33: Loot Table Rebalance - Context

**Gathered:** 2026-02-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Retune all drop tables for the compressed 25-level biome structure. Currency gates unlock at biome thresholds with ramp-up curves, items drop from pack kills (not map completion), all items drop as Normal (0 affixes), and drop volume stays lean. Maps keep their area progression role — map completion rewards are removed (future: totem parts).

</domain>

<decisions>
## Implementation Decisions

### Currency ramp-up shape
- "Immediate but low" curve — currency starts dropping right away at unlock threshold, at a low rate that gradually reaches full over ~12 levels
- Same ramp curve for all currencies (Forge Hammer at 25, Grand at 50, Claw and Tuning at 75)
- All earlier currencies persist at full rate — no phase-out when new currencies unlock
- Full drop rate target: ~1 currency per 3-5 packs

### Item drop volume
- Items drop from individual pack kills, NOT from map completion
- Drop rate: 1-3 items per map equivalent — most packs drop nothing
- Drop rate stays constant across all biomes (no scaling with progression)
- Item type (equipment slot) is purely random, no weighting
- Item stats are fixed by tier — currently only tier 8 items exist
- Higher tiers from higher areas are a future system, not this phase

### Normal-only enforcement
- All items drop as Normal (0 affixes) — mod assignment at drop time must be removed
- Existing saves: grandfather old items with affixes (no stripping on load)
- Items display "Normal" rarity label; label updates as player hammers mods on
- No hint system needed — player discovers hammering through crafting UI

### Drop source change
- Items now drop from pack kills within maps, not from map completion
- Maps are auto-entered (start combat / clear map / die and restart) — not dropped items
- Map completion reward is removed entirely for this phase
- Map completion reward will be replaced with totem parts in a future phase (deferred)
- Maps retain their area progression role

### Key system distinction (for all downstream agents)
- **Tier** = item advancement level. Higher tier = more advanced item. Property of the item itself. Currently only tier 8 items exist.
- **Rarity** = max number of mods an item can have. Defined by how many mods have been added via hammers. Items drop as Normal (0 mods).
- These are SEPARATE systems. Do not conflate them.

### Claude's Discretion
- Exact mathematical curve for the "immediate but low" ramp-up
- How to distribute the 1-3 item drops across packs within a map (probability per pack)
- Technical approach to removing mod assignment at drop time

</decisions>

<specifics>
## Specific Ideas

- Currency should feel generous at full rate (~1 per 3-5 packs) so the player always has material to craft with
- Items are intentionally rare (1-3 per map) — each drop matters and gets evaluated
- The crafting loop is the progression: find Normal item → hammer mods onto it → push further
- Map completion rewards → totem parts is noted in pending todos for future work

</specifics>

<deferred>
## Deferred Ideas

- Higher item tiers dropping in higher areas — future phase (tier system expansion)
- Map modifiers affecting drops on specific maps — future phase
- Totem parts as map completion reward — future phase (noted in project todos)

</deferred>

---

*Phase: 33-loot-table-rebalance*
*Context gathered: 2026-02-19*
