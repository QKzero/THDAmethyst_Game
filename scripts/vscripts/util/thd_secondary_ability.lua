
function SecondaryAbilityInit()
	CustomGameEventManager:RegisterListener("cast_secondary_ability", function (i, event) CastSecondaryAbility(event) end)
end

function CastSecondaryAbility(event)
	-- print("CastSecondaryAbility: ".."event = "..type(event))
	local ability = EntIndexToHScript(event.ability)
	local caster = EntIndexToHScript(event.caster)
	local player = event.playerid

	if ability:GetAbilityName() == "plus_high_five" then
		-- print("caster:CastAbilityNoTarget(ability, player)")
		caster:CastAbilityNoTarget(ability, player)
	end
end

SecondaryAbilityInit()
