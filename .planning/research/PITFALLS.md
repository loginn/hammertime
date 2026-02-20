# Pitfalls Research

**Domain:** Hammertime — Adding Prestige Reset Loop, Item Tier Gating, 32-Affix Tiers, and Tag-Targeted Crafting Currencies to Existing ARPG Idle Game
**Researched:** 2026-02-20
**Confidence:** HIGH — All critical pitfalls grounded in direct codebase analysis of the existing save system, affix model, and currency architecture. Balance and UX pitfalls informed by ARPG design literature (Path of Exile Harvest nerf, Last Epoch forum design post-mortems, idle game progression math). WebSearch findings flagged where relevant.

---

## Critical Pitfalls

### Pitfall 1: Prestige Data Overwrites During Reset — `initialize_fresh_game()` Nukes Prestige Level

**What goes wrong:**
`game_state.gd:42` has `initialize_fresh_game()` which is called unconditionally in `_ready()` before `load_game()`. It resets everything to zero, including any prestige fields that must persist across resets. If prestige data (prestige level, cumulative prestige currency, unlocked item tiers) is stored as top-level GameState vars alongside `area_level` and `currency_counts`, a call to `initialize_fresh_game()` during prestige reset will nuke them all together.

The prestige reset action needs to clear area progress, gear, and inventory — but explicitly PRESERVE prestige level, unlocked tiers, and prestige currency. If `initialize_fresh_game()` is reused as the prestige reset implementation (a natural temptation since it "resets the game"), it will silently wipe the prestige data the player earned.

**Why it happens:**
`initialize_fresh_game()` is a single-function "wipe everything" reset, designed for New Game. Prestige is a partial reset — the distinction is non-obvious until both use cases exist. Developers reuse the existing reset function rather than designing a separate prestige reset function with an explicit allowlist of what survives.

**How to avoid:**
1. Create a new `apply_prestige_reset()` function that explicitly lists every field that resets and every field that persists. Never call `initialize_fresh_game()` from the prestige path.
2. Separate prestige-persistent state into a distinct block in `GameState`: `prestige_level: int`, `prestige_currency: int`, `unlocked_item_tiers: int`. These must be initialized once (in `initialize_fresh_game()`) and never touched by the prestige reset.
3. The prestige reset clears: `hero.equipped_items`, `crafting_inventory`, `currency_counts` (non-prestige currencies), `area_level`, `max_unlocked_level`. It does NOT clear prestige fields.
4. Add an assertion after prestige reset: `assert(prestige_level == old_prestige_level + 1)` — catches accidental wipe in tests.

**Warning signs:**
- Prestige level shows 0 after performing a prestige
- Unlocked item tiers reset to tier 1 after prestige
- Prestige currency balance returns to 0 immediately after pressing the prestige button
- New game and prestige reset are handled by the same function call

**Phase to address:**
Phase: Prestige Core — Define the prestige reset contract (what resets, what survives) in code comments BEFORE writing the reset function. The separation must be explicit from day one.

---

### Pitfall 2: Save Migration Loses Prestige Fields — v2→v3 Migration Omits New Prestige Keys

**What goes wrong:**
The existing `_migrate_save()` in `save_manager.gd:150` runs version-chained migrations: `if saved_version < 2: data = _migrate_v1_to_v2(data)`. When v3 adds prestige fields (`prestige_level`, `prestige_currency`, `unlocked_item_tiers`), a v2 save will be migrated to v3. If the migration function does not add defaults for the new keys, `_restore_state()` will call `int(data.get("prestige_level", ???))`. If the fallback default is wrong (e.g., `0` for tier unlocks instead of `1` for base tier), restored saves will appear to have no unlocked tiers and the player cannot play at all.

Worse: if the migration function is skipped entirely (e.g., a developer bumps SAVE_VERSION to 3 but forgets to write `_migrate_v2_to_v3()`), existing players on v2 saves load into a game where `prestige_level` is null, causing a crash or silent 0 on the first `prestige_level += 1` call.

**Why it happens:**
Adding fields to a live save format is always a two-place change: `_build_save_data()` must write the new keys AND `_restore_state()` must read them with safe defaults AND the migration function must provide those defaults for old saves. Developers frequently write the first two but skip the migration defaults, relying on `data.get("key", default)` in restore — which works but breaks if the default is not the correct "legacy starting state."

**How to avoid:**
1. Bump SAVE_VERSION to 3 and write `_migrate_v2_to_v3(data)` that injects `"prestige_level": 0`, `"prestige_currency": 0`, `"unlocked_item_tiers": 1` into any v2 save before `_restore_state()` reads them.
2. The restore function must read all prestige fields with `.get("key", safe_default)` — but the migration guarantees the key is present so the default is never exercised in practice. Belt-and-suspenders.
3. Test with a hand-crafted v2 fixture JSON that has none of the prestige keys. Run `load_game()` and assert `prestige_level == 0`, `unlocked_item_tiers == 1`. A fresh v2 player should start at prestige 0 with only base tier items available.
4. The existing export string format `HT1:` prefix is version-agnostic (save version is in the JSON payload). Import of a v2 export string into a v3 game must run the migration before restoring — verify this path works since `import_save_string()` at `save_manager.gd:194` calls `_migrate_save(data)` before `_restore_state(data)`.

**Warning signs:**
- Players who had saves before v1.7 launch cannot load their saves (crash on prestige_level access)
- A fresh-migrated v2 save shows "0 item tiers unlocked" and the player cannot drop any items
- Exported v2 save strings imported into v3 game work but show incorrect prestige data
- `SAVE_VERSION` was incremented but there is no `_migrate_v2_to_v3()` function in `save_manager.gd`

