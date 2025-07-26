LinkLuaModifier( "modifier_item_hoshiguma_cup", "scripts/vscripts/items/item_hoshiguma_cup.lua.lua", LUA_MODIFIER_MOTION_NONE )
--Abilities
if item_hoshiguma_cup == nil then
	item_hoshiguma_cup = class({})
end
function item_hoshiguma_cup:GetIntrinsicModifierName()
	return "modifier_item_hoshiguma_cup"
end
---------------------------------------------------------------------
--Modifiers
if modifier_item_hoshiguma_cup == nil then
	modifier_item_hoshiguma_cup = class({})
end
function modifier_item_hoshiguma_cup:OnCreated(params)
	if IsServer() then
	end
end
function modifier_item_hoshiguma_cup:OnRefresh(params)
	if IsServer() then
	end
end
function modifier_item_hoshiguma_cup:OnDestroy()
	if IsServer() then
	end
end
function modifier_item_hoshiguma_cup:DeclareFunctions()
	return {
	}
end