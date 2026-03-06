# Phase 37: Affix Tier Expansion - Research

**Researched:** 2026-03-01
**Domain:** GDScript data model editing — affix tier ranges and base value retuning
**Confidence:** HIGH

## Summary

Phase 37 is a data and configuration update, not an architectural change. The `Affix` class in `models/affixes/affix.gd` already supports arbitrary `Vector2i` tier ranges via `tier_range`, and the tier scaling formula `value = base * (tier_range.y + 1 - tier)` is already implemented. The single source of truth for all affix definitions is `autoloads/item_affixes.gd`. Expanding to 32 tiers requires: (1) changing every `Vector2i(1, 8)` and `Vector2i(1, 30)` to `Vector2i(1, 32)`, (2) retuning `base_min`/`base_max` (and `dmg_*` bounds for flat damage affixes) so that tier 32 (the worst tier, rolled by P0 item tier 8) produces roughly the same floor as the old tier 8 values, and (3) bumping the save version so old saves are discarded.

The default `tier_range` in `Affix._init()` is `Vector2i(1, 8)` — any affix that omits the tier_range parameter currently inherits this default. There are 10 affixes in `item_affixes.gd` that currently omit `tier_range` (using the 8-tier default implicitly) and must be explicitly updated. The `ITEM_TIERS_BY_PRESTIGE` constant in `prestige_manager.gd` uses 8-item-tier values (1-8) which remain valid; Phase 38 will add affix-tier-gating on top of item tiers.

No new functions, classes, or files are required. `is_item_better()` in `forge_view.gd` is a single-line comparison (`new_item.tier > existing_item.tier`) that stays untouched — item tier comparison is Phase 38's concern.

**Primary recommendation:** Edit `item_affixes.gd` to set all `tier_range` to `Vector2i(1, 32)` with retuned base values, then bump `SAVE_VERSION` in `save_manager.gd`.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- Keep the existing LINEAR formula: `value = base * (tier_range.y + 1 - tier)`
- 32x spread at tier 1 is intentional — game difficulty increases exponentially
- Flat damage affixes keep the 4-bound scaling system (dmg_min_lo/hi, dmg_max_lo/hi) across 32 tiers
- Percentage-based affixes (%Physical Damage, %Armor, Attack Speed, etc.) use the same linear formula — large percentage values are fine
- Tier rolling remains fully random across the full tier_range (1-32)
- Backward compatibility not a concern: bump save version, new game on old save (no migration)
- Do NOT add an affix.quality() function
- is_item_better() continues using its current logic until Phase 38 introduces item_tier
- Full rebalance pass across ALL affixes (offensive and defensive) for 32-tier scaling
- Preserve relative power flavor between damage types:
  - Lightning: widest spread (volatile, 1:4 ratio style)
  - Physical: tightest spread (consistent, 1:1.5 ratio style)
  - Fire: wide (1:2.5 ratio style)
  - Cold: moderate (1:2 ratio style)
- Disabled suffixes remain disabled

### Claude's Discretion

- Specific base_min/base_max values for each affix at 32 tiers
- Whether any affixes need special treatment beyond the standard linear formula
- How to handle the resistance affixes (currently 1-8 and 1-5 ranges) in the rebalance

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope

</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| AFFIX-01 | Affix tiers expand from 8 to 32 levels (4 affix tiers per item tier band) | `tier_range` is already a `Vector2i` field; changing to `Vector2i(1, 32)` is the complete implementation. The Affix class, `from_affix()` cloning, `to_dict()`/`from_dict()` serialization, and all currency hammer logic all use `tier_range` dynamically — no structural changes needed beyond the data values. |
| AFFIX-02 | Affix quality normalization helper enables correct cross-range tier comparison | **Decision: Do NOT implement quality().** User decided is_item_better() will use item_tier (Phase 38). AFFIX-02 is satisfied by the tier_range expansion itself — normalized comparison is deferred to Phase 38. The planner should note that the requirement description is technically superseded by the user's decision from CONTEXT.md. |

</phase_requirements>

---

## Standard Stack

### Core
| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| GDScript | Godot 4.5 | All game logic | Project language |
| `autoloads/item_affixes.gd` | Current | Central affix registry — single file to modify | All affixes defined here; `from_affix()` clones at roll time |
| `models/affixes/affix.gd` | Current | Affix data model and tier scaling formula | Already supports arbitrary Vector2i tier_range |
| `autoloads/save_manager.gd` | Current | Save version gating | SAVE_VERSION bump discards old saves |

### No External Libraries

