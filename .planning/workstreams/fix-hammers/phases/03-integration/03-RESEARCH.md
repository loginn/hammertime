# Phase 3: Integration - Research

**Researched:** 2026-04-12
**Domain:** GDScript / Godot 4 — loot table extension, save-format version bump, integration test authoring
**Confidence:** HIGH (all findings verified directly against current source files)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Drop Tuning (INT-01)**
- D-01: Add 3 new entries to `CURRENCY_AREA_GATES`: `"alchemy": 15`, `"annulment": 30`, `"divine": 65`. Also retune `"augment"` gate from 15 to 5.
- D-02: Add 3 new entries to `pack_currency_rules`: `"alchemy": {"chance": 0.20, "max_qty": 1}`, `"annulment": {"chance": 0.15, "max_qty": 1}`, `"divine": {"chance": 0.15, "max_qty": 1}`. Keep existing 6 rules untouched.
- D-03: `ramp_duration` stays at default 12 for all new currencies.
- D-04: Drop chance rationale locked (Alchemy 0.20, Annulment 0.15, Divine 0.15 — see CONTEXT.md §D-04).
- D-05: `max_qty` = 1 for all 3 new currencies.
- D-06: No changes to `roll_pack_tag_currency_drop()`, `PACK_ITEM_DROP_CHANCE`, or rarity anchors.

**Save Format (INT-02)**
- D-07: Bump `SAVE_VERSION` constant in `autoloads/save_manager.gd` from 9 to 10.
- D-08: No migration code — existing delete-and-fresh policy (lines 62-64) handles v9→v10.
- D-09: No new migration functions; `currency_counts` already seeded with all 9 keys in `game_state.gd:97-107`.
- D-10: Group 50 updates: `save_data["version"] == 9` → `== 10`; optionally add v9 rejection assertion; add alchemy/divine/annulment round-trip assertions.
- D-11: No rollback path for v10→v9.

**Integration Tests (INT-03)**
- D-12: Add 7 new test groups: `_group_51_transmute_hammer`, `_group_52_augment_hammer`, `_group_53_alchemy_hammer`, `_group_54_chaos_hammer`, `_group_55_exalt_hammer`, `_group_56_divine_hammer`, `_group_57_annulment_hammer`.
- D-13: Each group has 3 sub-tests: rejection, success, edge.
- D-14: Edge cases per hammer locked (see CONTEXT.md §D-14).
- D-15: Invariant-only assertions — no specific affix names, no specific roll values.
- D-16: No RNG seeding, no loops, no mocking. Pure invariant testing.
- D-17: Call new groups from `_ready()` in numeric order after Group 50 (renamed to `_group_50_save_v10_round_trip`).
- D-18: Group naming comment style locked (see CONTEXT.md §D-18 example).
- D-19: Test setup uses `Broadsword.new(8)`, manipulate rarity/prefixes/suffixes directly.
- D-20: Currency instances created inline per group: `var hammer := AugmentHammer.new()`.

**Plan Layout**
- D-21: 3 plans in 2 waves: Wave 1 (parallel) = 03-01 (loot table) + 03-02 (save bump); Wave 2 (serial) = 03-03 (integration tests).
- D-22: Wave 1 plans touch disjoint files; no cross-plan data contracts.
- D-23: Wave 2 depends on wave 1 only via `SAVE_VERSION = 10` constant.
- D-24: Phase verification via grep checks + one manual F6 run.
- D-25: Integration harness is not CLI-runnable. Structural (grep) verification + user runs F6 once.
- D-26: Phase verification checks that INT-01, INT-02, INT-03 each map to at least one plan via plan frontmatter.

### Claude's Discretion
- Exact variable names inside the 7 new test groups (follow Groups 48/49 style)
- Exact error-message wording in assertions — copy from each currency's `get_error_message()` verbatim
- Whether to split long edge-case tests into helper functions or keep inline (prefer inline)
- Whether wave-1 plans use `gsd:execute-phase --wave 1` or default execution
- Internal ordering of the 7 new groups beyond numeric sequence
- Whether to also test `Currency.apply()` consumed-on-success contract — optional bonus coverage

