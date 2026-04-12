# Phase 3: Integration - Context

**Gathered:** 2026-04-12
**Status:** Ready for planning

<domain>
## Phase Boundary

New currencies (Alchemy, Divine, Annulment) appear in monster-pack drops with area gating, persist across save/load round-trips, and the integration test suite (`tools/test/integration_test.gd`) covers all 8 base hammer behaviors (apply success + apply rejection) per ROADMAP Phase 3 success criterion 4. Also includes a retune of Augment's drop gate, a bump of the save format version to 10, and the deletion of outdated saves on load.

**In scope:**
- `models/loot/loot_table.gd` — add alchemy/divine/annulment to `CURRENCY_AREA_GATES` and `pack_currency_rules`; tune augment's gate down to 5
- `autoloads/save_manager.gd` — bump `SAVE_VERSION` constant from 9 to 10; existing "delete outdated, start fresh" policy handles the migration path unchanged
- `tools/test/integration_test.gd` — add 7 new test groups (Transmute/Runic, Augment, Alchemy, Chaos, Exalt, Divine, Annulment) matching the Groups 48/49 structure; update Group 50 to reference v10 and include the 3 new currencies in the round-trip assertions
- Verification via the integration test harness (F6 in `tools/test/integration_test.tscn`)

**Out of scope:**
- UI work on the forge view (Phase 2 territory — buttons and tooltips already correct)
- Tag hammer behavior changes or tag hammer drops (they work; D-07 from Phase 2)
- Renaming the 4 creative-named classes (Runic/Tack/Grand/Tag) — deferred from Phase 1
- Save-format migration that preserves v9 currency counts (explicit delete-and-fresh policy choice)
- Phase 2 Godot-editor smoke check — stays separate, user runs it on their own time (kept in `02-01-SUMMARY.md` and `02-VERIFICATION.md` human_verification; does NOT block Phase 3)
- New crafting mechanics, new item types, drop-table restructure beyond adding the 3 new currency entries

</domain>

<decisions>
## Implementation Decisions

### Drop Tuning (INT-01)
- **D-01:** Add 3 new entries to `CURRENCY_AREA_GATES` in `models/loot/loot_table.gd`:
  ```gdscript
  "alchemy": 15,
  "annulment": 30,
  "divine": 65,
  ```
  Also retune existing `"augment"` gate from 15 down to 5 — user wants Augment available earlier to support Magic crafting loops from mid-game.
- **D-02:** Add 3 new entries to `pack_currency_rules` in `roll_pack_currency_drop()`:
  ```gdscript
  "alchemy":   {"chance": 0.20, "max_qty": 1},
  "annulment": {"chance": 0.15, "max_qty": 1},
  "divine":    {"chance": 0.15, "max_qty": 1},
  ```
  Keep existing rules for the other 6 currencies untouched (including Augment — only its gate changes, not its chance).
- **D-03:** `ramp_duration` stays at the default 12 for all new currencies. Full rate reached ~12 levels after unlock (alchemy ~level 27, annulment ~level 42, divine ~level 77). Augment's new gate 5 gives full rate ~level 17, which the user explicitly confirmed as the intent.
- **D-04:** Drop chance rationale:
  - Alchemy 0.20 — matches Regal/Chaos/Exalt rate; Alchemy creates Rares directly so it's slightly rarer than Augment (0.25)
  - Annulment 0.15 — rarer than Regal because it's a scalpel (removes, doesn't add)
  - Divine 0.15 — rarest of the 3 because it's a "finisher" currency; you only Divine an item you've already committed to
- **D-05:** `max_qty` = 1 for all 3 new currencies. Matches Regal/Chaos/Exalt. No bulk drops — new advanced currencies should feel earned.
- **D-06:** No changes to `roll_pack_tag_currency_drop()`, `PACK_ITEM_DROP_CHANCE`, or the rarity anchors. Tag hammer drops stay unchanged.

### Save Format (INT-02)
- **D-07:** Bump `SAVE_VERSION` constant in `autoloads/save_manager.gd` from 9 to 10. Single-line change on line 4.
- **D-08:** Do NOT add migration code. Existing policy (lines 62-64) — "delete outdated save, start fresh" — handles v9→v10 correctly and matches past precedent. Players on v9 will see the `push_warning` and start fresh next load; their currencies wipe but the game doesn't crash.
- **D-09:** No new migration functions, no conditional key-seeding, no version history comments. The bump is cosmetic from a code standpoint because `currency_counts` is already seeded with all 9 keys (alchemy/divine/annulment = 0) in `game_state.gd:97-107` from the Phase 1 pull-forward. The serialization via `.duplicate()` already includes the new keys — no save-path changes needed, only the constant.
- **D-10:** Group 50 in `integration_test.gd` must be updated:
  - Assertion `save_data["version"] == 9` → `== 10` (line 2436 or equivalent)
  - `v8_data` sanity check → remains valid because `8 < 10`; optionally also add a `v9_data` rejection assertion to prove v9 is now rejected
  - Add assertions that alchemy/divine/annulment currency counts round-trip (set to non-zero values, save, restore, verify)
