--keys.caster --施法者
--keys.target_entities -- 目标表
--keys.ability --技能

ability_thdots_rumia01 = {}

function ability_thdots_rumia01:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor("duration")
	if FindTelentValue(caster,"special_bonus_unique_rumia_3")==1 then
		caster:Purge(false,true,false,true,false)
	end
	caster:EmitSound("Voice_Thdots_Rumia.AbilityRumia01")
	caster:AddNewModifier(caster, self, "modifier_rumia01_buff", {duration = duration})

	local unit = CreateUnitByName(
		"npc_dummy_unit"
		,caster:GetOrigin()
		,false
		,caster
		,caster
		,caster:GetTeam()
	)
	local ability_dummy_unit = unit:FindAbilityByName("ability_dummy_unit")
	ability_dummy_unit:SetLevel(1)
	unit:AddNewModifier(caster, self, "modifier_rumia01_effect", {duration = duration})
end

modifier_rumia01_effect = {}
LinkLuaModifier("modifier_rumia01_effect", "scripts/vscripts/abilities/abilityRumia.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_rumia01_effect:IsHidden() 		return true end
function modifier_rumia01_effect:IsPurgable()		return false end
function modifier_rumia01_effect:RemoveOnDeath() 	return true end
function modifier_rumia01_effect:IsDebuff()			return false end

function modifier_rumia01_effect:GetEffectName()
	return "particles/thd2/heroes/rumia/ability_rumia01_effect.vpcf"
end
function modifier_rumia01_effect:GetEffectAttachType()
	return "PATTACH_CUSTOMORIGIN_FOLLOW"
end

function modifier_rumia01_effect:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.1)
end
function modifier_rumia01_effect:OnIntervalThink()
	if not IsServer() then return end
	self:GetParent():SetOrigin(self:GetCaster():GetOrigin())
end
function modifier_rumia01_effect:OnDestroy()
	if not IsServer() then return end
	self:GetParent():RemoveSelf()
end

modifier_rumia01_buff = {}
LinkLuaModifier("modifier_rumia01_buff", "scripts/vscripts/abilities/abilityRumia.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_rumia01_buff:IsHidden() 		return true end
function modifier_rumia01_buff:IsPurgable()		return false end
function modifier_rumia01_buff:RemoveOnDeath() 	return true end
function modifier_rumia01_buff:IsDebuff()		return false end

function modifier_rumia01_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_EVASION_CONSTANT,
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE
	}
end
function modifier_rumia01_buff:GetModifierEvasion_Constant() return self:GetAbility():GetSpecialValueFor("evasion") end
function modifier_rumia01_buff:GetModifierHealthRegenPercentage() return self:GetAbility():GetSpecialValueFor("health_regen_pct") end

function modifier_rumia01_buff:CheckState()
	return {
		[MODIFIER_STATE_INVISIBLE] = true
	}
end

ability_thdots_rumia02 = {}

function ability_thdots_rumia02:GetIntrinsicModifierName() return "passive_rumia02_attack" end

passive_rumia02_attack = {}
LinkLuaModifier("passive_rumia02_attack", "scripts/vscripts/abilities/abilityRumia.lua", LUA_MODIFIER_MOTION_NONE)
function passive_rumia02_attack:IsHidden() 			return false end
function passive_rumia02_attack:IsPurgable()		return false end
function passive_rumia02_attack:RemoveOnDeath() 	return false end
function passive_rumia02_attack:IsDebuff()			return false end

function passive_rumia02_attack:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_ATTACK_START
	}
end
function passive_rumia02_attack:OnAttackLanded(keys)
	local parent = self:GetParent()
	if parent ~= keys.attacker then return end
	local ability = self:GetAbility()
	local target = keys.target
	if target ~= nil and not target:IsAncient() and not target:IsBuilding() then
		local effectIndex = ParticleManager:CreateParticle(
			"particles/thd2/heroes/rumia/ability_rumia02_effect.vpcf",
			PATTACH_ABSORIGIN_FOLLOW,
			target)
		ParticleManager:DestroyParticle(effectIndex, false)
		target:AddNewModifier(parent, ability, "modifier_rumia02_bleed", {duration = ability:GetSpecialValueFor("duration")})
	end
