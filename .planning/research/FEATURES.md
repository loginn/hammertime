# Feature Research

**Domain:** ARPG idle game — hero archetype system with prestige-based selection
**Researched:** 2026-03-09
**Confidence:** HIGH (patterns verified across PoE 1/2 ascendancies, Last Epoch masteries, Diablo 4 Paragon, idle ARPG conventions; mapped against existing Hammertime v1.8 systems)

---

## Feature Landscape

### Table Stakes (Users Expect These)

Players who have experienced prestige systems in idle games and class selection in ARPGs expect these features as baseline.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Archetype selection on prestige | Every prestige-based idle game (Realm Grinder, NGU Idle, Melvor Idle) offers meaningful choice at reset. A prestige that only unlocks item tiers feels mechanical, not strategic | LOW | Hook into `PrestigeManager.execute_prestige()` — add hero selection step between currency spend and `_wipe_run_state()` |
| Passive bonuses that change damage math | Players expect a hero pick to DO something visible. "100% more fire damage" is the genre standard (PoE ascendancy, Last Epoch mastery passives). Without a mechanical bonus, the pick feels cosmetic | MEDIUM | Bonus must flow through `StatCalculator` or `Hero.update_stats()` — multiplicative "more" modifier applied after additive stacking |
| Distinct visual identity per archetype | STR = heavy/red, DEX = agile/green, INT = arcane/blue is universal ARPG color language. Players identify their hero at a glance | LOW | Name + color tint on Hero View panel. No sprite system needed for idle |
| Re-pick on each prestige | Idle games with prestige classes (Melvor, Realm Grinder) let you change on reset. Permanent lock-in punishes experimentation and kills replayability | LOW | Hero archetype stored on `GameState`, wiped by `_wipe_run_state()`, re-selected before run starts |
| At least 2 meaningful choices per archetype | A single hero per archetype (just "Warrior") offers no decision within the archetype. Players need subvariants to express preference (DoT Warrior vs Hit Warrior) | MEDIUM | 2-3 subvariants per archetype = 6-9 total heroes. Data-driven via Resource definitions |
| Bonuses complement existing affix system | Hero bonuses should amplify what affixes already do, not create a parallel stat system. "More fire damage" works because fire damage affixes already exist | LOW | Bonus types map directly to existing `Tag.StatType` entries and damage elements |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Draft selection (pick 1 from 3 random) | Creates anticipation and variance across prestiges. Better than static menu — every prestige feels different. Roguelike idle games (Legends of IdleOn, Soulstone Survivors) use draft mechanics for this exact reason | LOW | Roll 1 random per archetype (STR/DEX/INT), present 3 cards. Player picks 1. Simple UI: 3 buttons with name + bonus text |
| Subvariants create build synergy with existing items | "Fire Wizard + Wand + Fire Hammer crafting" creates a coherent build identity that emerges from three independent systems (hero + items + crafting). No single system is complex, but their intersection creates depth | MEDIUM | Hero bonus multiplies a damage type that items provide and tag hammers target. Emergent synergy, not new mechanics |
| Hero bonus visible in stat panel | Players see their hero's contribution in the Hero View stats breakdown. "Fire Damage: 50 (x2.0 from Pyromancer)" makes the hero feel impactful every time they check stats | LOW | Add a line item in Hero View stat display showing active hero bonus |
| Hero choice influences optimal item base selection | Picking "Frost Warrior" makes STR items with cold damage affixes optimal. This retroactively adds value to the 21 existing item bases — players now care WHICH Broadsword vs Battleaxe they use | LOW | No new items needed. Hero bonus makes certain affix/item combinations more valuable |
| Prestige level gates hero pool depth | P1 offers basic subvariants. Higher prestige levels unlock stronger or more specialized heroes. Creates prestige motivation beyond item tier unlocks | MEDIUM | `HEROES_BY_PRESTIGE` constant controls which heroes enter the draft pool at each prestige level |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Permanent hero progression across prestiges | "My hero should get stronger each run" | Destroys prestige reset tension. If hero power accumulates, prestige becomes mandatory grinding instead of fresh-start excitement. Idle games that do this (some Cookie Clicker mods) trivialize content | Hero resets on prestige. Meta-progression comes from item tier unlocks (existing) and eventually from hero pool expansion |
| Skill trees per hero | "Each hero should have a talent tree" | Massive scope (9 heroes x 10+ nodes = 90+ design decisions). Overwhelms an idle game where the core loop is crafting, not character building. Last Epoch and PoE have skill trees because combat is active — idle games benefit from fewer, larger decisions | Single powerful passive per hero. One decision, big impact. Matches idle game cognitive budget |
| Active abilities per hero | "Warrior should have a slam ability" | Contradicts idle design. Active abilities require input timing, which is antithetical to the "leave it running" loop. Every idle game that adds active abilities (IdleOn) creates a "play or lose efficiency" problem | Hero bonus is always-on passive. No button press, no timing, no penalty for being AFK |
| Hero-exclusive item bases | "Only Warriors can equip Broadswords" | Restricts the 21-base item pool that was just built in v1.8. Players already found bases they like. Taking away options feels punishing. PoE explicitly does NOT restrict base equipment by class | All heroes can equip all items. Hero bonus makes certain items BETTER for certain heroes, not required |
| More than 3 heroes per archetype | "9 subvariants per archetype for maximum variety" | Dilutes draft pool. With 9 per archetype, the chance of seeing the hero you want drops to 11%. Players feel RNG-screwed instead of making meaningful choices. 2-3 per archetype keeps the draft interesting without frustrating | 2-3 subvariants per archetype (6-9 total). Add more in future milestones as the hero pool earns expansion |
| Hero stacking / multi-hero parties | "Let me run 3 heroes at once" | Multiplies combat complexity (3x damage, 3x defense, targeting). Breaks the single-hero stat model that StatCalculator, Hero, and CombatEngine are built around | Single hero per run. The hero IS the build. Party systems are a different game |
| Percentage-based hero bonuses that stack with affix percentages | "Hero gives +50% fire damage (additive with gear)" | Additive stacking with gear makes hero bonus invisible at high gear levels. If gear already gives +200% fire, another +50% from hero is only a 17% relative increase. Feels weak | Use multiplicative "more" modifier. "100% more fire damage" doubles output regardless of gear level. Always impactful |

