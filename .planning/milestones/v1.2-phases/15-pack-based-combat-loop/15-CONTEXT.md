# Phase 15: Pack-Based Combat Loop - Context

**Gathered:** 2026-02-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Hero fights monster packs sequentially in idle auto-combat. Both hero and packs can die. Replaces the current time-based area clearing with pack-by-pack combat using Phase 14's MonsterPack data model and Phase 13's defensive calculations. Drop system changes are Phase 16. UI/combat feedback details are Phase 17.

</domain>

<decisions>
## Implementation Decisions

### Combat pacing
- Medium tick speed (~0.5s base) — each hit feels distinct but combat moves quickly
- Independent attack timers for hero and pack — each operates on their own attack_speed, not a shared tick
- Hero attack speed comes from weapon type (swords faster, hammers slower) — new stat on weapon bases
- Crit events should be tracked and emitted by the combat engine (even if visual treatment is Phase 17)

### Death & revival
- Death resets the current map — packs re-roll, progress lost
- Currency earned from killed packs is kept through death (Phase 16 implements the actual drop mechanics)
- Items only drop on full map completion, not per-pack (Phase 16 scope but informs combat loop design)
- Hero stays at the same area level after death — retry until cleared or gear up
- Revival restores full HP and full ES — clean slate for each map attempt

### Pack transitions
- Instant transition between packs — no pause, continuous combat flow
- ES recharges 33% of max between each pack (existing behavior preserved)
- Full ES recharge between maps (after all packs cleared)
- No base HP regen between packs — life damage is permanent within a map run
- Life regen from gear mods deferred to future phase

### Map flow
- Auto-advance after map completion — hero immediately starts next map
- Always advance area level on map clear (current_level + 1, not max_unlocked + 1) — deterministic progression replacing 10% RNG
- Player can choose to run any unlocked area level (engine supports level selection, UI is Phase 17)
- After death: toggle for auto-retry vs pause — player decides whether to immediately retry or stop
- Packs re-roll fresh on each map attempt (death or new map)
- Biome determined automatically by area level using BiomeConfig level ranges

### Claude's Discretion
- Exact combat tick implementation (Godot Timer vs _process delta accumulation)
- How to structure the CombatManager/combat loop architecture
- Default weapon attack speed values for existing weapon types
- Auto-retry toggle default state (on or off)

</decisions>

<specifics>
## Specific Ideas

- Combat should feel like watching an idle ARPG — continuous flow with visible exchanges, not a progress bar
- The "wall" experience: push levels until you die, gear up, push further — this is the core loop
- Weapon-based attack speed adds meaningful weapon variety beyond just DPS numbers
- ES as a map-level resource that slowly depletes across packs creates tension over the run

</specifics>

<deferred>
## Deferred Ideas

- Life regen gear mods — future affix/implicit addition
- Area level selection UI — Phase 17 scope
- Visual crit treatment — Phase 17 scope
- Drop mechanics (currency on kill, items on clear) — Phase 16 scope

</deferred>

---

*Phase: 15-pack-based-combat-loop*
*Context gathered: 2026-02-16*
