# Phase 11: Currency Area Gating - Research

**Researched:** 2026-02-16
**Domain:** GDScript drop system gating and area progression (Godot 4.x idle ARPG)
**Confidence:** HIGH

## Summary

Phase 11 gates currency drops by area level, preventing advanced hammers from dropping until players reach appropriate difficulty tiers. This requires minimal new code — the existing LootTable.roll_currency_drops() system already receives area_level as input and can exclude currencies before the probability roll. The challenge is not technical implementation but **balancing the gating thresholds and drop rate scaling** to create a smooth reward curve across the expanded area range (1 → 100 → 200 → 300).

The roadmap flags this phase as requiring "simulation testing to validate drop distribution." This is correct — tuning drop rates for a 300x area range requires empirical data, not guesswork. The research below identifies the standard patterns for gating systems and recommends creating a drop simulator to verify the balance before committing to specific values.

**Primary recommendation:** Implement hard gating with area thresholds, add optional ramping logic for newly-unlocked currencies, create a standalone drop simulator script to validate distribution across 300 area levels before finalizing constants.

## Standard Stack

### Core

This phase uses existing Godot 4.x GDScript patterns — no external libraries required.

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| GDScript static methods | Godot 4.x | Drop generation and filtering | LootTable already uses static methods for stateless drop logic |
| Dictionary-based config | GDScript native | Currency rules and thresholds | Existing RARITY_WEIGHTS and currency_rules patterns |
| Area level progression | Game-specific | Unlocking higher-tier rewards | Standard idle/ARPG pattern (Path of Exile, Diablo) |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| Drop simulator script | Custom GDScript | Validate distribution before deployment | Required for this phase per roadmap note |
| Debug UI panel | Godot Control node | Manual area level testing during development | Optional but recommended |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hard gating (exclude from pool) | Soft gating (very low probability) | Hard gating clearer to players, prevents confusion from impossible drops |
| Static area thresholds | Dynamic unlock based on player actions | Static thresholds simpler, matches existing area_level system |
| Linear ramping | Exponential/logarithmic scaling | Linear easier to reason about, adequate for 4-tier system |

**Pattern choice:** Hard gating + linear ramping. Hard gating prevents clutter in early areas (no Grand Hammer tooltips at level 1). Linear ramping provides smooth progression within tiers without mathematical complexity.

## Architecture Patterns

### Recommended Integration Structure

```
models/loot/loot_table.gd
├── CURRENCY_AREA_GATES (new const Dictionary)
│   └── Maps currency name → min_area_level
├── roll_currency_drops(area_level: int) → Dictionary
│   ├── Hard gate: skip if area_level < min_area_level
│   └── Ramping: reduce base chance for newly-unlocked currencies
└── _calculate_currency_chance(base_chance, area_level, unlock_level) → float (new helper)

tools/drop_simulator.gd (new file)
└── Simulates 1000 clears per area level, outputs CSV/console report
```

No changes required to Currency base class or subclasses. The gating logic lives entirely in LootTable because it's a **drop restriction**, not an **application restriction**. Once a player has a Grand Hammer, they can use it regardless of current area — gating only affects acquisition.

### Pattern 1: Hard Gating (Exclude from Drop Pool)

**What:** Check area_level against min_area_level threshold BEFORE rolling drop probability. Currencies below threshold are excluded from the pool entirely.

**When to use:** Always for this phase. Prevents UI clutter and player confusion.

**Example:**
```gdscript
# LootTable.gd
const CURRENCY_AREA_GATES: Dictionary = {
	"runic": 1,
	"tack": 1,
	"forge": 100,
	"grand": 200,
	"claw": 300,
	"tuning": 300,
}

static func roll_currency_drops(area_level: int) -> Dictionary:
	var drops: Dictionary = {}

	var currency_rules = {
		"runic": {"chance": 0.7, "min_qty": 1, "max_qty": 2},
		"forge": {"chance": 0.3, "min_qty": 1, "max_qty": 1},
		# ... etc
	}

	for currency_name in currency_rules:
		# HARD GATE: Skip if area too low
		if area_level < CURRENCY_AREA_GATES[currency_name]:
			continue

		var rule = currency_rules[currency_name]
		if randf() < rule["chance"]:
			var quantity = randi_range(rule["min_qty"], rule["max_qty"])
			drops[currency_name] = quantity

	# Bonus drops and guarantee logic unchanged
	# ...

	return drops
```

**Why this works:** The existing currency_rules loop structure already supports early-continue. Adding a gate check at the top of each iteration is a one-line change per currency. No refactoring required.

