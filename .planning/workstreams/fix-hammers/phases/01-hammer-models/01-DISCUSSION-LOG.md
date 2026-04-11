# Phase 1: Hammer Models - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-11
**Phase:** 01-hammer-models
**Areas discussed:** Refactor strategy, New file/class naming, Scene button node renames, Annulment edge cases, Alchemy/Chaos mod-count curve, Chaos code reuse

---

## Refactor Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Repoint + add new | Keep class names unchanged, update currency_name strings and forge_view dict keys only. Minimal diff. Class names no longer self-document behavior. | |
| Rename + add new | Rename class_name, file name, and display name. Touches all references (tests, scenes, docs) but leaves self-documenting code. | ✓ |
| Rewrite in place | Keep class names, rewrite _do_apply() to match correct PoE behavior. Discards working code, biggest churn. | |

**User's choice:** Rename + add new
**Notes:** User clarified the difference between "Repoint" and "Rename" first; once scoped clearly, they chose Rename for the self-documentation benefit. User explicitly added "just make sure to change all refs" — signalling awareness of the cascading update cost.

---

## New Class Names (for the 3 NEW currencies: Augment/Chaos/Exalt)

| Option | Description | Selected |
|--------|-------------|----------|
| Literal (AugmentHammer, etc.) | Consistent with renamed trio; all 8 base hammers use literal names. Abandons creative-name convention. | ✓ |
| Creative names | Invent new creative names (PinHammer, SmashHammer, etc.) to preserve the Runic/Tack/Grand pattern. Half-and-half naming. | |

**User's choice:** Literal (AugmentHammer, ChaosHammer, ExaltHammer)

---

## Scene Button Node Renames

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, rename nodes | Rename ClawHammerBtn → AnnulmentHammerBtn etc. in forge_view.tscn + node_2d.tscn. Cascades into @onready paths. Scene tree stays self-documenting. | ✓ |
| No, leave button nodes | Keep old button names. Internal names, user never sees them. Smaller diff, inconsistent with class names. | |
| Defer to Phase 2 | Leave scene files alone in Phase 1 (roadmap positions Phase 1 as model-only). Phase 2 handles forge UI work. | |

**User's choice:** Yes, rename nodes
**Notes:** User chose to rename even though the option flagged that Phase 2 owns forge UI work. The Phase 1 → Phase 2 transition temporarily exposes stale button labels (flagged in CONTEXT.md deferred ideas).

---

## Annulment: Empty Magic Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Stay Magic with 0 mods | Matches PoE. Rarity preserved, enables Augment→Annulment→Augment crafting loop. Existing ClawHammer already does this. | ✓ |
| Downgrade to Normal | Cleaner invariant ("Magic always has ≥1 mod") but diverges from PoE. | |

**User's choice:** Stay Magic with 0 mods

---

## Annulment: Rarity Guard in can_apply()

| Option | Description | Selected |
|--------|-------------|----------|
| Just check "has mods" | Keep existing ClawHammer logic: prefixes.size() > 0 or suffixes.size() > 0. Rarity check redundant. | ✓ |
| Also validate rarity | Add explicit Magic/Rare check for clearer error messages. Functionally identical. | |

**User's choice:** Just check "has mods"

---

## Annulment: Can It Remove Implicit?

| Option | Description | Selected |
|--------|-------------|----------|
| No — explicit mods only | Annulment pool = prefixes + suffixes. Implicit untouchable. Matches PoE and existing code. | ✓ |
| Yes — anything on the item | Diverges from PoE and from every other currency in the codebase. | |

**User's choice:** No — explicit mods only

---

## Alchemy/Chaos Mod-Count Distribution

| Option | Description | Selected |
|--------|-------------|----------|
| Keep uniform 4-6 | 1/3 each for 4, 5, 6 mods. Existing ForgeHammer logic verbatim. Predictable, zero code change for Alchemy. | ✓ |
| Weighted center (25/50/25) | More "typical" rolls in the middle. Requires new helper code. | |
| Weighted high (15/35/50) | Generous crafting, skew toward 6 mods. Requires balance justification. | |

**User's choice:** Keep uniform 4-6

---

## Chaos Code Reuse

| Option | Description | Selected |
|--------|-------------|----------|
| Duplicate the logic | Chaos._do_apply() contains its own clear+roll code. Matches current codebase pattern (each hammer self-contained). | ✓ |
| Extract shared helper | Pull roll logic into Currency.roll_random_mods(). DRY but adds abstraction not used elsewhere. | |
| Chaos inherits from Alchemy | class_name ChaosHammer extends AlchemyHammer. Most DRY but semantically weird IS-A relationship. | |

**User's choice:** Duplicate the logic

---

## Final Gate

| Option | Description | Selected |
|--------|-------------|----------|
| Ready for context | Write CONTEXT.md and queue plan-phase. | ✓ |
| Discuss error messages | Lock down exact error strings for new currencies. | |
| Discuss Chaos "has mods" precondition | PoE allows Chaos on empty Rare — nuance flagged. | |
| Something else | User has another gray area to raise. | |

**User's choice:** Ready for context

---

## Claude's Discretion

- Internal variable naming in new `_do_apply()` methods (follow existing conventions)
- Doc-comment style on new classes (match `grand_hammer.gd`/`runic_hammer.gd`)
- Print/logging inside `_do_apply()` — default to none, matching existing currencies
- Exact error-message phrasing (documented as defaults in CONTEXT.md D-18/21/24, open to Phase 2 UX revision)
- Chaos precondition: Chaos works on Rare regardless of current mod count (PoE-correct, doesn't require user decision)

## Deferred Ideas

- Rename the 4 untouched creative-named currency classes (Runic/Tack/Grand/Tag) — deferred as a future cleanup phase
- Shared currency helper `Currency.roll_random_mods(item, count)` — deferred, not worth the abstraction right now
- Phase 1 → Phase 2 shipping gap creates temporary UI inconsistency — mitigation flagged
- Error-message copy refinement — deferred to Phase 2 UX pass
