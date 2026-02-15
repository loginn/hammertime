# Project Research Summary

**Project:** Hammertime v1.1 - Defensive Affixes & Currency Gating
**Domain:** ARPG Crafting Idle Game (Godot 4.6 GDScript)
**Researched:** 2026-02-15
**Confidence:** HIGH

## Executive Summary

The v1.1 milestone extends Hammertime's existing tag-based affix system to support defensive equipment crafting and area-gated progression. Research confirms that **all four features (defensive prefixes, expanded affixes, currency area gating, drop rate rebalancing) integrate cleanly through extension, not architectural modification**. The existing codebase already contains the necessary infrastructure through its ItemAffixes autoload (unlimited affix definitions), LootTable static class (area-aware drop generation), and Resource-based data model (extensible without refactoring).

The recommended approach follows ARPG industry standards: flat/percentage defensive stat split (Path of Exile model), elemental resistance separation (table stakes for the genre), and threshold-based currency gating (clearer than pure RNG). All technologies are already validated - Godot 4.6 with GDScript requires no external libraries or plugins. The primary risk is tag filter explosion causing empty affix pools for some item types, which is mitigated by establishing tag taxonomy before adding any affixes and testing pool sizes per item type.

**Key takeaway:** This is pure content and balance work, not systems engineering. The architecture supports unlimited expansion. Success depends on data discipline (tag taxonomy, affix pool documentation) and quantitative tuning (simulation-based drop rate testing), not technical complexity.

## Key Findings

### Recommended Stack

**No stack changes required.** The existing Godot 4.6 + GDScript stack handles all v1.1 features through data model extension.

**Core technologies:**
- Godot 4.6: Already configured for mobile rendering; recent GDScript profiling improvements optimize affix pool iteration (negligible performance impact with 15-20 total prefixes)
- GDScript 4.6: Type-safe Resource extensions already power the data model; no language additions needed
- Autoload pattern: Four existing autoloads (ItemAffixes, Tag, GameState, GameEvents) are sufficient; new features fit existing architecture

**What NOT to add:**
- Loot table plugins (project has custom LootTable.gd with area-based weighting already implemented)
- State machine libraries (area gating is simple boolean unlock state, not complex transitions)
- Weighted choice plugins (LootTable.roll_rarity() already implements weighted random correctly)

**Critical pattern:** Tag-based filtering (Item.has_valid_tag()) enables unlimited affix expansion without code changes - just add Affix definitions to ItemAffixes.prefixes[] and suffixes[] arrays.

### Expected Features

**Must have (table stakes):**
- Defensive prefixes on armor slots - ARPGs universally have armor/evasion/energy shield prefixes; non-weapon items currently have zero prefixes, making them uncraftable
- Elemental resistance split - Individual fire/cold/lightning resistances are table stakes (current "Elemental Reduction" suffix is too generic)
- Defense scaling with item level - Defensive affixes must use T1-T8 tier scaling like offensive affixes to remain competitive
- Currency drop rate progression - Higher areas must drop rarer currencies; currently all 6 hammers have equal chance across all 4 areas

**Should have (competitive advantage):**
- Deterministic currency gating - Threshold-based unlock ("Grand Hammer unlocks in area 3") is clearer than pure RNG and differentiates from competitors
- Tag-based affix pool clarity - Showing valid tags in tooltips reduces trial-and-error crafting
- Defense type specialization - Different armor slots having different valid tags (rings=ES, boots=movement) creates build variety

**Defer (v2+):**
- Hybrid defense prefixes - Armor+Evasion single-slot affixes add complexity; defer until basic defensive system validates
- Visual prefix/suffix separation - UI polish that waits for 6-affix rare items to create clutter
- Suffix expansion beyond resistances - Focus prefixes first; suffixes already have 15 types

**Critical insight:** Industry analysis shows affix pool size matters more than affix variety - Path of Exile suffers from "dead mod" problems with 100+ affixes per slot, while Last Epoch succeeds with 15-25 focused affixes. Recommendation: Start with 15-20 defensive affixes total, avoid bloat.

### Architecture Approach

**Extension through existing patterns, no refactoring required.** The v1.1 features integrate via four clean extension points:

