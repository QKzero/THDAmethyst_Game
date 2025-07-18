function GetMaskValues(caster)
	mask = caster:GetModifierStackCount("modifier_ability_thdots_kokoroEx_2", caster)
	if mask == 1 then --怒面具加伤害
		xi = true
	else
		xi = false
	end
	if mask == 2 then --喜面具加移速
		you = true
	else
		you = false
	end
	if mask == 3 then --忧面具锁闭时间
		nu = true
	else
		nu = false
	end
	if caster:FindAbilityByName("special_bonus_unique_kokoro_5"):GetSpecialValueFor("value") ~= 0 then
		xi = true
		you = true
		nu = true
	end
	return xi, you, nu
end

--------------------------------------------------------
--吼怒的妖狐面
--------------------------------------------------------
ability_thdots_kokoro01 = {}


function ability_thdots_kokoro01:GetCooldown(level)
	return self.BaseClass.GetCooldown(self, level) - self:GetCaster():FindAbilityByName("special_bonus_unique_kokoro_2"):GetSpecialValueFor("value")
end

function ability_thdots_kokoro01:GetCastRange(location, target)
	if IsClient() then
		local caster = self:GetCaster()

		local range = self:GetSpecialValueFor("cast_range") + caster:GetCastRangeBonus()

		if caster:HasModifier("modifier_ability_thdots_kokoroEx_2") then
			local xi, you, nu = GetMaskValues(caster)

			if xi == true then
				range = range + self:GetSpecialValueFor("xi_cast_range")
			end
		end

		return range
	end
end

