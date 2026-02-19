# Architecture

**Analysis Date:** 2026-02-19

## Pattern Overview

**Overall:** Event-driven Model-View-Controller (MVC) with centralized global state. Godot engine scene hierarchy maps to UI views; models are plain GDScript classes; signals drive cross-component communication.

**Key Characteristics:**
- Autoload-based singleton pattern for persistent game state and event distribution (`GameState`, `GameEvents`, `SaveManager`, `ItemAffixes`, `Tag`)
- Signal-driven architecture: components emit signals, views observe and react without tight coupling
- Scene-based view system: each major UI section (Forge, Adventure, Settings) is a separate scene with a backing script
- Model objects are declarative classes extending `Resource` or plain `RefCounted`, no inheritance complexity
- Stat calculation is pure and deterministic, centralized in `StatCalculator`

## Layers

**Autoloads (Global Singletons):**
- Purpose: Persistent state, event bus, configuration data that survives scene reloads
- Location: `res://autoloads/`
- Contains:
  - `game_state.gd` — Hero, equipment, inventory, area progress
  - `game_events.gd` — Signal definitions for equipment, combat, drops, saves
  - `save_manager.gd` — JSON persistence, auto-save, import/export
  - `item_affixes.gd` — Master affix database (prefixes, suffixes, implicits)
  - `tag.gd` — Enum definitions for stat types and tags
- Depends on: Models (Hero, Item, Affix)
- Used by: All scenes, models

**Models (Data/Logic):**
- Purpose: Game entities with game logic (not UI)
- Location: `res://models/`
- Contains:
  - `hero.gd` — Character stats, equipment slots, stat calculation methods
  - `items/` — Item hierarchy (Item base, Weapon, Armor, Helmet, Boots, Ring)
  - `affixes/` — Affix (prefix/suffix), Implicit
  - `currencies/` — Currency types (RunicHammer, ForgeHammer, etc.)
  - `combat/` — CombatEngine (state machine, attack timers, pack management)
  - `stats/` — StatCalculator (pure stat math), DefenseCalculator (damage reduction)
  - `monsters/` — MonsterPack, MonsterType, PackGenerator, BiomeConfig
  - `loot/` — LootTable (item drops)
- Depends on: Affixes, Tag enums
- Used by: Views (Scenes), CombatEngine, SaveManager

**Scenes (Views):**
- Purpose: UI rendering and user input handling
- Location: `res://scenes/`
- Contains:
  - `main.tscn` / `main_view.gd` — Tab system, view routing
  - `forge_view.tscn` / `forge_view.gd` — Crafting bench, item modification UI
  - `gameplay_view.tscn` / `gameplay_view.gd` — Combat arena, health bars, pack fights
  - `settings_view.tscn` / `settings_view.gd` — New Game, Import/Export
  - `save_toast.tscn` / `save_toast.gd` — Save notification overlay
  - `floating_label.tscn` / `floating_label.gd` — Damage numbers, floating text
- Depends on: GameState, GameEvents, Models
- Used by: Player input, node tree

## Data Flow

**Game Initialization:**
1. Engine loads `res://scenes/main.tscn` (configured in project.godot)
2. `main_view.gd` `_ready()` connects tab buttons and cross-view signals
3. Autoloads initialize on first access (GameState, GameEvents, SaveManager)
4. `GameState._ready()` calls `initialize_fresh_game()`, then attempts `SaveManager.load_game()`
5. ForgeView/GameplayView load with default or saved state
6. UI renders current hero and inventory

**Crafting Loop (Forge View):**
1. Player selects item type (weapon/helmet/armor/boots/ring) → calls `_on_item_type_selected()`
2. ForgeView loads best item from `GameState.crafting_inventory[slot]`
3. Player selects hammer currency → `_on_currency_selected()` sets `selected_currency`
4. Player clicks item image → `update_item()` validates:
   - Currency is selected
   - Item exists
   - Currency can apply to item (checked via `selected_currency.can_apply()`)
   - GameState has currency balance (`spend_currency()`)
5. Currency applies effect via `selected_currency.apply(current_item)` → modifies affixes
6. Item calls `update_value()` → recalculates DPS/defense via StatCalculator
7. UI updates via `update_item_stats_display()`
8. Player equips → `_on_equip_pressed()` moves item to `GameState.hero.equipped_items[slot]`
9. Equipment change emits signal → `equipment_changed.emit()`
10. GameplayView receives signal → recalculates hero stats

**Combat Loop (Gameplay View → CombatEngine):**
1. Player presses "Start Clearing" → `_on_start_combat_pressed()`
2. CombatEngine.start_combat(area_level):
   - Generates packs via `PackGenerator.generate_packs(level)`
   - Sets state to FIGHTING
   - Emits `GameEvents.combat_started`
   - Calls `_start_pack_fight()`
3. Attack timers tick independently:
   - `hero_attack_timer` fires every `1.0 / hero_attack_speed` seconds
   - `pack_attack_timer` fires every `1.0 / pack.attack_speed` seconds
4. `_on_hero_attack()`:
   - Rolls damage for each element independently
   - Applies crit multiplier
   - Reduces by pack defense
   - Calls `pack.take_damage()`
   - Emits `GameEvents.hero_attacked`
5. `_on_pack_attack()`:
   - Pack rolls damage (no crit, no element split)
   - DefenseCalculator splits into life + ES damage
   - Calls `GameState.hero.apply_damage()`
   - Emits `GameEvents.pack_attacked`
6. When pack dies:
   - Recharge hero ES 33%
   - Generate item drop
   - Generate currency drop
   - Emit `GameEvents.items_dropped`, `GameEvents.currency_dropped`
   - Advance to next pack
