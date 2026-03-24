# Phase 51: Stat Integration - Research

**Researched:** 2026-03-25
**Domain:** GDScript Hero.update_stats() pipeline, multiplicative modifier injection, is_spell_user refactor, SaveManager/settings_view cleanup
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01 (Phase 50):** Archetypal titles only. Nine heroes: str_hit/str_dot/str_elem/dex_hit/dex_dot/dex_elem/int_hit/int_dot/int_elem.

**D-02 (Phase 50):** STR=red, DEX=green, INT=blue. All 9 entries already in `HeroArchetype.REGISTRY`.

**D-03 (Phase 50):** Two-layer bonus system — channel bonus + subvariant specialty bonus, both multiplicative "more" modifiers.

**D-04 (Phase 50):** Channel bonuses: STR `attack_damage_more: 0.25`, INT `spell_damage_more: 0.25`, DEX `damage_more: 0.15`.

**D-05 (Phase 50):** Subvariant bonuses: Hit `physical_damage_more: 0.25`; DoT `{type}_chance_more: 0.20, {type}_damage_more: 0.15`; Elemental `{element}_damage_more: 0.25`.

**D-01 (Phase 51):** Remove `settings_view.gd` spell mode toggle entirely. No manual override exists.

**D-02 (Phase 51):** `is_spell_user` is derived from archetype at runtime: if `hero_archetype != null`, `is_spell_user = hero_archetype.spell_user`. If null, `is_spell_user = false` always.

**D-03 (Phase 51):** Classless Adventurer (P0, no archetype) is always attack mode. Spell weapons calculate spell stats but CombatEngine never starts spell timer for classless hero.

**D-04 (Phase 51):** Stop writing `is_spell_user` to save data. On load, derive from archetype if present. Old saves with `is_spell_user` field are ignored (value derived, not restored). Full save format cleanup deferred to Phase 52.

**D-05 (Phase 51):** Element-specific bonuses (`fire_damage_more`, etc.) apply per-element to damage_ranges min/max AFTER equipment aggregation in `calculate_damage_ranges()` and `calculate_spell_damage_ranges()`.

**D-06 (Phase 51):** Channel bonuses (`attack_damage_more`, `spell_damage_more`) apply to ALL elements in their respective range dictionaries after equipment aggregation.

**D-07 (Phase 51):** DEX `damage_more` (general) applies to BOTH attack damage_ranges AND spell_damage_ranges.

**D-08 (Phase 51):** DoT bonuses (`bleed_chance_more`, `bleed_damage_more`, etc.) apply multiplicatively on final totals after affix aggregation in `calculate_dot_stats()`. Chance bonuses multiply total_X_chance; damage bonuses add to total_X_damage_pct (converted to percentage).

**D-09 (Phase 51):** `physical_damage_more` applies to the "physical" element in damage_ranges, same as element-specific bonuses.

**D-10 (Phase 51):** When `GameState.hero_archetype == null`, skip all bonus application silently. Single null check, no logging, no placeholder values.

**D-11 (Phase 51):** No UI changes in Phase 51. All UI deferred to Phase 53.

### Claude's Discretion
- Exact placement of bonus application code within each calculate_* function (inline vs helper)
- Whether to cache the passive_bonuses dictionary or read from GameState.hero_archetype each call
- Integration test structure for verifying bonus math

### Deferred Ideas (OUT OF SCOPE)
- Save format v8 with hero_archetype_id — Phase 52
- Hero name/title display in UI — Phase 53
- Bonus magnitude indicators in stat panel — Phase 53
- Balance tuning of bonus values — Phase 54
- Prestige-level-gated hero pool — Future requirement
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PASS-01 | Multiplicative "more" bonuses applied after gear stacking in Hero.update_stats() | Six bonus key types identified; three injection points in hero.gd verified (calculate_damage_ranges, calculate_spell_damage_ranges, calculate_dot_stats). Null guard pattern confirmed for classless hero. |
| PASS-02 | DoT subvariant heroes get +20% bleed/poison/burn chance bonus to bootstrap viability | `bleed_chance_more: 0.20`, `poison_chance_more: 0.20`, `burn_chance_more: 0.20` already in REGISTRY. Injection point is `calculate_dot_stats()` after affix aggregation loop. Math: `total_bleed_chance *= (1.0 + 0.20)`. |
</phase_requirements>

