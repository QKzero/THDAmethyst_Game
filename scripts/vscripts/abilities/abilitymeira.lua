----------------------------------------------------------------------------------------------
--- Meira Ability Class

AbilityMeira = AbilityMeira or {}

--- Meira Ability Class End
----------------------------------------------------------------------------------------------
--- Meira01

--- Class Member Data

--- Meira01 names
--- It must keep same as real names and sequence all the time
AbilityMeira.ability01_names = {
	"ability_thdots_meira01_1",
	"ability_thdots_meira01_2",
	"ability_thdots_meira01_3",
}

AbilityMeira.ability01_anim = {
	ACT_DOTA_CAST_ABILITY_1,
	ACT_DOTA_CAST_ABILITY_1_END,
	ACT_DOTA_CAST_ABILITY_7,
	ACT_DOTA_CHANNEL_ABILITY_7,
}

-- Ability01 Controllers
AbilityMeira.modifer_swaper = "modifier_meira01_swaper"
AbilityMeira.modifer_timer = "modifier_meira01_timer"

-- FSM Functions
function AbilityMeira:Abiltiy01Control()
	-- Realised in Swaper's OnStackCountChanged
	-- No need to be referenced
end

function AbilityMeira:CheckAbility01Spells(caster)
	for i, ability in ipairs(AbilityMeira.ability01_names) do
		local target_ability = caster:FindAbilityByName(ability)
		if target_ability == nil then return false end
	end

	return true
end

function AbilityMeira:Abiltiy01SpellStart(caster)
	if not IsServer() then return end
	if not AbilityMeira:CheckAbility01Spells(caster) then return end

	local modifer

	-- Timer
	if caster:HasModifier(self.modifer_timer) then
		modifer = caster:FindModifierByName(self.modifer_timer)
		modifer:InterruptTimer()
	end
end

function AbilityMeira:Abiltiy01SpellEnd(caster, ability, next_time)
	if not IsServer() then return end
	if not AbilityMeira:CheckAbility01Spells(caster) then return end

	local modifer

	-- Swaper
	if caster:HasModifier(self.modifer_swaper) then
		modifer = caster:FindModifierByName(self.modifer_swaper)
		local cur_stack = modifer:GetStackCount()
		if cur_stack == nil or cur_stack < #self.ability01_names then
			modifer:IncrementStackCount()
		else
			modifer:SetStackCount(1)
		end
	else
		caster:AddNewModifier(caster, ability, self.modifer_swaper, {})
	end

	-- Timer
	if next_time > 0 then
		if caster:HasModifier(self.modifer_timer) then
			modifer = caster:FindModifierByName(self.modifer_timer)
			modifer:SetDuration(next_time, true)
		else
			caster:AddNewModifier(caster, ability, self.modifer_timer, {
				duration = next_time,
			})
		end
	end
end

function AbilityMeira:Abiltiy01TimeUp(caster)
	-- Triggered on Timer Destroyed influenced by bool in Timer
	if not IsServer() then return end
	if not AbilityMeira:CheckAbility01Spells(caster) then return end

	if caster:HasModifier("modifier_meira01_swaper") then
		local modifer = caster:FindModifierByName("modifier_meira01_swaper")
		modifer:SetStackCount(1)
	end
end

--- Utility Functions

--- Changing the current ability on the location of meira01 using index in the member of this class
function AbilityMeira:Ability01SwapByIndex(caster, iUnableAbilityIndex, iEnableAbilityIndex2)
	local u, e = iUnableAbilityIndex, iEnableAbilityIndex2
	caster:SwapAbilities(
		self.ability01_names[u],
		self.ability01_names[e],
		false,
		true
	)
end

function AbilityMeira:Ability01RestartCooldown(caster)
	if not IsServer() then return end

	local ability = caster:FindAbilityByName(self.ability01_names[1])
	if ability ~= nil then
		ability:RestartCooldown()
	end
end

function AbilityMeira:AbilityEXSwordSpell(caster)
	if not IsServer() then return end

	local ability_ex = caster:FindAbilityByName("ability_thdots_meiraEx")
	if ability_ex ~= nil then
		ability_ex:SwordSpell()
	end
end

--- Return true if interruption condition is met
function AbilityMeira:InterruptChannelCheck(caster)
	return not caster:IsNull() and caster:IsStunned() or caster:IsFeared() or caster:IsFrozen() or caster:IsSilenced()
end

--- Ability Functions

--- Changing the state of meira01
function AbilityMeira:OnMeira01Update(caster, level)
	for _, ability_name in ipairs(AbilityMeira.ability01_names) do
		local target_ability = caster:FindAbilityByName(ability_name)
		if target_ability:GetLevel() ~= level then
			target_ability:SetLevel(level)
		end
	end
end

--- Ability Modifiers

--- Manager of Changing of Meira01
modifier_meira01_swaper = modifier_meira01_swaper or class({})
LinkLuaModifier("modifier_meira01_swaper", "scripts/vscripts/abilities/abilitymeira.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_meira01_swaper:IsHidden() return true end
function modifier_meira01_swaper:IsPurgable() return false end

function modifier_meira01_swaper:OnCreated()
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	self:SetStackCount(1)
end

function modifier_meira01_swaper:OnDestroy()
	if not IsServer() then return end

	self:SetStackCount(1)
end

function modifier_meira01_swaper:OnStackCountChanged(pre_stack)
	if not IsServer() then return end
	if not AbilityMeira:CheckAbility01Spells(self:GetCaster()) then return end

	if self.caster == nil then
		self.caster = self:GetCaster()
	end

	local cur_stack = self:GetStackCount()

	local ability01_names = AbilityMeira.ability01_names

	if not pre_stack or pre_stack == 0 then
		-- Init
		if self.caster:FindAbilityByName(ability01_names[1]):IsHidden() then
			for i = 2, #AbilityMeira.ability01_names do
				if not self.caster:FindAbilityByName(ability01_names[i]):IsHidden() then
					AbilityMeira:Ability01SwapByIndex(self.caster, i, 1)
				end
			end
		end
	else
		AbilityMeira:Ability01SwapByIndex(self.caster, pre_stack, cur_stack)
		if cur_stack == 1 then
			AbilityMeira:Ability01RestartCooldown(self.caster)
		end
	end
end

--- Record time in different stages
modifier_meira01_timer = modifier_meira01_timer or class({})
LinkLuaModifier("modifier_meira01_timer", "scripts/vscripts/abilities/abilitymeira.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_meira01_timer:IsPurgable() return false end

function modifier_meira01_timer:OnCreated()
	if not IsServer() then return end

	self.caster = self:GetCaster()

	self.interrupted = false
end

function modifier_meira01_timer:InterruptTimer()
	if not IsServer() then return end

	self.interrupted = true
	self:Destroy()
end

function modifier_meira01_timer:OnDestroy()
	if not IsServer() then return end

	if not self.interrupted then
		AbilityMeira:Abiltiy01TimeUp(self.caster)
	end
end

-----------------------------------------------
--- Meira01_1

ability_thdots_meira01_1 = ability_thdots_meira01_1 or class({})

function ability_thdots_meira01_1:OnUpgrade()
	if not IsServer() then return end
	if not AbilityMeira:CheckAbility01Spells(self:GetCaster()) then return end

	AbilityMeira:OnMeira01Update(self:GetCaster(), self:GetLevel())
end

function ability_thdots_meira01_1:GetIntrinsicModifierName()
	return "modifier_meira01_swaper"
end

function ability_thdots_meira01_1:GetAOERadius()
	return self:GetSpecialValueFor("sweep_radius")
end

function ability_thdots_meira01_1:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local target_pos = self:GetCursorPosition()

	AbilityMeira:Abiltiy01SpellStart(caster)
	AbilityMeira:ExMonitorOnAbilitiesSpellStart(caster)

	local cast_range = self:GetSpecialValueFor("cast_range")
	local speed = self:GetSpecialValueFor("dash_speed")

	local start_pos = caster:GetOrigin()
	local distance = math.abs(GetDistanceBetweenTwoVec2D(start_pos, target_pos))
	if distance > cast_range then
		distance = cast_range
	end
	local direction = (target_pos - start_pos):Normalized()
	local duration = distance / speed

	caster:Purge(false, true, false, true, false)
	caster:SetForwardVector(direction)
	-- caster:MoveToPosition(target_pos)

	caster:AddNewModifier(caster, self, "modifier_thdots_meira01_1_dash", {
		duration = duration,
		distance = distance,
		direction_x = direction.x,
		direction_y = direction.y,
	})

	self.cooldown = self:GetCooldownTimeRemaining()

	caster:EmitCasterSound("npc_dota_hero_ember_spirit",{"Voice_Thdots_Meira.meira_ability011_01"}, 100, DOTA_CAST_SOUND_FLAG_BOTH_TEAMS, nil, nil)
end

function ability_thdots_meira01_1:RestartCooldown()
	if not IsServer() then return end

	if self.cooldown ~= nil then
		self:StartCooldown(self.cooldown)
	end
end

modifier_thdots_meira01_1_dash = modifier_thdots_meira01_1_dash or class({})
LinkLuaModifier("modifier_thdots_meira01_1_dash", "scripts/vscripts/abilities/abilitymeira.lua", LUA_MODIFIER_MOTION_HORIZONTAL)

function modifier_thdots_meira01_1_dash:IsPurgable() return false end

function modifier_thdots_meira01_1_dash:OnCreated(param)
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	self.speed = self.ability:GetSpecialValueFor("dash_speed")
	self.width = self.ability:GetSpecialValueFor("dash_width")
	self.dash_mul = self.ability:GetSpecialValueFor("dash_mul")

	self.distance = param.distance
	self.direction = Vector(param.direction_x, param.direction_y, 0)
	self.duration = param.duration
	self.start_pos = self.caster:GetOrigin()
	self.target_pos = self.start_pos + self.direction * self.distance

	self.velocity = self.direction * self.speed

	self.caster:RemoveHorizontalMotionController(self)

	if self:ApplyHorizontalMotionController() == false then
		self:Destroy()
	end

	self.caster:StartGesture(AbilityMeira.ability01_anim[1])

	self.caster:StartGesture(ACT_DOTA_CAST_ABILITY_1)

end

function modifier_thdots_meira01_1_dash:OnDestroy()
	if not IsServer() then return end

	-- Set Destination and Interrupt Motion or the unit will still move
	self.caster:RemoveHorizontalMotionController(self)
	FindClearSpaceForUnit(self.caster, self.target_pos, true)

	-- Damage
	local targets = FindUnitsInLine(
		self.caster:GetTeamNumber(),
		self.start_pos,
		self.target_pos,
		nil,
		self.width,
		self.ability:GetAbilityTargetTeam(),
		self.ability:GetAbilityTargetType(),
		self.ability:GetAbilityTargetFlags()
	)
	local damage = self.dash_mul * self.ability:GetLevel()
	for _, target in ipairs(targets) do
		local damage_table = {
			ability = self.ability,
			victim = target,
			attacker = self.caster,
			damage = damage,
			damage_type = self.ability:GetAbilityDamageType(),
			damage_flags = DOTA_DAMAGE_FLAG_NONE,
		}
		UnitDamageTarget(damage_table)
	end

	-- Sweep
	self.caster:AddNewModifier(self.caster, self.ability, "modifier_thdots_meira01_1_sweep", {
		duration = self.ability:GetSpecialValueFor("sweep_duration")
	})
end

function modifier_thdots_meira01_1_dash:OnRefresh(params)
	self:OnCreated(params)
end

function modifier_thdots_meira01_1_dash:UpdateHorizontalMotion(me, dt)
	me:SetOrigin(GetGroundPosition(me:GetOrigin() + self.velocity * dt, nil))
end

function modifier_thdots_meira01_1_dash:OnHorizontalMotionInterrupted()
	self:Destroy()
end

function modifier_thdots_meira01_1_dash:CheckState()
	return {
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_MAGIC_IMMUNE]  = true,
		[MODIFIER_STATE_STUNNED]       = true,
		[MODIFIER_STATE_UNSELECTABLE]  = true,
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
	}
end

function modifier_thdots_meira01_1_dash:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
	}
