----------------------------------------------------------------------------------------------
-- 道具技能

item_jiduzhixinyan = {}

function item_jiduzhixinyan:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	if (not target:IsRealHero()) then return end

	local modifier
	if (caster:HasModifier("modifier_item_jiduzhixinyan_mark")) then
		modifier = caster:FindModifierByName("modifier_item_jiduzhixinyan_mark")
	else
		modifier = caster:AddNewModifier(caster, self, "modifier_item_jiduzhixinyan_mark", {})
	end

	if (caster == target) then
		modifier:SetStackCount(99)
	else
		modifier:SetStackCount(target:GetPlayerID())
	end

	local particle_name = "particles/econ/items/undying/undying_pale_augur/undying_pale_augur_decay_strength_xfer.vpcf"
	local particle = ParticleManager:CreateParticle(particle_name, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, caster:GetOrigin() + Vector(0, 0, 50))
	ParticleManager:SetParticleControl(particle, 1, target:GetOrigin() + Vector(0, 0, 50))
	ParticleManager:SetParticleControl(particle, 2, target:GetOrigin() + Vector(0, 0, 50))
	ParticleManager:ReleaseParticleIndex(particle)
	ParticleManager:DestroyParticle(particle, false)

	target:EmitSound("THD_ITEM.Jiduzhixinyan_Damage")
end

function item_jiduzhixinyan:GetIntrinsicModifierName()
	return "modifier_item_jiduzhixinyan_passive"
end

-- 道具技能 End
----------------------------------------------------------------------------------------------
-- 被动buff

modifier_item_jiduzhixinyan_passive = {}
LinkLuaModifier("modifier_item_jiduzhixinyan_passive","items/item_jiduzhixinyan.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_item_jiduzhixinyan_passive:IsHidden() return true end
function modifier_item_jiduzhixinyan_passive:IsPurgable() return false end
function modifier_item_jiduzhixinyan_passive:IsPurgeException() return false end
function modifier_item_jiduzhixinyan_passive:RemoveOnDeath() return false end

function modifier_item_jiduzhixinyan_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_MANA_BONUS,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
		MODIFIER_EVENT_ON_DEATH,
	}
end

function modifier_item_jiduzhixinyan_passive:MODIFIER_PROPERTY_HEALTH_BONUS()
	return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_jiduzhixinyan_passive:GetModifierManaBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_jiduzhixinyan_passive:GetModifierMoveSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("bonus_movespeed")
end

function modifier_item_jiduzhixinyan_passive:OnCreated(params)
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	self.bonusAuraDuration = self.ability:GetSpecialValueFor("bonus_aura_duration")

end

function modifier_item_jiduzhixinyan_passive:OnDestroy()
	if not IsServer() then return end

	if self.caster:HasModifier("modifier_item_jiduzhixinyan_mark") then
		self.caster:RemoveModifierByName("modifier_item_jiduzhixinyan_mark")
	end
end

function modifier_item_jiduzhixinyan_passive:OnDeath(keys)
	if not IsServer() then return end

	if self.caster == nil then self.caster = self:GetCaster() end
	if self.ability == nil then self.ability = self:GetAbility() end

	if keys.unit ~= self.caster or not self.caster:IsRealHero() then return end

	if self.bonusAuraDuration == nil then self.bonusAuraDuration = self.ability:GetSpecialValueFor("bonus_aura_duration") end

	local units = FindUnitsInRadius(
		self.caster:GetTeamNumber(),
		self.caster:GetOrigin(),
		nil,
		99999,
		self.ability:GetAbilityTargetTeam(),
		self.ability:GetAbilityTargetType(),
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)

	for _, v in pairs(units) do
		if not v:HasModifier("modifier_item_jiduzhixinyan_ally_buff") then
			v:AddNewModifier(self.caster, self.ability, "modifier_item_jiduzhixinyan_ally_buff", {
				duration = self.bonusAuraDuration
			})
		else
			v:FindModifierByName("modifier_item_jiduzhixinyan_ally_buff"):SetDuration(self.bonusAuraDuration, true)
		end
	end
end

-- 被动buff End
----------------------------------------------------------------------------------------------
-- 复活主体buff

modifier_item_jiduzhixinyan_mark = {}
LinkLuaModifier("modifier_item_jiduzhixinyan_mark","items/item_jiduzhixinyan.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_item_jiduzhixinyan_mark:IsHidden() return false end
function modifier_item_jiduzhixinyan_mark:IsPurgable() return false end
function modifier_item_jiduzhixinyan_mark:IsPurgeException() return false end
function modifier_item_jiduzhixinyan_mark:RemoveOnDeath() return false end

function modifier_item_jiduzhixinyan_mark:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_RESPAWNTIME_PERCENTAGE,
		MODIFIER_EVENT_ON_DEATH,
	}
end

function modifier_item_jiduzhixinyan_mark:OnCreated()
    if not IsServer() then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()
end

function modifier_item_jiduzhixinyan_mark:IsMarkValid()
	if not IsServer() then return false end

    if self:GetStackCount() ~= nil and self:GetStackCount() < 50 then
        local target = PlayerResource:GetPlayer(self:GetStackCount()):GetAssignedHero()
        if target ~= nil and not target:IsNull() and not target:IsAlive() then
			if not (target:HasModifier(self:GetName()) and target:FindModifierByName(self:GetName()):GetStackCount() < 50) then
				return true
			end
        end
    end

    return false
end

