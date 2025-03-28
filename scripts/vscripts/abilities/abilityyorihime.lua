
--自定义函数

--函数作用：计算距离
--函数输入：1. 施法者 2.目标
--函数输出：距离
function calDistanceHero(caster,target)
    local vCaster= caster:GetAbsOrigin()
    local vTarget= target:GetAbsOrigin()
    return math.sqrt(((vTarget.x-vCaster.x)*(vTarget.x-vCaster.x))+((vTarget.y-vCaster.y)*(vTarget.y-vCaster.y)))
end

--函数作用：计算距离
--函数输入：1. 坐标A 2.坐标B
--函数输出：距离
function calDistancePoint(v1,v2)
    return math.sqrt(((v2.x-v1.x)*(v2.x-v1.x))+((v2.y-v1.y)*(v2.y-v1.y)))
end

--自定义函数 end

ability_thdots_yorihime_01 = class({})
LinkLuaModifier( "modifier_ability_thdots_yorihime_01_debuff", "scripts/vscripts/abilities/abilityyorihime.lua",LUA_MODIFIER_MOTION_NONE )

--让技能有AOE显示
function ability_thdots_yorihime_01:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function ability_thdots_yorihime_01:CastFilterResultTarget(hTarget)
	if hTarget == self:GetCaster() or hTarget:IsMagicImmune() then
		return UF_FAIL_CUSTOM
	end
end

function ability_thdots_yorihime_01:OnSpellStart()
    if not IsServer() then return end
    local caster=self:GetCaster()
	self.target = self:GetCursorTarget()
	-- print(self:GetEffectiveCooldown(self:GetLevel()-1))
	if is_spell_blocked(self.target,caster) then return end
	

	

	EmitSoundOn( "Hero_Sven.StormBolt", self:GetCaster() )
	
	if caster:HasModifier("modifier_ability_thdots_yorihime_01_move") then
        caster:RemoveModifierByName("modifier_ability_thdots_yorihime_01_move")
    end
	caster:AddNewModifier(caster, self, "modifier_ability_thdots_yorihime_01_move", {duration = 60})

 
end
--------------------------------------------------------------------------------
--移动修饰器
modifier_ability_thdots_yorihime_01_move=class({})
LinkLuaModifier( "modifier_ability_thdots_yorihime_01_move", "scripts/vscripts/abilities/abilityyorihime.lua",LUA_MODIFIER_MOTION_NONE )
function modifier_ability_thdots_yorihime_01_move:IsHidden()        return false end
function modifier_ability_thdots_yorihime_01_move:IsPurgable()      return false end
function modifier_ability_thdots_yorihime_01_move:RemoveOnDeath()   return true end
function modifier_ability_thdots_yorihime_01_move:IsDebuff()        return false end
--Horizontal Motion Constant=0.033333335071802
--modifier 修改列表
-- function modifier_ability_thdots_yorihime_01_move:CheckState()
-- 	local state = {
-- 		[MODIFIER_STATE_STUNNED] = true,
-- 		[MODIFIER_STATE_OUT_OF_GAME] = true,
-- 		[MODIFIER_STATE_INVULNERABLE] = true,
-- 		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
-- 	}
-- 	return state
-- end

function modifier_ability_thdots_yorihime_01_move:CheckState()
	return {
		[MODIFIER_STATE_DISARMED] = true
	}
end

