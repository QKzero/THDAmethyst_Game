-- 通用"矩形带"施法指示器
-- 把"以施法者为起点、方向随鼠标、长度可固定/可封顶、带宽可参数化"的矩形指示器抽象为可复用模块，
-- 供多个自定义技能共用（当前：红美铃01、魔炮04）。依赖本库 CustomIndicator 框架（util/custom_indicator.lua）。
--
-- 接入方式（仅在技能的客户端分支里）：
--   function ability_xxx:Spawn()
--       if not IsServer() then
--           CustomIndicator:RegisterAbility(self)
--           RectIndicator:Attach(self, {
--               -- 可多条带叠加：外圈 + 内圈（ADD 混合下重叠区自然更亮，可用于高亮"额外伤害区"）
--               bands = {
--                   { particle = "particles/indicators/rect_range_finder.vpcf", half_width = 200 },
--                   { particle = "particles/indicators/rect_range_finder.vpcf", half_width = 100 },
--               },
--               -- 长度：返回固定值即"长恒定"；用鼠标距离即"跟随鼠标"（自行 clamp）
--               get_length = function(ability, loc) return 960 end,
--           })
--       end
--   end
--
-- 也兼容单条带简写：{ particle = <路径>, half_width = <数值> }。
-- 粒子约定：控制点 0 = 起点、1 = 终点、6 = 起点；带宽（半径）由控制点 2 的 x 分量驱动。
RectIndicator = RectIndicator or {}

local CONFIGS = {}
local PARTICLES = {}

local function Destroy(ability)
	local list = PARTICLES[ability]
	if list == nil then return end
	for _, particle in pairs(list) do
		ParticleManager:DestroyParticle(particle, true)
		ParticleManager:ReleaseParticleIndex(particle)
	end
	PARTICLES[ability] = nil
end

local function Update(ability, location)
	local opts = CONFIGS[ability]
	local list = PARTICLES[ability]
	if opts == nil or list == nil or location == nil then return end
	local caster = ability:GetCaster()
	if caster == nil or caster:IsNull() then return end

	local origin = caster:GetAbsOrigin()
	local direction = location - origin
	direction.z = 0
	if direction:Length2D() < 1 then
		--鼠标压在脚下时退回朝向，避免零向量归一化
		direction = caster:GetForwardVector()
		direction.z = 0
	end
	direction = direction:Normalized()

	local length = 0
	if opts.get_length ~= nil then
		length = opts.get_length(ability, location) or 0
	else
		length = (location - origin):Length2D()
	end
	if length < 0 then length = 0 end
	local endPos = origin + direction * length

	for i, band in ipairs(opts.bands) do
		local particle = list[i]
		if particle ~= nil then
			ParticleManager:SetParticleControl(particle, 0, origin)
			ParticleManager:SetParticleControl(particle, 1, endPos)
			ParticleManager:SetParticleControl(particle, 6, origin)
			--带宽参数：半宽写控制点 2 的 x 分量（粒子半径 = 半宽 ⇒ 视觉带宽 = 2×半宽）
			ParticleManager:SetParticleControl(particle, 2, Vector(band.half_width or 0, 0, 0))
		end
	end
end

local function Create(ability, location)
	local opts = CONFIGS[ability]
	if opts == nil then return end
	local caster = ability:GetCaster()
	if caster == nil or caster:IsNull() then return end
	--同一技能可能重复触发 START，先回收旧粒子，避免叠加残留
	Destroy(ability)
	local list = {}
	for _, band in ipairs(opts.bands) do
		if band.particle ~= nil then
			list[#list + 1] = ParticleManager:CreateParticle(band.particle, PATTACH_ABSORIGIN_FOLLOW, caster)
		end
	end
	PARTICLES[ability] = list
	if location ~= nil then
		Update(ability, location)
	end
end

--在技能 Spawn()（客户端）里调用：登记配置并把框架需要的三个回调挂到技能上
function RectIndicator:Attach(ability, opts)
	local bands = opts.bands
	if bands == nil then
		--单条带简写
		bands = { { particle = opts.particle, half_width = opts.half_width } }
	end
	CONFIGS[ability] = { bands = bands, get_length = opts.get_length }
	PARTICLES[ability] = nil
	ability.CreateCustomIndicator = function(self, location) Create(self, location) end
	ability.UpdateCustomIndicator = function(self, location) Update(self, location) end
	ability.DestroyCustomIndicator = function(self) Destroy(self) end
end

return RectIndicator
