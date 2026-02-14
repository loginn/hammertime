# Phase 2: Data Model Migration - Research

**Researched:** 2026-02-14
**Domain:** Godot 4.6 Resource system, autoload singletons, data architecture patterns
**Confidence:** HIGH

## Summary

This phase migrates game data classes from Node-based to Resource-based architecture. In Godot, Nodes represent scene tree entities with visual/behavioral aspects, while Resources are pure data containers optimized for serialization and reuse. The current codebase has Item, Weapon, Armor, Helmet, Boots, Ring, Affix, and Implicit classes all extending Node when they should extend Resource since they represent data without visual/scene tree requirements.

Godot 4.6 provides robust support for custom Resources via the `class_name` + `extends Resource` pattern. Resources are reference-counted, serializable, and can be nested for complex data structures. The autoload system enables globally accessible singletons for state management (GameState holding Hero instance) and event buses (GameEvents defining cross-scene signals).

The migration is straightforward: change `extends Node` to `extends Resource`, remove any Node-specific functionality (which doesn't exist in current code), and ensure no required parameters in `_init()` constructors (Godot's resource loader cannot pass constructor arguments). GameState and GameEvents autoloads are created as Node-based singletons and registered in project.godot.

**Primary recommendation:** Convert all data model classes to Resources, create Node-based GameState/GameEvents autoloads, verify through existing functionality tests.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Godot Engine | 4.6 | Game engine with built-in Resource system | Current project version, stable Resource implementation |
| GDScript | 2.0 (Godot 4.x) | Scripting language | Native to Godot 4.6, typed annotations with @export |

### Supporting
| Component | Purpose | When to Use |
|-----------|---------|-------------|
| Resource base class | Data-only classes requiring serialization | Item/equipment data, affixes, any pure data |
| Node base class | Scene tree entities, autoloads, managers | GameState, GameEvents, UI controllers |
| Autoload singleton | Global state and event buses | GameState (single Hero instance), GameEvents (signals) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Resource | RefCounted | RefCounted lacks built-in serialization, editor integration, save/load helpers |
| Autoload | Static class/singleton pattern | GDScript lacks true static classes; autoload is idiomatic Godot |
| Event bus | Direct signal connections | Direct connections create tight coupling across scene tree |

**Installation:**
```bash
# No installation needed - using Godot 4.6 built-in features
# Godot project already at 4.6 per project.godot
```

## Architecture Patterns

### Recommended Project Structure
```
models/
├── items/              # Item data classes (Resource)
├── affixes/            # Affix data classes (Resource)
└── hero.gd             # Hero data class (Resource after migration)

autoloads/
├── game_state.gd       # Global state singleton (Node)
├── game_events.gd      # Event bus singleton (Node)
├── item_affixes.gd     # Existing affix database (Node)
└── tag.gd              # Existing tag system (Node)
```

### Pattern 1: Custom Resource Classes
**What:** Data-only classes extending Resource with @export properties
**When to use:** Any game data that doesn't need scene tree presence (items, stats, configurations)
**Example:**
```gdscript
# Source: https://simondalvai.org/blog/godot-custom-resources/
class_name Item
extends Resource

@export var item_name: String
@export var tier: int
@export var implicit: Implicit
@export var prefixes: Array[Affix] = []
@export var suffixes: Array[Affix] = []
@export var valid_tags: Array[String]

# Methods work exactly like Node classes
func add_prefix() -> void:
    if len(self.prefixes) >= 3:
        return
    # ... logic
```

### Pattern 2: Autoload State Manager
**What:** Node-based singleton holding global game state
**When to use:** Single source of truth for player data, game progression
**Example:**
```gdscript
# Source: https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html
# autoloads/game_state.gd
extends Node

var hero: Hero  # Single hero instance accessible as GameState.hero

func _ready() -> void:
    hero = Hero.new()  # Initialize default hero

# Access from any script: GameState.hero.equip_item(item, "weapon")
```

### Pattern 3: Autoload Event Bus
**What:** Node-based singleton defining cross-scene signals
**When to use:** Decoupled communication between distant nodes (UI, gameplay, systems)
**Example:**
```gdscript
# Source: https://www.gdquest.com/tutorial/godot/design-patterns/event-bus-singleton/
# autoloads/game_events.gd
extends Node

signal equipment_changed(slot: String, item: Item)
signal item_crafted(item: Item)
signal area_cleared(area_level: int)

# Emit from anywhere: GameEvents.equipment_changed.emit("weapon", sword)
# Connect from anywhere: GameEvents.equipment_changed.connect(_on_equipment_changed)
```

