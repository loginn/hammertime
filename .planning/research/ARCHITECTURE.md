# Architecture Research: Godot 4.5 ARPG Refactoring

**Domain:** Godot 4.5 ARPG Idle Game Refactoring
**Researched:** 2026-02-14
**Confidence:** HIGH

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Main Scene (Root)                        │
│  - Manages view switching                                    │
│  - Coordinates high-level communication                      │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────┐    ┌──────────┐    ┌──────────┐              │
│  │  Hero    │    │ Crafting │    │ Gameplay │              │
│  │  View    │    │  View    │    │  View    │              │
│  │ (Scene)  │    │ (Scene)  │    │ (Scene)  │              │
│  └────┬─────┘    └────┬─────┘    └────┬─────┘              │
│       │ signals       │ signals       │ signals             │
├───────┴───────────────┴───────────────┴─────────────────────┤
│                   Autoload Singletons                        │
│  (Global State, Constants, Event Bus)                        │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────┐    ┌──────────┐    ┌──────────┐              │
│  │  Hero    │    │  Item    │    │  Game    │              │
│  │ (Model)  │    │ (Model)  │    │  State   │              │
│  │ Resource │    │ Resource │    │ Resource │              │
│  └──────────┘    └──────────┘    └──────────┘              │
└─────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| **Views (Scenes)** | Display game state, handle UI interactions | Node2D/Control scenes with attached scripts |
| **Models (Resources/Classes)** | Store game data, business logic | Resource classes (serializable) or RefCounted classes |
| **Autoloads** | Global constants, shared state, event bus | Scripts registered in project settings |
| **Main Scene** | Coordinate view lifecycle, orchestrate communication | Root scene managing child view visibility |

## Current Architecture Analysis

### Existing Structure Issues

**Problem 1: Flat File Organization**
- All 21 .gd files in project root
- No logical grouping
- Hard to navigate and maintain

**Problem 2: Item Data as Nodes**
- Item extends Node but contains only data
- Anti-pattern: Nodes should handle behavior, not pure data
- Memory overhead and no built-in serialization

**Problem 3: Tight Coupling via get_node()**
- Views use `get_node_or_null("../HeroView")` for cross-communication
- Fragile: breaks if scene tree changes
- Prevents independent scene testing

**Problem 4: Hero Instance Passed by Reference**
- Hero created in hero_view.gd
- Manually passed to gameplay_view via property access
- No single source of truth
- Lifecycle management unclear

**Problem 5: View-Owned Business Logic**
- Equipment logic in hero_view.gd
- Crafting logic in crafting_view.gd
- Should be in model layer

## Recommended Project Structure

```
res://
├── autoload/              # Singleton scripts
│   ├── game_state.gd      # Global game state manager
│   ├── game_events.gd     # Event bus for cross-scene signals
│   └── item_registry.gd   # Item definitions & affix data (renamed from ItemAffixes)
│
├── models/                # Data models (Resources/Classes)
│   ├── hero/
│   │   ├── hero.gd        # Hero data class (RefCounted or Resource)
│   │   └── hero_stats.gd  # Stats calculation logic
│   ├── items/
│   │   ├── item.gd        # Base item (Resource, not Node)
│   │   ├── weapon.gd      # Weapon subclass
│   │   ├── armor.gd       # Armor subclass
│   │   ├── helmet.gd      # Helmet subclass
│   │   ├── boots.gd       # Boots subclass
│   │   ├── ring.gd        # Ring subclass
│   │   └── affixes/
│   │       ├── affix.gd       # Base affix
│   │       └── implicit.gd    # Implicit affix
│   └── items/concrete/    # Concrete item implementations
│       ├── light_sword.gd
│       ├── basic_armor.gd
│       ├── basic_helmet.gd
│       ├── basic_boots.gd
│       └── basic_ring.gd
│
├── scenes/                # Scene files and view scripts
│   ├── main/
│   │   ├── main.tscn          # Root scene
│   │   └── main_view.gd       # Main orchestration script
│   ├── hero/
│   │   ├── hero_view.tscn     # Hero equipment UI
│   │   └── hero_view.gd       # Hero view controller
│   ├── crafting/
│   │   ├── crafting_view.tscn # Crafting UI
│   │   └── crafting_view.gd   # Crafting view controller
│   └── gameplay/
│       ├── gameplay_view.tscn # Adventure UI
│       └── gameplay_view.gd   # Gameplay view controller
│
├── utils/                 # Helper classes
│   └── constants.gd       # Game constants (renamed from Tag.gd)
│
└── project.godot
```

