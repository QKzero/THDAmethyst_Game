--====================================================================================================================
-- 八咫镜（伪）（item_yata_mirror_fake）
-- 由清莲宝珠改名而来；原版 item_lotus_orb 仍在 npc_abilities_override.txt 中 REMOVE。
-- 通用指向技能反弹引擎：不做技能白名单，运行时按技能行为位判定。
-- 主动：回响护盾——反弹敌方以护盾者为目标的指向性技能与投射物（不限距离、护盾期内无上限次数）。
--
-- 反弹执行（敌方倒影架构）：
--   以 CreateIllusions 复制敌方施法者本体，造一个「敌方倒影」幻象（无敌 / 不可选中 / 零赏金，
--   由 MODIFIER_PROPERTY_SUPER_ILLUSION 驱动可施法、SUPER_ILLUSION_WITH_ULTIMATE 驱动可施放大招），
--   按原施法者的万宝槌 / 魔晶状态对幻象做状态镜像后，由幻象把技能原样施回敌方本体。反弹出的技能版本（强化分支、伤害属性）完全跟随原施法者，不受护盾者自身出装影响。
--====================================================================================================================


-- 音效事件名（想换音效改这三行即可，改完重启对局生效）
-- 2026-10-02 复原：这三个 Voice_Thdots_* 事件定义在 soundevents/thdots_hero_sounds/
-- thdots_daiyousei_sounds.vsndevts_c（addon 自带，且大妖精三技能本身就在用），音源指向sounds/items/lotus_*.vsnd_c，是可正常发声的组合。
local YATA_SOUND_CAST    = "Voice_Thdots_daiyousei.Abilitydaiyousei03_Target"   -- 施放护盾（音源 lotus_activate）
local YATA_SOUND_REFLECT = "Voice_Thdots_Daiyousei03.AbilityDaiyousei03_1"      -- 触发反弹（音源 lotus_cast）
local YATA_SOUND_END     = "Voice_Thdots_daiyousei.Abilitydaiyousei03_End"      -- 护盾结束（音源 lotus_end）

item_yata_mirror_fake = {}

--====================================================================================================================
-- 反弹黑名单（按技能内部名精确匹配）
-- 维护原则：默认全部反弹，仅登记确认反弹后会产生 bug 的技能；
-- 对应技能修复问题后可移出本表。
--====================================================================================================================
local REFLECT_BLACKLIST = {
    ["ability_thdots_satori01"] = true, -- 偷技能：偷取记录表挂在技能实例上，倒影/副本新实例为 nil，OnSpellStart 直接空指针报错；且对施法者技能栏做 Swap/Remove 手术
    ["ability_thdots_lily01"]   = true, -- 黑白形态标记复制不确定，反弹可能走白形态给敌方加治疗（资敌）；lily02/kasen2_3 目标类型为 CREEP 无法对英雄施法，已移出
    ["ability_thdots_medicine04"] = true, -- 梅蒂欣大招 谵妄「陷入疯狂」
    ["ability_thdots_Merlin04"]   = true, -- 梅露兰大招 管灵「激昂小号曲」
    ["ability_thdots_keine01"]    = true, -- 慧音 产灵「初始的历史鸿流」
    ["ability_thdots_shion_04"]   = true, -- 依神紫苑大招 凭依交换「绝对输家」
}

--====================================================================================================================
-- 自身施法反弹清单（按技能内部名精确匹配）—— 参与分流，命中即由护盾者亲自施法
-- 副作用：反弹数值按护盾者属性结算；且每个清单技能会在护盾者身上留一份隐藏技能副本。
-- 注意：不要把大技能无节制塞进这张表——副本数会占用单单位技能上限（32）。
-- 未入清单的技能一律走敌方倒影施法：倒影句柄现在存活 12 秒（仅前 1 秒在场，其余时间神隐），
-- 大多数持续类效果能在 12 秒句柄窗口内正常结算。
--====================================================================================================================
local SELF_CAST_REFLECT = {
    ["ability_thdots_yorihime_01"]          = true, -- 绵月依姬 神灵「召请火雷神」：冲锋 modifier 挂护盾者 60 秒（玩家可用指令取消）
    ["ability_thdots_Merlin01"]             = true, -- 梅露兰 冥管「灵之克里福德」：嘲讽目标=护盾者（真实可攻击单位，正常嘲讽语义）
    ["ability_thdots_komachi04"]            = true, -- 小町 薄命「余命无几许」：处刑演出锁镜头/传送作用于护盾者；斩杀判断 caster:IsAlive() 满足
    ["ability_thdots_shinki_ultimate"]      = true, -- 神绮 「魔影支配」：0.03s 延迟创建幻象并持续读技能实例字段 → 副本必须长期保留
    ["ability_thdots_parsee04"]             = true, -- 帕露西 恨符「丑时参拜第七日」：人偶 think 的 caster/target 均需存活
    ["ability_thdots_shikieiki04"]          = true, -- 四季映姬 审判「Last Judgement」：判罪 think 引用护盾者
    ["ability_thdots_reisen_2_01"]          = true, -- 铃仙(新) 「月兔一击」：mark 回调引用护盾者
    ["ability_thdots_kokoro04_WBC"]         = true, -- 秦心 万宝槌技能「假面丧心舞·暗黑能乐」（KV 预置 Ability7 槽）：万宝槌授予型，走自身施法最稳
    ["ability_thdots_mikoWanbao"]           = true, -- 神子 万宝槌技能（ATTRIBUTES 槽，SetHidden 切换激活）：倒影复制 hidden/槽位不可靠，入清单测试
    ["ability_thdots_youmu2_05"]            = true, -- 妖梦(改) 万宝槌技能（ATTRIBUTES 槽，同神子模式）：入清单测试
    ["ability_thdots_aya02"]                = true, -- 射命丸文 「文文新闻」：按需求登记（UNIT_TARGET，射程 700）
    ["ability_thdots_yuuka02"]              = true, -- 幽香 二技能：追踪花命中回调偶发引用失效（观察名单），自身施法规避
}


