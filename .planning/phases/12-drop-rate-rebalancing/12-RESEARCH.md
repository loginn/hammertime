# Phase 12: Drop Rate Rebalancing - Research

**Researched:** 2026-02-16
**Domain:** Game balance / loot economy tuning (GDScript, Godot 4.5)
**Confidence:** HIGH

## Summary

Phase 12 tunes numerical values in the existing `LootTable` system to achieve the user's desired reward curve. The codebase already has the structural foundations: `RARITY_WEIGHTS` dictionary for rarity scaling, `roll_currency_drops()` with per-currency chances and area gating, and `roll_rarity()` for weighted random selection. The work is purely numerical tuning and adding item quantity scaling.

Two structural changes are needed: (1) replace the discrete `RARITY_WEIGHTS` lookup with interpolated logarithmic scaling so weights transition smoothly between tier boundaries, and (2) add an item quantity system to `clear_area()` so higher areas drop multiple items per clear. The `drop_simulator.gd` from Phase 11 provides validation infrastructure.

**Primary recommendation:** Implement smooth logarithmic interpolation for rarity weights, add area-scaled item quantity drops (1 at area 1, 4-5 at area 300), and reduce currency base chances for advanced types. Validate through the existing drop simulator, then playtest.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Rare items at area 1: approximately 1 per 50 clears (down from current ~1 per 10)
- Magic items also rarer in early areas (e.g. 1 per 10-15, down from ~1 per 5-6)
- Every clear guarantees at least 1 item drop (never zero items)
- Every clear guarantees at least 1 currency drop (steady hammer flow from the start)
- Rare items at area 300: approximately 1 per 5 clears (generous endgame)
- Advanced currencies (Grand, Claw, Tuning) still feel rare even at area 300
- Magic items become the dominant drop type at area 300
- Higher areas drop more items total per clear (volume reward on top of quality improvement)
- Max item drops at area 300: 4-5 items per clear (up from 1 guaranteed at area 1)
- Smooth logarithmic curve with rapid early improvement tapering into slow progression
- Mild bumps at tier boundaries (100/200/300) on top of the smooth curve
- Both item quantity and rarity weights scale with area level
- Playtest-driven validation with 2-3 iteration passes
- Drop simulator from Phase 11 available as reference

### Claude's Discretion
- Exact formula coefficients for the logarithmic curve
- Specific rarity weight values at each area level
- How to implement the mild tier-boundary bumps (additive bonus vs multiplicative)
- Item quantity scaling formula (floor vs fractional with RNG)
- How magic/rare weight distributions shift along the curve

### Deferred Ideas (OUT OF SCOPE)
- Meta progression / prestige system to resolve late-game taper
- Inventory management for higher drop volumes (stash, auto-sell, filters)
</user_constraints>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Godot 4.5 | 4.5 | Game engine | Project engine |
| GDScript | Native | Scripting | Project language |

No external libraries needed. All tuning is in existing GDScript files.

### Files to Modify
| File | Purpose | Changes |
|------|---------|---------|
| `models/loot/loot_table.gd` | Rarity weights, currency drops | Replace discrete weights with smooth interpolation, tune currency chances |
| `scenes/gameplay_view.gd` | Area clearing loop | Add multi-item drops per clear |
| `tools/drop_simulator.gd` | Validation | Update to test new quantity system |

## Architecture Patterns

### Pattern 1: Logarithmic Interpolation for Rarity Weights
**What:** Replace discrete `RARITY_WEIGHTS` dictionary lookups with a function that computes weights at any area level using logarithmic interpolation between anchor points.
**When to use:** When you need smooth progression that tapers naturally.
**Why logarithmic:** `log(x)` grows rapidly at low values and slowly at high values, matching the desired "rapid early improvement that tapers" shape.