---

## Feature Dependencies

```
[Hero Archetype Data Model]
    |-- new Resource --> HeroArchetype (name, archetype_tag, bonus_type, bonus_value, description)
    |-- uses --> Tag.STR / Tag.DEX / Tag.INT (existing archetype tags)
    |-- uses --> Tag.StatType entries (existing damage types for bonus targeting)
    |-- required-by --> [Hero Selection UI]
    |-- required-by --> [Stat Calculation Integration]
    |-- required-by --> [Save/Load Persistence]

[Hero Selection UI]
    |-- requires --> [HeroArchetype data model]
    |-- requires --> [PrestigeManager hook] (selection happens during prestige flow)
    |-- triggers --> GameEvents signal (hero_selected or similar)
    |-- impacts --> prestige_view.gd (add selection step before reset completes)
    |-- impacts --> main_view.gd (may need to coordinate selection overlay)

[Stat Calculation Integration]
    |-- requires --> [HeroArchetype on GameState] (active hero stored for stat lookup)
    |-- impacts --> Hero.update_stats() (apply hero bonus after equipment stat aggregation)
    |-- impacts --> Hero.calculate_dps() / calculate_spell_dps() (multiplicative bonus)
    |-- impacts --> Hero.calculate_dot_stats() (DoT-focused heroes need bonus applied to DoT DPS)
    |-- does NOT impact --> StatCalculator (item-level math unchanged; hero bonus is hero-level)
    |-- does NOT impact --> DefenseCalculator (no defensive hero bonuses in MVP)

[Save/Load Persistence]
    |-- requires --> [HeroArchetype serializable] (to_dict / from_dict on hero archetype)
    |-- impacts --> SaveManager (save format version bump; active_hero field on save data)
    |-- impacts --> GameState (active_hero_archetype field; wiped on prestige, restored on load)
    |-- migration --> Existing saves get null hero (P0 runs have no hero, which is correct)

[Prestige Flow Integration]
    |-- requires --> [Hero Selection UI]
    |-- impacts --> PrestigeManager.execute_prestige() (insert selection step)
    |-- impacts --> GameState._wipe_run_state() (clear active hero)
    |-- decision --> Selection BEFORE or AFTER wipe? AFTER wipe: hero is part of new run
```

### Key Dependency Insight

