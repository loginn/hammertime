---
status: diagnosed
trigger: "Hammers are not using the right icons from the asset folder. Text is too large + too much whitespace. it goes outside the viewport"
created: 2026-02-17T00:00:00Z
updated: 2026-02-17T00:02:00Z
symptoms_prefilled: true
goal: find_root_cause_only
---

## Current Focus

hypothesis: Hammer buttons use plain Button nodes with text labels instead of TextureButton/TextureRect with icon images; no font size overrides cause Godot default (16px) to render large in small buttons; layout dimensions exceed 720px viewport height
test: Read forge_view.tscn and forge_view.gd, checked assets/ folder for PNGs
expecting: Confirmed all three sub-issues
next_action: Return diagnosis

## Symptoms

expected: Hammer sidebar shows 45x45px icon images from assets/ folder (claw_hammer.png, forge_hammer.png, etc.) in a 2-column grid with 20px gaps, fitting within 1280x720 viewport
actual: Hammer buttons display text-only labels like "Runic (0)", "Forge (0)" with no icons. Text is too large for the button sizes. Layout has excessive whitespace and content extends beyond the 720px viewport height.
errors: None
reproduction: Open ForgeView scene in game
started: Phase 19 implementation

## Eliminated

(none - issues confirmed on first investigation pass)

## Evidence

- timestamp: 2026-02-17T00:00:30Z
  checked: forge_view.tscn hammer button node types
  found: All 6 hammer buttons are plain `Button` nodes (lines 23-75), NOT TextureButton or any icon-bearing control. They use `text = "Runic (0)"` etc. No texture/icon properties set. No ext_resource references to hammer PNGs.
  implication: Icons are completely absent from the scene definition

- timestamp: 2026-02-17T00:00:35Z
  checked: forge_view.gd update_currency_button_states()
  found: Line 216 sets `button.text = currencies[currency_type].currency_name + " (" + str(count) + ")"` -- only updates text, never sets any icon property
  implication: GD script also has no icon logic whatsoever

- timestamp: 2026-02-17T00:00:40Z
  checked: assets/ folder for hammer PNGs
  found: All 6 hammer icon PNGs exist and are valid: runic_hammer.png, forge_hammer.png, grand_hammer.png, claw_hammer.png, tack_hammer.png, tuning_hammer.png. They also have .import files (Godot has imported them).
  implication: Assets are available but simply not referenced by the scene

- timestamp: 2026-02-17T00:00:45Z
  checked: forge_view.tscn font/theme overrides
  found: NO font_size overrides on any node in the entire .tscn file. Godot default font size is 16px. Buttons are 65px tall (offset_bottom - offset_top = 80 - 15 = 65) and 110px wide (125 - 15 = 110). With 16px default font, text like "Runic (0)" renders at default size with no room for icons.
  implication: Default font is too large for the intended compact icon-based layout

- timestamp: 2026-02-17T00:00:50Z
  checked: HammerSidebar dimensions and position
  found: HammerSidebar is positioned at offset_top=0 (not 50 as wireframe specifies), offset_left=40, offset_right=300 (width=260, matches spec), offset_bottom=660. The sidebar is 260x660 starting from y=0.
  implication: Sidebar top position does not match wireframe spec (should be y=50)

- timestamp: 2026-02-17T00:01:00Z
  checked: Viewport overflow - bottom extent of all panels
  found: Background goes to y=660. HammerSidebar goes to y=660. ItemStatsPanel goes to y=660. HeroStatsPanel goes to y=660. HeroGraphicsPanel goes to y=200. All panels fit within 720px viewport height. However, InventoryLabel in HammerSidebar goes to local y=650 (offset_bottom=650), with multi-line text content that could clip if text is too long.
  implication: The viewport overflow complaint may stem from: (1) no top margin (sidebar starts at y=0 not y=50), (2) default font size making all text occupy more space than intended, (3) the text-only buttons being larger/taller than icon buttons would be, creating a visually "too much" feel

- timestamp: 2026-02-17T00:01:10Z
  checked: InventoryLabel dimensions
  found: InventoryLabel spans from y=320 to y=650 (330px of vertical space) within the sidebar for just 6 lines of inventory text. At 16px default font, 6 lines need ~120px. The label is allocated 330px — massive whitespace.
  implication: Excessive whitespace between FinishItemButton (ends at y=300) and bottom of sidebar, contributing to "too much whitespace" complaint

- timestamp: 2026-02-17T00:01:15Z
  checked: ItemStatsLabel dimensions
  found: ItemStatsLabel spans offset_top=10 to offset_bottom=380 (370px) in ItemStatsPanel. With default 16px font, even a fully modded item's stats would use ~250px. Meanwhile MeltButton and EquipButton are at y=385-425 inside a panel that's 430px tall (230 to 660). This creates significant dead space.
  implication: Additional source of whitespace perception

## Resolution

root_cause: |
  THREE interconnected issues in forge_view.tscn:

  1. NO HAMMER ICONS: All 6 hammer buttons (RunicHammerBtn, ForgeHammerBtn, etc.) are plain `Button` nodes with text-only labels like "Runic (0)". They should be TextureButton nodes (or Button nodes with icon properties) referencing the hammer PNG assets from assets/ folder (claw_hammer.png, forge_hammer.png, grand_hammer.png, runic_hammer.png, tack_hammer.png, tuning_hammer.png). The assets exist and are imported but are never referenced in the .tscn file. The GD script (update_currency_button_states) also only updates text, never sets icons.

  2. TEXT TOO LARGE: No font_size theme overrides are set on ANY node in the scene. Godot's default font size (16px) is used everywhere. For the compact hammer button layout (110x65px buttons), icon-based buttons at 45x45px with small count labels would fit, but 16px text-only labels fill the space poorly. Labels throughout (InventoryLabel, ItemStatsLabel, HeroStatsLabel) also use 16px default when smaller sizes would be more appropriate for the dense UI.

  3. EXCESSIVE WHITESPACE / VISUAL OVERFLOW: The HammerSidebar starts at y=0 instead of y=50 (per wireframe). InventoryLabel is allocated 330px of vertical space for ~6 lines of text that need ~120px. The combination of text-only buttons (taller than icon buttons would be), default font sizes, and oversized label regions creates excessive whitespace and a visually "too large" layout that crowds the viewport.

fix:
verification:
files_changed: []
