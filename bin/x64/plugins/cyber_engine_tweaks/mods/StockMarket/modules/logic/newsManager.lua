local lang = require("modules/utils/lang")
local Cron = require("modules/external/Cron")
local config = require("modules/utils/config")
local utils = require("modules/utils/utils")

newsManager = {}

function newsManager:new(mod)
        local o = {}

    o.mod = mod
    o.data = {}
    o.questDelays = {}
    o.updateCron = nil
    o.dataLink = nil

    o.settings = nil
    o.journalQ = nil
    o.messages = {}
    o.contactHash = 999999999999999999 -- ?
    o.isContactSelected = false
    o.bufferSize = 10

    o.lang = lang

        self.__index = self
        return setmetatable(o, self)
end

function newsManager:checkForData(data)
    self.data = {}

    if data["news"][1] == nil then
        self:setupData()
        data["news"] = self.data
    else
        self.data = data["news"]
    end
    self.dataLink = data -- Data cant get written back to the "data" otherwise

    if data["settings"]["notifications"] == nil then -- Setup settings data
        data["settings"]["notifications"] = true
    end
    if data["settings"]["lastNews"] == nil then -- Setup settings data
        local time = Game.GetTimeSystem():GetGameTime()
        data["settings"]["lastNews"] = {d = time:Days(), h = time:Hours(), m = time:Minutes()}
    end
    self.settings = data["settings"]

    local news = {} -- Fix wrong order
    for k, v in pairs(self.data) do
        news[k] = v
    end
    self.data = news
end

function newsManager:setupData() -- Setup some news to avoid empty news UI
    self:addNews("roadRage", 0)
    self:addNews("purchaseVehicleAny", 0)
    self:addNews("smartWeaponKills", 0)
end

function newsManager:onInit()
    self.updateCron = Cron.Every(5.0, function ()
        self:update()
    end)
    self.delays = config.loadFile("data/static/news/newsDelays.json")
    self:registerObservers()
end

function newsManager:isNewsActive(triggerName) -- Is this news already displayed
    for _, data in pairs(self.data) do
        if data.name == triggerName then return true end
    end
    return false
end

function newsManager:getNews() -- Returns list of all active news (No more delay)
    local news = {}
    for _, data in pairs(self.data) do
        if data.delay <= 1 then
            table.insert(news, data.name)
        end
    end
    return news
end

function newsManager:addNews(name, delay) -- Add to the queue
    local trigger = self.mod.market.triggerManager.triggers[name]
    local hasFactCondition = trigger and trigger.factCondition and trigger.factCondition ~= ""
    local factMet = hasFactCondition and Game.GetQuestsSystem():GetFactStr(trigger.factCondition) == 1
    
    local title, msg = lang.getNewsText(name, factMet)
    if title == nil or msg == nil or title == "" or msg == "" then return end -- No news for this trigger

    local shift = {}
    for key, value in pairs(self.data) do
        if key < self.bufferSize then
            shift[key + 1] = value
        end
    end

    shift[1] = {name = name, delay = delay or self.delays[name]}
    self.data = shift
end

function newsManager:updateLastMessageTime()
    local time = Game.GetTimeSystem():GetGameTime()
    self.settings.lastNews = {d = time:Days(), h = time:Hours(), m = time:Minutes()}
end

function newsManager:update() -- Runs on Cron
    local remove = nil
    for key, data in pairs(self.data) do -- Decrement delay, show notifications if needed
        if data.delay == 1 then
            self:updateLastMessageTime()
            if self.settings.notifications then
                self:sendMessage(data.name)
            end
            remove = key
        end
        data.delay = math.max(0, data.delay - 1)
    end
    if remove then -- Move newly activated news to the top
        local d = self.data[remove]
        table.remove(self.data, remove)
        table.insert(self.data, 1, d)
    end

    for name, trigger in pairs(self.mod.market.triggerManager.triggers) do -- Detect new news to add to the queue
        if not self.mod.market.stocks[name] then
            local newsThreshold = trigger.newsThreshold or 0.375
            if name:match("LocKey") then
                newsThreshold = 0.95
            end

            if (trigger.exportData.value >= newsThreshold or trigger.exportData.value < -0.95) and not self:isNewsActive(name) then -- Negative for quests with invert condition
                self:addNews(name)
            end
        end
    end

    self.dataLink["news"] = self.data
end

-- Phone stuff

