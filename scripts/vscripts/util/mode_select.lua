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

		-- 金币定时增加（每5分钟到下一等级）
		giveGoldAmount = {
			0, -- 0-5 min
			0, -- 5-10 min
			0, -- 10-15 min
			0, -- 15-20 min
			0, -- 20-25 min
			0, -- 25-30 min
			0, -- 30+ min
		},
		-- 经验定时增加（每5分钟到下一等级）
		giveExpAmount = {
			0, -- 0-5 min
			0, -- 5-10 min
			0, -- 10-15 min
			0, -- 15-20 min
			0, -- 20-25 min
			0, -- 25-30 min
			0, -- 30+ min
		},

		-- 三围固定增加（力量、敏捷、智力）
		giveAttrBase = { -5, -5, -5 },

		-- 三围定时增加
		giveAttrBonus = {
			-- 主属性区分
			{
				-- 力量主属性
				-- 力量、敏捷、智力增强（每5分钟到下一等级）
				{ 0, 0, 0 }, -- 0-5 min
				{ 0, 0, 0 }, -- 5-10 min
				{ 0, 0, 0 }, -- 10-15 min
				{ 0, 0, 0 }, -- 15-20 min
				{ 0, 0, 0 }, -- 20-25 min
				{ 0, 0, 0 }, -- 25-30 min
				{ 0, 0, 0 }, -- 30+ min
			},
			{
				-- 敏捷主属性
				-- 力量、敏捷、智力增强（每5分钟到下一等级）
				{ 0, 0, 0 }, -- 0-5 min
				{ 0, 0, 0 }, -- 5-10 min
				{ 0, 0, 0 }, -- 10-15 min
				{ 0, 0, 0 }, -- 15-20 min
				{ 0, 0, 0 }, -- 20-25 min
				{ 0, 0, 0 }, -- 25-30 min
				{ 0, 0, 0 }, -- 30+ min
			},
			{
				-- 智力主属性
				-- 力量、敏捷、智力增强（每5分钟到下一等级）
				{ 0, 0, 0 }, -- 0-5 min
				{ 0, 0, 0 }, -- 5-10 min
				{ 0, 0, 0 }, -- 10-15 min
				{ 0, 0, 0 }, -- 15-20 min
				{ 0, 0, 0 }, -- 20-25 min
				{ 0, 0, 0 }, -- 25-30 min
				{ 0, 0, 0 }, -- 30+ min
			},
		},
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

		-- 金币定时增加（每5分钟到下一等级）
		giveGoldAmount = {
			0, -- 0-5 min
			0, -- 5-10 min
			0, -- 10-15 min
			0, -- 15-20 min
			0, -- 20-25 min
			0, -- 25-30 min
			0, -- 30+ min
		},
		-- 经验定时增加（每5分钟到下一等级）
		giveExpAmount = {
			0, -- 0-5 min
			0, -- 5-10 min
			0, -- 10-15 min
			0, -- 15-20 min
			0, -- 20-25 min
			0, -- 25-30 min
			0, -- 30+ min
		},

		-- 三围固定增加（力量、敏捷、智力）
		giveAttrBase = { 0, 0, 0 },

		-- 三围定时增加
		giveAttrBonus = {
			-- 主属性区分
			{
				-- 力量主属性
				-- 力量、敏捷、智力增强（每5分钟到下一等级）
				{ 0, 0, 0 }, -- 0-5 min
				{ 0, 0, 0 }, -- 5-10 min
				{ 0, 0, 0 }, -- 10-15 min
				{ 0, 0, 0 }, -- 15-20 min
				{ 0, 0, 0 }, -- 20-25 min
				{ 0, 0, 0 }, -- 25-30 min
				{ 0, 0, 0 }, -- 30+ min
			},
			{
				-- 敏捷主属性
				-- 力量、敏捷、智力增强（每5分钟到下一等级）
				{ 0, 0, 0 }, -- 0-5 min
				{ 0, 0, 0 }, -- 5-10 min
				{ 0, 0, 0 }, -- 10-15 min
				{ 0, 0, 0 }, -- 15-20 min
				{ 0, 0, 0 }, -- 20-25 min
				{ 0, 0, 0 }, -- 25-30 min
				{ 0, 0, 0 }, -- 30+ min
			},
			{
				-- 智力主属性
				-- 力量、敏捷、智力增强（每5分钟到下一等级）
				{ 0, 0, 0 }, -- 0-5 min
				{ 0, 0, 0 }, -- 5-10 min
				{ 0, 0, 0 }, -- 10-15 min
				{ 0, 0, 0 }, -- 15-20 min
				{ 0, 0, 0 }, -- 20-25 min
				{ 0, 0, 0 }, -- 25-30 min
				{ 0, 0, 0 }, -- 30+ min
			},
		},
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

		-- 金币定时增加（每5分钟到下一等级）
		giveGoldAmount = {
			0, -- 0-5 min
			37.5, -- 5-10 min
			45, -- 10-15 min
			45, -- 15-20 min
			52.5, -- 20-25 min
			52.5, -- 25-30 min
			75, -- 30+ min
		},
		-- 经验定时增加（每5分钟到下一等级）
		giveExpAmount = {
			0, -- 0-5 min
			15, -- 5-10 min
			37.5, -- 10-15 min
			37.5, -- 15-20 min
			41.25, -- 20-25 min
			41.25, -- 25-30 min
			45, -- 30+ min
		},

		-- 三围固定增加（力量、敏捷、智力）
		giveAttrBase = { 8, 8, 8 },

		-- 三围定时增加（每5分钟到下一等级）
		giveAttrBonus = {
			-- 主属性区分
			{
				-- 力量主属性
				-- 力量、敏捷、智力增强（每5分钟到下一等级）
				{ 0, 0, 0 }, -- 0-5 min
				{ 0, 0, 0 }, -- 5-10 min
				{ 0.08, 0.02, 0.02 }, -- 10-15 min
				{ 0.08, 0.02, 0.02 }, -- 15-20 min
				{ 0.10, 0.025, 0.025 }, -- 20-25 min
				{ 0.10, 0.025, 0.025 }, -- 25-30 min
				{ 0.12, 0.03, 0.03 }, -- 30+ min
			},
			{
				-- 敏捷主属性
				-- 力量、敏捷、智力增强（每5分钟到下一等级）
				{ 0, 0, 0 }, -- 0-5 min
				{ 0, 0, 0 }, -- 5-10 min
				{ 0.04, 0.12, 0.02 }, -- 10-15 min
				{ 0.04, 0.12, 0.02 }, -- 15-20 min
				{ 0.05, 0.15, 0.025 }, -- 20-25 min
				{ 0.05, 0.15, 0.025  }, -- 25-30 min
				{ 0.06, 0.18, 0.03 }, -- 30+ min
			},
			{
				-- 智力主属性
				-- 力量、敏捷、智力增强（每5分钟到下一等级）
				{ 0, 0, 0 }, -- 0-5 min
				{ 0, 0, 0 }, -- 5-10 min
				{ 0.04, 0.04, 0.112 }, -- 10-15 min
				{ 0.04, 0.04, 0.112 }, -- 15-20 min
				{ 0.05, 0.05, 0.14 }, -- 20-25 min
				{ 0.05, 0.05, 0.14 }, -- 25-30 min
				{ 0.06, 0.06, 0.168 }, -- 30+ min
			},
		},
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

		-- 金币定时增加（每5分钟到下一等级）
		giveGoldAmount = {
			0, -- 0-5 min
			62.5, -- 5-10 min
			75, -- 10-15 min
			75, -- 15-20 min
			87.5, -- 20-25 min
			87.5, -- 25-30 min
			125, -- 30+ min
		},
		-- 经验定时增加（每5分钟到下一等级）
		giveExpAmount = {
			0, -- 0-5 min
			20, -- 5-10 min
			50, -- 10-15 min
			50, -- 15-20 min
			55, -- 20-25 min
			55, -- 25-30 min
			60, -- 30+ min
		},

		-- 三围固定增加（力量、敏捷、智力）
		giveAttrBase = { 12, 12, 12 },

		-- 三围定时增加
		giveAttrBonus = {
			-- 主属性区分
			{
				-- 力量主属性
				-- 力量、敏捷、智力增强（每5分钟到下一等级）
				{ 0, 0, 0 }, -- 0-5 min
				{ 0, 0, 0 }, -- 5-10 min
				{ 0.16, 0.04, 0.04 }, -- 10-15 min
				{ 0.16, 0.04, 0.04 }, -- 15-20 min
				{ 0.20, 0.05, 0.05 }, -- 20-25 min
				{ 0.20, 0.05, 0.05 }, -- 25-30 min
				{ 0.24, 0.06, 0.06 }, -- 30+ min
			},
			{
				-- 敏捷主属性
				-- 力量、敏捷、智力增强（每5分钟到下一等级）
				{ 0, 0, 0 }, -- 0-5 min
				{ 0, 0, 0 }, -- 5-10 min
				{ 0.08, 0.24, 0.04 }, -- 10-15 min
				{ 0.08, 0.24, 0.04 }, -- 15-20 min
				{ 0.1, 0.3, 0.05 }, -- 20-25 min
				{ 0.1, 0.3, 0.05  }, -- 25-30 min
				{ 0.12, 0.36, 0.06 }, -- 30+ min
			},
			{
				-- 智力主属性
				-- 力量、敏捷、智力增强（每5分钟到下一等级）
				{ 0, 0, 0 }, -- 0-5 min
				{ 0, 0, 0 }, -- 5-10 min
				{ 0.08, 0.08, 0.224 }, -- 10-15 min
				{ 0.08, 0.08, 0.224 }, -- 15-20 min
				{ 0.10, 0.10, 0.28 }, -- 20-25 min
				{ 0.10, 0.10, 0.28 }, -- 25-30 min
				{ 0.12, 0.12, 0.336 }, -- 30+ min
			},
		},
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


-- 难度数据
function SetBotDifficultyData(data)
	if not IsServer() then return end

	botDifficultyData = data
	CustomNetTables:SetTableValue(
			"selection",
			"botDifficultyData",
			botDifficultyData
	)
end

function GetBotDifficultyData()
	if IsServer() then
		return botDifficultyData
	else
		return CustomNetTables:GetTableValue("selection", "botDifficultyData")
	end
end

if IsServer() then
	SetBotDifficultyData(botDifficultyDefaultData[1])
end