---
phase: 1
slug: hammer-models
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-11
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
| TBD | TBD | TBD | TBD | TBD | TBD | TBD | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Populated by planner from PLAN.md task list.*

---

## Wave 0 Requirements

- Existing integration test harness covers behavioral smoke testing.
- Unit-level test coverage for new hammer classes is **deferred to Phase 3** per CONTEXT.md decision D-testing.

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

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
