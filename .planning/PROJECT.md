# Hammertime

## What This Is

An ARPG-style crafting idle game built in Godot 4.5. Players send a hero to fight monster packs across 4 biomes (Forest → Shadow Realm), collect item bases and crafting hammers, then use those hammers to craft and equip gear. Better gear lets the hero survive harder packs, which drop better and more plentiful loot. Items come in Normal, Magic, and Rare tiers with defensive and offensive affixes, each craftable with 6 themed hammers that add, remove, or reroll mods. Combat is pack-based idle auto-combat with death mechanics, defensive stat integration, and floating damage feedback. Game state persists via JSON save/load with auto-save and export/import strings.

## Core Value

The crafting loop must feel rewarding — finding items, using hammers to shape them, and equipping the result to push further into harder content.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

- ✓ Hero system with 5 equipment slots (weapon, helmet, armor, boots, ring)
- ✓ Item system with implicits, prefixes (up to 3), suffixes (up to 3), tier-based scaling
- ✓ Affix system with 9 prefix types and 15 suffix types, tag-based filtering
- ✓ Gameplay loop: clear areas, take damage, find item bases + hammers
- ✓ Area progression with difficulty scaling (Forest, Dark Forest, Cursed Woods, Shadow Realm)
- ✓ 5 item types with base classes (Weapon, Helmet, Armor, Boots, Ring)
- ✓ UI with Hero View (equipment/stats), Crafting View (hammers/inventory), Gameplay View (clearing)
- ✓ Code organization with feature-based folder structure (models/, scenes/, autoloads/, utils/) -- v0.1
- ✓ Signal-based UI communication following call-down/signal-up pattern -- v0.1
- ✓ Unified stat calculation system (StatCalculator) across all item types -- v0.1
- ✓ Tag system separation: AffixTag for filtering, StatType for damage routing -- v0.1
- ✓ Item rarity tiers (Normal/Magic/Rare) with configurable affix limits -- v1.0
- ✓ 6 crafting hammers with rarity-aware validation (Runic, Forge, Tack, Grand, Claw, Tuning) -- v1.0
- ✓ Area difficulty influences rarity drop weights -- v1.0
- ✓ 6 currency buttons replacing old 3-hammer system with select-and-click application -- v1.0
- ✓ Currency consumed only on successful application -- v1.0
- ✓ 9 defensive prefix affixes for non-weapon items (flat/% armor, evasion, energy shield, health, mana) -- v1.1
- ✓ Defensive prefixes use tag-based filtering (Tag.DEFENSE) -- v1.1
- ✓ StatCalculator handles defensive stat types with flat + percentage stacking -- v1.1
- ✓ Hero View shows separate Offense and Defense sections with non-zero filtering -- v1.1
- ✓ Individual fire/cold/lightning resistance suffixes replacing generic Elemental Reduction -- v1.1
- ✓ All-resistance suffix with narrower tier range for rarity balance -- v1.1
- ✓ Currency area gating: hard gates at 1/100/200/300 with linear ramping -- v1.1
- ✓ Logarithmic rarity interpolation with multi-item drops (1→4-5 items/clear) -- v1.1
- ✓ Advanced currencies (Grand, Claw, Tuning) significantly rarer than basic -- v1.1
- ✓ Runic Hammer 70/30 mod bias making TackHammer meaningful -- v1.1
- ✓ Implicit stat_types architecture: base stats flow through StatCalculator, not hardcoded -- v1.1
- ✓ DefenseCalculator with 4-stage damage pipeline (evasion, resistance, armor, ES/life split) -- v1.2
- ✓ MonsterPack/MonsterType Resources with biome-weighted element selection -- v1.2
- ✓ PackGenerator produces 8-15 packs per map with area-level scaling -- v1.2
- ✓ CombatEngine with state machine, dual attack timers, and auto-retry -- v1.2
- ✓ 7 combat signals on GameEvents for decoupled UI observation -- v1.2
- ✓ Pack-based idle combat replacing timer-based area clearing -- v1.2
- ✓ Per-pack currency drops with area scaling and difficulty bonus -- v1.2
- ✓ Map completion item drops (1-3 items) with area scaling -- v1.2
- ✓ Death penalty: lose map progress, keep earned currency -- v1.2
- ✓ ProgressBar-based combat UI with HP, ES overlay, pack HP, pack progress bars -- v1.2
- ✓ Floating damage numbers with crit styling and dodge text -- v1.2
- ✓ Explicit CanvasLayer visibility management for tab navigation -- v1.2
- ✓ JSON save/load with auto-save (5 min) and event-driven triggers (craft, equip, area clear) -- v1.3
- ✓ Save format versioning with migration pipeline for future compatibility -- v1.3
- ✓ Save string export/import with Base64 encoding and MD5 checksum validation -- v1.3
- ✓ Side-by-side ForgeView layout (equipment left, crafting right) with tab bar navigation -- v1.3
- ✓ Gameplay/combat view as separate full-width Adventure tab -- v1.3
- ✓ Hammer button tooltips describing behavior and rarity requirements -- v1.3
- ✓ Stat comparison on equip hover with color-coded deltas (green/red) -- v1.3
- ✓ Per-item-type crafting slots (weapon, helmet, armor, boots, ring) -- v1.3
- ✓ Two-click equip confirmation preventing accidental gear overwrites -- v1.3
- ✓ Starter Runic Hammer + weapon base for new game crafting tutorial -- v1.3
- ✓ Reduced Forest difficulty (40% reduction) for fresh hero survival -- v1.3
- ✓ Stat panels fit viewport with font size 11 and proper spacing -- v1.3

