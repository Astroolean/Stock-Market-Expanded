local json = json or require("modules/external/json")
local ConfigManager = {}

ConfigManager.settings = nil
ConfigManager.loaded = false
ConfigManager.configPath = "data/config/settings.json"

local defaults = {
    general = {
        enabled = true,
        stockUpdateInterval = 120,
        enablePhoneNotifications = true,
        enableDebugMode = false,
        language = "en-us",
        currencySymbol = "E$"
    },
    ui = {
        theme = {
            primaryColor = {r = 94, g = 246, b = 255},
            secondaryColor = {r = 255, g = 200, b = 50},
            accentColor = {r = 200, g = 50, b = 255},
            successColor = {r = 50, g = 255, b = 100},
            dangerColor = {r = 255, g = 80, b = 80},
            warningColor = {r = 255, g = 180, b = 50},
            backgroundColor = {r = 15, g = 25, b = 40},
            panelColor = {r = 20, g = 30, b = 45},
            textPrimary = {r = 255, g = 255, b = 255},
            textSecondary = {r = 200, g = 220, b = 240},
            textMuted = {r = 120, g = 140, b = 160}
        },
        fonts = {
            title = 56,
            header = 42,
            subheader = 36,
            body = 32,
            label = 28,
            small = 24,
            tiny = 20
        },
        layout = {
            viewportWidth = 1100,
            viewportStartX = 80,
            headerHeight = 200,
            panelPadding = 20,
            elementSpacing = 15,
            buttonHeight = 60,
            inputHeight = 55,
            cardHeight = 90
        }
    },
    stockMarket = {
        startingCash = 10000,
        maxSharesPerTransaction = 10000,
        volatility = {
            globalMultiplier = 1.0,
            largeCap = {stepSize = 2.5},
            mediumCap = {stepSize = 4.0},
            smallCap = {stepSize = 5.5},
            pennyCap = {stepSize = 8.0}
        },
        tradingFees = {
            enabled = false,
            buyFeePercent = 0.0,
            sellFeePercent = 0.0
        },
        priceFluctuation = {
            crashChance = 0.02,
            boomChance = 0.02
        }
    },
    security = {
        enabled = true,
        hackingRisk = {
            enabled = true,
            baseHackChance = 0.15,
            publicPCMultiplier = 2.0,
            insecureLogoutMultiplier = 1.5,
            maxHackChance = 0.50,
            minPortfolioValueToHack = 10000,
            hackSeverity = {
                minor = {chance = 0.50, lossPercent = 0.25},
                major = {chance = 0.35, lossPercent = 0.50},
                catastrophic = {chance = 0.15, lossPercent = 1.00}
            }
        },
        securityScore = {
            maxScore = 100,
            startingScore = 50,
            properLogoutBonus = 10,
            insecureLogoutPenalty = -15,
            publicPCPenalty = -5,
            longSessionPenalty = -2,
            longSessionThresholdMinutes = 30
        }
    },
    insurance = {
        enabled = true,
        provider = "Cyber Punk Insurance Corporation",
        claimCooldownDays = 30,
        maxClaimsPerYear = 3,
        tiers = {
            none = {name = "Uninsured", monthlyPremium = 0, coveragePercent = 0, maxPayout = 0},
            basic = {name = "CPIC Basic", monthlyPremium = 500, coveragePercent = 0.25, maxPayout = 100000},
            standard = {name = "CPIC Standard", monthlyPremium = 2000, coveragePercent = 0.40, maxPayout = 500000},
            premium = {name = "CPIC Premium", monthlyPremium = 5000, coveragePercent = 0.50, maxPayout = 2000000},
            platinum = {name = "CPIC Platinum", monthlyPremium = 15000, coveragePercent = 0.75, maxPayout = 10000000}
        }
    },
    news = {
        enabled = true,
        updateFrequencyHours = 6,
        maxActiveNews = 10,
        questNewsEnabled = true,
        marketNewsEnabled = true
    },
    difficulty = {
        preset = "normal",
        multipliers = {
            hackChance = 1.0,
            insuranceCost = 1.0,
            volatility = 1.0
        }
    },
    audio = {
        enabled = true,
        uiSoundsEnabled = true,
        notificationsEnabled = true
    },
    notifications = {
        showHackWarnings = true,
        showInsuranceReminders = true,
        showPriceAlerts = true,
        showNewsAlerts = true,
        showTradeConfirmations = true
    }
}

function ConfigManager.reload()
    ConfigManager.loaded = false
    ConfigManager.settings = nil
    local result = ConfigManager.load()
    print("[Stock Market] Config reloaded from settings.json")
    return result
end

function ConfigManager.load()
    local success, result = pcall(function()
        local file = io.open(ConfigManager.configPath, "r")
        if file then
            local content = file:read("*a")
            file:close()
            if content and content ~= "" then
                return json.decode(content)
            end
        end
        return nil
    end)
    
    if success and result then
        ConfigManager.settings = ConfigManager.mergeDeep(defaults, result)
    else
        ConfigManager.settings = defaults
    end
    
    ConfigManager.loaded = true
    ConfigManager.applyDifficultyPreset()
    return ConfigManager.settings
