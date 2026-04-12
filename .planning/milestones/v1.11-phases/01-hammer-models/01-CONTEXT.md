# Phase 1: Hammer Models - Context

**Gathered:** 2026-04-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver 8 base hammer currency models that behave exactly as a PoE player expects. Three existing hammers have mismatched labels vs behavior (Chaos, Augment, Exalt) — their current code actually implements the 3 missing currencies (Annulment, Alchemy, Divine). This phase reconciles labels, logic, and class names, and adds correct implementations for the 3 genuinely-missing PoE hammers (Augment, Chaos, Exalt).

**In scope:** currency class renames/moves, new currency classes, updates to `scenes/forge_view.gd` hammers dict + `@onready` paths, scene-tree button node renames in `scenes/forge_view.tscn` and `scenes/node_2d.tscn`, updates to `.planning/codebase/` live docs that reference the renamed classes.

**Out of scope:** adding NEW buttons to the forge UI for Alchemy/Divine/Annulment (that's Phase 2), drop-table wiring, save-format changes, integration tests (all Phase 3). Tag hammer behavior is untouched — tag hammers work correctly today.

</domain>

<decisions>
## Implementation Decisions

### Refactor Strategy
- **D-01:** Rename + add new. The 3 existing mismatched currency classes already implement PoE-correct logic for the 3 "missing" currencies — rename them instead of rewriting. File renames use `git mv`:
  - `models/currencies/claw_hammer.gd` → `annulment_hammer.gd` (`ClawHammer` → `AnnulmentHammer`)
  - `models/currencies/forge_hammer.gd` → `alchemy_hammer.gd` (`ForgeHammer` → `AlchemyHammer`)
  - `models/currencies/tuning_hammer.gd` → `divine_hammer.gd` (`TuningHammer` → `DivineHammer`)
- **D-02:** Update `currency_name` string inside each renamed class: `"Chaos Hammer"` → `"Annulment Hammer"`, `"Augment Hammer"` → `"Alchemy Hammer"`, `"Exalt Hammer"` → `"Divine Hammer"`.
- **D-03:** The `_do_apply()`, `can_apply()`, and `get_error_message()` bodies of the 3 renamed classes stay **byte-identical** — only class/file/display-name metadata changes. Zero risk of regressing already-correct logic.
- **D-04:** Add 3 genuinely-new currency classes with correct PoE behaviors:
  - `models/currencies/augment_hammer.gd` → `class_name AugmentHammer`
  - `models/currencies/chaos_hammer.gd` → `class_name ChaosHammer`
  - `models/currencies/exalt_hammer.gd` → `class_name ExaltHammer`

### Naming Convention
- **D-05:** All 8 base hammer classes use **literal PoE names** (`AugmentHammer`, `ChaosHammer`, `ExaltHammer`, `AlchemyHammer`, `DivineHammer`, `AnnulmentHammer`, plus untouched `RunicHammer`/`TackHammer`/`GrandHammer`/`TagHammer`). The old "creative name" pattern (claw/forge/tuning) is abandoned in favor of self-documenting class names. The 4 creative names that stay (Runic/Tack/Grand/Tag) are the cost of that inconsistency — not worth the churn to also rename them in this phase.
- **D-06:** `CONVENTIONS.md` line 11 and 16 reference the old creative-name pattern — update them to the new literal convention.

### Forge View Rewiring
- **D-07:** Update `scenes/forge_view.gd` `hammers` dictionary (lines 38-48) to route new PoE currency keys to the correct classes:
  ```gdscript
  var hammers := {
      "transmute": RunicHammer.new(),      # unchanged
      "augment":   AugmentHammer.new(),    # NEW class
      "alchemy":   AlchemyHammer.new(),    # renamed from ForgeHammer
      "alteration": TackHammer.new(),      # unchanged
      "regal":     GrandHammer.new(),      # unchanged
      "chaos":     ChaosHammer.new(),      # NEW class
      "exalt":     ExaltHammer.new(),      # NEW class
      "divine":    DivineHammer.new(),     # renamed from TuningHammer
      "annulment": AnnulmentHammer.new(),  # renamed from ClawHammer
      "fire":      TagHammer.new(...),     # unchanged
      ...
  }
  ```
  Note: **Phase 1 only wires the dict** — the forge UI does not yet have buttons for alchemy/divine/annulment. Those buttons come in Phase 2. So three new keys exist in the dict but aren't referenced by any `@onready` button handler until Phase 2. This is intentional.

### Scene Tree Button Node Renames
- **D-08:** Rename button nodes in `scenes/forge_view.tscn` (lines 64, 136, 160 and their `CountLabel` children) and `scenes/node_2d.tscn` (lines 49, 73, 81):
  - `ForgeHammerBtn` → `AlchemyHammerBtn`
  - `ClawHammerBtn` → `AnnulmentHammerBtn`
  - `TuningHammerBtn` → `DivineHammerBtn`
- **D-09:** Update `@onready` var paths in `scenes/forge_view.gd` lines 9, 12, 13 to match the renamed nodes. The variable names (`forge_btn`, `claw_btn`, `tuning_btn`) should also be renamed for consistency (`alchemy_btn`, `annulment_btn`, `divine_btn`). Update every `forge_btn`/`claw_btn`/`tuning_btn` reference in the rest of `forge_view.gd`.
- **D-10:** **Phase 1 does NOT add new button nodes** for augment/chaos/exalt. Those buttons already exist in the scene (the old `ForgeHammerBtn`/`ClawHammerBtn`/`TuningHammerBtn` were labeled as Augment/Chaos/Exalt in tooltips). After the rename, the scene has buttons labeled "alchemy/divine/annulment" — which is wrong for Phase 1's UI state but correct in the dict. Phase 2 will add the 3 missing buttons AND fix the tooltips for all 8. The UI will be temporarily inconsistent between Phase 1 and Phase 2; that's acceptable.
  - **Risk flag:** if Phase 1 runs and Phase 2 hasn't shipped, the user will see 3 buttons with stale labels routed to the wrong currency types. Mitigation: keep Phases 1 and 2 in the same release/commit window, or add a disabled-by-default flag for the forge view.

### Annulment Behavior
- **D-11:** `AnnulmentHammer.can_apply()` checks "has ≥1 explicit mod" only (`prefixes.size() > 0 or suffixes.size() > 0`). No rarity check — Normal items have zero explicit mods so they're rejected implicitly. This is the existing `ClawHammer` behavior unchanged.
- **D-12:** Removing the last mod from a Magic item leaves the item **Magic with 0 mods**. `item.rarity` is never modified by Annulment. Matches PoE — empty Magic is a valid state and enables Augment→Annulment→Augment crafting loops.
- **D-13:** Annulment never touches `item.implicit`. Only `prefixes` and `suffixes` are in the removal pool. This matches the existing code and the behavior of Divine and Chaos.

### Alchemy Behavior
- **D-14:** `AlchemyHammer._do_apply()` is the existing `ForgeHammer._do_apply()` verbatim: set rarity to RARE, roll `randi_range(4, 6)` uniform, 50/50 prefix/suffix per mod with fallback to the other side when `add_prefix()`/`add_suffix()` returns false.

### Divine Behavior
- **D-15:** `DivineHammer._do_apply()` is the existing `TuningHammer._do_apply()` verbatim: iterate `item.prefixes` and `item.suffixes`, call `reroll()` on each. Implicit is untouched.

### Chaos Behavior (NEW)
- **D-16:** `ChaosHammer.can_apply()` = `item.rarity == Item.Rarity.RARE`. PoE allows Chaos on any Rare item, including rare items with zero mods (empty rares), so no "has mods" precondition.
- **D-17:** `ChaosHammer._do_apply()`: clear `item.prefixes` and `item.suffixes`, then roll 4-6 new mods using the same uniform-random + 50/50 + fallback pattern as Alchemy. **Implementation is duplicated inline**, not extracted into a shared helper — matches the codebase convention where each currency class is self-contained.
- **D-18:** `ChaosHammer.get_error_message()`: `"Chaos Hammer can only be used on Rare items"` when rarity ≠ Rare.

### Augment Behavior (NEW)
- **D-19:** `AugmentHammer.can_apply()` = `item.rarity == Item.Rarity.MAGIC AND has_room`, where `has_room := len(item.prefixes) < item.max_prefixes() or len(item.suffixes) < item.max_suffixes()`. Magic limits are 1/1 per `RARITY_LIMITS` in `models/items/item.gd:5-9`.
- **D-20:** `AugmentHammer._do_apply()`: add exactly 1 mod with 50/50 prefix/suffix choice and fallback — same 1-mod pattern as `GrandHammer._do_apply()` (Regal). Reuse that shape.
- **D-21:** `AugmentHammer.get_error_message()`:
  - Not Magic → `"Augment Hammer can only be used on Magic items"`
  - Magic but full (2 mods) → `"Magic item has no room for another mod"`

### Exalt Behavior (NEW)
- **D-22:** `ExaltHammer.can_apply()` = `item.rarity == Item.Rarity.RARE AND has_room`. Rare limits are 3/3 per `RARITY_LIMITS`.
- **D-23:** `ExaltHammer._do_apply()`: same 1-mod pattern as Augment but on a Rare item.
- **D-24:** `ExaltHammer.get_error_message()`:
  - Not Rare → `"Exalt Hammer can only be used on Rare items"`
  - Rare but full (6 mods) → `"Rare item has no room for another mod"`

### Template Method Contract
- **D-25:** All 6 affected currencies continue to inherit the `Currency.apply()` template method (`currency.gd:14-19`) — `apply()` calls `can_apply()`, and only calls `_do_apply()` if true. Currencies are consumed only on successful application. New classes override `can_apply()` and `_do_apply()`; do not override `apply()`.

### Claude's Discretion
- **Internal variable naming** inside new `_do_apply()` methods: follow existing conventions (`mod_count`, `choose_prefix`) — planner can match the existing patterns.
- **Doc comments** (`##`) on new classes: match the style used in `grand_hammer.gd` and `runic_hammer.gd` — short preamble above `can_apply()` explaining the rarity/room check, short preamble above `_do_apply()` explaining what it rolls.
- **Print/logging**: none — existing currencies don't log inside `_do_apply()`; don't start now.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & Requirements
- `.planning/workstreams/fix-hammers/ROADMAP.md` §"Phase 1: Hammer Models" — goal, success criteria, requirements mapping
- `.planning/workstreams/fix-hammers/REQUIREMENTS.md` — FIX-01/02/03, NEW-01/02/03 definitions
- `.planning/workstreams/fix-hammers/PROJECT.md` — milestone context and per-hammer intent

### Existing Currency Code (to rename or pattern-match against)
- `models/currencies/currency.gd` — `Currency` base class + `apply()` template method contract
- `models/currencies/claw_hammer.gd` — becomes `AnnulmentHammer`, logic unchanged
- `models/currencies/forge_hammer.gd` — becomes `AlchemyHammer`, logic unchanged
- `models/currencies/tuning_hammer.gd` — becomes `DivineHammer`, logic unchanged
- `models/currencies/grand_hammer.gd` — reference pattern for `AugmentHammer` and `ExaltHammer` (1-mod-add with 50/50 fallback)
- `models/currencies/runic_hammer.gd` — reference pattern for roll-N-mods logic
- `models/currencies/tack_hammer.gd` — reference pattern for "clear mods then re-roll" (informs Chaos)

### Item & Affix Model
- `models/items/item.gd:5-9` — `RARITY_LIMITS` constant: Normal 0/0, Magic 1/1, Rare 3/3
- `models/items/item.gd:22-31` — `max_prefixes()` / `max_suffixes()` methods
- `models/items/item.gd:278-317` — `add_prefix()` / `add_suffix()` contract (returns false on full slot or no valid affix)
- `models/affixes/affix.gd` — `Affix` resource structure, `reroll()` behavior (used by DivineHammer)

### Forge View Wiring
- `scenes/forge_view.gd:8-21` — `@onready` button refs (3 need renaming)
- `scenes/forge_view.gd:38-48` — `hammers` dict (keys to update, new entries to add)
- `scenes/forge_view.tscn` lines 64, 74, 136, 146, 160, 170 — button node definitions + `CountLabel` children
- `scenes/node_2d.tscn` lines 49, 73, 81 — alternate-scene button refs

### Live Code-Map Docs (need surgical updates)
- `.planning/codebase/ARCHITECTURE.md` line 37 — mentions `ForgeHammer` by old name
- `.planning/codebase/CONVENTIONS.md` lines 11, 16 — old creative-name example
- `.planning/research/STACK.md` — single reference to renamed class

### Not to touch (archive — historical record)
- `.planning/milestones/v1.3-phases/**`
- `.planning/milestones/v1.7-phases/**`
- `.planning/workstreams/milestone/phases/**`
- `.planning/debug/resolved/**`
- `.planning/quick/**`
These contain ~100 references to the old class names but are historical artifacts. Do not rewrite history.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Patterns
- **`Currency.apply()` template method** (`currency.gd:14-19`): All new classes override `can_apply()` and `_do_apply()` only. Never override `apply()` — it enforces the "consumed only on success" contract.
- **1-mod add with fallback** (from `grand_hammer.gd` Regal): `choose_prefix = randi_range(0,1) == 0; if choose_prefix: if not item.add_prefix(): item.add_suffix()`. This is exactly what Augment and Exalt need.
- **4-6 mod roll with fallback** (from `forge_hammer.gd` → becomes AlchemyHammer): Loop N times calling the 1-mod-add-with-fallback inner. Chaos duplicates this shape after clearing existing mods.
- **Clear-then-reroll** (from `tack_hammer.gd` Alteration): `item.prefixes.clear(); item.suffixes.clear(); <roll new mods>`. Chaos starts with this.

### Affix Limit Enforcement
- `add_prefix()`/`add_suffix()` return `false` if the slot is already full OR no valid affixes are available for the item's tags. Currency classes must handle the false return gracefully — either fall back to the other slot (Augment/Exalt/Alchemy/Chaos pattern) or simply stop rolling.
- **Subtle gotcha:** `add_prefix()` may return false because all tag-valid affixes are already on the item (`is_affix_on_item` check). For Alchemy/Chaos rolling 4-6 mods on an item with few tag-valid affixes, the fallback may exhaust options. Existing `ForgeHammer` handles this silently — the item ends up with fewer mods than rolled. This is acceptable and matches existing behavior.

### Rarity Transitions
- Alchemy (existing ForgeHammer): sets `item.rarity = Item.Rarity.RARE` **before** rolling mods, because affix limit checks depend on rarity (`RARITY_LIMITS`). Same constraint applies to any future currency that changes rarity.
- Chaos (new): item is **already Rare** when Chaos applies, so no rarity change.
- Augment / Exalt (new): never change rarity.
- Divine (existing TuningHammer): never changes rarity.
- Annulment (existing ClawHammer): never changes rarity — Magic with 0 mods stays Magic.

### Integration Points
- `scenes/forge_view.gd` `hammers` dict is the single source of truth mapping string currency keys → currency class instances. Any new currency must appear here to be usable.
- `tools/test/integration_test.gd` uses string keys (`"augment"`, `"chaos"`, etc.) and has **zero** class-name references — tests are safe through the rename. Phase 3 will add coverage for the new behaviors.

</code_context>

<specifics>
## Specific Ideas

- **Same-commit coupling:** rename commits should bundle class rename + `currency_name` update + forge_view dict update + scene button rename + @onready path update into single atomic commits per currency, so the project builds green at every commit.
- **Augment mirrors Regal:** `GrandHammer._do_apply()` (Regal) is structurally what `AugmentHammer._do_apply()` should look like, minus the `rarity = RARE` line. Copy the shape.
- **Exalt mirrors Augment:** same shape, just different `can_apply` rarity check.

</specifics>

<deferred>
## Deferred Ideas

- **Rename the 4 untouched creative-named classes** (`RunicHammer`, `TackHammer`, `GrandHammer`, `TagHammer`) to literal names (`TransmuteHammer`, `AlterationHammer`, `RegalHammer`, `TagHammer` stays since it's parameterized) — would fully complete the naming migration. Deferred because those currencies are not in the phase scope (they work correctly) and the churn isn't worth it right now. Could be a cleanup phase later.
- **Shared currency helper** (e.g. `Currency.roll_random_mods(item, count)`) — deferred because the codebase pattern is currently "each hammer is self-contained." A DRY refactor could consolidate Alchemy/Chaos/Tag/Runic roll logic but requires buy-in across the whole currency module.
- **Scope note on Phase 1→2 gap:** After Phase 1 ships, the forge UI will have 3 buttons with stale labels (`AlchemyHammerBtn`, `DivineHammerBtn`, `AnnulmentHammerBtn`) routing to the correct behaviors but showing wrong tooltips until Phase 2. If the gap between Phase 1 and Phase 2 shipping is more than a single work session, consider hiding the new buttons until Phase 2 or shipping them together.
- **Exact error-message copy** for the new currencies — accepted defaults in D-18/21/24. If UX review wants terser or more instructive strings, update in Phase 2 when tooltips are written.

</deferred>

---

*Phase: 01-hammer-models*
*Context gathered: 2026-04-11*
