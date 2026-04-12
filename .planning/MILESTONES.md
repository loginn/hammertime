# Milestones: Hammertime

## v1.11 Fix Hammers (Shipped: 2026-04-12)

**Phases completed:** 3 phases, 6 plans, 11 tasks

**Key accomplishments:**

- Renamed ClawHammer/ForgeHammer/TuningHammer to AnnulmentHammer/AlchemyHammer/DivineHammer via git mv with zero body changes, rewired forge_view.gd + 2 scene files, and updated live codebase docs.
- Added 3 new base-hammer currency classes (AugmentHammer, ChaosHammer, ExaltHammer) implementing correct PoE behaviors and repointed the bridge-state keys in `scenes/forge_view.gd` `currencies` dict, completing the 8-base-hammer set for Phase 1.
- One-liner:
- 9-entry CURRENCY_AREA_GATES and pack_currency_rules now wire alchemy/annulment/divine into monster-pack drops with area gating, and retune augment gate from 15 to 5 for early Magic crafting access
- SAVE_VERSION constant bumped from 9 to 10 in save_manager.gd — one-line change; delete-and-fresh policy and key-agnostic .duplicate() serialization handle v10 without any additional code
- Group 50 updated to SAVE_VERSION 10 with 3 new currency round-trips; 7 new hammer test groups (Transmute through Annulment) added using _check()-only invariant assertions

---

## v1.8 — Content Pass — Items & Mods (Shipped: 2026-03-08)

**Goal:** Expand item bases to 3 per slot (STR/DEX/INT archetypes), add spell damage channel with cast speed, damage over time system, and broaden the affix pool.

**Phases:** 8 phases (42-49), 18 plans | **Timeline:** 3 days (2026-03-06 → 2026-03-08)
**Stats:** 14,375 LOC GDScript (up from 11,171)

**Key accomplishments:**

- 21 item base types across 5 equipment slots with STR/DEX/INT archetype identity, valid_tags constraining affix pools, and thematic naming
- Inventory rework from 10-item arrays to single crafting bench per slot, simplifying the item management path
- Spell damage channel with StatCalculator integration, Hero tracking, dual DPS display, and CombatEngine spell timer as third independent timer
- 14 new affixes (spell damage flat/%, cast speed, evade, bleed/poison/burn chance and damage) expanding the rollable pool
- Damage over time system (bleed/poison/burn) with CombatEngine tick processing, stacking rules, defense interaction, and UI feedback
- Save version bumped to v7, all 21 bases in drop pool with slot-first distribution, 35-group integration test suite

**Git range:** `feat(42-01)` → `feat(49-01)`

**Tech debt:**

- LOOT-03 (combined DPS comparison) dropped — tier-only comparison stays
- LOOT-04 (archetype labels) dropped — item names are self-documenting
- P2-P7 prestige costs still stub values (999999)

**What's next:** Planning next milestone

**Archives:** `.planning/milestones/v1.8-ROADMAP.md`, `.planning/milestones/v1.8-REQUIREMENTS.md`

---

## v1.7 — Meta-Progression (Shipped: 2026-03-06)

**Goal:** Add prestige reset loop with currency-gated tier progression, expanded affix tiers, and tag-targeted crafting currencies.

**Phases:** 7 phases (35-41), 9 plans | **Timeline:** 15 days (2026-02-20 → 2026-03-06)
**Stats:** 66 files changed, 11,171 LOC GDScript (up from ~4,895)

**Key accomplishments:**

- PrestigeManager autoload with 7 prestige levels, currency-cost gating, full run-state wipe preserving meta-progression
- Save format v4 with prestige field persistence, auto-save on prestige, and delete-on-old-version migration policy
- Affix tier expansion from 8 to 32 tiers with retuned base values for all 27 active affixes
- Item tier system (1-8) with area-weighted Gaussian drops and affix tier floor constraints at crafting time
- 5 tag-targeted hammers (Fire, Cold, Lightning, Defense, Physical) with prestige-gated visibility, "no valid mods" feedback, and 7.5% pack drop rate at P1+
- Prestige UI with 7-level unlock table, two-click confirmation, fade-to-black transition, and dynamic tab reveal
- 50-test integration verification suite covering full prestige loop, save round-trips, crafting regression, and tier gating

**Git range:** `feat(35-01)` → `feat(41-01)`

**Tech debt:**

- P2-P7 prestige costs are stub values (999999)
- Double save on prestige (prestige_view + signal handler)
- Pre-existing debug prints in affix.gd and item.gd

**What's next:** Planning next milestone

**Archives:** `.planning/milestones/v1.7-ROADMAP.md`, `.planning/milestones/v1.7-REQUIREMENTS.md`

