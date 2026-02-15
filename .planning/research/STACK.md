# Stack Research

**Domain:** ARPG Crafting Idle Game - Defensive Prefixes, Expanded Affixes, Currency Area Gating
**Researched:** 2026-02-15
**Confidence:** HIGH

## Recommended Stack

### Core Technologies (Already Validated)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Godot Engine | 4.6 | Game engine | Current stable release (Jan 27, 2026). Mobile renderer mode already configured. GDScript profiling improvements useful for affix pool iteration optimization. |
| GDScript | 4.6 | Language | Only language in existing codebase. Type-safe Resource extensions work well for data model. No additions needed. |

### Supporting Libraries

**None Required.**

The milestone features (defensive prefixes, expanded affixes, currency area gating, drop rate rebalancing) are pure data model extensions and game logic changes. No external libraries needed.

**Why:**
- Tag system already handles affix filtering (Tag.DEFENSE, Tag.ARMOR, etc.)
- ItemAffixes autoload pattern supports unlimited affix definitions
- LootTable.roll_currency_drops() already implements weighted random selection
- GameState already has area progression state (implicitly via area_level)
- StatCalculator.calculate_flat_stat() pattern extends to new stat types
- Resource-based data model supports new properties via @export

## What NOT to Add

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Godot Loot Table plugins (Lootie, godot-loot-tables) | Project already has custom LootTable static class with area-based rarity weighting. Adding plugin creates two systems. | Extend existing LootTable.gd with new methods |
| State machine libraries (godot-statecharts, StateSync) | Area gating is simple unlock state (bool per area), not complex state transitions. Autoload GameState already manages progression. | Add unlock_status Dictionary to GameState |
| Weighted Choice plugin | LootTable.roll_currency_drops() already implements weighted random correctly. Adding plugin for identical functionality creates dependency. | Extend roll_currency_drops() with area gates |
| New autoloads | Four autoloads (ItemAffixes, Tag, GameEvents, GameState) are sufficient. Area gating fits in GameState, new affixes fit in ItemAffixes. | Use existing autoloads |

## Stack Patterns by Feature

### Defensive Prefixes

**Existing pattern:** Affixes stored in ItemAffixes.prefixes array with tags and stat_types.

**Add:**
```gdscript
# In autoloads/item_affixes.gd
Affix.new("Armored", Affix.AffixType.PREFIX, 5, 15, [Tag.DEFENSE, Tag.ARMOR], [Tag.StatType.FLAT_ARMOR])
Affix.new("Warded", Affix.AffixType.PREFIX, 3, 10, [Tag.DEFENSE, Tag.ENERGY_SHIELD], [Tag.StatType.FLAT_ENERGY_SHIELD])
Affix.new("Healthy", Affix.AffixType.PREFIX, 10, 30, [Tag.DEFENSE], [Tag.StatType.FLAT_HEALTH])
```

**Why:** Matches weapon prefix pattern (lines 3-37). Tag.DEFENSE already exists (tag.gd:8). StatType enums already exist (tag.gd:28-30). Helmet/Armor/Boots already filter by Tag.DEFENSE via valid_tags property.

**Integration point:** Item.add_prefix() (item.gd:140-163) already checks has_valid_tag(). No code changes needed.

### Expanded Suffix Types

**Existing pattern:** 15 suffixes in ItemAffixes.suffixes array.

**Add:**
```gdscript
# New suffix types in autoloads/item_affixes.gd
Affix.new("Mana", Affix.AffixType.SUFFIX, 5, 20, [Tag.DEFENSE, Tag.MANA], [Tag.StatType.FLAT_MANA])
Affix.new("Movement Speed", Affix.AffixType.SUFFIX, 2, 8, [Tag.MOVEMENT], [Tag.StatType.MOVEMENT_SPEED])
# Additional elemental/physical variants as needed
```

**Why:** Tag.MANA (tag.gd:19) and Tag.MOVEMENT (tag.gd:20) already exist. StatType.FLAT_MANA and StatType.MOVEMENT_SPEED already exist (tag.gd:31-32). Pattern matches existing suffixes (item_affixes.gd:39-78).

