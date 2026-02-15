# Phase 4: Signal-Based Communication - Research

**Researched:** 2026-02-15
**Domain:** Godot 4 signal architecture, node communication patterns
**Confidence:** HIGH

## Summary

Godot 4's signal system provides a robust decoupling mechanism following the "call down, signal up" architectural pattern. Parent nodes directly call methods on their children (going down the tree), while children emit signals to communicate upward without needing to know their parent's structure. This prevents brittle node path dependencies that break during refactoring.

The existing codebase already has GameEvents autoload in place with defined signals (equipment_changed, item_crafted, area_cleared), but views currently use direct get_node() calls to find siblings (hero_view, crafting_view, gameplay_view references). Phase 4 eliminates these cross-view get_node() calls and establishes clear signal flow.

**Primary recommendation:** Use GameEvents for cross-view communication, parent coordination for sibling signal connections, and @onready caching for all child node references.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Godot Engine | 4.x | Signal system built-in | Native engine feature, zero dependencies |
| GDScript | 2.0+ | Typed signal declarations | Native scripting language with first-class signal support |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| N/A | - | No external libraries needed | Signals are engine-native |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Signals | Direct method calls via references | Faster (~3x) but creates tight coupling, breaks when scene structure changes |
| Event bus (GameEvents) | Node groups with call_group() | Groups good for broadcasting to tagged nodes, signals better for specific connections |
| Parent coordination | Each child finds siblings via get_node() | Signals via parent = clearer ownership, easier to test, survives refactoring |

**Installation:**
No installation needed - signals are built into Godot Engine.

## Architecture Patterns

### Recommended Project Structure
```
scenes/
├── main_view.gd          # Parent coordinator - connects child signals
├── hero_view.gd          # Child - emits signals upward
├── crafting_view.gd      # Child - emits signals upward
└── gameplay_view.gd      # Child - emits signals upward

autoloads/
├── game_events.gd        # Global event bus for cross-scene signals
└── game_state.gd         # Global state (already exists)
```

### Pattern 1: Call Down, Signal Up
**What:** Parents call methods directly on children; children emit signals that parents connect to receivers
**When to use:** All parent-child communication in scene trees

**Example:**
```gdscript
# Parent (main_view.gd) - calls DOWN to children
@onready var hero_view: Node2D = $HeroView
@onready var crafting_view: Node2D = $CraftingView

func _ready() -> void:
    # Connect child signals (upward communication)
    crafting_view.item_finished.connect(_on_item_finished)
    hero_view.equipment_changed.connect(_on_equipment_changed)

func _on_item_finished(item: Item) -> void:
    # Call DOWN to hero_view directly
    hero_view.set_last_crafted_item(item)

# Child (crafting_view.gd) - signals UP to parent
signal item_finished(item: Item)

func finish_item() -> void:
    finished_item = current_item
    item_finished.emit(finished_item)  # Signal UP
```

### Pattern 2: Event Bus for Cross-Scene Communication
**What:** Global autoload singleton (GameEvents) broadcasts signals accessible from anywhere
**When to use:** Communication between distant nodes, runtime-instantiated components, or when event affects multiple unrelated systems

**Example:**
```gdscript
# autoloads/game_events.gd (already exists)
extends Node

signal equipment_changed(slot: String, item: Item)
signal item_crafted(item: Item)
signal area_cleared(area_level: int)

# Any view can emit
func equip_item(item: Item, slot: String) -> bool:
    GameState.hero.equip_item(item, slot)
    GameEvents.equipment_changed.emit(slot, item)  # Global broadcast
    return true

# Any view can listen
func _ready() -> void:
    GameEvents.equipment_changed.connect(_on_equipment_changed)
```

### Pattern 3: @onready Node Caching
**What:** Cache node references at _ready() time using @onready annotation
**When to use:** All child node references accessed more than once

**Example:**
```gdscript
# GOOD - cache with @onready
@onready var stats_label: Label = $StatsPanel/StatsLabel
@onready var weapon_slot: Button = $WeaponSlot

func update_stats_display() -> void:
    stats_label.text = "DPS: %.1f" % get_total_dps()  # Fast - cached reference

# BAD - repeated get_node() calls
func update_stats_display() -> void:
    $StatsPanel/StatsLabel.text = "DPS: %.1f" % get_total_dps()  # Slower - tree walk every time
    $StatsPanel/StatsLabel.modulate = Color.WHITE  # Tree walk again
```

### Pattern 4: Typed Signals (Godot 4 Syntax)
**What:** Declare signals with parameter types for compile-time checking
**When to use:** Always - provides IntelliSense and catches errors early

