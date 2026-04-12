# Hammertime — Fix Hammers Workstream

## What This Is

A focused workstream to fix mismatched hammer/currency behaviors and complete the PoE currency mapping with 8 base hammers. Several hammers currently have the wrong behavior: Augment does Alchemy's job, Chaos does Annulment's job, Exalt does Divine's job, and Alchemy is missing entirely.

## Core Value

Every hammer must do exactly what a PoE player expects — correct currency behaviors build trust in the crafting system.

## Current Milestone: v1.11 Fix Hammers — Full PoE Currency Set

**Goal:** Fix mismatched hammer behaviors and complete the PoE currency mapping with 8 base hammers.

**Target features:**
- Fix Augment Hammer — add 1 mod to Magic item (currently does Alchemy behavior: Normal→Rare)
- Add Alchemy Hammer — Normal → Rare with 4-6 mods (new currency, takes Augment's current behavior)
- Fix Chaos Hammer — reroll all mods on Rare item (currently does Annulment behavior: removes 1 mod)
- Fix Exalt Hammer — add 1 random mod to Rare item (currently does Divine behavior: rerolls values)
- Add Divine Hammer — reroll mod values within tier ranges (new currency, takes Exalt's current behavior)
- Add Annulment Hammer — remove 1 random mod (new currency, takes Chaos's current behavior)
- Update UI — 8 base hammer buttons with correct tooltips
- Update drops, save format, and tests

**Key context:**
- Tag hammers (Fire/Cold/Lightning/Defense/Physical) keep their current behavior (Normal→Rare with tag guarantee)
- Save format needs version bump for new currency keys
- Existing saves need currency count migration or fresh start

## Context

See main PROJECT.md for full project context. This workstream focuses only on currency/hammer behavior fixes.

- 6 current base hammers: Transmute, Augment, Alteration, Regal, Chaos, Exalt
- Target: 8 base hammers: Transmute, Augment, Alchemy, Alteration, Regal, Chaos, Exalt, Divine, Annulment
- Currency classes in models/currencies/
- UI in scenes/forge_view.gd
- Drops in models/loot/loot_table.gd
- Save in autoloads/save_manager.gd (format v9)
- Tests in tools/test/integration_test.gd

## Constraints

- Must not break tag hammer behavior
- Must update save format version
- Must update integration tests

## Out of Scope

- Tag hammer changes — those work correctly
- New crafting mechanics beyond PoE standard currencies
- UI layout redesign — just add buttons for new hammers

## Evolution

This document evolves at phase transitions and milestone boundaries.

---
*Last updated: 2026-04-12 — Phase 3 (Integration) complete; all 3 phases of fix-hammers milestone done*