- **D-11:** No rollback path for v10→v9 downgrade. One-way bump.

### Integration Tests (INT-03)
- **D-12:** Add **7 new test groups** (not 6 — the option label had a miscount). One group per currently-untested base hammer:
  - `_group_51_transmute_hammer()` — RunicHammer (Transmute)
  - `_group_52_augment_hammer()` — AugmentHammer
  - `_group_53_alchemy_hammer()` — AlchemyHammer
  - `_group_54_chaos_hammer()` — ChaosHammer
  - `_group_55_exalt_hammer()` — ExaltHammer
  - `_group_56_divine_hammer()` — DivineHammer
  - `_group_57_annulment_hammer()` — AnnulmentHammer
- **D-13:** Each new group MUST mirror the Groups 48/49 structure (3 sub-tests minimum):
  1. **Rejection test** — hammer rejected on wrong rarity/state; assert `can_apply()` is false AND `get_error_message()` returns the expected string
  2. **Success test** — hammer accepted on valid item; assert `can_apply()` is true, apply the hammer, assert the expected invariant change
  3. **Edge test** — boundary condition specific to that hammer (see D-14)
- **D-14:** Edge cases per hammer (the third sub-test):
  - **Transmute (Runic):** second Transmute on a Magic item — rejected (not Normal)
  - **Augment:** Magic item with full slots (1 prefix + 1 suffix) — rejected, error `"Magic item has no room for another mod"`
  - **Alchemy:** Magic or Rare input — rejected; also verify Rare output has 4-6 mods after success
  - **Chaos:** empty Rare (0 mods) — accepted per D-16 from Phase 1; assert Chaos rolls 4-6 new mods
  - **Exalt:** Rare item with full slots (3 prefixes + 3 suffixes) — rejected, error `"Rare item has no room for another mod"`
  - **Divine:** Normal item with 0 mods — `can_apply()` should be true per D-15 Phase 1 (Divine iterates whatever mods exist, no-op on empty); but a better edge test is to verify that Divine on a Magic item preserves mod NAMES while rerolling values (i.e. iterate item.prefixes before and after, check `affix_name` stays the same, values may differ)
  - **Annulment:** Magic with 0 mods — rejected (no mods to remove); assert error path
- **D-15:** **Invariant-only assertions** — never assert on specific affix names, specific roll values, or specific RNG outcomes. Match the Group 48/49 style:
  - GOOD: "has ≥1 mod after reroll", "rarity became Rare", "mod count decreased by exactly 1"
  - BAD: "prefix[0].affix_name == 'local_physical_damage'", "weapon.damage_min == 42"
- **D-16:** Do NOT seed RNG. Do NOT run loops for statistical bounds. Do NOT mock anything. Pure invariant testing with real autoloads, matching the existing harness conventions.
- **D-17:** Call each new `_group_N_*()` from `_ready()` in numeric order after `_group_50_save_v9_round_trip()` (which is renamed to `_group_50_save_v10_round_trip()` per D-10). Update the dispatch list at the top of `_ready()`.
- **D-18:** Group naming comment style matches existing groups:
  ```gdscript
  # --- Group 52: Augment Hammer (INT-03) ---
  func _group_52_augment_hammer() -> void:
      # INT-03: Augment adds 1 mod to Magic with room; rejected on Normal/Rare/full-magic
      ...
      print("Group 52: Augment Hammer — PASSED")
  ```
- **D-19:** Test setup boilerplate: use `Broadsword.new(8)` as the item under test (matches existing Groups 48/49), manipulate rarity/prefixes/suffixes directly to set up the scenario. No `_reset_fresh()` calls required inside a group unless the test exercises GameState side effects.
- **D-20:** Currency instances are created inline per group: `var hammer := AugmentHammer.new()`. No fixture sharing across groups.

