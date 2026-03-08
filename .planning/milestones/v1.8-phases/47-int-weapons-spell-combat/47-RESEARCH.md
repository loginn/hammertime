# Phase 47: INT Weapons & Spell Combat - Research

## Research Summary

Phase 47 adds 3 INT weapon bases (Wand, Lightning Rod, Sceptre) with 8 tier variants each, and wires the CombatEngine so that spell-user heroes deal spell damage via an independent timer. This is the highest-risk change in the milestone because it modifies `combat_engine.gd` (the core combat loop).

Key findings:
- The combat engine currently has exactly two timers (`hero_attack_timer`, `pack_attack_timer`). The context decision says to use ONE timer per hero (spell OR attack, not both) based on `hero.is_spell_user`.
- All spell damage infrastructure already exists from Phase 46: `Weapon.base_spell_damage_min/max`, `Weapon.base_cast_speed`, `StatCalculator.calculate_spell_damage_range()`, `Hero.spell_damage_ranges`, `Hero.total_spell_dps`.
- Two new StatType values are needed: `FLAT_SPELL_LIGHTNING_DAMAGE` and `FLAT_SPELL_FIRE_DAMAGE` for element-specific spell implicits.
- The `StatCalculator.calculate_spell_damage_range()` currently only handles a single "spell" element. It must be extended to support per-element spell damage (spell, spell_fire, spell_lightning) for the new weapon implicits to work correctly.
- The existing weapon pattern (Phase 44) is well-established: class extends Weapon, TIER_NAMES dict, TIER_STATS dict, `_init(p_tier)`, `get_item_type_string()`.

Requirements addressed: BASE-04, SPELL-06.

---

## Codebase Analysis

### 1. CombatEngine (`models/combat/combat_engine.gd`)

**Current architecture:**
- Two timers: `hero_attack_timer` (fires `_on_hero_attack`) and `pack_attack_timer` (fires `_on_pack_attack`).
- `_start_pack_fight()` (line 63) sets both timer cadences and starts them.
- `_on_hero_attack()` (line 72) rolls per-element damage from `hero.damage_ranges`, applies crit, calls `pack.take_damage()`, emits `GameEvents.hero_attacked`.
- `_get_hero_attack_speed()` (line 212) reads `weapon.base_attack_speed` from equipped weapon, fallback 1.0.
- `_stop_timers()` (line 229) stops both timers.

**Changes needed for SPELL-06:**
- Per context decision: CombatEngine uses ONE timer per hero. If `hero.is_spell_user`, use spell timer with cast speed; otherwise use attack timer with attack speed. Never both simultaneously.
- Add `_on_hero_spell_hit()` method mirroring `_on_hero_attack()` but rolling from `hero.spell_damage_ranges`.
- Add `_get_hero_cast_speed()` mirroring `_get_hero_attack_speed()` but reading `base_cast_speed`, with fallback 1.0.
- Modify `_start_pack_fight()` to branch on `hero.is_spell_user`: connect and start the appropriate timer.
- Emit new `GameEvents.hero_spell_hit` signal (not `hero_attacked`) so UI can differentiate color.
- `_stop_timers()` must stop all timers (attack + spell + pack).

**Key concern:** The hero_attack_timer object can be reused for spell timing (just change the callback and wait_time), OR a separate `hero_spell_timer` Timer node can be created. The context says "third independent timer" but also says "ONE timer per hero." The safest approach: create the spell timer as a third Timer node in `_ready()`, but only start ONE of (hero_attack_timer, hero_spell_timer) based on `is_spell_user` in `_start_pack_fight()`.

### 2. Hero Model (`models/hero.gd`)

**Current state:**
- `damage_ranges` dict with keys: "physical", "fire", "cold", "lightning" (line 25-30).
- `spell_damage_ranges` dict with single key: "spell" (line 34-36).
- `calculate_spell_damage_ranges()` (line 184) populates from weapon + ring using `StatCalculator.calculate_spell_damage_range()`.
- `calculate_spell_dps()` (line 218) aggregates cast speed from weapon + ring.
- No `is_spell_user` property yet.

