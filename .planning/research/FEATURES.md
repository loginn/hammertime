# Feature Research

**Domain:** ARPG Item Archetypes (STR/DEX/INT bases), Spell Damage Systems, Affix Pool Differentiation -- Hammertime v1.8
**Researched:** 2026-03-06
**Confidence:** HIGH (patterns verified across PoE 1/2, Last Epoch, Diablo 4 -- core ARPG conventions with 20+ years of design iteration)

---

## 1. Table Stakes -- What Players Expect from Item Archetypes

ARPG players have deeply internalized the STR/DEX/INT archetype triangle. These expectations are non-negotiable for any game claiming ARPG item identity.

| Feature | Why Expected | Complexity | Hammertime Notes |
|---------|--------------|------------|------------------|
| 3 defense types tied to archetypes | Armor=STR, Evasion=DEX, Energy Shield=INT is the universal ARPG convention (PoE, Last Epoch, D4 all use it). Players instantly understand gear identity from its primary defense stat | LOW | Already have Armor, Evasion, ES as stats. Current bases are all armor-primary. Need DEX bases (evasion-primary) and INT bases (ES-primary) |
| Base stat determines archetype identity | The base item's inherent stats (not affixes) signal which archetype it serves. A "Silk Robe" with base ES tells the player "this is for casters" before any mods are applied | LOW | Current BasicArmor has `base_armor = 5`. New int body armor needs `base_energy_shield = X, base_armor = 0`. Dex body armor needs `base_evasion = X, base_armor = 0` |
| Implicit mods differ by archetype | Implicits are the primary way items announce "who should use this." A STR sword has flat phys implicit; an INT sceptre has spell damage implicit; a DEX bow has crit implicit | LOW | LightSword already has Attack Speed implicit. New weapon bases need different implicits (spell damage, crit chance, etc.) |
| Affix pool partially shared, partially exclusive | Some mods roll on all bases (life, resistances); some are archetype-exclusive (spell damage only on INT gear, attack speed only on STR/DEX gear). This creates meaningful gearing decisions | MEDIUM | Current tag system supports this. Weapon valid_tags control which affixes can roll. Need to add SPELL/CASTER tags and spell-specific affixes |
| Hybrid bases exist | Every major ARPG offers STR/DEX, STR/INT, or DEX/INT hybrid bases that split their defense between two types. These serve multi-archetype builds | LOW | Add after pure bases work. Hybrid = split base stats (e.g., armor/evasion boots) |
| Visual/naming convention signals archetype | STR items use heavy/plate/iron names. DEX items use leather/hide/scale names. INT items use silk/arcane/mystic names. This is genre vocabulary | LOW | Naming only; no code impact beyond item_name strings |

## 2. Item Base Differentiation Patterns

### How PoE Handles It

**Weapons:**
- STR: Maces, Axes (high base phys damage, slow). Implicit: +% elemental damage (maces) or accuracy (axes)
- DEX: Daggers, Claws, Bows (lower base damage, fast). Implicit: crit chance, life/mana on hit
- INT: Wands, Sceptres (low base damage, enable spells). Implicit: +spell damage, +elemental damage
- Hybrid: Swords (STR/DEX), Staves (STR/INT)

