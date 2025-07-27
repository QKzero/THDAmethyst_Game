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
-- 技能冷却降低
---------------------------------------------------------------------------------------------------------

-- 物品装备时添加冷却降低效果
function ItemAbility_ibaraki_masu_cooldown_reduction(keys)
    local caster = keys.caster
    local ability = keys.ability
    caster:AddNewModifier(caster, ability, "modifier_item_ibaraki_masu_cooldown_reduction", {})
end

-- 物品卸下时移除冷却降低效果
function ItemAbility_ibaraki_masu_cooldown_reduction_destroy(keys)
    local caster = keys.caster
    if caster ~= nil and not caster:IsNull() and not caster:HasModifier("modifier_item_ibaraki_masu") then
        caster:RemoveModifierByName("modifier_item_ibaraki_masu_cooldown_reduction")
    end
end

-- 冷却降低效果实现
modifier_item_ibaraki_masu_cooldown_reduction = class({})
LinkLuaModifier("modifier_item_ibaraki_masu_cooldown_reduction", "items/item_ibaraki_masu.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_item_ibaraki_masu_cooldown_reduction:IsDebuff() return false end
function modifier_item_ibaraki_masu_cooldown_reduction:IsHidden() return true end
function modifier_item_ibaraki_masu_cooldown_reduction:IsPurgable() return false end
function modifier_item_ibaraki_masu_cooldown_reduction:RemoveOnDeath() return false end

function modifier_item_ibaraki_masu_cooldown_reduction:OnCreated()
    -- 服务端专用逻辑
    if not IsServer() then return end
    -- 可以在这里添加初始化逻辑（如有需要）
end

function modifier_item_ibaraki_masu_cooldown_reduction:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE  -- 冷却缩减百分比属性
    }
end

function modifier_item_ibaraki_masu_cooldown_reduction:GetModifierPercentageCooldown()
    -- 从物品特殊值获取冷却缩减百分比
    return self:GetAbility():GetSpecialValueFor("bonus_cooldown_reduction")
end