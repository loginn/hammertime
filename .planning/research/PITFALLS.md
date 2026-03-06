# Pitfalls Research

**Domain:** Hammertime -- Adding Item Archetypes (str/dex/int) and Dual Damage Channels (attack + spell) to Existing ARPG Idle Game
**Researched:** 2026-03-06
**Confidence:** HIGH -- All pitfalls grounded in direct analysis of the existing codebase (Item, Affix, StatCalculator, CombatEngine, Tag, ItemAffixes, LootTable, ForgeView, save format v4). Balance pitfalls informed by ARPG dual-channel design patterns and idle game automation constraints.

---

## 1. Balance Pitfalls -- Spell vs Attack Parity

### 1a. One channel dominates, the other is dead content

**The problem:** When you add spell damage alongside attacks, the math almost always favors one channel. In Hammertime, attacks already have a tuned pipeline: base weapon damage -> flat adds -> % increased -> speed -> crit. If spell damage uses the same formula but with different base values, whichever channel has better scaling per affix slot wins, and the loser becomes a wasted mod.

**Why it hits idle games harder:** Players cannot manually alternate between attack and spell rotations to balance things. The auto-combat loop picks one cadence. If spells deal 30% more DPS than attacks at equivalent gear, every informed player ignores attack mods entirely. There is no skill expression to make the weaker channel work.

**Hammertime-specific risk:** The CombatEngine currently uses a single `hero_attack_timer` with `base_attack_speed` from the weapon. Adding a spell timer means two independent damage streams. If both scale with the same crit stats (crit chance and crit damage are currently suffixes available to all WEAPON/CRITICAL tagged items), the channel with higher base throughput double-dips on shared multipliers and pulls ahead exponentially.

**Prevention:**
- Make attack speed and cast speed separate suffix pools that do not cross-apply. Attack speed should not accelerate spell casts and vice versa.
- Give spells and attacks different crit scaling or make crit a shared stat that amplifies total DPS equally regardless of channel.
- Use a single DPS formula that sums both channels. Balance by making the affix budget the same: 3 spell affixes on a weapon should produce comparable DPS to 3 attack affixes at the same tier.
- Test with a spreadsheet: max-rolled T1 attack weapon vs max-rolled T1 spell weapon must land within 10% DPS of each other.

### 1b. Hybrid builds outperform pure builds

**The problem:** If a weapon can roll both attack and spell damage affixes, a rare item with 3 attack prefixes + 3 spell suffixes (or vice versa) stacks two full damage pipelines. Pure attack or pure spell builds only use one pipeline's worth of scaling.

**Why it is tempting:** More build diversity sounds good. But in an idle game, the auto-combat does not know which channel to prioritize. If both channels fire independently, hybrid is always strictly better because the hero deals damage from two timers simultaneously.

**Prevention:**
- Constrain item bases so str weapons have attack tags and int weapons have spell tags. A Light Sword should not roll spell damage. A Staff should not roll attack speed.
- If hybrid items exist (e.g., a ring), make the affix pool shared so you are choosing between attack and spell mods for the same slots, not stacking both.

### 1c. Cast speed vs attack speed equivalence

**The problem:** Attack speed currently ranges around 1.0-1.8 hits/sec (Light Sword is 1.8). If cast speed uses a different base or different affix scaling, the time-to-kill diverges. A 5% cast speed affix on a 2.0 base is worth more than 5% attack speed on a 1.0 base.

**Prevention:**
- Normalize: if base_attack_speed = 1.8, set base_cast_speed to a value that produces equivalent DPS when combined with spell base damage. E.g., if spell base damage is 2x attack base damage, cast speed should be half.
- Use two stat types (INCREASED_ATTACK_SPEED, INCREASED_CAST_SPEED) so the hero stat panel is unambiguous about which timer each mod affects.

---

## 2. Content Bloat Pitfalls -- Too Many Bases/Affixes

### 2a. Base proliferation overwhelming the crafting loop

**The problem:** Going from 5 item bases (LightSword, BasicArmor, BasicHelmet, BasicBoots, BasicRing) to 15 (3 per slot) triples the item pool. Each base drops at 18% per pack kill. With 15 bases the chance of getting the specific base you want drops from 20% to 6.7%. Players spend 3x longer finding the right blank base before they can even start crafting.

**Hammertime-specific risk:** Per-slot inventory arrays hold 10 items each. With 3 bases per slot, each slot fills 3x faster with bases the player does not want. Players spend more time melting unwanted bases than crafting.

**Prevention:**
- Weight drops toward the archetype the player is building. If the hero has a str weapon equipped, bias weapon drops toward str bases. This is an implicit loot filter.
- Alternatively, keep drops slot-based (weapon/armor/etc.) and let the player choose the archetype when they start crafting on a blank base. This avoids base proliferation entirely in the drop pool.
- Do not add archetype variants for ring. Ring is already a utility slot. 1 ring base with broad tags is better than 3 ring bases with narrow tags.

