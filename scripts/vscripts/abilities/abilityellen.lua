

ability_thdots_ellen01	= {}

LinkLuaModifier("ability_thdots_ellen01_thinker", "scripts/vscripts/abilities/abilityellen.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ability_thdots_ellen01_purge", "scripts/vscripts/abilities/abilityellen.lua", LUA_MODIFIER_MOTION_NONE)
modifier_ability_thdots_ellen01_purge	=  class({})
ability_thdots_ellen01_thinker	= ability_thdots_ellen01_thinker or class({})

function ability_thdots_ellen01:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
	-- return 99999
end

function ability_thdots_ellen01:OnSpellStart()
        if not IsServer() then return end
				-- print(self:GetCursorPosition())
	    self:GetCaster():EmitSound("Hero_ArcWarden.SparkWraith.Cast")
    	EmitSoundOnLocationWithCaster(self:GetCursorPosition(), "Hero_ArcWarden.SparkWraith.Appear", self:GetCaster())
        AddFOWViewer(self:GetCaster():GetTeamNumber(), self:GetCursorPosition(), 275, 5, true)
        -- special_bonus_unique_ellen_2 的天赋加成必须在这里手动叠加：
-- KV 的 LinkedSpecialBonus 只负责让技能详情面板显示加成后的数值，并不会改变 GetSpecialValueFor 的返回值（参照 reisen max_illusions 处的注释）。
CreateModifierThinker(self:GetCaster(), self, "ability_thdots_ellen01_thinker", {duration =  self:GetSpecialValueFor("duration")+FindTelentValue(self:GetCaster(),"special_bonus_unique_ellen_2") },  self:GetCursorPosition(), self:GetCaster():GetTeamNumber(), false)

    		ProjectileManager:CreateLinearProjectile({
    			Ability		= self,
    			Source		= self:GetCaster(),
    			vSpawnOrigin	= self:GetCaster():GetAbsOrigin(),
    			vVelocity	= ((self:GetCursorPosition() - self:GetCaster():GetAbsOrigin()) * Vector(1, 1, 0)):Normalized() * self:GetSpecialValueFor("wraith_speed"),
    			vAcceleration	= nil, --hmm...
    			fMaxSpeed	= nil, -- What's the default on this thing?
    			fDistance	= self.BaseClass.GetCastRange(self, self:GetCursorPosition(), self:GetCaster()) + self:GetCaster():GetCastRangeBonus(),
    			fStartRadius	= 100,
    			fEndRadius		= 100,
    			fExpireTime		= nil,
    			iUnitTargetTeam	= DOTA_UNIT_TARGET_TEAM_ENEMY,
    			iUnitTargetFlags	= DOTA_UNIT_TARGET_FLAG_NONE,
    			iUnitTargetType		= DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
    			bIgnoreSource		= true,
    			bHasFrontalCone		= false,
    			bDrawsOnMinimap		= false,
    			bVisibleToEnemies	= true,
    			bProvidesVision		= true,
    			iVisionRadius		= 300,
    			iVisionTeamNumber	= self:GetCaster():GetTeamNumber(),
    			ExtraData			= {
    				spark_damage		= self:GetSpecialValueFor("spark_damage"),
    				auto_cast			= 1
    			}
    		})

    end

