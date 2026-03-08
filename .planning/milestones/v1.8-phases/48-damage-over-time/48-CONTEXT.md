# Phase 48: Damage Over Time - Context

**Gathered:** 2026-03-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Add DoT system (bleed, poison, burn) with CombatEngine tick processing, defense interaction, and UI feedback. Bidirectional — hero applies DoTs to packs, packs apply DoTs to hero. Requirements: DOT-01 through DOT-07.

</domain>

<decisions>
## Implementation Decisions

### DoT Type Identity (each type is mechanically distinct)

**Bleed (STR archetype, PHYSICAL, attack-mode only):**
- Up to 8 stacks active simultaneously
- New application replaces the stack closest to expiry
- Scales with hit power: tick = hit_damage * base% * (1 + %bleed)
- base% comes from flat bleed damage affixes (converted to a scaling factor)
- Crit hits produce bigger bleeds (emergent from % of hit formula)

**Poison (DEX archetype, CHAOS, attack-mode only):**
- Infinite stacks (no cap, practically unbounded)
- Each stack deals identical flat damage, not scaled by hit power
- tick per stack = flat_poison * (1 + %poison)
- Power comes from stack count — fast attackers with high poison chance pile stacks
- Crit interaction: +100% chance to apply poison on crit hit
- Chance overflow: 120% chance = 1 guaranteed stack + 20% chance for a second stack

**Burn (INT archetype, FIRE, spell-mode only):**
- Single stack only
- Refreshes on each new spell hit (new application replaces previous)
- Scales strongly with hit power: tick = hit_damage * base% * (1 + %burn)
- base% higher than bleed (burn is the heavy single-stack DoT)
- Crit hits produce bigger burns (emergent from % of hit formula)

### Tick Mechanics
- 4-second duration per application, 1 tick per second (4 ticks total)
- Chance-based procs: each hit rolls against hero's total X_CHANCE stat
- 0% chance = no DoT even with flat damage stats
- Active combat mode determines which DoTs can proc:
  - Attack-mode hero: can proc bleed and poison, cannot proc burn
  - Spell-mode hero: can proc burn, cannot proc bleed or poison

### Defense Interaction
- DoT bypasses evasion and armor — only reduced by matching resistance
- Bleed (physical): no resistance applies (no physical resistance exists), full damage
- Poison (chaos): reduced by chaos resistance
- Burn (fire): reduced by fire resistance
- ES/Life split DOES apply to DoT ticks (50/50 split like direct hits)
- DoT does NOT bypass ES — ES builds get partial protection

### Bidirectional DoT (packs apply DoTs to hero)
- Pack DoT is element-based auto-proc:
  - Fire packs can apply burn, physical packs can apply bleed
  - Lightning/Cold packs: no DoT
- Pack DoT chance: 10% + (area_level * 0.2)%
- Pack DoT damage: pack.damage * 0.25 per tick
- Hero defenses (resistance + ES/Life split) apply to pack DoT ticks

### Combat UI Feedback
- Single running total accumulator for all DoTs combined
  - Stays visible near the HP bar, number grows with each tick
  - Fades out when all DoTs expire
  - Color-coded (dominant type or white)
  - Visually distinct from direct hit floating text (smaller, persistent vs float-away)
- Text label on HP bars showing active DoTs: "BLEED x3", "POISON x7", "BURN"
- Hero View stats panel shows "DoT DPS: X" below Attack/Spell DPS (hidden when 0)

### DoT DPS Display
- Combined DoT DPS line in hero stats (not per-type breakdown)
- Hidden when hero has no DoT stats
- Calculation: expected damage per second across all DoT types factoring chance and stacks

### Claude's Discretion
- Exact base% values for bleed and burn scaling (burn higher than bleed)
- Exact flat poison damage values per affix tier
- Pack DoT stacking behavior (likely single stack refresh for simplicity)
- DoT accumulator visual design (exact position, font size, fade timing)
- DoT DPS formula specifics for the hero stats display
- Whether to create a DoT manager class or integrate directly into CombatEngine

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `tag.gd`: All DoT stat types already declared (BLEED_DAMAGE, POISON_DAMAGE, BURN_DAMAGE, BLEED_CHANCE, POISON_CHANCE, BURN_CHANCE, CHAOS_RESISTANCE)
- `tag.gd`: DOT tag constant exists for affix filtering
- `item_affixes.gd`: All 10 DoT affixes already registered (flat damage prefixes, chance suffixes, % damage suffixes, generic %DoT prefix)
- `combat_engine.gd`: Dual timer architecture + spell timer. Hit handlers (_on_hero_attack, _on_hero_spell_hit) are DoT proc points
- `defense_calculator.gd`: 4-stage pipeline with resistance calculation. Can extract resistance-only path for DoT
- `floating_label.gd`: Tween-based floating text. show_damage/show_spell_damage/show_dodge patterns to extend
- `game_events.gd`: Signal bus pattern for decoupled UI observation
- `hero.gd`: Stat aggregation pattern (calculate_damage_ranges, calculate_defense). Mirror for DoT stats
- `monster_pack.gd`: Simple hp/take_damage model. Needs DoT effect tracking added

### Established Patterns
- DPS calculation: flat damage -> % damage -> speed -> crit multiplier (StatCalculator)
- Per-element damage rolling in CombatEngine with crit on total
- Hero caches stat totals in update_stats(), UI reads cached values
- GameEvents signal -> gameplay_view handler -> spawn floating text
- is_spell_user boolean on Hero determines active combat channel (Phase 47)

### Integration Points
- `combat_engine.gd`: _on_hero_attack() and _on_hero_spell_hit() — add DoT proc rolls after hit damage
- `combat_engine.gd`: Need DoT tick processing (timer or process-based)
- `combat_engine.gd`: _on_pack_attack() — add pack DoT proc on hero
- `defense_calculator.gd`: Add resistance-only damage calculation method for DoT ticks on hero
- `hero.gd`: Add DoT stat aggregation (total_bleed_chance, total_bleed_damage, etc.)
- `hero.gd`: Add calculate_dot_dps() for stats display
- `monster_pack.gd`: Add active DoT effect tracking (array/dict of active effects)
- `game_events.gd`: Add dot_ticked signal for UI
- `gameplay_view.gd`: Connect DoT signals, manage accumulator label and status text
- `scenes/forge_view.gd`: Add DoT DPS line to hero stats display

</code_context>

<specifics>
## Specific Ideas

- Each DoT type has real mechanical identity: bleed = multi-stack hit-scaled (STR), poison = infinite flat stacks (DEX speed), burn = single powerful hit-scaled stack (INT)
- Poison chance overflow: 120% chance = 1 guaranteed + 20% for second stack — rewards heavy investment
- Poison +100% chance on crit — gives crit meaningful interaction with poison despite no damage scaling
- DoT accumulator is a single number near HP bar that ticks up — NOT individual floating-away numbers per tick
- "DoT is supplemental" — affix values intentionally lower than direct damage (from Phase 45 context)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 48-damage-over-time*
*Context gathered: 2026-03-08*
