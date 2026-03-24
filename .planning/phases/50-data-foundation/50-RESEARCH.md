# Phase 50: Data Foundation - Research

**Researched:** 2026-03-24
**Domain:** GDScript Resource class, const registry pattern, GameEvents signals, GameState nullable fields
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** Archetypal titles only, no proper names. Format: "The [Role]" (e.g., "The Berserker")

**D-02:** Colors follow genre convention — STR red, DEX green, INT blue. All 3 subvariants within an archetype share the same color range.

**Draft Hero Roster:**

| ID | Archetype | Subvariant | Title | Color |
|----|-----------|-----------|-------|-------|
| str_hit | STR | Hit | The Berserker | Red |
| str_dot | STR | DoT | The Reaver | Red |
| str_elem | STR | Elemental | The Fire Knight | Red |
| dex_hit | DEX | Hit | The Assassin | Green |
| dex_dot | DEX | DoT | The Plague Hunter | Green |
| dex_elem | DEX | Elemental | The Frost Ranger | Green |
| int_hit | INT | Hit | The Arcanist | Blue |
| int_dot | INT | DoT | The Warlock | Blue |
| int_elem | INT | Elemental | The Storm Mage | Blue |

**D-03:** Two-layer bonus system — archetype channel bonus + subvariant specialty bonus, both multiplicative "more" modifiers.

**D-04:** Channel bonuses by archetype:
- STR: `attack_damage_more: 0.25`
- INT: `spell_damage_more: 0.25`
- DEX: `damage_more: 0.15`

**D-05:** Subvariant bonuses:
- Hit: `physical_damage_more: 0.25`
- DoT: `{type}_chance_more: 0.20, {type}_damage_more: 0.15` (STR=bleed, DEX=poison, INT=burn)
- Elemental: `{element}_damage_more: 0.25` (STR=fire, DEX=cold, INT=lightning)

**D-06:** All values are draft starting points — tuning happens in Phase 54.

**D-07:** INT heroes set `spell_user: true` on the archetype data. Hero archetype becomes the authority for spell mode, overriding weapon-driven logic.

**D-08:** The Arcanist (INT/hit) is a physical-spell fantasy — arcane force / gravity magic flavor.

**D-09:** Elemental subvariant element assignments are deliberately cross-archetype:
- STR elemental → fire
- DEX elemental → cold
- INT elemental → lightning

### Claude's Discretion
- Exact color hex values within the archetype color range
- Internal field naming conventions on the Resource
- Registry data structure (dict-of-dicts vs array with lookup)
- `generate_choices()` implementation details (random selection strategy)

### Deferred Ideas (OUT OF SCOPE)
- Stat integration (apply bonuses in Hero.update_stats()) — Phase 51
- Save format v8 with hero_archetype_id — Phase 52
- Selection UI (3-card overlay) — Phase 53
- Balance tuning of bonus magnitudes — Phase 54
- Prestige-level-gated hero pool — Future requirement
- Hero bonus scaling with prestige level — Future requirement
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HERO-01 | 9 hero roster — 3 archetypes (STR/DEX/INT) x 3 subvariants each (hit, DoT, elemental) | All 9 heroes defined in CONTEXT.md locked decisions. const registry pattern verified in `prestige_manager.gd` (PRESTIGE_COSTS, ITEM_TIERS_BY_PRESTIGE) and `item.gd` (ITEM_TYPE_STRINGS). |
| HERO-02 | HeroArchetype Resource with id, archetype, name, passive_bonuses dict, const registry in code | `Resource` base class pattern verified in 3 existing models. Flat dict registry pattern verified. Bonus key strings approach documented. |
| HERO-03 | Each hero has a title with color identity | Titles locked in D-01/D-02. Color approach (Color hex per archetype) follows existing `get_rarity_color()` pattern in `item.gd`. |
</phase_requirements>

## Summary

Phase 50 is a pure data foundation — no UI, no stat integration, no save changes. It creates one new file (`models/hero_archetype.gd`) and makes minimal additions to two autoloads (`game_events.gd`, `game_state.gd`). Everything follows established patterns already in the codebase.