function ability_thdots_ellen01:OnProjectileHit_ExtraData(target, location, ExtraData)
       if not IsServer() then return end
	if target then
		AddFOWViewer(self:GetCaster():GetTeamNumber(), location, self:GetSpecialValueFor("wraith_vision_radius"), self:GetSpecialValueFor("wraith_vision_duration"), true)

		if not target:IsMagicImmune() then
			target:EmitSound("Hero_ArcWarden.SparkWraith.Damage")

			if ExtraData.auto_cast == 1 then
				local burst_particle = ParticleManager:CreateParticle("particles/econ/items/shadow_demon/sd_ti7_shadow_poison/sd_ti7_golden_immortal_ambient_head_fire_trail.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
				ParticleManager:ReleaseParticleIndex(burst_particle)
			end

			UnitDamageTarget({
				victim 			= target,
				damage 			= ExtraData.spark_damage,
				damage_type		= self:GetAbilityDamageType(),
				damage_flags 	= DOTA_DAMAGE_FLAG_NONE,
				attacker 		= self:GetCaster(),
				ability 		= self
			})

			if target and not target:IsNull() then
				if(target:HasModifier("modifier_ability_thdots_ellen01_purge")) then
					local s = target:GetModifierStackCount("modifier_ability_thdots_ellen01_purge",self:GetCaster())
					local mod = target:AddNewModifier(self:GetCaster(), self, "modifier_ability_thdots_ellen01_purge", {duration = self:GetSpecialValueFor("miss_duration") * (1 - target:GetStatusResistance())})
					target:SetModifierStackCount("modifier_ability_thdots_ellen01_purge",self:GetCaster(),s+1)
				else
					target:AddNewModifier(self:GetCaster(), self, "modifier_ability_thdots_ellen01_purge", {duration = self:GetSpecialValueFor("miss_duration") * (1 - target:GetStatusResistance())})
					target:SetModifierStackCount("modifier_ability_thdots_ellen01_purge",self:GetCaster(),1)
				end
			end
		end

		return true
	end
end

function ability_thdots_ellen01_thinker:OnCreated()

	if not self:GetAbility() then self:Destroy() return end

	self.radius				= self:GetAbility():GetSpecialValueFor("radius")
	self.activation_delay	= self:GetAbility():GetSpecialValueFor("activation_delay")
	self.wraith_speed		= self:GetAbility():GetSpecialValueFor("wraith_speed")
	self.spark_damage		= self:GetAbility():GetSpecialValueFor("spark_damage")
	self.think_interval			= self:GetAbility():GetSpecialValueFor("think_interval")
	self.wraith_vision_radius	= self:GetAbility():GetSpecialValueFor("wraith_vision_radius")

	if not IsServer() then return end
	self:GetParent():EmitSound("Hero_ArcWarden.SparkWraith.Loop")

	self.wraith_particle = ParticleManager:CreateParticle("particles/world_environmental_fx/artifact_table_underlight.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControl(self.wraith_particle, 1, Vector(self.radius, 1, 1))
	self:AddParticle(self.wraith_particle, false, false, -1, false, false)

	self:GetCaster():SetContextThink(DoUniqueString(self:GetName()), function()
		self:StartIntervalThink(self.think_interval)
		return nil
	end, self.activation_delay - self.think_interval)
end

function ability_thdots_ellen01_thinker:OnIntervalThink()
    if not IsServer() then return end
    AddFOWViewer(self:GetCaster():GetTeamNumber(), self:GetParent():GetAbsOrigin(), 275, 2, true)
	for _, enemy in pairs(FindUnitsInRadius(self:GetCaster():GetTeamNumber(), self:GetParent():GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)) do
		self:GetParent():EmitSound("Hero_ArcWarden.SparkWraith.Activate")

		ProjectileManager:CreateTrackingProjectile({
			EffectName			= "particles/units/heroes/hero_arc_warden/arc_warden_wraith_prj.vpcf",
			Ability				= self:GetAbility(),
			Source				= self:GetParent(),
			vSourceLoc			= self:GetParent():GetAbsOrigin(),
			Target				= enemy,
			iMoveSpeed			= self.wraith_speed,
			flExpireTime		= nil,
			bDodgeable			= false,
			bIsAttack			= false,
			bReplaceExisting	= false,
			iSourceAttachment	= nil,
			bDrawsOnMinimap		= nil,
			bVisibleToEnemies	= true,
			bProvidesVision		= true,
			iVisionRadius		= 300,
			iVisionTeamNumber	= self:GetCaster():GetTeamNumber(),
			ExtraData			= {
				spark_damage		= self.spark_damage,
				thinker_time		= self:GetElapsedTime(),
				thinker_duration	= self:GetDuration()
			}
		})

		self:Destroy()
		break
	end
end

function ability_thdots_ellen01_thinker:OnDestroy()
	if not IsServer() then return end

	self:GetParent():StopSound("Hero_ArcWarden.SparkWraith.Loop")
end

function ability_thdots_ellen01_thinker:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_FIXED_DAY_VISION,
		MODIFIER_PROPERTY_FIXED_NIGHT_VISION
	}
end

function ability_thdots_ellen01_thinker:GetFixedDayVision()
	return self.wraith_vision_radius
end

function ability_thdots_ellen01_thinker:GetFixedNightVision()
	return self.wraith_vision_radius
end

-------------------------------------------------
-------------------------------------------------

function modifier_ability_thdots_ellen01_purge:GetEffectName()
	return "particles/units/heroes/hero_keeper_of_the_light/keeper_of_the_light_blinding_light_debuff.vpcf"
end

function modifier_ability_thdots_ellen01_purge:OnCreated()
     if not IsServer() then return end
	 if not self:GetAbility() then self:Destroy() return end
	self.miss	= self:GetAbility():GetSpecialValueFor("miss")
end

function modifier_ability_thdots_ellen01_purge:DeclareFunctions()
	local decFuncs = {
		MODIFIER_PROPERTY_MISS_PERCENTAGE
    }

    return decFuncs
end

function modifier_ability_thdots_ellen01_purge:GetModifierMiss_Percentage()
    return self.miss * self:GetStackCount()
end

------------------------------
------------------------------

LinkLuaModifier("modifier_ability_thdots_ellen02", "scripts/vscripts/abilities/abilityellen.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_thdots_ellen02_push", "scripts/vscripts/abilities/abilityellen.lua", LUA_MODIFIER_MOTION_HORIZONTAL)

ability_thdots_ellen02	= {}
modifier_ability_thdots_ellen02								= class({})
modifier_thdots_ellen02_push								= class({})
modifier_thdots_ellen02_pushing								= class({})
LinkLuaModifier("modifier_thdots_ellen02_pushing", "scripts/vscripts/abilities/abilityellen.lua", LUA_MODIFIER_MOTION_HORIZONTAL)

function ability_thdots_ellen02:GetBehavior()
	return DOTA_ABILITY_BEHAVIOR_NO_TARGET 
end

function ability_thdots_ellen02:OnSpellStart()
	if not IsServer() then return end

	local caster_pos		= self:GetCaster():GetAbsOrigin()

	local num_of_cogs		= self:GetSpecialValueFor("cogs_num")+FindTelentValue(self:GetCaster(),"special_bonus_unique_ellen_1")

	local cogs_radius		= self:GetSpecialValueFor("cogs_radius")

	local duration			= self:GetSpecialValueFor("duration")

	-- Static value cause this is kinda hot-fixing for now
	local square_dist		= 30

	local cog_vector 		= GetGroundPosition(caster_pos + Vector(0, cogs_radius, 0), nil)
	local second_cog_vector	= GetGroundPosition(caster_pos + Vector(0, cogs_radius * 2, 0), nil)

	self:GetCaster():StartGesture(ACT_DOTA_RATTLETRAP_POWERCOGS)
		for cog = 1, num_of_cogs do

			local cog = CreateUnitByName("npc_dota_rattletrap_cog", cog_vector, false, self:GetCaster(), self:GetCaster(), self:GetCaster():GetTeamNumber())
			SetTHD2BlockingNeutrals(cog, false)
			ResolveNPCPositions(cog:GetAbsOrigin(), 128)
         	cog:EmitSound("Hero_KeeperOfTheLight.Wisp.Active")

			cog:AddNewModifier(self:GetCaster(), self, "modifier_ability_thdots_ellen02",
			{
				duration 	= duration,
				x 			= (cog_vector - caster_pos).x,
				y 			= (cog_vector - caster_pos).y,

				center_x	= caster_pos.x,
				center_y	= caster_pos.y,
				center_z	= caster_pos.z
			})
			cog:AddNewModifier(self:GetCaster(), self, "modifier_kill", {duration = duration})
			cog_vector		= RotatePosition(caster_pos, QAngle(0, 360/num_of_cogs, 0), cog_vector)
		end

	local units = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), self:GetCaster():GetAbsOrigin(), nil, self:GetSpecialValueFor("cogs_radius") + 80, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)

end

-------------------------
-------------------------

function modifier_ability_thdots_ellen02:IsHidden()		return true end
function modifier_ability_thdots_ellen02:IsPurgable()	return false end

function modifier_ability_thdots_ellen02:OnCreated(params)
	if self:GetAbility() then
		self.damage					= self:GetAbility():GetSpecialValueFor("damage")
		self.mana_burn				= self:GetAbility():GetSpecialValueFor("mana_burn")
		self.attacks_to_destroy		= self:GetAbility():GetSpecialValueFor("attacks_to_destroy")
		self.push_length			= 200
		self.push_duration			= self:GetAbility():GetSpecialValueFor("push_duration")
		self.trigger_distance		= self:GetAbility():GetSpecialValueFor("trigger_distance")
		self.rotational_speed		= self:GetAbility():GetSpecialValueFor("rotational_speed")
		self.powered			= true
		self.health				= self:GetAbility():GetSpecialValueFor("attacks_to_destroy")
	else
		self:Destroy()
		return
	end

	if not IsServer() then return end
	self:GetParent():SetForwardVector(Vector(params.x, params.y, 0))
	self.center_loc		= Vector(params.center_x, params.center_y, params.center_z)
	self.second_gear	= params.second_gear

    self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_keeper_of_the_light/keeper_dazzling.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControl(self.particle, 1, Vector(self.radius, 1, 1))
    ParticleManager:SetParticleControl(self.particle, 2, Vector(0, 0, 0))
    self:AddParticle(self.particle, false, false, -1, false, false)

    self.particle2 = ParticleManager:CreateParticle("particles/units/heroes/hero_keeper_of_the_light/keeper_dazzling_on.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControl(self.particle2, 2, Vector(0, 0, 0))
    self:AddParticle(self.particle2, false, false, -1, false, false)

	self:OnIntervalThink()
	self:StartIntervalThink(FrameTime())
end

function modifier_ability_thdots_ellen02:OnIntervalThink()
	if not IsServer() then return end

	local enemies = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), self:GetParent():GetAbsOrigin(), nil, self.trigger_distance, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,0,0, false)

	for _, enemy in pairs(enemies) do
		if self.powered and not enemy:HasModifier("modifier_thdots_ellen02_pushing") and not enemy:HasModifier("modifier_thdots_ellen02_push") and math.abs(AngleDiff(VectorToAngles(self:GetParent():GetForwardVector()).y, VectorToAngles(enemy:GetAbsOrigin() - self:GetParent():GetAbsOrigin()).y)) <= 180 then
			if enemy:GetUnitName() == "npc_coin_up_unit" 
				or enemy:GetUnitName() == "npc_power_up_unit"
				or enemy:GetUnitName() == "npc_dota_roshan"
				or enemy:HasModifier("dummy_unit")
				or IsTHDImmune(enemy) then
				break
			else
				self.health = self.health - 1
				local max_count = self:GetAbility():GetSpecialValueFor("attacks_to_destroy")
				local set_healt = self:GetParent():GetBaseMaxHealth() * self.health / max_count
				self:GetParent():SetHealth(set_healt)
				if self.health <= 0 then
					self:StartIntervalThink(-1)
				end
				--防秒杀飞行
				enemy:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_thdots_ellen02_pushing",{duration	= self.push_duration * (1 - enemy:GetStatusResistance())})
				enemy:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_thdots_ellen02_push",
				{
					duration	= self.push_duration * (1 - enemy:GetStatusResistance()),
					damage		= self.damage,
					mana_burn	= self.mana_burn,
					push_length	= self.push_length
				})
				break
			end
		end
	end
