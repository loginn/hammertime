---
status: resolved
trigger: "Investigate and fix 3 UAT gaps from Phase 22 (Balance & Polish)"
created: 2026-02-18T00:00:00Z
updated: 2026-02-18T00:35:00Z
---

## Current Focus

hypothesis: All 3 gaps confirmed with root causes identified. Gap 1: divide monster base_hp by 2 in biome_config.gd + add health reset in combat_engine. Gap 2: calculate_defense needs to sum base_health from equipment + display health in hero stats. Gap 3: apply rarity color when displaying equipped item on hover.
test: Implementing fixes for all 3 gaps
expecting: All issues resolved
next_action: Apply fixes to biome_config.gd, hero.gd, forge_view.gd, combat_engine.gd

## Symptoms

expected:
- Gap 1: Fresh hero with starter Runic Hammer can craft tier 1 weapon and survive 3+ packs in Forest
- Gap 2: Hero stats panel shows Health/ES, health mods apply correctly
- Gap 3: Item type button hover shows rarity color

actual:
- Gap 1: Monsters still too strong even after 40% reduction
- Gap 2: Health mods don't apply, Health/ES not shown in stats panel
- Gap 3: Equipped item text on hover doesn't use rarity color

errors: None

reproduction:
- Gap 1: Start new game, craft with Runic Hammer, enter Forest
- Gap 2: Equip item with health mods, check stats panel
- Gap 3: Hover over item type buttons in forge view

started: Reported in UAT 22

## Eliminated

## Evidence

- timestamp: 2026-02-18T00:05:00Z
  checked: models/monsters/biome_config.gd Forest biome monster base HP
  found: Forest monsters have base HP: Forest Bear 72, Timber Wolf 48, Wild Boar 60, Spider 30, Sprite 24, Golem 90
  implication: These base values are scaled by area level. For level 1, these are the actual HP values. User says divide by 2.

- timestamp: 2026-02-18T00:10:00Z
  checked: models/hero.gd calculate_defense() method
  found: Method calculates total_armor, total_evasion, total_energy_shield from equipment but does NOT calculate max_health from base_health properties on armor/helmet/boots
  implication: Health mods not applying - calculate_defense doesn't sum base_health from equipment

- timestamp: 2026-02-18T00:12:00Z
  checked: scenes/forge_view.gd update_hero_stats_display() lines 545-586
  found: Hero stats display shows DPS, Crit Chance/Damage, then Defense section with Armor, Evasion, Energy Shield, and resistances. No Health or max_health displayed.
  implication: Gap 2 confirmed - hero stats panel missing Health/ES (ES is shown but Health is not)

- timestamp: 2026-02-18T00:15:00Z
  checked: scenes/forge_view.gd _on_type_hover_entered() lines 328-335
  found: When hovering item type button, displays equipped item stats using get_item_stats_text(equipped_item) but doesn't apply rarity color
  implication: Gap 3 - need to apply get_rarity_color() to the equipped item text during hover

- timestamp: 2026-02-18T00:20:00Z
  checked: models/combat/combat_engine.gd _on_map_completed() line 161
  found: On map completion, only ES is reset (current_energy_shield = total_energy_shield). Health is NOT reset to max_health.
  implication: Gap 1 sub-issue - hero health should reset between maps along with ES

- timestamp: 2026-02-18T00:22:00Z
  checked: User request for Gap 1
  found: "hero should only have access to 1 light sword and should clear maps to get the new items"
  implication: Need to review starting inventory - may need to remove starting armor/helmet/boots/ring, keep only weapon

## Resolution

root_cause: |
  Gap 1 (Monster Survivability):
    - Monster base HP values too high (need to divide by 2)
    - Hero health not resetting between maps (only ES resets)
    - Starting inventory gives 5 items (weapon, helmet, armor, boots, ring) but should only give weapon

  Gap 2 (Health Stats Missing):
    - calculate_defense() in hero.gd doesn't sum base_health from equipment
    - max_health never updated from equipped items
    - Hero stats display doesn't show Health or max_health

  Gap 3 (Rarity Color Missing):
    - When hovering item type buttons, equipped item text displayed without rarity color
    - Need to apply get_rarity_color() modulation to hero_stats_label in hover state

fix: |
  1. biome_config.gd: Divide all monster base_hp values by 2 (lines 64-109)
  2. combat_engine.gd: Reset hero health on map completion (line 161)
  3. forge_view.gd: Remove starting helmet/armor/boots/ring, keep only weapon (lines 144-153)
  4. hero.gd: Add base_health calculation in calculate_defense() and update max_health
  5. forge_view.gd: Add Health display to hero stats panel
  6. forge_view.gd: Apply rarity color when displaying equipped item on hover

verification: |
  All fixes implemented and verified:
  1. Monster base HP halved (Forest Bear 36, Wolf 24, Boar 30, Spider 15, Sprite 12, Golem 45)
  2. Hero health resets on map completion (GameState.hero.health = max_health)
  3. Starting inventory now gives only 1 LightSword (removed helmet/armor/boots/ring)
  4. Health calculation added to calculate_defense() with max_health update
  5. Hero stats panel displays "Health: X/Y"
  6. Item type button hover applies rarity color via modulate = get_rarity_color()

files_changed:
  - models/monsters/biome_config.gd (divided all monster base_hp by 2)
  - models/combat/combat_engine.gd (reset hero health on map completion)
  - scenes/forge_view.gd (removed starting armor/helmet/boots/ring, added health display, fixed rarity color)
  - models/hero.gd (added base_health calculation and max_health update)
