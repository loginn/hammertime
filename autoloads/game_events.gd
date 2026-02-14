extends Node

# Core gameplay signals for cross-scene communication
signal equipment_changed(slot: String, item: Item)
signal item_crafted(item: Item)
signal area_cleared(area_level: int)