end

function modifier_ability_thdots_ellen02:OnDestroy()
	if not IsServer() then return end
	self:GetParent():StopSound("Hero_KeeperOfTheLight.Mana_Leak_Target_Fp")

	self:GetParent():EmitSound("Hero_KeeperOfTheLight.Mana_Leak_Target")

	if self:GetRemainingTime() <= 0 then
		self:GetParent():RemoveSelf()
	end
end

function modifier_ability_thdots_ellen02:CheckState()
	return  {
		[MODIFIER_STATE_SPECIALLY_DENIABLE]					= true,
		[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY]	= true
	}
end

function modifier_ability_thdots_ellen02:DeclareFunctions()
	local decFuncs = {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
		MODIFIER_EVENT_ON_ATTACK_LANDED
    }

    return decFuncs
end

function modifier_ability_thdots_ellen02:GetAbsoluteNoDamageMagical()
    return 1
end

function modifier_ability_thdots_ellen02:GetAbsoluteNoDamagePhysical()
    return 1
end

function modifier_ability_thdots_ellen02:GetAbsoluteNoDamagePure()
    return 1
end

function modifier_ability_thdots_ellen02:OnAttackLanded(keys)
    if not IsServer() then return end

	if keys.target == self:GetParent() then
		if keys.attacker == self:GetCaster() then
			self:GetParent():RemoveSelf()
		else
			self.health = self.health - 1
			local max_count = self:GetAbility():GetSpecialValueFor("attacks_to_destroy")
			local set_healt = self:GetParent():GetBaseMaxHealth() * self.health / max_count
			self:GetParent():SetHealth(set_healt)
			if self.health <= 1 then
				self:GetParent():RemoveSelf()
			end
		end
	end
end

------------------------------
------------------------------