**Phase to address:**
Phase: Save Migration — Write v2→v3 migration function, bump SAVE_VERSION, and verify with a v2 fixture before any prestige gameplay code is written. The migration must be correct before the rest of the feature can be safely built on top of it.

---

### Pitfall 3: Affix Tier Range Expansion Breaks Existing Save Data — Old Affixes Have `tier_range.y = 8`, New System Uses `tier_range.y = 32`

**What goes wrong:**
The current `affix.gd:13` stores `var tier_range: Vector2i = Vector2i(1, 8)` on each affix instance. The affix `_init()` at line 56 computes values as `p_min * (tier_range.y + 1 - tier)` — the `+1` and subtraction create a scaling multiplier where tier 1 (best) = `tier_range.y` multiplier and tier `tier_range.y` (worst) = 1 multiplier.

When the system expands to 32 tiers, new affix templates will be defined with `Vector2i(1, 32)`. But saved items from before the expansion contain serialized `tier_range_y: 8` and a `tier` value in `[1, 8]`. When `affix.from_dict()` is called on a saved affix, it restores `tier_range = Vector2i(1, 8)` from the saved data — so old items remain at 8-tier scaling. This is correct for saved items.

The pitfall is in how NEW affixes are rolled and compared to OLD affixes. If old items roll tier 4/8 (value = 5x base_min) and new items roll tier 4/32 (value = 29x base_min), the tier number "4" means completely different things. Any code that compares `affix.tier` directly — like `is_item_better()` in `forge_view.gd` — will compare 4/8 vs 4/32 as if they are equal, when the new-system tier 4 is vastly better.

**Why it happens:**
`tier` is stored as an absolute number without its range context. Comparison code that uses `affix.tier` as a quality proxy assumes a shared scale. Expanding the scale invalidates the comparison without breaking serialization.

**How to avoid:**
1. Before expanding tiers, audit all code that reads `affix.tier` as a quality comparator and replace with normalized quality: `float(tier_range.y + 1 - tier) / float(tier_range.y)` — this gives 1.0 for best tier, near 0.0 for worst tier, regardless of scale.
2. Alternatively, define a helper `affix.quality() -> float` that does this normalization and use it everywhere tier quality is compared.
3. Old saved affixes with `tier_range.y = 8` will serialize and deserialize cleanly because `affix.from_dict()` reads `tier_range_y` from the save. No migration needed for the tier values themselves — but comparisons must be normalized before the expansion lands.
4. `item_affixes.gd` defines template affixes with hardcoded `Vector2i(1, 8)` (offense) and `Vector2i(1, 30)` (defense). The expansion to 32 tiers must update these templates. The offensive affixes jumping from 8 to 32 tiers means new items will have ~4x more granularity than old items — document that pre-expansion items are "legacy tier 1-8" and are functionally unchanged.

**Warning signs:**
- An item crafted before the expansion compares as "better" than a post-expansion item of the same affix type at the same tier number
- `is_item_better()` gives wrong results for mixed old/new affix tiers
- Items in save from before expansion show inflated or deflated stat values after expansion
- Affix `value` on old items changes after load (would indicate the scaling formula is re-running on load with wrong range)

**Phase to address:**
Phase: Affix Tier Expansion — Before adding any new affix tier definitions, add the normalized `quality()` helper to `affix.gd` and replace all tier-as-quality comparisons. Then expand the template definitions.

---

### Pitfall 4: Tag-Targeted Currencies Too Narrow or Too Broad — Either Obsoletes Other Hammers or Is Never Worth Using

**What goes wrong:**
Tag-targeted currencies (e.g., "Fire Hammer" guaranteeing a fire-tagged affix) exist in tension with the existing random-roll hammers. Two failure modes:

**Too strong (Obsoletes other hammers):** If the Fire Hammer adds a fire affix with no other constraints (can add to Normal, Magic, or Rare; can add at any tier; does not consume a mod slot before rolling), players will exclusively use tag hammers to build optimal items. The Runic and Forge hammers become vendor trash. In PoE, Harvest deterministic crafting was nerfed because "near-perfect items could be crafted with ease" — the game's item economy broke because players could guarantee any mod they wanted without engaging with the broader crafting system.

**Too narrow (Never worth using):** If the Fire Hammer only applies to fire-specced weapons, costs 10x more than other hammers, and still rolls a random tier within the fire affix family, players will simply use Runic/Forge and hope for fire. The hammer's cost exceeds the expected value of the guaranteed outcome.

**Why it happens:**
Tag-targeted currencies are evaluated in isolation during design but their power only manifests relative to the complete set of existing hammer options. The correct balance point requires knowing the expected number of Runic/Forge applications needed to land a desired tag without the targeted hammer, then pricing the targeted hammer below that expected cost.