```gdscript
# Anchor points define the curve at key area levels
# Interpolation fills in between
const RARITY_ANCHORS = {
    1: { "normal": 96, "magic": 3.5, "rare": 0.5 },    # ~1 rare per 200 rolls (but items per clear increases the effective rate)
    100: { "normal": 60, "magic": 32, "rare": 8 },
    200: { "normal": 25, "magic": 50, "rare": 25 },
    300: { "normal": 8, "magic": 55, "rare": 37 },
}

static func get_rarity_weights(area_level: int) -> Dictionary:
    # Find bounding anchors
    # Logarithmic interpolation between them
    # Add mild tier-boundary bump
    pass
```

### Pattern 2: Multi-Item Drops with Guaranteed Minimum
**What:** Scale item drops per clear from 1 (area 1) to 4-5 (area 300) using a logarithmic curve with floor + random roll for fractional part.
**When to use:** When item quantity should scale with area level.

```gdscript
# Example: get_item_drop_count(area_level) -> int
# area 1:   1.0 items -> always 1
# area 50:  1.8 items -> 1 guaranteed + 80% chance of 2nd
# area 100: 2.3 items -> 2 guaranteed + 30% chance of 3rd
# area 200: 3.5 items -> 3 guaranteed + 50% chance of 4th
# area 300: 4.5 items -> 4 guaranteed + 50% chance of 5th

static func get_item_drop_count(area_level: int) -> int:
    var base_count = 1.0 + 3.5 * log(1.0 + float(area_level) / 85.0) / log(1.0 + 300.0 / 85.0)
    # Add tier boundary bump
    if area_level >= 300:
        base_count += 0.3
    elif area_level >= 200:
        base_count += 0.2
    elif area_level >= 100:
        base_count += 0.1
    var guaranteed = int(base_count)
    var fractional = base_count - float(guaranteed)
    if randf() < fractional:
        guaranteed += 1
    return max(1, guaranteed)  # Never zero
```

### Pattern 3: Smooth Weight Interpolation
**What:** For rarity weights between anchor points, use logarithmic interpolation rather than linear.
**Why:** Linear interpolation between anchors creates kinks. Log interpolation maintains the smooth curve shape.

```gdscript
static func _log_interp(a: float, b: float, t: float) -> float:
    # t is 0-1 progress between two anchor points
    # Apply log curve to t for non-linear interpolation
    var log_t = log(1.0 + t * 9.0) / log(10.0)  # Maps 0-1 to 0-1 with log shape
    return a + (b - a) * log_t
```

### Anti-Patterns to Avoid
- **Discrete weight tables with no interpolation:** Current approach creates sudden jumps at tier boundaries (80/18/2 at level 99 jumps to 50/40/10 at level 100). Replace with smooth curve.
- **Linear item quantity scaling:** `items = 1 + area_level * 0.01` gives 4 items at area 300 but the early game feels too slow. Logarithmic front-loads the gains.
- **Tuning currency chances without considering the existing ramp system:** Phase 11's `_calculate_currency_chance()` already handles unlock ramping. This phase only adjusts the `base_chance` values.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Logarithmic math | Custom approximation | GDScript `log()` function | Built-in, exact |
| Random weighted selection | Custom weighted picker | Existing `roll_rarity()` pattern | Already tested, just needs new weights |
| Drop validation | Manual testing | Existing `drop_simulator.gd` | Phase 11 built this specifically |

## Common Pitfalls

### Pitfall 1: Changing Rarity Per-Item Without Accounting for Multi-Item Drops
**What goes wrong:** If you set rare chance to 2% (targeting 1 per 50 clears) but area 300 drops 5 items per clear, the effective rare rate is 5 * 37% = 1.85 per clear, not 0.37 per clear.
**Why it happens:** Rarity weight targets are set per-roll, but user expectations are per-clear.
**How to avoid:** Think in terms of "per clear" rates. With 4.5 items at area 300 and 37% rare chance, expected rares per clear = ~1.7. At area 1 with 1 item and 2% rare chance, expected rares per clear = 0.02 (1 per 50). Both match requirements.
**Warning signs:** Drop simulator showing unexpected per-clear rates.

