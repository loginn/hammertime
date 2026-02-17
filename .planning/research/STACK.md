# Stack Research: Save/Load, UI Layout, Crafting Feedback

**Domain:** Godot 4.5 Idle ARPG Enhancement
**Researched:** 2026-02-17
**Confidence:** HIGH

## Recommended Stack

### Core Persistence APIs

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| ResourceSaver | Godot 4.5 | Save Hero + equipment Resources | Native support for Resource references, preserves nested Item/Affix structure, static typing maintained |
| ResourceLoader | Godot 4.5 | Load Hero + equipment Resources | CACHE_MODE_IGNORE handles nested resources correctly, no manual deserialization |
| FileAccess.store_var() | Godot 4.5 | Save currency Dictionary | Fast binary serialization, compact format, native Godot type support |
| FileAccess.get_var() | Godot 4.5 | Load currency Dictionary | Direct Dictionary restore without type conversion |

### UI Layout Containers

| Container | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| HBoxContainer | Godot 4.5 | Side-by-side hero/crafting layout | Default choice for fixed horizontal split without resizing |
| HSplitContainer | Godot 4.5 | Draggable side-by-side layout | If user-controlled panel sizing desired (adds complexity) |
| MarginContainer | Godot 4.5 | Screen-edge padding wrapper | Wrap top-level layout for consistent margins |
| PanelContainer | Godot 4.5 | Visually separated sections | Background panels for hero/crafting sections |

### UI Feedback Systems

| API/Class | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| Tween (create_tween) | Godot 4.5 | Smooth property animations | Button presses, stat changes, currency animations |
| Label.text | Godot 4.5 | Dynamic text updates | Stat displays, currency counts (performant for simple updates) |
| PopupPanel | Godot 4.5 | Tooltip/feedback overlays | Crafting result notifications, error messages |
| Control.modulate | Godot 4.5 | Color flash feedback | Success/failure visual feedback via Tween |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| user:// path | Save file location | ONLY valid path for exported games (res:// is read-only after export) |
| .tres format | Text Resource files | Human-readable for debugging (dev), switch to .res (binary) for production |
| ResourceLoader.exists() | Save file detection | Check before load to avoid errors, create new save if missing |

## Installation

No external packages required. All APIs are built into Godot 4.5 core.

```gdscript
# No installation needed - use Godot built-ins:
# - ResourceSaver/ResourceLoader
# - FileAccess
# - Tween via create_tween()
# - Container nodes via scene tree
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| ResourceSaver | FileAccess.store_var() | NEVER for Hero/Items - loses Resource references and type safety |
| ResourceSaver | JSON | NEVER - requires manual Vector2/Color conversion, no nested Resource support |
| ResourceSaver | ConfigFile | NEVER - INI format unsuitable for complex nested data |
| HBoxContainer | HSplitContainer | Only if user-controlled panel resizing is explicitly required |
| Label.text | RichTextLabel | Only if BBCode formatting needed (performance cost, avoid for simple stats) |
| Tween | AnimationPlayer | Only for pre-designed complex multi-property sequences (overkill for simple feedback) |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| JSON for save/load | No native support for Item/Affix/Implicit Resource references, requires manual serialization/deserialization, error-prone | ResourceSaver + FileAccess.store_var() |
| ConfigFile for save/load | INI format unsuitable for nested Resource arrays, designed for simple key-value config | ResourceSaver + FileAccess.store_var() |
| RichTextLabel for stat displays | Slow in Godot 4.x, rebuilds entire BBCode on text change, 10x+ slower than Godot 3.5 | Label.text with direct assignment |
| += operator on RichTextLabel.text | Replaces entire text, very slow | append_text() method if RichTextLabel required |
| External save plugins | Unnecessary complexity, Godot built-ins handle Resource persistence natively | Built-in ResourceSaver/ResourceLoader |
| SQLite for save data | Massive overkill for single-player save, adds dependency, slower than binary | ResourceSaver + FileAccess.store_var() |

## Stack Patterns by Feature

### Save/Load Pattern (Recommended)

**Two-file approach:**
- **user://savegame.tres** - Hero Resource (includes equipped_items Dictionary with Item references)
- **user://currencies.sav** - Binary currency Dictionary (FileAccess.store_var)

**Why split:**
- ResourceSaver handles nested Item → Affix → Implicit references automatically
- Currency Dictionary has no Resource dependencies, binary is faster/smaller
- Hero changes less frequently than currencies (craft operations spam currency updates)

**Save implementation:**
```gdscript
func save_game() -> void:
    # Save Hero Resource (includes all equipped Items with nested Affixes)
    var hero_path := "user://savegame.tres"
    var save_result := ResourceSaver.save(GameState.hero, hero_path)
    if save_result != OK:
        push_error("Failed to save hero")

    # Save currency Dictionary as binary
    var currency_file := FileAccess.open("user://currencies.sav", FileAccess.WRITE)
    if currency_file:
        currency_file.store_var(GameState.currency_counts)
        currency_file.close()
