local utils = require("modules/utils/utils")

triggerUI = {
    hideStocks = true,
    hideQuests = true,
    hideZero = true,
    filter = ""
}

function triggerUI.draw(mod)
    triggerUI.hideQuests = ImGui.Checkbox("Hide quest triggers", triggerUI.hideQuests)
    ImGui.SameLine()
    triggerUI.hideStocks = ImGui.Checkbox("Hide stock triggers", triggerUI.hideStocks)
    ImGui.SameLine()
    triggerUI.hideZero = ImGui.Checkbox("Hide zero triggers", triggerUI.hideZero)
    ImGui.SameLine()
    if ImGui.Button("Skip 3H") then
        mod.market.time = mod.market.time - 3
    end
    ImGui.Separator()

    triggerUI.filter = ImGui.InputTextWithHint('##Filter', 'Search for trigger...', triggerUI.filter, 25)

    if triggerUI.filter ~= '' then
        ImGui.SameLine()
        if ImGui.Button('X') then
            triggerUI.filter = ''
        end
    end

    ImGui.Separator()

    for key, trigger in pairs(mod.market.triggerManager.triggers) do
        local locKey = string.gsub(trigger.name, "quest_", "")
        if not (triggerUI.hideStocks and mod.market.stocks[key]) and not (triggerUI.hideZero and trigger.exportData.value == 0) and trigger.name:lower():match(triggerUI.filter:lower()) ~= nil and not string.match(trigger.name, "quest_") then
            ImGui.PushID(trigger.name)
            ImGui.Text(trigger.name .. ": " .. tostring(trigger.exportData.value))
            ImGui.SameLine()
            if ImGui.Button("Reset") then
                trigger.exportData.value = 0
            end
            ImGui.SameLine()
            if ImGui.Button("Add .1") then
                trigger.exportData.value = trigger.exportData.value + 0.1
            end
            ImGui.SameLine()
            if ImGui.Button("Sub .1") then
                trigger.exportData.value = trigger.exportData.value - 0.1
            end
            ImGui.SameLine()
            ImGui.Text("| Gone in: " .. utils.round((30 * (trigger.exportData.value / trigger.fadeSpeed)) / 60, 1))
            ImGui.PopID()
        elseif (locKey and not triggerUI.hideQuests) and not (triggerUI.hideZero and trigger.exportData.value == 0) and GetLocalizedText(locKey):lower():match(triggerUI.filter:lower()) then
            ImGui.PushID(trigger.name)
            ImGui.Text(GetLocalizedText(locKey) .. ": " .. trigger.exportData.value)
            ImGui.SameLine()
            if ImGui.Button("Reset") then
                trigger.exportData.value = 0
            end
            ImGui.SameLine()
            if ImGui.Button("Add .1") then
                trigger.exportData.value = trigger.exportData.value + 0.1
            end
            ImGui.SameLine()
            if ImGui.Button("Sub .1") then
                trigger.exportData.value = trigger.exportData.value - 0.1
            end
            ImGui.SameLine()
            ImGui.Text("| Gone in: " .. utils.round((30 * (trigger.exportData.value / trigger.fadeSpeed)) / 60, 1))
            ImGui.PopID()
        end
    end
end

return triggerUI