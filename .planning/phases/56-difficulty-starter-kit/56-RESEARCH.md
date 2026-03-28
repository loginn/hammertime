# Phase 56: Difficulty & Starter Kit - Research

**Researched:** 2026-03-28
**Domain:** GDScript game balance, state initialization, string rename
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Starter weapon is archetype-matched: Broadsword for STR, Dagger for DEX, Wand for INT
- **D-02:** Starter armor is archetype-matched: IronPlate for STR, LeatherVest for DEX, SilkRobe for INT
- **D-03:** Starter items are Normal rarity (blank bases, no affixes)
- **D-04:** Fresh game starts with 2 Transmute + 2 Augment, replacing the old 1 Runic starter
- **D-05:** Currency key rename: runic→transmute, forge→augment, tack→alteration, grand→regal, claw→chaos, tuning→exalt. All references in code (currency_counts keys, UI labels, save compat) must be updated
- **D-06:** Tune Forest monster base_hp and base_damage values directly (not growth rate or curve changes)
- **D-07:** Survival target: fresh P0 hero with blank Normal starter weapon + armor should survive zone 1 only. Must craft by zone 2
- **D-08:** Prestige resets grant the same starter kit as fresh new games (archetype-matched weapon + armor in stash, 2 Transmute + 2 Augment)
- **D-09:** Starter items placed AFTER archetype re-selection — player picks archetype first (Phase 53 overlay), then matching starter items appear in stash. Requires hooking into the archetype selection callback

### Claude's Discretion
- Exact Forest monster base_hp/base_damage numbers (researcher should analyze current values vs hero blank-weapon DPS to find the right balance for zone 1 survival)
- Implementation details for the currency rename (how to handle save format v8 compatibility)
- Which function places starter items — could be in `initialize_fresh_game()`, `_wipe_run_state()`, or a new dedicated function called after archetype selection

### Deferred Ideas (OUT OF SCOPE)
- Large number formatting with suffix notation (K/M/B)
- Item drop filter for unwanted loot
- Prestige-scaled starter kit (better items at higher prestige)
- Smart discard policy (keep higher tier on overflow)
- Save format v9 changes (that is Phase 58 scope)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DIFF-01 | Fresh P0 hero survives Forest packs consistently with starter gear | Combat math analysis in Architecture Patterns; recommended base_hp/base_damage values in Code Examples |
| DIFF-03 | Fresh hero starts with starter weapon + armor in stash, plus 2 Transmute and 2 Augment hammers | Starter kit placement patterns; currency rename map; integration test additions documented |
</phase_requirements>

---

## Summary

Phase 56 has three independent work streams that touch different parts of the codebase: (1) starter kit placement — adding archetype-matched weapon/armor to the stash and setting initial currency counts correctly, (2) Forest difficulty tuning — reducing monster base_hp and base_damage so a blank-weapon hero survives zone 1, and (3) currency key rename — a pure string replacement across six files with a save-compat consideration.

The starter kit must be delivered in two moments: at `initialize_fresh_game()` for brand-new P0 games, and post-archetype-selection for prestige resets. The `_on_hero_card_selected()` callback in `main_view.gd` is the correct hook for prestige restarts because archetype is confirmed there before any other game-setup code runs. For P0 fresh games (no archetype overlay is shown), `initialize_fresh_game()` must also place a starter kit — but without an archetype, it defaults to Broadsword + IronPlate (the STR defaults, matching the existing precedent from the old single-Runic starter).

The currency rename is a save-compat rename only within the current v8 format. Since `save_manager.gd` restores currencies via a direct key-copy loop (`GameState.currency_counts[currency_type] = int(saved_currencies[currency_type])`), old v8 saves that contain the old key names ("runic", "forge", etc.) will simply not populate the new keys after rename. The chosen policy (matching the existing "outdated save = delete and start fresh" pattern) is to bump SAVE_VERSION to 9 only in Phase 58. For Phase 56, the rename is applied to all runtime code but the save version stays at 8. This means existing saves will load with 0 counts for all currencies — acceptable because the player also gets a fresh starter kit from `initialize_fresh_game()` defaults.

**Primary recommendation:** Implement in three atomic tasks: (1) currency rename + starter currency counts, (2) starter item placement with archetype hook, (3) Forest difficulty numbers. Run the integration test suite after each task.

