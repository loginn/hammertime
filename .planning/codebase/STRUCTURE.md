# Codebase Structure

**Analysis Date:** 2026-02-19

## Directory Layout

```
hammertime/
├── autoloads/              # Godot singleton autoloads (global state, events, config)
│   ├── game_events.gd      # Signal definitions
│   ├── game_state.gd       # Hero, inventory, currency, progress state
│   ├── item_affixes.gd     # Master affix database
│   ├── save_manager.gd     # Save/load persistence
│   └── tag.gd              # Enum definitions for stats and tags
├── models/                 # Game data models and logic (non-UI)
│   ├── hero.gd             # Character class with stat methods
│   ├── items/              # Item hierarchy
│   │   ├── item.gd         # Base Item class
│   │   ├── weapon.gd       # Weapons (damage, crit)
│   │   ├── armor.gd        # Body armor (defense)
│   │   ├── helmet.gd       # Helmet (defense, mana)
│   │   ├── boots.gd        # Boots (defense, speed)
│   │   ├── ring.gd         # Rings (damage, crit)
│   │   ├── light_sword.gd  # Starter weapon concrete class
│   │   ├── basic_armor.gd
│   │   ├── basic_helmet.gd
│   │   ├── basic_boots.gd
│   │   └── basic_ring.gd
│   ├── affixes/            # Affix system
│   │   ├── affix.gd        # Affix (prefix/suffix) class
│   │   └── implicit.gd     # Implicit (base) affix class
│   ├── currencies/         # Crafting currency types
│   │   ├── currency.gd     # Base Currency class
│   │   ├── runic_hammer.gd # Normal→Magic
│   │   ├── forge_hammer.gd # Normal→Rare
│   │   ├── tack_hammer.gd  # Add prefix (magic items)
│   │   ├── grand_hammer.gd # Add suffix (rare items)
│   │   ├── claw_hammer.gd  # Remove mod
│   │   └── tuning_hammer.gd # Reroll mod values
│   ├── combat/             # Combat simulation
│   │   └── combat_engine.gd # Main combat loop (state machine, timers)
│   ├── monsters/           # Monster/pack generation
│   │   ├── monster_type.gd
│   │   ├── monster_pack.gd
│   │   ├── pack_generator.gd
│   │   ├── biome_config.gd
│   │   └── .gitkeep
│   ├── stats/              # Stat calculation
│   │   ├── stat_calculator.gd     # Pure damage/DPS math
│   │   └── defense_calculator.gd  # Damage reduction logic
│   ├── loot/               # Drop system
│   │   └── loot_table.gd
│   └── .gitkeep
├── scenes/                 # UI Views (tscn + gd files)
│   ├── main.tscn           # Root scene (tab bar + 3 views)
│   ├── main_view.gd        # Main controller (view routing)
│   ├── forge_view.tscn     # Crafting bench scene
│   ├── forge_view.gd       # Crafting logic and displays
│   ├── gameplay_view.tscn  # Combat arena scene
│   ├── gameplay_view.gd    # Combat UI updates, pack/hero HP bars
│   ├── settings_view.tscn  # Settings/new game scene
│   ├── settings_view.gd    # Save/load/import/export
│   ├── save_toast.tscn     # Notification overlay scene
│   ├── save_toast.gd       # Toast auto-hide logic
│   ├── floating_label.tscn # Damage number scene
│   ├── floating_label.gd   # Floating text animation
│   └── .gitkeep
├── assets/                 # Images, textures, icons
│   ├── runic_hammer.png
│   ├── forge_hammer.png
│   ├── tack_hammer.png
│   ├── grand_hammer.png
│   ├── claw_hammer.png
│   ├── tuning_hammer.png
│   └── ... (other textures)
├── .planning/              # GSD planning artifacts (not in git on startup)
│   └── codebase/          # Architecture/structure analysis docs
├── .godot/                 # Godot editor cache (not committed)
├── Wireframe/              # Design sketches/prototypes
├── icon.svg                # Project icon
├── icon.svg.import         # Godot import metadata
├── project.godot           # Engine configuration (entry point, autoloads)
├── export_presets.cfg      # Build export settings
├── .editorconfig           # Editor formatting rules
├── .gitignore              # Git exclusions
└── .gitattributes          # Git LFS / line ending rules
```

## Directory Purposes

**autoloads/:**
- Purpose: Godot singleton nodes registered in `project.godot` that persist across scene loads
- Contains: Global state (hero, inventory), event signals, save/load logic, configuration data
- Key files: `game_state.gd` (mutable state hub), `game_events.gd` (signal bus)
- Access: Global e.g., `GameState.hero.health`, `GameEvents.equipment_changed.emit()`

