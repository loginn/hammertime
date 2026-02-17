# Phase 16: Drop System Split - Research

**Researched:** 2026-02-17
**Domain:** Loot system refactoring (GDScript/Godot 4.5)
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Packs are the **sole source** of currency — existing area-clear currency drops are removed entirely
- Currency types are **weighted by area level** — higher areas drop higher-tier currencies more often
- **Area gating applies to drops** — currencies only drop from packs if the area meets the currency's minimum area requirement (Phase 11 gates)
- Quantity per pack is **chance-based (0-2)** — each pack has a chance to drop 0, 1, or 2 currencies, adding variance
- **Higher area packs drop more currency** — currency drop rates scale with area level to incentivize pushing
- **Harder packs drop more** — pack difficulty (HP/damage) influences drop rates, not elemental type (elemental packs are not inherently harder)
- Map completion awards **1-3 items** with area-scaled distribution:
  - Area 1: ~99% chance for 1 item
  - Area 300: ~60% chance for 2, ~20% for 1, ~20% for 3
  - Smooth scaling between anchors
- **Both rarity and item level scale with area** — higher areas give better rarity chances AND higher item levels
- Item generation reuses existing `roll_rarity()` and `spawn_item_with_mods()` — only the quantity curve changes
- Death **restarts the same area** — hero keeps trying the same area level until they clear it
- Death **keeps currency from fully cleared packs** — only packs killed before death count (no partial credit for the pack you died fighting)
- **No additional death penalty** — losing item drops IS the penalty, currency kept is the consolation
- Map **generates new random packs** on retry — every run feels different
- **No bonus for full clears** beyond item drops — items are the reward, currency farming is the consolation

### Claude's Discretion
- Exact currency quantity distribution curves per area level
- How to adapt `roll_currency_drops()` for per-pack triggering vs the current per-clear bulk roll
- Pack difficulty classification for drop rate bonuses
- Transition of existing loot_table.gd — what stays, what gets removed, what gets refactored

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

## Summary

Phase 16 splits the existing unified drop system (where both items and currency drop on area clear) into two distinct reward streams: packs drop currency on kill, and map completion drops items. The death penalty preserves currency earned but forfeits item drops.

The existing `LootTable` class already has well-structured `roll_currency_drops()` and `get_item_drop_count()` methods. The core refactoring involves: (1) adapting `roll_currency_drops()` from a per-area-clear bulk roll to a per-pack-kill roll with scaled-down quantities, (2) replacing `get_item_drop_count()` with a new 1-3 area-scaled distribution, (3) moving drop triggering from `gameplay_view._on_map_completed()` into `CombatEngine._on_pack_killed()` and `_on_map_completed()`, and (4) adding a `run_currency_earned` accumulator that persists through death.

**Primary recommendation:** Keep LootTable as the static utility for all drop math. Add `roll_pack_currency_drop()` and `get_map_item_count()` as new static methods. Wire CombatEngine to call them at the right lifecycle points. Track currency accumulation on the engine so the UI (Phase 17) can observe it.

## Architecture Patterns

### Current Drop Flow (to be replaced)

```
gameplay_view._on_map_completed(level)
  → LootTable.get_item_drop_count(level)      # 1-4.5 items per clear
  → LootTable.roll_currency_drops(level)       # Bulk currency roll
  → GameState.add_currencies(drops)            # Direct inventory add
  → signals: item_base_found, currencies_found # UI updates
```

### Target Drop Flow (Phase 16)

```
CombatEngine._on_pack_killed()
  → LootTable.roll_pack_currency_drop(area_level, pack)  # Per-pack roll (0-2)
  → GameState.add_currencies(drops)                       # Immediate add
  → GameEvents.currency_dropped.emit(drops)               # New signal
  → run_currency_earned += sum(drops)                      # Track for display

CombatEngine._on_map_completed()
  → LootTable.get_map_item_count(area_level)   # 1-3 items
  → LootTable.roll_rarity(area_level)          # Existing method
  → GameEvents.items_dropped.emit(items)       # New signal
  → gameplay_view creates items                 # Via signal handler

CombatEngine._on_hero_died()
  → Currency already in inventory (added per-pack) — no clawback
  → No item drops (map not completed)
  → run_currency_earned tracked for UI display (Phase 17)
  → reset run_currency_earned for next attempt
```

