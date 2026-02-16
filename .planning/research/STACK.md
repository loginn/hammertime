# Stack Research

**Domain:** Pack-based ARPG mapping with idle combat system
**Researched:** 2026-02-16
**Confidence:** HIGH

## Recommended Stack

### Core Technologies (Already Validated)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Godot Engine | 4.5 | Game engine | Already validated in v1.1. Mobile renderer confirmed working. No changes needed for combat system additions. 4.5 adds shader baker (20x load time reduction), TileMapLayer physics improvements, stencil buffer support. |
| GDScript | 4.5 | Scripting language | Already validated. Native to Godot 4.5, excellent for Resource-based architectures. Await/async syntax perfect for sequential idle combat. |
| Mobile Renderer | 4.5 | Graphics backend | Already validated. Uses Vulkan/Metal/D3D12 with automatic fallback to Compatibility mode if needed. Single-pass lighting suitable for idle game. |

### Combat System Components (NEW)

| Component | Implementation | Purpose | Why This Approach |
|-----------|---------------|---------|-------------------|
| Timer Management | SceneTreeTimer + await | Sequential pack combat timing | One-shot timers managed by SceneTree. No node instantiation overhead. Clean async code with await pattern. Perfect for idle combat where battles run autonomously. |
| Combat State | Signal-based via GameEvents autoload | Combat lifecycle events | Consistent with existing signal architecture (equipment_changed, item_crafted, area_cleared). No state machine needed for simple sequential combat. |
| Monster Data | Resource (class_name MonsterPack) | Pack definitions with HP/damage/elemental type | Matches existing Item/Currency/Affix Resource pattern. Searchable in editor, saveable as .tres files. Data-driven design separates stats from logic. |
| Damage Calculation | Static methods in StatCalculator | Armor/evasion/resistance formulas | Extends existing StatCalculator pattern used for DPS. Keeps all combat math centralized and testable. |
| Combat Loop | Coroutine with await in GameState autoload | Idle combat automation | Runs in existing GameState singleton. No scene coupling. Can continue/pause/stop via signals. |

### Supporting Patterns

| Pattern | Purpose | When to Use |
|---------|---------|-------------|
| Resource with class_name | Monster pack definitions, map definitions | For all data-only entities. Already proven with Item, Currency, Affix, Hero, Implicit. |
| Template Method | Monster pack variations (normal, elite, boss) | If packs need shared structure with specialized behavior (similar to Currency system). |
| Signal broadcasting | Combat events (pack_defeated, hero_damaged, hero_died) | Extends existing GameEvents. Decouples combat logic from UI updates. |
| Static calculator methods | All damage formulas (armor reduction, evasion chance, resistance) | Matches existing StatCalculator.calculate_dps() pattern. Pure functions, easy to test. |

### Data Structures (NEW)

| Structure | Type | Fields | Purpose |
|-----------|------|--------|---------|
| MonsterPack | Resource | hp: float, damage: float, elemental_type: String, pack_size: int | Defines one pack encounter in a map |
| Map | Resource | packs: Array[MonsterPack], area_level: int, biome: String | Defines one full map with sequential packs |
| CombatState | Dictionary in GameState | current_pack: int, combat_active: bool, pack_hp: float | Tracks current combat progress (no new autoload needed) |

## Installation

No additional installations required. All features use Godot 4.5 built-in APIs.