**models/:**
- Purpose: Game logic and data objects (no UI rendering)
- Contains: Entity classes (Hero, Item, Affix, Currency), calculation logic (StatCalculator), simulation (CombatEngine)
- Key pattern: Classes use `class_name` for direct reference; Resources for serialization
- Organization: Subdirectories by domain (items, affixes, currencies, combat, stats, monsters, loot)

**models/items/:**
- Purpose: Item class hierarchy with inheritance (Weapon, Armor, Helmet, Boots, Ring)
- Contains: Base Item class with affix/rarity logic, concrete subclasses with stat calculations
- Key files: `item.gd` (polymorphic deserialization registry), `weapon.gd` (DPS), `armor.gd` (defense)

**models/affixes/:**
- Purpose: Modifier system (prefixes, suffixes, implicits)
- Contains: Affix class (holds name, tags, stat types, tier range), Implicit class
- Key concept: Affixes reference by object; deserialized via `to_dict()`/`from_dict()`

**models/currencies/:**
- Purpose: Crafting hammer behaviors (polymorphic behavior pattern)
- Contains: Base Currency class with abstract `can_apply()` / `apply()`, concrete hammer types
- Key pattern: Each hammer validates rarity/mod limits, then modifies item affixes in place

**models/combat/:**
- Purpose: Combat simulation state machine and attack resolution
- Contains: CombatEngine (IDLE/FIGHTING/MAP_COMPLETE states, hero+pack attack timers), no UI
- Key flow: Generates packs → starts timers → resolves attacks → emits signals (UI observes)

**models/monsters/:**
- Purpose: Pack generation and monster types
- Contains: MonsterType (stats), MonsterPack (array of monsters, health, attack speed), PackGenerator (procedural)
- Used by: CombatEngine.start_combat() calls PackGenerator.generate_packs()

**models/stats/:**
- Purpose: Pure, order-of-operations-correct mathematical functions
- Contains: StatCalculator (static DPS/damage range/percentage calculations), DefenseCalculator (damage split)
- Pattern: No state, all inputs passed as parameters
- Used by: Hero.update_stats(), Item.update_value(), CombatEngine._on_hero_attack()

**scenes/:**
- Purpose: UI Views paired with control scripts (MVC)
- Contains: Three major views (Forge, Gameplay, Settings) + overlays (SaveToast, FloatingLabel)
- Key pattern: Each view is a separate scene (tscn) with backing script (gd)
- Organization: No subdirectories; views are top-level (simple enough)

**assets/:**
- Purpose: Visual resources (textures, icons)
- Contains: Hammer icons, item graphics (if any), UI elements
- Path style: PNG for raster graphics, SVG for scalable

**Wireframe/:**
- Purpose: Design artifacts (not code)
- Contains: Designer sketches, UI mockups

## Key File Locations

**Entry Points:**
- `res://scenes/main.tscn` — Root scene loaded by engine (configured in `project.godot`, `run/main_scene`)
- `res://project.godot` — Engine configuration: autoloads, main scene, window size

**Configuration:**
- `res://project.godot` — Autoload registration, window settings, rendering backend (mobile)
- `res://autoloads/tag.gd` — Enum constants for stat types and affix tags

**Core Logic:**
- `res://models/hero.gd` — Hero class with equipment, stat methods
- `res://models/items/item.gd` — Item base class with polymorphic deserialization
- `res://models/combat/combat_engine.gd` — Combat simulation (state machine)
- `res://models/stats/stat_calculator.gd` — Pure stat calculations

**Persistence:**
- `res://autoloads/save_manager.gd` — Save/load to `user://hammertime_save.json`
- `res://autoloads/game_state.gd` — In-memory state container (serialized by SaveManager)

**Views:**
- `res://scenes/main_view.gd` — Tab routing, cross-view signal connections
- `res://scenes/forge_view.gd` — Crafting bench (currency selection, item modification)
- `res://scenes/gameplay_view.gd` — Combat arena (HP bars, pack fighting, drops)
- `res://scenes/settings_view.gd` — New Game, Import/Export dialogs

## Naming Conventions