**How to avoid:**
1. Before defining tag hammer cost, calculate expected hammers-to-specific-tag with existing hammers. For fire on a weapon: the weapon has N valid prefixes (from `item_affixes.gd` count prefixes with WEAPON tag), of which M have FIRE tag. A Runic adds a random valid prefix, so chance of hitting fire = M/N. Expected Runic hammers to get one fire affix ≈ N/M. The tag hammer should cost more than 1 but less than N/M.
2. The Fire Hammer should NOT guarantee a best-tier fire affix — it should guarantee a fire affix at a random tier within the normal affix tier range. This preserves the "still RNG inside the tag" element and means a crafted item can still have a mediocre fire affix, making repeat use of the hammer meaningful.
3. The Fire Hammer should apply only to items that already have space for an affix (same `can_apply()` constraints as Runic/Forge). It should NOT bypass rarity limits — if the item is Magic (1 prefix max) and already has a prefix, the Fire Hammer should fail like any other hammer.
4. Tag hammers must be rarer than basic hammers. Prestige-gated unlock (Prestige 1) already handles this. Within the drop system, the Fire Hammer should have a lower base drop chance than Runic/Forge.
5. Verify balance by simulating: how many tag hammer uses to fully outfit a weapon with desired element? How many Runic/Forge to do the same randomly? The tag hammer path should be faster but not instant.

**Warning signs:**
- Players report using only tag hammers after Prestige 1 and never touching Runic/Forge again
- Players report tag hammers costing too much currency for the value — never worth crafting with
- Tag hammer applies to items that are already full of mods (bypassing the slot limit check)
- Tag hammer guarantees best-tier affix (bypasses tier randomness entirely)

**Phase to address:**
Phase: Tag-Targeted Currency Design — Run the expected-value calculation for existing hammer-to-tag probability before setting the tag hammer drop rate. The hammer's cost/availability must be calibrated against the Runic/Forge baseline.

---

### Pitfall 5: Prestige Cost Scaling Creates a Wall or a Trivial Ramp — Wrong Math Kills the Loop

**What goes wrong:**
Two failure modes for prestige cost curves:

**Too cheap (Trivial):** If each prestige costs a flat amount of prestige currency that players accumulate quickly, players complete all 7 prestige levels in a single play session. The meta-progression collapses into a one-time grind rather than a recurring loop. The intended "each prestige feels like a milestone" behavior disappears.

**Too expensive (Wall):** If prestige cost scales exponentially without bound (e.g., 10x more currency per prestige level), the later prestiges (levels 5-7) require so much currency that players effectively cannot reach them. The system feels unfair rather than challenging. This is the idle game's most common retention failure — players quit when prestige feels impossibly gated.

The prestige currency accumulates from playing the game (area clears, pack kills). If the formula for how much currency is earned per session is not explicitly designed against the prestige cost curve, the two numbers can diverge in any direction.

**Why it happens:**
Prestige costs are often designed in abstract ("level 1 costs 50, level 2 costs 200, level 3 costs 500") without first modeling how much currency a typical session generates. The math only meets reality during playtesting.

**How to avoid:**
1. Before setting prestige costs, estimate sessions-to-prestige at target level: how many area clears to accumulate the required currency? A prestige should feel achievable in 1-3 play sessions of 20-30 minutes each. For prestige 7, it should feel like a long-term goal (maybe 5-10 sessions), not infinite.
2. Use a power curve between linear and exponential: `cost(level) = base * level^2` or `cost(level) = base * 1.5^level` are reasonable starting points. Test both by simulating expected play time to each prestige level.
3. Distinguish prestige currency from regular gameplay currency. The prestige currency should accumulate passively and consistently, not spike at specific milestones. "You earn 1 prestige point per area cleared" is a simple, predictable formula that allows exact cost modeling.
4. Design prestiges 1-3 to feel achievable for a player who is not yet optimized; prestiges 4-7 should feel like endgame goals. Gate new content (tag hammers, higher item tiers) at lower prestige levels so players get meaningful rewards before the wall hits.

**Warning signs:**
- Players reach prestige 7 in under 2 hours total play time (too cheap)
- Players are stuck at prestige 3 for many sessions with no visible progress toward prestige 4 (too expensive)
- Prestige currency is earned at such an irregular rate that players cannot estimate when they will prestige
- The gap between prestige 6 and prestige 7 is dramatically larger than between 1 and 2 (exponential runaway)

**Phase to address:**
Phase: Prestige Core — Model the cost curve with actual session-length estimates before setting any cost values. Do not tune costs based on "feels right" — use math.

---

### Pitfall 6: Item Tier Gating Makes Early Game Feel Punishing — Players Cannot Progress Without Tier 1 Content

**What goes wrong:**
If item tiers gate the affixes available on items (tier 1 items only roll tier 1-4 affixes, tier 2 items roll tier 1-8 affixes, etc.), and prestige is required to unlock higher item tiers, the first prestige run feels like playing with neutered gear. Players who have not yet prestiged can only find low-tier items with low-tier affixes. If the game balance was calibrated to the full affix tier range (tiers 1-8 previously), restricting pre-prestige players to tiers 25-32 of the new 32-tier range means those players are weaker than they were before the milestone launched — the expansion makes the pre-prestige experience worse.

**Why it happens:**
Affix tier expansion (8→32) distributes the same power budget across more tiers. If the 32-tier system's low tiers (25-32) have equivalent values to the old 8-tier system's low tiers (6-8), the pre-prestige experience is unchanged. But if the team re-scales all affix base values to accommodate 32 tiers without checking equivalence at the low end, old players are worse off on day one.

**How to avoid:**
1. Before expanding affix tiers, document the current pre-expansion affix values at each tier. After expansion, verify that the new tier system's "base tier" (the tiers available without prestige) produces equivalent or better values than the old system's lowest tiers.
2. The 32-tier system should map as follows: tiers 1-8 (old system) map to tiers 1-4 in the new system (prestige 3+ content), while the new tiers 25-32 produce values comparable to old tiers 7-8 (weakest). Pre-prestige players should get items in the tier 25-32 range — which should feel comparable to where they were before. Do not make the pre-prestige experience feel like "garbage" relative to launch.
3. The item tier unlock system must ensure that pre-prestige play feels similar to pre-expansion play. The expansion should add ceiling (new good stuff at high prestige), not lower the floor.
4. Test by simulating: "If a player who played before the expansion logs in after, is their best crafted item still competitive?" If yes, the floor is correct.

