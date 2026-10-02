function IsCreep(unit)
	if unit==nil or unit:IsNull() then
		return false
	end
	if unit:GetClassname() == "npc_dota_creep_lane" then 
		return true 
	end
	if unit:GetClassname() == "npc_dota_creep_siege" then 
		return true 
	end
	return false
end

function OnCheckNearby(keys)
	local caster=keys.caster
	local radius = keys.Radius
	local units = FindUnitsInRadius(
				   caster:GetTeam(),						--caster team
				   caster:GetOrigin(),							--find position
				   nil,										--find entity
				   radius,						--find radius
				   DOTA_UNIT_TARGET_TEAM_ENEMY,
				   keys.ability:GetAbilityTargetType(),
				   DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST,
				   false
			    )
	local attackable = false
	for _,v in pairs(units) do
		if IsCreep(v) and v:HasModifier("modifier_thdots_unit_anti_bd")==false then 
			attackable = true
			break
		elseif caster:HasModifier("modifier_thdots_anti_bd_stop") and v:IsRealHero() then 
			attackable = true
			break
		end
	end
	if attackable then
		keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_thdots_anti_bd_stop", {})
		caster:RemoveModifierByName("modifier_thdots_anti_bd_active")
	elseif caster:HasModifier("modifier_thdots_anti_bd_active") == false then
		keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_thdots_anti_bd_active", {})
	end
end
