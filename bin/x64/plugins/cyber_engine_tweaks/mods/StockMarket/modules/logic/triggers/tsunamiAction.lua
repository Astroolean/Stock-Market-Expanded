trigger = {}

function trigger:new()
	local o = {}

    -- Default data
    o.name = "tsunamiAction"
    o.fadeSpeed = 0.0075
    o.newsThreshold = 0.25
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
        if not killer then return end

        local weapon = killer:GetActiveWeapon()
        if killer:IsPuppet() and weapon and string.match(weapon:GetWeaponRecord():FriendlyName(), "tsunami") then
            self.exportData.value = self.exportData.value + 0.0225
        end

        local weapon = this:GetActiveWeapon()
        if weapon then
            if string.match(weapon:GetWeaponRecord():FriendlyName(), "tsunami") then
                self.exportData.value = self.exportData.value - 0.012
            end
        end
    end)
end

function trigger:update() -- Gets called onUpdate

end

return trigger