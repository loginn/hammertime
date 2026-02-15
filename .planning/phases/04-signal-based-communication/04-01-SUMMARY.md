# Phase 04 Plan 01: Signal-Based View Communication Summary

**One-liner:** Signal-based cross-view communication replacing brittle get_node() sibling lookups with parent-coordinated signal routing.

---

## Metadata

```yaml
phase: 04-signal-based-communication
plan: 01
subsystem: views
tags: [architecture, signals, coupling, refactoring]
completed: 2026-02-15
duration: 3min 11sec
```

## Dependency Graph

```yaml
requires:
  - phase: 03
    provides: unified-calculations
    reason: GameState.hero calculation methods used in signal callbacks

provides:
  - signal-coordination: Parent view coordinates child signals to sibling methods
  - typed-signals: All views declare typed signals for cross-view communication
  - zero-coupling: Child views have zero sibling references

affects:
  - main_view.gd: Now parent coordinator with @onready caching and signal connections
  - hero_view.gd: Emits equipment_changed instead of calling gameplay_view directly
  - crafting_view.gd: Emits item_finished instead of calling hero_view directly
  - gameplay_view.gd: Emits item_base_found and hammers_found instead of calling crafting_view directly
```

## Tech Stack

```yaml
added:
  - pattern: "call down, signal up" (Godot best practice)
  - pattern: "@onready caching" for node references
  - pattern: "parent coordinator" for sibling communication

patterns:
  - Child views emit typed signals upward
  - Parent main_view calls methods down on children
  - Parent connects child signals to sibling methods
  - No child knows about siblings
```

## Key Files

```yaml
created: []

modified:
  - path: scenes/main_view.gd
    purpose: Parent coordinator connecting child signals to sibling methods
    lines_changed: +24 -48
    key_changes:
      - Added @onready caching for 6 node references (3 views + 3 buttons)
      - Added 4 signal connections for child-to-sibling coordination
      - Removed defensive has_node() checks and debug prints
      - Replaced all $NodePath references with @onready vars

  - path: scenes/hero_view.gd
    purpose: Emits equipment_changed signal instead of calling gameplay_view
    lines_changed: +4 -16
    key_changes:
      - Added signal equipment_changed()
      - Removed notify_gameplay_of_equipment_change() method
      - Emit equipment_changed in equip_item() and unequip_item()
      - Emit GameEvents.equipment_changed for global tracking

  - path: scenes/crafting_view.gd
    purpose: Emits item_finished signal instead of calling hero_view
    lines_changed: +3 -9
    key_changes:
      - Added signal item_finished(item: Item)
      - Removed var hero_view sibling reference
      - Removed sibling lookup in _ready()
      - Emit item_finished in finish_item() and _ready()

  - path: scenes/gameplay_view.gd
    purpose: Emits item_base_found and hammers_found signals instead of calling crafting_view
    lines_changed: +6 -12
    key_changes:
      - Added signal item_base_found(item_base: Item)
      - Added signal hammers_found(implicit_count, prefix_count, suffix_count)
      - Removed var hero_view and var crafting_view sibling references
      - Removed sibling lookups in _ready()
      - Emit signals in clear_area() and give_hammer_rewards()
      - Emit GameEvents.area_cleared for global tracking
```

## Decisions Made

1. **Use @onready for all node references in main_view**
   - **Context:** Previous code used manual assignments in _ready()
   - **Decision:** Replace with @onready declarations
   - **Rationale:** Cleaner, more idiomatic Godot 4 code; eliminates null-check boilerplate
   - **Impact:** Reduced _ready() from 40+ lines to 12 lines

2. **Emit item_finished(null) during crafting_view initialization**
   - **Context:** Original code called hero_view.set_last_crafted_item(null) in _ready()
   - **Decision:** Replace with item_finished.emit(null)
   - **Rationale:** Signal fires before main_view connects it (no-op), but maintains consistency; hero_view already defaults to null anyway
   - **Impact:** No functional change, but eliminates special-case sibling reference

3. **Wire GameEvents signals alongside local signals**
   - **Context:** Phase 02 noted unused GameEvents signals
   - **Decision:** Emit GameEvents.equipment_changed and GameEvents.area_cleared at appropriate times
   - **Rationale:** Provides global event bus for future systems (achievements, analytics, etc.)
   - **Impact:** Eliminates "unused signal" warnings; provides extension point for future features

