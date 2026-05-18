
MUSHROOM_BANED_VEC = {
Vector(-4997.613770,-5483.517090,128.000000),
Vector(-2879.457031,-5381.724121,128.000000),
Vector(403.047760,-5450.785156,128.000000),
Vector(1833.770142,-2792.065430,128.000000),
Vector(1045.798950,-1009.788635,128.000000),
Vector(-2239.795410,2064.000000,128.000000),
Vector(-3031.070801,3913.613037,256.000000),
Vector(-1695.215820,5525.166992,256.000000),
Vector(2502.371094,5703.623047,256.000000),
Vector(5239.779785,5687.033691,256.000000),
}

function MushRoomStart()
	local mushroom_time = 0
	local start_time = 0		--刷蘑菇时间
	local interval_time = 60	--刷蘑菇间隔
	-- GameRules:SendCustomMessage("<font color='#00FFFF'>刷蘑菇启动</font>", 0, 0)
	-- 优化：原实现每帧 Think，但真正触发间隔是 60 秒，改为秒级轮询。
	local MUSHROOM_THINK_INTERVAL = 1.0
	THD_SetGlobalContextThink("mushroom_time",
		function()
			if GameRules:IsGamePaused() then return MUSHROOM_THINK_INTERVAL end
			if math.floor(GameRules:GetDOTATime(false, false)) >= start_time then
				start_time = start_time + interval_time
				-- GameRules:SendCustomMessage("<font color='#00FFFF'>刷一波蘑菇</font>", 0, 0)
				CreateMushRoom()
			end
			mushroom_time = mushroom_time + MUSHROOM_THINK_INTERVAL
			return MUSHROOM_THINK_INTERVAL
		end
		,
		0)
end

function CreateMushRoom()
	local MUSHROOM_SPAWN_CENTER = Vector(0, 0, 0)
	local MUSHROOM_SPAWN_RADIUS = 7500
	local MUSHROOM_DESTROY_TIME = 300 -- 蘑菇消除时间
	local MUSHROOM_CHANCE_THRESHOLD = 995 -- 蘑菇生成几率。共约 1380 棵树
	local MUSHROOM_MAX_PER_WAVE = 8
	local trees = GridNav:GetAllTreesAroundPoint(MUSHROOM_SPAWN_CENTER, MUSHROOM_SPAWN_RADIUS, false)
	local spawned = 0
	for _,tree in pairs(trees) do
		if spawned >= MUSHROOM_MAX_PER_WAVE then break end
		if RandomInt(1,1000) > MUSHROOM_CHANCE_THRESHOLD then
			spawned = spawned + 1
			local item = CreateItem("item_magic_mushroom", nil, nil)
			local pos = tree:GetAbsOrigin()
			local drop = CreateItemOnPositionSync(pos, item)
			-- AddFOWViewer(DOTA_TEAM_GOODGUYS, pos,128,300,false)
			drop:SetContextThink("drop_destroy", function ()
				if drop ~= nil and not drop:IsNull() then
					drop:RemoveSelf()
				end
				if item ~= nil and not item:IsNull() then
					UTIL_Remove(item)
				end
			end, MUSHROOM_DESTROY_TIME)
			-- item:LaunchLoot(false, 300, 0.5, pos)
		end
	end
end