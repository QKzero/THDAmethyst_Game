GAME_ROSHAN_KILLS = 0
if modifier_imba_roshan_ai == nil then modifier_imba_roshan_ai = class({}) end

function modifier_imba_roshan_ai:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end
function modifier_imba_roshan_ai:IsPurgeException() return false end
function modifier_imba_roshan_ai:IsPurgable() return false end
function modifier_imba_roshan_ai:IsDebuff() return false end
function modifier_imba_roshan_ai:IsHidden() return true end

function modifier_imba_roshan_ai:DeclareFunctions()
	return {
		--MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_DEATH,
	}
end

function modifier_imba_roshan_ai:OnCreated()
	if IsServer() then
		self.leash_distance = 900
		self.ForwardVector = self:GetParent():GetForwardVector()
		self.returningToLeash = false
		self.teleportAbiliyy = self:GetParent():FindAbilityByName("roshan_teleport")

		-- 肉山死亡时会掉落身上的物品
		local ROSHAN_ITEMS = GAME_ROSHAN_KILLS + 1

		self:GetParent():AddItemByName("item_aegis")

		if ROSHAN_ITEMS >= 2 then
			for i = 1, ROSHAN_ITEMS -1 do
				self:GetParent():AddItemByName("item_cheese")
			end
		end

		if ROSHAN_ITEMS >= 3 then
			self:GetParent():AddItemByName("item_wanbaochui2")
		end

		self:StartIntervalThink(1.0)
	end
end

function modifier_imba_roshan_ai:OnIntervalThink()
	-- if Roshan finished returning to his pit, purge him
	if self.returningToLeash == true and self:GetParent():IsIdle() then
		self.returningToLeash = false
		self:GetParent():Purge(false, true, true, true, false)
--		self:SetForwardVector(self.ForwardVector)
	end

	-- if Roshan is too far from pit, return him
	if (self:GetParent():GetAbsOrigin() - _G.ROSHAN_SPAWN_LOC):Length2D() >= self.leash_distance then
		self.returningToLeash = true
		self:GetParent():MoveToPosition(_G.ROSHAN_SPAWN_LOC)
	end

	-- 如果 Roshan 没有仇恨的单位， 返回
	if self:GetParent():GetAggroTarget() == nil and self:GetParent():GetAbsOrigin() ~= _G.ROSHAN_SPAWN_LOC then
		self.returningToLeash = true
		self:GetParent():MoveToPosition(_G.ROSHAN_SPAWN_LOC)
	end

	-- 强制使roshan_teleport技能进入冷却，无法施放（防止thdots地图肉山发呆）
	if self.teleportAbiliyy then
		self.teleportAbiliyy:StartCooldown(5)
	end
end

-- function modifier_imba_roshan_ai:OnAttackLanded(keys)
	-- if IsServer() then
		-- if self:GetParent() == keys.target then
			-- if keys.attacker:IsIllusion() then
				-- keys.attacker:ForceKill(true)
			-- end
		-- end
	-- end
-- end

function modifier_imba_roshan_ai:OnDeath( keys )
	if keys.unit ~= self:GetParent() then return end

	GAME_ROSHAN_KILLS = GAME_ROSHAN_KILLS + 1

	-- Respawn time for Roshan
	local respawn_time = RandomInt(6, 8) * 60
	Timer.Wait 'roshan_refresh' (respawn_time, function()
		local roshan = CreateUnitByName("npc_dota_roshan", _G.ROSHAN_SPAWN_LOC, true, nil, nil, DOTA_TEAM_NEUTRALS)
		roshan:AddNewModifier(roshan, nil, "modifier_imba_roshan_ai", {})
	end)
end
