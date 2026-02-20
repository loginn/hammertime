# Stack Research: Meta-Progression, Item Tiers, Affix Tier Expansion, Tag-Targeted Currencies

**Domain:** Godot 4.5 Idle ARPG — Adding prestige reset loop, item tier system (1-8), affix tier expansion (8 → 32), and tag-targeted crafting currencies to existing v1.6 codebase
**Researched:** 2026-02-20
**Confidence:** HIGH (all patterns verified against existing codebase and Godot 4.5 API)

---

## Context

This is a **subsequent milestone stack** for v1.7. Godot 4.5, GDScript, mobile renderer, Resource-based data model, template-method Currency pattern, and the v2 save format (per-slot arrays) are already validated and in production.

The four feature areas map cleanly to existing architectural extension points:

| Feature | Primary Extension Point |
|---------|------------------------|
| Prestige system | `GameState` (new meta fields) + `SaveManager` (v3 migration) + new `prestige_triggered` signal |
| Item tier gating (1-8) | `Item.tier` already exists, `LootTable` already has area scaling, need `item_tier` → affix tier filter |
| Affix tier expansion (8 → 32) | `Affix.tier_range` Vector2i already configurable per affix, `ItemAffixes` templates just need wider ranges |
| Tag-targeted currencies | New `Currency` subclasses using same template method, filter `ItemAffixes.prefixes` by tag before `pick_random()` |

---

## Recommended Stack

### Core Technologies (Unchanged)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Godot Engine | 4.5 | Game engine | Already in production. No version change needed. |
| GDScript | 4.5 | Scripting language | All patterns below use existing built-in methods: `Array.any()`, `Array.filter()`, `pick_random()`, lambdas. |
| Resource system | 4.5 | Data model (`Item`, `Affix`, `Hero`, `Currency`) | No changes to the resource class hierarchy. Extend fields, not classes. |
| JSON via `JSON.stringify` / `JSON.parse_string` | 4.5 | Save file format | Already in `SaveManager`. Prestige meta-state adds new top-level keys. Version bumps from 2 → 3. |

---

### GDScript Patterns for Prestige System

#### 1. Two-Layer State Model in GameState

Prestige creates two distinct categories of state that must never mix during reset. The cleanest GDScript pattern is grouping them explicitly with comments, not separate classes.

```gdscript
# game_state.gd — ADD these fields alongside existing state

# ─── META STATE ───────────────────────────────────────────────
# Persists across ALL prestige resets. Never cleared by do_prestige().
var prestige_level: int = 0         # 0 = not yet prestiged, max 7
var prestige_unlocks: Dictionary = {}  # {prestige_level: bool} — gating flags

# ─── RUN STATE ────────────────────────────────────────────────
# Everything below is cleared by do_prestige() (same as initialize_fresh_game).
# var hero: Hero                     ← existing
# var currency_counts: Dictionary    ← existing
# var crafting_inventory: Dictionary ← existing
# var max_unlocked_level: int        ← existing
# var area_level: int                ← existing
```

**Why Dictionary for prestige_unlocks, not just checking `prestige_level >= N`:** Future unlock types (new hammer types, new biomes) can be added as keys without schema changes. `prestige_unlocks.get("tag_targeted_currencies", false)` is readable and explicit at each gate.

**Why NOT a separate PrestigeMeta Resource class:** A Resource would require a separate serialization path alongside the existing JSON `_build_save_data()`. The project deliberately chose JSON over ResourceSaver specifically to enable export strings (`HT1:base64:md5`). Adding a second save format creates two sources of truth. A few extra Dictionary keys in the existing save structure is the right call.

#### 2. Prestige Reset Function

The reset is a surgical variant of `initialize_fresh_game()`. It PRESERVES meta state, then calls `initialize_fresh_game()` to wipe run state.

```gdscript
# game_state.gd — ADD

func do_prestige() -> void:
    # 1. Snapshot meta state (will survive reset)
    var new_level := prestige_level + 1
    # 2. Wipe all run state (resets hero, currencies, inventory, area)
    initialize_fresh_game()
    # 3. Restore meta state with incremented level
    prestige_level = new_level
    prestige_unlocks = _compute_unlocks(prestige_level)
    # 4. Emit for UI and SaveManager
    GameEvents.prestige_triggered.emit(prestige_level)


func _compute_unlocks(level: int) -> Dictionary:
    return {
        "tag_targeted_currencies": level >= 1,
        "item_tier_2": level >= 1,
        "item_tier_3": level >= 2,
        # ... extend per design
    }
```

**Why snapshot-before-wipe, not snapshot-after:** `initialize_fresh_game()` overwrites `hero`, `currency_counts`, etc. If meta fields lived in those same variables, snapshotting after would lose them. The explicit snapshot-increment-wipe-restore sequence is self-documenting and immune to ordering bugs.

