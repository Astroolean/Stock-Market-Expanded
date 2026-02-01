trigger = {}

function trigger:new()
	local o = {}

    -- Default data
    o.name = "droneAction"
    o.fadeSpeed = 0.0075
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
    ---@param this NPCPuppet
    ---@param evt gamePotentialDeathEvent
    Observe("NPCPuppet", "OnPotentialDeath", function (this, evt)
        local killerType = gamedataNPCType.Human
        pcall(function ()
            local inst = evt and evt.instigator or nil
            if inst then
                pcall(function()
                    killerType = inst:GetRecord():CharacterType():Type()
                end)
            end
        end)
        local selfType = this:GetRecord():CharacterType():Type()

        if selfType == gamedataNPCType.Android or selfType == gamedataNPCType.Drone or selfType == gamedataNPCType.Mech then
            self.exportData.value = self.exportData.value - 0.06
        end
        if killerType == gamedataNPCType.Android or killerType == gamedataNPCType.Drone or killerType == gamedataNPCType.Mech then
            self.exportData.value = self.exportData.value + 0.08
        end
    end)
end

function trigger:update() -- Gets called onUpdate

end

return trigger