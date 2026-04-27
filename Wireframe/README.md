# Handoff: HammerTime M001 — Core UI

## Overview

HammerTime is an ARPG-style crafting idle game built in Godot 4. The player is a blacksmith (not an adventurer): they pick an item base, craft it using "hammer" currencies that modify items (POE-style), equip a hero, send the hero on expeditions to earn materials + more hammers, and optionally prestige at a threshold to receive 999 of every hammer.

M001 is the first playable milestone and ships **four screens**, navigated by a persistent top tab bar:

1. **The Forge** — main screen. Crafting bench + inventory + hero equipment + aggregate stats, all in one view.
2. **Expeditions** — send the hero to Iron Quarry (easy) or Steel Depths (hard) to earn bases and hammers.
3. **Prestige** — the ritual reforge screen. Spend 100 Tack Hammers → reset items/materials → receive 999 of every hammer.
4. **Settings** — save / export / import / new game.

## About the Design Files

The files under `design_files/` are **design references created in HTML/React/Babel**. They are prototypes showing intended look, layout, and behavior — not production code to copy directly. Your task is to **recreate these designs inside HammerTime's Godot 4 project** using its existing control/theme patterns.

If the codebase already has a theme/style convention, use it. If not, translate the design tokens in `design_files/tokens.css` into a Godot `Theme` resource. The `.jsx` files are component trees; read them to understand structure and behavior, then rebuild each screen as Godot scenes with Controls (`VBoxContainer`, `HBoxContainer`, `GridContainer`, `Panel`, `Button`, `RichTextLabel`, etc.).

## Fidelity

**High-fidelity.** All colors, typography, spacing, and states are final. The intent is pixel-faithful recreation at 1280×720 logical resolution, with the warm cozy-blacksmith aesthetic (deep woods, candlelight, brass, ember glow). Use the exact token values in `tokens.css`. Fonts: **Cinzel** (display), **Spectral** (serif body), **Inter** (UI), **JetBrains Mono** (mono/numbers). Numeric values should use `font-variant-numeric: tabular-nums` (`.num` class in the mock).

## Canvas

- Logical resolution: **1280 × 720**
- Top tab bar: fixed **50px** tall, spans full width
- Body: everything below the tab bar, fills the remaining **670px**

---

## Screen 1 · The Forge

3-column body grid: `250px · 1fr · 430px`, gap 10, padding 10.

### Left column — Hammers rail (250px)

- **Section tabs** (Basic / Elemental / Meta) — only Basic is unlocked in M001; Elemental and Meta render as locked placeholders for future currencies.
- **Hammer grid** — 4-column grid inside a wood panel. 7 canonical hammers + 1 empty placeholder tile. Each tile is aspect-1:1, ~56×56 at this layout.
  - Tile shows: glyph (22px) + ×count (10px mono).
  - Hover reveals a dark tooltip with name, verb, target rarity, full effect.
  - Active tile has ember border + glow. "Hot" (recommended) tile has a small ember pip top-left.
- **Selected hammer card** — below the grid. 44×44 glyph badge + name + verb + count + effect + target.
- **Legend footer** — "◆ Tap a hammer to arm it. ◆ Then tap the item to strike."

#### The 7 hammers (M001 data)

| Key | Glyph | Name | Verb | Count | Target | Effect |
|---|---|---|---|---|---|---|
| tack | ⬦ | Tack | Transmute | 47 | Normal | Normal → Magic. Adds 1–2 random affixes. |
| tuning | ◈ | Tuning | Alteration | 142 | Magic | Rerolls all affixes on a Magic item. |
| forge | ◆ | Forge | Augment | 68 | Magic | Adds 1 random affix to an unfull Magic item. |
| grand | ✦ | Grand | Regal | 18 | Magic (hot) | Magic → Rare. Adds 1 affix, keeps existing. |
| runic | ⚒ | Runic | Exalt | 4 | Rare (rare-tier) | Adds 1 random affix to an unfull Rare item. |
| scour | ◎ | Scour | Scour | 11 | Any | Strips all affixes. Back to Normal. |
| claw | ✕ | Claw | Annul | 3 | Magic/Rare | Removes 1 random affix. |

### Center column — Bench + Inventory (1fr)

Two stacked rows.

#### Bench (top row)

3-subcolumn grid `1fr · 170px · 1fr`, gap 10.

