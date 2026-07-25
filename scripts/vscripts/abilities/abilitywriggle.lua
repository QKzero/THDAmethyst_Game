--function OnWriggle01Start(keys)
--	local caster = keys.caster
--	local unit = CreateUnitByName(
--		"npc_vision_dummy_unit"
--		,caster:GetOrigin()
--		,false
--		,caster
--		,caster
--		,caster:GetTeam()
--	)

--	unit:SetDayTimeVisionRange(keys.Vision)
--	unit:SetNightTimeVisionRange(keys.Vision)
--	if FindTelentValue(caster,"special_bonus_unique_wriggle_3") ~= 0 then
--		local abilityGEM = unit:FindAbilityByName("ability_thdots_wriggle_talent_unit")
--		if abilityGEM ~= nil then
--			abilityGEM:SetLevel(1)
--			unit:CastAbilityImmediately(abilityGEM, 0)
--		end
--	end
	
--	local effectIndex = ParticleManager:CreateParticle("particles/econ/items/outworld_devourer/od_shards_exile/od_shards_exile_prison_top_orb.vpcf", PATTACH_CUSTOMORIGIN, caster) 
--	ParticleManager:SetParticleControlEnt(effectIndex , 0, caster, 5, "attach_hitloc", Vector(0,0,0), true)

--	Timer.Loop 'ability_wriggle_01_vision' (0.1, keys.Duration * 10,
--			function(i)
--				unit:SetOrigin(caster:GetOrigin())
--				if i == keys.Duration * 10 then
--					unit:RemoveSelf()
--					if caster:HasItemInInventory("item_gem") == false then
--						caster:RemoveModifierByName("modifier_item_gem_of_true_sight")
--					end
--					ParticleManager:DestroyParticleSystem(effectIndex,true)
--					return true
--				end
--			end
--	)
--end

function OnWriggle03AttackLanded(keys)
	local caster = keys.caster
	
	if keys.ability:IsCooldownReady() then

		local caster = EntIndexToHScript(keys.caster_entindex)
		local target = keys.target
		if target == nil then
			return
		end

		caster:PerformAttack(target, false, true, true, true, true, false, false)
		local projectileTable = {
			Target = target,
			Source = caster,
			Ability = keys.ability,	
			EffectName = "particles/units/heroes/hero_weaver/weaver_base_attack.vpcf",
			iMoveSpeed = 1500,
			vSourceLoc= caster:GetAbsOrigin(),
			bDrawsOnMinimap = false, 
		    bDodgeable = true,
		    bIsAttack = false, 
		    bVisibleToEnemies = true,
		    bReplaceExisting = false,
		    flExpireTime = GameRules:GetGameTime() + 10,
			bProvidesVision = true,
			iVisionRadius = 100,
			iVisionTeamNumber = caster:GetTeamNumber(),
			iSourceAttachment = 1
		} 
		ProjectileManager:CreateTrackingProjectile(projectileTable)
		keys.ability:StartCooldown(keys.ability:GetCooldown(keys.ability:GetLevel() - 1))
		local cd_len = keys.ability:GetCooldown(keys.ability:GetLevel() - 1)
		if caster:HasModifier("modifier_cooldown_reduction_15") then
			cd_len = cd_len * 0.85;
		elseif caster:HasModifier("modifier_item_nuclear_stick_cooldown_reduction") then
			cd_len = cd_len * 0.75;
		end
		keys.ability:StartCooldown(cd_len)
	end
end

