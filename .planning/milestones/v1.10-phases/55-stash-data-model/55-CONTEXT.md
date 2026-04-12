# Phase 55 Context: Stash Data Model

**Created:** 2026-03-28
**Phase goal:** A 3-slot stash buffer per equipment type exists in GameState and items dropped from combat fill it automatically.
**Requirements:** STSH-01, STSH-04

## Design Shift: Single Universal Crafting Bench

The crafting bench changes from 5 per-type slots to a **single universal slot**. This is a fundamental model change:

- **Old model:** `crafting_inventory` dict with one item per slot type, `crafting_bench_type` selector to switch between them
- **New model:** Single `crafting_bench` item (any type), `stash` dict with 3-slot arrays per type

Items flow: **drop -> stash -> (player taps in Phase 57) -> bench**

The `crafting_bench_type` concept and its 5-button selector are removed. ForgeView still shows one item at a time on the bench, but the player loads it from stash rather than switching between pre-filled slots.

## Decisions

### D-01: Drops always go to stash
Items from combat always land in the stash array for the appropriate slot type. The bench is never auto-filled. The player always chooses what to work on by tapping a stash item (Phase 57).

**Why:** Prevents the system from choosing a base for the player. The player should decide which base to craft on.

### D-02: Bench loads only when empty
Tapping a stash item to load the bench is rejected if the bench already has an item. No swap behavior (bench item does not return to stash). Player must equip or melt the current bench item first.

**Why:** One-way flow keeps the model simple. Stash is a holding buffer, not a sorting area.

### D-03: Overflow silently discarded
When all 3 stash slots for a type are full and another item of that type drops, the new item is silently discarded. No toast, no notification.

**Why:** Toasts during combat are noisy. Smart discard (keep higher tier) is deferred as a future prestige bonus alongside item filters.

### D-04: Melt and equip unchanged
Melt destroys the bench item. Equip moves bench item to hero equipment. Both leave the bench empty. Same behavior as today, just operating on a single universal bench instead of per-type benches.

### D-05: Fresh game creates empty stash
`initialize_fresh_game()` creates empty stash arrays (3 empty slots per type) and no starter weapon. Phase 56 will handle placing starter items in the stash.

**Why:** Starter kit logic belongs to Phase 56 (Difficulty & Starter Kit). Phase 55 just provides the data structure.

### D-06: Prestige wipes stash and bench
Prestige click clears all stash arrays and the crafting bench before hero selection overlay appears. Consistent with existing full-wipe design.

### D-07: 3 stash slots per equipment type
15 total slots (3 per each of weapon, helmet, armor, boots, ring). No change from roadmap spec.

## Code Context

### Files to modify
- `autoloads/game_state.gd` — Replace `crafting_inventory` dict with `stash` dict (3-slot arrays) and single `crafting_bench` item; remove `crafting_bench_type`
- `scenes/forge_view.gd` — Update `add_item_to_inventory()` to route to stash; remove per-type bench switching; update display for single bench
- `scenes/gameplay_view.gd` — Drop signal chain unchanged (still emits `item_base_found`)
- `autoloads/game_events.gd` — May need `stash_updated` signal for UI reactivity
- `autoloads/save_manager.gd` — Stash persistence deferred to Phase 58 (save v9)
- `scenes/prestige_view.gd` or `autoloads/prestige_manager.gd` — Add stash/bench wipe to prestige execution

### Existing patterns to follow
- `crafting_inventory` dict structure → model `stash` dict the same way (keyed by slot string)
- `ForgeView._show_forge_error()` tween toast → reusable if feedback needed later
- `PrestigeManager.execute_prestige()` wipe sequence → add stash/bench clearing

### Integration points
- `MainView` connects `gameplay_view.item_base_found` to `forge_view.set_new_item_base()` — this routing changes to target stash instead
- `CombatEngine` currency drops go directly to `GameState.currency_counts` — item drops should follow similar pattern (directly to `GameState.stash`)

## Deferred Ideas

- **Smart discard policy** (keep higher tier on overflow) — future prestige unlock
- **Item drop filters** (auto-discard unwanted loot) — future prestige feature

## Out of Scope

- Stash UI display (Phase 57)
- Tap-to-bench interaction (Phase 57)
- Item detail hover/long-press (Phase 57)
- Save format v9 persistence (Phase 58)
- Starter items in stash (Phase 56)
- Alteration/Regal hammers (Phase 58)

---
*Context created: 2026-03-28*
