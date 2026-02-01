local ink = require("modules/ui/inkHelper")
local color = require("modules/ui/color")
local lang = require("modules/utils/lang")
local Cron = require("modules/external/Cron")
local utils = require("modules/utils/utils")
local ConfigManager = require("modules/utils/ConfigManager")

info = {}

local function getThemeColor(name)
    local rgb = ConfigManager.getColor("ui.theme." .. name)
    return color.new(rgb.r, rgb.g, rgb.b, 1, 255)
end

local function getFont(name)
    return ConfigManager.getFont(name)
end

function info:new(inkPage, controller, eventCatcher, mod)
        local o = {}

        o.mod = mod
    o.inkPage = inkPage
        o.controller = controller
        o.eventCatcher = eventCatcher
        o.pageName = "stockInfo"

        o.canvas = nil
        o.refreshCron = nil

        o.stock = nil
        o.buySellVolume = 0

        self.__index = self
        return setmetatable(o, self)
end

function info:initialize(stock)
        self.refreshCron = Cron.Every(2, function ()
                self:refresh()
        end)

        self.buySellVolume = 0
        self.stock = stock
        self.canvas = ink.canvas(0, -70, inkEAnchor.TopLeft)
        self.canvas:Reparent(self.inkPage, -1)

        self.buttons = require("modules/ui/pages/menuButtons").createMenu(self)

        self:setupHeroHeader()
        self:setupChartSection()
        self:setupTradingPanel()
        self:showData()
end

