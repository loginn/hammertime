# Phase 44: Item Bases (STR & DEX) — Research

**Date:** 2026-03-06
**Phase:** 44-item-bases-str-dex
**Requirements:** BASE-01, BASE-02, BASE-03, BASE-05, BASE-06, BASE-07, BASE-08, BASE-09, BASE-10

---

## Current Architecture Analysis

### Item Class Hierarchy

```
Item (Resource)                    # models/items/item.gd
├── Weapon                         # models/items/weapon.gd
│   └── LightSword                 # models/items/light_sword.gd (to be replaced)
├── Armor                          # models/items/armor.gd
│   └── BasicArmor                 # models/items/basic_armor.gd (to be replaced)
├── Helmet                         # models/items/helmet.gd
│   └── BasicHelmet                # models/items/basic_helmet.gd (to be replaced)
├── Boots                          # models/items/boots.gd
│   └── BasicBoots                 # models/items/basic_boots.gd (to be replaced)
└── Ring                           # models/items/ring.gd
    └── BasicRing                  # models/items/basic_ring.gd (to be replaced)
```

### Concrete Item Pattern (Exemplar: LightSword)

Each concrete item class:
1. Extends its slot base class (`LightSword extends Weapon`)
2. Overrides `get_item_type_string()` returning a unique string for serialization
3. In `_init()`: sets item_name, tier, valid_tags, base stats, implicit (or null), then calls `update_value()`
4. Hardcoded to tier 8 values — no tier-scaling in constructor

**Problem:** Current items are fixed at tier 8 with hardcoded stats. The new data-driven architecture needs a `tier` parameter in `_init()` that selects from a tier stats table.

### Serialization Registry (item.gd)

```gdscript
const ITEM_TYPE_STRINGS: PackedStringArray = [
    "LightSword", "BasicArmor", "BasicHelmet", "BasicBoots", "BasicRing"
]

static func create_from_dict(data: Dictionary) -> Item:
    match item_type_str:
        "LightSword": item = LightSword.new()
        "BasicArmor": item = BasicArmor.new()
        # ... etc
```

After construction, `create_from_dict` restores tier, rarity, implicit, prefixes, suffixes, then calls `update_value()`. The tier is restored via `item.tier = int(data.get("tier", 8))`, but this does NOT re-run `_init()` with that tier — it just overwrites the field.

**Key insight for data-driven items:** The new classes must accept a tier parameter: `Broadsword.new(tier)`. The `create_from_dict` flow becomes: construct with default tier -> restore tier from save -> restore affixes -> `update_value()`. BUT if the constructor uses tier to set base stats (damage, defense), we need the constructor's tier to match the saved tier. Two approaches:

1. **Tier parameter in constructor:** `create_from_dict` calls `Broadsword.new(saved_tier)` — requires passing tier to constructor in the match arm
2. **Post-construction tier setter:** Constructor uses tier 8 default, then `create_from_dict` sets `item.tier` and re-derives base stats

Approach 1 is cleaner. The `create_from_dict` needs to extract tier before constructing. The current flow already extracts tier at line 102: `item.tier = int(data.get("tier", 8))`. We can pre-extract tier and pass it:

```gdscript
var tier_val: int = int(data.get("tier", 8))
match item_type_str:
    "Broadsword": item = Broadsword.new(tier_val)
```

Then skip the subsequent `item.tier = ...` line (or let it harmlessly re-set the same value).

### Drop Generation (gameplay_view.gd:274-281)

```gdscript
func get_random_item_base() -> Item:
    var item_types = [LightSword, BasicHelmet, BasicArmor, BasicBoots, BasicRing]
    var random_type = item_types[randi() % item_types.size()]
    var item = random_type.new()
    item.tier = LootTable.roll_item_tier(GameState.area_level, GameState.max_item_tier_unlocked)
    return item
```

**Problem:** Hardcoded array of 5 types. Must be replaced with slot-first-then-archetype logic per context decisions. Also, tier is set AFTER construction — new data-driven items need tier at construction.

