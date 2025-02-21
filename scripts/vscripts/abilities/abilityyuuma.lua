
ability_thdots_yuumaEx = {}

function ability_thdots_yuumaEx:InnateAbilityType()
	return 1
end

function ability_thdots_yuumaEx:GetIntrinsicModifierName()
	return "modifier_thdots_yuumaEx_passive"
end

modifier_thdots_yuumaEx_passive = {}
LinkLuaModifier("modifier_thdots_yuumaEx_passive","scripts/vscripts/abilities/abilityyuuma.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_thdots_yuumaEx_passive:IsHidden()			return true end
function modifier_thdots_yuumaEx_passive:IsPurgable()		return false end
function modifier_thdots_yuumaEx_passive:RemoveOnDeath()	return false end
function modifier_thdots_yuumaEx_passive:IsDebuff()			return false end

function modifier_thdots_yuumaEx_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
	}
end

function modifier_thdots_yuumaEx_passive:OnCreated()
	if not IsServer() then return end
	self.parent = self:GetParent()
	self.yuuma02 = self.parent:FindAbilityByName("ability_thdots_yuuma02")

	self.tick_rate	= self:GetAbility():GetSpecialValueFor("tick_rate")
	self.curr_hp_loss_pct	= self:GetAbility():GetSpecialValueFor("curr_hp_loss_pct")
	self.hp_threshold	= self:GetAbility():GetSpecialValueFor("hp_threshold")
	self.lower_hp_loss_pct	= self:GetAbility():GetSpecialValueFor("lower_hp_loss_pct")

	self.every_max_hp	= self:GetAbility():GetSpecialValueFor("every_max_hp")
	self.as_every_max_hp	= self:GetAbility():GetSpecialValueFor("as_every_max_hp")
	self.every_loss_hp	= self:GetAbility():GetSpecialValueFor("every_loss_hp")
	self.as_every_loss_hp	= self:GetAbility():GetSpecialValueFor("as_every_loss_hp")

	if not self.timer then
		self:StartIntervalThink(self.tick_rate)
		self.timer = true
	end
end

function modifier_thdots_yuumaEx_passive:OnIntervalThink()
	if not IsServer() then return end

	-- Calculates damage
	local hp_loss = self.curr_hp_loss_pct
	if self.parent:GetHealth() < self.parent:GetMaxHealth()*self.hp_threshold/100 then
		hp_loss = hp_loss*self.lower_hp_loss_pct/100
	end

	local damage = self.parent:GetHealth() * (hp_loss * self.tick_rate) / 100

	ApplyDamage({attacker = self.parent, victim = self.parent, ability = self:GetAbility(), damage = damage, damage_type = DAMAGE_TYPE_PURE,
	damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS + DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY})

	-- 2技能护盾
	if self.yuuma02 and self.yuuma02:GetLevel() ~= 0 and not self.parent:PassivesDisabled() then
		local maxShield = self.parent:GetMaxHealth()*self.yuuma02:GetSpecialValueFor("maxShield_maxHP_pct")/100

		local shield_remaining = damage*self.yuuma02:GetSpecialValueFor("selfcostToShield_pct")/100

		if not self.parent:HasModifier("modifier_thdots_yuuma02_shield") then
			self.parent:AddNewModifier(self.parent, self.yuuma02, "modifier_thdots_yuuma02_shield", {duration = -1, shield_remaining = shield_remaining})
		else
			local shield_modifier = self.parent:FindModifierByName("modifier_thdots_yuuma02_shield")
			local currShield = shield_modifier:GetStackCount()
			if not (currShield >= maxShield) then
				if currShield + shield_remaining > maxShield then
					shield_modifier:SetStackCount(maxShield)
				else
					shield_modifier:SetStackCount(currShield + shield_remaining)
				end
			end
		end
	end
end

function modifier_thdots_yuumaEx_passive:GetModifierAttackSpeedBonus_Constant()
	local parent = self:GetParent()
	if not parent:PassivesDisabled() then

		-- 最大生命值增加攻速
		local maxHp = parent:GetMaxHealth()
		local every_max_hp = self:GetAbility():GetSpecialValueFor("every_max_hp")
		local maxHp_attackSpeed = (maxHp - maxHp % every_max_hp) / every_max_hp*self:GetAbility():GetSpecialValueFor("as_every_max_hp")

		-- 损失生命值增加攻速
		local lostHp = parent:GetMaxHealth()-parent:GetHealth()
		local every_loss_hp = self:GetAbility():GetSpecialValueFor("every_loss_hp")
		local lossHp_attackSpeed = (lostHp - lostHp % every_loss_hp) / every_loss_hp*self:GetAbility():GetSpecialValueFor("as_every_loss_hp")

		return maxHp_attackSpeed + lossHp_attackSpeed
	else
		return 0
	end
end

ability_thdots_yuuma01 = {}

-- 生命消耗
function ability_thdots_yuuma01:GetHealthCost(iLevel)
	return self:GetCaster():GetHealth()*self:GetSpecialValueFor("curr_hp_cost")/100
end

--------------------------------------------------------------------------------
-- Init Abilities
function ability_thdots_yuuma01:Spawn()
	-- register custom indicator
	if not IsServer() then
		CustomIndicator:RegisterAbility( self )
		return
	end
end

