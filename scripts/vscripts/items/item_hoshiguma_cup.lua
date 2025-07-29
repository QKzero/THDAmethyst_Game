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
-- 攻击距离（近战）
---------------------------------------------------------------------------------------------------------

function ItemAbility_hoshiguma_cup_attack_range_bonus(keys)
    local caster = keys.caster
    local ability = keys.ability
    caster:AddNewModifier(caster, ability, "modifier_item_hoshiguma_cup_attack_range_bonus", {})
end

function ItemAbility_hoshiguma_cup_attack_range_bonus_destroy(keys)
    local caster = keys.caster
    if caster ~= nil and not caster:IsNull() and not caster:HasModifier("modifier_item_hoshiguma_cup") then
        caster:RemoveModifierByName("modifier_item_hoshiguma_cup_attack_range_bonus")
    end
end

modifier_item_hoshiguma_cup_attack_range_bonus = class({})
LinkLuaModifier("modifier_item_hoshiguma_cup_attack_range_bonus", "items/item_hoshiguma_cup.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_item_hoshiguma_cup_attack_range_bonus:IsDebuff() return false end
function modifier_item_hoshiguma_cup_attack_range_bonus:IsHidden() return true end
function modifier_item_hoshiguma_cup_attack_range_bonus:IsPurgable() return false end
function modifier_item_hoshiguma_cup_attack_range_bonus:RemoveOnDeath() return false end

function modifier_item_hoshiguma_cup_attack_range_bonus:OnCreated(params)
    if not IsServer() then return end
end

function modifier_item_hoshiguma_cup_attack_range_bonus:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS
    }
end

function modifier_item_hoshiguma_cup_attack_range_bonus:GetModifierAttackRangeBonus()
    if not self:GetCaster():IsRangedAttacker() and not self:GetParent():HasModifier("modifier_item_kafziel_attack_range_bonus") then
        return self:GetAbility():GetSpecialValueFor("bonus_attack_range")
    end
end