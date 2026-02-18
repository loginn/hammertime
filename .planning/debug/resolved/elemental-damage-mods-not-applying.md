---
status: resolved
trigger: "elemental-damage-mods-not-applying"
created: 2026-02-18T00:00:00Z
updated: 2026-02-18T00:07:00Z
---

## Current Focus

hypothesis: CONFIRMED - Elemental damage affixes have empty stat_types arrays, so they are never processed by StatCalculator.calculate_dps()
test: Compare physical damage affixes vs elemental damage affixes in item_affixes.gd
expecting: Physical affixes should have StatType values while elemental affixes have empty arrays
next_action: Form fix strategy - decide whether to add elemental-specific StatTypes or route through existing FLAT_DAMAGE

## Symptoms

expected: Elemental damage mods on weapons (e.g., +fire damage) should increase the hero's total DPS shown in stats AND deal extra damage in combat on top of physical damage.
actual: Both hero DPS and damage in fights don't change after equipping a weapon with elemental damage mods. The mods appear to have no effect.
errors: None reported
reproduction: Craft or acquire a weapon with elemental damage mods, equip it, observe DPS doesn't change, fight monsters and observe damage doesn't change.
started: Unknown — may never have worked.

## Eliminated

## Evidence

- timestamp: 2026-02-18T00:01:00Z
  checked: item_affixes.gd lines 20-36 - elemental damage affix definitions
  found: Elemental damage affixes have EMPTY stat_types arrays ([])
  implication: StatCalculator.calculate_dps() iterates over stat_types to apply damage bonuses. Empty arrays = affixes are never processed

- timestamp: 2026-02-18T00:02:00Z
  checked: stat_calculator.gd calculate_dps() function
  found: Only processes affixes with Tag.StatType.FLAT_DAMAGE or Tag.StatType.INCREASED_DAMAGE
  implication: Elemental damage affixes need appropriate StatType values to be included in DPS calculation

- timestamp: 2026-02-18T00:03:00Z
  checked: tag.gd StatType enum
  found: No elemental-specific StatType values (no FIRE_DAMAGE, COLD_DAMAGE, LIGHTNING_DAMAGE entries)
  implication: Need to either add elemental StatTypes OR route elemental damage through existing FLAT_DAMAGE/INCREASED_DAMAGE types

- timestamp: 2026-02-18T00:04:00Z
  checked: weapon.gd update_value() and item_affixes.gd physical damage affixes
  found: "Physical Damage" affix uses [Tag.StatType.FLAT_DAMAGE], "%Physical Damage" uses [Tag.StatType.INCREASED_DAMAGE]
  implication: Physical affixes work because they have proper StatTypes. Elemental affixes just need the same treatment

- timestamp: 2026-02-18T00:05:00Z
  checked: weapon.gd properties
  found: Weapon has separate lightning_dps, cold_dps, fire_dps, phys_dps properties (lines 7-11)
  implication: System was designed to track elemental damage separately but affixes never populate it

## Resolution

root_cause: Elemental damage affixes in item_affixes.gd have empty stat_types arrays ([]), so StatCalculator.calculate_dps() never processes them. Physical damage works because it uses [Tag.StatType.FLAT_DAMAGE] and [Tag.StatType.INCREASED_DAMAGE]. The same pattern should be applied to elemental affixes.

fix: Updated item_affixes.gd to add proper stat_types to all 7 elemental damage affixes. Percentage elemental damage affixes (%Elemental, %Cold, %Fire, %Lightning) now use [Tag.StatType.INCREASED_DAMAGE]. Flat elemental damage affixes (Lightning Damage, Fire Damage, Cold Damage) now use [Tag.StatType.FLAT_DAMAGE]. This routes them through the same calculation path as physical damage in StatCalculator.calculate_dps().

verification: Logic verification completed.

**Before fix:**
- Elemental damage affixes had empty stat_types: []
- StatCalculator.calculate_dps() loops through affixes checking for Tag.StatType.FLAT_DAMAGE and Tag.StatType.INCREASED_DAMAGE
- Empty arrays never match these checks, so elemental affixes were skipped
- Result: No DPS increase from elemental mods

**After fix:**
- Flat elemental affixes (Fire Damage, Cold Damage, Lightning Damage) now have [Tag.StatType.FLAT_DAMAGE]
- Percentage elemental affixes (%Fire, %Cold, %Lightning, %Elemental) now have [Tag.StatType.INCREASED_DAMAGE]
- StatCalculator.calculate_dps() will now process them in Step 1 (flat) and Step 2 (percentage)
- Result: Elemental damage increases total DPS just like physical damage

**Trace example:**
1. Weapon has base_damage=10, base_speed=1.0
2. Weapon has "Fire Damage" affix with value=5 and stat_types=[Tag.StatType.FLAT_DAMAGE]
3. StatCalculator.calculate_dps() Step 1 loops affixes, finds FLAT_DAMAGE, adds 5 to damage (now 15)
4. Final DPS calculation uses damage=15 instead of 10
5. Hero DPS display shows increased value ✓
6. Combat uses hero.total_dps which comes from weapon.dps ✓

**Combat verification:**
- combat_engine.gd line 80: damage_per_hit = hero.total_dps / hero_attack_speed
- hero.total_dps comes from hero.calculate_dps() which sums weapon.dps (line 97)
- weapon.dps comes from StatCalculator.calculate_dps() (weapon.gd line 20-22)
- Elemental affixes now flow through entire chain ✓

files_changed: [autoloads/item_affixes.gd]
