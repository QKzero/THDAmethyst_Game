
function Ability_Bot_Buff_DeleteRune_OnInterval(keys)
	
	if keys.caster:IsIllusion() then return end
	
	-- from rune_fixer.lua
	local vec = Vector(0.0,0.0,-512.0)
	local checklen = 300

	local Caster = keys.caster
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

function Ability_Bot_Buff_OnInterval(keys)
	
	if keys.caster:IsIllusion() then return end
	
	local now_time = GameRules:GetDOTATime(false, false)
	if (now_time < 1.0) then return end
	local Caster = keys.caster
	local CasterPlayerID = Caster:GetPlayerOwnerID()
	local add_gold = keys.GiveGoldAmount
	local add_exp = keys.GiveExpAmount
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
			Caster:GetTeam(),		
			Caster:GetOrigin(),		
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
		tmm[Caster:GetPrimaryAttribute()]=tmm[Caster:GetPrimaryAttribute()]*5.0;
		if Caster:GetPrimaryAttribute() == 0 then
			tmm[0]=tmm[0]*0.8;
		end
		if Caster:GetPrimaryAttribute() == 1 then
			tmm[0]=tmm[0]*2.0;
			tmm[1]=tmm[1]*1.2;
		end
		if Caster:GetPrimaryAttribute() == 2 then
			tmm[0]=tmm[0]*2.0;
			tmm[1]=tmm[1]*2.0;
			tmm[2]=tmm[2]*1.4;
		end
		Caster:SetBaseStrength(Caster:GetBaseStrength() + keys.IncreaseAllstat * tmm[0])
		Caster:SetBaseAgility(Caster:GetBaseAgility() + keys.IncreaseAllstat * tmm[1])
		Caster:SetBaseIntellect(Caster:GetBaseIntellect() + keys.IncreaseAllstat * tmm[2])
		--print(PlayerResource:GetSelectedHeroName(CasterPlayerID) .. keys.IncreaseAllstat * tmm[0] .." ".. keys.IncreaseAllstat * tmm[1] .." ".. keys.IncreaseAllstat * tmm[2])
	end
	--DebugPrint("now:"..PlayerResource:GetUnreliableGold(CasterPlayerID).."+"..keys.GiveGoldAmount)
	if PlayerResource:GetUnreliableGold(CasterPlayerID) < 9000 then 
		PlayerResource:SetGold(CasterPlayerID,PlayerResource:GetUnreliableGold(CasterPlayerID) + add_gold,false)
	else
		PlayerResource:SetGold(CasterPlayerID,9000,false)
	end
	if Caster:GetLevel() < 29 then
		Caster:AddExperience(add_exp,DOTA_ModifyXP_CreepKill,false,false)
	end
	--SendOverheadEventMessage(Caster:GetOwner(),OVERHEAD_ALERT_GOLD,Caster,keys.GiveGoldAmount,nil)
end

function DeathBuff(keys)

	if keys.caster:IsIllusion() then return end

	local now_time = GameRules:GetDOTATime(false, false)
	if (now_time < 300.0) then return end --do not bonus on death before 5min
	local bn=keys.BonusOnDeath
	local Caster = keys.caster
	local CasterPlayerID = Caster:GetPlayerOwnerID()
	PlayerResource:SetGold(CasterPlayerID,PlayerResource:GetUnreliableGold(CasterPlayerID) + bn,false)
	if (now_time > 900.0) then 
		local mm=0.005
		if Caster:GetPrimaryAttribute() == 0 then
			Caster:SetBaseStrength(Caster:GetBaseStrength() + bn * mm)
		end
		if Caster:GetPrimaryAttribute() == 1 then
			Caster:SetBaseAgility(Caster:GetBaseAgility() + bn * mm)
		end
		if Caster:GetPrimaryAttribute() == 2 then
			Caster:SetBaseIntellect(Caster:GetBaseIntellect() + bn * mm)
		end
		--print('buff_y')
	end	
end

function NoobBuff(keys)
	if keys.caster:IsIllusion() then return end
	local bn=keys.BonusOnDeath
	local Caster = keys.caster
	local now_time = GameRules:GetDOTATime(false, false)
	if now_time>=1500.0 then
		Caster:ModifyGold(Caster:GetBuybackCost(false)+keys.Bonus,false,0)
		bn=bn*2
		Caster:FindModifierByName("modifier_ex_bot"):IncrementStackCount()
	end
	if Caster:GetLevel() < 29 then
		Caster:AddExperience(keys.Bonus,DOTA_ModifyXP_TomeOfKnowledge,false,false)
	end
	Caster:SetBaseStrength(Caster:GetBaseStrength() + bn*3)
	Caster:SetBaseAgility(Caster:GetBaseAgility() + bn)
	Caster:SetBaseIntellect(Caster:GetBaseIntellect() + bn)
	Caster:CalculateStatBonus(true)
	Caster:FindModifierByName("modifier_ex_bot"):IncrementStackCount()
	--print(Caster:GetBuybackCost(true))
	print('noob')
	Caster:SetBuybackCooldownTime(0)
	Caster:SetBuybackGoldLimitTime(0)
end
function Noob(keys)
	keys.ability:ApplyDataDrivenModifier(keys.caster,keys.caster,"modifier_ex_bot_buff",{})
	--print(keys.caster:GetClassname())
	--print('noob')
end
function Ability_Bot_SelfStun(keys)
	if RandomFloat(0.0,1.0) > keys.SelfStunChance then return end
	UtilStun:UnitStunTarget(keys.caster,keys.caster,keys.SelfStunDuration * RandomFloat(0.1,1.0) )
end


