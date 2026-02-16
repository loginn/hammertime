# Feature Research

**Domain:** Pack-based Idle ARPG Combat
**Researched:** 2026-02-16
**Confidence:** MEDIUM

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Sequential pack combat | Idle ARPGs use pack-by-pack progression, not simultaneous waves | MEDIUM | Requires combat tick system, HP tracking per pack, victory conditions. Old School RuneScape uses tick-based combat (20ms client-side). Similar to Idle Clans where attack meter fills based on weapon interval. |
| Physical + elemental damage types | Standard ARPG pattern: physical/fire/cold/lightning | LOW | Already exist as item stats. Need to assign to monsters. Grim Dawn standard: physical + 3 elemental types (fire/cold/lightning) that behave distinctly. |
| Resistance-based mitigation | 75% resistance cap is ARPG standard (PoE, Last Epoch, D3) | MEDIUM | Requires per-element damage calculation. Formula: `damage_taken = incoming_damage * (1 - resistance/100)`. Cap at 75% prevents immunity, maintains challenge. |
| Armor vs physical damage | Armor reduces physical damage using diminishing returns formula | MEDIUM | PoE formula: `DR = Armor / (Armor + 5 * Damage)`. To block 50% need 10x armor, 75% need 30x armor. Prevents armor from being overpowered vs small hits while keeping it effective. |
| Evasion as dodge chance | Evasion rating converts to % chance to avoid hits entirely | MEDIUM | Typically uses diminishing returns formula to prevent 100% dodge. Common approach: `dodge_chance = evasion / (evasion + constant)` soft-capping around 75-90%. PoE uses entropy system (pseudo-random) instead of pure RNG. |
| Energy shield as buffer HP | Extra HP pool that recharges after not taking damage | MEDIUM | PoE standard: 2-second delay before recharge starts. Recharge interrupts on any damage. Depletes before life. Requires tracking last_damage_time, recharge_rate, current_ES. |
| Death = lose map progress | Roguelite pattern: death forfeits current run but keeps permanent rewards | LOW | Keep currency earned before death, lose map completion and item drops. Hades/Dead Cells pattern. Users expect "wasted time still has value" in idle games. |
| Random pack count per map | Pack quantity varies per map run for replayability | LOW | PoE maps have variable "pack size". Typical range: 3-8 packs for early areas, 8-15 for endgame. Adds variance without complex implementation. |
| Biome damage type distribution | Early areas mostly physical, later areas more elemental | LOW | Reinforces progression: early game armor-focused, late game needs balanced defenses. Forest 80% physical, Dark Forest 60% phys/40% elemental, Cursed Woods 40/60, Shadow Realm 20/80. |
| Currency from packs, items from completion | Loot split encourages progression even on death | LOW | Packs drop currency on kill (kept on death). Map completion drops items (lost on death). Matches existing LootTable pattern. Incremental games avoid "all or nothing" failure states. |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not required, but valuable.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Elemental damage preview before entering | Shows biome's damage distribution before committing | LOW | Reduces "oops I wasn't resist-capped" deaths. Lets players make informed gear choices. Unique to planning-focused idle ARPGs. Display: "Forest: 80% Physical, 10% Fire, 5% Cold, 5% Lightning". |
| Energy shield recharge during combat | ES recharges mid-fight if you don't take damage for 2s | MEDIUM | Creates skill expression in idle game: high ES builds need to actually survive hits. More engaging than pure stat check. Matches PoE mechanic but rare in idle games. |
| Biome-specific pack elemental types | Shadow Realm packs vary: some fire-focused, some cold, some mixed | MEDIUM | Adds tactical depth: "This pack is all fire, my fire res can handle it. Next pack is lightning, might be risky." Prevents monotonous "same stats every fight" pattern. |
| Visible pack HP bars with damage breakdown | Show damage dealt by type: "Hit for 150 (100 phys blocked, 50 fire taken)" | MEDIUM | Educational: teaches players why defenses matter. Idle Clans shows attack meters; we show mitigation in action. Builds player understanding of defensive layers. |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| 100% damage immunity possible | "I want to cap all resists at 100%" | Removes challenge, makes combat trivial. No risk = no engagement. ARPGs universally cap at 75% for this reason. | Hard cap resistances at 75% per type. Players can exceed in stats but effective max is 75%. |
| Per-monster loot drops | "Every monster should drop loot like Diablo" | Explosion of items in idle game = inventory management nightmare. Contradicts "idle" philosophy. | Packs drop currency on kill (small reward). Map completion drops items (big reward). Keeps loot manageable. |
| Real-time combat with player timing | "Let me dodge attacks manually" | Fundamentally conflicts with "idle" genre. Requires active play. Scope creep into full action RPG. | Sequential automatic combat with stat-based outcomes. Depth comes from build planning, not execution. |
| Complex elemental interaction system | "Fire should melt ice shields, lightning conducts through water" | Adds massive complexity for questionable value. Balancing nightmare. Elemental interactions hard to communicate in idle format. | Simple resistance system: each element reduces its own damage type independently. Clear, predictable, no hidden mechanics. |
| Revive/retry mechanic with penalty | "Let me continue the map but take a penalty" | Encourages degenerate "throw bodies at it" gameplay. Death becomes meaningless. Undermines defensive stat investment. | Death = map failed, keep currency, lose items. Clean failure state. Incentivizes proper defense building. |

