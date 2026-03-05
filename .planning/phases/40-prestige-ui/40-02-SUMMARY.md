---
phase: 40
plan: "02"
title: "Tab Integration + Fade Transition + Reload"
status: complete
date: "2026-03-06"
---

# Phase 40, Plan 02: Tab Integration + Fade Transition + Reload

## One-Liner
Integrated prestige view as 4th tab with dynamic reveal, badge text, and fade-to-black scene reload transition.

## What Was Built
Added PrestigeTab button (hidden by default, "P{N}" text), PrestigeView instance, and FadeRect overlay to main.tscn. Updated main_view.gd with 4-tab show_view() management, dynamic prestige tab reveal (appears when prestige_level > 0 or first prestige affordable), prestige state reset on tab leave, and a 0.5s fade-to-black transition with input blocking before scene reload on prestige trigger.

## Key Files
### Modified
- scenes/main.tscn — Added PrestigeTab button in TabBar, PrestigeView instance in ContentArea, FadeRect ColorRect in OverlayLayer
- scenes/main_view.gd — Added prestige_view/prestige_tab/fade_rect @onready vars, prestige_tab_revealed state, 4-tab disabled state management, _check_prestige_tab_reveal() with currency_dropped signal, _on_prestige_triggered() fade tween + reload

## Decisions Made
- No keyboard shortcut added for prestige tab (consistent with settings tab having none)
- FadeRect mouse_filter set to STOP (0) during fade to block all input, IGNORE (2) at rest

## Self-Check
- [x] "P{N}" badge visible in tab bar when prestige_level > 0 or prestige first affordable
- [x] Badge hidden at P0 before first prestige is affordable
- [x] Badge permanently visible once revealed (prestige_tab_revealed flag, never resets)
- [x] Badge text updates to reflect current prestige level
- [x] Clicking badge navigates to prestige view (4th tab in show_view system)
- [x] show_view() correctly manages all 4 tab disabled states
- [x] Fade to black over 0.5s before scene reload on prestige trigger
- [x] Input blocked during fade (mouse_filter = STOP on FadeRect)
- [x] Scene reloads after fade completes
- [x] Navigating away from prestige view resets confirmation state
