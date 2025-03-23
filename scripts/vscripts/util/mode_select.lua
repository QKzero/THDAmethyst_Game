-- 模式选择框架
Bot_Mode_Select = {
	is_paused = false,
	dota_inter = false,
	is_bot_enabled = true,
	Difficulty = 4,
	MaxPlayer = 5,
	max_bot = 5,
}

function ChangeGamePause(data)
	if data ~= nil then
		local plyhd = PlayerResource:GetPlayer(data.PlayerID)
		if GameRules:PlayerHasCustomGameHostPrivileges(plyhd) then
			Bot_Mode_Select.is_paused = data.is_paused ~= 0
			PauseGame(Bot_Mode_Select.is_paused)
		end
	end
end

function ChangeGameDotaInter(data)
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

function ChangeGameBotMode(data)
	if data ~= nil then
		local plyhd = PlayerResource:GetPlayer(data.PlayerID)
		Bot_Mode_Select.is_bot_enabled = data.is_bot_enabled ~= 0
		THD2_SetBotMode(Bot_Mode_Select.is_bot_enabled)
		if Bot_Mode_Select.is_bot_enabled then
			Say(plyhd, "Bot Mode ON...", false)
		else
			Say(plyhd, "Bot Mode OFF...", false)
		end
	end
end

function ChangeGameDifficulty(data)
	if data ~= nil then
		local plyhd = PlayerResource:GetPlayer(data.PlayerID)
		THD2_ChangeBotDifficulty(plyhd, data.difficulty)
		Bot_Mode_Select.Difficulty = data.difficulty
	end
end

function ChangeGameMaxPlayer(data)
	if data ~= nil then
		local plyhd = PlayerResource:GetPlayer(data.PlayerID)
		Bot_Mode_Select.MaxPlayer = tonumber(data.maxPlayer)
		local res = THD2_SetPlayerPerTeam(Bot_Mode_Select.MaxPlayer)
		Say(plyhd, "Max player(per team) set to " .. tostring(res), false)
	end
end

function ChangeGameMaxBot(data)
	if data ~= nil then
		local plyhd = PlayerResource:GetPlayer(data.PlayerID)
		Bot_Mode_Select.max_bot = tonumber(data.max_bot)
		local res = THD2_SetPlayerBadTeam(Bot_Mode_Select.max_bot)
		Say(plyhd,"Max Bot set to "..tostring(res),false)
	end
end

function CloseGameMod()
	CustomGameEventManager:Send_ServerToAllClients("CloseGameMod", {})
end

function ModeSelect()
	CustomUI:DynamicHud_Create(-1, "Select", "file://{resources}/layout/custom_game/mode_select.xml", nil)
	CustomGameEventManager:Send_ServerToAllClients("ModeSelect", {Bot_Mode_Select})  --然后将LUA表里的数据传给重连的玩家
end

function BotModSelect()
	CustomUI:DynamicHud_Create(-1, "BotSelect", "file://{resources}/layout/custom_game/mode_select.xml", nil)
	CustomGameEventManager:Send_ServerToAllClients("BotModSelect", {Bot_Mode_Select})  --然后将LUA表里的数据传给重连的玩家
end