

function OnNazrin01SpellStart(keys)
	local target = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1	

	target:Stop()
	local caster = keys.caster

	caster.forced_direction = caster:GetForwardVector()
	ability.forced_distance = ability:GetLevelSpecialValueFor("push_length", ability_level)
	ability.forced_speed = ability:GetLevelSpecialValueFor("push_speed", ability_level) * 1/30	-- * 1/30 gives a duration of ~0.4 second push time (which is what the gamepedia-site says it should be)
	ability.forced_traveled = 0

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_OnNazrin01_active", {})
end


function OnNazrin01controlmotion(keys)
	local target = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1	

	local caster = keys.caster
	
	caster.forced_direction = caster:GetForwardVector()
end

function Nazrin01Horizontal(keys)

	local target = keys.caster
	local ability = keys.ability
	local caster = keys.caster
		

	if ability.forced_traveled < ability.forced_distance then
		target:SetAbsOrigin(target:GetAbsOrigin() + caster.forced_direction * ability.forced_speed)
		ability.forced_traveled = ability.forced_traveled + (caster.forced_direction * ability.forced_speed):Length2D()
	else
		target:InterruptMotionControllers(true)
	end

end




function OnNazrin03Attacklanded(keys)


	local caster = keys.caster
	local target = keys.caster	
	local ability = keys.ability
	
	local totalchance = keys.basechance
	
	if RollPercentage(totalchance) then	

	ability:ApplyDataDrivenModifier(caster, caster, "passive_nazrin03_attack_double", {})
	--caster:PerformAttack(target,true,false,true,false,true,false,true)
	end
end

function OnNazrin03Attackdouble(keys)


	local caster = keys.caster
	local target = keys.caster	
	local ability = keys.ability

	caster:RemoveModifierByName("passive_nazrin03_attack_double")
	--caster:PerformAttack(target,true,false,true,false,true,false,true)
end




