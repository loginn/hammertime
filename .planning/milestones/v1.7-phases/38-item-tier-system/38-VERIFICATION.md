---
phase: 38-item-tier-system
verified: 2026-03-01T00:00:00Z
status: passed
score: 6/6 must-haves verified
re_verification: false
---

# Phase 38: Item Tier System Verification Report

**Phase Goal:** Dropped items carry an item_tier field that gates which affix tiers can roll, and area level weights drops toward better tiers within the prestige-unlocked ceiling
**Verified:** 2026-03-01
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #  | Truth                                                                                          | Status     | Evidence                                                                                                                                  |
|----|------------------------------------------------------------------------------------------------|------------|-------------------------------------------------------------------------------------------------------------------------------------------|
| 1  | Every dropped item has an item_tier value between 1 and max_item_tier_unlocked                 | VERIFIED   | `gameplay_view.gd:279` — `item.tier = LootTable.roll_item_tier(GameState.area_level, GameState.max_item_tier_unlocked)` in `get_random_item_base()`                    |
| 2  | Items in higher areas skew toward higher-quality (lower-number) tiers at P1+                  | VERIFIED   | `loot_table.gd:117-141` — Gaussian bell-curve weights (`TIER_WEIGHT_SIGMA=25.0`) centered on biome-aligned home areas; P0 fast-path always returns 8 (`loot_table.gd:118-119`) |
| 3  | Crafting onto a tier-8 item rolls only affix tiers 29-32; tier-1 item rolls from all 32 tiers | VERIFIED   | `item.gd:225-226` — `_get_affix_tier_floor()` returns `(self.tier - 1) * 4 + 1`; T8=29, T1=1. Wired into `add_prefix`/`add_suffix` at lines 248-249 and 276-277    |
| 4  | Tuning Hammer rerolls within the same affix tier bounds originally rolled — unaffected by item tier | VERIFIED | `item.gd:199-200` — `reroll_affix()` only calls `affix.reroll()`. `affix.gd:87-99` — `reroll()` uses stored `min_value`/`max_value` (set at construction); item tier not consulted |
| 5  | Item tier label is hidden at P0 and visible as "T{n}" suffix at P1+                           | VERIFIED   | `forge_view.gd:850-853` — `tier_label` is `""` unless `GameState.prestige_level >= 1`; then `" — T%d" % item.tier` appended to stats header                          |
| 6  | Item tier survives save/load round-trip                                                        | VERIFIED   | `item.gd:64` — `"tier": tier` in `to_dict()` serializes tier. `item.gd:102` — `item.tier = int(data.get("tier", 8))` in `create_from_dict()` restores it; default 8 is backward-compatible |

**Score:** 6/6 truths verified

### Required Artifacts

| Artifact                        | Expected                                                         | Status     | Details                                                                                                              |
|---------------------------------|------------------------------------------------------------------|------------|----------------------------------------------------------------------------------------------------------------------|
| `models/loot/loot_table.gd`     | `roll_item_tier()` static helper with bell-curve weighting       | VERIFIED   | Lines 106-141: `TIER_WEIGHT_SIGMA`, `_tier_home_center()`, and `roll_item_tier()` all present and substantive        |
| `autoloads/item_affixes.gd`     | `from_affix()` with optional `affix_tier_floor` parameter        | VERIFIED   | Line 259: `static func from_affix(template: Affix, affix_tier_floor: int = 1)` — computes `effective_range` as new `Vector2i`, templates never mutated |
| `models/items/item.gd`          | `_get_affix_tier_floor()` helper; tier restore in `create_from_dict()` | VERIFIED | Lines 225-226: helper present. Line 102: `create_from_dict()` restores tier. Lines 248-249 and 276-277: floor wired into `add_prefix`/`add_suffix` |
| `scenes/gameplay_view.gd`       | Item tier assignment at drop time via `LootTable.roll_item_tier()` | VERIFIED | Line 279: `item.tier = LootTable.roll_item_tier(GameState.area_level, GameState.max_item_tier_unlocked)` in `get_random_item_base()` |
| `scenes/forge_view.gd`          | Conditional tier label in `get_item_stats_text()`                | VERIFIED   | Lines 850-853: `tier_label` variable, prestige gate, and concatenation into stats header all present                 |

### Key Link Verification

| From                     | To                          | Via                                                          | Status     | Details                                                                                                                |
|--------------------------|-----------------------------|--------------------------------------------------------------|------------|------------------------------------------------------------------------------------------------------------------------|
| `scenes/gameplay_view.gd` | `models/loot/loot_table.gd` | `LootTable.roll_item_tier()` call in `get_random_item_base()` | WIRED      | `gameplay_view.gd:279` directly calls `LootTable.roll_item_tier(GameState.area_level, GameState.max_item_tier_unlocked)` |
| `models/items/item.gd`   | `autoloads/item_affixes.gd` | `Affixes.from_affix(template, floor_val)` in `add_prefix`/`add_suffix` | WIRED | `item.gd:248-249`: `var floor_val = _get_affix_tier_floor(); self.prefixes.append(Affixes.from_affix(new_prefix, floor_val))`. Same at lines 276-277 for suffixes |
| `scenes/forge_view.gd`   | `autoloads/game_state.gd`   | `GameState.prestige_level >= 1` gate for tier display        | WIRED      | `forge_view.gd:851`: `if GameState.prestige_level >= 1:` directly gates the `tier_label` assignment                   |