--====================================================================================================================
-- 主动：施放反弹护盾
--====================================================================================================================
function item_yata_mirror_fake:GetIntrinsicModifierName()
    return "modifier_item_yata_mirror_fake_passive"
end

-- 主动技能的目标限制：只能对「自身及友方英雄」施放，且对魔法免疫单位无效。
-- KV 侧的 FRIENDLY + HERO 已挡掉敌方和非英雄单位，这里再补三道防线：
--   1) 必须是英雄（挡掉被 FRIENDLY 放行的友方召唤物 / 特殊单位）
--   2) 必须是同队（挡掉共享控制等边界情况）
--   3) 排除幻象（幻象 IsHero() 也为 true，但不算「英雄本体」）
-- 返回值 UF_FAIL_MAGIC_IMMUNE_ENEMY 在本工程没有先例，取值失败时退回项目惯用的 UF_FAIL_CUSTOM。
function item_yata_mirror_fake:CastFilterResultTarget(target)
    if not IsServer() then return UF_SUCCESS end
    if target == nil or target:IsNull() then return UF_SUCCESS end

    local failCustom = UF_FAIL_CUSTOM
    if failCustom == nil then failCustom = 1 end

    -- 1) 只作用于英雄
    local okHero, isHero = pcall(function() return target:IsHero() end)
    if not okHero or isHero ~= true then
        return failCustom
    end
    -- 2) 只作用于己方（自身或友方）
    local caster = self:GetCaster()
    if caster ~= nil and not caster:IsNull() then
        local okTeam, sameTeam = pcall(function()
            return target:GetTeamNumber() == caster:GetTeamNumber()
        end)
        if okTeam and sameTeam ~= true then
            local failEnemy = UF_FAIL_ENEMY
            if failEnemy == nil then failEnemy = failCustom end
            return failEnemy
        end
    end
    -- 3) 排除幻象（只认英雄本体）
    local okIllu, isIllu = pcall(function() return target:IsIllusion() end)
    if okIllu and isIllu == true then
        return failCustom
    end
    -- 4) 魔法免疫单位无效
    local okImmune, immune = pcall(function() return target:IsMagicImmune() end)
    if okImmune and immune == true then
        local fail = UF_FAIL_MAGIC_IMMUNE_ENEMY
        if fail == nil then fail = failCustom end
        return fail
    end
    return UF_SUCCESS
end

function item_yata_mirror_fake:OnSpellStart()
    if not IsServer() then return end
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    if target == nil or target:IsNull() then return end
    -- 二次防御：与 CastFilterResultTarget 同一套规则（英雄 / 己方 / 非幻象 / 非魔免），
    -- 防止脚本施法等绕过引擎目标过滤的情况
    if self:CastFilterResultTarget(target) ~= UF_SUCCESS then return end

    -- 施放瞬间净化目标身上的负面效果（强驱散）
    target:Purge(false, true, false, true, true)

    -- 挂反弹护盾
    local duration = self:GetSpecialValueFor("shield_duration")
    target:AddNewModifier(caster, self, "modifier_item_yata_mirror_fake_active", { duration = duration })

    -- 音效：施放护盾（本体原版清莲宝珠事件 DOTA_Item.LotusOrb.Activate，无需额外资源文件）
    EmitSoundOn(YATA_SOUND_CAST, caster)
    -- 护盾持续特效由 modifier 的 OnCreated 创建（挂 attach_hitloc 躯干骨骼），生命周期由 OnDestroy 回收
end

--====================================================================================================================
-- 被动 modifier：物品属性
--====================================================================================================================
modifier_item_yata_mirror_fake_passive = {}
LinkLuaModifier("modifier_item_yata_mirror_fake_passive", "items/item_yata_mirror_fake.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_item_yata_mirror_fake_passive:IsHidden() return true end
function modifier_item_yata_mirror_fake_passive:IsDebuff() return false end
function modifier_item_yata_mirror_fake_passive:IsPurgable() return false end
function modifier_item_yata_mirror_fake_passive:RemoveOnDeath() return false end
function modifier_item_yata_mirror_fake_passive:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_yata_mirror_fake_passive:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_MANA_BONUS,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
    }
end

