LinkLuaModifier( "modifier_abilityItem", "scripts/vscripts/abilities/abilityItem.lua.lua", LUA_MODIFIER_MOTION_NONE )
--Abilities
if abilityItem == nil then
	abilityItem = class({})
end
function abilityItem:GetIntrinsicModifierName()
	return "modifier_abilityItem"
end
---------------------------------------------------------------------
--Modifiers
if modifier_abilityItem == nil then
	modifier_abilityItem = class({})
end
function modifier_abilityItem:OnCreated(params)
	if IsServer() then
	end
end
function modifier_abilityItem:OnRefresh(params)
	if IsServer() then
	end
end
function modifier_abilityItem:OnDestroy()
	if IsServer() then
	end
end
function modifier_abilityItem:DeclareFunctions()
	return {
	}
end