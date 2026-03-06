# Stack Research: Item Archetypes (Str/Dex/Int), Spell Damage Channel, Cast Speed Timer, Affix Pool Expansion

**Domain:** Godot 4.5 Idle ARPG -- Adding 3 item bases per slot (str/dex/int), spell damage channel with cast timer, new affixes (spell damage, cast speed), and enabling disabled suffixes to existing v1.7 codebase
**Researched:** 2026-03-06
**Confidence:** HIGH (all patterns verified against existing codebase architecture and ARPG design conventions)

---

## Context

This is a **subsequent milestone stack** for v1.8. Godot 4.5, GDScript, Resource-based data model, StatCalculator with flat + percentage stacking, DefenseCalculator 4-stage pipeline, CombatEngine with dual attack timers, 18 prefix / 10 suffix affix pool with tag-based filtering, and item tier system (1-8) with 32 affix tiers are all in production.

The v1.8 content pass targets three axes of expansion:

| Feature | Primary Extension Point |
|---------|------------------------|
| 3 item bases per slot (str/dex/int) | New concrete `Item` subclasses alongside existing `BasicArmor`, `LightSword`, etc. `get_random_item_base()` expanded. `Item.create_from_dict()` registry expanded. |
| Spell damage channel with cast timer | New `StatType` entries, new timer in `CombatEngine`, new spell damage range tracking in `Hero`. |
| New affixes + enabling disabled suffixes | New entries in `ItemAffixes.prefixes`/`suffixes`, new `StatType` entries, `Tag` constants. |

---

## 1. New StatTypes Needed

### Current StatType Enum (19 entries)

The existing `Tag.StatType` enum covers attack damage, defense, and resistances. It has no spell-related entries.

### Required Additions

| New StatType | Purpose | Follows Pattern Of |
|---|---|---|
| `FLAT_SPELL_DAMAGE` | Flat added spell damage (min/max range, like `FLAT_DAMAGE`) | `FLAT_DAMAGE` |
| `INCREASED_SPELL_DAMAGE` | Percentage increased spell damage | `INCREASED_DAMAGE` |
| `INCREASED_CAST_SPEED` | Percentage increased cast speed (additive stacking) | `INCREASED_SPEED` |

These three are the minimum viable set. They mirror the attack damage trio (`FLAT_DAMAGE` / `INCREASED_DAMAGE` / `INCREASED_SPEED`) exactly, creating a clean symmetry.

### StatTypes for Enabled Disabled Suffixes

The disabled suffixes in `item_affixes.gd` (lines 247-255) have empty `stat_types` arrays. Enabling them requires:

| Disabled Suffix | Required StatType | Notes |
|---|---|---|
| Cast Speed | `INCREASED_CAST_SPEED` | New (see above). Tag: `[Tag.MAGIC]` |
| Damage over Time | `DOT_DAMAGE` (new) | Needs DoT tick system in CombatEngine. **Defer to future milestone** unless scope allows. |
| Bleed Damage | `BLEED_DAMAGE` (new) | Physical DoT subset. Same deferral concern. |
| Sigil | `FLAT_SIGIL` (new) | Undefined mechanic. **Defer.** |
| Evade | `FLAT_EVASION` | **Already exists.** Just needs correct `stat_types` array. |
| Physical Reduction | `PERCENT_PHYSICAL_REDUCTION` (new) | Overlaps with armor. Needs design decision. |
| Magical Reduction | `PERCENT_MAGICAL_REDUCTION` (new) | New defensive layer. Needs DefenseCalculator integration. |
| Dodge Chance | `DODGE_CHANCE` (new) | Separate from evasion-derived dodge? Or additive to evasion formula? |
| Dmg Suppression Chance | `SUPPRESSION_CHANCE` (new) | PoE-style 50% damage reduction on proc. Needs CombatEngine integration. |

**Recommendation for v1.8 scope:** Enable Cast Speed (uses new `INCREASED_CAST_SPEED`) and Evade (uses existing `FLAT_EVASION`). The others require new combat subsystems (DoT ticks, suppression rolls) that expand scope significantly.

### Summary: Minimum New StatType Entries

```
enum StatType {
    # ... existing 19 entries ...
    FLAT_SPELL_DAMAGE,        # 19
    INCREASED_SPELL_DAMAGE,   # 20
    INCREASED_CAST_SPEED,     # 21
}
```

This keeps the enum at 22 entries. Adding more for DoT/suppression later is backward-compatible since GDScript enums are integer-based and save format stores stat_types as arrays of ints.

