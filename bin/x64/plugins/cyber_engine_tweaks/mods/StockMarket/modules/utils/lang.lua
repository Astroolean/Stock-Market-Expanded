local config = require("modules/utils/config")

local lang = {}

lang.pc_stockmarket = "pc_stockmarket"
lang.button_home = "button_home"
lang.button_stocks = "button_stocks"
lang.button_portfolio = "button_portfolio"
lang.button_news = "button_news"
lang.button_insurance = "button_insurance"
lang.login_login = "login_login"
lang.button_logout = "button_logout"
lang.graph_time = "graph_time"
lang.graph_value = "graph_value"
lang.login_name = "login_name"
lang.login_password = "login_password"
lang.info_value = "info_value"
lang.info_buy = "info_buy"
lang.info_sell = "info_sell"
lang.info_owned = "info_owned"
lang.info_transaction = "info_transaction"
lang.info_post_portfolio = "info_post_portfolio"
lang.info_margin = "info_margin"
lang.stocks_ascending = "stocks_ascending"
lang.stocks_descending = "stocks_descending"
lang.portfolio_accountValue = "portfolio_accountValue"
lang.portfolio_ownedStocks = "portfolio_ownedStocks"
lang.portfolio_totalMoney = "portfolio_totalMoney"
lang.portfolio_moneyInStocks = "portfolio_moneyInStocks"
lang.news_toggleNotification = "news_toggleNotification"
lang.news_contactName = "news_contactName"

function lang.getLang(key)
    local language = Game.GetSettingsSystem():GetVar("/language", "OnScreen"):GetValue().value
    local loc = require("localization/" .. language)

    if loc[key] == "" or not loc[key] then
        return "en-us"
    else
        return language
    end
end

function lang.getText(key)
    local language = lang.getLang(key)
    local loc = require("localization/" .. language)
    local text = loc[key]

    if text == "" or not text then
        return "Not Localized"
    else
        return text
    end
end

function lang.getNewsLang(key)
    local language = "en-us"
    local ok, val = pcall(function()
        local v = Game.GetSettingsSystem():GetVar("/language", "OnScreen"):GetValue()
        if v and v.value and v.value.value then
            return v.value.value
        end
        if v and v.value then
            return v.value
        end
        return nil
    end)
    if ok and val and val ~= "" then
        language = val
    end

    local loc = config.loadFile("localization/news/" .. language .. ".json")
    if type(loc) ~= "table" then
        return "en-us"
    end

    local entry = loc[key]
    if type(entry) ~= "table" then
        return "en-us"
    end

    local d = entry["default"]
    local c = entry["choice"]
    if type(d) ~= "table" or type(c) ~= "table" then
        return "en-us"
    end

    local function empty(s) return (s == nil or s == "") end
    if empty(d["title"]) or empty(d["msg"]) or empty(c["title"]) or empty(c["msg"]) then
        return "en-us"
    end

    return language
end

function lang.getNewsText(key, condition)
    local language = lang.getNewsLang(key)
    local loc = config.loadFile("localization/news/" .. language .. ".json")

    local subNews = "default"
    if condition then subNews = "choice" end

    local entry = (type(loc) == "table") and loc[key] or nil
    local sub = (type(entry) == "table") and entry[subNews] or nil

    -- Fallback to en-us if missing
    if type(sub) ~= "table" then
        loc = config.loadFile("localization/news/en-us.json")
        entry = (type(loc) == "table") and loc[key] or nil
        sub = (type(entry) == "table") and entry[subNews] or nil
    end

    if type(sub) ~= "table" then
        return "Not Localized", "Not Localized"
    end

    local title = sub["title"] or "Not Localized"
    local msg = sub["msg"] or "Not Localized"

    if title == "" then title = "Not Localized" end
    if msg == "" then msg = "Not Localized" end

    return title, msg
end

return lang