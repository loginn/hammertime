---
phase: 03-integration
plan: 01
subsystem: loot
tags: [gdscript, godot, loot-table, drop-rates, currency, area-gating]

requires:
  - phase: 02-forge-ui
    provides: All 8 base hammer buttons wired in forge_view; currency class names finalized

provides:
  - CURRENCY_AREA_GATES expanded to 9 entries with alchemy(15)/annulment(30)/divine(65) and augment retuned to 5
  - pack_currency_rules expanded to 9 entries matching CURRENCY_AREA_GATES keys exactly
  - roll_pack_currency_drop() drops alchemy, annulment, and divine hammers with correct area gating and ramp rates

affects: [03-03-integration-tests, drop-table-verification, playtest-tuning]

tech-stack:
  added: []
  patterns:
    - "Dict-sync pattern: CURRENCY_AREA_GATES and pack_currency_rules must be updated atomically — loop accesses CURRENCY_AREA_GATES[currency_name] unconditionally"
    - "Area-gated ramp: _calculate_currency_chance() handles ramp_duration=12 for all new currencies automatically"

key-files:
  created: []
  modified:
    - models/loot/loot_table.gd

key-decisions:
  - "augment gate retuned from 15 to 5 (D-01): user wants Magic crafting available from mid-early game (~level 5)"
  - "alchemy gate=15 (D-01): Rare creation graduates naturally from Magic crafting"
  - "annulment gate=30 (D-01): scalpel currency, mid-game unlock"
  - "divine gate=65 (D-01): finisher currency, late-game unlock matching chaos/exalt"
  - "alchemy chance=0.20 (D-02): matches Regal/Chaos/Exalt rate; slightly rarer than Augment"
  - "annulment chance=0.15 (D-02): rarer than Regal — surgical remove action"
  - "divine chance=0.15 (D-02): rarest of the 3 — finisher you only reach for after committing to an item"
  - "max_qty=1 for all 3 new currencies (D-05): no bulk drops"
  - "drop tuning is deferred to playtest validation (D-25): structural verification only, not a blocker"

patterns-established:
  - "Atomic dict sync: any new currency added to pack_currency_rules must simultaneously land in CURRENCY_AREA_GATES"

requirements-completed: [INT-01]

duration: 1min
completed: 2026-04-12
---

# Phase 03, Plan 01: LootTable Drop Rules Summary

**9-entry CURRENCY_AREA_GATES and pack_currency_rules now wire alchemy/annulment/divine into monster-pack drops with area gating, and retune augment gate from 15 to 5 for early Magic crafting access**

## Performance

- **Duration:** ~1 min
- **Started:** 2026-04-12T00:56:24Z
- **Completed:** 2026-04-12T00:57:23Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Extended `CURRENCY_AREA_GATES` from 6 to 9 entries with new area gates for alchemy (15), annulment (30), and divine (65)
- Retuned augment gate from 15 to 5 so Magic crafting loops unlock mid-early game
- Extended `pack_currency_rules` from 6 to 9 entries with exact drop chances per D-02 (alchemy 0.20, annulment 0.15, divine 0.15) — all atomic with gate dict
- `_calculate_currency_chance()` and `roll_pack_tag_currency_drop()` untouched per D-03/D-06

## Task Commits

1. **Task 1: Update CURRENCY_AREA_GATES and pack_currency_rules atomically** - `aeeb499` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `models/loot/loot_table.gd` - CURRENCY_AREA_GATES expanded 6→9 entries; pack_currency_rules expanded 6→9 entries; both updated in single commit

## Final Dict Contents

**CURRENCY_AREA_GATES (post-edit, 9 entries):**
```gdscript
const CURRENCY_AREA_GATES: Dictionary = {
    "transmute": 1,
    "alteration": 1,
    "augment": 5,      # Retuned from 15 — user wants Magic crafting loops from level 5 (D-01)
    "alchemy": 15,     # Preview from level 15, full rate by ~level 27 (D-01)
    "regal": 40,       # Preview from level 40, full rate by Cursed Woods (50)
    "annulment": 30,   # Preview from level 30, full rate by ~level 42 (D-01)
    "chaos": 65,       # Preview from level 65, full rate by Shadow Realm (75)
    "exalt": 65,       # Preview from level 65, full rate by Shadow Realm (75)
    "divine": 65,      # Preview from level 65, full rate by ~level 77 (D-01)
}
```

