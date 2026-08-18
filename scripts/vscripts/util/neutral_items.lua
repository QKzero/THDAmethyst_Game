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
    "item_trusty_shovel",      -- 可靠铁铲
    "item_occult_bracelet",    -- 玄奥手镯
    "item_unstable_wand",      -- 豚杆
    "item_mana_draught",       -- 魔力药水
    "item_polliwog_charm",     -- 蝌蚪护符
    "item_spark_of_courage",   -- 勇气之光
    "item_rippers_lash",       -- 撕裂之鞭
    "item_orb_of_destruction", -- 毁灭灵球
    "item_mysterious_hat",     -- 仙灵饰品
    "item_ironwood_tree",      -- 铁树之木
    "item_safety_bubble",      -- 安全泡泡
    -- "item_royal_jelly",        -- 蜂王浆 可能存在版本冲突，不使用
    "item_duelist_gloves",     -- 决斗者手套
    "item_faded_broach",       -- 暗淡胸针
    "item_seeds_of_serenity",  -- 宁静种籽
    "item_possessed_mask",     -- 附魂面具
    "item_keen_optic",         -- 基恩镜片
    "item_ocean_heart",        -- 海洋之心
}

local Tier2NeutralItems = {
    "item_essence_ring",       -- 精华指环
    "item_iron_talon",         -- 寒铁钢爪
    "item_gossamer_cape",      -- 蛛丝斗篷
    "item_searing_signet",     -- 炽热纹章
    "item_misericorde",        -- 飞贼之刃
    "item_pogo_stick",         -- 杂技玩具
    "item_light_collector",    -- 集光器
    "item_defiant_shell",      -- 不羁甲壳
    "item_bullwhip",           -- 凌厉长鞭
    "item_grove_bow",          -- 林野长弓
    "item_ring_of_aquila",     -- 天鹰之城
    "item_quicksilver_amulet", -- 银闪护符
}

local Tier3NeutralItems = {
    "item_serrated_shiv",        -- 锯齿短刀
    "item_gale_guard",           -- 烈风护体
    "item_nemesis_curse",        -- 天诛之咒
    "item_gunpowder_gauntlets",  -- 火药手套
    "item_whisper_of_the_dread", -- 邪道私语
    "item_ninja_gear",           -- 忍者用具
    "item_vambrace",             -- 臂甲
    "item_psychic_headband",     -- 通灵头带
    "item_doubloon",             -- 双面币
    "item_craggy_coat",          -- 崎岖外衣
    "item_quickening_charm",     -- 加速护符
    "item_penta_edged_sword",    -- 五锋长剑
    "item_enchanted_quiver",     -- 魔力箭袋
    "item_dandelion_amulet",     -- 蒲公英护符
}

local Tier4NeutralItems = {
    "item_ogre_seal_totem",    -- 食人魔海豹图腾
    "item_magnifying_monocle", -- 放大单片
    "item_crippling_crossbow", -- 致残之弩
    "item_ceremonial_robe",    -- 祭礼长袍
    "item_mind_breaker",       -- 智灭
    -- "item_pyrrhic_cloak",      -- 皮洛士斗篷 反伤冲突，不用
    "item_martyrs_plate",      -- 烈士鳞甲
    "item_havoc_hammer",       -- 浩劫巨锤
    "item_stormcrafter",       -- 风暴宝器
    "item_ascetic_cap",        -- 简朴短帽
    "item_ancient_guardian",   -- 遗迹守护者
    "item_avianas_feather",    -- 艾维娜之羽
    "item_spell_prism",        -- 法术棱镜
    "item_trickster_cloak",    -- 欺诈师斗篷
    "item_heavy_blade",        -- 行巫之祸
}

