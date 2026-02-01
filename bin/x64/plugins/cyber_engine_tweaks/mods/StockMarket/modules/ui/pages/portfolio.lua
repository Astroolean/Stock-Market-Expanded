local ink = require("modules/ui/inkHelper")
local color = require("modules/ui/color")
local lang = require("modules/utils/lang")
local Cron = require("modules/external/Cron")
local utils = require("modules/utils/utils")
local UIScroller = require("modules/external/UIScroller")
local ConfigManager = require("modules/utils/ConfigManager")

portfolio = {}

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

function portfolio:new(inkPage, controller, eventCatcher, mod)
        local o = {}

        o.mod = mod
    o.inkPage = inkPage
        o.controller = controller
        o.eventCatcher = eventCatcher
        o.pageName = "portfolio"

        o.canvas = nil
        o.refreshCron = nil
        o.previews = {}
        o.sort = "desValue"
        o.sortButtons = {}
        o.scrollComponent = nil
        o.isUserScrolling = false
        o.scrollCooldownCron = nil

        self.__index = self
        return setmetatable(o, self)
end

function portfolio:initialize()
        self.refreshCron = Cron.Every(2, function ()
                self:refresh()
        end)

        self.canvas = ink.canvas(0, -70, inkEAnchor.TopLeft)
        self.canvas:Reparent(self.inkPage, -1)

        self.buttons = require("modules/ui/pages/menuButtons").createMenu(self)

        self:setupHeroSection()
        self:setupProfitPanel()
        self:setupHoldingsSection()
        self:setupHelpButton()
        self:setupHelpOverlay()
        self:refreshData()
end

