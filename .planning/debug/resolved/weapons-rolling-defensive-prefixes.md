---
status: resolved
trigger: "weapons-rolling-defensive-prefixes"
created: 2026-02-17T00:00:00Z
updated: 2026-02-17T00:30:00Z
---

## Current Focus

hypothesis: ROOT CAUSE SOLUTION IDENTIFIED - Defensive suffixes (resistances) need BOTH Tag.DEFENSE (for armor) AND Tag.WEAPON (for weapons/rings). Remove Tag.DEFENSE from LightSword/Ring, add Tag.WEAPON to defensive suffixes.
test: Implement fix - add Tag.WEAPON to resistance suffixes, remove Tag.DEFENSE from weapon classes
expecting: Weapons will roll offensive prefixes + defensive suffixes (resistances), armor will roll defensive prefixes + defensive suffixes
next_action: Apply the fix

## Symptoms

expected: Weapons only roll offensive prefixes (physical damage, attack speed, crit chance, etc.) and can roll defensive suffixes (resistances, etc.). Defensive prefixes (flat armor, % armor, flat evasion, % evasion, flat ES, % ES, flat health, % health, flat mana) should NOT appear on weapons.
actual: Weapons can roll defensive prefixes, which doesn't make sense from a game design perspective — armor/evasion/ES/health on a weapon prefix slot is wrong.
errors: None — this is a logic/design bug, not a crash
reproduction: Use crafting hammers (Runic, Forge) on a weapon and observe that defensive prefixes can appear
started: Likely since Phase 9 (Defensive Prefix Foundation) added defensive prefixes. The tag filtering may not exclude weapons from the defensive prefix pool.

## Eliminated

## Evidence

- timestamp: 2026-02-17T00:05:00Z
  checked: autoloads/item_affixes.gd lines 38-120
  found: Defensive prefixes (Flat Armor, %Armor, Evasion, %Evasion, Energy Shield, %Energy Shield, Health, %Health, Mana) all have [Tag.DEFENSE, ...] but NO Tag.WEAPON
  implication: Defensive prefixes are not explicitly marked as weapon-compatible

- timestamp: 2026-02-17T00:06:00Z
  checked: models/items/item.gd lines 212-216 (has_valid_tag function)
  found: Function checks if ANY tag from item.valid_tags appears in affix.tags - returns true on overlap
  implication: If an item has Tag.DEFENSE in valid_tags, it can roll ANY affix with Tag.DEFENSE

- timestamp: 2026-02-17T00:07:00Z
  checked: models/items/light_sword.gd line 12
  found: LightSword._init() sets valid_tags = [Tag.PHYSICAL, Tag.ATTACK, Tag.CRITICAL, Tag.DEFENSE]
  implication: THIS IS THE BUG - LightSword includes Tag.DEFENSE, allowing defensive prefixes to match

- timestamp: 2026-02-17T00:08:00Z
  checked: models/items/item.gd lines 219-242 (add_prefix function)
  found: add_prefix() uses has_valid_tag(prefix) to build valid_prefixes pool
  implication: Defensive prefixes pass the filter because both item and affix have Tag.DEFENSE

- timestamp: 2026-02-17T00:12:00Z
  checked: autoloads/item_affixes.gd lines 142-177 (defensive suffixes)
  found: Resistance suffixes (Fire, Cold, Lightning, All) ONLY have [Tag.DEFENSE], no Tag.WEAPON
  implication: If Tag.DEFENSE is removed from weapons, they lose ability to roll resistance suffixes too - NOT the desired behavior

- timestamp: 2026-02-17T00:15:00Z
  checked: models/items/basic_ring.gd line 12
  found: BasicRing has valid_tags = [Tag.ATTACK, Tag.CRITICAL, Tag.SPEED, Tag.WEAPON, Tag.DEFENSE]
  implication: Rings also have the same bug - they can roll defensive PREFIXES when they shouldn't

