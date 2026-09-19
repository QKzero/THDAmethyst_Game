--=================================================================================================================
-- 原版铃仙一技能（2026-09-15 重做）：幻弾「幻想视差」
--   弹道沿用新版 reisen01；后撤改为「因幡帝二技能」的做法：每 0.03 秒位移 120 单位，总距离 400。
--   命中敌方英雄时触发「丧心丧意」，不再触发新铃仙的幻兔「并行交差」。
--=================================================================================================================
function OnReisenOld01SpellStart(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local targetPoint = keys.ability:GetCursorPosition()
	keys.ability.reisenOld01_back_rad = GetRadBetweenTwoVec2D(caster:GetOrigin(), targetPoint)
	keys.ability.reisenOld01_back_traveled = nil
	keys.ability.reisenOld01_back_direction = nil
	-- 每次施法重置「大招首个命中英雄」标记
	keys.ability.reisen_old04_skill_triggered = nil
end

function OnReisenOld01Back(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local ability = keys.ability
	if ability.reisenOld01_back_rad == nil then
		return
	end
	if ability.reisenOld01_back_direction == nil then
		ability.reisenOld01_back_direction = Vector(-math.cos(ability.reisenOld01_back_rad),
			-math.sin(ability.reisenOld01_back_rad), 0)
	end
	if ability.reisenOld01_back_traveled == nil then
		ability.reisenOld01_back_traveled = 0
	end
	if ability.reisenOld01_back_traveled < keys.BackDistance then
		local step = ability.reisenOld01_back_direction * keys.BackSpeed
		caster:SetAbsOrigin(caster:GetAbsOrigin() + step)
		ability.reisenOld01_back_traveled = ability.reisenOld01_back_traveled + step:Length2D()
		if GridNav ~= nil and keys.TreeDestroyRadius ~= nil then
			GridNav:DestroyTreesAroundPoint(caster:GetAbsOrigin(), keys.TreeDestroyRadius, false)
		end
	else
		caster:InterruptMotionControllers(true)
	end
end

function OnReisenOld01BackEnd(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local ability = keys.ability
	ability.reisenOld01_back_traveled = nil
	ability.reisenOld01_back_direction = nil
	FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
end

function OnReisenOld01SpellHit(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local target = keys.target
	local ability = keys.ability
	local damage_table = {
		ability = ability,
		victim = target,
		attacker = caster,
		damage = ability:GetAbilityDamage(),
		damage_type = ability:GetAbilityDamageType(),
		damage_flags = 0
	}
	UnitDamageTarget(damage_table)

	-- 触发大招被动2：本次施法只对首个命中的敌方英雄生效
	ReisenOld04SpawnReflectionFromSkill(caster, ability, target)

	-- 触发原版被动「丧心丧意」：命中任意敌人即触发（不再限定英雄）
	if target ~= nil and not target:IsNull() then
		local exAbility = caster:FindAbilityByName("ability_thdots_reisenOldex")
		if exAbility ~= nil then
			ReisenOldExApply(caster, target, exAbility:GetSpecialValueFor("move_slow_duration"))
		end
	end

	SetTargetToTraversable(caster)
end

-- 「丧心丧意」的实际结算：0.5 倍主属性伤害 + 减速/降低命中
-- 抽出来供「普攻被动」与「一技能弹道命中」两条路径共用
function ReisenOldExApply(caster, target, duration)
	local exAbility = caster:FindAbilityByName("ability_thdots_reisenOldex")
	if exAbility == nil then
		return
	end
	local agi_multiplier = exAbility:GetSpecialValueFor("agi_damage_multiplier") or 0.5
	local deal_damage = caster:GetPrimaryStatValue() * agi_multiplier
	if target:IsBuilding() then
		deal_damage = deal_damage * 0.3
	end
	local damage_table = {
		ability = exAbility,
		victim = target,
		attacker = caster,
		damage = deal_damage,
		damage_type = exAbility:GetAbilityDamageType(),
		damage_flags = exAbility:GetAbilityTargetFlags()
	}
	exAbility:ApplyDataDrivenModifier(caster, target, "modifier_reisenexold_slow", {
		duration = duration
	})
	StartSoundEvent("Voice_Thdots_Reisen.AbilityReisen01", caster)
	UnitDamageTarget(damage_table)
end

function OnReisenOldExSpellSuccess(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local target = keys.target
	local RandomNumber = RandomInt(1, 100)
	-- 基础概率来自 KV（ability_chance_base），20 级天赋再加 20%
	-- 注：KV 的 LinkedSpecialBonus 只影响面板显示，所以这里必须手动追加
	local deal_chance = keys.Chance + FindTelentValue(caster, "special_bonus_unique_reisen_5")
	if RandomNumber <= deal_chance then
		ReisenOldExApply(caster, target, keys.Duration)
	elseif target:HasModifier("modifier_thdots_reisen03_full") then
		ReisenOldExApply(caster, target, keys.Duration)
	end
end

-- 2026-09-15 重做：不再由普攻被动产生分身，只保留主动效果。
-- 主动制造 1 个分身，继承攻击力 25/30/35/40%，持续 24/30/36/42 秒。
function OnReisenOld02SpellStart(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)

	-- 15 级天赋的 +10% 已由 KV 的 LinkedSpecialBonus 直接加进 %illusion_damage_out_pct，
	-- 这里不再二次计算，避免与 KV 重复加成
	local illusions = CreateIllusions(caster, caster, {
		outgoing_damage = keys.Illusion_damage_out_pct,
		incoming_damage = keys.Illusion_damage_in_pct,
		bounty_base = keys.Illusion_bounty_base,
		bounty_growth = keys.Illusion_bounty_growth,
		outgoing_damage_structure = nil,
		outgoing_damage_roshan = nil,
		duration = keys.Illusion_duration
	}, 1, caster:GetHullRadius(), true, true)

	for i, illusion in pairs(illusions) do
		if (illusion ~= nil) then
			local effectIndex = ParticleManager:CreateParticle(
				"particles/units/heroes/hero_phantom_lancer/phantom_lancer_spawn_smoke.vpcf", PATTACH_CUSTOMORIGIN,
				caster)
			ParticleManager:SetParticleControl(effectIndex, 0, illusion:GetOrigin())
			ParticleManager:SetParticleControl(effectIndex, 1, illusion:GetOrigin())
			ParticleManager:DestroyParticleSystem(effectIndex, false)
		end
	end
end

-- 2026-09-15：二技能不再被动产生分身，OnReisenOld02SpellSuccess / OnReisenOld02OnDeath 已随之移除。

function OnReisen03ChannellStart(keys)
    local caster = keys.caster
    local reduce_time = keys.ability:GetSpecialValueFor("reduce_time")
    caster.ability_reisen_03_time_count = 0.05
    caster.ability_reisen_03_damage_count = 0.05

end
function OnReisen03Channelling(keys)
    local caster = keys.caster
    caster.ability_reisen_03_time_count = caster.ability_reisen_03_time_count + 0.05
end

function OnReisen03Shoot(keys)
	local caster = keys.caster
	caster.ability_reisen_03_damage_count = caster.ability_reisen_03_time_count
	-- 每次射击重置「大招首个命中英雄」标记
	if keys.ability ~= nil then
		keys.ability.reisen_old04_skill_triggered = nil
	end
end

function OnReisenOld03SpellHit(keys)
    local caster = keys.caster
    local damage_rate = math.floor(10 * caster.ability_reisen_03_damage_count / 1.0) / 10
    local damagetype = keys.ability:GetAbilityDamageType()
    local damage_bonus = keys.ability:GetSpecialValueFor("damage_bonus") / 100
    --[[if caster:HasModifier("modifier_item_wanbaochui") then
		damage_rate=1
	end]] --
    local deal_damage = keys.ability:GetSpecialValueFor("total_damage") * damage_rate

    local amplifier = FindTelentValue(caster, "special_bonus_unique_reisen_1")
    if amplifier ~= 0 then
        deal_damage = deal_damage * amplifier
    end

    if damage_rate == 1 then
        if caster:HasModifier("modifier_item_wanbaochui") then
            deal_damage = deal_damage * (1 + damage_bonus)
        end
        print("damage_rate = " .. damage_rate)
        keys.ability:ApplyDataDrivenModifier(caster, keys.target, "modifier_thdots_reisen03_full", {})
    end
    if caster:HasModifier("modifier_item_wanbaochui") then
        local damage_table = {
            ability = keys.ability,
            victim = keys.target,
            attacker = caster,
            damage = deal_damage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            damage_flags = keys.ability:GetAbilityTargetFlags()
        }
        keys.ability:ApplyDataDrivenModifier(caster, keys.target, "modifier_reisen03_knockback", {})
        UnitDamageTarget(damage_table)
    else
        local damage_table = {
            ability = keys.ability,
            victim = keys.target,
            attacker = caster,
            damage = deal_damage,
            damage_type = keys.ability:GetAbilityDamageType(),
            damage_flags = keys.ability:GetAbilityTargetFlags()
        }
        UnitDamageTarget(damage_table)
    end

	-- 大招被动2：本次施法只对首个命中的敌方英雄生效
	ReisenOld04SpawnReflectionFromSkill(caster, keys.ability, keys.target)

	if caster:GetClassname() == "npc_dota_hero_mirana" then
		local ex_damage = caster:GetPrimaryStatValue() * 0.5
        local damage_table_ex = {
            ability = keys.ability,
            victim = keys.target,
            attacker = caster,
            damage = ex_damage,
            damage_type = keys.ability:GetAbilityDamageType(),
            damage_flags = keys.ability:GetAbilityTargetFlags()
        }
        caster:FindAbilityByName("ability_thdots_reisenOldex"):ApplyDataDrivenModifier(caster, keys.target,
            "modifier_reisenexold_slow", {
                duration = keys.duration
            })
        StartSoundEvent("Voice_Thdots_Reisen.AbilityReisen01", caster)
        UnitDamageTarget(damage_table_ex)
    end
end

--=================================================================================================================
-- 原版铃仙大招（2026-09-15 重做）：倒影幻象
--   被动1：增加攻击距离 100 / 200 / 300（KV 里挂 MODIFIER_PROPERTY_ATTACK_RANGE_BONUS）
--   被动2：技能一 / 技能三 命中敌方英雄、或普攻按概率命中时，制造该英雄的倒影幻象
--=================================================================================================================

-- 幻象索引：caster.reisen_old04_illusions[目标 entindex] = { 幻象, ... }
function ReisenOld04GetIllusionList(caster, target)
	if caster.reisen_old04_illusions == nil then
		caster.reisen_old04_illusions = {}
	end
	local key = target:GetEntityIndex()
	if caster.reisen_old04_illusions[key] == nil then
		caster.reisen_old04_illusions[key] = {}
	end
	return caster.reisen_old04_illusions[key]
end

-- 让幻象锁定并持续攻击其对应的敌方英雄
function ReisenOld04OrderAttack(illusion, target)
	if illusion == nil or illusion:IsNull() or target == nil or target:IsNull() then
		return
	end
	illusion:SetForceAttackTarget(target)
	local newOrder = {
		UnitIndex = illusion:entindex(),
		OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
		TargetIndex = target:entindex(),
		AbilityIndex = 0,
		Position = nil,
		Queue = 0
	}
	ExecuteOrderFromTable(newOrder)
end

function ReisenOld04PlayEffect(unit)
	local effectIndex = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_phantom_lancer/phantom_lancer_spawn_smoke.vpcf", PATTACH_CUSTOMORIGIN, unit)
	ParticleManager:SetParticleControl(effectIndex, 0, unit:GetOrigin())
	ParticleManager:SetParticleControl(effectIndex, 1, unit:GetOrigin())
	ParticleManager:DestroyParticleSystem(effectIndex, false)
end

-- 制造一个倒影幻象。asOwn = true 时复制铃仙自己（魔晶效果）
-- 所有数值都从 KV 的 AbilityValues 读取，不在 Lua 里硬编码
function ReisenOld04CreateOne(caster, ult, target, asOwn)
	local duration = ult:GetSpecialValueFor("illusion_duration")
	local lifeTime = duration + ult:GetSpecialValueFor("illusion_duration_buffer")
	local source = target
	if asOwn then
		source = caster
	end
	local created = CreateIllusions(caster, source, {
		outgoing_damage = ult:GetSpecialValueFor("illusion_damage_out_pct"),
		incoming_damage = ult:GetSpecialValueFor("illusion_damage_in_pct"),
		bounty_base = ult:GetSpecialValueFor("illusion_bounty_base"),
		bounty_growth = ult:GetSpecialValueFor("illusion_bounty_growth"),
		outgoing_damage_structure = nil,
		outgoing_damage_roshan = nil,
		duration = lifeTime
	}, 1, source:GetHullRadius(), true, true)
	local illusion = created[1]
	if illusion == nil then
		return nil
	end
	-- 把锁定的目标传给倒影，供其周期性地重新下达攻击指令
	illusion:AddNewModifier(caster, ult, "modifier_thdots_reisenOld04_illusion",
		{target_index = target:GetEntityIndex()})
	-- 魔晶窗口内制造的是铃仙自己的幻象，而 CreateIllusions 会把它放在「被复制单位」身边，
	-- 也就是铃仙自己身边；这里手动挪到真正被触发的那名敌方英雄旁边
	if asOwn then
		FindClearSpaceForUnit(illusion, target:GetOrigin(), true)
	end
	-- 单色 + 半透明外观；方法不存在时自动跳过，避免旧版 API 报错
	if illusion.SetRenderColor then
		illusion:SetRenderColor(ult:GetSpecialValueFor("illusion_render_color_r"),
			ult:GetSpecialValueFor("illusion_render_color_g"),
			ult:GetSpecialValueFor("illusion_render_color_b"))
	end
	if illusion.SetRenderAlpha then
		illusion:SetRenderAlpha(ult:GetSpecialValueFor("illusion_render_alpha"))
	end
	-- 嘲讽：让倒影被目标英雄「嘲讽」，从而强制攻击并持续跟随该英雄。
	-- 沿用工程内既有做法（见 abilitymedicine.lua 的嘲讽）——使用原版
	-- modifier_axe_berserkers_call，caster 传发起嘲讽的英雄、parent 传倒影，
	-- 引擎会自动把倒影的强制目标锁定到该英雄，比单纯 SetForceAttackTarget 多了「跟随」
	if target ~= nil and not target:IsNull() and target:IsAlive() then
		illusion:AddNewModifier(target, ult, "modifier_axe_berserkers_call", {duration = lifeTime})
	end
	ReisenOld04OrderAttack(illusion, target)
	ReisenOld04PlayEffect(illusion)
	local mod = illusion:FindModifierByName("modifier_illusion")
	if mod ~= nil then
		mod:SetDuration(lifeTime, true)
	end
	return illusion
end

-- 魔晶窗口判定：modifier 与时间戳双保险，确保窗口内新触发的幻象一定是铃仙幻象
function ReisenOld04InShardWindow(caster)
	if caster:HasModifier("modifier_thdots_reisenOld04_shard_window") then
		return true
	end
	if caster.reisen_old04_window_end ~= nil then
		return GameRules:GetGameTime() < caster.reisen_old04_window_end
	end
	return false
end

-- 被动2 的统一入口
function ReisenOld04SpawnReflection(caster, target)
	if caster == nil or caster:IsNull() then
		return
	end
	local ult = caster:FindAbilityByName("ability_thdots_reisenOld04")
	if ult == nil or ult:GetLevel() <= 0 then
		return
	end
	if target == nil or target:IsNull() or not target:IsAlive() then
		return
	end
	if not target:IsHero() then
		return
	end

	local duration = ult:GetSpecialValueFor("illusion_duration")
	local lifeTime = duration + ult:GetSpecialValueFor("illusion_duration_buffer")
	-- 25 级天赋：+1 大招幻象上限
	local cap = ult:GetSpecialValueFor("max_illusions") +
					FindTelentValue(caster, "special_bonus_unique_reisen_2")
	local asOwn = ReisenOld04InShardWindow(caster)

	local list = ReisenOld04GetIllusionList(caster, target)
	for i = #list, 1, -1 do
		if list[i] == nil or list[i]:IsNull() or not list[i]:IsAlive() then
			table.remove(list, i)
		end
	end

	if #list < cap then
		local illusion = ReisenOld04CreateOne(caster, ult, target, asOwn)
		if illusion ~= nil then
			table.insert(list, illusion)
		end
	end

	-- 重复触发时刷新已有幻象的存活时间，并确保仍锁定原目标
	for _, illusion in pairs(list) do
		local mod = illusion:FindModifierByName("modifier_illusion")
		if mod ~= nil then
			mod:SetDuration(lifeTime, true)
		end
		ReisenOld04OrderAttack(illusion, target)
	end

	-- 刷新目标身上的标记：被驱散或目标死亡时幻象一并消失
	target:AddNewModifier(caster, ult, "modifier_thdots_reisenOld04_mark", {duration = duration})
end

-- 技能触发入口：一次施法只会对「首个命中的敌方英雄」生效（小兵/野怪不占用这次触发）
function ReisenOld04SpawnReflectionFromSkill(caster, ability, target)
	if ability == nil or ability:IsNull() then
		return
	end
	if ability.reisen_old04_skill_triggered then
		return
	end
	if target == nil or target:IsNull() or not target:IsHero() then
		return
	end
	ability.reisen_old04_skill_triggered = true
	ReisenOld04SpawnReflection(caster, target)
end

--=================================================================================================================
-- ability_lua：没有魔晶时保持 KV 里的 PASSIVE（纯被动），持有魔晶后切换为主动。
-- 范式与 ability_thdots_lyrica03:GetBehavior() 一致（莉莉卡三技能获得万宝槌后变主动）。
--=================================================================================================================
ability_thdots_reisenOld04 = class({})

function ability_thdots_reisenOld04:GetIntrinsicModifierName()
	return "modifier_thdots_reisenOld04_passive"
end

-- 持有魔晶判定。注意：KV 的 LinkedSpecialBonus 只影响 tooltip 显示、不影响 GetSpecialValueFor，
-- 所以魔晶状态必须直接查 modifier。这里用的是本工程通行写法
-- HasModifier("modifier_item_aghanims_shard")（meirin / minoriko / shion / shizuha 等都在用）。
function ability_thdots_reisenOld04:IsShardActive()
	local caster = self:GetCaster()
	if caster == nil or caster:IsNull() then
		return false
	end
	return caster:HasModifier("modifier_item_aghanims_shard")
end

-- 与 ability_thdots_Merlin03:GetBehavior() 一致：
-- KV 里默认声明为 DOTA_ABILITY_BEHAVIOR_PASSIVE，持有魔晶时切换为可主动施放
function ability_thdots_reisenOld04:GetBehavior()
	if self:IsShardActive() then
		return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE
	end
	return self.BaseClass.GetBehavior(self)
end

function ability_thdots_reisenOld04:OnSpellStart()
	if not IsServer() then
		return
	end
	if not self:IsShardActive() then
		self:EndCooldown()
		return
	end
	-- 复用已有的魔晶转换逻辑
	OnReisenOld04ShardSpellStart({caster_entindex = self:GetCaster():entindex(), ability = self})
end

--=================================================================================================================
-- 被动1：增加攻击距离；同时承载被动2 的普攻触发（分身不继承）
--=================================================================================================================
modifier_thdots_reisenOld04_passive = class({})
LinkLuaModifier("modifier_thdots_reisenOld04_passive", "scripts/vscripts/abilities/abilityreisen.lua",
	LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_reisenOld04_passive:IsHidden() return true end
function modifier_thdots_reisenOld04_passive:IsPurgable() return false end
function modifier_thdots_reisenOld04_passive:RemoveOnDeath() return false end
-- 分身不继承被动2
function modifier_thdots_reisenOld04_passive:AllowIllusionDuplicate() return false end

function modifier_thdots_reisenOld04_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_thdots_reisenOld04_passive:GetModifierAttackRangeBonus()
	return self:GetAbility():GetSpecialValueFor("attack_range_bonus")
end

function modifier_thdots_reisenOld04_passive:OnAttackLanded(keys)
	if not IsServer() then
		return
	end
	local caster = self:GetParent()
	if keys.attacker ~= caster then
		return
	end
	if caster:IsIllusion() then
		return
	end
	local target = keys.target
	if target == nil or target:IsNull() or not target:IsHero() then
		return
	end
	local ult = self:GetAbility()
	if ult == nil or ult:GetLevel() <= 0 then
		return
	end

	-- 对同一敌方英雄的内置冷却
	if caster.reisen_old04_attack_cd == nil then
		caster.reisen_old04_attack_cd = {}
	end
	local key = target:GetEntityIndex()
	local now = GameRules:GetGameTime()
	if caster.reisen_old04_attack_cd[key] ~= nil and now < caster.reisen_old04_attack_cd[key] then
		return
	end

	if RandomInt(1, 100) > ult:GetSpecialValueFor("attack_chance") then
		return
	end

	caster.reisen_old04_attack_cd[key] = now + ult:GetSpecialValueFor("attack_trigger_cooldown")
	ReisenOld04SpawnReflection(caster, target)
end

--=================================================================================================================
-- 标记：挂在敌方英雄身上，被驱散或目标死亡时（OnDestroy）对应幻象一并消失
--=================================================================================================================
modifier_thdots_reisenOld04_mark = class({})
LinkLuaModifier("modifier_thdots_reisenOld04_mark", "scripts/vscripts/abilities/abilityreisen.lua",
	LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_reisenOld04_mark:IsDebuff() return true end
function modifier_thdots_reisenOld04_mark:IsPurgable() return true end
function modifier_thdots_reisenOld04_mark:IsHidden() return false end

function modifier_thdots_reisenOld04_mark:OnDestroy()
	if not IsServer() then
		return
	end
	local caster = self:GetCaster()
	local target = self:GetParent()
	if caster == nil or caster:IsNull() then
		return
	end
	if target == nil or target:IsNull() then
		return
	end
	if caster.reisen_old04_illusions == nil then
		return
	end
	local key = target:GetEntityIndex()
	local list = caster.reisen_old04_illusions[key]
	if list == nil then
		return
	end
	for _, illusion in pairs(list) do
		if illusion ~= nil and not illusion:IsNull() and illusion:IsAlive() then
			illusion:SetForceAttackTarget(nil)
			illusion:ForceKill(true)
		end
	end
	caster.reisen_old04_illusions[key] = nil
end

--=================================================================================================================
-- 倒影幻象：无敌 + 不可选中 + 隐藏 + 相位 + 低攻击优先级，并完全免疫三系伤害
-- 免疫部分与东风谷早苗大招 modifier_thdots_sanae04_target 一致
--=================================================================================================================
modifier_thdots_reisenOld04_illusion = class({})
LinkLuaModifier("modifier_thdots_reisenOld04_illusion", "scripts/vscripts/abilities/abilityreisen.lua",
	LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_reisenOld04_illusion:IsHidden() return true end
function modifier_thdots_reisenOld04_illusion:IsPurgable() return false end

-- 自动攻击：参考古明地恋大招
-- （modifier_koishi04_bonus 的 ThinkInterval 0.1 + OnKoishi04Think 里的 MoveToTargetToAttack），
-- 周期性地重新下达攻击指令，避免倒影因指令过期或被其他单位吸引而停手
function modifier_thdots_reisenOld04_illusion:OnCreated(params)
	if not IsServer() then
		return
	end
	self.target_index = params.target_index
	local repeat_interval = self:GetAbility():GetSpecialValueFor("illusion_attack_repeat_interval")
	if repeat_interval ~= nil and repeat_interval > 0 then
		self:StartIntervalThink(repeat_interval)
	end
end

function modifier_thdots_reisenOld04_illusion:OnIntervalThink()
	local illusion = self:GetParent()
	if illusion == nil or illusion:IsNull() or not illusion:IsAlive() then
		self:StartIntervalThink(-1)
		return
	end
	local target = EntIndexToHScript(self.target_index)
	if target == nil or target:IsNull() or not target:IsAlive() then
		return
	end
	if target:IsAttackImmune() then
		return
	end
	-- 注意：这里刻意不照搬恋的 IsInvisible() 过滤。
	-- IsInvisible() 判断的是「身上带隐身状态」，与「我方能不能看见」是两回事：
	-- 被真眼、撒粉等暴露视野的隐身敌人 IsInvisible() 依然为 true，
	-- 若直接按它过滤，倒影就会放过已经暴露的敌人。
	-- 只在确认我方确实看不到时才跳过；取不到视野 API 时按「可见」处理
	if target:IsInvisible() then
		local canSee = true
		if target.IsVisibleToTeam ~= nil then
			local ok, visible = pcall(function() return target:IsVisibleToTeam(illusion:GetTeamNumber()) end)
			if ok then
				canSee = visible == true
			end
		end
		if not canSee then
			return
		end
	end
	illusion:MoveToTargetToAttack(target)
end
-- 倒影的单位依附光效。这是让倒影「看起来是红色」最可靠的一层：
-- 幻象的蓝色是引擎 illusion 系统自带的着色，单纯 SetRenderColor 未必能盖过去，
-- 因此叠一层红色粒子保证观感。想换色调改这个路径即可，例如：
--   浅红 particles/thd2/heroes/kaguya/ability_kaguya01_light_red.vpcf
--   血色 particles/units/heroes/hero_bloodseeker/bloodseeker_bloodrage.vpcf
function modifier_thdots_reisenOld04_illusion:GetEffectName()
	return "particles/units/heroes/hero_bloodseeker/bloodseeker_bloodrage.vpcf"
end
function modifier_thdots_reisenOld04_illusion:GetEffectAttachType() return PATTACH_POINT_FOLLOW end

function modifier_thdots_reisenOld04_illusion:CheckState()
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
		-- 不可控：无法被玩家下达指令
		-- 与姬海棠果天赋幻象 modifier_ability_thdots_hatate01_illusion 用的同一个状态
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
	}
end

function modifier_thdots_reisenOld04_illusion:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
	}
end
function modifier_thdots_reisenOld04_illusion:GetAbsoluteNoDamagePhysical() return 1 end
function modifier_thdots_reisenOld04_illusion:GetAbsoluteNoDamageMagical() return 1 end
function modifier_thdots_reisenOld04_illusion:GetAbsoluteNoDamagePure() return 1 end

--=================================================================================================================
-- 魔晶主动窗口：期间新触发的幻象均为铃仙自己的幻象
--=================================================================================================================
modifier_thdots_reisenOld04_shard_window = class({})
LinkLuaModifier("modifier_thdots_reisenOld04_shard_window", "scripts/vscripts/abilities/abilityreisen.lua",
	LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_reisenOld04_shard_window:IsBuff() return true end
function modifier_thdots_reisenOld04_shard_window:IsPurgable() return false end
function modifier_thdots_reisenOld04_shard_window:IsHidden() return true end

-- 魔晶主动（挂在大招本体上，不再占用额外技能栏位）：
--   1) 开启 5 秒窗口，窗口内新触发的幻象全部是铃仙自己的幻象
--   2) 把场上已存在的大招幻象一并转为铃仙自己的幻象并刷新
function OnReisenOld04ShardSpellStart(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local ult = keys.ability
	if ult == nil then
		return
	end
	if not caster:HasShard() then
		ult:EndCooldown()
		return
	end
	if ult:GetLevel() <= 0 then
		ult:EndCooldown()
		return
	end

	local duration = ult:GetSpecialValueFor("illusion_duration")
	local window = ult:GetSpecialValueFor("shard_window_duration")

	-- 先开窗口，保证「随后 5 秒内触发的幻象均为铃仙幻象」
	caster:AddNewModifier(caster, ult, "modifier_thdots_reisenOld04_shard_window", {duration = window})
	caster.reisen_old04_window_end = GameRules:GetGameTime() + window

	-- 再转换场上已有的幻象
	if caster.reisen_old04_illusions ~= nil then
		for key, list in pairs(caster.reisen_old04_illusions) do
			local target = EntIndexToHScript(tonumber(key))
			local newList = {}
			if target ~= nil and not target:IsNull() and target:IsAlive() then
				for _, illusion in pairs(list) do
					if illusion ~= nil and not illusion:IsNull() and illusion:IsAlive() then
						local pos = illusion:GetOrigin()
						illusion:SetForceAttackTarget(nil)
						illusion:ForceKill(true)
						local own = ReisenOld04CreateOne(caster, ult, target, true)
						if own ~= nil then
							FindClearSpaceForUnit(own, pos, true)
							table.insert(newList, own)
						end
					end
				end
				target:AddNewModifier(caster, ult, "modifier_thdots_reisenOld04_mark", {duration = duration})
			end
			caster.reisen_old04_illusions[key] = newList
		end
	end
end

-- =================================================================================================================
-- 【库存保留】未启用的独立技能组 ability_thdots_reisen01 / 02 / 03 / 04 / reisenEx 的实现（RunScript 入口）
--   现 hero.txt 未启用该技能组（槽位为注释状态）；为保证资产不丢失，原样保留。
--   来源：2026-09-19 整合前的工程版本，未做任何修改。
--   ⚠ 已知（整合前既有）：本库存 KV 的 OnReisen04Damage 在 Lua 中并无同名函数，启用该技能组前需补齐。
-- =================================================================================================================
function OnReisenExSpellStart(caster, target)
    for i = 1, 1 do
        local rad = RandomFloat(-math.pi, math.pi)
        local dis = RandomFloat(400, 700)
        local unit = CreateUnitByName("npc_thdots_unit_reisenEx_unit",
            target:GetOrigin() + Vector(dis * math.cos(rad), dis * math.sin(rad), 0), false, caster, caster,
            caster:GetTeam())
        unit:FindAbilityByName("ability_dummy_unit"):SetLevel(1)
        -- unit:MoveToTargetToAttack(target)

        unit:SetContextThink("ability_reisen_ex_spell_think_attack", function()
            if GameRules:IsGamePaused() then
                return 0.03
            end
            if (target == nil) then
                return nil
            end
            local newOrder = {
                UnitIndex = unit:entindex(),
                OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
                TargetIndex = target:entindex(), -- Optional.  Only used when targeting units
                AbilityIndex = 0, -- Optional.  Only used when casting abilities
                Position = nil, -- Optional.  Only used when targeting the ground
                Queue = 0 -- Optional.  Used for queueing up abilities
            }
            ExecuteOrderFromTable(newOrder)
            return nil
        end, 0.1)
        unit:SetContextThink("ability_reisen_ex_spell_think", function()
            if GameRules:IsGamePaused() then
                return 0.03
            end
            unit:ForceKill(true)
        end, 2.3)
    end
    local dummy = CreateUnitByName("npc_dummy_unit", target:GetAbsOrigin(), false, caster, caster,
        caster:GetTeamNumber())
    local ability_dummy_unit = dummy:FindAbilityByName("ability_dummy_unit")
    ability_dummy_unit:SetLevel(1)
    dummy:SetContextThink("ability_reisen_ex_dummy_think", function()
        if GameRules:IsGamePaused() then
            return 0.03
        end
        dummy:RemoveSelf()
    end, 2.3)
end

function OnReisen01SpellStart(keys)
    local caster = EntIndexToHScript(keys.caster_entindex)
    local targetPoint = keys.ability:GetCursorPosition()
    local Reisen01rad = GetRadBetweenTwoVec2D(caster:GetOrigin(), targetPoint)
    keys.ability:SetContextNum("ability_Reisen01_Rad", Reisen01rad, 0)
end

function OnReisen01SpellMove(keys)
    local caster = EntIndexToHScript(keys.caster_entindex)
    local vecCaster = caster:GetOrigin()
    local targets = keys.target_entities
    local Reisen01rad = keys.ability:GetContext("ability_Reisen01_Rad")

    local vec = Vector(vecCaster.x - math.cos(Reisen01rad) * keys.MoveSpeed / 50,
        vecCaster.y - math.sin(Reisen01rad) * keys.MoveSpeed / 50, vecCaster.z)
    caster:SetOrigin(vec)
end

function OnReisen01SpellHit(keys)
    local caster = EntIndexToHScript(keys.caster_entindex)
    local damage_table = {
        ability = keys.ability,
        victim = keys.target,
        attacker = caster,
        damage = keys.ability:GetAbilityDamageType(),
        damage_type = keys.ability:GetAbilityDamageType(),
        damage_flags = 0
    }
    UnitDamageTarget(damage_table)
    if (caster:GetContext("ability_reisen02_buff") == TRUE) then
        local targets = FindUnitsInRadius(caster:GetTeam(), -- caster team
        keys.target:GetOrigin(), -- find position
        nil, -- find entity
        caster:GetContext("ability_reisen02_buff_radius"), -- find radius
        DOTA_UNIT_TARGET_TEAM_ENEMY, keys.ability:GetAbilityTargetType(), 0, FIND_CLOSEST, false)
        OnReisen02FireEffect(keys.target)
        OnReisen02DealDamage(caster, targets)
    end

    OnReisenExSpellStart(caster, keys.target)

    SetTargetToTraversable(caster)
end

function OnReisen02SpellStart(keys)
    local caster = EntIndexToHScript(keys.caster_entindex)
    caster:SetContextNum("ability_reisen02_buff", TRUE, 0)
    caster:SetContextNum("ability_reisen02_buff_damage", keys.BounsDamage, 0)
    caster:SetContextNum("ability_reisen02_buff_stun_duration", keys.Duration, 0)
    caster:SetContextNum("ability_reisen02_buff_radius", keys.Radius, 0)
    caster:SetContextNum("ability_reisen02_buff_type", keys.ability:GetAbilityDamageType(), 0)
    caster:SetContextNum("ability_reisen02_buff_flag", keys.ability:GetAbilityTargetFlags(), 0)
    local effectIndex = ParticleManager:CreateParticle("particles/heroes/reisen/ability_reisen02_buff.vpcf",
        PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControlEnt(effectIndex, 0, caster, 5, "attach_attack1", Vector(0, 0, 0), true)
    ParticleManager:DestroyParticleSystemTime(effectIndex, keys.AbilityDuration)

    caster:SetContextThink("ability_reisen02_buff_timer", function()
        if GameRules:IsGamePaused() then
            return 0.03
        end
        caster:SetContextNum("ability_reisen02_buff", FALSE, 0)
        return nil
    end, keys.AbilityDuration)
end

function OnReisen02DealDamage(caster, targets)
    for _, v in pairs(targets) do
        local damage_table = {
            ability = keys.ability,
            victim = v,
            attacker = caster,
            damage = caster:GetContext("ability_reisen02_buff_damage"),
            damage_type = caster:GetContext("ability_reisen02_buff_type"),
            damage_flags = caster:GetContext("ability_reisen02_buff_flag")
        }

        -- PrintTable(damage_table)
        -- OnReisenExSpellStart(caster,v)
        UnitDamageTarget(damage_table)
        UtilStun:UnitStunTarget(caster, v, caster:GetContext("ability_reisen02_buff_stun_duration"))
    end
end

function OnReisen02FireEffect(v)
    local effectIndex = ParticleManager:CreateParticle("particles/heroes/reisen/ability_reisen02.vpcf",
        PATTACH_CUSTOMORIGIN, v)
    ParticleManager:SetParticleControlEnt(effectIndex, 0, v, 0, follow_origin, v:GetOrigin(), false)
    ParticleManager:DestroyParticleSystem(effectIndex, false)
end

function OnReisen03SpellStart(keys)
    local caster = EntIndexToHScript(keys.caster_entindex)
    local targetPoint = keys.ability:GetCursorPosition()
    local reisen03rad = GetRadBetweenTwoVec2D(caster:GetOrigin(), targetPoint) + math.pi / 3
    local reisen03dis = GetDistanceBetweenTwoVec2D(caster:GetOrigin(), targetPoint)
    local effectIndex = ParticleManager:CreateParticle("particles/heroes/reisen/ability_reisen_01_e.vpcf",
        PATTACH_CUSTOMORIGIN, caster)
    local originVector = caster:GetOrigin() +
                             Vector(math.cos(reisen03rad - math.pi / 37.5) * reisen03dis,
            math.sin(reisen03rad - math.pi / 37.5) * reisen03dis, 0)

    ParticleManager:SetParticleControlEnt(effectIndex, 0, caster, 5, "attach_eye", Vector(0, 0, 0), true)
    ParticleManager:SetParticleControl(effectIndex, 1, originVector)
    ParticleManager:SetParticleControlEnt(effectIndex, 9, caster, 5, "attach_eye", Vector(0, 0, 0), true)

    keys.ability:SetContextNum("ability_reisen03_Rad", reisen03rad, 0)
    keys.ability:SetContextNum("ability_reisen03_dis", reisen03dis, 0)
    keys.ability:SetContextNum("ability_reisen03_effectIndex", effectIndex, 0)

    UnitPauseTarget(caster, caster, 0.5)
end

function OnReisen03SpellMove(keys)
    local caster = EntIndexToHScript(keys.caster_entindex)
    local vecCaster = caster:GetOrigin()
    local targets = keys.target_entities
    local originRad = keys.ability:GetContext("ability_reisen03_Rad")
    local originVector = Vector(math.cos(originRad), math.sin(originRad), 0)
    local originDis = keys.ability:GetContext("ability_reisen03_dis")

    for _, v in pairs(targets) do
        local vecV = v:GetOrigin()
        if (IsRadInRect(vecV, vecCaster, 100, originDis, originRad)) then
            local damage_table = {
                victim = v,
                attacker = caster,
                damage = keys.ability:GetSpecialValueFor("total_damage"),
                damage_type = keys.ability:GetAbilityDamageType(),
                ability_damage_target_type = keys.ability:GetAbilityTargetType(),
                damage_flags = 0
            }
            OnReisen03DamageTarget(damage_table)
        end
    end
    local effectIndex = keys.ability:GetContext("ability_reisen03_effectIndex")
    local originRad = originRad - math.pi / 37.5
    caster:SetForwardVector(Vector(math.cos(originRad) * originDis, math.sin(originRad) * originDis, 0))
    local forwardVec = caster:GetForwardVector()
    keys.ability:SetContextNum("ability_reisen03_Rad", originRad, 0)

    ParticleManager:SetParticleControl(effectIndex, 1, caster:GetOrigin() +
        Vector(math.cos(originRad) * originDis, math.sin(originRad) * originDis, 0))

    ParticleManager:DestroyParticleSystem(effectIndex, false)
end

function OnReisen03DamageTarget(damage_table)
    local caster = damage_table.attacker
    local target = damage_table.victim
    if (target:GetContext("ability_reisen03_damage_tag") == nil or target:GetContext("ability_reisen03_damage_tag") ==
        FALSE) then
        target:SetContextNum("ability_reisen03_damage_tag", TRUE, 0)
        Timer.Wait 'ability_reisen03_damage_tag'(1, function()
            OnReisenExSpellStart(caster, target)
            UnitDamageTarget(damage_table)

            if (caster:GetContext("ability_reisen02_buff") == TRUE) then
                local targets = FindUnitsInRadius(caster:GetTeam(), -- caster team
                target:GetOrigin(), -- find position
                nil, -- find entity
                caster:GetContext("ability_reisen02_buff_radius"), -- find radius
                DOTA_UNIT_TARGET_TEAM_ENEMY, damage_table.ability_damage_target_type, 0, FIND_CLOSEST, false)
                OnReisen02FireEffect(target)
                OnReisen02DealDamage(caster, targets)
            end

            target:SetContextNum("ability_reisen03_damage_tag", FALSE, 0)
        end)
    end
end

function OnReisen04SpellStart(keys)
    local caster = EntIndexToHScript(keys.caster_entindex)
    local OnHitFuction = "OnReisen04ProjectileOnHit"
    local forwardVec = caster:GetForwardVector()
    local forwardCos = forwardVec.x
    local forwardSin = forwardVec.y

    for i = 1, 5 do
        local rollRad = math.pi / 6 * i - math.pi / 2
        local shotVector = Vector(math.cos(rollRad) * forwardCos - math.sin(rollRad) * forwardSin,
            forwardSin * math.cos(rollRad) + forwardCos * math.sin(rollRad), 0)
        local BulletTable = {
            Ability = keys.ability,
            EffectName = "particles/heroes/reisen/ability_reisen_04_bullet.vpcf",
            vSpawnOrigin = caster:GetOrigin() + Vector(0, 0, 64),
            vSpawnOriginNew = caster:GetOrigin() + Vector(0, 0, 64),
            fDistance = 1500,
            fStartRadius = keys.DamageRadius,
            fEndRadius = keys.DamageRadius,
            Source = caster,
            bHasFrontalCone = false,
            bRepalceExisting = false,
            iUnitTargetTeams = "DOTA_UNIT_TARGET_TEAM_ENEMY",
            iUnitTargetTypes = "DOTA_UNIT_TARGET_HERO | DOTA_UNIT_TARGET_CREEP",
            iUnitTargetFlags = "DOTA_UNIT_TARGET_FLAG_NONE",
            fExpireTime = GameRules:GetGameTime() + 10.0,
            bDeleteOnHit = true,
            vVelocity = shotVector,
            bProvidesVision = true,
            iVisionRadius = 400,
            iVisionTeamNumber = caster:GetTeamNumber()
        }
        DotsCreateProjectileMoveToTargetPoint(BulletTable, caster, keys.MoveSpeed, keys.Acceleration1,
            keys.Acceleration2, OnHitFuction)
    end
end

function OnReisen04ProjectileOnHit(caster, targets, ability)
    local damage_table = {
        ability = keys.ability,
        victim = targets[1],
        attacker = caster,
        damage = ability:GetAbilityDamage(),
        damage_type = ability:GetAbilityDamageType(),
        damage_flags = ability:GetAbilityTargetFlags()
    }
    OnReisenExSpellStart(caster, targets[1])
    UnitDamageTarget(damage_table)
    if (caster:GetContext("ability_reisen02_buff") == TRUE and
        (GetDistanceBetweenTwoVec2D(caster:GetOrigin(), targets[1]:GetOrigin()) >= 200)) then
        local targets02 = FindUnitsInRadius(caster:GetTeam(), -- caster team
        targets[1]:GetOrigin(), -- find position
        nil, -- find entity
        caster:GetContext("ability_reisen02_buff_radius"), -- find radius
        DOTA_UNIT_TARGET_TEAM_ENEMY, ability:GetAbilityTargetType(), 0, FIND_CLOSEST, false)
        OnReisen02FireEffect(targets[1])
        OnReisen02DealDamage(caster, targets02)
    end
end

function DotsCreateProjectileMoveToTargetPoint(projectileTable, caster, speed, acceleration1, acceleration2,
    OnHitFuction)
    local effectIndex = ParticleManager:CreateParticle(projectileTable.EffectName, PATTACH_CUSTOMORIGIN, caster)
    local acceleration = acceleration1
    local targets = {}
    caster:SetContextThink(DoUniqueString("ability_caster_projectile"), function()
        if GameRules:IsGamePaused() then
            return 0.03
        end
        local vec = projectileTable.vSpawnOriginNew + projectileTable.vVelocity * speed / 50
        local dis = GetDistanceBetweenTwoVec2D(projectileTable.vSpawnOrigin, vec)
        targets = FindUnitsInRadius(caster:GetTeam(), -- caster team
        vec, -- find position
        nil, -- find entity
        projectileTable.fStartRadius, -- find radius
        projectileTable.Ability:GetAbilityTargetTeam(), projectileTable.Ability:GetAbilityTargetType(),
            projectileTable.Ability:GetAbilityTargetFlags(), FIND_CLOSEST, false)
        if (targets[1] ~= nil) then
            if (projectileTable.bDeleteOnHit) then
                if (OnHitFuction == "OnReisen04ProjectileOnHit") then
                    OnReisen04ProjectileOnHit(caster, targets, projectileTable.Ability)
                end
                ParticleManager:DestroyParticleSystem(effectIndex, true)
                return nil
            else
                if (OnHitFuction == "OnReisen04ProjectileOnHit") then
                    OnReisen04ProjectileOnHit(caster, targets, projectileTable.Ability)
                end
                targets = {}
            end
        end

        if (speed <= 0 and acceleration2 ~= 0) then
            acceleration = acceleration2
            speed = 0
            acceleration2 = 0
        end

        if (dis < projectileTable.fDistance) then
            ParticleManager:SetParticleControl(effectIndex, 3, vec)
            projectileTable.vSpawnOriginNew = vec
            speed = speed + acceleration
            return 0.02
        else
            ParticleManager:DestroyParticleSystem(effectIndex, true)
            return nil
        end
    end, 0.02)
end