**Integration point:** Item.add_suffix() (item.gd:166-189) already checks has_valid_tag(). No code changes needed.

### Currency Area Gating (Hard Gate + Ramping Drop Chance)

**Existing pattern:** GameState.currency_counts Dictionary tracks inventory. LootTable.roll_currency_drops() generates drops per area clear.

**Add:**
```gdscript
# In autoloads/game_state.gd
var area_unlock_status: Dictionary = {
	1: true,   # Tutorial area always unlocked
	2: false,  # Unlocked after clearing area 1
	3: false,  # Unlocked after clearing area 2
	# etc.
}

func unlock_area(area_level: int) -> void:
	if area_level in area_unlock_status:
		area_unlock_status[area_level] = true
		GameEvents.area_unlocked.emit(area_level)

func is_area_unlocked(area_level: int) -> bool:
	return area_unlock_status.get(area_level, false)
```

**Why:** Dictionary is O(1) lookup. Pattern matches currency_counts (game_state.gd:6). GameEvents autoload already exists for event signaling (game_events.gd).

**Integration point:**
- UI checks GameState.is_area_unlocked() before allowing area selection
- Gameplay clears call GameState.unlock_area(current_level + 1)

**Currency drop ramping:**
```gdscript
# In models/loot/loot_table.gd - extend roll_currency_drops()
static func get_currency_drop_chance(currency_name: String, area_level: int) -> float:
	# Example ramping: higher areas = higher drop chance for rare currencies
	var base_chances = {
		"runic": 0.7,
		"forge": 0.3,
		"tack": 0.5,
		"grand": 0.2,
		"claw": 0.4,
		"tuning": 0.4,
	}

	var base_chance = base_chances.get(currency_name, 0.0)

	# Ramp: +5% per area level (capped at 95%)
	var ramped_chance = min(base_chance + (area_level - 1) * 0.05, 0.95)
	return ramped_chance
```

**Why:** Keeps weighted random logic in LootTable (single responsibility). Area level already passed to roll_currency_drops() (loot_table.gd:53). No new dependencies.

### Drop Rate Rebalancing

**Existing pattern:** LootTable.RARITY_WEIGHTS constant defines weights per area level. LootTable.roll_rarity() performs weighted selection.

**Approach:**
```gdscript
# In models/loot/loot_table.gd - modify RARITY_WEIGHTS const
const RARITY_WEIGHTS: Dictionary = {
	1: { Item.Rarity.NORMAL: 70, Item.Rarity.MAGIC: 25, Item.Rarity.RARE: 5 },  # Rebalanced
	2: { Item.Rarity.NORMAL: 40, Item.Rarity.MAGIC: 45, Item.Rarity.RARE: 15 }, # Rebalanced
	# etc.
}
```

**Why:** Constants are compile-time. No performance cost. roll_rarity() already reads this Dictionary (loot_table.gd:22-47). Changing values is pure data tuning, not architecture change.

**Alternative (data-driven):**
- Export RARITY_WEIGHTS to JSON/CSV if frequent tuning needed
- **Recommendation:** Start with constants. Only externalize if balance iteration becomes bottleneck.

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| Godot 4.6 | Mobile renderer | project.godot already configures `rendering_method="mobile"` (line 37) |
| GDScript 4.6 | Typed arrays (Array[Affix]) | Existing code uses typed arrays throughout (item.gd:13-14). Continue pattern. |

## Performance Considerations

### Affix Pool Iteration

**Current:** Item.add_prefix() iterates ItemAffixes.prefixes (O(n) where n = prefix count).

**With expansion:** 9 weapon prefixes + ~5-10 defensive prefixes = ~15-19 total.

**Impact:** O(19) iteration per prefix add. Negligible (< 1ms on mobile).

**Godot 4.6 optimization:** GDScript array iteration bytecode improved in 4.6. No action needed.

### Dictionary Lookups

**Area unlock checks:** GameState.is_area_unlocked() uses Dictionary.get() = O(1).

