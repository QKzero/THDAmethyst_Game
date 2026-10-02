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

function modifier_item_esdw_passive:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE -- 允许多个相同修饰器共存
end

function modifier_item_esdw_passive:GetModifierHPRegenAmplify_Percentage() return self:GetAbility():GetSpecialValueFor("bonus_hp_regen_amplify_percentage") end
function modifier_item_esdw_passive:GetModifierSpellAmplify_Percentage() return self:GetAbility():GetSpecialValueFor("bonus_spell_amplify_percentage") end
function modifier_item_esdw_passive:GetModifierMPRegenAmplify_Percentage() return self:GetAbility():GetSpecialValueFor("bonus_mp_regen_amplify_percentage") end
function modifier_item_esdw_passive:OnCreated()
    if not IsServer() then return end
end

-- 主动技能释放逻辑（保持不变）
function item_esdw:OnSpellStart()
    local caster = self:GetCaster()
    local shield_value = self:GetSpecialValueFor("active_shield_value")
    local shield_duration = self:GetSpecialValueFor("active_shield_duration")
    
    -- 创建护盾效果
    caster:AddNewModifier(
        caster,
        self,
        "modifier_item_esdw_active_shield",
        {
            duration = shield_duration,
            shield_amount = shield_value
        }
    )
    
    -- 视觉特效：护盾粒子由 modifier_item_esdw_active_shield 托管，持续时间与 active_shield_duration（15 秒）一致
    EmitSoundOn("DOTA_Item.Pipe.Activate", caster)
end

-- 修复后的护盾效果修饰器
modifier_item_esdw_active_shield = {}
LinkLuaModifier("modifier_item_esdw_active_shield", "items/item_esdw.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_item_esdw_active_shield:IsHidden() return false end
function modifier_item_esdw_active_shield:IsDebuff() return false end
function modifier_item_esdw_active_shield:IsPurgable() return true end
function modifier_item_esdw_active_shield:RemoveOnDeath() return true end

function modifier_item_esdw_active_shield:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,  -- 关键：客户端护盾显示
        MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,      -- 关键：服务器端伤害吸收
        -- MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING -- 防止控制穿透
    }
end

function modifier_item_esdw_active_shield:OnCreated(params)
    if IsServer() then
        self.shield_remaining = params.shield_amount
        self:SetStackCount(self.shield_remaining)
        
        -- 创建护盾特效：灰烬之灵 TI9 火焰护盾（外环）
        -- 生命周期交给 modifier 托管，与主动持续时间 active_shield_duration（15 秒）一致，不会残留
        -- CP1 是「位置」不是半径（写成标量会把护盾推到地图原点而消失）。
        -- 该粒子内部自带 +100 的 Z 偏移，所以 CP1 要挂在单位原点（最低），护盾中心才落在躯干；
        -- 挂 attach_hitloc（胸口）会变成胸口再 +100，飘到头顶。
        self.particle = ParticleManager:CreateParticle(
            "particles/econ/items/ember_spirit/ember_ti9/ember_ti9_flameguard_shield_outer.vpcf",
            PATTACH_ABSORIGIN_FOLLOW,
            self:GetParent()
        )
        ParticleManager:SetParticleControlEnt(
            self.particle,
            1,
            self:GetParent(),
            PATTACH_ABSORIGIN_FOLLOW,
            "attach_hitloc",
            self:GetParent():GetAbsOrigin(),
            true
        )
        self:AddParticle(self.particle, false, false, -1, false, false)
    end
end

-- 关键：客户端护盾显示函数
function modifier_item_esdw_active_shield:GetModifierIncomingDamageConstant()
    if IsClient() then
        return self:GetStackCount() -- 客户端直接返回堆栈值用于UI显示
    end
    return 0
end

-- 关键：服务器端伤害吸收逻辑
function modifier_item_esdw_active_shield:GetModifierTotal_ConstantBlock(params)
    if not IsServer() then return 0 end
    
    -- 排除生命损失类伤害
    if bit.band(params.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
        return 0
    end
    
    local damage = params.damage
    local absorb_amount = math.min(self.shield_remaining, damage)
    
    -- 更新护盾值
    self.shield_remaining = self.shield_remaining - absorb_amount
    self:SetStackCount(self.shield_remaining)
    
    -- 伤害吸收特效
    if absorb_amount > 0 then
        ParticleManager:CreateParticle(
            "particles/items3_fx/lotus_orb_shield_hit.vpcf", -- 标准护盾击中特效
            PATTACH_ABSORIGIN,
            self:GetParent()
        )
        
        -- 显示吸收数值
        SendOverheadEventMessage(
            nil,
            OVERHEAD_ALERT_BLOCK,
            self:GetParent(),
            absorb_amount,
            nil
        )
    end
    
    -- 护盾耗尽时移除
    if self.shield_remaining <= 0 then
        self:Destroy()
    end
    
    return absorb_amount
end

-- function modifier_item_esdw_active_shield:GetModifierStatusResistanceStacking()
--     return 100 -- 100%状态抗性防止控制穿透
-- end

function modifier_item_esdw_active_shield:OnDestroy()
    if IsServer() then
        -- 播放护盾破碎特效
        ParticleManager:CreateParticle(
            "particles/items3_fx/lotus_orb_shell_shield_end.vpcf", -- 护盾结束特效（原 lotus_orb_destroy 在本体里不存在）
            PATTACH_ABSORIGIN,
            self:GetParent()
        )
        EmitSoundOn("DOTA_Item.LotusOrb.Target", self:GetParent())
    end
end