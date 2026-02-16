# Architecture Research

**Domain:** Pack-Based Combat Integration for ARPG Idle Game
**Researched:** 2026-02-16
**Confidence:** HIGH

## Executive Summary

The v1.2 milestone adds pack-based combat, monster packs, death mechanics, and defensive calculations to an existing Resource-based ARPG crafting game built on Godot 4.5. The existing architecture is well-suited for this integration with minimal disruption:

- **NEW Resources**: MonsterPack, Map (replacing area-as-integer)
- **MODIFIED Resources**: Hero (add defensive calculation methods), StatCalculator (add damage reduction functions)
- **MODIFIED Autoloads**: GameState (pack tracking, death state), GameEvents (new combat signals)
- **MAJOR REWORK**: gameplay_view (from time-based area clearing to pack-based combat loop)
- **MODIFIED System**: LootTable (split drops: packs→currency, maps→items)

The architecture follows Godot's Resource pattern for data, signal bus for events, and StatCalculator service for calculations. New combat features integrate cleanly without restructuring the existing feature-based folder organization or scene hierarchy.

## Current Architecture (v1.1)

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Scene Layer                             │
├─────────────────────────────────────────────────────────────┤
│  main.tscn                                                   │
│    └─ main_view (coordinator)                                │
│         ├─ crafting_view (Item creation)                     │
│         ├─ hero_view (Equipment, stats display)              │
│         └─ gameplay_view (Area clearing, drops) ← REWORK     │
├─────────────────────────────────────────────────────────────┤
│                    Service Layer                             │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │StatCalculator│  │  LootTable   │  │   Currency   │       │
│  │(DPS/defense) │  │ (rarity/qty) │  │ (template)   │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
├─────────────────────────────────────────────────────────────┤
│                    Data Layer (Resources)                    │
├─────────────────────────────────────────────────────────────┤
│  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐│
│  │  Hero  │  │  Item  │  │ Affix  │  │Currency│  │Implicit││
│  └────────┘  └────────┘  └────────┘  └────────┘  └────────┘│
├─────────────────────────────────────────────────────────────┤
│                    Global State (Autoloads)                  │
│  ┌────────────────────────┐  ┌────────────────────────┐     │
│  │      GameState         │  │      GameEvents        │     │
│  │ - hero: Hero singleton │  │  - equipment_changed   │     │
│  │ - currency_counts: {}  │  │  - item_crafted        │     │
│  │                        │  │  - area_cleared        │     │
│  └────────────────────────┘  └────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Pattern |
|-----------|----------------|---------|
| **GameState** | Hero singleton, currency inventory | Autoload singleton |
| **GameEvents** | Cross-scene signal bus | Event bus pattern |
| **StatCalculator** | DPS/defense calculations (static service) | Stateless service |
| **LootTable** | Rarity weights, drop counts (static service) | Stateless service |
| **Resource classes** | Item, Affix, Implicit, Hero, Currency data | Data objects extending Resource |
| **Currency** | Template method for validation/application | Template method pattern |
| **Views** | Scene-specific UI, coordinated by main_view | MVC-style views |

### Current Data Flow (v1.1)

```
CRAFTING FLOW:
User clicks hammer → crafting_view → Currency.apply(item) → item.update_value()
→ StatCalculator → item_finished signal → hero_view updates display

COMBAT FLOW (v1.1 - time-based):
Timer timeout → gameplay_view.clear_area()
  ├─ LootTable.get_item_drop_count(area_level) → spawn items
  ├─ LootTable.roll_currency_drops(area_level) → add currencies to GameState
  ├─ GameEvents.area_cleared.emit(area_level)
  ├─ Hero.take_damage() → simple armor formula
  └─ If dead: stop clearing, auto-revive

EQUIPMENT FLOW:
hero_view.equip_item() → Hero.equip_item() → Hero.update_stats()
→ GameEvents.equipment_changed → gameplay_view.refresh_clearing_speed()
```

## New Architecture for v1.2 (Pack-Based Combat)

### New Resources

