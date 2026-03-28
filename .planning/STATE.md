---
gsd_state_version: 1.0
milestone: v1.10
milestone_name: Early Game Rebalance
status: Defining requirements
stopped_at: null
last_updated: "2026-03-28T10:50:00.000Z"
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
---

# Project State: Hammertime

**Updated:** 2026-03-28
**Milestone:** v1.10 Early Game Rebalance

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-28)

**Core value:** The crafting loop must feel rewarding — finding items, using hammers to shape them, and equipping the result to push further into harder content.
**Current focus:** Defining requirements

**Architecture:** Godot 4.5 GDScript, feature-based folders (models/, scenes/, autoloads/, utils/), Resource-based data model, signal-based communication via GameEvents, JSON save/load via SaveManager autoload, PrestigeManager autoload.

## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: 2026-03-28 — Milestone v1.10 started

## Performance Metrics

**Milestone v1.8 (shipped 2026-03-08):**

- Phases: 8 (42-49) | Plans: 18 | Requirements: 39/39 | Timeline: 3 days

**Milestone v1.7 (shipped 2026-03-06):**

- Phases: 7 (35-41) | Plans: 9 | Requirements: 23/23 | Timeline: 15 days

**Milestone v1.6 (shipped 2026-02-20):**

- Phases: 4 (31-34) | Plans: 5 | Tasks: 9 | Requirements: 9/9 | Timeline: 1 day

**Milestone v1.5 (shipped 2026-02-19):**

- Phases: 4 (27-30) | Plans: 4 | Requirements: 9/9 | Timeline: 1 day

**Milestone v1.4 (shipped 2026-02-18):**

- Phases: 4 (23-26) | Plans: 7 | Requirements: 11/11 | Timeline: 1 day

**Milestone v1.3 (shipped 2026-02-18):**

- Phases: 5 (18-22) | Plans: 11 | Requirements: 13/13 | Timeline: 2 days

## Accumulated Context

### Decisions

All decisions logged in PROJECT.md Key Decisions table.

- [Phase 50-data-foundation]: HeroArchetype extends Resource with plain-string passive_bonuses dict; hero_archetype field not wired to prestige wipe (Phase 52 scope)
- [Phase 51]: is_spell_user derived from archetype at top of update_stats(), not stored or restored; spell mode toggle removed from settings_view.gd; is_spell_user removed from save format
- [Phase 51]: Bonus application order in calculate_damage_ranges(): element-specific first, then channel-wide (attack_damage_more), then general (damage_more)
- [Phase 51]: Spell element map: physical->spell, fire->spell_fire, lightning->spell_lightning for routing element bonuses to spell damage ranges
- [Phase 52-save-persistence]: SAVE_VERSION bumped to 8; hero_archetype_id round-trips via from_id(); strict import rejection for pre-v8 strings; hero_archetype wiped on prestige
- [Phase 53-selection-ui]: Overlay built programmatically in main_view.gd — no new scene files needed
- [Phase 53-selection-ui]: BONUS_LABELS const on HeroArchetype for clean label lookup and testability
- [Phase 54]: Hero title uses BBCode [color=#hex] rather than modulate for per-section coloring within a single RichTextLabel
- [Phase 54]: Classless Adventurer null archetype shows no hero section in ForgeView stat panel (per D-04)

### Pending Todos

- [ ] Add item drop filter for unwanted loot (FILT-01 — deferred to future)
- [ ] Add large number formatting with suffix notation
- [ ] Remove crafting inventory (simplify item management)
- [ ] Give ES more identity for spellcasters (e.g. ES mitigation buff for int archetype) — deferred to hero milestone
- [ ] Spell dodge / evasion applies to spells at x% effectiveness — new defensive mechanic, needs own phase

### Blockers/Concerns

None.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 7 | Handle untracked / unstaged files | 2026-02-19 | 2648f05 | [7-handle-untracked-unstaged-files](./quick/7-handle-untracked-unstaged-files/) |
| 8 | Audit and fix affix pipeline (disable 9 dead mods, fix FLAT_HEALTH/FLAT_ARMOR aggregation) | 2026-02-19 | 5b29755 | [8-audit-and-fix-affix-pipeline-to-ensure-a](./quick/8-audit-and-fix-affix-pipeline-to-ensure-a/) |
| 9 | Rename original_base_xxx to base_xxx and base_xxx to computed_xxx; remove BasicArmor/BasicHelmet FLAT_ARMOR implicits | 2026-02-19 | ac58cda | [9-rename-original-base-xxx-to-base-xxx-and](./quick/9-rename-original-base-xxx-to-base-xxx-and/) |
| 10 | Fix the icons in the crafting view | 2026-03-06 | 0501d90 | [10-fix-the-icons](./quick/10-fix-the-icons/) |
| Phase 50-data-foundation P01 | 2 | 3 tasks | 4 files |
| Phase 51 P01 | 20 | 3 tasks | 4 files |
| Phase 52-save-persistence P01 | 8 | 2 tasks | 3 files |
| Phase 53-selection-ui P01 | 157 | 3 tasks | 3 files |
| Phase 54 P01 | 15 | 2 tasks | 1 files |

## Session Continuity

Last session: 2026-03-28
Stopped at: Milestone v1.10 initialization
Resume file: None

---
*State initialized: 2026-02-15*
*Last updated: 2026-03-28 — v1.10 milestone started*
