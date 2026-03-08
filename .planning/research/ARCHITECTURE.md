# Architecture Research

**Domain:** ARPG idle game -- hero archetype integration with prestige-based selection
**Researched:** 2026-03-09
**Confidence:** HIGH (based on direct codebase analysis of Hero, StatCalculator, PrestigeManager, GameState, SaveManager, CombatEngine, and all 21 item base types)

---

## System Overview

```
                          PRESTIGE FLOW
                          =============
  PrestigeView                PrestigeManager              GameState
  [Upgrade Forge] ──press──> execute_prestige() ────────> _wipe_run_state()
        │                         │                            │
        │                         │  (NEW) Before wipe:        │  (NEW) After wipe:
        │                         │  ┌─────────────────────┐   │  ┌──────────────────┐
        │                         │  │ Store prestige_level │   │  │ hero_archetype   │
        │                         │  └─────────────────────┘   │  │   = null (cleared)│
        │                         │                            │  └──────────────────┘
        │                         ▼                            │
        │              GameEvents.prestige_completed ───────────┤
        │                         │                            │
        │              (NEW) GameEvents.hero_selection_needed ──┤
        │                         │                            │
        ▼                         ▼                            ▼
  ┌─────────────────────────────────────────────────────────────────┐
  │                    HERO SELECTION FLOW (NEW)                     │
  │                                                                 │
  │  HeroSelectionView (new scene)                                  │
  │  ┌─────────────────────────────────────────────────────────┐    │
  │  │ 1. HeroArchetype.generate_choices() -> [STR, DEX, INT] │    │
  │  │ 2. Display 3 cards with name + passive description      │    │
  │  │ 3. Player picks one                                     │    │
  │  │ 4. GameState.hero_archetype = chosen                    │    │
  │  │ 5. hero.apply_archetype(chosen)                         │    │
  │  │ 6. GameEvents.hero_selected.emit(chosen)                │    │
  │  │ 7. SaveManager auto-saves                               │    │
  │  └─────────────────────────────────────────────────────────┘    │
  └─────────────────────────────────────────────────────────────────┘

                          COMBAT FLOW
                          ===========
  CombatEngine._on_hero_attack()
        │
        ▼
  Roll per-element damage from hero.damage_ranges
        │
        ▼
  (NEW) Apply hero archetype passive bonus
        │  hero.archetype_damage_multipliers[element] -> "more" multiplier
        │  Multiplied AFTER all additive stacking (final multiplicative layer)
        │
        ▼
  Per-hit crit roll -> pack.take_damage()


                     STAT CALCULATION FLOW
                     =====================
  Hero.update_stats()
        │
        ├── calculate_crit_stats()
        ├── calculate_damage_ranges()      ◄── StatCalculator.calculate_damage_range()
        ├── (NEW) apply_archetype_bonuses() ◄── HeroArchetype.passive_bonuses
        ├── calculate_dps()                 ◄── Uses post-bonus damage_ranges
        ├── calculate_spell_damage_ranges()
        ├── (NEW) apply_archetype_spell_bonuses()
        ├── calculate_spell_dps()
        ├── calculate_defense()
        └── calculate_dot_stats()
```

## Component Responsibilities

| Component | Current Role | New Role (v1.9) |
|-----------|-------------|-----------------|
| `HeroArchetype` | Does not exist | NEW Resource: archetype identity, subvariant name, passive bonus definitions |
| `HeroSelectionView` | Does not exist | NEW Scene: 3-card hero picker shown after prestige or first game |
| `Hero` | Equipment, stats, combat state | + `archetype` field, `apply_archetype_bonuses()`, archetype-aware damage multipliers |
| `StatCalculator` | DPS/defense math with flat+% stacking | + `apply_more_multiplier()` static method for "more" (multiplicative) bonuses |
| `PrestigeManager` | Prestige levels, currency cost, run wipe | + Emit hero_selection_needed signal, gate hero selection on prestige |
| `GameState` | Hero instance, area, currencies | + `hero_archetype` field (nullable, persisted), starter weapon tied to archetype |
| `SaveManager` | JSON save/load v7 | + Serialize/restore hero_archetype (bump to v8) |
| `GameEvents` | Signal bus | + `hero_selection_needed`, `hero_selected` signals |
| `MainView` | Tab navigation, prestige fade | + Show HeroSelectionView overlay after prestige fade |
| `ForgeView` | Equipment + crafting | No changes (archetype bonus shown in hero stats panel via existing update_stats) |
| `CombatEngine` | Dual timer combat | + Apply archetype multipliers to per-hit damage |
| `LootTable` | Item drops, tier rolling | + Starter weapon selection by archetype |