### Pattern 2: Drop Chance Ramping (Newly Unlocked Items Start Rare)

**What:** When a currency first becomes available, its drop chance starts lower than the base rate and increases over the next N area levels until reaching full strength.

**When to use:** Recommended for Forge (unlocks at 100), Grand (unlocks at 200), Claw/Tuning (unlock at 300). Not needed for Runic/Tack (available from area 1).

**Example:**
```gdscript
# Helper function (add to LootTable.gd)
static func _calculate_currency_chance(
	base_chance: float,
	area_level: int,
	unlock_level: int,
	ramp_duration: int = 50
) -> float:
	"""
	Returns adjusted drop chance that ramps up after unlock.

	At unlock_level: returns base_chance * 0.1 (10% of normal)
	At unlock_level + ramp_duration: returns base_chance (100%)
	Linear interpolation between.
	"""
	if area_level < unlock_level:
		return 0.0  # Should never happen (hard gate prevents this)

	var levels_since_unlock = area_level - unlock_level
	if levels_since_unlock >= ramp_duration:
		return base_chance  # Full strength

	# Linear ramp from 10% to 100%
	var ramp_progress = float(levels_since_unlock) / float(ramp_duration)
	var ramp_multiplier = 0.1 + (0.9 * ramp_progress)
	return base_chance * ramp_multiplier

# Usage in roll_currency_drops()
for currency_name in currency_rules:
	if area_level < CURRENCY_AREA_GATES[currency_name]:
		continue

	var rule = currency_rules[currency_name]
	var unlock_level = CURRENCY_AREA_GATES[currency_name]

	# Apply ramping to newly-unlocked currencies
	var adjusted_chance = _calculate_currency_chance(
		rule["chance"],
		area_level,
		unlock_level
	)

	if randf() < adjusted_chance:
		# ... drop logic
```

**Trade-off:** Adds complexity (helper function, adjusted_chance calculation). Benefit: smoother progression feel — players notice Grand Hammers becoming more common as they advance in tier 3 areas.

**Recommendation:** Implement ramping for Forge/Grand/Claw/Tuning. Use ramp_duration = 50 (Forge common by area 150, Grand common by area 250). Skip ramping for Runic/Tack to keep area 1-99 simple.

### Pattern 3: Area Level Expansion (Update Thresholds)

**What:** Change area naming and progression to match the 1/100/200/300 scale instead of 1/2/3/4.

**Current state (gameplay_view.gd lines 255-265):**
```gdscript
match area_level:
	1: current_area = "Forest"
	2: current_area = "Dark Forest"
	3: current_area = "Cursed Woods"
	4: current_area = "Shadow Realm"
	_: current_area = "Area Level " + str(area_level)
```

**Required change:**
```gdscript
match area_level:
	1: current_area = "Forest"           # Areas 1-99
	100: current_area = "Dark Forest"     # Areas 100-199
	200: current_area = "Cursed Woods"    # Areas 200-299
	300: current_area = "Shadow Realm"    # Areas 300+
	_:
		# Determine tier based on level
		if area_level < 100:
			current_area = "Forest"
		elif area_level < 200:
			current_area = "Dark Forest"
		elif area_level < 300:
			current_area = "Cursed Woods"
		else:
			current_area = "Shadow Realm"
```

**Why this works:** The area_level is already an int that increments on progression. Changing the match thresholds doesn't break anything — it just changes when the name updates. The existing area progression logic (10% chance per clear) already supports going to level 300+.

**Side effect:** Rarity weights (RARITY_WEIGHTS in LootTable) currently cap at level 5. This needs updating for the wider range:

```gdscript
const RARITY_WEIGHTS: Dictionary = {
	1: { Item.Rarity.NORMAL: 80, Item.Rarity.MAGIC: 18, Item.Rarity.RARE: 2 },
	100: { Item.Rarity.NORMAL: 50, Item.Rarity.MAGIC: 40, Item.Rarity.RARE: 10 },
	200: { Item.Rarity.NORMAL: 20, Item.Rarity.MAGIC: 45, Item.Rarity.RARE: 35 },
	300: { Item.Rarity.NORMAL: 5, Item.Rarity.MAGIC: 30, Item.Rarity.RARE: 65 },
	500: { Item.Rarity.NORMAL: 2, Item.Rarity.MAGIC: 28, Item.Rarity.RARE: 70 },  # For area_level >= 500
}

static func get_rarity_weights(area_level: int) -> Dictionary:
	# Use floor division to find closest threshold below area_level
	var lookup_level = 1
	for threshold in [500, 300, 200, 100, 1]:
		if area_level >= threshold:
			lookup_level = threshold
			break
	return RARITY_WEIGHTS[lookup_level]
```