This phase involves only data editing within existing GDScript files. No new libraries, no new nodes, no new autoloads.

## Architecture Patterns

### Tier Scaling Formula (Existing — No Change)

```gdscript
# Source: models/affixes/affix.gd:56-57
self.min_value = p_min * (tier_range.y + 1 - tier)
self.max_value = p_max * (tier_range.y + 1 - tier)
```

At `tier_range = Vector2i(1, 32)`:
- Tier 1 (best): multiplier = 32
- Tier 32 (worst): multiplier = 1

This means `base_min` and `base_max` become the **tier-32 floor values**.

### Flat Damage 4-Bound System (Existing — No Change)

```gdscript
# Source: models/affixes/affix.gd:67-70
self.dmg_min_lo = p_dmg_min_lo * (tier_range.y + 1 - tier)
self.dmg_min_hi = p_dmg_min_hi * (tier_range.y + 1 - tier)
self.dmg_max_lo = p_dmg_max_lo * (tier_range.y + 1 - tier)
self.dmg_max_hi = p_dmg_max_hi * (tier_range.y + 1 - tier)
```

At tier 1: all bounds × 32. At tier 32: bounds × 1. Base damage bounds are the **tier-32 floor values**.

### Affix Definition Pattern in item_affixes.gd

**Scalar affix (omitting tier_range uses 8-tier default — MUST be explicit now):**
```gdscript
Affix.new(
    "Attack Speed",
    Affix.AffixType.SUFFIX,
    2,   # base_min (tier-32 floor)
    10,  # base_max (tier-32 ceiling)
    [Tag.SPEED, Tag.ATTACK, Tag.WEAPON],
    [Tag.StatType.INCREASED_SPEED],
    Vector2i(1, 32)  # MUST be explicit — no longer inheriting 8-tier default
)
```

**Flat damage affix:**
```gdscript
Affix.new(
    "Physical Damage",
    Affix.AffixType.PREFIX,
    2,   # base_min (unused for flat damage, kept for type consistency)
    10,  # base_max (unused for flat damage)
    [Tag.PHYSICAL, Tag.FLAT, Tag.WEAPON],
    [Tag.StatType.FLAT_DAMAGE],
    Vector2i(1, 32),
    3, 5, 7, 10  # dmg_min_lo, dmg_min_hi, dmg_max_lo, dmg_max_hi (tier-32 values)
)
```

### Save Version Bump Pattern

```gdscript
# Source: autoloads/save_manager.gd:4
const SAVE_VERSION = 3  # → change to 4

# The existing version-gate discards old saves automatically:
if saved_version < SAVE_VERSION:
    push_warning("SaveManager: Outdated save (v%d), deleting and starting fresh" % saved_version)
    delete_save()
    return false
```

No migration logic needed — old saves are deleted, fresh game starts.

### Anti-Patterns to Avoid

- **Forgetting implicit tier_range on default-8-tier affixes:** 10 affixes in `item_affixes.gd` omit `tier_range` and inherit `Vector2i(1, 8)` from `Affix._init()`. After this phase, all 20 affixes must have explicit `Vector2i(1, 32)`.
- **Changing the scaling formula:** The formula is locked. Only the data values (`base_min`, `base_max`, damage bounds) change.
- **Adding quality():** Explicitly locked out. Do not add it.
- **Touching is_item_better():** Stays as `new_item.tier > existing_item.tier`. Phase 38's concern.
- **Touching disabled suffixes:** They stay commented out.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Affix value at a given tier | Custom calculator | Existing `min_value`/`max_value` on `Affix` | Already computed at `_init()` time |
| Save version migration | Upgrade path from v3→v4 | Delete-on-old-version (already implemented) | User decision: no migration needed |
| Tier range constraint | New clamp/filter system | `tier_range` field already used by add_prefix/add_suffix | Phase 38 adds item_tier gating |

## Common Pitfalls

### Pitfall 1: Implicit Default tier_range Not Updated

**What goes wrong:** 10 affixes in `item_affixes.gd` currently omit the `tier_range` parameter, inheriting `Vector2i(1, 8)` from `Affix._init()`. If only affixes that currently pass `Vector2i(1, 8)` or `Vector2i(1, 30)` explicitly are updated, the 10 implicit-default affixes still roll 1-8 tiers.

**Why it happens:** The `Affix._init()` signature has `p_tier_range: Vector2i = Vector2i(1, 8)` as default. Any call omitting this parameter silently uses 8.

**How to avoid:** Count every `Affix.new(...)` call in `item_affixes.gd` and ensure all have `Vector2i(1, 32)`.