### Deferred Ideas (OUT OF SCOPE)
- v9→v10 migration path that preserves currency counts
- Headless test runner
- Drop-rate rebalance for existing currencies (Transmute, Alteration, Regal, Chaos, Exalt)
- Currency drop telemetry / logging
- Renaming the 4 creative-named classes (Runic/Tack/Grand/Tag)
- Shared `Currency.roll_random_mods(item, count)` helper
- Test selection / parallel test execution
- Auto-seeding RNG for deterministic tests
- Additional edge cases (Divine on implicits-only, etc.)
- Tag hammer tests
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INT-01 | LootTable drops new currencies (alchemy, divine, annulment) with appropriate area gating | `CURRENCY_AREA_GATES` and `pack_currency_rules` dicts in `loot_table.gd` are the only edit points. `_calculate_currency_chance()` is already generic. Caller `roll_pack_currency_drop()` iterates both dicts by key — adding entries is sufficient, no caller changes needed. |
| INT-02 | Save format updated to persist new currency counts with version bump | `SAVE_VERSION` constant on line 4 is the single edit point. `currency_counts` serialization via `.duplicate()` and restoration via `for currency_type in saved_currencies` loop are both forward-compatible. No code path changes needed. |
| INT-03 | Integration tests verify all 8 base hammer behaviors | Groups 48 (Alteration) and 49 (Regal) are already in the file. 7 new groups (51–57) must be added using the Groups 48/49 shape. Group 50 must be updated from v9 to v10 reference and renamed. All 9 hammer behavior invariants are verifiable from the existing currency `.gd` files. |
</phase_requirements>

## Summary

Phase 3 is a pure wiring phase: three files, zero new abstractions. The prep work is entirely done — all 9 currency classes exist and are correct (Phase 1), the forge UI exposes them (Phase 2 structural work complete), and `currency_counts` already contains all 9 keys (game_state.gd pull-forward). This phase only needs to connect the remaining plumbing: make the new currencies drop, make the save format acknowledge them, and add the missing test coverage.

CONTEXT.md contains 26 locked decisions with specific dict entries, exact line references, and a precise plan layout. Research has validated all of them against the current codebase. **All line numbers and patterns in CONTEXT.md match the current source.** There is one important behavioral nuance to surface for the planner: Groups 48 and 49 in the current file use `assert()` rather than `_check()` for their sub-tests. The new groups must use `_check()` to match the non-aborting harness contract.

**Primary recommendation:** Follow CONTEXT.md decisions verbatim. Research confirms zero drift between the decisions and the codebase. The planner's only job is to translate the 26 decisions into three atomic plan files.

---

## Codebase Validation Results

### VALIDATION: Drop Table (D-01, D-02) — CONFIRMED

**CURRENCY_AREA_GATES** (loot_table.gd lines 21-28) currently contains exactly 6 keys:
```gdscript
"transmute": 1,
"alteration": 1,
"augment": 15,   # <-- D-01 retunes this to 5
"regal": 40,
"chaos": 65,
"exalt": 65,
```
Three entries are missing (`alchemy`, `annulment`, `divine`) exactly as D-01 describes. The `augment` gate is currently 15, confirming the retune to 5 is still needed.

**pack_currency_rules** (loot_table.gd lines 68-75) currently contains exactly 6 keys:
```gdscript
"transmute": {"chance": 0.25, "max_qty": 2},
"alteration": {"chance": 0.25, "max_qty": 2},
"augment":    {"chance": 0.25, "max_qty": 1},
"regal":      {"chance": 0.20, "max_qty": 1},
"chaos":      {"chance": 0.20, "max_qty": 1},
"exalt":      {"chance": 0.20, "max_qty": 1},
```
Three entries are missing (`alchemy`, `annulment`, `divine`) exactly as D-02 describes.

