# Phase 42: Tag & Stat Foundation — Research

**Researched:** 2026-03-06

## Current State Analysis

### tag.gd Structure

File: `autoloads/tag.gd` (44 lines, class_name `Tag_List extends Node`)

**Tag constants (22 string consts, lines 2-22):**
Flat list, no grouping comments. All uppercase `const NAME = "NAME"` pattern.

Current tags in order:
```
PHYSICAL, ELEMENTAL, LIGHTNING, FIRE, COLD, DEFENSE, ATTACK, MAGIC,
DOT, SPEED, FLAT, PERCENTAGE, CRITICAL, WEAPON, ARMOR, ENERGY_SHIELD,
MANA, MOVEMENT, UTILITY, EVASION
```

**StatType enum (19 entries, lines 24-44):**
Single flat enum, comma-separated, no grouping comments.

Current entries:
```
FLAT_DAMAGE, INCREASED_DAMAGE, INCREASED_SPEED, CRIT_CHANCE, CRIT_DAMAGE,
FLAT_ARMOR, FLAT_ENERGY_SHIELD, FLAT_HEALTH, FLAT_MANA, MOVEMENT_SPEED,
PERCENT_ARMOR, PERCENT_EVASION, PERCENT_ENERGY_SHIELD, PERCENT_HEALTH,
FLAT_EVASION, FIRE_RESISTANCE, COLD_RESISTANCE, LIGHTNING_RESISTANCE,
ALL_RESISTANCE
```

### Existing Constants

**Already exist — no action needed:**
- `PHYSICAL` — reused for bleed (per CONTEXT decision)
- `FIRE` — reused for burn (per CONTEXT decision)
- `DOT` — exists but unused (disabled affix stubs reference it)
- `MAGIC` — exists but currently unused; SPELL will be a separate new constant (CONTEXT decision: INT and SPELL are independent tags)

**Do NOT exist yet (confirmed by grep):**
- STR, DEX, INT — no archetype tags
- SPELL — no spell tag
- CHAOS — no chaos element tag
- FLAT_SPELL_DAMAGE, INCREASED_SPELL_DAMAGE, INCREASED_CAST_SPEED — no spell stat types
- BLEED_DAMAGE, POISON_DAMAGE, BURN_DAMAGE — no DoT stat types
- CHAOS_RESISTANCE — no chaos resistance stat type

## New Constants Needed

### Tag Constants (string consts)

| Constant | Value | Rationale | Used By (Phase) |
|----------|-------|-----------|-----------------|
| `STR` | `"STR"` | Archetype identity for strength items (AFF-06) | 44, 45, 48, 49 |
| `DEX` | `"DEX"` | Archetype identity for dexterity items (AFF-06) | 44, 45, 48, 49 |
| `INT` | `"INT"` | Archetype identity for intelligence items (AFF-06) | 44, 45, 47, 49 |
| `SPELL` | `"SPELL"` | Spell damage channel tag, independent from INT (SPELL-02) | 45, 46, 47 |
| `CHAOS` | `"CHAOS"` | New element type for poison; analogous to PHYSICAL/FIRE/COLD/LIGHTNING | 48 |

**Total: 5 new Tag constants**

### StatType Enum Additions

| Constant | Rationale | Used By (Phase) |
|----------|-----------|-----------------|
| `FLAT_SPELL_DAMAGE` | Flat spell damage stat, mirrors FLAT_DAMAGE for spells (SPELL-01) | 45, 46 |
| `INCREASED_SPELL_DAMAGE` | Percentage spell damage stat, mirrors INCREASED_DAMAGE (SPELL-01) | 45, 46 |
| `INCREASED_CAST_SPEED` | Cast speed stat, mirrors INCREASED_SPEED for spells (SPELL-01) | 45, 46, 47 |
| `BLEED_DAMAGE` | Physical DoT damage stat (DOT-01 via Phase 42 scope) | 45, 48 |
| `POISON_DAMAGE` | Chaos DoT damage stat (DOT-01 via Phase 42 scope) | 45, 48 |
| `BURN_DAMAGE` | Fire DoT damage stat (DOT-01 via Phase 42 scope) | 45, 48 |
| `CHAOS_RESISTANCE` | Resistance to chaos damage; separate from ALL_RESISTANCE (CONTEXT decision) | 48 |