The `HeroArchetype` Resource follows the exact same structure as `Item`, `Affix`, and `Currency` — it extends `Resource`, holds flat data fields, carries a const registry dict of all 9 hero definitions, and exposes a static factory/query method (`generate_choices()`). Bonus keys are plain strings intentionally separate from `Tag.StatType` to prevent mixing additive and multiplicative modifiers.

`GameState` gains one nullable field (`hero_archetype: HeroArchetype = null`) — this is not wiped in `_wipe_run_state()` at Phase 50; wipe behavior and save integration belong to later phases. `GameEvents` gains two signals following the same "one signal per event, minimal parameters" pattern already present in the file.

**Primary recommendation:** Create `HeroArchetype` as a flat `Resource` subclass with a `const REGISTRY: Dictionary` holding all 9 heroes. Use string keys for bonus values. Add two signals to `GameEvents`. Add nullable field to `GameState`. No other files change.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| GDScript built-ins | Godot 4.5 | All implementation | Project uses GDScript throughout; no addons needed |
| `Resource` base class | Godot 4.5 | HeroArchetype data model | Matches Item, Affix, Currency pattern already in codebase |

No external libraries needed. This phase is pure GDScript data definition.

**Installation:** None required.

## Architecture Patterns

### Recommended Project Structure

```
models/
├── hero_archetype.gd    # NEW — extends Resource, REGISTRY const, generate_choices()
├── hero.gd              # MODIFIED — add hero_archetype field (Phase 51 integration)
autoloads/
├── game_state.gd        # MODIFIED — add hero_archetype nullable field
├── game_events.gd       # MODIFIED — add two new signals
```

### Pattern 1: Flat Resource with Const Registry

**What:** A single `class_name HeroArchetype extends Resource` holds all hero data as plain fields. A `const REGISTRY: Dictionary` at class scope stores all 9 definitions indexed by hero id string.

**When to use:** Data-only objects where all instances are known at compile time and referenced by id. Matches `PrestigeManager.PRESTIGE_COSTS` and `PrestigeManager.ITEM_TIERS_BY_PRESTIGE` patterns.

**Example (verified against existing codebase patterns):**
```gdscript
# Source: models/hero_archetype.gd (new file)
class_name HeroArchetype extends Resource

enum Archetype { STR, DEX, INT }
enum Subvariant { HIT, DOT, ELEMENTAL }

var id: String
var archetype: Archetype
var subvariant: Subvariant
var title: String          # "The Berserker"
var color: Color
var spell_user: bool       # true for INT heroes only (D-07)
var passive_bonuses: Dictionary  # string keys → float values

const REGISTRY: Dictionary = {
    "str_hit": {
        "archetype": Archetype.STR,
        "subvariant": Subvariant.HIT,
        "title": "The Berserker",
        "color": Color("#C0392B"),
        "spell_user": false,
        "passive_bonuses": {
            "attack_damage_more": 0.25,
            "physical_damage_more": 0.25,
        },
    },
    # ... 8 more entries
}

static func from_id(hero_id: String) -> HeroArchetype:
    if hero_id not in REGISTRY:
        push_warning("HeroArchetype.from_id: unknown id '%s'" % hero_id)
        return null
    var data: Dictionary = REGISTRY[hero_id]
    var h := HeroArchetype.new()
    h.id = hero_id
    h.archetype = data["archetype"]
    h.subvariant = data["subvariant"]
    h.title = data["title"]
    h.color = data["color"]
    h.spell_user = data["spell_user"]
    h.passive_bonuses = data["passive_bonuses"].duplicate()
    return h

static func generate_choices() -> Array[HeroArchetype]:
    # Returns exactly 3: one per archetype, random subvariant each
    var by_archetype: Dictionary = {
        Archetype.STR: [],
        Archetype.DEX: [],
        Archetype.INT: [],
    }
    for hero_id in REGISTRY:
        var data: Dictionary = REGISTRY[hero_id]
        by_archetype[data["archetype"]].append(hero_id)
    var choices: Array[HeroArchetype] = []
    for arch in [Archetype.STR, Archetype.DEX, Archetype.INT]:
        var ids: Array = by_archetype[arch]
        choices.append(from_id(ids.pick_random()))
    return choices
```

