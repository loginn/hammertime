# Phase 15: Pack-Based Combat Loop - Research

**Researched:** 2026-02-16
**Domain:** Godot 4.5 GDScript idle combat engine
**Confidence:** HIGH

## Summary

Phase 15 replaces the current timer-based area clearing in `gameplay_view.gd` with a pack-by-pack combat loop using the MonsterPack data model from Phase 14 and the DefenseCalculator from Phase 13. The hero and packs attack each other on independent timers until one side dies. The existing codebase already has all the primitives needed: `MonsterPack` with HP/damage/attack_speed/element, `DefenseCalculator.calculate_damage_taken()` with the full 4-stage defense pipeline, `Hero.apply_damage()` / `Hero.revive()`, and `PackGenerator.generate_packs()`.

The core challenge is replacing the single `ClearingTimer` approach with a dual-timer (or delta accumulation) combat engine where hero and pack attack independently at different speeds. The context locks independent attack timers, ~0.5s base tick, weapon-based hero attack speed, instant pack transitions, and 33% ES recharge between packs.

**Primary recommendation:** Build a `CombatEngine` (RefCounted or Node) that owns the combat loop state machine and dual attack timers, keeping `gameplay_view.gd` as a thin controller that delegates to it.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Medium tick speed (~0.5s base) -- each hit feels distinct but combat moves quickly
- Independent attack timers for hero and pack -- each operates on their own attack_speed, not a shared tick
- Hero attack speed comes from weapon type (swords faster, hammers slower) -- new stat on weapon bases
- Crit events should be tracked and emitted by the combat engine (even if visual treatment is Phase 17)
- Death resets the current map -- packs re-roll, progress lost
- Currency earned from killed packs is kept through death (Phase 16 implements the actual drop mechanics)
- Items only drop on full map completion, not per-pack (Phase 16 scope but informs combat loop design)
- Hero stays at the same area level after death -- retry until cleared or gear up
- Revival restores full HP and full ES -- clean slate for each map attempt
- Instant transition between packs -- no pause, continuous combat flow
- ES recharges 33% of max between each pack (existing behavior preserved)
- Full ES recharge between maps (after all packs cleared)
- No base HP regen between packs -- life damage is permanent within a map run
- Life regen from gear mods deferred to future phase
- Auto-advance after map completion -- hero immediately starts next map
- Always advance area level on map clear (current_level + 1, not max_unlocked + 1) -- deterministic progression replacing 10% RNG
- Player can choose to run any unlocked area level (engine supports level selection, UI is Phase 17)
- After death: toggle for auto-retry vs pause -- player decides whether to immediately retry or stop
- Packs re-roll fresh on each map attempt (death or new map)
- Biome determined automatically by area level using BiomeConfig level ranges

### Claude's Discretion
- Exact combat tick implementation (Godot Timer vs _process delta accumulation)
- How to structure the CombatManager/combat loop architecture
- Default weapon attack speed values for existing weapon types
- Auto-retry toggle default state (on or off)

### Deferred Ideas (OUT OF SCOPE)
- Life regen gear mods -- future affix/implicit addition
- Area level selection UI -- Phase 17 scope
- Visual crit treatment -- Phase 17 scope
- Drop mechanics (currency on kill, items on clear) -- Phase 16 scope
</user_constraints>

## Standard Stack

### Core
| Library/System | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Godot Timer node | 4.5 | Combat tick timing | Built-in, scene-tree integrated, pause-aware |
| GDScript Resource | 4.5 | Combat state data (MonsterPack, Hero) | Existing pattern throughout codebase |
| GDScript signals | 4.5 | Combat event communication | Existing pattern (GameEvents autoload) |

### Supporting
| System | Version | Purpose | When to Use |
|--------|---------|---------|-------------|
| RefCounted | 4.5 | CombatEngine class (stateless utilities) | If engine doesn't need scene tree |
| Node | 4.5 | CombatEngine class (needs timers as children) | If using Timer children for attack cadence |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Dual Timer nodes | `_process()` delta accumulation | Delta is more flexible but Timer is cleaner for discrete events; Timer recommended since attack events are discrete hits, not continuous |
| CombatEngine as Node | CombatEngine as RefCounted + external timers | Node is simpler when engine owns its own timers as children |

