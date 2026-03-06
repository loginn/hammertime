---
phase: 39-tag-targeted-currencies
plan: "02"
subsystem: crafting
tags: [gdscript, currencies, tag-hammer, loot-table, forge-view, ui]

# Dependency graph
requires:
  - phase: 39-01
    provides: TagHammer parameterized class, GameState.spend_tag_currency()
  - phase: 35-prestige-foundation
    provides: prestige_level gate, tag_currency_counts dict, prestige_completed signal
  - phase: 33-item-drop-system
    provides: combat_engine._on_pack_killed() pattern to extend
provides:
  - LootTable.roll_pack_tag_currency_drop() — tag drop pipeline at P1+
  - combat_engine tag drop integration — emits tag_currency_dropped on pack kill
  - forge_view TagHammerSection — 5 prestige-gated tag hammer buttons
  - forge_view ForgeErrorToast — 2s auto-dismiss error feedback
affects: [forge-view, loot-table, combat-engine]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Tag currency drop pattern: roll_pack_tag_currency_drop() mirrors roll_pack_currency_drop() as separate static method, returns empty dict at P0"
    - "TagHammerSection VBoxContainer: visibility=false at scene level, _update_tag_section_visibility() gates on prestige_level >= 1"
    - "Forge error toast pattern: tween_interval(2.0) hold + tween_property modulate:a fade, matches save_toast.gd pattern with longer hold"
    - "Dual spend routing: tag types use spend_tag_currency(), standard types use spend_currency() — branched on type string in update_item()"

key-files:
  created: []
  modified:
    - models/loot/loot_table.gd
    - models/combat/combat_engine.gd
    - scenes/forge_view.gd
    - scenes/forge_view.tscn

key-decisions:
  - "InventoryLabel moved outside HammerSidebar to root ForgeView to avoid layout overlap with 5 tag buttons (~350px) added to sidebar"
  - "TagHammerSeparator placed as first child of TagHammerSection VBoxContainer so separator hides/shows with section visibility toggle"
  - "update_currency_button_states() split into standard_types loop + tag_types loop — each reads from its respective GameState dict"
  - "Tag buttons use null icon (hammer_icons.get(tag_type, null)) — no tag hammer assets exist yet"

patterns-established:
  - "Error toast in forge view: _show_forge_error() mirrors SaveToast.show_toast() with 2.0s interval"

requirements-completed: [TAG-06, TAG-07, TAG-08]

# Metrics
duration: ~7min
completed: 2026-03-01
---

# Phase 39 Plan 02: Tag-Targeted Currency Drop Pipeline and Forge UI Summary

**Tag hammer drops wired end-to-end: pack drops at P1+ via LootTable.roll_pack_tag_currency_drop(), forge view with 5 prestige-gated tag buttons, error toast on failed apply, and tag spend routing through spend_tag_currency()**

## Performance

- **Duration:** ~7 min
- **Started:** 2026-03-01T21:47:00Z
- **Completed:** 2026-03-01T21:51:35Z
- **Tasks:** 2 completed
- **Files modified:** 4

## Accomplishments

- `LootTable.roll_pack_tag_currency_drop(area_level)` static method: 7.5% chance per pack at P1+, returns empty dict at P0, supports qty-2 at area >= 50 (15% of drops)
- `combat_engine._on_pack_killed()` extended: calls tag drop roller after item drops, writes directly to `GameState.tag_currency_counts`, emits `GameEvents.tag_currency_dropped`
- `forge_view.tscn` updated: `TagHammerSection` VBoxContainer (hidden) with separator + 5 toggle buttons; `ForgeErrorToast` Label at root; `InventoryLabel` moved outside `HammerSidebar`
- `forge_view.gd` wired: 5 `@onready` button refs, currencies dict + currency_buttons dict extended, `_ready()` connects signals and gates visibility, `_update_tag_section_visibility()` controls P1 gate
- Error feedback: `_show_forge_error()` with 2.0s hold + 0.5s fade replaces bare `print()` on `can_apply()` failure
- Dual spend path: tag types route through `spend_tag_currency()`, standard types route through `spend_currency()`

## Task Commits

Each task was committed atomically:

1. **Task 1: LootTable tag drop method + combat_engine integration** - `f95bd3a` (feat)
2. **Task 2: Forge view tag hammer buttons, prestige gate, and error toast** - `c7f6c38` (feat)

## Files Created/Modified

- `models/loot/loot_table.gd` - Added `roll_pack_tag_currency_drop()` static method after `roll_pack_item_drop()`
- `models/combat/combat_engine.gd` - Extended `_on_pack_killed()` with tag drop block before `current_pack_index += 1`
- `scenes/forge_view.gd` - Added 6 @onready refs, extended currencies/currency_buttons dicts, added tag signal wiring in `_ready()`, new methods (`_update_tag_section_visibility`, `_on_tag_currency_dropped`, `_on_prestige_completed`, `_show_forge_error`), updated `update_item()` and `update_currency_button_states()`
- `scenes/forge_view.tscn` - Added `TagHammerSection` (VBoxContainer, hidden) with `TagHammerSeparator` + 5 tag buttons; added `ForgeErrorToast` Label; moved `InventoryLabel` outside `HammerSidebar`

## Decisions Made

- `InventoryLabel` moved to root ForgeView node to prevent overlap with the 5 tag hammer buttons (~350px) that would otherwise collide with the label's original y=260 position inside HammerSidebar
- `TagHammerSeparator` is a child of `TagHammerSection` so it hides and shows together with the section — no extra visibility management needed
- `update_currency_button_states()` now iterates a `standard_types` array explicitly rather than all `currency_buttons` keys, ensuring standard deselect logic only reads from `currency_counts` and tag deselect only reads from `tag_currency_counts`
- Tag buttons use `hammer_icons.get(tag_type, null)` — no tag hammer PNG assets exist, null icon accepted

## Deviations from Plan

None - plan executed exactly as written. InventoryLabel relocation was explicitly anticipated in the plan's discretionary guidance.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 39 complete: tag hammer end-to-end wired — drops at P1+, forge buttons gated behind prestige, error toast on bad apply, spend routing correct
- Phase 40 can proceed (if any); otherwise milestone v1.7 verification phase

## Self-Check: PASSED

- FOUND: models/loot/loot_table.gd (roll_pack_tag_currency_drop at line 109)
- FOUND: models/combat/combat_engine.gd (tag drop block at line 154)
- FOUND: scenes/forge_view.gd (tag_hammer_section, _show_forge_error, spend_tag_currency)
- FOUND: scenes/forge_view.tscn (TagHammerSection + ForgeErrorToast = 8 occurrences)
- FOUND commit: f95bd3a (task 1)
- FOUND commit: c7f6c38 (task 2)

---
*Phase: 39-tag-targeted-currencies*
*Completed: 2026-03-01*
