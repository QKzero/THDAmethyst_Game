function OnCishidaishoujiAttackLanded(keys)
	local caster = keys.caster
	local ability = keys.ability

	local mana_regen = ability:GetSpecialValueFor("mana_regen")
	caster:GiveMana(mana_regen)
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_ADD, caster, mana_regen, nil)

	if not caster:HasModifier("modifier_item_cishidaishouji_buff") then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_item_cishidaishouji_buff", {})
		caster:SetModifierStackCount("modifier_item_cishidaishouji_buff", caster, 1)
	else
		local modifier = caster:FindModifierByName("modifier_item_cishidaishouji_buff")
		modifier:SetDuration(modifier:GetDuration(), false)
		if modifier:GetStackCount() < ability:GetSpecialValueFor("max_count") then
			modifier:IncrementStackCount()
		end
		modifier:ForceRefresh()
	end
end