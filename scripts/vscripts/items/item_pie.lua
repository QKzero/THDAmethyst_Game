item_mushroom_kebab={}

function item_mushroom_kebab:OnSpellStart()
    if not IsServer() then return end

	local target = self:GetCursorTarget()
	-- 用增量语义（Modify*），不用"读改写"（SetBase(GetBase()+n)）：避免与属性实验/换英雄等绝对写入互相覆盖
	target:ModifyStrength(self:GetSpecialValueFor("increase_strength"))
	if (self:IsItem()) then
		UTIL_Remove(self)
	end
end

function item_mushroom_kebab:CastFilterResultTarget(target)
	local caster = self:GetCaster()

	if target == caster then
		if GameRules:GetDOTATime(false,false) < self:GetSpecialValueFor("min_game_time") then
			-- 未到 min_game_time（KV AbilityValues）之前不可使用
			return UF_FAIL_CUSTOM
		else
			return UF_SUCCESS
		end
	else
		-- 无法对他人使用
		return UF_FAIL_CUSTOM
	end
end

function item_mushroom_kebab:GetCustomCastErrorTarget(target)
	local caster = self:GetCaster()

	if target == caster then
		if GameRules:GetDOTATime(false,false) < self:GetSpecialValueFor("min_game_time") then
			return "#thd_hud_error_cant_be_used_within_5_mins_of_game"
		end
	else
		return "#thd_hud_error_cant_be_used_on_others"
	end
end

function item_mushroom_kebab:GetIntrinsicModifierName() return  "modifier_item_mushroom_kebab" end