---

## v0.x — Prototype (pre-tracking)

**Shipped:** Core gameplay loop, basic item/affix system, hammer crafting, area clearing.

**Phases:** Not tracked (built before GSD).

**Key outcomes:**

- Hero system with equipment slots and stat calculation
- Item system with implicits, prefixes, suffixes, tiers
- 3 hammer types (implicit, prefix, suffix)
- Area progression with difficulty scaling
- 3 UI views (Hero, Crafting, Gameplay)

---

## v0.1 — Code Cleanup & Architecture (Shipped: 2026-02-15)

**Goal:** Refactor codebase to Godot best practices before v1.0.

**Phases:** 4 phases, 8 plans | **Timeline:** 2 days (2026-02-14 → 2026-02-15)
**Stats:** 45 commits, 109 files changed, 1,953 LOC GDScript

**Key accomplishments:**

- Formatted 18 GDScript files and added return type hints to 78 functions
- Reorganized 25 files into feature-based folder structure (models/, scenes/, autoloads/, utils/)
- Migrated all item/affix data classes from Node to Resource for proper serialization
- Created GameState/GameEvents autoloads as single source of truth for state management
- Built unified StatCalculator replacing 96 lines of duplicate DPS logic, fixed crit formula bug
- Replaced 7 sibling get_node() calls with signal-based parent coordination and 33 @onready cached references

**Archives:** `.planning/milestones/v0.1-ROADMAP.md`, `.planning/milestones/v0.1-REQUIREMENTS.md`

---

## v1.0 — Crafting Overhaul (Shipped: 2026-02-15)

**Goal:** Replace basic 3-hammer system with PoE-inspired rarity tiers and 6 themed crafting hammers.

**Phases:** 4 phases (5-8), 7 plans, 14 tasks | **Timeline:** 1 day (2026-02-15)
**Stats:** 39 files changed, 2,488 LOC GDScript

**Key accomplishments:**

- Item rarity system (Normal/Magic/Rare) with configurable affix limits and visual color coding
- Base Currency Resource with template method pattern enforcing validate-before-mutate and consume-only-on-success
- 6 themed crafting hammers (Runic, Forge, Tack, Grand, Claw, Tuning) with rarity-aware validation
- Area-difficulty-driven LootTable with rarity-weighted item drops and mod spawning
- Currency drop system with independent chances, area scaling, and guaranteed minimum drops
- 6-button crafting UI replacing legacy 3-hammer system with direct Currency.apply() integration

**Archives:** `.planning/milestones/v1.0-ROADMAP.md`, `.planning/milestones/v1.0-REQUIREMENTS.md`

---

## v1.1 — Content & Balance (Shipped: 2026-02-16)

**Goal:** Make all equipment slots meaningful through defensive prefixes, expand the affix pool, and tune drop/currency progression so rewards scale with area difficulty.

**Phases:** 4 phases (9-12), 7 plans, 13 tasks | **Timeline:** 2 days (2026-02-15 → 2026-02-16)
**Stats:** 3,161 LOC GDScript (up from 2,488)

**Key accomplishments:**

- 9 defensive prefix affixes for non-weapon items with tag-based filtering and StatCalculator integration
- Hero View offense/defense sections displaying armor, evasion, energy shield, and resistance totals
- Elemental resistance suffixes (fire/cold/lightning/all) replacing generic Elemental Reduction
- Currency area gating with hard gates at 1/100/200/300 and linear ramping for newly unlocked currencies
- Logarithmic rarity interpolation with multi-item drops (1→4-5 items/clear) across expanded area range
- Gap closures: Runic Hammer 70/30 mod bias, implicit stat_types architecture for intuitive stat math

**Archives:** `.planning/milestones/v1.1-ROADMAP.md`, `.planning/milestones/v1.1-REQUIREMENTS.md`

---

## v1.2 — Pack-Based Mapping (Shipped: 2026-02-17)

**Goal:** Replace time-based area clearing with pack-based map runs, adding real combat stakes and defensive stat integration.

**Phases:** 5 phases (13-17), 11 plans | **Timeline:** 2 days (2026-02-16 → 2026-02-17)
**Stats:** 17 code files changed (+1,163/-265 lines), 3,943 LOC GDScript (up from 3,161)

**Key accomplishments:**

- DefenseCalculator with 4-stage damage pipeline (evasion → resistance → armor → ES/life split)
- MonsterPack/MonsterType/BiomeConfig Resources with 22 named monster types and biome-weighted element selection
- CombatEngine state machine with dual attack timers and 7 combat signals on GameEvents
- Drop system split: per-pack currency drops + map completion item drops + architecture-enforced death penalty
- ProgressBar-based combat UI with floating damage numbers, crit styling, and ES overlay
- Pack-by-pack idle combat replacing timer-based area clearing

