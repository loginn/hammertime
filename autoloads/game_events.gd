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