function OnWriggle03ProjectileHit(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local target = keys.target
	local DamageTable = {
			ability = keys.ability,
			victim = target, 
			attacker = caster, 
			damage = keys.BaseDamage,
			damage_type = keys.ability:GetAbilityDamageType(),
			damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK
	}
	UtilSilence:UnitSilenceTarget( caster,target,keys.SilenceDuration)
	UnitDamageTarget(DamageTable)
end

ability_thdots_wriggle04 = ability_thdots_wriggle04 or class({})

function ability_thdots_wriggle04:GetIntrinsicModifierName()
	-- 4技能改为Lua永久被动，由统一modifier管理隐身、天赋和万宝槌状态。
	return "modifier_ability_thdots_wriggle04_passive"
end

LinkLuaModifier("modifier_ability_thdots_wriggle04_passive","scripts/vscripts/abilities/abilitywriggle.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wriggle04_invisible","scripts/vscripts/abilities/abilitywriggle.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wriggle04_noinvisible","scripts/vscripts/abilities/abilitywriggle.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("wriggle_wanbaochui_buff","scripts/vscripts/abilities/abilitywriggle.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("wriggle_wanbaochui_buff_2","scripts/vscripts/abilities/abilitywriggle.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("wriggle_talent_modifier_spell_amplify_40","scripts/vscripts/abilities/abilitywriggle.lua",LUA_MODIFIER_MOTION_NONE)

modifier_ability_thdots_wriggle04_passive = modifier_ability_thdots_wriggle04_passive or class({})
function modifier_ability_thdots_wriggle04_passive:IsHidden() return true end
function modifier_ability_thdots_wriggle04_passive:IsPurgable() return false end
function modifier_ability_thdots_wriggle04_passive:IsDebuff() return false end
function modifier_ability_thdots_wriggle04_passive:RemoveOnDeath() return false end

function modifier_ability_thdots_wriggle04_passive:OnCreated()
	if not IsServer() then return end
	self.wanbaochui_radius = 900
	-- 保留0.1秒状态刷新，但万宝槌范围搜索只在持有万宝槌时执行。
	self:StartIntervalThink(0.1)
	self:OnIntervalThink()
end

function modifier_ability_thdots_wriggle04_passive:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_START,
	}
end

function modifier_ability_thdots_wriggle04_passive:OnAttackStart(keys)
	if not IsServer() then return end
	if keys.attacker ~= self:GetParent() then return end
	local ability = self:GetAbility()
	if not ability or ability:GetLevel() <= 0 then return end
	-- 攻击开始时按原设计破隐，并进入不可隐身间隔。
	self:BreakInvisible()
end

function modifier_ability_thdots_wriggle04_passive:OnIntervalThink()
	if not IsServer() then return end
	local ability = self:GetAbility()
	if not ability or ability:GetLevel() <= 0 then
		-- intrinsic未学习时可能已存在，需要清理被动产生的状态。
		local caster = self:GetParent()
		caster:RemoveModifierByName("modifier_wriggle04_invisible")
		caster:RemoveModifierByName("wriggle_wanbaochui_buff")
		caster:RemoveModifierByName("wriggle_wanbaochui_buff_2")
		return
	end
	self:RefreshTalentModifier()
	self:RefreshWanbaochuiBuff()
	self:TryEnterInvisible()
end

function modifier_ability_thdots_wriggle04_passive:BreakInvisible()
	local caster = self:GetParent()
	if caster:HasModifier("modifier_wriggle04_invisible") then
		-- 仅在真实破隐时播放破隐粒子，避免普通攻击反复创建无效粒子。
		local effectIndex = ParticleManager:CreateParticle("particles/econ/courier/courier_master_chocobo/courier_master_chocobo_ambient_death_b.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(effectIndex, 0, caster:GetOrigin())
		ParticleManager:DestroyParticle(effectIndex, false)
		ParticleManager:ReleaseParticleIndex(effectIndex)
	end

	caster:AddNewModifier(caster, self:GetAbility(), "modifier_wriggle04_noinvisible", {duration = self:GetAbility():GetSpecialValueFor("invisible_interval")})
	caster:RemoveModifierByName("modifier_wriggle04_invisible")
end

function modifier_ability_thdots_wriggle04_passive:TryEnterInvisible()
	local caster = self:GetParent()
	local ability = self:GetAbility()
	if not ability or ability:GetLevel() <= 0 or not caster:IsAlive() or caster:PassivesDisabled() then
		caster:RemoveModifierByName("modifier_wriggle04_invisible")
		return
	end
	if not caster:HasModifier("modifier_wriggle04_noinvisible") and not caster:HasModifier("modifier_wriggle04_invisible") then
		-- 满足条件时立即补上隐身，noinvisible结束时也会主动调用这里。
		caster:AddNewModifier(caster, self:GetAbility(), "modifier_wriggle04_invisible", {})
	end
end

function modifier_ability_thdots_wriggle04_passive:RefreshTalentModifier()
	local caster = self:GetParent()
	local talent = caster:FindAbilityByName("special_bonus_unique_wriggle_2")
	if talent and talent:GetLevel() ~= 0 and not caster:HasModifier("wriggle_talent_modifier_spell_amplify_40") then
		-- 天赋学到后只补一次modifier，数值从天赋KV读取。
		local modifier = caster:AddNewModifier(caster, self:GetAbility(), "wriggle_talent_modifier_spell_amplify_40", {})
		if modifier then
			modifier:SetStackCount(talent:GetSpecialValueFor("value"))
		end
	end
end

function modifier_ability_thdots_wriggle04_passive:RefreshWanbaochuiBuff()
	local caster = self:GetParent()
	if caster:PassivesDisabled() or not caster:HasModifier("modifier_item_wanbaochui") then
		-- 没有万宝槌时不做范围搜索，只清理可能残留的两种状态。
		caster:RemoveModifierByName("wriggle_wanbaochui_buff")
		caster:RemoveModifierByName("wriggle_wanbaochui_buff_2")
		return
	end

	local targets = FindUnitsInRadius(
				caster:GetTeam(),
				caster:GetOrigin(),
				nil,
				self.wanbaochui_radius,
				DOTA_UNIT_TARGET_TEAM_ENEMY,
				DOTA_UNIT_TARGET_HERO,
				0, FIND_CLOSEST,
				false
	)

	local has_real_target = false
	for _,v in pairs(targets) do
		if not v:HasModifier("modifier_illusion") then
			-- 只需要判断是否存在真实英雄，找到一个即可停止遍历。
			has_real_target = true
			break
		end
	end

	if has_real_target then
		if not caster:HasModifier("wriggle_wanbaochui_buff_2") then
			caster:AddNewModifier(caster, self:GetAbility(), "wriggle_wanbaochui_buff_2", {})
		end
		caster:RemoveModifierByName("wriggle_wanbaochui_buff")
	else
		if not caster:HasModifier("wriggle_wanbaochui_buff") then
			caster:AddNewModifier(caster, self:GetAbility(), "wriggle_wanbaochui_buff", {})
		end
		caster:RemoveModifierByName("wriggle_wanbaochui_buff_2")
	end
end

modifier_wriggle04_invisible = modifier_wriggle04_invisible or class({})
function modifier_wriggle04_invisible:IsHidden() return true end
function modifier_wriggle04_invisible:IsPurgable() return false end
function modifier_wriggle04_invisible:IsDebuff() return false end
function modifier_wriggle04_invisible:RemoveOnDeath() return true end
function modifier_wriggle04_invisible:GetEffectName() return "particles/units/heroes/hero_mirana/mirana_moonlight_owner.vpcf" end
function modifier_wriggle04_invisible:GetEffectAttachType() return PATTACH_POINT_FOLLOW end
function modifier_wriggle04_invisible:CheckState()
	return {
		[MODIFIER_STATE_INVISIBLE] = true,
	}
end

modifier_wriggle04_noinvisible = modifier_wriggle04_noinvisible or class({})
function modifier_wriggle04_noinvisible:IsHidden() return true end
function modifier_wriggle04_noinvisible:IsPurgable() return false end
function modifier_wriggle04_noinvisible:IsDebuff() return false end
function modifier_wriggle04_noinvisible:RemoveOnDeath() return true end
function modifier_wriggle04_noinvisible:OnDestroy()
	if not IsServer() then return end
	local passive = self:GetParent():FindModifierByName("modifier_ability_thdots_wriggle04_passive")
	if passive then
		-- 不可隐身间隔结束时立刻尝试隐身，避免等下一次0.1秒刷新。
		passive:TryEnterInvisible()
	end
end

wriggle_wanbaochui_buff = wriggle_wanbaochui_buff or class({})
function wriggle_wanbaochui_buff:IsHidden() return false end
function wriggle_wanbaochui_buff:IsPurgable() return false end
function wriggle_wanbaochui_buff:IsDebuff() return false end
function wriggle_wanbaochui_buff:RemoveOnDeath() return false end
function wriggle_wanbaochui_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
		MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end
function wriggle_wanbaochui_buff:GetModifierHealthRegenPercentage() return 3 end
function wriggle_wanbaochui_buff:GetModifierTotalPercentageManaRegen() return 3 end
function wriggle_wanbaochui_buff:GetModifierMoveSpeedBonus_Percentage() return 40 end

wriggle_wanbaochui_buff_2 = wriggle_wanbaochui_buff_2 or class({})
function wriggle_wanbaochui_buff_2:IsHidden() return false end
function wriggle_wanbaochui_buff_2:IsPurgable() return false end
function wriggle_wanbaochui_buff_2:IsDebuff() return false end
function wriggle_wanbaochui_buff_2:RemoveOnDeath() return false end
function wriggle_wanbaochui_buff_2:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end
function wriggle_wanbaochui_buff_2:GetModifierBaseAttack_BonusDamage() return 30 end
function wriggle_wanbaochui_buff_2:GetModifierAttackSpeedBonus_Constant() return 30 end

wriggle_talent_modifier_spell_amplify_40 = wriggle_talent_modifier_spell_amplify_40 or class({})
function wriggle_talent_modifier_spell_amplify_40:IsHidden() return true end
function wriggle_talent_modifier_spell_amplify_40:IsPurgable() return false end
function wriggle_talent_modifier_spell_amplify_40:IsDebuff() return false end
function wriggle_talent_modifier_spell_amplify_40:RemoveOnDeath() return false end
function wriggle_talent_modifier_spell_amplify_40:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
	}
end
function wriggle_talent_modifier_spell_amplify_40:GetModifierSpellAmplify_Percentage()
	return self:GetStackCount()
end

ability_thdots_wriggle01 = {}

function ability_thdots_wriggle01:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor("duration")
	caster:AddNewModifier(caster,self,"modifier_item_gem_of_true_sight",{duration = duration})
	caster:AddNewModifier(caster,self,"modifier_wriggle_check",{duration = duration})
end

ability_thdots_wriggle01_special = {}

function ability_thdots_wriggle01_special:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor("duration")
	local radius = self:GetSpecialValueFor("radius")
	caster:AddNewModifier(caster,self,"modifier_item_gem_of_true_sight",{duration = duration})
	caster:AddNewModifier(caster,self,"modifier_wriggle_check",{duration = duration})
end

modifier_wriggle_check = {}
LinkLuaModifier("modifier_wriggle_check","scripts/vscripts/abilities/abilitywriggle.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_wriggle_check:IsHidden() return false end
function modifier_wriggle_check:IsPurgable() return false end
function modifier_wriggle_check:IsDebuff() return false end
function modifier_wriggle_check:RemoveOnDeath() return true end

-- 1技能视野降低刷新频率，持续时间略大于tick避免视野闪断。
local WRIGGLE_VISION_INTERVAL = 0.5
local WRIGGLE_VISION_DURATION = 0.55

function modifier_wriggle_check:OnCreated()
    if not IsServer() then return end
    self:StartIntervalThink(WRIGGLE_VISION_INTERVAL)
    local caster = self:GetCaster()
	self.effectIndex = ParticleManager:CreateParticle("particles/econ/items/outworld_devourer/od_shards_exile/od_shards_exile_prison_top_orb.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControlEnt(self.effectIndex , 0, caster, 5, "attach_hitloc", Vector(0,0,0), true)
	self.vision = self:GetAbility():GetSpecialValueFor("vision")
end

function modifier_wriggle_check:OnIntervalThink()
	if not IsServer() then return end
	local caster = self:GetCaster()
	THD_AddFOWViewer(caster:GetTeam(),caster:GetAbsOrigin(),self.vision,WRIGGLE_VISION_DURATION,false,"wriggle_check")
end

function modifier_wriggle_check:OnRemoved()
	if not IsServer() then return end
	local caster = self:GetCaster()
	if caster:HasItemInInventory("item_gem") == false then
		caster:RemoveModifierByName("modifier_item_gem_of_true_sight")
	end
	ParticleManager:DestroyParticleSystem(self.effectIndex,true)
end
