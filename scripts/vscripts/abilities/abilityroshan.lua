if modifier_roshan_item == nil then modifier_roshan_item = class({}) end
LinkLuaModifier("modifier_roshan_item", "scripts/vscripts/abilities/abilityroshan.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_roshan_item:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end
function modifier_roshan_item:IsPurgeException() return false end
function modifier_roshan_item:IsPurgable() return false end
function modifier_roshan_item:IsDebuff() return false end
function modifier_roshan_item:IsHidden() return true end

function modifier_roshan_item:GetRoshanCustomItems()
	return {
		"item_jiduzhixinyan",
	}
end

function modifier_roshan_item:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_DEATH,
	}
end

function modifier_roshan_item:OnCreated()
	if not IsServer() then return end

    local items = self:GetRoshanCustomItems()
    for i = 1, #items do
        self:GetParent():AddItemByName("item_jiduzhixinyan")
    end
end

function modifier_roshan_item:OnDeath( keys )
	if not IsServer() then return end

	if keys.unit ~= self:GetParent() then return end

	if self:GetParent():IsHero() or self:GetParent():HasInventory() then -- In order to make sure that the unit that died actually has items, it checks if it is either a hero or if it has an inventory.
		for itemSlot = 0, 5, 1 do --a For loop is needed to loop through each slot and check if it is the item that it needs to drop
            if self:GetParent() ~= nil then --checks to make sure the killed unit is not nonexistent.
                local Item = self:GetParent():GetItemInSlot( itemSlot ) -- uses a variable which gets the actual item in the slot specified starting at 0, 1st slot, and ending at 5,the 6th slot.
                if Item ~= nil and Item:GetName() == itemName then -- makes sure that the item exists and making sure it is the correct item
                    local items = self:GetRoshanCustomItems()
                    for i = 1, #items do
                        local itemName = items[i]
                        local newItem = CreateItem(itemName, nil, nil) -- creates a new variable which recreates the item we want to drop and then sets it to have no owner
                        CreateItemOnPositionSync(self:GetParent():GetOrigin(), newItem) -- takes the newItem variable and creates the physical item at the killed unit's location
                        self:GetParent():RemoveItem(Item) -- finally, the item is removed from the original units inventory.
                    end
                end
            end
		end
	end

	GameRules:GetGameModeEntity():SetContextThink("roshanItem_refresh",
		function()
			local roshan = Entities:FindByClassname(nil, "npc_dota_roshan")
			if roshan == nil then
				print(roshan ~= nil)
			else
				print(roshan ~= nil, not roshan:IsNull(), roshan:IsAlive())
			end
			if roshan ~= nil and not roshan:IsNull() and roshan:IsAlive() then
				local m = roshan:AddNewModifier(roshan, nil, "modifier_roshan_item", {})
				return nil
			end
			return 1
		end, 1
	)
end