**New file structure:**
```
models/
  monsters/
    monster_pack.gd         # Resource with class_name MonsterPack
  maps/
    map.gd                  # Resource with class_name Map

autoloads/
  game_state.gd             # Add combat state tracking + combat loop coroutine
  game_events.gd            # Add combat signals

models/stats/
  stat_calculator.gd        # Add defense calculation static methods
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| SceneTreeTimer + await | Timer node | Use Timer node only if you need pause/resume/speed control (not needed for idle combat). SceneTreeTimer is lighter, no scene tree pollution. |
| Signal-based combat state | Finite State Machine (FSM) | Use FSM if combat has complex branching (defending, counterattacking, status effects). Current design is linear (pack spawns → hero attacks → pack attacks → repeat until death). Signals sufficient. |
| Static methods in StatCalculator | Combat manager class | Use manager class if combat needs instance-level state. Current design is stateless formulas (armor value + damage → reduction %). Static methods match existing pattern. |
| Coroutine with await | Repeating Timer.timeout signals | Use repeating Timer if combat needs precise frame-locked timing. Await pattern is cleaner for "wait X seconds → damage → wait → damage" flow. |
| PoE-style armor formula | Flat percentage reduction | Use flat percentage (Armor / (Armor + 100)) if player education is a concern. PoE formula (Armor / (Armor + 5 × Damage)) provides more strategic depth but is less intuitive. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| CharacterBody2D/3D for monsters | Idle combat has no movement. Physics bodies cause unnecessary performance overhead. Forum reports show move_and_slide/move_and_collide are major bottlenecks. When performance drops, Godot does up to 8 physics updates per frame, cascading into worse performance. | Resource-based monster data. Combat is pure stat calculations. |
| Navigation2D/NavigationAgent2D | No pathfinding needed. Idle combat is entirely automated stat-based resolution. Navigation parsing is a documented performance issue. | Timer-based sequential combat. No spatial logic. |
| AnimationPlayer for damage numbers | Overkill for simple value changes. Creates reusable asset overhead. Requires creating animations in editor. | Tween.create_tween() for UI animations (HP bar drains, damage numbers). Auto-releases when complete. No scene pollution. |
| Multiple combat autoloads | Fragments state. Harder to track combat flow. | Single GameState autoload already exists. Add combat_active, current_pack_index, pack_hp fields. |
| Separate DamageCalculator class | Splits combat math from existing StatCalculator. Inconsistent with DPS calculation location. | Extend StatCalculator with static defense methods. Keep all combat formulas together. |
| Timer node for sequential combat | Requires instantiating nodes, managing references, connecting signals. More verbose than await. | SceneTreeTimer + await. One-liner: await get_tree().create_timer(1.0).timeout |
| Storing single-use Tween in field | Terrible practice that invites bugs. Tweens are not designed to be re-used. Trying to re-use results in undefined behavior. | Always create fresh Tween with create_tween(). Let it auto-release. |

## Stack Patterns by Feature

### Pattern 1: Monster Pack Combat (Sequential Idle)

**When:** Hero enters map with multiple monster packs
**Approach:** Coroutine-based combat loop in GameState

```gdscript
# In autoloads/game_state.gd
func start_map_combat(map: Map) -> void:
    combat_active = true
    GameEvents.combat_started.emit(map)

    for pack_index in range(map.packs.size()):
        current_pack_index = pack_index
        var pack = map.packs[pack_index]
        GameEvents.pack_spawned.emit(pack)

        await _fight_pack(pack)

        if not hero.is_alive:
            GameEvents.combat_ended.emit(false)
            return

        GameEvents.pack_defeated.emit(pack, pack.currency_drops)
        add_currencies(pack.currency_drops)

    combat_active = false
    GameEvents.combat_ended.emit(true)

func _fight_pack(pack: MonsterPack) -> void:
    pack_hp = pack.get_effective_hp(current_area_level)

    while pack_hp > 0 and hero.is_alive:
        # Hero attacks
        await get_tree().create_timer(hero.attack_speed).timeout
        pack_hp -= hero.total_dps
        pack_hp = max(0, pack_hp)

        if pack_hp <= 0:
            break

        # Pack attacks back
        await get_tree().create_timer(pack.attack_speed).timeout
        var damage := StatCalculator.calculate_damage_taken(
            pack.damage,
            pack.elemental_type,
            hero
        )
        hero.take_damage(damage)
        GameEvents.hero_damaged.emit(damage, hero.health)
