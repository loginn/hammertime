# Pitfalls Research

**Domain:** Hammertime — Adding Min/Max Damage Ranges to Existing Flat-Damage ARPG System
**Researched:** 2026-02-18
**Confidence:** HIGH

---

## Critical Pitfalls

### Pitfall 1: Save Migration Breaks Existing Affix `value` Field — Weapons Load with 0 Damage

**What goes wrong:**
Existing saves store flat damage affixes with a single integer `value` (e.g., `"value": 15`). After converting "Physical Damage" and elemental damage affixes to output a min-damage + max-damage pair instead of a single value, `Affix.from_dict()` at `affix.gd:93` still reads `int(data.get("value", affix.value))`. Loaded affixes end up with a single flat value that StatCalculator interprets as neither a min nor a max — whichever new field was added (e.g., `damage_min`, `damage_max`) defaults to 0. The weapon loads with 0 effective flat damage but no crash occurs, so the bug is silent. DPS displays as correct-ish because percentage-based modifiers still work.

**Why it happens:**
The `_migrate_save()` in `save_manager.gd:159` currently has no v1→v2 migration stub. SAVE_VERSION is 1. Adding damage range fields to Affix without bumping SAVE_VERSION and writing a migration means all existing saves load with the old schema, receive defaults for new fields, and silently produce wrong numbers. The migration hook exists but is empty (`# Future migrations go here`).

**How to avoid:**
1. Bump `SAVE_VERSION` to 2 before merging any Affix schema changes
2. Implement `_migrate_v1_to_v2(data: Dictionary)` that iterates all affixes in hero equipment, crafting inventory, and bench item
3. For each flat damage affix (`stat_types` contains `FLAT_DAMAGE`), synthesize `damage_min` and `damage_max` from the existing `value` field: both fields set equal to `value` (flat damage becomes a degenerate range)
4. After migration the player loses nothing — their flat damage value is preserved as `[value, value]`, which the new system treats as zero-variance damage (perfectly valid starting state)
5. Verify by loading a v1 save after migration: DPS should be identical to pre-migration value

**Warning signs:**
- Weapons display 0 flat damage after load but percentage modifiers work
- DPS drops exactly by the flat damage contribution amount on load
- Save-then-load cycle shows different DPS than before save
- New items crafted post-load have correct min/max, old items have 0

**Phase to address:**
Phase 1 (Save Migration) — Write migration BEFORE changing any Affix fields. The save pipeline must accept old data before the data model changes.

---

### Pitfall 2: DPS Formula Uses `base_damage` as a Single Float — Range Breaks `calculate_dps()` Signature

**What goes wrong:**
`StatCalculator.calculate_dps()` at `stat_calculator.gd:9` takes `base_damage: float` as a scalar. `Weapon.update_value()` passes `self.base_damage` (an int, `light_sword.gd:18`: `base_damage = 10`). After conversion, flat damage affixes contribute a range, not a scalar. If the DPS sheet value is computed using average damage `(min + max) / 2.0`, that is the mathematically correct expected-value DPS. But if the implementation naively replaces `affix.value` with `affix.damage_min` (or `damage_max`), the DPS shown on the item tooltip diverges from actual average combat output by up to 50% of the affix's range.

The correct formula for expected DPS with a damage range:
```
average_flat_damage = (min_damage + max_damage) / 2.0
DPS_sheet = average_flat_damage * speed * crit_multiplier
```
Expected value is NOT `min_damage * speed * crit_multiplier` (pessimistic) nor `max_damage * speed * crit_multiplier` (optimistic).

**Why it happens:**
The existing crit multiplier logic in `stat_calculator.gd:84` already uses correct expected-value math: `1 + c * (d - 1)`. But developers often apply expected-value thinking to crit while treating damage range inconsistently — using either min or max as the "representative" value for the tooltip rather than the mean.