**Caller pattern confirmed**: `roll_pack_currency_drop()` iterates `pack_currency_rules` (line 77: `for currency_name in pack_currency_rules`) and looks up the gate via `CURRENCY_AREA_GATES[currency_name]` (line 78). This means both dicts MUST stay in sync — every key in `pack_currency_rules` must also exist in `CURRENCY_AREA_GATES`. D-01 and D-02 together satisfy this constraint.

**_calculate_currency_chance() is unchanged**: Lines 38-53 are generic. It takes `base_chance`, `area_level`, `unlock_level`, `ramp_duration=12`. Adding new entries in the dicts automatically invokes this logic. No changes to the function needed.

**DRIFT FLAG — None.** Line numbers, dict contents, and call pattern all match CONTEXT.md exactly.

---

### VALIDATION: Save Format (D-07, D-08, D-09) — CONFIRMED

**SAVE_VERSION** is on line 4: `const SAVE_VERSION = 9`. D-07's "line 4, bump to 10" is exact.

**Delete-and-fresh policy** is on lines 61-65:
```gdscript
var saved_version: int = int(data.get("version", 1))
if saved_version < SAVE_VERSION:
    push_warning("SaveManager: Outdated save (v%d), deleting and starting fresh" % saved_version)
    delete_save()
    return false
```
This is a `<` comparison, not `!=`. When SAVE_VERSION becomes 10, any save with version 1–9 triggers the branch. D-08's "policy unchanged, handles v10 correctly" is confirmed.

**currency_counts seeding** (game_state.gd lines 97-107) — all 9 keys confirmed:
```gdscript
currency_counts = {
    "transmute": 2, "augment": 2, "alchemy": 0, "alteration": 0,
    "regal": 0, "chaos": 0, "exalt": 0, "divine": 0, "annulment": 0,
}
```
D-09 is confirmed. The alchemy/divine/annulment keys are already there from the Phase 1 pull-forward. The `_build_save_data()` call to `.duplicate()` (line 95) and the `for currency_type in saved_currencies` loop in `_restore_state()` (line 141) are both key-agnostic. No save-path code changes needed.

**DRIFT FLAG — None.**

---

### VALIDATION: Group 50 (D-10) — CONFIRMED WITH ONE NOTE

Group 50 (`_group_50_save_v9_round_trip`) is at line 2391. The version assertion is on line 2436:
```gdscript
_check(save_data["version"] == 9, "50g: save version is 9")
```
D-10's "assertion `save_data["version"] == 9` → `== 10` (line 2436 or equivalent)" matches exactly — the actual line is 2436.

The function name contains `v9_round_trip` in two places: the function declaration (`func _group_50_save_v9_round_trip()`) and in the final print statement (line 2485: `print("Group 50: Save v9 round-trip -- PASSED")`). D-10 calls for renaming to `_group_50_save_v10_round_trip`. Both the function name and the print string need updating.

The v8 rejection test (line 2479-2480) uses `{"version": 8, ...}` and asserts `< SaveManager.SAVE_VERSION`. After the bump to 10, the integer 8 is still `< 10`, so this assertion stays valid without changes. D-10's note "v8_data sanity check → remains valid because `8 < 10`" is confirmed.

**DRIFT FLAG — None.** Line 2436 matches exactly.

---

### VALIDATION: Groups 48/49 Reference Structure (D-13) — CONFIRMED WITH CRITICAL NOTE

Groups 48 and 49 are at lines 2320–2351 and 2354–2386 respectively.

**CRITICAL NOTE FOR PLANNER:** Groups 48 and 49 use `assert()` (GDScript built-in) rather than `_check()` for their sub-tests. Example from Group 48:
```gdscript
assert(not hammer.can_apply(normal_item), "48a: Alteration rejected on Normal")
assert(hammer.get_error_message(normal_item) == "...", "48a: error msg")
```
Group 50 uses `_check()`. The new groups 51–57 should use `_check()` (not `assert()`), matching the harness's non-aborting accumulator contract as described in TESTING.md and D-15. The `assert()` in Groups 48/49 aborts on failure; `_check()` accumulates and continues. New groups must use `_check()`.

