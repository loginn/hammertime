# Feature Research

**Domain:** ARPG Damage Range System — Hammertime v1.4
**Researched:** 2026-02-18
**Confidence:** HIGH (ARPG conventions verified via PoE Wiki, Diablo 2/4 documentation; codebase analysis confirms integration points)

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist in any ARPG with elemental damage. Missing these = system feels unfinished.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Weapon base damage as min-max range | Every ARPG (Diablo, PoE) expresses weapon damage as "X-Y damage" — a single flat number reads as a mobile game prototype | LOW | Replace `base_damage: int` with `base_min_damage: int` + `base_max_damage: int` on Weapon; LightSword already has `base_damage = 10`, convert to e.g. 8-12 |
| Per-hit damage rolling in CombatEngine | Rolling each hit separately is what makes combat exciting vs. pure expected-value math — players expect to see variance in floating numbers | LOW | `randi_range(min_damage, max_damage)` per hit in `_on_hero_attack()`; replaces current `damage_per_hit = hero.total_dps / hero_attack_speed` |
| Flat damage affixes as "adds X to Y" ranges | PoE/Diablo standard: affixes read "Adds 5 to 12 Fire Damage" not "Adds 8 Fire Damage" | MEDIUM | Affix already has `min_value`/`max_value` fields; need to store two values (add_min, add_max) that roll independently per hit instead of a single rolled `value` |
| DPS display using average | Every ARPG tooltip shows DPS as `(min+max)/2 * speed * crit_multiplier` — players need a stable number for gear comparison, not a range | LOW | StatCalculator.calculate_dps() currently takes `base_damage: float`; change call site to pass `(base_min + base_max) / 2.0` as the average |
| Item tooltip shows "X to Y" damage range | Weapons in Diablo 4 and PoE display the raw range, not the average, so players can evaluate variance — "8 to 42 Lightning Damage" communicates both floor and ceiling | LOW | Update item_view / forge_view stat display strings from `"%d" % value` to `"%d to %d" % [min_val, max_val]` for damage affixes and weapon base |
| Element-specific variance identity | Lightning is "spiky and extreme" in all ARPGs (PoE: "Adds 1 to 1000 Lightning Damage"); Physical is consistent/reliable; Cold is moderate — this is genre convention | MEDIUM | Define variance multipliers per element type; apply when generating affix min/max values. Physical: tight (ratio ~1.5:1), Cold: moderate (~3:1), Fire: wide (~5:1), Lightning: extreme (~10:1+) |
| Monster damage ranges | Monster hits should also vary — static pack.damage reads as unpolished | LOW | `MonsterPack.damage` is currently a scalar; convert to min/max range, roll per hit in `_on_pack_attack()` |

### Differentiators (Competitive Advantage)

Features not required by convention but meaningful for this specific game's identity.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Element variance shown in tooltip hint | Instead of just "8 to 42", a small text hint like "High variance" for lightning and "Consistent" for physical — makes the variance system legible to players | LOW | Simple string lookup by element type; adds storytelling to damage numbers |
| Hero View DPS breakdown by element | Show Physical DPS, Fire DPS, Cold DPS, Lightning DPS separately so players understand their damage composition | MEDIUM | Requires StatCalculator to track per-element averages; hero.gd currently exposes only `total_dps` |
| Min DPS and Max DPS as secondary stats | Show "DPS range: 40-120" alongside "Avg DPS: 80" so players understand their hit floor and ceiling | LOW | Simple: `(min_damage * speed)` and `(max_damage * speed)` × crit multiplier; display alongside avg DPS |
| Floating number variance feedback | Players see numbers ranging from small hits to giant crits — especially dramatic with high-variance lightning | NONE | Already works once per-hit rolling is in place; floating_label.gd already handles crit styling |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Store rolled per-hit value on Affix.value | Simplest approach — just roll once at item creation and show that | Misleads players: "5 fire damage" hides that the affix could have rolled 1-12; loses variance identity entirely | Keep `add_min`/`add_max` as the affix's data; roll at combat time |
| Lucky/Unlucky damage rolls (PoE mechanic) | Advanced PoE feature — roll twice, take better/worse | Adds significant complexity, needs UI explanation, zero value for idle game | Skip; standard uniform roll is sufficient |
| DPS tooltip using maximum damage only | "Looks bigger" to players | Misleading; makes all items look better than they perform; breaks gear comparison math | Always use average `(min+max)/2` for DPS display |
| Separate weapon and affix ranges summed separately in tooltip | Technically correct breakdown | Creates tooltip complexity players don't need in an idle game — they want one number to compare | Sum all flat damage ranges into total weapon range, show one "X to Y Damage" line |
| Storing weapon range on Hero as `hero.min_dps` / `hero.max_dps` | Feels natural | Hero.gd is already complex; adding more DPS variants bloats the API | Compute min/max DPS on-demand in UI layer; Hero exposes `total_dps` (avg) only |
| Float damage ranges on affixes | More granularity | Existing affixes use `int` throughout — floats would require migration across serialization, display, and math | Keep all damage values as `int`; float only at DPS calculation step |