This matches requirement AREA-03 (rarity weights progress gradually across area levels).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Smooth scaling curves | Custom exponential/logarithmic formulas | Linear interpolation with discrete thresholds | Easier to reason about, tune, and debug. Complex curves add minimal gameplay value for 4 tiers. |
| Drop rate validation | Manual playtesting only | Drop simulator script (run 1000 clears per level) | Catches imbalances before player-facing deployment. Manual testing can't cover 300 area levels efficiently. |
| Area gate data storage | Hardcoded if-statements per currency | const Dictionary mapping currency name → threshold | Single source of truth, easy to tune in one place. |

**Key insight:** With only 4 area tiers and 6 currencies, simple linear ramping and threshold dictionaries are sufficient. Don't over-engineer the scaling system — save complexity budget for Phase 12 (Drop Rate Rebalancing) where empirical tuning happens.

## Common Pitfalls

### Pitfall 1: Forgetting to Update Rarity Weights for Wider Area Range

**What goes wrong:** RARITY_WEIGHTS dictionary still uses 1-5 scale, causing areas 100+ to use level-5 weights (70% rare) when they should use tier-appropriate weights.

**Why it happens:** RARITY_WEIGHTS was designed for 1-4 area progression in Phase 7. It doesn't automatically adapt to 1/100/200/300 scale.

**How to avoid:** Update RARITY_WEIGHTS to use thresholds [1, 100, 200, 300, 500] and update get_rarity_weights() to find the largest threshold <= area_level (see Pattern 3 above).

**Warning signs:** Players at area 150 getting 70% rare drops when they should get ~30%. Simulator shows identical drop distribution for areas 100-300.

### Pitfall 2: Applying Area Gates to Currency Usage Instead of Drops

**What goes wrong:** Adding min_area_level check to Currency.can_apply() instead of LootTable.roll_currency_drops().

**Why it happens:** Misunderstanding the gating scope. Gating should prevent **acquisition**, not **use**.

**How to avoid:** Remember that gating is a drop restriction. Once a player has a Grand Hammer (maybe from trading, future features, or debug mode), they should be able to use it at any area level. The gate only affects whether it drops.

**Warning signs:** Player has Grand Hammer from area 250, returns to area 150 for fast farming, can't use Grand Hammer on items. This feels like a bug, not intended design.

### Pitfall 3: Bonus Drop System Diluting New Currencies

**What goes wrong:** The existing bonus drop system (`area_level - 1` bonus drops distributed to currencies that already dropped) heavily favors Runic/Tack at high areas because they drop more frequently, so they're more likely to receive bonus drops.

**Why it happens:** Bonus drops are distributed proportionally to existing drops. At area 300, Runic (70% chance) gets many more bonus drops than Claw (40% chance, newly unlocked, ramped to ~10% effective chance).

**How to avoid:** Consider changing bonus drop distribution to be uniform (equal chance per currency type) instead of weighted by what already dropped. OR accept that basic currencies scale better with area level (this might be intentional design).

**Warning signs:** Simulator shows Runic Hammer drop count increasing linearly with area level, but Grand Hammer drop count staying flat even after unlock. Players swim in Runic at area 300, starved for Grand.

**Recommendation:** Make bonus drop distribution uniform across all eligible currencies (those that passed the area gate). This gives advanced currencies a chance to benefit from high area levels even if their base drop chance is lower.

### Pitfall 4: Ramping Formula Using Wrong Baseline

**What goes wrong:** Ramping reduces drop chance to near-zero at unlock, making the currency feel "not actually unlocked yet."

**Why it happens:** Starting ramp_multiplier at 0.01 (1%) instead of 0.1 (10%), or using exponential curves that suppress early drops too much.

**How to avoid:** Start ramping at 10% of base chance (0.1 multiplier). This is low enough to signal "this is rare/new" but high enough that players see 1-2 drops in their first 20 clears, confirming the unlock.

**Warning signs:** Player reaches area 100, clears 50 times, never sees a Forge Hammer drop, assumes it's still locked or bugged.

## Code Examples

### Example 1: Complete roll_currency_drops() with Hard Gates and Ramping