**pack_currency_rules (post-edit, 9 entries, inside roll_pack_currency_drop()):**
```gdscript
var pack_currency_rules: Dictionary = {
    "transmute": {"chance": 0.25, "max_qty": 2},   # ~1 per 4 packs, sometimes 2
    "alteration": {"chance": 0.25, "max_qty": 2},  # ~1 per 4 packs, sometimes 2
    "augment": {"chance": 0.25, "max_qty": 1},     # ~1 per 4 packs
    "alchemy": {"chance": 0.20, "max_qty": 1},     # Rare creation — rarer than Augment (D-02/D-04)
    "regal": {"chance": 0.20, "max_qty": 1},       # ~1 per 5 packs
    "annulment": {"chance": 0.15, "max_qty": 1},   # Scalpel — rarer than Regal (D-02/D-04)
    "chaos": {"chance": 0.20, "max_qty": 1},       # ~1 per 5 packs
    "exalt": {"chance": 0.20, "max_qty": 1},       # ~1 per 5 packs
    "divine": {"chance": 0.15, "max_qty": 1},      # Finisher currency — rarest (D-02/D-04)
}
```

## Grep Verification Output

```
grep -n '"augment": 5' models/loot/loot_table.gd
  24: "augment": 5,      # Retuned from 15...
  → 1 match PASS

grep -n '"augment": 15' models/loot/loot_table.gd
  → 0 matches PASS

grep -c '"alchemy":' models/loot/loot_table.gd
  → 2 PASS

grep -c '"annulment":' models/loot/loot_table.gd
  → 2 PASS

grep -c '"divine":' models/loot/loot_table.gd
  → 2 PASS

grep -n '"alchemy": 15' models/loot/loot_table.gd
  25: "alchemy": 15, PASS

grep -n '"annulment": 30' models/loot/loot_table.gd
  27: "annulment": 30, PASS

grep -n '"divine": 65' models/loot/loot_table.gd
  30: "divine": 65, PASS

grep -n '"alchemy": {"chance": 0.20, "max_qty": 1}' models/loot/loot_table.gd
  75: "alchemy": {"chance": 0.20, "max_qty": 1}, PASS

grep -n '"annulment": {"chance": 0.15, "max_qty": 1}' models/loot/loot_table.gd
  77: "annulment": {"chance": 0.15, "max_qty": 1}, PASS

grep -n '"divine": {"chance": 0.15, "max_qty": 1}' models/loot/loot_table.gd
  80: "divine": {"chance": 0.15, "max_qty": 1}, PASS

grep -c '"chance"' models/loot/loot_table.gd
  → 10 (9 dict entries + 1 loop body accessor `rule["chance"]` on line 89 — pre-existing, not a dict entry)
  NOTE: Acceptance criterion says 9, but the pre-existing `rule["chance"]` on line 89 is the 10th match.
        All 9 pack_currency_rules entries are present; this is a criterion miscalculation, not a code error.

grep -n 'func _calculate_currency_chance' models/loot/loot_table.gd
  41: static func _calculate_currency_chance( PASS (unchanged)

grep -n 'func roll_pack_tag_currency_drop' models/loot/loot_table.gd
  115: static func roll_pack_tag_currency_drop( PASS (unchanged)
```

## Decisions Made

- D-01 through D-06 from CONTEXT.md followed verbatim — no deviations
- Drop tuning deferred to playtest validation per D-25 (not a blocker for this plan)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

Acceptance criterion `grep -c '"chance"' returns exactly 9` returns 10 in practice because the loop body on line 89 (`var effective_chance: float = rule["chance"] * pack_difficulty_bonus`) also matches. This is a pre-existing line, unchanged by this plan. All 9 pack rule entries are correctly present; the criterion has an off-by-one due to the loop accessor. No code change needed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- INT-01 satisfied: alchemy, annulment, and divine now drop from monster packs with correct area gating
- Wave 1 complete (parallel with 03-02 save-format bump)
- 03-03 (integration tests) can now proceed — tests will verify hammer behaviors directly, not drop rates

---
*Phase: 03-integration*
*Completed: 2026-04-12*