### Pattern 4: Resource Instantiation
**What:** Creating Resource instances at runtime
**When to use:** Procedurally generated items, copying base items with modifications
**Example:**
```gdscript
# Source: https://simondalvai.org/blog/godot-custom-resources/
# Create new instance
var new_item: Item = Item.new()
new_item.item_name = "Iron Sword"
new_item.tier = 1

# Copy existing (shallow copy)
var copied_item = base_item.duplicate(false)

# Deep copy (duplicates @export sub-resources)
var deep_copied_item = base_item.duplicate(true)
```

### Anti-Patterns to Avoid

- **Required _init() parameters on Resources:** Godot's load() and editor instantiation cannot pass constructor arguments. Use optional parameters with defaults or separate create() methods.
  ```gdscript
  # BAD - will fail when loaded from editor or load()
  func _init(required_name: String):
      self.item_name = required_name

  # GOOD - optional parameters
  func _init(p_name: String = "Default"):
      self.item_name = p_name
  ```

- **Storing complex logic in Resources:** Resources are data containers. Heavy logic, scene tree interaction, and delta processing belong in Nodes.

- **Overusing event bus:** Not every signal needs to be global. Use direct parent-child signals when nodes have clear ownership relationship.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Global state management | Static variables, manual singleton | Autoload with Node | Godot manages lifecycle, integrates with scene tree, officially supported |
| Data serialization | Custom save/load JSON/binary | Resource with ResourceSaver/ResourceLoader | Built-in, handles nested resources, editor integration, type-safe |
| Cross-scene communication | Global signal dictionary, custom event system | Autoload event bus (Node with signals) | Idiomatic Godot, leverages native signal system, debuggable in editor |
| Resource instantiation | Manual object pooling for data classes | Resource.new() and duplicate() | Reference-counted, Godot manages memory, copy-on-write optimization |

**Key insight:** Godot's Resource and autoload systems are battle-tested for exactly these use cases. Custom solutions lose editor integration, debuggability, and framework optimizations.

## Common Pitfalls

### Pitfall 1: Resource.duplicate() Gotchas
**What goes wrong:** Calling `duplicate(true)` doesn't deep-copy subresources in Arrays/Dictionaries; also duplicates the script reference
**Why it happens:** Godot's duplicate implementation has known limitations with nested collections
**How to avoid:**
- For arrays of resources: manually iterate and duplicate each element
- Test duplication behavior before relying on it
- Consider if duplication is necessary (often Resources can be shared read-only)
**Warning signs:** Modified "copy" affects original; unexpected script duplication errors
**Sources:**
- https://github.com/godotengine/godot/issues/74918
- https://simondalvai.org/blog/godot-duplicate-resources/

### Pitfall 2: class_name Registration Issues
**What goes wrong:** Custom Resource class_name not appearing in editor's "New Resource" list or "Parser Error: Could not resolve class"
**Why it happens:** Godot caches class registrations; name conflicts with built-ins; duplicating scripts loses registration
**How to avoid:**
- Restart Godot editor after creating new class_name Resources
- Ensure unique class_name (check against Godot built-in class list)
- After duplicating scripts, modify class_name and re-save to trigger re-registration
**Warning signs:** Class not autocompleting, editor errors about unknown class, resource not in creation menu
**Sources:**
- https://github.com/godotengine/godot/issues/76380
- https://github.com/godotengine/godot/issues/84480

### Pitfall 3: Memory Leaks with Resources in Autoloads
**What goes wrong:** Resources stored in autoload singletons never get freed, accumulating memory
**Why it happens:** Autoloads persist entire game session; strong references prevent garbage collection
**How to avoid:**
- Design autoloads to hold minimal state (e.g., single Hero instance, not arrays of all items)
- Clear/reset resources when changing scenes or game states
- Use WeakRef for references that shouldn't prevent cleanup
**Warning signs:** Increasing memory usage over time, especially across scene transitions
**Sources:**
- https://forum.godotengine.org/t/conditions-that-cause-memory-leaks/95406
- https://medium.com/@dogabudak/from-scenetree-to-gdscript-how-godot-manages-objects-and-memory-23548ea3624e

### Pitfall 4: Autoload Must Extend Node
**What goes wrong:** Attempting to use Resource as autoload fails with cryptic errors
**Why it happens:** Godot's autoload system instantiates and adds to scene tree root, requiring Node base class
**How to avoid:**
- GameState and GameEvents MUST extend Node (even though they manage/emit about Resources)
- Resources like Hero are instantiated INSIDE the autoload Node, not as autoload themselves
**Warning signs:** "Cannot add child" errors, autoload not accessible globally
**Sources:**
- https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html
- https://forum.godotengine.org/t/autoload-resource-singleton-for-keeping-and-saving-game-state/78981

