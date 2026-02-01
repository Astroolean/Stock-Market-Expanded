local config = require("modules/utils/config")

fileUI = {
    filter = ""
}

function fileUI.drawStock(file, debug)
    local name = file.name:match("(.+)%..+$")

    if fileUI[name] == nil then
        print("Loading: " .. "data/static/stocks/" .. name .. ".json")
        fileUI[name] = config.loadFile("data/static/stocks/" .. name .. ".json") -- Load file if not loaded yet
    end

    ImGui.Text(name)
    ImGui.SameLine()
    ImGui.PushID(name)
    if ImGui.Button("Load") then
        debug.switchToLoaded = true
        table.insert(debug.loadedUI.stocks, fileUI[name])
    end
    ImGui.SameLine()
    if ImGui.Button("Delete") then
        os.remove("data/static/stocks/" .. name .. ".json")
        fileUI[name] = nil
    end
    ImGui.PopID()
end

function fileUI.draw(debug)
    fileUI.filter = ImGui.InputTextWithHint('##Filter', 'Search for stock...', fileUI.filter, 25)

    if fileUI.filter ~= '' then
        ImGui.SameLine()
        if ImGui.Button('X') then
            fileUI.filter = ''
        end
    end

    for _, file in pairs(dir("data/static/stocks/")) do
        if file.name:match("^.+(%..+)$") == ".json" then
            if (file.name:lower():match(fileUI.filter:lower())) ~= nil then
                fileUI.drawStock(file, debug)
            end
        end
    end
end

return fileUI