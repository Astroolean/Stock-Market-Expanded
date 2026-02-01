local ink = require("modules/ui/inkHelper")
local color = require("modules/ui/color")
local lang = require("modules/utils/lang")
local Cron = require("modules/external/Cron")
local utils = require("modules/utils/utils")
local UIScroller = require("modules/external/UIScroller")

news = {}

local lightText = color.new(220, 230, 245, 1, 255)
local mediumText = color.new(180, 195, 215, 1, 255)
local cyanAccent = color.new(94, 246, 255, 1, 255)
local panelBg = color.new(15, 25, 40, 1, 255)
local panelBorder = color.new(60, 100, 120, 0.6, 255)

function news:new(inkPage, controller, eventCatcher, mod)
        local o = {}

        o.mod = mod
    o.inkPage = inkPage
        o.controller = controller
        o.eventCatcher = eventCatcher
        o.pageName = "news"

        o.canvas = nil
        o.newsButtons = {}
        o.locked = false
        o.helpVisible = false
        o.selectedNews = nil

        self.__index = self
        return setmetatable(o, self)
end

function news:initialize()
        self.canvas = ink.canvas(0, -70, inkEAnchor.TopLeft)
        self.canvas:Reparent(self.inkPage, -1)

        self.buttons = require("modules/ui/pages/menuButtons").createMenu(self)

        self:setupHeroSection()
        self:setupNewsListPanel()
        self:setupDetailPanel()
        self:setupSettingsPanel()
        self:setupHelpButton()
        self:setupHelpOverlay()
end

