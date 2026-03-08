# Phase 48: Damage Over Time — Research

**Date:** 2026-03-08
**Requirements:** DOT-01 through DOT-07

## Executive Summary

Phase 48 adds a Damage Over Time (DoT) combat subsystem with three mechanically distinct types: bleed (STR/physical, multi-stack, hit-scaled), poison (DEX/chaos, infinite flat stacks), and burn (INT/fire, single powerful stack). The system is bidirectional -- hero applies DoTs to packs, packs apply DoTs to hero. DoT bypasses evasion and armor, only reduced by matching resistance, and splits through ES/Life like direct hits.

**Foundation status:** Most data scaffolding already exists. All DoT stat types (BLEED_DAMAGE, POISON_DAMAGE, BURN_DAMAGE, BLEED_CHANCE, POISON_CHANCE, BURN_CHANCE, CHAOS_RESISTANCE) are declared in `tag.gd`. All 10 DoT affixes are registered in `item_affixes.gd`. Weapon bases with DoT implicits exist (Warhammer/bleed, VenomBlade/poison, Sceptre/burn via fire spell). What's missing is the runtime DoT processing, stat aggregation, defense interaction, and UI feedback.

**Scope:** ~7 files modified, 0-1 new files (optional DoT effect class). No save format changes needed (DoT effects are transient combat state, not persisted).

---

## Codebase Analysis

### tag.gd (autoloads/tag.gd)

All required stat types already present in `StatType` enum:
- `BLEED_DAMAGE`, `POISON_DAMAGE`, `BURN_DAMAGE` (lines 59-61)
- `BLEED_CHANCE`, `POISON_CHANCE`, `BURN_CHANCE` (lines 65-67)
- `CHAOS_RESISTANCE` (line 63)
- `DOT` tag constant (line 11)

**DOT-01 status:** Stat types are declared. No new enum values needed. However, there are currently no `INCREASED_BLEED_DAMAGE`, `INCREASED_POISON_DAMAGE`, or `INCREASED_BURN_DAMAGE` stat types for the `%Bleed Damage`, `%Poison Damage`, `%Burn Damage` suffixes. The existing `BLEED_DAMAGE`, `POISON_DAMAGE`, `BURN_DAMAGE` are reused for both flat and percentage roles. The `item_affixes.gd` already uses these same stat types for both the flat prefix and the `%` suffix variants -- the flat versions use `add_min`/`add_max` fields while the `%` versions use the `value` field. This dual-use pattern must be understood when aggregating stats in the hero.

### item_affixes.gd (autoloads/item_affixes.gd)

All 10 DoT affixes already registered:
- **Flat prefixes** (3): "Bleed Damage" (2-6 add_min/add_max), "Poison Damage" (2-6), "Burn Damage" (2-6) -- all tagged `[Tag.DOT, Tag.{element}, Tag.WEAPON]`
- **Generic % prefix** (1): "%DoT Damage" with stat_types `[BLEED_DAMAGE, POISON_DAMAGE, BURN_DAMAGE]` -- scales all three types
- **Chance suffixes** (3): "Bleed Chance" (3-10 value), "Poison Chance" (3-10), "Burn Chance" (3-10)
- **% damage suffixes** (3): "%Bleed Damage" (2-10), "%Poison Damage" (2-10), "%Burn Damage" (2-10)

**Key pattern for stat aggregation:** Flat damage prefixes have `add_min`/`add_max` > 0 (range-based). Percentage suffixes have `value` > 0 but `add_min`/`add_max` = 0. Chance suffixes have `value` as the percentage chance. The code must distinguish flat from percentage by checking whether `add_min`/`add_max` > 0.

### combat_engine.gd (models/combat/combat_engine.gd)