end

function ConfigManager.mergeDeep(base, override)
    local result = {}
    for k, v in pairs(base) do
        if type(v) == "table" and type(override[k]) == "table" then
            result[k] = ConfigManager.mergeDeep(v, override[k])
        elseif override[k] ~= nil then
            result[k] = override[k]
        else
            result[k] = v
        end
    end
    for k, v in pairs(override) do
        if result[k] == nil then
            result[k] = v
        end
    end
    return result
end

function ConfigManager.applyDifficultyPreset()
    if not ConfigManager.settings then return end
    
    local preset = ConfigManager.settings.difficulty and ConfigManager.settings.difficulty.preset or "normal"
    local presets = {
        story = {hackChance = 0.0, insuranceCost = 0.5, volatility = 0.5},
        easy = {hackChance = 0.5, insuranceCost = 0.75, volatility = 0.75},
        normal = {hackChance = 1.0, insuranceCost = 1.0, volatility = 1.0},
        hard = {hackChance = 1.5, insuranceCost = 1.25, volatility = 1.25},
        nightmare = {hackChance = 2.5, insuranceCost = 1.5, volatility = 1.75}
    }
    
    local presetData = presets[preset] or presets.normal
    if ConfigManager.settings.difficulty then
        ConfigManager.settings.difficulty.multipliers = presetData
    end
end

function ConfigManager.get(path, default)
    if not ConfigManager.loaded then
        ConfigManager.load()
    end
    
    local value = ConfigManager.settings
    for key in string.gmatch(path, "[^%.]+") do
        if type(value) == "table" then
            value = value[key]
        else
            return default
        end
    end
    
    return value ~= nil and value or default
end

function ConfigManager.getColor(path)
    local rgb = ConfigManager.get(path)
    if rgb and rgb.r and rgb.g and rgb.b then
        return {r = rgb.r, g = rgb.g, b = rgb.b, a = rgb.a or 255}
    end
    return {r = 255, g = 255, b = 255, a = 255}
end

function ConfigManager.toInkColor(rgb)
    if not rgb then
        return nil
    end
    local r = rgb.r or 255
    local g = rgb.g or 255
    local b = rgb.b or 255
    local a = rgb.a or 255
    return {r = r, g = g, b = b, a = a}
end

function ConfigManager.getFont(name)
    local fonts = ConfigManager.get("ui.fonts", {})
    return fonts[name] or 28
end

function ConfigManager.getLayout(name)
    local layout = ConfigManager.get("ui.layout", {})
    return layout[name] or 100
end

function ConfigManager.getVolatility(capType)
    local volatility = ConfigManager.get("stockMarket.volatility", {})
    local globalMult = volatility.globalMultiplier or 1.0
    local diffMult = ConfigManager.get("difficulty.multipliers.volatility", 1.0)
    
    local capData = volatility[capType]
    if capData and capData.stepSize then
        return capData.stepSize * globalMult * diffMult
    end
    return 5.0
end

function ConfigManager.getHackChance()
    local base = ConfigManager.get("security.hackingRisk.baseHackChance", 0.15)
    local diffMult = ConfigManager.get("difficulty.multipliers.hackChance", 1.0)
    return base * diffMult
end

function ConfigManager.getInsuranceTier(tierName)
    local tiers = ConfigManager.get("insurance.tiers", {})
    local tier = tiers[tierName]
    if tier then
        local costMult = ConfigManager.get("difficulty.multipliers.insuranceCost", 1.0)
        return {
            monthlyPremium = math.floor((tier.monthlyPremium or 0) * costMult),
            coveragePercent = tier.coveragePercent or 0,
            maxPayout = tier.maxPayout or 0,
            name = tier.name or tierName,
            description = tier.description or ""
        }
    end
    return nil
end

function ConfigManager.isEnabled(feature)
    local featureMap = {
        security = "security.enabled",
        hacking = "security.hackingRisk.enabled",
        insurance = "insurance.enabled",
        news = "news.enabled",
        tradingFees = "stockMarket.tradingFees.enabled",
        audio = "audio.enabled",
        uiSounds = "audio.uiSoundsEnabled",
        notifications = "general.enablePhoneNotifications"
    }
    
    local path = featureMap[feature]
    if path then
        return ConfigManager.get(path, true)
    end
    return true
end

function ConfigManager.reload()
    ConfigManager.loaded = false
    return ConfigManager.load()
end

function ConfigManager.save()
    local success, err = pcall(function()
        local file = io.open(ConfigManager.configPath, "w")
        if file then
            local content = json.encode(ConfigManager.settings)
            file:write(content)
            file:close()
        end
    end)
    return success
end

return ConfigManager