**How to avoid:**
1. When summing flat damage affixes in `calculate_dps()`, sum `(affix.damage_min + affix.damage_max) / 2.0` for each range affix
2. The weapon base itself (`base_damage`) can stay a scalar OR be converted to a range — if it stays scalar, add it directly; if converted, apply the same mean formula
3. The per-hit combat roll in `combat_engine.gd:80` MUST use `randi_range(total_min, total_max)` not the mean — sheet DPS uses mean, actual hits use random draw
4. Test: simulate 10,000 hits, compute average. Assert it is within 2% of sheet DPS value

**Warning signs:**
- Sheet DPS matches combat output only when lightning has 1:1 min:max ratio (degenerate case)
- Average observed damage in combat logs is consistently lower than sheet DPS (min was used) or higher (max was used)
- Lightning DPS appears far lower than physical DPS of equivalent gear because min was used as representative

**Phase to address:**
Phase 2 (DPS Formula Refactor) — Refactor `calculate_dps()` signature before wiring in affix ranges. New signature: `calculate_dps(base_min: float, base_max: float, ...)` or keep scalar base and sum ranges from affixes separately.

---

### Pitfall 3: Affix Tier Schema Needs 4 Values But Current System Encodes 2 — Silent Truncation on Re-roll

**What goes wrong:**
Current Affix tier math in `affix.gd:36-37`:
```gdscript
self.min_value = p_min * (tier_range.y + 1 - tier)
self.max_value = p_max * (tier_range.y + 1 - tier)
self.value = randi_range(self.min_value, self.max_value)
```
This uses `p_min` and `p_max` as the base scalar range for a tier. For flat damage affixes with a damage range, a tier now needs:
- `base_dmg_min_lo`: minimum possible min-damage at tier 1
- `base_dmg_min_hi`: maximum possible min-damage at tier 1
- `base_dmg_max_lo`: minimum possible max-damage at tier 1
- `base_dmg_max_hi`: maximum possible max-damage at tier 1

The current 2-value schema (`p_min`, `p_max`) cannot encode this. If the implementation tries to reuse `min_value` as the rolled min-damage and `max_value` as the rolled max-damage (repurposing the existing fields), the Tuning Hammer (`reroll()` at `affix.gd:46`) calls `randi_range(self.min_value, self.max_value)` — which would reroll `damage_max` between `[damage_min, damage_max]`, not between the template range. After one reroll, max-damage can collapse toward min-damage and never recover.

**Why it happens:**
The Affix class was designed around a single scalar stat. `min_value` and `max_value` are the rolled range for that single stat. Damage ranges introduce a second independent random variable. Conflating the two (using `min_value` = rolled min-damage, `max_value` = rolled max-damage) destroys the template information needed for re-rolls.

**How to avoid:**
1. Add distinct template fields to Affix for damage ranges: `dmg_min_lo`, `dmg_min_hi`, `dmg_max_lo`, `dmg_max_hi` (the tier-1 blueprint values, scaled by tier formula)
2. Add rolled result fields: `rolled_damage_min`, `rolled_damage_max`
3. Keep `value` as legacy field for all non-damage-range affixes (backward compatible)
4. `reroll()` for damage range affixes: `rolled_damage_min = randi_range(dmg_min_lo, dmg_min_hi)`, `rolled_damage_max = randi_range(dmg_max_lo, dmg_max_hi)`
5. Guard: always assert `rolled_damage_min <= rolled_damage_max` after reroll; if violated, swap values
6. `to_dict()` / `from_dict()` must serialize all 4 template fields and both rolled fields

**Warning signs:**
- Tuning Hammer compresses damage range toward zero over repeated uses (max converges to min)
- High-tier items have same damage spread as low-tier (tier scaling lost on re-roll)
- Console output from `print("reroll ", self.value)` in `affix.gd:47` shows `value` changing but damage range does not

**Phase to address:**
Phase 2 (Affix Data Model) — Extend Affix before writing any affix initialization code for damage ranges. Do not repurpose `min_value`/`max_value` for a different semantic.

---

### Pitfall 4: Per-Hit Damage Roll in CombatEngine Skips Affix Ranges — Uses Precomputed DPS Average

