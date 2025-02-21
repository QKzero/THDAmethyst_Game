
function UnitNoCollision( caster,target)
  FindClearSpaceForUnit(caster, target, false)
end


function UnitNoPathingfix( caster,target,duration)
  target:AddNewModifier(caster, nil, "modifier_spectre_spectral_dagger_path_phased", {duration=duration})
end