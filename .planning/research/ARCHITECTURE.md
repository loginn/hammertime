# Architecture Research

**Domain:** Save/Load, Side-by-Side UI Layout, Crafting UX Integration
**Researched:** 2026-02-17
**Confidence:** HIGH

## Integration Overview

This milestone adds save/load persistence, side-by-side hero/crafting UI layout, and crafting UX improvements to existing Godot 4.5 Resource-based idle ARPG. All features integrate with existing architecture rather than replacing it.

```
┌─────────────────────────────────────────────────────────────┐
│                    Scene Layer (main.tscn)                   │
├─────────────────────────────────────────────────────────────┤
│  ┌────────────────┐  ┌────────────────┐  ┌──────────────┐   │
│  │  HeroView      │  │  CraftingView  │  │ GameplayView │   │
│  │  (CanvasLayer) │  │  (CanvasLayer) │  │(CanvasLayer) │   │
│  └───────┬────────┘  └───────┬────────┘  └──────┬───────┘   │
│          └──────────┬─────────┘                  │           │
│                     │ (signals)                  │           │
├─────────────────────┴────────────────────────────┴───────────┤
│                   Autoload Layer                             │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐  ┌─────────────────────────────────┐  │
│  │   GameState      │  │        GameEvents               │  │
│  │   - hero         │  │   - equipment_changed           │  │
│  │   - currencies   │  │   - item_crafted                │  │
│  │   (singleton)    │  │   - combat signals (7)          │  │
│  └────────┬─────────┘  │   - drop signals (2)            │  │
│           │            └─────────────────────────────────┘  │
├───────────┴──────────────────────────────────────────────────┤
│                    Data Layer (Resources)                    │
├─────────────────────────────────────────────────────────────┤
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌─────────┐  ┌──────────┐   │
│  │ Hero │  │ Item │  │Affix │  │Currency │  │BiomeConf │   │
│  │(Res) │  │(Res) │  │(Res) │  │  (Res)  │  │  (Res)   │   │
│  └──────┘  └──────┘  └──────┘  └─────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Save/Load Integration

### Current State Snapshot

**What exists:**
- `GameState.hero: Hero` (Resource) with `equipped_items: Dictionary` (slot → Item Resource)
- `GameState.currency_counts: Dictionary` (type → int)
- All data extends Resource: Item, Affix, Implicit, Hero, Currency classes
- Hero.update_stats() recalculates total_dps, total_defense, resistances from equipped items

**What's missing:**
- No save file persistence
- No way to restore game state on launch
- No UI for save/load actions

### Save System Architecture

**Pattern: Resource Snapshot with Deep Copy**

Godot 4.5 provides `ResourceSaver.save()` and `ResourceLoader.load()` for Resource-based save systems. This is the recommended approach when you already have Resource-based data (HIGH confidence).

**Why this fits:**
- All game data already extends Resource
- Static typing prevents JSON serialization errors
- Works seamlessly with Godot data types (Vector2, Color, etc.)
- Editor can inspect `.tres` save files during development

**Critical limitation:** `Resource.duplicate(true)` does NOT deep copy subresources in Arrays or Dictionaries (see [Godot issue #74918](https://github.com/godotengine/godot/issues/74918)). Since Hero has `equipped_items: Dictionary` with Item Resources containing `prefixes: Array[Affix]` and `suffixes: Array[Affix]`, a shallow duplicate will share references.

### New Components Needed

#### 1. SaveData Resource (new file: `models/save/save_data.gd`)

```gdscript
class_name SaveData extends Resource

@export var hero_data: Hero
@export var currency_counts: Dictionary
@export var save_version: int = 1
@export var save_timestamp: int
```

**Rationale:** Container Resource for all persistent state. Exported vars enable editor inspection.

#### 2. SaveManager Singleton (new file: `autoloads/save_manager.gd`)

```gdscript
extends Node

const SAVE_PATH := "user://save_game.tres"

