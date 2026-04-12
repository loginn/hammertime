---
phase: 55
slug: stash-data-model
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-28
---

# Phase 55 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Godot built-in test scene (GDScript) |
| **Config file** | `tools/test/integration_test.gd` |
| **Quick run command** | Open `tools/test/integration_test.gd` scene in Godot editor, press F6 |
| **Full suite command** | Same — all groups run in `_ready()` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run F6 on integration_test.gd, verify new group passes, existing groups unchanged
- **After every plan wave:** Full suite green (all groups pass)
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 55-01-01 | 01 | 1 | STSH-01 | unit | F6 `integration_test.gd` (group_40) | ❌ W0 | ⬜ pending |
| 55-01-02 | 01 | 1 | STSH-01 | unit | F6 `integration_test.gd` (group_40) | ❌ W0 | ⬜ pending |
| 55-01-03 | 01 | 1 | STSH-01 | unit | F6 `integration_test.gd` (group_40) | ❌ W0 | ⬜ pending |
| 55-01-04 | 01 | 1 | STSH-01 | unit | F6 `integration_test.gd` (group_40) | ❌ W0 | ⬜ pending |
| 55-02-01 | 02 | 1 | STSH-04 | unit | F6 `integration_test.gd` (group_41) | ❌ W0 | ⬜ pending |
| 55-02-02 | 02 | 1 | STSH-04 | unit | F6 `integration_test.gd` (group_41) | ❌ W0 | ⬜ pending |
| 55-02-03 | 02 | 1 | STSH-04 | unit | F6 `integration_test.gd` (group_41) | ❌ W0 | ⬜ pending |
| 55-02-04 | 02 | 1 | STSH-04 | unit | F6 `integration_test.gd` (group_41) | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tools/test/integration_test.gd` — add `_group_40_stash_data_model()` covering STSH-01 checks (stash dict exists, 5 keys, empty arrays, crafting_bench null after fresh/wipe)
- [ ] `tools/test/integration_test.gd` — add `_group_41_stash_drop_routing()` covering STSH-04 checks (add_item_to_stash appends, returns true/false, overflow discard, no corruption)
- [ ] Call both groups from `_ready()` after existing groups

*Existing infrastructure covers framework needs — Godot editor + existing test file. No new infrastructure needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Items visually appear in stash after combat drop | STSH-04 | UI display is Phase 57 scope | Run combat, check `GameState.stash` via debugger or print statement |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
