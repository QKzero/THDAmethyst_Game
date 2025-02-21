item_fireflies_light = {}

function item_fireflies_light:GetIntrinsicModifierName()
	return "modifier_item_fireflies_light_passive"
end


modifier_item_fireflies_light_passive = {}
LinkLuaModifier("modifier_item_fireflies_light_passive","items/item_fireflies_light.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_item_fireflies_light_passive:IsHidden() return true end
function modifier_item_fireflies_light_passive:IsPurgable() return false end
function modifier_item_fireflies_light_passive:IsPurgeException() return false end
function modifier_item_fireflies_light_passive:RemoveOnDeath() return false end

function modifier_item_fireflies_light_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
		MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
	}
end

function modifier_item_fireflies_light_passive:GetModifierPreAttack_BonusDamage()
		return self:GetAbility():GetSpecialValueFor("bonus_damage")+self:GetAbility():GetSpecialValueFor("bonus_damage")*self:GetStackCount()*self:GetAbility():GetSpecialValueFor("night_improve")*0.01
end

function modifier_item_fireflies_light_passive:GetModifierStatusResistanceStacking() 
		return self:GetAbility():GetSpecialValueFor("debuff_decrease")+self:GetAbility():GetSpecialValueFor("debuff_decrease")*self:GetStackCount()*self:GetStackCount()*self:GetAbility():GetSpecialValueFor("night_improve")*0.01
end

function modifier_item_fireflies_light_passive:GetBonusNightVision()
	return self:GetAbility():GetSpecialValueFor("bonus_night_vision")
end

function modifier_item_fireflies_light_passive:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("movespeed_percent")+self:GetAbility():GetSpecialValueFor("movespeed_percent")*self:GetStackCount()*self:GetStackCount()*self:GetAbility():GetSpecialValueFor("night_improve")*0.01
end

function modifier_item_fireflies_light_passive:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("bonus_all_stats")+self:GetAbility():GetSpecialValueFor("bonus_all_stats")*self:GetStackCount()*self:GetAbility():GetSpecialValueFor("night_improve")*0.01
end
function modifier_item_fireflies_light_passive:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("bonus_all_stats")+self:GetAbility():GetSpecialValueFor("bonus_all_stats")*self:GetStackCount()*self:GetAbility():GetSpecialValueFor("night_improve")*0.01
end
function modifier_item_fireflies_light_passive:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("bonus_all_stats")+self:GetAbility():GetSpecialValueFor("bonus_all_stats")*self:GetStackCount()*self:GetAbility():GetSpecialValueFor("night_improve")*0.01
end

function modifier_item_fireflies_light_passive:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(2)
end
function modifier_item_fireflies_light_passive:OnIntervalThink()
	if not GameRules:IsDaytime() then 
	  self:SetStackCount(1)
	else
	  self:SetStackCount(0)
	end
end