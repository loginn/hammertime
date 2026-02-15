# Feature Research

**Domain:** ARPG Defensive Affixes, Expanded Affix Pools, and Currency/Item Drop Gating
**Researched:** 2026-02-15
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Defensive prefixes on armor items | ARPGs universally have flat/percent armor, evasion, energy shield on equipment slots. All 9 current prefixes require Tag.WEAPON - non-weapon items are prefix-less. | LOW | Add Tag.ARMOR, Tag.HELMET, Tag.BOOTS tags; create flat armor, %armor, flat evasion, %evasion, flat energy shield, %energy shield prefixes (6 new prefixes minimum) |
| Hybrid defense prefixes | PoE, Last Epoch, and Diablo use hybrid mods (armor+evasion, armor+ES, evasion+ES) that take 1 affix slot but grant 2 stats - space-efficient defense stacking | MEDIUM | 3 hybrid prefixes (armor+evasion, armor+ES, evasion+ES); requires stat_types array to support multiple StatType values; only on body armor/helmet |
| Elemental resistance suffixes | Resistances are suffixes in every major ARPG (PoE, D4, Last Epoch). Currently "Elemental Reduction" suffix exists but no fire/cold/lightning split | LOW | Add individual fire/cold/lightning resistance suffixes, plus "all resist" for space efficiency; 4 new suffixes |
| Defense scaling with item level/tier | Defensive affixes must scale T1-T8 like offensive affixes do currently. Higher tier = better defense = competitive with damage scaling | LOW | Already have tier system in Affix class; new defensive affixes use same tier multiplier (9-tier) formula |
| Currency drop rate progression by area | Diablo 4 World Tiers and PoE map tiers gate high-value currency to endgame areas. Currently all 6 hammers have equal chance across all 4 areas | MEDIUM | LootTable.roll_currency_drops() needs area-level-based chance scaling; lower areas drop basic hammers (Runic/Tack), higher areas add rare hammers (Grand/Tuning) |
| Item rarity progression by area | Sacred/Ancestral items in D4, item level gates in PoE - endgame areas must drop better base rarities. LootTable.RARITY_WEIGHTS already does this (area 4 = 65% Rare vs area 1 = 2% Rare) | LOW | Already implemented; verify weights feel correct during playtesting |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not required, but valuable.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Deterministic currency gating | Instead of RNG-based rare currency drops, gate currencies to specific areas - "Grand Hammer unlocks in Cursed Woods (area 3)" makes progression transparent | LOW | Replace roll_currency_drops() independent chances with area thresholds: areas 1-2 (Runic/Tack only), areas 3-4 (add Forge/Grand), area 4 (add Claw/Tuning) |
| Tag-based affix pool clarity | Item shows valid tags in tooltip - "This helmet can roll: DEFENSE, ARMOR, HELMET" - players know what's possible before wasting hammers | MEDIUM | Add Item.get_valid_tags_display() method; integrate into UI item tooltip; educates on crafting possibilities |
| Visual prefix/suffix separation in UI | Color-code or section prefixes (offensive) vs suffixes (defensive) in item display - faster gear evaluation | LOW | Update views/item_view.gd to render prefixes/suffixes in separate sections with labels; improves readability |
| Defense type specialization | Ring/boots/helmet have different valid tags - rings get ENERGY_SHIELD only, boots get MOVEMENT, helmets get hybrid options - creates slot identity | MEDIUM | Update Item subclasses' valid_tags arrays; prevents homogeneous gearing, adds build variety |
| Currency tooltips show use cases | "Runic Hammer: Adds 1-2 mods to Normal items, making them Magic" with valid rarity transitions - reduces trial-and-error learning | LOW | Add Currency.get_tooltip() returning rich text with examples; integrate into views/crafting_view.gd |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Too many niche affixes | "Add 50+ affixes for build diversity like PoE" | Creates "useless affix" problem - players find 80% of affixes worthless, dilutes mod pool, frustrates crafting. PoE community constantly complains about dead mods on class-specific items. | Focus on 15-20 universally useful defensive affixes; every affix should be good for SOME build, not 5% of builds |
| Per-monster currency drops | "Currency should drop from every kill like D4" | Floods economy, causes inflation, makes high-value currencies feel common. Research shows games need currency sinks to prevent devaluation. | Keep area-clear-based currency drops (current system); preserves scarcity, makes hammers feel valuable |
| Unlimited affix rerolling | "Let me reroll specific affixes infinitely" | Removes crafting tension, makes perfect items trivial, exhausts endgame in hours. D4 faced backlash for making loot too deterministic. | Keep Tuning Hammer's reroll as rare currency; limit uses per item session; force trade-offs |
| Complex hybrid affixes everywhere | "Every affix should be hybrid for efficiency" | Hybrid mods in PoE are complex (armor+evasion+stun recovery on one line) - reduces clarity, harder to evaluate items quickly. | Limit hybrids to defensive prefixes on body armor/helmet; suffixes stay single-stat for clarity |
| Per-difficulty currency types | "Add D4-style torment-only currencies" | Fragments economy, confuses new players, creates 6+ parallel currency tracks. Mobile games avoid this by separating hard/soft currencies, not 10 tiers. | Use single currency set across all areas; gate by drop chance, not by creating new currency types |
| Class-specific affixes | "Weapons should roll skill-specific mods" | Without class system, creates "wrong class" affix problem - Sentinel relics rolling Cold Damage when Sentinels can't use cold (Last Epoch complaint). | Tag system already prevents - weapons roll WEAPON tags, armor rolls ARMOR tags; no class-specific affixes |