**Pattern confirmed for D-19 (Broadsword.new(8) item setup):**
```gdscript
var magic_item := Broadsword.new(8)
magic_item.rarity = Item.Rarity.MAGIC
magic_item.prefixes.clear()
magic_item.suffixes.clear()
magic_item.add_prefix()
```
This is the exact idiom. `add_prefix()` / `add_suffix()` are used directly on the item to add mods.

**Pattern confirmed for D-20 (inline currency instantiation):** `var hammer := TackHammer.new()` — no fixture sharing.

**Pattern confirmed for D-18 (print marker style):** `print("Group 48: Alteration Hammer — PASSED")` — no trailing newline, em-dash separator.

---

### VALIDATION: _ready() Dispatch List (D-17) — CONFIRMED

Lines 55-60 show the current tail of `_ready()`:
```gdscript
_group_48_alteration_hammer()
_group_49_regal_hammer()
_group_50_save_v9_round_trip()
```
Adding 7 new group calls (51–57) after Group 50 and renaming Group 50 in both places is the complete change. No other dispatch list changes are needed.

---

### VALIDATION: Currency Behavior Invariants (D-14) — CONFIRMED

All 9 hammer classes exist and their behavior is verified. Key invariants for test authoring:

| Hammer | Class | can_apply() condition | get_error_message() — key strings |
|--------|-------|----------------------|-----------------------------------|
| Transmute | RunicHammer | `rarity == NORMAL` | `"Transmute Hammer can only be used on Normal items"` |
| Augment | AugmentHammer | `rarity == MAGIC AND has_room` | `"Augment Hammer can only be used on Magic items"` / `"Magic item has no room for another mod"` |
| Alchemy | AlchemyHammer | `rarity == NORMAL` | `"Alchemy Hammer can only be used on Normal items"` |
| Alteration | TackHammer | `rarity == MAGIC` | `"Alteration Hammer can only be used on Magic items"` |
| Regal | GrandHammer | `rarity == MAGIC` | `"Regal Hammer can only be used on Magic items"` |
| Chaos | ChaosHammer | `rarity == RARE` | `"Chaos Hammer can only be used on Rare items"` |
| Exalt | ExaltHammer | `rarity == RARE AND has_room` | `"Exalt Hammer can only be used on Rare items"` / `"Rare item has no room for another mod"` |
| Divine | DivineHammer | `prefixes.size() > 0 OR suffixes.size() > 0` | `"Item has no mods to reroll"` |
| Annulment | AnnulmentHammer | `prefixes.size() > 0 OR suffixes.size() > 0` | `"Item has no mods to remove"` |

**Edge case invariants from D-14, verified against source:**

- **Transmute edge (D-14):** Second Transmute on a Magic item — rejected. `RunicHammer.can_apply()` checks `rarity == NORMAL`. A Magic item fails this. Error: `"Transmute Hammer can only be used on Normal items"`.

- **Augment edge (D-14):** Magic item with 1 prefix + 1 suffix (full, Magic max is 1/1) — `has_room` is false (both prefix and suffix slots at max). Confirmed from AugmentHammer source: `len(item.prefixes) < item.max_prefixes() or len(item.suffixes) < item.max_suffixes()`. Error: `"Magic item has no room for another mod"`.

- **Alchemy edge (D-14):** Magic or Rare input — rejected (only Normal allowed). After success: item has `rarity == RARE` and `prefixes.size() + suffixes.size()` is in range [1, 6] (may be less than 4 if pool exhaustion hits, but typically 4–6). The invariant-safe assertion is `>= 1` and `<= 6` and `rarity == RARE`.

- **Chaos edge (D-14):** Empty Rare (0 mods) — `ChaosHammer.can_apply()` only checks `rarity == RARE`, no mod check. So `can_apply()` is true. After apply: mods cleared (already 0), then 4–6 new mods rolled. Invariant: `rarity == RARE`, `prefixes.size() + suffixes.size() >= 1`.

