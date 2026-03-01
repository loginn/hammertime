# Phase 39: Tag-Targeted Currencies - Context

**Gathered:** 2026-03-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Five tag hammers (Fire, Cold, Lightning, Defense, Physical) that transform Normal items to Rare with at least one guaranteed matching-tag affix. Gated behind Prestige 1. Drop from packs at appropriate rates. This phase builds the tag hammer classes, drop integration, and forge UI — no new affix types or prestige mechanics.

</domain>

<decisions>
## Implementation Decisions

### Guaranteed Affix Logic
- At least 1 matching-tag affix guaranteed (roll all 4-6 randomly, then if none matched, replace one with a matching affix)
- Tag matching uses existing `Tag.FIRE`, `Tag.DEFENSE`, etc. constants — an affix matches if its `tags` array contains the hammer's tag
- Tag hammers respect item tier's affix floor (e.g., tier 8 item + Fire Hammer = fire affix from T29-32 only)
- If no matching affix exists for the item+tag combo, block application entirely via `can_apply()` returning false — no currency consumed

### Drop Rates & Area Gating
- All 5 tag hammer types unlock simultaneously at Prestige 1 (no progressive area unlock)
- Rare drop rate: 5-10% per pack (roughly 1 per 10-20 packs)
- Random equal chance among all 5 tag types when a drop occurs
- Drop quantity: mostly 1, small chance (10-20%) of 2 at higher areas

### Forge UI Layout
- Tag hammer buttons in a separate section below standard hammers, visual separator (gap/line) between sections, no header text
- Section completely hidden before P1 (not grayed out, fully absent)
- Button labels: "Fire Hammer (3)" — name + count, matching existing standard hammer button style

### No-Valid-Mods Feedback
- Reactive error: button stays clickable, shows toast/popup notification on failed click ("No fire-tagged mods available for this item")
- Auto-dismisses after 2-3 seconds
- Same Normal-rarity requirement as Forge Hammer — "already Rare" is a different reactive toast than "no valid mods"
- Both error types are reactive toasts, no preventive disabling

### Claude's Discretion
- Toast notification implementation (reuse existing system if one exists, or create minimal one)
- Exact drop rate within 5-10% range
- Exact chance threshold for quantity 2 drops
- Visual separator style between standard and tag hammer sections

</decisions>

<specifics>
## Specific Ideas

- Tag hammers are essentially Forge Hammer clones with an added constraint — subclass or parameterize from ForgeHammer
- PrestigeManager already has `TAG_TYPES: ["fire", "cold", "lightning", "defense", "physical"]` and `_grant_random_tag_currency()` — reuse this infrastructure
- `tag_currency_dropped` signal already exists in GameEvents

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ForgeHammer` (models/currencies/forge_hammer.gd): Template for Normal->Rare with 4-6 mods — tag hammers add guaranteed-tag constraint on top
- `Currency` base class (models/currencies/currency.gd): Template method pattern with `can_apply()` / `_do_apply()` — tag hammers extend this
- `GameState.tag_currency_counts`: Already initialized, saved/loaded, wiped on prestige
- `PrestigeManager.TAG_TYPES`: ["fire", "cold", "lightning", "defense", "physical"] already defined
- `GameEvents.tag_currency_dropped` signal: Already declared, ready to emit
- `SaveManager`: Already serializes/deserializes `tag_currency_counts`

### Established Patterns
- Currency class hierarchy: `Currency` base -> `ForgeHammer`, `RunicHammer`, etc. — tag hammers follow same pattern
- `LootTable.CURRENCY_AREA_GATES` + `_calculate_currency_chance()`: Existing gating system, though tag hammers use simpler P1 gate
- `forge_view.gd` currency dictionary + button wiring pattern: Add tag hammer entries to `currencies` dict, create new buttons
- `Item.add_prefix()` / `add_suffix()` already accept affix tier floor from `_get_affix_tier_floor()`
- `ItemAffixes.from_affix()` handles tier floor constraint — tag hammers filter by tag THEN use same roll mechanics

### Integration Points
- `LootTable.roll_pack_currency_drop()`: Add tag currency rolling after P1 check
- `forge_view.gd` `currencies` dict + button signals: Wire 5 new buttons
- `forge_view.gd` `update_currency_button_states()`: Read from `GameState.tag_currency_counts`
- `GameState.spend_currency()` / `add_currencies()`: May need tag-currency variants or unified approach
- `gameplay_view.gd` `_on_items_dropped()`: Where currency drops are processed — add tag currency handling

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 39-tag-targeted-currencies*
*Context gathered: 2026-03-01*
