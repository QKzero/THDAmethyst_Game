if AbilityTensi == nil then
	AbilityTensi = class({})
end

ability_thdots_tensi02 = {}

function ability_thdots_tensi02:GetCooldown(level)
	local cooldown_reduction = self:GetCaster():GetCooldownReduction()
	local cooldown = self:GetSpecialValueFor("ability_multi") / self:GetCaster():GetStrength()
	return cooldown / cooldown_reduction
end

function ability_thdots_tensi02:GetIntrinsicModifierName() return "passive_tensi02_attack" end

passive_tensi02_attack = {}
LinkLuaModifier("passive_tensi02_attack","scripts/vscripts/abilities/abilityTensi.lua",LUA_MODIFIER_MOTION_NONE)
function passive_tensi02_attack:IsHidden() 			return true end
function passive_tensi02_attack:IsPurgable()		return false end
function passive_tensi02_attack:RemoveOnDeath() 	return false end
function passive_tensi02_attack:IsDebuff()			return false end

function passive_tensi02_attack:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED
	}
end
function passive_tensi02_attack:OnAttackLanded(keys)
	local caster = self:GetCaster()
	local target = keys.target
	if caster ~= keys.attacker then return end
	if caster:PassivesDisabled() then return end
	if not caster:IsRealHero() then return end

	local ability = self:GetAbility()
	local telent_chance = ability:GetSpecialValueFor("telent_chance")
	local should_attack = false
	local should_recool = false
	if telent_chance ~= 0 and RollPercentage(telent_chance) then
		should_attack = true
	elseif ability:IsCooldownReady() then
		should_attack = true
		should_recool = true
	end

	if should_attack == true then
		local telentdamage = FindTelentValue(caster,"special_bonus_unique_tensi_1") * caster:GetStrength()
		local damage = ability:GetSpecialValueFor("bouns_damage") + telentdamage
		local duration = ability:GetSpecialValueFor("stun_duration")
		local targets = FindUnitsInRadius(
			caster:GetTeam(),
			target:GetOrigin(),
			nil,
			ability:GetSpecialValueFor("stun_radius"),
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP + DOTA_UNIT_TARGET_OTHER,
			0,
			FIND_CLOSEST,
			false
		)
		if (#targets > 0) then
			for _,v in pairs(targets) do
				local damage_table = {
					ability = ability,
					victim = v,
					attacker = caster,
					damage = damage,
					damage_type = ability:GetAbilityDamageType(),
					damage_flags = 0
				}
				UtilStun:UnitStunTarget(caster,v,duration)
				UnitDamageTarget(damage_table)
			end

			if should_recool == true then
				ability:StartCooldown(ability:GetEffectiveCooldown(ability:GetLevel() - 1))
			end

			target:EmitSound("Hero_EarthShaker.Totem.Attack")

			local effectIndex = ParticleManager:CreateParticle("particles/econ/items/earthshaker/egteam_set/hero_earthshaker_egset/earthshaker_echoslam_start_fallback_low_egset.vpcf", PATTACH_CUSTOMORIGIN, caster)
			ParticleManager:SetParticleControl(effectIndex, 0, target:GetOrigin())
			ParticleManager:SetParticleControl(effectIndex, 1, target:GetOrigin())
			ParticleManager:DestroyParticleSystem(effectIndex,false)
		end
	end
end

function OnTensi03Passive(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	if caster:PassivesDisabled() then return end
	caster:Heal(keys.BounsHealth, caster)
	caster:GiveMana(keys.BounsMana)
	if caster:HasModifier("active_tensi03_attacked") then
		caster:Heal(keys.BounsHealth, caster)
	end
end

function OnTensi03SpellStart(keys)
	local caster=keys.caster
	local MaxStackCount = keys.MaxStackCount
	
	if caster:HasModifier("modifier_tensi03_bonus_attackspeed")~=true then
		caster.ModifierCount = 0
	end
	if caster.ModifierCount >= MaxStackCount then
		caster.ModifierCount = MaxStackCount
	else
		caster.ModifierCount = caster.ModifierCount+1
	end
	keys.ability:ApplyDataDrivenModifier(caster,caster,"modifier_tensi03_bonus_attackspeed",{})
	caster:SetModifierStackCount("modifier_tensi03_bonus_attackspeed",keys.ability,caster.ModifierCount)
	
end

function Tensiwanbaochuicheck(keys)
	local caster = keys.caster
	local casterName = caster:GetClassname()
	local abilityEx=nil
	if casterName == "npc_dota_hero_earthshaker" and caster:HasModifier("modifier_item_wanbaochui") then
		abilityEx = caster:FindAbilityByName("ability_thdots_tensiex")
		abilityEx:SetLevel(1)
	else
		abilityEx = caster:FindAbilityByName("ability_thdots_tensiex")
		abilityEx:SetLevel(0)
	end
end


function Tensiwanbaochuibuff(keys)
	local ability=keys.ability
	local caster=keys.caster
	local target=keys.target
	if is_spell_blocked(target,caster) then return end
	target:EmitSound("DOTA_Item.HeavensHalberd.Activate")
	if(caster:GetTeam() == keys.target:GetTeam())then
		keys.ability:ApplyDataDrivenModifier(caster, keys.target, "modifier_tensi_wanbaochui_buff", {})
		keys.ability:ApplyDataDrivenModifier(caster, keys.target, "modifier_tensi_wanbaochui_buff_2", {})
	else
		if is_spell_blocked(keys.target) then return end
		keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_tensi_wanbaochui_buff", {}) 
	end
end