### 2b. Affix pool dilution

**The problem:** Currently there are 18 prefixes and 9 active suffixes in ItemAffixes. Adding spell damage (flat + %) adds at minimum 4-5 new prefixes (flat spell per element, % spell damage) and 1-2 suffixes (cast speed). The weapon prefix pool goes from 9 offensive prefixes to 14+. When rolling a Runic Hammer on a weapon, the chance of hitting a useful physical damage mod drops from ~1/9 to ~1/14 (36% dilution).

**Why this kills crafting feel:** The core loop is "hammer strike matters." If the pool is so diluted that most hammer strikes give unwanted mods, the crafting loop feels like slot machine gambling rather than directed crafting. The Tag Hammers (Fire, Cold, Lightning, Physical, Defense) help but only for Forge-equivalent operations at P1+.

**Hammertime-specific risk:** The existing tag filtering system uses `valid_tags` on items to constrain which affixes can roll. If str/int/dex items all share the same WEAPON tag, they can roll each other's mods. A Staff rolling "Physical Damage" or a Sword rolling "Spell Damage" is confusing and wasteful.

**Prevention:**
- Use archetype tags (Tag.STRENGTH, Tag.DEXTERITY, Tag.INTELLIGENCE) on item bases. Spell damage affixes get Tag.INTELLIGENCE. Attack damage affixes get Tag.STRENGTH or Tag.ATTACK. The valid_tags system already supports this without code changes to the rolling logic in Item.add_prefix()/add_suffix().
- Do NOT add spell affixes to the global pool that all WEAPON items can roll. Scope them to items with the INT tag.
- Keep total rollable affixes per item base roughly constant. If a str weapon can roll 9 prefixes and an int weapon can roll 9 prefixes, the pool size per item is unchanged even though the global pool grew.

### 2c. Tag hammer effectiveness diluted

**The problem:** Tag Hammers (Fire, Cold, Lightning, Physical, Defense) guarantee at least one mod with the target tag. If spell damage affixes also carry element tags (e.g., "Flat Spell Fire Damage" with Tag.FIRE), the Fire Hammer on a str weapon might guarantee a spell damage mod on an item that cannot use it -- if the spell mod passes the tag filter but the item has no spell channel.

**Prevention:**
- Spell damage affixes should carry Tag.INTELLIGENCE (or Tag.SPELL) in addition to element tags. Str weapons without Tag.INTELLIGENCE in valid_tags never see them in the valid pool. The tag hammer then naturally selects from the correct subset.
- Test every tag hammer against every item base: verify no nonsensical guarantees.

---

## 3. Architecture Pitfalls -- Breaking Existing Systems

### 3a. Save format migration (v4 -> v5)

**The problem:** Item.create_from_dict() uses a match statement on item_type_str with 5 hardcoded cases (LightSword, BasicArmor, BasicHelmet, BasicBoots, BasicRing). Adding 10 new base types requires 10 new match arms. If a player loads a v4 save, all items are old types. If you rename LightSword to StrSword, every saved weapon becomes null (push_warning path in create_from_dict).

**Hammertime-specific risk:** The project already deleted v2/v3 saves rather than migrating them. But v4 saves represent real player progress through the prestige system (up to 7 prestige levels). Deleting them is much more costly.

**Prevention:**
- Keep LightSword as-is. It IS the str sword. Add new classes (Staff, Wand, etc.) alongside it.
- Add new match arms to create_from_dict() for new types. Old saves deserialize fine because old type strings still work.
- Bump save format to v5. Write a _migrate_v4_to_v5() that adds any new fields to existing items (e.g., a `damage_channel` field defaulting to "attack" for all old items).
- Test: create a v4 save, load it in v5 code, verify all items survive with correct stats.

### 3b. StatCalculator assumptions about single damage channel

**The problem:** StatCalculator.calculate_dps() assumes a single damage pipeline: base_damage -> flat -> % -> speed -> crit. calculate_damage_range() assumes all damage is attack damage routed through weapon base. Adding spell damage means either:
1. Two parallel calls to calculate_dps() (one for attack, one for spell), or
2. A unified calculate_dps() that sums both channels.

Option 1 risks doubling crit scaling (crit applies to both channels independently). Option 2 requires significant refactoring of the DPS method signature.

**Prevention:**
- Extend calculate_damage_range() to accept a channel parameter ("attack" or "spell"). Filter affixes by channel tag before accumulating. Return per-channel ranges.
- Hero.damage_ranges (currently used by CombatEngine for per-element rolling) should become Hero.attack_damage_ranges and Hero.spell_damage_ranges.
- CombatEngine._on_hero_attack() fires from hero_attack_timer using attack ranges. A new _on_hero_cast() fires from hero_cast_timer using spell ranges.
- Do NOT let crit stats double-apply. Either crit applies once to the sum, or each channel has its own crit that does not stack additively.

