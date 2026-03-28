# Phase 56: Difficulty & Starter Kit - Context

**Gathered:** 2026-03-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Fresh P0 heroes can engage with the crafting loop from zone 1 — starter items in stash, starter hammers, and tuned Forest difficulty. Also includes renaming all 6 currency keys to PoE conventions.

</domain>

<decisions>
## Implementation Decisions

### Starter Item Selection
- **D-01:** Starter weapon is archetype-matched: Broadsword for STR, Dagger for DEX, Wand for INT
- **D-02:** Starter armor is archetype-matched: IronPlate for STR, LeatherVest for DEX, SilkRobe for INT
- **D-03:** Starter items are Normal rarity (blank bases, no affixes). Player must use starter hammers to add mods — teaches the crafting loop

### Starter Hammer Loadout
- **D-04:** Fresh game starts with 2 Transmute (was "runic") + 2 Augment (was "forge"), replacing the old 1 Runic starter
- **D-05:** Currency key rename (folded into this phase): runic→transmute, forge→augment, tack→alteration, grand→regal, claw→chaos, tuning→exalt. All references in code (currency_counts keys, UI labels, save compat) must be updated

### Forest Difficulty Tuning
- **D-06:** Tune Forest monster base_hp and base_damage values directly (not growth rate or curve changes)
- **D-07:** Survival target: fresh P0 hero with blank Normal starter weapon + armor should survive zone 1 only. Must craft by zone 2

### Prestige Restart Behavior
- **D-08:** Prestige resets grant the same starter kit as fresh new games (archetype-matched weapon + armor in stash, 2 Transmute + 2 Augment)
- **D-09:** Starter items placed AFTER archetype re-selection — player picks archetype first (Phase 53 overlay), then matching starter items appear in stash. Requires hooking into the archetype selection callback

### Claude's Discretion
- Exact Forest monster base_hp/base_damage numbers (researcher should analyze current values vs hero blank-weapon DPS to find the right balance for zone 1 survival)
- Implementation details for the currency rename (how to handle save format v8 compatibility)
- Which function places starter items — could be in `initialize_fresh_game()`, `_wipe_run_state()`, or a new dedicated function called after archetype selection

### Folded Todos
- **Rebalance early progression difficulty curve** — Game scales too hard too early. Addressed by D-06/D-07 (Forest monster stat tuning for zone 1 survivability with blank starter gear)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

No external specs — requirements fully captured in decisions above and these source files:

### Game state and initialization
- `autoloads/game_state.gd` — `initialize_fresh_game()` (line 90), `_wipe_run_state()` (line 128), `currency_counts` dict (line 100), `_init_stash()` (line 79)

### Monster difficulty
- `models/monsters/pack_generator.gd` — `GROWTH_RATE`, `BIOME_BOUNDARIES`, `get_level_multiplier()`, Forest avg HP comment (line 15: 27.0)
- `models/monsters/monster_pack.gd` — `base_hp`, `base_damage`, `difficulty_bonus`

### Item models (starter items)
- `models/items/broadsword.gd` — STR starter weapon
- `models/items/dagger.gd` — DEX starter weapon
- `models/items/wand.gd` — INT starter weapon
- `models/items/iron_plate.gd` — STR starter armor
- `models/items/leather_vest.gd` — DEX starter armor
- `models/items/silk_robe.gd` — INT starter armor

### Archetype selection (timing for starter kit placement)
- `scenes/main_view.gd` — Archetype selection overlay (Phase 53)
- `autoloads/prestige_manager.gd` — `execute_prestige()` wipe sequence

### Requirements
- `.planning/REQUIREMENTS.md` — DIFF-01, DIFF-03

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `GameState._init_stash()` — Creates empty stash dict, can be extended to pre-populate with starter items
- `GameState.add_item_to_stash()` — Existing function to add items to stash slots
- `GameState.currency_counts` dict — All 6 currency keys defined in `initialize_fresh_game()` and `_wipe_run_state()`

### Established Patterns
- Item instantiation: `Broadsword.new(tier)` with tier parameter for item quality
- Currency keys are plain strings in a Dictionary, referenced throughout UI and save code
- `_wipe_run_state()` mirrors `initialize_fresh_game()` for prestige resets

### Integration Points
- Archetype selection callback in `main_view.gd` — starter items must be placed after archetype is confirmed
- `SaveManager` — currency key rename needs v8→v9 migration mapping (but save v9 is Phase 58 scope — may need coordination)
- All UI files referencing currency keys by string ("runic", "forge", etc.) need updating

</code_context>

<specifics>
## Specific Ideas

- Currency names should follow PoE orb conventions: Transmute, Augment, Alteration, Regal, Chaos, Exalt
- The user reasons about currencies using PoE terminology, so code should match for clarity

</specifics>

<deferred>
## Deferred Ideas

- Large number formatting with suffix notation (K/M/B) — separate todo, not related to difficulty
- Item drop filter for unwanted loot — future prestige feature
- Prestige-scaled starter kit (better items at higher prestige) — future enhancement
- Smart discard policy (keep higher tier on overflow) — future prestige unlock

### Reviewed Todos (not folded)
- **Add large number formatting with suffix notation** — UI concern, not related to difficulty or starter kit
- **Add item drop filter for unwanted loot** — Future feature, out of scope
- **Add a save slot for WIP item** — Crafting workflow, not starter kit related

</deferred>

---

*Phase: 56-difficulty-starter-kit*
*Context gathered: 2026-03-28*
