local ink = require("modules/ui/inkHelper")
local color = require("modules/ui/color")
local Cron = require("modules/external/Cron")
local utils = require("modules/utils/utils")
local lang = require("modules/utils/lang")

preview = {}

function preview:new(page)
        local o = {}

    o.x = 0
    o.y = 0
    o.sizeX = 1000
    o.sizeY = 200
    o.textSize = 110
    o.borderSize = 8

    o.fgColor = color.darkcyan
    o.bgColor = color.darkred
    o.textColor = color.white

    o.eventCatcher = nil
    o.cooldown = false
    o.page = page
    o.isSelected = false
    o.lastClickTime = 0

    o.bg = nil
    o.fg = nil
    o.clickArea = nil
    o.canvas = nil

    o.stock = nil
    o.stockIcon = nil
    o.stockName = nil
    o.stockPrice = nil
    o.stockTrend = nil

        self.__index = self
        return setmetatable(o, self)
end

function preview:initialize()
    local atlas = "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas"

    self.canvas = ink.canvas(self.x, self.y, inkEAnchor.TopLeft)
    self.canvas:SetSize(Vector2.new({X = self.sizeX, Y = self.sizeY}))
    self.canvas:SetInteractive(true)

    local halfW = self.sizeX / 2
    local halfH = self.sizeY / 2

    self.bg = ink.image(halfW, halfH, self.sizeX, self.sizeY, atlas, "cell_bg")
    self.bg.image.useNineSliceScale = true
    self.bg.image:SetTintColor(self.bgColor)
    self.bg.image:SetOpacity(0.95)
    self.bg.pos:Reparent(self.canvas, -1)

    self.fg = ink.image(halfW, halfH, self.sizeX - self.borderSize * 2, self.sizeY - self.borderSize * 2, atlas, "cell_fg")
    self.fg.image.useNineSliceScale = true
    self.fg.image:SetTintColor(self.fgColor)
    self.fg.pos:Reparent(self.canvas, -1)

    self.clickArea = ink.rect(halfW, halfH, self.sizeX, self.sizeY, color.new(0, 0, 0, 0, 255), 0, Vector2.new({X = 0.5, Y = 0.5}))
    self.clickArea:SetInteractive(true)
    self.clickArea:Reparent(self.canvas, -1)

    local maxIconSize = math.min(self.sizeY - self.borderSize * 4, 120)
    local iconX = self.borderSize * 2 + maxIconSize / 2 + 15
    self.stockIcon = ink.image(iconX, halfH, maxIconSize, maxIconSize, "", "")
    self.stockIcon.pos:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
    self.stockIcon.pos:Reparent(self.canvas, -1)

    local textStartX = iconX + maxIconSize / 2 + 25
    self.stockName = ink.text("", textStartX, halfH, self.textSize, self.textColor)
    self.stockName:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
    self.stockName:Reparent(self.canvas, -1)

    local priceX = self.sizeX - 350
    local priceSize = math.floor(self.textSize * 0.8)
    self.stockPrice = ink.text("", priceX, halfH, priceSize, self.textColor)
    self.stockPrice:SetAnchorPoint(Vector2.new({X = 1, Y = 0.5}))
    self.stockPrice:Reparent(self.canvas, -1)

    local trendX = self.sizeX - 40
    local trendSize = math.floor(self.textSize * 0.75)
    self.stockTrend = ink.text("", trendX, halfH, trendSize, color.lime)
    self.stockTrend:SetAnchorPoint(Vector2.new({X = 1, Y = 0.5}))
    self.stockTrend:Reparent(self.canvas, -1)
end