---

## Recommended Project Structure

### New Files

```
models/hero_archetype.gd          # HeroArchetype Resource (class_name HeroArchetype)
scenes/hero_selection_view.gd      # Hero picker UI logic
scenes/hero_selection_view.tscn    # Hero picker scene (3-card layout)
```

### Modified Files

```
models/hero.gd                     # + archetype field, apply_archetype_bonuses()
models/stats/stat_calculator.gd    # + apply_more_multiplier() static method
autoloads/game_state.gd            # + hero_archetype field, archetype-aware wipe/init
autoloads/game_events.gd           # + hero_selection_needed, hero_selected signals
autoloads/prestige_manager.gd      # + trigger hero selection after wipe
autoloads/save_manager.gd          # + save/load hero_archetype, bump to v8
scenes/main_view.gd                # + HeroSelectionView integration, post-prestige flow
scenes/main_view.tscn              # + HeroSelectionView node in scene tree
```

---

## Architectural Patterns

### Pattern 1: Resource-Based Archetype Data (follows existing Item/Affix/Hero pattern)

HeroArchetype extends Resource, holding all archetype identity and passive bonus data as pure data. No scene tree dependency, serializable, reference-counted.

```gdscript
class_name HeroArchetype extends Resource

enum Archetype { STR, DEX, INT }

var archetype: Archetype
var variant_name: String          # "Fire Wizard", "Frost Warrior", etc.
var display_name: String          # Shown in UI
var passive_description: String   # "100% more fire damage"
var passive_bonuses: Dictionary   # {"fire": 1.0, "spell_fire": 1.0} = 100% more

# All possible subvariants, grouped by archetype
const VARIANTS: Dictionary = {
    Archetype.STR: [
        {"name": "Berserker",       "desc": "100% more physical damage",
         "bonuses": {"physical": 1.0}},
        {"name": "Frost Warrior",   "desc": "100% more cold damage",
         "bonuses": {"cold": 1.0}},
        {"name": "Warlord",         "desc": "50% more bleed damage, 50% more physical damage",
         "bonuses": {"physical": 0.5, "bleed": 0.5}},
    ],
    Archetype.DEX: [
        {"name": "Assassin",        "desc": "100% more poison damage",
         "bonuses": {"poison": 1.0}},
        {"name": "Storm Archer",    "desc": "100% more lightning damage",
         "bonuses": {"lightning": 1.0}},
        {"name": "Shadow Blade",    "desc": "50% more physical damage, 50% more crit damage",
         "bonuses": {"physical": 0.5, "crit_damage": 0.5}},
    ],
    Archetype.INT: [
        {"name": "Fire Wizard",     "desc": "100% more fire spell damage",
         "bonuses": {"spell_fire": 1.0, "burn": 0.5}},
        {"name": "Storm Mage",      "desc": "100% more lightning spell damage",
         "bonuses": {"spell_lightning": 1.0}},
        {"name": "Warlock",         "desc": "100% more spell damage",
         "bonuses": {"spell": 0.5, "burn": 0.5}},
    ],
}

static func generate_choices() -> Array[HeroArchetype]:
    var choices: Array[HeroArchetype] = []
    for arch in [Archetype.STR, Archetype.DEX, Archetype.INT]:
        var variants: Array = VARIANTS[arch]
        var picked: Dictionary = variants.pick_random()
        var ha := HeroArchetype.new()
        ha.archetype = arch
        ha.variant_name = picked["name"]
        ha.display_name = picked["name"]
        ha.passive_description = picked["desc"]
        ha.passive_bonuses = picked["bonuses"]
        choices.append(ha)
    return choices

func to_dict() -> Dictionary:
    return {
        "archetype": int(archetype),
        "variant_name": variant_name,
        "display_name": display_name,
        "passive_description": passive_description,
        "passive_bonuses": passive_bonuses,
    }

static func from_dict(data: Dictionary) -> HeroArchetype:
    var ha := HeroArchetype.new()
    ha.archetype = data.get("archetype", 0) as Archetype
    ha.variant_name = str(data.get("variant_name", ""))
    ha.display_name = str(data.get("display_name", ""))
    ha.passive_description = str(data.get("passive_description", ""))
    ha.passive_bonuses = data.get("passive_bonuses", {})
    return ha
```

