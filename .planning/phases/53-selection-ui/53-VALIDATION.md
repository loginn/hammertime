---
phase: 53
slug: selection-ui
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-27
---

# Phase 53 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Godot in-engine integration test (GDScript scene) |
| **Config file** | `tools/test/integration_test.gd` |
| **Quick run command** | Run `tools/test/integration_test.gd` scene from Godot editor (F6) |
| **Full suite command** | Same — all groups run in sequence via `_ready()` |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run integration_test.gd (F6), verify Group 39 results and no regressions in Groups 36-38
- **After every plan wave:** Full suite green (all 39 groups pass)
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 2 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 53-01-01 | 01 | 1 | SEL-01 | unit | Group 39 in integration_test.gd | ❌ W0 | ⬜ pending |
| 53-01-02 | 01 | 1 | SEL-01 | unit | Group 39 in integration_test.gd | ❌ W0 | ⬜ pending |
| 53-01-03 | 01 | 1 | SEL-02 | unit | Group 39 in integration_test.gd | ❌ W0 | ⬜ pending |
| 53-01-04 | 01 | 1 | SEL-03 | unit | Group 39 in integration_test.gd | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Group 39 stubs in `tools/test/integration_test.gd` — SEL-01, SEL-02, SEL-03 test cases
- [ ] `BONUS_LABELS` dictionary on `models/hero_archetype.gd` — prerequisite for card display

*Existing test infrastructure (Groups 1-38) covers all prior phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Overlay visually blocks all input | SEL-03 | Runtime visual property (mouse_filter STOP on CanvasLayer) | Prestige to P1, verify overlay covers full screen, click behind overlay fails |
| Cards display correct colors/layout | SEL-01 | Visual rendering | Prestige to P1, verify 3 cards with STR red / DEX green / INT blue borders |
| Overlay fade-out on selection | SEL-03 | Animation timing | Pick a hero, verify overlay fades out over ~0.3s |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 2s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
