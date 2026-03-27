# Phase 53: Selection UI - Research

**Researched:** 2026-03-27
**Domain:** Godot 4 UI construction — CanvasLayer overlay, programmatic Control nodes, tween fade-out, signal wiring
**Confidence:** HIGH

## Summary

Phase 53 builds the 3-card hero selection overlay that appears after prestige when `hero_archetype` is null. All infrastructure required already exists in the codebase: `OverlayLayer` (CanvasLayer layer 10) is in `main.tscn`, `HeroArchetype.generate_choices()` returns the 3 hero objects, `GameEvents.hero_selection_needed` / `hero_selected` signals are declared in Phase 50, `GameState.hero_archetype` is the nullable field to set, and `SaveManager.save_game()` persists the choice. This phase is entirely a UI wiring and construction problem — no new data model work required.

The detection point is `main_view._ready()` after scene reload: check `prestige_level >= 1 AND hero_archetype == null`. P0 players are never shown the overlay. The overlay is a full-screen ColorRect (mouse_filter STOP) on OverlayLayer with 3 card panels built in code. After a card is clicked, set `GameState.hero_archetype`, emit `GameEvents.hero_selected`, call `SaveManager.save_game()`, then tween the overlay alpha to 0 and `queue_free()` it.

**Primary recommendation:** Build the selection overlay as a standalone Control node added dynamically to OverlayLayer from `main_view._ready()`. Use programmatic node construction (same pattern as `prestige_view._build_unlock_table()`). Do NOT add it to main.tscn — it is a transient UI that lives for one interaction.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Each card shows: archetype label + subvariant (e.g., "STR - Hit"), hero title (e.g., "The Berserker"), and human-readable passive bonus list.
- **D-02:** Bonuses displayed as percentage format: `+25% Attack Damage`, `+20% Bleed Chance`, etc. Converted from passive_bonuses dictionary values (0.25 -> "+25%").
- **D-03:** Card has a colored left border or outline using the hero's color from REGISTRY (red/green/blue). Title text stays white for readability.
- **D-04:** No flavor text or descriptions — title + bonuses is enough information.
- **D-05:** 3 cards arranged in a horizontal row, centered in viewport. ~380px per card with gaps between.
- **D-06:** "Choose Your Hero" header text above the card row.
- **D-07:** Single click on card selects that hero immediately — no two-click confirmation. This is a positive choice, not destructive.
- **D-08:** Detection happens in `main_view._ready()` after scene reload: if `GameState.prestige_level >= 1 AND GameState.hero_archetype == null`, show the overlay.
- **D-09:** P0 players (`prestige_level == 0`) never trigger the overlay regardless of archetype state.
- **D-10:** Flow: prestige wipe -> save -> fade to black -> reload_current_scene() -> main_view._ready() detects null archetype -> show overlay.
- **D-11:** Full-screen overlay on OverlayLayer (CanvasLayer layer 10) covers tab bar and all content. Mouse filter STOP blocks all clicks beneath.
- **D-12:** Overlay appears instantly on scene load (no fade-in). Since the scene just reloaded from prestige's black fade, instant appearance feels natural.
- **D-13:** After picking a hero, overlay fades out over ~0.3s revealing the forge view underneath.
- **D-14:** Auto-save triggered after hero selection so the choice persists immediately.
- **D-15:** Static `BONUS_LABELS` dictionary on HeroArchetype maps bonus keys to display strings (e.g., `"attack_damage_more": "Attack Damage"`).
- **D-16:** Format helper on HeroArchetype: takes passive_bonuses dict, returns array of formatted strings like `"+25% Attack Damage"`.

### Claude's Discretion

- Exact card dimensions and spacing within the ~380px per card budget
- Font sizes for title vs bonus text
- Overlay background color/opacity (semi-transparent dark is standard)
- Whether selection overlay is a separate scene (.tscn) or built in code
- Implementation of the hero_selection_needed / hero_selected signal wiring

### Deferred Ideas (OUT OF SCOPE)

