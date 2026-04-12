# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.10 — Early Game Rebalance

**Shipped:** 2026-04-12
**Phases:** 4 | **Plans:** 10

### What Was Built
- 3-slot stash per equipment type (15 total) with auto-stash on drop, silent overflow, and stash_updated signal
- Single universal crafting bench replacing per-slot switching, with ForgeView migration
- 15-slot StashDisplay grid with abbreviation labels, dim/filled states, tooltip, tap-to-bench transfer
- Currency keys renamed to PoE conventions (transmute/augment/alteration/regal/chaos/exalt)
- Archetype-matched starter items in stash for fresh games and post-prestige
- Forest difficulty tuned (~50% reduction) for zone 1 survivability
- Alteration Hammer (reroll Magic mods) and Regal Hammer (Magic → Rare upgrade)
- Save format v9 with stash/bench serialization and v8 compat shim removal

### What Worked
- 4-phase dependency chain (data model → difficulty/starter → UI → hammers/save) kept phases clean
- D-03 (silent overflow) and D-08 (null-gap removal) design decisions were made early in CONTEXT.md and never revisited
- Splitting data model (Phase 55) from UI (Phase 57) allowed the stash to be usable before UI existed
- Integration tests (groups 40-50) caught real issues and provided confidence for the save format migration

### What Was Inefficient
- Phase 57-03 gap closure was partially wasted — UAT revealed the stash layout was hidden behind the hero view, requiring a full UI revamp that couldn't be fixed incrementally
- 2 UAT items for Phase 56 remained permanently blocked (prestige path unreachable due to difficulty)
- SUMMARY frontmatter for STSH-03 and CRFT-03 was not populated, causing false "partial" in milestone audit
- Phase 56 ended up with 3 plans (one extra for currency hammer renames) — scope expanded mid-milestone

### Patterns Established
- Null-gap removal (D-08): stash slots use items[i] = null instead of remove_at() for stable UI indexing
- PoE currency naming convention: all runtime keys use transmute/augment/alteration/regal/chaos/exalt
- Starter kit pattern: _place_starter_kit(archetype) as reusable entry point for fresh game and prestige

### Key Lessons
1. UI phases should be UAT-tested early — the stash layout overlap was only caught at the end, making 57-03 gap closure work partially wasted
2. SUMMARY frontmatter must always include requirements-completed — the audit's 3-source cross-reference depends on it
3. Blocked UAT items (prestige path unreachable) need a dedicated unblocking plan, not just "try again later"

### Cost Observations
- Model mix: sonnet for executor/integration-checker, opus for orchestration/planning
- 4-day timeline for 4 phases with 10 plans
- Notable: Phase 58 (save migration) shipped cleanly in 2 plans despite touching the most files

---

## Milestone: v1.8 — Content Pass — Items & Mods

**Shipped:** 2026-03-08
**Phases:** 8 | **Plans:** 18

### What Was Built
- 21 item base types across 5 slots with STR/DEX/INT archetype identity and valid_tags constraining affix pools
- Single crafting bench per slot replacing 10-item array inventory model
- Spell damage channel with StatCalculator, Hero tracking, dual DPS display, and CombatEngine spell timer
- 14 new affixes (spell damage flat/%, cast speed, bleed/poison/burn chance and damage)
- DoT system with tick processing, stacking rules, resistance-only defense path, and combat UI feedback
- Save format v7 with full 21-type serialization registry and integration test suite (35 groups)

### What Worked
- 8-phase dependency chain (foundation → inventory → bases → affixes → spell channel → spell combat → DoT → integration) kept each phase focused and testable
- CONTEXT.md sessions before planning eliminated scope ambiguity — LOOT-03/LOOT-04 dropped early by user decision, zero rework
- Splitting spell damage wiring (phase 46, no CombatEngine) from spell combat (phase 47, CombatEngine) isolated the highest-risk change
- Base class proliferation (21 types) completed cleanly by doing serialization registry in a dedicated plan
- DoT defense interaction designed with PoE conventions (bleed bypasses resistance, burn uses fire resistance) — familiar mental model

### What Was Inefficient
- Coverage table in ROADMAP.md became garbled with duplicate columns during phase completion updates — needs better update tooling
- Some summary files lacked one_liner field, making automated accomplishment extraction fail — format inconsistency across phases
- Phase 44 was the largest (3 plans, 21 item classes) — could have been split further to reduce per-plan complexity

### Patterns Established
- valid_tags on item bases as the archetype identity mechanism — no class system needed
- Spell timer as independent third CombatEngine timer — clean extension point for future damage channels
- DoT resistance-only defense path in DefenseCalculator — separate from full 4-stage pipeline
- Slot-first-then-archetype drop distribution — prevents weapon flooding

### Key Lessons
1. Dropping requirements early (LOOT-03/LOOT-04) via CONTEXT.md discussion is better than implementing then removing — saves an entire plan's worth of work
2. The "foundation constants first, zero functional changes" pattern (Phase 42) eliminates merge conflicts in later phases — all consumers can reference new constants immediately
3. Isolating CombatEngine changes (spell timer, DoT ticks) in single-purpose phases prevents cascading regressions

### Cost Observations
- Model mix: predominantly sonnet for executor agents, opus for orchestration
- Notable: 8 phases with 18 plans shipped in 3 days — fastest per-plan throughput of any milestone

---

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
| v1.8 | 8 | 18 | Largest milestone — 3 new systems (archetypes, spell channel, DoT) in 3 days |
| v1.9 | 5 | 5 | Hero archetype system with passive bonuses and selection UI |
| v1.10 | 4 | 10 | Stash system, early game rebalance, Alteration/Regal hammers |

### Top Lessons (Verified Across Milestones)

1. Phase dependency chains (each phase builds on the last) keep scope tight and enable incremental verification
2. User decisions captured early (CONTEXT.md) prevent scope drift during execution
3. Integration tests at milestone end catch cross-phase wiring issues that per-phase verification misses