function modifier_item_yata_mirror_fake_passive:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_yata_mirror_fake_passive:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_yata_mirror_fake_passive:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_magic_resistance")
end

function modifier_item_yata_mirror_fake_passive:GetModifierManaBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_yata_mirror_fake_passive:GetModifierConstantHealthRegen()
    return self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end

function modifier_item_yata_mirror_fake_passive:GetModifierConstantManaRegen()
    return self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

--====================================================================================================================
-- 反弹护盾 modifier：护盾期内反弹指向技能与投射物
--====================================================================================================================
modifier_item_yata_mirror_fake_active = {}
LinkLuaModifier("modifier_item_yata_mirror_fake_active", "items/item_yata_mirror_fake.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_item_yata_mirror_fake_active:IsHidden() return false end
function modifier_item_yata_mirror_fake_active:IsDebuff() return false end
function modifier_item_yata_mirror_fake_active:IsPurgable() return true end
function modifier_item_yata_mirror_fake_active:RemoveOnDeath() return true end

function modifier_item_yata_mirror_fake_active:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ABILITY_EXECUTED,      -- 指向技能反弹
        MODIFIER_PROPERTY_PROJECTILE_REFLECTION, -- 投射物反弹（引擎级，自定义弹道同样生效）
    }
end

-- 护盾期间反弹投射物（引擎级）
function modifier_item_yata_mirror_fake_active:GetModifierProjectileReflection()
    return self:GetAbility():GetSpecialValueFor("reflect_projectile")
end

-- 护盾持续特效：手动创建并挂到 attach_hitloc 骨骼（人物躯干），跟随移动。
function modifier_item_yata_mirror_fake_active:OnCreated()
    if not IsServer() then return end
    local parent = self:GetParent()
    if parent == nil or parent:IsNull() then return end
    self.hShieldFx = ParticleManager:CreateParticle(
        "particles/items3_fx/lotus_orb_shield.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(self.hShieldFx, 0, parent,
        PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
    -- 生命周期交给 modifier 托管（item_esdw.lua 同款写法）：modifier 消失时引擎自动回收粒子
    self:AddParticle(self.hShieldFx, false, false, -1, false, false)
end

function modifier_item_yata_mirror_fake_active:OnDestroy()
    if not IsServer() then return end
    -- 护盾特效由 AddParticle 交给 modifier 托管，随 modifier 消亡自动回收，无需手动销毁
    -- 护盾结束音效（item_esdw.lua 同款）
    local parent = self:GetParent()
    if parent ~= nil and not parent:IsNull() then
        EmitSoundOn(YATA_SOUND_END, parent)
    end
end

-- 反弹入口：只有被指向技能作用在护盾者身上才反射
function modifier_item_yata_mirror_fake_active:OnAbilityExecuted(keys)
    if not IsServer() then return end
    local shield = self:GetParent()
    local attacker = keys.unit
    local ability = keys.ability
    local target = keys.target
    if target == nil and ability.GetCursorTarget ~= nil then
        target = ability:GetCursorTarget()
    end
    if attacker == nil or attacker:IsNull() then return end
    if ability == nil then return end

    -- 1 技能必须作用在护盾持有者身上（引擎事件 target 字段天然保证）
    if target ~= shield then return end
    -- 2 施法者不能是护盾持有者自己（自我施放类不反弹）
    if attacker == shield then return end
    -- 3 只反弹敌对施法（友军增益/治疗不反弹）
    -- 注：VScript 无 IsEnemy() 方法，改用项目已有先例 IsOpposingTeam(team)
    if not shield:IsOpposingTeam(attacker:GetTeam()) then return end
    -- 3.5 反射对魔法免疫单位无效（施法端）：魔法免疫单位施法的技能不会被反弹——
    --     与「无法对魔免单位施放护盾」保持同一互斥原则。
    --     典型场景：灵梦大招「八方鬼缚阵」作用的单位（阵内 modifier 含 MAGIC_IMMUNE）、
    --     BKB 类效果开启期间施法的单位。
    local okImm, attackerImmune = pcall(function() return attacker:IsMagicImmune() end)
    if okImm and attackerImmune == true then return end
    -- 4 只反弹真实英雄施法：CreateIllusions 只能复制英雄；
    --   同时天然防环——任何幻象（含本物品的倒影、敌方莲花的倒影）施法一律不反弹
    if not attacker:IsHero() or attacker:IsIllusion() then return end
    -- 5 施法者存活且可被指向
    if not attacker:IsAlive() then return end
    -- 6 防环（自身施法模式）：对方护盾者亲自施放反弹技能的瞬间带此标记，见标记即拒判，
    --   防止双方都用自身施法模式互弹同一技能形成乒乓
    if attacker:HasModifier("modifier_item_yata_mirror_fake_self_cast") then return end
    -- 7 黑名单：确认反弹后会产生 bug 的技能（原因见 REFLECT_BLACKLIST 注释）
    if REFLECT_BLACKLIST[ability:GetAbilityName()] then return end
    -- 8 运行时行为位判定（无白名单）：是否为可反射的指向性技能
    if not YataMirrorReflectableAbility(ability) then return end

    -- ============ 反弹触发：音效与特效 ============
    EmitSoundOn(YATA_SOUND_REFLECT, shield)
    local hReflectFx = ParticleManager:CreateParticle(
        "particles/items3_fx/lotus_orb_reflect.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, shield)
    ParticleManager:SetParticleControlEnt(hReflectFx, 0, shield,
        PATTACH_POINT_FOLLOW, "attach_hitloc", shield:GetAbsOrigin(), true)

    -- 分流（2026-09-26 回退为清单模式 + NOT_LEARNABLE 规则）：
    --   1) NOT_LEARNABLE 且 UNIT_TARGET 的技能（万宝槌/魔晶授予型，如 ability_thdots_tensiex）
    --      → 强制自身施法：幻象上这类技能等级复制/SetLevel 不可靠
    --   2) 清单内技能 → 自身施法（效果会持续引用施法者句柄，倒影消亡会报错）
    --   3) 其余技能 / 物品 → 敌方倒影施法（保留原施法者的数值与强化状态，不占护盾者技能槽）
    local abilityName = ability:GetAbilityName()
    if YataMirrorNeedsSelfCast(ability) or SELF_CAST_REFLECT[abilityName] then
        YataMirrorSelfCastReflect(shield, attacker, ability, self)
    else
        YataMirrorReflect(shield, attacker, ability, self)
    end