- Hero bonus display in ForgeView stat panel — Phase 54
- Balance tuning of bonus magnitudes — Phase 54
- Prestige-level-gated hero pool (P1 basic, P3+ full roster) — Future requirement
- Hero selection animation (card flip, particle effects) — Future polish
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SEL-01 | 3-card draft on prestige — 1 STR, 1 DEX, 1 INT drawn randomly, pick one | `HeroArchetype.generate_choices()` returns `Array[HeroArchetype]` with exactly 3 heroes, one per archetype. Card UI built programmatically in OverlayLayer. |
| SEL-02 | P0 plays as classless Adventurer (no hero, no passive). First selection at P1 | Detection guard in `main_view._ready()`: `prestige_level >= 1` check before showing overlay. `GameState.hero_archetype == null` already represents classless. |
| SEL-03 | Selection overlay UI blocks gameplay post-prestige until hero is picked (1280x720) | CanvasLayer layer 10 with mouse_filter STOP on background ColorRect blocks all underlying input. Overlay fills 1280x720. |
</phase_requirements>

---

## Standard Stack

### Core
| Library / Node | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| CanvasLayer (OverlayLayer) | Godot 4.5 (existing) | Renders overlay above all game content | Already in main.tscn at layer 10; same node used for FadeRect and SaveToast |
| ColorRect | Godot 4.5 built-in | Background dim + card backgrounds | Lightweight; supports color, size, mouse_filter STOP |
| VBoxContainer / HBoxContainer | Godot 4.5 built-in | Card layout rows | Standard programmatic layout; same pattern as `_build_unlock_table()` in prestige_view.gd |
| Tween | Godot 4.5 built-in | 0.3s fade-out on selection | Existing pattern in `_on_prestige_triggered()` |
| Label | Godot 4.5 built-in | Text content in cards | Same nodes used throughout prestige_view.gd and other views |

### Supporting
| Library / Node | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| Button | Godot 4.5 built-in | Clickable card surface | Entire card can be a Button with custom style, OR a ColorRect with `gui_input` signal — Button preferred for built-in hover state |
| StyleBoxFlat | Godot 4.5 built-in | Left colored border on cards (D-03) | Set `border_width_left` and `border_color` on a StyleBoxFlat applied to a panel |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Programmatic construction | Separate .tscn scene | .tscn adds a file to track; programmatic is simpler for a transient overlay and follows existing project patterns |
| Button node for cards | Panel + `gui_input` | Button gives free hover styling and pressed signal; simpler |
| StyleBoxFlat border | Separate thin ColorRect strip | StyleBoxFlat is cleaner; less node overhead |

**Installation:** No new packages. All Godot built-in nodes.

---

## Architecture Patterns

### Recommended Project Structure

No new files are strictly required, but the overlay logic should live in a dedicated node added dynamically. Two viable approaches:

**Option A: Inline in main_view.gd (simpler)**
- `main_view._ready()` calls `_show_hero_selection()` which builds the overlay node tree in code and adds it to OverlayLayer
- All overlay logic lives in main_view.gd as private helper functions
- Pro: no new file; con: main_view.gd grows longer

**Option B: Separate scene file (cleaner)**
- `scenes/hero_selection_overlay.gd` + optional `scenes/hero_selection_overlay.tscn`
- `main_view._ready()` instantiates it and adds to OverlayLayer
- Pro: encapsulated; con: minor file overhead for a transient UI

**Recommendation (Claude's discretion):** Option A (inline) for minimalism — the overlay is ~50-80 lines and never reused elsewhere. If building in code rather than .tscn (also Claude's discretion), Option A avoids creating a .tscn with no script separation benefit.

### Pattern 1: Programmatic Node Construction (established pattern)

**What:** Build UI nodes in GDScript using `Node.new()`, set properties, `add_child()`.
**When to use:** Transient, data-driven UI. Existing project precedent in `prestige_view._build_unlock_table()`.

```gdscript
# Source: scenes/prestige_view.gd (existing project pattern)
func _build_unlock_table() -> void:
    for child in unlock_table.get_children():
        child.queue_free()
    for level in range(1, PrestigeManager.MAX_PRESTIGE_LEVEL + 1):
        var row := HBoxContainer.new()
        row.custom_minimum_size.y = 35
        var label := Label.new()
        label.text = "P" + str(level)
        row.add_child(label)
        unlock_table.add_child(row)
```

### Pattern 2: OverlayLayer with STOP Mouse Filter (established pattern)

**What:** Add a full-screen ColorRect to CanvasLayer with `mouse_filter = Control.MOUSE_FILTER_STOP` to block all input.
**When to use:** Modal overlay that must block interaction with underlying views.

```gdscript
# Source: scenes/main_view.gd (existing project pattern — prestige fade)
fade_rect.mouse_filter = 0  # STOP — block all input during fade
# mouse_filter values: 0 = STOP, 1 = PASS, 2 = IGNORE
```

