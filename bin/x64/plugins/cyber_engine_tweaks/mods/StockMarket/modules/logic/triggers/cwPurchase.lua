trigger = {}

function trigger:new()
	local o = {}

    -- Default data
    o.name = "cwPurchase"
    o.fadeSpeed = 0.005
    o.newsThreshold = 0.33
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
    ---@param this RipperDocGameController
    ---@param id ItemID
    Observe("RipperDocGameController", "OnItemBought", function(this, id)
        self.exportData.value = self.exportData.value + MarketSystem.GetBuyPrice(this.VendorDataManager:GetVendorInstance(), id) / 50000
    end)
end

function trigger:update() -- Gets called onUpdate

end

return trigger