#### MonsterPack Resource
```gdscript
class_name MonsterPack extends Resource

var pack_name: String = "Goblin Pack"
var current_hp: float = 100.0
var max_hp: float = 100.0
var damage: float = 10.0
var damage_type: String = "physical"  # "physical", "fire", "cold", "lightning"
var pack_size: int = 5  # Visual only, affects HP
var area_level: int = 1

func is_alive() -> bool:
    return current_hp > 0

func take_damage(damage: float) -> void:
    current_hp -= damage
    current_hp = max(0, current_hp)
```

**Why Resource**: Follows existing pattern (Hero, Item, Currency all extend Resource). Pack instances are runtime state, not saved data, but Resource provides structure and inspector visibility for debugging.

#### Map Resource
```gdscript
class_name Map extends Resource

var map_name: String = "Forest Clearing"
var area_level: int = 1
var total_packs: int = 10
var packs_cleared: int = 0
var current_pack: MonsterPack = null

func generate_next_pack() -> MonsterPack:
    # Creates MonsterPack with HP/damage scaled by area_level
    pass

func is_complete() -> bool:
    return packs_cleared >= total_packs
```

**Why Resource**: Replaces current area_level integer. Encapsulates map progression state. Area tier names ("Forest", "Dark Forest") become map types.

### Modified Resources

#### Hero (models/hero.gd)

**ADD defensive calculation methods:**

```gdscript
# NEW method: Calculate damage reduction from armor/evasion/ES/resistances
func calculate_damage_taken(incoming_damage: float, damage_type: String) -> float:
    # Delegate to StatCalculator for actual formulas
    return StatCalculator.calculate_damage_taken(
        incoming_damage,
        damage_type,
        total_armor,
        total_evasion,
        total_energy_shield,
        total_fire_resistance,
        total_cold_resistance,
        total_lightning_resistance
    )

# EXISTING: calculate_defense() already sums armor/evasion/ES/resistances from affixes
# NO CHANGE needed to stat aggregation logic
```

**Why modify**: Hero already aggregates defensive stats (armor, evasion, ES, resistances). Adding damage calculation method keeps defensive logic centralized in Hero, matching existing DPS pattern (Hero.get_total_dps()).

#### StatCalculator (models/stats/stat_calculator.gd)

**ADD damage reduction functions:**

```gdscript
## Calculate final damage after defensive layers
## Order: Armor → Evasion → Energy Shield → Resistances
static func calculate_damage_taken(
    incoming_damage: float,
    damage_type: String,
    armor: int,
    evasion: int,
    energy_shield: int,
    fire_res: int,
    cold_res: int,
    lightning_res: int
) -> float:
    var damage := incoming_damage

    # Layer 1: Armor (physical only, diminishing returns)
    if damage_type == "physical":
        damage = _apply_armor_reduction(damage, armor)

    # Layer 2: Evasion (chance to avoid, entropy system)
    if _roll_evasion(evasion):
        return 0.0  # Attack evaded

    # Layer 3: Energy Shield (absorbs before life)
    # Handled separately in Hero.take_damage() since ES is a pool

    # Layer 4: Elemental Resistance (elemental damage only)
    if damage_type in ["fire", "cold", "lightning"]:
        var resistance := 0
        match damage_type:
            "fire": resistance = fire_res
            "cold": resistance = cold_res
            "lightning": resistance = lightning_res
        damage = _apply_resistance(damage, resistance)

    return max(1.0, damage)  # Minimum 1 damage

static func _apply_armor_reduction(damage: float, armor: int) -> float:
    # Formula: Damage * (1 - Armor/(Armor + 10*Damage))
    # More effective vs small hits, less vs large hits
    var reduction_factor := float(armor) / (float(armor) + 10.0 * damage)
    return damage * (1.0 - reduction_factor)

static func _apply_resistance(damage: float, resistance: int) -> float:
    # Cap resistance at 75% (standard ARPG cap)
    var capped_res := min(resistance, 75)
    return damage * (1.0 - capped_res / 100.0)

static func _roll_evasion(evasion: int) -> bool:
    # Simplified: higher evasion = higher avoid chance (cap at 75%)
    var avoid_chance := min(float(evasion) / 500.0, 0.75)
    return randf() < avoid_chance
```