**Warning signs:**
- Players who return after the v1.7 launch report their gear feeling "worse" without having touched the prestige button
- Pre-prestige area clearing becomes slower than it was in v1.6
- The weakest affixes in the 32-tier system produce visibly worse values than the weakest affixes in the 8-tier system
- Players report that the game feels "harder now" despite not having changed anything about their play style

**Phase to address:**
Phase: Affix Tier Expansion — Before shipping the expansion, run a direct comparison: create a v1.6 item and a v1.7 pre-prestige item with identical affix names and equivalent tiers. Their values must be within 10% of each other.

---

### Pitfall 7: Reset Scope Ambiguity — Prestige Resets Something It Should Not, or Fails to Reset Something It Should

**What goes wrong:**
The prestige reset must precisely define scope. Two specific risks in the Hammertime architecture:

**Resets too much:** `max_unlocked_level` tracks the furthest area cleared. If prestige resets this along with `area_level`, the player must re-unlock all content from area 1 every prestige. This is intentionally required for a "true reset" prestige, but if the design intent is a "soft reset" that only resets `area_level` (current position) while keeping `max_unlocked_level` (gates), players will expect to fast-travel back to where they were. The design must be explicit about which of these resets.

**Resets too little:** If prestige reset clears `hero.equipped_items` but does NOT clear `crafting_inventory`, players keep their stash of high-tier items. They immediately re-equip on a fresh hero from stash, and the prestige feels like it did nothing. The grind for new items is bypassed.

**Why it happens:**
The reset scope is defined implicitly by which `GameState` variables the reset function touches. Without an explicit list written down before code is written, developers make ad-hoc decisions ("should we reset crafting_inventory? I think so...") that result in inconsistent behavior.

**How to avoid:**
1. Before writing any reset code, write a two-column table: RESETS and PERSISTS. Every `GameState` variable must appear in exactly one column. This document becomes the specification for `apply_prestige_reset()`.
2. Recommended scope for Hammertime:
   - **RESETS:** `area_level`, `max_unlocked_level` (if hard reset), `hero.equipped_items`, `crafting_inventory`, `currency_counts` (non-prestige types)
   - **PERSISTS:** `prestige_level`, `prestige_currency`, `unlocked_item_tiers`, `max_unlocked_level` (if soft reset variant)
3. After reset, auto-save immediately. Do not let the player play before the post-prestige state is persisted — a crash between prestige button press and save would leave the game in an inconsistent state (prestige data wiped in memory but old save still on disk).
4. Add a confirmation dialog with a clear list of what will be lost. "Prestige will reset your area progress, equipped gear, and crafting inventory. Your prestige level and unlocked tiers will be preserved." Players must never be surprised by what resets.

**Warning signs:**
- Players immediately re-equip their pre-prestige BiS items from crafting inventory after a prestige (forgot to reset inventory)
- Players lose their max_unlocked_level and must re-unlock every area from scratch when the intent was soft-reset
- A crash between the prestige button press and auto-save leaves the game in a mixed state (prestige data gone, old gear still in save)
- The prestige confirmation dialog does not mention that crafting inventory will be cleared

**Phase to address:**
Phase: Prestige Core — Write the RESETS/PERSISTS table as a comment block at the top of `apply_prestige_reset()`. Every field touched by the function must appear in the table.

---

### Pitfall 8: Prestige UI Fails to Communicate Value Before the Player Commits — Players Prestige Blindly or Refuse to Prestige

**What goes wrong:**
Two UX failure modes:

**Blind prestige:** The prestige button is visible and triggerable with no explanation of what the player gains. Players hit it out of curiosity, lose all their gear, and are angry. They do not return.

**Refusal to prestige:** The prestige button shows the cost but not the benefit. Players see "500 prestige currency" but not "unlocks item tier 3 — affixes up to 3x stronger." They refuse to prestige because the cost is known but the reward is opaque. Prestige stalls.

Both are the same underlying problem: the UI shows the cost without showing the value.

**Why it happens:**
The prestige button is usually implemented first (as a trigger for the reset mechanic) and the explanatory UI is added later as an afterthought. By the time the "later" arrives, the button is already shipping.

**How to avoid:**
1. The prestige UI must show, before the player commits: current prestige level, cost to prestige, what unlocks at the next prestige level (specifically: "Item tier X unlocked — new affix tiers available"), and what will be reset.
2. Gate the prestige trigger behind a two-step confirmation: first press shows the consequence summary, second press executes. The two-click equip confirmation already in the game (`forge_view.gd:49-50`) is the right pattern.
3. Show prestige progress even when the player cannot afford to prestige: "You need 500 prestige currency. You have 237 (47% complete)." This keeps the long-term goal visible during normal play.
4. After prestige, immediately show the new tier unlock in the UI before the player does anything else. "You are now Prestige 2. Item tier 3 items can now drop." This closes the feedback loop.

**Warning signs:**
- Players report "I lost all my gear and didn't know prestige would do that"
- Players at maximum prestige currency sit idle rather than prestiging because they do not understand the benefit
- The prestige confirmation dialog shows cost but not reward
- Post-prestige state looks identical to pre-prestige at a glance (new tier unlock not visible until a drop occurs)