func save_game() -> bool:
	var save_data := SaveData.new()
	save_data.hero_data = _deep_copy_hero(GameState.hero)
	save_data.currency_counts = GameState.currency_counts.duplicate(true)
	save_data.save_timestamp = Time.get_unix_time_from_system()

	var err := ResourceSaver.save(save_data, SAVE_PATH)
	return err == OK

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var save_data: SaveData = ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	if save_data == null:
		return false

	GameState.hero = save_data.hero_data
	GameState.currency_counts = save_data.currency_counts
	GameEvents.equipment_changed.emit("all", null)  # Trigger UI refresh
	return true

func _deep_copy_hero(hero: Hero) -> Hero:
	var copy := Hero.new()
	copy.health = hero.health
	copy.max_health = hero.max_health
	copy.hero_name = hero.hero_name

	# Deep copy equipped items
	copy.equipped_items = {}
	for slot in hero.equipped_items:
		var item = hero.equipped_items[slot]
		if item != null:
			copy.equipped_items[slot] = _deep_copy_item(item)

	copy.update_stats()
	return copy

func _deep_copy_item(item: Item) -> Item:
	# Duplicate base (shallow copy)
	var copy = item.duplicate(false)

	# Manually deep copy affixes arrays
	copy.prefixes = []
	for prefix in item.prefixes:
		copy.prefixes.append(_deep_copy_affix(prefix))

	copy.suffixes = []
	for suffix in item.suffixes:
		copy.suffixes.append(_deep_copy_affix(suffix))

	# Deep copy implicit
	if item.implicit != null:
		copy.implicit = _deep_copy_affix(item.implicit)

	copy.update_value()
	return copy

func _deep_copy_affix(affix: Affix) -> Affix:
	var copy := Affix.new()
	copy.affix_name = affix.affix_name
	copy.type = affix.type
	copy.min_value = affix.min_value
	copy.max_value = affix.max_value
	copy.value = affix.value
	copy.tier = affix.tier
	copy.tags = affix.tags.duplicate()
	copy.stat_types = affix.stat_types.duplicate()
	copy.tier_range = affix.tier_range
	copy.base_min = affix.base_min
	copy.base_max = affix.base_max
	return copy
```

**Rationale:** Custom deep copy avoids Godot's duplicate() limitation with nested Array/Dictionary Resources. Uses `CACHE_MODE_IGNORE` to prevent stale cached saves (Godot 4 improvement).

**Sources:**
- [Saving and Loading Games in Godot 4 (with resources) | GDQuest](https://www.gdquest.com/library/save_game_godot4/)
- [Godot Resource.duplicate(true) doesn't duplicate subresources in Arrays/Dictionaries](https://github.com/godotengine/godot/issues/74918)
- [Duplicate Godot custom resources deeply, for real](https://simondalvai.org/blog/godot-duplicate-resources/)

#### 3. Save/Load UI (modify: `scenes/main_view.gd` and `main.tscn`)

Add buttons to NavigationPanel:
- Save button → `SaveManager.save_game()`
- Load button → `SaveManager.load_game()` + refresh all views

**Integration point:** main_view already has `@onready` references to all views. After load, call:
```gdscript
hero_view.update_all_slots()
hero_view.update_stats_display()
crafting_view.update_currency_button_states()
gameplay_view.update_display()
```

### Modified Components

| Component | Current | After Save/Load |
|-----------|---------|-----------------|
| `autoloads/game_state.gd` | Creates new Hero in _ready() | Check `SaveManager.has_save()`, load if exists, else create new |
| `scenes/main_view.gd` | 3 nav buttons | +2 buttons (Save, Load), connect to SaveManager |
| `project.godot` | 4 autoloads | +1 autoload: SaveManager |

**No changes needed:** Item, Hero, Affix classes already extend Resource.

### Data Flow: Save Operation

```
[User clicks Save]
       ↓
[main_view] → SaveManager.save_game()
       ↓
[SaveManager creates SaveData Resource]
       ↓
[Deep copy GameState.hero (custom logic)]
[Copy GameState.currency_counts (shallow OK)]
       ↓
[ResourceSaver.save(save_data, "user://save_game.tres")]
       ↓
