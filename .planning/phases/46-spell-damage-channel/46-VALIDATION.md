---
phase: 46
slug: spell-damage-channel
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-03-06
---

# Phase 46 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | GDScript integration tests (tools/test/integration_test.gd) |
| **Config file** | tools/test/integration_test.gd |
| **Quick run command** | `grep -c "PASS\|FAIL" <test_output>` (manual Godot run) |
| **Full suite command** | Run scene in Godot editor |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Verify affected calculation methods via test functions
- **After every plan wave:** Run full integration test suite in Godot
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 46-01-01 | 01 | 1 | SPELL-03 | unit | integration_test spell fields | ❌ W0 | ⬜ pending |
| 46-01-02 | 01 | 1 | SPELL-04 | unit | integration_test spell calc | ❌ W0 | ⬜ pending |
| 46-02-01 | 02 | 1 | SPELL-05 | unit | integration_test hero spell | ❌ W0 | ⬜ pending |
| 46-02-02 | 02 | 2 | SPELL-07 | manual | visual check in Godot | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Add test group for spell damage StatCalculator methods
- [ ] Add test group for Hero spell stat tracking
- [ ] Add test group for weapon/ring spell field serialization

*Existing integration_test.gd infrastructure covers test framework needs.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Attack DPS / Spell DPS display | SPELL-07 | UI label text requires visual check | Equip spell weapon, verify "Spell DPS" line appears; equip attack weapon, verify only "Attack DPS" shows |
| Weapon tooltip spell damage | SPELL-03 | Tooltip rendering requires visual check | Hover spell weapon, verify "Spell Damage: X to Y" and "Cast Speed" shown |
| Stat comparison channels | SPELL-07 | Comparison text requires visual check | Hover equip on spell weapon, verify both Attack DPS and Spell DPS deltas shown |

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