**Example:**
```gdscript
# Typed signal declarations
signal equipment_changed(slot: String, item: Item)
signal health_changed(new_health: float, max_health: float)
signal item_crafted(item: Item)

# Emit with .emit()
equipment_changed.emit("weapon", sword_item)

# Connect with callable
GameEvents.equipment_changed.connect(_on_equipment_changed)

func _on_equipment_changed(slot: String, item: Item) -> void:
    print("Equipped ", item.item_name, " to ", slot)
```

### Anti-Patterns to Avoid

- **Sibling get_node() calls:** `get_node("../GameplayView")` breaks when parent changes structure. Use parent coordination or event bus instead.

- **Upward tree traversal:** `get_parent().get_parent().get_node("SomeView")` creates brittle coupling. Emit signal upward and let parent route it.

- **Repeated get_node() in methods:** Performance waste and harder to refactor. Always cache with @onready.

- **Signal bubbling/forwarding:** Re-emitting child signals from parent creates tangled connection chains. Connect directly to final destination at parent level.

- **Direct method calls on siblings:** Even with cached references, creates hidden dependencies. Signals make data flow explicit.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cross-view messaging | Custom message queue system | Godot signals + event bus pattern | Signals handle connection management, disconnection, edge cases (null receivers, ready order) |
| Node reference management | Custom node registry/lookup | @onready caching + parent coordination | Engine handles lifecycle, memory, ready order automatically |
| Ready order coordination | Manual ready flags and polling | Signal connections in parent's _ready() | Parent is ready after all children, guaranteed by engine |
| Event filtering/routing | Custom dispatcher with handlers | Signal parameters + Callable bindings | Native bind() method passes extra data, no boilerplate needed |

**Key insight:** Godot's signal system already solves initialization order (children ready before parents), null safety (disconnected signals don't crash), and memory management (weak references). Custom solutions reimplement these poorly.

## Common Pitfalls

### Pitfall 1: Connecting Signals Before Nodes Are Ready
**What goes wrong:** Attempting to connect child signals in child's own _ready() fails because parent may not be ready yet.
**Why it happens:** _ready() executes children-first, parent-last. Child can't find parent or siblings reliably.
**How to avoid:** Always connect signals in the parent's _ready() function. Parent is guaranteed ready after all children.
**Warning signs:** "Node not found" errors, intermittent connection failures, order-dependent bugs.

**Code example:**
```gdscript
# WRONG - child tries to connect to sibling
# crafting_view.gd
func _ready() -> void:
    var gameplay_view = get_node_or_null("../GameplayView")  # May be null!
    if gameplay_view:
        item_crafted.connect(gameplay_view._on_item_crafted)

# RIGHT - parent connects siblings
# main_view.gd
func _ready() -> void:
    crafting_view.item_crafted.connect(gameplay_view._on_item_crafted)
```

### Pitfall 2: Using get_node() in Methods Instead of @onready
**What goes wrong:** Performance degradation in complex scenes, harder refactoring when paths change.
**Why it happens:** Developers test with simple scenes where repeated get_node() seems fine, then complexity grows.
**How to avoid:** Always cache node references with @onready at class level, never call get_node() inside methods.
**Warning signs:** FPS drops in complex UI, difficulty changing scene structure, scattered "$NodePath" calls.

**Code example:**
```gdscript
# WRONG - repeated tree traversal
func update_stats_display() -> void:
    $StatsPanel/StatsLabel.text = "DPS: %.1f" % dps
    $StatsPanel/StatsLabel.modulate = Color.WHITE
    if $StatsPanel/StatsLabel.visible:
        $StatsPanel/StatsLabel.size = Vector2(200, 50)

# RIGHT - cache once, use many times
@onready var stats_label: Label = $StatsPanel/StatsLabel

func update_stats_display() -> void:
    stats_label.text = "DPS: %.1f" % dps
    stats_label.modulate = Color.WHITE
    if stats_label.visible:
        stats_label.size = Vector2(200, 50)
```

### Pitfall 3: Direct Method Calls on Siblings via get_node()
**What goes wrong:** Tight coupling makes refactoring painful; changing scene structure breaks unrelated code.
**Why it happens:** Direct calls seem simpler than signals at first; "why add indirection when I can just call the method?"
**How to avoid:** Emit signal upward, let parent route to destination. Or use GameEvents for true cross-cutting concerns.
**Warning signs:** "notify_gameplay_of_equipment_change()" methods with get_node("../GameplayView"), fragile relative paths.

