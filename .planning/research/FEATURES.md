# Feature Research

**Domain:** ARPG Item Rarity and Crafting Currency Systems
**Researched:** 2026-02-14
**Confidence:** MEDIUM

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Visual rarity differentiation (colors) | Standard across ALL ARPGs since Diablo (1996) - white/blue/yellow is industry convention | LOW | Normal=white, Magic=blue, Rare=yellow. User expectations are hardcoded. |
| Rarity determines mod count limits | Core ARPG mechanic - Normal=0, Magic=1+1, Rare=3+3. Path of Exile, Last Epoch, Diablo all use this structure. | LOW | Already partially implemented - existing code has 3 prefix/3 suffix limits. Need to add rarity-based enforcement. |
| Currency shows preview/validation before use | Users expect to know what will happen - "Can I use this?" feedback before clicking | MEDIUM | Need pre-application validation: "This item already has max mods", "This currency requires Magic rarity", etc. |
| Currency application feedback | Users need to see what changed - before/after comparison, highlight new/changed mods | MEDIUM | Visual feedback on success/failure. Highlight mod value changes for Tuning Hammer, show removed mod for Claw Hammer. |
| Drop rate scaling with difficulty | Harder areas = better loot is fundamental ARPG loop. PoE shows 200-1000% rarity increase for magic/rare monsters. | LOW | Area difficulty should influence rarity roll weights. Already have area system. |
| Consistent rarity upgrade paths | Users expect Normal→Magic→Rare to be clear and achievable, not random dead-ends | LOW | Runic (N→M) and Forge (N→R) provide this. Need to ensure no "stuck" states. |
| Mod count visibility | Users must see current mod count vs. max (e.g., "Prefixes: 2/3") to make informed crafting decisions | LOW | Display rarity + current/max mod counts in item tooltip. Critical for decision-making. |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not required, but valuable.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Hammer-themed currency identity | Makes crafting memorable and thematic - "Tack Hammer" vs generic "Orb of Augmentation" creates brand identity | LOW | Already committed to this. Opportunity for visual/audio feedback (hammer striking item). |
| No full-reroll chaos orb equivalent | Reduces RNG frustration - items evolve rather than get bricked and rerolled infinitely | LOW | Explicit design choice. Positions game as "incremental improvement" vs "gambling simulator". |
| Simplified rarity system (no Unique tier) | Reduces complexity for idle game context - 3 tiers vs. 4+ in most ARPGs | LOW | Good for idle/incremental genre. Less to learn, faster to mastery. |
| Claw Hammer (mod removal) at lower rarity | PoE's Orb of Annulment is late-game currency. Early access = more experimentation | MEDIUM | Differentiator if common enough. Risk: too common = trivializes crafting. Needs drop rate balancing. |
| Grand Hammer for Rare augmentation | PoE's Exalted Orb equivalent. Giving this early (vs. ultra-rare) changes crafting accessibility | MEDIUM | Makes perfect rares achievable in reasonable time. Good for idle game pacing. |
| Persistent rarity through modification | Items never downgrade rarity unless explicitly scouring - reduces "bricking" anxiety | LOW | Build on PoE2 pattern where Annulment doesn't downgrade. Psychologically friendlier. |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Deterministic crafting (choose exact mod) | Feels "fair", removes RNG frustration | Removes entire gameplay loop - finding good RNG drops becomes worthless, everything is crafted to perfection | Use tag-based mod pools (already implemented) + targetable currencies with smart weighting. Let users nudge RNG, not eliminate it. |
| Full item reroll (Chaos Orb) | Feels powerful, gives "one more try" when item is bad | Creates degenerate "spam chaos until good" gameplay. Infinite rerolls = no value to drops or incremental progress. | Item melting (future) + incremental modification only. Forces strategic improvement. |
| Rarity downgrade currencies | Seems like it adds flexibility ("I want this Rare to be Magic") | Creates confusing edge cases and no clear use case. Why would you want fewer mods? | Claw Hammer removes mods without rarity change. If you want fewer mods, remove them. Rarity follows as consequence. |
| Guaranteed mod addition (no RNG) | "I should be able to add exactly what I want" | Eliminates itemization progression - perfect items in hours. Destroys long-term engagement. | Grand Hammer adds random mod within tag restrictions. Exalted-style RNG preserved. |
| Complex rarity tiers (Exalted/Fractured/Synthesized) | "More content!" | Feature bloat for idle game. Diablo/PoE complexity inappropriate for incremental genre. | Stick to 3 tiers. Add depth through mod tiers (already have 1-8) and hammer variety. |
| Metamod/block crafting (PoE-style) | Power users want control | Extreme complexity - requires understanding tag system, mod groups, blocking mechanics. Barrier to entry. | Tag-based filtering (already implemented) is sufficient. Keep it accessible. |