function portfolio:setupHeroSection()
        local heroY = 280
        local fullWidth = 2600
        
        local heroPanel = ink.canvas(80, heroY, inkEAnchor.TopLeft)
        heroPanel:SetSize(Vector2.new({X = fullWidth, Y = 200}))
        heroPanel:Reparent(self.canvas, -1)
        self.heroPanel = heroPanel
        
        local heroBg = ink.image(fullWidth/2, 100, fullWidth, 200, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_bg")
        heroBg.image.useNineSliceScale = true
        heroBg.image:SetTintColor(color.new(15, 25, 40, 1, 255))
        heroBg.image:SetOpacity(0.95)
        heroBg.pos:Reparent(heroPanel, -1)
        
        local heroBorder = ink.image(fullWidth/2, 100, fullWidth - 4, 196, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_fg")
        heroBorder.image.useNineSliceScale = true
        heroBorder.image:SetTintColor(color.new(94, 246, 255, 1, 255))
        heroBorder.image:SetOpacity(0.4)
        heroBorder.pos:Reparent(heroPanel, -1)
        
        local portfolioLabel = ink.text("PORTFOLIO DASHBOARD", 40, 40, 40, color.new(94, 246, 255, 1, 255))
        portfolioLabel:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        portfolioLabel:Reparent(heroPanel, -1)
        
        local wealthLabel = ink.text("TOTAL WEALTH", 40, 90, 52, color.new(200, 220, 240, 1, 255))
        wealthLabel:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        wealthLabel:Reparent(heroPanel, -1)
        
        self.heroWealth = ink.text("0 E$", 40, 155, 80, color.new(94, 246, 255, 1, 255))
        self.heroWealth:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        self.heroWealth:Reparent(heroPanel, -1)
        
        local dividerLine1 = ink.line(700, 35, 700, 165, color.new(60, 80, 100, 1, 255), 3)
        dividerLine1:Reparent(heroPanel, -1)
        
        local cashLabel = ink.text("CASH BALANCE", 780, 60, 40, color.new(200, 220, 240, 1, 255))
        cashLabel:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        cashLabel:Reparent(heroPanel, -1)
        
        self.heroCash = ink.text("0 E$", 780, 130, 72, color.white)
        self.heroCash:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        self.heroCash:Reparent(heroPanel, -1)
        
        local dividerLine2 = ink.line(1400, 35, 1400, 165, color.new(60, 80, 100, 1, 255), 3)
        dividerLine2:Reparent(heroPanel, -1)
        
        local equityLabel = ink.text("STOCK EQUITY", 1480, 60, 40, color.new(200, 220, 240, 1, 255))
        equityLabel:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        equityLabel:Reparent(heroPanel, -1)
        
        self.heroEquity = ink.text("0 E$", 1480, 130, 72, color.new(255, 200, 50, 1, 255))
        self.heroEquity:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        self.heroEquity:Reparent(heroPanel, -1)
        
end

function portfolio:setupHelpButton()
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

function portfolio:setupHelpOverlay()
        self.helpVisible = false
        self.helpCanvas = ink.canvas(80, 250, inkEAnchor.TopLeft)
        self.helpCanvas:Reparent(self.canvas, -1)
        self.helpCanvas:SetVisible(false)

        local panelW = 2500
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

        local helpTitle = ink.text("PORTFOLIO GUIDE", panelW / 2, 50, 64, color.cyan)
        helpTitle:SetAnchorPoint(0.5, 0.5)
        helpTitle:Reparent(self.helpCanvas, -1)

        local subtitle = ink.text("Understanding your holdings and profit/loss tracking", panelW / 2, 100, 36, color.new(200, 220, 240, 1, 255))
        subtitle:SetAnchorPoint(0.5, 0.5)
        subtitle:Reparent(self.helpCanvas, -1)

        local dividerTop = ink.rect(60, 140, panelW - 120, 3, color.cyan)
        dividerTop:SetOpacity(0.6)
        dividerTop:Reparent(self.helpCanvas, -1)

        local col1X = 80
        local col2X = 900
        local col3X = 1700

        local sec1Title = ink.text("WEALTH SUMMARY", col1X, 190, 44, color.cyan)
        sec1Title:Reparent(self.helpCanvas, -1)

        local sec1Line1 = ink.text("TOTAL WEALTH", col1X, 260, 36, color.white)
        sec1Line1:Reparent(self.helpCanvas, -1)
        local sec1Desc1 = ink.text("Your total net worth: cash balance plus the", col1X, 305, 30, color.new(180, 190, 200, 1, 255))
        sec1Desc1:Reparent(self.helpCanvas, -1)
        local sec1Desc1b = ink.text("current market value of all your stocks.", col1X, 340, 30, color.new(180, 190, 200, 1, 255))
        sec1Desc1b:Reparent(self.helpCanvas, -1)

        local sec1Line2 = ink.text("CASH BALANCE", col1X, 410, 36, color.lime)
        sec1Line2:Reparent(self.helpCanvas, -1)
        local sec1Desc2 = ink.text("Eddies available to purchase stocks.", col1X, 455, 30, color.new(180, 190, 200, 1, 255))
        sec1Desc2:Reparent(self.helpCanvas, -1)
        local sec1Desc2b = ink.text("This is your liquid buying power.", col1X, 490, 30, color.new(180, 190, 200, 1, 255))
        sec1Desc2b:Reparent(self.helpCanvas, -1)

        local sec1Line3 = ink.text("STOCK EQUITY", col1X, 560, 36, color.yellow)
        sec1Line3:Reparent(self.helpCanvas, -1)
        local sec1Desc3 = ink.text("Current market value of all stocks you own.", col1X, 605, 30, color.new(180, 190, 200, 1, 255))
        sec1Desc3:Reparent(self.helpCanvas, -1)
        local sec1Desc3b = ink.text("Changes as stock prices move.", col1X, 640, 30, color.new(180, 190, 200, 1, 255))
        sec1Desc3b:Reparent(self.helpCanvas, -1)

        local sec2Title = ink.text("PROFIT & LOSS", col2X, 190, 44, color.cyan)
        sec2Title:Reparent(self.helpCanvas, -1)

        local sec2Line1 = ink.text("REALIZED P/L", col2X, 260, 36, color.lime)
        sec2Line1:Reparent(self.helpCanvas, -1)
        local sec2Desc1 = ink.text("Profit or loss from stocks you have SOLD.", col2X, 305, 30, color.new(180, 190, 200, 1, 255))
        sec2Desc1:Reparent(self.helpCanvas, -1)
        local sec2Desc1b = ink.text("This is money you've actually made or lost.", col2X, 340, 30, color.new(180, 190, 200, 1, 255))
        sec2Desc1b:Reparent(self.helpCanvas, -1)

        local sec2Line2 = ink.text("UNREALIZED P/L", col2X, 410, 36, color.orange)
        sec2Line2:Reparent(self.helpCanvas, -1)
        local sec2Desc2 = ink.text("Potential profit/loss if you sold everything NOW.", col2X, 455, 30, color.new(180, 190, 200, 1, 255))
        sec2Desc2:Reparent(self.helpCanvas, -1)
        local sec2Desc2b = ink.text("Changes constantly with market prices.", col2X, 490, 30, color.new(180, 190, 200, 1, 255))
        sec2Desc2b:Reparent(self.helpCanvas, -1)

        local sec2Line3 = ink.text("TOTAL P/L", col2X, 560, 36, color.white)
        sec2Line3:Reparent(self.helpCanvas, -1)
        local sec2Desc3 = ink.text("Realized + Unrealized combined.", col2X, 605, 30, color.new(180, 190, 200, 1, 255))
        sec2Desc3:Reparent(self.helpCanvas, -1)
        local sec2Desc3b = ink.text("Your overall trading performance.", col2X, 640, 30, color.new(180, 190, 200, 1, 255))
        sec2Desc3b:Reparent(self.helpCanvas, -1)

        local sec3Title = ink.text("YOUR HOLDINGS", col3X, 190, 44, color.cyan)
        sec3Title:Reparent(self.helpCanvas, -1)

        local sec3Line1 = ink.text("POSITIONS", col3X, 260, 36, color.white)
        sec3Line1:Reparent(self.helpCanvas, -1)
        local sec3Desc1 = ink.text("Number of different stocks you own.", col3X, 305, 30, color.new(180, 190, 200, 1, 255))
        sec3Desc1:Reparent(self.helpCanvas, -1)
        local sec3Desc1b = ink.text("More positions = more diversification.", col3X, 340, 30, color.new(180, 190, 200, 1, 255))
        sec3Desc1b:Reparent(self.helpCanvas, -1)

        local sec3Line2 = ink.text("TOTAL SHARES", col3X, 410, 36, color.white)
        sec3Line2:Reparent(self.helpCanvas, -1)
        local sec3Desc2 = ink.text("Total number of shares across all stocks.", col3X, 455, 30, color.new(180, 190, 200, 1, 255))
        sec3Desc2:Reparent(self.helpCanvas, -1)
        local sec3Desc2b = ink.text("Each stock can have many shares.", col3X, 490, 30, color.new(180, 190, 200, 1, 255))
        sec3Desc2b:Reparent(self.helpCanvas, -1)

        local sec3Line3 = ink.text("BEST/WORST PERFORMERS", col3X, 560, 36, color.white)
        sec3Line3:Reparent(self.helpCanvas, -1)
        local sec3Desc3 = ink.text("Your top and worst performing stocks", col3X, 605, 30, color.new(180, 190, 200, 1, 255))
        sec3Desc3:Reparent(self.helpCanvas, -1)
        local sec3Desc3b = ink.text("ranked by profit/loss percentage.", col3X, 640, 30, color.new(180, 190, 200, 1, 255))
        sec3Desc3b:Reparent(self.helpCanvas, -1)

        local tipBg = ink.rect(60, 710, panelW - 120, 80, color.new(40, 60, 80, 1, 255))
        tipBg:Reparent(self.helpCanvas, -1)

        local tipText = ink.text("TIP: Click any holding in the list below to view full details and execute trades!", panelW / 2, 750, 40, color.yellow)
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

function portfolio:toggleHelp()
        self.helpVisible = not self.helpVisible
        if self.helpVisible then
                self.helpCanvas:Reparent(self.canvas, -1)
        end
        self.helpCanvas:SetVisible(self.helpVisible)
end

function portfolio:setupProfitPanel()
        local panelY = 500
        local panelW = 2600
        local panelPanel = ink.canvas(80, panelY, inkEAnchor.TopLeft)
        panelPanel:SetSize(Vector2.new({X = panelW, Y = 150}))
        panelPanel:Reparent(self.canvas, -1)
        self.profitPanel = panelPanel
        
        local panelBg = ink.image(panelW/2, 75, panelW, 150, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_bg")
        panelBg.image.useNineSliceScale = true
        panelBg.image:SetTintColor(color.new(20, 30, 45, 1, 255))
        panelBg.image:SetOpacity(0.85)
        panelBg.pos:Reparent(panelPanel, -1)
        
        local panelBorder = ink.image(panelW/2, 75, panelW - 4, 146, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_fg")
        panelBorder.image.useNineSliceScale = true
        panelBorder.image:SetTintColor(color.new(60, 100, 120, 0.5, 255))
        panelBorder.pos:Reparent(panelPanel, -1)
        
        local colSpacing = (panelW - 100) / 7
        local stats = {
                {label = "REALIZED P/L", x = 40, valueKey = "realized"},
                {label = "UNREALIZED P/L", x = 40 + colSpacing, valueKey = "unrealized"},
                {label = "TOTAL P/L", x = 40 + colSpacing * 2, valueKey = "totalPL"},
                {label = "POSITIONS", x = 40 + colSpacing * 3, valueKey = "positions"},
                {label = "SHARES", x = 40 + colSpacing * 4, valueKey = "shares"},
                {label = "BEST PERFORMER", x = 40 + colSpacing * 5, valueKey = "bestStock"},
                {label = "WORST PERFORMER", x = 40 + colSpacing * 6, valueKey = "worstStock"}
        }
        
        self.profitLabels = {}
        self.profitValues = {}
        
        for i, stat in ipairs(stats) do
                local label = ink.text(stat.label, stat.x, 40, 32, color.new(200, 220, 240, 1, 255))
                label:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
                label:Reparent(panelPanel, -1)
                
                local value = ink.text("--", stat.x, 100, 48, color.white)
                value:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
                value:Reparent(panelPanel, -1)
                
                self.profitLabels[stat.valueKey] = label
                self.profitValues[stat.valueKey] = value
        end
end

function portfolio:setupHoldingsSection()
        local sectionY = 670
        local fullWidth = 2600
        
        local headerCanvas = ink.canvas(80, sectionY, inkEAnchor.TopLeft)
        headerCanvas:SetSize(Vector2.new({X = fullWidth, Y = 90}))
        headerCanvas:Reparent(self.canvas, -1)
        
        local title = ink.text("YOUR HOLDINGS", 30, 45, 60, color.new(94, 246, 255, 1, 255))
        title:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        title:Reparent(headerCanvas, -1)
        
        self:createSortButton(headerCanvas, 1200, 10, "NAME", "ascAlpha", "desAlpha")
        self:createSortButton(headerCanvas, 1450, 10, "VALUE", "ascValue", "desValue")
        self:createSortButton(headerCanvas, 1700, 10, "P/L %", "ascPercent", "desPercent")
        
        local headerLine = ink.line(30, 85, 2000, 85, color.new(94, 246, 255, 1, 255), 3)
        headerLine:SetOpacity(0.6)
        headerLine:Reparent(headerCanvas, -1)
        
        self:setupScrollArea(sectionY + 100)
        self:setStocks()
end

function portfolio:createSortButton(parent, x, y, label, ascSort, desSort)
        local btnCanvas = ink.canvas(x, y, inkEAnchor.TopLeft)
        btnCanvas:SetSize(Vector2.new({X = 220, Y = 70}))
        btnCanvas:SetInteractive(true)
        btnCanvas:Reparent(parent, -1)
        
        local isActive = (self.sort == ascSort or self.sort == desSort)
        
        local btnBg = ink.image(110, 35, 215, 65, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_bg")
        btnBg.image.useNineSliceScale = true
        btnBg.pos:SetInteractive(true)
        if isActive then
                btnBg.image:SetTintColor(color.new(94, 246, 255, 1, 255))
        else
                btnBg.image:SetTintColor(color.new(30, 40, 55, 1, 255))
        end
        btnBg.pos:Reparent(btnCanvas, -1)
        
        local btnText = ink.text(label, 110, 35, 40, isActive and color.new(10, 15, 25, 1, 255) or color.white)
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

function portfolio:updateSortButtons()
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

function portfolio:setupScrollArea(startY)
        self.scrollComponent = UIScroller.Create()
        
        local scrollPanel = self.scrollComponent:GetRootWidget()
        scrollPanel:SetAnchor(inkEAnchor.TopLeft)
        scrollPanel:SetMargin(inkMargin.new({ left = 80.0, top = startY }))
        scrollPanel:SetSize(Vector2.new({ X = 2500.0, Y = 450.0 }))
        scrollPanel:Reparent(self.canvas, -1)
        
        local sliderArea = scrollPanel:GetWidgetByPathName(StringToName('sliderArea'))
        if sliderArea then
                sliderArea:SetVisible(false)
        end
        
        local scrollContent = self.scrollComponent:GetContentWidget()
        
        self.buttonList = inkVerticalPanel.new()
        self.buttonList:SetName('list')
        self.buttonList:SetPadding(inkMargin.new({ left = 20.0, top = 15.0, right = 20.0, bottom = 30.0 }))
        self.buttonList:SetChildMargin(inkMargin.new({ top = 12.0, bottom = 12.0 }))
        self.buttonList:SetFitToContent(true)
        self.buttonList:Reparent(scrollContent, -1)
        
        Cron.NextTick(function()
                if self.scrollComponent then
                        self.scrollComponent:UpdateContent(true)
                end
        end)
        
        local numStocks = 0
        pcall(function()
                numStocks = self.mod.market:getNumberStocks() or 0
        end)
        
        for i = 1, numStocks do
                local preview = self:createPreviewButton(0, 0)
                preview.canvas:Reparent(self.buttonList, -1)
        end
        
        local this = self
        self.scrollComponent:RegisterCallback('OnRelative', function()
                this:onUserScroll()
        end)
        self.scrollComponent:RegisterCallback('OnAxis', function()
                this:onUserScroll()
        end)
end

function portfolio:onUserScroll()
        self.isUserScrolling = true
        
        if self.scrollCooldownCron then
                pcall(function() Cron.Halt(self.scrollCooldownCron) end)
        end
        
        self.scrollCooldownCron = Cron.After(1.5, function()
                self.isUserScrolling = false
        end)
end

function portfolio:createPreviewButton(x, y)
        local button = require("modules/ui/widgets/stockPreview"):new(self)
        button.x = x
        button.y = y
        button.sizeX = 2400
        button.sizeY = 200
        button.textSize = 110
        button.borderSize = 4
        button.fgColor = color.new(40, 60, 80, 0.3, 255)
        button.bgColor = color.new(18, 24, 35, 1, 255)
        button.textColor = color.white
        
        button.showData = function(bt)
                pcall(function()
                        if not bt.stock then return end
                        
                        bt.stockIcon.image:SetAtlasResource(ResRef.FromString(bt.stock.atlasPath or ""))
                        bt.stockIcon.image:SetTexturePart(bt.stock.atlasPart or "")
                        
                        local maxIconSize = math.min(bt.sizeY - bt.borderSize * 4, 80)
                        local iconScaleX = maxIconSize / (bt.stock.iconX or 64)
                        local iconScaleY = maxIconSize / (bt.stock.iconY or 64)
                        local iconScale = math.min(iconScaleX, iconScaleY)
                        local scaledW = (bt.stock.iconX or 64) * iconScale
                        local scaledH = (bt.stock.iconY or 64) * iconScale
                        bt.stockIcon.pos:SetSize(scaledW, scaledH)
                        bt.stockIcon.image:SetTintColor(HDRColor.new({ Red = 0.9, Green = 0.9, Blue = 0.9, Alpha = 1.0 }))
                        
                        local displayName = bt.stock.name or "Unknown"
                        local maxChars = 35
                        if #displayName > maxChars then
                                displayName = string.sub(displayName, 1, maxChars - 2) .. ".."
                        end
                        bt.stockName:SetText(displayName)
                        
                        local price = bt.stock:getCurrentPrice() or 0
                        local owned = bt.stock:getPortfolioNum() or 0
                        local value = math.floor(price * owned)
                        bt.stockPrice:SetText(tostring(value) .. " E$")
                        
                        local trend = 0
                        local spent = bt.stock.exportData.spent or 0
                        if spent > 0 then
                                local unrealized = bt.stock:getUnrealizedProfit() or 0
                                trend = unrealized / spent
                                trend = utils.round(trend * 100, 1)
                        end
                        
                        local c = color.red
                        local trendText = tostring(trend) .. "%"
                        if trend >= 0 then
                                c = color.lime
                                trendText = "+" .. trendText
                        end
                        bt.stockTrend:SetText(trendText)
                        bt.stockTrend:SetTintColor(c)
                end)
        end
        
        button:initialize()
        button:registerCallbacks(self.eventCatcher)
        table.insert(self.previews, button)
        
        return button
end

function portfolio:setStocks()
        local stocks = {}
        
        pcall(function()
                for _, stock in pairs(self.mod.market.stocks or {}) do
                        local owned = 0
                        pcall(function() owned = stock:getPortfolioNum() or 0 end)
                        if owned > 0 then
                                table.insert(stocks, stock)
                        end
                end
        end)
        
        pcall(function()
                local marketStock = self.mod.market.marketStock
                if marketStock then
                        local owned = marketStock:getPortfolioNum() or 0
                        if owned > 0 then
                                table.insert(stocks, marketStock)
                        end
                end
        end)
        
        local function getProfitPercent(stock)
                local spent = 0
                local unrealized = 0
                pcall(function()
                        spent = stock.exportData.spent or 0
                        unrealized = stock:getUnrealizedProfit() or 0
                end)
                if spent == 0 then return 0 end
                return utils.round(unrealized / spent * 100, 1)
        end
        
        local function getStockValue(stock)
                local value = 0
                pcall(function()
                        value = (stock:getCurrentPrice() or 0) * (stock:getPortfolioNum() or 0)
                end)
                return value
        end
        
        local sortFunc = nil
        if self.sort == "ascAlpha" then
                sortFunc = function(a, b) return (a.name or "") < (b.name or "") end
        elseif self.sort == "desAlpha" then
                sortFunc = function(a, b) return (a.name or "") > (b.name or "") end
        elseif self.sort == "ascPercent" then
                sortFunc = function(a, b) return getProfitPercent(a) < getProfitPercent(b) end
        elseif self.sort == "desPercent" then
                sortFunc = function(a, b) return getProfitPercent(a) > getProfitPercent(b) end
        elseif self.sort == "ascValue" then
                sortFunc = function(a, b) return getStockValue(a) < getStockValue(b) end
        elseif self.sort == "desValue" then
                sortFunc = function(a, b) return getStockValue(a) > getStockValue(b) end
        end
        
        if sortFunc then
                pcall(function() table.sort(stocks, sortFunc) end)
        end
        
        for k, button in pairs(self.previews or {}) do
                if stocks[k] then
                        button.stock = stocks[k]
                        pcall(function() button:showData() end)
                        button.canvas:SetVisible(true)
                else
                        button.stock = nil
                        button.canvas:SetVisible(false)
                end
        end
        -- Keep scrollbar/content size in sync after filtering/sorting holdings
        Cron.NextTick(function()
                pcall(function()
                        if self.scrollComponent then
                                self.scrollComponent:UpdateContent(true)
                        end
                end)
        end)

end

function portfolio:refreshData()
        local cash = 0
        local equity = 0
        local shares = 0
        local positions = 0
        local totalRealized = 0
        local totalUnrealized = 0
        local bestStock = nil
        local bestPercent = -999999
        local worstStock = nil
        local worstPercent = 999999
        
        pcall(function()
                cash = Game.GetTransactionSystem():GetItemQuantity(GetPlayer(), MarketSystem.Money()) or 0
        end)
        
        local allStocks = {}
        pcall(function()
                allStocks = self.mod.market:getAllStocks() or {}
        end)
        
        for _, stock in pairs(allStocks) do
                pcall(function()
                        local owned = stock:getPortfolioNum() or 0
                        local price = stock:getCurrentPrice() or 0
                        local realized = stock:getRealizedProfit() or 0
                        local unrealized = stock:getUnrealizedProfit() or 0
                        
                        totalRealized = totalRealized + realized
                        totalUnrealized = totalUnrealized + unrealized
                        
                        if owned > 0 then
                                positions = positions + 1
                                shares = shares + owned
                                equity = equity + (owned * price)
                                
                                local spent = stock.exportData.spent or 0
                                local percent = 0
                                if spent > 0 then
                                        percent = unrealized / spent * 100
                                end
                                
                                if percent > bestPercent then
                                        bestPercent = percent
                                        bestStock = stock
                                end
                                if percent < worstPercent then
                                        worstPercent = percent
                                        worstStock = stock
                                end
                        end
                end)
        end
        
        local totalWealth = cash + equity
        local totalPL = totalRealized + totalUnrealized
        
        -- Security Score: Track portfolio check and diversification
        if self.mod.market.securityManager then
                pcall(function()
                        self.mod.market.securityManager:onPortfolioCheck(positions, totalWealth)
                        
                        -- Check for risky "all-in-one" behavior (1 position with high value)
                        local allInOneThreshold = ConfigManager.get("portfolio.allInOneThreshold") or 50000
                        if positions == 1 and equity > allInOneThreshold then
                                self.mod.market.securityManager:onAllInOne()
                        end
                end)
        end
        
        pcall(function()
                self.heroWealth:SetText(utils.formatNumber(totalWealth) .. " E$")
                self.heroCash:SetText(utils.formatNumber(cash) .. " E$")
                self.heroEquity:SetText(utils.formatNumber(equity) .. " E$")
        end)
        
        local function formatPL(value)
                local rounded = utils.round(value, 0)
                local formatted = utils.formatNumber(math.abs(rounded))
                if rounded >= 0 then
                        return "+" .. formatted .. " E$"
                else
                        return "-" .. formatted .. " E$"
                end
        end


        local function setPerfLabel(widget, name)
                local raw = name or "--"
                local rawLen = #raw
                local text = raw
                local size = 48

                -- Prefer two-line wrap on spaces for long names
                if rawLen > 14 then
                        local bestPos = nil
                        local mid = math.floor(rawLen / 2)
                        local bestDist = 999999

                        for i = 1, rawLen do
                                if string.sub(raw, i, i) == " " then
                                        local dist = math.abs(i - mid)
                                        if dist < bestDist then
                                                bestDist = dist
                                                bestPos = i
                                        end
                                end
                        end

                        if bestPos then
                                text = string.sub(raw, 1, bestPos - 1) .. "\n" .. string.sub(raw, bestPos + 1)
                                size = 34
                        end
                end

                -- Fallback: shrink font for very long single-word names
                if rawLen > 18 then size = 34 end
                if rawLen > 26 then size = 30 end
                if rawLen > 34 then size = 26 end
                if rawLen > 44 then size = 22 end

                pcall(function()
                        widget:SetFontSize(size)
                end)
                widget:SetText(text)
        end


        pcall(function()
                self.profitValues["realized"]:SetText(formatPL(totalRealized))
                if totalRealized >= 0 then
                        self.profitValues["realized"]:SetTintColor(color.lime)
                else
                        self.profitValues["realized"]:SetTintColor(color.red)
                end
                
                self.profitValues["unrealized"]:SetText(formatPL(totalUnrealized))
                if totalUnrealized >= 0 then
                        self.profitValues["unrealized"]:SetTintColor(color.lime)
                else
                        self.profitValues["unrealized"]:SetTintColor(color.red)
                end
                
                self.profitValues["totalPL"]:SetText(formatPL(totalPL))
                if totalPL >= 0 then
                        self.profitValues["totalPL"]:SetTintColor(color.lime)
                else
                        self.profitValues["totalPL"]:SetTintColor(color.red)
                end
                
                self.profitValues["positions"]:SetText(tostring(positions))
                self.profitValues["shares"]:SetText(tostring(shares))
                
                if bestStock and positions > 0 then
                        local bestName = bestStock.ticker or bestStock.name or "--"
                        setPerfLabel(self.profitValues["bestStock"], bestName)
                        self.profitValues["bestStock"]:SetTintColor(color.lime)
                else
                        pcall(function() self.profitValues["bestStock"]:SetFontSize(48) end)
                        self.profitValues["bestStock"]:SetText("--")
                        self.profitValues["bestStock"]:SetTintColor(color.white)
                end
                
                if worstStock and positions > 0 then
                        local worstName = worstStock.ticker or worstStock.name or "--"
                        setPerfLabel(self.profitValues["worstStock"], worstName)
                        self.profitValues["worstStock"]:SetTintColor(color.red)
                else
                        pcall(function() self.profitValues["worstStock"]:SetFontSize(48) end)
                        self.profitValues["worstStock"]:SetText("--")
                        self.profitValues["worstStock"]:SetTintColor(color.white)
                end
        end)
end

function portfolio:refresh()
        -- BLOCK REFRESH WHILE USER IS SCROLLING
        if self.isUserScrolling then
                return
        end
        
        -- Update data (prices, P/L, etc.) without rebuilding list
        self:refreshData()
        
        -- Only update visible preview data (don't call setStocks which rebuilds)
        for _, p in pairs(self.previews or {}) do
                pcall(function()
                        if p.canvas:IsVisible() and p.stock then
                                p:showData()
                        end
                end)
        end
end

function portfolio:uninitialize()
        pcall(function()
                Cron.Halt(self.refreshCron)
        end)
        
        if not self.canvas then return end
        self.previews = {}
        self.sortButtons = {}
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

return portfolio