function modifier_ability_thdots_yorihime_01_move:OnCreated()
	if not IsServer() then return end
	self.caster=self:GetCaster()
    self.ability=self:GetAbility()
	self.target=self.ability:GetCursorTarget()
	self.targetLoc = self.target:GetAbsOrigin()
	self.cancel = false
	self.velocity = self.ability:GetSpecialValueFor("dash_speed") + FindTelentValue(self.caster,"special_bonus_unique_yorihime_5")
	-- self.ability:SetActivated(false)
	-- self.caster=self:GetCaster()
    -- self.ability=self:GetAbility()
	-- self.target=self.ability:GetCursorTarget()
	-- self.velocity=self.ability:GetSpecialValueFor("dash_speed")

	self.particle_lightning= ParticleManager:CreateParticle("particles/units/heroes/hero_stormspirit/stormspirit_ball_lightning.vpcf", PATTACH_POINT_FOLLOW, self.caster)
	ParticleManager:SetParticleControlEnt(self.particle_lightning, 0, self.caster, PATTACH_POINT_FOLLOW, "attach_hitloc", self.caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(self.particle_lightning, 1, self.caster, PATTACH_POINT_FOLLOW, "attach_hitloc", self.caster:GetAbsOrigin(), true)

	self.particle = ParticleManager:CreateParticleForTeam("particles/units/heroes/hero_spirit_breaker/spirit_breaker_charge_target.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent(), self:GetCaster():GetTeamNumber())
	self:AddParticle(self.particle, false, false, -1, false, true)

	self.direction=(self.target:GetAbsOrigin() - self.caster:GetAbsOrigin()):Normalized()
	self.distance=calDistanceHero(self.caster,self.target)

	if self.caster:GetTeamNumber() ~= self.target:GetTeamNumber() then
		self.target:AddNewModifier(self.caster, self.ability, "modifier_ability_thdots_yorihime_01_vision", {})
	end
	self:StartIntervalThink(FrameTime())
	self.talent_effect = nil
	if FindTelentValue(self.caster,"special_bonus_unique_yorihime_5") ~= 0 then
		self.talent_effect = ParticleManager:CreateParticle( "particles/units/heroes/hero_phoenix/phoenix_icarus_dive.vpcf", PATTACH_WORLDORIGIN, nil )
	end
end

function modifier_ability_thdots_yorihime_01_move:OnOrder(keys)
    if not IsServer() then return end

    local caster=self:GetParent()
    local ability=self:GetAbility()

	if keys.unit==caster and keys.order_type==DOTA_UNIT_ORDER_HOLD_POSITION  then
		self:StartIntervalThink(-1) 
		self.target:RemoveModifierByName("modifier_ability_thdots_yorihime_01_vision")
		FindClearSpaceForUnit(self.caster,self.caster:GetAbsOrigin(),false)
		self.cancel=true
		self.caster:SetForwardVector(self.caster:GetAbsOrigin():Normalized())
		self:Destroy()
		ParticleManager:DestroyParticle(self.particle_lightning,true)
		StopSoundOn("Hero_Sven.StormBoltImpact",caster)
	end
	
end

function modifier_ability_thdots_yorihime_01_move:OnIntervalThink()
	if not IsServer() then return end
	if self.target == nil or self.target:IsNull() or not self.target:IsAlive() then
		if self.target and not self.target:IsNull() then
			self.target:RemoveModifierByName("modifier_ability_thdots_yorihime_01_vision")
		end

		self.target = nil
		local targets = FindUnitsInRadius(self.caster:GetTeam(), self.targetLoc,nil,1000,
			self.ability:GetAbilityTargetTeam(),self.ability:GetAbilityTargetType(),DOTA_UNIT_TARGET_FLAG_NO_INVIS,FIND_CLOSEST, false)
		DeleteDummy(targets)
		if #targets > 0 then
			for _,unit in pairs (targets) do
				if unit and not unit:IsNull() then
					self.target = unit
					self.targetLoc = unit:GetAbsOrigin()
					self.target:AddNewModifier(self.caster, self.ability, "modifier_ability_thdots_yorihime_01_vision",{})
					find_target = true
					break
				end
			end
		end
	end

	if not self.target then
		self:StartIntervalThink(-1) 
		FindClearSpaceForUnit(self.caster,self.caster:GetAbsOrigin(),false)
		self.cancel=true
		self.caster:SetForwardVector(self.caster:GetAbsOrigin():Normalized())
		self:Destroy()
		ParticleManager:DestroyParticle(self.particle_lightning,true)
		StopSoundOn("Hero_Sven.StormBoltImpact",self.caster)
		return
	end

	self.targetLoc = self.target:GetAbsOrigin()
	self.caster:SetForwardVector(self.direction)
	self.direction=(self.target:GetAbsOrigin() - self.caster:GetAbsOrigin()):Normalized()
	self.distance=calDistanceHero(self.caster,self.target)
	if self.talent_effect ~= nil then
		ParticleManager:SetParticleControl(self.talent_effect, 0, self.caster:GetAbsOrigin() + self.caster:GetRightVector() * 32 )
	end
	if self.caster:IsRooted() or self.caster:IsStunned() or self.caster:IsHexed() then
		FindClearSpaceForUnit(self.caster,self.caster:GetAbsOrigin(),false)
		self.cancel=true
		self.caster:SetForwardVector(self.caster:GetAbsOrigin():Normalized())
		self:Destroy()
	end

	if self.distance > 100 then
		self.caster:SetAbsOrigin(self.caster:GetAbsOrigin() + self.direction * self.velocity * 0.033333335071802)
		self.caster:SetAbsOrigin(Vector(self.caster:GetAbsOrigin().x, self.caster:GetAbsOrigin().y, GetGroundHeight(self.caster:GetAbsOrigin(), self.caster)))
	else 
		FindClearSpaceForUnit(self.caster,self.caster:GetAbsOrigin(),false)
		self.caster:SetForwardVector(self.caster:GetAbsOrigin():Normalized())
		self:Destroy()
	end
	
end

function modifier_ability_thdots_yorihime_01_move:OnDestroy()
	--结束时眩晕敌人
	if not IsServer() then return end
	local 	ability = self:GetAbility()
	local 	target 	= self.target
	local   targetLoc = ability:GetCaster():GetOrigin()
	local	caster  = ability:GetCaster()
	-- ability:SetActivated(true)
	ability:StartCooldown(ability:GetEffectiveCooldown(ability:GetLevel()-1))
	ParticleManager:DestroyParticle(self.particle_lightning,true) 
	if target and not target:IsNull() then
		target:RemoveModifierByName("modifier_ability_thdots_yorihime_01_vision")
	end
	if self.talent_effect ~= nil then
		ParticleManager:DestroyParticle(self.talent_effect, false)
		ParticleManager:ReleaseParticleIndex(self.talent_effect)
	end


	local   radius 	= ability:GetSpecialValueFor("radius")
	local	stun_duration = ability:GetSpecialValueFor( "duration" ) + FindTelentValue(caster,"special_bonus_unique_yorihime_4")
	local	heal_duration = ability:GetSpecialValueFor( "heal_duration" )
	if self.cancel then
		return
	end
	-- print(caster:GetTeam())
	local 	enemy 	= FindUnitsInRadius(caster:GetTeam(),
			targetLoc,
			nil,
			radius,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
			DOTA_UNIT_TARGET_FLAG_NONE,
			FIND_ANY_ORDER,
			false)
	if not caster:IsAlive() then return end

	local effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_sven/sven_storm_bolt_projectile_explosion.vpcf", PATTACH_POINT, caster)
	ParticleManager:SetParticleControl(effectIndex , 3, targetLoc)
	ParticleManager:ReleaseParticleIndex(effectIndex)
	for _,unit in pairs(enemy) do
		local damage_table=
			{
				victim=unit,
				attacker=caster,
				damage          = ability:GetSpecialValueFor("damage"),
				damage_type     = ability:GetAbilityDamageType(),
				damage_flags    = ability:GetAbilityTargetFlags(),
				ability= ability
			}
		UtilStun:UnitStunTarget(caster,unit,stun_duration)
		UnitDamageTarget(damage_table)
	end

	local allies = FindUnitsInRadius(
				   caster:GetTeam(),		
				   targetLoc,		
				   nil,					
				   ability:GetSpecialValueFor("radius"),		
				   DOTA_UNIT_TARGET_TEAM_FRIENDLY,
				   DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
					DOTA_UNIT_TARGET_FLAG_NONE,
					FIND_ANY_ORDER,
					false
	)
	for _,unit in pairs(allies) do
		unit:AddNewModifier(caster,ability,"modifier_ability_thdots_yorihime_01_buff",{duration = heal_duration})
	end

	if target and not target:IsNull() then
		EmitSoundOn( "Hero_Sven.StormBoltImpact", target )
	end


end
--------------------------------------------------------------------------------
--视野buff
modifier_ability_thdots_yorihime_01_vision=class({})
LinkLuaModifier( "modifier_ability_thdots_yorihime_01_vision", "scripts/vscripts/abilities/abilityyorihime.lua",LUA_MODIFIER_MOTION_NONE )
function modifier_ability_thdots_yorihime_01_vision:IsHidden()		return true end
function modifier_ability_thdots_yorihime_01_vision:IsPurgable()	return false end
function modifier_ability_thdots_yorihime_01_vision:GetAttributes()	return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_ability_thdots_yorihime_01_vision:ShouldUseOverheadOffset() return true end -- I have no idea when this works but it might be particle-specific

function modifier_ability_thdots_yorihime_01_vision:OnCreated()
	if not IsServer() then return end
	self.caster = self:GetCaster()
	self.particle = ParticleManager:CreateParticleForTeam("particles/units/heroes/hero_spirit_breaker/spirit_breaker_charge_target.vpcf", 
		PATTACH_OVERHEAD_FOLLOW, self:GetParent(), self:GetCaster():GetTeamNumber())
	self:StartIntervalThink(0.03)
end

function modifier_ability_thdots_yorihime_01_vision:OnIntervalThink()
	if not IsServer() then return end
	if not self.caster:HasModifier("modifier_ability_thdots_yorihime_01_move") then
		self:Destroy()
	end
end

function modifier_ability_thdots_yorihime_01_vision:CheckState()
	return {[MODIFIER_STATE_PROVIDES_VISION] = true}
end


function modifier_ability_thdots_yorihime_01_move:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ORDER,
    }
    return funcs
end

function modifier_ability_thdots_yorihime_01_vision:OnDestroy()
	if not IsServer() then return end
	ParticleManager:DestroyParticleSystem(self.particle,true)
end

--------------------------------------------------------------------------------

modifier_ability_thdots_yorihime_01_buff=class({})
LinkLuaModifier( "modifier_ability_thdots_yorihime_01_buff", "scripts/vscripts/abilities/abilityyorihime.lua",LUA_MODIFIER_MOTION_NONE )
function modifier_ability_thdots_yorihime_01_buff:IsHidden()        return true end
function modifier_ability_thdots_yorihime_01_buff:IsPurgable()      return false end
function modifier_ability_thdots_yorihime_01_buff:RemoveOnDeath()   return true end
function modifier_ability_thdots_yorihime_01_buff:IsDebuff()        return false end

function modifier_ability_thdots_yorihime_01_buff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK
	}
	return funcs