**Why StatCalculator**: Matches existing pattern (DPS calculation uses StatCalculator.calculate_dps()). Defense formulas are complex, tested independently. Stateless service keeps calculation logic separate from state.

### Modified Autoloads

#### GameState (autoloads/game_state.gd)

**ADD pack/map tracking:**

```gdscript
# NEW: Current map/pack state
var current_map: Map = null
var current_pack: MonsterPack = null

# NEW: Death state tracking
var hero_death_count: int = 0

# NEW: Generate/progress maps
func start_new_map(area_level: int) -> void:
    current_map = Map.new()
    current_map.area_level = area_level
    current_map.total_packs = 10  # Could scale with area_level
    current_map.packs_cleared = 0
    current_pack = current_map.generate_next_pack()
    GameEvents.map_started.emit(current_map)

func advance_to_next_pack() -> void:
    if current_map.is_complete():
        # Map finished, generate new one
        start_new_map(current_map.area_level + 1)
    else:
        current_pack = current_map.generate_next_pack()
        GameEvents.pack_spawned.emit(current_pack)
```

**Why GameState**: Already owns hero singleton and currency inventory. Current map/pack are runtime singletons (only one active). Centralizes game progression state.

#### GameEvents (autoloads/game_events.gd)

**ADD combat signals:**

```gdscript
# NEW signals
signal map_started(map: Map)
signal pack_spawned(pack: MonsterPack)
signal pack_defeated(pack: MonsterPack)
signal hero_death()
signal combat_damage_dealt(damage: float, target: MonsterPack)
signal combat_damage_taken(damage: float, source: MonsterPack)
```

**Why GameEvents**: Existing pattern for cross-scene communication. Views listen to events, don't poll state. Decouples combat logic from UI updates.

### Modified Services

#### LootTable (models/loot/loot_table.gd)

**SPLIT drop generation:**

```gdscript
# EXISTING: roll_currency_drops(area_level) → Dictionary
# NO CHANGE: Packs drop currency (called on pack death)

# NEW: Roll item drops for completed maps
static func roll_map_item_drops(area_level: int) -> Array[Item]:
    var items: Array[Item] = []
    var item_count := get_item_drop_count(area_level)

    for i in range(item_count):
        var item := _spawn_random_item_base()
        var rarity := roll_rarity(area_level)
        spawn_item_with_mods(item, rarity)
        items.append(item)

    return items

# EXISTING methods used by both:
# - get_item_drop_count(area_level) → int
# - roll_rarity(area_level) → Rarity
# - spawn_item_with_mods(item, rarity) → void
```

**Why split**: Drop sources change (packs vs maps), but formulas remain identical. Existing rarity/quantity logic reused. Clarifies when items vs currency drop.

### Major Rework: gameplay_view

**CURRENT (v1.1 - time-based):**
```gdscript
# Timer-based clearing with auto-progression
var area_level: int = 1
var clearing_timer: Timer

func clear_area():
    # Drop items immediately
    # Drop currency immediately
    # Take damage once
    # Maybe advance area_level
```

