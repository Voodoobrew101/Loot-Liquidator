local ADDON, LA = ...
LA = LA or {}
LA.version = "0.10.0-alpha4"
LA.targetInterface = 120105  -- Current Retail 12.1.5 compatibility target; NOT in-game QA

local COPPER_PER_GOLD = 10000
local floor, max, min = math.floor, math.max, math.min
-- Tests loading Core.lua in isolation may not have the optional item-rule module.
local function Ignored(self,id,method)
    return self.IsIgnoredAction and self:IsIgnoredAction(id,method) or false
end
local defaults = {
    enabled = true, collectTokenResearch = true,
    -- External integrations are opt-in to their own runtime dependencies.
    -- Tooltip visibility toggles never change the underlying calculations.
    enableTSMIntegration = true, enableATTIntegration = true,
    showTSMIntegrationDetails = true, showATTTooltipDetails = true, showATTTokenSummary = true,
    showATTTokenDEQuotes = true,
    showTooltips = true, showBetterBags = true, showGuildBank = true, showBlizzardBags = true,
    showBadges = true, showFallback = true, showProfessionHints = false,
    processingModes = {}, -- T/D/M/P/S/C/R/X: 1 Force on, 2 Auto, 3 Off, 4 Manual
    showAltHints = false, showSkillDetails = false, showUnknownBadge = true,
    showDisenchantStatus = false,
    showSoulboundVendorBadge = false,
    recordDisenchants = true, showDisenchantSamples = true,
    recordConversions = true, showProcessingSamples = true,
    showMaterialBreakdown = true, showResearchDetails = false, showExternalRates = false,
    disenchantDataMode = 1, millingDataMode = 1, prospectingDataMode = 1,
    otherConversionDataMode = 1, minPersonalSamples = 30,
    researchSkillTolerance = 10, materialPriceDisplay = 3,
    skillAwareProcessing = true, processingFallbackMode = 1,
    -- Midnight prospecting baseline by default; upgrade is manual/estimated,
    -- not inferred from profession skill, specialization or output quality.
    midnightProspectingUpgradePct = 0,
    midnightDiamondCopper = false, midnightDiamondTin = false,
    midnightDiamondSilver = false, midnightDiamondThorium = false,
    -- Independent Dragonflight fallback. Historical TSM rates are provisional
    -- yield references, NOT guaranteed no-skill measurements.
    dragonflightProspectingUpgradePct = 0,
    dragonflightProspectingOutputRank = 0,
    dragonflightProspectingInspirationPct = 0,
    dragonflightProspectingInspirationCrossesThreshold = false,
    dragonflightProspectingResourcefulnessPct = 0,
    dragonflightProspectingPrismaticUnlocked = false,
    warWithinProspectingUpgradePct = 0,
    dragonflightMillingUpgradePct = 0, warWithinMillingUpgradePct = 0,
    warWithinMillingOutputRank = 0,
    midnightMillingUpgradePct = 0,
    dragonflightDisenchantUpgradePct = 0, warWithinDisenchantUpgradePct = 0,
    midnightDisenchantUpgradePct = 0,
    tooltipDetail = 2, tooltipAuction = true, tooltipVendor = true,
    tooltipShowAfterAHCut = true,
    showUnavailableConversions = true,
    methodEnabledD=true,methodEnabledM=true,methodEnabledP=true,
    methodEnabledS=true,methodEnabledC=true,methodEnabledR=true,
    methodEnabledX=true, manualMilling=false,manualProspecting=false,
    manualSmelting=false,manualDisenchanting=false,
    enableLearnedRecipeDiscovery = true, includeVerifiedAlts = true,
    minConversionExtraGold = 0, minReagentProfitGold = 0, minGearProfitGold = 0,
    appearance = { position="TOPRIGHT", fontSize=14, colors={} }, characters = {},
    allowEnchantingAlt = false, allowMilling = false, allowProspecting = false,
    allowSmelting = false, allowExchanges = true,
    -- A hard floor per bag stack, not per reagent. Equipment needs higher profit.
    minGearProfit = 100 * COPPER_PER_GOLD,
    minReagentProfit = 2 * COPPER_PER_GOLD,
    minConversionExtra = 5 * COPPER_PER_GOLD,
    reagentMatchLowest = true,
    tsmGearOperation = "@assigned", tsmReagentOperation = "@assigned",
    tsmFallbackOperation = "@none",
    auctionFee = 0.05,
    -- A heuristic for repeat-post deposit loss. NOT a live Blizzard deposit quote.
    depositBufferMultiplier = 1.0,
    reportLimit = 300,
    missing = {}, ignoredItems = {},
}

local cache = {}
local cacheUntil = 0

-- The existing AH-fee setting controls BOTH prices and recommendations.
-- Keep the SavedVariables key so players retain their existing preference.
-- Default ON for new installs and older databases without the setting.
function LA:AHFeeRate()
    if self.db and self.db.tooltipShowAfterAHCut == false then return 0 end
    return (self.db and self.db.auctionFee) or 0.05
end

local function Positive(n)
    return type(n) == "number" and n > 0 and n < math.huge and n or nil
end

function LA:Money(n)
    if not n or n <= 0 then return "0g" end
    if GetMoneyString then return GetMoneyString(floor(n), true) end
    return ("%.2fg"):format(n / COPPER_PER_GOLD)
end

function LA:TSMString(link, itemID)
    if TSM_API and type(TSM_API.ToItemString) == "function" and link then
        local ok, value = pcall(TSM_API.ToItemString, link)
        if ok and type(value) == "string" and value ~= "" then return value end
    end
    return itemID and ("i:%d"):format(itemID) or nil
end

function LA:Price(source, itemString)
    if self.db and self.db.enableTSMIntegration==false then return nil end
    if not itemString or not TSM_API or type(TSM_API.GetCustomPriceValue) ~= "function" then return nil end
    local ok, value = pcall(TSM_API.GetCustomPriceValue, source, itemString)
    return ok and Positive(value) or nil
end

function LA:GetItemFacts(link, context)
    if not link then return nil end
    local itemID = (C_Item and C_Item.GetItemInfoInstant and C_Item.GetItemInfoInstant(link))
        or (GetItemInfoInstant and GetItemInfoInstant(link))
    if not itemID then return nil end
    local fn = C_Item and C_Item.GetItemInfo or GetItemInfo
    if type(fn) ~= "function" then return nil end
    local name, _, quality, baseLevel, _, _, _, _, equipLoc, _, sell, classID, subClassID, bindType, expansionID = fn(link)
    if not classID then
        local instant=C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
        if instant then classID,subClassID=select(6,instant(link)) end
    end
    local actualLevel = (C_Item and C_Item.GetDetailedItemLevelInfo and C_Item.GetDetailedItemLevelInfo(link))
        or (GetDetailedItemLevelInfo and GetDetailedItemLevelInfo(link)) or baseLevel
    local f = {
        expansionID = expansionID, itemLevel = actualLevel, equipLoc = equipLoc,
        id = itemID, link = link, name = name or ("Item " .. itemID),
        quality = quality, classID = classID, subClassID = subClassID,
        vendor = sell or 0, bindType = bindType, context = context or {},
        count = max(1, tonumber(context and context.count) or 1),
    }
    -- For reagent tooltips, prefer the total quantity carried in bags; a
    -- single BetterBags button can represent just one stack of several.
    -- Does not include bank/alt quantities. The number shown is labeled 'in bags'.
    if f.classID==7 and not f.context.guild and type(GetItemCount)=="function" then
        local ok,n=pcall(GetItemCount,f.id,false,false)
        if ok and type(n)=="number" and n>f.count then
            f.count=n
            f.countScope="bags"
        end
    end
    local qualityAPI=C_TradeSkillUI and C_TradeSkillUI.GetItemReagentQualityByItemInfo
    if qualityAPI then
        local ok,rank=pcall(qualityAPI,link)
        if ok and type(rank)=="number" and rank>0 then f.reagentQuality=rank end
    end
    f.tsmString = self:TSMString(link, itemID)
    return f
