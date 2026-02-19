extends Node

# Core gameplay signals for cross-scene communication
signal equipment_changed(slot: String, item: Item)
signal item_crafted(item: Item)
signal area_cleared(area_level: int)

# Combat signals for pack-based combat loop
signal combat_started(area_level: int, pack_count: int)
signal pack_killed(pack_index: int, total_packs: int)
signal hero_attacked(damage: float, is_crit: bool)
signal pack_attacked(result: Dictionary)
signal hero_died()
signal map_completed(area_level: int)
signal combat_stopped()

# Drop system signals (Phase 16/33)
signal currency_dropped(drops: Dictionary)  # Per-pack currency drops
signal items_dropped(area_level: int)  # Per-pack item drops (always 1 item, Normal rarity)

# Save system signals (Phase 18)
signal save_completed()
signal save_failed()

# Import/Export signals (Phase 21)
signal export_completed()
signal import_failed()
