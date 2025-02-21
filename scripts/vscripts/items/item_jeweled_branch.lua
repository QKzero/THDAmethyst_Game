item_jeweled_branch = {}
function item_jeweled_branch:GetIntrinsicModifierName()
	return "modifier_item_jeweled_branch_bonus"
end

modifier_item_jeweled_branch_bonus = {}
LinkLuaModifier("modifier_item_jeweled_branch_bonus","items/item_jeweled_branch.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_item_jeweled_branch_bonus:IsHidden() return true end
function modifier_item_jeweled_branch_bonus:IsPurgable() return false end
function modifier_item_jeweled_branch_bonus:IsPurgeException() return false end
function modifier_item_jeweled_branch_bonus:RemoveOnDeath() return false end
function modifier_item_jeweled_branch_bonus:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_jeweled_branch_bonus:DeclareFunctions() return
    {
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_MANA_BONUS,
        -- MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        -- MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        -- MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        -- MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        -- MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
    }
end

function modifier_item_jeweled_branch_bonus:GetModifierHealthBonus() return self:GetAbility():GetSpecialValueFor("bonus_hp") end
function modifier_item_jeweled_branch_bonus:GetModifierManaBonus() return self:GetAbility():GetSpecialValueFor("bonus_mp") end
--function modifier_item_jeweled_branch_bonus:GetModifierBonusStats_Strength() return self:GetAbility():GetSpecialValueFor("bonus_all_state") end
--function modifier_item_jeweled_branch_bonus:GetModifierBonusStats_Agility()   return self:GetAbility():GetSpecialValueFor("bonus_all_state") end
--function modifier_item_jeweled_branch_bonus:GetModifierBonusStats_Intellect() return self:GetAbility():GetSpecialValueFor("bonus_all_state") end
--function modifier_item_jeweled_branch_bonus:GetModifierConstantHealthRegen()return self:GetAbility():GetSpecialValueFor("bonus_health_regen") end
--function modifier_item_jeweled_branch_bonus:GetModifierConstantManaRegen()return self:GetAbility():GetSpecialValueFor("bonus_mana_regen") end
function modifier_item_jeweled_branch_bonus:OnCreated()
    if not IsServer() then return end
    local parent = self:GetParent()

    parent:AddNewModifier(parent, self:GetAbility(), "modifier_item_jeweled_branch_passive", {duration = -1})
end
function modifier_item_jeweled_branch_bonus:OnDestroy()
	if not IsServer() then return end
	local parent = self:GetParent()

    if parent:HasModifier("modifier_item_jeweled_branch_bonus") then return end
	parent:RemoveModifierByNameAndCaster("modifier_item_jeweled_branch_passive", parent)
end

modifier_item_jeweled_branch_passive = {}
LinkLuaModifier("modifier_item_jeweled_branch_passive","items/item_jeweled_branch.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_item_jeweled_branch_passive:IsHidden() return true end
function modifier_item_jeweled_branch_passive:IsPurgable() return false end
function modifier_item_jeweled_branch_passive:IsPurgeException() return false end
function modifier_item_jeweled_branch_passive:RemoveOnDeath() return false end

function modifier_item_jeweled_branch_passive:DeclareFunctions() return
    {
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_INCOMING_SPELL_DAMAGE_CONSTANT
    }
end

function modifier_item_jeweled_branch_passive:OnCreated()
end

function modifier_item_jeweled_branch_passive:OnTakeDamage(keys)
    if not IsServer() then return end
    local parent  = self:GetParent()
    local ability = self:GetAbility()
    if parent == keys.unit then 
        if parent:GetContext("ability_yuyuko_Ex_deadflag") == TRUE then return end
        parent:GiveMana(math.max(keys.damage, 0) * ability:GetSpecialValueFor("hp2mp")*0.01)
    end
    if parent == keys.attacker  and not keys.unit:IsBuilding() then
        if keys.damage_category == DOTA_DAMAGE_CATEGORY_SPELL and bit.band(keys.damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL) ~= DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL then			
			-- Particle effect
			self.lifesteal_pfx = ParticleManager:CreateParticle("particles/items3_fx/octarine_core_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, keys.attacker)
			ParticleManager:SetParticleControl(self.lifesteal_pfx, 0, keys.attacker:GetAbsOrigin())
			ParticleManager:ReleaseParticleIndex(self.lifesteal_pfx)
			keys.attacker:Heal(math.max(keys.damage, 0) * ability:GetSpecialValueFor("spell_lifesteal") * 0.01, keys.attacker)
        end
    end
end