Current structure:
- Three timers: `hero_attack_timer`, `hero_spell_timer`, `pack_attack_timer`
- `_on_hero_attack()` (line 82): rolls per-element damage, applies crit, calls `pack.take_damage()`, emits `hero_attacked`
- `_on_hero_spell_hit()` (line 113): same pattern for spell damage, emits `hero_spell_hit`
- `_on_pack_attack()` (line 144): rolls pack damage, routes through `DefenseCalculator.calculate_damage_taken()`, calls `hero.apply_damage()`
- `is_spell_user` on hero determines which timer starts (line 70-76)
- Pack kill triggers `_on_pack_killed()` which stops timers, processes drops

**DoT integration points:**
1. After `pack.take_damage()` in `_on_hero_attack()` -- roll bleed/poison chance and apply DoT to pack
2. After `pack.take_damage()` in `_on_hero_spell_hit()` -- roll burn chance and apply DoT to pack
3. After `hero.apply_damage()` in `_on_pack_attack()` -- roll pack DoT chance and apply DoT to hero
4. Need a new tick mechanism (4th timer or `_process()`) to process active DoTs every second

### defense_calculator.gd (models/stats/defense_calculator.gd)

4-stage pipeline: Evasion -> Resistance -> Armor -> ES/Life split.

For DoT ticks, need a simplified path:
- Skip stage 1 (evasion) -- DoT bypasses dodge
- Skip stage 3 (armor) -- DoT bypasses armor
- Stage 2 (resistance): only for poison (chaos res) and burn (fire res). Bleed has no resistance (physical has no resistance stat).
- Stage 4 (ES/Life split): applies normally

**Implementation:** Add a static method like `calculate_dot_damage_taken()` that takes raw_dot_damage, dot_type, and relevant resistance + ES params. Much simpler than full pipeline.

### hero.gd (models/hero.gd)

Current stat aggregation in `update_stats()`:
- `calculate_crit_stats()` -> `calculate_damage_ranges()` -> `calculate_spell_damage_ranges()` -> `calculate_dps()` -> `calculate_spell_dps()` -> `calculate_defense()`

**New additions needed:**
- Aggregate DoT stats from equipped items: total_bleed_chance, total_bleed_damage (flat), total_bleed_damage_pct, total_poison_chance, total_poison_damage, total_poison_damage_pct, total_burn_chance, total_burn_damage, total_burn_damage_pct
- Add `total_chaos_resistance` aggregation in `calculate_defense()` (CHAOS_RESISTANCE suffix exists but is NOT currently tracked)
- Add `calculate_dot_dps()` method for display
- Add `total_dot_dps` cached variable

**CHAOS_RESISTANCE gap:** The `CHAOS_RESISTANCE` affix exists in `item_affixes.gd` (line 308-314) but `hero.gd`'s `calculate_defense()` does NOT aggregate it. This must be added in this phase since poison DoT uses chaos resistance.

### monster_pack.gd (models/monsters/monster_pack.gd)

Simple data model (31 lines). Fields: pack_name, hp, max_hp, damage, damage_min, damage_max, attack_speed, element, difficulty_bonus.

**Needs:** Active DoT effect tracking. Each pack needs to store active DoT stacks with remaining duration and tick damage. A dictionary or array of DoT effect objects.

### game_events.gd (autoloads/game_events.gd)

Signal bus pattern. Currently has: combat_started, pack_killed, hero_attacked, hero_spell_hit, pack_attacked, hero_died, map_completed, combat_stopped, currency_dropped, items_dropped.

**New signals needed:**
- `dot_applied(target: String, dot_type: String, stack_count: int)` -- for UI status text
- `dot_ticked(target: String, dot_type: String, damage: float, total_accumulated: float)` -- for accumulator label
- `dot_expired(target: String, dot_type: String)` -- for clearing UI

### floating_label.gd (scenes/floating_label.gd)

Three display methods: `show_damage()`, `show_spell_damage()`, `show_dodge()`. All create tweens that drift up and fade out, then `queue_free()`.

**DoT UI is NOT floating text.** Per context decisions, DoT uses a persistent accumulator label near HP bars (not float-away numbers). This means the DoT UI will be a new Label node in gameplay_view's combat UI, not a floating_label instance.

### gameplay_view.gd (scenes/gameplay_view.gd)