**What goes wrong:**
`combat_engine.gd:80` computes per-hit damage as:
```gdscript
var damage_per_hit := hero.total_dps / hero_attack_speed
```
`hero.total_dps` is the expected-value DPS computed by `StatCalculator`. Dividing by `hero_attack_speed` gives expected damage per hit. This is deterministic — every hit deals exactly the same damage. After adding ranges, each hit should roll `randi_range(hero.total_damage_min, hero.total_damage_max)`. If the combat engine is not updated alongside the DPS formula, the variance system is implemented in the model but never used in combat. The tooltip shows "15 to 45 damage" but every hit deals exactly 30.

**Why it happens:**
The DPS sheet update and the combat hit calculation are in separate files (`stat_calculator.gd` vs `combat_engine.gd`). It is easy to update the tooltip display and DPS formula without realizing combat is still using the precomputed average path.

**How to avoid:**
1. Add `total_damage_min: float` and `total_damage_max: float` to `Hero` alongside `total_dps`
2. `hero.update_stats()` populates both min/max totals and total_dps (mean)
3. `CombatEngine._on_hero_attack()` replaces `hero.total_dps / hero_attack_speed` with `randi_range(int(hero.total_damage_min), int(hero.total_damage_max))` for base damage, then applies crit as before
4. The existing per-hit crit roll (`combat_engine.gd:83`) remains correct — range roll and crit roll are independent
5. Floating text labels in `gameplay_view.gd:201` already show int damage — no change needed for display

**Warning signs:**
- Every floating damage number is identical (same value every hit) despite tooltip showing a range
- Adding a "1 to 100 Lightning Damage" affix shows 50.5 DPS on tooltip, but combat shows 50 damage every single hit
- The variance design (Physical tight, Lightning extreme) has no visible effect in combat

**Phase to address:**
Phase 3 (Combat Integration) — Update CombatEngine immediately after extending Hero stats. Add an integration test: equip weapon with wide range, run 100 hits, assert standard deviation > 0.

---

### Pitfall 5: Lightning Variance Makes Idle Game Feel Unfair — Player Sees Death With No Counterplay

**What goes wrong:**
In PoE's design, lightning's high variance (1:N ratio) is balanced by the Shock ailment, which amplifies damage taken by the shocked target. Without a compensating mechanic, pure damage variance creates a problem specific to idle games: the player cannot react to bad RNG streaks. A monster pack that deals "20 to 80 lightning damage" will occasionally roll three 80s in a row, killing a hero who can survive the expected 50 average. The player sees their hero die despite having "enough" stats on paper. This feels like a bug, not a feature.

Lightning with a 5:1 max:min ratio (e.g., 4 to 20) and a 1.8 attacks/second monster produces a standard deviation roughly equal to half the expected damage per second. Over a 10-second fight: expected total = 180 damage, standard deviation ≈ 51 damage (28%). This means a 2-sigma event (95th percentile) deals 282 damage — 57% more than expected. A hero balanced to survive the expected amount has a 5% chance of dying from variance alone per fight.

**Why it happens:**
Developers set variance ratios based on "feels interesting" (wide range = exciting) without modeling the survivability impact. The stat comparison display (forge_view.gd:640) shows only DPS as a single number — players and developers both use DPS as the proxy for survivability, missing the variance dimension entirely.

**How to avoid:**
1. Establish variance ratios by element before implementing: Physical 1:1.5 (e.g., 10-15), Cold 1:2 (e.g., 8-16), Fire 1:2.5 (e.g., 6-15), Lightning 1:4 (e.g., 5-20)
2. Model survivability not as "HP > expected damage" but as "HP > mean + 2*stddev" per fight
3. For lightning specifically: keep average DPS equal to or below fire/cold but with wider spread, ensuring variance is a strategic risk, not invisible RNG death
4. Add variance indicator to the hero stat display (e.g., "Lightning hits: 5-20") so the player understands the risk profile
5. Consider a minimum survivability floor: hero always survives at least 3 hits regardless of element (enforced in combat engine, not by HP math)

**Warning signs:**
- Playtesters report lightning monsters feel "cheesy" or "unfair" even when hero has correct resistances
- Hero death rate is 3x higher against lightning packs than fire packs of the same level despite equal expected DPS
- Hero dies in fights where DPS display suggests comfortable margin
- Players report not understanding why they died (no visible feedback of damage range)