## Feature Dependencies

```
[Death Penalty]
    └──requires──> [Pack Currency Drops] (need something to keep on death)
    └──requires──> [Map Completion Tracking] (need to know progress was lost)

[Defensive Combat Calculations]
    └──requires──> [Damage Type System] (need to know what damage to reduce)
    └──requires──> [Monster Damage Values] (need incoming damage to reduce)
    └──requires──> [StatCalculator] (existing, extend for defense)

[Pack-based Combat]
    └──requires──> [Monster Pack Data Structure] (HP, damage, element types)
    └──requires──> [Combat Tick System] (sequential combat resolution)
    └──requires──> [Victory/Death Conditions] (when pack dies, when hero dies)

[Energy Shield Recharge]
    └──requires──> [Combat Timing Tracking] (last_damage_time)
    └──requires──> [Defensive Combat] (ES as HP pool)

[Biome Damage Distribution]
    └──requires──> [Pack-based Combat] (need packs to assign damage types)
    └──requires──> [Damage Type System] (need types to distribute)

[Random Pack Count]
    └──requires──> [Pack-based Combat] (need packs to randomize count)

[Elemental Damage Preview] ──enhances──> [Biome Selection]
[Visible Damage Breakdown] ──enhances──> [Defensive Combat]
```

### Dependency Notes

- **Death Penalty requires Pack Currency Drops:** The "lose progress but keep currency" pattern requires currency to drop during the run, not just at completion. Otherwise death loses everything, violating idle game expectations.
- **Defensive Combat requires StatCalculator:** Existing StatCalculator (calculate_dps, calculate_flat_stat) must be extended to support defensive calculations: armor_reduction(incoming_phys), resist_reduction(incoming_element), dodge_roll(evasion_rating).
- **Energy Shield Recharge requires Combat Timing:** Need to track when hero last took damage. If `current_time - last_damage_time >= 2.0`, start ES recharge. Interrupts on any damage (to ES or Life).
- **Pack-based Combat is foundation:** Almost all features depend on pack system existing first. Packs are the unit of combat, loot, and progression.

## MVP Definition

### Launch With (v1.2)

Minimum viable product — what's needed to validate pack-based combat.

- [x] **Sequential pack combat** — Core mechanic. Hero fights packs one at a time, each with HP pool. Essential for idle combat loop.
- [x] **Physical + 3 elemental damage types** — Monsters deal physical/fire/cold/lightning. Items already have these stats. Minimal implementation: assign damage_type to packs, calculate total damage as sum.
- [x] **Armor reduces physical damage** — Use PoE formula: `DR = Armor / (Armor + 5 * RawDamage)`. Essential to make armor stat useful. Test with: 100 armor vs 20 damage = 100/(100+100) = 50% reduction.
- [x] **Resistances reduce elemental damage** — Simple formula: `damage_taken = incoming * (1 - min(resistance, 75) / 100)`. Cap at 75%. Essential to make resistance stats useful.
- [x] **Evasion = dodge chance** — Use diminishing returns: `dodge_chance = min(evasion / (evasion + 500), 0.75)`. Pure random (no entropy system for v1.2). Essential to make evasion stat useful.
- [x] **Energy shield as extra HP** — ES depletes before life. Basic implementation: no recharge in v1.2 (treat as bonus HP). Recharge mechanic is v1.x enhancement.
- [x] **Death = lose map progress, keep currency** — Hero dies if life <= 0. Lose map completion and item drops. Keep currency earned from killed packs. Essential for fair failure state.
- [x] **Random pack count per map** — Simple RNG: `pack_count = randi_range(min, max)` where min/max scale with biome. Forest: 3-6, Dark Forest: 5-8, etc. Adds replayability.
- [x] **Packs drop currency, maps drop items** — Each pack killed rolls currency via existing `LootTable.roll_currency_drops()`. Map completion rolls items. Split reinforces "death has some value" pattern.
- [x] **Biome damage distributions** — Fixed per biome. Forest: 80/10/5/5 (phys/fire/cold/lightning). Dark Forest: 60/20/10/10. Cursed Woods: 40/30/15/15. Shadow Realm: 20/40/20/20. Simple progression curve.

