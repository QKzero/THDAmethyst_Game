-- 模式选择框架

-- 基础模式表
botModeSelect = {
	is_paused = false,
	dota_inter = false,
	is_bot_enabled = true,
	Difficulty = 4,
	MaxPlayer = 5,
	max_bot = 5,
}

-- 默认难度数据
botDifficultyDefaultData = {
	[1] = {
		name = "Easy",

		manaRegen = 0, -- 法术回复
		hpRegen = 0, -- 生命回复
		goldGainOnDeath = 0, -- 死亡时获取金币

		selfStunChanceOnAttack = 0.33, -- 攻击时自我眩晕触发概率
		selfStunDurationOnAttack = 0.3, -- 攻击时自我眩晕持续时间
		selfStunChanceOnMove = 0.002, -- 移动时自我眩晕触发概率
		selfStunDurationOnMove = 3, -- 移动时自我眩晕持续时间

		giveAttrBonus = -5, -- 三围定时增加
		giveGoldAmount = 0, -- 金币定时增加
		giveExpAmount = 0, -- 经验定时增加
	},
	[2] = {
		name = "Normal",

		manaRegen = 0, -- 法术回复
		hpRegen = 0, -- 生命回复
		goldGainOnDeath = 0, -- 死亡时获取金币

		selfStunChanceOnAttack = 0.1, -- 攻击时自我眩晕触发概率
		selfStunDurationOnAttack = 0.1, -- 攻击时自我眩晕持续时间
		selfStunChanceOnMove = 0, -- 移动时自我眩晕触发概率
		selfStunDurationOnMove = 0, -- 移动时自我眩晕持续时间

		giveAttrBonus = 0, -- 三围定时增加
		giveGoldAmount = 0, -- 金币定时增加
		giveExpAmount = 0, -- 经验定时增加
	},
	[3] = {
		name = "Hard",

		manaRegen = 5, -- 法术回复
		hpRegen = 0, -- 生命回复
		goldGainOnDeath = 300, -- 死亡时获取金币

		selfStunChanceOnAttack = 0, -- 攻击时自我眩晕触发概率
		selfStunDurationOnAttack = 0, -- 攻击时自我眩晕持续时间
		selfStunChanceOnMove = 0, -- 移动时自我眩晕触发概率
		selfStunDurationOnMove = 0, -- 移动时自我眩晕持续时间

		giveAttrBonus = 8, -- 三围定时增加
		giveGoldAmount = 30, -- 金币定时增加
		giveExpAmount = 15, -- 经验定时增加
	},
	[4] = {
		name = "Lunatic",

		manaRegen = 20, -- 法术回复
		hpRegen = 0, -- 生命回复
		goldGainOnDeath = 600, -- 死亡时获取金币

		selfStunChanceOnAttack = 0, -- 攻击时自我眩晕触发概率
		selfStunDurationOnAttack = 0, -- 攻击时自我眩晕持续时间
		selfStunChanceOnMove = 0, -- 移动时自我眩晕触发概率
		selfStunDurationOnMove = 0, -- 移动时自我眩晕持续时间

		giveAttrBonus = 12, -- 三围定时增加
		giveGoldAmount = 50, -- 金币定时增加
		giveExpAmount = 20, -- 经验定时增加
	},
}

function ChangeGamePause(data)
	if data ~= nil then
		local plyhd = PlayerResource:GetPlayer(data.PlayerID)
		if GameRules:PlayerHasCustomGameHostPrivileges(plyhd) then
			botModeSelect.is_paused = data.is_paused ~= 0
			PauseGame(botModeSelect.is_paused)
		end
	end
end

function ChangeGameDotaInter(data)
	if data ~= nil then
		local plyhd = PlayerResource:GetPlayer(data.PlayerID)
		botModeSelect.dota_inter = data.dota_inter ~= 0
		THD2_SetDotaMixedMode(botModeSelect.dota_inter)
		if botModeSelect.dota_inter then
			Say(plyhd, "Dota Mixed ON", false)
		else
			Say(plyhd, "Dota Mixed OFF", false)
		end
	end
end

function ChangeGameBotMode(data)
	if data ~= nil then
		local plyhd = PlayerResource:GetPlayer(data.PlayerID)
		botModeSelect.is_bot_enabled = data.is_bot_enabled ~= 0
		THD2_SetBotMode(botModeSelect.is_bot_enabled)
		if botModeSelect.is_bot_enabled then
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
		botModeSelect.Difficulty = data.difficulty
	end
end

function ChangeGameMaxPlayer(data)
	if data ~= nil then
		local plyhd = PlayerResource:GetPlayer(data.PlayerID)
		botModeSelect.MaxPlayer = tonumber(data.maxPlayer)
		local res = THD2_SetPlayerPerTeam(botModeSelect.MaxPlayer)
		Say(plyhd, "Max player(per team) set to " .. tostring(res), false)
	end
end

function ChangeGameMaxBot(data)
	if data ~= nil then
		local plyhd = PlayerResource:GetPlayer(data.PlayerID)
		botModeSelect.max_bot = tonumber(data.max_bot)
		local res = THD2_SetPlayerBadTeam(botModeSelect.max_bot)
		Say(plyhd,"Max Bot set to "..tostring(res),false)
	end
end

function CloseGameMod()
	CustomGameEventManager:Send_ServerToAllClients("CloseGameMod", {})
end

function ModeSelect()
	CustomUI:DynamicHud_Create(-1, "Select", "file://{resources}/layout/custom_game/mode_select.xml", nil)
	CustomGameEventManager:Send_ServerToAllClients("ModeSelect", { botModeSelect })  --然后将LUA表里的数据传给重连的玩家
end

function BotModSelect()
	CustomUI:DynamicHud_Create(-1, "BotSelect", "file://{resources}/layout/custom_game/mode_select.xml", nil)
	CustomGameEventManager:Send_ServerToAllClients("BotModSelect", { botModeSelect })  --然后将LUA表里的数据传给重连的玩家
end