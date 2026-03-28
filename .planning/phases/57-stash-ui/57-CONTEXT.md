# Phase 57: Stash UI - Context

**Gathered:** 2026-03-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Players can see stash contents at a glance in ForgeView and move any stash item onto the crafting bench with a single tap. 15 stash slots (3 per equipment type) displayed as a horizontal row of letter-coded squares with tap-to-bench interaction and tooltip item details.

</domain>

<decisions>
## Implementation Decisions

### Stash Layout
- **D-01:** Horizontal row of 15 slots in the ItemTypeButtons area (repurposing that region), with visual gaps between each slot type group
- **D-02:** Each group of 3 slots has a label above it (Weapon, Helmet, Armor, Boots, Ring)
- **D-03:** Filled slots show 2-3 letter abbreviations of the item base type (e.g. BS for Broadsword, DA for Dagger, WN for Wand)
- **D-04:** Empty slots render as dim/greyed squares; filled slots use normal button styling with no special rarity or full-stash indicators

### Tap-to-Bench Interaction
- **D-05:** Stash slot buttons are disabled (greyed out) while the crafting bench has an item; toast via existing ForgeErrorToast if somehow tapped ("Melt or equip first")
- **D-06:** Bench must be empty to load from stash — no swap behavior (carried forward from Phase 55 D-02)
- **D-07:** On successful tap, stash slot briefly highlights/flashes as the item transfers to bench
- **D-08:** Removing an item from a stash slot leaves an empty gap — remaining items do not shift to fill it

### Post-Action Feedback
- **D-09:** After equip or melt empties the bench, stash slots re-enable with a subtle pulse animation to draw attention
- **D-10:** Stash display updates live via `stash_updated` signal, even while on Forge tab during combat

### Item Detail Popup
- **D-11:** Hovering/long-pressing a stash item shows details via Godot's built-in `tooltip_text` property — same pattern as hammer button tooltips. Plain text, auto show/hide, no custom popup.

### Claude's Discretion
- Exact abbreviation codes for all 21 item base types (as long as they're 2-3 letters and unambiguous within each slot type)
- Animation timing for highlight flash and pulse effects
- Exact positioning of stash row within ForgeView layout

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Stash Data Model
- `autoloads/game_state.gd` -- stash dict, crafting_bench, add_item_to_stash(), _init_stash()
- `autoloads/game_events.gd` -- stash_updated signal

### ForgeView (primary modification target)
- `scenes/forge_view.gd` -- ItemTypeButtons (hidden, to be repurposed), ForgeErrorToast, hammer tooltip_text pattern, currency button layout
- `scenes/forge_view.tscn` -- Scene tree with ItemTypeButtons node group

### Prior Phase Context
- `.planning/phases/55-stash-data-model/55-CONTEXT.md` -- D-01 through D-07 decisions on stash data model
- `.planning/REQUIREMENTS.md` -- STSH-02, STSH-03, STSH-05 requirement definitions

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **ItemTypeButtons** (5 hidden Button nodes in ForgeView): Currently disabled/hidden by Phase 55. Can be repurposed or replaced with stash slot buttons in the same scene tree area.
- **ForgeErrorToast** + `_show_forge_error()` tween: Existing toast pattern for invalid actions, reusable for "bench occupied" feedback.
- **Hammer tooltip_text pattern**: All 11 hammer buttons use Godot's built-in tooltip_text for hover descriptions. Same pattern for stash item details.
- **GameEvents.stash_updated signal**: Already emits with slot type string when stash changes. Ready for UI binding.

### Established Patterns
- Button-based UI with `pressed.connect()` callbacks throughout ForgeView
- `mouse_entered`/`mouse_exited` signals for hover behavior (used on equip button, type buttons)
- Tween-based animations for toast (forge error toast fades out)
- `_update_currency_display()` pattern: refreshes all button states from GameState — stash display can follow same refresh pattern

### Integration Points
- `ForgeView._ready()` lines 187-198: ItemTypeButtons disabled/hidden — this is the insertion point for stash UI
- `GameEvents.stash_updated` signal: connect in ForgeView._ready() to trigger display refresh
- `GameState.stash` dict: keyed by slot string ("weapon", "helmet", etc.), each value is Array capped at 3
- `GameState.crafting_bench`: null when empty, Item when occupied — drives stash button enable/disable state

</code_context>

<specifics>
## Specific Ideas

No specific external references — standard Godot UI patterns apply.

</specifics>

<deferred>
## Deferred Ideas

- **Item drop filter for unwanted loot** — reviewed, out of scope (future prestige feature per STATE.md)
- **Save slot for work-in-progress item** — reviewed, out of scope (bench is single-item by design)

### Reviewed Todos (not folded)
- "Add item drop filter for unwanted loot" — future prestige unlock, not Phase 57 scope
- "Add a save slot for work-in-progress item" — conflicts with single-bench design (Phase 55 D-02)

</deferred>

---

*Phase: 57-stash-ui*
*Context gathered: 2026-03-28*