### Pattern 2: Nullable GameState Field

**What:** Add a nullable field with `= null` default directly on `game_state.gd`. Does not touch `_wipe_run_state()` at this phase — that is Phase 52 behavior.

**When to use:** New run-scoped state that starts null and is populated by a downstream phase.

**Example (follows existing `game_state.gd` field convention):**
```gdscript
# In autoloads/game_state.gd — add after existing prestige_level fields
# Hero archetype -- nullable, null = classless Adventurer (SEL-02)
var hero_archetype: HeroArchetype = null
```

### Pattern 3: GameEvents Signal Addition

**What:** Append new signals at the bottom of `game_events.gd` with a phase comment, following the exact style used for every prior phase's signals.

**When to use:** Any new cross-scene event.

**Example (follows existing pattern in `game_events.gd`):**
```gdscript
# Hero archetype signals (Phase 50)
signal hero_selection_needed
signal hero_selected(archetype: HeroArchetype)
```

### Anti-Patterns to Avoid

- **Subclassing per archetype:** Do not create `StrHero extends HeroArchetype`. The flat registry pattern eliminates the need for inheritance and keeps all data in one inspectable place. Matches how Item subtypes work only where behavior differs, not data.
- **External data file (JSON/tres):** Do not load archetype data from a `.json` or `.tres` file. Project pattern is "data lives in code" (see `PRESTIGE_COSTS`, `ITEM_TYPE_STRINGS`). Code-defined data is version-controlled, grep-able, and requires no file I/O.
- **Mixing bonus keys with Tag.StatType:** Do not use `Tag.StatType` enum values as bonus keys. The enum is the additive system. Hero bonuses are multiplicative "more" modifiers. Keeping them as plain strings (`"fire_damage_more"`, not `Tag.StatType.FIRE_DAMAGE`) prevents accidental mixing downstream in Phase 51.
- **Storing full HeroArchetype in save:** Phase 50 adds only the `var hero_archetype` field to GameState. Serialization belongs to Phase 52. Do not add save logic in this phase.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Picking 1 random item per group | Custom shuffle logic | `.pick_random()` | Godot built-in on Array; already used in `item.gd add_prefix()`, `prestige_manager.gd _grant_random_tag_currency()` |
| Color per archetype | Color parse utility | `Color("#hex")` | Godot built-in; already used in `item.gd get_rarity_color()` |
| Typed array returns | Untyped Array | `Array[HeroArchetype]` | Godot 4 supports typed arrays on static methods; prefer for clarity |

**Key insight:** Every mechanism needed in this phase (random selection, const registry, nullable fields, signals with typed parameters) is a GDScript or Godot 4 built-in already used elsewhere in the codebase.

## Common Pitfalls

### Pitfall 1: Bonus Key Naming Collision with Future Phases

**What goes wrong:** Using generic key names like `"damage_more"` or `"fire_more"` without a consistent naming convention, then discovering Phase 51 expects specific keys when applying bonuses in `update_stats()`.

**Why it happens:** Phase 50 defines keys but Phase 51 consumes them. If the key schema is ambiguous, Phase 51 must guess or the planner must revisit Phase 50.

**How to avoid:** Establish the full bonus key schema now. Confirmed keys from CONTEXT.md decisions:
- Channel bonuses: `"attack_damage_more"`, `"spell_damage_more"`, `"damage_more"`
- Hit subvariant: `"physical_damage_more"`
- DoT subvariant: `"bleed_chance_more"`, `"bleed_damage_more"`, `"poison_chance_more"`, `"poison_damage_more"`, `"burn_chance_more"`, `"burn_damage_more"`
- Elemental subvariant: `"fire_damage_more"`, `"cold_damage_more"`, `"lightning_damage_more"`

**Warning signs:** If Phase 51 needs to invent keys not in the registry, Phase 50 schema is incomplete.

### Pitfall 2: REGISTRY Dict Entry Field Name Inconsistency