```

**Why:** Matches idle game automation. Clean async flow. No state machine complexity. Easy to pause/resume via combat_active flag.

### Pattern 2: Damage Reduction Formulas (PoE-Inspired)

**When:** Monster attacks hero with elemental damage
**Approach:** Layered defense in StatCalculator

```gdscript
# In models/stats/stat_calculator.gd
static func calculate_damage_taken(
    raw_damage: float,
    elemental_type: String,
    hero: Hero
) -> float:
    # Layer 1: Evasion check (entropy-based or simple RNG)
    if randf() < calculate_evasion_chance(hero.total_evasion):
        return 0.0

    # Layer 2: Elemental resistance (percentage reduction, capped at 75%)
    var resistance := hero.get_resistance_for_type(elemental_type)
    var resist_mult := 1.0 - (min(resistance, 75) / 100.0)
    var damage := raw_damage * resist_mult

    # Layer 3: Energy shield depletes first
    if hero.current_energy_shield > 0:
        var es_damage := min(damage, hero.current_energy_shield)
        hero.current_energy_shield -= es_damage
        damage -= es_damage
        if damage <= 0:
            return 0.0

    # Layer 4: Armor reduction (PoE formula: Armor / (Armor + 5 * Damage))
    var armor_reduction := calculate_armor_reduction(hero.total_armor, damage)
    damage *= (1.0 - armor_reduction)

    return damage

static func calculate_armor_reduction(armor: int, incoming_damage: float) -> float:
    if armor <= 0:
        return 0.0
    var reduction := float(armor) / (float(armor) + 5.0 * incoming_damage)
    return min(reduction, 0.90)  # 90% cap

static func calculate_evasion_chance(evasion: int) -> float:
    # Simple formula: diminishing returns
    # At 100 evasion = 50% chance, 200 = 66%, 400 = 80%
    return float(evasion) / (float(evasion) + 100.0)

static func calculate_resistance_multiplier(resistance: int) -> float:
    return 1.0 - (min(resistance, 75) / 100.0)
```

**Why:**
- **Evasion first** creates all-or-nothing avoidance (like PoE)
- **Resistance** is flat percentage (easy to understand, 75% cap prevents immortality)
- **Energy shield** acts as second HP pool (recharges after 2s without damage)
- **Armor** scales inversely with hit size (better vs many small hits, weaker vs big hits). PoE formula prevents excessive mitigation (90% cap, minimum effectiveness = armor/5).

### Pattern 3: Resource-Based Monster Packs

**When:** Defining monster packs for maps
**Approach:** Custom Resource with class_name

```gdscript
# models/monsters/monster_pack.gd
class_name MonsterPack extends Resource

@export var pack_name: String = "Goblin Pack"
@export var base_hp: float = 100.0
@export var base_damage: float = 10.0
@export_enum("Physical", "Fire", "Cold", "Lightning") var elemental_type: String = "Physical"
@export var attack_speed: float = 1.5
@export var pack_size: int = 5
@export var currency_drops: Dictionary = {"tack": 1}

# Template method pattern for pack variations
func get_effective_hp(area_level: int) -> float:
    return base_hp * (1.0 + area_level * 0.1)

func get_effective_damage(area_level: int) -> float:
    return base_damage * (1.0 + area_level * 0.15)
