if AbilityMokou == nil then
	AbilityMokou = class({})
end

function OnMokouKill(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local ability1 = caster:FindAbilityByName("ability_thdots_mokou01")
	local ability2 = caster:FindAbilityByName("ability_thdots_mokouEx")
	
	if caster:HasModifier("modifier_item_wanbaochui") and keys.unit:IsHero()==true and keys.unit:HasModifier("modifier_illusion")==false then
		ability1:EndCooldown()
		ability2:EndCooldown()
	end
end


function OnMokou01SpellStart(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)

	local targetPoint = keys.target_points[1]
	local Mokou01rad = GetRadBetweenTwoVec2D(caster:GetOrigin(),targetPoint)
	local Mokou01Distance = GetDistanceBetweenTwoVec2D(caster:GetOrigin(),targetPoint)
	keys.ability.ability_Mokou01_Rad = Mokou01rad
	keys.ability.ability_Mokou01_Distance = Mokou01Distance
end

function OnMokou01SpellMove(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local vecCaster = caster:GetOrigin()
 

	local targets = keys.target_entities

	local damageenemy=(keys.ability:GetAbilityDamage()+FindTelentValue(caster,"special_bonus_unique_mokou_3"))
	local damageself=(keys.ability:GetAbilityDamage()+FindTelentValue(caster,"special_bonus_unique_mokou_3"))
	local wanbaochui=(keys.ability:GetSpecialValueFor("damage_wanbaochui"))

	if caster:HasModifier("modifier_item_wanbaochui") then
		damageself = damageself+caster:GetMaxHealth() * wanbaochui * 0.01
		damageenemy = damageenemy+caster:GetMaxHealth() * wanbaochui * 0.01
	end
	if caster:HasModifier("modifier_thdots_Mokou_ex") == true then
		damageenemy = damageenemy / 2
		damageself  = damageself * 2
	end
	
	if(keys.ability.ability_Mokou01_Distance<30)then
		
		for _,v in pairs(targets) do

			local damage_table = {
				ability = keys.ability,
				victim = v,
				attacker = caster,
				damage = damageenemy,
				damage_type = keys.ability:GetAbilityDamageType(), 
				damage_flags = keys.ability:GetAbilityTargetFlags()
			}
			UnitDamageTarget(damage_table)
		end
		local damage_table = {
			ability = keys.ability,
			victim = caster,
			attacker = caster,
			damage = damageself,
			damage_type = keys.ability:GetAbilityDamageType(), 
			damage_flags = keys.ability:GetAbilityTargetFlags()
		}
		--print(damageself)
		UnitDamageTarget(damage_table)
		caster:RemoveModifierByName("modifier_thdots_Mokou_ex")
		local effectIndex = ParticleManager:CreateParticle("particles/heroes/mouko/ability_mokou_01_boom.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(effectIndex, 0, caster:GetOrigin())
		ParticleManager:SetParticleControl(effectIndex, 1, caster:GetOrigin())
		ParticleManager:SetParticleControl(effectIndex, 3, caster:GetOrigin())
		ParticleManager:DestroyParticleSystem(effectIndex,false)
		
		caster:SetUnitOnClearGround()
		vecCaster = caster:GetOrigin()
		caster:RemoveModifierByName("modifier_thdots_Mokou01_think_interval")
		keys.ability.ability_Mokou01_Distance = 120
		caster:EmitSound("Voice_Thdots_Mokou.AbilityMokou01")
	else
		local distance = keys.ability.ability_Mokou01_Distance
		distance = distance - keys.MoveSpeed/50
		keys.ability.ability_Mokou01_Distance = distance
		local Mokou01rad = keys.ability.ability_Mokou01_Rad
		local vec = Vector(vecCaster.x+math.cos(Mokou01rad)*keys.MoveSpeed/50,vecCaster.y+math.sin(Mokou01rad)*keys.MoveSpeed/50,GetGroundPosition(vecCaster, nil).z)
		caster:SetOrigin(vec)
	end	
end


function OnMokou02SpellStartUnit(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local target = keys.target

	if(target.ability_Mokou02_speed_increase==nil)then
		target.ability_Mokou02_speed_increase = 0
	end
	local increaseSpeedCount = target.ability_Mokou02_speed_increase
	increaseSpeedCount = increaseSpeedCount + keys.IncreaseSpeed
	--[[if(increaseSpeedCount>keys.IncreaseMaxSpeed)then
		target:RemoveModifierByName("modifier_mokou02_speed_up")
	else
		target.ability_Mokou02_speed_increase = increaseSpeedCount
		target:SetThink(
			function()
				target:RemoveModifierByName("modifier_flandre02_slow")
				local decreaseSpeedNow = target.ability_Mokou02_speed_increase - keys.IncreaseSpeed
				target.ability_Mokou02_speed_increase = decreaseSpeedNow	
			end, 
			DoUniqueString("ability_flandre02_speed_increase_duration"), 
			keys.Duration
		)	
	end]]
end

function OnMokou02Created(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_mokou02_speed_up_counter",{})
	local counter = keys.caster:FindModifierByName("modifier_mokou02_speed_up_counter")
	counter:IncrementStackCount()
end

function OnMokou02Destory(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local counter = keys.caster:FindModifierByName("modifier_mokou02_speed_up_counter")

	if counter then
		counter:DecrementStackCount()
	end
end

function OnMokou02DamageStart(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local vecCaster = caster:GetOrigin()
	local targets = keys.target_entities

	if(caster.ability_Mokou02_damage_bouns==nil)then
		caster.ability_Mokou02_damage_bouns = 0
	end

	local effectIndex = ParticleManager:CreateParticle("particles/thd2/heroes/mouko/ability_mokou_02_boom.vpcf", PATTACH_CUSTOMORIGIN, caster)
	if(targets[1]~=nil)then
		ParticleManager:SetParticleControl(effectIndex, 0, targets[1]:GetOrigin())
		ParticleManager:SetParticleControl(effectIndex, 1, Vector(300,0,0))
		ParticleManager:DestroyParticleSystem(effectIndex,false)
	end

	for _,v in pairs(targets) do
		local dealdamage = keys.BounsDamage + caster.ability_Mokou02_damage_bouns 
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

function OnMokou04SpellStart(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local dealdamage = caster:GetHealth() * keys.CostHp * 0.01
	local damage_table = {
				ability = keys.ability,
			    victim = caster,
			    attacker = caster,
			    damage = dealdamage,
			    damage_type = keys.ability:GetAbilityDamageType(),
	    	    damage_flags = 0
	}
	if FindTelentValue(caster,"special_bonus_unique_mokou_1") == 0 then
		UnitDamageTarget(damage_table)
	end

	--[[local unit = CreateUnitByName(
		"npc_dota2x_unit_mokou_04"
		,caster:GetOrigin() - caster:GetForwardVector() * 15 + Vector(0,0,170)
		,false
		,caster
		,caster
		,caster:GetTeam()
	)
	unit:SetForwardVector(caster:GetForwardVector())]]

	caster.ability_Mokou02_damage_bouns = keys.BounsDamage
	Timer.Wait 'ability_Mokou02_damage_bouns_timer' (20,
		function()
			caster.ability_Mokou02_damage_bouns = 0
		end
	)

	local effectIndex = ParticleManager:CreateParticle("particles/thd2/heroes/mouko/ability_mokou_04_wing.vpcf", PATTACH_CUSTOMORIGIN, caster) 
	ParticleManager:SetParticleControlEnt(effectIndex , 0, caster, 5, "follow_origin", Vector(0,0,0), true)

	Timer.Wait 'ability_mokou_04_wing_destory' (20,
			function()
				ParticleManager:DestroyParticle(effectIndex,true)
			end
		)


	--[[Timer.Loop 'ability_Mokou04_wing_timer' (0.1, 200,
		function(i)
			unit:SetOrigin(caster:GetOrigin() - caster:GetForwardVector() * 15 + Vector(0,0,170))
			unit:SetForwardVector(caster:GetForwardVector())
			if(caster:IsAlive()==false)then
				unit:RemoveSelf()
				return nil
			end
		end
	)
	unit:SetContextThink('ability_Mokou04_wing_unit_timer',
		function()
			unit:RemoveSelf()
			return nil
		end, 
	20.5)]]
end

function OnMokouExSpellStart(keys)
	local caster = keys.caster
	local ability = nil
	ability = caster:FindAbilityByName("ability_thdots_mokou01")
	if ability~=nil then
		ability:EndCooldown()
	end
end
-- 重写最初的不死鸟
ability_thdots_mokou03 = {}
LinkLuaModifier( "modifier_phenx_egg_caster", "scripts/vscripts/abilities/abilityMokou.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_phenx_egg_form", "scripts/vscripts/abilities/abilityMokou.lua", LUA_MODIFIER_MOTION_NONE )

function ability_thdots_mokou03:IsStealable()
    return true
end

function ability_thdots_mokou03:IsHiddenWhenStolen()
    return false
end

function ability_thdots_mokou03:GetBehavior()
	return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_ATTACK + DOTA_ABILITY_BEHAVIOR_UNRESTRICTED
end

function ability_thdots_mokou03:OnSpellStart()
    local caster = self:GetCaster()
	
    EmitSoundOn("Hero_Phoenix.SuperNova.Cast", caster)

	local egg = CreateUnitByName("npc_dota_phoenix_sun", caster:GetAbsOrigin(), true, caster, nil, caster:GetTeam())
	local duration = self:GetSpecialValueFor("duration")
	local hp = self:GetSpecialValueFor("max_hero_attacks")
	egg:SetBaseMaxHealth(hp)
	egg:SetMaxHealth(hp)
	egg:SetHealth(hp)
    egg:AddNewModifier(caster, self, "modifier_phenx_egg_form", {Duration = duration})
    caster:AddNewModifier(caster, self, "modifier_phenx_egg_caster", {Duration = duration})
    EmitSoundOn("Hero_Phoenix.SuperNova.Begin", egg)
end

modifier_phenx_egg_caster = class({})
function modifier_phenx_egg_caster:OnCreated(table)
    if IsServer() then
        self:GetParent():AddNoDraw()
    end
end

function modifier_phenx_egg_caster:OnRemoved()
    if IsServer() then
        self:GetParent():RemoveNoDraw()
        self:GetParent():StartGesture(ACT_DOTA_INTRO)
    end
end

function modifier_phenx_egg_caster:CheckState()
    local state = { [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
					[MODIFIER_STATE_INVULNERABLE] = true,
					[MODIFIER_STATE_NO_HEALTH_BAR] = true,
					[MODIFIER_STATE_UNTARGETABLE] = true,
                    [MODIFIER_STATE_OUT_OF_GAME] = true,
					[MODIFIER_STATE_DISARMED] = true,
                    [MODIFIER_STATE_SILENCED] = true
                }
    return state
end

modifier_phenx_egg_form = class({})

function modifier_phenx_egg_form:OnCreated(table)
    if IsServer() then
        self.nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_supernova_egg.vpcf", PATTACH_POINT_FOLLOW, self:GetParent())
        ParticleManager:SetParticleControlEnt(self.nfx, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), false)
        ParticleManager:SetParticleControlEnt(self.nfx, 1, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), false)

        self.maxAttacks = self:GetAbility():GetSpecialValueFor("max_hero_attacks")
		self:GetParent().supernova_numAttacked = 0
        self:StartIntervalThink(0.5)
    end
end

function modifier_phenx_egg_form:OnIntervalThink()
	local egg = self:GetParent()
	local caster = self:GetCaster()
	
    GridNav:DestroyTreesAroundPoint(egg:GetAbsOrigin(), self:GetAbility():GetSpecialValueFor("radius"), false)
	
end

function modifier_phenx_egg_form:CheckState()
    local state = { [MODIFIER_STATE_ROOTED] = true,
                    [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                    [MODIFIER_STATE_FLYING] = true,
                }
    return state
end

function modifier_phenx_egg_form:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DISABLE_HEALING,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_PROPERTY_HEALTHBAR_PIPS,
    }
end

function modifier_phenx_egg_form:GetDisableHealing()
    return 1
end


function modifier_phenx_egg_form:GetModifierIncomingDamage_Percentage(params)
	local form_particel = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_supernova_hit.vpcf", PATTACH_POINT, params.target)
	ParticleManager:ReleaseParticleIndex(form_particel)
	
	local egg = self:GetParent()
	local attacker = params.attacker
	if not attacker:IsRealHero() then
		return -100
	end
	self.attacker = attacker
	local numAttacked = egg.supernova_numAttacked or 0
	local damage = 1
	numAttacked = numAttacked + damage
	egg.supernova_numAttacked = numAttacked

	if numAttacked >= self.maxAttacks then
		-- Now the egg has been killed.
		egg.supernova_lastAttacker = attacker
		egg:RemoveModifierByName("modifier_phenx_egg_form")
		egg:ForceKill(true)
	else
		egg:SetHealth( egg:GetHealth() - damage )
	end
	return -100
end

function modifier_phenx_egg_form:GetModifierHealthBarPips()
	return self:GetParent():GetMaxHealth()
end

function modifier_phenx_egg_form:OnRemoved()
    if IsServer() then
		local egg = self:GetParent()
        local caster = self:GetCaster()
        local ability = self:GetAbility()

        ParticleManager:DestroyParticle(self.nfx, false)
		caster:RemoveModifierByName("modifier_phenx_egg_caster")
        local isDead = egg.supernova_numAttacked >= self.maxAttacks
        if isDead then
			caster:Kill(self:GetAbility(), self.attacker)
        else
			caster:SetHealth( caster:GetMaxHealth() )
			caster:SetMana( caster:GetMaxMana() )
			-- 驱散
			caster:Purge(false, true, false, true, true)
        end

        -- Play sound effect
        local soundName = "Hero_Phoenix.SuperNova." .. ( isDead and "Death" or "Explode" )
        StartSoundEvent( soundName, caster )

        -- Create particle effect
        local pfxName = "particles/units/heroes/hero_phoenix/phoenix_supernova_" .. ( isDead and "death" or "reborn" ) .. ".vpcf"
        local pfx = ParticleManager:CreateParticle( pfxName, PATTACH_ABSORIGIN, caster )
        ParticleManager:SetParticleControlEnt( pfx, 0, caster, PATTACH_POINT_FOLLOW, "follow_origin", caster:GetAbsOrigin(), true )
        ParticleManager:SetParticleControlEnt( pfx, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true )
		ResolveNPCPositions(egg:GetAbsOrigin(), 9000)
        -- Remove the egg
        egg:ForceKill( false )
        egg:AddNoDraw()
    end
end

function modifier_phenx_egg_form:IsAura()
    return true
end

function modifier_phenx_egg_form:GetAuraDuration()
    return 0.5
end

function modifier_phenx_egg_form:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_phenx_egg_form:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_phenx_egg_form:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_phenx_egg_form:GetAuraSearchType()
    return DOTA_UNIT_TARGET_ALL
end

function modifier_phenx_egg_form:IsAuraActiveOnDeath()
    return false
end