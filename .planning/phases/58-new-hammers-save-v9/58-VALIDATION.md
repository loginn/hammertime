---
phase: 58
slug: new-hammers-save-v9
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-29
---

# Phase 58 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Custom GDScript integration test harness |
| **Config file** | `tools/test/integration_test.gd` (scene: `tools/test/integration_test.tscn`) |
| **Quick run command** | Run scene in Godot editor (F6 with test scene active) |
| **Full suite command** | Same — all groups run in `_ready()` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run test scene (F6)
- **After every plan wave:** Run full test suite
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 58-01-01 | 01 | 1 | CRFT-01 | unit | Run test scene | No — W0 | pending |
| 58-01-02 | 01 | 1 | CRFT-02 | unit | Run test scene | No — W0 | pending |
| 58-02-01 | 02 | 1 | CRFT-03 | integration | Run test scene | No — W0 | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `_group_48_alteration_hammer()` in `tools/test/integration_test.gd` — covers CRFT-01
- [ ] `_group_49_regal_hammer()` in `tools/test/integration_test.gd` — covers CRFT-02
- [ ] `_group_50_save_v9_round_trip()` in `tools/test/integration_test.gd` — covers CRFT-03
- [ ] All three group calls added to `_ready()` after existing `_group_47_stash_tooltip_text()` call

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Hammer button tooltip text correct | CRFT-01, CRFT-02 | Visual UI text | Check forge_view tooltip strings |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
