--------------------------------------------------------
--冬符「蕾蒂之心」
--------------------------------------------------------
ability_thdots_lettyEx = {}

-- function ability_thdots_lettyEx:GetIntrinsicModifierName()
-- 	return "modifier_ability_thdots_lettyEx"
-- end

function ability_thdots_lettyEx:OnToggle()
	if not IsServer() then return end
	local caster = self:GetCaster()
	if self:GetToggleState() then
		caster:AddNewModifier(caster, self, "modifier_ability_thdots_lettyEx",{})
		self:EndCooldown()
	else
		caster:RemoveModifierByName("modifier_ability_thdots_lettyEx")
		self:StartCooldown(self:GetCooldown(self:GetLevel() - 1))
	end
end

modifier_ability_thdots_lettyEx = {}
LinkLuaModifier("modifier_ability_thdots_lettyEx","scripts/vscripts/abilities/abilityletty.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_lettyEx:IsHidden() 		return false end
function modifier_ability_thdots_lettyEx:IsPurgable()		return false end
function modifier_ability_thdots_lettyEx:RemoveOnDeath() 	return false end
function modifier_ability_thdots_lettyEx:IsDebuff()		return false end

function modifier_ability_thdots_lettyEx:GetEffectName() return "particles/econ/items/ancient_apparition/ancient_apparation_ti8/ancient_ice_vortex_ti8_ring_spiral.vpcf" end
-- function modifier_ability_thdots_lettyEx:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_ability_thdots_lettyEx:DeclareFunctions()
	return
	{
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		-- MODIFIER_EVENT_ON_ORDER,
	}
end

function modifier_ability_thdots_lettyEx:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("movement_decrease") * self:GetStackCount()
end


function modifier_ability_thdots_lettyEx:GetModifierMagicalResistanceBonus()
	return self:GetAbility():GetSpecialValueFor("resistance_bonus") * self:GetStackCount()
end

function modifier_ability_thdots_lettyEx:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("armor_bonus") * self:GetStackCount()
end


function modifier_ability_thdots_lettyEx:GetModifierTotal_ConstantBlock(kv)
	if not IsServer() then return end
	if bit.band(kv.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then return 0 end
	if kv.attacker:IsHero() or self:GetStackCount() == 0 then
		return 0
	else
		return kv.damage * self:GetAbility():GetSpecialValueFor("imcome_damage") / 100
	end
end

function modifier_ability_thdots_lettyEx:OnCreated()
	if not IsServer() then return end
	self.caster 		= self:GetCaster()
	self.point 			= self:GetCaster():GetOrigin()
	self.active_time 	= self:GetAbility():GetSpecialValueFor("active_time")
	self.react_time		= 0
 	self:StartIntervalThink(FrameTime())

 	local particle_name =  "particles/econ/items/crystal_maiden/ti9_immortal_staff/cm_ti9_staff_lvlup_globe.vpcf"
 	local particle_name_2 =  "particles/econ/items/ancient_apparition/ancient_apparation_ti8/ancient_ice_vortex_ti8_ring_spiral.vpcf"
	self.fxIndex = ParticleManager:CreateParticle(particle_name, PATTACH_CUSTOMORIGIN_FOLLOW, self.caster)
	ParticleManager:SetParticleControlEnt(self.fxIndex , 0, self.caster, 5, "attach_hitloc", Vector(0,0,0), true)
	self.fxIndex_2 = ParticleManager:CreateParticle(particle_name_2, PATTACH_CUSTOMORIGIN_FOLLOW, self.caster)
	ParticleManager:SetParticleControlEnt(self.fxIndex_2 , 0, self.caster, 5, "attach_hitloc", Vector(0,0,0), true)
	ParticleManager:SetParticleControl(self.fxIndex, 5, Vector(0.6,1,5))
end

function modifier_ability_thdots_lettyEx:OnDestroy()
	if not IsServer() then return end
	ParticleManager:DestroyParticleSystem(self.fxIndex,true)
	ParticleManager:DestroyParticleSystem(self.fxIndex_2,true)
end

function modifier_ability_thdots_lettyEx:OnIntervalThink()
	if not IsServer() then return end
	self.count = self:GetAbility():GetSpecialValueFor("count") -- + FindTelentValue(self:GetCaster(),"special_bonus_unique_letty_3")
	--开启开关则加层数
	self.react_time = self.react_time + FrameTime()
	if self.react_time >= self.active_time and self:GetStackCount() < self.count then
		self:IncrementStackCount()
		self.react_time = 0
	end

	--位置不变则加层数
	-- if self.caster:GetOrigin() == self.point then
	-- 	if self.react_time >= self.active_time and self:GetStackCount() < self.count then
	-- 		self:IncrementStackCount()
	-- 		self.react_time = 0
	-- 	end
	-- 	self.react_time = self.react_time + 0.1
	-- else
	-- 	self:GetParent():SetContextThink("lettyEx_IsMove",function ()
	-- 		if GameRules:IsGamePaused() then return FrameTime() end
	-- 			print(self:GetParent():IsMoving())
	-- 			if self:GetParent():IsMoving() then
	-- 				self:SetStackCount(0)
	-- 				self.react_time = 0
	-- 				-- self.point = self.caster:GetOrigin()
	-- 			end
	-- 		end,0.05)
	-- 	self.point = self.caster:GetOrigin()
	-- end

	-- if FindTelentValue(self:GetCaster(),"special_bonus_unique_letty_1") ~= 0 and not self:GetCaster():HasModifier("modifier_ability_thdots_lettyEx_talent_1") then
	-- 	self:GetCaster():AddNewModifier(self:GetCaster(),self:GetAbility(),"modifier_ability_thdots_lettyEx_talent_1",{})
	-- end

end

--右键移动断层数
function modifier_ability_thdots_lettyEx:OnOrder(keys)
	if not IsServer() then return end
	if keys.unit == self:GetParent() then
		self:GetParent():SetContextThink("lettyEx_IsMove",function ()
			if GameRules:IsGamePaused() then return FrameTime() end
				print(keys.unit:IsMoving())
				if self:GetParent():IsMoving() then
					self:SetStackCount(0)
					self.react_time = 0
				end
			end,0.05)
		-- if keys.order_type == 1 then
		-- 	self:SetStackCount(0)
		-- 	self.react_time = 0
		-- elseif keys.order_type == 4 or keys.order_type == 3 then
		-- 	local stand_point = keys.unit:GetOrigin()
		-- 	self:GetParent():SetContextThink("lettyEx_IsMove",function ()
		-- 		if GameRules:IsGamePaused() then return FrameTime() end
		-- 		if stand_point ~= keys.unit:GetOrigin() then
		-- 			self:SetStackCount(0)
		-- 			self.react_time = 0
		-- 		end
		-- 	end,FrameTime())
		-- end
	end
end

modifier_ability_thdots_lettyEx_talent_1 = {}
LinkLuaModifier("modifier_ability_thdots_lettyEx_talent_1","scripts/vscripts/abilities/abilityletty.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_lettyEx_talent_1:IsHidden() 		return true end
function modifier_ability_thdots_lettyEx_talent_1:IsPurgable()		return false end
function modifier_ability_thdots_lettyEx_talent_1:RemoveOnDeath() 	return false end
function modifier_ability_thdots_lettyEx_talent_1:IsDebuff()		return false end

--------------------------------------------------------
--冬符「花之凋零]
--------------------------------------------------------
ability_thdots_letty01 = {}

function ability_thdots_letty01:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

function ability_thdots_letty01:GetAOERadius()
	-- if self:GetCaster():HasModifier("modifier_ability_thdots_lettyEx_talent_1") then
	-- 	return self:GetSpecialValueFor("radius") + 200
	-- else
		return self:GetSpecialValueFor("radius")
	-- end
end

function ability_thdots_letty01:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor("duration")
	self.damage = self:GetSpecialValueFor("damage")
	self.caster = self:GetCaster()
	self.radius = self:GetSpecialValueFor("radius") -- + FindTelentValue(self:GetCaster(),"special_bonus_unique_letty_1")
	self.explosion_interval = 1
	self.frametime = 0
	self.point = self:GetCursorPosition()

	caster:AddNewModifier(caster, self, "modifier_ability_thdots_letty01_channel",{duration = duration})
	self.freezing_field_aura = CreateModifierThinker(caster, self, "modifier_ability_thdots_letty01", {duration = duration}, self.point, caster:GetTeamNumber(), false)
	self.freezing_field_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_crystalmaiden/maiden_freezing_field_snow.vpcf", PATTACH_CUSTOMORIGIN, self.freezing_field_aura)

	ParticleManager:SetParticleControl(self.freezing_field_particle, 0, self.point)
	ParticleManager:SetParticleControl(self.freezing_field_particle, 1, Vector (self.radius, 0, 0))
	ParticleManager:SetParticleControl(self.freezing_field_particle, 5, Vector (self.radius, 0, 0))
	self:EmitSound("hero_Crystal.freezingField.wind")

end

function ability_thdots_letty01:OnChannelThink()
	if not IsServer() then return end
	if self.frametime == nil then self.frametime = 0 end
	self.frametime = self.frametime + FrameTime()
	if self.frametime >= self.explosion_interval then
		self.frametime = 0
		local caster = self.caster
		local damage = self.damage
		local point = self.point
		local radius = self.radius
		local targets = FindUnitsInRadius(caster:GetTeam(), point,nil,radius,self:GetAbilityTargetTeam(),
			self:GetAbilityTargetType(),0,0,false)
		--特效音效
		for i=0,math.floor(radius/50) do
			local random_point = GetGroundPosition(Vector(point.x + RandomInt(-radius, radius),point.y + RandomInt(-radius/2, radius),0), nil)
			local particle_name =  "particles/units/heroes/hero_crystalmaiden/maiden_freezing_field_explosion.vpcf"
			local fxIndex = ParticleManager:CreateParticle(particle_name, PATTACH_CUSTOMORIGIN, caster)
			ParticleManager:SetParticleControl(fxIndex, 0, random_point)
			ParticleManager:SetParticleControl(fxIndex, 1, random_point)
			ParticleManager:ReleaseParticleIndex(fxIndex)
		end

		EmitSoundOnLocationWithCaster(point, "hero_Crystal.freezingField.explosion", self:GetCaster())

		self:SetContextThink("letty01",
			function ()
			if GameRules:IsGamePaused() then return FrameTime() end
			for _,v in pairs (targets) do
				--添加视野
				AddFOWViewer(v:GetTeamNumber(), caster:GetOrigin(),128,1, false)
				local damage_tabel = {
						victim 			= v,
						damage 			= damage,
						damage_type		= self:GetAbilityDamageType(),
						attacker 		= caster,
						ability 		= self
					}
				UnitDamageTarget(damage_tabel)
			end
		end,0.4)
	end
end

function ability_thdots_letty01:OnChannelFinish()
	if not IsServer() then return end
	-- print(self.freezing_field_aura:GetRemainingTime())
	-- self.freezing_field_aura:Destroy()
	self:StopSound("hero_Crystal.freezingField.wind")
	ParticleManager:DestroyParticle(self.freezing_field_particle, false)
	ParticleManager:ReleaseParticleIndex(self.freezing_field_particle)
	self:GetCaster():RemoveModifierByName("modifier_ability_thdots_letty01_channel")
end


modifier_ability_thdots_letty01 = {}
LinkLuaModifier("modifier_ability_thdots_letty01","scripts/vscripts/abilities/abilityletty.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_letty01:IsHidden() 		return true end
function modifier_ability_thdots_letty01:IsPurgable()		return false end
function modifier_ability_thdots_letty01:RemoveOnDeath() 	return false end
function modifier_ability_thdots_letty01:IsDebuff()		return false end

-- function modifier_ability_thdots_letty01:OnCreated()
-- 	if not IsServer() then return end
-- 	self.caster = self:GetCaster()
-- 	self.radius = self:GetAbility():GetSpecialValueFor("radius")
-- 	self.damage = self:GetAbility():GetSpecialValueFor("damage")
-- 	local duration = self:GetAbility():GetSpecialValueFor("duration")
-- 	print(self.point)
-- 	-- self:StartIntervalThink(1)
-- end

-- function modifier_ability_thdots_letty01:OnDestroy()
-- 	if not IsServer() then return end
-- 	ParticleManager:DestroyParticle(self.freezing_field_particle, false)
-- 	ParticleManager:ReleaseParticleIndex(self.freezing_field_particle)
-- end

-- function modifier_ability_thdots_letty01:OnIntervalThink()
-- 	if not IsServer() then return end
-- 	local caster = self.caster
-- 	local ability = self:GetAbility()
-- 	local damage = self.damage
-- 	local point = self:GetAbility().point
-- 	local targets = FindUnitsInRadius(caster:GetTeam(), point,nil,self.radius,ability:GetAbilityTargetTeam(),
-- 		ability:GetAbilityTargetType(),0,0,false)
-- 	--特效音效
-- 	local particle_name =  "particles/units/heroes/hero_crystalmaiden/maiden_freezing_field_explosion.vpcf"
-- 	local fxIndex = ParticleManager:CreateParticle(particle_name, PATTACH_CUSTOMORIGIN, caster)
-- 	ParticleManager:SetParticleControl(fxIndex, 0, point)
-- 	ParticleManager:SetParticleControl(fxIndex, 1, point)
-- 	ParticleManager:ReleaseParticleIndex(fxIndex)

-- 	print("do it")
-- 	for _,v in pairs (targets) do
-- 		local damage_tabel = {
-- 				victim 			= v,
-- 				damage 			= damage,
-- 				damage_type		= ability:GetAbilityDamageType(),
-- 				damage_flags 	= ability:GetAbilityTargetFlags(),
-- 				attacker 		= caster,
-- 				ability 		= ability
-- 			}
-- 		UnitDamageTarget(damage_tabel)
-- 	end
-- end

modifier_ability_thdots_letty01_channel = {}
LinkLuaModifier("modifier_ability_thdots_letty01_channel","scripts/vscripts/abilities/abilityletty.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_letty01_channel:IsHidden() 		return true end
function modifier_ability_thdots_letty01_channel:IsPurgable()		return false end
function modifier_ability_thdots_letty01_channel:RemoveOnDeath() 	return false end
function modifier_ability_thdots_letty01_channel:IsDebuff()		return false end

--------------------------------------------------------
--白符「波光]
--------------------------------------------------------
ability_thdots_letty02 = {}


function ability_thdots_letty02:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end


function ability_thdots_letty02:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local player = caster:GetPlayerID()
	local duration = self:GetSpecialValueFor("duration")
	local number = self:GetSpecialValueFor("number") + FindTelentValue(self:GetCaster(),"special_bonus_unique_letty_1")
	local speed = self:GetSpecialValueFor("speed")
	local cast_range = self:GetSpecialValueFor("cast_range")
	self.start_point = self:GetCaster():GetAttachmentOrigin(self:GetCaster():ScriptLookupAttachment("attach_attack1"))

	--播放动画
	if caster:GetName() == "npc_dota_hero_winter_wyvern" and not caster:IsChanneling() then
		caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_2,2)
	end

	local point = caster:GetOrigin() + caster:GetForwardVector() * cast_range
	local angle = 360/number
	local qangle = QAngle(0, angle, 0)
	point = RotatePosition(self.start_point, qangle, point)

	--音效
	caster:EmitSound("Hero_Lich.ChainFrost")
	
	for i=0,number do
		-- local dummy = CreateUnitByName("npc_dota_hero_winter_wyvern", 
		local dummy = CreateUnitByName("npc_dummy_unit", 
	    	                        self.start_point, 
									false, 
								    caster, 
									caster, 
									caster:GetTeamNumber()
									)
									local ability_dummy_unit = dummy:FindAbilityByName("ability_dummy_unit")
									ability_dummy_unit:SetLevel(1)
		-- dummy:SetPlayerID(caster:GetPlayerID())
		-- dummy:SetControllableByPlayer(player, true)
		dummy:AddNewModifier(caster, self, "modifier_ability_thdots_letty02_dummy",{duration = 5})
		dummy.letty02_point = point
		point = RotatePosition(self.start_point, qangle, point)
		qangle = QAngle(0, angle, 0)
	end
end


modifier_ability_thdots_letty02_dummy = {}
LinkLuaModifier("modifier_ability_thdots_letty02_dummy","scripts/vscripts/abilities/abilityletty.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_letty02_dummy:IsHidden() 		return false end
function modifier_ability_thdots_letty02_dummy:IsPurgable()		return false end
function modifier_ability_thdots_letty02_dummy:RemoveOnDeath() 	return false end
function modifier_ability_thdots_letty02_dummy:IsDebuff()		return false end
function modifier_ability_thdots_letty02_dummy:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_ability_thdots_letty02_dummy:OnCreated()
	if not IsServer() then return end
	-- body
	self.caster 				= self:GetCaster()
	self.start_point 			= self:GetAbility().start_point
	self.stun_duration 			= self:GetAbility():GetSpecialValueFor("stun_duration") + FindTelentValue(self:GetCaster(),"special_bonus_unique_letty_2")
	self.damage 				= self:GetAbility():GetSpecialValueFor("damage")
	self.limit 					= self:GetAbility():GetSpecialValueFor("limit")
	self.speed 					= self:GetAbility():GetSpecialValueFor("speed") * FrameTime()
	self.angle = 0
	local dummy = self:GetParent()
	local particle = "particles/units/heroes/hero_lich/lich_chain_frost.vpcf"
	self.fxIndex = ParticleManager:CreateParticle(particle, PATTACH_CUSTOMORIGIN, dummy)
	-- ParticleManager:SetParticleControl(self.fxIndex, 0, dummy:GetOrigin())
	ParticleManager:SetParticleControlEnt(self.fxIndex , 0, dummy, 5, "attach_hitloc", Vector(0,0,0), true)
	-- ParticleManager:DestroyParticleSystemTime(effectIndex,keys.Duration)
	ParticleManager:SetParticleControl(self.fxIndex, 0, dummy:GetOrigin())
	ParticleManager:SetParticleControl(self.fxIndex, 1, dummy:GetOrigin())
	ParticleManager:SetParticleControl(self.fxIndex, 2, Vector(2000,0,0))
	self:StartIntervalThink(FrameTime())
end

function modifier_ability_thdots_letty02_dummy:OnIntervalThink()
	if not IsServer() then return end
	local caster = self.caster
	local dummy = self:GetParent()
	local ability = self:GetAbility()
	local qangle = QAngle(0, 30, 0)
	local add_increase		= 1	--递增角度
	local max_angel			= 10--最大发射角度
	if self.angle <= max_angel then
		self.angle = self.angle + add_increase
	else
		self.angle = -self.angle
		self.angle = self.angle - add_increase
	end
	qangle = QAngle(0, self.angle, 0)
	local direct = (dummy.letty02_point - dummy:GetOrigin()):Normalized()
	dummy.letty02_point = RotatePosition(self.start_point, qangle, dummy.letty02_point)

	ParticleManager:SetParticleControl(self.fxIndex, 1, dummy:GetOrigin())
	-- ParticleManager:SetParticleControl(self.fxIndex, 0, dummy:GetOrigin())
	-- ParticleManager:SetParticleControl(self.fxIndex, 2, Vector(2000,0,0))


	--冰冻伤害
	local targets = FindUnitsInRadius(caster:GetTeam(), dummy:GetOrigin(),nil,128,ability:GetAbilityTargetTeam(),
			ability:GetAbilityTargetType(),0,0,false)
	DeleteDummy(targets)
	for _,v in pairs(targets) do
		if not v:HasModifier("modifier_ability_thdots_letty02_mark") then
			v:AddNewModifier(caster, ability, "modifier_ability_thdots_letty02_debuff", {duration = self.stun_duration * (1 - v:GetStatusResistance())})
			v:AddNewModifier(caster, ability, "modifier_ability_thdots_letty02_mark", {duration = 1})
			self.limit = self.limit - 1
			if self.limit <= 0 then
				self:Destroy()
				return
			end
		end
	end

	--移动
	local next_point = dummy:GetOrigin() + direct * self.speed
	next_point.z = self.start_point.z
	dummy:SetOrigin(next_point)
	if ( dummy:GetOrigin() - self.start_point):Length2D() > 700 then
		self:Destroy()
	end
end

function modifier_ability_thdots_letty02_dummy:OnDestroy()
	if not IsServer() then return end
	local dummy = self:GetParent()
	dummy:EmitSound("Hero_Lich.ChainFrostImpact.Creep")
	dummy:RemoveSelf()
	-- ParticleManager:DestroyParticleSystem(self.fxIndex,true)
	ParticleManager:ReleaseParticleIndex(self.fxIndex)
end

modifier_ability_thdots_letty02_mark = {}
LinkLuaModifier("modifier_ability_thdots_letty02_mark","scripts/vscripts/abilities/abilityletty.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_letty02_mark:IsHidden() 		return true end
function modifier_ability_thdots_letty02_mark:IsPurgable()		return false end
function modifier_ability_thdots_letty02_mark:IsDebuff()		return false end

modifier_ability_thdots_letty02_debuff = {}
LinkLuaModifier("modifier_ability_thdots_letty02_debuff","scripts/vscripts/abilities/abilityletty.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_letty02_debuff:IsHidden() 		return false end
function modifier_ability_thdots_letty02_debuff:IsPurgable()		return true end
function modifier_ability_thdots_letty02_debuff:RemoveOnDeath() 	return true end
function modifier_ability_thdots_letty02_debuff:IsDebuff()		return true end

function modifier_ability_thdots_letty02_debuff:GetEffectName() return "particles/units/heroes/hero_crystalmaiden/maiden_frostbite_buff.vpcf" end
function modifier_ability_thdots_letty02_debuff:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end


function modifier_ability_thdots_letty02_debuff:CheckState() --冻结
	return {
		[MODIFIER_STATE_STUNNED] = true,
	}
end

function modifier_ability_thdots_letty02_debuff:OnRefresh(keys)
	if not IsServer() then return end
	self:OnCreated(keys)
end

function modifier_ability_thdots_letty02_debuff:OnCreated()
	if not IsServer() then return end
	-- body
	local caster 				= self:GetCaster()
	local target 				= self:GetParent()
	local ability 				= self:GetAbility()
	local damage 				= self:GetAbility():GetSpecialValueFor("damage")


	self:GetParent():EmitSound("Hero_Crystal.Frostbite")
	local damage_tabel = {
				victim 			= target,
				damage 			= damage,
				damage_type		= ability:GetAbilityDamageType(),
				attacker 		= caster,
				ability 		= ability
			}
	UnitDamageTarget(damage_tabel)
end

--------------------------------------------------------
--「霜心之大地」
--------------------------------------------------------
ability_thdots_letty03 = {}

function ability_thdots_letty03:GetIntrinsicModifierName()
	return "modifier_ability_thdots_letty03"
end

modifier_ability_thdots_letty03 = {}
LinkLuaModifier("modifier_ability_thdots_letty03","scripts/vscripts/abilities/abilityletty.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_letty03:IsHidden() 		return false end
function modifier_ability_thdots_letty03:IsPurgable()		return false end
function modifier_ability_thdots_letty03:RemoveOnDeath() 	return false end
function modifier_ability_thdots_letty03:IsDebuff()		return false end

function modifier_ability_thdots_letty03:GetEffectName() return "particles/generic_gameplay/generic_slowed_cold.vpcf" end
function modifier_ability_thdots_letty03:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_ability_thdots_letty03:DeclareFunctions()
	return
	{
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

function modifier_ability_thdots_letty03:GetModifierHealthBonus()
	return self:GetAbility():GetSpecialValueFor("health_bonus")
end


function modifier_ability_thdots_letty03:OnTakeDamage(keys)
	if not IsServer() then return end
	local caster = self:GetParent()
	if keys.attacker:GetTeam() == keys.unit:GetTeam() or caster.Poison == true then caster.Poison = false return end
	if keys.attacker == self:GetParent() and keys.damage_type == DAMAGE_TYPE_MAGICAL and self:GetStackCount() == 0 then
		local duration = self:GetAbility():GetSpecialValueFor("duration")
		local damage = self:GetAbility():GetSpecialValueFor("damage_perdamage")
		local count_limit = self:GetAbility():GetSpecialValueFor("count_limit") + FindTelentValue(self:GetCaster(),"special_bonus_unique_letty_7")
		--if FindTelentValue(self:GetCaster(),"special_bonus_unique_letty_5") ~= 0 then
		--	damage = damage + keys.unit:GetHealth() * FindTelentValue(self:GetCaster(),"special_bonus_unique_letty_5") / 100
		--end
		if keys.unit:HasModifier("modifier_ability_thdots_letty03_debuff") then
			local modifier_debuff = keys.unit:FindModifierByName("modifier_ability_thdots_letty03_debuff")
			modifier_debuff:SetDuration(duration, true)
			if modifier_debuff:GetStackCount() < count_limit then
				modifier_debuff:IncrementStackCount()
			else
				modifier_debuff:SetStackCount(count_limit)
			end
			damage = damage + self:GetAbility():GetSpecialValueFor("damage_percount") * (modifier_debuff:GetStackCount()-1)
		elseif keys.unit:IsAlive() then
			keys.unit:AddNewModifier(self:GetCaster(), self:GetAbility(),"modifier_ability_thdots_letty03_debuff", {duration = duration * (1 - self:GetParent():GetStatusResistance())}):SetStackCount(1)
		end
		--特效音效
		local damage_tabel = {
				victim 			= keys.unit,
				damage 			= damage,
				damage_type		= self:GetAbility():GetAbilityDamageType(),
				attacker 		= self:GetParent(),
				ability 		= self:GetAbility()
			}
		--添加视野
		self:SetStackCount(1)
		UnitDamageTarget(damage_tabel)
		self:SetStackCount(0)
	end
end

modifier_ability_thdots_letty03_debuff = {}
LinkLuaModifier("modifier_ability_thdots_letty03_debuff","scripts/vscripts/abilities/abilityletty.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_letty03_debuff:IsHidden() 		return false end
function modifier_ability_thdots_letty03_debuff:IsPurgable()		return true end
function modifier_ability_thdots_letty03_debuff:RemoveOnDeath() 	return true end
function modifier_ability_thdots_letty03_debuff:IsDebuff()		return true end
-- function modifier_ability_thdots_letty03_debuff:GetAttributes()		return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_ability_thdots_letty03_debuff:GetEffectName() return "particles/generic_gameplay/generic_slowed_cold.vpcf" end
function modifier_ability_thdots_letty03_debuff:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_ability_thdots_letty03_debuff:OnCreated()
	if not IsServer() then return end
	self.movement_slow = self:GetAbility():GetSpecialValueFor("decrease_speed")
	self.movement_slow_stack = self:GetAbility():GetSpecialValueFor("decrease_speed_pc")

	self:SetHasCustomTransmitterData(true)
end

function modifier_ability_thdots_letty03_debuff:DeclareFunctions()
	return
	{
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_DISABLE_HEALING,
	}
end

function modifier_ability_thdots_letty03_debuff:OnRefresh()
	if not IsServer() then return end
	self:OnCreated()

	self:SendBuffRefreshToClients()
end

function modifier_ability_thdots_letty03_debuff:AddCustomTransmitterData()
	return {
		movement_slow = self.movement_slow,
		movement_slow_stack = self.movement_slow_stack,
	}
end
function modifier_ability_thdots_letty03_debuff:HandleCustomTransmitterData(data)
	self.movement_slow = data.movement_slow
	self.movement_slow_stack = data.movement_slow_stack
end

function modifier_ability_thdots_letty03_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.movement_slow + self.movement_slow_stack * (self:GetStackCount()-1)
end

function modifier_ability_thdots_letty03_debuff:GetDisableHealing()
	if FindTelentValue(self:GetCaster(),"special_bonus_unique_letty_5")~=0 and self:GetStackCount() >= 5 then
		return 1
	else
		return 0
	end
end

--------------------------------------------------------
--寒符「Cold Snap]
--------------------------------------------------------

ability_thdots_letty04 = {}

function ability_thdots_letty04:GetCastRange()
	return self:GetSpecialValueFor("radius")
end

--function ability_thdots_letty04:GetCooldown(level)
--	if self:GetCaster():HasModifier("modifier_item_wanbaochui") then
--		return self:GetSpecialValueFor("wanbaochui_cooldown")
--	else
--		return self:GetSpecialValueFor("cooldown")
--	end
--end

function ability_thdots_letty04:OnSpellStart()
	if not IsServer() then return end
	local caster 				= self:GetCaster()
	local duration  			= self:GetSpecialValueFor("duration")
	self.radius  				= self:GetSpecialValueFor("radius")
	if self:GetCaster():HasModifier("modifier_item_wanbaochui") then
		self.radius = self.radius + 30000
		--duration = self:GetSpecialValueFor("wanbaochui_duration")
	end
	-- caster:AddNewModifier(caster, self, "modifier_ability_thdots_letty04", {duration = duration})
	CreateModifierThinker(caster, self, "modifier_ability_thdots_letty04", {duration = duration}, caster:GetOrigin(), caster:GetTeamNumber(), false)

end

modifier_ability_thdots_letty04 = {}
LinkLuaModifier("modifier_ability_thdots_letty04","scripts/vscripts/abilities/abilityletty.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_letty04:IsHidden() 		return false end
function modifier_ability_thdots_letty04:IsPurgable()		return false end
function modifier_ability_thdots_letty04:RemoveOnDeath() 	return true end
function modifier_ability_thdots_letty04:IsDebuff()		return false end

function modifier_ability_thdots_letty04:GetAuraRadius() return self.radius end -- global
function modifier_ability_thdots_letty04:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NONE end
function modifier_ability_thdots_letty04:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_ability_thdots_letty04:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP end
function modifier_ability_thdots_letty04:GetModifierAura() return "modifier_ability_thdots_letty04_debuff" end
function modifier_ability_thdots_letty04:IsAura() return true end

function modifier_ability_thdots_letty04:OnCreated()
	self.radius = self:GetAbility().radius
	if not IsServer() then return end
	local dummy = self:GetParent()
	local radius = self:GetAbility().radius
	local talent_effect_point = dummy:GetOrigin()
	--特效音效
	if self:GetCaster():HasModifier("modifier_item_wanbaochui") then
		talent_effect_point = Vector(0,0,0)
		EmitAnnouncerSoundForPlayer("hero_Crystal.freezingField.wind", self:GetCaster():GetPlayerID())
		EmitGlobalSound("hero_Crystal.freezingField.wind")
	end
	-- local particle = "particles/units/heroes/hero_lich/lich_chain_frost.vpcf"
	-- self.fxIndex = ParticleManager:CreateParticle(particle, PATTACH_CUSTOMORIGIN, dummy)
	-- -- ParticleManager:SetParticleControl(self.fxIndex, 0, dummy:GetOrigin())
	-- ParticleManager:SetParticleControlEnt(self.fxIndex , 0, dummy, 5, "attach_hitloc", Vector(0,0,0), true)
	-- -- ParticleManager:DestroyParticleSystemTime(effectIndex,keys.Duration)
	-- ParticleManager:SetParticleControl(self.fxIndex, 0, dummy:GetOrigin())
	
	self:GetParent():EmitSound("hero_Crystal.freezingField.wind")
	local particle_1 = "particles/units/heroes/hero_lich/lich_ice_spire.vpcf"
	local particle_2 = "particles/units/heroes/hero_crystalmaiden/maiden_freezing_field_snow.vpcf"
	self.letty04_particle_1 = ParticleManager:CreateParticle(particle_1, PATTACH_CUSTOMORIGIN, dummy)
	self.letty04_particle_2 = ParticleManager:CreateParticle(particle_2, PATTACH_CUSTOMORIGIN, dummy)
	-- ParticleManager:SetParticleControl(self.fxIndex, 0, dummy:GetOrigin())
	ParticleManager:SetParticleControl(self.letty04_particle_1, 0, talent_effect_point)
	ParticleManager:SetParticleControl(self.letty04_particle_1, 1, talent_effect_point)
	ParticleManager:SetParticleControl(self.letty04_particle_1, 2, talent_effect_point)
	ParticleManager:SetParticleControl(self.letty04_particle_1, 3, talent_effect_point)
	ParticleManager:SetParticleControl(self.letty04_particle_1, 4, talent_effect_point)
	ParticleManager:SetParticleControl(self.letty04_particle_1, 5, Vector(radius,radius,radius))
	ParticleManager:SetParticleControl(self.letty04_particle_2, 0, talent_effect_point)
	ParticleManager:SetParticleControl(self.letty04_particle_2, 1, Vector(radius,0,0))
	ParticleManager:ReleaseParticleIndex(self.letty04_particle_1)
	ParticleManager:ReleaseParticleIndex(self.letty04_particle_2)
end

function modifier_ability_thdots_letty04:OnDestroy()
	if not IsServer() then return end
	self:GetParent():StopSound("hero_Crystal.freezingField.wind")
end

modifier_ability_thdots_letty04_debuff = {}
LinkLuaModifier("modifier_ability_thdots_letty04_debuff","scripts/vscripts/abilities/abilityletty.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_ability_thdots_letty04_debuff:IsHidden() 		return false end
function modifier_ability_thdots_letty04_debuff:IsPurgable()		return true end
function modifier_ability_thdots_letty04_debuff:RemoveOnDeath() 	return true end
function modifier_ability_thdots_letty04_debuff:IsDebuff()		return true end

function modifier_ability_thdots_letty04_debuff:GetEffectName() return "particles/generic_gameplay/generic_slowed_cold.vpcf" end
function modifier_ability_thdots_letty04_debuff:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_ability_thdots_letty04_debuff:OnCreated()
	if not IsServer() then return end
	self.movement_slow = self:GetAbility():GetSpecialValueFor("decrease_mspeed")
	self.attak_speed_slow_pct = self:GetAbility():GetSpecialValueFor("decrease_aspeed")

	self:SetHasCustomTransmitterData(true)

	self:StartIntervalThink(1)
	if self:GetParent():IsHero() then
	EmitAnnouncerSoundForPlayer("hero_Crystal.freezingField.wind", self:GetParent():GetPlayerID())
	end
end

function modifier_ability_thdots_letty04_debuff:DeclareFunctions()
	return
	{
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE,
	}
end

function modifier_ability_thdots_letty04_debuff:OnRefresh()
	if not IsServer() then return end
	self:OnCreated()

	self:SendBuffRefreshToClients()
end

function modifier_ability_thdots_letty04_debuff:AddCustomTransmitterData()
	return {
		movement_slow = self.movement_slow,
		attak_speed_slow_pct = self.attak_speed_slow_pct,
	}
end
function modifier_ability_thdots_letty04_debuff:HandleCustomTransmitterData(data)
	self.movement_slow = data.movement_slow
	self.attak_speed_slow_pct = data.attak_speed_slow_pct
end

function modifier_ability_thdots_letty04_debuff:OnIntervalThink()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local target = self:GetParent()
	local damage = FindTelentValue(self:GetCaster(),"special_bonus_unique_letty_8") --self:GetAbility():GetSpecialValueFor("wanbaochui_damage")
	local ability = self:GetAbility()
	local damage_tabel = {
				victim 			= target,
				damage 			= damage,
				damage_type		= DAMAGE_TYPE_MAGICAL,
				attacker 		= caster,
				ability 		= ability
			}
	if target:IsHero() and damage~=0 then
		UnitDamageTarget(damage_tabel)
	end
end

function modifier_ability_thdots_letty04_debuff:GetModifierMoveSpeedBonus_Percentage()
	if self:GetParent():HasModifier("modifier_item_dragon_star_buff") --道具:龙星
	or self:GetParent():HasModifier("modifier_meirin02_buff") --红美铃：彩光风铃
	or self:GetParent():HasModifier("modifier_item_tsundere_invulnerable") --亡灵送行提灯
	then
		return 0
	else
		return self.movement_slow
	end
end

function modifier_ability_thdots_letty04_debuff:GetModifierAttackSpeedPercentage()
	if self:GetParent():HasModifier("modifier_item_dragon_star_buff") --道具:龙星
	or self:GetParent():HasModifier("modifier_meirin02_buff") --红美铃：彩光风铃
	or self:GetParent():HasModifier("modifier_item_tsundere_invulnerable") --亡灵送行提灯
	then
		return 0
	else
		return self.attak_speed_slow_pct
	end
end