---
phase: 44
slug: item-bases-str-dex
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-06
---

# Phase 44 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Godot integration test (custom) |
| **Config file** | tools/test/integration_test.gd |
| **Quick run command** | `Run scene tools/test/integration_test.tscn` |
| **Full suite command** | `Run scene tools/test/integration_test.tscn` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run integration test scene
- **After every plan wave:** Run full integration test suite
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 44-01-01 | 01 | 1 | BASE-01 | unit | Group 10: Item Base Construction | ❌ W0 | ⬜ pending |
| 44-01-02 | 01 | 1 | BASE-02 | unit | Group 10: Item Base Construction | ❌ W0 | ⬜ pending |
| 44-01-03 | 01 | 1 | BASE-03 | unit | Group 12: Defense Archetype | ❌ W0 | ⬜ pending |
| 44-01-04 | 01 | 1 | BASE-05 | unit | Group 11: Serialization | ❌ W0 | ⬜ pending |
| 44-01-05 | 01 | 1 | BASE-06 | unit | Group 13: Valid Tags | ❌ W0 | ⬜ pending |
| 44-01-06 | 01 | 1 | BASE-07 | unit | Group 14: Drop Generation | ❌ W0 | ⬜ pending |
| 44-01-07 | 01 | 1 | BASE-08 | unit | Group 10: Tier Scaling | ❌ W0 | ⬜ pending |
| 44-01-08 | 01 | 1 | BASE-09 | unit | Group 13: Affix Gating | ❌ W0 | ⬜ pending |
| 44-01-09 | 01 | 1 | BASE-10 | unit | Group 15: Starter Weapon | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Test Groups 10-15 stubs in `tools/test/integration_test.gd`
- [ ] Helper functions for batch item construction validation

*Existing infrastructure covers framework — only new test groups needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual item name display | BASE-01 | UI rendering | Launch game, verify starter weapon shows "Rusty Broadsword" |
| Drop variety visible | BASE-07 | Random drop observation | Kill mobs, verify drops from multiple slots/archetypes |
| Defense stat display | BASE-03 | UI rendering | Equip STR/DEX/INT armor, verify defense stat shows correctly |
| Hammer affix gating | BASE-06 | Gameplay interaction | Use Runic Hammer on STR vs DEX armor, verify correct mod pools |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
