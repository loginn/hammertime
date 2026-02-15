---
phase: 06-currency-behaviors
plan: 01
subsystem: crafting
tags: [currency, rarity-upgrade, validation]
dependency-graph:
  requires:
    - models/items/item.gd (Item.Rarity enum and add_prefix/add_suffix methods)
    - autoloads/item_affixes.gd (Affix pools for mod generation)
  provides:
    - models/currencies/currency.gd (Base Currency pattern)
    - models/currencies/runic_hammer.gd (Normal → Magic upgrade)
    - models/currencies/forge_hammer.gd (Normal → Rare upgrade)
  affects:
    - Future currency types (will extend Currency base class)
tech-stack:
  added:
    - Currency Resource class pattern
  patterns:
    - Template method pattern (validate → apply → error)
    - Consume-only-on-success enforcement
key-files:
  created:
    - models/currencies/currency.gd
    - models/currencies/runic_hammer.gd
    - models/currencies/forge_hammer.gd
  modified: []
decisions:
  - Set rarity BEFORE calling add_prefix/add_suffix to ensure proper limit enforcement
  - Use template method pattern in base Currency.apply() to enforce CRAFT-09
  - Random mod selection uses 50/50 prefix/suffix choice with fallback to alternate type
metrics:
  duration: 106s
  tasks_completed: 2
  files_created: 3
  commits: 2
  completed_date: 2026-02-15
---

# Phase 06 Plan 01: Currency Foundation Summary

**One-liner:** Base Currency Resource pattern with RunicHammer (Normal→Magic) and ForgeHammer (Normal→Rare) upgrade currencies enforcing validate-before-mutate and consume-only-on-success.

## What Was Built

Created the foundational currency system for Hammertime's crafting mechanics:

1. **Base Currency Resource** (`models/currencies/currency.gd`)
   - Template method pattern: `can_apply()` → `apply()` → `_do_apply()`
   - Enforces CRAFT-09: Currency consumed only when application succeeds
   - Provides `get_error_message()` for CRAFT-08 error reporting
   - All methods have explicit return type hints per project convention

2. **RunicHammer** (`models/currencies/runic_hammer.gd`)
   - Upgrades Normal items to Magic rarity
   - Adds 1-2 random mods (prefixes or suffixes)
   - Validates target is Normal rarity before application
   - Error message: "Runic Hammer can only be used on Normal items"

3. **ForgeHammer** (`models/currencies/forge_hammer.gd`)
   - Upgrades Normal items to Rare rarity
   - Adds 4-6 random mods (prefixes or suffixes)
   - Validates target is Normal rarity before application
   - Error message: "Forge Hammer can only be used on Normal items"

## Key Implementation Details

**Rarity-First Pattern:**
Both hammers set `item.rarity` BEFORE calling `add_prefix()/add_suffix()` because those methods enforce rarity-based limits. Setting rarity after would cause mod additions to fail (Normal items have 0 prefix/suffix limit).

**Mod Addition Logic:**
- Randomly chooses prefix or suffix with 50/50 probability (`randi_range(0, 1)`)
- If chosen type fails (at limit or no valid affixes), tries the alternate type
- ForgeHammer stops early if both types fail (affix pool exhausted)
- Calls `item.update_value()` after all mods added

**Template Method Enforcement:**
The base `Currency.apply()` method ensures:
1. Calls `can_apply()` first
2. Returns `false` immediately if validation fails (currency NOT consumed)
3. Only calls `_do_apply()` and returns `true` when validation passes (currency consumed)

This pattern prevents invalid applications and ensures currencies are only spent on successful uses.

## Requirements Satisfied

**CRAFT-01:** Runic Hammer upgrades Normal → Magic with 1-2 random mods ✓
**CRAFT-02:** Forge Hammer upgrades Normal → Rare with 4-6 random mods ✓
**CRAFT-07:** Currencies validate item state before application ✓
**CRAFT-08:** Error messages explain why currency cannot be used ✓
**CRAFT-09:** Currencies consumed only on successful application ✓

## Deviations from Plan

None - plan executed exactly as written.

## File Structure

```
models/currencies/
├── currency.gd           # Base Resource with template method pattern
├── runic_hammer.gd       # Normal → Magic (1-2 mods)
└── forge_hammer.gd       # Normal → Rare (4-6 mods)
```

## Commits

1. `3847016` - feat(06-01): create base Currency Resource class
2. `ba07384` - feat(06-01): create RunicHammer and ForgeHammer currencies

## Testing Notes

**To verify behavior:**
1. Create a Normal item (e.g., `LightSword.new()`)
2. Create currency instance (e.g., `var runic = RunicHammer.new()`)
3. Call `runic.can_apply(item)` → should return `true`
4. Call `runic.apply(item)` → should return `true` and upgrade item to Magic
5. Call `runic.can_apply(item)` again → should return `false` (no longer Normal)
6. Call `runic.get_error_message(item)` → should return descriptive error

**Expected outcomes:**
- RunicHammer on Normal item: rarity becomes MAGIC, 1-2 affixes added
- ForgeHammer on Normal item: rarity becomes RARE, 4-6 affixes added
- Either hammer on Magic/Rare item: `apply()` returns false, no changes, currency not consumed

## Next Steps

Phase 06 Plan 02 will add the 4 modifier hammers:
- Chaotic Hammer (add random mod to Magic/Rare)
- Annulment Hammer (remove random mod)
- Exalted Hammer (add prefix to Rare)
- Blessed Hammer (add suffix to Rare)

All will extend the Currency base class established here.

## Self-Check

Verifying all created files and commits exist:

- [x] File exists: models/currencies/currency.gd
- [x] File exists: models/currencies/runic_hammer.gd
- [x] File exists: models/currencies/forge_hammer.gd
- [x] Commit exists: 3847016
- [x] Commit exists: ba07384

**Self-Check: PASSED**