**Why this pattern:** Matches every other data class in the project (Item, Affix, Hero, MonsterType). Serializable via to_dict/from_dict for SaveManager. No scene tree coupling.

### Pattern 2: "More" Multiplier as Final Multiplicative Layer (follows PoE convention)

Existing StatCalculator uses additive stacking for "increased" modifiers: `base * (1.0 + sum_of_pct)`. Hero archetype bonuses use "more" multipliers: `damage * (1.0 + more_pct)`, applied AFTER all additive stacking. This is a separate multiplication step, not added to the additive pool.

```gdscript
# In Hero.apply_archetype_bonuses():
func apply_archetype_bonuses() -> void:
    if archetype == null:
        return
    for element in damage_ranges:
        if element in archetype.passive_bonuses:
            var more_mult := 1.0 + archetype.passive_bonuses[element]
            damage_ranges[element]["min"] *= more_mult
            damage_ranges[element]["max"] *= more_mult
```

**Why this pattern:** "More" vs "increased" is the standard ARPG damage layering. Additive stacking (existing affixes) has diminishing returns. Multiplicative "more" (archetype passive) is always impactful. This makes hero choice always meaningful regardless of gear quality.

### Pattern 3: Signal-Gated UI Overlay (follows prestige_triggered pattern)

Hero selection uses the same pattern as prestige: a signal triggers a UI overlay that blocks normal gameplay until the player makes a choice. MainView coordinates the overlay visibility.

```
PrestigeManager.execute_prestige()
  -> GameEvents.prestige_completed.emit()
  -> MainView._on_prestige_triggered()
    -> Fade to black
    -> Scene reload
    -> GameState detects hero_archetype == null
    -> GameEvents.hero_selection_needed.emit()
    -> MainView shows HeroSelectionView overlay
    -> Player picks hero
    -> GameEvents.hero_selected.emit()
    -> MainView hides overlay, shows forge
```

**Why this pattern:** Matches existing prestige flow. No modal dialog system needed. Overlay blocks tab navigation naturally.

---

## Data Flow

### Hero Selection Flow (prestige -> selection -> apply bonuses)

```
1. Player clicks "Upgrade Forge" (prestige_view.gd)
2. PrestigeManager.execute_prestige()
   a. Advance prestige_level
   b. GameState._wipe_run_state()  -- hero_archetype set to null
   c. GameEvents.prestige_completed.emit()
3. MainView._on_prestige_triggered()
   a. Fade to black
   b. Scene reload (get_tree().reload_current_scene())
4. GameState._ready() -> initialize_fresh_game()
   a. hero_archetype = null (fresh state)
   b. SaveManager.load_game() restores prestige_level but hero_archetype is null
5. MainView._ready()
   a. Detects GameState.hero_archetype == null AND GameState.prestige_level > 0
      (OR first game ever at P0 -- design choice)
   b. Emits GameEvents.hero_selection_needed
   c. Shows HeroSelectionView overlay
6. HeroSelectionView._ready()
   a. choices = HeroArchetype.generate_choices()  -- 1 STR, 1 DEX, 1 INT
   b. Displays 3 cards with variant_name + passive_description
7. Player taps a card
   a. GameState.hero_archetype = chosen
   b. Hero applies archetype: GameState.hero.archetype = chosen
   c. GameState.hero.update_stats()  -- recalculates with archetype bonuses
   d. Starter weapon set based on archetype:
      STR -> Broadsword, DEX -> Dagger, INT -> Wand
   e. GameState.crafting_inventory["weapon"] = archetype_starter_weapon
   f. GameEvents.hero_selected.emit(chosen)
   g. SaveManager auto-saves
8. MainView hides overlay, shows forge view
```