**NEW (v1.2 - pack-based):**
```gdscript
# Combat loop with explicit pack progression
var combat_timer: Timer  # Attacks every X seconds based on DPS
var current_map: Map = null  # Reference to GameState.current_map
var current_pack: MonsterPack = null  # Reference to GameState.current_pack

func _ready():
    GameEvents.map_started.connect(_on_map_started)
    GameEvents.pack_spawned.connect(_on_pack_spawned)
    GameEvents.pack_defeated.connect(_on_pack_defeated)
    GameEvents.hero_death.connect(_on_hero_death)

    # Start first map
    GameState.start_new_map(1)

func start_combat():
    combat_timer.start()

func stop_combat():
    combat_timer.stop()

func _on_combat_timer_timeout():
    # Hero attacks pack
    var hero_dps := GameState.hero.get_total_dps()
    var damage_per_hit := hero_dps * combat_timer.wait_time
    current_pack.take_damage(damage_per_hit)
    GameEvents.combat_damage_dealt.emit(damage_per_hit, current_pack)

    if not current_pack.is_alive():
        _on_pack_killed()
        return

    # Pack attacks hero
    var pack_damage := current_pack.damage
    var damage_taken := GameState.hero.calculate_damage_taken(
        pack_damage,
        current_pack.damage_type
    )
    GameState.hero.take_damage(damage_taken)
    GameEvents.combat_damage_taken.emit(damage_taken, current_pack)

    if not GameState.hero.is_alive:
        _on_hero_died()

func _on_pack_killed():
    # Currency drops from pack
    var currency_drops := LootTable.roll_currency_drops(current_map.area_level)
    GameState.add_currencies(currency_drops)
    currencies_found.emit(currency_drops)

    # Advance to next pack
    current_map.packs_cleared += 1
    GameEvents.pack_defeated.emit(current_pack)

    if current_map.is_complete():
        _on_map_completed()
    else:
        GameState.advance_to_next_pack()

func _on_map_completed():
    # Item drops from completed map
    var item_drops := LootTable.roll_map_item_drops(current_map.area_level)
    for item in item_drops:
        item_base_found.emit(item)

    # Start next map (higher area level)
    GameState.start_new_map(current_map.area_level + 1)

func _on_hero_died():
    stop_combat()
    GameState.hero_death_count += 1
    GameState.hero.revive()
    GameEvents.hero_death.emit()
    # Auto-restart combat (idle game design)
    start_combat()
```

**Why rework**: Current design is timer-based with area as integer. New design requires pack state, combat loop, split drop timing (packs vs maps). Rewrite is cleaner than bolting pack logic onto time-based system.

**What stays the same**:
- Signal emissions to crafting_view/hero_view
- Display update methods
- Button connections (Start/Stop clearing)
- Currency/item emission patterns

## Integration Points

### Data Flow Changes

```
OLD (v1.1):
Timer → clear_area() → drops items + currency → signals

NEW (v1.2):
Combat Timer → attack pack → pack dies → currency drops
                    ↓
              pack attacks hero → defensive calculations
                    ↓
          all packs dead → map complete → item drops
```

### Cross-Component Dependencies

| New Component | Depends On | Used By |
|---------------|------------|---------|
| MonsterPack | (none - data class) | GameState, gameplay_view |
| Map | MonsterPack | GameState, gameplay_view |
| Hero.calculate_damage_taken() | StatCalculator | gameplay_view |
| StatCalculator damage functions | Tag.StatType (existing) | Hero |
| GameState pack tracking | Map, MonsterPack | gameplay_view |
| GameEvents combat signals | (none - bus) | gameplay_view, hero_view (future) |
| LootTable.roll_map_item_drops() | Existing item/rarity logic | gameplay_view |

### Signal Flow (New)

```
GameState.start_new_map()
    ↓
GameEvents.map_started → gameplay_view updates display
    ↓
GameState.advance_to_next_pack()
    ↓
GameEvents.pack_spawned → gameplay_view updates display
    ↓
(combat loop)
    ↓
GameEvents.pack_defeated → gameplay_view advances pack count
    ↓
GameEvents.map_completed (NEW, optional)
    ↓
gameplay_view emits item_base_found → crafting_view
```

## Architectural Patterns in v1.2

### Pattern 1: Resource-Based State Objects

**What:** Game entities (Hero, Item, MonsterPack, Map) extend Godot's Resource class
**When to use:** Data that needs structure, inspector visibility, potential serialization
**Trade-offs:**
- PRO: Type-safe, editor integration, matches existing codebase pattern
- CON: Resources are reference types (shared state risk), but GameState enforces single ownership

**Example:**
```gdscript
# MonsterPack follows same pattern as Hero/Item
class_name MonsterPack extends Resource

var max_hp: float = 100.0
var current_hp: float = 100.0

func take_damage(damage: float) -> void:
    current_hp = max(0, current_hp - damage)
```

### Pattern 2: Stateless Service Layer

**What:** StatCalculator and LootTable are static classes with pure functions
**When to use:** Complex calculations that don't depend on instance state
**Trade-offs:**
- PRO: Testable in isolation, no state leakage, reusable
- CON: Can't be mocked (static), but GDScript testing is limited anyway

**Example:**
```gdscript
# StatCalculator doesn't hold state, just does math
var damage_taken := StatCalculator.calculate_damage_taken(
    100.0, "fire", armor, evasion, es, fire_res, cold_res, lightning_res
)
```

