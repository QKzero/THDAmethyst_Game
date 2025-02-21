--[[

item_autumn_leaves = {}

function item_autumn_leaves:GetIntrinsicModifierName()
	return "modifier_item_autumn_leaves_basic"
end

modifier_item_autumn_leaves_basic = {}
LinkLuaModifier("modifier_item_autumn_leaves_basic","items/item_autumn_leaves.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_item_autumn_leaves_basic:IsHidden() return true end
function modifier_item_autumn_leaves_basic:IsPurgable() return false end
function modifier_item_autumn_leaves_basic:IsPurgeException() return false end
function modifier_item_autumn_leaves_basic:RemoveOnDeath() return false end
function modifier_item_autumn_leaves_basic:GetAttributes()	return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_item_autumn_leaves_basic:OnCreated()
	if not IsServer() then return end
	if not self:GetCaster():HasModifier("modifier_illusion") and not self:GetCaster():HasModifier("modifier_item_autumn_leaves_passive") then
		self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_item_autumn_leaves_passive", {})
	end
end

function modifier_item_autumn_leaves_basic:OnDestroy()
	if not IsServer() then return end
	if  self:GetCaster():HasModifier("modifier_item_autumn_leaves_passive") then
		self:GetCaster():RemoveModifierByName("modifier_item_autumn_leaves_passive")
	end
end

function modifier_item_autumn_leaves_basic:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}
end

function modifier_item_autumn_leaves_basic:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_autumn_leaves_basic:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("bonus_damage")
end


modifier_item_autumn_leaves_passive = {}
LinkLuaModifier("modifier_item_autumn_leaves_passive","items/item_autumn_leaves.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_item_autumn_leaves_passive:IsHidden() return true end
function modifier_item_autumn_leaves_passive:IsPurgable() return false end
function modifier_item_autumn_leaves_passive:IsPurgeException() return false end
function modifier_item_autumn_leaves_passive:RemoveOnDeath() return false end

function modifier_item_autumn_leaves_passive:OnCreated()
	if not IsServer() then return end
	self.pierce = 0
	self.damage = self:GetAbility():GetSpecialValueFor("damage")
	self.chance = self:GetAbility():GetSpecialValueFor("change")
	self.ability = self:GetAbility()
	--print("yes")
end

function modifier_item_autumn_leaves_passive:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end


function modifier_item_autumn_leaves_passive:CheckState()
	if self.pierce == 1 then
		return {
			[MODIFIER_STATE_CANNOT_MISS] 	= true,
		}
	else
		return
	end
end

function modifier_item_autumn_leaves_passive:OnAttack(keys)
	--print("11111")
	if keys.attacker == self:GetParent() then
		if RollPseudoRandom(self.chance,self)then
			self.pierce = 1
		end
	end
end

function modifier_item_autumn_leaves_passive:OnAttackLanded(keys)
	if not IsServer() then return end
	if keys.attacker ~= self:GetParent() or keys.target:IsBuilding() or keys.attacker:IsIllusion() then return end
	if 	self.pierce == 1 then
		ApplyDamage({
			victim 			= keys.target,
			damage 			= self.damage,
			damage_type		= DAMAGE_TYPE_MAGICAL,
			damage_flags 	= DOTA_DAMAGE_FLAG_NONE,
			attacker 		= keys.attacker,
			ability 		= self.ability
		})
		keys.attacker:EmitSound("DOTA_Item.MKB.proc")
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, keys.target, self.damage, nil)
		--print("yes")
	end
	self.pierce = 0
end

]]--

function OnKnivesRandSucc(keys)
	--print('succ')
	--print(keys.target:GetHealth())
	keys.ability:ApplyDataDrivenModifier(keys.caster, keys.caster, keys.ModifierName, {})
end

function OnKnivesPierceLanded(keys)
	if not IsServer() then return end
	if keys.attacker ~= keys.caster or keys.target:IsBuilding() or keys.attacker:IsIllusion() then return end
	--print("yes")
	--print(keys.target:GetHealth())
		ApplyDamage({
			victim 			= keys.target,
			damage 			= keys.damage,
			damage_type		= DAMAGE_TYPE_MAGICAL,
			damage_flags 	= DOTA_DAMAGE_FLAG_NONE,
			attacker 		= keys.attacker,
			ability 		= keys.ability
		})
	keys.attacker:EmitSound("DOTA_Item.MKB.proc")
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, keys.target, keys.damage, nil)
	--print(keys.target:GetHealth())
	
	keys.attacker:RemoveModifierByName(keys.ModifierName)
end

-- debug
local attack_count = 0
local landed_count = 0

function ReconsiderNomiss(keys)
--[[
	print('ReconsiderNomiss')
	print(keys.ability)
	print(keys.ability:GetItemState())
	if keys.FirstCheck then
		attack_count = 0
		landed_count = 0
	else
		attack_count = attack_count + 1
	end
]]--
	keys.caster:RemoveModifierByName(keys.ModifierName)
	if (keys.FirstCheck or ( keys.ability and keys.ability:GetItemState()>0 ))
		and keys.Chance>=RandomInt(1,100)
	then
		keys.ability:ApplyDataDrivenModifier(keys.caster, keys.caster, keys.ModifierName, {})
		--print('added')
	end
end

function OnLeavesPierceLanded(keys)
	if not IsServer() then return end
	local ItemAbility = keys.ability
	local Caster = keys.caster
	local Target = keys.target
	local damage = ItemAbility:GetSpecialValueFor("damage")
	if Target:IsBuilding() or not Caster:IsRealHero() or not Target:IsAlive() then
		return
	end
	local duration = ItemAbility:GetSpecialValueFor("duration")
	local max_stack = ItemAbility:GetSpecialValueFor("maxstack")
	
	local debuff_name = keys.ModifierName
	local stackcount = 1
	if not Target:HasModifier(debuff_name) then
		ItemAbility:ApplyDataDrivenModifier(Caster, Target, debuff_name,  {duration = duration* (1 - Target:GetStatusResistance())} )
		Target:FindModifierByName(debuff_name):SetStackCount(1)
	else
		stackcount = Target:GetModifierStackCount(debuff_name, ItemAbility)
		if stackcount < max_stack then
			stackcount = stackcount + 1
		end
		Target:FindModifierByName(debuff_name):SetDuration(duration* (1 - Target:GetStatusResistance()), true)
		Target:FindModifierByName(debuff_name):SetStackCount(stackcount)
	end
	
	local damage_table = {
		ability = ItemAbility,
		victim = Target,
		attacker = Caster,
		damage = damage * stackcount,
		damage_type = DAMAGE_TYPE_MAGICAL, 
	}
	UnitDamageTarget(damage_table)
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, Target, damage * stackcount, nil)
	keys.attacker:EmitSound("DOTA_Item.MKB.proc")
	
	--landed_count = landed_count + 1
	--print(string.format("%d/%d=%f",landed_count,attack_count,landed_count/attack_count))
end