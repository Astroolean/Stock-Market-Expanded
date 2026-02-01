local ink = require("modules/ui/inkHelper")
local color = require("modules/ui/color")
local utils = require("modules/utils/utils")

graph = {}

function graph:new(x, y, sizeX, sizeY, stepsX, stepsY, labelX, labelY, gridThicc, labelSize, bgColor, bgAlpha)
        local o = {}

    o.x = x
    o.y = y
    o.sizeX = sizeX
    o.sizeY = sizeY

    o.stepsX = stepsX
    o.stepsY = stepsY
    o.labelX = labelX
    o.labelY = labelY
    o.gridThicc = gridThicc
    o.labelSize = labelSize

    o.data = {}

    o.useTimeScale = true
    o.intervall = 30

    o.bgColor = bgColor
    o.bgAlpha = bgAlpha
    
    o.showXAxisLabels = false
    o.showYAxisLabels = true

    o.gridLines = {
        ["x"] = {},
        ["y"] = {}
    }
    o.graphLines = {}
    o.labels = {}

    o.relativeScaling = false

        self.__index = self
        return setmetatable(o, self)
end

function graph:initialize(screen)
    self.canvas = ink.canvas(self.x, self.y, inkEAnchor.TopLeft)

    self.bg = ink.rect(0, 0, self.sizeX, self.sizeY, self.bgColor)
    self.bg:SetOpacity(self.bgAlpha)
    self.bg:Reparent(self.canvas, -1)

    self:initGrid()
    self:showLegends()

    self.canvas:Reparent(screen, -1)
end

function graph:getMinMaxY()
    local maxY = math.max(unpack(self.data))
    local minY = math.min(unpack(self.data))

    if self.relativeScaling then
        minY = math.max(self.data[#self.data] - self.data[#self.data] * 0.1, minY)
        maxY = math.min(self.data[#self.data] + self.data[#self.data] * 0.1, maxY)
    end

    return minY, maxY
end

function graph:getMarginSettings()
    local topRightMargin = 0.035
    local leftMargin = 0.05
    local bottomMargin = 0.05

    local topPosition = self.sizeY * topRightMargin
    local leftPosition = self.sizeX * leftMargin
    local xSize = self.sizeX - leftPosition - topPosition
    local ySize = self.sizeY - topPosition - (self.sizeY * bottomMargin)

    return topPosition, leftPosition, xSize, ySize
end

function graph:initGrid()
    local gridColor = color.new(0.7, 0.7, 0.7)
    local topPosition, leftPosition, xSize, ySize = self:getMarginSettings()

    self.grid = ink.canvas(0, 0, inkEAnchor.TopLeft)
    self.grid:Reparent(self.canvas, -1)

    for i = 0, self.stepsX do
        local line = ink.rect((i * (xSize / self.stepsX)) + leftPosition, topPosition, self.gridThicc, ySize, gridColor, 0)
        line:Reparent(self.grid, -1)
        self.gridLines["x"][i] = line
    end

    for i = 0, self.stepsY do
        local line = ink.rect(leftPosition, (i * (ySize / self.stepsY)) + topPosition, xSize, self.gridThicc, gridColor, 0)
        line:Reparent(self.grid, -1)
        self.gridLines["y"][i] = line
    end
end

function graph:showData()
    self:setLabels()

    local topPosition, leftPosition, xSize, ySize = self:getMarginSettings()
    local minY, maxY = self:getMinMaxY()
    local points = {}

    for x, y in pairs(self.data) do -- Generate list of remaped positions
        local x = utils.remap(x, 1, #self.data, leftPosition, leftPosition + xSize)
        local y = utils.remap(y, minY, maxY, 0, ySize)
        y = math.max(math.min(y, ySize), 0)
        table.insert(points, {x = x, y = (topPosition + ySize) - y})
    end

    for _, line in pairs(self.graphLines) do
        self.grid:RemoveChild(line)
    end
    self.graphLines = {}

    for k, p in ipairs(points) do -- Draw lines
        if k == #points then return end

        local lineColor
        if p.y < points[k + 1].y then
            lineColor = color.red
        else
            lineColor = color.lime
        end

        local line = ink.line(p.x, p.y, points[k + 1].x, points[k + 1].y, lineColor, 5)
        line:Reparent(self.grid, -1)
        table.insert(self.graphLines, line)
    end
end

function graph:showLegends()
    local topPosition, leftPosition, xSize, ySize = self:getMarginSettings()

    local x_X = leftPosition + xSize / 2
    local x_Y = topPosition / 2

    local xLegend = ink.text(self.labelX, x_X, x_Y, math.floor(self.labelSize / 2), color.white)
    xLegend:SetAnchorPoint(0.5, 0.5)
    xLegend:Reparent(self.grid, -1)

    local y_X = leftPosition + xSize + topPosition / 2
    local y_Y = topPosition + ySize / 2

    local yLegend = ink.text(self.labelY, y_X, y_Y, math.floor(self.labelSize / 2), color.white, nil, nil, 90)
    yLegend:SetAnchorPoint(0.5, 0.5)
    yLegend:Reparent(self.grid, -1)
end

function graph:setLabels()
    local minY, maxY = self:getMinMaxY()

    for _, label in pairs(self.labels) do
        self.grid:RemoveChild(label)
    end
    self.labels = {}

    for i = 0, self.stepsY do
        local label = minY + (i * (maxY - minY) / self.stepsY)

        local x = self.gridLines["y"][self.stepsY - i]:GetMargin().left
        local y = self.gridLines["y"][self.stepsY - i]:GetMargin().top
        local labelTextSize = math.max(math.floor(self.labelSize * 0.7), 18)
        local text = ink.text(tostring(math.floor(label)), x - self.labelSize - 5, y, labelTextSize, color.white)
        text:SetAnchorPoint(0.5, 0.5)
        text:Reparent(self.grid, -1)
        table.insert(self.labels, text)
    end

    if not self.showXAxisLabels then return end
    
    for i = 0, self.stepsX do
        local label = math.floor(1 + (i * (#self.data - 1) / self.stepsX))
        local xAnchor = 0.5

        if self.useTimeScale then
            local minutesPerStep = (self.intervall / 7.5) * (#self.data / self.stepsX)
            local totalSub = minutesPerStep * (self.stepsX - i)
            local subMinutes = totalSub % 60
            local subHours = math.floor(totalSub / 60)

            local minutes = Game.GetTimeSystem():GetGameTime():Minutes() - subMinutes
            if minutes < 0 then minutes = 60 + minutes end
            local hours = Game.GetTimeSystem():GetGameTime():Hours() - subHours
            if hours < 0 then hours = 24 + hours end

            label = string.format("%02d", hours) .. ":" .. string.format("%02d", minutes)

            if i == 0 then -- Fix time label being off graph
                xAnchor = 0
            elseif i == self.stepsX then
                xAnchor = 1
            end
        end

        local x = self.gridLines["x"][i]:GetMargin().left
        local y = self.gridLines["x"][i]:GetMargin().top + self.gridLines["x"][i]:GetSize().Y
        local text = ink.text(tostring(label), x, y + self.labelSize / 1.75, self.labelSize - 5, color.white)
        text:SetAnchorPoint(xAnchor, 0.5)
        text:Reparent(self.grid, -1)
        table.insert(self.labels, text)
    end
end

return graph