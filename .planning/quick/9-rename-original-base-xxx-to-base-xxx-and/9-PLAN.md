---
phase: quick-9
plan: 1
type: execute
wave: 1
depends_on: []
files_modified:
  - models/items/armor.gd
  - models/items/boots.gd
  - models/items/helmet.gd
  - models/items/basic_armor.gd
  - models/items/basic_boots.gd
  - models/items/basic_helmet.gd
  - models/hero.gd
  - scenes/forge_view.gd
autonomous: true
requirements: [QUICK-9]

must_haves:
  truths:
    - "Item base values use `base_xxx` naming (was `original_base_xxx`)"
    - "Computed values after affixes use `computed_xxx` naming (was `base_xxx`)"
    - "BasicArmor and BasicHelmet no longer have FLAT_ARMOR implicits"
    - "BasicArmor and BasicHelmet base_armor values provide armor that was previously from implicits"
    - "Hero stat calculation reads `computed_xxx` correctly"
    - "Forge view displays `computed_xxx` correctly"
    - "Game still runs without errors"
  artifacts:
    - path: "models/items/armor.gd"
      provides: "Renamed vars: base_xxx (immutable), computed_xxx (calculated)"
      contains: "var base_armor"
    - path: "models/items/basic_armor.gd"
      provides: "Armor base value set directly, no FLAT_ARMOR implicit"
    - path: "models/items/basic_helmet.gd"
      provides: "Armor base value set directly, no FLAT_ARMOR implicit"
  key_links:
    - from: "models/items/armor.gd"
      to: "models/hero.gd"
      via: "hero reads computed_xxx from equipped items"
      pattern: "computed_armor|computed_evasion|computed_energy_shield|computed_health"
    - from: "models/items/armor.gd"
      to: "scenes/forge_view.gd"
      via: "forge reads computed_xxx for display and comparison"
      pattern: "computed_armor|computed_evasion|computed_energy_shield|computed_health"
---

<objective>
Rename item stat properties for clarity and remove armor implicits from basic armor items.

Purpose: The current naming is confusing -- `original_base_xxx` is the actual base value and `base_xxx` is the computed value. Rename so `base_xxx` = immutable base, `computed_xxx` = value after affix calculations. Also, BasicArmor and BasicHelmet should get their armor as a direct base stat rather than through a FLAT_ARMOR implicit affix.

Output: All item classes, hero.gd, and forge_view.gd updated with new naming. BasicArmor/BasicHelmet have armor as base values instead of implicits.
</objective>

<execution_context>
@/home/travelboi/.claude/get-shit-done/workflows/execute-plan.md
@/home/travelboi/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@models/items/armor.gd
@models/items/boots.gd
@models/items/helmet.gd
@models/items/basic_armor.gd
@models/items/basic_boots.gd
@models/items/basic_helmet.gd
@models/items/item.gd
@models/hero.gd
@scenes/forge_view.gd
</context>

<tasks>

<task type="auto">
  <name>Task 1: Rename properties in parent item classes (Armor, Boots, Helmet)</name>
  <files>
    models/items/armor.gd
    models/items/boots.gd
    models/items/helmet.gd
  </files>
  <action>
In all three parent item classes, apply the following renames:

**Variable declarations:**
- `var original_base_xxx` --> `var base_xxx` (the immutable base value)
- `var base_xxx` --> `var computed_xxx` (the computed value after affixes)

For armor.gd specifically:
- `var base_armor` --> `var computed_armor`
- `var base_energy_shield` --> `var computed_energy_shield`
- `var base_health` --> `var computed_health`
- `var base_evasion` --> `var computed_evasion`
- `var original_base_armor` --> `var base_armor`
- `var original_base_energy_shield` --> `var base_energy_shield`
- `var original_base_health` --> `var base_health`
- `var original_base_evasion` --> `var base_evasion`