- **Prefix rail** (left): header "◆ PREFIX  1 / 3", then 3 affix scrolls — either filled (tier badge, text, roll range) or empty (dashed placeholder "vacant prefix"). Ember for suffix tone, brass/gold for prefix tone.
- **Weapon badge** (center, 130×160): parch plate with a rotated sword PNG (100×24, filter drop-shadow ember). Four 6×6 brass nails in corners.
  - Below: item name (12px, rarity-colored), meta line "MAT · BASE · Tier N" (8px mono).
  - **Stat readout panel** — primary stat (18px ember number) + label, divider, secondary (11px parch). Computed per slot:
    - Weapon → DPS (primary), Damage lo–hi (secondary), APS in unit line
    - Armor/Helmet → Armor (primary), Life (secondary)
    - Boots → Evasion (primary), Life (secondary)
    - Ring → Life (primary), Resist (secondary)
- **Suffix rail** (right): mirror of the prefix rail with ember/suffix tone.

The previous "Strike" button was removed. Crafting is triggered by clicking a hammer to arm, then clicking the item on the bench.

#### Inventory (bottom row)

- **Slot-type tabs** across the top (Weapon / Helmet / Armor / Boots / Ring) + right-aligned "N / 24" counter.
- **Grid**: 6 columns, gap 5. Each cell ≈ 70–80 × 50 min.
- First cell is always a **"+ New base" tile** — hatched background, dashed brass border, shows stockpile count "N in stock" for the active slot. Hover reveals a picker listing the player's stockpile by slot (e.g. Iron Shortsword ×3, Steel Saber ×2). Click places a fresh Normal-rarity base on the bench. Greys out with "Expedition needed" when stockpile is empty.
- **Item tiles** — rarity left-border (3px), rarity-colored name (11px, 2-line clamp), meta line (8px mono) "MAT  TN" (material abbreviation + tier).
  - "EQ" badge top-right when equipped.
  - **Melt icon** (🜂 alchemical fire symbol, 14×14 copper square) — appears top-right **on hover**, suppressed for equipped items. Hover state: copper fill, near-black glyph. Click destroys the item to reclaim material (fraction TBD by game design).
  - Hover reveals a dark tooltip: full name, rarity·material·base·Tier line, affix list with T-badges, and an "◆ Currently Equipped" line when applicable.

### Right column — Hero panel (430px)

Four stacked sections.

- **Hero portrait** — wood panel, 90×120 portrait PNG on the left, name + level + XP bar on the right.
- **Equipped slots** — wood panel with 5 slot rows (Weapon / Helmet / Armor / Boots / Ring). Clicking a slot row switches the inventory filter below. Active slot has an ember indicator. Each row shows slot icon, slot name, equipped item name (rarity-colored) or "empty" placeholder, and a small stat summary.
- **Aggregate stats** — wood panel with labeled rows (Life, Armor, Evasion, Fire Res, Cold Res, Light Res, DPS, Move Spd, …). Each row is 2-column: value + delta pill showing the change vs. currently equipped if the player were to equip the bench item (green = upgrade, red = downgrade, muted = equal).

---

## Screen 2 · Expeditions

2-column grid of expedition cards, gap 16, padding 20. Prestige has been **moved to its own screen** — do not render it here.

- Each card: difficulty label ("Expedition I / II"), 3 star pips (ember-filled), big 26px display name, flavor italic line, meta row (Material / Est. Time), Rewards list, and action block.
- **Iron Quarry** — difficulty 1, Iron material, 10s ETA, rewards: Iron bases 1–2, Tack/Tuning basic hammers, uncommon Scour.
- **Steel Depths** — difficulty 3, Steel material, 38s ETA, rewards: Steel bases 1–3, uncommon Forge/Grand, rare Runic/Claw.
- **Active** card: 14px progress bar with % label, "IN PROGRESS · ETA Ns", and a full-width "Recall Hero" button (iron background, muted red text).
- **Inactive** card: full-width "Send Hero ⚒" button (ember gradient, 14px label, letter-spacing 2).
- Only one expedition can be active at a time — the other dims to opacity 0.55 and its Send button disables.

---

## Screen 3 · Prestige

3-column grid `1fr · 580px · 1fr`, gap 24, padding `24 28`.

