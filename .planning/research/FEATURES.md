# Feature Research

**Domain:** ARPG Idle Prestige/Reset Meta-Progression — Hammertime v1.7
**Researched:** 2026-02-20
**Confidence:** MEDIUM (genre conventions from WebSearch verified across multiple idle game sources; ARPG-specific affix/tier patterns from Last Epoch wiki and official forums HIGH confidence; prestige reset/persist split from community analysis and Kongregate math series MEDIUM confidence)

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features users of idle ARPG prestige systems consider non-negotiable. Missing these makes the prestige loop feel broken or punishing rather than rewarding.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Prestige currency grant on reset | All idle prestige systems award a persistent currency for resetting. Without it, there's no incentive to reset — the loop breaks | LOW | New `prestige_points: int` field on GameState; awarded on prestige trigger; survives all future resets |
| Full reset of area level and gear on prestige | Players understand prestige as "start over but stronger" — keeping gear breaks the identity of the system and removes the early-game surge feeling | MEDIUM | On prestige: `area_level = 1`, `hero.equipment = {}`, `crafting_inventory = {type: []}`, `currencies = {}`. Prestige points and unlock tier survive |
| Visible prestige cost before commit | Every idle game with a prestige cost shows the cost, current progress toward it, and what you'll get before the player commits — hidden costs cause rage quits | LOW | PrestigeView (new tab or overlay): shows `prestige_level`, `prestige_points`, cost for next prestige, unlocks from next prestige |
| Permanent unlock that persists across resets | The prestige reward must feel meaningful. Unlocking new content (item tiers, hammer types) is a standard ARPG idle prestige reward pattern | MEDIUM | Item tier cap increases per prestige level (Prestige 0 = tier 1-2, Prestige 1 = tier 1-4, ..., Prestige 6 = tier 1-8). Tag-targeted hammers unlock at Prestige 1 |
| Faster early re-progression after prestige | Post-prestige early content should clear faster than the first run — the "power rush" feeling. Without it, players feel punished rather than rewarded | HIGH | Prestige points spent on a multiplier that boosts area XP/drop rates, OR item tier unlocks naturally accelerate the power curve (better items drop earlier) |
| Confirmation dialog before prestige | Every prestige-gated system has a "are you sure?" confirm. ARPG players are especially sensitive to accidental resets of crafted gear | LOW | Two-step prestige confirm: "Prestige? This resets area, gear, and inventory. Prestige points and tier unlocks persist." followed by confirm button |
| Prestige level display on main UI | Players should always know what prestige level they're on — it's an identity marker. Hidden prestige level = invisible progression | LOW | Small prestige level indicator in hero view or persistent HUD element; "Prestige 2" or star/level icon |

### Differentiators (Competitive Advantage)