**New flow:**
1. Pick random slot (20% each): weapon, armor, helmet, boots, ring
2. Pick random archetype (33% each): STR, DEX, INT (but only STR/DEX for weapons in Phase 44; INT weapons deferred to Phase 47)
3. Roll tier via `LootTable.roll_item_tier()`
4. Construct the appropriate class with the tier

### Tag System (autoloads/tag.gd)

All needed tags exist: STR, DEX, INT, PHYSICAL, ATTACK, CRITICAL, WEAPON, DEFENSE, ARMOR, EVASION, ENERGY_SHIELD, ELEMENTAL, SPELL, CHAOS, SPEED.

All needed StatTypes exist: FLAT_DAMAGE, INCREASED_DAMAGE, INCREASED_SPEED, CRIT_CHANCE, FLAT_ARMOR, FLAT_EVASION, FLAT_ENERGY_SHIELD, FLAT_HEALTH, PERCENT_ARMOR, PERCENT_EVASION, PERCENT_ENERGY_SHIELD, BLEED_DAMAGE, POISON_DAMAGE.

No new tags or stat types needed for Phase 44.

### Affix System (autoloads/item_affixes.gd)

The `has_valid_tag()` function on Item checks if ANY of the item's valid_tags match ANY of the affix's tags. This is the gating mechanism.

Current affix tags analysis (relevant for valid_tags design):
- **Flat Armor prefix:** tags = [DEFENSE, PHYSICAL, ARMOR]
- **%Armor prefix:** tags = [DEFENSE, PHYSICAL, ARMOR]
- **Evasion prefix:** tags = [DEFENSE, EVASION]
- **%Evasion prefix:** tags = [DEFENSE, EVASION]
- **Energy Shield prefix:** tags = [DEFENSE, ENERGY_SHIELD]
- **%Energy Shield prefix:** tags = [DEFENSE, ENERGY_SHIELD]
- **Health prefix:** tags = [DEFENSE, UTILITY]
- **%Health prefix:** tags = [DEFENSE, UTILITY]
- **Physical Damage prefix:** tags = [PHYSICAL, FLAT, WEAPON]
- **%Physical Damage prefix:** tags = [PHYSICAL, PERCENTAGE, WEAPON]
- **Elemental prefixes:** tags = [ELEMENTAL, ...]
- **Crit suffixes:** tags = [CRITICAL]
- **Resistance suffixes:** tags = [DEFENSE, element, WEAPON]
- **Attack Speed suffix:** tags = [SPEED, ATTACK, PHYSICAL, WEAPON]

**Important observation:** Resistance suffixes have DEFENSE tag, so any item with DEFENSE in valid_tags can roll resistances. Health/mana prefixes also use DEFENSE tag. This matches the context decision: "All defense bases keep DEFENSE tag for universal health + resistance access."

### Defense total_defense Calculation

Currently in armor.gd, helmet.gd, boots.gd:
```gdscript
self.total_defense = self.computed_armor
```

This only tracks armor. For DEX/INT bases with evasion/ES as primary defense, `total_defense` should reflect the primary defense stat. **This needs updating:** each defense base should set `total_defense` to its primary stat (armor for STR, evasion for DEX, energy_shield for INT).

### Starter Weapon and Prestige

- `game_state.gd:70` — `initialize_fresh_game()` creates `LightSword.new()` as starter weapon
- `game_state.gd:108` — `_wipe_run_state()` also creates `LightSword.new()`
- Both must change to `Broadsword.new(8)` (tier 8 STR weapon)

### Forge View Item Type Detection

```gdscript
func get_item_type(item: Item) -> String:
    if item is Weapon: return "weapon"
    elif item is Helmet: return "helmet"
    # etc.
```

Uses `is` checks against base classes (Weapon, Armor, Helmet, Boots, Ring). Since new items extend these base classes, **no changes needed** in forge_view for slot detection.

### Save Version

Current: `SAVE_VERSION = 5` in `save_manager.gd:4`. Must bump to 6 per context decisions.

---

## Files That Need Modification

