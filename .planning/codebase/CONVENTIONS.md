# Coding Conventions

**Analysis Date:** 2026-03-31

## Naming Patterns

**Files:**
- snake_case for all `.gd` files: `combat_engine.gd`, `forge_view.gd`, `stat_calculator.gd`
- Scene files match their script name: `forge_view.tscn` / `forge_view.gd`
- Concrete item subclasses use snake_case: `broadsword.gd`, `iron_plate.gd`, `silk_robe.gd`
- Currency subclasses use snake_case: `runic_hammer.gd`, `tag_hammer.gd`

**Classes (class_name):**
- PascalCase: `CombatEngine`, `StatCalculator`, `DefenseCalculator`, `MonsterPack`
- Item hierarchy: `Item` -> `Weapon` / `Armor` / `Helmet` / `Boots` / `Ring` -> `Broadsword` / `IronPlate` etc.
- Currency hierarchy: `Currency` -> `RunicHammer` / `AlchemyHammer` / `TagHammer` etc. (Base hammers use literal PoE names: Augment/Alchemy/Chaos/Exalt/Divine/Annulment. Legacy creative names remain for Runic/Tack/Grand/Tag.)
- Tag autoload uses `Tag_List` (legacy name with underscore -- exception to the pattern)

**Functions:**
- snake_case: `update_stats()`, `calculate_dps()`, `add_item_to_stash()`
- Private functions prefixed with underscore: `_on_hero_attack()`, `_build_save_data()`, `_wipe_run_state()`
- Signal handlers use `_on_` prefix: `_on_pack_killed()`, `_on_currency_selected()`
- Static utility functions: `StatCalculator.calculate_dps()`, `DefenseCalculator.calculate_damage_taken()`

**Variables:**
- snake_case: `total_dps`, `area_level`, `current_pack_index`
- Constants use UPPER_SNAKE_CASE: `SAVE_PATH`, `SAVE_VERSION`, `MAX_PRESTIGE_LEVEL`, `PACK_COUNT_MIN`
- Enum values use UPPER_SNAKE_CASE: `Rarity.NORMAL`, `State.FIGHTING`, `AffixType.PREFIX`
- Boolean state variables prefixed descriptively: `is_combat_active`, `is_alive`, `equip_confirm_pending`
- Private state with underscore: `_save_pending`, `_hero_overlay`, `_new_game_confirming`

**Signals:**
- snake_case, past tense for events: `equipment_changed`, `item_crafted`, `area_cleared`, `hero_died`
- Present tense for requests: `hero_selection_needed`
- Typed parameters: `signal equipment_changed(slot: String, item: Item)`

**Types/Enums:**
- PascalCase enum names: `Rarity`, `State`, `AffixType`, `StatType`, `Archetype`
- Enums defined inside their owning class: `Item.Rarity`, `CombatEngine.State`, `Tag.StatType`

## Code Style

**Formatting:**
- Tab indentation (Godot default)
- No explicit formatter config (relies on Godot editor defaults)
- Line length is not strictly enforced but stays reasonable (~100-120 chars)

**Linting:**
- No external linter (`.gdlintrc` not present)
- Relies on Godot editor warnings

**Type Annotations:**
- Use static typing on function signatures: `func can_apply(item: Item) -> bool:`
- Use `var x: Type` for typed locals: `var hero: Hero = GameState.hero`
- Use typed arrays where possible: `Array[Affix]`, `Array[MonsterPack]`, `Array[String]`
- Some older code omits type annotations on locals (inconsistent)

## Documentation Style

**Two competing styles exist in the codebase:**

1. **GDScript `##` doc comments** (preferred, newer code): Used in `autoloads/`, `models/stats/`, `models/currencies/`, `models/combat/`
   ```gdscript
   ## Calculates DPS using correct order of operations:
   ## base -> flat damage -> additive damage% -> speed -> crit multiplier
   static func calculate_dps(...) -> float:
   ```

2. **Python-style `"""` docstrings** (legacy, `models/hero.gd` only): 36 occurrences in `models/hero.gd`
   ```gdscript
   func take_damage(damage: float) -> void:
       """Hero takes damage and updates health"""
   ```

**Prescriptive rule:** Use `##` doc comments for all new code. Do NOT use `"""` docstrings. The `"""` in `hero.gd` is legacy and should be migrated.

**Comment sections:** Use `# --- Section Name ---` for organizing related functions:
```gdscript
# --- Combat signal handlers ---
# --- Drop signal handlers (Phase 16) ---
# --- Display ---
```

**Phase references:** Comments often reference design phases: `# Phase 55: dead code`, `# Phase 48`, `# v3 migration policy`. This is project-specific traceability.

## Import Organization

**No explicit imports.** GDScript uses:
- `class_name` for global class registration (no import needed)
- `preload()` for scene/resource loading at the top of files:
  ```gdscript
  const FLOATING_LABEL = preload("res://scenes/floating_label.tscn")
  ```
- Autoloads accessed by their registered name: `GameState`, `GameEvents`, `SaveManager`, `ItemAffixes`, `Tag`, `PrestigeManager`

**Path Aliases:**
- `res://` for project-relative paths
- `user://` for save data paths

## Error Handling

**Patterns:**
- `push_warning()` for non-fatal warnings: `push_warning("GameState: Save file appears corrupted, starting fresh")`
- Guard clauses with early returns: `if current_item == null: return`
- Boolean return values for success/failure: `func save_game() -> bool`, `func spend_currency() -> bool`
- Result dictionaries for complex operations: `func import_save_string() -> Dictionary` returns `{"success": bool, "error": String}`
- No exceptions or try/catch -- GDScript does not support them; use return values

