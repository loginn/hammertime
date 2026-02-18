# Feature Research

**Domain:** Idle ARPG Per-Slot Inventory System — Hammertime v1.5
**Researched:** 2026-02-18
**Confidence:** HIGH (codebase analysis confirmed; idle ARPG conventions verified via NGU Idle, Melvor Idle, Lootlands, AFK Arena/Journey pattern analysis; WebSearch MEDIUM for genre conventions)

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist in any ARPG idle game with persistent loot. Missing these = system feels incomplete or hostile.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Multiple items per slot (queue/stash per gear type) | Players find 2-3 items per area clear; a single-item bench means every drop immediately tramples the crafting project in progress — this reads as broken, not a design choice | MEDIUM | Replace `crafting_inventory: Dictionary` (single item per key) with `Array[Item]` per key (max 10); GameState and SaveManager both need updates |
| Item count display per slot (x/10 counter) | The x/10 counter is the primary feedback that the slot is finite — without it, players don't know if overflow is silently discarding items | LOW | Already specified in milestone context; one label per item type button in ForgeView |
| Crafting bench shows best/highest-tier item | Players use the bench to craft the best candidate for equipping; showing a random or oldest item wastes time and causes confusion | MEDIUM | `get_bench_item(slot)` returns the highest-tier item from the Array using existing `is_item_better()` comparison logic |
| Drops go directly to slot inventory | Every idle ARPG routes loot directly to stash — players expect zero friction between area clear and having items available to inspect | LOW | `add_item_to_inventory()` already routes drops; logic changes from replace-if-better to append-if-capacity |
| Overflow silently discards (not blocks combat) | Idle game convention: full stash silently ignores new drops rather than pausing combat or showing a blocking dialog — NGU Idle, Melvor Idle both use this pattern | LOW | At capacity (10/10), `add_item_to_inventory()` early-returns without error; no player-facing message needed beyond counter staying at 10 |
| Melt removes bench item from inventory | Players expect Melt to destroy the item on the bench and update the counter — if melt didn't remove it from inventory, the slot would appear full without the item visible | LOW | `_on_melt_pressed()` removes the returned item from its slot Array instead of setting a single key to null |
| Equip removes bench item from inventory | Players expect equipping to consume the item from the crafting queue — leaving it in the Array after equip would create phantom items | LOW | `_on_equip_pressed()` removes the equipped item from its slot Array; old equipped item is deleted as before |
| Save/load preserves full slot inventories | Players closing the game expect their full crafting queue to survive — saving only the bench item (one per slot) would feel like data loss | MEDIUM | SaveManager `_build_save_data()` must serialize Array per slot; `_restore_state()` must rebuild Arrays; save version bump required |

### Differentiators (Competitive Advantage)

