---
phase: 51
slug: stat-integration
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-25
---

# Phase 51 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Godot integration test scene (custom) |
| **Config file** | `tools/test/integration_test.gd` |
| **Quick run command** | Open Godot editor, run `tools/test/integration_test.gd` scene (F6) |
| **Full suite command** | Same — all 36 existing groups + new Group 37 run in `_ready()` |
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
| 51-01-01 | 01 | 1 | PASS-01 | unit | Group 37 in integration_test.gd | ❌ W0 | ⬜ pending |
| 51-01-02 | 01 | 1 | PASS-01 | unit | Group 37 in integration_test.gd | ❌ W0 | ⬜ pending |
| 51-01-03 | 01 | 1 | PASS-01 | unit | Group 37 in integration_test.gd | ❌ W0 | ⬜ pending |
| 51-01-04 | 01 | 1 | PASS-01 | unit | Group 37 in integration_test.gd | ❌ W0 | ⬜ pending |
| 51-01-05 | 01 | 1 | PASS-01 | unit | Group 37 in integration_test.gd | ❌ W0 | ⬜ pending |
| 51-01-06 | 01 | 1 | PASS-01 | unit | Group 37 in integration_test.gd | ❌ W0 | ⬜ pending |
| 51-01-07 | 01 | 1 | PASS-01 | unit | Group 37 in integration_test.gd | ❌ W0 | ⬜ pending |
| 51-01-08 | 01 | 1 | PASS-02 | unit | Group 37 in integration_test.gd | ❌ W0 | ⬜ pending |
| 51-01-09 | 01 | 1 | PASS-02 | unit | Group 37 in integration_test.gd | ❌ W0 | ⬜ pending |
| 51-01-10 | 01 | 1 | PASS-02 | unit | Group 37 in integration_test.gd | ❌ W0 | ⬜ pending |
| 51-01-11 | 01 | 1 | PASS-02 | unit | Group 37 in integration_test.gd | ❌ W0 | ⬜ pending |
| 51-01-12 | 01 | 1 | D-02 | unit | Group 37 in integration_test.gd | ❌ W0 | ⬜ pending |
| 51-01-13 | 01 | 1 | D-02 | unit | Group 37 in integration_test.gd | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tools/test/integration_test.gd` — add `_group_37_stat_integration()` covering all PASS-01/PASS-02/D-02 behaviors

*Existing test infrastructure covers framework needs. Only new test group needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Fire Knight with fire gear shows higher fire DPS in Hero View | PASS-01 | Requires Godot runtime + visual inspection | Equip fire gear, set archetype to str_elem, check Hero View DPS |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 2s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
