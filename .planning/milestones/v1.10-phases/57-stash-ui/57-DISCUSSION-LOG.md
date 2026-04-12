# Phase 57: Stash UI - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-28
**Phase:** 57-stash-ui
**Areas discussed:** Stash layout & letter icons, Tap-to-bench interaction, Item detail popup, Empty/full state visual treatment, Slot ordering, Post-action feedback, Update timing, Slot labels

---

## Stash Layout & Letter Icons

### Layout approach

| Option | Description | Selected |
|--------|-------------|----------|
| Single row above bench | All 15 slots horizontal, grouped with separators | |
| Column beside bench | Vertical stack of 5 rows, 3 slots each | |
| Repurpose ItemTypeButtons area | Replace hidden type buttons with stash groups | |

**User's choice:** Combination of 1 and 3 — horizontal row in the ItemTypeButtons area with gaps between slot types
**Notes:** User wanted both the horizontal layout and the reuse of the existing button area

### Letter representation

| Option | Description | Selected |
|--------|-------------|----------|
| First letter of item name | Simple, collisions possible (B for Broadsword and Battleaxe) | |
| Short abbreviation | 2-3 letter codes (BS, BA, DA, etc.) to avoid collisions | ✓ |
| First letter + rarity color | Single letter with rarity-colored border | |

**User's choice:** Short abbreviation (2-3 letter codes)
**Notes:** None

---

## Tap-to-Bench Interaction

### Bench occupied feedback

| Option | Description | Selected |
|--------|-------------|----------|
| Toast message | Reuse ForgeErrorToast ("Melt or equip first") | |
| Disable stash buttons | Grey out all stash slots while bench has item | |
| Both | Disabled buttons + toast fallback | ✓ |

**User's choice:** Both — disabled buttons plus toast as fallback
**Notes:** None

### Transfer visual feedback

| Option | Description | Selected |
|--------|-------------|----------|
| Instant swap | Item disappears/appears immediately | |
| Brief highlight | Stash slot flashes on transfer | ✓ |
| You decide | Claude picks based on existing patterns | |

**User's choice:** Brief highlight flash on transfer
**Notes:** None

---

## Item Detail Popup

| Option | Description | Selected |
|--------|-------------|----------|
| Godot tooltip_text | Built-in hover tooltip, plain text, same as hammers | ✓ |
| Floating panel | Custom rich panel with rarity colors and affix tiers | |
| Reuse ItemStatsLabel | Temporarily show details in existing stats panel | |

**User's choice:** Godot tooltip_text (built-in, same pattern as hammer tooltips)
**Notes:** None

---

## Empty/Full State Visual Treatment

| Option | Description | Selected |
|--------|-------------|----------|
| Filled normal, no full indicator | Standard buttons for filled, no special treatment | ✓ |
| Filled with rarity color | Slot background tints to Normal/Magic/Rare | |
| Filled + full indicator | Rarity colored + badge when 3/3 | |

**User's choice:** Simple — filled slots normal styling, empty slots dim/greyed, no special indicators
**Notes:** None

---

## Additional Gray Areas (Round 2)

### Slot ordering after removal

| Option | Description | Selected |
|--------|-------------|----------|
| Shift left | Remaining items fill the gap | |
| Empty gap | Slot stays empty where item was removed | ✓ |

**User's choice:** Empty gap — no shifting
**Notes:** Answered inline

### Post-equip/melt stash hint

| Option | Description | Selected |
|--------|-------------|----------|
| Silent re-enable | Stash slots just become tappable again | |
| Subtle pulse | Stash slots pulse when bench empties | ✓ |

**User's choice:** Subtle pulse animation
**Notes:** Answered inline

### Stash update timing

| Option | Description | Selected |
|--------|-------------|----------|
| Live updates | Stash refreshes in real-time via signal | ✓ |
| Tab-switch refresh | Only refresh when switching to Forge tab | |

**User's choice:** Live updates via stash_updated signal
**Notes:** Answered inline

### Slot type labels

| Option | Description | Selected |
|--------|-------------|----------|
| Labels per group | Each group of 3 gets a label (Weapon, Helmet, etc.) | ✓ |
| No labels | Abbreviations and grouping are self-explanatory | |

**User's choice:** Add labels
**Notes:** Answered inline

---

## Claude's Discretion

- Exact 2-3 letter abbreviation codes for all 21 item base types
- Animation timing for highlight flash and pulse effects
- Exact positioning of stash row within ForgeView layout

## Deferred Ideas

- Item drop filter for unwanted loot — future prestige feature
- Save slot for work-in-progress item — conflicts with single-bench design
