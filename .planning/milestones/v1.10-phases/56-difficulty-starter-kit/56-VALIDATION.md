---
phase: 56
slug: difficulty-starter-kit
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-28
---

# Phase 56 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Custom GDScript integration test (Godot scene) |
| **Config file** | `tools/test/integration_test.gd` |
| **Quick run command** | Run scene `tools/test/integration_test.gd` from Godot editor (F6) |
| **Full suite command** | Same — all groups run sequentially, output to Godot console |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run integration_test.gd, confirm all prior groups still pass
- **After every plan wave:** Full suite must be green (all groups pass)
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 56-01-01 | 01 | 1 | DIFF-01 | unit | F6 integration_test.gd group_42 | ❌ W0 | ⬜ pending |
| 56-01-02 | 01 | 1 | DIFF-03 | unit | F6 integration_test.gd group_43 | ❌ W0 | ⬜ pending |
| 56-01-03 | 01 | 1 | DIFF-03 | unit | F6 integration_test.gd group_44 | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tools/test/integration_test.gd` — add `_group_42_forest_difficulty_tuning()`: verify Forest biome monster base_hp and base_damage values match tuned targets
- [ ] `tools/test/integration_test.gd` — add `_group_43_starter_kit_fresh_game()`: verify `initialize_fresh_game()` produces 2 transmute + 2 augment, starter weapon in stash, starter armor in stash
- [ ] `tools/test/integration_test.gd` — add `_group_44_starter_kit_post_prestige()`: verify `_place_starter_kit(archetype)` places correct archetype-matched items for each of STR/DEX/INT

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Fresh P0 hero clears zone 1 Forest packs without dying | DIFF-01 | Requires live combat simulation in Godot | Start new game, observe hero survives zone 1 packs |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