function ability_thdots_kokoro01:OnSpellStart()
	if not IsServer() then return end
	local duration = self:GetSpecialValueFor("duration")
	local damage = self:GetSpecialValueFor("damage")
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local range = self:GetSpecialValueFor("cast_range") + caster:GetCastRangeBonus()
	local xi_cast_range = self:GetSpecialValueFor("xi_cast_range")
	local distance = (point - caster:GetOrigin()):Length2D()
	local xi = nil
	local you = nil
	local nu = nil
	local mask = 0
	local caster_point = caster:GetOrigin()

	if caster:HasModifier("modifier_ability_thdots_kokoroEx_2") then
		xi, you, nu = GetMaskValues(caster)
		if xi == true then --怒面具加伤害,加400距离
			range = range + xi_cast_range
			damage = damage * 2
		end
		if you == true then --喜面具加移速
			caster:AddNewModifier(caster, self, "modifier_ability_thdots_kokoro01_movespeed_buff", {duration = self:GetSpecialValueFor("movespeed_duraiton")})
		end
		if nu == true then --忧面具锁闭时间
		end
	end
	if distance >= range then
		distance = range
	end
	point = caster:GetOrigin() +  caster:GetForwardVector() * distance
	local step_particle = ParticleManager:CreateParticle("particles/heroes/kokoro/kokoro_ability01_step.vpcf", PATTACH_WORLDORIGIN, self:GetCaster())
	ParticleManager:SetParticleControl(step_particle, 0, self:GetCaster():GetAbsOrigin())
	ParticleManager:SetParticleControl(step_particle, 1, point)
	ParticleManager:ReleaseParticleIndex(step_particle)
	self:GetCaster():EmitSound("Hero_VoidSpirit.AstralStep.Start")
	local targets = FindUnitsInLine(caster:GetTeam(), caster:GetOrigin(), point, nil,100,self:GetAbilityTargetTeam(),self:GetAbilityTargetType(),0)
	for _,v in pairs(targets) do
		if #targets > 0 then
			local closest = nil
			local closest_distance = nil
			for _,hero in pairs(targets) do
				if hero:IsHero() then
					if closest_distance == nil then
						closest_distance = (caster:GetOrigin() - hero:GetOrigin()):Length2D()
						closest = hero
					end
					if (caster:GetOrigin() - hero:GetOrigin()):Length2D() < closest_distance then
						closest_distance = (caster:GetOrigin() - hero:GetOrigin()):Length2D()
						closest = hero
					end
				end
			end
			if closest then
				closest:AddNewModifier(caster,self,"modifier_ability_thdots_kokoro01_debuff",{duration = duration* (1 - closest:GetStatusResistance())})
				if nu == true then
					closest:AddNewModifier(caster,self,"modifier_ability_thdots_kokoro01_debuff_you",{duration = duration* (1 - closest:GetStatusResistance())})
				end
			end
		end
		self.impact_particle = ParticleManager:CreateParticle("particles/econ/items/spectre/spectre_arcana/spectre_arcana_desolate_slash_target.vpcf", PATTACH_ABSORIGIN_FOLLOW, v)
		ParticleManager:SetParticleControlEnt(self.impact_particle, 0, v, PATTACH_POINT_FOLLOW, "attach_hitloc", v:GetAbsOrigin(), true)
		ParticleManager:ReleaseParticleIndex(self.impact_particle)
		v:EmitSound("Hero_VoidSpirit.AstralStep.Target")
		local damage_tabel = {
				victim 			= v,
				-- Damage starts ramping from when cast time starts, so just gonna simiulate the effects by adding the cast point
				damage 			= damage,
				damage_type		= self:GetAbilityDamageType(),
				damage_flags 	= self:GetAbilityTargetFlags(),
				attacker 		= caster,
				ability 		= self
			}
			-- if v:HasModifier("modifier_ability_thdots_kokoroEx") then
			-- 	damage_tabel.damage_type = DAMAGE_TYPE_PURE
			-- end
		UnitDamageTarget(damage_tabel)
	end
	FindClearSpaceForUnit(caster,point,true)
	if caster:HasModifier("modifier_ability_thdots_kokoroEx_2") then

		if caster:FindModifierByName("modifier_ability_thdots_kokoroEx_2"):GetStackCount() ~= 1 then
			ParticleManager:CreateParticle("particles/heroes/kokoro/kokoro_mood_icon_red.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetCaster())
			caster:SetMaterialGroup("red")
		end
		caster:FindModifierByName("modifier_ability_thdots_kokoroEx_2"):SetStackCount(1)
	end
end


modifier_ability_thdots_kokoro01_debuff = {} --锁闭状态
LinkLuaModifier("modifier_ability_thdots_kokoro01_debuff","scripts/vscripts/abilities/abilitykokoro.lua",LUA_MODIFIER_MOTION_NONE)

function modifier_ability_thdots_kokoro01_debuff:IsHidden() 		return false end
function modifier_ability_thdots_kokoro01_debuff:IsPurgable()		return true end
function modifier_ability_thdots_kokoro01_debuff:RemoveOnDeath() 	return true end
function modifier_ability_thdots_kokoro01_debuff:IsDebuff()		return true end

function modifier_ability_thdots_kokoro01_debuff:CheckState()
	return {
		[MODIFIER_STATE_MUTED] = true,
	}
end
modifier_ability_thdots_kokoro01_debuff_you = {} --沉默状态
LinkLuaModifier("modifier_ability_thdots_kokoro01_debuff_you","scripts/vscripts/abilities/abilitykokoro.lua",LUA_MODIFIER_MOTION_NONE)

function modifier_ability_thdots_kokoro01_debuff_you:IsHidden() 		return false end
function modifier_ability_thdots_kokoro01_debuff_you:IsPurgable()		return true end
function modifier_ability_thdots_kokoro01_debuff_you:RemoveOnDeath() 	return true end
function modifier_ability_thdots_kokoro01_debuff_you:IsDebuff()		return true end

function modifier_ability_thdots_kokoro01_debuff_you:CheckState()
	return {
		[MODIFIER_STATE_SILENCED] = true,
	}
end


modifier_ability_thdots_kokoro01_movespeed_buff = {} --移速状态
LinkLuaModifier("modifier_ability_thdots_kokoro01_movespeed_buff","scripts/vscripts/abilities/abilitykokoro.lua",LUA_MODIFIER_MOTION_NONE)

function modifier_ability_thdots_kokoro01_movespeed_buff:IsHidden() 		return false end
function modifier_ability_thdots_kokoro01_movespeed_buff:IsPurgable()		return true end
function modifier_ability_thdots_kokoro01_movespeed_buff:RemoveOnDeath() 	return true end
function modifier_ability_thdots_kokoro01_movespeed_buff:IsDebuff()		return false end

function modifier_ability_thdots_kokoro01_movespeed_buff:DeclareFunctions()
	return {
		-- MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_EVENT_ON_ATTACK_LANDED
	}
end
-- function modifier_ability_thdots_kokoro01_movespeed_buff:GetModifierMoveSpeedBonus_Percentage()
-- 	return self:GetAbility():GetSpecialValueFor("movespeed")
-- end
function modifier_ability_thdots_kokoro01_movespeed_buff:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("preattack_damage")
end
function modifier_ability_thdots_kokoro01_movespeed_buff:OnAttackLanded(keys)
	if not IsServer() then return end
	if keys.attacker == self:GetParent() then
		local heal = keys.damage * self:GetAbility():GetSpecialValueFor("life_steal") / 100
		if keys.target:HasModifier("modifier_ability_thdots_kokoroEx") then
			heal = keys.original_damage * self:GetAbility():GetSpecialValueFor("life_steal") / 100
		end
		self:GetParent():Heal(heal,self:GetParent())
		SendOverheadEventMessage(nil,OVERHEAD_ALERT_HEAL,self:GetParent(),heal,nil)
	end
end



--------------------------------------------------------
--狂喜的火男面
--------------------------------------------------------
ability_thdots_kokoro02 = {}

function ability_thdots_kokoro02:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function ability_thdots_kokoro02:GetCooldown(level)
	return self.BaseClass.GetCooldown(self, level) - self:GetCaster():FindAbilityByName("special_bonus_unique_kokoro_1"):GetSpecialValueFor("value")
end

function ability_thdots_kokoro02:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local mask = 0
	local damage = self:GetSpecialValueFor("damage")
	local slow_duration = self:GetSpecialValueFor("slow_duration")
	local heal = self:GetSpecialValueFor("heal")
	local radius = self:GetSpecialValueFor("radius") 
	local heal_count = 0
	local xi = nil
	local you = nil
	local nu = nil
	local stroke_particle = ParticleManager:CreateParticle("particles/heroes/kokoro/kokoro_ability02_fireworks.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:ReleaseParticleIndex(stroke_particle)
	if caster:HasModifier("modifier_ability_thdots_kokoroEx_2") then
		xi, you, nu = GetMaskValues(caster)
		if xi == true then --怒面具加伤害
			damage = damage * 2
		end
	end
	damage = damage + self:GetCaster():GetIntellect(false) * self:GetSpecialValueFor("intellect_bonus")
	local particle = ParticleManager:CreateParticle("particles/heroes/kokoro/kokoro_ability02_fire.vpcf", PATTACH_POINT, self:GetCaster())
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, 0, 0))
	ParticleManager:SetParticleControl(particle, 3, self:GetCaster():GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(particle)
	caster:EmitSound("Hero_DragonKnight.BreathFire")
	local targets = FindUnitsInRadius(caster:GetTeam(),caster:GetOrigin(),nil,radius,self:GetAbilityTargetTeam(),
	 								self:GetAbilityTargetType(),0,0,false)
	heal_count = #targets
	for _,v in pairs(targets) do
		if v:IsHero() then
			heal_count = heal_count +1
		end
		if nu == true then --忧面具减速
			v:AddNewModifier(caster,self,"modifier_ability_thdots_kokoro02_debuff",{duration = slow_duration* (1 - v:GetStatusResistance())})
		end
		local damage_tabel = {
				victim 			= v,
				-- Damage starts ramping from when cast time starts, so just gonna simiulate the effects by adding the cast point
				damage 			= damage,
				damage_type		= self:GetAbilityDamageType(),
				damage_flags 	= self:GetAbilityTargetFlags(),
				attacker 		= caster,
				ability 		= self
			}
			-- if v:HasModifier("modifier_ability_thdots_kokoroEx") then
			-- 	damage_tabel.damage_type = DAMAGE_TYPE_PURE
			-- end
		UnitDamageTarget(damage_tabel)
	end
	if you == true then 
		if FindTelentValue(self:GetCaster(),"special_bonus_unique_kokoro_1") ~= 0 then --天赋加三倍回血，改为减4秒CD
			-- heal = heal * 3
		end
		caster:Heal(heal * heal_count, caster)
		SendOverheadEventMessage(nil,OVERHEAD_ALERT_HEAL,caster,heal * heal_count,nil)
	end
	if caster:HasModifier("modifier_ability_thdots_kokoroEx_2") then

		if caster:FindModifierByName("modifier_ability_thdots_kokoroEx_2"):GetStackCount() ~= 2 then
			ParticleManager:CreateParticle("particles/heroes/kokoro/kokoro_mood_icon_green.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetCaster())
			caster:SetMaterialGroup("green")
		end
		caster:FindModifierByName("modifier_ability_thdots_kokoroEx_2"):SetStackCount(2)
	end
end

modifier_ability_thdots_kokoro02_debuff = {}
LinkLuaModifier("modifier_ability_thdots_kokoro02_debuff","scripts/vscripts/abilities/abilitykokoro.lua",LUA_MODIFIER_MOTION_NONE)

function modifier_ability_thdots_kokoro02_debuff:GetEffectName()
	return "particles/units/heroes/hero_huskar/huskar_inner_fire_debuff.vpcf"
end

function modifier_ability_thdots_kokoro02_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_ability_thdots_kokoro02_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("movement_slow")
end
--------------------------------------------------------
--忧心的鬼婆面
--------------------------------------------------------
ability_thdots_kokoro03 = class({})

function ability_thdots_kokoro03:GetAbilityTextureName()
	if self:GetCaster():HasModifier("modifier_ability_thdots_kokoro03_release") then
		return "custom/ability_thdots_kokoro03_release"
	else
		return "custom/ability_thdots_kokoro03"
	end
end

function ability_thdots_kokoro03:GetCastPoint()
	if not self:GetCaster():HasModifier("modifier_ability_thdots_kokoro03_release") then
		return self.BaseClass.GetCastPoint(self)
	else
		return 0.2
	end
end

function ability_thdots_kokoro03:GetManaCost(level)
	if not self:GetCaster():HasModifier("modifier_ability_thdots_kokoro03_release") then
		return self.BaseClass.GetManaCost(self, level)
	else
		return 0
	end
end

function ability_thdots_kokoro03:GetCastAnimation()
	if not self:GetCaster():HasModifier("modifier_ability_thdots_kokoro03_release") then
		return self.BaseClass.GetCastAnimation(self)
	else
		return ACT_DOTA_CAST_ABILITY_3_END
	end
end

function ability_thdots_kokoro03:GetBehavior()
	if not self:GetCaster():HasModifier("modifier_ability_thdots_kokoro03_release") then
		return self.BaseClass.GetBehavior(self)
	else
		return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES
	end
end

function ability_thdots_kokoro03:CastFilterResultTarget(hTarget)
	if hTarget == self:GetCaster() or hTarget:IsMagicImmune() then
		return UF_FAIL_CUSTOM
	end
end

-- function ability_thdots_kokoro03:GetAssociatedSecondaryAbilities()	return "ability_thdots_kokoro03_release" end

-- function ability_thdots_kokoro03:OnUpgrade()
-- 	if not self.release_ability then
-- 		self.release_ability = self:GetCaster():FindAbilityByName("ability_thdots_kokoro03_release")
-- 	end
	
-- 	if self.release_ability and not self.release_ability:IsTrained() then
-- 		self.release_ability:SetLevel(1)
-- 	end
-- end


function ability_thdots_kokoro03:OnSpellStart()
	if not IsServer() then return end
	local duration 				= self:GetSpecialValueFor("stun_duration") --眩晕时间
	local knockback_duration	= self:GetSpecialValueFor("knockback_duration")	--击退时间
	local knockback_distance	= self:GetSpecialValueFor("knockback_distance")
	local knockback_height 		= self:GetSpecialValueFor("knockback_height")
	local radius				= self:GetSpecialValueFor("radius")
	local you_stun_duration 		= self:GetSpecialValueFor("you_stun_duration")
	local damage 				= self:GetSpecialValueFor("damage")
	local blink_duration 		= self:GetSpecialValueFor("blink_duration")
	local caster = self:GetCaster()
	local target = self:GetCursorTarget() or caster.target

	if not caster:HasModifier("modifier_ability_thdots_kokoro03_release") then
		if is_spell_blocked(target,caster) then return end
		self.remain_time = self:GetCooldownTimeRemaining()
		self:EndCooldown()
		if caster:GetTeam() == target:GetTeam() then
			duration = knockback_duration
		end
		if target:HasModifier("modifier_thdots_yugi04_think_interval") then
			duration = 0.1
		end
		if target:HasModifier("modifier_thdots_Suika_04") and target:HasModifier("modifier_thdots_Suika_04_telent") then
			duration = 0.1
		end
		self:GetCaster().target = target
		local mask = 0
		local xi = nil
		local you = nil
		local nu = nil
		if caster:HasModifier("modifier_ability_thdots_kokoroEx_2") then
			xi, you, nu = GetMaskValues(caster)
			if xi == true then --怒面具加伤害和击飞距离
				damage = damage * 2
				knockback_distance = knockback_distance + 400
			end
			if you == true then --喜面具加移速
				caster:AddNewModifier(caster, self, "modifier_ability_thdots_kokoro03_movespeed_buff", {duration = self:GetSpecialValueFor("movespeed_duraiton")})
			end
			if nu == true then --忧面具眩晕周围
				local targets = FindUnitsInRadius(caster:GetTeam(),caster:GetOrigin(),nil,radius,DOTA_UNIT_TARGET_TEAM_ENEMY,
		 								DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,0,0,false)
				for _,v in pairs(targets) do
					UtilStun:UnitStunTarget(caster,v,you_stun_duration)
				end
			end
		end
		--这段代码是不打断的平移
		-- target:AddNewModifier(self:GetCaster(), self, "modifier_ability_thdots_kokoro03_knockback", {duration = knockback_duration ,
		-- 	 x = self:GetCaster():GetAbsOrigin().x, y = self:GetCaster():GetAbsOrigin().y,z = self:GetCaster():GetAbsOrigin().z})
		local knockback_properties = {
				 center_x 			= caster:GetOrigin().x,
				 center_y 			= caster:GetOrigin().y,
				 center_z 			= caster:GetOrigin().z,
				 duration 			= duration ,
				 knockback_duration = knockback_duration,
				 knockback_distance = knockback_distance,
				 knockback_height 	= knockback_height,
			}
		knockback_modifier = target:AddNewModifier(caster, self, "modifier_knockback", knockback_properties) --击飞
		local bash_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_spirit_breaker/spirit_breaker_greater_bash.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
		ParticleManager:ReleaseParticleIndex(bash_particle)
		target:EmitSound("Hero_Spirit_Breaker.GreaterBash")
		if target:GetTeam() ~= caster:GetTeam() then
			local damage_tabel = {
						victim 			= target,
						-- Damage starts ramping from when cast time starts, so just gonna simiulate the effects by adding the cast point
						damage 			= damage,
						damage_type		= self:GetAbilityDamageType(),
						damage_flags 	= self:GetAbilityTargetFlags(),
						attacker 		= caster,
						ability 		= self
					}
			-- if target:HasModifier("modifier_ability_thdots_kokoroEx") then
			-- 	damage_tabel.damage_type = DAMAGE_TYPE_PURE
			-- end
			UnitDamageTarget(damage_tabel)
		end
		-- if not self.release_ability then
		-- 	self.release_ability = self:GetCaster():FindAbilityByName("ability_thdots_kokoro03_release")
		-- end	
		-- if self.release_ability then
		-- 	self:GetCaster():SwapAbilities(self:GetName(), self.release_ability:GetName(), false,true)
			self:GetCaster():AddNewModifier(self:GetCaster(), self,"modifier_ability_thdots_kokoro03_release",{duration = blink_duration})
		-- 	self:GetCaster().IsChangeBack = false
		-- end
		if caster:HasModifier("modifier_ability_thdots_kokoroEx_2") then
			if caster:FindModifierByName("modifier_ability_thdots_kokoroEx_2"):GetStackCount() ~= 3 then
				ParticleManager:CreateParticle("particles/heroes/kokoro/kokoro_mood_icon_blue.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetCaster())
				caster:SetMaterialGroup("blue")
			end
			caster:FindModifierByName("modifier_ability_thdots_kokoroEx_2"):SetStackCount(3)
		end
	else
		local caster = self:GetCaster()
		-- self:StartCooldown(self:GetCooldown(self:GetLevel()))
		local effectIndex = ParticleManager:CreateParticle("particles/econ/events/ti9/blink_dagger_ti9_start_lvl2.vpcf", PATTACH_POINT, caster)
		ParticleManager:SetParticleControl(effectIndex, 0, caster:GetAbsOrigin())
		ParticleManager:DestroyParticleSystem(effectIndex, false)
		FindClearSpaceForUnit(caster,caster.target:GetOrigin(),true)
		caster:EmitSound("DOTA_Item.BlinkDagger.Activate")
		self:EndCooldown()
		caster:RemoveModifierByName("modifier_ability_thdots_kokoro03_release")
	end
end

modifier_ability_thdots_kokoro03_movespeed_buff = {} --移速状态,攻速状态
LinkLuaModifier("modifier_ability_thdots_kokoro03_movespeed_buff","scripts/vscripts/abilities/abilitykokoro.lua",LUA_MODIFIER_MOTION_NONE)

function modifier_ability_thdots_kokoro03_movespeed_buff:IsHidden() 		return false end
function modifier_ability_thdots_kokoro03_movespeed_buff:IsPurgable()		return true end
function modifier_ability_thdots_kokoro03_movespeed_buff:RemoveOnDeath() 	return true end
function modifier_ability_thdots_kokoro03_movespeed_buff:IsDebuff()		return false end

function modifier_ability_thdots_kokoro03_movespeed_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end
function modifier_ability_thdots_kokoro03_movespeed_buff:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("movespeed")
end
function modifier_ability_thdots_kokoro03_movespeed_buff:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("attackspeed")
end

modifier_ability_thdots_kokoro03_release = {}
LinkLuaModifier("modifier_ability_thdots_kokoro03_release","scripts/vscripts/abilities/abilitykokoro.lua",LUA_MODIFIER_MOTION_NONE)

function modifier_ability_thdots_kokoro03_release:IsHidden() 		return false end
function modifier_ability_thdots_kokoro03_release:IsPurgable()		return false end
function modifier_ability_thdots_kokoro03_release:RemoveOnDeath() 	return false end
function modifier_ability_thdots_kokoro03_release:IsDebuff()		return false end

function modifier_ability_thdots_kokoro03_release:OnCreated()
     if not IsServer() then return end
	self:StartIntervalThink(0.1)
	self:OnIntervalThink()
end

function modifier_ability_thdots_kokoro03_release:OnIntervalThink()
    --if not IsServer() then return end
	self.count = self:GetParent():GetModifierStackCount("modifier_ability_thdots_kokoro03_release", nil) + 1
    self:GetCaster():SetModifierStackCount("modifier_ability_thdots_kokoro03_release",self:GetAbility(), self.count)
end

function modifier_ability_thdots_kokoro03_release:OnDestroy()
	if not IsServer() then return end
	print(self.count)
	local remain_time = self:GetAbility().remain_time - self.count * 0.1
	print(remain_time)
	self:GetAbility():StartCooldown(remain_time)
end

-- function modifier_ability_thdots_kokoro03_release:OnDestroy()
-- 	if not IsServer() then return end
-- 	if not self:GetAbility().release_ability then
-- 		self:GetAbility().release_ability	= self:GetParent():FindAbilityByName("ability_thdots_kokoro03_release")
-- 	end
-- 	if not self:GetParent().IsChangeBack then
-- 		self:GetParent():SwapAbilities(self:GetAbility():GetName(), self:GetAbility().release_ability:GetName(), true,false)
-- 		self:GetParent().IsChangeBack = true
-- 	end
-- end

-- modifier_ability_thdots_kokoro03_knockback = class({})  --不打断的平移
-- LinkLuaModifier("modifier_ability_thdots_kokoro03_knockback","scripts/vscripts/abilities/abilitykokoro.lua",LUA_MODIFIER_MOTION_HORIZONTAL)

-- function modifier_ability_thdots_kokoro03_knockback:IsHidden() return false end

-- function modifier_ability_thdots_kokoro03_knockback:OnCreated(params)
-- 	if not IsServer() then return end
	
-- 	self.ability				= self:GetAbility()
-- 	self.caster					= self:GetCaster()
-- 	self.parent					= self:GetParent()
	
-- 	-- AbilitySpecials
-- 	self.knockback_duration		= self.ability:GetSpecialValueFor("knockback_duration")
-- 	-- Knockbacks a set distance, so change this value based on distance from caster and parent
-- 	self.knockback_distance		= math.max(self.ability:GetSpecialValueFor("knockback_distance") - (self.caster:GetAbsOrigin() - self.parent:GetAbsOrigin()):Length2D(), 50)
	
-- 	-- Calculate speed at which modifier owner will be knocked back
-- 	self.knockback_speed		= 1200
	
-- 	-- Get the center of the Blinding Light sphere to know which direction to get knocked back
-- 	self.position	= GetGroundPosition(Vector(params.x, params.y, 0), nil)
	
-- 	-- print(self:ApplyHorizontalMotionController())
-- 	if self:ApplyHorizontalMotionController() == false then 
-- 		self:Destroy()
-- 		return
-- 	end
-- end

-- function modifier_ability_thdots_kokoro03_knockback:UpdateHorizontalMotion( me, dt )
-- 	if not IsServer() then return end

-- 	local distance = (me:GetOrigin() - self.position):Normalized()
	
-- 	me:SetOrigin( me:GetOrigin() + distance * self.knockback_speed * dt )
	
-- 	-- Destroy any trees passed through
-- 	GridNav:DestroyTreesAroundPoint( self.parent:GetOrigin(), self.parent:GetHullRadius(), true )
-- end

-- function modifier_ability_thdots_kokoro03_knockback:DeclareFunctions()
-- 	local decFuncs = {
-- 		MODIFIER_PROPERTY_OVERRIDE_ANIMATION
--     }

--     return decFuncs
-- end

-- function modifier_ability_thdots_kokoro03_knockback:GetOverrideAnimation()
-- 	 return ACT_DOTA_FLAIL
-- end

-- function modifier_ability_thdots_kokoro03_knockback:OnDestroy()
-- 	if not IsServer() then return end
	
-- 	self.parent:RemoveHorizontalMotionController( self )
-- end
--------------------------------------------------------
--忧心的鬼婆面:二段近身
--------------------------------------------------------
ability_thdots_kokoro03_release = {}

function ability_thdots_kokoro03_release:IsStealable()	return false end
function ability_thdots_kokoro03_release:GetAssociatedSecondaryAbilities()	return "ability_thdots_kokoro03" end

function ability_thdots_kokoro03_release:OnSpellStart()
	if not IsServer() then return end
	if not self.kokoro03_ability then
		self.kokoro03_ability	= self:GetCaster():FindAbilityByName("ability_thdots_kokoro03")
	end	
	if self.kokoro03_ability then
		local caster = self:GetCaster()
		local effectIndex = ParticleManager:CreateParticle("particles/econ/events/ti9/blink_dagger_ti9_start_lvl2.vpcf", PATTACH_POINT, caster)
		ParticleManager:SetParticleControl(effectIndex, 0, caster:GetAbsOrigin())
		ParticleManager:DestroyParticleSystem(effectIndex, false)
		FindClearSpaceForUnit(caster,caster.target:GetOrigin(),true)
		caster:EmitSound("DOTA_Item.BlinkDagger.Activate")
	end
	self:GetCaster():SwapAbilities(self:GetName(), self.kokoro03_ability:GetName(), false, true)
	self:GetCaster().IsChangeBack = true
end

--------------------------------------------------------
--「假面丧心舞·暗黑能乐」
--------------------------------------------------------
ability_thdots_kokoro04 = {}

function ability_thdots_kokoro04:CastFilterResultTarget( hTarget )
	if self:GetCaster() == hTarget then
		return UF_FAIL_CUSTOM
	end

	if hTarget:IsCreep() and ( not self:GetCaster():HasModifier("modifier_item_wanbaochui") ) then
		return UF_FAIL_CUSTOM
	end

	local nResult = UnitFilter( hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, self:GetCaster():GetTeamNumber() )
	if nResult ~= UF_SUCCESS then
		return nResult
	end

	return UF_SUCCESS
end

function ability_thdots_kokoro04:GetCustomCastErrorTarget( hTarget )
	if self:GetCaster() == hTarget then
		return "#dota_hud_error_cant_cast_on_self"
	end

	if hTarget:IsCreep() and ( not self:GetCaster():HasModifier("modifier_item_wanbaochui") ) then
		return "#dota_hud_error_cant_cast_on_creep"
	end

	return ""
end

-- function ability_thdots_kokoro04:GetCastAnimation()
-- 	if not self:GetCaster():HasModifier("modifier_item_wanbaochui") then
-- 		return self.BaseClass.GetCastAnimation(self)
-- 	else
-- 		return ACT_DOTA_CAST_ABILITY_4_END
-- 	end
-- end

function ability_thdots_kokoro04:OnSpellStart()
	self.target = self:GetCursorTarget()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	caster.target = target
	if is_spell_blocked(target) then return end
	if self:GetCaster():GetName() == "npc_dota_hero_legion_commander" then
		self:GetCaster():EmitSound("Voice_Thdots_Kokoro.AbilityKokoro04")
	end
	caster:EmitSound("Hero_Grimstroke.InkSwell.Cast")
	local ink_swell_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_grimstroke/grimstroke_cast_ink_swell.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControlEnt(ink_swell_particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack", caster:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(ink_swell_particle)

	caster:AddNewModifier(caster, self, "modifier_ability_thdots_kokoro04_caster",{duration = 0.9})
	caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_4,1)

	caster:FindAbilityByName("ability_thdots_kokoro04_WBC"):StartCooldown(self:GetCooldownTime())
end

function ability_thdots_kokoro04:OnUpgrade()
	local caster = self:GetCaster()
	local ability01 = self
	local ability02 = caster:FindAbilityByName("ability_thdots_kokoro04_WBC")
	if caster:GetClassname()~="npc_dota_hero_legion_commander" then return end
	if caster.upgrading == nil then caster.upgrading = false end
	if caster.upgrading~=true then
		caster.upgrading = true
		ability02:SetLevel(ability01:GetLevel())
		caster.upgrading = false
	end
end

function ability_thdots_kokoro04:OnInventoryContentsChanged()
	if IsServer() then
		local caster = self:GetCaster()
		local ability = caster:FindAbilityByName("ability_thdots_kokoro04")
		--print("swap")
		local ability_WBC = caster:FindAbilityByName("ability_thdots_kokoro04_WBC")
		if caster:HasScepter() then
			caster:UnHideAbilityToSlot("ability_thdots_kokoro04_WBC", "ability_thdots_kokoro04")
			--print("swap1")
		else
			caster:UnHideAbilityToSlot("ability_thdots_kokoro04", "ability_thdots_kokoro04_WBC")
			--print("swap2")
		end
	end
end
function ability_thdots_kokoro04:OnItemEquipped()
	if IsServer() then
		local caster = self:GetCaster()
		local ability = caster:FindAbilityByName("ability_thdots_kokoro04")
		--print("swap")
		local ability_WBC = caster:FindAbilityByName("ability_thdots_kokoro04_WBC")
		if caster:HasScepter() then
			caster:UnHideAbilityToSlot("ability_thdots_kokoro04_WBC", "ability_thdots_kokoro04")
			--print("swap1")
		else
			caster:UnHideAbilityToSlot("ability_thdots_kokoro04", "ability_thdots_kokoro04_WBC")
			--print("swap2")
		end
	end
end
ability_thdots_kokoro04_WBC = {}

function ability_thdots_kokoro04_WBC:OnUpgrade()
	local caster = self:GetCaster()
	local ability01 = caster:FindAbilityByName("ability_thdots_kokoro04")
	local ability02 = self
	if caster:GetClassname()~="npc_dota_hero_legion_commander" then return end
	if caster.upgrading == nil then caster.upgrading = false end
	if caster.upgrading~=true then
		caster.upgrading = true
		ability01:SetLevel(ability02:GetLevel())
		caster.upgrading = false
	end
end

function ability_thdots_kokoro04_WBC:OnSpellStart()
	self.target = self:GetCursorTarget()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	caster.target = target
	if is_spell_blocked(target) then return end
	if self:GetCaster():GetName() == "npc_dota_hero_legion_commander" then
		self:GetCaster():EmitSound("Voice_Thdots_Kokoro.AbilityKokoro04")
	end
	caster:EmitSound("Hero_Grimstroke.InkSwell.Cast")
	local ink_swell_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_grimstroke/grimstroke_cast_ink_swell.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControlEnt(ink_swell_particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack", caster:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(ink_swell_particle)

	local mask = 0
	local duration = self:GetSpecialValueFor("duration")
	if caster:HasModifier("modifier_ability_thdots_kokoroEx_2") then
		local xi, you, nu = GetMaskValues(caster)
		if xi == true then --怒面具加持续时间
			duration = duration + self:GetSpecialValueFor("xi_duration")
		end
		if you == true then --喜面具吸血
		end
		if nu == true then --忧面具结束眩晕
		end
	end
	caster:AddNewModifier(caster, self, "modifier_ability_thdots_kokoro04_caster_wanbaochui",{duration = duration})
	caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_4_END,caster:GetDisplayAttackSpeed()/100)
	caster:Purge(false,true,false,true,false)
	
	caster:FindAbilityByName("ability_thdots_kokoro04"):StartCooldown(self:GetCooldownTime())
end

modifier_ability_thdots_kokoro04_caster = {}
modifier_ability_thdots_kokoro04_caster_wanbaochui = {}
modifier_ability_thdots_kokoro04_target = {}
modifier_ability_thdots_kokoro04_cant_buyback = {}
LinkLuaModifier("modifier_ability_thdots_kokoro04_caster","scripts/vscripts/abilities/abilitykokoro.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ability_thdots_kokoro04_caster_wanbaochui","scripts/vscripts/abilities/abilitykokoro.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ability_thdots_kokoro04_target","scripts/vscripts/abilities/abilitykokoro.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ability_thdots_kokoro04_cant_buyback","scripts/vscripts/abilities/abilitykokoro.lua",LUA_MODIFIER_MOTION_NONE)

function modifier_ability_thdots_kokoro04_caster_wanbaochui:CheckState()
	return {
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_MAGIC_IMMUNE] = true,
	}
end

-- function modifier_ability_thdots_kokoro04_caster_wanbaochui:DeclareFunctions()
-- 	return {
-- 		MODIFIER_EVENT_ON_ATTACK_LANDED
-- 		}
-- end

-- function modifier_ability_thdots_kokoro04_caster_wanbaochui:OnAttackLanded(keys)
-- 	if not IsServer() then return end
-- 	if keys.attacker == self:GetParent() then
-- 		if keys.attacker:HasModifier("modifier_ability_thdots_kokoroEx_2") then
-- 			local mask = keys.attacker:FindModifierByName("modifier_ability_thdots_kokoroEx_2"):GetStackCount()
-- 			if mask == 2 or FindTelentValue(keys.attacker,"special_bonus_unique_kokoro_5") ~= 0 then
-- 				local heal = keys.damage * self:GetAbility():GetSpecialValueFor("life_steal") / 100
-- 				if keys.target:HasModifier("modifier_ability_thdots_kokoroEx") then
-- 					heal = keys.original_damage * self:GetAbility():GetSpecialValueFor("life_steal") / 100
-- 				end
-- 				self:GetParent():Heal(heal,self:GetParent())
-- 				SendOverheadEventMessage(nil,OVERHEAD_ALERT_HEAL,self:GetParent(),heal,nil)
-- 			end
-- 		end
-- 	end
-- end


function modifier_ability_thdots_kokoro04_caster_wanbaochui:StatusEffectPriority()
	return 20
end

function modifier_ability_thdots_kokoro04_caster_wanbaochui:GetStatusEffectName()
	return "particles/status_fx/status_effect_omnislash.vpcf"
end
function modifier_ability_thdots_kokoro04_caster_wanbaochui:OnCreated(keys)
	if not IsServer() then return end
	self.caster = self:GetParent()
	self.target = self:GetAbility().target
	self.int_time_max = 0.2
	self.int_time = 0
	local dummy = CreateUnitByName(
				"npc_vision_hatate_dummy_unit"
				,self.target:GetAbsOrigin()
				,false
				,self.caster
				,self.caster
				,self.caster:GetTeam()
				)
				dummy:SetNightTimeVisionRange(200)
				dummy:SetDayTimeVisionRange(200)
				local ability_dummy_unit = dummy:FindAbilityByName("ability_dummy_unit")
				ability_dummy_unit:SetLevel(1)
				local time = 0
				dummy:SetContextThink("vision_dummy_think",
					function()
						if GameRules:IsGamePaused() then return 0.03 end
						if time>=1 then 
							dummy:ForceKill(false)
							return nil 
						end
						time = time + 0.2
						return 0.2
					end,0
				)
		self:StartIntervalThink(100/self.caster:GetDisplayAttackSpeed())
end

function modifier_ability_thdots_kokoro04_caster_wanbaochui:OnIntervalThink()
	if IsServer() then
		if self.target ~= nil then
			local next_point = self.target:GetAbsOrigin() + RandomVector(128)
			local trail_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_juggernaut/juggernaut_omni_slash_trail.vpcf", PATTACH_CUSTOMORIGIN, self.caster)
			ParticleManager:SetParticleControl(trail_pfx, 0, Vector(next_point.x, next_point.y, next_point.z))
			ParticleManager:SetParticleControl(trail_pfx, 1, self:GetCaster():GetAbsOrigin())
			ParticleManager:ReleaseParticleIndex(trail_pfx)
			FindClearSpaceForUnit(self.caster, next_point, true)
			self.caster:FaceTowards(self.target:GetOrigin())

		-- local vec = (self.target:GetOrigin() - self.caster:GetOrigin()):Normalized()
		-- vec.z = 0
		-- self.int_time = 0.5
		-- if self.target:GetOrigin() ~= self.caster:GetOrigin() then
		-- print(vec)
		-- 	self.caster:SetContextThink("kokoro04_ability", function()
		-- 		if GameRules:IsGamePaused() then return FrameTime() end
		-- 		self.int_time = self.int_time - FrameTime()
		-- 		if self.int_time > 0 then
		-- 			self.caster:SetForwardVector(vec)
		-- 			return FrameTime()
		-- 		else
		-- 			return
		-- 		end
		-- 	end,0)
		-- end

			local trail_pfx1 = ParticleManager:CreateParticle("particles/units/heroes/hero_juggernaut/juggernaut_omni_slash_trail.vpcf", PATTACH_ABSORIGIN,self.caster)
			ParticleManager:SetParticleControl(trail_pfx1, 0, self.caster:GetOrigin())
			ParticleManager:SetParticleControl(trail_pfx1, 1, self.target:GetOrigin())
			ParticleManager:ReleaseParticleIndex(trail_pfx1)
			if self.caster:GetName() == "npc_dota_hero_legion_commander" then
				if self.caster:GetDisplayAttackSpeed() > 300 and RollPercentage(50) then
					self.caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_7,self.caster:GetDisplayAttackSpeed()/100)
				elseif RollPercentage(20) then
					self.caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_3,self.caster:GetDisplayAttackSpeed()/100)
				elseif RollPercentage(40) then
					self.caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_1,self.caster:GetDisplayAttackSpeed()/100)
				elseif RollPercentage(60) then
					self.caster:StartGestureWithPlaybackRate(ACT_DOTA_ATTACK,self.caster:GetDisplayAttackSpeed()/100)
			-- elseif RollPercentage(80) then
			-- 	self.caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_7,self.caster:GetDisplayAttackSpeed()/100)
				else
					self.caster:StartGestureWithPlaybackRate(ACT_DOTA_ATTACK2,self.caster:GetDisplayAttackSpeed()/100)
				end
			end
			local HasAegis = self.target:HasModifier("modifier_item_aegis")
			if self.target:FindModifierByName("modifier_ability_thdots_kokoro04_target") == nil 
				and self.target:IsRealHero() 
				and not self.target:HasModifier("modifier_illusion") then
				self.target:AddNewModifier(self.caster,self:GetAbility(),"modifier_ability_thdots_kokoro04_target",{duration = 0.05})
			end
			local yuyuko_dead_flag = false
			if self.target:GetContext("ability_yuyuko_Ex_deadflag") == 0 then --判定UUZ是否死亡
				yuyuko_dead_flag = true
			end

			local kokoro04_attack = "particles/econ/items/juggernaut/jugg_arcana/juggernaut_arcana_v2_omni_slash_tgt_bladekeeper.vpcf"
			local trail_pfx = ParticleManager:CreateParticle(kokoro04_attack, PATTACH_CUSTOMORIGIN, self.target)
			ParticleManager:SetParticleControl(trail_pfx, 0, self.target:GetOrigin())
			ParticleManager:SetParticleControl(trail_pfx, 1, self.target:GetOrigin())
			ParticleManager:ReleaseParticleIndex(trail_pfx)
			self.caster:EmitSound("Voice_Thdots_Kokoro.AbilityKokoro04_attack")
			self.caster:PerformAttack(self.target, true, true, true, true, false, false, false)
			self.int_time = 0
			--若UUZ被此伤害击杀，则附带刷新判定buff
			if self.target:GetClassname()=="npc_dota_hero_necrolyte" and self.target:GetContext("ability_yuyuko_Ex_deadflag") == 1 and self.target:IsRealHero() and yuyuko_dead_flag == true then
				self.target:AddNewModifier(self.caster, self:GetAbility(), "modifier_ability_thdots_kokoro04_target",{duration = 11}) --UUZ死亡10秒。给11秒
			end
			if self.caster:HasModifier("modifier_ability_thdots_kokoroEx_2") then
				local xi, you, nu = GetMaskValues(self.caster)
				if you == true then
					local heal = self.caster:GetAverageTrueAttackDamage(self.caster) * self:GetAbility():GetSpecialValueFor("life_steal") / 100
					self.caster:Heal(heal,self.caster)
					SendOverheadEventMessage(nil,OVERHEAD_ALERT_HEAL,self.caster,heal,nil)
				end
			end
		end
		next_target = FindUnitsInRadius(self.caster:GetTeam(), self.caster:GetOrigin(),nil,500,self:GetAbility():GetAbilityTargetTeam(),
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES+ DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE,0,false)
		for i = 1,#next_target do
			if next_target[i] == nil then 
				print("args")
				break
			end
			if next_target[i]:HasModifier("dummy_unit") or not self.caster:CanEntityBeSeenByMyTeam(next_target[i]) or not next_target[i]:IsAlive() 
				or next_target[i]:HasModifier("modifier_item_tsundere_invulnerable") or next_target[i]:HasModifier("modifier_sanae04_invulnerable") 
				or next_target[i]:IsUnselectable() then
				-- table.remove(next_target,i)
				next_target[i] = nil
			end
		end
		if #next_target == 0 then 
			self.int_time =  self.int_time + 100/self.caster:GetDisplayAttackSpeed()
			if self.int_time >= self.int_time_max then
				self.caster:RemoveModifierByName("modifier_ability_thdots_kokoro04_caster_wanbaochui")
				return
			else
				self.target = nil
			end
		end
		for i = 1,#next_target do
			if next_target[i] ~= nil and not next_target[i]:IsAlive() or not self.caster:CanEntityBeSeenByMyTeam(next_target[i]) or next_target[i]:HasModifier("dummy_unit") 
				or next_target[i]:HasModifier("modifier_item_tsundere_invulnerable") or next_target[i]:HasModifier("modifier_sanae04_invulnerable") 
				or next_target[i]:IsUnselectable() then
				-- print(next_target[i]:IsAlive())
				-- print(next_target[i]:HasModifier("dummy_unit"))
			else
				self.target = next_target[i]
				local dummy = CreateUnitByName(
				"npc_vision_hatate_dummy_unit"
				,self.target:GetAbsOrigin()
				,false
				,self.caster
				,self.caster
				,self.caster:GetTeam()
				)
				dummy:SetNightTimeVisionRange(200)
				dummy:SetDayTimeVisionRange(200)
				local ability_dummy_unit = dummy:FindAbilityByName("ability_dummy_unit")
				ability_dummy_unit:SetLevel(1)
				local time = 0
				dummy:SetContextThink("vision_dummy_think",
					function()
						if GameRules:IsGamePaused() then return 0.03 end
						if time>=1 then 
							dummy:ForceKill(false)
							return nil 
						end
						time = time + 0.2
						return 0.2
					end,0
				)
				-- print(self.target:GetName())
				-- print(self.target:IsAlive())
			end
		end
	end