**Why `initialize_fresh_game()` as the reset primitive:** It already correctly resets ALL run state (hero, currencies, inventory, area level, starter weapon). Calling it from `do_prestige()` means there is exactly ONE place that knows what "fresh run state" means. If a new run-state field is added later, it only needs to be added to `initialize_fresh_game()` and prestige reset gets it for free.

#### 3. Prestige Cost Validation

Prestige is triggered by spending currencies (design: specific currency costs per prestige level). The cost check must happen before `do_prestige()` is called.

```gdscript
# game_state.gd — ADD

const PRESTIGE_COSTS: Array[Dictionary] = [
    # Level 0 → 1
    {"runic": 50, "forge": 20, "grand": 5},
    # Level 1 → 2
    {"runic": 100, "forge": 50, "grand": 15, "claw": 5},
    # ... up to 6 entries for 7 prestige levels
]

func can_prestige() -> bool:
    if prestige_level >= 7:
        return false
    var cost: Dictionary = PRESTIGE_COSTS[prestige_level]
    for currency_type in cost:
        if currency_counts.get(currency_type, 0) < cost[currency_type]:
            return false
    return true


func spend_prestige_cost() -> bool:
    if not can_prestige():
        return false
    var cost: Dictionary = PRESTIGE_COSTS[prestige_level]
    for currency_type in cost:
        currency_counts[currency_type] -= cost[currency_type]
    return true
```

**Why `Array[Dictionary]` for costs indexed by prestige_level:** Indexing by `prestige_level` gives O(1) lookup. An array naturally enforces the 7-level cap (index out of bounds = bug, not silent wrong behavior). Costs are data, not logic — keep them as constants next to the functions that use them.

---

### GDScript Patterns for Save Format v3 Migration

#### 4. Save Version Bump: 2 → 3

The existing `_migrate_save()` function already has the version-gated chain pattern. Add one more step.

```gdscript
# save_manager.gd — MODIFY

const SAVE_VERSION = 3   # was 2

func _migrate_save(data: Dictionary) -> Dictionary:
    var saved_version: int = int(data.get("version", 1))

    if saved_version < SAVE_VERSION:
        print("SaveManager: Migrating save from v%d to v%d" % [saved_version, SAVE_VERSION])

    if saved_version < 2:
        data = _migrate_v1_to_v2(data)

    if saved_version < 3:
        data = _migrate_v2_to_v3(data)   # ADD

    data["version"] = SAVE_VERSION
    return data


func _migrate_v2_to_v3(data: Dictionary) -> Dictionary:
    # v3 adds prestige meta-state keys with safe defaults
    # Items and currencies are unchanged — this is additive only
    if not data.has("prestige_level"):
        data["prestige_level"] = 0
    if not data.has("prestige_unlocks"):
        data["prestige_unlocks"] = {}
    return data
```

**Why additive migration only for v2 → v3:** Prestige meta-state is entirely NEW keys. No existing keys change format. The migration just injects defaults for old saves — any v2 save loaded as v3 will correctly show prestige_level 0 (first-time player). This is the safest possible migration.

**Why not a separate meta-save file:** Two save files means two failure modes (one corrupted, one not), two export strings, and two import paths. The existing `HT1:base64:md5` export string already encodes the entire game state — keeping prestige meta in the same JSON envelope keeps export/import working with zero changes.

#### 5. Save and Restore for Prestige Meta-State

```gdscript
# save_manager.gd — MODIFY _build_save_data() to add prestige fields:

return {
    "version": SAVE_VERSION,
    "timestamp": Time.get_unix_time_from_system(),
    "hero_equipment": hero_equipment,
    "currencies": GameState.currency_counts.duplicate(),
    "crafting_inventory": crafting_inv,
    "crafting_bench_type": GameState.crafting_bench_type,
    "max_unlocked_level": GameState.max_unlocked_level,
    "area_level": GameState.area_level,
    # NEW:
    "prestige_level": GameState.prestige_level,
    "prestige_unlocks": GameState.prestige_unlocks.duplicate(),
}


# save_manager.gd — MODIFY _restore_state() to add:

GameState.prestige_level = int(data.get("prestige_level", 0))
var saved_unlocks: Dictionary = data.get("prestige_unlocks", {})
GameState.prestige_unlocks = {}
for key in saved_unlocks:
    GameState.prestige_unlocks[key] = bool(saved_unlocks[key])
```

**Why `duplicate()` on prestige_unlocks when saving:** `Dictionary.duplicate()` is already used for `currency_counts`. Without it, the JSON serializer gets a reference to the live dictionary. If any code mutates it between `_build_save_data()` and `JSON.stringify()`, the save is wrong. Shallow duplicate is sufficient because all values are primitives (bool).

