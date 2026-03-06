# Phase 35: Prestige Foundation - Research

**Researched:** 2026-02-20
**Domain:** GDScript autoload architecture, GameState extension, Godot 4.5 signal patterns
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Prestige cost curve:**
- P1 costs 100 Forge Hammers — this is the only real prestige cost for now
- P2–P7 get unreachable stub values in PRESTIGE_COSTS table (e.g., 999999) so they're impossible to hit until costs are tuned
- Costs are paid in standard currencies (not a dedicated prestige currency)
- Each prestige level has its own specific currency subset (P1 = Forge Hammers only; other levels TBD)

**Reset scope boundaries:**
- _wipe_run_state() resets exactly 4 categories: area level, hero equipment, crafting inventory, and standard currencies
- Tag currencies are also wiped on prestige (they're a run currency, not a meta currency)
- prestige_level and max_item_tier_unlocked survive resets
- After wipe, player gets the default starting state (same as a fresh game) plus 1 random tag-targeted hammer added as a currency count
- No extra Forge Hammers or gear beyond the default start

**Tag currency drop model:**
- All 5 tag types (fire, cold, lightning, defense, physical) available from P1
- Random chance per pack (not guaranteed) — rarer than Forge Hammer drops since tag hammers are a better currency
- Variable quantity: 1–3 per drop when it occurs
- Uniform random tag type selection (no area weighting)
- Drop chance scales with area level — higher areas have better tag currency drop rates
- tag_currency_dropped signal fires once per pack with bundled Dictionary (e.g., {fire: 2, cold: 1})
- Data model should support gating future currency types behind different prestige levels (even though all 5 tag currencies unlock at P1 for now)

### Claude's Discretion

- Exact placeholder values for P2–P7 costs
- Base drop chance percentage and area scaling formula for tag currencies
- Default starting state composition (whatever a fresh game currently provides)
- Internal structure of PRESTIGE_COSTS table and ITEM_TIERS_BY_PRESTIGE array

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PRES-01 | Player can prestige by spending required currency amounts (scaling per prestige level) | execute_prestige() validates PRESTIGE_COSTS[prestige_level + 1], spends currencies, increments prestige_level |
| PRES-02 | Prestige triggers full reset of area level, hero equipment, crafting inventory, and standard currencies | _wipe_run_state() clears all 4 categories; implementation mirrors initialize_fresh_game() but leaves prestige fields |
| PRES-03 | Prestige level and item tier unlocks persist across resets | prestige_level and max_item_tier_unlocked are NOT touched by _wipe_run_state(); they persist through save (Phase 36 handles actual save) |
| PRES-05 | Game supports 7 total prestige levels (P1 through P7) | MAX_PRESTIGE_LEVEL = 7 constant in PrestigeManager; PRESTIGE_COSTS indexed 1–7 |
| PRES-06 | Each prestige level unlocks the next better item tier (P1→tier 7, P2→tier 6, ..., P7→tier 1) | ITEM_TIERS_BY_PRESTIGE array maps prestige level to max_item_tier_unlocked; execute_prestige() updates this field |
</phase_requirements>

## Summary

Phase 35 is a pure data-model and autoload-creation phase. No UI is built here. The work divides into three parts: (1) create a new `PrestigeManager` autoload with constants and `execute_prestige()` logic, (2) add three new fields to `GameState` (`prestige_level`, `max_item_tier_unlocked`, `tag_currency_counts`), and (3) add two new signals to `GameEvents`.

The existing codebase establishes clear patterns to follow. `GameState` is the canonical home for mutable game data; `PrestigeManager` will follow the same `extends Node` autoload pattern as `SaveManager` and `GameEvents`. The `_wipe_run_state()` method must be written to mirror `initialize_fresh_game()` **without** calling it, because `initialize_fresh_game()` resets prestige fields (which don't exist yet, but will after this phase). The STATE.md key constraint is explicit: "never call initialize_fresh_game() from the prestige path."

The tag currency model in this phase is data-model only: `tag_currency_counts` lives as a separate dictionary on `GameState` (not merged into `currency_counts`). The `tag_currency_dropped` signal is declared in `GameEvents` here; actual drop roll integration into `LootTable` happens in Phase 39. Save/load of the new fields happens in Phase 36. This phase must NOT touch `SaveManager`.

**Primary recommendation:** Create `PrestigeManager` in `autoloads/prestige_manager.gd`, add it to project.godot after `GameState`, add three fields to `game_state.gd`, add two signals to `game_events.gd`, then write a targeted test in a scratch script or from the Godot editor to verify `execute_prestige()` from P0 produces `prestige_level == 1` and correct `max_item_tier_unlocked`.

---

## Standard Stack

### Core
| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| GDScript | Godot 4.5 | Implementation language | Project constraint — no alternatives |
| `extends Node` autoload | Godot 4.5 | PrestigeManager lifecycle | Matches GameState, GameEvents, SaveManager pattern |
| Dictionary constants | GDScript | PRESTIGE_COSTS lookup table | Already used for CURRENCY_AREA_GATES, RARITY_LIMITS; matches project idiom |
| Array constants | GDScript | ITEM_TIERS_BY_PRESTIGE | Indexed by prestige level (1–7); maps to tier unlock values |
| `signal` keyword | GDScript | Two new GameEvents signals | Existing pattern for all cross-scene communication |

### Supporting
| Component | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| `project.godot` `[autoload]` section | Godot 4.5 | Register PrestigeManager | Required for global access — same as existing autoloads |
| `call_deferred` / `emit` | GDScript | prestige_completed signal emission | Emit after state is fully updated, same as save_completed pattern |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Separate PrestigeManager autoload | Methods on GameState | GameState is already data-focused; prestige logic (cost validation, wipe, signal) belongs in a dedicated manager to match SaveManager pattern |
| Array for PRESTIGE_COSTS | Dictionary keyed by level | Dictionary is more self-documenting (PRESTIGE_COSTS[1] vs PRESTIGE_COSTS[0]) and allows sparse future entries |

---

## Architecture Patterns

### Recommended Project Structure
```
autoloads/
├── game_events.gd          # Add 2 new signals here
├── game_state.gd           # Add 3 new fields here
├── prestige_manager.gd     # NEW — create here
├── save_manager.gd         # DO NOT TOUCH this phase
└── item_affixes.gd         # DO NOT TOUCH
```

### Pattern 1: Autoload Registration Order
**What:** Godot processes autoloads in order. `PrestigeManager` needs `GameState` and `GameEvents` to exist before it can wire signals or read state.
**When to use:** Always — the existing order in project.godot is: `ItemAffixes, Tag, GameEvents, SaveManager, GameState`. Add `PrestigeManager` AFTER `GameState`.
**Example from project.godot:**
```
[autoload]

ItemAffixes="*res://autoloads/item_affixes.gd"
Tag="*res://autoloads/tag.gd"
GameEvents="*res://autoloads/game_events.gd"
SaveManager="*res://autoloads/save_manager.gd"
GameState="*res://autoloads/game_state.gd"
PrestigeManager="*res://autoloads/prestige_manager.gd"   # <-- ADD HERE
```

### Pattern 2: GameState Field Initialization
**What:** All GameState fields are initialized in `initialize_fresh_game()`, which is called in `_ready()` before `load_game()`. Prestige fields that survive resets must be initialized to their defaults in `initialize_fresh_game()` but must NOT be touched by `_wipe_run_state()`.
**When to use:** Any new data that has a "fresh game" default but may be loaded from save.
**Current initialize_fresh_game() initializes:**
```gdscript
# In game_state.gd initialize_fresh_game():
hero = Hero.new()
hero.equipped_items = { "weapon": null, "helmet": null, "armor": null, "boots": null, "ring": null }
currency_counts = { "runic": 1, "forge": 0, "tack": 0, "grand": 0, "claw": 0, "tuning": 0 }
crafting_inventory = { "weapon": [], "helmet": [], "armor": [], "boots": [], "ring": [] }
crafting_inventory["weapon"] = [LightSword.new()]
crafting_bench_type = "weapon"
max_unlocked_level = 1
area_level = 1
```
**New fields to add in initialize_fresh_game():**
```gdscript
prestige_level = 0
max_item_tier_unlocked = 8  # P0 = base tier 8 (lowest quality ceiling pre-prestige)
tag_currency_counts = {}    # Empty — no tag currencies at fresh start
```

### Pattern 3: _wipe_run_state() — New Method
**What:** Resets exactly the 4 run categories without touching prestige fields. This is a NEW method that does NOT exist yet. It must NOT call `initialize_fresh_game()` (which would zero out prestige_level).
**What gets wiped:**
1. `area_level` → 1, `max_unlocked_level` → 1
2. `hero.equipped_items` → all null
3. `crafting_inventory` → empty arrays per slot, starter weapon added
4. `currency_counts` → reset to fresh-game defaults (runic=1, all others=0)
5. `tag_currency_counts` → reset to `{}` (tag currencies are run currency per user decision)
**What survives:**
- `prestige_level` — untouched
- `max_item_tier_unlocked` — untouched
**Post-wipe:** After the wipe, apply the prestige bonus: pick 1 random tag type and add 1 to `tag_currency_counts[tag]`.
**Implementation:**
```gdscript
## Resets all run-scoped state. Called by PrestigeManager after a prestige.
## Does NOT reset prestige_level or max_item_tier_unlocked.
func _wipe_run_state() -> void:
    # 1. Area progress
    area_level = 1
    max_unlocked_level = 1

    # 2. Hero equipment
    hero = Hero.new()
    hero.equipped_items["weapon"] = null
    hero.equipped_items["helmet"] = null
    hero.equipped_items["armor"] = null
    hero.equipped_items["boots"] = null
    hero.equipped_items["ring"] = null

    # 3. Crafting inventory — fresh state with starter weapon
    crafting_inventory = {
        "weapon": [],
        "helmet": [],
        "armor": [],
        "boots": [],
        "ring": [],
    }
    crafting_inventory["weapon"] = [LightSword.new()]
    crafting_bench_type = "weapon"

    # 4. Standard currencies — reset to fresh-game defaults
    currency_counts = {
        "runic": 1,
        "forge": 0,
        "tack": 0,
        "grand": 0,
        "claw": 0,
        "tuning": 0,
    }

    # 5. Tag currencies — wiped (they are run currency, not meta)
    tag_currency_counts = {}
```

### Pattern 4: PrestigeManager Constants Structure
**What:** The constants table design follows existing project patterns (Dictionary for PRESTIGE_COSTS, Array for ITEM_TIERS_BY_PRESTIGE).
**ITEM_TIERS_BY_PRESTIGE logic:** P1 unlocks tier 7, P2 unlocks tier 6, ..., P7 unlocks tier 1. At P0, the ceiling is tier 8 (the lowest quality). This is an inverted relationship: higher prestige = lower tier NUMBER = better item quality.

```gdscript
# In prestige_manager.gd:
const MAX_PRESTIGE_LEVEL: int = 7

# Key = prestige level (1-7), Value = currency_type -> amount
# P2–P7 use stub values (999999) until costs are tuned
const PRESTIGE_COSTS: Dictionary = {
    1: { "forge": 100 },
    2: { "forge": 999999 },
    3: { "forge": 999999 },
    4: { "forge": 999999 },
    5: { "forge": 999999 },
    6: { "forge": 999999 },
    7: { "forge": 999999 },
}

# Index 0 = P0 baseline (tier 8), Index 1 = P1 unlock (tier 7), ..., Index 7 = P7 unlock (tier 1)
# max_item_tier_unlocked = ITEM_TIERS_BY_PRESTIGE[prestige_level]
const ITEM_TIERS_BY_PRESTIGE: Array[int] = [8, 7, 6, 5, 4, 3, 2, 1]
```

**Note on tier semantics:** `max_item_tier_unlocked` uses the value from `ITEM_TIERS_BY_PRESTIGE[prestige_level]` (lower number = better tier). After P7, max_item_tier_unlocked = 1 (best quality). At P0 (default), it is 8 (only lowest quality available). Phase 38 will use this field for item drop weighting.

### Pattern 5: execute_prestige() Flow
**What:** The full prestige execution sequence.
**Validation before spending:** Check can_prestige() first; cost payment only after confirmed.

```gdscript
## Returns true if the player meets requirements to prestige.
func can_prestige() -> bool:
    if GameState.prestige_level >= MAX_PRESTIGE_LEVEL:
        return false
    var next_level: int = GameState.prestige_level + 1
    var cost: Dictionary = PRESTIGE_COSTS[next_level]
    for currency_type in cost:
        if GameState.currency_counts.get(currency_type, 0) < cost[currency_type]:
            return false
    return true


## Executes a prestige if the player can afford it.
## Returns true on success, false if requirements not met.
func execute_prestige() -> bool:
    if not can_prestige():
        return false

    var next_level: int = GameState.prestige_level + 1
    var cost: Dictionary = PRESTIGE_COSTS[next_level]

    # Spend currencies BEFORE wipe (wipe zeroes standard currencies)
    for currency_type in cost:
        var amount: int = cost[currency_type]
        for i in range(amount):
            GameState.spend_currency(currency_type)

    # Advance prestige level
    GameState.prestige_level = next_level

    # Update item tier ceiling
    GameState.max_item_tier_unlocked = ITEM_TIERS_BY_PRESTIGE[next_level]

    # Wipe run state
    GameState._wipe_run_state()

    # Apply post-wipe prestige bonus: 1 random tag hammer
    _grant_random_tag_currency()

    # Emit signal
    GameEvents.prestige_completed.emit(next_level)

    return true


## Grants 1 unit of a uniformly-random tag currency type.
func _grant_random_tag_currency() -> void:
    var tag_types: Array[String] = ["fire", "cold", "lightning", "defense", "physical"]
    var chosen: String = tag_types.pick_random()
    if chosen not in GameState.tag_currency_counts:
        GameState.tag_currency_counts[chosen] = 0
    GameState.tag_currency_counts[chosen] += 1
```

**Critical ordering:** Currencies must be spent BEFORE the wipe. The wipe resets `currency_counts` to fresh defaults. If the spend happens after the wipe, the player is refunded for free.

### Pattern 6: New GameEvents Signals
**What:** Two new signals added to game_events.gd, following existing signal declaration style.

```gdscript
# In game_events.gd — add to existing signals:
# Prestige system signals (Phase 35)
signal prestige_completed(new_level: int)
signal tag_currency_dropped(drops: Dictionary)
```

**Note:** `tag_currency_dropped` is declared here (Phase 35) but will not be emitted until Phase 39 when `LootTable` is extended. Declaring it now means Phase 39 can emit without modifying `GameEvents`.

### Anti-Patterns to Avoid
- **Calling initialize_fresh_game() from execute_prestige():** This would zero out `prestige_level` immediately after setting it. `_wipe_run_state()` is the correct call site.
- **Merging tag_currency_counts into currency_counts:** STATE.md explicitly says `tag_currency_counts` lives as a separate Dictionary. Mixing them would complicate Phase 36 (save migration) and Phase 39 (drop gating).
- **Adding SAVE_VERSION bump in this phase:** Save format changes belong entirely to Phase 36. This phase must not touch `save_manager.gd`.
- **Putting ITEM_TIERS_BY_PRESTIGE as index 1-based directly:** Array index 0 = P0 makes the index = prestige level, which is simpler than +1/-1 offsets. `ITEM_TIERS_BY_PRESTIGE[prestige_level]` works cleanly for any level 0–7.
- **Spending currency after the wipe:** The wipe zeros `currency_counts`. Spend first, then wipe.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Currency validation | Custom balance check | `GameState.currency_counts.get(type, 0) >= amount` | Already works; `currency_counts` is the source of truth |
| Currency consumption | Manual decrement loop | `GameState.spend_currency(currency_type)` loop | Existing template method enforces validation contract |
| Signal emission | Custom callback system | `GameEvents.prestige_completed.emit(level)` | Existing event bus; all observers connect to GameEvents |
| Random tag selection | Weighted random | `tag_types.pick_random()` (uniform) | User decision: uniform random, no area weighting |

**Key insight:** This phase is wiring together existing primitives (`spend_currency`, `currency_counts`, `GameEvents.emit`). No new infrastructure is needed beyond the new autoload file.

---

## Common Pitfalls

### Pitfall 1: Spending After Wipe
**What goes wrong:** `execute_prestige()` calls `_wipe_run_state()` first, then tries to spend currencies — but `currency_counts` is now zeroed. The cost check passes (since `can_prestige()` was called before wipe), but `spend_currency()` returns false because the currency is already gone.
**Why it happens:** Logical ordering mistake — wipe resets the very currencies being spent.
**How to avoid:** Always spend currencies BEFORE calling `_wipe_run_state()`. Order: validate → spend → update prestige_level → update max_item_tier_unlocked → wipe → grant bonus → emit signal.
**Warning signs:** `execute_prestige()` returns true but `currency_counts["forge"]` is still positive after prestige (spend never happened).

### Pitfall 2: Calling initialize_fresh_game() Instead of _wipe_run_state()
**What goes wrong:** `prestige_level` is reset to 0, `max_item_tier_unlocked` is reset to 8, and the prestige becomes invisible.
**Why it happens:** `initialize_fresh_game()` is the "reset everything" method already in the codebase. It's tempting to reuse it.
**How to avoid:** `_wipe_run_state()` is a new method written specifically to exclude prestige fields. STATE.md documents this constraint explicitly.
**Warning signs:** After `execute_prestige()`, `prestige_level == 0` instead of 1.

### Pitfall 3: Autoload Registration Order
**What goes wrong:** `PrestigeManager._ready()` calls `GameState` or `GameEvents` but those autoloads aren't initialized yet, causing null reference errors on startup.
**Why it happens:** Godot initializes autoloads in project.godot order. If `PrestigeManager` is listed before `GameState`, it runs first.
**How to avoid:** Register `PrestigeManager` AFTER `GameState` in the `[autoload]` section of `project.godot`.
**Warning signs:** Null reference error in `_ready()` referencing `GameState` or `GameEvents`.

### Pitfall 4: tag_currency_counts Merge into currency_counts
**What goes wrong:** Adding tag currency keys to `currency_counts` causes `_wipe_run_state()` to wipe them with standard currencies — which is correct per user decision — but it also causes `add_currencies()` to handle them, muddying the `currency_dropped` signal semantics.
**Why it happens:** `currency_counts` already exists; it's tempting to reuse it for all currency types.
**How to avoid:** Keep `tag_currency_counts` as a separate `Dictionary` on `GameState`. The `tag_currency_dropped` signal carries a separate `drops` dict for this reason.
**Warning signs:** Phase 39 can't distinguish tag vs standard currency in signal handlers.

### Pitfall 5: ITEM_TIERS_BY_PRESTIGE Off-By-One
**What goes wrong:** `ITEM_TIERS_BY_PRESTIGE[prestige_level]` throws index-out-of-bounds if the array is 1-indexed (7 elements for P1–P7) and `prestige_level` is 0 at game start.
**Why it happens:** Starting at index 1 feels natural, but `prestige_level = 0` at P0 tries to access index 0.
**How to avoid:** Use an 8-element array: index 0 = P0 baseline (tier 8), index 1 = P1 (tier 7), ..., index 7 = P7 (tier 1). `ITEM_TIERS_BY_PRESTIGE[prestige_level]` works cleanly for all levels 0–7.

### Pitfall 6: Post-Wipe Bonus Grant Into Wiped Dictionary
**What goes wrong:** `_wipe_run_state()` sets `tag_currency_counts = {}`. If `_grant_random_tag_currency()` is called inside `_wipe_run_state()`, it must happen at the END, after the reset. If called before, it gets wiped.
**Why it happens:** Calling `_grant_random_tag_currency()` inside the wipe method before clearing the dict.
**How to avoid:** Call `_grant_random_tag_currency()` from `execute_prestige()` AFTER `GameState._wipe_run_state()` returns. Keep the grant as a separate step in the prestige sequence.

---

## Code Examples

### PrestigeManager autoload skeleton

```gdscript
# autoloads/prestige_manager.gd
extends Node

const MAX_PRESTIGE_LEVEL: int = 7

# Key = prestige level (1-7), Value = {currency_type: amount}
# P2–P7 use stub values (999999) — unreachable until costs are tuned
const PRESTIGE_COSTS: Dictionary = {
    1: { "forge": 100 },
    2: { "forge": 999999 },
    3: { "forge": 999999 },
    4: { "forge": 999999 },
    5: { "forge": 999999 },
    6: { "forge": 999999 },
    7: { "forge": 999999 },
}

# Index = prestige level (0-7), Value = max_item_tier_unlocked
# P0 baseline: tier 8 (lowest quality ceiling)
# P7 final: tier 1 (best quality ceiling)
const ITEM_TIERS_BY_PRESTIGE: Array[int] = [8, 7, 6, 5, 4, 3, 2, 1]

const TAG_TYPES: Array[String] = ["fire", "cold", "lightning", "defense", "physical"]


## Returns true if player meets all prestige requirements.
func can_prestige() -> bool:
    if GameState.prestige_level >= MAX_PRESTIGE_LEVEL:
        return false
    var next_level: int = GameState.prestige_level + 1
    var cost: Dictionary = PRESTIGE_COSTS[next_level]
    for currency_type in cost:
        if GameState.currency_counts.get(currency_type, 0) < cost[currency_type]:
            return false
    return true


## Returns the cost dictionary for the next prestige, or empty if at max.
func get_next_prestige_cost() -> Dictionary:
    if GameState.prestige_level >= MAX_PRESTIGE_LEVEL:
        return {}
    return PRESTIGE_COSTS[GameState.prestige_level + 1]


## Executes prestige: validates, spends, advances level, wipes run, grants bonus, signals.
## Returns true on success, false if requirements not met.
func execute_prestige() -> bool:
    if not can_prestige():
        return false

    var next_level: int = GameState.prestige_level + 1
    var cost: Dictionary = PRESTIGE_COSTS[next_level]

    # CRITICAL: Spend BEFORE wipe — wipe zeroes currency_counts
    for currency_type in cost:
        var amount: int = cost[currency_type]
        for i in range(amount):
            GameState.spend_currency(currency_type)

    # Advance prestige state (both fields before wipe so they survive)
    GameState.prestige_level = next_level
    GameState.max_item_tier_unlocked = ITEM_TIERS_BY_PRESTIGE[next_level]

    # Wipe all run-scoped state
    GameState._wipe_run_state()

    # Grant post-prestige bonus: 1 random tag hammer
    _grant_random_tag_currency()

    # Notify observers
    GameEvents.prestige_completed.emit(next_level)

    return true


## Grants 1 unit of a uniformly-random tag currency after prestige wipe.
func _grant_random_tag_currency() -> void:
    var chosen: String = TAG_TYPES.pick_random()
    if chosen not in GameState.tag_currency_counts:
        GameState.tag_currency_counts[chosen] = 0
    GameState.tag_currency_counts[chosen] += 1
```

### GameState additions

```gdscript
# In game_state.gd — add these new fields at the top with other vars:

# Prestige state — survives resets (NOT wiped by _wipe_run_state)
var prestige_level: int = 0
var max_item_tier_unlocked: int = 8  # ITEM_TIERS_BY_PRESTIGE[0] = 8 at P0

# Tag currency inventory — separate from standard currency_counts
# Wiped on prestige (run currency), but referenced here for persistence
var tag_currency_counts: Dictionary = {}


# In initialize_fresh_game() — add after existing field initializations:
prestige_level = 0
max_item_tier_unlocked = 8
tag_currency_counts = {}


# Add _wipe_run_state() as a new method on GameState:
## Resets all run-scoped state. Called by PrestigeManager.execute_prestige().
## Does NOT touch prestige_level or max_item_tier_unlocked.
func _wipe_run_state() -> void:
    # Area progress
    area_level = 1
    max_unlocked_level = 1

    # Hero — fresh hero with empty slots
    hero = Hero.new()
    hero.equipped_items["weapon"] = null
    hero.equipped_items["helmet"] = null
    hero.equipped_items["armor"] = null
    hero.equipped_items["boots"] = null
    hero.equipped_items["ring"] = null

    # Crafting inventory — fresh state with starter weapon
    crafting_inventory = {
        "weapon": [],
        "helmet": [],
        "armor": [],
        "boots": [],
        "ring": [],
    }
    crafting_inventory["weapon"] = [LightSword.new()]
    crafting_bench_type = "weapon"

    # Standard currencies — reset to fresh-game defaults
    currency_counts = {
        "runic": 1,
        "forge": 0,
        "tack": 0,
        "grand": 0,
        "claw": 0,
        "tuning": 0,
    }

    # Tag currencies — wiped (they are run currency per user decision)
    tag_currency_counts = {}
```

### GameEvents additions

```gdscript
# In game_events.gd — add after existing signals:

# Prestige system signals (Phase 35)
signal prestige_completed(new_level: int)
signal tag_currency_dropped(drops: Dictionary)
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single initialize_fresh_game() for all resets | Separate _wipe_run_state() for prestige path | Phase 35 (this phase) | Prestige fields survive reset without brittle exclusion logic |
| No prestige state | prestige_level, max_item_tier_unlocked, tag_currency_counts on GameState | Phase 35 | Foundation for all subsequent v1.7 phases |
| Single currency_counts dictionary | currency_counts + separate tag_currency_counts | Phase 35 | Tag currencies are run-scoped but separate from standard currencies |

---

## Open Questions

1. **Should _wipe_run_state() be public or prefixed with underscore?**
   - What we know: GDScript convention uses `_` prefix for methods not intended for external callers. `execute_prestige()` in PrestigeManager calls it on `GameState`.
   - What's unclear: Whether the underscore convention implies "private" in this project (GDScript has no true access modifiers).
   - Recommendation: Keep the `_` prefix (`_wipe_run_state`) consistent with how the method was named in the success criteria and STATE.md. The underscore signals intent; `PrestigeManager` calling it is intentional cross-autoload coordination, same as `SaveManager` calling `GameState` methods.

2. **What hero stats need recalculation after _wipe_run_state()?**
   - What we know: After `initialize_fresh_game()`, hero stats are fresh (no equipment). After `_restore_state()` in SaveManager, `GameState.hero.update_stats()` is called explicitly to recalculate from restored equipment.
   - What's unclear: Whether a fresh `Hero.new()` in `_wipe_run_state()` needs `update_stats()` called explicitly.
   - Recommendation: Call `hero.update_stats()` at the end of `_wipe_run_state()` to match `_restore_state()` pattern. A fresh hero with no equipment has zero affixes; `update_stats()` on an empty hero is safe and ensures derived stats are consistent.

3. **Type annotation for ITEM_TIERS_BY_PRESTIGE: Array[int] or just Array?**
   - What we know: GDScript 4.x supports typed arrays (`Array[int]`). The project uses typed arrays extensively (e.g., `Array[Affix]`, `Array[MonsterPack]`).
   - Recommendation: Use `Array[int]` for consistency with project conventions. Constants can be typed arrays in Godot 4.

---

## Sources

### Primary (HIGH confidence)
- Direct codebase inspection — `autoloads/game_state.gd`, `autoloads/game_events.gd`, `autoloads/save_manager.gd`, `models/loot/loot_table.gd`, `models/combat/combat_engine.gd` — verified patterns for autoload structure, initialize_fresh_game(), signal declarations, dictionary constants
- `.planning/STATE.md` — explicit constraint: "_wipe_run_state() must be separate from initialize_fresh_game() — never call the latter from the prestige path" and "tag_currency_counts lives as a separate dictionary on GameState"
- `.planning/REQUIREMENTS.md` — PRES-01 through PRES-06 definitions and traceability
- `.planning/phases/35-prestige-foundation/35-CONTEXT.md` — locked user decisions on costs, reset scope, tag currency model

### Secondary (MEDIUM confidence)
- `project.godot` autoload section — confirmed registration order pattern; PrestigeManager placement inferred from dependency order

### Tertiary (LOW confidence)
- None — all research conducted against local codebase and planning documents

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Godot 4.5 GDScript autoload pattern verified in 4 existing autoloads
- Architecture: HIGH — _wipe_run_state() structure derived from existing initialize_fresh_game() + explicit STATE.md constraints
- Pitfalls: HIGH — currency-before-wipe ordering derived from reading _wipe_run_state() reset behavior; autoload order from project.godot inspection
- Constants design: HIGH — PRESTIGE_COSTS/ITEM_TIERS_BY_PRESTIGE structure derived from user decisions and tier mapping math

**Research date:** 2026-02-20
**Valid until:** 2026-03-20 (stable — GDScript patterns don't change; valid until next milestone)
