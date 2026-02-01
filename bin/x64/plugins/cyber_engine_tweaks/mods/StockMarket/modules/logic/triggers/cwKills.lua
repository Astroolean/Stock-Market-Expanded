trigger = {}

function trigger:new()
	local o = {}

    -- Default data
    o.name = "cwKills"
    o.fadeSpeed = 0.004
    o.newsThreshold = 0.225
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
    ---@param evt gamePotentialDeathEvent
    Observe("NPCPuppet", "OnPotentialDeath", function (_, evt)
        ---@type GameObject
        local killer = evt and evt.instigator or nil

        if not killer then return end
        if not killer then return end

        local weapon = killer:GetActiveWeapon()
        if not weapon then return end

        local wType = weapon:GetWeaponRecord():ItemType():Type()
        local isCW = wType == gamedataItemType.Cyb_Launcher or wType == gamedataItemType.Cyb_MantisBlades or wType == gamedataItemType.Cyb_NanoWires or wType == gamedataItemType.Cyb_StrongArms

        if killer:IsPuppet() and isCW then
            self.exportData.value = self.exportData.value + 0.021
        end
    end)
end

function trigger:update() end

return trigger