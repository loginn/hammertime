# Requirements: Hammertime v1.10 Early Game Rebalance

**Defined:** 2026-03-28
**Core Value:** The crafting loop must feel rewarding — finding items, using hammers to shape them, and equipping the result to push further into harder content.

## v1.10 Requirements

### Difficulty

- [x] **DIFF-01**: Fresh P0 hero survives Forest packs consistently with starter gear
- [x] **DIFF-03**: Fresh hero starts with starter weapon + armor in stash, plus 2 Transmute and 2 Augment hammers

### Stash

- [x] **STSH-01**: Player has 3 stash slots per equipment type to hold unworked bases
- [x] **STSH-02**: Stash displays as letter-icon squares (W for wand, S for sword, etc.) in ForgeView
- [x] **STSH-03**: Player can tap a stash item to move it onto the crafting bench (item cannot be returned to stash)
- [x] **STSH-04**: Dropped items auto-stash; overflow discarded with feedback
- [x] **STSH-05**: Player can hover/long-press a stash item to see full item details (name, rarity, affixes)

### Crafting

- [x] **CRFT-01**: Alteration Hammer rerolls all mods at current rarity (Magic only; rejected on Normal/Rare)
- [x] **CRFT-02**: Regal Hammer upgrades Magic → Rare by adding a single mod (3-mod Rare)
- [ ] **CRFT-03**: Save format v9 persists new hammer currencies and 3-slot stash

## Future Requirements

- Large number formatting with suffix notation (K/M/B)
- Item drop filter for unwanted loot
- WIP item save slot (park mid-craft item)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Chaos-style full reroll | Deliberate design: no full rerolls, craft carefully |
| Multi-bench crafting | Stash is a holding buffer, not multiple active benches |
| Per-biome drop rate scaling | Current 18% flat rate is fine; more drops come from easier packs |
| Endgame difficulty changes | This milestone focuses on early game only |
| Affix tier rebalancing | 32 tiers stay as-is; future meta-progression depends on them |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| STSH-01 | Phase 55 | Complete |
| STSH-04 | Phase 55 | Complete |
| DIFF-01 | Phase 56 | Complete |
| DIFF-03 | Phase 56 | Complete |
| STSH-02 | Phase 57 | Complete |
| STSH-03 | Phase 57 | Complete |
| STSH-05 | Phase 57 | Complete |
| CRFT-01 | Phase 58 | Complete |
| CRFT-02 | Phase 58 | Complete |
| CRFT-03 | Phase 58 | Pending |

**Coverage:**
- v1.10 requirements: 10 total
- Mapped to phases: 10
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-28*
*Last updated: 2026-03-28 — traceability updated after roadmap creation*
