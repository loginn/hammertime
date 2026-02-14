# Feature Research

**Domain:** GDScript Codebase Refactoring (ARPG Idle Game)
**Researched:** 2026-02-14
**Confidence:** MEDIUM

## Feature Landscape

### Table Stakes (Core Refactoring Patterns)

Features that any comprehensive refactoring needs to address. Missing these = incomplete refactoring.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Unified Stat Calculation System | Eliminates duplicate compute_dps() logic across weapon.gd and ring.gd | MEDIUM | Resource-based stat modifiers with central calculation engine. Both Weapon and Ring call the same calculation pipeline. |
| Tag System Separation of Concerns | Tag.gd currently serves dual purposes (affix filtering AND damage calculation routing) | LOW | Split into TagFilter (item eligibility) and DamageType/StatType enums. Clear single-responsibility per constant set. |
| Proper Inheritance/Polymorphism Structure | Item subclasses share behavior but override methods inconsistently | LOW-MEDIUM | Define abstract update_value() contract in Item base class, standardize interface across all item types. |
| Signal-Based UI Communication | UI views use direct get_node() references causing tight coupling | MEDIUM | Implement "call down, signal up" pattern. Items emit stat_changed signals, UI components listen without direct references. |
| Directory Organization | All 21 .gd files in project root creates navigation/maintenance burden | LOW | Group by domain: items/, ui/, systems/, data/. Widely accepted as basic code hygiene. |
| Resource-Based Item Data | Currently items are Nodes, should be Resources for data-driven design | MEDIUM-HIGH | Migrate item definitions to custom Resources. Separates data from logic, enables inspector editing. |

### Differentiators (Advanced Refactoring Patterns)

Patterns that go beyond basic cleanup and improve architecture significantly.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Modifier Pipeline Architecture | Centralized stat modification system following order-of-operations (flat → increased → more) | HIGH | Industry-standard pattern from Path of Exile. Enables complex affix interactions without exponential code growth. Reference: Modular stat system with sequential modifier application. |
| Strategy Pattern for Damage Calculations | Different damage types (physical, elemental, DOT) use strategy objects instead of inline tag checking | MEDIUM | Eliminates if-chains in compute_dps(). Each DamageCalculationStrategy handles its own type. More extensible than current tag-checking approach. |
| Composition Over Deep Inheritance | Item behaviors defined by components/capabilities rather than rigid type hierarchy | HIGH | Prevents "weapon-that-is-also-armor" type problems. May be overkill for current scope. Godot community prefers pragmatic inheritance for simple cases. |
| Event Bus for Global State | Centralized signal routing through autoload singleton for hero stats, inventory changes | LOW-MEDIUM | Recommended by GDQuest for cases where direct connections create coupling. Alternative to direct signal wiring. |
| Stat Dependencies and Reactivity | Stats automatically recalculate when dependencies change (e.g., max_health affects health_percentage) | MEDIUM | Resource-based stats with getter properties. Prevents stale data bugs. Enables reactive UI updates. |

### Anti-Features (Commonly Requested, Often Problematic)

Refactoring approaches that seem good but create problems.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Full Entity-Component-System (ECS) | Composition over inheritance is mentioned frequently in game dev | Massive architectural rewrite, overkill for 5 item types, GDScript lacks ECS performance benefits that C++ engines get | Pragmatic inheritance with component-like Resource attachments for variable behavior |
| Over-Abstraction of Calculations | "Make everything configurable via data files" mentality | Premature generalization. Current game has ~10 affix types and 5 item types. Over-engineering before you understand requirements leads to wrong abstractions. | Start with shared base calculation, extract data when patterns emerge from real usage (Rule of Three) |
| Traits/Mixins via Scripts | GitHub proposal #6416 for trait system in GDScript | Not yet implemented in Godot 4.5. Relying on proposed features creates maintenance burden and migration work if never added or implemented differently. | Use composition with Resources and standard single inheritance |
| Immediate Type Safety Everywhere | Add type hints to all variables immediately | While valuable long-term, type hints don't provide performance benefits yet in GDScript. Refactoring for structure is higher priority than refactoring for types. | Add types to public APIs first (function parameters/returns), internal variables second |