## Feature Dependencies

```
Defensive Prefix System
    └──requires──> Tag Expansion (ARMOR, HELMET, BOOTS, ENERGY_SHIELD, EVASION)
                       └──requires──> StatType Expansion (FLAT_EVASION, INCREASED_ARMOR, etc.)

Hybrid Defense Prefixes
    └──requires──> Multi-StatType Support (stat_types array handles 2+ values)
    └──requires──> StatCalculator.calculate_defense() update

Currency Area Gating
    └──requires──> LootTable.roll_currency_drops() refactor
    └──enhances──> Progression clarity (players know when new hammers unlock)

Elemental Resistance Split
    └──requires──> New suffixes (fire_res, cold_res, lightning_res, all_res)
    └──replaces──> Generic "Elemental Reduction" suffix

Defense Specialization by Slot
    └──requires──> Updated valid_tags per Item subclass
    └──conflicts──> Homogeneous gearing (if all slots roll same mods)
```

### Dependency Notes

- **Defensive Prefix System requires Tag Expansion:** Cannot add defensive prefixes without ARMOR/EVASION/ENERGY_SHIELD tags - current Tag.gd has DEFENSE but no granular defense types. Must add tags before creating affixes.
- **Hybrid Defense Prefixes require Multi-StatType Support:** Affix.stat_types is Array[int] - already supports multiple values. Need to verify StatCalculator aggregates multiple stat_types correctly (e.g., hybrid armor+evasion should add to both stats).
- **Currency Area Gating enhances Progression clarity:** Current independent drop chances obscure when new hammers become available. Gating Grand Hammer to area 3+ tells players "reach Cursed Woods to unlock advanced crafting."
- **Defense Specialization conflicts with Homogeneous gearing:** If all armor slots can roll all defensive affixes, build variety suffers (everyone stacks armor). Specialization forces choices - rings for ES, boots for movement+evasion, helmets for hybrid armor.

## MVP Definition

### Launch With (v1.1 Milestone)

Minimum viable expansion - what's needed to make non-weapon items craftable.