local Tier5NeutralItems = {
    "item_panic_button",         -- 神妙明灯
    "item_desolator_2",          -- 寂灭
    "item_fallen_sky",           -- 天崩
    "item_minotaur_horn",        -- 恶牛角
    "item_spider_legs",          -- 网虫腿
    "item_unrelenting_eye",      -- 不屈之眼
    "item_pirate_hat",           -- 海盗帽
    "item_rattlecage",           -- 回响之笼
    "item_giants_ring",          -- 巨人之戒
    "item_unwavering_condition", -- 坚毅之件
    "item_ex_machina",           -- 机械之心
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
    { name = "item_enhancement_wise",      tier = 4, realName = "Wise Enhancement" , level = 1},

    -- Tier 5 enhancements
    { name = "item_enhancement_timeless",  tier = 5, realName = "Timeless Enhancement" , level = 2},
    { name = "item_enhancement_titanic",   tier = 5, realName = "Titanic Enhancement" , level = 2},
    { name = "item_enhancement_crude",     tier = 5, realName = "Crude Enhancement" , level = 2},
    { name = "item_enhancement_feverish",  tier = 5, realName = "Feverish Enhancement" , level = 1},
    { name = "item_enhancement_fleetfooted", tier = 5, realName = "Fleetfooted Enhancement" , level = 1},
    { name = "item_enhancement_audacious", tier = 5, realName = "Audacious Enhancement" , level = 1},
    { name = "item_enhancement_evolved",   tier = 5, realName = "Evolved Enhancement" , level = 1},
    { name = "item_enhancement_boundless", tier = 5, realName = "Boundless Enhancement" , level = 1},
    { name = "item_enhancement_wise",      tier = 5, realName = "Wise Enhancement" , level = 1},
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
            NeutralItems.GiveItem(Tier2NeutralItems[RandomInt(1, #Tier2NeutralItems)], h, isTierTwoDone, 2)
        end

        for _, h in pairs(TeamDire) do
            NeutralItems.GiveItem(Tier2NeutralItems[RandomInt(1, #Tier2NeutralItems)], h, isTierTwoDone, 2)
        end

        isTierTwoDone = true
    end

    -- Tier 3 Neutral Items
    if DotaTime() >= 13.5 * 60
    and not isTierThreeDone
    then
        for _, h in pairs(TeamRadiant) do
            NeutralItems.GiveItem(Tier3NeutralItems[RandomInt(1, #Tier3NeutralItems)], h, isTierThreeDone, 3)
        end

        for _, h in pairs(TeamDire) do
            NeutralItems.GiveItem(Tier3NeutralItems[RandomInt(1, #Tier3NeutralItems)], h, isTierThreeDone, 3)
        end

        isTierThreeDone = true
    end

    -- Tier 4 Neutral Items
    if DotaTime() >= 18.5 * 60
    and not isTierFourDone
    then

        for _, h in pairs(TeamRadiant) do
            NeutralItems.GiveItem(Tier4NeutralItems[RandomInt(1, #Tier4NeutralItems)], h, isTierFourDone, 4)
        end

        for _, h in pairs(TeamDire) do
            NeutralItems.GiveItem(Tier4NeutralItems[RandomInt(1, #Tier4NeutralItems)], h, isTierFourDone, 4)
        end

        isTierFourDone = true
    end

    -- Tier 5 Neutral Items
    if DotaTime() >= 25 * 60
    and not isTierFiveDone
    then

        for _, h in pairs(TeamRadiant) do
            NeutralItems.GiveItem(Tier5NeutralItems[RandomInt(1, #Tier5NeutralItems)], h, isTierFiveDone, 5)
        end

        for _, h in pairs(TeamDire) do
            NeutralItems.GiveItem(Tier5NeutralItems[RandomInt(1, #Tier5NeutralItems)], h, isTierFiveDone, 5)
        end

        isTierFiveDone = true
    end
end

function NeutralItems.GiveItem(itemName, hero, isTierDone, nTier)
    if hero == nil or hero:IsNull() then return end

    NeutralItems:RemoveEnhan(hero)

    local oldNeutralItem = hero:GetItemInSlot(DOTA_ITEM_NEUTRAL_SLOT)
    if oldNeutralItem ~= nil then
        hero:RemoveItem(oldNeutralItem)
        UTIL_Remove(oldNeutralItem)
    end

    if hero:HasRoomForItem(itemName, true, true)
    then
        local item = CreateItem(itemName, hero, hero)
        item:SetPurchaseTime(0)

        local addedItem = hero:AddItem(item)
        if addedItem == nil then
            UTIL_Remove(item)
            return
        end

        local enhancement = NeutralItems:GetRandomEnhanByTier(nTier)
        if enhancement then
            local enha = CreateItem(enhancement.name, hero, hero)
            enha:SetPurchaseTime(0)
            local addedEnha = hero:AddItem(enha)
            if addedEnha ~= nil then
                addedEnha:SetLevel(enhancement.level)
            else
                UTIL_Remove(enha)
            end
        end
    end
end

function NeutralItems:RemoveEnhan(unit)
	for idx = 1, 20 do
		local currentItem = unit:GetItemInSlot(idx)
		if currentItem ~= nil then
            if string.find(currentItem:GetName(), "item_enhancement") then
                unit:RemoveItem(currentItem)
                UTIL_Remove(currentItem)
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