### Pitfall 2: Currency Bonus Drops Scaling Out of Control
**What goes wrong:** Current code gives `area_level - 1` bonus currency drops (line 113 of loot_table.gd). At area 300, that's 299 bonus currencies per clear spread across eligible types.
**Why it happens:** This formula was designed for a 1-4 area range, not 1-300.
**How to avoid:** Replace linear bonus with logarithmic scaling: `floor(log(area_level) * 2)` gives ~11 bonus at area 300 instead of 299. Or cap bonus drops.
**Warning signs:** Drop simulator showing hundreds of currencies per clear at high levels.

### Pitfall 3: Integer Rounding Destroying Low Probabilities
**What goes wrong:** If rare weight is 0.5 out of 100 total, `randi_range(1, 100)` has only 1 value that hits rare (needs to be exactly 100). Effectively 1% not 0.5%.
**Why it happens:** Integer-based weight rolling can't represent sub-1% weights accurately.
**How to avoid:** Use larger weight totals (e.g., scale weights so total is 1000 or 10000) or use float-based rolling.
**Warning signs:** Early game rare rates being 1-2% instead of the target 0.5-2%.

### Pitfall 4: Tier Boundary Bumps Creating Regression
**What goes wrong:** If the bump at tier 100 is too large, area 101 might feel worse than area 100 as the bump fades.
**Why it happens:** Applying bumps as discrete additions rather than smooth humps.
**How to avoid:** Apply bumps as gaussian-shaped additions centered at boundaries: `bump * exp(-((level - boundary) / width)^2)` or simply apply them only to the interpolation anchors (simpler, no regression risk).
**Warning signs:** Drop rates at area 101 being lower than area 100.

## Code Examples

### Current Rarity Weights (Area 1)
```
NORMAL: 80%, MAGIC: 18%, RARE: 2%
```
Current effective rates per clear (1 item/clear):
- Normal: 80% of clears (1 per 1.25)
- Magic: 18% of clears (1 per 5.6)
- Rare: 2% of clears (1 per 50)

### Target Rarity Weights (Area 1) - per CONTEXT.md
```
Rare: ~1 per 50 clears = 2% (matches current for single-item drops)
Magic: ~1 per 10-15 clears = 7-10%
Normal: remainder = 88-91%
```

### Target Rarity Weights (Area 300)
```
With ~4.5 items per clear:
Rare: ~1 per 5 clears = need ~4.4% effective per clear
  -> 4.4% / 4.5 items = ~1% per roll? No, too low.
  -> Actually: P(at least 1 rare in 5 clears of 4.5 items) ≈ 1
  -> With 20% rare weight: 0.2 * 4.5 = 0.9 rares per clear ≈ 1 per 1.1 clears
  -> Target is 1 per 5 clears, so rare weight needs to be lower: ~4.5% per roll
  -> 0.045 * 4.5 = 0.2 rares per clear = 1 per 5 clears ✓

Wait - re-reading context: "Rare items at area 300: approximately 1 per 5 clears"
With 4.5 items/clear: rare_weight = 0.2 / 4.5 ≈ 4.4% per roll... but that seems very low for endgame.

Alternative reading: the user wants a REWARDING endgame. "1 per 5 clears" with 4.5 items means ~22.5 items between rares.
Let's trust the user's number and set rare weight accordingly.
```

**Recommended anchor values (will be refined through playtesting):**

| Area | Normal | Magic | Rare | Items/Clear | Rares/Clear |
|------|--------|-------|------|-------------|-------------|
| 1    | 91     | 7     | 2    | 1.0         | 0.02 (1/50) |
| 100  | 65     | 30    | 5    | 2.3         | 0.12 (1/8.7) |
| 200  | 40     | 50    | 10   | 3.5         | 0.35 (1/2.9) |
| 300  | 15     | 65    | 20   | 4.5         | 0.90 (1/1.1) |

Hmm, at 20% rare weight with 4.5 items, we get almost 1 rare per clear. That's more like "1 per 1" not "1 per 5." Let's recalculate:

For 1 rare per 5 clears at 4.5 items/clear: rare% = (1/5) / 4.5 = 4.4%

