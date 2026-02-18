# Project State: Hammertime

**Updated:** 2026-02-17
**Milestone:** v1.3 Save/Load & Polish

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-17)

**Core Value:** The crafting loop must feel rewarding — finding items, using hammers to shape them, and equipping the result to push further into harder content.

**Current Focus:** Phase 21 - Save Import/Export

**Architecture:** Godot 4.5 GDScript, feature-based folders (models/, scenes/, autoloads/, utils/, tools/), Resource-based data model, signal-based communication via GameEvents, JSON save/load via SaveManager autoload.

## Current Position

Phase: 20 of 22 (Crafting UX Enhancements)
Plan: 3 of 3 complete
Status: Complete
Last activity: 2026-02-18 - Completed quick task 2: Adventure tab UI has overlaps - move HP bars lower so they dont overlap with buttons

Progress: [████████████████████░] 91% (20/22 phases)

## Performance Metrics

**Milestone v1.2 (shipped 2026-02-17):**
- Phases: 5 (13-17)
- Plans executed: 11
- Requirements delivered: 21/21
- Gap closures: 1 (17-03 CanvasLayer fixes)
- Timeline: 2 days (2026-02-16 → 2026-02-17)
- Final LOC: 3,943 GDScript

**Milestone v1.1 (shipped 2026-02-16):**
- Phases: 4 (9-12)
- Plans executed: 7
- Tasks completed: 13
- Requirements delivered: 18/18
- Gap closures: 2
- Timeline: 2 days (2026-02-15 → 2026-02-16)
- Final LOC: 3,161 GDScript

**Milestone v1.0 (shipped 2026-02-15):**
- Phases: 4 (5-8), Plans: 7, Tasks: 14
- Final LOC: 2,488 GDScript

**Milestone v0.1 (shipped 2026-02-15):**
- Phases: 4 (1-4), Plans: 8
- Final LOC: 1,953 GDScript

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
All v1.2 decisions marked ✓ Good.

Recent decisions affecting v1.3 work:
- JSON save/load chosen over ResourceSaver (Phase 21 needs export strings)
- SaveManager autoload registered before GameState in autoload order
- Crafting inventory and area progress centralized in GameState for persistence
- Explicit CanvasLayer visibility management (v1.2) informs side-by-side layout approach
- [Phase 19]: TAB key now only toggles between forge and combat views (settings accessible via tab button only)
- [Phase 19]: Combat tab renamed to Adventure for user-facing clarity
- [Phase 19]: Viewport clear color set to dark gray matching theme background
- [Phase 19]: Use theme_override_font_sizes/font_size = 11 for all ForgeView UI text to prevent overflow in 1280x670 viewport
- [Phase 19]: Set item type buttons to 86px width with zero gaps to eliminate hover flicker
- [Phase 19]: Restore rarity color via modulate property matching Item.get_rarity_color() design
- [Phase 20]: Use Godot built-in tooltip_text for hammer tooltips (auto show/hide behavior)
- [Phase 20]: Equip and Melt operate directly on current_item, removing finished_item state
- [Phase 20]: Two-click equip confirmation with 3-second Timer auto-reset
- [Phase 20]: RichTextLabel with BBCode for colored stat comparison deltas (green #55ff55 / red #ff5555)
- [Phase 20]: Stat comparison shows item-level contribution differences, not total hero stat changes

### v1.3 Requirements Coverage

**Total requirements:** 13
- Save/Load: SAVE-01, SAVE-02, SAVE-03, SAVE-04 (4)
- UI Layout: LAYOUT-01, LAYOUT-02 (2)
- Crafting UX: CRAFT-01, CRAFT-02, CRAFT-03, CRAFT-04 (4)
- Balance: BAL-01, BAL-02 (2)
- Polish: UI-01 (1)

**Phase mapping:**
- Phase 18: SAVE-01, SAVE-02, SAVE-03
- Phase 19: LAYOUT-01, LAYOUT-02
- Phase 20: CRAFT-01, CRAFT-02, CRAFT-03, CRAFT-04
- Phase 21: SAVE-04
- Phase 22: BAL-01, BAL-02, UI-01

**Coverage:** 13/13 (100%)

### Known Issues

- debug_hammers flag in game_state.gd (currently true)
- Deprecated LootTable methods kept for drop_simulator tool (get_item_drop_count, roll_currency_drops)
- Level 1 difficulty may be too high for fresh heroes (addressing in Phase 22)

### Deferred Items

**v1.4+ scope:**
- Totem system (forge god shrine with slottable pieces, favor mechanic, map modifiers)
- Hybrid defense prefixes (armor+evasion single-slot affixes)
- Visual prefix/suffix separation in UI (color-coded or sectioned)
- Tag-based affix pool tooltips
- Multiple save slots (SAVE-05)
- Save backup rotation (SAVE-06)
- Crafting preview mode (CRAFT-05)
- Crafting audio/visual feedback (CRAFT-06)
- Crafting history with undo (CRAFT-07)
- Drag-and-drop equipping (UI-02)

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 1 | Fix Light Sword item type button regenerating a free weapon while other types do not | 2026-02-15 | c0bcfb8 | [1-fix-light-sword-item-type-button-regener](./quick/1-fix-light-sword-item-type-button-regener/) |
| Phase 19 P03 | 3 | 2 tasks | 2 files |
| Phase 20 P03 | 42 | 1 tasks | 2 files |
| 2 | Adventure tab UI has overlaps - move HP bars lower so they dont overlap with buttons | 2026-02-18 | c4a180c | [2-adventure-tab-ui-has-overlaps-move-hp-ba](./quick/2-adventure-tab-ui-has-overlaps-move-hp-ba/) |

## Session Continuity

**Last session:** 2026-02-18T01:59:28.726Z
- Phase 20 (Crafting UX Enhancements) complete — 3 of 3 plans executed
- Plan 20-01: Added hammer tooltips, removed Finish Item workflow, added two-click equip confirmation
- Plan 20-02: Added stat comparison display on equip hover with green/red BBCode-colored deltas
- Plan 20-03: UAT gap closure - reduced tooltip delay (0.5s → 0.2s), fixed button state refresh on type switch
- Requirements CRAFT-01, CRAFT-02, CRAFT-03, CRAFT-04 all delivered

**Next step:** `/gsd:plan-phase 21` to begin Save Import/Export

---
*State initialized: 2026-02-15*
*Last updated: 2026-02-18 — Quick task 2: Adventure tab UI overlap fix*
