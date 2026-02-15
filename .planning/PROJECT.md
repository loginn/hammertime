# Hammertime

## What This Is

An ARPG-style crafting idle game built in Godot 4.5. Players send a hero to clear areas, collect item bases and crafting hammers, then use those hammers to craft and equip gear. Better gear lets the hero clear harder areas, which drops better loot. Items come in Normal, Magic, and Rare tiers, each craftable with 6 themed hammers that add, remove, or reroll mods.

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

### Active

<!-- Current scope. Building toward these. -->

**Current Milestone: v1.1 Content & Balance**

**Goal:** Make all equipment slots meaningful through defensive prefixes, expand the affix pool, and tune drop/currency progression so rewards scale with area difficulty.

**Target features:**
- Defensive prefix affixes for non-weapon items (armor, evasion, block chance for helmet/armor/boots/ring)
- New suffix types to expand affix variety beyond current 15
- Currency area gating: hard gate preventing rare hammers from dropping before specific areas, with low initial drop chance ramping up
- Drop rate rebalancing: rare items harder to find, advanced currencies rarer overall

**Note:** Defensive stats will appear on items but combat damage reduction is deferred to a future mapping/combat milestone.

### Out of Scope

- Unique items -- defer to future milestone
- Item melting/salvage system -- future feature
- Chaos-style full reroll -- deliberate design choice: no full rerolls, craft carefully or equip as-is
- Drag-and-drop crafting UI -- select-and-click is sufficient
- Save/load system -- Resource model enables it, but not yet scoped
- Defensive combat calculations -- stats exist on items but damage reduction deferred to mapping milestone

## Context

- Built with Godot 4.5 (GDScript), targeting mobile renderer
- 2,488 LOC GDScript across ~25 files
- Feature-based folder structure: models/, scenes/, autoloads/, utils/
- Autoloads: ItemAffixes, Tag, GameState (Hero singleton + currency inventory), GameEvents (event bus)
- Scene structure: main.tscn with main_view coordinating hero_view, crafting_view, gameplay_view via signals
- StatCalculator handles all DPS/defense calculations with weighted-average crit formula
- All data classes extend Resource (Item, Affix, Implicit, Hero, Currency)
- Currency system uses template method pattern (base Currency.apply() with _do_apply() overrides)
- LootTable provides static rarity-weighted drop generation per area difficulty
- Known gap: non-weapon items (helmet, armor, boots, ring) have no prefix affixes -- all prefixes require Tag.WEAPON

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

---
*Last updated: 2026-02-15 after v1.1 milestone start*