function preview:showData()
    if not self.stock then
        self.canvas:SetVisible(false)
        return
    end
    self.canvas:SetVisible(true)

    self.stockIcon.image:SetAtlasResource(ResRef.FromString(self.stock.atlasPath))
    self.stockIcon.image:SetTexturePart(self.stock.atlasPart)
    
    local maxIconSize = math.min(self.sizeY - self.borderSize * 4, 100)
    local iconScale = math.min(maxIconSize / self.stock.iconX, maxIconSize / self.stock.iconY)
    local scaledW = self.stock.iconX * iconScale
    local scaledH = self.stock.iconY * iconScale
    self.stockIcon.pos:SetSize(scaledW, scaledH)
    self.stockIcon.image:SetTintColor(HDRColor.new({ Red = 0.9, Green = 0.9, Blue = 0.9, Alpha = 1.0 }))

    local displayName = self.stock.name
    local maxNameWidth = self.sizeX - 350
    local avgCharWidth = self.textSize * 0.55
    local maxChars = math.floor(maxNameWidth / avgCharWidth)
    if #displayName > maxChars then
        displayName = string.sub(displayName, 1, maxChars - 2) .. ".."
    end
    self.stockName:SetText(displayName)

    local price = self.stock:getCurrentPrice()
    self.stockPrice:SetText(tostring(math.floor(price)) .. " E$")

    local trend = self.stock:getTrend()
    local trendColor = color.red
    local trendText = tostring(trend) .. "%"
    if trend > 0 then
        trendColor = color.lime
        trendText = "+" .. trendText
    elseif trend == 0 then
        trendColor = color.white
    end
    self.stockTrend:SetText(trendText)
    self.stockTrend:SetTintColor(trendColor)
end

function preview:refreshPriceOnly()
    if not self.stock then return end
    if not self.canvas:IsVisible() then return end
    
    local price = self.stock:getCurrentPrice()
    self.stockPrice:SetText(tostring(math.floor(price)) .. " E$")

    local trend = self.stock:getTrend()
    local trendColor = color.red
    local trendText = tostring(trend) .. "%"
    if trend > 0 then
        trendColor = color.lime
        trendText = "+" .. trendText
    elseif trend == 0 then
        trendColor = color.white
    end
    self.stockTrend:SetText(trendText)
    self.stockTrend:SetTintColor(trendColor)
end

function preview:setSelected(selected)
    self.isSelected = selected
    if selected then
        self.bg.image:SetTintColor(color.new(40, 60, 90, 1, 255))
        self.fg.image:SetTintColor(color.new(94, 246, 255, 1, 255))
    else
        self.bg.image:SetTintColor(self.bgColor)
        self.fg.image:SetTintColor(self.fgColor)
    end
end

function preview:registerCallbacks(catcher)
    self.eventCatcher = sampleStyleManagerGameController.new()

        self.clickArea:RegisterToCallback('OnPress', self.eventCatcher, 'OnState1')
        self.clickArea:RegisterToCallback('OnEnter', self.eventCatcher, 'OnStyle1')
        self.clickArea:RegisterToCallback('OnLeave', self.eventCatcher, 'OnStyle2')

    table.insert(catcher.subscribers, self)
end

function preview:registerCallbacksShared(catcher, sharedController)
    self.eventCatcher = sharedController

        self.clickArea:RegisterToCallback('OnPress', self.eventCatcher, 'OnState1')
        self.clickArea:RegisterToCallback('OnEnter', self.eventCatcher, 'OnStyle1')
        self.clickArea:RegisterToCallback('OnLeave', self.eventCatcher, 'OnStyle2')

    table.insert(catcher.subscribers, self)
end

function preview:hoverInCallback()
    if not self.isSelected then
        self.bg.image:SetOpacity(0.7)
    end
end

function preview:hoverOutCallback()
    if not self.isSelected then
        self.bg.image:SetOpacity(0.95)
    end
end

function preview:clickCallback()
    if not self.stock then return end
    if self.cooldown then return end
    self.cooldown = true
    Cron.NextTick(function()
        self.cooldown = false
    end)
    utils.playSound("ui_menu_onpress", 1)

    local currentTime = os.clock()
    local timeDiff = currentTime - self.lastClickTime
    self.lastClickTime = currentTime

    if timeDiff < 0.4 then
        if self.page and self.page.controller then
            self.page.controller.currentInfoStock = self.stock
            self.page.controller:switchToPage("stockInfo")
        end
    else
        if self.page and self.page.selectStock then
            self.page:selectStock(self)
        else
            if self.page and self.page.controller then
                self.page.controller.currentInfoStock = self.stock
                self.page.controller:switchToPage("stockInfo")
            end
        end
    end
end

return preview