## Summary

Phase 51 is a focused wiring phase: all archetype data exists (Phase 50 shipped `HeroArchetype.REGISTRY` and `GameState.hero_archetype`), and the Hero stat calculation pipeline is well-understood. The work is injecting bonus multiplication at three specific points in `hero.gd` and removing the obsolete `is_spell_user` management from `settings_view.gd` and `save_manager.gd`.

The injection model is straightforward: after each `calculate_*()` function aggregates gear stats, a single null-guarded block reads `GameState.hero_archetype.passive_bonuses` and applies matching multipliers. The bonus key naming convention established in Phase 50 (`attack_damage_more`, `fire_damage_more`, `bleed_chance_more`, etc.) maps directly to known dictionary keys in damage_ranges / spell_damage_ranges / DoT totals. No new data structures are needed.

The `is_spell_user` refactor is equally mechanical: change the property from a stored `var` to a derived read by checking `GameState.hero_archetype` at each use site. Remove the toggle from `settings_view.gd`, stop writing `is_spell_user` to the save dict in `save_manager.gd`, and keep the load path reading it for backward compatibility (but ignore the value).

**Primary recommendation:** Inject bonus multipliers inline at the end of each `calculate_*()` function. Read `GameState.hero_archetype.passive_bonuses` directly each call (no caching needed — `update_stats()` is only called on equip events, not per-frame). Convert `is_spell_user` to a derived getter or inline derivation.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| GDScript built-ins | Godot 4.5 | All implementation | No new dependencies needed; pure logic changes to existing files |

No external libraries required. This phase modifies four existing files: `models/hero.gd`, `scenes/settings_view.gd`, `autoloads/save_manager.gd`, and adds a test group to `tools/test/integration_test.gd`.

**Installation:** None.

## Architecture Patterns

### Files Changed

```
models/
└── hero.gd                          # PRIMARY: bonus injection + is_spell_user derivation
scenes/
└── settings_view.gd                 # REMOVE: spell_mode_toggle, _on_spell_mode_toggled, reset_state line
autoloads/
└── save_manager.gd                  # STOP writing is_spell_user; KEEP reading it (ignored, backward compat)
tools/test/
└── integration_test.gd              # ADD: _group_37_stat_integration() tests
```

### Pattern 1: Bonus Injection Block (inline at end of calculate_* function)

**What:** After the gear aggregation loop in each `calculate_*()` function, a null-guarded block reads `passive_bonuses` from `GameState.hero_archetype` and multiplies matching stats.

**When to use:** Once per stat calculation function, after all affix accumulation is complete.

**Example (calculate_damage_ranges injection):**
```gdscript
# Source: models/hero.gd — append after weapon+ring loop in calculate_damage_ranges()
# Apply archetype passive bonuses (Phase 51)
if GameState.hero_archetype != null:
    var bonuses: Dictionary = GameState.hero_archetype.passive_bonuses
    for element in damage_ranges:
        var element_key: String = element + "_damage_more"
        if bonuses.has(element_key):
            damage_ranges[element]["min"] *= (1.0 + bonuses[element_key])
            damage_ranges[element]["max"] *= (1.0 + bonuses[element_key])
    # Channel bonus: attack_damage_more scales all attack elements
    if bonuses.has("attack_damage_more"):
        for element in damage_ranges:
            damage_ranges[element]["min"] *= (1.0 + bonuses["attack_damage_more"])
            damage_ranges[element]["max"] *= (1.0 + bonuses["attack_damage_more"])
    # General damage bonus: scales all attack elements (DEX)
    if bonuses.has("damage_more"):
        for element in damage_ranges:
            damage_ranges[element]["min"] *= (1.0 + bonuses["damage_more"])
            damage_ranges[element]["max"] *= (1.0 + bonuses["damage_more"])
```