**Code example - from current codebase:**
```gdscript
# WRONG - current code in hero_view.gd (lines 286-292)
func notify_gameplay_of_equipment_change() -> void:
    var gameplay_view = get_node_or_null("../GameplayView")
    if gameplay_view == null:
        gameplay_view = get_node_or_null("GameplayView")  # Why two attempts?
    if gameplay_view and gameplay_view.has_method("refresh_clearing_speed"):
        gameplay_view.refresh_clearing_speed()

# RIGHT - signal approach
# hero_view.gd
signal equipment_changed()

func equip_item(item: Item, slot: String) -> bool:
    GameState.hero.equip_item(item, slot)
    equipment_changed.emit()  # Signal up
    return true

# main_view.gd (parent connects)
func _ready() -> void:
    hero_view.equipment_changed.connect(gameplay_view.refresh_clearing_speed)
```

### Pitfall 4: Forgetting to Cache @onready References Is Not Instant
**What goes wrong:** Accessing @onready vars before _ready() completes gives null references.
**Why it happens:** @onready variables initialize immediately before _ready() call, not at script construction.
**How to avoid:** Never access @onready variables in _init() or from constructors. Use them starting from _ready() onward.
**Warning signs:** Null pointer errors during initialization, "trying to access variable before ready" errors.

### Pitfall 5: Signal Performance Concerns Leading to Premature Optimization
**What goes wrong:** Developers avoid signals thinking they're "too slow", use direct calls, create coupling.
**Why it happens:** Misunderstanding performance characteristics - signals are ~3x slower than direct calls, but this means 2300 emissions = 1ms.
**How to avoid:** Use signals by default for decoupling. Only optimize to direct calls if profiling shows actual bottleneck (rare).
**Warning signs:** Premature "optimization" comments in code, lack of profiling data, coupling for unproven performance gains.

## Code Examples

Verified patterns from official sources and current codebase analysis:

### Declaring Typed Signals
```gdscript
# Source: Official Godot 4.4 docs + GDScript.com
extends Node2D

# Typed signals - parameter types enforced
signal item_finished(item: Item)
signal equipment_changed(slot: String, item: Item)
signal health_changed(new_health: float, max_health: float)
signal area_cleared(area_level: int)
```

### Connecting Signals in Parent _ready()
```gdscript
# Source: KidsCanCode Godot Recipes
# main_view.gd - parent coordinates children
extends Node2D

@onready var crafting_view: Node2D = $CraftingView
@onready var hero_view: Node2D = $HeroView
@onready var gameplay_view: Node2D = $GameplayView

func _ready() -> void:
    # Connect sibling communication through parent
    crafting_view.item_finished.connect(_on_item_finished)
    hero_view.equipment_changed.connect(gameplay_view.refresh_clearing_speed)
    gameplay_view.item_base_found.connect(crafting_view.add_item_to_inventory)

func _on_item_finished(item: Item) -> void:
    # Parent routes message to appropriate child
    hero_view.set_last_crafted_item(item)
```

### Emitting Signals from Children
```gdscript
# Source: Current codebase pattern (to be refactored)
# crafting_view.gd
extends Node2D

signal item_finished(item: Item)

func finish_item() -> void:
    finished_item = current_item
    item_finished.emit(finished_item)  # Signal UP to parent
    current_item = null
    update_label()
```

### Using Event Bus for Global Events
```gdscript
# Source: GDQuest Event Bus tutorial
# Any view can emit to GameEvents
func clear_area() -> void:
    if GameState.hero.is_healthy():
        var item_base = get_random_item_base()
        GameEvents.area_cleared.emit(area_level)  # Global broadcast

# Any view can listen to GameEvents
func _ready() -> void:
    GameEvents.area_cleared.connect(_on_area_cleared)
    GameEvents.equipment_changed.connect(_on_equipment_changed)

func _on_area_cleared(level: int) -> void:
    print("Hero cleared area level ", level)
```

### @onready Caching Pattern
```gdscript
# Source: Official Godot docs, GDQuest best practices
extends Node2D

# Cache all child node references
@onready var stats_label: Label = $StatsPanel/StatsLabel
@onready var weapon_slot: Button = $WeaponSlot
@onready var helmet_slot: Button = $HelmetSlot
@onready var clearing_timer: Timer = $ClearingTimer

func _ready() -> void:
    # Connect using cached references
    weapon_slot.pressed.connect(_on_weapon_slot_pressed)
    clearing_timer.timeout.connect(_on_clearing_timer_timeout)

func update_stats_display() -> void:
    # Use cached reference - fast, clean
    stats_label.text = "DPS: %.1f" % get_total_dps()
```

