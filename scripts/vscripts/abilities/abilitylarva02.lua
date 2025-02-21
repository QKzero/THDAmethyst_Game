----------------天生技能---------------------
ability_thdots_larva02_ex = {}
function ability_thdots_larva02_ex:GetIntrinsicModifierName()
	return "modifier_ability_thdots_larva02_ex"
end
modifier_ability_thdots_larva02_ex = {}
LinkLuaModifier("modifier_ability_thdots_larva02_ex","scripts/vscripts/abilities/abilitylarva02.lua",MODIFIER_ATTRIBUTE_MULTIPLE)
function modifier_ability_thdots_larva02_ex:IsHidden() 		return true end     --是否隐藏
function modifier_ability_thdots_larva02_ex:IsPurgable()     return false end     --是否可净化
function modifier_ability_thdots_larva02_ex:RemoveOnDeath() 	return true  end     --死亡移除
function modifier_ability_thdots_larva02_ex:IsDebuff()	   	return false end     --是否是DEBUFF
function modifier_ability_thdots_larva02_ex:IsPassive() return true end   --是否是被动


-- modifier 光环判定
function modifier_ability_thdots_larva02_ex:IsAura() return true end
function modifier_ability_thdots_larva02_ex:GetAuraEntityReject(hEntity) 
	if self:GetParent():PassivesDisabled() then return true
	else return false
	end
end
function modifier_ability_thdots_larva02_ex:GetAuraRadius() 
	local auraRangeRadius = self:GetAbility():GetSpecialValueFor("auraRangeRadius")
	return auraRangeRadius
end
function modifier_ability_thdots_larva02_ex:GetAuraSearchTeam() return self:GetAbility():GetAbilityTargetTeam() end
function modifier_ability_thdots_larva02_ex:GetAuraSearchType() return self:GetAbility():GetAbilityTargetType() end
function modifier_ability_thdots_larva02_ex:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NONE end
function modifier_ability_thdots_larva02_ex:GetModifierAura() return "modifier_ability_thdots_larva02_ex_target" end
modifier_ability_thdots_larva02_ex_target = {}
LinkLuaModifier("modifier_ability_thdots_larva02_ex_target","scripts/vscripts/abilities/abilitylarva02.lua",MODIFIER_ATTRIBUTE_MULTIPLE)
function modifier_ability_thdots_larva02_ex_target:GetTexture() return "custom/ability_thdots_larva02" end
function modifier_ability_thdots_larva02_ex_target:IsHidden() return true end
function modifier_ability_thdots_larva02_ex_target:IsDebuff() return true end
function modifier_ability_thdots_larva02_ex_target:IsPurgable() return false end
function modifier_ability_thdots_larva02_ex_target:IsPurgeException() return false end
function modifier_ability_thdots_larva02_ex_target:RemoveOnDeath() return true end

function modifier_ability_thdots_larva02_ex_target:OnCreated()
	if not IsServer() then return end
	self.duration = self:GetAbility():GetSpecialValueFor("duration")
	self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("think_time"))
end
function modifier_ability_thdots_larva02_ex_target:OnIntervalThink()
	if not IsServer() then return end
	local ability = self:GetAbility()
	local parent = self:GetParent()
	local caster = self:GetCaster()
	--施法者为幻象在幻象消失后继续叠加会有错误，因为施法者已经被移除游戏
	if caster:IsIllusion() == true then caster = self:GetCaster():GetOwner():GetAssignedHero() end
	--检测目标为活才能不报错
	if parent:IsAlive() == true then
	  if parent:HasModifier("modifier_ability_thdots_larva02_ex_debuff") ~= true then
	   parent:AddNewModifier(caster, ability, "modifier_ability_thdots_larva02_ex_debuff", {Duration = self.duration}):SetStackCount(1)
	  else
		local stackcount = parent:FindModifierByName("modifier_ability_thdots_larva02_ex_debuff"):GetStackCount()
		parent:FindModifierByName("modifier_ability_thdots_larva02_ex_debuff"):SetStackCount(stackcount + self:GetAbility():GetSpecialValueFor("persecond_stack"))
	  end
	  parent:FindModifierByName("modifier_ability_thdots_larva02_ex_debuff"):SetDuration(self.duration, true)
	end
