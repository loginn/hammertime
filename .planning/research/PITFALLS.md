# Pitfalls Research

**Domain:** ARPG idle game — hero archetype addition (v1.9)
**Researched:** 2026-03-09
**Confidence:** HIGH — All pitfalls grounded in direct analysis of existing codebase (Hero, StatCalculator, CombatEngine, PrestigeManager, SaveManager, GameState, Tag). Architecture-specific risks verified against current save format v7, 41-affix pool, 21 item bases, and prestige wipe flow.

---

## Critical Pitfalls

### Pitfall 1: Multiplicative bonus stacking breaks damage scaling

**What goes wrong:** Hero affinity bonuses like "100% more fire damage" are multiplicative modifiers. The existing StatCalculator uses additive stacking for `INCREASED_DAMAGE` (line 29-31: `additive_damage_mult += affix.value / 100.0`, applied once as `damage *= (1.0 + sum)`). A hero affinity that multiplies after this additive sum creates a new scaling layer. A Fire Wizard with 100% more fire damage effectively doubles the output of every fire affix. Players who stack fire gear + fire affinity get exponential returns while non-matching elements get zero bonus. The gap between "right element" and "wrong element" becomes a cliff, not a slope.

**Why it happens:** "More" (multiplicative) vs "increased" (additive) is the classic ARPG balance trap. Additive bonuses have diminishing marginal value (going from 100% to 200% increased is a 50% relative gain). Multiplicative bonuses have constant marginal value (100% more always doubles). When a hero affinity is the only multiplicative layer, it dominates all other gearing decisions.

**How to avoid:**
- Make hero affinity bonuses additive with existing `INCREASED_DAMAGE` stacking, not a separate multiplier. "100% increased fire damage" added to the existing sum means it competes with gear mods for value, not multiplying on top of them.
- If multiplicative is the design intent, use smaller values (20-30% more, not 100% more) and test at endgame gear levels where the base additive sum is already 200-400%.
- Test the ratio: (best-in-slot fire gear + fire affinity) vs (best-in-slot fire gear + no affinity). If the ratio exceeds 2x, the affinity is too strong and invalidates non-matching heroes.

**Warning signs:** Players always pick the hero matching their best weapon's element. Hero selection becomes a solved optimization, not a meaningful choice. Non-matching heroes feel like a punishment.

**Phase to address:** Design phase (before any code). The stacking rule (additive vs multiplicative) must be decided and documented before StatCalculator is touched.

---

### Pitfall 2: Hero affinity bonus applied in wrong calculation stage

**What goes wrong:** StatCalculator has a strict order: flat damage -> additive % -> speed -> crit. The hero affinity bonus must be injected at exactly the right stage. If applied before flat damage is added, it does not scale flat mods. If applied after crit, it double-scales with crit multiplier. If applied per-element inside `calculate_damage_range()` but the hero has a "generic" affinity (like "100% more STR damage"), the routing logic for which elements qualify becomes a source of bugs.

**Why it happens:** The current `calculate_damage_range()` accumulates per-element (physical/fire/cold/lightning) and applies percentage modifiers per group (physical_pct vs elemental_pct). A hero affinity that says "fire damage" needs to be routed to fire only, but the existing code has no injection point for a per-element multiplier that comes from a source other than affixes.

**How to avoid:**
- Do NOT modify StatCalculator's internal loop to check for hero affinity. StatCalculator is a pure function operating on affixes. Instead, apply the hero bonus in Hero.calculate_damage_ranges() after StatCalculator returns, scaling the relevant element's min/max.
- Create a clear separation: StatCalculator handles gear math. Hero handles hero-level bonuses applied to StatCalculator's output.
- Add integration tests that verify: (a) affinity does not double-count with INCREASED_DAMAGE affixes, (b) affinity applies to the correct element only, (c) affinity works with both attack and spell damage channels.

**Warning signs:** DPS display shows different numbers than actual combat damage. Fire Wizard's displayed DPS does not match observed kill speed. Crit + affinity produces unexpectedly high numbers.

**Phase to address:** Implementation phase. The injection point must be verified with unit tests before integration.

---

### Pitfall 3: Save migration — hero_class field missing from v7 saves