---

## 2. New Tags Needed

### Current Tag Constants (19 entries)

The existing tag system uses string constants for affix filtering (`Tag.PHYSICAL`, `Tag.WEAPON`, `Tag.DEFENSE`, etc.) and an enum for stat routing (`Tag.StatType`).

### Required Tag Additions

| New Tag Constant | Purpose | Used By |
|---|---|---|
| `SPELL` | Marks spell-related affixes (spell damage, cast speed). Analogous to `ATTACK` for attack affixes. | Spell damage prefix/suffix tag filtering, item `valid_tags` on int-archetype items |
| `STR` | Strength archetype marker for items. Used in item `valid_tags` and potentially for tag-targeted hammers. | Str-archetype item bases |
| `DEX` | Dexterity archetype marker for items. | Dex-archetype item bases |
| `INT` | Intelligence archetype marker for items. | Int-archetype item bases |

### Tags NOT Needed

- No new element tags (fire/cold/lightning already exist and spell damage uses the same elements).
- No `CAST_SPEED` tag -- cast speed affixes use `Tag.SPELL` + `Tag.SPEED`, following the pattern of attack speed using `Tag.ATTACK` + `Tag.SPEED`.
- No archetype-specific damage tags -- spell damage uses element tags (fire/cold/lightning) same as attack damage.

### How Archetype Tags Interact with Valid Tags

Current items use `valid_tags` to control which affixes can roll. The archetype tags (`STR`/`DEX`/`INT`) serve two purposes:

1. **Item identity** -- which archetype pool the item belongs to for drop weighting and UI labeling.
2. **Affix filtering** -- archetype-specific affixes could use these tags to only appear on matching items. However, the simpler approach is to use existing tags (`Tag.ATTACK`, `Tag.SPELL`, `Tag.DEFENSE`) on the item's `valid_tags` to control affix pools. Archetype tags then serve primarily as metadata for the loot system.

**Recommendation:** Add `STR`, `DEX`, `INT` as item metadata tags. Use existing functional tags (`ATTACK`, `SPELL`, `DEFENSE`, `CRITICAL`, `SPEED`) in `valid_tags` arrays to control affix eligibility. This avoids duplicating affix filtering logic.

```gdscript
# tag.gd additions
const SPELL = "SPELL"
const STR = "STR"
const DEX = "DEX"
const INT = "INT"
```

---

## 3. Spell Damage Channel Implementation Patterns

### How ARPGs Implement Spell vs Attack Damage

In games like Path of Exile, Diablo, Last Epoch, and Grim Dawn, the fundamental pattern is:

**Two parallel damage pipelines that share some modifiers but have independent base values and scaling.**

| Aspect | Attack Channel | Spell Channel |
|---|---|---|
| Base damage source | Weapon base damage (min-max) | Skill gem / spell base damage (fixed or level-scaled) |
| Flat added damage | "Adds X to Y Physical Damage" (applies to attacks) | "Adds X to Y Fire Spell Damage" (applies to spells) |
| Percentage scaling | "Increased Attack Damage" | "Increased Spell Damage" |
| Speed modifier | Attack Speed (affects hits/sec) | Cast Speed (affects casts/sec) |
| Crit | Shared crit chance/damage pool (some games split this) | Same |
| Elemental damage | Shared % elemental damage applies to both | Same |

**Key design decision for idle games:** In a full ARPG, players choose skills. In an idle game, the hero auto-uses both channels simultaneously. This means:

1. **Both channels fire independently** on their own timers (attack timer and cast timer).
2. **Total DPS = Attack DPS + Spell DPS**, displayed separately or combined.
3. **Items specialize** -- str items boost attack, int items boost spell, but some affixes (elemental %, crit) are shared.

### Mapping to Existing Architecture

The current `CombatEngine` already has the dual-timer pattern with `hero_attack_timer` and `pack_attack_timer`. Adding a spell channel means:

**Option A: Third timer (spell_cast_timer)**
- CombatEngine gets a `spell_cast_timer` alongside `hero_attack_timer`.
- `_on_hero_spell_cast()` rolls spell damage ranges, applies crit, deals damage.
- Hero has `spell_damage_ranges` dict parallel to `damage_ranges`.
- Clean separation, easy to balance independently.

**Option B: Alternating timer (toggle between attack and spell)**
- Single hero timer alternates between attack and spell actions.
- Simpler but less flexible. Forces equal weighting.