- **Exalt edge (D-14):** Rare item with 3 prefixes + 3 suffixes (full) — `has_room` is false. Error: `"Rare item has no room for another mod"`.

- **Divine edge (D-14):** Magic item with 1 prefix before / after — `can_apply()` true (has mods). After apply: `item.prefixes.size()` is the same, `affix_name` on each prefix is the same (only values rerolled via `prefix.reroll()`). Invariant: mod count unchanged, mod names unchanged. From DivineHammer source: `for prefix in item.prefixes: prefix.reroll()` — names are not touched by `reroll()`.

- **Annulment edge (D-14):** Magic with 0 mods — `can_apply()` checks `prefixes.size() > 0 or suffixes.size() > 0`. False when empty. Error: `"Item has no mods to remove"`.

---

## Standard Stack

This phase uses no new libraries. All tools are already in the project.

| Component | Current State | Phase 3 Action |
|-----------|--------------|----------------|
| `models/loot/loot_table.gd` | 6 currencies wired | Add 3 dict entries + retune augment gate |
| `autoloads/save_manager.gd` | SAVE_VERSION = 9 | Bump constant to 10 |
| `tools/test/integration_test.gd` | Groups 1–50 (2485 lines) | Rename Group 50 + add Groups 51–57 |

---

## Architecture Patterns

### Pattern 1: Adding a currency to the drop table

Both dicts in `roll_pack_currency_drop()` must receive the new key. The for-loop on line 77 iterates `pack_currency_rules` and immediately accesses `CURRENCY_AREA_GATES[currency_name]` on line 78 — if the key exists in `pack_currency_rules` but not in `CURRENCY_AREA_GATES`, this causes a key-not-found error at runtime. **Both dicts must be updated atomically.**

```gdscript
# loot_table.gd: CURRENCY_AREA_GATES (add 3 entries, retune 1)
"augment":   5,    # was 15
"alchemy":   15,
"annulment": 30,
"divine":    65,

# loot_table.gd: pack_currency_rules inside roll_pack_currency_drop() (add 3 entries)
"alchemy":   {"chance": 0.20, "max_qty": 1},
"annulment": {"chance": 0.15, "max_qty": 1},
"divine":    {"chance": 0.15, "max_qty": 1},
```

### Pattern 2: Save version bump

Single constant change. No other code changes. The delete-and-fresh policy is already operative:

```gdscript
# autoloads/save_manager.gd line 4
const SAVE_VERSION = 10  # was 9
```

### Pattern 3: Test group structure (Groups 51–57)

Based on Group 48 and 49 patterns, adapted to use `_check()` (not `assert()`):

```gdscript
# --- Group 52: Augment Hammer (INT-03) ---
func _group_52_augment_hammer() -> void:
    # INT-03: Augment adds 1 mod to Magic with room; rejected on Normal/Rare/full-magic
    var hammer := AugmentHammer.new()

    # Test 1: Rejection — Normal item
    var normal_item := Broadsword.new(8)
    normal_item.rarity = Item.Rarity.NORMAL
    normal_item.prefixes.clear()
    normal_item.suffixes.clear()
    _check(not hammer.can_apply(normal_item), "52a: Augment rejected on Normal")
    _check(hammer.get_error_message(normal_item) == "Augment Hammer can only be used on Magic items", "52a: error msg on Normal")

    # Test 2: Success — Magic with room
    var magic_item := Broadsword.new(8)
    magic_item.rarity = Item.Rarity.MAGIC
    magic_item.prefixes.clear()
    magic_item.suffixes.clear()
    magic_item.add_prefix()
    var mod_count_before := magic_item.prefixes.size() + magic_item.suffixes.size()
    _check(hammer.can_apply(magic_item), "52b: Augment accepted on Magic with room")
    hammer.apply(magic_item)
    _check(magic_item.rarity == Item.Rarity.MAGIC, "52b: rarity stays MAGIC after Augment")
    _check(magic_item.prefixes.size() + magic_item.suffixes.size() == mod_count_before + 1, "52b: exactly one mod added")

    # Test 3: Edge — Magic with 1 prefix + 1 suffix (full)
    var full_magic := Broadsword.new(8)
    full_magic.rarity = Item.Rarity.MAGIC
    full_magic.prefixes.clear()
    full_magic.suffixes.clear()
    full_magic.add_prefix()
    full_magic.add_suffix()
    _check(not hammer.can_apply(full_magic), "52c: Augment rejected on full Magic")
    _check(hammer.get_error_message(full_magic) == "Magic item has no room for another mod", "52c: error msg on full Magic")

    print("Group 52: Augment Hammer — PASSED")
```

