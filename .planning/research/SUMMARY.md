# Project Research Summary

**Project:** Hammertime - ARPG Item Rarity & Crafting Currency System
**Domain:** Incremental ARPG with item crafting mechanics
**Researched:** 2026-02-14
**Confidence:** HIGH

## Executive Summary

This milestone adds rarity tiers (Normal/Magic/Rare) and 6 crafting currencies (Runic, Forge, Tack, Grand, Claw, Tuning Hammers) to an existing ARPG idle game built in Godot 4.5. Research shows that ARPG crafting systems follow well-established patterns from Path of Exile, with rarity determining mod count limits (Normal=0+0, Magic=1+1, Rare=3+3) and currency-based modification rather than full item rerolls. The existing codebase already has 70% of the foundation needed: an affix system with tiers, tag-based filtering, and a 3-hammer crafting UI that can be extended.

The recommended approach is a 4-phase implementation: (1) Add rarity enum and validation infrastructure without breaking existing code, (2) Replace the hardcoded 3-hammer system with 6 specialized currencies using validation-before-mutation patterns, (3) Integrate rarity-weighted drops scaled by area difficulty, and (4) Polish UI feedback and currency balance. All functionality is achievable with Godot 4.5 built-ins (enums, RandomNumberGenerator, Dictionary) - no external dependencies required.

The primary risks are: (a) affix pool exhaustion when Magic items require exactly 1+1 mods but only 2 valid affixes exist for a tag, (b) state desync between crafting/hero/gameplay views when rarity changes, and (c) consuming currencies on failed operations. These are mitigated through upfront validation tests, event-bus communication patterns, and validate-apply-commit transaction handling.

## Key Findings

### Recommended Stack

The stack research identified a "zero external dependencies" approach - all functionality achievable with Godot 4.5 built-ins. This aligns perfectly with the existing codebase which already uses Node-based items (suboptimal but established), Dictionary for currency tracking, and enum for AffixType.

**Core technologies:**
- **GDScript Enums (Godot 4.5)**: Rarity tier definition (Normal/Magic/Rare) - type-safe, autocomplete-friendly, explicit integer values prevent serialization bugs
- **Dictionary (typed)**: Currency storage using existing `hammer_counts` pattern - already proven in crafting_view.gd, easily serializable for save systems
- **RandomNumberGenerator**: Weighted rarity drops using `rand_weighted()` method - built-in since Godot 4.0, auto-seeded, better than global `randi()` for independent RNG streams

**Critical version requirements:**
- Godot 4.0+ for `RandomNumberGenerator.rand_weighted()` and auto-seeded RNG
- Godot 4.5 for improved Dictionary performance and enum type inference

**What NOT to use:**
- Node-based items (already technical debt, but keep for consistency - future refactor to Resources)
- External loot table plugins (overkill for 3 rarity tiers)
- String-based rarity (no type safety, typos fail silently)
- Autoload singleton for currencies (crafting_view already manages state - split responsibility creates bugs)

### Expected Features

Research across Path of Exile, Last Epoch, and Diablo systems identified clear feature tiers.

**Must have (table stakes):**
- Visual rarity differentiation (white/blue/yellow text colors) - industry standard since Diablo 1996
- Rarity determines mod count limits (Normal=0, Magic=1+1, Rare=3+3) - core ARPG mechanic
- Currency preview/validation before use - prevents mistakes and user frustration
- Drop rate scaling with difficulty - harder areas = better loot is fundamental ARPG loop
- Consistent rarity upgrade paths (Normal→Magic→Rare) - no stuck states
- Mod count visibility (e.g., "Prefixes: 2/3") - critical for crafting decisions

**Should have (competitive advantage):**
- Hammer-themed currency identity - "Tack Hammer" vs generic "Orb of Augmentation" creates brand identity
- No full-reroll chaos orb equivalent - positions game as "incremental improvement" vs "gambling simulator"
- Simplified rarity system (3 tiers, not 4-6) - appropriate for idle game genre
- Claw Hammer (mod removal) at lower rarity - more experimentation vs PoE's ultra-rare Annulment
- Persistent rarity through modification - items never downgrade rarity, reduces anxiety

**Defer (v2+):**
- Item melting/recycling (wait for inventory overflow problem)
- Crafting achievements/milestones (wait until core loop is fun)
- Metamod/block crafting (too complex for idle game)
- Complex rarity tiers (Exalted/Fractured/Synthesized inappropriate for this genre)

**Anti-features to avoid:**
- Deterministic crafting (choose exact mod) - eliminates entire gameplay loop
- Full item reroll (Chaos Orb) - creates degenerate "spam until good" gameplay
- Rarity downgrade currencies - confusing, no clear use case
- Guaranteed mod addition without RNG - destroys long-term engagement

