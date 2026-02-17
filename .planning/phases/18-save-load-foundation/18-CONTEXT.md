# Phase 18: Save/Load Foundation - Context

**Gathered:** 2026-02-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Persist full game state across sessions with automatic saving, manual save option, and version tracking for future migration. Single save slot. Import/export is Phase 21.

</domain>

<decisions>
## Implementation Decisions

### Save/Load UI
- Auto-save + manual save button
- Manual save button lives in a settings/menu area (gear icon or similar), not on the main game screen
- Auto-save shows a brief toast/indicator (1-2 seconds, then fades) — e.g., small "Saved" text
- Manual save shows the same brief toast — consistent feedback, no special treatment
- New Game option also lives in the same settings/menu

### Game startup flow
- Auto-load last save on launch — no title screen or menu
- If no save exists (first launch), start a fresh game immediately — no welcome screen
- Assume loading is instant — no loading indicator needed (save data is small)
- If save is corrupted/fails to load: start fresh game + warning toast ("Save could not be loaded")

### Save data scope
- **Saved:** Hero equipment, currencies, crafting inventory, crafting bench contents, highest area unlocked
- **Not saved:** Mid-combat state (combat restarts from beginning of area on load), derived stats (recalculated from equipment on load)
- Stats are derived from equipment on load — single source of truth, no redundant stat storage
- Area progress tracked as highest area unlocked (all previous areas available)
- Crafting bench state persists — whatever's on the bench stays across sessions

### Failure & reset UX
- New Game requires double confirmation (first click → "Are you sure?", second click → wipes save)
- New Game immediately auto-saves the fresh state to disk
- Auto-save failure shows a simple "Save failed" toast — no advice, no gameplay blocking
- Corrupted save on load → fresh game + warning (covered in startup flow above)

### Claude's Discretion
- Save file format and location (JSON, Godot resource, user:// path)
- Save version schema design
- Auto-save timer implementation
- Toast/indicator visual design and positioning
- Settings menu layout and styling

</decisions>

<specifics>
## Specific Ideas

- Double confirmation pattern for New Game matches the overwrite confirmation planned for Phase 20 (CRAFT-04) — keep consistent
- Save toast should be subtle enough to not distract from gameplay but visible enough that the player notices it happened

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 18-save-load-foundation*
*Context gathered: 2026-02-17*