## Feature Dependencies

```
[Item Rarity System]
    └──requires──> [Rarity-Based Mod Limits]
                       └──requires──> [Mod Count Validation]

[Rarity Upgrade Currencies (Runic/Forge)]
    └──requires──> [Item Rarity System]
    └──requires──> [Mod Addition Logic]

[Mod Addition Currencies (Tack/Grand)]
    └──requires──> [Rarity Validation] (can't use Grand on Magic)
    └──requires──> [Mod Count Validation] (can't exceed 1+1 or 3+3)

[Claw Hammer (Mod Removal)]
    └──requires──> [Rarity Preservation Logic] (item stays same rarity)
    └──requires──> [Mod Count Tracking]

[Tuning Hammer (Value Reroll)]
    └──requires──> [Mod Value Range System] (already exists: min_value/max_value)
    └──enhances──> [All Other Hammers] (optimize after adding mods)

[Drop Rate Scaling]
    └──requires──> [Area Difficulty System] (already exists)
    └──requires──> [Rarity Weight Tables]

[Crafting Feedback UI]
    └──requires──> [All Currency Systems] (needs to validate each)
    └──enhances──> [User Experience] (prevents confusion/mistakes)
```

### Dependency Notes

- **Item Rarity System requires Rarity-Based Mod Limits:** Cannot enforce Normal=0, Magic=1+1, Rare=3+3 without rarity field on items
- **All Currencies require Rarity Validation:** Each hammer must check "Can I use this on this rarity?" before application
- **Claw Hammer requires Rarity Preservation Logic:** Edge case - removing last mod from Magic item should keep it Magic (0 mods, but Magic rarity) to match PoE pattern
- **Tuning Hammer enhances All Other Hammers:** Natural last step in crafting flow - add mods, then optimize values
- **Crafting Feedback UI requires All Currency Systems:** Must validate against all rules to show accurate previews

## Edge Cases Documentation

### Critical Edge Cases by Currency

#### Runic Hammer (Normal→Magic)
- **Already Magic/Rare:** Cannot use. Show error: "Item must be Normal rarity"
- **Normal with 0 implicit mods:** Still valid. Adds 1-2 explicit mods, upgrades to Magic
- **Result mod count:** Randomly 1 or 2 mods (1 prefix, 1 suffix, or both)

#### Forge Hammer (Normal→Rare)
- **Already Magic/Rare:** Cannot use. Show error: "Item must be Normal rarity"
- **Result mod count:** 4-6 mods (PoE Alchemy pattern). Guarantees "feels rare" result
- **Skip Magic tier entirely:** Direct Normal→Rare is valid path

#### Tack Hammer (Add mod to Magic)
- **Used on Normal:** Cannot use. Show error: "Item must be Magic rarity"
- **Used on Rare:** Cannot use. Show error: "Item must be Magic rarity"
- **Magic already at 1+1:** Cannot use. Show error: "Item has maximum mods (1 prefix, 1 suffix)"
- **Magic with 1 prefix, needs suffix:** Adds random suffix from valid pool
- **No valid mods available:** Cannot use. Show error: "No valid mods available" (edge case: all valid mods already on item)

#### Grand Hammer (Add mod to Rare)
- **Used on Normal/Magic:** Cannot use. Show error: "Item must be Rare rarity"
- **Rare already at 3+3:** Cannot use. Show error: "Item has maximum mods (3 prefixes, 3 suffixes)"
- **Rare with 3 prefixes, 2 suffixes:** Adds random suffix only
- **No valid mods available:** Cannot use. Show error: "No valid mods available"

#### Claw Hammer (Remove mod)
- **Used on Normal (0 mods):** Cannot use. Show error: "Item has no mods to remove"
- **Used on Magic with 1 mod:** Removes mod, **item stays Magic rarity** with 0 mods (PoE pattern)
- **Used on Magic with 2 mods:** Removes random mod (50/50 prefix/suffix), stays Magic
- **Used on Rare with 1 mod:** Removes mod, **item stays Rare rarity** with 0 mods
- **Rarity never downgrades:** Critical rule - Claw Hammer only removes mods, not rarity
- **Random selection:** User cannot choose which mod to remove

