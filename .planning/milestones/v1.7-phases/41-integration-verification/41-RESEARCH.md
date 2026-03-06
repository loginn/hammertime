# Phase 41: Integration Verification - Research

**Researched:** 2026-03-06

## Research Summary

Phase 41 is a pure verification phase: no new features, only a GDScript test scene that exercises the full prestige loop end-to-end and validates save round-trips. The test scene runs in `tools/test/`, uses an isolated save path, and prints structured `[PASS]`/`[FAIL]` output. All 23 v1.7 requirements are already marked complete; this phase confirms they work together correctly.

Key findings:
- No existing test infrastructure exists (no `tools/test/` directory, no test framework). The test scene will be the first.
- All prestige, save, and crafting code is autoload-based, so the test scene has full access to `GameState`, `SaveManager`, `PrestigeManager`, `ItemAffixes` without additional wiring.
- The critical challenge is that `GameState._ready()` calls `initialize_fresh_game()` then `load_game()` on autoload initialization. The test scene must work *after* that initialization has already run, which means it needs to explicitly reset state before each test group.
- `SaveManager.SAVE_PATH` is a `const` -- cannot be reassigned at runtime. The test must either use `save_game()`/`load_game()` indirectly by writing to a temp path using raw `FileAccess`, or (simpler) manipulate `_build_save_data()` and `_restore_state()` directly for round-trip testing, only using the real `save_game()`/`load_game()` for the actual file I/O test (cleaning up after).

## Codebase Analysis

### PrestigeManager (`autoloads/prestige_manager.gd`)
- **Constants:**
  - `MAX_PRESTIGE_LEVEL = 7`
  - `PRESTIGE_COSTS`: Dictionary keyed by level 1-7. P1 costs `{"forge": 100}`, P2-P7 cost `{"forge": 999999}` (stub).
  - `ITEM_TIERS_BY_PRESTIGE`: 8-element array `[8, 7, 6, 5, 4, 3, 2, 1]`, index = prestige level.
  - `TAG_TYPES`: `["fire", "cold", "lightning", "defense", "physical"]`

- **`can_prestige() -> bool`** (line 26-34):
  - Returns `false` if `prestige_level >= MAX_PRESTIGE_LEVEL`.
  - Checks each currency in `PRESTIGE_COSTS[next_level]` against `GameState.currency_counts`.

- **`execute_prestige() -> bool`** (line 46-72):
  1. Validates via `can_prestige()`.
  2. Spends currencies BEFORE wipe (calls `GameState.spend_currency()` in a loop -- one call per unit).
  3. Advances `prestige_level` and `max_item_tier_unlocked`.
  4. Calls `GameState._wipe_run_state()`.
  5. Grants 1 random tag currency via `_grant_random_tag_currency()` (AFTER wipe).
  6. Emits `GameEvents.prestige_completed`.

- **`_grant_random_tag_currency()`** (line 76-80):
  - Picks one random tag from `TAG_TYPES`, increments `GameState.tag_currency_counts[chosen]`.

### GameState (`autoloads/game_state.gd`)
- **Prestige fields (persist across resets):**
  - `prestige_level: int = 0`
  - `max_item_tier_unlocked: int = 8`

- **Run-scoped fields (wiped on prestige):**
  - `currency_counts: Dictionary` (initialized with `"runic": 1, "forge": 0, ...`)
  - `crafting_inventory: Dictionary` (per-slot arrays, starter weapon in weapon slot)
  - `hero: Hero` (new Hero, all slots null)
  - `area_level: int = 1`, `max_unlocked_level: int = 1`
  - `tag_currency_counts: Dictionary = {}`

- **`_ready()`** (line 31-45): Calls `initialize_fresh_game()`, then `SaveManager.load_game()`.

- **`initialize_fresh_game()`** (line 49-91): Full reset of ALL state including prestige fields to defaults. Called only for truly new games and at startup before load.

- **`_wipe_run_state()`** (line 95-133): Resets run-scoped state only. Does NOT touch `prestige_level` or `max_item_tier_unlocked`. Creates new Hero, new crafting_inventory with LightSword starter, resets currencies, wipes `tag_currency_counts`.

- **`spend_currency(type) -> bool`** (line 145-153): Decrements `currency_counts[type]` by 1 if > 0.

- **`spend_tag_currency(type) -> bool`** (line 158-164): Decrements `tag_currency_counts[type]` by 1 if > 0.

### SaveManager (`autoloads/save_manager.gd`)
- **Constants:**
  - `SAVE_PATH = "user://hammertime_save.json"` (const -- not runtime-modifiable)
  - `SAVE_VERSION = 4`