**Example (calculate_spell_damage_ranges injection):**
```gdscript
# Source: models/hero.gd — append after weapon+ring loop in calculate_spell_damage_ranges()
# Apply archetype passive bonuses (Phase 51)
if GameState.hero_archetype != null:
    var bonuses: Dictionary = GameState.hero_archetype.passive_bonuses
    # Element-specific: spell_damage_ranges keys are "spell", "spell_fire", "spell_lightning"
    # Element map: "fire" key in bonuses → "spell_fire" in spell_damage_ranges
    var spell_element_map: Dictionary = {
        "fire": "spell_fire",
        "lightning": "spell_lightning",
        "physical": "spell",
    }
    for bonus_elem in spell_element_map:
        var bonus_key: String = bonus_elem + "_damage_more"
        var spell_key: String = spell_element_map[bonus_elem]
        if bonuses.has(bonus_key) and spell_key in spell_damage_ranges:
            spell_damage_ranges[spell_key]["min"] *= (1.0 + bonuses[bonus_key])
            spell_damage_ranges[spell_key]["max"] *= (1.0 + bonuses[bonus_key])
    # Channel bonus: spell_damage_more scales all spell elements
    if bonuses.has("spell_damage_more"):
        for element in spell_damage_ranges:
            spell_damage_ranges[element]["min"] *= (1.0 + bonuses["spell_damage_more"])
            spell_damage_ranges[element]["max"] *= (1.0 + bonuses["spell_damage_more"])
    # General damage bonus: scales all spell elements (DEX)
    if bonuses.has("damage_more"):
        for element in spell_damage_ranges:
            spell_damage_ranges[element]["min"] *= (1.0 + bonuses["damage_more"])
            spell_damage_ranges[element]["max"] *= (1.0 + bonuses["damage_more"])
```

**Example (calculate_dot_stats injection — after affix loop, before calculate_dot_dps()):**
```gdscript
# Source: models/hero.gd — append after the for-slot affix loop in calculate_dot_stats()
# Apply archetype passive bonuses (Phase 51)
if GameState.hero_archetype != null:
    var bonuses: Dictionary = GameState.hero_archetype.passive_bonuses
    if bonuses.has("bleed_chance_more"):
        total_bleed_chance *= (1.0 + bonuses["bleed_chance_more"])
    if bonuses.has("bleed_damage_more"):
        total_bleed_damage_pct += bonuses["bleed_damage_more"] * 100.0
    if bonuses.has("poison_chance_more"):
        total_poison_chance *= (1.0 + bonuses["poison_chance_more"])
    if bonuses.has("poison_damage_more"):
        total_poison_damage_pct += bonuses["poison_damage_more"] * 100.0
    if bonuses.has("burn_chance_more"):
        total_burn_chance *= (1.0 + bonuses["burn_chance_more"])
    if bonuses.has("burn_damage_more"):
        total_burn_damage_pct += bonuses["burn_damage_more"] * 100.0
# Then: calculate_dot_dps()  ← no change needed
```

### Pattern 2: is_spell_user Derivation

**What:** `Hero.is_spell_user` is no longer a stored property with an independent value. It is derived from `GameState.hero_archetype` wherever it is read.

