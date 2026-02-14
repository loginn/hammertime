# Stack Research

**Domain:** ARPG Crafting Idle Game - Item Rarity & Currency System
**Researched:** 2026-02-14
**Confidence:** HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **GDScript Enums** | Godot 4.5 | Rarity tier definition | Built-in type-safe constants with IDE autocomplete. Already used successfully for `AffixType` enum in existing codebase. Explicit value assignment prevents serialization issues. |
| **Dictionary (typed)** | Godot 4.5 | Currency storage | Native Godot data structure. Already used in `crafting_view.gd` for `hammer_counts` and `crafting_inventory`. Easily serializable to JSON for save systems. Zero overhead. |
| **RandomNumberGenerator** | Godot 4.5 | Weighted rarity drops | Built-in class with `rand_weighted()` method for weighted probability selection. Auto-seeded since Godot 4.0. Better than global `randi()` for multiple independent RNG streams. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **None Required** | - | - | All functionality achievable with Godot 4.5 built-ins. Avoid external dependencies for simple rarity/currency systems. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| **Godot 4.5 Inspector** | Configure rarity weights | Export variables to tune drop rates without code changes |
| **Godot Debugger** | Test drop probabilities | Use breakpoints to verify weighted selection logic |

## Integration with Existing Codebase

### Extend Item Class (item.gd)

```gdscript
class_name Item extends Node

enum Rarity {NORMAL = 0, MAGIC = 1, RARE = 2}

var item_name: String
var rarity: Rarity = Rarity.NORMAL  # NEW: Add rarity property
var implicit: Implicit
var prefixes: Array[Affix] = []
var suffixes: Array[Affix] = []
var tier: int
var valid_tags: Array[String]

# NEW: Rarity constraints
func get_max_prefixes() -> int:
    match rarity:
        Rarity.NORMAL: return 0
        Rarity.MAGIC: return 1
        Rarity.RARE: return 3
        _: return 0

func get_max_suffixes() -> int:
    match rarity:
        Rarity.NORMAL: return 0
        Rarity.MAGIC: return 1
        Rarity.RARE: return 3
        _: return 0
```

**Why:** Enums provide type safety. Match statements are efficient and readable. Existing `add_prefix()` method already checks `len(self.prefixes) >= 3`, so only need to change the limit based on rarity.

### Extend Crafting View (crafting_view.gd)

```gdscript
# Replace existing hammer_counts dictionary
var hammer_counts: Dictionary = {
    "runic": 0,      # Normal -> Magic
    "forge": 0,      # Normal -> Rare
    "tack": 0,       # Add mod to Magic
    "grand": 0,      # Add mod to Rare
    "claw": 0,       # Remove mod
    "tuning": 0      # Reroll values
}
```

**Why:** Already using Dictionary for `hammer_counts`. Just rename keys and update UI button logic. Existing `update_hammer_button_states()` pattern extends cleanly.

### Add Weighted Drop System (gameplay_view.gd)

```gdscript
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Area difficulty affects rarity weights
func get_rarity_weights() -> Array[float]:
    var base_weights = [0.85, 0.10, 0.05]  # Normal, Magic, Rare
    var difficulty_bonus = area_difficulty_multiplier - 1.0

    # Higher difficulty shifts probability toward rarer items
    base_weights[2] += difficulty_bonus * 0.02  # +2% Rare per difficulty level
    base_weights[1] += difficulty_bonus * 0.03  # +3% Magic per difficulty level
    base_weights[0] = 1.0 - base_weights[1] - base_weights[2]  # Remaining to Normal

    return base_weights

func get_random_item_base() -> Item:
    var item_types = [LightSword, BasicHelmet, BasicArmor, BasicBoots, BasicRing]
    var random_type = item_types[randi() % item_types.size()]
    var item = random_type.new()

    # NEW: Determine rarity based on area difficulty
    var rarity_weights = get_rarity_weights()
    var rarity_index = rng.rand_weighted(rarity_weights)
    item.rarity = rarity_index as Item.Rarity

    return item
```

