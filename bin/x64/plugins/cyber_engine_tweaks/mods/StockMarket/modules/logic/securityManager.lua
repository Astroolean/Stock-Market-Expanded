local utils = require("modules/utils/utils")
local config = require("modules/utils/config")

securityManager = {}

function securityManager:new(mod)
    local o = {}
    
    o.mod = mod
    o.configPath = "data/config/settings.json"
    o.settings = nil
    
    o.sessionData = {
        loginTime = 0,
        isLoggedIn = false,
        isPublicPC = false,
        properLogout = false,
        currentPCId = nil
    }
    
    o.exportData = {
        securityScore = 50,
        consecutiveSecureLogins = 0,
        lastLoginTime = 0,
        lastLogoutTime = 0,
        insecureLogoutCount = 0,
        totalLogins = 0,
        hackAttemptsPending = 0,
        lastHackCheck = 0,
        insuranceTier = "none",
        insuranceStartDate = 0,
        lastPremiumPaid = 0,
        claimHistory = {},
        lastClaimDate = 0,
        -- New tracking for enhanced scoring
        successfulTrades = 0,
        failedTrades = 0,
        portfolioChecks = 0,
        lastPortfolioCheck = 0,
        newsReads = 0,
        lastNewsRead = 0,
        diversificationBonus = 0,
        suspiciousActivityCount = 0,
        lastTradeTime = 0,
        largeTradeCount = 0
    }
    
    self.__index = self
    return setmetatable(o, self)
end

function securityManager:loadSettings()
    local defaults = {
        security = {
            enabled = true,
            hackingRisk = {
                enabled = true,
                baseHackChance = 0.15,
                maxHackChance = 0.50,
                minPortfolioValueToHack = 10000,
                hackSeverity = {
                    minor = { chance = 0.50, portfolioLossPercent = 0.25 },
                    major = { chance = 0.35, portfolioLossPercent = 0.50 },
                    catastrophic = { chance = 0.15, portfolioLossPercent = 1.0 }
                }
            },
            securityScore = {
                maxScore = 100,
                startingScore = 50,
                -- Login/Logout factors
                properLogoutBonus = 10,
                insecureLogoutPenalty = -15,
                publicPCPenalty = -5,
                longSessionPenalty = -2,
                longSessionThresholdMinutes = 30,
                consecutiveSecureLoginsBonus = 5,
                -- Trading factors
                successfulTradeBonus = 2,
                failedTradePenalty = -3,
                largeTradePenalty = -5,
                largeTradeThreshold = 100000,
                rapidTradingPenalty = -8,
                rapidTradingWindowSeconds = 30,
                -- Portfolio factors
                portfolioCheckBonus = 1,
                portfolioCheckCooldownMinutes = 5,
                diversifiedPortfolioBonus = 5,
                diversificationThreshold = 5,
                concentratedPortfolioPenalty = -10,
                -- News factors
                newsReadBonus = 1,
                newsReadCooldownMinutes = 2,
                -- Insurance factors
                hasInsuranceBonus = 3,
                insuranceCheckInterval = 300,
                -- Time-based factors
                nightTradingPenalty = -4,
                nightStartHour = 2,
                nightEndHour = 5,
                -- Behavior factors
                idleSessionPenalty = -1,
                idleThresholdMinutes = 15,
                frequentLoginBonus = 2,
                frequentLoginDays = 3,
                -- Risk factors
                allInOnePenalty = -15,
                highValueTargetPenalty = -5,
                highValueThreshold = 500000,
                -- Recovery factors
                cleanRecordBonus = 5,
                cleanRecordDays = 7,
                hackSurvivorBonus = 3
            }
        },
        insurance = {
            enabled = true,
            cpicInsurance = {
                tiers = {
                    none = { name = "Uninsured", monthlyPremium = 0, coveragePercent = 0, maxPayout = 0 },
                    basic = { name = "CPIC Basic", monthlyPremium = 500, coveragePercent = 0.25, maxPayout = 100000 },
                    standard = { name = "CPIC Standard", monthlyPremium = 2000, coveragePercent = 0.40, maxPayout = 500000 },
                    premium = { name = "CPIC Premium", monthlyPremium = 5000, coveragePercent = 0.50, maxPayout = 2000000 },
                    platinum = { name = "CPIC Platinum", monthlyPremium = 15000, coveragePercent = 0.75, maxPayout = 10000000 }
                },
                payoutCalculation = {
                    minSecurityScoreMultiplier = 0.5,
                    maxSecurityScoreMultiplier = 1.0
                }
            }
        }
    }
    
    if config.fileExists(self.configPath) then
        local loaded = config.loadFile(self.configPath)
        self.settings = self:mergeSettings(defaults, loaded)
    else
        self.settings = defaults
    end
