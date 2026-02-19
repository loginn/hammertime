---
status: diagnosed
trigger: "Phase 33 UAT - three issues: health resets to 100 on revive, % health mods not applied, difficulty too steep"
created: 2026-02-19T00:00:00Z
updated: 2026-02-19T00:10:00Z
symptoms_prefilled: true
goal: find_root_cause_only
---

## Current Focus

hypothesis: all three root causes confirmed
test: full codebase trace completed
expecting: N/A - resolution documented below
next_action: return diagnosis to caller

## Symptoms

### Issue 1: Hero health resets to 100 after dying
expected: hero revives with correct max health (e.g. 150 if max health is 150)
actual: hero revives with exactly 100 HP
errors: none reported
reproduction: kill hero, observe HP on revive
started: Phase 33 UAT

### Issue 2: % health mods not being applied
expected: percentage-based health modifiers from equipment/affixes increase hero max health
actual: % health mods appear to have no effect on the hero health pool
errors: none reported
reproduction: equip item with % health affix, observe health pool unchanged
started: Phase 33 UAT

### Issue 3: Difficulty curve too steep
expected: player can progress meaningfully beyond zone 20
actual: player cannot clear beyond zone 20
errors: none reported
reproduction: play to zone 20+
started: Phase 32 biome compression (GROWTH_RATE=0.10, boss walls at biome boundaries)

## Eliminated

- hypothesis: "hero.revive() uses a hardcoded 100 literal instead of max_health"
  evidence: hero.gd line 69 — revive() correctly calls `health = max_health`; max_health is not hardcoded here
  timestamp: 2026-02-19T00:05:00Z

- hypothesis: "armor.update_value() does not apply PERCENT_HEALTH"
  evidence: armor.gd lines 46-48, helmet.gd lines 48-50, boots.gd lines 48-50 — all three item types
    correctly apply PERCENT_HEALTH inside their own update_value() methods, writing the result into base_health
  timestamp: 2026-02-19T00:07:00Z

- hypothesis: "PERCENT_HEALTH stat type is missing from tag.gd enum"
  evidence: tag.gd line 43 — PERCENT_HEALTH is defined in the StatType enum; affix exists in item_affixes.gd
  timestamp: 2026-02-19T00:08:00Z

## Evidence

- timestamp: 2026-02-19T00:03:00Z
  checked: models/hero.gd — revive(), update_stats(), calculate_defense()
  found: |
    revive() (line 67-72): sets health = max_health and current_energy_shield = float(total_energy_shield).
    update_stats() (line 91-97): calls calculate_defense() among other methods, but does NOT
    set health = max_health at any point.
    calculate_defense() (line 174-236): starts with `var total_health: int = 100` (line 184),
    adds base_health from armor slots, then sets max_health = float(total_health) at line 231.
    HOWEVER: hero.health itself is NEVER updated in update_stats() or calculate_defense().
    After equipping items, max_health is recalculated correctly but health remains whatever
    it was before (often still the initial 100.0 from var health: float = 100.0 at line 4).
  implication: |
    Issue 1 root cause: When the hero first initializes (or _init() is called), health=100.0
    and update_stats() runs but does NOT set health = max_health. So if the player has gear
    that raises max_health above 100, current health is still 100. On death, revive() sets
    health = max_health (the correct value), which is FINE. The reported "health goes back to
    100" is actually correct behavior from revive() only when max_health itself equals 100,
    meaning the underlying cause is that max_health was never correctly computed — see Issue 2.