end
function passive_rumia02_attack:OnAttackStart(keys)
	if not IsServer() then return end
	local parent = self:GetParent()
	local ability = self:GetAbility()
	if parent == keys.attacker then
		if RollPercentage(ability:GetSpecialValueFor("crit_chance")) then
			parent:AddNewModifier(parent, ability, "modifier_rumia02_crit", {})
		end
	end
end

modifier_rumia02_crit = {}
LinkLuaModifier("modifier_rumia02_crit", "scripts/vscripts/abilities/abilityRumia.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_rumia02_crit:IsHidden() 		return true end
function modifier_rumia02_crit:IsPurgable()		return false end
function modifier_rumia02_crit:RemoveOnDeath() 	return false end
function modifier_rumia02_crit:IsDebuff()		return false end

function modifier_rumia02_crit:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
		MODIFIER_EVENT_ON_ATTACK_LANDED
	}
end
function modifier_rumia02_crit:GetModifierPreAttack_CriticalStrike() return self:GetAbility():GetSpecialValueFor("crit_damage") end
function modifier_rumia02_crit:OnAttackLanded(keys)
	if keys.attacker ~= self:GetParent() then return end
	keys.attacker:RemoveModifierByName("modifier_rumia02_crit")
end

modifier_rumia02_bleed = {}
LinkLuaModifier("modifier_rumia02_bleed", "scripts/vscripts/abilities/abilityRumia.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_rumia02_bleed:IsHidden() 			return false end
function modifier_rumia02_bleed:IsPurgable()		return true end
function modifier_rumia02_bleed:RemoveOnDeath() 	return true end
function modifier_rumia02_bleed:IsDebuff()			return true end

function modifier_rumia02_bleed:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	}
end
function modifier_rumia02_bleed:GetModifierMoveSpeedBonus_Percentage() return self:GetAbility():GetSpecialValueFor("move_speed_slow") end

function modifier_rumia02_bleed:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("think_interval"))
end
function modifier_rumia02_bleed:OnIntervalThink()
	if not IsServer() then return end
	local ability = self:GetAbility()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	local DamageTable = {
		ability = ability,
		victim = parent,
		attacker = caster,
		damage = ability:GetSpecialValueFor("damage"),
		damage_type = ability:GetAbilityDamageType(),
		damage_flags = 0
	}
	UnitDamageTarget(DamageTable)
end

ability_thdots_rumia03 = {}

function ability_thdots_rumia03:GetIntrinsicModifierName() return "modifier_rumia_03_think" end

modifier_rumia_03_think = {}
LinkLuaModifier("modifier_rumia_03_think", "scripts/vscripts/abilities/abilityRumia.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_rumia_03_think:IsHidden() 		return true end
function modifier_rumia_03_think:IsPurgable()		return false end
function modifier_rumia_03_think:RemoveOnDeath() 	return false end
function modifier_rumia_03_think:IsDebuff()			return false end

function modifier_rumia_03_think:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.3)
end
function modifier_rumia_03_think:OnIntervalThink()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local ability = self:GetAbility()

	if caster:IsAlive() then
		if GameRules:IsDaytime() then
			if caster:HasModifier("modifier_rumia_03_night") then
				caster:RemoveModifierByName("modifier_rumia_03_night")
			end
			if not caster:HasModifier("modifier_rumia_03_day") then
				caster:AddNewModifier(caster, ability, "modifier_rumia_03_day", {})
			end
		else
			if caster:HasModifier("modifier_rumia_03_day") and caster:HasModifier("modifier_rumia_03_night") == false then
				caster:RemoveModifierByName("modifier_rumia_03_day")
			end
			if not caster:HasModifier("modifier_rumia_03_night") then
				caster:AddNewModifier(caster, ability, "modifier_rumia_03_night", {})
			end
		end
	end
end

modifier_rumia_03_day = {}
LinkLuaModifier("modifier_rumia_03_day", "scripts/vscripts/abilities/abilityRumia.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_rumia_03_day:IsHidden() 		return false end
function modifier_rumia_03_day:IsPurgable()		return false end
function modifier_rumia_03_day:RemoveOnDeath() 	return true end
function modifier_rumia_03_day:IsDebuff()		return false end

function modifier_rumia_03_day:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
	}
