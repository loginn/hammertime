# Feature Research

**Domain:** Idle ARPG Save/Load, UI Layout, Crafting UX, Balance Tuning
**Researched:** 2026-02-17
**Confidence:** MEDIUM

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete.

#### Save/Load System

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Auto-save on progress | Idle games run in background; players expect zero loss on crash/close | LOW | Standard in idle games: 20-30 min intervals or on significant events |
| User data directory persistence | Modern games save to platform-specific user folders | LOW | Godot's `user://` path handles this automatically |
| Multiple save slots | Players want to test builds or restart without losing main progress | MEDIUM | Optional for MVP but commonly expected |
| Save format versioning | Updates shouldn't corrupt saves | MEDIUM | Critical for live games; use version field in save data |
| Restore from backup | Protect against corruption | MEDIUM | Keep 2-3 backup saves (main + previous 10-20 min) |

#### Side-by-Side Equipment/Crafting UI

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Simultaneous visibility | Switching views is tedious; ARPGs show equipment + inventory together | MEDIUM | Core UX improvement; reduces clicks |
| Equipment slot visibility | Players need to see what's equipped while crafting | LOW | Already exists; needs layout integration |
| Click-to-equip | Fast mass-equipping when focused | LOW | Already implemented in hero_view.gd |
| Hover tooltips | Show item stats on hover | LOW | Already implemented for equipped items |
| Visual slot states (empty/filled) | Instant recognition of gear gaps | LOW | Already implemented via color modulation |

#### Crafting UX Feedback

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Before/after stat comparison | ARPGs (Diablo 4, PoE) show stat deltas when modifying items | MEDIUM | Critical for informed crafting decisions |
| Hammer tooltips | Players need to know what currency does before using it | LOW | Missing; each hammer should explain effect |
| Visual/audio feedback on craft | Satisfying feedback loop; standard in all games | LOW | Sound effects for success/failure states |
| Currency count visibility | Players need to know budget before crafting | LOW | Already implemented in button text |
| Undo last craft | Prevents catastrophic mistakes | HIGH | Most ARPGs don't have this; use autosave instead |

#### Early-Game Balance

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Starter gear | Fresh heroes shouldn't fight naked; tutorial expects success | LOW | Provide basic weapon/armor at start |
| Tutorial difficulty ramp | Level 1 must be easy; idle games need accessible beginnings | LOW | Reduce monster damage/HP for first area |
| Visible progression feedback | Players need to see numbers go up early | LOW | Floating damage already exists; ensure positive feedback |
| Forgiving resource economy | Early levels shouldn't require grinding | LOW | Ensure hammer drops are generous at start |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not required, but valuable.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Cloud save sync | Cross-device play for idle games is premium feature | HIGH | Defer to post-MVP; requires backend |
| Export/import save strings | Community build sharing; modding-friendly | MEDIUM | Low-effort differentiator; base64 encode save JSON |
| Crafting preview mode | "Try before you buy" - preview hammer result without spending | MEDIUM | Unique to Hammertime; reduces anxiety |
| Drag-and-drop equipping | More satisfying than click; feels premium | MEDIUM | Nice-to-have; click-to-equip works for idle games |
| Crafting history log | Show last 10 crafts with undo capability | MEDIUM | Addresses "oops I misclicked" pain point |
| Stat overflow auto-scroll | ScrollContainer auto-handles long stat lists | LOW | Solves current pain point; quality-of-life win |
| Side-by-side comparison panel | Show equipped item vs crafted item stats simultaneously | MEDIUM | Informed decisions; reduces mental load |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Manual save only | "Player control over saves" | Idle games crash; players forget to save and lose hours | Auto-save + manual save option |
| Unlimited undo | "Fix all mistakes" | Trivializes crafting; removes risk/reward tension | Autosave before crafting session |
| Real-time cloud sync | "Never lose progress" | Complexity, cost, latency; overkill for single-player | Local save + export/import strings |
| Drag-and-drop-only | "Feels more tactile" | Slower for mass operations; accessibility issues | Support both drag and click |
| Crafting confirmation dialogs | "Prevent mistakes" | Breaks flow; tedious for iterative crafting | Undo last craft or autosave instead |