### Pattern 3: Event Bus for Decoupling

**What:** GameEvents autoload emits signals, views/systems subscribe
**When to use:** Cross-scene communication, avoiding direct references
**Trade-offs:**
- PRO: Loose coupling, views don't need references to each other
- CON: Harder to trace flow (signal connections), but signals are debuggable in Godot

**Example:**
```gdscript
# gameplay_view emits event
GameEvents.pack_defeated.emit(current_pack)

# hero_view listens (future feature)
GameEvents.pack_defeated.connect(_on_pack_defeated)
func _on_pack_defeated(pack: MonsterPack):
    update_combat_stats_display()
```

### Pattern 4: Template Method (Currency)

**What:** Currency base class defines apply() skeleton, subclasses override _do_apply()
**When to use:** Shared validation/consumption logic, varied behavior
**Trade-offs:**
- PRO: Enforces consumption-on-success rule (CRAFT-09), reduces duplication
- CON: Inheritance over composition, but only one level deep

**EXISTING - no changes for v1.2:**
```gdscript
class_name Currency extends Resource

func apply(item: Item) -> bool:
    if not can_apply(item):
        return false
    _do_apply(item)  # Subclass implements
    return true
```

### Pattern 5: Combat Loop State Machine

**What:** gameplay_view manages combat state (idle → fighting → pack_dead → map_complete)
**When to use:** State transitions with different behaviors per state
**Trade-offs:**
- PRO: Clear state progression, prevents invalid transitions
- CON: Could use formal FSM, but simple flags suffice for linear progression

**Example:**
```gdscript
enum CombatState { IDLE, FIGHTING, PACK_TRANSITION, MAP_COMPLETE }
var state: CombatState = CombatState.IDLE

func _on_combat_timer_timeout():
    match state:
        CombatState.FIGHTING:
            _process_combat()
        CombatState.PACK_TRANSITION:
            _spawn_next_pack()
        # etc.
```

## Build Order (Dependency-Driven)

### Phase 1: Data Foundation (No Dependencies)
1. **MonsterPack Resource** (models/combat/monster_pack.gd)
   - New file, extends Resource
   - No dependencies
   - Needed by: Map, GameState

2. **Map Resource** (models/combat/map.gd)
   - New file, extends Resource
   - Depends: MonsterPack
   - Needed by: GameState

### Phase 2: Calculation Extensions (Depends on Data)
3. **StatCalculator defensive functions** (models/stats/stat_calculator.gd)
   - Modify existing file
   - Depends: Tag.StatType (existing)
   - Needed by: Hero

4. **Hero damage calculation** (models/hero.gd)
   - Modify existing file
   - Depends: StatCalculator (modified)
   - Needed by: gameplay_view

### Phase 3: State Management (Depends on Data + Calcs)
5. **GameState pack tracking** (autoloads/game_state.gd)
   - Modify existing autoload
   - Depends: Map, MonsterPack
   - Needed by: gameplay_view

6. **GameEvents combat signals** (autoloads/game_events.gd)
   - Modify existing autoload
   - No dependencies (just signal definitions)
   - Needed by: gameplay_view

### Phase 4: Drop Logic Split (Depends on Data)
7. **LootTable map drops** (models/loot/loot_table.gd)
   - Modify existing file
   - Depends: Item (existing), LootTable existing methods
   - Needed by: gameplay_view

### Phase 5: View Integration (Depends on Everything)
8. **gameplay_view rework** (scenes/gameplay_view.gd)
   - Major rewrite of existing file
   - Depends: GameState (modified), GameEvents (modified), LootTable (modified), Hero (modified)
   - Last to implement, integrates all new systems

**Rationale**: Bottom-up dependency order. Data layer → calculation layer → state layer → view layer. Each phase is testable before moving to next. gameplay_view last because it orchestrates everything.

## What NOT to Restructure

### Keep Feature-Based Folders
```
models/
  items/
  affixes/
  currencies/
  stats/
  loot/
  combat/  ← NEW folder for MonsterPack, Map
```
**Why**: Existing organization is clear. Combat is a new feature domain, gets its own folder. Don't flatten to "data/" or "resources/" - feature-based is more maintainable.

