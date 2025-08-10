item_hoshiguma_cup = {}

function item_hoshiguma_cup:GetIntrinsicModifierName()
    return "modifier_item_hoshiguma_cup_passive"
end

modifier_item_hoshiguma_cup_passive = {}
LinkLuaModifier("modifier_item_hoshiguma_cup_passive","items/item_hoshiguma_cup.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_item_hoshiguma_cup_passive:IsHidden() return true end
function modifier_item_hoshiguma_cup_passive:IsDebuff() return false end
function modifier_item_hoshiguma_cup_passive:IsPurgable() return false end
function modifier_item_hoshiguma_cup_passive:IsPurgeException() return false end
function modifier_item_hoshiguma_cup_passive:RemoveOnDeath() return false end

function modifier_item_hoshiguma_cup_passive:DeclareFunctions() return
    {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE
    }
end

function modifier_item_hoshiguma_cup_passive:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE -- 允许多个相同修饰器共存
end

function modifier_item_hoshiguma_cup_passive:GetModifierBonusStats_Strength() return self:GetAbility():GetSpecialValueFor("bonus_strength") end
function modifier_item_hoshiguma_cup_passive:GetModifierHPRegenAmplify_Percentage() return self:GetAbility():GetSpecialValueFor("bonus_hp_ragen_amplfy_percentage") end
function modifier_item_hoshiguma_cup_passive:GetModifierAttackRangeBonus()
    if not self:GetCaster():IsRangedAttacker() and not self:GetParent():HasModifier("modifier_item_kafziel_attack_range_bonus") then
        return self:GetAbility():GetSpecialValueFor("bonus_attack_range")
    end
end