[Return success/failure to UI]
```

### Data Flow: Load Operation

```
[User clicks Load]
       ↓
[main_view] → SaveManager.load_game()
       ↓
[ResourceLoader.load("user://save_game.tres", CACHE_MODE_IGNORE)]
       ↓
[Overwrite GameState.hero and currency_counts]
       ↓
[Emit GameEvents.equipment_changed("all", null)]
       ↓
[hero_view, crafting_view, gameplay_view refresh via signals]
```

**Key consideration:** Use `CACHE_MODE_IGNORE` flag to prevent Godot from returning stale cached Resource (Godot 4 improvement over Godot 3).

**Source:** [Save and Load: Godot 4 Cheat Sheet | GDQuest](https://www.gdquest.com/library/cheatsheet_save_systems/)

---

## Side-by-Side UI Layout Integration

### Current Layout Architecture

**What exists:**
- main.tscn root: Node2D with 3 child CanvasLayers (CraftingView, HeroView, GameplayView)
- main_view.gd: Switches views via `visible = true/false`
- NavigationPanel: 3 buttons (Crafting, Hero, Adventure) at bottom (600-700px)
- Viewport: 1200x700px
- Each view is full-screen when visible

**Problem:** Views are mutually exclusive. Cannot see hero stats while crafting.

### New Layout Architecture

**Pattern: HBoxContainer Split with Persistent Panels**

Remove tab navigation. Show hero and crafting side-by-side simultaneously. Keep gameplay view separate (combat needs full attention).

#### Scene Tree Changes (modify: `scenes/main.tscn`)

**Before:**
```
MainView (Node2D)
├── NavigationPanel (ColorRect with 3 buttons)
├── CraftingView (Node2D, visible toggled)
├── HeroView (Node2D, visible toggled)
└── GameplayView (Node2D, visible toggled)
```

**After:**
```
MainView (Node2D)
├── NavigationPanel (ColorRect with 2 buttons: Adventure, Save, Load)
├── SideBySideContainer (HBoxContainer)  # NEW
│   ├── HeroView (PanelContainer → Node2D)  # LEFT HALF
│   └── CraftingView (PanelContainer → Node2D)  # RIGHT HALF
└── GameplayView (Node2D, visible toggled)  # FULLSCREEN when active
```

**HBoxContainer setup:**
- Position: (0, 0) to (1200, 600)
- Separation: 10px between hero and crafting panels
- Children use Size Flags: Fill + Expand with Stretch Ratio 1:1 (equal width)

**Sources:**
- [Using Containers — Godot Engine (stable) documentation](https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html)
- [HBoxContainer — Godot Engine (4.5) documentation](https://docs.godotengine.org/en/4.5/classes/class_hboxcontainer.html)
- [Overview of Godot UI containers | GDQuest](https://school.gdquest.com/courses/learn_2d_gamedev_godot_4/start_a_dialogue/all_the_containers)

#### Layout Calculations

Available space: 1200px wide × 600px tall (700 - 100 for nav panel)

**With 10px separation:**
- Hero panel: 595px wide × 600px tall
- Crafting panel: 595px wide × 600px tall

**Current hero_view.tscn layout (absolute positions):**
- Equipment slots: 700-850px (right side)
- Stats panels: 884-1200px (far right)
- Crafted item panel: 0-320px (left)

**Adjustments needed:**
All absolute `offset_` positions must scale to fit 595px width. Use Container nodes or anchors for responsive layout.

#### New Components Needed

1. **SideBySideContainer (HBoxContainer)** — add to main.tscn
2. **Wrapper PanelContainers** — wrap HeroView and CraftingView for visual separation

**PanelContainer benefits:**
- Draws background rectangle around child
- Single child only (perfect for view wrappers)
- Built-in padding via theme overrides

**Source:** [UI Layout using Containers in Godot](https://gdscript.com/solutions/ui-layout-using-containers-in-godot/)

#### Modified Components

| Component | Current | After Side-by-Side |
|-----------|---------|-------------------|
| `scenes/main.tscn` | 3 separate views toggled | HBoxContainer with hero+crafting always visible |
| `scenes/main_view.gd` | show_view() toggles 3 views | show_view() only toggles gameplay vs side-by-side |
| `scenes/hero_view.tscn` | Absolute positions for 1200px | Anchors/containers for 595px |
| `scenes/crafting_view.tscn` | Absolute positions for 1200px | Anchors/containers for 595px |
| NavigationPanel | 3 buttons (Crafting, Hero, Adventure) | 1 button (Adventure) + Save/Load |

**No changes needed:** Signal connections in main_view.gd still work (crafting_view.item_finished → hero_view.set_last_crafted_item).

### Data Flow: View Switching

**Before (3-way toggle):**
```
[User presses TAB/number key]
       ↓