---

## Feature Dependencies

```
[1] Weapon Base Damage Range (min/max on Weapon)
    └──required-by──> [3] Per-Hit Rolling (needs values to roll between)
    └──required-by──> [5] DPS Average Calculation (needs min+max to average)
    └──required-by──> [6] Tooltip "X to Y" Display (needs range to show)

[2] Affix Damage Range (add_min / add_max stored, rolled per hit)
    └──required-by──> [3] Per-Hit Rolling (affix flat added to weapon roll)
    └──required-by──> [5] DPS Average Calculation (affixes averaged separately)
    └──required-by──> [6] Tooltip "X to Y" Display (affix shows range)

[4] Element Variance Identity (variance ratio per element)
    └──required-by──> [2] Affix Damage Range (determines how wide the affix range is)
    └──enhances──> [7] Variance Hint in Tooltip (labels the element character)

[3] Per-Hit Rolling in CombatEngine
    └──required-by──> [8] Monster Damage Range (same rolling pattern for pack attacks)
    └──enhances──> [Floating Numbers] (already exists; range rolling adds visual drama)

[5] DPS Average Calculation
    └──required-by──> StatCalculator.calculate_dps() signature change
    └──required-by──> Hero.total_dps (computed from averaged range)
    └──independent──> [3] Per-Hit Rolling (display vs. combat are separate)
```

### Dependency Notes

- **Weapon base damage range blocks everything:** Until `base_min_damage`/`base_max_damage` exist on Weapon, neither rolling nor display works. This is Phase 1.
- **Affix damage range is independent from weapon range at the data layer:** `Affix.min_value`/`Affix.max_value` already exist but currently represent the tier-scaled value band; for damage affixes, these become `add_min`/`add_max` rolled per hit rather than at item generation. Requires careful reading of how existing code uses `affix.value`.
- **StatCalculator and CombatEngine are decoupled correctly:** StatCalculator computes expected-value DPS (shown in UI); CombatEngine rolls actual per-hit damage. These should remain separate — do not merge.
- **Monster damage range is lowest-risk change:** `MonsterPack.damage` is a scalar used only in `_on_pack_attack()`; converting to min/max range touches one call site.

---

## MVP Definition

### Launch With (v1.4 milestone)

Minimum set to replace the flat damage model with ranges.

- [ ] **Weapon base damage as min-max range** — `LightSword.base_damage = 10` becomes `base_min = 8, base_max = 12`; every Weapon subclass updated
- [ ] **Element variance ratios defined** — Per-element constants (Physical 1.5:1, Cold 3:1, Fire 5:1, Lightning 10:1) used when building affix ranges
- [ ] **Flat damage affixes store add_min / add_max** — Affix data model extended; existing `affix.value` field retired for damage affixes (or repurposed as the per-hit roll result)
- [ ] **Per-hit rolling in CombatEngine** — Hero attacks roll `randi_range(total_min, total_max)` per hit; replaces `total_dps / attack_speed` for actual combat
- [ ] **Monster damage range** — MonsterPack.damage becomes min/max; pack attacks roll per hit
- [ ] **DPS display uses average** — StatCalculator receives `(min+max)/2` as base_damage; display unchanged from player's perspective but now mathematically accurate
- [ ] **Item tooltip shows "X to Y"** — Weapon stat panel shows e.g. "8 to 42 Lightning Damage"; damage affixes show "Adds 5 to 18 Fire Damage"

