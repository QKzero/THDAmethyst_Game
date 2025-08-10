item_cht = {}

function item_cht:GetIntrinsicModifierName()
    return "modifier_item_cht_passive"
end

modifier_item_cht_passive = {}
LinkLuaModifier("modifier_item_cht_passive","items/item_cht.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_item_cht_passive:IsHidden() return false end
function modifier_item_cht_passive:IsDebuff() return false end
function modifier_item_cht_passive:IsPurgable() return false end
function modifier_item_cht_passive:IsPurgeException() return false end
function modifier_item_cht_passive:RemoveOnDeath() return false end

function modifier_item_cht_passive:DeclareFunctions() return
    {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE
    }
end

function modifier_item_cht_passive:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE -- 允许多个相同修饰器共存
end

function modifier_item_cht_passive:GetModifierBonusStats_Intellect() return self:GetAbility():GetSpecialValueFor("bonus_intellect") end
function modifier_item_cht_passive:GetModifierSpellAmplify_Percentage() return self:GetAbility():GetSpecialValueFor("bonus_spell_amplify_percentage") end
function modifier_item_cht_passive:GetModifierMPRegenAmplify_Percentage() return self:GetAbility():GetSpecialValueFor("bonus_mana_regen_percentage") end
function modifier_item_cht_passive:OnCreated()
    if not IsServer() then return end
end