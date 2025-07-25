---------------------------------------------------------------------------------------------------------
-- 生命回复增强
---------------------------------------------------------------------------------------------------------

function ItemAbility_hoshiguma_cup_hp_ragen_amplfy_percentage(keys)
    local caster = keys.caster
    local ability = keys.ability
    caster:AddNewModifier(caster, ability, "modifier_item_hoshiguma_cup_hp_ragen_amplfy_percentage", {})
end

function ItemAbility_hoshiguma_cup_hp_ragen_amplfy_percentage_destroy(keys)
    local caster = keys.caster
    if caster ~= nil and not caster:IsNull() and not caster:HasModifier("modifier_item_hoshiguma_cup") then
        caster:RemoveModifierByName("modifier_item_hoshiguma_cup_hp_ragen_amplfy_percentage")
    end
end

modifier_item_hoshiguma_cup_hp_ragen_amplfy_percentage = class({})
LinkLuaModifier("modifier_item_hoshiguma_cup_hp_ragen_amplfy_percentage", "items/item_hoshiguma_cup.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_item_hoshiguma_cup_hp_ragen_amplfy_percentage:IsDebuff() return false end
function modifier_item_hoshiguma_cup_hp_ragen_amplfy_percentage:IsHidden() return true end
function modifier_item_hoshiguma_cup_hp_ragen_amplfy_percentage:IsPurgable() return false end
function modifier_item_hoshiguma_cup_hp_ragen_amplfy_percentage:RemoveOnDeath() return false end

function modifier_item_hoshiguma_cup_hp_ragen_amplfy_percentage:OnCreated(params)
    if not IsServer() then return end
end

function modifier_item_hoshiguma_cup_hp_ragen_amplfy_percentage:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE
    }
end

function modifier_item_hoshiguma_cup_hp_ragen_amplfy_percentage:GetModifierHPRegenAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_hp_ragen_amplfy_percentage")
end

---------------------------------------------------------------------------------------------------------
-- 状态抗性
---------------------------------------------------------------------------------------------------------

function ItemAbility_hoshiguma_cup_status_resistance(keys)
    local caster = keys.caster
    local ability = keys.ability
    caster:AddNewModifier(caster, ability, "modifier_item_hoshiguma_cup_status_resistance", {})
end

function ItemAbility_hoshiguma_cup_status_resistance_destroy(keys)
    local caster = keys.caster
    if caster ~= nil and not caster:IsNull() and not caster:HasModifier("modifier_item_hoshiguma_cup") then
        caster:RemoveModifierByName("modifier_item_hoshiguma_cup_status_resistance")
    end
end

modifier_item_hoshiguma_cup_status_resistance = class({})
LinkLuaModifier("modifier_item_hoshiguma_cup_status_resistance", "items/item_hoshiguma_cup.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_item_hoshiguma_cup_status_resistance:IsDebuff() return false end
function modifier_item_hoshiguma_cup_status_resistance:IsHidden() return true end
function modifier_item_hoshiguma_cup_status_resistance:IsPurgable() return false end
function modifier_item_hoshiguma_cup_status_resistance:RemoveOnDeath() return false end

function modifier_item_hoshiguma_cup_status_resistance:OnCreated(params)
    if not IsServer() then return end
end

function modifier_item_hoshiguma_cup_status_resistance:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING
    }
end

function modifier_item_hoshiguma_cup_status_resistance:GetModifierStatusResistanceStacking()
    return self:GetAbility():GetSpecialValueFor("bonus_status_resistance")
end