---
status: resolved
trigger: "Armor stat calculation is wrong - base/implicit armor of 20 with 27% Armor prefix shows 46 instead of ~25"
created: 2026-02-16T00:00:00Z
updated: 2026-02-16T00:00:00Z
---

## Current Focus

hypothesis: CONFIRMED - Two bugs combine to produce the wrong total
test: Traced full calculation chain across all relevant files
expecting: Identified exact calculation that produces 46 and the missing implicit contribution
next_action: Write up findings

## Symptoms

expected: An armor item with base/implicit armor of 20 and a 27% Armor prefix should show total armor ~25 (20 * 1.27)
actual: Hero View shows total armor as 46
errors: No errors - just wrong math result
reproduction: Craft a BasicArmor with a %Armor prefix and optionally an Armor suffix, equip it, observe Hero View stats
started: Phase 09 (defensive prefixes with percentage stat calculation)

## Eliminated

- hypothesis: "calculate_percentage_stat divides incorrectly or skips /100.0"
  evidence: stat_calculator.gd line 71 clearly does `affix.value / 100.0` -- verified correct
  timestamp: 2026-02-16

- hypothesis: "Hero.calculate_defense() applies percentage on top of already-modified base_armor"
  evidence: hero.gd lines 107-151 just sums `armor_item.base_armor` -- no percentage logic
  timestamp: 2026-02-16

- hypothesis: "update_value() double-counts original_base_armor"
  evidence: armor.gd lines 19-34 correctly uses original_base_armor once for flat, then applies % to result
  timestamp: 2026-02-16

- hypothesis: "Display reads stale or different value than calculation"
  evidence: hero_view.gd line 204 reads GameState.hero.get_total_armor() which returns hero.total_armor set by calculate_defense() -- sequential call order, no stale state
  timestamp: 2026-02-16

## Evidence

- timestamp: 2026-02-16
  checked: Affix constructor in models/affixes/affix.gd lines 18-38
  found: Affix._init() has `p_stat_types: Array[int] = []` as 6th parameter. Value calculation uses tier system: `min_value = base_min * (tier_range.y + 1 - tier)`, `max_value = base_max * (tier_range.y + 1 - tier)`.
  implication: Any Affix constructed without explicitly passing stat_types gets an empty array -- won't match any StatType filter

- timestamp: 2026-02-16
  checked: BasicArmor constructor in models/items/basic_armor.gd line 15
  found: `Implicit.new("Armor", Affix.AffixType.IMPLICIT, 3, 8, [Tag.ARMOR, Tag.DEFENSE])` -- only 5 args passed, stat_types defaults to []
  implication: The implicit "Armor" affix has NO stat_types -- its value is NEVER picked up by calculate_flat_stat or calculate_percentage_stat

- timestamp: 2026-02-16
  checked: BasicHelmet constructor in models/items/basic_helmet.gd line 15
  found: Same pattern: `Implicit.new("Armor", Affix.AffixType.IMPLICIT, 2, 5, [Tag.ARMOR, Tag.DEFENSE])` -- no stat_types
  implication: Helmet implicit also loses its armor contribution

- timestamp: 2026-02-16
  checked: BasicBoots constructor in models/items/basic_boots.gd lines 15-17
  found: `Implicit.new("Movement Speed", Affix.AffixType.IMPLICIT, 1, 3, [Tag.SPEED, Tag.MOVEMENT])` -- no stat_types
  implication: Boots implicit movement speed is also purely cosmetic

- timestamp: 2026-02-16
  checked: Armor.update_value() in models/items/armor.gd lines 14-50
  found: flat_armor = original_base_armor + calculate_flat_stat(all_affixes, FLAT_ARMOR), then base_armor = calculate_percentage_stat(flat_armor, all_affixes, PERCENT_ARMOR)
  implication: Since implicit has empty stat_types, FLAT_ARMOR lookup returns 0 for implicit. Implicit's armor value is lost entirely.

- timestamp: 2026-02-16
  checked: StatCalculator.calculate_flat_stat in models/stats/stat_calculator.gd lines 55-60
  found: Iterates affixes, checks `if stat_type in affix.stat_types`. For implicit with stat_types=[], this is always false.
  implication: Implicit value never contributes to flat stat totals

- timestamp: 2026-02-16
  checked: ItemAffixes prefix/suffix definitions in autoloads/item_affixes.gd
  found: "%Armor" prefix (line 49-56) has stat_types=[PERCENT_ARMOR]. "Armor" suffix (line 139) has stat_types=[FLAT_ARMOR]. "Flat Armor" prefix (line 40-47) has stat_types=[FLAT_ARMOR].
  implication: Explicit affixes have correct stat_types -- only implicits are missing them

