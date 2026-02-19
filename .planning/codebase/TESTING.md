# Testing Patterns

**Analysis Date:** 2026-02-19

## Current Testing Status

**Testing Framework:** Not detected

**Assertion Library:** Not detected

**No automated test files found** in the codebase. No test runners (Jest, Vitest, pytest, GUT) configured.

Testing is currently **manual/exploratory** via:
- Debug methods for verification (e.g., `PackGenerator.debug_generate()`)
- Print statements throughout code for observation
- In-game play testing

## Code Observation & Debug Methods

**Built-in Debug Functions:**

`PackGenerator.debug_generate(area_level: int)` (`models/monsters/pack_generator.gd:103-135`)
- Prints formatted pack generation output for a given area level
- Shows multiplier, pack count, individual pack stats (HP, damage range, speed, element)
- Element distribution summary at end
- Purpose: Verification of pack generation correctness at development time

```gdscript
static func debug_generate(area_level: int) -> void:
	var biome := BiomeConfig.get_biome_for_level(area_level)
	var multiplier := get_level_multiplier(area_level)
	var packs := generate_packs(area_level)

	print("=== Pack Generation: Area Level %d (%s) ===" % [area_level, biome.biome_name])
	print("Multiplier: %.1fx" % multiplier)
	print("Packs: %d" % packs.size())
	# ... detailed pack info printed to console
```

**Debug Flags:**

`GameState.debug_hammers` (autoloads/game_state.gd:3, 34-37)
- Boolean flag to enable testing with infinite currency
- Set to true for development, false for normal play
- Spawns 999 of each hammer type on game init

```gdscript
var debug_hammers: bool = false  # Set to true for testing
# ...
if debug_hammers:
    for key in currency_counts:
        currency_counts[key] = 999
    print("DEBUG: Spawned with 999 of each hammer")
```

**Print Statement Usage:**

Extensive use of `print()` throughout models for observation:
- Item operations: `print("adding a prefix")`, `print("affix already on item")`
- Affix rerolls: `print("reroll add_min=%d add_max=%d" % [add_min, add_max])`
- Damage calculations: `print("Hero took ", damage, " damage! Health: ", health, "/", max_health)`
- Equip state: `print("Equipped ", item.item_name, " to ", slot)`

Examples from codebase:
- `models/items/item.gd:200` - `print(self.prefixes)` in validation
- `models/items/item.gd:220` - `print("adding a prefix")`
- `models/affixes/affix.gd:96` - `print("reroll add_min=%d add_max=%d" % [add_min, add_max])`
- `models/hero.gd:47` - `print("Hero took ", damage, " damage! Health: ", health, "/", max_health)`

## Testable Components

**High-Priority Test Areas** (if testing framework added):

### 1. Stat Calculations
**Location:** `models/stats/stat_calculator.gd`
**Functions to test:**
- `calculate_dps()` - Verifies correct order of operations (base → flat → additive % → speed → crit)
- `_calculate_crit_multiplier()` - Weighted-average crit formula with test cases documented in comments
- `calculate_damage_range()` - Per-element damage accumulation with percentage scaling
- `calculate_flat_stat()` - Flat stat aggregation from affixes
- `calculate_percentage_stat()` - Additive multiplier stacking

**Test data ready:** Crit multiplier has documented test cases in code comments:
```gdscript
## Test cases:
## - 0% crit, 150% damage -> 1.0 (no crit effect)
## - 100% crit, 150% damage -> 1.5 (always crits)
## - 5% crit, 150% damage -> 1.025 (2.5% DPS increase)
## - 50% crit, 200% damage -> 1.5 (50% DPS increase)
```

### 2. Item Serialization
**Location:** `models/items/item.gd`
**Functions to test:**
- `to_dict()` - Serialization of all item types and affixes
- `create_from_dict()` - Deserialization and registry lookup
- Affix preservation through round-trip: `to_dict()` → `from_dict()`

**Test data:** Item types registered in `ITEM_TYPE_STRINGS` constant (5 types: LightSword, BasicArmor, BasicHelmet, BasicBoots, BasicRing)

### 3. Defense Calculations
**Location:** `models/stats/defense_calculator.gd`
**Key function:** `calculate_damage_taken()`
- Armor/Evasion/Energy Shield interactions
- Element resistance application
- Dodge chance calculation

### 4. Pack Generation
**Location:** `models/monsters/pack_generator.gd`
**Functions to test:**
- `get_level_multiplier()` - Exponential scaling formula
- `roll_element()` - Weighted random element selection
- `create_pack()` - Individual pack scaling and difficulty bonus

**Debug method available:** `debug_generate()` can be used for regression testing output

### 5. Save/Load Roundtrip
**Location:** `autoloads/save_manager.gd`
**Functions to test:**
- Full game state serialization and reconstruction
- Version migration (`_migrate_save()`)
- Save file corruption detection
- All models' `to_dict()` / `from_dict()` in real scenario

## Recommended Testing Approach

**For Godot GDScript testing**, consider:

**Option 1: GUT (GDScript Unit Test Framework)**
- Native Godot testing framework
- No external dependencies
- Runs tests inside Godot editor
- Install via Asset Library

**Option 2: Manual Assertion Helpers**
- Create `autoloads/test_utils.gd` with assertion functions
- Run tests from debug scenes without full framework
- Keep output in console/file

## Potential Test Coverage Gaps

**Currently Untested:**
- UI logic (event handling, button presses) - `scenes/` files
- Combat simulation under game conditions - `CombatEngine` state transitions
- Hero stat calculations with full equipment - `Hero.update_stats()`
- Save file migration with actual version changes
- Concurrent affix modifications (add/remove/reroll sequences)
- Edge cases in currency spending with insufficient inventory

## Suggested Test File Structure (if framework added)

```
tests/
├── unit/
│   ├── test_stat_calculator.gd      # DPS, crit, damage range calculations
│   ├── test_item_serialization.gd   # to_dict/from_dict for all item types
│   ├── test_defense.gd              # Armor/evasion/ES interactions
│   ├── test_pack_generation.gd      # Level scaling, element rolling
│   └── test_save_manager.gd         # Save/load roundtrip
├── integration/
│   ├── test_hero_equipment.gd       # Full hero stat updates with gear
│   ├── test_combat_flow.gd          # Pack fight simulation
│   └── test_crafting_flow.gd        # Item craft operations
└── fixtures/
    ├── test_data.gd                 # Common test items, affixes, heroes
    └── helpers.gd                   # Assertion utilities
```

## Running Tests (Current Manual Approach)

**Via Godot Console:**
```gdscript
# In Godot debug console or test scene _ready():
PackGenerator.debug_generate(1)    # Print pack generation for level 1
PackGenerator.debug_generate(50)   # Print scaled packs for level 50

# Enable debug hammertime for manual crafting tests
GameState.debug_hammers = true
```

**Via Print Observation:**
- Equip items, check printed stats in Output window
- Craft items, observe affix addition/removal messages
- Load save files, monitor console for warnings/errors

## Note on Current Code Quality

**Positive testing indicators:**
- Extensive input validation (null checks, key existence, bounds)
- Defensive copying (arrays, dictionaries) to prevent side effects
- Type safety throughout (explicit return types, typed arrays)
- Constants for magic values (RARITY_LIMITS, GROWTH_RATE) enabling calculation verification
- Documented formulas (crit multiplier, element variance) make calculation correctness testable

**Current limitations:**
- No structured test runner means tests must be re-run manually
- Debug methods and print statements are ad-hoc, not standardized
- No regression test suite to catch changes
- Rely on human observation for correctness

---

*Testing analysis: 2026-02-19*
