item_esdw = {}

function item_esdw:GetIntrinsicModifierName()
    return "modifier_item_esdw_passive"
end

modifier_item_esdw_passive = {}
LinkLuaModifier("modifier_item_esdw_passive","items/item_esdw.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_item_esdw_passive:IsHidden() return false end
function modifier_item_esdw_passive:IsDebuff() return false end
function modifier_item_esdw_passive:IsPurgable() return false end
function modifier_item_esdw_passive:IsPurgeException() return false end
function modifier_item_esdw_passive:RemoveOnDeath() return false end

function modifier_item_esdw_passive:DeclareFunctions() return
    {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE,
        MODIFIER_PROPERTY_CAST_RANGE_BONUS,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_EXTRA_MANA_BONUS_PERCENTAGE
    }
end

function modifier_item_esdw_passive:GetModifierBonusStats_Strength() return self:GetAbility():GetSpecialValueFor("bonus_strength") end
function modifier_item_esdw_passive:GetModifierBonusStats_Intellect() return self:GetAbility():GetSpecialValueFor("bonus_intellect") end
function modifier_item_esdw_passive:GetModifierAttackRangeBonus() return self:GetAbility():GetSpecialValueFor("bonus_attack_range") end
function modifier_item_esdw_passive:GetModifierHPRegenAmplify_Percentage() return self:GetAbility():GetSpecialValueFor("bonus_hp_regen_amplify_percentage") end
function modifier_item_esdw_passive:GetModifierExtraHealthPercentage() return self:GetAbility():GetSpecialValueFor("bonus_extra_health_percentage") end
function modifier_item_esdw_passive:GetModifierCastRangeBonus() return self:GetAbility():GetSpecialValueFor("bonus_cast_range") end
function modifier_item_esdw_passive:GetModifierSpellAmplify_Percentage() return self:GetAbility():GetSpecialValueFor("bonus_spell_amplify_percentage") end
function modifier_item_esdw_passive:GetModifierExtraManaBonusPercentage() return self:GetAbility():GetSpecialValueFor("bonus_extra_mana_percentage") end
function modifier_item_esdw_passive:OnCreated()
    if not IsServer() then return end
end