- timestamp: 2026-02-16
  checked: Mathematical reconstruction of the reported value 46
  found: BasicArmor original_base_armor=15. If a Magic item has both "%Armor" prefix (value=27) AND "Armor" suffix (value=22, stat_types=[FLAT_ARMOR]), then: flat_armor = 15 + 22 = 37, base_armor = int(37 * 1.27) = int(46.99) = 46. EXACT MATCH.
  implication: The reported 46 is produced by a hidden flat armor suffix the user may not have accounted for, combined with the implicit NOT being counted (user sees implicit value ~20 and assumes that's the base)

- timestamp: 2026-02-16
  checked: Affix tier values for "Armor" suffix and "%Armor" prefix
  found: "Armor" suffix (base_min=2, base_max=10, tier_range=1-8). At tier 5: min=8, max=40. Value 22 is within range. "%Armor" prefix (base_min=1, base_max=3, tier_range=1-30). At tier 4: min=27, max=81. Value 27 is within range.
  implication: Both values are achievable within the tier system

## Resolution

root_cause: |
  **Two bugs combine to cause the wrong armor total:**

  **Bug 1 (Primary): Implicit affixes on all armor-type items have no stat_types.**

  In `models/items/basic_armor.gd` line 15, the implicit is constructed as:
  ```gdscript
  Implicit.new("Armor", Affix.AffixType.IMPLICIT, 3, 8, [Tag.ARMOR, Tag.DEFENSE])
  ```
  This passes only 5 arguments. The 6th parameter `p_stat_types` defaults to `[]` (empty array) in `models/affixes/affix.gd` line 24. As a result, `StatCalculator.calculate_flat_stat()` (line 58: `if stat_type in affix.stat_types`) never matches the implicit, and its armor value is completely ignored in calculations.

  The same bug exists in:
  - `models/items/basic_helmet.gd` line 15 (implicit "Armor" missing `[Tag.StatType.FLAT_ARMOR]`)
  - `models/items/basic_boots.gd` line 15-17 (implicit "Movement Speed" missing `[Tag.StatType.MOVEMENT_SPEED]`)

  **Bug 2 (Misleading display): The implicit value appears in the item tooltip but doesn't affect stats.**

  The user sees "Implicit: Armor ~ value: 20" and reasonably assumes this 20 is part of the armor stat. But `original_base_armor` is 15 (BasicArmor), and the implicit's 20 goes nowhere. The user thinks the base is 20 when it's actually 15.

  **The exact calculation that produces 46:**

  A Magic BasicArmor with two mods -- a "%Armor" prefix (value=27) and an "Armor" suffix (value=22, stat_types=[FLAT_ARMOR]):
  1. `flat_armor = original_base_armor + flat_stat_sum = 15 + 22 = 37`
  2. `base_armor = int(37 * (1.0 + 27/100.0)) = int(37 * 1.27) = int(46.99) = 46`

  The implicit value (~20) is displayed but not included. If the user accounts only for the "%Armor" prefix and thinks the base is 20, they expect `20 * 1.27 = 25`, not 46.

fix: |
  Add the missing stat_types to all armor-type item implicits:

  **File: models/items/basic_armor.gd, line 15**
  Change:
  ```gdscript
  self.implicit = Implicit.new("Armor", Affix.AffixType.IMPLICIT, 3, 8, [Tag.ARMOR, Tag.DEFENSE])
  ```
  To:
  ```gdscript
  self.implicit = Implicit.new("Armor", Affix.AffixType.IMPLICIT, 3, 8, [Tag.ARMOR, Tag.DEFENSE], [Tag.StatType.FLAT_ARMOR])
  ```

  **File: models/items/basic_helmet.gd, line 15**
  Change:
  ```gdscript
  self.implicit = Implicit.new("Armor", Affix.AffixType.IMPLICIT, 2, 5, [Tag.ARMOR, Tag.DEFENSE])
  ```
  To:
  ```gdscript
  self.implicit = Implicit.new("Armor", Affix.AffixType.IMPLICIT, 2, 5, [Tag.ARMOR, Tag.DEFENSE], [Tag.StatType.FLAT_ARMOR])
  ```

  **File: models/items/basic_boots.gd, lines 15-17**
  Change:
  ```gdscript
  self.implicit = Implicit.new(
      "Movement Speed", Affix.AffixType.IMPLICIT, 1, 3, [Tag.SPEED, Tag.MOVEMENT]
  )
  ```
  To:
  ```gdscript
  self.implicit = Implicit.new(
      "Movement Speed", Affix.AffixType.IMPLICIT, 1, 3, [Tag.SPEED, Tag.MOVEMENT], [Tag.StatType.MOVEMENT_SPEED]
  )
  ```

  After this fix, implicit values will be properly included in flat stat sums, and the percentage modifier will apply to the correct total base (original_base + implicit + flat affixes).

  Note: With the fix, the expected behavior for BasicArmor (original_base=15, implicit=20, %Armor=27, Armor suffix=22) would be:
  flat_armor = 15 + 20 + 22 = 57, base_armor = int(57 * 1.27) = int(72.39) = 72.
  For just an implicit of 20 and %Armor of 27 with no flat suffix:
  flat_armor = 15 + 20 = 35, base_armor = int(35 * 1.27) = int(44.45) = 44.

verification: Not yet applied -- diagnosis only
files_changed: []