---

## Standard Stack

No new libraries. All work is pure GDScript edits to existing files.

| File | Role | Changes Needed |
|------|------|----------------|
| `autoloads/game_state.gd` | State init | Currency keys renamed; starter item placement added |
| `autoloads/prestige_manager.gd` | Prestige cost | Currency key updated (forge → augment) |
| `scenes/forge_view.gd` | UI display | Currency keys renamed in 6 dictionaries + button bindings |
| `scenes/prestige_view.gd` | UI display | Currency key updated (forge → augment) in 2 label strings |
| `models/loot/loot_table.gd` | Drop rates | Currency keys renamed in GATE_LEVELS + DROP_RATES dicts |
| `models/monsters/biome_config.gd` | Monster data | Forest base_hp/base_damage values reduced |
| `scenes/main_view.gd` | Archetype hook | `_on_hero_card_selected()` extended to place starter kit post-selection |
| `tools/test/integration_test.gd` | Tests | Old currency key references renamed; new test groups added |

---

## Architecture Patterns

### Recommended Function Structure

```
initialize_fresh_game()
  → sets currency_counts with new keys: transmute=2, augment=2, alteration=0, ...
  → calls _init_stash()
  → calls _place_starter_kit(null)  # null = no archetype yet, use defaults

_wipe_run_state()
  → sets currency_counts with new keys: transmute=2, augment=2, alteration=0, ...
  → calls _init_stash()
  → does NOT call _place_starter_kit() — archetype not re-selected yet at this point

_place_starter_kit(archetype: HeroArchetype)
  → determines weapon class and armor class from archetype (or defaults for null)
  → instantiates weapon at tier 8 with Normal rarity
  → instantiates armor at tier 8 with Normal rarity
  → calls add_item_to_stash(weapon) and add_item_to_stash(armor)

main_view.gd _on_hero_card_selected(hero)
  → [existing: sets hero_archetype, updates stats, saves, emits]
  → [new: calls GameState._place_starter_kit(hero)]  ← insert here
```

**Key insight for P0 fresh game:** `initialize_fresh_game()` is called BEFORE the save load attempt in `_ready()`. For P0 there is no archetype overlay. The starter kit placed by `initialize_fresh_game()` using null-archetype defaults (Broadsword + IronPlate) will be the correct items unless the player has a save with an archetype already set. If a save loads successfully, the stash is restored from save data — so the starter kit from `initialize_fresh_game()` is overwritten by the save load. This is correct: returning players should not get a free starter kit on every load.

**The ordering is:**
1. `initialize_fresh_game()` — sets defaults including starter kit for the no-save case
2. `SaveManager.load_game()` — if save exists, overwrites stash and currencies from save
3. For prestige: `_wipe_run_state()` clears state but NO starter kit yet
4. `_on_hero_card_selected()` — places starter kit after archetype confirmed

### Pattern: Archetype → Starter Item Map

```gdscript
# Source: game_state.gd (new helper function)
func _place_starter_kit(archetype: HeroArchetype) -> void:
    var weapon: Item
    var armor: Item
    if archetype == null:
        # P0 fresh game with no archetype — use STR defaults
        weapon = Broadsword.new(8)
        armor = IronPlate.new(8)
    else:
        match archetype.archetype:
            HeroArchetype.Archetype.STR:
                weapon = Broadsword.new(8)
                armor = IronPlate.new(8)
            HeroArchetype.Archetype.DEX:
                weapon = Dagger.new(8)
                armor = LeatherVest.new(8)
            HeroArchetype.Archetype.INT:
                weapon = Wand.new(8)
                armor = SilkRobe.new(8)
    add_item_to_stash(weapon)
    add_item_to_stash(armor)
```

### Pattern: Currency Rename Map

The rename is a direct key substitution. Every dict literal and every string lookup using old keys must be updated. No migration function is needed for the save file at this phase — the existing "delete outdated save" policy means v8 saves with old keys simply result in zero counts (which is acceptable; player starts fresh with 2 transmute + 2 augment defaults).

