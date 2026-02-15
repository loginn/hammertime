---
phase: quick-fix
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - scenes/crafting_view.gd
autonomous: true
must_haves:
  truths:
    - "Clicking weapon type button when weapon slot is empty does NOT create a free Light Sword"
    - "All item type buttons behave consistently: selecting an empty slot shows 'No item selected' instead of generating a free item"
    - "Selecting a type that has an item in the crafting inventory still works correctly"
  artifacts:
    - path: "scenes/crafting_view.gd"
      provides: "Consistent item type selection behavior"
  key_links:
    - from: "_on_item_type_selected"
      to: "update_current_item"
      via: "guard clause treats all types equally"
      pattern: "crafting_inventory\\[item_type\\] == null"
---

<objective>
Fix bug where the weapon item type button creates a free Light Sword when the weapon inventory slot is empty, while other item type buttons correctly refuse selection when their slots are empty.

Purpose: Remove testing exception that allows free weapon generation, making all item type buttons behave consistently.
Output: Patched crafting_view.gd with consistent item type selection logic.
</objective>

<execution_context>
@/home/travelboi/.claude/get-shit-done/workflows/execute-plan.md
@/home/travelboi/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@scenes/crafting_view.gd
</context>

<tasks>

<task type="auto">
  <name>Task 1: Remove weapon exception and free item generation</name>
  <files>scenes/crafting_view.gd</files>
  <action>
Two changes in scenes/crafting_view.gd:

1. In `_on_item_type_selected()` (around line 340): Remove the `and item_type != "weapon"` exception from the guard clause. The line currently reads:
   ```
   if crafting_inventory[item_type] == null and item_type != "weapon":
   ```
   Change it to:
   ```
   if crafting_inventory[item_type] == null:
   ```
   Also remove the comment on line 339 that says "# Exception: weapons always work for testing (creates Light Swords)".

2. In `update_current_item()` (around lines 308-327): Replace the entire else branch that creates default items (LightSword.new(), BasicHelmet.new(), etc.) with simply setting `current_item = null`. The current code creates free items when inventory slots are empty, which should never happen now that the guard in `_on_item_type_selected` blocks selection of empty slots. Replace lines 308-327 with:
   ```
   else:
       current_item = null
       print("No ", selected_type, " in inventory")
   ```
   This is a safety fallback -- it should not be reachable in normal play, but if it is, it must not generate free items.
  </action>
  <verify>
Read the modified file and confirm:
- `_on_item_type_selected` guard clause no longer has `and item_type != "weapon"` exception
- `update_current_item` else branch sets `current_item = null` instead of creating default items
- No other code paths create free items when inventory slots are empty
  </verify>
  <done>
Weapon type button behaves identically to all other item type buttons: selecting an empty slot is rejected with a print message, and no free items are ever generated from type selection.
  </done>
</task>

</tasks>

<verification>
- Read crafting_view.gd and confirm the guard clause on line 340 treats all item types equally (no "weapon" exception)
- Read update_current_item and confirm no default item instantiation (no .new() calls for empty slots)
- Grep for "LightSword.new()" in crafting_view.gd -- should only appear in _ready() for the starting weapon, NOT in update_current_item
</verification>

<success_criteria>
- All item type buttons behave consistently when their inventory slot is empty (selection rejected)
- No free item generation from type button clicks
- Starting inventory setup in _ready() is unchanged (players still get initial items)
</success_criteria>

<output>
After completion, create `.planning/quick/1-fix-light-sword-item-type-button-regener/1-SUMMARY.md`
</output>