Features that give Hammertime's prestige loop a distinct identity. Not required by genre convention, but meaningful for the specific crafting-first design.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Item tier gating as prestige reward (unlock tier range, not just multiplier) | Most idle prestige systems reward number multipliers. Hammertime's reward is access to qualitatively different items — this ties prestige directly to the crafting identity rather than adding a separate number layer | HIGH | 8 item tiers; prestige level unlocks tier ceiling (P0=T2, P1=T4, P2=T5, P3=T6, P4=T7, P5=T7+, P6=T8). Area-level-weighted drop distribution within unlocked range |
| 32-tier affix system (4 tiers per item tier) | 8 tiers is too coarse for 7 prestige levels — incremental gear power feels flat. 32 tiers (4 per item-tier band) creates granular, visible upgrade paths that feel meaningful across a 30-hour prestige loop | HIGH | Expand `AffixDB` tier ranges from max 8 → max 32; values scale linearly within each item-tier band of 4 affix tiers. Existing `Vector2i tier_range` architecture supports this with a constant bump |
| Tag-targeted crafting hammers as Prestige 1 unlock | Standard crafting is random within prefix/suffix slot. Tag-targeted hammers (FireHammer guarantees a fire affix) introduce deliberate crafting as a prestige reward — this is the same design leap PoE2 made with Omens and essences, but simplified for an idle context | HIGH | New hammer subclasses with tag filter: `_do_apply()` checks `affix.tags.has(required_tag)` before rolling; rejects and re-rolls within valid pool. These are rarer than standard hammers, unlocked only after P1 |
| Currency-gated prestige trigger (not level-gated) | Level-gating prestige (e.g., "reach level 100") is common but passive. Currency-gating ("spend 500 prestige shards") requires players to actively run content, creating a concrete farming goal instead of waiting for a number to tick up | MEDIUM | New `prestige_shard` currency type; drops from Shadow Realm (area 75+) at low rate; cost scales per prestige level (P0→P1: 100, P1→P2: 250, ..., P6→P7: impossible by design — 7 total) |
| Area-level-weighted drop within unlocked tier range | Items shouldn't always drop at max unlocked tier — that removes the late-game loot surge. Higher area levels weight toward higher item tiers, creating visible gear progression within a single prestige run | MEDIUM | `LootTable` uses `area_level` to bias tier selection within `[1, max_unlocked_tier]`; low levels favor tier 1-2, high levels favor tier ceiling. Sqrt ramp pattern (already in codebase) applied to tier weight |
| Prestige unlock display (what each level gives) | Showing players the future unlocks ("Prestige 3: Unlock item tiers 5-6, Cold Hammer available") creates goal orientation across multiple resets. Players tolerate 3 resets to get there if they can see the destination | LOW | Static unlock table in PrestigeView listing all 7 prestige levels with their unlocks; current level highlighted; future levels shown as "locked" |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Gear persists through prestige | Reduces punishment anxiety; players don't want to lose crafted items | Defeats the prestige loop entirely — the power rush after reset comes from being forced through weaker content with better meta-knowledge. If gear persists, the early-game becomes trivially easy and players skip it, removing the feeling of progression | Full gear reset. The unlock of higher item tiers makes each subsequent run's gear ceiling higher, which is the correct reward |
| Per-prestige infinite scaling (no level cap) | "More prestige = always stronger" seems straightforward | Without a level cap, balancing the endgame becomes impossible. Hammertime's 7-prestige design (unlocking 8 item tier levels and all tag hammers) gives a designed end state. Beyond that, balance collapses and content runs out | Hard cap at 7 prestige levels. Prestige 7 is the "complete" state with all item tiers and all tag hammers unlocked |
| Prestige currency from all areas (not just endgame) | Players want prestige shards everywhere so they can prestige faster | Removes the design logic of prestige as an endgame reward. If shards drop in Forest, players prestige repeatedly through early areas with no incentive to reach Shadow Realm | Prestige shards drop only from Shadow Realm (area 75+); this gate means players must complete a full run before prestiging |
| Chaos/full reroll of affix tiers on prestige items | Higher item tiers should feel craftable with "perfect" affixes | Full rerolls allow bricking runs by making items too random — Hammertime explicitly excluded chaos-style rerolls as a design decision. This remains anti-feature even at higher tiers | Existing hammer set applies to all tiers; the TackHammer prefix removal and Grand Hammer reroll are the controlled intervention points |
| Visual tier indicators on items in inventory list | Players want to immediately know item tier from the slot view | Adds significant UI complexity to a mobile-first 1280x720 viewport with 10 items per slot. The bench shows tier via the item details on selection | Show item tier in the bench detail view (already shows affix quality); slot list shows count not per-item details |
| Separate prestige-only item pool (exclusive drops) | "Prestige items" as separate category feels rewarding | Creates a parallel loot track that must be balanced alongside the existing track, doubling content scope. Item tier is the correct prestige reward, not a separate item category | Higher prestige = higher item tier ceiling = qualitatively better items from the existing pool |
| Partial prestige (reset some things, keep others) | Less punishing, seems fair | Undermines the "power rush" effect that makes prestige psychologically rewarding. Research consistently shows partial resets feel less impactful than full resets — players feel they didn't really commit. The full reset + permanent gain is the complete emotional arc | Full reset with generous permanent unlocks (item tiers + hammers) compensates for the loss |

---

## Feature Dependencies

