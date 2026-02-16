# Milestones: Hammertime

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