```

**Why:**
- Matches existing Item/Currency Resource pattern
- Searchable in Add Resource dialog
- Saveable as .tres files (models/monsters/goblin_pack.tres)
- @export properties editable in Inspector
- Separation of data (stats) from logic (combat calculations)
- Template method allows subclasses (ElitePack, BossPack) to override scaling

### Pattern 4: Combat Signals (Extending GameEvents)

**When:** Combat state changes need to update UI
**Approach:** Add signals to existing GameEvents autoload

```gdscript
# autoloads/game_events.gd (additions)
signal pack_spawned(pack: MonsterPack)
signal pack_defeated(pack: MonsterPack, drops: Dictionary)
signal hero_damaged(damage: float, remaining_hp: float)
signal hero_died()
signal hero_revived()
signal combat_started(map: Map)
signal combat_ended(success: bool)
signal energy_shield_depleted()
signal energy_shield_recharged()
```

**Why:**
- Consistent with existing equipment_changed, item_crafted, area_cleared pattern
- Decouples combat logic from UI (scenes connect to signals, GameState emits)
- No scene coupling (GameState doesn't know about UI nodes)
- Easy to add combat log, damage numbers, health bar updates

## Version Compatibility

| Component | Compatible With | Notes |
|-----------|-----------------|-------|
| SceneTreeTimer | Godot 4.5 | One-shot timer, managed by SceneTree. Introduced in Godot 3.x, stable in 4.5. |
| await keyword | GDScript 4.5 | Replaces yield from Godot 3.x. Native async/await syntax. |
| Resource with class_name | Godot 4.5 | Improved in 4.x with better inspector integration. Known issue: creating new Resource script may temporarily show inspector error (fixed by reload). |
| Mobile renderer | Godot 4.5 | Auto-fallback to Compatibility mode if Vulkan/Metal/D3D12 unavailable. No breaking changes from 4.4. |
| @export_enum | GDScript 4.5 | Dropdown selector in Inspector. Used for elemental types. |

## Damage Formula Design Rationale

### Why PoE-style armor formula?

**Formula:** Armor Reduction = Armor / (Armor + 5 × Damage)

**Pros:**
- Scales inversely with hit size (strategic depth: many weak hits vs few strong hits)
- Never exceeds 90% (prevents immortality)
- Minimum effectiveness = Armor/5 (always provides some value)
- Self-balancing (high armor doesn't trivialize content)
- Matches ARPG genre expectations (PoE uses this exact formula)

**Cons:**
- Non-linear (less intuitive than flat percentage)
- Requires player education ("Why did I take full damage with 1000 armor?")

**Alternatives:**
- **Flat percentage (League of Legends style):** Armor / (Armor + 100) = % reduction. More intuitive, but less strategic depth.
- **Direct subtraction:** Armor reduces damage by X. Simple, but causes balance issues (immortality at high armor).

**Recommendation:** Use PoE formula. Matches ARPG genre expectations. Strategic depth (build for many fast attacks vs few slow attacks). Self-balancing prevents power creep.

### Why evasion as chance-to-avoid vs partial reduction?

**Chosen:** RNG-based all-or-nothing (if evade check succeeds, take 0 damage)

**Pros:**
- Creates distinct defensive playstyle from armor
- Exciting when it procs (full avoidance vs minor reduction)
- Matches ARPG genre (PoE, Diablo use evasion checks)

**Cons:**
- RNG can feel bad (unlucky streaks = death)
- Harder to balance than deterministic reduction

**Alternatives:**
- **Entropy-based (PoE style):** Guarantees evasion rate over time (removes unlucky streaks). More complex to implement.
- **Partial reduction:** Evasion reduces damage by X%. Less exciting, overlaps with armor.

**Recommendation:** Start with simple RNG (randf() < evasion_chance). Add entropy-based system if players complain about RNG. Entropy formula: track "evasion_counter", add evasion_chance each hit, subtract 100 when >= 100 (guaranteed evade).

### Why 75% resistance cap?

**Chosen:** Elemental resistances reduce damage by % (capped at 75%)

**Pros:**
- Intuitive (75% fire resist = take 25% fire damage)
- Cap prevents immortality against single element
- Matches PoE (75% cap), WoW (75% cap), GW2 (similar)
- Forces build diversity (can't ignore resistances)

**Cons:**
- Late-game resistance stacking becomes mandatory (75% is 4x effective HP vs elemental damage)

**Alternatives:**
- **No cap:** Allows 100% immunity. Breaks balance (fire-immune build trivializes fire content).
- **Lower cap (50%):** Less impactful, less satisfying to build.

**Recommendation:** Use 75% cap. Standard in ARPG genre. Forces build diversity. Prevents degenerate immunity builds.

### Why energy shield recharges after 2s?

**Chosen:** ES starts recharging 2s after last hit (PoE style)

**Pros:**
- Renewable defensive layer (doesn't require potions/healing)
- Rewards kiting/avoidance in manual content (future-proof for active gameplay)
- Different from armor/evasion (proactive vs reactive defense)

**Cons:**
- Less useful in sustained combat (doesn't recharge while taking hits)
- Requires tracking "time since last damage"

**Alternatives:**
- **Instant recharge:** Overpowered (infinite HP in slow combat).
- **After combat ends:** Simpler, but less strategic.

**Recommendation:** Use 2s delay. Matches PoE. Future-proof for active content. For idle combat, ES effectively acts as bonus HP per pack (recharges between packs).

## Combat Flow Integration Points

### Existing GameState Extensions

```gdscript
# Add to autoloads/game_state.gd
var combat_active: bool = false
var current_map: Map = null
var current_pack_index: int = 0
var pack_hp: float = 0.0

