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

--兜底自检：panorama 侧的 END 事件并非总能到达（例如带自动施法的技能，点击行为会一直停在施法态），
--失去更新超过该秒数就主动回收指示器，避免"永久残留的指示器"
local INDICATOR_STALE_TIME = 0.25

local function IndicatorNow()
	local ok, t = pcall(GameRules.GetGameTime, GameRules)
	if ok and type(t) == "number" then return t end
	return 0
end

local function StartIndicatorWatchdog( ability )
	if ability.indicator_watchdog then return end
	local caster = ability:GetCaster()
	if caster == nil or caster:IsNull() then return end
	ability.indicator_watchdog = true
	local ok = pcall(function()
		caster:SetContextThink("custom_indicator_watchdog_" .. tostring(ability:entindex()), function()
			if ability.indicator_watchdog ~= true then return nil end
			if IndicatorNow() - (ability.indicator_last_update or 0) > INDICATOR_STALE_TIME then
				if ability.DestroyCustomIndicator then
					ability:DestroyCustomIndicator()
				end
				ability.indicator_watchdog = nil
				return nil
			end
			return 0.1
		end, INDICATOR_STALE_TIME)
	end)
	if not ok then
		ability.indicator_watchdog = nil
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
			ability.indicator_last_update = IndicatorNow()
			StartIndicatorWatchdog( ability )
		elseif data.event==BEHAVIOR_EVENT_UPDATE then
			if ability.UpdateCustomIndicator then
				ability:UpdateCustomIndicator( pos, unit, data.behavior )
			end
			ability.indicator_last_update = IndicatorNow()
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