### Structure Rationale

- **autoload/**: Globally accessible singletons for shared state and event coordination
- **models/**: Pure data and business logic, separated from presentation (Resources for serialization, RefCounted for runtime-only)
- **scenes/**: Each scene grouped with its view controller script, organized by feature
- **utils/**: Helper scripts that don't fit elsewhere

## Architectural Patterns

### Pattern 1: Model-View Separation

**What:** Separate data/logic (Model) from presentation (View). Models are Resources or RefCounted classes. Views are Nodes that display model state.

**When to use:** Always for maintainable projects. Critical when data needs to persist, be serialized, or be tested independently.

**Trade-offs:**
- **Pros:** Testable logic, reusable models, serializable game state, clear separation of concerns
- **Cons:** More initial setup, need to coordinate model-view updates

**Example:**
```gdscript
# models/hero/hero.gd (Resource for serialization)
class_name Hero extends Resource

@export var hero_name: String = "Adventurer"
@export var max_health: float = 100.0
@export var health: float = 100.0
@export var equipped_items: Dictionary = {}

func equip_item(item: Item, slot: String) -> void:
    equipped_items[slot] = item
    emit_changed()  # Resource signal for observers

func get_total_dps() -> float:
    var total := 0.0
    if equipped_items.has("weapon") and equipped_items["weapon"]:
        total += equipped_items["weapon"].dps
    if equipped_items.has("ring") and equipped_items["ring"]:
        total += equipped_items["ring"].dps
    return total

# scenes/hero/hero_view.gd (View displays Hero state)
extends Node2D

var hero: Hero  # Reference to model

func _ready() -> void:
    hero = GameState.hero  # Get from singleton
    hero.changed.connect(_on_hero_changed)  # Listen to model updates
    _update_display()

func _on_hero_changed() -> void:
    _update_display()

func _update_display() -> void:
    $StatsLabel.text = "DPS: %.1f" % hero.get_total_dps()
```

### Pattern 2: Signal-Based Communication (Call Down, Signal Up)

**What:** Parent nodes access children via `get_node()` or `@onready` variables. Children signal up to parents. Siblings communicate through common parent.

**When to use:** All node-to-node communication. This is the Godot way.

**Trade-offs:**
- **Pros:** Decoupled, portable scenes, testable in isolation
- **Cons:** More verbose than direct calls, requires thinking about hierarchy

**Example:**
```gdscript
# scenes/crafting/crafting_view.gd (Child emits signal)
extends Node2D

signal item_crafted(item: Item)

func _on_finish_button_pressed() -> void:
    var item = _create_finished_item()
    item_crafted.emit(item)  # Signal up

# scenes/main/main_view.gd (Parent coordinates)
extends Node2D

@onready var crafting_view: Node2D = $CraftingView
@onready var hero_view: Node2D = $HeroView

func _ready() -> void:
    # Connect sibling communication through parent
    crafting_view.item_crafted.connect(_on_item_crafted)

func _on_item_crafted(item: Item) -> void:
    # Update shared state
    GameState.last_crafted_item = item
    # Notify other views via signals or direct call (we're the parent)
    hero_view.set_craftable_item(item)
```

### Pattern 3: Event Bus for Distant Communication

**What:** Autoload singleton with signals for cross-scene, loosely-coupled communication.

**When to use:** When nodes are far apart in scene tree OR across different scene files. Avoid for parent-child or close relatives.

**Trade-offs:**
- **Pros:** Zero coupling, works across any scene structure
- **Cons:** Harder to debug (global signal tracking), can become a dumping ground for unrelated signals

**Example:**
```gdscript
# autoload/game_events.gd
extends Node

# Equipment events
signal equipment_changed(hero: Hero)
signal item_equipped(item: Item, slot: String)

# Crafting events
signal item_crafted(item: Item)
signal hammers_gained(implicit: int, prefix: int, suffix: int)

# Gameplay events
signal area_cleared()
signal hero_died()

# autoload/game_state.gd
extends Node

var hero: Hero
var last_crafted_item: Item = null

func _ready() -> void:
    hero = Hero.new()
    hero.equipped_items = {
        "weapon": null,
        "helmet": null,
        "armor": null,
        "boots": null,
        "ring": null
    }

# scenes/hero/hero_view.gd (Listener)
func _ready() -> void:
    GameEvents.item_crafted.connect(_on_item_crafted)

func _on_item_crafted(item: Item) -> void:
    # React to crafted item from anywhere

# scenes/gameplay/gameplay_view.gd (Emitter)
func _on_area_cleared() -> void:
    GameEvents.area_cleared.emit()  # Any scene can listen
```

### Pattern 4: @onready and @export for Node References

**What:** Use `@onready` to cache node references. Use `@export` to assign nodes in Inspector.

**When to use:** Always for performance and robustness. Avoids repeated `get_node()` calls.

**Trade-offs:**
- **Pros:** Faster (one lookup), clearer dependencies, less error-prone
- **Cons:** Slightly more verbose

**Example:**
```gdscript
extends Node2D

# @onready caches child references at _ready()
@onready var stats_label: Label = $StatsPanel/StatsLabel
@onready var weapon_slot: Button = $WeaponSlot

# @export allows Inspector assignment (best for flexibility)
@export var inventory_panel: Control

func _ready() -> void:
    weapon_slot.pressed.connect(_on_weapon_slot_pressed)
    stats_label.text = "Ready"
```

### Pattern 5: Resources for Data, Nodes for Behavior

**What:** Use Resource classes for pure data (items, stats, config). Use Nodes for things that need scene tree access or rendering.

**When to use:**
- **Resource:** Data that should serialize (save/load), doesn't need _process(), no visual representation
- **Node:** Needs rendering, physics, scene tree access, frame updates

**Trade-offs:**
- **Resources Pros:** Built-in serialization, lightweight, editor-friendly
- **Resources Cons:** No scene tree access, no _process() callbacks
- **Nodes Pros:** Full engine features, scene integration
- **Nodes Cons:** Memory overhead, not designed for pure data

**Example:**
```gdscript
# models/items/item.gd (Resource - pure data)
class_name Item extends Resource

@export var item_name: String
@export var tier: int
@export var implicit: Implicit
@export var prefixes: Array[Affix] = []
@export var suffixes: Array[Affix] = []

func add_prefix() -> void:
    # Business logic is fine in Resources
    if prefixes.size() >= 3:
        return
    var new_prefix = _select_valid_prefix()
    if new_prefix:
        prefixes.append(new_prefix)
        emit_changed()  # Built-in Resource signal

# models/items/weapon.gd (Resource - weapon data)
class_name Weapon extends Item

@export var base_damage: int = 10
@export var base_speed: float = 1.0
@export var dps: float = 10.0
@export var crit_chance: float = 5.0
@export var crit_damage: float = 150.0

func update_dps() -> void:
    dps = base_damage * base_speed
    emit_changed()
```

## Data Flow

### Equipment Flow

```
User clicks slot in HeroView
    ↓
HeroView.gd: _on_slot_clicked()
    ↓
GameState.hero.equip_item(item, slot)  # Model update
    ↓
Hero emits changed signal
    ↓
HeroView._on_hero_changed() updates UI
    ↓
GameEvents.equipment_changed.emit(hero)  # Notify distant listeners
    ↓
GameplayView receives signal, updates clearing speed
```

### Crafting Flow

```
User clicks hammer in CraftingView
    ↓
CraftingView: apply_affix_to_item()
    ↓
Item.add_prefix() (model logic)
    ↓
Item emits changed signal
    ↓
CraftingView._on_item_changed() updates item display
    ↓
User clicks "Finish Item"
    ↓
CraftingView.item_crafted.emit(item)  # Signal to parent
    ↓
MainView receives signal, updates GameState.last_crafted_item
    ↓
GameEvents.item_crafted.emit(item)  # Global notification
    ↓
HeroView receives, enables equipping
```

### State Management

```
┌──────────────┐
│  GameState   │  (Autoload - single source of truth)
│  - hero      │
│  - inventory │
└──────┬───────┘
       │ (reads/writes)
       ↓
┌──────────────┐       signals        ┌──────────────┐
│  Models      │  ←─────────────────→  │  Views       │
│  (Resources) │                       │  (Nodes)     │
└──────────────┘                       └──────────────┘
       ↑                                      ↑
       │                                      │
       └────────── GameEvents.signal ─────────┘
           (distant communication)
```

### Key Data Flows

1. **Hero State Flow:** GameState.hero (source of truth) → Views observe via signals → Views update UI
2. **Cross-View Communication:** View A emits signal → MainView coordinates OR GameEvents relays → View B reacts
3. **Persistence:** Resources auto-serialize → ResourceSaver.save(hero, "user://save.tres") → ResourceLoader.load("user://save.tres")

## Decision Framework

### Signals vs Direct Calls vs Autoload

| Scenario | Solution | Rationale |
|----------|----------|-----------|
| Parent needs child data | Direct call down: `$ChildNode.get_data()` | Performance, clarity |
| Child needs parent action | Signal up: `signal_name.emit()`, parent connects | Decoupling |
| Sibling communication | Signal to parent, parent coordinates | Maintains hierarchy |
| Distant/cross-scene | Event bus (GameEvents autoload) | Zero coupling |
| Shared state access | GameState autoload with properties | Single source of truth |

### Resource vs Node vs RefCounted

| Need | Use | Example |
|------|-----|---------|
| Serializable data | Resource | Item, Hero, SaveData |
| Runtime-only data | RefCounted class | Temporary calculations, builders |
| Visual representation | Node (Control, Node2D) | UI elements, sprites |
| Physics/collision | Node (CharacterBody2D, Area2D) | Player, enemies |
| Frame updates | Node with _process() | Animation controllers |

### Autoload vs Scene Instance

| Use Autoload When | Use Scene Instance When |
|-------------------|-------------------------|
| Truly global (one instance ever) | Multiple instances needed |
| Cross-scene persistence | Scene-specific lifecycle |
| Event bus, constants | UI views, gameplay entities |
| Example: GameState, GameEvents | Example: HeroView, EnemySpawner |

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 0-10 scenes | Simple structure fine, minimal abstraction |
| 10-50 scenes | Introduce event bus, consistent folder structure critical |
| 50+ scenes | Modular architecture with feature-based organization, consider addons for reusable systems |

### Scaling Priorities

1. **First bottleneck:** get_node() fragility as scene tree evolves
   - **Fix:** Switch to @onready caching and signal-based communication early

2. **Second bottleneck:** Cluttered autoloads with mixed concerns
   - **Fix:** Split into domain-specific autoloads (GameState, GameEvents, ItemRegistry)

3. **Third bottleneck:** Duplicate logic across views
   - **Fix:** Extract to model layer (Resources/RefCounted) or service classes

## Anti-Patterns

### Anti-Pattern 1: Nodes for Pure Data

**What people do:** `class_name Item extends Node` with only data properties

**Why it's wrong:**
- Nodes have process overhead (even if not using _process)
- No built-in serialization (must write custom save/load)
- Memory inefficient
- Misleading (Nodes imply behavior)

**Do this instead:**
```gdscript
# WRONG
class_name Item extends Node
var item_name: String
var damage: int

# RIGHT
class_name Item extends Resource
@export var item_name: String
@export var damage: int
# Resources auto-serialize with ResourceSaver/Loader
```

### Anti-Pattern 2: get_parent() Chains

**What people do:**
```gdscript
get_parent().get_parent().get_node("UI/HealthBar")
get_node("../SiblingNode/ChildNode")
```

**Why it's wrong:**
- Fragile: breaks when hierarchy changes
- Prevents scene reuse/testing
- Violates encapsulation

**Do this instead:**
```gdscript
# For siblings: signal to parent, parent coordinates
signal health_changed(new_health: int)
# Parent connects: player.health_changed.connect(ui.update_health)

# For distant nodes: event bus
GameEvents.health_changed.emit(new_health)
```

### Anti-Pattern 3: Autoload Overuse

**What people do:** Put everything in autoloads because "it's easier to access"

**Why it's wrong:**
- Global state makes debugging hard
- Memory never freed
- Tight coupling across entire codebase
- Hard to test

**Do this instead:**
- **Autoload:** Only for truly global systems (GameState, GameEvents, constants)
- **Scene instances:** For most gameplay logic
- **Dependency injection:** Pass references via exported variables or signals

### Anti-Pattern 4: Logic in View Scripts

**What people do:** Implement game rules, calculations, and state management in `hero_view.gd`, `crafting_view.gd`

**Why it's wrong:**
- Can't test logic without UI
- Can't reuse logic (e.g., headless server, different UI)
- Violates separation of concerns

**Do this instead:**
```gdscript
# WRONG: Logic in view
# hero_view.gd
func equip_item(item: Item, slot: String):
    if item is Weapon and slot == "weapon":
        hero.weapon = item
        hero.dps = calculate_dps()  # Logic in view

# RIGHT: Logic in model
# models/hero/hero.gd
func equip_item(item: Item, slot: String) -> bool:
    if not _can_equip(item, slot):
        return false
    equipped_items[slot] = item
    _recalculate_stats()  # Model owns logic
    emit_changed()
    return true

# scenes/hero/hero_view.gd (View just coordinates)
func _on_slot_clicked(slot: String):
    var success = GameState.hero.equip_item(last_item, slot)
    if success:
        _update_display()
```

### Anti-Pattern 5: No Single Source of Truth

**What people do:**
```gdscript
# hero_view.gd
var hero: Hero = Hero.new()

# gameplay_view.gd
var hero: Hero  # Gets passed from hero_view
```

**Why it's wrong:**
- Multiple sources of truth
- Lifecycle management unclear
- Easy to have stale references

**Do this instead:**
```gdscript
# autoload/game_state.gd
var hero: Hero

func _ready():
    hero = Hero.new()
    # Single authoritative instance

# All views access same instance
func _ready():
    var hero = GameState.hero
```

## Integration Points

### Current System to Refactored

| Current Component | New Component | Migration Path |
|-------------------|---------------|----------------|
| hero_view.gd (owns Hero instance) | GameState autoload owns Hero | Move Hero creation to GameState._ready() |
| item.gd extends Node | item.gd extends Resource | Change base class, remove from scene tree, use model layer |
| get_node_or_null("../CraftingView") | GameEvents signal or parent coordination | Add signals, connect in parent (main_view.gd) |
| ItemAffixes autoload | ItemRegistry autoload | Rename, keep functionality |
| Tag autoload | Constants class | Move to utils/constants.gd, not autoload unless needed globally |
| hero_view equip logic | Hero.equip_item() in model | Move method to Hero class |
| crafting_view hammer counts | CraftingState (in GameState or Resource) | Extract to state object |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| View ↔ Model | Views read model, subscribe to changed signal | Models never know about views |
| View ↔ View (siblings) | Signal to parent OR event bus | Never direct get_node to sibling |
| View ↔ Autoload | Direct property access for reads, signals for writes | Autoload can emit signals views connect to |
| Model ↔ Autoload | Autoload owns model instances | Models stored in GameState |

## Refactoring Build Order

### Phase 1: Foundation (Models & Autoloads)
1. Create folder structure: `models/`, `autoload/`, `scenes/`, `utils/`
2. Create `autoload/game_state.gd` and register as autoload
3. Create `autoload/game_events.gd` with initial signals
4. Convert `item.gd` and subclasses from Node to Resource
5. Move Hero creation to GameState
6. Rename/move ItemAffixes to `autoload/item_registry.gd`
7. Move Tag to `utils/constants.gd` (remove autoload if not needed)

### Phase 2: Model Logic Extraction
1. Move equip/unequip logic from hero_view.gd to Hero class
2. Move crafting logic from crafting_view.gd to Item/CraftingState
3. Extract stat calculations to Hero model

### Phase 3: Scene Organization
1. Move scene files to `scenes/[feature]/`
2. Move view scripts alongside their .tscn files
3. Update scene paths in main.tscn

### Phase 4: Communication Refactor
1. Replace get_node_or_null("../OtherView") with signals
2. Connect sibling signals in main_view.gd
3. Add GameEvents emissions for distant communication
4. Convert @onready for child node references

### Phase 5: Testing & Polish
1. Test each view independently
2. Verify serialization works (save/load Hero)
3. Remove old/unused code
4. Document signal contracts

## Sources

**Official Godot Documentation (HIGH Confidence):**
- [Scene organization — Godot Engine (stable)](https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html)
- [Autoloads versus regular nodes — Godot Engine (stable)](https://docs.godotengine.org/en/stable/tutorials/best_practices/autoloads_versus_internal_nodes.html)
- [Using signals — Godot Engine (stable)](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html)
- [Singletons (Autoload) — Godot Engine (stable)](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html)
- [Project organization — Godot Engine (stable)](https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html)
- [Resources — Godot Engine (stable)](https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html)

**Community Best Practices (MEDIUM Confidence):**
- [Node communication (the right way) :: Godot 4 Recipes](https://kidscancode.org/godot_recipes/4.x/basics/node_communication/)
- [Best practices with Godot signals · GDQuest](https://www.gdquest.com/tutorial/godot/best-practices/signals/)
- [The Events bus singleton · GDQuest](https://www.gdquest.com/tutorial/godot/design-patterns/event-bus-singleton/)
- [When to Node, Resource, and Class in Godot](https://backat50ft.substack.com/p/when-to-node-resource-and-class-in)
- [MVC in Godot | Rads and Relics](https://radsandrelics.com/posts/godot-mvc/)

**GitHub Resources (MEDIUM Confidence):**
- [godot-architecture-organization-advice](https://github.com/abmarnie/godot-architecture-organization-advice)

---
*Architecture research for: Godot 4.5 ARPG Idle Game Refactoring*
*Researched: 2026-02-14*