### Files to DELETE (5)
| File | Reason |
|------|--------|
| `models/items/light_sword.gd` | Replaced by Broadsword |
| `models/items/basic_armor.gd` | Replaced by IronPlate |
| `models/items/basic_boots.gd` | Replaced by IronGreaves |
| `models/items/basic_helmet.gd` | Replaced by IronHelm |
| `models/items/basic_ring.gd` | Replaced by IronBand |

### Files to CREATE (21 new item classes)

All in `models/items/`:

**Weapons (6):**
| File | Class | Extends | Archetype |
|------|-------|---------|-----------|
| `broadsword.gd` | Broadsword | Weapon | STR |
| `battleaxe.gd` | Battleaxe | Weapon | STR |
| `warhammer.gd` | Warhammer | Weapon | STR |
| `dagger.gd` | Dagger | Weapon | DEX |
| `venom_blade.gd` | VenomBlade | Weapon | DEX |
| `shortbow.gd` | Shortbow | Weapon | DEX |

**Armors (3):**
| File | Class | Extends | Archetype |
|------|-------|---------|-----------|
| `iron_plate.gd` | IronPlate | Armor | STR |
| `leather_vest.gd` | LeatherVest | Armor | DEX |
| `silk_robe.gd` | SilkRobe | Armor | INT |

**Helmets (3):**
| File | Class | Extends | Archetype |
|------|-------|---------|-----------|
| `iron_helm.gd` | IronHelm | Helmet | STR |
| `leather_hood.gd` | LeatherHood | Helmet | DEX |
| `circlet.gd` | Circlet | Helmet | INT |

**Boots (3):**
| File | Class | Extends | Archetype |
|------|-------|---------|-----------|
| `iron_greaves.gd` | IronGreaves | Boots | STR |
| `leather_boots.gd` | LeatherBoots | Boots | DEX |
| `silk_slippers.gd` | SilkSlippers | Boots | INT |

**Rings (3):**
| File | Class | Extends | Archetype |
|------|-------|---------|-----------|
| `iron_band.gd` | IronBand | Ring | STR |
| `jade_ring.gd` | JadeRing | Ring | DEX |
| `sapphire_ring.gd` | SapphireRing | Ring | INT |

### Files to MODIFY (5)
| File | Changes |
|------|---------|
| `models/items/item.gd` | Update ITEM_TYPE_STRINGS (21 entries), rewrite create_from_dict (21 match arms, pass tier), update total_defense display logic |
| `scenes/gameplay_view.gd` | Rewrite get_random_item_base() with slot-first-then-archetype logic, pass tier to constructor |
| `autoloads/game_state.gd` | Change LightSword.new() to Broadsword.new(8) in both initialize_fresh_game() and _wipe_run_state() |
| `autoloads/save_manager.gd` | Bump SAVE_VERSION from 5 to 6 |
| `tools/test/integration_test.gd` | Update all LightSword references to Broadsword, add tests for all 21 types, save round-trip tests |

### Files to MODIFY (defense base classes — total_defense update)
| File | Changes |
|------|---------|
| `models/items/armor.gd` | Update total_defense to use primary defense stat (not hardcoded armor) |
| `models/items/helmet.gd` | Same as armor.gd |
| `models/items/boots.gd` | Same as armor.gd |

**Approach for total_defense:** Add a virtual method or let each concrete subclass set total_defense appropriately. Simplest: in each defense base class's `update_value()`, compute total_defense as `max(computed_armor, computed_evasion, computed_energy_shield)` — whichever is the primary stat will be highest since each archetype only has base value in one defense type.

---

## Recommended Implementation Approach

### Data-Driven Constructor Pattern

Each of the 21 item classes follows this pattern:

```gdscript
class_name Broadsword extends Weapon

const TIER_NAMES: Dictionary = {
    8: "Rusty Broadsword", 7: "Iron Broadsword", 6: "Steel Broadsword",
    5: "Hardened Broadsword", 4: "War Broadsword", 3: "Champion Broadsword",
    2: "Valiant Broadsword", 1: "Sovereign Broadsword"
}

const TIER_STATS: Dictionary = {
    8: {"dmg_min": 8, "dmg_max": 12, "speed": 1, "atk_speed": 1.8, "implicit_min": 2, "implicit_max": 5},
    7: {"dmg_min": 12, "dmg_max": 18, "speed": 1, "atk_speed": 1.8, "implicit_min": 3, "implicit_max": 7},
    # ... etc
}

func get_item_type_string() -> String:
    return "Broadsword"

func _init(p_tier: int = 8) -> void:
    self.rarity = Rarity.NORMAL
    self.tier = p_tier
    self.item_name = TIER_NAMES[p_tier]
    self.valid_tags = [Tag.STR, Tag.PHYSICAL, Tag.ATTACK, Tag.ARMOR, Tag.ELEMENTAL, Tag.WEAPON]
    self.base_damage_type = Tag.PHYSICAL
    var s = TIER_STATS[p_tier]
    self.base_damage_min = s["dmg_min"]
    self.base_damage_max = s["dmg_max"]
    self.base_speed = s["speed"]
    self.base_attack_speed = s["atk_speed"]
    self.implicit = Implicit.new(
        "Attack Speed", Affix.AffixType.IMPLICIT,
        s["implicit_min"], s["implicit_max"],
        [Tag.SPEED, Tag.ATTACK], [Tag.StatType.INCREASED_SPEED]
    )
    self.update_value()
```

Defense items follow the same pattern but use base_armor/base_evasion/base_energy_shield instead.

### Drop Generation Rewrite

```gdscript
func get_random_item_base() -> Item:
    var tier = LootTable.roll_item_tier(GameState.area_level, GameState.max_item_tier_unlocked)
    var slots = ["weapon", "armor", "helmet", "boots", "ring"]
    var slot = slots[randi() % slots.size()]

    var bases: Dictionary = {
        "weapon": [Broadsword, Battleaxe, Warhammer, Dagger, VenomBlade, Shortbow],
        "armor": [IronPlate, LeatherVest, SilkRobe],
        "helmet": [IronHelm, LeatherHood, Circlet],
        "boots": [IronGreaves, LeatherBoots, SilkSlippers],
        "ring": [IronBand, JadeRing, SapphireRing],
    }

    var slot_bases = bases[slot]
    var base_class = slot_bases[randi() % slot_bases.size()]
    return base_class.new(tier)
```

Note: Weapons have 6 bases (3 STR + 3 DEX) while other slots have 3. This matches "slot-first-then-archetype": weapon slot has equal chance for each of 6 weapon types (implicitly 50% STR, 50% DEX). When INT weapons are added in Phase 47, they get added to the weapon array (then 33% each archetype).

### Serialization Update

```gdscript
const ITEM_TYPE_STRINGS: PackedStringArray = [
    "Broadsword", "Battleaxe", "Warhammer",
    "Dagger", "VenomBlade", "Shortbow",
    "IronPlate", "LeatherVest", "SilkRobe",
    "IronHelm", "LeatherHood", "Circlet",
    "IronGreaves", "LeatherBoots", "SilkSlippers",
    "IronBand", "JadeRing", "SapphireRing",
]

static func create_from_dict(data: Dictionary) -> Item:
    var item_type_str: String = data.get("item_type", "")
    var tier_val: int = int(data.get("tier", 8))
    var item: Item = null
    match item_type_str:
        "Broadsword": item = Broadsword.new(tier_val)
        "Battleaxe": item = Battleaxe.new(tier_val)
        # ... 21 match arms total (18 new + kept for backward compat if desired)
```

---

## Tier Naming Table (168 Items)

### Weapons — STR

| Tier | Broadsword | Battleaxe | Warhammer |
|------|-----------|-----------|-----------|
| T8 | Rusty Broadsword | Chipped Battleaxe | Crude Warhammer |
| T7 | Iron Broadsword | Iron Battleaxe | Iron Warhammer |
| T6 | Steel Broadsword | Steel Battleaxe | Steel Warhammer |
| T5 | Tempered Broadsword | Tempered Battleaxe | Tempered Warhammer |
| T4 | War Broadsword | War Battleaxe | War Warhammer |
| T3 | Champion Broadsword | Champion Battleaxe | Champion Warhammer |
| T2 | Valiant Broadsword | Valiant Battleaxe | Valiant Warhammer |
| T1 | Sovereign Broadsword | Sovereign Battleaxe | Sovereign Warhammer |