end

--====================================================================================================================
-- 反弹引擎：运行时按技能行为位判断是否为可指向技能（无白名单，新技能自动兼容）
--====================================================================================================================
-- 取技能行为位的数值形式。
function YataMirrorGetBehaviorInt(ability)
    if ability.GetBehaviorInt ~= nil then
        local ok, v = pcall(function() return ability:GetBehaviorInt() end)
        if ok and type(v) == "number" then return v end
    end
    local ok, v = pcall(function() return ability:GetBehavior() end)
    if ok and type(v) == "number" then return v end
    return nil
end

-- NOT_LEARNABLE 且 UNIT_TARGET 的技能（万宝槌/魔晶授予型，KV 预置槽位 + Lua SetLevel(1/0) 切换，
-- 引擎复制幻象时这类技能的等级可能不被继承（保持 0）、SetLevel 可能被忽略，且隐藏状态可能随复制带入导致引擎拒绝施法；
function YataMirrorNeedsSelfCast(ability)
    if ability == nil or ability:IsNull() then return false end
    local okItem, isItem = pcall(function() return ability:IsItem() end)
    if okItem and isItem == true then return false end -- 物品走倒影路径（FindItemCopyOnIllusion）

    -- 充能技能（引擎 AbilityCharges 机制，如稀神探女大招「逆转的命运之轮」
    -- ability_thdots_sagume_4，25 级天赋以 KV 嵌套增加充能数）→ 强制走自身施法。
    -- 原因：充能技能的施放条件是 GetCurrentAbilityCharges() > 0，与冷却无关，
    -- EndCooldown() 对充能无效；而 CreateIllusions 复制的副本充能数为 0，会被引擎拒施。
    -- 自身施法的 AddAbility 副本充能初始为满，可正常施放。
    -- 判定用 GetMaxAbilityCharges（VScript 该 API 的签名存在带参/无参两种说法，pcall 双试）。
    local okCharges, maxCharges = pcall(function()
        return ability:GetMaxAbilityCharges(ability:GetLevel())
    end)
    if not okCharges or type(maxCharges) ~= "number" then
        local okCharges2, v2 = pcall(function() return ability:GetMaxAbilityCharges() end)
        if okCharges2 and type(v2) == "number" then maxCharges = v2 end
    end
    if type(maxCharges) == "number" and maxCharges > 0 then
        return true
    end

    local behavior = YataMirrorGetBehaviorInt(ability)
    if behavior == nil then return false end
    local notLearnable = DOTA_ABILITY_BEHAVIOR_NOT_LEARNABLE
    if notLearnable == nil then return false end
    local okUT, isUnitTarget = pcall(function()
        return bit.band(behavior, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) == DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
    end)
    local okNL, isNotLearnable = pcall(function()
        return bit.band(behavior, notLearnable) == notLearnable
    end)
    return okUT and okNL and isUnitTarget == true and isNotLearnable == true
end

function YataMirrorReflectableAbility(ability)
    local behavior = YataMirrorGetBehaviorInt(ability)
    -- 拿不到数值行为位时不做拦截：判定链里 keys.target == 护盾持有者
    -- 已经保证这是「以护盾者为目标的技能」，宁可放过也不误伤
    if behavior == nil then return true end

    -- 必须是指向单位技能
    if bit.band(behavior, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) ~= DOTA_ABILITY_BEHAVIOR_UNIT_TARGET then
        return false
    end
    -- 排除非主动 / 自动 / 持续施法 / 纯点目标类
    local banned = {
        DOTA_ABILITY_BEHAVIOR_PASSIVE,
        DOTA_ABILITY_BEHAVIOR_AURA,
        DOTA_ABILITY_BEHAVIOR_TOGGLE,
        DOTA_ABILITY_BEHAVIOR_ATTACK,
        DOTA_ABILITY_BEHAVIOR_NO_TARGET,
        DOTA_ABILITY_BEHAVIOR_CHANNELLED,
        DOTA_ABILITY_BEHAVIOR_POINT,
    }
    for _, flag in ipairs(banned) do
        if bit.band(behavior, flag) == flag then
            return false
        end
    end
    return true
