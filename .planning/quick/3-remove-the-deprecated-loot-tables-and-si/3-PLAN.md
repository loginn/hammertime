---
phase: quick-3
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - models/loot/loot_table.gd
  - tools/drop_simulator.gd
  - tools/drop_simulator.gd.uid
  - scenes/hero_view.gd
  - scenes/hero_view.gd.uid
  - scenes/hero_view.tscn
  - scenes/crafting_view.gd
  - scenes/crafting_view.gd.uid
  - scenes/node_2d.tscn
  - .planning/STATE.md
  - .planning/MILESTONES.md
autonomous: true
requirements: [CLEANUP-01]

must_haves:
  truths:
    - "No deprecated methods exist in LootTable"
    - "No drop_simulator tool exists in the codebase"
    - "No orphaned legacy view files remain"
    - "Active game code (combat_engine, gameplay_view) continues to work"
  artifacts:
    - path: "models/loot/loot_table.gd"
      provides: "LootTable with only active methods"
      contains: "get_map_item_count"
    - path: "tools/drop_simulator.gd"
      provides: "DELETED"
  key_links:
    - from: "models/combat/combat_engine.gd"
      to: "models/loot/loot_table.gd"
      via: "LootTable.roll_pack_currency_drop, LootTable.get_map_item_count"
      pattern: "LootTable\\.(roll_pack_currency_drop|get_map_item_count)"
    - from: "scenes/gameplay_view.gd"
      to: "models/loot/loot_table.gd"
      via: "LootTable.roll_rarity, LootTable.spawn_item_with_mods"
      pattern: "LootTable\\.(roll_rarity|spawn_item_with_mods)"
---

<objective>
Remove the deprecated drop simulator tool and its associated deprecated LootTable methods, plus clean up orphaned legacy view files that were replaced by ForgeView in v1.3.

Purpose: Eliminate dead code that was flagged as known issues in STATE.md and MILESTONES.md. The deprecated methods (get_item_drop_count, roll_currency_drops) were only kept for drop_simulator compatibility, and the legacy files (hero_view, crafting_view, node_2d.tscn) have been unused since the ForgeView migration in Phase 19.

Output: Cleaner codebase with no deprecated methods, no dead tool files, and no orphaned scenes.
</objective>

<execution_context>
@/home/travelboi/.claude/get-shit-done/workflows/execute-plan.md
@/home/travelboi/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@models/loot/loot_table.gd
@tools/drop_simulator.gd
@scenes/main.tscn
</context>

<tasks>

<task type="auto">
  <name>Task 1: Delete drop simulator and orphaned legacy files</name>
  <files>
    tools/drop_simulator.gd
    tools/drop_simulator.gd.uid
    scenes/hero_view.gd
    scenes/hero_view.gd.uid
    scenes/hero_view.tscn
    scenes/crafting_view.gd
    scenes/crafting_view.gd.uid
    scenes/node_2d.tscn
  </files>
  <action>
Delete the following files using `git rm`:

1. **Drop simulator tool (dev-only, uses deprecated LootTable methods):**
   - `tools/drop_simulator.gd`
   - `tools/drop_simulator.gd.uid`

2. **Orphaned legacy view files (replaced by ForgeView in v1.3 Phase 19, NOT referenced in scenes/main.tscn):**
   - `scenes/hero_view.gd` (old hero equipment view)
   - `scenes/hero_view.gd.uid`
   - `scenes/hero_view.tscn` (old hero scene)
   - `scenes/crafting_view.gd` (old crafting view, attached to node_2d.tscn)
   - `scenes/crafting_view.gd.uid`
   - `scenes/node_2d.tscn` (old crafting scene)

After deletion, check if the `tools/` directory is empty. If so, remove it. If other files remain, leave it.

Verify NONE of these files are referenced in any active `.gd` or `.tscn` file (they are not -- main.tscn uses forge_view.tscn, gameplay_view.tscn, and settings_view.tscn).
  </action>
  <verify>
Run: `git status` shows deleted files staged.
Run: `grep -r "hero_view\|crafting_view\|node_2d\.tscn\|drop_simulator" --include="*.gd" --include="*.tscn" --include="*.cfg" .` returns NO matches from active game files (only .planning/ docs may reference them historically).
  </verify>
  <done>All 8 dead files deleted. No active game code references them.</done>
</task>

<task type="auto">
  <name>Task 2: Remove deprecated methods from LootTable</name>
  <files>models/loot/loot_table.gd</files>
  <action>
Edit `models/loot/loot_table.gd` to remove exactly two deprecated static methods:

