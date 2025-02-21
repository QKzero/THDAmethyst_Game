--更换英雄技能天赋

function THD_Change_skill(hero,plyhd)
	if GameRules:GetDOTATime(false, false) > 0 then
		Say(plyhd, "游戏开始后无法更换技能", true)
		return 
	end
	if hero.HasSkillChange ~= true then
		Say(plyhd, "该少女没有技能卡", true)
		return
	elseif hero.HasSkillChange == false then
		Say(plyhd, "该少女已经更换技能，无法再更换", true)
		return
	end
	--删除技能天赋
	for i=0,17 do 
		if hero:GetAbilityByIndex(i) and hero:GetAbilityByIndex(i) ~= "" then
			print(hero:GetAbilityByIndex(i):GetName())
			hero:RemoveAbilityByHandle(hero:GetAbilityByIndex(i))
		end
	end
	if hero:GetName() == "npc_dota_hero_juggernaut" then
		THD_Change_skill_youmu2(hero,plyhd)
	elseif hero:GetName() == "" then

	end
end

function THD_Change_skill_youmu2(hero,plyhd)
	if GameRules:GetDOTATime(false, false) > 0 then
		Say(plyhd, "*游戏开始后无法更换技能", true)
		return
	end

	local gold = hero:GetGold()
	local exp = hero:GetCurrentXP()
	PrecacheUnitByNameAsync("npc_dota_hero_enchantress", function ()
		local hero = PlayerResource:ReplaceHeroWith(plyhd:GetPlayerID(), "npc_dota_hero_enchantress", gold, exp)

		local ability = hero:FindAbilityByName("ability_thdots_youmu2_Ex")
		ability:SetLevel(1)
		ability = hero:FindAbilityByName("ability_thdots_youmu2_05")
		ability:SetLevel(1)

		GameRules:SendCustomMessage("#Youmu2SkillChange", 0, 0)
	end, plyhd:GetPlayerID())
end

function THD_Change_skill_exrumia(hero,plyhd)
	if GameRules:GetDOTATime(false, false) > 0 then
		Say(plyhd, "*游戏开始后无法更换技能", true)
		return 
	end
	local gold = hero:GetGold()
	local exp = hero:GetCurrentXP()
	PrecacheUnitByNameAsync("npc_dota_hero_skeleton_king", function ()
		local hero = PlayerResource:ReplaceHeroWith(plyhd:GetPlayerID(), "npc_dota_hero_skeleton_king", gold, exp)
		local ability = hero:FindAbilityByName("ability_thdots_exrumiaEx")
		ability:SetLevel(1)
		GameRules:SendCustomMessage("<font color='#00FFFF'>露米娅更换了技能卡</font>", 0, 0)
	end, plyhd:GetPlayerID())
end

function THD_Change_skill_flandre(hero,plyhd)
	if GameRules:GetDOTATime(false, false) > 0 and not Naotan then
		Say(plyhd, "*游戏开始后无法更换技能", true)
		return 
	end
	local gold = hero:GetGold()
	local exp = hero:GetCurrentXP()
	PrecacheUnitByNameAsync("npc_dota_hero_pangolier", function()
		local hero = PlayerResource:ReplaceHeroWith(plyhd:GetPlayerID(), "npc_dota_hero_pangolier", gold, exp)
		local ability = hero:FindAbilityByName("ability_thdots_flandrev2_wanbaochui")
		ability:SetLevel(1)  
		ability:SetHidden(true)
		ability = hero:FindAbilityByName("ability_thdots_flandrev2_03")
		ability:SetLevel(1)

		if not Naotan_Mode then
			GameRules:SendCustomMessage("<font color='#00FFFF'>芙兰朵露更换了技能卡</font>", 0, 0)
		end
	end, plyhd:GetPlayerID())
end

function THD_Change_skill_miko(hero,plyhd)
	if GameRules:GetDOTATime(false, false) > 0 then
		Say(plyhd, "*游戏开始后无法更换技能", true)
		return 
	end
	local gold = hero:GetGold()
	local exp = hero:GetCurrentXP()
	PrecacheUnitByNameAsync("npc_dota_hero_marci", function()
		local hero = PlayerResource:ReplaceHeroWith(plyhd:GetPlayerID(), "npc_dota_hero_marci", gold, exp)
		local ability = hero:FindAbilityByName("ability_thdots_miko2_Ex")
		ability:SetLevel(1)
		GameRules:SendCustomMessage("<font color='#00FFFF'>丰聪耳神子更换了技能卡</font>", 0, 0)
	end, plyhd:GetPlayerID())
end

function THD_Change_skill_Larva2(hero,plyhd)
	if GameRules:GetDOTATime(false, false) > 0 then
		Say(plyhd, "*游戏开始后无法更换技能", true)
		return 
	end
	local gold = hero:GetGold()
	local exp = hero:GetCurrentXP()
	PrecacheUnitByNameAsync("npc_dota_hero_wisp", function()
		local hero = PlayerResource:ReplaceHeroWith(plyhd:GetPlayerID(), "npc_dota_hero_wisp", gold, exp)
		GameRules:SendCustomMessage("<font color='#00FFFF'>爱塔妮缇·拉尔瓦更换了技能卡</font>", 0, 0)
	end, plyhd:GetPlayerID())
end

function THD_Change_skill_kasen3(hero,plyhd)
	if GameRules:GetDOTATime(false, false) > 0 then
		Say(plyhd, "*游戏开始后无法更换技能", true)
		return
	end
	local gold = hero:GetGold()
	local exp = hero:GetCurrentXP()
	PrecacheUnitByNameAsync("npc_dota_hero_lone_druid", function()
		local hero = PlayerResource:ReplaceHeroWith(plyhd:GetPlayerID(), "npc_dota_hero_lone_druid", gold, exp)
		GameRules:SendCustomMessage("<font color='#00FFFF'>茨木华扇更换了技能卡</font>", 0, 0)
	end, plyhd:GetPlayerID())
end