# Roadmap: Hammertime

## Milestones

- ✅ **v0.1 Code Cleanup & Architecture** — Phases 1-4 (shipped 2026-02-15)
- ✅ **v1.0 Crafting Overhaul** — Phases 5-8 (shipped 2026-02-15)
- 🚧 **v1.1 Content & Balance** — Phases 9-12 (in progress)

## Phases

<details>
<summary>✅ v0.1 Code Cleanup & Architecture (Phases 1-4) — SHIPPED 2026-02-15</summary>

- [x] Phase 1: Foundation (2/2 plans) — completed 2026-02-14
- [x] Phase 2: Data Model Migration (2/2 plans) — completed 2026-02-15
- [x] Phase 3: Unified Calculations (2/2 plans) — completed 2026-02-15
- [x] Phase 4: Signal-Based Communication (2/2 plans) — completed 2026-02-15

Full details: `.planning/milestones/v0.1-ROADMAP.md`

</details>

<details>
<summary>✅ v1.0 Crafting Overhaul (Phases 5-8) — SHIPPED 2026-02-15</summary>

- [x] Phase 5: Item Rarity System (2/2 plans) — completed 2026-02-15
- [x] Phase 6: Currency Behaviors (2/2 plans) — completed 2026-02-15
- [x] Phase 7: Drop Integration (2/2 plans) — completed 2026-02-15
- [x] Phase 8: UI Migration (1/1 plan) — completed 2026-02-15

Full details: `.planning/milestones/v1.0-ROADMAP.md`

</details>

<details open>
<summary>🚧 v1.1 Content & Balance (Phases 9-12) — IN PROGRESS</summary>

### Phase 9: Defensive Prefix Foundation

**Goal:** Non-weapon items can be crafted with defensive prefix affixes that display meaningful stats.

**Dependencies:** None (extends existing ItemAffixes and StatCalculator patterns)

**Requirements:**
- DPFX-01: Non-weapon items can roll defensive prefix affixes
- DPFX-02: 6 defensive prefixes available (flat armor, %armor, flat evasion, %evasion, flat ES, %ES)
- DPFX-03: Defensive prefixes use tag-based filtering
- DPFX-04: StatCalculator handles new defensive stat types
- DPFX-05: Defensive stats display on items but don't affect combat

**Success Criteria:**
1. User can apply Runic Hammer to helmet/armor/boots/ring and see defensive prefix added
2. User sees armor, evasion, and energy shield values displayed on non-weapon items
3. User can craft items with both defensive prefixes and existing suffixes (e.g., helmet with +armor and +life)
4. User sees defensive stat totals on Hero View's equipped stats panel
5. UI clearly indicates defensive stats are not yet functional in combat (grayed text or "(display only)" label)

**Status:** Pending

---

### Phase 10: Elemental Resistance Split

**Goal:** Users can craft items with specific elemental resistances instead of generic reduction.

**Dependencies:** Phase 9 (uses StatCalculator expansion patterns)

**Requirements:**
- ERES-01: Individual fire, cold, lightning resistance suffixes replace generic Elemental Reduction
- ERES-02: All-resistance suffix available as space-efficient option
- ERES-03: Resistance suffixes can roll on all item types

**Success Criteria:**
1. User can apply Forge Hammer and see specific fire/cold/lightning resistance suffixes roll
2. User can apply Forge Hammer and see all-resistance suffix roll (rarer than single-element)
3. User sees resistance values displayed on item tooltips and Hero View stats panel
4. User observes that old "Elemental Reduction" affix no longer appears on new items

**Status:** Pending

---

### Phase 11: Currency Area Gating

**Goal:** Advanced currencies only drop when user reaches appropriate area difficulty levels.

**Dependencies:** None (extends LootTable drop generation)

