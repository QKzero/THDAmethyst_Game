URD = {}
Team1 = {}
Team2 = {}
Team1_count = 0
Team2_count = 0
FLAG1 = true
FLAG2 = true
TIME_DURATION = 60  --投票的持续时间
TIME_FLAG = 120		--投票的CD
WINER_TEAM = nil

Team1Name = "#DOTA_GoodGuys"
Team2Name = "#DOTA_BadGuys"

function THD_URD(plyid,plyhd)
	if not IsServer() then return end
	if GetMapName() ~= "1_thdots_map" then return end
	-- print_r(Team1)
	-- print_r(Team2)
	print(plyhd:GetAssignedHero():GetOrigin())
	siege_print()
	if GameRules:GetDOTATime(false, false) < 900 then
		GameRules:SendCustomMessage("#thd_urd_cannot_urd_before_15mins", plyhd:GetTeam(), 0)
		return
	end
	if not FLAG1 then
		GameRules:SendCustomMessage("#thd_urd_cannot_urd_cooldown", plyhd:GetTeam(), 0)
		return
	end
	--------------------测试代码
	-- if Team2_count == 1 then
	-- 	print("text")
	-- 	Team2[1] = {["ID"]=1,["TF"] = true }
	-- 	print_r(Team2)
	-- end
	-- if Team2_count == 2 then
	-- 	print("text")
	-- 	Team2[2] = {["ID"]=2,["TF"] = true }
	-- 	print_r(Team2)
	-- end
	-- if Team2_count == 3 then
	-- 	print("text")
	-- 	Team2[3] = {["ID"]=3,["TF"] = true }
	-- 	print_r(Team2)
	-- end
	-- GameRules:SendCustomMessage("<font color='#00FFFF'>Welcome to Touhou Defence of the shrines Re;mixed DOTS:R.</font>", 0, 0)	
	if Team1[plyid] ~= nil then
		if not FLAG1 then
			GameRules:SendCustomMessage("#thd_urd_cannot_urd_cooldown", plyhd:GetTeam(), 0)
			return
		end
		print("Team1[".. plyid .. "] is " .. Team1[plyid].ID)
		Team1[plyid].TF = true
		print("Team1[".. plyid .. "].TF is " ..tostring(Team1[plyid].TF))
		if Team1_count == 0 then
			Team1_count = 1

			-- 博丽神社发起了投降,输入-urd投票投降，票数：num/4
			CustomGameEventManager:Send_ServerToTeam(DOTA_TEAM_GOODGUYS, "urd_vote", {num = Team1_count})
			Team1_Interval(plyid,plyhd)
		end
	end
	if Team2[plyid] ~= nil then
		if not FLAG2 then
			GameRules:SendCustomMessage("#thd_urd_cannot_urd_cooldown", plyhd:GetTeam(), 0)
			return
		end
		print("Team2[".. plyid .. "] is " .. Team2[plyid].ID)
		Team2[plyid].TF = true
		print("Team2[".. plyid .. "].TF is " ..tostring(Team2[plyid].TF))
		if Team2_count == 0 then
			Team2_count = 1

			-- 守矢神社发起了投降,输入-urd投票投降，票数：num/4
			CustomGameEventManager:Send_ServerToTeam(DOTA_TEAM_BADGUYS, "urd_vote", {num = Team2_count})
			Team2_Interval(plyid,plyhd)
		end
	end
end

function URD_initialize()
	for i=1, PlayerResource:GetPlayerCount() do
		local plyhd = PlayerResource:GetPlayer(i-1)
		if plyhd then
			-- print("plyhd team is : ",plyhd:GetTeam())
			-- print("plyhd ID is : ",plyhd:GetPlayerID())
			-- GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
			if plyhd:GetTeam() == DOTA_TEAM_GOODGUYS then
				Team1[plyhd:GetPlayerID()] = {["ID"]=plyhd:GetPlayerID(),["TF"] = 0 }
			elseif plyhd:GetTeam() == DOTA_TEAM_BADGUYS then
				Team2[plyhd:GetPlayerID()] = {["ID"]=plyhd:GetPlayerID(),["TF"] = 0 }
			end
		end
	end
	-- print_r(Team1)
	-- print_r(Team2)
	-- print("initialize success")
end