### Architecture Approach

The architecture research identified a hybrid pattern: keep existing view-based structure (CraftingView/GameplayView/HeroView) but add centralized managers for cross-cutting concerns. This balances simplicity with proper state management.

**Major components:**
1. **CurrencyManager (autoload)** - Global currency state management with signal-based updates. Provides add/subtract/get_count methods. Replaces local `hammer_counts` dictionary. Rationale: Currency is game-wide persistent state accessed from multiple views.

2. **ItemDropManager (autoload)** - Rarity-weighted item generation using area-level-scaled probabilities. Returns ItemRarity enum values. Encapsulates drop logic separately from gameplay loop. Rationale: Stateless utility accessible from any drop source.

3. **CurrencyValidator (static class)** - Validation-before-mutation pattern. Centralizes all business rules (e.g., "Tack Hammer only on Magic items with open slots"). Returns bool + error message. Rationale: Pure validation logic with no state, enables UI to check validity before attempting application.

4. **Item.rarity property + validation methods** - Add ItemRarity enum, get_max_prefixes()/get_max_suffixes() based on rarity, can_add_prefix()/can_add_suffix() helpers. Modify existing add_prefix()/add_suffix() to check rarity limits instead of hardcoded 3.

5. **Event-based view communication** - Replace some direct node references with signals to prevent state desync when rarity changes affect multiple views simultaneously.

**Key patterns:**
- **Enum for rarity state** (not classes or strings) - type-safe, exhaustive match checking
- **Validate-apply-commit** for currency use - prevent consuming currency on failed operations
- **Weighted random with area scaling** - formulaic drop weights that scale predictably with difficulty
- **Centralized validation** separate from execution - UI can check validity, provide error messages

### Critical Pitfalls

Research identified 7 critical pitfalls from existing ARPG crafting implementations and Godot patterns:

1. **Rarity state without affix count enforcement** - Adding `rarity` enum but forgetting that existing `add_prefix()` allows any item to reach 3+3 mods. Results in Normal items with mods (invalid state). Prevention: Refactor add_prefix/add_suffix to check `can_add_prefix()` which validates against rarity-based limits BEFORE attempting add.

2. **Currency validation without state transition rules** - Implementing currencies in isolation without defining valid rarity transitions. Example: Claw Hammer removes last mod from Magic item - does it become Normal or stay Magic with 0 mods? Prevention: Define explicit state machine (Normal→Magic requires adding mod, Magic→Normal requires removing all, Rare never downgrades). Validate transitions before applying.

3. **Hardcoded 3-hammer system not fully replaced** - Adding new currencies but keeping old `hammer_counts` dictionary for "backward compatibility" creates dual state management. Prevention: Complete replacement in single phase - remove `hammer_counts`, replace with `currency_inventory`, update all references atomically.

4. **UI state desync between views via direct node references** - CraftingView/HeroView communicate via `get_node()` calls. When rarity changes in one view, others don't update automatically. Prevention: Implement event bus (autoload singleton with signals) for rarity_changed, currency_used events. Views subscribe and update themselves.

5. **Affix pool exhaustion for rarity constraints** - Magic items require exactly 1+1 mods, but if item has `valid_tags = [Tag.DEFENSE]` and only 2 prefixes match, third item fails to generate. Prevention: Validate minimum affix pool size at game init (assert each item type has 3+ valid prefixes AND 3+ valid suffixes for Rare support). Add fallback: downgrade rarity if generation fails.

6. **No rollback on failed currency application** - Current pattern consumes hammer before checking if `add_prefix()` succeeds. If affix pool exhausted, player loses hammer with no effect. Prevention: Implement validate-apply-commit pattern - only consume currency after successful effect application. Return Result type with success/failure + reason.

7. **Drop table rarity probabilities not tested at scale** - Configuring "Area 5: 50% Magic drops" but not simulating actual generation success rates. Gap between attempted vs achieved rarity distribution invisible until playtest. Prevention: Build drop simulation tool that runs 10,000 drops per area level, compares attempted vs achieved rarity distributions, makes it a CI check.

## Implications for Roadmap

Based on combined research findings, recommended 4-phase structure with clear dependency rationale:

### Phase 1: Rarity Foundation
**Rationale:** Establish core type system and validation infrastructure before any behavioral changes. This phase adds new code without modifying existing logic, allowing safe testing of foundation before dependent features.

**Delivers:**
- ItemRarity enum in item.gd
- CurrencyManager autoload (data storage only, no consumption yet)
- CurrencyValidator class with validation methods
- Item.get_max_prefixes()/get_max_suffixes() based on rarity
- Item.can_add_prefix()/can_add_suffix() validation helpers
- Affix pool validation tests (assert sufficient prefixes/suffixes per item type)
- Event bus autoload for cross-view state synchronization

