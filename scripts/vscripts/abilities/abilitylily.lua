

function THDDealdamageMsgPoison(damagetable)
	local thdfinaldamage = UnitDamageTarget(damagetable)
	if IsValidEntity(damagetable.victim) and damagetable.victim and damagetable.victim:IsNull() == false then
		SendOverheadEventMessage(nil,OVERHEAD_ALERT_BONUS_POISON_DAMAGE,damagetable.victim,thdfinaldamage, nil)
	end
end

function THDHealTargetLily(caster,target,healamount)
	if caster:GetName() == "npc_dota_hero_leshrac" and caster:FindAbilityByName("special_bonus_unique_lily_1"):GetLevel() > 0  then
		healamount = healamount * (1 + FindTelentValue(caster, "special_bonus_unique_lily_1")/100)
	end
	target:Heal(healamount,caster)
	SendOverheadEventMessage(nil,OVERHEAD_ALERT_HEAL,target,healamount,nil)
end

ability_thdots_lily05 = {}

function ability_thdots_lily05:OnToggle()
	local caster = self:GetCaster()
	if caster.caster_model == nil then
		caster.caster_model = caster:GetModelName()
	end
	if self:GetToggleState() == false then
		local modelWhite = "models/new_thd/lily/lilywhite.vmdl"
		self:StartCooldown(self:GetCooldown(self:GetLevel() - 1))
		caster:SetModel(modelWhite)
		caster:SetOriginalModel(modelWhite)
		caster:RemoveModifierByName("modifier_lily_black")
	else
		local modelBlack = "models/new_thd/lily/lilyblack.vmdl"
		self:StartCooldown(self:GetCooldown(self:GetLevel() - 1))
		caster:SetModel(modelBlack)
		caster:SetOriginalModel(modelBlack)
		caster:AddNewModifier(caster, self, "modifier_lily_black", {})
	end
end

function ability_thdots_lily05:GetIntrinsicModifierName() return "modifier_lily_black_check" end

