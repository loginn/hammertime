# M001: Core Crafting Loop

## Goal

Prove the core loop is fun: craft an item → equip hero → send on expedition → get materials + hammers → craft better → repeat. First prestige trigger closes the loop.

## What Ships

### Crafting System — 7 Currency Types

| Verb | Hammer | Effect |
|------|--------|--------|
| Transmute | Tack Hammer | Normal → Magic (1-2 affixes) |
| Alteration | Tuning Hammer | Reroll affixes on Magic item |
| Augment | Forge Hammer | Add affix to Magic item (not full) |
| Regal | Grand Hammer | Magic → Rare (add 1+ affix) |
| Exalt | Runic Hammer | Add affix to Rare item (not full) |
| Scour | *New hammer TBD* | Rare/Magic → Normal (strip all) |
| Annul | Claw Hammer | Remove random affix |

### Material Tiers — 2 Tiers

- **Iron** — affix tiers 32-29 (lowest ceiling)
- **Steel** — affix tiers 28-25 (higher ceiling)

Material tier gates the maximum affix tier that can roll, not the affix pool itself. All affixes are available at both tiers; only the roll ceiling differs.

### Base Items — 1 per slot per tier (10 total)

| Slot | Iron Base | Steel Base |
|------|-----------|------------|
| Weapon | Iron Shortsword | Steel Longsword |
| Armor | Iron Vest | Steel Chainmail |
| Helmet | Iron Cap | Steel Helm |
| Boots | Iron Sandals | Steel Greaves |
| Ring | Iron Band | Steel Signet |

Base stats scale with material tier. More bases per tier are future content.

### Item Slots

Weapon, Armor, Helmet, Boots, Ring (5 total). All ship in M001.

### Affix Pool

Use existing affix definitions from v1 codebase. No new affixes designed for M001 — tune numbers only.

### Expeditions — 2 Expeditions

- **Expedition 1: Iron Quarry** — difficulty 1, ~10s with no gear, drops iron bases + basic hammers (Tack, Tuning, Forge)
- **Expedition 2: Steel Depths** — difficulty 3, ~38s with no gear, drops steel bases + multiplied lower-tier hammers + rarer hammers (Grand, Runic, Claw)

Expeditions always succeed. Duration compresses with hero gear quality — a well-geared hero finishes dramatically faster. Undergeared hero on a hard expedition takes days (time is the disincentive, not failure).

Duration formula: `base_time / (1 + hero_power * scaling_factor)`

### Hero

Single hero. Equippable with items across all 5 slots. Stat aggregation from equipped items determines expedition performance (time compression). Hero persists across prestige.

### Prestige

- **Trigger:** Spend 100 Tack Hammers
- **Reward:** 999 of every hammer type
- **Resets:** Currency inventory, crafted items, expedition progress
- **Persists:** Hero (with equipped items stripped), unlocked state

This is MVP prestige — no unlock tree, no totem, no forge upgrades. Just enough to prove the reset-and-accelerate loop feels good.

### UI — 2 Screens

1. **Forge Screen** (craft + equip + inventory combined)
   - Hammer rail (left): 4×grid of 7 hammers + expansion slot, category tabs
   - Bench + inventory (center): item on bench with prefix/suffix rails, slot-tabbed inventory grid, "Forge New Base" button, "Melt" to destroy items
   - Hero panel (right): portrait + 5 equip slots + stat summary with expedition time estimates

2. **Expedition Screen**
   - 2 expedition cards with difficulty, estimated time, reward preview
   - Send/recall hero, progress bar, collect rewards

3. **Prestige Screen** — sacrifice panel, progress gauge (X/100 Tack Hammers), reward preview

4. **Settings Screen** — minimal, future save/load placeholder

### Debug System

Debug mode that grants 999 of every resource for testing. Accessible from settings or a dev shortcut.

### What's NOT in M001

- Save/load system (removed entirely until all milestones complete)
- Totem crafting
- Forge upgrades (batch crafting, keep-best)
- Advanced crafting verbs gated behind prestige
- New expedition types from prestige
- Multiple heroes
- Hero XP
- Onboarding/tutorial
- Themed expeditions (fire/cold resistance requirements)
- Item tooltip / stats ledger / achievements

## Codebase Strategy

**Keep:** StatCalculator, DefenseCalculator, affix system (item_affixes.gd), hero stat aggregation pattern, signal bus (game_events.gd), Resource-based item model, Tag system.

**Replace:** CombatEngine → Expedition resolver. All biome/loot/monster systems → expedition + reward tables.

**Fix in foundation:**
- Damage type strings → typed enums
- Hardcoded balance constants → single config resource
- Item computed stats → validated before read

**Remove:** SaveManager (entirely), old biome/monster/loot systems, old UI scenes.

**Rework:** Currency classes remapped to 7 new verbs. Item base classes replaced with data-driven ItemBase resource (slot, base_name, material_tier, base_stats, valid_tags, implicit).

## Success Criteria

A player can:
1. Start the game, see the forge screen
2. Pick a base item and apply hammers to craft it
3. Equip crafted items on the hero
4. Send the hero on either expedition
5. Collect materials and hammers from completed expeditions
6. Use expedition rewards to craft better items
7. Accumulate 100 Tack Hammers and trigger prestige
8. Receive 999 hammers and start the cycle again, noticeably faster
9. Feel like they want to do another cycle