### Active

<!-- Current scope. Building toward these. -->

## Current Milestone: v1.4 Damage Ranges

**Goal:** Replace flat damage values with min-max ranges for weapons, monsters, and affixes, giving each element a distinct variance identity and updating UI to display ranges.

**Target features:**
- Weapon base damage ranges (min-max per weapon type)
- Monster damage ranges (min-max per monster type, scaling with area)
- Flat damage affix ranges with element-specific variance (Physical tight → Lightning extreme)
- Per-hit damage rolling in CombatEngine
- UI updates showing "X to Y" damage on items and tooltips
- DPS display using average of ranges

### Out of Scope

- Unique items -- defer to future milestone
- Item melting/salvage system -- future feature
- Chaos-style full reroll -- deliberate design choice: no full rerolls, craft carefully or equip as-is
- Drag-and-drop crafting UI -- select-and-click is sufficient
- Hybrid defense prefixes (armor+evasion single-slot) -- future scope
- Visual prefix/suffix separation in UI (color-coded or sectioned) -- future scope
- Totem system (forge god shrine with slottable pieces, favor mechanic, map modifiers) -- future scope, builds on pack-based mapping
- Real-time combat with player timing -- fundamentally conflicts with idle genre
- Per-monster loot drops -- item explosion in idle game = inventory nightmare
- 100% damage immunity -- removes challenge; 75% resistance cap is ARPG standard

## Context

- Built with Godot 4.5 (GDScript), targeting mobile renderer
- 5,464 LOC GDScript across ~50 files
- Feature-based folder structure: models/, scenes/, autoloads/, utils/, tools/
- Autoloads: ItemAffixes, Tag, GameState (Hero singleton + currency inventory), GameEvents (event bus), SaveManager (JSON persistence)
- Scene structure: main.tscn with main_view coordinating forge_view, gameplay_view via tab bar
- ForgeView combines hero equipment (left) and crafting inventory (right) in side-by-side layout
- StatCalculator handles all DPS/defense calculations with flat + percentage stacking
- DefenseCalculator handles all incoming damage with 4-stage pipeline
- All data classes extend Resource (Item, Affix, Implicit, Hero, Currency, MonsterType, MonsterPack, BiomeConfig)
- Currency system uses template method pattern (base Currency.apply() with _do_apply() overrides)
- LootTable provides per-pack currency drops and map completion item drops with area scaling
- CombatEngine manages pack-by-pack combat with state machine lifecycle and dual attack timers
- BiomeConfig defines biome element weight arrays and pack count ranges for 4 biomes
- SaveManager handles JSON save/load, auto-save timer, event triggers, and Base64 export/import
- 18 prefix types (9 offensive + 9 defensive) and 19 suffix types (15 original + 4 resistance)
- Shipped 5 milestones: v0.1 (architecture), v1.0 (crafting), v1.1 (content/balance), v1.2 (combat), v1.3 (save/load & polish)