For boots.gd additionally:
- `var base_movement_speed` --> `var computed_movement_speed`
- `var original_base_movement_speed` --> `var base_movement_speed`

For helmet.gd additionally:
- `var base_mana` --> `var computed_mana`
- `var original_base_mana` --> `var base_mana`

**In update_value():**
- All references to `self.original_base_xxx` become `self.base_xxx`
- All assignments to `self.base_xxx = ...` (the computed results) become `self.computed_xxx = ...`
- `self.total_defense = self.base_armor` --> `self.total_defense = self.computed_armor`
- In boots.gd: `self.base_movement_speed = (self.original_base_movement_speed + ...)` --> `self.computed_movement_speed = (self.base_movement_speed + ...)`
- In helmet.gd: `self.base_mana = (self.original_base_mana + ...)` --> `self.computed_mana = (self.base_mana + ...)`

**In get_display_text():**
- All `self.base_xxx` references (these display the computed value) --> `self.computed_xxx`

**Add null-safety for implicit in update_value():**
Currently `all_affixes.append(self.implicit)` has no null check. Add:
```
if self.implicit != null:
    all_affixes.append(self.implicit)
```
This is needed because BasicArmor/BasicHelmet will lose their implicits in Task 2.

Also add null-safety for implicit display in get_display_text() -- wrap the implicit output line in `if self.implicit != null:`.
  </action>
  <verify>
Run `grep -rn "original_base_" models/items/armor.gd models/items/boots.gd models/items/helmet.gd` returns no matches.
Run `grep -rn "var computed_" models/items/armor.gd models/items/boots.gd models/items/helmet.gd` shows the computed vars exist.
Run `grep -rn "var base_" models/items/armor.gd models/items/boots.gd models/items/helmet.gd` shows the base vars exist (no original_ prefix).
  </verify>
  <done>
All three parent item classes use `base_xxx` for immutable base values and `computed_xxx` for affix-computed values. No `original_base_` references remain. Null-safety added for implicit in update_value() and get_display_text().
  </done>
</task>

<task type="auto">
  <name>Task 2: Update basic items, remove armor implicits, update hero.gd and forge_view.gd</name>
  <files>
    models/items/basic_armor.gd
    models/items/basic_boots.gd
    models/items/basic_helmet.gd
    models/items/item.gd
    models/hero.gd
    scenes/forge_view.gd
  </files>
  <action>
**Basic item subclasses -- rename assignments in _init():**

In all three basic items, rename property assignments to match new parent vars:
- `self.original_base_xxx = N` --> `self.base_xxx = N`
- `self.base_xxx = N` (the old computed init) --> `self.computed_xxx = N`

**BasicArmor (basic_armor.gd) -- remove armor implicit, add base value:**
- Remove the armor implicit line: `self.implicit = Implicit.new("Armor", ...)`
- Set `self.implicit = null`
- Set `self.base_armor = 5` (approximate midpoint of what the implicit would have rolled at tier 8: value range 3-8)
- Keep `self.computed_armor = 0` (will be calculated by update_value)

**BasicHelmet (basic_helmet.gd) -- remove armor implicit, add base value:**
- Remove the armor implicit line: `self.implicit = Implicit.new("Armor", ...)`
- Set `self.implicit = null`
- Set `self.base_armor = 3` (approximate midpoint of what the implicit would have rolled at tier 8: value range 2-5)
- Keep `self.computed_armor = 0` (will be calculated by update_value)

**BasicBoots (basic_boots.gd) -- keep its Movement Speed implicit (not armor), just rename vars:**
- Only apply the variable renames (original_base_ -> base_, base_ -> computed_)
- Keep its Movement Speed implicit as-is

**item.gd -- add null-safety for implicit in display() and get_display_text():**
- In `display()`: wrap the implicit print line (line ~149) in `if self.implicit != null:`
- In `get_display_text()`: wrap the implicit output line (line ~178) in `if self.implicit != null:`
- In `to_dict()`: the existing `implicit.to_dict() if implicit != null else {}` is already null-safe, no change needed
- In `create_from_dict()`: the implicit restore block already checks `if not implicit_data.is_empty()`, no change needed
- In `update_value()`: base class is a no-op pass, no change needed