- [x] **6 Defensive Prefixes** - Flat armor, %armor, flat evasion, %evasion, flat ES, %ES; essential to unblock helmet/armor/boots crafting
- [x] **Tag Expansion** - Add ARMOR, HELMET, BOOTS, ENERGY_SHIELD, EVASION to Tag.gd; update Item subclass valid_tags arrays
- [x] **StatType Expansion** - Add FLAT_EVASION, INCREASED_ARMOR, INCREASED_EVASION, FLAT_ENERGY_SHIELD, INCREASED_ENERGY_SHIELD to Tag.StatType enum
- [x] **Elemental Resistance Split** - Replace generic "Elemental Reduction" with fire_res, cold_res, lightning_res, all_res suffixes; aligns with ARPG standards
- [x] **Currency Area Gating** - Refactor LootTable.roll_currency_drops() to gate currencies by area threshold: Runic/Tack (area 1+), Forge/Grand (area 3+), Claw/Tuning (area 4 only)
- [x] **Drop Rate Rebalancing** - Test currency drop rates with gating; adjust RARITY_WEIGHTS if rare items drop too frequently in early areas

### Add After Validation (v1.2+)

Features to add once defensive prefixes prove functional.

- [ ] **Hybrid Defense Prefixes** - Armor+Evasion, Armor+ES, Evasion+ES (trigger: if players complain about affix slot pressure on defensive items)
- [ ] **Visual Prefix/Suffix Separation** - Color-code or section item display (trigger: when UI feels cluttered with 6 affixes on rare items)
- [ ] **Defense Specialization by Slot** - Ring = ES only, Boots = Movement+Evasion, Helmet = Hybrid options (trigger: if all slots feel same-y during gearing)
- [ ] **Tag-based Affix Pool Tooltips** - Show valid tags on item hover (trigger: if playtesters waste hammers on invalid crafting attempts)
- [ ] **Currency Tooltips** - Rich text descriptions with use cases (trigger: if new players confused about hammer purposes)

### Future Consideration (v2.0+)

Features to defer until core defensive system validated.

- [ ] **Suffix Expansion** - Life regen, mana regen, magic find, block chance (defer: focus on prefixes first, suffixes already have 15 types)
- [ ] **Rarity-Specific Affixes** - T0 affixes that only roll on Rare items (defer: adds complexity, validate core system first)
- [ ] **Crafting Benchmarks** - Guaranteed affix crafting at cost of currency (defer: requires economy balancing, might trivialize RNG)
- [ ] **Multi-tier Rarity** - Sacred/Ancestral item bases like D4 (defer: requires area expansion beyond 4 zones)

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Defensive prefixes (6 affixes) | HIGH | LOW | P1 |
| Tag expansion (5 new tags) | HIGH | LOW | P1 |
| StatType expansion (5 new enums) | HIGH | LOW | P1 |
| Elemental resistance split (4 suffixes) | HIGH | LOW | P1 |
| Currency area gating | HIGH | MEDIUM | P1 |
| Drop rate rebalancing | MEDIUM | LOW | P1 |
| Hybrid defense prefixes (3 affixes) | MEDIUM | MEDIUM | P2 |
| Visual prefix/suffix separation | MEDIUM | LOW | P2 |
| Defense specialization by slot | MEDIUM | MEDIUM | P2 |
| Tag-based affix pool tooltips | LOW | MEDIUM | P2 |
| Currency tooltips | LOW | LOW | P2 |
| Suffix expansion (4-5 affixes) | LOW | LOW | P3 |
| Rarity-specific affixes | LOW | HIGH | P3 |
| Crafting benchmarks | MEDIUM | HIGH | P3 |
| Multi-tier rarity (Sacred/Ancestral) | LOW | HIGH | P3 |

**Priority key:**
- P1: Must have for launch - unblocks non-weapon crafting
- P2: Should have, add when possible - improves UX after core works
- P3: Nice to have, future consideration - requires economy/balance validation

## Competitor Feature Analysis

