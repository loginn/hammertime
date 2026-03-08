# Phase 45: Affix Pool Expansion - Context

**Gathered:** 2026-03-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Add spell damage affixes, cast speed suffix, chaos resistance suffix, and DoT affixes (bleed/poison/burn with flat + chance + % variants) to the rollable affix pool. Enable disabled stubs where applicable. Drop the Evade suffix (AFF-04) -- evasion is already covered by prefixes.

</domain>

<decisions>
## Implementation Decisions

### Spell Damage Prefixes (AFF-01, AFF-02)
- Flat Spell Damage prefix: tags [SPELL, FLAT, WEAPON], stat FLAT_SPELL_DAMAGE
- %Spell Damage prefix: tags [SPELL, PERCENTAGE, WEAPON], stat INCREASED_SPELL_DAMAGE
- SPELL tag gates access -- only items with SPELL in valid_tags can roll these (INT weapons + Sapphire Ring)
- Flat Spell Damage uses range-based pattern (dmg_min_lo/hi, dmg_max_lo/hi) consistent with all other flat damage prefixes
- Values match physical damage parity: base_min=3-5, base_max=7-10, tight 1:1.5 ratio

### Cast Speed Suffix (AFF-03)
- Tags: [SPEED] only -- any item with SPEED tag can roll it
- Stat: INCREASED_CAST_SPEED
- Currently all rings have SPEED tag, plus relevant weapons -- cast speed accessible to all ring archetypes

### Evade Suffix (AFF-04) -- DROPPED
- No evade suffix added. Evasion prefixes (flat + %) already exist and provide sufficient evasion access
- User decision: suffixes and prefixes should not duplicate the same mechanic

### Chaos Resistance Suffix (new, not in original AFF scope)
- Tags: [DEFENSE, CHAOS, WEAPON] -- mirrors other resistance suffix tag patterns
- Stat: CHAOS_RESISTANCE
- Available on all defense items + weapons, consistent with other resistance suffixes
- Separate from ALL_RESISTANCE (decided in Phase 42) -- chaos resist is harder to get

### DoT Affixes (AFF-05, expanded)
- 10 DoT affixes total, organized by type:

**Bleed (STR archetype, PHYSICAL tag):**
- Flat Bleed Damage prefix (BLEED_DAMAGE stat)
- Bleed Chance suffix (BLEED_CHANCE stat -- new stat type added this phase)
- %Bleed Damage suffix (BLEED_DAMAGE stat, percentage scaling)

**Poison (DEX archetype, CHAOS tag):**
- Flat Poison Damage prefix (POISON_DAMAGE stat)
- Poison Chance suffix (POISON_CHANCE stat -- new stat type added this phase)
- %Poison Damage suffix (POISON_DAMAGE stat, percentage scaling)

**Burn (INT archetype, FIRE tag):**
- Flat Burn Damage prefix (BURN_DAMAGE stat)
- Burn Chance suffix (BURN_CHANCE stat -- new stat type added this phase)
- %Burn Damage suffix (BURN_DAMAGE stat, percentage scaling)

**Generic:**
- %DoT Damage prefix (generic, scales all DoT types -- available to all weapons with DOT tag)

- Archetype-exclusive gating: bleed = PHYSICAL tag (STR), poison = CHAOS tag (DEX), burn = FIRE tag (INT)
- DoT flat damage values lower than direct damage (e.g., 2-3 min, 4-6 max) -- DoT is supplemental
- DoT chance values: base 3-10% range (higher chance, DoT should feel impactful)
- All affixes use full Vector2i(1, 32) tier range

### New Stat Types (added to tag.gd)
- BLEED_CHANCE, POISON_CHANCE, BURN_CHANCE added to StatType enum
- Required for DoT chance suffixes; not present from Phase 42

### Claude's Discretion
- Exact base_min/base_max values for each new affix (within guidelines above)
- Tag list for generic %DoT prefix (likely [DOT, WEAPON] or similar)
- Whether to delete the old disabled stub comments or keep them as reference
- Ordering of new affixes in the prefixes/suffixes arrays

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `autoloads/item_affixes.gd`: All affix definitions live here. Disabled stubs at lines 243-255 provide starting points for Cast Speed and Bleed.
- `autoloads/tag.gd`: All Tag constants and StatType enum. SPELL, CHAOS, DoT stat types already exist from Phase 42.
- `models/affix.gd`: Affix class with constructor supporting range-based damage params (dmg_min_lo/hi, dmg_max_lo/hi).

### Established Patterns
- Prefixes use Affix.new(name, PREFIX, base_min, base_max, tags[], stat_types[], tier_range, [dmg params])
- Suffixes use same constructor without damage range params (unless flat damage suffix)
- Tag-based filtering: item.valid_tags must contain ALL tags in affix.tags for the affix to be rollable
- Flat damage affixes include 4 extra params for damage ranges
- % damage affixes use INCREASED_DAMAGE stat with element tag filtering

### Integration Points
- `item_affixes.gd`: Add new prefixes to `prefixes` array, new suffixes to `suffixes` array
- `tag.gd`: Add BLEED_CHANCE, POISON_CHANCE, BURN_CHANCE to StatType enum
- `hero.gd`: May need stat aggregation for new stat types (or defer to Phase 48)
- Disabled stubs (lines 243-255): Remove/replace Cast Speed and Bleed stubs with proper implementations

</code_context>

<specifics>
## Specific Ideas

- DoT affixes are "pre-wired" -- they roll on items and show stats, but the actual DoT tick mechanics are implemented in Phase 48
- Chaos resistance being a separate affix (not in ALL_RESISTANCE) creates meaningful itemization choices
- Generic %DoT prefix benefits any archetype that stacks DoT, rewarding cross-type investment
- Cast speed on SPEED tag means all ring archetypes can boost cast speed, creating hybrid build options

</specifics>

<deferred>
## Deferred Ideas

- Spell dodge / "evasion applies to spells at x% effectiveness" -- new defensive mechanic, needs its own phase
- Damage Suppression suffix -- needs DefenseCalculator integration (listed in REQUIREMENTS.md future)
- Dodge Chance suffix -- needs design decision on interaction with evasion (listed in REQUIREMENTS.md future)

</deferred>

---

*Phase: 45-affix-pool-expansion*
*Context gathered: 2026-03-06*