**Affected affixes (currently omitting tier_range):**
- `%Physical Damage`, `%Elemental Damage`, `%Cold Damage`, `%Fire Damage`, `%Lightning Damage` (5 prefixes)
- `Attack Speed`, `Life`, `Armor`, `Critical Strike Chance`, `Critical Strike Damage` (5 suffixes)

### Pitfall 2: Base Values Too High — Floor Too Low At Tier 32

**What goes wrong:** If base values are left unchanged, tier 32 values equal the current tier-8 values (same floor). This is intentional — but if base values are accidentally raised to match tier-1 targets, tier 32 becomes tiny.

**Why it happens:** Confusion between "base = tier-1 value" vs "base = tier-32 floor".

**How to avoid:** Remember: `base_min` and `base_max` are multiplied by 1 at tier 32. They ARE the tier-32 values. Tier-1 values are `base * 32`.

### Pitfall 3: ITEM_TIERS_BY_PRESTIGE Not Updated

**What goes wrong:** `PrestigeManager.ITEM_TIERS_BY_PRESTIGE` currently maps prestige levels to item tiers (1-8). These item tier numbers are the item tier system (Phase 38), not affix tiers. They don't need updating for Phase 37.

**Why it happens:** The naming overlap between "item tier" (1-8 item quality bands) and "affix tier" (1-32 power level within an affix) causes confusion.

**How to avoid:** `ITEM_TIERS_BY_PRESTIGE` stays unchanged. It returns item tier bands (1-8), not affix tiers. Phase 38 maps item tiers to affix tier ranges.

### Pitfall 4: Resistance Affixes — Range Uncertainty

**What goes wrong:** `Fire Resistance`, `Cold Resistance`, `Lightning Resistance` currently use `Vector2i(1, 8)` and `All Resistances` uses `Vector2i(1, 5)`. Their base values (5/12 and 3/8) would produce tier-1 values of 5*32=160 and 3*32=96 resistance — potentially unbalanced.

**Why it happens:** Resistance affixes are percentage reductions that cap at 75% in most ARPGs. A raw 160% resistance is gameplay-breaking.

**How to avoid:** Retune resistance base values so tier-1 produces ~75% max resistance. See recommended values below.

## Code Examples

### Complete Inventory of All Affixes Requiring Update

**Currently in item_affixes.gd — 19 active affixes (9 prefixes, 10 suffixes, not counting disabled):**

Prefixes (9):
1. `Physical Damage` — FLAT_DAMAGE, explicit `Vector2i(1, 8)`, 4-bound system
2. `%Physical Damage` — INCREASED_DAMAGE, no tier_range (defaults to 8)
3. `%Elemental Damage` — INCREASED_DAMAGE, no tier_range (defaults to 8)
4. `%Cold Damage` — INCREASED_DAMAGE, no tier_range (defaults to 8)
5. `%Fire Damage` — INCREASED_DAMAGE, no tier_range (defaults to 8)
6. `%Lightning Damage` — INCREASED_DAMAGE, no tier_range (defaults to 8)
7. `Lightning Damage` — FLAT_DAMAGE, explicit `Vector2i(1, 8)`, 4-bound system
8. `Fire Damage` — FLAT_DAMAGE, explicit `Vector2i(1, 8)`, 4-bound system
9. `Cold Damage` — FLAT_DAMAGE, explicit `Vector2i(1, 8)`, 4-bound system
10. `Flat Armor` — FLAT_ARMOR, explicit `Vector2i(1, 30)`
11. `%Armor` — PERCENT_ARMOR, explicit `Vector2i(1, 30)`
12. `Evasion` — FLAT_EVASION, explicit `Vector2i(1, 30)`
13. `%Evasion` — PERCENT_EVASION, explicit `Vector2i(1, 30)`
14. `Energy Shield` — FLAT_ENERGY_SHIELD, explicit `Vector2i(1, 30)`
15. `%Energy Shield` — PERCENT_ENERGY_SHIELD, explicit `Vector2i(1, 30)`
16. `Health` — FLAT_HEALTH, explicit `Vector2i(1, 30)`
17. `%Health` — PERCENT_HEALTH, explicit `Vector2i(1, 30)`
18. `Mana` — FLAT_MANA, explicit `Vector2i(1, 30)`