**Major components:**
1. **ItemAffixes autoload** - Extend prefixes[] with defensive definitions (Tag.ARMOR, Tag.ENERGY_SHIELD); extend suffixes[] with resistance splits; tag-based filtering automatically routes new affixes to correct item types
2. **LootTable static class** - Add min_area_level gating to roll_currency_drops(); modify RARITY_WEIGHTS and currency_rules constants for rebalancing; area-aware logic already present
3. **StatCalculator** - Add calculate_defense() method (mirrors existing calculate_dps() pattern); handles new StatType enum values for armor/evasion/ES calculations
4. **GameState autoload** - Add current_area_level field for currency gating reference; add area_unlock_status Dictionary if hard gates needed (simple O(1) lookup)

**Integration pattern:** Defensive prefixes flow through existing Item.add_prefix() → has_valid_tag() filter → StatCalculator.calculate_defense() → Item.update_value(). No new data flow, just new affix definitions matched to non-weapon item types.

**Build order:** Defensive Prefixes (1-2 hours) → Expanded Suffixes (30 min) → Currency Gating (1-2 hours) → Drop Rebalancing (15-30 min). Features are fully independent with zero dependencies between them.

### Critical Pitfalls

1. **Tag Filter Explosion** - Adding defensive prefixes with ARMOR/HELMET/BOOTS tags can cause weapons to get empty affix pools if tag taxonomy isn't established first. **Prevention:** Define mutually exclusive tag groups (WEAPON_ONLY, ARMOR_ONLY, ANY_ITEM) before adding affixes; test valid_prefixes.size() for each item type after changes.

2. **StatType Enum Expansion Breaking Calculator** - Adding INCREASED_ARMOR, FLAT_EVASION to Tag.StatType enum requires corresponding StatCalculator functions. Missing these causes items to show 0 for new stats despite having affixes. **Prevention:** Add StatType enum + calculator function in same commit; use match statements with wildcard fallback for unhandled cases.

3. **Area Bonus Drop Concentration** - Current bonus drop system (`for i in range(area_level - 1): drops[random_currency] += 1`) assumes all currencies are eligible. Area-gating reduces eligible pool, concentrating bonuses into unlocked currencies and creating exponential reward curves (area 1 awards 3-4x intended runic hammers). **Prevention:** Adjust bonus drops by unlocked currency count, or gate at UI/consumption instead of drop generation.

4. **Display-Only Stats Creating Confusion** - Defensive stats display prominently but don't affect combat until later milestone. Players optimize for high armor, equip defensive items over offensive items, then die because armor does nothing. **Prevention:** Add "(not yet functional)" to stat display, gray out text, or hide defensive stats until combat integration begins.

5. **Affix Pool Dilution** - Adding 12 defensive prefixes to existing 9 weapon prefixes doesn't dilute weapons (tag filtering protects them), but dilutes armor items from "guaranteed one of 3 options" to 1/12 (8.3%) probability for specific mod. **Prevention:** Document affix counts per tag category before adding; flag if pool exceeds 15 affixes per category without targeted crafting currencies.

6. **Rebalancing Without Anchors** - Tweaking RARITY_WEIGHTS to "feel better" without baseline metrics causes directionless iteration. **Prevention:** Record current drop rates before changes, define target metrics (items/hour, crafts per area), use simulation for validation instead of subjective feelings.

## Implications for Roadmap

Based on research, suggested phase structure (4 phases, 3-6 hours total development):

### Phase 1: Defensive Prefix Foundation
**Rationale:** Defensive prefixes are the foundation for all other features - unblocks non-weapon item crafting and establishes tag taxonomy that governs affix pool expansion. Must come first to prevent tag filter explosion.

**Delivers:**
- 6 core defensive prefixes (flat armor, %armor, flat evasion, %evasion, flat ES, %ES)
- Tag expansion (Tag.JEWELRY for rings)
- StatType expansion (INCREASED_ARMOR, FLAT_EVASION, INCREASED_EVASION, FLAT_ENERGY_SHIELD, INCREASED_ENERGY_SHIELD)
- StatCalculator.calculate_defense() method
- Updated Armor/Helmet/Boots/Ring.update_value() to use defense calculator

**Addresses:** Table stakes - defensive prefixes on armor items, defense scaling with item level
**Avoids:** Tag filter explosion (establish taxonomy first), StatType enum breaks (add enums + calculator together), display-only stat confusion (add UI disclaimer)

**Research flag:** Standard patterns - tag filtering and StatCalculator extension follow existing codebase patterns exactly. No additional research needed.

