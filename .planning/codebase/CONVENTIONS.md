# Coding Conventions

**Analysis Date:** 2026-02-19

## Language

**GDScript** (Godot 4.6)
- Type-safe with explicit type annotations required on function parameters and returns
- Class-based with optional `class_name` declarations for global accessibility

## Naming Patterns

**Files:**
- snake_case for filenames: `item.gd`, `combat_engine.gd`, `pack_generator.gd`
- Match class name to filename when using `class_name` declaration
- Example: `class_name Item` lives in `item.gd`, `class_name PackGenerator` in `pack_generator.gd`

**Classes:**
- PascalCase: `Item`, `Weapon`, `CombatEngine`, `StatCalculator`, `PackGenerator`
- Declared at top of file with `class_name ClassName`

**Functions and Methods:**
- snake_case: `update_stats()`, `calculate_dps()`, `take_damage()`, `is_affix_on_item()`
- Private/internal functions prefixed with underscore: `_on_hero_attack()`, `_start_pack_fight()`, `_get_damage_element()`
- Callback handlers named `_on_[event]()`: `_on_hero_attack()`, `_on_pack_killed()`, `_on_currency_selected()`

**Variables:**
- snake_case for all variables: `total_dps`, `max_health`, `hero_name`, `equipped_items`
- Private variables NOT prefixed with underscore (convention differs from some languages)
- Dictionary keys use snake_case strings: `{"prefixes": 0, "suffixes": 0}`

**Constants:**
- SCREAMING_SNAKE_CASE: `RARITY_LIMITS`, `PACK_COUNT_MIN`, `GROWTH_RATE`, `SAVE_PATH`, `AUTO_SAVE_INTERVAL`
- Placed at top of class/file before methods
- Can be untyped for simple values or explicitly typed for clarity

**Types (Enums):**
- PascalCase for enum names: `Rarity`, `ItemSlot`, `AffixType`, `State`
- SCREAMING_SNAKE_CASE for enum values: `Rarity.NORMAL`, `ItemSlot.WEAPON`, `AffixType.PREFIX`

**Signal/Event names:**
- snake_case: `equipment_changed`, `item_crafted`, `area_cleared`
- Emitted with `.emit()` method

## Code Style

**Formatting:**
- Tabs for indentation (standard Godot)
- 4-space equivalent (Godot IDE default)
- No specific linter/formatter tool configured beyond editor defaults
- EditorConfig minimal: UTF-8 charset only (see `.editorconfig`)

**Line Length:**
- No strict limit enforced, but aim for ~100 characters for readability
- Long statements may wrap across lines for clarity

**Whitespace:**
- Blank lines separate logical sections within functions
- No blank line after function declaration before body
- One blank line between method definitions

**Braces and Brackets:**
- Opening brace on same line: `func foo() -> void: {`
- Actually, GDScript uses colon-based scoping (not C-style braces in most contexts)
- Dictionary/Array literals use standard brackets: `{"key": value}`, `[1, 2, 3]`

## Comments

**When to Comment:**
- Header comment explaining module/class purpose (examples: `## Generates scaled monster packs...`)
- Complex algorithms: describe the math or logic (see `StatCalculator.gd` - crit formula explanation)
- Non-obvious branching logic or special cases
- Tier scaling and data transformations that may confuse future readers

**Documentation Format:**
- Use `## Comment` for documentation (triple slash in GDScript becomes doc comments)
- Can appear before function or inline in docstrings
- Examples from codebase:
  - `## Calculates DPS using correct order of operations:` (line 4, StatCalculator)
  - `## Creates an item from a serialized dictionary. Returns null if type unknown.` (Item.gd:79)

**Avoid Stating the Obvious:**
```gdscript
# Bad: var health: float = 100.0  # Hero health (redundant)

# Good:
## Each element damage is rolled independently from damage_ranges
var damage_per_hit := 0.0
for element in hero.damage_ranges:
    # Range is {"min": float, "max": float} for each element type
```

**Debug Comments:**
- Used rarely, examples: `# Debug override: always give hammers` (GameState.gd:33)
- Marked clearly with DEBUG prefix when intentional dev-only code

## Import Organization

**Autoloads (Singletons):**
- Registered in `project.godot` under `[autoload]` section
- Accessed directly by name: `ItemAffixes.prefixes`, `GameState.hero`, `SaveManager.load_game()`
- Examples: `ItemAffixes`, `Tag`, `GameEvents`, `SaveManager`, `GameState`

**Class Dependencies:**
- Classes referenced by `class_name` are available globally (no import needed)
- Extend base classes naturally: `class_name Weapon extends Item`
- Static utility classes follow pattern: `StatCalculator.calculate_dps()`, `PackGenerator.generate_packs()`

**Path References:**
- Asset paths use `res://` protocol: `preload("res://assets/runic_hammer.png")`
- Scene paths: `run/main_scene="res://scenes/main.tscn"` (project.godot)