**Phase to address:**
Phase: Prestige UI — Design the consequence summary UI alongside the prestige trigger mechanic. They must ship together. Do not ship the trigger without the summary.

---

## Moderate Pitfalls

### Pitfall 9: `add_prefix()` / `add_suffix()` in `item.gd` Ignores Item Tier — Tag-Targeted Hammers Can Add Affixes That Outscale the Item

**What goes wrong:**
`item.gd:229-244` — `add_prefix()` selects from `ItemAffixes.prefixes` filtered by `has_valid_tag()`. The filter checks tags but not item tier. When tag-targeted currencies add a fire affix to any item regardless of tier, a tier-1 item (intended to have weak affixes) can receive a best-tier fire affix because the tier selection in `affix._init()` at `line 52` rolls from the full `tier_range` regardless of what item tier is requesting it.

After the 32-tier expansion, `tier_range = Vector2i(1, 32)` means a tag hammer applied to a tier-1 item can roll tier 1 (best) fire affix — producing a tier-1 item with a tier-32 affix value, which breaks the item tier gating design intent.

**How to avoid:**
1. When item tier gating is implemented, affix rolling must respect the item's allowed tier range. Pass the item's tier context to `add_prefix()` / `add_suffix()` as a parameter that constrains the rolled affix tier.
2. Concretely: `add_prefix(allowed_tier_range: Vector2i = Vector2i(1, 32))` passes the constraint down to `Affixes.from_affix()`, which clips the template's `tier_range` to `allowed_tier_range` before calling `Affix._init()`.
3. Tag-targeted currencies use the same item-tier-constrained affix rolling as regular hammers. The tag is the constraint on affix type; the item tier is the constraint on affix power.

**Warning signs:**
- A tier-1 item has an affix with the same value as a post-prestige tier-4 item
- The item tier gating feels meaningless because hammers bypass it
- Affix tier display on items shows "tier 1" despite the item being tier 1 (which should produce tier 28-32 affixes in the 32-tier system)

**Phase to address:**
Phase: Affix Tier Expansion — When the tier constraint is added to the rolling system, ensure it applies to all currency `_do_apply()` paths, including the new tag hammers.

---

### Pitfall 10: `area_level` and `max_unlocked_level` Both Reset, But Item Drops Loot Table Still Uses Old Area Level

**What goes wrong:**
`loot_table.gd` uses `area_level` as the parameter for `roll_pack_currency_drop(area_level)`. After a prestige reset, `area_level` resets to 1. This is correct — the player starts over in Forest. But if any drop rate or item tier selection code caches the old area level (via a signal handler that stored it) and the cache is not cleared during prestige reset, drops in the new post-prestige run will use stale area data.

More specifically: `save_manager.gd:99` saves `area_level` directly. After prestige, this is re-saved as 1. No caching issue there. The risk is in scene-level caching — if `gameplay_view.gd` stores a local `current_area_level` that it updates only on `area_cleared` signal, a prestige reset that changes `GameState.area_level` without emitting `area_cleared` would leave `gameplay_view`'s local cache stale at the old level.

**How to avoid:**
1. Do not store `area_level` locally in scenes. Always read `GameState.area_level` directly from the drop calculation call site.
2. After prestige reset, emit a dedicated `prestige_completed` event on `GameEvents` that all scene-level state can listen to and use to clear any local caches.
3. `loot_table.gd` is stateless (all functions are `static`) — no caching risk there. Verify `gameplay_view.gd` and `main_view.gd` do not cache area level locally.

**Warning signs:**
- Currency drop rates immediately after prestige reflect Shadow Realm rates despite being in Forest
- Item tier drops after prestige reflect the old pre-prestige tier range despite being in the early biome
- Difficulty feels wrong (too easy or too hard) in the first map after prestige

**Phase to address:**
Phase: Prestige Core — When implementing the prestige reset function, emit a `prestige_completed` signal and verify all scene nodes handle it cleanly.

---

### Pitfall 11: Affix Tier Display Becomes Meaningless After Expansion — "Tier 4" Means Nothing Without Context

**What goes wrong:**
`item.gd:154-158` — `display()` prints `"~ tier %d" % [prefix.tier]`. Currently, tier 1 is best and tier 8 is worst. After expansion to 32 tiers, the display shows a number from 1-32. A player seeing "tier 4" does not know if this is excellent (4/32 = near best) or poor (4/8 = mid-range, old system). The context is the `tier_range` but that is not displayed.

Worse: old items (pre-expansion) have `tier_range.y = 8` and show "tier 4" meaning midrange. New items have `tier_range.y = 32` and show "tier 4" meaning near-best. The same number now means completely different things on items dropped before and after the expansion.

**How to avoid:**
1. Change affix display from raw tier number to a quality label: "Tier 4/32 (Exceptional)" or a star rating (1-5 stars). This communicates relative quality without requiring the player to know the range.
2. At minimum, display tier as `"tier %d/%d" % [tier, tier_range.y]` so the player always sees the context.
3. The defensive affixes already use `Vector2i(1, 30)` which differs from the 8-tier offensive affixes. This inconsistency already existed but becomes more visible after expansion — standardize the display format.

**Warning signs:**
- Players confuse old items with new items because both show "tier 4" for different actual quality levels
- Community feedback: "What does the tier number mean?"
- Players cannot determine which of two items is better from the tier display

**Phase to address:**
Phase: Affix Tier Expansion — Update all affix display code to show `tier/max_tier` before shipping the expansion. Do not ship raw tier numbers when the max changes between items.

