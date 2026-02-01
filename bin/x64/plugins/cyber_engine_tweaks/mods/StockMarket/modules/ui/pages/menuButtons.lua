local color = require("modules/ui/color")
local lang = require("modules/utils/lang")
local ink = require("modules/ui/inkHelper")

local buttons = {}

function buttons.createMenu(page)
    local canvas = ink.canvas(0, -80, inkEAnchor.TopCenter)
        canvas:Reparent(page.inkPage, -1)

    -- Logo
    local logo = ink.image(-1440, 175, 233, 233, "base\\icon\\stock_logo.inkatlas", "stock")
    logo.image:SetTintColor(HDRColor.new({ Red = 0.9, Green = 0.9, Blue = 0.9, Alpha = 1.0 }))
    logo.pos:Reparent(canvas, -1)

    -- Mod Title (positioned next to logo, left-aligned to avoid overlap with menu)
    local cyanAccent = HDRColor.new({ Red = 0.368627, Green = 0.964706, Blue = 1.0, Alpha = 1.0 })
    local lightText = color.new(220, 235, 250, 1, 255)
    
    local titleText = ink.text("Stock Market Expanded", -1290, 140, 44, cyanAccent)
    titleText:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
    titleText:Reparent(canvas, -1)
    
    local subtitleText = ink.text("by Astroolean", -1290, 185, 38, lightText)
    subtitleText:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
    subtitleText:Reparent(canvas, -1)
    
    local versionText = ink.text("v3.0.0", -1290, 225, 34, cyanAccent)
    versionText:SetAnchorPoint(Vector2.new({X = 0, Y = 0.5}))
    versionText:Reparent(canvas, -1)

    -- Uniform button sizing and spacing
    local buttonWidth = 280
    local buttonHeight = 150
    local buttonSpacing = 300
    local startX = -600
    local buttonY = 170

    -- Home button
        local home = buttons.createMenuButton(lang.getText(lang.button_home), startX, buttonY, buttonWidth, buttonHeight, page.eventCatcher)
    if page.pageName ~= "home" then
        home.callback = function()
            page.controller:switchToPage("home")
        end
    else
        home.fg.image:SetOpacity(1)
    end
    home.canvas:Reparent(canvas, -1)

    -- Stocks button
        local stocks = buttons.createMenuButton(lang.getText(lang.button_stocks), startX + buttonSpacing, buttonY, buttonWidth, buttonHeight, page.eventCatcher)
    if page.pageName ~= "stocks" then
        stocks.callback = function()
            page.controller:switchToPage("stocks")
        end
    else
        stocks.fg.image:SetOpacity(1)
    end
    stocks.canvas:Reparent(canvas, -1)

    -- News button
        local news = buttons.createMenuButton(lang.getText(lang.button_news), startX + buttonSpacing * 2, buttonY, buttonWidth, buttonHeight, page.eventCatcher)
    if page.pageName ~= "news" then
        news.callback = function()
            page.controller:switchToPage("news")
        end
    else
        news.fg.image:SetOpacity(1)
    end
    news.canvas:Reparent(canvas, -1)

    -- Portfolio button
        local portfolio = buttons.createMenuButton(lang.getText(lang.button_portfolio), startX + buttonSpacing * 3, buttonY, buttonWidth, buttonHeight, page.eventCatcher)
    if page.pageName ~= "portfolio" then
        portfolio.callback = function()
            page.controller:switchToPage("portfolio")
        end
    else
        portfolio.fg.image:SetOpacity(1)
    end
    portfolio.canvas:Reparent(canvas, -1)

    -- Insurance button
        local insurance = buttons.createMenuButton(lang.getText(lang.button_insurance), startX + buttonSpacing * 4, buttonY, buttonWidth, buttonHeight, page.eventCatcher)
    if page.pageName ~= "insurance" then
        insurance.callback = function()
            page.controller:switchToPage("insurance")
        end
    else
        insurance.fg.image:SetOpacity(1)
    end
    insurance.canvas:Reparent(canvas, -1)

    -- Logout button (separated to the right)
        local logout = buttons.createMenuButton(lang.getText(lang.button_logout), 1375, buttonY, buttonWidth, buttonHeight, page.eventCatcher)
    logout.callback = function()
        page.controller:switchToPage("login")
    end
    logout.fg.image:SetTexturePart("cell_fg")
    logout.fg.image:SetOpacity(0.25)
    logout.canvas:Reparent(canvas, -1)

    -- Horizontal divider
        local divider = ink.rect(1, 270, 3137, 5, HDRColor.new({ Red = 0.368627, Green = 0.964706, Blue = 1.0, Alpha = 1.0 }))
        divider:SetAnchorPoint(0.5, 0.5)
        divider:Reparent(canvas)

    return canvas
end

function buttons.createMenuButton(text, x, y, sizeX, sizeY, catcher)
        local button = require("modules/ui/widgets/button_texture"):new()
        button.x = x
        button.y = y
        button.sizeX = sizeX
        button.sizeY = sizeY
        button.textSize = 50
        button.text = text
        button.bgPart = ""
        button.fgPart = "tooltip_b_bracket_decent_fg_thick"
    button.bgColor = HDRColor.new({ Red = 1, Green = 1, Blue = 1, Alpha = 1.0 })
    button.fgColor = HDRColor.new({ Red = 0.368627, Green = 0.964706, Blue = 1.0, Alpha = 1.0 })
        button.textColor = color.white
    button.useNineSlice = true
    button.nineSliceScale = inkMargin.new({ left = 5.0, top = 0.0, right = 5.0, bottom = 0.0 })

    button.hoverInCallback = function (bt)
        bt.textWidget:SetTintColor(HDRColor.new({ Red = bt.textColor.Red * 1.7, Green = bt.textColor.Green * 1.7, Blue = bt.textColor.Blue * 1.7, Alpha = 1.0 }))
    end

    button.hoverOutCallback = function (bt)
        bt.textWidget:SetTintColor(bt.textColor)
    end

        button:initialize()
    button.fg.image:SetOpacity(0)
        button:registerCallbacks(catcher)

        return button
end

return buttons
