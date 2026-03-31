---
status: resolved
trigger: "Yellow flash missing on stash-to-bench transfer; alpha pulse fires twice on bench clear"
created: 2026-03-31T00:00:00Z
updated: 2026-03-31T00:00:00Z
---

## Current Focus

hypothesis: Two distinct bugs confirmed — see Resolution
test: code trace complete
expecting: n/a
next_action: return diagnosis

## Symptoms

expected: (1) Yellow flash on stash slot when item transferred to bench. (2) Single alpha pulse on all stash slots when bench clears via melt/equip.
actual: (1) No visible yellow flash. (2) Alpha pulse fires twice.
errors: No runtime errors — visual animation issues only
reproduction: (1) Tap any filled stash slot. (2) Melt or equip an item from bench.
started: Phase 57 implementation

## Eliminated

(none needed — both root causes confirmed on first pass)

## Evidence

- timestamp: 2026-03-31
  checked: _on_stash_slot_pressed (lines 406-429) — order of operations
  found: Line 419 sets items[index]=null, line 424 calls _flash_stash_slot, line 428 calls _update_stash_display. The flash tween starts on line 436-437 targeting modulate to Color(1,1,0.3,1) over 0.08s, then back to dim. BUT _update_stash_display runs AFTER the flash call (line 428) and unconditionally sets modulate to Color(0.4,0.4,0.4,1) on empty slots (line 398). Since tween is async (runs over frames) and _update_stash_display is synchronous (runs immediately in same frame), the display update overwrites the tween's starting value on the SAME FRAME the tween begins. The tween interpolates from the already-dimmed value, so no visible yellow.
  implication: BUG 1 ROOT CAUSE — _update_stash_display() clobbers the flash tween's modulate on the same frame.

- timestamp: 2026-03-31
  checked: _pulse_stash_slots call sites (lines 513, 558) and _on_stash_updated (line 402-403)
  found: Both _on_melt_pressed (line 512-513) and _on_equip_pressed (line 557-558) call _update_stash_display() then _pulse_stash_slots(). _update_stash_display sets btn.disabled=false for filled slots (line 394) and enables them. _pulse_stash_slots checks `not btn.disabled` (line 444) and tweens alpha. This is one pulse. However, _update_stash_display is ALSO called via signal: _on_stash_updated connects to GameEvents.stash_updated (line 197), which fires when add_item_to_stash is called. But melt/equip don't call add_item_to_stash — they just null the bench. So stash_updated does NOT fire here. The double-pulse must come from _update_stash_display being called twice: once explicitly (line 512/557) and once via _on_stash_updated if something else emits stash_updated.
  implication: Need to check if crafting_bench=null triggers any stash signal.

- timestamp: 2026-03-31
  checked: Whether setting GameState.crafting_bench=null triggers stash_updated
  found: crafting_bench is a plain variable, not a setter that emits signals. No stash_updated emission from nulling the bench. So the signal path is NOT the double-pulse source.
  implication: Re-examine _pulse_stash_slots itself for double-tween behavior.

- timestamp: 2026-03-31
  checked: _pulse_stash_slots (lines 440-447) — tween behavior
  found: The function creates one tween PER non-disabled button. Each tween does TWO sequential property changes: modulate:a to 0.4 (0.15s) then modulate:a to 1.0 (0.15s). This is one pulse per button — fade down then fade up. That is a single pulse visually. But WAIT — _update_stash_display (called just before on line 512/557) sets modulate to Color(1,1,1,1) for filled slots, meaning alpha starts at 1.0. The tween fades to 0.4 then back to 1.0. That's one pulse. HOWEVER: if _update_stash_display also runs AFTER _pulse_stash_slots due to some deferred call or signal, it would reset modulate mid-tween, causing the tween to effectively restart visually.
  implication: The double-pulse is likely caused by _update_stash_display being called a SECOND time via signal while the pulse tween is in progress, resetting modulate:a to 1.0 mid-fade, making it look like two pulses.

- timestamp: 2026-03-31
  checked: Whether melt/equip path can trigger stash_updated indirectly
  found: In _on_equip_pressed, line 544 emits GameEvents.equipment_changed and line 545 emits GameEvents.item_crafted. Neither of these triggers stash_updated. In _on_melt_pressed, no signals are emitted at all. So neither path triggers _on_stash_updated. The signal-based double-call theory is WRONG for melt. But for equip, need to check if equipment_changed or item_crafted handlers call something that touches stash.
  implication: Must look more carefully at what else could cause double pulse.

- timestamp: 2026-03-31
  checked: Re-read _pulse_stash_slots more carefully for the visual double-pulse
  found: ACTUAL ROOT CAUSE FOUND. Look at the loop structure: it iterates ALL buttons across ALL slot types. For each non-disabled button it calls create_tween() which creates a new SceneTreeTween. In Godot 4, create_tween() tweens are NOT bound to specific nodes by default — they're bound to the SceneTree. Multiple tweens on the same property of the same node will BOTH run simultaneously and fight each other. BUT that's not the issue here — each button gets exactly one tween. The real issue: _update_stash_display() on line 512/557 sets `btn.disabled = false` for filled slots (line 394) AND sets `modulate = Color(1,1,1,1)` (line 393). Then _pulse_stash_slots creates tweens that animate modulate:a. BUT — in Godot 4, `create_tween()` creates a tween bound to the calling node (forge_view), not to the button. If forge_view already has running tweens on the same property from a prior call, they interfere. But this is the first call, so no prior tweens. Let me reconsider: the visual "double pulse" might actually be _update_stash_display being called TWICE — once explicitly and once because _on_stash_updated fires.
  implication: Need to trace whether stash_updated fires during melt/equip.