```
[Prestige Points System]
    └──required-by──> [Prestige Trigger UI]
    └──required-by──> [Prestige Cost Scaling]
    └──persists-through──> [Prestige Reset]

[Prestige Reset]
    └──resets──> [Area Level]
    └──resets──> [Hero Equipment]
    └──resets──> [Crafting Inventory]
    └──resets──> [All Currencies (incl. regular hammers)]
    └──does-NOT-reset──> [Prestige Points]
    └──does-NOT-reset──> [Prestige Level / Tier Unlocks]
    └──does-NOT-reset──> [Tag-Targeted Hammer Unlocks]

[Item Tier Gating]
    └──requires──> [Prestige Level] (tier ceiling = f(prestige_level))
    └──required-by──> [32-Tier Affix Expansion] (tiers map to item tier bands)
    └──required-by──> [Area-Level-Weighted Tier Drops] (weight needs a ceiling)
    └──required-by──> [Item Display: show item tier]

[32-Tier Affix Expansion]
    └──requires──> [Item Tier Gating] (affix tiers 1-4 = item tier 1, etc.)
    └──requires──> [AffixDB refactor] (tier_range max bumped from 8 → 32)
    └──impacts──> [StatCalculator] (value ranges change; scaling math needed)
    └──impacts──> [SaveManager] (affix tier values in save; migration required)

[Tag-Targeted Hammers]
    └──requires──> [Prestige Level >= 1] (unlock gate)
    └──requires──> [Existing Tag system] (Tag.FIRE, Tag.COLD, etc. already exist)
    └──requires──> [Currency template method] (new subclasses of base Currency)
    └──requires──> [LootTable] (new hammer types added to drop pool post-P1)
    └──enhances──> [Crafting Loop] (deterministic targeting as prestige reward)

[Prestige Shard Currency]
    └──required-by──> [Prestige Trigger] (cost paid in shards)
    └──requires──> [LootTable] (shard added to Shadow Realm drop pool)
    └──resets-on──> [Prestige Reset] (shards consumed to trigger; leftover shards reset)

[Prestige UI]
    └──requires──> [Prestige Points System]
    └──requires──> [Item Tier Gating] (shows unlock table)
    └──requires──> [Prestige Shard Currency] (shows cost and current count)
```

### Dependency Notes

- **Item tier gating is the root unlock, not a bonus:** If item tier unlocks are wrong (wrong ceiling, wrong drop weights), the entire prestige loop feels broken. Build and validate this before tag-targeted hammers.
- **32-tier affix expansion requires item tier gating first:** Affix tiers 1-32 are organized as 4 tiers per item tier band. The item tier concept must exist before expanding affix tiers.
- **Tag-targeted hammers require existing tag infrastructure:** Hammertime already has `Tag.FIRE`, `Tag.COLD`, `Tag.LIGHTNING`, `Tag.DEFENSE` tags on affixes. New hammer subclasses filter by tag, not by implementing new tag logic. This is LOW-risk if built after the Currency template method is confirmed stable.
- **SaveManager migration required for affix tier expansion:** Existing saves have affix tier values in [1, 8]. After expanding to 32 tiers, old saves must migrate: multiply existing tier by 4 to map old tier 1 → new tier 4 (worst), old tier 8 → new tier 32 (best). This is the ARPG convention (tier 1 = best in Hammertime, so direction matters).
- **Prestige shard resets on prestige:** Shards are the trigger cost and do not persist. A player who fails to prestige before a run ends loses leftover shards. This creates a natural "commit when ready" tension.

---

## MVP Definition

### Launch With (v1.7 milestone)

Minimum viable prestige loop. Must validate the full reset + permanent unlock pattern.

- [ ] **Prestige points awarded on prestige** — GameState adds `prestige_points: int` and `prestige_level: int` (0–7); both persist through resets
- [ ] **Prestige shard currency** — New `PrestigeShard` drops from area 75+ via LootTable; does not ramp-unlock (Shadow Realm gate is sufficient)
- [ ] **Prestige trigger with cost** — PrestigeView shows current shards, cost for next level, and confirm dialog; validates `prestige_shards >= cost` before executing
- [ ] **Full reset on prestige** — `area_level = 1`, hero equipment cleared, crafting inventory cleared, all standard currencies zeroed; `prestige_level`, `prestige_points`, tag-hammer unlocks survive
- [ ] **Item tier gating by prestige level** — `MAX_ITEM_TIER[prestige_level]` lookup table (e.g., [2, 4, 5, 6, 6, 7, 7, 8]); LootTable references this ceiling when selecting dropped item tier
- [ ] **Area-level-weighted item tier drops** — LootTable selects item tier using sqrt-weighted distribution within [1, MAX_ITEM_TIER]; low areas weight toward tier 1-2, high areas weight toward ceiling
- [ ] **32 affix tiers (4 per item tier band)** — AffixDB expands tier ranges; value scale recalculated so tier 1 (best) is proportionally stronger than current tier 1; SaveManager migration maps old tier * 4 → new tier scale
- [ ] **Tag-targeted hammers at Prestige 1** — FireHammer, ColdHammer, LightningHammer subclasses; drop from LootTable only when `prestige_level >= 1`; `_do_apply()` filters affix pool by required tag
- [ ] **Prestige UI panel** — Shows: prestige level, cost to next prestige (in shards), current shards, prestige unlock table (all 7 levels with what each unlocks), confirm button
- [ ] **Save format v3** — Adds `prestige_level`, `prestige_points` to save; migrates affix tiers in all saved items; SAVE_VERSION bumped; v2→v3 migration defined

