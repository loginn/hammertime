# Requirements: Hammertime

**Defined:** 2026-02-19
**Core Value:** The crafting loop must feel rewarding — finding items, using hammers to shape them, and equipping the result to push further into harder content.

## v1.6 Requirements

Requirements for tech debt cleanup milestone. Each maps to roadmap phases.

### Repository Hygiene

- [x] **REPO-01**: Temporary Godot editor files (.tmp) removed from git tracking -- Phase 31
- [x] **REPO-02**: .gitignore updated with `*.tmp` pattern to prevent future commits -- Phase 31

### Progression Rebalance

- [ ] **PROG-01**: Biome boundaries compressed to ~25 levels each (Forest 1-24, Dark Forest 25-49, Cursed Woods 50-74, Shadow Realm 75+)
- [ ] **PROG-02**: Difficulty growth rate increased to moderate scaling (~10% per level) so endgame feels significantly harder than start
- [ ] **PROG-03**: Currency area gates moved to match new biome boundaries (Forge at 25, Grand at 50, Claw/Tuning at 75)
- [ ] **PROG-04**: Currency unlock ramp duration scaled proportionally to new biome size (~12 levels instead of 50)
- [ ] **PROG-05**: Item drop count formula rescaled for compressed level range
- [ ] **PROG-06**: User can receive rare preview currency drops from next biome (~1 per 50 packs average in current biome)
- [ ] **PROG-07**: All items drop at Normal rarity (0 affixes) — crafting is the sole source of item mods

## Future Requirements

### Filtering

- **FILT-01**: User can set minimum rarity filter for item drops
- **FILT-02**: User can filter by item type
- **FILT-03**: User can toggle auto-melt for filtered items

## Out of Scope

| Feature | Reason |
|---------|--------|
| CombatEngine async refactor | Working code with correct guards — not causing bugs |
| Full progression rebalance beyond biome compression | Focus on biome boundaries and scaling; fine-tuning can happen in future milestones |
| New biomes | 4 biomes sufficient for compressed range |
| Unique item drops | Future feature — not related to this milestone |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| REPO-01 | Phase 31 | Complete |
| REPO-02 | Phase 31 | Complete |
| PROG-01 | Phase 32 | Pending |
| PROG-02 | Phase 32 | Pending |
| PROG-03 | Phase 33 | Pending |
| PROG-04 | Phase 33 | Pending |
| PROG-05 | Phase 33 | Pending |
| PROG-07 | Phase 33 | Pending |
| PROG-06 | Phase 34 | Pending |

**Coverage:**
- v1.6 requirements: 9 total
- Mapped to phases: 9
- Unmapped: 0 ✓

---
*Requirements defined: 2026-02-19*
*Last updated: 2026-02-19 — REPO-01, REPO-02 completed in Phase 31*