- timestamp: 2026-02-19T00:05:00Z
  checked: models/hero.gd — calculate_defense() lines 174-236
  found: |
    The suffix loop (lines 207-228) iterates over equipped slots and processes these stat types
    from SUFFIXES only: FIRE_RESISTANCE, COLD_RESISTANCE, LIGHTNING_RESISTANCE, ALL_RESISTANCE,
    FLAT_HEALTH, FLAT_ARMOR.
    There is NO prefix loop in calculate_defense().
    There is NO check for PERCENT_HEALTH anywhere in hero.gd's calculate_defense().
    The only health accumulation is: (a) var total_health: int = 100, (b) add armor_item.base_health
    from armor/helmet/boots slots, (c) add FLAT_HEALTH from suffixes.
  implication: |
    Issue 2 root cause: The PERCENT_HEALTH affix exists and is correctly applied INSIDE each
    item's update_value() method (armor.gd, helmet.gd, boots.gd), writing the result into
    base_health. hero.gd DOES read base_health from those items (line 204-205), so PERCENT_HEALTH
    on armor items (helmets, armor, boots) is actually WORKING correctly.
    THE BUG: hero.calculate_defense() has a separate suffix loop (lines 207-228) that adds FLAT_HEALTH
    from suffixes again — but it NEVER checks for PERCENT_HEALTH anywhere. This means
    % health mods on PREFIXES of items are NOT being applied as a final global percentage
    to the hero's total health pool. The percent modifier only affects the individual item's
    base_health value (item-level scope), but there is no mechanism to apply a global
    "increased max health" percentage to the hero's total_health sum after aggregation.
    More critically: the suffix processing loop in hero.gd (lines 207-228) applies FLAT_HEALTH
    from suffixes directly — effectively double-counting it, because FLAT_HEALTH from suffixes
    on armor items was already baked into base_health by item.update_value(). This is a
    separate latent bug but not what was reported.

- timestamp: 2026-02-19T00:07:00Z
  checked: models/monsters/pack_generator.gd — GROWTH_RATE, get_level_multiplier(), boss wall logic
  found: |
    GROWTH_RATE = 0.10 (10% compounding per level), defined at line 10.
    Boss wall logic (lines 56-68): levels 22/23/24 (3 levels before biome boundary at 25)
    get +15%, +35%, +60% bonus respectively, ON TOP of the base multiplier.
    Actual multipliers computed:
      Level 20: 6.12x (base only)
      Level 22: 8.51x (+15% boss wall)
      Level 23: 10.99x (+35% boss wall)
      Level 24: 14.33x (+60% boss wall)
    That means going from zone 20 to zone 24 (only 4 levels) is a 2.34x harder increase —
    monster HP and damage more than DOUBLES over just 4 zones.
    The 10% compounding means that at level 20 monsters are already 6.12x harder than level 1,
    and the biome boundary boss walls compound that with brutal spikes.
  implication: |
    Issue 3 root cause: The GROWTH_RATE=0.10 creates a 6.12x multiplier by level 20 compared
    to level 1. The boss wall at levels 22-24 then spikes to 14.33x just before biome boundary 25.
    A player who can barely clear zone 20 (6.12x) faces an ~8.5x zone at level 22 immediately.
    If the player's gear grows linearly (typical for idle/loot games) but monster stats grow
    exponentially, the player hits a wall around level 20-22. The boss wall amplification
    (+60% at level 24) creates a particularly brutal spike that feels like an impassable wall
    even for well-geared players.

- timestamp: 2026-02-19T00:09:00Z
  checked: models/combat/combat_engine.gd — _on_hero_died(), _on_map_completed(), stop_combat()
  found: |
    _on_hero_died() (lines 190-201): calls GameState.hero.revive() then retries same level.
    _on_map_completed() (lines 172-184): sets hero.health = hero.max_health directly (line 175).
    stop_combat() (lines 46-52): sets hero.health = hero.max_health directly (line 50).
    Hero.revive() (hero.gd lines 67-72): sets health = max_health.
    All three paths correctly use max_health, NOT a hardcoded 100.
  implication: |
    The revive-to-100 symptom is a CONSEQUENCE of max_health being wrong (Issue 2),
    not a hardcoded value in the revive path. When max_health = 100 (because % health
    mods aren't boosting the hero's total pool beyond 100), revive() restores to 100,
    which appears correct to the engine but wrong to the player who expected more.
    HOWEVER: there is a separate subtle bug: update_stats() (hero.gd line 91-97) does NOT
    set health = max_health after recalculation. So if gear is equipped/unequipped mid-combat,
    the hero's current health could exceed the new max_health (if an item is removed), or
    the hero's initial health on a fresh session stays at 100.0 even if max_health is higher.

## Resolution

### Issue 1: Hero health resets to 100 after dying

