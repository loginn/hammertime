# Research Summary: v1.8 Content Pass — Items & Mods

**Synthesized:** 2026-03-06
**Sources:** STACK.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md

---

## Key Findings

### Stack Additions
- **3 new StatTypes:** FLAT_SPELL_DAMAGE, INCREASED_SPELL_DAMAGE, INCREASED_CAST_SPEED
- **1 new functional Tag:** SPELL (analogous to ATTACK)
- **3 metadata Tags:** STR, DEX, INT (archetype identity on items)
- No new intermediate classes needed — new items extend existing Weapon/Armor/Helmet/Boots/Ring

### Feature Table Stakes
- 3 defense types tied to archetypes (Armor=STR, Evasion=DEX, ES=INT) — universal ARPG convention
- Base stats signal archetype identity before crafting (name + defense type)
- Weapon type determines damage channel (attack vs spell)
- Implicit mods differ by archetype (attack speed vs crit chance vs spell damage)
- Shared suffix pool (life, resistances), split prefix pool (attack vs spell offense)

### Architecture Impact
- **10 new concrete item files** (2 per slot alongside existing 5)
- **Save format v4 is sufficient** — no version bump needed. New item types add match arms to create_from_dict(). New StatType enum values append without breaking existing indices. Spell weapon fields default to 0.
- **Existing valid_tags mechanism** handles all archetype affix filtering with zero code changes to rolling logic
- **CombatEngine gets third timer** (hero_spell_timer) — highest-risk change, guarded by "if cast_speed > 0"
- **StatCalculator gets parallel spell methods** — calculate_spell_damage_range(), calculate_spell_dps()
- **DefenseCalculator unchanged** — is_spell parameter already exists

### Watch Out For
1. **Channel dominance** — spreadsheet-verify T1 attack vs T1 spell DPS within 10%
2. **Base proliferation** — drop targeting goes from 20% to 6.7%. Use slot-first-then-archetype drops
3. **Affix pool dilution** — keep per-item rollable pool constant (~9 prefixes) even as global pool grows. Use valid_tags to constrain
4. **Hybrid builds** — don't let items roll both attack and spell offensive mods. Each base is one archetype
5. **Spells must auto-pilot** — no mana costs, no cooldowns, fire on timer like attacks
6. **Don't rename existing items** — LightSword/BasicArmor/etc. stay as-is (str archetype). Add dex/int alongside

### Build Order (lowest to highest risk)
1. Tag + StatType foundation
2. Spell affixes in item_affixes.gd
3. New str/dex item bases (no spell dependency)
4. Weapon spell fields + Hero spell stats
5. StatCalculator spell methods
6. Int item bases (SpellStaff exercises spell path)
7. CombatEngine spell timer (highest risk)
8. UI polish (hero view, tooltips, floating damage)

### Anti-Features (explicitly avoid)
- No attribute requirements (STR/DEX/INT as hero stats)
- No class system — items carry archetype identity
- No dual-wielding — single weapon slot
- No mana costs for spells
- No spell skill selection — auto-cast on timer
- No hybrid bases that roll both attack + spell offense

---

## Proposed Item Bases (15 total)

| Slot | STR | DEX | INT |
|------|-----|-----|-----|
| Weapon | LightSword (existing) | Dagger | Wand |
| Armor | BasicArmor (existing) | LeatherArmor | SilkRobe |
| Helmet | BasicHelmet (existing) | LeatherHood | Circlet |
| Boots | BasicBoots (existing) | LeatherBoots | SilkSlippers |
| Ring | BasicRing (existing) | JadeRing | SapphireRing |

### Archetype Identity Through Base Stats

| Archetype | Primary Defense | Offense Identity | Key Implicit |
|-----------|----------------|------------------|-------------|
| STR | Armor | High attack damage, slow | Attack Speed (LightSword) |
| DEX | Evasion | Fast attack, crit-focused | Crit Chance (Dagger) |
| INT | Energy Shield | Spell damage, cast speed | Spell Damage (Wand) |

## Proposed New Affixes

| Affix | Type | Tags | StatType | Status |
|-------|------|------|----------|--------|
| Flat Spell Damage | PREFIX | SPELL, FLAT, WEAPON | FLAT_SPELL_DAMAGE | New |
| %Spell Damage | PREFIX | SPELL, PERCENTAGE, WEAPON | INCREASED_SPELL_DAMAGE | New |
| Cast Speed | SUFFIX | SPEED, SPELL | INCREASED_CAST_SPEED | Enable (disabled stub) |
| Evade | SUFFIX | DEFENSE, EVASION | FLAT_EVASION | Enable (disabled stub) |

## Confidence Assessment

| Area | Confidence |
|------|------------|
| Stack (StatTypes, Tags) | HIGH — mirrors existing patterns exactly |
| Features (archetype triangle) | HIGH — universal ARPG convention, 20+ years of design iteration |
| Architecture (integration points) | HIGH — direct codebase analysis of all affected files |
| Pitfalls (balance, bloat) | HIGH — grounded in specific code paths; balance numbers need playtesting |

---
*Synthesized from 4 parallel research agents, 2026-03-06*
