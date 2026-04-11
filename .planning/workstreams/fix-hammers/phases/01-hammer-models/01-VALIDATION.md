---
phase: 1
slug: hammer-models
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-11
approved: 2026-04-11
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Godot `tools/test/integration_test.gd` (custom harness) |
| **Config file** | `tools/test/integration_test.gd` |
| **Quick run command** | `godot --headless --path . tools/test/integration_test.gd` |
| **Full suite command** | `godot --headless --path . tools/test/integration_test.gd` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick run command
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 01-01-T1 | 01 | 1 | NEW-01, NEW-02, NEW-03 | grep-assertion (rename metadata) | `grep -q "^class_name AnnulmentHammer extends Currency$" models/currencies/annulment_hammer.gd && grep -q "^class_name AlchemyHammer extends Currency$" models/currencies/alchemy_hammer.gd && grep -q "^class_name DivineHammer extends Currency$" models/currencies/divine_hammer.gd && grep -q 'currency_name = "Annulment Hammer"' models/currencies/annulment_hammer.gd && grep -q 'currency_name = "Alchemy Hammer"' models/currencies/alchemy_hammer.gd && grep -q 'currency_name = "Divine Hammer"' models/currencies/divine_hammer.gd && ! test -f models/currencies/claw_hammer.gd && ! test -f models/currencies/forge_hammer.gd && ! test -f models/currencies/tuning_hammer.gd && echo "RENAME OK"` | ✅ (post-run) | ⬜ pending |
| 01-01-T2 | 01 | 1 | NEW-01, NEW-02, NEW-03 | grep-assertion (wiring) | `! grep -q "ForgeHammer\|ClawHammer\|TuningHammer" scenes/forge_view.gd && ! grep -q "forge_btn\|claw_btn\|tuning_btn" scenes/forge_view.gd && grep -q '"alchemy": AlchemyHammer.new()' scenes/forge_view.gd && grep -q '"divine": DivineHammer.new()' scenes/forge_view.gd && grep -q '"annulment": AnnulmentHammer.new()' scenes/forge_view.gd && ! grep -q "ForgeHammerBtn\|ClawHammerBtn\|TuningHammerBtn" scenes/forge_view.tscn && ! grep -q "ForgeHammerBtn\|ClawHammerBtn\|TuningHammerBtn" scenes/node_2d.tscn && echo "WIRING OK"` | ✅ (post-run) | ⬜ pending |
| 01-01-T3 | 01 | 1 | NEW-01, NEW-02, NEW-03 | grep-assertion (live docs) | `! grep -q "ForgeHammer" .planning/codebase/CONVENTIONS.md && ! grep -q "ForgeHammer" .planning/codebase/ARCHITECTURE.md && grep -q "AlchemyHammer" .planning/codebase/CONVENTIONS.md && grep -q "AlchemyHammer" .planning/codebase/ARCHITECTURE.md && grep -q "literal PoE names" .planning/codebase/CONVENTIONS.md && echo "DOCS OK"` | ✅ (post-run) | ⬜ pending |
| 01-02-T1 | 02 | 2 | FIX-01, FIX-03 | grep-assertion (Augment + Exalt class structure) | `grep -q "^class_name AugmentHammer extends Currency$" models/currencies/augment_hammer.gd && grep -q "^class_name ExaltHammer extends Currency$" models/currencies/exalt_hammer.gd && grep -q 'currency_name = "Augment Hammer"' models/currencies/augment_hammer.gd && grep -q 'currency_name = "Exalt Hammer"' models/currencies/exalt_hammer.gd && grep -q "item.update_value()" models/currencies/augment_hammer.gd && grep -q "item.update_value()" models/currencies/exalt_hammer.gd && ! grep -q "item.rarity = " models/currencies/augment_hammer.gd && ! grep -q "item.rarity = " models/currencies/exalt_hammer.gd && ! grep -q "^func apply(" models/currencies/augment_hammer.gd && ! grep -q "^func apply(" models/currencies/exalt_hammer.gd && echo "AUG/EX OK"` | ✅ (post-run) | ⬜ pending |
| 01-02-T2 | 02 | 2 | FIX-02 | grep-assertion (Chaos class structure) | `grep -q "^class_name ChaosHammer extends Currency$" models/currencies/chaos_hammer.gd && grep -q 'currency_name = "Chaos Hammer"' models/currencies/chaos_hammer.gd && grep -q "item.prefixes.clear()" models/currencies/chaos_hammer.gd && grep -q "item.suffixes.clear()" models/currencies/chaos_hammer.gd && grep -q "randi_range(4, 6)" models/currencies/chaos_hammer.gd && grep -q "item.update_value()" models/currencies/chaos_hammer.gd && ! grep -q "item.rarity = " models/currencies/chaos_hammer.gd && ! grep -q "item.implicit" models/currencies/chaos_hammer.gd && ! grep -q "^func apply(" models/currencies/chaos_hammer.gd && echo "CHAOS OK"` | ✅ (post-run) | ⬜ pending |
| 01-02-T3 | 02 | 2 | FIX-01, FIX-02, FIX-03 | grep-assertion (dict repoint) | `grep -q '"augment": AugmentHammer.new()' scenes/forge_view.gd && grep -q '"chaos": ChaosHammer.new()' scenes/forge_view.gd && grep -q '"exalt": ExaltHammer.new()' scenes/forge_view.gd && grep -q '"alchemy": AlchemyHammer.new()' scenes/forge_view.gd && grep -q '"divine": DivineHammer.new()' scenes/forge_view.gd && grep -q '"annulment": AnnulmentHammer.new()' scenes/forge_view.gd && [ "$(grep -c 'AugmentHammer.new()' scenes/forge_view.gd)" = "1" ] && [ "$(grep -c 'ChaosHammer.new()' scenes/forge_view.gd)" = "1" ] && [ "$(grep -c 'ExaltHammer.new()' scenes/forge_view.gd)" = "1" ] && echo "DICT OK"` | ✅ (post-run) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*All 6 tasks have inline `<automated>` verify commands in their plan files. Feedback latency per task: sub-second (pure `grep` + `test` — no Godot runtime).*