---

### GDScript Patterns for Item Tier Gating

#### 6. Item Tier as a First-Class Drop Parameter

Items already have `var tier: int` in `item.gd`. The new requirement is that `tier` is set at **drop time** based on area level and unlocked prestige, not at item construction time.

```gdscript
# loot_table.gd or pack_generator.gd — ADD

## Returns the item tier for a drop at the given area level, given the max unlocked item tier.
## Weighted toward lower tiers (common) with higher tiers increasingly rare.
## Uses a triangular distribution capped at max_unlocked_tier.
static func roll_item_tier(area_level: int, max_unlocked_tier: int) -> int:
    # Weight array: tier 1 has highest weight, each tier halves the probability
    # This keeps lower-tier items common while making high-tier feel like finds
    var weights: Array[float] = []
    for t in range(1, max_unlocked_tier + 1):
        # Scale weight by area: at higher areas, higher tiers become more likely
        var area_scale := clampf(float(area_level) / (t * 12.0), 0.1, 1.0)
        weights.append(area_scale)

    # Weighted pick (same pattern as roll_element in PackGenerator)
    var total := 0.0
    for w in weights:
        total += w
    var roll := randf() * total
    var accumulated := 0.0
    for i in range(weights.size()):
        accumulated += weights[i]
        if roll < accumulated:
            return i + 1   # tier is 1-indexed
    return max_unlocked_tier
```

**Why triangular/scaled weights vs uniform:** Uniform would give equal probability to tier 1 and tier 8. That destroys the find-feel of high-tier items. The area-scaled weight gives players the right feeling: at low areas, almost all drops are tier 1-2; at high areas, tier 5-6 become common; tier 7-8 always feel rare.

**Why NOT store item tier in BiomeConfig:** BiomeConfig knows about monster element distribution, not item economics. Mixing loot tier math into biome config violates separation of concerns. LootTable already owns all drop probability logic.

#### 7. Item Tier → Affix Tier Range Mapping

The item tier gates which affix tiers can roll on the item. The mapping is a pure lookup — no logic, just a table.

```gdscript
# item.gd or a new utility — ADD as const

## Maps item tier (1-8) to the permitted affix tier range.
## Affix tier 1 is the BEST (highest values), tier 32 is weakest.
## Item tier 1 allows only low-value affixes (tiers 17-32).
## Item tier 8 allows the full range (tiers 1-32).
const ITEM_TIER_AFFIX_RANGE: Dictionary = {
    1: Vector2i(17, 32),   # Only weak affixes
    2: Vector2i(13, 28),
    3: Vector2i(9, 24),
    4: Vector2i(7, 20),
    5: Vector2i(5, 16),
    6: Vector2i(3, 12),
    7: Vector2i(2, 8),
    8: Vector2i(1, 4),     # Only strong affixes
}

## Returns the affix tier range permitted for an item of the given tier.
static func get_affix_tier_range(item_tier: int) -> Vector2i:
    return ITEM_TIER_AFFIX_RANGE.get(item_tier, Vector2i(1, 32))
```

**Why a Dictionary lookup rather than a formula:** The mapping is design data, not a mathematical relationship. A formula would hide the actual values from designers and make tuning opaque. The Dictionary is the single source of truth — change the table, the whole system updates.

**Why item tier 8 gives range (1, 4) not (1, 1):** Even the best item tier should have some variance. Fixed tier = no excitement. A narrow range (1-4) means 75% of rolls land in tier 1-2, which feels high-quality, with occasional tier 3-4 as the "not perfect" result.

**Why Vector2i:** This is the existing type for `Affix.tier_range`. Reusing the same type means the affix constructor receives `get_affix_tier_range(item.tier)` directly with no conversion.

---

### GDScript Patterns for Affix Tier Expansion (8 → 32)

#### 8. Widening Affix tier_range in ItemAffixes Templates

The expansion from 8 to 32 tiers does not require a new class or new affix instances. The `Affix` constructor already reads `tier_range` and scales `min_value`/`max_value` from it. Changing the template declarations in `item_affixes.gd` is sufficient.

```gdscript
# item_affixes.gd — MODIFY existing affix declarations

# BEFORE (8 tiers):
Affix.new("Physical Damage", Affix.AffixType.PREFIX, 2, 10,
    [Tag.PHYSICAL, Tag.FLAT, Tag.WEAPON], [Tag.StatType.FLAT_DAMAGE],
    Vector2i(1, 8), 3, 5, 7, 10)

# AFTER (32 tiers, preserving same base_min/base_max so tier 1 value is unchanged):
Affix.new("Physical Damage", Affix.AffixType.PREFIX, 2, 10,
    [Tag.PHYSICAL, Tag.FLAT, Tag.WEAPON], [Tag.StatType.FLAT_DAMAGE],
    Vector2i(1, 32), 3, 5, 7, 10)
```