root_cause: |
  INDIRECT BUG — revive() correctly uses max_health. The symptom (health = 100 on revive)
  occurs because max_health itself equals 100, which happens when Issue 2 leaves % health
  mods unapplied and the player has no gear with flat base_health.
  SECONDARY BUG: hero.update_stats() never synchronizes hero.health to the new max_health
  after stat recalculation (e.g., when gear is equipped), so on a fresh hero, health stays
  at the var declaration default of 100.0 even if max_health becomes 150 after equipping.

  Files involved:
    - models/hero.gd: update_stats() (line 91-97) — should set health = max_health after
      calculate_defense() has updated max_health

fix: N/A (research only)

### Issue 2: % health mods not being applied

root_cause: |
  TWO-LAYER BUG:

  Layer 1 (item-level % health — mostly working):
  Armor/Helmet/Boots items DO apply PERCENT_HEALTH correctly inside their own update_value()
  methods. The result is baked into item.base_health. When hero.calculate_defense() reads
  armor_item.base_health (hero.gd line 205), it gets the percentage-adjusted value. So
  PERCENT_HEALTH on armor ITEM PREFIXES is working.

  Layer 2 (global % health from any equipment — missing):
  hero.calculate_defense() has NO mechanism to apply a global "increased max health %" to
  the hero's total aggregated health pool. There is no post-aggregation percentage step for
  health the way there is for damage (StatCalculator.calculate_percentage_stat pattern).
  If the PERCENT_HEALTH affix is intended to scale the hero's TOTAL health (like PoE's
  "increased maximum life"), that global application is entirely absent from hero.gd.

  Layer 3 (double-counting FLAT_HEALTH from suffixes — latent):
  hero.calculate_defense() suffix loop (lines 207-228) adds FLAT_HEALTH from suffixes
  (line 225-226). But armor.update_value() / helmet.update_value() / boots.update_value()
  ALSO add FLAT_HEALTH from those same affixes into base_health. So FLAT_HEALTH on suffixes
  of armor items is counted TWICE in the hero's total health.

  Primary reported symptom root cause: Missing global PERCENT_HEALTH aggregation step in
  hero.calculate_defense(). The percentage modifier only scales the item's own base_health
  (item-local scope), not the final hero total.

  Files involved:
    - models/hero.gd: calculate_defense() (lines 174-236) — missing global PERCENT_HEALTH
      aggregation after the total_health sum is computed

fix: N/A (research only)

### Issue 3: Difficulty curve too steep

root_cause: |
  GROWTH_RATE = 0.10 produces exponential scaling that outpaces typical player gear progression.
  By level 20 monsters are already 6.12x harder than level 1. The boss wall mechanism adds
  +15/+35/+60% bonuses at levels 22/23/24, spiking the multiplier from 6.12x at L20 to
  14.33x at L24 — a 2.34x jump in just 4 levels.

  The biome system compresses gameplay into 25-level spans, meaning the hardest boss wall
  encounter (60% spike at level 24) falls within reach for early players who are still
  gearing up. The exponential base combined with the additive boss wall multipliers means:

  - L20 to L22 = +39% harder (6.12x -> 8.51x)
  - L22 to L23 = +29% harder (8.51x -> 10.99x)
  - L23 to L24 = +30% harder (10.99x -> 14.33x)
  - L24 to L25 = -57% easier (biome boundary relief dip back to 6.15x)

  The player who cannot clear zone 20 is facing a 6.12x monster difficulty versus level 1.
  If item drops from Phase 33 are not yet scaling hero power proportionally (Issue 2 means
  % health mods are partially broken), the gap between hero power and monster power widens.

  Key constants to consider reducing:
    - GROWTH_RATE = 0.10 in pack_generator.gd (line 10) — lowering to 0.07 or 0.08 would
      extend viable progression range significantly
    - Boss wall bonuses: +15/+35/+60% at lines 63-66 are steep; could be reduced to
      +10/+20/+40% for a softer biome culmination

  Files involved:
    - models/monsters/pack_generator.gd: GROWTH_RATE (line 10), boss wall bonuses (lines 63-66)

files_changed: []
