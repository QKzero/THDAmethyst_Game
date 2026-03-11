--require("util/mode_select")

-- Bot 基础管理器
ability_common_bot_buff = class({})

function ability_common_bot_buff:GetIntrinsicModifierName()
	return "modifier_bot_buff"
end

function ability_common_bot_buff:OnOwnerDied()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local ability = self

	if caster:IsIllusion() then return end

	local now_time = GameRules:GetDOTATime(false, false)
	if (now_time < 300.0) then return end --do not bonus on death before 5min

	local bonus = ability:GetSpecialValueFor("ex_death_gold")
	local casterPlayerID = caster:GetPlayerOwnerID()

	PlayerResource:SetGold(casterPlayerID,PlayerResource:GetUnreliableGold(casterPlayerID) + bonus,false)

	if (now_time > 900.0) then
		local mul = 0.005
		if caster:GetPrimaryAttribute() == 0 then
			caster:SetBaseStrength(caster:GetBaseStrength() + bonus * mul)
		end
		if caster:GetPrimaryAttribute() == 1 then
			caster:SetBaseAgility(caster:GetBaseAgility() + bonus * mul)
		end
		if caster:GetPrimaryAttribute() == 2 then
			caster:SetBaseIntellect(caster:GetBaseIntellect() + bonus * mul)
		end
	end
end

modifier_bot_buff = class({})
LinkLuaModifier("modifier_bot_buff", "scripts/vscripts/abilities/bot_buff.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_bot_buff:IsHidden() return false end
--function modifier_bot_buff:IsDebuff() return false end
function modifier_bot_buff:IsPurgable() return false end
function modifier_bot_buff:RemoveOnDeath() return false end

function modifier_bot_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,

		MODIFIER_EVENT_ON_ATTACK_START,
		MODIFIER_EVENT_ON_UNIT_MOVED,
	}
end

function modifier_bot_buff:GetModifierConstantManaRegen()
	return self:GetAbility():GetSpecialValueFor("mana_regen")
end

function modifier_bot_buff:GetModifierConstantHealthRegen()
	return self:GetAbility():GetSpecialValueFor("hp_regen")
end

 function modifier_bot_buff:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("bouns_value")
end

function modifier_bot_buff:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("bouns_value")
end

 function modifier_bot_buff:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("bouns_value")
end

function modifier_bot_buff:OnCreated(params)
    if not IsServer() then return end
    
    self.caster = self:GetCaster()
    self.ability = self:GetAbility()
    
    self.giveGoldAmount = self.ability:GetSpecialValueFor("give_gold_amount")
    self.giveExpAmount = self.ability:GetSpecialValueFor("give_exp_amount")
    self.giveAttrBonus = self.ability:GetSpecialValueFor("increaseallstat")
    
    self.selfStunChanceOnAttack = self.ability:GetSpecialValueFor("SelfStunchanceATK")
    self.selfStunDurationOnAttack = self.ability:GetSpecialValueFor("self_stun_duration_atk")
    self.selfStunChanceOnMove = self.ability:GetSpecialValueFor("SelfStunchanceMOV")
    self.selfStunDurationOnMove = self.ability:GetSpecialValueFor("self_stun_duration_mov")
    
    self.interval = self.ability:GetSpecialValueFor("interval")
    self:StartIntervalThink(self.interval)
end

