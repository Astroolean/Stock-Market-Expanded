-- Button with image background

local ink = require("modules/ui/inkHelper")
local Cron = require("modules/external/Cron")
local utils = require("modules/utils/utils")

button = {}

function button:new(x, y, sizeX, sizeY, text, textSize, textColor, bgPart, fgPart, bgColor, fgColor, callback)
        local o = {}

    o.x = x
    o.y = y
    o.sizeX = sizeX
    o.sizeY = sizeY
    o.text = text
    o.textSize = textSize
    o.textColor = textColor
    o.bgPart = bgPart
    o.fgPart = fgPart
    o.bgColor = bgColor
    o.fgColor = fgColor
    o.useNineSlice = false
    o.nineSliceScale = inkMargin.new({ left = 0.0, top = 0.0, right = 0.0, bottom = 0.0 })

    o.callback = callback
    o.eventCatcher = nil
    o.cooldown = false

    o.bg = nil
    o.fg = nil
    o.textWidget = nil
    o.canvas = nil

        self.__index = self
        return setmetatable(o, self)
end

function button:initialize()
    local atlas = "base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas"

    self.canvas = ink.canvas(self.x, self.y, inkEAnchor.Centered)
    self.canvas:SetSize(Vector2.new({X = self.sizeX, Y = self.sizeY}))
    self.canvas:SetInteractive(true)

    self.fg = ink.image(0, 0, self.sizeX, self.sizeY, atlas, self.fgPart)
    self.fg.pos:SetInteractive(true)
    self.fg.image:SetTintColor(self.fgColor)
    self.fg.image.useNineSliceScale = self.useNineSlice
    self.fg.image.nineSliceScale = self.nineSliceScale
    self.fg.pos:Reparent(self.canvas, -1)

    self.bg = ink.image(0, 0, self.sizeX, self.sizeY, atlas, self.bgPart)
    self.bg.pos:SetInteractive(true)
    self.bg.image:SetTintColor(self.bgColor)
    self.bg.image.useNineSliceScale = self.useNineSlice
    self.bg.image.nineSliceScale = self.nineSliceScale
    self.bg.image:SetOpacity(0)
    self.bg.pos:Reparent(self.canvas, -1)

    self.textWidget = ink.text(self.text, 0, 0, self.textSize, self.textColor)
    self.textWidget:SetAnchorPoint(Vector2.new({X = 0.5, Y = 0.5}))
    self.textWidget:Reparent(self.canvas, -1)
end

function button:registerCallbacks(catcher)
    self.eventCatcher = sampleStyleManagerGameController.new()

        self.bg.pos:RegisterToCallback('OnPress', self.eventCatcher, 'OnState1')
        self.bg.pos:RegisterToCallback('OnEnter', self.eventCatcher, 'OnStyle1')
        self.bg.pos:RegisterToCallback('OnLeave', self.eventCatcher, 'OnStyle2')

    table.insert(catcher.subscribers, self)
end

function button:hoverInCallback()
    self.bg.image:SetOpacity(0.05)
end

function button:hoverOutCallback()
    self.bg.image:SetOpacity(0)
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