modifier_lily_black = {}
LinkLuaModifier("modifier_lily_black", "scripts/vscripts/abilities/abilitylily.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_lily_black:IsHidden() 		return false end
function modifier_lily_black:IsPurgable()		return false end
function modifier_lily_black:RemoveOnDeath() 	return false end
function modifier_lily_black:IsDebuff()			return false end

modifier_lily_black_check = {}
LinkLuaModifier("modifier_lily_black_check", "scripts/vscripts/abilities/abilitylily.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_lily_black_check:IsHidden() 		return true end
function modifier_lily_black_check:IsPurgable()		return false end
function modifier_lily_black_check:RemoveOnDeath() 	return false end
function modifier_lily_black_check:IsDebuff()		return false end

function modifier_lily_black_check:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.1)
end

function modifier_lily_black_check:OnRefresh()
	if not IsServer() then return end
	self:StartIntervalThink(0.1)
end

function modifier_lily_black_check:OnIntervalThink()
	if not IsServer() then return end
	local ability = self:GetAbility()
	ability:SetActivated(ability:IsCooldownReady())
end

ability_thdots_lily01 = {}

function ability_thdots_lily01:GetManaCost()
	if self:GetCaster():HasModifier("modifier_lily_black") == false then
		return self:GetSpecialValueFor("spell_cost")
	else
		return 0
	end
end

function ability_thdots_lily01:CastFilterResultTarget( hTarget )
	if not IsServer() then return end
	local caster = self:GetCaster()
	if hTarget:IsBuilding() then return UF_FAIL_OTHER end
	if caster:HasModifier("modifier_lily_black") then
		if caster:GetTeam() == hTarget:GetTeam() and hTarget ~= caster and hTarget:GetHealthPercent() > 30 then
			return UF_FAIL_FRIENDLY
		end
	else
		if caster:GetTeam() ~= hTarget:GetTeam() then
			return UF_FAIL_ENEMY
		end
	end
	return UF_SUCCESS
end

function ability_thdots_lily01:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local spell_cost = self:GetSpecialValueFor("spell_cost")
	local spell_duration = self:GetSpecialValueFor("duration")

	if is_spell_blocked(target, caster) then return end
	if caster:HasModifier("modifier_lily_black") == false then
		target:EmitSound("lily01healcast")
		target:AddNewModifier(caster, self, "modifier_lily01buff", {duration = spell_duration} )
	else
		caster:ModifyHealth(caster:GetHealth()-spell_cost,self,false,0)
		target:EmitSound("lily01cursecast")
		target:AddNewModifier(caster, self, "modifier_lily01debuff", {duration = spell_duration} )
	end
end

function ability_thdots_lily01:GetIntrinsicModifierName()
	return "modifier_lily01_cost_check"
end

modifier_lily01_cost_check = {}
LinkLuaModifier( "modifier_lily01_cost_check", "scripts/vscripts/abilities/abilitylily.lua", LUA_MODIFIER_MOTION_NONE )
function modifier_lily01_cost_check:IsHidden() 			return true end
function modifier_lily01_cost_check:IsPurgable()		return false end
function modifier_lily01_cost_check:RemoveOnDeath() 	return false end
function modifier_lily01_cost_check:IsDebuff()			return false end

function modifier_lily01_cost_check:OnCreated(keys)
	if not IsServer() then return end
	self:StartIntervalThink(0.01)
end

function modifier_lily01_cost_check:OnIntervalThink( keys )
	if not IsServer() then return end
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local spell_cost = ability:GetSpecialValueFor("spell_cost")
	if caster:HasModifier("modifier_lily_black") then
		if caster:GetHealth() < spell_cost then
			ability:SetActivated(false)
		else
			ability:SetActivated(true)
		end
	else
		ability:SetActivated(true)
	end
end

modifier_lily01buff = {}
LinkLuaModifier( "modifier_lily01buff","scripts/vscripts/abilities/abilitylily.lua", LUA_MODIFIER_MOTION_NONE )
function modifier_lily01buff:IsHidden()			return false end
function modifier_lily01buff:IsPurgable()		return true end
function modifier_lily01buff:RemoveOnDeath()	return true end
function modifier_lily01buff:IsDebuff()			return false end
function modifier_lily01buff:GetEffectName()
	return "particles/units/heroes/hero_warlock/warlock_shadow_word_buff.vpcf"
end
function modifier_lily01buff:GetEffectAttachType()
	return "PATTACH_ABSORIGIN_FOLLOW"
end

function modifier_lily01buff:OnCreated(keys)
	if not IsServer() then return end
	self:StartThinking()
end

function modifier_lily01buff:OnRefresh(keys)
	if not IsServer() then return end
	self:StartThinking()
end

function modifier_lily01buff:StartThinking()
	local ability = self:GetAbility()
	self.tickrate = ability:GetSpecialValueFor("tick_rate")
	local base_tick_effect =  ability:GetSpecialValueFor("healanddamage")
	local bonus_tick_effect = ability:GetSpecialValueFor("statscale")
	self.tickeffects = base_tick_effect + (self:GetCaster():GetIntellect(false)*bonus_tick_effect)
	self:StartIntervalThink(self.tickrate)
end

function modifier_lily01buff:OnIntervalThink( keys )
	if not IsServer() then return end
	self:GetParent():EmitSound("lily01heal")
	THDHealTargetLily(self:GetCaster(), self:GetParent(), self.tickeffects)
end

modifier_lily01debuff = {}
LinkLuaModifier( "modifier_lily01debuff","scripts/vscripts/abilities/abilitylily.lua", LUA_MODIFIER_MOTION_NONE )
function modifier_lily01debuff:IsHidden()		return false end
function modifier_lily01debuff:IsPurgable()		return true end
function modifier_lily01debuff:RemoveOnDeath()	return true end
function modifier_lily01debuff:IsDebuff()		return true end
function modifier_lily01debuff:GetEffectName()
	return "particles/econ/items/witch_doctor/wd_ti8_immortal_head/wd_ti8_immortal_maledict.vpcf"
end
function modifier_lily01debuff:GetEffectAttachType()
	return "PATTACH_ABSORIGIN_FOLLOW"
end

function modifier_lily01debuff:OnCreated(keys)
	if not IsServer() then return end
	self:StartThinking()
end

function modifier_lily01debuff:OnRefresh(keys)
	if not IsServer() then return end
	self:StartThinking()
end

function modifier_lily01debuff:StartThinking()
	local ability = self:GetAbility()
	self.tickrate = ability:GetSpecialValueFor("tick_rate")
	local base_tick_effect =  ability:GetSpecialValueFor("healanddamage")
	local bonus_tick_effect = ability:GetSpecialValueFor("statscale")
	self.tickeffects = base_tick_effect + (self:GetCaster():GetIntellect(false)*bonus_tick_effect)
	self:StartIntervalThink(self.tickrate)
end

function modifier_lily01debuff:OnIntervalThink( keys )
	if not IsServer() then return end
	self:GetParent():EmitSound("lily01heal")
	local ability = self:GetAbility()
	local damage_table = {
			ability = ability,
			victim = self:GetParent(),
			attacker = self:GetCaster(),
			damage = self.tickeffects,
			damage_type = ability:GetAbilityDamageType(),
			damage_flags = 0
	}
	THDDealdamageMsgPoison(damage_table)
end

ability_thdots_lily02 = {}

function ability_thdots_lily02:GetManaCost()
	if self:GetCaster():HasModifier("modifier_lily_black") == false then
		return self:GetSpecialValueFor("spell_cost")
	else
		return 0
	end
end

function ability_thdots_lily02:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local target = self:GetCursorTarget()
	local spellcost = self:GetSpecialValueFor("spell_cost")
	local maxheal = target:GetMaxHealth()
	local duration = self:GetSpecialValueFor("duration")

	if caster:HasModifier("modifier_lily_black") == false then
		THDHealTargetLily(caster,target,maxheal)
		target:AddNewModifier(caster, self, "modifier_lily02buff", {duration = duration})
	else
		local enemies = FindUnitsInRadius(
			caster:GetTeam(),
			target:GetAbsOrigin(),
			nil,
			self:GetSpecialValueFor("radius"),
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
			DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
			FIND_ANY_ORDER,
			false)
		for _,v in pairs(enemies) do
			v:AddNewModifier(caster, self, "modifier_lily02debuff_penalty", {duration = duration})
		end

		if target:GetUnitName() == "ability_minamitsu_04_ship"
		or target:GetUnitName() == "ability_margatroid03_doll"
		or target:GetUnitName() == "npc_dota_mutation_pocket_roshan"
		or target:GetUnitName() == "npc_dota_roshan" then
			return
		end
		target:Kill(caster, caster)

		local damage_table = {
			ability = self,
			victim = caster,
			attacker = caster,
			damage = spellcost,
			damage_type = DAMAGE_TYPE_PURE,
			damage_flags = 0
		}
		UnitDamageTarget(damage_table)
	end
end

function ability_thdots_lily02:GetIntrinsicModifierName()
	return "modifier_lily02_cost_check"
end

modifier_lily02_cost_check = {}
LinkLuaModifier( "modifier_lily02_cost_check","scripts/vscripts/abilities/abilitylily.lua", LUA_MODIFIER_MOTION_NONE )
function modifier_lily02_cost_check:IsHidden() 		return true end
function modifier_lily02_cost_check:IsPurgable()		return false end
function modifier_lily02_cost_check:RemoveOnDeath() 	return false end
function modifier_lily02_cost_check:IsDebuff()		return false end

function modifier_lily02_cost_check:OnCreated(keys)
	if not IsServer() then return end
	self:StartIntervalThink(0.01)
end

function modifier_lily02_cost_check:OnIntervalThink( keys )
	if not IsServer() then return end
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local spell_cost = ability:GetSpecialValueFor("spell_cost")
	if caster:HasModifier("modifier_lily_black") then
		if caster:GetHealth() < spell_cost then
			ability:SetActivated(false)
		else
			ability:SetActivated(true)
		end
	else
		ability:SetActivated(true)
	end
end

modifier_lily02buff = {}
LinkLuaModifier("modifier_lily02buff", "scripts/vscripts/abilities/abilitylily.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_lily02buff:IsHidden() 		return true end
function modifier_lily02buff:IsPurgable()		return false end
function modifier_lily02buff:RemoveOnDeath() 	return false end
function modifier_lily02buff:IsDebuff()			return false end

function modifier_lily02buff:IsAura()	return true end
function modifier_lily02buff:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("radius") end
function modifier_lily02buff:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ALLIES end
function modifier_lily02buff:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_lily02buff:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_lily02buff:GetModifierAura() return "modifier_lily02buff_attack" end

modifier_lily02buff_attack = {}
LinkLuaModifier("modifier_lily02buff_attack", "scripts/vscripts/abilities/abilitylily.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_lily02buff_attack:IsHidden() 			return false end
function modifier_lily02buff_attack:IsPurgable()		return false end
function modifier_lily02buff_attack:RemoveOnDeath() 	return false end
function modifier_lily02buff_attack:IsDebuff()			return false end
function modifier_lily02buff_attack:GetEffectName()
	return "particles/econ/items/ogre_magi/ogre_ti8_immortal_weapon/ogre_ti8_immortal_bloodlust_buff.vpcf"
end
function modifier_lily02buff_attack:GetEffectAttachType()
	return "PATTACH_POINT"
end
function modifier_lily02buff_attack:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
	}
end
function modifier_lily02buff_attack:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("buffatk")
end

modifier_lily02debuff_penalty = {}
LinkLuaModifier("modifier_lily02debuff_penalty", "scripts/vscripts/abilities/abilitylily.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_lily02debuff_penalty:IsHidden() 			return false end
function modifier_lily02debuff_penalty:IsPurgable()			return false end
function modifier_lily02debuff_penalty:RemoveOnDeath() 		return false end
function modifier_lily02debuff_penalty:IsDebuff()			return false end
function modifier_lily02debuff_penalty:GetEffectName()
	return "particles/units/heroes/hero_dark_willow/dark_willow_wisp_spell_debuff.vpcf"
end
function modifier_lily02debuff_penalty:GetEffectAttachType()
	return "PATTACH_OVERHEAD_FOLLOW"
end
function modifier_lily02debuff_penalty:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
	}
end
function modifier_lily02debuff_penalty:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("debuffatk")
end

ability_thdots_lily03 = {}

function ability_thdots_lily03:GetAOERadius() return self:GetSpecialValueFor("radius") end

function ability_thdots_lily03:GetManaCost()
	if self:GetCaster():HasModifier("modifier_lily_black") == false then
		return self:GetSpecialValueFor("spell_cost")
	else
		return 0
	end
end

function ability_thdots_lily03:OnSpellStart()
	local caster = self:GetCaster()
	local spellcost = self:GetSpecialValueFor("spell_cost")
	local targetpoint = self:GetCursorPosition()
	local radius = self:GetSpecialValueFor("radius")
	local duration = self:GetSpecialValueFor("duration")

	if caster:HasModifier("modifier_lily_black") == false then
		CreateModifierThinker(
			caster,
			self,
			"modifier_lily_white03_area",
			{duration = duration},
			targetpoint,
			caster:GetTeamNumber(),
			false
		)
	else
		CreateModifierThinker(
			caster,
			self,
			"modifier_lily_black03_area",
			{duration = duration},
			targetpoint,
			caster:GetTeamNumber(),
			false
		)

		local damage_table = {
				ability = self,
			    victim = caster,
			    attacker = caster,
			    damage = spellcost,
			    damage_type = DAMAGE_TYPE_PURE,
	    	    damage_flags = 0
		}
		UnitDamageTarget(damage_table)
	end
end

function ability_thdots_lily03:GetIntrinsicModifierName()
	return "modifier_lily03_cost_check"
end

modifier_lily03_cost_check = {}
LinkLuaModifier( "modifier_lily03_cost_check","scripts/vscripts/abilities/abilitylily.lua", LUA_MODIFIER_MOTION_NONE )
function modifier_lily03_cost_check:IsHidden() 		return true end
function modifier_lily03_cost_check:IsPurgable()		return false end
function modifier_lily03_cost_check:RemoveOnDeath() 	return false end
function modifier_lily03_cost_check:IsDebuff()		return false end

function modifier_lily03_cost_check:OnCreated(keys)
	if not IsServer() then return end
	self:StartIntervalThink(0.01)
end

function modifier_lily03_cost_check:OnIntervalThink( keys )
	if not IsServer() then return end
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local spell_cost = ability:GetSpecialValueFor("spell_cost")
	if caster:HasModifier("modifier_lily_black") then
		if caster:GetHealth() < spell_cost then
			ability:SetActivated(false)
		else
			ability:SetActivated(true)
		end
	else
		ability:SetActivated(true)
	end
end

modifier_lily_white03_area = {}
LinkLuaModifier( "modifier_lily_white03_area","scripts/vscripts/abilities/abilitylily.lua", LUA_MODIFIER_MOTION_NONE )
function modifier_lily_white03_area:IsHidden() 			return false end
function modifier_lily_white03_area:IsPurgable()		return false end
function modifier_lily_white03_area:RemoveOnDeath() 	return false end
function modifier_lily_white03_area:IsDebuff()			return false end

function modifier_lily_white03_area:IsAura()				return true end
function modifier_lily_white03_area:GetAuraRadius()			return self:GetAbility():GetSpecialValueFor("radius") end
function modifier_lily_white03_area:GetAuraSearchFlags()	return DOTA_UNIT_TARGET_FLAG_NONE end
function modifier_lily_white03_area:GetAuraSearchTeam()		return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_lily_white03_area:GetAuraSearchType()		return DOTA_UNIT_TARGET_HERO end
function modifier_lily_white03_area:GetModifierAura()		return "modifier_lily_white03_area_buff" end

function modifier_lily_white03_area:GetEffectName()
	return "maps/journey_assets/particles/journey_fountain_radiant.vpcf"
end
function modifier_lily_white03_area:GetEffectAttachType()
	return "PATTACH_ABSORIGIN_FOLLOW"
end

function modifier_lily_white03_area:OnCreated()
	if not IsServer() then return end
	local parent = self:GetParent()
	local radius = self:GetAbility():GetSpecialValueFor("radius")
	local effectIndex = ParticleManager:CreateParticle("particles/heroes/lily/ability_lily_01.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:SetParticleControl(effectIndex, 0, Vector(0, 0, 0))
	ParticleManager:SetParticleControl(effectIndex, 1, Vector(radius, radius, radius))
	ParticleManager:DestroyParticle(effectIndex, false)
	parent:EmitSound("Hero_Enigma.Midnight_Pulse")

	GridNav:DestroyTreesAroundPoint(parent:GetAbsOrigin(), radius, false)

	self:StartIntervalThink(1)
end

function modifier_lily_white03_area:OnIntervalThink()
	if not IsServer() then return end
	local parent = self:GetParent()
	local radius = self:GetAbility():GetSpecialValueFor("radius")
	local effectIndex = ParticleManager:CreateParticle("particles/heroes/lily/ability_lily_01.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:SetParticleControl(effectIndex, 0, Vector(0, 0, 0))
	ParticleManager:SetParticleControl(effectIndex, 1, Vector(radius, radius, radius))
	ParticleManager:DestroyParticle(effectIndex, false)
	parent:EmitSound("lily03heal")
end

modifier_lily_white03_area_buff = {}
LinkLuaModifier( "modifier_lily_white03_area_buff","scripts/vscripts/abilities/abilitylily.lua", LUA_MODIFIER_MOTION_NONE )
function modifier_lily_white03_area_buff:IsHidden() 			return false end
function modifier_lily_white03_area_buff:IsPurgable()		return false end
function modifier_lily_white03_area_buff:RemoveOnDeath() 	return true end
function modifier_lily_white03_area_buff:IsDebuff()			return false end

function modifier_lily_white03_area_buff:OnCreated(keys)
	if not IsServer() then return end
	self:StartIntervalThink(1)
end

function modifier_lily_white03_area_buff:OnIntervalThink()
	local ability = self:GetAbility()
	local caster = self:GetCaster()
	local target = self:GetParent()
	local baseheal = ability:GetSpecialValueFor("healanddamage")
	local statscale = ability:GetSpecialValueFor("statscale") * caster:GetIntellect(false)
	local healingdone = baseheal + statscale

	target:EmitSound("lily03heal")

	THDHealTargetLily(caster, target, healingdone)

	if target:HasModifier("modifier_lily_white03_immunity_check") == true and not target:HasModifier("modifier_lily_white03_immunity") then
		local stackcount = target:GetModifierStackCount("modifier_lily_white03_immunity_check", caster)
		target:SetModifierStackCount("modifier_lily_white03_immunity_check", ability, stackcount+1)
	end

	if target:HasModifier("modifier_lily_white03_immunity_check") == false then
		target:AddNewModifier(caster, ability, "modifier_lily_white03_immunity_check", {duration = ability:GetSpecialValueFor("duration")})
		target:SetModifierStackCount("modifier_lily_white03_immunity_check", ability, 1)
	end

	if target:HasModifier("modifier_lily_white03_immunity_check") == true and target:GetModifierStackCount("modifier_lily_white03_immunity_check", caster) >= 3 then
		target:AddNewModifier(caster, ability, "modifier_lily_white03_immunity", {duration = ability:GetSpecialValueFor("immune_duration")})
		target:RemoveModifierByName("modifier_lily_white03_immunity_check")
	end
end

modifier_lily_white03_immunity_check = {}
LinkLuaModifier( "modifier_lily_white03_immunity_check","scripts/vscripts/abilities/abilitylily.lua", LUA_MODIFIER_MOTION_NONE )
function modifier_lily_white03_immunity_check:IsHidden() 		return true end
function modifier_lily_white03_immunity_check:IsPurgable()		return false end
function modifier_lily_white03_immunity_check:RemoveOnDeath() 	return true end
function modifier_lily_white03_immunity_check:IsDebuff()		return false end

modifier_lily_white03_immunity = {}
LinkLuaModifier( "modifier_lily_white03_immunity","scripts/vscripts/abilities/abilitylily.lua", LUA_MODIFIER_MOTION_NONE )
function modifier_lily_white03_immunity:IsHidden() 			return false end
function modifier_lily_white03_immunity:IsPurgable()		return false end
function modifier_lily_white03_immunity:RemoveOnDeath() 	return true end
function modifier_lily_white03_immunity:IsDebuff()			return false end
function modifier_lily_white03_immunity:GetEffectName()
	return "particles/units/heroes/hero_omniknight/omniknight_repel_buff.vpcf"
end
function modifier_lily_white03_immunity:GetEffectAttachType()
	return "PATTACH_ABSORIGIN_FOLLOW"
end

function modifier_lily_white03_immunity:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE
	}
end
function modifier_lily_white03_immunity:GetAbsoluteNoDamageMagical(keys) return 1 end
function modifier_lily_white03_immunity:GetAbsoluteNoDamagePure(keys) return 1 end

modifier_lily_black03_area = {}
LinkLuaModifier( "modifier_lily_black03_area","scripts/vscripts/abilities/abilitylily.lua", LUA_MODIFIER_MOTION_NONE )
function modifier_lily_black03_area:IsHidden() 			return false end
function modifier_lily_black03_area:IsPurgable()		return false end
function modifier_lily_black03_area:RemoveOnDeath() 	return false end
function modifier_lily_black03_area:IsDebuff()			return false end

function modifier_lily_black03_area:IsAura()				return true end
function modifier_lily_black03_area:GetAuraRadius()			return self:GetAbility():GetSpecialValueFor("radius") end
function modifier_lily_black03_area:GetAuraSearchFlags()	return DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES end
function modifier_lily_black03_area:GetAuraSearchTeam()		return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_lily_black03_area:GetAuraSearchType()		return DOTA_UNIT_TARGET_HERO end
function modifier_lily_black03_area:GetModifierAura()		return "modifier_lily_black03_area_debuff" end

function modifier_lily_black03_area:GetEffectName()
	return "maps/journey_assets/particles/journey_fountain_radiant.vpcf"
end
function modifier_lily_black03_area:GetEffectAttachType()
	return "PATTACH_ABSORIGIN_FOLLOW"
end

function modifier_lily_black03_area:OnCreated()
	if not IsServer() then return end
	local parent = self:GetParent()
	local radius = self:GetAbility():GetSpecialValueFor("radius")
	self.effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_enigma/enigma_midnight_pulse.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:SetParticleControl(self.effectIndex, 0, Vector(0, 0, 0))
	ParticleManager:SetParticleControl(self.effectIndex, 1, Vector(radius, radius, radius))
	parent:EmitSound("Hero_Enigma.Midnight_Pulse")

	GridNav:DestroyTreesAroundPoint(parent:GetAbsOrigin(), radius, false)
end

function modifier_lily_black03_area:OnDestroy()
	if not IsServer() then return end
	ParticleManager:DestroyParticle(self.effectIndex, false)
end

modifier_lily_black03_area_debuff = {}
LinkLuaModifier( "modifier_lily_black03_area_debuff","scripts/vscripts/abilities/abilitylily.lua", LUA_MODIFIER_MOTION_NONE )
function modifier_lily_black03_area_debuff:IsHidden() 		return false end
function modifier_lily_black03_area_debuff:IsPurgable()		return false end
function modifier_lily_black03_area_debuff:RemoveOnDeath() 	return true end
function modifier_lily_black03_area_debuff:IsDebuff()		return true end

function modifier_lily_black03_area_debuff:OnCreated(keys)
	if not IsServer() then return end
	self:StartIntervalThink(1)
end

function modifier_lily_black03_area_debuff:OnIntervalThink()
	local ability = self:GetAbility()
	local caster = self:GetCaster()
	local target = self:GetParent()
	local basedmg = ability:GetSpecialValueFor("healanddamage")
	local statscale = ability:GetSpecialValueFor("statscale") * caster:GetIntellect(false)
	local dmgdone = basedmg + statscale

	target:EmitSound("lily03damage")

	local damage_table = {
			ability = ability,
			victim = target,
			attacker = caster,
			damage = dmgdone,
			damage_type = DAMAGE_TYPE_MAGICAL,
			damage_flags = 0
	}
	THDDealdamageMsgPoison(damage_table)

	if target:HasModifier("modifier_lily_black03_stun_check") == true and not target:HasModifier("modifier_lily_black03_stun") then
		local stackcount = target:GetModifierStackCount("modifier_lily_black03_stun_check", caster)
		target:SetModifierStackCount("modifier_lily_black03_stun_check", ability, stackcount+1)
	end

	if target:HasModifier("modifier_lily_black03_stun_check") == false then
		target:AddNewModifier(caster, ability, "modifier_lily_black03_stun_check", {duration = ability:GetSpecialValueFor("duration")})
		target:SetModifierStackCount("modifier_lily_black03_stun_check", ability, 1)
	end

	if target:HasModifier("modifier_lily_black03_stun_check") == true and target:GetModifierStackCount("modifier_lily_black03_stun_check", caster) >= 3 then
		target:AddNewModifier(caster, ability, "modifier_lily_black03_stun", {duration = ability:GetSpecialValueFor("stun_duration")})
		target:RemoveModifierByName("modifier_lily_black03_stun_check")
	end
end

modifier_lily_black03_stun_check = {}
LinkLuaModifier( "modifier_lily_black03_stun_check","scripts/vscripts/abilities/abilitylily.lua", LUA_MODIFIER_MOTION_NONE )
function modifier_lily_black03_stun_check:IsHidden() 		return true end
function modifier_lily_black03_stun_check:IsPurgable()		return false end
function modifier_lily_black03_stun_check:RemoveOnDeath() 	return true end
function modifier_lily_black03_stun_check:IsDebuff()		return true end

modifier_lily_black03_stun = {}
LinkLuaModifier( "modifier_lily_black03_stun","scripts/vscripts/abilities/abilitylily.lua", LUA_MODIFIER_MOTION_NONE )
function modifier_lily_black03_stun:IsHidden() 			return false end
function modifier_lily_black03_stun:IsPurgable()		return true end
function modifier_lily_black03_stun:RemoveOnDeath() 	return true end
function modifier_lily_black03_stun:IsDebuff()			return true end
function modifier_lily_black03_stun:GetEffectName()
	return "particles/generic_gameplay/generic_stunned.vpcf"
end
function modifier_lily_black03_stun:GetEffectAttachType()
	return "PATTACH_ABSORIGIN_FOLLOW"
end

function modifier_lily_black03_stun:DeclareFunctions()
	return {
		MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
	}
end

function modifier_lily_black03_stun:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true
	}
end

function modifier_lily_black03_stun:OnCreated()
	if not IsServer() then return end
	self:GetParent():EmitSound("Hero_Omniknight.Repel")
end

ability_thdots_lily04 = {}

function ability_thdots_lily04:GetAOERadius() return self:GetSpecialValueFor("radius") end

function ability_thdots_lily04:GetManaCost()
	if self:GetCaster():HasModifier("modifier_lily_black") == false then
		return self:GetSpecialValueFor("spell_cost")
	else
		return 0
	end
end

function ability_thdots_lily04:OnSpellStart()
	local caster = self:GetCaster()
	local spellcost = self:GetSpecialValueFor("spell_cost")
	local targetpoint = self:GetCursorPosition()
	local radius = self:GetSpecialValueFor("radius")
	local duration = self:GetSpecialValueFor("duration")

	local thinker = nil
	if caster:HasModifier("modifier_lily_black") == false then
		thinker = CreateModifierThinker(
			caster,
			self,
			"modifier_lily_white04_area",
			{duration = duration},
			targetpoint,
			caster:GetTeamNumber(),
			false
		)
	else
		thinker = CreateModifierThinker(
			caster,
			self,
			"modifier_lily_black04_area",
			{duration = duration},
			targetpoint,
			caster:GetTeamNumber(),
			false
		)

		local damage_table = {
				ability = self,
			    victim = caster,
			    attacker = caster,
			    damage = spellcost,
			    damage_type = DAMAGE_TYPE_PURE,
	    	    damage_flags = 0
		}
		UnitDamageTarget(damage_table)
	end

	local selfAuraBorderFx = ParticleManager:CreateParticleForTeam("particles/heroes/lily/04ring.vpcf", PATTACH_ABSORIGIN_FOLLOW, thinker, 2)
    ParticleManager:SetParticleControl(selfAuraBorderFx, 0, Vector(radius,0,0))
    ParticleManager:SetParticleControl(selfAuraBorderFx, 1, Vector(radius,0,0))

	local selfAuraBorderFx2 = ParticleManager:CreateParticleForTeam("particles/heroes/lily/04ring.vpcf", PATTACH_ABSORIGIN_FOLLOW, thinker, 3)
    ParticleManager:SetParticleControl(selfAuraBorderFx2, 0, Vector(radius,0,0))
    ParticleManager:SetParticleControl(selfAuraBorderFx2, 1, Vector(radius,0,0))
end

modifier_lily04_cost_check = {}
LinkLuaModifier("modifier_lily04_cost_check","scripts/vscripts/abilities/abilitylily.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_lily04_cost_check:IsHidden() 		return true end
function modifier_lily04_cost_check:IsPurgable()		return false end
function modifier_lily04_cost_check:RemoveOnDeath() 	return false end
function modifier_lily04_cost_check:IsDebuff()		return false end

function modifier_lily04_cost_check:OnCreated(keys)
	if not IsServer() then return end
	self:StartIntervalThink(0.01)
end

function modifier_lily04_cost_check:OnIntervalThink( keys )
	if not IsServer() then return end
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local spell_cost = ability:GetSpecialValueFor("spell_cost")
	if caster:HasModifier("modifier_lily_black") then
		if caster:GetHealth() < spell_cost then
			ability:SetActivated(false)
		else
			ability:SetActivated(true)
		end
	else
		ability:SetActivated(true)
	end
end

modifier_lily_white04_area = {}
LinkLuaModifier("modifier_lily_white04_area","scripts/vscripts/abilities/abilitylily.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_lily_white04_area:IsHidden() 			return false end
function modifier_lily_white04_area:IsPurgable()		return false end
function modifier_lily_white04_area:RemoveOnDeath() 	return false end
function modifier_lily_white04_area:IsDebuff()			return false end

function modifier_lily_white04_area:IsAura()				return true end
function modifier_lily_white04_area:GetAuraRadius()			return self:GetAbility():GetSpecialValueFor("radius") end
function modifier_lily_white04_area:GetAuraSearchFlags()	return DOTA_UNIT_TARGET_FLAG_NONE end
function modifier_lily_white04_area:GetAuraSearchTeam()		return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_lily_white04_area:GetAuraSearchType()		return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP end
function modifier_lily_white04_area:GetModifierAura()		return "modifier_lily_white04_area_buff" end

function modifier_lily_white04_area:OnCreated()
	if not IsServer() then return end
	local parent = self:GetParent()
	local radius = self:GetAbility():GetSpecialValueFor("radius")
	self.effectIndex = ParticleManager:CreateParticle("particles/heroes/thtd_patchouli/ability_patchouli_01_bury_in_lake.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:SetParticleControl(self.effectIndex, 0, Vector(0, 0, 0))
	ParticleManager:SetParticleControl(self.effectIndex, 1, Vector(radius, radius, radius))
	parent:EmitSound("lily04heal")

	GridNav:DestroyTreesAroundPoint(parent:GetAbsOrigin(), radius, false)

	self:StartIntervalThink(2)
end

function modifier_lily_white04_area:OnIntervalThink()
	if not IsServer() then return end
	local parent = self:GetParent()
	local radius = self:GetAbility():GetSpecialValueFor("radius")
	local effectIndex = ParticleManager:CreateParticle("particles/thd2/heroes/eirin/ability_eirin02_heal.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:SetParticleControl(effectIndex, 0, Vector(0, 0, 0))
	ParticleManager:SetParticleControl(effectIndex, 1, Vector(radius, radius, radius))
	ParticleManager:DestroyParticle(effectIndex, false)
end

function modifier_lily_white04_area:OnDestroy()
	if not IsServer() then return end
	self:GetParent():StopSound("lily04heal")
	ParticleManager:DestroyParticle(self.effectIndex, false)
end

modifier_lily_white04_area_buff = {}
LinkLuaModifier( "modifier_lily_white04_area_buff","scripts/vscripts/abilities/abilitylily.lua", LUA_MODIFIER_MOTION_NONE )
function modifier_lily_white04_area_buff:IsHidden() 			return false end
function modifier_lily_white04_area_buff:IsPurgable()		return false end
function modifier_lily_white04_area_buff:RemoveOnDeath() 	return true end
function modifier_lily_white04_area_buff:IsDebuff()			return false end
function modifier_lily_white04_area_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
	}
end
function modifier_lily_white04_area_buff:GetModifierIncomingDamage_Percentage()
	return self:GetAbility():GetSpecialValueFor("bonus_reduction")
end

function modifier_lily_white04_area_buff:OnCreated(keys)
	if not IsServer() then return end
	self:StartIntervalThink(1)
end

function modifier_lily_white04_area_buff:OnIntervalThink()
	local caster = self:GetCaster()
	local target = self:GetParent()
	local ability = self:GetAbility()
	local baseheal = ability:GetSpecialValueFor("healanddamage")
	local statscale = ability:GetSpecialValueFor("statscale") * caster:GetIntellect(false)
	local healingdone = statscale+baseheal

	THDHealTargetLily(caster,target,healingdone)
end

modifier_lily_black04_area = {}
LinkLuaModifier("modifier_lily_black04_area","scripts/vscripts/abilities/abilitylily.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_lily_black04_area:IsHidden() 			return false end
function modifier_lily_black04_area:IsPurgable()		return false end
function modifier_lily_black04_area:RemoveOnDeath() 	return false end
function modifier_lily_black04_area:IsDebuff()			return false end

function modifier_lily_black04_area:IsAura()				return true end
function modifier_lily_black04_area:GetAuraRadius()			return self:GetAbility():GetSpecialValueFor("radius") end
function modifier_lily_black04_area:GetAuraSearchFlags()	return DOTA_UNIT_TARGET_FLAG_NONE end
function modifier_lily_black04_area:GetAuraSearchTeam()		return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_lily_black04_area:GetAuraSearchType()		return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP end
function modifier_lily_black04_area:GetModifierAura()		return "modifier_lily_black04_area_debuff" end

function modifier_lily_black04_area:OnCreated()
	if not IsServer() then return end
	local parent = self:GetParent()
	local radius = self:GetAbility():GetSpecialValueFor("radius")
	self.effectIndex = ParticleManager:CreateParticle("particles/heroes/thtd_patchouli/ability_patchouli_01_mercury_poison.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:SetParticleControl(self.effectIndex, 0, Vector(0, 0, 0))
	ParticleManager:SetParticleControl(self.effectIndex, 1, Vector(radius, radius, radius))
	parent:EmitSound("lily04damage")

	GridNav:DestroyTreesAroundPoint(parent:GetAbsOrigin(), radius, false)

	self:StartIntervalThink(2)
end

function modifier_lily_black04_area:OnDestroy()
	if not IsServer() then return end
	self:GetParent():StopSound("lily04damage")
	ParticleManager:DestroyParticle(self.effectIndex, false)
end

modifier_lily_black04_area_debuff = {}
LinkLuaModifier( "modifier_lily_black04_area_debuff","scripts/vscripts/abilities/abilitylily.lua", LUA_MODIFIER_MOTION_NONE )
function modifier_lily_black04_area_debuff:IsHidden() 			return false end
function modifier_lily_black04_area_debuff:IsPurgable()		return false end
function modifier_lily_black04_area_debuff:RemoveOnDeath() 	return true end
function modifier_lily_black04_area_debuff:IsDebuff()			return false end
function modifier_lily_black04_area_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
	}
end
function modifier_lily_black04_area_debuff:GetModifierIncomingDamage_Percentage()
	return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_lily_black04_area_debuff:OnCreated(keys)
	if not IsServer() then return end
	self:StartIntervalThink(1)
end

function modifier_lily_black04_area_debuff:OnIntervalThink()
	local caster = self:GetCaster()
	local target = self:GetParent()
	local ability = self:GetAbility()
	local basedamage = ability:GetSpecialValueFor("healanddamage")
	local statscale = ability:GetSpecialValueFor("statscale") * caster:GetIntellect(false)
	local dmgdone = statscale+basedamage

	local damage_table = {
		ability =ability,
		victim = target,
		attacker = caster,
		damage = dmgdone,
		damage_type = DAMAGE_TYPE_MAGICAL,
		damage_flags = 0
	}
	THDDealdamageMsgPoison(damage_table)
end