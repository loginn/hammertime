---
created: 2026-02-18T13:48:00.000Z
title: Add prestige meta-progression system
area: general
files:
  - autoloads/game_state.gd
  - models/combat/combat_engine.gd
  - autoloads/save_manager.gd
---

## Problem

Once the difficulty curve outpaces gear progression, players hit a permanent wall with no meaningful path forward. The game lacks a long-term loop beyond the initial biome progression. There's no reason to start over and no sense of permanent growth across runs.

## Solution

Add a prestige/reset system as the core meta-progression loop:

**Trigger:** When progression stalls, player spends currency to prestige (voluntary reset).

**What happens on prestige:**
- All gear and currency wiped, area progress reset to 0
- Player earns prestige points based on progress achieved
- Player chooses from 3 character classes (e.g., Assassin, Sorcerer, Warrior) — each with different base stats, implicit bonuses, or affix pool weightings
- New run starts with more powerful base capabilities

**Prestige point spending:**
- Permanent upgrades that persist across prestiges (e.g., +% damage, +% drop rate, starting currency, unlocked hammer tiers)
- Prestige talent tree or simple upgrade shop

**Design considerations:**
- How many prestiges before the system feels complete?
- Should character choice be permanent per prestige or permanent forever?
- Should some currencies be prestige-proof (rare prestige currency)?
- Save format needs prestige layer (prestige_level, prestige_points, character_class, permanent_upgrades)
- This is a large feature — likely its own milestone with multiple phases