### Pitfall 5: Changing Node to Resource Breaks Scene References
**What goes wrong:** If a Node-based class is instantiated in .tscn files, converting to Resource breaks those scenes
**Why it happens:** Scenes expect Nodes; Resources cannot be added to scene tree
**How to avoid:**
- Verify class usage: grep for scene instantiation (.tscn files) before converting
- Current codebase: Item/Affix classes are instantiated via .new() in code, NOT in scenes - safe to convert
- Hero class instantiated in code via _init() - safe to convert
**Warning signs:** Scene load errors, missing nodes after conversion, "incompatible class" errors
**Sources:** Phase 1 file organization confirms no .tscn instantiation of data classes

## Code Examples

Verified patterns from official sources and community best practices:

### Creating Custom Resource (Item Example)
```gdscript
# Source: https://simondalvai.org/blog/godot-custom-resources/
# models/items/item.gd
class_name Item
extends Resource

@export var item_name: String
@export var implicit: Implicit
@export var prefixes: Array[Affix] = []
@export var suffixes: Array[Affix] = []
@export var tier: int
@export var valid_tags: Array[String]

# No _init with required parameters - use optional or none
func _init(p_name: String = "", p_tier: int = 1) -> void:
    self.item_name = p_name
    self.tier = p_tier

# All methods work identically to Node classes
func add_prefix() -> void:
    if len(self.prefixes) >= 3:
        print("Cannot add more prefixes - item already has 3")
        return
    # ... existing logic unchanged
```

### Creating Affix Resource
```gdscript
# Source: https://simondalvai.org/blog/godot-custom-resources/
# models/affixes/affix.gd
class_name Affix
extends Resource

enum AffixType { IMPLICIT, PREFIX, SUFFIX }

@export var affix_name: String
@export var type: AffixType
@export var min_value: int
@export var max_value: int
@export var value: int
@export var tier: int
@export var tags: Array[String]

# Optional parameters with defaults - safe for resource loading
func _init(
    p_name: String = "",
    p_type: AffixType = AffixType.PREFIX,
    p_min: int = 0,
    p_max: int = 10,
    p_tags: Array[String] = []
) -> void:
    self.affix_name = p_name
    self.type = p_type
    self.tags = p_tags
    self.tier = randi_range(1, 8)
    self.min_value = p_min * (9 - tier)
    self.max_value = p_max * (9 - tier)
    self.value = randi_range(self.min_value, self.max_value)

func reroll() -> void:
    self.value = randi_range(self.min_value, self.max_value)
```

### GameState Autoload
```gdscript
# Source: https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html
# autoloads/game_state.gd
extends Node
# NOTE: No class_name needed for autoloads - accessed via autoload name

var hero: Hero  # Single source of truth

func _ready() -> void:
    hero = Hero.new()
    print("GameState initialized with hero: ", hero.hero_name)

# Access from any script:
# GameState.hero.equip_item(sword, "weapon")
# var dps = GameState.hero.get_total_dps()
```

### GameEvents Autoload
```gdscript
# Source: https://www.gdquest.com/tutorial/godot/design-patterns/event-bus-singleton/
# autoloads/game_events.gd
extends Node

# Core gameplay signals
signal equipment_changed(slot: String, item: Item)
signal item_crafted(item: Item)
signal area_cleared(area_level: int)

# Usage from any script:
# Emit: GameEvents.equipment_changed.emit("weapon", new_sword)
# Connect: GameEvents.equipment_changed.connect(_on_equipment_changed)
```

### Registering Autoloads in project.godot
```ini
# Source: https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html
# Add to [autoload] section in project.godot
[autoload]

ItemAffixes="*res://autoloads/item_affixes.gd"
Tag="*res://autoloads/tag.gd"
GameState="*res://autoloads/game_state.gd"
GameEvents="*res://autoloads/game_events.gd"

# Asterisk (*) makes it a true singleton (cannot be instanced again)
# Order matters: earlier autoloads can be accessed by later ones in _ready()
```