### Add After Validation (v1.x)

- [ ] **Element variance hint in tooltip** — "High variance" / "Consistent" label once players understand the range display
- [ ] **Per-element DPS breakdown in Hero View** — Physical/Fire/Cold/Lightning DPS separately when build diversity grows
- [ ] **Min/Max DPS display alongside Avg DPS** — "DPS range: 40-120 (avg 80)" as secondary stat once core ranges ship

### Future Consideration (v2+)

- [ ] **Lucky/Unlucky damage rolls** — PoE mechanic; only relevant if status ailments or buffs are added
- [ ] **Damage range visualization** — Bar or histogram showing spread; heavy UI investment for an idle game

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Weapon base damage range | HIGH | LOW | P1 |
| Element variance ratios | HIGH | LOW | P1 |
| Affix add_min / add_max data model | HIGH | MEDIUM | P1 |
| Per-hit rolling in CombatEngine | HIGH | LOW | P1 |
| Monster damage range | MEDIUM | LOW | P1 |
| DPS display using average | HIGH | LOW | P1 |
| Item tooltip "X to Y" display | HIGH | LOW | P1 |
| Variance hint in tooltip | MEDIUM | LOW | P2 |
| Per-element DPS breakdown | MEDIUM | MEDIUM | P2 |
| Min/Max DPS alongside Avg DPS | LOW | LOW | P2 |
| Lucky/Unlucky rolls | LOW | HIGH | P3 |

**Priority key:**
- P1: Required for v1.4 milestone — the feature is the milestone
- P2: Polish pass after core ranges work
- P3: Deferred; needs design justification to add

---

## ARPG Convention Reference

Sourced from Path of Exile, Diablo 2, and Diablo 4 to establish what "correct" looks like.

### (1) Weapon Base Damage Ranges

In all ARPGs studied, weapon base damage is expressed as a min-max range, not a scalar:
- Diablo 4: weapon tooltip shows "43-81 Damage" with attacks per second below it; DPS is `(43+81)/2 * 1.4 = 86.8`
- Path of Exile: base weapon shows "9-22 Physical Damage" — multiplied by all modifiers
- Design rule: the range represents the variance envelope of the weapon archetype; a dagger has tight physical range, a scepter has wide elemental range

**Application to Hammertime:** `LightSword.base_damage = 10` becomes a range. Fast weapons (high attack speed) conventionally have tighter ranges than slow heavy weapons. Suggested: LightSword 8-12, heavier weapons wider.

### (2) Flat Damage Affix Ranges ("Adds X to Y")

PoE affixes are explicitly defined with add_min and add_max — the item tooltips display "Adds 11 to 19 Physical Damage." This range is separate from the weapon base range. At hit time, the weapon base rolls its range AND the affix rolls its range independently; both are summed. DPS is computed as `(weapon_avg + affix_avg) * speed * crit`.

Existing `Affix` class in Hammertime already has `min_value` and `max_value` fields (tier-scaled), but currently the affix rolls a single `value` at item generation. For damage ranges, the affix must instead store two range boundaries and roll at combat time.

**Current code path to change:**
```gdscript
# Current (item generation time roll):
self.value = randi_range(self.min_value, self.max_value)

# Target (combat time roll for damage affixes):
# affix.add_min and affix.add_max define the range
# CombatEngine does: randi_range(affix.add_min, affix.add_max) per hit
```

**Serialization note:** `add_min`/`add_max` must be included in `Affix.to_dict()` / `from_dict()` for save compatibility.

