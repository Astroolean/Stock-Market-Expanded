local ink = require("modules/ui/inkHelper")
local color = require("modules/ui/color")
local lang = require("modules/utils/lang")
local Cron = require("modules/external/Cron")
local utils = require("modules/utils/utils")

home = {}

function home:new(inkPage, controller, eventCatcher, mod)
        local o = {}

        o.mod = mod
    o.inkPage = inkPage
        o.controller = controller
        o.eventCatcher = eventCatcher
        o.pageName = "home"

        o.canvas = nil
        o.refreshCron = nil
        o.previews = {}
        o.gainers = {}
        o.losers = {}

        self.__index = self
        return setmetatable(o, self)
end

function home:initialize()
        self.refreshCron = Cron.Every(5, function ()
                self:refresh()
        end)

        self.canvas = ink.canvas(0, -70, inkEAnchor.TopLeft)
        self.canvas:Reparent(self.inkPage, -1)

        self.buttons = require("modules/ui/pages/menuButtons").createMenu(self)

        self:setupHeroSection()
        self:setupMarketStats()
        self:setupGainersPanel()
        self:setupLosersPanel()
        self:setupHelpButton()
        self:setupHelpOverlay()
        
        self:setStocks()
        self:refreshData()
end

function home:setupHeroSection()
        local heroY = 280
        local fullWidth = 2600
        local heroH = 240
        
        local heroPanel = ink.canvas(80, heroY, inkEAnchor.TopLeft)
        heroPanel:SetSize(Vector2.new({X = fullWidth, Y = heroH}))
        heroPanel:Reparent(self.canvas, -1)
        self.heroPanel = heroPanel
        
        local heroBg = ink.image(fullWidth/2, heroH/2, fullWidth, heroH, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_bg")
        heroBg.image.useNineSliceScale = true
        heroBg.image:SetTintColor(color.new(15, 25, 40, 1, 255))
        heroBg.image:SetOpacity(0.95)
        heroBg.pos:Reparent(heroPanel, -1)
        
        local heroBorder = ink.image(fullWidth/2, heroH/2, fullWidth - 4, heroH - 4, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_fg")
        heroBorder.image.useNineSliceScale = true
        heroBorder.image:SetTintColor(color.new(94, 246, 255, 1, 255))
        heroBorder.image:SetOpacity(0.5)
        heroBorder.pos:Reparent(heroPanel, -1)
        
        local marketLabel = ink.text("NC STOCK EXCHANGE", 40, 45, 36, color.new(94, 246, 255, 1, 255))
        marketLabel:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        marketLabel:Reparent(heroPanel, -1)
        
        local etfLabel = ink.text("NC ETF INDEX", 40, 100, 56, color.white)
        etfLabel:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        etfLabel:Reparent(heroPanel, -1)
        
        self.heroPrice = ink.text("0 E$", 40, 170, 60, color.new(94, 246, 255, 1, 255))
        self.heroPrice:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        self.heroPrice:Reparent(heroPanel, -1)
        
        self.heroTrend = ink.text("+0%", 380, 170, 52, color.lime)
        self.heroTrend:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        self.heroTrend:Reparent(heroPanel, -1)
        
        self.sentimentLabel = ink.text("BULL MARKET", 680, 170, 52, color.lime)
        self.sentimentLabel:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        self.sentimentLabel:Reparent(heroPanel, -1)
        
        local graphX = 1100
        local graphY = heroY
        local graphW = 1400
        local graphH = heroH
        
        self.graph = require("modules/ui/widgets/graph"):new(graphX, graphY, graphW, graphH, 6, 3, "", "", 3, 24, color.new(20, 35, 55, 1, 255), 0.9)
        self.graph.intervall = self.mod.intervall
        self.graph.showXAxisLabels = false
        self.graph.showYAxisLabels = false
        self.graph:initialize(self.canvas)
        self.graph.data = self.mod.market.marketStock.exportData.data
        self.graph:showData()
end

function home:setupMarketStats()
        local statsY = 540
        local statsW = 2740
        local statsH = 150
        local statsPanel = ink.canvas(80, statsY, inkEAnchor.TopLeft)
        statsPanel:SetSize(Vector2.new({X = statsW, Y = statsH}))
        statsPanel:Reparent(self.canvas, -1)
        self.statsPanel = statsPanel
        
        local statsBg = ink.image(statsW/2, statsH/2, statsW, statsH, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_bg")
        statsBg.image.useNineSliceScale = true
        statsBg.image:SetTintColor(color.new(20, 30, 45, 1, 255))
        statsBg.image:SetOpacity(0.85)
        statsBg.pos:Reparent(statsPanel, -1)
        
        local colSpacing = (statsW - 100) / 7
        local stats = {
                {label = "TOTAL STOCKS", x = 50, valueKey = "totalStocks"},
                {label = "GAINERS", x = 50 + colSpacing, valueKey = "gainersCount"},
                {label = "LOSERS", x = 50 + colSpacing * 2, valueKey = "losersCount"},
                {label = "YOUR PORTFOLIO", x = 50 + colSpacing * 3, valueKey = "portfolioValue"},
                {label = "OWNED STOCKS", x = 50 + colSpacing * 4, valueKey = "ownedCount"},
                {label = "MARKET STATUS", x = 50 + colSpacing * 5, valueKey = "marketStatus"},
                {label = "SECURITY SCORE", x = 50 + colSpacing * 6, valueKey = "securityScore"}
        }
        
        self.statLabels = {}
        self.statValues = {}
        
        for i, stat in ipairs(stats) do
                local label = ink.text(stat.label, stat.x, 40, 36, color.new(200, 220, 240, 1, 255))
                label:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
                label:Reparent(statsPanel, -1)
                
                local value = ink.text("--", stat.x, 105, 56, color.white)
                value:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
                value:Reparent(statsPanel, -1)
                
                self.statLabels[stat.valueKey] = label
                self.statValues[stat.valueKey] = value
        end
        
end

function home:setupGainersPanel()
        local panelX = 80
        local panelY = 710
        local panelW = 1340
        local panelH = 580
        
        local panel = ink.canvas(panelX, panelY, inkEAnchor.TopLeft)
        panel:SetSize(Vector2.new({X = panelW, Y = panelH}))
        panel:Reparent(self.canvas, -1)
        self.gainersPanel = panel
        
        local panelBg = ink.image(panelW/2, panelH/2, panelW, panelH, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_bg")
        panelBg.image.useNineSliceScale = true
        panelBg.image:SetTintColor(color.new(15, 25, 40, 1, 255))
        panelBg.image:SetOpacity(0.9)
        panelBg.pos:Reparent(panel, -1)
        
        local headerBg = ink.image(panelW/2, 40, panelW - 8, 70, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_bg")
        headerBg.image.useNineSliceScale = true
        headerBg.image:SetTintColor(color.new(30, 80, 50, 1, 255))
        headerBg.image:SetOpacity(0.6)
        headerBg.pos:Reparent(panel, -1)
        
        local title = ink.text("TOP GAINERS", 30, 40, 48, color.lime)
        title:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        title:Reparent(panel, -1)
        
        local divider = ink.line(20, 80, panelW - 20, 80, color.new(60, 180, 80, 1, 255), 2)
        divider:SetOpacity(0.5)
        divider:Reparent(panel, -1)
        
        local startY = 100
        local itemHeight = 120
        for i = 1, 4 do
                local preview = self:createStockCard(panel, 25, startY + (i-1) * itemHeight, panelW - 50, 110, true)
                table.insert(self.gainers, preview)
                table.insert(self.previews, preview)
        end
end

function home:setupLosersPanel()
        local panelX = 1480
        local panelY = 710
        local panelW = 1340
        local panelH = 580
        
        local panel = ink.canvas(panelX, panelY, inkEAnchor.TopLeft)
        panel:SetSize(Vector2.new({X = panelW, Y = panelH}))
        panel:Reparent(self.canvas, -1)
        self.losersPanel = panel
        
        local panelBg = ink.image(panelW/2, panelH/2, panelW, panelH, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_bg")
        panelBg.image.useNineSliceScale = true
        panelBg.image:SetTintColor(color.new(15, 25, 40, 1, 255))
        panelBg.image:SetOpacity(0.9)
        panelBg.pos:Reparent(panel, -1)
        
        local headerBg = ink.image(panelW/2, 40, panelW - 8, 70, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_bg")
        headerBg.image.useNineSliceScale = true
        headerBg.image:SetTintColor(color.new(100, 40, 40, 1, 255))
        headerBg.image:SetOpacity(0.6)
        headerBg.pos:Reparent(panel, -1)
        
        local title = ink.text("TOP LOSERS", 30, 40, 48, color.red)
        title:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        title:Reparent(panel, -1)
        
        local divider = ink.line(20, 80, panelW - 20, 80, color.new(180, 60, 60, 1, 255), 2)
        divider:SetOpacity(0.5)
        divider:Reparent(panel, -1)
        
        local startY = 100
        local itemHeight = 120
        for i = 1, 4 do
                local preview = self:createStockCard(panel, 25, startY + (i-1) * itemHeight, panelW - 50, 110, false)
                table.insert(self.losers, preview)
                table.insert(self.previews, preview)
        end
end

function home:createStockCard(parent, x, y, w, h, isGainer)
        local card = {}
        
        local cardCanvas = ink.canvas(x, y, inkEAnchor.TopLeft)
        cardCanvas:SetSize(Vector2.new({X = w, Y = h}))
        cardCanvas:SetInteractive(true)
        cardCanvas:Reparent(parent, -1)
        card.canvas = cardCanvas
        
        local accentColor = isGainer and color.new(40, 100, 60, 1, 255) or color.new(100, 40, 40, 1, 255)
        local textAccent = isGainer and color.lime or color.red
        
        local cardBg = ink.image(w/2, h/2, w, h, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_bg")
        cardBg.image.useNineSliceScale = true
        cardBg.image:SetTintColor(color.new(25, 35, 50, 1, 255))
        cardBg.image:SetOpacity(0.9)
        cardBg.pos:SetInteractive(true)
        cardBg.pos:Reparent(cardCanvas, -1)
        card.bg = cardBg
        
        local accent = ink.image(6, h/2, 8, h - 16, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_bg")
        accent.image.useNineSliceScale = true
        accent.image:SetTintColor(textAccent)
        accent.pos:Reparent(cardCanvas, -1)
        
        card.icon = ink.image(70, h/2, 80, 80, "", "")
        card.icon.pos:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        card.icon.pos:Reparent(cardCanvas, -1)
        
        card.name = ink.text("", 130, h/2 - 22, 52, color.white)
        card.name:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        card.name:Reparent(cardCanvas, -1)
        
        card.sector = ink.text("", 130, h/2 + 28, 32, color.new(200, 220, 240, 1, 255))
        card.sector:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        card.sector:Reparent(cardCanvas, -1)
        
        card.price = ink.text("", w - 220, h/2, 56, color.white)
        card.price:SetAnchorPoint(Vector2.new({X = 1, Y = 0.5}))
        card.price:Reparent(cardCanvas, -1)
        
        card.trend = ink.text("", w - 30, h/2, 52, textAccent)
        card.trend:SetAnchorPoint(Vector2.new({X = 1, Y = 0.5}))
        card.trend:Reparent(cardCanvas, -1)
        
        card.stock = nil
        card.isGainer = isGainer
        card.page = self
        
        local eventCatcher = sampleStyleManagerGameController.new()
        cardBg.pos:RegisterToCallback('OnPress', eventCatcher, 'OnState1')
        cardBg.pos:RegisterToCallback('OnEnter', eventCatcher, 'OnStyle1')
        cardBg.pos:RegisterToCallback('OnLeave', eventCatcher, 'OnStyle2')
        
        card.eventCatcher = eventCatcher
        card.hoverInCallback = function()
                if card.stock then
                        cardBg.image:SetOpacity(0.7)
                end
        end
        card.hoverOutCallback = function()
                if card.stock then
                        cardBg.image:SetOpacity(0.9)
                end
        end
        card.clickCallback = function()
                if card.stock then
                        utils.playSound("ui_menu_onpress", 1)
                        self.controller.currentInfoStock = card.stock
                        self.controller:switchToPage("stockInfo")
                end
        end
        
        table.insert(self.eventCatcher.subscribers, card)
        
        return card
end

function home:updateStockCard(card)
        if not card.stock then
                card.canvas:SetVisible(false)
                return
        end
        card.canvas:SetVisible(true)
        
        card.icon.image:SetAtlasResource(ResRef.FromString(card.stock.atlasPath))
        card.icon.image:SetTexturePart(card.stock.atlasPart)
        card.icon.image:SetTintColor(HDRColor.new({ Red = 0.9, Green = 0.9, Blue = 0.9, Alpha = 1.0 }))
        
        local displayName = card.stock.name
        if #displayName > 22 then
                displayName = string.sub(displayName, 1, 20) .. ".."
        end
        card.name:SetText(displayName)
        
        local sector = card.stock.sector or "CORPORATION"
        card.sector:SetText(sector)
        
        local price = card.stock:getCurrentPrice()
        card.price:SetText(tostring(math.floor(price)) .. " E$")
        
        local trend = card.stock:getTrend()
        local trendText = tostring(trend) .. "%"
        if trend > 0 then
                trendText = "+" .. trendText
                card.trend:SetTintColor(color.lime)
        elseif trend < 0 then
                card.trend:SetTintColor(color.red)
        else
                card.trend:SetTintColor(color.white)
        end
        card.trend:SetText(trendText)
end


function home:setStocks()
        local allStocks = {}
        for _, stock in pairs(self.mod.market.stocks) do
                table.insert(allStocks, stock)
        end
        
        table.sort(allStocks, function(a, b)
                return a:getTrend() > b:getTrend()
        end)
        
        for i = 1, 4 do
                if self.gainers[i] then
                        self.gainers[i].stock = allStocks[i]
                end
        end
        
        for i = 1, 4 do
                if self.losers[i] then
                        self.losers[i].stock = allStocks[#allStocks - i + 1]
                end
        end
end

function home:refreshData()
        local mStock = self.mod.market.marketStock
        local price = mStock:getCurrentPrice()
        local trend = mStock:getTrend()
        
        self.heroPrice:SetText(tostring(math.floor(price)) .. " E$")
        
        local trendText = tostring(trend) .. "%"
        if trend > 0 then
                trendText = "+" .. trendText
                self.heroTrend:SetTintColor(color.lime)
                self.sentimentLabel:SetText("BULL MARKET")
                self.sentimentLabel:SetTintColor(color.lime)
        elseif trend < 0 then
                self.heroTrend:SetTintColor(color.red)
                self.sentimentLabel:SetText("BEAR MARKET")
                self.sentimentLabel:SetTintColor(color.red)
        else
                self.heroTrend:SetTintColor(color.white)
                self.sentimentLabel:SetText("NEUTRAL")
                self.sentimentLabel:SetTintColor(color.white)
        end
        self.heroTrend:SetText(trendText)
        
        local totalStocks = 0
        local gainersCount = 0
        local losersCount = 0
        local ownedCount = 0
        local portfolioValue = 0
        
        for _, stock in pairs(self.mod.market.stocks) do
                totalStocks = totalStocks + 1
                local t = stock:getTrend()
                if t > 0 then
                        gainersCount = gainersCount + 1
                elseif t <= 0 then
                        losersCount = losersCount + 1
                end
                local owned = stock:getPortfolioNum()
                if owned > 0 then
                        ownedCount = ownedCount + 1
                        portfolioValue = portfolioValue + (owned * stock:getCurrentPrice())
                end
        end
        
        if self.statValues.totalStocks then
                self.statValues.totalStocks:SetText(tostring(totalStocks))
        end
        if self.statValues.gainersCount then
                self.statValues.gainersCount:SetText(tostring(gainersCount))
                self.statValues.gainersCount:SetTintColor(color.lime)
        end
        if self.statValues.losersCount then
                self.statValues.losersCount:SetText(tostring(losersCount))
                self.statValues.losersCount:SetTintColor(color.red)
        end
        if self.statValues.portfolioValue then
                self.statValues.portfolioValue:SetText(tostring(math.floor(portfolioValue)) .. " E$")
                if portfolioValue > 0 then
                        self.statValues.portfolioValue:SetTintColor(color.new(255, 200, 50, 1, 255))
                end
        end
        if self.statValues.ownedCount then
                self.statValues.ownedCount:SetText(tostring(ownedCount))
                if ownedCount > 0 then
                        self.statValues.ownedCount:SetTintColor(color.new(255, 200, 50, 1, 255))
                end
        end
        if self.statValues.marketStatus then
                if gainersCount > losersCount then
                        self.statValues.marketStatus:SetText("BULLISH")
                        self.statValues.marketStatus:SetTintColor(color.lime)
                elseif losersCount > gainersCount then
                        self.statValues.marketStatus:SetText("BEARISH")
                        self.statValues.marketStatus:SetTintColor(color.red)
                else
                        self.statValues.marketStatus:SetText("NEUTRAL")
                        self.statValues.marketStatus:SetTintColor(color.white)
                end
        end
        
        if self.statValues.securityScore then
                local securityScore = 50
                local success, report = pcall(function()
                        if self.mod and self.mod.market and self.mod.market.securityManager then
                                return self.mod.market.securityManager:getSecurityReport()
                        end
                        return nil
                end)
                if success and report and report.score then
                        securityScore = report.score
                end
                
                self.statValues.securityScore:SetText(tostring(securityScore) .. "/100")
                if securityScore >= 80 then
                        self.statValues.securityScore:SetTintColor(color.lime)
                elseif securityScore >= 60 then
                        self.statValues.securityScore:SetTintColor(color.cyan)
                elseif securityScore >= 40 then
                        self.statValues.securityScore:SetTintColor(color.new(255, 200, 50, 1, 255))
                elseif securityScore >= 20 then
                        self.statValues.securityScore:SetTintColor(color.orange)
                else
                        self.statValues.securityScore:SetTintColor(color.red)
                end
        end
        
        for _, card in pairs(self.gainers) do
                self:updateStockCard(card)
        end
        for _, card in pairs(self.losers) do
                self:updateStockCard(card)
        end
        
        self.graph.data = self.mod.market.marketStock.exportData.data
        self.graph:showData()
end

function home:refresh()
        self:setStocks()
        self:refreshData()
end

function home:setupHelpButton()
        self.helpButton = require("modules/ui/widgets/button_texture"):new()
        self.helpButton.x = 2600
        self.helpButton.y = 340
        self.helpButton.sizeX = 80
        self.helpButton.sizeY = 80
        self.helpButton.textSize = 48
        self.helpButton.text = "?"
        self.helpButton.bgPart = "cell_bg"
        self.helpButton.fgPart = "cell_fg"
        self.helpButton.bgColor = color.new(30, 45, 60, 1, 255)
        self.helpButton.fgColor = color.cyan
        self.helpButton.textColor = color.cyan
        self.helpButton.useNineSlice = true

        self.helpButton.callback = function()
                self:toggleHelp()
        end

        self.helpButton:initialize()
        self.helpButton:registerCallbacks(self.eventCatcher)
        self.helpButton.canvas:Reparent(self.canvas, -1)
end

function home:setupHelpOverlay()
        self.helpVisible = false
        self.helpCanvas = ink.canvas(80, 250, inkEAnchor.TopLeft)
        self.helpCanvas:Reparent(self.canvas, -1)
        self.helpCanvas:SetVisible(false)

        local panelW = 2700
        local panelH = 900

        local bgRect = ink.rect(0, 0, panelW, panelH, HDRColor.new({ Red = 0.03, Green = 0.06, Blue = 0.08, Alpha = 0.98 }))
        bgRect:Reparent(self.helpCanvas, -1)

        local borderTop = ink.rect(0, 0, panelW, 4, color.cyan)
        borderTop:Reparent(self.helpCanvas, -1)

        local borderBottom = ink.rect(0, panelH - 4, panelW, 4, color.cyan)
        borderBottom:Reparent(self.helpCanvas, -1)

        local borderLeft = ink.rect(0, 0, 4, panelH, color.cyan)
        borderLeft:Reparent(self.helpCanvas, -1)

        local borderRight = ink.rect(panelW - 4, 0, 4, panelH, color.cyan)
        borderRight:Reparent(self.helpCanvas, -1)

        local helpTitle = ink.text("STOCK MARKET GUIDE", panelW / 2, 50, 64, color.cyan)
        helpTitle:SetAnchorPoint(0.5, 0.5)
        helpTitle:Reparent(self.helpCanvas, -1)

        local subtitle = ink.text("Everything you need to know about trading in Night City", panelW / 2, 100, 36, color.new(200, 220, 240, 1, 255))
        subtitle:SetAnchorPoint(0.5, 0.5)
        subtitle:Reparent(self.helpCanvas, -1)

        local dividerTop = ink.rect(60, 140, panelW - 120, 3, color.cyan)
        dividerTop:SetOpacity(0.6)
        dividerTop:Reparent(self.helpCanvas, -1)

        local col1X = 80
        local col2X = 980
        local col3X = 1880

        local sec1Title = ink.text("UNDERSTANDING THE MARKET", col1X, 190, 44, color.cyan)
        sec1Title:Reparent(self.helpCanvas, -1)

        local sec1Line1 = ink.text("NC ETF INDEX", col1X, 260, 36, color.white)
        sec1Line1:Reparent(self.helpCanvas, -1)
        local sec1Desc1 = ink.text("The NC ETF Index tracks the overall health of Night City's", col1X, 305, 30, color.new(180, 190, 200, 1, 255))
        sec1Desc1:Reparent(self.helpCanvas, -1)
        local sec1Desc1b = ink.text("economy. When it's up, most stocks are rising!", col1X, 340, 30, color.new(180, 190, 200, 1, 255))
        sec1Desc1b:Reparent(self.helpCanvas, -1)

        local sec1Line2 = ink.text("BULL VS BEAR MARKET", col1X, 410, 36, color.white)
        sec1Line2:Reparent(self.helpCanvas, -1)
        local sec1Desc2 = ink.text("Bull = prices rising (good time to sell)", col1X, 455, 30, color.lime)
        sec1Desc2:Reparent(self.helpCanvas, -1)
        local sec1Desc2b = ink.text("Bear = prices falling (good time to buy)", col1X, 490, 30, color.red)
        sec1Desc2b:Reparent(self.helpCanvas, -1)

        local sec1Line3 = ink.text("TOP GAINERS & LOSERS", col1X, 560, 36, color.white)
        sec1Line3:Reparent(self.helpCanvas, -1)
        local sec1Desc3 = ink.text("Shows which stocks are moving the most right now.", col1X, 605, 30, color.new(180, 190, 200, 1, 255))
        sec1Desc3:Reparent(self.helpCanvas, -1)
        local sec1Desc3b = ink.text("Great for finding quick trading opportunities!", col1X, 640, 30, color.new(180, 190, 200, 1, 255))
        sec1Desc3b:Reparent(self.helpCanvas, -1)

        local sec2Title = ink.text("HOW TO TRADE", col2X, 190, 44, color.cyan)
        sec2Title:Reparent(self.helpCanvas, -1)

        local sec2Line1 = ink.text("STOCKS TAB", col2X, 260, 36, color.white)
        sec2Line1:Reparent(self.helpCanvas, -1)
        local sec2Desc1 = ink.text("Browse all 128 corporations available for trading.", col2X, 305, 30, color.new(180, 190, 200, 1, 255))
        sec2Desc1:Reparent(self.helpCanvas, -1)
        local sec2Desc1b = ink.text("Click any stock to see details and buy/sell.", col2X, 340, 30, color.new(180, 190, 200, 1, 255))
        sec2Desc1b:Reparent(self.helpCanvas, -1)

        local sec2Line2 = ink.text("PORTFOLIO TAB", col2X, 410, 36, color.white)
        sec2Line2:Reparent(self.helpCanvas, -1)
        local sec2Desc2 = ink.text("View all stocks you currently own, track your", col2X, 455, 30, color.new(180, 190, 200, 1, 255))
        sec2Desc2:Reparent(self.helpCanvas, -1)
        local sec2Desc2b = ink.text("profits and losses, and manage your investments.", col2X, 490, 30, color.new(180, 190, 200, 1, 255))
        sec2Desc2b:Reparent(self.helpCanvas, -1)

        local sec2Line3 = ink.text("NEWS TAB", col2X, 560, 36, color.white)
        sec2Line3:Reparent(self.helpCanvas, -1)
        local sec2Desc3 = ink.text("Stay informed about market-moving events!", col2X, 605, 30, color.new(180, 190, 200, 1, 255))
        sec2Desc3:Reparent(self.helpCanvas, -1)
        local sec2Desc3b = ink.text("News can affect stock prices dramatically.", col2X, 640, 30, color.new(180, 190, 200, 1, 255))
        sec2Desc3b:Reparent(self.helpCanvas, -1)

        local sec3Title = ink.text("PROTECTING YOUR ASSETS", col3X, 190, 44, color.cyan)
        sec3Title:Reparent(self.helpCanvas, -1)

        local sec3Line1 = ink.text("SECURITY SCORE (0-100)", col3X, 260, 36, color.white)
        sec3Line1:Reparent(self.helpCanvas, -1)
        local sec3Desc1 = ink.text("Your protection level against hackers. Higher is", col3X, 305, 30, color.new(180, 190, 200, 1, 255))
        sec3Desc1:Reparent(self.helpCanvas, -1)
        local sec3Desc1b = ink.text("better! Low score = risk of losing your stocks.", col3X, 340, 30, color.new(180, 190, 200, 1, 255))
        sec3Desc1b:Reparent(self.helpCanvas, -1)

        local sec3Line2 = ink.text("INSURANCE TAB", col3X, 410, 36, color.white)
        sec3Line2:Reparent(self.helpCanvas, -1)
        local sec3Desc2 = ink.text("Purchase insurance plans to protect your portfolio", col3X, 455, 30, color.new(180, 190, 200, 1, 255))
        sec3Desc2:Reparent(self.helpCanvas, -1)
        local sec3Desc2b = ink.text("from hackers, crashes, and other threats.", col3X, 490, 30, color.new(180, 190, 200, 1, 255))
        sec3Desc2b:Reparent(self.helpCanvas, -1)

        local sec3Line3 = ink.text("ALWAYS LOG OUT PROPERLY!", col3X, 560, 36, color.yellow)
        sec3Line3:Reparent(self.helpCanvas, -1)
        local sec3Desc3 = ink.text("Using the Logout button improves your security", col3X, 605, 30, color.new(180, 190, 200, 1, 255))
        sec3Desc3:Reparent(self.helpCanvas, -1)
        local sec3Desc3b = ink.text("score. Closing without logout is risky!", col3X, 640, 30, color.new(180, 190, 200, 1, 255))
        sec3Desc3b:Reparent(self.helpCanvas, -1)

        local tipBg = ink.rect(60, 710, panelW - 120, 80, color.new(40, 60, 80, 1, 255))
        tipBg:Reparent(self.helpCanvas, -1)

        local tipText = ink.text("PRO TIP: Buy low during Bear markets, sell high during Bull markets. Watch the news for insider info!", panelW / 2, 750, 40, color.yellow)
        tipText:SetAnchorPoint(0.5, 0.5)
        tipText:Reparent(self.helpCanvas, -1)

        self.closeHelpButton = require("modules/ui/widgets/button_texture"):new()
        self.closeHelpButton.x = panelW / 2
        self.closeHelpButton.y = 850
        self.closeHelpButton.sizeX = 300
        self.closeHelpButton.sizeY = 70
        self.closeHelpButton.textSize = 44
        self.closeHelpButton.text = "GOT IT!"
        self.closeHelpButton.bgPart = "cell_bg"
        self.closeHelpButton.fgPart = "cell_fg"
        self.closeHelpButton.bgColor = color.cyan
        self.closeHelpButton.fgColor = color.cyan
        self.closeHelpButton.textColor = color.white
        self.closeHelpButton.useNineSlice = true

        self.closeHelpButton.callback = function()
                self:toggleHelp()
        end

        self.closeHelpButton:initialize()
        self.closeHelpButton:registerCallbacks(self.eventCatcher)
        self.closeHelpButton.canvas:Reparent(self.helpCanvas, -1)
end

function home:toggleHelp()
        self.helpVisible = not self.helpVisible
        if self.helpVisible then
                self.helpCanvas:Reparent(self.canvas, -1)
        end
        self.helpCanvas:SetVisible(self.helpVisible)
end

function home:uninitialize()
        Cron.Halt(self.refreshCron)

        if not self.canvas then return end
        if self.helpCanvas then
                self.helpCanvas:SetVisible(false)
        end
        for _, preview in pairs(self.previews) do
                if preview.eventCatcher then
                        self.eventCatcher.removeSubscriber(preview)
                end
        end
        self.previews = {}
        self.gainers = {}
        self.losers = {}
        self.inkPage:RemoveChild(self.canvas)
        self.inkPage:RemoveChild(self.buttons)
        self.canvas = nil
end

return home
