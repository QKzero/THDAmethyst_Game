-- Created by Elfansoer: https://github.com/Elfansoer/dota-2-lua-abilities/blob/master/scripts/vscripts/lua_abilities
--[[
	HOW TO USE:
	- Include this file in 'addon_init.lua' (for Lua client)
	- Copy 'custom_indicator.js' to panorama scripts folder (and include it in custom_ui_manifest.xml)
	- Add custom indicator entry on 'scripts/custom.gameevents' (see the file):
		"custom_indicator"
		{
			"ability"	"int"
			"behavior"	"int"
			"event"		"byte"
			"unit"		"int"
			"worldX"	"float"
			"worldY"	"float"
			"worldZ"	"float"
		}
	- Register the ability using CustomIndicator:RegisterAbility( self ) in ability:Spawn() (see examples).
	- Implement CreateCustomIndicator, UpdateCustomIndicator, and DestroyCustomIndicator (see examples).

	OVERVIEW:
	- All 3 abstract functions receives 3 parameters:
		- position, where current cursor is pointed at on the world
		- unit, where current mouse is pointing at. nil if no unit under cursor
		- behavior, currently allows these clickbehaviors:
			- DOTA_CLICK_BEHAVIOR_CAST: when player is aiming to cast the ability
			- DOTA_CLICK_BEHAVIOR_VECTOR_CAST: when player is aiming on second phase of vector target ability

	- About the functions:
		- CreateCustomIndicator triggers when player starts to cast the ability
		- UpdateCustomIndicator gets called repeatedly while player is still casting
		- DestroyCustomIndicator triggers when player finishes casting (either confirming cast or cancelling)
			- position and unit refers to last position and last unit before casting ends.

	- Each 3 functions gets called separately for different behaviors.
		- For non-vector abilities, 3 functions are only for DOTA_CLICK_BEHAVIOR_CAST behavior
		- For vector abilities, 3 functions gets called during DOTA_CLICK_BEHAVIOR_CAST,
			then all 3 gets called again during DOTA_CLICK_BEHAVIOR_VECTOR_CAST
		- The order is pretty much like this:
			CreateCustomIndicator( BEHAVIOR_CAST )
			UpdateCustomIndicator( BEHAVIOR_CAST ) (loops)
			DestroyCustomIndicator( BEHAVIOR_CAST )
			CreateCustomIndicator( BEHAVIOR_VECTOR_CAST )
			UpdateCustomIndicator( BEHAVIOR_VECTOR_CAST ) (loops)
			DestroyCustomIndicator( BEHAVIOR_VECTOR_CAST )
]]

local BEHAVIOR_EVENT_START = 0;
local BEHAVIOR_EVENT_UPDATE = 1;
local BEHAVIOR_EVENT_END = 2;

--兜底自检：panorama 侧的 END 事件并非总能到达（高频点击/被打断/带自动施法的技能会把点击行为一直停在施法态）。
--判据用"事件是否还在流动"而不是"时间差"：panorama 以 ~100fps 持续发 UPDATE，只要连着若干次检查都没有看到新的
--START/UPDATE，就认为瞄准已结束、主动回收，避免"永久残留的指示器"。
--（刻意不依赖 GameRules:GetGameTime —— 本库其余 SetContextThink 全在服务端，客户端该接口与时钟均未经验证）
local INDICATOR_STALE_CHECKS = 3   -- 检查次数 × 0.1s ≈ 0.3s 无事件即回收
local INDICATOR_CHECK_INTERVAL = 0.1

local function StartIndicatorWatchdog( ability )
	if ability.indicator_watchdog then return end
	if ability.indicator_watchdog_unavailable then return end
	local caster = ability:GetCaster()
	if caster == nil or caster:IsNull() then return end
	ability.indicator_watchdog = true
	local ok = pcall(function()
		local last_seen = ability.indicator_events or 0
		local idle = 0
		caster:SetContextThink("custom_indicator_watchdog_" .. tostring(ability:entindex()), function()
			if ability.indicator_watchdog ~= true then return nil end
			local seen = ability.indicator_events or 0
			if seen == last_seen then
				idle = idle + 1
				if idle >= INDICATOR_STALE_CHECKS then
					if ability.DestroyCustomIndicator then
						ability:DestroyCustomIndicator()
					end
					ability.indicator_watchdog = nil
					return nil
				end
			else
				last_seen = seen
				idle = 0
			end
			return INDICATOR_CHECK_INTERVAL
		end, INDICATOR_CHECK_INTERVAL)
	end)
	if not ok then
		--客户端不支持 SetContextThink：不再重试（另有 JS 侧补齐 END 与模块侧自愈重建兜底）
		ability.indicator_watchdog = nil
		ability.indicator_watchdog_unavailable = true
	end
end

if not CustomIndicator then
	CustomIndicator = {}
end

function CustomIndicator:Init()
	if self.initialized then return end

	self.initialized = true
	self.listeners = {}
	ListenToGameEvent("custom_indicator", Dynamic_Wrap(CustomIndicator, 'PanoramaListener'), self)
end

function CustomIndicator:RegisterAbility( ability )
	local ability_index = ability:entindex()
	self.listeners[ ability_index ] = ability
end

function CustomIndicator:PanoramaListener( data )
	local ability = self.listeners[ data.ability ]
	if ability then
		local pos = Vector( data.worldX, data.worldY, data.worldZ )
		--鼠标压在 UI 上时 GetScreenWorldPosition 会返回 (0,0,0)，会把指示器画向地图原点；
		--此时退回施法者坐标（得到零长度/朝向的指示器，而不是方向错误的残留）
		if data.worldX == 0 and data.worldY == 0 and data.worldZ == 0 then
			local caster = ability:GetCaster()
			if caster ~= nil and caster:IsNull() == false then
				pos = caster:GetAbsOrigin()
			end
		end
		local unit = nil
		if data.unit then
			unit = EntIndexToHScript( data.unit )
		end

		if data.event==BEHAVIOR_EVENT_START then
			if ability.CreateCustomIndicator then
				ability:CreateCustomIndicator( pos, unit, data.behavior )
			end
			ability.indicator_events = (ability.indicator_events or 0) + 1
			StartIndicatorWatchdog( ability )
		elseif data.event==BEHAVIOR_EVENT_UPDATE then
			if ability.UpdateCustomIndicator then
				ability:UpdateCustomIndicator( pos, unit, data.behavior )
			end
			ability.indicator_events = (ability.indicator_events or 0) + 1
			--START 事件若丢失过，这里补挂看门狗（已挂/客户端不支持时会直接返回）
			StartIndicatorWatchdog( ability )
		elseif data.event==BEHAVIOR_EVENT_END then
			if ability.DestroyCustomIndicator then
				ability:DestroyCustomIndicator( pos, unit, data.behavior )
			end
			ability.indicator_watchdog = nil
		end
	end
end

CustomIndicator:Init()

return CustomIndicator