| Feature | Path of Exile | Diablo 4 | Last Epoch | Our Approach |
|---------|---------------|----------|------------|--------------|
| Defensive prefixes | Flat armor, %armor, flat evasion, %evasion, flat ES, %ES on all armor slots; hybrid mods common | Armor, damage reduction as primary stats; affixes scale with item power (925 max) | Prefixes are offense/utility, suffixes are defense; 2 prefix + 2 suffix limit | Follow PoE model - flat/percent split, hybrid mods for efficiency; 3 prefix + 3 suffix on Rare items already matches PoE |
| Elemental resistances | Individual fire/cold/lightning suffixes, plus "all resist" hybrid; capped at 75% in endgame | Individual resistances as suffixes; World Tier gates max resistance values | Suffix-based; tier 1-7 scaling determines value range | Split "Elemental Reduction" into fire/cold/lightning/all_res; follow PoE/LE suffix model |
| Currency gating | Map tiers gate Exalted/Divine orb drops; campaign areas drop Transmutation/Augmentation only | World Tiers gate Sacred/Ancestral item drops and high-tier currency; torment levels add complexity | Endgame monoliths drop more advanced currency; campaign has lower drop rates | Threshold-based gating (area 1-2 = basic, 3-4 = advanced) vs pure RNG; clearer than PoE, simpler than D4 torment system |
| Item rarity progression | Normal/Magic/Rare/Unique; chaos/exalt spam for endgame crafting; very RNG-heavy | Normal/Magic/Rare/Legendary; Sacred/Ancestral tiers at World Tier 3-4; item power 925 cap | Normal/Magic/Rare/Unique/Set; Legendary system for target farming; less RNG than PoE | Normal/Magic/Rare (no Unique yet); area-based rarity weights already implemented; matches PoE structure without complexity |
| Affix pool size | 100+ affixes per item slot; notorious for "dead mod" problem - 80% of affixes useless | 20-30 affixes per slot; streamlined vs PoE but still has useless affixes (life regen complaints) | 15-25 affixes per slot; focused pool avoids dead mods; best balance of depth/clarity | Start with 15-20 defensive affixes; avoid PoE's bloat, aim for LE's focused approach |
| Hybrid affixes | Common on armor (armor+evasion, armor+ES, etc.); reduces affix slot pressure | Rare; most affixes single-stat for clarity | Hybrid mods noted with asterisk; displayed across 2 lines for readability | Limit to defensive prefixes on body armor/helmet; suffixes stay single-stat |

## Sources

- [Item Affixes for Gear - Diablo 4 Wowhead Guide](https://www.wowhead.com/diablo-4/guide/gear-items/affixes)
- [Gear Walkthrough - Last Epoch Maxroll.gg](https://maxroll.gg/last-epoch/resources/gear-walkthrough)
- [Defences - PoE Wiki](https://www.poewiki.net/wiki/Defences)
- [Path of Exile 2 Defense and Resistance Guide](https://www.sportskeeda.com/mmo/exile-2-poe2-defense-resistance-guide-energy-shield-armor-evasion)
- [Design Philosophy of Affixes - PoE Forum](http://www.pathofexile.com/forum/view-thread/544912)
- [Defining Loot Tables in ARPG Game Design - Gamedeveloper.com](https://www.gamedeveloper.com/design/defining-loot-tables-in-arpg-game-design)
- [Top ARPGs in 2026 - Tribality](https://www.tribality.com/articles/top-action-rpgs-arpgs-in-2026-the-best-isometric-loot-driven-games/)
- [Drop rate - PoE Wiki](https://www.poewiki.net/wiki/Drop_rate)
- [Diablo 4 World Tiers Guide - Mobalytics](https://mobalytics.gg/blog/diablo-4/world-tiers-guide/)
- [PoE 2 Crafting for Beginners - Item Modifiers - Mobalytics](https://mobalytics.gg/poe-2/guides/crafting-basics-part-1)
- [Prefixes - Body Armor - Last Epoch Database](https://www.lastepochtools.com/db/category/chest/prefixes)
- [Useless Affixes Discussion - No Rest For The Wicked Forum](https://forum.norestforthewicked.com/t/some-affixes-are-useless/14131)
- [Managing Virtual Economies: Inflation Domination - Gamedeveloper.com](https://www.gamedeveloper.com/business/managing-virtual-economies-inflation-domination)

---
*Feature research for: ARPG Defensive Affixes & Currency Gating*
*Researched: 2026-02-15*
