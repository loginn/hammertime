---
phase: 57
slug: stash-ui
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-28
---

# Phase 57 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | GDScript integration tests (tools/test/) |
| **Config file** | tools/test/integration_test.gd |
| **Quick run command** | `godot --headless --script tools/test/integration_test.gd` |
| **Full suite command** | `godot --headless --script tools/test/integration_test.gd` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `godot --headless --script tools/test/integration_test.gd`
- **After every plan wave:** Run `godot --headless --script tools/test/integration_test.gd`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 57-01-01 | 01 | 1 | STSH-02 | integration | `godot --headless --script tools/test/integration_test.gd` | ❌ W0 | ⬜ pending |
| 57-01-02 | 01 | 1 | STSH-03 | integration | `godot --headless --script tools/test/integration_test.gd` | ❌ W0 | ⬜ pending |
| 57-01-03 | 01 | 1 | STSH-05 | integration | `godot --headless --script tools/test/integration_test.gd` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tools/test/integration_test.gd` — stubs for STSH-02, STSH-03, STSH-05
- [ ] Stash display rendering assertions
- [ ] Tap-to-bench transfer assertions

*Existing infrastructure covers framework — test cases needed for phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Letter-icon squares render correctly in ForgeView | STSH-02 | Visual rendering requires human eye | Open ForgeView with stash items, verify letter squares display in row |
| Dim/greyed empty slots visible | STSH-02 | Visual appearance check | Open ForgeView with partially filled stash, verify empty slots are dim |
| Tooltip popup on hover/long-press | STSH-05 | Input interaction + visual | Hover over filled stash slot, verify popup shows name, rarity, affixes |
| Immediate update on item add/remove | STSH-03 | Real-time visual feedback | Tap a stash item, verify it moves to bench and slot updates instantly |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