**Why:** `RandomNumberGenerator.rand_weighted()` is built-in and handles weighted selection correctly. Existing `area_difficulty_multiplier` already scales with progression. No external libraries needed.

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| **GDScript Dictionary** | Custom Resource class | If you need save/load with `.tres` files or inspector editing of currency pools |
| **Enum for Rarity** | String constants | Never. Enums are type-safe and prevent typos |
| **RandomNumberGenerator** | Global `randi()`/`randf()` | Only if you never need seeded/deterministic randomness |
| **Built-in weighted selection** | Manual cumulative probability loop | Never. `rand_weighted()` is clearer and less error-prone |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| **Nodes for item data** | Already using Node inheritance incorrectly. Items should be Resources or RefCounted classes, not Nodes. Nodes have scene tree overhead and `_ready()`/`_process()` callbacks that items don't need. | **Keep current Node approach temporarily** for consistency with existing codebase, but flag for future refactor to Resource-based items |
| **Autoload singleton for currencies** | Crafting view already manages hammer counts. Adding autoload creates split responsibility. | **Dictionary in crafting_view.gd** (already proven pattern) |
| **External loot table plugins** | Overkill for 3 rarity tiers. Adds dependency and learning curve. | **Built-in `rand_weighted()`** with inline weights |
| **String-based rarity** | No compile-time safety. Typos like "MAGC" fail silently. | **Enum with explicit values** |

## Stack Patterns by Feature

### Pattern 1: Rarity System

**Data Structure:**
```gdscript
enum Rarity {NORMAL = 0, MAGIC = 1, RARE = 2}
var rarity: Rarity = Rarity.NORMAL
```

**Why:**
- Explicit integer values (0, 1, 2) ensure consistent serialization
- Type annotations enable IDE autocomplete
- Match statements provide exhaustive checking
- Aligns with existing `AffixType` enum pattern in `affix.gd`

### Pattern 2: Currency Management

**Data Structure:**
```gdscript
var hammer_counts: Dictionary = {
    "runic": 0,
    "forge": 0,
    "tack": 0,
    "grand": 0,
    "claw": 0,
    "tuning": 0
}
```

**Why:**
- Already proven in existing `hammer_counts` system
- Easily displayed in UI: `str(hammer_counts["runic"])`
- Simple increment/decrement: `hammer_counts["tack"] += 1`
- Dictionary keys act as currency type identifiers
- No need for complex inventory system for consumables

### Pattern 3: Weighted Drops

**Implementation:**
```gdscript
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var weights: Array[float] = [0.85, 0.10, 0.05]  # Normal, Magic, Rare
var rarity_index: int = rng.rand_weighted(weights)
```

**Why:**
- `rand_weighted()` returns index based on probability
- Array order matches enum order (NORMAL=0, MAGIC=1, RARE=2)
- Export weights to inspector for easy tuning: `@export var rarity_weights: Array[float] = [0.85, 0.10, 0.05]`
- Instance RNG allows multiple drop tables with different seeds

### Pattern 4: Crafting Operations

**Currency Consumption:**
```gdscript
func use_runic_hammer():
    if hammer_counts["runic"] <= 0:
        print("No Runic Hammers available")
        return false

    if current_item.rarity != Item.Rarity.NORMAL:
        print("Can only use Runic Hammer on Normal items")
        return false

    current_item.rarity = Item.Rarity.MAGIC
    hammer_counts["runic"] -= 1
    return true
```

**Why:**
- Validation before state change (transaction safety)
- Clear error messages for UI feedback
- Return boolean for success/failure handling
- Mirrors existing `update_item()` hammer consumption pattern

## Version Compatibility

| Component | Godot Version | Notes |
|-----------|---------------|-------|
| RandomNumberGenerator.rand_weighted() | 4.0+ | Added in Godot 4.0 with weighted selection |
| Auto-seeded RNG | 4.0+ | No need to call `randomize()` in `_ready()` |
| Typed Dictionaries | 4.0+ | `var dict: Dictionary = {}` works, but values are Variant |
| Enum type hints | 3.2+ | `var rarity: Rarity` supported, but runtime checks only |

**Godot 4.5 Specific Benefits:**
- Improved performance for Dictionary operations
- Better type inference for enum matches
- Enhanced debugger support for custom types

## Architectural Decisions

### Why NOT Resources for Items?

**Current State:** Items extend Node (incorrect but established pattern)

**Recommendation:** Keep Node-based items for this milestone to minimize refactoring risk.

**Future Refactor Path:**
1. Create `ItemData` Resource class with all properties
2. Have Item nodes reference ItemData
3. Gradually migrate logic from Node to Resource
4. Eventually replace Node items with Resource items

