function OnUtsuho01SpellStart(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	if is_spell_blocked(keys.target) then return end
	local vecCaster = caster:GetOrigin()
	local target = keys.target
	local ability = keys.ability
	local dealdamage = keys.ability:GetAbilityDamage()
	local damage_target = {
		victim = keys.target,
		attacker = caster,
		damage = dealdamage,
		damage_type = keys.ability:GetAbilityDamageType(), 
	    damage_flags = 0
	}
	local targetLoc = target:GetAbsOrigin()
	keys.ability:ApplyDataDrivenModifier(caster,target,keys.ModifiersName,{})
	keys.ability:ApplyDataDrivenModifier(caster,target,keys.DebuffName,{})
	UnitDamageTarget(damage_target)
	if FindTelentValue(caster,"special_bonus_unique_utsuho_2") ~= 0 then
		local targets = FindUnitsInRadius(caster:GetTeam(), targetLoc, nil,ability:GetSpecialValueFor("radius"),ability:GetAbilityTargetTeam(),ability:GetAbilityTargetType(),0,0, false)
		if #targets <= 1 then return end
		local hero = nil
		for _,v in pairs(targets) do
			if v ~= target then
				hero = v
				if hero:IsHero() then break end
			end
		end
		damage_target = {
		victim = hero,
		attacker = caster,
		damage = dealdamage,
		damage_type = keys.ability:GetAbilityDamageType(), 
	    damage_flags = 0
		}
		keys.ability:ApplyDataDrivenModifier(caster,hero,keys.ModifiersName,{})
		keys.ability:ApplyDataDrivenModifier(caster,hero,keys.DebuffName,{})
		local effectIndex = ParticleManager:CreateParticle("particles/thd2/heroes/utsuho/ability_utsuho01_effect.vpcf",PATTACH_ABSORIGIN_FOLLOW,hero)
		ParticleManager:ReleaseParticleIndex(effectIndex)
		UnitDamageTarget(damage_target)
	end
end

function OnUtsuho01FireDamage(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local vecCaster = caster:GetOrigin()
	local targets = keys.target_entities
	local dealdamage = keys.AbilityDamage/2 
	for _,v in pairs(targets) do
		local damage_table = {
				ability = keys.ability,
			    victim = v,
			    attacker = caster,
			    damage = dealdamage,
			    damage_type = keys.ability:GetAbilityDamageType(), 
	    	    damage_flags = 0
		}
		UnitDamageTarget(damage_table)
	end
end

function OnUtsuho02SpellStart(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local vecCaster = caster:GetOrigin()
	local targets = keys.target_entities
	local damage = keys.AbilityDamage
	for _,v in pairs(targets) do
		if v:GetTeam() == caster:GetTeam() and not v:IsHero() then 
			damage = damage / 2
		end
		local damage_table = {
			    victim = v,
			    attacker = caster,
			    damage = damage,
			    damage_type = keys.ability:GetAbilityDamageType(), 
	    	    damage_flags = 0
		}
		UnitDamageTarget(damage_table)
	end
end

function OnUtsuho03SpellStart(keys)
	local caster = keys.caster
end

function OnUtsuho03SpellEnd(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local vecCaster = caster:GetOrigin()
	local targets = keys.target_entities
	local dealdamage = keys.AbilityDamage
	local radius = keys.ability:GetSpecialValueFor("radius")
	caster:EmitSound("Hero_Invoker.ChaosMeteor.Impact")
	print("args")
	local utsuho03_particle = ParticleManager:CreateParticle("particles/thd2/heroes/utsuho/ability_utsuho03_effect.vpcf", PATTACH_OVERHEAD_FOLLOW,caster)
	ParticleManager:SetParticleControl(utsuho03_particle, 1, Vector(radius,radius,radius))
	ParticleManager:DestroyParticleSystem(utsuho03_particle,false)
	if FindTelentValue(caster,"special_bonus_unique_utsuho_5")==1 then
		dealdamage=dealdamage+caster:GetMaxHealth()*0.16
	end
	for _,v in pairs(targets) do
		local damage_table = {
				ability = keys.ability,
			    victim = v,
			    attacker = caster,
			    damage = dealdamage,
			    damage_type = keys.ability:GetAbilityDamageType(), 
	    	    damage_flags = 0
		}
		UnitDamageTarget(damage_table)
	end
end

function OnUtsuho04SpellStart(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local targetPoint = keys.target_points[1]
	if caster:HasModifier("modifier_item_wanbaochui") then 
		local targets = FindUnitsInRadius(
					caster:GetTeam(),		
					targetPoint,	
					nil,					
					750,			
					DOTA_UNIT_TARGET_TEAM_ENEMY,
					keys.ability:GetAbilityTargetType(),
					0,
					FIND_CLOSEST,
					false
				)
		for k,v in pairs(targets) do
			keys.ability:ApplyDataDrivenModifier(caster,v,"modifier_thdots_Utsuho04_wanbaochui_debuff",{})
			
		end
	end
	keys.ability.ability_utsuho04_point_x = targetPoint.x
	keys.ability.ability_utsuho04_point_y = targetPoint.y
	keys.ability.ability_utsuho04_point_z = targetPoint.z
	keys.ability.ability_utsuho04_timer_count = 0
	local dummy = CreateUnitByName("npc_dummy_unit", 
	    	                        targetPoint, 
									false, 
								    caster, 
									caster, 
									caster:GetTeamNumber()
									)
									local ability_dummy_unit = dummy:FindAbilityByName("ability_dummy_unit")
									ability_dummy_unit:SetLevel(1)
	caster.ability_utsuho_04_dummy = dummy
	dummy:SetContextThink("ability_utsuho04_effect_release",
		function ()
			if GameRules:IsGamePaused() then return 0.03 end
			dummy:RemoveSelf() 
		end,
	7.5)
	local effectIndex = ParticleManager:CreateParticle("particles/thd2/heroes/utsuho/ability_utsuho04_effect.vpcf", PATTACH_CUSTOMORIGIN, dummy)
	ParticleManager:SetParticleControl(effectIndex, 0, targetPoint)
	ParticleManager:SetParticleControl(effectIndex, 1, targetPoint)
	ParticleManager:SetParticleControl(effectIndex, 3, targetPoint)
	keys.ability.ability_utsuho04_effect_index = effectIndex
end

function OnUtsuho04SpellThink(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local tx = keys.ability.ability_utsuho04_point_x
	local ty = keys.ability.ability_utsuho04_point_y
	local tz = keys.ability.ability_utsuho04_point_z
	local targetPoint = Vector(tx,ty,tz)
	local Gravity=keys.Gravity
	if caster:HasModifier("modifier_item_wanbaochui") then
		Gravity=Gravity*1.4
	end
	local targets = FindUnitsInRadius(
		   caster:GetTeam(),		--caster team
		   targetPoint,				--find position
		   nil,						--find entity
		   keys.Radius,				--find radius
		   DOTA_UNIT_TARGET_TEAM_ENEMY,
		   keys.ability:GetAbilityTargetType(),
		   0, FIND_CLOSEST,
		   false
	)
	
	local count = keys.ability.ability_utsuho04_timer_count
	keys.ability.ability_utsuho04_timer_count = count+0.1

	for _,v in pairs(targets) do
		local dis = GetDistanceBetweenTwoVec2D(targetPoint,v:GetOrigin())* (1 - v:GetStatusResistance())
		if(dis<keys.DamageRadius and (v:GetClassname()~="npc_dota_roshan"))then
			local damage_table = {
				ability = keys.ability,
			    victim = v,
			    attacker = caster,
			    damage = keys.Damage/10,
			    damage_type = keys.ability:GetAbilityDamageType(), 
	    	    damage_flags = 0
			}
			UnitDamageTarget(damage_table)
		end
		if v and not v:IsNull() then
			local rad = GetRadBetweenTwoVec2D(targetPoint,v:GetOrigin())
			if(dis>=(Gravity/10))then
				v:SetOrigin(v:GetOrigin() - Gravity/10 * Vector(math.cos(rad),math.sin(rad),0))
				SetTargetToTraversable(v)
			end
		end
	end
end


function OnUtsuho04SpellRemove(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	--local targets = keys.target_entities
	local radius = keys.ability:GetSpecialValueFor("radius")
	local count = keys.ability.ability_utsuho04_timer_count
	local effectIndex = keys.ability.ability_utsuho04_effect_index 
	local tx = keys.ability.ability_utsuho04_point_x
	local ty = keys.ability.ability_utsuho04_point_y
	local tz = keys.ability.ability_utsuho04_point_z
	local targetPoint = Vector(tx,ty,tz)
	ParticleManager:DestroyParticleSystem(effectIndex,true)
	if(caster.ability_utsuho_04_dummy~=nil)then
		effectIndex = ParticleManager:CreateParticle("particles/thd2/heroes/utsuho/ability_utsuho04_end.vpcf", PATTACH_CUSTOMORIGIN, caster.ability_utsuho_04_dummy)
	else
		effectIndex = ParticleManager:CreateParticle("particles/thd2/heroes/utsuho/ability_utsuho04_end.vpcf", PATTACH_CUSTOMORIGIN, caster)
	end

	ParticleManager:SetParticleControl(effectIndex, 0, targetPoint)
	ParticleManager:SetParticleControl(effectIndex, 1, targetPoint)
	ParticleManager:SetParticleControl(effectIndex, 3, targetPoint)
	ParticleManager:DestroyParticleSystem(effectIndex,false)
	caster.ability_utsuho_04_dummy:SetContextThink("ability_utsuho04_effect_remove",
		function ()
			if GameRules:IsGamePaused() then return 0.03 end
			caster.ability_utsuho_04_dummy:RemoveSelf() 
		end,
	1.0)
	local dealdamage = keys.ability:GetAbilityDamage() * (count/6.5)
	local targets = FindUnitsInRadius(
	   caster:GetTeam(),		--caster team
	   targetPoint,				--find position
	   nil,						--find entity
	   radius,				--find radius
	   DOTA_UNIT_TARGET_TEAM_ENEMY,
	   keys.ability:GetAbilityTargetType(),
	   0, FIND_CLOSEST,
	   false
	)
	for _,v in pairs(targets) do
		local damage_table = {
				ability = keys.ability,
			    victim = v,
			    attacker = caster,
			    damage = dealdamage,
			    damage_type = keys.ability:GetAbilityDamageType(), 
	    	    damage_flags = 0
		}
		UnitDamageTarget(damage_table)
		if v and not v:IsNull() then
			SetTargetToTraversable(v)
		end
	end
end