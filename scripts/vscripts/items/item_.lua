LinkLuaModifier( "modifier_item_", "items/item_.lua", LUA_MODIFIER_MOTION_NONE )
--Abilities
if item_ == nil then
	item_ = class({})
end
function item_:GetIntrinsicModifierName()
	return "modifier_item_"
end
---------------------------------------------------------------------
--Modifiers
if modifier_item_ == nil then
	modifier_item_ = class({})
end
function modifier_item_:OnCreated(params)
	if IsServer() then
	end
end
function modifier_item_:OnRefresh(params)
	if IsServer() then
	end
end
function modifier_item_:OnDestroy()
	if IsServer() then
	end
end
function modifier_item_:DeclareFunctions()
	return {
	}
end