### Pattern 4: Group 50 update

Three surgical changes:
1. Function declaration: `_group_50_save_v9_round_trip` → `_group_50_save_v10_round_trip`
2. Version assertion on line 2436: `== 9` → `== 10`
3. Print marker on line 2485: `"Save v9 round-trip -- PASSED"` → `"Save v10 round-trip — PASSED"`
4. Add alchemy/divine/annulment round-trip assertions after the existing currency assertions (50p–50r)
5. Optionally add a v9 rejection assertion alongside the existing v8 assertion

### Anti-Patterns to Avoid

- **Using `assert()` in new test groups:** Groups 48/49 use `assert()` which aborts on failure. New groups must use `_check()` which accumulates. Using `assert()` would stop the entire test suite on the first failure in a new group.
- **Asserting on specific affix values or names in non-Divine tests:** Only Divine edge test intentionally checks that `affix_name` is preserved. All other tests assert counts and rarities only (D-15).
- **Adding only one dict entry:** `CURRENCY_AREA_GATES` and `pack_currency_rules` must both be updated. Missing the gate entry causes a runtime key-not-found crash in `roll_pack_currency_drop()`.
- **Forgetting to update both places Group 50 refers to v9:** The function name AND the print string both contain "v9" and both need updating.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Area-gated drop chance with ramp | Custom chance function | `_calculate_currency_chance()` already in `loot_table.gd` | Already generic; ramp_duration=12 default handles all new currencies |
| Forward-compatible save serialization | New save schema or migration | `.duplicate()` + key-iteration loop already in place | `currency_counts` already has all 9 keys; the loop picks them up automatically |
| Test assertion infrastructure | New assertion helper | `_check(condition, description)` at line 73 | Non-aborting accumulator; exactly what all new groups need |

---

## Common Pitfalls

### Pitfall 1: Dict sync failure in loot_table.gd
**What goes wrong:** Adding a currency to `pack_currency_rules` without adding it to `CURRENCY_AREA_GATES`. The loop on line 77-78 accesses `CURRENCY_AREA_GATES[currency_name]` unconditionally.
**Why it happens:** The two dicts look independent but have a runtime coupling via the loop.
**How to avoid:** 03-01-PLAN must add entries to both dicts in the same task. Verification grep: confirm `"alchemy"`, `"annulment"`, `"divine"` appear in both dict literals.
**Warning signs:** Any playtest with a pack kill crashes with a key-not-found error on `CURRENCY_AREA_GATES`.

### Pitfall 2: Using `assert()` instead of `_check()` in new test groups
**What goes wrong:** A single false assertion aborts all remaining groups, producing a misleadingly-low pass count.
**Why it happens:** Groups 48/49 (the reference structure) use `assert()` — copying their pattern verbatim imports this behavior.
**How to avoid:** New groups 51–57 must use `_check()`. Grep-verify: new group bodies must not contain `assert(` calls.
**Warning signs:** Test run stops partway through a group; groups after the failure don't print their PASSED marker.