### Left — "You Will Sacrifice"
Wood panel with rows for each thing that resets (items, ores, ingots, expedition progress). Each row: serif label + italic sub-line + 20px display value with a **strikethrough** indicating it will be destroyed. Footer aphorism: *"The anvil does not remember. Only the hammer endures."*

### Center — The ritual
- Section eyebrow "◆ The Reforging ◆" (copper mono, 4px letter-spacing).
- Title "PRESTIGE" (38px Cinzel, brass with ember shadow).
- Italic subtitle paragraph (12px Spectral).
- **Gauge panel**: "TACK HAMMERS · THRESHOLD" / "PCT%" header, then a centered counter where the HAVE number is 72px (ember when ready, brass otherwise) and the denominator is 36px muted. Below: 18px progress bar with 25/50/75 tick marks. Footer: "N MORE NEEDED" / "~X EXPEDITIONS".
- **Reforge button** — full-width, 18px label, letter-spacing 4, ember gradient when ready, iron + 0.7 opacity when locked. Caption: "Prestige count · 0 · first reforge".

### Right — "You Will Receive"
Wood panel with 7 reward rows, one per hammer. Each row: 32×32 glyph tile (same ember-glow treatment as the Forge hammer rail — do NOT use the old PNG assets), name "HAMMER", delta line "HAVE N → 999", and a "+N" (18px ember) column. Footer: "TOTAL · 6,993 HAMMERS".

Runic row uses the rare purple tint; all others use brass.

---

## Screen 4 · Settings

Centered single column, 380px wide.

- "SETTINGS" title (24px display), italic subtitle "All save data is stored locally."
- Stack of full-width buttons (~44px tall, 13px label):
  - **Save Game** (primary / ember)
  - **New Game…** (iron)
  - **Export Save** with muted "(copies to clipboard)" micro-caption
- **Import Save** section — 9px mono label, then a row with a mono textbox (fontsize 11) and a secondary "Import" button.

---

## Interactions & Behavior

### Hover states (universal)
- **120ms ease** opacity transition on tooltip reveals.
- Inventory tile hover: shows details tooltip + reveals melt icon.
- Melt icon hover: swaps to solid copper fill with near-black glyph.
- Hammer tile hover: brightens background, sets ember border, reveals tooltip.
- New-base tile hover: brass border, amber background, reveals stockpile picker.

### Click flows
- Click hammer → arms it (ember border, updates "Selected Hammer" card).
- Click inventory item → selects it on the bench (ember selection glow).
- Click slot tab OR equipped-slot row → filters inventory.
- Click "+ New base" → pops the stockpile picker (not yet modal — M001 can ship as hover-tooltip only).
- Click 🜂 melt → confirm → destroy item, reclaim material (game-side).
- Click hammer + click bench item → applies hammer, rerolls affixes per the hammer's verb.
- Click "Send Hero ⚒" on an Expedition card → starts timer, dims the other card.
- Click "Recall Hero" → cancels active expedition (no partial rewards).
- Click "Reforge · Claim the 999" on Prestige (only if Tack ≥ 100) → confirm → reset.

### State variables (minimum)
- `activeHammer: string | null` — currently armed hammer key.
- `activeSlot: 'Weapon' | 'Helmet' | 'Armor' | 'Boots' | 'Ring'` — filters inventory + equipped highlight.
- `selectedItem: string | null` — item on the bench.
- `inventory: Item[]`, each with `{ id, slot, name, base, rar, mat, tier, affixes[], equipped }`.
- `stockpile: Record<slot, BaseStock[]>` — from expeditions.
- `hammers: Record<key, number>` — counts.
- `activeExpedition: 'iron' | 'steel' | null` + `progressStart, durationSec`.
- `prestigeCount: number`.

---

## Design Tokens (from `tokens.css`)

### Color — warm woods
- `--wood-deep: #1d130b`
- `--wood-dark: #2a1d12`
- `--wood: #3a2a1a`
- `--wood-mid: #4e3a24`
- `--wood-hi: #6b4e30`

### Color — iron (for top bar)
- `--iron-deep: #0e0c0a`
- `--iron: #1a1714`
- `--iron-mid: #2a2520`
- `--iron-hi: #3a332c`

### Color — brass / copper (accents)
- `--brass-lo: #8a6a3e`
- `--brass: #b0864f`
- `--brass-hi: #e8a85a`
- `--copper: #c48070`