end

function modifier_ability_thdots_yorihime_01_buff:CheckState()
	return {
		-- [MODIFIER_STATE_INVULNERABLE] = true,
		-- [MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_MAGIC_IMMUNE] = true,
	}
end

function modifier_ability_thdots_yorihime_01_buff:GetEffectName() --无敌
	return "particles/thd2/items/item_tsundere.vpcf"
end

function modifier_ability_thdots_yorihime_01_buff:OnCreated()
	if not IsServer() then return end
	local 	ability = self:GetAbility()
	local heal=ability:GetSpecialValueFor("buff_heal")
	self:GetParent():Heal(heal,caster)
	SendOverheadEventMessage(nil,OVERHEAD_ALERT_HEAL,self:GetParent(),heal,nil)
end

function modifier_ability_thdots_yorihime_01_buff:GetModifierTotal_ConstantBlock(kv)
    if not IsServer() then return end
    if bit.band(kv.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then return 0 end
    return kv.damage
end

---------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------
ability_thdots_yorihime_02 = class({})
LinkLuaModifier( "modifier_ability_thdots_yorihime_02", "scripts/vscripts/abilities/abilityyorihime.lua",LUA_MODIFIER_MOTION_NONE )


function ability_thdots_yorihime_02:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local duration = self:GetSpecialValueFor("02_duration")
	self.caster = caster
	self.target = target
	target:AddNewModifier(caster,self,"modifier_ability_thdots_yorihime_02",{duration = duration})
	EmitSoundOn("Hero_Treant.LivingArmor.Target", target)
	EmitSoundOn("Hero_Treant.LivingArmor.Cast", caster)
end

--------------------------------------------------------------------------------

modifier_ability_thdots_yorihime_02 = class ({})

function modifier_ability_thdots_yorihime_02:IsHidden() 		return false end
function modifier_ability_thdots_yorihime_02:IsPurgable()		return true end
function modifier_ability_thdots_yorihime_02:RemoveOnDeath() 	return true end
function modifier_ability_thdots_yorihime_02:IsDebuff()		return false end


function modifier_ability_thdots_yorihime_02:OnCreated()
	if not IsServer() then return end
	local ability = self:GetAbility()
	local caster = ability.caster
	local target = ability.target
	local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_treant/treant_livingarmor.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
	ParticleManager:SetParticleControlEnt( nFXIndex, 2, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_head", self:GetCaster():GetOrigin(), true )
	self:AddParticle( nFXIndex, false, false, -1, false, true )

	self.particle= ParticleManager:CreateParticle("particles/units/heroes/hero_treant/treant_livingarmor.vpcf", PATTACH_ROOTBONE_FOLLOW, target)
	ParticleManager:SetParticleControlEnt(self.particle, 0, target, PATTACH_ROOTBONE_FOLLOW, "follow_rootbone", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(self.particle, 1, target, PATTACH_ROOTBONE_FOLLOW, "follow_rootbone", target:GetAbsOrigin(), true)
end

function modifier_ability_thdots_yorihime_02:OnDestroy()
    if not IsServer() then return end
    local ability=self:GetAbility()


    ParticleManager:DestroyParticle(self.particle,true) 
    
end



function modifier_ability_thdots_yorihime_02:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
	return funcs
end


function modifier_ability_thdots_yorihime_02:GetModifierMagicalResistanceBonus() 
	return self:GetAbility():GetSpecialValueFor( "02_magical" ) 
end



function modifier_ability_thdots_yorihime_02:GetModifierPhysicalArmorBonus(keys)
	local bonus = 0
	local ability = self:GetCaster():FindAbilityByName("special_bonus_unique_yorihime_2")
	if ability:GetLevel()~=0 then
		bonus = ability:GetSpecialValueFor("value")
	end
	return self:GetAbility():GetSpecialValueFor( "02_armor" ) + bonus
end


function modifier_ability_thdots_yorihime_02:GetModifierConstantManaRegen() 
	return self:GetAbility():GetSpecialValueFor( "02_manaregen" ) 
end


function modifier_ability_thdots_yorihime_02:GetModifierConstantHealthRegen() 
	return self:GetAbility():GetSpecialValueFor( "02_healregen" ) 
end



---------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------

ability_thdots_yorihime_03 = class({})

function ability_thdots_yorihime_03:GetCooldown(level)
	if self:GetCaster():HasModifier("ability_thdots_yorihime_talent_1") then
		return self.BaseClass.GetCooldown(self, level) - 6
	else
		return self.BaseClass.GetCooldown(self, level)
	end
end

function ability_thdots_yorihime_03:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	self.caster 	= caster
	self.target 	= target
	local duration = self:GetSpecialValueFor("shield_duration")
	target:EmitSound("Hero_Sven.WarCry")
	-- local MaxHealth = self:GetSpecialValueFor("shield_health")
	local MaxHealth = self:GetSpecialValueFor("shield_health")
	local strength = self.caster:GetStrength() * FindTelentValue(caster,"special_bonus_unique_yorihime_3")
	local shield_remaining = MaxHealth + strength
	-- self.shield_remaining = MaxHealth
	if target:HasModifier("modifier_ability_thdots_yorihime_02_shield_buff") then
		target:RemoveModifierByName("modifier_ability_thdots_yorihime_02_shield_buff")
	end
	target:AddNewModifier(caster,self,"modifier_ability_thdots_yorihime_02_shield_buff",{duration = duration ,shield_remaining = shield_remaining})
end

--------------------------------------------------------------------------------

modifier_ability_thdots_yorihime_02_shield_buff=class({})

LinkLuaModifier("modifier_ability_thdots_yorihime_02_shield_buff", "scripts/vscripts/abilities/abilityyorihime.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_ability_thdots_yorihime_02_shield_buff:IsHidden()        return false end
function modifier_ability_thdots_yorihime_02_shield_buff:IsPurgable()      return true end
function modifier_ability_thdots_yorihime_02_shield_buff:RemoveOnDeath()   return true end
function modifier_ability_thdots_yorihime_02_shield_buff:IsDebuff()        return false end

function modifier_ability_thdots_yorihime_02_shield_buff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
	}
	return funcs
end
function modifier_ability_thdots_yorihime_02_shield_buff:OnCreated(keys)
    if not IsServer() then return end
    local ability=self:GetAbility()
    local caster = ability.caster
    local target = ability.target
	self.shield_remaining=keys.shield_remaining
	self:SetStackCount(self.shield_remaining)
    self.particle= ParticleManager:CreateParticle("particles/econ/items/ember_spirit/ember_ti9/ember_ti9_flameguard_shield_outer.vpcf", PATTACH_ROOTBONE_FOLLOW, target)
	ParticleManager:SetParticleControlEnt(self.particle, 0, target, PATTACH_ROOTBONE_FOLLOW, "follow_rootbone", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(self.particle, 1, target, PATTACH_ROOTBONE_FOLLOW, "follow_rootbone", target:GetAbsOrigin(), true)


end

function modifier_ability_thdots_yorihime_02_shield_buff:OnDestroy()
    if not IsServer() then return end
    local ability=self:GetAbility()
	ParticleManager:DestroyParticle(self.particle,true) 

	
end

function modifier_ability_thdots_yorihime_02_shield_buff:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor( "buff_damage" )
end

function modifier_ability_thdots_yorihime_02_shield_buff:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor( "buff_movespeed" )
end
function modifier_ability_thdots_yorihime_02_shield_buff:GetModifierIncomingDamageConstant()
	if IsClient() then
		return self:GetStackCount()
	end
end
function modifier_ability_thdots_yorihime_02_shield_buff:GetModifierTotal_ConstantBlock(kv)
	if not IsServer() then return end
	if bit.band(kv.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then return 0 end
	
	if kv.damage < self.shield_remaining then 
		self.shield_remaining = self.shield_remaining-kv.damage
		self:SetStackCount(self.shield_remaining)
		-- print("kv.damage: ", kv.damage )
		-- print("shield_remaining: ", self.shield_remaining)
		return kv.damage
	else
		self:Destroy()
		return self.shield_remaining
	end

end


---------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------


ability_thdots_yorihime_Ex = class ({})

function ability_thdots_yorihime_Ex:IsHiddenWhenStolen() 		return false end
function ability_thdots_yorihime_Ex:IsRefreshable() 			return true end
function ability_thdots_yorihime_Ex:IsStealable() 			return false end

function ability_thdots_yorihime_Ex:GetIntrinsicModifierName()
    return "modifier_thdots_yorihime_ex"
end

function ability_thdots_yorihime_Ex:OnHeroLevelUp()
	local lvl=math.floor(1+(self:GetCaster():GetLevel()-1)/5)
	if lvl ~= self:GetLevel() and lvl< 7 then
		self:SetLevel(lvl)
	end
end

--------------------------------------------------------------------------------


modifier_thdots_yorihime_ex = class({})

LinkLuaModifier("modifier_thdots_yorihime_ex", "scripts/vscripts/abilities/abilityyorihime.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_yorihime_ex:IsHidden()         return false end
function modifier_thdots_yorihime_ex:IsPurgable()       return false end
function modifier_thdots_yorihime_ex:RemoveOnDeath()    return true end
function modifier_thdots_yorihime_ex:IsDebuff()     return false end

function modifier_thdots_yorihime_ex:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		-- MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
	return funcs
end

function modifier_thdots_yorihime_ex:OnCreated()
	if not IsServer() then return end

	self:StartIntervalThink(0.1)
end

function modifier_thdots_yorihime_ex:OnIntervalThink()
	if not IsServer() then return end
	local caster 		= self:GetParent()
	local ability = self:GetAbility()
	self.radius	= self:GetAbility():GetSpecialValueFor("ex_radius") + FindTelentValue(self:GetParent(),"special_bonus_unique_yorihime_7")
	local allies = FindUnitsInRadius(
					self:GetParent():GetTeam(),		
					self:GetParent():GetOrigin(),		
				   nil,					
				   self.radius,		
				   DOTA_UNIT_TARGET_TEAM_FRIENDLY,
				   DOTA_UNIT_TARGET_HERO,
				   0, FIND_CLOSEST,
				   false
	)
	local count = 0
	for k,v in pairs(allies) do
		if v:IsRealHero() then
			count = count + 1
		end
	end
	self:GetParent():SetModifierStackCount("modifier_thdots_yorihime_ex", self:GetAbility(), count)
	if self:GetAbility():IsCooldownReady() then

		self:GetParent():AddNewModifier(self:GetCaster(),self:GetAbility(),"modifier_thdots_yorihime_ex_crit",{duration = -1})
	end
	if FindTelentValue(self:GetCaster(),"special_bonus_unique_yorihime_1") ~= 0 and not self:GetCaster():HasModifier("ability_thdots_yorihime_talent_1") then
		self:GetCaster():AddNewModifier(self:GetCaster(),self:GetAbility(),"ability_thdots_yorihime_talent_1",{})
	end
end

function modifier_thdots_yorihime_ex:OnAttackLanded(keys)
	if not IsServer() then return end
	if keys.attacker ~= self:GetParent() then return end
	if self:GetParent():HasModifier("modifier_thdots_yorihime_ex_crit") then
		local d = self:GetAbility():GetSpecialValueFor("duration")
		--local p = self:GetAbility():GetSpecialValueFor("attack_mult")
		--local r = self:GetAbility():GetSpecialValueFor("cleave_radius")
		--local damage = keys.damage * p / 100
		self:GetParent():RemoveModifierByName("modifier_thdots_yorihime_ex_crit")
		--DoCleaveAttack(self:GetParent(),keys.target,keys.ability,damage,r,r,r,"particles/units/heroes/hero_sven/sven_spell_great_cleave.vpcf")
		self:GetAbility():StartCooldown(self:GetAbility():GetCooldown(self:GetAbility():GetLevel() - 1))
		keys.target:AddNewModifier(self:GetParent(),self:GetAbility(),"modifier_thdots_yorihime_ex_debuff",{duration = d})
	end
	self:GetParent():RemoveModifierByName("modifier_thdots_yorihime_ex_crit")
end

modifier_thdots_yorihime_ex_crit = class({})

LinkLuaModifier("modifier_thdots_yorihime_ex_crit", "scripts/vscripts/abilities/abilityyorihime.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_yorihime_ex_crit:IsHidden()         return true end
function modifier_thdots_yorihime_ex_crit:IsPurgable()       return false end
function modifier_thdots_yorihime_ex_crit:RemoveOnDeath()    return true end
function modifier_thdots_yorihime_ex_crit:IsDebuff()     return false end

function modifier_thdots_yorihime_ex_crit:OnCreated()
	if not IsServer() then return end
end
function modifier_thdots_yorihime_ex_crit:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE
	}
end

function modifier_thdots_yorihime_ex_crit:GetModifierDamageOutgoing_Percentage()
	local percent = self:GetAbility():GetSpecialValueFor("attack_mult") 
	return percent
end

modifier_thdots_yorihime_ex_debuff = class({})

LinkLuaModifier("modifier_thdots_yorihime_ex_debuff", "scripts/vscripts/abilities/abilityyorihime.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_thdots_yorihime_ex_debuff:IsHidden()         return true end
function modifier_thdots_yorihime_ex_debuff:IsPurgable()       return true end
function modifier_thdots_yorihime_ex_debuff:RemoveOnDeath()    return true end
function modifier_thdots_yorihime_ex_debuff:IsDebuff()     return true end

function modifier_thdots_yorihime_ex_debuff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	}
	return funcs
end

function modifier_thdots_yorihime_ex_debuff:GetModifierMoveSpeedBonus_Percentage()
	return -100
end

ability_thdots_yorihime_talent_1 = ability_thdots_yorihime_talent_1 or {}  --天赋监听
LinkLuaModifier("ability_thdots_yorihime_talent_1","scripts/vscripts/abilities/abilityyorihime.lua",LUA_MODIFIER_MOTION_NONE)
function ability_thdots_yorihime_talent_1:IsHidden() 		return true end
function ability_thdots_yorihime_talent_1:IsPurgable()		return false end
function ability_thdots_yorihime_talent_1:RemoveOnDeath() 	return false end
function ability_thdots_yorihime_talent_1:IsDebuff()		return false end



function modifier_thdots_yorihime_ex:GetModifierMagicalResistanceBonus() 
	return self:GetAbility():GetSpecialValueFor( "ex_magical" ) * self:GetStackCount()
end




function modifier_thdots_yorihime_ex:GetModifierPhysicalArmorBonus() 
	return self:GetAbility():GetSpecialValueFor( "ex_armor" ) * self:GetStackCount()
end


-- function modifier_thdots_yorihime_ex:GetModifierConstantManaRegen() 
-- 	return self:GetAbility():GetSpecialValueFor( "ex_manaregen" ) * self:GetStackCount()
-- end


function modifier_thdots_yorihime_ex:GetModifierConstantHealthRegen() 
	return self:GetAbility():GetSpecialValueFor( "ex_healthregen" ) * self:GetStackCount()
end





ability_thdots_yorihime_ultimate = class({})
LinkLuaModifier("modifier_thdots_yorihime_ultimate", "scripts/vscripts/abilities/abilityyorihime.lua", LUA_MODIFIER_MOTION_NONE)



---------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------


function ability_thdots_yorihime_ultimate:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local ultimate_duration = self:GetSpecialValueFor( "ultimate_duration" ) + FindTelentValue(caster,"special_bonus_unique_yorihime_6")
	print(ultimate_duration)
	-- local ultimate_duration = self:GetSpecialValueFor( "ultimate_duration" )
	
	-- print(ultimate_duration)
	self:GetCaster():AddNewModifier( self:GetCaster(), self, "modifier_thdots_yorihime_ultimate", { duration = ultimate_duration }  )

	local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_sven/sven_spell_gods_strength.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
	ParticleManager:SetParticleControlEnt( nFXIndex, 1, self:GetCaster(), PATTACH_ABSORIGIN_FOLLOW, nil, self:GetCaster():GetOrigin(), true )
	ParticleManager:ReleaseParticleIndex( nFXIndex )

	-- self.particle = ParticleManager:CreateParticleForTeam("particles/econ/items/sven/sven_warcry_ti5/sven_spell_warcry_ti_5.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent(), self:GetCaster():GetTeamNumber())
	-- self:AddParticle(self.particle, false, false, -1, false, true)

	-- EmitSoundOn("Hero_Sven.GodsStrength",caster)


	EmitSoundOn("Hero_Earthshaker.Arcana.GlobalLayer2",caster)
	local allies = FindUnitsInRadius(
		caster:GetTeam(),		
		caster:GetOrigin(),		
				   nil,					
				   self:GetSpecialValueFor("ult_radius")  + FindTelentValue(caster,"special_bonus_unique_yorihime_7"),		
				   DOTA_UNIT_TARGET_TEAM_FRIENDLY,
				   DOTA_UNIT_TARGET_HERO,
				   0, FIND_CLOSEST,
				   false
	)
	for k,v in pairs(allies) do
		if v:HasModifier("modifier_illusion")==false then
			local ability2 = caster:FindAbilityByName("ability_thdots_yorihime_02")
			local ability3 = caster:FindAbilityByName("ability_thdots_yorihime_03")
			ability3.target = v;
			ability3.caster = caster
			local duration = ability3:GetSpecialValueFor("shield_duration")
			local MaxHealth = ability3:GetSpecialValueFor("shield_health")
			local strength = caster:GetStrength() * FindTelentValue(caster,"special_bonus_unique_yorihime_3")
			local shield_remaining = MaxHealth + strength
			if v:HasModifier("modifier_ability_thdots_yorihime_02_shield_buff") then
				v:RemoveModifierByName("modifier_ability_thdots_yorihime_02_shield_buff")
			end
			v:AddNewModifier(caster,ability3,"modifier_ability_thdots_yorihime_02_shield_buff",{duration = duration ,shield_remaining = shield_remaining})
			--v:FindModifierByName("modifier_ability_thdots_yorihime_02_shield_buff").shield_remaining = shield_remaining
			local target = v
			local duration = ability2:GetSpecialValueFor("02_duration")
			ability2.caster = caster
			ability2.target = v
			target:AddNewModifier(caster,ability2,"modifier_ability_thdots_yorihime_02",{duration = duration })
		end
	end
end

--------------------------------------------------------------------------------

modifier_thdots_yorihime_ultimate = class({})

function modifier_thdots_yorihime_ultimate:IsHidden()        return false end
function modifier_thdots_yorihime_ultimate:IsPurgable()      return false end
function modifier_thdots_yorihime_ultimate:RemoveOnDeath()   return true end
function modifier_thdots_yorihime_ultimate:IsDebuff()        return false end


function modifier_thdots_yorihime_ultimate:GetStatusEffectName()
	return "particles/status_fx/status_effect_gods_strength.vpcf"
end



function modifier_thdots_yorihime_ultimate:GetHeroEffectName()
	return "particles/units/heroes/hero_sven/sven_gods_strength_hero_effect.vpcf"
end



function modifier_thdots_yorihime_ultimate:OnCreated( kv )
	self.gods_strength_damage = self:GetAbility():GetSpecialValueFor( "gods_strength_damage" )
	-- self.caster 		= self:GetParent()
	if not IsServer() then return end
	local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_sven/sven_spell_gods_strength_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
		ParticleManager:SetParticleControlEnt( nFXIndex, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_weapon" , self:GetParent():GetOrigin(), true )
		ParticleManager:SetParticleControlEnt( nFXIndex, 2, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_head" , self:GetParent():GetOrigin(), true )
		self:AddParticle( nFXIndex, false, false, -1, false, true )
		self:StartIntervalThink(0.1)
	
		self.particle_foot= ParticleManager:CreateParticle("particles/econ/items/sven/sven_warcry_ti5/sven_spell_warcry_ti_5.vpcf", PATTACH_ROOTBONE_FOLLOW, self:GetParent())
		ParticleManager:SetParticleControlEnt(self.particle_foot, 0, self:GetParent(), PATTACH_ROOTBONE_FOLLOW, "follow_rootbone", self:GetParent():GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(self.particle_foot, 1, self:GetParent(), PATTACH_ROOTBONE_FOLLOW, "follow_rootbone", self:GetParent():GetAbsOrigin(), true)


	end



function modifier_thdots_yorihime_ultimate:OnIntervalThink()
	if not IsServer() then return end
	local caster 		= self:GetParent()
	local ability = self:GetAbility()
	self.radius 		= self:GetAbility():GetSpecialValueFor("ult_radius")  + FindTelentValue(self:GetParent(),"special_bonus_unique_yorihime_7")
	local allies = FindUnitsInRadius(
					self:GetParent():GetTeam(),		
					self:GetParent():GetOrigin(),		
				   nil,					
				   self.radius,		
				   DOTA_UNIT_TARGET_TEAM_FRIENDLY,
				   DOTA_UNIT_TARGET_HERO,
				   0, FIND_CLOSEST,
				   false
	)
	local count = 0
	for k,v in pairs(allies) do
		if v:HasModifier("modifier_illusion")==false then
			count = count + 1
		end
	end
	self:GetParent():SetModifierStackCount("modifier_thdots_yorihime_ultimate", self:GetAbility(), count)
end


function modifier_thdots_yorihime_ultimate:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
	}

	return funcs
end

--------------------------------------------------------------------------------

function modifier_thdots_yorihime_ultimate:GetModifierBaseDamageOutgoing_Percentage()
	return self.gods_strength_damage * self:GetStackCount()
end

function modifier_thdots_yorihime_ultimate:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor( "ult_strength" ) * self:GetStackCount()
end



ability_thdots_yorihime_ultimateEX = class({})

LinkLuaModifier("modifier_thdots_yorihime_ultimateEX", "scripts/vscripts/abilities/abilityyorihime.lua", LUA_MODIFIER_MOTION_NONE)

function ability_thdots_yorihime_ultimateEX:OnInventoryContentsChanged()
	if not IsServer() then return end
		if self:GetCaster():HasModifier("modifier_item_wanbaochui") then
			self:SetHidden(false)
		else
			self:SetHidden(true)
		end
end

function ability_thdots_yorihime_ultimateEX:OnHeroCalculateStatBonus()
	self:OnInventoryContentsChanged()
end

function ability_thdots_yorihime_ultimateEX:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	self.caster 	= caster
	self.target 	= target
	local duration = self:GetSpecialValueFor( "ultimateEX_duration" )
	EmitSoundOn("Hero_Earthshaker.Arcana.GlobalLayer1",caster)
	target:AddNewModifier( caster, self, "modifier_thdots_yorihime_ultimateEX", { duration = duration }  )
end
--------------------------------------------------------------------------------
modifier_thdots_yorihime_ultimateEX = class({})

function modifier_thdots_yorihime_ultimateEX:IsHidden()        return false end
function modifier_thdots_yorihime_ultimateEX:IsPurgable()      return false end
function modifier_thdots_yorihime_ultimateEX:RemoveOnDeath()   return true end
function modifier_thdots_yorihime_ultimateEX:IsDebuff()        return false end


function modifier_thdots_yorihime_ultimateEX:GetStatusEffectName()
	return "particles/status_fx/status_effect_gods_strength.vpcf"
end



function modifier_thdots_yorihime_ultimateEX:GetHeroEffectName()
	return "particles/units/heroes/hero_sven/sven_gods_strength_hero_effect.vpcf"
end



function modifier_thdots_yorihime_ultimateEX:OnCreated( kv )
	self.gods_strength_damage = self:GetAbility():GetSpecialValueFor( "gods_strengthEX_damage" )
	-- self.caster 		= self:GetParent()
	if not IsServer() then return end
	local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_sven/sven_spell_gods_strength_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
	ParticleManager:SetParticleControlEnt( nFXIndex, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_weapon" , self:GetParent():GetOrigin(), true )
	ParticleManager:SetParticleControlEnt( nFXIndex, 2, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_head" , self:GetParent():GetOrigin(), true )
	self:AddParticle( nFXIndex, false, false, -1, false, true )
	self:StartIntervalThink(0.1)

	self.particle_foot= ParticleManager:CreateParticle("particles/econ/items/sven/sven_warcry_ti5/sven_spell_warcry_ti_5.vpcf", PATTACH_ROOTBONE_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControlEnt(self.particle_foot, 0, self:GetParent(), PATTACH_ROOTBONE_FOLLOW, "follow_rootbone", self:GetParent():GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(self.particle_foot, 1, self:GetParent(), PATTACH_ROOTBONE_FOLLOW, "follow_rootbone", self:GetParent():GetAbsOrigin(), true)
end

function modifier_thdots_yorihime_ultimateEX:OnRefresh()
	if not IsServer() then return end
	self:OnCreated()
end
function modifier_thdots_yorihime_ultimateEX:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
	}

	return funcs
end

function modifier_thdots_yorihime_ultimateEX:GetModifierBaseDamageOutgoing_Percentage()
	return self.gods_strength_damage 
end

function modifier_thdots_yorihime_ultimateEX:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor( "ult_strengthEX" )
end