### Weapons — DEX

| Tier | Dagger | Venom Blade | Shortbow |
|------|--------|-------------|----------|
| T8 | Rusty Dagger | Tainted Shiv | Crude Shortbow |
| T7 | Iron Dagger | Blight Blade | Elm Shortbow |
| T6 | Steel Dagger | Viper Blade | Yew Shortbow |
| T5 | Assassin Dagger | Naja Blade | Hunter Shortbow |
| T4 | Shadow Dagger | Basilisk Blade | War Shortbow |
| T3 | Phantom Dagger | Wyrm Blade | Ranger Shortbow |
| T2 | Nightfall Dagger | Hydra Blade | Sniper Shortbow |
| T1 | Eclipse Dagger | Ouroboros Blade | Sovereign Shortbow |

### Armors

| Tier | Iron Plate (STR) | Leather Vest (DEX) | Silk Robe (INT) |
|------|-----------------|-------------------|-----------------|
| T8 | Rusty Plate | Tattered Vest | Threadbare Robe |
| T7 | Iron Plate | Hide Vest | Linen Robe |
| T6 | Steel Plate | Studded Vest | Woven Robe |
| T5 | Tempered Plate | Hardened Vest | Embroidered Robe |
| T4 | War Plate | Shadow Vest | Mystic Robe |
| T3 | Champion Plate | Phantom Vest | Arcane Robe |
| T2 | Valiant Plate | Nightstalker Vest | Imbued Robe |
| T1 | Sovereign Plate | Eclipse Vest | Sovereign Robe |

### Helmets

| Tier | Iron Helm (STR) | Leather Hood (DEX) | Circlet (INT) |
|------|----------------|-------------------|---------------|
| T8 | Rusty Helm | Tattered Hood | Copper Circlet |
| T7 | Iron Helm | Hide Hood | Tin Circlet |
| T6 | Steel Helm | Studded Hood | Silver Circlet |
| T5 | Tempered Helm | Hardened Hood | Gilt Circlet |
| T4 | War Helm | Shadow Hood | Mystic Circlet |
| T3 | Champion Helm | Phantom Hood | Arcane Circlet |
| T2 | Valiant Helm | Nightstalker Hood | Imbued Circlet |
| T1 | Sovereign Helm | Eclipse Hood | Sovereign Circlet |

### Boots

| Tier | Iron Greaves (STR) | Leather Boots (DEX) | Silk Slippers (INT) |
|------|-------------------|--------------------|--------------------|
| T8 | Rusty Greaves | Tattered Boots | Threadbare Slippers |
| T7 | Iron Greaves | Hide Boots | Linen Slippers |
| T6 | Steel Greaves | Studded Boots | Woven Slippers |
| T5 | Tempered Greaves | Hardened Boots | Embroidered Slippers |
| T4 | War Greaves | Shadow Boots | Mystic Slippers |
| T3 | Champion Greaves | Phantom Boots | Arcane Slippers |
| T2 | Valiant Greaves | Nightstalker Boots | Imbued Slippers |
| T1 | Sovereign Greaves | Eclipse Boots | Sovereign Slippers |

### Rings

| Tier | Iron Band (STR) | Jade Ring (DEX) | Sapphire Ring (INT) |
|------|----------------|----------------|---------------------|
| T8 | Crude Band | Dull Jade Ring | Clouded Sapphire Ring |
| T7 | Iron Band | Pale Jade Ring | Dim Sapphire Ring |
| T6 | Steel Band | Polished Jade Ring | Clear Sapphire Ring |
| T5 | Tempered Band | Vivid Jade Ring | Bright Sapphire Ring |
| T4 | War Band | Deep Jade Ring | Lustrous Sapphire Ring |
| T3 | Champion Band | Royal Jade Ring | Radiant Sapphire Ring |
| T2 | Valiant Band | Imperial Jade Ring | Brilliant Sapphire Ring |
| T1 | Sovereign Band | Sovereign Jade Ring | Sovereign Sapphire Ring |