**What goes wrong:** Current save format v7 has no hero_class or hero_archetype field. When v1.9 ships with save format v8, existing v7 saves load with no hero class. The current SaveManager policy (line 62) is to DELETE outdated saves: `push_warning("SaveManager: Outdated save (v%d), deleting and starting fresh")`. This means every existing player loses all progress — prestige levels, unlocked tiers, everything — on update.

**Why it happens:** The delete-on-old-version policy was acceptable when saves represented hours of play (v2->v3 transition). At v7, players may have completed multiple prestige cycles. Deleting their save is a retention-killing event.

**How to avoid:**
- Add a migration path: `_migrate_v7_to_v8()` that defaults hero_class to null (no archetype selected). The game treats null hero_class as "classless" — equivalent to current gameplay with no bonuses. Player picks a hero on their next prestige.
- Change the save version check from "delete if old" to "migrate if old." The delete policy served its purpose in early development but is toxic for a game with meta-progression.
- Test: create a v7 save with P3+ progress, load in v8 code, verify prestige_level and max_item_tier_unlocked survive.

**Warning signs:** Test suite does not include a v7-to-v8 migration test. Save format bumped without migration function.

**Phase to address:** Implementation phase. Save migration must be written and tested before any other v1.9 code ships.

---

### Pitfall 4: Prestige wipe does not reset hero class, or resets it wrong

**What goes wrong:** `_wipe_run_state()` in GameState (line 93) creates a fresh `Hero.new()` and wipes all run-scoped state. If hero_class is stored on the Hero object, it gets wiped on prestige. But the v1.9 design says "hero choice resets on each prestige" — so it SHOULD be wiped. The pitfall is in the ordering: the prestige flow is (1) spend currency, (2) advance prestige_level, (3) wipe run state, (4) grant bonus, (5) emit signal. If hero selection happens in response to the `prestige_completed` signal (step 5), the UI must show the selection screen AFTER the wipe but BEFORE the player can do anything else. If the selection is skippable or deferred, the player plays with no hero class until they manually select one.

**Why it happens:** PrestigeManager.execute_prestige() is a synchronous function that returns bool. It does not await UI interaction. Adding a "pick your hero" step mid-prestige requires either: (a) making execute_prestige() async (breaking existing callers), or (b) splitting prestige into two phases (wipe + select), or (c) showing selection UI after prestige completes and blocking gameplay until selection is made.

**How to avoid:**
- Option (c) is safest: prestige completes as-is, hero_class is set to null on wipe, `prestige_completed` signal triggers a hero selection overlay that blocks the Adventure tab until the player picks. GameState stores selected_hero_class. CombatEngine refuses to start_combat() if selected_hero_class is null.
- Do NOT store hero class on the Hero Resource. Store it on GameState alongside prestige_level. It is meta-state that survives within a run but resets between prestiges.
- Test: execute prestige, verify hero_class is null, verify combat cannot start, select hero, verify combat works.

**Warning signs:** Player can start combat with no hero class selected. Hero class persists across prestige (defeating the "pick on prestige" design). Prestige flow hangs waiting for UI input in a non-UI context.

**Phase to address:** Design phase (data model), then implementation phase (prestige flow integration).

---

### Pitfall 5: Random hero selection produces feel-bad outcomes

**What goes wrong:** "Pick 1 from 3 random heroes (1 per archetype)" means the player always sees one STR, one DEX, one INT option. The subvariant within each archetype is random. If the player is building fire gear and gets offered Frost Warrior (STR/cold) instead of Fire Warrior (STR/fire), their entire gear set becomes mismatched. They must either: (a) pick the mismatched hero and lose affinity value, (b) pick a different archetype and waste their gear, or (c) prestige again to reroll — which costs significant currency.

**Why it happens:** Randomness in prestige selection means the player's strategic investment in specific gear can be invalidated by RNG. This is acceptable if the affinity bonus is modest (10-20% increased), but devastating if it is large (100% more).

**How to avoid:**
- Offer subvariant choice within archetype: "You picked STR. Choose: Fire Warrior or Frost Warrior." Two-step selection (archetype then subvariant) gives players agency over element matching.
- Alternatively, make affinity bonuses element-agnostic: "STR heroes deal 30% more attack damage" regardless of element. Subvariants are cosmetic or offer minor secondary bonuses.
- If full RNG is the design intent, keep affinity bonuses small enough that mismatches feel like "not ideal" rather than "run-ruining."

