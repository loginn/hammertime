---
phase: 50
slug: data-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-24
---

# Phase 50 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Godot integration test scene (custom) |
| **Config file** | `tools/test/integration_test.gd` |
| **Quick run command** | Open Godot editor, run `tools/test/integration_test.gd` scene (F6) |
| **Full suite command** | Same — all existing groups + new Group 36 run in `_ready()` |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run `tools/test/integration_test.gd` scene (F6)
- **After every plan wave:** Run full suite (all groups)
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 2 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 50-01-01 | 01 | 1 | HERO-01 | unit | Group 36 in integration_test.gd | ❌ W0 | ⬜ pending |
| 50-01-02 | 01 | 1 | HERO-01 | unit | Group 36 in integration_test.gd | ❌ W0 | ⬜ pending |
| 50-01-03 | 01 | 1 | HERO-02 | unit | Group 36 in integration_test.gd | ❌ W0 | ⬜ pending |
| 50-01-04 | 01 | 1 | HERO-02 | unit | Group 36 in integration_test.gd | ❌ W0 | ⬜ pending |
| 50-01-05 | 01 | 1 | HERO-02 | smoke | Group 36 in integration_test.gd | ❌ W0 | ⬜ pending |
| 50-01-06 | 01 | 1 | HERO-03 | unit | Group 36 in integration_test.gd | ❌ W0 | ⬜ pending |
| 50-01-07 | 01 | 1 | HERO-03 | unit | Group 36 in integration_test.gd | ❌ W0 | ⬜ pending |
| 50-01-08 | 01 | 1 | HERO-02 | unit | Group 36 in integration_test.gd | ❌ W0 | ⬜ pending |
| 50-01-09 | 01 | 1 | HERO-02 | unit | Group 36 in integration_test.gd | ❌ W0 | ⬜ pending |
| 50-01-10 | 01 | 1 | HERO-02 | unit | Group 36 in integration_test.gd | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tools/test/integration_test.gd` — add `_group_36_hero_archetype_data()` covering all HERO-01/02/03 behaviors

*Existing test infrastructure covers framework needs. Only new test group needed.*

---

## Manual-Only Verifications

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 2s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
