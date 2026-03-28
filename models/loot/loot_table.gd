class_name LootTable extends Resource

# Legacy rarity anchors — items now always drop as Normal (0 affixes).
# Retained for reference; not used in current drop path.
# Area 1:   1.0 items/clear -> 2% rare per roll = 0.02 rares/clear (1 per 50)
# Area 100: 2.3 items/clear -> 4% rare per roll = 0.09 rares/clear (1 per 11)
# Area 200: 3.5 items/clear -> 5% rare per roll = 0.18 rares/clear (1 per 5.7)
# Area 300: 4.5 items/clear -> 5% rare per roll = 0.23 rares/clear (1 per 4.4)
const RARITY_ANCHORS: Dictionary = {
	1: {Item.Rarity.NORMAL: 91.0, Item.Rarity.MAGIC: 7.0, Item.Rarity.RARE: 2.0},
	100: {Item.Rarity.NORMAL: 66.0, Item.Rarity.MAGIC: 30.0, Item.Rarity.RARE: 4.0},
	200: {Item.Rarity.NORMAL: 40.0, Item.Rarity.MAGIC: 55.0, Item.Rarity.RARE: 5.0},
	300: {Item.Rarity.NORMAL: 20.0, Item.Rarity.MAGIC: 75.0, Item.Rarity.RARE: 5.0},
}

# Currency unlock thresholds by area level.
# Gates shifted 10 levels before biome boundaries (Phase 34) so players
# receive preview drops from the next biome. The 12-level sqrt ramp from
# _calculate_currency_chance() means drops start very rare (~29% of base
# at unlock+1) and reach full rate by the original biome boundary.
const CURRENCY_AREA_GATES: Dictionary = {
	"transmute": 1,
	"alteration": 1,
	"augment": 15,    # Preview from level 15, full rate by Dark Forest (25)
	"regal": 40,    # Preview from level 40, full rate by Cursed Woods (50)
	"chaos": 65,     # Preview from level 65, full rate by Shadow Realm (75)
	"exalt": 65,   # Preview from level 65, full rate by Shadow Realm (75)
}

## Per-pack item drop chance. Constant across all areas.
## Targets 1-3 items per map (8-15 packs per map).
const PACK_ITEM_DROP_CHANCE: float = 0.18


## Calculates currency drop chance with ramping for newly unlocked currencies.
## Starts at ~29% of base chance at unlock (sqrt curve), ramps to 100% over ramp_duration levels.
## Square-root curve: immediate but low — player sees drops right away, full rate after 12 levels.
static func _calculate_currency_chance(
	base_chance: float,
	area_level: int,
	unlock_level: int,
	ramp_duration: int = 12
) -> float:
	if area_level < unlock_level:
		return 0.0
	var levels_since_unlock: int = area_level - unlock_level
	if levels_since_unlock >= ramp_duration:
		return base_chance
	var ramp_progress: float = float(levels_since_unlock) / float(ramp_duration)
	# Square-root curve: starts at ~30% at level 1, reaches 100% at level 12
	# This is the "immediate but low" shape from user decisions
	var ramp_multiplier: float = sqrt(ramp_progress)
	return base_chance * ramp_multiplier


