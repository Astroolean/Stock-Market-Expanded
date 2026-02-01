local Cron = require("modules/external/Cron")

trigger = {}

function trigger:new()
	local o = {}

    -- Default data
    o.name = "wantedLevel"
    o.fadeSpeed = 0.0075
    o.newsThreshold = 0.24
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
        local stars = tonumber(EnumInt(Game.GetScriptableSystemsContainer():Get("PreventionSystem"):GetHeatStage()))
        self.exportData.value = self.exportData.value + 0.005 * stars
    end)
end

function trigger:update() -- Gets called onUpdate

end

return trigger