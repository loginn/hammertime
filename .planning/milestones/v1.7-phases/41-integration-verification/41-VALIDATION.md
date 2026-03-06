---
phase: 41
slug: integration-verification
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-06
---

# Phase 41 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | GDScript test scene (custom [PASS]/[FAIL] runner) |
| **Config file** | none — created in this phase |
| **Quick run command** | Run `tools/test/test_prestige_integration.tscn` from Godot editor |
| **Full suite command** | Same — single test scene covers all groups |
| **Estimated runtime** | ~2 seconds (in-memory tests, no file I/O wait) |

---

## Sampling Rate

- **After every task commit:** Run test scene from editor, verify all [PASS]
- **After every plan wave:** Run full test scene
- **Before `/gsd:verify-work`:** All test groups must show [PASS], 0 [FAIL]
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 41-01-01 | 01 | 1 | all v1.7 | integration | Run test scene | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tools/test/test_prestige_integration.tscn` — test scene
- [ ] `tools/test/test_prestige_integration.gd` — test script with all 9 test groups

*No framework install needed — uses Godot's built-in scene runner.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Prestige tab visibility | UI gating | Requires visual inspection of tab bar | Play game, verify prestige tab hidden at P0, visible at P1 |
| Fade transition | UI polish | Visual animation timing | Trigger prestige, observe screen fade |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
