trigger = {}

function trigger:new()
	local o = {}

    -- Default data
    o.name = "smartWeaponKills"
    o.fadeSpeed = 0.005
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

function trigger:registerObservers() -- Gets called once onInit
    Observe("NPCPuppet", "OnPotentialDeath", function (_, evt)
        ---@type GameObject
        local killer = evt and evt.instigator or nil

        if not killer then return end

        if not killer then return end

        local weapon = killer:GetActiveWeapon()
        if killer:IsPuppet() and weapon and weapon:GetWeaponRecord():Evolution():Type() == gamedataWeaponEvolution.Smart then
            self.exportData.value = self.exportData.value + 0.024
        end
    end)
end

function trigger:update() end

return trigger