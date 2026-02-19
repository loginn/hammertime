---
phase: quick
plan: 8
type: execute
wave: 1
depends_on: []
files_modified:
  - autoloads/item_affixes.gd
  - models/hero.gd
autonomous: true
must_haves:
  truths:
    - "Every suffix with a stat_type contributes to hero stats when equipped"
    - "Suffixes that are purely cosmetic/unimplemented have empty stat_types AND are clearly marked"
    - "Weapon/ring 'Life' and 'Armor' suffixes actually affect hero health/armor totals"
  artifacts:
    - path: "autoloads/item_affixes.gd"
      provides: "All affix definitions with correct stat_types"
    - path: "models/hero.gd"
      provides: "Hero stat aggregation that reads defensive suffixes from ALL slots"
  key_links:
    - from: "autoloads/item_affixes.gd"
      to: "models/hero.gd"
      via: "stat_types on affixes -> calculate_defense reads them"
      pattern: "suffix\\.stat_types"
---

<objective>
Audit the full affix pipeline and fix gaps where affixes can roll on items but contribute nothing to hero stats.

Purpose: Multiple suffixes either have empty stat_types (making them dead weight that wastes a mod slot) or have stat_types that are never read by hero stat aggregation. Players lose power when rolling these affixes with no feedback that they are inert.

Output: All rollable affixes either (a) contribute to hero stats or (b) are removed/disabled until a mechanic exists for them.
</objective>

<execution_context>
@/home/travelboi/.claude/get-shit-done/workflows/execute-plan.md
@/home/travelboi/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@autoloads/item_affixes.gd
@autoloads/tag.gd
@models/affixes/affix.gd
@models/hero.gd
@models/stats/stat_calculator.gd
@models/items/weapon.gd
@models/items/ring.gd
@models/items/armor.gd
@models/items/helmet.gd
@models/items/boots.gd
</context>

<tasks>

<task type="auto">
  <name>Task 1: Audit affix pipeline and document all gaps</name>
  <files>autoloads/item_affixes.gd, autoloads/tag.gd</files>
  <action>
Perform a systematic audit of every affix in item_affixes.gd by tracing each one through the full pipeline: definition -> item selection (valid_tags) -> stat calculation (stat_types) -> hero aggregation (hero.gd calculate_defense/calculate_dps).

The audit has already been performed. Here are the findings:

**GAP 1: 9 suffixes have empty stat_types [] -- they roll on items but do NOTHING:**
- "Cast Speed" (tags: MAGIC) -- no StatType exists for cast speed
- "Damage over time" (tags: DOT, WEAPON) -- no StatType exists for DoT
- "Bleed Damage" (tags: DOT, PHYSICAL, WEAPON) -- no StatType exists for bleed
- "Sigil" (tags: DEFENSE, MAGIC) -- no StatType, unclear purpose
- "Evade" (tags: DEFENSE, WEAPON) -- should probably use FLAT_EVASION
- "Physical Reduction" (tags: DEFENSE, WEAPON) -- no StatType for phys reduction
- "Magical Reduction" (tags: DEFENSE, WEAPON) -- no StatType for magic reduction
- "Dodge Chance" (tags: DEFENSE, WEAPON) -- no StatType for dodge
- "Dmg Suppression Chance" (tags: DEFENSE, WEAPON) -- no StatType for suppression

**GAP 2: "Life" suffix (FLAT_HEALTH) and "Armor" suffix (FLAT_ARMOR) on weapons/rings are processed by stat_calculator but NEVER read by hero.gd:**
- hero.gd calculate_defense() only reads base_armor/base_evasion/etc from ["helmet", "armor", "boots"] slots
- hero.gd calculate_defense() only reads suffixes for RESISTANCE stats from all slots
- So "Life" suffix on a weapon adds FLAT_HEALTH but Weapon.update_value() doesn't compute health, and hero.gd doesn't check weapon for health contribution
- Same for "Armor" suffix on weapons

**DECISION for Gap 1:** Remove the 9 inert suffixes from the pool entirely. They waste a mod slot and confuse players. If/when DoT, cast speed, dodge, suppression, etc. mechanics are implemented, they can be re-added with proper stat_types. Comment them out with a note explaining they are disabled pending future mechanic support.