### Pattern: Per-Pack Currency Roll

The current `roll_currency_drops()` does a bulk roll designed for one call per area clear (includes logarithmic bonus drops scaling to ~11 extra at area 300 and a runic guarantee). For per-pack context this needs to be decomposed:

**Recommended approach:**
1. New `roll_pack_currency_drop()` — lightweight per-pack roll
2. Base chance per currency stays but scaled down (each pack is 1/8-1/15 of a map)
3. Remove the `bonus_drops` logarithmic bulk distribution — replace with area-level scaling on per-pack chance
4. Remove the "guarantee at least 1 runic" safety net from per-pack (not every pack should guarantee currency)
5. Keep the area gating logic (`CURRENCY_AREA_GATES`) and ramp mechanic (`_calculate_currency_chance`)

**Per-pack chance formula (recommended):**
```gdscript
# Base chances scaled for per-pack (vs current per-clear):
# Pack sees ~1/12 of the map (avg 12 packs), but with area scaling
# Area scaling: multiply base chance by (1 + log(area_level) * 0.15)
var area_multiplier := 1.0 + log(float(area_level)) * 0.15 if area_level > 1 else 1.0

var pack_currency_rules := {
    "runic":  {"chance": 0.15, "max_qty": 2},
    "tack":   {"chance": 0.10, "max_qty": 2},
    "forge":  {"chance": 0.05, "max_qty": 1},
    "grand":  {"chance": 0.03, "max_qty": 1},
    "claw":   {"chance": 0.04, "max_qty": 1},
    "tuning": {"chance": 0.04, "max_qty": 1},
}
```

### Pattern: Pack Difficulty Bonus

Context says harder packs (higher HP/damage) should drop more. The level multiplier already scales HP/damage, so raw values aren't comparable. Use the pack's MonsterType base stats relative to the biome average:

```gdscript
# Difficulty = pack's base_hp * base_damage relative to biome average
# Simple: use pack's max_hp relative to average pack max_hp in the run
# This requires knowing other packs — or simpler: use MonsterType base stats

# Recommended: classify by HP tier
# - Below average base_hp: normal (1.0x drop chance)
# - Above average base_hp: elite (1.5x drop chance)
```

However, MonsterPack currently doesn't store its MonsterType reference. Two options:
1. Add a `difficulty_bonus: float` field to MonsterPack, set by PackGenerator during creation
2. Pass MonsterType to the drop function

Option 1 is cleaner — the pack carries its own drop modifier.

### Pattern: Map Item Count (1-3 Distribution)

Replace `get_item_drop_count()` (which returns 1-4.5) with anchored distribution:

```gdscript
# Anchors from CONTEXT.md:
# Area 1:   99% for 1, ~1% for 2, ~0% for 3
# Area 300: 20% for 1, 60% for 2, 20% for 3
# Interpolate linearly or with log curve between anchors

static func get_map_item_count(area_level: int) -> int:
    # Log progress: 0 at area 1, ~1 at area 300
    var progress := log(1.0 + float(area_level) / 50.0) / log(1.0 + 300.0 / 50.0)
    progress = clampf(progress, 0.0, 1.0)

    # Interpolate anchor weights
    var w1 := lerpf(0.99, 0.20, progress)  # chance for 1 item
    var w2 := lerpf(0.01, 0.60, progress)  # chance for 2 items
    var w3 := lerpf(0.00, 0.20, progress)  # chance for 3 items

    var roll := randf()
    if roll < w1:
        return 1
    elif roll < w1 + w2:
        return 2
    else:
        return 3
```

### Pattern: Currency Accumulation Tracking

