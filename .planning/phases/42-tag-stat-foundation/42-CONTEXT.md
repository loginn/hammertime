# Phase 42: Tag & Stat Foundation - Context

**Gathered:** 2026-03-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Add all new Tag and StatType constants needed by v1.8 phases (42-49), with zero functional changes. This is a pure data-layer phase — no game logic, no UI, no behavior changes.

</domain>

<decisions>
## Implementation Decisions

### Archetype Tag Naming
- Use abbreviated names: STR, DEX, INT (matches ARPG convention, consistent with existing short tags like FLAT, DOT, SPEED)
- Tags serve as valid_tags on item bases, controlling which affixes can roll (per BASE-09)
- Mutually exclusive: each item has exactly one archetype tag (hybrids are out of scope)
- Existing items (LightSword, BasicArmor, etc.) do NOT get archetype tags in this phase — that's Phase 44
- INT and SPELL are independent tags — an INT weapon explicitly lists both [INT, SPELL, WEAPON] in valid_tags

### DoT Stat Types
- Add all DoT stat types in Phase 42: BLEED_DAMAGE, POISON_DAMAGE, BURN_DAMAGE
- Rationale: phase goal is "all new constants needed by later phases" — one phase owns all tag.gd changes

### Poison / Chaos Element
- Poison gets a new CHAOS element tag (new constant, analogous to PHYSICAL, FIRE, COLD, LIGHTNING)
- Bleed reuses PHYSICAL tag, Burn reuses FIRE tag, Poison uses new CHAOS tag
- CHAOS_RESISTANCE added to StatType enum (completes resistance set)
- ALL_RESISTANCE remains elemental-only (fire/cold/lightning) — chaos resistance is a separate, harder-to-get stat

### Claude's Discretion
- Ordering/grouping of new constants within tag.gd (logical grouping preferred)
- Whether to add inline comments grouping the constants by purpose

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `autoloads/tag.gd`: All Tag constants (string consts) and StatType enum live here. Single file to modify.

### Established Patterns
- Tag constants are uppercase string consts (e.g., `const PHYSICAL = "PHYSICAL"`)
- StatType is a single flat enum with no nesting or grouping
- No existing archetype or spell-related constants

### Integration Points
- Phase 44 (Item Bases) will use STR/DEX/INT tags in item valid_tags arrays
- Phase 45 (Affix Pool Expansion) will use SPELL tag and spell stat types for new affixes
- Phase 46 (Spell Damage Channel) will use FLAT_SPELL_DAMAGE, INCREASED_SPELL_DAMAGE, INCREASED_CAST_SPEED in StatCalculator
- Phase 48 (DoT) will use BLEED_DAMAGE, POISON_DAMAGE, BURN_DAMAGE and CHAOS tag

</code_context>

<specifics>
## Specific Ideas

- Poison as chaos-typed (inspired by PoE's chaos damage type) gives it distinct identity from elemental damage
- Chaos resistance being separate from ALL_RESISTANCE creates meaningful itemization choices (need dedicated chaos resist suffix)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 42-tag-stat-foundation*
*Context gathered: 2026-03-06*