### Requirements Coverage

| Requirement | Source Plan | Description                                                                 | Status    | Evidence                                                                                                                    |
|-------------|-------------|-----------------------------------------------------------------------------|-----------|-----------------------------------------------------------------------------------------------------------------------------|
| TIER-01     | 38-01-PLAN  | Items have an item_tier field (1-8) that gates which affix tiers can roll   | SATISFIED | `item.gd:15` — `var tier: int` field exists. `_get_affix_tier_floor()` computes gate. `add_prefix`/`add_suffix` enforce it |
| TIER-02     | 38-01-PLAN  | Item tier drops are weighted by area level (higher areas favor better tiers) | SATISFIED | `loot_table.gd:117-141` — Gaussian weighting with P0 fast-path; `gameplay_view.gd:279` calls it at drop time              |
| TIER-03     | 38-01-PLAN  | Tier constrains affix tier range during crafting (T8=29-32, T7=25-32, etc.) | SATISFIED | Floor formula `(tier-1)*4+1` confirmed: T8=29, T7=25, T6=21, T5=17, T4=13, T3=9, T2=5, T1=1. All 27 affix templates use `Vector2i(1, 32)` — templates never mutated |

No orphaned requirements detected. All three TIER requirement IDs appear in the plan frontmatter and are implemented.

### Anti-Patterns Found

| File                          | Line | Pattern                     | Severity | Impact  |
|-------------------------------|------|-----------------------------|----------|---------|
| `models/items/item.gd`        | 204  | `print(self.prefixes)`      | Info     | Debug print in `is_affix_on_item()`; pre-existing, not introduced by this phase |
| `models/items/item.gd`        | 207  | `print("affix ... already on item")` | Info | Debug prints in `is_affix_on_item()`; pre-existing |
| `models/items/item.gd`        | 230, 240, 250, 257, 275 | Multiple `print()` statements in `add_prefix`/`add_suffix` | Info | Pre-existing debug instrumentation; not introduced by this phase |

No blockers or warnings introduced by phase 38. The `print()` statements are pre-existing in the codebase and do not affect goal achievement.

### Human Verification Required

#### 1. Bell-curve tier distribution in play

**Test:** At P0, run combat in Forest (area 1-24) and collect 20+ item drops. Inspect tier on each item.
**Expected:** All items are tier 8 (P0 fast-path).
**Why human:** `roll_item_tier` returns immediately for `max_tier_unlocked == 8` — correct by code inspection, but requires runtime confirmation in Godot.

#### 2. Tier-weighted distribution at P1+

**Test:** Unlock P1 (so `max_item_tier_unlocked` becomes 7). Collect drops in Shadow Realm (area 75+) vs Forest (area 1-24). Compare tier distribution.
**Expected:** Shadow Realm drops skew toward tier 7; Forest drops are mostly tier 8, with occasional tier 7.
**Why human:** Stochastic behavior — code logic is correct but live feel needs runtime validation.

#### 3. Forge tier label display gate

**Test:** Open forge at P0 and inspect any item's stats panel. Then prestige and open forge again.
**Expected:** At P0: no tier suffix in item name. At P1+: "ItemName (Rarity) — T8" appears.
**Why human:** UI display requires visual confirmation in Godot editor/runtime.

#### 4. Affix tier constraint in crafting

**Test:** With a tier-8 item at P1+, use Runic Orb or Tack to craft a prefix. Inspect the resulting affix tier (shown in forge stats as "T{n}" suffix on the affix line).
**Expected:** Affix tier is in range 29-32 only.
**Why human:** Probabilistic outcome — requires multiple craft attempts to confirm the floor is applied.

### Gaps Summary

No gaps found. All six observable truths verified against the actual codebase.

Key implementation quality notes:
- Template affixes are never mutated: `from_affix()` constructs a new `Vector2i` for `effective_range` rather than modifying `template.tier_range`. All 27 affix templates confirmed to use `Vector2i(1, 32)`.
- `reroll_affix()` correctly left untouched: Tuning Hammer rerolls use stored `min_value`/`max_value` on the affix instance (set at construction), bypassing the item tier system entirely.
- Save/load round-trip: `item.tier` was already in `to_dict()` before this phase; `create_from_dict()` now reads it with a safe default of 8, requiring no `SAVE_VERSION` bump.
- Both commits from the summary (`14b7c41` and `6157471`) confirmed present in git log.

---

_Verified: 2026-03-01_
_Verifier: Claude (gsd-verifier)_