function OnNazrin04SpellStart(keys)

	local caster = keys.caster
	local target = keys.target	
	local ability = keys.ability
	if is_spell_blocked(target,caster) then return end
	local spell_duration = ability:GetSpecialValueFor("duration")
	ability:ApplyDataDrivenModifier(caster, target, "modifier_nazrin04takedamage", {})	
	target:AddNewModifier(caster, keys.ability, "modifier_nazrin04_track",  {duration = spell_duration} )

	target:EmitSound("Hero_BountyHunter.Target")
	local particle_projectile = "particles/units/heroes/hero_bounty_hunter/bounty_hunter_track_cast.vpcf"
	local particle_projectile_fx = ParticleManager:CreateParticle(particle_projectile, PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControlEnt(particle_projectile_fx, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(particle_projectile_fx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(particle_projectile_fx)
end	


-- function OnNazrin04Attacked(keys)

-- 	local attacker = keys.attacker

-- 	local caster = keys.caster
-- 	local target = keys.target		
-- 	local ability = keys.ability
-- 	local nazrin04dealdamage = keys.basenazrindamage + (keys.bonusnazrindamage*caster:GetAgility() )
	
	
	
	
-- 	if attacker:IsRealHero() then
	
-- 		if attacker:HasModifier("modifier_nazrin04_check") then
-- 			return

-- 		end
		
		
-- 		local damage_table = {
-- 				ability = keys.ability,
-- 			    victim = target,
-- 			    attacker = caster,
-- 			    damage = nazrin04dealdamage,
-- 			    damage_type = keys.ability:GetAbilityDamageType(), 
-- 	    	    damage_flags = 0
-- 		}
-- 		target:EmitSound("Nazrin04")
-- 		target:EmitSound("Nazrin04_"..math.random(1,6))
-- 		local effectIndex = ParticleManager:CreateParticle("particles/generic_gameplay/lasthit_coins.vpcf", PATTACH_CUSTOMORIGIN, caster)
-- 		ParticleManager:SetParticleControl(effectIndex, 0, target:GetOrigin())
-- --		ParticleManager:SetParticleControl(effectIndex, 1, Vector(300,0,0))
		
-- 		ParticleManager:SetParticleControl(effectIndex, 1, target:GetOrigin())
-- 		ParticleManager:DestroyParticleSystem(effectIndex,false)		
-- 		ability:ApplyDataDrivenModifier(caster, attacker, "modifier_nazrin04_check", {})	
-- 		ability:ApplyDataDrivenModifier(caster, target, "modifier_nazrin04_stun", {})			
-- 		UnitDamageTarget(damage_table)		
	
	
-- 	end



-- end

-- function OnNazrin04bounty(keys)

-- 	local caster = keys.caster
-- --	local target = keys.target		
-- 	local ability = keys.ability
-- 	local targets = FindUnitsInRadius(
-- 				   caster:GetTeam(),						--caster team
-- 				   caster:GetOrigin(),							--find position
-- 				   nil,										--find entity
-- 				   FIND_UNITS_EVERYWHERE,						--find radius
-- 				   DOTA_UNIT_TARGET_TEAM_FRIENDLY,
-- 				   DOTA_UNIT_TARGET_HERO,
-- 				   DOTA_UNIT_TARGET_FLAG_INVULNERABLE, 0,
-- 				   false
-- 			    )
					
-- 	EmitGlobalSound("Nazrin04_4")	
	
-- 	for _,v in pairs(targets) do
		
-- 	local bonus_gold = keys.GiveGoldAmount
	
-- 		if v:HasModifier("modifier_nazrin04_check")	 then
-- 			local effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_furion/furion_tnt_rain_coins.vpcf", PATTACH_CUSTOMORIGIN, caster)		
-- 			ParticleManager:SetParticleControl(effectIndex, 0, v:GetOrigin())
-- 			ParticleManager:SetParticleControl(effectIndex, 1, v:GetOrigin())
-- 			ParticleManager:DestroyParticleSystem(effectIndex,false)
-- 		--	target:EmitSound("Nazrin04_4")				
	
-- 			v:ModifyGold(bonus_gold, false, 0)
-- 			v:RemoveModifierByName("modifier_nazrin04_check")			
-- 		end
	
-- 	end

-- end

-- function OnNazrin04deatheffect(keys)
-- 	local ability = keys.ability
-- 	--local target = ability:GetParent()
-- 	local target = keys.Target
-- 	local caster = keys.caster
-- 	if target:GetHealth() == 0 then
	
-- 		local effectIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_furion/furion_tnt_rain_coins.vpcf", PATTACH_CUSTOMORIGIN, caster)
-- 		ParticleManager:SetParticleControl(effectIndex, 0, target:GetOrigin())
-- --		ParticleManager:SetParticleControl(effectIndex, 1, Vector(300,0,0))
		
-- 		ParticleManager:SetParticleControl(effectIndex, 1, target:GetOrigin())
-- 		ParticleManager:DestroyParticleSystem(effectIndex,false)	
-- 		target:EmitSound("Nazrin04_4")	
	
	
-- 	end




-- end

modifier_ability_thdots_nazrin02_effect = {}
LinkLuaModifier("modifier_ability_thdots_nazrin02_effect","scripts/vscripts/abilities/abilitynazrin.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_nazrin02_effect:IsHidden() 		return true end
function modifier_ability_thdots_nazrin02_effect:IsPurgable()		return false end
function modifier_ability_thdots_nazrin02_effect:RemoveOnDeath() 	return true end
function modifier_ability_thdots_nazrin02_effect:IsDebuff()		return false end

function modifier_ability_thdots_nazrin02_effect:OnCreated()
	if not IsServer() then return end
	self.effect = ParticleManager:CreateParticle("particles/econ/events/ti10/mjollnir_shield_ti10.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
end

function modifier_ability_thdots_nazrin02_effect:OnDestroy()
	if not IsServer() then return end
	ParticleManager:DestroyParticle(self.effect,true)
end

function OnNazrin02spellstart(keys)
	local caster = keys.caster
	local ability = keys.ability
	keys.target:AddNewModifier(caster, keys.ability, "modifier_ability_thdots_nazrin02_effect", {})
	-- ability.effect = ParticleManager:CreateParticle("particles/items2_fx/mjollnir_shield.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
end

function OnNazrin02ModifierCreated(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	
	local magresist = ability:GetSpecialValueFor("mag")
	
end


function OnNazrin02ModifierDestroyed(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	if target:HasModifier("modifier_ability_thdots_nazrin02_effect") then
		target:RemoveModifierByName("modifier_ability_thdots_nazrin02_effect")
	end
	
end


function OnNazrin02spelldamage(keys)

	local caster = keys.caster
	
	local target = keys.target
	
	local Radius = keys.Radius
	
	local totaldealdamage = (keys.basedealdamage + caster:GetAgility()*keys.abilitymulti)*keys.intervals
	
	local targets = FindUnitsInRadius(
				   caster:GetTeam(),						--caster team
				   target:GetOrigin(),							--find position
				   nil,										--find entity
				   Radius,						--find radius
				   DOTA_UNIT_TARGET_TEAM_ENEMY,
				   DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
				   DOTA_UNIT_TARGET_FLAG_INVULNERABLE, 0,
				   false
			    )	
				
	for _,v in pairs(targets) do
		
		local damage_table = {
				ability = keys.ability,
			    victim = v,
			    attacker = caster,
			    damage = totaldealdamage,
			    damage_type = keys.ability:GetAbilityDamageType(), 
	    	    damage_flags = 0
		}	
		UnitDamageTarget(damage_table)	

	
	end				



end


modifier_nazrin04_track = modifier_nazrin04_track or class({})
LinkLuaModifier("modifier_nazrin04_track", "scripts/vscripts/abilities/abilitynazrin.lua", LUA_MODIFIER_MOTION_NONE )


function modifier_nazrin04_track:IsPurgable() 
	return false 
end

function modifier_nazrin04_track:IsDebuff() 
	return true 
end
function modifier_nazrin04_track:RemoveOnDeath()
    return true
end

function modifier_nazrin04_track:IsHidden()
    return false
end


function modifier_nazrin04_track:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_nazrin04_track:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}

	return funcs
end


function modifier_nazrin04_track:OnCreated(keys)
	if not IsServer() then return end
	
	local ability = self:GetAbility()
	local target = self:GetParent()
	local caster = self:GetCaster()
	
	self.group = {}
	local bonus_gold = ability:GetSpecialValueFor("bonus_gold")
	
	print("totalgoldtoget=="..bonus_gold)
	
	
end

function modifier_nazrin04_track:OnRefresh(keys)
	if not IsServer() then return end
	self:OnCreated(keys)
end

function modifier_nazrin04_track:OnAttackLanded(keys)
	if not IsServer() then return end
	
	if keys.target ~= self:GetParent() then
		return
	end
	local attacker = keys.attacker
	if keys.attacker:IsHero() ~= true then
		return
	end
	if keys.attacker:IsRealHero() ~= true then
		return
	end

	if IsWithinThisGroup(attacker,self.group) then
		return
	end
	
	table.insert(self.group, attacker)
	
	local ability = self:GetAbility()
	local target = self:GetParent()
	local caster = self:GetCaster()
	
	local base_damage = ability:GetSpecialValueFor("basedamage")
	local agi_scale = ability:GetSpecialValueFor("ability_multi")
	
	local nazrin04dealdamage =  base_damage + (caster:GetAgility() * agi_scale)
	
	local damage_table = {
			ability = ability,
		    victim = target,
		    attacker = caster,
		    damage = nazrin04dealdamage,
		    damage_type = ability:GetAbilityDamageType(), 
	   	    damage_flags = 0
	}
	target:EmitSound("Nazrin04")
	target:EmitSound("Nazrin04_"..math.random(1,6))
	local effectIndex = ParticleManager:CreateParticle("particles/generic_gameplay/lasthit_coins.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(effectIndex, 0, target:GetOrigin())
	ParticleManager:SetParticleControl(effectIndex, 1, target:GetOrigin())
	ParticleManager:DestroyParticleSystem(effectIndex,false)		
	
	UtilStun:UnitStunTarget( caster,target,ability:GetSpecialValueFor("stun_duration"))
	
	UnitDamageTarget(damage_table)
	
	
end

function modifier_nazrin04_track:OnRemoved(keys)
	if not IsServer() then return end
	
	local ability = self:GetAbility()
	local target = self:GetParent()
	local caster = self:GetCaster()
	
	if target:IsAlive() then
	
		return
	
	end
	print(target:GetTimeUntilRespawn())
	if not target:IsRealHero() then 
		print("11111")
		return end
	--判断是否有盾
	target:SetContextThink("HasAegis",
		function()
			if target:GetTimeUntilRespawn() > 5 then
				print(target:GetTimeUntilRespawn())
				print("no aeigs")

				print("Nazrin04Start")
				print(PlayerResource:GetNetWorth(caster:GetPlayerOwnerID()))
				EmitGlobalSound("Nazrin04_4")	
				local bonus_gold = ability:GetSpecialValueFor("bonus_gold")
				
				print("totalgoldtoget=="..bonus_gold)
				for _,v in pairs(self.group) do
					if v ~= caster then
						local PlayerID = v:GetPlayerOwnerID()
						PlayerResource:SetGold(PlayerID,PlayerResource:GetUnreliableGold(PlayerID) + bonus_gold,false)
						local effectIndex = ParticleManager:CreateParticle("particles/thd2/items/item_donation_box.vpcf", PATTACH_CUSTOMORIGIN, v)
						ParticleManager:SetParticleControl(effectIndex, 0, v:GetAbsOrigin())
						ParticleManager:SetParticleControl(effectIndex, 1, v:GetAbsOrigin())
						ParticleManager:ReleaseParticleIndex(effectIndex)
						v:EmitSound("DOTA_Item.Hand_Of_Midas")
						SendOverheadEventMessage(nil, OVERHEAD_ALERT_GOLD,v, bonus_gold, nil)
					end
				end

				local effectIndex = ParticleManager:CreateParticle("particles/thd2/items/item_donation_box.vpcf", PATTACH_CUSTOMORIGIN, caster)
				ParticleManager:SetParticleControl(effectIndex, 0, caster:GetAbsOrigin())
				ParticleManager:SetParticleControl(effectIndex, 1, caster:GetAbsOrigin())
				ParticleManager:ReleaseParticleIndex(effectIndex)
				caster:EmitSound("DOTA_Item.Hand_Of_Midas")
				SendOverheadEventMessage(nil, OVERHEAD_ALERT_GOLD,caster, bonus_gold, nil)

				local PlayerID = caster:GetPlayerOwnerID()
				PlayerResource:SetGold(PlayerID,PlayerResource:GetUnreliableGold(PlayerID) + bonus_gold,false)
				print(PlayerResource:GetNetWorth(caster:GetPlayerOwnerID()))

			end
		end
		,
		0.03)
	
end

function IsWithinThisGroup(unit,group)


	for k,v in pairs(group) do
	
		if v == unit then
			return true
		end
	end
	
	return false
end

ability_thdotsr_NazrinEx = {}

function ability_thdotsr_NazrinEx:GetIntrinsicModifierName()
	return "modifier_ability_thdots_nazrinEx"
end
function ability_thdotsr_NazrinEx:GetBehavior()
	if self:GetCaster():HasModifier("modifier_item_wanbaochui") then
		return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_CHANNELLED + DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING
	else
		return self.BaseClass.GetBehavior(self)
	end
end
modifier_ability_thdots_nazrinEx = {}
LinkLuaModifier("modifier_ability_thdots_nazrinEx","scripts/vscripts/abilities/abilitynazrin.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_nazrinEx:IsHidden() 		return true end
function modifier_ability_thdots_nazrinEx:IsPurgable()		return false end
function modifier_ability_thdots_nazrinEx:RemoveOnDeath() 	return false end
function modifier_ability_thdots_nazrinEx:IsDebuff()		return false end

function modifier_ability_thdots_nazrinEx:OnCreated()
	if not IsServer() then return end
	self.caster = self:GetCaster()
	self.caster:SetContextThink("nazrinEx",
		function()
		local team = FindUnitsInRadius(self.caster:GetTeam(),self.caster:GetOrigin(),nil,99999,self:GetAbility():GetAbilityTargetTeam(),
									self:GetAbility():GetAbilityTargetType(),0,0,false)
		print("#team is:",#team)
			if #team > 0 then
				for _,v in pairs(team) do
					if v:IsRealHero() then
						v:AddNewModifier(self.caster, self:GetAbility(), "modifier_ability_thdots_nazrinEx_gold", {})
					end
				end
			end
		end
	,10)
end

modifier_ability_thdots_nazrinEx_gold = {}
LinkLuaModifier("modifier_ability_thdots_nazrinEx_gold","scripts/vscripts/abilities/abilitynazrin.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_nazrinEx_gold:IsHidden() 		return false end
function modifier_ability_thdots_nazrinEx_gold:IsPurgable()		return false end
function modifier_ability_thdots_nazrinEx_gold:RemoveOnDeath() 	return false end
function modifier_ability_thdots_nazrinEx_gold:IsDebuff()		return false end

function modifier_ability_thdots_nazrinEx_gold:OnCreated()
	if not IsServer() then return end
	self.give_gold_amount 			= self:GetAbility():GetSpecialValueFor("give_gold_amount")
	self.give_gold_interval 		= self:GetAbility():GetSpecialValueFor("give_gold_interval")
	self:StartIntervalThink(self.give_gold_interval)
end

function modifier_ability_thdots_nazrinEx_gold:OnIntervalThink()
	if not IsServer() then return end
	local Caster = self:GetParent()
	local CasterPlayerID = Caster:GetPlayerOwnerID()
	if GameRules:GetDOTATime(false, false) == 0 then return end
	PlayerResource:SetGold(CasterPlayerID,PlayerResource:GetUnreliableGold(CasterPlayerID) + self.give_gold_amount,false)
end

function ability_thdotsr_NazrinEx:OnSpellStart()
	if not IsServer() then return end

	self.BOUNTY_threshold = self:GetSpecialValueFor("DOTA_RUNE_BOUNTY_chance")
	self.XP_threshold = self:GetSpecialValueFor("DOTA_RUNE_XP_chance") + self.BOUNTY_threshold
	self.ILLUSION_threshold = self:GetSpecialValueFor("DOTA_RUNE_ILLUSION_chance") + self.XP_threshold
	self.INVISIBILITY_threshold = self:GetSpecialValueFor("DOTA_RUNE_INVISIBILITY_chance") + self.ILLUSION_threshold
	self.SHIELD_threshold = self:GetSpecialValueFor("DOTA_RUNE_SHIELD_chance") + self.INVISIBILITY_threshold
	self.DOUBLEDAMAGE_threshold = self:GetSpecialValueFor("DOTA_RUNE_DOUBLEDAMAGE_chance") + self.SHIELD_threshold
	self.pfx = ParticleManager:CreateParticle("particles/econ/events/ti9/shovel_dig.vpcf", PATTACH_WORLDORIGIN, self:GetCaster())
	ParticleManager:SetParticleControl(self.pfx, 0, self:GetCursorPosition())

	EmitSoundOn("SeasonalConsumable.TI9.Shovel.Dig", self:GetCaster())
end

function ability_thdotsr_NazrinEx:OnChannelThink(fInterval)
	if not IsServer() then return end
end

function ability_thdotsr_NazrinEx:OnChannelFinish(bInterrupted)
	if not IsServer() then return end

	-- successful channel
	if not bInterrupted then
		local random_int = RandomInt(1, 100)

		if random_int > 0 and random_int <= self.BOUNTY_threshold then
			CreateRune(self:GetCursorPosition(), DOTA_RUNE_BOUNTY)
		elseif random_int > self.BOUNTY_threshold and random_int <= self.XP_threshold then
			CreateRune(self:GetCursorPosition(), DOTA_RUNE_XP)
		elseif random_int > self.XP_threshold and random_int <= self.ILLUSION_threshold then
			CreateRune(self:GetCursorPosition(), DOTA_RUNE_ILLUSION)
		elseif random_int > self.ILLUSION_threshold and random_int <= self.INVISIBILITY_threshold then
			CreateRune(self:GetCursorPosition(), DOTA_RUNE_INVISIBILITY)
		elseif random_int > self.INVISIBILITY_threshold and random_int <= self.SHIELD_threshold then
			CreateRune(self:GetCursorPosition(), DOTA_RUNE_SHIELD)
		elseif random_int > self.SHIELD_threshold and random_int <= self.DOUBLEDAMAGE_threshold then
			CreateRune(self:GetCursorPosition(), DOTA_RUNE_DOUBLEDAMAGE)
		end

		local pfx2 = ParticleManager:CreateParticle("particles/econ/events/ti9/shovel_revealed_generic.vpcf", PATTACH_WORLDORIGIN, self:GetCaster())
		ParticleManager:SetParticleControl(pfx2, 0, self:GetCursorPosition())
		ParticleManager:ReleaseParticleIndex(pfx2)
	end

	if self.pfx then
		ParticleManager:DestroyParticle(self.pfx, false)
		ParticleManager:ReleaseParticleIndex(self.pfx)
	end

	StopSoundOn("SeasonalConsumable.TI9.Shovel.Dig", self:GetCaster())
end
