-- 仇恨之弓：弹道速度加成
-- datadriven 修正器的 Properties 不支持 MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS（不在白名单内，会被静默忽略），
-- 因此改由 OnCreated/OnDestroy 桥接一个 Lua 修正器来提供该属性。
-- 数值不写死，统一从该道具 AbilityValues 的 projectile_speed 读取。

modifier_item_grudge_bow_projectile_speed = {}
LinkLuaModifier("modifier_item_grudge_bow_projectile_speed", "scripts/vscripts/items/item_grudge_bow.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_item_grudge_bow_projectile_speed:IsHidden() return true end
function modifier_item_grudge_bow_projectile_speed:IsPurgable() return false end
function modifier_item_grudge_bow_projectile_speed:IsPurgeException() return false end
function modifier_item_grudge_bow_projectile_speed:RemoveOnDeath() return false end

function modifier_item_grudge_bow_projectile_speed:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_grudge_bow_projectile_speed:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS,
	}
end

function modifier_item_grudge_bow_projectile_speed:GetModifierProjectileSpeedBonus()
	return self:GetAbility():GetSpecialValueFor("projectile_speed")
end

-- 由 item_grudge_bow.txt 的 modifier_item_grudge_bow 在 OnCreated 时调用
function ItemAbility_Grudge_Bow_ProjectileSpeed_OnCreated(keys)
	local caster = keys.caster
	if not caster or caster:IsNull() then return end
	caster:AddNewModifier(caster, keys.ability, keys.ModifierName, {})
end

-- 由 item_grudge_bow.txt 的 modifier_item_grudge_bow 在 OnDestroy 时调用
function ItemAbility_Grudge_Bow_ProjectileSpeed_OnDestroy(keys)
	local caster = keys.caster
	if not caster or caster:IsNull() then return end
	caster:RemoveModifierByName(keys.ModifierName)
end