function modifier_thdots_ellen02_push:OnCreated(params)
	if not IsServer() then return end

	self.duration			= params.duration
	self.damage				= params.damage
	self.mana_burn			= params.mana_burn
	self.push_length		= params.push_length
	self.owner				= self:GetCaster():GetOwner() or self:GetCaster()

    self:GetCaster():EmitSound("Hero_KeeperOfTheLight.BlindingLight")
	local attack_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_puck/puck_phase_shift_c.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
    ParticleManager:SetParticleControlEnt(attack_particle, 1, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_attack1", self:GetParent():GetAbsOrigin(), true)

	self.knockback_speed		= self.push_length / self.duration
	self.position	= self:GetCaster():GetAbsOrigin()

	if self:ApplyHorizontalMotionController() == false then
		self:Destroy()
		return
	end
end

function modifier_thdots_ellen02_push:UpdateHorizontalMotion( me, dt )
	if not IsServer() then return end

	local distance = (me:GetOrigin() - self.position):Normalized()
    -- 三步必杀
	me:SetOrigin( me:GetOrigin() + distance * self.knockback_speed * dt )
end

function modifier_thdots_ellen02_push:OnHorizontalMotionInterrupted()
	self:Destroy()
end

function modifier_thdots_ellen02_push:OnDestroy()
	if not IsServer() then return end
	self:GetParent():RemoveHorizontalMotionController( self )
	self:GetParent():Script_ReduceMana(self.mana_burn, self:GetAbility())
	GridNav:DestroyTreesAroundPoint(self:GetParent():GetAbsOrigin(), 100, true )
	local damageTable = {
		victim 			= self:GetParent(),
		damage 			= self.damage,
		damage_type		= DAMAGE_TYPE_MAGICAL,
		damage_flags 	= DOTA_DAMAGE_FLAG_NONE,
		attacker 		= self:GetCaster(),
		ability 		= self:GetAbility()
	}

	if not damageTable.attacker then
		damageTable.attacker = self.owner
	end

	UnitDamageTarget(damageTable)
end

function modifier_thdots_ellen02_push:CheckState()
	local state = {[MODIFIER_STATE_STUNNED] = true}
	return state
end

function modifier_thdots_ellen02_push:DeclareFunctions()
	local decFuncs = {MODIFIER_PROPERTY_OVERRIDE_ANIMATION }
    return decFuncs
end

function modifier_thdots_ellen02_push:GetOverrideAnimation()
	 return ACT_DOTA_FLAIL
end

------------------------------
------------------------------
ability_thdots_ellen03 = class({})
function ability_thdots_ellen03:IsHiddenWhenStolen() 	return false end
function ability_thdots_ellen03:IsRefreshable() 		return true end
function ability_thdots_ellen03:IsStealable() 			return true end
function ability_thdots_ellen03:IsNetherWardStealable()	return true end

LinkLuaModifier("modifier_ability_thdots_ellen03_orb_thinker", "scripts/vscripts/abilities/abilityellen.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ability_thdots_ellen03_orb_silenced", "scripts/vscripts/abilities/abilityellen.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ability_thdots_ellen03_orb_controller", "scripts/vscripts/abilities/abilityellen.lua", LUA_MODIFIER_MOTION_NONE)

function ability_thdots_ellen03:GetAssociatedSecondaryAbilities()
	return "ability_thdots_ellen03_end"
end

function ability_thdots_ellen03:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("max_distance")
end

function ability_thdots_ellen03:OnUpgrade()
	if not IsServer() then return end

	local illuminate_end = self:GetCaster():FindAbilityByName("ability_thdots_ellen03_end")

	if illuminate_end then
		illuminate_end:SetLevel(self:GetLevel())
	end
end

function ability_thdots_ellen03:OnSpellStart()
	    local caster = self:GetCaster()
    	local pos = self:GetCursorPosition()
    	local direction = (pos - caster:GetAbsOrigin()):Normalized()
    	direction.z = 0
    	local sound = CreateModifierThinker(caster, self, "modifier_ability_thdots_ellen03_orb_thinker", {duration = 30.0}, caster:GetAbsOrigin(), caster:GetTeamNumber(), false)
    	sound:EmitSound("Hero_Puck.Illusory_Orb")
    	local distance = self:GetSpecialValueFor("max_distance")
    	local speed = self:GetSpecialValueFor("orb_speed")
    	local pfx_name = "particles/econ/items/puck/puck_merry_wanderer/puck_illusory_orb_merry_wanderer_linear_projectile.vpcf"
    	local info =
    	{
    		Ability = self,
    		EffectName = pfx_name,
    		vSpawnOrigin = caster:GetAbsOrigin(),
    		fDistance = distance,
    		fStartRadius = self:GetSpecialValueFor("radius"),
    		fEndRadius = self:GetSpecialValueFor("radius"),
    		Source = caster,
    		bHasFrontalCone = false,
    		bReplaceExisting = false,
    		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
    		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
    		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    		fExpireTime = GameRules:GetGameTime() + 10.0,
    		bDeleteOnHit = true,
    		vVelocity = direction * speed,
    		bProvidesVision = false,
    		ExtraData = {sound = sound:entindex()},
    	}
    	self.projectile = ProjectileManager:CreateLinearProjectile(info)
    	local time = (self:GetSpecialValueFor("max_distance") / self:GetSpecialValueFor("orb_speed") - 0.2)
    	caster:AddNewModifier(caster, self, "modifier_ability_thdots_ellen03_orb_controller", {duration = time}):SetStackCount(0)

end

function ability_thdots_ellen03:OnProjectileThink_ExtraData(pos, keys)
	AddFOWViewer(self:GetCaster():GetTeamNumber(), pos, self:GetSpecialValueFor("orb_vision"), self:GetSpecialValueFor("vision_duration"), false)
	if keys.sound then
		EntIndexToHScript(keys.sound):SetOrigin(pos)
	end
end

function ability_thdots_ellen03:OnProjectileHit_ExtraData(target, pos, keys)
	if not target and keys.sound then
		EntIndexToHScript(keys.sound):StopSound("Hero_Puck.Illusory_Orb")
		EntIndexToHScript(keys.sound):ForceKill(false)
	end
	if target then
		target:EmitSound("Hero_Puck.IIllusory_Orb_Damage")
		local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_puck/puck_orb_damage.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
		ParticleManager:ReleaseParticleIndex(pfx)
		UnitDamageTarget({victim = target, attacker = self:GetCaster(), ability = self, damage = self:GetSpecialValueFor("damage"), damage_type = self:GetAbilityDamageType()})
	end
end
------------------------------
------------------------------
modifier_ability_thdots_ellen03_orb_thinker = class({})

function modifier_ability_thdots_ellen03_orb_thinker:IsAura() return true end
function modifier_ability_thdots_ellen03_orb_thinker:GetAuraDuration() return 0.1 end
function modifier_ability_thdots_ellen03_orb_thinker:GetModifierAura() return "modifier_ability_thdots_ellen03_orb_silenced" end
function modifier_ability_thdots_ellen03_orb_thinker:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("radius") end
function modifier_ability_thdots_ellen03_orb_thinker:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NONE end
function modifier_ability_thdots_ellen03_orb_thinker:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_ability_thdots_ellen03_orb_thinker:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end

modifier_ability_thdots_ellen03_orb_silenced = class({})
function modifier_ability_thdots_ellen03_orb_silenced:IsDebuff()			return true end
function modifier_ability_thdots_ellen03_orb_silenced:IsHidden() 		return false end
function modifier_ability_thdots_ellen03_orb_silenced:IsPurgable() 		return true end
function modifier_ability_thdots_ellen03_orb_silenced:IsPurgeException() return true end
function modifier_ability_thdots_ellen03_orb_silenced:GetEffectName() return "particles/generic_gameplay/generic_silenced.vpcf" end
function modifier_ability_thdots_ellen03_orb_silenced:CheckState() return {[MODIFIER_STATE_SILENCED] = true} end
function modifier_ability_thdots_ellen03_orb_silenced:GetEffectAttachType() return PATTACH_OVERHEAD_FOLLOW end
function modifier_ability_thdots_ellen03_orb_silenced:ShouldUseOverheadOffset() return true end

modifier_ability_thdots_ellen03_orb_controller = class({})

function modifier_ability_thdots_ellen03_orb_controller:IsDebuff()			return false end
function modifier_ability_thdots_ellen03_orb_controller:IsHidden() 			return false end
function modifier_ability_thdots_ellen03_orb_controller:IsPurgable() 		return false end
function modifier_ability_thdots_ellen03_orb_controller:IsPurgeException() 	return false end
function modifier_ability_thdots_ellen03_orb_controller:RemoveOnDeath() return self:GetParent():IsIllusion() end

function modifier_ability_thdots_ellen03_orb_controller:OnCreated()
	if IsServer() then
	    self:GetCaster():SwapAbilities("ability_thdots_ellen03", "ability_thdots_ellen03_end", false, true)
	end
end

function modifier_ability_thdots_ellen03_orb_controller:OnDestroy()
	if IsServer() then
		 self:GetCaster():SwapAbilities("ability_thdots_ellen03", "ability_thdots_ellen03_end", true,false)
	end
end
------------------------------
------------------------------
ability_thdots_ellen03_end = class({})
function ability_thdots_ellen03_end:IsHiddenWhenStolen() 		return false end
function ability_thdots_ellen03_end:IsRefreshable() 			return true end
function ability_thdots_ellen03_end:IsStealable() 			return false end
function ability_thdots_ellen03_end:IsNetherWardStealable()	return false end
function ability_thdots_ellen03_end:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local ability = caster:FindAbilityByName("ability_thdots_ellen03")
    caster:EmitSound("Hero_Puck.Waning_Rift")

	self.miss				    = self:GetSpecialValueFor("miss")
	self.knockback_duration		= self:GetSpecialValueFor("knockback_duration")
    self.knockback_distance		= self:GetSpecialValueFor("knockback_distance")
	self.duration				= self:GetSpecialValueFor("duration")
	self.radius					= self:GetSpecialValueFor("radius")
	self.damage				    = self:GetSpecialValueFor("damage")
	local position = GetGroundPosition(ProjectileManager:GetLinearProjectileLocation(ability.projectile), nil)

	local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_puck/puck_waning_rift.vpcf",  PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(pfx, 0, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(pfx, 1, Vector(radius,radius,radius))
    ParticleManager:ReleaseParticleIndex(pfx)
	ParticleManager:DestroyParticleSystem(pfx,false)

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_keeper_of_the_light/keeper_of_the_light_blinding_light_aoe.vpcf", PATTACH_POINT_FOLLOW, caster)
    ParticleManager:SetParticleControl(particle, 0, position)
    ParticleManager:SetParticleControl(particle, 1, position)
    ParticleManager:SetParticleControl(particle, 2, Vector(self.radius, 0, 0))
    ParticleManager:ReleaseParticleIndex(particle)
	ParticleManager:DestroyParticleSystem(particle,false)

	local enemies = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), position, nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
    for _, enemy in pairs(enemies) do
			if enemy:HasModifier("modifier_ability_thdots_ellen03_knockback") then
				enemy:FindModifierByName("modifier_ability_thdots_ellen03_knockback"):Destroy()
			end
			enemy:AddNewModifier(self.caster, self, "modifier_ability_thdots_ellen03_knockback", {x = position.x, y = position.y, z = position.z, duration = self.knockback_duration * (1 - enemy:GetStatusResistance())})
			local damageTable = {
    			victim 			= enemy,
    			damage 			= self.damage,
    			damage_type		= DAMAGE_TYPE_MAGICAL,
    			damage_flags 	= DOTA_DAMAGE_FLAG_NONE,
                attacker 		= self:GetCaster(),
                ability 		= self
    	}
			UnitDamageTarget(damageTable)
		end
end

LinkLuaModifier("modifier_ability_thdots_ellen03_knockback", "scripts/vscripts/abilities/abilityellen.lua", LUA_MODIFIER_MOTION_HORIZONTAL)
modifier_ability_thdots_ellen03_knockback					= class({})
function modifier_ability_thdots_ellen03_knockback:IsHidden() return false end
function modifier_ability_thdots_ellen03_knockback:IsPurgable() return true end
function modifier_ability_thdots_ellen03_knockback:IsDebuff() return true end
function modifier_ability_thdots_ellen03_knockback:RemoveOnDeath() return true end

