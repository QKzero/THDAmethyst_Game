item_naginata = {}

function item_naginata:GetIntrinsicModifierName()
    return "modifier_item_naginata_passive"
end

modifier_item_naginata_passive = {}
LinkLuaModifier("modifier_item_naginata_passive","items/item_naginata.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_item_naginata_passive:IsHidden() return true end
function modifier_item_naginata_passive:IsDebuff() return false end
function modifier_item_naginata_passive:IsPurgable() return false end
function modifier_item_naginata_passive:IsPurgeException() return false end
function modifier_item_naginata_passive:RemoveOnDeath() return false end

function modifier_item_naginata_passive:DeclareFunctions() return
    {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_item_naginata_passive:GetModifierBonusStats_Agility() return self:GetAbility():GetSpecialValueFor("bonus_agility") end
function modifier_item_naginata_passive:GetModifierAttackSpeedBonus_Constant() return self:GetAbility():GetSpecialValueFor("bonus_attack_speed") end
function modifier_item_naginata_passive:GetModifierMoveSpeedBonus_Percentage() return self:GetAbility():GetSpecialValueFor("bonus_move_speed_percentage") end