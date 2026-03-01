# Phase 37: Affix Tier Expansion - Context

**Gathered:** 2026-03-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Expand all affixes from mixed tier ranges (5/8/30) to a uniform 32-tier range. Retune base values for balanced scaling. Update is_item_better() to use tier-based comparison. No new affix types or mechanics — just tier expansion and rebalancing of existing affixes.

</domain>

<decisions>
## Implementation Decisions

### Power curve scaling
- Keep the existing LINEAR formula: `value = base * (tier_range.y + 1 - tier)`
- 32x spread at tier 1 is intentional — game difficulty increases exponentially, and other multiplicative systems (prestige, character progression) will stack on top
- Flat damage affixes keep the 4-bound scaling system (dmg_min_lo/hi, dmg_max_lo/hi) across 32 tiers
- Percentage-based affixes (%Physical Damage, %Armor, Attack Speed, etc.) use the same linear formula — large percentage values are fine
- Tier rolling remains fully random across the full tier_range (1-32). Phase 38 (Item Tier System) will add item_tier gating later

### Existing item migration
- IMPORTANT: There are no live players. Backward compatibility with old saves is not a concern. Ask at the start of each milestone if this has changed.
- Bump save version. If save version is older than current, create a new game (don't attempt migration)
- No proportional remapping or mixed-range logic needed

### Quality function / item comparison
- Do NOT add an affix.quality() function
- is_item_better() should compare using item_tier (a single value per item), NOT individual affix tiers
- Item tier comparison is primarily Phase 38's concern. Phase 37 focuses on affix tier expansion only
- For Phase 37, is_item_better() can continue using its current logic until Phase 38 introduces item_tier

### Base value retuning
- Full rebalance pass across ALL affixes (offensive and defensive) for 32-tier scaling
- Claude determines appropriate base_min/base_max values — user will review in the plan
- Preserve relative power flavor between damage types:
  - Lightning: widest spread (volatile, 1:4 ratio style)
  - Physical: tightest spread (consistent, 1:1.5 ratio style)
  - Fire: wide (1:2.5 ratio style)
  - Cold: moderate (1:2 ratio style)
- Disabled suffixes (Cast Speed, DoT, Bleed, Sigil, Dodge, etc.) remain disabled — no stat_type implementation exists yet

### Claude's Discretion
- Specific base_min/base_max values for each affix at 32 tiers
- Whether any affixes need special treatment beyond the standard linear formula
- How to handle the resistance affixes (currently 1-8 and 1-5 ranges) in the rebalance

</decisions>

<specifics>
## Specific Ideas

- The 32x power spread is deliberate — this is an incremental/idle ARPG where exponential difficulty scaling demands exponential power growth across systems
- Element damage types should retain their "character" (Lightning = wild swings, Physical = reliable)

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Affix` class (models/affixes/affix.gd): Already has tier_range as Vector2i, tier scaling formula in _init(), reroll(), to_dict()/from_dict() serialization
- `Affixes` autoload (autoloads/item_affixes.gd): Central registry of all prefix/suffix definitions — single file to update
- `Affixes.from_affix()`: Clone factory that passes all parameters including tier_range and damage bounds

### Established Patterns
- Tier scaling formula: `value = base * (tier_range.y + 1 - tier)` — tier 1 is best, higher tiers are worse
- Flat damage affixes use 4-bound system (dmg_min_lo/hi, dmg_max_lo/hi) with same tier multiplier
- Defensive prefixes already use 30-tier range — pattern exists for wide ranges
- Save format uses to_dict()/from_dict() with explicit tier_range_x/tier_range_y fields

### Integration Points
- `PrestigeManager.ITEM_TIERS_BY_PRESTIGE` maps prestige level to max_item_tier — currently 8 tiers, will need updating to 32
- `is_item_better()` in item comparison logic — currently uses stat values, Phase 38 will change to item_tier
- `SaveManager` save version check — bump version, new game on old save
- All crafting currencies that roll affixes (forge_hammer, runic_hammer, etc.) will automatically use new tier ranges since they create affixes from templates

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 37-affix-tier-expansion*
*Context gathered: 2026-03-01*
