---
phase: 12-drop-rate-rebalancing
plan: 01
subsystem: loot-progression
tags: [drop-rates, rarity-weights, item-quantity, currency-tuning, logarithmic-scaling]
dependency-graph:
  requires: [Phase-11-currency-area-gating, Phase-07-drop-integration]
  provides: [smooth-rarity-interpolation, multi-item-drops, tuned-currency-rates, logarithmic-bonus-drops]
  affects: [loot-system, gameplay-loop, area-progression]
tech-stack:
  added: []
  patterns: [logarithmic-interpolation, anchor-point-curves, fractional-rng-drops]
key-files:
  created: []
  modified: [models/loot/loot_table.gd, scenes/gameplay_view.gd, tools/drop_simulator.gd]
decisions:
  - "Use logarithmic interpolation between 4 anchor points (1/100/200/300) for smooth rarity progression"
  - "Set rare weight to 2% at area 1 (unchanged) but reduce magic from 18% to 7% for scarcer early game"
  - "Cap rare weight at 5% per roll for areas 200-300 — multi-item drops achieve 1 rare per 5 clears target"
  - "Replace linear bonus drops (area_level - 1) with log(area_level) * 2 to prevent currency flooding"
  - "Reduce advanced currency chances: grand 0.2->0.1, claw/tuning 0.4->0.15"
  - "Use floor + fractional RNG for item quantity (2.3 items = 2 guaranteed + 30% chance of 3rd)"
  - "Apply mild +2% rare bump at tier boundaries (100/200/300) fading over 10 levels"
metrics:
  duration: 117s
  tasks: 2
  files: 3
  commits: 2
  completed: 2026-02-16
---

# Phase 12 Plan 01: Drop Rate Rebalancing Summary

**Logarithmic rarity interpolation with multi-item drops (1 to 4-5) and tuned currency rates across 1-300 area range**

## Performance

- **Duration:** 117s
- **Started:** 2026-02-16
- **Completed:** 2026-02-16
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Replaced discrete rarity weight tables with smooth logarithmic interpolation between anchor points
- Added area-scaled item quantity drops (1 at area 1, ~4.5 at area 300) with floor + fractional RNG
- Fixed critical bonus drops formula (linear area_level-1 gave 299 bonus at area 300, now uses log scaling for ~11)
- Reduced advanced currency drop chances to create meaningful rarity distinction
- Added tier boundary bumps for rarity and item quantity at areas 100/200/300
- Updated drop simulator with item quantity validation and per-clear rate calculations

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement smooth rarity interpolation and item quantity scaling in LootTable** - `a3d6a7c` (feat)
2. **Task 2: Add multi-item drops to gameplay_view and update drop simulator** - `b5ac126` (feat)

## Files Created/Modified
- `models/loot/loot_table.gd` - Logarithmic rarity interpolation, get_item_drop_count(), tuned currency rules, log-scaled bonus drops
- `scenes/gameplay_view.gd` - Multi-item drops per clear via LootTable.get_item_drop_count()
- `tools/drop_simulator.gd` - Added simulate_item_quantity(), updated rarity sim with per-clear rates

## What Was Built

**1. Logarithmic Rarity Interpolation (models/loot/loot_table.gd)**
- Replaced `RARITY_WEIGHTS` const dictionary with `RARITY_ANCHORS` at 4 key area levels
- `get_rarity_weights()` now computes weights at any area level using log interpolation
- Eliminates jarring jumps between tiers (e.g., 80% normal at area 99 vs 50% at area 100)
- Mild +2% rare bump at tier boundaries (100/200/300) fading over 10 levels

Anchor weights:
| Area | Normal% | Magic% | Rare% |
|------|---------|--------|-------|
| 1    | 91      | 7      | 2     |
| 100  | 66      | 30     | 4     |
| 200  | 40      | 55     | 5     |
| 300  | 20      | 75     | 5     |

**2. Float-Based Rarity Rolling (models/loot/loot_table.gd)**
- `roll_rarity()` switched from `randi_range` to `randf()` with float accumulation
- Eliminates integer rounding issues with sub-1% weights