**Warning signs:** Players consistently prestige multiple times to fish for the right subvariant. Prestige currency cost is too low relative to the value of the "right" hero. Players complain about bad RNG on hero selection.

**Phase to address:** Design phase. This is a core game feel decision that affects balance numbers and UI design.

---

### Pitfall 6: Hero affinity interacts badly with DoT system

**What goes wrong:** CombatEngine has three DoT types: bleed (physical, attack-mode), poison (chaos, attack-mode), burn (fire, spell-mode). A Fire Wizard with "100% more fire damage" should boost burn ticks (burn is fire element) but NOT bleed or poison. However, burn damage in CombatEngine (line 192-197) is calculated as a percentage of the spell hit damage, which already includes fire affinity if applied in Hero.calculate_spell_damage_ranges(). If fire affinity is ALSO applied to the burn tick separately, it double-dips.

Conversely, a Poison Assassin with "100% more poison damage" needs to boost poison ticks. But poison tick damage (line 149-150) is calculated from flat poison damage affixes, not from hit damage. If the affinity applies to hit damage, poison gets zero benefit. If it applies to DoT damage, it must specifically target poison and not bleed/burn.

**Why it happens:** The DoT system has three different damage derivation formulas (bleed scales from hit damage, poison scales from flat poison affixes, burn scales from spell hit damage). A generic "more damage" affinity interacts differently with each formula. Element-specific affinities must be carefully routed through the correct DoT path.

**How to avoid:**
- Define explicitly what each affinity affects: hit damage only, DoT damage only, or both. Document this in the hero class definition, not buried in combat code.
- If affinity affects hit damage and DoT scales from hit damage (bleed, burn), the affinity naturally flows through. No double-application needed.
- If affinity should separately boost DoT, add a `dot_damage_multiplier` field on Hero that is set by the affinity. Apply it once in `_on_dot_tick()`.
- Test each hero subvariant against each DoT type: verify no double-dipping, verify the correct DoT benefits.

**Warning signs:** Fire Wizard's burn DPS is suspiciously higher than expected. Poison Assassin's poison DPS does not benefit from hero affinity at all. Bleed damage is boosted by a cold affinity because it scales from total hit damage which includes cold bonuses.

**Phase to address:** Implementation phase. Requires explicit test cases for every hero-DoT combination.

---

### Pitfall 7: CombatEngine `is_spell_user` flag conflicts with hero archetype

**What goes wrong:** Currently, `is_spell_user` is a boolean on Hero (line 62) that determines whether CombatEngine uses `hero_attack_timer` or `hero_spell_timer` (line 88-94). This flag is persisted in the save (line 112). With hero archetypes, the damage channel should be determined by the hero class (INT heroes use spells, STR/DEX heroes use attacks). If `is_spell_user` is set by the weapon type (INT weapons set it true) but the hero class is STR, there is a conflict: STR hero with INT weapon — does the hero attack or cast?

**Why it happens:** `is_spell_user` was added in v1.8 as a weapon-driven flag. Hero archetypes add a second source of truth for damage channel selection. Two authorities for the same decision create inconsistency.

**How to avoid:**
- Make hero archetype the authority for damage channel. INT hero = spell user, STR/DEX hero = attack user. Remove `is_spell_user` from Hero; derive it from hero_class.
- If hybrid builds are desired (STR hero using INT weapon), define the rule explicitly: weapon determines channel, hero provides affinity bonus regardless. But this must be a conscious design decision, not an accident.
- Remove `is_spell_user` from the save format entirely. Derive it from hero_class on load.

**Warning signs:** `is_spell_user` and hero_class can disagree. Changing weapons mid-run flips the combat channel without changing hero class. Save contains both `is_spell_user` and `hero_class` with no validation that they agree.

**Phase to address:** Design phase (who is the authority for damage channel?), then implementation phase.

---

### Pitfall 8: Hero selection UI does not fit mobile viewport

**What goes wrong:** The viewport is 1280x720 (PROJECT.md line 166). A hero selection screen showing 3 archetypes with subvariants, affinity descriptions, and stat previews can easily overflow. If each hero card shows: name, archetype icon, affinity description, and stat bonuses, that is 3 cards with 4-5 lines each. Add a "Select" button per card and the screen is packed.

