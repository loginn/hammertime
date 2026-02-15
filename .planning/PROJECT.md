# Hammertime

## What This Is

An ARPG-style crafting idle game built in Godot 4.5. Players send a hero to clear areas, collect item bases and crafting hammers, then use those hammers to craft and equip gear. Better gear lets the hero clear harder areas, which drops better loot. The core fantasy is the satisfying crafting loop — every hammer strike could make or break an item.

## Core Value

The crafting loop must feel rewarding — finding items, using hammers to shape them, and equipping the result to push further into harder content.

## Current State

Shipped v0.1 Code Cleanup & Architecture. Codebase is clean, organized, and follows Godot 4.5 best practices. Ready for v1.0 Crafting Overhaul.

**Next milestone:** v1.0 Crafting Overhaul — replace basic hammer system with rarity tiers and 6 themed crafting hammers.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

- Hero system with 5 equipment slots (weapon, helmet, armor, boots, ring)
- Item system with implicits, prefixes (up to 3), suffixes (up to 3), tier-based scaling
- Affix system with 9 prefix types and 15 suffix types, tag-based filtering
- Hammer-based crafting (reroll implicit, add prefix, add suffix)
- Gameplay loop: clear areas, take damage, find item bases + hammers
- Area progression with difficulty scaling (Forest, Dark Forest, Cursed Woods, Shadow Realm)
- 5 item types with base classes (Weapon, Helmet, Armor, Boots, Ring)
- UI with Hero View (equipment/stats), Crafting View (hammers/inventory), Gameplay View (clearing)
- Code organization with feature-based folder structure (models/, scenes/, autoloads/, utils/) -- v0.1
- Signal-based UI communication following call-down/signal-up pattern -- v0.1
- Unified stat calculation system (StatCalculator) across all item types -- v0.1
- Tag system separation: AffixTag for filtering, StatType for damage routing -- v0.1

### Active

<!-- Current scope. Building toward these. -->

(None yet -- define with `/gsd:new-milestone`)

### Out of Scope

- Unique items -- defer to future milestone
- Item melting/salvage system -- mentioned as future feature
- Chaos-style full reroll -- deliberate design choice: no full rerolls, craft carefully or equip as-is
- Drag-and-drop crafting UI -- select-and-click is sufficient for now

## Context

- Built with Godot 4.5 (GDScript), targeting mobile renderer
- 1,953 LOC GDScript across 18 files
- Feature-based folder structure: models/, scenes/, autoloads/, utils/
- Autoloads: ItemAffixes, Tag, GameState (Hero singleton), GameEvents (event bus)
- Scene structure: main.tscn with main_view coordinating hero_view, crafting_view, gameplay_view via signals
- StatCalculator handles all DPS/defense calculations with weighted-average crit formula
- All data classes extend Resource (Item, Affix, Implicit, Hero)

## Constraints

- **Tech stack**: Godot 4.5, GDScript only
- **Platform**: Mobile target renderer, 1200x700 viewport
- **Architecture**: Feature-based folders, signal-based communication, Resource-based data model

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Hammers, not orbs | Game is called Hammertime -- all currencies are hammers | -- Pending |
| No chaos/full reroll | Forces deliberate crafting -- you commit to items or melt them later | -- Pending |
| PoE-style rarity tiers | Normal/Magic/Rare maps cleanly to affix count limits | -- Pending |
| Select-and-click UI | Same flow as current hammers, minimal UI rework | -- Pending |
| Code cleanup before v1.0 | Clean foundation prevents compounding tech debt across crafting overhaul | Good -- v0.1 shipped clean in 2 days |
| Resource over Node for data | Enables serialization, reference counting, no scene tree dependency | Good -- cleaner data model |
| GameState/GameEvents autoloads | Single source of truth for hero, event bus for cross-scene signals | Good -- eliminated duplicate Hero instances |
| StatCalculator singleton | One calculation source replaces duplicate DPS logic in weapon/ring | Good -- fixed crit formula bug, removed 96 lines of duplication |
| Signal-based parent coordination | main_view connects child signals to sibling methods instead of get_node() | Good -- zero sibling coupling, refactor-safe |
| @onready caching | Cache all node references at class level, eliminate repeated tree traversals | Good -- 33 cached refs, cleaner code |

---
*Last updated: 2026-02-15 after v0.1 milestone*
