# Phase 1: Hammer Models - Research

**Researched:** 2026-04-11
**Domain:** Godot/GDScript — currency class refactor (rename + add) inside a self-contained `models/currencies/` module
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions (copied verbatim)

**Refactor Strategy**
- **D-01:** Rename + add new. The 3 existing mismatched currency classes already implement PoE-correct logic for the 3 "missing" currencies — rename them instead of rewriting. File renames use `git mv`:
  - `models/currencies/claw_hammer.gd` → `annulment_hammer.gd` (`ClawHammer` → `AnnulmentHammer`)
  - `models/currencies/forge_hammer.gd` → `alchemy_hammer.gd` (`ForgeHammer` → `AlchemyHammer`)
  - `models/currencies/tuning_hammer.gd` → `divine_hammer.gd` (`TuningHammer` → `DivineHammer`)
- **D-02:** Update `currency_name` string inside each renamed class: `"Chaos Hammer"` → `"Annulment Hammer"`, `"Augment Hammer"` → `"Alchemy Hammer"`, `"Exalt Hammer"` → `"Divine Hammer"`.
- **D-03:** `_do_apply()`, `can_apply()`, `get_error_message()` bodies of the 3 renamed classes stay **byte-identical** — only class/file/display-name metadata changes.
- **D-04:** Add 3 new currency classes with correct PoE behaviors:
  - `models/currencies/augment_hammer.gd` → `class_name AugmentHammer`
  - `models/currencies/chaos_hammer.gd` → `class_name ChaosHammer`
  - `models/currencies/exalt_hammer.gd` → `class_name ExaltHammer`

**Naming Convention**
- **D-05:** All 8 base hammers use literal PoE names. Creative names (Runic/Tack/Grand/Tag) stay.
- **D-06:** Update `CONVENTIONS.md` lines 11 and 16 for the new literal convention.

**Forge View Rewiring**
- **D-07:** Update `scenes/forge_view.gd` currencies dict to route new PoE currency keys to the correct classes. Phase 1 wires the dict only — alchemy/divine/annulment keys exist but aren't referenced by `@onready` button handlers until Phase 2.

**Scene Tree Button Node Renames**
- **D-08:** Rename button nodes in `scenes/forge_view.tscn` (lines 64, 136, 160 and `CountLabel` children) and `scenes/node_2d.tscn` (lines 49, 73, 81):
  - `ForgeHammerBtn` → `AlchemyHammerBtn`
  - `ClawHammerBtn` → `AnnulmentHammerBtn`
  - `TuningHammerBtn` → `DivineHammerBtn`
- **D-09:** Update `@onready` var paths in `scenes/forge_view.gd` lines 9, 12, 13 and rename the vars (`forge_btn`→`alchemy_btn`, `claw_btn`→`annulment_btn`, `tuning_btn`→`divine_btn`) throughout the file.
- **D-10:** Phase 1 does NOT add new button nodes for augment/chaos/exalt. After the rename, the scene has 3 buttons labeled "alchemy/divine/annulment" — temporarily inconsistent with the dict routing until Phase 2 adds missing buttons and fixes all 8 tooltips.

**Behaviors**
- **D-11/12/13:** Annulment — check has ≥1 explicit mod only (no rarity check); Magic item with 0 mods stays Magic; never touches implicit.
- **D-14:** Alchemy — existing `ForgeHammer._do_apply()` verbatim: set RARE, roll `randi_range(4, 6)`, 50/50 prefix/suffix with fallback.
- **D-15:** Divine — existing `TuningHammer._do_apply()` verbatim: iterate prefixes/suffixes, call `reroll()`. Implicit untouched.
- **D-16/17/18:** Chaos — `can_apply = rarity == RARE` (no "has mods" check); `_do_apply` clears prefixes/suffixes then rolls 4–6 using Alchemy pattern; error "Chaos Hammer can only be used on Rare items".
- **D-19/20/21:** Augment — `can_apply = rarity == MAGIC AND has_room`; `_do_apply` adds exactly 1 mod (50/50 prefix/suffix with fallback) — same shape as `GrandHammer`; two error strings (not Magic / no room).
- **D-22/23/24:** Exalt — `can_apply = rarity == RARE AND has_room`; `_do_apply` same 1-mod shape as Augment; two error strings (not Rare / no room).
- **D-25:** All 6 affected currencies inherit `Currency.apply()` template method. Never override `apply()`.

**Claude's Discretion**
- Internal variable naming inside new `_do_apply()` methods: follow existing conventions (`mod_count`, `choose_prefix`).
- Doc comments (`##`) on new classes: match the style used in `grand_hammer.gd` and `runic_hammer.gd` — short preamble above `can_apply()` and `_do_apply()`.
- Print/logging: none — existing currencies don't log inside `_do_apply()`; don't start now.

### Deferred Ideas (OUT OF SCOPE)
- Renaming the 4 untouched creative-named classes (RunicHammer, TackHammer, GrandHammer, TagHammer).
- Shared currency helper (e.g. `Currency.roll_random_mods(item, count)`).
- Phase 1→2 gap: shipping/label consistency. (Flagged as risk, mitigation is keeping Phase 1 & 2 in same release window.)
- Exact error-message copy — accepted defaults in D-18/21/24; UX review can retune in Phase 2.
- Drop-table wiring, save-format version bump, integration tests (all Phase 3).
- Adding NEW buttons to the forge UI for Alchemy/Divine/Annulment (Phase 2).
- Tag hammer behavior (not broken, untouched).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FIX-01 | Augment Hammer adds 1 random mod to a Magic item with room | New `AugmentHammer` class patterned on `GrandHammer._do_apply()` (1-mod add with 50/50 fallback). `can_apply = rarity == MAGIC AND has_room`. See "Augment Hammer" code example. |
| FIX-02 | Chaos Hammer rerolls all mods on a Rare item with 4–6 new mods | New `ChaosHammer` class combining `TackHammer` clear pattern + `ForgeHammer` 4–6 roll pattern. `can_apply = rarity == RARE`. See "Chaos Hammer" code example. |
| FIX-03 | Exalt Hammer adds 1 random mod to a Rare item with room | New `ExaltHammer` class patterned on `GrandHammer._do_apply()` minus rarity transition. `can_apply = rarity == RARE AND has_room`. See "Exalt Hammer" code example. |
| NEW-01 | Alchemy Hammer converts Normal → Rare with 4–6 random mods | Rename `ForgeHammer` → `AlchemyHammer` (logic already correct). File+class rename only; `_do_apply`/`can_apply` bodies are byte-identical. |
| NEW-02 | Divine Hammer rerolls all mod values in tier ranges (mod types unchanged) | Rename `TuningHammer` → `DivineHammer`. Existing body iterates prefixes/suffixes calling `Affix.reroll()` which re-rolls value/damage ranges from template bounds — exactly PoE Divine behavior. |
| NEW-03 | Annulment Hammer removes 1 random mod from Magic or Rare item | Rename `ClawHammer` → `AnnulmentHammer`. Existing body picks a random prefix or suffix and removes it; does not touch rarity or implicit. Empty Magic (0 mods) stays Magic — enables Aug→Ann→Aug loop (D-12). |
</phase_requirements>