---

## Implicit Values and Scaling

### Weapon Implicits

Implicits scale linearly with tier. Tier 8 = weakest, Tier 1 = strongest. The Implicit class already handles tier-based scaling via `min_value = base_min * (tier_range.y + 1 - tier)`.

However, since each item constructor creates the implicit with fixed min/max values, and the item tier doesn't directly affect implicit tier rolling, we need to ensure the implicit's tier matches the item tier. The simplest approach: set the implicit's tier_range to `Vector2i(1, 1)` (single-tier) and scale the base_min/base_max per item tier in the constructor:

| Base Type | Implicit | StatType | T8 range | T1 range |
|-----------|----------|----------|----------|----------|
| Broadsword | Attack Speed | INCREASED_SPEED | 2-5 | 16-40 |
| Battleaxe | Physical Damage | INCREASED_DAMAGE | 2-5 | 16-40 |
| Warhammer | Bleed Chance | BLEED_DAMAGE | 2-5 | 16-40 |
| Dagger | Crit Chance | CRIT_CHANCE | 2-5 | 16-40 |
| Venom Blade | Poison Damage | POISON_DAMAGE | 2-5 | 16-40 |
| Shortbow | Attack Speed | INCREASED_SPEED | 2-5 | 16-40 |
| Iron Band | Attack Damage | FLAT_DAMAGE | 1-3 | 8-24 |
| Jade Ring | Crit Chance | CRIT_CHANCE | 1-2 | 8-16 |
| Sapphire Ring | Spell Damage | FLAT_SPELL_DAMAGE | 1-3 | 8-24 |

**Recommended implicit scaling formula:** Use the existing Implicit constructor with `base_min` and `base_max` that represent the T8 (weakest) values. Set `tier_range = Vector2i(1, 1)` so the implicit doesn't roll its own tier. Instead, multiply by the item's tier multiplier:

```
implicit_value_min = base_implicit_min * tier_multiplier
implicit_value_max = base_implicit_max * tier_multiplier
where tier_multiplier = (9 - tier)  # T8=1x, T7=2x, ... T1=8x
```

This matches the existing Affix._init scaling: `min_value = p_min * (tier_range.y + 1 - tier)`.

Simplest implementation: pass scaled min/max directly to Implicit.new() in each constructor based on TIER_STATS table.

### Defense Base Stat Scaling

Defense items have NO implicit. Their defense comes from base_armor, base_evasion, or base_energy_shield fields.

| Tier | Armor Base (STR) | Evasion Base (DEX) | Energy Shield Base (INT) |
|------|------------------|--------------------|--------------------------|
| T8 | 5 | 5 | 8 |
| T7 | 10 | 10 | 15 |
| T6 | 18 | 18 | 25 |
| T5 | 28 | 28 | 40 |
| T4 | 40 | 40 | 56 |
| T3 | 55 | 55 | 77 |
| T2 | 72 | 72 | 100 |
| T1 | 92 | 92 | 128 |

**Slot multipliers** (defense bases scale by slot weight):
- Armor: 1.0x (full values above)
- Helmet: 0.6x
- Boots: 0.5x

Energy shield values are ~1.4x armor/evasion to compensate for ES being the weaker defensive layer currently.

### Weapon Base Damage Scaling

| Tier | STR Weapon Damage | DEX Weapon Damage |
|------|-------------------|-------------------|
| T8 | 8-12 | 6-10 |
| T7 | 12-18 | 10-15 |
| T6 | 18-27 | 15-22 |
| T5 | 26-39 | 21-32 |
| T4 | 36-54 | 30-45 |
| T3 | 48-72 | 40-60 |
| T2 | 62-93 | 52-78 |
| T1 | 80-120 | 66-100 |

DEX weapons deal ~83% of STR weapon damage (compensated by crit and speed).

