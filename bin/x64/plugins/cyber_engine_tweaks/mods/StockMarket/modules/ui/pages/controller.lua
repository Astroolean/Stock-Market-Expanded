controller = {}

function controller:new(browserController, catcher, mod)
        local o = {}

    o.browserController = browserController
    o.catcher = catcher
    o.mod = mod

    o.loginPage = nil
    o.homePage = nil
    o.stockInfo = nil
    o.stocksPage = nil
    o.portfolioPage = nil
    o.insurancePage = nil
    o.currentInfoStock = nil
    o.properLogout = false

    o.activePage = ""

        self.__index = self
        return setmetatable(o, self)
end

function controller:initialize()
    if self.loginPage or self.homePage or self.stockInfo then self:uninitialize() end
    self.loginPage = require("modules/ui/pages/login"):new(self.browserController.currentPage, self, self.catcher)
    self.homePage = require("modules/ui/pages/home"):new(self.browserController.currentPage, self, self.catcher, self.mod)
    self.stockInfo = require("modules/ui/pages/stock"):new(self.browserController.currentPage, self, self.catcher, self.mod)
    self.stocksPage = require("modules/ui/pages/stocks"):new(self.browserController.currentPage, self, self.catcher, self.mod)
    self.newsPage = require("modules/ui/pages/news"):new(self.browserController.currentPage, self, self.catcher, self.mod)
    self.portfolioPage = require("modules/ui/pages/portfolio"):new(self.browserController.currentPage, self, self.catcher, self.mod)
    self.insurancePage = require("modules/ui/pages/insurance"):new(self.browserController.currentPage, self, self.catcher, self.mod)
    self.properLogout = false
    if self.mod.market.securityManager then
        self.mod.market.securityManager:onLogin(tostring(self.browserController), false)
    end
    self:switchToPage("login")
end

function controller:uninitialize()
    if self.mod.market.securityManager then
        self.mod.market.securityManager:onLogout(self.properLogout)
    end
    self.loginPage:uninitialize()
    self.homePage:uninitialize()
    self.stockInfo:uninitialize()
    self.stocksPage:uninitialize()
    self.newsPage:uninitialize()
    self.portfolioPage:uninitialize()
    if self.insurancePage then self.insurancePage:uninitialize() end
end

function controller:uninitializeAllPages()
    self.loginPage:uninitialize()
    self.homePage:uninitialize()
    self.stockInfo:uninitialize()
    self.stocksPage:uninitialize()
    self.newsPage:uninitialize()
    self.portfolioPage:uninitialize()
    if self.insurancePage then self.insurancePage:uninitialize() end
end

function controller:switchToPage(page)
    self.activePage = page
    self:uninitializeAllPages()
    
    if page == "login" then
        self.properLogout = true
        self.loginPage:initialize()
    elseif page == "home" then
        self.homePage:initialize()
    elseif page == "stockInfo" then
        self.stockInfo:initialize(self.currentInfoStock)
    elseif page == "stocks" then
        self.stocksPage:initialize()
    elseif page == "portfolio" then
        self.portfolioPage:initialize()
    elseif page == "news" then
        self.newsPage:initialize()
    elseif page == "insurance" then
        self.insurancePage:initialize()
    end
    inkTextRef.SetText(self.browserController.addressText, self:getPageAdress())
end

function controller:getPageAdress()
    if self.activePage == "login" then
        return "NETdir://nusa.stockXC.corp/login"
    elseif self.activePage == "home" then
        return "NETdir://nusa.stockXC.corp/home"
    elseif self.activePage == "stocks" then
        return "NETdir://nusa.stockXC.corp/stocks"
    elseif self.activePage == "portfolio" then
        return "NETdir://nusa.stockXC.corp/portfolio"
    elseif self.activePage == "news" then
        return "NETdir://nusa.stockXC.corp/news"
    elseif self.activePage == "insurance" then
        return "NETdir://nusa.stockXC.corp/cpic-insurance"
    elseif self.activePage == "stockInfo" then
        return "NETdir://nusa.stockXC.corp/stocks/" .. string.gsub(self.currentInfoStock.name, "%s", "_")
    end
end

return controller