**Requirements:**
- GATE-01: Each currency type has minimum area level required to drop
- GATE-02: Tiered unlock: Runic/Tack at area 1+, Forge at area 100+, Grand at area 200+, Claw/Tuning at area 300+
- GATE-03: Drop chance starts very low when currency first becomes available and ramps up
- GATE-04: Currencies that can't drop are excluded from drop pool entirely (hard gate)
- AREA-01: Area difficulty levels spread to 1, 100, 200, 300
- AREA-02: Drop rate formulas scale smoothly across wider area range
- AREA-03: Rarity weights progress gradually across area levels

**Success Criteria:**
1. User clearing Forest (area 1) receives only Runic and Tack hammers, never Forge/Grand/Claw/Tuning
2. User clearing Dark Forest (area 100) receives Runic/Tack/Forge, with Forge drops being notably rare initially
3. User clearing Cursed Woods (area 200) receives Runic/Tack/Forge/Grand, with Grand drops being very rare
4. User clearing Shadow Realm (area 300) can receive all 6 hammer types, with advanced hammers still rarer than basic
5. User observes currency drop rates increasing gradually as they clear higher area levels within same tier

**Status:** Pending

---

### Phase 12: Drop Rate Rebalancing

**Goal:** Item rarity and currency drop rates scale appropriately across the expanded area level range.

**Dependencies:** Phases 9-11 complete (requires full content in place for accurate tuning)

**Requirements:**
- DROP-01: Rare items are harder to find in early areas compared to v1.0
- DROP-02: Advanced currencies (Grand, Claw, Tuning) are significantly rarer than basic currencies
- DROP-03: Rarity weights and currency drop chances tuned for wider area level spread

**Success Criteria:**
1. User clearing Forest (area 1) finds rare items approximately 1 per 30-50 clears (down from current ~1 per 10)
2. User clearing Shadow Realm (area 300) finds rare items approximately 1 per 5-10 clears (increased from late game)
3. User observes that Grand/Claw/Tuning hammers drop significantly less frequently than Runic/Tack/Forge
4. User can progress through areas without currency/loot drought (minimum guaranteed drops still functional)

**Status:** Pending

---

</details>

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v0.1 | 2/2 | ✓ Complete | 2026-02-14 |
| 2. Data Model Migration | v0.1 | 2/2 | ✓ Complete | 2026-02-15 |
| 3. Unified Calculations | v0.1 | 2/2 | ✓ Complete | 2026-02-15 |
| 4. Signal-Based Communication | v0.1 | 2/2 | ✓ Complete | 2026-02-15 |
| 5. Item Rarity System | v1.0 | 2/2 | ✓ Complete | 2026-02-15 |
| 6. Currency Behaviors | v1.0 | 2/2 | ✓ Complete | 2026-02-15 |
| 7. Drop Integration | v1.0 | 2/2 | ✓ Complete | 2026-02-15 |
| 8. UI Migration | v1.0 | 1/1 | ✓ Complete | 2026-02-15 |
| 9. Defensive Prefix Foundation | v1.1 | 0/? | Pending | — |
| 10. Elemental Resistance Split | v1.1 | 0/? | Pending | — |
| 11. Currency Area Gating | v1.1 | 0/? | Pending | — |
| 12. Drop Rate Rebalancing | v1.1 | 0/? | Pending | — |

**v1.1 Coverage:** 18/18 requirements mapped (100%)

---

## Notes

**Phase independence:** Phases 9-10-11 are fully independent and can be developed in any order. Phase 12 must come last as it requires all content in place for accurate tuning.

**Research flags:**
- Phase 9-10: Standard patterns (tag filtering + StatCalculator extension follow existing codebase exactly)
- Phase 11: Requires simulation testing to validate drop distribution (create drop_simulator.gd to verify linear reward curve)
- Phase 12: Requires playtesting (empirical testing, not research - budget 2-3 iteration cycles)

**Tag taxonomy:** Establish mutually exclusive tag groups (WEAPON_ONLY, ARMOR_ONLY, ANY_ITEM) before adding affixes in Phase 9 to prevent empty affix pools.

---
*Roadmap created: 2026-02-14*
*Last updated: 2026-02-15 (v1.1 Content & Balance roadmap added)*
