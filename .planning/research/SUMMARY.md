# Project Research Summary

**Project:** Hammertime
**Domain:** ARPG idle game — hero archetype system
**Researched:** 2026-03-09
**Confidence:** HIGH

## Executive Summary

Hammertime v1.9 adds a hero archetype system to the existing prestige loop. Players pick 1 hero from a 3-card draft (one per STR/DEX/INT archetype) after each prestige, gaining a powerful passive bonus that multiplies a specific damage type. The system creates build identity by making hero choice interact with existing item bases, affixes, and tag hammers — three independent systems whose intersection produces emergent depth without new mechanics. Nine heroes (3 per archetype) cover hit-focused, DoT-focused, and elemental-specialty playstyles.

The recommended approach uses a single flat `HeroArchetype` Resource with a const dictionary registry — no class hierarchy, no external data files, no new autoloads. Archetype bonuses are multiplicative "more" modifiers applied as a final step in `Hero.update_stats()`, after all equipment-based additive stacking. This preserves StatCalculator as a pure gear-math function and keeps CombatEngine archetype-unaware (it reads pre-computed damage ranges that already include the bonus). Save format bumps from v7 to v8 with a non-destructive migration defaulting to null (classless).

Key risks center on damage scaling (multiplicative bonuses can dominate gearing decisions if too large), DoT interaction complexity (three DoT types derive damage differently), and the prestige flow integration (hero selection must block gameplay post-wipe without making `execute_prestige()` async). All risks have concrete prevention strategies identified in research.

## Key Findings

### Recommended Stack

The entire feature is implementable with built-in Godot 4.5 + GDScript. No addons, plugins, or external dependencies required.

- **Data model:** Single `HeroArchetype extends Resource` with flat data fields (id, archetype, subvariant, passive_bonuses dictionary). Follows existing Item/Affix/Currency pattern. No multi-level inheritance.
- **Registry:** Const dictionary on HeroArchetype class containing all 9 hero definitions. Matches existing `PRESTIGE_COSTS`, `ITEM_TIERS_BY_PRESTIGE` patterns — data lives in code, version-controlled.
- **Bonus keys:** String keys for "more" multipliers (e.g., `"fire_damage_more"`), separate from `StatType` enum used for additive affix stacking. Prevents accidental mixing of multiplicative and additive systems.
- **Persistence:** `hero_archetype_id: String` on GameState. Only the ID is saved; bonuses are reconstructed from the registry at load time. Save format v8 with `data.get("hero_archetype_id", "")` migration.
- **Communication:** Two new GameEvents signals: `hero_selection_needed`, `hero_selected`.

### Expected Features

**Must have (table stakes):**
- Archetype selection on prestige (meaningful choice at reset)
- Passive bonuses that visibly change damage math ("more" multipliers)
- Distinct visual identity per archetype (name + color, no sprites needed)
- Re-pick on each prestige (impermanent, encourages experimentation)
- At least 2 subvariants per archetype (within-archetype decision)
- Bonuses that complement existing affix system (not a parallel stat system)

**Should have (competitive):**
- Draft selection (pick 1 from 3 random, one per archetype)
- Build synergy with existing items (Fire Wizard + fire affixes = emergent depth)
- Hero bonus visible in stat panel (separate line showing contribution)
- Hero choice influences optimal item selection (retroactive value for 21 bases)
- DoT hero chance bonus (+20% bleed/poison/burn chance for DoT subvariants)

**Defer (v2+):**
- Prestige-level-gated hero pool (P1 basic, P3+ full roster)
- Hero bonus scaling with prestige level
- Defensive hero variants
- Dual-bonus heroes
- Hero-specific item affixes
- Ascendancy trees (full milestone scope)
- Hero cosmetic effects

### Architecture Approach

**Major components (3 new files, 8 modified):**

| Component | Role |
|-----------|------|
| `models/hero_archetype.gd` (NEW) | Resource: archetype enum, variant data, passive bonuses, `generate_choices()`, `to_dict()`/`from_dict()` |
| `scenes/hero_selection_view.gd/.tscn` (NEW) | 3-card picker overlay shown post-prestige, blocks gameplay until selection |
| `models/hero.gd` | + `archetype` field, `apply_archetype_bonuses()` in `update_stats()` chain |
| `autoloads/game_state.gd` | + `hero_archetype` field (nullable, wiped on prestige) |
| `autoloads/save_manager.gd` | + serialize/restore hero archetype, bump to v8 |
| `autoloads/game_events.gd` | + two new signals |
| `scenes/main_view.gd/.tscn` | + HeroSelectionView overlay integration |

**Key integration points:**
- Bonus injection: `Hero.update_stats()` chain, AFTER equipment aggregation, BEFORE DPS caching. StatCalculator untouched.
- Prestige flow: prestige completes normally, hero_archetype set to null on wipe, MainView detects null and shows selection overlay.
- Combat: CombatEngine reads pre-computed `hero.damage_ranges` (already includes bonus). Zero CombatEngine changes for passive damage bonuses.
- Save: ID-only persistence, registry reconstructs bonuses. Non-destructive v7-to-v8 migration.

### Critical Pitfalls