- **`_build_save_data() -> Dictionary`** (line 82-112): Serializes:
  - `version`, `timestamp`, `hero_equipment`, `currencies`, `crafting_inventory`, `crafting_bench_type`, `max_unlocked_level`, `area_level`
  - Prestige fields: `prestige_level`, `max_item_tier_unlocked`, `tag_currency_counts`

- **`_restore_state(data) -> bool`** (line 116-167): Restores all fields with `.get()` defaults:
  - `prestige_level` defaults to 0, `max_item_tier_unlocked` defaults to 8
  - `tag_currency_counts` cleared then rebuilt from save data
  - Calls `hero.update_stats()` after restore

- **`load_game() -> bool`** (line 42-67): Version check -- if `saved_version < SAVE_VERSION`, deletes save and returns false.

- **`save_game() -> bool`** (line 28-38): Writes JSON to `SAVE_PATH`.

- **`_on_prestige_completed()`** (line 254-255): Calls `save_game()` directly (not debounced).

### Item Tier System (`models/items/item.gd`)
- **`_get_affix_tier_floor() -> int`** (line 225-226): `return (self.tier - 1) * 4 + 1`
  - Tier 8: floor = 29 (affixes 29-32)
  - Tier 7: floor = 25 (affixes 25-32)
  - Tier 1: floor = 1 (affixes 1-32)

- **`add_prefix()` / `add_suffix()`** (lines 229-280): Both call `_get_affix_tier_floor()` and pass to `Affixes.from_affix(template, floor_val)`.

- **`tier: int`** field on Item, set in constructor (LightSword defaults to 8).

### Affixes System (`autoloads/item_affixes.gd`)
- **`Affixes.from_affix(template, affix_tier_floor) -> Affix`** (line 259-277):
  - Clamps `tier_range.x` to `max(tier_range.x, affix_tier_floor)`.
  - Creates new Affix instance with effective range -- tier is randomized within that range.
  - All template affixes have `tier_range = Vector2i(1, 32)`.

### Affix Model (`models/affixes/affix.gd`)
- **Tier calculation** (line 52-58): `tier = randi_range(tier_range.x, tier_range.y)`, then:
  - `min_value = base_min * (tier_range.y + 1 - tier)`
  - `max_value = base_max * (tier_range.y + 1 - tier)`
  - Higher tier number = lower values (tier 32 = weakest, tier 1 = strongest).

### Forge View Tag Gating (`scenes/forge_view.gd`)
- **`_update_tag_section_visibility()`** (line 278-279): `tag_hammer_section.visible = (GameState.prestige_level >= 1)`
- Called in `_ready()` and on `prestige_completed` signal.
- Tag hammer buttons are children of `$HammerSidebar/TagHammerSection`.

### Prestige View (`scenes/prestige_view.gd`)
- Displays current prestige level, next cost, unlock table.
- `_execute_prestige()` calls `PrestigeManager.execute_prestige()`, then `SaveManager.save_game()`, then emits `prestige_triggered`.
- Main view listens for `prestige_triggered` and triggers fade-to-black + `reload_current_scene()`.

### Item Types
- 5 concrete types: `LightSword`, `BasicArmor`, `BasicHelmet`, `BasicBoots`, `BasicRing`
- All registered in `Item.ITEM_TYPE_STRINGS` for deserialization.
- `LightSword` is the starter weapon (tier 8, Normal rarity, valid_tags: PHYSICAL, ATTACK, CRITICAL, WEAPON).

### Currency Types
- Standard: `RunicHammer`, `ForgeHammer`, `TackHammer`, `GrandHammer`, `ClawHammer`, `TuningHammer`
- Tag: `TagHammer` (parameterized by tag + name)
- `RunicHammer.can_apply()`: requires Normal rarity. Applies: sets MAGIC, adds 1-2 mods.
- `TagHammer.can_apply()`: requires Normal rarity + matching affix available. Applies: sets RARE, adds 4-6 mods, guarantees tagged affix.

## Integration Flow

### Full Prestige Execution (P0 -> P1):

1. **Pre-condition**: Player has >= 100 Forge Hammers (`GameState.currency_counts["forge"] >= 100`)
2. **`PrestigeManager.can_prestige()`** returns `true`
3. **`PrestigeManager.execute_prestige()`**:
   a. Spends 100 forge hammers (100 calls to `GameState.spend_currency("forge")`)
   b. Sets `GameState.prestige_level = 1`
   c. Sets `GameState.max_item_tier_unlocked = 7` (from `ITEM_TIERS_BY_PRESTIGE[1]`)
   d. Calls `GameState._wipe_run_state()`:
      - `area_level = 1`, `max_unlocked_level = 1`
      - New Hero with empty equipment
      - New crafting_inventory with LightSword in weapon slot
      - `currency_counts` reset (runic=1, rest=0)
      - `tag_currency_counts = {}`
   e. Calls `_grant_random_tag_currency()`: adds 1 unit of random tag type
   f. Emits `GameEvents.prestige_completed(1)`
