# Hammertime

## What This Is

An ARPG-style crafting idle game built in Godot 4.5. Players send a hero to clear areas across 4 biomes (Forest → Shadow Realm), collect item bases and crafting hammers, then use those hammers to craft and equip gear. Better gear lets the hero clear harder areas, which drops better and more plentiful loot. Items come in Normal, Magic, and Rare tiers with defensive and offensive affixes, each craftable with 6 themed hammers that add, remove, or reroll mods.

## Core Value

The crafting loop must feel rewarding — finding items, using hammers to shape them, and equipping the result to push further into harder content.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

- Hero system with 5 equipment slots (weapon, helmet, armor, boots, ring)
- Item system with implicits, prefixes (up to 3), suffixes (up to 3), tier-based scaling
- Affix system with 9 prefix types and 15 suffix types, tag-based filtering
- Gameplay loop: clear areas, take damage, find item bases + hammers
- Area progression with difficulty scaling (Forest, Dark Forest, Cursed Woods, Shadow Realm)
- 5 item types with base classes (Weapon, Helmet, Armor, Boots, Ring)
- UI with Hero View (equipment/stats), Crafting View (hammers/inventory), Gameplay View (clearing)
- Code organization with feature-based folder structure (models/, scenes/, autoloads/, utils/) -- v0.1
- Signal-based UI communication following call-down/signal-up pattern -- v0.1
- Unified stat calculation system (StatCalculator) across all item types -- v0.1
- Tag system separation: AffixTag for filtering, StatType for damage routing -- v0.1
- Item rarity tiers (Normal/Magic/Rare) with configurable affix limits -- v1.0
- 6 crafting hammers with rarity-aware validation (Runic, Forge, Tack, Grand, Claw, Tuning) -- v1.0
- Area difficulty influences rarity drop weights -- v1.0
- 6 currency buttons replacing old 3-hammer system with select-and-click application -- v1.0
- Currency consumed only on successful application -- v1.0
- 9 defensive prefix affixes for non-weapon items (flat/% armor, evasion, energy shield, health, mana) -- v1.1
- Defensive prefixes use tag-based filtering (Tag.DEFENSE) -- v1.1
- StatCalculator handles defensive stat types with flat + percentage stacking -- v1.1
- Hero View shows separate Offense and Defense sections with non-zero filtering -- v1.1
- Individual fire/cold/lightning resistance suffixes replacing generic Elemental Reduction -- v1.1
- All-resistance suffix with narrower tier range for rarity balance -- v1.1
- Currency area gating: hard gates at 1/100/200/300 with linear ramping -- v1.1
- Logarithmic rarity interpolation with multi-item drops (1→4-5 items/clear) -- v1.1
- Advanced currencies (Grand, Claw, Tuning) significantly rarer than basic -- v1.1
- Runic Hammer 70/30 mod bias making TackHammer meaningful -- v1.1
- Implicit stat_types architecture: base stats flow through StatCalculator, not hardcoded -- v1.1

### Active

<!-- Current scope. Building toward these. -->

## Current Milestone: v1.2 Pack-Based Mapping

**Goal:** Replace time-based area clearing with pack-based map runs, adding real combat stakes and defensive stat integration.

**Target features:**
- Monster packs with HP, damage, and elemental damage types (physical/fire/cold/lightning)
- Sequential idle combat — hero auto-attacks packs, packs hit back, hero can die
- Death mechanic — lose map progress, keep earned currency from killed packs
- Random pack count per biome within a range
- Drop split — packs drop currency, map completion drops items
- Biome damage distributions (Forest = mostly physical, later biomes = more elemental)
- Defensive combat calculations — armor, evasion, energy shield, and resistances actually reduce incoming damage

### Out of Scope

- Unique items -- defer to future milestone
- Item melting/salvage system -- future feature
- Chaos-style full reroll -- deliberate design choice: no full rerolls, craft carefully or equip as-is
- Drag-and-drop crafting UI -- select-and-click is sufficient
- Save/load system -- Resource model enables it, but not yet scoped
- Defensive combat calculations -- now in scope for v1.2 (pack-based mapping)
- Hybrid defense prefixes (armor+evasion single-slot) -- v1.3+ scope
- Visual prefix/suffix separation in UI (color-coded or sectioned) -- v1.3+ scope
- Totem system (forge god shrine with slottable pieces, favor mechanic, map modifiers) -- v1.3+ scope, builds on pack-based mapping