**3. Multi-Item Drops (models/loot/loot_table.gd + scenes/gameplay_view.gd)**
- `get_item_drop_count()` uses logarithmic curve: `1 + 3.5 * progress` where progress is log-normalized
- Floor + fractional roll: 2.3 items = 2 guaranteed + 30% chance of 3rd
- +0.3 item bump at tier boundaries (100/200/300)
- `clear_area()` now loops item_count times, emitting item_base_found per item
- area_cleared signal, currency drops, and progression checks fire once per clear

Expected items per clear:
| Area | Items/Clear |
|------|-------------|
| 1    | 1.0         |
| 100  | ~2.6        |
| 200  | ~3.6        |
| 300  | ~4.5        |

**4. Currency Rate Tuning (models/loot/loot_table.gd)**
- Reduced base chances for rarer feel:
  - runic: 0.7 -> 0.6
  - tack: 0.5 -> 0.45
  - forge: 0.3 -> 0.2
  - grand: 0.2 -> 0.1
  - claw: 0.4 -> 0.15
  - tuning: 0.4 -> 0.15
- Advanced currencies (claw, tuning) now max_qty 1 instead of 2

**5. Bonus Drop Fix (models/loot/loot_table.gd)**
- CRITICAL: Replaced `area_level - 1` with `log(area_level) * 2`
- Old: area 300 = 299 bonus currencies per clear (absurd)
- New: area 300 = ~11 bonus currencies per clear (reasonable)
- Distribution still uniform across eligible currencies (Phase 11 pattern preserved)

**6. Updated Drop Simulator (tools/drop_simulator.gd)**
- Added `simulate_item_quantity()` — tests item count across 9 area levels
- Updated `simulate_rarity_distribution()` — shows per-roll AND per-clear rare rates
- Preserved `simulate_currency_drops()` and `validate_hard_gates()` unchanged

## Decisions Made

1. **Rare weight capped at 5% per roll for areas 200-300** — multi-item drops (3.5-4.5 items) compensate, achieving ~0.2 rares per clear (1 per 5) without inflating per-roll rare chance
2. **Magic at 75% at area 300** — satisfies "magic dominant" endgame requirement while keeping rare meaningful
3. **Log interpolation factor `log(1 + t*9) / log(10)`** — maps linear progress 0-1 to log-shaped 0-1, creating front-loaded gains
4. **Item quantity k-value of 85** — `log(1 + level/85) / log(1 + 300/85)` produces a curve reaching ~4.5 at area 300
5. **Tier boundary bump of +2% rare** — "mild" per CONTEXT.md, fades over 10 levels to prevent regression at boundary+1

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 12 is the final phase in v1.1 milestone
- All 3 DROP requirements (DROP-01, DROP-02, DROP-03) addressed
- Playtest validation recommended (CONTEXT.md: "budget 2-3 iteration passes")
- Drop simulator available for empirical verification in Godot Editor
- v1.1 Content & Balance milestone ready for completion

## Self-Check: PASSED

**Modified files verification:**
- models/loot/loot_table.gd contains RARITY_ANCHORS, get_item_drop_count, logarithmic interpolation
- scenes/gameplay_view.gd contains multi-item drop loop with get_item_drop_count
- tools/drop_simulator.gd contains simulate_item_quantity function

**Commit verification:**
- a3d6a7c: feat(12-01): rebalance rarity weights, item quantity, and currency rates
- b5ac126: feat(12-01): add multi-item drops and update drop simulator

**Key patterns present:**
- RARITY_ANCHORS with 4 anchor points (1/100/200/300)
- Logarithmic interpolation in get_rarity_weights()
- Float-based roll_rarity()
- get_item_drop_count() with log curve and tier bumps
- Currency rules with reduced advanced chances
- Bonus drops using log(area_level) * 2
- Guaranteed runic fallback preserved
- Multi-item loop in clear_area()
- Item quantity simulation in drop_simulator

All claims validated. Implementation complete.

---
*Phase: 12-drop-rate-rebalancing*
*Completed: 2026-02-16*