For the selection overlay background:
```gdscript
var bg := ColorRect.new()
bg.color = Color(0, 0, 0, 0.75)  # semi-transparent dark
bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
bg.mouse_filter = Control.MOUSE_FILTER_STOP
overlay_layer.add_child(bg)
```

### Pattern 3: Tween Fade-Out then Queue Free

**What:** Create a tween on the overlay container, tween alpha to 0, then queue_free.
**When to use:** D-13 — 0.3s fade-out after card selection.

```gdscript
# Source: scenes/main_view.gd (existing project pattern — prestige fade uses same approach)
var tween = create_tween()
tween.tween_property(overlay_container, "modulate:a", 0.0, 0.3)
tween.tween_callback(overlay_container.queue_free)
```

Note: `modulate.a` on a container node fades all children. Alternative: tween `color:a` on a background ColorRect if the structure requires it.

### Pattern 4: BONUS_LABELS + format_bonuses() on HeroArchetype (new, required by D-15/D-16)

**What:** Static dict mapping bonus keys to display names; static method returns formatted strings.
**When to use:** Card content generation (D-02).

```gdscript
# To add to models/hero_archetype.gd (D-15/D-16)
const BONUS_LABELS: Dictionary = {
    "attack_damage_more": "Attack Damage",
    "physical_damage_more": "Physical Damage",
    "damage_more": "Damage",
    "bleed_chance_more": "Bleed Chance",
    "bleed_damage_more": "Bleed Damage",
    "poison_chance_more": "Poison Chance",
    "poison_damage_more": "Poison Damage",
    "burn_chance_more": "Burn Chance",
    "burn_damage_more": "Burn Damage",
    "fire_damage_more": "Fire Damage",
    "cold_damage_more": "Cold Damage",
    "lightning_damage_more": "Lightning Damage",
    "spell_damage_more": "Spell Damage",
}

static func format_bonuses(bonuses: Dictionary) -> Array[String]:
    var result: Array[String] = []
    for key in bonuses:
        var pct: int = roundi(bonuses[key] * 100)
        var label: String = BONUS_LABELS.get(key, key)
        result.append("+%d%% %s" % [pct, label])
    return result
```

### Pattern 5: Archetype Label from Enum (card header — D-01)

**What:** Convert enum value to display string for archetype label + subvariant.
**Example output:** "STR - Hit", "DEX - DoT", "INT - Elemental"

```gdscript
# Archetype enum name strings
const ARCHETYPE_NAMES: Dictionary = {
    HeroArchetype.Archetype.STR: "STR",
    HeroArchetype.Archetype.DEX: "DEX",
    HeroArchetype.Archetype.INT: "INT",
}
const SUBVARIANT_NAMES: Dictionary = {
    HeroArchetype.Subvariant.HIT: "Hit",
    HeroArchetype.Subvariant.DOT: "DoT",
    HeroArchetype.Subvariant.ELEMENTAL: "Elemental",
}
# Used in card building: "STR - Hit"
var header: String = ARCHETYPE_NAMES[hero.archetype] + " - " + SUBVARIANT_NAMES[hero.subvariant]
```

These label dicts can live in the overlay construction code rather than on HeroArchetype (they are UI-only concerns).

### Pattern 6: StyleBoxFlat for Colored Left Border (D-03)

**What:** Apply a StyleBoxFlat with only left border colored to each card panel.
**When to use:** Visual archetype color identity without colored text (title stays white per D-03).

```gdscript
var card_style := StyleBoxFlat.new()
card_style.bg_color = Color(0.15, 0.15, 0.15, 1.0)    # dark card bg
card_style.border_width_left = 4
card_style.border_color = hero.color                    # from REGISTRY
# Apply to a PanelContainer or Button add_theme_stylebox_override("panel", card_style)
```

Alternatively a thin left-strip ColorRect:
```gdscript
var border_strip := ColorRect.new()
border_strip.color = hero.color
border_strip.custom_minimum_size = Vector2(4, 0)
```

Both work; StyleBoxFlat on a PanelContainer is cleaner.

### Anti-Patterns to Avoid