end

function modifier_thdots_meira01_1_dash:GetAbsoluteNoDamagePhysical()
	return 1
end

function modifier_thdots_meira01_1_dash:GetAbsoluteNoDamageMagical()
	return 1
end

function modifier_thdots_meira01_1_dash:GetAbsoluteNoDamagePure()
	return 1
end

function modifier_thdots_meira01_1_dash:GetEffectName()
	return "particles/heroes/meira/ability_meira_01_1_staff.vpcf"
end
function modifier_thdots_meira01_1_dash:GetEffectAttachType()
	return "follow_origin"
end

modifier_thdots_meira01_1_sweep = modifier_thdots_meira01_1_sweep or class({})
LinkLuaModifier("modifier_thdots_meira01_1_sweep", "scripts/vscripts/abilities/abilitymeira.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_meira01_1_sweep:IsPurgable() return false end

function modifier_thdots_meira01_1_sweep:OnCreated()
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	self.delay = self.ability:GetSpecialValueFor("sweep_delay")
	self.radius = self.ability:GetSpecialValueFor("sweep_radius")
	self.sweep_mul = self.ability:GetSpecialValueFor("sweep_mul")
	self.knockback_distance = self.ability:GetSpecialValueFor("knockback_dist")
	self.knockback_duration = self.ability:GetSpecialValueFor("knockback_dur")
	self.knockback_height = self.ability:GetSpecialValueFor("knockback_hei")

	self.damaged = false

	self.caster:RemoveGesture(AbilityMeira.ability01_anim[1])
	self.caster:StartGesture(AbilityMeira.ability01_anim[2])

	self.caster:StartGesture(ACT_DOTA_CAST_ABILITY_1_END)
end

function modifier_thdots_meira01_1_sweep:OnDestroy()
	if not IsServer() then return end
	local stroke_particle = ParticleManager:CreateParticle("particles/heroes/meira/ability_meira_01_1_crit.vpcf", PATTACH_ABSORIGIN, self.caster)
	ParticleManager:ReleaseParticleIndex(stroke_particle)
	self.caster:EmitSound("samuraiattack1")
	-- Damage
	local targets = FindUnitsInRadius(
		self.caster:GetTeamNumber(),
		self.caster:GetOrigin(),
		nil,
		self.radius,
		self.ability:GetAbilityTargetTeam(),
		self.ability:GetAbilityTargetType(),
		self.ability:GetAbilityTargetFlags(),
		FIND_ANY_ORDER,
		false
	)

	local damage = self.sweep_mul * self.ability:GetLevel() * self.caster:GetStrength()
	local position = self.caster:GetOrigin()
	for _, target in ipairs(targets) do
		local damage_table = {
			ability = self.ability,
			victim = target,
			attacker = self.caster,
			damage = damage,
			damage_type = self.ability:GetAbilityDamageType(),
			damage_flags = DOTA_DAMAGE_FLAG_NONE,
		}
		UnitDamageTarget(damage_table)

		local knockback_properties = {
			center_x           = position.x,
			center_y           = position.y,
			center_z           = position.z,
			duration           = self.knockback_duration,
			knockback_duration = self.knockback_duration,
			knockback_distance = self.knockback_distance,
			knockback_height   = self.knockback_height,
		}
		target:AddNewModifier(self.caster, self.ability, "modifier_knockback", knockback_properties)
	end

	-- Move
	FindClearSpaceForUnit(self.caster, self.caster:GetOrigin(), false)
	-- self.caster:MoveToPosition(self.caster:GetOrigin() + self.caster:GetForwardVector())

	-- Next
	AbilityMeira:Abiltiy01SpellEnd(self.caster, self.ability, self.ability:GetSpecialValueFor("next_time"))
end

function modifier_thdots_meira01_1_sweep:CheckState()
	return {
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_MAGIC_IMMUNE]  = true,
		[MODIFIER_STATE_STUNNED]       = true,
		[MODIFIER_STATE_UNSELECTABLE]  = true,
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
	}
end

function modifier_thdots_meira01_1_sweep:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
		-- MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}
end

function modifier_thdots_meira01_1_sweep:GetAbsoluteNoDamagePhysical()
	return 1
end

function modifier_thdots_meira01_1_sweep:GetAbsoluteNoDamageMagical()
	return 1
end

function modifier_thdots_meira01_1_sweep:GetAbsoluteNoDamagePure()
	return 1
end

function modifier_thdots_meira01_1_sweep:GetOverrideAnimation()
	return ACT_DOTA_CAST_ABILITY_1_END
end

-----------------------------------------------
--- Meira01_2

ability_thdots_meira01_2 = ability_thdots_meira01_2 or class({})

function ability_thdots_meira01_2:OnUpgrade()
	if not IsServer() then return end
	if not AbilityMeira:CheckAbility01Spells(self:GetCaster()) then return end

	AbilityMeira:OnMeira01Update(self:GetCaster(), self:GetLevel())
end

function ability_thdots_meira01_2:GetIntrinsicModifierName()
	return "modifier_meira01_swaper"
end

