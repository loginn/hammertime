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

## v1.0 — Crafting Overhaul (planned)

**Goal:** Replace basic hammer system with rarity tiers and 6 themed crafting hammers.

**Status:** Research complete, requirements defined — awaiting planning

**Phases:** TBD (will plan after v0.1 archive)

---