### Pitfall 3: Incomplete Group 50 rename
**What goes wrong:** The function name is updated but the print string on line 2485 still says "v9" (or vice versa). Grep-based verification passes for one but the harness output confuses the user.
**How to avoid:** 03-03-PLAN must call out both the function declaration and the print string as separate edit points. Grep-verify: `"v9"` should not appear in Group 50 after the update.

### Pitfall 4: Divine edge test asserting values change
**What goes wrong:** A test asserts that `reroll()` changes the value (it may not, by RNG chance). Or the test asserts that `reroll()` doesn't change the `affix_name` using a fragile string-comparison pattern.
**How to avoid:** Assert only that `item.prefixes.size()` is unchanged and that `item.prefixes[0].affix_name` before and after are equal. Store the name before `hammer.apply()`, check equality after. Never assert on numeric values.

### Pitfall 5: Alchemy edge test asserting exactly 4–6 mods after success
**What goes wrong:** An assertion like `mod_count >= 4` fails on items where pool exhaustion produces fewer mods (e.g., a Tier 8 Broadsword with few valid affixes).
**How to avoid:** Assert `mod_count >= 1` and `rarity == RARE`. The invariant-only style (D-15) explicitly allows this.

---

## Validation Architecture

> `nyquist_validation` key absent from `.planning/config.json` — treated as enabled.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Custom GDScript harness (no external framework) |
| Config file | none — harness is self-contained in `tools/test/integration_test.gd` |
| Quick run command | None (CLI not available — must run in Godot editor) |
| Full suite command | Open `tools/test/integration_test.tscn`, press F6 |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INT-01 | alchemy/divine/annulment/augment entries in both loot dicts | structural grep | `grep -n '"alchemy"' models/loot/loot_table.gd` | ✅ |
| INT-01 | augment gate retuned to 5 | structural grep | `grep -n '"augment": 5' models/loot/loot_table.gd` | ✅ (after edit) |
| INT-02 | SAVE_VERSION constant is 10 | structural grep | `grep -n 'SAVE_VERSION = 10' autoloads/save_manager.gd` | ✅ (after edit) |
| INT-02 | Group 50 version assertion updated | structural grep | `grep -n '== 10' tools/test/integration_test.gd` | ✅ (after edit) |
| INT-03 | All 7 new group functions exist | structural grep | `grep -n '_group_5[1-7]_' tools/test/integration_test.gd` | ❌ Wave 0 gap |
| INT-03 | All 7 new groups print PASSED marker | structural grep | `grep -n '"Group 5[1-7]:.*PASSED"' tools/test/integration_test.gd` | ❌ Wave 0 gap |
| INT-03 | All 8 hammer behaviors pass at runtime | manual F6 | (Godot editor only) | ✅ (scene exists) |

### Sampling Rate
- **Per task commit:** Grep checks above (all structural, < 5 seconds)
- **Per wave merge:** All grep checks pass
- **Phase gate:** Full F6 run green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `tools/test/integration_test.gd` groups 51–57 — covers INT-03 (added in 03-03-PLAN)
- [ ] Group 50 renamed + v10 assertions — covers INT-02 (added in 03-03-PLAN)

No framework install needed — harness already exists.

---

## Code Examples

### Dict entries to add (03-01-PLAN)

```gdscript
# CURRENCY_AREA_GATES — change augment, add 3 new (loot_table.gd lines ~21-28)
"augment":   5,    # was 15 — D-01 retune
"alchemy":   15,   # D-01
"annulment": 30,   # D-01
"divine":    65,   # D-01

# pack_currency_rules inside roll_pack_currency_drop() (lines ~68-75)
"alchemy":   {"chance": 0.20, "max_qty": 1},  # D-02
"annulment": {"chance": 0.15, "max_qty": 1},  # D-02
"divine":    {"chance": 0.15, "max_qty": 1},  # D-02
```

### Save version bump (03-02-PLAN)

```gdscript
# autoloads/save_manager.gd line 4
const SAVE_VERSION = 10  # bumped from 9 per D-07
```

### Group 50 new currency assertions (03-03-PLAN)

