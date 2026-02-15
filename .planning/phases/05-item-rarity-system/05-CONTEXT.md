# Phase 5: Item Rarity System - Context

**Gathered:** 2026-02-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Add rarity tiers (Normal, Magic, Rare) to the item data model with affix count limits per tier and visual distinction via colored text. Items dropped from areas start as Normal. Crafting currencies that upgrade/modify rarity are Phase 6. Rarity-weighted drops are Phase 7. UI migration is Phase 8.

</domain>

<decisions>
## Implementation Decisions

### Existing item migration
- No migration needed — no save system, no persistent state. Items are session-only.
- Rip and replace: remove old hammer logic as soon as new system is ready, don't maintain parallel systems.
- Crafting can be temporarily broken between Phase 5 and Phase 6. Each phase tested against its own success criteria.

### Rarity display
- Colored name text only — no rarity prefix in the name (not "Magic Light Sword", just "Light Sword" in blue).
- Colors: Normal=white, Magic=blue, Rare=yellow. Claude picks specific shades for readability on dark background.
- Equipment slot buttons in hero_view also use rarity color based on equipped item's rarity.
- RARITY-06 (mod count display) is DROPPED — no mod count vs maximum shown. Rarity color alone communicates the tier.

### Mod limit enforcement
- Item class enforces mod limits based on its rarity tier. Any code path adding mods (hammers, drops, future systems) gets limit checking.
- Rarity defines default limits: Normal=0/0, Magic=1/1, Rare=3/3.
- Base types CAN override with optional custom_max_prefixes/custom_max_suffixes properties (defaults to null = use rarity defaults).
- For v1.0, no base types override — all use rarity defaults. Override mechanism exists for future exotic bases (e.g., Alchemist's Sword with 1/4 Rare limits).
- Configurable mapping for rarity → default limits (not hardcoded match statement).

### Item creation defaults
- All dropped item bases start as Normal (0 explicit mods, implicit only).
- Phase 5 changes item creation to produce clean Normal items — old random-affix-on-drop behavior removed.

### Claude's Discretion
- Error return mechanism when adding mod to full item (return bool vs error reason)
- Specific color hex values for rarity tiers
- Where to store the rarity → default limits mapping (autoload, resource, or enum)

</decisions>

<specifics>
## Specific Ideas

- Classic ARPG color coding: white/blue/yellow for Normal/Magic/Rare
- Future exotic bases like "Alchemist's Sword" should be able to have unusual affix limits (e.g., 1 prefix / 4 suffixes as Rare)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 05-item-rarity-system*
*Context gathered: 2026-02-15*
