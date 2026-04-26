require("util/mode_select")

-- Bot 基础管理器
ability_common_bot_buff = class({})

function ability_common_bot_buff:GetIntrinsicModifierName()
	return "modifier_bot_buff"
end

function ability_common_bot_buff:OnOwnerDied()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local ability = self

	if caster:IsIllusion() then return end

    caster:ModifyGold(botDifficultyData.goldGainOnDeath, false, DOTA_ModifyGold_AbilityGold)
end

modifier_bot_buff = class({})
LinkLuaModifier("modifier_bot_buff", "scripts/vscripts/abilities/bot_buff.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_bot_buff:IsHidden() return false end
--function modifier_bot_buff:IsDebuff() return false end
function modifier_bot_buff:IsPurgable() return false end
function modifier_bot_buff:RemoveOnDeath() return false end

function modifier_bot_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,

		MODIFIER_EVENT_ON_ATTACK_START,
		MODIFIER_EVENT_ON_UNIT_MOVED,
	}
end

function modifier_bot_buff:GetModifierConstantManaRegen()
    if self.manaRegen == nil then
        self.manaRegen = GetBotDifficultyData().manaRegen
    end

	return self.manaRegen
end

function modifier_bot_buff:GetModifierConstantHealthRegen()
    if self.hpRegen == nil then
        self.hpRegen = GetBotDifficultyData().hpRegen
    end

	return self.hpRegen
end

 function modifier_bot_buff:GetModifierBonusStats_Strength()
     if self.giveAttrBase == nil then
         self.giveAttrBase = GetBotDifficultyData().giveAttrBase
     end

	return self.giveAttrBase[1]
end

function modifier_bot_buff:GetModifierBonusStats_Agility()
    if self.giveAttrBase == nil then
        self.giveAttrBase = GetBotDifficultyData().giveAttrBase
    end

	return self.giveAttrBase[2]
end

 function modifier_bot_buff:GetModifierBonusStats_Intellect()
     if self.giveAttrBase == nil then
         self.giveAttrBase = GetBotDifficultyData().giveAttrBase
     end

     return self.giveAttrBase[3]
end

function modifier_bot_buff:OnCreated(params)
    if not IsServer() then return end
    
    self.caster = self:GetCaster()
    self.ability = self:GetAbility()

    local botDifficultyData = GetBotDifficultyData()
    print_r(botDifficultyData)
    
    self.giveGoldAmount = botDifficultyData.giveGoldAmount
    self.giveExpAmount = botDifficultyData.giveExpAmount
    self.giveAttrBonus = botDifficultyData.giveAttrBonus
    
    self.selfStunChanceOnAttack = botDifficultyData.selfStunChanceOnAttack
    self.selfStunDurationOnAttack = botDifficultyData.selfStunDurationOnAttack
    self.selfStunChanceOnMove = botDifficultyData.selfStunChanceOnMove
    self.selfStunDurationOnMove = botDifficultyData.selfStunDurationOnMove
    
    self.interval = self.ability:GetSpecialValueFor("interval")
    self:StartIntervalThink(self.interval)
end