### Current Codebase Anti-Pattern (To Fix)
```gdscript
# Source: Current gameplay_view.gd (lines 16-23, 117-118, 136-137)
# ANTI-PATTERN - finding siblings via get_node()
func _ready() -> void:
    hero_view = get_node_or_null("../HeroView")
    if hero_view == null:
        hero_view = get_node_or_null("HeroView")

    crafting_view = get_node_or_null("../CraftingView")
    if crafting_view == null:
        crafting_view = get_node_or_null("CraftingView")

func clear_area() -> void:
    if crafting_view:
        crafting_view.set_new_item_base(item_base)  # Direct sibling call

func give_hammer_rewards() -> void:
    if crafting_view:
        crafting_view.add_hammers(implicit_hammers, prefix_hammers, suffix_hammers)  # Direct sibling call
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `emit_signal("signal_name", args)` | `signal_name.emit(args)` | Godot 4.0 | Cleaner syntax, first-class signal objects, better IntelliSense |
| Untyped signals | Typed signal parameters | Godot 4.0 | Type safety at parse time, catches errors early |
| `connect("signal", self, "method_name")` | `signal.connect(method_reference)` | Godot 4.0 | Uses Callable system, more flexible, supports lambdas |
| `$ operator` caching unclear | `@onready` explicit caching | Godot 4.0 | Clear intent, guaranteed ready order, better performance in complex scenes |

**Deprecated/outdated:**
- **String-based signal emit:** `emit_signal("clicked")` still works but `clicked.emit()` is preferred
- **String-based method names in connect:** `connect("pressed", self, "_on_pressed")` still works but `pressed.connect(_on_pressed)` is cleaner
- **Node groups for everything:** Groups still useful for broadcast, but signals better for specific connections

## Open Questions

1. **Should we use GameEvents for all cross-view communication, or only for truly global events?**
   - What we know: GameEvents already exists with equipment_changed, item_crafted, area_cleared signals
   - What's unclear: Whether equipment_changed is truly "global" or just hero_view -> gameplay_view communication
   - Recommendation: Use parent coordination for same-parent siblings (crafting/hero/gameplay all under main_view). Reserve GameEvents for events that affect multiple unrelated systems or cross-scene boundaries. Parent coordination is easier to trace and test.

2. **Do we need to add more signals to GameEvents, or should views define their own signals?**
   - What we know: Views currently call each other directly (set_last_crafted_item, set_new_item_base, add_hammers, refresh_clearing_speed)
   - What's unclear: Whether these should be view-specific signals or GameEvents signals
   - Recommendation: Views define their own signals (item_finished, equipment_changed). Parent coordinates. GameEvents only for events that truly need global scope.

3. **How should we handle the ready order issue with GameEvents signal connections?**
   - What we know: Prior decision states "GameEvents registered before GameState in autoload order to ensure signals available during GameState._ready()"
   - What's unclear: Whether views should connect to GameEvents in their own _ready() or if main_view should coordinate
   - Recommendation: Views can safely connect to GameEvents in their own _ready() because autoloads initialize before any scene. For sibling coordination, parent must do connections.

## Sources

### Primary (HIGH confidence)
- [Godot 4.4 Official Docs - Using Signals](https://docs.godotengine.org/en/4.4/getting_started/step_by_step/signals.html) - Signal syntax and connection methods
- [Godot 4.4 Official Docs - Singletons (Autoload)](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html) - Autoload initialization order
- [Kids Can Code - Node Communication](https://kidscancode.org/godot_recipes/4.x/basics/node_communication/index.html) - Call down/signal up pattern with concrete examples
- [GDQuest - Best Practices with Signals](https://www.gdquest.com/tutorial/godot/best-practices/signals/) - When to use signals, performance data (2300 emissions = 1ms)
- [GDQuest - Event Bus Singleton](https://www.gdquest.com/tutorial/godot/design-patterns/event-bus-singleton/) - Event bus pattern implementation and limitations
- [Go, Go, Godot - Call Down Signal Up](https://www.gogogodot.io/patterns/call-down-signal-up/) - Pattern explanation and encapsulation rationale

### Secondary (MEDIUM confidence)
- [Godot Forums - Best Practice for Sibling Nodes](https://forum.godotengine.org/t/best-practice-for-accessing-sibling-nodes/120942) - Community consensus on avoiding sibling get_node()
- [Godot Forums - Signal Performance](https://forum.godotengine.org/t/signals-better-or-worse-performance-wise/66819) - Performance comparison data
- [Godot Forums - @onready vs $ operator](https://godotforums.org/d/36658-difference-between-get-node-and-at-onready-var) - Caching best practices
- [GDScript.com - Signals in Godot](https://gdscript.com/solutions/signals-godot/) - Typed signal syntax examples

### Tertiary (LOW confidence)
- None - all findings verified with official documentation or multiple community sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Built-in Godot features, official documentation complete
- Architecture: HIGH - Patterns well-documented in official recipes and GDQuest tutorials
- Pitfalls: HIGH - Directly observable in current codebase + confirmed by community best practices
- Code examples: HIGH - Sourced from official docs and verified community tutorials

**Research date:** 2026-02-15
**Valid until:** ~90 days (Godot 4 stable, patterns unlikely to change significantly)