**Why tier 1 value is unchanged after expansion:** The Affix constructor formula is `value = base_max * (tier_range.y + 1 - tier)`. At tier 1 with range (1, 32): `value = 10 * (32 + 1 - 1) = 10 * 32 = 320`. At tier 1 with range (1, 8): `value = 10 * (8 + 1 - 1) = 80`. This is a 4x INCREASE in top-tier values, which is intentional — prestige players earn access to items that are meaningfully stronger. The existing math does exactly what is needed with no formula changes.

**What changes at the bottom of the range:** Tier 32 value = `10 * (32 + 1 - 32) = 10 * 1 = 10`. This is the same as the old tier 8 minimum. The range is extended upward (better tiers), not compressed downward. Tier 8 items drop tier 17-32 affixes which remain in the same value territory as the old system's low rolls.

**Why no Affix subclass for "expanded" affixes:** GDScript inheritance for data classes adds serialization complexity. The `tier_range` parameter already parameterizes the tier window. Changing from 8 to 32 in the template is a one-field change per affix definition. No architecture change needed.

#### 9. Backward Compatibility of Existing Saved Affixes

Saved affixes already serialize `tier_range_x` and `tier_range_y` in `to_dict()` / `from_dict()`. Old saves have tier_range_y = 8. After the update, templates use 32. **This mismatch is intentional and safe:**

- Affixes already on items (in save files) keep their old `tier_range = Vector2i(1, 8)` because `from_dict()` reads the saved values, not the template.
- New affixes rolled after the update use the new `Vector2i(1, 32)`.
- No migration is needed for affixes — each affix carries its own tier range.

**Confidence: HIGH** — This is the same pattern that allowed the existing system to have some affixes with range (1, 8) and others with range (1, 30) simultaneously.

---

### GDScript Patterns for Tag-Targeted Crafting Currencies

#### 10. Tag-Targeted Currency Pattern: Filtered add_prefix / add_suffix

The existing `Item.add_prefix()` picks from `ItemAffixes.prefixes` where `has_valid_tag(prefix)` and `not is_affix_on_item(prefix)`. Tag-targeted currencies need to add an additional filter: the affix must contain a required tag.

The correct place for this logic is a new method on `Item` that accepts a required tag, NOT a new method on the currency. The currency provides the filter; the item enforces the affix rules.

```gdscript
# item.gd — ADD

## Adds a random prefix that both satisfies item tag requirements AND contains required_tag.
## Returns true if a valid affix was found and added.
func add_prefix_with_tag(required_tag: String) -> bool:
    if len(self.prefixes) >= max_prefixes():
        return false

    var valid_prefixes: Array[Affix] = []
    for prefix: Affix in ItemAffixes.prefixes:
        if has_valid_tag(prefix) and not is_affix_on_item(prefix) and required_tag in prefix.tags:
            valid_prefixes.append(prefix)

    if valid_prefixes.is_empty():
        return false

    var new_prefix: Affix = valid_prefixes.pick_random()
    self.prefixes.append(Affixes.from_affix(new_prefix))
    return true


## Adds a random suffix that satisfies item tag requirements AND contains required_tag.
func add_suffix_with_tag(required_tag: String) -> bool:
    if len(self.suffixes) >= max_suffixes():
        return false

    var valid_suffixes: Array[Affix] = []
    for suffix: Affix in ItemAffixes.suffixes:
        if has_valid_tag(suffix) and not is_affix_on_item(suffix) and required_tag in suffix.tags:
            valid_suffixes.append(suffix)

    if valid_suffixes.is_empty():
        return false

    var new_suffix: Affix = valid_suffixes.pick_random()
    self.suffixes.append(Affixes.from_affix(new_suffix))
    return true
```

**Why `required_tag in prefix.tags` not `prefix.tags.has(required_tag)`:** Both work identically for `Array[String]` in GDScript. The `in` operator is more idiomatic GDScript and matches the existing `tag in affix.tags` usage in `has_valid_tag()`. Consistency matters more than the distinction.

**Why NOT Array.filter() with a lambda for this:** `Array.filter()` in Godot 4 returns an untyped `Array`, not `Array[Affix]`. The existing codebase uses typed arrays (`Array[Affix]`) and explicit for-loops for this reason (verified in `Item.add_prefix()` and `Item.add_suffix()`). Continue the same pattern.

**Why NOT modify the existing `add_prefix()` / `add_suffix()`:** Adding an optional `required_tag: String = ""` parameter would add a conditional branch inside the hot path and mix two responsibilities (generic add vs. tag-targeted add). Two focused methods are cleaner.

#### 11. Tag-Targeted Currency Subclass