## Feature Dependencies

```
Directory Organization
    └──enables──> Clear Module Boundaries
                      └──enables──> Proper Encapsulation

Tag System Separation
    └──unlocks──> Damage Strategy Pattern
                      └──requires──> Unified Stat Calculation

Unified Stat Calculation
    └──requires──> Modifier Pipeline (order-of-operations)
    └──enables──> Reactive Stat Updates

Resource-Based Item Data
    └──enables──> Data-Driven Design
    └──conflicts──> Current Node-Based Architecture (requires migration)

Signal-Based UI
    └──requires──> Event Emission Points in Systems
    └──enhances──> Reactive Stat Updates
```

### Dependency Notes

- **Tag System Separation unlocks Damage Strategy:** Cannot cleanly implement strategy pattern while tags serve dual purposes. Separation allows damage strategies to reference DamageType enum without conflating with affix eligibility.
- **Unified Stat Calculation requires Modifier Pipeline:** If weapon.gd and ring.gd both call shared calculate_dps(), that function needs to handle order-of-operations (flat bonuses before percentage bonuses). Otherwise moving logic to one place doesn't eliminate the complexity.
- **Resource-Based Item Data conflicts with Node-Based:** Current Item extends Node. Resources can't be scene tree members. Migration path: Item becomes ItemData (Resource), ItemInstance wraps ItemData as Node where needed.
- **Signal-Based UI requires Event Emission Points:** Hero.update_stats() must emit signals for UI to react. Dependency is not on refactored structure, but on instrumentation of existing systems.

## MVP Definition

### Launch With (Refactoring v1 - Core Cleanup)

Essential refactoring to eliminate immediate pain points.

- [x] **Directory Organization** — Creates clear boundaries before restructuring code. Foundational for all other work.
- [x] **Tag System Separation** — Eliminates dual-purpose confusion. Low-effort, high-clarity gain.
- [x] **Unified Stat Calculation System** — Primary goal: eliminate duplicate compute_dps() logic in weapon.gd and ring.gd. Core value of this refactoring milestone.
- [x] **Standardized Item Interface** — Define abstract update_value() contract in Item base class. Ensures all item types calculate stats consistently.
- [x] **Signal-Based UI Updates** — Break tight coupling between hero stats and UI. Enables testing and future UI changes.

### Add After Core Works (v1.x - Architectural Improvements)

Features to add once basic refactoring is validated and tests pass.

- [ ] **Modifier Pipeline Architecture** — Once unified calculation works, formalize order-of-operations (flat → increased → more). Trigger: when adding new affix types that interact in complex ways.
- [ ] **Strategy Pattern for Damage Types** — Once tag separation is done, implement strategies for physical/elemental/DOT. Trigger: when adding 3+ damage types with unique calculation rules.
- [ ] **Event Bus Singleton** — After signal-based UI is working with direct connections, consider centralizing if connection management becomes burdensome. Trigger: more than 10 signal connections causing spaghetti.

### Future Consideration (v2+ - Advanced Patterns)

Defer until current refactoring is complete and new requirements emerge.

- [ ] **Resource-Based Item Data** — Major migration from Node to Resource. Enables data-driven design and inspector editing. Defer: requires rewriting item instantiation, scene structure. Consider when adding item editor or external item definitions.
- [ ] **Composition Over Inheritance** — Component-based item capabilities. Defer: current 5 item types don't justify complexity. Consider if requirements emerge like "weapon-armor hybrid" or "stackable equipment".
- [ ] **Reactive Stat Dependencies** — Automatic recalculation when dependencies change. Defer: current manual update_stats() works. Consider when adding complex derived stats or performance issues from over-calculation.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Unified Stat Calculation | HIGH | MEDIUM | P1 |
| Tag System Separation | HIGH | LOW | P1 |
| Directory Organization | MEDIUM | LOW | P1 |
| Signal-Based UI | HIGH | MEDIUM | P1 |
| Standardized Item Interface | HIGH | LOW | P1 |
| Modifier Pipeline | MEDIUM | HIGH | P2 |
| Damage Strategy Pattern | MEDIUM | MEDIUM | P2 |
| Event Bus | LOW | LOW | P2 |
| Resource-Based Items | MEDIUM | HIGH | P3 |
| Composition Architecture | LOW | HIGH | P3 |
| Reactive Stat System | LOW | MEDIUM | P3 |