function newsManager:registerObservers()
    Observe("JournalNotificationQueue", "OnMenuUpdate", function(this)
        self.journalQ = this
    end)

    Observe("JournalNotificationQueue", "OnPlayerAttach", function(this)
        self.journalQ = this
    end)

    Observe("JournalNotificationQueue", "OnInitialize", function(this)
        self.journalQ = this
    end)

        Override("MessengerUtils", "GetSimpleContactDataArray;JournalManagerBoolBoolBoolMessengerContactSyncData", function (journal, includeUnknown, skipEmpty, includeWithNoUnread, activeDataSync, wrapped)
                local contacts = wrapped(journal, includeUnknown, skipEmpty, includeWithNoUnread, activeDataSync)

        local contact = ContactData.new()
        contact.hash = self.contactHash
        contact.localizedName = lang.getText(lang.news_contactName)
        contact.id = "stock"
        contact.contactId = "stock"
        contact.isCallable = false
        contact.type = MessengerContactType.SingleThread
        contact.avatarID = TweakDBID.new("PhoneAvatars.Avatar_Unknown")

        local news = self:getNews()
        local name = news[1]
        local trigger = name and self.mod.market.triggerManager.triggers[name]
        local hasFactCondition = trigger and trigger.factCondition and trigger.factCondition ~= ""
        local factMet = hasFactCondition and Game.GetQuestsSystem():GetFactStr(trigger.factCondition) == 1
        local title, _ = lang.getNewsText(name, factMet)

        contact.localizedPreview  = title or "No news available"
        contact.hasValidTitle = true
        contact.timeStamp = GameTime.MakeGameTime(self.settings.lastNews.d, self.settings.lastNews.h, self.settings.lastNews.m, 0)
        table.insert(contacts, contact)

                return contacts
        end)

    Override("MessangerItemRenderer", "OnJournalEntryUpdated", function (this, entry, extra, wrapped) -- Insert messages text
                wrapped(entry, extra)

        -- Only rewrite message text for StockMarket "news" entries
        if not entry or not entry.id then return end
        local id = tostring(entry.id)
        if id == "stock" then return end

        -- Our messages are inserted as JournalPhoneMessage entries where the id is the trigger name
        -- (e.g. "roadRage", "purchaseVehicleAny", or quest triggers like "quest_LocKey#12345").
        -- If the id isn't one of our triggers, bail so we don't touch vanilla/other-mod messages.
        local trigger = self.mod.market.triggerManager.triggers[id]
        if not trigger then return end
        local hasFactCondition = trigger and trigger.factCondition and trigger.factCondition ~= ""
        local factMet = hasFactCondition and Game.GetQuestsSystem():GetFactStr(trigger.factCondition) == 1
        local title, msg = lang.getNewsText(id, factMet)

                if title and title ~= "Not Localized" and msg and msg ~= "Not Localized" then
            local text = title .. ":\n" .. msg
                        this:SetMessageView(text, MessageViewType.Received, lang.getText(lang.news_contactName));
                end
        end)

    Override("PhoneMessagePopupGameController", "OnInitialize", function (this, wrapped)
                wrapped()
                if lang.getText(lang.news_contactName) == this.data.contactNameLocKey.value then
                        this.data.journalEntry = JournalContact.new()
                        this.data.journalEntry.id = "stock"
                        this:SetupData()
                end
        end)

        Override("PhoneMessagePopupGameController", "OnRefresh", function (this, event, wrapped)
                if lang.getText(lang.news_contactName) == event.data.contactNameLocKey.value then
                        this.data = event.data
                        this.data.journalEntry = JournalContact.new()
                        this.data.journalEntry.id = "stock"
                        this:SetupData()
                else
                        wrapped(event)
                end
        end)

    ObserveAfter("MessengerDialogViewController", "UpdateData;BoolBool", function (this, a, _, _) -- Insert custom messages / replies
        if this.parentEntry and this.parentEntry.id == "stock" then -- Is our custom contact
                        local countMessages
                        local lastMessageWidget

            -- Insert emtpy custom messages
            local messages = {}
            local news = self:getNews()

            for i = #news, 1, -1 do
                table.insert(messages, JournalPhoneMessage.new({id = news[i]}))
            end

            this.messages = messages

                        inkWidgetRef.SetVisible(this.replayFluff, #this.replyOptions > 0) -- Vanilla stuff
                        this:SetVisited(this.messages)
                        this.messagesListController:Clear()
                        this.messagesListController:PushEntries(this.messages)

                        this.choicesListController:Clear()
                        this.choicesListController:PushEntries(this.replyOptions)
                        if #(this.replyOptions) > 0 then
                                this.choicesListController:SetSelectedIndex(0)
                        end
                        if IsDefined(this.newMessageAninmProxy) then
                                this.newMessageAninmProxy:Stop()
                        end
                        countMessages = this.messagesListController:Size()
                        if a and countMessages > 0 then
                                lastMessageWidget = this.messagesListController:GetItemAt(countMessages - 1)
                        end
                        if IsDefined(lastMessageWidget) then
                                this.newMessageAninmProxy = this:PlayLibraryAnimationOnAutoSelectedTargets("new_message", lastMessageWidget)
                        end
                        this.scrollController:SetScrollPosition(1.00)
                end
        end)
end

function newsManager:sendMessage(name)
    if not self.journalQ then return end

    local title, _ = lang.getNewsText(name, self.mod.market.triggerManager.triggers[name].factCondition and Game.GetQuestsSystem():GetFactStr(self.mod.market.triggerManager.triggers[name].factCondition) == 1)

        local notificationData = gameuiGenericNotificationData.new()
        local openAction = OpenPhoneMessageAction.new()
        openAction.phoneSystem = Game.GetScriptableSystemsContainer():Get("PhoneSystem")

        local contact = JournalContact.new()
        contact.id = "stock"
        openAction.journalEntry = contact

        local userData = PhoneMessageNotificationViewData.new()
        userData.title = lang.getText(lang.news_contactName)
        userData.SMSText = title
        userData.action = openAction
        userData.animation = CName("notification_phone_MSG")
        userData.soundEvent = CName("PhoneSmsPopup")
        userData.soundAction = CName("OnOpen")

        notificationData.time = 6.7
        notificationData.widgetLibraryItemName = CName("notification_message")
        notificationData.notificationData = userData

        self.journalQ:AddNewNotificationData(notificationData)
end

return newsManager