# New methods
func start_map_combat(map: Map) -> void
func _fight_pack(pack: MonsterPack) -> void
func stop_combat() -> void
```

### Existing StatCalculator Extensions

```gdscript
# Add to models/stats/stat_calculator.gd
static func calculate_evasion_chance(evasion: int) -> float
static func calculate_armor_reduction(armor: int, incoming_damage: float) -> float
static func calculate_resistance_multiplier(resistance: int) -> float
static func calculate_damage_taken(raw_damage: float, elemental_type: String, hero: Hero) -> float
```

### Existing Hero Extensions

```gdscript
# Add to models/hero.gd
var current_energy_shield: float = 0.0
var last_damage_time: float = 0.0
var attack_speed: float = 1.0  # Base 1 attack per second

# Extend existing take_damage()
func take_damage(damage: float) -> void:
    last_damage_time = Time.get_ticks_msec() / 1000.0
    # Damage already reduced by StatCalculator before calling
    health -= damage
    health = max(0, health)
    if health <= 0:
        die()

# New method
func _process(delta: float) -> void:
    _recharge_energy_shield(delta)

func _recharge_energy_shield(delta: float) -> void:
    if current_energy_shield >= total_energy_shield:
        return
    var time_since_damage := (Time.get_ticks_msec() / 1000.0) - last_damage_time
    if time_since_damage >= 2.0:
        var recharge_rate := total_energy_shield * 0.333  # 33.3% per second
        current_energy_shield += recharge_rate * delta
        current_energy_shield = min(current_energy_shield, total_energy_shield)

func get_resistance_for_type(elemental_type: String) -> int:
    match elemental_type:
        "Fire": return total_fire_resistance
        "Cold": return total_cold_resistance
        "Lightning": return total_lightning_resistance
        _: return 0  # Physical has no resistance