**Phase to address:**
Phase 2 (Balance Parameters) — Define variance ratios on paper before coding affix templates. Do not tune after implementation; this is a design decision that cascades through all affix values.

---

### Pitfall 6: Stat Aggregation Sums Damage Incorrectly When Mixing Range and Scalar Affixes

**What goes wrong:**
`StatCalculator.calculate_dps()` currently adds all `FLAT_DAMAGE` affixes as scalars. After conversion, some affixes are ranges (`rolled_damage_min`, `rolled_damage_max`) and the weapon base may remain a scalar. The aggregation must sum mins separately from maxes:
```
total_min = base_min + sum(affix.rolled_damage_min for range affixes)
total_max = base_max + sum(affix.rolled_damage_max for range affixes)
```
If implementation instead sums the average: `total = base + sum((affix.min + affix.max) / 2)`, then applies the percentage multipliers to this average, the final min and max are NOT correct percentages of their respective values. A "+50% damage" affix applied to average-42.5 gives 63.75 for both min and max — losing the range entirely.

Correct order:
```
total_min = (base_min + sum_flat_mins) * (1 + sum_percent_mults)
total_max = (base_max + sum_flat_maxes) * (1 + sum_percent_mults)
DPS_mean = (total_min + total_max) / 2.0 * speed * crit_mult
```

**Why it happens:**
The existing code in `stat_calculator.gd:22-30` adds flat damage affixes in a loop, then applies the `additive_damage_mult` to the running total. This pattern works for scalars but silently collapses range pairs into a single number if average is used as the intermediate.

**How to avoid:**
1. Run two separate accumulator loops in `calculate_dps()`: one for min totals, one for max totals
2. Apply percentage multipliers to each accumulator independently
3. Return both `total_min_dps` and `total_max_dps` as well as `avg_dps`
4. Verify: a weapon with base 10-20 and "+100% damage" suffix must show 20-40 DPS range (not 30-30)
5. Add an assertion in debug builds: `assert(total_min <= total_max)`

**Warning signs:**
- Adding a "+50% damage" affix collapses the displayed range to a single value
- High-variance weapons show a narrower range after adding percentage modifiers (range is compressed, not scaled)
- The min and max DPS values shown in tooltip are the same number despite the weapon having a range

**Phase to address:**
Phase 2 (DPS Formula Refactor) — Implement dual-accumulator pattern immediately when extending `calculate_dps()`. This is the core math change; getting it wrong breaks all downstream display and balance.

---

### Pitfall 7: UI Labels Overflow at Font Size 11 on 1280x720 — "Physical Damage: 10 to 45" Clips

