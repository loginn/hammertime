# Phase 47: INT Weapons & Spell Combat - Context

**Gathered:** 2026-03-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Add 3 INT weapon bases (Wand, Lightning Rod, Sceptre) with 8 tier variants each, and wire the CombatEngine spell timer so spell-user heroes deal spell damage in combat. Requirements: BASE-04, SPELL-06.

</domain>

<decisions>
## Implementation Decisions

### Hero Spell/Attack Mode
- Hero has `is_spell_user` boolean (default false) — determines which combat channel is active
- CombatEngine uses ONE timer per hero: spell timer if `is_spell_user`, attack timer otherwise — never both
- Spell user deals damage exclusively from `spell_damage_ranges`; attack damage is ignored
- Default cast speed fallback of 1.0 when spell user has 0 total cast speed (mirrors attack speed fallback)
- Temporary dev toggle in settings view to flip spell/attack mode for manual testing — removed when hero archetypes ship

### INT Weapon Stats
- INT weapons have small but non-zero base_attack_damage (not pure caster — attackers CAN equip but it's suboptimal)
- INT weapons have small base_attack_speed (~0.5) for same reason
- Cast speeds: Wand ~1.2 (fast), Lightning Rod ~1.0 (medium), Sceptre ~0.8 (slow/heavy)
- Element-specific implicits using SEPARATE spell stat types:
  - Wand: FLAT_SPELL_DAMAGE (generic spell damage)
  - Lightning Rod: FLAT_SPELL_LIGHTNING_DAMAGE (new stat type)
  - Sceptre: FLAT_SPELL_FIRE_DAMAGE (new stat type)

### Spell Stat Types (New)
- Create separate spell-channel stat types: FLAT_SPELL_LIGHTNING_DAMAGE, FLAT_SPELL_FIRE_DAMAGE
- These are NOT shared with attack stat types (FLAT_LIGHTNING_DAMAGE, FLAT_FIRE_DAMAGE)
- Only spell-tagged sources (affixes/implicits with SPELL tag) feed into spell_damage_ranges
- Non-spell gear's elemental damage does NOT cross over into spell channel

### Spell Damage Rolling
- Per-element rolls from hero.spell_damage_ranges — mirrors exact pattern of _on_hero_attack()
- Roll each spell element independently, sum, then apply crit (shared crit pool)
- %Increased Spell Damage scales ALL spell elements uniformly (confirmed from Phase 46)

### Combat Feedback
- Spell hits shown in distinct color (purple/blue) in floating damage numbers
- New `hero_spell_hit` signal on GameEvents (separate from hero_attacked)
- Same crit visual treatment for both spell and attack crits
- No mode indicator in pack HP label or hero stats UI — floating text color is sufficient

### Claude's Discretion
- Exact base_damage_min/max values for INT weapons at each tier
- Exact base_attack_speed value for INT weapons (around 0.5)
- Specific purple/blue color value for spell hit floating text
- Internal data table structure for INT weapon tier stats
- All 24 tier-specific names (8 tiers x 3 weapon types)

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `combat_engine.gd`: Dual timer architecture (hero_attack_timer, pack_attack_timer). Add spell equivalent alongside, CombatEngine picks one based on is_spell_user.
- `_on_hero_attack()`: Per-element roll pattern to mirror for `_on_hero_spell_hit()`
- `_get_hero_attack_speed()`: Mirror as `_get_hero_cast_speed()` reading from Hero
- Weapon.gd: Already has base_spell_damage_min/max and base_cast_speed fields (Phase 46)
- StatCalculator: Already has calculate_spell_dps() and calculate_spell_damage_range() (Phase 46)
- Hero: Already has spell_damage_ranges dict and total_spell_dps (Phase 46)
- Phase 44 data-driven weapon pattern: 21 base classes with tier stats tables

### Established Patterns
- Weapon subclasses: extend Weapon, set stats in _init(tier), override get_item_type_string()
- 8-tier naming convention from Phase 44 (T8 weakest to T1 strongest)
- INT weapon valid_tags: [INT, SPELL, ELEMENTAL, ENERGY_SHIELD, WEAPON] (Phase 44)
- GameEvents signal pattern: signal declaration + emit in CombatEngine + connect in gameplay_view

### Integration Points
- `combat_engine.gd:63-68`: _start_pack_fight() — branch on is_spell_user to pick timer
- `combat_engine.gd:72-99`: _on_hero_attack() — mirror for _on_hero_spell_hit()
- `combat_engine.gd:212-216`: _get_hero_attack_speed() — mirror for cast speed
- `autoloads/game_events.gd`: Add hero_spell_hit signal
- `autoloads/tag.gd`: Add FLAT_SPELL_LIGHTNING_DAMAGE, FLAT_SPELL_FIRE_DAMAGE stat types
- `models/hero.gd`: Add is_spell_user boolean
- `scenes/gameplay_view.gd`: Connect hero_spell_hit signal for colored floating text
- `scenes/settings_view.gd` (or equivalent): Add dev toggle for is_spell_user
- `models/items/item.gd`: Add 3 new weapon types to ITEM_TYPE_STRINGS and create_from_dict

</code_context>

<specifics>
## Specific Ideas

- "Heroes use spells or attacks — weapons don't impact this choice." — User's framing for hero-level mode selection
- "The base hero in Prestige 1 uses attacks" — is_spell_user defaults to false
- Hero archetypes (picking a hero on prestige with spell/attack identity) is a future milestone feature — Phase 47 just adds the boolean foundation
- INT weapons are viable but suboptimal for attack-mode heroes (small attack damage/speed)

</specifics>

<deferred>
## Deferred Ideas

- Hero archetype selection on prestige (future milestone — PROJECT.md "Hero archetypes")
- Full prestige hero picker UI replacing the dev toggle
- Spell-specific % damage affixes per element (e.g., %Increased Spell Lightning Damage)

</deferred>

---

*Phase: 47-int-weapons-spell-combat*
*Context gathered: 2026-03-07*
