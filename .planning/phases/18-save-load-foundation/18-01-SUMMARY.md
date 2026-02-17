# Plan 18-01 Summary: Core Save/Load Infrastructure

## What was done

### Task 1: Serialization methods on Affix, Implicit, and all Item subclasses
- Added `to_dict()` and `static func from_dict()` to `models/affixes/affix.gd` — serializes all affix fields including randomized tier/value, and `from_dict()` overwrites randomized fields after construction to preserve exact saved values
- Added `static func from_dict()` to `models/affixes/implicit.gd` returning Implicit type (inherits `to_dict()` from Affix)
- Added `to_dict()`, `get_item_type_string()`, and `static func create_from_dict()` to `models/items/item.gd` with ITEM_TYPES registry mapping type strings to constructors
- Added `get_item_type_string()` overrides to all 5 concrete subclasses: LightSword, BasicArmor, BasicHelmet, BasicBoots, BasicRing

### Task 2: SaveManager autoload and state centralization
- Created `autoloads/save_manager.gd` with `save_game()`, `load_game()`, `has_save()`, `delete_save()`, and `_migrate_save()` with version tracking
- Save file written to `user://hammertime_save.json` with readable JSON format
- Centralized crafting state in `autoloads/game_state.gd`: `crafting_inventory`, `crafting_bench_item`, `crafting_bench_type`, `max_unlocked_level`, `area_level`
- Added `initialize_fresh_game()` to GameState for clean state reset
- Added startup flow: `initialize_fresh_game()` -> `SaveManager.load_game()` -> corruption detection
- Registered SaveManager in `project.godot` before GameState in autoload order
- Migrated `scenes/crafting_view.gd` to use `GameState.crafting_inventory` and `GameState.crafting_bench_type`
- Migrated `models/combat/combat_engine.gd` to use `GameState.area_level` and `GameState.max_unlocked_level`
- Migrated `scenes/gameplay_view.gd` to use `GameState.area_level`
- Added `GameEvents.item_crafted.emit()` to crafting_view's `finish_item()`

## Files modified
- `models/affixes/affix.gd` — added to_dict(), from_dict()
- `models/affixes/implicit.gd` — added from_dict()
- `models/items/item.gd` — added to_dict(), get_item_type_string(), create_from_dict()
- `models/items/light_sword.gd` — added get_item_type_string()
- `models/items/basic_armor.gd` — added get_item_type_string()
- `models/items/basic_helmet.gd` — added get_item_type_string()
- `models/items/basic_boots.gd` — added get_item_type_string()
- `models/items/basic_ring.gd` — added get_item_type_string()
- `autoloads/save_manager.gd` — NEW: SaveManager autoload
- `autoloads/game_state.gd` — centralized state, initialize_fresh_game(), startup flow
- `scenes/crafting_view.gd` — migrated to GameState for inventory/bench state
- `models/combat/combat_engine.gd` — migrated to GameState for area_level/max_unlocked_level
- `scenes/gameplay_view.gd` — migrated to GameState.area_level
- `project.godot` — added SaveManager autoload

## Commit
`b3c59ef` — feat: add core save/load infrastructure with serialization and state centralization