**Files:**
- `[noun].gd` — Class definition (e.g., `hero.gd`, `combat_engine.gd`)
- `[noun]_[type].gd` — Specialized concrete class (e.g., `light_sword.gd`, `runic_hammer.gd`)
- `[adjective]_[noun].gd` — Utility or calculator (e.g., `stat_calculator.gd`, `save_manager.gd`)
- `*.tscn` — Scene file (paired with `.gd` of same name, e.g., `forge_view.tscn` + `forge_view.gd`)

**Directories:**
- Lowercase plural nouns: `items/`, `affixes/`, `currencies/`, `monsters/`, `autoloads/`
- Domain grouping: `models/` (all game logic), `scenes/` (all UI), `assets/` (all visuals)

**Classes (GDScript):**
- PascalCase: `Hero`, `Item`, `Weapon`, `Affix`, `CombatEngine`, `StatCalculator`
- Use `class_name` for direct reference (e.g., `class_name Hero extends Resource`)

**Variables & Functions:**
- snake_case: `total_dps`, `max_health`, `calculate_damage_ranges()`, `update_stats()`
- Signals: lowercase_with_underscores: `equipment_changed`, `item_crafted`, `hero_died`

**Enums:**
- PascalCase: `State.IDLE`, `Rarity.MAGIC`, `ItemSlot.WEAPON`

## Where to Add New Code

**New Feature (e.g., New Crafting Operation):**
- Primary code: `res://models/currencies/[your_hammer].gd` (extend `Currency` class)
- Logic: Implement `can_apply(item)` and `apply(item)` methods
- Registration: Add to `Affixes.prefixes` or reference in `forge_view.gd` currency buttons
- Tests: No test directory; manual testing via Godot editor

**New Item Type (e.g., Shield, Amulet):**
- Base class: `res://models/items/[your_item_type].gd` (extend `Item`)
- Concrete instance: `res://models/items/[specific_item].gd` (extend your base class)
- Registration: Add to `Item.ITEM_TYPE_STRINGS` array for deserialization
- Slots: Add slot to `Hero.equipped_items` and `GameState.crafting_inventory` dicts
- UI: Add button to `forge_view.tscn` / `forge_view.gd` item type buttons

**New Monster Type or Biome:**
- Monster: `res://models/monsters/[monster_name].gd` (extend or use MonsterType)
- Biome config: `res://models/monsters/biome_config.gd` (update tables)
- Generator: Modify `PackGenerator.generate_packs()` to reference new config

**New Stat/Affix:**
- Tag definition: Add to `res://autoloads/tag.gd` `StatType` enum
- Affix entry: Add to `Affixes.prefixes` or `.suffixes` array in `res://autoloads/item_affixes.gd`
- Calculator: Update `StatCalculator` methods if new calculation pattern needed
- Hero: Update `Hero.calculate_*()` methods if hero needs to track new stat

**New View / UI Section:**
- Scene: Create `res://scenes/[view_name].tscn` and `res://scenes/[view_name].gd`
- Routing: Register in `main_view.gd` — add button, add reference, connect signals
- State: Store in `GameState` if it needs persistence across scenes
- Signals: Define in `GameEvents` if view needs to communicate with other views

**Utilities / Pure Functions:**
- Location: `res://models/stats/` for calculation (e.g., DefenseCalculator)
- Pattern: Static class methods (no state)
- Example: `StatCalculator.calculate_dps()`, `DefenseCalculator.split_damage()`

## Special Directories

**autoloads/ (Godot-specific):**
- Purpose: Singleton Nodes registered in project.godot `[autoload]` section
- Persistence: Survive scene reloads; not instantiated multiple times
- Access: Global reference by name (e.g., `GameState`, `GameEvents`)
- Important: Changes to autoload scripts require engine restart to reload

**.godot/ (Generated, Not Committed):**
- Purpose: Godot editor cache (import metadata, shader caches)
- Generated: Yes
- Committed: No (in .gitignore)

**models/ Directory Organization Philosophy:**
- Flat structure preferred within `models/` (no deep nesting)
- Subdirectories only for closely related concepts (items, affixes, currencies)
- Keep calculators (StatCalculator, DefenseCalculator) at `models/stats/` level for easy discovery
- Keep CombatEngine at `models/combat/` for clear separation from item logic

**Crafting Inventory Data Structure (Phase 28/29):**
- Storage: `GameState.crafting_inventory` is `Dictionary` with slot names as keys
- Format: Each key maps to an `Array` of items (not a single item)
- Capacity: Each slot array has max 10 items
- Access: `GameState.crafting_inventory["weapon"]` returns Array[Item]
- UI: ForgeView displays "best item" (highest tier/DPS) from slot array

---

*Structure analysis: 2026-02-19*
