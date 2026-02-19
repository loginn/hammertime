# External Integrations

**Analysis Date:** 2026-02-19

## APIs & External Services

**None detected** - This is a single-player offline game with no external API integrations or remote services.

## Data Storage

**Local Filesystem Only:**
- Location: `user://hammertime_save.json`
- Format: JSON
- Client: Godot FileAccess API (built-in)
- Persistence: Save file stored in user data directory (OS-specific location)

**Save File Format:**
- Version: 2 (with migration from v1)
- Data: Hero equipment, currencies, crafting inventory, area progress
- Serialization: JSON with base64 encoding for export/import

**No Cloud Storage:**
- No cloud synchronization
- No remote database
- No server backend

**No File Storage Service:**
- No AWS S3, Google Cloud Storage, or similar
- All assets embedded in game binary

**No Caching Service:**
- No Redis, Memcached, or similar
- All data computed locally from item/affix models

## Authentication & Identity

**None Required:**
- Single-player game
- No user accounts
- No login system
- No API authentication tokens

## Monitoring & Observability

**Error Tracking:**
- None detected
- No Sentry, Bugsnag, or similar service

**Logs:**
- Godot push_warning() for save/load errors
- Console output only
- No centralized logging

## CI/CD & Deployment

**Hosting:**
- None - Desktop/mobile standalone application
- Export targets: Windows Desktop (Hammertime.exe)
- Additional platforms configurable in Godot export presets

**CI Pipeline:**
- None detected
- No GitHub Actions, GitLab CI, or similar
- Manual export/build process

## Environment Configuration

**Required env vars:**
- None - No external services to configure

**Secrets location:**
- N/A - No secrets, credentials, or API keys used

## Webhooks & Callbacks

**Incoming:**
- None - Offline game, no remote endpoints

**Outgoing:**
- None - No external services called

## Data Persistence Details

**Save Game Mechanism:**
- Location: `SaveManager` in `res://autoloads/save_manager.gd`
- Auto-save: Every 300 seconds (5 minutes)
- Event-driven saves: On item craft, equipment change, area clear
- Debounced: Prevents multiple saves in same frame

**Save/Load Format:**
- JSON with typed Item/Affix data
- Base64 encoding for portable save strings: `HT1:[base64]:[md5_checksum]`
- MD5 checksum validation for import integrity
- Version 2 format with backward compatibility (v1 to v2 migration)

**No Network Calls:**
- FileAccess.open() - Local file system only
- JSON.stringify() / JSON.parse_string() - Built-in Godot functions
- Marshalls.utf8_to_base64() - Built-in encoding

---

*Integration audit: 2026-02-19*
