# Phase 40: Prestige UI - Context

**Gathered:** 2026-03-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Prestige UI: player-facing prestige status display, cost/reward information, 7-level unlock table, and confirmation flow with prestige trigger. Requirements: PRES-04, PUI-01 through PUI-05.

</domain>

<decisions>
## Implementation Decisions

### Prestige Status Placement
- Prestige badge lives in the tab bar region — visible across all views
- Compact format: "P3" (letter P + level number)
- Hidden at P0 — no clutter for new players before first prestige
- Badge IS the Prestige tab button (one element, two purposes)

### Prestige Tab & Discovery
- Dedicated Prestige tab (4th tab alongside Forge/Combat/Settings)
- Tab hidden until player can first afford prestige (P0 → P1 threshold met)
- Once the tab appears, it stays permanently — never re-hides even if currency drops below next cost
- Clicking the P badge in the tab bar navigates to the prestige view

### Confirmation Flow
- Two-click pattern on same button (matches existing equip confirmation)
- Default button text: "Upgrade your forge"
- First click changes text to: "Reset progress?"
- Second click executes prestige
- Button disabled when player can't afford prestige (consistent with hammer buttons)
- After prestige: fade to black transition (0.5s tween on ColorRect overlay), then scene reload via get_tree().reload_current_scene()

### Unlock Table
- Vertical list with rows in VBoxContainer
- Each row: prestige level, max item tier unlock, reward text, cost
- Completed levels: checkmark indicator
- Current level: arrow/highlight indicator
- Future levels: locked indicator
- Future prestige costs hidden (only show cost for next level; others show "???")
- Per-level reward text column — P1 shows "Tag Hammers", other levels show tier-only for now but structure supports future reward additions per level
- Static reset list below the table: "Prestige resets: Area progress, Equipment, Inventory, Currencies, Tag Currencies"

### Claude's Discretion
- Exact layout and spacing within 1280x720 viewport
- Font sizes and color choices for row states (completed/current/locked)
- Timer duration for two-click confirmation timeout
- Whether the fade-to-black ColorRect lives in main.tscn or prestige_view.tscn

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- PrestigeManager autoload: has can_prestige(), get_next_prestige_cost(), execute_prestige(), PRESTIGE_COSTS, ITEM_TIERS_BY_PRESTIGE constants
- GameEvents: prestige_completed signal already exists
- settings_view.gd: two-click confirm pattern (new_game_button) and scene reload via new_game_started signal
- forge_view.gd: _update_tag_section_visibility() gates on prestige_level >= 1 — pattern for conditional UI

### Established Patterns
- Tab switching: main_view.gd show_view() toggles visibility + disables active tab button
- CanvasLayer visibility must be synced explicitly (combat_ui pattern)
- Button states: disabled when count is 0 (currency_buttons pattern)
- Two-click confirm: equip_confirm_pending bool + Timer with timeout callback
- Scene reload: get_tree().reload_current_scene() used for new game and import

### Integration Points
- main_view.gd: add prestige_view as 4th view in ContentArea, add prestige tab button in TabBar
- main_view.gd: show_view() needs "prestige" case
- Tab bar: P badge button hidden/shown based on prestige_level > 0 OR can_prestige()
- GameEvents.prestige_completed: trigger save + fade + reload
- settings_view.gd new_game_started signal pattern: reuse for prestige reload

</code_context>

<specifics>
## Specific Ideas

- "Upgrade your forge" as prestige button text — thematic to Hammertime, not generic "Prestige"
- "Reset progress?" as confirmation text — clear consequence without being too wordy
- Fade to black transition for prestige — feels momentous, simple to implement with tween
- Unlock table should be extensible for future per-level rewards beyond tier unlocks

</specifics>

<deferred>
## Deferred Ideas

- P2-P7 prestige costs need tuning (currently stub 999999) — balance/tuning task, not UI
- Future per-level rewards beyond tag hammers and tier unlocks — future milestone feature

</deferred>

---

*Phase: 40-prestige-ui*
*Context gathered: 2026-03-06*
