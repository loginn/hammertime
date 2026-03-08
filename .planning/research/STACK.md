# Stack Research

**Domain:** ARPG idle game -- hero archetype system with subvariants and prestige-based selection
**Researched:** 2026-03-09
**Confidence:** HIGH (all patterns verified against existing codebase architecture; no new engine features or external dependencies required)

---

## Context

This is a **subsequent milestone stack** for v1.9. The existing codebase has: Godot 4.5/GDScript, Resource-based data model (Hero, Item, Affix, Currency, MonsterPack), signal-based communication via GameEvents autoload, PrestigeManager with 7 prestige levels, StatCalculator for DPS/defense, CombatEngine with dual attack + spell timers, 21 item base types with STR/DEX/INT archetypes via `valid_tags`, and save format v7.

The v1.9 hero archetype system targets:
- Hero archetypes (STR/DEX/INT) with subvariants (DoT vs Hits, elemental affinities like Fire Wizard, Frost Warrior)
- Passive affinity bonuses (e.g., Fire Wizard gets +100% fire damage)
- Prestige hero selection: pick 1 from 3 random heroes (1 per archetype)
- Hero choice resets on each prestige

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|---|---|---|---|
| Godot Resource subclass (`HeroArchetype`) | 4.5 | Data definition for each archetype/subvariant | Follows existing pattern (Item, Affix, Currency all extend Resource). Serializable, no scene tree dependency, reference-counted. Already the project's data model pattern. |
| Dictionary-based modifier registry | N/A | Store passive bonuses as `{StatType: value}` pairs on HeroArchetype | Follows existing pattern: `PRESTIGE_COSTS` dict, `RARITY_LIMITS` dict, affix `stat_types` arrays. Avoids class hierarchy for modifiers. |
| StatCalculator extension (static methods) | N/A | Apply archetype bonuses in existing damage/defense pipeline | Single calculation source is established pattern. Adding a `apply_archetype_bonuses()` step keeps all math in one place. |
| GameState fields for archetype state | N/A | `hero_archetype_id: String` persisted alongside `prestige_level` | Follows existing pattern: prestige state lives on GameState, survives resets. |
| GameEvents signals for selection flow | N/A | `hero_selection_started`, `hero_selected` signals | Follows existing signal-based communication (7 combat signals, prestige_completed, etc.). |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---|---|---|---|
| None needed | -- | -- | The entire feature is implementable with built-in Godot 4.5 + GDScript. No addons, no plugins, no external dependencies. |

### Development Tools

| Tool | Purpose | Notes |
|---|---|---|
| Existing integration test suite (`integration_test.gd`) | Verify archetype bonuses apply correctly, selection pool works, save round-trips | Extend existing 35-group suite. Use `_simulate_prestige()` pattern for test isolation. |

---

## Recommended Patterns

### 1. HeroArchetype as Flat Resource (Not Inheritance)

**Pattern:** A single `HeroArchetype` Resource class with data fields, NOT a class hierarchy of `StrHero extends BaseHero extends Resource`.

```gdscript
class_name HeroArchetype extends Resource

var id: String                    # "fire_wizard", "frost_warrior", etc.
var display_name: String          # "Fire Wizard"
var archetype: String             # "STR", "DEX", "INT"
var subvariant: String            # "fire", "frost", "poison", "bleed", "hits", etc.
var passive_bonuses: Dictionary   # {StatType: float} e.g., {INCREASED_FIRE_DAMAGE: 100.0}
var description: String           # "100% more Fire Damage"
```

**Why:** The project already uses flat Resource subclasses for all data (21 item types, 41 affixes, currency types). A `HeroArchetype` is pure data -- it has no behavior that would benefit from polymorphism. The `passive_bonuses` dictionary replaces what would otherwise be a dozen overridden methods in a class hierarchy.

**Why NOT inheritance:** Every existing "type differentiation" in this codebase uses data, not inheritance. Items use `valid_tags` arrays, affixes use `stat_types` arrays, currencies use a template method but with a flat class per currency. A `FireWizard extends IntHero extends BaseHero` tree would be the first multi-level inheritance in the project and would fight the established architecture.

### 2. Archetype Registry as Const Dictionary

**Pattern:** A static registry of all archetypes, defined as a const on an autoload or the HeroArchetype class itself.

