local ink = require("modules/ui/inkHelper")
local color = require("modules/ui/color")
local lang = require("modules/utils/lang")
local Cron = require("modules/external/Cron")

login = {}

function login:new(inkPage, controller, eventCatcher)
        local o = {}

    o.inkPage = inkPage
        o.controller = controller
        o.eventCatcher = eventCatcher

        o.canvas = nil
        o.button = nil

        o.nameFilled = false
        o.pwFilled = false
        o.loginDone = false
        o.loginCron = nil

        self.__index = self
        return setmetatable(o, self)
end

function login:initialize()
        self.canvas = ink.canvas(0, 20, inkEAnchor.TopCenter)
        self.canvas:Reparent(self.inkPage, -1)

        local t = ink.text(tostring(lang.getText(lang.login_name) .. ":         "), 360, 350, 150, color.white)
        t:SetAnchorPoint(1, 0.5)
        t:Reparent(self.canvas, -1)

        local t = ink.text(lang.getText(lang.login_password) .. ":               ", 585, 550, 150, color.white)
        t:SetAnchorPoint(1, 0.5)
        t:Reparent(self.canvas, -1)

        local logo = ink.image(-1440, 75, 233, 233, "base\\icon\\stock_logo.inkatlas", "stock")
    logo.image:SetTintColor(HDRColor.new({ Red = 0.9, Green = 0.9, Blue = 0.9, Alpha = 1.0 }))
    logo.pos:Reparent(self.canvas, -1)

        self.fluff = ink.text("", -1500, 750, 30, color.aqua)
        self.fluff:SetOpacity(0.85)
        self.fluff:Reparent(self.canvas, -1)

        local fluff2 = ink.text("Connection secured by Netwatch. STOCKXC v.1.2", 916, 1200, 32, color.aqua)
        fluff2:SetOpacity(0.5)
        fluff2:Reparent(self.canvas, -1)

        self.button = require("modules/ui/widgets/button"):new()
        self.button.x = 0
        self.button.y = 800
        self.button.sizeX = 500
        self.button.sizeY = 220
        self.button.textSize = 85
        self.button.text = lang.getText(lang.login_login)
        self.button.borderSize = 6
        self.button.fillColor = color.new(0.2, 0.2, 0.2)
        self.button.bgColor = color.new(0.5, 0.5, 0.5)
        self.button.textColor = color.white
        self.button.callback = function()
                if self.loginCron then return end
                if self.pwFilled and self.nameFilled then
                        self:startFluffSeq()
                end
                -- self.controller:switchToPage("home")
        end
        self.button.hoverInCallback = function (bt)
                bt.fill:SetOpacity(0.95)
        end
        self.button:initialize()
        self.button:registerCallbacks(self.eventCatcher)
        self.button.canvas:Reparent(self.canvas, -1)

        local name = "Valerie"
        if GetPlayer():GetGender().value == "Male" then name = "Vincent" end
        self:createFillButton(240, 350, 400, name, "name")
        self:createFillButton(365, 550, 650, "*************", "pw")
end

function login:startFluffSeq()
        local fluffText = {"Starting connection request from CLIENT_ID 31280904....",
                                                "Checking for valid subnet...",
                                                "Preparing for Handshake with main server...",
                                                "Targeting server ID-39-NC, Ping=27ms",
                                                "Handshake success, verifying USER_DATA with server...",
                                                "Data USERNAME_ valid...",
                                                "Data PASSWORD_h valid...",
                                                "User ID confirmed, server preparing for peer connection...",
                                                "NETWATCH node injection, nw-37913...",
                                                "Secure connection via NETWATCH node established...",
                                                "Connection established...",
                                                "INFO: Server=ID-39-NC;USER_ID=9323477;SESSION_KEY=c9qc83bhc292"}

        self.loginCron = Cron.Every(0.085, { tick = 1 }, function(timer)
                if timer.tick <= #fluffText then
                        self.fluff:SetText(self.fluff:GetText() .. "\n" .. fluffText[timer.tick])
                else
                        timer:Halt()
                        self.controller:switchToPage("home")
                        self.loginCron = nil
                end
                timer.tick = timer.tick + 1
        end)
end

function login:createFillButton(x, y, sX, text, type)
        local button = require("modules/ui/widgets/button"):new()
        button.x = x
        button.y = y
        button.sizeX = sX
        button.sizeY = 160
        button.textSize = 85
        button.text = ""
        button.borderSize = 6
        button.fillColor = color.new(0.2, 0.2, 0.2)
        button.bgColor = color.new(0.5, 0.5, 0.5)
        button.textColor = color.white
        button.callback = function()
                if button.textWidget:GetText() == text or button.fillCron then return end

                button.fillCron = Cron.Every(0.075, { tick = 1 }, function(timer)
                        local c = text:sub(timer.tick, timer.tick)
                        if timer.tick <= #text then
                                button.textWidget:SetText(button.textWidget:GetText() .. c)
                        else
                                timer:Halt()
                                self:updateLogin(type)
                                button.fillCron = nil
                        end
                        timer.tick = timer.tick + 1
                end)
        end
        button:initialize()
        button:registerCallbacks(self.eventCatcher)
        button.canvas:Reparent(self.canvas, -1)
end

function login:updateLogin(type)
        if type == "name" then self.nameFilled = true end
        if type == "pw" then self.pwFilled = true end

        if self.pwFilled and self.nameFilled then
                self.button.fill:SetTintColor(color.black)
                self.button.bg:SetTintColor(color.cyan)
        end
end

function login:uninitialize()
        if not self.canvas then return end
        self.nameFilled = false
        self.pwFilled = false
        self.loginDone = false
        self.eventCatcher.removeSubscriber(self.button)
        self.inkPage:RemoveChild(self.canvas)
        self.canvas = nil
end

return login