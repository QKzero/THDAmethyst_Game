item_leiyunzhiyuchuan = {}

function item_leiyunzhiyuchuan:GetIntrinsicModifierName()
	return "modifier_item_leiyunzhiyuchuan_passive"
end

modifier_item_leiyunzhiyuchuan_passive = {}
LinkLuaModifier("modifier_item_leiyunzhiyuchuan_passive","items/item_leiyunzhiyuchuan.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_item_leiyunzhiyuchuan_passive:IsHidden() return true end
function modifier_item_leiyunzhiyuchuan_passive:IsPurgable() return false end
function modifier_item_leiyunzhiyuchuan_passive:IsPurgeException() return false end
function modifier_item_leiyunzhiyuchuan_passive:RemoveOnDeath() return false end
function modifier_item_leiyunzhiyuchuan_passive:GetAttributes()	return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_leiyunzhiyuchuan_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end

function modifier_item_leiyunzhiyuchuan_passive:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("bonus_attack_damage")	
end

function modifier_item_leiyunzhiyuchuan_passive:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_leiyunzhiyuchuan_passive:OnCreated()
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	if not self.caster:HasModifier("modifier_item_leiyunzhiyuchuan_lightning") then
		self.caster:AddNewModifier(self.caster, self.ability, "modifier_item_leiyunzhiyuchuan_lightning", {})
	end
end

function modifier_item_leiyunzhiyuchuan_passive:OnDestroy()
	if not IsServer() then return end

	if self.caster:HasModifier("modifier_item_leiyunzhiyuchuan_lightning") then
		self.caster:RemoveModifierByName("modifier_item_leiyunzhiyuchuan_lightning")
	end
end

modifier_item_leiyunzhiyuchuan_lightning = {}
LinkLuaModifier("modifier_item_leiyunzhiyuchuan_lightning","items/item_leiyunzhiyuchuan.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_item_leiyunzhiyuchuan_lightning:IsHidden() return false end
function modifier_item_leiyunzhiyuchuan_lightning:IsPurgable() return false end
function modifier_item_leiyunzhiyuchuan_lightning:IsPurgeException() return false end
function modifier_item_leiyunzhiyuchuan_lightning:RemoveOnDeath() return false end

function modifier_item_leiyunzhiyuchuan_lightning:Init()
	if self.inited ~= nil and self.inited == true then return end
	self.inited = true

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	self.chance = self.ability:GetSpecialValueFor("chance")
	self.lockRange = self.ability:GetSpecialValueFor("lock_range")
	self.maxTarget = self.ability:GetSpecialValueFor("max_target")
	self.lightningDamage = self.ability:GetSpecialValueFor("lightning_damage")
	self.lightningDamageCreep = self.ability:GetSpecialValueFor("lightning_damage_creep")
end

function modifier_item_leiyunzhiyuchuan_lightning:OnCreated()
	if not IsServer() then return end

	self:Init()
end

function modifier_item_leiyunzhiyuchuan_lightning:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_item_leiyunzhiyuchuan_lightning:OnAttackLanded(event)
	if not IsServer() then return end

	if self:GetCaster() ~= event.attacker then return end

	self:Init()

	if RandomInt(1, 100) > self.chance then return end

	-- 闪电索敌的上一个实体
	local preUnit = self.caster
	for i = 1, self.maxTarget do
		local targets = FindUnitsInRadius(
			self.caster:GetTeamNumber(),
			preUnit:GetOrigin(),
			nil,
			self.lockRange,
			self.ability:GetAbilityTargetTeam(),
			self.ability:GetAbilityTargetType(),
			DOTA_UNIT_TARGET_FLAG_NONE,
			FIND_ANY_ORDER,
			false
		)

		if #targets == 0 then break end

		local target = targets[RandomInt(1, #targets)]
		local damage = self.lightningDamage
		if target:IsCreep() then
			damage = damage + self.lightningDamageCreep
		end

		local damageTable = {
			ability = self.ability,
			victim = target,
			attacker = self.caster,
			damage = damage,
			damage_type = self.ability:GetAbilityDamageType(),
			damage_flags = DOTA_DAMAGE_FLAG_NONE,
		}
		UnitDamageTarget(damageTable)

		--创建音效
		EmitSoundOn("Hero_Zuus.ArcLightning.Cast", self.caster)
		--创建特效
		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_arc_lightning_head.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, preUnit)
		if preUnit == self.caster then
			ParticleManager:SetParticleControlEnt(particle, 0, self.caster, 5, "attach_attack1", Vector(0, 0, 0), true)
		else
			ParticleManager:SetParticleControlEnt(particle, 0, preUnit, 5, "attach_hitloc", Vector(0, 0, 0), true)
		end
		ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin() + Vector(0, 0, 150))
		ParticleManager:ReleaseParticleIndex(particle)
		ParticleManager:DestroyParticleSystemTime(particle, 2)

		preUnit = target
	end
end