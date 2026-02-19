---
status: diagnosed
phase: v1.5-inventory-rework (phases 27-30)
source: [27-01-SUMMARY.md, 28-01-SUMMARY.md, 29-01-SUMMARY.md, 30-01-SUMMARY.md]
started: 2026-02-19T00:00:00Z
updated: 2026-02-19T00:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. New Game Starter Weapon
expected: Start a fresh new game. The weapon slot has 1 starter weapon. Bench displays it. Button shows "Weapon (1/10)".
result: pass

### 2. Item Drops Accumulate in Slot
expected: Kill packs until items drop. Dropped items accumulate in the matching slot — the counter increments (e.g., "Weapon (2/10)"). Items are NOT replaced, they stack up.
result: pass

### 3. Slot Counter Updates on Drop
expected: After each item drop, the affected slot button counter updates immediately without needing to click anything or reload.
result: pass

### 4. Full Slot Overflow Discard
expected: Fill a slot to 10 items (keep killing until counter shows "X (10/10)"). Additional drops of that type are silently discarded — counter stays at 10, no error message.
result: pass
note: Code-verified at forge_view.gd:455 (size >= 10 guard)

### 5. Best Item Selected for Bench
expected: Click a slot button that has multiple items. The crafting bench loads the best item (highest DPS for weapon/ring, highest tier for armor/helmet/boots) — not just the first item found.
result: issue
reported: "Items should be selected based on tier in all situations. Not based on calculations"
severity: major

### 6. Melt Removes and Auto-Selects Next
expected: With multiple items in a slot, melt the bench item. It is removed from the slot (counter decreases by 1). The next-best item auto-loads onto the bench.
result: pass

### 7. Equip From Bench
expected: Equip the bench item (two-click confirmation). Item moves to hero equipment slot. The previously equipped item is deleted (not returned to inventory). Counter decreases by 1 and next-best item loads.
result: pass
note: "User feedback — bench should be empty after equip, not auto-select next item"

### 8. Empty Slot Button Disabled
expected: After removing all items from a slot (via melt/equip), the slot button shows "SlotName (0/10)" and is disabled (grayed out, not clickable).
result: pass

### 9. Crafting Persists in Array
expected: With an item on the bench, apply a hammer to it. The crafted item stays in the slot array — it is not duplicated or lost. Switching away and back to the slot still shows the crafted item.
result: pass

### 10. Save/Load Preserves Full Inventory
expected: With items in multiple slots, save the game (auto-save or manual). Reload the page/game. All items in all slots are preserved with correct counts. Crafted affixes are intact.
result: pass

### 11. Currency-Only Kill No Counter Change
expected: Kill a pack that drops only currency (no item). Slot counters do not change — no phantom increment or decrement.
result: pass

## Summary

total: 11
passed: 10
issues: 1
pending: 0
skipped: 0

## Gaps

- truth: "Best item selection should use tier comparison for all slot types"
  status: failed
  reason: "User reported: Items should be selected based on tier in all situations. Not based on calculations"
  severity: major
  test: 5
  root_cause: "get_best_item() at forge_view.gd:501 delegates to is_item_better() which uses DPS for Weapon/Ring. Should use tier for all types."
  artifacts:
    - path: "scenes/forge_view.gd"
      issue: "is_item_better() uses dps comparison for Weapon/Ring at line ~467-470; get_best_item() inherits this via delegation"
  missing:
    - "Change get_best_item() or is_item_better() to use new_item.tier > existing_item.tier for ALL item types"

- truth: "Bench should be empty after equipping, not auto-select next item"
  status: failed
  reason: "User reported: pass, although we should not select an item in that case"
  severity: minor
  test: 7
  root_cause: "_on_equip_pressed() at forge_view.gd:422 calls get_best_item(slot_name) after removal. Should set current_item = null instead."
  artifacts:
    - path: "scenes/forge_view.gd"
      issue: "Line 422: current_item = get_best_item(slot_name) should be current_item = null"
  missing:
    - "Replace get_best_item() call with null assignment after equip, then call update_inventory_display()"
