local ink = require("modules/ui/inkHelper")
local color = require("modules/ui/color")
local lang = require("modules/utils/lang")
local Cron = require("modules/external/Cron")
local utils = require("modules/utils/utils")

insurance = {}

local lightText = color.new(220, 230, 245, 1, 255)
local mediumText = color.new(180, 195, 215, 1, 255)
local cyanAccent = color.new(94, 246, 255, 1, 255)
local panelBg = color.new(15, 25, 40, 1, 255)
local panelBorder = color.new(60, 100, 120, 0.6, 255)

function insurance:new(inkPage, controller, eventCatcher, mod)
        local o = {}

        o.mod = mod
    o.inkPage = inkPage
        o.controller = controller
        o.eventCatcher = eventCatcher
        o.pageName = "insurance"

        o.canvas = nil
        o.refreshCron = nil
        o.securityManager = mod.market.securityManager
        o.tierButtons = {}
        o.helpVisible = false

        self.__index = self
        return setmetatable(o, self)
end

function insurance:initialize()
        self.refreshCron = Cron.Every(2, function()
                self:refresh()
        end)

        self.canvas = ink.canvas(0, -70, inkEAnchor.TopLeft)
        self.canvas:Reparent(self.inkPage, -1)

        self.buttons = require("modules/ui/pages/menuButtons").createMenu(self)

        self:setupHeroSection()
        self:setupSecurityPanel()
        self:setupInsurancePlansPanel()
        self:setupYourPlanPanel()
        self:setupHelpButton()
        self:setupHelpOverlay()
        self:setupScamPopup()
        self:setupConfirmPopup()
        self:showData()
end

function insurance:setupHeroSection()
        local heroY = 280
        local fullWidth = 2600
        local heroH = 160

        local heroPanel = ink.canvas(80, heroY, inkEAnchor.TopLeft)
        heroPanel:SetSize(Vector2.new({X = fullWidth, Y = heroH}))
        heroPanel:Reparent(self.canvas, -1)

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

        local icon = ink.text(">>", 50, heroH/2, 60, cyanAccent)
        icon:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        icon:Reparent(heroPanel, -1)

        local titleLabel = ink.text("CPIC INSURANCE", 140, heroH/2 - 15, 72, color.white)
        titleLabel:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        titleLabel:Reparent(heroPanel, -1)

        local subtitleLabel = ink.text("CYBER PUNK INSURANCE CORPORATION", 140, heroH/2 + 45, 36, mediumText)
        subtitleLabel:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        subtitleLabel:Reparent(heroPanel, -1)

        local tagline = ink.text("PROTECTING YOUR DIGITAL ASSETS", fullWidth - 200, heroH/2, 42, cyanAccent)
        tagline:SetAnchorPoint(Vector2.new({X = 1, Y = 0.5}))
        tagline:Reparent(heroPanel, -1)
end

