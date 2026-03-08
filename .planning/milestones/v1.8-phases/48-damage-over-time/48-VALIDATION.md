---
phase: 48
slug: damage-over-time
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-08
---

# Phase 48 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Godot integration_test.gd (custom) |
| **Config file** | tools/test/integration_test.gd |
| **Quick run command** | `godot --headless --script tools/test/integration_test.gd -- --group=N` |
| **Full suite command** | `godot --headless --script tools/test/integration_test.gd` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `godot --headless --script tools/test/integration_test.gd -- --group=N`
- **After every plan wave:** Run `godot --headless --script tools/test/integration_test.gd`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 48-01-01 | 01 | 1 | DOT-01 | unit | `--group=30` (via 48-03-03) | ❌ W0 | ⬜ pending |
| 48-01-02 | 01 | 1 | DOT-02 | integration | `--group=31` (via 48-03-03) | ❌ W0 | ⬜ pending |
| 48-01-03 | 01 | 1 | DOT-02 | integration | `--group=31` (via 48-03-03) | ❌ W0 | ⬜ pending |
| 48-01-04 | 01 | 1 | DOT-02 | integration | `--group=33` (via 48-03-05) | ❌ W0 | ⬜ pending |
| 48-01-05 | 01 | 1 | DOT-03/04/05 | inline verify | per-task grep | N/A | ⬜ pending |
| 48-01-06 | 01 | 1 | DOT-03/04/05 | inline verify | per-task grep | N/A | ⬜ pending |
| 48-02-01 | 02 | 1 | DOT-07 | integration | `--group=32` (via 48-03-04) | ❌ W0 | ⬜ pending |
| 48-02-02 | 02 | 1 | DOT-07 | integration | `--group=32` (via 48-03-04) | ❌ W0 | ⬜ pending |
| 48-02-03 | 02 | 1 | DOT-05 | inline verify | per-task grep | N/A | ⬜ pending |
| 48-03-01 | 03 | 2 | DOT-06 | signal/manual | `--group=34` + manual | ❌ W0 | ⬜ pending |
| 48-03-02 | 03 | 2 | DOT-01 | inline verify | per-task grep | N/A | ⬜ pending |
| 48-03-03 | 03 | 2 | DOT-01/02 | integration | `--group=30,31` | ❌ W0 | ⬜ pending |
| 48-03-04 | 03 | 2 | DOT-07 | integration | `--group=32` | ❌ W0 | ⬜ pending |
| 48-03-05 | 03 | 2 | DOT-02/06 | integration | `--group=33,34` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tools/test/integration_test.gd` — Group 30: DoT stat type existence (DOT-01)
- [ ] `tools/test/integration_test.gd` — Group 31: DoT stat aggregation and proc logic (DOT-02/03/04/05)
- [ ] `tools/test/integration_test.gd` — Group 32: DoT defense interaction (DOT-07)
- [ ] `tools/test/integration_test.gd` — Group 33: DoT DPS calculation (DOT-02)
- [ ] `tools/test/integration_test.gd` — Group 34: GameEvents DoT signal verification (DOT-06)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| DoT accumulator label appears near HP bar | DOT-06 | Visual UI element | Play combat with bleed weapon, observe accumulator label |
| Accumulator increases with ticks | DOT-06 | Visual animation | Watch accumulator during multi-tick DoT |
| Accumulator fades on expiry | DOT-06 | Visual animation | Wait for DoT to expire, observe fade |
| Status text format "BLEED x3" | DOT-06 | Visual formatting | Apply multiple bleed stacks, check text |
| DoT text distinct from floating numbers | DOT-06 | Visual comparison | Compare DoT display vs direct hit floating text |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