4. **Signal handlers**:
   - `SaveManager._on_prestige_completed(1)` -> `save_game()` (auto-save)
   - `forge_view._on_prestige_completed(1)` -> `_update_tag_section_visibility()` (shows tag section)
   - `prestige_view._execute_prestige()` also calls `save_game()` again + emits `prestige_triggered`
   - `main_view._on_prestige_triggered()` -> fade-to-black -> `reload_current_scene()`

### Post-Prestige State:
- `prestige_level = 1`
- `max_item_tier_unlocked = 7`
- `area_level = 1`, `max_unlocked_level = 1`
- Hero: fresh, no equipment
- Crafting: LightSword (tier 8, Normal) in weapon slot
- `currency_counts = {"runic": 1, "forge": 0, ...}`
- `tag_currency_counts = {<random_tag>: 1}` (exactly 1 total)

## Save Format Details

**SAVE_VERSION = 4** (current). Saves with version < 4 are deleted on load.

```json
{
  "version": 4,
  "timestamp": <unix_time>,
  "hero_equipment": {
    "weapon": <item_dict or null>,
    "helmet": <item_dict or null>,
    "armor": <item_dict or null>,
    "boots": <item_dict or null>,
    "ring": <item_dict or null>
  },
  "currencies": {"runic": 1, "forge": 0, "tack": 0, "grand": 0, "claw": 0, "tuning": 0},
  "crafting_inventory": {
    "weapon": [<item_dict>, ...],
    "helmet": [],
    ...
  },
  "crafting_bench_type": "weapon",
  "max_unlocked_level": 1,
  "area_level": 1,
  "prestige_level": 0,
  "max_item_tier_unlocked": 8,
  "tag_currency_counts": {}
}
```

**Prestige-specific fields in save:**
- `prestige_level` (int, default 0)
- `max_item_tier_unlocked` (int, default 8)
- `tag_currency_counts` (dict, default {})

**Restore defaults** (from `_restore_state` `.get()` calls):
- `prestige_level` -> 0
- `max_item_tier_unlocked` -> 8
- `tag_currency_counts` -> {} (cleared before rebuild)

## Test Infrastructure

**Current state:** No test infrastructure exists.
- No `tools/test/` directory
- No test framework (GUT or custom)
- No test scenes
- Only debug aids: `GameState.debug_hammers`, `PackGenerator.debug_generate()`, print statements

**Test scene approach (per CONTEXT decisions):**
- Create `tools/test/integration_test.tscn` + `tools/test/integration_test.gd`
- Run as standalone scene from Godot editor
- Structured output: `[PASS]`/`[FAIL]` per check, summary at end
- Separate save path to avoid touching real saves

## Validation Architecture

### Test Scene Design

The test scene (`tools/test/integration_test.gd`) extends `Node` and runs all checks in `_ready()`. Since autoloads initialize before any scene's `_ready()`, `GameState` will have already called `initialize_fresh_game()` + `load_game()`. The test must explicitly set state before each test group.

### Proposed Test Groups:

**Group 1: Pre-Prestige Baseline (P0)**
1. Reset GameState to fresh (call `initialize_fresh_game()`)
2. Verify `prestige_level == 0`, `max_item_tier_unlocked == 8`
3. Verify `can_prestige() == false` (no forge hammers)
4. Verify starter weapon exists (LightSword in crafting_inventory["weapon"])
5. Verify `area_level == 1`
6. Verify `tag_currency_counts` is empty

**Group 2: Prestige Gating**
1. Grant 99 forge hammers -> verify `can_prestige() == false`
2. Grant 1 more (total 100) -> verify `can_prestige() == true`
3. Verify prestige cost for P1: `get_next_prestige_cost() == {"forge": 100}`

**Group 3: Execute Prestige P0 -> P1**
1. Execute prestige -> verify returns `true`
2. Verify `prestige_level == 1`
3. Verify `max_item_tier_unlocked == 7`
4. Verify `area_level == 1` (reset)
5. Verify hero equipment all null (fresh hero)
6. Verify starter weapon in crafting inventory
7. Verify `currency_counts["forge"] == 0` (spent + wiped)
8. Verify `tag_currency_counts` has exactly 1 total currency
9. Verify `can_prestige() == false` (P2 costs 999999)

**Group 4: Save Round-Trip at P0**
1. Set up known P0 state
2. Call `_build_save_data()`
3. Modify GameState to garbage values
4. Call `_restore_state(saved_data)`
5. Verify all prestige fields match original

**Group 5: Save Round-Trip at P1**
1. Set up known P1 state (after prestige)
2. Call `_build_save_data()`
3. Modify GameState to garbage values
4. Call `_restore_state(saved_data)`
5. Verify `prestige_level == 1`, `max_item_tier_unlocked == 7`, `tag_currency_counts` preserved

