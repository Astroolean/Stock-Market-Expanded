local config = require("modules/utils/config")

createUI = {
    name = ""
}

function createUI.draw()
    createUI.name =  ImGui.InputTextWithHint("Stock Name", "Name...", createUI.name, 100)

    if ImGui.Button("Create") then
        local stock = {
            name = createUI.name,
            triggers = {},
            maxStepSize = 1,
            max = 400,
            min = 100,
            smoothOff = 5,
            sharesAmount = 50000,
            atlasPath = "base\\gameplay\\gui\\common\\icons\\weapon_manufacturers.inkatlas",
            atlasPart = "budgetarms",
            iconX = 150,
            iconY = 100,
            stockInfluence = {}
        }
        config.saveFile("data/static/stocks/" .. stock.name .. ".json", stock)
        createUI.name = ""
    end
end

return createUI