```gdscript
# models/currencies/fire_hammer.gd — NEW FILE (example for fire-targeted hammer)
class_name FireHammer extends Currency


func _init() -> void:
    currency_name = "Fire Hammer"


## Can apply to Normal items only (same as RunicHammer — grants 1 guaranteed fire mod)
func can_apply(item: Item) -> bool:
    return item.rarity == Item.Rarity.NORMAL


func get_error_message(item: Item) -> String:
    if item.rarity != Item.Rarity.NORMAL:
        return "Fire Hammer can only be used on Normal items"
    return ""


func _do_apply(item: Item) -> void:
    item.rarity = Item.Rarity.MAGIC

    # Try to add a FIRE-tagged prefix; fall back to suffix if no valid prefix exists
    if not item.add_prefix_with_tag(Tag.FIRE):
        item.add_suffix_with_tag(Tag.FIRE)

    item.update_value()
```

**Why one file per tag-targeted hammer:** Matches the existing pattern — each Currency subclass lives in its own file (`runic_hammer.gd`, `forge_hammer.gd`, etc.). The file structure is the project's organizational unit.

**Why require NORMAL rarity:** Tag-targeted hammers grant guaranteed mods, which is a strong effect. Restricting to Normal items keeps the power level consistent with RunicHammer (also requires Normal). This also prevents players from stacking guaranteed fire mods on an already-crafted item.

**Why try prefix first, then suffix:** Fire affixes currently exist only as prefixes (Physical Damage, Fire Damage, etc. are all `Affix.AffixType.PREFIX`). The suffix fallback is defensive programming — it costs nothing and future-proofs the hammer if fire suffixes are added.

#### 12. Prestige Gating for Tag-Targeted Currencies

Tag-targeted currencies unlock at Prestige 1. The gate belongs in the LootTable drop logic and the UI, not in the Currency class itself.

```gdscript
# loot_table.gd — MODIFY roll_pack_currency_drop to add tag-targeted hammers:

var pack_currency_rules: Dictionary = {
    "runic": {"chance": 0.25, "max_qty": 2},
    "tack": {"chance": 0.25, "max_qty": 2},
    "forge": {"chance": 0.25, "max_qty": 1},
    "grand": {"chance": 0.20, "max_qty": 1},
    "claw": {"chance": 0.20, "max_qty": 1},
    "tuning": {"chance": 0.20, "max_qty": 1},
    # NEW — tag-targeted hammers, only added if prestige unlocked:
    "fire": {"chance": 0.15, "max_qty": 1},
    "cold": {"chance": 0.15, "max_qty": 1},
    "lightning": {"chance": 0.15, "max_qty": 1},
    "defense": {"chance": 0.15, "max_qty": 1},
}

# Gate in the drop loop:
for currency_name in pack_currency_rules:
    # Check prestige gating before unlock level check
    if currency_name in ["fire", "cold", "lightning", "defense"]:
        if not GameState.prestige_unlocks.get("tag_targeted_currencies", false):
            continue
    # ... rest of existing drop logic
```

**Why gate in LootTable, not in GameState.currency_counts:** The currency counts dictionary in GameState should only grow as currencies unlock — new keys should be added when prestige unlocks them. LootTable is the right gate because it controls what can drop. GameState.currency_counts should not reference currencies that haven't been unlocked yet.

**How to add new currency keys to currency_counts when prestige unlocks them:**

```gdscript
# game_state.gd — MODIFY _compute_unlocks() or initialize_fresh_game()

func _initialize_currency_counts_for_prestige_level() -> void:
    # Base currencies always present
    if not "runic" in currency_counts:
        currency_counts = {"runic": 1, "forge": 0, "tack": 0,
                           "grand": 0, "claw": 0, "tuning": 0}
    # Prestige 1 unlocks tag-targeted currencies
    if prestige_level >= 1:
        for tag_hammer in ["fire", "cold", "lightning", "defense"]:
            if not tag_hammer in currency_counts:
                currency_counts[tag_hammer] = 0
```

---

### Signal Additions

```gdscript
# game_events.gd — ADD

signal prestige_triggered(new_level: int)   # Emitted by GameState.do_prestige()
signal prestige_available()                  # Emitted when can_prestige() becomes true (optional, for UI glow)
```

**Why `prestige_triggered` on GameEvents, not a direct call:** The existing event bus pattern decouples the prestige logic from the UI. `PrestigeView` connects to `GameEvents.prestige_triggered` to update its display; `SaveManager` connects to trigger a save after prestige. No caller needs to know which listeners exist.

**Why emit `prestige_available` separately:** The prestige button should visually indicate when prestige is ready (e.g., glow or enable state). This signal lets the UI react to currency accumulation without polling `can_prestige()` every frame. Emit it from `GameState.add_currencies()` after each currency gain when `can_prestige()` flips from false to true.