### Color — ember (candlelight / active state)
- `--ember-lo: #c4571d`
- `--ember: #e8874a`
- `--ember-hi: #ffb070`

### Color — parchment & ink
- `--parch: #d9c9a3`
- `--parch-dim: #a89268`
- `--ink: #8a6f4a`
- `--ink-faint: #5a4a30`

### Color — rarity
- `--r-normal: #a89268`, `--r-normal-hi: #d9c9a3`
- `--r-magic: #5a7ac9`, `--r-magic-hi: #8cb4ff`
- `--r-rare: #c4a04a`, `--r-rare-hi: #f4d77c`

### Color — affix tones
- `--pre: #d9c9a3` (prefix — brass/parch)
- `--suf: #e8874a` (suffix — ember)

### Typography
- `--f-display: 'Cinzel', 'Spectral', serif` — titles, big numbers
- `--f-serif: 'Spectral', Georgia, serif` — body, item names
- `--f-ui: 'Inter', system-ui, sans-serif` — generic UI
- `--f-mono: 'JetBrains Mono', 'IBM Plex Mono', monospace` — labels, numbers, small caps

### Panels & surfaces (reusable classes in `tokens.css`)
- `.hm-wood-panel` — primary wood-grain panel with inner highlight + outer shadow
- `.hm-iron-panel` — iron gradient with rivet line (used by top bar)
- `.hm-inset` — inset dark groove (used for progress bars)
- `.num` — tabular-nums numeric run

### Scale
- Tab bar: 50px
- IronHeader: ~26px
- Buttons: ~44px (primary), ~24px (inline/melt)
- Inventory tile min-height: 50px
- Gutters: 5–10 inside panels, 10–16 between panels, 20–28 around screen edges.

---

## Assets

Under `design_files/assets/` in the prototype:
- `hero.png` — placeholder hero portrait (90×120 rendered).
- `sword2.png` — placeholder weapon art (100×24 rendered, rotated 90° on bench).
- `tack_hammer.png`, `tuning_hammer.png`, `forge_hammer.png`, `grand_hammer.png`, `runic_hammer.png`, `claw_hammer.png` — **no longer used**. All hammer representations in M001 are glyph tiles (unicode symbols + ember glow), matching the compact Forge rail. Do not reintroduce these PNGs into the new UI.

All assets are placeholders — the production build should swap in real art with matching footprints.

---

## Files

Inside `design_files/`:

- `Hammertime Prototype.html` — entry point. Mounts a design canvas with four artboards (forge / expeditions / prestige / settings) plus a tooltip reference artboard.
- `tokens.css` — all design tokens, panel classes, and hover rules. This is the closest thing to a style guide.
- `design-canvas.jsx` — layout scaffolding for the mock (not needed in Godot).
- `primitives.jsx` — shared helpers: `Ph` placeholder, `IronHeader`, `Nails`, `HammerIcon`, `ItemName`, rarity classes.
- `views/forge.jsx` — the Forge screen. Contains `M001_HAMMERS`, `M001_SLOTS`, `M001_INVENTORY`, `M001_STOCKPILE` data mocks and components: `ForgeView`, `Hammer`, `HammerEmpty`, `HammerTab`, `ActiveHammerCard`, `SlotTab`, `NewBaseTile`, `InvItem`, `EquipSlot`, `ScrollAffix`, `ScrollAffixEmpty`, `BenchStatReadout`, `DeltaStat`, `Tab`.
- `views/expeditions.jsx` — the Expeditions screen. Components: `ExpeditionsView`, `ExpeditionCard`, `MetaBox`, `ExTab`.
- `views/prestige.jsx` — the Prestige screen. Components: `PrestigeView`, `SacRow`, `RewardRow`, `PrTab`. Note the glyph-tile reward rows (no PNGs).
- `views/settings.jsx` — the Settings screen. Components: `SettingsView`, `SetButton`, `SetTab`.
- `views/other.jsx` — reference tooltip artboard only, not part of M001 shipping screens. Included for visual reference of a fully-loaded item tooltip.
- `uploads/M001-UI-DESIGN-BRIEF.md` — the original product brief this milestone was designed against.

To view the design interactively, open `Hammertime Prototype.html` in a browser with internet access (it loads React/Babel and Google Fonts via CDN).
