# Phase 9: Defensive Prefix Foundation - Context

**Gathered:** 2026-02-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Add defensive prefix affixes to non-weapon items (armor, boots, helmet). Items gain craftable armor/evasion/energy shield prefixes that display stats. Defense type is determined by base item type. Combat integration is deferred. Also adds utility prefixes (+Life, +Mana, +% Life) to expand non-weapon crafting options.

</domain>

<decisions>
## Implementation Decisions

### Defense distribution
- Defense type is tied to base item type, not item slot (e.g., leather armor = evasion, mage robe = energy shield)
- Current basic items (basic armor, basic boots, basic helmet) all roll armor prefixes (flat armor + % armor) since they represent simple physical protection
- Rings get NO defensive prefixes — they are accessory slots, not armor
- Tag system must be designed to support future base types mapping to different defense types

### Value ranges & scaling
- Defensive prefixes follow the existing tier system: tiers gated by item level (from area level), with higher-rank tiers weighted rarer
- Tier numbering: T1 = best (highest values, hardest to roll), T30 = worst (lowest values, easiest to roll) — players immediately know quality
- Target 30+ tiers for defensive prefixes to support idle game bulk-crafting depth
- Both flat and percentage-based defenses available from tier 1 (no tier-gating % defenses)
- Tier details (tier number, ranges) shown on a toggle — clean default view, detailed on demand
- Claude's discretion on specific numerical ranges, calibrated against existing offensive affix values

### Display-only treatment
- No visual distinction for "display only" stats — show defensive stats normally (no gray text, no labels)
- Hero View gets a separate defense section (not mixed with offense stats)
- Hero View defense section shows aggregate totals from all equipped items
- Only show non-zero defense types in Hero View (don't show Armor: 0, Evasion: 0 etc.)

### Affix pool balance
- Rare armor items (3 prefix slots) can stack multiple defensive prefixes (e.g., flat armor + % armor on same piece)
- Also adding utility prefixes: +Life, +Mana, +% Life for non-weapon items
- Claude's discretion on whether utility prefixes (+Life, +Mana, +% Life) also roll on weapons

### Claude's Discretion
- Specific flat/% armor value ranges per tier (calibrate against existing offensive values)
- Whether +Life, +Mana, +% Life roll on weapons or non-weapons only
- Tier toggle UI implementation details
- Tag taxonomy naming conventions

</decisions>

<specifics>
## Specific Ideas

- Defense type tied to base item archetype, like Path of Exile (armor base = armor, leather = evasion, robe = ES)
- T1 = best tier convention — players don't need to guess max tier count, lower number always means better
- 30+ tiers for idle game depth where players will eventually bulk-craft and keep best results
- The whole system should be designed so adding new base types later automatically slots them into the right defense pool via tags

</specifics>

<deferred>
## Deferred Ideas

- Multiple base types per slot (leather armor, mage robe, etc.) — future phase for expanding base item variety
- Expand existing offensive affix tiers to 30+ (currently 8 tiers) — separate task to align offensive with new defensive tier depth
- Advanced mod info toggle UI (showing tier numbers, value ranges) — could be its own UI enhancement phase

</deferred>

---

*Phase: 09-defensive-prefix-foundation*
*Context gathered: 2026-02-15*