- timestamp: 2026-02-17T00:16:00Z
  checked: models/items/basic_armor.gd line 12
  found: BasicArmor has valid_tags = [Tag.DEFENSE, Tag.ARMOR, Tag.ENERGY_SHIELD] - no Tag.WEAPON
  implication: Armor correctly does NOT have Tag.WEAPON, so it won't roll offensive prefixes

## Resolution

root_cause: Weapons and rings include Tag.DEFENSE in valid_tags, which allows them to roll defensive PREFIXES (armor, evasion, ES, health, mana) via has_valid_tag(). The tag system doesn't distinguish between defensive prefixes (which should be armor-only) and defensive suffixes (resistances, which should be universal). Defensive suffixes only have Tag.DEFENSE, so they're currently gated by the item having Tag.DEFENSE.

fix: Two-part fix to properly separate defensive prefixes from defensive suffixes:
1. Added Tag.WEAPON to all defensive suffixes (Life, Evade, Armor, Physical Reduction, Magical Reduction, Fire/Cold/Lightning/All Resistances, Dodge Chance, Dmg Suppression Chance) in item_affixes.gd - this allows weapons to roll defensive suffixes
2. Removed Tag.DEFENSE from LightSword.valid_tags and BasicRing.valid_tags, replaced with Tag.WEAPON - this prevents weapons from rolling defensive prefixes while preserving ability to roll offensive prefixes and defensive suffixes

verification: Manual logic trace verification (Godot not available for runtime testing):

**Test 1: Weapons CANNOT roll defensive prefixes**
- LightSword.valid_tags = [Tag.PHYSICAL, Tag.ATTACK, Tag.CRITICAL, Tag.WEAPON]
- Defensive prefix "Flat Armor" tags = [Tag.DEFENSE, Tag.ARMOR]
- has_valid_tag() checks for overlap → No overlap → Cannot roll ✓

**Test 2: Weapons CAN roll offensive prefixes**
- LightSword.valid_tags = [Tag.PHYSICAL, Tag.ATTACK, Tag.CRITICAL, Tag.WEAPON]
- Offensive prefix "Physical Damage" tags = [Tag.PHYSICAL, Tag.FLAT, Tag.WEAPON]
- has_valid_tag() checks for overlap → Tag.PHYSICAL and Tag.WEAPON match → Can roll ✓

**Test 3: Weapons CAN roll defensive suffixes (resistances)**
- LightSword.valid_tags = [Tag.PHYSICAL, Tag.ATTACK, Tag.CRITICAL, Tag.WEAPON]
- Resistance suffix "Fire Resistance" tags = [Tag.DEFENSE, Tag.WEAPON] (AFTER FIX)
- has_valid_tag() checks for overlap → Tag.WEAPON matches → Can roll ✓

**Test 4: Armor CAN still roll defensive prefixes**
- BasicArmor.valid_tags = [Tag.DEFENSE, Tag.ARMOR, Tag.ENERGY_SHIELD]
- Defensive prefix "Flat Armor" tags = [Tag.DEFENSE, Tag.ARMOR]
- has_valid_tag() checks for overlap → Tag.DEFENSE and Tag.ARMOR match → Can roll ✓

**Test 5: Armor CAN still roll defensive suffixes**
- BasicArmor.valid_tags = [Tag.DEFENSE, Tag.ARMOR, Tag.ENERGY_SHIELD]
- Resistance suffix "Fire Resistance" tags = [Tag.DEFENSE, Tag.WEAPON] (AFTER FIX)
- has_valid_tag() checks for overlap → Tag.DEFENSE matches → Can roll ✓

**Test 6: Rings follow same behavior as weapons**
- BasicRing.valid_tags = [Tag.ATTACK, Tag.CRITICAL, Tag.SPEED, Tag.WEAPON] (AFTER FIX)
- Cannot roll defensive prefixes (no Tag.DEFENSE) ✓
- Can roll offensive prefixes (has Tag.WEAPON) ✓
- Can roll resistances (has Tag.WEAPON matching suffix Tag.WEAPON) ✓

All verification tests pass via logic trace.
files_changed: [
  "autoloads/item_affixes.gd",
  "models/items/light_sword.gd",
  "models/items/basic_ring.gd"
]