### Passive Bonus Application Flow (hero bonus -> StatCalculator -> combat)

```
Hero.update_stats() call chain:
  1. calculate_crit_stats()        -- base 5% + equipment
  2. calculate_damage_ranges()     -- weapon base + flat affixes + % increased
  3. apply_archetype_bonuses()     -- NEW: "more" multiplier on damage_ranges
     For each element with a bonus:
       damage_ranges[element]["min"] *= (1.0 + bonus)
       damage_ranges[element]["max"] *= (1.0 + bonus)
  4. calculate_dps()               -- uses post-bonus ranges for DPS display
  5. calculate_spell_damage_ranges()
  6. apply_archetype_spell_bonuses() -- NEW: "more" multiplier on spell_damage_ranges
  7. calculate_spell_dps()
  8. calculate_defense()
  9. calculate_dot_stats()         -- NEW: apply DoT bonuses (bleed/poison/burn "more")

CombatEngine per-hit flow (UNCHANGED):
  - Reads hero.damage_ranges (already includes archetype bonus)
  - Rolls per-element, applies crit
  - No CombatEngine changes needed for passive damage bonuses

DPS Display (ForgeView hero stats panel):
  - Reads hero.total_dps (already includes archetype bonus via calculate_dps)
  - No ForgeView changes needed for damage display
  - NEW: Show archetype name + passive below hero name
```

---

## Integration Points

### Modified Components

| File | Change | Complexity | Dependencies |
|------|--------|------------|--------------|
| `models/hero.gd` | Add `archetype: HeroArchetype` field, `apply_archetype_bonuses()`, `apply_archetype_spell_bonuses()` in update_stats() chain | Medium | HeroArchetype resource |
| `autoloads/game_state.gd` | Add `hero_archetype: HeroArchetype` field, null on fresh/wipe, archetype-aware starter weapon in `_wipe_run_state()` | Low | HeroArchetype resource |
| `autoloads/game_events.gd` | Add `hero_selection_needed` and `hero_selected(archetype: HeroArchetype)` signals | Trivial | None |
| `autoloads/prestige_manager.gd` | No code change needed (hero_archetype nulled by _wipe_run_state) | None | GameState wipe handles it |
| `autoloads/save_manager.gd` | Serialize hero_archetype in `_build_save_data()`, restore in `_restore_state()`, bump SAVE_VERSION to 8 | Low | HeroArchetype.to_dict/from_dict |
| `scenes/main_view.gd` | Show HeroSelectionView after scene reload when hero_archetype is null, connect hero_selected signal | Medium | HeroSelectionView scene |
| `scenes/main_view.tscn` | Add HeroSelectionView node to scene tree | Low | hero_selection_view.tscn |
| `scenes/forge_view.gd` | Display archetype name + passive in hero stats panel | Low | GameState.hero_archetype |

### New Components

| File | Purpose | Complexity | Dependencies |
|------|---------|------------|--------------|
| `models/hero_archetype.gd` | HeroArchetype Resource: archetype enum, variant data, passive bonuses, generate_choices(), to_dict/from_dict | Medium | Tag constants for element keys |
| `scenes/hero_selection_view.gd` | 3-card picker UI: generate choices, display cards, handle selection, emit signal | Medium | HeroArchetype, GameState, GameEvents |
| `scenes/hero_selection_view.tscn` | Scene layout: 3 card panels with labels, centered overlay | Low | hero_selection_view.gd |

---

## Anti-Patterns

### 1. DO NOT bake archetype bonuses into StatCalculator's additive pool