[main_view.show_view(view_name)]
       ↓
[Hide all 3 views, show selected]
       ↓
[Sync CanvasLayer visibility]
```

**After (2-mode toggle):**
```
[User presses Adventure button]
       ↓
[main_view.show_view("gameplay")]
       ↓
[Hide SideBySideContainer, show GameplayView]
       ↓
[Sync CombatUI CanvasLayer visibility]

[User presses TAB/ESC]
       ↓
[main_view.show_view("side_by_side")]
       ↓
[Show SideBySideContainer, hide GameplayView]
```

**Benefit:** Hero stats and crafting inventory always visible together. No tab switching during crafting workflow.

---

## Crafting UX Feedback Integration

### Current Crafting Flow

**What exists:**
- crafting_view.gd: Click item → select currency → click item → currency applied
- hero_view.gd: Crafted item stored in `last_crafted_item`, shown in CraftedItemStatsPanel
- Equipment slots show item stats on hover (via `currently_hovered_slot`)

**Problem:** Cannot compare crafted item stats to equipped item stats BEFORE equipping.

### New UX: Before/After Comparison

**Pattern: Temporary Stat Preview via Signals**

When hovering over equipment slot with `last_crafted_item` available, show:
1. Current equipped item stats (already exists)
2. Crafted item stats (already exists in separate panel)
3. **NEW:** Stat delta preview (DPS change, defense change, etc.)

**No tooltips needed.** ARPG pattern: side-by-side panels show "current" vs "new" (Path of Exile, Diablo, Last Epoch).

**Source:** [Game UI Database - Weapon Comparison Pickup](https://www.gameuidatabase.com/index.php?scrn=154)

#### New Component: StatComparisonPanel

**File:** `scenes/stat_comparison_panel.gd` (new)

```gdscript
class_name StatComparisonPanel extends PanelContainer

@onready var comparison_label: Label = $ComparisonLabel

func show_comparison(current_item: Item, new_item: Item, slot: String) -> void:
	visible = true
	var current_stats = _get_item_contribution(current_item, slot)
	var new_stats = _get_item_contribution(new_item, slot)

	var text := "Equipping will change:\n\n"
	text += _format_stat_delta("DPS", new_stats.dps - current_stats.dps)
	text += _format_stat_delta("Armor", new_stats.armor - current_stats.armor)
	text += _format_stat_delta("Evasion", new_stats.evasion - current_stats.evasion)
	text += _format_stat_delta("Energy Shield", new_stats.es - current_stats.es)

	comparison_label.text = text

func hide_comparison() -> void:
	visible = false

func _format_stat_delta(stat_name: String, delta: float) -> String:
	if delta == 0:
		return ""
	var color := Color.GREEN if delta > 0 else Color.RED
	var sign := "+" if delta > 0 else ""
	return "[color=%s]%s: %s%.1f[/color]\n" % [color.to_html(), stat_name, sign, delta]

func _get_item_contribution(item: Item, slot: String) -> Dictionary:
	# Calculate what this specific item contributes to hero stats
	# (Not total hero stats, just this item's portion)
	var stats := {"dps": 0.0, "armor": 0, "evasion": 0, "es": 0}

	if item == null:
		return stats

	if item is Weapon:
		stats.dps = item.dps
	elif item is Ring:
		stats.dps = item.dps
	elif "base_armor" in item:
		stats.armor = item.base_armor
		stats.evasion = item.base_evasion if "base_evasion" in item else 0
		stats.es = item.base_energy_shield if "base_energy_shield" in item else 0

	return stats