```gdscript
# LootTable.gd

const CURRENCY_AREA_GATES: Dictionary = {
	"runic": 1,
	"tack": 1,
	"forge": 100,
	"grand": 200,
	"claw": 300,
	"tuning": 300,
}

static func roll_currency_drops(area_level: int) -> Dictionary:
	var drops: Dictionary = {}

	# Base drop rules (unchanged from Phase 7)
	var currency_rules = {
		"runic": {"chance": 0.7, "min_qty": 1, "max_qty": 2},
		"forge": {"chance": 0.3, "min_qty": 1, "max_qty": 1},
		"tack": {"chance": 0.5, "min_qty": 1, "max_qty": 2},
		"grand": {"chance": 0.2, "min_qty": 1, "max_qty": 1},
		"claw": {"chance": 0.4, "min_qty": 1, "max_qty": 2},
		"tuning": {"chance": 0.4, "min_qty": 1, "max_qty": 2},
	}

	# Roll each currency with gating and ramping
	for currency_name in currency_rules:
		var unlock_level = CURRENCY_AREA_GATES[currency_name]

		# HARD GATE: Skip if area too low
		if area_level < unlock_level:
			continue

		var rule = currency_rules[currency_name]
		var base_chance = rule["chance"]

		# Apply ramping to newly-unlocked currencies
		var adjusted_chance = base_chance
		if unlock_level > 1:  # Skip ramping for starter currencies
			adjusted_chance = _calculate_currency_chance(
				base_chance,
				area_level,
				unlock_level,
				50  # Ramp duration: 50 levels to full strength
			)

		# Roll for drop
		if randf() < adjusted_chance:
			var quantity = randi_range(rule["min_qty"], rule["max_qty"])
			drops[currency_name] = quantity

	# Bonus drops (area_level - 1), distributed uniformly
	var bonus_drops = area_level - 1
	if bonus_drops > 0 and drops.size() > 0:
		var eligible_currencies = drops.keys()
		for i in range(bonus_drops):
			var random_currency = eligible_currencies[randi() % eligible_currencies.size()]
			drops[random_currency] += 1

	# Guarantee at least 1 runic hammer if nothing dropped
	if drops.is_empty():
		drops["runic"] = 1

	return drops

static func _calculate_currency_chance(
	base_chance: float,
	area_level: int,
	unlock_level: int,
	ramp_duration: int = 50
) -> float:
	"""
	Returns drop chance that ramps from 10% to 100% over ramp_duration levels.
	"""
	if area_level < unlock_level:
		return 0.0

	var levels_since_unlock = area_level - unlock_level
	if levels_since_unlock >= ramp_duration:
		return base_chance

	var ramp_progress = float(levels_since_unlock) / float(ramp_duration)
	var ramp_multiplier = 0.1 + (0.9 * ramp_progress)
	return base_chance * ramp_multiplier
```

**Source:** Derived from existing LootTable.roll_currency_drops() pattern (Phase 7) with gating logic added.

### Example 2: Drop Simulator for Validation

```gdscript
# tools/drop_simulator.gd
extends Node

# Simulates currency drops across area levels to validate distribution

func _ready() -> void:
	simulate_drops()

func simulate_drops() -> void:
	print("=== Currency Drop Simulator ===\n")

	# Test key area thresholds and transitions
	var test_levels = [1, 50, 99, 100, 150, 199, 200, 250, 299, 300, 350, 400]
	var clears_per_level = 1000

	for area_level in test_levels:
		var totals = {
			"runic": 0, "forge": 0, "tack": 0,
			"grand": 0, "claw": 0, "tuning": 0
		}

		# Simulate many clears
		for i in range(clears_per_level):
			var drops = LootTable.roll_currency_drops(area_level)
			for currency in drops:
				totals[currency] += drops[currency]

		# Print results
		print("Area Level %d (%d clears):" % [area_level, clears_per_level])
		for currency in ["runic", "tack", "forge", "grand", "claw", "tuning"]:
			var avg = float(totals[currency]) / float(clears_per_level)
			print("  %s: %.2f per clear" % [currency, avg])
		print()

	print("=== Simulation Complete ===")
	print("Expected patterns:")
	print("- Runic/Tack available at all levels")
	print("- Forge appears at 100+, low at 100, higher at 150+")
	print("- Grand appears at 200+, low at 200, higher at 250+")
	print("- Claw/Tuning appear at 300+, low at 300, higher at 350+")
```