```

### Existing GameEvents Extensions

```gdscript
# Add to autoloads/game_events.gd
signal pack_spawned(pack: MonsterPack)
signal pack_defeated(pack: MonsterPack, drops: Dictionary)
signal hero_damaged(damage: float, remaining_hp: float)
signal hero_died()
signal map_started(map: Map)
signal map_completed(map: Map, success: bool)
signal energy_shield_depleted()
signal energy_shield_recharged()
```

## Performance Considerations

### Why no physics bodies?

Idle combat is stat-based. No movement, collision, or spatial queries. CharacterBody2D/RigidBody2D would add:
- Unnecessary _physics_process() calls every frame
- Collision detection overhead
- Transform updates for static entities

**Evidence:** Godot forums report move_and_slide and move_and_collide as major performance bottlenecks. When performance drops, Godot does up to 8 physics updates per frame, cascading into worse performance.

**Recommendation:** Pure Resource data + StatCalculator formulas. No Node2D, no physics.

### Why SceneTreeTimer over Timer node?

**SceneTreeTimer:**
- No scene tree pollution (no node instances)
- Auto-managed by SceneTree (no manual cleanup)
- One-liner usage: `await get_tree().create_timer(1.0).timeout`

**Timer node:**
- Requires instantiation, add_child(), remove_child()
- Signal connection overhead
- Useful for repeating timers or pause/resume control

**Recommendation:** SceneTreeTimer for idle combat. One-shot timers, auto-cleanup, cleaner code.

### Why Tween over AnimationPlayer for UI?

**Tween (via create_tween()):**
- Code-based, no AnimationPlayer node needed
- Auto-releases when complete (no memory leak)
- Perfect for procedural animations (HP bar drain, damage numbers)

**AnimationPlayer:**
- Asset-based, requires creating animations in editor
- Reusable across scenes
- Better for complex multi-property animations

**Recommendation:** Tween for combat UI (HP bars, damage numbers). AnimationPlayer for complex scene transitions if needed.

**Warning:** Never store single-use Tween in a field. Creates bugs. Tweens are not reusable.

### Mobile renderer compatibility

**Confirmed:** Mobile renderer uses Vulkan/Metal/D3D12 with auto-fallback to Compatibility (OpenGL) if unavailable. Single-pass lighting. Suitable for idle game (no complex shaders, limited light sources).

**No issues expected.** Combat system is pure logic (no rendering changes).

## Sources

### Official Godot Documentation (HIGH CONFIDENCE)
- [Godot 4.5 Release](https://godotengine.org/releases/4.5/) — Verified 4.5 features (shader baker, TileMapLayer physics, stencil buffers)
- [SceneTreeTimer (4.5 docs)](https://docs.godotengine.org/en/4.5/classes/class_scenetreetimer.html) — Confirmed one-shot timer API
- [Timer Node (4.5 docs)](https://docs.godotengine.org/en/4.5/classes/class_timer.html) — Confirmed repeating timer patterns
- [GDScript Exports](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_exports.html) — Verified @export syntax
- [Overview of Renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html) — Mobile renderer limitations
- [3D Rendering Limitations (4.5)](https://docs.godotengine.org/en/4.5/tutorials/3d/3d_rendering_limitations.html) — Performance considerations
- [Idle and Physics Processing](https://docs.godotengine.org/en/stable/tutorials/scripting/idle_and_physics_processing.html) — Physics performance issues

### Path of Exile Wiki (HIGH CONFIDENCE — ARPG damage formulas)
- [Armor Formula](https://www.poewiki.net/wiki/Armour) — Verified: DR = A/(A + 5×D), 90% cap
- [Energy Shield Mechanics](https://www.poewiki.net/wiki/Energy_shield) — Verified: 2s recharge delay, 33.3%/s rate
- [Resistance](https://www.poewiki.net/wiki/Resistance) — Verified: 75% cap standard
- [Evasion](https://www.poewiki.net/wiki/Evasion) — Verified: entropy-based formula

### Community Resources (MEDIUM CONFIDENCE — best practices)
- [Timer Best Practices — Godot Forum](https://forum.godotengine.org/t/timer-node-best-practices/84112) — Process mode, one-shot vs repeating
- [Godot Timing Tutorial](https://gdscript.com/solutions/godot-timing-tutorial/) — Await patterns
- [Make a Finite State Machine in Godot 4](https://www.gdquest.com/tutorial/godot/design-patterns/finite-state-machine/) — When to use FSM (not needed for linear combat)
- [Custom Resources in Godot 4](https://ezcha.net/news/3-1-23-custom-resources-are-op-in-godot-4) — Resource with class_name patterns
- [Creating Custom Nodes (Feb 2026)](https://uhiyama-lab.com/en/notes/godot/custom-node-editor-extension/) — @export, class_name best practices
- [Tween Smooth Animation](https://uhiyama-lab.com/en/notes/godot/tween-smooth-animation/) — Tween vs AnimationPlayer

### Game Design References (MEDIUM CONFIDENCE — formula alternatives)
- [Damage Types, Resistances, Gameplay Tags](https://www.thegames.dev/?p=165) — Resistance calculation patterns
- [League of Legends Armor](https://leagueoflegends.fandom.com/wiki/Armor) — Flat percentage approach (Armor/(Armor+100))
- [Evasion Formulas](https://www.gamedev.net/forums/topic/685930-the-simplest-but-most-effective-and-intuitive-way-to-implement-accuracy-and-dodge-chance-in-an-rpg/) — Additive vs multiplicative

### Community Discussions (LOW CONFIDENCE — anecdotal)
- [Resource-based Enemy Data](https://forum.godotengine.org/t/beginner-making-sure-i-understand-resources-to-set-up-the-monster-database-in-a-retro-styled-rpg/72046) — Resource patterns for monsters
- [Idle Game Combat Automation](https://medium.com/@sexwoojisung/what-if-idle-rpgs-let-you-design-the-auto-battle-0ab3cdb24295) — Idle game design patterns
- [Tween vs AnimationPlayer Performance](https://forum.godotengine.org/t/tween-vs-animation-player-performance/2278) — Performance comparison
- [Physics Performance Issues](https://forum.godotengine.org/t/guidance-when-optimizing-minimizing-idle-time-and-reading-the-profiler/29052) — Avoid physics for idle games

---
*Stack research for: Pack-based mapping with idle combat in Godot 4.5*
*Researched: 2026-02-16*
*Confidence: HIGH — All core recommendations validated against existing Godot 4.5 patterns and ARPG genre standards*