modifier_item_mushroom_kebab = {}
LinkLuaModifier("modifier_item_mushroom_kebab","items/item_pie.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_item_mushroom_kebab:IsHidden() return true end
function modifier_item_mushroom_kebab:IsPurgable() return false end
function modifier_item_mushroom_kebab:IsPurgeException() return false end
function modifier_item_mushroom_kebab:RemoveOnDeath() return false end
function modifier_item_mushroom_kebab:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_mushroom_kebab:DeclareFunctions() return
    {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
    }
end

function modifier_item_mushroom_kebab:GetModifierBonusStats_Strength()  return self:GetAbility():GetSpecialValueFor("bonus_strength") end
function modifier_item_mushroom_kebab:GetModifierBonusStats_Agility()   return self:GetAbility():GetSpecialValueFor("bonus_agility") end
function modifier_item_mushroom_kebab:GetModifierBonusStats_Intellect()   return self:GetAbility():GetSpecialValueFor("bonus_intellect") end
function modifier_item_mushroom_kebab:GetModifierStatusResistanceStacking()   return self:GetAbility():GetSpecialValueFor("bonus_resist") end


-- 立即生效的派
item_mushroom_kebab_immediate = {}

function item_mushroom_kebab_immediate:GetIntrinsicModifierName()
	return "modifier_item_mushroom_kebab_immediate"
end

modifier_item_mushroom_kebab_immediate = {}
LinkLuaModifier("modifier_item_mushroom_kebab_immediate","items/item_pie.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_item_mushroom_kebab_immediate:IsHidden() return true end
function modifier_item_mushroom_kebab_immediate:IsPurgable() return false end
function modifier_item_mushroom_kebab_immediate:IsPurgeException() return false end
function modifier_item_mushroom_kebab_immediate:RemoveOnDeath() return false end
function modifier_item_mushroom_kebab_immediate:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_mushroom_kebab_immediate:OnCreated()
    if not IsServer() then return end
    if self.applied then return end
    self.applied = true

	local caster = self:GetCaster()
	local ability = self:GetAbility()

	caster:ModifyStrength(ability:GetSpecialValueFor("increase_strength"))

	-- 延迟一帧再销毁宿主物品：本修改器是宿主物品的 intrinsic modifier，
	-- 若在其"正在创建"的当帧嵌套销毁宿主，引擎会漏掉回收，导致本修改器永久残留在英雄身上（越用越卡）
	if (ability:IsItem()) then
		local item = ability
		Timers:CreateTimer(0.03, function()
			if item ~= nil and (item.IsNull == nil or not item:IsNull()) then
				UTIL_Remove(item)
			end
		end)
	end
end


item_mushroom_pie={}

function item_mushroom_pie:OnSpellStart()
    if not IsServer() then return end

	local target = self:GetCursorTarget()
	-- 用增量语义（Modify*），不用"读改写"（SetBase(GetBase()+n)）：避免与属性实验/换英雄等绝对写入互相覆盖
	target:ModifyAgility(self:GetSpecialValueFor("increase_agility"))
	if (self:IsItem()) then
		UTIL_Remove(self)
	end
end

function item_mushroom_pie:CastFilterResultTarget(target)
	local caster = self:GetCaster()

	if target == caster then
		if GameRules:GetDOTATime(false,false) < self:GetSpecialValueFor("min_game_time") then
			-- 未到 min_game_time（KV AbilityValues）之前不可使用
			return UF_FAIL_CUSTOM
		else
			return UF_SUCCESS
		end
	else
		-- 无法对他人使用
		return UF_FAIL_CUSTOM
	end
end

function item_mushroom_pie:GetCustomCastErrorTarget(target)
	local caster = self:GetCaster()

	if target == caster then
		if GameRules:GetDOTATime(false,false) < self:GetSpecialValueFor("min_game_time") then
			return "#thd_hud_error_cant_be_used_within_5_mins_of_game"
		end
	else
		return "#thd_hud_error_cant_be_used_on_others"
	end
end

function item_mushroom_pie:GetIntrinsicModifierName() return  "modifier_item_mushroom_pie" end

modifier_item_mushroom_pie = {}
LinkLuaModifier("modifier_item_mushroom_pie","items/item_pie.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_item_mushroom_pie:IsHidden() return true end
function modifier_item_mushroom_pie:IsPurgable() return false end
function modifier_item_mushroom_pie:IsPurgeException() return false end
function modifier_item_mushroom_pie:RemoveOnDeath() return false end
function modifier_item_mushroom_pie:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_mushroom_pie:DeclareFunctions() return
    {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
end

function modifier_item_mushroom_pie:GetModifierBonusStats_Strength()  return self:GetAbility():GetSpecialValueFor("bonus_strength") end
function modifier_item_mushroom_pie:GetModifierBonusStats_Agility()   return self:GetAbility():GetSpecialValueFor("bonus_agility") end
function modifier_item_mushroom_pie:GetModifierBonusStats_Intellect()   return self:GetAbility():GetSpecialValueFor("bonus_intellect") end
function modifier_item_mushroom_pie:GetModifierMoveSpeedBonus_Percentage()   return self:GetAbility():GetSpecialValueFor("bonus_speed") end

-- 立即生效的派
item_mushroom_pie_immediate = {}

function item_mushroom_pie_immediate:GetIntrinsicModifierName()
	return "modifier_item_mushroom_pie_immediate"
end

modifier_item_mushroom_pie_immediate = {}
LinkLuaModifier("modifier_item_mushroom_pie_immediate","items/item_pie.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_item_mushroom_pie_immediate:IsHidden() return true end
function modifier_item_mushroom_pie_immediate:IsPurgable() return false end
function modifier_item_mushroom_pie_immediate:IsPurgeException() return false end
function modifier_item_mushroom_pie_immediate:RemoveOnDeath() return false end
function modifier_item_mushroom_pie_immediate:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_mushroom_pie_immediate:OnCreated()
    if not IsServer() then return end
    if self.applied then return end
    self.applied = true

	local caster = self:GetCaster()
	local ability = self:GetAbility()

	caster:ModifyAgility(ability:GetSpecialValueFor("increase_agility"))

	-- 同 kebab：延迟一帧销毁宿主物品，避免本 intrinsic modifier 漏回收而残留
	if (ability:IsItem()) then
		local item = ability
		Timers:CreateTimer(0.03, function()
			if item ~= nil and (item.IsNull == nil or not item:IsNull()) then
				UTIL_Remove(item)
			end
		end)
	end
end

item_mushroom_soup={}

function item_mushroom_soup:OnSpellStart()
    if not IsServer() then return end

	local target = self:GetCursorTarget()
	-- 用增量语义（Modify*），不用"读改写"（SetBase(GetBase()+n)）：避免与属性实验/换英雄等绝对写入互相覆盖
	target:ModifyIntellect(self:GetSpecialValueFor("increase_intellect"))
	if (self:IsItem()) then
		UTIL_Remove(self)
	end
end

function item_mushroom_soup:CastFilterResultTarget(target)
	local caster = self:GetCaster()

	if target == caster then
		if GameRules:GetDOTATime(false,false) < self:GetSpecialValueFor("min_game_time") then
			-- 未到 min_game_time（KV AbilityValues）之前不可使用
			return UF_FAIL_CUSTOM
		else
			return UF_SUCCESS
		end
	else
		-- 无法对他人使用
		return UF_FAIL_CUSTOM
	end
end

function item_mushroom_soup:GetCustomCastErrorTarget(target)
	local caster = self:GetCaster()

	if target == caster then
		if GameRules:GetDOTATime(false,false) < self:GetSpecialValueFor("min_game_time") then
			return "#thd_hud_error_cant_be_used_within_5_mins_of_game"
		end
	else
		return "#thd_hud_error_cant_be_used_on_others"
	end
end

function item_mushroom_soup:GetIntrinsicModifierName() return  "modifier_item_mushroom_soup" end

modifier_item_mushroom_soup = {}
LinkLuaModifier("modifier_item_mushroom_soup","items/item_pie.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_item_mushroom_soup:IsHidden() return true end
function modifier_item_mushroom_soup:IsPurgable() return false end
function modifier_item_mushroom_soup:IsPurgeException() return false end
function modifier_item_mushroom_soup:RemoveOnDeath() return false end
function modifier_item_mushroom_soup:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_mushroom_soup:DeclareFunctions() return
    {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE
    }
end

function modifier_item_mushroom_soup:GetModifierBonusStats_Strength()  return self:GetAbility():GetSpecialValueFor("bonus_strength") end
function modifier_item_mushroom_soup:GetModifierBonusStats_Agility()   return self:GetAbility():GetSpecialValueFor("bonus_agility") end
function modifier_item_mushroom_soup:GetModifierBonusStats_Intellect()   return self:GetAbility():GetSpecialValueFor("bonus_intellect") end
function modifier_item_mushroom_soup:GetModifierPercentageCooldown()   return self:GetAbility():GetSpecialValueFor("bonus_cooldown_reduction") end


-- 立即生效的派
item_mushroom_soup_immediate = {}

function item_mushroom_soup_immediate:GetIntrinsicModifierName()
	return "modifier_item_mushroom_soup_immediate"
end

modifier_item_mushroom_soup_immediate = {}
LinkLuaModifier("modifier_item_mushroom_soup_immediate","items/item_pie.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_item_mushroom_soup_immediate:IsHidden() return true end
function modifier_item_mushroom_soup_immediate:IsPurgable() return false end
function modifier_item_mushroom_soup_immediate:IsPurgeException() return false end
function modifier_item_mushroom_soup_immediate:RemoveOnDeath() return false end
function modifier_item_mushroom_soup_immediate:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_mushroom_soup_immediate:OnCreated()
    if not IsServer() then return end
    if self.applied then return end
    self.applied = true

	local caster = self:GetCaster()
	local ability = self:GetAbility()

	caster:ModifyIntellect(ability:GetSpecialValueFor("increase_intellect"))

	-- 同 kebab：延迟一帧销毁宿主物品，避免本 intrinsic modifier 漏回收而残留
	if (ability:IsItem()) then
		local item = ability
		Timers:CreateTimer(0.03, function()
			if item ~= nil and (item.IsNull == nil or not item:IsNull()) then
				UTIL_Remove(item)
			end
		end)
	end
end