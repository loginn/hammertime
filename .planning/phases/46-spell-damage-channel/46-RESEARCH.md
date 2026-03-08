# Phase 46: Spell Damage Channel — Research

**Researched:** 2026-03-06

## Existing Infrastructure

### Tag Constants (Already Exist — Phase 42)
- `Tag.SPELL` constant (tag.gd line 26)
- `Tag.StatType.FLAT_SPELL_DAMAGE` (line 53)
- `Tag.StatType.INCREASED_SPELL_DAMAGE` (line 54)
- `Tag.StatType.INCREASED_CAST_SPEED` (line 55)

### Spell Affixes (Already Registered — Phase 45)
- Flat Spell Damage prefix: tags `[SPELL, FLAT, WEAPON]`, stat `FLAT_SPELL_DAMAGE` (item_affixes.gd lines 179-184)
- %Spell Damage prefix: tags `[SPELL, PERCENTAGE, WEAPON]`, stat `INCREASED_SPELL_DAMAGE` (lines 188-192)
- Cast Speed suffix: tags `[SPEED]`, stat `INCREASED_CAST_SPEED` (lines 301-306)

### Sapphire Ring (Already Has Spell Implicit)
- `FLAT_SPELL_DAMAGE` implicit (sapphire_ring.gd lines 36-40)
- `valid_tags = [Tag.INT, Tag.SPELL, Tag.SPEED, Tag.WEAPON]` (line 29)
- Needs `base_cast_speed` field added per CONTEXT.md decision

## Pattern Analysis

### StatCalculator.calculate_dps() Pipeline
**File:** `models/stats/stat_calculator.gd`

Order: flat damage → % damage → speed → crit multiplier

```
1. Base damage (weapon.base_damage_min/max)
2. Add flat damage affixes (FLAT_PHYSICAL_DAMAGE, FLAT_FIRE_DAMAGE, etc.)
3. Apply % increased damage (additive stacking of all "increased" modifiers)
4. Multiply by attack speed (base_speed + INCREASED_ATTACK_SPEED affixes)
5. Apply crit multiplier: 1 + (crit_chance/100) * (crit_damage/100 - 1)
```

**Spell equivalent must mirror this:**
```
1. Base spell damage (weapon.base_spell_damage_min/max OR ring implicit FLAT_SPELL_DAMAGE)
2. Add flat spell damage affixes (FLAT_SPELL_DAMAGE)
3. Apply % increased spell damage (INCREASED_SPELL_DAMAGE, additive stacking)
4. Multiply by cast speed (base_cast_speed + INCREASED_CAST_SPEED affixes)
5. Apply shared crit multiplier (same formula, same stats)
```

### StatCalculator.calculate_damage_range()
Returns per-element dict: `{"physical": {"min": X, "max": Y}, "fire": {...}, ...}`

Uses dual accumulators per element. Spell version should return same structure since spell damage can be elemental (fire/cold/lightning spell damage via tagged affixes).

### Hero.update_stats() Call Order
```gdscript
calculate_crit_stats()      # weapon + ring crit, no double-count
calculate_damage_ranges()   # per-element min/max from weapon + ring
calculate_dps()             # sum of element averages * speed * crit
calculate_defense()         # armor, evasion, ES, resistances
```

**Spell additions needed in same pipeline:**
```gdscript
calculate_crit_stats()           # unchanged — shared crit pool
calculate_damage_ranges()        # unchanged — attack ranges
calculate_spell_damage_ranges()  # NEW — parallel to attack ranges
calculate_dps()                  # now sets attack_dps (renamed from total_dps)
calculate_spell_dps()            # NEW — parallel to calculate_dps()
calculate_defense()              # unchanged
```

### Hero Damage Ranges Dict Structure
```gdscript
damage_ranges = {
    "physical": {"min": 0.0, "max": 0.0},
    "fire": {"min": 0.0, "max": 0.0},
    "cold": {"min": 0.0, "max": 0.0},
    "lightning": {"min": 0.0, "max": 0.0}
}
```

`spell_damage_ranges` should use identical structure.

### ForgeView Stat Display
**File:** `scenes/forge_view.gd`

- `update_hero_stats_display()` builds stat text (lines 657+)
- Currently shows "Total DPS: %.1f" (line 691) — rename to "Attack DPS"
- Add "Spell DPS: %.1f" line with hide-zero logic
- Weapon comparison (lines 776-786) shows DPS delta
- Ring comparison (lines 796-808) shows DPS delta
- Both need spell DPS delta lines

