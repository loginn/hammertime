---
phase: 45
slug: affix-pool-expansion
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-06
---

# Phase 45 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | GDScript integration tests (no external framework) |
| **Config file** | `tools/test/integration_test.gd` |
| **Quick run command** | F6 in Godot editor (runs integration_test.gd) |
| **Full suite command** | F6 in Godot editor |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run F6 integration tests
- **After every plan wave:** Run F6 full suite
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 2 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 45-01-01 | 01 | 1 | AFF-01, AFF-02 | unit | F6 integration tests | ✅ | ⬜ pending |
| 45-01-02 | 01 | 1 | AFF-03 | unit | F6 integration tests | ✅ | ⬜ pending |
| 45-01-03 | 01 | 1 | AFF-05 | unit | F6 integration tests | ✅ | ⬜ pending |
| 45-02-01 | 02 | 1 | AFF-01, AFF-05 | unit | F6 integration tests | ✅ | ⬜ pending |
| 45-02-02 | 02 | 1 | AFF-01, AFF-05 | unit | F6 integration tests | ✅ | ⬜ pending |
| 45-03-01 | 03 | 2 | AFF-01-05 | integration | F6 integration tests | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements. Test groups 16-21 added to integration_test.gd during implementation.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Forge UI displays "Adds X to Y Damage" for new flat affixes | AFF-01, AFF-05 | Requires Godot editor visual inspection | Craft a SapphireRing, verify spell damage line shows range format |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 2s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