### Add After Validation (v1.x)

Features to add once core is working.

- [ ] **Energy shield recharge mechanic** — Add 2-second delay, then recharge at rate. Trigger: core combat stable, users understand ES as HP pool. Adds strategic depth: "Can I survive 2 seconds without damage?"
- [ ] **Elemental damage preview** — Display biome's damage distribution before entering. Trigger: users report unexpected deaths due to wrong resists. Low-effort quality-of-life win.
- [ ] **Visible damage breakdown in combat log** — Show "Hit for 150 (100 phys blocked, 50 fire taken)". Trigger: users confused why defenses aren't working. Educational feature.
- [ ] **Biome-specific pack elemental variance** — Instead of fixed distribution, each pack has random elemental focus. Trigger: combat feels repetitive. Adds variety without complexity.

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] **Energy shield recharge rate modifiers** — Items/affixes that speed up recharge delay or increase recharge rate. Trigger: ES build diversity needed. Requires affix pool expansion.
- [ ] **Evasion entropy system** — Replace pure RNG with PoE-style pseudo-random (guarantee hit every N attempts). Trigger: users complain about RNG streaks. Significant implementation effort for marginal feel improvement.
- [ ] **Elemental status effects** — Fire ignites (DoT), cold chills (slow), lightning shocks (increased damage). Trigger: elemental damage types feel too similar. Major complexity increase.
- [ ] **Partial map progress on death** — Keep currency + some % of items based on packs killed. Trigger: death penalty feels too harsh. Changes risk/reward balance significantly.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Sequential pack combat | HIGH | MEDIUM | P1 |
| Armor vs physical formula | HIGH | LOW | P1 |
| Resistance vs elemental formula | HIGH | LOW | P1 |
| Evasion = dodge chance | HIGH | LOW | P1 |
| Energy shield as buffer HP | HIGH | LOW | P1 |
| Death = lose progress, keep currency | HIGH | LOW | P1 |
| Random pack count | MEDIUM | LOW | P1 |
| Packs drop currency, maps drop items | HIGH | LOW | P1 |
| Biome damage distributions | HIGH | LOW | P1 |
| Damage type system (phys/fire/cold/lightning) | HIGH | LOW | P1 |
| Energy shield recharge mid-combat | MEDIUM | MEDIUM | P2 |
| Elemental damage preview | MEDIUM | LOW | P2 |
| Visible damage breakdown | LOW | MEDIUM | P2 |
| Biome-specific pack elemental variance | LOW | MEDIUM | P3 |
| ES recharge rate modifiers | LOW | MEDIUM | P3 |
| Evasion entropy system | LOW | HIGH | P3 |
| Elemental status effects | MEDIUM | HIGH | P3 |

**Priority key:**
- P1: Must have for v1.2 launch — core combat loop
- P2: Should have in v1.x iterations — polish and feedback-driven improvements
- P3: Nice to have in v2+ — depth features after product-market fit

## Competitor Feature Analysis

