---
phase: 54
slug: polish-balance
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-27
---

# Phase 54 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | GDScript integration tests (custom runner) |
| **Config file** | `tools/test/integration_test.gd` |
| **Quick run command** | `(run scene in Godot)` |
| **Full suite command** | `(run integration_test scene)` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run existing Groups 37-39
- **After every plan wave:** Run full integration test suite
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 54-01-01 | 01 | 1 | PASS-03 | manual | Visual inspection of stat panel | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Hero title displays in archetype color | PASS-03 | BBCode color rendering requires visual check | Open ForgeView with a hero selected, verify title is colored |
| Passive bonus lines appear below title | PASS-03 | Layout/formatting is visual | Verify "Passive:" label and indented bonus lines |
| Classless Adventurer shows no hero section | PASS-03 | Absence of UI element | Start without hero selection, verify stat panel starts at Offense |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