### Add After Validation (v1.x)

- [ ] **Post-prestige drop rate bonus** — Small multiplier on shard and currency drop rates per prestige level; only if playtesting reveals re-progression feels too slow
- [ ] **"Prestige N" badge in hero view** — Visual identity marker; only if players report not knowing their prestige level without opening the UI
- [ ] **Per-prestige unlock tooltips** — Hover over locked prestige in the table to see "Requires X shards" and "Unlocks: Y"; only if the static table is confusing

### Future Consideration (v2+)

- [ ] **Stat-targeted hammers** — Explicitly out of scope per PROJECT.md; listed here as natural next extension of tag-targeted hammers
- [ ] **Outcome-locking hammers** — Protect specific mods while rerolling; out of scope for v1.7 per PROJECT.md
- [ ] **Hero archetypes** — PROJECT.md explicitly defers to post-prestige milestone; archetypes layered on top of the established prestige loop
- [ ] **Prestige-exclusive biome** — A 5th biome (Void, etc.) that only unlocks at Prestige 3+; future milestone if the 4-biome structure feels complete to players after prestige

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Prestige shard currency + drop | HIGH | LOW | P1 |
| Prestige trigger + reset + confirm | HIGH | MEDIUM | P1 |
| Item tier gating by prestige level | HIGH | MEDIUM | P1 |
| Area-level-weighted tier drops | HIGH | MEDIUM | P1 |
| 32-tier affix expansion + value rescale | HIGH | HIGH | P1 |
| Tag-targeted hammers (Fire/Cold/Lightning) | HIGH | MEDIUM | P1 |
| Prestige UI panel | HIGH | MEDIUM | P1 |
| Save format v3 + migration | HIGH | MEDIUM | P1 |
| Post-prestige drop rate bonus | MEDIUM | LOW | P2 |
| Prestige badge in hero view | LOW | LOW | P2 |
| Unlock tooltip on locked prestige row | LOW | LOW | P2 |
| Stat-targeted hammers | MEDIUM | HIGH | P3 |
| Outcome-locking hammers | MEDIUM | HIGH | P3 |
| Hero archetypes | HIGH | HIGH | P3 |

**Priority key:**
- P1: Required for v1.7 milestone — the feature is the milestone
- P2: Polish after core prestige works; add if playtesting reveals friction
- P3: Deferred; separate milestone with design justification

---

## Prestige System Design Principles

Derived from Kongregate's idle math series, community feedback on Endless World Idle RPG, Revolution Idle guides, and Last Epoch's affix tier progression research. Organized for Hammertime's specific decisions.

### (1) Reset Scope: Full Reset is Correct

Community research consistently shows partial resets feel less impactful than full resets. The "power rush" emotional arc — the feeling of being overpowered through early content you struggled with before — requires a full reset. Keeping gear removes this arc entirely.

**Hammertime application:** Reset area level, all equipment, all inventory, and all standard currencies. Keep prestige level, prestige points, and unlock state. This is the standard prestige contract.

### (2) Prestige Currency: Lifetime-Based, Not Since-Last-Reset

Kongregate's idle math series documents two prestige currency models: lifetime-based (total ever earned) and since-reset (earned this run). For ARPG content with crafting, since-reset is the correct model — it rewards players for completing more of the current run before prestiging, creating a natural "go as far as possible" incentive.

**Hammertime application:** Prestige shards drop from the endgame area (Shadow Realm) throughout the run. Players accumulate shards over multiple runs if they don't meet the threshold. The cost scales with prestige level to prevent immediate back-to-back resets.

### (3) Item Tier Gating: Quality, Not Quantity