### Phase 2: Elemental Resistance Split
**Rationale:** Builds on Phase 1's StatType expansion. Resistances are suffixes (separate from prefix work), allowing parallel development or sequential add-on. Simple data addition with zero new mechanics.

**Delivers:**
- 4 new suffixes (fire resistance, cold resistance, lightning resistance, all resistance)
- Replaces generic "Elemental Reduction" suffix
- Uses existing StatType.FIRE_RESIST, COLD_RESIST, LIGHTNING_RESIST (already exist in Tag.gd)

**Addresses:** Table stakes - elemental resistance split (ARPG genre standard)
**Uses:** StatCalculator pattern from Phase 1

**Research flag:** Standard patterns - suffix addition identical to Phase 1 prefix addition. No research needed.

### Phase 3: Currency Area Gating
**Rationale:** Independent from affix work. Can develop in parallel or after Phases 1-2. Requires careful design of gating mechanism to avoid area bonus drop concentration.

**Delivers:**
- Currency.min_area_level field (default 1)
- Set min_area_level in each Currency subclass (Runic: 1, Forge: 2, Grand: 3, Claw: 4, Tuning: 1, Tack: 1)
- GameState.current_area_level field
- Modified LootTable.roll_currency_drops() with area-level gating before probability rolls
- Optional ramping logic (low drop chance when just unlocked, scales up over 2 levels)

**Addresses:** Table stakes - currency drop rate progression by area; Differentiator - deterministic currency gating
**Avoids:** Area bonus drop concentration (design gating separate from probability checks, simulate before committing)

**Research flag:** Moderate complexity - bonus drop distribution requires simulation testing to verify linear (not exponential) reward curve. Consider running 100-clear simulation per area level before finalizing.

### Phase 4: Drop Rate Rebalancing
**Rationale:** Must come LAST. Rebalancing requires all content in place (defensive affixes + currency gating) to tune against actual gameplay loop. Tuning too early wastes effort when mechanics change.

**Delivers:**
- Modified LootTable.RARITY_WEIGHTS (reduce rare% at low levels: area 1 = 0% rare instead of 2%)
- Modified currency_rules (reduce advanced currency chances by 30-50%)
- Baseline metrics documented (current: 1.2 items/clear at area 1, 0.18 magic, 0.02 rare)
- Target metrics defined (goal: 1 rare per 30 clears at area 1)

**Addresses:** Table stakes - item rarity progression by area
**Avoids:** Rebalancing without anchors (document baseline, define targets, simulate before committing)

**Research flag:** Requires playtesting - no amount of research replaces empirical testing. Plan for iteration: initial tuning → playtest → adjust → re-test. Create simulation script first (roll_rarity 1000 times per area, record distribution).

### Phase Ordering Rationale

- **Phases 1-2 are data work** (add affixes, add StatTypes) with zero risk to existing systems - tag filtering protects weapons from defensive prefix additions
- **Phase 3 is mechanics work** (currency gating) that's independent from affixes - can run in parallel with Phases 1-2 or sequentially
- **Phase 4 requires all content in place** - can't balance drop rates without knowing full affix pool size and currency unlock thresholds
- **No dependencies between Phases 1-2-3** - defensive prefixes, resistance suffixes, and currency gating are orthogonal features
- **Phase 4 depends on 1-2-3 completion** - rebalancing is final tuning pass

### Research Flags

**Phases needing deeper research during planning:**
- **Phase 3 (Currency Area Gating):** Requires simulation script to validate drop distribution. Create `drop_simulator.gd` that runs 1000 area clears, logs currency counts, verifies linear reward curve (not exponential). Medium complexity - pattern exists in LootTable.gd but scaling math needs verification.

**Phases with standard patterns (skip research-phase):**
- **Phase 1 (Defensive Prefix Foundation):** Tag filtering and StatCalculator extension follow existing codebase patterns exactly (compare: weapon prefixes in ItemAffixes.gd lines 3-37, StatCalculator.calculate_dps() lines 15-45)
- **Phase 2 (Elemental Resistance Split):** Suffix addition identical to existing suffix definitions (ItemAffixes.gd lines 39-78)
- **Phase 4 (Drop Rate Rebalancing):** Constant modification only; research can't predict "feels good" - empirical playtesting required instead

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All recommendations validated against existing Godot 4.6 codebase; no external dependencies required; patterns proven in current implementation |
| Features | HIGH | Multiple ARPG source comparisons (PoE, D4, Last Epoch) confirm table stakes; feature prioritization matrix clear; MVP scoped to 6 defensive prefixes + 4 resistances |
| Architecture | HIGH | Integration points verified in codebase; extension patterns (not refactoring) keep risk low; build order has zero dependencies between Phases 1-2-3 |
| Pitfalls | HIGH (code analysis) / MEDIUM (patterns) | Critical pitfalls derived from codebase analysis (tag filtering, StatType enum, area bonus math); industry pattern pitfalls (pool dilution, rebalancing) verified via WebSearch |