**Option C: Combined timer with both damage types**
- Each hero "hit" includes both attack and spell components.
- Simplest but least interesting -- no cast speed vs attack speed tradeoff.

**Recommendation: Option A (third timer).** It mirrors the existing dual-timer pattern, gives spell-focused builds a distinct feel (faster casts = more spell hits), and allows interesting gearing decisions (stack attack speed OR cast speed, not both).

### Spell Damage Source

In the current system, attack damage comes from weapon base damage. Spell damage needs a base value source. Options:

1. **Weapon implicit/property** -- Int weapons could have `base_spell_damage_min`/`max` alongside `base_damage_min`/`max`. A "Wand" has high spell damage, low attack damage.
2. **Ring as spell damage source** -- Ring currently contributes attack damage. Could also contribute spell damage.
3. **Fixed base from hero level** -- Spell damage scales with progression, not gear. Less interesting for crafting.

**Recommendation:** Weapon is the spell damage source. Int-archetype weapons (e.g., "Wand") have `base_spell_damage_min`/`max` as their primary damage, with low/zero `base_damage_min`/`max`. Str weapons have the reverse. Dex weapons are attack-focused with higher crit/speed. This creates the classic ARPG archetype triangle.

### Hero Spell Damage Tracking

Parallel to existing `damage_ranges`:

```gdscript
# hero.gd additions
var spell_damage_ranges: Dictionary = {
    "physical": {"min": 0.0, "max": 0.0},
    "fire": {"min": 0.0, "max": 0.0},
    "cold": {"min": 0.0, "max": 0.0},
    "lightning": {"min": 0.0, "max": 0.0},
}
var total_spell_dps: float = 0.0
var base_cast_speed: float = 0.0  # From weapon, 0 = no spells
```

### StatCalculator Extensions

A new `calculate_spell_damage_range()` static function paralleling `calculate_damage_range()`, reading `FLAT_SPELL_DAMAGE` and `INCREASED_SPELL_DAMAGE` instead of `FLAT_DAMAGE` and `INCREASED_DAMAGE`. Percentage elemental modifiers (`%Elemental Damage`) should apply to **both** attack and spell elemental damage -- this is standard ARPG behavior and creates interesting shared scaling.

### Shared vs Separate Modifiers

| Modifier | Applies To | Rationale |
|---|---|---|
| `%Physical Damage` | Attack only | Physical spells are rare in ARPGs; keeps str identity clear |
| `%Elemental Damage` | Both attack and spell | Standard ARPG. Makes elemental % universally valuable. |
| `%Fire/Cold/Lightning Damage` | Both attack and spell | Same element, same scaling. |
| `%Spell Damage` (new) | Spell only | Int-archetype scaling. |
| `%Attack Damage` (could add) | Attack only | Would need new `INCREASED_ATTACK_DAMAGE` StatType. **Defer** -- current `INCREASED_DAMAGE` serves this role via tag filtering. |
| Crit Chance / Crit Damage | Both | Shared crit pool is simpler and still creates interesting choices. |
| Attack Speed | Attack only | Timer cadence for attacks. |
| Cast Speed (new) | Spell only | Timer cadence for spells. |

**Implementation note:** The current `INCREASED_DAMAGE` applies to attack damage via `calculate_dps()`. With spell damage added, `INCREASED_DAMAGE` should remain attack-only, and `INCREASED_SPELL_DAMAGE` handles spells. Shared elemental scaling works through the existing tag system -- `%Elemental Damage` affixes with `Tag.ELEMENTAL` tag apply when calculating both attack and spell ranges, since `calculate_damage_range()` and the new `calculate_spell_damage_range()` both check for `INCREASED_DAMAGE` / `INCREASED_SPELL_DAMAGE` respectively, plus a shared elemental multiplier bucket.

---

## 4. Cast Speed Timer Considerations

### Current Attack Timer Architecture

```
CombatEngine._start_pack_fight():
    hero_attack_timer.wait_time = 1.0 / hero_attack_speed
    hero_attack_speed comes from Weapon.base_attack_speed (e.g., 1.8 for LightSword)
```

Attack speed affixes (`INCREASED_SPEED`) modify DPS calculation in `StatCalculator.calculate_dps()` but do NOT currently change the combat timer cadence. The `base_attack_speed` is a separate field from the DPS `base_speed` multiplier. This is documented as a deliberate design decision: "base_attack_speed separate from base_speed -- Combat timer cadence (hits/sec) vs DPS multiplier are distinct concepts."