end

--====================================================================================================================
-- 反弹施法：清冷却 + 补法力，再用标准指令施放到目标
--====================================================================================================================
local function YataMirrorForceCast(unit, castAbility, target, playerId)
    if unit == nil or unit:IsNull() or castAbility == nil or castAbility:IsNull() then return end
    if target == nil or target:IsNull() then return end

    -- 反弹免费：不占用施法者的冷却
    pcall(function() castAbility:EndCooldown() end)

    -- 反弹免费：法力不足时补到刚好够施放一次（倒影法力通常为 0）
    local cost = 0
    pcall(function() cost = castAbility:GetManaCost(castAbility:GetLevel()) end)
    if type(cost) ~= "number" then cost = 0 end
    if cost > 0 and unit.GetMana ~= nil and unit:GetMana() < cost then
        -- 给到 max(cost, 上限)：SetMana 会被上限截断，确保至少拿到能施放的量
        local want = cost
        if unit.GetMaxMana ~= nil then
            want = math.max(cost, unit:GetMaxMana())
        end
        pcall(function() unit:SetMana(want) end)
    end

    -- 诊断日志：控制台搜 [YataMirror] 即可定位反弹失败到底卡在哪一步
    local range = -1
    pcall(function() range = castAbility:GetCastRange() end)
    print(string.format("[YataMirror] cast %s lv=%d cd=%.2f mana=%.0f/%.0f cost=%d dist=%.0f range=%s",
        tostring(castAbility:GetAbilityName()), castAbility:GetLevel(),
        castAbility:GetCooldownTimeRemaining(), unit:GetMana(), unit:GetMaxMana(), cost,
        (target:GetAbsOrigin() - unit:GetAbsOrigin()):Length2D(), tostring(range)))

    -- 主方案：SetCursorCastTarget + CastAbilityImmediately。
    unit:SetCursorCastTarget(target)
    local ok, err = pcall(function()
        unit:CastAbilityImmediately(castAbility, playerId)
    end)
    -- 注意：不能施放后立刻清空 cursor target。
    -- 物品 AbilityCastPoint 普遍是 0（所以之前测不出问题），但英雄技能有 0.1~0.3s 前摇，
    -- OnSpellStart 要到前摇结束才执行，那时仍要读 self:GetCursorTarget()；
    -- 立刻清空会让技能读不到目标。这里延迟到前摇之后再清。
    Timers:CreateTimer(1.0, function()
        if unit ~= nil and not unit:IsNull() then
            pcall(function() unit:SetCursorCastTarget(nil) end)
        end
    end)
    if not ok then
        print("[YataMirror] cast failed: " .. tostring(err))
        -- 兜底：极端情况下再试一次标准指令（真身施法路径可能用得上）
        pcall(function() unit:CastAbilityOnTarget(target, castAbility, playerId) end)
    end
end

--====================================================================================================================
-- 倒影退场：把倒影从场上「神隐」掉，但保留句柄。倒影的实体句柄继续存活到 duration 结束，被反弹技能挂载的 modifier/think 引用它不会失效；但视觉与场上占用在 hide_delay 后就消失。
-- 范式取自八云紫的隙间收纳 abilityyukari.lua: Yukari_StoreCreepInGap
--====================================================================================================================
local function YataMirrorBanishIllusion(illusion)
    if illusion == nil or illusion:IsNull() then return end
    pcall(function() illusion:Stop() end)
    pcall(function() illusion:AddNoDraw() end)
    pcall(function()
        illusion:AddNewModifier(illusion, nil, "modifier_out_of_world", {})
    end)
    pcall(function() illusion:SetAbsOrigin(Vector(-7907, 7624, 1024)) end)
end

--====================================================================================================================
-- 倒影销毁：优先用项目通用的 UTIL_Remove，取不到时退回 ForceKill
--====================================================================================================================
local function YataMirrorRemoveIllusion(illusion)
    if illusion == nil or illusion:IsNull() then return end
    pcall(function() illusion:Stop() end)
    local ok = pcall(function() UTIL_Remove(illusion) end)
    if not ok then
        pcall(function() illusion:ForceKill(false) end)
    end
end

