---
phase: 42
slug: tag-stat-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-06
---

# Phase 42 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Godot integration tests (GDScript) |
| **Config file** | `tools/test/integration_test.tscn` |
| **Quick run command** | Run scene `tools/test/integration_test.tscn` (F6) |
| **Full suite command** | Run scene `tools/test/integration_test.tscn` (F6) |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run integration_test.tscn
- **After every plan wave:** Run integration_test.tscn (full suite)
- **Before `/gsd:verify-work`:** Full suite must show "ALL PASSED"
- **Max feedback latency:** 2 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 42-01-01 | 01 | 1 | AFF-06 | integration | Run integration_test.tscn | Yes | pending |
| 42-01-02 | 01 | 1 | SPELL-01 | integration | Run integration_test.tscn | Yes | pending |
| 42-01-03 | 01 | 1 | SPELL-02 | integration | Run integration_test.tscn | Yes | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. The integration test suite in `tools/test/integration_test.gd` exercises Tag and StatType constants extensively. Pure constant additions require no new test stubs.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Game launches without errors | All | Godot parse errors only visible at runtime | Launch game, verify no console errors |
| Enum integer stability | All | Serialization values need manual spot-check | Print StatType values, verify FLAT_DAMAGE=0 through ALL_RESISTANCE=18 unchanged |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 2s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
