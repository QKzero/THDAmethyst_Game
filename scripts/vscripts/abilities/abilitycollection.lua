
-- 使用modifierthinker防止P点和点封野

aura_ability_collection_find_master_lua = {}
LinkLuaModifier("aura_ability_collection_find_master_lua", "scripts/vscripts/abilities/abilityCollection.lua", LUA_MODIFIER_MOTION_NONE)

function aura_ability_collection_find_master_lua:IsHidden()			return true end
function aura_ability_collection_find_master_lua:IsPurgable()		return false end
function aura_ability_collection_find_master_lua:RemoveOnDeath()	return false end
function aura_ability_collection_find_master_lua:IsDebuff()			return false end

function aura_ability_collection_find_master_lua:IsAura()				return true end
function aura_ability_collection_find_master_lua:GetAuraDuration()		return 0 end
function aura_ability_collection_find_master_lua:GetAuraRadius()		return 500.0 end
function aura_ability_collection_find_master_lua:GetAuraSearchTeam()	return DOTA_UNIT_TARGET_TEAM_BOTH end
function aura_ability_collection_find_master_lua:GetAuraSearchType()	return DOTA_UNIT_TARGET_HERO end
function aura_ability_collection_find_master_lua:GetAuraSearchFlags()	return DOTA_UNIT_TARGET_FLAG_NONE end
function aura_ability_collection_find_master_lua:GetModifierAura()		return "modifier_ability_collection_move_lua" end

function aura_ability_collection_find_master_lua:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MODEL_CHANGE,
	}
end

function aura_ability_collection_find_master_lua:GetModifierModelChange()
	return self.model
end

function aura_ability_collection_find_master_lua:OnCreated(keys)
	if not IsServer() then return end

	self.model = keys.model

	self:GetParent():SetUnitName(keys.name)
	self:GetParent():SetModelScale(0.1)
end

