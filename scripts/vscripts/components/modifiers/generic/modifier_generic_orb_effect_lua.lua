-- Generic Orb Effect Library created by Elfansoer
-- See the reference at https://github.com/Elfansoer/dota-2-lua-abilities/blob/master/scripts/vscripts/lua_abilities/generic/modifier_generic_orb_effect_lua.lua

modifier_generic_orb_effect_lua = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_generic_orb_effect_lua:IsHidden()
	return true
end

function modifier_generic_orb_effect_lua:IsDebuff()
	return false
end

function modifier_generic_orb_effect_lua:IsPurgable()
	return false
end

function modifier_generic_orb_effect_lua:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_generic_orb_effect_lua:OnCreated( kv )
	-- generate data
	self.ability = self:GetAbility()
	self.records = {}
end

function modifier_generic_orb_effect_lua:OnRefresh( kv )
end

function modifier_generic_orb_effect_lua:OnDestroy( kv )

end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_generic_orb_effect_lua:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK,
		MODIFIER_EVENT_ON_ATTACK_FAIL,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY,

		MODIFIER_PROPERTY_PROJECTILE_NAME,
	}

	return funcs
end

function modifier_generic_orb_effect_lua:OnAttack( params )
	-- if not IsServer() then return end
	if params.attacker~=self:GetParent() then return end

	-- register attack if being cast and fully castable
	if self:ShouldLaunch( params.target ) then
		-- use mana and cd
		self.ability:UseResources( true, true, false, true )

		-- record the attack
		self.records[params.record] = true

		-- run OrbFire script if available
		if self.ability.OnOrbFire then self.ability:OnOrbFire( params ) end
	end

end
function modifier_generic_orb_effect_lua:OnAttackLanded( params )
	if self.records[params.record] then
		-- apply the effect
		if self.ability.OnOrbImpact then self.ability:OnOrbImpact( params ) end
	end
end
function modifier_generic_orb_effect_lua:OnAttackFail( params )
	if self.records[params.record] then
		-- apply the fail effect
		if self.ability.OnOrbFail then self.ability:OnOrbFail( params ) end
	end
end
function modifier_generic_orb_effect_lua:OnAttackRecordDestroy( params )
	-- destroy attack record
	self.records[params.record] = nil
end

function modifier_generic_orb_effect_lua:GetModifierProjectileName()
	if not self.ability.GetProjectileName then return end

	if self:ShouldLaunch(self:GetParent():GetAttackTarget()) then
		return self.ability:GetProjectileName()
	end
end

--------------------------------------------------------------------------------
-- Helper
function modifier_generic_orb_effect_lua:ShouldLaunch( target )
	-- check autocast
	local cast = false
	if self.ability:GetAutoCastState() or self:GetParent():GetCurrentActiveAbility() == self.ability then
		-- filter whether target is valid
		if self.ability.CastFilterResultTarget~=CDOTA_Ability_Lua.CastFilterResultTarget then
			-- check if ability has custom target cast filter
			if self.ability:CastFilterResultTarget( target )==UF_SUCCESS then
				cast = true
			end
		else
			local nResult = UnitFilter(
				target,
				self.ability:GetAbilityTargetTeam(),
				self.ability:GetAbilityTargetType(),
				self.ability:GetAbilityTargetFlags(),
				self:GetParent():GetTeamNumber()
			)
			if nResult == UF_SUCCESS then
				cast = true
			end
		end
	end

	if cast and self.ability:IsFullyCastable() then
		return true
	end

	return false
end

-- Graphics & Animations