```gdscript
# Could live on a new HeroArchetypes autoload or as a static on HeroArchetype
const ARCHETYPES: Dictionary = {
    "fire_wizard": { "name": "Fire Wizard", "archetype": "INT", "subvariant": "fire",
        "bonuses": {Tag.StatType.INCREASED_SPELL_DAMAGE: 50.0}, "desc": "+50% Spell Fire Damage" },
    "frost_warrior": { "name": "Frost Warrior", "archetype": "STR", "subvariant": "frost",
        "bonuses": {Tag.StatType.INCREASED_DAMAGE: 50.0}, "desc": "+50% Cold Damage" },
    # ...
}
```

**Why:** Follows existing patterns: `PRESTIGE_COSTS`, `ITEM_TIERS_BY_PRESTIGE`, `TAG_TYPES`, `TIER_STATS` on item classes are all const dictionaries. No database, no JSON files, no external data loading. Data lives in code where it is version-controlled and type-checked.

### 3. Modifier Application Point

**Pattern:** Apply archetype bonuses as a final multiplier step in `Hero.update_stats()`, AFTER equipment-based calculation but BEFORE caching final values.

```gdscript
# In Hero.update_stats(), after existing calculate_* calls:
func update_stats() -> void:
    calculate_crit_stats()
    calculate_damage_ranges()
    calculate_spell_damage_ranges()
    calculate_dps()
    calculate_spell_dps()
    calculate_defense()
    calculate_dot_stats()
    _apply_archetype_bonuses()  # NEW: final pass
    current_energy_shield = float(total_energy_shield)
    health = max_health
```

**Why:** This is the least invasive integration point. Archetype bonuses are "more" multipliers (multiplicative with equipment), not additive stacking with affixes. Applying them after the equipment pipeline means:
- StatCalculator remains unchanged (it calculates equipment stats, not hero-level bonuses)
- Equipment DPS/defense calculations are correct in isolation (for item comparison tooltips)
- Archetype bonuses are a single, auditable step

**Why NOT inside StatCalculator:** StatCalculator is item-scoped (it takes affixes as input, not hero state). Archetype bonuses are hero-scoped. Mixing scopes would require passing archetype data through every StatCalculator call, coupling systems that are currently independent.

### 4. Passive Bonus Types (Keep It Simple)

**Pattern:** Archetype bonuses use the EXISTING `StatType` enum values as keys, with percentage values. No new bonus types needed for v1.9.

Sufficient bonus categories using existing StatTypes:

| Bonus Example | StatType Key | Effect |
|---|---|---|
| +100% Fire Damage | Custom key `"fire_damage_more"` | Multiplies fire damage ranges by 2.0 |
| +50% Spell Damage | Custom key `"spell_damage_more"` | Multiplies spell DPS by 1.5 |
| +30% Attack Speed | Custom key `"attack_speed_more"` | Multiplies attack timer speed by 1.3 |
| +50% Bleed Damage | Custom key `"bleed_damage_more"` | Multiplies bleed DPS by 1.5 |
| +25% All Resistance | Custom key `"all_resistance_flat"` | Adds 25 to all resistances |

**Important design decision:** Use string keys (not StatType enum) for archetype bonuses. Reason: archetype bonuses are "more" multipliers (multiplicative), while StatType values are used for "increased" (additive) stacking in StatCalculator. Using separate keys prevents accidental mixing of additive and multiplicative systems.

**Why NOT new StatType entries:** Adding `MORE_FIRE_DAMAGE`, `MORE_SPELL_DAMAGE`, etc. to the enum would pollute the affix system. No affix should ever roll a "more" multiplier -- those are reserved for hero-level bonuses. Separate namespaces keep the systems clean.

### 5. Random Selection Pool for Prestige

**Pattern:** On prestige, generate 3 candidates (1 per archetype) by filtering the ARCHETYPES registry and picking randomly within each archetype group.

```gdscript
func generate_hero_choices() -> Array[HeroArchetype]:
    var choices: Array[HeroArchetype] = []
    for arch in ["STR", "DEX", "INT"]:
        var pool = ARCHETYPES.values().filter(func(a): return a["archetype"] == arch)
        choices.append(_dict_to_archetype(pool.pick_random()))
    return choices
```

**Why:** `pick_random()` is already used in the codebase (`TAG_TYPES.pick_random()` in PrestigeManager). Filtering by archetype guarantees one choice per archetype, which is the design requirement. No weighted random needed -- uniform within archetype is sufficient for v1.9.

