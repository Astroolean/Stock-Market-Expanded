trigger = {}

function trigger:new()
	local o = {}

    -- Default data
    o.name = "pacificaCrime"
    o.fadeSpeed = 0.005
    o.newsThreshold = 0.175
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

        local district = TweakDBInterface.GetDistrictRecord(Game.GetScriptableSystemsContainer():Get("PreventionSystem").districtManager:GetCurrentDistrict():GetDistrictID())
        local mainDistrict = district:LocalizedName()

        local pacifica = mainDistrict == "LocKey#10957" or mainDistrict == "LocKey#10958"

        if not killer then return end
        if killer:IsPlayer() and pacifica and (faction ~= gamedataAffiliation.Civilian or faction ~= gamedataAffiliation.Unaffiliated) then
            self.exportData.value = self.exportData.value + 0.033
        elseif pacifica then
            self.exportData.value = self.exportData.value + 0.005
        end
    end)
end

function trigger:update() -- Gets called onUpdate

end

return trigger