## Summary

This is a **local, closed-system refactor** — zero network surface, zero library choices, zero framework decisions. All research lives inside this repository at `models/currencies/` and its two callers (`scenes/forge_view.gd`, `scenes/forge_view.tscn`, `scenes/node_2d.tscn`). The phase is 80% rename + 20% three new files that mirror existing patterns verbatim.

The existing codebase has mislabeled 3 of its currency classes (Chaos/Augment/Exalt) but implemented correct PoE logic for *the other 3 currencies* (Annulment/Alchemy/Divine). The user's decision to rename rather than rewrite is exactly right: it preserves battle-tested logic while correcting names, and limits behavioral risk to the 3 genuinely-new classes.

The three new classes — Augment, Chaos, Exalt — can each be assembled from **existing in-repo templates**: `GrandHammer` (Regal) for the "add-1-mod-with-fallback" pattern, `ForgeHammer` (→ Alchemy) for the "roll-4-to-6-mods" pattern, and `TackHammer` (Alteration) for the "clear-then-reroll" pattern. No new algorithmic work.

**Primary recommendation:** Copy shapes, not lines. Augment = GrandHammer minus the `rarity = RARE` line. Exalt = Augment with a RARE guard. Chaos = TackHammer's clear + ForgeHammer's 4–6 roll loop, with a RARE guard. Make each rename a single atomic commit (class + `currency_name` + forge_view references + scene node + `@onready` var) so the project builds green at every commit. Finish with `codebase/` live-doc touch-ups and a local Godot editor validation run.

## Standard Stack

This phase adds **no external dependencies**. All work uses facilities already in the repo:

### Core
| Facility | Location | Purpose | Why Standard |
|----------|----------|---------|--------------|
| `Currency` base class | `models/currencies/currency.gd` | Template Method: `apply()` → `can_apply()` + `_do_apply()` | Enforces CRAFT-09 "currency consumed only on success" — every existing hammer uses it |
| `Item.RARITY_LIMITS` | `models/items/item.gd:5-9` | Normal 0/0, Magic 1/1, Rare 3/3 affix caps | Single source of truth for "has room" checks |
| `Item.max_prefixes()` / `max_suffixes()` | `models/items/item.gd:22-31` | Rarity-driven affix cap accessors | Already handles custom overrides |
| `Item.add_prefix()` / `add_suffix()` | `models/items/item.gd:278-317` | Append a random valid affix respecting tags, tier floor, slot cap, and `is_affix_on_item` dedup | Return `false` on failure — enables 50/50 fallback pattern |
| `Affix.reroll()` | `models/affixes/affix.gd:92-103` | Re-rolls damage range OR scalar value from **template** bounds (not rolled values) | Used by Divine; correct behavior already implemented |
| `Array.pick_random()` | GDScript built-in | Uniform random selection from a list | Used by existing `ClawHammer._do_apply()` for mod removal |
| `randi_range(a, b)` / `randf()` | GDScript built-in | Integer range / 0–1 float | Used by every existing hammer for 50/50 and mod count rolls |

### Reference Templates (in-repo patterns to clone)
| Template | File | What to Borrow | Used By |
|----------|------|----------------|---------|
| 1-mod-add-with-fallback | `grand_hammer.gd:21-33` (Regal) | `choose_prefix = randi_range(0,1) == 0; if choose_prefix: if not item.add_prefix(): item.add_suffix() else: ...` | AugmentHammer, ExaltHammer |
| 4–6 roll loop with fallback | `forge_hammer.gd:22-39` (→ Alchemy) | `var mod_count = randi_range(4, 6); for i in range(mod_count): <fallback>` | ChaosHammer |
| Clear-then-reroll | `tack_hammer.gd:22-25` (Alteration) | `item.prefixes.clear(); item.suffixes.clear()` | ChaosHammer |
| Random mod removal | `claw_hammer.gd:22-42` (→ Annulment) | Build positional `all_mods` list, `pick_random()`, `remove_at()` | No new user — logic ships unchanged under new class name |
| Reroll values in place | `tuning_hammer.gd:20-33` (→ Divine) | Iterate `prefixes`/`suffixes` calling `reroll()` | No new user — logic ships unchanged under new class name |

**Version verification:** N/A — no external packages. Godot engine version is whatever the repo currently targets (not changing in this phase).

## Architecture Patterns

### Recommended File Layout

```
models/currencies/
├── currency.gd              # base class (unchanged)
├── runic_hammer.gd          # Transmute — unchanged
├── augment_hammer.gd        # NEW — 1-mod add on Magic
├── alchemy_hammer.gd        # RENAMED from forge_hammer.gd (logic unchanged)
├── tack_hammer.gd           # Alteration — unchanged
├── grand_hammer.gd          # Regal — unchanged
├── chaos_hammer.gd          # NEW — clear + 4–6 roll on Rare
├── exalt_hammer.gd          # NEW — 1-mod add on Rare
├── divine_hammer.gd         # RENAMED from tuning_hammer.gd (logic unchanged)
├── annulment_hammer.gd      # RENAMED from claw_hammer.gd (logic unchanged)
└── tag_hammer.gd            # parameterized — unchanged
```

### Pattern 1: Template Method (Currency.apply)

**What:** `Currency.apply()` is a non-overridable template method that calls `can_apply()` first and only runs `_do_apply()` if true. The currency is consumed (by caller) only when `apply()` returns true.

**When to use:** Every concrete currency class, always. Never override `apply()`.

**Source:** `models/currencies/currency.gd:16-21`

```gdscript
func apply(item: Item) -> bool:
    if not can_apply(item):
        return false
    _do_apply(item)
    return true
```

### Pattern 2: 1-mod Add with 50/50 Fallback (Regal/Augment/Exalt)

**What:** Roll a random slot choice; if that slot is full/exhausted, fall back to the other slot.

**When to use:** Currencies that add exactly one mod to an item that already has room.

**Source:** `models/currencies/grand_hammer.gd:21-33`

```gdscript
func _do_apply(item: Item) -> void:
    # (Regal only: item.rarity = Item.Rarity.RARE — OMIT for Augment/Exalt)

    var choose_prefix = randi_range(0, 1) == 0
    if choose_prefix:
        if not item.add_prefix():
            item.add_suffix()
    else:
        if not item.add_suffix():
            item.add_prefix()

    item.update_value()
```

### Pattern 3: 4–6 Roll Loop with Fallback (Alchemy/Chaos)

**What:** Roll `randi_range(4, 6)` iterations; each iteration tries a 50/50 slot and falls back to the other slot; `break` when both slots return false (pool exhausted).

