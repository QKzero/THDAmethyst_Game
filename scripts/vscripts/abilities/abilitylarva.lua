ability_thdots_larvaEx = {}

function ability_thdots_larvaEx:GetIntrinsicModifierName()  --内置modifier
	if not IsServer() then return end
	return "modifier_ability_larvaEx_passive"
end

modifier_ability_larvaEx_passive = {}
LinkLuaModifier("modifier_ability_larvaEx_passive","scripts/vscripts/abilities/abilitylarva.lua",LUA_MODIFIER_MOTION_NONE)  --必要步骤  
function modifier_ability_larvaEx_passive:IsHidden() 		return true end     --是否隐藏
function modifier_ability_larvaEx_passive:IsPurgable()     return false end     --是否可净化
function modifier_ability_larvaEx_passive:RemoveOnDeath() 	return true  end     --死亡移除
function modifier_ability_larvaEx_passive:IsDebuff()	   	return false end     --是否是DEBUFF

function modifier_ability_larvaEx_passive:DeclareFunctions() --宣布将要使用哪些效果
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,            
	}   
end

function modifier_ability_larvaEx_passive:OnCreated() --天赋监听
	if not IsServer() then return end
	self:StartIntervalThink(0.03)
end
function modifier_ability_larvaEx_passive:OnIntervalThink()
	if not IsServer() then return end
	--if FindTelentValue(self:GetCaster(),"special_bonus_unique_larva_1") ~= 0 and not self:GetCaster():HasModifier("modifier_ability_thdots_larva_telent_1") then
	--	self:GetCaster():AddNewModifier(self:GetCaster(),self:GetAbility(),"modifier_ability_thdots_larva_telent_1",{})
	--end
	if FindTelentValue(self:GetCaster(),"special_bonus_unique_larva_6") ~= 0 and not self:GetCaster():HasModifier("modifier_ability_thdots_larva_telent_2") then
		self:GetCaster():AddNewModifier(self:GetCaster(),self:GetAbility(),"modifier_ability_thdots_larva_telent_2",{})
	end
end


function modifier_ability_larvaEx_passive:OnAttackLanded(keys)  
	if not IsServer() then return end
	local attacker = keys.attacker
	local duration = self:GetAbility():GetSpecialValueFor("duration")
	if keys.target ~= self:GetParent() then return end  --判断被攻击者是否为拉尔瓦
	attacker:RemoveModifierByName("modifier_ability_larvaEx_buff") --刷新持续时间
	attacker:AddNewModifier(keys.target,self:GetAbility(),"modifier_ability_larvaEx_buff",{duration = duration})
end