## Architecture Patterns

### Recommended Structure
```
models/combat/
├── combat_engine.gd      # CombatEngine node: state machine + dual timers
scenes/
├── gameplay_view.gd       # Modified: delegates to CombatEngine instead of ClearingTimer
autoloads/
├── game_events.gd         # Extended: new combat signals
```

### Pattern 1: State Machine Combat Loop
**What:** CombatEngine as a Node with an enum-based state machine (IDLE, FIGHTING, PACK_TRANSITION, MAP_COMPLETE, HERO_DEAD) and two child Timer nodes (hero_attack_timer, pack_attack_timer).
**When to use:** Exactly this phase -- manages the combat lifecycle.
**Example:**
```gdscript
class_name CombatEngine extends Node

enum State { IDLE, FIGHTING, PACK_TRANSITION, MAP_COMPLETE, HERO_DEAD }

var state: State = State.IDLE
var current_packs: Array[MonsterPack] = []
var current_pack_index: int = 0
var area_level: int = 1
var auto_retry: bool = true
var max_unlocked_level: int = 1

@onready var hero_attack_timer: Timer = $HeroAttackTimer
@onready var pack_attack_timer: Timer = $PackAttackTimer

signal pack_killed(pack_index: int, total_packs: int)
signal hero_attacked(damage: float, crit: bool)
signal pack_attacked(damage_result: Dictionary)
signal hero_died()
signal map_completed(area_level: int)
signal combat_started(area_level: int, pack_count: int)
```

### Pattern 2: Independent Attack Timers
**What:** Two Timer nodes with different wait_times. Hero timer fires hero_attack(), pack timer fires pack_attack(). Both start simultaneously when combat begins with a pack.
**When to use:** The locked decision requires independent attack cadences.
**Example:**
```gdscript
func start_pack_fight() -> void:
    var pack := get_current_pack()
    hero_attack_timer.wait_time = 1.0 / hero_attack_speed  # e.g., 2.0 speed = 0.5s
    pack_attack_timer.wait_time = 1.0 / pack.attack_speed
    hero_attack_timer.start()
    pack_attack_timer.start()
```

### Pattern 3: Weapon Base Attack Speed
**What:** Add `base_attack_speed: float` to Weapon class. Light swords are fast (~2.0 attacks/sec), hammers are slow (~0.8). Hero's effective attack speed = weapon base_attack_speed (no modifiers this phase).
**When to use:** This phase -- weapon variety affects combat pacing.
**Example:**
```gdscript
# In weapon subclasses:
# LightSword: base_attack_speed = 2.0 (0.5s between hits)
# Hammer-type: base_attack_speed = 0.8 (1.25s between hits)
```

### Anti-Patterns to Avoid
- **Single shared tick:** Don't use one timer for both hero and pack attacks. The context explicitly requires independent timers.
- **_process accumulation for discrete hits:** While technically possible, Timer nodes are cleaner for fire-and-forget attack cadences. _process is better for continuous effects.
- **Combat logic in gameplay_view.gd:** Keep the engine separate. gameplay_view.gd should only connect signals and update display.
- **Modifying MonsterPack or Hero Resource classes heavily:** These are data containers. Combat logic belongs in CombatEngine.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Damage calculation | Custom damage math | `DefenseCalculator.calculate_damage_taken()` | Already handles full 4-stage pipeline (evasion, resistance, armor, ES split) |
| Pack generation | Manual pack creation | `PackGenerator.generate_packs(area_level)` | Already handles biome selection, scaling, element rolling |
| ES recharge | Custom ES math | `Hero.recharge_energy_shield()` | Already does 33% recharge |
| Hero revival | Custom health reset | `Hero.revive()` | Already restores full HP + full ES |
| Biome lookup | Manual level ranges | `BiomeConfig.get_biome_for_level()` | Already matches level thresholds |