### Using GameState and GameEvents Together
```gdscript
# Source: Community pattern synthesis
# Example: Equipment system using both autoloads

# In hero_view.gd or gameplay_view.gd
func _on_equip_button_pressed(item: Item, slot: String) -> void:
    # Update global state
    GameState.hero.equip_item(item, slot)

    # Notify other systems via event bus
    GameEvents.equipment_changed.emit(slot, item)

    # Other systems can react:
    # - UI updates hero stats display
    # - Sound system plays equip sound
    # - Achievement system checks for set bonuses
    # All without direct coupling
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Node-based data classes | Resource-based data classes | Godot 4.0+ recommendation | Better serialization, clearer architecture, no scene tree overhead |
| Manual singleton pattern | Autoload system | Godot 3.0+ | Framework-managed lifecycle, editor integration, consistent access |
| Global signals via groups | Event bus autoload | Community best practice ~2020+ | More maintainable, explicit signal definitions, easier debugging |
| @export (Godot 3) | @export annotation (Godot 4) | Godot 4.0 | Type hints required, clearer syntax, better autocomplete |

**Deprecated/outdated:**
- **Manual singleton static pattern:** GDScript lacks true static classes; autoload is idiomatic replacement
- **export keyword (Godot 3):** Replaced with @export annotation in Godot 4.x
- **resource_local_to_scene workaround:** Godot 4 improved duplicate() handling (though still has limitations)

## Open Questions

1. **Hero class migration timing**
   - What we know: Hero extends Node but has no Node-specific functionality
   - What's unclear: Whether Hero should migrate in Phase 2 or stay Node temporarily
   - Recommendation: Migrate Hero to Resource in Phase 2 AFTER Item/Affix migration verified working, since GameState needs to instantiate Hero.new()

2. **Implicit class keeps extending Affix or independent Resource?**
   - What we know: `class_name Implicit extends Affix` currently (1 line file)
   - What's unclear: Whether inheritance still makes sense after Resource conversion
   - Recommendation: Keep inheritance - Implicit IS-A Affix, just forced to IMPLICIT type. The relationship is semantically valid for Resources.

3. **Existing ItemAffixes autoload compatibility**
   - What we know: ItemAffixes.gd already exists as autoload with prefix/suffix arrays
   - What's unclear: Whether changing Affix to Resource breaks ItemAffixes initialization
   - Recommendation: Test ItemAffixes after Affix conversion - likely works unchanged since it just creates Affix instances via .new()

4. **Signal emission timing in autoload _ready()**
   - What we know: GameEvents autoload just defines signals
   - What's unclear: Can GameEvents signals be connected in other autoloads' _ready() given initialization order
   - Recommendation: GameEvents should be listed BEFORE GameState in project.godot autoload order; document that signal connections in _ready() are safe

## Sources

### Primary (HIGH confidence)
- [Godot 4.6 Singletons (Autoload) Official Docs](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html) - Autoload system specification
- [Godot 4.6 Resources Official Docs](https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html) - Resource system architecture
- [Godot 4.6 Resource Class Reference](https://docs.godotengine.org/en/stable/classes/class_resource.html) - API documentation
- [Simon Dalvai: Custom Resources in Godot 4.x](https://simondalvai.org/blog/godot-custom-resources/) - Practical examples with code
- [GDQuest: Event Bus Singleton Pattern](https://www.gdquest.com/tutorial/godot/design-patterns/event-bus-singleton/) - Event bus implementation

### Secondary (MEDIUM confidence)
- [Godot Forum: Autoload Resource Singleton Discussion](https://forum.godotengine.org/t/autoload-resource-singleton-for-keeping-and-saving-game-state/78981) - Community patterns
- [Godot Forum: When to Use Resource vs Node](https://forum.godotengine.org/t/when-should-you-use-resource-vs-node-script-with-export-var/96601) - Design guidance
- [Godot Tutorials: Custom Resources OP in Godot 4](https://ezcha.net/news/3-1-23-custom-resources-are-op-in-godot-4) - Migration benefits
- [Medium: From SceneTree to GDScript Memory Management](https://medium.com/@dogabudak/from-scenetree-to-gdscript-how-godot-manages-objects-and-memory-23548ea3624e) - Memory model understanding

### Tertiary (LOW confidence - known issues flagged for awareness)
- [Godot Issue #74918](https://github.com/godotengine/godot/issues/74918) - duplicate(true) doesn't deep-copy Arrays/Dictionaries
- [Godot Issue #76380](https://github.com/godotengine/godot/issues/76380) - class_name registration caching issues
- [Godot Issue #71625](https://github.com/godotengine/godot/issues/71625) - Resources with required _init params turn null
- [Godot Issue #84480](https://github.com/godotengine/godot/issues/84480) - Duplicate class_name prevents resource listing

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Using Godot 4.6 built-in features with official documentation
- Architecture: HIGH - Official docs + verified community patterns from GDQuest/Simon Dalvai
- Pitfalls: HIGH - Multiple source confirmation (official issues, forum discussions, blog posts)
- Code examples: HIGH - Sourced from official docs and established community educators

**Research date:** 2026-02-14
**Valid until:** 2026-03-14 (30 days - Godot 4.6 is stable, patterns are established)

**Key research notes:**
- Godot 4.6 has minimal breaking changes from 4.5 (primarily glow post-processing)
- Resource and autoload systems unchanged from 4.0-4.6
- Community consensus strong on Resource-for-data, Node-for-behavior separation
- Event bus pattern widely adopted as best practice for cross-scene communication
- Current codebase already uses typed GDScript, so @export migration is straightforward