| Feature | Path of Exile | Diablo 3 | Idle ARPGs (Lootlands, Melvor) | Our Approach |
|---------|---------------|----------|-------------------------------|--------------|
| Armor formula | `Armor / (Armor + 5 * Damage)` — damage-relative | `Armor / (Armor + 50 * Level)` — level-relative | Simple % reduction or none | **PoE formula** — damage-relative creates interesting scaling, armor useful vs many small hits but weak vs one-shots |
| Resistance cap | 75% base, can raise to 85%+ with investment | 75% (earlier versions used different systems) | Often uncapped or simple % reduction | **75% hard cap** — simpler than PoE's "over-cap" system, maintains challenge |
| Evasion | Entropy-based pseudo-random (guaranteed hit every ~N attacks) | Not a primary mechanic (dodge was removed) | Pure % reduction or none | **Pure RNG with diminishing returns** for v1.2, entropy later if needed. Simpler implementation. |
| Energy shield | Recharges after 2s, high investment builds | Not present (shields are armor) | Rare in idle ARPGs | **PoE-style 2s delay** — proven mechanic, creates risk/reward decisions |
| Death penalty | Lose 10% XP in maps, 0% in acts. Hardcore = character deleted | Lose gold and time (corpse run), no permanent loss | Varies: some have no death, others lose progress | **Lose map progress, keep currency** — roguelite pattern (Hades, Dead Cells). Fair for idle game. |
| Pack-based combat | Large, dense packs with magic/rare modifiers | Medium packs, champion/elite packs | Often single enemies or abstract "waves" | **Sequential packs with HP pools** — borrows PoE density concept, adapts for idle/turn-based |
| Damage types | Physical + 5 elemental (fire/cold/lightning/chaos/phys-as-element) | Physical + 6 elemental + specific types (poison, bleed) | Often simplified to "damage" | **Physical + 3 elemental** (fire/cold/lightning) — proven trinity, simpler than PoE/D3 |
| Loot split (currency vs items) | Both drop from monsters and chests | Both drop from monsters and events | Varies widely | **Packs = currency, completion = items** — unique split that makes death less punishing |

## Damage Reduction Formula Comparison

### Path of Exile Armor (RECOMMENDED)

**Formula:** `DR% = Armor / (Armor + 5 × RawDamage)`

**Pros:**
- Scales with incoming damage (effective vs many small hits)
- Diminishing returns prevent immunity
- Well-tested across 10+ years
- Makes armor valuable without being overpowered

**Cons:**
- Less effective vs one-shots
- Harder to communicate to players ("why did my 5000 armor not protect me?")

**Example:** 1000 armor vs 100 damage = 1000/(1000+500) = 66.6% reduction. Same armor vs 500 damage = 1000/(1000+2500) = 28.6% reduction.

**Implementation notes:** Requires per-hit calculation. Can't pre-calculate "armor = X% reduction" because it depends on damage amount.

### Diablo 3 Armor

**Formula:** `DR% = Armor / (Armor + 50 × CharacterLevel)`

