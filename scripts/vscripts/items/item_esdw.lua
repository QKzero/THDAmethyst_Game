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
        MODIFIER_PROPERTY_CAST_RANGE_BONUS,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE,
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_item_esdw_passive:GetModifierBonusStats_Strength() return self:GetAbility():GetSpecialValueFor("bonus_strength") end
function modifier_item_esdw_passive:GetModifierBonusStats_Intellect() return self:GetAbility():GetSpecialValueFor("bonus_intellect") end
function modifier_item_esdw_passive:GetModifierAttackRangeBonus() return self:GetAbility():GetSpecialValueFor("bonus_attack_range") end
function modifier_item_esdw_passive:GetModifierHPRegenAmplify_Percentage() return self:GetAbility():GetSpecialValueFor("bonus_hp_regen_amplify_percentage") end
function modifier_item_esdw_passive:GetModifierCastRangeBonus() return self:GetAbility():GetSpecialValueFor("bonus_cast_range") end
function modifier_item_esdw_passive:GetModifierSpellAmplify_Percentage() return self:GetAbility():GetSpecialValueFor("bonus_spell_amplify_percentage") end
function modifier_item_esdw_passive:GetModifierMPRegenAmplify_Percentage() return self:GetAbility():GetSpecialValueFor("bonus_mp_regen_amplify_percentage") end

function modifier_item_esdw_passive:IsCooldownReady()
    return GameRules:GetGameTime() >= self.cooldown_end
end

function modifier_item_esdw_passive:OnCreated()
    if not IsServer() then return end
    self.damage_threshold = self:GetAbility():GetSpecialValueFor("damage_threshold_percentage")/100  -- 30% 最大生命值
    self.time_window = 1.0       -- 1 秒时间窗口
    self.damage_records = {}      -- 存储伤害记录 {时间, 伤害值}
    self.cooldown_end = 0
    self:StartIntervalThink(0.1) -- 每 0.1 秒清理过期伤害
end

-- 新增：覆盖冷却时间查询方法
function item_esdw:GetCooldown(level)
    return self.BaseClass.GetCooldown(self, level)
end

-- 新增：获取冷却剩余时间
function item_esdw:GetCooldownTimeRemaining()
    local modifier = self:GetCaster():FindModifierByName("modifier_item_esdw_passive")
    if modifier and not modifier:IsCooldownReady() then
        return modifier.cooldown_end - GameRules:GetGameTime()
    end
    return 0
end

function modifier_item_esdw_passive:OnIntervalThink()
    local now = GameRules:GetGameTime()
    -- 移除超过 1 秒的伤害记录
    for i = #self.damage_records, 1, -1 do
        if now - self.damage_records[i].time > self.time_window then
            table.remove(self.damage_records, i)
        end
    end
end

function modifier_item_esdw_passive:OnTakeDamage(keys)
    if not IsServer() then return end
    local unit = self:GetParent()
    
    -- 只处理本单位的伤害
    if unit ~= keys.unit then return end

    -- 忽略生命损失类伤害
    if bit.band(keys.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
        return
    end

    local now = GameRules:GetGameTime()
    if now < self.cooldown_end then
        return  -- 冷却中，不触发护盾
    end

    local now = GameRules:GetGameTime()
    local max_hp = unit:GetMaxHealth()
    local damage = keys.damage

    -- 记录伤害
    table.insert(self.damage_records, { time = now, damage = damage })

    -- 计算 1 秒内总伤害
    local total_damage = 0
    for _, record in ipairs(self.damage_records) do
        total_damage = total_damage + record.damage
    end

    -- 检查是否达到阈值 (30% 最大生命值)
    if total_damage >= max_hp * self.damage_threshold then
        -- 清空记录
        self.damage_records = {}

        -- 设置冷却时间 (30秒)
        self.cooldown_end = now + self:GetAbility():GetSpecialValueFor("cooldown")
        self:GetAbility():StartCooldown(30)
        
        -- 创建护盾（最大魔法值的 50%）
        local max_mana = unit:GetMaxMana()
        local shield_value = max_mana * self:GetAbility():GetSpecialValueFor("shield_mana_percentage")/100
        
        -- 添加护盾修饰器（持续 10 秒）
        unit:AddNewModifier(
            unit, 
            self:GetAbility(), 
            "modifier_item_esdw_shield", 
            { 
                duration = self:GetAbility():GetSpecialValueFor("shield_duration"),
                shield_value = shield_value
            }
        )
    end
end

-- 新增护盾修饰器
modifier_item_esdw_shield = {}
LinkLuaModifier("modifier_item_esdw_shield", "items/item_esdw.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_item_esdw_shield:IsHidden() return false end
function modifier_item_esdw_shield:IsDebuff() return false end
function modifier_item_esdw_shield:IsPurgable() return true end

function modifier_item_esdw_shield:OnCreated(params)
    if not IsServer() then return end
    self.shield_remaining = params.shield_value
    self:SetStackCount(self.shield_remaining)
    
    -- 添加护盾特效
    self.particle = ParticleManager:CreateParticle(
        "particles/econ/items/ember_spirit/ember_ti9/ember_ti9_flameguard_shield_outer.vpcf", 
        PATTACH_ABSORIGIN_FOLLOW, 
        self:GetParent()
    )
    ParticleManager:SetParticleControl(self.particle, 0, self:GetParent():GetAbsOrigin())
    self:AddParticle(self.particle, false, false, -1, false, false)
end

function modifier_item_esdw_shield:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT, -- 显示护盾值
        MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK      -- 吸收伤害
    }
end

-- 客户端显示护盾值
function modifier_item_esdw_shield:GetModifierIncomingDamageConstant()
    if IsClient() then return self:GetStackCount() end
end

-- 服务器端吸收伤害
function modifier_item_esdw_shield:GetModifierTotal_ConstantBlock(keys)
    if not IsServer() then return 0 end
    
    if bit.band(keys.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
        return 0
    end

    local damage = keys.damage
    local block_amount = math.min(damage, self.shield_remaining)
    
    -- 更新护盾剩余值
    self.shield_remaining = self.shield_remaining - block_amount
    self:SetStackCount(math.floor(self.shield_remaining))  -- 整数显示
    
    -- 护盾耗尽时才移除修饰器
    if self.shield_remaining <= 0 then
        self:Destroy()
    end
    
    return block_amount
end