### (3) Element Variance Identity

Verified from Diablo 2 community documentation and PoE Wiki:

| Element | Variance Profile | Design Intent | Ratio Example |
|---------|-----------------|---------------|---------------|
| Physical | Tight, consistent | Reliable baseline; mastery of fundamentals | 8 to 12 (1.5:1) |
| Cold | Moderate | Balanced; cold is controlled, precise | 5 to 15 (3:1) |
| Fire | Wide | Explosive, chaotic; fire burns unpredictably | 3 to 18 (6:1) |
| Lightning | Extreme | "1 to 1000" — massive ceiling, near-zero floor; pure gambler's damage | 1 to 30 (30:1 extreme) |

The Diablo 2 wiki explicitly documents lightning: "Lightning Damage has an extremely large damage range, sometimes ranging from a measly 1 to a player-killing 2000." This is intentional genre convention — lightning identity is variance.

**Implementation approach for Hammertime:** Define a `VARIANCE_RATIO` constant per element. When building an affix range for a given element and tier, set:
```
add_min = base_roll / variance_ratio  (rounded down, minimum 1)
add_max = base_roll * variance_ratio
```
This keeps the average damage equal across elements (same DPS at same tier) while dramatically differing the distribution.

### (4) Per-Hit Rolling

PoE Wiki confirms: "The damage number rolled is rolled per hit, and not per skill use." Guild Wars 2 uses the same pattern: "whenever a weapon skill deals damage, a value is chosen at random from the range of weapon strength."

This means:
- The DPS stat in the UI is a theoretical average (`(min+max)/2 * speed * crit`)
- Every actual hit in combat generates a fresh roll
- Crit rolls happen separately on top of the damage roll (already implemented in CombatEngine)

**Current CombatEngine hit path:**
```gdscript
var damage_per_hit := hero.total_dps / hero_attack_speed  # expected value
```
**Target:**
```gdscript
var base_hit := randi_range(hero.total_min_damage, hero.total_max_damage)
var damage_per_hit := float(base_hit)
if is_crit:
    damage_per_hit *= (hero.total_crit_damage / 100.0)
```

### (5) DPS Calculation with Ranges

Standard formula across all ARPGs studied:
```
DPS = average_damage * attacks_per_second * crit_multiplier
average_damage = (min_damage + max_damage) / 2
```

Where `min_damage` and `max_damage` are the sum of weapon base min/max and all flat added damage affix min/max.

StatCalculator currently receives `base_damage: float` (a scalar). The change: call site in `Weapon.update_value()` passes `(base_min_damage + base_max_damage) / 2.0` as the base, and affix averaging is unchanged (affixes also provide their average at DPS time).

Alternatively, StatCalculator's signature could be updated to accept `base_min` and `base_max` and average internally — cleaner long-term.

### (6) Display Conventions

From Diablo 4 and PoE, confirmed:
- **Weapon tooltip:** Shows raw range "43 to 81 Physical Damage" — not the average
- **DPS stat:** Shows computed average as a single number (largest number on the tooltip)
- **Affix display:** "Adds 11 to 19 Fire Damage" — the range, not a single value
- **Hero stat panel:** Shows "DPS: 86.8" — the theoretical average, matching Diablo 4's approach

Guild Wars 2 confirms the midpoint convention: "when a damage value is displayed in skill tooltips, the midpoint of the range is used to calculate the displayed value."

**Application to Hammertime:**
- Weapon item card: "8 to 42 Lightning Damage" (base + elemental implicit)
- Damage affix line: "Adds 3 to 18 Fire Damage" (the stored range, not a rolled snapshot)
- Hero Offense section: "DPS: 84.2" (unchanged; still average-based)
- Floating combat numbers: the actual per-hit roll (already working; will now vary more)

---

## Integration Points with Existing System

