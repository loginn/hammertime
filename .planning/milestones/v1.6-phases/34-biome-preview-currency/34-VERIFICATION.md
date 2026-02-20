---
phase: 34-biome-preview-currency
verified: 2026-02-19T16:12:27Z
status: gaps_found
score: 3/5 must-haves verified
re_verification: false
gaps:
  - truth: "Preview currency drops are very rare at first due to the existing sqrt ramp curve"
    status: failed
    reason: "At unlock+1 the drop rate is 7.2% (1 per ~14 packs), not the ~2% required for 1 per 50 packs. Averaged across the entire Forest biome (areas 1-24), forge drops at 5.8% mean = 1 per 17 packs. The ROADMAP success criterion requires approximately 1 occurrence per 50 packs on average. The PLAN overestimated rarity by describing 29% of base as 'very rare', but 29% of a 25% base is 7.2% actual — 3.6x higher than the 2% needed for the 50-pack target."
    artifacts:
      - path: "models/loot/loot_table.gd"
        issue: "CURRENCY_AREA_GATES thresholds and sqrt ramp are correctly implemented, but the combination of base_chance=0.25 and ramp_duration=12 produces drop rates far above the 1-per-50-packs target. Either base_chance for preview currencies needs reduction or ramp_duration needs to be increased to achieve rarer initial preview drops."
    missing:
      - "Reduce base_chance for non-starter currencies (forge/grand/claw/tuning) OR increase ramp_duration so that the preview window drop rate averages ~2% per pack (~1 per 50 packs) as stated in PROG-06 and the ROADMAP success criterion"
human_verification:
  - test: "Play through Forest biome (areas 1-24) and observe how frequently Forge Hammer currency drops appear"
    expected: "Forge Hammer drops should feel rare and exciting — approximately once per 50 packs, not once every 14 packs"
    why_human: "Drop feel and pacing is subjective. Math shows 7.2% at unlock+1 (1 per 14 packs) which is likely too frequent to feel special, but playtest confirms this."
---

# Phase 34: Biome Preview Currency Verification Report

**Phase Goal:** Players receive occasional rare currency drops from the next biome as a teaser for upcoming content, appearing at roughly 1 drop per 50 packs in the current biome
**Verified:** 2026-02-19T16:12:27Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Forge Hammer drops begin appearing at area level 15 (10 levels before Dark Forest) | VERIFIED | `CURRENCY_AREA_GATES["forge"] = 15` at line 24 of `models/loot/loot_table.gd` |
| 2 | Grand Hammer drops begin appearing at area level 40 (10 levels before Cursed Woods) | VERIFIED | `CURRENCY_AREA_GATES["grand"] = 40` at line 25 of `models/loot/loot_table.gd` |
| 3 | Claw and Tuning Hammer drops begin appearing at area level 65 (10 levels before Shadow Realm) | VERIFIED | `CURRENCY_AREA_GATES["claw"] = 65` and `CURRENCY_AREA_GATES["tuning"] = 65` at lines 26-27 |
| 4 | Preview currency drops are very rare at first due to the existing sqrt ramp curve | FAILED | At unlock+1 (area 16), forge drops at 7.2% per pack (1 per ~14 packs). Across the full Forest biome average is 5.8% (1 per 17 packs). The ROADMAP requires ~1 per 50 packs (~2%). The 29%-of-base claim in the PLAN is mathematically correct but 29% of 25% base = 7.2% actual — 3.6x above the target rate. |
| 5 | By the original gate level (25/50/75), currencies reach full drop rates as before | PARTIAL | At area 25, forge is at 91.3% of base rate (full rate reached at area 27, not 25). This 8.7% shortfall is minor and may be acceptable, but the PLAN's claim of "full rate by original biome boundary" is technically inaccurate. |

**Score:** 3/5 truths verified (3 fully verified, 1 failed, 1 partial)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `models/loot/loot_table.gd` | Currency gate thresholds shifted down by 10 levels | VERIFIED (structurally) | File exists, 104 lines, substantive implementation. `CURRENCY_AREA_GATES` constant correctly contains forge:15, grand:40, claw:65, tuning:65. Old values (25/50/75) do not appear in the constant. `_calculate_currency_chance()` and `roll_pack_currency_drop()` functions are unchanged. |