**Changes needed:**
- Add `var is_spell_user: bool = false` property (default false per context).
- Expand `spell_damage_ranges` to support multiple elements: "spell", "spell_fire", "spell_lightning" (needed for Lightning Rod and Sceptre implicits).
- Update `calculate_spell_damage_ranges()` to handle new element-specific flat spell damage stat types.

### 3. Weapon Base Class (`models/items/weapon.gd`)

**Current state:**
- Already has `base_spell_damage_min`, `base_spell_damage_max`, `base_cast_speed`, `spell_dps` (Phase 46).
- `update_value()` already calls `StatCalculator.calculate_spell_dps()`.

**No changes needed** to the base class. INT weapons just set these fields in their `_init()`.

### 4. Tag System (`autoloads/tag.gd`)

**Current StatType enum:**
- Has `FLAT_SPELL_DAMAGE`, `INCREASED_SPELL_DAMAGE`, `INCREASED_CAST_SPEED` (from Phase 42/46).
- Does NOT have `FLAT_SPELL_LIGHTNING_DAMAGE` or `FLAT_SPELL_FIRE_DAMAGE`.

**Changes needed:**
- Add `FLAT_SPELL_LIGHTNING_DAMAGE` and `FLAT_SPELL_FIRE_DAMAGE` to the StatType enum.
- These are separate from attack-channel `FLAT_DAMAGE` with element tags. Per context: "These are NOT shared with attack stat types."

### 5. StatCalculator (`models/stats/stat_calculator.gd`)

**Current `calculate_spell_damage_range()`** (line 142):
- Only handles a single "spell" element.
- Adds `FLAT_SPELL_DAMAGE` to the "spell" bucket.
- Applies `INCREASED_SPELL_DAMAGE` percentage.

**Changes needed:**
- Extend to support spell_fire and spell_lightning elements.
- Route `FLAT_SPELL_FIRE_DAMAGE` affixes to "spell_fire" bucket.
- Route `FLAT_SPELL_LIGHTNING_DAMAGE` affixes to "spell_lightning" bucket.
- `INCREASED_SPELL_DAMAGE` scales ALL spell elements uniformly (confirmed in context).

### 6. GameEvents (`autoloads/game_events.gd`)

**Current signals (combat-related):**
- `hero_attacked(damage: float, is_crit: bool)` -- line 11
- `pack_attacked(result: Dictionary)` -- line 12

**Changes needed:**
- Add `signal hero_spell_hit(damage: float, is_crit: bool)` -- separate signal for spell hits.

### 7. Gameplay View (`scenes/gameplay_view.gd`)

**Current floating text:**
- `_on_hero_attacked()` (line 142) calls `_spawn_floating_text()` with white/gold colors.
- `_spawn_floating_text()` (line 200) delegates to `floating_label.gd`.
- `floating_label.gd` `show_damage()` uses white for normal, gold for crit.

**Changes needed:**
- Connect `GameEvents.hero_spell_hit` signal.
- Add `_on_hero_spell_hit()` handler that spawns floating text with purple/blue color.
- Extend `floating_label.gd` with a `show_spell_damage(value, is_crit)` method or pass a color parameter.

### 8. Item Drop System (`scenes/gameplay_view.gd` lines 274-294)

**Current `get_random_item_base()`:**
- Weapon bases array: `[Broadsword, Battleaxe, Warhammer, Dagger, VenomBlade, Shortbow]` (6 weapons, no INT).

**Changes needed:**
- Add Wand, LightningRod, Sceptre to the weapon bases array (9 total weapons).

### 9. Item Registry (`models/items/item.gd`)

**Current `ITEM_TYPE_STRINGS`** (line 74):
- 18 entries. No INT weapons.

**`create_from_dict()`** match statement (line 90):
- 18 match arms. Must add 3 more.

**Changes needed:**
- Add "Wand", "LightningRod", "Sceptre" to `ITEM_TYPE_STRINGS`.
- Add 3 match arms in `create_from_dict()`.