| Existing Component | Current State | Required Change | Complexity |
|-------------------|---------------|-----------------|------------|
| `Weapon.base_damage: int` | Single scalar | Split to `base_min_damage`/`base_max_damage` | LOW |
| `LightSword._init()` | `base_damage = 10` | `base_min_damage = 8, base_max_damage = 12` | LOW |
| `StatCalculator.calculate_dps(base_damage: float)` | Takes single value | Accept min+max or average; average at call site | LOW |
| `Weapon.update_value()` | Passes `base_damage` to StatCalculator | Pass `(base_min + base_max) / 2.0` | LOW |
| `Affix` data model | `min_value`/`max_value` for tier scaling; single `value` rolled at init | Add `add_min`/`add_max` for damage affixes; retain `value` for non-damage affixes | MEDIUM |
| `Affix.to_dict()` / `from_dict()` | Does not include add_min/add_max | Add both fields; save format version bump | LOW |
| `CombatEngine._on_hero_attack()` | `hero.total_dps / hero_attack_speed` | `randi_range(hero.total_min_damage, hero.total_max_damage)` | LOW |
| `Hero.total_dps` | Single float, computed by StatCalculator avg | Unchanged; avg DPS is still the display value | NONE |
| `Hero` (new fields needed) | No min/max damage tracking | Add `total_min_damage: int` + `total_max_damage: int` computed by Hero.calculate_dps() | LOW |
| `MonsterPack.damage` | Scalar float | Add `min_damage`/`max_damage`; roll in CombatEngine | LOW |
| `CombatEngine._on_pack_attack()` | `pack.damage` as scalar | `randi_range(pack.min_damage, pack.max_damage)` | LOW |
| Forge/Item tooltip display | Single value strings | Range strings for damage fields | LOW |
| `item_affixes.gd` affix definitions | `Affix.new("Fire Damage", ...)` with single base_min/base_max | New damage affixes need element variance applied to their ranges | MEDIUM |

---

## Sources

**Path of Exile Damage Wiki (HIGH confidence — official wiki):**
- [Flat damage | PoE Wiki](https://www.poewiki.net/wiki/Flat_damage) — Confirms "adds X to Y" format, per-hit rolling, DPS = (min+max)/2
- [Damage | PoE Wiki](https://www.poewiki.net/wiki/Damage) — Per-hit rolling confirmed: "rolled per hit, not per skill use"; lightning high variance documented
- [Lightning damage | PoE Wiki](https://www.poewiki.net/wiki/Lightning_damage) — Element variance identity confirmed

**Diablo 2 (HIGH confidence — established game documentation):**
- [Lightning (Damage) | Diablo Wiki](https://diablo.fandom.com/wiki/Lightning_(Damage)) — "extremely large damage range, sometimes ranging from 1 to 2000"; cold as lowest damage/highest control
- [Elemental Damage | Diablo Wiki](https://diablo.fandom.com/wiki/Elemental_Damage) — Lightning adds highest max damage; cold adds lowest damage values

**Diablo 4 (HIGH confidence — documented mechanic):**
- [Damage Per Second | Diablo Wiki](https://www.diablowiki.net/Damage_Per_Second) — DPS = avg(min, max) * attacks/sec; "2-5 Damage = 3.5 average"
- [In-Depth Damage Guide | Maxroll D4](https://maxroll.gg/d4/resources/in-depth-damage-guide) — Flat affixes incorporated before DPS display

**Guild Wars 2 (HIGH confidence — official wiki):**
- [Damage calculation | GW2 Wiki](https://wiki.guildwars2.com/wiki/Damage_calculation) — "midpoint of range used for tooltip DPS"; per-hit random from range confirmed

**Path of Exile 2 (MEDIUM confidence — WebSearch):**
- [Damage Scaling | Maxroll PoE2](https://maxroll.gg/poe2/getting-started/damage-scaling) — "Adds X to Y" format consistent with PoE1

---
*Feature research for: Hammertime v1.4 Damage Range System*
*Researched: 2026-02-18*
*Confidence: HIGH (PoE Wiki, Diablo 2/4 docs verified; codebase analysis HIGH confidence)*
