---
status: diagnosed
trigger: "forge view is_item_better() uses simple tier comparison for armor/helmet/boots — user wants per-defensive-stat comparison"
created: 2026-02-18T00:00:00Z
updated: 2026-02-18T00:00:00Z
---

## Current Focus

hypothesis: Confirmed — is_item_better() uses item.tier (a scalar) for all non-Weapon/Ring items, ignoring the rich per-stat data already present on Armor/Helmet/Boots
test: Read is_item_better() at forge_view.gd:465-472 and compared against item model fields
expecting: Replacement logic must sum/score per-stat contributions (armor, evasion, ES, HP, resistances) and compare new vs existing totals
next_action: Deliver diagnosis

## Symptoms

expected: Incoming armor/helmet/boots items should be kept in crafting inventory when they are strictly better on a per-stat basis (more total defensive value across Evasion, HP, Armor, ES, Resistances)
actual: The method returns `new_item.tier > existing_item.tier` for all three defensive slots, ignoring all affix-derived stat inflation and the fact that two different base items at the same tier can have wildly different effective stats
errors: None (logic error, not a crash)
reproduction: Drop a lower-tier armor with a high-roll FLAT_ARMOR prefix — it will be rejected in favor of a bare higher-tier piece even though it has more effective armor
started: Always present by design

## Evidence

- timestamp: 2026-02-18
  checked: scenes/forge_view.gd lines 465-472
  found: |
    func is_item_better(new_item: Item, existing_item: Item) -> bool:
      if new_item is Weapon and existing_item is Weapon:
        return new_item.dps > existing_item.dps
      if new_item is Ring and existing_item is Ring:
        return new_item.dps > existing_item.dps
      return new_item.tier > existing_item.tier  # <-- the problem
  implication: Tier is the raw base-item tier (e.g. 1, 2, 3 set at item creation), not a composite of effective stats after affixes are applied.

- timestamp: 2026-02-18
  checked: models/items/armor.gd, helmet.gd, boots.gd
  found: |
    All three classes expose: base_armor, base_evasion, base_energy_shield, base_health
    Boots also has base_movement_speed; Helmet also has base_mana.
    These are ALREADY post-affix values (update_value() folds flat + percent modifiers in).
    Resistances are NOT stored on the item; they live in suffix arrays (StatType.FIRE/COLD/LIGHTNING/ALL_RESISTANCE).
  implication: All the data needed for a per-stat comparison is accessible directly from item fields and suffix arrays — no new model machinery is required.

- timestamp: 2026-02-18
  checked: scenes/forge_view.gd lines 782-787 (_sum_suffix_stat helper)
  found: |
    func _sum_suffix_stat(item: Item, stat_type: int) -> int:
      var total: int = 0
      for suffix in item.suffixes:
        if stat_type in suffix.stat_types:
          total += suffix.value
      return total
  implication: A resistance-summing helper already exists in the same file and can be called directly from is_item_better().

- timestamp: 2026-02-18
  checked: models/items/item.gd line 16
  found: var tier: int  (scalar, set at item construction in subclasses)
  implication: Tier has no defensive meaning by itself — it only indicates which base type (e.g. BasicArmor tier 1 vs 2) was used as a template, before any affix application.

- timestamp: 2026-02-18
  checked: models/stats/stat_calculator.gd
  found: No defensive-stat aggregation helper exists. StatCalculator only has calculate_flat_stat, calculate_percentage_stat, calculate_dps, calculate_damage_range.
  implication: A scoring helper could be added to StatCalculator, or the scoring logic can live entirely in forge_view.gd using existing fields.

## Eliminated

- hypothesis: "The stat comparison UI (get_stat_comparison_text) and is_item_better() share a root cause"
  evidence: get_stat_comparison_text() already does per-stat deltas correctly (lines 618-743). Only is_item_better() uses tier. They are independent paths.
  timestamp: 2026-02-18

## Resolution

root_cause: |
  is_item_better() uses `new_item.tier > existing_item.tier` as a universal fallback for Armor, Helmet, and Boots.
  Tier is a single scalar that encodes only which base template was used — it does not account for:
    (a) affix-inflated stats (flat/percent armor, evasion, ES, health modifiers already folded into base_* fields via update_value())
    (b) suffix resistances (fire/cold/lightning/all from suffix arrays)
  A Tier 1 item with three PERCENT_ARMOR prefixes can have more total armor than a bare Tier 2 item, but is_item_better() will always discard it.

fix: |
  Replace the `return new_item.tier > existing_item.tier` line with per-item-type stat scoring.
  For each defensive item type, compute a scalar "defensive score" for new and existing items, then compare.
  Suggested scoring per type:

    Armor:   base_armor + base_evasion + base_energy_shield + base_health
             + sum(fire/cold/lightning/all resistances from suffixes)
    Helmet:  base_armor + base_evasion + base_energy_shield + base_health + base_mana
             + sum(resistances from suffixes)
    Boots:   base_armor + base_evasion + base_energy_shield + base_health + base_movement_speed
             + sum(resistances from suffixes)

  The _sum_suffix_stat() helper already in forge_view.gd handles resistance summing.
  No new model files need to change.

files_changed: []
