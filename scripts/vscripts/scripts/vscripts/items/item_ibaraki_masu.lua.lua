LinkLuaModifier( "modifier_item_cht", "scripts/vscripts/items/item_cht.lua.lua", LUA_MODIFIER_MOTION_NONE )
--Abilities
if item_cht == nil then
	item_cht = class({})
end
function item_cht:GetIntrinsicModifierName()
	return "modifier_item_cht"
end
---------------------------------------------------------------------
--Modifiers
if modifier_item_cht == nil then
	modifier_item_cht = class({})
end
function modifier_item_cht:OnCreated(params)
	if IsServer() then
	end
end
function modifier_item_cht:OnRefresh(params)
	if IsServer() then
	end
end
function modifier_item_cht:OnDestroy()
	if IsServer() then
	end
end
function modifier_item_cht:DeclareFunctions()
	return {
	}
end