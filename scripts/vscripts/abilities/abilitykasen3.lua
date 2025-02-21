ability_thdots_kasen3_01 = {}
function ability_thdots_kasen3_01:OnSpellStart()
	if not IsServer() then return end
   	self.caster = self:GetCaster()
    local target = self:GetCursorTarget()
    self.duration = self:GetSpecialValueFor("duration")
    local projectile_name = "models/ibaraki_kasen/bandage_attack.vpcf"
	local projectile_speed = 1000
	local info = {
		Target = target,
		Source = self.caster,
		Ability = self,	
		EffectName = projectile_name,
		iMoveSpeed = projectile_speed,
		vSourceLoc= self.caster:GetAbsOrigin(),                
		bDodgeable = false,                               
	}
	ProjectileManager:CreateTrackingProjectile(info)
	if self.caster:HasScepter() then
		local targets = FindUnitsInRadius(
			self.caster:GetTeamNumber(),	-- int, your team number
			target:GetOrigin(),	-- point, center point
			nil,	-- handle, cacheUnit. (not known)
			300,	-- float, radius. or use FIND_UNITS_EVERYWHERE
			DOTA_UNIT_TARGET_TEAM_BOTH,	-- int, team filter
			DOTA_UNIT_TARGET_HERO,	-- int, type filter
			DOTA_UNIT_TARGET_FLAG_NONE,	-- int, flag filter
			FIND_CLOSEST,	-- int, order filter
			false	-- bool, can grow cache
		)
		if targets[2] == nil then
			targets = FindUnitsInRadius(
			self.caster:GetTeamNumber(),
			target:GetOrigin(),
			nil,
			300,
			DOTA_UNIT_TARGET_TEAM_BOTH,
			DOTA_UNIT_TARGET_BASIC,
			DOTA_UNIT_TARGET_FLAG_NONE,
			FIND_CLOSEST,
			false
		)
		end
		print(targets[2]:GetClassname())
		if targets == nil then return end
		info = {
			Target = targets[2],
			Source = self.caster,
			Ability = self,
			EffectName = projectile_name,
			iMoveSpeed = projectile_speed,
			vSourceLoc= target:GetAbsOrigin(),
			bDodgeable = false,
		}
		ProjectileManager:CreateTrackingProjectile(info)
	end
end
function ability_thdots_kasen3_01:OnProjectileHit(hTarget, vLocation)
    if hTarget:GetTeam() ~= self.caster:GetTeam() then
		if hTarget:TriggerSpellAbsorb(self) then return nil end
        hTarget:AddNewModifier(self.caster, self, "modifier_ability_thdots_kasen3_01_enemy", { duration = self.duration * (1 - hTarget:GetStatusResistance())})
    else
        hTarget:AddNewModifier(self.caster, self, "modifier_ability_thdots_kasen3_01_ally", {duration = self.duration})
    end