**Pros:**
- Predictable reduction % (doesn't vary by hit)
- Easier to communicate ("your armor gives 60% reduction")
- Simpler calculation (compute once per combat, not per hit)

**Cons:**
- Requires level scaling to remain relevant
- Flat % reduction less interesting mechanically
- Can lead to "armor is everything" or "armor is useless" depending on tuning

**Example:** 5000 armor at level 70 = 5000/(5000+3500) = 58.8% reduction. Always 58.8% regardless of incoming damage.

**Implementation notes:** Can pre-calculate reduction % at combat start. Store as `armor_dr: float`. Apply to all physical hits.

### Verdict

**Use PoE formula** for armor (damage-relative). More interesting mechanically, rewards balanced defense building (armor + HP + ES, not just armor stacking). Makes armor strong vs pack damage (many medium hits) but requires other defenses (HP/ES) for boss one-shots. This fits the pack-based combat model where most damage comes from repeated pack hits.

## Combat Tick Rate Analysis

### Old School RuneScape
- Client-side actions: 20ms tick
- Combat: 3-6 ticks per attack (600ms-1200ms per hit)
- **Takeaway:** Sub-second combat feels responsive even in automated system

### Idle Clans
- Attack meter fills based on weapon interval
- When full, automatic attack executes
- **Takeaway:** Variable speed based on weapon stats creates build diversity

### Our Approach
For v1.2, use **fixed 1-second tick rate** for simplicity:
- Every 1 second, hero attacks current pack (if alive)
- Pack attacks hero back (if alive)
- Calculate damage, apply mitigation, update HP
- If pack HP <= 0, pack defeated, roll currency drops, advance to next pack
- If hero life <= 0, hero dies, end map

**Why 1 second:**
- Human-readable (players can follow combat)
- Matches common idle game update frequency
- Simple to implement: `timer += delta; if timer >= 1.0: do_combat_tick()`
- Can add attack speed modifiers later (0.5s, 1.5s, etc.) without refactoring

**Future enhancement:** Variable attack speed based on weapon stats. Fast weapons (daggers) 0.6s, medium (swords) 1.0s, slow (hammers) 1.4s. Requires storing `attack_interval` and separate timers for hero and pack.

## Pack HP Scaling

### Linear Scaling (NOT RECOMMENDED)
`HP = base_hp × area_level`

**Example:** Base 100 HP. Area 1 = 100 HP. Area 100 = 10,000 HP. Area 200 = 20,000 HP.

**Problem:** Player DPS grows exponentially (item scaling, affixes multiply), but monster HP grows linearly. Later areas become trivial.

### Exponential Scaling (RECOMMENDED)
`HP = base_hp × (growth_rate ^ area_level)`

**Example:** Base 100 HP, growth 1.05. Area 1 = 105 HP. Area 100 = 13,150 HP. Area 200 = 1,739,274 HP.

**Advantage:** Matches exponential DPS growth. Keeps challenge consistent across progression. Kongregate idle game research confirms: "Costs grow exponentially while production grows linearly/polynomially" — applying inverse (HP grows exponentially, DPS grows polynomially) creates healthy challenge curve.

**Our Formula:**
```gdscript
func calculate_pack_hp(base_hp: float, area_level: int) -> float:
    # Growth rate: 1.08 = HP doubles every ~9 levels
    # Balanced against DPS doubling via affix stacking every 10-15 levels
    var growth_rate := 1.08
    return base_hp * pow(growth_rate, area_level)
```

**Tuning:** Growth rate 1.08 means:
- Level 10: 2.16x base HP
- Level 50: 46.9x base HP
- Level 100: 2199x base HP
- Level 200: 4.8M× base HP

Adjust growth_rate based on testing. Too high = wall. Too low = trivial.

## Existing System Integration

### StatCalculator Extension

Current `StatCalculator` supports:
- `calculate_dps()` — offensive stats
- `calculate_flat_stat()` — flat additions
- `calculate_percentage_stat()` — percentage modifiers

**Add defensive functions:**

```gdscript
## Calculates physical damage reduction from armor using PoE formula
## DR = Armor / (Armor + 5 * RawDamage)
static func calculate_armor_reduction(armor: float, raw_damage: float) -> float:
    if armor <= 0 or raw_damage <= 0:
        return 0.0
    return armor / (armor + 5.0 * raw_damage)

## Calculates elemental damage reduction from resistance
## Capped at 75% (0.75) to prevent immunity
static func calculate_resist_reduction(resistance: float) -> float:
    var capped_resist := min(resistance, 75.0)
    return capped_resist / 100.0

## Calculates dodge chance from evasion using diminishing returns
## Formula: evasion / (evasion + 500) capped at 75%
static func calculate_dodge_chance(evasion: float) -> float:
    if evasion <= 0:
        return 0.0
    var chance := evasion / (evasion + 500.0)
    return min(chance, 0.75)
```

### LootTable Integration

Current `LootTable` supports:
- `roll_currency_drops(area_level)` — already perfect for pack drops
- `roll_rarity(area_level)` — for map completion item drops
- `get_item_drop_count(area_level)` — for map completion

**Use existing system:**
- When pack dies: `var currency_drops = LootTable.roll_currency_drops(area_level)`
- Add to temporary "run currency" pool (not GameState until map complete or death)
- On map completion: `var item_drops = LootTable.roll_items(area_level)`
- On hero death: Move "run currency" to GameState, discard "run items"
- On map complete: Move "run currency" + "run items" to GameState

### GameState Extension

Current `GameState` has:
- `hero: Hero` — with equipped items
- `currency_counts: Dictionary` — hammer inventory
- `add_currencies(drops: Dictionary)` — perfect for post-run rewards

**Add combat state:**

```gdscript
var current_map_area_level: int = 1
var current_pack_index: int = 0
var packs: Array[MonsterPack] = []
var run_currency: Dictionary = {}  # Earned but not yet committed
var run_items: Array[Item] = []    # Earned but not yet committed
var hero_current_life: float = 0
var hero_current_es: float = 0
```

## Sources

### Damage Reduction Formulas
- [Damage reduction | PoE Wiki](https://www.poewiki.net/wiki/Damage_reduction) — HIGH confidence, official PoE mechanics
- [Armour | PoE Wiki](https://www.poewiki.net/wiki/Armour) — HIGH confidence, armor formula details
- [Diablo 3 Damage Reduction Explained - Maxroll.gg](https://maxroll.gg/d3/resources/damage-reduction-explained) — HIGH confidence, D3 armor formula
- [PoE 2 Guide: Armour Explained](https://mobalytics.gg/poe-2/guides/armour) — MEDIUM confidence, recent PoE2 changes (formula updated to Armor/(Armor + 12×Damage))

### Energy Shield Mechanics
- [Energy shield | PoE Wiki](https://www.poewiki.net/wiki/Energy_shield) — HIGH confidence, 2-second delay confirmed
- [PoE 2 Guide: Energy Shield Explained](https://mobalytics.gg/poe-2/guides/energy-shield) — MEDIUM confidence, confirms ES = extra HP pool, recharge delay

### Resistance Mechanics
- [Resistance | PoE Wiki](https://www.poewiki.net/wiki/Resistance) — HIGH confidence, 75% cap standard
- [PoE 2 Guide: Resistances Explained](https://mobalytics.gg/poe-2/guides/resistances) — MEDIUM confidence, confirms cap mechanics
- [So resistances at lvl 75+? :: Last Epoch](https://steamcommunity.com/app/899770/discussions/0/4295943164870872152/) — MEDIUM confidence, comparison to other ARPGs

### Evasion/Dodge Mechanics
- [Evasion Tome Guide | Megabonk Wiki](https://megabonk.org/database/tomes/evasion-tome) — LOW confidence, diminishing returns formula example
- [Path Of Exile Mechanics Explained: Evasion & Entropy System](https://www.poecurrency.com/news/path-of-exile-evasion-entropy-system) — MEDIUM confidence, entropy vs pure RNG
- [Armor, Evasion, or Energy Shield? Best Defensive Stat | Path of Exile 2](https://game8.co/games/Path-of-Exile-2/archives/497440) — MEDIUM confidence, comparative analysis

### Death Penalty Patterns
- [Permadeath - Wikipedia](https://en.wikipedia.org/wiki/Permadeath) — MEDIUM confidence, general roguelike patterns
- [On Roguelikes and Progression Systems – Indiecator](https://indiecator.org/2022/03/30/on-roguelikes-and-progression-systems/) — MEDIUM confidence, roguelite vs roguelike distinction
- [Roguelite Games With The Best Progression Systems](https://gamerant.com/roguelite-games-with-best-progression-systems/) — LOW confidence, examples of keep-currency patterns

### Damage Types
- [Damage Types - Official Grim Dawn Wiki](https://grimdawn.fandom.com/wiki/Damage_Types) — HIGH confidence, physical + elemental trinity standard
- [Learn the Different Damage Types - Torchlight: Infinite](https://www.chaptercheats.com/cheat/pc/573300/torchlight-infinite/hint/175036) — MEDIUM confidence, confirms fire/cold/lightning as standard elemental trio
- [[Discussion] Damage Types in ARPG's - Crate Entertainment Forum](https://forums.crateentertainment.com/t/discussion-damage-types-in-arpgs/45441) — LOW confidence, design philosophy discussion

### Idle Game Combat Patterns
- [How to design idle games • Machinations.io](https://machinations.io/articles/idle-games-and-how-to-design-them) — MEDIUM confidence, boss as roadblock, passive farming vs active pushing
- [The Math of Idle Games, Part I](https://blog.kongregate.com/the-math-of-idle-games-part-i/) — HIGH confidence, Kongregate research on exponential vs linear scaling
- [Game tick - OSRS Wiki](https://oldschool.runescape.wiki/w/Game_tick) — HIGH confidence, tick rate examples
- [Combat - Idle Clans wiki](https://wiki.idleclans.com/index.php/Combat) — MEDIUM confidence, attack meter pattern

### Pack-Based Mapping
- [Map | PoE Wiki](https://www.poewiki.net/wiki/Map) — MEDIUM confidence, pack size as variable map attribute
- [Monster | PoE Wiki](https://www.poewiki.net/wiki/Monster) — MEDIUM confidence, normal/magic/rare pack composition

---
*Feature research for: Pack-based Idle ARPG Combat*
*Researched: 2026-02-16*
