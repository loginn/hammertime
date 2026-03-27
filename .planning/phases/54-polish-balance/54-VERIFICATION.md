---
phase: 54-polish-balance
verified: 2026-03-27T00:00:00Z
status: human_needed
score: 4/4 must-haves verified
human_verification:
  - test: "Visual stat panel — hero with archetype"
    expected: "Hero title in archetype color (red/green/blue) appears above 'Passive:' label, indented bonus lines, blank line, then 'Offense:' section"
    why_human: "BBCode color rendering in RichTextLabel cannot be verified without running Godot; confirms layout matches design spec D-01 through D-03"
  - test: "Visual stat panel — Classless Adventurer (P0)"
    expected: "Stat panel shows no hero title or passive section — starts directly at 'Offense:'"
    why_human: "Null-archetype path produces empty string then appends Offense — correct layout must be eyeballed in running game"
  - test: "Stat comparison hover does not change hero section"
    expected: "Hovering equip/item slot shows stat comparison; releasing hover restores hero section unchanged"
    why_human: "Early-return branch behavior requires interactive testing; grep confirms branches return early but UI flow is runtime-only"
---

# Phase 54: Polish-Balance Verification Report

**Phase Goal:** Display hero bonuses in ForgeView stat panel, verify all 9 heroes across all damage channels, and tune bonus magnitudes.
**Verified:** 2026-03-27
**Status:** human_needed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Note on "Tune Bonus Magnitudes"

The phase goal statement includes "tune bonus magnitudes." The CONTEXT.md (D-06/D-07) explicitly resolved this: bonus magnitudes were locked as-is and tuning was deferred to a future balance pass. This is a design decision, not a gap — the goal's tuning component was answered by "no changes needed."

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Hero with an archetype sees their title and passive bonuses above the Offense section in the stat panel | ? HUMAN | Code path verified — BBCode render requires running game |
| 2 | Classless Adventurer (null archetype) sees no hero title or passive section — stat panel starts at Offense | ? HUMAN | Code path verified — null guard produces `""` then `+= "Offense:\n"` |
| 3 | Hero title is displayed in the archetype color (red/green/blue) | ? HUMAN | BBCode `[color=#hex]` pattern confirmed in code; render requires running game |
| 4 | Stat comparison hover mode does not alter the hero bonus section | ? HUMAN | Early-return branches at lines 662-681 confirmed unchanged; requires interactive test |

**Score:** 4/4 truths — automated evidence complete, visual confirmation required

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `scenes/forge_view.gd` | Hero bonus display in `update_hero_stats_display()` | VERIFIED | Contains `format_bonuses`, BBCode color, `Passive:` label, null guard |

### Artifact Detail — scenes/forge_view.gd

**Level 1 (Exists):** Yes — file present.

**Level 2 (Substantive):** Yes — implementation at lines 689-702:
- Line 690: `var archetype: HeroArchetype = GameState.hero_archetype` — null check
- Line 693: `hero_stats_label.text = "[color=#%s]%s[/color]\n" % [hex, archetype.title]` — BBCode colored title
- Line 694: `hero_stats_label.text += "Passive:\n"` — section label
- Line 695: `for line in HeroArchetype.format_bonuses(archetype.passive_bonuses):` — static method call
- Line 696: `hero_stats_label.text += "  %s\n" % line` — indented bonus lines
- Line 699: `hero_stats_label.text = ""` — classless Adventurer empty path
- Line 702: `hero_stats_label.text += "Offense:\n"` — append (not assign) preserves hero block

**Level 3 (Wired):**
- `hero_stats_label` is `@onready var hero_stats_label: RichTextLabel` (line 33) — connected to scene node
- Scene node `HeroStatsLabel` is `type="RichTextLabel"` with `bbcode_enabled = true` (forge_view.tscn line 387)
- `GameState.hero_archetype` is declared as `var hero_archetype: HeroArchetype = null` (game_state.gd line 25)
- `HeroArchetype.format_bonuses()` is a `static func` returning `Array[String]` (hero_archetype.gd line 139)

**Old header removed:** `grep -c "Hero Stats:" forge_view.gd` returns 0 — old `"Hero Stats:\n\nOffense:\n"` initializer fully removed.

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `scenes/forge_view.gd` | `models/hero_archetype.gd` | `HeroArchetype.format_bonuses()` and `archetype.color` | WIRED | Line 695: `HeroArchetype.format_bonuses(archetype.passive_bonuses)` — static call confirmed |
| `scenes/forge_view.gd` | `autoloads/game_state.gd` | `GameState.hero_archetype` null check | WIRED | Line 690: `var archetype: HeroArchetype = GameState.hero_archetype` — null guard at line 691 |

Note: gsd-tools `verify key-links` reported both as unverified due to regex escaping of `.` in patterns. Manual grep confirms both patterns are present.

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| PASS-03 | 54-01-PLAN.md | Hero bonus visible as separate line in ForgeView stat panel | SATISFIED | `update_hero_stats_display()` prepends hero title + Passive section before Offense; human visual confirm pending |

