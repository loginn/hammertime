# Project Research Summary

**Project:** Hammertime v1.2 - Pack-Based Combat System
**Domain:** Idle ARPG combat integration with defensive mechanics
**Researched:** 2026-02-16
**Confidence:** HIGH

## Executive Summary

Hammertime v1.2 adds pack-based combat, defensive stat mechanics, and death penalties to an existing Resource-based ARPG crafting game built on Godot 4.5. The research validates that the existing architecture is exceptionally well-suited for this integration. All core technologies (Godot 4.5, GDScript, Mobile renderer) are already validated from v1.1, requiring no stack changes. The combat system uses SceneTreeTimer + await for sequential idle combat, Resource-based monster packs matching the existing Item/Currency pattern, and extends StatCalculator with defensive formulas.

The recommended approach follows Path of Exile's proven ARPG defensive mechanics: layered defense (armor → evasion → resistances → energy shield), damage-relative armor formula preventing immunity, 75% resistance caps, and roguelite death penalty (lose progress but keep currency). Critical risks center on progression curve disruption when switching from time-based to pack-based clearing, defensive formula edge cases (division by zero, resistance bypass), and combat pacing mismatch for idle gameplay. These are well-documented with concrete prevention strategies.

Implementation follows a bottom-up dependency order: data layer (MonsterPack, Map Resources) → calculation layer (StatCalculator defense methods, Hero damage calculation) → state layer (GameState pack tracking, GameEvents signals) → view layer (gameplay_view combat loop). The existing feature-based folder structure, autoload pattern, and signal bus architecture require no restructuring. The integration is additive, not disruptive.

## Key Findings

### Recommended Stack

**No stack changes required.** All combat features use Godot 4.5 built-in APIs already validated in v1.1. The stack research confirmed that sequential idle combat is best implemented with SceneTreeTimer + await (one-shot timers, auto-cleanup, clean async code), monster data as Resources with class_name (matches existing pattern), and signal-based combat state via GameEvents autoload (consistent with equipment_changed/item_crafted pattern).

**Core technologies:**
- **Godot Engine 4.5:** Already validated in v1.1. No changes needed for combat system additions.
- **GDScript 4.5:** Await/async syntax perfect for sequential idle combat (await pack death → spawn next pack).
- **SceneTreeTimer + await:** Sequential pack combat timing. No node instantiation overhead, cleaner than Timer nodes for one-shot delays.
- **Resource with class_name:** Monster pack definitions with HP/damage/elemental type. Matches existing Item/Currency/Affix Resource pattern.
- **Signal-based via GameEvents:** Combat lifecycle events (pack_spawned, pack_defeated, hero_died). Extends existing signal architecture.
- **StatCalculator static methods:** Armor/evasion/resistance formulas. Extends existing DPS calculation pattern, keeps combat math centralized and testable.

**Avoid:**
- CharacterBody2D/3D for monsters (idle combat has no movement, physics bodies cause performance overhead)
- Navigation2D (no pathfinding needed, navigation parsing is a documented performance issue)
- Multiple combat autoloads (fragments state, use single GameState)
- Separate DamageCalculator class (splits combat math from existing StatCalculator, inconsistent)

### Expected Features

**Must have (v1.2 MVP):**
- Sequential pack combat — hero fights packs one at a time, each with HP pool. Core idle ARPG pattern.
- Physical + 3 elemental damage types (fire/cold/lightning) — ARPG standard, items already have these stats.
- Armor reduces physical damage via PoE formula (Armor / (Armor + 5 × Damage)) — essential to make armor stat useful.
- Resistances reduce elemental damage with 75% cap — essential to make resistance stats useful.
- Evasion = dodge chance with diminishing returns — essential to make evasion stat useful.
- Energy shield as extra HP buffer — depletes before life, basic implementation without recharge for v1.2.
- Death = lose map progress, keep currency — roguelite pattern (Hades/Dead Cells), fair failure state for idle games.
- Random pack count per map — simple replayability, 3-6 packs early areas, 8-15 endgame.
- Packs drop currency, maps drop items — split reinforces "death has some value" pattern.
- Biome damage distributions — Forest 80% physical, Shadow Realm 20% physical / 80% elemental progression curve.