end

function securityManager:mergeSettings(defaults, loaded)
    local result = {}
    for k, v in pairs(defaults) do
        if type(v) == "table" then
            if loaded[k] and type(loaded[k]) == "table" then
                result[k] = self:mergeSettings(v, loaded[k])
            else
                result[k] = v
            end
        else
            result[k] = loaded[k] ~= nil and loaded[k] or v
        end
    end
    for k, v in pairs(loaded) do
        if result[k] == nil then
            result[k] = v
        end
    end
    return result
end

function securityManager:checkForData(data)
    if data["security"] == nil then
        data["security"] = self.exportData
    else
        self.exportData = data["security"]
        -- Defensive defaults for backward compatibility with old saves
        if self.exportData.securityScore == nil then self.exportData.securityScore = 50 end
        if self.exportData.consecutiveSecureLogins == nil then self.exportData.consecutiveSecureLogins = 0 end
        if self.exportData.lastLoginTime == nil then self.exportData.lastLoginTime = 0 end
        if self.exportData.lastLogoutTime == nil then self.exportData.lastLogoutTime = 0 end
        if self.exportData.insecureLogoutCount == nil then self.exportData.insecureLogoutCount = 0 end
        if self.exportData.totalLogins == nil then self.exportData.totalLogins = 0 end
        if self.exportData.hackAttemptsPending == nil then self.exportData.hackAttemptsPending = 0 end
        if self.exportData.lastHackCheck == nil then self.exportData.lastHackCheck = 0 end
        if self.exportData.insuranceTier == nil then self.exportData.insuranceTier = "none" end
        if self.exportData.insuranceStartDate == nil then self.exportData.insuranceStartDate = 0 end
        if self.exportData.lastPremiumPaid == nil then self.exportData.lastPremiumPaid = 0 end
        if self.exportData.claimHistory == nil then self.exportData.claimHistory = {} end
        if self.exportData.lastClaimDate == nil then self.exportData.lastClaimDate = 0 end
    end
end

function securityManager:onLogin(pcId, isPublicPC)
    local currentTime = os.time()
    local timeSinceLastLogout = currentTime - (self.exportData.lastLogoutTime or 0)
    local loginCooldown = self.settings.security.securityScore.loginCooldownSeconds or 30
    
    self.sessionData.loginTime = currentTime
    self.sessionData.isLoggedIn = true
    self.sessionData.isPublicPC = isPublicPC or false
    self.sessionData.properLogout = false
    self.sessionData.currentPCId = pcId
    
    -- Anti-exploit: Track if this is a "valid" session for scoring purposes
    -- Sessions started within cooldown period won't earn bonus on logout
    self.sessionData.isValidForBonus = timeSinceLastLogout >= loginCooldown
    
    self.exportData.totalLogins = self.exportData.totalLogins + 1
    self.exportData.lastLoginTime = currentTime
    
    if self.sessionData.isPublicPC then
        self:modifySecurityScore(self.settings.security.securityScore.publicPCPenalty or -5)
    end
end

