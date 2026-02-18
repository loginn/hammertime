# Phase 20: Crafting UX Enhancements - Context

**Gathered:** 2026-02-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Improve the crafting workflow with hammer tooltips, stat comparison on equip, per-type independent crafting slots, and safety confirmation when overwriting equipped items. No new crafting mechanics or item types — this is UX polish on existing systems.

</domain>

<decisions>
## Implementation Decisions

### Tooltip design
- Hover tooltips on hammer buttons (appear on hover, disappear on mouse leave)
- Content: hammer name, effect description in a sentence (e.g. "Turns a normal item into a rare item"), and rarity requirement
- Description only — no count in tooltip (count already visible on button)
- Position: above the hammer button

### Stat comparison
- Stat deltas display inline in the hero stats panel (left side of ForgeView) when hovering the Equip button
- Format: current value with colored +/- delta (e.g. "DPS: 45 +12" in green, "Armor: 30 -5" in red)
- Triggers on hovering the Equip button — compares currently equipped item vs the crafted item about to be equipped
- Shows all relevant stats that would change (DPS, armor, evasion, ES, resistances, life, mana, etc.)
- Shows item-level contribution differences, not total hero stat changes

### Per-type slot layout
- Each item type (weapon, helmet, armor, boots, ring) has its own independent crafting slot
- Switching item types shows the different item without losing work on other types
- Items auto-fill from inventory (whatever is stored for that type)
- Items come from loot drops only — no free generation buttons
- Claude has discretion on empty slot visual treatment (fits dark theme)
- Researcher should verify current state: do item type buttons already maintain separate items or share one slot?

### Safety confirmations
- Only the Equip action gets confirmation (not hammers or other actions)
- Remove the existing "Finish Item" button entirely
- Modify existing Equip button: when equipping would overwrite an existing equipped item, button text changes to "Confirm Overwrite?"
- Text change only — no color change on the button
- Confirm state times out after 3 seconds and reverts to normal "Equip" text
- When slot is empty, Equip works immediately with no confirmation

### Claude's Discretion
- Empty crafting slot visual treatment
- Tooltip hover delay timing
- Exact tooltip styling (fits dark theme)
- Stat delta color values (green/red shades)

</decisions>

<specifics>
## Specific Ideas

- Hammer tooltip descriptions should be natural sentences (e.g. "Turns a normal item into a rare item") not technical jargon
- The Equip button already exists — this is a behavior change, not a new button
- The Finish Item button should be removed, not hidden

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 20-crafting-ux-enhancements*
*Context gathered: 2026-02-17*