**Speed values:**
- Broadsword: base_speed=1, base_attack_speed=1.8
- Battleaxe: base_speed=1, base_attack_speed=1.4 (slower, harder hitting)
- Warhammer: base_speed=1, base_attack_speed=1.2 (slowest STR)
- Dagger: base_speed=1, base_attack_speed=2.2 (fastest)
- Venom Blade: base_speed=1, base_attack_speed=1.8
- Shortbow: base_speed=1, base_attack_speed=2.0

### Ring Base Damage Scaling

| Tier | Ring Base Damage | Ring Base Speed |
|------|-----------------|-----------------|
| T8 | 3 | 1 |
| T7 | 5 | 1 |
| T6 | 8 | 1 |
| T5 | 12 | 1 |
| T4 | 17 | 1 |
| T3 | 23 | 1 |
| T2 | 30 | 1 |
| T1 | 38 | 1 |

---

## Valid Tags per Base Type

### Weapons

| Base | Valid Tags |
|------|-----------|
| Broadsword (STR) | [STR, PHYSICAL, ATTACK, ARMOR, ELEMENTAL, WEAPON] |
| Battleaxe (STR) | [STR, PHYSICAL, ATTACK, ARMOR, ELEMENTAL, WEAPON] |
| Warhammer (STR) | [STR, PHYSICAL, ATTACK, ARMOR, ELEMENTAL, WEAPON] |
| Dagger (DEX) | [DEX, PHYSICAL, ATTACK, CRITICAL, EVASION, ELEMENTAL, WEAPON, CHAOS] |
| Venom Blade (DEX) | [DEX, PHYSICAL, ATTACK, CRITICAL, EVASION, ELEMENTAL, WEAPON, CHAOS] |
| Shortbow (DEX) | [DEX, PHYSICAL, ATTACK, CRITICAL, EVASION, ELEMENTAL, WEAPON, CHAOS] |

### Defense Bases

| Base | Valid Tags |
|------|-----------|
| Iron Plate / Iron Helm / Iron Greaves (STR) | [STR, DEFENSE, ARMOR] |
| Leather Vest / Leather Hood / Leather Boots (DEX) | [DEX, DEFENSE, EVASION] |
| Silk Robe / Circlet / Silk Slippers (INT) | [INT, DEFENSE, ENERGY_SHIELD] |

### Rings

| Base | Valid Tags |
|------|-----------|
| Iron Band (STR) | [STR, ATTACK, CRITICAL, SPEED, WEAPON] |
| Jade Ring (DEX) | [DEX, ATTACK, CRITICAL, SPEED, WEAPON, CHAOS] |
| Sapphire Ring (INT) | [INT, SPELL, SPEED, WEAPON] |

---

## Integration Risks

### Risk 1: .uid Files
Deleting old item .gd files will leave orphaned .uid files. The 5 old `.gd.uid` files must also be deleted (or Godot may error on load). New .gd files will auto-generate .uid files when Godot opens the project.

### Risk 2: total_defense for Non-Armor Defense Types
Current `total_defense = self.computed_armor` in all defense base classes means DEX/INT items would show 0 defense. Must update armor.gd, helmet.gd, boots.gd to set `total_defense` from the primary defense stat. Best approach: compute total_defense as `computed_armor + computed_evasion + computed_energy_shield` (only one will be non-zero per archetype base).

### Risk 3: Implicit Tier vs Item Tier
The Implicit class rolls its own tier from tier_range during `_init()`. For data-driven items, the implicit value should be deterministic based on the item tier, not randomly rolled. Solution: use `Vector2i(1, 1)` for tier_range so tier is always 1, and pre-scale min/max in the constructor based on item tier.

### Risk 4: Item Display — Tier Name
The item_name is set in the constructor from TIER_NAMES. If someone changes an item's tier after construction (e.g., during save/load), the name won't update. However, `create_from_dict` constructs with the saved tier, so the name will be correct. The only concern is code that does `item.tier = X` post-construction — only `get_random_item_base()` does this currently, and the rewrite eliminates that pattern.

