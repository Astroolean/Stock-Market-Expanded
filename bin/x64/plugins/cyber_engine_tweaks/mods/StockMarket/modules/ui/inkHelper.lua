ink = {}

---@param text string
---@param size number
---@param x number
---@param y number
---@param color HDRColor
---@param letterCase textLetterCase
---@param fontStlye string
---@param rotation number
---@return inkText
function ink.text(text, x, y, size, color, letterCase, fontStyle, rotation) -- Create a text
    local c = color or HDRColor.new({ Red = 1, Green = 1, Blue = 1, Alpha = 1.0 })
    local case = letterCase or textLetterCase.OriginalCase
    local style = fontStyle or "Medium"
    local r = rotation or 0

    local widget = inkText.new()
    widget:SetName(tostring(text))
    widget:SetFontFamily('base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily')
    widget:SetFontStyle(style)
    widget:SetFontSize(size)
    widget:SetLetterCase(case)
    widget:SetTintColor(c)
    widget:SetAnchor(inkEAnchor.TopLeft)
    widget:SetMargin(inkMargin.new({ left = x, top = y, right = 0.0, bottom = 0.0 }))
    widget:SetText(text)
    widget:SetVisible(true)
    widget:SetRotation(r)

    return widget
end

---@param x number
---@param y number
---@param anchor inkEAnchor
---@return inkCanvas
function ink.canvas(x, y, anchor) -- Create a basic canvas
    local a = anchor or inkEAnchor.TopLeft

    local area = inkCanvas.new()
    area:SetMargin(inkMargin.new({ left = x, top = y, right = 0.0, bottom = 0.0 }))
	area:SetAnchor(a)

    return area
end

---@param sizeX number
---@param sizeY number
---@param posX number
---@param posY number
---@param color HDRColor
---@param rot number
---@param anchorPoint Vector2
---@return inkRectangle
function ink.rect(posX, posY, sizeX, sizeY, color, rot, anchorPoint) -- Create a rectangle
    local r = rot or 0
    local c = color or HDRColor.new({ Red = 1, Green = 1, Blue = 1, Alpha = 1.0 })
    local a = anchorPoint or Vector2.new({X = 0, Y = 0})

    local rect = inkRectangle.new()
	rect:SetName(tostring('rect' .. math.random(0, 100000000000000000)))

	rect:SetSize(sizeX, sizeY)
	rect:SetRotation(r)
	rect:SetMargin(inkMargin.new({ left = posX, top = posY, right = 0.0, bottom = 0.0 }))
	rect:SetTintColor(c)
	rect:SetAnchor(inkEAnchor.TopLeft)
    rect:SetAnchorPoint(a)

	return rect
end

---@param posX number
---@param posY number
---@param size number
---@param color HDRColor
---@return inkCircle
function ink.circle(posX, posY, size, color) -- Create a circle
    local s = size or 10
    local c = color or HDRColor.new({ Red = 1, Green = 1, Blue = 1, Alpha = 1.0 })

    local circle = inkCircle.new()
	circle:SetName(tostring('circle' .. math.random(0, 100000000000000000)))
	circle:SetSize(s, s)
	circle:SetMargin(inkMargin.new({ left = posX, top = posY, right = 0.0, bottom = 0.0 }))
	circle:SetTintColor(c)
	circle:SetOpacity(1)
	circle:SetAnchor(inkEAnchor.TopLeft)
	circle:SetAnchorPoint(Vector2.new({ X = 0.5, Y = 0.5}))

	return circle
end

---@param startPosX number
---@param startPosY number
---@param endPosX number
---@param endPosY number
---@param color HDRColor
---@param size number
---@return inkRectangle
function ink.line(startPosX, startPosY, endPosX, endPosY, color, size) -- Create a line
    local s = size or 3
    local c = color or HDRColor.new({ Red = 1, Green = 1, Blue = 1, Alpha = 1.0 })
    local p0 = {x = startPosX, y = startPosY}
    local p1 = {x = endPosX, y = endPosY}

    local subVector = Game['OperatorSubtract;Vector4Vector4;Vector4']

    local rect = inkRectangle.new()
	rect:SetName(tostring('rect' .. math.random(0, 100000000000000000)))

	local dir = subVector(Vector4.new(p1.x, p1.y, 0, 0), Vector4.new(p0.x, p0.y, 0, 0))
    local rot = dir:ToRotation()
	local y = ink.distance(p0, p1)

	local posX = p0.x + dir.x / 2
	local posY = p0.y + dir.y / 2

	rect:SetSize(s, y)
	rect:SetRotation(rot.yaw)
	rect:SetMargin(inkMargin.new({ left = posX, top = posY, right = 0.0, bottom = 0.0 }))
	rect:SetTintColor(c)
	rect:SetOpacity(1)
	rect:SetAnchor(inkEAnchor.TopLeft)
	rect:SetAnchorPoint(Vector2.new({ X = 0.5, Y = 0.5}))

	return rect
end

---@param rectWidget inkRectangle
---@param startPosX number
---@param startPosY number
---@param endPosX number
---@param endPosY number
function ink.updateLine(rectWidget, startPosX, startPosY, endPosX, endPosY) -- Update a "line", by recalculating its position and rotation
    local subVector = Game['OperatorSubtract;Vector4Vector4;Vector4']
    local p0 = {x = startPosX, y = startPosY}
    local p1 = {x = endPosX, y = endPosY}

    local dir = subVector(Vector4.new(p1.x, p1.y, 0, 0), Vector4.new(p0.x, p0.y, 0, 0))
    local rot = dir:ToRotation()
    local y = ink.distance(p0, p1)

    local posX = p0.x + dir.x / 2
    local posY = p0.y + dir.y / 2

    rectWidget:SetSize(rectWidget:GetSize().X, y)
    rectWidget:SetRotation(rot.yaw)
    rectWidget:SetMargin(inkMargin.new({ left = posX, top = posY, right = 0.0, bottom = 0.0 }))
end

---@param x number
---@param y number
---@param sizeX number
---@param sizeY number
---@param path String
---@param part String
---@param rot number
---@param mirror inkBrushMirrorType
---@return {pos: inkCanvas, image: inkImage}
function ink.image(x, y, sizeX, sizeY, path, part, rot, color, mirror) -- Create a table with a position controlling canvas, and the image part itself parented to that
    local r = rot or 0
    local m = mirror or inkBrushMirrorType.NoMirror
    local c = color or HDRColor.new({ Red = 1, Green = 1, Blue = 1, Alpha = 1.0 })

    local t = {pos = nil, image = nil}
    t.pos= ink.canvas(x, y)
    t.pos:SetSize(sizeX, sizeY)
    t.pos:SetAnchorPoint(Vector2.new({ X = 0.5, Y = 0.5 }))

	t.image = inkImage.new()
	t.image:SetAtlasResource(ResRef.FromName(path))
	t.image:SetTexturePart(part)
	t.image:SetOpacity(1)
	t.image:SetAnchor(inkEAnchor.Fill)
	t.image:SetRotation(r)
	t.image:SetBrushMirrorType(m)
    t.image:SetTintColor(c)
    t.image:Reparent(t.pos, -1)

	return t
end

---@param p1 table
---@param p2 table
---@return number
function ink.distance(p1, p2) -- Returns distance between two points {x, y}
	local dx = p1.x - p2.x
    local dy = p1.y - p2.y
    return math.sqrt(math.pow(dx, 2) + math.pow(dy, 2))
end

return ink