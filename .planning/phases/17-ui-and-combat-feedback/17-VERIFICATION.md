---
phase: 17
phase_name: UI and Combat Feedback
status: passed
verified: 2026-02-17
must_haves_passed: 4
must_haves_total: 4
---

# Phase 17: UI and Combat Feedback — Verification

## Goal
Players can observe pack-based combat state, HP changes, and progression through the map.

## Must-Haves Verification

### 1. Gameplay view displays pack-based combat instead of time-based progress bar
**Status: PASSED**

- MaterialsLabel completely removed from gameplay_view.tscn and gameplay_view.gd
- CanvasLayer > UIRoot > ProgressBar nodes for hero HP (red), ES (blue overlay), pack HP (orange-red), pack progress (green)
- All bars styled with unique StyleBoxFlat instances, show_percentage disabled
- update_display() reads from GameState.hero and CombatEngine state — no text dump

**Evidence:**
- `scenes/gameplay_view.tscn`: HeroHPBar, HeroESBar, PackHPBar, PackProgressBar as ProgressBar nodes under CanvasLayer
- `scenes/gameplay_view.gd`: 8 StyleBoxFlat.new() calls in _setup_bar_styles(), no MaterialsLabel reference

### 2. Current pack HP and hero HP are visible and update during combat
**Status: PASSED**

- hero_hp_bar.value = hero.health, hero_hp_bar.max_value = hero.max_health (gameplay_view.gd lines 222-223)
- hero_es_bar overlaid on HP bar when ES > 0 with correct max_value = total_energy_shield (lines 228-231)
- hero_hp_label shows "150/200 ES: 50/100" format when ES exists, "150/200" when not
- pack_hp_bar.value = pack.hp, pack_hp_bar.max_value = pack.max_hp (lines 251-253)
- Pack container visible only during FIGHTING state with valid pack
- All updates triggered by GameEvents signals, not _process polling

**Evidence:**
- Signal handlers: _on_hero_attacked, _on_pack_attacked both call update_display()
- Bar values set from GameState.hero (single source of truth)

### 3. Pack progress is shown clearly (e.g., "Pack 3 of 7 cleared")
**Status: PASSED**

- pack_progress_bar with green fill, max_value = total_packs, value = current_pack_index
- pack_progress_label shows "%d/%d" format (e.g., "3/7")
- Updates instantly on pack_killed signal (snappy, no tween animation)
- Visible during FIGHTING and MAP_COMPLETE states
- Area level and biome name shown via area_label: "Biome -- Level N"

**Evidence:**
- gameplay_view.gd lines 260-265: pack_progress_bar/label update logic
- AreaLabel in .tscn at offset 50,50 always visible

### 4. Combat state changes are visible (fighting, pack transition, death, map complete)
**Status: PASSED**

- combat_state_label updated in every signal handler with appropriate colors:
  - "Fighting..." (white) on combat_started
  - "Pack cleared!" (white) on pack_killed
  - "Hero died! Retrying..." (red Color(1.0, 0.3, 0.3)) on hero_died
  - "Map Clear!" (green Color(0.2, 0.9, 0.2)) on map_completed
  - "Combat stopped." (white) on combat_stopped
- Pack-to-pack transition: 0.5s await delay in combat_engine._on_pack_killed() with state guard
- Death retry: 2.5s await delay in combat_engine._on_hero_died() with state guard
- Map complete: auto-advances seamlessly to next map via start_combat(area_level)

**Evidence:**
- combat_engine.gd: pack_transition_delay_sec = 0.5, death_retry_delay_sec = 2.5
- Both delays have state guards preventing stale transitions after await

## Bonus: Floating Damage Numbers (Plan 17-02)

- FloatingLabel scene: self-animating Label with tween drift-up + fade-out
- Normal hits: white text at 1.0x scale
- Crits: gold Color(1.0, 0.8, 0.0) at 1.5x scale
- Evasion: "DODGE" white text
- Auto-cleanup: await tween.finished + queue_free()
- Uniform color regardless of element type (user decision)
- Spawned via _spawn_floating_text with random X jitter for visual variety

## Requirements Traceability

| Requirement | Status |
|-------------|--------|
| UI-01: Pack-based combat display | PASSED |
| UI-02: HP bars visible and updating | PASSED |
| UI-03: Pack progress and state visible | PASSED |

## Score: 4/4 must-haves passed

---
*Verified: 2026-02-17*