function modifier_bot_buff:OnIntervalThink()
    if not IsServer() then return end

    if self.caster:IsIllusion() then return end

    local now_time = GameRules:GetDOTATime(false, false)
    if (now_time < 1.0) then return end
    local caster = self.caster
    local casterPlayerID = caster:GetPlayerOwnerID()
    local add_gold = self.giveGoldAmount
    local add_exp = self.giveExpAmount
    if now_time >= 300.0 and now_time < 600.0 then --30 times
        add_gold = add_gold * 1.25
        add_exp = add_exp * 2
    elseif now_time >= 600.0 and now_time < 1200.0 then --60 times
        add_gold = add_gold * 1.5
        add_exp = add_exp * 2.5
    elseif now_time >= 1200.0 and now_time < 1800.0 then --60 times
        add_gold = add_gold * 1.75
        add_exp = add_exp * 2.75
    elseif now_time >= 1800.0 then
        add_gold = add_gold * 2.5
        add_exp = add_exp * 3
    end
    if now_time <= 600.0 then
        local hcnt = FindUnitsInRadius(
                caster:GetTeam(),
                caster:GetOrigin(),
                nil,
                1200,
                DOTA_UNIT_TARGET_TEAM_FRIENDLY,
                DOTA_UNIT_TARGET_HERO,
                0, FIND_CLOSEST,
                false
        )
        add_exp = add_exp / math.max(#hcnt,1.0)
    else
        local mm=0.1	--6
        if now_time>=600.0 then
            mm=0.2		--12(18)
        end
        if now_time>=1200.0 then
            mm=0.25		--15(33)
        end
        if now_time>=1800.0 then
            mm=0.3		--18(51)
        end
        if now_time>=2400.0 then
            mm=0.15		--9(60)
        end
        if now_time>=3000.0 then
            mm=0.05		--3
        end
        local tmm = {[0]=mm,[1]=mm,[2]=mm};
        tmm[caster:GetPrimaryAttribute()]=tmm[caster:GetPrimaryAttribute()]*5.0;
        if caster:GetPrimaryAttribute() == 0 then
            tmm[0]=tmm[0]*0.8;
        end
        if caster:GetPrimaryAttribute() == 1 then
            tmm[0]=tmm[0]*2.0;
            tmm[1]=tmm[1]*1.2;
        end
        if caster:GetPrimaryAttribute() == 2 then
            tmm[0]=tmm[0]*2.0;
            tmm[1]=tmm[1]*2.0;
            tmm[2]=tmm[2]*1.4;
        end
        caster:SetBaseStrength(caster:GetBaseStrength() + self.giveAttrBonus * tmm[0])
        caster:SetBaseAgility(caster:GetBaseAgility() + self.giveAttrBonus * tmm[1])
        caster:SetBaseIntellect(caster:GetBaseIntellect() + self.giveAttrBonus * tmm[2])
    end
    if PlayerResource:GetUnreliableGold(casterPlayerID) < 9000 then
        PlayerResource:SetGold(casterPlayerID,PlayerResource:GetUnreliableGold(casterPlayerID) + add_gold,false)
    else
        PlayerResource:SetGold(casterPlayerID,9000,false)
    end
    if caster:GetLevel() < 29 then
        caster:AddExperience(add_exp,DOTA_ModifyXP_CreepKill,false,false)
    end
    --SendOverheadEventMessage(Caster:GetOwner(),OVERHEAD_ALERT_GOLD,Caster,self.GiveGoldAmount,nil)
end

function modifier_bot_buff:OnAttackStart(event)
    if not IsServer() then return end

    if event.attacker ~= self.caster then return end

    self:SelfStun(self.selfStunChanceOnAttack, self.selfStunDurationOnAttack)
end

function modifier_bot_buff:OnUnitMoved(event)
    if not IsServer() then return end

    if event.unit ~= self.caster then return end

    self:SelfStun(self.selfStunChanceOnMove, self.selfStunDurationOnMove)
end

function modifier_bot_buff:SelfStun(chance, duration)
    if chance == 0 then return end

    if RandomFloat(0.0,1.0) > chance then return end
    
    UtilStun:UnitStunTarget(self.caster, self.caster, duration * RandomFloat(0.1,1.0) )
end

-- Bot 收集器
ability_common_bot_corrector = class({})

function ability_common_bot_corrector:GetIntrinsicModifierName()
    return "modifier_bot_corrector"
end

modifier_bot_corrector = class({})
LinkLuaModifier("modifier_bot_corrector", "scripts/vscripts/abilities/bot_buff.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_bot_corrector:IsHidden() return true end
--function modifier_bot_corrector:IsDebuff() return false end
function modifier_bot_corrector:IsPurgable() return false end
function modifier_bot_corrector:RemoveOnDeath() return false end

function modifier_bot_corrector:OnCreated(params)
    if not IsServer() then return end

    self.caster = self:GetCaster()
    self.ability = self:GetAbility()

    self:StartIntervalThink(0.1)
end

function modifier_bot_corrector:OnIntervalThink()
    if not IsServer() then return end
	
	if self.caster:IsIllusion() then return end
	
	-- from rune_fixer.lua
	local vec = Vector(0.0,0.0,-512.0)
	local checklen = 300

	local Caster = self.caster
	local Bounty_Spwner_List = Entities:FindAllByClassnameWithin("dota_item_rune_spawner_bounty", Caster:GetOrigin() + vec, checklen)
	
	if #Bounty_Spwner_List > 0 then
		local Rune_Bounty_List = Entities:FindAllByClassnameWithin("dota_item_rune", Caster:GetOrigin(), checklen)
		for _,v in pairs(Rune_Bounty_List) do
			if v ~= nil then
				--UTIL_Remove(v)
				Caster:PickupRune(v)
				break
			end
		end
	end
end


