# Hero Power Formula

`hero_power = total_dps + defensive_score * DEFENSE_WEIGHT`

---

## Offensive score — `total_dps`

```
total_dps = avg_damage * weapon_speed * crit_multiplier

crit_multiplier = 1 + (crit_chance / 100) * (crit_damage / 100 - 1)
```

`avg_damage` is the average across all active damage elements (physical + elemental).
Flat damage affixes are added first, then `%increased physical` / `%increased elemental` are applied separately per element.
Weapon and ring base damage both contribute.

---

## Defensive score — `defensive_score`

```
effective_hp  = (max_health + total_energy_shield) * (1 + armor / ARMOR_SCALING)
avg_res       = average of (fire_res, cold_res, lightning_res), each capped at RESISTANCE_CAP
res_factor    = 1 + avg_res / 100
evasion_factor = 1 + total_evasion / EVASION_SCALING

defensive_score = effective_hp * res_factor * evasion_factor
```

---

## Tuning constants (`autoloads/balance_config.gd`)

| Constant | Default | Effect |
|---|---|---|
| `ARMOR_SCALING` | 500.0 | Higher = armor contributes less to effective_hp |
| `EVASION_SCALING` | 300.0 | Higher = evasion contributes less |
| `DEFENSE_WEIGHT` | 0.5 | Scales how much defensive_score moves hero_power relative to DPS |
| `RESISTANCE_CAP` | 75 | Max resistance % per element |

`DEFENSE_WEIGHT` is the primary rebalance lever. If defensive builds feel too weak or too strong in expedition timing, adjust this first.

---

## Implementation

- Formula lives in `models/hero.gd` — `get_hero_power()` (line 195)
- Defensive score computed in `calculate_defense()` (line 169)
- Tuning constants in `autoloads/balance_config.gd`
