---
created: 2026-02-19T08:38:03.892Z
title: Add large number formatting with suffix notation
area: ui
files: []
---

## Problem

All numbers are currently displayed as raw integers. As the game progresses into idle/incremental territory, values will grow beyond readable ranges. Need a number formatting system that scales gracefully — showing values as K (kilo), M (mega), B, T, etc. or scientific notation (x^y) once they exceed thresholds.

This is a prerequisite for the "number go up" phase of the idle game loop where damage, gold, and stats scale exponentially.

## Solution

Create a utility function (e.g., `NumberFormatter`) that:
- Returns raw numbers below a threshold (e.g., < 1,000)
- Switches to suffix notation (1.2K, 3.5M, etc.) for larger values
- Optionally supports scientific notation (1.2e6) as an alternative display mode
- Apply consistently across all UI labels that display numeric values (damage, gold, stats, item counts)