## Constraints

- **Tech stack**: Godot 4.5, GDScript only
- **Platform**: Mobile target renderer, 1280x720 viewport
- **Architecture**: Feature-based folders, signal-based communication, Resource-based data model

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Hammers, not orbs | Game is called Hammertime -- all currencies are hammers | ✓ Good -- thematic consistency |
| No chaos/full reroll | Forces deliberate crafting -- you commit to items or melt them later | ✓ Good -- each hammer strike matters |
| PoE-style rarity tiers | Normal/Magic/Rare maps cleanly to affix count limits | ✓ Good -- clean system, intuitive |
| Select-and-click UI | Same flow as current hammers, minimal UI rework | ✓ Good -- shipped in 1 plan |
| Code cleanup before v1.0 | Clean foundation prevents compounding tech debt across crafting overhaul | ✓ Good -- v0.1 shipped clean in 2 days |
| Resource over Node for data | Enables serialization, reference counting, no scene tree dependency | ✓ Good -- cleaner data model |
| GameState/GameEvents autoloads | Single source of truth for hero, event bus for cross-scene signals | ✓ Good -- eliminated duplicate Hero instances |
| StatCalculator singleton | One calculation source replaces duplicate DPS logic in weapon/ring | ✓ Good -- fixed crit formula bug, removed 96 lines |
| Signal-based parent coordination | main_view connects child signals to sibling methods instead of get_node() | ✓ Good -- zero sibling coupling |
| Template method for Currency | Base apply() enforces validation/consumption flow, subclasses override _do_apply() | ✓ Good -- impossible to forget validation |
| Dictionary-based rarity limits | RARITY_LIMITS dict over match statement for configuration flexibility | ✓ Good -- easy to add tiers later |
| Independent currency drop chances | Each hammer type rolls independently, not mutually exclusive | ✓ Good -- richer rewards in harder areas |
| Tag.DEFENSE for defensive affixes | Single tag enables both defensive prefixes and resistance suffixes on appropriate items | ✓ Good -- clean extension point |
| Vector2i tier ranges | Configurable per-affix tier ranges (30 for defensive vs 8 for weapon) | ✓ Good -- backward compatible |
| Implicit stat_types as sole base stat source | Removed hardcoded base_armor, implicits flow through StatCalculator | ✓ Good -- intuitive stat math |
| 70/30 Runic Hammer mod bias | TackHammer meaningful on 70% of items instead of 50% | ✓ Good -- better currency design |
| Hard currency gating by area | Clearer progression than pure RNG, prevents early-game clutter | ✓ Good -- meaningful gates |
| Logarithmic rarity interpolation | Smooth progression between 4 anchor points, no discrete jumps | ✓ Good -- natural feeling |
| Multi-item drops at high areas | Endgame loot shower (4-5 items) compensates per-roll rare scarcity | ✓ Good -- rewarding endgame |
| DefenseCalculator 4-stage pipeline | Evasion -> Resistance -> Armor -> ES/Life split for all incoming damage | ✓ Good -- clean damage flow |
| MonsterPack Resources with biome weighting | Packs use BiomeConfig weight arrays for element selection per biome | ✓ Good -- thematic biome identity |
| CombatEngine dual-timer architecture | Independent hero/pack attack timers with state machine lifecycle | ✓ Good -- clean combat loop |
| base_attack_speed separate from base_speed | Combat timer cadence (hits/sec) vs DPS multiplier are distinct concepts | ✓ Good -- no double-counting |
| DPS / attack_speed for per-hit damage | Removes speed factor from DPS formula to get correct per-hit value | ✓ Good -- mathematically correct |
| Per-hit crit rolls in combat | randf() each hit vs expected-value in DPS display -- more exciting gameplay | ✓ Good -- combat variance |
| Auto-retry after death | Hero immediately starts new attempt on same level, no regression | ✓ Good -- idle-friendly |
| Deterministic area progression | area_level += 1 on map clear, not RNG-based | ✓ Good -- clear goal posts |
| Stacked ProgressBar ES overlay | Blue ES bar overlaid on red HP bar (PoE pattern) | ✓ Good -- intuitive health display |
| Explicit mouse_filter=IGNORE on containers | Godot defaults to STOP; non-interactive containers must be set to IGNORE | ✓ Good -- prevents phantom click blocking |
| Explicit CanvasLayer visibility management | CanvasLayer ignores parent visibility; must toggle in show_view() | ✓ Good -- tab navigation works correctly |
| JSON save over ResourceSaver | JSON enables export strings; ResourceSaver doesn't | ✓ Good -- Phase 21 export/import validated this |
| SaveManager autoload before GameState | Save infrastructure must exist before GameState._ready() calls load_game() | ✓ Good -- clean startup order |
| Unified ForgeView over separate tabs | Side-by-side layout shows equipment + crafting simultaneously | ✓ Good -- eliminates tab switching during crafting |
| Two-click equip confirmation | Prevents accidental overwrites without modal dialogs | ✓ Good -- non-intrusive safety |
| Godot tooltip_text for hammer tooltips | Built-in auto show/hide behavior, zero custom tooltip code | ✓ Good -- minimal implementation |
| Direct equip/melt on current_item | Removed finished_item state; Equip/Melt operate on crafting bench item directly | ✓ Good -- simpler state model |
| MD5 checksum on save export strings | Detects clipboard corruption without crypto overhead | ✓ Good -- catches copy errors |
| 40% Forest difficulty reduction | Fresh heroes survive 3+ packs with starter gear | ✓ Good -- playable from level 1 |
| Font size 11 for ForgeView | Prevents text overflow in 1280x720 viewport | ✓ Good -- readable and fits |
| Computed base_damage getter for backward compat | Weapon.base_damage returns (min+max)/2; zero changes to StatCalculator or UI | ✓ Good -- seamless migration |
| Immutable template bounds for affix reroll | dmg_min_lo/hi are never modified; reroll always reads from bounds, not rolled values | ✓ Good -- prevents range collapse |
| Base + scaled field pattern for affixes | base_dmg_* stores unscaled params, dmg_* stores tier-scaled; from_affix() passes base to avoid double-scaling | ✓ Good -- follows existing base_min/base_max pattern |
| ELEMENT_VARIANCE in PackGenerator | Constants define min_mult/max_mult per element; Physical 1:1.5 through Lightning 1:4 | ✓ Good -- centralized, easy to tune |
| Dual-accumulator per-element damage ranges | StatCalculator tracks min and max separately per element; percentage mods scale both independently | ✓ Good -- mathematically correct variance preservation |
| Hero range-based DPS formula | DPS = sum of per-element (min+max)/2 * speed * crit instead of summing weapon.dps + ring.dps | ✓ Good -- uses hero-level crit, more accurate |
| DPS comparison for weapon/ring drops | is_item_better() uses DPS for damage slots, tier for defense slots | ✓ Good -- evaluates actual damage output |
| update_stats() order: crit -> ranges -> dps -> defense | Ensures crit stats available for DPS calculation, ranges available for DPS average | ✓ Good -- correct dependency order |

---
*Last updated: 2026-02-18 after Phase 24*