end

function modifier_ability_thdots_kokoro04_caster_wanbaochui:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_DEATH
	}
end

function modifier_ability_thdots_kokoro04_caster_wanbaochui:OnDeath(keys)
	if not keys.unit:IsRealHero() then return end
	if keys.attacker == self:GetCaster() then
		local caster = keys.attacker
		if FindTelentValue(self:GetCaster(),"special_bonus_unique_kokoro_6") ~= 0 then --刷新所有技能
			kokoro04_refresh_effect(caster)
			self:GetAbility():EndCooldown()
			if caster:FindAbilityByName("ability_thdots_kokoro01") then
				caster:FindAbilityByName("ability_thdots_kokoro01"):EndCooldown()
			end
			if caster:FindAbilityByName("ability_thdots_kokoro02") then
				caster:FindAbilityByName("ability_thdots_kokoro02"):EndCooldown()
			end
			if caster:FindAbilityByName("ability_thdots_kokoro03") then
				caster:FindAbilityByName("ability_thdots_kokoro03"):EndCooldown()
			end
			if caster:FindAbilityByName("ability_thdots_kokoroEx") then
				caster:FindAbilityByName("ability_thdots_kokoroEx"):EndCooldown()
			end
			if caster:FindAbilityByName("ability_thdots_kokoroEx_2") then
				caster:FindAbilityByName("ability_thdots_kokoroEx_2"):EndCooldown()
			end
		end
	end
