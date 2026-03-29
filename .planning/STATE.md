---
gsd_state_version: 1.0
milestone: v0.1
milestone_name: milestone
status: verifying
stopped_at: Completed 58-02-PLAN.md (Save v9 stash/bench serialization and shim removal)
last_updated: "2026-03-29T00:50:05.111Z"
last_activity: 2026-03-29
progress:
  total_phases: 4
  completed_phases: 4
  total_plans: 8
  completed_plans: 8
---

# Project State: Hammertime

**Updated:** 2026-03-28
**Milestone:** v1.10 Early Game Rebalance

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-28)

**Core value:** The crafting loop must feel rewarding — finding items, using hammers to shape them, and equipping the result to push further into harder content.
**Current focus:** Phase 58 — New Hammers & Save v9

**Architecture:** Godot 4.5 GDScript, feature-based folders (models/, scenes/, autoloads/, utils/), Resource-based data model, signal-based communication via GameEvents, JSON save/load via SaveManager autoload (format v8), PrestigeManager autoload.

## Current Position

Phase: 58
Plan: Not started
Status: Phase complete — ready for verification
Last activity: 2026-03-29

```
v1.10 Progress: [ 55 ][ 56 ][ 57 ][ 58 ]
                [    ][    ][    ][    ]
                  0%
```

## Performance Metrics

**Milestone v1.9 (shipped 2026-03-28):**

- Phases: 5 (50-54) | Plans: 5 | Requirements: 6/6 | Timeline: 1 day

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
- [Phase 55-stash-data-model]: crafting_inventory and crafting_bench_type kept as property shims for v8 save_manager compat — real removal deferred to Phase 58
- [Phase 55-stash-data-model]: initialize_fresh_game() and _wipe_run_state() no longer create Broadsword.new(8) starter weapon — Phase 56 handles starter items
- [Phase 55-02]: ItemTypeButtons hidden not removed — Phase 57 repurposes them as stash slot navigation
- [Phase 55-02]: Dead code stubs with push_warning for add_item_to_inventory and set_new_item_base — dead, traceable, Phase 57 may reuse
- [Phase 56-difficulty-starter-kit]: Currency keys renamed to PoE conventions: runic->transmute, forge->augment, tack->alteration, grand->regal, claw->chaos, tuning->exalt (D-05). Starter counts updated to 2 transmute + 2 augment.
- [Phase 56-difficulty-starter-kit]: null archetype = STR defaults (Broadsword + IronPlate) for P0 fresh game; starter items placed after archetype selection not during wipe
- [Phase 57-stash-ui]: Used is-keyword for item abbreviation lookup; removed currently_hovered_type hover branch; accepted tooltip gap on disabled filled slots (Godot suppresses tooltips on disabled Controls)
- [Phase 57-stash-ui]: items[index] = null over remove_at: preserves stash slot positions per D-08 no-shift rule
- [Phase 57-stash-ui]: add_item_to_stash counts non-null items for cap and fills null gaps before append to handle D-08 null-gap arrays
- [Phase 58]: TackHammer (Alteration) rejects on Normal and Rare; no room-for-mods check since clear() always makes room
- [Phase 58]: GrandHammer (Regal) rejects on Normal and Rare; adds exactly one mod after setting RARE rarity — PoE Regal convention
- [Phase 58]: Save v9 rejects v8 saves strictly (delete + fresh start) — consistent with no-migration policy
- [Phase 58]: Test group 50 uses _build_save_data()/_restore_state() directly to avoid file I/O in integration tests

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
| Phase 55-stash-data-model P01 | 5 | 2 tasks | 3 files |
| Phase 55-stash-data-model P02 | 8 | 2 tasks | 2 files |
| Phase 56-difficulty-starter-kit P01 | 15 | 1 tasks | 6 files |
| Phase 56-difficulty-starter-kit P02 | 18 | 3 tasks | 5 files |
| Phase 57-stash-ui P01 | 25 | 2 tasks | 3 files |
| Phase 57-stash-ui P02 | 15 | 2 tasks | 2 files |
| Phase 58 P01 | 8 | 2 tasks | 4 files |
| Phase 58 P02 | 15 | 2 tasks | 3 files |

## Session Continuity

Last session: 2026-03-29T00:44:22.250Z
Stopped at: Completed 58-02-PLAN.md (Save v9 stash/bench serialization and shim removal)
Resume file: None

---
*State initialized: 2026-02-15*
*Last updated: 2026-03-28 — v1.10 roadmap ready, Phase 55 next*