--------------------------------------------------------------------------------
-- Ability Custom Indicator (using CustomIndicator library, this section is Client Lua only)
function ability_thdots_yuuma01:CreateCustomIndicator(loc)
	local particle_cast = "particles/units/heroes/hero_primal_beast/primal_beast_rock_throw_range_finder_aoe.vpcf"

	local min_range = self:GetSpecialValueFor("min_chose_range")

	-- 最小选择距离特效
	self.effect_cast = ParticleManager:CreateParticle(particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControl( self.effect_cast, 6, Vector( min_range, min_range, min_range ) )

	-- references
	local effect_end_radius = "particles/ui_mouseactions/range_finder_aoe.vpcf"
	-- get data
	local radius = self:GetSpecialValueFor( "end_radius" )
	-- create particle 范围特效
	self.effect_end_radius = ParticleManager:CreateParticle( effect_end_radius, PATTACH_WORLDORIGIN, self:GetCaster())
	ParticleManager:SetParticleControl( self.effect_end_radius, 3, Vector( radius, radius, radius ) )

	self:UpdateCustomIndicator( loc )
end

function ability_thdots_yuuma01:UpdateCustomIndicator(loc)
	-- get data
	local origin = self:GetCaster():GetAbsOrigin()
	local min_chose_range = self:GetSpecialValueFor("min_chose_range")

	-- limit distance
	local direction = (loc-origin)
	direction.z = 0
	if direction:Length2D()<min_chose_range then
		loc = origin + direction:Normalized() * min_chose_range
	end

	ParticleManager:SetParticleControl(self.effect_cast, 0, origin)

	ParticleManager:SetParticleControl(self.effect_end_radius, 2, loc)
end

function ability_thdots_yuuma01:DestroyCustomIndicator()
	ParticleManager:DestroyParticle(self.effect_cast, true)
	ParticleManager:ReleaseParticleIndex(self.effect_cast)

	ParticleManager:DestroyParticle(self.effect_end_radius, true)
	ParticleManager:ReleaseParticleIndex(self.effect_end_radius)
end

function ability_thdots_yuuma01:OnAbilityPhaseStart()
	if not IsServer() then return end

	-- 记录消耗的生命
	self.healthCost = self:GetCaster():GetHealth()*self:GetSpecialValueFor("curr_hp_cost")/100
	local cost_hp_to_damage = self:GetSpecialValueFor("cost_hp_to_damage")
	self.bonusDamage = self.healthCost * cost_hp_to_damage / 100
end

function ability_thdots_yuuma01:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	self.start_origin = caster:GetOrigin()
	self.yuuma02 = caster:FindAbilityByName("ability_thdots_yuuma02")

	-- 2技能护盾
	if self.yuuma02 and self.yuuma02:GetLevel() ~= 0 and not caster:PassivesDisabled() then
		local maxShield = caster:GetMaxHealth()*self.yuuma02:GetSpecialValueFor("maxShield_maxHP_pct")/100

		local shield_remaining = self.healthCost*self.yuuma02:GetSpecialValueFor("selfcostToShield_pct")/100

		if not caster:HasModifier("modifier_thdots_yuuma02_shield") then
			caster:AddNewModifier(caster, self.yuuma02, "modifier_thdots_yuuma02_shield", {duration = -1, shield_remaining = shield_remaining})
		else
			local shield_modifier = caster:FindModifierByName("modifier_thdots_yuuma02_shield")
			local currShield = shield_modifier:GetStackCount()
			if not (currShield >= maxShield) then
				if currShield + shield_remaining > maxShield then
					shield_modifier:SetStackCount(maxShield)
				else
					shield_modifier:SetStackCount(currShield + shield_remaining)
				end
			end
		end
	end

	-- 防止在脚下施放
	if self:GetCursorPosition() == caster:GetAbsOrigin() then
		caster:SetCursorPosition(self:GetCursorPosition() + caster:GetForwardVector())
	end

	local target_pos = self:GetCursorPosition()

	local cast_range = self:GetSpecialValueFor("cast_range") + caster:GetCastRangeBonus()
	local min_chose_range = self:GetSpecialValueFor("min_chose_range")

	-- 距离限制
	local end_distance = math.abs(GetDistanceBetweenTwoVec2D(self.start_origin, target_pos))
	if end_distance > cast_range then
		end_distance = cast_range
	elseif end_distance < min_chose_range then
		end_distance = min_chose_range
	end

	self.direction = (target_pos - self.start_origin):Normalized()
	self.direction.z = 0

	-- 终点位置
	self.end_pos = self.start_origin + self.direction*end_distance

	caster:SetForwardVector(self.direction)
	caster:AddNewModifier(caster, self, "modifier_thdots_yuuma01_jump", {})
end

-- 起跳modifier
modifier_thdots_yuuma01_jump = {}
LinkLuaModifier("modifier_thdots_yuuma01_jump","scripts/vscripts/abilities/abilityyuuma.lua",LUA_MODIFIER_MOTION_BOTH)

function modifier_thdots_yuuma01_jump:IsHidden()			return true end
function modifier_thdots_yuuma01_jump:IsPurgable()			return false end
function modifier_thdots_yuuma01_jump:RemoveOnDeath()		return false end
function modifier_thdots_yuuma01_jump:IsDebuff()			return false end
function modifier_thdots_yuuma01_jump:GetAttributes()		return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

function modifier_thdots_yuuma01_jump:CheckState()
	return {
		[MODIFIER_STATE_STUNNED]	= true,
	}
end

function modifier_thdots_yuuma01_jump:OnCreated(keys)
	if not IsServer() then return end

	-- 记录击中的目标
	self.hitTargets = {}

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	-- 打断移动相关
	self.enableDown = false

	self.start_radius = self.ability:GetSpecialValueFor("start_radius")

	self.distance = self.ability:GetSpecialValueFor("jump_range")
	self.height = self.ability:GetSpecialValueFor("jump_height")
	self.duration = self.ability:GetSpecialValueFor("jump_duration")

	self.direction = self.ability.direction
	self.speed = self.ability:GetSpecialValueFor("jump_hSpeed")

	-- 水平速度
	self.velocity = self.direction * self.speed

	-- 垂直速度
	self.vertical_velocity = 4 * self.height / self.duration
	self.vertical_acceleration = - (8 * self.height) / (self.duration * self.duration)

	self.caster:RemoveHorizontalMotionController(self)
	self.caster:RemoveVerticalMotionController(self)

	if self:ApplyVerticalMotionController() == false then
		self:Destroy()
	end

	if self:ApplyHorizontalMotionController() == false then
		self:Destroy()
	end

	-- 模拟转勺子特效
	self.spinParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_juggernaut/juggernaut_blade_fury.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.caster)
	ParticleManager:SetParticleControl(self.spinParticle, 5, Vector(self.ability:GetSpecialValueFor("start_radius"), 0, 0))

	self:StartIntervalThink(FrameTime())
end

function modifier_thdots_yuuma01_jump:OnIntervalThink()
	if not IsServer() then return end

	-- 碰撞判定
	local targets = FindUnitsInRadius(
		self.caster:GetTeam(),
		self.caster:GetOrigin(),
		nil,
		self.ability:GetSpecialValueFor("start_radius"),
		self.ability:GetAbilityTargetTeam(),
		self.ability:GetAbilityTargetType(),
		self.ability:GetAbilityTargetFlags(),
		FIND_ANY_ORDER,
		false
	)

	for i, target in pairs(targets) do
		if not self.hitTargets[target:GetEntityIndex()] then
			self.hitTargets[target:GetEntityIndex()] = true

			-- 高度差判定
			if math.abs(target:GetOrigin().z - self.caster:GetOrigin().z) > 80 then return end

			local baseDamage = self.ability:GetSpecialValueFor("base_damage")

			ApplyDamage({victim = target, attacker = self.caster, damage = baseDamage, damage_type = self.ability:GetAbilityTargetTeam(), ability = self.ability})
		end
	end

end

function modifier_thdots_yuuma01_jump:OnDestroy()
	if not IsServer() then return end

	-- Set Destination and Interrupt Motion or the unit will still move
	self.caster:RemoveHorizontalMotionController(self)
	self.caster:RemoveVerticalMotionController(self)

	if self.spinParticle then
		ParticleManager:DestroyParticle(self.spinParticle, false)
		ParticleManager:ReleaseParticleIndex(self.spinParticle)
	end

	if self.enableDown then
		self.caster:AddNewModifier(self.caster, self.ability, "modifier_thdots_yuuma01_down", {})
	end