end

-- Item quality/rarity alone cannot establish disenchant eligibility.
-- Blizzard can mark individual equipment items "Cannot be disenchanted".
-- Check native tooltip DATA (never a tooltip we appended to) so TSM Destroy
-- estimates and research tables cannot override a confirmed restriction.
-- The localized game string is ITEM_DISENCHANT_NOT_DISENCHANTABLE; use the
-- English fallback only when the constant isn't exposed by the client.
local function IsNotDisenchantableTooltipLine(text)
    if type(text) ~= "string" or (issecretvalue and issecretvalue(text)) then return false end
    local localized = ITEM_DISENCHANT_NOT_DISENCHANTABLE
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    -- Do not depend on global-string availability. The English fallback is
    -- useful for current enUS clients; localized text remains authoritative.
    return (type(localized)=="string" and localized~=""
            and text:find(localized,1,true) ~= nil)
        or text:find("Cannot be disenchanted",1,true) ~= nil
end

-- Tooltip-data fields can be secret in Retail. Restriction detection must
-- never crash on such fields or require the tooltip to be printable.
function LA:TooltipDataSaysNoDisenchant(data)
    if type(data) ~= "table" or (issecretvalue and issecretvalue(data))
        or type(data.lines) ~= "table" then return false end
    for _,line in ipairs(data.lines) do
        if type(line)=="table" and not (issecretvalue and issecretvalue(line))
            and (IsNotDisenchantableTooltipLine(line.leftText)
                or IsNotDisenchantableTooltipLine(line.rightText)) then
            return true
        end
    end
    return false
end

-- Some Blizzard tooltip decorators show "Cannot be disenchanted" on the
-- rendered GameTooltip even when C_TooltipInfo.GetHyperlink omitted the line.
-- Only examine the tooltip currently being displayed, not an unrelated UI
-- element. This is a lightweight fallback on mouseover, not on bag repaint.
function LA:RenderedTooltipSaysNoDisenchant(tooltip)
    if not tooltip or type(tooltip.GetName)~="function"
        or type(tooltip.NumLines)~="function" then return false end
    local ok,name=pcall(tooltip.GetName,tooltip)
    if not ok or type(name)~="string" or name=="" then return false end
    local countOK,count=pcall(tooltip.NumLines,tooltip)
    if not countOK or type(count)~="number" then return false end
    for i=1,math.min(count,80) do
        for _,side in ipairs({"Left","Right"}) do
            local fs=_G and _G[name.."Text"..side..i]
            if fs and type(fs.GetText)=="function" then
                local textOK,value=pcall(fs.GetText,fs)
                if textOK and IsNotDisenchantableTooltipLine(value) then return true end
            end
        end
    end
    return false
end

-- Reconcile our cached bag recommendation against the tooltip Blizzard
-- actually displayed. This catches dynamic warning lines added after the
-- C_TooltipInfo data was constructed. Do NOT permanently store these inferred
-- results in SavedVariables: an equipped/bag item's instance may differ.
function LA:ObserveVisibleDisenchantRestriction(link,data,tooltip)
    if type(link)~="string" or link=="" then return false end
    local itemID=tonumber(link:match("item:(%d+)"))
    if type(data)=="table" and type(data.id)=="number" and itemID
        and data.id~=itemID then return false end
    if not (self:TooltipDataSaysNoDisenchant(data)
        or self:RenderedTooltipSaysNoDisenchant(tooltip)) then return false end
    self._observedNoDisenchantLinks=self._observedNoDisenchantLinks or {}
    if not self._observedNoDisenchantLinks[link] then
        self._observedNoDisenchantLinks[link]=true
        if self.Invalidate then self:Invalidate() end
    end
    return true
end

function LA:NativeDisenchantRestriction(f)
    if not f or not f.link or not C_TooltipInfo then return false end
    -- Tooltip-data scans can be expensive when bag addons repaint hundreds of
    -- slots. Cache per item LINK and bag slot, not item ID (different instances
    -- may carry different restrictions). Negative scans are short-lived.
    local context=f.context or {}
    local cacheKey=tostring(f.link)..":"..tostring(context.bagID)..":"..tostring(context.slotID)
    local now=(GetTime and GetTime()) or 0
    self._deRestrictionCache=self._deRestrictionCache or {}
    local previous=self._deRestrictionCache[cacheKey]
    if previous and now-previous.at < (previous.blocked and 60 or 5) then
        return previous.blocked
    end
    local function ContainsRestriction(data)
        if type(data) ~= "table" or (issecretvalue and issecretvalue(data)) then return false end
        -- A bag slot can be rebound while its tooltip is being evaluated.
        if type(data.id) == "number" and not (issecretvalue and issecretvalue(data.id))
            and data.id ~= f.id then return false end
        return self:TooltipDataSaysNoDisenchant(data)
    end
    local blocked=false
    if type(context.bagID)=="number" and type(context.slotID)=="number"
        and type(C_TooltipInfo.GetBagItem)=="function" then
        local ok,data=pcall(C_TooltipInfo.GetBagItem,context.bagID,context.slotID)
        if ok and ContainsRestriction(data) then blocked=true end
    end
    -- Also works on ordinary item links and items outside the character bags.
    if not blocked and type(C_TooltipInfo.GetHyperlink)=="function" then
        local ok,data=pcall(C_TooltipInfo.GetHyperlink,f.link)
        if ok and ContainsRestriction(data) then blocked=true end
    end
    if not blocked and type(C_TooltipInfo.GetItemByID)=="function" then
        local ok,data=pcall(C_TooltipInfo.GetItemByID,f.id)
        if ok and ContainsRestriction(data) then blocked=true end
    end
    -- An unreadable tooltip is UNKNOWN, not proof that DE is permitted.
    self._deRestrictionCache[cacheKey]={at=now,blocked=blocked}
    return blocked
end

