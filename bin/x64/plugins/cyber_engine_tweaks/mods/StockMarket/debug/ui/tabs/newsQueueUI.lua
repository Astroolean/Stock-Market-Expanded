newsBufferUI = {}

function newsBufferUI.draw(_, mod)
    ImGui.Text("In Buffer: " .. #mod.market.newsManager.data .. " / " .. mod.market.newsManager.bufferSize)
    ImGui.Separator()
    for i = 1, mod.market.newsManager.bufferSize do
        ImGui.PushID(i)
        local news = mod.market.newsManager.data[i]
        ImGui.Text("Slot " .. i .. ": ")
        ImGui.SameLine()
        if news == nil then
            ImGui.Text("Empty")
        else
            ImGui.Text(news.name .. " | Delay left: " .. news.delay * 5)
            if news.delay > 1 then
                ImGui.SameLine()
                if ImGui.Button("Skip Delay") then
                    news.delay = 1
                end
            end
        end
        ImGui.PopID()
    end
end

return newsBufferUI