end

function modifier_ability_thdots_kokoro04_caster_wanbaochui:OnDestroy()
	if not IsServer() then return end
	if self:GetParent():HasModifier("modifier_ability_thdots_kokoroEx_2") then
		local xi, you, nu = GetMaskValues(self:GetCaster())
		if nu == true then
			targets = FindUnitsInRadius(self:GetParent():GetTeam(),self:GetParent():GetOrigin(),nil,600,self:GetAbility():GetAbilityTargetTeam(),
			DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,0,0,false)
			for _,v in pairs(targets) do
				UtilStun:UnitStunTarget(self:GetParent(),v,self:GetAbility():GetSpecialValueFor("stun_duration"))
			end
		end
	end
	if self:GetCaster():HasModifier("modifier_ability_thdots_kokoroEx_2") then
		self:GetCaster():FindModifierByName("modifier_ability_thdots_kokoroEx_2"):SetStackCount(0)
	end
end

function modifier_ability_thdots_kokoro04_target:IsHidden() 		return false end
function modifier_ability_thdots_kokoro04_target:IsPurgable()		return false end
function modifier_ability_thdots_kokoro04_target:RemoveOnDeath() 	return true end
function modifier_ability_thdots_kokoro04_target:IsDebuff()		return false end

function modifier_ability_thdots_kokoro04_target:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_DEATH
	}
