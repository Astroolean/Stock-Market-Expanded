local config = require("modules/utils/config")

newsUI = {
    news = nil,
    newsMeta = nil,
    filter = "",
    currentStockSelect = 0,
    stocks = {}
}

function newsUI.load(mod)
    if newsUI.news == nil then
        newsUI.news = {}
        for _, l in pairs(Game.GetSettingsSystem():GetVar("/language", "OnScreen"):GetValues()) do
            local language = l.value

            if not config.fileExists("localization/news/" .. language .. ".json") then
                config.tryCreateConfig("localization/news/" .. language .. ".json", {})
            end

            local locFile = config.loadFile("localization/news/" .. language .. ".json")

            for name, _ in pairs(mod.market.triggerManager.triggers) do
                if not mod.market.stocks[name] and locFile[name] == nil then
                    locFile[name] = {choice = {title = "", msg = ""}, default = {title = "", msg = ""}}
                end
                -- if not mod.market.stocks[name] then
                --     locFile[name] = {choice = {title = "", msg = ""}, default = {title = locFile[name].title, msg = locFile[name].msg}}
                -- end
            end

            config.saveFile("localization/news/" .. language .. ".json", locFile)
            newsUI.news[language] = locFile
        end
    end

    if not newsUI.newsMeta then
        config.tryCreateConfig("data/static/news/newsDelays.json", {})
        newsUI.newsMeta = config.loadFile("data/static/news/newsDelays.json")

        for name, _ in pairs(mod.market.triggerManager.triggers) do
            if not mod.market.stocks[name] and name:match("LocKey") then
                if not newsUI.newsMeta[name] then
                    newsUI.newsMeta[name] = 36 -- News delay for quest
                end
            elseif not mod.market.stocks[name] then
                if not newsUI.newsMeta[name] then
                    newsUI.newsMeta[name] = 12 -- News delay for dyn trigger
                end
            end
        end

        config.saveFile("data/static/news/newsDelays.json", newsUI.newsMeta)
    end
end

function newsUI.draw(_, mod)
    newsUI.load(mod)

    newsUI.filter = ImGui.InputTextWithHint('##Filter', 'Search for trigger...', newsUI.filter, 25)

    if newsUI.filter ~= '' then
        ImGui.SameLine()
        if ImGui.Button('X') then
            newsUI.filter = ''
        end
    end

    ImGui.Separator()

    local language = Game.GetSettingsSystem():GetVar("/language", "OnScreen"):GetValue().value

    for name, data in pairs(newsUI.news[language]) do
        local trigger = name
        local name = name

        if string.match(name, "LocKey") then
            local lockey = string.gsub(name, "quest_", "")
            name = GetLocalizedText(lockey)
        end

        if (tostring(name):lower():match(newsUI.filter:lower())) ~= nil then
            local state = ImGui.CollapsingHeader(name)
            if state then
                ImGui.PushID(name)

                ImGui.Indent(25)

                ImGui.PushItemWidth(450)

                data.default.title, changed = ImGui.InputTextWithHint("##title", "News Title...", data.default.title, 100000)
                if changed then config.saveFile("localization/news/" .. language .. ".json", newsUI.news[language]) end
                data.default.msg, changed = ImGui.InputTextWithHint("##msg", "News Message...", data.default.msg, 100000)
                if changed then config.saveFile("localization/news/" .. language .. ".json", newsUI.news[language]) end
                ImGui.PopItemWidth()

                ImGui.PushItemWidth(75)
                local minutes = (newsUI.newsMeta[trigger] * 5) / 60
                minutes, changed = ImGui.InputFloat("News message delay in minutes", minutes)

                if changed then
                    newsUI.newsMeta[trigger] = math.floor((minutes * 60) / 5)
                    config.saveFile("data/static/news/newsDelays.json", newsUI.newsMeta)
                end

                ImGui.PopItemWidth()
                ImGui.Separator()

                if string.match(trigger, "quest") and mod.market.triggerManager.triggers[trigger].factCondition ~= "" then
                    local cond = mod.market.triggerManager.triggers[trigger].factCondition
                    ImGui.Text("Alternative news will show if this fact is true: " .. cond)
                end

                ImGui.PushItemWidth(450)
                data.choice.title, changed = ImGui.InputTextWithHint("##Atitle", "Alternative News Title...", data.choice.title, 100000)
                if changed then config.saveFile("localization/news/" .. language .. ".json", newsUI.news[language]) end
                data.choice.msg, changed = ImGui.InputTextWithHint("##Amsg", "Alternative News Message...", data.choice.msg, 100000)
                if changed then config.saveFile("localization/news/" .. language .. ".json", newsUI.news[language]) end
                ImGui.PopItemWidth()

                ImGui.Unindent(25)
                ImGui.PopID()
            end
        end
    end
end

return newsUI