function securityManager:onLogout(proper)
    if not self.sessionData.isLoggedIn then return end
    
    self.sessionData.properLogout = proper
    self.sessionData.isLoggedIn = false
    self.exportData.lastLogoutTime = os.time()
    
    local sessionLength = os.time() - self.sessionData.loginTime
    local longSessionThreshold = (self.settings.security.securityScore.longSessionThresholdMinutes or 30) * 60
    local minSessionForBonus = self.settings.security.securityScore.minSessionForBonusSeconds or 10
    local isValidSession = self.sessionData.isValidForBonus ~= false  -- Default true for backward compat
    
    if proper then
        -- Anti-exploit: Only give bonus if:
        -- 1. Session lasted at least minimum time
        -- 2. Session was not started during cooldown period
        if sessionLength >= minSessionForBonus and isValidSession then
            self:modifySecurityScore(self.settings.security.securityScore.properLogoutBonus or 10)
            self.exportData.consecutiveSecureLogins = self.exportData.consecutiveSecureLogins + 1
            
            -- Anti-exploit: Consecutive bonus only applies at milestones (3, 6, 9, etc.)
            -- not every single logout after 3
            local milestone = self.settings.security.securityScore.consecutiveBonusMilestone or 3
            if self.exportData.consecutiveSecureLogins % milestone == 0 then
                self:modifySecurityScore(self.settings.security.securityScore.consecutiveSecureLoginsBonus or 5)
            end
        end
        -- No bonus for instant logouts or rapid re-logins (anti-farming)
    else
        self:modifySecurityScore(self.settings.security.securityScore.insecureLogoutPenalty or -15)
        self.exportData.consecutiveSecureLogins = 0
        self.exportData.insecureLogoutCount = self.exportData.insecureLogoutCount + 1
        
        if self.settings.security.hackingRisk.enabled then
            self:scheduleHackAttempt()
        end
    end
    
    if sessionLength > longSessionThreshold then
        self:modifySecurityScore(self.settings.security.securityScore.longSessionPenalty or -2)
    end
    
    self.sessionData.currentPCId = nil
end

function securityManager:modifySecurityScore(amount)
    local maxScore = self.settings.security.securityScore.maxScore or 100
    self.exportData.securityScore = math.max(0, math.min(maxScore, self.exportData.securityScore + amount))
end

function securityManager:getSecurityScore()
    return self.exportData.securityScore
end

function securityManager:scheduleHackAttempt()
    self.exportData.hackAttemptsPending = self.exportData.hackAttemptsPending + 1
end

function securityManager:checkForHack(portfolioValue)
    if not self.settings.security.hackingRisk.enabled then return nil end
    if self.exportData.hackAttemptsPending <= 0 then return nil end
    
    local minValue = self.settings.security.hackingRisk.minPortfolioValueToHack or 10000
    if portfolioValue < minValue then return nil end
    
    local baseChance = self.settings.security.hackingRisk.baseHackChance or 0.15
    local maxChance = self.settings.security.hackingRisk.maxHackChance or 0.50
    
    local securityMultiplier = 1 - (self.exportData.securityScore / 100) * 0.5
    local hackChance = math.min(maxChance, baseChance * securityMultiplier * self.exportData.hackAttemptsPending)
    
    local roll = math.random()
    
    if roll < hackChance then
        self.exportData.hackAttemptsPending = 0
        self.exportData.lastHackCheck = os.time()
        return self:determineHackSeverity()
    else
        self.exportData.hackAttemptsPending = math.max(0, self.exportData.hackAttemptsPending - 1)
        self.exportData.lastHackCheck = os.time()
        return nil
    end
end

function securityManager:determineHackSeverity()
    local severity = self.settings.security.hackingRisk.hackSeverity
    local roll = math.random()
    
    if roll < severity.catastrophic.chance then
        return {
            severity = "catastrophic",
            lossPercent = severity.catastrophic.portfolioLossPercent
        }
    elseif roll < severity.catastrophic.chance + severity.major.chance then
        return {
            severity = "major",
            lossPercent = severity.major.portfolioLossPercent
        }
    else
        return {
            severity = "minor",
            lossPercent = severity.minor.portfolioLossPercent
        }
    end
end

