local utils = require("modules/utils/utils")
local config = require("modules/utils/config")

editUI = {
    currentStock = nil,
    currentStockSelect = 0,
    currentTriggerSelect = 0
}

function editUI.draw(debug, mod)
    debug.questUI.stocks = {}

    if editUI.currentStock ~= nil then
        local stock = editUI.currentStock
        local name = stock.name

        stock.name, changed =  ImGui.InputTextWithHint("Stock Name", "Name...", stock.name, 100)
        if changed then
            os.rename("data/static/stocks/" .. name .. ".json", "data/static/stocks/" .. stock.name .. ".json")
        end

        stock.atlasPath =  ImGui.InputTextWithHint("Atlas Path", "Path...", stock.atlasPath, 100)
        stock.atlasPart =  ImGui.InputTextWithHint("Atlas Part", "Part...", stock.atlasPart, 100)
        stock.iconX = ImGui.InputInt("IconX Size", stock.iconX)
        stock.iconY = ImGui.InputInt("IconY Size", stock.iconY)

        if ImGui.Button("AutoFit (TM)") then
            local maxY = 140
            local maxX = 415

            local xFitY = math.floor(stock.iconX * (maxY / stock.iconY))

            if xFitY > maxX then
                stock.iconY = math.floor(stock.iconY * (maxX / stock.iconX))
                stock.iconX = maxX
            else
                stock.iconX = xFitY
                stock.iconY = maxY
            end
        end

        ImGui.Separator()

        stock.sharesAmount = ImGui.InputInt("Shares Amount", stock.sharesAmount)
        stock.min = ImGui.InputInt("Share Min Price", stock.min)
        stock.max = ImGui.InputInt("Share Max Price", stock.max)
        stock.smoothOff = ImGui.InputInt("Share MinMax Delta Power", stock.smoothOff)
        stock.maxStepSize = ImGui.InputFloat("Share Max Step", stock.maxStepSize)

        ImGui.Separator()

        local state = ImGui.CollapsingHeader("Stock influences")
        if state then
            local stockList = {"--Select stock--"}
            for _, stock in pairs(mod.market.stocks) do
                table.insert(stockList, stock.name)
            end

            if ImGui.Button("Add") and editUI.currentStockSelect ~= 0 then
                table.insert(stock.stockInfluence, {
                    name = stockList[editUI.currentStockSelect + 1],
                    amount = 0.5
                })
            end

            ImGui.SameLine()
            editUI.currentStockSelect = ImGui.Combo("Stock to influence", editUI.currentStockSelect, stockList, #stockList)

            for _, inf in pairs(stock.stockInfluence) do
                ImGui.PushID(inf.name)
                ImGui.Separator()
                ImGui.Text("Influence to stock: " .. inf.name)
                inf.amount = ImGui.InputFloat("Influence amount", inf.amount)
                if ImGui.Button("Remove") then
                    utils.removeItem(stock.stockInfluence, inf)
                end
                ImGui.Separator()
                ImGui.PopID()
            end

            ImGui.Separator()
        end

        local state = ImGui.CollapsingHeader("Triggers")
        if state then
            local triggerList = {"--Select trigger--"}
            for _, trigger in pairs(mod.market.triggerManager.triggers) do
                if mod.market.stocks[trigger.name] == nil and not string.match(trigger.name, "quest") then
                    table.insert(triggerList, trigger.name)
                end
            end
            table.sort(triggerList, function (a, b)
                return a < b
            end)

            if ImGui.Button("Add") and editUI.currentTriggerSelect ~= 0 then
                table.insert(stock.triggers, {name = triggerList[editUI.currentTriggerSelect + 1], amount = 1})
            end

            ImGui.SameLine()
            editUI.currentTriggerSelect = ImGui.Combo("Trigger", editUI.currentTriggerSelect, triggerList, #triggerList)

            for _, trigger in pairs(stock.triggers) do
                ImGui.PushID(trigger.name)
                ImGui.Separator()
                ImGui.Text("Trigger name: " .. trigger.name)
                trigger.amount = ImGui.InputFloat("Amount", trigger.amount)
                if ImGui.Button("Remove") then
                    utils.removeItem(stock.triggers, trigger)
                end
                ImGui.Separator()
                ImGui.PopID()
            end
        end
    end
end

return editUI