**What goes wrong:** Dict entries use different key names (e.g., `"archetype_type"` in one entry, `"archetype"` in another, or mixing `Archetype.STR` with the string `"STR"`).

**Why it happens:** Hand-writing 9 dictionary entries is error-prone. Copy-paste without disciplined review.

**How to avoid:** Define one entry completely, test `from_id()` on it, then copy that entry as a template for the remaining 8. Verify with an assertion or print in the integration test.

**Warning signs:** `from_id()` returns null for some heroes but not others.

### Pitfall 3: `generate_choices()` Returns Wrong Count or Missing Archetype

**What goes wrong:** Returns fewer than 3 items, or returns 2 STR heroes and 0 DEX heroes, because the by-archetype grouping is wrong.

**Why it happens:** Iterating REGISTRY and using incorrect field to group, or `pick_random()` called on empty array.

**How to avoid:** Assert count == 3 and each element has a distinct archetype. Add this to integration test group 36.

**Warning signs:** `Array.pick_random()` on an empty array returns null in Godot 4 (does not crash, returns null). Silence hides the bug.

### Pitfall 4: `hero_archetype` Field Added to `_wipe_run_state()`

**What goes wrong:** `_wipe_run_state()` is modified to set `hero_archetype = null`, which is correct for Phase 52 but causes a regression at Phase 50 — there is no selection UI yet, so wiping triggers a state the game cannot handle.

**Why it happens:** The developer anticipates Phase 52 behavior and jumps ahead.

**How to avoid:** Phase 50 only adds the field declaration. `_wipe_run_state()` is not touched until Phase 52.

**Warning signs:** Prestige during Phase 50 development unexpectedly clears hero_archetype.

### Pitfall 5: Signal Parameter Type Mismatch

**What goes wrong:** `hero_selected(archetype: HeroArchetype)` declared in `game_events.gd` but emitted with a Dictionary or String, causing a silent type warning or runtime error.

**Why it happens:** Phase 50 declares signals but no emitter exists yet. When Phase 53 wires up emission, the parameter type is re-guessed.

**How to avoid:** Document the declared signal signature clearly. Phase 53 must emit `GameEvents.hero_selected.emit(archetype_resource_object)` not `GameEvents.hero_selected.emit("str_hit")`.

**Warning signs:** Godot's "Signal parameter type mismatch" warning in output.

## Code Examples

Verified patterns from codebase analysis:

### Const Registry (from `prestige_manager.gd`)
```gdscript
# Source: autoloads/prestige_manager.gd lines 7-15
const PRESTIGE_COSTS: Dictionary = {
    1: { "forge": 100 },
    2: { "forge": 999999 },
    # ...
}
```

### Array `pick_random()` (from `prestige_manager.gd`)
```gdscript
# Source: autoloads/prestige_manager.gd line 77
var chosen: String = TAG_TYPES.pick_random()
```

### Color Hex Construction (from `item.gd`)
```gdscript
# Source: models/items/item.gd line 39
return Color("#6888F5")  # Soft blue, readable on dark
```

### Typed Signal with Parameter (from `game_events.gd`)
```gdscript
# Source: autoloads/game_events.gd line 4
signal equipment_changed(slot: String, item: Item)
```

### Nullable Field Pattern (from `game_state.gd`)
```gdscript
# Source: models/items/item.gd line 18
var custom_max_prefixes = null
# From game_state.gd initialize_fresh_game():
hero.equipped_items["weapon"] = null
```

### Complete HeroArchetype REGISTRY — All 9 Entries

This is the authoritative data derived from locked decisions D-01 through D-09:

