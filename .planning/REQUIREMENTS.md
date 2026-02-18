# Requirements: Hammertime v1.4

**Defined:** 2026-02-18
**Core Value:** The crafting loop must feel rewarding — finding items, using hammers to shape them, and equipping the result to push further into harder content.

## v1.4 Requirements

Requirements for the Damage Ranges milestone. Each maps to roadmap phases.

### Damage Ranges

- [x] **DMG-01**: Weapon base damage expressed as min-max range per weapon type
- [x] **DMG-02**: Flat damage affixes store add_min and add_max values rolled from element-specific tier ranges at item creation
- [x] **DMG-03**: Element-specific variance ratios define spread between min and max (Physical tight, Cold moderate, Fire wide, Lightning extreme)
- [x] **DMG-04**: Monster pack damage expressed as min-max range with variance based on pack element type

### Combat

- [ ] **CMB-01**: Hero attacks roll each damage element independently (physical base + each elemental flat affix), apply element-specific percentage modifiers per element, then sum for total hit
- [ ] **CMB-02**: Monster pack attacks roll damage per-hit from pack min-max range before defense pipeline

### Stat Calculation

- [x] **STAT-01**: Hero tracks per-element min/max damage totals (physical, fire, cold, lightning) for independent rolling

### Display

- [ ] **DISP-01**: Weapon tooltip shows "X to Y" damage range instead of single number
- [ ] **DISP-02**: Flat damage affixes display "Adds X to Y [Element] Damage" format
- [ ] **DISP-03**: DPS stat computed using average of per-element damage ranges with element modifiers applied
- [ ] **DISP-04**: Current combat pack shows its name and damage element type in the gameplay view

## Future Requirements

Deferred to future release. Tracked but not in current roadmap.

### Display Enhancements

- **DISP-05**: Element variance hint in tooltip ("High variance" / "Consistent" label)
- **DISP-06**: Per-element DPS breakdown in Hero View (Physical/Fire/Cold/Lightning separately)
- **DISP-07**: Min/Max DPS shown alongside average DPS on hero stats panel

### Advanced Mechanics

- **MECH-01**: Lucky/Unlucky damage rolls (roll twice, take better/worse)
- **MECH-02**: Damage range visualization (histogram/bar showing spread)

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Save migration v1→v2 | User chose fresh saves only; no backward compatibility needed |
| Store single rolled value on affix | Anti-feature: hides variance identity, misleads players |
| DPS tooltip using maximum only | Anti-feature: misleading, breaks gear comparison math |
| Float damage ranges on affixes | Existing affixes use int throughout; float only at DPS calculation step |
| Separate weapon/affix range tooltips | Tooltip complexity players don't need in an idle game |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| DMG-01 | Phase 23 | Complete |
| DMG-02 | Phase 23 | Complete |
| DMG-03 | Phase 23 | Complete |
| DMG-04 | Phase 23 | Complete |
| STAT-01 | Phase 24 | Complete |
| CMB-01 | Phase 25 | Pending |
| CMB-02 | Phase 25 | Pending |
| DISP-01 | Phase 26 | Pending |
| DISP-02 | Phase 26 | Pending |
| DISP-03 | Phase 26 | Pending |
| DISP-04 | Phase 26 | Pending |

**Coverage:**
- v1.4 requirements: 11 total
- Mapped to phases: 11
- Unmapped: 0 ✓

---
*Requirements defined: 2026-02-18*
*Last updated: 2026-02-18 — added DISP-04 (pack info display)*
