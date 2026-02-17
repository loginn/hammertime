# Phase 17: UI and Combat Feedback - Research

**Researched:** 2026-02-17
**Domain:** Godot 4.6 UI System (ProgressBar, Label, Tween, Signals)
**Confidence:** HIGH

## Summary

Phase 17 displays pack-based combat state through visual feedback, making the existing CombatEngine observable. The existing architecture already emits all necessary signals through GameEvents (combat_started, pack_attacked, hero_attacked, pack_killed, hero_died, map_completed). The UI layer needs to subscribe to these signals and render feedback using Godot 4's built-in UI nodes.

Godot 4.6 provides native solutions for all required UI elements: ProgressBar for HP/ES/pack progress, Label with Tween for floating damage numbers, and StyleBoxFlat for visual styling. The signal-based architecture ("call down, signal up") is already in place. The implementation follows standard patterns with minimal performance risk for this phase's scope (single hero + single pack at a time, not hundreds of entities).

**Primary recommendation:** Use ProgressBar nodes for all bar displays (HP, ES, pack progress), Tween-animated Labels for floating numbers, and subscribe to GameEvents signals for reactive updates. Implement ES overlay using two stacked ProgressBar nodes at the same position (PoE blue-over-red pattern).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**HP Display:**
- Health bar + numbers for both hero and pack (current/max overlaid on bar)
- Energy shield shown as stacked overlay on top of HP bar (blue over red, Path of Exile style)
- Pack HP uses the same bar+numbers style as hero HP — consistent treatment

**Pack Progress:**
- Progress bar that fills as packs are cleared
- Pack count overlaid on the bar itself ("3/7" format)
- Area level and biome name always visible during map runs
- Bar updates with instant jump when a pack is killed (snappy, not animated)

**Combat Feedback:**
- Floating damage numbers pop up and fade near the target (ARPG style)
- Crits get distinct treatment: bigger numbers in a different color
- Evasion shows "DODGE" floating text when hero evades an attack
- Damage numbers are uniform color regardless of element type (no elemental color-coding)

**State Transitions:**
- Death: inline state change in the combat area, not a full overlay
- Map complete: auto-advance seamlessly to next map with minimal fanfare
- Pack-to-pack: brief visual pause (~half second) so player notices pack change
- After death: auto-retry after a short delay (2-3 seconds), no button needed

### Claude's Discretion

- HP bar positioning/layout within the gameplay view
- Exact colors and sizing for HP bars, floating numbers, and crit styling
- Floating number animation (direction, fade speed, drift)
- Death state visual treatment (what "inline state change" looks like specifically)
- ES recharge visual feedback during pack transitions

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope

</user_constraints>

## Standard Stack

### Core

| Library/Node | Version | Purpose | Why Standard |
|--------------|---------|---------|--------------|
| ProgressBar | Godot 4.6 | HP/ES/pack progress bars | Built-in Control node with value/max_value properties, direct integration with themes |
| TextureProgressBar | Godot 4.6 | Optional enhanced visuals | Supports textures for more polished appearance, backward compatible with ProgressBar |
| Label | Godot 4.6 | Floating damage numbers and text overlays | Lightweight text display with LabelSettings for styling |
| Tween | Godot 4.6 | Floating number animations | Fire-and-forget animation system, auto-cleanup, chainable |
| StyleBoxFlat | Godot 4.6 | Bar coloring and styling | Theme override resource for customizing Control node appearance |
| CanvasLayer | Godot 4.6 | UI layer management | Separates UI from game world rendering, ensures UI renders on top |

**Current Project Setup:**
- Godot 4.6 project (`config/features=PackedStringArray("4.6", "Mobile")`)
- GameEvents autoload already emitting combat signals
- CombatEngine dual-timer architecture with state machine
- Existing gameplay_view.gd subscribes to signals (lines 22-32)

### Supporting

| Library/Node | Version | Purpose | When to Use |
|--------------|---------|---------|-------------|
| VBoxContainer/HBoxContainer | Godot 4.6 | Layout management | Automatic positioning of stacked/side-by-side UI elements |
| Control | Godot 4.6 | Spacers and positioning anchors | When manual positioning or flexible spacers needed |
| Timer | Godot 4.6 | Pack transition pause, death delay | Brief delays before state changes (already used in CombatEngine) |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| ProgressBar | Custom drawn bars (draw_rect) | ProgressBar is simpler and theme-aware; custom drawing only if pixel-perfect control needed |
| Tween | AnimationPlayer | Tween is fire-and-forget and better for dynamic runtime animations; AnimationPlayer better for complex pre-authored animations |
| Two stacked ProgressBars for ES | Single bar with shader | Two bars is simpler to implement and debug; shader only if performance bottleneck appears (unlikely) |