CombatEngine needs to track currency earned in the current run so the UI (Phase 17) can display it. This is display data, not game state — the actual currency is already added to `GameState.currency_counts` immediately on pack kill.

```gdscript
# In CombatEngine:
var run_currency_earned: Dictionary = {}  # {"runic": 5, "tack": 2, ...}

# Reset on start_combat()
# Accumulate on _on_pack_killed()
# Persist through death (for display), reset on next start_combat()
# Emit via signal for Phase 17 UI
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Currency gating by area | New gate logic | Existing `CURRENCY_AREA_GATES` + `_calculate_currency_chance()` | Already handles unlock + ramp |
| Item rarity rolling | New rarity system | Existing `roll_rarity()` | Proven logarithmic interpolation |
| Item mod generation | New mod logic | Existing `spawn_item_with_mods()` | Handles magic/rare mod counts |
| Pack stat scaling | New formula | Existing `PackGenerator.get_level_multiplier()` | Compound 6% growth already working |

## Common Pitfalls

### Pitfall 1: Double Currency — Keeping Old + Adding New
**What goes wrong:** Forgetting to remove the existing `roll_currency_drops()` call from `gameplay_view._on_map_completed()`, causing currency to drop both per-pack AND per-map-clear.
**Why it happens:** The old code is clearly marked "temporary" but easy to miss.
**How to avoid:** The plan must explicitly remove lines 100-103 of `gameplay_view.gd` (`var drops := LootTable.roll_currency_drops(...)` and `GameState.add_currencies(drops)`).
**Warning signs:** Currency counts are much higher than expected in testing.

### Pitfall 2: Currency Signals Overload
**What goes wrong:** Emitting a signal for every single pack kill currency drop (8-15 times per map) when the UI isn't ready for that frequency.
**Why it happens:** Phase 17 will add UI handling but it doesn't exist yet.
**How to avoid:** Emit the signal but keep the handler lightweight (Phase 16 just needs the signal defined; Phase 17 wires display). Use `GameEvents` for the signal, not a local signal.
**Warning signs:** Performance issues in gameplay view during combat.

### Pitfall 3: Partial Pack Death Credit
**What goes wrong:** Giving currency for the pack the hero died fighting (which violates "only packs killed before death count").
**Why it happens:** If currency is dropped inside `_on_pack_killed()` and the death check is also there, order of operations matters.
**How to avoid:** In `CombatEngine._on_pack_killed()`, currency drop happens AFTER confirming the pack is dead and BEFORE hero death check. But hero death happens in `_on_pack_attack()` — the current architecture already handles this correctly because `_on_pack_killed()` only fires when `pack.hp <= 0`, and hero death fires when `hero.hp <= 0` from pack attack. These are independent timer-driven events. A pack can't kill the hero and die in the same tick.
**Warning signs:** Currency counts don't match killed pack count.

### Pitfall 4: Removing Too Much from LootTable
**What goes wrong:** Deleting `roll_currency_drops()` entirely instead of keeping it for reference/testing, or removing `get_item_drop_count()` before the replacement is in place.
**Why it happens:** Overzealous cleanup.
**How to avoid:** Deprecate old methods (rename with `_legacy_` prefix or delete only after replacements verified). Better yet: add new methods, wire them, then remove old ones.
**Warning signs:** Drop simulator breaks.

### Pitfall 5: Item Drop Signal Architecture
**What goes wrong:** Trying to create Item instances inside CombatEngine (which is a Node, not the gameplay_view that knows about item types).
**Why it happens:** Natural desire to centralize all drop logic in one place.
**How to avoid:** CombatEngine should emit a signal with the area level and item count; gameplay_view handles actual item creation (it already has `get_random_item_base()`). Keep item creation in gameplay_view.
**Warning signs:** CombatEngine importing item type classes it shouldn't need.

## Code Examples

### Current gameplay_view._on_map_completed (to be refactored)

```gdscript
# Lines 88-105 of scenes/gameplay_view.gd
func _on_map_completed(completed_level: int) -> void:
    GameEvents.area_cleared.emit(completed_level)

    # REMOVE: item drops move to new signal handler
    var item_count := LootTable.get_item_drop_count(completed_level)
    for i in range(item_count):
        var item_base := get_random_item_base(completed_level)
        if item_base != null:
            item_bases_collected.append(item_base)
            item_base_found.emit(item_base)

    # REMOVE: currency drops move to per-pack in CombatEngine
    var drops := LootTable.roll_currency_drops(completed_level)
    GameState.add_currencies(drops)
    currencies_found.emit(drops)
