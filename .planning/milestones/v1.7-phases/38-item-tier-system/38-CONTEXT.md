# Phase 38: Item Tier System - Context

**Gathered:** 2026-03-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Add an item_tier field (1-8) to items that gates which affix tiers can roll during crafting, with area-level-weighted drop distribution within the prestige-unlocked range. This phase builds the SYSTEM only — new base item types for tiers 1-7 are a separate content phase.

All existing base items are tier 8. The system is ready for tier 7-1 items when a future content phase creates them.

</domain>

<decisions>
## Implementation Decisions

### Item tier as fixed base property
- Item tier is an intrinsic, constant property of each base item type (Light Sword = always tier 8)
- Reuse the existing `Item.tier` field (item.gd:15) — no new field needed
- All current base items are tier 8
- Higher-tier (lower-number) items require new base item definitions (future content phase)
- `is_item_better()` in forge_view.gd already compares on `item.tier` — no change needed

### Drop tier weighting
- Area-weighted distribution: each tier has a "home" area range with bell-curve tapering
- T8 peaks in early areas (Forest), becomes rare by area 50+, very rare beyond 75+
- Higher tiers progressively appear at higher areas (threshold unlocks with smooth overlap)
- Best unlocked tier is NEVER guaranteed — always some RNG
- At P0 (only tier 8 unlocked), all drops are tier 8 — weighting only kicks in at P1+
- Distribution shape: normal-distribution-like curves centered at each tier's "home" area

### Affix tier constraint model
- Strict 4-per-band: item tier maps to exact affix tier floor
  - Tier 8: affix tiers 29-32
  - Tier 7: affix tiers 25-32
  - Tier 6: affix tiers 21-32
  - Tier 5: affix tiers 17-32
  - Tier 4: affix tiers 13-32
  - Tier 3: affix tiers 9-32
  - Tier 2: affix tiers 5-32
  - Tier 1: affix tiers 1-32
- Equal probability within the allowed range (no weighting toward worse affix tiers)
- Only new mod additions respect item tier (Tack, Forge, Claw, Grand)
- Tuning Hammer rerolls within the SAME affix tier that was originally rolled — unaffected by item tier

### Item tier visibility
- Hidden at P0 — tier display only appears after first prestige (P1+)
- Display format: text label after item name — "Light Sword (Rare) — T5"
- Card/stats panel only — item slot list buttons do NOT show tier
- No color coding or visual hierarchy for tier (just text)

### Claude's Discretion
- Exact bell curve parameters for drop tier weighting (sigma, centers per tier)
- How to wire tier constraint into add_prefix()/add_suffix() (implementation approach)
- Save format changes if needed (item.tier may already serialize)

</decisions>

<specifics>
## Specific Ideas

- Drop distribution should feel like a normal distribution for each tier, centered around its "home" area
- T8s centered around Forest (area 1-25), T7s around Dark Forest (25-50), etc.
- The overlap between tiers creates a smooth progression feel within each prestige level

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Item.tier` (item.gd:15): Already exists, used by `is_item_better()` in forge_view.gd:492
- `GameState.max_item_tier_unlocked` (game_state.gd:18): Set by prestige system, defaults to 8
- `ITEM_TIERS_BY_PRESTIGE` (prestige_manager.gd:20): Maps prestige level to max item tier — [8, 7, 6, 5, 4, 3, 2, 1]
- `LootTable` (loot_table.gd): Has biome-aware currency gating pattern that could inform tier weighting
- `Affixes.from_affix()` (item_affixes.gd:259): Clones affix templates — tier rolling happens in affix.gd constructor

### Established Patterns
- Area-gated drops: `CURRENCY_AREA_GATES` + `_calculate_currency_chance()` with sqrt ramp — pattern for progressive unlocks
- Affix tier range: `tier_range = Vector2i(1, 32)` — all affixes use uniform 32-tier range (Phase 37)
- Affix scaling formula: `value = base * (tier_range.y + 1 - tier)` — tier 1 = best, tier 32 = worst

### Integration Points
- `add_prefix()`/`add_suffix()` in item.gd: Must pass item tier to affix rolling to constrain tier range
- `_on_items_dropped()` in gameplay_view.gd: Creates items but doesn't assign tier — needs to roll item tier from weighted distribution
- `get_item_stats_text()` in forge_view.gd: Must conditionally show tier label (only at P1+)
- `save_manager.gd`: Item.tier may already serialize — verify before adding new save logic

</code_context>

<deferred>
## Deferred Ideas

- **Tier-specific base item variants**: Higher tiers need new base items with stronger base stats (e.g., "Mythic Sword" at tier 1 vs "Light Sword" at tier 8). Required for prestige to feel meaningful. Should be its own content phase.
- **Visual tier differentiation**: Color coding or icons per item tier — could enhance the system after base content exists.

</deferred>

---

*Phase: 38-item-tier-system*
*Context gathered: 2026-03-01*