**Wrong:** Adding archetype bonus to the `additive_damage_mult` sum in StatCalculator.calculate_damage_range().
**Why wrong:** Archetype bonuses are "more" (multiplicative), not "increased" (additive). Mixing them into the additive pool makes them subject to diminishing returns and breaks the ARPG damage layering convention. A 100% more bonus should always double damage, regardless of how much "increased" the player has stacked.
**Correct:** Apply as a separate multiplicative step after all additive stacking, in Hero.apply_archetype_bonuses().

### 2. DO NOT store archetype choice in PrestigeManager

**Wrong:** Adding hero_archetype field to PrestigeManager alongside prestige_level.
**Why wrong:** PrestigeManager is a stateless utility (all state lives in GameState). Archetype is run-scoped state that gets wiped on prestige, same as hero equipment and currencies.
**Correct:** Store on GameState (run-scoped, wiped by _wipe_run_state). PrestigeManager stays pure logic.

### 3. DO NOT modify CombatEngine to apply archetype bonuses per-hit

**Wrong:** Adding archetype multiplier application inside CombatEngine._on_hero_attack().
**Why wrong:** CombatEngine reads pre-computed hero.damage_ranges. If archetype bonuses are already baked into those ranges during update_stats(), CombatEngine needs zero changes. Adding per-hit application would either double-count or require CombatEngine to know about archetypes (coupling).
**Correct:** Apply bonuses in Hero.update_stats() chain so damage_ranges already reflect the "more" multiplier. CombatEngine stays archetype-unaware.

### 4. DO NOT create a separate HeroClass + HeroArchetype two-level hierarchy

**Wrong:** Creating both a HeroClass resource (STR/DEX/INT) and a HeroArchetype resource (Fire Wizard, etc.) with a parent-child relationship.
**Why wrong:** Over-engineering for 9 variants. The archetype enum on HeroArchetype already captures the STR/DEX/INT grouping. A two-level hierarchy adds indirection without value.
**Correct:** Single HeroArchetype resource with an `archetype` enum field for the STR/DEX/INT grouping.

### 5. DO NOT show hero selection at P0 first game

**Wrong:** Forcing hero selection on brand new players who have never played.
**Why wrong:** New players should experience the crafting loop first. Hero selection is a prestige reward that adds replayability. Showing it at P0 adds decision complexity before the player understands what damage types even mean.
**Correct:** P0 starts with a default "Adventurer" (no archetype, no passive bonus). First hero selection appears after first prestige (P1+). The archetype is the prestige reward that makes each run feel different.

---

## Build Order

The suggested implementation order respects dependency chains:

| Phase | Component | Rationale |
|-------|-----------|-----------|
| 1 | `models/hero_archetype.gd` | Foundation data class, no dependencies. Must exist before anything else can reference it. |
| 2 | `autoloads/game_events.gd` + `autoloads/game_state.gd` | Add signals and hero_archetype field. Low risk, enables all downstream work. |
| 3 | `models/hero.gd` | Add archetype field and apply_archetype_bonuses() in update_stats(). Depends on HeroArchetype existing. |
| 4 | `autoloads/save_manager.gd` | Serialize/restore hero_archetype. Depends on HeroArchetype.to_dict/from_dict and GameState.hero_archetype. Bump save version. |
| 5 | `scenes/hero_selection_view.gd` + `.tscn` | UI for picking hero. Depends on HeroArchetype.generate_choices(), GameState, GameEvents. |
| 6 | `scenes/main_view.gd` + `.tscn` | Wire HeroSelectionView into post-prestige flow. Depends on everything above. |
| 7 | `scenes/forge_view.gd` | Display archetype name/passive in hero stats panel. Polish step, no blockers. |
| 8 | Integration tests | Verify prestige->selection->save round-trip, archetype bonus math, P0 default behavior. |

---

## Sources

- Direct codebase analysis of all files listed in Modified/New Components tables
- `/mnt/c/Users/vince/Documents/GitHub/hammertime/.planning/PROJECT.md` -- v1.9 milestone definition
- Existing architectural patterns: Resource-based data model, signal bus, template method currency, prestige fade flow
- PoE damage layering conventions: "increased" (additive) vs "more" (multiplicative) as standard ARPG pattern

---
*Architecture research for: hero archetype integration*
*Researched: 2026-03-09*