The prestige reward should change what players can craft and equip, not just how fast they do it. Multiplier-only prestige (double drop rates) produces diminishing returns and fails to create new crafting decisions. Item tier unlocks create qualitatively new affixes and power ceiling changes that players can see and plan toward.

**Hammertime application:** Each prestige level unlocks a higher item tier ceiling. At Prestige 0, players can only find tier 1-2 bases. At Prestige 6 (max), players access all 8 item tiers. Affix values are meaningfully higher on tier 7-8 items than on tier 1-2 items — this must be noticeable, not marginal.

### (4) Tag-Targeted Hammers: Prestige Reward for Deliberate Crafting

PoE2's Patch 0.3 deterministic crafting via Omens (same-tag-family guaranteed mods) and Last Epoch's shard-based targeted crafting both show that ARPG players strongly value being able to target specific affix types. For Hammertime, introducing this at Prestige 1 serves as the single most impactful prestige reward beyond item tier access — players can now guarantee a fire or cold affix, enabling build-oriented crafting for the first time.

**Hammertime application:** FireHammer, ColdHammer, LightningHammer each apply affixes exclusively from their element's tag pool. They are rarer than standard hammers, require Prestige 1 unlock, and otherwise use the existing Currency template method pattern.

### (5) 32 Affix Tiers: Avoid Tier Compression at Top End

With 8 item tiers, having only 8 affix tiers means each item tier maps to a single affix tier — no granularity within a tier band. Last Epoch's forum post on introducing T6 and T7 affixes documents player frustration when gear upgrades feel like cliffs (suddenly much better) rather than ramps. 4 affix tiers per item tier band creates a visible upgrade path within each prestige level's item tier range.

**Hammertime application:** Affix tiers 1-4 map to item tier 1, tiers 5-8 to item tier 2, ..., tiers 29-32 to item tier 8. Tier 1 remains "best" per existing convention. Values should be balanced so the gap between adjacent affix tiers is noticeable but not cliff-like.

### (6) Prestige Cost: Steep Enough to Feel Earned

Community data from Revolution Idle and Endless World forums shows two failure modes: prestige costs too low (players prestige before meaningful progression; resets feel trivial) and too high (players grind for multi-day sessions with nothing to do; engagement collapses). The sweet spot is a cost that requires completing 60-80% of the current run's content to accumulate.

**Hammertime application:** Shadow Realm (area 75+) is the prestige shard source. Players must survive into the final biome before accumulating enough shards. The first prestige should be achievable in 2-4 hours of play on a first run; later prestiges take longer due to cost scaling but are faster due to better meta-unlocks.

---

## Integration Points with Existing Hammertime System

| Existing Component | Current State | Required Change for v1.7 | Complexity |
|-------------------|---------------|--------------------------|------------|
| `GameState` | `prestige_level` absent | Add `prestige_level: int = 0`, `prestige_points: int = 0`; both persist through reset | LOW |
| `GameState.initialize_fresh_game()` | Creates fresh hero, currencies, inventory | Called on prestige; must preserve `prestige_level` and `prestige_points` before and restore after | MEDIUM |
| `LootTable` | Currency + item drops per pack | Add `PrestigeShard` to Shadow Realm drop pool; add tag-targeted hammer types to post-P1 pool | MEDIUM |
| `ItemAffixes` (AffixDB) | 8 affix tiers max (`tier_range` Vector2i) | Expand tier_range upper bounds to 32; recalculate value scale per tier; all existing affixes affected | HIGH |
| `Item` | `tier: int` field (1-8 item tier) | No change to model; LootTable now determines tier from prestige-gated ceiling and area level weight | LOW |
| `LootTable` item tier selection | Currently unweighted or simple | Add `_weighted_item_tier(area_level, max_tier)` using sqrt ramp pattern (already in codebase for currency) | MEDIUM |
| `Currency` base class | Template method with `_do_apply()` | New subclasses: `FireHammer`, `ColdHammer`, `LightningHammer` override `_do_apply()` to filter by tag | MEDIUM |
| `SaveManager` | `SAVE_VERSION = 2` | Bump to `3`; add `prestige_level`, `prestige_points` to schema; affix tier migration (old * 4 = new scale equivalent) | HIGH |
| `ForgeView` | 6 currency buttons | Add tag-hammer buttons (Fire/Cold/Lightning) hidden until P1; shown/enabled when unlocked | MEDIUM |
| New: `PrestigeView` | Does not exist | New scene: prestige level, shard count, cost, unlock table, confirm button; tab in main_view or overlay | MEDIUM |

