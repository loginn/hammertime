---
status: resolved
trigger: "Runic Hammer guarantees 2 mods instead of randomly giving 1 or 2"
created: 2026-02-16T00:00:00Z
updated: 2026-02-16T00:00:00Z
---

## Current Focus

hypothesis: RARITY_LIMITS for MAGIC sets independent per-type limits (1 prefix + 1 suffix = 2 capacity) with no total mod cap, and the fallback logic guarantees both slots fill when mod_count = 2
test: Traced all code paths through _do_apply, add_prefix, add_suffix, RARITY_LIMITS
expecting: n/a - diagnosis complete
next_action: Report findings

## Symptoms

expected: Runic Hammer randomly adds 1 or 2 mods when upgrading Normal -> Magic
actual: Always adds exactly 2 mods (1 prefix + 1 suffix)
errors: None (behavioral bug, not a crash)
reproduction: Apply Runic Hammer to any Normal item; inspect prefixes/suffixes; always see 1 of each
started: Unknown - may have been this way since implementation

## Eliminated

- hypothesis: Extra mods added by crafting_view.gd or game_state.gd after _do_apply
  evidence: crafting_view.gd:138 calls selected_currency.apply() which calls _do_apply() and nothing else adds mods. No signals trigger additional affix additions.
  timestamp: 2026-02-16

- hypothesis: add_prefix() or add_suffix() adds more than one affix per call
  evidence: item.gd:140-163 (add_prefix) and item.gd:166-189 (add_suffix) each append exactly ONE affix to their respective array and return true. No multi-add path.
  timestamp: 2026-02-16

- hypothesis: No valid prefixes/suffixes for item types causing unexpected fallback behavior
  evidence: All 5 item bases (LightSword, BasicArmor, BasicHelmet, BasicBoots, BasicRing) have valid_tags that match multiple prefixes AND suffixes in ItemAffixes. add_prefix()/add_suffix() will succeed on any fresh item.
  timestamp: 2026-02-16

- hypothesis: RNG seed not randomized, producing deterministic sequence
  evidence: No seed() or set_seed() calls in codebase. Godot 4 auto-seeds on startup. randi_range(1, 2) should produce 1 or 2 with equal probability.
  timestamp: 2026-02-16

## Evidence

- timestamp: 2026-02-16
  checked: runic_hammer.gd _do_apply method (lines 18-38)
  found: |
    Line 20: item.rarity = Item.Rarity.MAGIC (sets rarity first)
    Line 23: var mod_count = randi_range(1, 2) -- requests 1 or 2 mods
    Lines 28-35: fallback logic ensures that if prefix fails, suffix is tried (and vice versa)
    Comment on line 22 says "Add 1-2 random mods total" confirming design intent
  implication: Code intends 1-2 mods but the fallback + RARITY_LIMITS structure may guarantee 2

- timestamp: 2026-02-16
  checked: item.gd RARITY_LIMITS (lines 5-9)
  found: |
    Rarity.MAGIC: { "prefixes": 1, "suffixes": 1 }
    Limits are PER-TYPE (1 prefix max, 1 suffix max) not TOTAL (2 total)
    No "total" mod limit exists in the data structure
  implication: Magic items have room for exactly 2 mods (1 prefix + 1 suffix). There is no mechanism to enforce "1 total mod" at the rarity level.

- timestamp: 2026-02-16
  checked: item.gd add_prefix() (lines 140-163) and add_suffix() (lines 166-189)
  found: |
    add_prefix checks len(self.prefixes) >= max_prefixes() (which is 1 for MAGIC)
    On a fresh MAGIC item with 0 prefixes, this check passes (0 < 1)
    Picks a random valid prefix from ItemAffixes.prefixes filtered by has_valid_tag()
    Returns true on success, false only if at limit or no valid affixes
  implication: On a fresh item, both add_prefix and add_suffix always succeed

- timestamp: 2026-02-16
  checked: tack_hammer.gd (adds 1 mod to Magic items)
  found: |
    TackHammer exists specifically to add a single mod to Magic items
    Its can_apply() checks if prefixes.size() < max_prefixes() OR suffixes.size() < max_suffixes()
    This means Magic items are DESIGNED to sometimes have open mod slots (fewer than 2 mods)
  implication: TackHammer would be useless on Runic Hammer'd items if Runic always gives 2 mods. Confirms the bug breaks game design.

- timestamp: 2026-02-16
  checked: loot_table.gd spawn_item_with_mods() (lines 200-225)
  found: |
    Lines 209-222: Uses identical pattern to runic_hammer.gd for Magic items
    var mod_count: int = randi_range(1, 2) -- same 1-2 range
    Same fallback logic (prefix fails -> try suffix, suffix fails -> try prefix)
  implication: Same structural issue exists in loot generation. Magic items from drops may also always get 2 mods.

- timestamp: 2026-02-16
  checked: Godot 4 randi_range(1, 2) behavior
  found: Returns random integer in inclusive range [1, 2]. Both bounds inclusive. Should return 1 or 2 with equal probability.
  implication: randi_range itself is correct. The 50% chance of mod_count=1 should produce single-mod items.