### Cast Speed Timer Design

Two approaches:

**Approach A: Cast speed modifies timer cadence (like base_attack_speed)**
- `base_cast_speed` on weapon (e.g., Wand has 1.2 casts/sec).
- `INCREASED_CAST_SPEED` affixes modify the actual timer: `spell_cast_timer.wait_time = 1.0 / (base_cast_speed * (1.0 + cast_speed_bonus))`.
- Cast speed affixes directly change how often spells fire in combat.
- More impactful, more interesting gearing choice.

**Approach B: Cast speed is DPS multiplier only (like current base_speed)**
- Cast speed scales spell DPS in calculation but timer stays fixed.
- Simpler but less satisfying -- player doesn't "see" the speed change.

**Recommendation: Approach A.** Cast speed should modify the actual combat timer, making it a visible and feelable stat. This departs from how attack speed currently works (DPS multiplier only), but it is the more engaging design for the player. Consider later retrofitting attack speed affixes to also modify the attack timer for consistency.

### Implementation Pattern

```gdscript
# In CombatEngine
var spell_cast_timer: Timer

func _ready() -> void:
    # ... existing timers ...
    spell_cast_timer = Timer.new()
    spell_cast_timer.one_shot = false
    add_child(spell_cast_timer)
    spell_cast_timer.timeout.connect(_on_hero_spell_cast)

func _start_pack_fight() -> void:
    # Existing attack timer
    hero_attack_speed = _get_hero_attack_speed()
    hero_attack_timer.wait_time = 1.0 / hero_attack_speed

    # New spell timer (only if hero has spell capability)
    var cast_speed := _get_hero_cast_speed()
    if cast_speed > 0.0:
        spell_cast_timer.wait_time = 1.0 / cast_speed
        spell_cast_timer.start()

func _on_hero_spell_cast() -> void:
    # Mirror of _on_hero_attack() but reading spell_damage_ranges
    # Same crit roll pattern, same pack.take_damage() call
    pass

func _get_hero_cast_speed() -> float:
    var weapon = GameState.hero.equipped_items.get("weapon")
    if weapon != null and weapon is Weapon and weapon.base_cast_speed > 0.0:
        # Apply cast speed modifiers from affixes
        var all_affixes: Array = weapon.prefixes.duplicate()
        all_affixes.append_array(weapon.suffixes)
        if weapon.implicit:
            all_affixes.append(weapon.implicit)
        var additive_cast_speed_mult := 0.0
        for affix: Affix in all_affixes:
            if Tag.StatType.INCREASED_CAST_SPEED in affix.stat_types:
                additive_cast_speed_mult += affix.value / 100.0
        return weapon.base_cast_speed * (1.0 + additive_cast_speed_mult)
    return 0.0
```

### Timer Interaction with Pack Death

When the pack dies, both timers stop (existing `_stop_timers()` expands to include `spell_cast_timer.stop()`). No interaction issues -- timers are independent.

### Edge Case: Zero Spell Damage

If `base_cast_speed == 0.0` (str/dex weapons), the spell timer never starts. The hero is attack-only. This is clean -- no special-case branching needed in combat logic beyond the initial `cast_speed > 0.0` check.

### Edge Case: Zero Attack Damage

If a Wand has `base_damage_min == 0` / `base_damage_max == 0`, the attack timer still fires but deals 0 damage (affixes might add flat attack damage). Alternatively, the attack timer could skip when base attack damage is zero. Recommendation: still fire it -- flat damage affixes on an int weapon should work, just be suboptimal.

---

## 5. Recommendations for This Project

### 5.1 Item Archetype Design (3 per slot)

Each equipment slot gets 3 concrete subclasses. All share the same abstract parent (Weapon, Armor, Helmet, Boots, Ring) and the same `update_value()` pipeline. They differ in:

- `item_name` and `get_item_type_string()`
- Base stat values (base_armor, base_evasion, base_energy_shield, etc.)
- `valid_tags` array (controls which affixes can roll)
- Implicits (archetype-defining built-in stats)
- For weapons: `base_damage_min/max`, `base_spell_damage_min/max`, `base_attack_speed`, `base_cast_speed`

**Weapon Slot:**

