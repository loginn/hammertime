# Phase 58: New Hammers & Save v9 — Research

**Researched:** 2026-03-29
**Domain:** GDScript currency model, item rarity system, save/load serialization
**Confidence:** HIGH — all findings from direct source code inspection

---

## Summary

Phase 58 has two independent workstreams that share one plan boundary: (1) new crafting semantics for two existing currency keys, and (2) bumping save format from v8 to v9 to persist the stash and the two new currency keys as first-class fields.

**Critical discovery — naming mismatch between keys and classes:** The `alteration` and `regal` currency *keys* already exist throughout the codebase (GameState, forge_view.gd, loot_table.gd), but they are currently wired to **TackHammer** (add one mod to Magic) and **GrandHammer** (add one mod to Rare) respectively. Phase 58 requires rewriting those two class implementations to deliver the intended PoE-style behaviors: Alteration rerolls all mods (Magic only), Regal upgrades Magic to Rare by adding one mod. The class names themselves do not need to change; only the logic inside `tack_hammer.gd` and `grand_hammer.gd` changes, plus tooltip text in `forge_view.gd`.

**Save v9 is mostly additive.** The stash data was deliberately deferred from v8 with explicit `# Not persisted until Phase 58` comments in game_state.gd. The v8 compat shims (`crafting_inventory` and `crafting_bench_type` properties) exist to let SaveManager v8 write/read the bench — Phase 58 replaces those with proper stash serialization and removes the shims.

**Primary recommendation:** Split into two plans — (1) rewrite TackHammer and GrandHammer logic with forge_view tooltip updates and integration tests; (2) v9 save format: stash serialization, bench serialization, shim removal, version bump to 9, and integration tests.

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CRFT-01 | Alteration Hammer rerolls all mods at current rarity (Magic only; rejected on Normal/Rare) | TackHammer.gd rewrite: clear prefixes/suffixes then re-add; can_apply checks rarity == MAGIC |
| CRFT-02 | Regal Hammer upgrades Magic to Rare by adding a single mod (3-mod Rare) | GrandHammer.gd rewrite: rarity = RARE then add one mod; can_apply checks rarity == MAGIC |
| CRFT-03 | Save format v9 persists new hammer currencies and 3-slot stash | SaveManager: SAVE_VERSION = 9, stash serialization in _build_save_data and _restore_state; remove v8 shims |
</phase_requirements>

---

## Standard Stack

This is a Godot 4.x GDScript project. No external libraries are involved. All patterns are first-party GDScript.

### Core Types in Scope

| File | Class | Role |
|------|-------|------|
| `models/currencies/tack_hammer.gd` | `TackHammer` | Currently implements add-one-mod-to-Magic; rewritten for CRFT-01 |
| `models/currencies/grand_hammer.gd` | `GrandHammer` | Currently implements add-one-mod-to-Rare; rewritten for CRFT-02 |
| `models/currencies/currency.gd` | `Currency` | Base class — `can_apply()`, `_do_apply()`, `get_error_message()` template |
| `autoloads/save_manager.gd` | SaveManager | `SAVE_VERSION`, `_build_save_data()`, `_restore_state()`, `import_save_string()` |
| `autoloads/game_state.gd` | GameState | `stash: Dictionary`, `crafting_bench: Item`, shim properties |
| `models/items/item.gd` | Item | `Rarity` enum, `prefixes`, `suffixes`, `add_prefix()`, `add_suffix()`, `update_value()` |
| `scenes/forge_view.gd` | ForgeView | `hammer_descriptions` dict; tooltip strings for alteration/regal |
| `tools/test/integration_test.gd` | — | Integration test harness; new groups follow `_group_N_name()` convention |

---

## Architecture Patterns

### Currency Template Method (established)

All hammers follow the `Currency` base class template:

```gdscript
# Source: models/currencies/currency.gd
func apply(item: Item) -> bool:
    if not can_apply(item):
        return false
    _do_apply(item)
    return true
```

Subclasses override three methods:
- `can_apply(item)` — rarity/state gate
- `get_error_message(item)` — human-readable rejection reason shown by `_show_forge_error()`
- `_do_apply(item)` — the mutation (called only if can_apply passed)

The caller in `forge_view.gd:update_item()` calls `selected_currency.can_apply()` and `selected_currency.apply()` — no changes to the forge_view crafting flow are needed for CRFT-01/02.