### Keep Autoload Pattern for Singletons
GameState and GameEvents remain autoloads. Don't move to scene instances.
**Why**: Global state (hero, currency) is legitimately singleton. Event bus needs global access. Autoloads are Godot's idiomatic pattern for this.

### Keep main_view Coordination Pattern
main_view remains the coordinator, views remain siblings.
**Why**: Existing signal wiring (crafting_view → hero_view) works. Don't introduce parent-child view nesting - keeps views reusable.

### Keep Resource Pattern (Don't Switch to Dictionaries)
MonsterPack/Map extend Resource, not plain Dictionaries.
**Why**: Consistency with Hero/Item/Currency. Type safety. Inspector visibility for debugging. Resources are Godot's idiomatic data pattern.

### Keep StatCalculator Stateless
Don't make StatCalculator an autoload or instance.
**Why**: Pure functions are testable, no side effects. Static class prevents accidental state leakage.

### Keep Currency Template Method
Don't refactor Currency to composition or delegate pattern.
**Why**: Works well, only one level of inheritance, enforces consumption rules. Not broken, don't fix.

## Anti-Patterns to Avoid

### Anti-Pattern 1: Tight Coupling gameplay_view → Hero

**What people might do:**
```gdscript
# gameplay_view directly modifying Hero internal state
GameState.hero.health -= 50
GameState.hero.is_alive = false
```

**Why it's wrong:** Breaks encapsulation, bypasses Hero's take_damage() logic, skips death signals

**Do this instead:**
```gdscript
# Use Hero's public interface
GameState.hero.take_damage(50)
# Hero handles health clamping, death state, signals internally
```

### Anti-Pattern 2: Polling State Instead of Signals

**What people might do:**
```gdscript
# gameplay_view checking state every frame
func _process(delta):
    if current_pack.current_hp <= 0:
        _on_pack_killed()
```

**Why it's wrong:** Misses exact moment of death, runs logic multiple times, doesn't notify other systems

**Do this instead:**
```gdscript
# Event-driven flow
func _on_combat_timer_timeout():
    current_pack.take_damage(damage)
    if not current_pack.is_alive():
        _on_pack_killed()
        GameEvents.pack_defeated.emit(current_pack)
```

### Anti-Pattern 3: Mixing Drop Logic in gameplay_view

**What people might do:**
```gdscript
# gameplay_view rolling its own rarity/quantity
func _on_pack_killed():
    var currency_amount = randi_range(1, 5)
    GameState.currency_counts["runic"] += currency_amount
```

**Why it's wrong:** Duplicates LootTable logic, inconsistent with existing system, not area-scaled

**Do this instead:**
```gdscript
# Delegate to LootTable service
func _on_pack_killed():
    var drops := LootTable.roll_currency_drops(current_map.area_level)
    GameState.add_currencies(drops)
```

### Anti-Pattern 4: Energy Shield as Instant Mitigation

**What people might do:**
```gdscript
# Treating ES like armor (% reduction)
var es_reduction = energy_shield / (energy_shield + 100)
damage *= (1.0 - es_reduction)
```

**Why it's wrong:** Energy Shield in ARPGs is a damage buffer (like extra HP), not mitigation

**Do this instead:**
```gdscript
# ES absorbs damage before life (in Hero.take_damage())
func take_damage(damage: float):
    if total_energy_shield > 0:
        var absorbed = min(damage, total_energy_shield)
        total_energy_shield -= absorbed
        damage -= absorbed
    health -= damage
```

### Anti-Pattern 5: Storing Pack State in gameplay_view

**What people might do:**
```gdscript
# gameplay_view owns pack instances
var current_pack: MonsterPack = MonsterPack.new()
```

**Why it's wrong:** Pack state isn't view state. Other systems (future: minimap, achievements) need pack access. View gets destroyed/recreated.

**Do this instead:**
```gdscript
# GameState owns single source of truth
var current_pack: MonsterPack = null  # Reference to GameState.current_pack

func _on_pack_spawned(pack: MonsterPack):
    current_pack = pack  # Store reference, don't own
```