```gdscript
const REGISTRY: Dictionary = {
    # STR heroes — Red — attack_damage_more: 0.25 channel bonus
    "str_hit": {
        "archetype": Archetype.STR,
        "subvariant": Subvariant.HIT,
        "title": "The Berserker",
        "color": Color("#C0392B"),   # deep red
        "spell_user": false,
        "passive_bonuses": {
            "attack_damage_more": 0.25,
            "physical_damage_more": 0.25,
        },
    },
    "str_dot": {
        "archetype": Archetype.STR,
        "subvariant": Subvariant.DOT,
        "title": "The Reaver",
        "color": Color("#E74C3C"),   # medium red
        "spell_user": false,
        "passive_bonuses": {
            "attack_damage_more": 0.25,
            "bleed_chance_more": 0.20,
            "bleed_damage_more": 0.15,
        },
    },
    "str_elem": {
        "archetype": Archetype.STR,
        "subvariant": Subvariant.ELEMENTAL,
        "title": "The Fire Knight",
        "color": Color("#FF6B6B"),   # bright red-orange
        "spell_user": false,
        "passive_bonuses": {
            "attack_damage_more": 0.25,
            "fire_damage_more": 0.25,
        },
    },
    # DEX heroes — Green — damage_more: 0.15 channel bonus
    "dex_hit": {
        "archetype": Archetype.DEX,
        "subvariant": Subvariant.HIT,
        "title": "The Assassin",
        "color": Color("#27AE60"),   # deep green
        "spell_user": false,
        "passive_bonuses": {
            "damage_more": 0.15,
            "physical_damage_more": 0.25,
        },
    },
    "dex_dot": {
        "archetype": Archetype.DEX,
        "subvariant": Subvariant.DOT,
        "title": "The Plague Hunter",
        "color": Color("#2ECC71"),   # medium green
        "spell_user": false,
        "passive_bonuses": {
            "damage_more": 0.15,
            "poison_chance_more": 0.20,
            "poison_damage_more": 0.15,
        },
    },
    "dex_elem": {
        "archetype": Archetype.DEX,
        "subvariant": Subvariant.ELEMENTAL,
        "title": "The Frost Ranger",
        "color": Color("#A8E6CF"),   # light mint green
        "spell_user": false,
        "passive_bonuses": {
            "damage_more": 0.15,
            "cold_damage_more": 0.25,
        },
    },
    # INT heroes — Blue — spell_damage_more: 0.25 channel bonus, spell_user: true
    "int_hit": {
        "archetype": Archetype.INT,
        "subvariant": Subvariant.HIT,
        "title": "The Arcanist",
        "color": Color("#2980B9"),   # deep blue
        "spell_user": true,
        "passive_bonuses": {
            "spell_damage_more": 0.25,
            "physical_damage_more": 0.25,  # D-08: arcane force / gravity flavor
        },
    },
    "int_dot": {
        "archetype": Archetype.INT,
        "subvariant": Subvariant.DOT,
        "title": "The Warlock",
        "color": Color("#3498DB"),   # medium blue
        "spell_user": true,
        "passive_bonuses": {
            "spell_damage_more": 0.25,
            "burn_chance_more": 0.20,
            "burn_damage_more": 0.15,
        },
    },
    "int_elem": {
        "archetype": Archetype.INT,
        "subvariant": Subvariant.ELEMENTAL,
        "title": "The Storm Mage",
        "color": Color("#7FB3D3"),   # light blue
        "spell_user": true,
        "passive_bonuses": {
            "spell_damage_more": 0.25,
            "lightning_damage_more": 0.25,
        },
    },
}
```

Note on hex choices: these are Claude's discretion (unlocked). They use three shades per hue to give subvariants slight visual distinction within the archetype color family while staying clearly in the STR=red, DEX=green, INT=blue convention.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hero is always the classless "Adventurer" | Hero gains archetype at first prestige; P0 = null | v1.9 (this milestone) | GameState.hero_archetype must be nullable |
| spell_user driven by equipped weapon type | spell_user driven by hero archetype (D-07) | v1.9 Phase 50 | INT heroes are always spell users regardless of weapon |

Note on `spell_user` authority: D-07 locks that "hero archetype becomes the authority for spell mode." In Phase 50 we add `spell_user: bool` to the archetype data. The actual override of weapon-driven logic in `hero.gd` belongs to Phase 51 stat integration. Phase 50 just stores the value.

## Validation Architecture

