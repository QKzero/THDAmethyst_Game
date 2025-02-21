item_kusanagi = {}

function item_kusanagi:GetIntrinsicModifierName()
	return "modifier_item_kusanagi"
end

function item_kusanagi:OnOwnerDied(params)
	local hOwner = self:GetOwner()
	local pos = hOwner:GetAbsOrigin()
	local new_pos = pos + RandomVector(RandomInt(0, 50))
	--print("OnOwnerDied")
	--print("Item: "..self:GetAbilityName())
	--print("hOwner: "..hOwner:GetUnitName())

	-- Non-heroes should automatically drop rapier and return so they can't crash script at hOwner:IsReincarnating() check
	if not hOwner:IsRealHero() then
		hOwner:DropItemAtPositionImmediate(self, new_pos)
		return
	end
	
	if not hOwner:IsReincarnating() then
		hOwner:DropItemAtPositionImmediate(self, new_pos)
	end
end

function item_kusanagi:IsRapier()
	return true
end

modifier_item_kusanagi = {}
LinkLuaModifier("modifier_item_kusanagi", "items/item_kusanagi.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_item_kusanagi:IsHidden() return true end
function modifier_item_kusanagi:IsPurgable() return false end
function modifier_item_kusanagi:RemoveOnDeath() return false end
function modifier_item_kusanagi:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_kusanagi:DeclareFunctions()
	return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE
    }
end

function modifier_item_kusanagi:OnCreated()
	if IsServer() then
        if not self:GetAbility() then self:Destroy() end
    end

	local item = self:GetAbility()
	if item and not self:GetParent():IsCourier() and not self:GetParent():IsIllusion() then
		self.bonus_damage = item:GetSpecialValueFor("bonus_damage")
        self.bonus_spell_damage = item:GetSpecialValueFor("bonus_spell_damage")
	else
		self.bonus_damage = 0
        self.bonus_spell_damage = 0
	end
end

function modifier_item_kusanagi:GetModifierPreAttack_BonusDamage(keys)
	return self.bonus_damage
end
function modifier_item_kusanagi:GetModifierSpellAmplify_Percentage(keys)
	return self.bonus_spell_damage
end