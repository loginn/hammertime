# Phase 46: Spell Damage Channel - Context

**Gathered:** 2026-03-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire spell damage through StatCalculator, Hero, and UI so that spell stats are tracked and displayed — without touching CombatEngine yet. Requirements: SPELL-03, SPELL-04, SPELL-05, SPELL-07.

</domain>

<decisions>
## Implementation Decisions

### Ring Spell Contribution
- Rings feed spell DPS via their FLAT_SPELL_DAMAGE implicit and affixes (e.g., Sapphire Ring)
- Rings do NOT gain base_spell_damage_min/max fields — they contribute through implicit/affixes only
- Rings CAN have base_cast_speed — Sapphire Ring should have a cast speed value
- Spell channel activates when total cast speed > 0 from ANY equipped gear — spells are character-driven, not weapon-gated
- A ring with cast speed can enable spell casting even without a spell weapon

### DPS Display Logic
- Show "Attack DPS" and "Spell DPS" as separate lines in Hero View
- Hide whichever channel is 0 (hide-zero logic)
- Rename existing "Total DPS" label to "Attack DPS"
- Per-element damage ranges stay unified (not split by channel)
- Section header always "Offense" regardless of active channels

### Crit Interaction
- Shared crit pool — one crit chance/damage applies to both attack and spell hits
- Fully independent speed calculations — spell DPS = spell_damage * cast_speed * crit_mult, attack DPS = attack_damage * attack_speed * crit_mult
- %Increased Spell Damage scales ALL spell element damage (global spell multiplier)

### Stat Comparison
- Equip comparison shows both channels separately: "Attack DPS: X -> Y" and "Spell DPS: X -> Y"
- Hide spell DPS comparison line when both old and new item have 0 spell DPS
- Keep tier-based auto-bench selection (is_item_better unchanged)
- Weapon tooltips show "Spell Damage: X to Y" and "Cast Speed: X" when base_spell_damage > 0

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- StatCalculator.calculate_dps() / calculate_damage_range(): Mirror these for spell equivalents
- Hero.damage_ranges dict pattern: Replicate as spell_damage_ranges
- Tag.FLAT_SPELL_DAMAGE, INCREASED_SPELL_DAMAGE, INCREASED_CAST_SPEED: Already exist (Phase 42)
- Spell damage affixes (flat + %): Already registered in item_affixes.gd (Phase 45)
- Cast speed suffix: Already registered in item_affixes.gd (Phase 45)
- Sapphire Ring: Already has FLAT_SPELL_DAMAGE implicit and SPELL valid_tag

### Established Patterns
- DPS calculation pipeline: flat damage → % damage → speed → crit multiplier
- Dual-accumulator per-element damage ranges in StatCalculator
- Hero caches ranges then computes DPS from averages
- ForgeView._update_hero_stats_display() builds stat text with non-zero filtering

### Integration Points
- Weapon.gd: Add base_spell_damage_min/max, base_cast_speed fields (defaulting to 0)
- Ring.gd: Add base_cast_speed field (defaulting to 0)
- StatCalculator: New calculate_spell_damage_range() and calculate_spell_dps() static methods
- Hero: New spell_damage_ranges dict, total_spell_dps, calculate methods
- ForgeView: Update hero stats display and stat comparison text

</code_context>

<specifics>
## Specific Ideas

- "Spells are a factor of the character, not the weapon. Some characters use spells, some use attacks." — User's framing for why ring cast speed can enable spells independently.
- Weapon tooltip format when spell damage present: "Damage: X to Y / Spell Damage: X to Y / Cast Speed: 1.2 / Crit: 5.0%"

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 46-spell-damage-channel*
*Context gathered: 2026-03-06*
