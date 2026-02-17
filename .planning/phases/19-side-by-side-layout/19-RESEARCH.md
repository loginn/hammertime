# Phase 19: Side-by-Side Layout - Research

**Researched:** 2026-02-17
**Domain:** Godot 4.5 UI layout restructuring (Node2D-based scenes, CanvasLayer visibility, tab navigation)
**Confidence:** HIGH

## Summary

Phase 19 replaces the current three-tab navigation (Crafting / Hero / Adventure) with a unified "Forge" view that displays hero equipment and crafting side-by-side, plus a top tab bar for switching between The Forge, Combat, and Settings. The viewport changes from 1200x700 to 1280x720.

The current architecture uses Node2D-based scenes with absolute pixel positioning (no Godot Control layout containers). Each view (CraftingView, HeroView, GameplayView) is a separate Node2D child of MainView, toggled via `.visible`. A bottom NavigationPanel (ColorRect at y=600) holds three buttons plus a Settings button. Settings is a modal overlay on a CanvasLayer (layer 10). CombatUI uses a separate CanvasLayer (layer 1) that requires explicit visibility sync because CanvasLayer does not inherit parent visibility.

**Primary recommendation:** Build the new ForgeView as a single new Node2D scene that consolidates crafting and hero functionality, replace the bottom NavigationPanel with a top tab bar at y=0, and update MainView to manage three views (ForgeView, GameplayView, SettingsView) instead of four (CraftingView, HeroView, GameplayView, SettingsMenu-as-modal).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Viewport changes to **1280x720** (from 1200x700)
- Top tab bar: y=0, height 40px — tabs: "The Forge" | "Combat" | ... | "Settings" (right-aligned)
- 10px vertical padding between tab bar and content
- Content area starts at y=50, total content height 660px
- Dark panels (#333 range) on darker background (#1a1a1a range) — dark theme
- Single unified view called **"The Forge"** replaces both Hero View and Crafting View
- Full hero view compressed to left side, full crafting view compressed to right side
- If space is tight, **prioritize crafting** — it's the active workflow; hero panel is compact reference
- Exact panel positions and sizes defined in CONTEXT.md table
- Hammer sidebar: 2-column grid, 45x45px icons, 20px gaps
- Item type selection: 5 equal-width buttons (~80px each) below item image
- Item Stats panel has Melt and Equip buttons at bottom
- Melt destroys item, frees crafting slot; Equip equips to hero slot, old item destroyed
- Hero stats update instantly on equip, NOT during crafting
- Top tab bar with 3 tabs: "The Forge", "Combat", "Settings"
- Settings tab right-aligned on the bar
- Settings view is full-screen tab view (not a modal)

### Claude's Discretion
- Combat view layout adjustments (if any) for consistency with new viewport
- Exact dark theme color values
- Panel border/shadow styling
- Text sizing and spacing within panels
- Settings view content layout
- Tab bar visual styling (active/inactive states)
- Transition/animation between views (if any)

### Deferred Ideas (OUT OF SCOPE)
- Melt-for-currency recycling — Melt just destroys for now
- Dynamic item images — placeholder doesn't change per type
- 4-column hammer grid — stay with 2 columns
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| LAYOUT-01 | Hero equipment and crafting views display side by side (equipment left, crafting right) instead of separate tabs | ForgeView consolidates both into a single Node2D scene with panel layout per wireframe |
| LAYOUT-02 | Gameplay/combat view remains a separate full-width view toggled from the side-by-side view | MainView tab system switches between ForgeView and GameplayView; combat remains full-width |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Godot | 4.5 | Game engine | Project engine |
| GDScript | 4.5 | Scripting | Project language |

### Supporting
| Component | Purpose | When to Use |
|-----------|---------|-------------|
| Node2D | Scene root | All views use Node2D, not Control — maintain consistency |
| ColorRect | Panel backgrounds | Dark themed panels with solid colors |
| TextureRect | Image display | Item and hero portrait placeholders |
| Button | Interactive elements | Tabs, hammer buttons, item type buttons, Melt/Equip |
| Label | Text display | Stats, item info, inventory |
| CanvasLayer | Overlay layers | CombatUI (layer 1), SaveToast/overlay (layer 10) |

## Architecture Patterns

### Current Architecture (What Exists)
```
scenes/main.tscn (MainView - Node2D)
├── NavigationPanel (ColorRect, y=600-700, bottom bar)
│   ├── CraftingButton, HeroButton, GameplayButton, SettingsButton
│   └── HelpLabel
├── CraftingView (Node2D, node_2d.tscn)
│   ├── ButtonControl (hammer buttons, vertical list)
│   ├── ItemView (TextureRect, sword.jpg)
│   ├── Label (item stats text)
│   ├── InventoryPanel (crafting inventory)
│   └── ItemTypeButtons (weapon/helmet/armor/boots/ring)
├── HeroView (Node2D, hero_view.tscn)
│   ├── Background, HeroImage, equipment slots (5 Buttons)
│   ├── StatsPanel (hero offense/defense stats)
│   ├── CraftedItemStatsPanel (finished item stats)
│   └── ItemStatsPanel (hovered slot item stats)
├── GameplayView (Node2D, gameplay_view.tscn)
│   ├── Background, AreaLabel, combat buttons
│   ├── CombatEngine (Node)
│   └── CombatUI (CanvasLayer layer 1, health/progress bars)
└── OverlayLayer (CanvasLayer layer 10)
    ├── SaveToast
    └── SettingsMenu (PanelContainer modal)
```

### Target Architecture (What We Build)
```
scenes/main.tscn (MainView - Node2D)
├── TabBar (ColorRect, y=0, height=40px)
│   ├── ForgeTab, CombatTab (left-aligned)
│   └── SettingsTab (right-aligned)
├── ForgeView (Node2D, NEW forge_view.tscn)
│   ├── HammerSidebar (Panel, x=40, 260x660)
│   │   └── 2-col grid of TextureRect hammer icons
│   ├── ItemGraphics (TextureRect, x=340, 430x160)
│   ├── ItemTypeButtons (5 buttons, x=340, 430x40)
│   ├── HeroGraphics (hero portrait, x=810, 430x200)
│   ├── ItemStatsPanel (Panel, x=340, 430x430)
│   │   ├── ItemStatsLabel
│   │   ├── MeltButton, EquipButton
│   │   └── CraftingInventoryLabel
│   └── HeroStatsPanel (Panel, x=810, 430x430)
│       └── HeroStatsLabel (offense + defense)
├── GameplayView (Node2D, adjusted for 1280x720)
│   └── CombatUI (CanvasLayer layer 1)
├── SettingsView (Node2D, NEW settings_view.tscn, full-screen tab)
└── OverlayLayer (CanvasLayer layer 10)
    └── SaveToast
```

### Pattern 1: View Toggle via Visibility
**What:** MainView hides/shows views by setting `.visible`, syncing CanvasLayer visibility separately
**When to use:** Tab switching between ForgeView, GameplayView, SettingsView
**Current code:**
```gdscript
func show_view(view_name: String) -> void:
    crafting_view.visible = false
    hero_view.visible = false
    gameplay_view.visible = false
    match view_name:
        "crafting": crafting_view.visible = true
        "hero": hero_view.visible = true
        "gameplay": gameplay_view.visible = true
    combat_ui.visible = (view_name == "gameplay")
```
**New pattern:** Same approach, but with forge_view, gameplay_view, settings_view. CombatUI CanvasLayer sync remains.

### Pattern 2: Cross-View Signal Communication
**What:** CraftingView signals to HeroView for item equipping via parent-coordinated connections
**Current code:**
```gdscript
# main_view.gd _ready()
crafting_view.item_finished.connect(hero_view.set_last_crafted_item)
hero_view.equipment_changed.connect(gameplay_view.refresh_clearing_speed)
gameplay_view.item_base_found.connect(crafting_view.set_new_item_base)
gameplay_view.currencies_found.connect(crafting_view.on_currencies_found)
```
**New pattern:** ForgeView handles crafting+hero internally. Only forge_view <-> gameplay_view signals need parent coordination. The `item_finished -> set_last_crafted_item -> equip` chain becomes internal to ForgeView.

### Pattern 3: Absolute Pixel Positioning
**What:** All UI elements use absolute offsets, not Godot Container layout nodes
**Why:** Project convention — all existing scenes use `offset_left/top/right/bottom`, not anchors_preset with containers
**Impact:** Panel positions from CONTEXT.md map directly to offset properties in .tscn

### Anti-Patterns to Avoid
- **Mixing Control containers with absolute positioning:** Don't introduce VBoxContainer/HBoxContainer for panels — use offset-based positioning consistent with existing scenes
- **Keeping CraftingView and HeroView as separate scenes:** The ForgeView must be ONE scene, not two embedded sub-scenes — merging logic avoids unnecessary signal indirection
- **Forgetting CanvasLayer visibility sync:** When switching away from Combat, CombatUI CanvasLayer must be explicitly hidden (learned in v1.2 Phase 17)
- **Settings as modal overlay:** CONTEXT.md specifies Settings is a full-screen tab view, not the current PanelContainer modal

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tab bar | Custom container logic | Simple Button nodes with toggle_mode in a ColorRect | Matches existing pattern, no layout engine needed |
| Panel backgrounds | StyleBoxFlat for panels | ColorRect nodes | All existing panels use ColorRect, proven pattern |
| Hammer icon grid | GridContainer | Manual positioning with 2-column math | Consistent with project's absolute positioning; only 6 icons, grid math is trivial |

## Common Pitfalls

### Pitfall 1: Signal Wiring After Scene Merge
**What goes wrong:** Merging CraftingView and HeroView into ForgeView breaks the cross-view signal connections in main_view.gd
**Why it happens:** `crafting_view.item_finished.connect(hero_view.set_last_crafted_item)` references separate nodes that no longer exist
**How to avoid:** ForgeView handles equipping internally. Only expose signals that MainView needs: `equipment_changed` (for gameplay_view) and accept `item_base_found`/`currencies_found` from gameplay_view
**Warning signs:** Errors about null node references, signals not connecting

### Pitfall 2: CanvasLayer Visibility Desync
**What goes wrong:** CombatUI CanvasLayer stays visible when switching to Forge or Settings because CanvasLayer doesn't inherit Node2D parent visibility
**Why it happens:** Godot CanvasLayer has its own visibility independent of parent
**How to avoid:** Explicit `combat_ui.visible = (view_name == "combat")` in show_view(), same as current pattern
**Warning signs:** Combat health bars visible over Forge view

### Pitfall 3: Viewport Size Change Breaking Existing Layouts
**What goes wrong:** Changing from 1200x700 to 1280x720 shifts elements that use anchor_right=1.0 or center-anchored positioning
**Why it happens:** Anchored elements recalculate positions based on new viewport dimensions
**How to avoid:** Audit all scenes for anchor-based positioning. GameplayView background uses `offset_right = 1200.0` — needs update to 1280. NavigationPanel uses `offset_right = 1200.0` — being replaced anyway.
**Warning signs:** UI elements cut off at right edge, misaligned center elements

### Pitfall 4: Losing Save/Load Compatibility
**What goes wrong:** Renaming or restructuring crafting_view.gd / hero_view.gd breaks SaveManager's load_game() if it references these scenes
**Why it happens:** SaveManager serializes GameState, not scene nodes directly — but scene _ready() reads GameState
**How to avoid:** Verify SaveManager (Phase 18) only touches GameState/SaveManager autoloads. ForgeView's _ready() should read GameState.crafting_inventory, crafting_bench_type, hero.equipped_items the same way the old scenes did
**Warning signs:** Save loads but UI shows wrong state

### Pitfall 5: Keyboard Shortcuts Conflict
**What goes wrong:** Current KEY_1/KEY_2/KEY_3 shortcuts map to Crafting/Hero/Gameplay — new layout has only 3 tabs (Forge/Combat/Settings)
**Why it happens:** Forgetting to update _input() key mappings
**How to avoid:** Update shortcuts: KEY_1=Forge, KEY_2=Combat, KEY_3=Settings. TAB cycles through 3 views instead of 3.
**Warning signs:** Pressing "2" shows nothing or wrong view

## Code Examples

### Panel Background with Dark Theme
```gdscript
# In .tscn file, a dark panel:
[node name="ItemStatsPanel" type="ColorRect" parent="."]
offset_left = 340.0
offset_top = 280.0
offset_right = 770.0   # 340 + 430
offset_bottom = 710.0   # 280 + 430
color = Color(0.2, 0.2, 0.2, 1.0)  # #333 range
```

### Hammer Icon Grid (2-column, 45x45px, 20px gaps)
```gdscript
# 6 hammers in 2 columns, 3 rows
# Column positions: x=20, x=85 (20+45+20)
# Row positions: y=20, y=85, y=150 (each 45+20 apart)
var hammer_types = ["runic", "forge", "tack", "grand", "claw", "tuning"]
for i in range(hammer_types.size()):
    var col = i % 2
    var row = i / 2
    var icon = TextureRect.new()
    icon.position = Vector2(20 + col * 65, 20 + row * 65)
    icon.size = Vector2(45, 45)
    icon.texture = load("res://assets/" + hammer_types[i] + "_hammer.png")
```

### Tab Bar Button Styling
```gdscript
# Active tab: brighter, disabled (can't click current tab)
# Inactive tab: dimmer, clickable
func update_tab_states(active: String) -> void:
    forge_tab.disabled = (active == "forge")
    combat_tab.disabled = (active == "combat")
    settings_tab.disabled = (active == "settings")
```

### Melt/Equip Button Logic
```gdscript
func _on_melt_pressed() -> void:
    if finished_item == null:
        return
    # Destroy the item, free the crafting slot
    finished_item = null
    update_item_stats_display()

func _on_equip_pressed() -> void:
    if finished_item == null:
        return
    var slot_name = get_item_type(finished_item)
    # Old item in slot is destroyed (no swap-back)
    GameState.hero.equip_item(finished_item, slot_name)
    GameEvents.equipment_changed.emit(slot_name, finished_item)
    finished_item = null
    update_hero_stats_display()
    update_item_stats_display()
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Separate Crafting + Hero views | Unified Forge view | Phase 19 | Eliminates tab-switching for core crafting loop |
| Bottom navigation bar | Top tab bar | Phase 19 | More standard UI pattern, frees bottom space |
| Settings as modal overlay | Settings as full-screen tab | Phase 19 | Consistent with other views |
| 1200x700 viewport | 1280x720 viewport | Phase 19 | Standard 16:9 ratio, more horizontal space for side-by-side |

## Open Questions

1. **Item type button hover behavior for Hero Stats**
   - What we know: CONTEXT.md says "Selecting/hovering a type swaps Hero Stats panel to show the currently equipped item of that type for comparison"
   - What's unclear: Does this mean mouse_entered on the button triggers the swap, or only after clicking/selecting a type?
   - Recommendation: Implement both — hovering shows equipped item stats temporarily, clicking selects the crafting type AND shows equipped item stats persistently

2. **GameplayView adjustments for 1280x720**
   - What we know: Combat view "remains full-width" and viewport grows by 80px width, 20px height
   - What's unclear: Whether combat UI elements need repositioning or just the background extends
   - Recommendation: Extend background to 1280x720, adjust any hardcoded 1200-width elements; combat bars are anchored centrally so should adapt. Minimal changes.

## Sources

### Primary (HIGH confidence)
- Codebase analysis: all scene files (.tscn), scripts (.gd), project.godot — full read
- CONTEXT.md: User decisions with exact panel positions and sizes
- Wireframe: `Wireframe/Hero view.png` — visual reference for layout

### Secondary (MEDIUM confidence)
- Godot 4.5 CanvasLayer visibility behavior — confirmed from existing project code (Phase 17 explicit sync pattern)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — using existing Godot 4.5 patterns, no new libraries
- Architecture: HIGH — direct codebase analysis of all affected files
- Pitfalls: HIGH — based on actual bugs encountered in prior phases (CanvasLayer sync from v1.2)

**Research date:** 2026-02-17
**Valid until:** 2026-03-17 (stable — internal restructuring, no external dependencies)
