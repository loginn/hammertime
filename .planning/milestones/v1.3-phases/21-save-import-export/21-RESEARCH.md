# Phase 21: Save Import/Export - Research

**Researched:** 2026-02-18
**Domain:** Save serialization, Base64 encoding, clipboard access in Godot 4.5
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Base64-encoded JSON with `HT1:base64data` prefix format
- Checksum appended for corruption/truncation detection
- Always exports full game state (no partial/selective)
- Controls live in existing Settings menu (SettingsView scene)
- Export: single click, auto-copy to clipboard, toast confirms "Copied!"
- Import: TextEdit paste field + "Import Save" button
- Import button disabled when text field is empty
- Export button always enabled
- Two-click import confirmation (consistent with equip confirmation pattern)
- No auto-backup before import
- After successful import: load into memory AND persist to disk immediately
- Success toast after import, no automatic reload
- Errors via toast notifications (red-tinted, matching save toast pattern)
- Generic error message: "Invalid save string. Please check and try again."
- Prefix check first, then checksum validation

### Claude's Discretion
- Version compatibility handling for newer/older save versions
- Exact checksum algorithm choice
- TextEdit field sizing and placement within settings layout
- Toast duration and styling details

### Deferred Ideas (OUT OF SCOPE)
None
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SAVE-04 | Player can export save as a string and import a save string to restore state | Full research coverage: Base64 encoding, clipboard API, checksum validation, import/export UI in settings, error handling via toast |
</phase_requirements>

## Summary

Phase 21 adds export/import capability to the existing save system built in Phase 18. The core architecture is straightforward: `SaveManager._build_save_data()` already produces a complete Dictionary of game state, and `_restore_state()` already restores from a Dictionary. The export flow serializes that Dictionary to JSON, Base64-encodes it, prepends the `HT1:` prefix and appends a checksum. Import reverses the process with validation at each step.

Godot 4.5 provides all needed primitives natively: `Marshalls.utf8_to_base64()` / `Marshalls.base64_to_utf8()` for encoding, `DisplayServer.clipboard_set()` / `DisplayServer.clipboard_get()` for clipboard access, and `String.md5_text()` or `String.sha256_text()` for checksums. No external libraries are needed.

The UI additions go into the existing `SettingsView` scene (Node2D-based, positioned with absolute offsets). New controls: an Export button, a TextEdit for paste input, and an Import button with two-click confirmation.

**Primary recommendation:** Use CRC32 via Godot's `crc32()` on the Base64 payload for the checksum (fast, short output, good enough for corruption detection), and add export/import methods directly to SaveManager.

## Standard Stack

### Core (Already in Project)
| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Marshalls | Godot 4.5 built-in | Base64 encode/decode | Native utility class, no import needed |
| DisplayServer | Godot 4.5 built-in | Clipboard read/write | OS clipboard access |
| JSON | Godot 4.5 built-in | Serialize/parse dictionaries | Already used by SaveManager |
| String.md5_text() | Godot 4.5 built-in | Checksum generation | Built into String class |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| md5_text() | sha256_text() | SHA-256 is longer (64 chars vs 32); overkill for corruption detection |
| md5_text() | crc32() on PackedByteArray | Shorter output (8 hex chars) but requires byte conversion step |
| Marshalls.utf8_to_base64 | Marshalls.variant_to_base64 | variant_to_base64 uses Godot's binary serialization which is NOT JSON — avoid for portability |

**Recommendation:** Use `md5_text()` — 32-char hex output is compact enough for a save string, and it's a single method call on String with no conversion needed.

## Architecture Patterns

### Export Flow
```
_build_save_data() → JSON.stringify() → Marshalls.utf8_to_base64() → prepend "HT1:" → append ":" + checksum
```

### Import Flow
```
validate "HT1:" prefix → split checksum → verify checksum → Marshalls.base64_to_utf8() → JSON.parse_string() → _migrate_save() → _restore_state() → save_game()
```

