# Phase 56: Difficulty & Starter Kit - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-28
**Phase:** 56-difficulty-starter-kit
**Areas discussed:** Starter item selection, Starter hammer loadout, Forest difficulty tuning, Prestige restart behavior

---

## Starter Item Selection

### Weapon matching strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Archetype-matched | Broadsword for STR, Dagger/Shortbow for DEX, Wand/Sceptre for INT | ✓ |
| Fixed Broadsword for all | Simple, one item type. Was the v1.3 starter | |
| One weapon per archetype in stash | Put 3 weapons in stash, player picks | |

**User's choice:** Archetype-matched
**Notes:** None

### STR weapon

| Option | Description | Selected |
|--------|-------------|----------|
| Broadsword | Physical damage, classic STR melee weapon | ✓ |
| Warhammer | Physical damage, heavier STR weapon | |
| Battleaxe | Physical damage, another STR option | |

**User's choice:** Broadsword

### DEX weapon

| Option | Description | Selected |
|--------|-------------|----------|
| Dagger | Physical damage, fast DEX weapon | ✓ |
| Shortbow | Physical damage, ranged DEX weapon | |
| VenomBlade | Poison damage, more exotic | |

**User's choice:** Dagger

### INT weapon

| Option | Description | Selected |
|--------|-------------|----------|
| Wand | Spell damage, basic INT caster weapon | ✓ |
| Sceptre | Spell damage, alternative INT weapon | |
| LightningRod | Lightning spell damage, element-locked | |

**User's choice:** Wand

### Armor matching strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Archetype-matched | IronPlate for STR, LeatherVest for DEX, SilkRobe for INT | ✓ |
| Fixed LeatherVest for all | Neutral choice, no base armor | |
| IronPlate for all | Most protective but STR-biased | |

**User's choice:** Archetype-matched

### Starter item rarity

| Option | Description | Selected |
|--------|-------------|----------|
| Normal (blank bases) | No affixes, teaches crafting loop | ✓ |
| Magic (1-2 affixes) | Immediately usable in combat | |

**User's choice:** Normal (blank bases)

---

## Starter Hammer Loadout

### Currency name mapping

| Option | Description | Selected |
|--------|-------------|----------|
| Transmute=Runic, Augment=Forge | Natural mapping, currency keys stay as-is | |
| New currency keys needed | Transmute and Augment are new hammers | |
| Rename all to PoE conventions | (User's custom input) | ✓ |

**User's choice:** Rename all currencies to PoE conventions (Transmute, Augment, Alteration, Regal, Chaos, Exalt)
**Notes:** User reasons about currencies using PoE terminology, wants code to match

### Currency rename scope

| Option | Description | Selected |
|--------|-------------|----------|
| Defer to backlog | Rename is a cross-cutting refactor | |
| Fold into Phase 56 | Do the rename as part of this phase | ✓ |

**User's choice:** Fold into Phase 56

### Starter hammer counts

| Option | Description | Selected |
|--------|-------------|----------|
| Replace: 2 Runic + 2 Forge | Clean slate, matches DIFF-03 | ✓ |
| Add: 3 Runic + 2 Forge | Keep legacy starter on top | |

**User's choice:** Replace (2 Transmute + 2 Augment)

---

## Forest Difficulty Tuning

### Tuning approach

| Option | Description | Selected |
|--------|-------------|----------|
| Tune monster base stats | Lower Forest monster base_hp and/or base_damage | ✓ |
| Lower growth rate for early levels | Reduce 7% compounding for levels 1-24 | |
| Claude's discretion | Let planner/researcher figure out numbers | |

**User's choice:** Tune monster base stats

### Survival target

| Option | Description | Selected |
|--------|-------------|----------|
| Survive zone 1-3 with blanks | Generous, forces crafting by zone 4-5 | |
| Survive zone 1 only with blanks | Minimal breathing room, must craft immediately | ✓ |
| Survive zone 1-5 with blanks | Very generous, delays crafting need | |

**User's choice:** Survive zone 1 only with blanks

---

## Prestige Restart Behavior

### Starter kit on prestige

| Option | Description | Selected |
|--------|-------------|----------|
| Same starter kit on prestige | _wipe_run_state() gives same items as fresh game | ✓ |
| Empty stash on prestige | Harder restart, earn everything from scratch | |
| Prestige-scaled starter kit | Higher prestige = better starter items | |

**User's choice:** Same starter kit on prestige

### Timing of starter item placement

| Option | Description | Selected |
|--------|-------------|----------|
| After archetype selection | Player picks archetype first, then items appear | ✓ |
| Before archetype selection | Place generic items first | |

**User's choice:** After archetype selection

---

## Claude's Discretion

- Exact Forest monster base_hp/base_damage numbers
- Implementation details for currency rename save compat
- Which function places starter items (dedicated function vs inline)

## Deferred Ideas

- Prestige-scaled starter kit (better items at higher prestige) — future enhancement