---

### UI Pattern: Prestige Panel

No new UI architecture needed. The prestige panel follows the existing tab pattern.

```
PrestigeView (CanvasLayer or Control, managed by main_view.gd tab bar)
├── Label: "Prestige Level: N / 7"
├── VBoxContainer: Cost display (one Label per currency in PRESTIGE_COSTS[prestige_level])
├── Button: "Prestige" — disabled unless can_prestige(), connected to GameState.do_prestige()
└── VBoxContainer: Unlock display (one Label per unlock at new level)
```

**Why CanvasLayer managed by main_view:** This is the existing pattern for all views (ForgeView, GameplayView, SettingsView). Adding prestige as a new tab requires only a new CanvasLayer child and one new case in `main_view._on_tab_pressed()`.

---

## What NOT to Add

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Separate prestige save file (`user://prestige.json`) | Two save files = two failure modes + broken export strings | One JSON envelope with prestige fields at the top level |
| `ResourceSaver` for prestige meta-state | Breaks the `HT1:base64:md5` export string system entirely | Extend existing `_build_save_data()` / `_restore_state()` |
| `PrestigeMeta` Resource class with `@export` fields | Creates a second serialization path alongside SaveManager JSON | Plain Dictionary fields in `GameState` autoload |
| `Array.filter()` with lambda for tag matching | Returns untyped `Array` (Godot 4 known issue), breaks `Array[Affix]` typed context | Explicit for-loop (matches existing `Item.add_prefix()` pattern) |
| `Array.any()` with lambda for the tag check in hot-path affix filtering | Creates a Callable allocation per check; for n=10 affixes it's acceptable but the for-loop is already established | `required_tag in affix.tags` inline — single `in` operator, zero allocation |
| Formula-based item tier → affix tier mapping | Hides design intent, makes tuning opaque | `ITEM_TIER_AFFIX_RANGE` Dictionary constant — explicit, tunable |
| New Affix subclass for "post-prestige affixes" | Breaks `create_from_dict()` dispatch, adds serialization complexity | Change `tier_range` in the template definitions only |
| Autoload for prestige state separate from GameState | GameState is already the single source of truth for all run + meta state | Two new vars in `game_state.gd` |
| `get_tree().reload_current_scene()` for prestige reset | Unnecessary scene reload overhead; autoload state persists across scene reloads anyway | Call `GameState.do_prestige()` directly — it resets run state in-memory without a scene reload |
| `@abstract` annotation on Currency base class (new in 4.5) | The project has no incorrectly-instantiated Currency base objects, and the `_do_apply()` virtual pattern already enforces the contract via comments | Keep the existing template method pattern with a `pass` in the base `_do_apply()` |

---

## Integration Points

### Changes

| Location | Current | After |
|----------|---------|-------|
| `GameState` | No prestige fields | +`prestige_level: int`, +`prestige_unlocks: Dictionary`, +`do_prestige()`, +`can_prestige()`, +`PRESTIGE_COSTS` const |
| `SaveManager.SAVE_VERSION` | 2 | 3 |
| `SaveManager._build_save_data()` | No prestige fields | +`prestige_level`, +`prestige_unlocks` keys |
| `SaveManager._restore_state()` | No prestige fields | +restore `prestige_level`, `prestige_unlocks` |
| `SaveManager._migrate_save()` | Handles v1→v2 | +handles v2→v3 (additive defaults injection) |
| `Item` | `add_prefix()`, `add_suffix()` only | +`add_prefix_with_tag(tag)`, +`add_suffix_with_tag(tag)` |
| `Item` | `var tier: int` set at item construction | `tier` set at drop time via `LootTable.roll_item_tier()` |
| `item.gd` | `ITEM_TIER_AFFIX_RANGE` does not exist | +`ITEM_TIER_AFFIX_RANGE: Dictionary` constant |
| `ItemAffixes.prefixes/suffixes` | `Vector2i(1, 8)` or `Vector2i(1, 30)` tier ranges | Expand to `Vector2i(1, 32)` for all offensive affixes; defensive stay wide or expand to (1, 32) |
| `LootTable` | 6 currency types in `pack_currency_rules` | +4 tag-targeted hammer types, prestige-gated |
| `GameEvents` | No prestige signals | +`prestige_triggered(level)`, +`prestige_available()` |
| `GameState.currency_counts` | 6 fixed keys | +4 conditional keys added when `prestige_level >= 1` |
| New file: `models/currencies/fire_hammer.gd` | Does not exist | `FireHammer extends Currency` |
| New file: `models/currencies/cold_hammer.gd` | Does not exist | `ColdHammer extends Currency` |
| New file: `models/currencies/lightning_hammer.gd` | Does not exist | `LightningHammer extends Currency` |
| New file: `models/currencies/defense_hammer.gd` | Does not exist | `DefenseHammer extends Currency` |
| New scene/view: `prestige_view.gd` + `.tscn` | Does not exist | Prestige panel, managed by `main_view.gd` tab system |