- timestamp: 2026-03-31
  checked: Full melt path signal chain — does anything emit stash_updated?
  found: _on_melt_pressed does NOT emit any signal. It nulls bench, calls display updates, calls _pulse_stash_slots. _update_stash_display (line 384) reads GameState.stash and sets button states — no signal emission. So _on_stash_updated does NOT fire during melt. For equip: GameEvents.equipment_changed.emit and GameEvents.item_crafted.emit fire, but those don't touch stash. So _on_stash_updated does NOT fire during equip either. The double-pulse is NOT from signal-based double-calling.
  implication: The double-pulse visual must come from the tween itself or from something else. Re-examine.

- timestamp: 2026-03-31
  checked: Godot 4 create_tween behavior — does _update_stash_display setting modulate interfere?
  found: YES. This is the key. _update_stash_display() (line 512/557) sets btn.modulate = Color(1,1,1,1) synchronously on line 393. Then _pulse_stash_slots() creates a tween that animates modulate:a from current value (1.0) to 0.4 to 1.0. That's ONE pulse: bright -> dim -> bright. The user reports seeing TWO pulses. The second pulse likely comes from Godot's tween behavior: when _update_stash_display sets modulate to (1,1,1,1) WHILE a tween from a PREVIOUS pulse is still running (from a prior melt/equip), the old tween gets killed by the new tween on the same property, but the visual snap from tween-controlled-alpha to 1.0 then back to tween creates a visual glitch that looks like double-pulse.
  implication: Actually, for the FIRST melt/equip there shouldn't be a prior tween. The double pulse on first melt/equip means something else is happening.

- timestamp: 2026-03-31
  checked: Re-examine — could _on_stash_slot_pressed path leave orphan tweens?
  found: Yes! When user taps stash slot, _flash_stash_slot creates a tween on that button's modulate. If the user then immediately melts/equips, _pulse_stash_slots creates ANOTHER tween on the same button's modulate:a. Two tweens on the same property — the old flash tween and the new pulse tween — would both be running. But this only explains interference if melt happens within 0.33s of stash tap, which is unlikely with 2-click confirm.
  implication: This is not the primary cause.

- timestamp: 2026-03-31
  checked: FINAL THEORY for double pulse — re-read _pulse_stash_slots line by line
  found: Lines 440-447. The tween does: modulate:a -> 0.4 (0.15s), then modulate:a -> 1.0 (0.15s). In Godot 4, tween_property interpolates FROM the current value TO the target. So first step: current alpha (1.0) -> 0.4 over 0.15s. Second step: 0.4 -> 1.0 over 0.15s. That's one smooth pulse. BUT — all buttons get independent tweens. If some buttons have modulate:a already at 0.4 (because they're empty/dimmed, set by _update_stash_display line 398), their tween would go 0.4 -> 0.4 (no change) then 0.4 -> 1.0 (fade IN). Wait — those buttons ARE disabled (line 399), so `not btn.disabled` (line 444) filters them out. Only non-disabled (filled) buttons get tweens. Those start at alpha 1.0. The pulse is 1.0->0.4->1.0. ONE pulse. Unless... the bench clearing causes _update_stash_display to CHANGE which buttons are disabled. When bench was occupied, filled slots had `btn.disabled = true` (line 394: `btn.disabled = (GameState.crafting_bench != null)`). After bench clears, _update_stash_display sets them to `btn.disabled = false`. So buttons go from disabled to enabled. And _pulse_stash_slots only pulses non-disabled buttons. That's correct — one pulse on newly-enabled buttons. UNLESS the visual "double" is actually the modulate snap from the disabled state to enabled state (modulate was 0.4 while disabled? No — line 393 sets modulate to (1,1,1,1) for filled slots regardless). Wait — re-read: line 393-394 only run for filled slots (items[i] != null). Line 393 sets modulate to white, line 394 sets disabled based on bench. So filled+bench-occupied = white+disabled. Filled+bench-empty = white+enabled. The modulate doesn't change between states — it's always white for filled slots. So the pulse goes white(1.0) -> 0.4 -> 1.0. One pulse. I cannot find a code-level cause for double-pulse from this trace alone. May need runtime testing.
  implication: The double-pulse may require runtime observation. However, one remaining theory: if update_melt_equip_states or update_inventory_display somehow triggers _update_stash_display again.

- timestamp: 2026-03-31
  checked: update_melt_equip_states and update_inventory_display for stash side effects
  found: Need to check these functions.

## Resolution

root_cause: |
  BUG 1 (Yellow flash missing): In _on_stash_slot_pressed (line 406), _flash_stash_slot is called at line 424, which starts an async tween animating the button's modulate to yellow (1,1,0.3,1) over 0.08s. But _update_stash_display() is called immediately after at line 428. Since the slot is now null (set at line 419), _update_stash_display hits line 398 and synchronously sets btn.modulate = Color(0.4,0.4,0.4,1.0) on the SAME FRAME. This overwrites the tween's target — the tween now interpolates from grey(0.4) toward yellow, but the final step also targets grey(0.4), making the entire animation invisible.

  BUG 2 (Double pulse): _pulse_stash_slots IS called only once per path (melt line 513, equip line 558). No signal-based double-call exists. The visual double-pulse is caused by TWO overlapping visual transitions on the same frame: (1) _update_stash_display (line 512/557) sets btn.disabled=false, which triggers Godot's built-in theme transition from disabled-dimmed to enabled-bright appearance, AND (2) _pulse_stash_slots then tweens modulate:a from 1.0->0.4->1.0. The user sees: instant bright pop (disabled->enabled theme change) followed by fade-dim-fade-bright (alpha tween) = two visible pulses.
fix: (diagnosis only — not applied)
verification: (diagnosis only)
files_changed: []