function info:setupHeroHeader()
        local heroY = 280
        local heroW = 2800
        local heroH = 160
        
        local heroPanel = ink.canvas(80, heroY, inkEAnchor.TopLeft)
        heroPanel:SetSize(Vector2.new({X = heroW, Y = heroH}))
        heroPanel:Reparent(self.canvas, -1)
        self.heroPanel = heroPanel
        
        local heroBg = ink.image(heroW/2, heroH/2, heroW, heroH, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_bg")
        heroBg.image.useNineSliceScale = true
        heroBg.image:SetTintColor(color.new(15, 25, 40, 1, 255))
        heroBg.image:SetOpacity(0.95)
        heroBg.pos:Reparent(heroPanel, -1)
        
        local heroBorder = ink.image(heroW/2, heroH/2, heroW - 4, heroH - 4, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_fg")
        heroBorder.image.useNineSliceScale = true
        heroBorder.image:SetTintColor(color.new(94, 246, 255, 1, 255))
        heroBorder.image:SetOpacity(0.5)
        heroBorder.pos:Reparent(heroPanel, -1)
        
        self.heroIcon = ink.image(90, heroH/2, 120, 120, "", "")
        self.heroIcon.pos:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        self.heroIcon.pos:Reparent(heroPanel, -1)
        
        self.heroIcon.image:SetAtlasResource(ResRef.FromString(self.stock.atlasPath))
        self.heroIcon.image:SetTexturePart(self.stock.atlasPart)
        self.heroIcon.image:SetTintColor(HDRColor.new({ Red = 0.9, Green = 0.9, Blue = 0.9, Alpha = 1.0 }))
        
        local nameSize = 64
        if #self.stock.name > 20 then nameSize = 52
        elseif #self.stock.name > 15 then nameSize = 58 end
        
        self.heroName = ink.text(self.stock.name, 180, 50, nameSize, color.white)
        self.heroName:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        self.heroName:Reparent(heroPanel, -1)
        
        self.heroTicker = ink.text("TRADING TERMINAL", 180, 105, 32, color.new(94, 246, 255, 1, 255))
        self.heroTicker:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        self.heroTicker:Reparent(heroPanel, -1)
        
        local divider1 = ink.rect(850, 30, 3, heroH - 60, color.new(60, 80, 100, 1, 255))
        divider1:Reparent(heroPanel, -1)
        
        local priceLabel = ink.text("CURRENT PRICE", 900, 40, 28, color.new(200, 220, 240, 1, 255))
        priceLabel:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        priceLabel:Reparent(heroPanel, -1)
        
        self.heroPrice = ink.text("0 E$", 900, 100, 72, color.new(94, 246, 255, 1, 255))
        self.heroPrice:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        self.heroPrice:Reparent(heroPanel, -1)
        
        self.heroTrend = ink.text("+0%", 1250, 100, 56, color.lime)
        self.heroTrend:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        self.heroTrend:Reparent(heroPanel, -1)
        
        local divider2 = ink.rect(1450, 30, 3, heroH - 60, color.new(60, 80, 100, 1, 255))
        divider2:Reparent(heroPanel, -1)
        
        local ownedLabel = ink.text("YOUR POSITION", 1500, 40, 28, color.new(200, 220, 240, 1, 255))
        ownedLabel:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        ownedLabel:Reparent(heroPanel, -1)
        
        self.heroOwned = ink.text("0 SHARES", 1500, 100, 56, color.white)
        self.heroOwned:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        self.heroOwned:Reparent(heroPanel, -1)
        
        local divider3 = ink.rect(1950, 30, 3, heroH - 60, color.new(60, 80, 100, 1, 255))
        divider3:Reparent(heroPanel, -1)
        
        local valueLabel = ink.text("POSITION VALUE", 2000, 40, 28, color.new(200, 220, 240, 1, 255))
        valueLabel:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        valueLabel:Reparent(heroPanel, -1)
        
        self.heroValue = ink.text("0 E$", 2000, 100, 56, color.yellow)
        self.heroValue:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        self.heroValue:Reparent(heroPanel, -1)
        
        local divider4 = ink.rect(2400, 30, 3, heroH - 60, color.new(60, 80, 100, 1, 255))
        divider4:Reparent(heroPanel, -1)
        
        local plLabel = ink.text("UNREALIZED P/L", 2450, 40, 28, color.new(200, 220, 240, 1, 255))
        plLabel:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        plLabel:Reparent(heroPanel, -1)
        
        self.heroPL = ink.text("+0%", 2450, 100, 56, color.lime)
        self.heroPL:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        self.heroPL:Reparent(heroPanel, -1)
end

function info:setupChartSection()
        local chartX = 80
        local chartY = 460
        local chartW = 1700
        local chartH = 800
        
        local chartPanel = ink.canvas(chartX, chartY, inkEAnchor.TopLeft)
        chartPanel:SetSize(Vector2.new({X = chartW, Y = chartH}))
        chartPanel:Reparent(self.canvas, -1)
        
        local chartBg = ink.image(chartW/2, chartH/2, chartW, chartH, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_bg")
        chartBg.image.useNineSliceScale = true
        chartBg.image:SetTintColor(color.new(10, 14, 20, 1, 255))
        chartBg.image:SetOpacity(0.9)
        chartBg.pos:Reparent(chartPanel, -1)
        
        local chartTitle = ink.text("PRICE HISTORY", 40, 45, 44, color.new(94, 246, 255, 1, 255))
        chartTitle:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        chartTitle:Reparent(chartPanel, -1)
        
        local chartLine = ink.line(40, 80, chartW - 40, 80, color.new(60, 80, 100, 1, 255), 2)
        chartLine:Reparent(chartPanel, -1)
        
        self.graph = require("modules/ui/widgets/graph"):new(40, 100, chartW - 80, chartH - 140, 10, 5, "", "", 5, 40, color.new(20, 35, 55, 1, 255), 0.08)
        self.graph.intervall = self.mod.intervall
        self.graph.showXAxisLabels = false
        self.graph:initialize(chartPanel)
        self.graph.data = self.stock.exportData.data
        self.graph:showData()
end

function info:setupTradingPanel()
        local panelX = 1820
        local panelY = 460
        local panelW = 1060
        local panelH = 750
        
        local tradingPanel = ink.canvas(panelX, panelY, inkEAnchor.TopLeft)
        tradingPanel:SetSize(Vector2.new({X = panelW, Y = panelH}))
        tradingPanel:Reparent(self.canvas, -1)
        self.tradingPanel = tradingPanel
        
        local panelBg = ink.image(panelW/2, panelH/2, panelW, panelH, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_bg")
        panelBg.image.useNineSliceScale = true
        panelBg.image:SetTintColor(color.new(15, 22, 32, 1, 255))
        panelBg.image:SetOpacity(0.95)
        panelBg.pos:Reparent(tradingPanel, -1)
        
        local panelBorder = ink.image(panelW/2, panelH/2, panelW - 4, panelH - 4, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_fg")
        panelBorder.image.useNineSliceScale = true
        panelBorder.image:SetTintColor(color.new(94, 246, 255, 1, 255))
        panelBorder.image:SetOpacity(0.4)
        panelBorder.pos:Reparent(tradingPanel, -1)
        
        local tradeTitle = ink.text("EXECUTE TRADE", panelW/2, 45, 52, color.new(94, 246, 255, 1, 255))
        tradeTitle:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        tradeTitle:Reparent(tradingPanel, -1)
        
        local titleLine = ink.line(40, 85, panelW - 40, 85, color.new(94, 246, 255, 1, 255), 2)
        titleLine:SetOpacity(0.6)
        titleLine:Reparent(tradingPanel, -1)
        
        local balanceLabel = ink.text("AVAILABLE BALANCE", 60, 120, 42, color.new(200, 220, 240, 1, 255))
        balanceLabel:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        balanceLabel:Reparent(tradingPanel, -1)
        
        self.balanceValue = ink.text("0 E$", 60, 165, 52, color.lime)
        self.balanceValue:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        self.balanceValue:Reparent(tradingPanel, -1)
        
        local sharesLine = ink.line(40, 200, panelW - 40, 200, color.new(94, 246, 255, 1, 255), 2)
        sharesLine:SetOpacity(0.6)
        sharesLine:Reparent(tradingPanel, -1)
        
        local sharesLabel = ink.text("SHARES TO TRADE", panelW/2, 235, 44, color.new(200, 220, 240, 1, 255))
        sharesLabel:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        sharesLabel:Reparent(tradingPanel, -1)
        
        local btnSize = 100
        local btnSpacing = 12
        self.volumeButtons = {}
        
        local largeAmounts = {-500, -250, -50, 50, 250, 500}
        local totalLargeBtns = (btnSize * 6) + (btnSpacing * 5)
        local largeStartX = (panelW - totalLargeBtns) / 2
        local largeY = 275
        
        for i, amt in ipairs(largeAmounts) do
                local btnX = largeStartX + (i - 1) * (btnSize + btnSpacing)
                local btn = self:createVolumeButton(tradingPanel, btnX, largeY, btnSize, amt)
                table.insert(self.volumeButtons, btn)
        end
        
        local smallAmounts = {-25, -5, -1, 0, 1, 5, 25}
        local totalSmallBtns = (btnSize * 7) + (btnSpacing * 6)
        local smallStartX = (panelW - totalSmallBtns) / 2
        local smallY = 390
        
        for i, amt in ipairs(smallAmounts) do
                local btnX = smallStartX + (i - 1) * (btnSize + btnSpacing)
                local btn = self:createVolumeButton(tradingPanel, btnX, smallY, btnSize, amt)
                table.insert(self.volumeButtons, btn)
                if amt == 0 then
                        self.middleButton = btn
                end
        end
        
        local summaryY = 510
        local summaryLine = ink.line(40, summaryY, panelW - 40, summaryY, color.new(94, 246, 255, 1, 255), 2)
        summaryLine:SetOpacity(0.6)
        summaryLine:Reparent(tradingPanel, -1)
        
        local summaryTitle = ink.text("TRANSACTION SUMMARY", panelW/2, summaryY + 35, 44, color.new(200, 220, 240, 1, 255))
        summaryTitle:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        summaryTitle:Reparent(tradingPanel, -1)
        
        self.transText = ink.text("Select shares above", panelW/2, summaryY + 80, 48, color.white)
        self.transText:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        self.transText:Reparent(tradingPanel, -1)
        
        self.accountText = ink.text("", panelW/2, summaryY + 125, 44, color.white)
        self.accountText:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        self.accountText:Reparent(tradingPanel, -1)
        
        self.profitText = ink.text("", panelW/2, summaryY + 165, 44, color.white)
        self.profitText:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        self.profitText:Reparent(tradingPanel, -1)
        
        local actionLineY = summaryY + 210
        local actionLine = ink.line(40, actionLineY, panelW - 40, actionLineY, color.new(94, 246, 255, 1, 255), 2)
        actionLine:SetOpacity(0.6)
        actionLine:Reparent(tradingPanel, -1)
        
        local btnWidth = 200
        local btnHeight = 60
        local btnGap = 30
        local actionY = actionLineY + 50
        local btnCenterX = panelW / 2
        
        local confirmBtnY = actionLineY + 60
        
        local confirmCanvas = ink.canvas(panelW/2, confirmBtnY, inkEAnchor.TopLeft)
        confirmCanvas:SetSize(Vector2.new({X = btnWidth * 2 + btnGap, Y = btnHeight}))
        confirmCanvas:Reparent(tradingPanel, -1)
        
        local yesX = -btnWidth/2 - btnGap/2
        local yesBg = ink.image(yesX, btnHeight/2, btnWidth, btnHeight, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_bg")
        yesBg.image.useNineSliceScale = true
        yesBg.image:SetTintColor(color.new(30, 100, 50, 1, 255))
        yesBg.pos:SetInteractive(true)
        yesBg.pos:Reparent(confirmCanvas, -1)
        
        local yesFg = ink.image(yesX, btnHeight/2, btnWidth - 4, btnHeight - 4, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_fg")
        yesFg.image.useNineSliceScale = true
        yesFg.image:SetTintColor(color.lime)
        yesFg.pos:Reparent(confirmCanvas, -1)
        
        local yesText = ink.text("CONFIRM", yesX, btnHeight/2, 36, color.white)
        yesText:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        yesText:Reparent(confirmCanvas, -1)
        
        self.yesButton = {
                canvas = confirmCanvas,
                bg = yesBg,
                fg = yesFg,
                textWidget = yesText,
                eventCatcher = nil,
                clickCallback = function()
                        if self.buySellVolume == 0 then return end
                        self.stock:performTransaction(self.buySellVolume)
                        self.buySellVolume = 0
                        self:showData()
                        utils.playSound("ui_menu_onpress", 1)
                end,
                hoverInCallback = function() yesBg.image:SetOpacity(0.8) end,
                hoverOutCallback = function() yesBg.image:SetOpacity(1) end
        }
        
        self.yesButton.eventCatcher = sampleStyleManagerGameController.new()
        yesBg.pos:RegisterToCallback('OnPress', self.yesButton.eventCatcher, 'OnState1')
        yesBg.pos:RegisterToCallback('OnEnter', self.yesButton.eventCatcher, 'OnStyle1')
        yesBg.pos:RegisterToCallback('OnLeave', self.yesButton.eventCatcher, 'OnStyle2')
        table.insert(self.eventCatcher.subscribers, self.yesButton)
        
        local noX = btnWidth/2 + btnGap/2
        local noBg = ink.image(noX, btnHeight/2, btnWidth, btnHeight, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_bg")
        noBg.image.useNineSliceScale = true
        noBg.image:SetTintColor(color.new(100, 40, 40, 1, 255))
        noBg.pos:SetInteractive(true)
        noBg.pos:Reparent(confirmCanvas, -1)
        
        local noFg = ink.image(noX, btnHeight/2, btnWidth - 4, btnHeight - 4, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_fg")
        noFg.image.useNineSliceScale = true
        noFg.image:SetTintColor(color.red)
        noFg.pos:Reparent(confirmCanvas, -1)
        
        local noText = ink.text("CANCEL", noX, btnHeight/2, 36, color.white)
        noText:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        noText:Reparent(confirmCanvas, -1)
        
        self.noButton = {
                canvas = confirmCanvas,
                bg = noBg,
                fg = noFg,
                textWidget = noText,
                eventCatcher = nil,
                clickCallback = function()
                        self.buySellVolume = 0
                        self:showData()
                        utils.playSound("ui_menu_onpress", 1)
                        if self.controller and self.controller.switchToPage then self.controller:switchToPage("stocks") end
                end,
                hoverInCallback = function() noBg.image:SetOpacity(0.8) end,
                hoverOutCallback = function() noBg.image:SetOpacity(1) end
        }
        
        self.noButton.eventCatcher = sampleStyleManagerGameController.new()
        noBg.pos:RegisterToCallback('OnPress', self.noButton.eventCatcher, 'OnState1')
        noBg.pos:RegisterToCallback('OnEnter', self.noButton.eventCatcher, 'OnStyle1')
        noBg.pos:RegisterToCallback('OnLeave', self.noButton.eventCatcher, 'OnStyle2')
        table.insert(self.eventCatcher.subscribers, self.noButton)
end

function info:createVolumeButton(parent, x, y, size, amount)
        local btnCanvas = ink.canvas(x, y, inkEAnchor.TopLeft)
        btnCanvas:SetSize(Vector2.new({X = size, Y = size}))
        btnCanvas:SetInteractive(true)
        btnCanvas:Reparent(parent, -1)
        
        local isMiddle = (amount == 0)
        local bgColor = isMiddle and color.new(94, 246, 255, 1, 255) or color.new(30, 45, 60, 1, 255)
        local textColor = isMiddle and color.new(10, 15, 25, 1, 255) or color.white
        
        local btnBg = ink.image(size/2, size/2, size, size, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_bg")
        btnBg.image.useNineSliceScale = true
        btnBg.image:SetTintColor(bgColor)
        btnBg.pos:SetInteractive(true)
        btnBg.pos:Reparent(btnCanvas, -1)
        
        local btnBorder = ink.image(size/2, size/2, size - 4, size - 4, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_fg")
        btnBorder.image.useNineSliceScale = true
        btnBorder.image:SetTintColor(isMiddle and color.new(94, 246, 255, 1, 255) or color.new(80, 100, 120, 1, 255))
        btnBorder.pos:Reparent(btnCanvas, -1)
        
        local text = tostring(amount)
        if amount > 0 then text = "+" .. text end
        
        local btnText = ink.text(text, size/2, size/2, isMiddle and 48 or 40, textColor)
        btnText:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        btnText:Reparent(btnCanvas, -1)
        
        local pageRef = self
        
        local button = {
                canvas = btnCanvas,
                bg = btnBg,
                border = btnBorder,
                text = btnText,
                amount = amount,
                isMiddle = isMiddle,
                eventCatcher = nil,
                
                clickCallback = function(btn)
                        pageRef.buySellVolume = pageRef.buySellVolume + amount
                        if -pageRef.buySellVolume > pageRef.stock:getPortfolioNum() then
                                pageRef.buySellVolume = -pageRef.stock:getPortfolioNum()
                                if pageRef.buySellVolume == -0 then pageRef.buySellVolume = 0 end
                        elseif (Game.GetTransactionSystem():GetItemQuantity(GetPlayer(), MarketSystem.Money()) - (pageRef.buySellVolume * pageRef.stock:getCurrentPrice())) < 0 then
                                pageRef.buySellVolume = pageRef.buySellVolume - amount
                        end
                        utils.playSound("ui_menu_onpress", 1)
                        pageRef:showData()
                end,
                
                hoverInCallback = function(btn)
                        btnBg.image:SetTintColor(color.new(50, 70, 90, 1, 255))
                end,
                
                hoverOutCallback = function(btn)
                        btnBg.image:SetTintColor(color.new(30, 45, 60, 1, 255))
                end
        }
        
        if not isMiddle then
                button.eventCatcher = sampleStyleManagerGameController.new()
                btnBg.pos:RegisterToCallback('OnPress', button.eventCatcher, 'OnState1')
                btnBg.pos:RegisterToCallback('OnEnter', button.eventCatcher, 'OnStyle1')
                btnBg.pos:RegisterToCallback('OnLeave', button.eventCatcher, 'OnStyle2')
                
                table.insert(self.eventCatcher.subscribers, button)
        end
        
        return button
end

function info:showData()
        local currentPrice = self.stock:getCurrentPrice()
        local trend = self.stock:getTrend()
        local owned = self.stock:getPortfolioNum()
        local positionValue = owned * currentPrice
        local balance = Game.GetTransactionSystem():GetItemQuantity(GetPlayer(), MarketSystem.Money())
        
        self.heroPrice:SetText(tostring(currentPrice) .. " E$")
        
        local trendColor = trend >= 0 and color.lime or color.red
        local trendText = trend >= 0 and ("+" .. trend .. "%") or (trend .. "%")
        self.heroTrend:SetText(trendText)
        self.heroTrend:SetTintColor(trendColor)
        
        self.heroOwned:SetText(tostring(owned) .. " SHARES")
        self.heroValue:SetText(tostring(math.floor(positionValue)) .. " E$")
        
        local plPercent = 0
        local spent = self.stock.exportData.spent or 0
        if spent > 0 then
                plPercent = utils.round((self.stock:getUnrealizedProfit() / spent) * 100, 1)
        end
        local plColor = plPercent >= 0 and color.lime or color.red
        local plText = plPercent >= 0 and ("+" .. plPercent .. "%") or (plPercent .. "%")
        self.heroPL:SetText(plText)
        self.heroPL:SetTintColor(plColor)
        
        self.balanceValue:SetText(tostring(balance) .. " E$")
        
        if self.middleButton then
                self.middleButton.text:SetText(tostring(self.buySellVolume))
        end
        
        local transCost = math.abs(self.buySellVolume * currentPrice)
        
        if self.buySellVolume < 0 then
                self.transText:SetText("SELL " .. math.abs(self.buySellVolume) .. " SHARES")
                self.transText:SetTintColor(color.red)
                self.accountText:SetText("You receive: +" .. tostring(transCost) .. " E$")
                self.accountText:SetTintColor(color.lime)
                
                local profitLoss = self.stock:getProfit(self.buySellVolume)
                local profitColor = profitLoss >= 0 and color.lime or color.red
                local profitSign = profitLoss >= 0 and "+" or ""
                self.profitText:SetText("Profit/Loss: " .. profitSign .. tostring(profitLoss) .. " E$")
                self.profitText:SetTintColor(profitColor)
                
                if self.yesButton then
                        self.yesButton.textWidget:SetText("SELL")
                        self.yesButton.bg.image:SetTintColor(color.new(180, 50, 50, 1, 255))
                        self.yesButton.fg.image:SetTintColor(color.new(180, 50, 50, 1, 255))
                end
                
        elseif self.buySellVolume > 0 then
                self.transText:SetText("BUY " .. self.buySellVolume .. " SHARES")
                self.transText:SetTintColor(color.lime)
                self.accountText:SetText("Total cost: -" .. tostring(transCost) .. " E$")
                self.accountText:SetTintColor(color.red)
                
                local balanceAfter = balance - transCost
                self.profitText:SetText("Balance after: " .. tostring(balanceAfter) .. " E$")
                self.profitText:SetTintColor(color.white)
                
                if self.yesButton then
                        self.yesButton.textWidget:SetText("BUY")
                        self.yesButton.bg.image:SetTintColor(color.new(50, 180, 80, 1, 255))
                        self.yesButton.fg.image:SetTintColor(color.new(50, 180, 80, 1, 255))
                end
                
        else
                self.transText:SetText("Select shares above")
                self.transText:SetTintColor(color.white)
                self.accountText:SetText("")
                self.profitText:SetText("")
                
                if self.yesButton then
                        self.yesButton.textWidget:SetText("CONFIRM")
                        self.yesButton.bg.image:SetTintColor(color.new(60, 80, 100, 1, 255))
                        self.yesButton.fg.image:SetTintColor(color.new(60, 80, 100, 1, 255))
                end
        end
end

function info:calculateBuySellAmount(baseAmount)
        if math.abs(baseAmount) == 1 then return baseAmount end
        if baseAmount == 0 then return 0 end

        local factor = 200

        local amount
        if baseAmount < 0 and self.stock:getPortfolioNum() ~= 0 then
                amount = self.stock:getPortfolioNum() / (factor / baseAmount)
        else
                amount = Game.GetTransactionSystem():GetItemQuantity(GetPlayer(), MarketSystem.Money()) / self.stock:getCurrentPrice() / (factor / baseAmount)
        end

        if baseAmount < 0 then
                return math.min(math.floor((amount / 5) + 0.5) * 5, baseAmount)
        end

        return math.max(math.floor((amount / 5) + 0.5) * 5, baseAmount)
end

function info:refresh()
        self:showData()
        self.graph.data = self.stock.exportData.data
        self.graph:showData()
end

function info:uninitialize()
        Cron.Halt(self.refreshCron)
        if not self.canvas then return end
        self.inkPage:RemoveChild(self.canvas)
        self.inkPage:RemoveChild(self.buttons)
        self.canvas = nil
end

return info