end
function modifier_rumia_03_day:GetModifierMoveSpeedBonus_Percentage() return self:GetAbility():GetSpecialValueFor("day_move_speed") end
function modifier_rumia_03_day:GetModifierAttackSpeedBonus_Constant() return self:GetAbility():GetSpecialValueFor("day_attack_speed") end

modifier_rumia_03_night = {}
LinkLuaModifier("modifier_rumia_03_night", "scripts/vscripts/abilities/abilityRumia.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_rumia_03_night:IsHidden() 		return false end
function modifier_rumia_03_night:IsPurgable()		return false end
function modifier_rumia_03_night:RemoveOnDeath() 	return true end
function modifier_rumia_03_night:IsDebuff()		return false end

function modifier_rumia_03_night:GetEffectName()
	return "particles/econ/items/nightstalker/nightstalker_black_nihility/nightstalker_black_nihility_void_swarm.vpcf"
end
function modifier_rumia_03_night:GetEffectAttachType()
	return "PATTACH_CUSTOMORIGIN_FOLLOW"
end

function modifier_rumia_03_night:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
	}
end
function modifier_rumia_03_night:GetModifierMoveSpeedBonus_Percentage() return self:GetAbility():GetSpecialValueFor("night_move_speed") end
function modifier_rumia_03_night:GetModifierAttackSpeedBonus_Constant() return self:GetAbility():GetSpecialValueFor("night_attack_speed") end

ability_thdots_rumia04 = {}