--====================================================================================================================
-- 敌方倒影：复制敌方施法者本体，由倒影把技能施回敌方
--====================================================================================================================
-- 倒影保护修饰器：无敌 + 不可选中 + 免疫三系伤害 + 零赏金不可击杀 + 禁止攻击，
-- 由 SUPER_ILLUSION 特性驱动可施法、SUPER_ILLUSION_WITH_ULTIMATE 驱动可施放大招
-- （可施法幻象写法先例：abilitykasen2.lua modifier_kasenIllusion）
modifier_item_yata_mirror_fake_reflect_illusion = {}
LinkLuaModifier("modifier_item_yata_mirror_fake_reflect_illusion", "items/item_yata_mirror_fake.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_item_yata_mirror_fake_reflect_illusion:IsHidden() return true end
function modifier_item_yata_mirror_fake_reflect_illusion:IsDebuff() return false end
function modifier_item_yata_mirror_fake_reflect_illusion:IsPurgable() return false end
function modifier_item_yata_mirror_fake_reflect_illusion:RemoveOnDeath() return true end

-- 倒影外观：灰色高透明度（r/g/b 与 alpha 都在 KV 里可调）。
-- 主要靠 SetRenderAlpha 压到极低实现「几乎看不到」；alpha 调到 0 即完全不可见。
function modifier_item_yata_mirror_fake_reflect_illusion:OnCreated()
    if not IsServer() then return end
    local parent = self:GetParent()
    local ability = self:GetAbility()
    if ability ~= nil then
        if parent.SetRenderColor then
            parent:SetRenderColor(
                ability:GetSpecialValueFor("reflect_illusion_render_r"),
                ability:GetSpecialValueFor("reflect_illusion_render_g"),
                ability:GetSpecialValueFor("reflect_illusion_render_b"))
        end
        if parent.SetRenderAlpha then
            parent:SetRenderAlpha(ability:GetSpecialValueFor("reflect_illusion_render_alpha"))
        end
    end
    -- 倒影只负责施放被反弹的技能：禁止普攻、禁止自动索敌，避免施法后追着人打
    pcall(function() parent:SetAcquisitionRange(0) end)
    pcall(function() parent:SetIdleAcquire(false) end)
    pcall(function() parent:Stop() end)
end

function modifier_item_yata_mirror_fake_reflect_illusion:CheckState()
    return {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_LOW_ATTACK_PRIORITY] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
        [MODIFIER_STATE_DISARMED] = true,
        -- 注意：刻意不加 MODIFIER_STATE_COMMAND_RESTRICTED 与 MODIFIER_STATE_MUTED，
        -- 二者都会阻断脚本指令施法（kasen 幻象正是靠解除 MUTED 才能施法）
    }
end

function modifier_item_yata_mirror_fake_reflect_illusion:DeclareFunctions()
    return {
        -- 可施法幻象核心：一般可施法幻象无法施放终极技能，
        -- 施放大招需额外声明 SUPER_ILLUSION_WITH_ULTIMATE
        MODIFIER_PROPERTY_SUPER_ILLUSION,
        MODIFIER_PROPERTY_SUPER_ILLUSION_WITH_ULTIMATE,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    }
end

function modifier_item_yata_mirror_fake_reflect_illusion:GetModifierSuperIllusion()
    return true
end

function modifier_item_yata_mirror_fake_reflect_illusion:GetModifierSuperIllusionWithUltimate()
    return true
end

function modifier_item_yata_mirror_fake_reflect_illusion:GetAbsoluteNoDamagePhysical() return 1 end
function modifier_item_yata_mirror_fake_reflect_illusion:GetAbsoluteNoDamageMagical() return 1 end
function modifier_item_yata_mirror_fake_reflect_illusion:GetAbsoluteNoDamagePure() return 1 end

--====================================================================================================================
-- 万宝槌状态镜像标记：让倒影的 HasScepter() 与原施法者一致
--====================================================================================================================
modifier_item_yata_mirror_fake_scepter_mark = {}
LinkLuaModifier("modifier_item_yata_mirror_fake_scepter_mark", "items/item_yata_mirror_fake.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_item_yata_mirror_fake_scepter_mark:IsHidden() return true end
function modifier_item_yata_mirror_fake_scepter_mark:IsDebuff() return false end
function modifier_item_yata_mirror_fake_scepter_mark:IsPurgable() return false end
function modifier_item_yata_mirror_fake_scepter_mark:RemoveOnDeath() return false end

function modifier_item_yata_mirror_fake_scepter_mark:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_IS_SCEPTER,
    }
end

function modifier_item_yata_mirror_fake_scepter_mark:GetModifierIsScepter()
    return 1
end

