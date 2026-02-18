---
phase: 22-balance-polish
status: complete
updated: 2026-02-18
---

# Phase 22: Balance & Polish - Context

## Phase Goal
Fresh heroes can survive level 1 content and UI provides polished feedback.

## Requirements
- BAL-01: Starter gear (1 Runic Hammer + 1 weapon base item at new game)
- BAL-02: Level 1 difficulty tuning (fresh hero survives 3+ packs)
- UI-01: Stat panel text fits viewport without overflow

## Decisions

### 1. Starter Gear (BAL-01)

**Decision:** On fresh game start, grant 1 Runic Hammer and have the weapon crafting slot pre-populated with a LightSword base item (already happens via forge_view.gd starting items). The Runic Hammer is the key addition -- it lets the player immediately craft their weapon from Normal to Magic rarity.

**Where to add:** `GameState.initialize_fresh_game()` should set `currency_counts["runic"] = 1` instead of 0. No other starter items needed -- the ForgeView already creates a LightSword, BasicHelmet, BasicArmor, BasicBoots, and BasicRing as starting crafting inventory when no saved items exist.

**Rationale:** The requirement says "1 Runic Hammer and 1 weapon base item." The weapon base is already granted. Adding 1 Runic Hammer to starting currency is the minimal change that satisfies BAL-01 and lets players immediately craft their first magic weapon to start pushing content.

### 2. Level 1 Difficulty Reduction (BAL-02)

**Decision:** Reduce Forest biome (level 1) monster base stats by 40% across the board. This means:
- Forest Bear: 120 HP / 12 dmg -> 72 HP / 7.2 dmg
- Timber Wolf: 80 HP / 10 dmg -> 48 HP / 6.0 dmg
- Wild Boar: 100 HP / 14 dmg -> 60 HP / 8.4 dmg
- Venomous Spider: 50 HP / 11 dmg -> 30 HP / 6.6 dmg
- Forest Sprite: 40 HP / 8 dmg -> 24 HP / 4.8 dmg
- Bramble Golem: 150 HP / 7 dmg -> 90 HP / 4.2 dmg

**Implementation:** Directly reduce the base_hp and base_damage values in `biome_config.gd` for Forest monsters. The 6% exponential growth per level means by level 10 the multiplier is 1.69x, so the reduced values will scale back up naturally. This is simpler and more transparent than adding a level-range multiplier.

**Rationale:** A fresh hero has 100 HP and a LightSword with 10 base damage at 1.8 attack speed = 18 DPS (before any crafting). With a magic weapon (1-2 mods via Runic Hammer), DPS might reach ~25-35. Against the current Forest Bear (120 HP, 12 dmg at 0.8 speed = 9.6 DPS to hero), the hero takes 9.6 DPS while dealing ~25 DPS. Hero dies in ~10 seconds, bear dies in ~5 seconds. That's survivable but tight with no armor. With 40% reduction (72 HP, 7.2 dmg at 0.8 speed = 5.76 DPS), the hero is much more comfortable and can survive 3+ packs as required. The reduction also applies to the dangerous fast attackers (Venomous Spider 1.8 speed, Forest Sprite 2.0 speed) where the original damage was punishing to unarmored heroes.

**No changes to other biomes.** Dark Forest (level 100+) and beyond already require significant gear progression to reach, so their difficulty is appropriate.

### 3. Stat Panel Text Overflow (UI-01)

**Decision:** The HeroStatsPanel in ForgeView already uses `theme_override_font_sizes/normal_font_size = 11` and has a 430x420 pixel content area (offsets: 10,10 to 420,420 within a 430x430 panel). The current hero stats display shows up to ~15 lines of text at font size 11, which fits comfortably.

The issue is specifically when all 3 resistance types + all 3 defense types are displayed simultaneously (max 10 defense lines + 4 header lines + 3 offense lines = 17 lines). At font size 11 with default line height (~16px), 17 lines = 272px, which fits within the 420px available height.

**Implementation:** Verify the current layout handles max-stat scenarios. If any overflow is detected, reduce `normal_font_size` to 10 in the .tscn file. Also ensure the stat comparison view (BBCode with color tags) fits similarly.

**No scrollbar needed** -- the panel is large enough and scroll_active is already false on the RichTextLabel.

### 4. Debug Hammers Flag

**Decision:** Set `debug_hammers = false` in `game_state.gd` as part of polish. This was noted as a known issue in STATE.md (`debug_hammers flag in game_state.gd (currently true)`). Shipping with 999 of each hammer defeats the game loop.

## Scope Notes

- No changes to crafting mechanics, drop rates, or currency behaviors
- No changes to save/load system
- No new UI scenes or navigation changes
- Focus is purely on number tuning and text sizing