### 10. Settings View (`scenes/settings_view.gd`)

**Current state:**
- Simple view with Save, New Game, Export, Import buttons.
- No dev toggles currently.

**Changes needed:**
- Add a temporary CheckButton or similar toggle for `is_spell_user`.
- When toggled, set `GameState.hero.is_spell_user` and call `hero.update_stats()`.
- This is a temporary dev tool, removed when hero archetypes ship.

### 11. Existing Weapon Pattern (Phase 44)

All weapons follow identical structure. Example from `broadsword.gd`:

```gdscript
class_name Broadsword extends Weapon

const TIER_NAMES: Dictionary = {
    8: "Rusty Broadsword", 7: "Iron Broadsword", ...
}

const TIER_STATS: Dictionary = {
    8: {"dmg_min": 8, "dmg_max": 12, "atk_speed": 1.8, "imp_min": 2, "imp_max": 5},
    ...
}

func get_item_type_string() -> String:
    return "Broadsword"

func _init(p_tier: int = 8) -> void:
    self.rarity = Rarity.NORMAL
    self.tier = p_tier
    self.item_name = TIER_NAMES[p_tier]
    self.valid_tags = [Tag.STR, Tag.PHYSICAL, Tag.ATTACK, Tag.ARMOR, Tag.ELEMENTAL, Tag.WEAPON]
    self.base_damage_type = Tag.PHYSICAL
    var s = TIER_STATS[p_tier]
    self.base_damage_min = s["dmg_min"]
    self.base_damage_max = s["dmg_max"]
    self.base_speed = 1
    self.base_attack_speed = s["atk_speed"]
    self.implicit = Implicit.new(...)
    self.update_value()
```

**INT weapon differences:**
- `valid_tags` = `[Tag.INT, Tag.SPELL, Tag.ELEMENTAL, Tag.ENERGY_SHIELD, Tag.WEAPON]` (per Phase 44 context).
- Small but non-zero `base_damage_min/max` (suboptimal for attackers).
- Small `base_attack_speed` (~0.5).
- Non-zero `base_spell_damage_min/max` and `base_cast_speed`.
- Element-specific implicits using new spell stat types.

### 12. Save System (`autoloads/save_manager.gd`)

The `is_spell_user` boolean on Hero needs to be serialized/restored. Currently Hero is not directly serialized as a resource -- stats are derived from equipment. However, `is_spell_user` is a player choice (dev toggle), not derived from equipment. It must be saved in the game state.

Looking at `game_state.gd`, the save system builds save data from GameState fields. `is_spell_user` should be stored in GameState or on the Hero and included in save data.

---

## Implementation Patterns

### Weapon Creation Pattern
1. Create `models/items/wand.gd` (and lightning_rod.gd, sceptre.gd) extending Weapon.
2. Define TIER_NAMES (8 entries) and TIER_STATS (8 entries) with: `dmg_min`, `dmg_max`, `atk_speed`, `spell_min`, `spell_max`, `cast_speed`, `imp_min`, `imp_max`.
3. In `_init()`: set `valid_tags`, both attack fields (small values) and spell fields, create element-specific implicit.
4. Override `get_item_type_string()`.

### Timer Branching Pattern
In `_start_pack_fight()`:
```
if GameState.hero.is_spell_user:
    hero_spell_timer.wait_time = 1.0 / _get_hero_cast_speed()
    hero_spell_timer.start()
else:
    hero_attack_timer.wait_time = 1.0 / _get_hero_attack_speed()
    hero_attack_timer.start()
pack_attack_timer.start()  # always starts
```

### Signal Emission Pattern
Follow existing `hero_attacked` pattern:
- Declare signal in `game_events.gd`.
- Emit in `combat_engine.gd` after damage calculation.
- Connect in `gameplay_view.gd:_ready()`.
- Handle in gameplay_view with colored floating text.