---

## Wave 0 Requirements

- Existing integration test harness covers behavioral smoke testing.
- Unit-level test coverage for new hammer classes is **deferred to Phase 3** per CONTEXT.md decision D-testing.
- No MISSING references in any task's `<automated>` block — all 6 tasks verify using shell built-ins (`grep`, `test`) that exist today. Wave 0 test scaffolding is not required.

*Phase 1 validation gate: existing `integration_test.gd` must still pass after refactor + new class additions.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Augment Hammer rejects full Magic | FIX-01 | Godot UI smoke | Run game, create Magic with 2 prefix + 2 suffix, try Augment → confirm rejection |
| Chaos Hammer reroll count | FIX-02 | RNG distribution | Run game, apply Chaos 10x on Rare → confirm 4–6 mods each time |
| Exalt Hammer rejects full Rare | FIX-03 | Godot UI smoke | Run game, create Rare with 3+3 mods, try Exalt → confirm rejection |
| Alchemy Hammer Normal→Rare | NEW-01 | Godot UI smoke | Run game, apply Alchemy on Normal → confirm Rare with 4–6 mods |
| Divine rerolls values, not mods | NEW-02 | RNG + comparison | Record mod set pre-Divine, apply Divine, confirm identical mod IDs, different values |
| Annulment removes 1 random mod | NEW-03 | Godot UI smoke | Apply Annulment on Magic/Rare → confirm exactly 1 mod removed |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (none required — pure grep/test shell built-ins)
- [x] No watch-mode flags
- [x] Feedback latency < 10s (sub-second per task — grep/test only)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-11
