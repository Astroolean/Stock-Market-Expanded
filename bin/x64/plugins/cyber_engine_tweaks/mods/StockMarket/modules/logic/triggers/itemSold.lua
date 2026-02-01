trigger = {}

function trigger:new()
	local o = {}

    -- Default data
    o.name = "anyItemSold"
    o.fadeSpeed = 0.005
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
        self.exportData.value = 0
    end
end

function trigger:registerObservers() -- Gets called once onInit
    Observe("FullscreenVendorGameController", "SellItem", function(_, item, quantity)
        local weight = nil
        local okW, w = pcall(function() return RPGManager.GetItemWeight(item) end)
        if okW and type(w) == "number" then
            weight = w
        else
            local okData, itemData = pcall(function()
                if item and item.GetItemData then return item:GetItemData() end
                if item and item.GetGameItemData then return item:GetGameItemData() end
                return nil
            end)
            if okData and itemData then
                local okW2, w2 = pcall(function() return RPGManager.GetItemWeight(itemData) end)
                if okW2 and type(w2) == "number" then
                    weight = w2
                end
            end
        end
        if not weight then weight = 1 end
        if weight == 0 then weight = 1 end
        self.exportData.value = self.exportData.value - weight * quantity * 0.0075
    end)
end

function trigger:update() -- Gets called onUpdate

end

return trigger