## Error Handling

**Strategy:**
- Use `push_warning()` for non-fatal issues: `push_warning("SaveManager: Save file appears corrupted...")`
- Return false/null on failure with warning: `if file == null: push_warning(...); return false`
- Guard clauses for early returns: `if state != State.FIGHTING: return` (CombatEngine.gd:73-74)
- Fallback values: `return biome.primary_element` (PackGenerator.gd:49)

**Patterns:**
```gdscript
# Guard against null/invalid state
var pack := get_current_pack()
if pack == null or not pack.is_alive():
    return

# Check preconditions and warn
if currency_type not in currency_counts:
    return false
if currency_counts[currency_type] <= 0:
    return false

# Validate data during deserialization
var parsed = JSON.parse_string(json_text)
if parsed == null or not (parsed is Dictionary):
    push_warning("SaveManager: Save file contains invalid JSON")
    return false
```

## Data Validation

**Type Safety:**
- Explicit type annotations on all function parameters: `func take_damage(damage: float) -> void:`
- Return types always specified: `-> int`, `-> float`, `-> Dictionary`, `-> Array[Affix]`
- Type-safe arrays: `Array[Affix]`, `Array[MonsterPack]` (not raw `Array`)

**Defensive Checks:**
- Check for null before accessing: `if weapon != null and weapon is Weapon:`
- Verify dictionary keys exist: `if slot in equipped_items:`, `data.get("key", default_value)`
- Bounds checking on arrays: `if current_pack_index >= current_packs.size():`

**Data Integrity:**
- Ensure value consistency after calculations: `if self.add_min > self.add_max: swap` (Affix.gd:77-80)
- Use `match` statements for exhaustive enum checks: `match rarity: Rarity.NORMAL: ...`
- Serialize/deserialize with version tracking: `const SAVE_VERSION = 2` (SaveManager)

## Function Design

**Size Guidelines:**
- Prefer functions under 50 lines
- Complex functions (100+ lines) are broken into helper methods: `calculate_defense()` calls sub-calculations
- Example: `CombatEngine._on_hero_attack()` (15 lines) is concise and focused

**Parameters:**
- Keep parameter count low (< 5 ideal)
- Use keyword args or pass objects for many related params: `calculate_damage_taken(damage, element, is_spell, armor, evasion, es, ...)`
- Default parameters used when sensible: `func calculate_dps(..., base_crit_chance: float = 5.0, base_crit_damage: float = 150.0)`

**Return Values:**
- Single return type, not multiple outputs
- Use Dictionary for structured returns: `DefenseCalculator.calculate_damage_taken()` returns `{"dodged": bool, "life_damage": float, "es_damage": float}`
- Consistent null returns for "not found": `return null` (Item.create_from_dict on unknown type)
- Boolean returns for success/failure: `func spend_currency(currency_type: String) -> bool:`

## Module Design

**Exports:**
- Public methods have no underscore prefix: `save_game()`, `load_game()`, `calculate_dps()`
- Private/helper methods start with underscore: `_restore_state()`, `_build_save_data()`
- Static utility classes expose only static methods (no instance methods): `StatCalculator`, `PackGenerator`, `DefenseCalculator`, `LootTable`

**File Organization:**
- One primary class per file (GDScript convention)
- Related constants and enums defined in same file as class
- Helper data structures (dictionaries, arrays) declared as class members or static const

**Inheritance Hierarchy:**
- Base classes: `extends Resource` (data models), `extends Node` (runtime objects)
- Subclassing for specialization: `Weapon extends Item`, `BasicSword extends Weapon`
- Static-only utility classes: `extends RefCounted` (lightweight, no scene tree presence)

**Signal Usage:**
- Centralized in `GameEvents` autoload
- Defined at top of scene/node files
- Connected in `_ready()` functions
- Emitted by state-changing methods: `GameEvents.combat_started.emit(...)`

## Special Patterns

**Resource-based Models:**
- Data models extend `Resource` class: `class_name Item extends Resource`
- Implement `to_dict()` for serialization and `from_dict(data: Dictionary) -> ClassName` static method for deserialization
- Allows saving to disk and reconstructing from JSON

**State Machines:**
- Enum for states: `enum State { IDLE, FIGHTING, MAP_COMPLETE, HERO_DEAD }`
- Current state stored in variable: `var state: State = State.IDLE`
- Guard clauses check state before actions: `if state != State.FIGHTING: return`

**Calculator/Utility Pattern:**
- Static-only classes with no instance state: `StatCalculator`, `DefenseCalculator`, `PackGenerator`
- All methods are `static func`
- Named with "Calculator" or "Generator" suffix for clarity
- Example call: `StatCalculator.calculate_dps(base_damage, base_speed, affixes)`

---

*Convention analysis: 2026-02-19*