### CRFT-01: Alteration Hammer Rewrite (TackHammer)

**Current behavior:** adds one mod to a Magic item that has room.
**Required behavior:** rerolls all mods — clears existing prefixes/suffixes, then re-adds 1-2 mods (same mod count range as Transmute/RunicHammer).

Key constraint: Magic items have max 1 prefix and 1 suffix (from `Item.RARITY_LIMITS`). The reroll must keep rarity = MAGIC throughout. The existing RunicHammer `_do_apply` is the template for "set Magic, add 1-2 mods" — Alteration reuses the same mod-adding logic without the rarity change:

```gdscript
# Pattern: clear existing mods then re-add (same logic as RunicHammer but no rarity change)
func can_apply(item: Item) -> bool:
    return item.rarity == Item.Rarity.MAGIC

func _do_apply(item: Item) -> void:
    # Clear existing mods — rarity stays MAGIC
    item.prefixes.clear()
    item.suffixes.clear()
    # Re-add 1-2 mods (same distribution as Transmute)
    var mod_count = 1 if randf() < 0.7 else 2
    for i in range(mod_count):
        var choose_prefix = randi_range(0, 1) == 0
        if choose_prefix:
            if not item.add_prefix():
                item.add_suffix()
        else:
            if not item.add_suffix():
                item.add_prefix()
    item.update_value()
```

Error message must indicate "Magic only": `"Alteration Hammer can only be used on Magic items"`

### CRFT-02: Regal Hammer Rewrite (GrandHammer)

**Current behavior:** adds one mod to a Rare item with room.
**Required behavior:** upgrades Magic → Rare by adding a single mod (result: 3-mod Rare from a 2-mod Magic base).

Key constraint: When applied, item already has 1-2 mods (Magic). After rarity is set to RARE the limits expand to 3 prefixes / 3 suffixes, so add_prefix()/add_suffix() will succeed. The resulting item has 2 existing + 1 new = 3 mods, fulfilling the "3-mod Rare" success criterion.

```gdscript
# Pattern: set rarity then add one mod (similar to ForgeHammer but single mod, from Magic)
func can_apply(item: Item) -> bool:
    return item.rarity == Item.Rarity.MAGIC

func _do_apply(item: Item) -> void:
    item.rarity = Item.Rarity.RARE
    # Add exactly one mod (prefix or suffix, random choice with fallback)
    var choose_prefix = randi_range(0, 1) == 0
    if choose_prefix:
        if not item.add_prefix():
            item.add_suffix()
    else:
        if not item.add_suffix():
            item.add_prefix()
    item.update_value()
```

Error message: `"Regal Hammer can only be used on Magic items"`

### Forge View Tooltip Updates

`forge_view.gd` has a `hammer_descriptions` dictionary (lines 71-83). The current descriptions for `"alteration"` and `"regal"` reflect the old TackHammer/GrandHammer semantics:

```gdscript
# CURRENT (wrong semantics):
"alteration": "Adds one random mod to a magic item.\nRequires: Magic rarity with room for mods",
"regal": "Adds one random mod to a rare item.\nRequires: Rare rarity with room for mods",

# REQUIRED (new semantics):
"alteration": "Rerolls all mods on a magic item.\nRequires: Magic rarity",
"regal": "Upgrades a magic item to rare\nby adding one mod.\nRequires: Magic rarity",
```

No other UI changes are needed — the buttons, icons, and wiring already use `"alteration"` and `"regal"` keys.

### Save v9 Architecture

**What v8 currently persists (save_manager.gd):**
- `crafting_inventory` — via the shim property (reads `crafting_bench` mapped into slot dict)
- `crafting_bench_type` — via the shim property (ignored on set)
- Does NOT persist `stash`

**What v9 must persist:**
- `crafting_bench` — the single bench item (replaces `crafting_inventory` + `crafting_bench_type`)
- `stash` — the 5-key dictionary of item arrays

**Shims to remove (game_state.gd lines 14-38):**
- `crafting_inventory` computed property
- `crafting_bench_type` computed property

**_build_save_data() changes:**
```gdscript
# Remove:
var crafting_inv := {}
for type_name in GameState.crafting_inventory: ...
"crafting_inventory": crafting_inv,
"crafting_bench_type": GameState.crafting_bench_type,

# Add:
"crafting_bench": GameState.crafting_bench.to_dict() if GameState.crafting_bench != null else null,
"stash": _serialize_stash(GameState.stash),
```