Manages combat UI display. Has references to hero/pack HP bars, floating text container, and all signal handlers. `update_display()` refreshes HP bars on every combat event.

**DoT UI additions:**
- New Label nodes for DoT accumulator (near pack HP bar for hero->pack DoT, near hero HP bar for pack->hero DoT)
- New Label for DoT status text on HP bars ("BLEED x3", "POISON x7", "BURN")
- Connect new DoT signals from GameEvents
- Manage accumulator state (running total, fade timer)

### forge_view.gd (scenes/forge_view.gd)

`update_hero_stats_display()` (line 657) shows Attack DPS, Spell DPS, crit stats, defense stats.

**DoT DPS line:** Add "DoT DPS: X.X" after Attack/Spell DPS, hidden when 0. Simple addition.

### stat_calculator.gd (models/stats/stat_calculator.gd)

Static utility for DPS calculation. Has `calculate_dps()`, `calculate_spell_dps()`, `calculate_damage_range()`, `calculate_spell_damage_range()`, `_calculate_crit_multiplier()`.

**May need:** A `calculate_dot_dps()` static method, or the calculation can live directly in `hero.gd` since it depends on hero-specific stats (chance, stacks, speed).

### Weapon bases with DoT implicits

- **Warhammer** (`models/items/warhammer.gd`): Implicit named "Bleed Chance" but stat_type is `BLEED_DAMAGE`, tags `[PHYSICAL, DOT]`. This is a flat bleed damage implicit, not a chance implicit. The name is misleading -- the implicit adds flat bleed damage, not bleed chance. **Naming inconsistency** -- should be addressed or understood as intentional.
- **VenomBlade** (`models/items/venom_blade.gd`): Implicit "Poison Damage" with `POISON_DAMAGE`, tags `[CHAOS, DOT]`. Correctly provides flat poison damage.
- **Sceptre** (`models/items/sceptre.gd`): Implicit "Fire Spell Damage" with `FLAT_SPELL_FIRE_DAMAGE`, tags `[SPELL, FIRE, FLAT]`. This is NOT a burn implicit -- it's flat spell fire damage. Sceptre has no inherent burn stat.

**Implication:** The Warhammer implicit name should probably be corrected to "Bleed Damage" since it uses `BLEED_DAMAGE` stat type. Sceptre does NOT have a burn implicit -- burn comes entirely from affixes rolled on gear.

---

## Implementation Strategy per Requirement

### DOT-01: New StatTypes for DoT in tag.gd

**Status: Already complete.** All stat types (BLEED_DAMAGE, POISON_DAMAGE, BURN_DAMAGE, BLEED_CHANCE, POISON_CHANCE, BURN_CHANCE) exist in `tag.gd` StatType enum. No code changes needed for DOT-01 itself.

