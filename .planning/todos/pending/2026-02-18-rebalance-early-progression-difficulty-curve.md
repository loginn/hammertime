---
created: 2026-02-18T13:17:00.000Z
title: Rebalance early progression difficulty curve
area: general
files:
  - models/loot/loot_table.gd
  - models/monsters/pack_generator.gd
  - models/monsters/biome_config.gd
  - autoloads/game_state.gd
---

## Problem

Game scales too hard too early. Players hit a wall before they can get meaningful gear upgrades. Rare items come too late in progression — by the time players can drop or craft them, the difficulty has already outpaced their gear. This makes the mid-game feel punishing rather than rewarding.

## Solution

Two potential approaches (possibly both):

1. **Earlier access to rare items** — adjust rarity drop weights or currency gating so players can obtain rare-tier items sooner, either through lucky drops or through currency crafting (e.g., lower the area gate for Runic/Forge hammers, or increase rare drop weight in early areas)

2. **Shorter areas (~30 levels instead of current scaling)** — reduce the number of levels per biome so players reach the next biome (and its loot tier) faster, compressing the progression curve

Need to playtest both approaches. Could also combine: shorter areas + slightly earlier rare access for a smoother power curve.