function ability_thdots_meira01_2:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()

	AbilityMeira:Abiltiy01SpellStart(caster)
	AbilityMeira:ExMonitorOnAbilitiesSpellStart(caster)

	local back_dur = self:GetSpecialValueFor("back_dur")

	caster:AddNewModifier(caster, self, "modifier_thdots_meira01_2_back", {
		duration = back_dur,
	})

	caster:EmitCasterSound("npc_dota_hero_ember_spirit",{"Voice_Thdots_Meira.meira_ability012_01"}, 100, DOTA_CAST_SOUND_FLAG_BOTH_TEAMS, nil, nil)
end

modifier_thdots_meira01_2_back = modifier_thdots_meira01_2_back or class({})
LinkLuaModifier("modifier_thdots_meira01_2_back", "scripts/vscripts/abilities/abilitymeira.lua", LUA_MODIFIER_MOTION_HORIZONTAL)

function modifier_thdots_meira01_2_back:IsPurgable() return false end

function modifier_thdots_meira01_2_back:OnCreated(param)
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	self.length = self.ability:GetSpecialValueFor("back_length")
	self.width = self.ability:GetSpecialValueFor("back_width")
	self.height = self.ability:GetSpecialValueFor("back_height")
	self.level_mul = self.ability:GetSpecialValueFor("level_mul")
	self.agi_mul = self.ability:GetSpecialValueFor("agi_mul")
	self.stun_dur = self.ability:GetSpecialValueFor("stun_dur")
	self.next_time = self.ability:GetSpecialValueFor("next_time")
	self.duration = param.duration

	self.direction = - self.caster:GetForwardVector()
	self.start_pos = self.caster:GetOrigin()
	self.target_pos = GetGroundPosition(self.start_pos + self.length * self.direction, nil)
	self.speed = self.length / self.duration

	self.velocity = self.direction * self.speed

	self.caster:RemoveHorizontalMotionController(self)

	if self:ApplyHorizontalMotionController() == false then
		self:Destroy()
	end

	self.caster:RemoveGesture(AbilityMeira.ability01_anim[2])
	self.caster:StartGestureWithPlaybackRate(AbilityMeira.ability01_anim[3], 1.3 / self.duration)

	self:StartIntervalThink(FrameTime())
end

function modifier_thdots_meira01_2_back:OnIntervalThink()
	if not IsServer() then return end

	-- Damage
	local targets = FindUnitsInLine(
		self.caster:GetTeamNumber(),
		self.start_pos,
		self.target_pos,
		nil,
		self.width,
		self.ability:GetAbilityTargetTeam(),
		self.ability:GetAbilityTargetType(),
		self.ability:GetAbilityTargetFlags()
	)
	local damage = self.level_mul * self.ability:GetLevel() + self.agi_mul * self.caster:GetAgility()
	for _, target in ipairs(targets) do
		if not target:HasModifier("modifier_thdots_meira01_2_back_damage_flag") then
			local damage_table = {
				ability = self.ability,
				victim = target,
				attacker = self.caster,
				damage = damage,
				damage_type = self.ability:GetAbilityDamageType(),
				damage_flags = DOTA_DAMAGE_FLAG_NONE,
			}
			target:AddNewModifier(self.caster, self.ability, "modifier_thdots_meira01_2_back_damage_flag", {
				duration = self:GetRemainingTime() + 0.1
			})

			-- 后跳命中
			UnitDamageTarget(damage_table)
			UtilStun:UnitStunTarget(self.caster, target, self.stun_dur)
			local particle = ParticleManager:CreateParticle("particles/heroes/meira/ability_meira_01_2_dmg.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
			ParticleManager:ReleaseParticleIndex(particle)
			self.caster:EmitSound("samuraiattack2")
		end
	end
end

function modifier_thdots_meira01_2_back:OnDestroy()
	if not IsServer() then return end

	-- Set Destination and Interrupt Motion or the unit will still move
	self.caster:RemoveHorizontalMotionController(self)
	FindClearSpaceForUnit(self.caster, self.target_pos, true)

	-- Next
	AbilityMeira:Abiltiy01SpellEnd(self.caster, self.ability, self.next_time)
end

function modifier_thdots_meira01_2_back:OnRefresh(params)
	self:OnCreated(params)
end

function modifier_thdots_meira01_2_back:UpdateHorizontalMotion(me, dt)
	me:SetOrigin(GetGroundPosition(me:GetOrigin() + self.velocity * dt, nil))

	local stroke_particle = ParticleManager:CreateParticle("particles/heroes/meira/ability_meira_01_2_back.vpcf", PATTACH_ABSORIGIN, me)
	ParticleManager:ReleaseParticleIndex(stroke_particle)
end

function modifier_thdots_meira01_2_back:OnHorizontalMotionInterrupted()
	self:Destroy()
end

function modifier_thdots_meira01_2_back:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
	}
end

function modifier_thdots_meira01_2_back:GetAbsoluteNoDamagePhysical()
	return 1
end

function modifier_thdots_meira01_2_back:GetAbsoluteNoDamageMagical()
	return 1
end

function modifier_thdots_meira01_2_back:GetAbsoluteNoDamagePure()
	return 1
end

function modifier_thdots_meira01_2_back:CheckState()
	return {
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_MAGIC_IMMUNE]  = true,
		[MODIFIER_STATE_STUNNED]       = true,
		[MODIFIER_STATE_UNSELECTABLE]  = true,
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
	}
end

modifier_thdots_meira01_2_back_damage_flag = modifier_thdots_meira01_2_back_damage_flag or class({})
LinkLuaModifier("modifier_thdots_meira01_2_back_damage_flag", "scripts/vscripts/abilities/abilitymeira.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_meira01_2_back_damage_flag:IsHidden() return true end
function modifier_thdots_meira01_2_back_damage_flag:IsDebuff() return true end
function modifier_thdots_meira01_2_back_damage_flag:IsPurgable() return false end

-----------------------------------------------
--- Meira01_3

ability_thdots_meira01_3 = ability_thdots_meira01_3 or class({})

function ability_thdots_meira01_3:OnUpgrade()
	if not IsServer() then return end
	if not AbilityMeira:CheckAbility01Spells(self:GetCaster()) then return end

	AbilityMeira:OnMeira01Update(self:GetCaster(), self:GetLevel())
end

function ability_thdots_meira01_3:GetIntrinsicModifierName()
	return "modifier_meira01_swaper"
end

function ability_thdots_meira01_3:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()

	AbilityMeira:Abiltiy01SpellStart(caster)
	AbilityMeira:ExMonitorOnAbilitiesSpellStart(caster)

	local back_dur = self:GetSpecialValueFor("back_duration")
	local dash_dur = self:GetSpecialValueFor("dash_duration")

	caster:AddNewModifier(caster, self, "modifier_thdots_meira01_3_back", {
		duration = back_dur,
	})

	caster:AddNewModifier(caster, self, "modifier_thdots_meira01_3_states", {
		duration = back_dur + dash_dur,
	})

	caster:EmitCasterSound("npc_dota_hero_ember_spirit",{"Voice_Thdots_Meira.meira_ability013_01"}, 100, DOTA_CAST_SOUND_FLAG_BOTH_TEAMS, nil, nil)
end

modifier_thdots_meira01_3_states = modifier_thdots_meira01_3_states or class({})
LinkLuaModifier("modifier_thdots_meira01_3_states", "scripts/vscripts/abilities/abilitymeira.lua", LUA_MODIFIER_MOTION_BOTH)

function modifier_thdots_meira01_3_states:IsHidden() return true end
function modifier_thdots_meira01_3_states:IsPurgable() return false end

function modifier_thdots_meira01_3_states:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
	}
end

function modifier_thdots_meira01_3_states:GetAbsoluteNoDamagePhysical()
	return 1
end

function modifier_thdots_meira01_3_states:GetAbsoluteNoDamageMagical()
	return 1
end

function modifier_thdots_meira01_3_states:GetAbsoluteNoDamagePure()
	return 1
end

function modifier_thdots_meira01_3_states:CheckState()
	return {
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_MAGIC_IMMUNE]  = true,
		[MODIFIER_STATE_STUNNED]       = true,
		[MODIFIER_STATE_UNSELECTABLE]  = true,
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
	}
end

modifier_thdots_meira01_3_back = modifier_thdots_meira01_3_back or class({})
LinkLuaModifier("modifier_thdots_meira01_3_back", "scripts/vscripts/abilities/abilitymeira.lua", LUA_MODIFIER_MOTION_BOTH)

function modifier_thdots_meira01_3_back:IsPurgable() return false end