**Group 6: Crafting Regression After Prestige**
1. Set `prestige_level = 1` and grant 1 runic hammer
2. Get starter weapon (LightSword, Normal rarity)
3. Apply RunicHammer -> verify rarity changes to MAGIC
4. Verify item has 1-2 mods (prefixes + suffixes count)

**Group 7: Item Tier / Affix Tier Floor**
1. Create LightSword (tier 8) -> verify `_get_affix_tier_floor() == 29`
2. Set item tier to 7 -> verify `_get_affix_tier_floor() == 25`
3. Apply RunicHammer to tier 7 item -> verify all affix tiers >= 25
4. Set item tier to 1 -> verify `_get_affix_tier_floor() == 1`

**Group 8: Tag Hammer Gating (Logic-Only)**
1. At P0: verify `tag_hammer_section` visibility check logic (`prestige_level >= 1` is false)
2. At P1: verify visibility check logic is true
3. Verify TagHammer can_apply requires Normal rarity
4. Grant 1 fire tag currency, verify `spend_tag_currency("fire")` succeeds

**Group 9: File I/O Round-Trip**
1. Use `SaveManager._build_save_data()` to get data dict
2. Write to test path (`user://test_save.json`) using raw FileAccess
3. Read back and parse JSON
4. Call `_restore_state()` with parsed data
5. Verify state matches
6. Clean up test file

### Key Architecture Decisions:

1. **Isolated save path**: Since `SAVE_PATH` is `const`, can't redirect `save_game()`/`load_game()`. Instead, test `_build_save_data()` and `_restore_state()` directly (they are the real logic). For file I/O verification, write/read manually to a test path.

2. **State reset between groups**: Call `GameState.initialize_fresh_game()` at the start of each group to ensure clean slate. This resets ALL state including prestige fields.

3. **No scene tree dependencies**: The test scene should NOT instantiate ForgeView or other UI scenes. Tag section visibility gating is tested by checking the condition (`prestige_level >= 1`) directly, not by checking node visibility.

4. **Cleanup**: Delete `user://test_save.json` at end of all tests (in `_notification(NOTIFICATION_PREDELETE)` or at end of `_ready()`).

## Key Risks and Edge Cases

1. **`SAVE_PATH` is const**: Cannot be reassigned. Test must work around this by either:
   - Testing `_build_save_data()` / `_restore_state()` in memory (preferred)
   - Using raw FileAccess for file I/O tests with a separate path
   - Being careful NOT to call `save_game()` which would overwrite the real save

2. **Autoload initialization order**: GameState calls `initialize_fresh_game()` then `load_game()` in its `_ready()`. By the time the test scene's `_ready()` runs, autoloads are already initialized. If a real save exists, it will have been loaded. The test must call `initialize_fresh_game()` explicitly to get a clean baseline.

3. **`_wipe_run_state()` is "private"**: The `_` prefix in GDScript is convention only; still callable from test code.

4. **Random tag currency after prestige**: `_grant_random_tag_currency()` picks randomly. Test should verify total count == 1, not which specific tag.

5. **Affix tier randomness**: When testing affix tier floor, need to verify `tier >= floor` on generated affixes. Since tiers are random within range, run the check on the generated affix (which must be >= floor by construction).

6. **RunicHammer mod count is probabilistic**: 70% chance of 1 mod, 30% chance of 2 mods. Test should verify `prefixes.size() + suffixes.size() >= 1` (at least 1 mod added).

7. **`spend_currency()` loop in execute_prestige**: Spends one at a time in a loop of 100. Not a risk for testing, but worth noting it's O(n) calls.

8. **Hero.update_stats() after restore**: `_restore_state()` calls `hero.update_stats()` which recalculates derived stats. Test should verify hero exists and is functional after restore.

9. **Test scene must not accidentally save**: Calling `GameEvents.item_crafted.emit()` or similar would trigger debounced save via SaveManager signal connections. The test should avoid emitting signals that trigger saves, or the test should call `initialize_fresh_game()` at the end to restore clean state. Safest approach: avoid crafting-related signal emissions entirely, and clean up state at end.

10. **Prestige auto-save via signal**: `execute_prestige()` emits `prestige_completed`, which SaveManager listens to and calls `save_game()`. This WILL overwrite the real save. The test should either:
    - Disconnect the signal before testing, then reconnect
    - Or call `execute_prestige()` steps manually (spend, advance, wipe, grant) without going through the full method
    - Or accept that the test overwrites the save and restore original state after

    **Recommended**: Manually replicate prestige steps without calling `execute_prestige()` to avoid signal emission, OR disconnect `SaveManager._on_prestige_completed` before the test and reconnect after.

## RESEARCH COMPLETE