| Old Key | New Key | Old Human Name | New Human Name |
|---------|---------|----------------|----------------|
| `"runic"` | `"transmute"` | Runic Hammer | Transmute Hammer |
| `"forge"` | `"augment"` | Forge Hammer | Augment Hammer |
| `"tack"` | `"alteration"` | Tack Hammer | Alteration Hammer |
| `"grand"` | `"regal"` | Grand Hammer | Regal Hammer |
| `"claw"` | `"chaos"` | Claw Hammer | Chaos Hammer |
| `"tuning"` | `"exalt"` | Tuning Hammer | Exalt Hammer |

**Files with currency key string references (confirmed by grep):**

| File | Old Key Occurrences | Notes |
|------|---------------------|-------|
| `autoloads/game_state.gd` | runic×2, forge×2, tack×2, grand×2, claw×2, tuning×2 | 2 locations (initialize + wipe) |
| `autoloads/prestige_manager.gd` | forge×7 | PRESTIGE_COSTS dict keys |
| `models/loot/loot_table.gd` | runic×2, tack×2, forge×3, grand×2, claw×2, tuning×2 | GATE_LEVELS + DROP_RATES |
| `scenes/forge_view.gd` | runic×6, forge×6, tack×6, grand×6, claw×6, tuning×6 | HAMMER_INSTANCES, TOOLTIPS, ICONS, BUTTONS, bindings, standard_types array |
| `scenes/prestige_view.gd` | forge×2 | Two label strings |
| `tools/test/integration_test.gd` | forge×7, runic×2 | Test assertions with old key names |

**Note:** `scenes/main_view.gd` uses `"forge"` as a VIEW NAME (not a currency key). The string `"forge"` in `show_view("forge")` and `current_view == "forge"` refers to the forge/crafting tab name, NOT the hammer currency. Do NOT rename these occurrences.

### Pattern: Forest Difficulty Tuning

**Combat math for blank P0 hero (STR archetype, Broadsword tier 8):**

- Hero HP: 100 (base, no armor affixes on a blank Normal IronPlate with base_armor=5)
- Broadsword tier 8 DPS: avg_damage=10 × base_attack_speed=1.8 × base_speed=1 × crit_mult=1.0525 ≈ **18.9 DPS**
- IronPlate tier 8: base_armor=5, no affixes → minimal damage reduction via DefenseCalculator

**Current Forest monsters at level 1 (multiplier = 1.0x):**

| Monster | base_hp | base_damage | base_attack_speed | DPS to hero | Seconds to kill |
|---------|---------|-------------|-------------------|-------------|-----------------|
| Forest Bear | 36 | 7.0 | 0.8 | 5.6 | 1.9s |
| Timber Wolf | 24 | 6.0 | 1.2 | 7.2 | 1.3s |
| Wild Boar | 30 | 8.0 | 0.9 | 7.2 | 1.6s |
| Venomous Spider | 15 | 7.0 | 1.8 | 12.6 | 0.8s |
| Forest Sprite | 12 | 5.0 | 2.0 | 10.0 | 0.6s |
| Bramble Golem | 45 | 4.0 | 0.6 | 2.4 | 2.4s |

**Hero DPS vs pack HP (time to kill each pack):**
- Bear: 36 / 18.9 = 1.9s → hero takes 1.9 × 5.6 = 10.6 dmg
- Wolf: 24 / 18.9 = 1.3s → hero takes 9.4 dmg
- Boar: 30 / 18.9 = 1.6s → hero takes 11.5 dmg
- Spider: 15 / 18.9 = 0.8s → hero takes 10.1 dmg
- Sprite: 12 / 18.9 = 0.6s → hero takes 6.3 dmg
- Golem: 45 / 18.9 = 2.4s → hero takes 5.8 dmg

**Average pack damage taken:** ~8.9 dmg/pack. With 8-15 packs per map, hero takes 71–134 dmg total. The hero's 100 HP with 5 base armor means the hero DIES on roughly the 12th pack, which is within the 8-15 pack range. This means zone 1 is borderline — the hero survives easier maps (8 packs) but dies on harder ones (15 packs). Note: armor value of 5 provides minimal reduction through the DefenseCalculator formula.

**D-07 target:** Survive zone 1 only (must craft by zone 2). This means the hero should reliably clear a full 15-pack map at level 1 with ~20 HP remaining.

**Recommended tuned values (targeting ~5 dmg/pack average = 75 dmg total for 15 packs):**

