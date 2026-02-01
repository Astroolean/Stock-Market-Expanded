trigger = {}

function trigger:new()
	local o = {}

    -- Default data
    o.name = "bioGrenadeUsage"
    o.fadeSpeed = 0.005
    o.newsThreshold = 0.275
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
    ---@param this BaseGrenade
    Observe("BaseGrenade", "OnShoot", function (this)
        local gType = this:GetGrenadeType()

        if gType == EGrenadeType.Biohazard then
            self.exportData.value = self.exportData.value + 0.075
        end
    end)
end

function trigger:update() end

return trigger