---

### Pitfall 12: `Currency` Template Method `can_apply()` Hardcodes Rarity Checks — Tag Hammers Need New Validity Conditions

**What goes wrong:**
`runic_hammer.gd:8` — `can_apply()` checks `item.rarity == Item.Rarity.NORMAL`. `forge_hammer.gd:8` — same. Tag-targeted hammers will have different conditions: they should apply to items that have room for a mod of the targeted tag (e.g., a weapon with an empty prefix slot AND the targeted tag being valid for weapons). If tag hammer `can_apply()` is written as a copy-paste of RunicHammer's check plus a tag check, it will fail in edge cases where the item is Normal/MAGIC/RARE with different slot availability.

The existing `Currency` base class correctly enforces that `_do_apply()` is never called if `can_apply()` returns false. The risk is writing `can_apply()` for tag hammers that is incomplete — e.g., forgetting to check that the item actually has an empty prefix slot, only checking that it is the right item type.

**How to avoid:**
1. Write `can_apply()` for tag hammers with explicit checks:
   - Item has the valid tag for the currency's target tag (e.g., WEAPON tag for Fire Hammer on weapon affixes)
   - Item has at least one open prefix or suffix slot (depending on whether the targeted affix is prefix or suffix)
   - Item rarity allows at least one more mod (not NORMAL if targeting prefix, unless the hammer also upgrades rarity)
2. Implement a helper in `Item` — `has_room_for_prefix() -> bool` and `has_room_for_suffix() -> bool` — to avoid duplicating slot-availability logic across hammers.
3. Write `get_error_message()` for each failure condition so the UI can show specific feedback: "Item is full of mods" vs. "This item type cannot have fire affixes."

**Warning signs:**
- Fire Hammer can be applied to a Rare item with 3 prefixes already (bypasses prefix cap)
- Fire Hammer can be applied to a ring (which does not support fire damage affixes per `valid_tags`)
- Tag hammer applies but adds nothing (the `_do_apply()` finds no valid affixes to add and returns silently)

**Phase to address:**
Phase: Tag-Targeted Currencies — Write and test `can_apply()` for each tag hammer covering all item type and rarity combinations before wiring to the UI.

---

### Pitfall 13: Prestige Level 7 Is the Ceiling — The Game Has Nowhere to Go After Max Prestige

**What goes wrong:**
The spec says "7 prestige levels total." Once a player reaches prestige 7 with all item tiers unlocked and all tag hammers available, the game's meta-progression loop ends. Idle game retention math requires that the engagement loop has meaningful continuation. If players reach prestige 7 and then continue playing with no new systems, the game dies.

This is not a coding pitfall but a design trap that affects how the prestige system should be architected: it should be built with extensibility in mind, not as a one-time ceiling.

**How to avoid:**
1. Design `prestige_level` as an integer with no hardcoded ceiling in the code (even if the design says 7 levels). The ceiling should be a data constant, not a structural constraint.
2. The prestige UI should communicate "Prestige X of 7 (Final tier)" rather than removing the prestige button at max level. Future milestones can raise the ceiling.
3. Document the expected post-max prestige player experience in the milestone spec: "At prestige 7, players have full access to all item tiers and tag hammers and continue playing for endgame optimization." This sets the right expectation and identifies future milestone targets.

**Warning signs:**
- `prestige_level` is used in a match statement with cases 1-7 and a catch-all that does nothing
- The prestige button is hidden or disabled at prestige 7 with no explanation
- Players reach prestige 7 and the game loop has no remaining goal

**Phase to address:**
Phase: Prestige Core — Define the prestige level ceiling as a constant `const MAX_PRESTIGE_LEVEL = 7` in `GameState`, not as hardcoded logic. This makes it trivially extensible.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Reuse `initialize_fresh_game()` for prestige reset | No new function needed | Silently wipes prestige data — saves become corrupt | Never |
| Store prestige fields in same dict as regular game state | Simple save format | Any migration that touches that dict can accidentally clear prestige | Never — always isolate prestige fields in their own save key |
| Compare affix tiers as raw integers across different tier ranges | Simpler comparison code | `affix.tier == 4` means different things for 8-tier vs 32-tier affixes | Never — normalize to quality float before expansion |
| Skip `_migrate_v2_to_v3()` and rely on `.get("key", default)` in restore | Less code to write | Old saves load with wrong default tier unlocks (0 instead of 1, or 32 instead of 1) | Never — write the migration function |
| Show raw tier number (tier 4) without max context in UI | No display code change needed | Players cannot interpret tier numbers after 8→32 expansion | Acceptable before expansion ships; must fix before expansion lands |
| Hardcode tag hammer power level to be roughly equivalent to Runic | Simple tuning | Tag hammers either obsolete or are never used — binary outcome | Never — calculate expected-value against existing hammers before tuning |
| Gate all 7 prestige levels on the same cost curve | Simple cost formula | Mid-prestige wall causes player churn before they reach tag hammer content | Acceptable at MVP if playtested; requires adjustment before launch |

---

## Integration Gotchas

