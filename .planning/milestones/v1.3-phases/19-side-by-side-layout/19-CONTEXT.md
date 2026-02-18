# Phase 19: Side-by-Side Layout - Context

**Gathered:** 2026-02-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Restructure the UI so hero equipment and crafting display on the same screen ("The Forge"), replacing the current separate Hero View and Crafting View. Add a top tab bar for navigation between The Forge, Combat, and Settings. Gameplay/combat view remains a separate full-width screen. Viewport changes from 1200x700 to 1280x720.

</domain>

<decisions>
## Implementation Decisions

### Viewport & Layout Structure
- Viewport changes to **1280x720** (from 1200x700)
- Top tab bar: y=0, height 40px — tabs: "The Forge" | "Combat" | ... | "Settings" (right-aligned)
- 10px vertical padding between tab bar and content
- Content area starts at y=50, total content height 660px
- Dark panels (#333 range) on darker background (#1a1a1a range) — dark theme

### The Forge View (replaces Hero View + Crafting View)
- Single unified view called **"The Forge"** replaces both Hero View and Crafting View
- Full hero view compressed to left side, full crafting view compressed to right side
- If space is tight, **prioritize crafting** — it's the active workflow; hero panel is compact reference

### Panel Layout (exact positions, content starts at y=50)

| Panel | Position (x, y) | Size (WxH) |
|-------|-----------------|-------------|
| Hammer sidebar | (40, 50) | 260 x 660 |
| Item graphics | (340, 50) | 430 x 160 |
| Item type buttons | (340, 210) | 430 x 40 |
| Hero graphics | (810, 50) | 430 x 200 |
| Item Stats | (340, 280) | 430 x 430 |
| Hero Stats | (810, 280) | 430 x 430 |

- 40px horizontal margins and gaps between panels
- 30px vertical gap between graphics row and stats row
- 10px bottom margin (content ends at y=710)
- Visible panel backgrounds with subtle borders

### Hammer Sidebar
- 2-column grid of hammer icons
- Icons: 45x45px with 20px gaps
- 6 current hammers fill 3 rows
- Remaining space below for future hammer types
- Hammer icon assets in `assets/` folder

### Item Type Selection
- 5 equal-width buttons (~80px each) in a row below item image: weapon, helmet, armor, boots, ring
- Selecting/hovering a type swaps Hero Stats panel to show the currently equipped item of that type for comparison
- Item image above is a placeholder (sword2.png) — does not change per type yet

### Item Stats Panel Actions
- Two buttons at bottom of Item Stats panel: **Melt** (left) and **Equip** (right)
- Player must choose Melt or Equip before beginning a new craft
- **Melt**: destroys the item, frees the crafting slot (recycle-for-currency is deferred)
- **Equip**: equips to hero's slot, swaps instantly — **old item is destroyed** (no swap-back)

### Hero Stats Updates
- Hero stats update **instantly when equipping** a crafted item
- Stats do NOT update during crafting — only on equip action

### Navigation
- Top tab bar with 3 tabs: "The Forge", "Combat", "Settings"
- Settings tab right-aligned on the bar
- Each tab is a full-screen view below the tab bar
- Combat view: full-width (Claude's discretion on adjustments for consistency)
- Settings view: full-screen tab view (not a modal)

### Claude's Discretion
- Combat view layout adjustments (if any) for consistency with new viewport
- Exact dark theme color values
- Panel border/shadow styling
- Text sizing and spacing within panels
- Settings view content layout
- Tab bar visual styling (active/inactive states)
- Transition/animation between views (if any)

</decisions>

<specifics>
## Specific Ideas

- Wireframe reference: `Wireframe/Hero view.png` — the definitive layout reference
- Placeholder images: `assets/sword2.png` (item), `assets/hero.png` (hero portrait)
- View name is "The Forge" — not "Crafting" or "Hero View"
- The layout deliberately puts hammers on the far left as a persistent toolbar, with item and hero as the two main content columns

</specifics>

<deferred>
## Deferred Ideas

- **Melt-for-currency recycling** — Melt button currently just destroys; recycle mechanic (return hammers/materials) belongs in a future phase
- **Dynamic item images** — Item graphics placeholder doesn't change per type yet; could show actual item art per type in a future phase
- **4-column hammer grid** — Currently 2 columns; could expand to 4 columns if more hammer types are added

</deferred>

---

*Phase: 19-side-by-side-layout*
*Context gathered: 2026-02-17*