```

### New CombatEngine._on_pack_killed (target)

```gdscript
func _on_pack_killed() -> void:
    var killed_pack := get_current_pack()
    _stop_timers()

    # Currency drops on pack kill (Phase 16)
    var drops := LootTable.roll_pack_currency_drop(area_level, killed_pack)
    if not drops.is_empty():
        GameState.add_currencies(drops)
        _accumulate_run_currency(drops)
        GameEvents.currency_dropped.emit(drops)

    current_pack_index += 1
    GameEvents.pack_killed.emit(current_pack_index, current_packs.size())
    # ... rest of existing logic
```

### New CombatEngine._on_map_completed (target)

```gdscript
func _on_map_completed() -> void:
    state = State.MAP_COMPLETE
    GameState.hero.current_energy_shield = float(GameState.hero.total_energy_shield)

    # Item drops on map completion (Phase 16)
    var item_count := LootTable.get_map_item_count(area_level)
    GameEvents.items_dropped.emit(area_level, item_count)

    area_level += 1
    max_unlocked_level = maxi(max_unlocked_level, area_level)
    GameEvents.map_completed.emit(area_level - 1)
    start_combat(area_level)
```

### New signals needed in GameEvents

```gdscript
# Add to autoloads/game_events.gd:
signal currency_dropped(drops: Dictionary)  # Per-pack currency drops
signal items_dropped(area_level: int, item_count: int)  # Map completion items
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Area-clear bulk drops (both items + currency) | Per-pack currency + map-complete items | Phase 16 | Distinct reward loops, death penalty |
| `get_item_drop_count()` (1-4.5) | `get_map_item_count()` (1-3) | Phase 16 | Lower count but guaranteed on clear |
| `roll_currency_drops()` per clear | `roll_pack_currency_drop()` per pack | Phase 16 | Granular, immediate feedback |

## Open Questions

1. **Drop simulator (`tools/drop_simulator.gd`) update**
   - What we know: A drop simulator exists that likely calls `roll_currency_drops()` and `get_item_drop_count()`
   - What's unclear: Whether it needs updating in this phase or can wait
   - Recommendation: Update it if it references changed methods, but don't add new simulation features (Phase 17+ scope)

2. **`area_cleared` signal fate**
   - What we know: `gameplay_view._on_map_completed()` emits `GameEvents.area_cleared` which other systems may depend on
   - What's unclear: Whether removing it breaks anything
   - Recommendation: Keep `area_cleared` signal emission — it may be used by systems we haven't traced. Move it to CombatEngine alongside `map_completed`.

## Sources

### Primary (HIGH confidence)
- Direct codebase inspection: `models/loot/loot_table.gd`, `models/combat/combat_engine.gd`, `scenes/gameplay_view.gd`, `autoloads/game_state.gd`, `autoloads/game_events.gd`
- Phase 16 CONTEXT.md decisions (user-locked)
- ROADMAP.md Phase 16 success criteria

## Metadata

**Confidence breakdown:**
- Architecture: HIGH — all affected code inspected, clear refactoring path
- Drop formulas: MEDIUM — per-pack quantity curves are Claude's discretion, need tuning
- Pitfalls: HIGH — identified from direct code inspection of current flow

**Research date:** 2026-02-17
**Valid until:** 2026-03-17 (stable internal architecture, no external dependencies)
