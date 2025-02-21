ability_fast_respawn_buff = {}

function ability_fast_respawn_buff:GetIntrinsicModifierName()
    return "modifier_fast_respawn"
end

modifier_fast_respawn = {}
LinkLuaModifier("modifier_fast_respawn", "scripts/vscripts/abilities/specialmode_modifier.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_fast_respawn:IsHidden() return false end
function modifier_fast_respawn:IsPurgable() return false end
function modifier_fast_respawn:RemoveOnDeath() return false end
function modifier_fast_respawn:IsDebuff() return false end

function modifier_fast_respawn:DeclareFunctions()
    return{
        MODIFIER_PROPERTY_RESPAWNTIME_PERCENTAGE,
    }
end

function modifier_fast_respawn:GetModifierPercentageRespawnTime()
    if not IsServer() then return end
    --百分比复活时间， 正数减少，负数增加。0.5表示减少50%复活时间
    local value = THD2_GetFRSValue()
    return value / 100
end