function modifier_bot_buff:OnIntervalThink()
    if not IsServer() then return end

    if self.caster:IsIllusion() then return end

    -- 游戏还未开始，不生效
    local nowTime = GameRules:GetDOTATime(false, false)
    if (nowTime < 1.0) then return end

    -- 按照5分钟分批的索引
    local timeIndex5 = math.ceil(nowTime / 300.0)
    -- 按照10分钟分批的索引
    local timeIndex10 = math.ceil(nowTime / 600.0)

    -- 定时增加金币（5分钟批次）
    local addGold = botDifficultyData.giveGoldAmount[math.min(timeIndex5, #botDifficultyData.giveGoldAmount)]
    self.caster:ModifyGold(addGold, false, DOTA_ModifyGold_AbilityGold)

    -- 定时增加经验（5分钟批次）
    local addExp = botDifficultyData.giveExpAmount[math.min(timeIndex5, #botDifficultyData.giveExpAmount)]
    self.caster:AddExperience(addExp, DOTA_ModifyXP_HeroAbility, false, true)

    -- 定时增加三围（5分钟批次）
    local addStrength = 0
    local addAgility = 0
    local addIntelligence = 0
    if self.caster:GetPrimaryAttribute() == DOTA_ATTRIBUTE_STRENGTH then
        local attrBonusTable = botDifficultyData.giveAttrBonus[1][math.min(timeIndex5, #botDifficultyData.giveAttrBonus[1])]

        addStrength = attrBonusTable[1]
        addAgility = attrBonusTable[2]
        addIntelligence = attrBonusTable[3]
    elseif self.caster:GetPrimaryAttribute() == DOTA_ATTRIBUTE_AGILITY then
        local attrBonusTable = botDifficultyData.giveAttrBonus[2][math.min(timeIndex5, #botDifficultyData.giveAttrBonus[2])]

        addStrength = attrBonusTable[1]
        addAgility = attrBonusTable[2]
        addIntelligence = attrBonusTable[3]
    elseif self.caster:GetPrimaryAttribute() == DOTA_ATTRIBUTE_INTELLECT then
        local attrBonusTable = botDifficultyData.giveAttrBonus[3][math.min(timeIndex5, #botDifficultyData.giveAttrBonus[3])]

        addStrength = attrBonusTable[1]
        addAgility = attrBonusTable[2]
        addIntelligence = attrBonusTable[3]
    end
    self.caster:ModifyStrength(addStrength)
    self.caster:ModifyAgility(addAgility)
    self.caster:ModifyIntellect(addIntelligence)

    -- print_r({
    --     HeroName = self.caster:GetName(),
    --     time = nowTime,
    --     addGold = addGold,
    --     addExp = addExp,
    --     addStrength = addStrength,
    --     addAgility = addAgility,
    --     addIntelligence = addIntelligence,
    -- })
end

function modifier_bot_buff:OnAttackStart(event)
    if not IsServer() then return end

    if event.attacker ~= self.caster then return end

    self:SelfStun(botDifficultyData.selfStunChanceOnAttack, botDifficultyData.selfStunDurationOnAttack)
end

function modifier_bot_buff:OnUnitMoved(event)
    if not IsServer() then return end

    if event.unit ~= self.caster then return end

    self:SelfStun(botDifficultyData.selfStunChanceOnMove, botDifficultyData.selfStunDurationOnMove)
end

function modifier_bot_buff:SelfStun(chance, duration)
    if chance == 0 then return end

    if RandomFloat(0.0,1.0) > chance then return end
    
    UtilStun:UnitStunTarget(self.caster, self.caster, duration * RandomFloat(0.1,1.0) )
end

-- Bot 收集器
ability_common_bot_corrector = class({})

function ability_common_bot_corrector:GetIntrinsicModifierName()
    return "modifier_bot_corrector"
end

modifier_bot_corrector = class({})
LinkLuaModifier("modifier_bot_corrector", "scripts/vscripts/abilities/bot_buff.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_bot_corrector:IsHidden() return true end
--function modifier_bot_corrector:IsDebuff() return false end
function modifier_bot_corrector:IsPurgable() return false end
function modifier_bot_corrector:RemoveOnDeath() return false end

function modifier_bot_corrector:OnCreated(params)
    if not IsServer() then return end

    self.caster = self:GetCaster()
    self.ability = self:GetAbility()

    self:StartIntervalThink(0.1)
end

function modifier_bot_corrector:OnIntervalThink()
    if not IsServer() then return end
	
	if self.caster:IsIllusion() then return end
	
	-- from rune_fixer.lua
	local vec = Vector(0.0,0.0,-512.0)
	local checklen = 300

	local Caster = self.caster
	local Bounty_Spwner_List = Entities:FindAllByClassnameWithin("dota_item_rune_spawner_bounty", Caster:GetOrigin() + vec, checklen)
	
	if #Bounty_Spwner_List > 0 then
		local Rune_Bounty_List = Entities:FindAllByClassnameWithin("dota_item_rune", Caster:GetOrigin(), checklen)
		for _,v in pairs(Rune_Bounty_List) do
			if v ~= nil then
				--UTIL_Remove(v)
				Caster:PickupRune(v)
				break
			end
		end
	end
end


