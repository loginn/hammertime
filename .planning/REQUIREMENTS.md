# Requirements: Hammertime

**Defined:** 2026-02-18
**Core Value:** The crafting loop must feel rewarding — finding items, using hammers to shape them, and equipping the result to push further into harder content.

## v1.5 Requirements

Requirements for Inventory Rework milestone. Each maps to roadmap phases.

### Inventory Storage

- [ ] **INV-01**: Items drop into per-slot inventory arrays (weapon, helmet, armor, boots, ring)
- [ ] **INV-02**: Each slot holds up to 10 items; drops to a full slot are silently discarded
- [ ] **INV-03**: Melt destroys the bench item and removes it from slot inventory

### Crafting Bench

- [ ] **BENCH-01**: Clicking a slot button loads the highest-tier item from that slot onto the crafting bench
- [ ] **BENCH-02**: Crafting bench is a view into inventory — item remains in the array while being crafted

### Equip Flow

- [ ] **EQUIP-01**: Equipping moves the bench item from inventory to the hero's equipment slot
- [ ] **EQUIP-02**: Previously equipped item is deleted (not returned to inventory)

### Save/Load

- [ ] **SAVE-01**: Save/load supports per-slot inventory arrays in the save format

### Display

- [ ] **DISP-01**: Each slot shows an x/10 counter in the crafting view indicating fill level

## Future Requirements

Deferred to future release. Tracked but not in current roadmap.

### Loot Filtering

- **FILT-01**: Player can define which items to auto-discard by type
- **FILT-02**: Player can define which items to auto-discard by rarity
- **FILT-03**: Loot filter is persisted in save data

### Inventory Browsing

- **BROWSE-01**: Player can cycle through all items in a slot (not just highest tier)
- **BROWSE-02**: Player can select a non-best item for crafting

### Inventory Polish

- **POLISH-01**: Visual urgency indicator when slot reaches 10/10
- **POLISH-02**: Non-blocking notification when drops are discarded due to full slot

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Return old equipped item to inventory on equip | Breaks inventory cap bounds and contradicts idle genre; equip is a commitment |
| Auto-equip best item when slot fills | Removes the craft decision; keep explicit equip button |
| Per-item drop notification toast | Spam for idle game; x/10 counter is sufficient feedback |
| v1→v2 save migration | No external players; fresh saves only |
| Item sorting within slot | Not needed when bench always picks highest tier |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| INV-01 | — | Pending |
| INV-02 | — | Pending |
| INV-03 | — | Pending |
| BENCH-01 | — | Pending |
| BENCH-02 | — | Pending |
| EQUIP-01 | — | Pending |
| EQUIP-02 | — | Pending |
| SAVE-01 | — | Pending |
| DISP-01 | — | Pending |

**Coverage:**
- v1.5 requirements: 9 total
- Mapped to phases: 0
- Unmapped: 9 ⚠️

---
*Requirements defined: 2026-02-18*
*Last updated: 2026-02-18 after initial definition*