### Pattern 1: Export Method on SaveManager
```gdscript
func export_save_string() -> String:
    var save_data := _build_save_data()
    var json_string := JSON.stringify(save_data)
    var base64 := Marshalls.utf8_to_base64(json_string)
    var checksum := base64.md5_text()
    return "HT1:" + base64 + ":" + checksum
```

### Pattern 2: Import Method on SaveManager
```gdscript
func import_save_string(save_string: String) -> bool:
    # Prefix check
    if not save_string.begins_with("HT1:"):
        return false

    # Strip prefix, split checksum
    var payload := save_string.substr(4)  # Remove "HT1:"
    var colon_pos := payload.rfind(":")
    if colon_pos < 0:
        return false

    var base64_part := payload.substr(0, colon_pos)
    var checksum_part := payload.substr(colon_pos + 1)

    # Verify checksum
    if base64_part.md5_text() != checksum_part:
        return false

    # Decode
    var json_string := Marshalls.base64_to_utf8(base64_part)
    if json_string.is_empty():
        return false

    var parsed = JSON.parse_string(json_string)
    if parsed == null or not (parsed is Dictionary):
        return false

    var data: Dictionary = parsed
    data = _migrate_save(data)

    if not _restore_state(data):
        return false

    # Persist to disk immediately
    save_game()
    return true
```

### Pattern 3: Two-Click Import Confirmation
```gdscript
var _import_confirming: bool = false

func _on_import_pressed() -> void:
    if import_text_edit.text.strip_edges().is_empty():
        return
    if not _import_confirming:
        _import_confirming = true
        import_button.text = "Confirm overwrite?"
    else:
        _import_confirming = false
        import_button.text = "Import Save"
        _do_import()
```

### Pattern 4: Clipboard Auto-Copy on Export
```gdscript
func _on_export_pressed() -> void:
    var save_string := SaveManager.export_save_string()
    DisplayServer.clipboard_set(save_string)
    # Show success toast
```

### Anti-Patterns to Avoid
- **Using Marshalls.variant_to_base64:** This uses Godot's internal binary format, not JSON. The resulting string is not portable across versions and cannot be decoded by anything except Godot.
- **Storing checksum inside the Base64:** The checksum must be outside the encoded payload so it can be verified before attempting decode.
- **Using TextEdit.text without strip_edges():** Pasted strings often include trailing newlines or whitespace that break Base64 decode.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Base64 encoding | Custom encode/decode | Marshalls.utf8_to_base64 / base64_to_utf8 | Godot handles padding and character set correctly |
| Clipboard access | OS.execute("xclip") | DisplayServer.clipboard_set/get | Cross-platform, no external dependencies |
| JSON serialization | Manual string building | JSON.stringify / parse_string | Already used by save system, handles escaping |
| Checksum | Custom hash function | String.md5_text() | One-liner, well-tested implementation |

## Common Pitfalls

### Pitfall 1: Base64 Whitespace Corruption
**What goes wrong:** Users may copy save strings with line breaks (some text editors wrap long lines) or trailing whitespace.
**Why it happens:** Base64 strings can be very long; clipboard managers or text fields may insert line breaks.
**How to avoid:** Strip all whitespace from the pasted string before processing: `save_string.strip_edges().replace("\n", "").replace("\r", "").replace(" ", "")`
**Warning signs:** Import fails on valid exports when copied through certain apps.

### Pitfall 2: Empty TextEdit Triggering Import
**What goes wrong:** Clicking Import with empty field attempts to parse empty string.
**Why it happens:** Button press handler doesn't check input state.
**How to avoid:** Disable Import button when TextEdit is empty. Connect to TextEdit's `text_changed` signal to toggle button disabled state.

### Pitfall 3: State Not Refreshing After Import
**What goes wrong:** UI still shows old state after successful import because scenes don't know state changed.
**Why it happens:** `_restore_state` modifies GameState but doesn't emit signals that UI listens to.
**How to avoid:** After import, emit relevant signals or add an `import_completed` signal that views connect to for full refresh. The `new_game_started` signal path in SettingsView already handles this pattern for New Game.