---

## Sources

**Idle game prestige system design (MEDIUM confidence — WebSearch, multiple sources agree):**
- [The Math of Idle Games, Part III — Kongregate Blog](https://blog.kongregate.com/the-math-of-idle-games-part-iii/) — Lifetime vs. since-reset prestige currency models; bumpy progression design; prestige currency doubling math
- [Revolution Idle Prestige Guide — Tap Guides](https://tap-guides.com/2025/10/24/revolution-idle-prestige-guide/) — When to prestige, cost balance, persistent upgrade patterns
- [Endless World Idle RPG Community Thread — Steam](https://steamcommunity.com/app/840260/discussions/0/1637543304828072083/) — Player frustration with high prestige costs; multi-day grind causes disengagement; community solutions
- [Reset Milestones — TV Tropes](https://tvtropes.org/pmwiki/pmwiki.php/Main/ResetMilestones) — Genre conventions for what resets vs. persists documented across many games
- [Top 7 Idle Game Mechanics — Mobile Free to Play](https://mobilefreetoplay.com/top-7-idle-game-mechanics/) — Prestige as one of 7 core idle mechanics; design intent

**ARPG affix tier gating (HIGH confidence — Last Epoch official sources):**
- [Introducing Tier 6 and 7 Item Affixes — Last Epoch Dev Blog](https://forum.lastepoch.com/t/introducing-tier-6-and-7-item-affixes/22279) — Official developer post on adding higher tiers; player frustration with tier cliffs; rationale for granular tiers
- [Level Requirements and Affix Levels Breakpoints — Last Epoch Forums](https://forum.lastepoch.com/t/level-requirements-and-affix-levels-breakpoints/35382) — How affix tiers map to item level requirements; area-level gating patterns
- [Affixes — Last Epoch Game Guide (lastepochtools.com)](https://www.lastepochtools.com/guide/section/affixes) — Affix tier structure, tier 5 crafting cap, T6/T7 as drop-only
- [Crafting Basics Guide — Last Epoch Maxroll.gg](https://maxroll.gg/last-epoch/resources/beginner-crafting-guide) — Shard-based targeted crafting; forging potential as crafting limiter

**Deterministic and tag-targeted crafting (MEDIUM confidence — PoE2 sources):**
- [PoE 2 0.3 Deterministic Crafting Guide — AOEAH](https://www.aoeah.com/news/4116--poe-2-03-guaranteed-mods-crafting-guide--how-to-craft-bis-gear-jewels-rings-weapon-armor) — Tag-family targeted mod addition via Omens; same-tag guarantee mechanic
- [PoE 2 Abyssal League Deterministic Crafting — MMOJUGG](https://www.mmojugg.com/news/poe-2-abyssal-league-deterministic-crafting-path.html) — Tag system for filtering mods; deterministic paths documented
- [Crafting Basics: Metacrafting — POE Maxroll.gg](https://maxroll.gg/poe/crafting/metacrafting) — Prefix/suffix locking patterns; tag-based crafting bench mods

**Loot table design (MEDIUM confidence — game dev article):**
- [Defining Loot Tables in ARPG Game Design — Game Developer](https://www.gamedeveloper.com/design/defining-loot-tables-in-arpg-game-design) — Affix rarity grouping by item tier; area-level weighted selection

**Codebase analysis (HIGH confidence — direct code review of Hammertime v1.6):**
- `game_state.gd` — `prestige_level` absent; `initialize_fresh_game()` structure confirms reset scope
- `currency.gd` — Template method pattern; `_do_apply()` override structure confirmed for new tag-hammer subclasses
- `loot_table.gd` — Current drop pool structure; sqrt ramp pattern already implemented for currency gating
- `item_affixes.gd` — `Vector2i tier_range` per affix; current max tier confirmed as 8
- `save_manager.gd` — `SAVE_VERSION = 2`; schema structure for migration planning

---

*Feature research for: Hammertime v1.7 Prestige Meta-Progression System*
*Researched: 2026-02-20*
*Confidence: MEDIUM overall (ARPG affix patterns HIGH; idle prestige conventions MEDIUM; tag-targeted crafting design MEDIUM)*