**Addresses features:**
- Rarity-based mod count enforcement (table stakes)
- Foundation for currency validation (table stakes)

**Avoids pitfalls:**
- Pitfall #1: Rarity state without enforcement - validation built from start
- Pitfall #4: UI state desync - event bus introduced early
- Pitfall #5: Affix pool exhaustion - validated upfront before drops

**Research needs:** SKIP - well-documented Godot enum patterns, no unknowns

### Phase 2: Currency System
**Rationale:** With validation infrastructure from Phase 1, safely implement all 6 currencies. This phase REPLACES the old 3-hammer system atomically to avoid dual state management.

**Delivers:**
- Remove `hammer_counts` dictionary entirely
- Implement all 6 currency effects (Runic, Forge, Tack, Grand, Claw, Tuning)
- Modify Item.add_prefix()/add_suffix() to check rarity limits via can_add_prefix()
- Currency application using validate-apply-commit pattern
- Update crafting_view.gd: 6 currency buttons, validation feedback
- Migration: convert any old hammer saves to new currencies

**Addresses features:**
- Runic/Forge Hammers - rarity upgrade paths (table stakes)
- Tack/Grand Hammers - mod addition to Magic/Rare (table stakes)
- Claw Hammer - mod removal without rarity downgrade (differentiator)
- Tuning Hammer - value optimization (table stakes)
- Currency preview/validation before use (table stakes)

**Avoids pitfalls:**
- Pitfall #2: State transition rules - explicit transitions implemented
- Pitfall #3: Dual systems - complete replacement, no backward compatibility
- Pitfall #6: No rollback - validate-apply-commit enforced

**Research needs:** SKIP - currency rules defined in FEATURES.md edge cases, straightforward implementation

### Phase 3: Drop System Integration
**Rationale:** With rarity and currency systems functional, integrate into drop rewards. This requires working foundation from Phases 1-2 to generate valid rarity-aware items.

**Delivers:**
- ItemDropManager.roll_rarity() using area-level-scaled weights
- Modify gameplay_view.get_random_item_base() to assign rarity
- Add starting affixes based on rarity (Magic=1-2 mods, Rare=4-6 mods)
- ItemDropManager.roll_currency_rewards() for hammer drops
- Update gameplay_view.give_hammer_rewards() to use CurrencyManager
- Drop simulation test suite (10k drops per area, verify distribution)

**Addresses features:**
- Drop rate scaling with difficulty (table stakes)
- Visual rarity indicators - white/blue/yellow text (table stakes)
- Rarity-based drop weighting formula

**Avoids pitfalls:**
- Pitfall #7: Untested drop tables - simulation built as part of implementation
- Pitfall #5: Affix pool exhaustion - tests catch failures, downgrades rarity gracefully

**Research needs:** MEDIUM - Drop rate balancing requires iteration. Formulas are standard (exponential scaling) but specific percentages need playtesting feedback. Allocate time for simulation tuning.

### Phase 4: UI Polish & Balance
**Rationale:** With functional systems from Phases 1-3, improve UX based on early playtesting. Defer to allow data-driven decisions rather than premature optimization.

**Delivers:**
- Mod count visibility in tooltips ("Prefixes: 2/3")
- Advanced crafting feedback (before/after preview, highlight changes)
- Rarity-specific visual effects (glow, particle systems, sound)
- Currency drop rate balancing based on observed progression pacing
- Smart currency suggestions (highlight usable currencies for selected item)
- Color-blind accessibility (text labels alongside colors)

**Addresses features:**
- Mod count visibility (table stakes - deferred to polish because functional without it)
- Currency application feedback (table stakes)
- Rarity visual effects (differentiator)

**Avoids pitfalls:**
- UX pitfalls: No visual feedback, silent failures, color-blind unfriendly

**Research needs:** LOW - Standard UI/UX patterns, data from Phase 3 playtesting informs balancing

### Phase Ordering Rationale

- **Phase 1 before Phase 2**: Cannot implement currencies without validation infrastructure. CurrencyValidator needs ItemRarity enum. Currency effects need can_add_prefix() checks. Event bus prevents desync bugs that would require refactoring.

- **Phase 2 before Phase 3**: Cannot integrate rarity into drops without functional currency system to reward players. Dropping Magic items useless if players can't use Tack Hammer. Complete currency replacement prevents dual-system maintenance burden.

- **Phase 3 before Phase 4**: Need actual drop distribution data to tune UI feedback and balance. Premature optimization of currency suggestions before observing usage patterns wastes time. Simulation tests in Phase 3 inform Phase 4 priorities.

**Dependency chain:**
```
Rarity enum → Validation methods → Currency implementation → Drop integration → UI polish
     ↓              ↓                      ↓                      ↓
Event bus → CurrencyValidator → apply_currency() → roll_rarity() → Feedback
```