function modifier_ability_thdots_ellen03_knockback:OnCreated(params)
	if not IsServer() then return end

	self.ability				= self:GetAbility()
	self.parent					= self:GetParent()
	self.knockback_duration		= self.ability:GetSpecialValueFor("knockback_duration")
	self.knockback_distance		= self.ability:GetSpecialValueFor("knockback_distance")
	self.knockback_speed		= self.ability.knockback_distance / self.knockback_duration
	self.position	= Vector(params.x, params.y, params.z)
	self.parent:StartGesture(ACT_DOTA_FLAIL)
	if self:ApplyHorizontalMotionController() == false then
		self:Destroy()
		return
	end
end

function modifier_ability_thdots_ellen03_knockback:UpdateHorizontalMotion( me, dt )
	if not IsServer() then return end

	local distance = (me:GetOrigin() - self.position):Normalized()
   -- 三步必杀
    if not me:HasModifier("modifier_thdots_yugi04_think_interval") then
		me:SetOrigin( me:GetOrigin() + distance * self.knockback_speed * dt )
	end
end

function modifier_ability_thdots_ellen03_knockback:OnDestroy()
	if not IsServer() then return end
	GridNav:DestroyTreesAroundPoint( self.parent:GetOrigin(), 150, true )
	self.parent:FadeGesture(ACT_DOTA_FLAIL)
		self.parent:RemoveHorizontalMotionController( self )
	FindClearSpaceForUnit(self:GetParent(), self:GetParent():GetAbsOrigin(), false)
end

function modifier_ability_thdots_ellen03_knockback:DeclareFunctions()
	local decFuncs = {
		MODIFIER_PROPERTY_DISABLE_TURNING
    }

    return decFuncs
end

-------------------
-------------------
--=================================================================================================================
-- 大招「Tabula Rasa」：空白领域（2026-09-20 改版）
-- 施放后持续 duration 秒：自身与全部己方英雄及其控制单位获得血条隐藏、敌方小地图隐藏，并逐渐进入隐身（渐隐 fade_time 秒）；渐隐期间被敌方英雄攻击命中会重置渐隐计时，隐身被打破（攻击/施法）后同样从头渐隐，直至领域结束。
--=================================================================================================================
ability_thdots_ellen04 = class({})

LinkLuaModifier("modifier_ability_thdots_ellen04_controller", "scripts/vscripts/abilities/abilityellen.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ability_thdots_ellen04_blank", "scripts/vscripts/abilities/abilityellen.lua", LUA_MODIFIER_MOTION_NONE)

function ability_thdots_ellen04:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	if caster == nil or caster:IsNull() then return end

	local duration = self:GetSpecialValueFor("duration")

	caster:EmitSound("DOTA_Item.SmokeOfDeceit.Activate")

	-- 施法者立即拿到状态，不再等控制器第一次扫描
	caster:AddNewModifier(caster, self, "modifier_ability_thdots_ellen04_blank", {duration = duration})

	-- 控制器挂在爱莲身上：爱莲阵亡【不】中断领域（控制器 RemoveOnDeath=false）；
	-- 控制器负责给队友与召唤物补发，领域只随 duration 到期结束
	caster:AddNewModifier(caster, self, "modifier_ability_thdots_ellen04_controller", {duration = duration})
end

--=================================================================================================================
-- 领域控制器：周期性把空白状态下发给全队英雄及其控制单位
--=================================================================================================================
modifier_ability_thdots_ellen04_controller = class({})

function modifier_ability_thdots_ellen04_controller:IsHidden() return true end
function modifier_ability_thdots_ellen04_controller:IsPurgable() return false end
-- 挂在爱莲身上，RemoveOnDeath=false：爱莲阵亡【不】中断领域；
-- 她自己的空白状态随死亡移除，复活后由控制器补发（重新渐隐）
function modifier_ability_thdots_ellen04_controller:RemoveOnDeath() return false end

function modifier_ability_thdots_ellen04_controller:OnCreated()
	if not IsServer() then return end
	local ability = self:GetAbility()
	if ability == nil then self:Destroy() return end

	self.search_interval	= ability:GetSpecialValueFor("search_interval")
	self.expire_time		= GameRules:GetGameTime() + ability:GetSpecialValueFor("duration")

	-- 施放瞬间立即下发一次，之后周期补发（覆盖中途复活的英雄与新召唤的单位）
	self:OnIntervalThink()
	self:StartIntervalThink(self.search_interval)
end

-- 连续施法时引擎对已存在的 controller 触发 OnRefresh（不是 OnCreated），必须在这里重置领域结束时间，否则 expire_time 停留在首次施法时刻，友方状态的持续时间不会被重置。
function modifier_ability_thdots_ellen04_controller:OnRefresh()
	if not IsServer() then return end
	local ability = self:GetAbility()
	if ability == nil then return end
	self.expire_time = GameRules:GetGameTime() + ability:GetSpecialValueFor("duration")
end

function modifier_ability_thdots_ellen04_controller:OnIntervalThink()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local ability = self:GetAbility()
	if caster == nil or caster:IsNull() or ability == nil then return end

	-- 领域剩余时间：中途加入的单位按剩余时间获得状态，保证全队同时结束
	local remaining = self.expire_time - GameRules:GetGameTime()
	if remaining <= 0 then return end

	-- 收集受益单位：己方英雄 + 英雄控制的单位（召唤物/幻象等，owner 为英雄）
	local seen = {}
	local units = {}
	local function CollectUnit(unit)
		if unit ~= nil and not unit:IsNull() and not seen[unit] then
			seen[unit] = true
			table.insert(units, unit)
		end
	end

	for _, hero in pairs(HeroList:GetAllHeroes()) do
		if not hero:IsNull() and hero:GetTeamNumber() == caster:GetTeamNumber() and hero:IsAlive() then
			CollectUnit(hero)
		end
	end

	local all_units = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil,
		99999, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _, unit in pairs(all_units) do
		-- 已持有状态的单位直接跳过（补发循环也不会处理它），避免对它们做无谓的 pcall / owner 判定
		if unit:IsAlive() and not unit:HasModifier("modifier_ability_thdots_ellen04_blank") then
			local ok, is_hero = pcall(function()
				return unit:GetOwner():IsRealHero()
			end)
			if ok and is_hero then
				local owner = unit:GetOwner()
				if owner ~= nil and not owner:IsNull() and owner:GetTeamNumber() == caster:GetTeamNumber() then
					CollectUnit(unit)
				end
			end
		end
	end

	for _, unit in pairs(units) do
		local existing = unit:FindModifierByNameAndCaster("modifier_ability_thdots_ellen04_blank", caster)
		if existing == nil then
			unit:AddNewModifier(caster, ability, "modifier_ability_thdots_ellen04_blank", {duration = remaining})
		elseif existing:GetDieTime() < self.expire_time then
			-- 连续施法后 expire_time 已刷新：已持有单位同步延长持续时间（渐隐进度不重置，只有到期时间对齐最新一次施法）
			existing:SetDuration(remaining, true)
		end
	end
end

function modifier_ability_thdots_ellen04_controller:OnDestroy()
	if not IsServer() then return end

	-- 领域自然结束（duration 到期）时：强制移除所有受影响单位的空白状态，结束全部效果
	local caster = self:GetCaster()
	if caster == nil or caster:IsNull() then return end
	local all_units = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil,
		99999, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _, unit in pairs(all_units) do
		local mod = unit:FindModifierByNameAndCaster("modifier_ability_thdots_ellen04_blank", caster)
		if mod ~= nil then
			mod:Destroy()
		end
	end
end

--=================================================================================================================
-- 空白状态：挂每个受益单位——血条隐藏、敌方小地图隐藏、渐隐进入隐身
--=================================================================================================================
modifier_ability_thdots_ellen04_blank = class({})

