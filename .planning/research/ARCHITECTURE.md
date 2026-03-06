# Architecture Research

**Domain:** Str/Dex/Int item archetypes (3 base types per slot), spell damage channel with cast speed, and broadened affix pool -- integration with existing Hammertime v1.7 architecture
**Researched:** 2026-03-06
**Confidence:** HIGH (based on direct codebase analysis of all affected files)

---

## System Overview

The v1.8 content pass adds two major features:

1. **Three item archetypes per slot** (str/dex/int) replacing the single base type per slot
2. **Spell damage as a second damage channel** with its own cast timer in CombatEngine

Currently there are 5 concrete item classes (LightSword, BasicArmor, BasicHelmet, BasicBoots, BasicRing) -- one per slot. Each extends a slot-specific intermediate class (Weapon, Armor, Helmet, Boots, Ring) which extends Item. This hierarchy is sound and does not need restructuring -- new archetypes simply add more leaf classes extending the same intermediates.

---

## 1. Integration Points -- Existing Code Requiring Modification

### 1a. `autoloads/tag.gd` -- New StatTypes and Tags

Current StatType enum has 19 entries. Needs additions:

```
FLAT_SPELL_DAMAGE,      # Flat spell damage (analogous to FLAT_DAMAGE)
INCREASED_SPELL_DAMAGE, # % spell damage
INCREASED_CAST_SPEED,   # % cast speed (analogous to INCREASED_SPEED for attacks)
```

Tag constants may need a `SPELL` constant alongside existing `ATTACK`:

```
const SPELL = "SPELL"
```

No existing tags need renaming. The `ATTACK` tag already exists and disambiguates from `SPELL`.

### 1b. `autoloads/item_affixes.gd` -- New Affix Definitions

**New prefixes needed:**
- Flat Spell Damage (physical/fire/cold/lightning variants, mirroring existing flat damage prefixes)
- % Spell Damage (mirroring % Physical/Elemental Damage)

**Suffixes to enable:**
- Cast Speed (currently disabled, line 247: `#Affix.new("Cast Speed", ...)`) -- needs stat_types `[Tag.StatType.INCREASED_CAST_SPEED]` and tags `[Tag.MAGIC, Tag.SPELL]`

**No structural changes** to the Affix class itself -- it already supports damage range parameters (dmg_min_lo/hi, dmg_max_lo/hi) and tag-based routing.

### 1c. `models/stats/stat_calculator.gd` -- Spell Damage Calculation

Currently has `calculate_dps()` which computes attack DPS and `calculate_damage_range()` which computes per-element attack damage ranges.

**Needs new static methods:**
- `calculate_spell_damage_range(base_spell_min, base_spell_max, affixes)` -- mirrors `calculate_damage_range()` but filters on `FLAT_SPELL_DAMAGE` and `INCREASED_SPELL_DAMAGE` StatTypes
- `calculate_spell_dps(base_spell_damage, base_cast_speed, affixes, crit_chance, crit_damage)` -- mirrors `calculate_dps()` but uses `INCREASED_CAST_SPEED` instead of `INCREASED_SPEED`

**Key design question:** Should spell and attack damage share percentage modifiers? Recommendation: **No** -- keep them fully independent. `INCREASED_DAMAGE` applies to attacks only, `INCREASED_SPELL_DAMAGE` to spells only. This creates meaningful build diversity (attack vs spell builds).

### 1d. `models/combat/combat_engine.gd` -- Spell Cast Timer

Currently uses dual timers (hero_attack_timer, pack_attack_timer). The hero attack timer fires `_on_hero_attack()` which rolls per-element damage from `hero.damage_ranges`.

**Needs a third timer: `hero_spell_timer`.**

Changes:
- `_start_pack_fight()` must start spell timer if hero has spell damage (cast speed > 0)
- New `_on_hero_spell_cast()` handler that rolls from `hero.spell_damage_ranges` and applies damage to pack
- `_get_hero_cast_speed()` pulls cast speed from equipped int weapon (or returns 0.0 if no spell source)
- `_stop_timers()` must also stop spell timer

**The spell timer is independent of the attack timer.** A hero with both attack and spell damage uses both simultaneously (dual channel). This is the key combat identity difference: str builds do pure attack damage, int builds do pure spell damage, and hybrid builds do both at reduced individual power.

### 1e. `models/combat/defense_calculator.gd` -- Minimal Changes