**Currency drops:** LootTable.currency_rules Dictionary lookup = O(1) per currency (6 currencies = 6 lookups).

**Rarity weights:** LootTable.RARITY_WEIGHTS[area_level] = O(1).

**Verdict:** All hot paths are O(1) or O(n) where n is small constants (< 20). No performance concerns.

## Data Model Extensions

### New StatType Enums (If Needed)

**Current:** Tag.StatType enum has 10 values (tag.gd:22-33).

**Potentially add:**
```gdscript
# In autoloads/tag.gd StatType enum
PERCENT_ARMOR,        # For %Armor prefixes
PERCENT_ENERGY_SHIELD # For %Energy Shield prefixes
```

**Why:** Current StatTypes are FLAT_* only. If defensive prefixes include percentage modifiers, add enum values. Matches INCREASED_DAMAGE pattern (tag.gd:24).

**Integration:** StatCalculator would need calculate_percentage_stat() method (similar to calculate_flat_stat(), line 55-60). Defense items call it in update_value().

## Installation

**No installation required.** All changes are GDScript source modifications.

**Workflow:**
1. Extend ItemAffixes.prefixes/suffixes arrays (autoloads/item_affixes.gd)
2. Add area_unlock_status to GameState (autoloads/game_state.gd)
3. Modify RARITY_WEIGHTS in LootTable (models/loot/loot_table.gd)
4. Add currency ramping to roll_currency_drops() (models/loot/loot_table.gd)
5. Update UI to check unlock status (scenes/*.gd)

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Dictionary for area unlocks | BitMask (int flags) | If area count exceeds 64 and memory is constrained (unlikely for idle game) |
| Constants for rarity weights | External JSON/CSV | If non-programmers need to tune drop rates frequently (not indicated in milestone) |
| Autoload GameState for unlocks | Save/Load system | If unlocks persist between sessions (milestone doesn't mention persistence) |
| StatCalculator static methods | Hero class methods | Never. StatCalculator single responsibility is calculation. Hero is state container. |

## Migration from Existing Code

**Breaking changes:** None. All additions are backward compatible.

**Safe changes:**
- Adding affixes to ItemAffixes arrays (new affixes won't appear on old items, only new drops/crafts)
- Adding properties to GameState (new Dictionary doesn't affect existing currency_counts)
- Modifying LootTable constants (changes drop rates going forward, doesn't invalidate existing items)

**Testing:** Existing items (if persisted) remain valid. New affixes only appear on newly generated items.

## Sources

- [Godot 4.6 Release](https://godotengine.org/releases/4.6/) - Confirmed January 27, 2026 release, GDScript performance improvements
- [Godot 4.6 Features Guide 2026](https://www.live-laugh-love.world/blog/godot-46-features-complete-guide-2026/) - GDScript bytecode optimizations for array iteration
- [Weighted Random Selection With Godot](http://kehomsforge.com/tutorials/single/weighted-random-selection-godot/) - Validated existing LootTable.roll_rarity() implementation pattern
- [Godot Dictionary Performance](https://generalistprogrammer.com/tutorials/godot-dictionary-tutorial-with-examples) - O(1) average case for hash map operations
- [When to Node, Resource, and Class in Godot](https://backat50ft.substack.com/p/when-to-node-resource-and-class-in) - Confirmed Resource pattern for data containers (existing Item/Affix/Currency classes)
- [Godot Resources Documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html) - Validated Resource extension via @export pattern
- [GDQuest Godot 4.6 Workflow Changes](https://www.gdquest.com/library/godot_4_6_workflow_changes/) - Profiling tools for optimization validation
- [Loot Drop Best Practices](https://www.gamedeveloper.com/design/loot-drop-best-practices) - Industry patterns for drop rate ramping (informed currency ramping design)

---
*Stack research for: Hammertime - Defensive Prefixes, Expanded Affixes, Currency Area Gating*
*Researched: 2026-02-15*
*Confidence: HIGH — All core recommendations validated against existing Godot 4.6 codebase patterns*