| Archetype | Class Name | Identity | Key Base Stats | Key Valid Tags |
|---|---|---|---|---|
| Str | `GreatSword` | Slow, high phys damage | high base_damage, low base_attack_speed (0.8), no spell | `[PHYSICAL, ATTACK, CRITICAL, WEAPON, STR]` |
| Dex | `LightSword` (existing) | Fast, moderate damage | moderate base_damage, high base_attack_speed (1.8) | `[PHYSICAL, ATTACK, CRITICAL, WEAPON, DEX]` (add DEX) |
| Int | `Wand` | Spell-focused | low/zero base_damage, base_spell_damage, base_cast_speed (1.4) | `[SPELL, ELEMENTAL, CRITICAL, WEAPON, INT]` |

**Armor Slot:**

| Archetype | Class Name | Identity | Key Base Stats | Key Valid Tags |
|---|---|---|---|---|
| Str | `PlateArmor` | High armor | high base_armor | `[DEFENSE, ARMOR, STR]` |
| Dex | `LeatherArmor` | Evasion | base_evasion, some armor | `[DEFENSE, EVASION, DEX]` |
| Int | `RobeArmor` | Energy shield | base_energy_shield | `[DEFENSE, ENERGY_SHIELD, INT]` |

**Helmet Slot:**

| Archetype | Class Name | Identity | Key Base Stats |
|---|---|---|---|
| Str | `GreatHelm` | High armor, health | base_armor, base_health |
| Dex | `LeatherHood` | Evasion | base_evasion |
| Int | `CircletHelmet` | ES, mana | base_energy_shield, base_mana |

**Boots Slot:**

| Archetype | Class Name | Identity | Key Base Stats |
|---|---|---|---|
| Str | `PlateBoots` | Armor | base_armor |
| Dex | `LeatherBoots` | Evasion, movement speed | base_evasion, higher movement speed implicit |
| Int | `SilkSlippers` | ES | base_energy_shield |

**Ring Slot:**

| Archetype | Class Name | Identity | Key Valid Tags |
|---|---|---|---|
| Str | `IronRing` | Attack damage | `[ATTACK, CRITICAL, WEAPON, STR]` |
| Dex | `BasicRing` (existing) | Crit, speed | `[ATTACK, CRITICAL, SPEED, WEAPON, DEX]` (add DEX) |
| Int | `SapphireRing` | Spell damage, can contribute spell DPS | `[SPELL, CRITICAL, WEAPON, INT]` |

### 5.2 Affix Pool Expansion

**New Prefixes:**

| Affix Name | Type | Tags | StatTypes | Notes |
|---|---|---|---|---|
| Flat Spell Damage | PREFIX | `[SPELL, FLAT, WEAPON]` | `[FLAT_SPELL_DAMAGE]` | Mirror of "Physical Damage". Needs dmg range params. |
| %Spell Damage | PREFIX | `[SPELL, PERCENTAGE, WEAPON]` | `[INCREASED_SPELL_DAMAGE]` | Mirror of "%Physical Damage". |

**New/Enabled Suffixes:**

| Affix Name | Type | Tags | StatTypes | Status |
|---|---|---|---|---|
| Cast Speed | SUFFIX | `[SPEED, SPELL]` | `[INCREASED_CAST_SPEED]` | Currently disabled. Enable with correct stat_types. |
| Evade | SUFFIX | `[DEFENSE, EVASION]` | `[FLAT_EVASION]` | Currently disabled. Enable with existing StatType. Fix tags (remove WEAPON). |

**Suffixes to Remain Disabled (v1.8):**
- Damage over Time, Bleed Damage -- need DoT tick system
- Sigil -- undefined mechanic
- Physical Reduction, Magical Reduction -- need DefenseCalculator integration design
- Dodge Chance -- needs design decision (additive to evasion or separate roll?)
- Dmg Suppression Chance -- needs CombatEngine suppression roll

### 5.3 Serialization / Save Format Impact

- New `StatType` enum entries are backward-compatible (integer IDs append to end).
- New item type strings (`GreatSword`, `Wand`, `PlateArmor`, etc.) require expanding `Item.create_from_dict()` match statement and `ITEM_TYPE_STRINGS` array.
- `Weapon` class gains `base_spell_damage_min`, `base_spell_damage_max`, `base_cast_speed` fields. Default values of 0 make old saves compatible (no spell damage = attack-only).
- Save format version bump (v4 -> v5) is warranted for the new item types. Old items in save files will fail `create_from_dict()` match -- recommend wiping inventories on version mismatch (precedent: v2/v3 wipe decision).

### 5.4 Loot Table Changes

`get_random_item_base()` currently picks uniformly from 5 types. With 15 types (3 per slot), options:

