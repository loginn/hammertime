---
phase: 06-currency-behaviors
plan: 02
subsystem: crafting
tags: [currency, mod-manipulation, validation]
dependency-graph:
  requires:
    - models/items/item.gd (Item.Rarity enum and affix arrays)
    - models/affixes/affix.gd (Affix.reroll() method)
    - models/currencies/currency.gd (Base Currency pattern)
    - autoloads/item_affixes.gd (Affix pools for mod generation)
  provides:
    - models/currencies/tack_hammer.gd (Add mod to Magic items)
    - models/currencies/grand_hammer.gd (Add mod to Rare items)
    - models/currencies/claw_hammer.gd (Remove random mod)
    - models/currencies/tuning_hammer.gd (Reroll mod values)
  affects:
    - Crafting system completeness (all 6 hammers now implemented)
tech-stack:
  added: []
  patterns:
    - Template method pattern inheritance from Currency base
    - Random selection with fallback for mod type choice
    - Rarity-specific validation with descriptive errors
key-files:
  created:
    - models/currencies/tack_hammer.gd
    - models/currencies/grand_hammer.gd
    - models/currencies/claw_hammer.gd
    - models/currencies/tuning_hammer.gd
  modified: []
decisions:
  - TackHammer and GrandHammer use same 50/50 prefix/suffix logic as upgrade hammers
  - ClawHammer preserves rarity when removing mods per CRAFT-05
  - TuningHammer only rerolls explicit mods (not implicit) per CRAFT-06
  - All four validate mod presence/space before application
metrics:
  duration: 87s
  tasks_completed: 2
  files_created: 4
  commits: 2
  completed_date: 2026-02-15
---

# Phase 06 Plan 02: Modifier Hammers Summary

**One-liner:** Four mod-manipulation currencies (TackHammer, GrandHammer, ClawHammer, TuningHammer) completing the 6-hammer crafting system with add/remove/reroll mechanics.

## What Was Built

Created four modifier hammers that work on items already at Magic or Rare rarity:

1. **TackHammer** (`models/currencies/tack_hammer.gd`)
   - Adds one random mod to Magic items
   - Validates item is Magic rarity
   - Validates item has room for at least one more mod (respects 1+1 limit)
   - Error messages: "Tack Hammer can only be used on Magic items" or "Item already has maximum mods for Magic rarity"

2. **GrandHammer** (`models/currencies/grand_hammer.gd`)
   - Adds one random mod to Rare items
   - Validates item is Rare rarity
   - Validates item has room for at least one more mod (respects 3+3 limit)
   - Error messages: "Grand Hammer can only be used on Rare items" or "Item already has maximum mods for Rare rarity"

3. **ClawHammer** (`models/currencies/claw_hammer.gd`)
   - Removes one random explicit mod from any item with mods
   - Works on Magic or Rare items (any rarity with mods)
   - Does NOT change item rarity per CRAFT-05
   - Builds list of all mods, picks one randomly, removes via `remove_at()`
   - Error message: "Item has no mods to remove"

4. **TuningHammer** (`models/currencies/tuning_hammer.gd`)
   - Rerolls all explicit mod values within their tier ranges
   - Works on Magic or Rare items (any rarity with mods)
   - Calls `affix.reroll()` on each prefix and suffix
   - Does NOT reroll implicit (only explicit mods) per CRAFT-06
   - Error message: "Item has no mods to reroll"

## Key Implementation Details

**Mod Addition Logic (TackHammer and GrandHammer):**
- Use same 50/50 prefix/suffix random selection as RunicHammer/ForgeHammer
- Check which mod types have available slots
- If both available, choose randomly; if only one available, use that one
- Fallback: if chosen type fails, try alternate type
- Call `item.update_value()` after modification

**Mod Removal Logic (ClawHammer):**
- Build array of dictionaries tracking all mod positions: `{"type": "prefix", "index": 0}`
- Pick one randomly with `pick_random()`
- Remove using `item.prefixes.remove_at()` or `item.suffixes.remove_at()`
- Explicitly does NOT change `item.rarity` (CRAFT-05 requirement)

