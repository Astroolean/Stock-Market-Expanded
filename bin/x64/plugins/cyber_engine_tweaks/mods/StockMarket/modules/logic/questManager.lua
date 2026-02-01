local utils = require("modules/utils/utils")
local Cron = require("modules/external/Cron")

questManager = {}

function questManager:new(mod)
	local o = {}

    o.mod = mod
    o.quests = {}

	self.__index = self
   	return setmetatable(o, self)
end

function questManager:onInit()
    self.quests = config.loadFile("data/static/quests/quests.json")

    for _, quest in pairs(self.quests) do
        local trigger = require("modules/logic/questTrigger"):new(self.mod.market)
        trigger:initialize(quest)
        trigger:checkForData(self.mod.market.persistentData)
        self.mod.market.triggerManager.triggers["quest_" .. quest.name] = trigger
    end

    Observe("JournalNotificationQueue", "OnJournalUpdate", function(_, hash, class)
        if class.value == "gameJournalQuest" then
            local entry = Game.GetJournalManager():GetEntry(hash)
            local state = Game.GetJournalManager():GetEntryState(entry)
            local name = entry:GetTitle(Game.GetJournalManager())

            if state == gameJournalEntryState.Succeeded then
                local questData = self.quests[name]
                if not questData then return end

                local condition = 1
                if Game.GetQuestsSystem():GetFactStr(questData.factCondition) == 1 then
                    condition = -1
                end
                self.mod.market.triggerManager.triggers["quest_" .. questData.name].exportData.value = questData.amount * condition * 1.3
            end
        end
    end)

    Observe("JournalNotificationQueue", "OnNCPDJobDoneEvent", function(_, evt)
        local ncpdTrigger = self.mod.market.triggerManager.triggers["ncpdHustler"]
        ncpdTrigger.exportData.value = ncpdTrigger.exportData.value + (evt.levelXPAwarded / 3500) + (evt.streetCredXPAwarded / 3500)
    end)
end

return questManager