The hero bonus hooks into `Hero.update_stats()` at the hero level, NOT into `StatCalculator` at the item level. This is critical: item math stays clean, hero math gets one new multiplicative pass. The bonus applies after all equipment stats are aggregated, making it a single multiplication at the end of the pipeline.

---

## Subvariant Design Analysis

### How Many Subvariants?

| Count | Pros | Cons | Verdict |
|-------|------|------|---------|
| 1 per archetype (3 total) | Simplest. No within-archetype choice | No draft variance. Picking "STR" is always the same hero. Boring prestige loop | Too few |
| 2 per archetype (6 total) | Clean DoT vs Hits split per archetype. Draft always offers meaningful choice (2 options per archetype = always novel pairs) | Limited elemental variety. No fire/cold/lightning differentiation | Good MVP |
| 3 per archetype (9 total) | Enables DoT + 2 elemental variants per archetype. Rich draft pool. 9 choose 3 = 84 possible draft combinations | More data definitions. Risk of balance gaps between 9 heroes | Best target for v1.9 |
| 4+ per archetype (12+ total) | Maximum variety | Diluted draft odds. Balance nightmare. Content bloat for minimal gameplay gain | Too many for MVP |

**Recommendation: 3 per archetype (9 total heroes)**

This maps naturally to the existing game axes:
- Axis 1: Archetype (STR/DEX/INT) — determines defense type affinity
- Axis 2: Damage style — DoT vs Hits vs Elemental specialty

### Proposed 9-Hero Roster

| Archetype | Hero | Passive Bonus | Synergy Target |
|-----------|------|---------------|----------------|
| STR | Berserker | 100% more physical damage | Broadsword/Battleaxe + physical affixes |
| STR | Warlord | 100% more bleed damage, +20% bleed chance | Warhammer + bleed affixes (DoT path) |
| STR | Frost Knight | 100% more cold damage | Any STR weapon + cold flat damage affixes |
| DEX | Assassin | 100% more critical damage | Dagger + crit affixes |
| DEX | Venomancer | 100% more poison damage, +20% poison chance | VenomBlade + poison affixes (DoT path) |
| DEX | Windrunner | 100% more lightning damage | Shortbow + lightning flat damage affixes |
| INT | Pyromancer | 100% more fire spell damage | Wand/Sceptre + fire spell damage affixes |
| INT | Warlock | 100% more burn damage, +20% burn chance | Sceptre + burn affixes (DoT path) |
| INT | Stormcaller | 100% more lightning spell damage | LightningRod + lightning spell damage affixes |

### Bonus Structure: Why "More" (Multiplicative) Not "Increased" (Additive)

| Modifier Type | Formula | At 0% Gear Bonus | At 200% Gear Bonus | Feel |
|---------------|---------|-------------------|---------------------|------|
| +100% increased (additive) | base * (1 + gear% + hero%) | 2x damage | 1.33x relative boost | Diminishing. Feels weak at high gear |
| 100% more (multiplicative) | base * (1 + gear%) * (1 + hero%) | 2x damage | 2x relative boost | Constant. Always doubles output |

Multiplicative "more" is the correct choice because:
1. It scales with gear investment, not against it. Better gear makes the hero bonus MORE impactful, not less
2. PoE uses "more" for ascendancy keystones for exactly this reason
3. In an idle game where gear power grows exponentially across prestige levels, additive bonuses become invisible. Multiplicative stays relevant forever
4. It creates a clear hierarchy: affixes are "increased" (additive with each other), hero bonus is "more" (multiplicative on top)

### Conditional Bonuses: Keep It Simple

DoT heroes get a secondary bonus (+20% chance) alongside the "more" damage bonus. This is acceptable because:
- It maps to an existing stat (`total_bleed_chance`, `total_poison_chance`, `total_burn_chance`)
- It's a flat addition, not a new modifier type
- Without it, DoT heroes need extensive DoT gear to even trigger their bonus. The chance boost bootstraps viability

No other conditional bonuses (kill-based, health-threshold, combo-based) — these require state tracking that complicates idle combat.

---

## MVP Definition

### Launch With (v1.9)

Core hero system with prestige-based selection and passive bonuses.

