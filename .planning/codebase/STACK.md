# Technology Stack

**Analysis Date:** 2026-02-19

## Languages

**Primary:**
- GDScript - Game scripting language, used for all game logic, models, scenes, and UI

## Runtime

**Environment:**
- Godot Engine 4.6 - Open-source game engine

**Platform:**
- Mobile (primary rendering method: mobile)
- Windows Desktop (export preset configured)

## Frameworks

**Core:**
- Godot Engine 4.6 - Game engine providing Node system, scene management, rendering, and physics

**Rendering:**
- Mobile renderer - Optimized for mobile and desktop platforms
- Canvas Items mode - Viewport stretch mode for responsive UI

## Key Dependencies

**Built-in Libraries:**
- Godot FileAccess API - Local file I/O for save/load operations
- Godot JSON - JSON serialization/deserialization for save data
- Godot Marshalls - Base64 encoding/decoding for save string export/import
- Godot Timer - Game loop timing and auto-save intervals
- Godot Signals - Event-driven communication system

**No External Package Manager:**
- No npm, pip, gem, or Cargo dependencies
- No third-party libraries required

## Configuration

**Environment:**
- No environment variables required
- No configuration files (environment-specific settings not used)
- No API keys or credentials needed

**Build:**
- `export_presets.cfg` - Export configuration for Windows Desktop and other platforms
- `project.godot` - Godot project manifest with engine settings

## Platform Requirements

**Development:**
- Godot Engine 4.6 installed
- GDScript editor (built into Godot)
- Text editor compatible with `.gd` files

**Production:**
- Godot 4.6 runtime for target platform (Windows, Web, etc.)
- Minimal system requirements (mobile-oriented rendering)

## Autoloads (Global Services)

**Available at runtime:**
- `ItemAffixes` (`res://autoloads/item_affixes.gd`) - Item affix database
- `Tag` (`res://autoloads/tag.gd`) - Game tag/stat type definitions
- `GameEvents` (`res://autoloads/game_events.gd`) - Global event signal hub
- `SaveManager` (`res://autoloads/save_manager.gd`) - Save/load persistence
- `GameState` (`res://autoloads/game_state.gd`) - Global game state holder

## Asset Management

**Graphics:**
- SVG icon: `icon.svg`
- Temporary scene files: `.tscn*.tmp` (editor-generated, not committed)

**Scenes:**
- TSCN format for scene definitions (Godot native format)
- GD scripts attached to scene nodes for behavior

---

*Stack analysis: 2026-02-19*
