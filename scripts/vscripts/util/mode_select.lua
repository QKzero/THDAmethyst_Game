-- 模式选择框架
Bot_Mode_Select = {
	is_paused = false,
	dota_inter = false,
	Difficulty = 4,
	MaxPlayer = 5,
	Mod = 2,
}

function ChangeGamePause(data)
	print("ChangeGamePause")
	if data ~= nil then
		local plyhd = PlayerResource:GetPlayer(data.PlayerID)
		if GameRules:PlayerHasCustomGameHostPrivileges(plyhd) then
			Bot_Mode_Select.is_paused = data.is_paused ~= 0
			PauseGame(Bot_Mode_Select.is_paused)
		end
	end
end

function ChangeGameDotaInter(data)
	print("ChangeGameDotaInter")
	if data ~= nil then
		local plyhd = PlayerResource:GetPlayer(data.PlayerID)
		Bot_Mode_Select.dota_inter = data.dota_inter ~= 0
		THD2_SetDotaMixedMode(Bot_Mode_Select.dota_inter)
		if Bot_Mode_Select.dota_inter then
			Say(plyhd, "Dota Mixed ON", false)
		else
			Say(plyhd, "Dota Mixed OFF", false)
		end
	end
end

function ChangeGameDifficulty(data)
	print("ChangeGameDifficulty")
	if data ~= nil then
		local plyhd = PlayerResource:GetPlayer(data.PlayerID)
		THD2_ChangeBotDifficulty(plyhd, data.difficulty)
		Bot_Mode_Select.Difficulty = data.difficulty
	end
end

function ChangeGameMaxPlayer(data)
	print("ChangeGameMaxPlayer")
	if data ~= nil then
		local plyhd = PlayerResource:GetPlayer(data.PlayerID)
		local res = THD2_SetPlayerPerTeam(tonumber(data.maxPlayer))
		Say(plyhd, "Max player(per team) set to " .. tostring(res), false)
		Bot_Mode_Select.MaxPlayer = tonumber(data.maxPlayer)
	end
end

function CloseGameMod()
	CustomGameEventManager:Send_ServerToAllClients("CloseGameMod", {})
end

function ModeSelect()
	print("ModeSelect")
	CustomUI:DynamicHud_Create(-1, "Select", "file://{resources}/layout/custom_game/mode_select.xml", nil)
	CustomGameEventManager:Send_ServerToAllClients("ModeSelect", {Bot_Mode_Select})  --然后将LUA表里的数据传给重连的玩家
end

function BotModSelect()
	print("BotModSelect")
	CustomUI:DynamicHud_Create(-1, "BotSelect", "file://{resources}/layout/custom_game/mode_select.xml", nil)
	CustomGameEventManager:Send_ServerToAllClients("BotModSelect", {Bot_Mode_Select})  --然后将LUA表里的数据传给重连的玩家
end