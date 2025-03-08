ability_thdots_minoriko01 = {}

function ability_thdots_minoriko01:GetAOERadius()
	if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
		return self:GetSpecialValueFor("wanbaochui_radius")
	else
		return 0
	end
end

function ability_thdots_minoriko01:GetBehavior()
	if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
		return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_AOE
	else
		return self.BaseClass.GetBehavior(self)
	end
end

function ability_thdots_minoriko01:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	if is_spell_blocked(target,caster) then return end
	caster:EmitSound("Voice_Thdots_Minoriko.AbilityMinoriko01")
	if not self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
		local info = {
			Source = self:GetCaster(),
			Target = target,
			Ability = self,
			bDodgeable = true,
			bProvidesVision		= true,
			iVisionRadius = 100,
			EffectName = "particles/heroes/minoriko/ability_minoriko_01.vpcf",
			iMoveSpeed = 1000,
			iSourceAttachment 	= DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
		}
		ProjectileManager:CreateTrackingProjectile(info)
	else
		local radius = self:GetSpecialValueFor("wanbaochui_radius")
		local targets = FindUnitsInRadius(caster:GetTeam(), target:GetOrigin(),nil,radius,self:GetAbilityTargetTeam(),
		self:GetAbilityTargetType(),0,0,false)
		DeleteDummy(targets)
		for _,v in pairs(targets) do
			local info = {
			Source = self:GetCaster(),
			Target = v,
			Ability = self,
			bDodgeable = true,
			bProvidesVision		= true,
			iVisionRadius = 100,
			EffectName = "particles/heroes/minoriko/ability_minoriko_01.vpcf",
			iMoveSpeed = 1000,
			iSourceAttachment 	= DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
		}
		ProjectileManager:CreateTrackingProjectile(info)
		end
	end
end

function ability_thdots_minoriko01:OnProjectileHit(hTarget, vLocation)
	if not IsServer() then return end
	if not hTarget then return end
	local caster 				= self:GetCaster()
	local target 				= hTarget
	local damage  				= self:GetSpecialValueFor("damage")
	local stun_duration  		= self:GetSpecialValueFor("stun_duration")
	local duration  			= self:GetSpecialValueFor("duration")
	local radius  				= self:GetSpecialValueFor("radius")
	local aoe_damage  			= self:GetSpecialValueFor("aoe_damage")
	local heal_amount  			= self:GetSpecialValueFor("heal_amount")
	local heal_percent  		= self:GetSpecialValueFor("heal_percent")

	target:EmitSound("Minoriko.AbilityMinoriko01")
	local target = hTarget
	if caster:GetTeam() ~= target:GetTeam() then
		local ex=target:GetMaxHealth()*heal_percent/100
		UtilStun:UnitStunTarget( caster,target,(stun_duration+FindTelentValue(caster,"special_bonus_unique_minoriko_3")))
		local targets = FindUnitsInRadius(
				   caster:GetTeam(),		
				   target:GetOrigin(),	
				   nil,					
				   radius,		
				   DOTA_UNIT_TARGET_TEAM_ENEMY,
				   self:GetAbilityTargetType(),
				   0,
				   FIND_CLOSEST,
				   false
			    )
		--local mod = v:AddNewModifier(caster, self, "modifier_ability_thdots_minoriko01_sign",{duration = 1})
		local damage_table = {
			ability = self,
			victim = target,
			attacker = caster,
			damage = aoe_damage + ex,
			damage_type = self:GetAbilityDamageType(),
		    damage_flags = DOTA_DAMAGE_FLAG_NONE
		}
		UnitDamageTarget(damage_table)

		local effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_ogre_magi/ogre_magi_fireblast.vpcf", PATTACH_CUSTOMORIGIN, target)
		ParticleManager:SetParticleControl(effectIndex , 0, target:GetOrigin())
		ParticleManager:SetParticleControl(effectIndex , 1, target:GetOrigin())
		
	elseif target:GetUnitName() == "npc_thdots_unit_minoriko02_box" and caster:GetPlayerOwner() == target:GetPlayerOwner() and caster:FindAbilityByName("ability_thdots_minoriko02") ~= nil then --砸车
		local minoriko02 = caster:FindAbilityByName("ability_thdots_minoriko02")
		local box_damage = self:GetSpecialValueFor("aoe_damage")
		local minoriko02_radius = minoriko02:GetSpecialValueFor("aura_radius")
		local minoriko01_box_particle = "particles/econ/items/lina/lina_ti7/lina_spell_light_strike_array_ti7_gold.vpcf"
		local minoriko01_box_particle_fx = ParticleManager:CreateParticle(minoriko01_box_particle, PATTACH_ABSORIGIN,target)
		ParticleManager:SetParticleControl(minoriko01_box_particle_fx, 0,target:GetAbsOrigin())
		ParticleManager:SetParticleControl(minoriko01_box_particle_fx, 1, Vector(minoriko02_radius,1,1))
		ParticleManager:ReleaseParticleIndex(minoriko01_box_particle_fx)
		--对周围敌方造成伤害
		local damage_targets = FindUnitsInRadius(
				   caster:GetTeam(),		
				   target:GetOrigin(),	
				   nil,					
				   minoriko02_radius,		
				   DOTA_UNIT_TARGET_TEAM_ENEMY,
				   self:GetAbilityTargetType(),
				   0,
				   FIND_CLOSEST,
				   false
			    )
		for _,vic in pairs(damage_targets) do
			local damage_table = {
				ability = self,
				victim = vic,
				attacker = caster,
				damage = box_damage,
				damage_type = self:GetAbilityDamageType(), 
			    damage_flags = DOTA_DAMAGE_FLAG_NONE
			}
			UnitDamageTarget(damage_table) 
		end
		--[[对周围友军治疗
		local heal_targets = FindUnitsInRadius(
				   caster:GetTeam(),		
				   target:GetOrigin(),	
				   nil,					
				   minoriko02_radius,		
				   DOTA_UNIT_TARGET_TEAM_FRIENDLY,
				   self:GetAbilityTargetType(),
				   0,
				   FIND_CLOSEST,
				   false
			    )
		for _,vic in pairs(heal_targets) do
			local minoriko02 = caster:FindAbilityByName("ability_thdots_minoriko02")
			local box_heal = minoriko02:GetSpecialValueFor("heal_amount")
			vic:Heal(box_heal, caster) 
			SendOverheadEventMessage(nil,OVERHEAD_ALERT_HEAL,vic,box_heal,nil)
		end
		]]
	else
		target:Heal(heal_amount+target:GetMaxHealth()*heal_percent/100, caster) 
		SendOverheadEventMessage(nil,OVERHEAD_ALERT_HEAL,target,heal_amount+target:GetMaxHealth()*heal_percent/100,nil)
		local effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_buff.vpcf", PATTACH_CUSTOMORIGIN, target)
		ParticleManager:SetParticleControl(effectIndex , 0, target:GetOrigin())
		ParticleManager:DestroyParticleSystemTime(effectIndex,1.0)
	end