function modifier_ability_thdots_ellen04_blank:IsHidden() return false end
function modifier_ability_thdots_ellen04_blank:IsDebuff() return false end
function modifier_ability_thdots_ellen04_blank:IsPurgable() return false end
-- 单位死亡即失去状态，复活后由控制器重新下发（重新渐隐）
function modifier_ability_thdots_ellen04_blank:RemoveOnDeath() return true end

-- 全能骑士退化光环对受影响单位的特效
function modifier_ability_thdots_ellen04_blank:GetEffectName()
	return "particles/units/heroes/hero_omniknight/omniknight_degen_aura_debuff.vpcf"
end

function modifier_ability_thdots_ellen04_blank:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_ability_thdots_ellen04_blank:OnCreated()
	local ability = self:GetAbility()
	if ability == nil then self:Destroy() return end

	-- 【双端】渐隐基准。OnCreated 在客户端同样会被调用，这几个赋值必须放在IsServer 守卫【之前】：双端基于同一个 GameRules 时钟各自算出一致的值，客户端渲染才能看到渐隐过程。
	self.parent			= self:GetParent()
	self.fade_time		= ability:GetSpecialValueFor("fade_time")
	self.fade_start		= GameRules:GetGameTime()
	self.fade_end_time	= self.fade_start + self.fade_time
	-- 渐隐进度初值（双端）：0 = 完全可见。之后由服务端 think 每tick更新并网络同步
	self:SetStackCount(0)

	if not IsServer() then return end

	local caster = self:GetCaster()
	if caster == nil or caster:IsNull() then self:Destroy() return end
	if self:GetDuration() <= 0 then
		self:Destroy()
		return
	end

	self.tick_interval	= ability:GetSpecialValueFor("tick_interval")
	-- 万宝槌周期强驱散的结算步长（tick 数）：见 ability-patterns.md 模式 11 的换算约定
	self.purge_ticks	= math.max(1, math.floor(ability:GetSpecialValueFor("scepter_purge_interval") / self.tick_interval + 0.5))
	self.tick_count		= 0

	-- 万宝槌：进入领域时立即强驱散一次
	if caster:HasModifier("modifier_item_wanbaochui") then
		self:StrongPurge()
	end

	self:OnIntervalThink()
	self:StartIntervalThink(self.tick_interval)
end

function modifier_ability_thdots_ellen04_blank:OnIntervalThink()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	if caster == nil or caster:IsNull() or ability == nil then return end

	-- 渐隐进度同步：SetStackCount 由引擎网络同步到客户端，渲染端 GetFadeLevel 读 StackCount，破隐重置立即反映到画面。
	local now = GameRules:GetGameTime()
	local level = 1
	if now < self.fade_end_time and self.fade_time > 0 then
		level = (now - self.fade_start) / self.fade_time
		if level < 0 then level = 0 end
	end
	self:SetStackCount(math.floor(level * 100 + 0.5))

	-- 渐隐满 100% 后挂上完全隐身 modifier；未满 / 破隐时摘除。invis 的 CheckState 只写常量，创建即生效，不受「CheckState 缓存」影响。
	if self:IsFullyFaded() then
		if self.parent ~= nil and not self.parent:IsNull()
			and not self.parent:HasModifier("modifier_ability_thdots_ellen04_invis") then
			-- invis 必须带 duration（blank 的剩余时间），否则 blank 到期后 OnIntervalThink 停止。
			local remaining = self:GetDieTime() - GameRules:GetGameTime()
			if remaining > 0 then
				self.parent:AddNewModifier(caster, ability, "modifier_ability_thdots_ellen04_invis",
					{duration = remaining})
			end
		end
	elseif self.parent ~= nil and not self.parent:IsNull()
		and self.parent:HasModifier("modifier_ability_thdots_ellen04_invis") then
		self.parent:RemoveModifierByName("modifier_ability_thdots_ellen04_invis")
	end

	-- 万宝槌：领域期间周期性强驱散
	if caster:HasModifier("modifier_item_wanbaochui") then
		self.tick_count = self.tick_count + 1
		if self.tick_count >= self.purge_ticks then
			self.tick_count = 0
			self:StrongPurge()
		end
	end
end

-- 强驱散 + 视觉反馈。施法瞬间与每 scepter_purge_interval 秒各调用一次，每次调用都完整播放一遍冰龙爆发特效。
function modifier_ability_thdots_ellen04_blank:StrongPurge()
	if self.parent == nil or self.parent:IsNull() then return end
	self.parent:Purge(false, true, false, true, true)
	local pfx = ParticleManager:CreateParticle(
		"particles/econ/items/winter_wyvern/winter_wyvern_ti7/wyvern_cold_embrace_ti7buff_burst.vpcf",
		PATTACH_ABSORIGIN_FOLLOW, self.parent)
	local parent = self.parent
	parent:SetContextThink(DoUniqueString("ellen04_purge_fx"), function()
		if pfx ~= nil then
			ParticleManager:DestroyParticle(pfx, false)
		end
		return nil
	end, 0.9)
end

-- 渐隐重置：破隐或渐隐期间被敌方英雄攻击命中后，从头开始渐隐。
function modifier_ability_thdots_ellen04_blank:ResetFade()
	self.fade_start = GameRules:GetGameTime()
	self.fade_end_time = self.fade_start + self.fade_time

	if not IsServer() then return end
	-- 渐隐进度清零并同步到客户端（渲染端据此立即恢复可见）
	self:SetStackCount(0)
	if self.parent ~= nil and not self.parent:IsNull()
		and self.parent:HasModifier("modifier_ability_thdots_ellen04_invis") then
		self.parent:RemoveModifierByName("modifier_ability_thdots_ellen04_invis")
	end
end

function modifier_ability_thdots_ellen04_blank:CheckState()
	return {
		[MODIFIER_STATE_NO_HEALTH_BAR]				= true,
		[MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES]	= true,
	}
end

--=================================================================================================================
-- 完全隐身状态：与「渐隐进度」解耦。
--=================================================================================================================
function modifier_ability_thdots_ellen04_blank:OnRefresh()
	if not IsServer() then return end
	local ability = self:GetAbility()
	if ability ~= nil then
		self.fade_time = ability:GetSpecialValueFor("fade_time")
	end
	self.fade_start = GameRules:GetGameTime()
	self.fade_end_time = self.fade_start + self.fade_time
	self:SetStackCount(0)
	if self.parent ~= nil and not self.parent:IsNull()
		and self.parent:HasModifier("modifier_ability_thdots_ellen04_invis") then
		self.parent:RemoveModifierByName("modifier_ability_thdots_ellen04_invis")
	end
end


function modifier_ability_thdots_ellen04_blank:OnDestroy()
	if not IsServer() then return end
	if self.parent ~= nil and not self.parent:IsNull()
		and self.parent:HasModifier("modifier_ability_thdots_ellen04_invis") then
		self.parent:RemoveModifierByName("modifier_ability_thdots_ellen04_invis")
	end
end

