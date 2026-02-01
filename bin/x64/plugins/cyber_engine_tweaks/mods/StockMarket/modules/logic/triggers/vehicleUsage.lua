local Cron = require("modules/external/Cron")

trigger = {}

function trigger:new()
	local o = {}

    -- Default data
    o.name = "vehicleUsage"
    o.fadeSpeed = 0.0065
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
    Cron.Every(5, function ()
        if GetPlayer():GetMountedVehicle() ~= nil then
            self.exportData.value = math.min(1, self.exportData.value + 0.00235)
        end
    end)
end

function trigger:update() -- Gets called onUpdate

end

return trigger