# Phase 53: Selection UI - Context

**Gathered:** 2026-03-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Build the 3-card hero selection overlay that appears after prestige and blocks gameplay until a hero is picked. P0 players never see the overlay. Overlay fits 1280x720 viewport.

Requirements: SEL-01, SEL-02, SEL-03

</domain>

<decisions>
## Implementation Decisions

### Card Content
- **D-01:** Each card shows: archetype label + subvariant (e.g., "STR - Hit"), hero title (e.g., "The Berserker"), and human-readable passive bonus list.
- **D-02:** Bonuses displayed as percentage format: `+25% Attack Damage`, `+20% Bleed Chance`, etc. Converted from passive_bonuses dictionary values (0.25 -> "+25%").
- **D-03:** Card has a colored left border or outline using the hero's color from REGISTRY (red/green/blue). Title text stays white for readability.
- **D-04:** No flavor text or descriptions — title + bonuses is enough information.

### Card Layout
- **D-05:** 3 cards arranged in a horizontal row, centered in viewport. ~380px per card with gaps between.
- **D-06:** "Choose Your Hero" header text above the card row.
- **D-07:** Single click on card selects that hero immediately — no two-click confirmation. This is a positive choice, not destructive.

### Selection Trigger
- **D-08:** Detection happens in `main_view._ready()` after scene reload: if `GameState.prestige_level >= 1 AND GameState.hero_archetype == null`, show the overlay.
- **D-09:** P0 players (`prestige_level == 0`) never trigger the overlay regardless of archetype state.
- **D-10:** Flow: prestige wipe -> save -> fade to black -> reload_current_scene() -> main_view._ready() detects null archetype -> show overlay.

### Overlay Behavior
- **D-11:** Full-screen overlay on OverlayLayer (CanvasLayer layer 10) covers tab bar and all content. Mouse filter STOP blocks all clicks beneath.
- **D-12:** Overlay appears instantly on scene load (no fade-in). Since the scene just reloaded from prestige's black fade, instant appearance feels natural.
- **D-13:** After picking a hero, overlay fades out over ~0.3s revealing the forge view underneath.
- **D-14:** Auto-save triggered after hero selection so the choice persists immediately.

### Bonus Label System
- **D-15:** Static `BONUS_LABELS` dictionary on HeroArchetype maps bonus keys to display strings (e.g., `"attack_damage_more": "Attack Damage"`).
- **D-16:** Format helper on HeroArchetype: takes passive_bonuses dict, returns array of formatted strings like `"+25% Attack Damage"`.

### Claude's Discretion
- Exact card dimensions and spacing within the ~380px per card budget
- Font sizes for title vs bonus text
- Overlay background color/opacity (semi-transparent dark is standard)
- Whether selection overlay is a separate scene (.tscn) or built in code
- Implementation of the hero_selection_needed / hero_selected signal wiring

</decisions>

<specifics>
## Specific Ideas

- Cards should feel like a draft pick moment — 3 distinct options, one from each archetype
- The overlay pattern already exists (OverlayLayer with FadeRect at layer 10) — reuse that infrastructure
- Prestige flow already reloads the scene, so detection in _ready() is clean and requires no new signal plumbing for the trigger

</specifics>

<canonical_refs>
## Canonical References

### Requirements
- `.planning/REQUIREMENTS.md` — SEL-01 (3-card draft), SEL-02 (P0 classless), SEL-03 (overlay blocks gameplay)

### Prior Phase Context
- `.planning/phases/50-data-foundation/50-CONTEXT.md` — D-01/D-02: hero titles and colors; D-03 through D-06: passive bonus schema; D-07: spell_user authority
- `.planning/phases/52-save-persistence/52-CONTEXT.md` — D-07/D-08: prestige wipe nulls hero_archetype; Phase 53 owns UI detection

### Existing Patterns
- `scenes/main_view.gd` — Tab management, prestige fade flow, OverlayLayer usage
- `scenes/prestige_view.gd` — Two-click confirmation pattern (not used here, but reference for prestige flow)
- `scenes/main.tscn` — OverlayLayer (CanvasLayer layer 10) with FadeRect and SaveToast
- `models/hero_archetype.gd` — REGISTRY data, generate_choices(), from_id()
- `autoloads/game_events.gd` — hero_selection_needed and hero_selected signals (wired in Phase 50)
- `autoloads/game_state.gd` — hero_archetype nullable field, prestige_level

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `HeroArchetype.generate_choices()`: Returns 3 heroes (1 STR, 1 DEX, 1 INT) — call this to populate the 3 cards
- `HeroArchetype.from_id()`: Already exists for save/load — not needed for selection but validates the data model
- `OverlayLayer` (CanvasLayer, layer 10): Already in main.tscn with FadeRect — hero selection overlay goes here
- `GameEvents.hero_selection_needed` / `hero_selected`: Signals exist from Phase 50, ready to wire

### Established Patterns
- Prestige fade: `_on_prestige_triggered()` tweens FadeRect alpha to 1.0, then calls `reload_current_scene()` — overlay appears after this reload
- Tab visibility management: `show_view()` hides all views then shows selected — overlay bypasses this entirely (lives on CanvasLayer above tab system)
- Programmatic UI construction: prestige_view.gd builds unlock table rows in code — card construction can follow same pattern
- mouse_filter = STOP (value 0) on FadeRect blocks input during prestige fade — same pattern for selection overlay background

### Integration Points
- `main_view._ready()` — add hero selection check after existing setup
- `OverlayLayer` in main.tscn — add hero selection overlay node (sibling to FadeRect and SaveToast)
- `SaveManager.save_game()` — call after hero selection to persist choice
- `GameState.hero_archetype` — set when player picks a card
- `GameEvents.hero_selected` — emit after selection for any listeners

</code_context>

<deferred>
## Deferred Ideas

- Hero bonus display in ForgeView stat panel — Phase 54
- Balance tuning of bonus magnitudes — Phase 54
- Prestige-level-gated hero pool (P1 basic, P3+ full roster) — Future requirement
- Hero selection animation (card flip, particle effects) — Future polish

</deferred>

---

*Phase: 53-selection-ui*
*Context gathered: 2026-03-27*
