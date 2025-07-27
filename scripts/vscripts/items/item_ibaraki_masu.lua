---------------------------------------------------------------------------------------------------------
-- 施法距离
---------------------------------------------------------------------------------------------------------

-- function ItemAbility_ibaraki_masu_cast_range(keys)
-- 	local caster = keys.caster
-- 	local ability = keys.ability
--     caster:AddNewModifier(caster, ability, "modifier_item_ibaraki_masu_cast_range",{ })
-- end

-- function ItemAbility_ibaraki_masu_cast_range_destroy(keys)
-- 	local caster = keys.caster
-- 	if caster ~= nil and not caster:IsNull() and not caster:HasModifier("modifier_item_ibaraki_masu") then
--         caster:RemoveModifierByName("modifier_item_ibaraki_masu_cast_range")
--     end
-- end

-- modifier_item_ibaraki_masu_cast_range = class({})
-- LinkLuaModifier("modifier_item_ibaraki_masu_cast_range", "items/item_ibaraki_masu.lua", LUA_MODIFIER_MOTION_NONE)

-- function modifier_item_ibaraki_masu_cast_range:IsDebuff() return false end
-- function modifier_item_ibaraki_masu_cast_range:IsHidden() return true end
-- function modifier_item_ibaraki_masu_cast_range:IsPurgable() return false end
-- function modifier_item_ibaraki_masu_cast_range:RemoveOnDeath() return false end

-- function modifier_item_ibaraki_masu_cast_range:OnCreated(params)
--     if not IsServer() then return end
-- end

-- function modifier_item_ibaraki_masu_cast_range:DeclareFunctions()
-- 	return {
-- 		MODIFIER_PROPERTY_CAST_RANGE_BONUS
-- 	}
-- end

-- function modifier_item_ibaraki_masu_cast_range:GetModifierCastRangeBonus() return 
--     self:GetAbility():GetSpecialValueFor("bonus_cast_range") 
-- end

---------------------------------------------------------------------------------------------------------
-- 魔法消耗降低
---------------------------------------------------------------------------------------------------------

function ItemAbility_ibaraki_masu_manacost_percentage(keys)
	local caster = keys.caster
	local ability = keys.ability
    caster:AddNewModifier(caster, ability, "modifier_item_ibaraki_masu_manacost_percentage",{ })
end

function ItemAbility_ibaraki_masu_manacost_percentage_destroy(keys)
	local caster = keys.caster
	if caster ~= nil and not caster:IsNull() and not caster:HasModifier("modifier_item_ibaraki_masu") then
        caster:RemoveModifierByName("modifier_item_ibaraki_masu_manacost_percentage")
    end
end

modifier_item_ibaraki_masu_manacost_percentage = class({})
LinkLuaModifier("modifier_item_ibaraki_masu_manacost_percentage", "items/item_ibaraki_masu.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_item_ibaraki_masu_manacost_percentage:IsDebuff() return false end
function modifier_item_ibaraki_masu_manacost_percentage:IsHidden() return true end
function modifier_item_ibaraki_masu_manacost_percentage:IsPurgable() return false end
function modifier_item_ibaraki_masu_manacost_percentage:RemoveOnDeath() return false end

function modifier_item_ibaraki_masu_manacost_percentage:OnCreated(params)
    if not IsServer() then return end
end
function modifier_item_ibaraki_masu_manacost_percentage:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MANA_DRAIN_AMPLIFY_PERCENTAGE
	}
end

function modifier_item_ibaraki_masu_manacost_percentage:GetModifierPercentageManacostStacking() 
	return -self:GetAbility():GetSpecialValueFor("bonus_manacost_percentage") 
end