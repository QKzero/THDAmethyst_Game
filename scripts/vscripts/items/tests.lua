
function ItemTestCast(keys)
	if keys.caster:HasModifier(keys.ModifierName) then
		keys.caster:RemoveModifierByName(keys.ModifierName)
	else
		keys.ability:ApplyDataDrivenModifier(keys.caster, keys.caster, keys.ModifierName, {})
	end
end

function ItemTestOnAttack(keys)
	print('ItemTestOnAttack')
end

function ItemTestOnAttackLanded(keys)
	print('ItemTestOnAttackLanded')
end
