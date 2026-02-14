# Architecture Research

**Domain:** ARPG Item Rarity & Crafting Currency System
**Researched:** 2026-02-14
**Confidence:** HIGH

## Integration Architecture Overview

```
┌────────────────────────────────────────────────────────────────┐
│                         UI Layer                                │
├────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │ CraftingView │  │  HeroView    │  │ GameplayView │         │
│  │              │  │              │  │              │         │
│  │ - currency   │  │ - equipped   │  │ - drop logic │         │
│  │   buttons    │  │   items      │  │ - hammer     │         │
│  │ - validation │  │              │  │   rewards    │         │
│  └──────┬───────┘  └──────────────┘  └──────┬───────┘         │
│         │                                    │                 │
├─────────┴────────────────────────────────────┴─────────────────┤
│                      Domain Logic                               │
├────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────┐      │
│  │            Item (with rarity property)               │      │
│  │    Weapon, Armor, Helmet, Boots, Ring (unchanged)   │      │
│  └──────────────────────────────────────────────────────┘      │
│                                                                 │
│  ┌──────────────────────────────────────────────────────┐      │
│  │         CurrencyValidator (new static class)         │      │
│  │  - can_apply_to_item(currency, item) -> bool         │      │
│  │  - get_error_message(currency, item) -> String       │      │
│  └──────────────────────────────────────────────────────┘      │
├────────────────────────────────────────────────────────────────┤
│                        Data Layer                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                     │
│  │ Currency │  │ ItemDrop │  │ ItemAff- │                     │
│  │ Manager  │  │ Manager  │  │ ixes     │                     │
│  │(autoload)│  │(autoload)│  │(existing)│                     │
│  └──────────┘  └──────────┘  └──────────┘                     │
└────────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | Implementation Type |
|-----------|----------------|---------------------|
| **ItemRarity enum** | Define rarity tiers (Normal/Magic/Rare) | Enum in Item.gd |
| **CurrencyType enum** | Define 6 currency types | Enum in new autoload |
| **CurrencyManager** | Track currency counts globally | Autoload singleton |
| **CurrencyValidator** | Validate currency application rules | Static utility class |
| **ItemDropManager** | Determine item rarity based on area level | Autoload singleton |
| **Item.rarity** | Store current rarity state | New property on Item |
| **Item.get_max_affixes()** | Return max prefix/suffix based on rarity | New method on Item |
| **crafting_view.gd** | Replace hammer buttons with currency buttons | Modified existing |
| **gameplay_view.gd** | Use ItemDropManager for rarity-aware drops | Modified existing |

## New Components Required

### 1. CurrencyManager Autoload

**Purpose:** Centralized global currency state management

**File:** `currency_manager.gd`

**Responsibilities:**
- Track counts of 6 hammer currencies
- Provide add/subtract methods
- Emit signals on currency changes
- Persist currency counts across scenes

**Why Autoload:** Currency is global state that persists across scene transitions and needs to be accessible from CraftingView (consumption) and GameplayView (rewards).

**Rationale:** [Godot's autoload singleton pattern](https://docs.godotengine.org/en/latest/tutorials/scripting/singletons_autoload.html) is designed for exactly this use case - "elements that need to be shared and managed game-wide" including "player score, money, lives, and inventory."

### 2. ItemDropManager Autoload

**Purpose:** Rarity-weighted item generation

**File:** `item_drop_manager.gd`

**Responsibilities:**
- Calculate rarity weights based on area level
- Roll random rarity for new item drops
- Return ItemRarity enum value

**Why Autoload:** Drop logic is stateless utility that needs to be accessed from GameplayView. While this could be a static class, using autoload provides consistency with other managers and allows future extension (e.g., adding drop rate modifiers).

### 3. CurrencyValidator Static Class

**Purpose:** Encapsulate currency application rules

**File:** `currency_validator.gd`

**Responsibilities:**
- Validate if currency can be applied to item
- Return human-readable error messages
- Centralize all business rules (e.g., "Tack Hammer only applies to Magic items")

**Why Static:** Pure validation logic with no state. Doesn't need to be instantiated or autoloaded.

**Pattern:** This follows the [validation pattern](https://medium.com/gamedev-architecture/decoupling-game-code-via-command-pattern-debugging-it-with-time-machine-2b177e61556c) where validation is separated from execution, allowing UI to check validity before attempting application.

## Modified Components

### Item Class

**New Properties:**
```gdscript
enum ItemRarity { NORMAL, MAGIC, RARE }
var rarity: ItemRarity = ItemRarity.NORMAL
```

**New Methods:**
```gdscript
func get_max_prefixes() -> int:
    match rarity:
        ItemRarity.NORMAL: return 0
        ItemRarity.MAGIC: return 1
        ItemRarity.RARE: return 3

