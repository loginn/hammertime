# M001 Roadmap: Core Crafting Loop

## Slices

- [ ] **S01: Foundation — typed enums, balance config, currency remap, item base rework** `risk:high` `depends:[]`
- [ ] **S02: Material tier system — iron/steel bases with affix ceiling gating** `risk:high` `depends:[S01]`
- [ ] **S03: Expedition resolver — stat-based timed completion engine** `risk:high` `depends:[S01]`
- [ ] **S04: Forge UI — unified craft + equip + inventory screen** `risk:medium` `depends:[S01, S02]`
- [ ] **S05: Expedition UI — send hero, timer, collect rewards** `risk:medium` `depends:[S03]`
- [ ] **S06: Expedition rewards — 2 expeditions with tiered drop tables** `risk:medium` `depends:[S03, S02]`
- [ ] **S07: Prestige — spend 100 tack hammers, reset cycle, receive 999 of each** `risk:low` `depends:[S04, S05]`
- [ ] **S08: Debug system + settings screen** `risk:low` `depends:[S04, S05]`

## Slice Details

### S01: Foundation

**Demo:** All 7 currency verbs apply correctly to items in code. Damage types are enums. Balance constants live in one config resource. Item bases are data-driven. SaveManager is removed.

**Tasks:**
- Replace damage/element type strings with typed enums (Tag system rework)
- Extract all hardcoded balance constants into a single BalanceConfig resource
- Add computed stat validation on hero item reads
- Remap existing currency classes to 7 new verbs (transmute, alteration, augment, regal, exalt, scour, annul)
- Create Scour hammer (new currency — strips all affixes)
- Replace class-per-item model with data-driven ItemBase resource
- Define 10 base items (1 per slot × 2 material tiers) as data
- Remove SaveManager and all save/load code
- Remove old biome, monster, loot table systems
- Remove old UI scenes

### S02: Material Tier System

**Demo:** Creating an iron base limits affix rolls to tiers 32-29. Steel base limits to tiers 28-25. Crafting on both tiers shows the ceiling difference in rolled affixes.

**Tasks:**
- Define MaterialTier resource (tier_id, name, min_affix_tier, max_affix_tier, base_stat_multiplier)
- Create Iron and Steel tier definitions
- Modify affix rolling pipeline to filter by material tier ceiling
- Wire base item creation to respect material tier constraints
- Verify affix tier gating works across all 7 currency verbs

### S03: Expedition Resolver

**Demo:** A hero can be sent on an expedition. Completion time compresses with better gear. Expedition completes and returns placeholder rewards. ~10s naked on expedition 1.

**Tasks:**
- Design Expedition resource (id, name, difficulty, base_time, reward_table_ref)
- Build expedition state machine (idle → in_progress → complete → collected)
- Implement hero power calculation from equipped item stats
- Implement time compression formula: `base_time / (1 + hero_power * scaling_factor)`
- Wire expedition completion to reward generation (placeholder rewards OK here)
- Add expedition signals to GameEvents bus
- Define 2 expedition instances (Iron Quarry, Steel Depths)

### S04: Forge UI

**Demo:** Player can select a base item, apply any hammer, see affixes change, equip items on hero, manage inventory, forge new bases, and melt unwanted items. Matches wireframe layout.

**Tasks:**
- Build Forge screen layout (3-column: hammer rail, bench+inventory, hero panel)
- Implement hammer rail (4×grid, 7 hammers + expansion slot, quantity display)
- Implement crafting bench (item display with prefix/suffix rails, apply hammer interaction)
- Implement inventory grid (slot-tabbed, shows all owned items)
- Implement hero equip panel (portrait + 5 slots + stat summary + expedition time estimate)
- Add "Forge New Base" flow (pick slot → pick material tier → create normal item)
- Add "Melt" / item destruction (remove item from inventory)
- Apply wireframe visual style (wood/iron/parchment palette from tokens.css)

### S05: Expedition UI

**Demo:** Player picks between 2 expeditions, sends hero, watches timer count down, collects materials and hammers on completion.

**Tasks:**
- Build Expedition screen layout (2 expedition cards)
- Display expedition info (difficulty, estimated time based on current hero gear, reward preview)
- Send hero button (with hero-busy mutual exclusion)
- Progress bar with real-time countdown
- Collect rewards interaction (adds to inventory/currency)
- Recall hero option

### S06: Expedition Rewards

**Demo:** Expedition 1 drops iron bases + basic hammers. Expedition 2 drops steel bases + multiplied/rarer hammers. The reward difference is visible and meaningful.

**Tasks:**
- Design reward table format (item type, quantity range, weight, tier filter)
- Build expedition 1 reward table (iron bases, Tack/Tuning/Forge hammers)
- Build expedition 2 reward table (steel bases, all hammer types weighted toward rarer, multiplied quantities)
- Wire reward tables to expedition resolver completion
- Tune drop rates so progression feels natural (enough hammers to craft, enough bases to experiment)

### S07: Prestige

**Demo:** Player accumulates 100 Tack Hammers, triggers prestige, receives 999 of every hammer, starts a new cycle with cleared items/expeditions but retained hero.

**Tasks:**
- Build Prestige screen (sacrifice panel, progress gauge, reward preview)
- Implement prestige trigger check (100 Tack Hammers in inventory)
- Implement prestige reset (clear: currency counts, crafted items, expedition state. keep: hero entity, base item definitions)
- Grant 999 of each hammer type on prestige
- Strip equipped items from hero on prestige
- Verify loop: post-prestige player can immediately craft and send expeditions again

### S08: Debug System + Settings

**Demo:** Developer can toggle debug mode to get 999 of every resource. Settings screen matches wireframe.

**Tasks:**
- Build debug panel (grant all resources, reset state, skip expedition timers)
- Wire debug toggle to settings or keyboard shortcut
- Build Settings screen (placeholder UI matching wireframe)
- Future-proof settings for save/load slots when that system returns

## Dependency Graph

```
S01 ─┬─→ S02 ─┬─→ S04 ─┬─→ S07
     │        │         │
     │        └─→ S06   ├─→ S08
     │              │   │
     └─→ S03 ──────┘   │
              │         │
              └─→ S05 ──┘
```

## Execution Order

Critical path: S01 → S02 + S03 (parallel) → S04 + S05 + S06 (parallel after deps met) → S07 + S08 (parallel)

S02 and S03 can run in parallel after S01 since they're independent (material tiers vs expedition engine). S04 needs S01+S02. S05 needs S03. S06 needs S02+S03. S07 and S08 need both UIs.
