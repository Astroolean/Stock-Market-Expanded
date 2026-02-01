local ink = require("modules/ui/inkHelper")
local color = require("modules/ui/color")
local lang = require("modules/utils/lang")
local Cron = require("modules/external/Cron")
local utils = require("modules/utils/utils")
local UIScroller = require("modules/external/UIScroller")
local ConfigManager = require("modules/utils/ConfigManager")

stocks = {}

local function getThemeColor(name)
    local rgb = ConfigManager.getColor("ui.theme." .. name)
    return color.new(rgb.r, rgb.g, rgb.b, 1, 255)
end

local function getFont(name)
    return ConfigManager.getFont(name)
end

local function getLayout(name)
    return ConfigManager.getLayout(name)
end

function stocks:new(inkPage, controller, eventCatcher, mod)
        local o = {}

        o.mod = mod
    o.inkPage = inkPage
        o.controller = controller
        o.eventCatcher = eventCatcher
        o.pageName = "stocks"

        o.canvas = nil
        o.refreshCron = nil
        o.previews = {}
        o.sort = "ascAlpha"
        o.filter = "all"
        o.sortButtons = {}
        o.filterButtons = {}
        o.selectedPreview = nil
        o.selectedStock = nil
        o.scrollComponent = nil
        o.isUserScrolling = false
        o.scrollCooldownCron = nil

        self.__index = self
        return setmetatable(o, self)
end

function stocks:initialize()
        self.refreshCron = Cron.Every(5, function ()
                self:refresh()
        end)
        
        self.canvas = ink.canvas(0, -70, inkEAnchor.TopLeft)
        self.canvas:Reparent(self.inkPage, -1)

        self.buttons = require("modules/ui/pages/menuButtons").createMenu(self)

        self:setupHeader()
        self:setupScrollArea()
        self:setupDetailPanel()
        self:setStocks()

        Cron.After(0.3, function()
                if self.scrollComponent then
                        self.scrollComponent:UpdateContent(true)
                end
        end)
end

function stocks:setupHeader()
        local viewportX = getLayout("viewportStartX")
        local viewportW = getLayout("viewportWidth")
        local headerH = getLayout("headerHeight")
        local primaryColor = getThemeColor("primaryColor")
        local titleFont = getFont("title")
        local headerFont = getFont("header")
        
        local headerCanvas = ink.canvas(viewportX, 270, inkEAnchor.TopLeft)
        headerCanvas:SetSize(Vector2.new({X = viewportW, Y = headerH}))
        headerCanvas:Reparent(self.canvas, -1)
        self.headerCanvas = headerCanvas

        local title = ink.text("MARKET OVERVIEW", 20, 30, titleFont, primaryColor)
        title:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        title:Reparent(headerCanvas, -1)

        self:createFilterButton(headerCanvas, 20, 75, "ALL", "all", 90)
        self:createFilterButton(headerCanvas, 130, 75, "OWNED", "owned", 140)
        self:createFilterButton(headerCanvas, 290, 75, "GAINERS", "gainers", 160)
        self:createFilterButton(headerCanvas, 470, 75, "LOSERS", "losers", 150)

        self:createSortButton(headerCanvas, 700, 20, "NAME", "ascAlpha", "desAlpha")
        self:createSortButton(headerCanvas, 860, 20, "PRICE", "ascValue", "desValue")
        self:createSortButton(headerCanvas, 1020, 20, "TREND", "ascPercent", "desPercent")

        self.stockCountLabel = ink.text("128 STOCKS", 565, 30, headerFont, color.cyan)
        self.stockCountLabel:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        self.stockCountLabel:Reparent(headerCanvas, -1)

        local headerLine = ink.line(20, 145, 1250, 145, color.new(94, 246, 255, 1, 255), 3)
        headerLine:SetOpacity(0.6)
        headerLine:Reparent(headerCanvas, -1)
end