## Feature Dependencies

```
Save/Load System
    └──requires──> Serialization format (JSON/Resource)
    └──requires──> GameState centralization (already exists)

Side-by-Side Layout
    └──requires──> UI restructure (hero_view + crafting_view merge)
    └──enhances──> Crafting UX (visibility while crafting)

Crafting UX Feedback
    └──requires──> Before/after stat calculation
    └──requires──> Hammer tooltip system
    └──enhances──> Side-by-Side Layout (comparison panel)

Balance Tuning
    └──requires──> Starter gear items
    └──requires──> Monster damage/HP adjustments
    └──conflicts──> Current level 1 difficulty (too hard)

Stat Overflow Fix
    └──requires──> ScrollContainer on stats panels
    └──independent──> Other features (cosmetic fix)

Crafting Preview Mode
    └──requires──> Deep copy of item for simulation
    └──requires──> Before/after comparison
    └──enhances──> Crafting UX
```

### Dependency Notes

- **Save/Load requires GameState centralization:** All state already flows through `game_state.gd` autoload, making serialization straightforward
- **Side-by-Side enhances Crafting UX:** Visibility of equipment while crafting reduces cognitive load
- **Crafting Preview requires Before/after comparison:** Preview is superset of comparison feature
- **Balance Tuning conflicts with current difficulty:** Level 1 is currently too hard; needs explicit nerfs

## MVP Definition

### Launch With (v1.3 milestone)

Minimum viable product — what's needed to validate the concept.

- [x] **Auto-save system** — Core feature; prevents progress loss (critical for idle games)
- [x] **User directory persistence** — Table stakes; use Godot's `user://` path
- [x] **Side-by-side equipment/crafting layout** — Solves view-switching pain point
- [x] **Hammer tooltips** — Players need to know what currency does before spending
- [x] **Before/after stat comparison** — Informed crafting decisions; expected in ARPGs
- [x] **Starter gear (weapon + armor)** — Fresh heroes need basic equipment to survive level 1
- [x] **Level 1 balance tuning** — Reduce difficulty so tutorial is accessible
- [x] **Stat overflow fix** — Current pain point; prevents stat lists from breaking viewport
- [x] **Crafting audio/visual feedback** — Satisfying feedback loop; low effort, high impact

### Add After Validation (v1.x)

Features to add once core is working.

- [ ] **Export/import save strings** — When players want to share builds or backup saves
- [ ] **Crafting preview mode** — When crafting anxiety becomes pain point
- [ ] **Crafting history with undo** — When "misclick" complaints arise
- [ ] **Drag-and-drop equipping** — When polish pass happens
- [ ] **Multiple save slots** — When players request build experimentation
- [ ] **Side-by-side comparison panel** — Enhancement to before/after comparison

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] **Cloud save sync** — Requires backend infrastructure; overkill for single-player
- [ ] **Real-time save conflict resolution** — Only needed if cloud sync added
- [ ] **Crafting simulation API** — Only if modding community emerges

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Auto-save system | HIGH | MEDIUM | P1 |
| Side-by-side layout | HIGH | MEDIUM | P1 |
| Hammer tooltips | HIGH | LOW | P1 |
| Before/after comparison | HIGH | MEDIUM | P1 |
| Starter gear | HIGH | LOW | P1 |
| Level 1 balance tuning | HIGH | LOW | P1 |
| Stat overflow fix | MEDIUM | LOW | P1 |
| Crafting feedback (sound/visual) | MEDIUM | LOW | P1 |
| Export/import saves | MEDIUM | MEDIUM | P2 |
| Crafting preview mode | MEDIUM | MEDIUM | P2 |
| Crafting history/undo | MEDIUM | MEDIUM | P2 |
| Drag-and-drop equip | LOW | MEDIUM | P2 |
| Multiple save slots | MEDIUM | LOW | P2 |
| Side-by-side comparison panel | MEDIUM | MEDIUM | P2 |
| Cloud save sync | LOW | HIGH | P3 |

**Priority key:**
- P1: Must have for launch (v1.3 milestone)
- P2: Should have, add when possible (v1.4+)
- P3: Nice to have, future consideration (v2+)