function securityManager:purchaseInsurance(tier)
    if not self.settings or not self.settings.insurance or not self.settings.insurance.enabled then 
        return false, "Insurance not available" 
    end
    
    if not self.settings.insurance.cpicInsurance or not self.settings.insurance.cpicInsurance.tiers then
        return false, "Insurance configuration error"
    end
    
    local tierData = self.settings.insurance.cpicInsurance.tiers[tier]
    if not tierData then return false, "Invalid insurance tier" end
    
    local currentTier = self.exportData.insuranceTier or "none"
    
    -- Already on this tier - don't double charge
    if currentTier == tier then
        return false, "Already subscribed to this plan"
    end
    
    local success, currentMoney = pcall(function()
        return Game.GetTransactionSystem():GetItemQuantity(GetPlayer(), MarketSystem.Money())
    end)
    
    if not success or not currentMoney then
        return false, "Unable to check funds"
    end
    
    -- Calculate cost based on upgrade/downgrade/new purchase
    local costToCharge = tierData.monthlyPremium
    local isUpgrade = false
    local isDowngrade = false
    
    local tierOrder = { none = 0, basic = 1, standard = 2, premium = 3, platinum = 4 }
    local currentRank = tierOrder[currentTier] or 0
    local newRank = tierOrder[tier] or 0
    
    if currentRank > 0 and newRank > currentRank then
        -- Upgrading: charge difference
        isUpgrade = true
        local currentTierData = self.settings.insurance.cpicInsurance.tiers[currentTier]
        if currentTierData then
            costToCharge = tierData.monthlyPremium - currentTierData.monthlyPremium
            -- Don't charge negative
            if costToCharge < 0 then costToCharge = 0 end
        end
    elseif currentRank > 0 and newRank < currentRank then
        -- Downgrading: no charge, switch immediately
        isDowngrade = true
        costToCharge = 0
    end
    
    if costToCharge > 0 and currentMoney < costToCharge then
        return false, "Insufficient funds"
    end
    
    if costToCharge > 0 then
        local spendSuccess = pcall(function()
            utils.spendMoney(costToCharge)
        end)
        
        if not spendSuccess then
            return false, "Transaction failed"
        end
    end
    
    self.exportData.insuranceTier = tier
    
    -- Only reset dates for new purchases, not upgrades/downgrades
    if currentRank == 0 then
        self.exportData.insuranceStartDate = os.time()
        self.exportData.lastPremiumPaid = os.time()
    end
    
    local actionType = isUpgrade and "Upgraded to" or (isDowngrade and "Downgraded to" or "Purchased")
    return true, actionType .. ": " .. tierData.name
end

function securityManager:cancelInsurance()
    self.exportData.insuranceTier = "none"
    self.exportData.insuranceStartDate = 0
    return true, "Insurance cancelled"
end

function securityManager:getInsuranceTier()
    return self.exportData.insuranceTier
end

function securityManager:getInsuranceData()
    local tier = self.exportData.insuranceTier
    if tier == "none" or not self.settings.insurance.cpicInsurance.tiers[tier] then
        return nil
    end
    return self.settings.insurance.cpicInsurance.tiers[tier]
end

function securityManager:calculateInsurancePayout(portfolioValueLost)
    local tierData = self:getInsuranceData()
    if not tierData then return 0 end
    
    local basePayout = portfolioValueLost * tierData.coveragePercent
    
    local minMultiplier = self.settings.insurance.cpicInsurance.payoutCalculation.minSecurityScoreMultiplier or 0.5
    local maxMultiplier = self.settings.insurance.cpicInsurance.payoutCalculation.maxSecurityScoreMultiplier or 1.0
    
    local scorePercent = self.exportData.securityScore / 100
    local securityMultiplier = minMultiplier + (maxMultiplier - minMultiplier) * scorePercent
    
    local adjustedPayout = basePayout * securityMultiplier
    local finalPayout = math.min(adjustedPayout, tierData.maxPayout)
    
    return math.floor(finalPayout)
end

function securityManager:processHackEvent(hack, portfolioValue)
    if not hack then return nil end
    
    local amountLost = math.floor(portfolioValue * hack.lossPercent)
    local insurancePayout = self:calculateInsurancePayout(amountLost)
    
    local netLoss = amountLost - insurancePayout
    
    if insurancePayout > 0 then
        Game.AddToInventory("Items.money", insurancePayout)
        
        table.insert(self.exportData.claimHistory, {
            date = os.time(),
            amountLost = amountLost,
            payout = insurancePayout,
            severity = hack.severity
        })
        self.exportData.lastClaimDate = os.time()
    end
    
    return {
        severity = hack.severity,
        amountLost = amountLost,
        insurancePayout = insurancePayout,
        netLoss = netLoss,
        securityScore = self.exportData.securityScore
    }
end

function securityManager:checkPremiumDue()
    if self.exportData.insuranceTier == "none" then return false end
    
    local daysSincePayment = (os.time() - self.exportData.lastPremiumPaid) / 86400
    return daysSincePayment >= 30
end

function securityManager:payPremium()
    local tierData = self:getInsuranceData()
    if not tierData then return false, "No active insurance" end
    
    local currentMoney = Game.GetTransactionSystem():GetItemQuantity(GetPlayer(), MarketSystem.Money())
    if currentMoney < tierData.monthlyPremium then
        self:cancelInsurance()
        return false, "Insurance cancelled - insufficient funds"
    end
    
    utils.spendMoney(tierData.monthlyPremium)
    self.exportData.lastPremiumPaid = os.time()
    
    return true, "Premium paid: " .. tierData.monthlyPremium .. " E$"
