Neutrals = Neutrals or class({})

Neutrals.Spanwers = {}

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
    GameRules:GetGameModeEntity():SetContextThink("neutral_spawner_fixer",
		function()
			if GameRules:IsGamePaused() then return FrameTime() end
			if math.floor(GameRules:GetDOTATime(false, false)) >= start_time then
                --print("start_time: "..start_time)
				start_time = start_time + interval_time

				CheckNeutralSpawn()
			end

			return FrameTime()
		end
		,
		0)
end

function CheckNeutralSpawn()
	for i, spawner in pairs(Entities:FindAllByClassname("npc_dota_neutral_spawner") or {}) do
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
				--print("spawn ingore thd2 blockers")
			end
		end
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