function ability_thdots_rumia04:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	target:AddNewModifier(caster, self, "modifier_rumia04_effect", {duration = 1})
	if is_spell_blocked(target) then return end
	if RollPercentage(50) then
		caster:EmitSound("Voice_Thdots_Rumia.AbilityRumia04")
	end

	local DamageTable= {
		ability = self,
		victim = target,
		attacker = caster,
		damage = self:GetAbilityDamage(),
		damage_type = DAMAGE_TYPE_PURE,
	}
	if target:IsHero() ==false and (target:GetClassname()~="npc_dota_roshan") and not target:HasModifier("modifier_ability_thdots_super_siege") then
		DamageTable.damage = 99999
	end

	local Rumia_Strength_Bouns = 0
	local Rumia_Strength_Up = 0
	local steal_health = self:GetSpecialValueFor("steal_health_percent") / 100
	if (caster:GetTeam() ~= target:GetTeam())then
		if target:GetHealth() <= DamageTable.damage  then
			--local strength = 0
			if target:IsHero() then
				if not target:HasModifier("modifier_illusion")	then
					Rumia_Strength_Up = self:GetSpecialValueFor("hero_str_gain")
				end
			else
				Rumia_Strength_Up = self:GetSpecialValueFor("str_gain")
			end
				caster:SetHealth(caster:GetHealth() + target:GetHealth()*steal_health)
				caster:CalculateStatBonus(true)
				local strength_buff = caster:FindModifierByName("modifier_ability_thdots_rumia04_strength")
				if not strength_buff then
					strength_buff = caster:AddNewModifier(caster, self, "modifier_ability_thdots_rumia04_strength", {})
					--strength_buff:SetStackCount(0)
				end
				Rumia_Strength_Bouns = strength_buff:GetStackCount()
				strength_buff:SetStackCount(Rumia_Strength_Bouns + Rumia_Strength_Up)
		else
			caster:SetHealth(caster:GetHealth() + self:GetAbilityDamage()*steal_health)
		end
		--特效
		caster:EmitSound("Hero_LifeStealer.Infest")
		local infest_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_life_stealer/life_stealer_infest_cast.vpcf", PATTACH_POINT, caster)
		ParticleManager:SetParticleControl(infest_particle, 0, target:GetAbsOrigin())
		ParticleManager:SetParticleControlEnt(infest_particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
		ParticleManager:ReleaseParticleIndex(infest_particle)

		if DamageTable.damage == 99999 then
			target:Kill(self,caster)
		else
			UnitDamageTarget(DamageTable)
		end
	end
end

function ability_thdots_rumia04:GetIntrinsicModifierName() return "passive_rumia04_wanbaochui" end

modifier_rumia04_effect = {}
LinkLuaModifier("modifier_rumia04_effect", "scripts/vscripts/abilities/abilityrumia.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_rumia04_effect:IsHidden()			return false end
function modifier_rumia04_effect:IsDebuff()			return false end
function modifier_rumia04_effect:IsPurgable()		return false end
function modifier_rumia04_effect:RemoveOnDeath()	return false end

function modifier_rumia04_effect:GetEffectName()
	return "particles/blood_impact/blood_advisor_pierce_spray.vpcf"
end
function modifier_rumia04_effect:GetEffectAttachType()
	return "PATTACH_ABSORIGIN_FOLLOW"
end

modifier_ability_thdots_rumia04_strength = {}
LinkLuaModifier("modifier_ability_thdots_rumia04_strength", "scripts/vscripts/abilities/abilityrumia.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_rumia04_strength:IsHidden()		return false end
function modifier_ability_thdots_rumia04_strength:IsDebuff()		return false end
function modifier_ability_thdots_rumia04_strength:IsPurgable()		return false end
function modifier_ability_thdots_rumia04_strength:RemoveOnDeath()	return false end
function modifier_ability_thdots_rumia04_strength:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_ability_thdots_rumia04_strength:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_EVENT_ON_DEATH,
		}
end

function modifier_ability_thdots_rumia04_strength:GetModifierBonusStats_Strength()
	return self:GetStackCount()
end

function modifier_ability_thdots_rumia04_strength:OnDeath(keys)
	if not IsServer() then return end
	local caster = self:GetCaster()
	if caster ~= keys.unit then return end
	local Rumia_Strength_Up = self:GetStackCount()
	if ( Rumia_Strength_Up == nil or Rumia_Strength_Up <= 0 ) then return end	
	local strengthDown = Rumia_Strength_Up*self:GetAbility():GetSpecialValueFor("lost_strength_percent")/100
	Rumia_Strength_Up = Rumia_Strength_Up - strengthDown
	self:SetStackCount(Rumia_Strength_Up)
end

passive_rumia04_wanbaochui = {}
LinkLuaModifier("passive_rumia04_wanbaochui", "scripts/vscripts/abilities/abilityrumia.lua", LUA_MODIFIER_MOTION_NONE)
function passive_rumia04_wanbaochui:IsHidden()		return true end
function passive_rumia04_wanbaochui:IsDebuff()		return false end
function passive_rumia04_wanbaochui:IsPurgable()	return false end
function passive_rumia04_wanbaochui:RemoveOnDeath()	return false end

function passive_rumia04_wanbaochui:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED
	}
end
function passive_rumia04_wanbaochui:OnAttackLanded(keys)
	if keys.attacker ~= self:GetParent() then return end
	local parent = self:GetParent()
	local target = keys.target
	local ability = self:GetAbility()
	if RollPercentage(ability:GetSpecialValueFor("eat_chance")) then
		if (parent:IsRealHero() and parent:HasModifier("modifier_item_wanbaochui") and target:IsBuilding()==false) then
			local steal_health = ability:GetSpecialValueFor("steal_health_percent") / 100
			local DamageTable= {
				ability = ability,
				victim = target,
				attacker = parent,
				damage = ability:GetAbilityDamage()/2,
				damage_type = DAMAGE_TYPE_PURE,
			}
			if target:IsHero() == false and (target:GetClassname()~="npc_dota_roshan") then
				DamageTable.damage = 99999
			end
			if (parent:GetTeam() ~= target:GetTeam())then
				if target:GetHealth() <= DamageTable.damage  then
					parent:SetHealth(parent:GetHealth() + target:GetHealth()*steal_health)
				else
					parent:SetHealth(parent:GetHealth() + DamageTable.damage*steal_health)
				end
				local vec = target:GetOrigin()
				UnitDamageTarget(DamageTable)
				local effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_culling_blade_kill.vpcf", PATTACH_CUSTOMORIGIN, parent)
				ParticleManager:SetParticleControl(effectIndex, 0, vec)
				ParticleManager:SetParticleControl(effectIndex, 1, vec)
				ParticleManager:SetParticleControl(effectIndex, 2, vec)
				ParticleManager:SetParticleControl(effectIndex, 3, vec)
				ParticleManager:SetParticleControl(effectIndex, 4, vec)
				ParticleManager:SetParticleControl(effectIndex, 8, vec)
			end
		end
	end
end