### Pitfall 4: Version Mismatch on Import
**What goes wrong:** Importing a save from a newer game version with unknown fields, or an older version missing fields.
**Why it happens:** Save strings can be shared between players on different versions.
**How to avoid:** The existing `_migrate_save()` already handles older versions. For newer versions (save version > SAVE_VERSION), reject the import with an error message rather than silently dropping unknown fields.

## Code Examples

### Base64 Encode/Decode in Godot 4.5
```gdscript
# Encode string to Base64
var original := "Hello World"
var encoded := Marshalls.utf8_to_base64(original)
# encoded = "SGVsbG8gV29ybGQ="

# Decode Base64 to string
var decoded := Marshalls.base64_to_utf8(encoded)
# decoded = "Hello World"
```

### Clipboard Access in Godot 4.5
```gdscript
# Copy to clipboard
DisplayServer.clipboard_set("text to copy")

# Read from clipboard
var pasted := DisplayServer.clipboard_get()
```

### MD5 Checksum on String
```gdscript
var data := "some base64 data here"
var checksum := data.md5_text()
# Returns 32-character lowercase hex string
```

### TextEdit with text_changed Signal
```gdscript
# In scene: TextEdit node
@onready var import_text: TextEdit = $ImportTextEdit
@onready var import_button: Button = $ImportButton

func _ready():
    import_text.text_changed.connect(_on_import_text_changed)
    import_button.disabled = true

func _on_import_text_changed():
    import_button.disabled = import_text.text.strip_edges().is_empty()
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| OS.clipboard (Godot 3.x) | DisplayServer.clipboard_set/get (4.x) | Godot 4.0 | DisplayServer is the 4.x API |
| Marshalls.raw_to_base64 | Marshalls.utf8_to_base64 | Stable since 4.0 | utf8 variant handles string encoding directly |

## Open Questions

1. **Toast color for errors**
   - What we know: Existing save_toast.gd uses default label color. Context says "red-tinted" for errors.
   - What's unclear: Exact red color value and whether to modify existing toast or create separate error styling.
   - Recommendation: Add a `color` parameter to `show_toast()` — default white for success, `Color.RED` or `Color(1, 0.4, 0.4)` for errors. Soft red is more readable on dark backgrounds.

2. **Import of future save versions**
   - What we know: Current SAVE_VERSION is 1. _migrate_save handles older→current.
   - What's unclear: Whether to reject saves with version > SAVE_VERSION or attempt best-effort load.
   - Recommendation: Reject with clear error. Importing a newer save could silently lose data. Message: "Save requires a newer game version."

## Sources

### Primary (HIGH confidence)
- Codebase inspection: `autoloads/save_manager.gd` — existing _build_save_data(), _restore_state(), _migrate_save() patterns
- Codebase inspection: `scenes/settings_view.gd` / `.tscn` — current UI layout and button patterns
- Codebase inspection: `scenes/save_toast.gd` — existing toast notification system
- Codebase inspection: `autoloads/game_events.gd` — existing signal patterns
- Codebase inspection: `models/items/item.gd` — to_dict() / create_from_dict() serialization

### Secondary (MEDIUM confidence)
- Godot 4.x Marshalls class documentation — Base64 methods (utf8_to_base64, base64_to_utf8)
- Godot 4.x DisplayServer documentation — clipboard_set, clipboard_get
- Godot 4.x String documentation — md5_text(), sha256_text()

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All components are Godot built-ins verified in codebase and docs
- Architecture: HIGH - Builds directly on existing SaveManager patterns with minimal new code
- Pitfalls: HIGH - Based on common serialization/clipboard issues well-documented across platforms

**Research date:** 2026-02-18
**Valid until:** 2026-03-18 (stable domain, no fast-moving dependencies)