end

function modifier_thdots_yuuma01_jump:OnRefresh(params)
	if not IsServer() then return end

	self:OnCreated(params)
end

function modifier_thdots_yuuma01_jump:UpdateHorizontalMotion(me, dt)
	if GetGroundHeight(self:GetParent():GetAbsOrigin(), self.caster) > self:GetParent():GetAbsOrigin().z then
		-- 地面高度（墙）比施法者高时，停止水平移动（撞墙）
		me:SetOrigin(GetGroundPosition(me:GetOrigin() + 0 * dt, self.caster))
	else
		me:SetOrigin(GetGroundPosition(me:GetOrigin() + self.velocity * dt, self.caster))
	end
end

function modifier_thdots_yuuma01_jump:OnHorizontalMotionInterrupted()
	self:Destroy()
end

function modifier_thdots_yuuma01_jump:UpdateVerticalMotion(me, dt)
	if self.vertical_velocity + (self.vertical_acceleration * dt) <= 0 then
		-- 垂直速度将要变为负数时下落
		self.enableDown = true
		self:Destroy()
	else
		me:SetOrigin(me:GetOrigin() + Vector(0, 0, self.vertical_velocity) * dt)
		-- 重力加速度
		self.vertical_velocity = self.vertical_velocity + (self.vertical_acceleration * dt)
	end
	--[[local stroke_particle = ParticleManager:CreateParticle("particles/heroes/meira/ability_meira_01_3_back_branching.vpcf", PATTACH_ABSORIGIN, me)
	ParticleManager:ReleaseParticleIndex(stroke_particle)
	--]]

end

-- -- This typically gets called if the caster uses a position breaking tool (ex. Earth Spike) while in mid-motion
function modifier_thdots_yuuma01_jump:OnVerticalMotionInterrupted()
	self:Destroy()
end

-- 下落modifier
modifier_thdots_yuuma01_down = {}
LinkLuaModifier("modifier_thdots_yuuma01_down","scripts/vscripts/abilities/abilityyuuma.lua",LUA_MODIFIER_MOTION_BOTH)

function modifier_thdots_yuuma01_down:IsHidden()			return true end
function modifier_thdots_yuuma01_down:IsPurgable()			return false end
function modifier_thdots_yuuma01_down:RemoveOnDeath()		return false end
function modifier_thdots_yuuma01_down:IsDebuff()			return false end
function modifier_thdots_yuuma01_down:GetAttributes()		return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

function modifier_thdots_yuuma01_down:CheckState()
	return {
		[MODIFIER_STATE_STUNNED]	= true,
	}
end

function modifier_thdots_yuuma01_down:OnCreated(keys)
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	self.start_radius = self.ability:GetSpecialValueFor("end_radius")

	self.distance = math.abs(GetDistanceBetweenTwoVec2D(self.caster:GetOrigin(), self.ability.end_pos))
	-- 计算下落时间
	self.height = self:GetParent():GetAbsOrigin().z - GetGroundHeight(self:GetParent():GetAbsOrigin(), self.caster)
	self.vSpeed = self.ability:GetSpecialValueFor("down_vSpeed")
	self.duration = self.height / self.vSpeed

	-- 水平位置在下落时间内到达地点
	self.direction = self.ability.direction
	self.hSpeed = self.distance / self.duration

	self.velocity = self.direction * self.hSpeed

	-- 恒定下落速度
	self.vertical_velocity = - (self.vSpeed)
	--self.vertical_acceleration = - (8 * self.height) / (self.duration * self.duration)

	self.caster:RemoveHorizontalMotionController(self)
	self.caster:RemoveVerticalMotionController(self)

	if self:ApplyVerticalMotionController() == false then
		self:Destroy()
	end

	if self:ApplyHorizontalMotionController() == false then
		self:Destroy()
	end
end