| Integration Point | Common Mistake | Correct Approach |
|------------------|----------------|------------------|
| Prestige reset + `initialize_fresh_game()` | Call `initialize_fresh_game()` then manually restore prestige fields | Write `apply_prestige_reset()` that only touches the RESETS list; never call `initialize_fresh_game()` from prestige path |
| v2→v3 save migration for prestige fields | Rely on `data.get("prestige_level", 0)` default in restore | Inject defaults in `_migrate_v2_to_v3()` so the key is always present before restore runs |
| Affix tier comparison after 8→32 expansion | Compare `affix.tier` directly | Compare `affix.quality()` (normalized float) to ensure consistent cross-range comparison |
| Tag hammer `can_apply()` | Copy RunicHammer's rarity check only | Include rarity check AND slot availability check AND item type tag check — all three |
| Post-prestige area level in drop calculations | Use cached local area level from `gameplay_view` | Always read `GameState.area_level` directly; emit `prestige_completed` signal for scene cache invalidation |
| Item tier constraint in affix rolling | Allow any affix tier on any item tier | Pass `allowed_tier_range` to `add_prefix()`/`add_suffix()` based on item tier; clip the template's `tier_range` |
| Prestige currency vs. regular currency | Store in `currency_counts` dict alongside runic/forge | Add dedicated `prestige_currency: int` var to `GameState`; exclude from the regular currency reset path |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Affix tier normalization computed every comparison | CPU spike in forge_view when comparing many items in a full 10-slot inventory | Cache `quality()` result on affix at roll time; never recompute | At 50+ items across all slots (far-future scale; not critical at 10-item cap) |
| Prestige confirmation dialog re-reads all GameState to display consequences | Brief stutter on prestige button press | Pre-compute consequence summary at idle time or on scene load | Not a concern until GameState grows very large |
| Post-prestige auto-save while scene is reinitializing | Race condition: save fires mid-reinit, saves partial state | Disable auto-save during prestige reset; re-enable after reinit and initial new-state save | First prestige attempt |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Prestige button visible but not yet affordable | Confusion about how to trigger it | Show prestige progress bar ("237/500 prestige currency") with button grayed out and tooltip explaining cost and reward |
| Post-prestige state looks identical to pre-prestige at a glance | Players wonder if prestige did anything | Show "Prestige 2 Complete — Item Tier 3 Unlocked!" overlay before returning to normal play |
| Reset clears crafting inventory without warning | Players who spent hours crafting feel robbed | Confirmation dialog explicitly lists "Your crafting inventory (10 items per slot) will be cleared" |
| Item tier gating not visible in loot — players don't know why they're getting weak items | Players think the game is bugged | Show item tier on each dropped item ("Tier 2 Light Sword") so players know tier unlocks matter |
| Tag hammer does nothing on a full Rare item with no error message | Silent failure — player loses nothing but is confused | `get_error_message()` must return specific failure reason; UI must display it |
| Prestige 7 reached with no indication of "you're done" | Players think more prestige exists and grind pointlessly | Show "Maximum Prestige Achieved" indicator; surface endgame optimization goals explicitly |
| Affix tier number means different things before/after expansion | Players' mental model of their item quality is wrong | Standardize to `tier/max_tier` display format before expansion ships |

---

## "Looks Done But Isn't" Checklist