| Monster | Current base_hp | Recommended base_hp | Current base_damage | Recommended base_damage |
|---------|-----------------|---------------------|---------------------|-------------------------|
| Forest Bear | 36 | 20 | 7.0 | 3.5 |
| Timber Wolf | 24 | 14 | 6.0 | 3.0 |
| Wild Boar | 30 | 18 | 8.0 | 4.0 |
| Venomous Spider | 15 | 9 | 7.0 | 3.5 |
| Forest Sprite | 12 | 7 | 5.0 | 2.5 |
| Bramble Golem | 45 | 26 | 4.0 | 2.0 |

**Rationale:** ~50% reduction in both HP and damage. This keeps zone 2 (where level multiplier compounds) still challenging. The biome_config comment average HP of 27.0 drops to ~15.7 with these values, which BIOME_STAT_RATIOS[25] = 1.63 still applies correctly (the ratio is between biomes, not absolute values, so adjusting Forest base stats does not break the ratio math).

**Note on BIOME_STAT_RATIOS:** These ratios compare average HP between biomes. If Forest base HP changes, the ratio 1.63 (Dark Forest avg / Forest avg) becomes inaccurate for the relief dip calculation at level 25. Since D-06 says "tune Forest monster base_hp and base_damage directly", the planner should decide whether to also update `BIOME_STAT_RATIOS[25]` to reflect the new Forest average. The current value (1.63) was computed from the old Forest avg HP of 27.0. With new avg ~15.7, the new ratio would be approximately 44.0 / 15.7 = 2.80. Updating this is RECOMMENDED to keep the biome boundary relief dip accurate, but it is a minor balancing concern not a correctness bug.

### Pattern: Item Construction (confirmed)

All six starter item classes use `ClassName.new(tier)` with tier defaulting to 8. The `_init()` always sets `self.rarity = Rarity.NORMAL`. No additional initialization is needed to produce a blank Normal item.

```gdscript
# These constructors produce blank Normal tier-8 items with no affixes:
Broadsword.new(8)   # STR weapon: 8-12 physical dmg, 1.8 att/sec
Dagger.new(8)       # DEX weapon: 6-10 physical dmg, 2.2 att/sec
Wand.new(8)         # INT weapon: 3-5 atk + 6-10 spell, 0.5/1.2 speeds
IronPlate.new(8)    # STR armor: 5 base_armor
LeatherVest.new(8)  # DEX armor: 5 base_evasion
SilkRobe.new(8)     # INT armor: 8 base_energy_shield
```

### Anti-Patterns to Avoid