## Implementation Details by Feature Area

### Save/Load System

**What to persist:**
- Hero equipment (5 slots: weapon, helmet, armor, boots, ring)
- Currency counts (6 hammer types)
- Crafting inventory (5 slots: weapon, helmet, armor, boots, ring)
- Current crafting item (if in-progress)
- Combat state (current area, pack progress)

**Save frequency patterns (from research):**
- **Idle Wizard:** Every 30 minutes
- **NGU IDLE:** Every 10-20 minutes + 2 backup files
- **Recommended:** Every 5 minutes + on significant events (item crafted, area completed, currency spent)

**Format choice:**
- **JSON:** Human-readable, debuggable, easy export/import (recommended for MVP)
- **Godot Resource:** Type-safe, editor-inspectable, harder to manually edit
- **Binary:** Fast, compact, not human-readable (defer until performance issues)

**Implementation approach:**
- Create `SaveGame` resource or Dictionary with version field
- Serialize `GameState` autoload to JSON using `var_to_str()` or `JSON.stringify()`
- Write to `user://saves/autosave.json` every 5 minutes via Timer
- Keep 3 backups: `autosave.json`, `autosave_backup1.json`, `autosave_backup2.json`
- Load on `_ready()` if save exists

### Side-by-Side UI Layout

**Current state (from code analysis):**
- 3 separate views: `hero_view.tscn`, `crafting_view.tscn`, `gameplay_view.tscn`
- Switching between hero/crafting is tedious
- Equipment slots in hero_view, crafting in crafting_view

**Target layout:**
```
┌─────────────────────────────────────────┐
│  Combat Area (top, existing)            │
├──────────────────┬──────────────────────┤
│  Equipment       │  Crafting            │
│  - 5 slots       │  - Item type buttons │
│  - Stats panel   │  - Hammer buttons    │
│  - Item stats    │  - Current item      │
│                  │  - Inventory panel   │
└──────────────────┴──────────────────────┘
```

**Implementation approach:**
- Merge hero_view and crafting_view into single scene
- Use HBoxContainer to split left (equipment) and right (crafting)
- Keep existing signals and state management
- Update main_view navigation to show merged view

### Crafting UX Feedback

**Before/After Comparison:**
- When hovering over hammer button, show projected stats if applied
- Format: `Current: 10 DPS → After: 12 DPS (+2)`
- Color code: green for improvements, red for downgrades (if applicable)

**Hammer Tooltips:**
- Add `description` field to Currency base class
- Show on button hover: "Runic Hammer: Upgrades Normal item to Magic rarity"
- Include validation rules: "Requires: Normal rarity item"

