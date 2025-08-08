item_esdw = {}

function item_esdw:GetIntrinsicModifierName()
    return "modifier_item_esdw_passive"
end

modifier_item_esdw_passive = {}
LinkLuaModifier("modifier_item_esdw_passive","items/item_esdw.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_item_esdw_passive:IsHidden() return true end
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
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE,
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_item_esdw_passive:GetModifierBonusStats_Strength() return self:GetAbility():GetSpecialValueFor("bonus_strength") end
function modifier_item_esdw_passive:GetModifierBonusStats_Intellect() return self:GetAbility():GetSpecialValueFor("bonus_intellect") end
function modifier_item_esdw_passive:GetModifierAttackRangeBonus() 
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local bonus_range = ability:GetSpecialValueFor("bonus_attack_range")
    
    -- 近战单位：始终生效
    if not caster:IsRangedAttacker() then
        return bonus_range
    end
    
    -- 远程单位：检查道具互斥
    local hasModifier1 = caster:HasModifier("modifier_item_yuemianjidongzhuangzhi_range")
    local hasModifier2 = caster:HasModifier("modifier_item_yuemianzhinu_range")
    
    -- 无冲突道具时生效
    if not (hasModifier1 or hasModifier2) then
        return bonus_range
    end
    
    -- 默认不生效
    return 0
end
function modifier_item_esdw_passive:GetModifierHPRegenAmplify_Percentage() return self:GetAbility():GetSpecialValueFor("bonus_hp_regen_amplify_percentage") end
function modifier_item_esdw_passive:GetModifierSpellAmplify_Percentage() return self:GetAbility():GetSpecialValueFor("bonus_spell_amplify_percentage") end
function modifier_item_esdw_passive:GetModifierMPRegenAmplify_Percentage() return self:GetAbility():GetSpecialValueFor("bonus_mp_regen_amplify_percentage") end
function modifier_item_esdw_passive:OnCreated()
    if not IsServer() then return
end