end

modifier_ability_thdots_minoriko01_sign = {}
LinkLuaModifier("modifier_ability_thdots_minoriko01_sign","scripts/vscripts/abilities/abilityMinoriko.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_minoriko01_sign:IsHidden() return true end

function modifier_ability_thdots_minoriko01_sign:OnCreated()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local target = self:GetParent()
	local ability = self:GetAbility()
	local total_damage = ability:GetSpecialValueFor("aoe_damage")
	total_damage = total_damage + self.exdamage
	local damage_table = {
			ability = ability,
			victim = target,
			attacker = caster,
			damage = total_damage,
			damage_type = ability:GetAbilityDamageType(), 
		    damage_flags = ability:GetAbilityTargetFlags()
		}
	UnitDamageTarget(damage_table)
end


function OnMinoriko01ProjectileHitUnit(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local target = keys.target
	if target:IsNull()==false and target ~= nil then
		if caster:GetTeam() ~= target:GetTeam() and is_spell_blocked(keys.target) then 
			return 
		end
	end
	print(caster:GetPlayerOwner())
	print(target:GetPlayerOwner())
	if caster:GetTeam() ~= target:GetTeam() then
		local targetLoc = target:GetAbsOrigin()
		local exdamage=target:GetMaxHealth()*keys.heal_percent/100
		local damage_table = {
			ability = keys.ability,
			victim = target,
			attacker = caster,
			damage = keys.ability:GetAbilityDamage(),
			damage_type = keys.ability:GetAbilityDamageType(), 
		    damage_flags = keys.ability:GetAbilityTargetFlags()
		}
		UtilStun:UnitStunTarget( caster,target,(keys.stun_duration+FindTelentValue(caster,"special_bonus_unique_minoriko_3")))
		local effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_ogre_magi/ogre_magi_fireblast.vpcf", PATTACH_CUSTOMORIGIN, target)
		ParticleManager:SetParticleControl(effectIndex , 0, target:GetOrigin())
		ParticleManager:SetParticleControl(effectIndex , 1, target:GetOrigin())
		UnitDamageTarget(damage_table) 
		local targets = FindUnitsInRadius(
				   caster:GetTeam(),		
				   targetLoc,	
				   nil,					
				   keys.radius,		
				   DOTA_UNIT_TARGET_TEAM_ENEMY,
				   keys.ability:GetAbilityTargetType(),
				   0,
				   FIND_CLOSEST,
				   false
			    )
		for k,v in pairs(targets) do
			if v and not v:IsNull() then
				local damage_table = {
					ability = keys.ability,
					victim = v,
					attacker = caster,
					damage = keys.aoe_damage+exdamage,
					damage_type = keys.ability:GetAbilityDamageType(), 
						damage_flags = keys.ability:GetAbilityTargetFlags()
				}
				UnitDamageTarget(damage_table) 
			end
		end
	elseif target:GetUnitName() == "npc_thdots_unit_minoriko02_box" and caster:GetPlayerOwner() == target:GetPlayerOwner() and caster:FindAbilityByName("ability_thdots_minoriko02") ~= nil then --砸车
		local minoriko02 = caster:FindAbilityByName("ability_thdots_minoriko02")
		local box_damage = minoriko02:GetSpecialValueFor("heal_amount")
		local minoriko02_radius = minoriko02:GetSpecialValueFor("aura_radius")
		local minoriko01_box_particle = "particles/econ/items/lina/lina_ti7/lina_spell_light_strike_array_ti7_gold.vpcf"
		local minoriko01_box_particle_fx = ParticleManager:CreateParticle(minoriko01_box_particle, PATTACH_ABSORIGIN,target)
		ParticleManager:SetParticleControl(minoriko01_box_particle_fx, 0,target:GetAbsOrigin())
		ParticleManager:SetParticleControl(minoriko01_box_particle_fx, 1, Vector(minoriko02_radius,1,1))
		ParticleManager:ReleaseParticleIndex(minoriko01_box_particle_fx)
		--对周围敌方造成伤害
		local damage_targets = FindUnitsInRadius(
				   caster:GetTeam(),		
				   target:GetOrigin(),	
				   nil,					
				   minoriko02_radius,		
				   DOTA_UNIT_TARGET_TEAM_ENEMY,
				   keys.ability:GetAbilityTargetType(),
				   0,
				   FIND_CLOSEST,
				   false
			    )
		for _,vic in pairs(damage_targets) do
			local damage_table = {
				ability = keys.ability,
				victim = vic,
				attacker = caster,
				damage = box_damage,
				damage_type = keys.ability:GetAbilityDamageType(), 
			    damage_flags = keys.ability:GetAbilityTargetFlags()
			}
			UnitDamageTarget(damage_table) 
		end
		--对周围友军治疗
		local heal_targets = FindUnitsInRadius(
				   caster:GetTeam(),		
				   target:GetOrigin(),	
				   nil,					
				   minoriko02_radius,		
				   DOTA_UNIT_TARGET_TEAM_FRIENDLY,
				   keys.ability:GetAbilityTargetType(),
				   0,
				   FIND_CLOSEST,
				   false
			    )
		for _,vic in pairs(heal_targets) do
			local minoriko02 = caster:FindAbilityByName("ability_thdots_minoriko02")
			local box_heal = minoriko02:GetSpecialValueFor("heal_amount")
			vic:Heal(box_heal, caster) 
			SendOverheadEventMessage(nil,OVERHEAD_ALERT_HEAL,vic,box_heal,nil)
		end
	else
		target:Heal(keys.heal_amount+target:GetMaxHealth()*keys.heal_percent/100, caster) 
		SendOverheadEventMessage(nil,OVERHEAD_ALERT_HEAL,target,keys.heal_amount+target:GetMaxHealth()*keys.heal_percent/100,nil)
		local effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_buff.vpcf", PATTACH_CUSTOMORIGIN, target)
		ParticleManager:SetParticleControl(effectIndex , 0, target:GetOrigin())
		ParticleManager:DestroyParticleSystemTime(effectIndex,1.0)
	end
end

modifier_thdots_minoriko02_box = class({})
LinkLuaModifier("modifier_thdots_minoriko02_box", "scripts/vscripts/abilities/abilityminoriko.lua", LUA_MODIFIER_MOTION_NONE)

function Minoriko02_OnIntervalThink(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	if caster:HasModifier("modifier_item_wanbaochui") then
		keys.ability:ApplyDataDrivenModifier(caster, caster, "thdots_minoriko02_wanbaochui_buff", {})
	else
		caster:RemoveModifierByName("thdots_minoriko02_wanbaochui_buff")
	end
end

function OnMinoriko02SpellStart(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	EmitAnnouncerSoundForTeamOnLocation("Voice_Thdots_Minoriko.AbilityMinoriko02", caster:GetTeam(), caster:GetOrigin())
	THDReduceCooldown(keys.ability,FindTelentValue(caster,"special_bonus_unique_minoriko_4"))
	local targetPoint = keys.target_points[1]
	local NewDuration = keys.duration + FindTelentValue(caster,"special_bonus_unique_minoriko_4") - 1

	local minoriko02 = CreateUnitByName(
		"npc_thdots_unit_minoriko02_box"
		,targetPoint
		,false
		,caster
		,caster
		,caster:GetTeam()
	)
	SetTHD2BlockingNeutrals(minoriko02, false)
	FindClearSpaceForUnit(minoriko02, targetPoint, false)
	minoriko02:SetControllableByPlayer(caster:GetPlayerID(),false)
	if not caster:HasModifier("modifier_item_wanbaochui") then
		minoriko02:SetBaseMaxHealth(4)
	else
		minoriko02:SetBaseMoveSpeed(350)
	end

	minoriko02.box_regen_targets = {}
	keys.ability:ApplyDataDrivenModifier( minoriko02, minoriko02, "aura_thdots_minoriko02_buff", {Duration = NewDuration} )
	minoriko02:AddNewModifier(minoriko02, keys.ability, "modifier_thdots_minoriko02_box", {Duration = NewDuration})
	if caster:HasModifier("modifier_item_wanbaochui") then
		keys.ability:ApplyDataDrivenModifier( minoriko02, minoriko02, "aura_thdots_minoriko02_wanbaochui", {Duration = NewDuration} )
	end
	
	minoriko02:SetContextThink(DoUniqueString("OnMinoriko02Destroy"), 
		function()
			if GameRules:IsGamePaused() then return 0.03 end
			for k,v in pairs(minoriko02.box_regen_targets) do
				if v~=nil and v:IsNull()==false then
					v:RemoveModifierByName("modifier_thdots_minoriko02_buff")
				end
			end
			minoriko02:Destroy()
			return nil
		end, 
	keys.duration + FindTelentValue(caster,"special_bonus_unique_minoriko_4"))
end

function OnMinoriko02Attacked(params) -- health handling
	if params.caster:GetHealth() > 1 then
		params.caster:SetHealth(params.caster:GetHealth() - 1)
	else
		params.caster:Kill(nil, params.attacker)
	end
end

function OnMinoriko02RegenHealth(keys)
	local count = 0
	for k,v in pairs(keys.caster.box_regen_targets) do
		if v == keys.target then
			return
		end
	end
	keys.target:SetContextThink(DoUniqueString("Minoriko02RegenHealth"), 
		function ()
			if count < 4 then
				keys.target:Heal(keys.heal_amount/4, keys.caster)
				keys.target:SetMana(keys.mana_regen_amount/4+keys.target:GetMana())
				SendOverheadEventMessage(nil,OVERHEAD_ALERT_HEAL,keys.target,keys.heal_amount/4,nil)
				count = count + 1
				return 1.0
			else
				table.insert( keys.caster.box_regen_targets , keys.target)
				return nil
			end
		end,
	1.0)
end

function modifier_thdots_minoriko02_box:IsHidden()			return true end
function modifier_thdots_minoriko02_box:IsPurgable()		return false end
-- function modifier_thdots_minoriko02_box:RemoveOnDeath()		return false end
-- function modifier_thdots_minoriko02_box:IsDebuff()			return false end

function modifier_thdots_minoriko02_box:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTHBAR_PIPS,
	}
end

function modifier_thdots_minoriko02_box:GetModifierHealthBarPips()
	return self:GetParent():GetMaxHealth()
end

function OnMinoriko04SpellStart(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local target = keys.target

	local time = 0
	caster:EmitSound("Voice_Thdots_Minoriko.AbilityMinoriko04")
	caster:SetContextThink(DoUniqueString("OnMinoriko04SpellThink"), 
		function ()
			if GameRules:IsGamePaused() then return 0.03 end
			if time < keys.duration then 
				time = time + 0.5
				local effectIndex1 = ParticleManager:CreateParticle("particles/heroes/minoriko/ability_minoriko_04.vpcf", PATTACH_CUSTOMORIGIN, target)
				ParticleManager:SetParticleControlEnt(effectIndex1 , 0, target, 5, "attach_hitloc", Vector(0,0,0), true)
			else
				return nil
			end

			caster:EmitSound("Minoriko.AbilityMinoriko04")

			if caster:GetTeam() == target:GetTeam() then
				local targets = FindUnitsInRadius(
						   caster:GetTeam(),		
						   target:GetOrigin(),	
						   nil,					
						   keys.radius + FindTelentValue(caster,"special_bonus_unique_minoriko_1"),		
						   DOTA_UNIT_TARGET_TEAM_ENEMY,
						   keys.ability:GetAbilityTargetType(),
						   0,
						   FIND_CLOSEST,
						   false
					    )
				if #targets > 0 then
					keys.ability:ApplyDataDrivenModifier( caster, target, "aura_thdots_minoriko04_buff", {} )
					local stackCount = target:GetModifierStackCount("aura_thdots_minoriko04_buff", caster)
					target:SetModifierStackCount("aura_thdots_minoriko04_buff", caster, stackCount + keys.strength_amount * (#targets))
					keys.ability:ApplyDataDrivenModifier( caster, target, "aura_thdots_minoriko04_strength", {} )

					for k,v in pairs(targets) do

						local effectIndex = ParticleManager:CreateParticle("particles/heroes/minoriko/ability_minoriko_04_laser.vpcf", PATTACH_CUSTOMORIGIN, caster)

						ParticleManager:SetParticleControlEnt(effectIndex , 0, v, 5, "attach_hitloc", Vector(0,0,0), true)
						ParticleManager:SetParticleControlEnt(effectIndex , 1, target, 5, "attach_hitloc", Vector(0,0,0), true)
						ParticleManager:SetParticleControlEnt(effectIndex , 9, v, 5, "attach_hitloc", Vector(0,0,0), true)

						keys.ability:ApplyDataDrivenModifier( caster, v, "aura_thdots_minoriko04_debuff", {} )
						stackCount = v:GetModifierStackCount("aura_thdots_minoriko04_debuff", caster)
						v:SetModifierStackCount("aura_thdots_minoriko04_debuff", caster, stackCount + keys.strength_amount)
						keys.ability:ApplyDataDrivenModifier( caster, v, "aura_thdots_minoriko04_strength", {} )
					end
				end
			else
				local targets = FindUnitsInRadius(
						   caster:GetTeam(),		
						   target:GetOrigin(),	
						   nil,					
						   keys.radius + FindTelentValue(caster,"special_bonus_unique_minoriko_1"),		
						   DOTA_UNIT_TARGET_TEAM_FRIENDLY,
						   keys.ability:GetAbilityTargetType(),
						   0,
						   FIND_CLOSEST,
						   false
					    )
				if #targets > 0 then
					keys.ability:ApplyDataDrivenModifier( caster, target, "aura_thdots_minoriko04_debuff", {} )
					local stackCount = target:GetModifierStackCount("aura_thdots_minoriko04_debuff", caster)
					target:SetModifierStackCount("aura_thdots_minoriko04_debuff", caster, stackCount + keys.strength_amount * (#targets))
					keys.ability:ApplyDataDrivenModifier( caster, target, "aura_thdots_minoriko04_strength", {} )

					for k,v in pairs(targets) do

						local effectIndex = ParticleManager:CreateParticle("particles/heroes/minoriko/ability_minoriko_04_laser.vpcf", PATTACH_CUSTOMORIGIN, caster)

						ParticleManager:SetParticleControlEnt(effectIndex , 0, v, 5, "attach_hitloc", Vector(0,0,0), true)
						ParticleManager:SetParticleControlEnt(effectIndex , 1, target, 5, "attach_hitloc", Vector(0,0,0), true)
						ParticleManager:SetParticleControlEnt(effectIndex , 9, v, 5, "attach_hitloc", Vector(0,0,0), true)

						keys.ability:ApplyDataDrivenModifier( caster, v, "aura_thdots_minoriko04_buff", {} )
						stackCount = v:GetModifierStackCount("aura_thdots_minoriko04_buff", caster)
						v:SetModifierStackCount("aura_thdots_minoriko04_buff", caster, stackCount + keys.strength_amount)
						keys.ability:ApplyDataDrivenModifier( caster, v, "aura_thdots_minoriko04_strength", {} )
					end
				end
			end
			return 0.5
		end,
	0.5)
end
