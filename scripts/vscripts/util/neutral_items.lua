if NeutralItems == nil
then
    NeutralItems = {}
end

local isTierOneDone   = false
local isTierTwoDone   = false
local isTierThreeDone = false
local isTierFourDone  = false
local isTierFiveDone  = false
local DOTA_ITEM_NEUTRAL_SLOT = 16

print("NeutralItems.lua loaded")

local Tier1NeutralItems = {
    "item_trusty_shovel",
    "item_occult_bracelet",
    "item_unstable_wand",
    "item_polliwog_charm",
    "item_spark_of_courage",
    "item_kobold_cup",
    "item_sisters_shroud",
}

local Tier2NeutralItems = {
    "item_essence_ring",
    "item_gossamer_cape",
    "item_searing_signet",
    "item_mana_draught",
    "item_misericorde",
    "item_pogo_stick",
}

local Tier3NeutralItems = {
    "item_serrated_shiv",
    "item_nemesis_curse",
    "item_gale_guard",
    "item_gunpowder_gauntlets",
    "item_whisper_of_the_dread",
    "item_jidi_pollen_bag",
    "item_psychic_headband",
}

local Tier4NeutralItems = {
    "item_crippling_crossbow",
    "item_magnifying_monocle",
    "item_ceremonial_robe",
    "item_giant_maul",
    "item_outworld_staff",
    "item_pyrrhic_cloak",
    "item_dezun_bloodrite",
}

local Tier5NeutralItems = {
    "item_desolator_2",
    "item_fallen_sky",
    "item_demonicon",
    "item_minotaur_horn",
    "item_spider_legs",
    "item_panic_button",
    "item_unrelenting_eye",
    "item_pirate_hat",
    "item_helm_of_the_undying",
}

local enhancements = {
    -- Tier 1 enhancements
    { name = "item_enhancement_mystical",  tier = 1, realName = "Mystical Enhancement" , level = 1},
    { name = "item_enhancement_brawny",    tier = 1, realName = "Brawny Enhancement" , level = 1},
    { name = "item_enhancement_alert",     tier = 1, realName = "Alert Enhancement" , level = 1},
    { name = "item_enhancement_tough",     tier = 1, realName = "Tough Enhancement" , level = 1},
    { name = "item_enhancement_quickened", tier = 1, realName = "Quickened Enhancement" , level = 1},

    -- Tier 2 enhancements
    { name = "item_enhancement_mystical",  tier = 2, realName = "Mystical Enhancement" , level = 2},
    { name = "item_enhancement_brawny",    tier = 2, realName = "Brawny Enhancement" , level = 2},
    { name = "item_enhancement_alert",     tier = 2, realName = "Alert Enhancement" , level = 2},
    { name = "item_enhancement_tough",     tier = 2, realName = "Tough Enhancement" , level = 2},
    { name = "item_enhancement_quickened", tier = 2, realName = "Quickened Enhancement" , level = 2},
    { name = "item_enhancement_keen_eyed", tier = 2, realName = "Keen Eyed Enhancement" , level = 1},
    { name = "item_enhancement_vast",      tier = 2, realName = "Vast Enhancement" , level = 1},
    { name = "item_enhancement_greedy",    tier = 2, realName = "Greedy Enhancement" , level = 1},
    { name = "item_enhancement_vampiric",  tier = 2, realName = "Vampiric Enhancement" , level = 1},

    -- Tier 3 enhancements
    { name = "item_enhancement_mystical",  tier = 3, realName = "Mystical Enhancement" , level = 3},
    { name = "item_enhancement_brawny",    tier = 3, realName = "Brawny Enhancement" , level = 3},
    { name = "item_enhancement_alert",     tier = 3, realName = "Alert Enhancement" , level = 3},
    { name = "item_enhancement_tough",     tier = 3, realName = "Tough Enhancement" , level = 3},
    { name = "item_enhancement_quickened", tier = 3, realName = "Quickened Enhancement" , level = 3},
    { name = "item_enhancement_keen_eyed", tier = 3, realName = "Keen Eyed Enhancement" , level = 2},
    { name = "item_enhancement_vast",      tier = 3, realName = "Vast Enhancement" , level = 2},
    { name = "item_enhancement_greedy",    tier = 3, realName = "Greedy Enhancement" , level = 2},
    { name = "item_enhancement_vampiric",  tier = 3, realName = "Vampiric Enhancement" , level = 2},

    -- Tier 4 enhancements
    { name = "item_enhancement_mystical",  tier = 4, realName = "Mystical Enhancement" , level = 4},
    { name = "item_enhancement_brawny",    tier = 4, realName = "Brawny Enhancement" , level = 4},
    { name = "item_enhancement_alert",     tier = 4, realName = "Alert Enhancement" , level = 4},
    { name = "item_enhancement_tough",     tier = 4, realName = "Tough Enhancement" , level = 4},
    { name = "item_enhancement_quickened", tier = 4, realName = "Quickened Enhancement" , level = 4},
    { name = "item_enhancement_vampiric",  tier = 4, realName = "Vampiric Enhancement" , level = 3},
    { name = "item_enhancement_timeless",  tier = 4, realName = "Timeless Enhancement" , level = 1},
    { name = "item_enhancement_titanic",   tier = 4, realName = "Titanic Enhancement" , level = 1},
    { name = "item_enhancement_crude",     tier = 4, realName = "Crude Enhancement" , level = 1},

    -- Tier 5 enhancements
    { name = "item_enhancement_timeless",  tier = 5, realName = "Timeless Enhancement" , level = 2},
    { name = "item_enhancement_titanic",   tier = 5, realName = "Titanic Enhancement" , level = 2},
    { name = "item_enhancement_crude",     tier = 5, realName = "Crude Enhancement" , level = 2},
    { name = "item_enhancement_feverish",  tier = 5, realName = "Feverish Enhancement" , level = 1},
    { name = "item_enhancement_fleetfooted", tier = 5, realName = "Fleetfooted Enhancement" , level = 1},
    { name = "item_enhancement_audacious", tier = 5, realName = "Audacious Enhancement" , level = 1},
    { name = "item_enhancement_evolved",   tier = 5, realName = "Evolved Enhancement" , level = 1},
    { name = "item_enhancement_boundless", tier = 5, realName = "Boundless Enhancement" , level = 1},
}