```

**Load implementation:**
```gdscript
func load_game() -> void:
    # Load Hero Resource
    if ResourceLoader.exists("user://savegame.tres"):
        GameState.hero = ResourceLoader.load(
            "user://savegame.tres",
            "",
            ResourceLoader.CACHE_MODE_IGNORE  # Critical for nested resources
        )
    else:
        GameState.hero = Hero.new()  # Fresh start

    # Load currency Dictionary
    if FileAccess.file_exists("user://currencies.sav"):
        var currency_file := FileAccess.open("user://currencies.sav", FileAccess.READ)
        if currency_file:
            GameState.currency_counts = currency_file.get_var()
            currency_file.close()
```

### UI Layout Pattern (Recommended)

**Side-by-side fixed layout:**
```
MarginContainer (Full Rect, 20px margins)
└─ HBoxContainer (Fill parent)
   ├─ PanelContainer (Expand Fill, stretch_ratio: 1)
   │  └─ hero_view (existing scene)
   └─ PanelContainer (Expand Fill, stretch_ratio: 1)
      └─ crafting_view (existing scene)
```

**Why this structure:**
- MarginContainer provides consistent screen-edge padding
- HBoxContainer arranges panels horizontally (no draggable split complexity)
- PanelContainer with Expand Fill + stretch_ratio: 1 = equal 50/50 split
- Existing hero_view/crafting_view scenes slot in unchanged
- gameplay_view becomes overlay or tab (not shown simultaneously)

**If draggable split needed:**
Replace HBoxContainer with HSplitContainer, set split_offset: 600 (half of 1200px width)

### Crafting Feedback Pattern (Recommended)

**Visual feedback on craft success:**
```gdscript
func on_craft_success(item: Item) -> void:
    # Flash green feedback
    var tween := create_tween()
    tween.tween_property(craft_button, "modulate", Color.GREEN, 0.15)
    tween.tween_property(craft_button, "modulate", Color.WHITE, 0.15)

    # Show result popup (optional)
    show_craft_result_popup(item)
```

**Stat update animation:**
```gdscript
func update_stat_label(label: Label, old_value: int, new_value: int) -> void:
    var tween := create_tween()
    var temp_obj := {"value": old_value}
    tween.tween_property(temp_obj, "value", new_value, 0.3)
    tween.tween_callback(func(): label.text = str(new_value))
```

**Currency animation (subtle):**
```gdscript
func animate_currency_change(currency_label: Label, amount: int) -> void:
    # Pulse scale on currency change
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
    tween.tween_property(currency_label, "scale", Vector2(1.2, 1.2), 0.2)
    tween.tween_property(currency_label, "scale", Vector2.ONE, 0.3)
```

## Critical Integration Notes

### Resource Save Gotchas

**CACHE_MODE_IGNORE is mandatory for nested resources:**
```gdscript
# WRONG - cached load may have stale references
var hero = ResourceLoader.load("user://savegame.tres")

# CORRECT - forces fresh load with current nested Item/Affix instances
var hero = ResourceLoader.load("user://savegame.tres", "", ResourceLoader.CACHE_MODE_IGNORE)
```

**Typed arrays in Resources persist correctly in Godot 4.5:**
Your current code uses `Array[Affix]` for prefixes/suffixes - this WILL save/load correctly via ResourceSaver. Earlier Godot 4.x versions had issues, but Godot 4.5 handles typed Resource arrays properly.

**Dictionary with null values:**
Hero.equipped_items contains null for empty slots. ResourceSaver handles this correctly:
```gdscript
# This structure saves/loads fine
equipped_items = {
    "weapon": LightSword instance,
    "helmet": null,  # Empty slot
    "armor": BasicArmor instance,
    # ...
}
```

### UI Layout Gotchas

**Size flags are critical for proper filling:**
```gdscript
# Make PanelContainer expand to fill HBoxContainer space
panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