The `is_spell` parameter already exists in `calculate_damage_taken()` (line 105). Currently only affects evasion dodge check (spells bypass evasion). **No changes needed** for hero spell output -- `is_spell` is for incoming damage classification only.

### 1f. `models/hero.gd` -- Spell Damage Range Tracking

Currently tracks `damage_ranges` dict with per-element min/max for attacks.

**Needs parallel tracking:**
- `spell_damage_ranges` dict mirroring `damage_ranges` structure
- `total_spell_dps` float
- `base_cast_speed` float (from int weapon)
- `calculate_spell_damage_ranges()` method mirroring `calculate_damage_ranges()`
- `calculate_spell_dps()` method mirroring `calculate_dps()`
- `update_stats()` must call spell calculation methods in correct order

### 1g. `scenes/gameplay_view.gd` -- Item Drop Pool Expansion

`get_random_item_base()` (line 274) currently has a hardcoded list:
```gdscript
var item_types = [LightSword, BasicHelmet, BasicArmor, BasicBoots, BasicRing]
```

This must expand to include all 15 base types (3 per slot). Equal weight random selection is fine -- players craft whatever drops.

### 1h. `autoloads/game_state.gd` -- Starter Item Changes

`initialize_fresh_game()` and `_wipe_run_state()` both create `LightSword.new()` as the starter weapon. This is still appropriate -- str/sword is the beginner archetype. No changes needed unless a different starter is desired.

### 1i. `scenes/forge_view.gd` -- UI for Multiple Base Types

The crafting view uses slot tabs (weapon, helmet, armor, boots, ring). Currently each slot implicitly has one base type. With 3 bases per slot, the **slot concept remains the same** -- all 3 weapon archetypes go into the "weapon" slot array. The inventory already holds `Array` per slot with a 10-item cap.

**No structural UI changes needed.** Item names differentiate archetypes (e.g., "Light Sword" vs "Battle Axe" vs "Spell Staff"). The ForgeView already displays item_name on buttons.

### 1j. `models/items/item.gd` -- Serialization Registry

`ITEM_TYPE_STRINGS` (line 74) and `create_from_dict()` (line 80) have a hardcoded match statement for deserialization. Must add all 10 new base types:

```gdscript
const ITEM_TYPE_STRINGS: PackedStringArray = [
    "LightSword", "BasicArmor", "BasicHelmet", "BasicBoots", "BasicRing",
    # New str archetypes
    "BattleAxe", "HeavyPlate", "GreatHelm", "IronGreaves", "WarBand",
    # New int archetypes
    "SpellStaff", "SilkRobe", "CircletOfFocus", "MysticSlippers", "ArcaneLoop",
]
```

Names are illustrative -- actual names TBD in design phase.

---

## 2. New Components Needed

### 2a. New Concrete Item Classes (10 files)

Each extends the existing slot intermediate class. Pattern mirrors LightSword/BasicArmor/etc.

**Str archetype (melee/tanky):**
- `models/items/battle_axe.gd` -- extends Weapon. Higher base damage, slower attack speed. Tags include `[Tag.PHYSICAL, Tag.ATTACK]`.
- `models/items/heavy_plate.gd` -- extends Armor. Higher base_armor, implicit armor%.
- `models/items/great_helm.gd` -- extends Helmet. Higher base_armor, implicit flat armor.
- `models/items/iron_greaves.gd` -- extends Boots. Higher base_armor, implicit armor.
- `models/items/war_band.gd` -- extends Ring. Higher base_damage, attack-focused tags.

**Dex archetype (fast/evasive):**
- `models/items/curved_blade.gd` -- extends Weapon. Lower base damage, higher base_attack_speed. Tags include `[Tag.ATTACK, Tag.CRITICAL, Tag.SPEED, Tag.EVASION]`.
- `models/items/leather_vest.gd` -- extends Armor. Higher base_evasion, implicit evasion%.
- `models/items/scout_cap.gd` -- extends Helmet. Higher base_evasion, implicit crit chance.
- `models/items/swift_boots.gd` -- extends Boots. Higher base_evasion, implicit movement speed.
- `models/items/jade_ring.gd` -- extends Ring. Crit/speed-focused tags and implicits.

**Int archetype (spell/ES):**
- `models/items/spell_staff.gd` -- extends Weapon. Has `base_spell_damage_min/max` and `base_cast_speed` instead of (or in addition to) attack speed. Tags include `[Tag.SPELL, Tag.MAGIC, Tag.ELEMENTAL]`.