**Should have (v1.x iterations):**
- Energy shield recharge mechanic (2s delay, then recharge) — adds strategic depth after core combat is stable.
- Elemental damage preview before entering map — QoL to prevent "oops I wasn't resist-capped" deaths.
- Visible damage breakdown in combat log — educational, teaches players why defenses matter.
- Biome-specific pack elemental variance — adds variety once combat feels repetitive.

**Defer (v2+):**
- Energy shield recharge rate modifiers (affix pool expansion)
- Evasion entropy system (PoE-style pseudo-random to eliminate RNG streaks)
- Elemental status effects (fire ignites, cold chills, lightning shocks)
- Partial map progress on death (keep some % of items based on packs killed)

**Anti-features to avoid:**
- 100% damage immunity (breaks balance, hard cap resistances at 75%)
- Per-monster loot drops (inventory explosion, contradicts "idle" philosophy)
- Real-time combat with player timing (conflicts with "idle" genre)
- Complex elemental interaction systems (massive balancing nightmare)

### Architecture Approach

The v1.2 architecture integrates pack-based combat with minimal disruption to existing systems. New Resources (MonsterPack, Map) follow the established pattern. StatCalculator extends with defensive functions matching the existing DPS pattern. GameState adds pack tracking fields without restructuring. gameplay_view gets a major rework from time-based clearing to pack-based combat loop, but this is the only breaking change.

**Major components:**
1. **MonsterPack Resource** (models/combat/monster_pack.gd) — pack HP/damage/elemental type, matches Item/Currency Resource pattern.
2. **Map Resource** (models/combat/map.gd) — replaces area_level integer, encapsulates map progression state (total_packs, packs_cleared, current_pack).
3. **StatCalculator defense extensions** (models/stats/stat_calculator.gd) — armor reduction, resistance capping, evasion chance. Pure functions extending existing offensive calculation service.
4. **Hero damage calculation** (models/hero.gd) — calculate_damage_taken() delegates to StatCalculator, keeps defensive logic centralized.
5. **GameState pack tracking** (autoloads/game_state.gd) — current_map, current_pack, death tracking. Single source of truth for combat state.
6. **GameEvents combat signals** (autoloads/game_events.gd) — pack_spawned, pack_defeated, hero_died. Decouples combat logic from UI updates.
7. **LootTable split** (models/loot/loot_table.gd) — roll_pack_drops() for currency, roll_map_drops() for items. Preserves existing methods for backward compatibility.
8. **gameplay_view combat loop** (scenes/gameplay_view.gd) — timer-based combat with pack progression, signal emissions, death handling. Major rework from time-based clearing.

**Build order (dependency-driven):**
1. MonsterPack/Map Resources (no dependencies)
2. StatCalculator defensive functions (depends on Tag.StatType)
3. Hero damage calculation (depends on StatCalculator)
4. GameState pack tracking (depends on Map, MonsterPack)
5. GameEvents combat signals (no dependencies)
6. LootTable map drops (depends on existing Item/rarity logic)
7. gameplay_view rework (depends on everything, last to implement)

### Critical Pitfalls

1. **Armor formula division by zero and edge cases** — Damage reduction formulas fail at extremes: negative armor, uncapped resistance, zero damage. Prevention: hard cap all mitigation at 90%, floor at -100%, clamp resistances before calculation, test with extreme values (armor=0, armor=999999, armor=-1000). Address in Phase 1 (defensive prefix foundation).

2. **Progression curve disruption from gameplay loop change** — Switching from time-based to pack-based clearing breaks v1.1 progression curve. Currency drops balanced for "X per minute" become "X per pack" with variable clear speed. Prevention: normalize currency drops to DPS tiers, implement pack scaling, run statistical baseline testing (simulate 1000 clears at each gear tier), verify currency/hour matches v1.1 baseline ±20%. Address in Phase 3 (drop split) and Phase 4 (combat pacing).