```gdscript
# Add after existing 50p–50r currency assertions
GameState.currency_counts["alchemy"] = 7
GameState.currency_counts["divine"] = 3
GameState.currency_counts["annulment"] = 2
var save_data2 := SaveManager._build_save_data()
GameState.initialize_fresh_game()
SaveManager._restore_state(save_data2)
_check(GameState.currency_counts["alchemy"] == 7, "50v: alchemy count round-tripped")
_check(GameState.currency_counts["divine"] == 3, "50w: divine count round-tripped")
_check(GameState.currency_counts["annulment"] == 2, "50x: annulment count round-tripped")
```

### Divine edge test — mod-name preservation invariant (03-03-PLAN)

```gdscript
# Store names before apply
var names_before: Array[String] = []
for p in magic_item.prefixes:
    names_before.append(p.affix_name)
for s in magic_item.suffixes:
    names_before.append(s.affix_name)
var count_before := magic_item.prefixes.size() + magic_item.suffixes.size()

hammer.apply(magic_item)

# Assert count unchanged
_check(magic_item.prefixes.size() + magic_item.suffixes.size() == count_before, "56c: Divine preserves mod count")

# Assert names unchanged
var names_after: Array[String] = []
for p in magic_item.prefixes:
    names_after.append(p.affix_name)
for s in magic_item.suffixes:
    names_after.append(s.affix_name)
_check(names_before == names_after, "56c: Divine preserves mod names")
```

---

## Open Questions

1. **Group 50 second save cycle for new currencies**
   - What we know: The existing Group 50 pattern sets currency counts, calls `_build_save_data()`, wipes state, calls `_restore_state()`, then checks. Adding 3 new currency assertions fits naturally into this same cycle.
   - What's unclear: Whether to reuse the same `save_data` dict (which now needs `alchemy/divine/annulment` set before `_build_save_data()`) or build a second save dict. The code example above uses a second save cycle for clarity.
   - Recommendation: Use a second mini-cycle (set three new counts → build → wipe → restore → assert) to keep Group 50 edits additive rather than invasive. This avoids re-reading the existing assertions.

2. **`assert()` vs `_check()` in existing Groups 48/49**
   - What we know: Groups 48 and 49 use `assert()`. The full test suite currently passes (these groups pass), so the `assert()` calls don't abort in practice.
   - What's unclear: Whether the plan should retroactively update Groups 48/49 to use `_check()` for consistency.
   - Recommendation: Leave 48/49 unchanged. Converting them is out of scope for Phase 3 (they are working tests). The D-15 guidance says "match the Group 48/49 style" — interpret this as the structural 3-sub-test shape, not the assertion primitive. New groups use `_check()`.

---

## Sources

### Primary (HIGH confidence)
- `models/loot/loot_table.gd` — direct read; confirmed dict contents, line numbers, call patterns
- `autoloads/save_manager.gd` — direct read; confirmed SAVE_VERSION=9 on line 4, delete-and-fresh policy lines 61-65, serialization via `.duplicate()` line 95
- `autoloads/game_state.gd` lines 97-107 — direct read; confirmed all 9 currency keys present
- `tools/test/integration_test.gd` lines 55-60, 2320-2485 — direct read; confirmed dispatch list, Groups 48/49/50 structure and line numbers
- `models/currencies/*.gd` — all 9 hammer classes direct-read; confirmed `can_apply()` / `get_error_message()` exact strings

### Secondary (MEDIUM confidence)
- `.planning/workstreams/fix-hammers/phases/03-integration/03-CONTEXT.md` — 26 decisions, all validated against source

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — zero new dependencies; all files verified
- Architecture: HIGH — call patterns confirmed by reading actual code
- Pitfalls: HIGH — dict-sync pitfall confirmed by reading loop on line 77-78; assert-vs-check confirmed by reading Groups 48/49

**Research date:** 2026-04-12
**Valid until:** End of Phase 3 execution (no external dependencies; purely internal code)
