# Phase 44: Item Bases (STR & DEX) - Context

**Gathered:** 2026-03-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Add 21 item base types across 5 equipment slots (3 archetypes x 7 slot-groups: 3 weapon subtypes + armor/helmet/boots/ring), with tiered variants (8 tiers each = 168 total named items). Each base has archetype-appropriate implicits and valid_tags. Existing items (LightSword, BasicArmor, etc.) are renamed to STR variants and replaced with data-driven classes. Save version bumped, old saves wiped.

</domain>

<decisions>
## Implementation Decisions

### Naming & Identity
- Existing items renamed to STR archetype names: LightSword -> Broadsword, BasicArmor -> Iron Plate, BasicHelmet -> Iron Helm, BasicBoots -> Iron Greaves, BasicRing -> Iron Band
- Use roadmap names for all 21 base types (Broadsword/Battleaxe/Warhammer, Dagger/Venom Blade/Shortbow, Iron Plate/Leather Vest/Silk Robe, etc.)
- Old class files (light_sword.gd, basic_armor.gd, etc.) deleted and replaced with new data-driven classes
- Item display shows tier-specific name only (e.g., "Bone Wand"), no archetype label (deferred to Phase 49 LOOT-04)

### Tiered Base Variants (168 items)
- Each of the 21 base types has 8 tier variants (T8 = weakest, T1 = strongest)
- Each tier variant has a unique thematic name (e.g., Wand: Driftwood Wand T8 -> ... -> Prophecy Wand T1)
- Claude generates all 168 names during research/planning
- Data-driven architecture: 21 base classes, each with a tier stats table in the constructor. Constructor takes tier param. NOT 168 separate class files.
- Implicit type is fixed per base type (Wand always = spell damage), implicit value scales with tier
- Defense bases (armor/helmet/boots): no implicit, base stats (base_armor, base_evasion, base_energy_shield) scale with tier

### Serialization
- Save stores base type + tier: `{"item_type": "Wand", "tier": 7}` — 21 match arms in create_from_dict, not 168
- Save version bumped to v6 in this phase (breaking change). Old v5 saves wiped on load.
- ITEM_TYPE_STRINGS registry updated with all 21 new type strings

### Implicit Design
- Weapons: each base type has a unique implicit type within its archetype. Same implicit type CAN appear across different archetypes (e.g., Broadsword STR and Shortbow DEX both have attack speed)
- Implicit value scales with tier (stronger at lower tier numbers)
- Ring implicits: Iron Band/attack damage, Jade Ring/crit, Sapphire Ring/spell damage — value scales with tier
- Defense bases: NO implicit. Defense comes from base_armor/base_evasion/base_energy_shield fields that scale with tier

### Valid Tags & Affix Access
- **STR weapons**: [STR, PHYSICAL, ATTACK, ARMOR, ELEMENTAL, WEAPON]
- **DEX weapons**: [DEX, PHYSICAL, ATTACK, CRITICAL, EVASION, ELEMENTAL, WEAPON, CHAOS]
- **INT weapons**: [INT, SPELL, ELEMENTAL, ENERGY_SHIELD, WEAPON] — no PHYSICAL, no ATTACK
- **STR defense** (armor/helmet/boots): [STR, DEFENSE, ARMOR] — only armor affixes + health + resistances
- **DEX defense**: [DEX, DEFENSE, EVASION] — only evasion affixes + health + resistances
- **INT defense**: [INT, DEFENSE, ENERGY_SHIELD] — only ES affixes + health + resistances
- **STR ring** (Iron Band): [STR, ATTACK, CRITICAL, SPEED, WEAPON]
- **DEX ring** (Jade Ring): [DEX, ATTACK, CRITICAL, SPEED, WEAPON, CHAOS]
- **INT ring** (Sapphire Ring): [INT, SPELL, SPEED, WEAPON]
- All defense bases keep DEFENSE tag for universal health + resistance access
- Chaos resistance available on all defense items (gated by DEFENSE tag)
- Chaos DAMAGE affixes DEX-exclusive (gated by CHAOS tag — only on DEX weapons + DEX ring)
- Tag-targeted hammers (Fire, Cold, Lightning, Defense, Physical) work on any item with matching tag — no archetype restriction
- Cast speed affix should use SPEED tag (accessible to all rings + relevant weapons)
- Dead mod rolls are acceptable — no need to prevent every bad combination

### Drop Distribution
- All 21 bases in drop pool immediately in Phase 44
- Slot-first-then-archetype distribution: pick random slot (20% each), then random archetype within slot (33% each)
- Starter weapon for new games: Broadsword T8 (STR)

### Claude's Discretion
- Class naming convention (thematic like `Broadsword` vs systematic like `StrWeapon1`) — Claude picks what's cleanest
- Internal data table structure for tier stats (Dictionary, Array, or match statement)
- Specific implicit values at each tier (scaling formula or hand-tuned table)
- All 168 tier-specific item names
- Base stat scaling formulas for defense items across tiers

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `models/items/item.gd`: Base Item class with serialization (to_dict/create_from_dict), affix system, rarity. 21 new classes extend this hierarchy.
- `models/items/weapon.gd`: Weapon base with damage fields, DPS calc via StatCalculator. STR/DEX/INT weapons extend this.
- `models/items/armor.gd`: Armor base with defense stat calculation (flat + percentage). Defense bases extend this.
- `models/items/helmet.gd`, `boots.gd`, `ring.gd`: Similar slot-specific base classes.
- `autoloads/tag.gd`: STR, DEX, INT, SPELL, CHAOS tags already added in Phase 42.
- `models/loot/loot_table.gd`: roll_item_tier() already handles tier distribution per area level.

### Established Patterns
- Concrete items extend slot base class (LightSword extends Weapon), override `_init()` and `get_item_type_string()`
- `_init()` sets item_name, tier, valid_tags, base stats, implicit, then calls `update_value()`
- `create_from_dict()` in item.gd is the deserialization registry (match on item_type string)
- `gameplay_view.gd:274` `get_random_item_base()` is the drop generation point — currently hardcoded 5-item array

### Integration Points
- `gameplay_view.gd:274-279`: get_random_item_base() needs slot-first-then-archetype rewrite
- `game_state.gd:70,108`: Starter weapon creation (LightSword.new() -> Broadsword.new())
- `item.gd:74-94`: ITEM_TYPE_STRINGS and create_from_dict match arms need all 21 types
- `save_manager.gd`: SAVE_VERSION constant bump from 5 to 6
- `prestige_manager.gd`: _wipe_run_state() initializes inventory — needs new starter weapon

</code_context>

<specifics>
## Specific Ideas

- Tiered item naming inspired by PoE progression (Driftwood -> Bone -> Carved -> etc.)
- Chaos/poison damage is DEX's signature mechanic — only DEX weapons and Jade Ring can roll chaos damage affixes
- All archetypes can defend against chaos (chaos resistance on all DEFENSE items)
- INT weapons excluded from physical damage but included in elemental damage via WEAPON + ELEMENTAL tags

</specifics>

<deferred>
## Deferred Ideas

- Archetype label on items (LOOT-04 — Phase 49)
- Spell damage affixes for INT weapons (AFF-01, AFF-02 — Phase 45)
- Combined DPS comparison across damage channels (LOOT-03 — Phase 49)

</deferred>

---

*Phase: 44-item-bases-str-dex*
*Context gathered: 2026-03-06*
