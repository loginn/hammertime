# Requirements: Hammertime

**Defined:** 2026-02-17
**Core Value:** The crafting loop must feel rewarding — finding items, using hammers to shape them, and equipping the result to push further into harder content.

## v1.3 Requirements

Requirements for v1.3 Save/Load & Polish milestone. Each maps to roadmap phases.

### Save/Load

- [x] **SAVE-01**: Player's full game state persists across sessions (hero equipment, currencies, area progress, crafting inventory)
- [x] **SAVE-02**: Game auto-saves every 5 minutes and on significant events (item crafted, area completed, item equipped)
- [x] **SAVE-03**: Save format includes version tracking for future migration compatibility
- [x] **SAVE-04**: Player can export save as a string and import a save string to restore state

### UI Layout

- [x] **LAYOUT-01**: Hero equipment and crafting views display side by side (equipment left, crafting right) instead of separate tabs
- [x] **LAYOUT-02**: Gameplay/combat view remains a separate full-width view toggled from the side-by-side view

### Crafting UX

- [x] **CRAFT-01**: Each hammer button shows a tooltip describing what it does and its requirements
- [x] **CRAFT-02**: Hovering an equipment slot with a craftable item available shows before/after stat comparison (item-level deltas, not total hero stats)
- [x] **CRAFT-03**: Crafting view has one crafted-item slot per item type (weapon, helmet, armor, boots, ring) instead of a single shared slot
- [x] **CRAFT-04**: Finishing an item into an occupied slot requires two-click confirmation (button text changes to confirm message, second click overwrites)

### Balance

- [x] **BAL-01**: New game starts with 1 Runic Hammer and 1 weapon base item so the player can craft their first gear
- [x] **BAL-02**: Level 1 area difficulty is reduced so a fresh hero with starter gear can survive early packs

### Polish

- [x] **UI-01**: Hero View stat panels fit within the viewport by reducing text size and whitespace

## Future Requirements

Deferred to future release. Tracked but not in current roadmap.

### Save/Load Enhancements

- **SAVE-05**: Multiple save slots for build experimentation
- **SAVE-06**: Backup rotation (2-3 auto-save backups for corruption protection)

### Crafting Enhancements

- **CRAFT-05**: Crafting preview mode — preview hammer result before spending currency
- **CRAFT-06**: Crafting audio/visual feedback (Tween flash on success/fail, sound effects)
- **CRAFT-07**: Crafting history log with undo capability

### UI Enhancements

- **UI-02**: Drag-and-drop equipping alongside click-to-equip
- **UI-03**: Visual prefix/suffix separation in item display (color-coded or sectioned)

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Cloud save sync | Requires backend infrastructure; overkill for single-player offline game |
| ScrollContainer for stats | User prefers smaller text + reduced whitespace over scroll UI |
| Starter gear auto-equipped | Player should craft first gear from base item + Runic Hammer (teaches crafting loop) |
| Crafting confirmation dialogs | Breaks crafting flow; two-click button confirmation is sufficient |
| Unlimited undo | Trivializes crafting risk/reward tension |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| SAVE-01 | Phase 18 | Satisfied |
| SAVE-02 | Phase 18 | Satisfied |
| SAVE-03 | Phase 18 | Satisfied |
| SAVE-04 | Phase 21 | Satisfied |
| LAYOUT-01 | Phase 19 | Satisfied |
| LAYOUT-02 | Phase 19 | Satisfied |
| CRAFT-01 | Phase 20 | Satisfied |
| CRAFT-02 | Phase 20 | Satisfied |
| CRAFT-03 | Phase 20 | Satisfied |
| CRAFT-04 | Phase 20 | Satisfied |
| BAL-01 | Phase 22 | Satisfied |
| BAL-02 | Phase 22 | Satisfied |
| UI-01 | Phase 22 | Satisfied |

**Coverage:**
- v1.3 requirements: 13 total
- Mapped to phases: 13 (100%)
- Satisfied: 13 (100%)
- Unmapped: 0

**Phase distribution:**
- Phase 18 (Save/Load Foundation): 3 requirements
- Phase 19 (Side-by-Side Layout): 2 requirements
- Phase 20 (Crafting UX Enhancements): 4 requirements
- Phase 21 (Save Import/Export): 1 requirement
- Phase 22 (Balance & Polish): 3 requirements

---
*Requirements defined: 2026-02-17*
*Last updated: 2026-02-18 — all 13 requirements satisfied (100%)*