#### Tuning Hammer (Reroll values)
- **Used on Normal (0 mods):** Cannot use. Show error: "Item has no mods to reroll" (only implicit exists, don't reroll that)
- **Used on item with mods:** Rerolls ALL explicit mod values within their tier ranges
- **Does not change tiers:** A tier 3 mod stays tier 3, just gets new value within that tier's min/max
- **Does not change mods:** Same mods, different values only
- **Implicit preservation:** Implicit mod value is NOT rerolled

### Rarity State Transitions

```
Normal (0 mods)
    ├─[Runic Hammer]──> Magic (1-2 mods)
    └─[Forge Hammer]──> Rare (4-6 mods)

Magic (0-2 mods)
    ├─[Tack Hammer]──> Magic (1-2 mods) [if not at max]
    ├─[Claw Hammer]──> Magic (0-1 mods) [rarity preserved]
    └─[Cannot downgrade to Normal]

Rare (0-6 mods)
    ├─[Grand Hammer]──> Rare (1-6 mods) [if not at max]
    ├─[Claw Hammer]──> Rare (0-5 mods) [rarity preserved]
    └─[Cannot downgrade to Magic/Normal]

Any rarity with mods
    └─[Tuning Hammer]──> Same rarity, same mods, new values
```

### Validation Flow for Currency Application

1. **Check item rarity matches currency requirement**
   - Runic/Forge: Must be Normal
   - Tack: Must be Magic
   - Grand: Must be Rare
   - Claw/Tuning: Any rarity with mods

2. **Check mod count limits**
   - Tack: Magic must have <2 mods (1 prefix + 1 suffix max)
   - Grand: Rare must have <6 mods (3 prefix + 3 suffix max)
   - Claw: Must have >0 mods to remove

3. **Check valid mod pool availability**
   - Tack/Grand: Must have at least 1 valid mod that's not already on item
   - Tag filtering already implemented in existing code

4. **Show preview/confirmation**
   - "This will add a random [prefix/suffix] to your [Magic/Rare] item"
   - "This will remove a random mod from your item (stays [current rarity])"
   - "This will reroll all mod values within their current ranges"

## MVP Definition

### Launch With (v1) - This Milestone

Minimum viable crafting system for rarity + currency milestone.

- [x] **Item rarity field (Normal/Magic/Rare)** — Core system requirement. Cannot enforce mod limits without it.
- [x] **Rarity-based mod count enforcement** — Normal=0 explicit, Magic=1+1 max, Rare=3+3 max. Prevents invalid states.
- [x] **Runic Hammer (Normal→Magic)** — Primary rarity upgrade path. Adds 1-2 mods.
- [x] **Forge Hammer (Normal→Rare)** — Alternative upgrade path. Adds 4-6 mods. Skips Magic tier.
- [x] **Tack Hammer (Add mod to Magic)** — Completes partial Magic items. Essential for Magic crafting.
- [x] **Grand Hammer (Add mod to Rare)** — Completes partial Rare items. Core late-game currency.
- [x] **Claw Hammer (Remove mod)** — Mistake correction. Allows iterative crafting without bricking items.
- [x] **Tuning Hammer (Reroll values)** — Value optimization. Natural final step in crafting flow.
- [x] **Basic currency validation** — "Can I use this currency on this item?" prevention logic.
- [x] **Rarity-based drop weighting** — Harder areas drop rarer items. Core ARPG loop.
- [x] **Visual rarity indicators** — White/blue/yellow text colors. Industry standard expectation.

### Add After Validation (v1.x)

Features to add once core rarity system is working.

- [ ] **Currency drop rate balancing** — Trigger: After observing crafting progression pacing. Adjust hammer rarity to match desired time-to-perfect-item.
- [ ] **Advanced crafting feedback UI** — Trigger: User confusion about currency usage. Add preview windows, before/after comparisons, mod highlighting.
- [ ] **Rarity-specific visual effects** — Trigger: Items feel samey. Add glow effects, particle systems, sound effects per rarity.
- [ ] **Currency stacking display** — Trigger: Inventory clutter. Show hammer counts more prominently, consolidate space.
- [ ] **Crafting history/undo** — Trigger: User frustration with Claw Hammer RNG. Allow 1-step undo or show "last removed mod" info.
- [ ] **Smart currency suggestions** — Trigger: New user confusion. Highlight usable currencies for selected item.

### Future Consideration (v2+)

Features to defer until core crafting is validated.

- [ ] **Item melting/recycling** — Defer until: Item inventory overflow becomes problem. Converts unwanted items to resources.
- [ ] **Crafting achievements/milestones** — Defer until: Core loop is fun. Meta-progression layer on top of crafting.
- [ ] **Hammer upgrade tiers** — Defer until: Late-game feels stale. Better hammers with modified rules (e.g., "Blessed Tuning Hammer: reroll with +10% to max value").
- [ ] **Fractured/locked mods** — Defer until: Advanced players want more control. PoE-style complexity inappropriate for v1.
- [ ] **Crafting bench/workstation** — Defer until: Crafting feels disconnected from world. Spatial element to hammer usage.
- [ ] **Currency exchange/conversion** — Defer until: Hammer economy is established. Trade unwanted hammers for desired ones.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Item rarity field + enforcement | HIGH | LOW | P1 |
| Visual rarity colors (white/blue/yellow) | HIGH | LOW | P1 |
| Runic Hammer (Normal→Magic) | HIGH | LOW | P1 |
| Forge Hammer (Normal→Rare) | HIGH | LOW | P1 |
| Tack Hammer (add to Magic) | HIGH | MEDIUM | P1 |
| Grand Hammer (add to Rare) | HIGH | MEDIUM | P1 |
| Claw Hammer (remove mod) | MEDIUM | MEDIUM | P1 |
| Tuning Hammer (reroll values) | HIGH | LOW | P1 |
| Currency validation (prevent invalid use) | HIGH | MEDIUM | P1 |
| Drop rate scaling | HIGH | LOW | P1 |
| Mod count visibility (2/3 prefixes) | HIGH | LOW | P1 |
| Advanced crafting feedback UI | MEDIUM | HIGH | P2 |
| Currency drop rate balancing | HIGH | LOW | P2 |
| Rarity visual effects (glow/particles) | MEDIUM | MEDIUM | P2 |
| Crafting history/undo | LOW | MEDIUM | P2 |
| Smart currency suggestions | MEDIUM | MEDIUM | P2 |
| Item melting/recycling | MEDIUM | MEDIUM | P3 |
| Hammer upgrade tiers | LOW | HIGH | P3 |
| Fractured/locked mods | LOW | HIGH | P3 |

**Priority key:**
- P1: Must have for milestone completion - core rarity + all 6 currencies functional
- P2: Should have when polish time available - improves UX, prevents frustration
- P3: Nice to have, future consideration - adds depth but not essential

## Competitor Feature Analysis

| Feature | Path of Exile | Last Epoch | Diablo 3 | Hammertime Approach |
|---------|---------------|------------|----------|---------------------|
| Rarity tiers | Normal/Magic/Rare/Unique (4 tiers) | Normal/Magic/Rare/Exalted/Unique/Legendary (6+ tiers) | Normal/Magic/Rare/Legendary/Set (5 tiers) | **Normal/Magic/Rare (3 tiers)** - Simplified for idle game. No unique tier. |
| Normal→Magic upgrade | Orb of Transmutation (common) | Rune of Shattering (common) | Drops as Magic | **Runic Hammer** - Thematic name, common drop |
| Normal→Rare upgrade | Orb of Alchemy (uncommon) | Rune of Ascendance (rare) | Drops as Rare | **Forge Hammer** - Skips Magic tier entirely |
| Add mod to Magic | Orb of Augmentation (common) | Glyph of Despair (common) | N/A (no crafting on Magic) | **Tack Hammer** - Small hammer for small items |
| Add mod to Rare | Exalted Orb (ultra-rare, tradeable) | Glyph of Despair (common, can't use on Rare) | N/A (limited crafting) | **Grand Hammer** - More accessible than PoE Exalts. Not ultra-rare. |
| Remove mod | Orb of Annulment (rare, random) | Rune of Removal (common, choose which) | N/A | **Claw Hammer** - Random like PoE, preserves rarity |
| Reroll values | Divine Orb (valuable, tradeable) | Glyph of Order (uncommon) | Enchanting (limited) | **Tuning Hammer** - Rerolls ALL mod values at once |
| Full item reroll | Chaos Orb (common, core currency) | Chaos (rare) | N/A | **NONE** - Explicit anti-feature. No chaos spam. |
| Rarity downgrade | Orb of Scouring (clears to Normal) | N/A | N/A | **NONE** - Items only upgrade. Claw Hammer removes mods but preserves rarity. |
| Mod count limits | Magic: 1+1, Rare: 3+3 | Magic: 1+1, Rare: 2+2, Exalted: 4 affixes (T6+) | Rare: Fixed count by slot | **Magic: 1+1, Rare: 3+3** - Matches PoE standard |
| Drop rate scaling | 200-1000% rarity boost for Magic/Rare/Unique mobs | Corruption/Blessing modifiers on zones | Torment difficulty: 1.15^N multiplier per level | **Area difficulty scaling** - Harder areas = rarer drops. Specific formula TBD. |
| Visual differentiation | White/Blue/Yellow/Orange text + 3D art | White/Blue/Yellow/Purple/Orange/Pink + unique models | White/Blue/Yellow/Orange/Green + unique effects | **White/Blue/Yellow text** - Standard colors. Future: glow effects. |

### Key Differentiation Points

1. **Simplified rarity tiers** - 3 instead of 4-6. Better for idle game learning curve.
2. **No chaos orb equivalent** - Forces incremental improvement, not infinite rerolls.
3. **Grand Hammer accessibility** - PoE's Exalted Orbs are ultra-rare economy drivers. Hammertime makes them achievable for solo play.
4. **Rarity preservation** - Claw Hammer doesn't downgrade. Reduces crafting anxiety.
5. **Thematic currency names** - "Hammers" not "Orbs". Fits "Hammertime" brand.
6. **All currencies available early** - PoE gates advanced crafting behind late-game. Hammertime gives all tools upfront, balanced by drop rates.

## Implementation Dependencies on Existing Systems

### Already Exists (Leverage)

- **Affix tier system (1-8)** - Already implemented with tier-based value scaling
- **Tag-based mod filtering** - `has_valid_tag()` in item.gd line 74
- **Mod count limits (3+3)** - Enforced in `add_prefix()` line 83 and `add_suffix()` line 105
- **Duplicate mod prevention** - `is_affix_on_item()` in item.gd line 62
- **Value reroll logic** - `reroll()` in affix.gd line 26-27
- **Item display system** - `get_display_text()` shows current mods
- **Hero equipment slots** - Already calculates DPS/defense from equipped items

### Needs Addition

- **Item rarity field** - Add `enum Rarity {NORMAL, MAGIC, RARE}` to item.gd
- **Rarity-based mod limit enforcement** - Replace hardcoded `>= 3` with rarity-dependent max
- **Currency item class** - New `Currency` class with `can_apply(item)` and `apply(item)` methods
- **Rarity upgrade logic** - Methods for Normal→Magic and Normal→Rare with random mod addition
- **Mod removal logic** - Random mod selection + removal while preserving rarity
- **Visual rarity indicators** - Color-code item names in UI based on rarity
- **Drop rate weighting** - Area difficulty → rarity weights for item/currency drops
- **Currency inventory** - Track hammer counts, show in UI
- **Validation feedback** - "Cannot use because..." messages for blocked currency usage

## Sources

### High Confidence (Official Documentation)

- [Path of Exile Wiki - Rarity](https://www.poewiki.net/wiki/Rarity) - Authoritative source for PoE rarity mechanics
- [Path of Exile Wiki - Orb of Scouring](https://www.poewiki.net/wiki/Orb_of_Scouring) - Mod removal and rarity downgrade mechanics
- [Path of Exile Wiki - Orb of Annulment](https://www.poewiki.net/wiki/Orb_of_Annulment) - Random mod removal without rarity change
- [Path of Exile Wiki - Divine Orb](https://www.poewiki.net/wiki/Divine_Orb) - Value reroll mechanics
- [Path of Exile 2 Crafting Overview - Maxroll.gg](https://maxroll.gg/poe2/resources/path-of-exile-2-crafting-overview) - PoE2 crafting changes and patterns

### Medium Confidence (Verified Web Sources)

- [Last Epoch Crafting Guide - Maxroll.gg](https://maxroll.gg/last-epoch/resources/beginner-crafting-guide) - Alternative ARPG crafting system
- [Diablo Wiki - Item Rarity](https://www.diablowiki.net/Legendary) - Diablo series rarity conventions
- [Path of Exile 2 Currency Guide - NeonLightsMedia](https://www.neonlightsmedia.com/blog/path-of-exile-2-currency-crafting-guide-2026) - Current PoE2 currency mechanics
- [Game UI Database - Crafting](https://www.gameuidatabase.com/index.php?scrn=75) - Crafting UI patterns across games

### Low Confidence (Community/General)

- [TV Tropes - Color-Coded Item Tiers](https://tvtropes.org/pmwiki/pmwiki.php/Main/ColorCodedItemTiers) - Historical context on rarity colors
- [Origins of Color Coded Loot - Tales of the Aggronaut](https://aggronaut.com/2020/09/03/origins-of-color-coded-loot/) - Diablo (1996) origin of white/blue/yellow convention

---
*Feature research for: Hammertime ARPG Crafting - Item Rarity and Currency Systems*
*Researched: 2026-02-14*
