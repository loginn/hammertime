class_name TotemPieceFactory extends RefCounted


static func can_afford(material_tier: Tag_List.MaterialTier) -> bool:
	match material_tier:
		Tag_List.MaterialTier.ASH:
			return GameState.currency_counts.get("ash", 0) >= BalanceConfig.BASE_TOTEM_ASH_COST
		Tag_List.MaterialTier.OAK:
			return GameState.currency_counts.get("oak", 0) >= BalanceConfig.BASE_TOTEM_OAK_COST
		_:
			return false


static func create_base(material_tier: Tag_List.MaterialTier) -> TotemPiece:
	if not can_afford(material_tier):
		return null

	match material_tier:
		Tag_List.MaterialTier.ASH:
			GameState.spend_currency("ash", BalanceConfig.BASE_TOTEM_ASH_COST)
		Tag_List.MaterialTier.OAK:
			GameState.spend_currency("oak", BalanceConfig.BASE_TOTEM_OAK_COST)
		_:
			return null

	var piece := TotemPiece.new()
	piece.material_tier = material_tier
	piece.rarity = CraftableItem.Rarity.NORMAL
	piece.item_name = Tag_List.material_name(material_tier) + " Totem"
	piece.base_id = "totem_" + Tag_List.material_name(material_tier).to_lower()
	return piece
