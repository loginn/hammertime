# Phase 13: Defensive Stat Foundation - Context

**Gathered:** 2026-02-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Defensive stats (armor, evasion, resistances, energy shield) reduce incoming damage through ARPG formulas. This phase builds the calculation layer — how each defense type processes damage. Mod/affix restrictions and leech mechanics are future content.

</domain>

<decisions>
## Implementation Decisions

### Defense Scaling Feel
- Armor uses **diminishing returns** formula (PoE-style) — effective against small hits, less effective against large hits
- Armor has a **soft cap via formula** — no hard cap, diminishing returns naturally prevent reaching 100%
- Elemental resistances cap at **75% effective** but **over-capping is allowed** in stats — gear can give >75%, effective is clamped. Future-proofs for resistance penalty mechanics
- All defenses use diminishing returns scaling (armor and evasion both)

### Evasion Model
- **Pure RNG** dodge — each attack independently rolls against evasion chance. No entropy tracking
- Evasion **only dodges attacks, not spells** — packs will be attack-based or spell-based (Phase 14 defines this)
- Spell dodge is a **separate future mod** — not part of this phase's evasion system
- Evasion dodge chance **capped at 75%** (matches resistance cap)
- Evasion uses **diminishing returns** scaling like armor

### Energy Shield Behavior
- ES is NOT blue life — it has a distinct identity as the **only leechable defense** (no life leech exists in the game)
- **50% bypass model**: incoming damage (after armor/resistances) splits — 50% to ES, 50% directly to life
- Future mods can reduce bypass (e.g., "Max ES bypass +10%" means only 40% bypasses to life)
- ES **recharges 33% of max ES between pack fights** (fixed percentage)
- Recharge rate is a future mod opportunity
- Damage reduction order: armor/resistances apply first, THEN remaining damage splits to ES/life — ES benefits from all other defenses

### Defense Layering
- Defense application order: **Evasion → Resistances → Armor → ES/Life split**
  1. Evasion: dodge check (attacks only, not spells)
  2. Resistances: reduce elemental damage portion
  3. Armor: reduce physical damage portion (physical only, not elemental)
  4. Remaining damage splits 50/50 to ES and life
- **Clear defense gaps**: evasion doesn't dodge spells, armor doesn't reduce elemental. Elemental spells bypass both — only resistances protect
- Defense types are **gear-limited**: armor bases roll armor mods, mage robes roll ES mods. No cross-type defense mods on single-type bases
- Hybrid gear bases planned for the future
- Calculation layer supports all defenses coexisting — gear system limits practical combinations
- **Zero base defense** — naked hero has no armor, evasion, or ES. All defense comes from equipment

### Claude's Discretion
- Specific diminishing returns formula constants (tuning)
- When defenses feel impactful in area progression (early vs late scaling)
- ES recharge timing implementation details
- Defense calculation code architecture

</decisions>

<specifics>
## Specific Ideas

- "No lifesteal, only energy shield leech" — ES leech as the only sustain mechanic is a core game identity decision
- Gear base types restrict available defense mods (armor body armor can't roll flat evasion, mage robe can't roll armor)
- Pack damage types (attack vs spell, physical vs elemental) will be defined in Phase 14 but the defense system must support both paths
- 50% ES bypass as a base value with mod-driven customization mirrors the resistance over-cap philosophy — base value with room to push

</specifics>

<deferred>
## Deferred Ideas

- Spell dodge chance mod — future affix content
- ES leech mechanic — future mod/affix phase
- ES bypass reduction mods ("Max ES bypass +10%") — future affix content
- ES recharge rate mods — future affix content
- Hybrid gear bases (armor+evasion, armor+ES) — future gear content
- Visual prefix/suffix separation in UI — already in v1.3+ backlog

</deferred>

---

*Phase: 13-defensive-stat-foundation*
*Context gathered: 2026-02-16*
