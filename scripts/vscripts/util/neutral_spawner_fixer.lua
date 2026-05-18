Neutrals = Neutrals or class({})

require("util.util")

Neutrals.Spanwers = {}
THD_NEUTRAL_SPAWNER_FIXER_ENABLED = true
THD_NEUTRAL_SPAWNER_FIXER_STATS = {
	ticks = 0,
	disabledTicks = 0,
	spawnersChecked = 0,
	spawned = 0,
}

function THD_ResetNeutralSpawnerFixerStats()
	THD_NEUTRAL_SPAWNER_FIXER_STATS = {
		ticks = 0,
		disabledTicks = 0,
		spawnersChecked = 0,
		spawned = 0,
	}
end

function THD_SetNeutralSpawnerFixerEnabled(enabled, source)
	THD_NEUTRAL_SPAWNER_FIXER_ENABLED = enabled == true
	local message = string.format(
		"[THD][NeutralSpawnerFixer] enabled=%s source=%s",
		tostring(THD_NEUTRAL_SPAWNER_FIXER_ENABLED),
		tostring(source or "unknown")
	)
	print(message)
	if GameRules ~= nil then
		GameRules:SendCustomMessage(message, 0, 0)
	end
end

function THD_GetNeutralSpawnerFixerEnabled()
	return THD_NEUTRAL_SPAWNER_FIXER_ENABLED == true
end

function THD_GetNeutralSpawnerFixerStats()
	local stats = THD_NEUTRAL_SPAWNER_FIXER_STATS or {}
	local mappedSpawners = 0
	for _ in pairs(Neutrals.Spanwers or {}) do
		mappedSpawners = mappedSpawners + 1
	end
	return {
		enabled = THD_NEUTRAL_SPAWNER_FIXER_ENABLED == true,
		ticks = stats.ticks or 0,
		disabledTicks = stats.disabledTicks or 0,
		spawnersChecked = stats.spawnersChecked or 0,
		spawned = stats.spawned or 0,
		mappedSpawners = mappedSpawners,
	}
end

function THD2_neutral_spawner_fixer()

    local start_time = 60		-- 初始时间
	local interval_time = 60	-- 间隔时间

	-- init
	for i, spawner in pairs(Entities:FindAllByClassname("npc_dota_neutral_spawner") or {}) do

		for idx, trigger in pairs(Entities:FindAllByClassname("trigger_multiple") or {}) do

			if spawner and trigger then

				-- 记录spawner对应的trigger
				if (spawner:GetAbsOrigin() - trigger:GetAbsOrigin()):Length2D() < 1000 then
					--print("triggerName: "..trigger:GetName())
					Neutrals.Spanwers[spawner] = trigger

					break
				end
			end
		end

	end

	-- timer
	-- 优化：原实现每帧 Think，但真正触发间隔是 60 秒，改为秒级轮询。
	local NEUTRAL_SPAWNER_THINK_INTERVAL = 1.0
    THD_SetGlobalContextThink("neutral_spawner_fixer",
		function()
			if GameRules:IsGamePaused() then return NEUTRAL_SPAWNER_THINK_INTERVAL end
			if math.floor(GameRules:GetDOTATime(false, false)) >= start_time then
                --print("start_time: "..start_time)
				start_time = start_time + interval_time

				if THD_GetNeutralSpawnerFixerEnabled == nil or THD_GetNeutralSpawnerFixerEnabled() then
					local stats = THD_NEUTRAL_SPAWNER_FIXER_STATS or {}
					stats.ticks = (stats.ticks or 0) + 1
					THD_NEUTRAL_SPAWNER_FIXER_STATS = stats
					CheckNeutralSpawn()
				else
					local stats = THD_NEUTRAL_SPAWNER_FIXER_STATS or {}
					stats.disabledTicks = (stats.disabledTicks or 0) + 1
					THD_NEUTRAL_SPAWNER_FIXER_STATS = stats
					if THD_SanitizeNeutralNativeAbilities ~= nil then
						THD_SanitizeNeutralNativeAbilities("neutral_spawner_fixer_disabled")
					end
				end
				if THD_CleanupHiddenInvulnerableNeutrals ~= nil then
					THD_CleanupHiddenInvulnerableNeutrals("neutral_spawner_fixer_timer")
				end
				if THD_ALL_NEUTRAL_CLEANUP_ENABLED == true and THD_CleanupAllNeutralUnits ~= nil then
					THD_CleanupAllNeutralUnits("neutral_spawner_fixer_timer")
				end
				if THD_ApplyCombatExperiments ~= nil then
					THD_ApplyCombatExperiments("neutral_spawner_fixer_timer")
				end
			end

			return NEUTRAL_SPAWNER_THINK_INTERVAL
		end
		,
		0)
end

function CheckNeutralSpawn()
	for i, spawner in pairs(Entities:FindAllByClassname("npc_dota_neutral_spawner") or {}) do
		local stats = THD_NEUTRAL_SPAWNER_FIXER_STATS or {}
		stats.spawnersChecked = (stats.spawnersChecked or 0) + 1
		THD_NEUTRAL_SPAWNER_FIXER_STATS = stats

		local trigger = Neutrals.Spanwers[spawner]

		-- 附近可能阻止中立刷新的单位
		local units = FindUnitsInRadius(
			DOTA_TEAM_FIRST,
			trigger:GetAbsOrigin(),
			nil,
			1200,
			DOTA_UNIT_TARGET_TEAM_BOTH,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_OTHER,
			DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD,
			0,
			false
		)

		--print(trigger:GetName().." pre#units = "..#units)

		for idx = #units, 1, -1 do
			--print("trying touching: "..units[idx]:GetUnitName())
			if not trigger:IsTouching(units[idx]) then
				table.remove(units, idx)
			end
		end

		-- 如果trigger内有单位，判断是否阻止中立刷新
		if #units > 0 then
			--print(trigger:GetName().." touching#units = "..#units)
			for idx = #units, 1, -1 do
				local unit = units[idx]

				--print("!unitName: "..unit:GetUnitName())
				--print("!unitClassname: "..unit:GetClassname())

				if unit:GetClassname() == "npc_dota_base_additive" or not IsTHD2BlockingNeutrals(unit) or unit:HasModifier("dummy_unit") then
					table.remove(units, idx)
					--print("removed")
				end
			end

			-- 没有阻止中立刷新的单位，刷新中立
			if #units == 0 then
				spawner:SpawnNextBatch(true)
				local stats = THD_NEUTRAL_SPAWNER_FIXER_STATS or {}
				stats.spawned = (stats.spawned or 0) + 1
				THD_NEUTRAL_SPAWNER_FIXER_STATS = stats
				--print("spawn ingore thd2 blockers")
			end
		end
	end

	if THD_SanitizeNeutralNativeAbilities ~= nil then
		THD_SanitizeNeutralNativeAbilities("neutral_spawner_fixer")
	end
end

-- utils
function IsTHD2BlockingNeutrals(hUnit)
	if hUnit.THD2BlockingNeutrals == nil then
		return true
	end
	return hUnit.THD2BlockingNeutrals
end

function SetTHD2BlockingNeutrals(hUnit, bool)
	hUnit.THD2BlockingNeutrals = bool
end