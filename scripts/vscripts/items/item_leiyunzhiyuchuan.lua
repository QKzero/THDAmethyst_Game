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
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_HEALTH_BONUS,
	}
end

function modifier_item_leiyunzhiyuchuan_passive:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_armor")	
end

function modifier_item_leiyunzhiyuchuan_passive:GetModifierMagicalResistanceBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_magical_armor")
end

function modifier_item_leiyunzhiyuchuan_passive:GetModifierHealthBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_health")
end

-- function item_leiyunzhiyuchuan:GetCastRange(vLocation, hTarget)
-- 	return self:GetSpecialValueFor("radius")
-- end

function item_leiyunzhiyuchuan:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local target1 = self:GetCursorTarget()
	local ability = self
	local point = target1:GetOrigin()
	local target1team = self:GetSpecialValueFor("targetteam")
	local radius = self:GetSpecialValueFor("radius")

	target1:EmitSound("THD_ITEM.Leiyunzhiyuchuan_Cast")
	local particle = "particles/thd2/heroes/iku/iku_02.vpcf"
	self.particle = ParticleManager:CreateParticle(particle,PATTACH_CUSTOMORIGIN,target1)
	ParticleManager:SetParticleControlEnt(self.particle , 2, target1, 5, "attach_hitloc", Vector(0,0,0), true)
	-- ParticleManager:SetParticleControl(self.particle, 1, Vector(direct.x*1500,direct.y*1500,0))
	-- ParticleManager:SetParticleControl(self.particle, 2, Vector(200,200,200))
	ParticleManager:DestroyParticleSystemTime(self.particle,0.4)

	local targets = FindUnitsInRadius(target1:GetTeam(), point,nil,radius,DOTA_UNIT_TARGET_TEAM_ENEMY
			,self:GetAbilityTargetType(),0,0,false)
	for _,victim in ipairs(targets) do
		if not victim:HasModifier("modifier_thdots_yugi04_think_interval") then
			victim:AddNewModifier(target1, self, "modifier_item_leiyunzhiyuchuan_push",{duration = 0.2})
		end
	end

end

modifier_item_leiyunzhiyuchuan_push = {}
LinkLuaModifier("modifier_item_leiyunzhiyuchuan_push","items/item_leiyunzhiyuchuan.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_item_leiyunzhiyuchuan_push:IsDebuff() return true end
function modifier_item_leiyunzhiyuchuan_push:IsHidden() return false end
function modifier_item_leiyunzhiyuchuan_push:IsPurgable() return false end
function modifier_item_leiyunzhiyuchuan_push:RemoveOnDeath() return true end

function modifier_item_leiyunzhiyuchuan_push:OnCreated()
	if not IsServer() then return end
	self.point = self:GetCaster():GetOrigin()
	self.target = self:GetParent()
	self.direct = (self.target:GetOrigin() - self.point):Normalized()
	local distance = self:GetAbility():GetSpecialValueFor("distance")
	local duration = self:GetRemainingTime()
	print(duration)
	self.speed = distance /  (1/duration)
	print(self.speed)
	self:StartIntervalThink(FrameTime())
end

function modifier_item_leiyunzhiyuchuan_push:OnIntervalThink()
	if not IsServer() then return end
	local target = self:GetParent()
	local position = target:GetOrigin() + self.direct * self.speed
	if target:HasModifier("modifier_thdots_yugi04_think_interval") then
		self:Destroy()
	end
	target:SetOrigin(position)
end

function modifier_item_leiyunzhiyuchuan_push:OnDestroy()
	if not IsServer() then return end
	ResolveNPCPositions(self:GetParent():GetAbsOrigin(), 128)
end

function modifier_item_leiyunzhiyuchuan_push:CheckState()
	return {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
end