**Installation:**
No installation needed — all are built-in Godot 4.6 nodes.

## Architecture Patterns

### Recommended UI Structure

```
GameplayView (Node2D)
├── CombatEngine (Node)
├── CanvasLayer (UI layer - renders on top)
│   ├── CombatUI (Control - container for all combat UI)
│   │   ├── HeroHealthContainer (VBoxContainer/Control)
│   │   │   ├── HeroHPBar (ProgressBar) - red, life
│   │   │   ├── HeroESBar (ProgressBar) - blue, positioned over HP bar
│   │   │   └── HeroHPLabel (Label) - "150/200" text overlay
│   │   ├── PackHealthContainer (VBoxContainer/Control)
│   │   │   ├── PackHPBar (ProgressBar)
│   │   │   └── PackHPLabel (Label)
│   │   ├── PackProgressContainer (VBoxContainer/Control)
│   │   │   ├── PackProgressBar (ProgressBar)
│   │   │   └── PackProgressLabel (Label) - "3/7"
│   │   └── AreaInfoLabel (Label) - "Forest (Level 5)"
│   └── FloatingTextContainer (Control - parent for damage numbers)
│       └── [Dynamic FloatingLabel instances]
```

### Pattern 1: Signal-Driven UI Updates ("Call Down, Signal Up")

**What:** UI nodes subscribe to GameEvents signals and update display properties directly without storing game state references.

**When to use:** All reactive UI updates where combat state changes