### Plan Layout
- **D-21:** **3 plans in 2 waves:**
  - **Wave 1 (parallel, 2 plans):**
    - `03-01-PLAN.md` — LootTable drop rules (D-01 through D-06). Files: `models/loot/loot_table.gd`.
    - `03-02-PLAN.md` — Save format bump (D-07 through D-09). Files: `autoloads/save_manager.gd`.
  - **Wave 2 (serial, 1 plan):**
    - `03-03-PLAN.md` — Integration test groups + Group 50 v10 update (D-10, D-12 through D-20). Files: `tools/test/integration_test.gd`. Depends on wave 1 because tests assert against the new save version constant and verify drop behavior holds (though tests don't actually invoke `roll_pack_currency_drop` with seeded RNG — they just verify hammer behaviors directly).
- **D-22:** Wave 1 plans run in parallel — they touch disjoint files (`loot_table.gd` vs `save_manager.gd`). No cross-wave cross-plan data contracts.
- **D-23:** Wave 2 depends on wave 1 only via the `SAVE_VERSION = 10` constant (referenced in Group 50's updated assertions). No runtime coupling.
- **D-24:** Phase verification runs the integration test suite once (via the gsd-verifier reading the test file + checking for `print("Group N: ... — PASSED")` markers, since the test runner is Godot-editor-only and not CLI-invokable). Verifier also greps the constants and dict entries directly to verify the drops/save decisions landed.

### Verification Approach
- **D-25:** The integration test harness is NOT CLI-runnable (no `godot --headless` target set up). Structural verification strategy:
  - **Grep checks** against source files for constants, dict entries, group function names, `print("Group N: ...")` markers
  - **User manually runs** `tools/test/integration_test.tscn` via F6 in the Godot editor ONCE after all plans land; user reports pass/fail count back. This is a single gating verification step, not a loop.
  - Per D-17/D-18 from Phase 2 precedent, user-driven manual verification is acceptable when the harness cannot be automated.
- **D-26:** Phase 3 verification also checks that `phase_req_ids` INT-01, INT-02, INT-03 each map to at least one plan via plan frontmatter `requirements` field.

### Claude's Discretion
- Exact variable names inside the 7 new test groups (`magic_item`, `rare_item`, `hammer`, etc.) — follow Groups 48/49 style
- Exact error-message wording in assertions — copy from each currency's `get_error_message()` verbatim
- Whether to split long edge-case tests into helper functions or keep them inline (prefer inline for consistency with existing groups)
- Whether the 3 wave-1 plans use `gsd:execute-phase --wave 1` or just default execution
- Internal ordering of the 7 new groups beyond the numeric sequence
- Whether to also test the `Currency.apply()` consumed-on-success contract (D-25 from Phase 1) — optional bonus coverage

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & Requirements
- `.planning/workstreams/fix-hammers/ROADMAP.md` §"Phase 3: Integration" — goal, 4 success criteria, INT-01/02/03 mapping
- `.planning/workstreams/fix-hammers/REQUIREMENTS.md` §"UI & Integration" — INT-01/02/03 definitions and traceability table
- `.planning/workstreams/fix-hammers/PROJECT.md` — milestone context; notes that save format needs version bump and existing saves "need currency count migration or fresh start" (resolved: fresh start per D-08)

### Prior Phase Handoff Documents
- `.planning/workstreams/fix-hammers/phases/01-hammer-models/01-CONTEXT.md` §D-25 (template method contract), §D-03 (byte-identical logic for renamed hammers), §D-11–D-24 (per-hammer behavior specs — drives test invariants in D-14 above)
- `.planning/workstreams/fix-hammers/phases/01-hammer-models/01-VERIFICATION.md` — confirms all 9 currency classes exist and the `hammers` dict wiring is correct
- `.planning/workstreams/fix-hammers/phases/02-forge-ui/02-CONTEXT.md` §D-07 (tag hammers untouched), §D-17/D-18 (structural-only verification precedent)

### Code Under Modification
- `models/loot/loot_table.gd` lines 21-28 (`CURRENCY_AREA_GATES` — 3 new entries + augment retune)
- `models/loot/loot_table.gd` lines 60-96 (`roll_pack_currency_drop` → `pack_currency_rules` dict — 3 new entries)
- `models/loot/loot_table.gd` lines 38-53 (`_calculate_currency_chance` — unchanged, already supports any gate)
- `autoloads/save_manager.gd` line 4 (`SAVE_VERSION` constant — bump 9→10)
- `autoloads/save_manager.gd` lines 62-67 (outdated-save policy — unchanged, already handles v10 correctly)
- `autoloads/save_manager.gd` lines 95, 141-142 (currency serialization/restoration — unchanged, forward-compatible)
- `tools/test/integration_test.gd` lines 55-60 (_ready dispatch list — 7 new calls + Group 50 rename)
- `tools/test/integration_test.gd` lines 2320-2390 (Groups 48/49 reference structure — pattern to mirror in 7 new groups)
- `tools/test/integration_test.gd` lines 2391-2485 (Group 50 save round-trip — rename + v10 update + new currency assertions)

### Reference Patterns (read before writing test groups)
- `tools/test/integration_test.gd` `_group_48_alteration_hammer()` (lines 2320-2351) — canonical "3 sub-test" structure for a single-hammer group (reject / accept / reject-edge)
- `tools/test/integration_test.gd` `_group_49_regal_hammer()` (lines 2354-2386) — canonical structure for a hammer that changes rarity
- `tools/test/integration_test.gd` `_check()` helper (early in file, ~line 100-ish) — the assertion primitive
- `.planning/codebase/TESTING.md` — full harness conventions, why there is no mocking, why RNG is not seeded

### Currency Behavior Truth Table (drives test invariants)
- `models/currencies/runic_hammer.gd` — Transmute behavior (Normal → Magic with 1 mod)
- `models/currencies/augment_hammer.gd` — Augment behavior (Magic + room → +1 mod)
- `models/currencies/alchemy_hammer.gd` — Alchemy behavior (Normal → Rare with 4-6 mods)
- `models/currencies/tack_hammer.gd` — Alteration behavior (Magic mods reroll, already tested in Group 48)
- `models/currencies/grand_hammer.gd` — Regal behavior (Magic → Rare with +1 mod, already tested in Group 49)
- `models/currencies/chaos_hammer.gd` — Chaos behavior (Rare mods replaced with 4-6 new)
- `models/currencies/exalt_hammer.gd` — Exalt behavior (Rare + room → +1 mod)
- `models/currencies/divine_hammer.gd` — Divine behavior (reroll mod values, preserve names)
- `models/currencies/annulment_hammer.gd` — Annulment behavior (remove 1 random mod from Magic/Rare)
- `models/items/item.gd` lines 5-9 (`RARITY_LIMITS`) — Normal 0/0, Magic 1/1, Rare 3/3 — authoritative for "has room" edge tests

### GameState Integration
- `autoloads/game_state.gd` lines 97-107 — `currency_counts` initialization (all 9 keys already seeded)
- `autoloads/game_state.gd` lines 147-157 — `_wipe_run_state()` currency reset (mirrors initialization)

### Codebase Conventions
- `.planning/codebase/CONVENTIONS.md` — GDScript style (tabs, naming, doc comments)
- `.planning/codebase/ARCHITECTURE.md` §"Layers" — autoload vs model vs scene boundaries
- `.planning/codebase/TESTING.md` — test harness conventions, no mocking, sequential-group pattern

### Not to touch (archive — historical record)
- `.planning/milestones/**`
- `.planning/debug/resolved/**`
- `.planning/workstreams/milestone/phases/**`
- `.planning/quick/**`
- Any file under `scenes/` — Phase 2 owned UI; Phase 3 does not touch scenes
- `scenes/forge_view.gd` or `scenes/forge_view.tscn` — untouched
- `models/currencies/*.gd` — Phase 1 already finalized these

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`_calculate_currency_chance()`** (`loot_table.gd:38`) — already supports any unlock level and any ramp_duration. New currencies just need entries in the `CURRENCY_AREA_GATES` and `pack_currency_rules` dicts; the ramp math is free.
- **`_check(condition, description)`** (`integration_test.gd`) — the assertion primitive used by every group. Writes to pass/fail counters, never aborts.
- **`currency_counts` dict seeding** (`game_state.gd:97-107`) — all 9 keys (including alchemy/divine/annulment = 0) are already there from Phase 1 pull-forward. Save serializer via `.duplicate()` picks them up automatically.
- **`SaveManager._build_save_data()` / `_restore_state()`** — already uses key iteration (`for currency_type in saved_currencies`), which is forward-compatible. Only the `SAVE_VERSION` constant needs to change.

### Established Patterns
- **One group = one feature area** (TESTING.md). Don't cram 3 hammers into one group — matches D-12's 7-group split.
- **No mocking, no RNG seeding, no async** — every test is synchronous and operates on real autoloads. D-16 honors this.
- **`print("Group N: Name — PASSED")` at the end of each group** — used by verifiers as a grep-able success marker. Included in D-18's example.
- **Item instantiation inside each group** — e.g., `var magic_item := Broadsword.new(8)`. No shared fixtures. D-19 matches.
- **Rarity-manipulated-then-mod-added setup** — Groups 48/49 show the idiom: construct with `Broadsword.new(8)`, set `.rarity = Item.Rarity.MAGIC`, clear prefixes/suffixes, then add via `.add_prefix()` / `.add_suffix()`.

### Integration Points
- **`loot_table.gd` → `combat_engine.gd` or `pack_runner.gd`** — the `roll_pack_currency_drop()` function is called on pack kills. Adding entries to the dicts automatically makes them drop; no caller changes needed. (Verify this is still the case — quick grep before planning.)
- **`save_manager.gd:141` `for currency_type in saved_currencies: GameState.currency_counts[currency_type] = ...`** — forward-compatible loop. Loading a v10 save where the player collected 47 alchemies will set `currency_counts["alchemy"] = 47` cleanly.
- **`integration_test.tscn` run trigger** — the scene's `_ready()` dispatches all groups sequentially. Adding 7 new groups and a rename to Group 50 requires updating the dispatch list at the top of `_ready()`.

### Non-Integration Points (intentional)
- **Forge view (`scenes/forge_view.gd`) does NOT read from loot_table** — it reads from `GameState.currency_counts`. So drop changes surface automatically in the forge without UI changes. (Phase 2's work is independent of Phase 3.)
- **PrestigeManager** is unrelated to new currency drops. Tag currency drops (prestige-gated) stay untouched per D-06.

### Sidebar Space Budget
- Not relevant to Phase 3 (no UI work).

</code_context>

<specifics>
## Specific Ideas

- **"Unlock Augment earlier (gate 5) and Alchemy at 15"** — the user wants to dismantle the "Magic crafting comes mid-game" gate by making Augment available from level 5. Alchemy follows at 15 as the natural Rare-creation graduation. This adjusts the intended player progression: quick access to Magic crafting, delayed access to Rare creation.
- **"Divine is a finisher, Annulment is a scalpel"** — drop chances reflect emotional role: Divine is rarer (0.15) than Chaos/Exalt (0.20) because you only reach for it after your item is already committed. Annulment is rarer than Regal (0.15 vs 0.20) because a mod-removal is a surgical action, not a progression step.
- **"Delete-and-fresh is the existing policy — don't build migration code for a hobby project"** — the save bump strategy explicitly rejects building a v9→v10 migrator. Players lose their currency counts on bump; this is acceptable cost for simplicity.
- **"Match Groups 48/49 — I like the reject/accept/edge shape"** — the reference pattern for the 7 new groups is already in the codebase. Don't reinvent; don't add group-level helpers; don't extract a shared `_test_hammer(hammer, valid_item, invalid_item)` helper — the codebase pattern is self-contained per group.
- **"Phase 2 smoke check stays separate"** — the user is explicit that Phase 2 human verification does not bleed into Phase 3. It sits in `02-01-SUMMARY.md` and `02-VERIFICATION.md` human_verification indefinitely until the user manually confirms.

</specifics>

<deferred>
## Deferred Ideas

- **v9→v10 migration path** that preserves currency counts — rejected for this milestone per D-08 (delete-and-fresh is simpler). Could be revisited if future version bumps justify the infrastructure.
- **Headless test runner** (e.g., `godot --headless --script tools/test/integration_test.gd`) — would enable CI-style automated verification but is out of scope. Manual F6 verification suffices.
- **Drop-rate rebalance for existing currencies** (Transmute, Alteration, Regal, Chaos, Exalt) — only Augment's gate changes in this phase (5 instead of 15). Other existing drop rates stay untouched.
- **Currency drop telemetry / logging** — not needed; tests verify behavior, playthrough verifies tuning.
- **Renaming the 4 creative-named classes** (Runic/Tack/Grand/Tag → literal names) — carried over from Phase 1 deferred ideas. Still deferred.
- **Shared `Currency.roll_random_mods(item, count)` helper** — carried over from Phase 1 deferred ideas. Still deferred.
- **Test selection / parallel test execution** — existing harness runs all 50+ groups sequentially. Adding CI-grade isolation is a future concern.
- **Auto-seeding RNG for deterministic tests** — rejected per D-16. The invariant-only style is the project's signature; preserving it matters more than deterministic outcomes.
- **Additional edge cases** (Divine on item with implicits only, Annulment on implicit-only item, etc.) — not in this phase. The 7 new groups + Group 50 update satisfy the ROADMAP criterion; deeper edge coverage is a follow-up phase if UAT reveals gaps.
- **Tag hammer tests** — tag hammers already work and are explicitly out of scope (D-07 Phase 2). Could add coverage in a future phase if tag behavior ever changes.

</deferred>

---

*Phase: 03-integration*
*Context gathered: 2026-04-12*
