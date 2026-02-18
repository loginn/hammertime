# Phase 21: Save Import/Export - Context

**Gathered:** 2026-02-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Players can export their full game state as a copyable string and import save strings to restore or share game state. Builds on Phase 18's core save/load infrastructure and SaveManager autoload.

</domain>

<decisions>
## Implementation Decisions

### Save string format
- Base64-encoded JSON — compact, safe to paste anywhere, not human-readable
- Prefixed with game identifier and version: `HT1:base64data` format for quick validation
- Includes checksum appended to detect corruption/truncation before attempting decode
- Always exports full game state — no partial/selective export

### Export/Import UI
- Controls live in the existing Settings menu alongside save/load buttons
- Export flow: Click "Export Save" button, string auto-copies to clipboard, success toast confirms "Copied!"
- Import flow: TextEdit field for pasting + "Import Save" button to apply
- Import button disabled when text field is empty (prevents empty import errors)
- Export button always enabled (even for fresh game state)

### Import behavior
- Two-click confirmation before overwriting: first click shows "This will overwrite your current save. Confirm?", second click applies (consistent with equip confirmation pattern)
- No auto-backup before import — user is responsible for exporting current save first if wanted
- After successful import: load into memory AND persist to disk immediately
- Success toast notification after import, no automatic reload — user navigates normally to see new state

### Error handling
- Errors displayed via toast notifications (red-tinted, matching existing save toast pattern)
- Generic error message for all import failures: "Invalid save string. Please check and try again."
- Prefix check catches non-Hammertime strings before decode attempt
- Checksum validation catches truncated/corrupted strings

### Claude's Discretion
- Version compatibility handling for newer/older save versions
- Exact checksum algorithm choice
- TextEdit field sizing and placement within settings layout
- Toast duration and styling details

</decisions>

<specifics>
## Specific Ideas

- Two-click import confirmation mirrors the equip overwrite confirmation from Phase 20 — consistent UX pattern
- Export auto-copy to clipboard keeps the flow to a single click — no text field for export
- HT1 prefix format allows future version bumps (HT2, etc.) if save format changes drastically

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 21-save-import-export*
*Context gathered: 2026-02-18*