func get_max_suffixes() -> int:
    match rarity:
        ItemRarity.NORMAL: return 0
        ItemRarity.MAGIC: return 1
        ItemRarity.RARE: return 3

func can_add_prefix() -> bool:
    return prefixes.size() < get_max_prefixes()

func can_add_suffix() -> bool:
    return suffixes.size() < get_max_suffixes()
```

**Modified Methods:**
- `add_prefix()`: Check `can_add_prefix()` instead of hardcoded `>= 3`
- `add_suffix()`: Check `can_add_suffix()` instead of hardcoded `>= 3`
- `get_display_text()`: Show rarity tier in output

**Rationale:** [Using enums for item rarity](https://tajammalmaqbool.com/blogs/godot-enum-a-comprehensive-guide) is the standard GDScript pattern. Enums are preferred over classes for simple state because they "make code more expressive, maintainable, and less error-prone than using raw numbers or strings."

### crafting_view.gd

**Replace:**
- `hammer_counts` dictionary → Call `CurrencyManager.get_count(type)`
- 3 hammer buttons → 6 currency buttons
- `update_item()` logic → Currency application via validation

**New:**
```gdscript
var selected_currency: CurrencyManager.CurrencyType = CurrencyManager.CurrencyType.NONE

func _on_currency_button_pressed(currency_type):
    selected_currency = currency_type
    update_currency_button_states()

func update_item(event: InputEvent):
    if selected_currency == CurrencyManager.CurrencyType.NONE:
        return

    # Validate before applying
    if not CurrencyValidator.can_apply(selected_currency, current_item):
        print(CurrencyValidator.get_error_message(selected_currency, current_item))
        return

    # Check currency count
    if CurrencyManager.get_count(selected_currency) <= 0:
        print("No ", CurrencyManager.get_name(selected_currency), " remaining!")
        return

    # Apply currency effect
    apply_currency(selected_currency, current_item)
    CurrencyManager.subtract(selected_currency, 1)
    update_currency_button_states()
```

**Rationale:** Existing pattern of button toggles + item clicking works well. Just expand from 3 buttons to 6 and replace direct dictionary access with CurrencyManager calls.

### gameplay_view.gd

**Modified:**
```gdscript
func get_random_item_base() -> Item:
    var item_types = [LightSword, BasicHelmet, BasicArmor, BasicBoots, BasicRing]
    var random_type = item_types[randi() % item_types.size()]
    var item = random_type.new()

    # NEW: Set rarity based on area level
    item.rarity = ItemDropManager.roll_rarity(area_level)

    # NEW: If rarity is Magic or Rare, add starting affixes
    if item.rarity == Item.ItemRarity.MAGIC:
        item.add_prefix()  # 1 random prefix
        item.add_suffix()  # 1 random suffix
    elif item.rarity == Item.ItemRarity.RARE:
        # Add 3 prefixes and 3 suffixes
        for i in range(3):
            item.add_prefix()
            item.add_suffix()

    return item

func give_hammer_rewards():
    # Replace hardcoded hammer distribution with currency distribution
    # Higher area levels can drop rarer currencies more frequently
    var currency_drops = ItemDropManager.roll_currency_rewards(area_level)

    for currency_type in currency_drops:
        CurrencyManager.add(currency_type, currency_drops[currency_type])
```

**Rationale:** Minimal change to existing drop logic. ItemDropManager encapsulates rarity rolling, keeping gameplay_view.gd clean.

## Data Flow Patterns

### Currency Application Flow

```
[User clicks currency button]
    ↓
[crafting_view sets selected_currency]
    ↓
[User clicks item]
    ↓
[CurrencyValidator.can_apply(currency, item)] → Returns bool + error msg
    ↓
[If valid] → apply_currency(currency, item)
    ↓
[CurrencyManager.subtract(currency, 1)]
    ↓
[Item.update_value()] → Recalculate DPS
    ↓
