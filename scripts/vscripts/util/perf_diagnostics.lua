if PerfDiagnostics == nil then
    PerfDiagnostics = {}
end

PerfDiagnostics.AUTO_INTERVAL = 300.0
PerfDiagnostics.AUTO_ENABLED = false
PerfDiagnostics.INITIAL_DELAY = 10.0
PerfDiagnostics.THINK_NAME = "thd_perf_diagnostics_auto"
PerfDiagnostics.enabled = true
PerfDiagnostics.started = false
PerfDiagnostics.SEARCH_RADIUS = 99999
PerfDiagnostics.ENTITY_CLASS_TOP_LIMIT = 12
PerfDiagnostics.ENTITY_INSPECT_LIMIT = 5
PerfDiagnostics.BOT_PRESSURE_SAMPLE_LIMIT = 5
PerfDiagnostics.DETAIL_ENTITY_CLASS_TOP_LIMIT = 25
PerfDiagnostics.DETAIL_ENTITY_INSPECT_LIMIT = 20
PerfDiagnostics.DETAIL_BOT_PRESSURE_SAMPLE_LIMIT = 24
PerfDiagnostics.history = PerfDiagnostics.history or {}
PerfDiagnostics.seenNeutralEnts = PerfDiagnostics.seenNeutralEnts or {}
PerfDiagnostics.neutralBirthSampleLimit = 8
PerfDiagnostics.inspectClassnames = {
    "item_lua",
    "item_datadriven",
    "ability_lua",
    "ability_datadriven",
    "npc_dota_base_additive",
    "twin_gate_portal_warp",
    "neutral_upgrade",
    "npc_dota_creep_neutral",
    "frogmen_riverborn_aura",
    "frogmen_arm_of_the_deep",
    "npc_dota_thinker",
    "dota_item_drop",
}

local function CountTable(t)
    local count = 0
    if t == nil then return count end
    for _, _ in pairs(t) do
        count = count + 1
    end
    return count
end

