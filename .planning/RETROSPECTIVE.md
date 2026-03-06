# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.7 — Meta-Progression

**Shipped:** 2026-03-06
**Phases:** 7 | **Plans:** 9

### What Was Built
- Full prestige system with 7 levels, currency-cost gating, and run-state wipe preserving meta-progression
- Item tier system (1-8) with Gaussian area-weighted drops and affix tier floor constraints
- Affix tier expansion from 8 to 32 tiers across all 27 active affixes
- 5 tag-targeted hammers with prestige-gated visibility and guaranteed tag matching
- Prestige UI with unlock table, two-click confirmation, fade transition, and dynamic tab reveal
- 50-test integration verification suite

### What Worked
- Layered phase dependency chain (35→36→37→38→39→40→41) kept each phase focused and testable
- CONTEXT.md discuss-phase sessions eliminated ambiguity before planning — zero scope changes during execution
- TagHammer as a single parameterized class avoided 5x code duplication
- Manual prestige simulation in tests (_simulate_prestige) cleanly avoided auto-save signal side effects
- Integration test scene caught real verification gaps that static code review couldn't

### What Was Inefficient
- 15-day timeline for 7 phases with a 9-day gap between phases 39 and 40 — session continuity was disrupted
- VALIDATION.md only introduced at phase 41 — phases 35-40 lack validation strategies retroactively
- Phase 41 ROADMAP success criteria mentioned v2 fixture tests that CONTEXT.md correctly excluded — criteria drift

### Patterns Established
- Affix tier floor applied at construction time (from_affix), not stored on item — keeps reroll behavior clean
- Tag currency as separate dictionary (tag_currency_counts) rather than merged into currency_counts
- _wipe_run_state() as separate method from initialize_fresh_game() — prestige never calls the latter
- Test scene pattern: tools/test/ directory with structured [PASS]/[FAIL] output

### Key Lessons
1. Static code verification catches structural issues but runtime tests are essential for integration — the 50/50 test pass confirmed what 7 phase verifications couldn't guarantee
2. Signal side effects (auto-save on prestige_completed) are a real testing hazard — always consider signal chains when writing test harnesses
3. Delete-on-old-version migration policy dramatically simplifies save code — worth the tradeoff for pre-production games

### Cost Observations
- Model mix: predominantly sonnet for research/verification agents, opus for planning/execution
- Notable: Phase 41 (verification-only) shipped in a single session including research, planning, execution, and audit

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v0.1 | 4 | 8 | Initial GSD adoption |
| v1.0 | 4 | 7 | Template method pattern established |
| v1.1 | 4 | 7 | Gap closure phases introduced |
| v1.2 | 5 | 11 | Combat system complexity peak |
| v1.3 | 5 | 11 | Save/load + UI polish |
| v1.4 | 4 | 7 | Damage range migration |
| v1.5 | 4 | 4 | Inventory rework |
| v1.6 | 4 | 5 | Tech debt cleanup |
| v1.7 | 7 | 9 | CONTEXT.md discussions, integration testing, Nyquist validation introduced |

### Top Lessons (Verified Across Milestones)

1. Phase dependency chains (each phase builds on the last) keep scope tight and enable incremental verification
2. User decisions captured early (CONTEXT.md) prevent scope drift during execution
3. Integration tests at milestone end catch cross-phase wiring issues that per-phase verification misses