**When to use:** Currencies that populate an item with 4–6 random mods from empty.

**Source:** `models/currencies/forge_hammer.gd:22-39`

```gdscript
var mod_count = randi_range(4, 6)
for i in range(mod_count):
    var choose_prefix = randi_range(0, 1) == 0
    if choose_prefix:
        if not item.add_prefix():
            if not item.add_suffix():
                break
    else:
        if not item.add_suffix():
            if not item.add_prefix():
                break
```

### Pattern 4: Clear-Then-Reroll (Alteration/Chaos)

**What:** Dump existing mods via `prefixes.clear(); suffixes.clear()`, then use Pattern 3 (or a smaller variant) to repopulate. Rarity is **not** changed — the caller's `can_apply()` already gated it.

**Source:** `models/currencies/tack_hammer.gd:22-36`

### Pattern 5: Reroll in Place (Divine)

**What:** Iterate `item.prefixes` and `item.suffixes`, calling `Affix.reroll()` on each. `reroll()` re-rolls from **template bounds** (not current rolled values), so repeated divines don't drift. Implicit is untouched.

**Source:** `models/currencies/tuning_hammer.gd:22-33` + `models/affixes/affix.gd:92-103`

### Pattern 6: Random-Index Removal (Annulment)

**What:** Build a positional list of `{"type": "prefix"|"suffix", "index": i}` dicts for every explicit mod, `pick_random()`, `remove_at()`. Rarity and implicit untouched.

**Source:** `models/currencies/claw_hammer.gd:22-43`

### Anti-Patterns to Avoid

- **Overriding `apply()`:** Breaks the CRAFT-09 consumption contract. Always override `can_apply()` + `_do_apply()` only.
- **Pre-building an "available affixes" list in the currency class:** Item already does this inside `add_prefix()` / `add_suffix()` with tag filtering and dedup. Duplicating it would drift from `is_affix_on_item()` semantics.
- **Extracting a shared `Currency.roll_mods()` helper:** Violates the codebase convention that each hammer is self-contained. CONTEXT.md D-17 explicitly keeps Chaos's 4–6 loop inline.
- **Changing rarity in `_do_apply()` when `can_apply()` already gated it:** Only Alchemy changes rarity (Normal → Rare). Augment, Exalt, Chaos, Divine, Annulment must never mutate `item.rarity`.
- **Touching `item.implicit`:** None of the 6 affected currencies touch implicits. Divine's `reroll()` loop iterates `prefixes`/`suffixes` only — preserve that.
- **Calling `add_prefix()` after `rarity = RARE` without understanding that rarity change happens first:** `add_prefix()` reads `max_prefixes()` which reads `RARITY_LIMITS[rarity]`, so rarity MUST be set before any `add_*()` call on rarity-changing currencies.
- **Forgetting `item.update_value()` at the end of `_do_apply()`:** Every existing hammer calls this last. The sell value depends on mods. Miss this and tooltips stay stale.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| "Pick a random valid affix that respects tags and tier floor and dedup" | Manual iteration over `ItemAffixes.prefixes` | `item.add_prefix()` / `item.add_suffix()` | Already handles tag validity, `is_affix_on_item` dedup, tier floor (`_get_affix_tier_floor`), and slot cap |
| "Compute whether a Magic/Rare item has room" | `len(prefixes) < 1 if magic else 3 or len(suffixes) < 1 if magic else 3` | `len(item.prefixes) < item.max_prefixes() or len(item.suffixes) < item.max_suffixes()` | Handles `custom_max_prefixes` overrides, reads `RARITY_LIMITS` SSoT |
| "Reroll an affix value within its tier range" | `randi_range(affix.min_value, affix.max_value)` | `affix.reroll()` | Correctly handles damage-range affixes (`dmg_min_lo` / `dmg_max_hi`) and preserves template bounds |
| "Pick a random mod to remove" | Manually count prefixes + suffixes and build an index | Existing `ClawHammer._do_apply()` pattern — copy verbatim | Already handles the positional dict + `pick_random()` + `remove_at()` flow |
| "Compute prefix/suffix 50-50" | Two-arg `match` or weighted table | `randi_range(0, 1) == 0` | Every existing hammer does exactly this |

**Key insight:** Every building block needed by Augment/Chaos/Exalt already exists and is battle-tested in the existing hammers and `Item` API. The new classes are **assemblies**, not **inventions**.

## Runtime State Inventory

Rename/refactor phase — all 5 categories answered explicitly.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| **Stored data** | Save files contain `currency_counts` dict keys: `"transmute"`, `"augment"`, `"alteration"`, `"regal"`, `"chaos"`, `"exalt"` (strings, not class names). String keys are **PoE keys**, not class names, so the rename does NOT break existing saves. Phase 3 will add `"alchemy"`, `"divine"`, `"annulment"` keys — NOT Phase 1's concern. | **None** for Phase 1. Existing save files round-trip unchanged. |
| **Live service config** | None — this is a local desktop game. No external services. | **None.** Verified by inspection — no network, no remote config, no database. |
| **OS-registered state** | None — no OS-registered processes, tasks, services, or schedulers. Godot editor launches the game directly from `.tscn`. | **None.** |
| **Secrets / env vars** | None — no secrets, no `.env`, no API keys. Pure offline game. | **None.** |
| **Build artifacts / installed packages** | Godot `.import/` cache holds resource metadata keyed by `res://` path. The 3 currency scripts being renamed (`claw_hammer.gd` → `annulment_hammer.gd` etc.) will produce **new** `.import` cache entries. Old cache entries become orphaned. Godot typically handles this cleanly on next editor open, but stale UID references in `.import/*.md5` could cause warnings. | **Open Godot editor once after the rename** to let it regenerate import cache. Do NOT commit stale `.import/` entries. If UID references appear in `project.godot` or `.tscn` files, update them (unlikely for scripts, but verify). |

**Critical runtime concern — `GameState.currency_counts` is NOT affected by Phase 1 but planner must know:**
- `autoloads/game_state.gd:97-104` and `:144-151` seed `currency_counts` with exactly 6 keys (`transmute/augment/alteration/regal/chaos/exalt`). The three new keys (`alchemy/divine/annulment`) are **not** seeded.
- `spend_currency()` at `:172-180` rejects unknown keys (`if currency_type not in currency_counts: return false`) — so even if Phase 1 adds the keys to `scenes/forge_view.gd` `currencies` dict, they are **not spendable** until `GameState.initialize_fresh_game()` and `_wipe_run_state()` are also updated with the new keys.
- Phase 2 (UI) would actually try to read/display the counts. Without seeding, `currency_counts["alchemy"]` would crash or return 0.
- **Planner decision needed:** does Phase 1 also seed the 3 new keys in `GameState` (zero-init) to prevent Phase 2 from crashing, or is that deferred to Phase 2? See "Open Questions" — Q1.