local function BuildTopMapText(map, limit)
    if map == nil then return "none" end

    local entries = {}
    for key, value in pairs(map) do
        table.insert(entries, { key = tostring(key), value = tonumber(value) or 0 })
    end
    table.sort(entries, function(a, b)
        if a.value == b.value then return a.key < b.key end
        return a.value > b.value
    end)

    local parts = {}
    local maxCount = math.min(limit or #entries, #entries)
    for i = 1, maxCount do
        table.insert(parts, entries[i].key .. "=" .. tostring(entries[i].value))
    end

    if #parts == 0 then return "none" end
    return table.concat(parts, ",")
end

local function CountUniqueBotBuffEntries()
    local unique = {}
    local count = 0
    if G_Bot_Buff_List == nil then return 0 end

    for _, ability in pairs(G_Bot_Buff_List) do
        local key = nil
        pcall(function()
            if ability ~= nil and not (ability.IsNull ~= nil and ability:IsNull()) then
                local name = ability.GetAbilityName ~= nil and ability:GetAbilityName() or tostring(ability)
                local owner = ability.GetOwner ~= nil and ability:GetOwner() or nil
                local playerId = -1
                if owner ~= nil and owner.GetPlayerOwnerID ~= nil then
                    playerId = owner:GetPlayerOwnerID()
                end
                key = tostring(playerId) .. ':' .. tostring(name)
            end
        end)

        if key ~= nil and unique[key] ~= true then
            unique[key] = true
            count = count + 1
        end
    end

    return count
end

local function PerfPrint(message)
    print(message)
end

local function SafeFindEntitiesByClassname(classname)
    local ok, result = pcall(function()
        return Entities:FindAllByClassname(classname)
    end)
    if ok and result ~= nil then
        return result
    end
    return {}
end

local function CountEntitiesByClassname(classname)
    return #SafeFindEntitiesByClassname(classname)
end

local function SafeCall(defaultValue, fn)
    local ok, result = pcall(fn)
    if ok and result ~= nil then return result end
    return defaultValue
end

local function VectorToText(v)
    if v == nil then return "nil" end
    return string.format("%.0f,%.0f,%.0f", v.x or 0, v.y or 0, v.z or 0)
end

local function GetEntityName(entity)
    return SafeCall("<noname>", function()
        local name = entity:GetName()
        if name == nil or name == "" then
            name = entity:GetUnitName()
        end
        return name
    end)
end

local function GetVisibleObserverForTeam(team)
    for _, hero in pairs(SafeFindEntitiesByClassname("npc_dota_hero*")) do
        if hero ~= nil and SafeCall(false, function() return not hero:IsNull() end) then
            local heroTeam = SafeCall(nil, function()
                if hero.GetTeamNumber == nil then return nil end
                return hero:GetTeamNumber()
            end)
            if heroTeam == team and hero.CanEntityBeSeenByMyTeam ~= nil then
                return hero
            end
        end
    end
    return nil
end

local function CanEntityBeSeenByTeam(entity, team)
    local observer = GetVisibleObserverForTeam(team)
    if observer == nil or observer.CanEntityBeSeenByMyTeam == nil then return false end
    return SafeCall(false, function() return observer:CanEntityBeSeenByMyTeam(entity) end) == true
end

local function GetEntityOwnerName(entity)
    return SafeCall("nil", function()
        local owner = entity:GetOwner()
        if owner == nil or owner:IsNull() then return "nil" end
        return GetEntityName(owner)
    end)
end

local function GetEntityPlayerOwnerId(entity)
    return SafeCall(-1, function()
        if entity.GetPlayerOwnerID ~= nil then
            return entity:GetPlayerOwnerID()
        end
        local owner = entity:GetOwner()
        if owner ~= nil and not owner:IsNull() and owner.GetPlayerOwnerID ~= nil then
            return owner:GetPlayerOwnerID()
        end
        return -1
    end)
end

local function GetEntityHullRadius(entity)
    return SafeCall(-1, function()
        if entity.GetHullRadius == nil then return -1 end
        return entity:GetHullRadius()
    end)
end

local function GetEntityMoveCapability(entity)
    return SafeCall(-1, function()
        if entity.GetMoveCapability == nil then return -1 end
        return entity:GetMoveCapability()
    end)
end

local function GetEntityAbsOriginText(entity)
    return VectorToText(SafeCall(nil, function() return entity:GetAbsOrigin() end))
end

local function GetEntityAbsOriginVector(entity)
    return SafeCall(nil, function()
        if entity == nil or entity.GetAbsOrigin == nil then return nil end
        return entity:GetAbsOrigin()
    end)
end

local function GetNearestNeutralSpawnerInfo(origin)
    if origin == nil then
        return "nil", -1
    end

    local nearestName = "nil"
    local nearestDistance = -1
    for _, spawner in pairs(SafeFindEntitiesByClassname("npc_dota_neutral_spawner")) do
        if spawner ~= nil and not spawner:IsNull() then
            local spawnerOrigin = GetEntityAbsOriginVector(spawner)
            if spawnerOrigin ~= nil then
                local distance = (origin - spawnerOrigin):Length2D()
                if nearestDistance < 0 or distance < nearestDistance then
                    nearestDistance = distance
                    nearestName = GetEntityName(spawner)
                end
            end
        end
    end

    return nearestName, nearestDistance
end

local function GetEntityModifierNames(entity)
    local names = {}
    if entity == nil or entity:IsNull() then return names end
    local ok, modifiers = pcall(function()
        return entity:FindAllModifiers()
    end)
    if ok and modifiers ~= nil then
        for _, modifier in pairs(modifiers) do
            if modifier ~= nil and not modifier:IsNull() then
                local name = SafeCall("<unknown>", function() return modifier:GetName() end)
                if name == nil or name == "" then name = "<unknown>" end
                table.insert(names, name)
            end
        end
    else
        local count = SafeCall(0, function()
            if entity.GetModifierCount == nil then return 0 end
            return entity:GetModifierCount()
        end)
        for i = 0, count - 1 do
            local name = SafeCall("<unknown>", function()
                return entity:GetModifierNameByIndex(i)
            end)
            if name ~= nil and name ~= "" then
                table.insert(names, name)
            end
        end
    end
    table.sort(names)
    return names
end

local function GetEntityAbilityNames(entity)
    local names = {}
    if entity == nil or entity:IsNull() or entity.GetAbilityCount == nil or entity.GetAbilityByIndex == nil then return names end

    local count = SafeCall(0, function() return entity:GetAbilityCount() end)
    for i = 0, count - 1 do
        local abilityName = SafeCall(nil, function()
            local ability = entity:GetAbilityByIndex(i)
            if ability == nil or ability:IsNull() then return nil end
            if ability.GetAbilityName ~= nil then return ability:GetAbilityName() end
            if ability.GetName ~= nil then return ability:GetName() end
            return nil
        end)
        if abilityName ~= nil and abilityName ~= "" then
            table.insert(names, abilityName)
        end
    end

    table.sort(names)
    return names
end

local function BuildEntitySamples(classname, limit)
    local entities = SafeFindEntitiesByClassname(classname)
    local samples = {}
    local maxCount = math.min(limit or PerfDiagnostics.ENTITY_INSPECT_LIMIT, #entities)

    for i = 1, maxCount do
        local entity = entities[i]
        if entity ~= nil and not entity:IsNull() then
            local modifierNames = nil
            local abilityNames = nil
            if classname == "npc_dota_thinker" or classname == "npc_dota_creep_neutral" then
                modifierNames = GetEntityModifierNames(entity)
            end
            if classname == "npc_dota_creep_neutral" then
                abilityNames = GetEntityAbilityNames(entity)
            end
            table.insert(samples, {
                classname = classname,
                entindex = SafeCall(-1, function() return entity:entindex() end),
                name = GetEntityName(entity),
                owner = GetEntityOwnerName(entity),
                playerOwnerId = GetEntityPlayerOwnerId(entity),
                hullRadius = GetEntityHullRadius(entity),
                moveCapability = GetEntityMoveCapability(entity),
                origin = GetEntityAbsOriginText(entity),
                alive = SafeCall("na", function()
                    if entity.IsAlive == nil then return "na" end
                    return tostring(entity:IsAlive())
                end),
                team = SafeCall(-1, function()
                    if entity.GetTeamNumber == nil then return -1 end
                    return entity:GetTeamNumber()
                end),
                modifierNames = modifierNames,
                abilityNames = abilityNames,
            })
        end
    end

    return {
        classname = classname,
        total = #entities,
        samples = samples,
    }
end

local function BuildEntityInspections()
    local inspections = {}
    for _, classname in ipairs(PerfDiagnostics.inspectClassnames) do
        table.insert(inspections, BuildEntitySamples(classname, PerfDiagnostics.ENTITY_INSPECT_LIMIT))
    end
    return inspections
end

local function BuildNativeNeutralSamples()
    local result = {}
    local classnames = {
        "neutral_upgrade",
        "npc_dota_creep_neutral",
        "frogmen_riverborn_aura",
        "frogmen_arm_of_the_deep",
    }

    for _, classname in ipairs(classnames) do
        local sample = BuildEntitySamples(classname, 2)
        if sample ~= nil and sample.samples ~= nil and #sample.samples > 0 then
            table.insert(result, sample)
        end
    end

    return result
end

local function BuildThinkerStats(limit)
    local thinkers = SafeFindEntitiesByClassname("npc_dota_thinker")
    local byModifier = {}
    local byOwner = {}

    for _, thinker in pairs(thinkers) do
        if thinker ~= nil and not thinker:IsNull() then
            local ownerName = GetEntityOwnerName(thinker)
            byOwner[ownerName] = (byOwner[ownerName] or 0) + 1

            local modifierNames = GetEntityModifierNames(thinker)
            if #modifierNames == 0 then
                byModifier["<none>"] = (byModifier["<none>"] or 0) + 1
            else
                for _, modifierName in ipairs(modifierNames) do
                    byModifier[modifierName] = (byModifier[modifierName] or 0) + 1
                end
            end
        end
    end

    return {
        total = #thinkers,
        byModifier = BuildTopMapText(byModifier, limit or 10),
        byOwner = BuildTopMapText(byOwner, limit or 10),
    }
end

local function BuildNeutralEntityState(limit)
    local neutrals = SafeFindEntitiesByClassname("npc_dota_creep_neutral")
    local stats = {
        total = #neutrals,
        alive = 0,
        dead = 0,
        zeroHealth = 0,
        nullOrInvalid = 0,
        neutralUnitType = 0,
        notNeutralUnitType = 0,
        attackCapable = 0,
        noAttack = 0,
        byTeam = {},
        byName = {},
        byAbility = {},
        byModifier = {},
    }

    for _, neutral in pairs(neutrals) do
        if neutral == nil or neutral:IsNull() then
            stats.nullOrInvalid = stats.nullOrInvalid + 1
        else
            local alive = SafeCall(false, function()
                if neutral.IsAlive == nil then return false end
                return neutral:IsAlive()
            end)
            if alive then stats.alive = stats.alive + 1 else stats.dead = stats.dead + 1 end

            local health = SafeCall(nil, function()
                if neutral.GetHealth == nil then return nil end
                return neutral:GetHealth()
            end)
            if health ~= nil and health <= 0 then stats.zeroHealth = stats.zeroHealth + 1 end

            local neutralType = SafeCall(false, function()
                if neutral.IsNeutralUnitType == nil then return false end
                return neutral:IsNeutralUnitType()
            end)
            if neutralType then stats.neutralUnitType = stats.neutralUnitType + 1 else stats.notNeutralUnitType = stats.notNeutralUnitType + 1 end

            local attackCapability = SafeCall(0, function()
                if neutral.GetAttackCapability == nil then return 0 end
                return neutral:GetAttackCapability()
            end)
            if attackCapability ~= nil and attackCapability ~= 0 then stats.attackCapable = stats.attackCapable + 1 else stats.noAttack = stats.noAttack + 1 end

            local team = SafeCall(-1, function()
                if neutral.GetTeamNumber == nil then return -1 end
                return neutral:GetTeamNumber()
            end)
            stats.byTeam[tostring(team)] = (stats.byTeam[tostring(team)] or 0) + 1

            local unitName = SafeCall("<unknown>", function()
                if neutral.GetUnitName == nil then return "<unknown>" end
                return neutral:GetUnitName()
            end)
            if unitName == nil or unitName == "" then unitName = "<unknown>" end
            stats.byName[unitName] = (stats.byName[unitName] or 0) + 1

            local abilityNames = GetEntityAbilityNames(neutral)
            if #abilityNames == 0 then
                stats.byAbility["<none>"] = (stats.byAbility["<none>"] or 0) + 1
            else
                for _, abilityName in ipairs(abilityNames) do
                    stats.byAbility[abilityName] = (stats.byAbility[abilityName] or 0) + 1
                end
            end

            local modifierNames = GetEntityModifierNames(neutral)
            if #modifierNames == 0 then
                stats.byModifier["<none>"] = (stats.byModifier["<none>"] or 0) + 1
            else
                for _, modifierName in ipairs(modifierNames) do
                    stats.byModifier[modifierName] = (stats.byModifier[modifierName] or 0) + 1
                end
            end
        end
    end

    local topLimit = limit or 8
    return {
        total = stats.total,
        alive = stats.alive,
        dead = stats.dead,
        zeroHealth = stats.zeroHealth,
        nullOrInvalid = stats.nullOrInvalid,
        neutralUnitType = stats.neutralUnitType,
        notNeutralUnitType = stats.notNeutralUnitType,
        attackCapable = stats.attackCapable,
        noAttack = stats.noAttack,
        byTeam = BuildTopMapText(stats.byTeam, topLimit),
        byName = BuildTopMapText(stats.byName, topLimit),
        byAbility = BuildTopMapText(stats.byAbility, topLimit),
        byModifier = BuildTopMapText(stats.byModifier, topLimit),
    }
end

local function BuildNeutralBirthStats(limit)
    local neutrals = SafeFindEntitiesByClassname("npc_dota_creep_neutral")
    local seen = PerfDiagnostics.seenNeutralEnts or {}
    local current = {}
    local newSamples = {}
    local byName = {}
    local byAbility = {}
    local byModifier = {}
    local newCount = 0
    local removedCount = 0
    local sampleLimit = limit or PerfDiagnostics.neutralBirthSampleLimit or 8

    for _, neutral in pairs(neutrals) do
        if neutral ~= nil and not neutral:IsNull() then
            local entindex = SafeCall(-1, function() return neutral:entindex() end)
            if entindex ~= nil and entindex >= 0 then
                current[entindex] = true
                if seen[entindex] ~= true then
                    newCount = newCount + 1
                    local unitName = SafeCall("<unknown>", function()
                        if neutral.GetUnitName == nil then return "<unknown>" end
                        return neutral:GetUnitName()
                    end)
                    if unitName == nil or unitName == "" then unitName = "<unknown>" end
                    byName[unitName] = (byName[unitName] or 0) + 1

                    local abilityNames = GetEntityAbilityNames(neutral)
                    if #abilityNames == 0 then
                        byAbility["<none>"] = (byAbility["<none>"] or 0) + 1
                    else
                        for _, abilityName in ipairs(abilityNames) do
                            byAbility[abilityName] = (byAbility[abilityName] or 0) + 1
                        end
                    end

                    local modifierNames = GetEntityModifierNames(neutral)
                    if #modifierNames == 0 then
                        byModifier["<none>"] = (byModifier["<none>"] or 0) + 1
                    else
                        for _, modifierName in ipairs(modifierNames) do
                            byModifier[modifierName] = (byModifier[modifierName] or 0) + 1
                        end
                    end

                    if #newSamples < sampleLimit then
                        local origin = GetEntityAbsOriginVector(neutral)
                        local spawnerName, spawnerDistance = GetNearestNeutralSpawnerInfo(origin)
                        table.insert(newSamples, {
                            entindex = entindex,
                            name = unitName,
                            origin = VectorToText(origin),
                            team = SafeCall(-1, function()
                                if neutral.GetTeamNumber == nil then return -1 end
                                return neutral:GetTeamNumber()
                            end),
                            alive = SafeCall("na", function()
                                if neutral.IsAlive == nil then return "na" end
                                return tostring(neutral:IsAlive())
                            end),
                            nearestSpawner = spawnerName,
                            nearestSpawnerDist = spawnerDistance,
                            abilities = table.concat(abilityNames, ","),
                            modifiers = table.concat(modifierNames, ","),
                        })
                    end
                end
            end
        end
    end

    for entindex, _ in pairs(seen) do
        if current[entindex] ~= true then
            removedCount = removedCount + 1
        end
    end
    PerfDiagnostics.seenNeutralEnts = current

    return {
        total = #neutrals,
        newCount = newCount,
        removedCount = removedCount,
        seenCount = CountTable(current),
        byName = BuildTopMapText(byName, sampleLimit),
        byAbility = BuildTopMapText(byAbility, sampleLimit),
        byModifier = BuildTopMapText(byModifier, sampleLimit),
        samples = newSamples,
    }
end

local function TryUnitBool(unit, methodName)
    if unit == nil or unit[methodName] == nil then return "na" end
    local ok, result = pcall(function() return unit[methodName](unit) end)
    if not ok or result == nil then return "err" end
    return result == true and "true" or "false"
end

local function BuildNeutralVisibilityStats(limit)
    local neutrals = SafeFindEntitiesByClassname("npc_dota_creep_neutral")
    local stats = {
        total = 0,
        alive = 0,
        dead = 0,
        visibleRadiant = 0,
        visibleDire = 0,
        visibleBoth = 0,
        visibleNone = 0,
        invulnerable = 0,
        outOfGame = 0,
        attackImmune = 0,
        magicImmune = 0,
        commandRestricted = 0,
        rooted = 0,
        stunned = 0,
        hiddenLike = 0,
        samples = {},
        byNameHidden = {},
        byNameVisible = {},
    }
    local sampleLimit = limit or 8

    for _, neutral in pairs(neutrals) do
        if neutral ~= nil and not neutral:IsNull() then
            stats.total = stats.total + 1
            local alive = SafeCall(false, function() return neutral.IsAlive ~= nil and neutral:IsAlive() end) == true
            if alive then stats.alive = stats.alive + 1 else stats.dead = stats.dead + 1 end

            local unitName = SafeCall("<unknown>", function()
                if neutral.GetUnitName == nil then return "<unknown>" end
                return neutral:GetUnitName()
            end)
            if unitName == nil or unitName == "" then unitName = "<unknown>" end

            local visibleRadiant = CanEntityBeSeenByTeam(neutral, DOTA_TEAM_GOODGUYS)
            local visibleDire = CanEntityBeSeenByTeam(neutral, DOTA_TEAM_BADGUYS)
            if visibleRadiant then stats.visibleRadiant = stats.visibleRadiant + 1 end
            if visibleDire then stats.visibleDire = stats.visibleDire + 1 end
            if visibleRadiant and visibleDire then
                stats.visibleBoth = stats.visibleBoth + 1
            elseif not visibleRadiant and not visibleDire then
                stats.visibleNone = stats.visibleNone + 1
                stats.byNameHidden[unitName] = (stats.byNameHidden[unitName] or 0) + 1
            else
                stats.byNameVisible[unitName] = (stats.byNameVisible[unitName] or 0) + 1
            end

            local invulnerable = SafeCall(false, function() return neutral.IsInvulnerable ~= nil and neutral:IsInvulnerable() end) == true
            local outOfGame = SafeCall(false, function() return neutral.IsOutOfGame ~= nil and neutral:IsOutOfGame() end) == true
            local attackImmune = SafeCall(false, function() return neutral.IsAttackImmune ~= nil and neutral:IsAttackImmune() end) == true
            local magicImmune = SafeCall(false, function() return neutral.IsMagicImmune ~= nil and neutral:IsMagicImmune() end) == true
            local commandRestricted = SafeCall(false, function() return neutral.IsCommandRestricted ~= nil and neutral:IsCommandRestricted() end) == true
            local rooted = SafeCall(false, function() return neutral.IsRooted ~= nil and neutral:IsRooted() end) == true
            local stunned = SafeCall(false, function() return neutral.IsStunned ~= nil and neutral:IsStunned() end) == true
            if invulnerable then stats.invulnerable = stats.invulnerable + 1 end
            if outOfGame then stats.outOfGame = stats.outOfGame + 1 end
            if attackImmune then stats.attackImmune = stats.attackImmune + 1 end
            if magicImmune then stats.magicImmune = stats.magicImmune + 1 end
            if commandRestricted then stats.commandRestricted = stats.commandRestricted + 1 end
            if rooted then stats.rooted = stats.rooted + 1 end
            if stunned then stats.stunned = stats.stunned + 1 end

            local hiddenLike = alive and (not visibleRadiant) and (not visibleDire)
            if hiddenLike then stats.hiddenLike = stats.hiddenLike + 1 end
            if hiddenLike and #stats.samples < sampleLimit then
                table.insert(stats.samples, {
                    entindex = SafeCall(-1, function() return neutral:entindex() end),
                    name = unitName,
                    origin = VectorToText(GetEntityAbsOriginVector(neutral)),
                    team = SafeCall(-1, function() return neutral.GetTeamNumber ~= nil and neutral:GetTeamNumber() or -1 end),
                    alive = tostring(alive),
                    radiant = tostring(visibleRadiant),
                    dire = tostring(visibleDire),
                    invulnerable = tostring(invulnerable),
                    outOfGame = tostring(outOfGame),
                    attackImmune = tostring(attackImmune),
                    magicImmune = tostring(magicImmune),
                    commandRestricted = tostring(commandRestricted),
                    abilities = table.concat(GetEntityAbilityNames(neutral), ","),
                    modifiers = table.concat(GetEntityModifierNames(neutral), ","),
                })
            end
        end
    end

    return {
        total = stats.total,
        alive = stats.alive,
        dead = stats.dead,
        visibleRadiant = stats.visibleRadiant,
        visibleDire = stats.visibleDire,
        visibleBoth = stats.visibleBoth,
        visibleNone = stats.visibleNone,
        invulnerable = stats.invulnerable,
        outOfGame = stats.outOfGame,
        attackImmune = stats.attackImmune,
        magicImmune = stats.magicImmune,
        commandRestricted = stats.commandRestricted,
        rooted = stats.rooted,
        stunned = stats.stunned,
        hiddenLike = stats.hiddenLike,
        byNameHidden = BuildTopMapText(stats.byNameHidden, sampleLimit),
        byNameVisible = BuildTopMapText(stats.byNameVisible, sampleLimit),
        samples = stats.samples,
    }
end

local function BuildEntityClassStats(limit)
    local entities = SafeFindEntitiesByClassname("*")
    local counts = {}
    local result = {}

    for _, entity in pairs(entities) do
        if entity ~= nil and not entity:IsNull() then
            local classname = SafeCall("<unknown>", function() return entity:GetClassname() end)
            if classname == nil or classname == "" then classname = "<unknown>" end
            counts[classname] = (counts[classname] or 0) + 1
        end
    end

    for classname, count in pairs(counts) do
        table.insert(result, {
            classname = classname,
            count = count,
        })
    end

    table.sort(result, function(a, b)
        if a.count == b.count then
            return a.classname < b.classname
        end
        return a.count > b.count
    end)

    local top = {}
    local maxCount = math.min(limit or PerfDiagnostics.ENTITY_CLASS_TOP_LIMIT, #result)
    for i = 1, maxCount do
        table.insert(top, result[i])
    end

    return top
end

local function CountTimers()
    if Timers == nil or Timers.timers == nil then return 0 end
    return CountTable(Timers.timers)
end

local function SafeFindAllUnits()
    local ok, result = pcall(function()
        return FindUnitsInRadius(
            DOTA_TEAM_GOODGUYS,
            Vector(0, 0, 0),
            nil,
            PerfDiagnostics.SEARCH_RADIUS,
            DOTA_UNIT_TARGET_TEAM_BOTH,
            DOTA_UNIT_TARGET_ALL,
            DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD,
            FIND_ANY_ORDER,
            false
        )
    end)
    if ok and result ~= nil then
        return result
    end
    return {}
end

local function BuildLaneCreepState(limit)
    local creeps = SafeFindEntitiesByClassname("npc_dota_creep_lane")
    local stats = {
        total = 0,
        alive = 0,
        attacking = 0,
        nearEnemy = 0,
        marching = 0,
        spawnLike = 0,
        noAcquire = 0,
        acqZero = 0,
        acqLow = 0,
        acqHigh = 0,
        byName = {},
        byAttackTarget = {},
        samples = {},
    }
    local sampleLimit = limit or 8

    for _, creep in pairs(creeps) do
        if creep ~= nil and not creep:IsNull() then
            stats.total = stats.total + 1
            local alive = SafeCall(false, function() return creep.IsAlive ~= nil and creep:IsAlive() end)
            local name = GetEntityName(creep)
            stats.byName[name] = (stats.byName[name] or 0) + 1
            if alive then
                stats.alive = stats.alive + 1
                local attackTarget = SafeCall(nil, function()
                    if creep.GetAttackTarget == nil then return nil end
                    return creep:GetAttackTarget()
                end)
                local attackTargetName = attackTarget ~= nil and GetEntityName(attackTarget) or "<none>"
                stats.byAttackTarget[attackTargetName] = (stats.byAttackTarget[attackTargetName] or 0) + 1
                if attackTarget ~= nil then stats.attacking = stats.attacking + 1 end

                local team = SafeCall(-1, function()
                    if creep.GetTeamNumber == nil then return -1 end
                    return creep:GetTeamNumber()
                end)
                local enemies = SafeCall({}, function()
                    if creep.GetAbsOrigin == nil then return {} end
                    return FindUnitsInRadius(
                        team,
                        creep:GetAbsOrigin(),
                        nil,
                        900,
                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_BUILDING,
                        DOTA_UNIT_TARGET_FLAG_NONE,
                        FIND_ANY_ORDER,
                        false
                    )
                end)
                local enemyCount = enemies ~= nil and #enemies or 0
                if enemyCount > 0 then stats.nearEnemy = stats.nearEnemy + 1 end
                if attackTarget == nil and enemyCount == 0 then stats.marching = stats.marching + 1 end
                if attackTarget == nil and enemyCount == 0 and stats.alive <= 12 then stats.spawnLike = stats.spawnLike + 1 end

                local acq = SafeCall(-1, function()
                    if creep.GetAcquisitionRange == nil then return -1 end
                    return creep:GetAcquisitionRange()
                end)
                if acq == 0 then stats.acqZero = stats.acqZero + 1 end
                if acq > 0 and acq <= 500 then stats.acqLow = stats.acqLow + 1 end
                if acq > 500 then stats.acqHigh = stats.acqHigh + 1 end
                if acq <= 0 then stats.noAcquire = stats.noAcquire + 1 end

                if #stats.samples < sampleLimit then
                    table.insert(stats.samples, {
                        entindex = SafeCall(-1, function() return creep:entindex() end),
                        name = name,
                        team = team,
                        origin = GetEntityAbsOriginText(creep),
                        attackTarget = attackTargetName,
                        nearbyEnemies = enemyCount,
                        acquisitionRange = acq,
                        modifiers = table.concat(GetEntityModifierNames(creep), ","),
                        abilities = table.concat(GetEntityAbilityNames(creep), ","),
                    })
                end
            end
        end
    end
    return stats
end

local function BuildUnitStats()
    local stats = {
        all = 0,
        heroes = 0,
        realHeroes = 0,
        illusions = 0,
        creeps = 0,
        laneCreeps = 0,
        neutralCreeps = 0,
        buildings = 0,
        couriers = 0,
        summons = 0,
        controllableNonHeroes = 0,
        botOwnedUnits = 0,
        aliveBotOwnedUnits = 0,
        other = 0,
        teamGood = 0,
        teamBad = 0,
        teamNeutral = 0,
    }

    local units = SafeFindAllUnits()
    stats.all = #units

    for _, unit in pairs(units) do
        if unit ~= nil and not unit:IsNull() then
            local team = SafeCall(-1, function()
                if unit.GetTeamNumber == nil then return -1 end
                return unit:GetTeamNumber()
            end)
            if team == DOTA_TEAM_GOODGUYS then
                stats.teamGood = stats.teamGood + 1
            elseif team == DOTA_TEAM_BADGUYS then
                stats.teamBad = stats.teamBad + 1
            elseif team == DOTA_TEAM_NEUTRALS then
                stats.teamNeutral = stats.teamNeutral + 1
            end

            local isHero = SafeCall(false, function()
                return unit.IsHero ~= nil and unit:IsHero()
            end)
            local isRealHero = SafeCall(false, function()
                return unit.IsRealHero ~= nil and unit:IsRealHero()
            end)
            local isBuilding = SafeCall(false, function()
                return unit.IsBuilding ~= nil and unit:IsBuilding()
            end)
            local isCourier = SafeCall(false, function()
                return unit.IsCourier ~= nil and unit:IsCourier()
            end)
            local isCreep = SafeCall(false, function()
                return unit.IsCreep ~= nil and unit:IsCreep()
            end)
            local isNeutral = SafeCall(false, function()
                return unit.IsNeutralUnitType ~= nil and unit:IsNeutralUnitType()
            end)
            local unitName = SafeCall("", function()
                if unit.GetUnitName == nil then return "" end
                return unit:GetUnitName()
            end)

            local playerOwnerId = GetEntityPlayerOwnerId(unit)
            if playerOwnerId >= 0 and not isHero then
                stats.controllableNonHeroes = stats.controllableNonHeroes + 1
            end
            local owner = SafeCall(nil, function()
                if unit.GetOwner == nil then return nil end
                return unit:GetOwner()
            end)
            local ownerIsHero = SafeCall(false, function()
                return owner ~= nil and not owner:IsNull() and owner.IsHero ~= nil and owner:IsHero()
            end)
            if ownerIsHero then
                local ownerPlayerId = GetEntityPlayerOwnerId(owner)
                if ownerPlayerId >= 0 and PlayerResource:IsValidPlayerID(ownerPlayerId) then
                    stats.botOwnedUnits = stats.botOwnedUnits + 1
                    if SafeCall(false, function() return unit.IsAlive ~= nil and unit:IsAlive() end) then
                        stats.aliveBotOwnedUnits = stats.aliveBotOwnedUnits + 1
                    end
                end
            end

            if isHero then
                stats.heroes = stats.heroes + 1
                if isRealHero then
                    stats.realHeroes = stats.realHeroes + 1
                else
                    stats.illusions = stats.illusions + 1
                end
            elseif isBuilding then
                stats.buildings = stats.buildings + 1
            elseif isCourier then
                stats.couriers = stats.couriers + 1
            elseif isCreep then
                stats.creeps = stats.creeps + 1
                if isNeutral then
                    stats.neutralCreeps = stats.neutralCreeps + 1
                elseif string.find(unitName, "creep") ~= nil then
                    stats.laneCreeps = stats.laneCreeps + 1
                else
                    stats.summons = stats.summons + 1
                end
            else
                stats.other = stats.other + 1
            end
        end
    end

    return stats
end

local function BuildNearbyPressure(unit, units, radius)
    local result = {
        radius = radius or 1600,
        allies = 0,
        enemies = 0,
        enemyHeroes = 0,
        enemyCreeps = 0,
    }
    if unit == nil or unit:IsNull() then return result end

    local origin = SafeCall(nil, function()
        if unit.GetAbsOrigin == nil then return nil end
        return unit:GetAbsOrigin()
    end)
    local team = SafeCall(-1, function()
        if unit.GetTeamNumber == nil then return -1 end
        return unit:GetTeamNumber()
    end)
    if origin == nil or team < 0 then return result end

    local radiusValue = result.radius
    for _, other in pairs(units or {}) do
        if other ~= nil and not other:IsNull() and other ~= unit then
            local otherOrigin = SafeCall(nil, function()
                if other.GetAbsOrigin == nil then return nil end
                return other:GetAbsOrigin()
            end)
            if otherOrigin ~= nil and (otherOrigin - origin):Length2D() <= radiusValue then
                local otherTeam = SafeCall(-1, function()
                    if other.GetTeamNumber == nil then return -1 end
                    return other:GetTeamNumber()
                end)
                if otherTeam == team then
                    result.allies = result.allies + 1
                elseif otherTeam > 0 then
                    result.enemies = result.enemies + 1
                    if SafeCall(false, function() return other.IsHero ~= nil and other:IsHero() end) then
                        result.enemyHeroes = result.enemyHeroes + 1
                    elseif SafeCall(false, function() return other.IsCreep ~= nil and other:IsCreep() end) then
                        result.enemyCreeps = result.enemyCreeps + 1
                    end
                end
            end
        end
    end

    return result
end

local function GetUnitAttackTargetName(unit)
    return SafeCall("nil", function()
        if unit.GetAttackTarget == nil then return "nil" end
        local target = unit:GetAttackTarget()
        if target == nil or target:IsNull() then return "nil" end
        return GetEntityName(target)
    end)
end

local function GetUnitCurrentAbilityName(unit)
    return SafeCall("nil", function()
        if unit.GetCurrentActiveAbility == nil then return "nil" end
        local ability = unit:GetCurrentActiveAbility()
        if ability == nil or ability:IsNull() then return "nil" end
        return ability:GetAbilityName()
    end)
end

local function BuildBotPressureStats()
    local stats = {
        controllableNonHeroes = 0,
        illusions = 0,
        summons = 0,
        botOwnedUnits = 0,
        aliveBotOwnedUnits = 0,
        samples = {},
        bots = {},
    }

    local sampleLimit = PerfDiagnostics.BOT_PRESSURE_SAMPLE_LIMIT or 24
    local units = SafeFindAllUnits()
    local ownerCounts = {}

    for _, unit in pairs(units) do
        if unit ~= nil and not unit:IsNull() then
            local isHero = SafeCall(false, function() return unit.IsHero ~= nil and unit:IsHero() end)
            local isIllusion = SafeCall(false, function() return unit.IsIllusion ~= nil and unit:IsIllusion() end)
            local isSummon = SafeCall(false, function()
                local explicitSummon = unit.IsSummoned ~= nil and unit:IsSummoned()
                local isCreep = unit.IsCreep ~= nil and unit:IsCreep()
                local isNeutral = unit.IsNeutralUnitType ~= nil and unit:IsNeutralUnitType()
                local unitName = unit.GetUnitName ~= nil and unit:GetUnitName() or ""
                local creepLikeSummon = isCreep and not isNeutral and string.find(unitName, "creep") == nil
                return explicitSummon or creepLikeSummon
            end)
            local playerOwnerId = GetEntityPlayerOwnerId(unit)
            local ownerName = GetEntityOwnerName(unit)
            local owner = SafeCall(nil, function()
                if unit.GetOwner == nil then return nil end
                return unit:GetOwner()
            end)
            local ownerPlayerId = -1
            if owner ~= nil and not owner:IsNull() then
                ownerPlayerId = GetEntityPlayerOwnerId(owner)
            end

            local botOwned = ownerPlayerId >= 0 and PlayerResource:IsValidPlayerID(ownerPlayerId)
            local suspicious = false

            if playerOwnerId >= 0 and not isHero then
                stats.controllableNonHeroes = stats.controllableNonHeroes + 1
                suspicious = true
            end
            if isIllusion then
                stats.illusions = stats.illusions + 1
                suspicious = true
            end
            if isSummon then
                stats.summons = stats.summons + 1
                suspicious = true
            end
            if botOwned then
                stats.botOwnedUnits = stats.botOwnedUnits + 1
                if SafeCall(false, function() return unit.IsAlive ~= nil and unit:IsAlive() end) then
                    stats.aliveBotOwnedUnits = stats.aliveBotOwnedUnits + 1
                end
                ownerCounts[ownerPlayerId] = (ownerCounts[ownerPlayerId] or 0) + 1
                suspicious = true
            end

            if suspicious and #stats.samples < sampleLimit then
                table.insert(stats.samples, {
                    entindex = SafeCall(-1, function()
                        if unit.entindex == nil then return -1 end
                        return unit:entindex()
                    end),
                    name = GetEntityName(unit),
                    owner = ownerName,
                    playerOwnerId = playerOwnerId,
                    ownerPlayerId = ownerPlayerId,
                    team = SafeCall(-1, function()
                        if unit.GetTeamNumber == nil then return -1 end
                        return unit:GetTeamNumber()
                    end),
                    alive = SafeCall("na", function()
                        if unit.IsAlive == nil then return "na" end
                        return tostring(unit:IsAlive())
                    end),
                    hero = tostring(isHero),
                    illusion = tostring(isIllusion),
                    summon = tostring(isSummon),
                    controllable = tostring(playerOwnerId >= 0 and not isHero),
                    hullRadius = GetEntityHullRadius(unit),
                    moveCapability = GetEntityMoveCapability(unit),
                    origin = GetEntityAbsOriginText(unit),
                    modifiers = SafeCall(0, function()
                        if unit.FindAllModifiers ~= nil then return #unit:FindAllModifiers() end
                        if unit.GetModifierCount ~= nil then return unit:GetModifierCount() end
                        return 0
                    end),
                })
            end
        end
    end

    for playerId, count in pairs(ownerCounts) do
        local hero = PlayerResource:GetSelectedHeroEntity(playerId)
        if hero ~= nil and not hero:IsNull() then
            local nearby = BuildNearbyPressure(hero, units, 1600)
            table.insert(stats.bots, {
                playerId = playerId,
                heroName = SafeCall("nil", function()
                    if hero.GetUnitName == nil then return "nil" end
                    return hero:GetUnitName()
                end),
                team = SafeCall(-1, function()
                    if hero.GetTeamNumber == nil then return -1 end
                    return hero:GetTeamNumber()
                end),
                alive = SafeCall("na", function()
                    if hero.IsAlive == nil then return "na" end
                    return tostring(hero:IsAlive())
                end),
                level = SafeCall(-1, function()
                    if hero.GetLevel == nil then return -1 end
                    return hero:GetLevel()
                end),
                ownedUnits = count,
                attackTarget = GetUnitAttackTargetName(hero),
                currentAbility = GetUnitCurrentAbilityName(hero),
                nearbyAllies = nearby.allies,
                nearbyEnemies = nearby.enemies,
                nearbyEnemyHeroes = nearby.enemyHeroes,
                nearbyEnemyCreeps = nearby.enemyCreeps,
                hullRadius = GetEntityHullRadius(hero),
                moveCapability = GetEntityMoveCapability(hero),
                modifiers = SafeCall(0, function()
                    if hero.FindAllModifiers ~= nil then return #hero:FindAllModifiers() end
                    if hero.GetModifierCount ~= nil then return hero:GetModifierCount() end
                    return 0
                end),
            })
        end
    end

    local maxPlayers = DOTA_MAX_TEAM_PLAYERS or 24
    for playerId = 0, maxPlayers - 1 do
        if ownerCounts[playerId] == nil and PlayerResource:IsValidPlayerID(playerId) then
            local hero = PlayerResource:GetSelectedHeroEntity(playerId)
            if hero ~= nil and not hero:IsNull() then
                local nearby = BuildNearbyPressure(hero, units, 1600)
                table.insert(stats.bots, {
                    playerId = playerId,
                    heroName = SafeCall("nil", function()
                        if hero.GetUnitName == nil then return "nil" end
                        return hero:GetUnitName()
                    end),
                    team = SafeCall(-1, function()
                        if hero.GetTeamNumber == nil then return -1 end
                        return hero:GetTeamNumber()
                    end),
                    alive = SafeCall("na", function()
                        if hero.IsAlive == nil then return "na" end
                        return tostring(hero:IsAlive())
                    end),
                    level = SafeCall(-1, function()
                        if hero.GetLevel == nil then return -1 end
                        return hero:GetLevel()
                    end),
                    ownedUnits = 0,
                    attackTarget = GetUnitAttackTargetName(hero),
                    currentAbility = GetUnitCurrentAbilityName(hero),
                    nearbyAllies = nearby.allies,
                    nearbyEnemies = nearby.enemies,
                    nearbyEnemyHeroes = nearby.enemyHeroes,
                    nearbyEnemyCreeps = nearby.enemyCreeps,
                    hullRadius = GetEntityHullRadius(hero),
                    moveCapability = GetEntityMoveCapability(hero),
                    modifiers = SafeCall(0, function()
                        if hero.FindAllModifiers ~= nil then return #hero:FindAllModifiers() end
                        if hero.GetModifierCount ~= nil then return hero:GetModifierCount() end
                        return 0
                    end),
                })
            end
        end
    end

    table.sort(stats.bots, function(a, b)
        if a.ownedUnits == b.ownedUnits then return a.playerId < b.playerId end
        return a.ownedUnits > b.ownedUnits
    end)

    return stats
end

local function SafeFindAllModifiers(hero)
    if hero == nil or hero:IsNull() then return {} end
    local ok, modifiers = pcall(function()
        return hero:FindAllModifiers()
    end)
    if ok and modifiers ~= nil then
        return modifiers
    end
    return {}
end

local function GetHeroModifierNames(hero)
    local names = {}
    local modifiers = SafeFindAllModifiers(hero)
    for _, modifier in pairs(modifiers) do
        local name = "<unknown>"
        if modifier ~= nil and not modifier:IsNull() then
            name = SafeCall("<unknown>", function() return modifier:GetName() end)
            if name == nil or name == "" then name = "<unknown>" end
        end
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

local function GetHeroModifierCount(hero)
    local modifiers = SafeFindAllModifiers(hero)
    if modifiers ~= nil and #modifiers > 0 then
        return #modifiers
    end

    local okCount, count = pcall(function()
        return hero:GetModifierCount()
    end)
    if okCount and count ~= nil then
        return count
    end

    return 0
end

local function GetGameTimeText()
    local seconds = 0
    local ok, dotaTime = pcall(function()
        return GameRules:GetDOTATime(false, false)
    end)
    if ok and dotaTime ~= nil then
        seconds = math.floor(dotaTime)
    end
    if seconds < 0 then seconds = 0 end
    local minutes = math.floor(seconds / 60)
    local remaining = seconds % 60
    return string.format("%02d:%02d", minutes, remaining)
end

function PerfDiagnostics:BuildSnapshot(reason)
    local snapshot = {}
    snapshot.reason = reason or "auto"
    snapshot.time = GetGameTimeText()

    snapshot.entities = {
        total = CountEntitiesByClassname("*"),
        thinkers = CountEntitiesByClassname("npc_dota_thinker"),
        infoTargets = CountEntitiesByClassname("info_target"),
        itemDrops = CountEntitiesByClassname("dota_item_drop"),
        itemRunes = CountEntitiesByClassname("dota_item_rune"),
        couriers = CountEntitiesByClassname("npc_dota_courier"),
        projectiles = CountEntitiesByClassname("dota_base_projectile"),
    }

    local detail = reason == "detail" or reason == "console_detail" or reason == "manual_detail" or reason == "dump_detail"
    local oldEntityLimit = self.ENTITY_INSPECT_LIMIT
    local oldBotSampleLimit = self.BOT_PRESSURE_SAMPLE_LIMIT
    local oldClassTopLimit = self.ENTITY_CLASS_TOP_LIMIT
    if detail then
        self.ENTITY_INSPECT_LIMIT = self.DETAIL_ENTITY_INSPECT_LIMIT
        self.BOT_PRESSURE_SAMPLE_LIMIT = self.DETAIL_BOT_PRESSURE_SAMPLE_LIMIT
        self.ENTITY_CLASS_TOP_LIMIT = self.DETAIL_ENTITY_CLASS_TOP_LIMIT
    end

    snapshot.entityClassTop = BuildEntityClassStats(self.ENTITY_CLASS_TOP_LIMIT)
    snapshot.entityInspections = detail and BuildEntityInspections() or nil
    snapshot.nativeNeutralSamples = BuildNativeNeutralSamples()
    snapshot.thinkerStats = BuildThinkerStats(detail and 15 or 8)
    snapshot.neutralEntityState = BuildNeutralEntityState(detail and 15 or 8)
    snapshot.neutralBirthStats = BuildNeutralBirthStats(detail and 15 or 8)
    snapshot.neutralVisibilityStats = BuildNeutralVisibilityStats(detail and 15 or 8)
    snapshot.laneCreepState = BuildLaneCreepState(detail and 15 or 8)
    snapshot.units = BuildUnitStats()
    snapshot.botPressure = BuildBotPressureStats()

    self.ENTITY_INSPECT_LIMIT = oldEntityLimit
    self.BOT_PRESSURE_SAMPLE_LIMIT = oldBotSampleLimit
    self.ENTITY_CLASS_TOP_LIMIT = oldClassTopLimit

    snapshot.timers = {
        count = CountTimers(),
    }

    local goodBotCount = 0
    local badBotCount = 0
    if botTable ~= nil then
        goodBotCount = CountTable(botTable[DOTA_TEAM_GOODGUYS])
        badBotCount = CountTable(botTable[DOTA_TEAM_BADGUYS])
    end

    snapshot.tables = {
        registeredCustomEventListeners = CountTable(registeredCustomEventListeners),
        goodBots = goodBotCount,
        badBots = badBotCount,
        gBotList = CountTable(G_Bot_List),
        gBotBuffList = CountTable(G_Bot_Buff_List),
        gBotBuffUnique = CountUniqueBotBuffEntries(),
    }

    snapshot.heroModifiers = {}
    snapshot.maxHeroModifiers = 0
    snapshot.heroCombat = {
        count = 0,
        botCount = 0,
        totalAttackRange = 0,
        maxAttackRange = 0,
        totalAttackSpeed = 0,
        maxAttackSpeed = 0,
        totalVision = 0,
        maxVision = 0,
    }
    local maxPlayers = DOTA_MAX_TEAM_PLAYERS or 24
    for playerId = 0, maxPlayers - 1 do
        if PlayerResource:IsValidPlayerID(playerId) then
            local hero = PlayerResource:GetSelectedHeroEntity(playerId)
            if hero ~= nil and not hero:IsNull() then
                local modifierCount = GetHeroModifierCount(hero)
                snapshot.maxHeroModifiers = math.max(snapshot.maxHeroModifiers, modifierCount)

                local attackRange = SafeCall(0, function()
                    if hero.Script_GetAttackRange ~= nil then return hero:Script_GetAttackRange() end
                    if hero.GetAttackRange ~= nil then return hero:GetAttackRange() end
                    return 0
                end)
                local attackSpeed = SafeCall(0, function()
                    if hero.GetAttacksPerSecond ~= nil then return hero:GetAttacksPerSecond() end
                    if hero.GetAttackSpeed ~= nil then return hero:GetAttackSpeed() end
                    return 0
                end)
                local vision = SafeCall(0, function()
                    if hero.GetCurrentVisionRange ~= nil then return hero:GetCurrentVisionRange() end
                    if hero.GetDayTimeVisionRange ~= nil then return hero:GetDayTimeVisionRange() end
                    return 0
                end)
                local isBotHero = SafeCall(false, function()
                    local pid = hero:GetPlayerOwnerID()
                    return pid >= 0 and PlayerResource:IsValidPlayerID(pid) and PlayerResource:IsFakeClient(pid)
                end)

                snapshot.heroCombat.count = snapshot.heroCombat.count + 1
                snapshot.heroCombat.totalAttackRange = snapshot.heroCombat.totalAttackRange + attackRange
                snapshot.heroCombat.maxAttackRange = math.max(snapshot.heroCombat.maxAttackRange, attackRange)
                snapshot.heroCombat.totalAttackSpeed = snapshot.heroCombat.totalAttackSpeed + attackSpeed
                snapshot.heroCombat.maxAttackSpeed = math.max(snapshot.heroCombat.maxAttackSpeed, attackSpeed)
                snapshot.heroCombat.totalVision = snapshot.heroCombat.totalVision + vision
                snapshot.heroCombat.maxVision = math.max(snapshot.heroCombat.maxVision, vision)
                if isBotHero then
                    snapshot.heroCombat.botCount = snapshot.heroCombat.botCount + 1
                end

                table.insert(snapshot.heroModifiers, {
                    playerId = playerId,
                    heroName = SafeCall("nil", function()
                        if hero.GetUnitName == nil then return "nil" end
                        return hero:GetUnitName()
                    end),
                    team = SafeCall(-1, function()
                        if hero.GetTeamNumber == nil then return -1 end
                        return hero:GetTeamNumber()
                    end),
                    modifiers = modifierCount,
                    modifierNames = GetHeroModifierNames(hero),
                    alive = SafeCall("na", function()
                        if hero.IsAlive == nil then return "na" end
                        return tostring(hero:IsAlive())
                    end),
                    attackRange = attackRange,
                    attackSpeed = attackSpeed,
                    vision = vision,
                    isBot = tostring(isBotHero),
                })
            end
        end
    end

    return snapshot
end

function PerfDiagnostics:StoreSnapshot(snapshot)
    table.insert(self.history, snapshot)
end

local function PrintEntityClassTop(entityClassTop)
    if entityClassTop == nil or #entityClassTop == 0 then return end
    PerfPrint("[PERF][EntityClassesTop] begin")
    for i, entry in ipairs(entityClassTop) do
        PerfPrint(string.format(
            "[PERF][EntityClass] rank=%d class=%s count=%d",
            i,
            tostring(entry.classname),
            entry.count
        ))
    end
    PerfPrint("[PERF][EntityClassesTop] end")
end

local function PrintEntityInspections(entityInspections)
    if entityInspections == nil or #entityInspections == 0 then return end
    PerfPrint("[PERF][EntityInspect] begin")
    for _, group in ipairs(entityInspections) do
        PerfPrint(string.format(
            "[PERF][EntityInspectClass] class=%s total=%d samples=%d",
            tostring(group.classname),
            group.total or 0,
            group.samples ~= nil and #group.samples or 0
        ))
        if group.samples ~= nil then
            for i, sample in ipairs(group.samples) do
                PerfPrint(string.format(
                    "[PERF][EntityInspectItem] class=%s index=%d ent=%s name=%s owner=%s playerOwner=%s team=%s alive=%s hull=%s moveCap=%s origin=%s",
                    tostring(group.classname),
                    i,
                    tostring(sample.entindex),
                    tostring(sample.name),
                    tostring(sample.owner),
                    tostring(sample.playerOwnerId),
                    tostring(sample.team),
                    tostring(sample.alive),
                    tostring(sample.hullRadius),
                    tostring(sample.moveCapability),
                    tostring(sample.origin)
                ))
                if sample.abilityNames ~= nil then
                    PerfPrint(string.format(
                        "[PERF][EntityInspectAbilities] class=%s index=%d ent=%s count=%d names=%s",
                        tostring(group.classname),
                        i,
                        tostring(sample.entindex),
                        #sample.abilityNames,
                        table.concat(sample.abilityNames, ",")
                    ))
                end
                if sample.modifierNames ~= nil then
                    PerfPrint(string.format(
                        "[PERF][EntityInspectMods] class=%s index=%d ent=%s count=%d begin",
                        tostring(group.classname),
                        i,
                        tostring(sample.entindex),
                        #sample.modifierNames
                    ))
                    for modIndex, modifierName in ipairs(sample.modifierNames) do
                        PerfPrint(string.format(
                            "[PERF][EntityInspectMod] class=%s index=%d ent=%s modIndex=%d name=%s",
                            tostring(group.classname),
                            i,
                            tostring(sample.entindex),
                            modIndex,
                            tostring(modifierName)
                        ))
                    end
                    PerfPrint(string.format(
                        "[PERF][EntityInspectMods] class=%s index=%d ent=%s end",
                        tostring(group.classname),
                        i,
                        tostring(sample.entindex)
                    ))
                end
            end
        end
    end
    PerfPrint("[PERF][EntityInspect] end")
end

local function PrintNativeNeutralSamples(snapshot)
    if snapshot == nil or snapshot.nativeNeutralSamples == nil or #snapshot.nativeNeutralSamples == 0 then return end

    for _, group in ipairs(snapshot.nativeNeutralSamples) do
        PerfPrint(string.format(
            "[PERF][NativeNeutralSample] class=%s total=%d samples=%d",
            tostring(group.classname),
            group.total or 0,
            group.samples ~= nil and #group.samples or 0
        ))
        if group.samples ~= nil then
            for i, sample in ipairs(group.samples) do
                PerfPrint(string.format(
                    "[PERF][NativeNeutralSampleItem] class=%s index=%d ent=%s name=%s owner=%s team=%s alive=%s hull=%s moveCap=%s origin=%s",
                    tostring(group.classname),
                    i,
                    tostring(sample.entindex),
                    tostring(sample.name),
                    tostring(sample.owner),
                    tostring(sample.team),
                    tostring(sample.alive),
                    tostring(sample.hullRadius),
                    tostring(sample.moveCapability),
                    tostring(sample.origin)
                ))
                if sample.abilityNames ~= nil then
                    PerfPrint(string.format(
                        "[PERF][NativeNeutralAbilities] class=%s index=%d ent=%s count=%d names=%s",
                        tostring(group.classname),
                        i,
                        tostring(sample.entindex),
                        #sample.abilityNames,
                        table.concat(sample.abilityNames, ",")
                    ))
                end
                if sample.modifierNames ~= nil then
                    PerfPrint(string.format(
                        "[PERF][NativeNeutralMods] class=%s index=%d ent=%s count=%d names=%s",
                        tostring(group.classname),
                        i,
                        tostring(sample.entindex),
                        #sample.modifierNames,
                        table.concat(sample.modifierNames, ",")
                    ))
                end
            end
        end
    end
end

local function PrintBotPressure(botPressure, detail)
    if botPressure == nil then return end
    PerfPrint(string.format(
        "[PERF][BotPressure] controllableNonHeroes=%d illusions=%d summons=%d botOwned=%d aliveBotOwned=%d samples=%d bots=%d",
        botPressure.controllableNonHeroes or 0,
        botPressure.illusions or 0,
        botPressure.summons or 0,
        botPressure.botOwnedUnits or 0,
        botPressure.aliveBotOwnedUnits or 0,
        botPressure.samples ~= nil and #botPressure.samples or 0,
        botPressure.bots ~= nil and #botPressure.bots or 0
    ))

    if detail and botPressure.bots ~= nil then
        for i, botInfo in ipairs(botPressure.bots) do
            PerfPrint(string.format(
                "[PERF][BotPressureOwner] rank=%d pid=%d hero=%s team=%s alive=%s level=%s ownedUnits=%d target=%s ability=%s nearAllies=%s nearEnemies=%s nearEnemyHeroes=%s nearEnemyCreeps=%s hull=%s moveCap=%s modifiers=%s",
                i,
                botInfo.playerId,
                tostring(botInfo.heroName),
                tostring(botInfo.team),
                tostring(botInfo.alive),
                tostring(botInfo.level),
                botInfo.ownedUnits or 0,
                tostring(botInfo.attackTarget),
                tostring(botInfo.currentAbility),
                tostring(botInfo.nearbyAllies),
                tostring(botInfo.nearbyEnemies),
                tostring(botInfo.nearbyEnemyHeroes),
                tostring(botInfo.nearbyEnemyCreeps),
                tostring(botInfo.hullRadius),
                tostring(botInfo.moveCapability),
                tostring(botInfo.modifiers)
            ))
        end
    end

    if detail and botPressure.samples ~= nil then
        for i, sample in ipairs(botPressure.samples) do
            PerfPrint(string.format(
                "[PERF][BotPressureSample] index=%d ent=%s name=%s owner=%s playerOwner=%s ownerPlayer=%s team=%s alive=%s hero=%s illusion=%s summon=%s controllable=%s hull=%s moveCap=%s modifiers=%s origin=%s",
                i,
                tostring(sample.entindex),
                tostring(sample.name),
                tostring(sample.owner),
                tostring(sample.playerOwnerId),
                tostring(sample.ownerPlayerId),
                tostring(sample.team),
                tostring(sample.alive),
                tostring(sample.hero),
                tostring(sample.illusion),
                tostring(sample.summon),
                tostring(sample.controllable),
                tostring(sample.hullRadius),
                tostring(sample.moveCapability),
                tostring(sample.modifiers),
                tostring(sample.origin)
            ))
        end
    end
end

local function PrintHeroModifierNames(heroInfo)
    if heroInfo.modifierNames == nil then return end
    PerfPrint(string.format(
        "[PERF][HeroMods] pid=%d hero=%s count=%d begin",
        heroInfo.playerId,
        heroInfo.heroName,
        heroInfo.modifiers
    ))
    for i, modifierName in ipairs(heroInfo.modifierNames) do
        PerfPrint(string.format(
            "[PERF][HeroMod] pid=%d hero=%s index=%d name=%s",
            heroInfo.playerId,
            heroInfo.heroName,
            i,
            tostring(modifierName)
        ))
    end
    PerfPrint(string.format(
        "[PERF][HeroMods] pid=%d hero=%s end",
        heroInfo.playerId,
        heroInfo.heroName
    ))
end

function PerfDiagnostics:PrintSnapshotData(snapshot, detail)
    local s = snapshot
    local summary = string.format(
        "[PERF] %s t=%s ent=%d thinkers=%d units=%d heroes=%d creeps=%d timers=%d drops=%d maxMods=%d botOwned=%d ctrlNonHero=%d botThinking=%s",
        s.reason,
        s.time,
        s.entities.total,
        s.entities.thinkers,
        s.units.all,
        s.units.realHeroes,
        s.units.creeps,
        s.timers.count,
        s.entities.itemDrops,
        s.maxHeroModifiers,
        s.botPressure ~= nil and s.botPressure.botOwnedUnits or 0,
        s.botPressure ~= nil and s.botPressure.controllableNonHeroes or 0,
        tostring(THD2_GetBotThinking ~= nil and THD2_GetBotThinking() or "na")
    )

    PerfPrint(summary)
    PerfPrint(string.format(
        "[PERF][Entities] total=%d thinkers=%d info_target=%d item_drop=%d rune=%d courierEnt=%d projectiles=%d",
        s.entities.total,
        s.entities.thinkers,
        s.entities.infoTargets,
        s.entities.itemDrops,
        s.entities.itemRunes,
        s.entities.couriers,
        s.entities.projectiles
    ))
    if s.thinkerStats ~= nil then
        PerfPrint(string.format(
            "[PERF][Thinkers] total=%d byModifier=%s byOwner=%s",
            s.thinkerStats.total or 0,
            tostring(s.thinkerStats.byModifier or "none"),
            tostring(s.thinkerStats.byOwner or "none")
        ))
    end
    if s.neutralEntityState ~= nil then
        PerfPrint(string.format(
            "[PERF][NeutralEntityState] total=%d alive=%d dead=%d zeroHealth=%d null=%d neutralType=%d nonNeutralType=%d attackCapable=%d noAttack=%d byTeam=%s byName=%s byAbility=%s byModifier=%s",
            s.neutralEntityState.total or 0,
            s.neutralEntityState.alive or 0,
            s.neutralEntityState.dead or 0,
            s.neutralEntityState.zeroHealth or 0,
            s.neutralEntityState.nullOrInvalid or 0,
            s.neutralEntityState.neutralUnitType or 0,
            s.neutralEntityState.notNeutralUnitType or 0,
            s.neutralEntityState.attackCapable or 0,
            s.neutralEntityState.noAttack or 0,
            tostring(s.neutralEntityState.byTeam or "none"),
            tostring(s.neutralEntityState.byName or "none"),
            tostring(s.neutralEntityState.byAbility or "none"),
            tostring(s.neutralEntityState.byModifier or "none")
        ))
    end
    if s.neutralBirthStats ~= nil then
        PerfPrint(string.format(
            "[PERF][NeutralBirth] total=%d seen=%d new=%d removed=%d byName=%s byAbility=%s byModifier=%s",
            s.neutralBirthStats.total or 0,
            s.neutralBirthStats.seenCount or 0,
            s.neutralBirthStats.newCount or 0,
            s.neutralBirthStats.removedCount or 0,
            tostring(s.neutralBirthStats.byName or "none"),
            tostring(s.neutralBirthStats.byAbility or "none"),
            tostring(s.neutralBirthStats.byModifier or "none")
        ))
        if s.neutralBirthStats.samples ~= nil then
            for i, sample in ipairs(s.neutralBirthStats.samples) do
                PerfPrint(string.format(
                    "[PERF][NeutralBirthItem] index=%d ent=%s name=%s team=%s alive=%s origin=%s nearestSpawner=%s nearestSpawnerDist=%.1f abilities=%s modifiers=%s",
                    i,
                    tostring(sample.entindex),
                    tostring(sample.name),
                    tostring(sample.team),
                    tostring(sample.alive),
                    tostring(sample.origin),
                    tostring(sample.nearestSpawner),
                    sample.nearestSpawnerDist or -1,
                    tostring(sample.abilities),
                    tostring(sample.modifiers)
                ))
            end
        end
    end
    if s.neutralVisibilityStats ~= nil then
        PerfPrint(string.format(
            "[PERF][NeutralVisibility] total=%d alive=%d dead=%d visibleRadiant=%d visibleDire=%d visibleBoth=%d visibleNone=%d hiddenLike=%d invulnerable=%d outOfGame=%d attackImmune=%d magicImmune=%d commandRestricted=%d rooted=%d stunned=%d byNameHidden=%s byNameVisible=%s",
            s.neutralVisibilityStats.total or 0,
            s.neutralVisibilityStats.alive or 0,
            s.neutralVisibilityStats.dead or 0,
            s.neutralVisibilityStats.visibleRadiant or 0,
            s.neutralVisibilityStats.visibleDire or 0,
            s.neutralVisibilityStats.visibleBoth or 0,
            s.neutralVisibilityStats.visibleNone or 0,
            s.neutralVisibilityStats.hiddenLike or 0,
            s.neutralVisibilityStats.invulnerable or 0,
            s.neutralVisibilityStats.outOfGame or 0,
            s.neutralVisibilityStats.attackImmune or 0,
            s.neutralVisibilityStats.magicImmune or 0,
            s.neutralVisibilityStats.commandRestricted or 0,
            s.neutralVisibilityStats.rooted or 0,
            s.neutralVisibilityStats.stunned or 0,
            tostring(s.neutralVisibilityStats.byNameHidden or "none"),
            tostring(s.neutralVisibilityStats.byNameVisible or "none")
        ))
        if s.neutralVisibilityStats.samples ~= nil then
            for i, sample in ipairs(s.neutralVisibilityStats.samples) do
                PerfPrint(string.format(
                    "[PERF][NeutralVisibilityItem] index=%d ent=%s name=%s team=%s alive=%s origin=%s radiant=%s dire=%s invulnerable=%s outOfGame=%s attackImmune=%s magicImmune=%s commandRestricted=%s abilities=%s modifiers=%s",
                    i,
                    tostring(sample.entindex),
                    tostring(sample.name),
                    tostring(sample.team),
                    tostring(sample.alive),
                    tostring(sample.origin),
                    tostring(sample.radiant),
                    tostring(sample.dire),
                    tostring(sample.invulnerable),
                    tostring(sample.outOfGame),
                    tostring(sample.attackImmune),
                    tostring(sample.magicImmune),
                    tostring(sample.commandRestricted),
                    tostring(sample.abilities),
                    tostring(sample.modifiers)
                ))
            end
        end
    end
    PerfPrint(string.format(
        "[PERF][Units] all=%d heroes=%d realHeroes=%d illusions=%d creeps=%d laneCreeps=%d neutral=%d summons=%d buildings=%d couriers=%d other=%d controllableNonHeroes=%d botOwned=%d aliveBotOwned=%d",
        s.units.all,
        s.units.heroes,
        s.units.realHeroes,
        s.units.illusions,
        s.units.creeps,
        s.units.laneCreeps,
        s.units.neutralCreeps,
        s.units.summons,
        s.units.buildings,
        s.units.couriers,
        s.units.other,
        s.units.controllableNonHeroes or 0,
        s.units.botOwnedUnits or 0,
        s.units.aliveBotOwnedUnits or 0
    ))
    if s.laneCreepState ~= nil then
        local lane = s.laneCreepState
        PerfPrint(string.format(
            "[PERF][LaneCreepState] total=%d alive=%d attacking=%d nearEnemy=%d marching=%d spawnLike=%d noAcquire=%d acqZero=%d acqLow=%d acqHigh=%d byName=%s byAttackTarget=%s",
            lane.total or 0,
            lane.alive or 0,
            lane.attacking or 0,
            lane.nearEnemy or 0,
            lane.marching or 0,
            lane.spawnLike or 0,
            lane.noAcquire or 0,
            lane.acqZero or 0,
            lane.acqLow or 0,
            lane.acqHigh or 0,
            BuildTopMapText(lane.byName, 5),
            BuildTopMapText(lane.byAttackTarget, 5)
        ))
        if detail and lane.samples ~= nil then
            for index, sample in ipairs(lane.samples) do
                PerfPrint(string.format(
                    "[PERF][LaneCreepItem] index=%d ent=%s name=%s team=%s origin=%s attackTarget=%s nearbyEnemies=%d acquisitionRange=%s abilities=%s modifiers=%s",
                    index,
                    tostring(sample.entindex),
                    tostring(sample.name),
                    tostring(sample.team),
                    tostring(sample.origin),
                    tostring(sample.attackTarget),
                    sample.nearbyEnemies or 0,
                    tostring(sample.acquisitionRange),
                    tostring(sample.abilities),
                    tostring(sample.modifiers)
                ))
            end
        end
    end
    if detail then
        PerfPrint(string.format(
            "[PERF][Teams] good=%d bad=%d neutral=%d",
            s.units.teamGood,
            s.units.teamBad,
            s.units.teamNeutral
        ))
        PerfPrint(string.format(
            "[PERF][Tables] timers=%d listeners=%d goodBots=%d badBots=%d G_Bot_List=%d G_Bot_Buff_List=%d uniqueBotBuffs=%d",
            s.timers.count,
            s.tables.registeredCustomEventListeners,
            s.tables.goodBots,
            s.tables.badBots,
            s.tables.gBotList,
            s.tables.gBotBuffList,
            s.tables.gBotBuffUnique or 0
        ))

        if s.heroCombat ~= nil and s.heroCombat.count > 0 then
            PerfPrint(string.format(
                "[PERF][HeroCombat] heroes=%d bots=%d avgRange=%.1f maxRange=%.1f avgAS=%.3f maxAS=%.3f avgVision=%.1f maxVision=%.1f",
                s.heroCombat.count,
                s.heroCombat.botCount or 0,
                s.heroCombat.totalAttackRange / s.heroCombat.count,
                s.heroCombat.maxAttackRange,
                s.heroCombat.totalAttackSpeed / s.heroCombat.count,
                s.heroCombat.maxAttackSpeed,
                s.heroCombat.totalVision / s.heroCombat.count,
                s.heroCombat.maxVision
            ))
        end

        if THD_GetFOWViewerStats ~= nil then
            local fowStats = THD_GetFOWViewerStats()
            PerfPrint(string.format(
                "[PERF][FOWViewer] enabled=%s calls=%d blocked=%d maxRadius=%.1f maxDuration=%.2f",
                tostring(THD_FOW_VIEWER_ENABLED),
                fowStats.calls or 0,
                fowStats.blocked or 0,
                fowStats.maxRadius or 0,
                fowStats.maxDuration or 0
            ))
        end

        if THD_GetContextThinkStats ~= nil then
            local contextStats = THD_GetContextThinkStats()
            PerfPrint(string.format(
                "[PERF][ContextThink] enabled=%s calls=%d blocked=%d uniqueNameCalls=%d",
                tostring(THD_CONTEXT_THINK_ENABLED),
                contextStats.calls or 0,
                contextStats.blocked or 0,
                contextStats.uniqueNameCalls or 0
            ))
        end
    end

    if THD_GetNeutralSpawnerFixerStats ~= nil then
        local spawnerStats = THD_GetNeutralSpawnerFixerStats()
        PerfPrint(string.format(
            "[PERF][NeutralSpawnerFixer] enabled=%s ticks=%d disabledTicks=%d mappedSpawners=%d spawnersChecked=%d spawned=%d",
            tostring(spawnerStats.enabled),
            spawnerStats.ticks or 0,
            spawnerStats.disabledTicks or 0,
            spawnerStats.mappedSpawners or 0,
            spawnerStats.spawnersChecked or 0,
            spawnerStats.spawned or 0
        ))
    end
    if THD_GetNeutralAbilitySanitizerStats ~= nil then
        local neutralStats = THD_GetNeutralAbilitySanitizerStats()
        local byAbilityText = BuildTopMapText(neutralStats.byAbility, 4)
        PerfPrint(string.format(
            "[PERF][NeutralSanitizer] enabled=%s scans=%d neutralUnits=%d removed=%d byAbility=%s",
            tostring(THD_NEUTRAL_ABILITY_SANITIZER_ENABLED),
            neutralStats.scans or 0,
            neutralStats.neutralUnits or 0,
            neutralStats.removed or 0,
            byAbilityText
        ))
    end
    if THD_GetHiddenNeutralCleanupStats ~= nil then
        local cleanupStats = THD_GetHiddenNeutralCleanupStats()
        PerfPrint(string.format(
            "[PERF][HiddenNeutralCleanup] enabled=%s scans=%d grace=%.1f candidates=%d deferred=%d removed=%d byName=%s",
            tostring(THD_HIDDEN_NEUTRAL_CLEANUP_ENABLED),
            cleanupStats.scans or 0,
            THD_HIDDEN_NEUTRAL_CLEANUP_GRACE_SECONDS or 0,
            cleanupStats.candidates or 0,
            cleanupStats.deferred or 0,
            cleanupStats.removed or 0,
            BuildTopMapText(cleanupStats.byName, 6)
        ))
    end
    if THD_GetAllNeutralCleanupStats ~= nil then
        local allNeutralStats = THD_GetAllNeutralCleanupStats()
        PerfPrint(string.format(
            "[PERF][AllNeutralCleanup] enabled=%s scans=%d removed=%d byName=%s",
            tostring(THD_ALL_NEUTRAL_CLEANUP_ENABLED == true),
            allNeutralStats.scans or 0,
            allNeutralStats.removed or 0,
            BuildTopMapText(allNeutralStats.byName, 6)
        ))
    end
    if THD_GetCombatExperimentStats ~= nil then
        local combatStats = THD_GetCombatExperimentStats()
        local flags = THD_COMBAT_EXPERIMENT_FLAGS or {}
        PerfPrint(string.format(
            "[PERF][CombatExperiment] hiddenNoAttack=%s hiddenNoAcquire=%s hiddenStripAbilities=%s neutralStripAbilities=%s neutralRemoveModifiers=%s laneLowAcquire=%s laneStripAbilities=%s laneRemoveModifiers=%s scans=%d neutral=%d hidden=%d hiddenNoAttackApplied=%d hiddenNoAcquireApplied=%d hiddenStripped=%d neutralStripped=%d neutralModifiersRemoved=%d lane=%d laneLowAcquireApplied=%d laneStripped=%d laneModifiersRemoved=%d restored=%d",
            tostring(flags.hiddenNoAttack == true),
            tostring(flags.hiddenNoAcquire == true),
            tostring(flags.hiddenStripAbilities == true),
            tostring(flags.neutralStripAbilities == true),
            tostring(flags.neutralRemoveSelectedModifiers == true),
            tostring(flags.laneLowAcquire == true),
            tostring(flags.laneStripAbilities == true),
            tostring(flags.laneRemoveSelectedModifiers == true),
            combatStats.scans or 0,
            combatStats.neutral or 0,
            combatStats.hidden or 0,
            combatStats.hiddenNoAttack or 0,
            combatStats.hiddenNoAcquire or 0,
            combatStats.hiddenStripped or 0,
            combatStats.neutralStripped or 0,
            combatStats.neutralModifiersRemoved or 0,
            combatStats.lane or 0,
            combatStats.laneLowAcquire or 0,
            combatStats.laneStripped or 0,
            combatStats.laneModifiersRemoved or 0,
            combatStats.restored or 0
        ))
    end
    if THD_GetHeroExperimentStats ~= nil then
        local heroStats = THD_GetHeroExperimentStats()
        PerfPrint(string.format(
            "[PERF][HeroExperiment] attrValue=%s visionValue=%s attrApplied=%d visionApplied=%d restored=%d",
            tostring(heroStats.attrValue),
            tostring(heroStats.visionValue),
            heroStats.attrApplied or 0,
            heroStats.visionApplied or 0,
            heroStats.restored or 0
        ))
    end

    PrintEntityClassTop(s.entityClassTop)
    if detail then
        PrintEntityInspections(s.entityInspections)
        PrintBotPressure(s.botPressure, detail)
        PrintNativeNeutralSamples(s)
    end

    if detail then
        for _, heroInfo in ipairs(s.heroModifiers) do
            PerfPrint(string.format(
                "[PERF][Hero] pid=%d team=%d alive=%s hero=%s modifiers=%d",
                heroInfo.playerId,
                heroInfo.team,
                tostring(heroInfo.alive),
                heroInfo.heroName,
                heroInfo.modifiers
            ))
            PrintHeroModifierNames(heroInfo)
        end
    else
        for _, heroInfo in ipairs(s.heroModifiers) do
            if heroInfo.modifiers >= 25 then
                PerfPrint(string.format(
                    "[PERF][Hero] pid=%d team=%d alive=%s hero=%s modifiers=%d",
                    heroInfo.playerId,
                    heroInfo.team,
                    tostring(heroInfo.alive),
                    heroInfo.heroName,
                    heroInfo.modifiers
                ))
            end
        end
    end

    return summary
end

function PerfDiagnostics:PrintSnapshot(reason)
    local detail = reason == "detail" or reason == "console_detail" or reason == "manual_detail"
    local snapshot = self:BuildSnapshot(detail and "detail" or reason)
    self:StoreSnapshot(snapshot)
    local summary = self:PrintSnapshotData(snapshot, detail)
    GameRules:SendCustomMessage(summary, 0, 0)
end

function PerfDiagnostics:DumpHistory(detail)
    PerfPrint(string.format("[PERF][History] begin count=%d detail=%s", #self.history, tostring(detail == true)))
    for _, snapshot in ipairs(self.history) do
        self:PrintSnapshotData(snapshot, detail == true)
    end
    PerfPrint("[PERF][History] end")
    GameRules:SendCustomMessage(string.format("[PERF] dumped history snapshots=%d", #self.history), 0, 0)
end

function PerfDiagnostics:RegisterConsoleCommands()
    if self.consoleCommandsRegistered then return end
    self.consoleCommandsRegistered = true

    Convars:RegisterCommand("thd_perfdiag", function()
        local ok, err = pcall(function()
            PerfDiagnostics:PrintSnapshot("console")
        end)
        if not ok then
            local message = "[PERF] thd_perfdiag failed: " .. tostring(err)
            print(message)
            GameRules:SendCustomMessage(message, 0, 0)
        end
    end, "Print current THD performance diagnostics snapshot.", 0)

    Convars:RegisterCommand("thd_perfdetail", function()
        local ok, err = pcall(function()
            PerfDiagnostics:PrintSnapshot("console_detail")
        end)
        if not ok then
            local message = "[PERF] thd_perfdetail failed: " .. tostring(err)
            print(message)
            GameRules:SendCustomMessage(message, 0, 0)
        end
    end, "Print detailed THD performance diagnostics snapshot.", 0)

    Convars:RegisterCommand("thd_perfdumpdetail", function()
        local ok, err = pcall(function()
            PerfDiagnostics:DumpHistory(true)
        end)
        if not ok then
            local message = "[PERF] thd_perfdumpdetail failed: " .. tostring(err)
            print(message)
            GameRules:SendCustomMessage(message, 0, 0)
        end
    end, "Dump detailed THD performance diagnostics history.", 0)

    Convars:RegisterCommand("thd_perfdump", function()
        local ok, err = pcall(function()
            PerfDiagnostics:DumpHistory()
        end)
        if not ok then
            local message = "[PERF] thd_perfdump failed: " .. tostring(err)
            print(message)
            GameRules:SendCustomMessage(message, 0, 0)
        end
    end, "Dump stored THD performance diagnostics history.", 0)
end

function PerfDiagnostics:Start()
    if self.started then return end
    self.started = true
    self:RegisterConsoleCommands()

    if self.AUTO_ENABLED ~= true then
        PerfPrint("[PERF] automatic diagnostics disabled; use thd_perfdiag/thd_perfdetail manually")
        return
    end

    local startMessage = string.format("[PERF] diagnostics started interval=%.0fs initial=%.0fs", self.AUTO_INTERVAL, self.INITIAL_DELAY or self.AUTO_INTERVAL)
    PerfPrint(startMessage)

    GameRules:GetGameModeEntity():SetContextThink(self.THINK_NAME, function()
        if not self.enabled then return self.AUTO_INTERVAL end
        if GameRules:IsGamePaused() then return self.AUTO_INTERVAL end

        local ok, err = pcall(function()
            local snapshot = self:BuildSnapshot("auto")
            self:StoreSnapshot(snapshot)
            local summary = string.format(
                "[PERF] auto t=%s ent=%d thinkers=%d units=%d heroes=%d creeps=%d timers=%d drops=%d maxMods=%d botOwned=%d ctrlNonHero=%d botThinking=%s",
                snapshot.time,
                snapshot.entities.total,
                snapshot.entities.thinkers,
                snapshot.units.all,
                snapshot.units.realHeroes,
                snapshot.units.creeps,
                snapshot.timers.count,
                snapshot.entities.itemDrops,
                snapshot.maxHeroModifiers,
                snapshot.botPressure ~= nil and snapshot.botPressure.botOwnedUnits or 0,
                snapshot.botPressure ~= nil and snapshot.botPressure.controllableNonHeroes or 0,
                tostring(THD2_GetBotThinking ~= nil and THD2_GetBotThinking() or "na")
            )
            PerfPrint(summary)
            PrintEntityClassTop(snapshot.entityClassTop)
            GameRules:SendCustomMessage(summary, 0, 0)
        end)

        if not ok then
            local message = "[PERF] auto diagnostics failed: " .. tostring(err)
            PerfPrint(message)
            GameRules:SendCustomMessage(message, 0, 0)
        end

        return self.AUTO_INTERVAL
    end, self.INITIAL_DELAY or self.AUTO_INTERVAL)
end