**Known Gaps:**

- Level 1 difficulty may be too high for fresh heroes (balance tuning deferred to v1.3+)

**Archives:** `.planning/milestones/v1.2-ROADMAP.md`, `.planning/milestones/v1.2-REQUIREMENTS.md`

---

## v1.3 — Save/Load & Polish (Shipped: 2026-02-18)

**Goal:** Persist full game state across sessions and fix UX pain points — side-by-side hero/crafting layout, item safety, stats overflow, crafting feedback, and level 1 balance.

**Phases:** 5 phases (18-22), 11 plans | **Timeline:** 2 days (2026-02-17 → 2026-02-18)
**Stats:** 74 commits, 128 files changed, 5,464 LOC GDScript (up from 3,943)

**Key accomplishments:**

- JSON save/load with auto-save timer (5 min) and event-driven triggers (craft, equip, area clear)
- Unified ForgeView side-by-side layout (equipment left, crafting right) with tab bar navigation
- Hammer tooltips, direct equip/melt workflow, two-click overwrite confirmation, and stat comparison hover
- Save string export/import with Base64 encoding, MD5 checksums, clipboard auto-copy, and colored toast notifications
- Starter Runic Hammer + weapon base for new games, Forest difficulty reduced 40% for fresh hero survival

**Archives:** `.planning/milestones/v1.3-ROADMAP.md`, `.planning/milestones/v1.3-REQUIREMENTS.md`

---

## v1.4 — Damage Ranges (Shipped: 2026-02-18)

**Goal:** Replace flat damage values with min-max ranges for weapons, monsters, and affixes, giving each element a distinct variance identity and updating UI to display ranges.

**Phases:** 4 phases (23-26), 7 plans | **Timeline:** 1 day (2026-02-18)
**Stats:** 11 GDScript files changed (+318/-43 lines), 4,849 LOC GDScript (down from 5,464 due to refactoring)

**Key accomplishments:**

- Weapon base damage min/max range fields with computed average getter for zero-change backward compatibility
- Affix six-field damage range schema with immutable template bounds and element-specific variance (Physical 1:1.5, Cold 1:2, Fire 1:2.5, Lightning 1:4)
- StatCalculator dual-accumulator per-element damage range calculation with correct percentage modifier routing
- Hero range caching with range-based DPS formula and DPS-based item comparison for weapon/ring slots
- Per-element hero damage rolling and per-hit pack rolling replacing deterministic combat values
- UI displaying "Damage: X to Y" on weapons, "Adds X to Y [Element] Damage" on affixes, and pack name + element in combat view

**Archives:** `.planning/milestones/v1.4-ROADMAP.md`, `.planning/milestones/v1.4-REQUIREMENTS.md`

---

## v1.5 Inventory Rework (Shipped: 2026-02-19)

**Phases completed:** 16 phases, 27 plans, 6 tasks

**Key accomplishments:**

- (none recorded)

---

## v1.6 — Tech Debt Cleanup (Shipped: 2026-02-20)

**Goal:** Clean repo hygiene and rebalance progression — compress biomes to ~25 levels each, retune all scaling, and make crafting the sole source of item mods.

**Phases:** 4 phases (31-34), 5 plans, 9 tasks | **Timeline:** 1 day (2026-02-19)
**Stats:** 17 code files changed (+366/-409 lines), 4,849 LOC GDScript

**Key accomplishments:**

- Cleaned repo — removed 6 stale .tmp files and added *.tmp to .gitignore
- Compressed 4 biomes from ~100-level spans to 25-level spans with boss wall/relief/ramp-back difficulty curve
- Retuned currency gates to biome boundaries (25/50/75) with 12-level sqrt ramp-up for newly unlocked currencies
- Enforced Normal-only item drops — crafting is now the sole source of item mods
- Fixed hero health/armor double-counting and reduced difficulty curve (GROWTH_RATE 0.10→0.07) for zone 25+ progressability
- Added biome preview currency drops by shifting gates 10 levels before boundaries

**Tech debt:**

- RARITY_ANCHORS dict retained as dead data in loot_table.gd
- PROG-06 drop rate ~1/14 packs vs spec ~1/50 (user accepted)
- Code comment inaccuracy: "full rate by biome boundary" but math shows 91.3% at boundary

**Archives:** `.planning/milestones/v1.6-ROADMAP.md`, `.planning/milestones/v1.6-REQUIREMENTS.md`

---