1. **`get_item_drop_count(area_level: int) -> int`** (lines 126-148) -- marked "DEPRECATED: Use get_map_item_count() instead. Kept for drop_simulator compatibility." Remove the entire method including its doc comment.

2. **`roll_currency_drops(area_level: int) -> Dictionary`** (lines 213-265) -- marked "DEPRECATED: Use roll_pack_currency_drop() instead. Per-pack drops replace bulk rolls." Remove the entire method including its doc comment.

DO NOT remove any other methods. The following methods MUST remain intact:
- `get_rarity_weights()` -- used by roll_rarity
- `roll_rarity()` -- used by gameplay_view.gd
- `get_map_item_count()` -- used by combat_engine.gd
- `_calculate_currency_chance()` -- used by roll_pack_currency_drop
- `roll_pack_currency_drop()` -- used by combat_engine.gd
- `spawn_item_with_mods()` -- used by gameplay_view.gd
- Constants `RARITY_ANCHORS` and `CURRENCY_AREA_GATES` -- used by active methods
  </action>
  <verify>
Run: `grep -n "DEPRECATED\|get_item_drop_count\|roll_currency_drops" models/loot/loot_table.gd` returns NO matches.
Run: `grep -n "get_map_item_count\|roll_pack_currency_drop\|roll_rarity\|spawn_item_with_mods\|_calculate_currency_chance" models/loot/loot_table.gd` returns matches for all 5 active methods.
  </verify>
  <done>LootTable contains only active methods. No deprecated code remains. Active callers (combat_engine.gd, gameplay_view.gd) unaffected.</done>
</task>

<task type="auto">
  <name>Task 3: Update planning docs to clear known issues</name>
  <files>
    .planning/STATE.md
    .planning/MILESTONES.md
  </files>
  <action>
1. **Update `.planning/STATE.md`:**
   - In `### Known Issues`, remove the line: "- Deprecated LootTable methods kept for drop_simulator tool (get_item_drop_count, roll_currency_drops)"
   - In `### Known Issues`, remove the line: "- 2 orphaned legacy files (scenes/hero_view.gd, scenes/crafting_view.gd) replaced by ForgeView"
   - If the Known Issues section is now empty, replace its contents with "None" or "No known issues."
   - Add entry to `### Quick Tasks Completed` table: `| 3 | Remove deprecated loot tables and simulator tool | {today's date} | {commit hash - leave TBD} | [3-remove-the-deprecated-loot-tables-and-si](./quick/3-remove-the-deprecated-loot-tables-and-si/) |`

2. **Update `.planning/MILESTONES.md`:**
   - In the `v1.2` section, under `**Known Gaps:**`, remove the line: "- Deprecated LootTable methods kept for drop_simulator tool"
   - If Known Gaps has only one entry remaining (the level 1 difficulty line), keep that. If it becomes empty, remove the Known Gaps subsection.
  </action>
  <verify>
Run: `grep "drop_simulator\|orphaned legacy" .planning/STATE.md` returns NO matches.
Run: `grep "drop_simulator" .planning/MILESTONES.md` returns NO matches.
  </verify>
  <done>STATE.md has no known issues about deprecated code. MILESTONES.md has no known gap about drop_simulator. Quick task #3 is recorded in the completed table.</done>
</task>

</tasks>

<verification>
1. Game code integrity: `grep -rn "LootTable\." --include="*.gd" .` shows only calls to active methods (roll_rarity, spawn_item_with_mods, roll_pack_currency_drop, get_map_item_count, get_rarity_weights)
2. No dangling references: `grep -rn "drop_simulator\|hero_view\|crafting_view\|node_2d\.tscn" --include="*.gd" --include="*.tscn" --include="*.cfg" .` returns no matches
3. LootTable file has no DEPRECATED markers: `grep "DEPRECATED" models/loot/loot_table.gd` returns nothing
4. Dead files removed: `ls tools/drop_simulator.gd scenes/hero_view.* scenes/crafting_view.* scenes/node_2d.tscn 2>&1` shows "No such file"
</verification>

<success_criteria>
- 8 dead files deleted (drop_simulator tool + 6 orphaned legacy files)
- 2 deprecated methods removed from LootTable (~140 lines of dead code)
- All 6 active LootTable methods remain intact
- STATE.md and MILESTONES.md updated with no references to deprecated code
- Game compiles and runs without errors (no active code referenced the removed items)
</success_criteria>

<output>
After completion, create `.planning/quick/3-remove-the-deprecated-loot-tables-and-si/3-SUMMARY.md`
</output>