| # | Pitfall | Severity | Prevention |
|---|---------|----------|------------|
| 1 | **Multiplicative bonus breaks damage scaling** — 100% more doubles output regardless of gear, creating a cliff between matching and non-matching elements | HIGH | Decide additive vs multiplicative in design phase. If multiplicative, test ratio of best-gear+affinity vs best-gear+no-affinity; cap at 2x. Consider smaller values (20-30% more). |
| 2 | **Bonus applied at wrong calculation stage** — double-counting with crit or missing flat damage | HIGH | Apply in Hero after StatCalculator returns, not inside StatCalculator. Integration tests for each element + each damage channel. |
| 3 | **Save migration deletes player progress** — current v7 policy deletes outdated saves | CRITICAL | Add `_migrate_v7_to_v8()` defaulting hero to null. Change delete-on-old-version to migrate-on-old-version. Test v7 save round-trip. |
| 4 | **DoT interaction double-dipping** — burn scales from spell hit (already boosted), separate boost double-counts; poison scales from flat affixes (gets zero benefit) | HIGH | Define explicitly per hero what is boosted (hit, DoT, or both). Test every hero x DoT combination. |
| 5 | **Feel-bad random selection** — player invested in fire gear, offered only cold STR hero | MEDIUM | Consider two-step selection (archetype then subvariant). Or keep bonuses small enough that mismatches feel suboptimal, not ruinous. |

## Implications for Roadmap

### Suggested Phases with Rationale

| Phase | Scope | Rationale |
|-------|-------|-----------|
| **Phase 1: Data Foundation** | `hero_archetype.gd` Resource, `game_events.gd` signals, `game_state.gd` field | Zero-dependency foundation. Everything downstream references these. Can be tested in isolation. |
| **Phase 2: Stat Integration** | `hero.gd` archetype field + `apply_archetype_bonuses()` in update_stats chain | Core mechanic. Must work correctly before UI or save touches it. Unit-testable without UI. |
| **Phase 3: Save & Migration** | `save_manager.gd` v8 format, v7-to-v8 migration, save round-trip tests | Must ship before any player-facing build. Blocks all deployment. |
| **Phase 4: Selection UI** | `hero_selection_view.gd/.tscn`, `main_view` overlay integration | Depends on phases 1-3. Most visible deliverable. Layout at 1280x720 resolution. |
| **Phase 5: Polish & Balance** | Forge view display, DoT verification, balance tuning, integration tests | Final pass. Verify all 9 heroes x all damage channels. UX copy in plain language. |

### Phase Ordering Rationale

Data model first because every other component imports `HeroArchetype`. Stat integration second because it validates the core mechanic (do bonuses actually work?) before investing in UI. Save migration third because it is a hard deployment blocker — shipping v1.9 without migration destroys player saves. UI fourth because it is the most complex new code and benefits from stable underlying systems. Polish last because balance tuning requires all systems operational.

### Research Flags

- **Design decision needed:** Additive vs multiplicative bonus stacking. Research recommends multiplicative ("more") for genre alignment and scaling properties, but pitfalls research warns about element-matching cliffs. Team should decide and document before Phase 2.
- **Design decision needed:** `is_spell_user` authority. Currently weapon-driven (v1.8). Should hero archetype become the authority? Affects CombatEngine timer selection. Resolve before Phase 2.
- **Design decision needed:** P0 experience. Research recommends no hero at P0 (classless "Adventurer"). First selection at P1. Affects Phase 4 UI flow.
- **Deferred investigation:** Hero-weighted item drops. Not in v1.9 scope but flagged as a balance concern if affinity bonuses are large. Revisit after v1.9 ships based on player feedback.

## Confidence Assessment

| Area | Confidence | Basis |
|------|------------|-------|
| Data model (HeroArchetype Resource) | HIGH | Follows 4 existing Resource patterns in codebase. No new concepts. |
| Stat integration (more multiplier) | HIGH | Injection point identified, StatCalculator stays unchanged. PoE/Last Epoch precedent for the math model. |
| Save format migration | HIGH | Clear migration path. Pattern exists in codebase (version check). Risk is in policy change (delete -> migrate). |
| Prestige flow integration | MEDIUM | Synchronous `execute_prestige()` needs post-wipe UI overlay. Pattern exists (prestige fade) but hero selection adds a blocking step. |
| UI layout at 1280x720 | MEDIUM | 3 cards fit horizontally but content density needs prototype validation. No existing multi-card selection pattern in codebase. |
| DoT interaction correctness | MEDIUM | Three DoT types with different derivation formulas. Each hero x DoT combination needs explicit testing. High test surface area. |
| Balance (bonus magnitude) | LOW | No existing endgame data to calibrate against. Multiplicative vs additive decision significantly affects feel. Requires playtesting. |

## Sources

- **Codebase analysis:** hero.gd, stat_calculator.gd, combat_engine.gd, prestige_manager.gd, game_state.gd, save_manager.gd, game_events.gd, tag.gd, loot_table.gd, all 21 item base types
- **PROJECT.md:** v1.9 milestone spec, architecture constraints, key decisions
- **Genre precedent:** PoE 1/2 ascendancies, Last Epoch masteries, Diablo 4 Paragon, Melvor Idle, Realm Grinder factions, NGU Idle classes, Legends of IdleOn subclasses
- **Prior milestone research:** v1.8 stack/pitfalls research (save migration lessons, affix pool patterns)

---
*Research completed: 2026-03-09*
*Ready for roadmap: yes*