**Pool sizing consideration:** With 3 archetypes and ~3 subvariants each (DoT-focused, Hit-focused, elemental affinity), the pool is ~9 total heroes. Small enough that a const dictionary is the right storage; no need for procedural generation or database queries.

### 6. UI Pattern for Hero Selection Screen

**Pattern:** A modal overlay (like the existing prestige confirmation) that appears during `execute_prestige()`, presenting 3 hero cards. Selection triggers `hero_selected` signal and completes the prestige flow.

Key UI decisions:
- **3 VBoxContainer cards** in an HBoxContainer, each showing: hero name, archetype icon/label, passive bonus description, "Select" button.
- **No cancel** -- you must pick a hero to complete prestige. This matches the prestige design (irreversible action, already confirmed with two-click).
- **CanvasLayer-based** -- follows existing pattern where prestige_view uses explicit CanvasLayer visibility management.

**Why NOT a separate scene:** The hero selection is part of the prestige flow, not a standalone view. It should be a panel within `prestige_view.gd` or a popup triggered by `prestige_completed` signal. Adding a 5th tab would clutter the UI for a one-time-per-prestige interaction.

### 7. Save Format Integration

**Pattern:** Add `hero_archetype_id: String` to GameState (persisted, survives prestige). Save format bump to v8.

```gdscript
# In GameState
var hero_archetype_id: String = ""  # Empty = no archetype (P0)

# In SaveManager._build_save_data()
"hero_archetype_id": GameState.hero_archetype_id,

# In SaveManager.load_game()
GameState.hero_archetype_id = data.get("hero_archetype_id", "")
```

**Why:** Only the archetype ID needs persistence, not the full bonus dictionary. The registry reconstructs bonuses from the ID at load time. This follows the existing pattern where `prestige_level` is an int that indexes into `ITEM_TIERS_BY_PRESTIGE` -- minimal save footprint, data reconstructed from code.

**Migration:** `data.get("hero_archetype_id", "")` with empty string default means v7 saves load cleanly as "no archetype selected" (P0 state). No destructive migration needed.

### 8. Integration with CombatEngine

**Pattern:** CombatEngine reads archetype bonuses indirectly through Hero's cached stats. No direct CombatEngine changes needed for passive bonuses.

**Why:** CombatEngine already reads `GameState.hero.damage_ranges`, `GameState.hero.total_spell_dps`, etc. If `Hero._apply_archetype_bonuses()` modifies these cached values after equipment calculation, CombatEngine automatically uses the buffed values. Zero coupling between archetype system and combat system.