### Stays the Same

| What | Why Unchanged |
|------|--------------|
| `Item.to_dict()` / `Item.create_from_dict()` | Affix tier_range serialization already round-trips `tier_range_x` and `tier_range_y`. Saved affixes carry their own range. |
| `Affix` class and constructor | No new fields needed. `tier_range` parameterizes everything. |
| `Currency.apply()` / `_do_apply()` template method | New hammers are identical subclasses to existing ones. |
| `StatCalculator` / `DefenseCalculator` | Affix values scale with tier, not stat type. No stat formula changes. |
| `SaveManager` export/import string format (`HT1:base64:md5`) | The envelope is unchanged. Inner JSON gains new keys. |
| `LootTable.roll_pack_item_drop()` | Item drop chance is unchanged. Item tier assignment is a new layer on top. |
| `PackGenerator`, `CombatEngine`, `DefenseCalculator` | Prestige/tier changes do not touch combat resolution. |
| `BiomeConfig` | Biome structure and area scaling are unchanged. |
| `Hero.update_stats()` | Affix values change in magnitude (tier scaling), but stat aggregation logic is unchanged. |
| `ForgeView` crafting bench flow | select-and-click interaction is unchanged. New hammers appear as new buttons. |
| `GameEvents` existing signals | All 7 combat signals, `item_crafted`, `equipment_changed`, `area_cleared`, `save_completed`, `save_failed` are unchanged. |

---

## Version Compatibility

| API | Godot Version | Notes |
|-----|--------------|-------|
| `Array.any(Callable)` | 4.0+ | `[Tag.FIRE] in affix.tags` achieves the same result without Callable allocation. Use `in` operator for single-element checks. |
| `Array.filter(Callable)` | 4.0+ | Returns untyped `Array`. Do not assign to `Array[Affix]` without cast. Use for-loop instead. |
| `Dictionary.get(key, default)` | 4.0+ | Already used throughout for safe dictionary access. |
| `Dictionary.duplicate()` | 4.0+ | Shallow copy. Already used in `_build_save_data()` for `currency_counts`. |
| `pick_random()` on `Array` | 4.0+ | Already used in `Item.add_prefix()` and `PackGenerator`. |
| `sort_custom(Callable)` | 4.0+ | Lambda callable syntax already used in codebase. |
| `Vector2i(x, y)` | 4.0+ | Already the type for `Affix.tier_range`. |
| `in` operator for Array membership | 4.0+ | `"FIRE" in affix.tags` — O(n) linear scan, acceptable for n < 10 tags. |
| `clampf(value, min, max)` | 4.0+ | Float-typed clamp. Already used in LootTable sqrt ramp. |
| `@abstract` annotation on class | **4.5 only** | New in Godot 4.5. NOT recommended for this milestone (see What NOT to Add). |
| `duplicate_deep()` on Array/Dictionary | **4.5 only** | New in Godot 4.5. Not needed here — prestige_unlocks values are primitives. |
| `JSON.stringify` / `JSON.parse_string` | 4.0+ | Already in `SaveManager`. Boolean values serialize as JSON true/false and round-trip correctly. |
| `FileAccess.open` / `DirAccess.remove_absolute` | 4.0+ | Already in `SaveManager`. No changes needed. |

---

## Alternatives Considered

| Recommended | Alternative | Why Not |
|-------------|-------------|---------|
| Two vars in `GameState` for prestige meta | Separate `PrestigeMeta` Resource class | Resource needs its own serialize path. The project uses JSON via `SaveManager`. Adding a Resource layer adds a second save format. |
| `ITEM_TIER_AFFIX_RANGE` Dictionary constant | Formula: `Vector2i(33 - item_tier * 4, 32 - (item_tier - 1) * 4)` | Formula gives same results but hides the design intent and makes tier boundary tuning opaque. Dictionary is explicit and tunable. |
| `add_prefix_with_tag(required_tag)` on Item | Pass a filter Callable into the existing `add_prefix()` | Callable parameter obscures the call site. Two explicit methods are more readable and match the existing `can_apply()` / `_do_apply()` pattern for Currency. |
| Inline `required_tag in prefix.tags` check in for-loop | `prefix.tags.any(func(t): return t == required_tag)` | The lambda version creates a Callable object per iteration. The `in` operator is the idiomatic GDScript equivalent with zero allocation. |
| `initialize_fresh_game()` called from `do_prestige()` | Duplicate the reset logic in `do_prestige()` | Single source of truth for "what is run state" prevents desync. `initialize_fresh_game()` is already the canonical reset — reuse it. |
| Version bump to v3 with additive migration | Keep SAVE_VERSION at 2 and detect new fields with `has()` | The existing migration chain is the established pattern. Explicit versioning prevents ambiguous states during development and makes migration intent searchable. |
| LootTable gates tag-targeted currency drops by prestige | Currency class checks `GameState.prestige_level` directly | LootTable already owns all drop gating logic (see `CURRENCY_AREA_GATES`). Centralizing gates in one place prevents scattered `if prestige >= 1` checks. |