**DECISION for Gap 2:** Fix hero.gd calculate_defense() to also read FLAT_HEALTH and FLAT_ARMOR from weapon/ring suffixes. This makes "Life" and "Armor" suffixes on weapons actually contribute to hero stats.

Implementation:
1. In `autoloads/item_affixes.gd`, comment out the 9 inert suffixes from the `suffixes` array. Add a block comment above them: "# DISABLED: These suffixes have no stat_type implementation yet. Re-enable when mechanics are added."
2. Keep the following suffixes active (they have working stat_types): Attack Speed, Life, Armor, Fire Resistance, Cold Resistance, Lightning Resistance, All Resistances, Critical Strike Chance, Critical Strike Damage.
  </action>
  <verify>Count active suffixes in item_affixes.gd -- should be exactly 9 (Attack Speed, Life, Armor, Fire/Cold/Lightning Resistance, All Resistances, Crit Chance, Crit Damage). Verify no suffix in the active array has empty stat_types [].</verify>
  <done>All 9 inert suffixes are commented out with explanation. Only suffixes with working stat_types remain in the active pool.</done>
</task>

<task type="auto">
  <name>Task 2: Fix hero stat aggregation to read defensive suffixes from weapon/ring</name>
  <files>models/hero.gd</files>
  <action>
In hero.gd `calculate_defense()`, the existing resistance suffix loop (lines 207-224) already iterates all 5 slots (weapon, helmet, armor, boots, ring) for resistance stat_types. Extend this same loop to ALSO accumulate FLAT_HEALTH and FLAT_ARMOR from suffixes on weapon/ring slots.

Specifically, inside the existing `for slot in ["helmet", "armor", "boots", "weapon", "ring"]` loop that processes suffixes:
- Add: if Tag.StatType.FLAT_HEALTH in suffix.stat_types, add suffix.value to total_health
- Add: if Tag.StatType.FLAT_ARMOR in suffix.stat_types, add suffix.value to total_armor

This must happen AFTER the base stat aggregation from armor pieces (lines 187-206) but uses the same `total_health` variable that feeds into `max_health`.

Note: The "Armor" and "Life" suffixes currently have tags `[Tag.DEFENSE, Tag.WEAPON]` so they can roll on weapons. After this fix, their FLAT_ARMOR and FLAT_HEALTH stat_types will actually feed into hero totals.

Do NOT change how armor/helmet/boots items calculate their own base stats (their update_value() already handles prefixes correctly via StatCalculator). This fix is specifically for suffix stat_types on weapon/ring that currently fall through the cracks in hero aggregation.
  </action>
  <verify>Read hero.gd calculate_defense() and confirm: (1) FLAT_HEALTH from suffixes on ALL slots feeds into max_health, (2) FLAT_ARMOR from suffixes on ALL slots feeds into total_armor. Verify the loop structure is clean and doesn't double-count (armor items already fold flat prefix stats into their base_armor via update_value, so only suffix contributions need to be added here).</verify>
  <done>A weapon with a "Life" suffix now increases hero max_health. A weapon with an "Armor" suffix now increases hero total_armor. The calculate_defense() method reads FLAT_HEALTH and FLAT_ARMOR from suffixes across all 5 equipment slots.</done>
</task>

</tasks>

<verification>
1. Grep for `stat_types` in active (non-commented) suffix definitions in item_affixes.gd -- none should be empty `[]`
2. Read hero.gd calculate_defense() -- confirm it processes FLAT_HEALTH, FLAT_ARMOR, and all RESISTANCE stat_types from suffixes on ALL 5 equipment slots
3. No suffix in the active pool is a "dead mod" that wastes a player's affix slot
</verification>

<success_criteria>
- Zero active affixes with empty stat_types in item_affixes.gd
- hero.gd calculate_defense() aggregates FLAT_HEALTH and FLAT_ARMOR from suffixes on all slots
- 9 inert suffixes commented out with clear re-enablement instructions
- Remaining 9 active suffixes all have functional stat_type -> hero stat pathways
</success_criteria>

<output>
After completion, create `.planning/quick/8-audit-and-fix-affix-pipeline-to-ensure-a/8-SUMMARY.md`
</output>