**Example:**
```gdscript
# In combat_ui.gd
func _ready() -> void:
    GameEvents.hero_attacked.connect(_on_hero_attacked)
    GameEvents.pack_attacked.connect(_on_pack_attacked)
    GameEvents.pack_killed.connect(_on_pack_killed)

func _on_hero_attacked(damage: float, is_crit: bool) -> void:
    # Update hero HP bar from GameState.hero (single source of truth)
    hero_hp_bar.value = GameState.hero.health
    hero_hp_bar.max_value = GameState.hero.max_health

    # Spawn floating damage number at pack position
    _spawn_floating_text(pack_position, str(int(damage)), is_crit)

func _on_pack_attacked(result: Dictionary) -> void:
    if result["dodged"]:
        _spawn_floating_text(hero_position, "DODGE", false, Color.WHITE)
    else:
        var total_damage = result["life_damage"] + result["es_damage"]
        _spawn_floating_text(hero_position, str(int(total_damage)), false)

    # Update hero bars
    hero_hp_bar.value = GameState.hero.health
    hero_es_bar.value = GameState.hero.current_energy_shield
```
**Source:** [Godot signal best practices](https://www.gdquest.com/tutorial/godot/best-practices/signals/)

### Pattern 2: Stacked ProgressBar for ES Overlay

**What:** Two ProgressBar nodes at identical positions/sizes, ES bar renders on top with transparency

**When to use:** Path of Exile style blue-over-red shield/life display

**Example:**
```gdscript
# In scene setup or _ready()
hero_hp_bar.position = Vector2(50, 50)
hero_hp_bar.size = Vector2(200, 30)
hero_hp_bar.max_value = GameState.hero.max_health
hero_hp_bar.value = GameState.hero.health

# ES bar positioned identically
hero_es_bar.position = Vector2(50, 50)
hero_es_bar.size = Vector2(200, 30)
hero_es_bar.max_value = GameState.hero.total_energy_shield
hero_es_bar.value = GameState.hero.current_energy_shield

# Styling via theme overrides (inspector or code)
var hp_style = StyleBoxFlat.new()
hp_style.bg_color = Color(0.8, 0.0, 0.0)  # Red
hero_hp_bar.add_theme_stylebox_override("fill", hp_style)

var es_style = StyleBoxFlat.new()
es_style.bg_color = Color(0.0, 0.5, 1.0)  # Blue
hero_es_bar.add_theme_stylebox_override("fill", es_style)
```
**Source:** [ProgressBar in Godot guide](https://gamedevacademy.org/progressbar-in-godot-complete-guide/)

### Pattern 3: Tween-Animated Floating Labels

**What:** Spawn Label nodes, animate position and alpha using Tween, auto-cleanup on finish

**When to use:** Floating damage numbers, dodge text, any ephemeral feedback

**Example:**
```gdscript
# FloatingLabel.gd (attached to a Label scene)
extends Label

func show_value(value_text: String, is_crit: bool = false) -> void:
    text = value_text

    # Crit styling
    if is_crit:
        modulate = Color(1.0, 0.8, 0.0)  # Gold
        scale = Vector2(1.5, 1.5)
    else:
        modulate = Color(1.0, 1.0, 1.0)  # White
        scale = Vector2(1.0, 1.0)

    # Animate upward drift and fade
    var tween = create_tween()
    tween.set_parallel(true)  # Position and alpha animate simultaneously
    tween.tween_property(self, "position:y", position.y - 50, 1.0)
    tween.tween_property(self, "modulate:a", 0.0, 1.0)

    # Cleanup after animation
    await tween.finished
    queue_free()

# In CombatUI manager
func _spawn_floating_text(spawn_pos: Vector2, text: String, is_crit: bool) -> void:
    var label = FLOATING_LABEL_SCENE.instantiate()
    label.position = spawn_pos
    floating_text_container.add_child(label)
    label.show_value(text, is_crit)
```
**Source:** [Floating combat text Godot 4 recipe](https://kidscancode.org/godot_recipes/4.x/ui/floating_text/index.html), [Godot Tween guide](https://www.gotut.net/tweens-in-godot-4/)

### Pattern 4: Instant vs Animated Bar Updates

**What:** ProgressBar.value = X updates instantly (no tween), suitable for snappy feedback

**When to use:** Pack progress bar jumps, death state changes — user wants immediate visual confirmation

**Example:**
```gdscript
func _on_pack_killed(pack_index: int, total_packs: int) -> void:
    # Instant update (no tween)
    pack_progress_bar.value = pack_index
    pack_progress_bar.max_value = total_packs
    pack_progress_label.text = "%d/%d" % [pack_index, total_packs]

    # Brief visual pause before next pack (per user constraint)
    await get_tree().create_timer(0.5).timeout
    # Next pack fight starts automatically in CombatEngine
```

### Anti-Patterns to Avoid

- **Storing duplicate game state in UI nodes:** UI should read from GameState.hero, not cache HP values. Single source of truth prevents desyncs.
- **Connecting signals in editor for dynamic content:** Editor connections work for static nodes but not runtime-spawned labels. Use code-based connect() for dynamic UI.
- **Forgetting queue_free() on tweened labels:** Memory leak. Always await tween.finished and call queue_free().
- **Updating bars every frame in _process():** Wasteful. Update reactively on signals only.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Progress bars | Custom draw_rect() with manual percentage math | ProgressBar node | Built-in value/max_value handling, theme integration, accessibility |
| Smooth animations | Manual interpolation in _process() with delta time | Tween.tween_property() | Automatic easing, parallel/sequential chaining, auto-cleanup |
| UI layering | Z-index juggling in Node2D | CanvasLayer | Guaranteed render order, independent transform |
| Text fade-out | Manual modulate.a -= delta in _process() | Tween.tween_property(self, "modulate:a", ...) | Cleaner, no leftover timers, parallel animations |

**Key insight:** Godot's Control nodes and Tween system handle 90% of UI patterns out-of-the-box. Custom drawing is only needed for specialized effects (shaders, procedural shapes). For bars, labels, and basic animations, built-in nodes are simpler, more maintainable, and better integrated with themes.

## Common Pitfalls

### Pitfall 1: ES Bar Max Value Mismatch

**What goes wrong:** ES bar doesn't shrink properly when ES depletes because max_value is set to hero max HP instead of hero max ES.

**Why it happens:** Copy-paste error when setting up two stacked bars, forgetting ES has its own max value.

**How to avoid:**
- hero_hp_bar.max_value = GameState.hero.max_health
- hero_es_bar.max_value = GameState.hero.total_energy_shield (not max_health)

**Warning signs:** ES bar appears full even when hero has 0 ES, or bar doesn't visually deplete.

### Pitfall 2: Floating Labels Parent to Wrong Node

**What goes wrong:** Floating damage numbers disappear mid-animation or render behind other UI elements.

**Why it happens:** Parenting labels to combat entities (packs) that get freed, or parenting to a low z-index container.

**How to avoid:** Always parent floating labels to a dedicated Control node under CanvasLayer, not to game entities. Use CanvasLayer to ensure UI renders on top.

**Warning signs:** Labels vanish before tween finishes, labels hidden behind bars/buttons.

**Source:** [Floating combat text recipe](https://kidscancode.org/godot_recipes/4.x/ui/floating_text/index.html) notes "add it to the root of the scene tree... if you parent it to the object taking damage and that object is deleted, the FloatingLabel will also be deleted"

### Pitfall 3: Tween Not Cleaned Up After queue_free()

**What goes wrong:** Tweens continue running on freed nodes, causing errors or memory leaks.

**Why it happens:** Calling queue_free() without awaiting tween.finished, or forgetting to kill tween if node is freed externally.

**How to avoid:** Always structure as:
```gdscript
await tween.finished
queue_free()
```
Or use tween.kill() if freeing node before tween completes.

**Warning signs:** Console errors about accessing freed objects, memory usage creeping up over time.

**Source:** [Tweens and queue_free forum discussion](https://forum.godotengine.org/t/tweens-and-queue-free/49267), [Tween autokill issue](https://github.com/godotengine/godot/issues/63874)

### Pitfall 4: Signal Connection Memory Leaks

**What goes wrong:** Connecting signals without disconnecting causes handlers to fire after node is freed, or multiple connections stack up.

**Why it happens:** Connecting in _ready() but not disconnecting in cleanup, or reconnecting every time scene is re-entered.

**How to avoid:**
- Godot auto-disconnects when signal owner or target is freed (usually safe)
- If manually managing: disconnect in cleanup or use `connect(..., CONNECT_ONE_SHOT)` for one-time signals
- Avoid connecting same signal multiple times

**Warning signs:** UI updates triggering multiple times per event, errors after scene transitions.

### Pitfall 5: Modifying StyleBoxFlat Without Unique Resource

**What goes wrong:** Changing bar colors in code affects all bars using the same theme resource.

**Why it happens:** StyleBoxFlat assigned via theme is shared; modifying it mutates the shared instance.

**How to avoid:** Always create new StyleBoxFlat instances per bar or call .duplicate() on theme resources before modifying.

**Example:**
```gdscript
# WRONG - mutates shared theme
hero_hp_bar.get_theme_stylebox("fill").bg_color = Color.RED

# CORRECT - unique instance
var hp_style = StyleBoxFlat.new()
hp_style.bg_color = Color.RED
hero_hp_bar.add_theme_stylebox_override("fill", hp_style)
```

**Source:** [StyleBoxFlat color forum discussion](https://forum.godotengine.org/t/how-to-change-the-color-of-styleboxflat/46004)

## Code Examples

Verified patterns from official sources and community best practices:

### Subscribing to Combat Signals

```gdscript
# combat_ui.gd
extends Control

@onready var hero_hp_bar: ProgressBar = $HeroHPBar
@onready var hero_es_bar: ProgressBar = $HeroESBar
@onready var pack_hp_bar: ProgressBar = $PackHPBar
@onready var pack_progress_bar: ProgressBar = $PackProgressBar

func _ready() -> void:
    # Subscribe to combat events
    GameEvents.combat_started.connect(_on_combat_started)
    GameEvents.hero_attacked.connect(_on_hero_attacked)
    GameEvents.pack_attacked.connect(_on_pack_attacked)
    GameEvents.pack_killed.connect(_on_pack_killed)
    GameEvents.hero_died.connect(_on_hero_died)
    GameEvents.map_completed.connect(_on_map_completed)

func _on_combat_started(area_level: int, pack_count: int) -> void:
    pack_progress_bar.max_value = pack_count
    pack_progress_bar.value = 0
    _update_all_bars()

func _update_all_bars() -> void:
    var hero = GameState.hero
    hero_hp_bar.value = hero.health
    hero_hp_bar.max_value = hero.max_health
    hero_es_bar.value = hero.current_energy_shield
    hero_es_bar.max_value = hero.total_energy_shield

    var pack = get_current_pack()
    if pack:
        pack_hp_bar.value = pack.hp
        pack_hp_bar.max_value = pack.max_hp
```

### Creating Tween Animations for Floating Text

```gdscript
# floating_label.gd
extends Label

func show_damage(damage: int, is_crit: bool) -> void:
    if is_crit:
        text = str(damage)
        add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))  # Gold
        scale = Vector2(1.5, 1.5)
    else:
        text = str(damage)
        add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))  # White

    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(self, "position:y", position.y - 60, 1.0)
    tween.tween_property(self, "modulate:a", 0.0, 1.0)

    await tween.finished
    queue_free()

func show_dodge() -> void:
    text = "DODGE"
    add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(self, "position:y", position.y - 40, 0.8)
    tween.tween_property(self, "modulate:a", 0.0, 0.8)

    await tween.finished
    queue_free()
```
**Source:** [Godot 4 Tween tutorial](https://www.gotut.net/tweens-in-godot-4/)

### Spawning Floating Text Dynamically

```gdscript
# combat_ui.gd
const FLOATING_LABEL_SCENE = preload("res://scenes/floating_label.tscn")

@onready var floating_text_container: Control = $FloatingTextContainer

func _on_hero_attacked(damage: float, is_crit: bool) -> void:
    _spawn_damage_number(pack_position, int(damage), is_crit)

func _on_pack_attacked(result: Dictionary) -> void:
    if result["dodged"]:
        _spawn_dodge_text(hero_position)
    else:
        var total = int(result["life_damage"] + result["es_damage"])
        _spawn_damage_number(hero_position, total, false)

func _spawn_damage_number(pos: Vector2, damage: int, is_crit: bool) -> void:
    var label = FLOATING_LABEL_SCENE.instantiate()
    label.position = pos
    floating_text_container.add_child(label)
    label.show_damage(damage, is_crit)

func _spawn_dodge_text(pos: Vector2) -> void:
    var label = FLOATING_LABEL_SCENE.instantiate()
    label.position = pos
    floating_text_container.add_child(label)
    label.show_dodge()
```

### Setting Up StyleBoxFlat for Bar Colors

```gdscript
# In _ready() or scene setup
func _setup_bar_styles() -> void:
    # Hero HP bar - red
    var hp_fill = StyleBoxFlat.new()
    hp_fill.bg_color = Color(0.8, 0.0, 0.0)
    hero_hp_bar.add_theme_stylebox_override("fill", hp_fill)

    var hp_bg = StyleBoxFlat.new()
    hp_bg.bg_color = Color(0.2, 0.0, 0.0)
    hero_hp_bar.add_theme_stylebox_override("background", hp_bg)

    # Hero ES bar - blue
    var es_fill = StyleBoxFlat.new()
    es_fill.bg_color = Color(0.0, 0.5, 1.0)
    hero_es_bar.add_theme_stylebox_override("fill", es_fill)

    var es_bg = StyleBoxFlat.new()
    es_bg.bg_color = Color(0.0, 0.1, 0.3)
    hero_es_bar.add_theme_stylebox_override("background", es_bg)
```
**Source:** [ProgressBar guide](https://gamedevacademy.org/progressbar-in-godot-complete-guide/)

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Godot 3 Tween node | Godot 4 create_tween() method | Godot 4.0 | Tweens are now fire-and-forget, no node pollution, better chaining |
| String-based signal names | First-class Signal type | Godot 4.0 | Better autocomplete, compile-time checking, cleaner API |
| TextureProgress | TextureProgressBar | Godot 3.x → 4.x rename | API compatible, just renamed for clarity |
| Manual anchor calculations | Layout containers | Ongoing best practice | Responsive UI without manual math |

**Deprecated/outdated:**
- Godot 3 Tween node: Use create_tween() in Godot 4 instead
- connect(signal_name, target, method_name): Use connect(signal, callable) in Godot 4
- rect_position, rect_size properties: Use position, size in Godot 4 (compatibility aliases exist)

## Open Questions

1. **What exact pause duration feels right for pack-to-pack transitions?**
   - What we know: User wants ~0.5 second visual pause, CombatEngine currently has instant transition
   - What's unclear: Does 0.5s feel good, or too slow/fast in practice?
   - Recommendation: Implement 0.5s Timer-based delay, make it configurable for playtesting adjustment

2. **Should ES recharge be visually animated between packs?**
   - What we know: CombatEngine recharges 33% ES between packs (instant in code)
   - What's unclear: User left this to Claude's discretion
   - Recommendation: Start with instant bar update (no tween), add smooth tween if playtesting shows it's confusing

3. **Where exactly should floating damage numbers spawn?**
   - What we know: "near the target" (ARPG style), hero vs pack positions
   - What's unclear: Exact offset from health bar, random variance, vertical vs centered
   - Recommendation: Spawn above health bar center with small random X offset (±20 pixels) for visual variety

4. **Performance: Should we object pool floating labels?**
   - What we know: Godot 4 node instantiation is slower than Godot 3, pooling recommended for high-volume spawning
   - What's unclear: Is 2-4 damage numbers per second (hero+pack attacks) high enough volume to matter?
   - Recommendation: Start without pooling (simpler), profile in play. Only add pooling if FPS drops below 60.

## Sources

### Primary (HIGH confidence)

**Official Godot Documentation:**
- [ProgressBar class](https://docs.godotengine.org/en/stable/classes/class_progressbar.html) - Core properties and usage
- [TextureProgressBar class](https://docs.godotengine.org/en/stable/classes/class_textureprogressbar.html) - Enhanced visuals with textures
- [Tween class](https://docs.godotengine.org/en/stable/classes/class_tween.html) - Animation API
- [CanvasLayer class](https://docs.godotengine.org/en/stable/classes/class_canvaslayer.html) - UI layering
- [Using signals tutorial](https://docs.godotengine.org/en/4.4/getting_started/step_by_step/signals.html) - Signal best practices

**GDQuest (Godot authority):**
- [Best practices with Godot signals](https://www.gdquest.com/tutorial/godot/best-practices/signals/) - "Call down, signal up" pattern
- [Add The Health Bar tutorial](https://school.gdquest.com/courses/learn_2d_gamedev_godot_4/loot_it_all/add_the_health_bar) - Practical ProgressBar setup

**Godot Recipes (Chris Bradfield):**
- [Floating combat text Godot 4](https://kidscancode.org/godot_recipes/4.x/ui/floating_text/index.html) - Complete floating label implementation
- [Node communication](https://kidscancode.org/godot_recipes/4.x/basics/node_communication/index.html) - Signal architecture patterns

### Secondary (MEDIUM confidence)

**Community Tutorials:**
- [ProgressBar in Godot - Complete Guide](https://gamedevacademy.org/progressbar-in-godot-complete-guide/) - Setup and theme overrides
- [Tweens in Godot 4 - Tutorial](https://www.gotut.net/tweens-in-godot-4/) - Tween API with examples
- [Godot 4 Health System with Progress Bar](https://gamerdevops.com/godot-4-health-system-with-progress-bar-tutorial/) - Health bar patterns
- [UI Layout using Containers](https://gdscript.com/solutions/ui-layout-using-containers-in-godot/) - Container-based layouts
- [Elevate Your Godot Game: Implementing Floating Damage Numbers](https://www.wayline.io/blog/godot-floating-damage-numbers) - Floating text best practices

**Forums (verified patterns):**
- [How to change StyleBoxFlat color](https://forum.godotengine.org/t/how-to-change-the-color-of-styleboxflat/46004) - Theme override examples
- [Tweens and queue_free](https://forum.godotengine.org/t/tweens-and-queue-free/49267) - Cleanup patterns
- [Multiple texture support for TextureProgressBar](https://github.com/godotengine/godot-proposals/discussions/4536) - ES overlay approach

### Tertiary (LOW confidence)

**Performance discussions:**
- [Godot 4.x slower creating nodes](https://github.com/godotengine/godot/issues/71182) - Node instantiation performance (needs profiling to confirm impact)
- [Object pooling guide](https://uhiyama-lab.com/en/notes/godot/godot-object-pooling-basics/) - When to use pooling (phase may not need this)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All built-in Godot 4.6 nodes, official docs available
- Architecture: HIGH - Signal patterns verified by GDQuest/official docs, existing CombatEngine already implements signal emission
- Pitfalls: HIGH - Common issues documented in forums with solutions, tested patterns from Godot recipes
- Performance: MEDIUM - Object pooling may not be needed at current scale, requires profiling

**Research date:** 2026-02-17
**Valid until:** ~60 days (Godot 4.x is stable, UI API unlikely to change rapidly)
**Godot version:** 4.6 (project config verified)