## Defensive Stat Formulas (Path of Exile-Inspired)

The defensive calculation architecture follows ARPG standards, specifically Path of Exile's layered defense system. Sources: [Path of Exile 2 Defense Guide](https://www.sportskeeda.com/mmo/exile-2-poe2-defense-resistance-guide-energy-shield-armor-evasion), [Maxroll Defense Layering](https://maxroll.gg/poe/resources/defenses-and-defensive-layering), [PoE Wiki Armor](https://www.poewiki.net/wiki/Armour).

### Armor Formula
```
Damage Reduction = Armor / (Armor + 10 * Incoming Damage)
Final Damage = Incoming Damage * (1 - Damage Reduction)
```
**Characteristics**: Diminishing returns against large hits, very effective vs many small hits. Physical damage only.

### Evasion Formula
```
Avoid Chance = min(Evasion / 500, 0.75)  # Simplified, cap at 75%
```
**Characteristics**: Entropy-based (prevents lucky/unlucky streaks), downgrade crits to normal hits, works vs attacks not spells.

### Resistance Formula
```
Final Damage = Elemental Damage * (1 - min(Resistance, 75) / 100)
```
**Characteristics**: Linear reduction, hard cap at 75%, applies to fire/cold/lightning damage types.

### Energy Shield
Not a mitigation layer - acts as damage buffer before life. Absorbed in Hero.take_damage() before applying to health.

**Layer Order**: Armor → Evasion (chance to avoid) → Resistances → ES absorbs → Life damage

## Scaling Considerations

| Scale | Combat Architecture |
|-------|---------------------|
| **MVP (10 areas)** | Simple pack HP scaling (HP = base * area_level). Single damage type (physical). Basic combat loop. |
| **Mid (100 areas)** | Elemental damage types per pack. Resistance becomes valuable. Evasion entropy system. Pack variety (fast/slow packs). |
| **Late (300+ areas)** | All defensive layers required. Boss packs (unique modifiers). Map modifiers (increased pack damage/size). Multiple packs per screen (future). |

**First bottleneck**: Defensive calculations become complex (4+ layers). Mitigation: StatCalculator caches resistance caps, armor formula precomputed for common values.

**Second bottleneck**: Combat feels same across 300 areas. Mitigation: Pack modifiers ("Elemental", "Fast", "Armored"), boss encounters, map affixes.

## Sources

**Godot Architecture Patterns:**
- [Game Development Patterns with Godot 4](https://www.packtpub.com/en-us/product/game-development-patterns-with-godot-4-9781835880296)
- [Top Game Development Patterns in Godot Engine](https://www.manuelsanchezdev.com/blog/game-development-patterns)
- [GDQuest: Design patterns in Godot](https://www.gdquest.com/tutorial/godot/design-patterns/intro-to-design-patterns/)
- [Godot Finite State Machine Tutorial](https://www.gdquest.com/tutorial/godot/design-patterns/finite-state-machine/)

**State Management:**
- [Godot Resource Pattern for State Management](https://forum.godotengine.org/t/autoload-resource-singleton-for-keeping-and-saving-game-state/78981)
- [State Management in Godot with Vue.js Twist](https://tumeo.space/gamedev/2023/10/18/godot-states/)

**ARPG Defense Mechanics:**
- [Path of Exile 2 Defense and Resistance Guide](https://www.sportskeeda.com/mmo/exile-2-poe2-defense-resistance-guide-energy-shield-armor-evasion)
- [Path of Exile 2 Defences Explained](https://vulkk.com/2025/06/12/path-of-exile-2-defences-explained/)
- [Defenses and Defensive Layering in Path of Exile](https://maxroll.gg/poe/resources/defenses-and-defensive-layering)
- [PoE Wiki: Armour](https://www.poewiki.net/wiki/Armour)

**Damage Calculation Patterns:**
- [RPG Stats: Implementing Character Stats](https://howtomakeanrpg.com/r/a/how-to-make-an-rpg-stats.html)
- [RPG Damage Formula Wiki](https://rpg.fandom.com/wiki/Damage_Formula)

---
*Architecture research for: Hammertime v1.2 pack-based combat integration*
*Researched: 2026-02-16*