## Context

- Built with Godot 4.5 (GDScript), targeting mobile renderer
- 3,161 LOC GDScript across ~30 files
- Feature-based folder structure: models/, scenes/, autoloads/, utils/, tools/
- Autoloads: ItemAffixes, Tag, GameState (Hero singleton + currency inventory), GameEvents (event bus)
- Scene structure: main.tscn with main_view coordinating hero_view, crafting_view, gameplay_view via signals
- StatCalculator handles all DPS/defense calculations with flat + percentage stacking
- All data classes extend Resource (Item, Affix, Implicit, Hero, Currency)
- Currency system uses template method pattern (base Currency.apply() with _do_apply() overrides)
- LootTable provides logarithmic rarity-weighted drop generation with multi-item drops and currency area gating
- Drop simulator (tools/drop_simulator.gd) validates currency gating, rarity distribution, and item quantity
- Implicit stat_types flow: all item base stats derive from implicits through StatCalculator (no hardcoded bases)
- 18 prefix types (9 offensive + 9 defensive) and 19 suffix types (15 original + 4 resistance)

## Constraints

- **Tech stack**: Godot 4.5, GDScript only
- **Platform**: Mobile target renderer, 1200x700 viewport
- **Architecture**: Feature-based folders, signal-based communication, Resource-based data model

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Hammers, not orbs | Game is called Hammertime -- all currencies are hammers | Good -- thematic consistency |
| No chaos/full reroll | Forces deliberate crafting -- you commit to items or melt them later | Good -- each hammer strike matters |
| PoE-style rarity tiers | Normal/Magic/Rare maps cleanly to affix count limits | Good -- clean system, intuitive |
| Select-and-click UI | Same flow as current hammers, minimal UI rework | Good -- shipped in 1 plan |
| Code cleanup before v1.0 | Clean foundation prevents compounding tech debt across crafting overhaul | Good -- v0.1 shipped clean in 2 days |
| Resource over Node for data | Enables serialization, reference counting, no scene tree dependency | Good -- cleaner data model |
| GameState/GameEvents autoloads | Single source of truth for hero, event bus for cross-scene signals | Good -- eliminated duplicate Hero instances |
| StatCalculator singleton | One calculation source replaces duplicate DPS logic in weapon/ring | Good -- fixed crit formula bug, removed 96 lines |
| Signal-based parent coordination | main_view connects child signals to sibling methods instead of get_node() | Good -- zero sibling coupling |
| Template method for Currency | Base apply() enforces validation/consumption flow, subclasses override _do_apply() | Good -- impossible to forget validation |
| Dictionary-based rarity limits | RARITY_LIMITS dict over match statement for configuration flexibility | Good -- easy to add tiers later |
| Independent currency drop chances | Each hammer type rolls independently, not mutually exclusive | Good -- richer rewards in harder areas |
| Tag.DEFENSE for defensive affixes | Single tag enables both defensive prefixes and resistance suffixes on appropriate items | Good -- clean extension point |
| Vector2i tier ranges | Configurable per-affix tier ranges (30 for defensive vs 8 for weapon) | Good -- backward compatible |
| Implicit stat_types as sole base stat source | Removed hardcoded base_armor, implicits flow through StatCalculator | Good -- intuitive stat math |
| 70/30 Runic Hammer mod bias | TackHammer meaningful on 70% of items instead of 50% | Good -- better currency design |
| Hard currency gating by area | Clearer progression than pure RNG, prevents early-game clutter | Good -- meaningful gates |
| Logarithmic rarity interpolation | Smooth progression between 4 anchor points, no discrete jumps | Good -- natural feeling |
| Multi-item drops at high areas | Endgame loot shower (4-5 items) compensates per-roll rare scarcity | Good -- rewarding endgame |

---
*Last updated: 2026-02-16 after v1.2 milestone started*
