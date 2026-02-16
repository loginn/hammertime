---
phase: 15-pack-based-combat-loop
status: passed
verified: 2026-02-16
score: 5/5
---

# Phase 15: Pack-Based Combat Loop - Verification

**Phase Goal:** Hero fights monster packs sequentially in idle auto-combat where both hero and packs can die

## Must-Have Verification

### 1. Hero automatically attacks the current pack and pack attacks hero back each combat tick
**Status:** PASSED
**Evidence:**
- `models/combat/combat_engine.gd:67` - `_on_hero_attack()` fires on hero timer, deals `total_dps / hero_attack_speed` damage with per-hit crit roll
- `models/combat/combat_engine.gd:93` - `_on_pack_attack()` fires on pack timer, routes through `DefenseCalculator.calculate_damage_taken()` with pack's element type
- `models/combat/combat_engine.gd:58-63` - `_start_pack_fight()` starts both timers with independent cadences (hero from weapon speed, pack from MonsterType speed)
- Timers are repeating (`one_shot = false`) for continuous combat

### 2. When pack HP reaches 0, hero moves to the next pack
**Status:** PASSED
**Evidence:**
- `models/combat/combat_engine.gd:88-89` - After `pack.take_damage()`, checks `not pack.is_alive()` and calls `_on_pack_killed()`
- `models/combat/combat_engine.gd:127-139` - `_on_pack_killed()` stops timers, increments `current_pack_index`, recharges ES 33%, starts next fight immediately
- `scenes/gameplay_view.gd:140-143` - Display shows "Pack X of Y" for progress tracking

### 3. When hero HP reaches 0, combat stops and hero is marked as dead
**Status:** PASSED
**Evidence:**
- `models/combat/combat_engine.gd:122-123` - After `hero.apply_damage()`, checks `not hero.is_healthy()` and calls `_on_hero_died()`
- `models/combat/combat_engine.gd:157-159` - `_on_hero_died()` sets `state = State.HERO_DEAD`, stops both timers
- `models/hero.gd:39-41` - `die()` sets `is_alive = false`

### 4. After hero dies, hero can revive and start a new map run
**Status:** PASSED
**Evidence:**
- `models/combat/combat_engine.gd:160` - Calls `GameState.hero.revive()` which restores full HP + ES
- `models/combat/combat_engine.gd:163-164` - With `auto_retry = true` (default), calls `start_combat(area_level)` for fresh map attempt
- `models/combat/combat_engine.gd:162` - Hero stays at same area level (no regression)
- `models/hero.gd:58-62` - `revive()` restores `health = max_health` and `current_energy_shield = total_energy_shield`

### 5. When all packs in a map are cleared, hero advances to the next map
**Status:** PASSED
**Evidence:**
- `models/combat/combat_engine.gd:132-134` - When `current_pack_index >= current_packs.size()`, calls `_on_map_completed()`
- `models/combat/combat_engine.gd:143-153` - `_on_map_completed()`: full ES recharge, `area_level += 1` (deterministic), auto-starts next map via `start_combat(area_level)`
- `scenes/gameplay_view.gd:88-105` - Map completion triggers area_cleared signal, item drops, and currency drops

## Requirements Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| COMBAT-01: Sequential idle auto-combat | PASSED | CombatEngine state machine + dual timers |
| COMBAT-02: Hero/pack exchange each tick | PASSED | Independent _on_hero_attack/_on_pack_attack |
| COMBAT-03: Hero can die (HP 0) | PASSED | _on_hero_died stops combat, sets HERO_DEAD |
| COMBAT-05: Hero revives for new map | PASSED | hero.revive() + start_combat auto-retry |
| COMBAT-06: All packs cleared advances | PASSED | _on_map_completed increments area_level |

## Additional Verifications

- **Independent attack timers:** Hero timer uses `weapon.base_attack_speed`, pack timer uses `pack.attack_speed` -- different cadences confirmed
- **DefenseCalculator integration:** Pack damage routes through full 4-stage pipeline with `pack.element` for correct damage type
- **ES mechanics:** 33% recharge between packs (`recharge_energy_shield()`), full recharge between maps
- **No HP regen between packs:** Confirmed -- no regen code, life damage permanent within map run
- **Deterministic progression:** `area_level += 1` on map clear, no RNG
- **GameEvents signals:** All 7 combat signals emitted and connected in gameplay_view
- **Old system removed:** No references to ClearingTimer, clearing_timer, hero_clearing, area_difficulty_multiplier remain

## Score: 5/5 must-haves passed

---
*Verified: 2026-02-16*