**Stash serialization helper:**
```gdscript
func _serialize_stash(stash: Dictionary) -> Dictionary:
    var result := {}
    for slot_type in stash:
        var arr: Array = []
        for item in stash[slot_type]:
            if item != null:
                arr.append(item.to_dict())
            else:
                arr.append(null)
        result[slot_type] = arr
    return result
```

**_restore_state() changes:**
```gdscript
# Remove crafting_inventory restore block (lines 138-147)
# Remove crafting_bench_type restore (line 147)

# Add bench restore:
var bench_data = data.get("crafting_bench", null)
if bench_data != null and bench_data is Dictionary:
    GameState.crafting_bench = Item.create_from_dict(bench_data)
else:
    GameState.crafting_bench = null

# Add stash restore:
GameState._init_stash()  # reset to empty arrays
var saved_stash: Dictionary = data.get("stash", {})
for slot_type in ["weapon", "helmet", "armor", "boots", "ring"]:
    var slot_arr = saved_stash.get(slot_type, [])
    if slot_arr is Array:
        for item_data in slot_arr:
            if item_data != null and item_data is Dictionary:
                var item = Item.create_from_dict(item_data)
                if item != null:
                    GameState.stash[slot_type].append(item)
            else:
                GameState.stash[slot_type].append(null)
```

**Version check:** Strict rejection — any save with version < 9 triggers `delete_save()` and returns false (consistent with existing policy in `load_game()`). The `load_game()` check is already version-agnostic: `if saved_version < SAVE_VERSION`. Bumping `SAVE_VERSION` to 9 is the only change needed there.

**Import rejection:** `import_save_string()` already rejects `import_version < SAVE_VERSION` with `"outdated_version"`. No change needed beyond the constant bump.

### Integration Test Groups

The test file uses sequential group numbering. Last group is `_group_47_stash_tooltip_text` (group 47). New groups:

- **Group 48**: CRFT-01 — Alteration Hammer behavior (reroll Magic, reject Normal/Rare)
- **Group 49**: CRFT-02 — Regal Hammer behavior (upgrade Magic to Rare, reject Normal/Rare)
- **Group 50**: CRFT-03 — Save v9 round-trip (stash, bench, alteration/regal counts, archetype)

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| Item mod serialization | Custom dict builder | `item.to_dict()` and `Item.create_from_dict()` — already handle rarity, tier, prefixes, suffixes, implicit |
| Mod clearing for reroll | Iterate and remove | `item.prefixes.clear()` / `item.suffixes.clear()` — GDScript Array method, safe and immediate |
| Stash null-gap handling | Custom insert logic | Already in `GameState.add_item_to_stash()` — fills null gaps, not needed in save restore (restore appends in order) |
| Save file checksums | Custom hash | `export_save_string()` uses `base64.md5_text()` — already implemented, no changes needed |

---

## Common Pitfalls

### Pitfall 1: Forgetting that MAGIC item can have 1 prefix AND 1 suffix

**What goes wrong:** Alteration `_do_apply` clears mods and adds 2 new ones. If both new picks try to add a prefix, the second call to `add_prefix()` returns false (at capacity) and falls through to `add_suffix()`. The item ends up with 1 prefix + 1 suffix which is correct — but only if the fallback logic matches RunicHammer exactly.

**How to avoid:** Use the exact same 70/30 + fallback pattern from RunicHammer. Do not simplify to "just add prefix then suffix" — that always produces 2-mod items and removes the 1-mod case.

### Pitfall 2: Regal applied to a 2-prefix Magic item

