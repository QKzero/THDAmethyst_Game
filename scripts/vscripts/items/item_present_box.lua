item_present_box = {}

function item_present_box:GetIntrinsicModifierName()
    return "modifier_item_present_box_passive"
end

function item_present_box:GetIntrinsicModifierName()
    return "modifier_item_present_box_give_gold"
end

-- 新增modifier类来处理间隔给金币
modifier_item_present_box_give_gold = class({})

LinkLuaModifier("modifier_item_present_box_give_gold", "items/item_present_box.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_item_present_box_give_gold:IsHidden() 
    return false  -- 或者true，根据是否需要显示在状态栏
end

function modifier_item_present_box_give_gold:IsPurgable() 
    return false
end

function modifier_item_present_box_give_gold:RemoveOnDeath() 
    return false
end

function modifier_item_present_box_give_gold:AllowIllusionDuplicate()
    return false
end

function modifier_item_present_box_give_gold:OnCreated()
    if not IsServer() then return end
    
    local ability = self:GetAbility()
    if not ability or ability:IsNull() then return end
    
    -- 从ability的特殊值中获取间隔时间
    local give_gold_interval = ability:GetSpecialValueFor("give_gold_interval")
    
    -- 启动间隔计时器
    self:StartIntervalThink(give_gold_interval)
end

function modifier_item_present_box_give_gold:OnIntervalThink()
    if not IsServer() then return end
    
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    
    if not caster or caster:IsNull() or not ability or ability:IsNull() then
        return
    end
    
    -- 从ability的特殊值中获取金币数量
    local give_gold_amount = ability:GetSpecialValueFor("give_gold_amount")
    local playerID = caster:GetPlayerOwnerID()
    
    if playerID and playerID >= 0 then
        local current_gold = PlayerResource:GetUnreliableGold(playerID)
        PlayerResource:SetGold(playerID, current_gold + give_gold_amount, false)
        
        -- 显示金币获取效果
        -- SendOverheadEventMessage(nil, OVERHEAD_ALERT_GOLD, caster, give_gold_amount, nil)
    end
end
-- 修饰器
modifier_item_present_box_passive = {}

LinkLuaModifier("modifier_item_present_box_passive", "items/item_present_box.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_item_present_box_passive:IsHidden() return true end
function modifier_item_present_box_passive:IsDebuff() return false end
function modifier_item_present_box_passive:IsPurgable() return false end
function modifier_item_present_box_passive:RemoveOnDeath() return false end

function modifier_item_present_box_passive:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_MANA_BONUS
    }
end

function modifier_item_present_box_passive:GetModifierHealthBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_present_box_passive:GetModifierManaBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_mana")
end

-- 灵魂碎片显示修饰器
modifier_soul_fragments_display = class({})

LinkLuaModifier("modifier_soul_fragments_display", "items/item_present_box.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_soul_fragments_display:IsHidden() return false end
function modifier_soul_fragments_display:IsPurgable() return false end
function modifier_soul_fragments_display:IsDebuff() return false end
function modifier_soul_fragments_display:RemoveOnDeath() return false end

function modifier_soul_fragments_display:GetTexture()
    return "item_present_box"  
end

-- 灵魂结晶显示修饰器
modifier_soul_crystals_display = class({})

LinkLuaModifier("modifier_soul_crystals_display", "items/item_present_box.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_soul_crystals_display:IsHidden() return false end
function modifier_soul_crystals_display:IsPurgable() return false end
function modifier_soul_crystals_display:IsDebuff() return false end
function modifier_soul_crystals_display:RemoveOnDeath() return false end

function modifier_soul_crystals_display:GetTexture()
    return "item_present_box"  
end