modifier_ability_collection_move_lua = {}
LinkLuaModifier("modifier_ability_collection_move_lua", "scripts/vscripts/abilities/abilityCollection.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_ability_collection_move_lua:IsHidden()		return true end
function modifier_ability_collection_move_lua:IsPurgable()		return false end
function modifier_ability_collection_move_lua:RemoveOnDeath()	return false end
function modifier_ability_collection_move_lua:IsDebuff()		return false end
function modifier_ability_collection_move_lua:GetAttributes()	return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_ability_collection_move_lua:OnCreated()

	self.FindRadius = 500.0
	self.MaxMovespeed = 25

	self:StartIntervalThink(0.03)
end

function modifier_ability_collection_move_lua:OnIntervalThink()

	OnCollectionMoveToMaster({caster = self:GetAuraOwner(), target = self:GetParent(), FindRadius = self.FindRadius, MaxMovespeed = self.MaxMovespeed})
end

function OnCollectionPower(keys)
	print("OnCollectionPower")
	local caster = EntIndexToHScript(keys.caster_entindex)
	caster:SetContextNum("ability_collection_power_speed",2,0)
	local vecCaster = caster:GetOrigin()
	local targets = keys.target_entities
	for _,v in pairs(targets) do
		if((v:GetUnitName()=="npc_coin_up_unit") or (v:GetUnitName()== "npc_power_up_unit"))then
			if(v:GetContext("ability_collection_power")==nil)then
				v:SetThink(
				function()
					OnCollectionPowerMove(v,caster)
					return FrameTime()
				end, 
				"ability_collection_power",
				FrameTime())
			end
		end
	end
end

function OnGetCollection(Collection,Hero)
	local vecHero = Hero:GetOrigin()
	print("GEtPOWER")
	print(Collection.IsGet)
	if((Collection:GetUnitName()=="npc_coin_up_unit"))then
		local effectIndex = ParticleManager:CreateParticle("particles/items2_fx/hand_of_midas.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(effectIndex, 0, vecHero)
		ParticleManager:SetParticleControl(effectIndex, 1, vecHero)
		ParticleManager:DestroyParticleSystem(effectIndex,false)
		local ply = Hero:GetOwner()
		local playerId = ply:GetPlayerID()
		local modifyGold = PlayerResource:GetReliableGold(playerId) + 35
		PlayerResource:SetGold(playerId, modifyGold, true)
		-- SendOverheadEventMessage(Hero:GetOwner(),OVERHEAD_ALERT_GOLD,Hero,35,nil)
	-- elseif(Collection:GetUnitName()=="npc_power_up_unit")then
	elseif(Collection:GetUnitName()=="npc_power_up_unit") and Collection.IsGet == false then
		Collection.IsGet = true
		local powerCount = Hero:GetContext("hero_bouns_stat_power_count")
		if(powerCount==nil)then
			Hero:SetContextNum("hero_bouns_stat_power_count",0,0)
			powerCount = 0
		end
		if(powerCount<30)then
			local effectIndex = ParticleManager:CreateParticle("particles/items_fx/aegis_respawn_spotlight.vpcf", PATTACH_CUSTOMORIGIN, Hero)
			ParticleManager:SetParticleControl(effectIndex, 0, vecHero)
			ParticleManager:ReleaseParticleIndex(effectIndex)
			powerCount = powerCount + 1
			print(powerCount)
			Hero:SetContextNum("hero_bouns_stat_power_count",powerCount,0)
			local ability = Hero:FindAbilityByName("ability_common_power_buff")
			if ability then
				if(Hero:GetPrimaryAttribute()==0)then
					Hero:SetModifierStackCount("common_thdots_power_str_buff",ability,powerCount)
				elseif(Hero:GetPrimaryAttribute()==1)then
					Hero:SetModifierStackCount("common_thdots_power_agi_buff",ability,powerCount)
				elseif(Hero:GetPrimaryAttribute()==2)then
					Hero:SetModifierStackCount("common_thdots_power_int_buff",ability,powerCount)
				else
					Hero:SetModifierStackCount("common_thdots_power_all_buff",ability,powerCount)
				end
			end
		end
	end
	Hero:EmitSound("THD_GetPower")
	Collection:RemoveSelf()
end

function OnCollectionPowerMove(target,caster)
	local vecTarget = target:GetOrigin()
	local vecCaster = caster:GetOrigin()
	local speed = caster:GetContext("ability_collection_power_speed") + 1
	local radForward = GetRadBetweenTwoVec2D(vecTarget,vecCaster)
	local vecForward = Vector(math.cos(radForward) * speed,math.sin(radForward) * speed,1)
	vecTarget = vecTarget + vecForward
	
	target:SetOrigin(vecTarget)
	caster:SetContextNum("ability_collection_power_speed",speed,0)
	if(GetDistanceBetweenTwoVec2D(vecTarget,vecCaster)<50)then
		OnGetCollection(target,caster)
	end
end

function OnCollectionMoveToMaster(keys)
	local Collection = keys.caster
	local Hero = keys.target
	if (Collection~=nil and Hero:IsRealHero()) then
		local vecCollection = Collection:GetAbsOrigin()
		local vecHero = Hero:GetAbsOrigin()
		local Vec = vecHero - vecCollection
		local Distance = GetDistanceBetweenTwoVec2D(vecHero,vecCollection)
		if (Distance<keys.FindRadius) then
			local MoveDistance = (keys.FindRadius-Distance)/keys.FindRadius*keys.MaxMovespeed
			local ts=keys.FindRadius/GetDistanceBetweenTwoVec2D(vecHero,vecCollection)
			Collection:SetAbsOrigin(vecCollection + Vec:Normalized()*MoveDistance)
			if(GetDistanceBetweenTwoVec2D(vecCollection,vecHero)<25)then
				OnGetCollection(Collection,Hero)
			end
		end
	end
end


