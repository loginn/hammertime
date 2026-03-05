---
phase: 40
plan: "01"
title: "Prestige View Scene + Confirmation Flow"
status: complete
date: "2026-03-06"
---

# Phase 40, Plan 01: Prestige View Scene + Confirmation Flow

## One-Liner
Created the prestige view scene with a 7-level unlock table, status display, static reset list, and two-click prestige trigger with 3-second timer confirmation.

## What Was Built
A new prestige_view.tscn scene following the settings_view.tscn pattern: Node2D root with 1280x670 dark background (mouse_filter pass-through), centered title with font_size 28, current prestige level label, next cost/reward info labels, a table header HBoxContainer with 5 columns (Status, Level, Max Item Tier, Reward, Cost), a VBoxContainer for dynamically-built unlock rows, a static reset list warning in red-tinted text, and a prestige trigger button.

The prestige_view.gd script implements the full prestige view logic. It dynamically builds 7 unlock table rows from PrestigeManager constants, with completed levels showing a checkmark and green tint, the next level showing an arrow and white text, and future levels showing a dash and grey tint. Future costs display "???" while completed and next-level costs show actual values. The P1 row uniquely shows "Tag Hammers" as its reward. The two-click confirmation flow mirrors forge_view.gd's equip pattern: first click changes button to "Reset progress?", second click executes prestige + saves + emits prestige_triggered signal, and a 3-second Timer resets the confirmation state if no second click occurs. The button stays disabled when prestige is unaffordable or at max level, and updates dynamically via the currency_dropped signal.

## Key Files
### Created
- scenes/prestige_view.tscn -- Prestige view scene with Background, labels, table header, UnlockTable VBoxContainer, reset list, and PrestigeButton
- scenes/prestige_view.gd -- View script with dynamic unlock table, two-click confirmation, timer reset, and prestige_triggered signal

## Decisions Made
- Used dash "-" instead of unicode padlock for locked/future row status indicator to avoid potential font rendering issues with emoji characters in Godot
- Used unicode checkmark (U+2713) for completed row status since it's in the BMP and widely supported
- Cost column shows actual forge hammer cost for both completed and next-level rows, "???" for future rows (matching plan spec)

## Self-Check
- [x] prestige_view.tscn exists with Background, status labels, UnlockTable, ResetListLabel, PrestigeButton
- [x] 7-row unlock table displays level, tier, reward, and cost for each prestige level
- [x] Completed levels show checkmark + green tint, next level shows arrow + white, future shows lock/dash + grey
- [x] Future costs display "???" instead of actual values
- [x] P1 row shows "Tag Hammers" as reward; other rows show "-"
- [x] Two-click confirmation: "Upgrade your forge" -> "Reset progress?" -> execute
- [x] 3-second timer resets confirmation state
- [x] Button disabled when prestige is unaffordable or at max level
- [x] Static reset list shows what gets wiped
- [x] prestige_triggered signal emitted after execute_prestige() + save_game()