modifier_ability_larvaEx_buff = {}
LinkLuaModifier("modifier_ability_larvaEx_buff","scripts/vscripts/abilities/abilitylarva.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_larvaEx_buff:IsHidden() 		return false end     --是否隐藏
function modifier_ability_larvaEx_buff:IsPurgable()     return true end     --是否可净化
function modifier_ability_larvaEx_buff:RemoveOnDeath() 	return true  end     --死亡移除
function modifier_ability_larvaEx_buff:IsDebuff()	   	return true end     --是否是DEBUFF

function modifier_ability_larvaEx_buff:DeclareFunctions()   --技能增强
	return {
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
	}
end

function modifier_ability_larvaEx_buff:GetModifierSpellAmplify_Percentage() --给一个反的数就能达到降低技能伤害的效果了
	return -self:GetAbility():GetSpecialValueFor("damage_percent")
end 

------------------------------------------------------------------------------------------------
------------------------------蝶符  盛夏振翅 扑棱蛾子---------------------------------------------
------------------------------------------------------------------------------------------------
ability_thdots_larva01_1 = {}

function ability_thdots_larva01_1:GetCastRange(location, target)
	if IsServer() then
		return 0
	else
		return self:GetSpecialValueFor("length") + self:GetCaster():GetCastRangeBonus()
	end
end

function ability_thdots_larva01_1:OnUpgrade()
    if not IsServer() then return end
    local synchronousLevelAbility = {
        self:GetCaster():FindAbilityByName("ability_thdots_larva01_2"),
    }
    for _, val in pairs(synchronousLevelAbility) do
        if val:GetLevel() ~= self:GetLevel() then
            val:SetLevel(self:GetLevel())
        end
    end
end

function ability_thdots_larva01_1:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()

	local dashLength = self:GetSpecialValueFor("length")
	local dashDuration = self:GetSpecialValueFor("duration")

	local casterPos = caster:GetOrigin()
	local targetPos = self:GetCursorPosition()
	dashLength = math.min(dashLength, (targetPos - casterPos):Length2D())
	targetPos = casterPos + (targetPos - casterPos):Normalized() * dashLength
	
	caster:EmitSound("larva01")
	caster:AddNewModifier(caster, self, "modifier_ability_larva01_dash", {
		duration = dashDuration,
		dashLength = dashLength,
	})
end

ability_thdots_larva01_2 = {}

function ability_thdots_larva01_2:OnUpgrade()
    if not IsServer() then return end
    local synchronousLevelAbility = {
        self:GetCaster():FindAbilityByName("ability_thdots_larva01_1"),
    }
    for _, val in pairs(synchronousLevelAbility) do
        if val:GetLevel() ~= self:GetLevel() then
            val:SetLevel(self:GetLevel())
        end
    end
end

function ability_thdots_larva01_2:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()

	local modifier = caster:FindModifierByName("modifier_ability_larva01_dash")
	if (modifier ~= nil) then
		modifier:Destroy()
	end
end

modifier_ability_larva01_dash = {}
LinkLuaModifier("modifier_ability_larva01_dash", "scripts/vscripts/abilities/abilitylarva.lua", LUA_MODIFIER_MOTION_BOTH)
-- function modifier_ability_larva01_dash:IsHidden() 		return true end     --是否隐藏
function modifier_ability_larva01_dash:IsPurgable()     return false end     --是否可净化
-- function modifier_ability_larva01_dash:RemoveOnDeath() 	return true  end     --死亡移除
function modifier_ability_larva01_dash:IsDebuff()	   	return false end     --是否是DEBUFF

function modifier_ability_larva01_dash:OnCreated(params)
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

    self.caster:SwapAbilities("ability_thdots_larva01_1", "ability_thdots_larva01_2", false, true)
	self.abilityCooldown = self.ability:GetCooldownTime()

	self.dashLength = tonumber(params.dashLength)
	self.dashWidth = self.ability:GetSpecialValueFor("width")
	self.damage = self.ability:GetSpecialValueFor("damage")
	self.damageMulBonus = self.ability:GetSpecialValueFor("damage_mul_bonus")
	self.flyDuration = self.ability:GetSpecialValueFor("fly_duration")

	self.casterOrigin = self.caster:GetOrigin()
	self.casterAngles = self.caster:GetAngles()
	self.forwardDir = self.caster:GetForwardVector()
	self.rightDir = self.caster:GetRightVector()

	self.caster:RemoveHorizontalMotionController(self)
	self.caster:RemoveVerticalMotionController(self)
	if self:ApplyVerticalMotionController() == false then self:Destroy() end
	if self:ApplyHorizontalMotionController() == false then self:Destroy() end

	self:StartIntervalThink(FrameTime())
end

function modifier_ability_larva01_dash:OnIntervalThink()
	if not IsServer() then return end

	local heros = FindUnitsInRadius(
		self.caster:GetTeamNumber(),
		self.caster:GetOrigin(),
		nil,
		200,
		self.ability:GetAbilityTargetTeam(),
		self.ability:GetAbilityTargetType(),
		DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
		false
	) -- 将沿途单位计入heros中

	for _, v in pairs(heros) do
		if not v:HasModifier("modifier_ability_larva01_damaged_flag") then
			v:AddNewModifier(caster, self, "modifier_ability_larva01_damaged_flag", {
				duration = self:GetRemainingTime() + 0.1
			})

			local damageBonus = 0
			if v:IsRealHero() then
				damageBonus = v:GetStrength() + v:GetAgility() + v:GetIntellect(false) - 
					(self.caster:GetStrength() + self.caster:GetAgility() + self.caster:GetIntellect(false))
			end -- 对英雄计算属性差伤害
			damageBonus = math.abs(damageBonus)

			local damage_table = {
				victim = v,
				attacker = self.caster,
				damage = self.damage + damageBonus * self.damageMulBonus,
				damage_type = self.ability:GetAbilityDamageType()
			}
			UnitDamageTarget(damage_table)
		end
	end
end

function modifier_ability_larva01_dash:OnDestroy()
    if not IsServer() then return end

	-- Set Destination and Interrupt Motion or the unit will still move
	self.caster:RemoveHorizontalMotionController(self)
	self.caster:RemoveVerticalMotionController(self)
	FindClearSpaceForUnit(self.caster, self.caster:GetOrigin(), false)

	self.ability:StartCooldown(self.abilityCooldown)
    self.caster:SwapAbilities("ability_thdots_larva01_1", "ability_thdots_larva01_2", true, false)

	-- 大于0说明有天赋
	if self.flyDuration > 0 then
		self.caster:AddNewModifier(self.caster, self.ability, "modifier_ability_larva01_fly", {
			duration = self.flyDuration,
		})
	end
end

function modifier_ability_larva01_dash:OnRefresh(params)
    self:OnCreated(params)
end

function modifier_ability_larva01_dash:UpdateHorizontalMotion(me, dt)
	local passedTime = 1 - self:GetRemainingTime() / self:GetDuration()

	local theta = - 2 * math.pi * passedTime
	local x = math.sin(theta) * self.dashWidth * 0.5
	local y = - math.cos(theta) * self.dashLength * 0.5

	local pos = self.casterOrigin + self.forwardDir * (self.dashLength / 2) + self.rightDir * x + self.forwardDir * y

	local startAngle = 60 -- 人物开始飞行转动的角
	local cyclesAngle = 300 -- 人物完成飞行转动的角
	local yaw = startAngle - passedTime * cyclesAngle

	me:SetOrigin(pos)
	self.caster:FaceTowards(pos + RotatePosition(Vector(0, 0, 0), QAngle(0, yaw, 0), self.forwardDir))
end

function modifier_ability_larva01_dash:OnHorizontalMotionInterrupted()
    self:Destroy()
end

function modifier_ability_larva01_dash:UpdateVerticalMotion(me, dt)
	me:SetOrigin(GetGroundPosition(me:GetOrigin(), nil))
end

-- -- This typically gets called if the caster uses a position breaking tool (ex. Earth Spike) while in mid-motion
function modifier_ability_larva01_dash:OnVerticalMotionInterrupted()
    self:Destroy()
end

modifier_ability_larva01_damaged_flag = {}
LinkLuaModifier("modifier_ability_larva01_damaged_flag", "scripts/vscripts/abilities/abilitylarva.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_ability_larva01_damaged_flag:IsHidden() 		return true end     --是否隐藏
function modifier_ability_larva01_damaged_flag:IsPurgable()     return false end     --是否可净化
-- function modifier_ability_larva01_damaged_flag:RemoveOnDeath() 	return true  end     --死亡移除
function modifier_ability_larva01_damaged_flag:IsDebuff()	   	return false end     --是否是DEBUFF

modifier_ability_larva01_fly = {}
LinkLuaModifier("modifier_ability_larva01_fly", "scripts/vscripts/abilities/abilitylarva.lua", LUA_MODIFIER_MOTION_NONE)
-- function modifier_ability_larva01_fly:IsHidden() 		return false end     --是否隐藏
function modifier_ability_larva01_fly:IsPurgable()     return false end     --是否可净化
-- function modifier_ability_larva01_fly:RemoveOnDeath() 	return true  end     --死亡移除
function modifier_ability_larva01_fly:IsDebuff()	   	return false end     --是否是DEBUFF

function modifier_ability_larva01_fly:CheckState()  --飞行 没有高空视野
	return{
		[MODIFIER_STATE_FLYING]  = true,
	}
end

function modifier_ability_larva01_fly:OnCreated()  --高空视野
	if not IsServer() then return end

	self:StartIntervalThink(FrameTime())
	self:OnIntervalThink()
end

function modifier_ability_larva01_fly:OnIntervalThink()  
	if not IsServer() then return end

	local target = self:GetParent()
    AddFOWViewer(target:GetTeamNumber(), target:GetOrigin(), target:GetCurrentVisionRange(), FrameTime() * 2, false)  --高空视野
end

---------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------蝶符  沾身难下的鳞粉----------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------

ability_thdots_larva02 = {}

function ability_thdots_larva02:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function ability_thdots_larva02:GetIntrinsicModifierName()  --天赋被动
	if not IsServer() then return end
	--if not self:GetCaster():FindTelentValue(self:GetCaster(),"special_bonus_unique_larva_6") ~= 0 then return end
	    return "modifier_ability_larva02_attack"
end

function ability_thdots_larva02:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	caster:EmitSound("larva02")
	local duration = self:GetSpecialValueFor("duration")  
	local radius = self:GetSpecialValueFor("radius")
	local heros = FindUnitsInRadius(caster:GetTeam(),caster:GetAbsOrigin(),nil,radius,DOTA_UNIT_TARGET_TEAM_ENEMY + DOTA_UNIT_TARGET_TEAM_CUSTOM  --[[搜索施法者350码内的敌人]]
		,DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP + DOTA_UNIT_TARGET_CUSTOM,0,0,false)
	for _,v in pairs(heros) do   
		if not v:HasModifier("modifier_ability_larva02_debuff") then
			v:AddNewModifier(caster,self,"modifier_ability_larva02_debuff",{duration = duration})
		end
	end
	local larva02 = ParticleManager:CreateParticle("particles/heroes/larva/ability_larva_02_warning_circle.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(larva02 , 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(larva02 , 1, Vector(radius,0,0))
end

modifier_ability_larva02_attack = {}
LinkLuaModifier("modifier_ability_larva02_attack","scripts/vscripts/abilities/abilitylarva.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_larva02_attack:IsHidden() 
	if self:GetCaster():HasModifier("modifier_ability_thdots_larva_telent_2") then
	return false else return true end end
function modifier_ability_larva02_attack:IsPurgable() return true end
function modifier_ability_larva02_attack:IsDebuff() return false end
function modifier_ability_larva02_attack:RemoveOnDeath() return true end

function modifier_ability_larva02_attack:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_ability_larva02_attack:OnAttackLanded(keys)  --天赋普攻附带2技能 ，实现方法与技能一致
	if not IsServer() then return end
	if not self:GetCaster():HasModifier("modifier_ability_thdots_larva_telent_2") then return end
	if keys.attacker ~= self:GetParent() then return end
	if keys.target:IsBuilding() then return end
	 --print_r(keys)
	 local duration = self:GetAbility():GetSpecialValueFor("duration")
	 local addduration = self:GetAbility():GetSpecialValueFor("addduration")
	 local caster = keys.attacker
	 local target = keys.target
	 if not target:HasModifier("modifier_ability_larva02_debuff") then
	 	target:AddNewModifier(caster,self:GetAbility(),"modifier_ability_larva02_debuff",{duration = duration})
	 else
	    local count = target:GetModifierStackCount("modifier_ability_larva02_debuff", nil) + 1 --读取目标层数
	    target:SetModifierStackCount("modifier_ability_larva02_debuff", self, count ) 
	    target:FindModifierByName("modifier_ability_larva02_debuff"):SetDuration( duration, true)
	end
end
     

modifier_ability_larva02_debuff = {}
LinkLuaModifier("modifier_ability_larva02_debuff","scripts/vscripts/abilities/abilitylarva.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_larva02_debuff:IsHidden()   return false end
function modifier_ability_larva02_debuff:IsPurgable()  return true end
function modifier_ability_larva02_debuff:IsDebuff()  return true end
function modifier_ability_larva02_debuff:GetEffectName() return "particles/units/heroes/hero_dark_willow/dark_willow_willowisp_ambient_trail_bits.vpcf" end
function modifier_ability_larva02_debuff:GetEffectAttachType()  return PATTACH_CENTER_FOLLOW end
function modifier_ability_larva02_debuff:RemoveOnDeath()  return true end

function modifier_ability_larva02_debuff:OnCreated()
	self.base_damage = self:GetAbility():GetSpecialValueFor("damage")
	self.stack_damage = self:GetAbility():GetSpecialValueFor("damage_bonus")
	self.slow = self:GetAbility():GetSpecialValueFor("slow")
	if not IsServer() then return end
	self:StartIntervalThink(1)
end

function  modifier_ability_larva02_debuff:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ABILITY_EXECUTED,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_ability_larva02_debuff:OnIntervalThink()
	if not IsServer() then return end
	local count = self:GetParent():GetModifierStackCount("modifier_ability_larva02_debuff", nil)  
	local damage = self.base_damage + ( self.stack_damage * count )
	--print(damage)
	local damage_table ={
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		damage = damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
	}
	UnitDamageTarget(damage_table)

	--只有英雄显示这个头顶特效
	if self:GetParent():IsHero() then
		local index = ParticleManager:CreateParticle("particles/units/heroes/hero_dark_willow/dark_willow_shadow_realm_alert_burst.vpcf", PATTACH_POINT_FOLLOW, self:GetParent())
	--ParticleManager:SetParticleControl(index, 0, self:GetParent():GetOrigin())
		ParticleManager:DestroyParticleSystemTime(index,1.0)
	end
	--if count == 0 then self:GetParent():RemoveModifierByName("modifier_ability_larva02_debuff") end
end


function modifier_ability_larva02_debuff:OnAbilityExecuted(keys)  --使用技能时
	if not IsServer() then return end
	--print_r(keys.ability:GetName())
	if keys.unit ~= self:GetParent() or keys.ability:IsItem() or keys.ability:IsToggle() or IsNotLunchbox_ability(keys.ability) then  --判断是否为buff携带者 使用的是否是技能
		return
	end
	local count = self:GetParent():GetModifierStackCount("modifier_ability_larva02_debuff", nil) + 1 --读取目标层数
	self:GetParent():SetModifierStackCount("modifier_ability_larva02_debuff", self, count )  --层数 + 额外持续时间
	self:GetParent():FindModifierByName("modifier_ability_larva02_debuff"):SetDuration( self:GetDuration(), true)  --层数 + 额外持续时间
end

function modifier_ability_larva02_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end

---------------------------------------------------------------------------------------------------------
-------------------------------------梦蝶  Crazy Butterfly-----------------------------------------------
---------------------------------------------------------------------------------------------------------

ability_thdots_larva03 = {}

function ability_thdots_larva03:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	target:EmitSound("larva03")
	local duration = self:GetSpecialValueFor("duration")
	target:AddNewModifier(caster,self,"modifier_ability_larva03_buff",{duration = duration})
end

modifier_ability_larva03_buff = {}
LinkLuaModifier("modifier_ability_larva03_buff","scripts/vscripts/abilities/abilitylarva.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_larva03_buff:IsDebuff() return false end
function modifier_ability_larva03_buff:IsHidden() return false end
function modifier_ability_larva03_buff:IsPurgable() return true end
function modifier_ability_larva03_buff:RemoveOnDeath() return true end
function modifier_ability_larva03_buff:GetEffectName() return "particles/heroes/larva/lotus_orb_shield.vpcf" end
function modifier_ability_larva03_buff:GetEffectAttachType() return PATTACH_CENTER_FOLLOW end

function modifier_ability_larva03_buff:OnCreated()
	self.slowduration = self:GetAbility():GetSpecialValueFor("slowtime")
	self.slow = self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_ability_larva03_buff:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

function modifier_ability_larva03_buff:OnTakeDamage(keys)
	if not IsServer() then return end
	if not keys.attacker:IsRealHero() then return end
	if keys.attacker:GetTeam() == self:GetCaster() then return end
	if keys.unit ~= self:GetParent() then return end
	if keys.damage <= 50 then return end
	--print_r(keys)
	local lasthealth = keys.unit:GetHealth() + keys.damage
	if keys.unit:GetHealth() == 0 then
		if keys.damage > 150 then lasthealth = 150
		else
			lasthealth = keys.damage
		end
	end
	keys.unit:SetHealth(lasthealth)
	if keys.attacker:IsNull() or not keys.attacker:IsAlive() or keys.attacker:IsMagicImmune() or IsTHDImmune(keys.attacker) then return end--魔免检测
	keys.attacker:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_ability_larva03_debuff", {duration = self.slowduration, slow = self.slow})
	local damage_table = {
		victim = keys.attacker,
		damage = keys.damage,
		damage_type = DAMAGE_TYPE_PURE,
		attacker = self:GetCaster(),
	}
	self:GetParent():RemoveModifierByName("modifier_ability_larva03_buff")
	UnitDamageTarget(damage_table)
end
function modifier_ability_larva03_buff:OnRemoved()
	if not IsServer() then return end
	--local shield_particle = ParticleManager:CreateParticle("particles/heroes/larva/medusa_daughters_mana_shield_shell_impact_c.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	--ParticleManager:ReleaseParticleIndex(shield_particle)
end

modifier_ability_larva03_debuff = {}
LinkLuaModifier("modifier_ability_larva03_debuff","scripts/vscripts/abilities/abilitylarva.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_larva03_debuff:IsHidden() return false end
function modifier_ability_larva03_debuff:IsDebuff() return true end
function modifier_ability_larva03_debuff:IsPurgable() return true end
function modifier_ability_larva03_debuff:RemoveOnDeath() return true end

function modifier_ability_larva03_debuff:OnCreated(keys)
	if not IsServer() then return end

	self.slow = keys.slow

	self:SetHasCustomTransmitterData(true)
end

function modifier_ability_larva03_debuff:OnRefresh(keys)
	if not IsServer() then return end
	self:OnCreated(keys)

	self:SendBuffRefreshToClients()
end

function modifier_ability_larva03_debuff:AddCustomTransmitterData()
	return {
		slow = self.slow
	}
end
function modifier_ability_larva03_debuff:HandleCustomTransmitterData(data)
	self.slow = data.slow
end

function modifier_ability_larva03_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_ability_larva03_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end

---------------------------------------------------------------------------------------------------------
-----------------------------------------仲夏的妖精梦-----------------------------------------------------
---------------------------------------------------------------------------------------------------------

ability_thdots_larva04 = {}

function ability_thdots_larva04:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function ability_thdots_larva04:OnSpellStart()
	if not IsServer() then return end
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")
    --local damage = self:GetSpecialValueFor("damage")
    --local stuntime = self:GetSpecialValueFor("stuntime")
    local point = self:GetCursorPosition()
    local range = self:GetSpecialValueFor("movelimit")
	print(range)
    local thinker = CreateModifierThinker(caster,self,"modifier_ability_larva04_catch",{duration = duration},point,caster:GetTeamNumber(),false)  --为鼠标选中地点创建一个有坐标的替身（？）
    self.dream = ParticleManager:CreateParticle("particles/units/larva/larva04.vpcf", PATTACH_ABSORIGIN, thinker)
    --self.dream_aura = ParticleManager:CreateParticle("particles/heroes/misc/aura_circle_common.vpcf", PATTACH_CUSTOMORIGIN,nil)
	--ParticleManager:SetParticleControl(self.dream_aura, 0, point)
	--ParticleManager:SetParticleControl(self.dream_aura, 1, Vector(range,0,0))
	--ParticleManager:SetParticleControl(self.dream_aura, 2, Vector(duration-0.5,0,0))
	--ParticleManager:SetParticleControl(self.dream_aura, 3, Vector(221,160,221))
	ParticleManager:DestroyParticleSystemTime(self.dream,duration+1)
    thinker:EmitSound("larva04")
    if caster:HasModifier("modifier_item_wanbaochui") then thinker:AddNewModifier(caster,self,"modifier_larva_wanbaochui",{duration = duration}) end
    if FindTelentValue(self:GetCaster(),"special_bonus_unique_larva_5") ~= 0 then thinker:AddNewModifier(caster,self,"modifier_larva_telent5",{duration = duration}) end
    --[[local heros = FindUnitsInRadius(caster:GetTeam(),point,nil,radius,DOTA_UNIT_TARGET_TEAM_ENEMY,DOTA_UNIT_TARGET_HERO,0,0,false)
            for _,v in pairs(heros) do
            	v:AddNewModifier(caster,self,"modifier_ability_larva04_catch",{duration = duration})
            end]]
end

modifier_larva_wanbaochui = {}
LinkLuaModifier("modifier_larva_wanbaochui","scripts/vscripts/abilities/abilitylarva.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_larva_wanbaochui:IsPurgable() return false end
function modifier_larva_wanbaochui:IsHidden() return true end
function modifier_larva_wanbaochui:IsDebuff() return false end
function modifier_larva_wanbaochui:RemoveOnDeath() return true end

modifier_larva_telent5 = {}
LinkLuaModifier("modifier_larva_telent5","scripts/vscripts/abilities/abilitylarva.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_larva_telent5:IsPurgable() return false end
function modifier_larva_telent5:IsHidden() return true end
function modifier_larva_telent5:IsDebuff() return false end
function modifier_larva_telent5:RemoveOnDeath() return true end

modifier_ability_larva04_catch = {}
LinkLuaModifier("modifier_ability_larva04_catch","scripts/vscripts/abilities/abilitylarva.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_larva04_catch:IsDebuff() return true end
function modifier_ability_larva04_catch:IsHidden() return false end
function modifier_ability_larva04_catch:IsPurgable() return true end
function modifier_ability_larva04_catch:RemoveOnDeath() return true end

function modifier_ability_larva04_catch:OnCreated()
	if not IsServer() then return end
	local caster = self:GetParent()
    local radius = self:GetAbility():GetSpecialValueFor("radius")
	local duration = self:GetAbility():GetSpecialValueFor("duration")
	local heros = FindUnitsInRadius(caster:GetTeamNumber(),caster:GetAbsOrigin(),nil,radius,DOTA_UNIT_TARGET_TEAM_ENEMY,DOTA_UNIT_TARGET_HERO,0,0,false)
            for _,v in pairs(heros) do
            	v:AddNewModifier(caster,self:GetAbility(),"modifier_ability_larva04_caught",{duration = duration})
            	v:SetModifierStackCount("modifier_ability_larva04_caught", self:GetAbility(), 1 )
            end
end

modifier_ability_larva04_stun = {}
LinkLuaModifier("modifier_ability_larva04_stun","scripts/vscripts/abilities/abilitylarva.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_larva04_stun:IsHidden() return false end
function modifier_ability_larva04_stun:IsDebuff() return true end
function modifier_ability_larva04_stun:IsPurgable()
	if not IsServer() then return end
	if self:GetCaster():HasModifier("modifier_larva_telent5") then
	    return false
    else
    	return true
	 end
end

function modifier_ability_larva04_stun:RemoveOnDeath() return true end

function modifier_ability_larva04_stun:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

function modifier_ability_larva04_stun:OnTakeDamage(keys)
	if keys.unit ~= self:GetParent() then return end
	if self.lock == 0 then return end
	local count = self:GetParent():GetModifierStackCount("modifier_ability_larva04_stun", nil) - keys.damage
	if count <= 0 then
	 self:GetParent():RemoveModifierByName("modifier_ability_larva04_stun")
	else
	 self:GetParent():SetModifierStackCount("modifier_ability_larva04_stun",self:GetAbility(),count)
	end
end

function modifier_ability_larva04_stun:OnCreated()
	if not IsServer() then return end
	self.lock = 0
	local count =  self:GetParent():GetModifierStackCount("modifier_ability_larva04_caught", nil)
    local damage = self:GetAbility():GetSpecialValueFor("damage")
    local damage_table = {
	        	victim = self:GetParent(),
		        attacker = self:GetCaster(),
	        	damage = damage * count,
		        damage_type = DAMAGE_TYPE_MAGICAL,
	           }
    UnitDamageTarget(damage_table)
	self.lock = 1
	if not self:GetParent() or self:GetParent():IsNull() then
		self:Destroy()
		return
	end
	if self:GetCaster():HasModifier("modifier_larva_wanbaochui") then self:GetParent():SetModifierStackCount("modifier_ability_larva04_caught", self:GetAbility(), count + 1 ) end
	local limit = self:GetAbility():GetSpecialValueFor("damagelimit")
	self:GetParent():SetModifierStackCount("modifier_ability_larva04_stun",self:GetAbility(),limit)
end

function modifier_ability_larva04_stun:CheckState()
	return{
		[MODIFIER_STATE_NIGHTMARED]  = true,
		[MODIFIER_STATE_STUNNED] = true,
	}
end

modifier_ability_larva04_caught = {}
LinkLuaModifier("modifier_ability_larva04_caught","scripts/vscripts/abilities/abilitylarva.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_larva04_caught:IsDebuff() return true end
function modifier_ability_larva04_caught:IsHidden() return false end
function modifier_ability_larva04_caught:IsPurgable() return false end
function modifier_ability_larva04_caught:RemoveOnDeath() return true end

function modifier_ability_larva04_caught:OnCreated()
      local caster = self:GetCaster()
      local target = self:GetParent()
     self.larvaline = ParticleManager:CreateParticle("particles/units/larva/larva04line.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	        ParticleManager:SetParticleControlEnt(self.larvaline , 0, caster, 5, "attach_hitloc", caster:GetAbsOrigin(), true)
	        ParticleManager:SetParticleControlEnt(self.larvaline , 1, target, 5, "attach_hitloc", target:GetAbsOrigin(), true)
	    end

function modifier_ability_larva04_caught:OnRemoved()
   	ParticleManager:DestroyParticle(self.larvaline,true)
end

function modifier_ability_larva04_caught:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_UNIT_MOVED,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end

function modifier_ability_larva04_caught:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_ability_larva04_caught:OnUnitMoved()
	if not IsServer() then return end
	local caster = self:GetCaster()  --这是替身
	local target = self:GetParent()	
	local movelimit = self:GetAbility():GetSpecialValueFor("movelimit")
	local duration  = self:GetAbility():GetSpecialValueFor("duration")
    local stuntime = self:GetAbility():GetSpecialValueFor("stuntime")
    local radius = self:GetAbility():GetSpecialValueFor("radius")
    local distance = (self:GetParent():GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()  --判断玩家距离替身的位置
    if distance > movelimit then
    	caster:EmitSound("larva04_break")
        self:GetParent():RemoveModifierByName("modifier_ability_larva04_caught")  --没有惩罚的逃离
        local heros = FindUnitsInRadius(caster:GetTeam(),caster:GetAbsOrigin(),nil,radius,DOTA_UNIT_TARGET_TEAM_ENEMY,DOTA_UNIT_TARGET_HERO,0,0,false)
        --[[for _,v in pairs(heros) do  --连坐
        	if v:HasModifier("modifier_ability_larva04_caught") then
               v:AddNewModifier(caster,self:GetAbility(),"modifier_ability_larva04_stun",{duration = stuntime})
               if not caster:HasModifier("modifier_larva_wanbaochui") then
                     v:RemoveModifierByName("modifier_ability_larva04_caught")
                 else
                 	v:FindModifierByName("modifier_ability_larva04_caught"):SetDuration( duration , true)
                 	caster:FindModifierByName("modifier_larva_wanbaochui"):SetDuration( duration ,true )
                end
           end
       end]]

       if caster:HasModifier("modifier_larva_wanbaochui") then
       	for _,v in pairs(heros) do
       		if v:HasModifier("modifier_ability_larva04_caught") then
               v:FindModifierByName("modifier_ability_larva04_caught"):SetDuration( duration , true)
               v:AddNewModifier(caster,self:GetAbility(),"modifier_ability_larva04_stun",{duration = stuntime})
           else
           	   v:AddNewModifier(caster,self:GetAbility(),"modifier_ability_larva04_caught",{duration = duration})
            	v:SetModifierStackCount("modifier_ability_larva04_caught", self:GetAbility(), 1 )
           	end
               caster:FindModifierByName("modifier_larva_wanbaochui"):SetDuration( duration ,true )
               caster:FindModifierByName("modifier_larva_telent5"):SetDuration( duration ,true )
           end
       else
       	 for _,v in pairs(heros) do
       	 	if v:HasModifier("modifier_ability_larva04_caught") then
       	 		v:AddNewModifier(caster,self:GetAbility(),"modifier_ability_larva04_stun",{duration = stuntime})
       	 		v:RemoveModifierByName("modifier_ability_larva04_caught")
       	 	end
       	 end
    end
end
end

--modifier_ability_thdots_larva_telent_1 = {}
--LinkLuaModifier("modifier_ability_thdots_larva_telent_1","scripts/vscripts/abilities/abilitylarva.lua",LUA_MODIFIER_MOTION_NONE)
--function modifier_ability_thdots_larva_telent_1:IsHidden() 		return true end     --是否隐藏
--function modifier_ability_thdots_larva_telent_1:IsPurgable()     return false end     --是否可净化
--function modifier_ability_thdots_larva_telent_1:RemoveOnDeath() 	return false  end     --死亡移除
--function modifier_ability_thdots_larva_telent_1:IsDebuff()	   	return false end     --是否是DEBUFF

modifier_ability_thdots_larva_telent_2 = {}
LinkLuaModifier("modifier_ability_thdots_larva_telent_2","scripts/vscripts/abilities/abilitylarva.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_larva_telent_2:IsHidden() 		return true end     --是否隐藏
function modifier_ability_thdots_larva_telent_2:IsPurgable()     return false end     --是否可净化
function modifier_ability_thdots_larva_telent_2:RemoveOnDeath() 	return false  end     --死亡移除
function modifier_ability_thdots_larva_telent_2:IsDebuff()	   	return false end     --是否是DEBUFF
















