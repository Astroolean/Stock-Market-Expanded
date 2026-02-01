local Cron = require("modules/external/Cron")

trigger = {}

function trigger:new()
	local o = {}

    -- Default data
    o.name = "rayfieldAction"
    o.fadeSpeed = 0.005
    o.newsThreshold = 0.35
    o.exportData = {
        value = 0
    }

    o.cooldown = false

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
        self.exportData.value = self.exportData.value + self.fadeSpeed
    end
end

function trigger:registerObservers() -- Gets called once onInit
    Observe("VehicleComponent", "StealVehicle", function(this)
        if self.cooldown then return end
        self.cooldown = true
        local okVeh, match = pcall(function()
            local v = this:GetVehicle()
            if not v then return false end
            local r = v:GetRecord()
            if not r then return false end
            local m = r:Manufacturer()
            if not m then return false end
            return m:Type() == gamedataVehicleManufacturer.Rayfield
        end)
        if not okVeh or not match then return end
        Cron.After(1, function ()
            self.cooldown = false
        end)
        self.exportData.value = self.exportData.value - 0.16
    end)

    Cron.Every(5, function ()
        local veh = GetPlayer():GetMountedVehicle()
        if veh ~= nil then
            local okVeh2, match2 = pcall(function()
                local r = veh:GetRecord()
                if not r then return false end
                local m = r:Manufacturer()
                if not m then return false end
                return m:Type() == gamedataVehicleManufacturer.Rayfield
            end)
            if not okVeh2 or not match2 then return end
            self.exportData.value = math.min(1, self.exportData.value + 0.00275)
        end
    end)
end

function trigger:update() end

return trigger