--====================================================================================================================
-- 自身施法防环标记：护盾者亲自施放反弹技能的瞬间短暂携带，
-- 敌方护盾的判定链见此标记即拒判，防止双方互弹同一技能形成乒乓
--====================================================================================================================
modifier_item_yata_mirror_fake_self_cast = {}
LinkLuaModifier("modifier_item_yata_mirror_fake_self_cast", "items/item_yata_mirror_fake.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_item_yata_mirror_fake_self_cast:IsHidden() return true end
function modifier_item_yata_mirror_fake_self_cast:IsDebuff() return false end
function modifier_item_yata_mirror_fake_self_cast:IsPurgable() return false end
function modifier_item_yata_mirror_fake_self_cast:RemoveOnDeath() return false end

--====================================================================================================================
-- 自身施法反弹：护盾持有者亲自作为施法者，把技能施回敌方本体
-- 适用于「效果挂在敌方身上的 modifier/think 持续引用施法者句柄」的技能，护盾者持续存活，引用永远有效（倒影会消亡导致句柄失效报错）。
-- 副作用：反弹数值按护盾者属性结算（与倒影模式「按原施法者结算」不同）。
-- 返回 false 表示这条路走不通（物品技能 / 拿不到或加不上技能副本）。清单模式下调用方目前不使用该返回值；保留它是为了将来若要启用「自身施法失败自动回退倒影」时无需再改函数内部。
--====================================================================================================================
function YataMirrorSelfCastReflect(shield, attacker, originAbility, modifier)
    local ability = modifier:GetAbility()
    local delay = ability:GetSpecialValueFor("reflect_delay")
    local markerDuration = ability:GetSpecialValueFor("self_cast_marker_duration")
    local abilityName = originAbility:GetAbilityName()
    local originLevel = originAbility:GetLevel()
    local playerId = shield:GetPlayerOwnerID()

    -- 物品技能不走自身施法：AddAbility 对物品名不可靠，交给倒影路径
    -- （倒影会复制敌方物品栏，FindItemCopyOnIllusion 取同名物品副本）
    if originAbility:IsItem() then return false end

    -- 护盾者已拥有同名技能（如镜像对局）则复用，否则新建一份隐藏副本
    local reflectAbility = shield:FindAbilityByName(abilityName)
    local isTempCopy = reflectAbility == nil
    if isTempCopy then
        reflectAbility = shield:AddAbility(abilityName)
    end
    if reflectAbility == nil then
        -- 技能槽已满或该技能无法授予，交给倒影路径兜底
        print("[YataMirror] self-cast unavailable: " .. tostring(abilityName))
        return false
    end

    -- 临时副本保留不删除：部分技能延迟访问技能实例字段
    -- 立即删除会让这些句柄失效；隐藏图标避免污染护盾者技能栏。
    -- 复用护盾者已有技能时不动其显示，只做等级/冷却的保存与恢复。
    if isTempCopy and reflectAbility.SetHidden ~= nil then
        reflectAbility:SetHidden(true)
    end

    local savedLevel = reflectAbility:GetLevel()
    local savedCooldown = reflectAbility:GetCooldownTimeRemaining()
    if originLevel >= 1 then
        reflectAbility:SetLevel(originLevel)
    end

    Timers:CreateTimer(math.max(0, delay), function()
        if shield == nil or shield:IsNull() or not shield:IsAlive() then return end
        if attacker == nil or attacker:IsNull() or not attacker:IsAlive() then return end

        -- 防环标记：施放瞬间挂上，覆盖事件触发时刻即可（默认 1 秒余量）
        shield:AddNewModifier(shield, ability, "modifier_item_yata_mirror_fake_self_cast", { duration = markerDuration })

        YataMirrorForceCast(shield, reflectAbility, attacker, playerId)

        -- 复用护盾者自身技能时：反弹不得改动其等级、不得占用其冷却
        if not isTempCopy then
            if savedLevel >= 1 then
                reflectAbility:SetLevel(savedLevel)
            end
            reflectAbility:EndCooldown()
            if savedCooldown > 0 then
                reflectAbility:StartCooldown(savedCooldown)
            end
        end
    end)
    return true
end

--====================================================================================================================
-- 反射执行：造敌方倒影 → 状态镜像 → 倒影施法回敌方本体 → 施法后销毁倒影
--====================================================================================================================
-- 在倒影身上找同名物品副本（物品技能反弹用）。
-- 扫描 0-20：主物品栏 0-5、背包 6-8、中立槽 16（中立物品反弹的关键——
-- CreateIllusions 不复制中立槽，镜像补齐后才能在这里找到副本）
local function YataMirrorFindItemCopyOnIllusion(illusion, itemName)
    for slot = 0, 20 do
        local item = illusion:GetItemInSlot(slot)
        if item ~= nil and item:GetName() == itemName then
            return item
        end
    end
    return nil
end

-- 把施法者身上倒影没有的物品补复制给倒影（中立物品反弹的关键步骤）。
-- CreateIllusions 只复制主物品栏，中立槽（16）/背包等不会复制；
-- 范式取自 abilitylily.lua 的 LilySyncNeutralItem：CreateItem → AddItem → 校验落位。
-- 材质等无需处理；层数（消耗品）同步原物品。
local function YataMirrorCopyItemsToIllusion(attacker, illusion)
    if attacker == nil or attacker:IsNull() or illusion == nil or illusion:IsNull() then return end
    if not attacker:IsHero() or not illusion:IsHero() then return end
    for slot = 0, 20 do
        local item = attacker:GetItemInSlot(slot)
        if item ~= nil and not item:IsNull() then
            local name = item:GetName()
            local exists = false
            for s = 0, 20 do
                local it2 = illusion:GetItemInSlot(s)
                if it2 ~= nil and it2:GetName() == name then
                    exists = true
                    break
                end
            end
            if not exists then
                local okNew, newItem = pcall(function()
                    local ni = CreateItem(name, illusion, illusion)
                    ni:SetPurchaseTime(0)
                    return illusion:AddItem(ni)
                end)
                -- 没装上（物品栏满等）：移除刚创建的实体防泄漏
                if not okNew or newItem == nil then
                    pcall(function()
                        if newItem ~= nil and not newItem:IsNull() then
                            UTIL_Remove(newItem)
                        end
                    end)
                    print("[YataMirror] item mirror failed: " .. tostring(name))
                end
            end
        end
    end
end

function YataMirrorReflect(shield, attacker, originAbility, modifier)
    local ability = modifier:GetAbility()
    local delay = ability:GetSpecialValueFor("reflect_delay")
    local illusionDuration = ability:GetSpecialValueFor("reflect_illusion_duration")
    local illusionIncoming = ability:GetSpecialValueFor("reflect_illusion_incoming_damage")
    local illusionOutgoing = ability:GetSpecialValueFor("reflect_illusion_outgoing_damage")
    local postCastDelay = ability:GetSpecialValueFor("reflect_illusion_post_cast_delay")
    local abilityName = originAbility:GetAbilityName()
    local originLevel = originAbility:GetLevel()
    local isItem = originAbility:IsItem()
    local playerId = shield:GetPlayerOwnerID()

    -- 复制敌方本体造倒影：owner 传护盾持有者，倒影与护盾者同阵营；
    -- 生成在护盾持有者身旁（反弹视觉：技能从护盾处飞回施法者）
    local createOk, illusion = pcall(CreateIllusionTHD,
        { caster = shield },
        attacker,
        shield:GetAbsOrigin(),
        illusionIncoming,
        illusionOutgoing,
        illusionDuration,
        true
    )
    if not createOk or illusion == nil or illusion:IsNull() then
        print("[YataMirror] reflect failed: illusion creation error")
        return
    end

    -- 倒影保护 + 可施法特性 + 灰色半透明外观 + 禁止攻击
    illusion:AddNewModifier(shield, ability, "modifier_item_yata_mirror_fake_reflect_illusion", { duration = illusionDuration })

    -- 物品镜像：把施法者身上倒影没有的物品（含中立槽 16）补复制给倒影，
    -- 保证 FindItemCopyOnIllusion 能找到中立物品副本（CreateIllusions 只复制主物品栏）
    YataMirrorCopyItemsToIllusion(attacker, illusion)

    -- 状态镜像：让倒影的万宝槌 / 魔晶判定与原施法者一致（仅补缺，不重复挂）
    if attacker:HasScepter() and not illusion:HasScepter() then
        illusion:AddNewModifier(shield, ability, "modifier_item_yata_mirror_fake_scepter_mark", { duration = illusionDuration })
    end
    if attacker:HasModifier("modifier_item_aghanims_shard") and not illusion:HasModifier("modifier_item_aghanims_shard") then
        -- 官方魔晶标记为纯标记修饰器，直接按名挂载（先例：abilityreisen.lua 按名挂 modifier_axe_berserkers_call）
        local ok = pcall(function()
            illusion:AddNewModifier(shield, ability, "modifier_item_aghanims_shard", { duration = illusionDuration })
        end)
        if not ok then
            print("[YataMirror] shard state mirror failed")
        end
    end

    -- 延迟执行，避开与原始技能结算冲突
    Timers:CreateTimer(math.max(0, delay), function()
        if illusion == nil or illusion:IsNull() or not illusion:IsAlive() then return end
        if attacker == nil or attacker:IsNull() or not attacker:IsAlive() then return end

        -- 取倒影身上的技能副本
        local castAbility = nil
        if isItem then
            -- 物品技能：倒影复制了敌方物品栏，找同名物品副本
            castAbility = YataMirrorFindItemCopyOnIllusion(illusion, abilityName)
        else
            castAbility = illusion:FindAbilityByName(abilityName)
            -- 兜底：动态授予类技能（万宝槌/魔晶挂 Ability5/7 的）未被复制时现场补
            if castAbility == nil then
                castAbility = illusion:AddAbility(abilityName)
            end
            if castAbility ~= nil and originLevel >= 1 then
                castAbility:SetLevel(originLevel)
            end
        end
        if castAbility == nil then
            print("[YataMirror] reflect failed: ability copy not found: " .. tostring(abilityName))
            YataMirrorRemoveIllusion(illusion)
            return
        end

        YataMirrorForceCast(illusion, castAbility, attacker, playerId)

        -- 倒影退场分两步（句柄存活时长与在场时长解耦）：
        --   hide_delay 后「神隐」：AddNoDraw + modifier_out_of_world + 挪到地图外。
        --     此后倒影不再出现在场上，但实体句柄仍存活到 duration 结束，
        --     被反弹技能挂载的持续效果（think/周期伤害）继续引用它不会失效。
        --   post_cast_delay 后彻底移除（此时 duration 也接近自然到期，交给引擎消亡兜底）。
        --   ⚠ hide_delay 必须大于施法前摇（delay + cast point），否则传送会打断尚未完成的施法。
        local hideDelay = ability:GetSpecialValueFor("reflect_illusion_hide_delay")
        Timers:CreateTimer(math.max(0, hideDelay), function()
            if illusion == nil or illusion:IsNull() then return end
            if not illusion:IsAlive() then return end
            YataMirrorBanishIllusion(illusion)
        end)
        Timers:CreateTimer(math.max(0, postCastDelay), function()
            YataMirrorRemoveIllusion(illusion)
        end)
    end)
end