7. When all packs die:
   - Emit `GameEvents.area_cleared`
   - Set state to MAP_COMPLETE
8. Player clicks "Next Area" or dies and retries

**Stat Calculation (Deferred):**
1. Hero equips item → `GameState.hero.equip_item(item, slot)`
2. Item calls `Hero.update_stats()`:
   - `calculate_damage_ranges()` — Per-element min/max from weapon+ring affixes
   - `calculate_dps()` — Average damage * speed * crit multiplier
   - `calculate_defense()` — Base armor from slots, resistance from all affixes
   - `calculate_crit_stats()` — Crit chance/damage from weapon+ring
3. All calculations use `StatCalculator` static methods
4. Hero stores computed totals (`total_dps`, `total_defense`, etc.)
5. Views read from hero and display (no recalculation)

**State Persistence:**
1. Save triggers: item crafted, equipment changed, area cleared, or every 5 min auto-save
2. SaveManager.save_game():
   - Serializes hero (equipment slots, health, stats)
   - Serializes crafting inventory (per-slot arrays)
   - Serializes all items (via `to_dict()`, which recursively serializes affixes)
   - Stores area progress, currency counts
   - Writes JSON to `user://hammertime_save.json`
3. SaveManager.load_game():
   - Reads JSON
   - Deserializes hero
   - Deserializes items via `Item.create_from_dict()` (polymorph lookup table)
   - Populates GameState with restored state
   - Returns true/false to flag corruption

## Key Abstractions

**GameState (Singleton):**
- Purpose: Centralized mutable game state container
- Examples: `res://autoloads/game_state.gd`
- Pattern: Godot Node with `extends Node`, initialized in project.godot `[autoload]`
- Access: Global `GameState.hero`, `GameState.crafting_inventory`, `GameState.currency_counts`

**GameEvents (Signal Hub):**
- Purpose: Decouple components via named signals
- Examples: `res://autoloads/game_events.gd`
- Pattern: Godot Node with `signal equipment_changed(slot, item)`, etc.
- Access: Any script can call `GameEvents.equipment_changed.emit(slot, item)`

**Models (Resource-based):**
- Purpose: Serializable game objects with calculated properties
- Examples: `Hero`, `Item`, `Weapon`, `Affix`, `MonsterPack`
- Pattern: Class extending `Resource` or `RefCounted` with `class_name` declaration
- Serialization: `to_dict()` for save, `from_dict()` or `create_from_dict()` for load

**StatCalculator (Pure Functions):**
- Purpose: Deterministic, order-of-operations-correct math
- Examples: `res://models/stats/stat_calculator.gd`
- Pattern: Static methods only, no state
- Operations: Damage (flat → % → speed → crit), defense (armor + resistances), DPS

**Currency (Behavior Pattern):**
- Purpose: Each hammer type has `can_apply()` and `apply()` logic
- Examples: `res://models/currencies/*.gd`
- Pattern: Class extending `Currency` with overridden methods
- Behavior: Runic validates normal rarity, applies magic; Forge validates normal, applies rare; Tack adds prefix; etc.

**CombatEngine (State Machine):**
- Purpose: Manage pack sequence and dual-timer attack resolution
- Examples: `res://models/combat/combat_engine.gd`
- Pattern: Node with `state: State` enum, two timers (hero and pack)
- Workflow: IDLE → FIGHTING (with pack transitions) → MAP_COMPLETE or HERO_DEAD

## Entry Points

**Application Start:**
- Location: `res://scenes/main.tscn` (configured in project.godot)
- Triggers: Engine startup
- Responsibilities: Load TabBar, instantiate three views, connect tab signals

**View Routing (Main View):**
- Location: `res://scenes/main_view.gd`
- Triggers: Player clicks tab button or presses 1/2/TAB
- Responsibilities: Show/hide views, manage mutual visibility (especially CombatUI CanvasLayer)

**Crafting Interaction (Forge View):**
- Location: `res://scenes/forge_view.gd`, method `update_item()`
- Triggers: Player clicks on item image with currency selected
- Responsibilities: Validate, apply currency, update item, refresh UI

**Combat Start (Gameplay View):**
- Location: `res://scenes/gameplay_view.gd`, method `_on_start_combat_pressed()`
- Triggers: Player presses "Start Clearing" button
- Responsibilities: Delegate to CombatEngine, observe signals for UI updates

## Error Handling

**Strategy:** Graceful degradation with console warnings. No exceptions thrown.

**Patterns:**
- Guards on null checks: `if current_item == null: return`
- Boolean returns from fallible operations: `if not GameState.spend_currency(): return`
- Fallback values: If no item in crafting bench, display "(No item)"
- Save corruption flag: `GameState.save_was_corrupted` checked by SaveToast to warn player
- Item lookup via registry: `Item.create_from_dict()` returns null for unknown types (logged)

## Cross-Cutting Concerns

**Logging:** Print statements throughout; no centralized logger
- Used for: Debug tracking of user actions, currency operations, item modifications
- Examples: `print("Applied " + selected_currency.currency_name)`

**Validation:** Validation is distributed
- Currency validation: Currency.can_apply() checks rarity, rarity limits, balance
- Item deserialization: Item.create_from_dict() checks type string against registry
- Save state: SaveManager checks JSON structure before restore

**Signal Wiring:** Main view orchestrates cross-module connections
- Location: `res://scenes/main_view.gd`, `_ready()` method
- Pattern: `forge_view.equipment_changed.connect(gameplay_view.refresh_clearing_speed)`
- Reason: Decouples Forge from Gameplay; views never import each other

---

*Architecture analysis: 2026-02-19*
