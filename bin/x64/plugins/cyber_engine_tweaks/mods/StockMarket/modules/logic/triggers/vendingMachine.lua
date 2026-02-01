trigger = {}

function trigger:new()
	local o = {}

    -- Default data
    o.name = "vendingMachine"
    o.fadeSpeed = 0.008
    o.newsThreshold = 0.32
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
    Observe("VendingMachine", "OnDispenceItemFromVendor", function(this, evt)
        local price = MarketSystem.GetBuyPrice(this, evt:GetItemID())
        local pMoney = Game.GetTransactionSystem():GetItemQuantity(GetPlayer(), MarketSystem.Money())
        if pMoney < price then return end

        self.exportData.value = self.exportData.value + price * 0.0006
    end)
end

function trigger:update() -- Gets called onUpdate

end

return trigger