**Exception:** If an archetype bonus affects timer cadence (e.g., "+30% attack speed"), CombatEngine's `_get_hero_attack_speed()` needs to read the bonus. Options:
- A. Hero exposes `get_effective_attack_speed()` that includes archetype bonus. CombatEngine calls that instead of reading raw weapon speed. (Preferred -- keeps bonus logic on Hero.)
- B. CombatEngine queries archetype bonuses directly. (Rejected -- couples CombatEngine to archetype system.)

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|---|---|---|
| Flat `HeroArchetype` Resource with data dict | Class hierarchy (`FireWizard extends IntHero extends BaseHero`) | Never in this project. No behavior differences justify polymorphism. All archetypes do the same thing (apply passive bonuses) with different data. |
| Const dictionary registry | JSON data files loaded at runtime | If archetype count exceeds ~30 or if modding support is needed. At ~9 archetypes, code-defined data is simpler and type-safe. |
| Bonuses applied in `Hero.update_stats()` | Bonuses applied in `StatCalculator` | If archetype bonuses need to interact with individual affix calculations (e.g., "double the value of fire affixes"). Current design of flat multipliers doesn't need this. |
| String keys for bonus types | Reuse `StatType` enum | If bonuses were additive (same stacking as affixes). Since they are multiplicative "more" modifiers, separate keys prevent accidental mixing. |
| Selection UI as prestige_view panel | Separate hero_select_view as 5th tab | If hero selection happens outside prestige flow (e.g., between runs, or at any time). Current design ties selection to prestige events only. |
| `hero_archetype_id` on GameState | Full `HeroArchetype` Resource serialized in save | If archetype data changes between versions and you need to preserve the exact bonus values from the save. Since bonuses are code-defined and reconstructed from ID, the ID is sufficient. |
| Uniform random within archetype | Weighted random by prestige level | If higher prestige should unlock "better" subvariants. Current design has all subvariants equal in power (different, not better). Could add prestige-gated variants later. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|---|---|---|
| Multi-level class hierarchy for heroes | Only pattern in this codebase using deep inheritance is Currency (1 level: Currency -> ForgeHammer). A 3-level hero tree adds complexity with no behavior payoff. All archetypes apply bonuses identically. | Single `HeroArchetype` Resource with data dictionary |
| Godot's `class_name` registration for each subvariant | 9+ registered class names for pure data objects clutters the global namespace and autocompletion. Items justify this (21 types) because they have distinct constructors and stat tables. Archetypes are just data rows. | Factory function that constructs `HeroArchetype` from registry dict |
| Custom Resource `.tres` files for archetype definitions | Adds 9+ resource files that need manual editing in Godot editor. The project defines all game data in code (affixes, item stats, prestige costs). External resource files break this convention. | Const dictionary in GDScript |
| Separate "more" multiplier pipeline in StatCalculator | StatCalculator is item-scoped. Adding hero-level multipliers here couples two concerns and requires passing hero/archetype data through every calculation call. | Post-equipment multiplier step in `Hero.update_stats()` |
| New autoload for hero archetypes (at 9 variants) | The project has 6 autoloads. Adding one for 9 data rows is overkill. | Static const on `HeroArchetype` class, or extend `PrestigeManager` (it already handles prestige flow) |
| Enum for archetype IDs | Enums are integers in save files. If archetype order changes, saves break. | String IDs ("fire_wizard") -- human-readable, order-independent, matches existing `currency_type` pattern |
| Signals for bonus application | Bonuses are deterministic transforms on cached stats, not events. Signaling every stat recalculation adds overhead with no observer benefit. | Direct method call in `Hero.update_stats()` |
| Mutable archetype bonuses (scaling with level/gear) | Over-engineers v1.9. Passive bonuses should be fixed values that define archetype identity. Dynamic scaling muddies the "pick your identity" design. | Fixed const bonuses per archetype. Revisit if player feedback demands progression within archetype. |

---

## Stack Patterns by Variant

### If subvariants are purely elemental (Fire/Cold/Lightning per archetype):
- 9 total archetypes (3 archetypes x 3 elements)
- Bonus pattern: `{"element_damage_more": 100.0}` where element matches subvariant
- Selection pool: 3 choices (1 per archetype), element is random within archetype
- Simple, balanced, easy to reason about

### If subvariants include DoT vs Hits distinction:
- Up to 18 archetypes (3 archetypes x 3 elements x 2 styles)
- Bonus pattern: Hit variants get `{"element_damage_more": 100.0}`, DoT variants get `{"dot_type_damage_more": 100.0}`
- Selection pool: still 3 choices (1 per archetype), but internal pool is larger
- More complex, but `pick_random()` handles it identically

### If hero selection should feel "roguelike" (different each prestige):
- Larger pool with more varied bonuses (speed, crit, defense, etc.)
- Same architecture scales -- just more entries in the ARCHETYPES dictionary
- No structural changes needed, only more data rows

### If archetype should affect item drops (e.g., Fire Wizard finds more INT items):
- Add archetype-aware weighting to `LootTable.get_random_item_base()`
- LootTable reads `GameState.hero_archetype_id` and biases the archetype roll within each slot
- Minimal change: the slot-first-then-archetype pattern already has the archetype roll as a separate step

---

## Sources

- Existing codebase analysis (models/hero.gd, autoloads/prestige_manager.gd, autoloads/game_state.gd, models/stats/stat_calculator.gd, autoloads/tag.gd, autoloads/game_events.gd, autoloads/save_manager.gd, models/items/wand.gd)
- Previous stack research (`.planning/research/STACK.md` v1.8 -- patterns for item archetypes, StatType extensions, serialization)
- Godot 4.5 Resource documentation -- `Resource` as data container pattern
- ARPG design conventions (PoE/Last Epoch class systems: ascendancy as passive bonus tree, not behavior inheritance)
- PROJECT.md v1.9 milestone specification

---
*Stack research for: hero archetype system*
*Researched: 2026-03-09*