4. **Keep internal $NodePath references in child views**
   - **Context:** Plan scope could have converted ALL $NodePath references to @onready
   - **Decision:** Only convert cross-view references; leave internal $ClearingTimer, $ButtonControl, etc. for Plan 02
   - **Rationale:** Strict separation of concerns; Plan 01 = cross-view coupling, Plan 02 = internal references
   - **Impact:** Clear phase boundaries; Plan 02 has well-defined scope

## Outcomes

### What Was Built

**Signal-based view architecture** following Godot's "call down, signal up" pattern:

1. **Child views declare typed signals** for outgoing communication
2. **Parent main_view acts as coordinator** connecting child signals to sibling methods
3. **Zero sibling coupling** - no child view references another child
4. **GameEvents integration** for global event tracking

### Key Metrics

- **Files modified:** 4
- **Lines changed:** +37 -85 (net -48 lines)
- **Sibling get_node() calls removed:** 7
- **Signals added:** 4 (equipment_changed, item_finished, item_base_found, hammers_found)
- **Signal connections in main_view:** 4 (coordinating child-to-sibling flow)
- **@onready declarations added:** 6 (3 views + 3 buttons)

### Verification Results

All verification checks passed:

✅ **VIEW-01:** Zero sibling get_node() calls in any view file
✅ **VIEW-02:** main_view contains 4 signal connections (call down via connect)
✅ **VIEW-03:** Child views emit signals (signal up) with zero sibling knowledge
✅ **Signal flow correctness:**
  - crafting_view.item_finished → hero_view.set_last_crafted_item
  - hero_view.equipment_changed → gameplay_view.refresh_clearing_speed
  - gameplay_view.item_base_found → crafting_view.set_new_item_base
  - gameplay_view.hammers_found → crafting_view.add_hammers

### Structural Improvements

**Before (Phase 03):**
```
hero_view <--get_node()-- crafting_view
    |                           ^
    |                           |
    get_node()            get_node()
    |                           |
    v                           |
gameplay_view ---get_node()-----+
```
Brittle coupling: every view knows about siblings via path lookups.

**After (Phase 04-01):**
```
        main_view (coordinator)
       /    |    \
    connect connect connect
     /      |      \
hero_view crafting_view gameplay_view
    |          |          |
  signal     signal     signal
    up         up         up
```
Clean architecture: signals up, calls down, parent coordinates.

## Deviations from Plan

**None - plan executed exactly as written.**

No bugs found, no missing critical functionality, no blocking issues. All three tasks completed as specified with zero architectural decisions required.

## Follow-Up Work

### For Phase 04-02 (Internal Node References)

- Convert internal $NodePath references to @onready in all views
- Apply same @onready pattern to crafting_view's button/label references
- Convert gameplay_view's $ClearingTimer, $StartClearingButton, etc. to @onready
- Verify zero $ references remain except in @onready declarations

### Future Enhancements

- **Achievement system** can subscribe to GameEvents.area_cleared
- **Analytics/metrics** can track GameEvents.equipment_changed for player behavior
- **Tutorial system** can watch GameEvents.item_crafted to trigger tooltips
- **Save system** can serialize equipped items using GameEvents.equipment_changed log

## Self-Check

```bash
# Files created/modified exist
[ -f scenes/main_view.gd ] && echo "✓ main_view.gd modified"
[ -f scenes/hero_view.gd ] && echo "✓ hero_view.gd modified"
[ -f scenes/crafting_view.gd ] && echo "✓ crafting_view.gd modified"
[ -f scenes/gameplay_view.gd ] && echo "✓ gameplay_view.gd modified"

# Commits exist
git log --oneline | grep -q "3610c05" && echo "✓ Task 1 commit found"
git log --oneline | grep -q "ca52bbd" && echo "✓ Task 2 commit found"
git log --oneline | grep -q "45674a6" && echo "✓ Task 3 commit found"

# Signal connections verified
grep -q "item_finished.connect" scenes/main_view.gd && echo "✓ item_finished connection exists"
grep -q "equipment_changed.connect" scenes/main_view.gd && echo "✓ equipment_changed connection exists"
grep -q "item_base_found.connect" scenes/main_view.gd && echo "✓ item_base_found connection exists"
grep -q "hammers_found.connect" scenes/main_view.gd && echo "✓ hammers_found connection exists"

# Zero sibling coupling
! grep -r "get_node_or_null.*\.\." scenes/ && echo "✓ Zero sibling get_node() calls remain"
```

**Self-Check: PASSED** ✅

All files exist, all commits present, all signal connections verified, zero sibling coupling confirmed.

---

**Plan Status:** ✅ COMPLETE
**Next Plan:** 04-02 (Internal Node References with @onready)
**Phase Status:** 1 of 2 plans complete