**Why it happens:** Hero selection is a one-time-per-prestige screen, so developers often over-design it with rich detail. But the game runs at 1280x720 with font size 11 (KEY DECISIONS), and the existing prestige_view already uses significant vertical space for the 7-level unlock table.

**How to avoid:**
- Keep hero cards minimal: Name + one-line affinity description + Select button. Three cards in a horizontal row fit 1280px at ~400px each with margins.
- Do NOT show stat previews or detailed breakdowns. The player has no gear yet (prestige just wiped it). Previewing stats against zero gear is meaningless.
- Use the same font size (11) and styling as the existing prestige_view to maintain visual consistency.
- Test at exactly 1280x720. Do not design at a higher resolution and scale down.

**Warning signs:** Hero selection text is truncated or overlaps. Scroll bars appear on a screen that should fit without scrolling. Font size is increased from 11 to fit more text, breaking consistency with other views.

**Phase to address:** Implementation phase (UI). Prototype the layout at target resolution before building functionality.

---

### Pitfall 9: Hero class creates item drop frustration

**What goes wrong:** With 21 item bases distributed across STR/DEX/INT, and hero affinity bonuses favoring one archetype's items, players want drops that match their hero. Current drop distribution is slot-first then uniform within slot (KEY DECISIONS: "20% per slot, uniform within slot"). A Fire Wizard gets STR weapons and DEX weapons at the same rate as INT weapons. Two-thirds of weapon drops are useless for the hero's affinity.

**Why it happens:** The loot system was designed before hero classes existed. Adding hero classes without adjusting drop weights creates a mismatch between what the player needs and what the game gives them.

**How to avoid:**
- Add hero-weighted drops in LootTable: if hero_class is INT, INT item bases within each slot have 2x weight. This does not eliminate non-matching drops (they are still useful for experimentation) but makes matching drops more common.
- Do NOT make it 100% matching drops. That eliminates the possibility of the player trying a different archetype within a run.
- Defer this to a polish phase if the base implementation is complex. The game already drops all items as Normal rarity (crafting-only mods), so non-matching bases are still usable — they just lack the affinity bonus.

**Warning signs:** Players melt 60%+ of drops without looking at them. Inventory fills with bases the player cannot use effectively. Time-to-upgrade increases 3x compared to pre-hero-class gameplay.

**Phase to address:** Balance/polish phase, after core hero system works.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Store hero_class as string instead of enum | No new enum, faster to implement | String comparison everywhere, typo bugs, no autocomplete | Never — use an enum or const. 9 subvariants means 9 string literals scattered across code. |
| Hardcode affinity bonuses in CombatEngine | Quick to test | CombatEngine becomes aware of hero classes, violating its role as a combat state machine | Only in prototype. Move to Hero or a new HeroArchetype Resource before shipping. |
| Skip save migration, bump version and delete old saves | No migration code to write | Every existing player loses progress including prestige levels | Unacceptable at v7+. Migration is mandatory. |
| Put hero selection in prestige_view.gd | Reuse existing scene, no new file | prestige_view grows too large, mixes prestige logic with hero selection | Acceptable if hero selection is <50 lines. Extract if it grows. |
| Use `is_spell_user` alongside hero_class | No refactor of existing v1.8 code | Two sources of truth for damage channel | Only during transition. Remove `is_spell_user` before shipping. |
| Apply affinity in StatCalculator directly | Single calculation pass | StatCalculator loses its "pure gear math" property, becomes coupled to hero state | Never. StatCalculator should remain a pure function. |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Recalculating affinity bonus every combat tick | Frame drops during combat, especially with DoT ticks | Cache affinity multiplier on Hero.update_stats(). Only recalculate on equip/hero selection. | Immediately on any mid-combat stat recalculation |
| Hero selection UI instantiating 9 hero card scenes on every prestige | Noticeable hitch during prestige transition | Pre-instantiate cards, update text/visibility. Or use a simple VBoxContainer with labels, not scenes. | Prestige cycles happen frequently in endgame |
| Iterating all 21 item base types to find matching archetype on every drop | Slow LootTable.roll_pack_item_drop() | Build a lookup dictionary (archetype -> base types per slot) once at startup. | 8-15 packs per map, each rolling item drops. 15+ dictionary lookups per clear. |
| String-based hero class comparison in hot paths | Micro-stutter accumulation | Use integer enum for hero class. String comparison only in UI display and save serialization. | Noticeable at 200+ area levels with fast kill speed |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Showing hero selection before explaining what heroes do | Player picks randomly, regrets choice, no undo | Show a 2-line explanation of each hero's bonus before the selection buttons. One sentence max. |
| No indication of current hero in main gameplay UI | Player forgets which hero they picked, cannot verify bonuses are active | Add hero name/icon to the hero stats panel in forge_view. Small, non-intrusive. |
| Hero affinity described with ARPG jargon ("100% more fire damage") | Casual idle players do not know "more" vs "increased" | Use plain language: "Fire damage doubled" or "Fire attacks deal 2x damage." Avoid ARPG-specific terminology. |
| Offering hero selection at P0 (first prestige) | Player has no context for what archetypes mean, no gear to match | Gate hero selection to P1+. P0 plays classless. First prestige introduces the hero system as a reward. |
| Hero bonuses not reflected in stat panel | Player cannot see the impact of their choice | Show affinity bonus as a separate line in offense stats: "Fire Affinity: +100% fire damage" |
| Allowing hero respec without prestige | Trivializes the choice, removes prestige incentive | Hero locks on selection, resets on next prestige. No mid-run respec. |