end
modifier_ability_thdots_kasen3_01_enemy={}
LinkLuaModifier("modifier_ability_thdots_kasen3_01_enemy","scripts/vscripts/abilities/abilitykasen3.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_kasen3_01_enemy:OnCreated()
    if not IsServer() then return end
    self.caster = self:GetCaster()
    self.target = self:GetParent()
    self.ability = self:GetAbility()
    self.damage = self.ability:GetSpecialValueFor("damage_per_tick")/2
    self.damage_type = self.ability:GetAbilityDamageType()
    self.damage_interval = 0.5
    self.damage_table = {
        victim = self.target,
        attacker = self.caster,
        damage = self.damage,
        damage_type = self.damage_type,
        ability = self.ability,
    }
    ApplyDamage(self.damage_table)
    self:StartIntervalThink(self.damage_interval)
end
function modifier_ability_thdots_kasen3_01_enemy:OnIntervalThink()
	if IsServer() then
		ApplyDamage(self.damage_table)
	end
end
function modifier_ability_thdots_kasen3_01_enemy:CheckState()
	local state = {
	[MODIFIER_STATE_DISARMED] = true,
	[MODIFIER_STATE_ROOTED] = true,
	[MODIFIER_STATE_INVISIBLE] = false,
	}
	return state
end
function modifier_ability_thdots_kasen3_01_enemy:GetEffectName()
	return "models/ibaraki_kasen/bandage_winding.vpcf"
end

function modifier_ability_thdots_kasen3_01_enemy:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

modifier_ability_thdots_kasen3_01_ally={}
LinkLuaModifier("modifier_ability_thdots_kasen3_01_ally","scripts/vscripts/abilities/abilitykasen3.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_kasen3_01_ally:OnCreated()
    self.caster = self:GetCaster()
    self.target = self:GetParent()
    self.ability = self:GetAbility()
    self.damage_interval = 0.5
    self.heal_per_tick = self.ability:GetSpecialValueFor("damage_per_tick")/2
    if IsServer() then
    self.target:Heal(self.heal_per_tick, self.caster)
    self:StartIntervalThink(self.damage_interval)
    end
end
function modifier_ability_thdots_kasen3_01_ally:OnIntervalThink()
	self:GetParent():Heal(self.heal_per_tick, self:GetCaster())
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, self:GetParent(), self.heal_per_tick, nil)
end
function OnKasenBear01AttackLanded(keys)
    local caster =keys.caster
    if(keys.ability:IsCooldownReady()) then
        if RollPseudoRandom(keys.ability:GetSpecialValueFor("chance"),caster) then
        keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_kasenbear_01_buff", {duration = 5})
		keys.ability:StartCooldown(keys.ability:GetCooldown(keys.ability:GetLevel()-1))
        end
    end
end
function OnKasenBear02AttackLanded(keys)
    local caster =keys.caster
    if caster:PassivesDisabled() then return end
	local target = keys.target
	if(target.kasan02_debuff==nil)then target.kasan02_debuff= 0 end
    local count = target.kasan02_debuff + 1
    if(count<=keys.limit)then
		keys.ability:ApplyDataDrivenModifier(caster,target , "modifier_kasen3_bear_02_attack_debuff", {duration = 3})
        target.kasan02_debuff= count
		print(target.kasan02_debuff)
	end
end
function OnKasenBear02DebuffEnd(keys)
	local target = keys.target
	print(target.kasan02_debuff)
	if(target.kasan02_debuff~=nil)then target.kasan02_debuff= target.kasan02_debuff - 1 end
end
ability_kasenbear_03={}
function ability_kasenbear_03:GetIntrinsicModifierName() return "modifier_razor_eye_of_the_storm_lua" end
LinkLuaModifier( "modifier_razor_eye_of_the_storm_lua", "scripts/vscripts/abilities/abilitykasen3.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_razor_eye_of_the_storm_lua_debuff", "scripts/vscripts/abilities/abilitykasen3.lua", LUA_MODIFIER_MOTION_NONE )
function ability_kasenbear_03:Precache( context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_razor.vsndevts", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_razor/razor_eye_of_the_storm.vpcf", context )
end
-- Created by Elfansoer
modifier_razor_eye_of_the_storm_lua = class({})
function modifier_razor_eye_of_the_storm_lua:RemoveOnDeath() return true end
function modifier_razor_eye_of_the_storm_lua:IsHidden() return false end
function modifier_razor_eye_of_the_storm_lua:IsDebuff() return false end
function modifier_razor_eye_of_the_storm_lua:IsPurgable() return false end
function modifier_razor_eye_of_the_storm_lua:OnCreated( kv )
	if not IsServer() then return end
	self.parent = self:GetParent()
	-- references
	self.radius = self:GetAbility():GetSpecialValueFor( "AbilityCastRange" )
	self.damage = self:GetAbility():GetSpecialValueFor( "damage" )
	self.interval = self:GetAbility():GetSpecialValueFor( "AbilityCooldown" )
	self.armor = self:GetAbility():GetSpecialValueFor( "armor_reduce" )
	self.strikes = 3
	self.targets = {}
	self.flag = false
	-- ability properties
	self.abilityDamageType = self:GetAbility():GetAbilityDamageType()

	-- precache damage
	self.damageTable = {
		-- victim = target,
		attacker = self.parent,
		damage = self.damage,
		damage_type = self.abilityDamageType,
		ability = self:GetAbility(), --Optional.
	}
	-- Start interval
	self:StartIntervalThink( self.interval )
	self:OnIntervalThink()

	-- play effects
	self:PlayEffects1()
end

function modifier_razor_eye_of_the_storm_lua:OnRemoved()
end
function modifier_razor_eye_of_the_storm_lua:OnDestroy()
	if not IsServer() then return end
	-- stop sound
	local sound_loop = "Hero_Razor.Storm.Loop"
	local sound_end = "Hero_Razor.StormEnd"
	StopSoundOn( sound_loop, self.parent )
	EmitSoundOn( sound_end, self.parent )
end
function modifier_razor_eye_of_the_storm_lua:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
	return funcs
end
function modifier_razor_eye_of_the_storm_lua:OnAttackLanded(keys)
	if not IsServer() then return end
	if keys.attacker ~= self.parent then return end
	if keys.target:IsBuilding() then return end
	if self.flag == true then
		self.damageTable.victim = keys.target
		ApplyDamage( self.damageTable )
		keys.target:AddNewModifier(self.parent, self, "modifier_razor_eye_of_the_storm_lua_debuff", {duration = 5,armor = self.armor}
		)
	end
end
--------------------------------------------------------------------------------
-- Interval Effects
function modifier_razor_eye_of_the_storm_lua:OnIntervalThink()
	if not IsServer() then return end
	if self.parent:GetClassname()=="npc_dota_lone_druid_bear" then
		print(self.parent:GetHealth())
		if self.parent:GetHealth() <= 0 then self:Destroy() end
		if self.parent.owner:FindAbilityByName("special_bonus_unique_kasen3_2"):GetLevel() ~= 0 then
		self.flag = true
		end
	end
	local targets = {}
	-- find enemies
	local enemies = FindUnitsInRadius(
		self.parent:GetTeamNumber(),	-- int, your team number
		self.parent:GetOrigin(),	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		self.radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,	-- int, type filter
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)
	if #enemies<1 then return end

	-- find enemies based on number of strikes per interval
	for i=1,self.strikes do
		local target
		-- find enemies in linked
		if target then break end
		-- find target in lowest
		for _,enemy in pairs(enemies) do
			if not targets[enemy] then
				-- check building
				if not enemy:IsBuilding() then
					targets[enemy] = true
					target = enemy
					break
				elseif (enemy:IsAncient() or enemy:IsTower() or enemy:IsBarracks()) then
					targets[enemy] = true
					target = enemy
					break
				end
			end
		end
	end

	-- strike targets
	for enemy,_ in pairs(targets) do
		-- damage
		self.damageTable.victim = enemy
		ApplyDamage( self.damageTable )

		-- add modifier
		enemy:AddNewModifier(
			self.parent, -- player source
			self, -- ability source
			"modifier_razor_eye_of_the_storm_lua_debuff", -- modifier name
			{
				duration = 5,
			} -- kv
		)

		-- play effects
		self:PlayEffects2( enemy )
	end
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_razor_eye_of_the_storm_lua:PlayEffects1()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_razor/razor_rain_storm.vpcf"
	local sound_cast = "Hero_Razor.Storm.Cast"
	local sound_loop = "Hero_Razor.Storm.Loop"
	-- Create Particle
	self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self.parent )
	-- buff particle
	self:AddParticle(
		self.effect_cast,
		false, -- bDestroyImmediately
		false, -- bStatusEffect
		-1, -- iPriority
		false, -- bHeroEffect
		false -- bOverheadEffect
	)
	-- Create Sound
	EmitSoundOn( sound_cast, self.parent )
	EmitSoundOn( sound_loop, self.parent )