This is the trickiest integration point. The Weapon class currently assumes attack-based damage. Two approaches:

**Option A: Add spell fields to Weapon class.** Weapon gains optional `base_spell_damage_min`, `base_spell_damage_max`, `base_cast_speed` fields. SpellStaff sets these; LightSword/BattleAxe/CurvedBlade leave them at 0. Weapon.update_value() calculates both attack DPS and spell DPS.

**Option B: Create a SpellWeapon intermediate class.** `SpellWeapon extends Weapon` adds spell-specific fields. SpellStaff extends SpellWeapon.

**Recommendation: Option A.** Fewer classes, simpler serialization, and hybrid items become possible in the future. The Weapon class is already compact (26 lines).

Remaining int items:
- `models/items/silk_robe.gd` -- extends Armor. Higher base_energy_shield, implicit ES%.
- `models/items/circlet.gd` -- extends Helmet. Higher base_energy_shield, implicit flat mana.
- `models/items/mystic_slippers.gd` -- extends Boots. Higher base_energy_shield, implicit cast speed.
- `models/items/arcane_loop.gd` -- extends Ring. Spell damage/cast speed-focused tags.

### 2b. No New Intermediate Classes Needed

The existing Weapon, Armor, Helmet, Boots, Ring intermediates handle all stat computation. Dex and str armor items just set different base stats and valid_tags. Int items set higher ES bases and ES-favoring tags.

---

## 3. Data Flow Changes

### 3a. Attack Damage Flow (existing, unchanged)

```
Weapon.base_damage_min/max
    -> Hero.calculate_damage_ranges()
        -> StatCalculator.calculate_damage_range(weapon_min, weapon_max, affixes)
            -> hero.damage_ranges["physical"/"fire"/"cold"/"lightning"]
                -> CombatEngine._on_hero_attack()
                    -> randf_range(el_min, el_max) per element
                        -> pack.take_damage(total)
```

### 3b. Spell Damage Flow (new)

```
Weapon.base_spell_damage_min/max (set by SpellStaff, 0 for attack weapons)
    -> Hero.calculate_spell_damage_ranges()
        -> StatCalculator.calculate_spell_damage_range(spell_min, spell_max, affixes)
            -> hero.spell_damage_ranges["physical"/"fire"/"cold"/"lightning"]
                -> CombatEngine._on_hero_spell_cast()
                    -> randf_range(el_min, el_max) per element
                        -> pack.take_damage(total)
```

Key differences from attack flow:
- Uses `FLAT_SPELL_DAMAGE` / `INCREASED_SPELL_DAMAGE` StatTypes instead of `FLAT_DAMAGE` / `INCREASED_DAMAGE`
- Uses `INCREASED_CAST_SPEED` instead of `INCREASED_SPEED`
- Crit applies identically (same crit chance/damage stats affect both channels)
- Timer cadence comes from `base_cast_speed` not `base_attack_speed`

### 3c. Defense Flow (unchanged for str/dex)

Str items provide more armor (already flows through `calculate_defense()` -> `computed_armor`).
Dex items provide more evasion (already flows through `calculate_defense()` -> `computed_evasion`).
Int items provide more ES (already flows through `calculate_defense()` -> `computed_energy_shield`).

**No changes to DefenseCalculator.** The 4-stage pipeline already handles armor, evasion, and ES correctly.

### 3d. Affix Filtering Flow (existing, key for archetype identity)

```
Item.valid_tags (set in concrete class _init)
    -> Item.has_valid_tag(affix)
        -> Item.add_prefix() / add_suffix()
```

This is the mechanism that gives archetypes distinct crafting pools:

- **Str weapon** `valid_tags = [Tag.PHYSICAL, Tag.ATTACK, Tag.WEAPON]` -- gets physical damage affixes, attack speed
- **Dex weapon** `valid_tags = [Tag.PHYSICAL, Tag.ATTACK, Tag.CRITICAL, Tag.SPEED, Tag.WEAPON]` -- gets crit + speed affixes
- **Int weapon** `valid_tags = [Tag.SPELL, Tag.MAGIC, Tag.ELEMENTAL, Tag.WEAPON]` -- gets spell damage affixes, cast speed
- **Int armor** `valid_tags = [Tag.DEFENSE, Tag.ENERGY_SHIELD, Tag.MAGIC]` -- favors ES prefixes over armor prefixes

**No changes to the filtering mechanism itself.** Archetype identity emerges purely from `valid_tags` configuration.