**Artifact wiring (Level 3):** `roll_pack_currency_drop` is called in `models/combat/combat_engine.gd` at line 143 inside `_on_pack_killed()`, which reads `CURRENCY_AREA_GATES` via `roll_pack_currency_drop(GameState.area_level, killed_pack.difficulty_bonus)` and emits results through `GameEvents.currency_dropped`. The loot path is fully wired end-to-end.

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `models/loot/loot_table.gd` | `CURRENCY_AREA_GATES` | `roll_pack_currency_drop reads gate thresholds` | WIRED | Line 78: `var unlock_level: int = CURRENCY_AREA_GATES[currency_name]` reads the constant correctly. The shifted thresholds are consumed by the drop function. |
| `models/combat/combat_engine.gd` | `LootTable.roll_pack_currency_drop` | `_on_pack_killed()` call | WIRED | Line 143: `var drops := LootTable.roll_pack_currency_drop(GameState.area_level, killed_pack.difficulty_bonus)`. Result is applied to `GameState.add_currencies(drops)` and emitted via `GameEvents.currency_dropped.emit(drops)`. Full round-trip confirmed. |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| PROG-06 | 34-01-PLAN.md | User can receive rare preview currency drops from next biome (~1 per 50 packs average in current biome) | BLOCKED | Gate thresholds are correctly shifted to enable preview drops. However, the "~1 per 50 packs" rarity target is not met. At area 16 (first preview level for forge), drop rate is 7.2% = 1 per ~14 packs. Averaged across the Forest biome (areas 1-24), rate is 5.8% = 1 per ~17 packs. The requirement explicitly states ~1 per 50 packs (~2% per pack). |

**PROG-06 mapping confirmed:** REQUIREMENTS.md line 22 documents the requirement, line 56 marks it as Complete (Phase 34). ROADMAP.md lists it under Phase 34. The plan claims the requirement, and the SUMMARY marks it done. However, the actual drop rate does not satisfy the stated rarity constraint.

**No orphaned requirements:** PROG-06 is the only requirement mapped to Phase 34. No other requirement IDs found in REQUIREMENTS.md that reference Phase 34 and are unclaimed.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None | — | — | — | No TODO/FIXME/placeholder/stub patterns found in `models/loot/loot_table.gd`. All functions are substantive and complete. |

### Human Verification Required

#### 1. Preview Drop Feel — Frequency vs. Rarity Intent

**Test:** Play through Forest biome (areas 1-24), specifically areas 15-24. Count how many packs it takes to see a Forge Hammer currency drop after reaching area 16.
**Expected:** Drops should feel occasional and special — roughly once every 50 packs. If a drop appears every 10-15 packs, the preview feels routine rather than anticipation-building.
**Why human:** The mathematical gap (14 packs vs. 50 packs) is programmatically verified, but whether the actual play feel is acceptable or whether the ROADMAP's "50 packs" was an informal approximation requires a human judgment call.

---

## Gap Analysis

### Root Cause

The phase goal and PROG-06 both specify "approximately 1 occurrence per 50 packs" (~2% chance per pack). The implementation achieves this by shifting gate thresholds down 10 levels and relying on the existing 12-level sqrt ramp to produce "very rare" initial drops.

The flaw: the plan describes 29%-of-base as "very rare," but this maps to 7.2% actual chance per pack (29% × 25% base = 0.072), which is 1 per 14 packs — not 1 per 50.

To achieve 1 per 50 packs at unlock+1, the effective chance would need to be 2%. With the sqrt ramp at unlock+1 providing a 28.9% multiplier, the base_chance would need to be ~6.9% (instead of 25%) for preview currencies during their preview window — or the ramp_duration would need to increase significantly (requiring 156 levels to ramp from 2% to 25%, which is impractical).

The most practical fix is to reduce the `forge`/`grand`/`claw`/`tuning` base chances in `pack_currency_rules` within `roll_pack_currency_drop()`, adding a separate "preview mode" chance when the area is within the 10-level preview window. Alternatively, treat the ramp differently for preview vs. normal unlock, or accept a less aggressive rarity target and revise the ROADMAP criterion to match actual behavior.

### What Works

- Gate thresholds are correctly shifted (forge 25→15, grand 50→40, claw/tuning 75→65). This structural change is correct.
- The wiring is complete and functional: `combat_engine.gd` calls `roll_pack_currency_drop`, which reads `CURRENCY_AREA_GATES`, which applies the ramp — the full pipeline is live.
- runic and tack are correctly untouched at gate=1.
- No anti-patterns, no stubs, no orphaned code.

### What Needs Fixing

The rarity of preview drops does not meet the stated target. Preview currency drops are currently 3.6x more frequent than required (1 per 14 packs vs. 1 per 50 packs). This could make preview drops feel routine rather than exciting, undermining the goal of creating "anticipation for the next biome without disrupting current progression balance."

---

*Verified: 2026-02-19T16:12:27Z*
*Verifier: Claude (gsd-verifier)*
