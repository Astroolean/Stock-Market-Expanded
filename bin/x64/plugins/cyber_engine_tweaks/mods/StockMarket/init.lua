-------------------------------------------------------------------------------------------------------------------------------
-- STOCK MARKET EXPANDED BY ASTROOLEAN
-- Version 3.0 - 128 Companies + Security & Insurance System
--
-- Expansion by: Astroolean
-- Original mod by: keanuWheeze (CP2077 Modding Tools Discord)
--
-- Features: 128 corporations, 445 news events, CPIC Insurance, Security Score,
--           Hacking Risk System, Master Config (settings.json)
--
-- Original license applies to base code:
--    * It may not be uploaded to any other site without express permission.
--    * Using any code contained herein in another mod requires credits.
-------------------------------------------------------------------------------------------------------------------------------

local GameUI = require("modules/external/GameUI")
local Cron = require("modules/external/Cron")
local debug = false

stocks = {
    runtimeData = {
        inMenu = false,
        inGame = false,
        cetOpen = false,
        popupManager = nil,
        errorPopupToken = nil
    },
    intervall = 120,
    config = require("modules/utils/config"),
    ConfigManager = require("modules/utils/ConfigManager"),
    browser = require("modules/ui/browser"),
    debug = require("debug/ui/baseUI"),
    version = 3.0
}

function stocks:new()
    registerForEvent("onInit", function()
        math.randomseed(os.clock()) -- Prevent predictable random() behavior
        CName.add("stocks")
        CName.add("stock")
        
        self.ConfigManager.load()
        self.intervall = self.ConfigManager.get("general.stockUpdateInterval", 120)

        local triggerManager = require("modules/logic/triggerManager"):new(self, self.intervall)
        local questManager = require("modules/logic/questManager"):new(self)
        local newsManager = require("modules/logic/newsManager"):new(self)

        self.market = require("modules/logic/stockMarket"):new(self.intervall, triggerManager, questManager, newsManager)
        self.market.triggerManager:onInit()
        self.market.questManger:onInit()
        self.market:setupPersistency()
        self.market:initialize()
        self.market:checkForData()

        Observe('RadialWheelController', 'OnIsInMenuChanged', function(_, isInMenu) -- Setup observer and GameUI to detect inGame / inMenu
            self.runtimeData.inMenu = isInMenu
        end)

        Observe("PopupsManager", "OnMenuUpdate", function (this)
            self.runtimeData.popupManager = this
        end)

        GameUI.OnSessionStart(function()
            self.runtimeData.inGame = true
            self.market.time = Game.GetTimeSystem():GetGameTime():Hours()
            self.market:checkForData()
        end)

        GameUI.OnSessionEnd(function()
            self.runtimeData.inGame = false
        end)

        self.listener = NewProxy({
            OnClose = {
                args = {'handle:inkGameNotificationData'},
                callback = function(_)
                    self.runtimeData.errorPopupToken = nil
                    collectgarbage()
                end
            }
        })

        self.runtimeData.inGame = not GameUI.IsDetached() -- Required to check if ingame after reloading all mods
        if self.runtimeData.inGame then
            self.market.time = Game.GetTimeSystem():GetGameTime():Hours()

            if debug then return end

            -- Force function call, to allow for getting a new ref to the PopupsManager
            Game.GetBlackboardSystem():Get(GetAllBlackboardDefs().UI_System):SetBool(GetAllBlackboardDefs().UI_System.IsInMenu, true)
            Game.GetBlackboardSystem():Get(GetAllBlackboardDefs().UI_System):SetBool(GetAllBlackboardDefs().UI_System.IsInMenu, false)

            Cron.After(1, function ()
                self.runtimeData.errorPopupToken = GenericMessageNotification.Show(self.runtimeData.popupManager, "Stock Market Error", "Why am i seeing this?\n- You reloaded all mods, using CETs [Reload all mods] button, while in-game.\n\nWhat does this mean?\n- This means the stock market mods saved data (Such as bought stocks) for this session have been lost.\n\nWhat can i do to fix it?\n- Reload the last save.", GenericMessageNotificationType.OK);
                self.runtimeData.errorPopupToken:RegisterListener(self.listener:Target(), self.listener:Function("OnClose"))
            end)
        end

        self.browser.init(self)
    end)

    registerForEvent("onUpdate", function(dt)
        if not self.runtimeData.inMenu and self.runtimeData.inGame then
            Cron.Update(dt)
            self.market:checkForTimeSkip(dt)
            self.market.triggerManager:update()
        end
    end)

    registerForEvent("onDraw", function()
        if not self.runtimeData.cetOpen or not debug then return end
        self.debug.draw(self)
    end)

    registerForEvent("onOverlayOpen", function()
        self.runtimeData.cetOpen = true
    end)

    registerForEvent("onOverlayClose", function()
        self.runtimeData.cetOpen = false
    end)
    
    registerHotkey("stocks_reload_config", "Reload Stock Market Config", function()
        self:reloadConfig()
    end)

    return self
end

function stocks:reloadConfig()
    print("[Stock Market] Reloading configuration...")
    self.ConfigManager.reload()
    
    self.intervall = self.ConfigManager.get("general.stockUpdateInterval", 120)
    
    if self.market and self.market.triggerManager then
        self.market.triggerManager.intervall = self.intervall
    end
    
    print("[Stock Market] Configuration reloaded! Some changes may require reopening the stock browser.")
    print("[Stock Market] Note: UI theme changes require closing and reopening the stock browser.")
end

return stocks:new()
