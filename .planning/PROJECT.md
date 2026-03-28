# Hammertime

## What This Is

An ARPG-style crafting idle game built in Godot 4.5. Players send a hero to fight monster packs across 4 biomes (Forest → Shadow Realm), collect item bases and crafting hammers, then use those hammers to craft and equip gear. Better gear lets the hero survive harder packs, which drop better and more plentiful loot. 21 item base types across 5 equipment slots support 3 archetypes (STR/DEX/INT) with archetype-specific affix pools. Items come in Normal, Magic, and Rare tiers with 41 active affixes across 32 affix tiers, craftable with 11 themed hammers (6 base + 5 tag-targeted). Dual damage channels (attack + spell) with independent combat timers and damage over time (bleed/poison/burn) create distinct playstyles. A prestige system lets players reset progress to unlock better item tiers (1-8) and tag-targeted crafting currencies. Combat is pack-based idle auto-combat with death mechanics, defensive stat integration, DoT tick processing, and floating damage feedback. Game state persists via JSON save/load (format v8) with auto-save and export/import strings. Hero archetype selection persists across saves and resets on prestige.

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
- ✓ Weapon base damage ranges (min-max per weapon type) with computed average getter -- v1.4
- ✓ Flat damage affix ranges with element-specific variance (Physical tight, Lightning extreme) -- v1.4
- ✓ Monster pack damage ranges with element variance constants -- v1.4
- ✓ Dual-accumulator per-element damage range tracking in StatCalculator -- v1.4
- ✓ Hero range caching with range-based DPS formula -- v1.4
- ✓ Per-element hero damage rolling and per-hit pack rolling in CombatEngine -- v1.4
- ✓ Weapon tooltip "Damage: X to Y" and affix "Adds X to Y [Element] Damage" display -- v1.4
- ✓ Pack name and element type shown in gameplay view during combat -- v1.4
- ✓ DPS-based item comparison for weapon/ring slots -- v1.4
- ✓ Per-slot inventory arrays (10 items each) for all 5 equipment slots -- v1.5
- ✓ Save format v2 with per-slot arrays and v1-to-v2 migration -- v1.5
- ✓ Single add point (add_item_to_inventory) with 10-item cap enforcement -- v1.5
- ✓ Best-item bench selection using tier comparison across all slot types -- v1.5
- ✓ Melt removes from slot array, equip moves to hero (old item deleted) -- v1.5
- ✓ x/10 slot counter with auto-updating on drop/melt/equip -- v1.5
- ✓ Empty slot buttons disabled, crafting_bench_item removed from GameState -- v1.5
- ✓ Temporary Godot editor files (.tmp) removed from git tracking -- v1.6
- ✓ .gitignore updated with *.tmp pattern -- v1.6
- ✓ Biome boundaries compressed to ~25 levels each (Forest 1-24, Dark Forest 25-49, Cursed Woods 50-74, Shadow Realm 75+) -- v1.6
- ✓ Difficulty growth rate retuned to 7% compounding with boss wall/relief/ramp-back curve -- v1.6
- ✓ Currency area gates moved to biome boundaries (forge 25, grand 50, claw/tuning 75) with 12-level sqrt ramp -- v1.6
- ✓ All items drop at Normal rarity (0 affixes) — crafting is sole source of item mods -- v1.6
- ✓ Per-pack item drops at 18% chance replacing map completion drops -- v1.6
- ✓ Hero health/armor double-counting fixed (FLAT_HEALTH/FLAT_ARMOR suffix split) -- v1.6
- ✓ Preview currency drops from next biome (gates shifted 10 levels before boundaries) -- v1.6

- ✓ Prestige system with 7 levels, currency-cost gating, full run-state reset preserving meta-progression — v1.7
- ✓ Save format v4 with prestige field persistence and auto-save on prestige — v1.7
- ✓ Affix tier expansion from 8 to 32 tiers with retuned base values — v1.7
- ✓ Item tier system (1-8) with area-weighted drops and affix tier floor constraints — v1.7
- ✓ 5 tag-targeted hammers (Fire, Cold, Lightning, Defense, Physical) with prestige-gated visibility — v1.7
- ✓ Prestige UI with 7-level unlock table, two-click confirmation, fade transition, dynamic tab reveal — v1.7
- ✓ 50-test integration verification suite for prestige loop, save round-trips, and regression checks — v1.7

