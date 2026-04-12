---
phase: 3
slug: integration
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-12
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Custom GDScript harness (self-contained in `tools/test/integration_test.gd`) |
| **Config file** | none |
| **Quick run command** | `grep` checks (see Per-Task map) — CLI not available for the harness itself |
| **Full suite command** | Open `tools/test/integration_test.tscn` in the Godot editor, press F6 |
| **Estimated runtime** | <5s structural grep / ~10-20s manual F6 |

---

## Sampling Rate

- **After every task commit:** Run the task's structural grep command(s) from the Per-Task map below
- **After every plan wave:** Re-run all grep checks for the wave's tasks
- **Before `/gsd:verify-work`:** User runs the full harness (F6) once; reports pass/fail count
- **Max feedback latency:** <5 seconds for grep checks

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | INT-01 | structural grep | `grep -n '"alchemy": 15' models/loot/loot_table.gd` | ✅ (after edit) | ⬜ pending |
| 03-01-01 | 01 | 1 | INT-01 | structural grep | `grep -n '"divine": 65' models/loot/loot_table.gd` | ✅ (after edit) | ⬜ pending |
| 03-01-01 | 01 | 1 | INT-01 | structural grep | `grep -n '"annulment": 30' models/loot/loot_table.gd` | ✅ (after edit) | ⬜ pending |
| 03-01-01 | 01 | 1 | INT-01 | structural grep | `grep -n '"augment": 5' models/loot/loot_table.gd` | ✅ (after edit) | ⬜ pending |
| 03-01-02 | 01 | 1 | INT-01 | structural grep | `grep -nE '"(alchemy\|divine\|annulment)":[[:space:]]*\{"chance"' models/loot/loot_table.gd` | ✅ (after edit) | ⬜ pending |
| 03-02-01 | 02 | 1 | INT-02 | structural grep | `grep -n 'const SAVE_VERSION = 10' autoloads/save_manager.gd` | ✅ (after edit) | ⬜ pending |
| 03-03-01 | 03 | 2 | INT-02 | structural grep | `grep -n '_group_50_save_v10_round_trip' tools/test/integration_test.gd` | ❌ W0 | ⬜ pending |
| 03-03-01 | 03 | 2 | INT-02 | structural grep | `grep -n 'save_data\["version"\] == 10' tools/test/integration_test.gd` | ❌ W0 | ⬜ pending |
| 03-03-02 | 03 | 2 | INT-03 | structural grep | `grep -nE '_group_5[1-7]_' tools/test/integration_test.gd` (must show ≥7 matches) | ❌ W0 | ⬜ pending |
| 03-03-02 | 03 | 2 | INT-03 | structural grep | `grep -cE '"Group 5[1-7]:.*PASSED"' tools/test/integration_test.gd` (must return 7) | ❌ W0 | ⬜ pending |
| 03-03-02 | 03 | 2 | INT-03 | structural grep | no `assert(` calls in new group bodies — `grep -nE 'func _group_5[1-7]' tools/test/integration_test.gd` then inspect | ❌ W0 | ⬜ pending |
| 03-GATE | — | — | INT-01/02/03 | manual F6 | Open `tools/test/integration_test.tscn`, press F6, report pass count | ✅ scene exists | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tools/test/integration_test.gd` — 7 new group functions `_group_51_transmute_hammer` through `_group_57_annulment_hammer` (INT-03)
- [ ] `tools/test/integration_test.gd` — Group 50 renamed to `_group_50_save_v10_round_trip` with `== 10` assertion + alchemy/divine/annulment round-trip assertions (INT-02)
- [ ] No framework install needed — harness already self-contained

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Full integration test suite pass | INT-01/02/03 | Harness has no CLI runner (`godot --headless` not configured — deferred per CONTEXT §Deferred) | 1. Open Godot editor. 2. Open `tools/test/integration_test.tscn`. 3. Press F6. 4. Read console output; confirm no `FAILED` lines and all new `Group 5[1-7]: ... — PASSED` markers appear. 5. Report pass/fail count back to verifier. |
| Drop table playtest (sanity) | INT-01 | Drop tuning is subjective; tests only verify dict structure, not roll outcomes | (Optional, not blocking) Run a few packs in Normal at level ≥5 — Augment should drop; at level ≥15 — Alchemy should begin; at level ≥30 — Annulment should begin; at level ≥65 — Divine should begin. |

---

## Validation Sign-Off

- [ ] All tasks have structural grep verify or Wave 0 dependencies listed
- [ ] Sampling continuity: every task in 03-01/03-02/03-03 has at least one grep check
- [ ] Wave 0 covers all MISSING references (Groups 51-57 + renamed Group 50)
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s for structural checks
- [ ] `nyquist_compliant: true` set in frontmatter (after planner fills task IDs)

**Approval:** pending