```

**Rationale:** Shows item-level stat contribution deltas, not total hero stats. Prevents confusion (e.g., "Why did DPS only go up 10 when item has 50 DPS?" — because old item had 40 DPS).

#### Integration Points

**Modify:** `scenes/hero_view.gd`

Add StatComparisonPanel as child node. Connect to hover signals:

```gdscript
func _on_item_slot_hover_entered(slot: ItemSlot) -> void:
	currently_hovered_slot = slot
	update_item_stats_display()

	# NEW: Show comparison if hovering with last_crafted_item available
	if last_crafted_item != null and can_equip_item(last_crafted_item, slot):
		var slot_name = get_slot_name(slot).to_lower()
		var current_item = GameState.hero.equipped_items[slot_name]
		stat_comparison_panel.show_comparison(current_item, last_crafted_item, slot_name)

func _on_item_slot_hover_exited(_slot: ItemSlot) -> void:
	currently_hovered_slot = ItemSlot.NONE
	update_item_stats_display()
	stat_comparison_panel.hide_comparison()  # NEW
```

**No new signals needed.** Reuse existing `mouse_entered`/`mouse_exited` connections.

#### Scene Tree Changes

**scenes/hero_view.tscn:**
```
HeroView (Node2D)
├── [existing nodes]
└── StatComparisonPanel (PanelContainer)  # NEW
    └── ComparisonLabel (Label with RichText enabled)
```

**Position:** Float above equipment slots (e.g., 350-550px horizontal, 200-400px vertical).

### Data Flow: Stat Comparison

```
[User hovers equipment slot with last_crafted_item available]
       ↓
[hero_view._on_item_slot_hover_entered(slot)]
       ↓
[Check: can_equip_item(last_crafted_item, slot)?]
       ↓ YES
[Get current_item from GameState.hero.equipped_items[slot]]
       ↓
[stat_comparison_panel.show_comparison(current_item, last_crafted_item, slot)]
       ↓
[Calculate stat deltas (item contribution, not total hero stats)]
       ↓
[Display green (+) or red (-) deltas with RichText color]

[User moves mouse away]
       ↓
[hero_view._on_item_slot_hover_exited()]
       ↓
[stat_comparison_panel.hide_comparison()]
```

**Key insight:** Item-level comparison prevents confusion. Total hero stats change calculation would require temp-equipping item (expensive, complex state management).

---

## Build Order and Dependencies

### Phase Structure Recommendation

**Phase 1: Save/Load Foundation**
- Add SaveData Resource
- Add SaveManager autoload with deep copy logic
- Add Save/Load buttons to main_view
- Test: Save game with equipped items, quit, load, verify items restored

**Rationale:** Independent of UI changes. Establishes persistence layer.

**Phase 2: Side-by-Side Layout**
- Modify main.tscn: Add HBoxContainer, wrap views in PanelContainers
- Modify main_view.gd: Change show_view() to 2-mode toggle
- Adjust hero_view.tscn and crafting_view.tscn for 595px width
- Test: Hero and crafting panels visible simultaneously, gameplay view still toggles

**Rationale:** Requires scene restructuring. Do before adding comparison UI to avoid repositioning twice.

**Phase 3: Crafting UX — Stat Comparison**
- Add StatComparisonPanel scene
- Modify hero_view.gd: Connect hover signals to comparison panel
- Test: Hover equipment slot with crafted item → see stat deltas

**Rationale:** Depends on side-by-side layout (comparison panel positioning assumes new layout).

### Dependency Graph

```
Phase 1: Save/Load
    ↓ (no dependency, parallel possible)
Phase 2: Side-by-Side Layout
    ↓ (comparison panel position depends on new layout)