function NeutralItems:GetRandomEnhanByTier(tier)
    local filtered = {}
    for _, enh in ipairs(enhancements) do
        if enh.tier == tier then
            table.insert(filtered, enh)
        end
    end

    if #filtered == 0 then
        return nil  -- No enhancement found for this tier
    end

    -- Return a random enhancement from the filtered list.
    return filtered[RandomInt(1, #filtered)]
end


-- Just give out random for now.
-- Will work out a decent algorithm later to better assign suitable items.
function NeutralItems.GiveNeutralItems(TeamRadiant, TeamDire)

    -- Tier 1 Neutral Items
    if DotaTime() >= 3.5 * 60
    and not isTierOneDone
    then

        for _, h in pairs(TeamRadiant) do
            NeutralItems.GiveItem(Tier1NeutralItems[RandomInt(1, #Tier1NeutralItems)], h, isTierOneDone, 1)
        end

        for _, h in pairs(TeamDire) do
            NeutralItems.GiveItem(Tier1NeutralItems[RandomInt(1, #Tier1NeutralItems)], h, isTierOneDone, 1)
        end

        isTierOneDone = true
    end

    -- Tier 2 Neutral Items
    if DotaTime() >= 8.5 * 60
    and not isTierTwoDone
    then
        for _, h in pairs(TeamRadiant) do
            NeutralItems.GiveItem(Tier2NeutralItems[RandomInt(1, #Tier2NeutralItems)], h, isTierOneDone, 2)
        end

        for _, h in pairs(TeamDire) do
            NeutralItems.GiveItem(Tier2NeutralItems[RandomInt(1, #Tier2NeutralItems)], h, isTierOneDone, 2)
        end

        isTierTwoDone = true
    end

    -- Tier 3 Neutral Items
    if DotaTime() >= 13.5 * 60
    and not isTierThreeDone
    then
        for _, h in pairs(TeamRadiant) do
            NeutralItems.GiveItem(Tier3NeutralItems[RandomInt(1, #Tier3NeutralItems)], h, isTierTwoDone, 3)
        end

        for _, h in pairs(TeamDire) do
            NeutralItems.GiveItem(Tier3NeutralItems[RandomInt(1, #Tier3NeutralItems)], h, isTierTwoDone, 3)
        end

        isTierThreeDone = true
    end

    -- Tier 4 Neutral Items
    if DotaTime() >= 18.5 * 60
    and not isTierFourDone
    then

        for _, h in pairs(TeamRadiant) do
            NeutralItems.GiveItem(Tier4NeutralItems[RandomInt(1, #Tier4NeutralItems)], h, isTierThreeDone, 4)
        end

        for _, h in pairs(TeamDire) do
            NeutralItems.GiveItem(Tier4NeutralItems[RandomInt(1, #Tier4NeutralItems)], h, isTierThreeDone, 4)
        end

        isTierFourDone = true
    end

    -- Tier 5 Neutral Items
    if DotaTime() >= 25 * 60
    and not isTierFiveDone
    then

        for _, h in pairs(TeamRadiant) do
            NeutralItems.GiveItem(Tier5NeutralItems[RandomInt(1, #Tier5NeutralItems)], h, isTierFourDone, 5)
        end

        for _, h in pairs(TeamDire) do
            NeutralItems.GiveItem(Tier5NeutralItems[RandomInt(1, #Tier5NeutralItems)], h, isTierFourDone, 5)
        end

        isTierFiveDone = true
    end
end

function NeutralItems.GiveItem(itemName, hero, isTierDone, nTier)
    NeutralItems:RemoveEnhan(hero)
    if hero:HasRoomForItem(itemName, true, true)
    then
        local item = CreateItem(itemName, hero, hero)
        item:SetPurchaseTime(0)

        if NeutralItems.HasNeutralItem(hero)
        and isTierDone
        then
            hero:RemoveItem(hero:GetItemInSlot(DOTA_ITEM_NEUTRAL_SLOT))
            NeutralItems:RemoveEnhan(hero)
            hero:AddItem(item)
        else
            hero:AddItem(item)
        end
        local enhancement = NeutralItems:GetRandomEnhanByTier(nTier)
        if enhancement then
            local enha = CreateItem(enhancement.name, hero, hero)
            enha:SetPurchaseTime(0)
            hero:AddItem(enha):SetLevel(enhancement.level)
        end
    end
end

function NeutralItems:RemoveEnhan(unit)
	for idx = 1, 20 do
		local currentItem = unit:GetItemInSlot(idx)
		if currentItem ~= nil then
			if string.find(currentItem:GetName(), "item_enhancement") then
				unit:RemoveItem(currentItem)
				-- return
			end
		end
	end
end

function NeutralItems.HasNeutralItem(hero)
    if not hero then
        return false
    end

    local item = hero:GetItemInSlot(DOTA_ITEM_NEUTRAL_SLOT)
    if item then
        return true
    end

    return false
end

function DotaTime()
    local time = GameRules:GetDOTATime(false, false)
    if time == nil or time < 0 then return 0 end
    return time
end

return NeutralItems