- timestamp: 2026-02-16
  checked: Full code path trace for mod_count = 1
  found: |
    When mod_count = 1: loop runs once, either add_prefix() or add_suffix() succeeds
    (fresh item always has room). The "if not" fallback does NOT trigger because the
    first call succeeds. Result: exactly 1 mod. This is correct.
  implication: When randi_range returns 1, only 1 mod is added. The code path is sound.

- timestamp: 2026-02-16
  checked: Full code path trace for mod_count = 2
  found: |
    When mod_count = 2: loop runs twice. First iteration adds 1 mod (prefix or suffix).
    Second iteration: if same type chosen, it fails (at limit) and fallback adds the other type.
    If different type chosen, it succeeds directly.
    Either way: exactly 1 prefix + 1 suffix. Always 2 mods.
  implication: When randi_range returns 2, you always get exactly 2 mods with 1 prefix + 1 suffix. The fallback guarantees this.

## Resolution

root_cause: |
  PRIMARY: The RARITY_LIMITS structure in item.gd line 7 defines Magic item capacity as
  independent per-type limits: { "prefixes": 1, "suffixes": 1 }. This creates a total
  capacity of 2 mods with no "total mods" enforcement mechanism.

  Combined with the fallback logic in runic_hammer.gd lines 28-35 (if prefix fails, try
  suffix; if suffix fails, try prefix), whenever mod_count = 2 (50% of the time via
  randi_range(1, 2) on line 23), both the prefix and suffix slots are GUARANTEED to be
  filled. The fallback never lets a mod attempt "waste" an iteration.

  The code at line 23 (randi_range(1, 2)) does correctly produce mod_count = 1 half the
  time, which should result in only 1 mod. If the user is consistently seeing 2 mods on
  every application, the most likely explanation is small sample size with unlucky RNG (50%
  chance compounds: 3 consecutive 2-mod results has 12.5% probability).

  HOWEVER, there is a confirmed design mismatch: TackHammer (tack_hammer.gd) exists
  specifically to add 1 mod to Magic items that have open slots. If Runic Hammer frequently
  fills both slots (50% of the time), TackHammer's utility is significantly reduced. The
  system design implies Magic items should more reliably start with 1 mod, making TackHammer
  a meaningful "add another mod" currency.

  DUPLICATE ISSUE: loot_table.gd:210 uses the identical pattern for spawning Magic items
  from drops (randi_range(1, 2) with same fallback logic). The same behavior applies there.

fix: |
  Not yet applied (diagnosis only). Two approaches:

  APPROACH A - Bias the mod_count toward 1:
    In runic_hammer.gd line 23, change randi_range(1, 2) to a weighted roll that favors 1.
    For example, use a weighted random where 1 has 70% weight and 2 has 30% weight.
    This preserves the existing RARITY_LIMITS structure but makes TackHammer more relevant.
    Same change needed in loot_table.gd:210.

  APPROACH B - Always add exactly 1 mod:
    In runic_hammer.gd, change mod_count to always be 1.
    This makes Runic Hammer consistently add 1 mod, and TackHammer becomes the way to add
    a second mod. Clean division of responsibility between currencies.
    Would need to evaluate loot_table.gd separately (drops might still want 1-2).

  APPROACH C - Add total mod limit to RARITY_LIMITS:
    Add a "total" key to RARITY_LIMITS: Rarity.MAGIC: { "prefixes": 1, "suffixes": 1, "total": 2 }
    Enforce total limit in add_prefix/add_suffix. This is a larger refactor but more architecturally sound.
    However, this alone doesn't solve the problem since the total for Magic would still be 2.

  RECOMMENDED: Approach A or B depending on desired game feel. The simplest fix that makes
  TackHammer meaningful is Approach B (Runic always adds 1, TackHammer adds the 2nd).

verification: Not yet verified (diagnosis only)

files_changed: []

## Artifacts

### Primary Files

1. `/var/home/travelboi/Programming/hammertime/models/currencies/runic_hammer.gd`
   - Line 23: `var mod_count = randi_range(1, 2)` -- the mod count roll
   - Lines 28-35: fallback logic that guarantees both slots fill when mod_count = 2

2. `/var/home/travelboi/Programming/hammertime/models/items/item.gd`
   - Line 7: `Rarity.MAGIC: { "prefixes": 1, "suffixes": 1 }` -- per-type limits (not total)
   - Lines 140-163: `add_prefix()` -- always succeeds on fresh items
   - Lines 166-189: `add_suffix()` -- always succeeds on fresh items

### Secondary Files (same pattern, same issue)

3. `/var/home/travelboi/Programming/hammertime/models/loot/loot_table.gd`
   - Line 210: `var mod_count: int = randi_range(1, 2)` -- duplicate pattern for Magic drops
   - Lines 211-222: identical fallback logic

### Related Files (affected by this behavior)

4. `/var/home/travelboi/Programming/hammertime/models/currencies/tack_hammer.gd`
   - Adds 1 mod to Magic items; utility is reduced if Runic always fills both slots
