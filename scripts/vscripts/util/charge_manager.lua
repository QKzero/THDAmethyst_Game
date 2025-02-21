
ChargeManager = {
	["abilities"] = {},
}

AbilitiesSharedCharge = {
	["lunchbox"] = 0
}

function ChargeManager:InitCharges(hAbility, hUnit, sKey)
	if hAbility.InitedCharge then
		ChargeManager:SetCharges(hUnit, sKey, hAbility:GetCurrentCharges())
		return
	end
	local charges = ChargeManager:GetCharges(hUnit, sKey, hAbility)
	hAbility:SetCurrentCharges(charges)
end

function ChargeManager:SetCharges(hUnit, sKey, nCharge)
	local nPlayerID = hUnit:GetPlayerOwnerID()
	if hUnit:IsRealHero() and not hUnit:IsClone() and not hUnit:IsTempestDouble() and ChargeManager["abilities"][nPlayerID] == nil then
		ChargeManager["abilities"][nPlayerID] = {}
		for k, v in pairs(AbilitiesSharedCharge) do
			ChargeManager["abilities"][nPlayerID][k] = v
		end
	end

	ChargeManager["abilities"][nPlayerID][sKey] = nCharge
end

function ChargeManager:GetCharges(hUnit, sKey, hAbility)
	local nPlayerID = hUnit:GetPlayerOwnerID()
	if hUnit:IsRealHero() and not hUnit:IsClone() and not hUnit:IsTempestDouble() and ChargeManager["abilities"][nPlayerID] == nil then
		ChargeManager["abilities"][nPlayerID] = {}
		for k, v in pairs(AbilitiesSharedCharge) do
			ChargeManager["abilities"][nPlayerID][k] = v
		end
	end

	if hAbility and hAbility.InitedCharge == nil then hAbility.InitedCharge = true end
	return ChargeManager["abilities"][nPlayerID][sKey]
end

function ChargeManager:RemoveCharges(hUnit, sKey, tModifiers)
	local nPlayerID = hUnit:GetPlayerOwnerID()

	-- 没有modifier时重置Charges
	if tModifiers ~= nil then
		for i, modifier in pairs(tModifiers) do
			if hUnit:HasModifier(modifier) then return end
		end
	end

	ChargeManager:SetCharges(hUnit, sKey, 0)
end