end
------debuff
modifier_ability_thdots_larva02_ex_debuff = {}
LinkLuaModifier("modifier_ability_thdots_larva02_ex_debuff","scripts/vscripts/abilities/abilitylarva02.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_larva02_ex_debuff:GetTexture() return "custom/ability_thdots_larva02" end
function modifier_ability_thdots_larva02_ex_debuff:IsHidden() 		return false end     --是否隐藏
function modifier_ability_thdots_larva02_ex_debuff:IsPurgable()     return false end     --是否可净化
function modifier_ability_thdots_larva02_ex_debuff:RemoveOnDeath() 	return true  end     --死亡移除
function modifier_ability_thdots_larva02_ex_debuff:IsDebuff()	   	return true end     --是否是DEBUFF
function modifier_ability_thdots_larva02_ex_debuff:DeclareFunctions() return
    {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
end
function modifier_ability_thdots_larva02_ex_debuff:OnCreated()
	if not IsServer() then return end
	self.ability = self:GetAbility()
	self.caster = self:GetCaster()
	if  self.caster:IsIllusion() == true 
	    then self.caster = self.caster:GetOwner():GetAssignedHero() 
	end
	self.ability01 = self.caster:FindAbilityByName("ability_thdots_larva02_01")
	self.ability03 = self.caster:FindAbilityByName("ability_thdots_larva02_03")
	self:StartIntervalThink(1)
end
function modifier_ability_thdots_larva02_ex_debuff:GetModifierAttackSpeedBonus_Constant()
	self.ability = self:GetAbility()
	self.caster = self:GetCaster()
	if  self.caster:IsIllusion() == true 
	    then self.caster = self.caster:GetOwner():GetAssignedHero() 
	end
	return -self.caster:FindAbilityByName("ability_thdots_larva02_ex"):GetSpecialValueFor("attackspeed")*self:GetStackCount()
end
function modifier_ability_thdots_larva02_ex_debuff:GetModifierMoveSpeedBonus_Percentage()
	self.ability = self:GetAbility()
	self.caster = self:GetCaster()
	if  self.caster:IsIllusion() == true 
	    then self.caster = self.caster:GetOwner():GetAssignedHero() 
	end
	self.ability01 = self.caster:FindAbilityByName("ability_thdots_larva02_01")
	if self.ability01:GetLevel() == 0 then return end
	if self:GetStackCount() <= self.ability01:GetSpecialValueFor("max_speed_down_stack") then return -self.ability01:GetSpecialValueFor("speed_down")*self:GetStackCount()
	else return -self.ability01:GetSpecialValueFor("speed_down")*self.ability01:GetSpecialValueFor("max_speed_down_stack")
	end
end
function modifier_ability_thdots_larva02_ex_debuff:OnIntervalThink() 
	if self.ability03:GetLevel() == 0 then return end
	local damage = self.ability03:GetSpecialValueFor("stack_damage")*self:GetStackCount()
	local damage_table = {
		victim 			= self:GetParent(),
		damage          = damage,
		damage_type		= self.ability03:GetAbilityDamageType(),
		damage_flags 	= self.ability03:GetAbilityTargetFlags(),
		attacker 		= self.caster,
		ability 		= self:GetAbility(),
	}
	SendOverheadEventMessage(nil,OVERHEAD_ALERT_BONUS_POISON_DAMAGE,self:GetParent(),damage,nil)
    ApplyDamage(damage_table)
end
----------------1技能---------------------
ability_thdots_larva02_01 = {}
function ability_thdots_larva02_01:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor("duration")
    caster:AddNewModifier(caster, self, "modifier_ability_thdots_larva02_01_buff",{Duration = duration})
	ParticleManager:CreateParticle("particles/units/heroes/hero_brewmaster/brewmaster_windwalk.vpcf", PATTACH_ABSORIGIN_FOLLOW,caster)
    caster:EmitSound("Hero_Dark_Seer.Surge")
end
function ability_thdots_larva02_01:GetCooldown(level)
	local cd = self.BaseClass.GetCooldown(self, level)
	local telent = self:GetCaster():FindAbilityByName("special_bonus_unique_larva_02_1_1")
	if telent then
		cd = cd - telent:GetSpecialValueFor("value")
	end
	return cd
end
modifier_ability_thdots_larva02_01_buff = {}
LinkLuaModifier("modifier_ability_thdots_larva02_01_buff","scripts/vscripts/abilities/abilitylarva02.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_larva02_01_buff:IsHidden() 		return false end     --是否隐藏
function modifier_ability_thdots_larva02_01_buff:IsPurgable()     return true end     --是否可净化
function modifier_ability_thdots_larva02_01_buff:RemoveOnDeath() 	return true  end     --死亡移除
function modifier_ability_thdots_larva02_01_buff:IsDebuff()	   	return false end     --是否是DEBUFF
function modifier_ability_thdots_larva02_01_buff:DeclareFunctions() return
    {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		-- MODIFIER_STATE_DISARMED,
		-- MODIFIER_PROPERTY_MOVESPEED_LIMIT,
    }
end
function modifier_ability_thdots_larva02_01_buff:CheckState()
    local state = {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_FLYING] = true,
    }
	return state
end
function modifier_ability_thdots_larva02_01_buff:GetModifierMoveSpeedBonus_Percentage() 
	return self:GetAbility():GetSpecialValueFor("speed_up")
end
function modifier_ability_thdots_larva02_01_buff:GetEffectName()
	return "particles/units/heroes/hero_dark_seer/dark_seer_surge.vpcf"
end

function modifier_ability_thdots_larva02_01_buff:OnCreated()
	if not IsServer() then return end
	if self:GetParent():FindAbilityByName("special_bonus_unique_larva_02_1_1"):GetLevel() == 0 then return end
	self:StartIntervalThink(0.2)
end
function modifier_ability_thdots_larva02_01_buff:OnIntervalThink()
	if not IsServer() then return end
	AddFOWViewer(self:GetParent():GetTeamNumber(), self:GetParent():GetAbsOrigin(), self:GetParent():GetBaseDayTimeVisionRange() , 0.25, false)
end
function modifier_ability_thdots_larva02_01_buff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
function modifier_ability_thdots_larva02_01_buff:OnDestroy()
	if not IsServer() then return end
	local ability = self:GetAbility()
	local caster = self:GetAbility():GetCaster()
	local target = self:GetParent()
    local radius = self:GetAbility():GetSpecialValueFor("radius")
    local base_duration = self:GetAbility():GetCaster():FindAbilityByName("ability_thdots_larva02_ex"):GetSpecialValueFor("duration")
	local duration = self:GetAbility():GetSpecialValueFor("duration")
	local pfx_name        = "particles/econ/items/faceless_void/faceless_void_bracers_of_aeons/fv_bracers_of_aeons_red_timedialate.vpcf"
	local pfx = ParticleManager:CreateParticle(pfx_name, PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(pfx, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(pfx, 1, Vector(100, 100, 100))

	local heros = FindUnitsInRadius(caster:GetTeamNumber(),caster:GetAbsOrigin(),nil,radius,ability:GetAbilityTargetTeam(),ability:GetAbilityTargetType(),0,0,false)
            for _,v in pairs(heros) do
            	if  v:HasModifier("modifier_ability_thdots_larva02_ex_debuff") ~= true then
					v:AddNewModifier(caster, ability, "modifier_ability_thdots_larva02_ex_debuff", {Duration = base_duration})
					v:FindModifierByName("modifier_ability_thdots_larva02_ex_debuff"):SetStackCount(self:GetAbility():GetSpecialValueFor("stack_get"))
				else
					local stackcount = v:FindModifierByName("modifier_ability_thdots_larva02_ex_debuff"):GetStackCount()
					v:FindModifierByName("modifier_ability_thdots_larva02_ex_debuff"):SetStackCount(stackcount + self:GetAbility():GetSpecialValueFor("stack_get"))
				end
		    end
	caster:EmitSound("larva02")
end
----------------2技能---------------------
ability_thdots_larva02_02 = {}
--被动
function ability_thdots_larva02_02:GetIntrinsicModifierName()
    return "modifier_ability_thdots_larva02_02_heal"
end

modifier_ability_thdots_larva02_02_heal={}
LinkLuaModifier("modifier_ability_thdots_larva02_02_heal","scripts/vscripts/abilities/abilitylarva02.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_larva02_02_heal:IsHidden() 		return true end
function modifier_ability_thdots_larva02_02_heal:IsPurgable()		return false end
function modifier_ability_thdots_larva02_02_heal:RemoveOnDeath() 	return true end
function modifier_ability_thdots_larva02_02_heal:IsDebuff()		return false end
function modifier_ability_thdots_larva02_02_heal:IsPassive() return true end   --是否是被动

function modifier_ability_thdots_larva02_02_heal:DeclareFunctions() return
    {
        MODIFIER_EVENT_ON_TAKEDAMAGE,
    }
end
function modifier_ability_thdots_larva02_02_heal:OnTakeDamage(keys)
	if not IsServer() then return end
	local caster = self:GetCaster()
	local parent  = self:GetParent()
    local ability = self:GetAbility()
	local heal_stack  = ability:GetSpecialValueFor("heal_stack")
	local telent_heal_stack = self:GetCaster():FindAbilityByName("special_bonus_unique_larva_02_2_2")
	if caster:FindAbilityByName("special_bonus_unique_larva_02_2_2"):GetLevel() ~= 0 then heal_stack = heal_stack + telent_heal_stack:GetSpecialValueFor("value") end
    -- local lf_stack = keys.attacker:FindModifierByName("modifier_ability_thdots_larva02_ex_debuff"):GetStackCount()
    if parent == keys.unit and keys.attacker:HasModifier("modifier_ability_thdots_larva02_ex_debuff") then 
        if parent:GetContext("ability_yuyuko_Ex_deadflag") == TRUE then return end
		local heal = math.max(keys.damage, 0) * ability:GetSpecialValueFor("heal_stack") * keys.attacker:FindModifierByName("modifier_ability_thdots_larva02_ex_debuff"):GetStackCount() * 0.01
        parent:Heal(heal, keys.unit)
		SendOverheadEventMessage(nil,OVERHEAD_ALERT_HEAL,self:GetParent(),heal,nil)
    end
end
--主动
function ability_thdots_larva02_02:OnSpellStart()
	if not IsServer() then return end
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")
    local caster_point = caster:GetAbsOrigin()
	caster:AddNewModifier(caster, self, "modifier_ability_thdots_larva02_02_start", {Duration = duration})
    self.dream = ParticleManager:CreateParticle("particles/units/larva/larva04.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    --self.dream_aura = ParticleManager:CreateParticle("particles/heroes/misc/aura_circle_common.vpcf", PATTACH_CUSTOMORIGIN,nil)
	--ParticleManager:SetParticleControl(self.dream_aura, 0, point)
	--ParticleManager:SetParticleControl(self.dream_aura, 1, Vector(range,0,0))
	--ParticleManager:SetParticleControl(self.dream_aura, 2, Vector(duration-0.5,0,0))
	--ParticleManager:SetParticleControl(self.dream_aura, 3, Vector(221,160,221))
	ParticleManager:DestroyParticleSystemTime(self.dream,duration+1)
    caster:EmitSound("larva04")
end

modifier_ability_thdots_larva02_02_start = {}
LinkLuaModifier("modifier_ability_thdots_larva02_02_start","scripts/vscripts/abilities/abilitylarva02.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_larva02_02_start:IsHidden() 		return true end     --是否隐藏
function modifier_ability_thdots_larva02_02_start:IsPurgable()     return false end     --是否可净化
function modifier_ability_thdots_larva02_02_start:RemoveOnDeath() 	return true  end     --死亡移除
function modifier_ability_thdots_larva02_02_start:IsDebuff()	   	return false end     --是否是DEBUFF
function modifier_ability_thdots_larva02_02_start:GetAttributes()	return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_ability_thdots_larva02_02_start:OnCreated()
	if not IsServer() then return end
	local ability = self:GetAbility()
	local caster = self:GetAbility():GetCaster()
	local target = self:GetParent()
    local radius = self:GetAbility():GetSpecialValueFor("AbilityCastRange")
	local duration = self:GetAbility():GetSpecialValueFor("duration")
	local heros = FindUnitsInRadius(caster:GetTeamNumber(),caster:GetAbsOrigin(),nil,radius,ability:GetAbilityTargetTeam(),ability:GetAbilityTargetType(),0,0,false)
            for _,v in pairs(heros) do
            	v:AddNewModifier(target,self:GetAbility(),"modifier_ability_thdots_larva02_02_debuff",{duration = duration})
            end
end
modifier_ability_thdots_larva02_02_debuff = {}
LinkLuaModifier("modifier_ability_thdots_larva02_02_debuff","scripts/vscripts/abilities/abilitylarva02.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_larva02_02_debuff:IsHidden() 		return false end     --是否隐藏
function modifier_ability_thdots_larva02_02_debuff:IsPurgable()     return true end     --是否可净化
function modifier_ability_thdots_larva02_02_debuff:RemoveOnDeath() 	return true  end     --死亡移除
function modifier_ability_thdots_larva02_02_debuff:IsDebuff()	   	return true end     --是否是DEBUFF

function modifier_ability_thdots_larva02_02_debuff:OnCreated()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local target = self:GetParent()
    self.larvaline = ParticleManager:CreateParticle("particles/units/larva/larva04line.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(self.larvaline , 0, caster, 5, "attach_hitloc", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(self.larvaline , 1, target, 5, "attach_hitloc", target:GetAbsOrigin(), true)
	self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("duration")-0.1)
end
function modifier_ability_thdots_larva02_02_debuff:OnIntervalThink()
	if not IsServer() then return end
	UtilStun:UnitStunTarget(self:GetCaster(),self:GetParent(),self:GetAbility():GetSpecialValueFor("stun_duration"))
	local damage_table = {
		victim 			= self:GetParent(),
		damage          = self:GetAbility():GetSpecialValueFor("bone_damage"),
		damage_type		= self:GetAbility():GetAbilityDamageType(),
		damage_flags 	= self:GetAbility():GetAbilityTargetFlags(),
		attacker 		= self:GetCaster(),
		ability 		= self:GetAbility(),
	}
    ApplyDamage(damage_table)
	self:GetParent():RemoveModifierByName("modifier_ability_thdots_larva02_02_debuff")
	self:GetParent():EmitSound("larva04_break")
	------万宝槌-------
	if self:GetCaster():HasScepter() then
	local caster = self:GetCaster()
	local modifier=
    {
        outgoing_damage=self:GetAbility():GetSpecialValueFor("illusion_outgoing_damage") - 100,
        incoming_damage=self:GetAbility():GetSpecialValueFor("illusion_incoming_damage"),
        duration=self:GetAbility():GetSpecialValueFor("illusions_duration"),
        bounty_base=0,
        bounty_growth=0,
        outgoing_damage_structure=0,
        outgoing_damage_roshan=0,
    }
	FindClearSpaceForUnit(CreateIllusions(caster, caster, modifier, 1, 150, false, true)[1], self:GetParent():GetAbsOrigin(), false)
	    if self:GetParent():HasModifier("modifier_ability_thdots_larva02_ex_debuff") == true then
		    local stackcount = self:GetParent():FindModifierByName("modifier_ability_thdots_larva02_ex_debuff"):GetStackCount()
			self:GetParent():FindModifierByName("modifier_ability_thdots_larva02_ex_debuff"):SetStackCount(stackcount + self:GetSpecialValueFor("stack_get"))
		end
	end
end
function modifier_ability_thdots_larva02_02_debuff:OnRemoved()
	if not IsServer() then return end
	ParticleManager:DestroyParticle(self.larvaline,true)
end

function modifier_ability_thdots_larva02_02_debuff:DeclareFunctions()
    return 
	{
	  MODIFIER_EVENT_ON_UNIT_MOVED,
    }
end

function modifier_ability_thdots_larva02_02_debuff:OnUnitMoved()
    if not IsServer() then return end
    local caster = self:GetCaster()
    local target = self:GetParent()	
    local runrange = self:GetAbility():GetSpecialValueFor("runrange")
	local telent_runrange = self:GetCaster():FindAbilityByName("special_bonus_unique_larva_02_2_1")
    local duration  = self:GetAbility():GetSpecialValueFor("duration")
    local stun_duration = self:GetAbility():GetSpecialValueFor("stun_duration")
    local runrange = self:GetAbility():GetSpecialValueFor("runrange")
    local distance = (self:GetParent():GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()  --判断玩家距离替身的位置
	if caster:FindAbilityByName("special_bonus_unique_larva_02_2_1"):GetLevel() ~= 0 then runrange = runrange + telent_runrange:GetSpecialValueFor("value") end
    if  distance > runrange then
	    caster:EmitSound("larva04_break")
	    self:GetParent():RemoveModifierByName("modifier_ability_thdots_larva02_02_debuff")
    end
end



----------------3技能---------------------
ability_thdots_larva02_03 = {}
function ability_thdots_larva02_03:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local base_duration = self:GetCaster():FindAbilityByName("ability_thdots_larva02_ex"):GetSpecialValueFor("duration")
	local heros = FindUnitsInRadius(caster:GetTeamNumber(),caster:GetAbsOrigin(),nil,radius,self:GetAbilityTargetTeam(),self:GetAbilityTargetType(),0,0,false)
	local pfx_name        = "particles/econ/items/faceless_void/faceless_void_bracers_of_aeons/fv_bracers_of_aeons_red_timedialate.vpcf"
	local pfx = ParticleManager:CreateParticle(pfx_name, PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(pfx, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(pfx, 1, Vector(100, 100, 100))
            for _,v in pairs(heros) do
				local damage_table = {
					victim 			= v,
					damage          = self:GetSpecialValueFor("bone_damage"),
					damage_type		= self:GetAbilityDamageType(),
					damage_flags 	= self:GetAbilityTargetFlags(),
					attacker 		= caster,
					ability 		= self,
				}
				ApplyDamage(damage_table)
				if  v:HasModifier("modifier_ability_thdots_larva02_ex_debuff") ~= true then
					v:AddNewModifier(caster, self, "modifier_ability_thdots_larva02_ex_debuff", {Duration = base_duration})
					v:FindModifierByName("modifier_ability_thdots_larva02_ex_debuff"):SetStackCount(self:GetSpecialValueFor("stack_get"))
				else
					local stackcount = v:FindModifierByName("modifier_ability_thdots_larva02_ex_debuff"):GetStackCount()
					v:FindModifierByName("modifier_ability_thdots_larva02_ex_debuff"):SetStackCount(stackcount + self:GetSpecialValueFor("stack_get"))
				end
            end
	caster:EmitSound("larva02")
end

----------------4技能---------------------
ability_thdots_larva02_04 = {}
function ability_thdots_larva02_04:GetCastRange(location, target)
	if IsClient() then
		return self:GetSpecialValueFor("project_range") + self:GetSpecialValueFor("projectwide_end")
	end
end

function ability_thdots_larva02_04:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local targetpoint = self:GetCursorPosition()
	local direction   = (targetpoint - caster:GetAbsOrigin()):Normalized()
	local spelllong   =(targetpoint- caster:GetAbsOrigin()):Length2D()
	if spelllong<=0 then
		direction=caster:GetForwardVector()
	end
	direction.z           = 0
	local distance        = 800
	local particle1        = "particles/econ/items/death_prophet/death_prophet_acherontia/death_prophet_acher_swarm.vpcf"
	local particle2 = "particles/units/heroes/hero_death_prophet/death_prophet_carrion_swarm.vpcf"
	local pointRad = GetRadBetweenTwoVec2D(caster:GetAbsOrigin(),targetpoint)
	local forwardVec = Vector( math.cos(pointRad) * 800 , math.sin(pointRad) * 800 , 0 )
	local orb_thinker = CreateModifierThinker(
		caster,
		self,
		nil, -- Maybe add one later
		{},
		caster:GetOrigin(),
		caster:GetTeamNumber(),
		false		
	)
	-- + Vector(0,0,128)
	local info1 = 
	{
		Ability				= self,
		EffectName			= particle1,
		vSpawnOrigin		= caster:GetAbsOrigin() + Vector(0,0,128),
		fDistance			= self:GetSpecialValueFor("project_range"),
		fStartRadius		= self:GetSpecialValueFor("projectwide_first"),
		fEndRadius			= self:GetSpecialValueFor("projectwide_end"),
		Source				= caster,
		bHasFrontalCone		= false,
		bReplaceExisting	= false,
		iUnitTargetTeam		= DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags	= DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType		= self:GetAbilityTargetType(),
		fExpireTime			= GameRules:GetGameTime() + 5.0,
		bDeleteOnHit		= false,
		vVelocity			= forwardVec,
		bProvidesVision		= true,
		iVisionRadius		= 200,
		iVisionTeamNumber	= caster:GetTeamNumber(),
		iSourceAttachment 	= PATTACH_CUSTOMORIGIN,
		ExtraData = {
			orb_thinker		= orb_thinker:entindex(),}
	}
	-- table.insert(self.orbs, orb_thinker:entindex())
	ProjectileManager:CreateLinearProjectile(info1)
	self.particle = ParticleManager:CreateParticle(particle2,PATTACH_WORLDORIGIN,nil)
	ParticleManager:SetParticleControl(self.particle, 0, caster:GetAbsOrigin())
	local direct = ((targetpoint - caster:GetAbsOrigin()) * Vector(1, 1, 0)):Normalized()
	ParticleManager:SetParticleControl(self.particle, 1, Vector(direct.x*800,direct.y*800,0))
	ParticleManager:SetParticleControl(self.particle, 2, Vector(300,300,100))
	ParticleManager:DestroyParticleSystemTime(self.particle,1)
	caster:EmitSound("Hero_Visage.SoulAssumption.Cast")
end
function ability_thdots_larva02_04:OnProjectileHit_ExtraData(target, location, data)
	if not IsServer() then return end
	local caster = self:GetCaster()
	local base_duration = self:GetCaster():FindAbilityByName("ability_thdots_larva02_ex"):GetSpecialValueFor("duration")
	if target then
		local damage_table = {
					ability = self,
					victim = target,
					attacker = self:GetCaster(),
					damage = self:GetSpecialValueFor("bone_damage"),
					damage_type = self:GetAbilityDamageType(), 
					damage_flags = 0
			}
		ApplyDamage(damage_table)
		if  target:HasModifier("modifier_ability_thdots_larva02_ex_debuff") ~= true then
			target:AddNewModifier(caster, self, "modifier_ability_thdots_larva02_ex_debuff", {Duration = base_duration})
			target:FindModifierByName("modifier_ability_thdots_larva02_ex_debuff"):SetStackCount(self:GetSpecialValueFor("stack_get"))
		else
			local stackcount = target:FindModifierByName("modifier_ability_thdots_larva02_ex_debuff"):GetStackCount()
			target:FindModifierByName("modifier_ability_thdots_larva02_ex_debuff"):SetStackCount(stackcount + self:GetSpecialValueFor("stack_get"))
		end
		local stackcount_all = target:FindModifierByName("modifier_ability_thdots_larva02_ex_debuff"):GetStackCount()
		local damage_table02 = {
			ability = self,
			victim = target,
			attacker = self:GetCaster(),
			damage = self:GetSpecialValueFor("stack_damage")*(stackcount_all),
			damage_type = self:GetAbilityDamageType(), 
			damage_flags = 0
	        }
			ApplyDamage(damage_table02)	
			local total_damage = self:GetSpecialValueFor("bone_damage") + self:GetSpecialValueFor("stack_damage")*(stackcount_all)
			SendOverheadEventMessage(nil,OVERHEAD_ALERT_BONUS_SPELL_DAMAGE,target,total_damage,nil)
			target:RemoveModifierByName("modifier_ability_thdots_larva02_ex_debuff")
	------------------------------------------------------------------------------------------------
	target:EmitSound("Hero_Visage.SoulAssumption.Target")
	end
end