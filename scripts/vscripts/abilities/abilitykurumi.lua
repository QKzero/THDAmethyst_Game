

ability_thdots_kurumiEx = {}
function ability_thdots_kurumiEx:GetIntrinsicModifierName() return "modifier_thdots_kurumiEx_passive" end

modifier_thdots_kurumiEx_passive={}
LinkLuaModifier("modifier_thdots_kurumiEx_passive","scripts/vscripts/abilities/abilitykurumi.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_thdots_kurumiEx_passive:IsHidden() 		return true end
function modifier_thdots_kurumiEx_passive:IsPurgable()		return false end
function modifier_thdots_kurumiEx_passive:RemoveOnDeath() 	return false end
function modifier_thdots_kurumiEx_passive:IsDebuff()		return false end
function modifier_thdots_kurumiEx_passive:AllowIllusionDuplicate() return true end

function modifier_thdots_kurumiEx_passive:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACKED,
	}
end

function modifier_thdots_kurumiEx_passive:OnAttacked(keys)
	if not IsServer() then return end
	if self:GetParent():PassivesDisabled() then return end
	local attacker = keys.attacker
	local target = keys.target
	if attacker ~= self:GetParent() 
		or attacker:GetTeam() == target:GetTeam()
		or target:IsBuilding()
		or target:IsIllusion()
	then 
		return 
	end
	local lifesteal_constant = self:GetAbility():GetSpecialValueFor("lifesteal_constant")
	local level_multiple = self:GetAbility():GetSpecialValueFor("level_multiple") * attacker:GetLevel()

	local lifesteal = lifesteal_constant + level_multiple

	attacker:Heal(lifesteal, attacker)

	local particle = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
	ParticleManager:SetParticleControl(particle, 0, Vector(attacker:GetAbsOrigin().x, attacker:GetAbsOrigin().y, attacker:GetAbsOrigin().z))

end


---------------------------------------------------------------------
-------------------------	Blink Strike	-------------------------
---------------------------------------------------------------------
-- Visible Modifiers:
ability_thdots_kurumi01 = {}

function ability_thdots_kurumi01:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

function ability_thdots_kurumi01:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_1
end

