function ItemAbility_Flower_Umbrella_OnSpellStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	local targets = FindUnitsInRadius(
		caster:GetTeam(),
		caster:GetAbsOrigin(),
		nil,
		keys.Radius,
		ability:GetAbilityTargetTeam(),
		ability:GetAbilityTargetType(),
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)
	for _, v in pairs(targets) do
		v:AddNewModifier(caster, ability, "modifier_item_flower_umbrella_spellstart_buff",{ Duration = keys.Duration}):SetStackCount(v:GetStrength()*ability:GetSpecialValueFor("str_percent")/100)
        v:EmitSound("Hero_TemplarAssassin.Refraction")
    end
end

modifier_item_flower_umbrella_spellstart_buff = {}
LinkLuaModifier("modifier_item_flower_umbrella_spellstart_buff","scripts/vscripts/items/item_umbrella.lua",LUA_MODIFIER_MOTION_NONE)
function modifier_item_flower_umbrella_spellstart_buff:IsHidden() 		return false end     --是否隐藏
function modifier_item_flower_umbrella_spellstart_buff:IsPurgable()     return true end     --是否可净化
function modifier_item_flower_umbrella_spellstart_buff:RemoveOnDeath() 	return true  end     --死亡移除
function modifier_item_flower_umbrella_spellstart_buff:IsDebuff()	   	return false end     --是否是DEBUFF
function modifier_item_flower_umbrella_spellstart_buff:DeclareFunctions() return
	{
		MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK,
	}
end
function modifier_item_flower_umbrella_spellstart_buff:GetModifierPhysical_ConstantBlock(events)--被攻击时触发
	if IsClient() then return self:GetStackCount() end
	if events.damage <= self:GetStackCount() then return events.damage end
	return self:GetStackCount()
end

function modifier_item_flower_umbrella_spellstart_buff:OnCreated()
	if IsClient() then return end

	if self.refraction_particle then
		ParticleManager:DestroyParticle(self.refraction_particle, false)
		ParticleManager:ReleaseParticleIndex(self.refraction_particle)
	end

	self.refraction_particle = ParticleManager:CreateParticle("particles/thd2/items/item_flower_umbrella_shield.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControlEnt(self.refraction_particle, 1, self:GetParent(), PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
	self:AddParticle(self.refraction_particle, false, false, -1, true, false)
end
function modifier_item_flower_umbrella_spellstart_buff:OnDestroy()
	if IsClient() then return end
end