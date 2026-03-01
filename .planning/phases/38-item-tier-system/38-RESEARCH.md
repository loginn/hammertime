# Phase 38: Item Tier System - Research

**Researched:** 2026-03-01
**Domain:** GDScript item data model, loot drop weighting, affix construction pipeline
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **Item tier as fixed base property:** Item tier is an intrinsic, constant property of each base item type (Light Sword = always tier 8). Reuse the existing `Item.tier` field (item.gd:15) — no new field needed. All current base items are tier 8. Higher-tier (lower-number) items require new base item definitions (future content phase). `is_item_better()` in forge_view.gd already compares on `item.tier` — no change needed.

- **Drop tier weighting:** Area-weighted distribution: each tier has a "home" area range with bell-curve tapering. T8 peaks in early areas (Forest), becomes rare by area 50+, very rare beyond 75+. Higher tiers progressively appear at higher areas (threshold unlocks with smooth overlap). Best unlocked tier is NEVER guaranteed — always some RNG. At P0 (only tier 8 unlocked), all drops are tier 8 — weighting only kicks in at P1+. Distribution shape: normal-distribution-like curves centered at each tier's "home" area.

- **Affix tier constraint model — strict 4-per-band:**
  - Tier 8: affix tiers 29-32
  - Tier 7: affix tiers 25-32
  - Tier 6: affix tiers 21-32
  - Tier 5: affix tiers 17-32
  - Tier 4: affix tiers 13-32
  - Tier 3: affix tiers 9-32
  - Tier 2: affix tiers 5-32
  - Tier 1: affix tiers 1-32
  - Equal probability within the allowed range (no weighting toward worse affix tiers)
  - Only new mod additions respect item tier (Tack, Forge, Claw, Grand)
  - Tuning Hammer rerolls within the SAME affix tier that was originally rolled — unaffected by item tier

- **Item tier visibility:** Hidden at P0 — tier display only appears after first prestige (P1+). Display format: text label after item name — "Light Sword (Rare) — T5". Card/stats panel only — item slot list buttons do NOT show tier. No color coding or visual hierarchy for tier (just text).

### Claude's Discretion

- Exact bell curve parameters for drop tier weighting (sigma, centers per tier)
- How to wire tier constraint into add_prefix()/add_suffix() (implementation approach)
- Save format changes if needed (item.tier may already serialize)

### Deferred Ideas (OUT OF SCOPE)

- **Tier-specific base item variants**: Higher tiers need new base items with stronger base stats (e.g., "Mythic Sword" at tier 1 vs "Light Sword" at tier 8). Required for prestige to feel meaningful. Should be its own content phase.
- **Visual tier differentiation**: Color coding or icons per item tier — could enhance the system after base content exists.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| TIER-01 | Items have an item_tier field (1-8) that gates which affix tiers can roll | `Item.tier` already exists and serializes in `to_dict()`/`create_from_dict()`. No new field. All base item constructors already set `self.tier = 8`. The field is the item_tier; no rename needed. |
| TIER-02 | Item tier drops are weighted by area level (higher areas favor better tiers within prestige-unlocked range) | `get_random_item_base()` in gameplay_view.gd is the sole drop creation site. It currently ignores area level. Must gain access to `GameState.area_level` and `GameState.max_item_tier_unlocked` plus a weight-roll function. At P0, all items are tier 8 (only one tier unlocked) so the roll degenerates trivially. |
| TIER-03 | Item tier constrains affix tier range during crafting (tier 8 = affix tiers 29-32, tier 7 = 25-32, etc.) | `add_prefix()`/`add_suffix()` in item.gd call `Affixes.from_affix(template)`, which calls `Affix.new(... tier_range ...)`. The `tier_range` is read from the template (always `Vector2i(1,32)` post-Phase 37). The constraint must be applied at the `from_affix` call site by overriding the floor of tier_range based on `self.tier`. Tuning Hammer calls `affix.reroll()` directly and stays untouched. |
</phase_requirements>

## Summary

Phase 38 is a pure GDScript logic phase with no new external dependencies. The three changes are: (1) assign item tier during drop creation based on area-weighted probability, (2) constrain the affix tier floor in `add_prefix()`/`add_suffix()` based on the item's tier, and (3) show the tier label in the forge card after P1.