**Overall confidence:** HIGH

### Gaps to Address

**Defensive stat combat integration timeline:** Research assumes defensive stats are display-only in v1.1 (combat integration happens in later milestone). If combat integration is required for v1.1, add Phase 5 for combat math (damage reduction formulas, resistance caps, defense vs offense scaling). This was not in scope for current research.

**Area count expansion:** Research assumes 4 areas (current codebase state). If area count expands to 5+ during v1.1, currency gating thresholds need recalibration (currently: Runic/Tack=1, Forge=2, Grand=3, Claw=4). Monitor PROJECT.md for area expansion requirements.

**Hybrid defense prefixes complexity:** Research deferred hybrid affixes to v2.0+. If user feedback during Phase 1-2 shows affix slot pressure (players want more stats per affix), re-evaluate hybrid prefix addition. Currently flagged as "add after validation" not "never add."

**Affix pool size limits:** Research recommends 15-20 defensive affixes total to avoid pool dilution. If design requires more affixes (e.g., adding life/mana/movement prefixes in addition to armor/ES/evasion), implement targeted crafting currencies (Armorer's Hammer, Jeweler's Hammer) to prevent 1/30 crafting odds.

**Drop rate "feels good" calibration:** Phase 4 requires playtesting - no research substitute. Budget 2-3 iteration cycles: initial tuning (30 min) → playtest session (1 hour) → adjustments (15 min) → re-test. Consider external playtesters (internal testers know drop rates are tuned, real players don't).

## Sources

### Primary (HIGH confidence)
- Existing Hammertime codebase (`/var/home/travelboi/Programming/hammertime/`) - Architecture patterns, tag filtering implementation, LootTable area scaling, StatCalculator formulas
- [Godot 4.6 Release](https://godotengine.org/releases/4.6/) - Confirmed January 27, 2026 release, GDScript performance improvements
- [Godot Resources Documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html) - Resource extension patterns via @export
- [Item Affixes for Gear - Diablo 4 Wowhead Guide](https://www.wowhead.com/diablo-4/guide/gear-items/affixes) - Defensive affix patterns, table stakes identification
- [Gear Walkthrough - Last Epoch Maxroll.gg](https://maxroll.gg/last-epoch/resources/gear-walkthrough) - Focused affix pool approach (15-25 affixes)
- [Defences - PoE Wiki](https://www.poewiki.net/wiki/Defences) - Flat/percentage defensive stat split, hybrid mod structure

### Secondary (MEDIUM confidence)
- [Path of Exile 2 Defense and Resistance Guide](https://www.sportskeeda.com/mmo/exile-2-poe2-defense-resistance-guide-energy-shield-armor-evasion) - Resistance suffix patterns
- [Diablo 4 World Tiers Guide - Mobalytics](https://mobalytics.gg/blog/diablo-4/world-tiers-guide/) - Area-gated currency drop progression
- [Drop rate - PoE Wiki](https://www.poewiki.net/wiki/Drop_rate) - Quantitative drop rate testing patterns
- [Path of Exile 2 affix pool dilution discussion](https://www.pathofexile.com/forum/view-thread/3659293) - Hybrid mod complexity pitfalls
- [Loot drop best practices](https://www.gamedeveloper.com/design/loot-drop-best-practices) - Industry patterns for drop rate ramping, anchor-based tuning

### Tertiary (LOW confidence - needs validation)
- [Weighted Random Selection With Godot](http://kehomsforge.com/tutorials/single/weighted-random-selection-godot/) - Validated existing LootTable pattern (tutorial matches implementation)
- [Managing Virtual Economies: Inflation Domination](https://www.gamedeveloper.com/business/managing-virtual-economies-inflation-domination) - Currency scarcity principles (generic, not ARPG-specific)

---
*Research completed: 2026-02-15*
*Ready for roadmap: yes*