Suffixes (10 — 3 with explicit tier_range, 5 default-8, 2 disabled resistance-adjacent):
1. `Attack Speed` — INCREASED_SPEED, no tier_range (defaults to 8)
2. `Life` — FLAT_HEALTH, no tier_range (defaults to 8)
3. `Armor` — FLAT_ARMOR, no tier_range (defaults to 8)
4. `Fire Resistance` — FIRE_RESISTANCE, explicit `Vector2i(1, 8)`
5. `Cold Resistance` — COLD_RESISTANCE, explicit `Vector2i(1, 8)`
6. `Lightning Resistance` — LIGHTNING_RESISTANCE, explicit `Vector2i(1, 8)`
7. `All Resistances` — ALL_RESISTANCE, explicit `Vector2i(1, 5)`
8. `Critical Strike Chance` — CRIT_CHANCE, no tier_range (defaults to 8)
9. `Critical Strike Damage` — CRIT_DAMAGE, no tier_range (defaults to 8)

**Total to update: all 27 active affix definitions** (18 prefixes + 9 suffixes).

### Recommended Base Value Retuning

**Design anchor:** Tier 32 floor should equal roughly the old tier-8 floor (preserve the pre-prestige baseline). Tier 1 ceiling = tier-32 value × 32.

**Flat Weapon Damage Affixes (4-bound system):**

| Affix | Old bounds (tier-8 floor) | New bounds (tier-32 floor = same) | Tier-1 ceiling |
|-------|--------------------------|-----------------------------------|----------------|
| Physical Damage | dmg: 3,5,7,10 | dmg: 3,5,7,10 | dmg: 96,160,224,320 |
| Lightning Damage | dmg: 1,3,8,16 | dmg: 1,3,8,16 | dmg: 32,96,256,512 |
| Fire Damage | dmg: 2,4,8,14 | dmg: 2,4,8,14 | dmg: 64,128,256,448 |
| Cold Damage | dmg: 2,5,7,12 | dmg: 2,5,7,12 | dmg: 64,160,224,384 |

Note: The `base_min`/`base_max` (scalar params) on flat damage affixes are passed but unused for FLAT_DAMAGE stat types — they don't drive any computed value. They should be set to small placeholder integers (e.g., 2, 10) to avoid confusion.

**Percentage Damage Affixes (scalar, INCREASED_DAMAGE):**

Current: base_min=2, base_max=10 → tier-8 value = 2 to 10 (%)

At 32 tiers: Keep base_min=2, base_max=10 → tier-32 floor = 2% to 10%, tier-1 = 64% to 320%.

Note: 320% increased damage at tier 1 is intentional — this is an incremental ARPG with multiplicative stacking. Large percentages are fine per locked decision.

**Flat Defensive Affixes (currently 30-tier):**

| Affix | Current bases | Old tier-30 floor | New tier-32 floor | Recommended bases |
|-------|--------------|------------------|------------------|------------------|
| Flat Armor | 2, 5 | 2, 5 | keep ~same | 2, 5 |
| %Armor | 1, 3 | 1%, 3% | keep ~same | 1, 3 |
| Evasion | 2, 5 | 2, 5 | keep ~same | 2, 5 |
| %Evasion | 1, 3 | 1%, 3% | keep ~same | 1, 3 |
| Energy Shield | 3, 6 | 3, 6 | keep ~same | 3, 6 |
| %Energy Shield | 1, 3 | 1%, 3% | keep ~same | 1, 3 |
| Health | 3, 8 | 3, 8 | keep ~same | 3, 8 |
| %Health | 1, 3 | 1%, 3% | keep ~same | 1, 3 |
| Mana | 2, 6 | 2, 6 | keep ~same | 2, 6 |

For defensive affixes, the 30-tier → 32-tier change is minimal (old tier-30 floor → new tier-32 floor). Old tier-30 multiplier was 1 (tier 30 of 30), new tier-32 multiplier is also 1. Floor stays the same. Tier-1 ceiling increases from 30× to 32×.

**Suffix Affixes (scalar, currently default 8-tier):**

| Affix | Current bases | Old tier-8 floor | New tier-32 floor | Recommendation |
|-------|--------------|-----------------|------------------|----------------|
| Attack Speed | 2, 10 | 2%, 10% | keep same | 2, 10 |
| Life | 2, 10 | 2, 10 | keep same | 2, 10 |
| Armor | 2, 10 | 2, 10 | keep same | 2, 10 |
| Crit Chance | 2, 10 | 2%, 10% | keep same | 2, 10 |
| Crit Damage | 2, 10 | 2%, 10% | keep same | 2, 10 |

**Resistance Affixes (requires retuning — cap concern):**

