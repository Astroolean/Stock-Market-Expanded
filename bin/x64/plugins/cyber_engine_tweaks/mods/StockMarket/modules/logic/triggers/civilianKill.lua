trigger = {}

function trigger:new()
	local o = {}

    -- Default data
    o.name = "civilianKill"
    o.fadeSpeed = 0.004
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
    ---@param this NPCPuppet
    ---@param evt gamePotentialDeathEvent
    Observe("NPCPuppet", "OnPotentialDeath", function (this, evt)
        ---@type GameObject
        local killer = evt and evt.instigator or nil

        if not killer then return end
        local faction = this:GetRecord():Affiliation():Type()
        if faction ~= gamedataAffiliation.Civilian and faction ~= gamedataAffiliation.Unaffiliated then return end

        if not killer then return end
        if killer:IsPlayer() then
            self.exportData.value = self.exportData.value + 0.04
        end
    end)
end

function trigger:update() -- Gets called onUpdate

end

return trigger