function news:setupHeroSection()
        local heroY = 280
        local fullWidth = 2600
        local heroH = 160
        
        local heroPanel = ink.canvas(80, heroY, inkEAnchor.TopLeft)
        heroPanel:SetSize(Vector2.new({X = fullWidth, Y = heroH}))
        heroPanel:Reparent(self.canvas, -1)
        self.heroPanel = heroPanel
        
        local heroBg = ink.image(fullWidth/2, heroH/2, fullWidth, heroH, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_bg")
        heroBg.image.useNineSliceScale = true
        heroBg.image:SetTintColor(panelBg)
        heroBg.image:SetOpacity(0.95)
        heroBg.pos:Reparent(heroPanel, -1)
        
        local heroBorder = ink.image(fullWidth/2, heroH/2, fullWidth - 4, heroH - 4, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_fg")
        heroBorder.image.useNineSliceScale = true
        heroBorder.image:SetTintColor(cyanAccent)
        heroBorder.image:SetOpacity(0.5)
        heroBorder.pos:Reparent(heroPanel, -1)
        
        local newsIcon = ink.text(">>", 50, heroH/2, 60, cyanAccent)
        newsIcon:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        newsIcon:Reparent(heroPanel, -1)
        
        local titleLabel = ink.text("NEWS FEED", 140, heroH/2 - 15, 72, color.white)
        titleLabel:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        titleLabel:Reparent(heroPanel, -1)
        
        local subtitleLabel = ink.text("NIGHT CITY MARKET INTELLIGENCE", 140, heroH/2 + 45, 38, mediumText)
        subtitleLabel:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        subtitleLabel:Reparent(heroPanel, -1)
        
        self.newsCountLabel = ink.text("0 STORIES", fullWidth - 200, heroH/2, 52, cyanAccent)
        self.newsCountLabel:SetAnchorPoint(Vector2.new({X = 1, Y = 0.5}))
        self.newsCountLabel:Reparent(heroPanel, -1)
end

function news:setupNewsListPanel()
        local panelX = 80
        local panelY = 460
        local panelW = 1200
        local panelH = 700
        
        local listPanel = ink.canvas(panelX, panelY, inkEAnchor.TopLeft)
        listPanel:SetSize(Vector2.new({X = panelW, Y = panelH}))
        listPanel:Reparent(self.canvas, -1)
        self.listPanel = listPanel
        
        local listBg = ink.image(panelW/2, panelH/2, panelW, panelH, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_bg")
        listBg.image.useNineSliceScale = true
        listBg.image:SetTintColor(color.new(20, 30, 45, 1, 255))
        listBg.image:SetOpacity(0.85)
        listBg.pos:Reparent(listPanel, -1)
        
        local listBorder = ink.image(panelW/2, panelH/2, panelW - 4, panelH - 4, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_fg")
        listBorder.image.useNineSliceScale = true
        listBorder.image:SetTintColor(panelBorder)
        listBorder.pos:Reparent(listPanel, -1)
        
        local headerLabel = ink.text("LATEST HEADLINES", 50, 50, 48, cyanAccent)
        headerLabel:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        headerLabel:Reparent(listPanel, -1)
        
        local headerLine = ink.line(50, 90, panelW - 50, 90, cyanAccent, 2)
        headerLine:SetOpacity(0.4)
        headerLine:Reparent(listPanel, -1)
        
        self:setupScrollArea(listPanel, panelW, panelH)
end

function news:setupScrollArea(parent, panelW, panelH)
        self.scrollComponent = UIScroller.Create()

        local scrollPanel = self.scrollComponent:GetRootWidget()
        scrollPanel:SetAnchor(inkEAnchor.TopLeft)
        scrollPanel:SetMargin(inkMargin.new({ left = 30.0, top = 110.0 }))
        scrollPanel:SetSize(Vector2.new({ X = panelW - 60, Y = panelH - 130 }))
        scrollPanel:Reparent(parent, -1)

        local scrollContent = self.scrollComponent:GetContentWidget()

        self.buttonList = inkVerticalPanel.new()
        self.buttonList:SetName('list')
        self.buttonList:SetPadding(inkMargin.new({ left = 0.0, top = 10.0, right = 20.0 }))
        self.buttonList:SetChildMargin(inkMargin.new({ top = 12.0, bottom = 12.0 }))
        self.buttonList:SetFitToContent(true)
        self.buttonList:Reparent(scrollContent, -1)

        local newsItems = self.mod.market.newsManager:getNews()
        local displayedCount = 0
        local maxNewsToShow = 3

        for i = 1, #newsItems do
                if displayedCount >= maxNewsToShow then
                        break
                end
                local newsBtn = self:createNewsButton(newsItems[i], i)
                if newsBtn then
                        displayedCount = displayedCount + 1
                        newsBtn.canvas:SetAffectsLayoutWhenHidden(false)
                        newsBtn.canvas:Reparent(self.buttonList, -1)
                end
        end
        
        self.newsCountLabel:SetText(displayedCount .. " STORIES")

        Cron.NextTick(function()
                self.scrollComponent:UpdateContent(true)
        end)

        if #newsItems < 6 then
                self:toggleSlider(false)
        end
end

function news:toggleSlider(state)
        self.scrollComponent:GetRootWidget():GetWidgetByPathName(StringToName('sliderArea')):SetVisible(state)
end

function news:createNewsButton(name, index)
        local trigger = self.mod.market.triggerManager.triggers[name]
        if not trigger then
                return nil
        end
        
        local hasFactCondition = trigger.factCondition and trigger.factCondition ~= ""
        local factMet = hasFactCondition and Game.GetQuestsSystem():GetFactStr(trigger.factCondition) == 1
        local title, text = lang.getNewsText(name, factMet)
        
        if not title or title == "" then
                title = trigger.displayName or name
        end
        if not text or text == "" then
                text = "Market activity detected for " .. (trigger.displayName or name) .. "."
        end
        
        local button = require("modules/ui/widgets/button_texture"):new()
        button.x = 550
        button.y = 50
        button.sizeX = 1100
        button.sizeY = 100
        button.textColor = color.white
        button.textSize = 44
        button.bgPart = "cell_bg"
        button.fgPart = "cell_fg"
        button.bgColor = color.new(30, 45, 60, 1, 255)
        button.fgColor = color.new(60, 100, 120, 1, 255)
        button.useNineSlice = true

        button:initialize()
        button:registerCallbacks(self.eventCatcher)
        table.insert(self.newsButtons, button)

        local indexLabel = ink.text(string.format("%02d", index), -520, 0, 38, cyanAccent)
        indexLabel:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        indexLabel:Reparent(button.canvas, -1)
        
        local divider = ink.line(-485, -30, -485, 30, color.new(60, 100, 120, 1, 255), 2)
        divider:Reparent(button.canvas, -1)
        
        local titleText = ink.text(title, -465, 0, 46, lightText)
        titleText:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        titleText:Reparent(button.canvas, -1)
        
        button.newsName = name
        button.newsTitle = title
        button.newsText = text
        
        button.textWidget:SetText("")

        button.callback = function()
                self.locked = true
                self.selectedNews = button
                
                for _, b in pairs(self.newsButtons) do
                        b.fg.image:SetTintColor(color.new(60, 100, 120, 1, 255))
                        b.bg.image:SetTintColor(color.new(30, 45, 60, 1, 255))
                end
                
                button.fg.image:SetTintColor(cyanAccent)
                button.bg.image:SetTintColor(color.new(40, 60, 80, 1, 255))
                
                self:showNewsDetail(button.newsTitle, button.newsText)
        end

        button.hoverInCallback = function(bt)
                if not self.locked or self.selectedNews ~= bt then
                        bt.bg.image:SetTintColor(color.new(45, 65, 85, 1, 255))
                end
                
                if not self.locked then
                        self:showNewsDetail(bt.newsTitle, bt.newsText)
                end
        end
        
        button.hoverOutCallback = function(bt)
                if not self.locked or self.selectedNews ~= bt then
                        bt.bg.image:SetTintColor(color.new(30, 45, 60, 1, 255))
                end
                
                if not self.locked then
                        self:hideNewsDetail()
                end
        end

        return button
end

function news:setupDetailPanel()
        local panelX = 1300
        local panelY = 460
        local panelW = 1380
        local panelH = 700
        
        local detailPanel = ink.canvas(panelX, panelY, inkEAnchor.TopLeft)
        detailPanel:SetSize(Vector2.new({X = panelW, Y = panelH}))
        detailPanel:Reparent(self.canvas, -1)
        self.detailPanel = detailPanel
        
        local detailBg = ink.image(panelW/2, panelH/2, panelW, panelH, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_bg")
        detailBg.image.useNineSliceScale = true
        detailBg.image:SetTintColor(color.new(20, 30, 45, 1, 255))
        detailBg.image:SetOpacity(0.85)
        detailBg.pos:Reparent(detailPanel, -1)
        
        local detailBorder = ink.image(panelW/2, panelH/2, panelW - 4, panelH - 4, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_fg")
        detailBorder.image.useNineSliceScale = true
        detailBorder.image:SetTintColor(panelBorder)
        detailBorder.pos:Reparent(detailPanel, -1)
        
        local headerLabel = ink.text("STORY DETAILS", 50, 50, 48, cyanAccent)
        headerLabel:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        headerLabel:Reparent(detailPanel, -1)
        
        local headerLine = ink.line(50, 90, panelW - 50, 90, cyanAccent, 2)
        headerLine:SetOpacity(0.4)
        headerLine:Reparent(detailPanel, -1)
        
        self.detailContent = ink.canvas(0, 0, inkEAnchor.TopLeft)
        self.detailContent:SetVisible(false)
        self.detailContent:Reparent(detailPanel, -1)
        
        self.detailTitle = ink.text("", 50, 150, 60, color.white)
        self.detailTitle:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        self.detailTitle:Reparent(self.detailContent, -1)
        
        self.detailTitleLine = ink.line(50, 195, 400, 195, cyanAccent, 3)
        self.detailTitleLine:Reparent(self.detailContent, -1)
        
        self.detailText = ink.text("", 50, 250, 46, lightText)
        self.detailText:SetAnchorPoint(Vector2.new({X = 0, Y = 0}))
        self.detailText:Reparent(self.detailContent, -1)
        
        self.emptyState = ink.canvas(0, 0, inkEAnchor.TopLeft)
        self.emptyState:Reparent(detailPanel, -1)
        
        local emptyIcon = ink.text("<<", panelW/2, panelH/2 - 40, 90, color.new(70, 110, 130, 1, 255))
        emptyIcon:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        emptyIcon:Reparent(self.emptyState, -1)
        
        local emptyText = ink.text("SELECT A HEADLINE", panelW/2, panelH/2 + 50, 48, mediumText)
        emptyText:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        emptyText:Reparent(self.emptyState, -1)
        
        local emptyHint = ink.text("Click or hover over a story to read more", panelW/2, panelH/2 + 120, 38, mediumText)
        emptyHint:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        emptyHint:Reparent(self.emptyState, -1)
end

function news:showNewsDetail(title, text)
        self.emptyState:SetVisible(false)
        self.detailContent:SetVisible(true)
        
        self.detailTitle:SetText(title)
        self.detailText:SetText(utils.wrap(text, 48))
        
        -- Security Score: Award bonus for reading news (with cooldown)
        if self.mod.market.securityManager then
                self.mod.market.securityManager:onNewsRead()
        end
        
        Cron.NextTick(function()
                local titleWidth = self.detailTitle:GetDesiredWidth()
                ink.updateLine(self.detailTitleLine, 50, 195, 50 + math.min(titleWidth, 1280), 195)
        end)
end

function news:hideNewsDetail()
        self.emptyState:SetVisible(true)
        self.detailContent:SetVisible(false)
end

function news:setupSettingsPanel()
        local panelX = 80
        local panelY = 1180
        local panelW = 2600
        local panelH = 120
        
        local settingsPanel = ink.canvas(panelX, panelY, inkEAnchor.TopLeft)
        settingsPanel:SetSize(Vector2.new({X = panelW, Y = panelH}))
        settingsPanel:Reparent(self.canvas, -1)
        
        local settingsBg = ink.image(panelW/2, panelH/2, panelW, panelH, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_bg")
        settingsBg.image.useNineSliceScale = true
        settingsBg.image:SetTintColor(color.new(20, 30, 45, 1, 255))
        settingsBg.image:SetOpacity(0.85)
        settingsBg.pos:Reparent(settingsPanel, -1)
        
        local settingsBorder = ink.image(panelW/2, panelH/2, panelW - 4, panelH - 4, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_fg")
        settingsBorder.image.useNineSliceScale = true
        settingsBorder.image:SetTintColor(panelBorder)
        settingsBorder.pos:Reparent(settingsPanel, -1)
        
        local settingsLabel = ink.text("PHONE NOTIFICATIONS", 50, 35, 48, lightText)
        settingsLabel:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        settingsLabel:Reparent(settingsPanel, -1)
        
        local descLabel = ink.text("Receive breaking news alerts on your phone  (You can enable, disable, and edit this in settings.json)", 50, 80, 36, mediumText)
        descLabel:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        descLabel:Reparent(settingsPanel, -1)
        
        self:setupToggleButton(settingsPanel, panelW - 150, panelH/2)
end

function news:setupToggleButton(parent, x, y)
        local btnSize = 70
        
        local button = require("modules/ui/widgets/button_texture"):new()
        button.x = x
        button.y = y
        button.sizeX = btnSize
        button.sizeY = btnSize
        button.textColor = color.white
        button.textSize = 44
        button.bgPart = "cell_bg"
        button.fgPart = "cell_fg"
        button.bgColor = color.new(30, 45, 60, 1, 255)
        button.fgColor = cyanAccent
        button.useNineSlice = true

        button:initialize()
        button.canvas:Reparent(parent, -1)

        button.cross = ink.canvas(btnSize/2, btnSize/2, inkEAnchor.Centered)
        button.cross:Reparent(button.canvas, -1)
        
        local checkmark1 = ink.rect(0, 8, 40, 6, cyanAccent, 45, Vector2.new({X = 0.5, Y = 0.5}))
        checkmark1:Reparent(button.cross, -1)
        local checkmark2 = ink.rect(12, -5, 55, 6, cyanAccent, -45, Vector2.new({X = 0.5, Y = 0.5}))
        checkmark2:Reparent(button.cross, -1)

        if not self.mod.market.newsManager.settings.notifications then
                button.cross:SetVisible(false)
                button.fg.image:SetTintColor(color.new(60, 100, 120, 1, 255))
        end

        button:registerCallbacks(self.eventCatcher)

        button.callback = function()
                self.mod.market.newsManager.settings.notifications = not self.mod.market.newsManager.settings.notifications
                button.cross:SetVisible(self.mod.market.newsManager.settings.notifications)
                if self.mod.market.newsManager.settings.notifications then
                        button.fg.image:SetTintColor(cyanAccent)
                else
                        button.fg.image:SetTintColor(color.new(60, 100, 120, 1, 255))
                end
        end

        self.settingsButton = button
end

function news:setupHelpButton()
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

function news:setupHelpOverlay()
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

        local helpTitle = ink.text("NEWS FEED GUIDE", panelW / 2, 50, 64, color.cyan)
        helpTitle:SetAnchorPoint(0.5, 0.5)
        helpTitle:Reparent(self.helpCanvas, -1)

        local subtitle = ink.text("Understanding Night City Market Intelligence", panelW / 2, 100, 36, color.new(200, 220, 240, 1, 255))
        subtitle:SetAnchorPoint(0.5, 0.5)
        subtitle:Reparent(self.helpCanvas, -1)

        local col1X = 100
        local col2X = 950
        local col3X = 1800

        local sec1Title = ink.text("MARKET INTELLIGENCE", col1X, 180, 48, cyanAccent)
        sec1Title:Reparent(self.helpCanvas, -1)

        local sec1Line1 = ink.text("News stories provide insight into", col1X, 240, 38, lightText)
        sec1Line1:Reparent(self.helpCanvas, -1)

        local sec1Line2 = ink.text("market trends and stock performance.", col1X, 290, 38, lightText)
        sec1Line2:Reparent(self.helpCanvas, -1)

        local sec1Line3 = ink.text("Breaking news can trigger", col1X, 360, 38, lightText)
        sec1Line3:Reparent(self.helpCanvas, -1)

        local sec1Line4 = ink.text("significant price movements.", col1X, 410, 38, lightText)
        sec1Line4:Reparent(self.helpCanvas, -1)

        local sec1Line5 = ink.text("Stay informed to trade smarter.", col1X, 480, 42, color.lime)
        sec1Line5:Reparent(self.helpCanvas, -1)

        local sec2Title = ink.text("READING NEWS", col2X, 180, 48, cyanAccent)
        sec2Title:Reparent(self.helpCanvas, -1)

        local sec2Line1 = ink.text("HOVER over headlines to preview", col2X, 240, 38, lightText)
        sec2Line1:Reparent(self.helpCanvas, -1)

        local sec2Line2 = ink.text("the story content on the right.", col2X, 290, 38, lightText)
        sec2Line2:Reparent(self.helpCanvas, -1)

        local sec2Line3 = ink.text("CLICK a headline to lock it", col2X, 360, 38, lightText)
        sec2Line3:Reparent(self.helpCanvas, -1)

        local sec2Line4 = ink.text("and read the full story.", col2X, 410, 38, lightText)
        sec2Line4:Reparent(self.helpCanvas, -1)

        local sec2Line5 = ink.text("Click again to unlock.", col2X, 480, 42, color.yellow)
        sec2Line5:Reparent(self.helpCanvas, -1)

        local sec3Title = ink.text("NEWS TYPES", col3X, 180, 48, cyanAccent)
        sec3Title:Reparent(self.helpCanvas, -1)

        local sec3Line1 = ink.text("POSITIVE news = prices may rise", col3X, 240, 38, color.lime)
        sec3Line1:Reparent(self.helpCanvas, -1)

        local sec3Line2 = ink.text("NEGATIVE news = prices may fall", col3X, 300, 38, color.red)
        sec3Line2:Reparent(self.helpCanvas, -1)

        local sec3Line3 = ink.text("NEUTRAL news = market stable", col3X, 360, 38, color.yellow)
        sec3Line3:Reparent(self.helpCanvas, -1)

        local sec3Line4 = ink.text("Watch for breaking stories", col3X, 440, 38, lightText)
        sec3Line4:Reparent(self.helpCanvas, -1)

        local sec3Line5 = ink.text("to catch early opportunities!", col3X, 490, 42, cyanAccent)
        sec3Line5:Reparent(self.helpCanvas, -1)

        local divider1 = ink.rect(80, 560, panelW - 160, 2, mediumText)
        divider1:Reparent(self.helpCanvas, -1)

        local tipLabel = ink.text("PRO TIP:", 100, 620, 48, color.new(255, 215, 0, 1, 255))
        tipLabel:Reparent(self.helpCanvas, -1)

        local tipText = ink.text("Corporation-specific news has the biggest impact on that company's stock price. Act fast!", 320, 620, 42, lightText)
        tipText:Reparent(self.helpCanvas, -1)

        local tipLabel2 = ink.text("NOTIFICATIONS:", 100, 700, 48, cyanAccent)
        tipLabel2:Reparent(self.helpCanvas, -1)

        local tipText2 = ink.text("Toggle phone alerts in settings to get notified when breaking market news drops.", 520, 700, 42, lightText)
        tipText2:Reparent(self.helpCanvas, -1)

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

function news:toggleHelp()
        self.helpVisible = not self.helpVisible
        if self.helpVisible then
                self.helpCanvas:Reparent(self.canvas, -1)
        end
        self.helpCanvas:SetVisible(self.helpVisible)
end

function news:uninitialize()
        Cron.Halt(self.refreshCron)

        if not self.canvas then return end
        self.newsButtons = {}
        self.eventCatcher.removeSubscriber(self.button)
        self.inkPage:RemoveChild(self.canvas)
        self.inkPage:RemoveChild(self.buttons)
        self.canvas = nil
        self.locked = false
        self.selectedNews = nil
end

return news