end

function securityManager:getSecurityReport()
    return {
        score = self.exportData.securityScore,
        tier = self.exportData.insuranceTier,
        consecutiveSecure = self.exportData.consecutiveSecureLogins,
        insecureLogouts = self.exportData.insecureLogoutCount,
        totalLogins = self.exportData.totalLogins,
        pendingThreats = self.exportData.hackAttemptsPending,
        successfulTrades = self.exportData.successfulTrades or 0,
        newsReads = self.exportData.newsReads or 0,
        portfolioChecks = self.exportData.portfolioChecks or 0
    }
end

-- ============================================
-- TRADING SCORE FACTORS
-- ============================================

function securityManager:onSuccessfulTrade(tradeAmount)
    local cfg = self.settings.security.securityScore
    local currentTime = os.time()
    
    self.exportData.successfulTrades = (self.exportData.successfulTrades or 0) + 1
    
    -- Bonus for successful trade
    self:modifySecurityScore(cfg.successfulTradeBonus or 2)
    
    -- Penalty for large trades (suspicious activity)
    if tradeAmount >= (cfg.largeTradeThreshold or 100000) then
        self:modifySecurityScore(cfg.largeTradePenalty or -5)
        self.exportData.largeTradeCount = (self.exportData.largeTradeCount or 0) + 1
    end
    
    -- Penalty for rapid trading (within 30 seconds of last trade)
    local timeSinceLastTrade = currentTime - (self.exportData.lastTradeTime or 0)
    if timeSinceLastTrade < (cfg.rapidTradingWindowSeconds or 30) and self.exportData.lastTradeTime > 0 then
        self:modifySecurityScore(cfg.rapidTradingPenalty or -8)
        self.exportData.suspiciousActivityCount = (self.exportData.suspiciousActivityCount or 0) + 1
    end
    
    -- Penalty for night trading (suspicious hours 2AM-5AM game time)
    if self:isNightTime() then
        self:modifySecurityScore(cfg.nightTradingPenalty or -4)
    end
    
    self.exportData.lastTradeTime = currentTime
end

function securityManager:onFailedTrade()
    local cfg = self.settings.security.securityScore
    self.exportData.failedTrades = (self.exportData.failedTrades or 0) + 1
    self:modifySecurityScore(cfg.failedTradePenalty or -3)
end

-- ============================================
-- PORTFOLIO SCORE FACTORS
-- ============================================

function securityManager:onPortfolioCheck(stockCount, totalValue)
    local cfg = self.settings.security.securityScore
    local currentTime = os.time()
    local cooldown = (cfg.portfolioCheckCooldownMinutes or 5) * 60
    
    -- Only award bonus if cooldown has passed
    if currentTime - (self.exportData.lastPortfolioCheck or 0) >= cooldown then
        self:modifySecurityScore(cfg.portfolioCheckBonus or 1)
        self.exportData.portfolioChecks = (self.exportData.portfolioChecks or 0) + 1
        self.exportData.lastPortfolioCheck = currentTime
    end
    
    -- Bonus for diversified portfolio (owning 5+ different stocks)
    local maxDivBonuses = cfg.maxDiversificationBonuses or 3
    if stockCount >= (cfg.diversificationThreshold or 5) then
        if (self.exportData.diversificationBonus or 0) < maxDivBonuses then
            self:modifySecurityScore(cfg.diversifiedPortfolioBonus or 5)
            self.exportData.diversificationBonus = (self.exportData.diversificationBonus or 0) + 1
        end
    end
    
    -- Penalty for high-value target (large portfolio attracts hackers)
    if totalValue >= (cfg.highValueThreshold or 500000) then
        self:modifySecurityScore(cfg.highValueTargetPenalty or -5)
    end
end

function securityManager:onConcentratedPortfolio()
    -- Called when player has all money in one stock
    local cfg = self.settings.security.securityScore
    self:modifySecurityScore(cfg.concentratedPortfolioPenalty or -10)
end