All data structures are already in place. `Item.tier` exists on every item and already serializes via `to_dict()` (the `"tier"` key is present in the save dict). `GameState.max_item_tier_unlocked` is already set by the prestige system. The only implementation decisions left to Claude's discretion are the bell-curve parameters for tier weighting and the exact call-site pattern for threading `self.tier` into `Affixes.from_affix()`.

**Primary recommendation:** Implement tier weighting as a static helper on `LootTable` (mirrors the existing `_calculate_currency_chance` pattern), modify `add_prefix()`/`add_suffix()` to compute a constrained `tier_range` floor before calling `Affixes.from_affix()`, and add a conditional tier suffix to `get_item_stats_text()` in forge_view.gd.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| GDScript / Godot 4.5 | 4.5 | All logic | Project architecture |
| `LootTable` (loot_table.gd) | existing | Drop probability helper | Existing pattern for area-gated, ramped chances |
| `Affixes` (item_affixes.gd) | existing | Affix template registry and clone factory | All affix construction goes through `from_affix()` |
| `GameState` autoload | existing | Authoritative prestige_level / max_item_tier_unlocked | Single source of truth, already used everywhere |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| GDScript `randf_range` / `randi_range` | built-in | RNG for tier rolls | Use for the weighted pick; no external RNG lib needed |
| `BiomeConfig` (biome_config.gd) | existing | Area-to-biome mapping | Biome boundaries (25/50/75) inform tier center choices |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Bell-curve via Gaussian rejection sampling | Simple weight-table lookup per tier | Weight table is deterministic and inspectable; Gaussian is cleaner math. Either works; weight-table is simpler to tune later. |
| Passing `item.tier` as parameter to `from_affix()` | Passing a pre-computed `Vector2i` floor to the clone call | Pre-computing the floor is simpler and avoids touching `Affix._init` signature. |

**Installation:** No new packages — pure GDScript.

## Architecture Patterns

### Recommended Project Structure

No new files needed. Touch exactly four existing files:

```
models/loot/loot_table.gd      # Add roll_item_tier() static helper
models/items/item.gd            # Modify add_prefix() / add_suffix() to apply tier floor
scenes/forge_view.gd            # Add tier label to get_item_stats_text()
scenes/gameplay_view.gd         # Pass area_level to roll_item_tier() in get_random_item_base()
```

### Pattern 1: Item Tier Drop Weighting

**What:** A static function on `LootTable` that takes `area_level` and `max_item_tier_unlocked` and returns a rolled item tier (integer 1-8). Uses bell-curve-like weights per tier, one tier per "home" area band.

**When to use:** Called once per dropped item in `gameplay_view.get_random_item_base()`.

**Tier home centers (aligned to biome boundaries from `biome_config.gd`):**

| Item Tier | Home area center | Tier unlocked at prestige |
|-----------|-----------------|--------------------------|
| 8 | 12 (mid-Forest, 1-24) | P0 |
| 7 | 37 (mid-Dark Forest, 25-49) | P1 |
| 6 | 62 (mid-Cursed Woods, 50-74) | P2 |
| 5 | 87 (Shadow Realm 75+, offset 12) | P3 |
| 4 | 112 | P4 |
| 3 | 137 | P5 |
| 2 | 162 | P6 |
| 1 | 187 | P7 |