**Class-name reference audit (old → new, git-mv targets):**
- `ClawHammer`: 2 non-doc refs (`scenes/forge_view.gd:42`, `models/currencies/claw_hammer.gd:1`) + 1 live-doc ref (`.planning/codebase/ARCHITECTURE.md` line 37 mentions `ForgeHammer`, not `ClawHammer`)
- `ForgeHammer`: 2 non-doc refs (`scenes/forge_view.gd:39`, `models/currencies/forge_hammer.gd:1`) + 2 live-doc refs (`.planning/codebase/CONVENTIONS.md:16`, `.planning/codebase/ARCHITECTURE.md:37`, `.planning/research/STACK.md:206`)
- `TuningHammer`: 2 non-doc refs (`scenes/forge_view.gd:43`, `models/currencies/tuning_hammer.gd:1`) + 0 live-doc refs
- `ForgeHammerBtn` / `ClawHammerBtn` / `TuningHammerBtn` node names: `scenes/forge_view.tscn` (lines 64, 74, 136, 146, 160, 170) + `scenes/node_2d.tscn` (lines 49, 73, 81)
- `forge_btn` / `claw_btn` / `tuning_btn` variable names in `scenes/forge_view.gd` (lines 9, 12, 13, 101, 104, 105, 115, 118, 119) — **9 references total, all in one file**
- Tests: `tools/test/integration_test.gd` has **zero** references to the 3 old class names OR the old `_btn` vars. Verified via grep.
- Archives (`.planning/milestones/`, `.planning/quick/`, `.planning/workstreams/milestone/`, `.planning/debug/resolved/`): **do not touch** per CONTEXT.md canonical_refs — these are historical record (~100 references).

**Icon asset filenames (NOT in CONTEXT.md D-list — flagged):**
`scenes/forge_view.gd:87-94` preloads 3 PNG files named after old creative names:
- `"res://assets/forge_hammer.png"` (used for `"augment"` key)
- `"res://assets/claw_hammer.png"` (used for `"chaos"` key)
- `"res://assets/tuning_hammer.png"` (used for `"exalt"` key)

These asset filenames and the keys they're mapped to become **semantically wrong** after the class rename (e.g., `forge_hammer.png` for a key now meaning "augment"). CONTEXT.md does not direct renaming the PNG files. **Recommendation:** planner should NOT rename PNGs in Phase 1 (out of scope — they're visual assets, not logic). Flag for Phase 2 UI work. The key→file mapping continues to work because the dict keys (`augment`/`chaos`/`exalt`) are unchanged.

`scenes/forge_view.tscn:71, 143, 167` also reference `ExtResource("5_forge")`, `ExtResource("8_claw")`, `ExtResource("9_tuning")` — these are load identifiers inside the .tscn, NOT filenames. Do not change them unless the `[ext_resource]` declarations at the top of the file are also updated. **Recommendation:** leave ExtResource IDs alone — they're opaque identifiers.

## Common Pitfalls

### Pitfall 1: Setting rarity AFTER calling add_prefix()/add_suffix()
**What goes wrong:** `add_prefix()` reads `max_prefixes()` which reads `RARITY_LIMITS[self.rarity]`. If you add mods before setting rarity, the cap is 0 (NORMAL) and every `add_*()` fails.
**Why it happens:** Forgetting the ordering. Only Alchemy is affected (Normal → Rare transition); Chaos/Augment/Exalt do NOT change rarity so they're immune.
**How to avoid:** In Alchemy (unchanged from `ForgeHammer`), `item.rarity = Item.Rarity.RARE` is the FIRST line of `_do_apply()` before any `add_*()`. Don't reorder.
**Warning signs:** Items created by Alchemy end up with 0 mods. Existing tests (if any) would catch this; manual test by Alchemizing a Normal item and expecting 4–6 mods.

### Pitfall 2: Missing item.update_value() at end of _do_apply()
**What goes wrong:** Sell value and tooltip displays show stale data from before the craft.
**Why it happens:** `update_value()` is the last line of every existing `_do_apply()`; easy to forget in new code.
**How to avoid:** Last line of every new `_do_apply()` is `item.update_value()`. Grep the new files for `update_value` — must be exactly one match per new class.
**Warning signs:** Forge view shows correct mods but wrong sell price; melt returns stale currency amount.

### Pitfall 3: Reading item.rarity when you mean item.rarity BEFORE the craft
**What goes wrong:** Augment on a Magic item is fine, but if you set `item.rarity = Rarity.MAGIC` somewhere in `_do_apply()`, you're a no-op for Magic inputs and silently upgrade-down from Rare inputs (though Rare is rejected by `can_apply()`).
**Why it happens:** Over-generalizing the Regal pattern. Regal sets `rarity = RARE`; Augment must NOT.
**How to avoid:** Augment / Exalt / Chaos / Divine / Annulment must not assign to `item.rarity`. Grep new files for `item.rarity =` — should be zero matches in all five.

### Pitfall 4: Fallback pool exhaustion silently under-rolls Alchemy/Chaos
**What goes wrong:** If few affixes are tag-valid for a small pool item, `add_prefix()` / `add_suffix()` both return false before the 4–6 count is reached. The loop breaks early and the item ships with 2–3 mods instead of 4–6.
**Why it happens:** `add_prefix()` filters by `has_valid_tag()` + `is_affix_on_item()` dedup. On items with narrow tag pools, the pool exhausts before 6 mods.
**How to avoid:** This is **existing ForgeHammer behavior** — accept it. CONTEXT.md code_context note explicitly says "existing `ForgeHammer` handles this silently" and calls it acceptable. Do NOT add retry logic or error paths. Chaos should inherit the same tolerance.
**Warning signs:** Alchemy on a low-pool item yields 2–3 mods. Not a bug — it's the design.

### Pitfall 5: Magic item with 0 mods after Annulment — unexpectedly valid state
**What goes wrong:** An Annulment on a 1-mod Magic item leaves it at 0 mods but still MAGIC rarity. Downstream code (UI tooltips, sell calc, combat) must handle this. PoE does the same.
**Why it happens:** D-12 explicitly preserves this to enable Aug→Ann→Aug loops. Don't be tempted to auto-demote to Normal.
**How to avoid:** Don't add "if no mods left, set rarity = NORMAL" logic. Leave the existing `ClawHammer._do_apply()` body byte-identical (D-03).
**Warning signs:** Someone "helpfully" adds a rarity reset. Reject it in review.

### Pitfall 6: Annulment removal_at(index) invalidates downstream indices
**What goes wrong:** If you build `[{type: prefix, index: 0}, {type: prefix, index: 1}]` and remove index 0, the affix originally at index 1 shifts to index 0 — but you're not iterating, you're removing exactly one. False alarm.
**Why it happens:** Reviewers may flag this as a bug on first read. Existing `ClawHammer._do_apply()` (→ AnnulmentHammer) removes exactly one mod per call, so indices never need to re-stabilize.
**How to avoid:** Preserve the existing single-removal logic. Do NOT extend Annulment to remove multiple mods.
**Warning signs:** Reviewer comment asking for index re-stabilization — answer "we only remove one."