### 3c. CombatEngine dual timer complexity

**The problem:** CombatEngine currently has hero_attack_timer and pack_attack_timer (2 timers). Adding a spell cast timer makes 3 timers total. The state machine (IDLE, FIGHTING, MAP_COMPLETE, HERO_DEAD) now has more edge cases: what if the spell timer fires during pack_transition_delay? What if the hero dies between an attack and a cast?

**Prevention:**
- Only add spell timer if the hero has spell damage > 0. If no spell mods equipped, no spell timer runs. This keeps the default case identical to current behavior.
- Spell timer obeys the same state guards that _on_hero_attack() uses: `if state != State.FIGHTING: return`.
- _stop_timers() must stop all 3 timers. Add spell_cast_timer to the stop list.
- Consider a single hero timer that alternates between attack and cast if both are active (simpler state, but changes DPS math -- probably not worth the tradeoff).

### 3d. Item type string registry fragility

**The problem:** ITEM_TYPE_STRINGS is a const PackedStringArray and create_from_dict() is a match statement. Both must be updated in lockstep for every new base type. Adding 10 bases means 10 error-prone manual entries.

**Prevention:**
- Consider a registry Dictionary mapping string -> Script. New bases register themselves. Reduces match statement maintenance.
- At minimum, add integration tests that verify every entry in ITEM_TYPE_STRINGS round-trips through to_dict()/create_from_dict().

### 3e. Weapon.update_value() single-channel assumption

**The problem:** Weapon.update_value() calls StatCalculator.calculate_dps() with self.base_damage and self.base_speed. A spell weapon (Staff) would need a different base damage and base cast speed. If Staff extends Weapon, it inherits base_damage_min/max and base_attack_speed fields that are semantically wrong for spells.

**Prevention:**
- Staff should extend Weapon but use its own fields: base_spell_min, base_spell_max, base_cast_speed. Or generalize Weapon to have channel-agnostic field names.
- Better: keep Weapon as the base class with generic damage fields. The "channel" is metadata (a tag or enum), not a class hierarchy difference. A Staff's base_damage_min/max represents spell base damage. The channel tag tells StatCalculator which formula to use.

---

## 4. UX Pitfalls -- Overwhelming Player Choice in an Idle Game

### 4a. Item type buttons explosion

**The problem:** ForgeView has 5 item type buttons (Weapon, Helmet, Armor, Boots, Ring). With 3 bases per slot, the player needs to see which archetype each inventory item is. Options: (a) show 15 buttons -- does not fit 1280x720 viewport, (b) show 5 slot buttons then 3 sub-buttons -- adds navigation layer, (c) show 5 slot buttons and mix archetypes in the same 10-item array.

**Prevention:**
- Keep 5 slot buttons. Show all bases for that slot in the existing 10-item inventory grid. Differentiate by name/color (e.g., "Light Sword" vs "Staff" vs "Dagger" in the item name label).
- Do not sub-navigate. Idle game players want fewer clicks, not more.
- Archetype identity should be visible at a glance: item name or a small icon/color indicator.

### 4b. Tooltip and stat comparison complexity

**The problem:** Stat comparison on equip hover currently shows damage delta and defense delta. With dual channels, a spell weapon replacing an attack weapon shows "-500 attack DPS, +400 spell DPS." Is that better? The is_item_better() function currently uses tier comparison for bench selection. Tier still works for same-archetype items, but a tier 3 Staff is not comparable to a tier 3 Sword if the player is building for attacks.

**Prevention:**
- Comparison should use combined DPS (attack + spell) for offensive items. This gives a single number that captures overall damage change.
- Keep tier as the auto-bench heuristic. Manual equip uses stat comparison.
- Add a clear label: "[Attack]" or "[Spell]" next to the item name so the player knows what channel the item supports.

### 4c. New player confusion at prestige 0

**The problem:** At P0, only tier 8 items drop and only basic hammers are available. If all 3 archetypes drop at P0, new players see Staffs with no way to make spell damage work (no cast timer implementation, no spell affixes in the pool). The items are mechanically dead but fill inventory slots.

**Prevention:**
- Gate int archetype behind prestige. P0 = str only (current items, no changes). P1 = dex unlocked. P2 = int unlocked. This matches the existing prestige unlock pattern (tag hammers at P1, higher tiers at P1+).
- Alternative: all archetypes available from P0 but each archetype can roll appropriate mods from the start. Str items roll attack mods, dex items roll evasion/crit, int items roll ES/defensive mods. Spell damage channel (the offensive payoff for int) unlocks at P1.
- Best for v1.8: all 3 archetypes drop, each with correct tags so they roll useful mods within their domain. Spell damage as a new offensive channel can land in this milestone if the combat engine changes are scoped tightly.