| Area | Normal | Magic | Rare | Items/Clear | Rares/Clear |
|------|--------|-------|------|-------------|-------------|
| 1    | 91     | 7     | 2    | 1.0         | 0.02 (1/50) |
| 100  | 72     | 25    | 3    | 2.3         | 0.07 (1/14) |
| 200  | 55     | 40    | 5    | 3.5         | 0.18 (1/5.7) |
| 300  | 30     | 66    | 4    | 4.5         | 0.18 (1/5.6) |

This doesn't feel right either - the rare chance at 300 is lower per roll than 200. The issue is that item quantity scaling compensates.

**Recommended approach:** Set rarity weights for the "per clear" experience, then back-calculate per-roll weights from item quantity.

Final recommended anchors:

| Area | Target Rares/Clear | Items/Clear | Required Rare% | Magic% | Normal% |
|------|-------------------|-------------|----------------|--------|---------|
| 1    | 0.02 (1/50)       | 1.0         | 2%             | 7%     | 91%     |
| 100  | 0.10 (1/10)       | 2.3         | 4.3%           | 30%    | 65.7%   |
| 200  | 0.15 (1/6.7)      | 3.5         | 4.3%           | 50%    | 45.7%   |
| 300  | 0.20 (1/5)        | 4.5         | 4.4%           | 70%    | 25.6%   |

Magic becomes dominant at area 300 (70% of all drops). Rare stays meaningful. Normal fades. This matches all user constraints.

### Currency Tuning
Current base chances and issues:
```gdscript
# Current values
"runic": {"chance": 0.7}   # Fine, keep high
"tack": {"chance": 0.5}    # Fine
"forge": {"chance": 0.3}   # OK, already gated to area 100+
"grand": {"chance": 0.2}   # Needs to feel rare even at 300
"claw": {"chance": 0.4}    # Too generous for an area-300 unlock
"tuning": {"chance": 0.4}  # Too generous for an area-300 unlock
```

**Critical issue:** Bonus drops formula `area_level - 1` is wildly overtuned for 1-300 range. At area 300, players get 299 bonus currencies per clear. Must fix.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Discrete tier lookup | Needs smooth interpolation | Phase 12 | Eliminates jarring jumps between tiers |
| 1 item per clear | Multi-item drops | Phase 12 | Volume reward for progression |
| Linear bonus currencies | Logarithmic scaling | Phase 12 | Prevents currency flooding at high levels |

## Open Questions

1. **Exact logarithmic coefficients**
   - What we know: Shape should be rapid early improvement, tapering late
   - What's unclear: Exact `k` value in `log(1 + level/k)`
   - Recommendation: Start with k=85 (gives nice curve shape), playtest and adjust

2. **Tier boundary bump magnitude**
   - What we know: "Mild bumps" at 100/200/300
   - What's unclear: How large is "mild"?
   - Recommendation: Start with +5% bonus to rare weight at boundary, fading over 20 levels. Simple additive approach.

3. **Whether to keep `RARITY_WEIGHTS` as a const or switch to computed**
   - What we know: Current system uses const dictionary
   - What's unclear: Whether performance matters (it doesn't - called once per clear)
   - Recommendation: Switch to computed. One function, no const table needed.

## Sources

### Primary (HIGH confidence)
- Codebase analysis of `models/loot/loot_table.gd` - current rarity weights and currency system
- Codebase analysis of `scenes/gameplay_view.gd` - current clear_area() loop (1 item per clear)
- Codebase analysis of `tools/drop_simulator.gd` - existing validation infrastructure
- Phase 12 CONTEXT.md - user decisions and constraints

### Secondary (MEDIUM confidence)
- Logarithmic curve mathematics - standard calculus, GDScript `log()` is natural log

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All changes are in existing GDScript files
- Architecture: HIGH - Patterns are straightforward math on existing systems
- Pitfalls: HIGH - Identified from direct codebase analysis (especially the bonus drops formula)

**Research date:** 2026-02-16
**Valid until:** Indefinite (game balance tuning, not library versions)