- [ ] **HeroArchetype Resource class** — data model with name, archetype_tag, bonus_type, bonus_value, bonus_description
- [ ] **9 hero definitions** — 3 per archetype as outlined in roster above
- [ ] **Hero selection UI** — 3-card draft presented after prestige confirmation, before run starts
- [ ] **GameState.active_hero** — nullable HeroArchetype field, cleared on wipe, set on selection
- [ ] **Hero.update_stats() integration** — multiplicative "more" bonus applied after equipment aggregation
- [ ] **DoT hero chance bonus** — flat addition to bleed/poison/burn chance for DoT-focused heroes
- [ ] **Hero View display** — show active hero name + bonus description in stat panel
- [ ] **Save format update** — persist active_hero; version bump; null migration for existing saves
- [ ] **PrestigeManager flow** — insert hero selection step into execute_prestige()
- [ ] **GameEvents.hero_selected signal** — notify UI observers when hero is chosen

### Add After Validation (v1.x)

- [ ] **Prestige-level-gated hero pool** — P1 offers 6 basic heroes; P3+ unlocks all 9
- [ ] **Hero bonus scaling with prestige level** — P1 hero gives 50% more; P7 hero gives 150% more
- [ ] **Defensive hero variants** — heroes with defensive bonuses (e.g., "50% more armor" for tank builds)
- [ ] **Hero history tracking** — show which heroes were picked in previous prestiges
- [ ] **Themed hero names per prestige tier** — Berserker -> Warchief -> God of War across prestige levels

### Future Consideration (v2+)

- [ ] **Dual-bonus heroes** — heroes with two smaller bonuses instead of one large one
- [ ] **Hero-specific item affixes** — affixes that only roll when a specific hero is active
- [ ] **Hero synergy with tag hammers** — hero choice unlocks a bonus tag hammer type
- [ ] **Ascendancy trees** — multi-node passive trees per hero (scope: full milestone)
- [ ] **Hero cosmetic effects** — visual effects on combat based on hero type

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| HeroArchetype data model (Resource) | HIGH | LOW | P0 — foundation |
| 9 hero definitions (data only) | HIGH | LOW | P0 — content |
| Hero selection UI (3-card draft) | HIGH | MEDIUM | P0 — core UX |
| Multiplicative bonus in Hero.update_stats() | HIGH | MEDIUM | P0 — makes heroes matter |
| GameState.active_hero + save persistence | HIGH | LOW | P0 — persistence |
| PrestigeManager flow integration | HIGH | LOW | P0 — hooks into existing system |
| DoT hero chance bonus (+20%) | MEDIUM | LOW | P1 — DoT viability |
| Hero View stat display | MEDIUM | LOW | P1 — visibility |
| GameEvents.hero_selected signal | MEDIUM | LOW | P1 — UI coordination |
| Prestige-gated hero pool | LOW | LOW | P2 — depth |
| Bonus scaling with prestige level | LOW | MEDIUM | P2 — tuning |
| Defensive hero variants | LOW | MEDIUM | P2 — broadens options |
| Hero-specific affixes | LOW | HIGH | P3 — scope risk |
| Ascendancy trees | LOW | HIGH | P3 — different game |

---

## Competitor Feature Analysis

| Feature | PoE Approach | Diablo 4 Approach | Idle ARPG Approach (Melvor/IdleOn) | Our Approach |
|---------|-------------|-------------------|--------------------------------------|--------------|
| **Class/archetype selection** | Permanent at character creation. 7 classes, each with 3 ascendancies (21 total) | Permanent at character creation. 5 classes with Paragon boards | Per-account unlock or prestige-based. Melvor: pick combat style per slayer task. IdleOn: pick class at character creation | Prestige-based draft. Pick 1 from 3 random heroes each prestige. Impermanent — re-pick every reset |
| **Subclass depth** | Deep: 6-8 ascendancy nodes per subclass with major/minor passives. Hundreds of passive points on tree | Medium: Paragon boards with glyphs and rare nodes. ~20 meaningful choices | Shallow: Melvor has no subclasses. IdleOn has 3 subclasses per class with simple stat bonuses | Shallow-but-impactful: 1 powerful "more" passive per hero. Depth comes from hero x item x hammer interaction, not from hero complexity alone |
| **Passive bonus type** | Mix of flat, %, and "more" multipliers. Some conditional (on kill, on crit). Keystones are build-defining | Flat + % bonuses. Paragon glyphs provide conditional bonuses based on nearby node stats | Flat stat bonuses. Simple multipliers. No conditional logic | Single "more" multiplier per hero. DoT heroes also get flat chance bonus. No conditionals |
| **Respec/re-pick** | Respec available but costly (orbs of regret). Ascendancy refund very expensive. Effectively permanent | Free respec at any time in town | Melvor: change freely. IdleOn: fixed per character | Free re-pick every prestige. Prestige IS the respec mechanism |
| **Number of options** | 21 ascendancies across 7 classes | 5 classes, each with ~4 Paragon paths | Melvor: 3 combat styles. IdleOn: 9 subclasses | 9 heroes (3 per archetype). Expandable in future milestones |
| **Integration with items** | Ascendancy bonuses interact with item mods. Some keystones change how mods work (e.g., "modifiers to claw damage apply to unarmed") | Paragon bonuses are separate from item system. Minimal interaction | Minimal item interaction. Bonuses are stat sticks | Strong item interaction. Hero bonus multiplies damage types that items provide. Fire Wizard + fire affixes = synergy |
| **Selection UX** | Labyrinth trial (gameplay gate) then menu selection | Menu at character creation | Menu selection | 3-card draft on prestige. Randomized but guaranteed 1-per-archetype |