Features not mandatory for idle ARPG genre conventions but meaningful for Hammertime's crafting identity.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| "Highest tier on bench" as the default view | Showing the best candidate automatically reduces decision fatigue — players can immediately evaluate whether to craft or equip without scrolling | MEDIUM | Requires `get_bench_item()` using tier-comparison; ties broken by rarity (Rare > Magic > Normal) then DPS for weapons/rings |
| Per-slot counter as crafting progress feedback | The x/10 counter communicates how productive the farming session was without requiring a separate loot log screen — "weapon 7/10" tells a clear story | LOW | Already in milestone spec; label updates on every `add_item_to_inventory()` and every melt/equip |
| Silent overflow (zero friction) | Blocking popups or sound-on-overflow would interrupt idle flow — NGU Idle's "full = silently discard" is the right pattern for an idle game; players check occasionally, not constantly | LOW | The behavior itself; no additional UI needed |
| Overflow feedback on return (counter at cap) | Players returning after idle time can glance at 10/10 counters and understand the slot filled — this is richer feedback than a single item showing "best found" | LOW | The counter at 10/10 is the feedback; no additional system needed |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Return old equipped item to inventory on equip | Players from full ARPGs (Diablo, PoE) expect swapping gear to return the old piece | Breaks the defined equip contract ("old item DELETED") and would fill slots with used gear — the crafting loop is find-craft-equip, not manage-swap-hoard | Delete old equipped item on equip; this is already the existing behavior and must stay |
| Let players scroll/navigate all 10 items per slot in the bench UI | Seems natural if you have 10 items | Creates a browsing UI that fights the idle game identity — the game finds loot, shows you the best candidate, you craft or equip | Always show highest-tier item only; let players melt unwanted items one at a time via the bench |
| Per-item drop notification ("Helmet dropped!") | Common in mobile ARPGs | Notification spam for an idle game that may drop 30 items across a session; high-signal items (rares) already stand out via counter going up | Counter update is sufficient feedback; no per-drop toast needed |
| Loot filter (hide item types you don't want) | Power feature in NGU Idle and Path of Exile | Adds significant configuration surface to a small indie game with 5 item types and a 10-item cap; cap is the natural filter | 10-item cap with silent discard is the filter; complexity is not warranted until item type variety expands significantly |
| Manual item selection from the bench (pick which of the 10 to show) | Gives players full control | Adds UI browsing mode that makes the bench a mini-inventory manager — contradicts the "view into inventory, not removal" contract | Surface only the best item; all 10 remain in storage for the crafting queue until melted |
| Overflow notification popup or sound | Players want to know the slot is full | Blocking or intrusive feedback interrupts idle loop — players check the counter on return; a popup during auto-clear would be disruptive | x/10 counter turning 10/10 is the passive signal |
| Auto-equip best item when slot fills | Players want zero friction | Removes the crafting decision entirely; the loop is find → craft → equip, and auto-equipping bypasses the craft step | Keep the equip button explicit; auto-equip removes player agency over crafting |
| Melt-all or bulk melt | Inventory management convenience | With 10 items max per slot, manual melt is trivial; bulk-melt removes player attention from individual items they might want to craft | One-at-a-time melt via bench is sufficient at this scale |

---

## Feature Dependencies

```
[1] Per-Slot Array Storage (GameState: crafting_inventory[type] = Array[Item])
    └──required-by──> [2] Add to Inventory Logic (append vs. replace)
    └──required-by──> [3] Get Bench Item (highest-tier selector)
    └──required-by──> [4] Melt/Equip Removal (remove-from-array vs. null-assign)
    └──required-by──> [5] x/10 Counter Display
    └──required-by──> [6] Save/Load Array Serialization

[2] Add to Inventory Logic (append if capacity, discard if full)
    └──required-by──> [5] x/10 Counter Display (counter updates on add)
    └──requires──> [1] Per-Slot Array Storage

[3] Get Bench Item / Highest-Tier Selector
    └──required-by──> [ForgeView current_item] (bench always shows best)
    └──required-by──> [7] Stat Comparison (compare equipped vs. bench item)
    └──requires──> [1] Per-Slot Array Storage
    └──uses-existing──> is_item_better() (already implemented in ForgeView)

[4] Melt/Equip Removal
    └──required-by──> [5] x/10 Counter Display (counter decrements on melt/equip)
    └──requires──> [3] Get Bench Item (know which item to remove)
    └──requires──> [1] Per-Slot Array Storage

[5] x/10 Counter Display (per item-type button label)
    └──requires──> [1] Per-Slot Array Storage (Array.size() for count)
    └──updates-on──> [2] Add, [4] Melt/Equip

[6] Save/Load Array Serialization
    └──requires──> [1] Per-Slot Array Storage
    └──integrates-with──> SaveManager._build_save_data() / _restore_state()
    └──requires──> Save version bump (SAVE_VERSION += 1)

[7] Stat Comparison (existing: hover equip button shows delta)
    └──requires──> [3] Get Bench Item (must compare the bench item, which is now "best of slot")
    └──uses-existing──> get_stat_comparison_text() in ForgeView (unchanged logic)
```

### Dependency Notes

- **Per-slot Array storage blocks everything:** The GameState data model is the root change. Until `crafting_inventory[type]` holds an Array instead of a single Item reference, no other feature can be built. This must be Phase 1.
- **`is_item_better()` is already correct:** The existing comparison function works for selecting the highest-tier bench item from the Array. No changes needed to comparison logic.
- **Save/load is high-risk:** The serialization format for `crafting_inventory` changes from `{type: item_dict}` to `{type: [item_dict, ...]}`. The save version must be bumped and the migration path defined (old single-item save loads as a single-element Array).
- **`current_item` in ForgeView becomes computed, not stored:** Currently `current_item` is set directly. With the Array model, `current_item` becomes the result of calling `get_bench_item(selected_type)` — recalculated after every add/melt/equip. This prevents stale references.
- **Equip and Melt share removal logic:** Both need to remove a specific item from its slot Array. A shared `remove_from_slot(item, slot_type)` helper in GameState or ForgeView prevents duplication.

---

## MVP Definition

### Launch With (v1.5 milestone)

Minimum to replace single-item bench with per-slot 10-item inventory.

- [ ] **GameState: Array per slot** — `crafting_inventory[type]` becomes `Array[Item]` with max size 10; all existing code that reads/writes this key updated
- [ ] **Add to inventory appends, not replaces** — `add_item_to_inventory()` appends when `size < 10`, silently returns when full; the is-item-better check is removed (keep everything up to cap)
- [ ] **Get bench item = highest tier** — `get_bench_item(slot_type)` iterates the Array and returns the item with the best `is_item_better()` ranking; used everywhere `current_item` is set
- [ ] **Melt removes from Array** — `_on_melt_pressed()` removes the bench item from its slot Array via `erase()` or index removal
- [ ] **Equip removes from Array** — `_on_equip_pressed()` removes the equipped item from its slot Array after equipping to hero
- [ ] **x/10 counter per slot button** — Each of the 5 item type buttons shows "WEAPON 7/10" label; updates on every add/melt/equip
- [ ] **Save/load Array serialization** — `_build_save_data()` serializes Arrays; `_restore_state()` rebuilds Arrays; SAVE_VERSION bumped; migration from v1 (single item per slot) handled gracefully
- [ ] **Bench type button disabled when slot empty** — If slot Array is empty, item type button is disabled (already existing behavior; must work with Array emptiness check)

### Add After Validation (v1.x)

- [ ] **x/10 visual urgency at cap** — Color or style change when counter reaches 10/10 to signal "slot is full, items being discarded" — useful once players learn the system
- [ ] **Drop notification on full slot (opt-in)** — Small non-blocking indicator when a drop is discarded due to full capacity; only if playtesting reveals players miss this

### Future Consideration (v2+)

- [ ] **Slot capacity upgrade** — Expand beyond 10 via progression unlock; only relevant if item variety grows significantly
- [ ] **Loot filter** — Filter which item types drop; only relevant if item type count grows beyond current 5 or players have builds that ignore certain slots
- [ ] **Item browsing in bench** — Ability to view all items in a slot, not just the best; only if crafting complexity grows such that the best-first heuristic fails players regularly

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| GameState Array per slot | HIGH | MEDIUM | P1 |
| Add to inventory (append, discard on full) | HIGH | LOW | P1 |
| Get bench item (highest tier) | HIGH | LOW | P1 |
| Melt removes from Array | HIGH | LOW | P1 |
| Equip removes from Array | HIGH | LOW | P1 |
| x/10 counter per slot | HIGH | LOW | P1 |
| Save/load Array serialization | HIGH | MEDIUM | P1 |
| Bench type button disabled when empty | MEDIUM | LOW | P1 |
| x/10 visual urgency at cap | LOW | LOW | P2 |
| Drop notification on full slot | LOW | LOW | P2 |
| Slot capacity upgrade | LOW | MEDIUM | P3 |
| Loot filter | LOW | HIGH | P3 |
| Item browsing in bench | LOW | HIGH | P3 |

**Priority key:**
- P1: Required for v1.5 milestone — the feature is the milestone
- P2: Polish after core inventory works; add if playtesting reveals friction
- P3: Deferred; needs design justification to add

---

## Idle ARPG Convention Reference

Sourced from NGU Idle, Melvor Idle, Lootlands, AFK Arena, and AFK Journey to establish what "correct" looks like for this genre specifically.

### (1) Overflow Handling: Silent Discard is Standard

NGU Idle (2018, established idle ARPG): "If your inventory is full, any items that drop are immediately discarded." No blocking dialog, no sound, no toast. Players are expected to manage their stash before it caps.

Melvor Idle: Inventory discussions on Steam reveal player frustration with managed bank slots — the cap itself is the signal, not a per-overflow notification. "If you rarely use items, remove them" is the player-facing advice.

**Application to Hammertime:** Silent discard at 10/10 is correct for the idle genre. The x/10 counter turning 10/10 is sufficient feedback. A popup or toast on discard would be an anti-pattern that interrupts the idle loop.

### (2) Stash Organization: Per-Type, Not Grid

AFK Arena used per-character item inventories (individual 6-slot inventories per character). AFK Journey simplified to per-archetype organization. Neither uses a free-form grid for an idle context — grid management adds the exact overhead idle games are designed to eliminate.

Hammertime's per-slot Array (weapon/helmet/armor/boots/ring) maps directly to the per-archetype pattern AFK Journey converged on. This is correct for the genre.

### (3) Crafting Bench: Show Best, Not a Browser

The primary pain point across ARPGs at crafting stations (documented in ESO and PoE player feedback) is **needing to leave the crafting interface to check your equipped items**. Hammertime already solves this with the stat comparison on equip hover. The "show best item on bench" pattern extends this philosophy: the bench pre-selects the most relevant item so players can make one decision (craft or equip) rather than browsing.

### (4) Item Comparison is the Critical UX

The existing `get_stat_comparison_text()` in ForgeView already implements the core comparison pattern. With the per-slot inventory, the bench item changes to "highest-tier in slot" — the comparison logic remains unchanged. This is the right coupling point: the data model changes, the UX logic stays.

### (5) Equip Destroys Old Item — Correct for Idle

In full ARPGs (Diablo, PoE), equipping returns the old item to inventory. In idle ARPGs with constrained stash space, this creates automatic overflow and management overhead. AFK Journey eliminated gear-swapping overhead by moving to class-based gear abstraction. Hammertime's "equip destroys old item" contract is the correct idle-genre choice — it keeps the loop clean and the stash bounded.

---

## Integration Points with Existing System

| Existing Component | Current State | Required Change | Complexity |
|-------------------|---------------|-----------------|------------|
| `GameState.crafting_inventory` | `{type: Item or null}` | `{type: Array[Item]}` — empty Array replaces null | MEDIUM |
| `ForgeView.add_item_to_inventory()` | Replaces if `is_item_better()` | Appends if `size() < 10`, else silently returns | LOW |
| `ForgeView.get_bench_item()` (new) | Does not exist | Iterates slot Array, returns best by `is_item_better()` | LOW |
| `ForgeView.current_item` (usage) | Set directly by type selection | Computed from `get_bench_item(selected_type)` on every update | LOW |
| `ForgeView._on_melt_pressed()` | Sets `crafting_inventory[slot] = null` | Removes bench item from Array via erase/index | LOW |
| `ForgeView._on_equip_pressed()` | Sets `crafting_inventory[slot] = null` after equip | Removes equipped item from Array | LOW |
| `ForgeView.update_inventory_display()` | Shows type name + single item name | Shows type name + x/10 counter | LOW |
| `ForgeView.update_item_type_button_states()` | Checks `crafting_inventory[type] != null` | Checks `crafting_inventory[type].size() > 0` | LOW |
| `SaveManager._build_save_data()` | Single item dict per slot | Array of item dicts per slot | MEDIUM |
| `SaveManager._restore_state()` | Restores single item per slot | Restores Array per slot; v1 migration wraps single item in Array | MEDIUM |
| `SaveManager.SAVE_VERSION` | `1` | Increment to `2`; migration v1→v2 defined | LOW |
| `GameState.initialize_fresh_game()` | `crafting_inventory = {type: null}` | `crafting_inventory = {type: []}` | LOW |

---

## Sources

**NGU Idle (MEDIUM confidence — community wiki and player guides):**
- [NGU Idle Inventory Wiki](https://ngu-idle.fandom.com/wiki/Inventory) — Auto-discard when full confirmed; Loot Filters as post-launch addition
- [NGU Idle Inventory Management Guide (2025)](https://tap-guides.com/2025/10/24/ngu-idle-inventory-management-guide/) — "If inventory is full you won't get any new drops"; filter pattern documented

**Melvor Idle (MEDIUM confidence — Steam community discussions):**
- [Melvor Idle Inventory Management](https://tap-guides.com/2025/10/24/melvor-idle-inventory-bank-management-tips/) — Bank slot management patterns; cap-as-signal behavior documented
- [Melvor Idle General Discussions](https://steamcommunity.com/app/1267910/discussions/0/3828665107790112513/) — Player frustration with managed bank slots; confirms cap behavior

**Lootlands: Idle ARPG (MEDIUM confidence — Steam store page):**
- [Lootlands on Steam](https://store.steampowered.com/app/3397910/Lootlands_Idle_ARPG/) — "Storage, shops, and itemization decide how sticky an ARPG feels after the first hour"; shared stash design noted

**AFK Arena / AFK Journey (MEDIUM confidence — game analysis article):**
- [Evolution of Idle RPG Systems](https://www.pocketgamer.biz/game-analysis-the-evolution-of-idle-rpg-systems/) — Per-character inventory overhead documented as friction source; AFK Journey's simplification to archetype-based gear as industry response

**Path of Exile / ARPG Crafting Bench UX (MEDIUM confidence — player forums):**
- [ESO Crafting Bench Comparison Thread](https://forums.elderscrollsonline.com/en/discussion/68072/compare-item-to-be-crafted-with-currently-equipped) — "Can't see equipped items at crafting station" documented as widespread UX pain; Hammertime's stat comparison hover already addresses this

**Codebase analysis (HIGH confidence — direct code review):**
- `game_state.gd` — `crafting_inventory: Dictionary = {}` with `{type: null}` per slot; single-item model confirmed
- `forge_view.gd` — `add_item_to_inventory()`, `_on_melt_pressed()`, `_on_equip_pressed()` all operate on single item per slot; `is_item_better()` comparison logic reusable for best-item selection
- `save_manager.gd` — `SAVE_VERSION = 1`; `crafting_inventory` serialized as `{type: item_dict}` — confirms version bump and migration scope

---

*Feature research for: Hammertime v1.5 Per-Slot Inventory System*
*Researched: 2026-02-18*
*Confidence: HIGH (codebase confirmed; MEDIUM for idle ARPG genre conventions from WebSearch)*