end

function modifier_razor_eye_of_the_storm_lua:PlayEffects2( enemy )
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_razor/razor_storm_lightning_strike.vpcf"
	local sound_cast = "Hero_razor.lightning"
	-- Create Particle
	-- NOTE: Don't know what is the proper effect
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_CUSTOMORIGIN, self.parent )
	ParticleManager:SetParticleControl( effect_cast, 0, self.parent:GetOrigin() + Vector(0,0,500) )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		1,
		enemy,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(0,0,0), -- unknown
		true -- unknown, true
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )
	-- Create Sound
	EmitSoundOn( sound_cast, enemy )
end
modifier_razor_eye_of_the_storm_lua_debuff = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_razor_eye_of_the_storm_lua_debuff:IsHidden() return false end
function modifier_razor_eye_of_the_storm_lua_debuff:IsDebuff() return true end
function modifier_razor_eye_of_the_storm_lua_debuff:IsPurgable() return false end
function modifier_razor_eye_of_the_storm_lua_debuff:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
--------------------------------------------------------------------------------
-- Initializations
function modifier_razor_eye_of_the_storm_lua_debuff:OnCreated( kv )
	if not IsServer() then return end
end
--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_razor_eye_of_the_storm_lua_debuff:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,}
	return funcs
end

function modifier_razor_eye_of_the_storm_lua_debuff:GetModifierPhysicalArmorBonus()
	return -1
end

ability_thdots_kasen3_04={}
function ability_thdots_kasen3_04:OnSpellStart()
	if not IsServer() then return end
    local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor("duration")
	caster:AddNewModifier(caster, self, "modifier_ability_thdots_kasen3_04", {duration = duration})