**Priority key:**
- P1: Must have for refactoring milestone completion
- P2: Should have, add when patterns emerge
- P3: Nice to have, future architectural evolution

## Implementation Patterns

### Pattern 1: Unified Stat Calculation

**Current Problem:** weapon.gd lines 18-64 and ring.gd lines 13-35 have nearly identical compute_dps() implementations. weapon.gd has more sophisticated tag checking (PHYSICAL + FLAT, PHYSICAL + PERCENTAGE) while ring.gd uses simpler tag matching (ATTACK, SPEED, CRITICAL).

**Solution Approach:**

```gdscript
# stat_calculator.gd (new system script)
class_name StatCalculator extends Node

static func calculate_dps(base_damage: int, base_speed: int, affixes: Array[Affix], base_crit_chance: float = 5.0, base_crit_damage: float = 150.0) -> float:
    # Centralized calculation logic
    # Order: flat damage → percentage damage → attack speed → crit
    pass

# weapon.gd (refactored)
func compute_dps() -> float:
    var affixes = self.prefixes + self.suffixes + [self.implicit]
    return StatCalculator.calculate_dps(base_damage, base_speed, affixes, crit_chance, crit_damage)

# ring.gd (refactored)
func compute_dps() -> float:
    var affixes = self.prefixes + self.suffixes + [self.implicit]
    return StatCalculator.calculate_dps(base_damage, base_speed, affixes, crit_chance, crit_damage)
```

**Why:** Eliminates duplication, centralizes ARPG calculation rules, makes testing easier. Based on modular stat system pattern from Medium article and GDQuest separation of concerns.

**Complexity:** MEDIUM - requires extracting logic, handling different tag interpretation between items, ensuring backward compatibility with current behavior.

