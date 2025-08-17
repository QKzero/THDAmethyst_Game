item_sss = {}

function item_sss:GetIntrinsicModifierName()
    return "modifier_item_sss_passive"
end

modifier_item_sss_passive = {}
LinkLuaModifier("modifier_item_sss_passive","items/item_sss.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_item_sss_passive:IsHidden() return true end
function modifier_item_sss_passive:IsDebuff() return false end
function modifier_item_sss_passive:IsPurgable() return false end
function modifier_item_sss_passive:IsPurgeException() return false end
function modifier_item_sss_passive:RemoveOnDeath() return false end

function modifier_item_sss_passive:DeclareFunctions() return
    {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_CASTTIME_PERCENTAGE
    }
end

function modifier_item_sss_passive:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE -- 允许多个相同修饰器共存
end

function modifier_item_sss_passive:GetModifierBonusStats_Agility() return self:GetAbility():GetSpecialValueFor("bonus_agility") end
function modifier_item_sss_passive:GetModifierBonusStats_Intellect() return self:GetAbility():GetSpecialValueFor("bonus_intellect") end
function modifier_item_sss_passive:GetModifierAttackSpeedBonus_Constant() return self:GetAbility():GetSpecialValueFor("bonus_attack_speed") end
function modifier_item_sss_passive:GetModifierMoveSpeedBonus_Percentage() return self:GetAbility():GetSpecialValueFor("bonus_move_speed") end
function modifier_item_sss_passive:GetModifierSpellAmplify_Percentage() return self:GetAbility():GetSpecialValueFor("bonus_spell_amplify_percentage") end
function modifier_item_sss_passive:GetModifierMPRegenAmplify_Percentage() return self:GetAbility():GetSpecialValueFor("bonus_mp_regen_amplify_percentage") end
function modifier_item_sss_passive:GetModifierPercentageCasttime()
    return self:GetAbility():GetSpecialValueFor("bonus_cast_speed")
end