end
modifier_ability_thdots_kasen3_04 = {}
LinkLuaModifier("modifier_ability_thdots_kasen3_04","scripts/vscripts/abilities/abilitykasen3.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_kasen3_04:IsHidden() return false end
function modifier_ability_thdots_kasen3_04:IsDebuff() return false end
function modifier_ability_thdots_kasen3_04:IsPurgable() return true end
function modifier_ability_thdots_kasen3_04:RemoveOnDeath() return true end
function modifier_ability_thdots_kasen3_04:OnCreated()
	if not IsServer() then return end
	--print("Created")
	self.caster = self:GetCaster()
	self.ability = self:GetAbility()
	self.strength = self.caster:GetStrength()
	self.strength_bonus =  self.ability:GetSpecialValueFor("strength_bonus_pct") * self.strength * 0.01
	--print(self.strength_bonus)
	self.scale = (self.strength+self.strength_bonus)/5
	--print(self.scale)
	self.model = "models/ibaraki_kasen/ibaraki_kasen_2.vmdl"
	if self.ability:GetLevel() == 3 then
		self.model ="models/ibaraki_kasen/ibaraki_kasen_3.vmdl"
	end
	self.distance = self.ability:GetSpecialValueFor("distance")
	self.skeleton_bat = self.ability:GetSpecialValueFor("skeleton_bat")
	self.skeleton_duration = self.ability:GetSpecialValueFor("skeleton_duration")
	self.skeleton_armor = self.ability:GetSpecialValueFor("skeleton_armor")
	self.skeleton_hp = self.ability:GetSpecialValueFor("skeleton_hp")
end
function modifier_ability_thdots_kasen3_04:GetModifierBonusStats_Strength()
	return self.strength_bonus
end
function modifier_ability_thdots_kasen3_04:GetModifierModelScale()
	return self.scale
end
function modifier_ability_thdots_kasen3_04:GetModifierModelChange()
	return self.model
end
function modifier_ability_thdots_kasen3_04:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_MODEL_SCALE,
		MODIFIER_PROPERTY_MODEL_CHANGE,
	}
	return funcs
end
function modifier_ability_thdots_kasen3_04:OnDeath(params)
	if not IsServer() then return end
	if self:GetParent():PassivesDisabled() then return end
	if params.unit:GetClassname()=="npc_dota_wraith_king_skeleton_warrior" then self:GetParent():Heal(17.5,self.ability) end
	if (self:GetParent():GetAbsOrigin()-params.unit:GetAbsOrigin()):Length2D()> self.distance then return end
	if params.unit:IsBuilding() then return end
	local skeleton = nil
	print("dead")
	if  params.unit:IsRealHero() then
		skeleton = CreateUnitByName("npc_dota_wraith_king_skeleton_warrior", self.caster:GetAbsOrigin() + RandomVector(100) , true, self.caster, self.caster, self.caster:GetTeamNumber())
		skeleton:AddNewModifier(self.caster, self, "modifier_kill", {duration = self.skeleton_duration})
		skeleton:SetPhysicalArmorBaseValue(self.skeleton_armor*3)
		skeleton:SetBaseMaxHealth(self.skeleton_hp*3)
		skeleton:SetHealth(self.skeleton_hp*3)
		skeleton:SetBaseAttackTime(self.skeleton_bat/3)
		skeleton:SetBaseDamageMin(90)
		skeleton:SetBaseDamageMax(90)
		skeleton:SetModelScale(1.5)
		skeleton:SetControllableByPlayer( self.caster:GetPlayerID(),  true )
		skeleton:SetOwner(self.caster)
		skeleton:SetContextThink(DoUniqueString(self:GetName()), function()
			if self.caster:GetTeam() == DOTA_TEAM_GOODGUYS then
				skeleton:MoveToPositionAggressive(Vector(5654, 4939, 0))
			elseif self.caster:GetTeam() == DOTA_TEAM_BADGUYS then
				skeleton:MoveToPositionAggressive(Vector(-5864, -5340, 0))
			end
			return nil
		end, FrameTime())
	else
		skeleton = CreateUnitByName("npc_dota_wraith_king_skeleton_warrior", self.caster:GetAbsOrigin() + RandomVector(100), true, self.caster, self.caster, self.caster:GetTeamNumber())
		skeleton:AddNewModifier(self.caster, self, "modifier_kill", {duration = self.skeleton_duration})
		skeleton:SetControllableByPlayer( self.caster:GetPlayerID(),  true )
		skeleton:SetOwner(self.caster)
		skeleton:SetPhysicalArmorBaseValue(self.skeleton_armor)
		skeleton:SetBaseAttackTime(self.skeleton_bat)
		skeleton:SetContextThink(DoUniqueString(self:GetName()), function()
			if self.caster:GetTeam() == DOTA_TEAM_GOODGUYS then
				skeleton:MoveToPositionAggressive(Vector(5654, 4939, 0))
			elseif self.caster:GetTeam() == DOTA_TEAM_BADGUYS then
				skeleton:MoveToPositionAggressive(Vector(-5864, -5340, 0))
			end
			
			return nil
		end, FrameTime())
	end
end