# Equal split with stretch_ratio
left_panel.stretch_ratio = 1.0
right_panel.stretch_ratio = 1.0
```

**Anchor presets for MarginContainer:**
Set MarginContainer anchor preset to "Full Rect" in editor or via code:
```gdscript
margin_container.set_anchors_preset(Control.PRESET_FULL_RECT)
```

### Performance Considerations

**Label vs RichTextLabel:**
Based on research, RichTextLabel is significantly slower in Godot 4.x. For your stat displays (DPS, defense, resistance numbers), use Label.text with direct string assignment. Only use RichTextLabel if you need BBCode formatting (colored text, etc.).

**Tween cleanup:**
Tweens auto-cleanup when finished by default in Godot 4.5. No manual kill() needed unless you want to interrupt mid-animation.

**Save frequency:**
- Save Hero: Only on equipment change (infrequent)
- Save currencies: After every craft (frequent, but binary save is fast)
- Consider auto-save timer (every 30-60 seconds) + save on game close

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| Godot 4.5 | All built-in APIs | No external dependencies, all APIs core to engine |
| ResourceSaver | Godot 4.5+ Resources | Works with class_name Resources extending Resource |
| FileAccess.store_var() | Godot 4.5+ types | Supports Dictionary, Array, Vector2, Color natively |

## Implementation Checklist

- [ ] Create SaveManager autoload with save_game()/load_game() methods
- [ ] Add CACHE_MODE_IGNORE to ResourceLoader.load() calls
- [ ] Restructure main_view layout: MarginContainer → HBoxContainer → 2x PanelContainer
- [ ] Set size flags and stretch ratios for equal 50/50 split
- [ ] Replace hero_view/crafting_view tab switching with simultaneous visibility
- [ ] Add Tween feedback to craft operations (modulate flash, scale pulse)
- [ ] Replace RichTextLabel with Label for stat displays (if any exist)
- [ ] Add auto-save timer (optional but recommended)
- [ ] Test save/load with equipped items containing nested Affixes
- [ ] Test save/load with null equipment slots

## Sources

**HIGH Confidence (Official Docs + Community Verification):**
- [Saving and Loading Games in Godot 4 (with resources) | GDQuest Library](https://www.gdquest.com/library/save_game_godot4/) - Resource save/load patterns
- [Save and Load: Godot 4 Cheat Sheet | GDQuest Library](https://www.gdquest.com/library/cheatsheet_save_systems/) - FileAccess vs Resources comparison
- [ResourceSaver — Godot Engine (stable) documentation](https://docs.godotengine.org/en/stable/classes/class_resourcesaver.html) - Official API
- [Saving/loading data :: Godot 4 Recipes](https://kidscancode.org/godot_recipes/4.x/basics/file_io/index.html) - Implementation patterns
- [Using Containers — Godot Engine (stable) documentation](https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html) - Container usage
- [HBoxContainer — Godot Engine (4.5) documentation](https://docs.godotengine.org/en/4.5/classes/class_hboxcontainer.html) - HBoxContainer API
- [HSplitContainer — Godot Engine (stable) documentation](https://docs.godotengine.org/en/stable/classes/class_hsplitcontainer.html) - HSplitContainer API
- [Tween — Godot Engine (4.5) documentation](https://docs.godotengine.org/en/4.5/classes/class_tween.html) - Tween API
- [Tweens in Godot 4 - Tutorial](https://www.gotut.net/tweens-in-godot-4/) - Tween usage examples
- [Smooth Animations with Tween | ういやまラボ](https://uhiyama-lab.com/en/notes/godot/tween-smooth-animation/) - Tween patterns

**MEDIUM Confidence (Community Forums, verified patterns):**
- [Godot 4.2.2 Resource based Inventory Save and Load](https://forum.godotengine.org/t/godot-4-2-2-resource-based-inventory-save-and-load-using-resourcesaver/88712) - Nested resource handling
- [Saving Nested Custom Resources](https://forum.godotengine.org/t/saving-nested-custom-resources/123063) - CACHE_MODE_IGNORE pattern
- [RichTextLabel performance observations](https://github.com/godotengine/godot-proposals/discussions/7510) - Performance warning
- [Responsive UI Design in Godot: Anchors, Size Flags](https://www.wayline.io/blog/responsive-ui-design-godot-anchors-size-flags) - Layout best practices
- [Control Node Fundamentals and Layout Containers](https://uhiyama-lab.com/en/notes/godot/control-layout-containers/) - Container patterns
- [SplitContainer — Godot Engine (stable) documentation](https://docs.godotengine.org/en/stable/classes/class_splitcontainer.html) - split_offset property

**Implementation Comparison Reference:**
- [Implementing Save/Load Systems - Comparison of JSON, ConfigFile, and Custom Resources](https://uhiyama-lab.com/en/notes/godot/save-load-system/) - Why Resources win for complex data
- [Popup Tooltip UI design in Godot 4](https://www.patreon.com/posts/popup-tooltip-ui-105814975) - PopupPanel styling

---
*Stack research for: Hammertime v1.3 Milestone - Save/Load, UI Layout, Crafting Feedback*
*Researched: 2026-02-17*
*Confidence: HIGH - All recommendations based on Godot 4.5 official documentation and verified community patterns*