**Body Armor:**
- STR: Base Armor only (e.g., Glorious Plate: 776 armor)
- DEX: Base Evasion only (e.g., Assassin's Garb: 705 evasion)
- INT: Base ES only (e.g., Vaal Regalia: 242 ES)
- Hybrid: Two defense types split (e.g., STR/DEX: Triumphant Lamellar: armor + evasion)

**Key principle:** The base item determines defense type identity. Affixes can add other defense types on top, but the base stat is always the primary.

### How Last Epoch Handles It

**Weapons per archetype:**
- Sentinel (STR): Swords, Axes, Maces -- high base damage
- Rogue (DEX): Daggers, Bows -- crit-oriented, faster
- Mage (INT): Wands, Sceptres, Staves -- enable spell casting, +spell damage implicit
- Acolyte (INT-adjacent): Catalysts -- specifically for DoT/necro builds

**Armor per archetype:**
- Each class has its own armor type with weighted defenses
- Last Epoch also gates affixes by item class (some mods only appear on mage helmets)

**Key principle:** Last Epoch takes archetype differentiation further by class-gating some affixes to specific item types, not just by tag filtering.

### How Diablo 4 Handles It

**Simpler model:**
- STR: Barbarian items (high armor, weapon damage)
- DEX: Rogue items (dodge chance, crit)
- INT: Sorcerer items (skill ranks, cooldown reduction)
- All classes share generic slots with class-specific affixes

**Key principle:** D4 simplifies by tying archetypes to classes rather than items. Less relevant for Hammertime since there's no class system -- items must carry the archetype identity themselves.

### Pattern Summary for Hammertime

The consistent cross-game pattern is:

| Slot | STR Base | DEX Base | INT Base |
|------|----------|----------|----------|
| Weapon | High phys damage, slow. Implicit: phys % or accuracy | Medium damage, fast. Implicit: crit chance | Low phys damage, spell-enabling. Implicit: spell damage |
| Body Armor | Base Armor | Base Evasion | Base ES |
| Helmet | Base Armor | Base Evasion | Base ES |
| Boots | Base Armor + move speed | Base Evasion + move speed | Base ES + move speed |
| Ring | Flat phys damage | Crit chance or accuracy | Spell damage or cast speed |

**Hammertime mapping (using existing class hierarchy):**

| Slot | STR (exists) | DEX (new) | INT (new) |
|------|-------------|-----------|-----------|
| Weapon | LightSword (phys, attack speed implicit) | ShortBow (phys, crit chance implicit) | Wand (low phys, +spell damage implicit) |
| Body Armor | BasicArmor (base_armor=5) | LeatherArmor (base_evasion=5) | SilkRobe (base_energy_shield=5) |
| Helmet | BasicHelmet (base_armor=3) | LeatherHelm (base_evasion=3) | CircletHelm (base_energy_shield=3) |
| Boots | BasicBoots (base_armor=0, move speed implicit) | LeatherBoots (base_evasion=0, move speed implicit) | SilkSlippers (base_energy_shield=0, move speed implicit) |
| Ring | BasicRing (flat phys, crit chance implicit) | JadeRing (accuracy or crit multi implicit) | SapphireRing (cast speed or spell damage implicit) |

## 3. Spell vs Attack Damage -- How Games Split These Systems

### The Core Split

Every ARPG with spell damage uses the same fundamental split:

| Dimension | Attack Damage | Spell Damage |
|-----------|---------------|--------------|
| Damage source | Weapon base damage + flat added damage | Spell base damage (fixed per skill) + flat added spell damage |
| Scaling stats | %increased attack damage, flat phys, attack speed | %increased spell damage, flat spell damage, cast speed |
| Speed stat | Attack speed | Cast speed |
| Crit route | Weapon crit chance (base on weapon) | Spell crit chance (base on spell or global) |
| Defense bypass | Evasion dodges attacks | Evasion does NOT dodge spells (already in DefenseCalculator) |
| Weapon dependency | DPS scales directly with weapon base | Weapon provides +spell damage as a stat, not as base DPS |

### How This Maps to an Idle Game

In an idle game without active skill selection, "spell damage" is a parallel damage channel:

**Option A: Dual-channel simultaneous (recommended for idle)**
- Hero deals attack damage AND spell damage every tick
- Attack damage comes from weapon base + attack affixes
- Spell damage comes from a separate formula: base spell + spell affixes
- Total DPS = attack DPS + spell DPS
- Player optimizes one or both channels through gear choices

**Option B: Skill-based toggle (too complex for idle)**
- Player picks "use attacks" or "use spells" -- requires active choice and skill UI
- Not appropriate for an idle game

**Option C: Weapon type determines channel (good middle ground)**
- STR/DEX weapons calculate attack DPS (current system)
- INT weapons calculate spell DPS instead of attack DPS
- Only one channel active at a time, determined by equipped weapon
- Simpler than dual-channel, still creates meaningful weapon choice

### Recommendation for Hammertime: Option C (weapon determines channel)

Option C is the cleanest fit because:
1. No new combat tick system needed -- weapon DPS is already the single damage source
2. The Wand simply calculates DPS differently: `spell_base * (1 + spell_damage%) * cast_speed * crit`
3. Attack speed affixes are dead weight on a Wand; cast speed affixes are dead weight on a Sword. This creates natural affix differentiation without complex tag exclusion rules
4. The hero already has a single `total_dps` that feeds combat. Spell DPS just replaces attack DPS when a wand is equipped

### Spell Damage Implementation Sketch

New stats needed:
- `SPELL_DAMAGE` (flat added spell damage) -- prefix, analogous to FLAT_DAMAGE
- `INCREASED_SPELL_DAMAGE` (% spell damage) -- prefix, analogous to INCREASED_DAMAGE
- `CAST_SPEED` (% increased cast speed) -- suffix, analogous to INCREASED_SPEED (already stubbed!)
- `SPELL_CRIT_CHANCE` -- suffix (or share existing CRIT_CHANCE with SPELL tag)

Wand base stats:
```
base_spell_damage_min: int = 5
base_spell_damage_max: int = 10
base_cast_speed: float = 1.0  # casts per second
# base_damage_min/max still exist but are very low (1-2) for when attack affixes land on it
```

DPS formula for wand:
```
spell_dps = avg(spell_min, spell_max) * (1 + sum(increased_spell_damage%)) * cast_speed * crit_multiplier
```

## 4. Affix Pool Per Archetype

### Which Mods Matter for Each Playstyle

| Affix | STR (Attack/Armor) | DEX (Attack/Evasion) | INT (Spell/ES) | Tag Filter |
|-------|-------------------|---------------------|----------------|------------|
| **Offensive Prefixes** | | | | |
| Flat Physical Damage | Core | Core | Dead | Tag.ATTACK, Tag.WEAPON |
| %Physical Damage | Core | Good | Dead | Tag.ATTACK, Tag.WEAPON |
| %Elemental Damage | Good | Good | Good | Tag.WEAPON (attacks and spells) |
| Flat Fire/Cold/Lightning | Good | Good | Good | Tag.WEAPON |
| %Fire/%Cold/%Lightning | Good | Good | Good | Tag.WEAPON |
| Flat Spell Damage (NEW) | Dead | Dead | Core | Tag.SPELL, Tag.WEAPON |
| %Spell Damage (NEW) | Dead | Dead | Core | Tag.SPELL, Tag.WEAPON |
| **Defensive Prefixes** | | | | |
| Flat Armor | Core | Weak | Dead | Tag.DEFENSE, Tag.ARMOR |
| %Armor | Core | Weak | Dead | Tag.DEFENSE, Tag.ARMOR |
| Flat Evasion | Weak | Core | Dead | Tag.DEFENSE, Tag.EVASION |
| %Evasion | Weak | Core | Dead | Tag.DEFENSE, Tag.EVASION |
| Flat Energy Shield | Dead | Dead | Core | Tag.DEFENSE, Tag.ENERGY_SHIELD |
| %Energy Shield | Dead | Dead | Core | Tag.DEFENSE, Tag.ENERGY_SHIELD |
| Health | Core | Core | Good | Tag.DEFENSE, Tag.UTILITY |
| %Health | Core | Core | Good | Tag.DEFENSE, Tag.UTILITY |
| Mana | Weak | Weak | Core | Tag.DEFENSE, Tag.MANA |
| **Suffixes** | | | | |
| Attack Speed | Core | Core | Dead | Tag.ATTACK, Tag.WEAPON |
| Cast Speed (ENABLE) | Dead | Dead | Core | Tag.SPELL, Tag.WEAPON |
| Crit Chance | Good | Core | Good | Tag.CRITICAL |
| Crit Damage | Good | Core | Good | Tag.CRITICAL |
| Fire/Cold/Lightning Res | Core | Core | Core | Tag.DEFENSE |
| All Resistances | Core | Core | Core | Tag.DEFENSE |
| Life (suffix) | Core | Core | Core | Tag.DEFENSE |
| Armor (suffix) | Core | Weak | Dead | Tag.DEFENSE, Tag.ARMOR |
| Dodge Chance (ENABLE) | Dead | Core | Dead | Tag.DEFENSE, Tag.EVASION |
| Dmg Suppression (ENABLE) | Dead | Good | Good | Tag.DEFENSE |

### How valid_tags Creates Archetype Identity

The existing `valid_tags` array on each item base is the mechanism. Affixes check `has_valid_tag()` before rolling.

**STR Weapon (LightSword):**
```gdscript
valid_tags = [Tag.PHYSICAL, Tag.ATTACK, Tag.CRITICAL, Tag.WEAPON]
```
- Gets: flat phys, %phys, attack speed, crit, elemental flat/%, resistances
- Excluded: spell damage, cast speed (no Tag.SPELL)

**INT Weapon (Wand) -- proposed:**
```gdscript
valid_tags = [Tag.SPELL, Tag.ELEMENTAL, Tag.CRITICAL, Tag.WEAPON]
```
- Gets: spell damage, %spell damage, cast speed, crit, elemental flat/%, resistances
- Excluded: flat phys, %phys, attack speed (no Tag.PHYSICAL, no Tag.ATTACK)

**DEX Weapon (ShortBow) -- proposed:**
```gdscript
valid_tags = [Tag.PHYSICAL, Tag.ATTACK, Tag.CRITICAL, Tag.WEAPON]
```
- Same offensive pool as STR weapon but different base stats (faster, lower base damage, higher crit implicit)

**STR Body Armor (BasicArmor):**
```gdscript
valid_tags = [Tag.DEFENSE, Tag.ARMOR, Tag.ENERGY_SHIELD]  # current
```
- Gets: flat armor, %armor, ES, health, resistances

**DEX Body Armor (LeatherArmor) -- proposed:**
```gdscript
valid_tags = [Tag.DEFENSE, Tag.EVASION, Tag.ENERGY_SHIELD]
```
- Gets: flat evasion, %evasion, ES, health, resistances
- Excluded: flat armor, %armor (no Tag.ARMOR)

**INT Body Armor (SilkRobe) -- proposed:**
```gdscript
valid_tags = [Tag.DEFENSE, Tag.ENERGY_SHIELD, Tag.MANA]
```
- Gets: flat ES, %ES, mana, health, resistances
- Excluded: flat armor, %armor, flat evasion, %evasion (no Tag.ARMOR, no Tag.EVASION)

### New Affixes Needed

| Affix Name | Type | Tags | StatType (new) | Notes |
|------------|------|------|----------------|-------|
| Flat Spell Damage | PREFIX | [Tag.SPELL, Tag.FLAT, Tag.WEAPON] | FLAT_SPELL_DAMAGE | Analogous to Physical Damage prefix |
| %Spell Damage | PREFIX | [Tag.SPELL, Tag.PERCENTAGE, Tag.WEAPON] | INCREASED_SPELL_DAMAGE | Analogous to %Physical Damage prefix |
| Cast Speed | SUFFIX | [Tag.SPEED, Tag.SPELL, Tag.WEAPON] | CAST_SPEED | Already stubbed in item_affixes.gd |
| Dodge Chance | SUFFIX | [Tag.DEFENSE, Tag.EVASION] | DODGE_CHANCE | Already stubbed; DEX defensive identity |
| Dmg Suppression | SUFFIX | [Tag.DEFENSE] | DAMAGE_SUPPRESSION | Already stubbed; reduces spell damage taken |

New StatType enum entries needed:
```gdscript
FLAT_SPELL_DAMAGE,
INCREASED_SPELL_DAMAGE,
CAST_SPEED,      # already stubbed as disabled suffix
DODGE_CHANCE,    # already stubbed
DAMAGE_SUPPRESSION,  # already stubbed
```

## 5. Differentiators vs Anti-Features

### Differentiators (Include -- Competitive Advantage for Idle ARPG)

| Feature | Value for Hammertime | Why It Works in Idle Context |
|---------|---------------------|------------------------------|
| **Weapon type determines damage channel** (attack vs spell) | Single cleanest archetype differentiator. Equipping a wand vs a sword changes your entire build identity without needing a class system | No active skill selection needed. Weapon swap changes the math; player sees DPS update immediately. Idle-friendly |
| **Defense type on base item (not affixes)** creates gear identity | Players know at a glance if an item is "for them." A Silk Robe with base ES screams "caster gear" before any crafting | Zero UI complexity added. The item name + base stat communicates archetype. Works in small mobile viewports |
| **Shared suffix pool, split prefix pool** | Resistances and life on all gear (everyone needs survivability). Damage prefixes split by archetype (spell vs attack). Creates meaningful crafting decisions: "Do I craft this Wand for spell damage or sell and find a Sword?" | Reduces total affix count needed. Suffixes are universal; only offensive prefixes and a few defensive prefixes need archetype filtering |
| **3 pure bases per slot, no hybrids initially** | 15 total item bases (5 slots x 3 archetypes) is manageable scope. Hybrids add later as content expansion | Keeps loot pool readable. Player sees 3 weapons, 3 armors, etc. Not overwhelmed by choice in an idle context |
| **Implicit mod as archetype signature** | The implicit is the one stat players can't change via crafting. It permanently marks the item's identity. LightSword = attack speed. Wand = spell damage. ShortBow = crit chance | Existing implicit system supports this with zero changes. Just set different implicits per base |
| **Enable disabled suffix stubs (cast speed, dodge)** | These stubs were designed for this exact milestone. Enabling them completes the suffix pool for DEX and INT archetypes | Near-zero new code. The affixes exist in item_affixes.gd as comments. Enable and assign appropriate StatType implementations |

### Anti-Features (Avoid -- Commonly Requested, Problematic in Idle Context)

| Feature | Why Requested | Why Problematic for Hammertime | Alternative |
|---------|---------------|-------------------------------|-------------|
| **Attribute requirements (need 50 STR to equip plate)** | "Realism" and build constraint in PoE/D4 | Hammertime has no attribute system. Adding STR/DEX/INT as hero stats just to gate equipment adds complexity with no gameplay payoff in idle. The item's base stats already self-select -- a caster won't equip plate because plate has no ES | Item base stats create natural selection pressure. No attribute gate needed |
| **Class system to restrict gear** | "Only mages should wear robes" | No classes in Hammertime. The entire point is that crafting IS the build system. Any weapon can be equipped. The optimization comes from matching gear archetype to your damage channel preference | Weapon determines damage channel; armor archetype is player's defensive choice. Full freedom |
| **Dual-wielding or off-hand items** | Adds depth, more gear slots | Doubles weapon slot complexity. Current 5-slot system is tuned for idle. A second weapon slot means balancing DPS for 2 weapons, dual-wield bonuses, etc. | Single weapon slot. Ring already serves as secondary damage source |
| **Separate spell skill system** | "Spells should have cooldowns and mana costs" | Turns idle game into action RPG. Mana exists as a stat but has no mechanical effect yet. Adding skill cooldowns requires active play, which contradicts idle design | Spell damage is passive -- wand auto-casts on the same timer as attacks. Cast speed replaces attack speed. Mana remains a defensive stat (mana shield potential) |
| **Per-element spell specialization** | "Fire mage should only do fire damage" | Over-constrains builds in a game with 3 elements already. Elemental flat damage affixes already exist and can roll on any weapon. Forcing element-locking reduces crafting option space | Elemental affixes remain shared across all archetypes. A wand can have fire, cold, or lightning spell damage. Player specializes via tag-targeted hammers from v1.7, not via base item restriction |
| **Armor-type-exclusive affixes** (mods that ONLY appear on plate, never on leather) | "Plate should have plate-only mods" | With only 3 bases per slot and the existing tag filter system, exclusive mods shrink the affix pool too aggressively. A DEX helmet with only 4 possible prefixes feels boring to craft | Use valid_tags to weight toward archetype-appropriate mods while keeping the pool large enough for interesting crafting. A leather helmet CAN roll flat ES (via Tag.ENERGY_SHIELD in valid_tags if desired) but primarily rolls evasion |
| **Weapon range / melee vs ranged split** | Standard ARPG distinction | No spatial combat in idle game. Melee vs ranged has no mechanical meaning when combat is auto-resolved via timers. The distinction would be purely cosmetic | All weapons are equivalent in combat delivery. Differentiate via damage formula (attack vs spell) and implicit, not range |
| **Gem/socket system on items** | PoE's core identity; Last Epoch has it too | Massive scope expansion. Sockets require a new resource type (gems), a linking system, and per-socket UI. This is a separate milestone-scale feature, not part of item base differentiation | Affixes ARE the customization layer. Tag-targeted hammers from v1.7 serve the "choose your build" role that gems serve in PoE |

---

## Feature Dependencies

```
[New Item Bases (10 new bases)]
    |-- requires --> [Existing Item class hierarchy] (Weapon, Armor, Helmet, Boots, Ring)
    |-- requires --> [New SPELL tag + CASTER tag] in tag.gd
    |-- requires --> [New StatTypes] (FLAT_SPELL_DAMAGE, INCREASED_SPELL_DAMAGE, CAST_SPEED, DODGE_CHANCE)
    |-- required-by --> [Loot Table update] (new bases added to drop pool)
    |-- required-by --> [Save/Load update] (new type strings in Item.create_from_dict)
    |-- required-by --> [GameState slots] (gameplay_view must handle new item types)

[Spell Damage Channel]
    |-- requires --> [Wand item base] (INT weapon that uses spell DPS formula)
    |-- requires --> [New StatTypes] (FLAT_SPELL_DAMAGE, INCREASED_SPELL_DAMAGE, CAST_SPEED)
    |-- requires --> [StatCalculator update] (spell DPS formula parallel to attack DPS)
    |-- requires --> [Hero.calculate_damage_ranges update] (spell damage path)
    |-- impacts --> [CombatEngine._on_hero_attack] (damage source may be spell, not attack)

[New Affixes (spell damage, cast speed, dodge)]
    |-- requires --> [New StatTypes] in tag.gd
    |-- requires --> [Enable disabled suffixes] in item_affixes.gd
    |-- requires --> [StatCalculator] spell damage aggregation
    |-- requires --> [Hero.update_stats] to aggregate new stat types
    |-- required-by --> [DefenseCalculator] (dodge chance, damage suppression)

[valid_tags Per Base]
    |-- requires --> [New bases exist] (each base sets its own valid_tags)
    |-- uses --> [Existing has_valid_tag() in Item] (no code change needed)
    |-- impacts --> [Crafting experience] (different bases roll different mod pools)
```

### Dependency Notes

- **New bases are the leaf change:** Each new base is a small GDScript file (~20 lines) extending the existing Weapon/Armor/Helmet/Boots/Ring classes. The class hierarchy already supports all needed base stats.
- **Spell damage is the deepest change:** Adding a parallel damage channel requires StatCalculator, Hero, and CombatEngine updates. This should be built and tested before adding all 10 bases.
- **Enabling disabled suffixes is near-zero risk:** The stubs in item_affixes.gd just need StatType values and hero aggregation. Cast Speed and Dodge Chance are the most impactful enables.
- **Save migration is required:** Item.create_from_dict needs new match cases for each new type string. SAVE_VERSION bump needed.

---

## MVP Definition

### Launch With (v1.8 Phase 1 -- Item Bases)

Minimum viable archetype system. Must create 3 visually and mechanically distinct gear paths.

- [ ] **10 new item base files** -- 2 new per slot (DEX + INT variants): ShortBow, Wand, LeatherArmor, SilkRobe, LeatherHelm, CircletHelm, LeatherBoots, SilkSlippers, JadeRing, SapphireRing
- [ ] **New tags** -- Tag.SPELL, Tag.CASTER added to tag.gd
- [ ] **New StatTypes** -- FLAT_SPELL_DAMAGE, INCREASED_SPELL_DAMAGE, CAST_SPEED (at minimum)
- [ ] **2 new prefixes** -- Flat Spell Damage, %Spell Damage
- [ ] **Enable Cast Speed suffix** -- Uncomment and wire to CAST_SPEED StatType
- [ ] **Spell DPS formula** in StatCalculator -- parallel to attack DPS but using spell base + spell affixes
- [ ] **Wand DPS calculation** -- Wand.update_value() uses spell DPS formula instead of attack DPS
- [ ] **Hero spell damage path** -- Hero.calculate_damage_ranges() handles wand spell damage
- [ ] **Loot table update** -- All 15 bases in drop pool; area level weights apply to all bases equally
- [ ] **Save format update** -- New type strings registered; migration handles existing saves

### Launch With (v1.8 Phase 2 -- Affix Pool Polish)

- [ ] **Enable Dodge Chance suffix** -- DEX defensive identity
- [ ] **Enable Damage Suppression suffix** -- Shared DEX/INT defensive identity
- [ ] **valid_tags tuned per base** -- Each of 15 bases has archetype-appropriate tag set
- [ ] **Defense calculator updates** -- Dodge Chance and Damage Suppression wired to combat

### Add After Validation (v1.9+)

- [ ] **Hybrid bases** (STR/DEX, STR/INT, DEX/INT) -- 1 per slot = 5 more bases; only if 3-archetype system feels complete
- [ ] **Mana as spell resource** -- Mana cost per cast, mana regen stat; only if spell builds feel too "free"
- [ ] **Spell-specific crit** -- Separate SPELL_CRIT_CHANCE stat; only if shared crit feels wrong
- [ ] **Sigil suffix** -- INT-specific defensive suffix; only if ES identity needs more depth

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| 10 new item base files (DEX + INT per slot) | HIGH | LOW | P1 |
| Spell damage as parallel damage channel | HIGH | MEDIUM | P1 |
| 2 new spell prefixes (flat + %) | HIGH | LOW | P1 |
| Enable Cast Speed suffix | HIGH | LOW | P1 |
| Wand spell DPS formula | HIGH | MEDIUM | P1 |
| valid_tags per base (affix pool differentiation) | HIGH | LOW | P1 |
| Loot table + save format update | HIGH | MEDIUM | P1 |
| Enable Dodge Chance suffix | MEDIUM | LOW | P2 |
| Enable Damage Suppression suffix | MEDIUM | LOW | P2 |
| Hybrid bases (STR/DEX, etc.) | LOW | MEDIUM | P3 |
| Mana as spell resource | LOW | HIGH | P3 |
| Spell-specific crit chance | LOW | MEDIUM | P3 |
| Sigil suffix (INT defense) | LOW | LOW | P3 |

**Priority key:**
- P1: Required for v1.8 -- the 3-archetype system is the milestone
- P2: Complete the affix pool; ship in same milestone if time allows
- P3: Future milestone; requires design validation of core archetype system first

---

## Design Principles

### (1) Item Base Stats ARE Archetype Identity

The base item's inherent stats (armor, evasion, ES, base damage, implicit) communicate archetype before any crafting. Players should never need to read affix tags to know "this is a caster helmet." The name + base stat does it.

**Hammertime application:** Each new base has a single primary defense type (not split). BasicArmor: pure armor. LeatherArmor: pure evasion. SilkRobe: pure ES. Simple, readable, immediate.

### (2) Weapon Type Determines Damage Channel

In an idle game, the equipped weapon decides whether the hero deals attack damage or spell damage. This is the single biggest build decision and should feel consequential. Swapping from Sword to Wand should visibly change the DPS number and which affixes matter.

**Hammertime application:** LightSword/ShortBow use attack DPS formula (existing). Wand uses spell DPS formula (new). The hero's `total_dps` reflects whichever channel the weapon provides. No dual-channel complexity.

### (3) Affix Pools Overlap Generously, Diverge on Offense

Defensive suffixes (life, resistances) should be universal -- every build needs survivability. Offensive prefixes diverge: attack builds want flat phys and %phys; spell builds want flat spell and %spell. This creates the crafting decision: "I found a great wand base, but should I craft spell damage or elemental damage on it?"

**Hammertime application:** Suffixes like resistances, life, crit use Tag.DEFENSE or Tag.CRITICAL (no archetype restriction). Offensive prefixes use Tag.ATTACK or Tag.SPELL to gate by weapon type. Defense body/helm/boot bases use Tag.ARMOR, Tag.EVASION, or Tag.ENERGY_SHIELD to gate defensive prefixes.

### (4) Three Archetypes, Not Two or Four

Two archetypes (melee/caster) feels too binary. Four or more (adding summoner, hybrid, etc.) explodes scope without proportional gameplay payoff. Three provides the minimum triangle where each archetype has a natural counter-stat and creates meaningful itemization variety (3 weapons x 3 armors x 3 helmets = 27 possible gear combinations per those 3 slots alone).

**Hammertime application:** STR/DEX/INT. DEX and STR share the attack damage channel but differ in defense type and implicit emphasis (STR = high base damage + armor, DEX = crit + evasion). INT uses spell damage channel + ES. Three is enough.

### (5) Enable Existing Stubs Before Creating New Systems

The codebase already has disabled suffix stubs for Cast Speed, Dodge Chance, Damage Suppression, and Sigil. These were designed for this exact milestone. Enabling them is lower risk and faster than designing new affix systems from scratch.

**Hammertime application:** Uncomment and wire Cast Speed, Dodge Chance, Damage Suppression before creating any new suffix types. Sigil can wait for future INT-defense expansion.

---

## Integration Points with Existing Hammertime System

| Existing Component | Current State | Required Change for v1.8 | Complexity |
|-------------------|---------------|--------------------------|------------|
| `tag.gd` | 22 tags, 19 StatTypes | Add Tag.SPELL, Tag.CASTER; add FLAT_SPELL_DAMAGE, INCREASED_SPELL_DAMAGE, CAST_SPEED StatTypes | LOW |
| `item.gd` | 5 type strings in registry | Add 10 new type strings; update `create_from_dict()` match block | LOW |
| `item_affixes.gd` | 18 prefixes, 10 suffixes (7 enabled) | Add 2 spell prefixes; enable Cast Speed, Dodge Chance, Damage Suppression suffixes | LOW |
| `stat_calculator.gd` | Attack DPS formula only | Add `calculate_spell_dps()` parallel to `calculate_dps()` | MEDIUM |
| `hero.gd` | `calculate_damage_ranges()` assumes attack damage | Add spell damage range path when weapon is Wand | MEDIUM |
| `combat_engine.gd` | `_on_hero_attack()` rolls from damage_ranges | No change needed if Hero provides unified damage_ranges (spell or attack) | LOW |
| `defense_calculator.gd` | Dodge from evasion; no dodge chance stat | Add dodge_chance from gear to evasion-based dodge calculation | LOW |
| `game_state.gd` | 5 item slots, 1 base per slot | No slot change needed; loot table generates from expanded base pool | LOW |
| `loot_table.gd` | Drops from 5 base types | Expand to 15 base types; equal weight within slot, slot selection unchanged | LOW |
| `save_manager.gd` | SAVE_VERSION handles 5 item types | Add 10 new match cases; bump version; migration preserves existing items | MEDIUM |
| `forge_view.gd` / `item_view.gd` | Displays current 5 item types | Must handle new item types in display; UI auto-adapts if using polymorphic `get_display_text()` | LOW |

---

## Sources

**Cross-game archetype analysis (HIGH confidence -- primary game documentation):**
- Path of Exile item system: STR/DEX/INT base types, attribute requirements, defense type mapping (armor/evasion/ES), affix pools filtered by item class and tags
- Path of Exile 2 weapon archetypes: weapon type determines skill access; spell vs attack damage channels; mace/sceptre/wand differentiation
- Last Epoch class-gated affixes: Sentinel/Rogue/Mage/Acolyte armor types with class-specific mod pools; implicit system per base type
- Diablo 4 class-gated items: simplified attribute model; class-specific affixes on shared base types

**Spell vs attack damage design (HIGH confidence -- core ARPG convention):**
- PoE damage calculation: attack damage from weapon base; spell damage from gem level + flat additions; completely separate scaling paths
- Last Epoch spell system: spell damage scales from base skill, not weapon; +spell damage on weapon acts as %more multiplier
- D4 spell system: skill ranks on items; no weapon-base dependency for spells

**Idle ARPG adaptation (MEDIUM confidence -- design reasoning from existing Hammertime patterns):**
- Option C (weapon determines channel) derived from analysis of combat_engine.gd single-timer architecture
- Defense type mapping from existing defense_calculator.gd evasion/armor/ES pipeline
- Affix pool filtering from existing valid_tags + has_valid_tag() pattern in item.gd

**Codebase analysis (HIGH confidence -- direct code review of Hammertime v1.7):**
- `item_affixes.gd` -- Disabled suffix stubs confirmed: Cast Speed, Dodge Chance, Damage Suppression, Sigil
- `tag.gd` -- Tag.MAGIC exists but unused; can repurpose or add Tag.SPELL alongside
- `weapon.gd` -- `update_value()` delegates to StatCalculator; wand can override with spell formula
- `defense_calculator.gd` -- `is_spell: bool` parameter already exists in `calculate_damage_taken()`; spell/attack distinction is already part of the defense pipeline

---

*Feature research for: Hammertime v1.8 Content Pass -- Item Archetypes, Spell Damage, Affix Pool Differentiation*
*Researched: 2026-03-06*
*Confidence: HIGH overall (ARPG archetype conventions are the most standardized design patterns in the genre)*