---

## Implementation Notes for Downstream Consumers

### Stat Pipeline Integration Point

The hero bonus inserts at a specific point in the existing calculation chain:

```
Equipment affixes (additive "increased" stacking)
    -> Hero.update_stats() aggregates per existing logic
        -> NEW: apply active_hero "more" multiplier
            -> Final hero stats (DPS, spell DPS, DoT DPS)
```

For attack/spell DPS, the bonus multiplies `total_dps` or `total_spell_dps` after the existing formula completes. For DoT heroes, the bonus multiplies the specific DoT DPS component AND adds flat chance.

### Save Format Considerations

- New field: `active_hero` (nullable string — hero identifier or null for no hero)
- Save version bump required (v7 -> v8)
- Migration: existing v7 saves get `active_hero: null` — P0 runs correctly have no hero
- HeroArchetype definitions are code-side constants (like `PRESTIGE_COSTS`), not serialized. Only the hero identifier is saved

### Draft Pool Mechanics

- On prestige: roll 1 random hero from each archetype pool (STR, DEX, INT)
- Present all 3 to player simultaneously
- Player picks 1; other 2 are discarded
- No "re-roll" or "refresh" — the 3 offered are the 3 options
- If player cancels: prestige does not complete (selection is mandatory to start new run)

---

## Sources

**Prestige class systems in idle games (HIGH confidence):**
- Melvor Idle combat style system: simple stat multipliers chosen per activity; free switching; no permanent commitment
- Realm Grinder faction system: faction choice on each abdication (prestige) with production bonuses; re-pick every reset
- NGU Idle class system: unlocked via prestige currency; passive bonuses scale with investment
- Legends of IdleOn subclass system: 3 classes with 3 subclasses each; permanent per character; stat-focused passives

**ARPG ascendancy/mastery systems (HIGH confidence):**
- PoE ascendancy classes: 3 per base class; keystones provide "more" multipliers and build-defining mechanics; chosen via labyrinth trial
- PoE 2 ascendancy system: similar structure, deeper trees, same "more" modifier philosophy for keystones
- Last Epoch masteries: 1 per base class at launch, each with passive tree; "more" multipliers on key nodes; chosen at level 25
- Diablo 4 Paragon system: post-endgame character customization; rare/magic nodes with conditional bonuses

**Multiplicative vs additive bonus design (HIGH confidence — verified math):**
- PoE "more" vs "increased" distinction: documented in community wiki; "increased" stacks additively, "more" multiplies independently
- Last Epoch "more" modifiers: same convention; mastery keystones use "more" to ensure scaling at all gear levels
- Idle game scaling analysis: exponential power growth in idle games makes additive bonuses irrelevant at high levels; multiplicative bonuses maintain relevance

**Codebase integration analysis (HIGH confidence — direct code review of Hammertime v1.8):**
- `Hero.update_stats()` call chain: crit -> ranges -> dps -> spell_dps -> defense -> dot; hero bonus inserts after each relevant step
- `PrestigeManager.execute_prestige()` flow: validate -> spend -> advance -> wipe -> grant bonus -> signal; hero selection inserts after wipe, before signal
- `GameState._wipe_run_state()` scope: clears area, hero, inventory, currencies, tag currencies; hero archetype field added to wipe list
- `Tag.StatType` enum: all damage types already enumerated; hero bonus targets existing enum values, no new types needed

---

*Feature research for: hero archetype system*
*Researched: 2026-03-09*