**Crafting Feedback:**
- Sound effects from libraries like [BOOM Library Modern UI](https://www.boomlibrary.com/sound-effects/modern-ui/)
- Visual: brief flash/glow on item_view when hammer applied
- Floating text showing affix added (reuse floating_label.gd)

### Early-Game Balance

**Current pain points (from milestone context):**
- Level 1 too hard for fresh heroes
- No starter gear; hero starts naked

**Starter gear approach:**
- Generate basic weapon (LightSword tier 0) on new game
- Generate basic armor (BasicArmor tier 0) on new game
- Auto-equip both on game start
- Provide 5-10 of each hammer type as starting currency

**Level 1 tuning:**
- Reduce monster damage by 30-50% for first area
- Reduce monster HP by 20-30% for first area
- Increase hammer drop rates by 2x for first area
- Add visual feedback: "Tutorial Area" label

### Stat Overflow Fix

**Current issue:**
- Stats panel uses fixed-size Label
- Long stat lists (many affixes) overflow viewport
- No scrolling capability

**Solution (from Godot research):**
- Wrap stats_label in ScrollContainer
- Set ScrollContainer size constraints
- Enable vertical scroll, disable horizontal
- Let content expand naturally

**Implementation:**
```gdscript
# In hero_view.tscn scene tree:
StatsPanel (Panel)
  └─ ScrollContainer
      └─ StatsLabel (Label)
          - autowrap_mode: AUTOWRAP_WORD_SMART
          - custom_minimum_size: (0, 0)
```

## Competitor Feature Analysis

| Feature | Path of Exile | Diablo 4 | Idle Heroes | Our Approach |
|---------|---------------|----------|-------------|--------------|
| Save system | Cloud auto-save | Cloud auto-save | Cloud + local | Local auto-save (MVP), export strings (P2) |
| Crafting UI | Modal popup | Modal popup | Side panel | Side-by-side (less interruption) |
| Before/after comparison | No preview | Full preview with Shift | No preview | Hover preview (P1), full preview (P2) |
| Undo crafting | No | No | No | Autosave snapshots (P2) |
| Starter gear | Yes (basic weapon) | Yes (full set) | Yes (auto-equip) | Yes (weapon + armor) |
| Drag-and-drop | Yes | Yes | Click only | Click (P1), drag (P2) |

## Sources

**Godot Save/Load Best Practices:**
- [GDQuest: Saving and Loading Games in Godot 4](https://www.gdquest.com/library/save_game_godot4/)
- [GDQuest: Save and Load Cheat Sheet](https://www.gdquest.com/library/cheatsheet_save_systems/)
- [Kids Can Code: Saving/loading data in Godot 4](https://kidscancode.org/godot_recipes/4.x/basics/file_io/index.html)
- [GDQuest: Choosing the right save game format](https://www.gdquest.com/tutorial/godot/best-practices/save-game-formats/)

**Idle Game Patterns:**
- [Idle Wizard Auto-Save Discussion](https://steamcommunity.com/app/992070/discussions/0/2247803885929795897/)
- [Game Developer: Balancing Tips for Idle Games](https://www.gamedeveloper.com/design/balancing-tips-how-we-managed-math-on-idle-idol)
- [Machinations: How to Design Idle Games](https://machinations.io/articles/idle-games-and-how-to-design-them)
- [Kongregate: The Math of Idle Games](https://blog.kongregate.com/the-math-of-idle-games-part-i/)

**ARPG Crafting UX:**
- [Diablo 4 Advanced Tooltip Compare](https://www.denofgeek.com/games/diablo-4-best-hidden-setting-compare-gear/)
- [Path of Exile Interface Design](https://interfaceingame.com/games/path-of-exile/)
- [RPGCodex: Drag-and-Drop vs Click-to-Equip Discussion](https://rpgcodex.net/forums/threads/drag-and-drop-from-inventory-to-equipment-slot-or-click-to-equip.141654/)

**Game UI Patterns:**
- [Game UI Database - Inventory Browse](https://www.gameuidatabase.com/index.php?scrn=71)
- [Medium: UX and UI in Game Design](https://medium.com/@brdelfino.work/ux-and-ui-in-game-design-exploring-hud-inventory-and-menus-5d8c189deb65)

**Crafting Feedback:**
- [BOOM Library: Modern UI Sound Effects](https://www.boomlibrary.com/sound-effects/modern-ui/)
- [A Sound Effect: How to Succeed in UI/UX Sound Design](https://www.asoundeffect.com/sound-success-ui-ux-sound-design-adr-audio-programming/)

**Early Game Balance:**
- [MapleStory Idle RPG Beginner Guide](https://www.ldcloud.net/blog/maplestory-idle-rpg-en-beginner-guide)
- [Melvor Idle Combat Guide](https://wiki.melvoridle.com/w/Combat_Guide)
- [Lootfiend Idle Dungeons Build Guide](https://www.bluestacks.com/blog/game-guides/lootfiendidle-dungeons/lfid-builds-guide-en.html)

**Godot ScrollContainer:**
- [Godot ScrollContainer Documentation](https://docs.godotengine.org/en/stable/classes/class_scrollcontainer.html)
- [Godot Forum: ScrollContainer and Scrollbar Activation](https://forum.godotengine.org/t/how-to-stop-scrollcontainer-from-not-activating-scrollbar-and-resizing-contents-to-fit-in-the-box/64615)

---
*Feature research for: Hammertime v1.3 Milestone (Save/Load, UI Layout, Crafting UX, Balance)*
*Researched: 2026-02-17*
*Confidence: MEDIUM (WebSearch primary source; Godot docs verified via official documentation)*