### Risk 5: Integration Test References
The integration test directly references `LightSword` in 3 places and checks `is LightSword` in 2 places. All must be updated to Broadsword.

### Risk 6: INT Defense Bases Added Without INT Weapons
Phase 44 adds INT armor/helmet/boots/ring (Silk Robe, Circlet, Silk Slippers, Sapphire Ring) but INT weapons are deferred to Phase 47. Players may find INT defense items they can't effectively use yet. This is acceptable per scope — INT defense still works mechanically, just lacks synergy until Phase 47.

### Risk 7: Weapon Count Imbalance in Drop Pool
Weapons have 6 types (3 STR + 3 DEX) while other slots have 3. With slot-first (20% each), weapon slot gives 1/6 = 3.33% per weapon type while other slots give 1/3 = 6.67% per type. This is acceptable — weapons are the most differentiated slot.

---

## Validation Architecture

### Automated Tests (integration_test.gd)

**Group 10: Item Base Construction (all 21 types)**
For each of the 21 base types:
1. Construct at tier 8 and tier 1
2. Verify item_name matches expected tier name
3. Verify valid_tags match expected set
4. Verify base stats are non-zero and scale (T1 > T8)
5. Verify get_item_type_string() returns correct string

**Group 11: Serialization Round-Trip (all 21 types)**
For each of the 21 base types:
1. Construct at tier 5
2. Call `to_dict()`
3. Call `Item.create_from_dict(dict)`
4. Verify restored item_name, tier, base stats match original
5. Verify `get_item_type_string()` matches

**Group 12: Defense Archetype Verification**
1. Create IronPlate T5 — verify computed_armor > 0, computed_evasion == 0
2. Create LeatherVest T5 — verify computed_evasion > 0, computed_armor == 0
3. Create SilkRobe T5 — verify computed_energy_shield > 0, computed_armor == 0
4. Verify total_defense reflects primary stat for each

**Group 13: Valid Tags / Affix Gating**
1. Create STR weapon — verify it can roll Physical Damage prefix (has PHYSICAL + WEAPON)
2. Create DEX weapon — verify it can roll Crit suffix (has CRITICAL)
3. Create STR armor — verify it can roll Flat Armor (has ARMOR) but NOT Evasion (no EVASION)
4. Create DEX armor — verify it can roll Evasion but NOT Flat Armor

**Group 14: Drop Generation**
1. Call get_random_item_base() 100 times
2. Verify all 5 slots represented
3. Verify at least 2 archetypes represented in weapons
4. Verify all returned items have valid tier and item_name

**Group 15: Starter Weapon**
1. Call initialize_fresh_game()
2. Verify crafting_inventory["weapon"] is Broadsword
3. Verify starter weapon tier == 8

### Manual Verification Checklist

1. Launch game, verify starter weapon shows "Rusty Broadsword"
2. Kill mobs, verify drops from multiple slots and archetypes appear
3. Use Runic Hammer on STR armor — verify only armor-appropriate mods roll
4. Use Runic Hammer on DEX armor — verify only evasion-appropriate mods roll
5. Equip items from all archetypes — verify defense stat displays correctly
6. Save game, reload — verify all items preserved with correct names and stats
7. Prestige — verify starter weapon resets to Rusty Broadsword

---

## Implementation Order

1. **Create 21 new item class files** with data-driven constructors and tier tables
2. **Update item.gd** — new ITEM_TYPE_STRINGS, rewrite create_from_dict with tier pre-extraction
3. **Update defense base classes** (armor.gd, helmet.gd, boots.gd) — fix total_defense calculation
4. **Update gameplay_view.gd** — rewrite get_random_item_base() with slot-first-then-archetype
5. **Update game_state.gd** — change starter weapon to Broadsword
6. **Update save_manager.gd** — bump SAVE_VERSION to 6
7. **Delete old item files** (5 .gd files + 5 .gd.uid files)
8. **Update integration_test.gd** — replace LightSword references, add new test groups
9. **Verify** — run integration tests, manual smoke test

---

## RESEARCH COMPLETE