Phase 3: Stat Comparison UI
```

**Critical path:** Phase 2 → Phase 3. Phase 1 can run in parallel or first.

---

## Integration Points Summary

### What Gets Serialized (Save/Load)

| Data | Location | Serialization Strategy |
|------|----------|----------------------|
| Hero stats | GameState.hero (Resource) | Deep copy with custom logic |
| Equipment | Hero.equipped_items (Dictionary) | Deep copy Items + Affixes arrays |
| Currencies | GameState.currency_counts (Dictionary) | Shallow duplicate (primitives) |
| Combat state | Not persisted | Recreate from equipped_items on load |

**NOT serialized:**
- crafting_view.current_item (transient work-in-progress)
- crafting_view.crafting_inventory (regenerate from drops)
- gameplay_view.item_bases_collected (per-session drops)

**Rationale:** Only persist hero progression (equipment, currencies). Crafting work resets on load (matches ARPG patterns — don't save half-crafted items).

### View Communication After Changes

**Existing signals (unchanged):**
```
crafting_view.item_finished → hero_view.set_last_crafted_item
hero_view.equipment_changed → gameplay_view.refresh_clearing_speed
gameplay_view.item_base_found → crafting_view.set_new_item_base
gameplay_view.currencies_found → crafting_view.on_currencies_found
```

**New signal usage:**
```
SaveManager (after load) → GameEvents.equipment_changed.emit("all", null)
    ↓
    [All views listening to GameEvents refresh displays]
```

**No new cross-view signals needed.** Stat comparison is internal to hero_view (hover events).

### Components: New vs Modified

**New files:**
- `models/save/save_data.gd` (Resource)
- `autoloads/save_manager.gd` (Node singleton)
- `scenes/stat_comparison_panel.gd` (scene + script)
- `scenes/stat_comparison_panel.tscn`

**Modified files:**
- `scenes/main.tscn` (add HBoxContainer, Save/Load buttons)
- `scenes/main_view.gd` (2-mode view toggle, SaveManager calls)
- `scenes/hero_view.tscn` (add StatComparisonPanel, responsive layout)
- `scenes/hero_view.gd` (connect comparison panel to hover signals)
- `scenes/crafting_view.tscn` (responsive layout for 595px)
- `autoloads/game_state.gd` (_ready checks SaveManager.has_save())
- `project.godot` (add SaveManager autoload)

**Unchanged files:**
- `models/` classes (Item, Hero, Affix, etc.) — already Resource-based
- `autoloads/game_events.gd` — existing signals sufficient
- `scenes/gameplay_view.gd` — no layout changes (still full-screen)

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Using JSON for Resource Save Data

**What people do:** Convert Resources to Dictionary → JSON.stringify() → save as .json

**Why it's wrong:**
- Loses static typing (load returns Dictionary, not Hero)
- Manual serialization for Godot types (Vector2, Color)
- Nested resources (Item with Affixes array) require recursive dict conversion

**Do this instead:** Use ResourceSaver/ResourceLoader with Resource classes. Already extends Resource.

**Source:** [Resource-based architecture for Godot 4 | Medium](https://medium.com/@sfmayke/resource-based-architecture-for-godot-4-25bd4b2d9018)

### Anti-Pattern 2: Using Resource.duplicate(true) for Deep Copy

**What people do:** Assume `hero.duplicate(true)` deep copies nested arrays

**Why it's wrong:** Godot 4's duplicate() does NOT deep copy Resources inside Arrays or Dictionaries. Hero.equipped_items with Item Resources containing Affix arrays will share references.

**Do this instead:** Implement custom deep copy that manually duplicates arrays:

```gdscript
func _deep_copy_item(item: Item) -> Item:
	var copy = item.duplicate(false)  # Shallow
	copy.prefixes = []
	for prefix in item.prefixes:
		copy.prefixes.append(_deep_copy_affix(prefix))
	# ... repeat for suffixes, implicit
	return copy