**Total: 7 new StatType enum entries**

## Implementation Notes

### Patterns to Follow
- Tag constants: `const NAME = "NAME"` — exact pattern used by all 22 existing constants
- StatType entries: plain enum values, comma-separated, trailing comma on last entry (Godot convention in this file)
- Referenced as `Tag.CONSTANT_NAME` for tags, `Tag.StatType.ENTRY_NAME` for stat types

### Suggested Grouping/Ordering

**Tags — insert after existing constants with logical grouping:**
```gdscript
# Existing element tags: PHYSICAL, ELEMENTAL, LIGHTNING, FIRE, COLD
# Add CHAOS after COLD (element group)
const CHAOS = "CHAOS"

# Existing category tags: DEFENSE, ATTACK, MAGIC
# Add SPELL after ATTACK (damage channel group)
const SPELL = "SPELL"

# Archetype tags (new group, add at end before or after EVASION)
const STR = "STR"
const DEX = "DEX"
const INT = "INT"
```

**StatType — append new entries at the end (after ALL_RESISTANCE):**
```gdscript
# Spell damage stats
FLAT_SPELL_DAMAGE,
INCREASED_SPELL_DAMAGE,
INCREASED_CAST_SPEED,
# DoT damage stats
BLEED_DAMAGE,
POISON_DAMAGE,
BURN_DAMAGE,
# Chaos resistance
CHAOS_RESISTANCE,
```

### Key Gotchas
1. **Enum ordering matters for serialization** — new entries MUST go at the end of the StatType enum to avoid shifting existing integer values. Existing saves store StatType as integers; inserting mid-enum would corrupt loaded data.
2. **MAGIC tag already exists** — SPELL is intentionally a new, separate constant. Do NOT repurpose MAGIC.
3. **No functional code changes** — no stat_calculator.gd, hero.gd, item_affixes.gd, or item changes in this phase. Constants only.
4. **Disabled affix stubs** (item_affixes.gd lines 247-255) reference `Tag.DOT` and `Tag.MAGIC` — those stay as-is; Phase 45 will update them.
5. **INT tag vs INT keyword** — in GDScript, `INT` is not a reserved word (unlike `int` lowercase), so `const INT = "INT"` is valid.

### Requirement Traceability

| Req ID | Requirement | Constants Delivered |
|--------|------------|-------------------|
| AFF-06 | STR/DEX/INT metadata tag constants | Tag.STR, Tag.DEX, Tag.INT |
| SPELL-01 | 3 new StatTypes for spell damage | StatType.FLAT_SPELL_DAMAGE, StatType.INCREASED_SPELL_DAMAGE, StatType.INCREASED_CAST_SPEED |
| SPELL-02 | SPELL tag constant | Tag.SPELL |

**Bonus constants (Phase 42 scope per CONTEXT — "all constants needed by later phases"):**
- Tag.CHAOS (needed by Phase 48)
- StatType.BLEED_DAMAGE, POISON_DAMAGE, BURN_DAMAGE (needed by Phase 48)
- StatType.CHAOS_RESISTANCE (needed by Phase 48)

## Validation Architecture

### What to Test
1. **Game launches without errors** — Godot will fail to parse tag.gd if any syntax error exists
2. **Existing integration test passes** — Run `tools/test/integration_test.gd` (30 tests across 9 groups). All tests exercise Tag.StatType and Tag constants extensively. Zero failures = zero regression.
3. **Constants are accessible** — Quick spot-check: `print(Tag.SPELL)` and `print(Tag.StatType.FLAT_SPELL_DAMAGE)` in integration test or _ready()
4. **Enum values stable** — Verify existing StatType entries retain their integer values (FLAT_DAMAGE=0 through ALL_RESISTANCE=18). New entries start at 19.

### Verification Method
- Run existing integration test (F6 on integration_test.tscn) — must show "ALL PASSED"
- No new test code needed for pure constant additions
- Optional: add a small test group to integration_test.gd that asserts new constants exist and have expected values

### Risk Assessment
**Very low risk.** This is a pure additive change to a single file:
- No behavior changes
- No existing code references the new constants
- No save format changes
- Enum additions at the end preserve serialization compatibility
- Single file modified: `autoloads/tag.gd`

## RESEARCH COMPLETE
