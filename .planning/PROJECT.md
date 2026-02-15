# Hammertime

## What This Is

An ARPG-style crafting idle game built in Godot 4.5. Players send a hero to clear areas, collect item bases and crafting hammers, then use those hammers to craft and equip gear. Better gear lets the hero clear harder areas, which drops better loot. The core fantasy is the satisfying crafting loop — every hammer strike could make or break an item.

## Core Value

The crafting loop must feel rewarding — finding items, using hammers to shape them, and equipping the result to push further into harder content.

## Current Milestone: v1.0 Crafting Overhaul

**Goal:** Replace the basic 3-hammer system with a PoE-inspired rarity and currency system — Normal/Magic/Rare items crafted with 6 themed hammers, with area difficulty driving drop quality.

**Target features:**
- Item rarity tiers (Normal / Magic / Rare) with affix count limits
- 6 crafting hammers replacing the old 3 (Runic, Forge, Tack, Grand, Claw, Tuning)
- Area difficulty scaling affects item rarity drop weights
- New UI with 6 currency buttons, select-and-click application
- Full replacement of old implicit/prefix/suffix hammer system

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

- [ ] Item rarity tiers (Normal / Magic / Rare)
- [ ] 6 crafting hammers with rarity-aware validation
- [ ] Area difficulty influences rarity drop weights
- [ ] New crafting UI with 6 currency buttons
- [ ] Old 3-hammer system fully replaced

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
*Last updated: 2026-02-15 after v1.0 milestone start*
