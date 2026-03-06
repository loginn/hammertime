# Phase 41: Integration Verification - Context

**Gathered:** 2026-03-06
**Status:** Ready for planning

<domain>
## Phase Boundary

End-to-end verification of the full prestige loop (P0 to P1) with save round-trip validation and regression checks on crafting, item tiers, tag hammer gating, and area/hero reset. No new features — purely validation that all v1.7 systems work together correctly.

</domain>

<decisions>
## Implementation Decisions

### Verification method
- GDScript test scene in tools/test/ directory, run from editor as standalone scene
- Structured pass/fail output: each check prints [PASS] or [FAIL] with description, summary at end ("X/Y tests passed")
- Uses a separate save path (e.g., user://test_save.json) to avoid touching real saves; cleans up test files when done

### Save verification scope
- No v2/v3 fixture tests — old save versions are deleted on load, no backward-compat testing needed until prod
- Save round-trip at each prestige level (P0 and P1): save, reload, compare all prestige fields (prestige_level, max_item_tier_unlocked, tag_currency_counts)
- Only verify against current SAVE_VERSION (currently 4)

### Prestige depth
- P0 to P1 only — the one achievable prestige level (100 Forge Hammers)
- P2+ has stub costs (999999) and would test the same code path with different numbers
- Verify can_prestige() gating: returns false with insufficient funds, true after granting 100 forge hammers
- Verify post-prestige bonus: tag_currency_counts has exactly 1 total tag currency after prestige (confirms grant happens after wipe)

### Regression coverage
- Crafting still works: after prestige, apply Runic Hammer to starter weapon, verify it adds a mod
- Item tier gating: after P1, verify item_tier affects affix tier floor (tier 7 item = affix tiers 25-32)
- Tag hammer availability: before P1 tag section hidden, after P1 visible and usable
- Area/hero reset: after prestige, area_level=1, hero has no equipment, starter weapon in inventory
- No combat/drop system verification (they don't interact with prestige state directly)
- No new game flow verification (separate concern from prestige)

### Claude's Discretion
- Test scene structure and helper function organization
- Exact assertions and edge cases beyond the specified checks
- Whether to use a minimal test framework or raw print statements with [PASS]/[FAIL] prefix

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- PrestigeManager autoload: can_prestige(), execute_prestige(), PRESTIGE_COSTS, ITEM_TIERS_BY_PRESTIGE
- SaveManager: save_game(), load_game(), _build_save_data(), _restore_state(), SAVE_PATH constant
- GameState: _wipe_run_state(), initialize_fresh_game(), prestige_level, max_item_tier_unlocked, tag_currency_counts
- GameEvents: prestige_completed signal

### Established Patterns
- SaveManager.SAVE_PATH = "user://hammertime_save.json" — test should use different path
- SaveManager.SAVE_VERSION = 4 — current version to test against
- GameState._ready() calls initialize_fresh_game() then load_game() — test scene must account for this initialization order
- Currency spending: GameState.spend_currency() for standard, spend_tag_currency() for tags

### Integration Points
- PrestigeManager.execute_prestige() is the main integration point: validates -> spends -> advances -> wipes -> grants bonus -> signals
- SaveManager._build_save_data() and _restore_state() handle all prestige field serialization
- Tag hammer visibility gated on GameState.prestige_level >= 1 in forge_view.gd

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 41-integration-verification*
*Context gathered: 2026-03-06*
