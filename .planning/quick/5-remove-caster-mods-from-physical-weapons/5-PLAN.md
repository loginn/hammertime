---
phase: quick
plan: 5
type: execute
wave: 1
depends_on: []
files_modified:
  - autoloads/item_affixes.gd
autonomous: true
requirements: [QUICK-5]

must_haves:
  truths:
    - "Light Sword cannot roll Cast Speed suffix"
    - "Items with Tag.MAGIC can still roll Cast Speed"
    - "All other weapon affixes remain rollable on Light Sword (physical damage, elemental damage, attack speed, crit, resistances, etc.)"
  artifacts:
    - path: "autoloads/item_affixes.gd"
      provides: "Affix definitions with corrected caster mod tags"
      contains: "Cast Speed"
  key_links:
    - from: "models/items/item.gd"
      to: "autoloads/item_affixes.gd"
      via: "has_valid_tag() filters affixes by matching item.valid_tags against affix.tags"
      pattern: "has_valid_tag"
---

<objective>
Remove caster-oriented affixes from rolling on physical weapons like Light Sword.

Purpose: Physical weapons should only roll attack/physical/elemental/defense mods, not caster mods like Cast Speed. The tag-based affix filtering currently allows caster mods to leak through via the shared `Tag.WEAPON` tag.

Output: Updated affix definitions that prevent caster mods from appearing on physical weapon bases.
</objective>

<execution_context>
@/home/travelboi/.claude/get-shit-done/workflows/execute-plan.md
@/home/travelboi/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@autoloads/item_affixes.gd
@autoloads/tag.gd
@models/items/item.gd (has_valid_tag method — the filtering mechanism)
@models/items/light_sword.gd (valid_tags: [Tag.PHYSICAL, Tag.ATTACK, Tag.CRITICAL, Tag.WEAPON])
</context>

<tasks>

<task type="auto">
  <name>Task 1: Remove Tag.WEAPON from caster affixes so they only match caster items</name>
  <files>autoloads/item_affixes.gd</files>
  <action>
In `autoloads/item_affixes.gd`, remove `Tag.WEAPON` from the "Cast Speed" suffix definition (line 181).

Current: `Affix.new("Cast Speed", Affix.AffixType.SUFFIX, 2, 10, [Tag.MAGIC, Tag.WEAPON], [])`
Change to: `Affix.new("Cast Speed", Affix.AffixType.SUFFIX, 2, 10, [Tag.MAGIC], [])`

This is the ONLY caster affix that leaks onto physical weapons. The mechanism:
- LightSword.valid_tags includes Tag.WEAPON
- Cast Speed tags include [Tag.MAGIC, Tag.WEAPON]
- has_valid_tag() returns true because Tag.WEAPON matches

By removing Tag.WEAPON from Cast Speed, it will only match items whose valid_tags include Tag.MAGIC. Physical weapons (Light Sword) do NOT have Tag.MAGIC, so Cast Speed will no longer roll on them. Future caster weapons that include Tag.MAGIC in their valid_tags will still be able to roll Cast Speed.

The other caster affix "Sigil" already has tags [Tag.DEFENSE, Tag.MAGIC] with no Tag.WEAPON, so it already cannot roll on Light Sword. No changes needed there.

Do NOT change any other affix definitions. Elemental damage mods (Lightning, Fire, Cold, %Elemental, etc.) are intended to roll on physical weapons — they are attack mods that happen to deal elemental damage, not caster mods.
  </action>
  <verify>
Verify the change by reading item_affixes.gd and confirming:
1. "Cast Speed" suffix tags are [Tag.MAGIC] (no Tag.WEAPON)
2. All other affixes remain unchanged
3. Run the game scene if possible, or verify by tracing the tag logic:
   - LightSword.valid_tags = [Tag.PHYSICAL, Tag.ATTACK, Tag.CRITICAL, Tag.WEAPON]
   - Cast Speed tags = [Tag.MAGIC] — no overlap — Cast Speed will NOT appear on Light Sword
   - Attack Speed tags = [Tag.SPEED, Tag.ATTACK, Tag.WEAPON] — Tag.ATTACK and Tag.WEAPON overlap — still rolls (correct)
  </verify>
  <done>Cast Speed suffix no longer has Tag.WEAPON in its tags array. Physical weapons like Light Sword cannot roll Cast Speed because they lack Tag.MAGIC. No other affixes are affected.</done>
</task>

</tasks>

<verification>
- Read autoloads/item_affixes.gd and confirm Cast Speed tags are [Tag.MAGIC] only
- Trace tag matching: LightSword valid_tags has no Tag.MAGIC, so Cast Speed (requiring Tag.MAGIC) will never match
- Confirm all other weapon affixes still have Tag.WEAPON and will continue rolling on physical weapons
</verification>

<success_criteria>
- Cast Speed suffix tags = [Tag.MAGIC] (Tag.WEAPON removed)
- No other affix definitions changed
- Physical weapons (LightSword) cannot roll Cast Speed
- Future caster items with Tag.MAGIC in valid_tags can still roll Cast Speed
</success_criteria>

<output>
After completion, create `.planning/quick/5-remove-caster-mods-from-physical-weapons/5-SUMMARY.md`
</output>