[Update UI]
```

### Item Drop Flow

```
[Hero clears area]
    ↓
[gameplay_view.clear_area()]
    ↓
[ItemDropManager.roll_rarity(area_level)] → Returns ItemRarity enum
    ↓
[Create item with rarity]
    ↓
[If Magic/Rare] → Add starting affixes based on rarity limits
    ↓
[crafting_view.set_new_item_base(item)]
```

### Currency Reward Flow

```
[Hero clears area]
    ↓
[ItemDropManager.roll_currency_rewards(area_level)] → Returns Dictionary
    ↓
[For each currency type] → CurrencyManager.add(type, count)
    ↓
[CurrencyManager emits "currency_changed" signal]
    ↓
[crafting_view updates button states]
```

## Currency Application Rules (Validation Logic)

| Currency | Effect | Valid When | Error Message |
|----------|--------|------------|---------------|
| **Runic Hammer** | Normal → Magic, add 1 prefix + 1 suffix | Item is Normal rarity | "Can only upgrade Normal items to Magic" |
| **Forge Hammer** | Normal → Rare, add 3 prefix + 3 suffix | Item is Normal rarity | "Can only upgrade Normal items to Rare" |
| **Tack Hammer** | Add 1 mod (prefix or suffix) | Item is Magic, has room for 1 more mod | "Can only add mods to Magic items with open slots" |
| **Grand Hammer** | Add 1 mod (prefix or suffix) | Item is Rare, has room for 1 more mod | "Can only add mods to Rare items with open slots" |
| **Claw Hammer** | Remove 1 random mod | Item has at least 1 prefix or suffix | "Item has no mods to remove" |
| **Tuning Hammer** | Reroll all mod values | Item has at least 1 prefix or suffix | "Item has no mods to reroll" |

**Implementation:** All rules centralized in `CurrencyValidator.can_apply()` method.

## Architectural Patterns

### Pattern 1: Enum for Rarity State

**What:** Use GDScript enum for item rarity instead of separate classes or string literals.

**When to use:** For simple, mutually exclusive states with no behavior differences.

**Trade-offs:**
- **Pro:** Type-safe, autocomplete-friendly, memory-efficient
- **Pro:** Match statements provide exhaustive case checking
- **Con:** Cannot add methods to enum values (but Item class has methods)

**Example:**
```gdscript
# Item.gd
enum ItemRarity { NORMAL, MAGIC, RARE }
var rarity: ItemRarity = ItemRarity.NORMAL

func get_max_prefixes() -> int:
    match rarity:
        ItemRarity.NORMAL: return 0
        ItemRarity.MAGIC: return 1
        ItemRarity.RARE: return 3
```

**Rationale:** [GDScript enum best practices](https://gamedevacademy.org/gdscript-enums-tutorial-complete-guide/) recommend enums for "states, modes, item rarities, AI phases" because they "make code more expressive, maintainable, and less error-prone."

### Pattern 2: Autoload Singleton for Global Currency State

**What:** Use Godot's autoload feature to create a globally accessible currency manager.

**When to use:** For game-wide shared state that needs to persist across scenes and be accessed from multiple independent nodes.

**Trade-offs:**
- **Pro:** Accessible from any script without get_node() references
- **Pro:** Automatically instantiated at game start
- **Pro:** Persists across scene changes
- **Con:** Global state can lead to tight coupling if overused
- **Mitigation:** Use signals for change notifications, keep manager focused on data storage only

**Example:**
```gdscript
# currency_manager.gd (autoload as "CurrencyManager")
extends Node

signal currency_changed(currency_type: CurrencyType, new_count: int)

enum CurrencyType { NONE, RUNIC, FORGE, TACK, GRAND, CLAW, TUNING }

var counts: Dictionary = {
    CurrencyType.RUNIC: 10,
    CurrencyType.FORGE: 5,
    CurrencyType.TACK: 10,
    CurrencyType.GRAND: 5,
    CurrencyType.CLAW: 3,
    CurrencyType.TUNING: 3
}

func add(type: CurrencyType, amount: int):
    counts[type] += amount
    currency_changed.emit(type, counts[type])

func subtract(type: CurrencyType, amount: int) -> bool:
    if counts[type] >= amount:
        counts[type] -= amount
        currency_changed.emit(type, counts[type])
        return true
    return false