### Pitfall 7: forge_view.gd `currencies` dict is called `currencies`, not `hammers`
**What goes wrong:** CONTEXT.md D-07 says "`hammers` dictionary (lines 38-48)" but the actual variable is `var currencies: Dictionary = {` at `scenes/forge_view.gd:37`. Following CONTEXT.md verbatim could cause confusion in task descriptions.
**Why it happens:** Minor naming discrepancy in the decision doc.
**How to avoid:** Planner should use the actual variable name `currencies` in task descriptions. The dict is at `forge_view.gd:37-49`, and the full class-name references to update inside it are at lines 39 (`ForgeHammer.new()` → `AlchemyHammer.new()`), 42 (`ClawHammer.new()` → `AnnulmentHammer.new()`), and 43 (`TuningHammer.new()` → `DivineHammer.new()`). Plus three NEW entries for `augment`/`chaos`/`exalt`, though — **wait** — those keys already exist in the dict today, pointed at the wrong classes (`ForgeHammer`/`ClawHammer`/`TuningHammer`). Phase 1 is repointing the existing keys AND adding 3 new keys (`alchemy`/`divine`/`annulment`) that no UI button references yet. See "Existing Code Insights — Dict Rewiring" below.

### Pitfall 8: Button signal connection still bound to wrong currency key after rename
**What goes wrong:** `scenes/forge_view.gd:115, 118, 119` bind the old-var buttons to old keys: `forge_btn.pressed.connect(_on_currency_selected.bind("augment"))`. After the rename, the button VISUALLY labeled "Alchemy" but routed via the RENAMED variable (`alchemy_btn`) is still `.bind("augment")` — so clicking the Alchemy button runs Augment's behavior. This is **correct per CONTEXT.md D-10** ("temporarily inconsistent") but must be explicit in the plan so the planner and reviewer don't fix it.
**Why it happens:** Phase 1 is intentionally leaving the old button-to-key bindings in place because no new UI buttons exist yet. The dict now maps `"augment"` → `AugmentHammer.new()` (correct), `"alchemy"` → `AlchemyHammer.new()` (correct), but the Alchemy button STILL fires `"augment"` (wrong, but fixable in Phase 2).
**How to avoid:** The plan MUST update:
  - Line 115: `alchemy_btn.pressed.connect(_on_currency_selected.bind("augment"))` — keep `.bind("augment")` because this button will be the Augment button until Phase 2.
  - Line 118: `annulment_btn.pressed.connect(_on_currency_selected.bind("chaos"))` — same reasoning: will be Chaos button until Phase 2.
  - Line 119: `divine_btn.pressed.connect(_on_currency_selected.bind("exalt"))` — same: will be Exalt button until Phase 2.

  Phase 2 will swap the `.bind()` args and add 3 new button widgets.
  **Alternative approach:** If the planner prefers, Phase 1 can use the **new** button variable names pointing at the **correct** new keys (`alchemy_btn` → `.bind("alchemy")`) and accept that three buttons visually present the wrong behavior until Phase 2 adds new buttons. This is cleaner but user-visible for the interim period. Recommend sticking with CONTEXT.md D-10's "temporarily inconsistent" framing — use renamed vars with OLD keys so behavior matches the button labels as much as possible during the interim.
**Warning signs:** Clicking any of the 3 renamed buttons does nothing, or runs the wrong currency.

## Code Examples

Verified patterns ready to template. All sources are in-repo files.

### New: Augment Hammer (FIX-01)

```gdscript
# models/currencies/augment_hammer.gd
class_name AugmentHammer extends Currency


func _init() -> void:
	currency_name = "Augment Hammer"


## Augment adds one mod to a Magic item that still has room for another affix.
func can_apply(item: Item) -> bool:
	if item.rarity != Item.Rarity.MAGIC:
		return false
	var has_room: bool = (
		len(item.prefixes) < item.max_prefixes()
		or len(item.suffixes) < item.max_suffixes()
	)
	return has_room


func get_error_message(item: Item) -> String:
	if item.rarity != Item.Rarity.MAGIC:
		return "Augment Hammer can only be used on Magic items"
	if len(item.prefixes) >= item.max_prefixes() and len(item.suffixes) >= item.max_suffixes():
		return "Magic item has no room for another mod"
	return ""


## Adds exactly one mod (prefix or suffix, 50/50 with fallback to the other slot).
func _do_apply(item: Item) -> void:
	var choose_prefix = randi_range(0, 1) == 0
	if choose_prefix:
		if not item.add_prefix():
			item.add_suffix()
	else:
		if not item.add_suffix():
			item.add_prefix()

	item.update_value()
```
*Template source: `models/currencies/grand_hammer.gd` (Regal), minus the `rarity = RARE` line and with a MAGIC guard instead of MAGIC.*

### New: Exalt Hammer (FIX-03)

```gdscript
# models/currencies/exalt_hammer.gd
class_name ExaltHammer extends Currency


func _init() -> void:
	currency_name = "Exalt Hammer"


## Exalt adds one mod to a Rare item that still has room for another affix.
func can_apply(item: Item) -> bool:
	if item.rarity != Item.Rarity.RARE:
		return false
	var has_room: bool = (
		len(item.prefixes) < item.max_prefixes()
		or len(item.suffixes) < item.max_suffixes()
	)
	return has_room


func get_error_message(item: Item) -> String:
	if item.rarity != Item.Rarity.RARE:
		return "Exalt Hammer can only be used on Rare items"
	if len(item.prefixes) >= item.max_prefixes() and len(item.suffixes) >= item.max_suffixes():
		return "Rare item has no room for another mod"
	return ""


## Adds exactly one mod (prefix or suffix, 50/50 with fallback to the other slot).
func _do_apply(item: Item) -> void:
	var choose_prefix = randi_range(0, 1) == 0
	if choose_prefix:
		if not item.add_prefix():
			item.add_suffix()
	else:
		if not item.add_suffix():
			item.add_prefix()

	item.update_value()
```
*Identical to AugmentHammer except for the RARE guard and error strings. Structurally a clone. (`_do_apply()` bodies are byte-identical — this is expected; planner should not DRY them up.)*

### New: Chaos Hammer (FIX-02)