end

function modifier_ability_thdots_kokoro04_target:OnDeath(keys)
	if not keys.unit:IsRealHero() then return end
	if keys.attacker == self:GetCaster() then
		local caster = keys.attacker
		if FindTelentValue(self:GetCaster(),"special_bonus_unique_kokoro_6") ~= 0 then --刷新所有技能
			kokoro04_refresh_effect(caster)
			self:GetAbility():EndCooldown()
			if caster:FindAbilityByName("ability_thdots_kokoro01") then
				caster:FindAbilityByName("ability_thdots_kokoro01"):EndCooldown()
			end
			if caster:FindAbilityByName("ability_thdots_kokoro02") then
				caster:FindAbilityByName("ability_thdots_kokoro02"):EndCooldown()
			end
			if caster:FindAbilityByName("ability_thdots_kokoro03") then
				caster:FindAbilityByName("ability_thdots_kokoro03"):EndCooldown()
			end
			if caster:FindAbilityByName("ability_thdots_kokoroEx") then
				caster:FindAbilityByName("ability_thdots_kokoroEx"):EndCooldown()
			end
			if caster:FindAbilityByName("ability_thdots_kokoroEx_2") then
				caster:FindAbilityByName("ability_thdots_kokoroEx_2"):EndCooldown()
			end
		end
	end