| Affix | Current bases | Tier-1 at 32 (unchanged) | Cap-safe bases | Tier-1 ceiling | Tier-32 floor |
|-------|--------------|--------------------------|----------------|----------------|--------------|
| Fire Resistance | 5, 12 | 160%, 384% (broken) | 1, 2 | 32%, 64% | 1%, 2% |
| Cold Resistance | 5, 12 | 160%, 384% (broken) | 1, 2 | 32%, 64% | 1%, 2% |
| Lightning Resistance | 5, 12 | 160%, 384% (broken) | 1, 2 | 32%, 64% | 1%, 2% |
| All Resistances | 3, 8 | 96%, 256% (broken) | 1, 2 | 32%, 64% | 1%, 2% |

Resistance affixes need significant downward retuning. With 32 tiers and linear scaling, the old base values produce game-breaking resistance percentages at tier 1. Recommended: base_min=1, base_max=2 for single-element resistances; base_min=1, base_max=2 for All Resistances (or base_min=1, base_max=1 for tighter floor). This gives tier-1 = 32-64% which is near typical ARPG resistance caps. User should review in plan.

## State of the Art

| Old State | New State | Impact |
|-----------|-----------|--------|
| Mixed tier ranges: 5-tier (AllRes), 8-tier (weapons/suffixes), 30-tier (defense) | Uniform 32-tier for all | All affixes on same scale; P0 floor = tiers 29-32, P7 ceiling = tier 1 |
| Default `Vector2i(1, 8)` used implicitly by 10 affixes | Explicit `Vector2i(1, 32)` on all 27 definitions | No silent inheritance; intent is clear in code |
| SAVE_VERSION = 3 | SAVE_VERSION = 4 | Old saves discarded on load |

## Open Questions

1. **Resistance affix cap behavior**
   - What we know: Resistances currently have no hard cap enforced in code (no clamping in stat_calculator.gd or hero.gd seen). Old values 5-12 at 8 tiers = 5-12 floor, reasonable.
   - What's unclear: Does the game's combat engine cap resistance at 75% or 80%? If so, the actual ceiling is already capped and we could use larger base values.
   - Recommendation: Set base values conservatively (1, 2) to keep tier-1 at 32-64% and avoid potential cap violations. User reviews in plan.

2. **`Life` and `Armor` suffix vs. prefix overlap**
   - What we know: Both `Health` prefix (FLAT_HEALTH, 30-tier) and `Life` suffix (FLAT_HEALTH, 8-tier default) share the same StatType. Same for `Flat Armor` prefix and `Armor` suffix.
   - What's unclear: Is the suffix a weaker version of the prefix by design, or an oversight?
   - Recommendation: After expansion, `Life` suffix at tier 1 = base_max * 32 = 320 and `Health` prefix at tier 1 = 8 * 32 = 256. They'll cross. This is Claude's discretion — can differentiate by adjusting Life suffix bases. User reviews in plan.

3. **Balance verification — pre-prestige floor within 10% of v1.6**
   - What we know: STATE.md flags: "verify pre-prestige floor within 10% of v1.6 before shipping."
   - What's unclear: How this verification will be done — manually or via test output.
   - Recommendation: Plan should include a verification step where the implementer prints tier-32 values for each affix and compares against old tier-8 values.

## Sources

### Primary (HIGH confidence)

- `models/affixes/affix.gd` — Verified: `tier_range`, `base_min`, `base_max`, scaling formula, `to_dict()`/`from_dict()`, flat damage 4-bound system
- `autoloads/item_affixes.gd` — Verified: all 27 active affix definitions with current bases and tier_range values
- `autoloads/save_manager.gd` — Verified: `SAVE_VERSION = 3`, delete-on-old-version logic in `load_game()`
- `autoloads/prestige_manager.gd` — Verified: `ITEM_TIERS_BY_PRESTIGE` stays unchanged (item tiers 1-8, not affix tiers)
- `scenes/forge_view.gd:491` — Verified: `is_item_better()` is `new_item.tier > existing_item.tier`, stays unchanged
- `.planning/phases/37-affix-tier-expansion/37-CONTEXT.md` — Authoritative user decisions

### Secondary (MEDIUM confidence)

- `.planning/STATE.md` — Context: balance verification concern, background decisions

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all code read directly from source
- Architecture patterns: HIGH — existing patterns verified in source files
- Pitfalls: HIGH — identified from direct code inspection (implicit defaults, resistance cap)
- Recommended values: MEDIUM — mechanically sound but balance is gameplay judgment; user reviews in plan

**Research date:** 2026-03-01
**Valid until:** Stable until Phase 38 (Item Tier System) changes affix tier gating logic
