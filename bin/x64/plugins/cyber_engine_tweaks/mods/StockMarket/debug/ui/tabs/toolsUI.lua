local utils = require("modules/utils/utils")

toolsUI = {
    forceUpdateAmount = 1
}

function toolsUI.draw(debug, mod)
    ImGui.Spacing()

    if ImGui.Button("Force stocks update") then
        for i = 1, toolsUI.forceUpdateAmount do
            mod.market:update()
        end
    end

    ImGui.SameLine()

    ImGui.PushItemWidth(150)
    toolsUI.forceUpdateAmount = ImGui.InputInt("Force update multiplier", toolsUI.forceUpdateAmount)
end

return toolsUI