1. **Uniform across all 15** -- equal chance of any base. Simple, may flood with one archetype.
2. **Pick slot first, then archetype** -- uniform slot selection (1/5), then uniform archetype within slot (1/3). Guarantees even slot distribution.
3. **Weighted by area/biome** -- str items more common in Forest, int items in Shadow Realm. Thematic but complex.

**Recommendation:** Option 2 (pick slot, then archetype). Maintains current slot distribution behavior and is trivial to implement.

### 5.5 Hero DPS Display

Currently Hero View shows a single `total_dps`. With spell DPS added:

- Show `Attack DPS` and `Spell DPS` separately in offense section.
- Show `Total DPS` as sum.
- This mirrors the existing offense/defense split pattern in Hero View.

### 5.6 Implementation Order

Recommended phasing to minimize risk:

1. **Tag + StatType additions** -- add new constants/enum values. Zero behavior change. All tests pass.
2. **New item base classes** -- add 10 new concrete subclasses (2 new per slot, existing ones become the "dex" or "str" variant). Update `get_random_item_base()`, `create_from_dict()`, `ITEM_TYPE_STRINGS`.
3. **Spell damage affixes** -- add flat/% spell damage prefixes, enable cast speed suffix.
4. **Weapon spell damage fields** -- add `base_spell_damage_min/max` and `base_cast_speed` to `Weapon`. Wand class uses them.
5. **StatCalculator spell range function** -- `calculate_spell_damage_range()` parallel to `calculate_damage_range()`.
6. **Hero spell stat tracking** -- `spell_damage_ranges`, `total_spell_dps`, `calculate_spell_dps()`.
7. **CombatEngine spell timer** -- third timer, `_on_hero_spell_cast()`, `_get_hero_cast_speed()`.
8. **UI updates** -- Hero View offense section shows attack/spell DPS. Weapon tooltip shows spell damage range.
9. **Enable remaining safe suffixes** -- Evade suffix.
10. **Save format migration** -- v5 format, inventory wipe path for old item types.

### 5.7 What NOT to Do

- **Do not create a separate SpellWeapon class.** Keep spell fields on `Weapon` base class with 0 defaults. Wand is a Weapon subclass like LightSword. This avoids branching everywhere that checks `item is Weapon`.
- **Do not split crit into attack crit / spell crit.** Shared crit pool is simpler, still creates interesting choices, and reduces StatType proliferation.
- **Do not make %Elemental Damage attack-only.** In every major ARPG, elemental scaling applies to all damage sources of that element. Spell fire damage and attack fire damage both scale from %Fire Damage.
- **Do not add a mana cost system.** The game has `FLAT_MANA` stat but no mana consumption mechanic. Spells auto-cast on timer with no resource cost -- this is consistent with the idle genre (attacks also have no cost).
- **Do not change existing LightSword/BasicRing to dex archetype yet in the same PR that adds spell.** Changing existing item class names/identities breaks saves. Instead, add the dex tag to existing classes and create new str/int variants alongside them.

---

## File Touch Points Summary

| File | Change Type | Scope |
|---|---|---|
| `autoloads/tag.gd` | Add `SPELL`, `STR`, `DEX`, `INT` constants + 3 StatType enum values | Small |
| `autoloads/item_affixes.gd` | Add 2 spell damage prefixes, enable Cast Speed + Evade suffixes | Small |
| `models/items/weapon.gd` | Add `base_spell_damage_min`, `base_spell_damage_max`, `base_cast_speed` fields | Small |
| `models/items/` | Add 10 new concrete item subclasses | Medium (repetitive) |
| `models/items/item.gd` | Expand `create_from_dict()` match + `ITEM_TYPE_STRINGS` | Small |
| `models/stats/stat_calculator.gd` | Add `calculate_spell_damage_range()` | Small |
| `models/hero.gd` | Add `spell_damage_ranges`, `total_spell_dps`, `calculate_spell_dps()`, `calculate_spell_damage_ranges()` | Medium |
| `models/combat/combat_engine.gd` | Add `spell_cast_timer`, `_on_hero_spell_cast()`, `_get_hero_cast_speed()` | Medium |
| `scenes/gameplay_view.gd` | Expand `get_random_item_base()` to 15 item types | Small |
| `scenes/forge_view.gd` | UI for spell DPS display, weapon spell damage tooltip | Medium |
| `autoloads/save_manager.gd` | Save format v5, migration path | Small |

---
*Last updated: 2026-03-06*