- ✓ 21 item base types (9 weapons + 12 armor/helmet/boots/ring) across STR/DEX/INT archetypes — v1.8
- ✓ Single crafting bench per slot replacing 10-item arrays — v1.8
- ✓ Spell damage channel with StatCalculator, Hero tracking, and CombatEngine spell timer — v1.8
- ✓ 14 new affixes (spell damage, cast speed, bleed/poison/burn chance and damage) — v1.8
- ✓ Damage over time system (bleed/poison/burn) with tick processing and defense interaction — v1.8
- ✓ Archetype-specific affix pools via valid_tags on item bases — v1.8
- ✓ Save format v7 with 21-type serialization registry — v1.8
- ✓ 35-group integration test suite (up from 28 at v1.7) — v1.8
- ✓ HeroArchetype Resource with 9-hero REGISTRY (3 STR, 3 DEX, 3 INT), passive bonus dictionaries, generate_choices() — v1.9
- ✓ Archetype passive bonuses wired into Hero.update_stats() as multiplicative "more" modifiers; is_spell_user derived from archetype — v1.9
- ✓ Save format v8 with hero_archetype_id persistence; prestige wipe nulls archetype — v1.9
- ✓ 3-card hero selection overlay after prestige (P1+) with BONUS_LABELS display, colored borders, single-click selection — v1.9
- ✓ ForgeView stat panel shows hero title in archetype color with "Passive:" bonus section — v1.9

- ✓ 3-slot stash per equipment type (15 total) replacing per-slot inventory arrays — v1.10
- ✓ Single universal crafting bench replacing per-type bench switching — v1.10
- ✓ Item drops route to stash via GameState.add_item_to_stash() with silent overflow discard — v1.10
- ✓ stash_updated signal on GameEvents for UI reactivity — v1.10
- ✓ Prestige wipes stash and bench via _wipe_run_state() — v1.10
- ✓ Integration test groups 40-41 covering stash data model and drop routing — v1.10

- ✓ Currency keys renamed to PoE conventions (transmute, augment, alteration, regal, chaos, exalt) — v1.10
- ✓ Archetype-matched starter items in stash (weapon + armor) for fresh games and post-prestige — v1.10
- ✓ Starter currency loadout: 2 Transmute + 2 Augment replacing 1 Runic — v1.10
- ✓ Forest difficulty tuned (~50% HP/damage reduction) for zone 1 survivability with blank starter gear — v1.10
- ✓ _place_starter_kit() with archetype-aware item selection, wired into init and prestige callback — v1.10
- ✓ Integration test groups 42-44 covering Forest difficulty, fresh-game starter kit, post-prestige starter kit — v1.10

## Current Milestone: v1.10 Early Game Rebalance

**Goal:** Make the early crafting loop feel rewarding from zone 1 — more base drops, a small stash to work with, new hammers for iterating on gear, and tuned difficulty so fresh heroes can engage with the systems.

**Target features:**
- Early difficulty tuning — reduce Forest pack HP and damage so fresh P0 heroes survive with starter gear
- 3-slot stash per equipment type — small inventory buffer with letter-icon UI (W for wand, S for sword, etc.), one-way move to bench
- Alteration Hammer — reroll all mods at current rarity, enabling iteration on Magic items
- Regal Hammer — upgrade Magic → Rare, completing the early crafting arc (transmute → alt → regal)

### Active

<!-- Current scope. Building toward these. -->

(Requirements defined in REQUIREMENTS.md)

### Out of Scope

- Unique items -- defer to future milestone
- Item melting/salvage system -- future feature
- Chaos-style full reroll -- deliberate design choice: no full rerolls, craft carefully or equip as-is
- Drag-and-drop crafting UI -- select-and-click is sufficient
- Hybrid defense prefixes (armor+evasion single-slot) -- future scope
- Visual prefix/suffix separation in UI (color-coded or sectioned) -- future scope
- Totem system (forge god shrine with slottable pieces, favor mechanic, map modifiers) -- future scope, builds on pack-based mapping
- Hero archetypes beyond passive bonuses (active abilities, attack pattern changes) -- future milestone
- Loot filtering system -- future milestone
- Totem progression system -- future milestone
- Stat-targeted hammers (add specific stat type affixes) -- future prestige unlock
- Outcome locking hammers (protect existing mods while rerolling) -- future prestige unlock
- Real-time combat with player timing -- fundamentally conflicts with idle genre
- Per-monster loot drops -- item explosion in idle game = inventory nightmare
- 100% damage immunity -- removes challenge; 75% resistance cap is ARPG standard

## Context