**What goes wrong:** A 2-mod Magic item could have 1 prefix + 1 suffix, or theoretically 2 prefixes if add logic allowed it (it doesn't — max_prefixes() == 1 for MAGIC). After rarity is set to RARE, the item has room for 2 more prefixes and 2 more suffixes. `add_prefix()` / `add_suffix()` both succeed. The single-mod add logic (random choice with fallback) handles this correctly.

**How to avoid:** Confirm that Magic items always have at most 1 prefix + 1 suffix before upgrade. The RARITY_LIMITS constant enforces this: `Rarity.MAGIC: { "prefixes": 1, "suffixes": 1 }`. No special case needed.

### Pitfall 3: Stash null gaps in save/load

**What goes wrong:** The stash uses null gaps (items[index] = null) when a slot is moved to bench. Serializing arrays with null entries to JSON and restoring them requires explicit null handling. `JSON.stringify` will write JSON `null` for GDScript null values; `JSON.parse_string` returns null for JSON null. The restore loop must handle `item_data == null` without calling `create_from_dict`.

**How to avoid:** Check `if item_data != null and item_data is Dictionary` before calling `create_from_dict`. Append null for null entries to preserve slot positions.

### Pitfall 4: Removing shims before save_manager is updated

**What goes wrong:** The `crafting_inventory` and `crafting_bench_type` shims in game_state.gd exist because save_manager.gd references them. If the shims are removed before save_manager is updated to use `crafting_bench` and `stash` directly, the game crashes at save/load.

**How to avoid:** Update save_manager.gd and game_state.gd in the same task (or ensure save_manager is updated first). The plan should make both edits atomically.

### Pitfall 5: Test group numbering

**What goes wrong:** Adding group 48 without calling it from `_ready()` (the test harness calls all groups in sequence from `_ready()`).

**How to avoid:** Add both the function definition AND the call in `_ready()`. The last existing call is `_group_47_stash_tooltip_text()`.

### Pitfall 6: Tooltip descriptions still describe old behavior

**What goes wrong:** `forge_view.gd`'s `hammer_descriptions` for `"alteration"` and `"regal"` say "Adds one random mod..." which describes the old TackHammer/GrandHammer semantics. The UI shows this description on hover.

**How to avoid:** Update both tooltip strings in `hammer_descriptions` as part of the CRFT-01/02 plan.

---

## Code Examples

### Existing RunicHammer for reference (reroll source pattern)

```gdscript
# Source: models/currencies/runic_hammer.gd
func _do_apply(item: Item) -> void:
    item.rarity = Item.Rarity.MAGIC
    var mod_count = 1 if randf() < 0.7 else 2
    for i in range(mod_count):
        var choose_prefix = randi_range(0, 1) == 0
        if choose_prefix:
            if not item.add_prefix():
                item.add_suffix()
        else:
            if not item.add_suffix():
                item.add_prefix()
    item.update_value()
```

Alteration reuses this mod-addition loop without the `item.rarity = Item.Rarity.MAGIC` line (rarity already MAGIC) and prepends `item.prefixes.clear()` + `item.suffixes.clear()`.

### Existing ForgeHammer for reference (rarity-upgrade pattern)

```gdscript
# Source: models/currencies/forge_hammer.gd
func _do_apply(item: Item) -> void:
    item.rarity = Item.Rarity.RARE
    var mod_count = randi_range(4, 6)
    for i in range(mod_count):
        ...
    item.update_value()
```

Regal reuses the rarity-upgrade line but replaces the loop with a single-mod add (same as existing TackHammer loop body).

### Item rarity limits (no changes needed)

```gdscript
# Source: models/items/item.gd
const RARITY_LIMITS: Dictionary = {
    Rarity.NORMAL: { "prefixes": 0, "suffixes": 0 },
    Rarity.MAGIC: { "prefixes": 1, "suffixes": 1 },
    Rarity.RARE: { "prefixes": 3, "suffixes": 3 },
}
```

A 2-mod Magic item (1 prefix + 1 suffix) becomes a 3-mod Rare after Regal adds 1 more mod.

### v8 save _build_save_data (current — shows what to replace)

```gdscript
# Source: autoloads/save_manager.gd lines 91-114
# Currently uses crafting_inventory shim and crafting_bench_type shim
# Phase 58 replaces with direct stash + crafting_bench serialization
return {
    "version": SAVE_VERSION,   # bump to 9
    ...
    "crafting_inventory": crafting_inv,      # REMOVE
    "crafting_bench_type": GameState.crafting_bench_type,  # REMOVE
    ...
    # ADD:
    # "crafting_bench": GameState.crafting_bench.to_dict() if ... else null,
    # "stash": _serialize_stash(GameState.stash),
}
```

---

## State of the Art

| Old (v8) | New (v9) | Impact |
|----------|----------|--------|
| `crafting_inventory` shim + `crafting_bench_type` shim | `crafting_bench` item dict | Cleaner serialization, removes 25 lines of compat code |
| Stash not persisted ("Not persisted until Phase 58") | `stash` dict of item arrays | Stash survives save/load |
| TackHammer adds one mod to Magic | AlterationHammer rerolls all mods on Magic | New crafting loop: iterate on existing mods |
| GrandHammer adds one mod to Rare | RegalHammer graduates Magic to Rare | New crafting decision: push Magic items to Rare |

**Deprecated/removed in Phase 58:**
- `crafting_inventory` computed property (game_state.gd lines 14-30)
- `crafting_bench_type` computed property (game_state.gd lines 32-38)
- `crafting_inventory` restore block in save_manager.gd (lines 138-147)
- `crafting_bench_type` restore line in save_manager.gd (line 147)

---

## Open Questions

1. **Currency name displayed in error toasts**
   - What we know: `get_error_message()` returns a string; `_show_forge_error()` in forge_view.gd displays it with a red fade tween
   - What's unclear: The class `currency_name` fields still say "Tack Hammer" and "Grand Hammer" — should they be updated to "Alteration Hammer" and "Regal Hammer"?
   - Recommendation: Yes, update `currency_name` in both files. The `currency_name` field is used in `print()` calls in forge_view.gd (`"Applied " + selected_currency.currency_name`) so it should reflect the PoE naming.

2. **Starter alteration/regal counts after prestige**
   - What we know: `_wipe_run_state()` resets currencies to `{"transmute": 2, "augment": 2, "alteration": 0, "regal": 0, ...}`
   - What's unclear: The REQUIREMENTS say nothing about starter alteration/regal counts changing
   - Recommendation: Leave at 0 — the existing defaults are correct per the existing game_state.gd.

---

## Validation Architecture

`nyquist_validation` key is absent from `.planning/config.json` — treat as enabled.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Custom GDScript integration test harness |
| Config file | `tools/test/integration_test.gd` (scene file: `tools/test/integration_test.tscn` assumed) |
| Quick run command | Run scene in Godot editor (F6 with test scene active) |
| Full suite command | Same — all groups run in `_ready()` |

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Group | File Exists? |
|--------|----------|-----------|-------|-------------|
| CRFT-01 | Alteration rerolls Magic mods; rejected on Normal/Rare | unit | Group 48 | No — Wave 0 |
| CRFT-02 | Regal upgrades Magic to Rare (+1 mod); rejected on Normal/Rare | unit | Group 49 | No — Wave 0 |
| CRFT-03 | v9 stash + bench + currencies round-trip | integration | Group 50 | No — Wave 0 |

### Wave 0 Gaps

- [ ] `_group_48_alteration_hammer()` in `tools/test/integration_test.gd` — covers CRFT-01
- [ ] `_group_49_regal_hammer()` in `tools/test/integration_test.gd` — covers CRFT-02
- [ ] `_group_50_save_v9_round_trip()` in `tools/test/integration_test.gd` — covers CRFT-03
- [ ] All three group calls added to `_ready()` after existing `_group_47_stash_tooltip_text()` call

---

## Sources

### Primary (HIGH confidence)
- Direct inspection of `autoloads/save_manager.gd` — v8 format, shims, version check logic
- Direct inspection of `autoloads/game_state.gd` — stash structure, currency_counts, shim properties
- Direct inspection of `models/currencies/tack_hammer.gd` — current Magic add-one behavior
- Direct inspection of `models/currencies/grand_hammer.gd` — current Rare add-one behavior
- Direct inspection of `models/currencies/runic_hammer.gd` — reroll mod-add pattern to reuse
- Direct inspection of `models/currencies/currency.gd` — template method contract
- Direct inspection of `models/items/item.gd` — RARITY_LIMITS, add_prefix/add_suffix, to_dict/create_from_dict
- Direct inspection of `scenes/forge_view.gd` — hammer_descriptions, currencies dict, update_item flow
- Direct inspection of `tools/test/integration_test.gd` — last group number (47), test conventions
- Direct inspection of `.planning/phases/52-save-persistence/52-01-PLAN.md` — v8 save migration precedent

### Secondary (MEDIUM confidence)
- STATE.md decisions — Phase 55 stash deferred note, Phase 56 currency rename decisions

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all files read directly from source
- Architecture: HIGH — currency template and save patterns verified from existing code
- Pitfalls: HIGH — derived from known code structure (null gaps, shim ordering)

**Research date:** 2026-03-29
**Valid until:** Until any of the listed source files change