**What goes wrong:**
The item stats label in `forge_view.gd:782` currently formats damage affixes as `prefix.affix_name + ": " + str(prefix.value)`. At font size 11, "Physical Damage: 15" is approximately 160px wide. Replacing it with "Physical Damage: 10 to 45" adds 8-12 characters, reaching approximately 230-250px. The `ItemStatsPanel` label width is not known from the scene (it's a Label, not RichTextLabel, so no word wrap by default). If the panel is narrower than the rendered text width, the label silently clips — no overflow indicator, no wrapping, just truncation at the panel edge. The player sees "Physical Damage: 10 to 4" and has no idea a number is missing.

Similar overflow risks exist in:
- `hero_stats_label` (RichTextLabel — word-wraps but may push content off screen)
- `format_stat_delta()` comparison strings (`forge_view.gd:588`): "Base Damage: 10 [+5]" becomes "Base Damage Range: 10-15 to 20-45 [+5-15]" — 40+ character gain
- The `item_stats_label` (plain Label) used in `update_item_stats_display()` at line 498 — Label clips by default

**Why it happens:**
Flat single values occupy at most 4-6 digits. Damage ranges use the format "X to Y" which adds 4 characters plus potentially two multi-digit numbers. The UI was sized for the shorter format. Since Label (not RichTextLabel) does not word-wrap by default in Godot, overflow is silent.

**How to avoid:**
1. Switch `item_stats_label` from Label to RichTextLabel with `fit_content = true` and a `ScrollContainer` parent, OR enable `autowrap_mode` on the Label
2. Use abbreviated format for tight spaces: "Phys Dmg: 10-45" (dash instead of " to ") — saves 2 characters and is standard ARPG notation
3. Measure expected max string length at design time: longest affix name "Physical Damage" (15 chars) + ": " (2) + "1000 to 9999" (12) = 29 chars at font size 11 ≈ ~190px; verify panel is at least 200px wide
4. For the stat comparison panel (`format_stat_delta()`), show delta in range format: "[+5 to +15]" — do not try to show before/after ranges in one line
5. Test explicitly: equip a weapon with maximum-value affixes (tier 1 lightning with highest possible numbers) and verify the label does not clip

**Warning signs:**
- Affix lines in item panel end mid-number with no "..." indicator
- "to" appears at end of line with the second number missing (soft-wrap cutting the line, not the number)
- Different affixes display correctly but the longest one clips (only fails at maximum values)
- The panel looks fine in editor preview (Godot previews with different font rendering than runtime)

**Phase to address:**
Phase 3 (UI Display) — Before implementing range display strings. Audit all Label nodes that show affix values. Switch to RichTextLabel or enable autowrap. Test with longest possible strings before connecting data.

---

### Pitfall 8: `is_item_better()` Comparison Uses `tier` — DPS Range Makes This Stale

**What goes wrong:**
`forge_view.gd:466`:
```gdscript
func is_item_better(new_item: Item, existing_item: Item) -> bool:
    return new_item.tier > existing_item.tier
```
This comparison drives the auto-replace logic when a new item drops. With flat damage, higher tier = higher base_damage = more DPS. With ranges, a lower-tier weapon with a lucky high-end range roll may have higher actual DPS than a higher-tier weapon with a poor roll. A tier 5 weapon with max roll beats a tier 3 with min roll. The tier comparison will discard the better weapon.

Additionally: the Weapon DPS stat comparison in `get_stat_comparison_text()` at `forge_view.gd:640` compares `weapon.dps` (a precomputed average) — this comparison remains correct for the display, but `is_item_better()` ignores DPS entirely.

**Why it happens:**
The `tier` shortcut was acceptable when damage was a linear function of tier. Adding per-roll variance breaks the monotonic relationship between tier and DPS. This is a design assumption violation.

**How to avoid:**
1. Replace `is_item_better()` for weapons and rings with a DPS-based comparison: `new_item.dps > existing_item.dps`
2. For armor items (no DPS), keep tier comparison OR switch to `get_total_defense()` comparison
3. Consider making the auto-replace threshold more conservative: only auto-replace if new item is strictly better by a margin (>5% DPS), otherwise let the player decide
4. The stat comparison display already uses DPS (`forge_view.gd:641`) — it is already correct for display purposes; only `is_item_better()` needs fixing

**Warning signs:**
- A rare, high-DPS weapon is auto-discarded in favor of a just-dropped normal item with higher tier but lower DPS
- Player equips a weapon manually and the inventory keeps offering "better" items that are visibly worse
- The crafting bench displays a "better" item but the hero stat comparison shows a DPS loss

**Phase to address:**
Phase 3 (UI Integration) — When DPS becomes range-derived, update `is_item_better()`. This is a one-line fix but easy to miss since the feature appears to work correctly until a high-variance drop exposes it.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Use `(min + max) / 2` everywhere and never expose actual range to combat engine | Simpler implementation, no combat engine changes | Per-hit variance never surfaces; variance system is cosmetic only | Never — defeats the purpose |
| Reuse `min_value`/`max_value` fields to mean "rolled_min_damage" / "rolled_max_damage" | No new Affix fields needed | Tuning Hammer reroll corrupts range (cannot recover template bounds) | Never |
| Skip save migration, delete old saves, start fresh | Zero migration code | Player loses all progress; unacceptable for any non-alpha release | Alpha only, with explicit warning |
| Format all damage as average in UI ("Physical Damage: 27") | UI unchanged, no overflow risk | Players cannot see variance; lightning vs physical feel identical on paper | Never — the feature becomes invisible |
| Keep `is_item_better()` using tier | No change to inventory logic | Good high-variance drops auto-discarded | Acceptable until first playtest reveals it |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| `calculate_dps()` with ranges | Pass average damage as the scalar base | Sum min/max separately through all steps; return mean, min, max |
| CombatEngine per-hit damage | Continue using `total_dps / attack_speed` | Roll `randi_range(total_min, total_max)` per hit, then apply crit |
| Affix.reroll() with damage ranges | Reroll `value` field (scalar) unchanged | Reroll `rolled_damage_min` and `rolled_damage_max` independently |
| Save migration for old affixes | Leave `SAVE_VERSION = 1`, add new fields | Bump to v2, write migration that derives min/max from old `value` |
| Stat comparison display (forge_view) | Show "Base Damage Range: X-Y to A-B [delta]" on one line | Show current DPS delta only; let dedicated tooltip show full range breakdown |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| `randi_range()` called multiple times per timer tick per element type | Micro-stutter at 5+ affixes per hit | One consolidated roll: compute total_min/total_max first, one `randi_range()` call | 10+ affixes on weapon, 1.8 attacks/sec |
| Recomputing `total_damage_min` / `total_damage_max` on every hit | CPU spike at fast attack speeds | Cache on `Hero.update_stats()`, only recompute on equipment change | Attack speed > 3.0/sec |
| Label re-layout every hit (Label resize for longer range strings) | UI jank on high attack speed | Pre-size labels to maximum expected width; do not use `fit_content` on per-hit labels | Combat damage labels at > 2 attacks/sec |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Show damage range on tooltip but single DPS number on hero panel | Player cannot understand why two similar-DPS weapons feel different in combat | Add "Damage: X to Y" line below DPS on hero panel |
| No visual indicator of variance tier (tight vs swingy) | Lightning builds surprise players with high death rate | Color-code or tag the damage range: narrow range = blue, wide range = yellow |
| Stat comparison shows old "Base Damage: X" label after range added | Player confused by mismatch between tooltip and comparison text | Update all display paths simultaneously; do not leave dead code paths |
| Tuning Hammer re-rolls collapse range over time (if Pitfall 3 not fixed) | Crafted items get progressively worse on re-roll | Fix Affix data model before releasing Tuning Hammer functionality |
| Auto-replace discards better weapon (Pitfall 8) | Player loses a good drop without knowing | Add console/UI notification: "Item discarded (lower tier): [name] [DPS]" |

---

## "Looks Done But Isn't" Checklist

- [ ] **DPS Formula:** Tooltip shows correct DPS but have you verified per-hit combat rolls use `randi_range(min, max)` not `total_dps / speed`? (Pitfall 4)
- [ ] **DPS Formula:** Percentage multipliers applied to average, not to min/max separately? (Pitfall 6 — verify with "+100% damage" test)
- [ ] **Save Migration:** New affix fields added but SAVE_VERSION still 1? (Pitfall 1 — check `save_manager.gd:6`)
- [ ] **Affix Re-roll:** Tuning Hammer applies to new rolled fields? Test 10 rerolls, verify max-damage never drops below original min-damage (Pitfall 3)
- [ ] **Lightning Balance:** Hero dies 3x more often to lightning vs fire at same level? Check variance ratios (Pitfall 5)
- [ ] **UI Labels:** Tested with maximum-tier lightning affix (widest possible number string)? (Pitfall 7 — "Lightning Damage: 1000 to 4000" test)
- [ ] **is_item_better():** A tier-3 weapon with 200 DPS auto-replaced by a tier-5 weapon with 80 DPS? (Pitfall 8)
- [ ] **Stat Aggregation:** Two flat damage range affixes sum to combined min+min and max+max? (Pitfall 6 — equip two range affixes, verify display range equals sum)
- [ ] **Combat Variance Visible:** Floating damage numbers show different values hit-to-hit for a lightning weapon? (Pitfall 4 — watch combat for 10 hits)
- [ ] **Export Save String:** HT1 base64 format includes all new Affix fields (`rolled_damage_min`, `rolled_damage_max`, template fields)? (Pitfall 1 — export, import, verify DPS unchanged)

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Missing save migration (v1 loads with 0 damage) | MEDIUM | 1. Write migration immediately 2. Bump SAVE_VERSION to 2 3. Test with a v1 fixture save 4. Cannot recover player saves already corrupted — they must start fresh if deployed |
| Wrong DPS formula (average not mean of separate min/max) | LOW | 1. Fix accumulator loop 2. Re-verify against formula sheet 3. No save impact (DPS is recomputed on load) |
| Affix re-roll corrupts range (Pitfall 3) | HIGH | 1. Must add template fields to Affix 2. Must bump SAVE_VERSION again (to 3) 3. Migration v2→v3 must reconstruct template fields from rolled values (lossy — cannot recover true template if already corrupted) |
| Lightning variance causing unfair deaths | LOW | 1. Reduce lightning max-damage ratio 2. No save migration needed (template values only in ItemAffixes, not saved) 3. Existing items retain old rolls until Tuning Hammer re-roll |
| Label overflow clips numbers | LOW | 1. Switch affected Labels to RichTextLabel 2. Enable autowrap OR size panel wider 3. Test immediately — no data changes required |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Old saves load with 0 flat damage (Pitfall 1) | Phase 1: Save Migration | Load a saved v1 fixture; assert weapon DPS unchanged after migration |
| DPS formula uses wrong representative value (Pitfall 2) | Phase 2: DPS Formula Refactor | Simulate 10,000 hits; assert mean within 2% of sheet DPS |
| Affix re-roll collapses range (Pitfall 3) | Phase 2: Affix Data Model | Apply Tuning Hammer 20x; assert `rolled_max >= original_min` throughout |
| Combat always deals average damage (Pitfall 4) | Phase 3: Combat Integration | Watch 10 consecutive hits; assert standard deviation > 0 |
| Lightning variance causes unfair deaths (Pitfall 5) | Phase 2: Balance Parameters | Simulate 100 fights vs lightning pack; assert hero death rate < 10% at designed survivability margin |
| Percentage mults collapse min/max range (Pitfall 6) | Phase 2: DPS Formula Refactor | Assert: base 10-20 + 100% mult = 20-40 (not 30-30) |
| Label overflow clips numbers (Pitfall 7) | Phase 3: UI Display | Display longest possible affix string; assert no clipping at 1280x720 |
| is_item_better() discards better weapon (Pitfall 8) | Phase 3: UI Integration | Drop low-tier high-DPS weapon; assert it is not auto-discarded in favor of high-tier low-DPS item |

---

## Sources

- [Path of Exile Wiki: Lightning Damage — Variance Design](https://www.poewiki.net/wiki/Lightning_damage)
- [Last Epoch: Damage Calculations Explained (Expected Value vs Hit Variance)](https://maxroll.gg/last-epoch/resources/damage-explained)
- [Godot Issue #89795: randi() performance vs randi_range()](https://github.com/godotengine/godot/issues/89795)
- [Godot Docs: Random Number Generation](https://docs.godotengine.org/en/stable/tutorials/math/random_number_generation.html)
- [You Smack the Rat for ??? Damage — James Margaris (damage variance design essay)](https://jmargaris.substack.com/p/you-smack-the-rat-for-damage)
- [Path of Exile 2: Item Modifiers Explained — tier + sub-range structure](https://mobalytics.gg/poe-2/guides/item-modifiers)
- Codebase analysis: `affix.gd`, `stat_calculator.gd`, `combat_engine.gd`, `hero.gd`, `forge_view.gd`, `save_manager.gd`, `item_affixes.gd`, `light_sword.gd`

---
*Pitfalls research for: Hammertime — Damage Range Milestone*
*Researched: 2026-02-18*
*Confidence: HIGH — Based on direct codebase analysis (all file paths verified), ARPG design references, and Godot-specific documentation*
