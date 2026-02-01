trigger = {}

function trigger:new()
	local o = {}

    -- Default data
    o.name = "foodPurchase"
    o.fadeSpeed = 0.015
    o.newsThreshold = 0.265
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
    Observe("FullscreenVendorGameController", "BuyItem", function(this, item, quantity)
        if not item then return end
        quantity = quantity or 1

        local isEdible = false

        -- Try dynamic tags first (varies by game version)
        if item.GetDynamicTags then
            local okTags, tags = pcall(function() return item:GetDynamicTags() end)
            if okTags and type(tags) == "table" then
                for _, t in pairs(tags) do
                    if t and t.value == "Edible" then
                        isEdible = true
                        break
                    end
                end
            end
        end

        -- Fallback: TweakDB record tags (best-effort; safe if unavailable)
        if not isEdible and item.GetID then
            pcall(function()
                local id = item:GetID()
                local rec = TweakDBInterface.GetItemRecord(id)
                if rec and rec.Tags then
                    local rtags = rec:Tags()
                    if rtags then
                        for _, t in ipairs(rtags) do
                            if tostring(t) == "Edible" then
                                isEdible = true
                                break
                            end
                        end
                    end
                end
            end)
        end

        if not isEdible then return end

        local okPrice, price = pcall(function()
            local vendor = (this and this.VendorDataManager and this.VendorDataManager:GetVendorInstance()) or nil
            if not vendor then return nil end
            return MarketSystem.GetBuyPrice(vendor, item:GetID()) * quantity
        end)
        if not okPrice or not price then return end

        local okMoney, pMoney = pcall(function()
            return Game.GetTransactionSystem():GetItemQuantity(GetPlayer(), MarketSystem.Money())
        end)
        if not okMoney or not pMoney or pMoney < price then return end

        self.exportData.value = self.exportData.value + price * 0.00028
    end)
end

function trigger:update() -- Gets called onUpdate

end

return trigger