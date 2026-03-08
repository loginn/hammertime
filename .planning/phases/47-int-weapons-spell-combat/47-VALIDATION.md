---
phase: 47
slug: int-weapons-spell-combat
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-07
---

# Phase 47 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | GDScript integration tests (tools/test/) |
| **Config file** | tools/test/integration_test.gd |
| **Quick run command** | `Run scene in Godot editor` |
| **Full suite command** | `Run integration_test.gd scene` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Manual scene run verification
- **After every plan wave:** Run integration test scene
- **Before `/gsd:verify-work`:** Full integration suite must pass
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 47-01-01 | 01 | 1 | BASE-04 | unit | Integration test | TBD | pending |
| 47-01-02 | 01 | 1 | BASE-04 | unit | Integration test | TBD | pending |
| 47-02-01 | 02 | 2 | SPELL-06 | integration | Combat scene test | TBD | pending |
| 47-02-02 | 02 | 2 | SPELL-06 | manual | Visual combat check | N/A | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements. Integration test framework from Phase 44+ already in place.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Spell hit floating text color (purple/blue) | SPELL-06 | Visual rendering | Equip INT weapon, enter combat, verify spell hits show in distinct color |
| Dev toggle in settings | SPELL-06 | UI interaction | Open settings, toggle spell/attack mode, verify combat behavior changes |
| No crashes on weapon swap mid-combat | BASE-04 | State edge case | Swap between INT/STR/DEX weapons during active combat |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
