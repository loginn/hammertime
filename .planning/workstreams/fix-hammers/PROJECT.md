# Hammertime — Fix Hammers Workstream

## What This Is

A focused workstream that fixed mismatched hammer/currency behaviors and completed the PoE currency mapping with 9 base hammers (Transmute, Augment, Alchemy, Alteration, Regal, Chaos, Exalt, Divine, Annulment). All hammers now behave exactly as a PoE player expects.

## Core Value

Every hammer must do exactly what a PoE player expects — correct currency behaviors build trust in the crafting system.

## Shipped: v1.11 Fix Hammers — Full PoE Currency Set

**Status:** Complete (2026-04-12)
**Phases:** 3 | **Plans:** 6 | **Tasks:** 11

### What Was Delivered

1. **Hammer Models (Phase 1):** Renamed 3 mislabeled classes (ForgeHammer→AlchemyHammer, TuningHammer→DivineHammer, ClawHammer→AnnulmentHammer) and created 3 new classes (AugmentHammer, ChaosHammer, ExaltHammer) with correct PoE behaviors
2. **Forge UI (Phase 2):** Rarity-grouped 3x4 grid with all 9 base hammer buttons, correct tooltips, grey-out on zero currency
3. **Integration (Phase 3):** Drop tables wired for alchemy/divine/annulment with area gating; SAVE_VERSION bumped 9→10; 7 new integration test groups covering all 8 base hammer behaviors

### Key Decisions

- Preserved byte-identical currency bodies during rename (only class_name/currency_name metadata changed)
- Augment gate retuned from 15→5 for early Magic crafting access
- Delete-and-fresh save policy (no v9→v10 migration code — hobby project simplicity)
- New test groups use `_check()` (not `assert()`) to match non-aborting harness contract
- Invariant-only test assertions (no specific affix names/values)

### Requirements: All Validated

- FIX-01, FIX-02, FIX-03 — Augment/Chaos/Exalt behavior fixes (v1.11)
- NEW-01, NEW-02, NEW-03 — Alchemy/Divine/Annulment new currencies (v1.11)
- UI-01 — Forge view 9 base hammer buttons with tooltips (v1.11)
- INT-01, INT-02, INT-03 — Drop tables, save format, integration tests (v1.11)

## Context

- 9 base hammers: Transmute, Augment, Alchemy, Alteration, Regal, Chaos, Exalt, Divine, Annulment
- 5 tag hammers: Fire, Cold, Lightning, Defense, Physical (unchanged)
- Currency classes in `models/currencies/`
- UI in `scenes/forge_view.gd` (rarity-grouped 3x4 grid)
- Drops in `models/loot/loot_table.gd` (9-entry CURRENCY_AREA_GATES + pack_currency_rules)
- Save in `autoloads/save_manager.gd` (format v10)
- Tests in `tools/test/integration_test.gd` (Groups 48-57 cover all 8 base hammer behaviors)

## Out of Scope (unchanged)

- Tag hammer changes — those work correctly
- New crafting mechanics beyond PoE standard currencies
- UI layout redesign beyond the rarity-grouped grid

---
*Last updated: 2026-04-12 after v1.11 milestone*
