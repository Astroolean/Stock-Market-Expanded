trigger = {}

function trigger:new()
	local o = {}

    -- Default data
    o.name = "moneySpent"
    o.fadeSpeed = 0.0025
    o.newsThreshold = 0.25
    o.exportData = {
        value = 0
    }

    o.money = 0
    o.time = 0

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

function trigger:registerObservers()
    Observe("CurrencyNotification", "UpdateData", function(this)
        if this.currencyData.diff < 0 then
            self.exportData.value = self.exportData.value + (-this.currencyData.diff / 500000)
        end
    end)
end

function trigger:update() end

return trigger