func get_count(type: CurrencyType) -> int:
    return counts[type]
```

**Rationale:** [Godot autoload documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html) states it's "ideal for Global State Management like player score, money, lives, and inventory." Using signals maintains loose coupling.

### Pattern 3: Validation Before Mutation

**What:** Separate validation logic from execution logic. Check if an action is valid before performing it.

**When to use:** When actions have preconditions and you want to provide user feedback before failure.

**Trade-offs:**
- **Pro:** UI can disable/enable buttons based on validity
- **Pro:** Provides clear error messages before action attempt
- **Pro:** Centralized business rules in validator
- **Con:** Slight performance overhead of double-checking (validation + execution)
- **Mitigation:** For crafting UI, overhead is negligible

**Example:**
```gdscript
# currency_validator.gd
class_name CurrencyValidator

static func can_apply(currency: CurrencyManager.CurrencyType, item: Item) -> bool:
    match currency:
        CurrencyManager.CurrencyType.RUNIC:
            return item.rarity == Item.ItemRarity.NORMAL
        CurrencyManager.CurrencyType.TACK:
            return item.rarity == Item.ItemRarity.MAGIC and \
                   (item.can_add_prefix() or item.can_add_suffix())
        # ... other cases
    return false

static func get_error_message(currency: CurrencyManager.CurrencyType, item: Item) -> String:
    if can_apply(currency, item):
        return ""
    match currency:
        CurrencyManager.CurrencyType.RUNIC:
            return "Runic Hammer can only upgrade Normal items to Magic"
        # ... other cases
```

**Rationale:** This follows the [validation pattern in game systems](https://medium.com/gamedev-architecture/decoupling-game-code-via-command-pattern-debugging-it-with-time-machine-2b177e61556c) where "the system must check if the game state is valid" before mutations. Enables better UX through early validation.

### Pattern 4: Weighted Random with Area Scaling

**What:** Use area level to influence rarity drop weights, making rarer items more likely in harder areas.

**When to use:** For progression systems where difficulty correlates with reward quality.

**Trade-offs:**
- **Pro:** Creates natural progression curve
- **Pro:** Rewards players for tackling harder content
- **Con:** Requires balancing drop rates across area levels
- **Mitigation:** Use formulaic weights that scale predictably

**Example:**
```gdscript
# item_drop_manager.gd
extends Node

static func roll_rarity(area_level: int) -> Item.ItemRarity:
    # Weight calculation: higher area = better rarity chances
    # Area 1: 70% Normal, 25% Magic, 5% Rare
    # Area 5: 40% Normal, 40% Magic, 20% Rare
    # Area 10: 20% Normal, 40% Magic, 40% Rare

    var normal_weight = max(20, 70 - (area_level * 5))
    var magic_weight = min(40, 25 + (area_level * 3))
    var rare_weight = min(40, 5 + (area_level * 3))

    var total = normal_weight + magic_weight + rare_weight
    var roll = randf() * total

    if roll < normal_weight:
        return Item.ItemRarity.NORMAL
    elif roll < normal_weight + magic_weight:
        return Item.ItemRarity.MAGIC
    else:
        return Item.ItemRarity.RARE
```

**Rationale:** Based on [ARPG item rarity systems](https://www.poewiki.net/wiki/Rarity) from Path of Exile where "rarity gives a visual indicator of how one item compares to another in terms of game advancement."

## Build Order (Dependency Graph)

### Phase 1: Foundation (No Dependencies)

1. **CurrencyManager autoload** - Pure data storage, no dependencies
2. **ItemRarity enum in Item.gd** - Just add enum, no logic changes
3. **CurrencyValidator class** - References CurrencyManager enum and Item.ItemRarity enum

**Why First:** These are foundational types that other components depend on. No behavioral changes yet, so existing code continues working.

### Phase 2: Item Rarity Logic (Depends on Phase 1)

4. **Item.get_max_affixes() methods** - Uses ItemRarity enum
5. **Item.add_prefix()/add_suffix() modifications** - Calls get_max_affixes()
6. **Item.get_display_text() modification** - Shows rarity

**Why Second:** Makes Item class rarity-aware. Doesn't break existing code because items default to NORMAL rarity (0 max affixes until upgraded).

### Phase 3: Drop System (Depends on Phase 2)

7. **ItemDropManager autoload** - Returns ItemRarity values
8. **gameplay_view.get_random_item_base() modification** - Calls ItemDropManager
9. **gameplay_view.give_hammer_rewards() modification** - Calls CurrencyManager

**Why Third:** Integrates rarity into drop system. Items now drop with rarities, but crafting UI still uses old hammer system (backward compatible).

### Phase 4: Crafting UI (Depends on All Previous)

10. **crafting_view.gd currency button UI** - Replace 3 hammers with 6 currencies
11. **crafting_view.update_item() rewrite** - Use CurrencyValidator and CurrencyManager
12. **crafting_view currency application logic** - Implement all 6 currency effects

**Why Last:** This is the final integration point. All supporting systems must be in place. This phase replaces the old hammer system with the new currency system.

### Dependency Rationale

```
CurrencyManager ──┐
ItemRarity enum ──┼─→ CurrencyValidator
                  │
                  ├─→ Item rarity methods
                  │       ↓
                  ├─→ ItemDropManager ─→ gameplay_view
                  │
                  └─→ crafting_view (final integration)
