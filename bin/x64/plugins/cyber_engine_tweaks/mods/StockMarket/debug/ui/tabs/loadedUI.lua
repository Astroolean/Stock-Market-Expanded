loadedUI = {
    stocks = {}
}

function loadedUI.draw(debug)
    for k, stock in pairs(loadedUI.stocks) do
        loadedUI.drawStock(stock, debug, k)
    end
end

function loadedUI.drawStock(stock, debug, key)
    debug.questUI.stocks = {}

    local name = stock.name

    ImGui.BeginChild("stock_" .. key, 300, 65, true)

    stock.name, changed =  ImGui.InputTextWithHint("Stock Name", "Name...", stock.name, 100)
    if changed then
        os.rename("data/static/stocks/" .. name .. ".json", "data/static/stocks/" .. stock.name .. ".json")
    end

    ImGui.Separator()

    if ImGui.Button("Load to edit") then
        debug.switchToEdit = true
        debug.editUI.currentStock = stock
    end
    ImGui.SameLine()
    if ImGui.Button("Save") then
        config.saveFile("data/static/stocks/" .. stock.name .. ".json", stock)
        debug.fileUI[name] = nil
    end
    ImGui.SameLine()
    if ImGui.Button("Remove") then
        if debug.editUI.currentStock == stock then
            debug.editUI.currentStock = nil
        end
        loadedUI.stocks[key] = nil
    end

    ImGui.EndChild()
end

return loadedUI