**Safe rollback:** Each phase is independently testable. If Phase 3 has issues, Phases 1-2 remain functional (currencies work manually in crafting view, just not from drops).

### Research Flags

**Phases likely needing deeper research during planning:**
- **Phase 3 (Drop System)**: Drop rate balancing formulas and currency rarity tiers need iteration. While exponential scaling is standard, specific percentages (e.g., "Area 1: 80% Normal, 15% Magic, 5% Rare" vs "70/25/5") require simulation testing and playtesting feedback. Budget 30% of phase time for tuning cycles.

**Phases with standard patterns (skip research-phase):**
- **Phase 1 (Rarity Foundation)**: Godot enum patterns well-documented, validation is straightforward boolean logic
- **Phase 2 (Currency System)**: Edge cases fully documented in FEATURES.md, implementation is direct translation of business rules
- **Phase 4 (UI Polish)**: Standard Godot UI patterns, UX best practices well-established

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All recommendations based on Godot 4.5 official docs and proven patterns from existing codebase. Zero external dependencies reduces risk. |
| Features | MEDIUM | Table stakes identified from ARPG industry standards (PoE/Last Epoch/Diablo). Edge cases documented. Differentiators are design choices, not unknowns. Lower confidence on exact feature prioritization for v1 vs v1.x - needs validation. |
| Architecture | HIGH | Component boundaries align with existing codebase structure. Autoload pattern for global state is Godot best practice. Validation-before-mutation is proven game dev pattern. Build order prevents circular dependencies. |
| Pitfalls | HIGH | All 7 critical pitfalls derived from real ARPG implementation issues (PoE crafting bugs, Godot signal patterns, state machine failures). Recovery strategies documented. Phase-to-pitfall mapping explicit. |

**Overall confidence:** HIGH

Research converges on established patterns (ARPG rarity tiers, Godot state management, currency-based crafting) with no novel/experimental techniques required. Primary uncertainty is balancing drop rates and currency rarity, which is iterative tuning rather than unknown domain.

### Gaps to Address

- **Currency drop rate ratios**: Research identifies need for area-scaled drops but doesn't prescribe exact ratios (e.g., should Tuning Hammer be 2x rarer than Runic Hammer? 5x? 10x?). Handle via simulation in Phase 3 - start with Path of Exile ratios (Divine Orbs ~10x rarer than Chaos Orbs), measure player progression time-to-perfect-item, adjust.

- **Affix pool coverage by item type**: Research validates that existing codebase has 9 prefixes and 21 suffixes, but doesn't enumerate which item types have sufficient coverage for all tags. Handle via automated validation test in Phase 1 - assert each of 5 item types (Sword/Helmet/Armor/Boots/Ring) has min 3 prefixes and 3 suffixes matching their valid_tags. If failures, expand pools before Phase 3.

- **Event bus vs direct references migration scope**: Architecture recommends event bus but doesn't specify which existing direct references to migrate. Handle via surgical approach in Phase 1 - migrate only rarity-change events and currency-change events, keep existing hero/crafting communication via direct calls (already works, no reason to refactor). Full migration to events is v2+ architecture cleanup, not milestone-critical.

- **Tuning Hammer value range guarantees**: FEATURES.md specifies "reroll all mod values" but doesn't address: should reroll guarantee improvement? Allow downgrades? Path of Exile's Divine Orb allows downgrades (80% value → 30% is valid). Handle via explicit rule in Phase 2: Tuning Hammer rerolls within tier's min_value/max_value range, no guarantees, player sees preview "20-100 (current: 80)" with confirmation dialog for expensive currencies.

## Sources

### Primary (HIGH confidence)
- [STACK.md](.planning/research/STACK.md) - Godot 4.5 official documentation, existing codebase patterns
- [FEATURES.md](.planning/research/FEATURES.md) - Path of Exile Wiki (authoritative), Last Epoch crafting guides, Diablo references
- [ARCHITECTURE.md](.planning/research/ARCHITECTURE.md) - Godot autoload documentation, game architecture patterns, ARPG system design
- [PITFALLS.md](.planning/research/PITFALLS.md) - Real implementation bugs from GitHub issues, state machine patterns, validation best practices

### Secondary (MEDIUM confidence)
- Path of Exile 2 crafting overviews (Maxroll.gg) - system in flux, but directional patterns valid
- Community ARPG crafting guides - consensus on table stakes features
- Godot inventory/crafting system examples (GitHub repositories) - implementation patterns

### Tertiary (LOW confidence)
- TV Tropes color-coded loot tiers - historical context, not technical guidance
- General game dev architecture articles - high-level patterns, need adaptation

---
*Research completed: 2026-02-14*
*Ready for roadmap: yes*
