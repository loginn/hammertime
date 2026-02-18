---
created: 2026-02-18T13:15:37.125Z
title: Remove caster mods from physical weapons
area: general
files:
  - autoloads/item_affixes.gd
  - models/affixes/affix.gd
  - models/items/item.gd
---

## Problem

Light Sword (and potentially other physical weapon bases) can roll caster-oriented affixes like spell damage. The tag-based affix filtering doesn't distinguish between weapon subtypes — any prefix/suffix that passes `has_valid_tag()` can appear on any weapon. This means physical weapons can get useless mods, diluting the affix pool and making crafting feel worse.

## Solution

Add tag-based filtering to prevent caster mods from rolling on physical weapons. Options:
- Add a `CASTER` tag to spell-oriented affixes and exclude them from physical weapon pools
- Add a `MELEE` / `PHYSICAL_WEAPON` tag to physical weapons and use it in affix pool filtering
- Filter at the `add_prefix()`/`add_suffix()` level in item.gd using item-type-specific exclusion lists

Need to audit which affixes are caster-only and which weapon types should exclude them.
