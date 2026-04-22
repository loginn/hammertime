# HammerTime M001 — UI Design Brief

## What is this game?

HammerTime is an ARPG-style crafting idle game built in Godot 4. You play as a blacksmith, not an adventurer. The core loop: pick an item base → craft it using currency hammers → equip a hero → send them on passive expeditions → they bring back crafting materials and currency → craft better items → push harder expeditions → eventually prestige and repeat faster.

Think Path of Exile's crafting system as the entire game, with idle-game progression pacing.

## Target platform

Desktop (1280×720 viewport). Dark theme — dark gray backgrounds (#1a1a1a base, #333333 panels, #2b2b2b chrome). White text default. No mobile considerations for M001.

## What ships in M001

- 1 hero (always present, always equipped)
- 5 item slots: Weapon, Armor, Helmet, Boots, Ring
- 7 currency types (hammers) that modify items
- 2 material tiers (Iron, Steel) — item bases come in these materials
- 2 expeditions (different difficulty/rewards, always succeed, time = gear quality)
- Prestige trigger (spend 100 Tack Hammers → get 999 of every hammer)

---

## Screens

There are **3 screens** navigated via a top tab bar: **Forge**, **Expeditions**, **Settings**. The tab bar is a persistent 1280×50px strip at the top.

---

### Screen 1: The Forge

This is the main screen. It combines crafting, inventory, hero equipment, and hero stats into one view. The player spends most of their time here.

#### Layout: 3 columns

```
┌─────────────────────────────────────────────────────────────┐
│  [The Forge]  [Expeditions]                    [Settings]   │  ← Tab bar
├──────────┬────────────────────────┬──────────────────────────┤
│          │                        │                          │
│ HAMMERS  │    CRAFTING BENCH      │     HERO PANEL           │
│          │                        │                          │
│ 7 hammer │  Item visual           │  Hero portrait/graphic   │
│ buttons  │  Item type selector    │                          │
│ in grid  │  Item stat display     │  Equipped items summary  │
│          │  (affixes, rarity,     │  (5 slots, clickable)    │
│ Counts   │   material tier)       │                          │
│ shown    │                        │  Aggregate hero stats    │
│ per      │  [Craft] action area   │  (life, armor, resists,  │
│ hammer   │                        │   damage, etc.)          │
│          │                        │                          │
│          ├────────────────────────┤                          │
│          │    INVENTORY           │                          │
│          │                        │                          │
│          │  Crafted items grid    │                          │
│          │  (filterable by slot)  │                          │
│          │  Base items available  │                          │
│          │                        │                          │
└──────────┴────────────────────────┴──────────────────────────┘
```

#### Left column: Hammer Sidebar (~250px wide)

Displays the 7 currency hammers the player can use. Each hammer is a button showing:
- Hammer icon
- Hammer name
- Count owned (e.g., "×42")

Selecting a hammer makes it the active crafting tool. Only one can be active. The active hammer is visually highlighted.

**The 7 hammers and what they do** (the designer needs this context to write good tooltips and understand the flow):

| Hammer | Verb | What it does |
|--------|------|-------------|
| Tack Hammer | Transmute | Normal item → Magic item (adds 1-2 random affixes) |
| Tuning Hammer | Alteration | Rerolls all affixes on a Magic item (new random 1-2 affixes) |
| Forge Hammer | Augment | Adds 1 random affix to a Magic item that isn't full |
| Grand Hammer | Regal | Magic item → Rare item (adds 1+ affix, keeps existing) |
| Runic Hammer | Exalt | Adds 1 random affix to a Rare item that isn't full |
| Scour Hammer | Scour | Strips all affixes → Normal item (works on Magic or Rare) |
| Claw Hammer | Annul | Removes 1 random affix (works on Magic or Rare) |

**Design consideration:** Each hammer should have a distinct visual identity. The player will be rapidly clicking between them. Icon + color differentiation matters more than label text during fast crafting.

#### Center column: Crafting Bench + Inventory (~430px wide)

**Top section — Crafting Bench:**
- Shows the currently selected item prominently
- Displays: item name, rarity (Normal/Magic/Rare), material tier (Iron/Steel), all affixes with their tier numbers and values
- Rarity colors: Normal = White/Gray, Magic = Blue, Rare = Yellow/Gold
- Clicking the item (or a dedicated [Craft] button) applies the selected hammer
- Visual/audio feedback on craft: the affixes change, rarity may change, satisfying feedback

**Item type selector:** Row of 5 buttons (Weapon, Helmet, Armor, Boots, Ring) to filter which slot type you're working on. This controls which bases appear in inventory below and which item is on the bench.

**Bottom section — Inventory:**
- Grid or list of items the player owns for the selected slot type
- Includes uncrafted base items (from expedition rewards)
- Each item shows: name, rarity color indicator, material tier, brief affix summary
- Clicking an item puts it on the crafting bench
- An equipped indicator on items currently worn by the hero
- An [Equip] action on the benched item (or drag to hero panel)

**Design consideration:** The crafting loop is *fast*. A player might transmute → look at affixes → not like them → scour → transmute again 50 times in a row. The UI must support rapid repeated actions without modal dialogs or confirmation prompts. The feedback should be in the affix display changing, not in popups.

#### Right column: Hero Panel (~430px wide)

**Top section — Hero Portrait:**
- Character graphic/portrait
- Hero name (if applicable)

**Equipped items summary:**
- Visual representation of 5 equipment slots
- Each slot shows: the equipped item's name and rarity, or "Empty" if nothing equipped
- Clicking a slot could select that slot type in the crafting bench (cross-column interaction)

**Aggregate stats display:**
- Computed totals from all equipped gear
- Key stats: Life, Energy Shield, Armor, Evasion, Fire/Cold/Lightning Resistance, Physical Damage, Attack Speed, Crit Chance
- When hovering/previewing an item swap: show delta values (green for improvement, red for downgrade) inline with each stat

**Design consideration:** Stat comparison is critical. The player needs to instantly see "is this new craft better than what I'm wearing?" The delta display should be scannable at a glance — not a separate popup or tooltip, but inline color-coded changes.

---

### Screen 2: Expeditions

This is where the player sends their hero to earn materials and hammers. It's a simpler screen — mostly status display and a launch button.

#### Layout

```
┌─────────────────────────────────────────────────────────────┐
│  [The Forge]  [Expeditions]                    [Settings]   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────┐  ┌─────────────────────┐          │
│  │  EXPEDITION 1       │  │  EXPEDITION 2       │          │
│  │  "Iron Quarry"      │  │  "Steel Depths"     │          │
│  │                     │  │                     │          │
│  │  Difficulty: ★      │  │  Difficulty: ★★★    │          │
│  │  Material: Iron     │  │  Material: Steel    │          │
│  │                     │  │                     │          │
│  │  Rewards:           │  │  Rewards:           │          │
│  │  · Iron bases       │  │  · Steel bases      │          │
│  │  · Basic hammers    │  │  · Better hammers   │          │
│  │                     │  │  · More hammers     │          │
│  │  Est. time: 10s     │  │  Est. time: 45s     │          │
│  │                     │  │                     │          │
│  │  [Send Hero]        │  │  [Send Hero]        │          │
│  │                     │  │                     │          │
│  └─────────────────────┘  └─────────────────────┘          │
│                                                             │
│  ┌─────────────────────────────────────────────┐           │
│  │  EXPEDITION IN PROGRESS (if active)         │           │
│  │  ████████████░░░░░░░░  62%  ETA: 4s         │           │
│  │                                              │           │
│  │  [Collect Rewards] (when complete)           │           │
│  └─────────────────────────────────────────────┘           │
│                                                             │
│  ┌──────────────────────┐                                  │
│  │  PRESTIGE            │                                  │
│  │  Tack Hammers: 47/100│                                  │
│  │  [Prestige] (greyed) │                                  │
│  └──────────────────────┘                                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### Expedition Cards

Two cards side by side, one per expedition. Each shows:
- Expedition name and flavor
- Difficulty indicator
- Material tier it drops
- Reward summary (what types of hammers/bases)
- Estimated completion time (calculated from hero's current gear)
- [Send Hero] button

Only one expedition can be active at a time. While active:
- The active card shows a progress bar with time remaining
- The other card's [Send Hero] is disabled
- On completion: rewards are shown and a [Collect] button appears

**Design consideration:** Estimated time is a key motivator. Showing "Est. 45s" for expedition 2 when you're undergeared, then watching it drop to "Est. 12s" after crafting better gear, is the core feedback loop that ties crafting to expeditions. Make this number prominent.

#### Prestige Section

A section (bottom of screen or sidebar) showing:
- Current Tack Hammer count vs. 100 required
- Progress bar or counter toward prestige threshold
- [Prestige] button — disabled until threshold met, prominent when available
- Brief description: "Reset your items and materials. Receive 999 of every hammer."

**Design consideration:** Prestige should feel like a big deal when triggered. The button should have visual weight when available. But it should not be intrusive during normal play — just quietly tracking progress.

---

### Screen 3: Settings

Minimal screen. Centered vertical stack of buttons:
- Save Game
- New Game (with confirmation)
- Export Save (copies to clipboard)
- Import Save (text input + button)
- Version label at bottom

No major design work needed here — functional and clean.

---

## User Flows

### Flow 1: First-time crafting
1. Player starts on Forge screen with some starting Tack Hammers
2. They see empty item slots on the hero, base items in inventory
3. They click a base item → it goes on the crafting bench (Normal rarity, no affixes)
4. They select Tack Hammer from sidebar
5. They click craft → item becomes Magic with 1-2 affixes
6. They read the affixes, decide to keep or scour and try again
7. They click [Equip] → item moves to hero, stats update

### Flow 2: Crafting upgrade cycle
1. Player has a Magic item equipped, wants better
2. Grabs another base from inventory, transmutes it
3. If affixes are good → Augment to add another, then Regal to go Rare
4. If affixes are bad → Scour and restart
5. Compare stats with equipped item (delta display)
6. Equip if better

### Flow 3: Expedition loop
1. Player switches to Expedition screen
2. Sees estimated times based on current gear
3. Sends hero to Expedition 1 (10s)
4. Waits (or switches to Forge to craft while waiting)
5. Expedition completes → rewards shown → collect
6. Back to Forge to use new hammers on new bases

### Flow 4: Prestige
1. Player accumulates 100 Tack Hammers over many expeditions
2. Prestige section shows threshold met, button lights up
3. Player clicks Prestige → confirmation
4. All items, materials, expedition progress reset
5. Player receives 999 of every hammer
6. Back to Forge with a massive hammer stockpile, faster progression

---

## Visual Language

### Rarity Colors
| Rarity | Color | Usage |
|--------|-------|-------|
| Normal | White/Gray (#cccccc) | Base items, no affixes |
| Magic | Blue (#4488ff) | 1-2 affixes |
| Rare | Yellow/Gold (#ffcc00) | 3-6 affixes |

### Material Tiers
| Material | Visual Treatment |
|----------|-----------------|
| Iron | Gray/silver tone, basic |
| Steel | Slightly brighter, subtle blue tint |

### Hammer Identity
Each of the 7 hammers needs a distinct color/shape so they're distinguishable at icon size (~40-60px). They'll be clicked constantly — recognition speed matters.

### General Style Notes
- Dark UI, no bright backgrounds
- Panel surfaces: #333333 on #1a1a1a base
- Chrome/tabs: #2b2b2b
- Accent colors used sparingly for rarity, positive/negative stat deltas
- Stat deltas: Green (#55ff55) for improvement, Red (#ff5555) for downgrade
- Toast notifications: top-right corner, auto-fade after 1-2 seconds
- No modal dialogs during crafting — speed matters
- Progress bars for expedition timers, prestige threshold

---

## Interactions That Matter Most

1. **Crafting feel** — clicking a hammer on an item must feel snappy and satisfying. The affixes should visibly change with minimal latency. Consider a brief flash or color pulse on the item card when crafted.

2. **Stat comparison** — equipping decisions are the strategic core. The player must be able to instantly compare a crafted item against equipped gear without navigating away.

3. **Expedition time as motivation** — watching estimated expedition time drop as you craft better gear is the hook that connects the two systems. This number should update live when you equip new items.

4. **Prestige moment** — the transition from "grinding" to "prestige available" to "reset with 999 hammers" should feel like a reward, not a punishment.

5. **Inventory management** — with 5 slots × 2 material tiers × many crafted items, the inventory needs to be scannable. Rarity color + slot type + material tier should all be visible at a glance in the grid.

---

## What this doc does NOT cover

- Sound design
- Specific art style (waiting on mockups)
- Animation details beyond "make crafting feel snappy"
- Responsive/mobile layouts
- Accessibility
- Later milestones (totem crafting, multi-hero, expedition themes, forge upgrades)