### Spell Damage Rolling Pattern
Mirror `_on_hero_attack()` exactly:
```
for element in hero.spell_damage_ranges:
    var el_min = hero.spell_damage_ranges[element]["min"]
    var el_max = hero.spell_damage_ranges[element]["max"]
    if el_max > 0.0:
        damage_per_hit += randf_range(el_min, el_max)
# Apply shared crit
```

---

## Risk Areas

### 1. Timer State Leaks (HIGH)
If combat stops mid-fight and `is_spell_user` changes before next fight, the wrong timer could still be connected or running. `_stop_timers()` must stop ALL three timers. Timer callbacks are connected in `_ready()` (not dynamically), so both callbacks always exist -- only the timer start/stop matters.

### 2. Spell Damage Range Expansion (MEDIUM)
Currently `spell_damage_ranges` has only "spell" key. Adding "spell_fire" and "spell_lightning" keys requires updating:
- `Hero.calculate_spell_damage_ranges()` -- initialize and populate new keys
- `Hero.calculate_spell_dps()` -- sum across all spell elements
- `StatCalculator.calculate_spell_damage_range()` -- route new stat types
- `_on_hero_spell_hit()` in combat engine -- iterate all spell elements

If any of these are missed, element-specific spell damage will be silently zero.

### 3. is_spell_user Persistence (MEDIUM)
The `is_spell_user` flag is a player choice (dev toggle). If not saved, it resets to false on reload. Must be included in save data. Also must survive prestige (or reset -- context says dev toggle is temporary, so resetting to false on prestige is fine).

### 4. Integration Test Regression (LOW)
Existing 24 test groups reference the current spell_damage_ranges structure with single "spell" key. Expanding to multiple keys could break Group 22-24 assertions if not careful. New tests should verify INT weapon construction, spell combat, and the new stat types.

### 5. Cast Speed Fallback (LOW)
Context says "default cast speed fallback of 1.0 when spell user has 0 total cast speed." This prevents division by zero in timer wait_time calculation. Must be implemented in `_get_hero_cast_speed()`.

---

## Validation Architecture

### Integration Tests (New Groups)

**Group 25: INT Weapon Base Construction**
- Wand, LightningRod, Sceptre construct at tiers 1 and 8
- Each has Tag.INT in valid_tags
- Each has non-zero base_spell_damage_min, base_spell_damage_max, base_cast_speed
- Each has non-zero (but small) base_damage_min, base_damage_max, base_attack_speed
- T1 stats > T8 stats for both attack and spell damage
- Implicits use correct element-specific stat types

**Group 26: INT Weapon Serialization**
- Wand, LightningRod, Sceptre round-trip via to_dict/create_from_dict
- item_name, tier, spell fields all preserved
- spell_dps matches original after restore

**Group 27: New Spell Stat Types**
- `FLAT_SPELL_LIGHTNING_DAMAGE` and `FLAT_SPELL_FIRE_DAMAGE` exist in StatType enum
- They are distinct values from each other and from existing stat types
- StatCalculator routes them to correct spell elements

**Group 28: Hero Spell Combat Mode**
- `hero.is_spell_user` defaults to false
- Setting `is_spell_user = true` does not crash
- Spell damage ranges populate correctly with INT weapon equipped
- Element-specific spell damage (fire, lightning) appears in spell_damage_ranges when corresponding weapon equipped

**Group 29: Drop Pool Inclusion**
- INT weapons appear in gameplay_view weapon bases array
- Random generation of all 9 weapon types succeeds

### Manual Verification

1. **Equip Wand + toggle spell mode ON**: Floating text should appear in purple/blue at spell timer cadence. Attack timer should NOT fire.
2. **Equip Broadsword + toggle spell mode OFF**: Normal white floating text at attack speed. No purple text.
3. **Switch weapons mid-combat**: No crashes. Timer switches cleanly at next pack fight start.
4. **Toggle spell/attack during combat**: Verify timers swap at next `_start_pack_fight()` (not mid-pack).
5. **Equip/unequip INT weapon**: Verify spell_dps in hero stats view updates correctly (shows/hides).
6. **Save/load with is_spell_user=true**: Verify mode persists across reload.

---

## RESEARCH COMPLETE