end

-----------------------------------------------------------------------------

function modifier_ability_thdots_kokoro04_caster:IsHidden() 		return true end
function modifier_ability_thdots_kokoro04_caster:IsPurgable()		return false end
function modifier_ability_thdots_kokoro04_caster:RemoveOnDeath() 	return true end
function modifier_ability_thdots_kokoro04_caster:IsDebuff()		return false end


-- function modifier_ability_thdots_kokoro04_caster:GetEffectName()
-- 	return "particles/units/heroes/hero_grimstroke/grimstroke_dark_artistry_debuff.vpcf"
-- end
function modifier_ability_thdots_kokoro04_caster:GetStatusEffectName()
	return "particles/status_fx/status_effect_grimstroke_ink_swell.vpcf"
end

function modifier_ability_thdots_kokoro04_caster:CheckState()
	return {
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true
		-- [MODIFIER_STATE_STUNNED] = true
	}
end

function modifier_ability_thdots_kokoro04_caster:OnCreated()
	self.caster = self:GetParent()
	self.target = self:GetAbility().target
	-- print("name is :" .. self.caster.target:GetName())
	-- print("ability name is :" .. self:GetAbility().target:GetName())
	self:StartIntervalThink(FrameTime())
end

function modifier_ability_thdots_kokoro04_caster:OnIntervalThink()
	if not IsServer() then return end
	if not self.target:IsAlive() then
		self:SetStackCount(1)
		self:Destroy()
		self.caster:StopSound("Voice_Thdots_Kokoro.AbilityKokoro04")
		return
	end
	local vec = self.target:GetAbsOrigin() - self.caster:GetAbsOrigin()
	vec.z = 0
	if vec.x == 0 and vec.y == 0 then
	else
		-- self.caster:SetForwardVector(vec:Normalized())
		self.caster:FaceTowards(self.target:GetOrigin())
	end
end