function stocks:createFilterButton(parent, x, y, label, filterType, width)
        local btnCanvas = ink.canvas(x, y, inkEAnchor.TopLeft)
        local btnWidth = width or 100
        local btnHeight = 60
        btnCanvas:SetSize(Vector2.new({X = btnWidth, Y = btnHeight}))
        btnCanvas:SetInteractive(true)
        btnCanvas:Reparent(parent, -1)

        local isActive = (self.filter == filterType)

        local btnBg = ink.image(btnWidth/2, btnHeight/2, btnWidth, btnHeight, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_bg")
        btnBg.image.useNineSliceScale = true
        btnBg.pos:SetInteractive(true)
        if isActive then
                btnBg.image:SetTintColor(color.new(94, 246, 255, 1, 255))
        else
                btnBg.image:SetTintColor(color.new(30, 40, 55, 1, 255))
        end
        btnBg.pos:Reparent(btnCanvas, -1)

        local btnText = ink.text(label, btnWidth/2, btnHeight/2, 36, isActive and color.new(10, 15, 25, 1, 255) or color.white)
        btnText:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        btnText:Reparent(btnCanvas, -1)

        local button = {
                canvas = btnCanvas,
                bg = btnBg,
                text = btnText,
                label = label,
                filterType = filterType
        }

        local eventCatcher = sampleStyleManagerGameController.new()
        btnBg.pos:RegisterToCallback('OnPress', eventCatcher, 'OnState1')
        btnBg.pos:RegisterToCallback('OnEnter', eventCatcher, 'OnStyle1')
        btnBg.pos:RegisterToCallback('OnLeave', eventCatcher, 'OnStyle2')

        button.eventCatcher = eventCatcher
        button.hoverInCallback = function()
                btnBg.image:SetOpacity(0.7)
        end
        button.hoverOutCallback = function()
                btnBg.image:SetOpacity(1)
        end
        button.clickCallback = function()
                utils.playSound("ui_menu_onpress", 1)
                self.filter = filterType
                self:updateFilterButtons()
                self:setStocks()
        end

        table.insert(self.eventCatcher.subscribers, button)
        self.filterButtons[filterType] = button
end

function stocks:updateFilterButtons()
        for key, btn in pairs(self.filterButtons) do
                local isActive = (self.filter == btn.filterType)
                if isActive then
                        btn.bg.image:SetTintColor(color.new(94, 246, 255, 1, 255))
                        btn.text:SetTintColor(color.new(10, 15, 25, 1, 255))
                else
                        btn.bg.image:SetTintColor(color.new(30, 40, 55, 1, 255))
                        btn.text:SetTintColor(color.white)
                end
        end
end

function stocks:createSortButton(parent, x, y, label, ascSort, desSort)
        local btnCanvas = ink.canvas(x, y, inkEAnchor.TopLeft)
        btnCanvas:SetSize(Vector2.new({X = 150, Y = 55}))
        btnCanvas:SetInteractive(true)
        btnCanvas:Reparent(parent, -1)

        local isActive = (self.sort == ascSort or self.sort == desSort)

        local btnBg = ink.image(75, 27, 145, 50, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_bg")
        btnBg.image.useNineSliceScale = true
        btnBg.pos:SetInteractive(true)
        if isActive then
                btnBg.image:SetTintColor(color.new(94, 246, 255, 1, 255))
        else
                btnBg.image:SetTintColor(color.new(30, 40, 55, 1, 255))
        end
        btnBg.pos:Reparent(btnCanvas, -1)

        local btnText = ink.text(label, 75, 27, 32, isActive and color.new(10, 15, 25, 1, 255) or color.white)
        btnText:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        btnText:Reparent(btnCanvas, -1)

        local button = {
                canvas = btnCanvas,
                bg = btnBg,
                text = btnText,
                label = label,
                ascSort = ascSort,
                desSort = desSort
        }

        local eventCatcher = sampleStyleManagerGameController.new()
        btnBg.pos:RegisterToCallback('OnPress', eventCatcher, 'OnState1')
        btnBg.pos:RegisterToCallback('OnEnter', eventCatcher, 'OnStyle1')
        btnBg.pos:RegisterToCallback('OnLeave', eventCatcher, 'OnStyle2')

        button.eventCatcher = eventCatcher
        button.hoverInCallback = function()
                btnBg.image:SetOpacity(0.7)
        end
        button.hoverOutCallback = function()
                btnBg.image:SetOpacity(1)
        end
        button.clickCallback = function()
                utils.playSound("ui_menu_onpress", 1)
                if self.sort == ascSort then
                        self.sort = desSort
                elseif self.sort == desSort then
                        self.sort = ascSort
                else
                        self.sort = ascSort
                end
                self:updateSortButtons()
                self:setStocks()
        end

        table.insert(self.eventCatcher.subscribers, button)
        self.sortButtons[ascSort] = button
end

function stocks:updateSortButtons()
        for key, btn in pairs(self.sortButtons) do
                local isActive = (self.sort == btn.ascSort or self.sort == btn.desSort)
                if isActive then
                        btn.bg.image:SetTintColor(color.new(94, 246, 255, 1, 255))
                        btn.text:SetTintColor(color.new(10, 15, 25, 1, 255))
                else
                        btn.bg.image:SetTintColor(color.new(30, 40, 55, 1, 255))
                        btn.text:SetTintColor(color.white)
                end
        end
end

function stocks:setupDetailPanel()
        local viewportSize = self.inkPage:GetSize()
        local panelX = (self.listRightEdge or 1180) + 10
        local panelY = 270
        local panelWidth = math.max(900, viewportSize.X - panelX - 40)
        local panelHeight = math.max(800, viewportSize.Y - panelY - 40)
        
        self.detailPanel = ink.canvas(panelX, panelY, inkEAnchor.TopLeft)
        self.detailPanel:Reparent(self.canvas, -1)

        local panelCenterX = panelWidth / 2
        self.detailPanelWidth = panelWidth
        self.detailPanelHeight = panelHeight

        local panelBg = ink.image(panelCenterX, panelHeight/2, panelWidth, panelHeight, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_bg")
        panelBg.image.useNineSliceScale = true
        panelBg.image:SetTintColor(color.new(10, 14, 20, 1, 255))
        panelBg.image:SetOpacity(0.95)
        panelBg.pos:Reparent(self.detailPanel, -1)

        local panelBorder = ink.image(panelCenterX, panelHeight/2, panelWidth, panelHeight, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_fg")
        panelBorder.image.useNineSliceScale = true
        panelBorder.image:SetTintColor(color.new(60, 180, 200, 0.4, 255))
        panelBorder.pos:Reparent(self.detailPanel, -1)

        local headerLine = ink.line(40, 25, panelWidth - 40, 25, color.new(255, 50, 150, 1, 255), 4)
        headerLine:Reparent(self.detailPanel, -1)

        local detailTitle = ink.text("STOCK DETAILS", 50, 55, 44, color.new(255, 50, 150, 1, 255))
        detailTitle:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        detailTitle:Reparent(self.detailPanel, -1)

        self.detailIcon = ink.image(110, 170, 140, 140, "", "")
        self.detailIcon.pos:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        self.detailIcon.pos:Reparent(self.detailPanel, -1)

        self.detailName = ink.text("SELECT A STOCK", 200, 115, 56, color.white)
        self.detailName:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        self.detailName:Reparent(self.detailPanel, -1)

        self.detailDesc = ink.text("Click any stock from the list to view details here", 200, 160, 34, color.new(200, 200, 200, 1, 255))
        self.detailDesc:SetAnchorPoint(Vector2.new({X = 0, Y = 0}))
        self.detailDesc:SetSize(Vector2.new({X = panelWidth - 240, Y = 120}))
        self.detailDesc:SetWrapping(true, panelWidth - 260)
        self.detailDesc:SetHorizontalAlignment(textHorizontalAlignment.Left)
        self.detailDesc:Reparent(self.detailPanel, -1)

        local statsLineY = 290
        local statsLine = ink.line(40, statsLineY, panelWidth - 40, statsLineY, color.new(60, 80, 100, 1, 255), 2)
        statsLine:Reparent(self.detailPanel, -1)

        self.statLabels = {}
        self.statValues = {}

        local colSpacing = (panelWidth - 120) / 4
        local col1 = 60
        local col2 = 60 + colSpacing
        local col3 = 60 + colSpacing * 2
        local col4 = 60 + colSpacing * 3
        
        local row1Y = 330
        local row1ValY = 395
        local row2Y = 470
        local row2ValY = 535
        
        local stats = {
                {label = "CURRENT PRICE", x = col1, row = 1},
                {label = "24H CHANGE", x = col2, row = 1},
                {label = "DAY HIGH", x = col3, row = 1},
                {label = "DAY LOW", x = col4, row = 1},
                {label = "SHARES OWNED", x = col1, row = 2},
                {label = "PORTFOLIO VALUE", x = col2, row = 2},
                {label = "UNREALIZED P/L", x = col3, row = 2},
                {label = "AVG COST", x = col4, row = 2}
        }

        for i, stat in ipairs(stats) do
                local labelY = stat.row == 1 and row1Y or row2Y
                local valueY = stat.row == 1 and row1ValY or row2ValY
                
                local label = ink.text(stat.label, stat.x, labelY, 36, color.new(200, 220, 240, 1, 255))
                label:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
                label:Reparent(self.detailPanel, -1)
                self.statLabels[i] = label

                local value = ink.text("--", stat.x, valueY, 56, color.white)
                value:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
                value:Reparent(self.detailPanel, -1)
                self.statValues[i] = value
        end

        local graphLineY = 600
        local graphLine = ink.line(40, graphLineY, panelWidth - 40, graphLineY, color.new(60, 80, 100, 1, 255), 2)
        graphLine:Reparent(self.detailPanel, -1)

        local graphLabel = ink.text("PRICE HISTORY", 50, 640, 40, color.new(200, 220, 240, 1, 255))
        graphLabel:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        graphLabel:Reparent(self.detailPanel, -1)

        local graphY = 680
        local graphHeight = panelHeight - graphY - 100
        local graphWidth = panelWidth - 80
        self.graph = require("modules/ui/widgets/graph"):new(40, graphY, graphWidth, graphHeight, 8, 4, "", "", 4, 24, color.darkcyan, 0.08)
        self.graph.intervall = self.mod.intervall
        self.graph.showXAxisLabels = false
        self.graph:initialize(self.detailPanel)

        self:setupActionButtons()
end

function stocks:setupActionButtons()
        local btnHeight = 60
        local btnWidth = 420
        local btnSpacing = 40
        local btnY = self.detailPanelHeight - 80

        local totalWidth = (btnWidth * 2) + btnSpacing
        local startX = (self.detailPanelWidth - totalWidth) / 2

        self:createActionButton(startX, btnY, btnWidth, btnHeight, "BUY / SELL", color.new(94, 246, 255, 1, 255), function()
                if self.selectedStock then
                        self.controller.currentInfoStock = self.selectedStock
                        self.controller:switchToPage("stockInfo")
                end
        end)

        self:createActionButton(startX + btnWidth + btnSpacing, btnY, btnWidth, btnHeight, "VIEW DETAILS", color.white, function()
                if self.selectedStock then
                        self.controller.currentInfoStock = self.selectedStock
                        self.controller:switchToPage("stockInfo")
                end
        end)
end

function stocks:createActionButton(x, y, w, h, text, textColor, callback)
        local btnCanvas = ink.canvas(x, y, inkEAnchor.TopLeft)
        btnCanvas:SetSize(Vector2.new({X = w, Y = h}))
        btnCanvas:SetInteractive(true)
        btnCanvas:Reparent(self.detailPanel, -1)

        local btnBg = ink.image(w/2, h/2, w, h, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_bg")
        btnBg.image.useNineSliceScale = true
        btnBg.image:SetTintColor(color.new(25, 35, 50, 1, 255))
        btnBg.pos:SetInteractive(true)
        btnBg.pos:Reparent(btnCanvas, -1)

        local btnFg = ink.image(w/2, h/2, w, h, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_fg")
        btnFg.image.useNineSliceScale = true
        btnFg.image:SetTintColor(color.new(60, 180, 200, 0.5, 255))
        btnFg.pos:Reparent(btnCanvas, -1)

        local btnText = ink.text(text, w/2, h/2, 36, textColor)
        btnText:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        btnText:Reparent(btnCanvas, -1)

        local button = {
                canvas = btnCanvas,
                bg = btnBg,
                fg = btnFg,
                text = btnText
        }

        local eventCatcher = sampleStyleManagerGameController.new()
        btnBg.pos:RegisterToCallback('OnPress', eventCatcher, 'OnState1')
        btnBg.pos:RegisterToCallback('OnEnter', eventCatcher, 'OnStyle1')
        btnBg.pos:RegisterToCallback('OnLeave', eventCatcher, 'OnStyle2')

        button.eventCatcher = eventCatcher
        button.hoverInCallback = function()
                btnBg.image:SetTintColor(color.new(40, 55, 75, 1, 255))
                btnFg.image:SetTintColor(color.new(94, 246, 255, 0.8, 255))
        end
        button.hoverOutCallback = function()
                btnBg.image:SetTintColor(color.new(25, 35, 50, 1, 255))
                btnFg.image:SetTintColor(color.new(60, 180, 200, 0.5, 255))
        end
        button.clickCallback = function()
                utils.playSound("ui_menu_onpress", 1)
                if callback then callback() end
        end

        table.insert(self.eventCatcher.subscribers, button)
        return button
end

function stocks:setupScrollArea()
        self.scrollComponent = UIScroller.Create()

        local scrollPanel = self.scrollComponent:GetRootWidget()
        scrollPanel:SetAnchor(inkEAnchor.TopLeft)
        scrollPanel:SetMargin(inkMargin.new({ left = 80.0, top = 430 }))
        scrollPanel:SetSize(Vector2.new({ X = 1250.0, Y = 900.0 }))
        scrollPanel:Reparent(self.canvas, -1)
        
        self.listRightEdge = 80 + 1250
        
        local scrollContent = self.scrollComponent:GetContentWidget()

        local buttonList = inkVerticalPanel.new()
        buttonList:SetName('list')
        buttonList:SetPadding(inkMargin.new({ left = 15.0, top = 10.0, right = 15.0, bottom = 25.0 }))
        buttonList:SetChildMargin(inkMargin.new({ top = 8.0, bottom = 8.0 }))
        buttonList:SetFitToContent(true)
        buttonList:Reparent(scrollContent, -1)

        for i = 1, self.mod.market:getNumberStocks() do
                local preview = self:createPreviewButton(0, 0)
                preview.canvas:Reparent(buttonList, -1)
        end

        Cron.NextTick(function()
                self.scrollComponent:UpdateContent(true)
        end)
        
        local this = self
        self.scrollComponent:RegisterCallback('OnRelative', function()
                this:onUserScroll()
        end)
        self.scrollComponent:RegisterCallback('OnAxis', function()
                this:onUserScroll()
        end)
end

function stocks:onUserScroll()
        self.isUserScrolling = true
        
        if self.scrollCooldownCron then
                pcall(function() Cron.Halt(self.scrollCooldownCron) end)
        end
        
        self.scrollCooldownCron = Cron.After(1.5, function()
                self.isUserScrolling = false
        end)
end

function stocks:createPreviewButton(x, y)
        local button = require("modules/ui/widgets/stockPreview"):new(self)
        button.x = x
        button.y = y
        button.sizeX = 1180
        button.sizeY = 140
        button.textSize = 56
        button.borderSize = 4
        button.fgColor = color.new(60, 180, 200, 0.4, 255)
        button.bgColor = color.new(18, 24, 35, 1, 255)
        button.textColor = color.white
        button:initialize()
        button:registerCallbacks(self.eventCatcher)
        table.insert(self.previews, button)
        return button
end

function stocks:selectStock(preview)
        if self.selectedPreview then
                self.selectedPreview:setSelected(false)
        end

        self.selectedPreview = preview
        self.selectedStock = preview.stock
        preview:setSelected(true)

        self:updateDetailPanel()
end

function stocks:wrapText(text, maxChars)
        if not text or text == "" then return "", "" end
        if #text <= maxChars then return text, "" end
        
        local breakPoint = maxChars
        for i = maxChars, 1, -1 do
                if string.sub(text, i, i) == " " then
                        breakPoint = i
                        break
                end
        end
        
        local line1 = string.sub(text, 1, breakPoint)
        local remaining = string.sub(text, breakPoint + 1)
        
        if #remaining > maxChars then
                remaining = string.sub(remaining, 1, maxChars - 3) .. "..."
        end
        
        return line1, remaining
end

function stocks:updateDetailPanel()
        if not self.selectedStock then return end

        local stock = self.selectedStock

        self.detailIcon.image:SetAtlasResource(ResRef.FromString(stock.atlasPath))
        self.detailIcon.image:SetTexturePart(stock.atlasPart)
        local maxIconSize = 120
        local iconScale = math.min(maxIconSize / stock.iconX, maxIconSize / stock.iconY)
        local scaledW = stock.iconX * iconScale
        local scaledH = stock.iconY * iconScale
        self.detailIcon.pos:SetSize(scaledW, scaledH)
        self.detailIcon.image:SetTintColor(HDRColor.new({ Red = 1, Green = 1, Blue = 1, Alpha = 1.0 }))

        local nameSize = 48
        if #stock.name > 30 then nameSize = 32
        elseif #stock.name > 24 then nameSize = 38
        elseif #stock.name > 18 then nameSize = 42
        end
        self.detailName:SetFontSize(nameSize)
        self.detailName:SetText(stock.name)

        local desc = lang.getText(stock.info)
        if desc and desc ~= "" and desc ~= stock.info then
                self.detailDesc:SetText(desc)
        else
                self.detailDesc:SetText("A Night City corporation")
        end

        local price = stock:getCurrentPrice() or 0
        local owned = stock:getPortfolioNum() or 0
        local trend = stock:getTrend() or 0
        
        self.statValues[1]:SetText(tostring(math.floor(price)) .. " E$")
        self.statValues[1]:SetTintColor(color.new(94, 246, 255, 1, 255))

        local trendText = tostring(trend) .. "%"
        if trend > 0 then
                trendText = "+" .. trendText
                self.statValues[2]:SetTintColor(color.lime)
        elseif trend < 0 then
                self.statValues[2]:SetTintColor(color.red)
        else
                self.statValues[2]:SetTintColor(color.white)
        end
        self.statValues[2]:SetText(trendText)

        local dayHigh = 0
        local dayLow = 0
        pcall(function()
                local data = stock.exportData.data or {}
                if #data > 0 then
                        dayHigh = data[1]
                        dayLow = data[1]
                        for _, v in ipairs(data) do
                                if v > dayHigh then dayHigh = v end
                                if v < dayLow then dayLow = v end
                        end
                else
                        dayHigh = price
                        dayLow = price
                end
        end)
        self.statValues[3]:SetText(tostring(math.floor(dayHigh)) .. " E$")
        self.statValues[3]:SetTintColor(color.lime)
        
        self.statValues[4]:SetText(tostring(math.floor(dayLow)) .. " E$")
        self.statValues[4]:SetTintColor(color.red)

        self.statValues[5]:SetText(tostring(owned))
        if owned > 0 then
                self.statValues[5]:SetTintColor(color.new(255, 200, 50, 1, 255))
        else
                self.statValues[5]:SetTintColor(color.white)
        end

        local portfolioValue = owned * price
        self.statValues[6]:SetText(tostring(math.floor(portfolioValue)) .. " E$")
        self.statValues[6]:SetTintColor(color.white)

        local unrealized = 0
        local avgCost = 0
        pcall(function()
                unrealized = stock:getUnrealizedProfit() or 0
                local spent = stock.exportData.spent or 0
                if owned > 0 and spent > 0 then
                        avgCost = spent / owned
                end
        end)
        
        local unrealizedText = tostring(math.floor(unrealized)) .. " E$"
        if unrealized >= 0 then
                unrealizedText = "+" .. unrealizedText
                self.statValues[7]:SetTintColor(color.lime)
        else
                self.statValues[7]:SetTintColor(color.red)
        end
        self.statValues[7]:SetText(unrealizedText)
        
        if avgCost > 0 then
                self.statValues[8]:SetText(tostring(math.floor(avgCost)) .. " E$")
                self.statValues[8]:SetTintColor(color.new(200, 200, 200, 1, 255))
        else
                self.statValues[8]:SetText("--")
                self.statValues[8]:SetTintColor(color.new(100, 100, 100, 1, 255))
        end

        self.graph.data = stock.exportData.data
        self.graph:showData()
end

function stocks:setStocks()
        local allStocks = {}
        for _, stock in pairs(self.mod.market.stocks) do
                table.insert(allStocks, stock)
        end

        local stockList = {}
        for _, stock in pairs(allStocks) do
                local include = true
                if self.filter == "owned" then
                        include = stock:getPortfolioNum() > 0
                elseif self.filter == "gainers" then
                        include = stock:getTrend() > 0
                elseif self.filter == "losers" then
                        include = stock:getTrend() <= 0
                end
                if include then
                        table.insert(stockList, stock)
                end
        end

        local sortFunc = nil
        if self.sort == "ascAlpha" then
                sortFunc = function(a, b) return a.name < b.name end
        elseif self.sort == "desAlpha" then
                sortFunc = function(a, b) return a.name > b.name end
        elseif self.sort == "ascPercent" then
                sortFunc = function(a, b) return a:getTrend() < b:getTrend() end
        elseif self.sort == "desPercent" then
                sortFunc = function(a, b) return a:getTrend() > b:getTrend() end
        elseif self.sort == "ascValue" then
                sortFunc = function(a, b) return a:getCurrentPrice() < b:getCurrentPrice() end
        elseif self.sort == "desValue" then
                sortFunc = function(a, b) return a:getCurrentPrice() > b:getCurrentPrice() end
        end

        table.sort(stockList, sortFunc)

        if self.stockCountLabel then
                if #stockList == 0 then
                        self.stockCountLabel:SetText("NO STOCKS")
                elseif #stockList == 1 then
                        self.stockCountLabel:SetText("1 STOCK")
                else
                        self.stockCountLabel:SetText(tostring(#stockList) .. " STOCKS")
                end
        end

        for k, button in pairs(self.previews) do
                button.stock = stockList[k]
                button:showData()
        end
end

function stocks:refresh()
        -- BLOCK REFRESH WHILE USER IS SCROLLING
        if self.isUserScrolling then
                return
        end
        
        -- Update prices only (no list rebuild, no visibility changes)
        for _, p in ipairs(self.previews or {}) do
                pcall(function()
                        if p and p.refreshPriceOnly then
                                p:refreshPriceOnly()
                        end
                end)
        end
        
        -- Update detail panel if stock is selected
        if self.selectedStock then
                pcall(function()
                        self:updateDetailPanel()
                end)
        end
end

function stocks:uninitialize()
        Cron.Halt(self.refreshCron)

        if not self.canvas then return end
        self.previews = {}
        self.sortButtons = {}
        self.filterButtons = {}
        self.selectedPreview = nil
        self.selectedStock = nil
        self.scrollComponent = nil
        pcall(function()
                self.eventCatcher.removeSubscriber(self.button)
        end)
        pcall(function()
                self.inkPage:RemoveChild(self.canvas)
        end)
        pcall(function()
                self.inkPage:RemoveChild(self.buttons)
        end)
        self.canvas = nil
end

return stocks