3. **Combat pacing mismatch for idle games** — Combat either resolves instantly (feels like clicker) or drags 2-3 minutes per pack (frustrating). Prevention: target 5-15 seconds per pack, implement time-to-kill normalization, add combat speed multiplier setting (1x/2x/4x), use exponential pack HP scaling with logarithmic curve flattening, test with underpowered gear. Address in Phase 4 (combat pacing).

4. **State management race conditions during combat** — Hero starts clearing, player unequips weapon mid-combat, DPS recalculates to 0, division by zero crashes game. Or double-clicking "Clear" spawns two parallel combat loops. Prevention: lock equipment during combat (disable actions while is_clearing=true), snapshot combat stats at combat start, atomic state transitions via signal-based state machine, validate state before actions. Address in Phase 2 (pack-based combat loop) and Phase 5 (death mechanics).

5. **Resistance cap bypass and invincibility** — Player stacks fire resistance to 150% via suffixes on all gear slots, formula doesn't cap resistance, hero becomes immune or negative damage heals hero. Prevention: clamp all resistances to [-100, 90] in calculate_defense(), display capped and uncapped values in UI, apply cap before damage calculation, add overcap testing (test hero with 200% resistance). Address in Phase 1 (defensive prefix foundation).

## Implications for Roadmap

Based on research, suggested phase structure following dependency order and pitfall prevention:

### Phase 1: Defensive Stat Foundation
**Rationale:** Bottom-up dependency order. Data layer before calculation layer. Defensive stats (armor, evasion, resistances) must exist before combat can use them. Addresses critical pitfalls (armor formula edge cases, resistance cap bypass) at foundation level before they compound.

**Delivers:**
- StatCalculator defensive methods (armor reduction, resistance capping, evasion chance)
- Hero.calculate_damage_taken() integration
- Test suite for edge cases (negative armor, resistance >100%, zero damage)
- Defensive stat display in hero_view

**Addresses features:**
- Armor vs physical damage (PoE formula)
- Resistance vs elemental damage (75% cap)
- Evasion = dodge chance (diminishing returns)

**Avoids pitfalls:**
- Armor formula division by zero (hard caps, epsilon checks)
- Resistance cap bypass (clamp to [-100, 90] range)
- Negative armor amplification asymmetry (separate formula for negative values)

**Research flag:** Standard patterns, well-documented ARPG formulas. Skip phase-level research.

---

### Phase 2: Monster Pack Data Model
**Rationale:** Second layer of dependency tree. Combat loop needs monster packs to exist. Resource pattern matches existing architecture (Item, Currency, Affix all extend Resource). Can be tested in isolation before integrating with combat loop.

**Delivers:**
- MonsterPack Resource (models/combat/monster_pack.gd)
- Map Resource (models/combat/map.gd)
- Pack generation logic (HP/damage scaling by area)
- GameState pack tracking fields (current_map, current_pack)
- GameEvents combat signals (pack_spawned, pack_defeated, hero_died)

**Addresses features:**
- Sequential pack combat (data structure foundation)
- Random pack count per map (Map.total_packs randomization)
- Physical + elemental damage types (MonsterPack.damage_type)
- Biome damage distributions (Map.biome determines pack type distribution)

**Avoids pitfalls:**
- State management race conditions (establish single source of truth in GameState)
- Combat pacing mismatch (exponential HP scaling formula built into pack generation)

**Research flag:** Standard patterns. Skip phase-level research.

---

### Phase 3: Pack-Based Combat Loop
**Rationale:** Third layer. Depends on Phase 1 (defensive calculations) and Phase 2 (monster data). Integrates everything into gameplay_view. Major rework but isolated to single file. State machine prevents race conditions. Snapshot stats prevent equipment change bugs.

**Delivers:**
- gameplay_view combat timer loop
- Hero attacks pack → Pack attacks hero flow
- Combat state machine (IDLE → FIGHTING → PACK_TRANSITION → MAP_COMPLETE)
- Equipment locking during combat (is_clearing flag)
- Stat snapshots at combat start

**Addresses features:**
- Sequential pack combat (core mechanic implementation)
- Death = lose map progress (hero_died signal, stop combat, no map completion drops)
- Energy shield as buffer HP (ES depletes before life in damage calculation)