---

## 4. Item Factory Changes -- LootTable and Drop System

### 4a. Current Drop Path

```
CombatEngine._on_pack_killed()
    -> LootTable.roll_pack_item_drop()  # 18% chance
        -> GameEvents.items_dropped.emit(area_level)
            -> gameplay_view._on_items_dropped(level)
                -> get_random_item_base()
                    -> picks from [LightSword, BasicHelmet, BasicArmor, BasicBoots, BasicRing]
                    -> rolls tier via LootTable.roll_item_tier()
```

### 4b. Required Changes

`get_random_item_base()` in `scenes/gameplay_view.gd` must expand its pool:

```gdscript
func get_random_item_base() -> Item:
    var item_types = [
        # Str
        LightSword, BasicArmor, BasicHelmet, BasicBoots, BasicRing,
        # Dex
        CurvedBlade, LeatherVest, ScoutCap, SwiftBoots, JadeRing,
        # Int
        SpellStaff, SilkRobe, Circlet, MysticSlippers, ArcaneLoop,
    ]
    var random_type = item_types[randi() % item_types.size()]
    var item = random_type.new()
    item.tier = LootTable.roll_item_tier(GameState.area_level, GameState.max_item_tier_unlocked)
    return item
```

**No changes to LootTable itself.** Tier rolling, rarity system, and drop chances are all item-type-agnostic.

**Slot assignment is implicit.** Each concrete item's intermediate class determines its slot (Weapon -> "weapon", Armor -> "armor", etc.). The `add_item_to_inventory()` path in gameplay_view already determines slot from item type. This pattern holds for new archetypes since they extend the same intermediates.

### 4c. Inventory Slot Compatibility

The per-slot inventory arrays (`crafting_inventory["weapon"]` etc.) can hold any item that extends the slot's intermediate class. A SpellStaff (extends Weapon) naturally goes into the "weapon" array. A SilkRobe (extends Armor) goes into "armor". **No inventory changes needed.**

The 10-item cap per slot means players see more base variety but same total count. This is good -- players must choose which archetype to keep/craft.

---

## 5. Save Format Implications

### 5a. Current Save Format (v4)

Items serialize via `Item.to_dict()` which stores:
```json
{
    "item_type": "LightSword",
    "item_name": "Light Sword",
    "tier": 8,
    "rarity": 0,
    "valid_tags": ["PHYSICAL", "ATTACK", "CRITICAL", "WEAPON"],
    "implicit": {...},
    "prefixes": [...],
    "suffixes": [...]
}
```

Deserialization uses `Item.create_from_dict()` which matches on `item_type` string.

### 5b. Does v1.8 Require Save Format v5?

**No.** The save format is already extensible:

1. **New item types** only require adding cases to `create_from_dict()`. Old saves with only old item types deserialize fine. New item types in saves are forward-compatible because the match statement returns null for unknown types (with a warning), and the restore loop handles null gracefully.

2. **New StatType enum values** are stored as integer indices in affix serialization. New enum values are appended to the end of the enum, so existing indices remain stable. Affixes from old saves deserialize correctly.

3. **New Weapon fields** (base_spell_damage_min/max, base_cast_speed) can default to 0 in Weapon._init(). Old weapon saves won't have these fields, and the Weapon class doesn't serialize base stats (they come from the concrete class _init). So `create_from_dict()` instantiates the concrete class (which sets base stats in _init), then restores affixes on top. **No migration needed.**

4. **Hero spell stats** (spell_damage_ranges, total_spell_dps) are derived stats, not serialized. Calculated from equipped items via `update_stats()`.

