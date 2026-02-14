# Hammertime

## What This Is

An ARPG-style crafting idle game built in Godot 4.5. Players send a hero to clear areas, collect item bases and crafting hammers, then use those hammers to craft and equip gear. Better gear lets the hero clear harder areas, which drops better loot. The core fantasy is the satisfying crafting loop — every hammer strike could make or break an item.

## Core Value

The crafting loop must feel rewarding — finding items, using hammers to shape them, and equipping the result to push further into harder content.

## Current Milestone: v1.0 Crafting Overhaul

**Goal:** Replace the basic hammer system with a PoE-inspired rarity and currency system, all themed around different types of hammers.

**Target features:**
- Item rarity tiers (Normal / Magic / Rare)
- 6 crafting hammers replacing the old 3 (Runic, Forge, Tack, Grand, Claw, Tuning)
- Area difficulty scaling affects item rarity drops
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

### Active

<!-- Current scope. Building toward these. -->

- [ ] Item rarity system (Normal / Magic / Rare)
- [ ] 6 new crafting hammers (Runic, Forge, Tack, Grand, Claw, Tuning)
- [ ] Rarity-aware drop system (harder areas = rarer drops)
- [ ] Replace old hammer system with new currency system
- [ ] UI update: currency buttons with select-and-click-to-apply flow

### Out of Scope

- Unique items — defer to future milestone
- Item melting/salvage system — mentioned as future feature
- Chaos-style full reroll — deliberate design choice: no full rerolls, craft carefully or equip as-is
- Drag-and-drop crafting UI — select-and-click is sufficient for now

## Context

- Built with Godot 4.5 (GDScript), targeting mobile renderer
- All scripts are flat in the project root (no folder structure)
- Autoloads: ItemAffixes (affix definitions), Tag (tag constants)
- Scene structure: main.tscn contains HeroView, CraftingView, GameplayView as sibling nodes
- Current hammer system uses 3 types (implicit, prefix, suffix) with limited counts that replenish from area clearing

## Constraints

- **Tech stack**: Godot 4.5, GDScript only
- **Platform**: Mobile target renderer, 1200x700 viewport
- **Architecture**: Flat file structure, no deep folder nesting

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Hammers, not orbs | Game is called Hammertime — all currencies are hammers | -- Pending |
| No chaos/full reroll | Forces deliberate crafting — you commit to items or melt them later | -- Pending |
| PoE-style rarity tiers | Normal/Magic/Rare maps cleanly to affix count limits | -- Pending |
| Select-and-click UI | Same flow as current hammers, minimal UI rework | -- Pending |

---
*Last updated: 2026-02-14 after milestone v1.0 definition*