**Avoids pitfalls:**
- State management race conditions (equipment locking, state machine, stat snapshots)
- Combat pacing mismatch (TTK testing with beginner/mid/endgame gear)
- Integer overflow in damage calculations (enforce float types, clamp before display)

**Research flag:** Complex integration. Consider `/gsd:research-phase` for state machine patterns and async combat cancellation if team is unfamiliar with Godot SceneTreeTimer patterns.

---

### Phase 4: Loot System Split
**Rationale:** Fourth layer. Depends on Phase 3 (combat loop must exist to emit pack_defeated/map_completed signals). LootTable backward compatibility is critical — existing crafting/simulator must not break. Requires statistical validation against v1.1 baseline.

**Delivers:**
- LootTable.roll_pack_drops() (currency from pack kills)
- LootTable.roll_map_drops() (items from map completion)
- Preserve existing roll_rarity() and roll_currency_drops() for backward compatibility
- Currency drops on pack_defeated signal
- Item drops on map_completed signal
- Drop simulator validation (v1.1 vs v1.2 comparison)

**Addresses features:**
- Packs drop currency, maps drop items (core loot split)
- Death = lose map progress, keep currency (currency committed on pack kill, items on map complete)

**Avoids pitfalls:**
- Drop split implementation breaking LootTable (separate methods, deprecate carefully, test existing flows)
- Progression curve disruption (normalize drops to DPS tiers, statistical baseline testing, verify currency/hour)

**Research flag:** Needs validation research. Run `/gsd:research-phase` to analyze v1.1 drop rates, currency/hour baselines, and create statistical test plan. High risk of breaking economy.

---

### Phase 5: Combat Pacing Tuning
**Rationale:** Fifth layer. Depends on Phase 3 (combat loop) and Phase 4 (drops). Pure tuning phase. Pack HP scaling, combat speed, TTK normalization. Requires playtesting with multiple gear tiers. Iterative refinement based on feel.

**Delivers:**
- Pack HP scaling curve (exponential growth with logarithmic flattening)
- Combat speed multiplier setting (1x/2x/4x toggle)
- TTK normalization (5-15 seconds per pack at appropriate gear level)
- Underpowered gear testing (verify combat possible with white items)
- Visual feedback (HP bars, damage numbers, combat state indicators)

**Addresses features:**
- Random pack count per map (tune pack count ranges for pacing)
- Biome damage distributions (verify elemental damage feels impactful)

**Avoids pitfalls:**
- Combat pacing mismatch for idle games (5-15s TTK target, speed multiplier, animation decoupling)
- Progression curve disruption (verify pack HP scaling matches DPS growth curve)

**Research flag:** Standard tuning patterns. Skip phase-level research. Focus on playtesting and iteration.

---

### Phase 6: UI and Feedback Polish
**Rationale:** Final layer. Depends on all previous phases. Pure UX improvements. Combat must work before feedback can be tuned. Addresses "looks done but isn't" gaps (no visual feedback, hidden stats, unclear death).

**Delivers:**
- Combat state indicators (pulsing health bar, "Fighting Pack 3/10" display)
- Damage numbers (floating text on damage dealt/taken)
- Death feedback (combat log showing why hero died)
- Resistance stat visibility in hero_view (show capped vs uncapped values)
- Pack HP bar with elemental type indicator
- Currency drop floating text ("+5 Runic" on pack defeat)
- Combat log with damage breakdown ("Took 50 fire damage (0% resistance)")