- **Adding the overlay to main.tscn as a permanent node:** It's transient — only needed post-prestige. Adding to the scene tree permanently means managing visibility state; dynamic instantiation and `queue_free()` is cleaner.
- **Using `set_process(false)` on underlying views to "block" gameplay:** Use `mouse_filter = STOP` on the overlay background. Process blocking is not necessary — combat doesn't run without player input anyway in this idle game.
- **Connecting `hero_selected` signal before the overlay is created:** Wire signals only after the overlay node is added to the tree.
- **Calling `SaveManager.save_game()` before setting `GameState.hero_archetype`:** Set archetype first, then save; otherwise null gets persisted.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Percentage formatting | Custom string format function | `"+%d%% %s" % [roundi(val * 100), label]` (one-liner) | GDScript string formatting handles this natively |
| Input blocking | Custom input interception | `mouse_filter = Control.MOUSE_FILTER_STOP` on overlay ColorRect | Godot's built-in input propagation handles this correctly through the UI tree |
| Overlay fade | Manual alpha step in `_process()` | `create_tween().tween_property(node, "modulate:a", 0.0, 0.3)` | Existing tween pattern already in codebase |
| Random hero selection | Custom randomization | `HeroArchetype.generate_choices()` — already implemented | Already exists in Phase 50; calls `Array.pick_random()` per archetype pool |

**Key insight:** Every mechanism this phase needs already exists in the codebase. The implementation is pure UI wiring.

---

## Common Pitfalls

### Pitfall 1: FadeRect Still Visible After Prestige Reload

**What goes wrong:** After `reload_current_scene()`, FadeRect from the prestige fade is still opaque black (`color.a = 1.0`, `visible = true`). The new scene instance has a fresh FadeRect (default: `visible = false`, `color = Color(0,0,0,0)`) so this is NOT a problem — `reload_current_scene()` creates a fresh scene tree.

**Confirmed safe:** The existing `main.tscn` sets FadeRect `visible = false` and `color = Color(0,0,0,0)` at scene definition. After reload the FadeRect starts hidden. The hero selection overlay appears on top of the already-revealed scene.

**Warning sign:** If the overlay appears behind the FadeRect, check that the FadeRect is not being made visible during `_ready()`.

### Pitfall 2: mouse_filter on CanvasLayer Children