**Mod Reroll Logic (TuningHammer):**
- Iterate over all `item.prefixes` and call `prefix.reroll()`
- Iterate over all `item.suffixes` and call `suffix.reroll()`
- Does NOT touch `item.implicit` (CRAFT-06 specifies "mod values" = explicit mods)
- Affix.reroll() randomizes value between min_value and max_value (tier range)

**Validation Consistency:**
- All four use Currency base template method pattern
- All validate before applying (consume-only-on-success per CRAFT-09)
- All provide descriptive error messages (CRAFT-08)
- All call `item.update_value()` after modification

## Requirements Satisfied

**CRAFT-03:** Tack Hammer adds random mod to Magic items respecting 1+1 limit ✓
**CRAFT-04:** Grand Hammer adds random mod to Rare items respecting 3+3 limit ✓
**CRAFT-05:** Claw Hammer removes random mod without changing rarity ✓
**CRAFT-06:** Tuning Hammer rerolls all explicit mod values within tier ranges ✓
**CRAFT-07:** All four validate item state before application ✓
**CRAFT-08:** All four return descriptive error messages ✓
**CRAFT-09:** All four use Currency.apply() template ensuring consume-only-on-success ✓

## Deviations from Plan

None - plan executed exactly as written.

## File Structure

```
models/currencies/
├── currency.gd           # Base Resource (from 06-01)
├── runic_hammer.gd       # Normal → Magic (from 06-01)
├── forge_hammer.gd       # Normal → Rare (from 06-01)
├── tack_hammer.gd        # Add mod to Magic (new)
├── grand_hammer.gd       # Add mod to Rare (new)
├── claw_hammer.gd        # Remove random mod (new)
└── tuning_hammer.gd      # Reroll mod values (new)
```

**Full 6-hammer system now complete:**
- RunicHammer: Normal → Magic (1-2 mods)
- ForgeHammer: Normal → Rare (4-6 mods)
- TackHammer: Add mod to Magic (respects 1+1)
- GrandHammer: Add mod to Rare (respects 3+3)
- ClawHammer: Remove random mod (any rarity)
- TuningHammer: Reroll mod values (any rarity)

## Commits

1. `0a7e958` - feat(06-02): create TackHammer and GrandHammer currencies
2. `e933dde` - feat(06-02): create ClawHammer and TuningHammer currencies

## Testing Notes

**To verify TackHammer/GrandHammer:**
1. Create a Magic/Rare item with 0 mods
2. Create hammer instance (e.g., `var tack = TackHammer.new()`)
3. Call `tack.can_apply(item)` → should return `true`
4. Call `tack.apply(item)` → should add one mod, return `true`
5. Repeat until item is full (Magic: 2 mods, Rare: 6 mods)
6. Call `tack.can_apply(item)` → should return `false`
7. Call `tack.get_error_message(item)` → should return "Item already has maximum mods..."

**To verify ClawHammer:**
1. Create item with mods (Magic or Rare)
2. Count initial mod count (prefixes + suffixes)
3. Create `var claw = ClawHammer.new()`
4. Call `claw.apply(item)` → should remove one mod randomly
5. Verify mod count decreased by 1
6. Verify rarity unchanged
7. Repeat until no mods left
8. Call `claw.can_apply(item)` → should return `false`

**To verify TuningHammer:**
1. Create item with mods
2. Note initial mod values
3. Create `var tuning = TuningHammer.new()`
4. Call `tuning.apply(item)` → should reroll all mod values
5. Verify mod values changed (within tier ranges)
6. Verify mod count unchanged
7. Verify implicit.value unchanged

## Next Steps

Phase 6 complete. All 6 crafting hammers implemented:
- Upgrade hammers: RunicHammer, ForgeHammer (06-01)
- Modifier hammers: TackHammer, GrandHammer, ClawHammer, TuningHammer (06-02)

Next: Phase 7 - Drop Integration
- Hook hammer drops into enemy loot tables
- Configure drop rates by difficulty/tier
- Validate full crafting loop in-game

## Self-Check

Verifying all created files and commits exist:

- [x] File exists: models/currencies/tack_hammer.gd
- [x] File exists: models/currencies/grand_hammer.gd
- [x] File exists: models/currencies/claw_hammer.gd
- [x] File exists: models/currencies/tuning_hammer.gd
- [x] Commit exists: 0a7e958
- [x] Commit exists: e933dde

**Self-Check: PASSED**