- Built with Godot 4.5 (GDScript), targeting mobile renderer
- 14,375 LOC GDScript across ~70 files
- Feature-based folder structure: models/, scenes/, autoloads/, utils/, tools/
- Autoloads: ItemAffixes, Tag, GameState, GameEvents, SaveManager, PrestigeManager
- Scene structure: main.tscn with main_view coordinating forge_view, gameplay_view, prestige_view, settings_view via 4-tab bar; hero selection overlay on OverlayLayer post-prestige
- ForgeView combines hero equipment (left) and single universal crafting bench (right) with tag hammer section (P1+); stash UI pending Phase 57
- Currency keys use PoE conventions: transmute, augment, alteration, regal, chaos, exalt
- Fresh games and prestige resets provide archetype-matched starter items (weapon + armor) in stash via _place_starter_kit()
- StatCalculator handles all DPS/defense calculations including spell damage and DoT DPS with flat + percentage stacking
- DefenseCalculator handles all incoming damage with 4-stage pipeline; DoT uses resistance-only path
- All data classes extend Resource (Item, Affix, Implicit, Hero, Currency, TagHammer, MonsterType, MonsterPack, BiomeConfig)
- 21 item base types across 5 slots with STR/DEX/INT archetype identity via valid_tags
- Currency system uses template method pattern (base Currency.apply() with _do_apply() overrides); TagHammer extends Currency
- LootTable provides per-pack currency drops, item drops with slot-first distribution, and tag currency drops (P1+) with area scaling
- CombatEngine manages pack-by-pack combat with state machine lifecycle, dual attack timers, spell timer, and DoT tick processing
- PrestigeManager handles 7 prestige levels with currency-cost gating and full run-state wipe
- SaveManager handles JSON save/load (format v8), auto-save timer, event triggers, prestige auto-save, Base64 export/import, and strict version rejection on imports
- 41 active affixes with Vector2i(1, 32) tier ranges; item tiers 1-8 constrain affix tier floor at crafting time
- 44-group integration test suite (up from 41 at Phase 55)
- Shipped 11 milestones: v0.1 (architecture), v1.0 (crafting), v1.1 (content/balance), v1.2 (combat), v1.3 (save/load & polish), v1.4 (damage ranges), v1.5 (inventory rework), v1.6 (tech debt cleanup), v1.7 (meta-progression), v1.8 (content pass), v1.9 (heroes)

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
| Tier comparison for all item drops | is_item_better() uses tier for all slot types (changed from DPS in UAT) | ✓ Good -- consistent, simple comparison |
| update_stats() order: crit -> ranges -> dps -> defense | Ensures crit stats available for DPS calculation, ranges available for DPS average | ✓ Good -- correct dependency order |
| Per-element hero rolling with crit on total | Roll each element independently, sum, then crit; matches ARPG expected-value math | ✓ Good -- natural per-hit variance |
| Pack per-hit rolling from damage_min/max | randf_range(min, max) replaces flat average; lightning naturally wider than physical | ✓ Good -- element identity in combat |
| Weapon tooltip "Damage: X to Y" format | Replaces "Base Damage: N"; shows actual min/max range from base_damage_min/max | ✓ Good -- players see damage variance |
| _format_affix_line() helper for flat damage | Flat damage affixes show "Adds X to Y [Element] Damage"; element from tags; others unchanged | ✓ Good -- clean display, single helper |
| Pack HP label with name and element | "PackName (Element) -- HP/MaxHP" in gameplay view; no new UI nodes needed | ✓ Good -- combat context at a glance |
| Stat comparison shows damage ranges | Weapons show "Damage: X-Y (was X-Y)" instead of single-value delta | ✓ Good -- meaningful comparison for ranged damage |
| Per-slot inventory arrays | crafting_inventory changes from {slot: Item} to {slot: Array} with 10-item cap | ✓ Good -- enables multi-item stash per slot |
| Single add point enforcement | All inventory mutations go through add_item_to_inventory() with cap check | ✓ Good -- single enforcement point prevents overflow bugs |
| Starter weapon in GameState | initialize_fresh_game() creates starter weapon; ForgeView no longer creates one | ✓ Good -- centralized initialization |
| Drop all items (no is_item_better gate) | Removed DPS/tier gating from drop path; all items kept until slot full | ✓ Good -- players choose which item to craft on |
| Save format v2 with migration chain | Version-gated _migrate_save() routes through per-version functions | ✓ Good -- extensible for future versions |
| Bridge pattern for save format transition | Phase 27 save writes arrays while GameState still held singles; Phase 28 completed transition | ✓ Good -- incremental migration |
| crafting_bench_item removed from GameState | Bench item is ForgeView-local concept, not persisted | ✓ Good -- simpler state model |
| get_best_item() on ForgeView | Best-item selection lives near is_item_better() for locality | ✓ Good -- cohesive code organization |
| Bench clears after equip | Equipping does not auto-select next item; bench goes empty | ✓ Good -- UAT feedback, clearer UX |
| update_slot_button_labels() via update_inventory_display() | Central sync point for all counter updates | ✓ Good -- single call chain for all mutations |
| Biomes compressed 4x (25-level spans) | Tighter biomes = faster progression feel, less grinding per biome | ✓ Good -- meaningful biome transitions |
| GROWTH_RATE 0.07 with boss walls | 10% was too steep; 7% + softer boss walls (+10/20/40%) allows zone 25+ progression | ✓ Good -- playable difficulty curve |
| Currency gates at biome boundaries (25/50/75) | Aligns currency unlocks with biome transitions for natural progression | ✓ Good -- currencies feel like biome rewards |
| Sqrt ramp for currency unlock | Immediate-but-low drop rate at unlock, full rate after 12 levels | ✓ Good -- players see new currency quickly |
| Normal-only item drops | Crafting is sole source of mods; items drop as blank bases | ✓ Good -- reinforces crafting loop |
| Per-pack item drops (18% chance) | Items drop during combat, not just on map completion | ✓ Good -- more frequent reward moments |
| FLAT_HEALTH/FLAT_ARMOR suffix split | Weapon/ring get suffix treatment; armor slots bake via update_value() | ✓ Good -- fixed double-counting |
| Currency preview via 10-level gate shift | Forge at 15, Grand at 40, Claw/Tuning at 65; reuses existing sqrt ramp | ✓ Good -- minimal code change, thematic teasers |

