miscUtils = {}

function miscUtils.deepcopy(origin)
        local orig_type = type(origin)
    local copy
    if orig_type == 'table' then
        copy = {}
        for origin_key, origin_value in next, origin, nil do
            copy[miscUtils.deepcopy(origin_key)] = miscUtils.deepcopy(origin_value)
        end
        setmetatable(copy, miscUtils.deepcopy(getmetatable(origin)))
    else
        copy = origin
    end
    return copy
end

function miscUtils.indexValue(table, value)
    local index={}
    for k,v in pairs(table) do
        index[v]=k
    end
    return index[value]
end

function miscUtils.has_value(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function miscUtils.getIndex(tab, val)
    local index = nil
    for i, v in ipairs(tab) do
                if v == val then
                        index = i
                end
    end
    return index
end

function miscUtils.removeItem(tab, val)
    table.remove(tab, miscUtils.getIndex(tab, val))
end

function miscUtils.split(s, delimiter) --https://www.codegrepper.com/code-examples/lua/lua+split+string+by+space
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function miscUtils.isSameInstance(a, b)
        return Game['OperatorEqual;IScriptableIScriptable;Bool'](a, b)
end

function miscUtils.remap(value, low1, high1, low2, high2) -- Made by github copilot
    return low2 + (value - low1) * (high2 - low2) / (high1 - low1)
end

function miscUtils.playSound(name, mult)
    local m = mult or 1

    for _ = 1, m do
        local audioEvent = SoundPlayEvent.new ()
        audioEvent.soundName = name
        GetPlayer():QueueEvent(audioEvent)
    end
end

function miscUtils.spendMoney(amount)
    local moneyId = gameItemID.FromTDBID(TweakDBID.new("Items.money"))
    Game.GetTransactionSystem():RemoveItem(GetPlayer(), moneyId, math.floor(amount + 0.5))
end

function miscUtils.round(num, precision)
    precision = precision or 1
    return tonumber(string.format(tostring("%." .. precision .. "f"), num))
end

function miscUtils.formatNumber(num)
    local formatted = tostring(math.floor(num))
    local result = ""
    local len = #formatted
    for i = 1, len do
        if i > 1 and (len - i + 1) % 3 == 0 then
            result = result .. ","
        end
        result = result .. formatted:sub(i, i)
    end
    return result
end

function miscUtils.wrap(text, chars)
    local str = ""
    local shouldBreak = false
    local n = 1
    for i = 1, #text do
        local c = text:sub(i,i)
        if n > chars then
            shouldBreak = true
        end
        if shouldBreak and i ~= 0 and text:sub(i - 1,i - 1) == " " then
            n = 0
            shouldBreak = false
            str = tostring(str .. "\n")
        end
        str = tostring(str .. c)
        n = n + 1
    end

    return str
end

return miscUtils