function Team1_Interval(plyid,plyhd)
	local time = 0
	GameRules:GetGameModeEntity():SetContextThink("urd_interval_1", 
		function()
			if GameRules:IsGamePaused() then return 0.03 end
			if time < TIME_DURATION then
				local count = 0
				for _,v in pairs(Team1) do
					if v.TF == true then
						count = count + 1
					end
				end
				if count > Team1_count then
					print("tou piao  + 1")
					Team1_count = count
					-- 同意投降，当前票数：num
					CustomGameEventManager:Send_ServerToTeam(DOTA_TEAM_GOODGUYS, "urd_vote", {num = Team1_count})
				end
				if Team1_count >= 4 then
					print("SS shengli")
					-- 博丽神社投降，游戏将在10秒后结束
					CustomGameEventManager:Send_ServerToAllClients("urd_surrender", {team = Team1Name})
					WINER_TEAM = DOTA_TEAM_BADGUYS
					local end_time = 0
					GameRules:GetGameModeEntity():SetContextThink("urd_hakurei", 
						function()
							if GameRules:IsGamePaused() then return 0.03 end
							if end_time >= 10 then
								GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
								WebApi:AfterMatch()
								return nil
							end
						end_time = end_time + 0.03
						return 0.03
						end
						,
						0)
					return nil
				end
			else
				print("end")
				-- 博丽神社投降失败，2分钟以内无法再次发起投降
				GameRules:SendCustomMessageToTeam("#thd_urd_surrender_fail_hakurei", DOTA_TEAM_GOODGUYS, 0, 0)
				FLAG1 = false
				FLAG1_interval()
				for _,v in pairs(Team1) do
					v.TF = 0
				end
				print_r(Team1)
				Team1_count = 0
				return nil
			end
		time = time + 0.03
		return 0.03
		end
		,
		0)
end

function Team2_Interval(plyid,plyhd)
	local time = 0
	GameRules:GetGameModeEntity():SetContextThink("urd_interval_2", 
		function()
			if GameRules:IsGamePaused() then return 0.03 end
			if time < TIME_DURATION then
				local count = 0
				for _,v in pairs(Team2) do
					if v.TF == true then
						count = count + 1
					end
				end
				if count > Team2_count then
					print("tou piao  + 1")
					Team2_count = count
					-- 同意投降，当前票数：num
					CustomGameEventManager:Send_ServerToTeam(DOTA_TEAM_BADGUYS, "urd_vote", {num = Team2_count})
				end
				if Team2_count >= 4 then
					print("BL shengli")
					WINER_TEAM = DOTA_TEAM_GOODGUYS
					-- 守矢神社投降，游戏将在10秒后结束
					CustomGameEventManager:Send_ServerToAllClients("urd_surrender", {team = Team2Name})
					local end_time = 0
					GameRules:GetGameModeEntity():SetContextThink("urd_moriya", 
						function()
							if GameRules:IsGamePaused() then return 0.03 end
							if end_time >= 10 then
								GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
								WebApi:AfterMatch()
								return nil
							end
						end_time = end_time + 0.03
						return 0.03
						end
						,
						0)
					return nil
				end
			else
				print("end")
				-- 守矢神社投降失败，2分钟以内无法再次发起投降
				GameRules:SendCustomMessageToTeam("#thd_urd_surrender_fail_moriya", DOTA_TEAM_BADGUYS, 0, 0)
				FLAG2 = false
				FLAG2_interval()
				for _,v in pairs(Team2) do
					v.TF = 0
				end
				print_r(Team2)
				Team2_count = 0
				return nil
			end
		time = time + 0.03
		return 0.03
		end
		,
		0)
end

function FLAG1_interval()
	local end_time = 0
	GameRules:GetGameModeEntity():SetContextThink("urd_moriya_1", 
		function()
			if GameRules:IsGamePaused() then return 0.03 end
			if end_time >= TIME_FLAG then
				FLAG1 = true
				return nil
			end
		end_time = end_time + 0.03
		return 0.03
		end
		,
		0)
end

function FLAG2_interval()
	local end_time = 0
	GameRules:GetGameModeEntity():SetContextThink("urd_moriya_2", 
		function()
			if GameRules:IsGamePaused() then return 0.03 end
			if end_time >= TIME_FLAG then
				FLAG2 = true
				return nil
			end
		end_time = end_time + 0.03
		return 0.03
		end
		,
		0)
end

function ClearTeam1()
	for _,v in pairs(Team1) do
		v.TF = 0
	end
	Team1_count = 0
end

function ClearTeam2()
	for _,v in pairs(Team2) do
		v.TF = 0
	end
	Team2_count = 0
end

function GetWinerteam()
	return WINER_TEAM
end