| Prestige full-reset design | Wipe all run state (area, gear, inventory, currencies) but preserve prestige_level and max_item_tier_unlocked | ✓ Good -- clean emotional arc, meaningful progression |
| Delete-on-old-version saves | v2/v3 saves deleted on load instead of migrating; breaking old saves acceptable | ✓ Good -- eliminated migration code complexity |
| 32 affix tiers (4 per item tier) | Uniform Vector2i(1,32) range enables consistent cross-tier comparison | ✓ Good -- granular progression visible to player |
| Affix tier floor at construction | from_affix() constrains range, not stored on item; reroll untouched | ✓ Good -- clean implementation, tuning hammer works correctly |
| TagHammer parameterized class | Single class handles all 5 tag types via required_tag parameter | ✓ Good -- no code duplication |
| Gaussian bell-curve tier drops | Area-weighted distribution centered on biome-aligned home areas | ✓ Good -- natural feeling drop distribution |
| Manual prestige simulation in tests | _simulate_prestige() avoids execute_prestige() signal triggering auto-save | ✓ Good -- test isolation without touching real saves |
| Two-click prestige confirmation | First click shows "Reset progress?", 3-second timer reset, second click executes | ✓ Good -- non-intrusive safety, matches forge equip pattern |
| Dynamic prestige tab reveal | Tab appears when can_prestige() first returns true, stays permanently | ✓ Good -- discovery moment without cluttering P0 UI |

| Single bench per slot (no arrays) | Simplifies item path before 21-base proliferation; forces deliberate crafting | ✓ Good -- cleaner UX, simpler saves |
| valid_tags on item bases | Archetype identity constrains affix pools without class system | ✓ Good -- emergent build diversity |
| Spell timer as third independent CombatEngine timer | Spell and attack channels fire independently at different speeds | ✓ Good -- distinct INT playstyle |
| DoT resistance-only defense path | DoT bypasses evasion and armor; bleed bypasses all resistance (PoE convention) | ✓ Good -- DoT has clear identity |
| LOOT-03/LOOT-04 dropped by design | Tier-only comparison stays; item names self-document archetype | ✓ Good -- avoided unnecessary complexity |
| DoT multi-stack on packs, single-stack on hero | Hero refreshes DoT (simpler), packs stack per source (rewards investment) | ✓ Good -- balanced risk/reward |
| Slot-first then archetype drop distribution | 20% per slot, uniform within slot; prevents weapon flooding | ✓ Good -- fair distribution |

| Stash replaces per-slot inventory | 3-slot stash per equipment type (15 total) with single universal bench; drops go to stash, player chooses bench item | ✓ Good -- deliberate crafting, clear item flow |
| Silent overflow discard | Stash full → new item silently discarded (no toast); smart discard deferred as prestige unlock | ✓ Good -- no combat noise, future design space |
| Save-manager compat shims | crafting_inventory/crafting_bench_type kept as computed properties for save_manager v8; removed in Phase 58 | ✓ Good -- incremental migration |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-03-28 — Phase 57 (Stash UI) complete*