```

**Source:** [Resource.duplicate(true) doesn't duplicate subresources stored in Array or Dictionary](https://github.com/godotengine/godot/issues/74918)

### Anti-Pattern 3: Absolute Positioning in Resizable Containers

**What people do:** Use `offset_left/right/top/bottom` for all UI elements in HBoxContainer

**Why it's wrong:** Container expects children to use Size Flags (Fill, Expand) for responsive layout. Absolute positions override container behavior.

**Do this instead:**
- Use anchors for percentage-based positioning inside panels
- Use nested VBoxContainer/HBoxContainer for structured layouts
- Set Size Flags: Fill + Expand on container children

**Source:** [Using Containers — Godot Engine documentation](https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html)

### Anti-Pattern 4: Showing Total Hero Stats in Item Comparison

**What people do:** Compare total hero DPS before vs after equipping

**Why it's wrong:**
- User sees "Equip this 100 DPS weapon" but total DPS only goes up 50 (because unequipping 50 DPS weapon)
- Requires temp-equipping item to calculate (mutates state during preview)
- Confusing when item has affixes affecting multiple stats

**Do this instead:** Show item contribution delta:
```
Current weapon: 50 DPS
New weapon: 100 DPS
Display: "DPS: +50"
```

Calculate delta from item properties only, not total hero stats.

---

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 0-100 save files | Current architecture sufficient. ResourceSaver handles .tres files efficiently. |
| 100+ save files | Add save slot UI (numbered saves). Use file naming: `save_slot_01.tres`, `save_slot_02.tres`. |
| Cloud saves | Replace ResourceSaver with HTTP upload/download + local cache. SaveData Resource serializes to bytes with `var2bytes()` for network transfer. |

### Current Bottlenecks

**Not a concern for idle ARPG:**
- Save file size: Hero + 5 equipped items + 6 currency counts ≈ 5-10KB
- Save/load time: ResourceSaver/Loader handles <1KB resources instantly
- Deep copy performance: 5 items × 6 affixes average × manual copy = negligible (<1ms)

**Only matters if:**
- Expanding to 100+ item stash (add incremental save — only dirty items)
- Adding cloud sync (batch updates, avoid save on every currency drop)

---

## Sources

**Save/Load:**
- [Saving and Loading Games in Godot 4 (with resources) | GDQuest Library](https://www.gdquest.com/library/save_game_godot4/)
- [Saving games — Godot Engine (stable) documentation](https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html)
- [Resource-based architecture for Godot 4 | Medium](https://medium.com/@sfmayke/resource-based-architecture-for-godot-4-25bd4b2d9018)
- [Save and Load: Godot 4 Cheat Sheet | GDQuest Library](https://www.gdquest.com/library/cheatsheet_save_systems/)
- [Resource.duplicate(true) doesn't duplicate subresources in Arrays/Dictionaries](https://github.com/godotengine/godot/issues/74918)
- [Duplicate Godot custom resources deeply, for real](https://simondalvai.org/blog/godot-duplicate-resources/)

**UI Layout:**
- [Using Containers — Godot Engine (stable) documentation](https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html)
- [HBoxContainer — Godot Engine (4.5) documentation](https://docs.godotengine.org/en/4.5/classes/class_hboxcontainer.html)
- [Overview of Godot UI containers | GDQuest](https://school.gdquest.com/courses/learn_2d_gamedev_godot_4/start_a_dialogue/all_the_containers)
- [UI Layout using Containers in Godot](https://gdscript.com/solutions/ui-layout-using-containers-in-godot/)

**Inventory/Equipment Systems:**
- [GitHub - alfredbaudisch/GodotDynamicInventorySystem](https://github.com/alfredbaudisch/GodotDynamicInventorySystem)
- [How To Build An Inventory System In Godot 4 - GameDev Academy](https://gamedevacademy.org/godot-inventory-system-tutorial/)

**Crafting UX Patterns:**
- [Game UI Database - Weapon Comparison Pickup](https://www.gameuidatabase.com/index.php?scrn=154)

---

*Architecture research for: Hammertime v1.3 milestone — Save/Load, Side-by-Side UI, Crafting UX*
*Researched: 2026-02-17*
