abilitylyrica = class({})

LYRICA_BONUS_COUNT = nil --天生击杀计数
LYRICA03TALENT_FLAG = 1 --给一次加25级天赋的次数

ability_thdots_lyrica01 = {}

function ability_thdots_lyrica01:GetCastRange(location, target)
	if IsServer() then return 0 end
	return self.BaseClass.GetCastRange(self, location, target)
end

function ability_thdots_lyrica01:GetAOERadius()
	return self:GetSpecialValueFor("heal_radius")
end

function ability_thdots_lyrica01:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local targetPoint = self:GetCursorPosition()
	local vecCaster = caster:GetOrigin()
	local maxRange = self:GetSpecialValueFor("cast_range") + caster:GetCastRangeBonus()
	local pointRad = GetRadBetweenTwoVec2D(vecCaster,targetPoint)

	if(GetDistanceBetweenTwoVec2D(vecCaster,targetPoint)<=maxRange)then
		FindClearSpaceForUnit(caster,targetPoint,true)
	else
		local blinkVector = Vector(math.cos(pointRad)*maxRange,math.sin(pointRad)*maxRange,0) + vecCaster
		FindClearSpaceForUnit(caster,blinkVector,true)
	end

	local effectIndex = ParticleManager:CreateParticle("particles/econ/items/omniknight/hammer_ti6_immortal/omniknight_pur_ti6_immortal_hampart_b.vpcf", PATTACH_POINT, caster)
	ParticleManager:DestroyParticleSystem(effectIndex, false)
	if FindTelentValue(caster,"special_bonus_unique_lyrica_3") then
		local effectIndex3 = ParticleManager:CreateParticle("particles/econ/items/omniknight/hammer_ti6_immortal/omniknight_pur_ti6_immortal_beams.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(effectIndex3, 0, caster:GetOrigin())
		ParticleManager:SetParticleControl(effectIndex3, 3, caster:GetOrigin())
		ParticleManager:DestroyParticleSystem(effectIndex3, false)
	end

	-- 这里的施法坐标是已经传送完之后的坐标
	vecCaster = caster:GetOrigin()
	local heal = self:GetSpecialValueFor("heal")
	local intellectBonus = self:GetSpecialValueFor("intellect_bonus")
	local totalHeal = heal + caster:GetIntellect(false) * intellectBonus
	local targets = FindUnitsInRadius(caster:GetTeam(), 
									 vecCaster, 
									 nil, 
									 self:GetSpecialValueFor("heal_radius"), 
									 DOTA_UNIT_TARGET_TEAM_BOTH, 
									 self:GetAbilityTargetType(), 
									 DOTA_UNIT_TARGET_FLAG_NONE, 
									 FIND_ANY_ORDER, 
									 false
									)
	for _,v in pairs (targets) do
		if v:GetTeam() == caster:GetTeam() then
			local effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", PATTACH_POINT, v)
			ParticleManager:DestroyParticleSystem(effectIndex, false)
			v:Heal(totalHeal, caster)
			SendOverheadEventMessage(nil,OVERHEAD_ALERT_HEAL,v,totalHeal,nil)
		elseif FindTelentValue(caster,"special_bonus_unique_lyrica_4") == 1 and not v:IsBuilding() then
				local damage_table = {
				ability = self,
				victim = v,
				attacker = caster,
				damage = totalHeal,
				damage_type = self:GetAbilityDamageType()
				}
			local effectIndex1 = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_guardian_angel_buff_n.vpcf", PATTACH_POINT, v)
			ParticleManager:DestroyParticleSystem(effectIndex1, false)
			UnitDamageTarget(damage_table)
		end
	end
	
	caster:EmitSound("Voice_Thdots_Cirno.AbilityLyrica01")
end

ability_thdots_lyrica02 = {}

function ability_thdots_lyrica02:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	target:AddNewModifier(caster, self, "modifier_ability_thdots_lyrica02_attack", {Duration = self:GetSpecialValueFor("duration")})
	target:AddNewModifier(caster, self, "modifier_ability_thdots_lyrica02_beattack", {Duration = self:GetSpecialValueFor("duration")})
	
	local effectIndex = ParticleManager:CreateParticle("particles/econ/items/omniknight/omni_ti8_head/omniknight_repel_buff_ti8_sphere.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, target)
	effectIndex1 = ParticleManager:CreateParticle("particles/econ/items/omniknight/omni_ti8_head/omniknight_repel_buff_ti8_swoosh.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, target)
	effectIndex2 = ParticleManager:CreateParticle("particles/econ/items/omniknight/omni_ti8_head/omniknight_repel_buff_ti8_glyph.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, target)
	ParticleManager:DestroyParticleSystemTime(effectIndex, self:GetSpecialValueFor("duration"))
	ParticleManager:DestroyParticleSystemTime(effectIndex1, self:GetSpecialValueFor("duration"))
	ParticleManager:DestroyParticleSystemTime(effectIndex2, self:GetSpecialValueFor("duration"))
	
	caster:EmitSound("Voice_Thdots_Cirno.AbilityLyrica02")
end

modifier_ability_thdots_lyrica02_attack = {}
LinkLuaModifier("modifier_ability_thdots_lyrica02_attack", "scripts/vscripts/abilities/abilitylyrica.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_ability_thdots_lyrica02_attack:IsHidden() 		return false end
function modifier_ability_thdots_lyrica02_attack:IsPurgable()		return true end
function modifier_ability_thdots_lyrica02_attack:RemoveOnDeath() 	return true end
function modifier_ability_thdots_lyrica02_attack:IsDebuff()			return false end

function modifier_ability_thdots_lyrica02_attack:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED
	}
end

function modifier_ability_thdots_lyrica02_attack:OnAttackLanded(keys)
	if not IsServer() then return end
	local parent = self:GetParent()
	local target = keys.target
	if keys.attacker == parent and target:GetTeamNumber() ~= parent:GetTeamNumber() then
		if not target:IsBuilding() then
			ParticleManager:DestroyParticle(effectIndex1,true)
			target:AddNewModifier(parent, self:GetAbility(), "modifier_ability_thdots_lyrica02_debuff", {Duration = self:GetAbility():GetSpecialValueFor("debuff_duration")})
			parent:RemoveModifierByName("modifier_ability_thdots_lyrica02_attack")
			local effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_degen_aura_debuff.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, target)
			ParticleManager:DestroyParticleSystemTime(effectIndex, self:GetAbility():GetSpecialValueFor("debuff_duration"))
			local damage_table = {
					ability = self,
					victim = target,
					attacker = parent,
					damage = self:GetAbility():GetSpecialValueFor("damage") + parent:GetIntellect(false) * self:GetAbility():GetSpecialValueFor("bonus_int"),
					damage_type = self:GetAbility():GetAbilityDamageType()
					}
			UnitDamageTarget(damage_table)
			if not target or target:IsNull() or not target:IsAlive() then
				ParticleManager:DestroyParticleSystem(effectIndex,true)
			end
		end
	end
end

modifier_ability_thdots_lyrica02_beattack = {}
LinkLuaModifier("modifier_ability_thdots_lyrica02_beattack", "scripts/vscripts/abilities/abilitylyrica.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_ability_thdots_lyrica02_beattack:IsHidden() 		return false end
function modifier_ability_thdots_lyrica02_beattack:IsPurgable()		return true end
function modifier_ability_thdots_lyrica02_beattack:RemoveOnDeath() 	return true end
function modifier_ability_thdots_lyrica02_beattack:IsDebuff()		return false end

function modifier_ability_thdots_lyrica02_beattack:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACKED
	}
end

function modifier_ability_thdots_lyrica02_beattack:OnAttacked(keys)
	if not IsServer() then return end
	local parent = self:GetParent()
	local target = keys.attacker
	if keys.target == parent and target:GetTeamNumber() ~= parent:GetTeamNumber() then
		if target:IsHero() then
			ParticleManager:DestroyParticle(effectIndex2,true)
			parent:RemoveModifierByName("modifier_ability_thdots_lyrica02_beattack")
			target:AddNewModifier(parent, self:GetAbility(), "modifier_ability_thdots_lyrica02_debuff", {Duration = self:GetAbility():GetSpecialValueFor("debuff_duration")})
			local effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_degen_aura_debuff.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, target)
			ParticleManager:DestroyParticleSystemTime(effectIndex, self:GetAbility():GetSpecialValueFor("debuff_duration"))
			local damage_table = {
					ability = self,
					victim = target,
					attacker = parent,
					damage = self:GetAbility():GetSpecialValueFor("damage") + parent:GetIntellect(false) * self:GetAbility():GetSpecialValueFor("bonus_int"),
					damage_type = self:GetAbility():GetAbilityDamageType()
					}
			UnitDamageTarget(damage_table)
			if not target or target:IsNull() or not target:IsAlive() then
				ParticleManager:DestroyParticleSystem(effectIndex,true)
			end
		end
	end
end

modifier_ability_thdots_lyrica02_debuff = {}
LinkLuaModifier("modifier_ability_thdots_lyrica02_debuff", "scripts/vscripts/abilities/abilitylyrica.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_ability_thdots_lyrica02_debuff:IsHidden() 		return false end
function modifier_ability_thdots_lyrica02_debuff:IsPurgable()		return true end
function modifier_ability_thdots_lyrica02_debuff:RemoveOnDeath() 	return true end
function modifier_ability_thdots_lyrica02_debuff:IsDebuff()			return true end

function modifier_ability_thdots_lyrica02_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	}
end

function modifier_ability_thdots_lyrica02_debuff:GetModifierAttackSpeedBonus_Constant() return self:GetAbility():GetSpecialValueFor("attack_speed_reduction") end
function modifier_ability_thdots_lyrica02_debuff:GetModifierMoveSpeedBonus_Percentage() return self:GetAbility():GetSpecialValueFor("movement_speed_reduction") end

--------------------------
--「幻想乡绮想音波」
--------------------------
ability_thdots_lyrica03 = {}

function ability_thdots_lyrica03:GetIntrinsicModifierName()		
	return "modifier_ability_thdots_lyrica03_debuff"
end
function ability_thdots_lyrica03:GetBehavior()
	if self:GetCaster():HasScepter() then
		return DOTA_ABILITY_BEHAVIOR_TOGGLE
	else
		return self.BaseClass.GetBehavior(self)
	end
end
function ability_thdots_lyrica03:OnToggle()
	if self:GetToggleState() then
		self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_ability_thdots_lyrica03_wanbaochui", {})
	else
		self:GetCaster():RemoveModifierByName("modifier_ability_thdots_lyrica03_wanbaochui")
	end
end
function ability_thdots_lyrica03:ResetToggleOnRespawn()	return true end

modifier_ability_thdots_lyrica03_debuff = {}
LinkLuaModifier("modifier_ability_thdots_lyrica03_debuff", "scripts/vscripts/abilities/abilitylyrica.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_lyrica03_debuff:IsHidden() 		return true end
function modifier_ability_thdots_lyrica03_debuff:IsPurgable()		return false end
function modifier_ability_thdots_lyrica03_debuff:RemoveOnDeath() 	return true end
function modifier_ability_thdots_lyrica03_debuff:IsDebuff()		return false end
function modifier_ability_thdots_lyrica03_debuff:AllowIllusionDuplicate() return false end
function modifier_ability_thdots_lyrica03_debuff:IsAura() return true end

function modifier_ability_thdots_lyrica03_debuff:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("aura_radius") end -- global
function modifier_ability_thdots_lyrica03_debuff:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NONE end
function modifier_ability_thdots_lyrica03_debuff:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_ability_thdots_lyrica03_debuff:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO end
function modifier_ability_thdots_lyrica03_debuff:GetModifierAura() return "modifier_ability_thdots_lyrica03_debuff_aura" end

function modifier_ability_thdots_lyrica03_debuff:OnCreated()
	if not IsServer() then return end
	self.ability = self:GetAbility()
	self.caster = self:GetCaster()
	self.hp_bouns = self.ability:GetSpecialValueFor("trigger_pct")
	self.base_bouns = self.ability:GetSpecialValueFor("all_state_reduce_base")
	self.bonus_stack = math.floor(self.base_bouns+ (100-self.caster:GetHealthPercent())/self.hp_bouns)
	--print(self.bonus_stack)
	local talent = self.caster:FindAbilityByName("special_bonus_unique_lyrica_2")
	self.targets = FindUnitsInRadius(self.caster:GetTeamNumber(), self.caster:GetOrigin(), self, self.ability:GetSpecialValueFor("aura_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, 0, false)
	for _,u in pairs (self.targets) do
		u:SetModifierStackCount("modifier_ability_thdots_lyrica03_debuff_aura", self.caster, self.bonus_stack)
	end
	self:StartIntervalThink(0.3)
end
function modifier_ability_thdots_lyrica03_debuff:OnIntervalThink()
	if not IsServer() then return end
	self.hp_bouns = self.ability:GetSpecialValueFor("trigger_pct")
	self.base_bouns = self.ability:GetSpecialValueFor("all_state_reduce_base")
	self.bonus_stack = math.floor(self.base_bouns+ (100-self.caster:GetHealthPercent())/self.hp_bouns)
	local talent = self.caster:FindAbilityByName("special_bonus_unique_lyrica_2")
	self.targets = FindUnitsInRadius(self.caster:GetTeamNumber(), self.caster:GetOrigin(), nil, self.ability:GetSpecialValueFor("aura_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, 0, false)
	for _,u in pairs (self.targets) do
		u:SetModifierStackCount("modifier_ability_thdots_lyrica03_debuff_aura", self.caster, self.bonus_stack)
	end
end

modifier_ability_thdots_lyrica03_debuff_aura = {}
LinkLuaModifier("modifier_ability_thdots_lyrica03_debuff_aura", "scripts/vscripts/abilities/abilitylyrica.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_lyrica03_debuff_aura:IsHidden() 		return false end
function modifier_ability_thdots_lyrica03_debuff_aura:IsPurgable()		return false end
function modifier_ability_thdots_lyrica03_debuff_aura:RemoveOnDeath() 	return true end
function modifier_ability_thdots_lyrica03_debuff_aura:IsDebuff()		return true end
function modifier_ability_thdots_lyrica03_debuff_aura:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}
end
function modifier_ability_thdots_lyrica03_debuff_aura:OnCreated()
	if not IsServer() then return end
end
function modifier_ability_thdots_lyrica03_debuff_aura:OnStackCountChanged()
	if not IsServer() then return end
	self:GetParent():CalculateStatBonus(true)
end
function modifier_ability_thdots_lyrica03_debuff_aura:GetModifierBonusStats_Strength()
	return -self:GetStackCount()
end
function modifier_ability_thdots_lyrica03_debuff_aura:GetModifierBonusStats_Agility()
	return -self:GetStackCount()
end
function modifier_ability_thdots_lyrica03_debuff_aura:GetModifierBonusStats_Intellect()
	if self:GetParent():GetClassname()=="npc_dota_hero_axe" then 
		return 0 end
	return -self:GetStackCount()
end


modifier_ability_thdots_lyrica03_wanbaochui = {}
LinkLuaModifier("modifier_ability_thdots_lyrica03_wanbaochui", "scripts/vscripts/abilities/abilitylyrica.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_lyrica03_wanbaochui:IsHidden() 		return true end
function modifier_ability_thdots_lyrica03_wanbaochui:IsPurgable()		return false end
function modifier_ability_thdots_lyrica03_wanbaochui:RemoveOnDeath() 	return true end
function modifier_ability_thdots_lyrica03_wanbaochui:IsDebuff()		return false end
function modifier_ability_thdots_lyrica03_wanbaochui:AllowIllusionDuplicate() return false end
function modifier_ability_thdots_lyrica03_wanbaochui:IsAura() return true end

function modifier_ability_thdots_lyrica03_wanbaochui:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("aura_radius") end -- global
function modifier_ability_thdots_lyrica03_wanbaochui:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NONE end
function modifier_ability_thdots_lyrica03_wanbaochui:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_ability_thdots_lyrica03_wanbaochui:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO end
function modifier_ability_thdots_lyrica03_wanbaochui:GetModifierAura() return "modifier_ability_thdots_lyrica03_buff_aura" end
function modifier_ability_thdots_lyrica03_wanbaochui:OnCreated()
	if not IsServer() then return end
	self.caster = self:GetCaster()
	self.ability = self:GetAbility()
	
	self.hp_bouns = self.ability:GetSpecialValueFor("trigger_pct")
	self.base_bouns = self.ability:GetSpecialValueFor("all_state_reduce_base")

	self.tick			= self.ability:GetSpecialValueFor("tick")
	self.damage_percent	= self.ability:GetSpecialValueFor("damage_percent") 
	self.damage_per_tick	= self.caster:GetMaxHealth() * self.damage_percent * 0.01 * self.tick

	ApplyDamage({
		victim 			= self:GetParent(),
		damage 			= self.damage_per_tick,
		damage_type		= DAMAGE_TYPE_PURE,
		damage_flags 	= DOTA_DAMAGE_FLAG_HPLOSS,
		attacker 		= self.caster,
		ability 		= self.ability
	})
	self:StartIntervalThink(self.tick)
end
function modifier_ability_thdots_lyrica03_wanbaochui:OnIntervalThink()
	if not IsServer() then return end
	self.hp_bouns = self.ability:GetSpecialValueFor("trigger_pct")
	self.base_bouns = self.ability:GetSpecialValueFor("all_state_reduce_base")
	print(self.caster:GetHealthPercent())
	print(self.base_bouns)
	self.targets = FindUnitsInRadius(self.caster:GetTeamNumber(), self.caster:GetOrigin(), nil, self.ability:GetSpecialValueFor("aura_radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, 0, 0, false)
	self.bonus_stack = math.floor(self.base_bouns+ (100-self.caster:GetHealthPercent())/self.hp_bouns)
	print(self.bonus_stack)
	for _,u in pairs (self.targets) do
		u:SetModifierStackCount("modifier_ability_thdots_lyrica03_buff_aura", self.caster, self.bonus_stack)
	end
	self.damage_per_tick	= self.caster:GetMaxHealth() * self.damage_percent * 0.01 * self.tick
	ApplyDamage({
		victim 			= self:GetParent(),
		damage 			= self.damage_per_tick,
		damage_type		= DAMAGE_TYPE_PURE,
		damage_flags 	= DOTA_DAMAGE_FLAG_HPLOSS,
		attacker 		= self.caster,
		ability 		= self.ability
	})
end
modifier_ability_thdots_lyrica03_buff_aura = {}
LinkLuaModifier("modifier_ability_thdots_lyrica03_buff_aura", "scripts/vscripts/abilities/abilitylyrica.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_lyrica03_buff_aura:IsHidden() 		return false end
function modifier_ability_thdots_lyrica03_buff_aura:IsPurgable()		return false end
function modifier_ability_thdots_lyrica03_buff_aura:RemoveOnDeath() 	return true end
function modifier_ability_thdots_lyrica03_buff_aura:IsDebuff()		return false end

function modifier_ability_thdots_lyrica03_buff_aura:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}
end
function modifier_ability_thdots_lyrica03_buff_aura:OnCreated()
	if not IsServer() then return end
end
function modifier_ability_thdots_lyrica03_buff_aura:OnStackCountChanged()
	if not IsServer() then return end
	self:GetParent():CalculateStatBonus(true)
end
function modifier_ability_thdots_lyrica03_buff_aura:GetModifierBonusStats_Strength()
	return self:GetStackCount()
end
function modifier_ability_thdots_lyrica03_buff_aura:GetModifierBonusStats_Agility()
	return self:GetStackCount()
end
function modifier_ability_thdots_lyrica03_buff_aura:GetModifierBonusStats_Intellect()
	if self:GetParent():GetClassname()=="npc_dota_hero_axe" then 
		return 0 end
	return self:GetStackCount()
end
---------------------------
-----键灵「韵动钢琴曲第一乐章」
----------------------------
ability_thdots_lyrica04 = {}

function ability_thdots_lyrica04:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	target:AddNewModifier(caster, self, "modifier_ability_thdots_lyrica04", {Duration = self:GetSpecialValueFor("duration")})

	local effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_heavenly_grace_buff.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, target)
	ParticleManager:DestroyParticleSystemTime(effectIndex, self:GetSpecialValueFor("duration"))
	local effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_guardian_angel_omni.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, target)
	ParticleManager:DestroyParticleSystemTime(effectIndex, self:GetSpecialValueFor("duration"))
	
	caster:EmitSound("Voice_Thdots_Cirno.AbilityLyrica04")
end

modifier_ability_thdots_lyrica04 = {}
LinkLuaModifier("modifier_ability_thdots_lyrica04", "scripts/vscripts/abilities/abilitylyrica.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_lyrica04:IsHidden() 		return false end
function modifier_ability_thdots_lyrica04:IsPurgable()		return false end
function modifier_ability_thdots_lyrica04:RemoveOnDeath() 	return true end
function modifier_ability_thdots_lyrica04:IsDebuff()		return true end

function modifier_ability_thdots_lyrica04:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE
	}
end

function modifier_ability_thdots_lyrica04:GetAbsoluteNoDamagePhysical() return 1 end
function modifier_ability_thdots_lyrica04:GetAbsoluteNoDamageMagical() return 1 end
function modifier_ability_thdots_lyrica04:GetAbsoluteNoDamagePure() return 1 end

ability_thdots_lyricaEx = {}
function ability_thdots_lyricaEx:Spawn()
	if not IsServer() then return end
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_ability_thdots_lyricaEx", {Duration = nil})
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_ability_thdots_lyricaEx_bonus", {Duration = nil})
end

modifier_ability_thdots_lyricaEx = {}
LinkLuaModifier("modifier_ability_thdots_lyricaEx", "scripts/vscripts/abilities/abilitylyrica.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_lyricaEx:IsHidden() 		return false end
function modifier_ability_thdots_lyricaEx:IsPurgable()		return false end
function modifier_ability_thdots_lyricaEx:RemoveOnDeath() 	return false end
function modifier_ability_thdots_lyricaEx:IsDebuff()		return false end

function modifier_ability_thdots_lyricaEx:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
		MODIFIER_EVENT_ON_DEATH
	}
end

function modifier_ability_thdots_lyricaEx:GetModifierPercentageCooldown()
	return self:GetAbility():GetSpecialValueFor("cooldown_bonus_half") * self:GetCaster():GetModifierStackCount("modifier_ability_thdots_lyricaEx", self:GetCaster())
end

function modifier_ability_thdots_lyricaEx:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.1)
	self:OnIntervalThink()
end

function modifier_ability_thdots_lyricaEx:OnIntervalThink()
    if not IsServer() then return end
	if LYRICA_BONUS_COUNT ~= nil then
		self:GetCaster():SetModifierStackCount("modifier_ability_thdots_lyricaEx", self:GetCaster(), LYRICA_BONUS_COUNT)
	end
end

function modifier_ability_thdots_lyricaEx:OnDeath(keys)
	-- 天生, 每击杀一个单位增加0.2%冷却时间, 击杀200个单位后层数减半,上限75%
    if not IsServer() then return end
	local caster = self:GetCaster()
	if keys.attacker == caster then
		local cooldown_limit = math.ceil(self:GetAbility():GetSpecialValueFor("cooldown_limit") / self:GetAbility():GetSpecialValueFor("cooldown_bonus_half"))
		local cooldown_max = math.ceil(self:GetAbility():GetSpecialValueFor("cooldown_max") / self:GetAbility():GetSpecialValueFor("cooldown_bonus_half"))
		local lyricaExModifier = caster:FindModifierByName("modifier_ability_thdots_lyricaEx")
		if lyricaExModifier and not caster:HasModifier("modifier_illusion") then
			if LYRICA_BONUS_COUNT == nil then
				LYRICA_BONUS_COUNT = caster:GetModifierStackCount("modifier_ability_thdots_lyricaEx", caster)
			end
			if LYRICA_BONUS_COUNT >= cooldown_max then
				LYRICA_BONUS_COUNT = cooldown_max
			elseif LYRICA_BONUS_COUNT >= cooldown_limit then
				LYRICA_BONUS_COUNT = LYRICA_BONUS_COUNT +1
			else
				LYRICA_BONUS_COUNT = LYRICA_BONUS_COUNT +2
			end
		end
	end
end

modifier_ability_thdots_lyricaEx_bonus = {}
LinkLuaModifier("modifier_ability_thdots_lyricaEx_bonus", "scripts/vscripts/abilities/abilitylyrica.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_lyricaEx_bonus:IsHidden() 			return false end
function modifier_ability_thdots_lyricaEx_bonus:IsPurgable()		return false end
function modifier_ability_thdots_lyricaEx_bonus:RemoveOnDeath() 	return false end
function modifier_ability_thdots_lyricaEx_bonus:IsDebuff()			return false end

function modifier_ability_thdots_lyricaEx_bonus:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED
	}
end

function modifier_ability_thdots_lyricaEx_bonus:OnAttackLanded(keys)
    if not IsServer() then return end
	--每第四次攻击附加法术伤害
	local caster = self:GetCaster()
	local target = keys.target
	if keys.attacker == caster and target:GetTeamNumber() ~= caster:GetTeamNumber() then
		local count = caster:GetModifierStackCount("modifier_ability_thdots_lyricaEx_bonus", caster)
		if count >= 3 then
			caster:SetModifierStackCount("modifier_ability_thdots_lyricaEx_bonus", self:GetAbility(), 0)
			local targets = FindUnitsInRadius(caster:GetTeam(), 
										target:GetOrigin(), 
										nil, 
										self:GetAbility():GetSpecialValueFor("radius"), 
										DOTA_UNIT_TARGET_TEAM_ENEMY, 
										self:GetAbility():GetAbilityTargetType(), 
										DOTA_UNIT_TARGET_NONE, 
										FIND_ANY_ORDER, 
										false
										)
			for _,v in pairs(targets) do
				if not v:IsBuilding() then
					local damage_table = {
								ability = self:GetAbility(),
								victim = v,
								attacker = caster,
								damage = self:GetAbility():GetSpecialValueFor("damage") + caster:GetLevel(),
								damage_type = self:GetAbility():GetAbilityDamageType()
								}
					local effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_repel_buff_e.vpcf", PATTACH_ABSORIGIN, v)
					ParticleManager:DestroyParticleSystem(effectIndex,false)
					UnitDamageTarget(damage_table)
				end
			end
		else
			caster:SetModifierStackCount("modifier_ability_thdots_lyricaEx_bonus", self:GetAbility(), count + 1)
		end
	end
end