**Sources:**
- [Modular Stat/Attribute System Tutorial for Godot 4](https://medium.com/@minoqi/modular-stat-attribute-system-tutorial-for-godot-4-0bac1c5062ce)
- [Godot Tactics RPG – 09. Stats](https://theliquidfire.com/2024/10/10/godot-tactics-rpg-09-stats/)

### Pattern 2: Tag System Separation

**Current Problem:** Tag.gd defines constants used for both:
1. Affix eligibility filtering (item.gd lines 74-77: "does this affix have a tag matching item.valid_tags?")
2. Damage calculation routing (weapon.gd lines 33-39: "if PHYSICAL and FLAT in tags, add to base damage")

**Solution Approach:**

```gdscript
# affix_tag.gd (affix eligibility)
class_name AffixTag extends Node
const WEAPON = "WEAPON"
const ARMOR = "ARMOR"
const DEFENSE = "DEFENSE"
const ATTACK = "ATTACK"

# stat_type.gd (calculation routing)
class_name StatType extends Node
const PHYSICAL_FLAT = "PHYSICAL_FLAT"
const PHYSICAL_PERCENT = "PHYSICAL_PERCENT"
const ATTACK_SPEED = "ATTACK_SPEED"
const CRIT_CHANCE = "CRIT_CHANCE"
const CRIT_DAMAGE = "CRIT_DAMAGE"

# affix.gd (updated)
var eligibility_tags: Array[String] = []  # for filtering
var stat_modifications: Array[StatModifier] = []  # for calculations
```

**Why:** Single Responsibility Principle. Affix filtering is about "what can roll on this item base" while stat calculation is about "how does this affix modify stats". They change for different reasons (adding new item types vs. adding new damage mechanics).

**Complexity:** LOW - mostly renaming and updating references. No algorithmic changes.

**Sources:**
- [GDScript Principles - Single Responsibility](https://this-is-envy.github.io/writing/gdscript.html)
- [SOLID Principles prevention strategy](https://www.bairesdev.com/blog/software-anti-patterns/)

### Pattern 3: Signal-Based UI Communication

**Current Problem:** UI views likely use get_node() to access hero stats, creating tight coupling. Changes to scene hierarchy break at runtime only.

**Solution Pattern: "Call Down, Signal Up"**

```gdscript
# hero.gd (emits changes)
signal stats_updated(stats: Dictionary)
signal health_changed(current: float, max: float)

func update_stats():
    calculate_dps()
    calculate_defense()
    calculate_crit_stats()
    stats_updated.emit({
        "dps": total_dps,
        "defense": total_defense,
        "crit_chance": total_crit_chance,
        "crit_damage": total_crit_damage
    })

func take_damage(damage: float):
    health -= damage
    health = max(0, health)
    health_changed.emit(health, max_health)
    # ...

# hero_view.gd (listens)
@onready var hero: Hero = get_node("../../Hero")  # cache on ready

func _ready():
    hero.stats_updated.connect(_on_hero_stats_updated)
    hero.health_changed.connect(_on_hero_health_changed)

func _on_hero_stats_updated(stats: Dictionary):
    dps_label.text = "DPS: %.1f" % stats.dps
    # ...
```

**Why:** Loose coupling. UI doesn't need to poll for changes. Hero doesn't need to know about UI structure. Enables multiple listeners without hero knowing.

**Complexity:** MEDIUM - requires adding signal emissions at all state change points, updating UI to listen instead of poll.

**Sources:**
- [Node communication (the right way) - Godot 4 Recipes](https://kidscancode.org/godot_recipes/4.x/basics/node_communication/index.html)
- [Godot Signals Complete Guide: Scene Communication Mastery](https://generalistprogrammer.com/tutorials/godot-signals-complete-guide-scene-communication)
- [Best practices with Godot signals - GDQuest](https://www.gdquest.com/tutorial/godot/best-practices/signals/)

### Pattern 4: Modifier Pipeline (Advanced)

**When to Implement:** After unified stat calculation is working, when adding affixes with complex interactions.

**Order-of-Operations Pattern:**

```gdscript
# stat_modifier.gd
class_name StatModifier extends Resource

enum ModifierType {
    FLAT,        # +50 damage
    INCREASED,   # +25% increased damage (additive with other increased)
    MORE,        # 30% more damage (multiplicative, separate)
}

var type: ModifierType
var value: float
var stat_name: String

# stat_calculator.gd
static func apply_modifiers(base_value: float, modifiers: Array[StatModifier]) -> float:
    # Phase 1: Flat additions
    var flat_sum = base_value
    for mod in modifiers:
        if mod.type == StatModifier.ModifierType.FLAT:
            flat_sum += mod.value

    # Phase 2: Increased (additive pool)
    var increased_sum = 0.0
    for mod in modifiers:
        if mod.type == StatModifier.ModifierType.INCREASED:
            increased_sum += mod.value
    flat_sum *= (1.0 + increased_sum / 100.0)

    # Phase 3: More (multiplicative)
    var final_value = flat_sum
    for mod in modifiers:
        if mod.type == StatModifier.ModifierType.MORE:
            final_value *= (1.0 + mod.value / 100.0)

    return final_value
```

**Why:** Prevents exponential power creep from stacking multipliers. Industry-standard pattern from Path of Exile, Diablo-likes. Allows "+25% increased damage" and "+25% increased damage" to combine as 50% (additive) rather than 56.25% (multiplicative).

**Complexity:** HIGH - requires refactoring affix system to emit StatModifiers instead of raw tags, updating all calculation paths to use pipeline.

**Sources:**
- [Modular Stat/Attribute System Tutorial for Godot 4](https://medium.com/@minoqi/modular-stat-attribute-system-tutorial-for-godot-4-0bac1c5062ce)
- Path of Exile modifier mechanics (common game dev knowledge, multiplicative vs increased distinction)

## Refactoring Threshold Rules

### When to Extract Shared Logic

**Rule of Three:** Don't abstract until code appears in 3 places. Currently weapon.gd and ring.gd = 2 instances. If a third damage-dealing item type is added, THEN extract. However, the duplication is substantial (47 lines in weapon.gd vs 23 in ring.gd covering same concepts), so extraction is justified.

**Source:** [My Thresholds for Refactoring - Coffee Brain Games](https://coffeebraingames.wordpress.com/2017/11/06/my-thresholds-for-refactoring/)

### When NOT to Refactor

**Stable Code:** If armor.gd update_value() (lines 11-32) works correctly and hasn't changed in months, leave it alone even if structure differs from weapon/ring. "If it ain't broke, don't fix it" applies when code isn't causing maintenance burden.

**Before Understanding:** Don't refactor calculation logic until you understand why weapon.gd uses `new_dps *= (1.0 + affix.value / 100.0)` (multiplicative) while ring.gd uses `new_spd += affix.value` (additive). Refactoring without understanding leads to breaking subtle intentional differences.

**Source:** [Refactoring: the Way to Perfection](https://www.gamedeveloper.com/programming/refactoring-the-way-to-perfection-)

## Anti-Pattern Warnings

### God Class/Object

**Risk:** Creating a CentralItemManager that handles item creation, stat calculation, affix rolling, display formatting, inventory management, etc.

**Prevention:** Keep StatCalculator focused on stat calculation only. Item creation stays in item factory. Display logic stays in items. Inventory management is separate system.

**Source:** [The God Class Intervention: Avoiding the All-Knowing Anti-Pattern in Game Development](https://www.wayline.io/blog/god-class-intervention-avoiding-anti-pattern)

### Premature Abstraction

**Risk:** Creating abstract "CalculationStrategy" interfaces before you have 3+ concrete strategies to learn from.

**Prevention:** Start with concrete StatCalculator.calculate_dps(). If adding elemental damage reveals different calculation path, THEN extract strategy interface from 2 working implementations.

**Source:** [Anti-patterns You Should Avoid in Your Code](https://www.freecodecamp.org/news/antipatterns-to-avoid-in-code/)

### Reinventing the Wheel

**Risk:** Creating custom modifier system when Godot Resource-based stats exist.

**Prevention:** Check GitHub for existing Godot 4 stat systems (EnhancedStat addon, inventory-system by expressobits) before building from scratch. Adapt existing patterns to your needs.

**Sources:**
- [EnhancedStat addon for Godot 4](https://github.com/Zennyth/EnhancedStat)
- [Modular inventory system for Godot 4](https://github.com/expressobits/inventory-system)

## Sources

### Godot-Specific Resources
- [GDScript style guide - Godot Engine](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- [A GDScript refactoring exercise - Go, Go, Godot!](https://www.gogogodot.io/refactoring-in-godot/)
- [Godot GDScript guidelines - GDQuest](https://gdquest.gitbook.io/gdquests-guidelines/godot-gdscript-guidelines)
- [Node communication (the right way) - Godot 4 Recipes](https://kidscancode.org/godot_recipes/4.x/basics/node_communication/index.html)
- [Best practices with Godot signals - GDQuest](https://www.gdquest.com/tutorial/godot/best-practices/signals/)
- [The Events bus singleton - GDQuest](https://www.gdquest.com/tutorial/godot/design-patterns/event-bus-singleton/)
- [Godot Signals Complete Guide: Scene Communication Mastery](https://generalistprogrammer.com/tutorials/godot-signals-complete-guide-scene-communication)

### Stat System Architecture
- [Modular Stat/Attribute System Tutorial for Godot 4](https://medium.com/@minoqi/modular-stat-attribute-system-tutorial-for-godot-4-0bac1c5062ce)
- [How is a complex RPG damage system typically done? - Godot Forum](https://forum.godotengine.org/t/how-is-a-complex-rpg-damage-system-typically-done/87174)
- [Godot Tactics RPG – 09. Stats](https://theliquidfire.com/2024/10/10/godot-tactics-rpg-09-stats/)
- [EnhancedStat addon - GitHub](https://github.com/Zennyth/EnhancedStat)

### Resource-Based Design
- [Resource-based architecture for Godot 4](https://medium.com/@sfmayke/resource-based-architecture-for-godot-4-25bd4b2d9018)
- [Creating and Using Custom Resources - Data-Driven Design in Godot Engine](https://uhiyama-lab.com/en/notes/godot/custom-resource-data-driven/)
- [Inventory System Design Fundamentals - Resource and Signals](https://uhiyama-lab.com/en/notes/godot/inventory-system/)
- [Custom Resources are OP in Godot 4](https://ezcha.net/news/3-1-23-custom-resources-are-op-in-godot-4)
- [Build Powerful and Scalable Inventories in Godot](https://dropc-gamestudio.com/concepts/build-powerful-and-scalable-inventories-in-godot/)

### Object-Oriented Design Patterns
- [Polymorphism in GDScript - Godot Forum](https://forum.godotengine.org/t/polymorphism-in-gdscript/27500)
- [Godot's Node System, Part 1: An OOP Overview](https://willnationsdev.wordpress.com/2018/04/05/godots-node-system-a-paradigm-overview/)
- [Inheritance, polymorphism, and more!](http://blog.moblcade.com/?p=59)
- [Class Inheritance - Godot GDScript Tutorial](https://godottutorials.com/courses/introduction-to-gdscript/godot-tutorials-gdscript-17/)

### Composition vs Inheritance
- [OOP: Inheritance or Components for an Item System - GameDev.net](https://www.gamedev.net/forums/topic/704545-oop-inheritance-or-components-for-an-item-system/)
- [Composition over Inheritance - Example in game development](https://www.ckhang.com/blog/2020/composition-over-inheritance/)
- [Composition vs. Inheritance: Boosting Game Performance with Component-Based Design](https://www.wayline.io/blog/composition-vs-inheritance-game-performance)
- [Prefer Composition over Implementation Inheritance](http://whats-in-a-game.com/prefer-composition-over-implementation-inheritance/)

### Design Patterns for Damage/Stats
- [Strategy Pattern - Composition over Inheritance](https://onewheelstudio.com/blog/2020/8/16/strategy-pattern-composition-over-inheritance)
- [Designing a data driven crafting system using tags - GameDev.net](https://www.gamedev.net/forums/topic/715034-designing-a-data-driven-crafting-system-using-tags/)
- [Essential Game Development Programming Patterns](https://medium.com/@chitranshnishad27/essential-game-development-programming-patterns-ebcf606d2ca9)
- [Game Programming Patterns - Table of Contents](https://gameprogrammingpatterns.com/contents.html)

### Refactoring Best Practices
- [Code Refactor and Game Polishing Advice - Godot Tutorials](https://godottutorials.com/courses/pong-gdscript-series/pong-gdscript-tutorial-14/)
- [Refactoring the Pong Game - Godot Tutorials](https://godottutorials.com/courses/pong-gdscript-series/pong-gdscript-tutorial-07/)
- [My Thresholds for Refactoring - Coffee Brain Games](https://coffeebraingames.wordpress.com/2017/11/06/my-thresholds-for-refactoring/)
- [Refactoring: the Way to Perfection - Game Developer](https://www.gamedeveloper.com/programming/refactoring-the-way-to-perfection-)

### Anti-Patterns to Avoid
- [The God Class Intervention: Avoiding the All-Knowing Anti-Pattern in Game Development](https://www.wayline.io/blog/god-class-intervention-avoiding-anti-pattern)
- [A Catalogue of Game-Specific Anti-Patterns - ACM](https://dl.acm.org/doi/abs/10.1145/3511430.3511436)
- [Top 5 Software Anti Patterns to Avoid](https://www.bairesdev.com/blog/software-anti-patterns/)
- [Anti-patterns You Should Avoid in Your Code](https://www.freecodecamp.org/news/antipatterns-to-avoid-in-code/)
- [6 Types of Anti Patterns to Avoid in Software Development](https://www.geeksforgeeks.org/blogs/types-of-anti-patterns-to-avoid-in-software-development/)

---
*Feature research for: Refactoring GDScript ARPG Codebase*
*Researched: 2026-02-14*