modifier_ability_thdots_ellen04_invis = class({})
LinkLuaModifier("modifier_ability_thdots_ellen04_invis", "scripts/vscripts/abilities/abilityellen.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_ability_thdots_ellen04_invis:IsHidden() return false end
function modifier_ability_thdots_ellen04_invis:IsDebuff() return false end
function modifier_ability_thdots_ellen04_invis:IsPurgable() return false end
function modifier_ability_thdots_ellen04_invis:RemoveOnDeath() return true end

function modifier_ability_thdots_ellen04_invis:CheckState()
	return {
		[MODIFIER_STATE_INVISIBLE] = true,
	}
end

function modifier_ability_thdots_ellen04_blank:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_ATTACK_START,
		MODIFIER_EVENT_ON_ABILITY_EXECUTED,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

-- 受到敌方英雄的伤害（含技能伤害）时重置渐隐 —— 平A命中走 OnAttackLanded，技能/法术伤害走（OnAttackLanded 覆盖不到非攻击伤害）
function modifier_ability_thdots_ellen04_blank:OnTakeDamage(keys)
	if keys.unit ~= self.parent then return end
	local damage = keys.original_damage or keys.damage or 0
	if damage <= 0 then return end
	local attacker = keys.attacker
	if attacker == nil or attacker:IsNull() then return end
	if attacker:GetTeamNumber() == self.parent:GetTeamNumber() then return end
	-- 伤害来源可能是特殊实体（无 IsRealHero 方法），pcall 兜底
	local ok, is_hero = pcall(function()
		return attacker:IsRealHero()
	end)
	if ok and is_hero then
		self:ResetFade()
	end
end

-- 渐隐进度
function modifier_ability_thdots_ellen04_blank:GetFadeLevel()
	return (self:GetStackCount() or 0) / 100
end

-- 是否已完全渐隐
function modifier_ability_thdots_ellen04_blank:IsFullyFaded()
	return self:GetFadeLevel() >= 1
end

-- 模型渐隐渲染：引擎按 0~1 插值透明度
function modifier_ability_thdots_ellen04_blank:GetModifierInvisibilityLevel()
	return self:GetFadeLevel()
end

-- 完全隐身期间提供移速加成
function modifier_ability_thdots_ellen04_blank:GetModifierMoveSpeedBonus_Percentage()
	if self:IsFullyFaded() then
		local ability = self:GetAbility()
		if ability ~= nil then
			return ability:GetSpecialValueFor("movespeed_bonus")
		end
	end
	return 0
end

-- 25 级天赋：领域期间受到的伤害降低。
function modifier_ability_thdots_ellen04_blank:GetModifierIncomingDamage_Percentage()
	local ability = self:GetAbility()
	if ability == nil then return 0 end
	local caster = self:GetCaster()
	if caster == nil or caster:IsNull() then return 0 end
	return ability:GetSpecialValueFor("damage_reduction")
		+ FindTelentValue(caster, "special_bonus_unique_ellen_3")
end

-- 受到敌方英雄攻击命中：渐隐期间 → 重置渐隐计时（延迟渐隐）；已隐身 → 破隐后重新渐隐
function modifier_ability_thdots_ellen04_blank:OnAttackLanded(keys)
	if keys.target ~= self.parent then return end
	local attacker = keys.attacker
	if attacker == nil or attacker:IsNull() then return end
	if attacker:GetTeamNumber() == self.parent:GetTeamNumber() then return end

	if self:IsFullyFaded() then
		self:ResetFade()
	elseif attacker:IsRealHero() then
		self:ResetFade()
	end
end

-- 自身主动攻击：破隐后重新渐隐
function modifier_ability_thdots_ellen04_blank:OnAttackStart(keys)
	if keys.attacker ~= self.parent then return end
	self:ResetFade()
end

-- 自身施放技能：破隐后重新渐隐
function modifier_ability_thdots_ellen04_blank:OnAbilityExecuted(keys)
	if keys.unit ~= self.parent then return end
	self:ResetFade()
end

--=================================================================================================================
-- 魔晶「空白少女」（2026-09-20）
--=================================================================================================================
ability_thdots_ellen_shard = class({})

LinkLuaModifier("modifier_thdots_ellen_shard_stats", "scripts/vscripts/abilities/abilityellen.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_thdots_ellen_shard_invuln", "scripts/vscripts/abilities/abilityellen.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_thdots_ellen_shard_shuffle", "scripts/vscripts/abilities/abilityellen.lua", LUA_MODIFIER_MOTION_NONE)

function ability_thdots_ellen_shard:GetIntrinsicModifierName()
	return "modifier_thdots_ellen_shard_stats"
end

function ability_thdots_ellen_shard:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	if caster == nil or caster:IsNull() then return end

	caster:EmitSound("Hero_Omniknight.Purification")

	-- 洗礼特效
	local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:DestroyParticleSystem(pfx, false)

	-- 提灯主动特效
	caster:AddNewModifier(caster, self, "modifier_thdots_ellen_shard_lantern",
		{duration = self:GetSpecialValueFor("invuln_duration")})

	-- 短暂无敌，无敌结束时执行属性重分
	caster:AddNewModifier(caster, self, "modifier_thdots_ellen_shard_invuln", {duration = self:GetSpecialValueFor("invuln_duration")})
end

--=================================================================================================================
-- 被动：+30 主属性（按当前主属性动态提供，属性重分后自动跟随切换）
--=================================================================================================================
modifier_thdots_ellen_shard_stats = class({})

function modifier_thdots_ellen_shard_stats:IsHidden() return true end
function modifier_thdots_ellen_shard_stats:IsPurgable() return false end
function modifier_thdots_ellen_shard_stats:RemoveOnDeath() return false end

function modifier_thdots_ellen_shard_stats:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}
end

-- 属性重分产生的增量，不写进 SetBaseXxx，避免引擎在重生时按 hero KV 还原基础属性。
function modifier_thdots_ellen_shard_stats:GetShuffleDeltas()
	local parent = self:GetParent()
	if parent == nil or parent:IsNull() then return 0, 0, 0 end
	local shuffle = parent:FindModifierByName("modifier_thdots_ellen_shard_shuffle")
	if shuffle == nil then return 0, 0, 0 end
	return shuffle.delta_str or 0, shuffle.delta_agi or 0, shuffle.delta_int or 0
end

function modifier_thdots_ellen_shard_stats:GetModifierBonusStats_Strength()
	local d_str = self:GetShuffleDeltas()
	local bonus = 0
	if self:GetParent():GetPrimaryAttribute() == DOTA_ATTRIBUTE_STRENGTH then
		bonus = self:GetAbility():GetSpecialValueFor("stats_bonus")
	end
	return bonus + d_str
end

function modifier_thdots_ellen_shard_stats:GetModifierBonusStats_Agility()
	local _, d_agi = self:GetShuffleDeltas()
	local bonus = 0
	if self:GetParent():GetPrimaryAttribute() == DOTA_ATTRIBUTE_AGILITY then
		bonus = self:GetAbility():GetSpecialValueFor("stats_bonus")
	end
	return bonus + d_agi
end

function modifier_thdots_ellen_shard_stats:GetModifierBonusStats_Intellect()
	local _, _, d_int = self:GetShuffleDeltas()
	local bonus = 0
	if self:GetParent():GetPrimaryAttribute() == DOTA_ATTRIBUTE_INTELLECT then
		bonus = self:GetAbility():GetSpecialValueFor("stats_bonus")
	end
	return bonus + d_int
end