-- Being soulbound or Warbound does NOT mean equipment is impossible to
-- disenchant. Binding is relevant to auction eligibility, not the DE table.
-- This is a candidate filter, not a guarantee the Enchanting spell accepts it.
function LA:DisenchantEligibility(f)
    if f and f._deEligibilityChecked then
        return f._deEligible,f._deEligibilityReason
    end
    local function Verdict(eligible,reason)
        if f then
            f._deEligibilityChecked=true
            f._deEligible=eligible
            f._deEligibilityReason=reason
            f.disenchantBlocked=(not eligible and
                (reason=="Blizzard: Cannot be disenchanted" 
                    or reason=="Item database: Cannot be disenchanted"
                    or reason=="Displayed tooltip: Cannot be disenchanted"))
        end
        return eligible,reason
    end
    -- Tokens can be item-class Miscellaneous; classify them by known token ID
    -- before checking ordinary equipment. Never apply armor DE rates to tokens.
    if f and (self.ATTTokenInfo and self:ATTTokenInfo(f)) then
        return Verdict(false, "Equipment token: identify redemption/reward before valuing disenchant")
    end
    if not f or not (f.classID == 2 or f.classID == 4) then
        return Verdict(false, "Not a weapon or armor item")
    end
    if not f.quality or f.quality < 2 or f.quality > 4 then
        return Verdict(false, "Quality outside the normal disenchant range")
    end
    if f.bindType == 4 or (f.context and f.context.isQuest) then
        return Verdict(false, "Quest item")
    end
    if not f.equipLoc or f.equipLoc == "" or f.equipLoc == "INVTYPE_BODY"
        or f.equipLoc == "INVTYPE_TABARD" then
        return Verdict(false, "Not ordinary equippable gear")
    end
    if self.ExternalDisenchantRestriction and self:ExternalDisenchantRestriction(f.id) then
        return Verdict(false, "Item database: Cannot be disenchanted")
    end
    if self._observedNoDisenchantLinks and self._observedNoDisenchantLinks[f.link] then
        return Verdict(false, "Displayed tooltip: Cannot be disenchanted")
    end
    if Ignored(self,f.id,"D") then
        return Verdict(false, "User ignored Disenchant")
    end
    if C_Item and C_Item.IsCosmeticItem then
        local ok, cosmetic = pcall(C_Item.IsCosmeticItem, f.id)
        if ok and cosmetic then return Verdict(false, "Cosmetic item") end
    end
    if self:NativeDisenchantRestriction(f) then
        return Verdict(false,"Blizzard: Cannot be disenchanted")
    end
    return Verdict(true,"Candidate only; the game makes the final eligibility decision")
end
function LA:EligibleDisenchant(f)
    return self:DisenchantEligibility(f)
end

-- Bind-on-pickup gear is known to be bound even without an inventory location,
-- e.g. when an item tooltip opens without an attached bag button.
function LA:IsNonAuctionableByBinding(f)
    if not f then return true end
    local c = f.context or {}
    return c.isBound == true or c.isSoulbound == true or c.isBoundToAccount == true
        or f.bindType == 1 or f.bindType == 4 or f.bindType == 7
        or f.bindType == 8 or f.bindType == 9
end

function LA:CurrentHasEnchanting()
    local key = self.CharacterKey and self:CharacterKey()
    local character = key and self.db.characters and self.db.characters[key]
    if character and character.professions and character.professions.Enchanting then return true end
    -- Snapshot can be missing directly after login. Cache the extra API
    -- probe briefly; don't repeat a profession scan for every item redraw.
    local now = (GetTime and GetTime()) or 0
    if self._enchantCache and self._enchantCache.key==key
        and now-self._enchantCache.at < 15 then
        return self._enchantCache.value
    end
    local found = false
    if type(GetProfessions) == "function" and type(GetProfessionInfo) == "function" then
        local p1,p2,p3,p4,p5 = GetProfessions()
        local slots = {p1,p2,p3,p4,p5}
        for i=1,5 do
            local slot=slots[i]
            if slot then
                local name = GetProfessionInfo(slot)
                if name == "Enchanting" then found=true; break end
            end
        end
    end
    self._enchantCache = {at=now,key=key,value=found}
    return found
end

-- Always resolve expansion BEFORE consulting any disenchant table. Never
-- infer it from character level or equipment ilvl. Do not guess on nil.
function LA:DisenchantExpansion(f)
    local exp = f and f.expansionID
    if type(exp) ~= "number" or exp < 0 or exp > 11 then
        return nil, "Expansion unknown; cannot select disenchant table"
    end
    return exp
end

-- A cached once-per-item-priced-material estimate. It does not modify TSM.
-- For modern gear, unverified reference outputs are NEVER treated as
-- guaranteed 1x gold values. Prefer current local observations, then Game Data.
function LA:DisenchantEstimate(f,character)
    return self:EvaluateDisenchant(f,character)
end

function LA:HasProfessionAccess(method)
    if method == "Exchange" then return self.db.allowExchanges end
    if method == "Smelt" then return self.db.allowSmelting end
    if method == "Mill" then return self.db.allowMilling end
    if method == "Prospect" then return self.db.allowProspecting end
    if method == "Disenchant" then
        if self.db.allowEnchantingAlt then return true end
        return self:CurrentHasEnchanting()
    end
    return false
end

-- The sole BestConversion implementation is ConversionEngine.lua.

function LA:ReportMissing(f)
    if not self.db or not f then return end
    local eligible = self:EligibleDisenchant(f)
    local reagent = f.classID == 7
    if not (eligible or reagent) then return end
    if (self.Conversions and self.Conversions[f.id])
        or (self.ResearchProcessingInputs and self.ResearchProcessingInputs[f.id])
        or (self.DB2Processable and self.DB2Processable[f.id]) then return end
    local dict = self.db.missing
    if not dict[f.id] then
        local total = 0
        for _ in pairs(dict) do total = total + 1 end
        if total >= self.db.reportLimit then return end
        dict[f.id] = {name=f.name, seen=0, classID=f.classID, subClassID=f.subClassID}
    end
    dict[f.id].seen = (dict[f.id].seen or 0) + 1
end

-- Auction candidates respect the first TSM operation's min/normal when present.
-- A is only a recommendation: post cap, duration, and live scan can still block.
function LA:AuctionUnit(f)
    local key=f.tsmString
    -- If an operation was explicitly selected, a missing TSM record is a
    -- hard error. NEVER silently value it using another operation's price.
    if self.ChosenTSMAuctionOperation then
        local op,name,override,reason=self:ChosenTSMAuctionOperation(f)
        if override and not op then return nil,reason or "Selected operation unavailable" end
        if op then
            return self:QuoteTSMAuctionOperation(f,op)
        end
    end
    -- Compatibility fallback for installations exposing only TSM's public
    -- operation price sources. These describe the item's assigned operation.
    local opMin=self:Price("auctioningopmin",key)
    local opNormal=self:Price("auctioningopnormal",key)
    local opMax=self:Price("auctioningopmax",key)
    local low=self:Price("dbminbuyout",key)
    local isGear=f.classID==2 or f.classID==4
    local ask
    if opMin and low and low<opMin then
        return nil,"Competitor below assigned TSM operation minimum"
    end
    if opNormal then
        -- A grouped item should follow its operation, not an unconditional
        -- region average. If competition is within the operation's band, an
        -- approximate match-lowest quote is useful. Actual post price depends
        -- on TSM's posting scan and above-max/below-min operation policies.
        if low and (not opMax or low<=opMax) then ask=low
        else ask=opNormal end
    elseif isGear then
        ask=low or self:Price("dbregionsaleavg",key)
    else
        -- Common reagents: TSM cached lowest listing, then local market,
        -- then regional average. A former "match lowest" toggle was a no-op.
        ask=low or self:Price("dbmarket",key)
            or self:Price("dbregionsaleavg",key)
    end
    if not ask then return nil,"No TSM price" end
    if opMin and ask<opMin then return nil,"Below TSM operation minimum" end
    return ask,nil