```

**Build order prevents:**
- Referencing undefined enums
- Calling methods that don't exist yet
- UI depending on backend logic before it's implemented

**Safe rollback:** Each phase is independently testable. If Phase 4 has issues, Phase 1-3 remain functional.

## Anti-Patterns to Avoid

### Anti-Pattern 1: String-Based Rarity

**What people do:** Use strings like `var rarity = "magic"` instead of enums

**Why it's wrong:**
- No type safety - typos cause runtime errors
- No autocomplete
- Cannot exhaustively check all cases in match statements
- String comparisons are slower than int comparisons

**Do this instead:** Use `enum ItemRarity { NORMAL, MAGIC, RARE }` and `var rarity: ItemRarity`

### Anti-Pattern 2: Currency Logic in UI

**What people do:** Implement currency application rules directly in crafting_view.gd button handlers

**Why it's wrong:**
- Business logic mixed with UI logic
- Cannot reuse validation elsewhere (e.g., in item tooltips)
- Hard to test without instantiating entire UI
- Violation of single responsibility principle

**Do this instead:** Centralize rules in `CurrencyValidator` static class, UI just calls validator methods

### Anti-Pattern 3: Hardcoded Affix Limits

**What people do:** Keep `if len(prefixes) >= 3` checks in add_prefix/add_suffix

**Why it's wrong:**
- Doesn't respect rarity-based limits
- Magic items with 1 max would still check against 3
- Business rule (max affixes) is scattered across codebase

**Do this instead:** Use `can_add_prefix()` / `can_add_suffix()` methods that check `get_max_prefixes()` / `get_max_suffixes()`

### Anti-Pattern 4: Direct Currency Dictionary Access

**What people do:** Access `CurrencyManager.counts` directly from UI

**Why it's wrong:**
- Breaks encapsulation
- UI can modify counts without triggering signals
- Cannot add validation or logging to currency changes
- Tight coupling between UI and data structure

**Do this instead:** Use `CurrencyManager.get_count()`, `add()`, `subtract()` methods. Subscribe to `currency_changed` signal for updates.

### Anti-Pattern 5: Creating Items at Wrong Rarity

**What people do:** Create item, then upgrade rarity, then add affixes

```gdscript
var item = LightSword.new()  # Defaults to NORMAL
item.rarity = Item.ItemRarity.RARE  # Upgrade
for i in range(3):
    item.add_prefix()  # Add affixes after