function securityManager:onAllInOne()
    -- Called when player puts everything in one stock
    local cfg = self.settings.security.securityScore
    self:modifySecurityScore(cfg.allInOnePenalty or -15)
    self.exportData.suspiciousActivityCount = (self.exportData.suspiciousActivityCount or 0) + 1
end

-- ============================================
-- NEWS READING SCORE FACTORS  
-- ============================================

function securityManager:onNewsRead()
    local cfg = self.settings.security.securityScore
    local currentTime = os.time()
    local cooldown = (cfg.newsReadCooldownMinutes or 2) * 60
    
    -- Only award bonus if cooldown has passed
    if currentTime - (self.exportData.lastNewsRead or 0) >= cooldown then
        self:modifySecurityScore(cfg.newsReadBonus or 1)
        self.exportData.newsReads = (self.exportData.newsReads or 0) + 1
        self.exportData.lastNewsRead = currentTime
    end
end

-- ============================================
-- INSURANCE SCORE FACTORS
-- ============================================

function securityManager:checkInsuranceBonus()
    local cfg = self.settings.security.securityScore
    
    -- Bonus for having active insurance (responsible behavior)
    if self.exportData.insuranceTier ~= "none" then
        self:modifySecurityScore(cfg.hasInsuranceBonus or 3)
        return true
    end
    return false
end

-- ============================================
-- TIME-BASED SCORE FACTORS
-- ============================================

function securityManager:isNightTime()
    local cfg = self.settings.security.securityScore
    local success, gameTime = pcall(function()
        return Game.GetTimeSystem():GetGameTime()
    end)
    
    if not success or not gameTime then return false end
    
    local hour = gameTime:Hours()
    local nightStart = cfg.nightStartHour or 2
    local nightEnd = cfg.nightEndHour or 5
    
    return hour >= nightStart and hour < nightEnd
end

function securityManager:checkIdleSession()
    if not self.sessionData.isLoggedIn then return end
    
    local cfg = self.settings.security.securityScore
    local sessionLength = os.time() - self.sessionData.loginTime
    local idleThreshold = (cfg.idleThresholdMinutes or 15) * 60
    
    -- Penalty for idle session (potential security risk)
    if sessionLength > idleThreshold then
        self:modifySecurityScore(cfg.idleSessionPenalty or -1)
    end
end

-- ============================================
-- BEHAVIOR & RECOVERY SCORE FACTORS
-- ============================================

function securityManager:checkFrequentLogin()
    local cfg = self.settings.security.securityScore
    local daysBetweenLogins = (os.time() - (self.exportData.lastLoginTime or 0)) / 86400
    
    -- Bonus for logging in frequently (within 3 days)
    if daysBetweenLogins <= (cfg.frequentLoginDays or 3) and self.exportData.lastLoginTime > 0 then
        self:modifySecurityScore(cfg.frequentLoginBonus or 2)
        return true
    end
    return false
end

function securityManager:checkCleanRecord()
    local cfg = self.settings.security.securityScore
    local daysSinceHack = 999999
    
    if self.exportData.lastClaimDate and self.exportData.lastClaimDate > 0 then
        daysSinceHack = (os.time() - self.exportData.lastClaimDate) / 86400
    end
    
    -- Bonus for clean record (no hacks in X days)
    if daysSinceHack >= (cfg.cleanRecordDays or 7) then
        self:modifySecurityScore(cfg.cleanRecordBonus or 5)
        return true
    end
    return false
end

function securityManager:onHackSurvived()
    -- Called when a hack attempt was blocked
    local cfg = self.settings.security.securityScore
    self:modifySecurityScore(cfg.hackSurvivorBonus or 3)
end

-- ============================================
-- SUSPICIOUS ACTIVITY TRACKING
-- ============================================

function securityManager:flagSuspiciousActivity(reason)
    self.exportData.suspiciousActivityCount = (self.exportData.suspiciousActivityCount or 0) + 1
    
    -- Every 3 suspicious activities increases hack risk
    if self.exportData.suspiciousActivityCount % 3 == 0 then
        self:scheduleHackAttempt()
    end
end

function securityManager:getSuspiciousActivityCount()
    return self.exportData.suspiciousActivityCount or 0
end

-- ============================================
-- PERIODIC CHECK (call from Cron)
-- ============================================

function securityManager:periodicSecurityCheck()
    if not self.sessionData.isLoggedIn then return end
    
    self:checkIdleSession()
    self:checkInsuranceBonus()
end

return securityManager