function modifier_thdots_meira01_3_back:OnCreated(param)
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	self.length = self.ability:GetSpecialValueFor("back_length")
	self.width = self.ability:GetSpecialValueFor("back_width")
	self.height = self.ability:GetSpecialValueFor("back_height")
	self.duration = param.duration

	self.direction = - self.caster:GetForwardVector()
	self.start_pos = self.caster:GetOrigin()
	self.target_pos = GetGroundPosition(self.start_pos + self.length * self.direction, nil)
	self.speed = self.length / self.duration

	self.velocity = self.direction * self.speed

	self.vertical_velocity = 4 * self.height / self.duration
	self.vertical_acceleration = - (8 * self.height) / (self.duration * self.duration)

	self.caster:RemoveHorizontalMotionController(self)

	if self:ApplyVerticalMotionController() == false then
		self:Destroy()
	end

	if self:ApplyHorizontalMotionController() == false then
		self:Destroy()
	end

	self.caster:RemoveGesture(AbilityMeira.ability01_anim[3])
	self.caster:StartGesture(AbilityMeira.ability01_anim[4])
end

function modifier_thdots_meira01_3_back:OnDestroy()
	if not IsServer() then return end

	-- Set Destination and Interrupt Motion or the unit will still move
	self.caster:RemoveHorizontalMotionController(self)
	self.caster:RemoveVerticalMotionController(self)
	FindClearSpaceForUnit(self.caster, self.target_pos, true)

	-- Dash
	self.caster:AddNewModifier(self.caster, self.ability, "modifier_thdots_meira01_3_dash", {
        duration = self.ability:GetSpecialValueFor("dash_duration"),
    })
end

function modifier_thdots_meira01_3_back:OnRefresh(params)
	self:OnCreated(params)
end

function modifier_thdots_meira01_3_back:UpdateHorizontalMotion(me, dt)
	me:SetOrigin(GetGroundPosition(me:GetOrigin() + self.velocity * dt, nil))
end

function modifier_thdots_meira01_3_back:OnHorizontalMotionInterrupted()
	self:Destroy()
end

function modifier_thdots_meira01_3_back:UpdateVerticalMotion(me, dt)
	if GetGroundHeight(self:GetParent():GetAbsOrigin(), nil) > self:GetParent():GetAbsOrigin().z then
		self.vertical_velocity = GetGroundHeight(self:GetParent():GetAbsOrigin(), nil)
		me:SetOrigin(me:GetOrigin() + Vector(0, 0, self.vertical_velocity) * dt)
	else
		me:SetOrigin(me:GetOrigin() + Vector(0, 0, self.vertical_velocity) * dt)
		self.vertical_velocity = self.vertical_velocity + (self.vertical_acceleration * dt)
	end
	local stroke_particle = ParticleManager:CreateParticle("particles/heroes/meira/ability_meira_01_3_back_branching.vpcf", PATTACH_ABSORIGIN, me)
	ParticleManager:ReleaseParticleIndex(stroke_particle)
	
end

-- -- This typically gets called if the caster uses a position breaking tool (ex. Earth Spike) while in mid-motion
function modifier_thdots_meira01_3_back:OnVerticalMotionInterrupted()
	self:Destroy()
end

modifier_thdots_meira01_3_dash = modifier_thdots_meira01_3_dash or class({})
LinkLuaModifier("modifier_thdots_meira01_3_dash", "scripts/vscripts/abilities/abilitymeira.lua", LUA_MODIFIER_MOTION_HORIZONTAL)

function modifier_thdots_meira01_3_dash:IsPurgable() return false end

function modifier_thdots_meira01_3_dash:OnCreated(param)
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	self.width = self.ability:GetSpecialValueFor("dash_width")
	self.mul = self.ability:GetSpecialValueFor("dash_mul")
	self.range = self.ability:GetSpecialValueFor("dash_range")
	self.distance = self.ability:GetSpecialValueFor("dash_distance")
	self.duration = param.duration
	self.range = 25

	self.speed = self.distance / self.duration
	self.direction = self.caster:GetForwardVector()
	self.start_pos = self.caster:GetOrigin()
	self.target_pos = self.start_pos + self.distance * self.direction

	self.velocity = self.direction * self.speed

	self.caster:RemoveHorizontalMotionController(self)

	if self:ApplyHorizontalMotionController() == false then
		self:Destroy()
	end

	self.frame_time = FrameTime()
	self:StartIntervalThink(self.frame_time)
end

function modifier_thdots_meira01_3_dash:OnIntervalThink()
	if not IsServer() then return end

	-- Push
	local range_vec = self.direction * self.range
	local cur_pos = self.caster:GetOrigin()
	local targets = FindUnitsInLine(
		self.caster:GetTeamNumber(),
		cur_pos,
		cur_pos + range_vec,
		nil,
		self.width,
		self.ability:GetAbilityTargetTeam(),
		self.ability:GetAbilityTargetType(),
		self.ability:GetAbilityTargetFlags()
	)
	local remain_time = self:GetRemainingTime()
	for _, target in ipairs(targets) do
		if not target:HasModifier("modifier_thdots_meira01_3_dash_target") then
			target:AddNewModifier(self.caster, self.ability, "modifier_thdots_meira01_3_dash_target", {
				duration = remain_time + 0.1,
				speed = self.speed,
				direction_x = self.direction.x,
				direction_y = self.direction.y,
			})
		end
	end
end

function modifier_thdots_meira01_3_dash:OnDestroy()
	if not IsServer() then return end

	-- Set Destination and Interrupt Motion or the unit will still move
	self.caster:RemoveHorizontalMotionController(self)
	self.caster:RemoveVerticalMotionController(self)
	FindClearSpaceForUnit(self.caster, self.target_pos, true)

	AbilityMeira:Abiltiy01SpellEnd(self.caster, self.ability, -1)
end

function modifier_thdots_meira01_3_dash:OnRefresh(params)
	self:OnCreated(params)
end