end

function LA:AuctionEligible(f)
    if f.context and f.context.isQuest then return false end
    if self:IsNonAuctionableByBinding(f) then return false end
    if C_Item and type(C_Item.IsItemBindToAccountUntilEquip) == "function" then
        local ok, bound = pcall(C_Item.IsItemBindToAccountUntilEquip, f.link)
        if ok and bound == true then return false end
    end
    if C_Item and type(C_Item.IsItemBindToAccount) == "function" then
        local ok, bound = pcall(C_Item.IsItemBindToAccount, f.link)
        if ok and bound == true then return false end
    end
    -- For equipment in bags require explicit per-instance verification.
    if (f.classID == 2 or f.classID == 4)
        and not (f.context and (f.context.guild == true or f.context.verifiedUnbound == true)) then
        return false
    end
    return true
end

local COLORS = {A="|cFFFFFF00", V="|cFFE0E0E0", D="|cFFAA55FF", C="|cFFFF9933",
                M="|cFF33DD66", P="|cFF55AAFF", S="|cFFFF9933", Q="|cFFFF8833"}
LA.Colors = COLORS

function LA:Evaluate(link, context)
    if not self.db or not self.db.enabled then return nil end
    local f = self:GetItemFacts(link, context)
    if not f then return nil end
    if (self.IgnoreEntry and self:IgnoreEntry(f.id)) and Ignored(self,f.id,"A")
        and Ignored(self,f.id,"D") and Ignored(self,f.id,"V")
        and Ignored(self,f.id,"P")
        and (Ignored(self,f.id,"T") or self:IgnoreEntry(f.id).T==nil) then
        return {action=nil,itemID=f.id,facts=f,ignoredAll=true,conversionOptions={}}
    end
    local deAllowed,deReason=self:DisenchantEligibility(f)
    -- Blizzard classifies quest items (12); they are not vendor trash by default.
    -- A missing external token cache must never create a question-mark badge.
    if f.classID==12 or f.bindType==4 or (f.context and f.context.isQuest==true) then
        return {action=nil,itemID=f.id,facts=f,conversionOptions={},questItem=true}
    end
    -- Resolve appearance ownership before caching a decision. Two otherwise
    -- identical items can change status after learning an appearance.
    local collectedAppearance
    if self.AppearanceCollectionState and (f.classID==2 or f.classID==4) then
        collectedAppearance=self:AppearanceCollectionState(f.link)
    end
    local missingDirectAppearance=collectedAppearance==false
    -- ATT's exchange index/item cache may become available after the bag's
    -- first paint. Include its verified token recognition state in the
    -- decision cache key, so an early Vendor choice cannot hide later T rows.
    local tokenInfo=self.ATTTokenInfo and self:ATTTokenInfo(f)
    -- The bag item tooltip may know this INSTANCE is Warbound before the
    -- player hovers it.  Read only the passive Blizzard tooltip data for
    -- positively identified equipment tokens. Otherwise a recipient on a
    -- verified alt stays hidden behind an orange Q until first mouseover.
    -- This must run before building the context-sensitive decision cache key.
    if tokenInfo and self.VerifyTokenWarboundFromBag then
        self:VerifyTokenWarboundFromBag(f)
    end
    -- Caches only until the next explicit refresh; context-specific binding is in key.
    -- A soulbound copy and a warbound copy of the same item ID must NEVER share a result.
    local ignoreFlags=(self.IgnoreEntry and self:IgnoreEntry(f.id))
    local ignoreKey=ignoreFlags and table.concat({tostring(ignoreFlags.A),tostring(ignoreFlags.D),
        tostring(ignoreFlags.V),tostring(ignoreFlags.P),tostring(ignoreFlags.T)},",") or "none"
    local signature = ignoreKey..":"..tostring(self.db.disenchantDataMode)..":" .. tostring(self.db.millingDataMode)..":"
       ..tostring(self.db.prospectingDataMode)..":"..tostring(self.db.otherConversionDataMode)..":"
       ..tostring(self.db.minPersonalSamples)..":"..tostring(self.db.researchSkillTolerance)..":"
       ..tostring(self.db.skillAwareProcessing)..":"..tostring(self.db.processingFallbackMode)..":"
       ..tostring(self.db.midnightProspectingUpgradePct)..":"
       ..tostring(self.db.midnightDiamondCopper)..":"..tostring(self.db.midnightDiamondTin)..":"
       ..tostring(self.db.midnightDiamondSilver)..":"..tostring(self.db.midnightDiamondThorium)..":"
       ..tostring(self.db.dragonflightProspectingUpgradePct)..":"
       ..tostring(self.db.dragonflightProspectingOutputRank)..":"
       ..tostring(self.db.dragonflightProspectingInspirationPct)..":"
       ..tostring(self.db.dragonflightProspectingInspirationCrossesThreshold)..":"
       ..tostring(self.db.dragonflightProspectingResourcefulnessPct)..":"
       ..tostring(self.db.dragonflightProspectingPrismaticUnlocked)..":"..
       tostring(self.db.warWithinProspectingUpgradePct)..":"..
       tostring(self.db.dragonflightMillingUpgradePct)..":"..
       tostring(self.db.warWithinMillingUpgradePct)..":"..
       tostring(self.db.warWithinMillingOutputRank)..":"..
       tostring(self.db.midnightMillingUpgradePct)..":"..
       tostring(self.db.dragonflightDisenchantUpgradePct)..":"..
       tostring(self.db.warWithinDisenchantUpgradePct)..":"..
       tostring(self.db.midnightDisenchantUpgradePct)..":"
       ..tostring(self.db.tooltipShowAfterAHCut)..":"
       ..tostring(f.tsmString) .. ":" .. tostring(f.count) .. ":" ..
       tostring(f.expansionID) .. ":" .. tostring(f.quality) .. ":" .. tostring(f.itemLevel) .. ":"
       .. tostring(f.context.verifiedUnbound) .. ":" .. tostring(f.context.guild)
       .. ":" .. tostring(f.context.isBound) .. ":" .. tostring(f.context.isBoundToAccount)
       .. ":" .. tostring(f.context.isSoulbound) .. ":" .. tostring(f.context.verifiedWarbound)
       .. ":" .. tostring(f.context.bagID) .. ":" .. tostring(f.context.slotID)
       .. ":" .. tostring(deAllowed) .. ":" .. tostring(f.disenchantBlocked)
       .. ":" .. tostring(self.db.tsmGearOperation) .. ":" .. tostring(self.db.tsmReagentOperation)
       .. ":" .. tostring(self.db.tsmFallbackOperation)
       .. ":" .. tostring(self.ATTAvailable and self:ATTAvailable())
       .. ":" .. tostring(tokenInfo and #tokenInfo.rewards or 0)
       .. ":" .. tostring(tokenInfo and tokenInfo.possibleMissingAppearance)
       .. ":" .. tostring(self._altRosterRevision or 0)
       .. ":appearance:" .. tostring(collectedAppearance)
       .. ":transmogMode:" .. tostring(self.ProcessingMethodMode and self:ProcessingMethodMode("T") or 2)
    local now = (GetTime and GetTime()) or 0
    local cached = cache[signature]
    if cached and (now - cached.at) < 30 then return cached.result end

    local conversion = tokenInfo and nil or self:BestConversion(f)
    if tokenInfo then
        conversion = nil
    end
    local vendor = (Ignored(self,f.id,"V") and 0) or (f.vendor or 0)
    local action, fallback, reason = nil, nil, nil
    local isToken = tokenInfo~=nil
    local methodLetter = {Disenchant="D", Mill="M", Prospect="P", Smelt="S", Exchange="C", Craft="C", Combine="C", Split="C"}
    local convertedValue = conversion and conversion.value or 0
    if convertedValue > vendor and conversion
        and (convertedValue - vendor) * f.count > (self.db.minConversionExtraGold or 5) * COPPER_PER_GOLD then
        fallback = methodLetter[conversion.name] or "C"
    elseif vendor > 0 then
        fallback = "V"
    end

    local hasAlternative, hasAvailableDE = false, false
    for _, option in ipairs(f.conversionOptions or {}) do
        if option.available and type(option.value)=="number" and option.value>0 then
            hasAlternative = true
            if option.name=="Disenchant" then hasAvailableDE = true end
        end
    end
    local canAuction = not Ignored(self,f.id,"A") and self:AuctionEligible(f)
    -- Deliberately excluding D for one item is an item-specific request to
    -- compare its REMAINING methods. If Vendor wins on otherwise quiet bound
    -- gear, respect that choice even when the broad soulbound-V setting is off.
    -- This does not enable Vendor when V itself is ignored or worth zero.
    local vendorOptIn = Ignored(self,f.id,"D") and not Ignored(self,f.id,"V")
        and vendor > 0 and not isToken
    -- Do not query or display Auctioning operation errors for soulbound gear.
    local ask, blocked
    if canAuction then ask,blocked = self:AuctionUnit(f) end
    -- A gear token is not itself disenchantable. Its redemption chain must
    -- be verified before a profit recommendation, regardless of material market value.
    if isToken and not canAuction then ask = nil end
    local marketAuction
    if (f.classID==2 or f.classID==4) and not ask
        and not Ignored(self,f.id,"A") then
        marketAuction=self:Price("dbminbuyout",f.tsmString)
            or self:Price("dbmarket",f.tsmString)
            or self:Price("dbregionsaleavg",f.tsmString)
    end
    local fees = self:AHFeeRate()
    local safeGross = ask and ask * (1 - fees) or 0
    local bestLiquidate = max(vendor, convertedValue)
    local minProfit = (f.classID == 2 or f.classID == 4)
        and (self.db.minGearProfitGold or 100) * COPPER_PER_GOLD or (self.db.minReagentProfitGold or 2) * COPPER_PER_GOLD
    -- For equipment, use a conservative heuristic for 48h repeat deposits.
    local vendorDepositBuffer = 0 -- actual AH deposit is not available away from AH; do not fabricate it
    local incremental = (safeGross - bestLiquidate - vendorDepositBuffer) * f.count
    if canAuction and ask and incremental > minProfit then
        action = "A"
        reason = "TSM auction price beats immediate alternatives"
    else
        -- The lower-rank-only result is NOT a measured minimum. If a priced
        -- higher-rank outcome could reverse the vendor decision, admit that
        -- our unverified quality distribution prevents a reliable answer.
        local possible = f.disenchantEstimate
        local higherValue = possible and possible.higherValue
        local deUncertain = hasAvailableDE and higherValue and higherValue > vendor
            and (higherValue-vendor)*f.count > (self.db.minConversionExtraGold or 5) * COPPER_PER_GOLD
            and convertedValue <= vendor + (self.db.minConversionExtraGold or 5) * COPPER_PER_GOLD / f.count
        if conversion and convertedValue > vendor
            and (convertedValue - vendor) * f.count > (self.db.minConversionExtraGold or 5) * COPPER_PER_GOLD then
            action, reason = methodLetter[conversion.name] or "C", "Estimated conversion beats vendoring"
        elseif deUncertain then
            action, reason = "Q", "Disenchant may beat vendoring, but material quality/yield probabilities are unknown"
        elseif vendor > 0 and hasAlternative then
            -- Meaningful V: another verified, priced liquidation METHOD exists,
            -- but vendoring wins based on our available estimates. Do not mark
            -- vendor-only soulbound items that cannot be disenchanted.
            action, reason = "V", "Vendor estimate beats other available conversion methods"
        elseif not Ignored(self,f.id,"D") and self:EligibleDisenchant(f) and f.currentCanDisenchant and f.disenchantIssue then
            action, reason = "Q", "Disenchant: " .. f.disenchantIssue
        elseif isToken then
            action, reason = "Q", "ATT equipment token: possible rewards; quantities and chances unverified"
        elseif not canAuction then
            -- Explicit opt-in lets players see V even on vendor-only soulbound
            -- gear; it does not change D eligibility or invent AH eligibility.
            if vendor > 0 and (self.db.showSoulboundVendorBadge == true or vendorOptIn)
                and self:IsNonAuctionableByBinding(f) and not isToken then
                action, reason = "V", vendorOptIn
                    and "Vendor is the best remaining method (Disenchant ignored for this item)"
                    or "Vendor-only bound item (badge explicitly enabled)"
            else
                action, reason = nil, nil
            end
        elseif not ask and (not blocked or blocked == "No TSM price") then
            action, reason = "Q", "Insufficient Data - missing TSM auction valuation"
        elseif vendor > 0 then
            action, reason = "V", blocked or "Vendor is the dependable fallback"
        else
            action, reason = "Q", blocked or "Insufficient Data - cannot verify a worthwhile action"
        end
    end
    if action and Ignored(self,f.id, action == "Q" and "P" or action) then
        action,reason=nil,nil
    end
    if action == "V" and self:IsNonAuctionableByBinding(f)
        and self.db.showSoulboundVendorBadge ~= true and not vendorOptIn then
        -- Keep conversion math/tooltips intact; only hide the V badge/action.
        action, reason = nil, nil
    end
    -- Collection priority takes precedence over every gold quote, but only
    -- if Blizzard explicitly confirms the VISUAL is absent across all sources.
    -- An unknown source or merely uncollected item instance must not become T.
    local missingAppearance=missingDirectAppearance
    local transmogRecipient
    local collectingEnabled=(not self.ProcessingMethodMode or self:ProcessingMethodMode("T")~=3)
        and not Ignored(self,f.id,"T")
    if missingDirectAppearance and collectingEnabled and not tokenInfo then
        transmogRecipient=self.DirectTransmogRecipient and self:DirectTransmogRecipient(f)
    end
    -- For a class-restricted item, do not mark T based on an alt disabled
    -- by the user or a recipient who cannot legally receive the item.
    if tokenInfo and tokenInfo.possibleMissingAppearance
        and (not self.ProcessingMethodMode or self:ProcessingMethodMode("T")~=3)
        and not Ignored(self,f.id,"T") and self.TokenTransmogRecipient then
        transmogRecipient=self:TokenTransmogRecipient(f,tokenInfo)
        -- ATT's overall reward list can include OTHER classes' gear.
        -- Only a missing appearance usable by this character or a verified
        -- transferable, enabled alt should override the gold comparison.
        if transmogRecipient then missingAppearance=true end
    end
    if missingAppearance and transmogRecipient and collectingEnabled then
        action,reason="T",transmogRecipient and (transmogRecipient.current
            and "Missing appearance usable on current character"
            or "Missing appearance usable on enabled alt "..transmogRecipient.displayName)
            or "Appearance missing from collection (not just this source)"
    end
    -- Unresolved ATT cache entries are not evidence of a token.
    -- Never turn an ordinary quest or miscellaneous item into a Q badge.
    local operationName, operationSimulation
    if canAuction and self.ChosenTSMAuctionOperation then
        local _, name, simulated = self:ChosenTSMAuctionOperation(f)
        operationName, operationSimulation = name, simulated
    end
    -- Only informational estimates for ATT token outputs. Probability and
    -- class-dependent reward selection aren't verified: never rank these.
    local tokenEnchanter=tokenInfo and self.TokenDisenchanter and self:TokenDisenchanter(f)
    local tokenDE=tokenInfo and tokenEnchanter and self.TokenDEQuotes
        and self:TokenDEQuotes(f,tokenInfo,tokenEnchanter)
    local result = { action=action, fallback=(action == "A" and fallback or nil),
        method=conversion and conversion.name, conversion=conversion, vendor=vendor,
        rawAuction=ask, netAuction=safeGross,
        marketAuction=marketAuction, marketAuctionNet=marketAuction and marketAuction*(1-fees) or nil,
        converted=convertedValue,
        auctionDisplayPrice=ask, auctionNetPrice=safeGross,
        auctionOperation=operationName,
        operationSimulation=operationSimulation or false,
        conversionOptions=f.conversionOptions or {},
        why=reason, itemID=f.id, count=f.count, name=f.name,
        priceSource="TSM", blocked=blocked, facts=f,
        deIssue=f.disenchantIssue, deUnavailable=f.unavailableDisenchant,
        deStats=(deAllowed and self.DisenchantStatsFor and self:DisenchantStatsFor(f)) or nil,
        deEstimate=f.disenchantEstimate, canDisenchant=f.currentCanDisenchant,
        disenchantEligible=deAllowed, disenchantRestriction=f.disenchantBlocked and deReason or nil,
        isBound=self:IsNonAuctionableByBinding(f), auctionEligible=canAuction,
        tokenInfo=tokenInfo, tokenEnchanter=tokenEnchanter,tokenDE=tokenDE,
        missingAppearance=missingAppearance, collectedAppearance=collectedAppearance,
        transmogRecipient=transmogRecipient }
    self:ReportMissing(f)
    cache[signature] = {at=now, result=result}
    return result
end

function LA:Invalidate(reason)
    wipe(cache)
    self._processingModelCache=nil
    if reason~="evidence" then
        self._processingContextCache=nil
        self._professionOperationCache=nil
    end
    if self.ClearBadgeDecisionCache then self:ClearBadgeDecisionCache() end
    self._deRestrictionCache = nil
    self._enchantCache = nil
    if self.InvalidateATTCache then self:InvalidateATTCache() end
    if self.RequestBadgeRefresh then self:RequestBadgeRefresh() end
    if self.QueueBlizzardBagRefresh then self:QueueBlizzardBagRefresh() end
    if self.QueueGuildRefresh then self:QueueGuildRefresh() end
end

function LA:MakeReport()
    local lines = {"itemID,name,classID,subClassID,observations,wowhead_url"}
    local ids = {}
    for id in pairs(self.db.missing or {}) do ids[#ids+1] = id end
    table.sort(ids)
    for _, id in ipairs(ids) do
        local r = self.db.missing[id]
        local name = tostring(r.name or ""):gsub('"','""')
        lines[#lines+1] = ("%d,\"%s\",%s,%s,%d,https://www.wowhead.com/item=%d"):format(
            id, name, tostring(r.classID or ""), tostring(r.subClassID or ""), r.seen or 0, id)
    end
    return table.concat(lines, "\n")
end

function LA:ShowCopy(title, contents)
    if not self.copyDialog then
        local f = CreateFrame("Frame", "LootLiquidatorCopyDialog", UIParent, "BasicFrameTemplateWithInset")
        f:SetSize(720, 450); f:SetPoint("CENTER"); f:SetMovable(true)
        f:EnableMouse(true); f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        local sf = CreateFrame("ScrollFrame", nil, f, "ScrollFrameTemplate")
        sf:SetPoint("TOPLEFT", 12, -32); sf:SetPoint("BOTTOMRIGHT", -30, 12)
        local edit = self:CreateSettingsEditBox(sf)
        edit:SetMultiLine(true); edit:SetAutoFocus(false); edit:SetFontObject(ChatFontNormal)
        edit:SetWidth(650); edit:SetHeight(400)
        edit:SetScript("OnEscapePressed", function() f:Hide() end)
        sf:SetScrollChild(edit)
        f.edit = edit
        self.copyDialog = f
    end
    self.copyDialog.TitleText:SetText(title)
    self.copyDialog.edit:SetText(contents)
    self.copyDialog.edit:SetFocus()
    self.copyDialog.edit:HighlightText()
    self.copyDialog:Show()
end

local function Say(s) print("|cff66ccffLoot Liquidator|r: " .. s) end
local function Command(msg)
    local command, arg = msg:lower():match("^(%S*)%s*(%S*)")
    if command == "settings" or command == "config" then
        if LA.OpenSettings then LA:OpenSettings() end
    elseif command == "processingdebug" then
        if arg=="show" then
            local d=LA.processingDebug
            LA:ShowCopy("Live Processing Diagnostic",d and d.lines and table.concat(d.lines,"\n") or "No capture yet. Run /ll processingdebug start, then re-hover a milling/prospecting item.")
        elseif arg=="clear" then
            LA.processingDebug=nil
            Say("Processing diagnostic cleared")
        else
            LA.processingDebug={armed=true,done=false,lines={}}
            Say("LIVE diagnostic ARMED. Move the cursor away and re-hover one ore/herb; then /ll processingdebug show")
        end
    elseif command == "dbstatus" then
        local restrictions,inputs=0,0
        for _ in pairs(LA.ItemRestrictions or {}) do restrictions=restrictions+1 end
        for _ in pairs(LA.DB2Processable or {}) do inputs=inputs+1 end
        Say(("Item database: %s; %d restricted IDs, %d processing input hints. Missing IDs are NOT assumed disenchantable."):format(
            tostring(LA.ItemRestrictionsBuild or "no snapshot"), restrictions,inputs))
    elseif command == "ignore" or command == "unignore" then
        local id=tonumber(tostring(arg or ""):match("item:(%d+)")) or tonumber(arg)
        if not id then Say("Usage: /ll ignore 12345 or /ll unignore 12345")
        elseif not LA.SetIgnoreEntry then Say("Ignore module unavailable")
        else
            if command=="ignore" then
                LA:SetIgnoreEntry(id,{A=true,D=true,V=true,P=true})
                Say("Ignored Auction, Disenchant, Vendor and Processing for item "..id)
            else
                LA:SetIgnoreEntry(id,nil)
                Say("Removed item "..id.." from ignore list")
            end
        end
    elseif command == "report" then
        LA:ShowCopy("Missing Conversion Report", LA:MakeReport())
    elseif command == "clearreport" then
        LA.db.missing = {}
        Say("Missing conversion report cleared.")
    elseif command == "refresh" then
        LA:Invalidate(); Say("Price cache cleared; requested bag and guild-bank badge refresh.")
    elseif command == "tsmops" then
        local names,reason=LA:GetAuctionOperationNames()
        if #names==0 then Say("No TSM Auctioning operations: "..tostring(reason or "none found"))
        else Say("TSM Auctioning operations: "..table.concat(names,", ")) end
    elseif command == "enchanting" or command == "milling"
        or command == "prospecting" or command == "smelting"
        or command == "exchanges" then
        local key = ({enchanting="allowEnchantingAlt",milling="allowMilling",
            prospecting="allowProspecting",smelting="allowSmelting",
            exchanges="allowExchanges"})[command]
        if arg == "on" or arg == "off" then
            LA.db[key] = (arg == "on"); LA:Invalidate()
        end
        Say(command .. " = " .. tostring(LA.db[key]))
    elseif command == "tokenstats" then
        Say(LA.TokenResearchStatus and LA:TokenResearchStatus() or "Token collector unavailable")
    elseif command == "tokenexport" then
        local page=math.max(1,math.floor(tonumber(arg) or 1))
        if LA.TokenResearchExport then
            LA:ShowCopy("Direct token research - page "..page,LA:TokenResearchExport(page))
        else Say("Token collector unavailable") end
    elseif command == "attcache" then
        if arg=="status" then
            Say(LA.ATTCacheStatus and LA:ATTCacheStatus() or "ATT cache unavailable")
        elseif LA.StartATTCacheUpdate then
            local ok,msg=LA:StartATTCacheUpdate()
            if not ok then Say(msg or "ATT cache update not started") end
        else Say("ATT cache module unavailable") end
    elseif command == "perf" then
        if LA.BadgePerfReport then
            local result=LA:BadgePerfReport(arg=="reset")
            for line in tostring(result):gmatch("[^\n]+") do Say(line) end
        else
            Say("Badge profiler is unavailable")
        end
    elseif command == "attdiag" then
        local id=tonumber(arg)
        if not id then Say("Usage: /ll attdiag 45648")
        else
            local f=LA:GetItemFacts("item:"..id,{})
            if not f then Say("Item data not ready for "..id.."; hover the item and try again")
            else
                local info=LA.ATTTokenInfo and LA:ATTTokenInfo(f)
                Say(("ATT diagnostic item %d: classID=%s slot=%s, %s"):format(id,
                    tostring(f.classID),tostring(f.equipLoc),
                    LA.ATTTokenDiagnostics and LA:ATTTokenDiagnostics(id) or "ATT adapter unavailable"))
                Say(info and ("Token identified: "..#info.rewards.." eligible equipment rewards; "
                    ..(info.kind or "unknown").."; missing appearance="..tostring(info.possibleMissingAppearance))
                    or "No confirmed equipment token results yet (not proof this item is vendor-only)")
            end
        end
    elseif command == "inspect" then
        local itemID = tonumber(tostring(arg or ""):match("%d+"))
        if not itemID then
            Say("Usage: /ll inspect 272147 (replace with the item's ID)")
        else
            local f = LA:GetItemFacts("item:"..itemID, {})
            if not f then
                Say("Item data not loaded yet. Hover over the item and try again.")
            else
                Say(("%s [ID %d] expansion=%s rarity=%s ilvl=%s"):format(
                    f.name, f.id, tostring(f.expansionID), tostring(f.quality), tostring(f.itemLevel)))
                local de, missing = LA:DisenchantEstimate(f)
                if de then
                    Say("DE "..(LA:AHFeeRate()>0 and "net" or "gross").." estimate: " .. LA:Money(de.value) .. " (" ..
                        tostring(de.expansionName or "TSM legacy") .. "; " .. tostring(de.note) .. ")")
                else
                    Say("DE unavailable/unknown: " .. tostring(missing or "not eligible"))
                end
            end
        end
    elseif command == "inspectbags" then
        if not C_Container or not C_Container.GetContainerNumSlots then
            Say("Blizzard bag API unavailable")
        else
            local printed, total = 0, 0
            for bag = 0, 5 do
                local slots = C_Container.GetContainerNumSlots(bag) or 0
                for slot = 1, slots do
                    local link = C_Container.GetContainerItemLink and C_Container.GetContainerItemLink(bag,slot)
                    if link then
                        local context = {bagID=bag,slotID=slot}
                        local location
                        if ItemLocation and ItemLocation.CreateFromBagAndSlot then
                            local ok, loc=pcall(ItemLocation.CreateFromBagAndSlot,ItemLocation,bag,slot)
                            if ok then location=loc end
                        end
                        if location and C_Item and C_Item.IsBound then
                            local ok,bound=pcall(C_Item.IsBound,location)
                            if ok then context.isBound=bound;context.verifiedUnbound=not bound end
                        end
                        local f=LA:GetItemFacts(link,context)
                        if f and (f.classID==2 or f.classID==4) and f.expansionID==11 then
                            total=total+1
                            if printed<15 then
                                local r=LA:Evaluate(link,context)
                                local eligible,eligibleWhy=LA:DisenchantEligibility(f)
                                local note=r and (r.deIssue or r.why) or nil
                                if not note and r and eligible and not r.canDisenchant then
                                    note="Current character's Enchanting not verified"
                                end
                                if not note and r and r.deEstimate then
                                    note="DE ~"..LA:Money(r.deEstimate.value)
                                        .." vs vendor "..LA:Money(r.vendor)
                                end
                                Say(("Bag %d:%d | %s [ID %d] | bound=%s | candidate=%s | action=%s | %s"):format(
                                    bag,slot,f.name,f.id,tostring(context.isBound or f.bindType==1),
                                    tostring(eligible),r and (r.action or "none") or "none",
                                    tostring(note or eligibleWhy)))
                                printed=printed+1
                            end
                        end
                    end
                end
            end
            Say(("Inspected %d Midnight weapons/armor; printed first %d. Reports are diagnostic only."):format(total,printed))
        end
    elseif command == "detrack" then
        if LA.DisenchantTrackingReport then LA:ShowCopy("Disenchant Tracking Diagnostics",LA:DisenchantTrackingReport())
        else Say("Disenchant diagnostics unavailable") end
    elseif command == "destats" then
        if LA.ShowDisenchantStats then LA:ShowCopy("Recorded Disenchant Statistics", LA:ShowDisenchantStats())
        else Say("Disenchant recorder unavailable") end
    elseif command == "deexport" then
        if LA.ExportDisenchantData then LA:ShowCopy("Disenchant Research CSV", LA:ExportDisenchantData())
        else Say("Disenchant recorder unavailable") end
    elseif command == "processstats" then
        if LA.ShowProcessingStats then LA:ShowCopy("Processing Research",LA:ShowProcessingStats()) end
    elseif command == "processexport" then
        if LA.ExportProcessingData then LA:ShowCopy("Processing Research CSV",LA:ExportProcessingData()) end
    elseif command == "craftstats" then
        LA:ShowCopy("Craft recording",LA:CraftRecordingReport())
    elseif command == "craftexport" then
        LA:ShowCopy("Craft research JSON",LA:ExportCraftResearch(tonumber(arg)))
    elseif command == "craftbaseline" then
        LA:ShowCopy("Measured craft baselines JSON",LA:ExportCraftBaselines())
    elseif command == "craftstudy" then
        local study,reason=LA:StartCraftStudy(msg:match("^%S+%s+(.+)$"))
        Say(study and ("Started research study: "..study) or reason or "Unable to start a study")
    elseif command == "craftzero" then
        local _,message=LA:ConfirmEmptyCraft();Say(message)
    elseif command == "scanstatus" then
        local candidates,consumers,recipes=0,0,0
        for _,list in pairs(LA.db.recipeCandidates or {}) do
            for _ in pairs(list) do candidates=candidates+1 end
        end
        for _ in pairs(LA.db.reagentConsumers or {}) do consumers=consumers+1 end
        for _,char in pairs(LA.db.characters or {}) do
            for _ in pairs(char.recipes or {}) do recipes=recipes+1 end
        end
        Say(("Scanned %d learned recipes; %d single-input recipe candidates; %d reagent IDs observed in profession recipes. Coverage is partial until you open professions on your characters."):format(recipes,candidates,consumers))
    elseif command == "status" then
        if LA.EvidenceDatabaseStatus then Say(LA:EvidenceDatabaseStatus()) end
        if LA.personalProjectionStatus then Say("Personal history: "..LA.personalProjectionStatus) end
        Say("Version "..LA.version.." (interface " .. LA.targetInterface .. "); Game Data: " .. tostring(LA.GameDataVersion or "missing") .. "; TSM API: " .. tostring(type(TSM_API) == "table") ..
            ", BetterBags: " .. tostring(LibStub and LibStub("AceAddon-3.0", true) ~= nil))
    else
        Say("/ll settings - appearance, colors, and optional profession hints")
        Say("Disenchanting requires a verified current character or eligible alt; /ll enchanting no longer overrides eligibility")
        Say("/ll milling on|off, /ll prospecting on|off, /ll smelting on|off")
        Say("/ll craftstats, /ll craftexport [page], /ll craftbaseline, /ll craftstudy LABEL, /ll craftzero, /ll exchanges on|off, /ll inspect ITEMID, /ll inspectbags, /ll destats, /ll detrack, /ll deexport, /ll processstats, /ll processexport, /ll processingdebug start|show|clear, /ll report, /ll scanstatus, /ll clearreport, /ll refresh, /ll tsmops, /ll attdiag ITEMID, /ll attcache, /ll attcache status, /ll dbstatus, /ll ignore ITEMID, /ll unignore ITEMID, /ll status")
        Say("Uses TSM prices; item processing recommendations are estimates, never automatic sells.")
    end
end

SLASH_LOOTLIQUIDATOR1 = "/ll"
SLASH_LOOTLIQUIDATOR2 = "/lootliquidator"
SLASH_LOOTLIQUIDATOR3 = "/la"
SlashCmdList.LOOTLIQUIDATOR = Command

local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == ADDON then
        LootLiquidatorDB = LootLiquidatorDB or {}
        for k,v in pairs(defaults) do
            if LootLiquidatorDB[k] == nil then LootLiquidatorDB[k] = v end
        end
        LA.db = LootLiquidatorDB
        if LA.MigrateEvidenceSettings then LA:MigrateEvidenceSettings() end
        LA.db.appearance = LA.db.appearance or {position="TOPRIGHT",fontSize=14,colors={}}
        LA.db.appearance.colors = LA.db.appearance.colors or {}
        LA.db.characters = LA.db.characters or {}
        LA.db.recipeCandidates = LA.db.recipeCandidates or {}
        LA.db.reagentConsumers = LA.db.reagentConsumers or {}
        -- Migrate thresholds from the old copper values on existing installs.
        if not LA.db._v04Migrated then
            if type(LA.db.minConversionExtra)=="number" then
                LA.db.minConversionExtraGold=math.floor(LA.db.minConversionExtra/10000+.5)
            end
            if type(LA.db.minGearProfit)=="number" then
                LA.db.minGearProfitGold=math.floor(LA.db.minGearProfit/10000+.5)
            end
            if type(LA.db.minReagentProfit)=="number" then
                LA.db.minReagentProfitGold=math.floor(LA.db.minReagentProfit/10000+.5)
            end
            LA.db._v04Migrated=true
        end
    elseif event == "PLAYER_LOGIN" then
        Say("Loaded. /ll settings for options; /ll report to copy unknown conversions. No automatic selling.")
    end
end)

do -- Item decision filters and DB2 restrictions
-- Item decision filters. Saved in the existing account-wide LootLiquidatorDB.
-- Static DB2 data is stored separately and NEVER copied into SavedVariables.
local LL=LA
LL.ItemRestrictions = LL.ItemRestrictions or {}
local function State(self)
    if not self.db then return nil end
    self.db.ignoredItems = self.db.ignoredItems or {}
    return self.db.ignoredItems
end
local function Id(item)
    if type(item)=="number" then return item end
    if type(item)~="string" then return nil end
    return tonumber(item:match("item:(%d+)")) or tonumber(item)
end
function LL:IgnoreEntry(item)
    local id=Id(item)
    local s=State(self)
    return id and s and (s[id] or s[tostring(id)]) or nil
end
function LL:IsIgnoredAction(item, method)
    local entry=self:IgnoreEntry(item)
    if not entry then return false end
    if entry.all == true then return true end
    if (method=="T" or method=="Transmog") and entry.T==nil
        and entry.A==true and entry.D==true and entry.V==true and entry.P==true then
        return true
    end
    local normalized=({Auction="A",Disenchant="D",Vendor="V",Transmog="T",Mill="P",Prospect="P",
        Smelt="P",Recycle="P",Research="P",Combine="P",Split="P",Exchange="P",Craft="P"})[method] or method
    return entry[normalized] == true
end
function LL:SetIgnoreEntry(item, flags, name)
    local id=Id(item)
    if not id or id<=0 or id~=math.floor(id) then return false end
    local s=State(self)
    if not s then return false end
    if flags==nil then s[id]=nil;s[tostring(id)]=nil
    else
        local entry=s[id] or s[tostring(id)] or {}
        s[tostring(id)]=nil
        entry.A = flags.A == true; entry.D= flags.D == true
        entry.V = flags.V == true; entry.P = flags.P == true; entry.T = flags.T == true or (flags.T == nil
            and flags.A == true and flags.D == true and flags.V == true and flags.P == true)
        entry.all=nil
        if type(name)=="string" and name~="" then entry.name=name end
        s[id]=entry
    end
    if self.Invalidate then self:Invalidate() end
    return true
end
-- DB2 no-disenchant flags take priority over estimates, regardless of price.
function LL:ExternalDisenchantRestriction(item)
    local id=Id(item)
    if not id then return nil end
    if self.ItemRestrictions and self.ItemRestrictions[id] then
        return "Item database: Cannot be disenchanted"
    end
    return nil
end

end