```

**Why it's wrong:**
- Two-step process that can be interrupted
- Affixes added after rarity change might not respect old limits
- Creates "in-between" states that violate invariants

**Do this instead:** Set rarity immediately on creation, before adding affixes

```gdscript
var item = LightSword.new()
item.rarity = ItemDropManager.roll_rarity(area_level)
# Now add affixes - they'll respect rarity limits
```

## Integration Points

### Internal Boundaries

| Boundary | Communication Pattern | Notes |
|----------|----------------------|-------|
| **CraftingView ↔ CurrencyManager** | Direct method calls + signal subscription | CraftingView calls `get_count()`, `subtract()`. Subscribes to `currency_changed` for UI updates |
| **CraftingView ↔ CurrencyValidator** | Static method calls | CraftingView calls `can_apply()` before enabling buttons, `get_error_message()` for tooltips |
| **GameplayView ↔ ItemDropManager** | Static method calls | GameplayView calls `roll_rarity()` and `roll_currency_rewards()` during item/reward generation |
| **GameplayView ↔ CurrencyManager** | Direct method calls | GameplayView calls `add()` to grant currency rewards |
| **CraftingView ↔ GameplayView** | Sibling node references (existing) | `get_node_or_null("../GameplayView")` pattern unchanged |
| **Item ↔ ItemAffixes** | Autoload reference (existing) | Items call `ItemAffixes.prefixes/suffixes` arrays unchanged |

### View Communication Pattern (Existing)

```gdscript
# Existing sibling reference pattern - UNCHANGED
var crafting_view = get_node_or_null("../CraftingView")
crafting_view.set_new_item_base(item)
```

**Why not change:** This pattern already works. Views are guaranteed to be siblings in main.tscn structure. Refactoring to signals would be over-engineering for this simple case.

## Scaling Considerations

| Scale | Current Architecture | Notes |
|-------|---------------------|-------|
| **6 currencies** | CurrencyManager.counts dictionary | Works fine |
| **50+ currencies** | Consider categorizing currencies in sub-dictionaries | E.g., `basic_currencies`, `advanced_currencies` |
| **Complex currency interactions** | Add CurrencyEffect class hierarchy | If currencies need state or multi-step effects |
| **Multiplayer** | CurrencyManager needs network sync | Would need to emit RPC calls on add/subtract |

### Scaling Priorities

**Current scope (6 currencies, single-player):** Proposed architecture is appropriate. Simple, direct, no unnecessary abstraction.

**If expanding to 20+ currencies:** Consider factory pattern for currency application instead of giant match statement in `apply_currency()`.

**If adding multiplayer:** CurrencyManager would need authority checks and RPC synchronization. ItemDropManager would need to run on server only to prevent client cheating.

## Sources

**Godot-Specific Patterns:**
- [Godot 4 Grid Inventory with Patterns](https://github.com/alpapaydin/Godot-4-Grid-Inventory-with-Patterns) - Item rarity system examples
- [Pandora RPG Data Management](https://github.com/bitbrain/pandora) - Modular RPG systems for Godot 4
- [Simple In-Game Currency System in Godot](https://www.wayline.io/blog/simple-in-game-currency-system-godot) - Currency implementation patterns
- [Construct a Crafting System in Godot 4](https://academy.zenva.com/product/godot-crafting-system/) - Crafting system architecture

**GDScript Language Patterns:**
- [Godot Enum - Comprehensive Guide](https://tajammalmaqbool.com/blogs/godot-enum-a-comprehensive-guide) - Enum best practices
- [GDScript Enums Tutorial](https://gamedevacademy.org/gdscript-enums-tutorial-complete-guide/) - When to use enums vs classes
- [Singletons (Autoload) - Official Docs](https://docs.godotengine.org/en/latest/tutorials/scripting/singletons_autoload.html) - Autoload pattern for global state
- [Managing Cross-Scene Data with Autoload](https://uhiyama-lab.com/en/notes/godot/autoload-global-data-management/) - Currency and state management

**ARPG Design Patterns:**
- [Rarity - PoE Wiki](https://www.poewiki.net/wiki/Rarity) - Item rarity tier systems
- [Path of Exile 2 Crafting Overview](https://maxroll.gg/poe2/resources/path-of-exile-2-crafting-overview) - Currency-based crafting
- [Currency - PoE Wiki](https://www.poewiki.net/wiki/Currency) - Orb system architecture
- [Color-Coded Item Tiers](https://tvtropes.org/pmwiki/pmwiki.php/Main/ColorCodedItemTiers) - Rarity visualization

**Game Architecture Patterns:**
- [Decoupling Game Code via Command Pattern](https://medium.com/gamedev-architecture/decoupling-game-code-via-command-pattern-debugging-it-with-time-machine-2b177e61556c) - Validation before mutation
- [Command Pattern - Game Programming Patterns](https://gameprogrammingpatterns.com/command.html) - State validation patterns
- [Top Game Development Patterns in Godot Engine](https://www.manuelsanchezdev.com/blog/game-development-patterns) - Godot-specific architectural patterns

---
*Architecture research for: Hammertime ARPG Item Rarity & Crafting Currency System*
*Researched: 2026-02-14*