**Key insight:** Phase 13 and 14 built all the combat primitives. Phase 15 is purely orchestration -- wiring existing pieces into a loop.

## Common Pitfalls

### Pitfall 1: Timer Not Stopped on State Transition
**What goes wrong:** Hero or pack timer fires after combat ends (pack dead, hero dead, map complete), causing null reference or double-processing.
**Why it happens:** Timers are one-shot or repeating but continue across state transitions if not explicitly stopped.
**How to avoid:** Stop both timers on EVERY state transition. Create a `stop_combat()` helper that stops both timers and is called from every exit path.
**Warning signs:** Errors about null pack reference, damage applied after death.

### Pitfall 2: Hero DPS Used as Flat Damage
**What goes wrong:** Hero deals `total_dps` as damage per hit, but DPS already factors in attack speed -- double-counting speed.
**Why it happens:** DPS = damage * speed * crit_mult. If you deal DPS per hit AND hit faster with high speed, speed is applied twice.
**How to avoid:** Calculate damage per hit as `total_dps / hero_attack_speed`. Or better: compute raw damage = base_damage + flat_mods, apply crit per-hit, and let attack speed only control timer frequency.
**Warning signs:** Fast weapons doing disproportionately more damage than expected.

### Pitfall 3: ES Recharge Between Packs When Hero Died
**What goes wrong:** ES recharges between packs even when hero is dead, allowing partial recovery before death processing.
**Why it happens:** Pack transition logic runs ES recharge before checking hero alive state.
**How to avoid:** Check `hero.is_alive` BEFORE any pack transition logic. Dead hero goes to HERO_DEAD state immediately.

### Pitfall 4: Area Level vs Max Unlocked Level Confusion
**What goes wrong:** Area level advances incorrectly -- jumping to max_unlocked + 1 instead of current + 1.
**Why it happens:** Two concepts: the level you're currently running, and the highest level you've cleared. Context says always advance current_level + 1.
**How to avoid:** Track both `area_level` (current run) and `max_unlocked_level` (highest cleared). On map clear: `area_level += 1`, `max_unlocked_level = max(max_unlocked_level, area_level)`.

### Pitfall 5: Crit Calculation Mismatch
**What goes wrong:** Hero crit in combat doesn't match the DPS preview.
**Why it happens:** `StatCalculator._calculate_crit_multiplier` uses expected-value averaging, but per-hit combat needs actual crit rolls.
**How to avoid:** In combat, roll crit per hit: if `randf() < crit_chance/100`, multiply damage by `crit_damage/100`. The DPS display uses the expected-value formula (which is correct for averaging), but individual hits should be rolled.

## Code Examples

### Hero Attack on Pack (with crit roll)
```gdscript
func hero_attack() -> void:
    var pack := get_current_pack()
    if pack == null or not pack.is_alive():
        return

    var hero := GameState.hero
    # Base damage per hit (DPS / attack_speed removes the speed factor)
    var damage_per_hit := hero.total_dps / hero_attack_speed

    # Roll crit
    var is_crit := randf() < (hero.total_crit_chance / 100.0)
    if is_crit:
        damage_per_hit *= (hero.total_crit_damage / 100.0)

    pack.take_damage(damage_per_hit)
    hero_attacked.emit(damage_per_hit, is_crit)

    if not pack.is_alive():
        on_pack_killed()
```

### Pack Attack on Hero (using DefenseCalculator)
```gdscript
func pack_attack() -> void:
    var pack := get_current_pack()
    if pack == null:
        return

    var hero := GameState.hero
    var result := DefenseCalculator.calculate_damage_taken(
        pack.damage,
        pack.element,
        false,  # packs are attacks, not spells
        hero.get_total_armor(),
        hero.get_total_evasion(),
        hero.get_total_energy_shield(),
        hero.get_total_fire_resistance(),
        hero.get_total_cold_resistance(),
        hero.get_total_lightning_resistance(),
        hero.get_current_energy_shield()
    )

    if result["dodged"]:
        pack_attacked.emit({"dodged": true})
        return

    hero.apply_damage(result["life_damage"], result["es_damage"])
    pack_attacked.emit(result)

    if not hero.is_healthy():
        on_hero_died()
```