**hero.gd -- rename all property reads:**
- All `armor_item.base_armor` --> `armor_item.computed_armor`
- All `armor_item.base_evasion` --> `armor_item.computed_evasion`
- All `armor_item.base_energy_shield` --> `armor_item.computed_energy_shield`
- All `armor_item.base_health` --> `armor_item.computed_health`
- Update the property-existence checks: `if "base_armor" in armor_item` --> `if "computed_armor" in armor_item`
- Same pattern for evasion, energy_shield, health
- Update the comments referencing `base_health/base_armor` to say `computed_health/computed_armor`

**scenes/forge_view.gd -- rename all property reads:**
This file has many references to `.base_armor`, `.base_evasion`, `.base_energy_shield`, `.base_health`, `.base_mana`, `.base_movement_speed`. ALL must become `computed_` prefix:
- `eq_item.base_armor` --> `eq_item.computed_armor` (and similar for all stats)
- `crafted.base_armor` --> `crafted.computed_armor` (and similar)
- `armor_item.base_armor` --> `armor_item.computed_armor`
- `boots_item.base_armor` --> `boots_item.computed_armor`
- `boots_item.base_movement_speed` --> `boots_item.computed_movement_speed`
- `helmet_item.base_armor` --> `helmet_item.computed_armor`
- `helmet_item.base_mana` --> `helmet_item.computed_mana`
- Apply to ALL occurrences in the file (approx 50+ references across stat comparison and stat display functions)
  </action>
  <verify>
Run `grep -rn "original_base_" models/items/basic_*.gd` returns no matches.
Run `grep -rn "\.base_armor\|\.base_evasion\|\.base_energy_shield\|\.base_health\|\.base_mana\|\.base_movement_speed" models/hero.gd scenes/forge_view.gd` returns no matches (only computed_ references should remain).
Run `grep -rn "Implicit.new" models/items/basic_armor.gd models/items/basic_helmet.gd` returns no matches.
Run `grep -rn "computed_armor\|computed_evasion\|computed_energy_shield\|computed_health" models/hero.gd` shows the hero reads computed values.
  </verify>
  <done>
Basic items use new naming. BasicArmor and BasicHelmet have null implicit with armor as base values. Hero and forge_view read computed_xxx instead of base_xxx. No references to old naming remain outside of variable declarations in parent classes.
  </done>
</task>

</tasks>

<verification>
1. `grep -rn "original_base_" models/ scenes/` returns zero matches across the entire codebase
2. `grep -rn "\.base_armor\b\|\.base_evasion\b\|\.base_energy_shield\b\|\.base_health\b\|\.base_mana\b\|\.base_movement_speed\b" models/hero.gd scenes/forge_view.gd` returns zero matches (hero and forge only reference computed_ now)
3. BasicArmor and BasicHelmet have `self.implicit = null` and `self.base_armor` set to a fixed value
4. BasicBoots still has its Movement Speed implicit
5. Run the game -- no crash on load, items display correctly, forge comparison works
</verification>

<success_criteria>
- Zero references to `original_base_` anywhere in GDScript files
- Parent item classes declare `base_xxx` (immutable) and `computed_xxx` (calculated) properties
- Hero.gd and forge_view.gd read `computed_xxx` from equipped items
- BasicArmor/BasicHelmet have no FLAT_ARMOR implicit; armor comes from base_armor directly
- BasicBoots retains its Movement Speed implicit unchanged
- Null-safe implicit handling in update_value(), display(), get_display_text()
</success_criteria>

<output>
After completion, create `.planning/quick/9-rename-original-base-xxx-to-base-xxx-and/9-SUMMARY.md`
</output>