**Prescriptive rules:**
- Use `push_warning()` for unexpected but recoverable states
- Use guard clauses at function top, not nested if/else
- Return `bool` for simple success/failure, `Dictionary` for operations with error details

## Logging

**Framework:** `print()` statements (console output)

**Patterns:**
- Debug logging via `print()` scattered throughout gameplay code: `print("Equipped ", item.item_name, " to ", slot)`
- 92 `print()` calls across 7 files (excluding test file)
- `models/hero.gd` has 6 print calls for combat events
- `scenes/forge_view.gd` has 11 print calls for UI actions
- No log levels, no structured logging

**Prescriptive rule:** `print()` is acceptable for development. No logging framework is used.

## Signal/Event Patterns

**Central event bus:** `autoloads/game_events.gd` defines all cross-scene signals. Connected in `_ready()`:
```gdscript
GameEvents.combat_started.connect(_on_combat_started)
GameEvents.pack_killed.connect(_on_pack_killed)
```

**Local signals:** Scenes define their own signals for parent-child communication:
```gdscript
signal equipment_changed()       # forge_view.gd
signal prestige_triggered()      # prestige_view.gd
signal new_game_started()        # settings_view.gd
signal item_base_found(item_base: Item)  # gameplay_view.gd
```

**Wiring:** Cross-view signal connections happen in `main_view.gd`:
```gdscript
forge_view.equipment_changed.connect(gameplay_view.refresh_clearing_speed)
gameplay_view.item_base_found.connect(GameState.add_item_to_stash)
```

## Resource/Data Model Patterns

**All game data models extend Resource:**
```gdscript
class_name Item extends Resource
class_name Hero extends Resource
class_name Currency extends Resource
class_name Affix extends Resource
```

**Serialization pattern:** Every persistable model implements `to_dict() -> Dictionary` and a static `from_dict(data: Dictionary) -> T`:
```gdscript
func to_dict() -> Dictionary:
    return {"item_type": get_item_type_string(), "tier": tier, ...}

static func create_from_dict(data: Dictionary) -> Item:
    match item_type_str:
        "Broadsword": item = Broadsword.new(tier)
        ...
```

**Factory pattern:** `Item.create_from_dict()` is a manual match-based factory. New item types require adding a case.

**Template Method pattern:** `Currency.apply()` calls `can_apply()` then `_do_apply()`. Subclasses override `can_apply()` and `_do_apply()`.

## UI Patterns

**Two-click confirmation:** Used for destructive actions (equip overwrite, melt, prestige, new game, import):
```gdscript
if not equip_confirm_pending:
    equip_confirm_pending = true
    equip_button.text = "Confirm Overwrite?"
    equip_timer.start()
    return
# Second click -- execute
```
Timer resets the confirmation state after 3 seconds.

**Toast/Error display:** Forge errors use a tween-based fade:
```gdscript
forge_error_toast.visible = true
var tween := create_tween()
tween.tween_interval(2.0)
tween.tween_property(forge_error_toast, "modulate:a", 0.0, 0.5)
tween.tween_callback(func(): forge_error_toast.visible = false)
```

**@onready node references:** All scene node references use `@onready var`:
```gdscript
@onready var hero_hp_bar: ProgressBar = $CombatUI/UIRoot/HeroHealthContainer/HeroHPBar
```

**Display updates:** Views have an `update_display()` method that refreshes all UI elements. Called after every state change.

**Programmatic UI construction:** Hero selection cards in `main_view.gd` are built entirely in code (no `.tscn`), using `PanelContainer`, `VBoxContainer`, `StyleBoxFlat`.

## Autoload Access Pattern

**Global singletons accessed directly by name:**
- `GameState.hero`, `GameState.currency_counts`, `GameState.stash`
- `GameEvents.combat_started.emit()`
- `SaveManager.save_game()`
- `ItemAffixes.prefixes`, `ItemAffixes.suffixes`
- `PrestigeManager.can_prestige()`
- `Tag.PHYSICAL`, `Tag.StatType.FLAT_DAMAGE`

**Prescriptive rule:** Access autoloads by their registered name. Do not pass them as parameters.

## Static Utility Pattern

**Pure calculation classes use `static func` and extend `RefCounted`:**
- `StatCalculator` (`models/stats/stat_calculator.gd`)
- `DefenseCalculator` (`models/stats/defense_calculator.gd`)
- `PackGenerator` (`models/monsters/pack_generator.gd`)
- `LootTable` (`models/loot/loot_table.gd`)

These are never instantiated -- all methods are static.

## Item Subclass Pattern

**Concrete items follow a strict template:**
```gdscript
class_name Broadsword extends Weapon

const TIER_NAMES: Dictionary = { 8: "Rusty Broadsword", ... }
const TIER_STATS: Dictionary = { 8: {"dmg_min": 8, ...}, ... }

func get_item_type_string() -> String:
    return "Broadsword"

func _init(p_tier: int = 8) -> void:
    self.tier = p_tier
    self.item_name = TIER_NAMES[p_tier]
    self.valid_tags = [...]
    # Set base stats from TIER_STATS
    self.implicit = Implicit.new(...)
    self.update_value()
```

Every new item type must:
1. Define `TIER_NAMES` and `TIER_STATS` dicts (tiers 1-8)
2. Override `get_item_type_string()` returning its PascalCase name
3. Call `self.update_value()` at end of `_init()`
4. Be added to `Item.create_from_dict()` match block and `Item.ITEM_TYPE_STRINGS`
5. Be added to `gameplay_view.gd` `bases` dictionary for drop pool
6. Be added to `forge_view.gd` `_get_item_abbreviation()` for stash display

---

*Convention analysis: 2026-03-31*
