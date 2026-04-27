extends Node

signal equipment_changed(slot: int, item: HeroItem)
signal item_crafted(item: HeroItem)
signal item_melted(item: HeroItem)

signal expedition_started(expedition_id: String)
signal expedition_completed(expedition_id: String, rewards: Dictionary)
signal expedition_collected(expedition_id: String)

signal prestige_triggered()
signal prestige_completed()

signal currency_changed(currency_key: String, new_amount: int)
signal inventory_changed(slot: int)