**Addresses features:**
- Elemental damage preview (show biome's damage distribution before entering)
- Visible damage breakdown (educational, teaches players why defenses matter)

**Avoids pitfalls:**
- UX pitfalls (no visual feedback, hidden resistance stats, unclear death cause)
- Combat pacing mismatch (speed multiplier setting in UI)

**Research flag:** Standard UI patterns. Skip phase-level research.

---

### Phase Ordering Rationale

- **Bottom-up dependency order:** Data layer (Phase 1-2) → calculation layer (Phase 1) → state layer (Phase 2) → combat loop (Phase 3) → drops (Phase 4) → tuning (Phase 5) → polish (Phase 6).
- **Pitfall prevention at each layer:** Phase 1 addresses formula edge cases before they're used. Phase 2 establishes single source of truth before race conditions emerge. Phase 3 implements state machine from start. Phase 4 validates economy before launch. Phase 5 tunes feel. Phase 6 polishes UX.
- **Testability:** Each phase is independently testable. Phase 1 = unit tests for formulas. Phase 2 = resource generation tests. Phase 3 = combat loop integration tests. Phase 4 = drop rate statistical tests. Phase 5 = playtesting. Phase 6 = UX validation.
- **Incremental integration:** gameplay_view is the only breaking change (Phase 3). All other phases extend existing systems without disruption.

### Research Flags

**Phases likely needing deeper research during planning:**
- **Phase 4 (Loot System Split):** High risk of breaking economy. Needs v1.1 baseline analysis, statistical test plan, currency/hour normalization research. Run `/gsd:research-phase` before implementation.

**Phases with standard patterns (skip research-phase):**
- **Phase 1 (Defensive Stat Foundation):** Well-documented ARPG formulas, PoE/Diablo reference implementations, standard diminishing returns patterns.
- **Phase 2 (Monster Pack Data Model):** Godot Resource pattern already proven in v1.1, straightforward data structure.
- **Phase 3 (Pack-Based Combat Loop):** Standard timer-based combat, signal-driven state machine, well-documented in Godot tutorials. Consider research only if team unfamiliar with async patterns.
- **Phase 5 (Combat Pacing Tuning):** Iterative playtesting, no novel patterns.
- **Phase 6 (UI and Feedback Polish):** Standard Godot UI patterns, Tween animations, existing signal connections.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All technologies validated in v1.1. SceneTreeTimer, Resources, signals, StatCalculator all proven patterns. Official Godot 4.5 docs confirm no breaking changes. |
| Features | MEDIUM | Table stakes well-documented (PoE/Diablo standard). Differentiators (ES recharge, damage preview) are lower confidence — need playtesting to validate value. Anti-features clearly identified. |
| Architecture | HIGH | Bottom-up dependency order validated. Resource pattern, autoload singletons, signal bus all match existing codebase. Build order tested via existing v1.1 patterns. |
| Pitfalls | HIGH | Critical pitfalls well-documented with concrete examples from ARPG genre (PoE armor formula, resistance caps). Prevention strategies proven (hard caps, edge case testing, statistical validation). |

**Overall confidence:** HIGH

The stack and architecture are exceptionally solid because they extend proven patterns from v1.1 without introducing new technologies. Features are MEDIUM because differentiators need validation, but table stakes are industry-standard. Pitfalls are well-researched with concrete prevention strategies from ARPG genre history.

### Gaps to Address

- **Economy rebalancing validation:** v1.1 currency/hour baseline needs statistical measurement before Phase 4. Run drop_simulator.gd with existing configuration, record results, compare after pack-based drops implemented. Acceptable variance: ±20%. If outside range, adjust LootTable multipliers.

- **Combat feel tuning:** 5-15 second TTK target is educated guess, not validated. Needs playtesting in Phase 5 with beginner/mid/endgame gear tiers. May require iteration on pack HP scaling curve. Consider adding telemetry (track actual TTK per area, currency/hour) for data-driven tuning.

- **Energy shield recharge timing:** 2-second delay matches PoE but needs validation for idle gameplay. Idle games have different pacing expectations than active ARPGs. May need adjustment in v1.x based on player feedback. Start with basic ES (no recharge) in v1.2, add recharge mechanic in v1.3 after combat pacing is stable.

- **Elemental damage differentiation:** Fire/cold/lightning behave identically except for resistance checks. If elemental damage types feel too similar in playtesting, consider adding minor differences (fire = high single-hit, cold = many small hits, lightning = mixed) or defer to v2+ status effects (ignite/chill/shock).

## Sources

### Primary (HIGH confidence)

**Official Godot Documentation:**
- [Godot 4.5 Release](https://godotengine.org/releases/4.5/) — Verified 4.5 features (shader baker, TileMapLayer physics)
- [SceneTreeTimer (4.5 docs)](https://docs.godotengine.org/en/4.5/classes/class_scenetreetimer.html) — Confirmed one-shot timer API
- [GDScript Exports](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_exports.html) — Verified @export syntax
- [Overview of Renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html) — Mobile renderer limitations

**Path of Exile Wiki (ARPG damage formulas):**
- [Armour Formula](https://www.poewiki.net/wiki/Armour) — Verified: DR = A/(A + 5×D), 90% cap
- [Energy Shield Mechanics](https://www.poewiki.net/wiki/Energy_shield) — Verified: 2s recharge delay, 33.3%/s rate
- [Resistance](https://www.poewiki.net/wiki/Resistance) — Verified: 75% cap standard
- [Damage Reduction](https://www.poewiki.net/wiki/Damage_reduction) — Verified: 90% max, -200% min caps

### Secondary (MEDIUM confidence)

**ARPG Defense Mechanics:**
- [Path of Exile 2 Defense Guide](https://www.sportskeeda.com/mmo/exile-2-poe2-defense-resistance-guide-energy-shield-armor-evasion) — Layered defense system
- [Maxroll Defense Layering](https://maxroll.gg/poe/resources/defenses-and-defensive-layering) — Defense layer ordering
- [Diablo 3 Damage Reduction Explained](https://maxroll.gg/d3/resources/damage-reduction-explained) — D3 armor formula comparison
- [PoE 2 Guide: Armour Explained](https://mobalytics.gg/poe-2/guides/armour) — Recent PoE2 changes (formula updated to Armor/(Armor + 12×Damage))

**Idle Game Design Patterns:**
- [How to Design Idle Games](https://machinations.io/articles/idle-games-and-how-to-design-them) — Boss as roadblock, passive farming vs active pushing
- [The Math of Idle Games, Part I](https://blog.kongregate.com/the-math-of-idle-games-part-i/) — Kongregate research on exponential vs linear scaling
- [Game tick - OSRS Wiki](https://oldschool.runescape.wiki/w/Game_tick) — Tick rate examples (20ms client-side, 600ms-1200ms combat)
- [Combat - Idle Clans wiki](https://wiki.idleclans.com/index.php/Combat) — Attack meter pattern

**Godot Architecture Patterns:**
- [Game Development Patterns with Godot 4](https://www.packtpub.com/en-us/product/game-development-patterns-with-godot-4-9781835880296) — Design pattern reference
- [GDQuest: Design patterns in Godot](https://www.gdquest.com/tutorial/godot/design-patterns/intro-to-design-patterns/) — State machine, service layer
- [Custom Resources in Godot 4](https://ezcha.net/news/3-1-23-custom-resources-are-op-in-godot-4) — Resource with class_name patterns

### Tertiary (LOW confidence)

**Community Discussions:**
- [Resource-based Enemy Data](https://forum.godotengine.org/t/beginner-making-sure-i-understand-resources-to-set-up-the-monster-database-in-a-retro-styled-rpg/72046) — Resource patterns for monsters
- [Idle Game Combat Automation](https://medium.com/@sexwoojisung/what-if-idle-rpgs-let-you-design-the-auto-battle-0ab3cdb24295) — Idle game design patterns
- [Tween vs AnimationPlayer Performance](https://forum.godotengine.org/t/tween-vs-animation-player-performance/2278) — Performance comparison
- [Physics Performance Issues](https://forum.godotengine.org/t/guidance-when-optimizing-minimizing-idle-time-and-reading-the-profiler/29052) — Avoid physics for idle games

**Incremental Game Economy:**
- [Designing Game Economies](https://medium.com/@msahinn21/designing-game-economies-inflation-resource-management-and-balance-fa1e6c894670) — Faucets, sinks, inflation
- [I Designed Economies for $150M Games](https://www.gamedeveloper.com/production/i-designed-economies-for-150m-games-here-s-my-ultimate-handbook) — Professional economy design
- [The Math of Idle Games Part III](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-iii) — Progression curve design

---
*Research completed: 2026-02-16*
*Ready for roadmap: yes*