`workflow.nyquist_validation` is not set in `.planning/config.json`, so this section is included.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Godot integration test scene (custom, no external framework) |
| Config file | `tools/test/integration_test.gd` (scene run with F6 in editor) |
| Quick run command | Open Godot editor, run `tools/test/integration_test.gd` scene (F6) |
| Full suite command | Same — all 35 existing groups run in `_ready()` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HERO-01 | REGISTRY contains exactly 9 entries | unit | Group 36 in integration_test.gd | ❌ Wave 0 |
| HERO-01 | 3 STR, 3 DEX, 3 INT heroes in registry | unit | Group 36 in integration_test.gd | ❌ Wave 0 |
| HERO-02 | `from_id("str_hit")` returns correct fields | unit | Group 36 in integration_test.gd | ❌ Wave 0 |
| HERO-02 | `generate_choices()` returns exactly 3 heroes (1 per archetype) | unit | Group 36 in integration_test.gd | ❌ Wave 0 |
| HERO-02 | `generate_choices()` returns different subvariants across runs (probabilistic) | smoke | Group 36 in integration_test.gd | ❌ Wave 0 |
| HERO-03 | Each hero has non-empty title string | unit | Group 36 in integration_test.gd | ❌ Wave 0 |
| HERO-03 | STR heroes have red-family color, DEX green, INT blue | unit | Group 36 in integration_test.gd | ❌ Wave 0 |
| HERO-02 | `GameState.hero_archetype` is null on fresh game | unit | Group 36 in integration_test.gd | ❌ Wave 0 |
| HERO-02 | `GameEvents` has `hero_selection_needed` signal | unit | Group 36 in integration_test.gd | ❌ Wave 0 |
| HERO-02 | `GameEvents` has `hero_selected` signal | unit | Group 36 in integration_test.gd | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** Run integration_test.gd scene (F6), verify all groups pass
- **Per wave merge:** Same full scene run — all 35 existing + new Group 36
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `tools/test/integration_test.gd` — add `_group_36_hero_archetype_data()` covering all HERO-01/02/03 behaviors listed above

## Open Questions

1. **`is_spell_user` on GameState.hero vs HeroArchetype**
   - What we know: `hero.gd` currently has `var is_spell_user: bool = false` (line 63). D-07 says "hero archetype becomes the authority." Phase 50 adds `spell_user` to archetype data.
   - What's unclear: Does Phase 50 also update `hero.is_spell_user` to read from archetype, or does Phase 51 own that bridge?
   - Recommendation: Phase 50 adds `spell_user` to archetype data only. Phase 51 stat integration reads it and sets `hero.is_spell_user`. No behavior change at Phase 50.

2. **`generate_choices()` randomness in tests**
   - What we know: `pick_random()` is non-deterministic. A test asserting "returns different subvariants" is probabilistic.
   - What's unclear: Whether the test should call `generate_choices()` multiple times to verify diversity, or just verify count + 1-per-archetype guarantee.
   - Recommendation: Test the guarantee (3 results, 1 per archetype, all non-null). Do not test statistical distribution — that is over-specification.

## Sources

### Primary (HIGH confidence)
- Codebase analysis — `models/items/item.gd`, `models/hero.gd`, `autoloads/game_events.gd`, `autoloads/game_state.gd`, `autoloads/prestige_manager.gd`, `models/currencies/currency.gd` — direct read of all integration points
- `.planning/phases/50-data-foundation/50-CONTEXT.md` — locked decisions, bonus schema, hero roster
- `.planning/research/SUMMARY.md` — prior architecture research with confidence assessments
- `tools/test/integration_test.gd` — existing test pattern (35 groups) verified by inspection

### Secondary (MEDIUM confidence)
- `.planning/REQUIREMENTS.md` — HERO-01, HERO-02, HERO-03 requirement text

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies, all built-ins verified in codebase
- Architecture: HIGH — follows 4 existing Resource patterns; registry pattern verified in prestige_manager and item
- Hero data (9 entries): HIGH — directly derived from locked decisions in CONTEXT.md
- Pitfalls: HIGH — identified from direct code inspection of integration points
- Test pattern: HIGH — existing integration_test.gd pattern is clear and extensible

**Research date:** 2026-03-24
**Valid until:** 2026-06-24 (stable GDScript patterns; 90-day estimate)