## Rolls currency drops for a single pack kill.
## Returns dictionary mapping currency name to drop count.
## Target: ~1 drop per 3-5 packs at full rate. Area gating from CURRENCY_AREA_GATES applies.
## New currencies ramp from low to full over 12 levels (sqrt curve).
static func roll_pack_currency_drop(
	area_level: int, pack_difficulty_bonus: float = 1.0
) -> Dictionary:
	var drops: Dictionary = {}

	# Per-pack base chances targeting ~1 drop per 3-5 packs
	# Runic/Tack are basic currencies — more generous (25%, max 2)
	# Advanced currencies drop at 20% since player accumulates multiple types simultaneously
	var pack_currency_rules: Dictionary = {
		"transmute": {"chance": 0.25, "max_qty": 2},   # ~1 per 4 packs, sometimes 2
		"alteration": {"chance": 0.25, "max_qty": 2},  # ~1 per 4 packs, sometimes 2
		"augment": {"chance": 0.25, "max_qty": 1},     # ~1 per 4 packs
		"regal": {"chance": 0.20, "max_qty": 1},       # ~1 per 5 packs
		"chaos": {"chance": 0.20, "max_qty": 1},       # ~1 per 5 packs
		"exalt": {"chance": 0.20, "max_qty": 1},       # ~1 per 5 packs
	}

	for currency_name in pack_currency_rules:
		var unlock_level: int = CURRENCY_AREA_GATES[currency_name]
		if area_level < unlock_level:
			continue

		var rule: Dictionary = pack_currency_rules[currency_name]
		var effective_chance: float = rule["chance"] * pack_difficulty_bonus

		# Apply unlock ramp for currencies that don't unlock at area 1
		if unlock_level > 1:
			effective_chance = _calculate_currency_chance(
				effective_chance, area_level, unlock_level
			)

		if randf() < effective_chance:
			# Roll quantity: 1 or up to max_qty
			var quantity: int = randi_range(1, rule["max_qty"])
			drops[currency_name] = quantity

	return drops


## Rolls whether a pack kill drops an item.
## Returns true if an item should drop, false otherwise.
## Drop rate is constant across all biomes (no area scaling).
static func roll_pack_item_drop() -> bool:
	return randf() < PACK_ITEM_DROP_CHANCE


## Rolls tag currency drops for a single pack kill.
## Only active after Prestige 1. ~7.5% chance per pack.
## Returns dict mapping tag type to quantity (e.g. {"fire": 1}).
static func roll_pack_tag_currency_drop(area_level: int) -> Dictionary:
	if GameState.prestige_level < 1:
		return {}

	var drops: Dictionary = {}
	# 7.5% per pack — middle of 5-10% range per user decision
	if randf() < 0.075:
		var tag_types: Array[String] = PrestigeManager.TAG_TYPES
		var chosen: String = tag_types[randi() % tag_types.size()]
		# Small qty-2 chance at higher areas (area >= 50, 15% of drops)
		var qty: int = 1
		if area_level >= 50 and randf() < 0.15:
			qty = 2
		drops[chosen] = qty
	return drops


## Tier home area centers aligned to biome boundaries.
## T8=12 (mid-Forest), T7=37 (mid-Dark Forest), T6=62, T5=87, T4=112, T3=137, T2=162, T1=187.
const TIER_WEIGHT_SIGMA: float = 25.0

static func _tier_home_center(t: int) -> float:
	return 12.0 + float(8 - t) * 25.0

## Rolls an item tier (1-8) from area-weighted bell-curve distribution.
## At P0 (max_tier_unlocked == 8, only tier 8), always returns 8.
## At P1+ tiers compete with Gaussian-like weights centered on their home areas.
## Lower tier number = better item. max_tier_unlocked is the numerically smallest tier allowed.
static func roll_item_tier(area_level: int, max_tier_unlocked: int) -> int:
	if max_tier_unlocked == 8:
		return 8

	var weights: Array[float] = []
	var tiers: Array[int] = []
	# Iterate from worst (8) to best (max_tier_unlocked)
	for t in range(8, max_tier_unlocked - 1, -1):
		var center: float = _tier_home_center(t)
		var dist: float = abs(float(area_level) - center)
		var w: float = exp(-0.5 * (dist / TIER_WEIGHT_SIGMA) * (dist / TIER_WEIGHT_SIGMA))
		weights.append(maxf(w, 0.01))  # Floor prevents any tier from having 0 weight
		tiers.append(t)

	# Weighted random pick
	var total: float = 0.0
	for w in weights:
		total += w
	var roll: float = randf() * total
	var cumulative: float = 0.0
	for i in range(tiers.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return tiers[i]
	return tiers[-1]