**Why defer refactoring:**
- Existing system works (5 equipment slots, display, DPS calculation)
- Rarity/currency features don't require architecture change
- Node → Resource migration is risky mid-development
- Can ship rarity system faster without refactor

### Why Dictionary for Currencies?

**Alternatives Considered:**
1. **Autoload singleton:** Splits state between views
2. **Array of Currency Resources:** Over-engineered for 6 currencies
3. **Individual variables:** `var runic_hammers: int`, etc. (verbose, hard to iterate)

**Dictionary wins because:**
- Already proven in `hammer_counts` and `crafting_inventory`
- Iterable for UI generation: `for currency in hammer_counts.keys()`
- String keys act as type identifiers for button mapping
- Easily serializable for save systems: `JSON.stringify(hammer_counts)`

### Why Enums for Rarity?

**Type Safety:**
```gdscript
# Good: Compile-time autocomplete
item.rarity = Item.Rarity.MAGIC

# Bad: Typo fails silently
item.rarity = "MAGC"  # No error, just broken logic later
```

**Match Exhaustiveness:**
```gdscript
match item.rarity:
    Item.Rarity.NORMAL: return 0
    Item.Rarity.MAGIC: return 1
    Item.Rarity.RARE: return 3
    _: return 0  # Default case catches future enum additions
```

**Serialization Safety:**
- Explicit values (`NORMAL = 0`) prevent reordering bugs
- Integer serialization is compact and cross-compatible
- Enum name remains readable in debug prints

## Implementation Checklist

**Phase 1: Rarity Enum (Low Risk)**
- [ ] Add `enum Rarity` to `item.gd`
- [ ] Add `var rarity: Rarity = Rarity.NORMAL` to Item class
- [ ] Add `get_max_prefixes()` and `get_max_suffixes()` methods
- [ ] Update `add_prefix()` to check `get_max_prefixes()` instead of hardcoded 3
- [ ] Update `add_suffix()` to check `get_max_suffixes()` instead of hardcoded 3

**Phase 2: Currency Dictionary (Low Risk)**
- [ ] Rename `hammer_counts` keys to new currency names
- [ ] Update `update_hammer_button_states()` to reference new keys
- [ ] Update UI buttons to show new currency names
- [ ] Update `add_hammers()` signature to accept 6 currency types

**Phase 3: Weighted Drops (Medium Risk)**
- [ ] Add `RandomNumberGenerator` instance to `gameplay_view.gd`
- [ ] Implement `get_rarity_weights()` based on `area_difficulty_multiplier`
- [ ] Update `get_random_item_base()` to set item rarity via `rand_weighted()`
- [ ] Export rarity weights to inspector for tuning
- [ ] Test drop distribution across difficulty levels

**Phase 4: Crafting Operations (Medium Risk)**
- [ ] Implement Runic Hammer (Normal → Magic)
- [ ] Implement Forge Hammer (Normal → Rare)
- [ ] Implement Tack Hammer (add mod to Magic if space)
- [ ] Implement Grand Hammer (add mod to Rare if space)
- [ ] Implement Claw Hammer (remove random mod)
- [ ] Implement Tuning Hammer (reroll existing mod values)
- [ ] Add validation for each operation (check rarity, check slots, etc.)

## Sources

- [GDScript Enums Tutorial - Complete Guide](https://gamedevacademy.org/gdscript-enums-tutorial-complete-guide/) — Enum best practices, explicit values, type safety
- [Resources — Godot Engine (stable) documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html) — Resource vs Node guidance
- [When to Node, Resource, and Class in Godot](https://backat50ft.substack.com/p/when-to-node-resource-and-class-in) — Architecture decision framework
- [RandomNumberGenerator — Godot Engine (stable) documentation](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html) — rand_weighted() method, seeding
- [Weighted Random Selection With Godot](http://kehomsforge.com/tutorials/single/weighted-random-selection-godot/) — Implementation patterns
- [Singletons (Autoload) — Godot Engine (stable) documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html) — When to use autoload (and when not to)
- [JSON In Godot - Complete Guide](https://gamedevacademy.org/json-in-godot-complete-guide/) — Dictionary serialization for save systems
- [Godot 4.5 Release Notes](https://godotengine.org/releases/4.5/) — New features: shader baking, accessibility, custom loggers

---
*Stack research for: Hammertime ARPG - Rarity & Currency Milestone*
*Researched: 2026-02-14*
*Confidence: HIGH — All recommendations based on Godot 4.5 official docs and proven patterns from existing codebase*