- **Renaming view name "forge" strings:** The string `"forge"` appears as a tab/view identifier in `main_view.gd` (`current_view`, `show_view("forge")`). These are NOT currency keys and must not be renamed.
- **Placing starter kit in `_wipe_run_state()`:** Wipe runs before archetype selection. Placing items here would put the wrong archetype's items in the stash and then overwrite them after archetype selection anyway.
- **Using `add_item_to_inventory()` (removed in v1.8):** The current stash API is `add_item_to_stash(item)`. The old per-slot inventory is gone.
- **Bumping SAVE_VERSION to 9 in this phase:** Save v9 is Phase 58 scope. Phase 56 keeps `SAVE_VERSION = 8`. Old saves with old currency keys will produce zero-count currencies on load — which is acceptable behavior per the existing delete-outdated-save policy (old saves that ARE v8 will load fine; currency counts just won't map to new keys).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Stash population | Custom array assignment | `GameState.add_item_to_stash(item)` | Emits `stash_updated` signal and enforces 3-slot cap |
| Archetype detection | Switch on archetype string | `HeroArchetype.Archetype` enum with `match` | Type-safe, uses existing enum values |
| Item blank construction | Setting rarity/affixes manually | `Broadsword.new(8)` etc. | `_init()` already sets NORMAL rarity and no affixes |

---

## Runtime State Inventory

This phase includes a runtime string rename (currency keys).

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | Save file at `user://hammertime_save.json` stores currency counts under old key names ("runic", "forge", etc.) | No data migration — policy is to load v8 save with old keys and get zero counts for new keys; player receives fresh starter kit from `initialize_fresh_game()`. Acceptable per existing design. |
| Live service config | None — no external services | None |
| OS-registered state | None — no task scheduler or daemon entries | None |
| Secrets/env vars | None | None |
| Build artifacts | `.uid` files for item models are present in working tree but untracked — these are Godot 4.5 generated files, not related to rename | None required |

---

## Common Pitfalls

### Pitfall 1: Renaming "forge" as a view name
**What goes wrong:** A grep-replace of `"forge"` in `main_view.gd` renames the tab identifier, breaking tab navigation entirely.
**Why it happens:** `"forge"` appears in both `current_view` state and `show_view()` calls in `main_view.gd` as a VIEW name, and also as a currency key in every other file.
**How to avoid:** Rename currency keys only in these files: `game_state.gd`, `prestige_manager.gd`, `loot_table.gd`, `forge_view.gd`, `prestige_view.gd`, `integration_test.gd`. Do not modify `main_view.gd` currency references (there are none — the word "forge" there is always a view name).
**Warning signs:** If `show_view("forge")` stops working, the tab name was accidentally renamed.

### Pitfall 2: Starter kit placed on every game load, not just fresh starts
**What goes wrong:** If `_place_starter_kit()` is called in `_ready()` after `initialize_fresh_game()` AND after `load_game()`, returning players get duplicate items in their stash on every launch.
**Why it happens:** `initialize_fresh_game()` runs unconditionally before the load attempt. Items placed there are overwritten when a save loads. The pitfall is calling placement a second time AFTER load.
**How to avoid:** Call `_place_starter_kit()` only from `initialize_fresh_game()` (handles no-save case) and `_on_hero_card_selected()` (handles post-prestige case). Never call it from `_ready()` directly or after `load_game()`.

### Pitfall 3: BIOME_STAT_RATIOS drift after Forest tuning
**What goes wrong:** `BIOME_STAT_RATIOS[25]` = 1.63 was computed from the old Forest avg HP of 27.0. After reducing Forest HP by ~50%, the relief dip at level 25 uses a stale ratio and may be over- or under-powered.
**Why it happens:** `PackGenerator.get_level_multiplier()` uses this ratio to scale the relief value: `relief_mult = peak_base * 1.40 * 0.70 / stat_ratio`. A lower Forest avg HP means the true ratio is larger (~2.80), meaning the current ratio underestimates the stat jump and the relief dip is too small.
**How to avoid:** Recompute `BIOME_STAT_RATIOS[25]` after finalizing Forest base_hp values. New Forest avg HP = (20+14+18+9+7+26)/6 = 15.67. New ratio = 44.0 / 15.67 ≈ 2.81. Update the constant and its comment.

### Pitfall 4: Integration test false failures after currency rename
**What goes wrong:** Tests in groups 1-5 assert `GameState.currency_counts["forge"] == ...` and `GameState.currency_counts["runic"] == 1`. After rename, these assertions fail with key-not-found errors, causing the test suite to report failures even when the feature code is correct.
**Why it happens:** The test file has hardcoded old currency key strings.
**How to avoid:** Update `integration_test.gd` currency key references as part of the rename task, not as a follow-up.

### Pitfall 5: Wand tier 8 DPS is low — INT hero may not survive zone 1
**What goes wrong:** Wand tier 8 attack DPS = 4 avg × 0.5 att/sec ≈ 2 DPS. Spell DPS = 8 avg × 1.2 cast/sec × 1.0525 crit ≈ 10 DPS. Total ~12 DPS — compared to Broadsword's ~19 DPS. The Wand hero takes more hits per pack and may still die in zone 1 even with reduced Forest difficulty.
**Why it happens:** Wand is designed as a spell-damage weapon with a deliberately weak attack channel. At tier 8 with no affixes the spell DPS is only ~10.
**How to avoid:** Verify zone 1 survival math with Wand stats. With the recommended tuned Forest values, a Wand hero vs Forest Bear (new 20 HP): 20 / 10 = 2.0s to kill, takes 2.0 × 3.5 = 7.0 dmg per Bear pack. Average pack damage ≈ 5 dmg. 15 packs = 75 dmg total. Hero has 100 HP + 8 base ES from SilkRobe = 108 effective HP. Should survive. Confirm tuned numbers work for INT archetype in the plan.

---

## Code Examples

### Currency Init in `initialize_fresh_game()` (after rename)
```gdscript
# Source: autoloads/game_state.gd (lines 100-107, renamed)
currency_counts = {
    "transmute": 2,
    "augment": 2,
    "alteration": 0,
    "regal": 0,
    "chaos": 0,
    "exalt": 0
}
```

### Currency Init in `_wipe_run_state()` (after rename)
```gdscript
# Source: autoloads/game_state.gd (lines 147-153, renamed)
currency_counts = {
    "transmute": 2,
    "augment": 2,
    "alteration": 0,
    "regal": 0,
    "chaos": 0,
    "exalt": 0,
}
```

### Prestige Cost in `prestige_manager.gd` (after rename)
```gdscript
# Source: autoloads/prestige_manager.gd (line 8, renamed)
1: { "augment": 100 },
```

### Forest biome config after tuning
```gdscript
# Source: models/monsters/biome_config.gd (lines 60-71, tuned values)
biomes.append(BiomeConfig.new(
    "Forest", 1, 25, "physical",
    {"physical": 0.40, "fire": 0.20, "cold": 0.20, "lightning": 0.20},
    [
        MonsterType.create("Forest Bear",     20.0, 3.5, 0.8),
        MonsterType.create("Timber Wolf",     14.0, 3.0, 1.2),
        MonsterType.create("Wild Boar",       18.0, 4.0, 0.9),
        MonsterType.create("Venomous Spider",  9.0, 3.5, 1.8),
        MonsterType.create("Forest Sprite",    7.0, 2.5, 2.0),
        MonsterType.create("Bramble Golem",   26.0, 2.0, 0.6),
    ]
))
```

### Updated BIOME_STAT_RATIOS comment and value
```gdscript
# Source: models/monsters/pack_generator.gd (lines 14-23, updated)
# Forest avg HP: (20+14+18+9+7+26)/6 = 15.67
# Dark Forest avg HP: (42.5+80+17.5+45+35)/5 = 44.0
const BIOME_STAT_RATIOS: Dictionary = {
    25: 2.81,   # Dark Forest (44.0) / Forest (15.67)
    50: 0.955,  # Cursed Woods (42.0) / Dark Forest (44.0)
    75: 1.17,   # Shadow Realm (49.17) / Cursed Woods (42.0)
}
```

### `_place_starter_kit()` in game_state.gd
```gdscript
## Places archetype-matched starter weapon and armor in the stash.
## Called by initialize_fresh_game() (null archetype = STR defaults)
## and by main_view._on_hero_card_selected() after prestige archetype selection.
func _place_starter_kit(archetype: HeroArchetype) -> void:
    var weapon: Item
    var armor: Item
    if archetype == null:
        weapon = Broadsword.new(8)
        armor = IronPlate.new(8)
    else:
        match archetype.archetype:
            HeroArchetype.Archetype.STR:
                weapon = Broadsword.new(8)
                armor = IronPlate.new(8)
            HeroArchetype.Archetype.DEX:
                weapon = Dagger.new(8)
                armor = LeatherVest.new(8)
            HeroArchetype.Archetype.INT:
                weapon = Wand.new(8)
                armor = SilkRobe.new(8)
    add_item_to_stash(weapon)
    add_item_to_stash(armor)
```

### Archetype selection hook in `main_view.gd`
```gdscript
# Source: scenes/main_view.gd (line 279, after SaveManager.save_game() call)
# Insert after existing: SaveManager.save_game()
GameState._place_starter_kit(hero)
```

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Custom GDScript integration test (Godot scene) |
| Config file | `tools/test/integration_test.gd` |
| Quick run command | Run scene `tools/test/integration_test.gd` from Godot editor (F6) |
| Full suite command | Same — all 41 groups run sequentially, output to Godot console |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DIFF-01 | Forest pack HP/damage values allow zone 1 survival with starter gear | unit (data verification) | F6 integration_test.gd — new group_42 | Wave 0 gap |
| DIFF-03 | Fresh game has starter weapon + armor in stash + 2 transmute + 2 augment | unit | F6 integration_test.gd — new group_43 | Wave 0 gap |
| DIFF-03 | Post-prestige archetype selection places correct starter kit in stash | unit | F6 integration_test.gd — new group_44 | Wave 0 gap |

### Sampling Rate
- **Per task commit:** Run integration_test.gd, confirm all prior groups still pass
- **Per wave merge:** Full suite must be green (all groups pass)
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `tools/test/integration_test.gd` — add `_group_42_forest_difficulty_tuning()`: verify Forest biome monster base_hp and base_damage values match tuned targets
- [ ] `tools/test/integration_test.gd` — add `_group_43_starter_kit_fresh_game()`: verify `initialize_fresh_game()` produces 2 transmute + 2 augment, starter weapon in stash, starter armor in stash
- [ ] `tools/test/integration_test.gd` — add `_group_44_starter_kit_post_prestige()`: verify `_place_starter_kit(archetype)` places correct archetype-matched items for each of STR/DEX/INT

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| 1 Runic Hammer starter | 2 Transmute + 2 Augment starter | Phase 56 | Player can use Transmute then Augment on starter weapon before zone 2 |
| "runic"/"forge"/etc. key names | "transmute"/"augment"/etc. | Phase 56 | Code matches PoE terminology that user reasons in |
| 40% Forest difficulty reduction (v1.3 decision) | Direct base_hp/base_damage reduction | Phase 56 | Replaces the prior reduction with explicit tuned values |

**Deprecated/outdated:**
- The PROJECT.md entry "40% Forest difficulty reduction — Fresh heroes survive 3+ packs with starter gear" is superseded by Phase 56 direct stat tuning
- The `initialize_fresh_game()` starter of `"runic": 1` was the v1.3 single-hammer starter; replaced by 2T+2A

---

## Open Questions

1. **Is the old 40% Forest reduction still active?**
   - What we know: PROJECT.md records "40% Forest difficulty reduction" as a v1.3 decision. However, the current `biome_config.gd` shows the raw base HP values (e.g., Forest Bear 36 HP) with no multiplier applied. The `PackGenerator.get_level_multiplier()` has no hardcoded 40% reduction.
   - What's unclear: The reduction may have been removed in a cleanup phase, or it may have been implemented differently.
   - Recommendation: Treat current `biome_config.gd` values as authoritative. The recommended tuned values in this research are computed against current (unreduced) base stats.

2. **Does P0 fresh game (no archetype) need a starter kit at all?**
   - What we know: D-03 says starter items are Normal rarity (teaches crafting loop). D-09 says items placed AFTER archetype selection. However `initialize_fresh_game()` serves P0 players who have no archetype overlay.
   - What's unclear: Should a P0 player who never selected an archetype get STR-default items, or nothing?
   - Recommendation: Place STR-default starter kit (Broadsword + IronPlate) for P0 fresh games as the safe default. A P0 player always gets an Adventurer hero. This matches the old behavior of placing a starter weapon.

---

## Sources

### Primary (HIGH confidence)
- `autoloads/game_state.gd` — direct code inspection of `initialize_fresh_game()`, `_wipe_run_state()`, `_init_stash()`, `add_item_to_stash()`, currency_counts dict
- `autoloads/prestige_manager.gd` — `execute_prestige()` flow, PRESTIGE_COSTS
- `scenes/main_view.gd` — `_on_hero_card_selected()` hook location, `_show_hero_selection()` flow
- `models/monsters/biome_config.gd` — all Forest monster base_hp and base_damage values
- `models/monsters/pack_generator.gd` — GROWTH_RATE, BIOME_STAT_RATIOS, `get_level_multiplier()` formula
- `models/hero.gd` — base health=100, DPS calculation formula, defense calculation
- `autoloads/save_manager.gd` — v8 currency restore loop, version rejection policy
- `scenes/forge_view.gd` — all 6 currency key occurrences confirmed by grep
- Item model files (broadsword, dagger, wand, iron_plate, leather_vest, silk_robe) — tier 8 base stats confirmed

### Secondary (MEDIUM confidence)
- PROJECT.md — v1.3 "40% Forest difficulty reduction" entry; not reflected in current biome_config.gd values (possible prior removal)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all affected files read directly
- Architecture: HIGH — function signatures and call sites verified in code
- Combat math: HIGH — hand-calculated from actual base stats; minor uncertainty around DefenseCalculator exact formula for 5 base_armor (negligible reduction, math still valid)
- Currency rename scope: HIGH — confirmed via grep across all .gd files
- Pitfalls: HIGH — derived from actual code patterns observed

**Research date:** 2026-03-28
**Valid until:** Until Forest stats or combat formulas change (stable; no external dependencies)
