LinkLuaModifier( "modifier_item_ibaraki_masu", "scripts/vscripts/items/item_ibaraki_masu.lua.lua", LUA_MODIFIER_MOTION_NONE )
--Abilities
if item_ibaraki_masu == nil then
	item_ibaraki_masu = class({})
end
function item_ibaraki_masu:GetIntrinsicModifierName()
	return "modifier_item_ibaraki_masu"
end
---------------------------------------------------------------------
--Modifiers
if modifier_item_ibaraki_masu == nil then
	modifier_item_ibaraki_masu = class({})
end
function modifier_item_ibaraki_masu:OnCreated(params)
	if IsServer() then
	end
end
function modifier_item_ibaraki_masu:OnRefresh(params)
	if IsServer() then
	end
end
function modifier_item_ibaraki_masu:OnDestroy()
	if IsServer() then
	end
end
function modifier_item_ibaraki_masu:DeclareFunctions()
	return {
	}
end