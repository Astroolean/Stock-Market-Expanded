trigger = {}

function trigger:new()
    local o = {}
    o.name = "event_little_china_trading"
    o.fadeSpeed = 0.007
    o.newsThreshold = 0.28
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

function trigger:decreaseValue()
    if self.exportData.value == 0 then return end
    if self.exportData.value > 0 then
        self.exportData.value = self.exportData.value - self.fadeSpeed
    elseif self.exportData.value < 0 then
        self.exportData.value = 0
    end
end

function trigger:registerObservers()
end

function trigger:update()
end

return trigger