---

## "Looks Done But Isn't" Checklist

- [ ] Hero affinity bonus shows in DPS display but is not actually applied in CombatEngine damage rolls
- [ ] Hero affinity works for attack damage but not spell damage (or vice versa)
- [ ] Hero affinity works for hit damage but not for DoT ticks that scale from hits
- [ ] Save round-trips hero_class correctly but does not re-derive `is_spell_user` from it on load
- [ ] Hero selection screen appears on prestige but player can dismiss it and play with no hero
- [ ] Prestige wipe resets hero_class but the old affinity multiplier is still cached on Hero stats
- [ ] Hero-weighted drops work for weapons but not for armor/helmet/boots/ring slots
- [ ] All 9 subvariants are defined in code but only 3 are tested (one per archetype)
- [ ] Hero selection works on first prestige but crashes on subsequent prestiges (UI not cleaned up)
- [ ] Export/import save string includes hero_class but import does not validate against known hero types
- [ ] Test suite covers hero damage bonus but not the case where hero_class is null (classless state)
- [ ] Hero affinity bonus tooltip says "100% more" but code implements it as additive "100% increased"

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|-----------------|--------------|
| P1: Multiplicative stacking | Design — decide additive vs multiplicative before coding | Spreadsheet: max-gear + affinity vs max-gear + no affinity ratio |
| P2: Wrong calculation stage | Implementation — injection point tests | Unit test: affinity * INCREASED_DAMAGE does not double-count |
| P3: Save migration v7->v8 | Implementation — before any other v1.9 code | Integration test: v7 save loads in v8 with null hero_class |
| P4: Prestige wipe ordering | Design + Implementation — data model then flow | Integration test: prestige -> null hero -> selection -> combat |
| P5: Feel-bad random selection | Design — subvariant choice mechanism | Playtest: 10 prestige cycles, track frustration with offered heroes |
| P6: DoT interaction | Implementation — per-DoT-type test coverage | Unit test: each hero subvariant x each DoT type = correct multiplier |
| P7: is_spell_user conflict | Design — single authority for damage channel | Remove is_spell_user, derive from hero_class. Grep for all usages. |
| P8: UI viewport overflow | Implementation — layout prototype first | Visual test: screenshot at 1280x720, no truncation/overlap |
| P9: Drop frustration | Balance/polish — after core system works | Metric: % of drops melted without crafting. Target <50%. |

---

## Sources

- Direct codebase analysis: `StatCalculator` (calculate_damage_range additive stacking pattern), `CombatEngine` (is_spell_user branching, DoT formulas), `PrestigeManager` (execute_prestige flow), `SaveManager` (version check delete policy, _build_save_data fields), `GameState` (_wipe_run_state scope), `Hero` (update_stats order, damage_ranges caching), `Tag` (existing STR/DEX/INT constants, StatType enum)
- PROJECT.md: v1.9 target features, architecture constraints, key decisions (font size 11, 1280x720 viewport, additive stacking convention, tier comparison, slot-first drops)
- v1.8 pitfalls research (this file, previous version): save migration lessons, affix pool dilution patterns, CombatEngine timer complexity

---
*Pitfalls research for: hero archetype addition*
*Researched: 2026-03-09*
