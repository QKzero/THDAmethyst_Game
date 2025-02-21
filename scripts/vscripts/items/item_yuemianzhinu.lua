function ItemAbility_yuemianzhinu_range(keys)
	local caster = keys.caster
	local ability = keys.ability
    caster:AddNewModifier(caster, ability, "modifier_item_yuemianzhinu_range",{ })
end
function ItemAbility_yuemianzhinu_range_destory(keys)
	local caster = keys.caster
	if caster:HasModifier("modifier_item_yuemianzhinu") then return end
    caster:RemoveModifierByName("modifier_item_yuemianzhinu_range")
end
modifier_item_yuemianzhinu_range = modifier_item_yuemianzhinu_range or class({})
LinkLuaModifier("modifier_item_yuemianzhinu_range", "items/item_yuemianzhinu.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_item_yuemianzhinu_range:IsDebuff() return false end

function modifier_item_yuemianzhinu_range:IsHidden() return true end

function modifier_item_yuemianzhinu_range:IsPurgable() return false end

function modifier_item_yuemianzhinu_range:RemoveOnDeath() return false end

function modifier_item_yuemianzhinu_range:OnCreated(params)
    if not IsServer() then return end
end
function modifier_item_yuemianzhinu_range:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS
	}
end
function modifier_item_yuemianzhinu_range:GetModifierAttackRangeBonus()
	if self:GetCaster():IsRangedAttacker() and not self:GetParent():HasModifier("modifier_item_yuemianjidongzhuangzhi_range") then
		return self:GetAbility():GetSpecialValueFor("bonus_attack_range")
	end
end