**Usage:** Add to project temporarily, run as main scene, verify output matches expectations, remove before deployment.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| All currencies drop everywhere | Area-gated progression | v1.1 (Phase 11) | Creates sense of progression and reward for reaching new areas. Prevents overwhelming new players with 6 currency types immediately. |
| Fixed area names (1-4) | Scalable area levels (1-300+) | v1.1 (Phase 11) | Supports long-term content expansion without refactoring. Matches idle game genre expectation of unbounded progression. |
| Linear area bonuses | Still linear but across wider range | v1.1 (Phase 11) | Bonus drop formula (area_level - 1) works at any scale. May need exponential scaling in future for areas 1000+, but adequate for v1.1. |

**Current best practices (idle ARPGs, 2024-2025):**
- Hard gating for rare resources (not soft gating via low probability)
- Visual/audio cues when new currency type first drops (not implemented yet, consider for future)
- Gradual ramping instead of instant full availability (feels more rewarding)
- Area names tied to difficulty tiers, not individual levels (1-100 all called "Forest")

## Open Questions

### 1. Should bonus drops favor basic or advanced currencies at high levels?

**What we know:** Current system distributes bonus drops proportionally to what already dropped. At area 300, Runic/Tack get most bonuses because they drop most often.

**What's unclear:** Is this intended design (basic currencies scale better with area level) or an imbalance (advanced currencies should also benefit from high area bonuses)?

**Recommendation:** Make bonus drop distribution uniform across all currencies that passed the area gate. This gives Claw/Tuning a better growth curve at area 300+ without nerfing Runic/Tack at low levels. Test with simulator to confirm feel.

### 2. Should area progression slow down at higher tiers?

**What we know:** Current system has 10% chance to advance area per clear. This is uniform across all levels.

**What's unclear:** Should progression from 200→201 take longer than 1→2? Idle games often exponentially increase progression time.

**Recommendation:** Leave as-is for Phase 11. This is a progression pacing question, not a currency gating question. Phase 12 (Drop Rate Rebalancing) can tune progression speed if needed.

### 3. How many area levels should a player clear before seeing their first advanced currency?

**What we know:** With 10% starting chance and ramping, Forge at area 100 has ~3% effective chance (0.3 base × 0.1 ramp).

**What's unclear:** Is 1 Forge per ~33 clears the right feel, or should first Forge drop faster (higher starting ramp) or slower (lower starting ramp)?

**Recommendation:** Start with 0.1 (10%) ramp multiplier. Simulator will show approximately how many clears until first drop. If it feels too slow in playtesting (Phase 12), increase starting multiplier to 0.2 or reduce ramp_duration to 25.

## Sources

### Primary (HIGH confidence)

- **Codebase analysis** — LootTable.gd, gameplay_view.gd, Currency.gd examined directly
- **Phase 7 Plans** — 07-01-PLAN.md and 07-02-PLAN.md document existing drop system design
- **ARCHITECTURE.md** — Lines 400-600 document currency gating integration patterns

### Secondary (MEDIUM confidence)

- **Roadmap note** — "Requires simulation testing to validate drop distribution" confirms validation approach
- **Phase requirements** — GATE-01 through GATE-04 and AREA-01 through AREA-03 define acceptance criteria

### Tertiary (LOW confidence)

- **Genre conventions** — Idle ARPG pattern of resource gating (Path of Exile, Idle Champions, Melvor Idle) informs hard-gating vs soft-gating decision. Not verified against official documentation, based on genre knowledge.

## Metadata

**Confidence breakdown:**
- Implementation patterns: HIGH — existing LootTable structure supports gating with minimal changes
- Area threshold values (1/100/200/300): HIGH — explicitly defined in requirements
- Ramping formula parameters (0.1 start, 50 duration): MEDIUM — educated guess, requires simulator validation
- Bonus drop distribution: MEDIUM — existing code analyzed, but optimal approach unclear without playtesting

**Research date:** 2026-02-16
**Valid until:** 60 days (stable domain — drop systems in Godot don't change rapidly)

## Next Steps for Planner

When creating PLAN.md files, focus on:

1. **Task 1: Update LootTable with gating and ramping** — Add CURRENCY_AREA_GATES, modify roll_currency_drops(), add _calculate_currency_chance() helper
2. **Task 2: Expand area level range in gameplay_view** — Update area naming to use 1/100/200/300 thresholds
3. **Task 3: Update rarity weights for wider range** — Modify RARITY_WEIGHTS and get_rarity_weights() to support 300+ area levels
4. **Task 4: Create drop simulator** — Build tools/drop_simulator.gd to validate distribution before deployment
5. **Task 5: Verification testing** — Run simulator, confirm GATE-01 through AREA-03 requirements met

**Critical success factor:** Simulator output showing smooth progression (Forge common by area 150, Grand common by area 250) without starvation periods (no 100-clear droughts).
