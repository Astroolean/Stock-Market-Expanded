-- Legacy button

local ink = require("modules/ui/inkHelper")
local Cron = require("modules/external/Cron")
local utils = require("modules/utils/utils")

button = {}

function button:new(x, y, sizeX, sizeY, borderSize, text, textSize, bgColor, fillColor, textColor, callback)
        local o = {}

    o.x = x
    o.y = y
    o.sizeX = sizeX
    o.sizeY = sizeY
    o.borderSize = borderSize
    o.text = text
    o.textSize = textSize
    o.bgColor = bgColor
    o.fillColor = fillColor
    o.textColor = textColor

    o.callback = callback
    o.eventCatcher = nil
    o.cooldown = false

    o.bg = nil
    o.fill = nil
    o.textWidget = nil
    o.canvas = nil

        self.__index = self
        return setmetatable(o, self)
end

function button:initialize()
    self.canvas = ink.canvas(self.x, self.y, inkEAnchor.Centered)
    self.canvas:SetInteractive(true)

    self.bg = ink.rect(0, 0, self.sizeX, self.sizeY, self.bgColor, 0, Vector2.new({X = 0.5, Y = 0.5}))
    self.bg:Reparent(self.canvas, -1)

    self.fill = ink.rect(0, 0, self.sizeX - self.borderSize * 2, self.sizeY - self.borderSize * 2, self.fillColor, 0, Vector2.new({X = 0.5, Y = 0.5}))
    self.fill:Reparent(self.canvas, -1)
    self.fill:SetInteractive(true)

    self.textWidget = ink.text(self.text, 0, 0, self.textSize, self.textColor)
    self.textWidget:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
    self.textWidget:Reparent(self.canvas, -1)
end

function button:registerCallbacks(catcher)
    self.eventCatcher = sampleStyleManagerGameController.new()

        self.fill:RegisterToCallback('OnPress', self.eventCatcher, 'OnState1')
        self.fill:RegisterToCallback('OnEnter', self.eventCatcher, 'OnStyle1')
        self.fill:RegisterToCallback('OnLeave', self.eventCatcher, 'OnStyle2')

    table.insert(catcher.subscribers, self)
end

function button:hoverInCallback()
    self.fill:SetOpacity(0.6)
end

function button:hoverOutCallback()
    self.fill:SetOpacity(1)
end

function button:clickCallback()
    if not self.callback or self.cooldown then return end
    self.cooldown = true
    Cron.NextTick(function()
        self.cooldown = false
    end)
    utils.playSound("ui_menu_onpress", 1)
    self.callback()
end

return button