-- 提灯特效托管
modifier_thdots_ellen_shard_lantern = class({})
LinkLuaModifier("modifier_thdots_ellen_shard_lantern", "scripts/vscripts/abilities/abilityellen.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_ellen_shard_lantern:IsHidden() return true end
function modifier_thdots_ellen_shard_lantern:IsPurgable() return false end
function modifier_thdots_ellen_shard_lantern:RemoveOnDeath() return true end

function modifier_thdots_ellen_shard_lantern:OnCreated()
	if not IsServer() then return end
	local parent = self:GetParent()
	if parent == nil or parent:IsNull() then return end
	self.lantern_pfx = ParticleManager:CreateParticle(
		"particles/thd2/items/item_tsundere.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
end

function modifier_thdots_ellen_shard_lantern:OnRemoved()
	if not IsServer() then return end
	if self.lantern_pfx ~= nil then
		ParticleManager:DestroyParticle(self.lantern_pfx, true)
		self.lantern_pfx = nil
	end
end

--=================================================================================================================
-- 无敌窗口：白色高亮特效，无敌结束时随机重分基础属性并切换主属性
--=================================================================================================================
modifier_thdots_ellen_shard_invuln = class({})

function modifier_thdots_ellen_shard_invuln:IsHidden() return false end
function modifier_thdots_ellen_shard_invuln:IsPurgable() return false end
function modifier_thdots_ellen_shard_invuln:RemoveOnDeath() return false end

-- 白色高亮：守护天使白光
function modifier_thdots_ellen_shard_invuln:GetEffectName()
	return "particles/units/heroes/hero_omniknight/omniknight_guardian_angel_ally.vpcf"
end

function modifier_thdots_ellen_shard_invuln:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_thdots_ellen_shard_invuln:CheckState()
	return {
		-- 施放期间无法行动（眩晕：不能移动/攻击/施法），时长与无敌一致
		[MODIFIER_STATE_STUNNED] = true,
	}
end

-- 无敌用三系 ABSOLUTE_NO_DAMAGE 实现
function modifier_thdots_ellen_shard_invuln:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
	}
end

function modifier_thdots_ellen_shard_invuln:GetAbsoluteNoDamagePhysical() return 1 end
function modifier_thdots_ellen_shard_invuln:GetAbsoluteNoDamageMagical() return 1 end
function modifier_thdots_ellen_shard_invuln:GetAbsoluteNoDamagePure() return 1 end

function modifier_thdots_ellen_shard_invuln:OnDestroy()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local ability = self:GetAbility()
	if caster == nil or caster:IsNull() then return end
	if ability == nil then return end
	if not caster:IsAlive() then return end

	-- 读取重分前的基础属性（GetBaseXxx 不含装备/天赋等外部加成）
	local old_str = caster:GetBaseStrength()
	local old_agi = caster:GetBaseAgility()
	local old_int = caster:GetBaseIntellect()
	local min_stat = ability:GetSpecialValueFor("min_stat")
	local total = math.floor(old_str + old_agi + old_int)

	-- 属性总和过低时不重分（防御性下限，正常等级远高于此）
	if total < min_stat * 3 then return end

	-- 把基础属性总和随机分成三份（每份至少 min_stat 点）
	local part1 = RandomInt(min_stat, total - min_stat * 2)
	local part2 = RandomInt(min_stat, total - part1 - min_stat)
	local part3 = total - part1 - part2

	-- 洗牌：三份与力量/敏捷/智力的对应顺序随机
	local parts = {part1, part2, part3}
	for i = #parts, 2, -1 do
		local j = RandomInt(1, i)
		parts[i], parts[j] = parts[j], parts[i]
	end
	local new_str, new_agi, new_int = parts[1], parts[2], parts[3]

	-- 以分配后最高的属性作为主属性（数值并列时偏向力量，与秦心先例一致）
	local primary = DOTA_ATTRIBUTE_STRENGTH
	if new_agi > new_str and new_agi >= new_int then
		primary = DOTA_ATTRIBUTE_AGILITY
	elseif new_int > new_str and new_int > new_agi then
		primary = DOTA_ATTRIBUTE_INTELLECT
	end

	-- 关键：不写 SetBaseXxx。引擎会在重生时按 hero KV 的 AttributeBaseXxx 把基础属性还原，面板主属性随之退回智力。改为把「相对当前基础属性的增量」记在常驻 modifier 上，由 modifier_thdots_ellen_shard_stats 在 property 里叠加。
	local base_str = math.floor(caster:GetBaseStrength())
	local base_agi = math.floor(caster:GetBaseAgility())
	local base_int = math.floor(caster:GetBaseIntellect())

	local old_shuffle = caster:FindModifierByName("modifier_thdots_ellen_shard_shuffle")
	if old_shuffle ~= nil then
		old_shuffle:Destroy()
	end
	caster:AddNewModifier(caster, ability, "modifier_thdots_ellen_shard_shuffle", {
		delta_str = new_str - base_str,
		delta_agi = new_agi - base_agi,
		delta_int = new_int - base_int,
		primary = primary,
	})

	-- 立即刷新一次面板主属性
	caster:SetPrimaryAttribute(primary)
	caster:CalculateStatBonus(true)

	-- 三色数字：力量红 / 敏捷绿 / 智力蓝。
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, caster, new_str, nil)
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, caster, new_agi, nil)
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_ADD, caster, new_int, nil)

end

--=================================================================================================================
-- 属性重分记录：重生时重新写入基础属性与主属性（重生后仍有效）
--=================================================================================================================
modifier_thdots_ellen_shard_shuffle = class({})

function modifier_thdots_ellen_shard_shuffle:IsHidden() return true end
function modifier_thdots_ellen_shard_shuffle:IsPurgable() return false end
function modifier_thdots_ellen_shard_shuffle:RemoveOnDeath() return false end

-- params 由 AddNewModifier 网络同步到客户端，
function modifier_thdots_ellen_shard_shuffle:OnCreated(params)
	self.delta_str	= params.delta_str or 0
	self.delta_agi	= params.delta_agi or 0
	self.delta_int	= params.delta_int or 0
	self.primary	= params.primary or DOTA_ATTRIBUTE_STRENGTH

	if not IsServer() then return end
	self:StartIntervalThink(0.5)
end

-- 周期校正主属性：引擎会在重生 / 属性重算等多个时点按 hero KV 把主属性还原。
function modifier_thdots_ellen_shard_shuffle:OnIntervalThink()
	if not IsServer() then return end
	if self.primary == nil then return end
	local parent = self:GetParent()
	if parent == nil or parent:IsNull() then return end
	parent:SetPrimaryAttribute(self.primary)
	parent:CalculateStatBonus(true)
end

function modifier_thdots_ellen_shard_shuffle:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_RESPAWN,
	}
end

function modifier_thdots_ellen_shard_shuffle:OnRespawn(keys)
	if not IsServer() then return end
	if keys.unit ~= self:GetParent() then return end
	if self.primary == nil then return end
	local parent = self:GetParent()
	local other = DOTA_ATTRIBUTE_STRENGTH
	if self.primary == DOTA_ATTRIBUTE_STRENGTH then
		other = DOTA_ATTRIBUTE_AGILITY
	end
	parent:SetPrimaryAttribute(other)
	parent:CalculateStatBonus(true)
	parent:SetContextThink(DoUniqueString("ellen_shard_writeback"), function()
		if parent ~= nil and not parent:IsNull() and self.primary ~= nil then
			parent:SetPrimaryAttribute(self.primary)
			parent:CalculateStatBonus(true)
		end
		return nil
	end, 0.15)

	-- 保险：单位死亡期间引擎可能清除 modifier 的 interval think，这里强制重启周期校正，并叠加多时点延迟校正覆盖引擎任意还原时机。
	self:StartIntervalThink(0.5)
	local delays = {0.5, 1.0, 2.0, 3.0}
	for i, t in ipairs(delays) do
		parent:SetContextThink(DoUniqueString("ellen_shard_reapply"), function()
			if parent ~= nil and not parent:IsNull() and parent:IsAlive()
				and self.primary ~= nil then
				parent:SetPrimaryAttribute(self.primary)
				parent:CalculateStatBonus(true)
			end
			return nil
		end, t)
	end
end