**Approach (recommended — weight table, Claude's discretion on sigma):**

```gdscript
# Source: authored pattern matching LootTable._calculate_currency_chance style
static func roll_item_tier(area_level: int, max_tier_unlocked: int) -> int:
    # P0: only tier 8 available, skip weighting
    if max_tier_unlocked == 8:
        return 8

    # Build weight array for each tier from max_tier_unlocked down to 8
    # (lower number = better tier; max_tier_unlocked is numerically smallest allowed)
    var weights: Array[float] = []
    var tiers: Array[int] = []
    for t in range(8, max_tier_unlocked - 1, -1):  # 8, 7, 6, ... max_tier_unlocked
        var center: float = _tier_home_center(t)
        var sigma: float = 25.0  # tune: half-width of overlap region
        var dist: float = abs(float(area_level) - center)
        var w: float = exp(-0.5 * (dist / sigma) * (dist / sigma))
        weights.append(maxf(w, 0.01))  # floor prevents a tier from having 0 weight
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
    return tiers[-1]  # fallback

static func _tier_home_center(t: int) -> float:
    # T8=12, T7=37, T6=62, T5=87, T4=112, T3=137, T2=162, T1=187
    return 12.0 + float(8 - t) * 25.0
```

**Sigma = 25 provides smooth overlap:** at area 37 (T7 home), T8 still has weight ~exp(-0.5*(25/25)^2) = ~0.61 relative weight, so both tiers compete. At area 75 (Shadow Realm entry), T7 is at center=37 giving weight ~exp(-0.5*(38/25)^2) ≈ 0.05, meaning it's rare but possible — matching the spec ("becomes rare by area 50+, very rare beyond 75+"). Tune sigma after playtesting.

### Pattern 2: Affix Tier Floor Constraint in add_prefix() / add_suffix()

**What:** Before calling `Affixes.from_affix(template)`, compute the affix tier floor from `self.tier`, clone with an overridden `tier_range`, and pass the constrained range.

**Key insight from code audit:** `Affixes.from_affix()` passes `template.tier_range` directly to `Affix.new()`. The tier is rolled in `Affix._init` via `self.tier = randi_range(tier_range.x, tier_range.y)`. So the cleanest hook is to pass a modified `tier_range` to `from_affix()` — either by adding a parameter to `from_affix()`, or by computing the floor in `item.gd` and calling `Affix.new()` directly with the overridden range.

**Recommended approach (Claude's discretion): add optional `floor_override` parameter to `Affixes.from_affix()`:**

```gdscript
# In item_affixes.gd — add optional parameter
static func from_affix(template: Affix, affix_tier_floor: int = 1) -> Affix:
    var effective_range := Vector2i(
        maxi(template.tier_range.x, affix_tier_floor),
        template.tier_range.y
    )
    var affix_copy = Affix.new(
        template.affix_name,
        template.type,
        template.base_min,
        template.base_max,
        template.tags,
        template.stat_types,
        effective_range,
        template.base_dmg_min_lo,
        template.base_dmg_min_hi,
        template.base_dmg_max_lo,
        template.base_dmg_max_hi
    )
    return affix_copy
```

**Affix tier floor formula** (from CONTEXT.md constraint model):

```gdscript
# In item.gd add_prefix() / add_suffix() — before the from_affix call
func _get_affix_tier_floor() -> int:
    # item_tier 8 -> floor 29, item_tier 7 -> floor 25, ... item_tier 1 -> floor 1
    return (8 - self.tier) * 4 + 1
```

Verification: tier 8 → (8-8)*4+1 = 1... wait — re-reading spec: tier 8 = affix tiers 29-32 (floor=29). Formula should be: `floor = (self.tier - 1) * 4 + 1`.

| Item tier | Formula (tier-1)*4+1 | Expected floor |
|-----------|----------------------|----------------|
| 8 | 7*4+1 = 29 | 29 ✓ |
| 7 | 6*4+1 = 25 | 25 ✓ |
| 6 | 5*4+1 = 21 | 21 ✓ |
| 5 | 4*4+1 = 17 | 17 ✓ |
| 4 | 3*4+1 = 13 | 13 ✓ |
| 3 | 2*4+1 = 9 | 9 ✓ |
| 2 | 1*4+1 = 5 | 5 ✓ |
| 1 | 0*4+1 = 1 | 1 ✓ |

```gdscript
# Correct formula
func _get_affix_tier_floor() -> int:
    return (self.tier - 1) * 4 + 1
```

**In `add_prefix()` and `add_suffix()` (item.gd):**

```gdscript
var floor_val := _get_affix_tier_floor()
self.prefixes.append(Affixes.from_affix(new_prefix, floor_val))
```

**Tuning Hammer:** Calls `affix.reroll()` directly (item.gd line 197: `affix.reroll()`), which rolls within `self.min_value`/`self.max_value` — the already-fixed bounds from original construction. This is naturally unaffected by any changes to `add_prefix()`/`add_suffix()`.

### Pattern 3: Tier Label in get_item_stats_text()

**What:** Append " — T{n}" to the item name+rarity header line in `get_item_stats_text()` when `GameState.prestige_level >= 1`.

```gdscript
# In forge_view.gd get_item_stats_text()
var tier_label: String = ""
if GameState.prestige_level >= 1:
    tier_label = " — T%d" % item.tier
var stats_text: String = item.item_name + " (" + rarity_name + ")" + tier_label + "\n\n"
```

**Current line (forge_view.gd:850):**
```gdscript
var stats_text: String = item.item_name + " (" + rarity_name + ")" + "\n\n"
```

### Anti-Patterns to Avoid

- **Don't store affix floor on the item:** The constraint is applied at construction time. The `Affix` itself captures the constrained `tier_range` in its serialized `tier_range_x`/`tier_range_y` fields. No new save field needed on `Item`.
- **Don't call Tuning Hammer through add_prefix/add_suffix:** It calls `affix.reroll()` directly and must not receive the item tier floor — it rerolls within the existing rolled tier's range.
- **Don't change the `tier_range` on template affixes in `item_affixes.gd`:** Templates must remain `Vector2i(1,32)`. The override is applied only at clone time in `from_affix()`.
- **Don't filter by item tier in `get_random_item_base()`:** The item base type (LightSword, BasicArmor etc.) is independent of tier. Tier is assigned after the base type is picked, then set via `item.tier = rolled_tier`.
- **Don't add Forge/Runic hammer behavior:** Forge and Runic hammers transform rarity and re-roll ALL affixes. Their affix selection goes through `add_prefix()`/`add_suffix()`, so they will inherit the item tier constraint for free without any hammer-specific changes.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Weighted random selection | Custom weighted picker | GDScript built-in randf() with cumulative sum | No library needed; pattern is trivial in GDScript |
| Gaussian distribution | Import scipy/numpy equivalent | exp() approximation (weight table) | GDScript has no stats library; exp() is accurate enough for a game |
| Area-to-tier mapping | Biome switch statement | Formula: `12.0 + float(8 - t) * 25.0` | Deterministic, tunable with sigma |

**Key insight:** Every needed mechanism (area level, prestige tier ceiling, RNG, affix clone factory) already exists. This phase is plumbing between existing systems, not new infrastructure.

## Common Pitfalls

### Pitfall 1: item.tier Not Set After Drop

**What goes wrong:** `get_random_item_base()` creates an item via `random_type.new()` which sets `self.tier = 8` in each constructor. If the tier-rolling logic runs but its result is not written back to `item.tier`, the affix constraint later uses tier 8 regardless.

**Why it happens:** `random_type.new()` always hard-codes tier in `_init`. The roll result must explicitly overwrite it: `item.tier = rolled_tier`.

**How to avoid:** After `var item = random_type.new()`, always do `item.tier = LootTable.roll_item_tier(GameState.area_level, GameState.max_item_tier_unlocked)`.

**Warning signs:** All dropped items craft at affix tier floor 29 even at P1+ with high area levels.

### Pitfall 2: Tier Floor Applied to Tuning Hammer

**What goes wrong:** Tuning Hammer bypass is broken if `reroll()` is somehow rerouted through `add_prefix()`/`add_suffix()`.

**Why it happens:** Misunderstanding the call path. Confirmed audit: `item.reroll_affix(affix)` calls `affix.reroll()` (item.gd:197-199), which uses `self.min_value`/`self.max_value` — the already-fixed tier-scaled bounds stored on the Affix object. No change needed.

**How to avoid:** Only modify `add_prefix()` and `add_suffix()`. Do not touch `reroll_affix()` or `affix.reroll()`.

### Pitfall 3: P0 Tier Display Leaks

**What goes wrong:** Tier label shown at P0, breaking the "hidden until P1" decision.

**Why it happens:** Forgetting the prestige gate when modifying `get_item_stats_text()`.

**How to avoid:** Always check `GameState.prestige_level >= 1` before appending the tier suffix.

**Warning signs:** Tier label visible on a fresh save (P0) before any prestige.

### Pitfall 4: template.tier_range Mutated

**What goes wrong:** If `from_affix()` mutates the template's `tier_range` instead of reading it, subsequent clones from the same template get corrupted ranges.

**Why it happens:** Passing `effective_range` as a local but accidentally assigning to `template.tier_range`. GDScript Vector2i is a value type (not reference), so assignment is safe, but explicit construction `Vector2i(maxi(...), ...)` is clearest.

**How to avoid:** Always construct `effective_range` as a new `Vector2i`. Never assign to `template.tier_range`.

### Pitfall 5: Save Version Bump Needed

**What goes wrong:** Existing saves (SAVE_VERSION=4) have `item.tier` already serialized as 8 for all items. Loading them is fine. But if any new field were added, the version would need bumping and old saves would be deleted per the Phase 36 migration policy.

**Why it doesn't apply here:** `Item.tier` already serializes in `to_dict()` (line 64: `"tier": tier`). `Item.create_from_dict()` does NOT restore `item.tier` from save — it is not in the restore block. This is a gap: after loading a save, `item.tier` reverts to the value set in the constructor (`= 8` for all current base types). Since all current items are tier 8, this is currently harmless and will remain harmless through Phase 38 (all drops will still be tier 8 at P0 and will be re-rolled correctly on future drops). No SAVE_VERSION bump is needed for Phase 38.

**However:** After Phase 38 ships and players accumulate tier 7 items at P1+, a subsequent save MUST restore `item.tier` from the save dict. The planner should add restoring `item.tier` from `data.get("tier", 8)` inside `create_from_dict()` to ensure tier-7+ items survive a reload. This is a one-line fix in `item.gd`'s `create_from_dict()` without any version bump.

### Pitfall 6: Forge Hammer Rarity Upgrade Path

**What goes wrong:** Forge Hammer upgrades a Normal item to Rare, rolling 3 prefixes and 3 suffixes via `add_prefix()`/`add_suffix()`. If those calls already apply the item tier constraint, the tier gating works for free. No special Forge Hammer handling is needed.

**Why this is a non-issue:** Confirmed by reading the codebase — Forge Hammer (`forge_hammer.gd`) will call `add_prefix()`/`add_suffix()` on the item (standard path). The item's `self.tier` is set at drop time. The constraint applies automatically.

## Code Examples

### Complete add_prefix() modification (item.gd)

```gdscript
# Source: item.gd — add_prefix() with tier floor constraint applied
func add_prefix() -> bool:
    print("adding a prefix")
    if len(self.prefixes) >= max_prefixes():
        print("Cannot add more prefixes - at rarity limit (%d)" % max_prefixes())
        return false

    var valid_prefixes: Array[Affix] = []
    for prefix: Affix in ItemAffixes.prefixes:
        if has_valid_tag(prefix) and not self.is_affix_on_item(prefix):
            valid_prefixes.append(prefix)
    print("valid: ", valid_prefixes)

    if valid_prefixes.is_empty():
        print("No valid prefixes available for this item")
        return false

    var new_prefix: Affix = valid_prefixes.pick_random()
    if new_prefix != null:
        var floor_val: int = (self.tier - 1) * 4 + 1
        self.prefixes.append(Affixes.from_affix(new_prefix, floor_val))
        print("Added prefix: ", new_prefix.affix_name)
        return true

    return false
```

### get_random_item_base() modification (gameplay_view.gd)

```gdscript
# Source: gameplay_view.gd — item drop with tier roll
func get_random_item_base() -> Item:
    var item_types = [LightSword, BasicHelmet, BasicArmor, BasicBoots, BasicRing]
    var random_type = item_types[randi() % item_types.size()]
    var item = random_type.new()
    # Roll item tier from area-weighted distribution
    item.tier = LootTable.roll_item_tier(GameState.area_level, GameState.max_item_tier_unlocked)
    # Items always drop as Normal (0 affixes) — crafting is the sole source of mods
    return item
```

### Item.create_from_dict() tier restoration (item.gd)

```gdscript
# Source: item.gd — add tier restoration so tier-7+ items survive save/load
# After: item.rarity = int(data.get("rarity", 0)) as Rarity
item.tier = int(data.get("tier", 8))
```

### Tier label in get_item_stats_text() (forge_view.gd)

```gdscript
# Source: forge_view.gd — conditional tier display at P1+
var tier_label: String = ""
if GameState.prestige_level >= 1:
    tier_label = " — T%d" % item.tier
var stats_text: String = item.item_name + " (" + rarity_name + ")" + tier_label + "\n\n"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Item.tier field undefined / unused in crafting | Item.tier gates affix floor | Phase 38 | Affix quality becomes item-tier-gated |
| All drops same tier (8) | Area-weighted tier distribution | Phase 38 | Progression feel post-prestige |
| Affix tier_range always Vector2i(1,32) for all items | Floor raised to (item_tier-1)*4+1 | Phase 38 | Tier-8 items craft tier 29-32 affixes only |

**Deprecated/outdated:**

- `get_random_item_base()` ignoring area level: replaced with `LootTable.roll_item_tier()` call.
- `Affixes.from_affix(template)` with no tier override: gains optional second parameter.

## Open Questions

1. **Sigma / overlap tuning**
   - What we know: sigma=25 gives plausible overlap at biome boundaries; T8 is ~0.05 relative weight at area 75+ (Shadow Realm).
   - What's unclear: Whether sigma=25 feels right in actual play — T7 at area 37 may not be common enough vs T8 given floor weight=0.01.
   - Recommendation: Start with sigma=25, expose it as a const in LootTable so the planner can tune it without touching logic.

2. **`item.tier` restoration in create_from_dict() — timing**
   - What we know: Currently missing; all current base items are tier 8 so it's harmless today.
   - What's unclear: Whether this should be treated as a Phase 38 required fix or deferred.
   - Recommendation: Fix it in Phase 38 (one-line addition to `create_from_dict()`) since Phase 38 produces the first non-tier-8 items. Not fixing it would mean tier-7+ items revert to tier 8 on reload, breaking TIER-03 for saved items.

## Sources

### Primary (HIGH confidence)

- Direct source read: `models/items/item.gd` — confirmed `Item.tier` field at line 15, `to_dict()` serializes tier at line 64, `create_from_dict()` does NOT restore tier (gap identified).
- Direct source read: `autoloads/item_affixes.gd` — confirmed `from_affix()` passes `template.tier_range` to `Affix.new()`; all affixes use `Vector2i(1,32)` post-Phase 37.
- Direct source read: `models/affixes/affix.gd` — confirmed tier rolled in `_init` via `randi_range(tier_range.x, tier_range.y)` at line 52; `reroll()` uses pre-fixed `min_value`/`max_value` only.
- Direct source read: `models/loot/loot_table.gd` — confirmed `_calculate_currency_chance()` pattern and sqrt-ramp style; `roll_item_tier()` does not exist yet.
- Direct source read: `scenes/gameplay_view.gd` — confirmed `get_random_item_base()` at line 274 is the sole item drop creation site; ignores area level.
- Direct source read: `scenes/forge_view.gd` — confirmed `get_item_stats_text()` at line 843; header built at line 850; no prestige check currently.
- Direct source read: `autoloads/game_state.gd` — confirmed `max_item_tier_unlocked` at line 18, defaults to 8.
- Direct source read: `autoloads/prestige_manager.gd` — confirmed `ITEM_TIERS_BY_PRESTIGE = [8,7,6,5,4,3,2,1]` and that `max_item_tier_unlocked` is set correctly on prestige.
- Direct source read: `models/monsters/biome_config.gd` — confirmed biome boundaries: Forest 1-24, Dark Forest 25-49, Cursed Woods 50-74, Shadow Realm 75+.
- Direct source read: `autoloads/save_manager.gd` — confirmed `SAVE_VERSION=4`; `max_item_tier_unlocked` already in save dict; no version bump needed for Phase 38.
- Direct source read: `models/items/light_sword.gd` — confirmed `self.tier = 8` in constructor at line 11, proving all base items hard-code tier 8.

### Secondary (MEDIUM confidence)

- CONTEXT.md decision block — tier constraint formula cross-verified against code: (item_tier-1)*4+1 produces exact floors matching the spec table.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — all findings from direct source reads of the live codebase
- Architecture: HIGH — all integration points identified with specific line numbers; patterns extrapolated from existing analogous code (`_calculate_currency_chance`, `from_affix`)
- Pitfalls: HIGH — derived from reading actual serialization paths; the `create_from_dict()` gap is a concrete code fact, not speculation

**Research date:** 2026-03-01
**Valid until:** 2026-04-01 (stable Godot GDScript codebase)