function insurance:setupSecurityPanel()
        local panelX = 80
        local panelY = 460
        local panelW = 700
        local panelH = 700

        local secPanel = ink.canvas(panelX, panelY, inkEAnchor.TopLeft)
        secPanel:SetSize(Vector2.new({X = panelW, Y = panelH}))
        secPanel:Reparent(self.canvas, -1)
        self.securityCanvas = secPanel

        local bg = ink.image(panelW/2, panelH/2, panelW, panelH, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_bg")
        bg.image.useNineSliceScale = true
        bg.image:SetTintColor(color.new(20, 30, 45, 1, 255))
        bg.image:SetOpacity(0.85)
        bg.pos:Reparent(secPanel, -1)

        local border = ink.image(panelW/2, panelH/2, panelW - 4, panelH - 4, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_fg")
        border.image.useNineSliceScale = true
        border.image:SetTintColor(panelBorder)
        border.pos:Reparent(secPanel, -1)

        local headerLabel = ink.text("SECURITY SCORE", panelW/2, 50, 52, cyanAccent)
        headerLabel:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        headerLabel:Reparent(secPanel, -1)

        local headerLine = ink.line(50, 90, panelW - 50, 90, cyanAccent, 2)
        headerLine:SetOpacity(0.4)
        headerLine:Reparent(secPanel, -1)

        self.scoreDisplay = ink.text("50", panelW/2 + 40, 200, 180, cyanAccent)
        self.scoreDisplay:SetAnchorPoint(Vector2.new({X = 1, Y = 0.5}))
        self.scoreDisplay:Reparent(secPanel, -1)

        self.scoreLabel = ink.text("/100", panelW/2 + 55, 200, 60, mediumText)
        self.scoreLabel:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
        self.scoreLabel:Reparent(secPanel, -1)

        self.scoreStatus = ink.text("MODERATE", panelW/2, 320, 56, color.yellow)
        self.scoreStatus:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        self.scoreStatus:Reparent(secPanel, -1)

        local divider1 = ink.line(50, 380, panelW - 50, 380, mediumText, 2)
        divider1:SetOpacity(0.3)
        divider1:Reparent(secPanel, -1)

        self.securityTips = ink.text("Tip: Logout properly to improve score", panelW/2, 430, 40, lightText)
        self.securityTips:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        self.securityTips:Reparent(secPanel, -1)

        local divider2 = ink.line(50, 480, panelW - 50, 480, mediumText, 2)
        divider2:SetOpacity(0.3)
        divider2:Reparent(secPanel, -1)

        local disclaimer1 = ink.text("Not affiliated with any real insurer.", panelW/2, 530, 36, mediumText)
        disclaimer1:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        disclaimer1:Reparent(secPanel, -1)

        local disclaimer2 = ink.text("Night City FDIC did NOT approve this.", panelW/2, 580, 36, mediumText)
        disclaimer2:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        disclaimer2:Reparent(secPanel, -1)

        local disclaimer3 = ink.text("Parody only.", panelW/2, 630, 36, mediumText)
        disclaimer3:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        disclaimer3:Reparent(secPanel, -1)
end

function insurance:setupInsurancePlansPanel()
        local panelX = 800
        local panelY = 460
        local panelW = 1100
        local panelH = 870

        local plansPanel = ink.canvas(panelX, panelY, inkEAnchor.TopLeft)
        plansPanel:SetSize(Vector2.new({X = panelW, Y = panelH}))
        plansPanel:Reparent(self.canvas, -1)
        self.tiersCanvas = plansPanel

        local bg = ink.image(panelW/2, panelH/2, panelW, panelH, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_bg")
        bg.image.useNineSliceScale = true
        bg.image:SetTintColor(color.new(20, 30, 45, 1, 255))
        bg.image:SetOpacity(0.85)
        bg.pos:Reparent(plansPanel, -1)

        local border = ink.image(panelW/2, panelH/2, panelW - 4, panelH - 4, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_fg")
        border.image.useNineSliceScale = true
        border.image:SetTintColor(panelBorder)
        border.pos:Reparent(plansPanel, -1)

        local headerLabel = ink.text("INSURANCE PLANS", panelW/2, 50, 52, cyanAccent)
        headerLabel:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        headerLabel:Reparent(plansPanel, -1)

        local headerLine = ink.line(50, 90, panelW - 50, 90, cyanAccent, 2)
        headerLine:SetOpacity(0.4)
        headerLine:Reparent(plansPanel, -1)

        local function formatNumber(num)
                if num >= 1000000 then
                        return tostring(math.floor(num / 1000000)) .. "M"
                elseif num >= 1000 then
                        return tostring(math.floor(num / 1000)) .. "K"
                else
                        return tostring(num)
                end
        end

        local tierConfigs = {}
        local success = pcall(function()
                if self.securityManager and self.securityManager.settings and 
                   self.securityManager.settings.insurance and 
                   self.securityManager.settings.insurance.cpicInsurance and
                   self.securityManager.settings.insurance.cpicInsurance.tiers then
                        tierConfigs = self.securityManager.settings.insurance.cpicInsurance.tiers
                end
        end)

        local basicData = tierConfigs.basic or { monthlyPremium = 500, coveragePercent = 0.25, maxPayout = 100000 }
        local standardData = tierConfigs.standard or { monthlyPremium = 2000, coveragePercent = 0.40, maxPayout = 500000 }
        local premiumData = tierConfigs.premium or { monthlyPremium = 5000, coveragePercent = 0.50, maxPayout = 2000000 }
        local platinumData = tierConfigs.platinum or { monthlyPremium = 15000, coveragePercent = 0.75, maxPayout = 10000000 }

        local tiers = {
                {name = "BASIC", premium = formatNumber(basicData.monthlyPremium) .. "/month", coverage = tostring(math.floor(basicData.coveragePercent * 100)) .. "%", maxPayout = formatNumber(basicData.maxPayout), tier = "basic", y = 120},
                {name = "STANDARD", premium = formatNumber(standardData.monthlyPremium) .. "/month", coverage = tostring(math.floor(standardData.coveragePercent * 100)) .. "%", maxPayout = formatNumber(standardData.maxPayout), tier = "standard", y = 245},
                {name = "PREMIUM", premium = formatNumber(premiumData.monthlyPremium) .. "/month", coverage = tostring(math.floor(premiumData.coveragePercent * 100)) .. "%", maxPayout = formatNumber(premiumData.maxPayout), tier = "premium", y = 370},
                {name = "PLATINUM", premium = formatNumber(platinumData.monthlyPremium) .. "/month", coverage = tostring(math.floor(platinumData.coveragePercent * 100)) .. "%", maxPayout = formatNumber(platinumData.maxPayout), tier = "platinum", y = 495},
                {name = "DIAMOND", premium = "100K ONE-TIME", coverage = "100%", maxPayout = "ALL", tier = "diamond", y = 620, isDiamond = true}
        }

        local vipTagline = ink.text("VIP EXCLUSIVE - Lifetime protection for the elite of Night City", panelW/2, 765, 34, color.new(255, 215, 0, 1, 255))
        vipTagline:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        vipTagline:Reparent(plansPanel, -1)

        local vipTagline2 = ink.text("\"Why pay monthly when you can pay ONCE and be covered FOREVER?\"", panelW/2, 805, 30, lightText)
        vipTagline2:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        vipTagline2:Reparent(plansPanel, -1)

        local vipTagline3 = ink.text("- Trusted by 0 verified customers", panelW/2, 840, 28, color.new(200, 210, 225, 1, 255))
        vipTagline3:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        vipTagline3:Reparent(plansPanel, -1)

        self.tierLabels = {}

        local goldColor = color.new(255, 215, 0, 1, 255)

        for _, t in ipairs(tiers) do
                local rowCanvas = ink.canvas(50, t.y, inkEAnchor.TopLeft)
                rowCanvas:Reparent(plansPanel, -1)

                local rowW = panelW - 100
                local rowH = 120

                local button = require("modules/ui/widgets/button_texture"):new()
                button.x = rowW/2
                button.y = rowH/2
                button.sizeX = rowW
                button.sizeY = rowH
                button.textColor = color.white
                button.textSize = 1
                button.text = ""
                button.bgPart = "cell_bg"
                button.fgPart = "cell_fg"

                if t.isDiamond then
                        button.bgColor = color.new(40, 35, 20, 1, 255)
                        button.fgColor = goldColor
                else
                        button.bgColor = color.new(30, 45, 60, 1, 255)
                        button.fgColor = color.new(60, 100, 120, 1, 255)
                end
                button.useNineSlice = true
                button.tierName = t.tier

                button.callback = function()
                        self:purchaseTier(t.tier)
                end

                button:initialize()
                button:registerCallbacks(self.eventCatcher)
                button.canvas:Reparent(rowCanvas, -1)

                local tierNameColor = t.isDiamond and goldColor or cyanAccent
                local nameText = ink.text(t.name, 30, rowH/2, 48, tierNameColor)
                nameText:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
                nameText:Reparent(rowCanvas, -1)

                local premiumLabel = ink.text(t.premium, 260, rowH/2, 42, lightText)
                premiumLabel:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
                premiumLabel:Reparent(rowCanvas, -1)

                local coverageColor = t.isDiamond and goldColor or color.lime
                local coverageText = ink.text(t.coverage, 550, rowH/2, 56, coverageColor)
                coverageText:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
                coverageText:Reparent(rowCanvas, -1)

                -- RIGHT SIDE LAYOUT (FIXED): keep "Max:" + value from smashing into BUY
                local buyTextColor = t.isDiamond and goldColor or cyanAccent
                local buyX = rowW - 30
                local buyText = ink.text("BUY", buyX, rowH/2, 48, buyTextColor)
                buyText:SetAnchorPoint(Vector2.new({X = 1, Y = 0.5}))
                buyText:Reparent(rowCanvas, -1)

                local maxTextColor = t.isDiamond and goldColor or lightText
                local gapFromBuy = 150
                local labelGap = 170
                local maxRightX = buyX - gapFromBuy
                local maxLabelX = maxRightX - labelGap

                local minMaxLabelX = 650
                if maxLabelX < minMaxLabelX then
                        local delta = minMaxLabelX - maxLabelX
                        maxLabelX = maxLabelX + delta
                        maxRightX = maxRightX + delta
                end

                local maxLabel = ink.text("Max:", maxLabelX, rowH/2, 38, mediumText)
                maxLabel:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
                maxLabel:Reparent(rowCanvas, -1)

                local maxText = ink.text(t.maxPayout, maxRightX, rowH/2, 46, maxTextColor)
                maxText:SetAnchorPoint(Vector2.new({X = 1, Y = 0.5}))
                maxText:Reparent(rowCanvas, -1)

                self.tierLabels[t.tier] = {
                        premiumLabel = premiumLabel,
                        coverageText = coverageText,
                        maxText = maxText
                }

                table.insert(self.tierButtons, button)
        end
end

function insurance:purchaseDiamond()
        local diamondCost = ConfigManager.get("insurance.tiers.diamond.oneTimeCost") or 100000

        local playerMoney = 0
        local success = pcall(function()
                playerMoney = Game.GetTransactionSystem():GetItemQuantity(Game.GetPlayer(), GetSingleton("gameItemID"):FromTDBID(TweakDBID.new("Items.money")))
        end)

        if not success or playerMoney < diamondCost then
                return false, "Insufficient funds"
        end

        local removeSuccess = pcall(function()
                Game.GetTransactionSystem():RemoveItem(Game.GetPlayer(), GetSingleton("gameItemID"):FromTDBID(TweakDBID.new("Items.money")), diamondCost)
        end)

        if not removeSuccess then
                return false, "Transaction failed"
        end

        self:showScamPopup()
        return true
end

function insurance:setupScamPopup()
        self.scamVisible = false
        self.scamCanvas = ink.canvas(80, 250, inkEAnchor.TopLeft)
        self.scamCanvas:Reparent(self.canvas, -1)
        self.scamCanvas:SetVisible(false)

        local panelW = 2700
        local panelH = 900

        local bgRect = ink.rect(0, 0, panelW, panelH, HDRColor.new({ Red = 0.04, Green = 0.02, Blue = 0.02, Alpha = 0.98 }))
        bgRect:Reparent(self.scamCanvas, -1)

        local redBorder = color.new(255, 80, 80, 1, 255)
        local borderTop = ink.rect(0, 0, panelW, 4, redBorder)
        borderTop:Reparent(self.scamCanvas, -1)

        local borderBottom = ink.rect(0, panelH - 4, panelW, 4, redBorder)
        borderBottom:Reparent(self.scamCanvas, -1)

        local borderLeft = ink.rect(0, 0, 4, panelH, redBorder)
        borderLeft:Reparent(self.scamCanvas, -1)

        local borderRight = ink.rect(panelW - 4, 0, 4, panelH, redBorder)
        borderRight:Reparent(self.scamCanvas, -1)

        local goldColor = color.new(255, 215, 0, 1, 255)
        local redColor = color.new(255, 80, 80, 1, 255)

        local title = ink.text("TRANSACTION COMPLETE", panelW/2, 70, 72, goldColor)
        title:SetAnchorPoint(0.5, 0.5)
        title:Reparent(self.scamCanvas, -1)

        local subtitle = ink.text("Your Diamond Tier membership has been processed", panelW/2, 130, 42, lightText)
        subtitle:SetAnchorPoint(0.5, 0.5)
        subtitle:Reparent(self.scamCanvas, -1)

        local divider1 = ink.rect(100, 180, panelW - 200, 3, redColor)
        divider1:Reparent(self.scamCanvas, -1)

        local line1 = ink.text("Just kidding.", panelW/2, 250, 64, redColor)
        line1:SetAnchorPoint(0.5, 0.5)
        line1:Reparent(self.scamCanvas, -1)

        local line2 = ink.text("Your 100,000 eddies are gone. Forever. You get nothing.", panelW/2, 330, 48, lightText)
        line2:SetAnchorPoint(0.5, 0.5)
        line2:Reparent(self.scamCanvas, -1)

        local divider2 = ink.rect(100, 400, panelW - 200, 2, mediumText)
        divider2:Reparent(self.scamCanvas, -1)

        local line3 = ink.text("Welcome to Night City, where the fine print reads:", panelW/2, 460, 42, mediumText)
        line3:SetAnchorPoint(0.5, 0.5)
        line3:Reparent(self.scamCanvas, -1)

        local line4 = ink.text("\"If it sounds too good to be true, a corpo already owns it.\"", panelW/2, 520, 48, cyanAccent)
        line4:SetAnchorPoint(0.5, 0.5)
        line4:Reparent(self.scamCanvas, -1)

        local divider3 = ink.rect(100, 580, panelW - 200, 2, mediumText)
        divider3:Reparent(self.scamCanvas, -1)

        local line5 = ink.text("100% coverage? Infinite payout? One-time fee?", panelW/2, 640, 42, lightText)
        line5:SetAnchorPoint(0.5, 0.5)
        line5:Reparent(self.scamCanvas, -1)

        local line6 = ink.text("In what world does that exist? Not this one.", panelW/2, 700, 42, lightText)
        line6:SetAnchorPoint(0.5, 0.5)
        line6:Reparent(self.scamCanvas, -1)

        local line7 = ink.text("CPIC Insurance thanks you for your... donation.", panelW/2, 770, 48, goldColor)
        line7:SetAnchorPoint(0.5, 0.5)
        line7:Reparent(self.scamCanvas, -1)

        self.closeScamButton = require("modules/ui/widgets/button_texture"):new()
        self.closeScamButton.x = panelW/2
        self.closeScamButton.y = 850
        self.closeScamButton.sizeX = 300
        self.closeScamButton.sizeY = 70
        self.closeScamButton.textSize = 44
        self.closeScamButton.text = "GOT IT"
        self.closeScamButton.bgPart = "cell_bg"
        self.closeScamButton.fgPart = "cell_fg"
        self.closeScamButton.bgColor = redColor
        self.closeScamButton.fgColor = redColor
        self.closeScamButton.textColor = color.white
        self.closeScamButton.useNineSlice = true

        self.closeScamButton.callback = function()
                self:hideScamPopup()
        end

        self.closeScamButton:initialize()
        self.closeScamButton:registerCallbacks(self.eventCatcher)
        self.closeScamButton.canvas:Reparent(self.scamCanvas, -1)
end

function insurance:showScamPopup()
        self.scamVisible = true
        self.scamCanvas:Reparent(self.canvas, -1)
        self.scamCanvas:SetVisible(true)
end

function insurance:hideScamPopup()
        self.scamVisible = false
        self.scamCanvas:SetVisible(false)
end

function insurance:setupConfirmPopup()
        self.confirmVisible = false
        self.pendingTier = nil
        self.confirmCanvas = ink.canvas(80, 250, inkEAnchor.TopLeft)
        self.confirmCanvas:Reparent(self.canvas, -1)
        self.confirmCanvas:SetVisible(false)

        local panelW = 2700
        local panelH = 500

        local bgRect = ink.rect(0, 0, panelW, panelH, HDRColor.new({ Red = 0.03, Green = 0.06, Blue = 0.08, Alpha = 0.98 }))
        bgRect:Reparent(self.confirmCanvas, -1)

        local borderTop = ink.rect(0, 0, panelW, 4, color.cyan)
        borderTop:Reparent(self.confirmCanvas, -1)

        local borderBottom = ink.rect(0, panelH - 4, panelW, 4, color.cyan)
        borderBottom:Reparent(self.confirmCanvas, -1)

        local borderLeft = ink.rect(0, 0, 4, panelH, color.cyan)
        borderLeft:Reparent(self.confirmCanvas, -1)

        local borderRight = ink.rect(panelW - 4, 0, 4, panelH, color.cyan)
        borderRight:Reparent(self.confirmCanvas, -1)

        local confirmTitle = ink.text("CONFIRM INSURANCE PURCHASE", panelW / 2, 60, 64, cyanAccent)
        confirmTitle:SetAnchorPoint(0.5, 0.5)
        confirmTitle:Reparent(self.confirmCanvas, -1)

        local divider1 = ink.rect(80, 110, panelW - 160, 2, mediumText)
        divider1:Reparent(self.confirmCanvas, -1)

        self.confirmMessage = ink.text("You are about to purchase the BASIC insurance plan.", panelW / 2, 170, 48, lightText)
        self.confirmMessage:SetAnchorPoint(0.5, 0.5)
        self.confirmMessage:Reparent(self.confirmCanvas, -1)

        self.confirmDetails = ink.text("Monthly premium will be charged automatically.", panelW / 2, 230, 42, mediumText)
        self.confirmDetails:SetAnchorPoint(0.5, 0.5)
        self.confirmDetails:Reparent(self.confirmCanvas, -1)

        local warningText = ink.text("Are you sure you want to proceed?", panelW / 2, 300, 48, color.yellow)
        warningText:SetAnchorPoint(0.5, 0.5)
        warningText:Reparent(self.confirmCanvas, -1)

        local buttonY = 420
        local buttonSpacing = 400

        self.confirmYesButton = require("modules/ui/widgets/button_texture"):new()
        self.confirmYesButton.x = panelW / 2 - buttonSpacing / 2
        self.confirmYesButton.y = buttonY
        self.confirmYesButton.sizeX = 300
        self.confirmYesButton.sizeY = 80
        self.confirmYesButton.textSize = 48
        self.confirmYesButton.text = "YES"
        self.confirmYesButton.bgPart = "cell_bg"
        self.confirmYesButton.fgPart = "cell_fg"
        self.confirmYesButton.bgColor = color.new(30, 80, 50, 1, 255)
        self.confirmYesButton.fgColor = color.lime
        self.confirmYesButton.textColor = color.white
        self.confirmYesButton.useNineSlice = true

        self.confirmYesButton.callback = function()
                self:confirmPurchase()
        end

        self.confirmYesButton:initialize()
        self.confirmYesButton:registerCallbacks(self.eventCatcher)
        self.confirmYesButton.canvas:Reparent(self.confirmCanvas, -1)

        self.confirmNoButton = require("modules/ui/widgets/button_texture"):new()
        self.confirmNoButton.x = panelW / 2 + buttonSpacing / 2
        self.confirmNoButton.y = buttonY
        self.confirmNoButton.sizeX = 300
        self.confirmNoButton.sizeY = 80
        self.confirmNoButton.textSize = 48
        self.confirmNoButton.text = "NO"
        self.confirmNoButton.bgPart = "cell_bg"
        self.confirmNoButton.fgPart = "cell_fg"
        self.confirmNoButton.bgColor = color.new(80, 30, 30, 1, 255)
        self.confirmNoButton.fgColor = color.new(200, 60, 60, 1, 255)
        self.confirmNoButton.textColor = color.white
        self.confirmNoButton.useNineSlice = true

        self.confirmNoButton.callback = function()
                self:hideConfirmPopup()
        end

        self.confirmNoButton:initialize()
        self.confirmNoButton:registerCallbacks(self.eventCatcher)
        self.confirmNoButton.canvas:Reparent(self.confirmCanvas, -1)
end

function insurance:showConfirmPopup(tier)
        self.pendingTier = tier

        local tierNames = {
                basic = "BASIC",
                standard = "STANDARD",
                premium = "PREMIUM",
                platinum = "PLATINUM",
                diamond = "DIAMOND"
        }

        local tierName = tierNames[tier] or tier:upper()
        self.confirmMessage:SetText("You are about to purchase the " .. tierName .. " insurance plan.")

        local tierData = nil
        pcall(function()
                if self.securityManager and self.securityManager.settings and 
                   self.securityManager.settings.insurance and 
                   self.securityManager.settings.insurance.cpicInsurance and
                   self.securityManager.settings.insurance.cpicInsurance.tiers then
                        tierData = self.securityManager.settings.insurance.cpicInsurance.tiers[tier]
                end
        end)

        if tier == "diamond" then
                self.confirmDetails:SetText("One-time payment: 100,000 E$  |  Coverage: 100%")
        elseif tierData then
                local premium = tierData.monthlyPremium or 0
                local coverage = (tierData.coveragePercent or 0) * 100
                self.confirmDetails:SetText("Premium: " .. tostring(premium) .. " E$/month  |  Coverage: " .. tostring(coverage) .. "%")
        else
                self.confirmDetails:SetText("Monthly premium will be charged automatically.")
        end

        self.confirmVisible = true
        self.confirmCanvas:Reparent(self.canvas, -1)
        self.confirmCanvas:SetVisible(true)
end

function insurance:hideConfirmPopup()
        self.confirmVisible = false
        self.pendingTier = nil
        self.confirmCanvas:SetVisible(false)
end

function insurance:confirmPurchase()
        if self.pendingTier then
                if self.pendingTier == "diamond" then
                        local success = self:purchaseDiamond()
                        -- Diamond scam popup handles itself
                else
                        local success, message = self.securityManager:purchaseInsurance(self.pendingTier)
                        if success then
                                self:showData()
                        end
                end
        end
        self:hideConfirmPopup()
end

function insurance:setupYourPlanPanel()
        local panelX = 1920
        local panelY = 460
        local panelW = 760
        local panelH = 870

        local planPanel = ink.canvas(panelX, panelY, inkEAnchor.TopLeft)
        planPanel:SetSize(Vector2.new({X = panelW, Y = panelH}))
        planPanel:Reparent(self.canvas, -1)
        self.currentCanvas = planPanel

        local bg = ink.image(panelW/2, panelH/2, panelW, panelH, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_bg")
        bg.image.useNineSliceScale = true
        bg.image:SetTintColor(color.new(20, 30, 45, 1, 255))
        bg.image:SetOpacity(0.85)
        bg.pos:Reparent(planPanel, -1)

        local border = ink.image(panelW/2, panelH/2, panelW - 4, panelH - 4, "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas", "cell_fg")
        border.image.useNineSliceScale = true
        border.image:SetTintColor(panelBorder)
        border.pos:Reparent(planPanel, -1)

        local headerLabel = ink.text("YOUR PLAN", panelW/2, 50, 52, cyanAccent)
        headerLabel:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        headerLabel:Reparent(planPanel, -1)

        local headerLine = ink.line(50, 90, panelW - 50, 90, cyanAccent, 2)
        headerLine:SetOpacity(0.4)
        headerLine:Reparent(planPanel, -1)

        self.currentPlan = ink.text("UNINSURED", panelW/2, 180, 64, color.red)
        self.currentPlan:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        self.currentPlan:Reparent(planPanel, -1)

        local divider1 = ink.line(50, 240, panelW - 50, 240, mediumText, 2)
        divider1:SetOpacity(0.3)
        divider1:Reparent(planPanel, -1)

        self.currentCoverage = ink.text("Coverage: 0%", panelW/2, 300, 48, lightText)
        self.currentCoverage:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        self.currentCoverage:Reparent(planPanel, -1)

        local divider2 = ink.line(50, 360, panelW - 50, 360, mediumText, 2)
        divider2:SetOpacity(0.3)
        divider2:Reparent(planPanel, -1)

        self.currentMax = ink.text("Max Payout: 0 E$", panelW/2, 420, 48, lightText)
        self.currentMax:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        self.currentMax:Reparent(planPanel, -1)

        local divider3 = ink.line(50, 480, panelW - 50, 480, mediumText, 2)
        divider3:SetOpacity(0.3)
        divider3:Reparent(planPanel, -1)

        self.nextPayment = ink.text("No active insurance", panelW/2, 540, 44, color.yellow)
        self.nextPayment:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
        self.nextPayment:Reparent(planPanel, -1)

        self.cancelButton = require("modules/ui/widgets/button_texture"):new()
        self.cancelButton.x = panelW/2
        self.cancelButton.y = 630
        self.cancelButton.sizeX = 320
        self.cancelButton.sizeY = 80
        self.cancelButton.textSize = 44
        self.cancelButton.text = "CANCEL PLAN"
        self.cancelButton.bgPart = "cell_bg"
        self.cancelButton.fgPart = "cell_fg"
        self.cancelButton.bgColor = color.new(80, 30, 30, 1, 255)
        self.cancelButton.fgColor = color.new(150, 50, 50, 1, 255)
        self.cancelButton.textColor = color.white
        self.cancelButton.useNineSlice = true

        self.cancelButton.callback = function()
                self:cancelPlan()
        end

        self.cancelButton:initialize()
        self.cancelButton:registerCallbacks(self.eventCatcher)
        self.cancelButton.canvas:Reparent(planPanel, -1)
        self.cancelButton.canvas:SetVisible(false)
end

function insurance:setupHelpButton()
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

function insurance:setupHelpOverlay()
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

        local helpTitle = ink.text("INSURANCE & SECURITY GUIDE", panelW / 2, 50, 64, color.cyan)
        helpTitle:SetAnchorPoint(0.5, 0.5)
        helpTitle:Reparent(self.helpCanvas, -1)

        local subtitle = ink.text("Protecting Your Digital Assets in Night City", panelW / 2, 100, 36, color.new(200, 220, 240, 1, 255))
        subtitle:SetAnchorPoint(0.5, 0.5)
        subtitle:Reparent(self.helpCanvas, -1)

        local col1X = 100
        local col2X = 950
        local col3X = 1800

        local sec1Title = ink.text("SECURITY SCORE", col1X, 180, 48, cyanAccent)
        sec1Title:Reparent(self.helpCanvas, -1)

        local sec1Line1 = ink.text("Score 0-100 measures your", col1X, 240, 38, lightText)
        sec1Line1:Reparent(self.helpCanvas, -1)

        local sec1Line2 = ink.text("account protection level.", col1X, 290, 38, lightText)
        sec1Line2:Reparent(self.helpCanvas, -1)

        local sec1Line3 = ink.text("80-100: EXCELLENT", col1X, 360, 40, color.lime)
        sec1Line3:Reparent(self.helpCanvas, -1)

        local sec1Line4 = ink.text("60-79: GOOD", col1X, 410, 40, cyanAccent)
        sec1Line4:Reparent(self.helpCanvas, -1)

        local sec1Line5 = ink.text("40-59: MODERATE", col1X, 460, 40, color.yellow)
        sec1Line5:Reparent(self.helpCanvas, -1)

        local sec1Line6 = ink.text("20-39: HIGH RISK", col1X, 510, 40, color.orange)
        sec1Line6:Reparent(self.helpCanvas, -1)

        local sec1Line7 = ink.text("0-19: CRITICAL", col1X, 560, 40, color.red)
        sec1Line7:Reparent(self.helpCanvas, -1)

        local sec2Title = ink.text("INSURANCE TIERS", col2X, 180, 48, cyanAccent)
        sec2Title:Reparent(self.helpCanvas, -1)

        local sec2Line1 = ink.text("Protects against hacking losses.", col2X, 240, 38, lightText)
        sec2Line1:Reparent(self.helpCanvas, -1)

        local sec2Line2 = ink.text("Premiums charged monthly.", col2X, 290, 38, lightText)
        sec2Line2:Reparent(self.helpCanvas, -1)

        local sec2Line3 = ink.text("BASIC: 25% cover, 100K max", col2X, 360, 40, mediumText)
        sec2Line3:Reparent(self.helpCanvas, -1)

        local sec2Line4 = ink.text("STANDARD: 40% cover, 500K max", col2X, 410, 40, mediumText)
        sec2Line4:Reparent(self.helpCanvas, -1)

        local sec2Line5 = ink.text("PREMIUM: 50% cover, 2M max", col2X, 460, 40, mediumText)
        sec2Line5:Reparent(self.helpCanvas, -1)

        local sec2Line6 = ink.text("PLATINUM: 75% cover, 10M max", col2X, 510, 40, mediumText)
        sec2Line6:Reparent(self.helpCanvas, -1)

        local sec2Line7 = ink.text("Higher tier = better protection!", col2X, 570, 42, color.lime)
        sec2Line7:Reparent(self.helpCanvas, -1)

        local sec3Title = ink.text("CLAIMS & PAYOUTS", col3X, 180, 48, cyanAccent)
        sec3Title:Reparent(self.helpCanvas, -1)

        local sec3Line1 = ink.text("When your account is compromised:", col3X, 240, 38, lightText)
        sec3Line1:Reparent(self.helpCanvas, -1)

        local sec3Line2 = ink.text("1. Losses calculated automatically", col3X, 310, 40, mediumText)
        sec3Line2:Reparent(self.helpCanvas, -1)

        local sec3Line3 = ink.text("2. Coverage percentage applied", col3X, 360, 40, mediumText)
        sec3Line3:Reparent(self.helpCanvas, -1)

        local sec3Line4 = ink.text("3. Payout capped at tier maximum", col3X, 410, 40, mediumText)
        sec3Line4:Reparent(self.helpCanvas, -1)

        local sec3Line5 = ink.text("4. Funds deposited to account", col3X, 460, 40, mediumText)
        sec3Line5:Reparent(self.helpCanvas, -1)

        local sec3Line6 = ink.text("Low scores = more hacking!", col3X, 530, 42, color.yellow)
        sec3Line6:Reparent(self.helpCanvas, -1)

        local divider1 = ink.rect(80, 630, panelW - 160, 2, mediumText)
        divider1:Reparent(self.helpCanvas, -1)

        local tipLabel = ink.text("PRO TIP:", 100, 700, 48, color.new(255, 215, 0, 1, 255))
        tipLabel:Reparent(self.helpCanvas, -1)

        local tipText = ink.text("Log out properly and avoid suspicious terminals to maintain a high security score!", 320, 700, 42, lightText)
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

function insurance:toggleHelp()
        self.helpVisible = not self.helpVisible
        if self.helpVisible then
                self.helpCanvas:Reparent(self.canvas, -1)
        end
        self.helpCanvas:SetVisible(self.helpVisible)
end

function insurance:refreshTierLabels()
        if not self.tierLabels then return end

        local function formatNumber(num)
                if num >= 1000000 then
                        return tostring(math.floor(num / 1000000)) .. "M"
                elseif num >= 1000 then
                        return tostring(math.floor(num / 1000)) .. "K"
                else
                        return tostring(num)
                end
        end

        local tierConfigs = {}
        pcall(function()
                if self.securityManager and self.securityManager.settings and 
                   self.securityManager.settings.insurance and 
                   self.securityManager.settings.insurance.cpicInsurance and
                   self.securityManager.settings.insurance.cpicInsurance.tiers then
                        tierConfigs = self.securityManager.settings.insurance.cpicInsurance.tiers
                end
        end)

        local tierList = {"basic", "standard", "premium", "platinum"}
        for _, tierName in ipairs(tierList) do
                local data = tierConfigs[tierName]
                local labels = self.tierLabels[tierName]
                if data and labels then
                        labels.premiumLabel:SetText(formatNumber(data.monthlyPremium) .. "/month")
                        labels.coverageText:SetText(tostring(math.floor(data.coveragePercent * 100)) .. "%")
                        labels.maxText:SetText(formatNumber(data.maxPayout))
                end
        end
end

function insurance:showData()
        if not self.securityManager then return end

        self:refreshTierLabels()

        local success, report = pcall(function()
                return self.securityManager:getSecurityReport()
        end)

        if not success or not report then
                report = { score = 50, tier = "none", pendingThreats = 0 }
        end

        self.scoreDisplay:SetText(tostring(report.score or 50))

        local scoreColor = color.red
        local statusText = "CRITICAL"
        if report.score >= 80 then
                scoreColor = color.lime
                statusText = "EXCELLENT"
        elseif report.score >= 60 then
                scoreColor = cyanAccent
                statusText = "GOOD"
        elseif report.score >= 40 then
                scoreColor = color.yellow
                statusText = "MODERATE"
        elseif report.score >= 20 then
                scoreColor = color.orange
                statusText = "HIGH RISK"
        end

        self.scoreDisplay:SetTintColor(scoreColor)
        self.scoreStatus:SetText(statusText)
        self.scoreStatus:SetTintColor(scoreColor)

        local tierSuccess, tierData = pcall(function()
                return self.securityManager:getInsuranceData()
        end)

        if tierSuccess and tierData then
                self.currentPlan:SetText(tierData.name)
                self.currentPlan:SetTintColor(color.lime)
                self.currentCoverage:SetText("Coverage: " .. tostring(tierData.coveragePercent * 100) .. "%")
                self.currentMax:SetText("Max Payout: " .. tostring(tierData.maxPayout) .. " E$")
                self.nextPayment:SetText("Premium: " .. tostring(tierData.monthlyPremium) .. " E$/month")
                self.cancelButton.canvas:SetVisible(true)
        else
                self.currentPlan:SetText("UNINSURED")
                self.currentPlan:SetTintColor(color.red)
                self.currentCoverage:SetText("Coverage: 0%")
                self.currentMax:SetText("Max Payout: 0 E$")
                self.nextPayment:SetText("No active insurance")
                self.cancelButton.canvas:SetVisible(false)
        end

        local pendingThreats = report.pendingThreats or 0
        if pendingThreats > 0 then
                self.securityTips:SetText("WARNING: " .. pendingThreats .. " threat(s)!")
                self.securityTips:SetTintColor(color.red)
        else
                self.securityTips:SetText("Tip: Logout properly to improve score")
                self.securityTips:SetTintColor(lightText)
        end
end

function insurance:purchaseTier(tier)
        self:showConfirmPopup(tier)
end

function insurance:cancelPlan()
        local success, message = self.securityManager:cancelInsurance()
        if success then
                self:showData()
        end
end

function insurance:refresh()
        self:showData()
end

function insurance:uninitialize()
        Cron.Halt(self.refreshCron)

        if not self.canvas then return end
        self.tierButtons = {}
        self.inkPage:RemoveChild(self.canvas)
        self.inkPage:RemoveChild(self.buttons)
        self.canvas = nil
end

return insurance