function ability_thdots_kurumi01:OnSpellStart()
	if not IsServer() then return end
	local caster 				= self:GetCaster()
	local target 				= self:GetCursorTarget()

	if target:GetName() ~= "" and target:TriggerSpellAbsorb(self) then caster:EmitSoundParams("Hero_Grimstroke.DarkArtistry.Cast.Layer", 0, 3, 0) return end

	local velocity = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized() * 4800

	local info = {
		Ability				= self,
		EffectName			= "particles/econ/items/grimstroke/ti9_immortal/gs_ti9_artistry_proj.vpcf",
		vSpawnOrigin		= caster:GetAbsOrigin(),
		fDistance			= math.max((target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D(), 300),
		fStartRadius		= 120,
		fEndRadius			= 0,
		Source				= self:GetCaster(),
		bHasFrontalCone		= false,
		bReplaceExisting	= false,
		iUnitTargetTeam		= DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags	= DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType		= DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		fExpireTime 		= GameRules:GetGameTime() + 10.0,
		bDeleteOnHit		= false,
		vVelocity			= Vector(velocity.x, velocity.y, 0),
		bProvidesVision		= true,
		iVisionRadius 		= 0,
		iVisionTeamNumber 	= self:GetCaster():GetTeamNumber()
		
		-- ExtraData			= 
		-- {
		-- 	stroke_dummy	= stroke_dummy:entindex(),
		-- 	bPrimary		= bPrimary,
		-- 	bMain			= bMain
		-- }
	}
	
	local projectile = ProjectileManager:CreateLinearProjectile(info)

	--特效音效
	-- local blink_start_pfx = ParticleManager:CreateParticle("particles/econ/items/riki/riki_immortal_ti6/riki_immortal_ti6_blinkstrike_gold.vpcf", PATTACH_ABSORIGIN,caster)
	
	StartSoundEventFromPosition("Hero_Grimstroke.DarkArtistry.Projectile", caster:GetOrigin())
	FindClearSpaceForUnit(caster,target:GetAbsOrigin(),true)
	caster:EmitSound("Hero_Grimstroke.InkOver.Target")


	local ability = self
	local dmg = ability:GetAbilityDamage() + (caster:GetAverageTrueAttackDamage(caster) * ability:GetSpecialValueFor("attack_multiple"))
	local damage_table = {
				ability = ability,
			    victim = target,
			    attacker = caster,
			    damage = dmg ,
			    damage_type = ability:GetAbilityDamageType(), 
		}
	UnitDamageTarget(damage_table)	
	caster:MoveToTargetToAttack(target)

	-- caster:PerformAttack(target, true, true, true, true, false, false, false)
end


--------------------------
--  
--------------------------
ability_thdots_kurumi02 = {}

function ability_thdots_kurumi02:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function ability_thdots_kurumi02:GetAssociatedSecondaryAbilities()
	return "ability_thdots_kurumi02_out"
end

function ability_thdots_kurumi02:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_2
end

function ability_thdots_kurumi02:OnUpgrade()
	local out_ability = self:GetCaster():FindAbilityByName("ability_thdots_kurumi02_out")
	
	if out_ability and out_ability:GetLevel() ~= self:GetLevel() then
		out_ability:SetLevel(self:GetLevel())
	end
end

function ability_thdots_kurumi02:IsStealable()
    return true
end

function ability_thdots_kurumi02:IsHiddenWhenStolen()
    return false
end

function ability_thdots_kurumi02:OnSpellStart()
	local caster = self:GetCaster()
	local cast_time = self:GetSpecialValueFor("cast_time")

	caster:AddNewModifier(caster, self, "modifier_thdots_kurumi02_hiding", {duration = cast_time})

end

modifier_thdots_kurumi02_hiding = {}
LinkLuaModifier( "modifier_thdots_kurumi02_hiding", "scripts/vscripts/abilities/abilitykurumi.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_thdots_kurumi02_hiding:IsHidden() return true end
function modifier_thdots_kurumi02_hiding:IsPurgable() return false end
function modifier_thdots_kurumi02_hiding:RemoveOnDeath() return true end
function modifier_thdots_kurumi02_hiding:IsDebuff() return false end
function modifier_thdots_kurumi02_hiding:GetEffectName()	--魔法阵特效
	return "particles/heroes/flandre/ability_flandre_04_aura.vpcf"
end
function modifier_thdots_kurumi02_hiding:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_thdots_kurumi02_hiding:CheckState()
	return
	{
		[MODIFIER_STATE_INVULNERABLE]		= true,
		[MODIFIER_STATE_COMMAND_RESTRICTED]	= true,
	}
end

function modifier_thdots_kurumi02_hiding:OnCreated()
	if not IsServer() then return end
	local ability = self:GetAbility()
	local caster = ability:GetCaster()

	EmitSoundOn("Hero_Bloodseeker.BloodRite.Cast", caster)
end

function modifier_thdots_kurumi02_hiding:OnRemoved()
	if not IsServer() then return end
	local ability = self:GetAbility()
	local caster = ability:GetCaster()

	--ProjectileManager:ProjectileDodge(caster)

	--棺材
	local coffin = CreateUnitByName("npc_thdots_unit_kurumi02_coffin", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
	coffin:SetControllableByPlayer(caster:GetPlayerID(),false)
	local duration = ability:GetSpecialValueFor("coffin_duration")

	local hp = ability:GetSpecialValueFor("coffin_hp")

	local armor = ability:GetSpecialValueFor("coffin_armor")
	local magic_resist = ability:GetSpecialValueFor("coffin_magic_resist")

	local bonus_armor = caster:GetPhysicalArmorValue(false)*ability:GetSpecialValueFor("armor_pct")/100
	local bonus_magic_resist = caster:Script_GetMagicalArmorValue(false, nil)*ability:GetSpecialValueFor("magic_resist_pct") -- Script_GetMagicalArmorValue获取到纯小数

	--属性设定
	coffin:SetBaseMaxHealth(hp)
	coffin:SetMaxHealth(hp)
	coffin:SetHealth(hp)
	coffin:SetPhysicalArmorBaseValue(armor)
	coffin:SetBaseMagicalResistanceValue(magic_resist)

    -- 天赋树 移动速度
    coffin:SetBaseMoveSpeed(ability:GetSpecialValueFor("coffin_movespeed"))

	local modifier_thdots_kurumi02_coffin = coffin:AddNewModifier(caster, ability, "modifier_thdots_kurumi02_coffin", {Duration = duration,
	bonus_magic_resist = bonus_magic_resist, bonus_armor = bonus_armor})
	local modifier_thdots_kurumi02_caster = caster:AddNewModifier(caster, ability, "modifier_thdots_kurumi02_caster", {Duration = duration})

    EmitSoundOn("Hero_Boodseeker.Bloodmist", coffin)

	if modifier_thdots_kurumi02_caster and modifier_thdots_kurumi02_coffin then
		modifier_thdots_kurumi02_caster.modifier_thdots_kurumi02_coffin	= modifier_thdots_kurumi02_coffin
		modifier_thdots_kurumi02_coffin.modifier_thdots_kurumi02_caster	= modifier_thdots_kurumi02_caster
	end

	--隐藏技能
	ability.HiddenAbility = {}

	for spell_id = 0, caster:GetAbilityCount()-1 do
		local tAbility = caster:GetAbilityByIndex(spell_id)
		if tAbility ~= nil and not tAbility:IsHidden() then
			if tAbility ~= ability then
				tAbility:SetHidden(true)
				table.insert(ability.HiddenAbility, tAbility)
			end
		end
	end

	--替换技能
	local out_ability = caster:FindAbilityByName("ability_thdots_kurumi02_out")

	if out_ability then
		caster:SwapAbilities(ability:GetName(), out_ability:GetName(), false, true)
	end

	local caster_modifier = caster:FindModifierByNameAndCaster("modifier_thdots_kurumi02_caster", caster)

	--为棺材添加技能
	local out_ability = coffin:AddAbility("ability_thdots_kurumi02_out")

	if out_ability then
		if caster_modifier:GetAbility() then
			out_ability:SetLevel(caster_modifier:GetAbility():GetLevel())
		else
			out_ability:SetLevel(1)
		end
		out_ability:SetHidden(false)
		out_ability:SetActivated(true)
	end

	--切换选择为棺材
	if coffin and caster:GetTeamNumber() == coffin:GetTeamNumber() then
		PlayerResource:NewSelection(caster:GetPlayerID(), coffin)
	end

end

modifier_thdots_kurumi02_caster = {}
LinkLuaModifier( "modifier_thdots_kurumi02_caster", "scripts/vscripts/abilities/abilitykurumi.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_thdots_kurumi02_caster:IsHidden() return false end
function modifier_thdots_kurumi02_caster:IsPurgable() return false end
function modifier_thdots_kurumi02_caster:RemoveOnDeath() return false end
function modifier_thdots_kurumi02_caster:IsDebuff() return false end

function modifier_thdots_kurumi02_caster:OnCreated()
	if IsServer() then
		self:GetParent():AddNoDraw()
		self:StartIntervalThink(0.1)
	end
end

function modifier_thdots_kurumi02_caster:OnIntervalThink()
	if not IsServer() then return end
	self:GetParent():SetAbsOrigin(self.modifier_thdots_kurumi02_coffin:GetParent():GetAbsOrigin())
end

function modifier_thdots_kurumi02_caster:OnRemoved()
	if IsServer() then
		--替换技能
		local ability = self:GetAbility()
		local out_ability = self:GetCaster():FindAbilityByName("ability_thdots_kurumi02_out")
		
		if out_ability and self:GetAbility() then
			self:GetCaster():SwapAbilities(self:GetAbility():GetName(), out_ability:GetName(), true, false)
		end

		for i=1,#ability.HiddenAbility do
			if ability.HiddenAbility[i]:IsHidden() then
				ability.HiddenAbility[i]:SetHidden(false)
			end
		end

		self:GetParent():RemoveNoDraw()
		self:GetParent():StartGesture(ACT_DOTA_INTRO)
		FindClearSpaceForUnit(self:GetParent(), self:GetParent():GetAbsOrigin(), false)

		--切换回施法者
		PlayerResource:NewSelection(self:GetCaster():GetPlayerID(), self:GetCaster())
		self:GetCaster():StartGesture(ACT_DOTA_CAST_ABILITY_2_END)
	end
end

function modifier_thdots_kurumi02_caster:CheckState()
	if not IsServer() then return end
	local coffin = self.modifier_thdots_kurumi02_coffin and self.modifier_thdots_kurumi02_coffin:GetParent()
	return {
		[MODIFIER_STATE_NO_UNIT_COLLISION]			= true,
		[MODIFIER_STATE_INVULNERABLE]				= true,
		[MODIFIER_STATE_NO_HEALTH_BAR]				= true,
		[MODIFIER_STATE_UNTARGETABLE]				= true,
		[MODIFIER_STATE_UNSELECTABLE]				= true,
		[MODIFIER_STATE_OUT_OF_GAME]				= true,
		[MODIFIER_STATE_DISARMED]					= true,
		[MODIFIER_STATE_COMMAND_RESTRICTED]			= true,
		[MODIFIER_STATE_ROOTED]						= true,

		[MODIFIER_STATE_STUNNED]					= coffin and coffin:IsStunned() or false,
		[MODIFIER_STATE_HEXED]						= coffin and coffin:IsHexed() or false,
		[MODIFIER_STATE_SILENCED]					= coffin and coffin:IsSilenced() or false,
	}
end

modifier_thdots_kurumi02_coffin = {}
LinkLuaModifier( "modifier_thdots_kurumi02_coffin", "scripts/vscripts/abilities/abilitykurumi.lua", LUA_MODIFIER_MOTION_NONE )
function modifier_thdots_kurumi02_coffin:IsHidden() 		return false end
function modifier_thdots_kurumi02_coffin:IsPurgable()		return false end
function modifier_thdots_kurumi02_coffin:RemoveOnDeath() 	return true end
function modifier_thdots_kurumi02_coffin:IsDebuff()			return false end
function modifier_thdots_kurumi02_coffin:GetEffectName()	--魔法阵特效
	return "particles/heroes/flandre/ability_flandre_04_aura.vpcf"
end
function modifier_thdots_kurumi02_coffin:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_thdots_kurumi02_coffin:IsAura()				return true end
function modifier_thdots_kurumi02_coffin:GetAuraRadius()		return self:GetAbility():GetSpecialValueFor("radius") end
function modifier_thdots_kurumi02_coffin:GetAuraSearchTeam()	return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_thdots_kurumi02_coffin:GetAuraSearchType()	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_thdots_kurumi02_coffin:GetModifierAura()		return "modifier_thdots_kurumi02_area_debuff" end

function modifier_thdots_kurumi02_coffin:CheckState()
	local movespeed = self:GetAbility():GetSpecialValueFor("coffin_movespeed")
	return
	{
		[MODIFIER_STATE_COMMAND_RESTRICTED]	= movespeed == 0,
		[MODIFIER_STATE_ROOTED]				= movespeed == 0,
	}
end

function modifier_thdots_kurumi02_coffin:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_DISABLE_HEALING,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
end

function modifier_thdots_kurumi02_coffin:GetDisableHealing()
	return 1
end

function modifier_thdots_kurumi02_coffin:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end

function modifier_thdots_kurumi02_coffin:GetModifierMagicalResistanceBonus()
	return self.bonus_magic_resist
end

-- 传服务端数据
function modifier_thdots_kurumi02_coffin:AddCustomTransmitterData()
	return {
		bonus_armor = self.bonus_armor,
		bonus_magic_resist = self.bonus_magic_resist,
	}
end
-- 接受数据
function modifier_thdots_kurumi02_coffin:HandleCustomTransmitterData( data )
	self.bonus_armor = data.bonus_armor
	self.bonus_magic_resist = data.bonus_magic_resist
end

function modifier_thdots_kurumi02_coffin:OnCreated(keys)
	if IsServer() then
		self.bonus_armor = keys.bonus_armor
		self.bonus_magic_resist = keys.bonus_magic_resist

		self:SetHasCustomTransmitterData(true)

		--血之湖光环特效
		local coffin = self:GetParent()
		local radius = self:GetAbility():GetSpecialValueFor("radius")
		self.effectIndex = ParticleManager:CreateParticle(
		"particles/heroes/kurumi/kurumi_02_lake_of_blood_aoe.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		coffin)
		ParticleManager:SetParticleControl(self.effectIndex, 0, coffin:GetAbsOrigin()+Vector(0,0,64))
		ParticleManager:SetParticleControl(self.effectIndex, 1, Vector(radius,1,1))

		self:StartIntervalThink(0.1)
	end
end

function modifier_thdots_kurumi02_coffin:OnIntervalThink()
	if not IsServer() then return end
	--死亡移除棺材modifier
	local coffin = self:GetParent()
	if coffin:GetHealth() == 0 then
		coffin:RemoveModifierByName("modifier_thdots_kurumi02_coffin")
	end
end

function modifier_thdots_kurumi02_coffin:OnDestroy()
	if IsServer() then
		local coffin = self:GetParent()
		local caster = self:GetCaster()
		local ability = self:GetAbility()

		--摧毁血之湖光环特效
		ParticleManager:DestroyParticle(self.effectIndex,true)
		ParticleManager:ReleaseParticleIndex(self.effectIndex)

		caster:RemoveModifierByName("modifier_thdots_kurumi02_caster")
		caster:RemoveNoDraw()
		local isDead = not self:GetParent():IsAlive()	--死亡判断

		--音效
		StartSoundEvent("Hero_Undying.Tombstone", caster )

		caster:SetUnitOnClearGround()

		-- Remove the egg --很喜欢这句
		coffin:ForceKill( false )
		coffin:AddNoDraw()

		StopSoundOn("Hero_Boodseeker.Bloodmist", coffin)
	end
end

modifier_thdots_kurumi02_area_debuff = {}
LinkLuaModifier( "modifier_thdots_kurumi02_area_debuff", "scripts/vscripts/abilities/abilitykurumi.lua", LUA_MODIFIER_MOTION_NONE )
function modifier_thdots_kurumi02_area_debuff:IsHidden() 		return false end
function modifier_thdots_kurumi02_area_debuff:IsPurgable()		return false end
function modifier_thdots_kurumi02_area_debuff:RemoveOnDeath() 	return true end
function modifier_thdots_kurumi02_area_debuff:IsDebuff()		return true end

function modifier_thdots_kurumi02_area_debuff:OnCreated()
	self.parent = self:GetParent()
end

function modifier_thdots_kurumi02_area_debuff:CheckState()
	return
	{
		[MODIFIER_STATE_SILENCED] = IsServer() and not self.parent:IsTHDImmune() or (IsClient() and self.parent:IsSilenced()),
	}
end

ability_thdots_kurumi02_out = {}

function ability_thdots_kurumi02_out:GetAssociatedPrimaryAbilities()
	return "ability_thdots_kurumi02"
end

function ability_thdots_kurumi02_out:ProcsMagicStick() return false end

function ability_thdots_kurumi02_out:OnUpgrade()
	local caster_ability = self:GetCaster():FindAbilityByName("ability_thdots_kurumi02")

	if caster_ability and caster_ability:GetLevel() ~= self:GetLevel() then
		caster_ability:SetLevel(self:GetLevel())
	end
end

function ability_thdots_kurumi02_out:OnSpellStart()
	if not IsServer() then return end
	--不知道
	local caster_modifier	= self:GetCaster():FindModifierByNameAndCaster("modifier_thdots_kurumi02_caster", self:GetCaster())
	local caster			= self:GetCaster()

	if not caster_modifier and self:GetCaster():GetOwner() then
		caster_modifier		= self:GetCaster():GetOwner():FindModifierByNameAndCaster("modifier_thdots_kurumi02_caster", self:GetCaster():GetOwner())
		caster				= self:GetCaster():GetOwner()
	end

	if caster_modifier then
		if caster_modifier.modifier_thdots_kurumi02_coffin then
			local coffin = caster_modifier.modifier_thdots_kurumi02_coffin:GetParent()
			coffin:RemoveModifierByName("modifier_thdots_kurumi02_coffin")				--主动提前结束棺材
		end
	end
end
-----------------
-- 03
----------------

ability_thdots_kurumi03 = class({})

modifier_thdots_kurumi03_attack = class({})
LinkLuaModifier("modifier_thdots_kurumi03_attack", "scripts/vscripts/abilities/abilitykurumi.lua", LUA_MODIFIER_MOTION_NONE)
function ability_thdots_kurumi03:GetIntrinsicModifierName() return "modifier_thdots_kurumi03_attack" end
function modifier_thdots_kurumi03_attack:IsHidden() 		return true end
function modifier_thdots_kurumi03_attack:OnCreated()
	if not IsServer() then return end 
end
function modifier_thdots_kurumi03_attack:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED
	}
end
function modifier_thdots_kurumi03_attack:OnAttackLanded(keys)
	if not IsServer() then return end
	if keys.attacker ~= self:GetParent() then return end
	if keys.target:IsBuilding() then return end
	local caster = self:GetParent()
	if caster:PassivesDisabled() then return end
	if caster:IsRealHero() then

		local ability = self:GetAbility()

		local radius = ability:GetSpecialValueFor("radius")
		local targets = FindUnitsInRadius(caster:GetTeam(), keys.target:GetOrigin(), nil, radius, ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), ability:GetAbilityTargetFlags(), FIND_CLOSEST, false)
		local damage = ability:GetAbilityDamage()

		local duration = ability:GetSpecialValueFor("atk_speed_slow_duration")

		for _,v in pairs(targets) do
			local damage_table = {
					ability = ability,
				    victim = v,
				    attacker = caster,
				    damage = damage,
				    damage_type = ability:GetAbilityDamageType(), 
			}
			UnitDamageTarget(damage_table)

			--local count =  v:GetDisplayAttackSpeed() * (atk_speed_slow / -100)
			v:AddNewModifier(caster, ability, "modifier_kurumi03_slow_debuff", {duration = duration * (1 - v:GetStatusResistance())})
			--v:SetModifierStackCount("modifier_kurumi03_slow_debuff",caster,count)

		end

		local effectIndex = ParticleManager:CreateParticle("particles/heroes/kurumi/kurumi_03_on_hit_drip.vpcf", PATTACH_POINT_FOLLOW, caster)
		ParticleManager:SetParticleControlEnt(effectIndex, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
		ParticleManager:DestroyParticleSystem(effectIndex,false)
	end
end

modifier_kurumi03_slow_debuff = {}
LinkLuaModifier("modifier_kurumi03_slow_debuff", "scripts/vscripts/abilities/abilitykurumi.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_kurumi03_slow_debuff:IsPurgable()			return true end
function modifier_kurumi03_slow_debuff:RemoveOnDeath() 		return true end
function modifier_kurumi03_slow_debuff:IsDebuff()			return true end

function modifier_kurumi03_slow_debuff:GetEffectName()
	return "particles/econ/items/wraith_king/wraith_king_arcana/wk_arc_slow_debuff.vpcf"
end
function modifier_kurumi03_slow_debuff:GetEffectAttachType()
	return "follow_origin"
end

function modifier_kurumi03_slow_debuff:DeclareFunctions()
	return{
		-- MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
	}
end

function modifier_kurumi03_slow_debuff:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("atk_speed_slow")
end

-- 百分比减少攻击速度  MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE
-- function modifier_kurumi03_slow_debuff:GetModifierAttackSpeedPercentage()
-- 	return self:GetAbility():GetSpecialValueFor("atk_speed_slow")
-- end

---------------
-- 04
----------------
ability_thdots_kurumi04 = class({})

ability_thdots_kurumi04_passive = class({})
LinkLuaModifier("ability_thdots_kurumi04_passive", "scripts/vscripts/abilities/abilitykurumi.lua", LUA_MODIFIER_MOTION_NONE)

function ability_thdots_kurumi04:GetIntrinsicModifierName() return "ability_thdots_kurumi04_passive" end
-- function ability_thdots_kurumi04:InnateAbilityType() return 2 end

-- function ability_thdots_kurumi04_passive:OnCreated()
-- 	if not IsServer() then return end 
-- 	self:StartIntervalThink(0.2)
-- end

-- function ability_thdots_kurumi04_passive:OnIntervalThink()
-- 	if not IsServer() then return end
-- 	self:GetParent():CalculateStatBonus(true)
-- end

function ability_thdots_kurumi04_passive:IsHidden() return true end

function ability_thdots_kurumi04_passive:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED
	}
end

function ability_thdots_kurumi04_passive:OnAttackLanded(keys)
	if not IsServer() then return end
	if keys.attacker ~= self:GetParent() then return end
	if keys.target:IsBuilding() then return end
	local caster = self:GetParent()
	if caster:PassivesDisabled() then return end
	if caster:IsRealHero() then
		local ability = self:GetAbility()
		local damage = ability:GetSpecialValueFor("damage")
		local average_damage = (caster:GetBaseDamageMin() + caster:GetBaseDamageMax())/2
		local bonus_damage = average_damage*ability:GetSpecialValueFor("base_attack_damage_bonus_pct")/100
		local missing_health = ( 1 - keys.target:GetHealth()/keys.target:GetMaxHealth())

		local total_damage = damage + bonus_damage * missing_health
		-- print("total_damage: "..total_damage.." at "..(keys.target:GetHealth()/keys.target:GetMaxHealth()*100).."% health")
			local damage_table = {
					ability = ability,
				    victim = keys.target,
				    attacker = caster,
				    damage = total_damage,
				    damage_type = ability:GetAbilityDamageType(), 
			}
			UnitDamageTarget(damage_table)
			if missing_health > 0.5 then keys.target:EmitSoundParams("Hero_PhantomAssassin.Spatter", 0, missing_health*2, 0) end
			-- local effectIndex = ParticleManager:CreateParticle("particles/econ/items/bloodseeker/bloodseeker_eztzhok_weapon/bloodseeker_bloodbath_eztzhok_ribbon.vpcf", PATTACH_CUSTOMORIGIN, caster)

			local effectIndex = ParticleManager:CreateParticle("particles/econ/items/lifestealer/ls_ti9_immortal/ls_ti9_open_wounds_impact.vpcf", PATTACH_CUSTOMORIGIN, caster)
			ParticleManager:SetParticleControl(effectIndex, 0, keys.target:GetOrigin())
			ParticleManager:DestroyParticleSystem(effectIndex,false)
	end
	
end