- [ ] **Prestige Reset Scope:** Written a RESETS/PERSISTS table? Does `apply_prestige_reset()` match the table exactly? — verify by pressing prestige and checking every GameState variable
- [ ] **Prestige Fields Survive Reset:** `prestige_level` increments by exactly 1 after prestige? `prestige_currency` returns to 0 (spent) or persists (retained — design choice)? `unlocked_item_tiers` increments? — check all three after first prestige
- [ ] **Save Migration v2→v3:** `_migrate_v2_to_v3()` written and injects all prestige field defaults? Load a hand-crafted v2 fixture — assert `prestige_level == 0` and `unlocked_item_tiers == 1`
- [ ] **Affix Tier Comparison:** `affix.quality()` or equivalent normalization used everywhere tier quality is compared? Grep for direct `affix.tier` comparisons — any remaining are suspect
- [ ] **Tag Hammer can_apply():** Tests cover all failure modes: full mods, wrong item type, rarity mismatch? — run tag hammer against Rare weapon with 3 prefixes, should fail gracefully
- [ ] **Tag Hammer Balance:** Expected Runic hammer rolls to get target tag without tag hammer calculated? Tag hammer cost set below that value?
- [ ] **Affix Tier Display:** All affix display code shows `tier/max_tier` format? Old items and new items both display correctly?
- [ ] **Item Tier Floor:** Pre-prestige item values comparable to v1.6 equivalent? Simulate one: craft a weapon in v1.6, craft equivalent in v1.7 pre-prestige — values within 10%
- [ ] **Prestige UI Consequence Summary:** Confirmation dialog shows cost AND reward AND what resets? — confirm before first press shows all three
- [ ] **Post-Prestige Signal:** `prestige_completed` signal emitted after reset? All scene-level state (gameplay_view, forge_view) listening and clearing caches?
- [ ] **MAX_PRESTIGE_LEVEL Constant:** Defined as a constant, not hardcoded in conditionals? Code still compiles and runs correctly if the constant is changed to 8?
- [ ] **Currency Account Separation:** Prestige currency in dedicated `GameState.prestige_currency` var, not in `currency_counts`? Prestige reset does not clear `prestige_currency`?

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| `initialize_fresh_game()` used for prestige, nukes prestige data | HIGH — existing player saves may show wrong prestige level | 1. Write `apply_prestige_reset()` immediately 2. If players already have corrupt saves, add a prestige_level recovery in the next migration (read from a backup key or prompt player to confirm their prestige level) 3. Cannot fully recover lost prestige state from JSON if it was overwritten |
| v2→v3 migration missing — saves load with wrong defaults | MEDIUM | 1. Write migration function 2. Bump SAVE_VERSION to 4 3. Detect corrupt v3 state (prestige_level == null or unlocked_tiers == 0 for a non-fresh game) and repair in v3→v4 migration |
| Affix comparison broken after tier expansion | LOW — no save data at risk | 1. Add `quality()` helper 2. Find and replace all direct tier comparisons 3. No save migration needed — save data is unchanged |
| Tag hammer too strong — players quit using other hammers | MEDIUM — requires design change | 1. Increase tag hammer area gate (later prestige level unlock) 2. Reduce tag hammer drop rate 3. Add tier constraint so tag hammer rolls in same tier range as random hammers |
| Tag hammer too weak — never used | LOW | 1. Decrease cost (more common drops) 2. Lower prestige unlock requirement 3. Widen the targeted tag pool (fire hammer adds any elemental affix, not just fire) |
| Item tier floor too low — pre-prestige players feel punished | MEDIUM | 1. Recalibrate the lowest item tier's affix scaling to match v1.6 values 2. Does not require save migration — affects new item drops only 3. Items already crafted retain their serialized values |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Prestige wipes prestige data via `initialize_fresh_game()` (Pitfall 1) | Prestige Core | Press prestige; assert `prestige_level == old_level + 1` and `currency_counts` cleared but `prestige_level` not reset |
| v2→v3 migration omits prestige field defaults (Pitfall 2) | Save Migration | Load v2 fixture JSON; assert `prestige_level == 0`, `unlocked_item_tiers == 1` |
| Affix tier expansion breaks tier comparison (Pitfall 3) | Affix Tier Expansion | Create old-system affix (tier 4/8) and new-system affix (tier 4/32); verify `quality()` returns different values |
| Tag hammers too strong or too narrow (Pitfall 4) | Tag-Targeted Currency Design | Calculate expected-value; verify hammer usage remains supplementary (not primary) with playtest |
| Prestige cost curve creates wall or triviality (Pitfall 5) | Prestige Core | Model sessions-to-prestige for levels 1 and 7; both must feel achievable within target session counts |
| Item tier gating lowers pre-prestige floor (Pitfall 6) | Affix Tier Expansion | Compare equivalent items in v1.6 and v1.7 pre-prestige; values within 10% |
| Reset scope includes wrong fields (Pitfall 7) | Prestige Core | Verify all fields in RESETS list are cleared and all fields in PERSISTS list are unchanged after prestige |
| Prestige UI hides cost or benefit (Pitfall 8) | Prestige UI | Confirmation dialog shows cost, reward, and reset consequences — user must see all three before confirming |
| Tag hammers bypass item tier constraint (Pitfall 9) | Affix Tier Expansion | Apply tag hammer to tier-1 item; verify affix tier is in the allowed tier range for that item tier |
| Stale area level in drops after prestige (Pitfall 10) | Prestige Core | After prestige, clear map and verify drop rates match area 1 rates, not pre-prestige area |
| Affix tier display context lost after expansion (Pitfall 11) | Affix Tier Expansion | Verify display shows `tier/max_tier` for affixes from both old (8-tier) and new (32-tier) items |
| Tag hammer `can_apply()` incomplete (Pitfall 12) | Tag-Targeted Currencies | Run tag hammer against full Rare item; verify it returns false with correct error message |
| Prestige 7 ceiling hard-coded (Pitfall 13) | Prestige Core | Change `MAX_PRESTIGE_LEVEL` to 8 in test; verify no compile errors or runtime crashes |

---

## Sources

- Codebase analysis: `autoloads/save_manager.gd`, `autoloads/game_state.gd`, `models/affixes/affix.gd`, `autoloads/item_affixes.gd`, `models/items/item.gd`, `models/currencies/currency.gd`, `models/currencies/runic_hammer.gd`, `models/currencies/forge_hammer.gd`, `models/loot/loot_table.gd`
- Milestone context: `.planning/PROJECT.md` (v1.7 Meta-Progression requirements)
- Path of Exile Harvest crafting nerf post-mortem: GGG Development Manifesto — "We're concerned by how deterministic some Harvest Crafts are and how easily players can craft near-perfect items." (MEDIUM confidence via WebSearch)
- Last Epoch forum discussion on affix tier design: "Some affixes gain half of their power in Tier 1, others scale multiplicatively" — scaling imbalances in affix tier systems [https://forum.lastepoch.com/t/affix-tier-and-implicit-drops-to-fix-gear-progression/25536/16] (MEDIUM confidence)
- Idle game prestige math — Kongregate Math of Idle Games Part III [https://blog.kongregate.com/the-math-of-idle-games-part-iii/] — prestige formulas and plateau behavior (MEDIUM confidence)
- Hunt: Showdown prestige item loss community backlash — "Losing all items and having to grind from scratch negatively impacts player experience" (MEDIUM confidence via WebSearch)
- Save migration best practices — Meta Horizon developer documentation [https://developers.meta.com/horizon/documentation/unity/ps-save-game-best-practices/] — chain migrations, version flags, defaults for new fields (HIGH confidence via official docs)
- Previous v1.5 PITFALLS.md — save migration and bench reference pitfalls (HIGH confidence — already shipped and verified)

---
*Pitfalls research for: Hammertime — Prestige Reset Loop, Item Tier Gating, 32-Affix Tiers, Tag-Targeted Crafting Currencies (v1.7)*
*Researched: 2026-02-20*
*Confidence: HIGH — All critical pitfalls grounded in direct codebase analysis with specific file paths; balance pitfalls informed by ARPG design literature and idle game math; no claims made without architectural evidence or sourced precedent*