**Implementation options (Claude's discretion):**

Option A — Inline derivation in `update_stats()`, set once per recalculation:
```gdscript
# At top of update_stats() (before calculate_crit_stats())
is_spell_user = GameState.hero_archetype.spell_user if GameState.hero_archetype != null else false
```
This preserves all existing read sites (`calculate_dot_dps()` line 580, `CombatEngine`) without change.

Option B — Change the `var` declaration to provide a derived getter:
GDScript 4 does not support computed property getters on `var` declarations in the same way C# properties work. Option A is simpler and matches the codebase pattern.

**Recommendation: Option A.** Add one line at the top of `update_stats()`. All existing `if not is_spell_user:` checks in `calculate_dot_dps()` and elsewhere continue to work unchanged.

### Pattern 3: settings_view.gd Cleanup

**What:** Remove the spell mode toggle added as a dev tool. Three changes:

1. Remove `var spell_mode_toggle: CheckButton` field declaration (line 13)
2. Remove toggle creation block in `_ready()` (lines 25-30)
3. Remove `_on_spell_mode_toggled()` handler (lines 79-82)
4. Remove the `spell_mode_toggle.button_pressed = GameState.hero.is_spell_user` line from `reset_state()` (line 101)

**Nothing else in settings_view.gd changes.** The save/export/import/new-game buttons are unaffected.

### Pattern 4: save_manager.gd Cleanup

**What:** Two targeted changes only.

1. In `_build_save_data()` (line 112): **Remove** `"is_spell_user": GameState.hero.is_spell_user,` from the returned dictionary.
2. In `_restore_state()` (line 163): **Keep** `GameState.hero.is_spell_user = bool(data.get("is_spell_user", false))` but change it to be a no-op derivation note — OR simply delete the line entirely since `update_stats()` (called two lines later at line 166) will now set `is_spell_user` from archetype.

**Recommendation:** Delete the restore line. Since `update_stats()` is called at line 166 and now sets `is_spell_user` via Option A above, restoring the saved value is redundant and may override the correct derived value. Old saves with the field are harmlessly ignored by simply not reading it.

### Anti-Patterns to Avoid

- **Modifying StatCalculator:** Do not touch `utils/stat_calculator.gd`. It is a pure function operating on affixes. Hero-level bonuses apply post-aggregation in `hero.gd`, not inside StatCalculator. (Confirmed: PITFALLS.md Pitfall 2 and Technical Debt table both document this.)
- **Double-counting with INCREASED_DAMAGE affixes:** Element bonuses apply to damage_ranges AFTER StatCalculator has already applied all additive gear modifiers. The flow is: `StatCalculator.calculate_damage_range()` → returns ranges with gear mods applied → hero.gd multiplies ranges by archetype bonus. No overlap with additive stacking.
- **Caching passive_bonuses as a field on Hero:** Bonuses are read directly from `GameState.hero_archetype` each `update_stats()` call. `update_stats()` runs only on equip events (not per-frame), so reading a dictionary reference each call costs nothing meaningful. Caching adds state that can become stale if archetype changes.
- **Applying bonuses inside the equipment loop:** Bonuses must be applied AFTER all equipment is aggregated. Applying per-weapon or per-ring would be incorrect — they must scale the final sum.
- **Storing is_spell_user in save AND deriving from archetype:** This creates two authorities. Once Phase 51 ships, `is_spell_user` is derived-only. Removing it from the save dict is the correct cleanup even before Phase 52's full save format bump.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Bonus key routing | Custom router class or match statement per key | Dictionary `.has()` loop | `passive_bonuses` keys ARE the routing — `"fire_damage_more"` maps directly to `damage_ranges["fire"]`. Simple string concatenation (`element + "_damage_more"`) handles all element cases. |
| Per-element multiplier tracking | Accumulator float per element | Multiply in-place on min/max | damage_ranges is already a mutable dictionary; multiply and move on. No intermediate storage needed. |
| Spell element key mapping | Separate REGISTRY or lookup constant | Inline local Dictionary | Only 3 spell elements need mapping (fire→spell_fire, lightning→spell_lightning, physical→spell). Define locally in the function. |

**Key insight:** The passive_bonuses dictionary keys were designed in Phase 50 to match exactly what Phase 51 needs. String concatenation (`element + "_damage_more"`) plus `.has()` checks is all the routing required.

## Bonus Key → Application Point Reference

This table is the authoritative mapping that the planner needs to create correct tasks:

| Bonus Key | Applied In | Targets | Math |
|-----------|-----------|---------|------|
| `attack_damage_more` | `calculate_damage_ranges()` | ALL elements in damage_ranges | `range.min *= (1 + value)` |
| `spell_damage_more` | `calculate_spell_damage_ranges()` | ALL elements in spell_damage_ranges | `range.min *= (1 + value)` |
| `damage_more` | BOTH `calculate_damage_ranges()` AND `calculate_spell_damage_ranges()` | ALL elements in both dicts | `range.min *= (1 + value)` |
| `physical_damage_more` | `calculate_damage_ranges()` | `damage_ranges["physical"]` only | `range.min *= (1 + value)` |
| `fire_damage_more` | `calculate_damage_ranges()` | `damage_ranges["fire"]` only | `range.min *= (1 + value)` |
| `cold_damage_more` | `calculate_damage_ranges()` | `damage_ranges["cold"]` only | `range.min *= (1 + value)` |
| `lightning_damage_more` | `calculate_damage_ranges()` | `damage_ranges["lightning"]` only | `range.min *= (1 + value)` |
| `bleed_chance_more` | `calculate_dot_stats()` | `total_bleed_chance` | `total *= (1 + value)` |
| `bleed_damage_more` | `calculate_dot_stats()` | `total_bleed_damage_pct` | `total += value * 100.0` |
| `poison_chance_more` | `calculate_dot_stats()` | `total_poison_chance` | `total *= (1 + value)` |
| `poison_damage_more` | `calculate_dot_stats()` | `total_poison_damage_pct` | `total += value * 100.0` |
| `burn_chance_more` | `calculate_dot_stats()` | `total_burn_chance` | `total *= (1 + value)` |
| `burn_damage_more` | `calculate_dot_stats()` | `total_burn_damage_pct` | `total += value * 100.0` |

**Notes on spell element mapping:**
- `spell_damage_ranges` keys are `"spell"`, `"spell_fire"`, `"spell_lightning"` (not plain element names)
- `physical_damage_more` in the context of INT/hit (Arcanist) applies to `damage_ranges["physical"]` — this is the "arcane force/gravity" fantasy (D-09 Phase 50). It does NOT apply to `spell_damage_ranges["spell"]` because the Arcanist's physical_damage_more is a hit-channel bonus, not a spell-channel bonus.
- `fire_damage_more` from STR elemental (Fire Knight) applies to `damage_ranges["fire"]` (attack channel). There is no spell variant of fire_damage_more in the current registry.

## Common Pitfalls

### Pitfall 1: Applying Bonuses Inside StatCalculator

**What goes wrong:** Modifying `StatCalculator.calculate_damage_range()` to accept a hero bonus parameter. This couples a pure utility to hero state and breaks the architectural separation that allows testing gear math in isolation.

**Why it happens:** It seems like "the right place" to apply damage multipliers since that's where other damage multipliers live.

**How to avoid:** Never touch `stat_calculator.gd` in this phase. All bonus application is in `hero.gd` after StatCalculator returns. PITFALLS.md explicitly calls this out as "never acceptable" debt.

**Warning signs:** Any import of `HeroArchetype` or reference to `GameState` inside `stat_calculator.gd`.

### Pitfall 2: Bonus Order Causes Double-Scaling

**What goes wrong:** `attack_damage_more` scales ALL elements in damage_ranges. If `physical_damage_more` is ALSO present (as it is for str_hit), naive double-loop application multiplies "physical" by both bonuses — which is correct (two separate bonuses), but the order matters: applying element-specific BEFORE channel-wide is cleaner and avoids confusion.

**Why it happens:** When iterating passive_bonuses to apply them, applying a channel-wide bonus first then element-specific causes the element-specific to stack ON TOP of the channel-wide. That's correct behavior (they are independent multipliers) but can surprise a reviewer who expects a single multiplication.

**How to avoid:** Apply element-specific bonuses first, then channel bonuses. Both are independent multipliers — if str_hit has `attack_damage_more: 0.25` and `physical_damage_more: 0.25`, physical damage is `base * 1.25 * 1.25 = base * 1.5625`. This is intentional by design (two distinct bonuses stack multiplicatively).

**Warning signs:** Integration test shows physical damage getting only 1.25x when it should be 1.5625x (element-specific wasn't applied), or 1.5625x on all elements (channel bonus accidentally applied element-specific bonus width).

### Pitfall 3: calculate_dot_dps() Uses is_spell_user That is Not Yet Derived

**What goes wrong:** `calculate_dot_dps()` (line 580) branches on `if not is_spell_user`. If `is_spell_user` is derived at the top of `update_stats()` (Pattern 2), the order `calculate_dot_stats() → calculate_dot_dps()` inside `update_stats()` must come AFTER the derivation line. Currently `update_stats()` calls `calculate_crit_stats()` first. The derivation must be inserted before `calculate_crit_stats()`, or at least before `calculate_dot_stats()` — first line of `update_stats()` is safest.

**Why it happens:** The derivation line is added mid-function without checking what downstream functions read `is_spell_user`.

**How to avoid:** Add the `is_spell_user` derivation as the FIRST line of `update_stats()`.

**Warning signs:** Classless hero (null archetype) being treated as spell_user=true because an old saved value is still present on the Hero object from a previous session.

### Pitfall 4: spell_damage_more Bonus Applied to Attack Channel (or vice versa)

**What goes wrong:** `damage_more` (DEX general bonus) correctly applies to both channels. `spell_damage_more` must only apply to spell_damage_ranges, not to damage_ranges. `attack_damage_more` must only apply to damage_ranges, not spell_damage_ranges. If a copy-paste error puts `spell_damage_more` check in `calculate_damage_ranges()`, INT heroes get double bonus.

**Why it happens:** The three injection blocks (attack ranges, spell ranges, DoT) are structurally similar. Copy-paste between them is likely.

**How to avoid:** Each block checks ONLY its applicable keys. See the Bonus Key table above as the authoritative routing reference. Integration test must verify an INT hero with `spell_damage_more` does NOT receive attack damage bonus.

**Warning signs:** The Arcanist shows boosted attack DPS but should show only boosted spell DPS.

### Pitfall 5: settings_view.gd Retains Dead spell_mode_toggle Reference

**What goes wrong:** Deleting the `_on_spell_mode_toggled()` function but leaving the `spell_mode_toggle` variable or the signal connection causes a Godot warning or runtime error when `reset_state()` tries to set `spell_mode_toggle.button_pressed`.

**Why it happens:** Incremental deletion misses one of the four removal sites (variable declaration, creation in `_ready()`, signal handler function, reset_state reference).

**How to avoid:** All four sites must be removed together. See Pattern 3 above for the complete list.

**Warning signs:** Godot prints "Attempt to call function 'button_pressed' on a null instance" or similar.

### Pitfall 6: DoT Damage Bonus Conversion Error (Percentage vs Decimal)

**What goes wrong:** `total_bleed_damage_pct` is a percentage value (e.g., 30.0 = 30%). The archetype bonus is stored as a decimal (e.g., `bleed_damage_more: 0.15`). Adding 0.15 directly to total_bleed_damage_pct would give only 0.15% more bleed damage instead of 15%.

**Why it happens:** The bonus dict uses 0.0–1.0 float fractions, but the DoT pct fields use 0–100 scale.

**How to avoid:** Conversion: `total_bleed_damage_pct += bonuses["bleed_damage_more"] * 100.0`. This is documented in D-08.

**Warning signs:** DoT DPS barely changes after archetype is set despite bleed_damage_more being 0.15.

## Code Examples

### Verified: update_stats() Current Order

```gdscript
# Source: models/hero.gd lines 119-130
func update_stats() -> void:
    calculate_crit_stats()
    calculate_damage_ranges()
    calculate_spell_damage_ranges()
    calculate_dps()
    calculate_spell_dps()
    calculate_defense()
    calculate_dot_stats()          # <-- calls calculate_dot_dps() internally
    current_energy_shield = float(total_energy_shield)
    health = max_health
```

After Phase 51, `is_spell_user` derivation is inserted as the first statement.

### Verified: damage_ranges Dictionary Structure

```gdscript
# Source: models/hero.gd lines 44-49
var damage_ranges: Dictionary = {
    "physical": {"min": 0.0, "max": 0.0},
    "fire": {"min": 0.0, "max": 0.0},
    "cold": {"min": 0.0, "max": 0.0},
    "lightning": {"min": 0.0, "max": 0.0},
}
```

Keys exactly match `element + "_damage_more"` concatenation pattern.

### Verified: spell_damage_ranges Dictionary Structure

```gdscript
# Source: models/hero.gd lines 53-57
var spell_damage_ranges: Dictionary = {
    "spell": {"min": 0.0, "max": 0.0},
    "spell_fire": {"min": 0.0, "max": 0.0},
    "spell_lightning": {"min": 0.0, "max": 0.0},
}
```

Keys do NOT match direct concatenation — requires the explicit mapping dict (fire→spell_fire, lightning→spell_lightning, physical→spell).

### Verified: DoT stat variables and their scale

```gdscript
# Source: models/hero.gd lines 23-36
var total_bleed_chance: float = 0.0      # 0.0 to 100.0 (percentage)
var total_bleed_damage_pct: float = 0.0  # 0.0 to 100.0 (percentage)
var total_poison_chance: float = 0.0     # same
var total_poison_damage_pct: float = 0.0 # same
var total_burn_chance: float = 0.0       # same
var total_burn_damage_pct: float = 0.0   # same
```

Bonus dict values are 0.0–1.0 decimals. Multiply by 100.0 before adding to _pct fields.

### Verified: save_manager.gd Current Write and Read of is_spell_user

```gdscript
# Source: autoloads/save_manager.gd line 112 (_build_save_data) — TO REMOVE:
"is_spell_user": GameState.hero.is_spell_user,

# Source: autoloads/save_manager.gd line 163 (_restore_state) — TO REMOVE:
GameState.hero.is_spell_user = bool(data.get("is_spell_user", false))
```

### Verified: settings_view.gd Spell Toggle — All Four Removal Sites

```gdscript
# Line 13 — field declaration — REMOVE:
var spell_mode_toggle: CheckButton

# Lines 25-30 — creation in _ready() — REMOVE:
spell_mode_toggle = CheckButton.new()
spell_mode_toggle.text = "Spell Mode (Dev)"
spell_mode_toggle.button_pressed = GameState.hero.is_spell_user
spell_mode_toggle.toggled.connect(_on_spell_mode_toggled)
add_child(spell_mode_toggle)
spell_mode_toggle.position = Vector2(10, 300)

# Lines 79-82 — handler function — REMOVE:
func _on_spell_mode_toggled(toggled_on: bool) -> void:
    GameState.hero.is_spell_user = toggled_on
    GameState.hero.update_stats()

# Line 101 — reset_state() reference — REMOVE:
spell_mode_toggle.button_pressed = GameState.hero.is_spell_user
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `is_spell_user` stored on Hero, toggled manually via dev button | `is_spell_user` derived from `GameState.hero_archetype.spell_user` each `update_stats()` | Phase 51 | INT heroes always spell mode; STR/DEX always attack mode; dev toggle removed |
| No archetype bonuses — all heroes identical | Archetype passive bonuses multiply damage after equipment aggregation | Phase 51 | STR/INT/DEX heroes diverge in DPS output with same gear |
| `is_spell_user` written to save file | `is_spell_user` omitted from save; derived on load from archetype | Phase 51 | Save file slightly smaller; old saves backward-compatible (derived value overwrites stale field) |

**Deprecated/outdated after Phase 51:**
- `settings_view.gd` spell mode toggle: removed; replaced by archetype authority
- `save_manager.gd` `is_spell_user` save field: removed from write; read silently ignored

## Validation Architecture

`workflow.nyquist_validation` is not set in `.planning/config.json` — section included.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Godot integration test scene (custom, no external framework) |
| Config file | `tools/test/integration_test.gd` |
| Quick run command | Open Godot editor, run `tools/test/integration_test.gd` scene (F6) |
| Full suite command | Same — all 36 existing groups + new Group 37 run in `_ready()` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PASS-01 | STR hero with gear shows higher attack DPS than classless hero with same gear | unit | Group 37 in integration_test.gd | ❌ Wave 0 |
| PASS-01 | INT hero with gear shows higher spell DPS than classless hero with same gear | unit | Group 37 in integration_test.gd | ❌ Wave 0 |
| PASS-01 | Null archetype (classless) produces zero bonus — DPS unchanged from baseline | unit | Group 37 in integration_test.gd | ❌ Wave 0 |
| PASS-01 | Fire Knight (str_elem) shows fire DPS boost; cold DPS unchanged | unit | Group 37 in integration_test.gd | ❌ Wave 0 |
| PASS-01 | attack_damage_more does NOT apply to spell_damage_ranges | unit | Group 37 in integration_test.gd | ❌ Wave 0 |
| PASS-01 | spell_damage_more does NOT apply to damage_ranges | unit | Group 37 in integration_test.gd | ❌ Wave 0 |
| PASS-01 | damage_more (DEX) applies to BOTH channels | unit | Group 37 in integration_test.gd | ❌ Wave 0 |
| PASS-02 | Reaver (str_dot) total_bleed_chance increases by 20% after update_stats | unit | Group 37 in integration_test.gd | ❌ Wave 0 |
| PASS-02 | Reaver total_bleed_damage_pct increases by 15 percentage points after update_stats | unit | Group 37 in integration_test.gd | ❌ Wave 0 |
| PASS-02 | Plague Hunter (dex_dot) total_poison_chance increases by 20% | unit | Group 37 in integration_test.gd | ❌ Wave 0 |
| PASS-02 | Warlock (int_dot) total_burn_chance increases by 20% | unit | Group 37 in integration_test.gd | ❌ Wave 0 |
| D-02 | is_spell_user true for INT archetype hero, false for STR/DEX | unit | Group 37 in integration_test.gd | ❌ Wave 0 |
| D-02 | is_spell_user false when hero_archetype is null | unit | Group 37 in integration_test.gd | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** Run integration_test.gd (F6), verify all groups pass
- **Per wave merge:** Same full run — all 36 existing + Group 37
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `tools/test/integration_test.gd` — add `_group_37_stat_integration()` to `_ready()` call list and implement the function covering all PASS-01, PASS-02, and D-02 behaviors above

**Test setup pattern** (follows existing `_group_33_dot_dps_calculation()` pattern):
```gdscript
func _group_37_stat_integration() -> void:
    print("\n--- Group 37: Stat Integration (Phase 51) ---")
    _reset_fresh()
    # Equip a weapon with known fire damage to get nonzero damage_ranges["fire"]
    # Set GameState.hero_archetype = HeroArchetype.from_id("str_elem")  # Fire Knight
    # Call GameState.hero.update_stats()
    # Assert fire range is 1.25x * 1.25x (attack_damage_more * fire_damage_more) of baseline
    # Repeat for other bonus keys
```

## Open Questions

1. **physical_damage_more on Arcanist (int_hit) and spell_damage_ranges**
   - What we know: The Arcanist has `spell_damage_more: 0.25` (INT channel) and `physical_damage_more: 0.25` (Hit subvariant). D-08 says "arcane force/gravity" — physical damage through spells.
   - What's unclear: Does `physical_damage_more` apply to `spell_damage_ranges["spell"]` (the "physical" spell element)? The spell damage ranges have a `"spell"` key which represents the base physical-spell element.
   - Recommendation: Yes — for the spell channel, `physical_damage_more` maps to `spell_damage_ranges["spell"]` via the element map (physical→spell). This is consistent with D-05 ("physical_damage_more applies to 'physical' element") and the element map already handles this mapping. The planner should treat this as resolved and include `"physical": "spell"` in the spell_element_map.

2. **DEX general damage_more and the Frost Ranger (dex_elem) cold damage interaction**
   - What we know: Frost Ranger has `damage_more: 0.15` (DEX channel) and `cold_damage_more: 0.25` (elemental subvariant). Both apply to attack damage_ranges.
   - What's unclear: Application order — element-specific first, then channel-wide, means cold gets `1.25 * 1.15 = 1.4375x`. Channel-wide first, then element-specific, gives the same result because multiplication is commutative.
   - Recommendation: Order does not matter mathematically; pick element-specific first for readability. Document the expected Frost Ranger cold multiplier as 1.4375x in the test assertions.

## Sources

### Primary (HIGH confidence)
- Direct codebase read: `models/hero.gd` (full file, all calculate_* functions and update_stats order)
- Direct codebase read: `models/hero_archetype.gd` (full REGISTRY, all 9 entries, all bonus keys)
- Direct codebase read: `autoloads/game_state.gd` (hero_archetype field confirmed, _wipe_run_state scope)
- Direct codebase read: `scenes/settings_view.gd` (spell_mode_toggle, all four removal sites identified)
- Direct codebase read: `autoloads/save_manager.gd` (is_spell_user write at line 112, restore at line 163)
- Direct codebase read: `tools/test/integration_test.gd` (group pattern, existing group 36 structure)
- `.planning/phases/51-stat-integration/51-CONTEXT.md` — all locked decisions for Phase 51
- `.planning/phases/50-data-foundation/50-CONTEXT.md` — bonus schema (D-03 through D-09)
- `.planning/research/PITFALLS.md` — Pitfall 2 (injection stage), Pitfall 6 (DoT interaction), Pitfall 7 (is_spell_user authority)

### Secondary (MEDIUM confidence)
- `.planning/REQUIREMENTS.md` — PASS-01, PASS-02 requirement text
- `.planning/phases/50-data-foundation/50-RESEARCH.md` — bonus key schema, confirmed all 13 keys

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; pure GDScript modifications to known files
- Architecture (injection points): HIGH — all four target functions read directly; code verified
- Bonus key routing: HIGH — derived from REGISTRY data already in codebase + locked decisions
- is_spell_user refactor: HIGH — all four file changes identified and verified by code read
- Pitfalls: HIGH — grounded in direct code inspection of all changed functions
- Test structure: HIGH — existing group 36 pattern is the direct template for group 37

**Research date:** 2026-03-25
**Valid until:** 2026-06-25 (stable GDScript patterns; no external dependencies to go stale)
