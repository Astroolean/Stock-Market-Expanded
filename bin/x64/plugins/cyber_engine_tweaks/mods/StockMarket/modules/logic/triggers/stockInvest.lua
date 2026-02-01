trigger = {}

function trigger:new()
	local o = {}

    -- Default data
    o.name = "stockInvest"
    o.fadeSpeed = 0.0075
    o.newsThreshold = 0.2
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

function trigger:transaction(stock, amount)
    self.exportData.value = self.exportData.value + (stock:getCurrentPrice() * amount) / 270000
end

function trigger:registerObservers()end
function trigger:update()end

return trigger