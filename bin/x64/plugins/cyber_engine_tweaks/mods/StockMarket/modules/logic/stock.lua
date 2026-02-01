local lang = require("modules/utils/lang")
local utils = require("modules/utils/utils")

stock = {}

function stock:new(steps, market)
        local o = {}

    o.market = market

    o.steps = steps
    o.name = ""
    o.info = ""
    o.atlasPath = ""
    o.atlasPart = ""
    o.iconX = 0
    o.iconY = 0

    o.startPrice = 0
    o.sharesAmount = 0
    o.max = 0
    o.min = 0
    o.maxStep = 0
    o.deltaPower = 0
    o.triggers = {}

    o.exportData = {}
    o.default = {
        owned = 0,
        spent = 0,
        realizedProfit = 0,
        data = {}
    }

        self.__index = self
        return setmetatable(o, self)
end

function stock:getCurrentPrice()
    if self.exportData.data == nil or #self.exportData.data == 0 then
        return self.startPrice
    end
    return utils.round(self.exportData.data[#self.exportData.data], 1)
end

function stock:getTrend()
    if not self.exportData.data then return 0 end
    if #self.exportData.data < 11 then return 0 end
    local basePrice = self.exportData.data[#self.exportData.data - 10]
    if not basePrice or basePrice == 0 then return 0 end
    local percent = 100 * (self:getCurrentPrice() - basePrice) / basePrice
    return utils.round(percent, 1)
end

function stock:getPortfolioNum()
    return self.exportData.owned
end

function stock:getProfit(amount)
    -- Guard against zero amount
    if amount == 0 then return 0 end
    
    local owned = self.exportData.owned or 0
    local spent = self.exportData.spent or 0
    
    -- Guard against division by zero - no position means no profit to calculate
    if owned == 0 or spent == 0 then return 0 end
    
    local avgCost = spent / owned
    local v = (amount * avgCost) - (self:getCurrentPrice() * amount)
    return utils.round(v, 1)
end

-- Returns unrealized P/L for current position (value difference vs cost basis)
function stock:getUnrealizedProfit()
    local owned = self.exportData.owned or 0
    local spent = self.exportData.spent or 0
    
    if owned == 0 then return 0 end
    
    local currentValue = owned * self:getCurrentPrice()
    return utils.round(currentValue - spent, 1)
end

-- Returns realized P/L from past trades (accumulated when selling)
function stock:getRealizedProfit()
    return utils.round(self.exportData.realizedProfit or 0, 1)
end

-- Returns total P/L: realized + unrealized
function stock:getTotalProfit()
    return utils.round(self:getRealizedProfit() + self:getUnrealizedProfit(), 1)
end

function stock:performTransaction(amount)
    -- Initialize realizedProfit if not present (for backward compatibility)
    if not self.exportData.realizedProfit then
        self.exportData.realizedProfit = 0
    end
    
    -- Calculate average cost before ownership changes (for sell P/L)
    local oldOwned = self.exportData.owned or 0
    local oldSpent = self.exportData.spent or 0
    local avgCost = 0
    if oldOwned > 0 then
        avgCost = oldSpent / oldOwned
    end
    
    self.exportData.owned = self.exportData.owned + amount
    self.market.triggerManager:onTransaction(self, amount)

    local tradeValue = math.abs(amount * self:getCurrentPrice())

    if amount > 0 then
        -- Buying shares
        utils.spendMoney(amount * self:getCurrentPrice())
        self.exportData.spent = self.exportData.spent + amount * self:getCurrentPrice()
    else
        -- Selling shares
        local sellAmount = math.abs(amount)
        local salePrice = self:getCurrentPrice()
        local totalSaleValue = sellAmount * salePrice
        
        -- Calculate and accumulate realized profit (sale proceeds - cost basis)
        local costBasis = sellAmount * avgCost
        local realizedGain = totalSaleValue - costBasis
        self.exportData.realizedProfit = self.exportData.realizedProfit + realizedGain
        
        -- Give player the sale money
        Game.AddToInventory("Items.money", math.floor(totalSaleValue))
        
        -- Update spent (reduce proportionally)
        local divisor = sellAmount + self.exportData.owned
        if divisor > 0 then
            self.exportData.spent = self.exportData.spent - (sellAmount * (self.exportData.spent / divisor))
        else
            self.exportData.spent = 0
        end
    end
    
    -- Security Score: Track successful trade
    if self.market.securityManager then
        self.market.securityManager:onSuccessfulTrade(tradeValue)
    end
end

function stock:loadFromDefinition(data) -- Load from json file
    self.name = data.name
    self.info = data.info or ("stockInfo_" .. data.name)
    self.sharesAmount = data.sharesAmount
    self.min = data.min
    self.max = data.max
    self.startPrice = self.min + (self.max - self.min) / 2
    self.maxStep = data.maxStepSize
    self.stockInfluence = data.stockInfluence
    self.atlasPath = data.atlasPath
    self.atlasPart = data.atlasPart
    self.iconX = data.iconX
    self.iconY = data.iconY

    self.deltaPower = data.smoothOff
    if self.deltaPower and self.deltaPower % 2 == 0 then
        self.deltaPower = self.deltaPower + 1
    end

    self.triggers = data.triggers or {}
end

function stock:checkForData(data)
    if data["stocks"][self.name] == nil then
        self:loadDefault()
        data["stocks"][self.name] = self.exportData
    else
        self.exportData = data["stocks"][self.name]
    end

    -- Fix wrong order
    local points = {}
    for k, v in pairs(self.exportData.data) do
        points[k] = v
    end
    self.exportData.data = points
    self:checkForOverFlow()
end

function stock:loadDefault()
    self.exportData.owned = 0
    self.exportData.spent = 0
    self.exportData.data = {}
    -- Generate some initial data
    local currentValue = self.startPrice
        for i = 1, self.steps do
                currentValue = currentValue + self:getStep(true)
                self.exportData.data[i] = currentValue
        end
end

function stock:getMinMaxAdjustment() -- Trying to keep the price in min/max range
    local remaped = utils.remap(self:getCurrentPrice(), self.min, self.max, -1, 1)
    remaped = math.min(math.max(remaped, -1), 1)
    return remaped ^ self.deltaPower
end

function stock:getInfluence() -- Get amount of direct influence
    if #self.exportData.data ~= self.steps then return 0 end -- Ignore influence on initial data fill

    local totalInfluence = 0
    for _, st in pairs(self.market.stocks) do -- TODO: Buffer all influences on load
        for _, inf in pairs(st.stockInfluence) do
            if inf.name == self.name then
                totalInfluence = totalInfluence + (st:getTrend() / 16) * inf.amount -- TODO: Could buffer getTrend
            end
        end
    end
    return totalInfluence
end

function stock:getStep(default) -- Size of random step
    local rand = (math.random() * 2) - 1 -- Base random -1 -> 1

    rand = rand - self:getMinMaxAdjustment() -- Keep in bounds
    if default then
        rand = rand * self.maxStep
        return utils.round(rand, 2)
    end

    rand = rand + self.market.triggerManager:getStockDelta(self) -- Get triggers
    rand = rand + self:getInfluence() -- Direct influence

    rand = rand * self.maxStep -- Scale to range
    return utils.round(rand, 2)
end

function stock:update() -- Runs every intervall
    local shift = {}
    for i = 2, #self.exportData.data do -- Shift table, to remove first element
        shift[i - 1] = self.exportData.data[i]
    end

    local value = shift[#shift] + self:getStep() -- Calc new value
    shift[#shift + 1] = value
    self.exportData.data = shift

    self:checkForOverFlow()
end

function stock:checkForOverFlow()
    if self:getCurrentPrice() < self.min - self.min * 0.5 or self:getCurrentPrice() > self.max + self.max * 0.5 or self:getCurrentPrice() < 0 then
        self.market:overflowReset()
    end
end

return stock