---

## Sources

**HIGH Confidence (Direct codebase analysis):**
- `/var/home/travelboi/Programming/hammertime/autoloads/game_state.gd` — `initialize_fresh_game()`, `currency_counts`, `spend_currency()` — prestige reset extends these
- `/var/home/travelboi/Programming/hammertime/autoloads/save_manager.gd` — `_migrate_save()` chain, `_build_save_data()`, `_restore_state()`, `SAVE_VERSION` — v3 migration follows same pattern
- `/var/home/travelboi/Programming/hammertime/models/affixes/affix.gd` — `tier_range: Vector2i`, constructor scaling formula `base * (tier_range.y + 1 - tier)`, `to_dict()` / `from_dict()` with `tier_range_x/y`
- `/var/home/travelboi/Programming/hammertime/autoloads/item_affixes.gd` — Template definitions with `Vector2i(1, 8)` and `Vector2i(1, 30)` — confirmed range is just a constructor param
- `/var/home/travelboi/Programming/hammertime/models/items/item.gd` — `add_prefix()`, `add_suffix()`, `has_valid_tag()`, `is_affix_on_item()` — tag-targeted extension points
- `/var/home/travelboi/Programming/hammertime/models/currencies/runic_hammer.gd` — Template method pattern confirmed: `can_apply()` → `_do_apply()` with rarity change + affix add
- `/var/home/travelboi/Programming/hammertime/models/loot/loot_table.gd` — `roll_pack_currency_drop()`, `CURRENCY_AREA_GATES`, `_calculate_currency_chance()` — tag hammer gating extends this pattern
- `/var/home/travelboi/Programming/hammertime/autoloads/tag.gd` — `Tag.FIRE`, `Tag.COLD`, `Tag.LIGHTNING`, `Tag.DEFENSE` string constants — used as required_tag values

**MEDIUM Confidence (Official Godot docs and community sources):**
- [Godot 4.5 release notes — godotengine.org](https://godotengine.org/releases/4.5/) — Confirmed: `@abstract` annotation added in 4.5, `duplicate_deep()` added. No save/serialization changes. GDScript lambdas and `Array.any()` existed since 4.0.
- [Array filter() returns untyped Array — GitHub #82538](https://github.com/godotengine/godot/issues/82538) — Confirmed known issue: `filter()` does not return typed arrays. Use for-loops for `Array[Affix]` contexts.
- [Godot Forum — Resetting autoload state](https://forum.godotengine.org/t/resetting-rerunning-autoloaded-script-to-generate-new-random-variables-how/12554) — Pattern: extract init logic into `_initialize_state()` function callable multiple times. Do NOT destroy/recreate autoloads.
- [Godot Forum — Array intersection](https://forum.godotengine.org/t/how-to-check-for-array-intersection/27600) — For small arrays (< 10 tags), `element in array` is acceptable. Dictionary-based O(1) lookup only needed for large arrays.
- [GDQuest save format comparison](https://www.gdquest.com/tutorial/godot/best-practices/save-game-formats/) — Confirmed: JSON recommended when export strings or external data exchange is needed. Already the right choice for this project.
- [Array.any() / Array.all() in GDScript 4](https://www.syntaxcache.com/gdscript/arrays-loops) — Confirmed: `any(Callable)` and `all(Callable)` available in Godot 4.0+. Accept lambda functions.

**LOW Confidence (Inferred from patterns, no direct official source):**
- Weighted triangular drop table for item tier (`roll_item_tier` formula) — The specific area-scaling formula is original design. The weighted accumulation pattern is verified (matches `PackGenerator.roll_element()`). The specific weight values are a design choice, not a Godot API question.
- `prestige_available` signal emit strategy from `add_currencies()` — Pattern is sound (check `can_prestige()` after currency gain, emit once on true). The specific emit placement is a design decision, not researched.

---

*Stack research for: Hammertime v1.7 — Meta-Progression, Item Tiers, Affix Tier Expansion, Tag-Targeted Currencies*
*Researched: 2026-02-20*
*Confidence: HIGH — All GDScript patterns verified against existing codebase. Godot 4.5 API points confirmed via official release notes and community sources.*