### Item Serialization
- `to_dict()` serializes item_type, name, rarity, tier, implicit, prefixes, suffixes
- `from_dict()` uses match statement with all 18+ item types
- `update_value()` called post-deserialization — recalculates all stats
- New spell fields (base_spell_damage_min/max, base_cast_speed) need serialization in weapon/ring to_dict/from_dict
- Existing affixes (spell damage, cast speed) serialize automatically via affix system

### Weapon.gd Fields
Current: `base_damage_min`, `base_damage_max`, `base_speed`, `base_attack_speed`, `crit_chance`, `crit_damage`, `dps`

Add: `base_spell_damage_min`, `base_spell_damage_max`, `base_cast_speed` (all default 0)

### Ring.gd Fields
Current: `base_damage`, `base_speed`, `crit_chance`, `crit_damage`, `dps`

Add: `base_cast_speed` (default 0) — rings contribute spell damage via implicit/affixes only, not base fields

## Key Implementation Notes

### Spell Channel Activation
Per CONTEXT.md: spell channel activates when total cast speed > 0 from ANY equipped gear. This means:
- Hero must aggregate cast_speed from weapon AND ring
- If only Sapphire Ring equipped (with base_cast_speed > 0) and no spell weapon, spell channel still activates
- If cast_speed == 0, spell DPS is hidden (hide-zero logic)

### Element Routing for Spells
Spell damage can be elemental. FLAT_SPELL_DAMAGE is "generic" spell damage (physical element equivalent for spells). Elemental spell damage would come from affixes tagged with both SPELL and FIRE/COLD/LIGHTNING.

Currently only FLAT_SPELL_DAMAGE exists as a spell-specific stat. The existing elemental flat damage affixes (FLAT_FIRE_DAMAGE etc.) are tagged ATTACK. For Phase 46, spell damage will likely be single-element unless we route some affixes to spell channel too.

**Recommendation:** Keep it simple — FLAT_SPELL_DAMAGE contributes generic spell damage. %INCREASED_SPELL_DAMAGE scales it. Don't try to split spell damage into elements until needed (Phase 47+ when INT weapons actually deal typed spell damage).

### update_value() in Weapon/Ring
Both call `StatCalculator.calculate_dps()` to update their `dps` field. They should also call the new spell equivalent to update a `spell_dps` field.

### No CombatEngine Changes
Phase 46 explicitly excludes CombatEngine changes. The spell timer (hero_spell_timer) is Phase 47. Phase 46 only wires the stat pipeline and display.

## Risk Assessment

**Low risk:** This is a parallel system addition. Attack damage calculations remain unchanged. Spell damage mirrors the exact same patterns.

**Watch for:**
1. Double-counting if ring spell implicit is counted as both attack AND spell damage
2. Crit multiplier applied correctly to spell DPS (shared pool, same formula)
3. Serialization of new fields — save format needs version bump? (Check if new fields with defaults need it, or if they're optional)
4. Element routing — keep spell damage as single "spell" element for now, don't over-engineer

## Validation Architecture

### Unit Tests
1. **StatCalculator spell methods:**
   - `calculate_spell_damage_range()` with base spell damage + flat spell damage affixes
   - `calculate_spell_dps()` with cast speed and crit
   - Verify %spell damage scales correctly
   - Verify 0 cast speed → 0 spell DPS

2. **Hero spell stats:**
   - Hero with spell weapon shows spell_damage_ranges populated
   - Hero with attack-only weapon has empty spell_damage_ranges
   - Hero with Sapphire Ring + attack weapon still shows spell DPS (ring cast speed enables)
   - Crit applies to spell DPS correctly

3. **Weapon/Ring fields:**
   - Default spell fields are 0
   - Serialization round-trip preserves spell fields

### Integration Tests
4. **Full equip flow:**
   - Equip weapon with spell damage → Spell DPS appears in Hero View
   - Equip attack-only weapon → Spell DPS hidden
   - Equip Sapphire Ring → spell channel contribution verified
   - Unequip spell weapon → Spell DPS disappears

5. **Comparison flow:**
   - Compare spell weapon vs attack weapon → both channels shown
   - Compare two attack weapons → spell line hidden

### Manual Verification
6. **Visual check:**
   - "Attack DPS" label (not "Total DPS")
   - "Spell DPS" line appears/hides correctly
   - Weapon tooltip shows "Spell Damage: X to Y" when applicable

## RESEARCH COMPLETE