**Related work:** Add `total_chaos_resistance` to hero.gd defense aggregation (CHAOS_RESISTANCE exists but isn't tracked). This is needed for DOT-07 but should be done early.

### DOT-02: DoT tick system in CombatEngine

This is the core implementation. Needs:

1. **DoT effect data model:** A lightweight class or dictionary representing an active DoT:
   ```
   {
     "type": "bleed" | "poison" | "burn",
     "damage_per_tick": float,
     "ticks_remaining": int,  # starts at 4, decrements each second
     "element": "physical" | "chaos" | "fire"
   }
   ```

2. **DoT tracking on targets:**
   - `MonsterPack`: Add `var active_dots: Array = []` for hero-applied DoTs
   - `Hero` or `CombatEngine`: Add active DoTs array for pack-applied DoTs on hero

3. **DoT application logic in hit handlers:**
   - `_on_hero_attack()`: After damage dealt, roll bleed/poison chance. If success, create DoT effect and add to pack's active_dots.
   - `_on_hero_spell_hit()`: After damage dealt, roll burn chance. If success, create/refresh burn on pack.
   - `_on_pack_attack()`: After damage dealt, roll pack DoT chance (10% + area_level * 0.2%), create DoT on hero if pack element supports it.

4. **DoT tick timer:** Add a 1-second repeating timer in CombatEngine. On each tick:
   - Process all active DoTs on current pack (damage the pack, decrement ticks, remove expired)
   - Process all active DoTs on hero (apply through resistance-only defense, decrement ticks, remove expired)
   - Emit signals for UI

5. **Stacking rules per type:**
   - **Bleed:** Max 8 stacks. New application replaces stack closest to expiry (lowest ticks_remaining). tick_damage = hit_damage * base_bleed_pct * (1 + %bleed).
   - **Poison:** Unlimited stacks. Each stack independent flat damage. tick_damage per stack = flat_poison * (1 + %poison). On crit: +100% chance to apply.
   - **Burn:** Max 1 stack. New application replaces existing. tick_damage = hit_damage * base_burn_pct * (1 + %burn).

6. **Combat lifecycle:** Clear all active DoTs on pack kill, hero death, combat stop, map complete.

**Architectural decision -- DoT manager vs inline:**
- **Recommend inline in CombatEngine.** The DoT logic is tightly coupled to combat state (current pack, hero, timers). A separate DoT manager class would need all the same references. Keep it in CombatEngine with clearly named helper methods (`_apply_dot_to_pack()`, `_apply_dot_to_hero()`, `_process_dot_ticks()`).

### DOT-03: Bleed affix (physical DoT, STR signature)

**Affix already registered.** The "Bleed Damage" prefix, "%Bleed Damage" suffix, and "Bleed Chance" suffix exist in item_affixes.gd.

**Runtime implementation needed:**
- Hero stat aggregation: sum total_bleed_chance from BLEED_CHANCE suffixes, sum flat bleed from BLEED_DAMAGE prefixes (add_min/add_max), sum %bleed from BLEED_DAMAGE suffixes (value field, distinguished by add_min == 0).
- Bleed proc in `_on_hero_attack()`: roll against total_bleed_chance. On success, calculate tick = hit_damage * (flat_bleed_sum / base_weapon_damage) * (1 + %bleed). This converts flat bleed damage into a scaling factor relative to hit power.
- Attack-mode only: bleed cannot proc from `_on_hero_spell_hit()`.

**Base% design choice:** The context says "tick = hit_damage * base% * (1 + %bleed)" where "base% comes from flat bleed damage affixes (converted to a scaling factor)." The simplest conversion: `base_bleed_pct = total_flat_bleed / avg_weapon_damage`. At T1, flat bleed adds 2-6 damage per affix vs weapon base of ~80-120, so base_bleed_pct would be roughly 3-5%. With the %bleed multiplier on top, this seems intentionally supplemental.

**Alternative simpler approach:** Use flat bleed damage directly as per-tick damage (not scaled by hit). `tick = flat_bleed_avg * (1 + %bleed)`. This is simpler but diverges from the context decision of "scales with hit power." Recommend following the context: hit_damage * base% * (1 + %bleed).

### DOT-04: Poison affix (DEX signature)

**Affix already registered.** "Poison Damage" prefix, "%Poison Damage" suffix, "Poison Chance" suffix exist.

**Runtime implementation:**
- Poison is flat-damage-per-stack, NOT hit-scaled: `tick_per_stack = flat_poison * (1 + %poison)`
- Infinite stacks (no cap)
- Chance overflow: 120% chance = 1 guaranteed + 20% for second stack
- Crit interaction: +100% chance on crit hit (additive with base chance)
- Attack-mode only

**Flat poison value:** From affix definition, flat poison has add_min range 2-3, add_max range 4-6 (tier-scaled). At T1, that's roughly 64-192 add_min and 128-192 add_max. Per tick per stack = avg(add_min, add_max) * (1 + %poison). With fast attack speed (VenomBlade at 1.8 APS) and high poison chance, stacks accumulate quickly.

### DOT-05: Burn affix (fire DoT, INT signature)

**Affix already registered.** "Burn Damage" prefix, "%Burn Damage" suffix, "Burn Chance" suffix exist.

**Runtime implementation:**
- Single stack only, refreshes on new proc
- Hit-scaled like bleed but higher base%: `tick = hit_damage * base_burn% * (1 + %burn)`
- Spell-mode only: burn procs from `_on_hero_spell_hit()`, NOT from `_on_hero_attack()`
- Crit hits produce bigger burns (emergent from hit_damage being crit-multiplied)

**Base burn% should be higher than bleed base%.** Suggest bleed base% conversion factor of 0.15 (15% of hit) and burn base% of 0.25 (25% of hit). These are discretionary values per context.

### DOT-06: DoT damage shown in combat UI

**Three UI elements per context decisions:**

1. **DoT accumulator label:** Single running total near HP bar. Number grows with each tick, fades when all DoTs expire. Visually distinct from floating damage text (persistent, smaller).
   - Implementation: New Label node in gameplay_view's CombatUI tree, positioned near pack/hero HP bars.
   - State tracking: running total float, incremented on each dot_ticked signal, reset on DoT expiry.
   - Fade: start a tween to fade out after last DoT expires (e.g., 2s delay then 1s fade).
   - Color: white default, or color-coded by dominant type (red=bleed, green=poison, orange=burn).

2. **Status text on HP bars:** "BLEED x3", "POISON x7", "BURN" labels.
   - Implementation: Additional Label nodes below/beside HP bars.
   - Updated on dot_applied and dot_expired signals.
   - Format: concatenated string of active DoT types with stack counts.

3. **No floating damage numbers for DoT ticks.** The accumulator replaces per-tick floaters.

### DOT-07: DoT defense interaction design

**Decided in context:**
- DoT bypasses evasion (no dodge check)
- DoT bypasses armor (no physical mitigation)
- Reduced by matching resistance only:
  - Bleed (physical): NO resistance applies (no physical resistance stat exists) -- full damage
  - Poison (chaos): reduced by chaos resistance
  - Burn (fire): reduced by fire resistance
- ES/Life split DOES apply (50/50 like direct hits)
- DoT does NOT bypass ES

**Implementation in DefenseCalculator:**
Add static method:
```gdscript
static func calculate_dot_damage_taken(
    raw_dot_damage: float,
    dot_element: String,  # "physical", "chaos", "fire"
    resistance: int,       # matching resistance (0 for bleed)
    current_es: float,
    max_es: int
) -> Dictionary:
    var damage := raw_dot_damage
    # Apply resistance (skip for physical/bleed)
    if dot_element in ["chaos", "fire"]:
        damage *= (1.0 - calculate_resistance_reduction(resistance))
    # Apply ES/Life split
    if current_es > 0.0 and max_es > 0:
        return apply_es_split(damage, current_es)
    return {"es_damage": 0.0, "life_damage": damage}
```

**CHAOS_RESISTANCE aggregation:** Must add `total_chaos_resistance` to hero.gd `calculate_defense()`. Pattern: iterate all equipment suffixes checking for `CHAOS_RESISTANCE` stat type, same as fire/cold/lightning resistance.

---

## Risk Assessment

### Low Risk
- **DOT-01 (stat types):** Already complete. Zero code change needed.
- **DOT-03/04/05 (affix registration):** Already complete in item_affixes.gd. Runtime stat aggregation is straightforward following existing patterns.
- **DOT-07 (defense):** Simple subset of existing defense pipeline. Well-defined rules.

### Medium Risk
- **DOT-02 (tick system):** Most complex piece. Adding a 4th timer and tick processing to CombatEngine. Risk of timing issues (DoT ticking after pack dies, DoT ticking during pack transition delay, DoT persisting across pack kills). Needs careful lifecycle management.
- **DOT-06 (UI):** Accumulator label is a new UI pattern not used elsewhere. Needs scene tree modification. Risk of visual clutter or positioning issues. Testing requires visual inspection.
- **Warhammer implicit naming:** Currently named "Bleed Chance" but uses `BLEED_DAMAGE` stat type. If runtime code checks affix names, this could cause confusion. Should rename to "Bleed Damage" for consistency.

### High Risk
- **DoT stat aggregation complexity:** Distinguishing flat vs percentage DoT stats using the same `StatType` enum values is error-prone. Flat prefixes use `add_min`/`add_max`, percentage suffixes use `value`. The %DoT Damage prefix also uses `value`. Must handle correctly or DoT damage calculations will be wrong.
- **Poison infinite stacking + fast attack speed:** At high area levels with VenomBlade (1.8 APS) and high poison chance, poison stacks could grow very large (hundreds of stacks). Need to consider performance impact of tracking many individual stacks. Mitigated by 4-second duration -- max practical stacks = ~7 per second * 4 seconds = ~28 stacks.

### Dependencies
- No external dependencies. All needed infrastructure exists.
- No save format changes (DoT effects are transient).
- No new autoloads or scene files needed (except possibly new Label nodes added to existing gameplay_view.tscn).

---

## Validation Architecture

### DOT-01: StatType declarations

**Test (integration_test.gd, Group 30):**
- Assert `Tag.StatType.BLEED_DAMAGE` exists and has expected enum value
- Assert `Tag.StatType.POISON_DAMAGE` exists and has expected enum value
- Assert `Tag.StatType.BURN_DAMAGE` exists and has expected enum value
- Assert `Tag.StatType.BLEED_CHANCE` exists and has expected enum value
- Assert `Tag.StatType.POISON_CHANCE` exists and has expected enum value
- Assert `Tag.StatType.BURN_CHANCE` exists and has expected enum value
- Assert `Tag.DOT` constant equals "DOT"

**Note:** These will pass with no code changes since stat types already exist. Tests serve as regression guard.

### DOT-02: DoT tick system in CombatEngine

**Tests (integration_test.gd, Group 31-33):**

Group 31 -- DoT application:
- Create a hero with bleed chance > 0, simulate attack hit, verify DoT effect created on pack
- Create a hero with burn chance > 0, set `is_spell_user = true`, simulate spell hit, verify burn DoT on pack
- Verify bleed does NOT proc from spell hits
- Verify burn does NOT proc from attack hits
- Verify poison chance overflow: 150% chance creates at least 1 stack, sometimes 2

Group 32 -- DoT tick processing:
- Apply a bleed DoT to a pack, call tick processing 4 times, verify pack takes damage each tick
- Apply a bleed DoT, call tick processing 5 times, verify DoT expired after 4th tick
- Apply multiple bleed stacks (up to 8), verify each ticks independently
- Apply 9th bleed stack, verify oldest stack replaced (one with lowest ticks_remaining)
- Apply poison stacks, verify each stack ticks independently
- Apply burn, then apply again, verify only 1 stack active (refresh)

Group 33 -- DoT lifecycle:
- Verify all pack DoTs cleared on pack kill
- Verify all hero DoTs cleared on hero death
- Verify all DoTs cleared on combat stop
- Verify DoTs do NOT persist between pack fights

### DOT-03: Bleed affix (physical DoT)

**Tests (integration_test.gd, Group 34):**
- Create Warhammer, verify implicit has BLEED_DAMAGE stat type
- Create hero with bleed damage affix on weapon, verify total_bleed_damage is aggregated correctly
- Create hero with bleed chance suffix, verify total_bleed_chance is aggregated
- Verify bleed tick damage scales with hit damage (larger hit -> larger bleed tick)
- Verify crit hit produces proportionally larger bleed (since tick = hit_damage * base%)

### DOT-04: Poison affix (DEX signature)

**Tests (integration_test.gd, Group 35):**
- Create VenomBlade, verify implicit has POISON_DAMAGE stat type
- Verify poison tick is flat (NOT scaled by hit damage)
- Verify poison stacks independently (apply 3 stacks, verify 3x tick damage)
- Verify poison chance overflow: 120% -> guaranteed stack + 20% chance for second
- Verify crit hit adds +100% to poison chance (additive)

### DOT-05: Burn affix (fire DoT)

**Tests (integration_test.gd, Group 36):**
- Create hero with burn damage/chance, set is_spell_user, verify burn procs from spell hits
- Verify burn single-stack: apply burn, apply again, verify only 1 stack (refreshed duration)
- Verify burn tick scales with spell hit damage
- Verify burn does NOT proc from attack hits

### DOT-06: DoT damage shown in combat UI

**Validation approach:** UI testing is primarily visual. Integration tests can verify:
- GameEvents.dot_ticked signal emits with correct parameters
- GameEvents.dot_applied signal emits with correct target/type/stack_count
- GameEvents.dot_expired signal emits when last stack expires

**Manual verification checklist:**
- [ ] DoT accumulator label appears near pack HP bar when hero DoTs are active
- [ ] Accumulator number increases with each tick
- [ ] Accumulator fades out when all DoTs expire
- [ ] Status text shows "BLEED x3", "POISON x7", "BURN" format
- [ ] DoT text is visually distinct from floating combat numbers
- [ ] Pack DoT on hero shows accumulator near hero HP bar

### DOT-07: DoT defense interaction

**Tests (integration_test.gd, Group 37):**
- Call `DefenseCalculator.calculate_dot_damage_taken()` with physical DoT (bleed), resistance=0 -> full damage
- Call with chaos DoT (poison), chaos_resistance=50 -> 50% reduction
- Call with fire DoT (burn), fire_resistance=75 -> 75% reduction (cap)
- Call with fire DoT, fire_resistance=100 -> 75% reduction (over-cap clamped)
- Verify ES/Life split applies: DoT with current_es > 0 -> 50/50 split
- Verify ES overflow: ES portion > current_es -> overflow to life
- Verify hero.total_chaos_resistance is aggregated from CHAOS_RESISTANCE suffixes

---

## Open Questions

1. **Warhammer implicit name:** Currently "Bleed Chance" but stat_type is `BLEED_DAMAGE`. Should it be renamed to "Bleed Damage" for consistency? Or was the intent to provide bleed chance (requiring a stat_type change to `BLEED_CHANCE`)?

2. **Sceptre burn interaction:** Sceptre's implicit is `FLAT_SPELL_FIRE_DAMAGE`, not burn damage. Burn affixes must come entirely from rolled prefixes/suffixes. Is this intentional? (Likely yes -- burn is supplemental, not the primary damage source for INT weapons.)

3. **DoT base% values:** Context defers exact values. Proposed:
   - Bleed base%: 15% of hit damage per tick (60% total over 4 ticks)
   - Burn base%: 25% of hit damage per tick (100% total over 4 ticks)
   - These feel reasonable for "supplemental" damage that doesn't overshadow direct hits.

4. **Poison flat damage per tick:** The flat poison prefix adds 2-6 add_min / 4-6 add_max per affix (tier-scaled). At T1 this would be ~64-96 / 128-192. The tick per stack would be avg(add_min, add_max) * (1 + %poison). Is this per-stack-per-tick or total? Per context: per-stack-per-tick. With fast attackers piling stacks, this needs balance testing.

5. **Pack DoT stacking:** Context says pack DoT on hero likely single-stack refresh for simplicity. Recommend: single bleed/burn stack on hero from pack, refreshing on each new application. This prevents pack DoTs from being lethal at high area levels.

6. **DoT DPS formula for hero stats:** Proposed formula:
   - Bleed DPS = avg_hit_damage * bleed_base% * (1 + %bleed) * bleed_chance/100 * min(attack_speed * 4, 8) (max 8 stacks active)
   - Poison DPS = flat_poison_avg * (1 + %poison) * poison_chance/100 * attack_speed * 4 (stacks = chance * speed * duration)
   - Burn DPS = avg_spell_hit_damage * burn_base% * (1 + %burn) * burn_chance/100 (single stack, always refreshed)
   - Total DoT DPS = sum of applicable types based on is_spell_user

7. **DoT tick timer placement:** Should the 1-second tick timer be a new Timer node in CombatEngine, or use `_process()` with a delta accumulator? Timer is simpler and consistent with existing pattern (hero_attack_timer, pack_attack_timer). Recommend Timer.

---

*Phase: 48-damage-over-time*
*Research completed: 2026-03-08*