function modifier_thdots_meira01_3_dash:UpdateHorizontalMotion(me, dt)
	local end_point = GetGroundPosition(me:GetOrigin() + self.velocity * dt, nil)
	local start_point = me:GetOrigin()
	local forward = (end_point - start_point):Normalized()
	local distance = ( end_point - start_point ):Length2D()

	me:SetOrigin(end_point)

	local particle = ParticleManager:CreateParticle("particles/heroes/meira/ability_meira_01_3_dash_walk_preimage.vpcf", PATTACH_ABSORIGIN, me)
	ParticleManager:SetParticleControl(particle, 0, start_point)
	ParticleManager:SetParticleControl(particle, 1, me:GetAbsOrigin() + forward * distance)
	ParticleManager:SetParticleControlEnt(particle, 2, me, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", me:GetForwardVector(), true)
	ParticleManager:ReleaseParticleIndex(particle)

	local aoe_pfx = ParticleManager:CreateParticle("particles/heroes/meira/ability_meira_01_3_dash_walk_slow.vpcf", PATTACH_ABSORIGIN, me)
	ParticleManager:SetParticleControl(aoe_pfx, 1, Vector(300,300,300))
	ParticleManager:ReleaseParticleIndex(aoe_pfx)

end

function modifier_thdots_meira01_3_dash:OnHorizontalMotionInterrupted()
	self:Destroy()
end

modifier_thdots_meira01_3_dash_target = modifier_thdots_meira01_3_dash_target or class({})
LinkLuaModifier("modifier_thdots_meira01_3_dash_target", "scripts/vscripts/abilities/abilitymeira.lua", LUA_MODIFIER_MOTION_HORIZONTAL)

function modifier_thdots_meira01_3_dash_target:IsPurgable() return false end

function modifier_thdots_meira01_3_dash_target:OnCreated(param)
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()

	self.level_mul = self.ability:GetSpecialValueFor("dash_level_mul")
	self.agi_mul = self.ability:GetSpecialValueFor("dash_agi_mul")

	self.duration = param.duration
	self.speed = param.speed
	self.direction = Vector(param.direction_x, param.direction_y, 0)
	self.start_pos = self.parent:GetOrigin()
	self.target_pos = self.start_pos + self.duration * self.speed * self.direction

	self.velocity = self.direction * self.speed

	self.caster:RemoveHorizontalMotionController(self)

	if self:ApplyHorizontalMotionController() == false then
		self:Destroy()
	end
end

function modifier_thdots_meira01_3_dash_target:OnDestroy()
	if not IsServer() then return end

	-- Damage
	local damage = self.level_mul * self.ability:GetLevel() + self.agi_mul * self.caster:GetAgility()
	local damage_table = {
		ability = self.ability,
		victim = self.parent,
		attacker = self.caster,
		damage = damage,
		damage_type = self.ability:GetAbilityDamageType(),
		damage_flags = DOTA_DAMAGE_FLAG_NONE,
	}
	UnitDamageTarget(damage_table)

	-- Set Destination and Interrupt Motion or the unit will still move
	self.parent:RemoveHorizontalMotionController(self)
	self.parent:RemoveVerticalMotionController(self)
	FindClearSpaceForUnit(self.parent, self.target_pos, true)
end

function modifier_thdots_meira01_3_dash_target:OnRefresh(params)
	self:OnCreated(params)
end

function modifier_thdots_meira01_3_dash_target:UpdateHorizontalMotion(me, dt)
	me:SetOrigin(GetGroundPosition(me:GetOrigin() + self.velocity * dt, nil))
end

function modifier_thdots_meira01_3_dash_target:OnHorizontalMotionInterrupted()
	self:Destroy()
end

function modifier_thdots_meira01_3_dash_target:CheckState()
	return {
		[MODIFIER_STATE_STUNNED]       = true,
	}
end

----------------------------------------------------------------------------------------------
--- Meira02

function OnMeira02SpellStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target_entities[1]

	local offset = keys.offset
	local int_bonus = keys.int_bonus
	local stun_dur = keys.stun_dur
	local knockback_dist = keys.knockback_dist
	local knockback_dur = keys.knockback_dur
	local knockback_hei = keys.knockback_hei


	-- local step_particle = ParticleManager:CreateParticle("particles/econ/items/void_spirit/void_spirit_immortal_2021/void_spirit_immortal_2021_astral_step.vpcf", PATTACH_WORLDORIGIN, caster)
	-- ParticleManager:SetParticleControl(step_particle, 0, caster:GetAbsOrigin())
	-- ParticleManager:SetParticleControl(step_particle, 1, target:GetAbsOrigin())
	-- ParticleManager:ReleaseParticleIndex(step_particle)


	-- 02命中特效
	local particle = ParticleManager:CreateParticle("particles/heroes/meira/ability_meira_02_bash.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControlEnt(particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(particle, 2, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(particle, 4, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(particle, 5, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)

	ParticleManager:ReleaseParticleIndex(particle)

	caster:EmitSound("samuraiattack3")

	caster:EmitCasterSound("npc_dota_hero_ember_spirit",{"Voice_Thdots_Meira.meira_ability02_01"}, 100, DOTA_CAST_SOUND_FLAG_BOTH_TEAMS, nil, nil)

	-- Move
	local target_pos = target:GetOrigin()
	local destination = target_pos - target:GetForwardVector() * offset
	caster:SetOrigin(destination)
	caster:SetForwardVector((destination - target_pos):Normalized())


	-- Damage
	local damage = caster:GetIntellect(false) * int_bonus
	local damage_table = {
		ability = ability,
		victim = target,
		attacker = caster,
		damage = damage,
		damage_type = ability:GetAbilityDamageType(),
		damage_flags = ability:GetAbilityTargetFlags(),
	}
	UnitDamageTarget(damage_table)
	AbilityMeira:AbilityEXSwordSpell(caster)

	-- Knock
	local position = caster:GetOrigin()
	local knockback_properties = {
		center_x           = position.x,
		center_y           = position.y,
		center_z           = position.z,
		duration           = stun_dur + knockback_dur,
		knockback_duration = knockback_dur,
		knockback_distance = knockback_dist,
		knockback_height   = knockback_hei,
	}
	target:AddNewModifier(caster, ability, "modifier_knockback", knockback_properties)

	-- Move End
	FindClearSpaceForUnit(caster, caster:GetOrigin(), false)
end

----------------------------------------------------------------------------------------------
--- Meira03

ability_thdots_meira03 = ability_thdots_meira03 or class({})

function ability_thdots_meira03:GetChannelTime()
	return self:GetSpecialValueFor("channel_duration")
end

function ability_thdots_meira03:GetCastRange()
	return self:GetSpecialValueFor("knockback_range")
end

function ability_thdots_meira03:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()

	AbilityMeira:ExMonitorOnAbilitiesSpellStart(caster)

	caster:AddNewModifier(caster, self, "modifier_thdots_meira03_channel", {
		duration = self:GetChannelTime()
	})
end

function ability_thdots_meira03:SlashDefend()
	if not IsServer() then return end

	local caster = self:GetCaster()

	local radius = self:GetCastRange()
	local agi_mul = self:GetSpecialValueFor("agi_mul")
	local agi_pure_floor = self:GetSpecialValueFor("agi_pure_floor")
	local knockback_distance = self:GetSpecialValueFor("knockback_distance")
	local knockback_duration = self:GetSpecialValueFor("knockback_duration")
	local knockback_height = self:GetSpecialValueFor("knockback_height")

	local position = caster:GetOrigin()

	caster:Purge(false, true, false, true, false)

	caster:EmitCasterSound("npc_dota_hero_ember_spirit",{"Voice_Thdots_Meira.meira_ability03_01"}, 100, DOTA_CAST_SOUND_FLAG_BOTH_TEAMS, nil, nil)

	caster:StartGesture(ACT_DOTA_CHANNEL_END_ABILITY_3)

	-- Damage
	local targets = FindUnitsInRadius(
		caster:GetTeamNumber(),
		position,
		nil,
		radius,
		self:GetAbilityTargetTeam(),
		self:GetAbilityTargetType(),
		self:GetAbilityTargetFlags(),
		FIND_ANY_ORDER,
		false
	)
	caster:EmitSound("samuraiattack2")
	local stroke_particle = ParticleManager:CreateParticle("particles/heroes/meira/ability_meira_03_impact.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:ReleaseParticleIndex(stroke_particle)
	for _, target in ipairs(targets) do
		if caster ~= target then
			local knockback_properties = {
				center_x           = position.x,
				center_y           = position.y,
				center_z           = position.z,
				duration           = knockback_duration,
				knockback_duration = knockback_duration,
				knockback_distance = knockback_distance,
				knockback_height   = knockback_height,
			}
			target:AddNewModifier(caster, self, "modifier_knockback", knockback_properties)

			local agi = caster:GetAgility()
			local damage = caster:GetAgility() * agi_mul
			local damageTable = {
				ability = self,
				victim = target,
				attacker = caster,
				damage = damage,
				damage_type = self:GetAbilityDamageType(),
				damage_flags = self:GetAbilityTargetFlags(),
			}
			if agi > agi_pure_floor then
				damageTable.damage_type = DAMAGE_TYPE_PURE
			end
			UnitDamageTarget(damageTable)
		end
	end

	-- Modifiers
	caster:AddNewModifier(caster, self, "modifier_thdots_meira03_immune", {
		duration = self:GetSpecialValueFor("immune_duration"),
	})
end

modifier_thdots_meira03_channel = modifier_thdots_meira03_channel or class({})
LinkLuaModifier("modifier_thdots_meira03_channel", "scripts/vscripts/abilities/abilitymeira.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_meira03_channel:IsPurgable() return true end

function modifier_thdots_meira03_channel:OnCreated()
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	self.defenced = false

	self:StartIntervalThink(FrameTime())
end

function modifier_thdots_meira03_channel:OnIntervalThink()
	if not IsServer() then return end

	if AbilityMeira:InterruptChannelCheck(self.caster) then
		self.ability:EndChannel(true)
		if not self.defenced then
			-- The defenced must be at first because of reflection like medicine
			self.defenced = true
			self.ability:SlashDefend()
		end
		self:Destroy()
		return
	elseif not self.ability:IsChanneling() then
		self:Destroy()
		return
	end
end

-- function modifier_thdots_meira03_channel:CheckState()
-- 	return {
-- 		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
-- 	}
-- end

function modifier_thdots_meira03_channel:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE
	}
end

function modifier_thdots_meira03_channel:OnTakeDamage(event)
	if not IsServer() then return end

	if event.unit ~= self:GetCaster() then return end
	if not event.attacker:IsNull() and not event.attacker:IsHero() then return end
	-- if IsTHDReflect(event.attacker) then return end

	local ability = self:GetAbility()

	if ability:IsChanneling() then
		ability:EndChannel(true)
	end

	if self.defenced == nil then self.defenced = false end
	if not self.defenced then
		-- The defenced must be at first because of reflection like medicine
		self.defenced = true
		ability:SlashDefend()
		self:Destroy()
	end

	self:Destroy()
end

modifier_thdots_meira03_immune = modifier_thdots_meira03_immune or class({})
LinkLuaModifier("modifier_thdots_meira03_immune", "scripts/vscripts/abilities/abilitymeira.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_meira03_immune:CheckState()
	return {
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_MAGIC_IMMUNE] = true,
	}
end

function modifier_thdots_meira03_immune:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE
	}
end

function modifier_thdots_meira03_immune:GetAbsoluteNoDamagePhysical()
	return 1
end

function modifier_thdots_meira03_immune:GetAbsoluteNoDamageMagical()
	return 1
end

function modifier_thdots_meira03_immune:GetAbsoluteNoDamagePure()
	return 1
end

function modifier_thdots_meira03_immune:GetEffectName()
	return "particles/econ/items/omniknight/omni_ti8_head/omniknight_repel_buff_ti8.vpcf"
end

function modifier_thdots_meira03_immune:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

----------------------------------------------------------------------------------------------
--- MeiraEX

--- Monitor and Functions
function AbilityMeira:ExMonitorOnAbilitiesSpellStart(caster)
	local ability = caster:FindAbilityByName("ability_thdots_meiraEx")
	if ability ~= nil then
		ability:MonitorOnAbilitiesSpellStart()
	end
end

function AbilityMeira:GetAbility04Level(caster)
	local ability = caster:FindAbilityByName("ability_thdots_meira04_1")
	if ability ~= nil then
		return ability:GetLevel()
	else
		return -1
	end
end

--- Ability
--- Define
ability_thdots_meiraEx = ability_thdots_meiraEx or class({})

--- Behavior
function ability_thdots_meiraEx:GetBehavior()
	local caster = self:GetCaster()
	local behavior = DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES
	-- level 1
	if AbilityMeira:GetAbility04Level(caster) < 1 then
		behavior = behavior + DOTA_ABILITY_BEHAVIOR_PASSIVE
	else
		behavior = behavior + DOTA_ABILITY_BEHAVIOR_NO_TARGET
	end
	return behavior
end

--- The Realise of Dark Power of Sword
function ability_thdots_meiraEx:SwordSpell()
	if not IsServer() then return end

	local caster = self:GetCaster()

	local width = self:GetSpecialValueFor("A_damage_wid")
	local length = self:GetSpecialValueFor("A_damage_len")
	local str_mul = self:GetSpecialValueFor("A_damage_str_mul")
	local damage_mul = self:GetSpecialValueFor("A_damage_mul")

	local start_pos = caster:GetOrigin()
	local end_pos = start_pos + caster:GetForwardVector() * length

	--黑暗剑气特效
	local stroke_particle = ParticleManager:CreateParticle("particles/heroes/meira/ability_meira_ex_diffusal.vpcf", PATTACH_ABSORIGIN, self:GetCaster())
	ParticleManager:ReleaseParticleIndex(stroke_particle)

	local targets = FindUnitsInLine(
		caster:GetTeamNumber(),
		start_pos,
		end_pos,
		nil,
		width,
		self:GetAbilityTargetTeam(),
		self:GetAbilityTargetType(),
		self:GetAbilityTargetFlags()
	)
	local damage = caster:GetStrength() * str_mul
	damage = damage * damage_mul
	for _, target in ipairs(targets) do
		local damage_table = {
			ability = self,
			victim = target,
			attacker = caster,
			damage = damage,
			damage_type = self:GetAbilityDamageType(),
			damage_flags = DOTA_DAMAGE_FLAG_NONE,
		}
		UnitDamageTarget(damage_table)
	end
end

--- Passive of effect on spell starting
function ability_thdots_meiraEx:MonitorOnAbilitiesSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()

	if not caster:HasModifier("modifier_thdots_meiraex_attack") then
		caster:AddNewModifier(caster, self, "modifier_thdots_meiraex_attack", {})
	end
end

--- Active at that level is equal to 1
function ability_thdots_meiraEx:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()

	AbilityMeira:ExMonitorOnAbilitiesSpellStart(caster)

	caster:AddNewModifier(caster, self, "modifier_thdots_meiraex_jump", {
		duration = self:GetSpecialValueFor("B_jump_dur"),
	})

	caster:EmitCasterSound("npc_dota_hero_ember_spirit",{"Voice_Thdots_Meira.meira_ability04_01"}, 100, DOTA_CAST_SOUND_FLAG_BOTH_TEAMS, 5, "meiraEx")
end

--- Modifiers
--- Attack Effect
modifier_thdots_meiraex_attack = modifier_thdots_meiraex_attack or class({})
LinkLuaModifier("modifier_thdots_meiraex_attack", "scripts/vscripts/abilities/abilitymeira.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_meiraex_attack:IsPurgable() return false end

function modifier_thdots_meiraex_attack:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_thdots_meiraex_attack:OnAttackLanded(event)
	if not IsServer() then return end

	if event.attacker ~= self:GetCaster() then return end

	AbilityMeira:AbilityEXSwordSpell(self:GetCaster())
	

	self:Destroy()
end

function modifier_thdots_meiraex_attack:OnCreated()
	if not IsServer() then return end
	self.shadow_particle = ParticleManager:CreateParticle("particles/heroes/meira/ability_meira_ex_blade.vpcf", PATTACH_POINT_FOLLOW,self:GetCaster())
    ParticleManager:SetParticleControlEnt(self.shadow_particle,0,self:GetCaster(),PATTACH_POINT_FOLLOW,"attach_attack2",Vector(0,0,0),true)
    ParticleManager:SetParticleControlEnt(self.shadow_particle,1,self:GetCaster(),PATTACH_POINT_FOLLOW,"attach_attack2",Vector(0,0,0),true)
    ParticleManager:SetParticleControlEnt(self.shadow_particle,2,self:GetCaster(),PATTACH_POINT_FOLLOW,"attach_attack2",Vector(0,0,0),true)
    ParticleManager:SetParticleControlEnt(self.shadow_particle,3,self:GetCaster(),PATTACH_POINT_FOLLOW,"attach_attack2",Vector(0,0,0),true)
    ParticleManager:SetParticleControlEnt(self.shadow_particle,4,self:GetCaster(),PATTACH_POINT_FOLLOW,"attach_attack2",Vector(0,0,0),true)

end

function modifier_thdots_meiraex_attack:OnDestroy()
	if not IsServer() then return end
	ParticleManager:DestroyParticleSystem(self.shadow_particle,true)
end

--- Jump Modifier
modifier_thdots_meiraex_jump = modifier_thdots_meiraex_jump or class({})
LinkLuaModifier("modifier_thdots_meiraex_jump", "scripts/vscripts/abilities/abilitymeira.lua", LUA_MODIFIER_MOTION_BOTH)

function modifier_thdots_meiraex_jump:IsPurgable() return false end

function modifier_thdots_meiraex_jump:OnCreated()
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	self.distance = self.ability:GetSpecialValueFor("B_jump_dist")
	self.direction = self.caster:GetForwardVector()
	self.duration = self.ability:GetSpecialValueFor("B_jump_dur")
	self.height = self.ability:GetSpecialValueFor("B_jump_hei")

	self.velocity = self.direction * self.distance / self.duration

	self.vertical_velocity = 4 * self.height / self.duration
	self.vertical_acceleration = -(8 * self.height) / (self.duration * self.duration)

	self.caster:RemoveHorizontalMotionController(self)

	if self:ApplyVerticalMotionController() == false then
		self:Destroy()
	end

	-- Do NOT continue with motion controllers if rooted; trying to be finnicky with this will cause crashes
	if self.caster:IsRooted() then return end

	if self:ApplyHorizontalMotionController() == false then
		self:Destroy()
	end
end

function modifier_thdots_meiraex_jump:OnDestroy()
	if not IsServer() then return end

	self.caster:RemoveHorizontalMotionController(self)
	self.caster:RemoveVerticalMotionController(self)

	FindClearSpaceForUnit(self.caster, self.caster:GetOrigin(), false)
end

function modifier_thdots_meiraex_jump:UpdateHorizontalMotion(me, dt)
	me:SetOrigin(me:GetOrigin() + self.velocity * dt)
end

--- This typically gets called if the caster uses a position breaking tool (ex. Blink Dagger) while in mid-motion
function modifier_thdots_meiraex_jump:OnHorizontalMotionInterrupted()
	self:Destroy()
end

function modifier_thdots_meiraex_jump:UpdateVerticalMotion(me, dt)
	if GetGroundHeight(self:GetParent():GetAbsOrigin(), nil) > self:GetParent():GetAbsOrigin().z then
		self.vertical_velocity = GetGroundHeight(self:GetParent():GetAbsOrigin(), nil)
		me:SetOrigin(me:GetOrigin() + Vector(0, 0, self.vertical_velocity) * dt)
	else
		me:SetOrigin(me:GetOrigin() + Vector(0, 0, self.vertical_velocity) * dt)
		self.vertical_velocity = self.vertical_velocity + (self.vertical_acceleration * dt)
	end
end

--- This typically gets called if the caster uses a position breaking tool (ex. Earth Spike) while in mid-motion
function modifier_thdots_meiraex_jump:OnVerticalMotionInterrupted()
	self:Destroy()
end

function modifier_thdots_meiraex_jump:CheckState()
	return {
		[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_MAGIC_IMMUNE] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
	}
end

function modifier_thdots_meiraex_jump:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE
	}
end

function modifier_thdots_meiraex_jump:GetAbsoluteNoDamagePhysical()
	return 1
end

function modifier_thdots_meiraex_jump:GetAbsoluteNoDamageMagical()
	return 1
end

function modifier_thdots_meiraex_jump:GetAbsoluteNoDamagePure()
	return 1
end

function modifier_thdots_meiraex_jump:GetEffectName()
	return "particles/heroes/meira/ability_meira_01_3_back_branching.vpcf"
end
function modifier_thdots_meiraex_jump:GetEffectAttachType()
	return "follow_origin"
end

----------------------------------------------------------------------------------------------
--- Meira04

modifier_thdots_meira04_swarper = modifier_thdots_meira04_swarper or class({})
LinkLuaModifier("modifier_thdots_meira04_swarper", "scripts/vscripts/abilities/abilitymeira.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_meira04_swarper:IsHidden() return true end
function modifier_thdots_meira04_swarper:IsPurgable() return false end

function modifier_thdots_meira04_swarper:ValidAbilityLevel()
	local caster = self:GetCaster()
	local ability04 = caster:FindAbilityByName("ability_thdots_meira04_1")
	if ability04 ~= nil and ability04:GetLevel() >= 3 then
		return true
	else
		return false
	end
end

function modifier_thdots_meira04_swarper:SwapAbility(enable01, enable02)
	local caster = self:GetCaster()

	if self:ValidAbilityLevel() then
		caster:SwapAbilities("ability_thdots_meira04_1", "ability_thdots_meira04_2", enable01, enable02)
	else
		self:Destroy()
	end
end

function modifier_thdots_meira04_swarper:OnCreated()
	if not IsServer() then return end

	self:SwapAbility(false, true)
end

function modifier_thdots_meira04_swarper:OnDestroy()
	if not IsServer() then return end

	self:SwapAbility(true, false)
end

----------------------------------------------------------------------------------------------
--- Meira04_1

ability_thdots_meira04_1 = ability_thdots_meira04_1 or class({})

function ability_thdots_meira04_1:GetCastPoint()
	return self:GetSpecialValueFor("cast_point")
end

function ability_thdots_meira04_1:OnUpgrade()
	if not IsServer() then return end

	local ability = self:GetCaster():FindAbilityByName("ability_thdots_meira04_2")

	if ability == nil then return end

	if ability:GetLevel() ~= self:GetLevel() then
		ability:SetLevel(self:GetLevel())
	end
end

function ability_thdots_meira04_1:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	AbilityMeira:ExMonitorOnAbilitiesSpellStart(caster)

	local cast_dur = self:GetSpecialValueFor("cast_dur")
	local rear_dist = self:GetSpecialValueFor("rear_dist")

	local target_pos = target:GetOrigin()
	local destination = target_pos - target:GetForwardVector() * rear_dist
	local next_dire = - (target:GetOrigin() - destination):Normalized()
	caster:SetOrigin(destination)
	caster:SetForwardVector(next_dire)
	caster:MoveToPosition(destination + next_dire)

	local rad = GetRadBetweenTwoVec2D(caster:GetOrigin(),target:GetOrigin())
	local tarForward = Vector(math.cos(rad),math.sin(rad),0)

	local impact_particle = ParticleManager:CreateParticle("particles/heroes/meira/ability_meira_04_1_glow.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
		ParticleManager:SetParticleControlEnt(impact_particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(impact_particle, 5, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
		ParticleManager:ReleaseParticleIndex(impact_particle)


	caster:AddNewModifier(caster, self, "modifier_thdots_meira04_1_caster", {
		duration = cast_dur,
	})
	target:AddNewModifier(caster, self, "modifier_thdots_meira04_1_target", {
		duration = cast_dur,
	})

	caster:EmitCasterSound("npc_dota_hero_ember_spirit",{"Voice_Thdots_Meira.meira_ability061_01"}, 100, DOTA_CAST_SOUND_FLAG_BOTH_TEAMS, nil, nil)
end

modifier_thdots_meira04_1_caster = modifier_thdots_meira04_1_caster or class({})
LinkLuaModifier("modifier_thdots_meira04_1_caster", "scripts/vscripts/abilities/abilitymeira.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_meira04_1_caster:IsPurgable() return false end

function modifier_thdots_meira04_1_caster:OnDestroy()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local ability = self:GetAbility()

	caster:AddNewModifier(caster, ability, "modifier_thdots_meira04_swarper", {
		duration = ability:GetSpecialValueFor("next_time"),
	})

	FindClearSpaceForUnit(caster, caster:GetOrigin(), false)
end

function modifier_thdots_meira04_1_caster:CheckState()
	return {
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_MAGIC_IMMUNE] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_STUNNED] = true,
	}
end

function modifier_thdots_meira04_1_caster:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}
end

function modifier_thdots_meira04_1_caster:GetAbsoluteNoDamagePhysical()
	return 1
end

function modifier_thdots_meira04_1_caster:GetAbsoluteNoDamageMagical()
	return 1
end

function modifier_thdots_meira04_1_caster:GetAbsoluteNoDamagePure()
	return 1
end

function modifier_thdots_meira04_1_caster:GetOverrideAnimation()
	return ACT_DOTA_CHANNEL_ABILITY_6
end

modifier_thdots_meira04_1_target = modifier_thdots_meira04_1_target or class({})
LinkLuaModifier("modifier_thdots_meira04_1_target", "scripts/vscripts/abilities/abilitymeira.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_meira04_1_target:IsDebuff() return true end
function modifier_thdots_meira04_1_target:IsPurgable() return false end

function modifier_thdots_meira04_1_target:CheckState()
	return {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_STUNNED] = true,
	}
end

function modifier_thdots_meira04_1_target:OnCreated()
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()
	self.target = self:GetParent()

	self.str_mul = self.ability:GetSpecialValueFor("str_mul")
	self.agi_mul = self.ability:GetSpecialValueFor("agi_mul")
	self.int_mul = self.ability:GetSpecialValueFor("int_mul")
	self.damage_const = self.ability:GetSpecialValueFor("damage_const")
	self.damage_int = self.ability:GetSpecialValueFor("damage_int")

	self.damage_time = 0
	self:StartIntervalThink(self.damage_int)
end

function modifier_thdots_meira04_1_target:OnIntervalThink()
	if not IsServer() then return end

	local damage = self.damage_const
	if self.damage_time == 0 then
		damage = damage + self.caster:GetStrength() * self.str_mul
	elseif self.damage_time == 1 then
		damage = damage + self.caster:GetAgility() * self.agi_mul
	elseif self.damage_time == 2 then
		damage = damage + self.caster:GetIntellect(false) * self.int_mul
	end
	self.damage_time = self.damage_time + 1
	self:SetStackCount(self.damage_time)

	-- 命中特效
	local particle = ParticleManager:CreateParticle("particles/heroes/meira/ability_meira_hit_blood.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.target)
	ParticleManager:ReleaseParticleIndex(particle)
	self.caster:EmitSound("samuraiattack1")
	local damageTable = {
		ability = self.ability,
		victim = self.target,
		attacker = self.caster,
		damage = damage,
		damage_type = self.ability:GetAbilityDamageType(),
		damage_flags = self.ability:GetAbilityTargetFlags(),
	}
	UnitDamageTarget(damageTable)
end

function modifier_thdots_meira04_1_target:OnDestroy()
	if not IsServer() then return end

	self.target:AddNewModifier(self.caster, self.ability, "modifier_thdots_meira04_1_speed_bonus", {
		duration = self.ability:GetSpecialValueFor("speed_dur")
	})
end

modifier_thdots_meira04_1_speed_bonus = modifier_thdots_meira04_1_speed_bonus or class({})
LinkLuaModifier("modifier_thdots_meira04_1_speed_bonus", "scripts/vscripts/abilities/abilitymeira.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_meira04_1_speed_bonus:IsDebuff() return true end
function modifier_thdots_meira04_1_speed_bonus:IsPurgable() return false end

function modifier_thdots_meira04_1_speed_bonus:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE,
	}
end

function modifier_thdots_meira04_1_speed_bonus:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("speed_pct")
end

function modifier_thdots_meira04_1_speed_bonus:GetModifierAttackSpeedPercentage()
	return self:GetAbility():GetSpecialValueFor("speed_pct")
end

----------------------------------------------------------------------------------------------
--- Meira04_2

ability_thdots_meira04_2 = ability_thdots_meira04_2 or class({})

function ability_thdots_meira04_2:OnUpgrade()
	if not IsServer() then return end

	local ability = self:GetCaster():FindAbilityByName("ability_thdots_meira04_2")

	if ability == nil then return end

	if ability:GetLevel() ~= self:GetLevel() then
		ability:SetLevel(self:GetLevel())
	end
end

function ability_thdots_meira04_2:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()

	AbilityMeira:ExMonitorOnAbilitiesSpellStart(caster)

	if caster:HasModifier("modifier_thdots_meira04_swarper") then
		caster:RemoveModifierByName("modifier_thdots_meira04_swarper")
	end

	caster:AddNewModifier(caster, self, "modifier_thdots_meira04_2_slash", {
		duration = self:GetSpecialValueFor("duration")
	})

	caster:EmitCasterSound("npc_dota_hero_ember_spirit",{"Voice_Thdots_Meira.meira_ability062_01"}, 100, DOTA_CAST_SOUND_FLAG_BOTH_TEAMS, nil, nil)
end

modifier_thdots_meira04_2_slash = modifier_thdots_meira04_2_slash or class({})
LinkLuaModifier("modifier_thdots_meira04_2_slash", "scripts/vscripts/abilities/abilitymeira.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_meira04_2_slash:OnCreated()
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	self.basic_damage = self.ability:GetSpecialValueFor("basic_damage")
	self.agi_mul = self.ability:GetSpecialValueFor("agi_mul")
	self.length = self.ability:GetSpecialValueFor("length")

	local origin_pos = self.caster:GetOrigin()
	local distance = self.ability:GetSpecialValueFor("distance")
	local length = math.cos(45) * distance * 2
	local direction = RotatePosition(Vector(0, 0, 0), QAngle(0, 45, 0), self.caster:GetForwardVector())
	self.start_pos = origin_pos - length * direction
	self.end_pos = origin_pos + length * direction
	self.width = length
end

function modifier_thdots_meira04_2_slash:OnDestroy()
	if not IsServer() then return end

	-- Damage
	local targets = FindUnitsInLine(
		self.caster:GetTeamNumber(),
		self.start_pos,
		self.end_pos,
		nil,
		self.width,
		self.ability:GetAbilityTargetTeam(),
		self.ability:GetAbilityTargetType(),
		self.ability:GetAbilityTargetFlags()
	)
	local damage = self.basic_damage + self.caster:GetAgility() * self.agi_mul

	local particle = ParticleManager:CreateParticle("particles/heroes/meira/ability_meira_04_2_impact_ring.vpcf", PATTACH_POINT, self.caster)
	ParticleManager:SetParticleControl(particle, 1, self.caster:GetOrigin())
	ParticleManager:ReleaseParticleIndex(particle)
	self.caster:EmitSound("samuraiattack3")
	for _, target in ipairs(targets) do
		local damage_table = {
			ability = self.ability,
			victim = target,
			attacker = self.caster,
			damage = damage,
			damage_type = self.ability:GetAbilityDamageType(),
			damage_flags = DOTA_DAMAGE_FLAG_NONE,
		}
		UnitDamageTarget(damage_table)
	end

	-- Move
	FindClearSpaceForUnit(self.caster, self.caster:GetOrigin(), false)
end

function modifier_thdots_meira04_2_slash:CheckState()
	return {
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_MAGIC_IMMUNE] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_STUNNED] = true,
	}
end

function modifier_thdots_meira04_2_slash:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}
end

function modifier_thdots_meira04_2_slash:GetAbsoluteNoDamagePhysical()
	return 1
end

function modifier_thdots_meira04_2_slash:GetAbsoluteNoDamageMagical()
	return 1
end

function modifier_thdots_meira04_2_slash:GetAbsoluteNoDamagePure()
	return 1
end

function modifier_thdots_meira04_2_slash:GetOverrideAnimation()
	return ACT_DOTA_CHANNEL_END_ABILITY_4
end

function modifier_thdots_meira04_2_slash:GetEffectName()
	return "particles/heroes/meira/ability_meira_04_2_effect.vpcf"
end

function modifier_thdots_meira04_2_slash:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

----------------------------------------------------------------------------------------------
--- Meira05

ability_thdots_meira05 = ability_thdots_meira05 or class({})

function ability_thdots_meira05:GetChannelTime()
	return self:GetSpecialValueFor("duration")
end

function ability_thdots_meira05:GetChannelAnimation()
	if not IsServer() then return end

	return ACT_DOTA_CHANNEL_ABILITY_3
end

function ability_thdots_meira05:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()

	AbilityMeira:ExMonitorOnAbilitiesSpellStart(caster)

	caster:AddNewModifier(caster, self, "modifier_thdots_meira05_medit", {
		duration = self:GetSpecialValueFor("duration"),
	})
end

modifier_thdots_meira05_medit = modifier_thdots_meira05_medit or class({})
LinkLuaModifier("modifier_thdots_meira05_medit", "scripts/vscripts/abilities/abilitymeira.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_meira05_medit:OnCreated()
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	self.immue_dur = self.ability:GetSpecialValueFor("immune_dur")

	self.defenced = false

	self:StartIntervalThink(FrameTime())
end

function modifier_thdots_meira05_medit:OnIntervalThink()
	if not IsServer() then return end

	if self.defenced then
		self:Destroy()
		return
	end

	if AbilityMeira:InterruptChannelCheck(self.caster) then
		if self.ability:IsChanneling() then
			self.ability:EndChannel(true)
		end

		if not self.defenced then
			local ability03 = self.caster:FindAbilityByName("ability_thdots_meira03")
			if ability03 ~= nil and ability03:GetLevel() >= 1 then
				-- The defenced must be at first because of reflection like medicine
				self.defenced = true
				ability03:SlashDefend()
			end

			self.caster:Purge(false, true, false, true, false)
		end

		self:Destroy()
	elseif not self.ability:IsChanneling() then
		self:Destroy()
	end
end

function modifier_thdots_meira05_medit:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
	}
end

function modifier_thdots_meira05_medit:OnTakeDamage(event)
	if not IsServer() then return end

	if event.unit ~= self:GetCaster() then return end
	if not event.attacker:IsHero() then return end
	-- if IsTHDReflect(event.attacker) then return end

	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local target = event.attacker

	if ability:IsChanneling() then
		ability:EndChannel(false)
	end

	if self.defenced == nil then self.defenced = false end
	if self.defenced then
		self:Destroy()
		return
	end
	self.defenced = true

	-- move
	local forward_vector = target:GetForwardVector()
	caster:SetOrigin(target:GetOrigin() - forward_vector * ability:GetSpecialValueFor("rear_dist"))
	caster:SetForwardVector(forward_vector)
	caster:StartGesture(ACT_DOTA_CHANNEL_END_ABILITY_3)

	caster:EmitSound("samuraiattack2")
	-- 命中特效
	local impact_particle = ParticleManager:CreateParticle("particles/econ/items/centaur/centaur_ti9/centaur_double_edge_ti9_hit_src.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControlEnt(impact_particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(impact_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(impact_particle, 2, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(impact_particle, 3, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(impact_particle, 4, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(impact_particle, 5, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(impact_particle, 9, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(impact_particle)

	-- damage
	for _ = 1, ability:GetSpecialValueFor("damage_time") do
		AbilityMeira:AbilityEXSwordSpell(caster)
	end

	-- immue
	caster:Purge(false, true, false, true, false)
	caster:AddNewModifier(caster, ability, "modifier_thdots_meira05_immune", {
		duration = ability:GetSpecialValueFor("immune_dur"),
	})

	-- refresh cooldown
	local abilityex = caster:FindAbilityByName("ability_thdots_meiraEx")
	if abilityex ~= nil then
		abilityex:EndCooldown()
	end

	self:Destroy()
end

function modifier_thdots_meira05_medit:GetModifierIncomingDamage_Percentage()
	return - self:GetAbility():GetSpecialValueFor("damage_rad_pct")
end

modifier_thdots_meira05_immune = modifier_thdots_meira05_immune or class({})
LinkLuaModifier("modifier_thdots_meira05_immune", "scripts/vscripts/abilities/abilitymeira.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_meira05_immune:OnCreated()
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	self:StartIntervalThink(FrameTime())
end

function modifier_thdots_meira05_immune:OnIntervalThink()
	if not IsServer() then return end

	self.caster:Purge(false, true, false, true, false)
end

function modifier_thdots_meira05_immune:CheckState()
	return {
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_MAGIC_IMMUNE] = true,
	}
end

function modifier_thdots_meira05_immune:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE
	}
end

function modifier_thdots_meira05_immune:GetAbsoluteNoDamagePhysical()
	return 1
end

function modifier_thdots_meira05_immune:GetAbsoluteNoDamageMagical()
	return 1
end

function modifier_thdots_meira05_immune:GetAbsoluteNoDamagePure()
	return 1
end

function modifier_thdots_meira05_immune:GetEffectName()
	return "particles/econ/items/omniknight/omni_ti8_head/omniknight_repel_buff_ti8.vpcf"
end

function modifier_thdots_meira05_immune:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end