**What goes wrong:** `mouse_filter = STOP` must be set on the ColorRect node directly, not on the CanvasLayer parent (CanvasLayer doesn't inherit mouse_filter). The CanvasLayer itself (`OverlayLayer`) already exists — children added to it need their own mouse_filter set.

**How to avoid:** When building the overlay background ColorRect, explicitly set `bg.mouse_filter = Control.MOUSE_FILTER_STOP`. The value `0` is STOP (same as used in the existing prestige fade: `fade_rect.mouse_filter = 0`).

**Warning sign:** Clicks passing through the overlay to buttons underneath.

### Pitfall 3: CanvasLayer Children Are Not Control Nodes by Default

**What goes wrong:** Adding a Node2D to a CanvasLayer works but doesn't participate in Godot's Control/UI layout system — no anchors, no `set_anchors_and_offsets_preset()`, no mouse_filter. The overlay background and card layout must use Control-derived nodes (ColorRect, VBoxContainer, etc.).

**How to avoid:** Make the root overlay node a `Control` or `ColorRect`, not a `Node2D`. Use `set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)` to fill the viewport.

**Warning sign:** Overlay not covering the full 1280x720, or positioned at (0,0) with wrong size.

### Pitfall 4: Tween After queue_free

**What goes wrong:** If the tween's `tween_callback` calls `queue_free` but the node is already freed (e.g., by another code path), Godot emits an error. The tween itself holds a reference and normally prevents this, but care is needed.

**How to avoid:** Use `tween.tween_callback(overlay_root.queue_free)` at the end of the tween chain. Ensure no other code path frees the overlay during the 0.3s fade. Disable the card buttons immediately on selection (before the tween starts) to prevent double-clicks.

**Warning sign:** "Attempt to call function on a freed instance" error in the Godot output.

### Pitfall 5: generate_choices() Called Before REGISTRY Is Available

**What goes wrong:** `HeroArchetype.generate_choices()` uses `Array.pick_random()` which calls GDScript's RNG. This is deterministic within a session but produces different heroes each scene load — this is correct and expected behavior (SEL-01 says "drawn randomly").

**How to avoid:** No action needed — this is the intended behavior. Call `generate_choices()` once in `_show_hero_selection()` and store the result for card construction.

### Pitfall 6: Hero Archetype Set But Not Reflected in Hero Stats

**What goes wrong:** After the player picks a hero, `GameState.hero_archetype` is set, but `GameState.hero.update_stats()` may not be called. The hero passive bonuses only apply when `update_stats()` runs (per Phase 51 implementation).

**How to avoid:** After setting `GameState.hero_archetype`, call `GameState.hero.update_stats()` before saving. Verify by checking that passive bonus keys appear in `GameState.hero.computed_stats` (or equivalent) after selection.

**Warning sign:** Hero archetype is set in save file but passive bonuses have no effect in gameplay.

---

## Code Examples

### Full overlay detection check in main_view._ready()

```gdscript
# Source: main_view.gd pattern + D-08/D-09 locked decisions
func _ready() -> void:
    # ... existing setup code ...
    show_view("forge")

    # Hero selection check (D-08, D-09)
    if GameState.prestige_level >= 1 and GameState.hero_archetype == null:
        _show_hero_selection()


func _show_hero_selection() -> void:
    var choices: Array[HeroArchetype] = HeroArchetype.generate_choices()
    # Build overlay node tree and add to $OverlayLayer
    # ...
```

### Card construction pattern (combining prestige_view pattern + D-01 through D-07)

```gdscript
func _build_card(hero: HeroArchetype) -> Control:
    var card := PanelContainer.new()
    card.custom_minimum_size = Vector2(360, 200)  # within ~380px budget (D-05)

    # Colored left border via StyleBoxFlat (D-03)
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.12, 0.12, 0.12, 1.0)
    style.border_width_left = 5
    style.border_color = hero.color
    card.add_theme_stylebox_override("panel", style)

    var vbox := VBoxContainer.new()
    card.add_child(vbox)

    # Archetype + subvariant header (D-01)
    var arch_label := Label.new()
    arch_label.text = _archetype_string(hero)  # e.g., "STR - Hit"
    vbox.add_child(arch_label)

    # Hero title (D-01), white text (D-03)
    var title_label := Label.new()
    title_label.text = hero.title
    title_label.add_theme_color_override("font_color", Color.WHITE)
    vbox.add_child(title_label)

    # Passive bonuses (D-02)
    for bonus_str in HeroArchetype.format_bonuses(hero.passive_bonuses):
        var bonus_label := Label.new()
        bonus_label.text = bonus_str
        vbox.add_child(bonus_label)

    # Click to select (D-07) — wrap in Button or connect gui_input
    card.gui_input.connect(func(event):
        if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            _on_card_selected(hero)
    )
    card.mouse_filter = Control.MOUSE_FILTER_STOP

    return card
```

### Selection handler and fade-out (D-13, D-14)

```gdscript
func _on_card_selected(hero: HeroArchetype) -> void:
    # Set archetype and update stats (D-14 + Pitfall 6)
    GameState.hero_archetype = hero
    GameState.hero.update_stats()

    # Persist immediately (D-14)
    SaveManager.save_game()

    # Emit signal for any listeners
    GameEvents.hero_selected.emit(hero)

    # Disable all cards to prevent double-click
    # (disable card mouse_filter during fade)
    _overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE

    # Fade out over 0.3s then free (D-13)
    var tween = create_tween()
    tween.tween_property(_overlay_root, "modulate:a", 0.0, 0.3)
    tween.tween_callback(_overlay_root.queue_free)
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Separate .tscn for every UI component | Programmatic construction for transient/data-driven UI | Phase 50 (prestige_view.gd pattern established) | Fewer files, faster iteration |
| Scene-level signal connections in .tscn | Code-level `.connect()` calls in `_ready()` | Established in main_view.gd | Explicit, traceable wiring |

**Deprecated/outdated:**
- Nothing deprecated for this phase — all patterns are current.

---

## Open Questions

1. **Should `_show_hero_selection()` emit `GameEvents.hero_selection_needed` or skip it?**
   - What we know: `hero_selection_needed` signal exists in game_events.gd (Phase 50), but no subscriber is connected anywhere yet.
   - What's unclear: The CONTEXT.md says signal wiring is Claude's discretion. The signal may be useful for future features (logging, tutorial hints).
   - Recommendation: Emit `hero_selection_needed` when showing the overlay for forward-compatibility, but do not rely on it for current behavior. The overlay shows regardless.

2. **What happens if `generate_choices()` returns the same hero the player had before prestige?**
   - What we know: `_wipe_run_state()` nulls `hero_archetype`. `generate_choices()` picks randomly per archetype. It is possible (1-in-3 per slot) that a prior hero type reappears.
   - What's unclear: Is this a problem? Per current requirements, no — each prestige is a fresh draft.
   - Recommendation: No special handling needed. The system is working as designed.

3. **Does `update_stats()` need to be called after hero selection, and what does it read?**
   - What we know: Phase 51 implementation routes `hero_archetype.passive_bonuses` through `update_stats()` when `GameState.hero_archetype` is set. `is_spell_user` is derived at the top of `update_stats()`.
   - What's unclear: Whether `update_stats()` auto-reads from `GameState.hero_archetype` or needs to be explicitly triggered.
   - Recommendation: Call `GameState.hero.update_stats()` explicitly after setting `GameState.hero_archetype` to guarantee stats reflect the new hero. This is a one-line call and has no downside.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Godot in-engine integration test (GDScript scene) |
| Config file | `tools/test/integration_test.gd` (standalone scene, run with F6) |
| Quick run command | Run `tools/test/integration_test.gd` scene from Godot editor (F6) |
| Full suite command | Same — all groups run in sequence via `_ready()` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SEL-01 | `generate_choices()` returns 3 heroes (1 STR, 1 DEX, 1 INT) | unit | Group 39 in integration_test.gd | ❌ Wave 0 |
| SEL-01 | Each card hero has title, color, passive_bonuses | unit | Group 39 in integration_test.gd | ❌ Wave 0 |
| SEL-01 | `format_bonuses()` converts 0.25 to "+25% Attack Damage" | unit | Group 39 in integration_test.gd | ❌ Wave 0 |
| SEL-02 | P0 state: prestige_level==0 -> overlay NOT triggered | unit | Group 39 in integration_test.gd | ❌ Wave 0 |
| SEL-02 | P1+ state with null archetype -> overlay triggered | unit | Group 39 in integration_test.gd | ❌ Wave 0 |
| SEL-02 | P1+ state with non-null archetype -> overlay NOT triggered | unit | Group 39 in integration_test.gd | ❌ Wave 0 |
| SEL-03 | After selection: hero_archetype set on GameState | unit | Group 39 in integration_test.gd | ❌ Wave 0 |
| SEL-03 | After selection: hero_archetype_id in save data matches selected hero | unit | Group 39 in integration_test.gd | ❌ Wave 0 |
| SEL-03 | BONUS_LABELS covers all 13 passive_bonuses keys in REGISTRY | unit | Group 39 in integration_test.gd | ❌ Wave 0 |

Note: The overlay's visual block (mouse_filter STOP, full-screen coverage) cannot be automated in integration_test.gd — these are runtime/visual properties verified manually by running the game and performing a prestige.

### Sampling Rate
- **Per task commit:** Run integration_test.gd (F6), verify Group 39 results and no regressions in Groups 36-38
- **Per wave merge:** Full suite green (all 39 groups pass)
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] Group 39 test functions in `tools/test/integration_test.gd` — covers SEL-01, SEL-02, SEL-03
- [ ] `HeroArchetype.BONUS_LABELS` const and `format_bonuses()` static method — required before tests can run (D-15/D-16)

*(The existing `_group_38_save_persistence()` already covers SAVE-01 which is a dependency for this phase.)*

---

## Sources

### Primary (HIGH confidence)
- Direct code reading: `scenes/main_view.gd` — prestige fade pattern, OverlayLayer wiring, `_ready()` structure
- Direct code reading: `models/hero_archetype.gd` — REGISTRY, `generate_choices()`, `from_id()`
- Direct code reading: `autoloads/game_events.gd` — signal declarations
- Direct code reading: `autoloads/game_state.gd` — `hero_archetype` field, `_wipe_run_state()`
- Direct code reading: `autoloads/save_manager.gd` — `save_game()`, `_build_save_data()`
- Direct code reading: `scenes/main.tscn` — OverlayLayer structure, FadeRect defaults
- Direct code reading: `scenes/prestige_view.gd` — programmatic node construction pattern
- Direct code reading: `tools/test/integration_test.gd` — test group pattern (Groups 36-38)

### Secondary (MEDIUM confidence)
- Godot 4 Control.MOUSE_FILTER_STOP constant value confirmed by existing code: `fade_rect.mouse_filter = 0` in main_view.gd
- Tween pattern confirmed by existing code: `create_tween().tween_property(...).tween_callback(...)` in main_view.gd

### Tertiary (LOW confidence)
- None — all findings sourced directly from project code.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all nodes are Godot 4 built-ins verified by existing code usage in this project
- Architecture: HIGH — patterns directly sourced from existing project files (prestige_view.gd, main_view.gd)
- Pitfalls: HIGH — derived from reading actual code paths and Godot node behavior patterns already in use
- BONUS_LABELS coverage: HIGH — all bonus keys enumerated from REGISTRY in hero_archetype.gd

**Research date:** 2026-03-27
**Valid until:** Stable — no external dependencies; all patterns are project-internal. Valid until codebase changes.
