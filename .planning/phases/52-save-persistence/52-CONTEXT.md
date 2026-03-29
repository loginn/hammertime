# Phase 52: Save & Persistence - Context

**Gathered:** 2026-03-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Bump save format to v8 with hero_archetype_id persistence. Old saves (v7 and below) trigger a fresh new game — both file loads and import strings. Add hero_archetype null-out to _wipe_run_state() so prestige resets the hero choice.

Requirements: SAVE-01

</domain>

<decisions>
## Implementation Decisions

### Save Format v8
- **D-01:** Add `hero_archetype_id` field to `_build_save_data()`. Value is the string ID (e.g., `"str_hit"`) or `null` for classless Adventurer.
- **D-02:** Bump `SAVE_VERSION` from 7 to 8. Existing delete-on-old-version policy (`saved_version < SAVE_VERSION` → delete and start fresh) handles v7 saves automatically.
- **D-03:** In `_restore_state()`, read `hero_archetype_id` from save data and restore `GameState.hero_archetype` via `HeroArchetype.from_id()`. Missing or null key → `hero_archetype` stays null (classless Adventurer).
- **D-04:** P0 saves write `hero_archetype_id: null` explicitly. On load, null default is sufficient — classless behavior is already the default from Phase 50/51.

### Import String Versioning
- **D-05:** Import strings with `version < SAVE_VERSION` must be rejected — never accept old versions. Return `{success: false, error: "outdated_version"}` for any pre-v8 import string.
- **D-06:** This replaces the current lenient import behavior (save_manager.gd:218-219 which silently accepted old versions with defaults). No backward compatibility until first alpha release.

### Prestige Wipe Behavior
- **D-07:** `_wipe_run_state()` in game_state.gd sets `hero_archetype = null` alongside existing run-state resets. This forces hero re-selection on each prestige, matching ROADMAP intent ("Hero choice resets on each prestige").
- **D-08:** Phase 52 owns the wipe logic; Phase 53 owns the UI that detects null archetype and shows the selection overlay.

### Claude's Discretion
- Whether to add a `hero_selected` save trigger (auto-save when hero is picked) — may not be needed until Phase 53 wires the selection UI
- Test structure for save round-trip verification
- Exact error message wording for outdated import strings

</decisions>

<specifics>
## Specific Ideas

- Never accept old save versions (file or import) until first alpha release — always reset to fresh game
- Save format changes should be minimal: one new field (`hero_archetype_id`) added to build/restore

</specifics>

<canonical_refs>
## Canonical References

### Requirements
- `.planning/REQUIREMENTS.md` — SAVE-01 (save format v8 with hero_archetype_id, old saves trigger new game)

### Prior Phase Context
- `.planning/phases/50-data-foundation/50-CONTEXT.md` — D-07: spell_user on archetype data; hero roster with string IDs
- `.planning/phases/51-stat-integration/51-CONTEXT.md` — D-04: is_spell_user removed from save format, derived from archetype

### Existing Patterns
- `autoloads/save_manager.gd` — Save/load pipeline, _build_save_data()/_restore_state(), export/import strings, version check policy
- `autoloads/game_state.gd` — GameState fields, _wipe_run_state(), initialize_fresh_game()
- `autoloads/prestige_manager.gd` — execute_prestige() calls _wipe_run_state()
- `models/hero_archetype.gd` — HeroArchetype.from_id() for deserialization, REGISTRY with string IDs

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `HeroArchetype.from_id(id: String)`: Already exists from Phase 50 — converts string ID back to HeroArchetype Resource
- `_build_save_data()` / `_restore_state()`: Established save pipeline — add one field to each
- Delete-on-old-version policy: `saved_version < SAVE_VERSION` → `delete_save()` and return false — already handles v7→v8 migration

### Established Patterns
- Save fields follow `GameState.field_name` → `data["field_name"]` mapping with `.get()` defaults
- Prestige state (prestige_level, max_item_tier_unlocked) survives `_wipe_run_state()` — hero_archetype should be wiped (it's run-scoped, re-selected each prestige)
- Version constant bump + existing version check is the only migration mechanism needed

### Integration Points
- `save_manager.gd:SAVE_VERSION` — bump 7 → 8
- `save_manager.gd:_build_save_data()` — add hero_archetype_id field
- `save_manager.gd:_restore_state()` — restore hero_archetype from ID
- `save_manager.gd:import_save_string()` — reject old versions instead of accepting silently
- `game_state.gd:_wipe_run_state()` — add `hero_archetype = null`
- `game_state.gd:initialize_fresh_game()` — ensure hero_archetype = null (already the default)

</code_context>

<deferred>
## Deferred Ideas

- Hero selection UI detecting null archetype post-prestige — Phase 53
- Auto-save trigger on hero selection — Phase 53 (when selection UI exists)
- Hero bonus display in stat panel — Phase 54

</deferred>

---

*Phase: 52-save-persistence*
*Context gathered: 2026-03-27*