function modifier_ability_thdots_kokoro04_caster:OnDestroy()
	if not IsServer() then return end
	local caster = self:GetParent()
	local target = self:GetAbility().target
	local damage = self:GetAbility():GetSpecialValueFor("damage")
	local buyback_time = self:GetAbility():GetSpecialValueFor("buyback_time")
	local HasAegis = target:HasModifier("modifier_item_aegis")
	if not caster:IsAlive() or self:GetStackCount() == 1 then 
		self:GetAbility():EndCooldown()
		return 
	end --caster死亡不触发,重置冷却
	damage = damage * (target:GetMaxHealth() - target:GetHealth()) --造成伤害
	local mask = 0
	if caster:HasModifier("modifier_ability_thdots_kokoroEx_2") then
		local xi, you, nu = GetMaskValues(caster)
		if xi == true then --怒面具加伤害
			damage = damage + self:GetAbility():GetSpecialValueFor("xi_damage")
		end
		if you == true then --喜面具恢复一半生命
			local heal = 0
			if damage > target:GetMaxHealth() then
				heal = target:GetMaxHealth()
				caster:Heal(heal, caster)
				SendOverheadEventMessage(nil,OVERHEAD_ALERT_HEAL,caster,heal,nil)
			else
				heal = damage
				caster:Heal(heal, caster)
				SendOverheadEventMessage(nil,OVERHEAD_ALERT_HEAL,caster,heal,nil)
			end
		end
		if nu == true then --忧面具无法买活
		end
	end
	local distance = (target:GetOrigin() - caster:GetOrigin()):Length2D() + 300
	local point = caster:GetOrigin() + caster:GetForwardVector() * distance
	-- caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_5,8)
	local coup_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact_lv.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(coup_pfx, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(coup_pfx, 1, target:GetAbsOrigin())
	ParticleManager:SetParticleControlOrientation(coup_pfx, 1, self:GetParent():GetForwardVector() * (-1), self:GetParent():GetRightVector(), self:GetParent():GetUpVector())
	ParticleManager:ReleaseParticleIndex(coup_pfx)

	local kokoro04_kill = ParticleManager:CreateParticle("particles/econ/items/phantom_assassin/phantom_assassin_arcana_elder_smith/phantom_assassin_crit_impact_dagger_arcana.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(kokoro04_kill, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(kokoro04_kill, 1, target:GetAbsOrigin())
	ParticleManager:SetParticleControlOrientation(kokoro04_kill, 1, caster:GetForwardVector() * (-1), caster:GetRightVector(), caster:GetUpVector())
	ParticleManager:ReleaseParticleIndex(kokoro04_kill)

	local ability = self:GetAbility()
	ProjectileManager:CreateLinearProjectile({
				Ability = ability,
				EffectName = "particles/units/heroes/hero_grimstroke/grimstroke_darkartistry_proj.vpcf",
				vSpawnOrigin = caster:GetAbsOrigin(),
				fDistance = distance,
				fStartRadius = 150,
				fEndRadius = 150,
				fExpireTime = GameRules:GetGameTime() + 10.0,
				Source = caster,
				bHasFrontalCone = false,
				bReplaceExisting = false,
				iUnitTargetTeam = ability:GetAbilityTargetTeam(),							
				iUnitTargetType = ability:GetAbilityTargetType(),							
				bDeleteOnHit = false,
				vVelocity = ((point - caster:GetAbsOrigin()) * Vector(1, 1, 0)):Normalized() * 7500,
				bProvidesVision = false,	
			})
	target:EmitSound("Hero_PhantomAssassin.CoupDeGrace")
	target:EmitSound("Hero_PhantomAssassin.Arcana_Layer")
	FindClearSpaceForUnit(caster,point ,true)
	local damage_tabel = {
					victim 			= target,
					-- Damage starts ramping from when cast time starts, so just gonna simiulate the effects by adding the cast point
					damage 			= damage,
					damage_type		= self:GetAbility():GetAbilityDamageType(),
					damage_flags 	= self:GetAbility():GetAbilityTargetFlags(),
					attacker 		= caster,
					ability 		= self:GetAbility()
				}
	-- if target:HasModifier("modifier_ability_thdots_kokoroEx") then
	-- 	damage_tabel.damage_type = DAMAGE_TYPE_PURE
	-- end
	-- 为幽幽子大招击杀附上BUFF
	local yuyuko_dead_flag = false
	if target:GetContext("ability_yuyuko_Ex_deadflag") == 0 then --判定UUZ是否死亡
		yuyuko_dead_flag = true
	end
	UnitDamageTarget(damage_tabel)
	--若UUZ被此伤害击杀，则附带刷新判定buff
	if target and not target:IsNull() and target:GetClassname()=="npc_dota_hero_necrolyte" and target:GetContext("ability_yuyuko_Ex_deadflag") == 1 and target:IsRealHero() and yuyuko_dead_flag == true then
		target:AddNewModifier(caster, self:GetAbility(), "modifier_ability_thdots_kokoro04_target",{duration = 11})
	end
	if not HasAegis and target and not target:IsNull() and not target:IsAlive() and target:IsRealHero() then
		if nu == true then
			target:SetBuybackCooldownTime(buyback_time)
		end
		if FindTelentValue(self:GetCaster(),"special_bonus_unique_kokoro_6") ~= 0 then --刷新所有技能
			print("shuaxin")
			kokoro04_refresh_effect(caster)
			self:GetAbility():EndCooldown()
			if caster:FindAbilityByName("ability_thdots_kokoro01") then
				caster:FindAbilityByName("ability_thdots_kokoro01"):EndCooldown()
			end
			if caster:FindAbilityByName("ability_thdots_kokoro02") then
				caster:FindAbilityByName("ability_thdots_kokoro02"):EndCooldown()
			end
			if caster:FindAbilityByName("ability_thdots_kokoro03") then
				caster:FindAbilityByName("ability_thdots_kokoro03"):EndCooldown()
			end
			if caster:FindAbilityByName("ability_thdots_kokoroEx") then
				caster:FindAbilityByName("ability_thdots_kokoroEx"):EndCooldown()
			end
			if caster:FindAbilityByName("ability_thdots_kokoroEx_2") then
				caster:FindAbilityByName("ability_thdots_kokoroEx_2"):EndCooldown()
			end
		end
	end
	if self:GetCaster():HasModifier("modifier_ability_thdots_kokoroEx_2") then
		self:GetCaster():FindModifierByName("modifier_ability_thdots_kokoroEx_2"):SetStackCount(0)
	end
end

function kokoro04_refresh_effect(caster)
	caster:EmitSound("Voice_Thdots_Kokoro.AbilityKokoro04_kill")
	local kokoro04_attack = "particles/econ/items/juggernaut/jugg_arcana/juggernaut_arcana_v2_trigger.vpcf"
	local trail_pfx = ParticleManager:CreateParticle(kokoro04_attack, PATTACH_CUSTOMORIGIN, caster)
	-- ParticleManager:SetParticleControl(trail_pfx, 0, caster:GetOrigin())
	ParticleManager:SetParticleControlEnt(trail_pfx , 0, caster, 5, "attach_hitloc", Vector(0,0,0), true)
	ParticleManager:SetParticleControlEnt(trail_pfx , 1, caster, 5, "attach_hitloc", Vector(0,0,0), true)
	ParticleManager:SetParticleControlEnt(trail_pfx , 2, caster, 5, "attach_hitloc", Vector(0,0,0), true)
	ParticleManager:ReleaseParticleIndex(trail_pfx)
end
--------------------------------------------------------
--凭依「喜怒哀乐Possession」
--------------------------------------------------------
ability_thdots_kokoroEx = {}

function ability_thdots_kokoroEx:GetCooldown(level)
	return self.BaseClass.GetCooldown(self, level) - self:GetCaster():FindAbilityByName("special_bonus_unique_kokoro_4"):GetSpecialValueFor("value")
end

function ability_thdots_kokoroEx:OnSpellStart()
	if not IsServer() then return end
	-- local target = self:GetCursorTarget()
	-- if is_spell_blocked(target) then return end

	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor("duration")
	local radius = self:GetSpecialValueFor("radius")
	local targets = FindUnitsInRadius(caster:GetTeam(),caster:GetOrigin(),nil,radius,self:GetAbilityTargetTeam(),
	 								self:GetAbilityTargetType(),0,0,false)
	for _,v in pairs(targets) do
		v:AddNewModifier(self:GetCaster(), self, "modifier_ability_thdots_kokoroEx",{duration = duration* (1 - v:GetStatusResistance())})
	end
	if self:GetCaster():GetName() == "npc_dota_hero_legion_commander" then
		self:GetCaster():EmitSound("Voice_Thdots_Kokoro.AbilityKokoroEx")
	end
	local particle_pact = "particles/units/heroes/hero_monkey_king/monkey_king_weapon_blur_b_cud.vpcf"
	local particle_pact_fx = ParticleManager:CreateParticle(particle_pact, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:ReleaseParticleIndex(particle_pact_fx)
	caster:EmitSound("Hero_Grimstroke.InkCreature.Spawn")
end

modifier_ability_thdots_kokoroEx = {}
LinkLuaModifier("modifier_ability_thdots_kokoroEx","scripts/vscripts/abilities/abilitykokoro.lua",LUA_MODIFIER_MOTION_NONE)

function modifier_ability_thdots_kokoroEx:IsHidden() 		return false end
function modifier_ability_thdots_kokoroEx:RemoveOnDeath() 	return true end
function modifier_ability_thdots_kokoroEx:IsDebuff()		return true end
function modifier_ability_thdots_kokoroEx:IsPurgable()  --天赋无法驱散
	-- if not IsServer() then return end
	if  self:GetCaster():HasModifier("modifier_ability_thdots_kokoroEx_2_talent3") then
		return false
	else
		return true
	end
end
function modifier_ability_thdots_kokoroEx:GetEffectName()
	return "particles/items4_fx/nullifier_mute_debuff.vpcf"
end

function modifier_ability_thdots_kokoroEx:DeclareFunctions()
	return{
		-- MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PURE,
		-- MODIFIER_PROPERTY_AVOID_DAMAGE,
		-- MODIFIER_EVENT_ON_ATTACKED
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end
-- function modifier_ability_thdots_kokoroEx:GetModifierAvoidDamage()
-- 	return 1
-- end

-- function modifier_ability_thdots_kokoroEx:GetModifierProcAttack_BonusDamage_Pure()
-- 	return 0
-- end

function modifier_ability_thdots_kokoroEx:OnTakeDamage(keys)
	if not IsServer() then return end
	if keys.inflictor ~= nil then return end
	if keys.unit == self:GetParent() and keys.attacker == self:GetCaster() and self:GetStackCount() == 0 then
		self:SetStackCount(1)
		if self:GetStackCount() == 1 then
			local pure_damage = keys.original_damage - keys.damage
			local damage_tabel = {
					victim 			= keys.unit,
					-- Damage starts ramping from when cast time starts, so just gonna simiulate the effects by adding the cast point
					damage 			= pure_damage,
					damage_type		= DAMAGE_TYPE_PURE,
					damage_flags 	= DOTA_DAMAGE_FLAG_NONE,
					attacker 		= keys.attacker,
					ability 		= self:GetAbility()
				}
			--判断是否有妖梦万宝槌效果
			if not keys.attacker:HasModifier("modifier_ability_thdots_youmu2_05_passive") then 
				UnitDamageTarget(damage_tabel)
			end
			-- SendOverheadEventMessage(nil,OVERHEAD_ALERT_BONUS_SPELL_DAMAGE,keys.unit,pure_damage,nil)
			self:SetStackCount(0)
		end
	end
end



--------------------------------------------------------
--表情丰富的扑克脸
--------------------------------------------------------
ability_thdots_kokoroEx_2 = {}

function ability_thdots_kokoroEx_2:GetIntrinsicModifierName() --面具切换modifier
	return "modifier_ability_thdots_kokoroEx_2"
end

function ability_thdots_kokoroEx_2:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	self.Strength = caster:GetStrength() + caster:GetStrengthGain()
	self.Agility = caster:GetAgility() + caster:GetAgilityGain()
	self.Intellect = caster:GetIntellect(false) + caster:GetIntellectGain()
	local duration = self:GetSpecialValueFor("duration")
	if self:GetCaster():GetName() == "npc_dota_hero_legion_commander" then
		self:GetCaster():EmitSound("Voice_Thdots_Kokoro.AbilityKokoroEx_2")
	end
	local num = 0
	local PrimaryAttribute = math.max(self.Strength,self.Agility,self.Intellect)
	-- print("S is :" .. self.Strength .. " .A is :" .. self.Agility .. " .I is :" .. self.Intellect)
	-- print("PrimaryAttribute is:" .. PrimaryAttribute)
	if PrimaryAttribute == self.Strength then
		num = 0
	elseif PrimaryAttribute == self.Agility then
		num = 1
	elseif PrimaryAttribute == self.Intellect then
		num = 2
	end
	caster:AddNewModifier(caster,self,"modifier_ability_thdots_kokoroEx_2_active",{duration = duration})
end

modifier_ability_thdots_kokoroEx_2_active = {}
LinkLuaModifier("modifier_ability_thdots_kokoroEx_2_active","scripts/vscripts/abilities/abilitykokoro.lua",LUA_MODIFIER_MOTION_NONE)

function modifier_ability_thdots_kokoroEx_2_active:GetAttributes()	return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_ability_thdots_kokoroEx_2_active:OnCreated()
	if not IsServer() then return end

	-- self.parent = self:GetParent()
	-- local particle	=	"particles/econ/events/diretide_2020/emblem/fall20_emblem_v1_effect.vpcf"
	-- self.particle_fx = ParticleManager:CreateParticle(particle, PATTACH_OVERHEAD_FOLLOW, self.parent)

	self.Strength = self:GetAbility().Strength
	self.Agility = self:GetAbility().Agility
	self.Intellect = self:GetAbility().Intellect
	local PrimaryAttribute = math.max(self.Strength,self.Agility,self.Intellect)
	if PrimaryAttribute == self.Strength then
		self:SetStackCount(0)
	elseif PrimaryAttribute == self.Agility then
		self:SetStackCount(1)
	elseif PrimaryAttribute == self.Intellect then
		self:SetStackCount(2)
	end
end

function modifier_ability_thdots_kokoroEx_2_active:GetEffectName()
	return "particles/heroes/kokoro/kokoro_buff_mask_effect.vpcf"
end
function modifier_ability_thdots_kokoroEx_2_active:GetEffectAttachType()
	return "follow_origin"
end

function modifier_ability_thdots_kokoroEx_2_active:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}
end

function modifier_ability_thdots_kokoroEx_2_active:GetModifierBonusStats_Strength()
	if not IsServer() then return end
	if self:GetStackCount() == 0 then
		return self:GetAbility().Strength * 0.5
	else
		return 0
	end
end
function modifier_ability_thdots_kokoroEx_2_active:GetModifierBonusStats_Agility()
	if not IsServer() then return end
	if self:GetStackCount() == 1 then
		return self:GetAbility().Agility * 0.5
	else
		return 0
	end
end
function modifier_ability_thdots_kokoroEx_2_active:GetModifierBonusStats_Intellect()
	if not IsServer() then return end
	if self:GetStackCount() == 2 then
		return self:GetAbility().Intellect * 0.5
	else
		return 0
	end
end

modifier_ability_thdots_kokoroEx_2 = {}  --被动modifier，处理各种天赋机制
LinkLuaModifier("modifier_ability_thdots_kokoroEx_2","scripts/vscripts/abilities/abilitykokoro.lua",LUA_MODIFIER_MOTION_NONE)

function modifier_ability_thdots_kokoroEx_2:IsHidden() 		return false end
function modifier_ability_thdots_kokoroEx_2:IsPurgable()		return false end
function modifier_ability_thdots_kokoroEx_2:RemoveOnDeath() 	return false end
function modifier_ability_thdots_kokoroEx_2:IsDebuff()		return false end


function modifier_ability_thdots_kokoroEx_2:OnCreated() --设置层数，1层怒，2层喜，3层忧
	-- self.resistance = 0
	-- self.movespeed = 0
	-- self.spell_amplify = 0
	-- self.num = 4
	if not IsServer() then return end
	self:SetStackCount(0)
	self:StartIntervalThink(0.5)
	self:GetCaster():AddNewModifier(self:GetCaster(),self:GetAbility(),"modifier_ability_thdots_kokoroEx_2_Strength",{})
	self:GetCaster():AddNewModifier(self:GetCaster(),self:GetAbility(),"modifier_ability_thdots_kokoroEx_2_Agility",{})
	self:GetCaster():AddNewModifier(self:GetCaster(),self:GetAbility(),"modifier_ability_thdots_kokoroEx_2_Intellect",{})
end


function modifier_ability_thdots_kokoroEx_2:OnIntervalThink()
	self.num = 0
	self.Strength = self:GetCaster():GetStrength()
	self.Agility = self:GetCaster():GetAgility()
	self.Intellect = self:GetCaster():GetIntellect(false)
	local PrimaryAttribute = math.max(self.Strength,self.Agility,self.Intellect)
	local Strength = self:GetCaster():FindModifierByName("modifier_ability_thdots_kokoroEx_2_Strength")
	local Agility = self:GetCaster():FindModifierByName("modifier_ability_thdots_kokoroEx_2_Agility")
	local Intellect = self:GetCaster():FindModifierByName("modifier_ability_thdots_kokoroEx_2_Intellect")
	if PrimaryAttribute == self.Strength then
		self.num = 0
		self.resistance = self.Strength --* 0.3
		self:GetCaster():SetModifierStackCount("modifier_ability_thdots_kokoroEx_2_Strength",self:GetCaster(),self.resistance)
		self:GetCaster():SetModifierStackCount("modifier_ability_thdots_kokoroEx_2_Agility",self:GetCaster(),0)
		self:GetCaster():SetModifierStackCount("modifier_ability_thdots_kokoroEx_2_Intellect",self:GetCaster(),0)
	elseif PrimaryAttribute == self.Agility then
		self.num = 1
		self.movespeed = self.Agility --* 0.5
		self:GetCaster():SetModifierStackCount("modifier_ability_thdots_kokoroEx_2_Strength",self:GetCaster(),0)
		self:GetCaster():SetModifierStackCount("modifier_ability_thdots_kokoroEx_2_Agility",self:GetCaster(),self.movespeed)
		self:GetCaster():SetModifierStackCount("modifier_ability_thdots_kokoroEx_2_Intellect",self:GetCaster(),0)
	elseif PrimaryAttribute == self.Intellect then
		self.num = 2
		self.spell_amplify = self.Intellect -- * 0.1
		self:GetCaster():SetModifierStackCount("modifier_ability_thdots_kokoroEx_2_Strength",self:GetCaster(),0)
		self:GetCaster():SetModifierStackCount("modifier_ability_thdots_kokoroEx_2_Agility",self:GetCaster(),0)
		self:GetCaster():SetModifierStackCount("modifier_ability_thdots_kokoroEx_2_Intellect",self:GetCaster(),self.spell_amplify)
	end
	if not IsServer() then return end
	self:GetCaster():SetPrimaryAttribute(self.num) --设置主属性，0是力量，1是敏捷，2是智力
	if FindTelentValue(self:GetCaster(),"special_bonus_unique_kokoro_1") ~= 0 and not self:GetCaster():HasModifier("modifier_ability_thdots_kokoroEx_2_talent1") then
		self:GetCaster():AddNewModifier(self:GetCaster(),self:GetAbility(),"modifier_ability_thdots_kokoroEx_2_talent1",{})
	end
	if FindTelentValue(self:GetCaster(),"special_bonus_unique_kokoro_2") ~= 0 and not self:GetCaster():HasModifier("modifier_ability_thdots_kokoroEx_2_talent2") then
		self:GetCaster():AddNewModifier(self:GetCaster(),self:GetAbility(),"modifier_ability_thdots_kokoroEx_2_talent2",{})
	end
	if FindTelentValue(self:GetCaster(),"special_bonus_unique_kokoro_3") ~= 0 and not self:GetCaster():HasModifier("modifier_ability_thdots_kokoroEx_2_talent3") then
		self:GetCaster():AddNewModifier(self:GetCaster(),self:GetAbility(),"modifier_ability_thdots_kokoroEx_2_talent3",{})
	end
	if FindTelentValue(self:GetCaster(),"special_bonus_unique_kokoro_4") ~= 0 and not self:GetCaster():HasModifier("modifier_ability_thdots_kokoroEx_2_talent4") then
		self:GetCaster():AddNewModifier(self:GetCaster(),self:GetAbility(),"modifier_ability_thdots_kokoroEx_2_talent4",{})
	end
end
-- function modifier_ability_thdots_kokoroEx_2:DeclareFunctions()
-- 	return {
-- 		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
-- 		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
-- 		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
-- 	}
-- end

-- function modifier_ability_thdots_kokoroEx_2:GetModifierMagicalResistanceBonus()
-- 	if self.num == 1 then
-- 		return self.resistance
-- 	else
-- 		return 0
-- 	end
-- end
-- function modifier_ability_thdots_kokoroEx_2:GetModifierMoveSpeedBonus_Constant()
-- 	if self.num == 2 then
-- 		return self.movespeed
-- 	else
-- 		return 0
-- 	end
-- end
-- function modifier_ability_thdots_kokoroEx_2:GetModifierSpellAmplify_Percentage()
-- 	if self.num == 3 then
-- 		return self.spell_amplify
-- 	else
-- 		return 0
-- 	end
-- end


modifier_ability_thdots_kokoroEx_2_Strength = {}
LinkLuaModifier("modifier_ability_thdots_kokoroEx_2_Strength","scripts/vscripts/abilities/abilitykokoro.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_kokoroEx_2_Strength:IsHidden() 		return true end
function modifier_ability_thdots_kokoroEx_2_Strength:IsPurgable()		return false end
function modifier_ability_thdots_kokoroEx_2_Strength:RemoveOnDeath() 	return false end
function modifier_ability_thdots_kokoroEx_2_Strength:IsDebuff()		return false end
modifier_ability_thdots_kokoroEx_2_Agility = {}
LinkLuaModifier("modifier_ability_thdots_kokoroEx_2_Agility","scripts/vscripts/abilities/abilitykokoro.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_kokoroEx_2_Agility:IsHidden() 		return true end
function modifier_ability_thdots_kokoroEx_2_Agility:IsPurgable()		return false end
function modifier_ability_thdots_kokoroEx_2_Agility:RemoveOnDeath() 	return false end
function modifier_ability_thdots_kokoroEx_2_Agility:IsDebuff()		return false end
modifier_ability_thdots_kokoroEx_2_Intellect = {}
LinkLuaModifier("modifier_ability_thdots_kokoroEx_2_Intellect","scripts/vscripts/abilities/abilitykokoro.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_kokoroEx_2_Intellect:IsHidden() 		return true end
function modifier_ability_thdots_kokoroEx_2_Intellect:IsPurgable()		return false end
function modifier_ability_thdots_kokoroEx_2_Intellect:RemoveOnDeath() 	return false end
function modifier_ability_thdots_kokoroEx_2_Intellect:IsDebuff()		return false end

function modifier_ability_thdots_kokoroEx_2_Strength:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
	}
end
function modifier_ability_thdots_kokoroEx_2_Strength:GetModifierMagicalResistanceBonus()
	return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("strength_bonus")
end
function modifier_ability_thdots_kokoroEx_2_Agility:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT
	}
end
function modifier_ability_thdots_kokoroEx_2_Agility:GetModifierMoveSpeedBonus_Constant()
	return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("agility_bonus")
end
function modifier_ability_thdots_kokoroEx_2_Intellect:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE
	}
end
function modifier_ability_thdots_kokoroEx_2_Intellect:GetModifierSpellAmplify_Percentage()
	return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("intellect_bonus")
end

modifier_ability_thdots_kokoroEx_2_talent1 = modifier_ability_thdots_kokoroEx_2_talent1 or {}  --天赋监听
LinkLuaModifier("modifier_ability_thdots_kokoroEx_2_talent1","scripts/vscripts/abilities/abilitykokoro.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_kokoroEx_2_talent1:IsHidden() 		return true end
function modifier_ability_thdots_kokoroEx_2_talent1:IsPurgable()		return false end
function modifier_ability_thdots_kokoroEx_2_talent1:RemoveOnDeath() 	return false end
function modifier_ability_thdots_kokoroEx_2_talent1:IsDebuff()		return false end

modifier_ability_thdots_kokoroEx_2_talent2 = modifier_ability_thdots_kokoroEx_2_talent2 or {}  --天赋监听
LinkLuaModifier("modifier_ability_thdots_kokoroEx_2_talent2","scripts/vscripts/abilities/abilitykokoro.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_kokoroEx_2_talent2:IsHidden() 		return true end
function modifier_ability_thdots_kokoroEx_2_talent2:IsPurgable()		return false end
function modifier_ability_thdots_kokoroEx_2_talent2:RemoveOnDeath() 	return false end
function modifier_ability_thdots_kokoroEx_2_talent2:IsDebuff()		return false end

modifier_ability_thdots_kokoroEx_2_talent3 = modifier_ability_thdots_kokoroEx_2_talent3 or {}  --天赋监听
LinkLuaModifier("modifier_ability_thdots_kokoroEx_2_talent3","scripts/vscripts/abilities/abilitykokoro.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_kokoroEx_2_talent3:IsHidden() 		return true end
function modifier_ability_thdots_kokoroEx_2_talent3:IsPurgable()		return false end
function modifier_ability_thdots_kokoroEx_2_talent3:RemoveOnDeath() 	return false end
function modifier_ability_thdots_kokoroEx_2_talent3:IsDebuff()		return false end

modifier_ability_thdots_kokoroEx_2_talent4 = modifier_ability_thdots_kokoroEx_2_talent4 or {}  --天赋监听
LinkLuaModifier("modifier_ability_thdots_kokoroEx_2_talent4","scripts/vscripts/abilities/abilitykokoro.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_kokoroEx_2_talent4:IsHidden() 		return true end
function modifier_ability_thdots_kokoroEx_2_talent4:IsPurgable()		return false end
function modifier_ability_thdots_kokoroEx_2_talent4:RemoveOnDeath() 	return false end
function modifier_ability_thdots_kokoroEx_2_talent4:IsDebuff()		return false end