```gdscript
# models/currencies/chaos_hammer.gd
class_name ChaosHammer extends Currency


func _init() -> void:
	currency_name = "Chaos Hammer"


## Chaos rerolls all explicit mods on a Rare item. Works on empty rares too.
func can_apply(item: Item) -> bool:
	return item.rarity == Item.Rarity.RARE


func get_error_message(item: Item) -> String:
	if item.rarity != Item.Rarity.RARE:
		return "Chaos Hammer can only be used on Rare items"
	return ""


## Clears existing prefixes/suffixes and rolls 4-6 new random mods.
## Rarity is already RARE (gated by can_apply); does not change.
func _do_apply(item: Item) -> void:
	item.prefixes.clear()
	item.suffixes.clear()

	var mod_count = randi_range(4, 6)
	for i in range(mod_count):
		var choose_prefix = randi_range(0, 1) == 0
		if choose_prefix:
			if not item.add_prefix():
				if not item.add_suffix():
					break
		else:
			if not item.add_suffix():
				if not item.add_prefix():
					break

	item.update_value()
```
*Template sources: `tack_hammer.gd` for `prefixes.clear() / suffixes.clear()`, `forge_hammer.gd:22-39` for the 4–6 roll loop with fallback.*

### Renamed: Alchemy Hammer (NEW-01) — logic unchanged

```gdscript
# models/currencies/alchemy_hammer.gd (was forge_hammer.gd)
class_name AlchemyHammer extends Currency


func _init() -> void:
	currency_name = "Alchemy Hammer"   # was "Augment Hammer"


func can_apply(item: Item) -> bool:
	return item.rarity == Item.Rarity.NORMAL


func get_error_message(item: Item) -> String:
	if item.rarity != Item.Rarity.NORMAL:
		return "Alchemy Hammer can only be used on Normal items"   # was "Augment Hammer can only..."
	return ""


func _do_apply(item: Item) -> void:
	# Set rarity to RARE before adding mods (required for affix limit enforcement)
	item.rarity = Item.Rarity.RARE

	var mod_count = randi_range(4, 6)
	for i in range(mod_count):
		var choose_prefix = randi_range(0, 1) == 0
		if choose_prefix:
			if not item.add_prefix():
				if not item.add_suffix():
					break
		else:
			if not item.add_suffix():
				if not item.add_prefix():
					break

	item.update_value()
```
*Diff vs `forge_hammer.gd`: `class_name ForgeHammer` → `class_name AlchemyHammer`, two string literals. Body is byte-identical.*

### Renamed: Divine Hammer (NEW-02) — logic unchanged