### 9 Heroes Across All Damage Channels

All 9 heroes are defined in `models/hero_archetype.gd` REGISTRY, covering all damage channels:

| Hero | Archetype | Subvariant | Channel Bonuses |
|------|-----------|------------|-----------------|
| The Berserker (str_hit) | STR | Hit | +25% Attack Damage, +25% Physical Damage |
| The Reaver (str_dot) | STR | DoT | +25% Attack Damage, +20% Bleed Chance, +15% Bleed Damage |
| The Fire Knight (str_elem) | STR | Elemental | +25% Attack Damage, +25% Fire Damage |
| The Assassin (dex_hit) | DEX | Hit | +15% Damage, +25% Physical Damage |
| The Plague Hunter (dex_dot) | DEX | DoT | +15% Damage, +20% Poison Chance, +15% Poison Damage |
| The Frost Ranger (dex_elem) | DEX | Elemental | +15% Damage, +25% Cold Damage |
| The Arcanist (int_hit) | INT | Hit | +25% Spell Damage, +25% Physical Damage |
| The Warlock (int_dot) | INT | DoT | +25% Spell Damage, +20% Burn Chance, +15% Burn Damage |
| The Storm Mage (int_elem) | INT | Elemental | +25% Spell Damage, +25% Lightning Damage |

All 13 `BONUS_LABELS` keys are mapped, covering: attack, spell, general damage, physical, fire, cold, lightning, bleed/poison/burn chance and damage.

### Bonus Magnitude Tuning

Decision D-06 (CONTEXT.md): magnitudes locked as-is. D-07: tuning deferred to future balance pass. This component of the phase goal was explicitly resolved by design decision — no code change was needed or appropriate.

### REQUIREMENTS.md Traceability Table

The traceability table (lines 44-55) shows all requirements as "not started" — this is a known stale artifact. The checkbox list at the top of REQUIREMENTS.md (lines 6-22) correctly marks all v1.9 requirements as `[x]` completed, which is the authoritative status. The table was not updated during phase execution; this is an administrative gap, not an implementation gap.

---

## Anti-Patterns Found

No anti-patterns detected in `scenes/forge_view.gd`:
- No TODO/FIXME/placeholder comments
- No empty implementations (return null, return {})
- No hardcoded empty data arrays
- All hero stat display paths are substantive

---

## Human Verification Required

### 1. Hero Stat Panel Visual — Archetype Hero

**Test:** Start Godot, prestige to P1, select any STR hero (e.g., The Berserker). Open Forge view.
**Expected:** Stat panel shows: hero title in red color → "Passive:" → indented bonus lines ("+25% Attack Damage", "+25% Physical Damage") → blank line → "Offense:" → existing stats.
**Why human:** BBCode `[color=#C0392B]` rendering in RichTextLabel requires Godot runtime. Cannot verify color display or layout fidelity from code alone.

### 2. Classless Adventurer Panel

**Test:** Start a new game (P0). Open Forge view stat panel.
**Expected:** Panel shows "Offense:" directly with no hero title or passive section preceding it.
**Why human:** The null-archetype path sets `hero_stats_label.text = ""` then appends "Offense:\n" — must confirm no visual artifacts remain from old "Hero Stats:" header.

### 3. Hover Isolation

**Test:** With a hero selected, hover an equipped item slot in Forge view, then release hover.
**Expected:** During hover: stat comparison appears. After hover: hero section (title + Passive + bonuses) reappears unchanged.
**Why human:** Early-return at lines 662-681 prevents modification — confirmed by code, but the full UI interaction loop requires interactive testing to confirm no race conditions or state bleed.

---

## Commit Verification

Commit `61babaa` exists and is valid:
- Message: `feat(54-01): add hero title and passive bonus block to stat panel`
- Diff: `scenes/forge_view.gd | 16 insertions(+), 2 deletions(-)`
- Content: adds hero archetype section, removes old "Hero Stats:" initializer

---

## Summary

Phase 54 automated verification is complete. All four observable truths are substantiated by code evidence:

1. The hero section (BBCode-colored title, "Passive:" label, formatted bonus lines) is implemented at `forge_view.gd` lines 689-702.
2. The null-archetype guard correctly gates the hero section — classless Adventurer reaches "Offense:" directly.
3. BBCode `[color=#hex]` with `to_html(false)` from `archetype.color` drives title coloring; `bbcode_enabled = true` is set on the scene node.
4. Equip-hover and item-hover branches (lines 662-681) both `return` early before the hero section, leaving it static during comparison.

All 9 heroes are defined with appropriate bonuses across all 13 damage channels. Bonus magnitude tuning was explicitly locked/deferred by design decision D-06/D-07. PASS-03 is satisfied in code.

Three human verification items remain (visual layout, classless Adventurer appearance, hover isolation) — all require Godot runtime. The phase goal is achieved in code; visual approval completes it.

---

_Verified: 2026-03-27_
_Verifier: Claude (gsd-verifier)_