**Conclusion: Save format v4 is sufficient. No version bump needed.** Old saves load fine (they just have old item types). New saves with new item types load fine on old code (unknown types become null, items are lost but game doesn't crash).

However, the `SAVE_VERSION` check in SaveManager (line 62) deletes saves with version < SAVE_VERSION. As long as we keep SAVE_VERSION = 4, old saves persist through the update.

### 5c. Risk: Item.ITEM_TYPE_STRINGS

This PackedStringArray is only used for documentation/validation, not for deserialization logic. The match statement in `create_from_dict()` is the actual registry. Both must be updated in sync.

---

## 6. Suggested Build Order

Ordered for minimal breakage and incremental testability. Each step produces a working game.

### Phase 1: Tag and StatType Foundation

**Files:** `autoloads/tag.gd`

Add new StatType enum entries (FLAT_SPELL_DAMAGE, INCREASED_SPELL_DAMAGE, INCREASED_CAST_SPEED) and new Tag constant (SPELL).

**Risk:** None. Appending to enums and adding constants has no effect on existing code.

### Phase 2: Spell Damage in StatCalculator

**Files:** `models/stats/stat_calculator.gd`

Add `calculate_spell_damage_range()` and `calculate_spell_dps()` static methods.

**Risk:** None. New static methods, no changes to existing methods.
**Test:** Unit test new methods with synthetic affixes.

### Phase 3: Spell Affixes

**Files:** `autoloads/item_affixes.gd`

Add flat spell damage prefix variants and enable the Cast Speed suffix with proper stat_types.

**Risk:** Low. New affixes only appear on items whose valid_tags include SPELL/MAGIC. Existing items don't have these tags, so existing crafting is unchanged.

### Phase 4: Weapon Spell Fields + Hero Spell Stats

**Files:** `models/items/weapon.gd`, `models/hero.gd`

Add optional spell damage fields to Weapon (defaulting to 0). Add spell_damage_ranges tracking and calculation methods to Hero. Update `update_stats()` call order.

**Risk:** Low. New fields default to 0, so existing weapons behave identically. Hero spell DPS starts at 0 for existing builds.
**Test:** Verify existing weapon DPS unchanged. Verify spell DPS = 0 with no spell weapon.

### Phase 5: Str/Dex Item Bases (No Spell Dependency)

**Files:** 10 new files in `models/items/`

Create str and dex concrete classes. These are purely data: different base stats, valid_tags, and implicits. They extend existing intermediates with zero code changes.

**Also update:** `models/items/item.gd` (create_from_dict match statement), `scenes/gameplay_view.gd` (get_random_item_base pool).

**Risk:** Low. New items use existing stat calculation paths. Str items are just different numbers on the same Armor/Weapon/etc classes.
**Test:** Drop each new base type, verify stats display correctly, verify crafting produces appropriate affixes.

### Phase 6: Int Item Bases (Spell Staff)

**Files:** New int concrete classes in `models/items/`

SpellStaff sets base_spell_damage_min/max and base_cast_speed. Int armor/helm/boots/ring set ES-heavy bases and MAGIC/SPELL tags.

**Risk:** Medium. SpellStaff is the first item that actually exercises the spell damage path. Requires Phase 4 to be solid.
**Test:** Equip SpellStaff, verify hero.spell_damage_ranges populated, verify spell DPS calculated.

### Phase 7: CombatEngine Spell Timer

**Files:** `models/combat/combat_engine.gd`

Add hero_spell_timer, _on_hero_spell_cast(), and cast speed integration in _start_pack_fight().

**Risk:** Medium. This is the highest-risk change -- a new timer in the combat state machine. Must handle all state transitions (idle, fighting, dead, map complete) correctly.
**Test:** Equip SpellStaff, enter combat, verify spell casts fire at correct cadence. Verify attack-only weapons still work. Verify dual-channel (attack + spell ring?) works if applicable.

### Phase 8: UI Polish

**Files:** `scenes/forge_view.gd`, `scenes/hero_view.gd`

- Show spell DPS in hero stats panel (if > 0)
- Floating spell damage numbers (different color?)
- Item tooltip shows spell damage range for int weapons

**Risk:** Low. Display-only changes.

---

## Appendix: Archetype Identity Through valid_tags

The entire archetype system works through `valid_tags` on concrete item classes. No special archetype enum or class hierarchy needed.

| Archetype | Key valid_tags | Crafting Identity |
|-----------|---------------|-------------------|
| Str weapon | PHYSICAL, ATTACK, WEAPON | Physical damage, attack speed |
| Dex weapon | PHYSICAL, ATTACK, CRITICAL, SPEED, WEAPON | Crit chance, crit damage, attack speed |
| Int weapon | SPELL, MAGIC, ELEMENTAL, WEAPON | Spell damage, cast speed, elemental |
| Str armor | DEFENSE, ARMOR, PHYSICAL | Flat armor, % armor |
| Dex armor | DEFENSE, EVASION | Flat evasion, % evasion |
| Int armor | DEFENSE, ENERGY_SHIELD, MAGIC | Flat ES, % ES |

This means build diversity emerges from item choice + crafting, not from a class selection screen. Players organically discover builds by equipping different archetypes and seeing what affixes appear.

---

*Last updated: 2026-03-06*
