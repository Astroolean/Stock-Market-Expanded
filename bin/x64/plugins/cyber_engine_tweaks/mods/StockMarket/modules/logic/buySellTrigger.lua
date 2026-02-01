trigger = {}

function trigger:new()
	local o = {}

    o.name = ""
    o.fadeSpeed = 0.01
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

function trigger:onTransaction(stock, amount)
    local price = stock:getCurrentPrice()
    local totalValue = price * stock.sharesAmount
    local percent = (math.abs(amount) * price) / totalValue

    if amount > 0 then
        self.exportData.value = self.exportData.value + percent
    else
        self.exportData.value = self.exportData.value - percent
    end
end

function trigger:decreaseValue()
    if self.exportData.value == 0 then return end
    local delta = self.fadeSpeed
    if self.exportData.value < 0 then delta = - delta end
    self.exportData.value = self.exportData.value - delta

    if self.exportData.value < 0 and self.exportData.value + delta > 0 then
        self.exportData.value = 0
    end
    if self.exportData.value > 0 and self.exportData.value + delta < 0 then
        self.exportData.value = 0
    end
end

function trigger:registerObservers() end
function trigger:update() end

return trigger