function modifier_item_jiduzhixinyan_mark:GetModifierPercentageRespawnTime()
	if not IsServer() then return 0 end
	if self:IsMarkValid() then
		return - self:GetAbility():GetSpecialValueFor("respawn_bonus") * 0.01
	end
	return 0
end

function modifier_item_jiduzhixinyan_mark:OnDeath(keys)
	if not IsServer() then return end

	if self.caster == nil then self.caster = self:GetCaster() end
	if self.ability == nil then self.ability = self:GetAbility() end

	if keys.unit ~= self.caster or not self.caster:IsRealHero() then return end

	if self:IsMarkValid() then
		local target = PlayerResource:GetPlayer(self:GetStackCount()):GetAssignedHero()
		target:RespawnHero(false, false)
	end
end

--- ChangeTargetMarkFlag
---@param change boolean Increment or Reduction, true meaning increment or false meaning reduction
function modifier_item_jiduzhixinyan_mark:ChangeTargetMarkFlag(change)
	if not IsServer() then return end

	local target = PlayerResource:GetPlayer(self:GetStackCount()):GetAssignedHero()
	
	if not target:HasModifier("modifier_item_jiduzhixinyan_mark_flag") then
		if change then
			local modifier = target:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_item_jiduzhixinyan_mark_flag", {})
			if modifier ~= nil then
				modifier:IncrementStackCount()
			end
		end
	else
		local modifier = target:FindModifierByName("modifier_item_jiduzhixinyan_mark_flag")
		if change then
			modifier:IncrementStackCount()
		else
			local flag = modifier:GetStackCount()
			if flag < 1 then
				modifier:Destroy()
			else
				modifier:DecrementStackCount()
			end
		end
	end
end

-- 复活主体buff End
----------------------------------------------------------------------------------------------
-- 复活标记显示buff（未完工和实装）

modifier_item_jiduzhixinyan_mark_flag = {}
LinkLuaModifier("modifier_item_jiduzhixinyan_mark_flag","items/item_jiduzhixinyan.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_item_jiduzhixinyan_mark_flag:IsHidden() return false end
function modifier_item_jiduzhixinyan_mark_flag:IsPurgable() return false end
function modifier_item_jiduzhixinyan_mark_flag:IsPurgeException() return false end
function modifier_item_jiduzhixinyan_mark_flag:RemoveOnDeath() return true end

function modifier_item_jiduzhixinyan_mark_flag:OnCreated()
	if not IsServer() then return end

	self.parent = self:GetParent()

	self:ShowStackCount(self:GetStackCount())
end

function modifier_item_jiduzhixinyan_mark_flag:OnStackCountChanged(count)
	if not IsServer() then return end

	if self.parent == nil then self.parent = self:GetParent() end

	self:ShowStackCount(count)
end

function modifier_item_jiduzhixinyan_mark_flag:ShowStackCount(count)
	if not IsServer() then return end

	if self.parent == nil then self.parent = self:GetParent() end
	if self.particle_ui == nil then
		self.particle_ui = ParticleManager:CreateParticle("particles/thd2/items/item_jiduzhixinyan_number.vpcf", PATTACH_OVERHEAD_FOLLOW, self.parent)
		ParticleManager:SetParticleControl(self.particle_ui, 0, self.parent:GetAbsOrigin()) -- position
		ParticleManager:SetParticleControl(self.particle_ui, 2, Vector(0, 1, 0)) -- number colour
		self:AddParticle(self.particle_ui, true, false, -1, false, true)
	end

	local stacks = self:GetStackCount()
	local first_digit = stacks % 10
	local second_digit = 0 -- default

	-- Max Number Limit
	if stacks >= 10 then
		second_digit = 1 -- This is the highest second digit supported by this particle UI
	end
	if stacks > 19 then
		first_digit = 9
	end

	ParticleManager:SetParticleControl(self.particle_ui, 1, Vector(second_digit, first_digit, 0)) -- showed number
end

-- 复活标记显示buff End
----------------------------------------------------------------------------------------------
-- 死亡光环

modifier_item_jiduzhixinyan_ally_buff = {}
LinkLuaModifier("modifier_item_jiduzhixinyan_ally_buff","items/item_jiduzhixinyan.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_item_jiduzhixinyan_ally_buff:IsHidden() return false end
function modifier_item_jiduzhixinyan_ally_buff:IsPurgable() return false end
function modifier_item_jiduzhixinyan_ally_buff:IsPurgeException() return false end
function modifier_item_jiduzhixinyan_ally_buff:RemoveOnDeath() return true end

function modifier_item_jiduzhixinyan_ally_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_item_jiduzhixinyan_ally_buff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_aura_movespeed")
end

function modifier_item_jiduzhixinyan_ally_buff:OnCreated(params)
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()

	self.healthRegenPct = self.ability:GetSpecialValueFor("bonus_aura_health_regen_pct")
	self.healthRegenTime = self.ability:GetSpecialValueFor("bonus_aura_duration")

	self.counter = 0
	self.interval = 1

	self:StartIntervalThink(self.interval)
end

function modifier_item_jiduzhixinyan_ally_buff:OnIntervalThink()
	if not IsServer() then return end

	if (self.counter < self.healthRegenTime) then
		self.counter = self.counter + self.interval

		local heal = self.parent:GetMaxHealth() * self.healthRegenPct * 0.01 / self.healthRegenTime
		self.parent:Heal(heal, self.caster)
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, self.parent, heal, nil)
	else
		self:StartIntervalThink(-1)
	end
end

-- 死亡光环 End
----------------------------------------------------------------------------------------------