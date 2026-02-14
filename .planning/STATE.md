# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-14)

**Core value:** The crafting loop must feel rewarding -- finding items, using hammers to shape them, and equipping the result to push further into harder content.
**Current focus:** Milestone v0.1 -- Code Cleanup & Architecture

## Current Position

Phase: Not started (defining requirements)
Plan: --
Status: Defining requirements
Last activity: 2026-02-14 -- Milestone v0.1 started

## Accumulated Context

- Existing codebase has flat file structure, all .gd files in project root
- Hero instance is created in hero_view.gd and shared via node references
- Item base class uses has_method/property checks for polymorphism
- Affix system uses tag-based filtering to determine valid affixes per item type
- Current hammer system is tightly coupled to crafting_view.gd
- Damage calculations duplicated across weapon.gd, ring.gd, armor.gd
- Tag system serves dual purpose: affix filtering AND damage type routing
- User is new to Godot — first project
- v1.0 Crafting Overhaul research and requirements preserved in .planning/research/
