---
phase: 2
slug: forge-ui
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-12
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — grep-based structural checks (no GDScript test infrastructure in project) |
| **Config file** | none |
| **Quick run command** | `grep -c "icon = ExtResource" scenes/forge_view.tscn` (expect `0`) |
| **Full suite command** | See "Structural Check Suite" below |
| **Estimated runtime** | ~3 seconds (greps only) |

---

## Sampling Rate

- **After every task commit:** Run relevant grep(s) from the Per-Task Verification Map
- **After every plan wave:** Run the full Structural Check Suite
- **Before `/gsd:verify-work`:** Full suite must be green AND manual Godot smoke check passed
- **Max feedback latency:** ~3 seconds (grep suite)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | UI-01 | structural | `grep -A3 "AugmentHammerBtn" scenes/forge_view.tscn \| grep "offset_top = 70.0"` | ✅ | ⬜ pending |
| 02-01-01 | 01 | 1 | UI-01 | structural | `grep -A3 "GrandHammerBtn" scenes/forge_view.tscn \| grep "offset_left = 125.0"` | ✅ | ⬜ pending |
| 02-01-01 | 01 | 1 | UI-01 | structural | `grep -c "HammerBtn" scenes/forge_view.tscn` → `14` | ✅ | ⬜ pending |
| 02-01-02 | 01 | 1 | UI-01 | structural | `grep -c "icon = ExtResource" scenes/forge_view.tscn` → `0` | ✅ | ⬜ pending |
| 02-01-02 | 01 | 1 | UI-01 | structural | `grep -c "expand_icon = true" scenes/forge_view.tscn` → `0` | ✅ | ⬜ pending |
| 02-01-02 | 01 | 1 | UI-01 | structural | `grep -c "ext_resource" scenes/forge_view.tscn` → `3` (script, sword, hero) | ✅ | ⬜ pending |
| 02-01-03 | 01 | 1 | UI-01 | structural | `grep -c "hammer_icons" scenes/forge_view.gd` → `0` | ✅ | ⬜ pending |
| 02-01-04 | 01 | 1 | UI-01 | structural | `grep -n "button.disabled = (count <= 0)" scenes/forge_view.gd` (present) | ✅ | ⬜ pending |
| 02-01-04 | 01 | 1 | UI-01 | structural | `grep -A3 "TagHammerSection" scenes/forge_view.tscn \| grep "offset_top = 290.0"` | ✅ | ⬜ pending |
| 02-01-04 | 01 | 1 | UI-01 | manual | Godot editor loads scene without parse errors + F1 smoke check | manual | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*None — project has no test framework, structural greps run directly against live source files. No stubs or fixtures needed.*

---

## Structural Check Suite (full run before sign-off)

```bash
# 1. Button count (14 = 9 base + 5 tag)
grep -c "HammerBtn" scenes/forge_view.tscn

# 2. No legacy icon references
grep -c "icon = ExtResource" scenes/forge_view.tscn            # expect 0
grep -c "expand_icon = true" scenes/forge_view.tscn            # expect 0

# 3. ext_resource cleanup (only script + sword + hero remain)
grep -c "ext_resource" scenes/forge_view.tscn                  # expect 3

# 4. Dead code removed
grep -c "hammer_icons" scenes/forge_view.gd                    # expect 0

# 5. Grey-out binding still wired
grep -n "button.disabled = (count <= 0)" scenes/forge_view.gd  # expect line ~379

# 6. Rarity-grouped positions (spot check one per row)
grep -A3 "RunicHammerBtn"   scenes/forge_view.tscn | grep "offset_top = 15.0"
grep -A3 "AugmentHammerBtn" scenes/forge_view.tscn | grep "offset_top = 70.0"
grep -A3 "GrandHammerBtn"   scenes/forge_view.tscn | grep "offset_left = 125.0"
grep -A3 "ChaosHammerBtn"   scenes/forge_view.tscn | grep "offset_top = 125.0"
grep -A3 "DivineHammerBtn"  scenes/forge_view.tscn | grep "offset_top = 180.0"

# 7. TagHammerSection offset unchanged
grep -A3 "TagHammerSection" scenes/forge_view.tscn | grep "offset_top = 290.0"
```

All commands must exit 0 (non-empty match) for items 1-7 where a value is expected; items 2-4 must output their exact numeric expected value.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Scene parse | UI-01 | Godot editor not scriptable in CI | Open `scenes/forge_view.tscn` in Godot 4 editor — confirm no parse errors in Output panel |
| 2-letter codes render | UI-01 (success criterion 1) | Requires Godot runtime rendering | Play forge view (F5 in editor), press F1 debug shortcut, verify all 9 base buttons display their 2-letter codes (TR, AL, AU, AT, RG, CH, EX, DI, AN) in rarity-grouped order |
| Grey-out on zero currency | UI-01 (success criterion 3) | Requires Godot runtime state | Start fresh (no F1), confirm all 9 base buttons greyed/disabled; press F1 to grant currency, confirm buttons become enabled |
| Tooltip display on hover | UI-01 (success criterion 2) | Requires Godot runtime input | Hover any base hammer button for ~1s, confirm tooltip shows currency name, count, and PoE behavior description |

*Rationale per D-17/D-18: Runtime UAT is not required because Phase 1 UAT (`01-HUMAN-UAT.md`, 7/7 pass) already validated these exact buttons. Manual checks above are the single smoke pass from D-18(f).*

---

## Validation Sign-Off

- [ ] All tasks have structural grep or manual smoke verification
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 n/a — no framework needed
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s (grep suite ~3s)
- [ ] `nyquist_compliant: true` set in frontmatter after first successful run

**Approval:** pending