### Pack Transition with ES Recharge
```gdscript
func on_pack_killed() -> void:
    stop_timers()
    current_pack_index += 1
    pack_killed.emit(current_pack_index, current_packs.size())

    if current_pack_index >= current_packs.size():
        on_map_completed()
        return

    # ES recharge between packs (33%)
    GameState.hero.recharge_energy_shield()
    # Instant transition -- start next fight immediately
    start_pack_fight()
```

### Map Flow
```gdscript
func on_map_completed() -> void:
    state = State.MAP_COMPLETE
    # Full ES recharge between maps
    GameState.hero.current_energy_shield = float(GameState.hero.total_energy_shield)
    area_level += 1
    max_unlocked_level = max(max_unlocked_level, area_level)
    map_completed.emit(area_level - 1)
    # Auto-advance: start next map immediately
    start_new_map()

func on_hero_died() -> void:
    state = State.HERO_DEAD
    stop_timers()
    GameState.hero.revive()
    hero_died.emit()
    # Packs re-roll on retry (same area level)
    if auto_retry:
        start_new_map()

func start_new_map() -> void:
    current_packs = PackGenerator.generate_packs(area_level)
    current_pack_index = 0
    state = State.FIGHTING
    combat_started.emit(area_level, current_packs.size())
    start_pack_fight()
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single ClearingTimer + RNG progression | Pack-by-pack combat with dual timers | Phase 15 (this phase) | Replaces time-based clearing with actual combat loop |
| 10% random area advancement | Deterministic area_level + 1 on clear | Phase 15 (this phase) | Players always progress on success |
| area_difficulty_multiplier for damage | MonsterPack.damage with exponential scaling | Phase 14 | Pack damage comes from data, not formula |

## Open Questions

1. **Hero damage-per-hit calculation**
   - What we know: Hero has `total_dps` which includes attack speed in the formula
   - What's unclear: Should we derive damage_per_hit as `total_dps / attack_speed`, or recalculate from base stats ignoring the DPS formula?
   - Recommendation: Use `total_dps / hero_attack_speed` for simplicity. This correctly removes the speed factor from DPS, giving damage per hit. Crit should be rolled per-hit separately from the DPS expected-value formula.

2. **Weapon base_attack_speed values**
   - What we know: LightSword exists as only weapon type. Context says "swords faster, hammers slower"
   - What's unclear: Exact values for LightSword
   - Recommendation: LightSword `base_attack_speed = 1.8` (fast, ~0.56s between hits). Default weapon fallback = 1.0. Future weapon types can vary. The hero defaults to 1.0 if no weapon equipped.

3. **Auto-retry toggle persistence**
   - What we know: Context says toggle for auto-retry vs pause after death
   - What's unclear: Whether this persists in GameState or is local to CombatEngine
   - Recommendation: Store in CombatEngine as `auto_retry: bool = true` (default on). Phase 17 UI can expose the toggle. No need for GameState persistence yet.

## Sources

### Primary (HIGH confidence)
- Codebase analysis: `models/hero.gd`, `models/monsters/monster_pack.gd`, `models/monsters/pack_generator.gd`, `models/stats/defense_calculator.gd`, `scenes/gameplay_view.gd` -- direct reading of existing implementation
- Codebase analysis: `models/stats/stat_calculator.gd`, `models/items/weapon.gd` -- DPS calculation chain
- Codebase analysis: `autoloads/game_state.gd`, `autoloads/game_events.gd` -- state and signal patterns

### Secondary (MEDIUM confidence)
- Godot 4.5 Timer documentation -- Timer node behavior for repeating timers with wait_time

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all Godot built-ins, no external dependencies
- Architecture: HIGH -- follows existing codebase patterns exactly
- Pitfalls: HIGH -- derived from reading actual code and identifying integration points

**Research date:** 2026-02-16
**Valid until:** 2026-03-16 (stable -- Godot core and project architecture unlikely to change)