### 4d. Crafting decision paralysis

**The problem:** Currently the player has one weapon base, one armor base, etc. The decision is "craft this item or melt it." With 3 bases per slot, the decision becomes "which base to craft AND which mods to aim for." In an idle game, players check in for 30-second sessions. Adding a strategic layer that requires comparing 3 base types across 5 slots is 15 decisions per gear cycle.

**Prevention:**
- Make archetype choice obvious: str = big damage, dex = speed + crit, int = spell/ES. If the player wants more DPS, pick str weapon. The choice should take 2 seconds, not 2 minutes.
- Show archetype strength as a single word or icon on the item button. Do not require reading affix lists to understand what each base is for.

### 4e. Spell builds must work on auto-pilot

**The problem:** In an active ARPG, spell builds use player-timed abilities, mana management, and positioning. In Hammertime, combat is fully automated. Spell damage needs to fire automatically like attacks do.

**Prevention:**
- Spells fire on a timer identical in structure to the attack timer. No mana cost gating idle DPS (mana exists as a stat type but has no gameplay effect -- adding mana cost for spells creates a resource management problem that fights the idle loop).
- Do not add cooldowns, ability selection, or mana management. These are anti-idle mechanics.
- The hero always uses both attack and spell if both have damage. No "mode switching" required.

---

## 5. Prevention Strategies Summary

### Effort-ranked prevention table

| Category | Strategy | Effort | Impact |
|----------|----------|--------|--------|
| **Bloat** | Archetype tags on bases constrain affix pool per item via existing valid_tags | Low | Critical |
| **Architecture** | Keep old item classes, add new ones alongside (no rename/delete) | Low | Critical |
| **UX** | Keep 5 slot buttons, mix archetypes in same 10-item inventory | Low | High |
| **UX** | Spells fire automatically on timer, no mana gating | Low | High |
| **Balance** | Spreadsheet-verify T1 attack vs T1 spell DPS within 10% | Low | Critical |
| **Architecture** | Guard spell timer with "if spell_damage > 0" | Low | High |
| **UX** | Combined DPS for stat comparison headline number | Low | Medium |
| **Balance** | Separate speed stat types (INCREASED_ATTACK_SPEED vs INCREASED_CAST_SPEED) | Medium | High |
| **Architecture** | Save v5 migration defaults old items to attack channel | Medium | Critical |
| **Architecture** | Channel-parameterized StatCalculator.calculate_damage_range() | Medium | Critical |
| **Bloat** | Weight drops toward equipped archetype (implicit loot filter) | Medium | Medium |
| **Bloat** | Test every tag hammer against every item base for nonsensical guarantees | Medium | High |

### Critical path (do these first or risk cascading rework)

1. **Define archetype tags** before adding any new item bases. Add Tag.STRENGTH, Tag.DEXTERITY, Tag.INTELLIGENCE constants. Add Tag.SPELL for spell affixes. Put archetype tags in valid_tags on each item base. This single decision constrains all downstream affix pool and tag hammer behavior.

2. **Extend StatCalculator with channel awareness** before adding spell affixes. calculate_damage_range() needs to filter by channel or DPS numbers are wrong everywhere (hero panel, item comparison, combat engine).

3. **Test save round-trip** for every new item type before shipping. One missing match arm in create_from_dict() = silently lost player items on load.

4. **Spreadsheet balance** attack vs spell at T1 and T8 before tuning any other numbers. If the channels are not within 10% at extremes, they will not be balanced at any point in between.

### Anti-patterns to avoid

- **Do not** add Tag.SPELL to the existing valid_tags on current items (LightSword, BasicArmor, etc.). Current items are attack items. Spell is a new channel for new bases only.
- **Do not** add mana as a spell gating resource for idle combat. Mana exists as a stat type (FLAT_MANA) but has no gameplay effect. Adding mana cost for spells creates a resource management problem that directly conflicts with the idle loop.
- **Do not** create hybrid bases that roll both attack and spell offensive mods. Every base should clearly be one archetype. Rings can be the exception as the utility slot.
- **Do not** add more than 2-3 new tag constants. Reuse existing tags (FIRE, COLD, LIGHTNING, PHYSICAL, DEFENSE, WEAPON, ATTACK) and add only SPELL and the 3 archetype tags as new discriminators.
- **Do not** show "Spell DPS: 0" on attack items or "Attack DPS: 0" on spell items. If a channel is inactive, hide it entirely. Zero is noise, not signal.
- **Do not** rename or remove LightSword, BasicArmor, BasicHelmet, BasicBoots, or BasicRing. These are the str archetype. Add dex and int classes alongside them.

---

*Research completed 2026-03-06 for v1.8 Content Pass planning.*