```gdscript
# models/currencies/divine_hammer.gd (was tuning_hammer.gd)
class_name DivineHammer extends Currency


func _init() -> void:
	currency_name = "Divine Hammer"   # was "Exalt Hammer"


## Returns true if item has at least one explicit mod (prefix or suffix).
func can_apply(item: Item) -> bool:
	return item.prefixes.size() > 0 or item.suffixes.size() > 0


func get_error_message(item: Item) -> String:
	if item.prefixes.size() == 0 and item.suffixes.size() == 0:
		return "Item has no mods to reroll"
	return ""


## Rerolls all explicit mod values within their tier ranges. Implicit untouched.
func _do_apply(item: Item) -> void:
	for prefix in item.prefixes:
		prefix.reroll()
	for suffix in item.suffixes:
		suffix.reroll()
	item.update_value()
```
*Diff vs `tuning_hammer.gd`: class_name and display name only. Existing comments mentioning CRAFT-06 should be preserved as-is (they're historical traceability per CONVENTIONS.md "Phase references" section).*

### Renamed: Annulment Hammer (NEW-03) — logic unchanged

```gdscript
# models/currencies/annulment_hammer.gd (was claw_hammer.gd)
class_name AnnulmentHammer extends Currency


func _init() -> void:
	currency_name = "Annulment Hammer"   # was "Chaos Hammer"


## Returns true if item has at least one explicit mod (prefix or suffix).
## Works on any rarity (Magic or Rare) that has mods.
func can_apply(item: Item) -> bool:
	return item.prefixes.size() > 0 or item.suffixes.size() > 0


func get_error_message(item: Item) -> String:
	if item.prefixes.size() == 0 and item.suffixes.size() == 0:
		return "Item has no mods to remove"
	return ""


## Removes one random explicit mod from the item without changing rarity.
func _do_apply(item: Item) -> void:
	var all_mods: Array[Dictionary] = []
	for i in range(item.prefixes.size()):
		all_mods.append({"type": "prefix", "index": i})
	for i in range(item.suffixes.size()):
		all_mods.append({"type": "suffix", "index": i})

	if all_mods.size() > 0:
		var selected = all_mods.pick_random()
		if selected["type"] == "prefix":
			item.prefixes.remove_at(selected["index"])
		else:
			item.suffixes.remove_at(selected["index"])

	item.update_value()
```
*Diff vs `claw_hammer.gd`: class_name and display name only. Existing comment "CRAFT-05 explicitly says 'without changing rarity'" should be preserved.*

### Forge View Dict Rewiring

Source: `scenes/forge_view.gd:37-49`

```gdscript
# BEFORE (Phase 1 in-progress)
var currencies: Dictionary = {
	"transmute": RunicHammer.new(),
	"augment": ForgeHammer.new(),      # WRONG: ForgeHammer is Alchemy behavior
	"alteration": TackHammer.new(),
	"regal": GrandHammer.new(),
	"chaos": ClawHammer.new(),          # WRONG: ClawHammer is Annulment behavior
	"exalt": TuningHammer.new(),        # WRONG: TuningHammer is Divine behavior
	"fire": TagHammer.new(Tag.FIRE, "Fire Hammer"),
	"cold": TagHammer.new(Tag.COLD, "Cold Hammer"),
	"lightning": TagHammer.new(Tag.LIGHTNING, "Lightning Hammer"),
	"defense": TagHammer.new(Tag.DEFENSE, "Defense Hammer"),
	"physical": TagHammer.new(Tag.PHYSICAL, "Physical Hammer"),
}

# AFTER Phase 1
var currencies: Dictionary = {
	"transmute": RunicHammer.new(),
	"augment": AugmentHammer.new(),     # NEW class, correct PoE behavior
	"alchemy": AlchemyHammer.new(),     # NEW key (not UI-wired until Phase 2)
	"alteration": TackHammer.new(),
	"regal": GrandHammer.new(),
	"chaos": ChaosHammer.new(),         # NEW class, correct PoE behavior
	"exalt": ExaltHammer.new(),         # NEW class, correct PoE behavior
	"divine": DivineHammer.new(),       # NEW key (not UI-wired until Phase 2)
	"annulment": AnnulmentHammer.new(), # NEW key (not UI-wired until Phase 2)
	"fire": TagHammer.new(Tag.FIRE, "Fire Hammer"),
	"cold": TagHammer.new(Tag.COLD, "Cold Hammer"),
	"lightning": TagHammer.new(Tag.LIGHTNING, "Lightning Hammer"),
	"defense": TagHammer.new(Tag.DEFENSE, "Defense Hammer"),
	"physical": TagHammer.new(Tag.PHYSICAL, "Physical Hammer"),
}
```

Note the dict grows from 11 entries to 14 entries. Existing base-hammer keys (`augment`, `chaos`, `exalt`) REPOINT to new classes; three new base-hammer keys (`alchemy`, `divine`, `annulment`) are ADDED.

### `@onready` Variable Rename

Source: `scenes/forge_view.gd:9, 12, 13` (and uses at 101, 104, 105, 115, 118, 119)

```gdscript
# BEFORE
@onready var forge_btn: Button = $HammerSidebar/ForgeHammerBtn
@onready var claw_btn: Button = $HammerSidebar/ClawHammerBtn
@onready var tuning_btn: Button = $HammerSidebar/TuningHammerBtn

# AFTER
@onready var alchemy_btn: Button = $HammerSidebar/AlchemyHammerBtn
@onready var annulment_btn: Button = $HammerSidebar/AnnulmentHammerBtn
@onready var divine_btn: Button = $HammerSidebar/DivineHammerBtn
```

All uses of `forge_btn`, `claw_btn`, `tuning_btn` (9 references total, all in `forge_view.gd`) must be renamed. See Pitfall 8 above for the `.bind()` signal-connection subtlety — the bind args may or may not be rekeyed depending on the "temporary inconsistency" strategy chosen.

## State of the Art

| Old (current codebase) | New (after Phase 1) | Impact |
|------------------------|---------------------|--------|
| Creative-named classes (`ClawHammer`, `ForgeHammer`, `TuningHammer`) with wrong `currency_name` strings | Literal PoE class names (`AnnulmentHammer`, `AlchemyHammer`, `DivineHammer`) matching their actual behavior | Code reads correctly; fewer "wait, which one is this?" bugs |
| 3 missing PoE base currencies (real Augment, Chaos, Exalt) | 3 new self-contained classes implementing the real behaviors | Matches PoE player expectations; completes the base currency set (6 → 9 counting RunicHammer as Transmute, with TackHammer as Alteration and GrandHammer as Regal for a full 6 non-tag base hammers) |
| Inconsistent naming pattern (creative + literal) | Consistent literal naming for 3 new + 3 renamed classes; 4 legacy creative names remain | Documented as partial migration in `CONVENTIONS.md`; fully resolvable later (deferred) |

**Deprecated/outdated:**
- `ClawHammer` class name — gone. Any archive doc referencing it is historical record (do not rewrite).
- `ForgeHammer` class name — gone.
- `TuningHammer` class name — gone.
- `forge_btn` / `claw_btn` / `tuning_btn` variables — renamed.
- `ForgeHammerBtn` / `ClawHammerBtn` / `TuningHammerBtn` scene nodes — renamed.

## Open Questions

1. **Should Phase 1 also seed the 3 new `currency_counts` keys in `GameState`?**
   - What we know: `autoloads/game_state.gd:97-104` (`initialize_fresh_game()`) and `:144-151` (`_wipe_run_state()`) hard-code 6 keys (`transmute`, `augment`, `alteration`, `regal`, `chaos`, `exalt`). The new `currencies` dict in `forge_view.gd` will hold 9 base-hammer keys after Phase 1 — the 3 new keys (`alchemy`, `divine`, `annulment`) will not be seeded in GameState.
   - What's unclear: CONTEXT.md scopes this as "all integration work is Phase 3" (save format is Phase 3). But if Phase 2 (UI) references `currency_counts["alchemy"]` directly for display before Phase 3 ships, it will read 0 (benign — dict access returns null/0 on missing key in GDScript, but `spend_currency()` explicitly rejects unknown keys at line 173).
   - Recommendation: **Seed zero counts in Phase 1** as a one-line addition to both functions (`"alchemy": 0, "divine": 0, "annulment": 0`). This is cheap, safe, and prevents Phase 2 from needing a GameState touch. If the planner prefers pure model-only Phase 1, defer to Phase 3 with save format work — either is defensible. Planner should make an explicit call.

2. **Should the `forge_view.gd` `hammer_descriptions` dict be updated in Phase 1?**
   - What we know: `scenes/forge_view.gd:72-84` has a `hammer_descriptions` dict with tooltip strings for the 6 base hammer keys. These strings currently describe the WRONG behaviors for the 3 relabeled keys (e.g., `"augment"` → "Turns a normal item into a rare item with 4-6 random mods" — that description matches Alchemy, not PoE Augment).
   - What's unclear: CONTEXT.md D-10 scopes tooltips to Phase 2 ("Phase 2 will add the 3 missing buttons AND fix the tooltips for all 8"). So descriptions should stay wrong in Phase 1 — temporarily mismatched.
   - Recommendation: **Leave `hammer_descriptions` unchanged in Phase 1.** Phase 2 rewrites the whole tooltip table. Document the staleness as an intentional Phase 1→2 interim state.

3. **Icon assets (`forge_hammer.png`, `claw_hammer.png`, `tuning_hammer.png`) keep their old creative filenames — is that OK?**
   - What we know: `scenes/forge_view.gd:87-94` preloads 3 PNG files by old creative name. The PNG filenames are not in CONTEXT.md's rename list.
   - What's unclear: Aesthetically, `claw_hammer.png` being used for the `"chaos"` key is wrong after Phase 1. But the icon asset arguably depicts a hammer shape, not a behavior. And renaming PNG files breaks `ExtResource` paths in `.tscn` files which requires editor-driven imports.
   - Recommendation: **Leave PNG filenames alone in Phase 1.** Phase 2 can re-art if needed. Filename ≠ class name in this codebase's conventions.

4. **Phase 1→2 interim UX risk: how to mitigate?**
   - What we know: CONTEXT.md D-10 acknowledges that after Phase 1 ships, the forge UI will have 3 buttons with stale labels. CONTEXT.md "deferred" section suggests "hiding the new buttons until Phase 2 or shipping them together."
   - What's unclear: Does the team plan to ship Phase 1 independently to users, or coalesce Phase 1+2 in one release?
   - Recommendation: **Plan assumes Phase 1 and Phase 2 ship together** unless planner/user explicitly decides otherwise. If shipping Phase 1 solo is desired, add a feature-flag task to hide the 3 renamed buttons behind a bool in `forge_view.gd`.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Custom in-engine Godot test harness at `tools/test/integration_test.gd` (~2485 lines, single file, sequential `_group_N_*()` functions) |
| Config file | None — test lives in a standalone `.tscn` scene (`tools/test/integration_test.tscn`) |
| Quick run command | Open `tools/test/integration_test.tscn` in Godot editor + press **F6**. No CLI runner. |
| Full suite command | Same as quick run — there's only one suite. All groups run together in `_ready()`. |

**No CI integration.** Tests run only inside the Godot editor. Manual engine launch is the gate.

### Phase Requirements → Test Map

Per CONTEXT.md scope: "Phase 3 will add coverage for the new behaviors." Phase 1's validation is:
  1. **Compile validation** — Godot editor loads the project without errors after class renames.
  2. **Hand-run smoke** — manually apply each renamed/new currency via `GameState.debug_hammers = true` (999 of each currency) and verify behavior matches PoE expectations.

Automated test writing is **explicitly deferred to Phase 3** (INT-03).

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FIX-01 | Augment adds 1 mod to Magic item with room; rejects full | unit (Phase 3) | Phase 3: new `_group_N_augment_hammer()` in `integration_test.gd` | ❌ Deferred to Phase 3 |
| FIX-02 | Chaos rerolls all mods on Rare with 4–6 new mods | unit (Phase 3) | Phase 3: new `_group_N_chaos_hammer()` | ❌ Deferred to Phase 3 |
| FIX-03 | Exalt adds 1 mod to Rare with room; rejects full | unit (Phase 3) | Phase 3: new `_group_N_exalt_hammer()` | ❌ Deferred to Phase 3 |
| NEW-01 | Alchemy converts Normal → Rare with 4–6 mods | unit (Phase 3) | Phase 3: new `_group_N_alchemy_hammer()` | ❌ Deferred to Phase 3 |
| NEW-02 | Divine rerolls explicit mod values (tier-bounded, mod types unchanged) | unit (Phase 3) | Phase 3: new `_group_N_divine_hammer()` | ❌ Deferred to Phase 3 |
| NEW-03 | Annulment removes 1 random mod from Magic or Rare; implicit untouched | unit (Phase 3) | Phase 3: new `_group_N_annulment_hammer()` | ❌ Deferred to Phase 3 |

### Sampling Rate for Phase 1

- **Per task commit:** Open Godot editor, confirm no parse/compile errors on affected files (especially `forge_view.gd` after dict + `@onready` rewiring). Look for `[FAIL]` / red warnings in the editor's Output panel.
- **Per wave merge:** Run existing `integration_test.tscn` (F6). It has ~50 groups; group 6 (`_group_6_crafting_regression`) uses `RunicHammer.new()` — planner should verify it still passes after rename. No existing group uses `ForgeHammer`/`ClawHammer`/`TuningHammer` class names directly, so the test suite should remain green through the rename. (Verified via grep: zero hits for those 3 class names in `integration_test.gd`.)
- **Phase gate:** Full suite green in Godot editor + manual validation of each new/renamed currency against a starter-kit item. Validation protocol (manual):
  1. Start fresh game (debug_hammers = true for 999 of each).
  2. Normal item → apply Alchemy → expect Rare + 4–6 mods.
  3. Magic item (1 mod) → apply Augment → expect 2 mods.
  4. Full Magic item (2 mods) → apply Augment → expect "no room" error toast.
  5. Rare item (mods present) → apply Chaos → expect 4–6 new mods.
  6. Rare item (mods present) → apply Divine → expect same mod types, different values (compare before/after).
  7. Rare item (3 mods) → apply Exalt → expect 4 mods.
  8. Full Rare (6 mods) → apply Exalt → expect "no room" error toast.
  9. Magic item (1 mod) → apply Annulment → expect 0 mods, rarity still Magic.

### Wave 0 Gaps

- [ ] None. Existing test infrastructure (`tools/test/integration_test.gd`) is sufficient for Phase 1 validation (which is "existing tests still pass after rename"). New test coverage for new behaviors is explicitly Phase 3 scope.
- [ ] Optional: planner may add a single smoke-test group `_group_51_hammer_models_sanity()` that instantiates each of the 9 base hammer classes (`RunicHammer`, `AugmentHammer`, `AlchemyHammer`, `TackHammer`, `GrandHammer`, `ChaosHammer`, `ExaltHammer`, `DivineHammer`, `AnnulmentHammer`) with `.new()` and asserts `currency_name` is the expected string + `can_apply(normal_item)` / `can_apply(magic_item)` / `can_apply(rare_item)` return the expected booleans. ~30 lines. Low cost, high confidence for a rename phase. Planner call — not required by CONTEXT.md.

## Sources

### Primary (HIGH confidence) — all in-repo
- `models/currencies/currency.gd` — Template Method contract (`apply` → `can_apply` + `_do_apply`)
- `models/currencies/claw_hammer.gd` — source for AnnulmentHammer (logic unchanged)
- `models/currencies/forge_hammer.gd` — source for AlchemyHammer (logic unchanged)
- `models/currencies/tuning_hammer.gd` — source for DivineHammer (logic unchanged)
- `models/currencies/grand_hammer.gd` — template for AugmentHammer / ExaltHammer (1-mod add)
- `models/currencies/runic_hammer.gd` — template for 4–6 roll loop pattern
- `models/currencies/tack_hammer.gd` — template for clear-then-reroll pattern
- `models/items/item.gd:1-60, 270-320` — `RARITY_LIMITS`, `max_prefixes()`, `max_suffixes()`, `add_prefix()`, `add_suffix()`
- `models/affixes/affix.gd:92-103` — `Affix.reroll()` behavior (used by Divine)
- `scenes/forge_view.gd:7-160` — `currencies` dict, `@onready` btns, button signal bindings
- `scenes/forge_view.tscn:60-180` — button node definitions (3 to rename)
- `scenes/node_2d.tscn:40-90` — secondary button node definitions (3 to rename)
- `autoloads/game_state.gd:6-180` — `currency_counts` seeding and `spend_currency()` behavior (runtime state concern Q1)
- `.planning/codebase/CONVENTIONS.md:11, 16` — creative-name convention text to update (D-06)
- `.planning/codebase/ARCHITECTURE.md:37` — `ForgeHammer` mention to update
- `.planning/research/STACK.md:206` — `ForgeHammer` mention to update
- `.planning/workstreams/fix-hammers/phases/01-hammer-models/01-CONTEXT.md` — user decisions
- `.planning/workstreams/fix-hammers/REQUIREMENTS.md` — FIX-01/02/03, NEW-01/02/03

### Secondary (MEDIUM confidence)
- PoE wiki conventions for Augment/Alchemy/Chaos/Divine/Annulment/Exalt behavior — inferred from the user's success criteria and FIX/NEW requirement descriptions. Not re-verified against PoE wiki; CONTEXT.md's D-11 through D-24 spell out the exact expected behaviors, which serve as the authoritative spec for this phase.

### Tertiary (LOW confidence)
- None. This phase has no external knowledge dependencies.

## Metadata

**Confidence breakdown:**
- Standard stack: **HIGH** — all facilities are in-repo, verified by direct file reads.
- Architecture: **HIGH** — patterns copied from existing hammer implementations, verified line-by-line.
- Pitfalls: **HIGH** — derived from actual code inspection (rarity ordering, `update_value()`, fallback exhaustion all observed in source).
- Runtime state: **HIGH** for Godot-local concerns, **MEDIUM** for the `currency_counts` seeding question (Q1) — flagged as open question because CONTEXT.md is ambiguous on whether Phase 1 or Phase 3 owns that change.
- Validation architecture: **HIGH** — Godot test harness inspected via `.planning/codebase/TESTING.md` and verified against `tools/test/integration_test.gd` references.

**Research date:** 2026-04-11
**Valid until:** Indefinite (this is a local refactor with no external dependency drift).
