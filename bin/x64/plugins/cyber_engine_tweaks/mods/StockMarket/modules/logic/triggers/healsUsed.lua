trigger = {}

function trigger:new()
	local o = {}

    -- Default data
    o.name = "healsUsed"
    o.fadeSpeed = 0.005
    o.newsThreshold = 0.22
    o.exportData = {
        value = 0
    }

	self.__index = self
   	return setmetatable(o, self)
end

function trigger:checkForData(data)
    if data["triggers"][self.name] == nil then
        data["triggers"][self.name] = self.exportData
    else
        self.exportData = data["triggers"][self.name]
    end
end

function trigger:decreaseValue() -- Runs every intervall
    if self.exportData.value == 0 then return end
    if self.exportData.value > 0 then
        self.exportData.value = self.exportData.value - self.fadeSpeed
    elseif self.exportData.value < 0 then
        self.exportData.value = 0
    end
end

function trigger:registerObservers() -- Gets called once onInit
    ---@param itemID gameItemID
    Observe("ItemActionsHelper", "ConsumeItem;GameObjectItemIDBool", function (_, itemID)
        if TweakDBInterface.GetConsumableItemRecord(itemID:GetTDBID()):ConsumableType() then
            self.exportData.value = self.exportData.value + 0.0225
        end
    end)
end

function trigger:update() end

return trigger