function modifier_thdots_yuuma01_down:OnDestroy()
	if not IsServer() then return end

	-- Set Destination and Interrupt Motion or the unit will still move
	self.caster:RemoveHorizontalMotionController(self)
	self.caster:RemoveVerticalMotionController(self)

	-- 落地特效
	self.earthBreak = ParticleManager:CreateParticle("particles/units/heroes/hero_grimstroke/grimstroke_death.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(self.earthBreak, 0, self.caster:GetAbsOrigin())

	-- 落地伤害判定
	local targets = FindUnitsInRadius(
		self.caster:GetTeam(),
		self.caster:GetOrigin(),
		nil,
		self.ability:GetSpecialValueFor("end_radius"),
		self.ability:GetAbilityTargetTeam(),
		self.ability:GetAbilityTargetType(),
		self.ability:GetAbilityTargetFlags(),
		FIND_ANY_ORDER,
		false
	)

	for i, target in pairs(targets) do

		-- 高度差判定
		if math.abs(target:GetOrigin().z - self.caster:GetOrigin().z) > 80 then return end

		local slow_duration = self.ability:GetSpecialValueFor("slow_duration")
		target:AddNewModifier(self.caster, self.ability, "modifier_thdots_yuuma01_slow", {duration = slow_duration})

		local baseDamage = self.ability:GetSpecialValueFor("base_damage")
		local totalDamage = baseDamage + self.ability.bonusDamage

		ApplyDamage({victim = target, attacker = self.caster, damage = totalDamage, damage_type = self.ability:GetAbilityTargetTeam(), ability = self.ability})
	end
end

function modifier_thdots_yuuma01_down:OnRefresh(params)
	self:OnCreated(params)
end

function modifier_thdots_yuuma01_down:UpdateHorizontalMotion(me, dt)
	if GetGroundHeight(self:GetParent():GetAbsOrigin(), self.caster) > self:GetParent():GetAbsOrigin().z then
		-- 撞墙
		me:SetOrigin(GetGroundPosition(me:GetOrigin() + 0 * dt, self.caster))
	else
		me:SetOrigin(GetGroundPosition(me:GetOrigin() + self.velocity * dt, self.caster))
	end
end

function modifier_thdots_yuuma01_down:OnHorizontalMotionInterrupted()
	self:Destroy()
end

function modifier_thdots_yuuma01_down:UpdateVerticalMotion(me, dt)
	local groundHeight = GetGroundHeight(self:GetParent():GetAbsOrigin(), self.caster)
	local parentHeight = self:GetParent():GetAbsOrigin().z
	if ((math.abs(groundHeight - parentHeight) < 12) or (groundHeight > parentHeight and (groundHeight - parentHeight) > 12)) and self:GetElapsedTime() > 0.1 then
		-- 落地 or 爬山 and 经过0.1秒
		self:Destroy()
	else
		me:SetOrigin(me:GetOrigin() + Vector(0, 0, self.vertical_velocity) * dt)
		--self.vertical_velocity = self.vertical_velocity + (self.vertical_acceleration * dt)
	end
end

function modifier_thdots_yuuma01_down:OnVerticalMotionInterrupted()
	self:Destroy()
end

modifier_thdots_yuuma01_slow = {}
LinkLuaModifier("modifier_thdots_yuuma01_slow","scripts/vscripts/abilities/abilityyuuma.lua",LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_yuuma01_slow:IsHidden()			return false end
function modifier_thdots_yuuma01_slow:IsPurgable()			return true end
function modifier_thdots_yuuma01_slow:RemoveOnDeath()		return true end
function modifier_thdots_yuuma01_slow:IsDebuff()			return true end

function modifier_thdots_yuuma01_slow:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	}
end

function modifier_thdots_yuuma01_slow:GetModifierMoveSpeedBonus_Percentage() return self:GetAbility():GetSpecialValueFor("slow") end

ability_thdots_yuuma02 = {}

function ability_thdots_yuuma02:GetIntrinsicModifierName()
	return "modifier_thdots_yuuma02_passive"
end

function ability_thdots_yuuma02:CastFilterResult()
	if not IsServer() then return end
	local caster = self:GetCaster()

	-- 无护盾时无法释放
	if not caster:HasModifier("modifier_thdots_yuuma02_shield") then
		return UF_FAIL_CUSTOM
	else
		return UF_SUCCESS
	end
end

function ability_thdots_yuuma02:GetCustomCastError()
	local caster = self:GetCaster()

	if not caster:HasModifier("modifier_thdots_yuuma02_shield") then
		return "#thd_hud_error_cant_cast_without_shield"
	end
end

function ability_thdots_yuuma02:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor("convert_duration")
	local convert_pct = self:GetSpecialValueFor("convert_pct")

	if caster:HasModifier("modifier_thdots_yuuma02_shield") then
		local shield_modifier = caster:FindModifierByName("modifier_thdots_yuuma02_shield")
		local currShield = shield_modifier:GetStackCount()
		local convert_health = currShield*convert_pct/100

		shield_modifier:Destroy()

		-- 传入转换的生命
		caster:AddNewModifier(caster, self, "modifier_thdots_yuuma02_maxHealth_bonus", {duration = duration, convert_health = convert_health})
	end
end

modifier_thdots_yuuma02_passive = {}
LinkLuaModifier("modifier_thdots_yuuma02_passive","scripts/vscripts/abilities/abilityyuuma.lua",LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_yuuma02_passive:IsHidden()			return true end
function modifier_thdots_yuuma02_passive:IsPurgable()		return false end
function modifier_thdots_yuuma02_passive:RemoveOnDeath()	return false end
function modifier_thdots_yuuma02_passive:IsDebuff()			return false end

function modifier_thdots_yuuma02_passive:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

function modifier_thdots_yuuma02_passive:OnTakeDamage(keys)
	if not IsServer() then return end
	local parent  = self:GetParent()
	local ability = self:GetAbility()
	if parent:PassivesDisabled() then return end

	local maxShield = parent:GetMaxHealth()*ability:GetSpecialValueFor("maxShield_maxHP_pct")/100

	-- 对敌人造成伤害转化护盾
	if parent == keys.attacker and parent ~= keys.unit and not keys.unit:IsBuilding() then

		-- 计算护盾值
		local shield_remaining = keys.damage*ability:GetSpecialValueFor("damageToShiled_pct")/100
		-- 对非英雄降低
		if not keys.unit:IsRealHero() then
			shield_remaining = shield_remaining*ability:GetSpecialValueFor("nonheroReduce_pct")/100
		end

		if not parent:HasModifier("modifier_thdots_yuuma02_shield") then
			parent:AddNewModifier(parent, ability, "modifier_thdots_yuuma02_shield", {duration = -1, shield_remaining = shield_remaining})
		else
			local shield_modifier = parent:FindModifierByName("modifier_thdots_yuuma02_shield")
			local currShield = shield_modifier:GetStackCount()
			if not (currShield >= maxShield) then
				if currShield + shield_remaining > maxShield then
					shield_modifier:SetStackCount(maxShield)
				else
					shield_modifier:SetStackCount(currShield + shield_remaining)
				end
			end
		end
	end
end

modifier_thdots_yuuma02_shield = {}
LinkLuaModifier("modifier_thdots_yuuma02_shield","scripts/vscripts/abilities/abilityyuuma.lua",LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_yuuma02_shield:IsHidden()			return true end
function modifier_thdots_yuuma02_shield:IsPurgable()		return false end
function modifier_thdots_yuuma02_shield:RemoveOnDeath()		return false end
function modifier_thdots_yuuma02_shield:IsDebuff()			return false end

function modifier_thdots_yuuma02_shield:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
	}
end

function modifier_thdots_yuuma02_shield:OnCreated(keys)
	if not IsServer() then return end

	self:SetStackCount(keys.shield_remaining)
end

function modifier_thdots_yuuma02_shield:GetModifierIncomingDamageConstant()
	if IsClient() then
		return self:GetStackCount()
	end
end

function modifier_thdots_yuuma02_shield:GetModifierTotal_ConstantBlock(keys)
	if not IsServer() then return end
	-- 不格挡生命流失
	if bit.band(keys.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then return 0 end

	-- 计算护盾格挡
	local shield_remaining = self:GetStackCount()

	if keys.damage < shield_remaining then
		shield_remaining = shield_remaining-keys.damage
		-- 减少护盾值
		self:SetStackCount(shield_remaining)

		return keys.damage
	else
		self:Destroy()

		return shield_remaining
	end

end

modifier_thdots_yuuma02_maxHealth_bonus = {}
LinkLuaModifier("modifier_thdots_yuuma02_maxHealth_bonus","scripts/vscripts/abilities/abilityyuuma.lua",LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_yuuma02_maxHealth_bonus:IsHidden()			return false end
function modifier_thdots_yuuma02_maxHealth_bonus:IsPurgable()		return true end
function modifier_thdots_yuuma02_maxHealth_bonus:RemoveOnDeath()	return true end
function modifier_thdots_yuuma02_maxHealth_bonus:IsDebuff()			return false end

function modifier_thdots_yuuma02_maxHealth_bonus:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,		-- Destroy时不会根据百分比调整生命
	}
end

function modifier_thdots_yuuma02_maxHealth_bonus:OnCreated(keys)
	if not IsServer() then return end

	self.convert_health = keys.convert_health

	local parent = self:GetParent()
	-- 增加转换过来的生命
	parent:ModifyHealth(parent:GetHealth() + self.convert_health, self:GetAbility(), false, 0)

	-- 特效
	self.castEffect = ParticleManager:CreateParticle("particles/items2_fx/refresher.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:SetParticleControlEnt(self.castEffect, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(self.castEffect)

	-- 同步客户端
	self:SetHasCustomTransmitterData(true)
end

function modifier_thdots_yuuma02_maxHealth_bonus:OnRefresh(keys)
	if not IsServer() then return end

	self:OnCreated(keys)

	-- 客户端刷新
	self:SendBuffRefreshToClients()
end

-- 传服务端数据
function modifier_thdots_yuuma02_maxHealth_bonus:AddCustomTransmitterData()
	return {
		convert_health = self.convert_health
	}
end
-- 接受数据
function modifier_thdots_yuuma02_maxHealth_bonus:HandleCustomTransmitterData( data )
	self.convert_health = data.convert_health
end

function modifier_thdots_yuuma02_maxHealth_bonus:GetModifierExtraHealthBonus()
	return self.convert_health
end

ability_thdots_yuuma03 = {}
-- 法球modifier
LinkLuaModifier("modifier_generic_orb_effect_lua", "components/modifiers/generic/modifier_generic_orb_effect_lua", LUA_MODIFIER_MOTION_NONE)

function ability_thdots_yuuma03:OnUpgrade()
	if not IsServer() then return end

	local caster = self:GetCaster()

	-- 被动modifier
	if not caster:HasModifier("modifier_thdots_yuuma03_passive") then
		caster:AddNewModifier(caster, self, "modifier_thdots_yuuma03_passive", {duration = -1})
	end

	if not caster:HasModifier("modifier_thdots_yuuma03_talent_listener") then		-- 天赋监听
		caster:AddNewModifier(caster, self, "modifier_thdots_yuuma03_talent_listener", {duration = -1})
	end

	if (not self.ability_manager) and not (self:IsStolen()) then
		self.ability_manager = yuuma03_ability_manager:CreateInstance()
		self.ability_manager:Init( self )
	end
end

function ability_thdots_yuuma03:GetCastRange()
	return self:GetCaster():Script_GetAttackRange()
end

function ability_thdots_yuuma03:GetIntrinsicModifierName()
	return "modifier_generic_orb_effect_lua"
end

function ability_thdots_yuuma03:GetPriority()
	return "DOTA_ORB_PRIORITY_ABILITY"
end

function ability_thdots_yuuma03:OnOrbImpact(keys)
	if not IsServer() then return end

	local caster = self:GetCaster()
	local target = keys.target
	local duration = self:GetSpecialValueFor("mark_duration")

	if not target:IsMagicImmune() then
		if self.lastMarkTarget ~= nil then
			-- 移除上个标记
			self.lastMarkTarget:RemoveModifierByName("modifier_thdots_yuuma03_mark")
		end
		target:AddNewModifier(caster, self, "modifier_thdots_yuuma03_mark", {duration = duration})
		-- 记录标记目标
		self.lastMarkTarget = target
	end
end

modifier_thdots_yuuma03_passive = {}
LinkLuaModifier("modifier_thdots_yuuma03_passive","scripts/vscripts/abilities/abilityyuuma.lua",LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_yuuma03_passive:IsHidden()			return true end
function modifier_thdots_yuuma03_passive:IsPurgable()		return false end
function modifier_thdots_yuuma03_passive:RemoveOnDeath()	return false end
function modifier_thdots_yuuma03_passive:IsDebuff()			return false end

function modifier_thdots_yuuma03_passive:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_DEATH,
	}
end

function modifier_thdots_yuuma03_passive:OnCreated()
	if not IsServer() then return end

	local parent = self:GetParent()

	-- 记录助攻
	self.assists = parent:GetAssists()
end

function modifier_thdots_yuuma03_passive:OnDeath(keys)
	if not IsServer() then return end

	local parent = self:GetParent()
	local ability = self:GetAbility()
	local maxHealth_gain = ability:GetSpecialValueFor("maxHealth_gain")
	local targetMaxHP_pct = ability:GetSpecialValueFor("targetMaxHP_pct")
	local target = keys.unit

	-- 击杀
	if keys.attacker == parent and keys.attacker:IsRealHero() then

		if not parent:HasModifier("modifier_thdots_yuuma03_HP_Bonus") then
			parent:AddNewModifier(parent, ability, "modifier_thdots_yuuma03_HP_Bonus", {duration = -1})
		end
		local bonus_modifier = parent:FindModifierByName("modifier_thdots_yuuma03_HP_Bonus")
		local bonus_stack = bonus_modifier:GetStackCount()

		if target:IsRealHero() then
			bonus_modifier:SetStackCount(bonus_stack + (maxHealth_gain*ability:GetSpecialValueFor("kill_bonus_times")))
		else
			if target:IsAncient() then
				bonus_modifier:SetStackCount(bonus_stack + (maxHealth_gain*ability:GetSpecialValueFor("ancient_bonus_times")))
			else
				bonus_modifier:SetStackCount(bonus_stack + maxHealth_gain)
			end
		end

		if not parent:PassivesDisabled() then
			local heal_amount = target:GetMaxHealth()*targetMaxHP_pct/100

			parent:Heal(heal_amount, ability)
			SendOverheadEventMessage(nil,OVERHEAD_ALERT_HEAL,parent,heal_amount,nil)
		end

	-- 助攻
	elseif keys.attacker ~= parent and keys.attacker:GetTeam() == parent:GetTeam() and target:IsRealHero() then

		if parent:GetAssists() > self.assists then
			-- 助攻增加时
			if not parent:HasModifier("modifier_thdots_yuuma03_HP_Bonus") then
				parent:AddNewModifier(parent, ability, "modifier_thdots_yuuma03_HP_Bonus", {duration = -1})
			end
			local bonus_modifier = parent:FindModifierByName("modifier_thdots_yuuma03_HP_Bonus")
			local bonus_stack = bonus_modifier:GetStackCount()

			-- 记录助攻
			self.assists = parent:GetAssists()
			bonus_modifier:SetStackCount(bonus_stack + (maxHealth_gain*ability:GetSpecialValueFor("assist_bonus_times")))
		end

	end
end

modifier_thdots_yuuma03_HP_Bonus = {}
LinkLuaModifier("modifier_thdots_yuuma03_HP_Bonus","scripts/vscripts/abilities/abilityyuuma.lua",LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_yuuma03_HP_Bonus:IsHidden()			return false end
function modifier_thdots_yuuma03_HP_Bonus:IsPurgable()			return false end
function modifier_thdots_yuuma03_HP_Bonus:RemoveOnDeath()		return false end
function modifier_thdots_yuuma03_HP_Bonus:IsDebuff()			return false end
function modifier_thdots_yuuma03_HP_Bonus:AllowIllusionDuplicate()			return true end

function modifier_thdots_yuuma03_HP_Bonus:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_BONUS,
	}
end

function modifier_thdots_yuuma03_HP_Bonus:GetModifierHealthBonus()
	return self:GetStackCount()
end

-- 天赋监听
modifier_thdots_yuuma03_talent_listener = {}
LinkLuaModifier("modifier_thdots_yuuma03_talent_listener","scripts/vscripts/abilities/abilityyuuma.lua",LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_yuuma03_talent_listener:IsHidden()			return true end
function modifier_thdots_yuuma03_talent_listener:IsPurgable()		return false end
function modifier_thdots_yuuma03_talent_listener:RemoveOnDeath()	return false end
function modifier_thdots_yuuma03_talent_listener:IsDebuff()			return false end

function modifier_thdots_yuuma03_talent_listener:OnCreated()
	if not IsServer() then return end

	self.ability = self:GetAbility()
	self.slot1 = self:GetParent():FindAbilityByName("ability_yuuma03_empty1")
	self.slot2 = self:GetParent():FindAbilityByName("ability_yuuma03_empty2")

	self:StartIntervalThink(FrameTime())
end

function modifier_thdots_yuuma03_talent_listener:OnIntervalThink()
	if not IsServer() then return end
	local maxPassive = self.ability:GetSpecialValueFor("maxPassive")

	-- 当前技能为默认技能时不隐藏
	if maxPassive >= 1 and self.ability.ability_manager.current_abilities[1] == self.ability.ability_manager.default_abilities[1]  then
		if self.slot1:IsHidden() then
			self.slot1:SetHidden(false)
		end
	end
	if maxPassive >= 2 and self.ability.ability_manager.current_abilities[2] == self.ability.ability_manager.default_abilities[2] then
		if self.slot2:IsHidden() then
			self.slot2:SetHidden(false)
		end
	end
end

modifier_thdots_yuuma03_mark = {}
LinkLuaModifier("modifier_thdots_yuuma03_mark","scripts/vscripts/abilities/abilityyuuma.lua",LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_yuuma03_mark:IsHidden()			return false end
function modifier_thdots_yuuma03_mark:IsPurgable()			return false end
function modifier_thdots_yuuma03_mark:RemoveOnDeath()		return false end
function modifier_thdots_yuuma03_mark:IsDebuff()			return false end

function modifier_thdots_yuuma03_mark:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_DEATH,
	}
end

function modifier_thdots_yuuma03_mark:OnCreated()
	if not IsServer() then return end

	-- 特效
	self.icon = ParticleManager:CreateParticleForTeam("particles/units/heroes/hero_pudge/pudge_swallow.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent(), self:GetCaster():GetTeamNumber())
	self:AddParticle(self.icon, false, false, -1, true, true)
end

function modifier_thdots_yuuma03_mark:OnDestroy()
	if not IsServer() then return end

	self:GetAbility().lastMarkTarget = nil

	ParticleManager:DestroyParticle(self.icon, false)
	ParticleManager:ReleaseParticleIndex(self.icon)
end

function modifier_thdots_yuuma03_mark:OnDeath(keys)
	local sAbility = self:GetAbility()		-- self
	local caster = self:GetCaster()
	local target = self:GetParent()

	if keys.unit ~= target then return end

	-- 黑名单技能
	local abilityIgnore = {
		[1] = "neutral_upgrade",
		[2] = "creep_irresolute",
		[3] = "creep_siege",
		[4] = "creep_piercing",
		[5] = "neutral_spell_immunity",
	}
	local tAbility = nil					-- target
	local tAbility_list = {}
	for i=0,5 do
		local avaiable = true
		local ability = target:GetAbilityByIndex( i )
		if ability and ability:IsPassive() and not ability:IsHidden() then
			for idx, ignored in pairs(abilityIgnore) do
				if ability:GetAbilityName() == ignored then
					avaiable = false
					break
				end
			end
			if avaiable == true then
				table.insert(tAbility_list,ability)
			end
		end
	end

	-- 随机获取技能
	local randomAbility = tAbility_list[RandomInt(1, #tAbility_list)]
	if randomAbility ~= nil then
		tAbility = randomAbility
	end

	-- absorb abilities if autocast is on and target has abilities
	if tAbility ~= nil and (not sAbility:IsStolen()) then

		-- add ability using ability manager
		sAbility.ability_manager:SetAbility( tAbility, 1 )
	end
end

--------------------------------------------------------------------------------
-- Helper class
yuuma03_ability_manager = {}

-- just in case if modified to allow devouring more than 2 abilities, use this for default list
yuuma03_ability_manager.default_ability_list = {
	[1] = "ability_yuuma03_empty1",
	[2] = "ability_yuuma03_empty2",
	-- [3] = "doom_devour_lua_slot3",
}

yuuma03_ability_manager.current_abilities = {}
yuuma03_ability_manager.default_abilities = {}
yuuma03_ability_manager.default_index = {}

function yuuma03_ability_manager:CreateInstance()
	local ret = {}

	-- initialize fields
	ret.abilities = {}
	ret.ability_slot = {}
	ret.MAX_ABILITY = 2

	-- initialize methods and constants
	for k,v in pairs(self) do
		ret[k] = v
	end
	return ret
end

-- init ability manager
function yuuma03_ability_manager:Init( ability )
	-- store this ability (devour)
	self.ability = ability

	for k,v in pairs(self.default_ability_list) do
		-- get handles
		self.default_abilities[k] = ability:GetCaster():FindAbilityByName( v )
		self.current_abilities[k] = self.default_abilities[k]

		-- store ability indices
		self.default_index[k] = self.default_abilities[k]:GetAbilityIndex()
		self.current_index = 1
	end
end

-- pass 'ability' as nil to reset to default ability
function yuuma03_ability_manager:SetAbility( ability, slot )
	local caster = self.ability:GetCaster()
	local maxPassive = self.ability:GetSpecialValueFor("maxPassive")

	-- if nil, reset instead
	if not ability then
		self:ResetAbility( slot )
		return
	end

	-- check if ability already exist
	local existing = nil
	for i,current in pairs(self.current_abilities) do
		if current:GetAbilityName()==ability:GetAbilityName() then
			existing = current
			break
		end
	end

	-- same ability already exist, only minor process
	if existing then
		-- if within the same position, just return
		if existing:GetAbilityIndex()==self.default_index[slot] then
			return
		end

		-- if it is on different slot, swap with current one
		caster:SwapAbilities(
			existing:GetAbilityName(),
			self.current_abilities[slot]:GetAbilityName(),
			true,
			true
		)

		self.current_abilities[slot + 1] = self.current_abilities[slot]
		self.current_abilities[slot] = existing
		return
	end

	-- duplicate new ability
	local ability_new = caster:AddAbility( ability:GetAbilityName() )
	ability_new:SetLevel( ability:GetLevel() )
	ability_new:SetStolen( true )

	-- swap abilities
	caster:SwapAbilities( 
		ability_new:GetAbilityName(),
		self.current_abilities[slot]:GetAbilityName(),
		true,
		false
	)

	if maxPassive > 1 then
		caster:SwapAbilities( 
			self.current_abilities[slot]:GetAbilityName(),
			self.current_abilities[2]:GetAbilityName(),
			true,
			false
		)

		if self.current_abilities[2]~=self.default_abilities[2] then
			caster:RemoveAbility( self.current_abilities[2]:GetAbilityName() )
		end

		self.current_abilities[2] = self.current_abilities[slot]
	else
		-- remove old ability if it is not default abilities
		if self.current_abilities[slot]~=self.default_abilities[slot] then
			caster:RemoveAbility( self.current_abilities[slot]:GetAbilityName() )
		end
	end

	-- register new ability
	self.current_abilities[slot] = ability_new
end

function yuuma03_ability_manager:ResetAbility( slot )
	local caster = self.ability:GetCaster()

	-- check if already reset
	if self.current_abilities[slot]==self.default_abilities[slot] then return end

	-- swap abilities
	caster:SwapAbilities( 
		self.default_abilities[slot]:GetAbilityName(),
		self.current_abilities[slot]:GetAbilityName(),
		true,
		false
	)

	-- remove old ability
	caster:RemoveAbility( self.current_abilities[slot]:GetAbilityName() )

	-- register default as new ability	
	self.current_abilities[slot] = self.default_abilities[slot]
end

ability_thdots_yuuma04 = {}

function ability_thdots_yuuma04:GetCastRange()
	if IsClient() then
		return self:GetSpecialValueFor("pull_radius")
	end
end

function ability_thdots_yuuma04:GetAssociatedSecondaryAbilities()
	return "ability_thdots_yuuma04_end"
end

function ability_thdots_yuuma04:OnUpgrade()
	-- 升级子技能
	local end_ability = self:GetCaster():FindAbilityByName("ability_thdots_yuuma04_end")

	if end_ability and end_ability:GetLevel() ~= self:GetLevel() then
		end_ability:SetLevel(self:GetLevel())
	end
end

function ability_thdots_yuuma04:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor("duration")

	caster:AddNewModifier(caster, self, "modifier_thdots_yuuma04_caster", {duration = duration})
end

modifier_thdots_yuuma04_caster = {}
LinkLuaModifier("modifier_thdots_yuuma04_caster","scripts/vscripts/abilities/abilityyuuma.lua",LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_yuuma04_caster:IsHidden()			return false end
function modifier_thdots_yuuma04_caster:IsPurgable()		return false end
function modifier_thdots_yuuma04_caster:RemoveOnDeath()		return true end
function modifier_thdots_yuuma04_caster:IsDebuff()			return false end
function modifier_thdots_yuuma04_caster:CheckState()
	return {
		[MODIFIER_STATE_COMMAND_RESTRICTED]			= true,
		[MODIFIER_STATE_ROOTED]						= true,
	}
end

function modifier_thdots_yuuma04_caster:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
	}
end

function modifier_thdots_yuuma04_caster:OnCreated()
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()
	self.tick_rate = self.ability:GetSpecialValueFor("tick_rate")
	self.pull_speed = self.ability:GetSpecialValueFor("pull_speed")
	self.pull_radius = self.ability:GetSpecialValueFor("pull_radius")

	-- 替换技能
	self.end_ability = self.caster:FindAbilityByName("ability_thdots_yuuma04_end")

	if self.end_ability then
		self.caster:SwapAbilities(self.ability:GetAbilityName(), self.end_ability:GetAbilityName(), false, true)
	end

	self.end_ability:StartCooldown(1)

	-- 特效
	self.pullEffect = ParticleManager:CreateParticle("particles/units/heroes/hero_enigma/enigma_black_hole_scepter.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.caster)
	ParticleManager:SetParticleControl(self.pullEffect, 1, Vector(self.pull_radius, 0, 0))

	self:StartIntervalThink(self.tick_rate)
end

function modifier_thdots_yuuma04_caster:OnRefresh()
	if not IsServer() then return end

	self:OnCreated()
end

function modifier_thdots_yuuma04_caster:OnIntervalThink()
	if not IsServer() then return end

	-- 吸
	local targets = FindUnitsInRadius(
		self.caster:GetTeam(),
		self.caster:GetAbsOrigin(),
		nil,
		self.pull_radius,
		self.ability:GetAbilityTargetTeam(),
		self.ability:GetAbilityTargetType(),
		self.ability:GetAbilityTargetFlags(),
		FIND_ANY_ORDER,
		false
	)

	local speed = self.pull_speed / (1 / self.tick_rate)
	for i, target in pairs (targets) do
		local vec = target:GetAbsOrigin()
		local direct = ( self.caster:GetAbsOrigin() - vec):Normalized() * speed
		if not target:IsMagicImmune() and not target:IsDebuffImmune() and not IsTHDImmune(target) then
			-- 受地形阻挡
			FindClearSpaceForUnit(target, target:GetAbsOrigin() + direct, false)
		end
	end

	if self:GetRemainingTime() <= self.ability:GetSpecialValueFor("end_delay") and not self.caster:HasModifier("modifier_thdots_yuuma04_end_delay") then
		self.caster:AddNewModifier(self.caster, self.ability, "modifier_thdots_yuuma04_end_delay", {duration = self.ability:GetSpecialValueFor("end_delay")})
	end
end

function modifier_thdots_yuuma04_caster:GetModifierIncomingDamage_Percentage(keys)
	if not IsServer() then return end

	-- Ability properties
	local parent = self:GetParent()

	--  A heal to heal the damage,and -100% to prevent it,
	parent:Heal(keys.damage, self:GetAbility())

	return -100
end

function modifier_thdots_yuuma04_caster:OnRemoved()
	if not IsServer() then return end

	-- 替换技能
	self.end_ability = self.caster:FindAbilityByName("ability_thdots_yuuma04_end")

	if self.end_ability then
		self.caster:SwapAbilities(self.ability:GetAbilityName(), self.end_ability:GetAbilityName(), true, false)
	end

	ParticleManager:DestroyParticle( self.pullEffect, true )
	ParticleManager:ReleaseParticleIndex( self.pullEffect )
end

modifier_thdots_yuuma04_end_delay = {}
LinkLuaModifier("modifier_thdots_yuuma04_end_delay","scripts/vscripts/abilities/abilityyuuma.lua",LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_yuuma04_end_delay:IsHidden()			return true end
function modifier_thdots_yuuma04_end_delay:IsPurgable()			return false end
function modifier_thdots_yuuma04_end_delay:RemoveOnDeath()		return true end
function modifier_thdots_yuuma04_end_delay:IsDebuff()			return false end
function modifier_thdots_yuuma04_end_delay:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
	}
end

function modifier_thdots_yuuma04_end_delay:OnCreated()
	if not IsServer() then return end

	local caster = self:GetParent()
	local ability = self:GetAbility()

	local radius = ability:GetSpecialValueFor("center_radius")

	-- Get Resources
	local particle_cast = "particles/heroes/yuuma/yumma04_calldown.vpcf"

	-- Create Particle
	self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_CUSTOMORIGIN, self:GetCaster() )
	ParticleManager:SetParticleControl( self.effect_cast, 0, self:GetParent():GetOrigin() )
	ParticleManager:SetParticleControl( self.effect_cast, 1, Vector( radius, 0, -(radius / self:GetDuration())*2 ) )
	ParticleManager:SetParticleControl( self.effect_cast, 2, Vector( self:GetDuration(), 0, 0 ) )
end

function modifier_thdots_yuuma04_end_delay:OnRemoved()
	if not IsServer() then return end

	local caster = self:GetParent()
	local ability = self:GetAbility()

	ParticleManager:DestroyParticle( self.effect_cast, true )
	ParticleManager:ReleaseParticleIndex( self.effect_cast )

	-- 结束效果和僵直
	caster:AddNewModifier(caster, ability, "modifier_thdots_yuuma04_end", {duration = ability:GetSpecialValueFor("end_duration")})
end

modifier_thdots_yuuma04_end = {}
LinkLuaModifier("modifier_thdots_yuuma04_end","scripts/vscripts/abilities/abilityyuuma.lua",LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_yuuma04_end:IsHidden()			return true end
function modifier_thdots_yuuma04_end:IsPurgable()		return false end
function modifier_thdots_yuuma04_end:RemoveOnDeath()	return true end
function modifier_thdots_yuuma04_end:IsDebuff()			return false end
function modifier_thdots_yuuma04_end:CheckState()
	return {
		[MODIFIER_STATE_STUNNED]						= true,
	}
end

function modifier_thdots_yuuma04_end:OnCreated()
	if not IsServer() then return end

	local caster = self:GetParent()
	local ability = self:GetAbility()

	-- 中断牵引效果
	if caster:HasModifier("modifier_thdots_yuuma04_caster") then
		caster:RemoveModifierByName("modifier_thdots_yuuma04_caster")
	end

	-- 咬
	local targets = FindUnitsInRadius(
		caster:GetTeam(),
		caster:GetAbsOrigin(),
		nil,
		ability:GetSpecialValueFor("center_radius"),
		ability:GetAbilityTargetTeam(),
		ability:GetAbilityTargetType(),
		ability:GetAbilityTargetFlags(),
		FIND_ANY_ORDER,
		false
	)

	local stolenStr = 0

	for i, target in pairs(targets) do
		if target:IsMagicImmune() or target:IsDebuffImmune() or IsTHDImmune(target) then return end
		if target:IsRealHero() then
			-- 计算窃取的力量
			local steal = target:GetStrength()*ability:GetSpecialValueFor("str_steal_pct")/100

			target:AddNewModifier(caster, ability, "modifier_thdots_yuuma04_str_stolen",
			{duration = ability:GetSpecialValueFor("steal_duration") * (1 - target:GetStatusResistance()), stolen = steal})

			-- 计算窃取到的力量
			stolenStr = stolenStr + steal
		end
		if (target:IsCreep() and not target:IsAncient()) or target:IsIllusion() then
			-- 秒杀
			target:Kill(ability, caster)
		end
	end
	if stolenStr ~= 0 then
		caster:AddNewModifier(caster, ability, "modifier_thdots_yuuma04_stolen_bonus", {duration = ability:GetSpecialValueFor("steal_duration"), stolen = stolenStr})
	end
end

modifier_thdots_yuuma04_str_stolen = {}
LinkLuaModifier("modifier_thdots_yuuma04_str_stolen","scripts/vscripts/abilities/abilityyuuma.lua",LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_yuuma04_str_stolen:IsHidden()			return false end
function modifier_thdots_yuuma04_str_stolen:IsPurgable()		return false end
function modifier_thdots_yuuma04_str_stolen:RemoveOnDeath()		return true end
function modifier_thdots_yuuma04_str_stolen:IsDebuff()			return true end
function modifier_thdots_yuuma04_str_stolen:GetAttributes()		return MODIFIER_ATTRIBUTE_MULTIPLE end	-- 刷新并增加层数时MODIFIER_PROPERTY_EXTRA_STRENGTH_BONUS有bug
function modifier_thdots_yuuma04_str_stolen:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_EXTRA_STRENGTH_BONUS,			-- Destroy时不会根据百分比调整生命
	}
end

function modifier_thdots_yuuma04_str_stolen:OnCreated(keys)
	if not IsServer() then return end

	self:SetStackCount(self:GetStackCount() + keys.stolen)
end

function modifier_thdots_yuuma04_str_stolen:GetModifierExtraStrengthBonus()
	return -self:GetStackCount()
end

modifier_thdots_yuuma04_stolen_bonus = {}
LinkLuaModifier("modifier_thdots_yuuma04_stolen_bonus","scripts/vscripts/abilities/abilityyuuma.lua",LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_yuuma04_stolen_bonus:IsHidden()			return false end
function modifier_thdots_yuuma04_stolen_bonus:IsPurgable()			return false end
function modifier_thdots_yuuma04_stolen_bonus:RemoveOnDeath()		return true end
function modifier_thdots_yuuma04_stolen_bonus:IsDebuff()			return false end
function modifier_thdots_yuuma04_stolen_bonus:GetAttributes()		return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_thdots_yuuma04_stolen_bonus:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_EXTRA_STRENGTH_BONUS,
		MODIFIER_PROPERTY_MODEL_SCALE,
	}
end

function modifier_thdots_yuuma04_stolen_bonus:OnCreated(keys)
	if not IsServer() then return end

	self:SetStackCount(self:GetStackCount() + keys.stolen)
end

function modifier_thdots_yuuma04_stolen_bonus:GetModifierExtraStrengthBonus()
	return self:GetStackCount()
end

function modifier_thdots_yuuma04_stolen_bonus:GetModifierModelScale()
	return self:GetStackCount()/2
end

ability_thdots_yuuma04_end = {}

function ability_thdots_yuuma04_end:GetAssociatedPrimaryAbilities()
	return "ability_thdots_yuuma04"
end

function ability_thdots_yuuma04_end:ProcsMagicStick() return false end

function ability_thdots_yuuma04_end:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local ability = caster:FindAbilityByName("ability_thdots_yuuma04")

	-- 主动停止
	if caster:HasModifier("modifier_thdots_yuuma04_caster") and not caster:HasModifier("modifier_thdots_yuuma04_end_delay") then
		caster:AddNewModifier(caster, ability, "modifier_thdots_yuuma04_end_delay", {duration = ability:GetSpecialValueFor("end_delay")})
	end
end