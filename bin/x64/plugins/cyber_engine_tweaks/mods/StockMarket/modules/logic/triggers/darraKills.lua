trigger = {}

function trigger:new()
	local o = {}

    -- Default data
    o.name = "darraKills"
    o.fadeSpeed = 0.004
    o.newsThreshold = 0.22
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
        self.exportData.value = self.exportData.value + self.fadeSpeed
    end
end

function trigger:registerObservers() -- Gets called once onInit
    ---@param evt gamePotentialDeathEvent
    Observe("NPCPuppet", "OnPotentialDeath", function (this, evt)
        ---@type GameObject
        local killer = evt and evt.instigator or nil

        if not killer then return end

        local weapon = nil
        pcall(function() weapon = killer:GetActiveWeapon() end)
        if killer:IsPuppet() and weapon and string.match(weapon:GetWeaponRecord():FriendlyName(), "darra") then
            self.exportData.value = self.exportData.value + 0.025
        end

        local weapon = nil
        pcall(function() weapon = this:GetActiveWeapon() end)
        if weapon then
            if weapon and weapon.GetWeaponRecord and weapon:GetWeaponRecord() and string.match(weapon:GetWeaponRecord():FriendlyName(), "darra") then
                self.exportData.value = self.exportData.value - 0.01
            end
        end
    end)
end

function trigger:update() end

return trigger