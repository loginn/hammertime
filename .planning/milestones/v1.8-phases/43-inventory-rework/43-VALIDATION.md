---
phase: 43
slug: inventory-rework
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-06
---

# Phase 43 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | GDScript integration tests (tools/test/integration_test.gd) |
| **Config file** | tools/test/integration_test.gd |
| **Quick run command** | `grep -c "PASS\|FAIL" tools/test/integration_test.gd` (manual review) |
| **Full suite command** | Run game scene with integration_test.gd autoload |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Review changed files for array-to-nullable patterns
- **After every plan wave:** Run full integration test suite
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 43-01-01 | 01 | 1 | INV-01 | unit | integration_test assertions | Yes | pending |
| 43-01-02 | 01 | 1 | INV-05 | unit | save round-trip test | Yes | pending |
| 43-01-03 | 01 | 1 | INV-02 | functional | manual slot tab verification | N/A | pending |
| 43-01-04 | 01 | 1 | INV-03 | functional | manual drop discard test | N/A | pending |
| 43-01-05 | 01 | 1 | INV-04 | functional | manual ForgeView check | N/A | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements. Integration test file exists at tools/test/integration_test.gd and needs assertion updates, not new test infrastructure.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Drop discard when bench occupied | INV-03 | Requires live game loop with pack combat generating drops | Clear maps with occupied bench, verify console "discarding" message |
| Melt two-click confirmation | INV-04 | UI interaction timing (3s timer) | Click Melt, verify "Confirm Melt?", click again within 3s, verify bench clears |
| Slot tab display (name only, no counts) | INV-04 | Visual UI check | Verify tabs show "Weapon", "Helmet" etc. without "(N/10)" counts |
| Empty bench disabled state | INV-04 | Visual UI state | Verify empty slot tabs are greyed out and unclickable |
| Old v4 save wipe on load | INV-05 | Requires v4 save file | Place v4 save, load game, verify fresh start |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
