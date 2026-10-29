local ADDON, LA = ...
local hookedBetterBags = false
-- Weak keys: never prevent Blizzard/BetterBags buttons from being collected.
local activeButtons=setmetatable({}, {__mode="k"})

-- Display logic is shared by BetterBags, Blizzard bags and guild bank.
function LA:Paint(button, link, result)
    if not button then return end
    button.laLink = link
    button.laDecision = result
    if link then activeButtons[button]=true end
    if not self.db or self.db.showBadges == false then
        if button.laLetter then button.laLetter:Hide() end
        return
    end
    local action = result and result.action
    if action == "Q" and self.db.showUnknownBadge == false then
        action = nil
    elseif action == "C" then
        -- The generic Convert badge is retired. Advanced conversion estimates
        -- remain available in tooltips without an ambiguous bag letter.
        action = nil
    end
    if not action then
        if button.laLetter then button.laLetter:Hide() end
        return
    end
    if not button.laLetter then
        if InCombatLockdown and InCombatLockdown() then return end
        button.laLetter = button:CreateFontString(nil, "OVERLAY")
    end
    local font=button.laLetter
    local appearance=self.db.appearance or {}
    local size=appearance.fontSize or 14
    local pos=appearance.position or "TOPRIGHT"
    local ox=(pos:find("RIGHT") and -2 or pos:find("LEFT") and 2 or 0)
    local oy=(pos:find("TOP") and -2 or pos:find("BOTTOM") and 2 or 0)
    if button.laPosition ~= pos then
        font:ClearAllPoints()
        font:SetPoint(pos,button,pos,ox,oy)
        button.laPosition=pos
    end
    if button.laFontSize ~= size then
        font:SetFont(STANDARD_TEXT_FONT,size,"OUTLINE")
        button.laFontSize=size
    end
    local c=self:GetBadgeColor(action)
    font:SetText(action=="Q" and "?" or action)
    font:SetTextColor(c[1],c[2],c[3],1)
    font:Show()
end

function LA:ClearButton(button)
    if not button then return end
    button.laLink = nil; button.laDecision = nil
    button.laBadgeFingerprint=nil
    activeButtons[button]=nil
    if button.laLetter then button.laLetter:Hide() end
end

local function GetContext(data)
    local info = data and data.itemInfo
    local ctx = {isQuest = data and data.questInfo and data.questInfo.isQuestItem}
    ctx.count = (info and (info.stackCount or info.count)) or (data and data.stackCount) or 1
    ctx.isBound = (data and (data.isBound or data.bound)) or (info and (info.isBound or info.bound))
    ctx.isSoulbound = (data and data.isSoulbound) or (info and info.isSoulbound)
    ctx.isBoundToAccount = (data and data.isBoundToAccount)
    -- Never equate the item's static Warbound tooltip with verified transfer
    -- eligibility after it has become Soulbound.
    local guid = (data and (data.guid or data.itemGUID)) or (info and (info.guid or info.itemGUID))
    local location
    if guid and C_Item and C_Item.GetItemLocation then
        local ok, loc = pcall(C_Item.GetItemLocation, guid)
        if ok then location = loc end
    end
    local bag = (data and (data.bagID or data.bagid)) or (info and (info.bagID or info.bagid))
    local slot = (data and (data.slotID or data.slotid)) or (info and (info.slotID or info.slotid))
    -- BetterBags may expose a GUID instead of bag/slot coordinates. Resolve
    -- the actual item location so pre-hover token checks work there too.
    if location and (type(bag)~="number" or type(slot)~="number")
        and type(location.GetBagAndSlot)=="function" then
        local ok,b,s=pcall(location.GetBagAndSlot,location)
        if ok and type(b)=="number" and type(s)=="number" then bag,slot=b,s end
    end
    if type(bag)=="number" and type(slot)=="number" then
        ctx.bagID,ctx.slotID=bag,slot
    end
    if not location and type(bag) == "number" and type(slot) == "number"
        and ItemLocation and ItemLocation.CreateFromBagAndSlot then
        local ok, loc = pcall(ItemLocation.CreateFromBagAndSlot, ItemLocation, bag, slot)
        if ok then location = loc end
    end
    if location and C_Item and type(C_Item.DoesItemExist) == "function" then
        local ok, exists = pcall(C_Item.DoesItemExist, location)
        if ok and exists then
            if type(C_Item.IsBound) == "function" then
                local boundOK, bound = pcall(C_Item.IsBound, location)
                if boundOK and bound == true then ctx.isBound = true end
                if boundOK and bound == false then ctx.verifiedUnbound = true end
            end
            if type(C_Item.IsBoundToAccountUntilEquip) == "function" then
                local wbOK, wb = pcall(C_Item.IsBoundToAccountUntilEquip, location)
                if wbOK and wb == true then
                    ctx.isBoundToAccount = true
                    ctx.verifiedWarbound = true -- verified from THIS item location
                end
            end
            if C_AuctionHouse and type(C_AuctionHouse.IsSellItemValid) == "function" then
                local validOK, valid = pcall(C_AuctionHouse.IsSellItemValid, location, false)
                if validOK and valid == false then ctx.verifiedUnbound = false end
            end
        end
    end
    if ctx.isBound or ctx.isBoundToAccount or ctx.isSoulbound then ctx.verifiedUnbound = false end
    return ctx
end

-- BetterBags may repeatedly rebuild and reassign exactly the same item
-- while laying out a large Warbank.  Do not discard/reprice a correctly
-- painted badge just because SetItemFromData fired again.  A key includes
-- the instance GUID/bag slot/binding/count so a changed item is never reused.
local function BadgeFingerprint(link,data,context)
    local info=data and data.itemInfo
    local loc=data or {}
    local c=context or {}
    return table.concat({
        tostring(link),
        tostring(loc.guid or loc.itemGUID or (info and (info.guid or info.itemGUID)) or c.guid),
        tostring(loc.bagID or loc.bagid or (info and (info.bagID or info.bagid)) or c.bagID),
        tostring(loc.slotID or loc.slotid or (info and (info.slotID or info.slotid)) or c.slotID),
        tostring((info and (info.stackCount or info.count)) or loc.stackCount or c.count or 1),
        tostring(loc.isBound or (info and info.isBound) or c.isBound),
        tostring(loc.isSoulbound or (info and info.isSoulbound) or c.isSoulbound),
        tostring(loc.isBoundToAccount or (info and info.isBoundToAccount) or c.isBoundToAccount),
        tostring(c.verifiedWarbound),
    }, "|")
end

-- All expensive recommendations remain accurate, but an ATT lookup may
-- exceed an entire frame's budget by itself. A timer cannot interrupt a
-- running Lua lookup.  Process ONE at a time and back off after slow calls,
-- rather than repeatedly blocking consecutive frames.
local pendingBadgeJobs=setmetatable({}, {__mode="k"})
local pendingBadgeOrder={}
local pendingBadgeHead=1
local badgeTickScheduled=false
local perf={processed=0,repeatSkips=0,cacheHits=0,totalMs=0,maxMs=0,maxItem="?",slow=0,top={}}
local recentBadgeDecisions={}
local recentBadgeCount=0
function LA:ClearBadgeDecisionCache()
    recentBadgeDecisions={}
    recentBadgeCount=0
end
local function BadgeTime()
    return type(debugprofilestop)=="function" and debugprofilestop() or nil
end
local function RecordBadgeTime(link,elapsed)
    if not elapsed then return end
    perf.processed=perf.processed+1
    perf.totalMs=perf.totalMs+elapsed
    if elapsed>=16 then perf.slow=perf.slow+1 end
    local id=tostring(link or "?"):match("item:(%d+)") or tostring(link or "?"):sub(1,20)
    if elapsed>perf.maxMs then perf.maxMs,perf.maxItem=elapsed,id end
    if elapsed>=8 then
        local found
        for _,record in ipairs(perf.top) do
            if record.id==id then found=record; break end
        end
        if found then
            found.count=found.count+1
            if elapsed>found.ms then found.ms=elapsed end
        else
            perf.top[#perf.top+1]={id=id,ms=elapsed,count=1}
        end
        table.sort(perf.top,function(a,b)return a.ms>b.ms end)
        while #perf.top>5 do table.remove(perf.top) end
    end
end
function LA:BadgePerfReport(reset)
    if reset then
        perf={processed=0,repeatSkips=0,cacheHits=0,totalMs=0,maxMs=0,maxItem="?",slow=0,top={}}
        return "BetterBags badge performance counters reset"
    end
    local waiting=0
    for _ in pairs(pendingBadgeJobs) do waiting=waiting+1 end
    local lines={string.format(
        "BetterBags: %d timed jobs, %.0f ms total, %.1f ms worst (item %s), %d jobs >=16ms; %d repeat redraws skipped; %d instant cached badges; %d queued",
        perf.processed,perf.totalMs,perf.maxMs,perf.maxItem,perf.slow,perf.repeatSkips,perf.cacheHits,waiting)}
    for _,r in ipairs(perf.top) do
        lines[#lines+1]=string.format("slow item %s: %.1f ms max (%d slow jobs)",r.id,r.ms,r.count)
    end
    if not BadgeTime() then lines[#lines+1]="WoW debugprofilestop unavailable (timing disabled)" end
    return table.concat(lines,"\n")
end

local function ProcessBadgeJobs()
    badgeTickScheduled=false
    local elapsed
    local count=0
    local start=BadgeTime()
    -- Several cheap badge decisions can be painted each frame. Stop once
    -- the measured work exceeds 3 ms; one slow API call can't be preempted.
    while pendingBadgeHead<=#pendingBadgeOrder and count<8 do
        local button=pendingBadgeOrder[pendingBadgeHead]
        pendingBadgeOrder[pendingBadgeHead]=false -- preserve array length
        pendingBadgeHead=pendingBadgeHead+1
        local job=button and pendingBadgeJobs[button]
        if job then
            pendingBadgeJobs[button]=nil
            -- A pooled item button may have changed item, or its bank may
            -- have closed while it was queued. Never paint stale results.
            local current=job.data and job.data.itemInfo and job.data.itemInfo.itemLink
            if (not job.data or current==job.link)
                and (not button.IsVisible or button:IsVisible()) then
                local t=BadgeTime()
                local ctx=job.data and GetContext(job.data) or job.context or {}
                ctx._LLFastBadge=true -- never do an uncached ATT search here
                local decision=LA:Evaluate(job.link,ctx)
                LA:Paint(button,job.link,decision)
                local fingerprint=job.fingerprint
                button.laBadgeFingerprint=fingerprint
                if decision then
                    if recentBadgeCount>=400 then
                        recentBadgeDecisions={};recentBadgeCount=0
                    end
                    if not recentBadgeDecisions[fingerprint] then recentBadgeCount=recentBadgeCount+1 end
                    recentBadgeDecisions[fingerprint]={result=decision,at=GetTime and GetTime() or 0}
                end
                local after=BadgeTime()
                elapsed=t and after and math.max(0,after-t) or nil
                RecordBadgeTime(job.link,elapsed)
            end
            count=count+1
            if start and BadgeTime() and BadgeTime()-start>=3 then break end
        end
    end
    if pendingBadgeHead>#pendingBadgeOrder then
        pendingBadgeOrder={}
        pendingBadgeHead=1
    end
    if pendingBadgeHead<=#pendingBadgeOrder and not badgeTickScheduled then
        badgeTickScheduled=true
        -- A budget can only be observed AFTER an individual ATT call returns.
        -- Cool off between expensive item lookups rather than stalling every
        -- frame of a Warbank opening animation.
        local delay=elapsed and (elapsed>=16 and 0.20 or elapsed>=6 and 0.06 or 0) or 0.03
        C_Timer.After(delay,ProcessBadgeJobs)
    end
end
local function QueueBetterBagsBadge(button,link,data,context,force)
    if not button then return end
    if not link then
        pendingBadgeJobs[button]=nil
        LA:ClearButton(button)
        return
    end
    if LA.RememberATTItem then LA:RememberATTItem(link) end
    local fingerprint=BadgeFingerprint(link,data,context)
    -- Do not re-evaluate the same instance when BetterBags repaints a section.
    if not force and button.laLink==link and button.laDecision
        and button.laBadgeFingerprint==fingerprint and not pendingBadgeJobs[button] then
        perf.repeatSkips=perf.repeatSkips+1
        return
    end
    if not force then
        local previous=recentBadgeDecisions[fingerprint]
        local now=GetTime and GetTime() or 0
        if previous and now-previous.at<30 and not pendingBadgeJobs[button] then
            LA:Paint(button,link,previous.result)
            button.laBadgeFingerprint=fingerprint
            perf.cacheHits=perf.cacheHits+1
            return
        end
    end
    -- This path also makes tests without the retail timer work.
    if not (C_Timer and type(C_Timer.After)=="function") then
        local ctx=data and GetContext(data) or context or {}
        ctx._LLFastBadge=true
        LA:Paint(button,link,LA:Evaluate(link,ctx))
        button.laBadgeFingerprint=fingerprint
        return
    end
    local pending=pendingBadgeJobs[button]
    if pending and not force and pending.fingerprint==fingerprint then
        pending.data=data -- keep newest data; the identity is unchanged
        return
    end
    if not pending then
        pendingBadgeOrder[#pendingBadgeOrder+1]=button
    end
    pendingBadgeJobs[button]={link=link,data=data,context=context,fingerprint=fingerprint}
    -- Never show the old item's V/D/T while a pooled slot changes.
    if button.laLink~=link or button.laBadgeFingerprint~=fingerprint then
        LA:ClearButton(button)
    end
    if not badgeTickScheduled then
        badgeTickScheduled=true
        C_Timer.After(0,ProcessBadgeJobs)
    end
end

local function HookBetterBags()
    if hookedBetterBags or not LA.db or not LA.db.showBetterBags then return end
    if not LibStub then return end
    local ace = LibStub("AceAddon-3.0", true)
    if not ace then return end
    local bb = ace:GetAddon("BetterBags", true)
    if not bb then return end
    local itemFrame = bb:GetModule("ItemFrame", true)
    if not itemFrame or not itemFrame.itemProto then return end
    local proto = itemFrame.itemProto
    if type(proto.SetItemFromData) ~= "function" then return end
    hookedBetterBags = true
    hooksecurefunc(proto, "SetItemFromData", function(self, _, data)
        local button = self.button
        local link = data and data.itemInfo and data.itemInfo.itemLink
        QueueBetterBagsBadge(button,link,data)
    end)
    local function ClearItem(self) QueueBetterBagsBadge(self and self.button,nil) end
    if type(proto.SetFreeSlots) == "function" then hooksecurefunc(proto, "SetFreeSlots", ClearItem) end
    if type(proto.ClearItem) == "function" then hooksecurefunc(proto, "ClearItem", ClearItem) end
end

function LA:RequestBadgeRefresh()
    -- Refresh already-painted buttons immediately without requiring bag sorts.
    -- The next bag update revalidates item contents and instance binding.
    for button in pairs(activeButtons) do
        -- Blizzard buttons are refreshed by QueueBlizzardBagRefresh().
        if not button.laBlizzardBag and not button.laGuildBank then
        local link=button.laLink
        local last=button.laDecision
        if link and last then
            local context=last.facts and last.facts.context or {}
            QueueBetterBagsBadge(button,link,nil,context,true)
        end
        end
    end
end

-- Keep token summary/reward lines in the tooltip's normal font. Past
-- versions forced GameFontHighlightSmall, which was harder to read and
-- required pooled FontString restoration hooks.

-- Blizzard's class icon texture + shared class coordinates. Only markup in
-- Loot Liquidator rows is changed; ATT/TSM own tooltips remain untouched.
local function LLClassIcon(class)
    local coords=CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
    if coords and type(CreateTextureMarkup)=="function" then
        local ok,result=pcall(CreateTextureMarkup,
            "Interface\\WorldStateFrame\\Icons-Classes",256,256,14,14,
            coords[1],coords[2],coords[3],coords[4],-2,-1)
        if ok and type(result)=="string" then return result.." " end
    end
    local atlas="class-"..tostring(class):lower()
    if C_Texture and type(C_Texture.GetAtlasInfo)=="function"
        and type(CreateAtlasMarkup)=="function" then
        local ok,value=pcall(C_Texture.GetAtlasInfo,atlas)
        if ok and value then
            local good,icon=pcall(CreateAtlasMarkup,atlas,14,14)
            if good and type(icon)=="string" then return icon.." " end
        end
    end
    return ""
end
local function LLTokenRewardLabel(id)
    if not id then return nil end
    local info=C_Item and C_Item.GetItemInfo or GetItemInfo
    if type(info)~="function" then return nil end
    local ok,name,link=pcall(info,id)
    if ok and name then return link or name end
end

-- Extend all ordinary item tooltips. Bag/guild-bank tooltips reuse their already
-- calculated decisions. Elsewhere we fail closed for unverified gear binding.
-- One renderer for in-game tooltips and the live settings preview.
function LA:AppendRecommendationTooltip(tooltip,decision)
    if not LA.db or not LA.db.showTooltips or not tooltip or not decision then return end
    local method=decision.method
    local names={A="Auction",V="Vendor",D="Disenchant",M="Mill",P="Prospect",
        S="Smelt",C=method or "Craft/refine",Q="Insufficient Data",T="Transmog"}
    local label=names[decision.action]
    local compactToken=decision.tokenInfo and LA.db.showATTTokenSummary~=false
        and type(LA.ATTTokenClassSummary)=="function"
    if compactToken and decision.action=="Q" then label="Review token" end
    local detail=LA.db.tooltipDetail or 2
    local printedSamples=false
    local progress=(detail>=3 and LA.ProfessionProgression and decision.facts)
        and LA:ProfessionProgression(decision.facts,decision) or {}
    -- Bound/vendor-only loot remains quiet unless there are research results
    -- or a detailed external reference model worth showing transparently.
    local f=decision.facts
    local model=f and LA.DisenchantTables and LA.DisenchantTables[f.expansionID]
    local modelRule=model and model.quality and model.quality[f.quality]
    -- Old imported reference-rates toggle retired: compiled Game Data
    -- supplies rates with explicit per-output confidence instead.
    if not decision.action and (detail<3 or #(decision.conversionOptions or {})==0)
        and #progress==0 and not (LA.db.showProcessingSamples and decision.deStats)
        then return end
    local function two(left,right,letter)
        local color=LA:MarkupColor(letter)
        if tooltip.AddDoubleLine then
            tooltip:AddDoubleLine(color..left.."|r",right or "",1,1,1,1,1,1)
        else
            tooltip:AddLine(color..left.."|r"..(right and "  "..right or ""))
        end
    end
    local function MaterialDisplay(materialID)
        local name, quality
        local info = C_Item and C_Item.GetItemInfo or GetItemInfo
        if type(info)=="function" then
            local ok, n, _, q = pcall(info,materialID)
            if ok then name, quality = n,q end
        end
        local icon
        local getIcon = C_Item and C_Item.GetItemIconByID or GetItemIcon
        if type(getIcon)=="function" then
            local ok, value=pcall(getIcon,materialID)
            if ok and (type(value)=="number" or type(value)=="string") then icon=value end
        end
        local prefix=icon and ("|T%s:14:14:0:0|t "):format(tostring(icon)) or ""
        -- Blizzard profession reagent quality is independent of ITEM_QUALITY_COLORS.
        -- It has its own small pip atlas, shown immediately after the item icon.
        -- Only use known rank-to-itemID mappings, never guess from item rarity.
        local rank=LA.MaterialReagentRanks and LA.MaterialReagentRanks[materialID]
        -- Retail exposes crafting reagent quality directly. Never infer it
        -- from the ID order or from ordinary green/blue/purple item rarity.
        local reagentInfo
        if C_TradeSkillUI and type(C_TradeSkillUI.GetItemReagentQualityInfo)=="function" then
            local ok,result=pcall(C_TradeSkillUI.GetItemReagentQualityInfo,materialID)
            if ok and type(result)=="table" then reagentInfo=result end
        end
        rank=rank or (reagentInfo and reagentInfo.quality)
        if rank then
            local atlas=(reagentInfo and reagentInfo.iconSmall)
                or ("Professions-Icon-Quality-Tier"..rank.."-Small")
            local supported=false
            if C_Texture and type(C_Texture.GetAtlasInfo)=="function" then
                local ok, info=pcall(C_Texture.GetAtlasInfo,atlas)
                supported=ok and info~=nil
            end
            if supported then prefix=prefix..("|A:%s:13:13|a "):format(atlas)
            else prefix=prefix..("|cffb4d8ff[R%d]|r "):format(rank) end
        end
        if not name and C_Item and type(C_Item.RequestLoadItemDataByID)=="function" then
            pcall(C_Item.RequestLoadItemDataByID,materialID)
        end
        local color=(quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
            and ITEM_QUALITY_COLORS[quality].hex)
        local label=name or ("Material "..tostring(materialID))
        -- ITEM_QUALITY_COLORS[quality].hex normally ALREADY includes |c.
        -- Accept either WoW markup or a raw 8/6-digit hex value, never |c|c.
        if type(color)=="string" then
            local code=color:match("^|[cC](%x%x%x%x%x%x%x%x)$")
                or color:match("^#?(%x%x%x%x%x%x%x%x)$")
            if not code then
                local rgb=color:match("^#?(%x%x%x%x%x%x)$")
                if rgb then code="ff"..rgb end
            end
            if code then label="|c"..code..label.."|r" end
        end
        return prefix..label
    end
    -- Short money labels for showing TWO values in a narrow WoW tooltip.
    -- These are display-only; all gold decisions keep unrounded copper values.
    -- For >=10g round to gold, between 1s and 10g round to silver,
    -- and below 1s retain copper. Icon paths match Blizzard money textures.
    local function CompactMoney(value)
        if type(value)~="number" or value<0 or value>=math.huge then return nil end
        local goldIcon="|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:0:0|t"
        local silverIcon="|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:0:0|t"
        local copperIcon="|TInterface\\MoneyFrame\\UI-CopperIcon:12:12:0:0|t"
        local amount
        if value>=100000 then
            amount=math.floor(value/10000+.5)
            return tostring(amount)..goldIcon
        end
        if value>=100 then
            amount=math.floor(value/100+.5)
            local g=math.floor(amount/100)
            local silver=amount%100
            if g>0 and silver>0 then
                return tostring(g)..goldIcon.." "..tostring(silver)..silverIcon
            end
            if g>0 then return tostring(g)..goldIcon end
            return tostring(silver)..silverIcon
        end
        return tostring(math.floor(value+.5))..copperIcon
    end
    local function MaterialPriceText(mat,mode)
        -- mat.expectedValue is GROSS, based on actual aggregate quantities /
        -- total operations; chance is ALREADY included, never multiply twice.
        local gross=mat.expectedValue
        if gross==nil and mat.unitPrice and mat.expectedQuantity then
            gross=mat.unitPrice*mat.expectedQuantity
        end
        local expected=gross and gross*(1-LA:AHFeeRate())
        local unit=mat.unitPrice
        if mode==1 then return unit and LA:Money(unit) or "" end
        if mode==2 then return expected and LA:Money(expected) or "" end
        if expected and unit then
            return CompactMoney(expected).." ("..CompactMoney(unit)..")"
        end
        if expected then return CompactMoney(expected) or "" end
        -- Never imply an unknown drop chance yields a positive expected price.
        if unit then return "("..CompactMoney(unit).." unit; yield unknown)" end
        return ""
    end
    local function valued(label,unit,letter,count)
        if unit==nil then return end
        count=math.max(1,tonumber(count) or 1)
        -- All prices are per original item, like TSM. Repeating '(each)'
        -- beside every method obscures the actual value comparison.
        two(label,LA:Money(unit),letter)
    end
    if label then
        local suffix=""
        if decision.action=="A" and decision.fallback and LA.db.showFallback~=false then
            local fallbackName=names[decision.fallback] or method
            if fallbackName then suffix=" ("..fallbackName..")" end
        end
        if decision.action=="D" and decision.conversion
            and decision.conversion.confidence=="baseline" then suffix=" (estimated)" end
        tooltip:AddLine("|cff66ccffLoot Liquidator:|r "..
            LA:MarkupColor(decision.action)..label..suffix.."|r")
    end
    -- All priced methods (including the winning Auction) use the SAME row
    -- renderer below. Minimal mode still includes the Auction quote.
    if detail<2 and decision.action=="A" and decision.rawAuction then
        local price=LA.db.tooltipShowAfterAHCut~=false and decision.netAuction
            or decision.rawAuction
        two("Auction",LA:Money(price),"A")
    end
    -- For tokens the guaranteed price belongs directly below the action,
    -- as it does for ordinary disenchant/vendor recommendations.  Do not
    -- repeat it after class sets or confuse it with a redeemed reward's price.
    if compactToken and LA.db.tooltipVendor~=false
        and type(decision.vendor)=="number" and decision.vendor>0 then
        two("Vendor token (guaranteed)",LA:Money(decision.vendor),"V")
    end
    if decision.action=="Q" and decision.why and not compactToken then
        local issue=decision.why
        if issue:find("TSM operation",1,true) then
            issue="TSM auction operation: no valid price"
        end
        tooltip:AddLine(issue,1,.65,.30,true)
    end
    -- Confirmed restrictions merit one short line even when the V badge is
    -- hidden for soulbound gear; suppress all processing value estimates.
    if decision.disenchantRestriction and detail>=2 then
        tooltip:AddLine("Disenchant unavailable: "..decision.disenchantRestriction,.95,.55,.40,true)
    end
    -- One method renderer: header/price followed IMMEDIATELY by its output
    -- materials. Collection ownership, auctionability and profit are separate.
    -- Normal equipment must NEVER skip money quotes because the top badge is T.
    if detail>=2 and (decision.action~="T" or not decision.tokenInfo or compactToken) then
        local count=decision.count or 1
        if LA.db.tooltipAuction~=false then
            local quote=decision.rawAuction and (LA.db.tooltipShowAfterAHCut~=false
                and decision.netAuction or decision.rawAuction)
            if type(quote)=="number" and quote>0 then
                two("Auction",LA:Money(quote),"A")
            elseif type(decision.marketAuction)=="number" and decision.marketAuction>0 then
                local market=LA.db.tooltipShowAfterAHCut~=false
                    and decision.marketAuctionNet or decision.marketAuction
                local suffix=decision.auctionEligible and " (market, not operation quote)"
                    or " (market only; cannot auction)"
                two("Auction"..suffix,LA:Money(market),"A")
            end
        end
        if detail>=3 and LA.db.showResearchDetails==true and decision.operationSimulation then
            tooltip:AddLine("TSM preview only: assign this operation in TSM to post with it",1,.63,.24,true)
        end
        local options=decision.conversionOptions or {}
        local choices={}
        for _,option in ipairs(options) do
            if option.name then
                local previous=choices[option.name]
                if not previous or (option.value and not previous.value)
                    or (option.value and previous.value
                        and ((option.available and not previous.available)
                            or (option.available==previous.available and option.value>previous.value))) then
                    choices[option.name]=option
                end
            end
        end
        local names={Disenchant="Disenchant",Mill="Milling",Prospect="Prospecting",
            Smelt="Smelting",Craft="Craft/refine",Recycle="Recycle",Research="Research",
            Exchange="Exchange",Combine="Combine",Split="Split"}
        local methodOrder={"Disenchant","Mill","Prospect","Smelt","Craft",
            "Recycle","Research","Combine","Split","Exchange"}
        local function ShowMaterials(option,model)
            if detail<3 or LA.db.showMaterialBreakdown==false then return end
            local list=model and model.materials
            if type(list)=="table" and #list>0 then
                local batch=math.max(1,tonumber(model.inputCount) or tonumber(option.inputCount) or 1)
                local limit=LA.db.showResearchDetails==true and #list or math.min(#list,12)
                for i=1,limit do
                    local m=list[i]
                    local left="  "
                    if type(m.chance)=="number" then
                        -- Occurrence probability is separate from unconditional
                        -- expected units. Approximate values are marked ~.
                        local prefix=(m.provisional or (type(m.probabilityBasis)=="string"
                            and (m.probabilityBasis:find("estimated",1,true) or
                                 m.probabilityBasis:find("proxy",1,true)))) and "~" or ""
                        left=left..prefix..("%.1f"):format(m.chance*100):gsub("%.0$","").."% "
                    else left=left.."? " end
                    left=left..MaterialDisplay(m.id)
                    if m.minQuantity and m.maxQuantity then
                        left=left..(m.minQuantity==m.maxQuantity
                            and (" [x%d]"):format(m.minQuantity)
                            or (" [x%d-%d]"):format(m.minQuantity,m.maxQuantity))
                    end
                    left=left..(type(m.expectedQuantity)=="number" and ("  EV %.3f"):format(m.expectedQuantity) or "  EV ?")
                    local net=m.netExpectedValue
                    local amount=net~=nil and LA:Money(net/batch) or "Insufficient Data"
                    two(left,amount,option.letter or "D")
                    if LA.db.showResearchDetails==true then
                        for _,source in ipairs(LA.SourceOrder or {}) do
                            local estimate=m.sourceEstimates and m.sourceEstimates[source]
                            if estimate then
                                local p=type(estimate.dropChance)=='number' and ('%.1f%%'):format(estimate.dropChance*100) or '?'
                                tooltip:AddLine(('    %s: P %s; range %s–%s; E %s'):format(source,p,
                                    tostring(estimate.minQuantity or '?'),tostring(estimate.maxQuantity or '?'),
                                    type(estimate.expectedQuantity)=='number' and ('%.3f'):format(estimate.expectedQuantity) or '?'),.65,.68,.76,true)
                                if estimate.sourceConflict then tooltip:AddLine('    Source fields disagree; original values preserved',1,.68,.3,true) end
                                if estimate.appliedRule then tooltip:AddLine('    Profession rule: '..estimate.appliedRule,.65,.68,.76,true) end
                            end
                        end
                        if m.boundsSource then tooltip:AddLine("    Conditional bounds: "..m.boundsSource,.65,.68,.76,true) end
                        if m.personalHistogram and m.personalSamples and m.personalSamples>0 then
                            local bins={} for quantity,n in pairs(m.personalHistogram) do bins[#bins+1]={quantity=quantity,n=n} end
                            table.sort(bins,function(a,b) return tonumber(a.quantity)<tonumber(b.quantity) end)
                            for j=1,math.min(#bins,12) do
                                local bin=bins[j]
                                tooltip:AddLine(("    Personal x%s: %.1f%% (%g/%g casts)"):format(tostring(bin.quantity),
                                    bin.n*100/m.personalSamples,bin.n,m.personalSamples),.62,.72,.83,true)
                            end
                        end
                    end
                end
                if model.sources then
                    for _,source in ipairs(LA.SourceOrder or {}) do
                        local contribution=model.sources[source]
                        if contribution and contribution>0 then
                            tooltip:AddLine(("  %s: %.1f%% effective contribution"):format(source,contribution*100),.65,.72,.80,true)
                        end
                    end
                end
                if model.context then
                    local ctx=model.context
                    local era=LA.DisenchantTables and LA.DisenchantTables[ctx.expansionID]
                    tooltip:AddLine(("  %s %s — skill %s"):format(era and era.name or "Unknown expansion",
                        ctx.profession or option.profession or "Profession",tostring(ctx.effectiveSkill or "?")),.70,.75,.82,true)
                    tooltip:AddLine(("  %s (%s)"):format(ctx.character or "Unknown character",ctx.profileKind or "unknown context"),.70,.75,.82,true)
                    if ctx.stale or ctx.incomplete then tooltip:AddLine("  Profession snapshot stale or incomplete",1,.68,.3,true) end
                end
                tooltip:AddLine("  "..(model.adjustment or "Unadjusted reference")..
                    (model.provisional and " — provisional" or ""),.72,.70,.80,true)
                if model.warning then tooltip:AddLine("  "..model.warning,1,.68,.3,true) end
                if model.partialPrice then tooltip:AddLine("  Insufficient Data: incomplete output valuation",1,.68,.3,true) end
                if #list>limit then
                    tooltip:AddLine(("  +%d more materials"):format(#list-limit),.70,.72,.78,true)
                end
                if LA.db.showResearchDetails==true then
                    if model.samples then
                        tooltip:AddLine(("  Research: %d casts"):format(model.samples),.62,.79,.98,true)
                    end
                end
                return
            end
            tooltip:AddLine("  "..(option.note or "Insufficient Data: no researched yield model"),.83,.72,.59,true)
        end
        for _,methodName in ipairs(methodOrder) do
            local option=choices[methodName]
            -- A sword cannot acquire unrelated Prospect/Smelt rows merely
            -- because a Force On profession switch is set.
            local isGear=f and (f.classID==2 or f.classID==4)
            if option and (not isGear or methodName=="Disenchant")
                and (option.available or LA.db.showUnavailableConversions~=false) then
                -- Reuse the exact evaluated material model used to price this option.
                local model=option.yieldModel
                local hasMaterials=(model and model.materials and #model.materials>0)
                if option.value or hasMaterials
                    or (option.category=="destroy" and
                        (methodName=="Mill" or methodName=="Prospect"))
                    or (methodName=="Disenchant"
                    and decision.disenchantEligible)
                    or methodName=="Smelt" then
                    local confidence=model and model.confidence
                    local label=names[methodName] or methodName
                    if model and model.confidenceUnscored then label=label.." (Confidence unscored)"
                    elseif confidence then label=label..(" (Confidence %d/100)"):format(confidence)
                    elseif option.available==false then label=label.." (estimate)" end
                    if option.value then
                        valued(label,option.value,option.letter,methodName=="Disenchant" and count or 1)
                    else
                        two(label,"Insufficient Data",option.letter or "D")
                    end
                    ShowMaterials(option,model)
                    if not option.value and (detail<3 or LA.db.showMaterialBreakdown==false) then
                        local note=(model and model.warning) or option.note
                        if note then tooltip:AddLine("  "..note,.83,.72,.59,true) end
                    end
                    if option.available==false and option.why then
                        tooltip:AddLine("  "..option.why,1,.68,.3,true)
                    end
                    if not hasMaterials and not option.value
                        and (methodName=="Mill" or methodName=="Prospect") then
                        tooltip:AddLine("  Output yields not researched yet",.73,.69,.61,true)
                    end
                    if LA.db.showResearchDetails==true and option.character
                        and option.character~="Current character" then
                        tooltip:AddLine("  On: "..option.character,.68,.80,.97,true)
                    end
                end
            end
        end
        -- The actual collection state is informational even if the account
        -- prefers the higher-gold method or has no eligible transmog recipient.
        if decision.missingAppearance and decision.action~="T" then
            tooltip:AddLine("  Appearance not collected (collection yields 0g)",.55,.88,.79,true)
        end
        -- The recipient instruction is collection advice, never a gold quote.
        -- Place it before the final Vendor row, not beneath it.
        if decision.action=="T" and not decision.tokenInfo and decision.transmogRecipient then
            local recipient=decision.transmogRecipient
            tooltip:AddLine(recipient.current and "Keep for transmog on this character"
                or ("Send to "..(recipient.displayName or "eligible alt").." for transmog"),
                .51,.90,.80,true)
        end
        -- Posting diagnostics belong above Vendor, not after the monetary
        -- comparison. Token-only messaging retains its separate layout.
        if not decision.tokenInfo and decision.blocked=="No TSM price" then
            tooltip:AddLine((not TSM_API or type(TSM_API.GetCustomPriceValue)~="function")
                and "AH pricing unavailable (TSM not providing prices)"
                or "AH pricing unavailable (no TSM price data)",.95,.6,.35,true)
        end
        -- Vendor is the LAST comparison row for ordinary items.
        if LA.db.tooltipVendor~=false and type(decision.vendor)=="number"
            and decision.vendor>0 and not compactToken then
            valued("Vendor",decision.vendor,"V",count)
        end
    end
    if detail>=3 and LA.db.showResearchDetails==true
        and LA.db.showProcessingSamples~=false and decision.deStats
        and not printedSamples then
        local n=decision.deStats.total or 0
        if decision.deStats.borrowedSamples and decision.deStats.borrowedSamples>0 then
            tooltip:AddLine(("Disenchant research: %d exact + %d nearby (%.1f effective / %d)"):format(
                decision.deStats.exactSamples or 0,decision.deStats.borrowedSamples,
                decision.deStats.effectiveSamples or n,LA.ProcessingMinimum and LA:ProcessingMinimum() or 30),.56,.81,1,true)
        else
            tooltip:AddLine(("Disenchant research: %d / %d matching samples"):format(n,
                LA.ProcessingMinimum and LA:ProcessingMinimum() or 30),.56,.81,1,true)
        end
    end
    -- Profession progression stays strictly informational: it never changes
    -- the highest-gold action or fabricates discovery/skill-up chances.
    if #progress>0 then
        for i=1,math.min(#progress,3) do
            tooltip:AddLine("Profession: "..progress[i],.67,.85,.97,true)
        end
    end
    if LA.db.showDisenchantStatus and decision.disenchantEligible
        and decision.action~="D" then
        local note=decision.deIssue or (decision.canDisenchant
            and "Disenchant candidate; outcome probabilities may be unknown"
            or "Disenchant requires a verified eligible character")
        tooltip:AddLine(note,.69,.56,.82,true)
    end
    if LA.db.showProfessionHints and LA.ProfessionAlternatives and decision.facts then
        local options=LA:ProfessionAlternatives(decision.facts,decision)
        for i=1,math.min(#options,4) do
            local option=options[i]
            tooltip:AddLine("Profession: "..option.description,.73,.78,.92,true)
            if LA.db.showAltHints and LA.MatchingCharacters then
                local matches=LA:MatchingCharacters(option.profession)
                if #matches>0 then
                    local labels={}
                    for j=1,math.min(3,#matches) do
                        local char=matches[j]
                        labels[#labels+1]=char.name.." (profession known; recipe may not be)"
                    end
                    tooltip:AddLine("Known characters: "..table.concat(labels,", "),.67,.75,.85,true)
                end
            end
        end
    end
    local token=decision.tokenInfo
    if compactToken then
        local groups=LA:ATTTokenClassSummary(token)
        if #groups>0 then
            tooltip:AddLine("Class sets",.68,.82,1,true)
            local bestRecipient
            for _,group in ipairs(groups) do
                -- An ATT reward belonging to another class is not necessarily
                -- usable by the current character or by an enabled alt.
                local recipient
                if group.missing>0 and LA.TokenTransmogRecipient then
                    recipient=LA:TokenTransmogRecipient(decision.facts,
                        {rewards=group.ids,kind=token.kind})
                end
                local letter=recipient and "T" or
                    (group.unknown==0 and group.missing==0 and decision.vendor>0 and "V" or "?")
                if recipient and not bestRecipient then bestRecipient=recipient end
                local actionColor=letter=="?" and "|cffaaaaaa" or LA:MarkupColor(letter)
                local icon=group.class~="UNKNOWN" and LLClassIcon(group.class) or ""
                if group.class~="UNKNOWN" and icon=="" then
                    icon="["..(group.className or group.class or "Class").."] "
                end
                local status=("%d/%d"):format(group.collected,group.count)
                if group.unknown>0 then status=status.." ?" end
                local className=group.title
                if className=="Equipment set" then className=(group.className or "Other").." equipment" end
                local left=("%s%s|r %s|cffa788dd%s|r"):format(
                    actionColor,letter,icon,className)
                if tooltip.AddDoubleLine then
                    tooltip:AddDoubleLine(left,status,1,1,1,1,1,1)
                else
                    tooltip:AddLine(left.."  "..status,1,1,1,true)
                end

            end
            -- Just ONE concrete target, rather than printing every reward.
            -- This recommendation is collection-driven, not a made-up
            -- valuation of an unpriced exchange chain.
            local recipient=decision.transmogRecipient or bestRecipient
            if recipient and recipient.rewardID then
                local item=LLTokenRewardLabel(recipient.rewardID)
                if item then
                    local who=recipient.current and "current character"
                        or (recipient.displayName or "eligible alt")
                    -- Class icon comes from the eligible recipient or
                    -- from ATT's verified reward-to-class set relationship.
                    local class=recipient.class
                    if type(class)~="string" then
                        for _,group in ipairs(groups) do
                            for _,rewardID in ipairs(group.ids or {}) do
                                if rewardID==recipient.rewardID then
                                    class=group.class
                                    break
                                end
                            end
                            if class then break end
                        end
                    end
                    local icon=class and LLClassIcon(class) or ""
                    tooltip:AddLine("  Get "..icon..item.." |cff80decf"..who.."|r",.80,.86,1,true)
                end
            end
        end
        if detail>=2 and LA.db.showResearchDetails==true and LA.db.showATTTokenSummary~=false then
            tooltip:AddLine(token.kind=="exchange"
                and "Exchange may require additional items or currency"
                or "Reward quantities or chances not verified",.72,.70,.76,true)
        end
        -- The LAST rows compare actual redeemable equipment, never the
        -- guaranteed price of selling the token itself. Show the full item
        -- name rather than a slot abbreviation or an anonymous reward ID.
        local bestVendor=LA.TokenBestVendorReward and LA:TokenBestVendorReward(token)
        if bestVendor then
            two("Best reward vendor: "..(LLTokenRewardLabel(bestVendor.itemID)
                or bestVendor.name or ("Item "..bestVendor.itemID)),
                LA:Money(bestVendor.value),"V")

        end
    elseif token then
        -- If the compact summary is deliberately off, preserve useful
        -- recommendations but do not create an unsolicited item dump.
        if token.kind=="exchange" and detail>=2 and LA.db.showResearchDetails==true and LA.db.showATTTokenSummary~=false then
            tooltip:AddLine("Exchange may require other items",.70,.68,.77,true)
        end
        if decision.action=="T" and decision.transmogRecipient then
            local recipient=decision.transmogRecipient
            tooltip:AddLine(recipient.current and "Keep for transmog on this character"
                or ("Send to "..(recipient.displayName or "eligible alt").." for transmog"),
                .51,.90,.80,true)
        end
    end
    if decision.tokenInfo and decision.blocked=="No TSM price" then
        tooltip:AddLine("AH pricing unavailable (TSM)",.95,.6,.35)
    end
end

-- Only a literal Warbound binding line from the item tooltip can supplement
-- missing bag-location binding metadata. Never infer transfer from the static
-- template's Bind-on-Pickup flag or from unrelated descriptive text.
local function TooltipWarbound(data,tooltip)
    local lines=data and data.lines
    local bindingTexts={ ["Warbound"]=true,["Warbound until Equipped"]=true,
        ["Warbound Until Equipped"]=true }
    local soulbound=false
    local warbound=false
    local function Visit(text)
        if type(text)~="string" or (issecretvalue and issecretvalue(text)) then return end
        text=text:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
        if text=="Soulbound" then soulbound=true end
        if bindingTexts[text] then warbound=true end
    end
    if type(lines)=="table" then
        for _,line in ipairs(lines) do if type(line)=="table" then Visit(line.leftText) end end
    end
    -- Tooltip can contain a line that wasn't present in its source data.
    if tooltip and type(tooltip.GetNumLines)=="function" and type(tooltip.GetName)=="function" then
        local ok,n=pcall(tooltip.GetNumLines,tooltip)
        local name=tooltip:GetName()
        if ok and type(n)=="number" and type(name)=="string" then
            for i=1,math.min(n,35) do
                local font=_G and _G[name.."TextLeft"..i]
                if font and type(font.GetText)=="function" then
                    local good,text=pcall(font.GetText,font)
                    if good then Visit(text) end
                end
            end
        end
    end
    return warbound and not soulbound
end

-- The first badge pass happens before anyone hovers the item. For a known
-- equipment token, inspect Blizzard's NON-VISIBLE tooltip data for the actual
-- bag slot. Do not build/show a GameTooltip and do not treat a static binding
-- template as transferable; the instance must explicitly say Warbound.
function LA:VerifyTokenWarboundFromBag(f)
    local ctx=f and f.context
    if not ctx or ctx.verifiedWarbound or ctx.isSoulbound or ctx.guild then return end
    local bag,slot=ctx.bagID,ctx.slotID
    if type(bag)~="number" or type(slot)~="number" or slot<1 then return end
    if not (C_TooltipInfo and type(C_TooltipInfo.GetBagItem)=="function") then return end
    local ok,data=pcall(C_TooltipInfo.GetBagItem,bag,slot)
    if not ok or type(data)~="table" then return end
    -- A pooled bag button can be re-used between frames. Never borrow a
    -- binding line from the previous occupant of the same slot.
    if type(data.id)=="number" and not (issecretvalue and issecretvalue(data.id))
        and data.id~=f.id then return end
    if TooltipWarbound(data,nil) then
        ctx.verifiedWarbound=true
        ctx.isBoundToAccount=true
        ctx.verifiedUnbound=false
    end
end

local function TooltipItem(tooltip, data)
    if not LA.db or not LA.db.showTooltips or not tooltip then return end
    local link
    if TooltipUtil and TooltipUtil.GetDisplayedItem then
        local _, l = TooltipUtil.GetDisplayedItem(tooltip)
        link = l
    end
    if not link and tooltip.GetItem then _, link = tooltip:GetItem() end
    if not link and data and data.id then
        local fn = C_Item and C_Item.GetItemInfo or GetItemInfo
        if fn then _, link = fn(data.id) end
    end
    if not link then return end
    local owner = tooltip.GetOwner and tooltip:GetOwner()
    local decision
    for _ = 1, 7 do
        if not owner then break end
        if owner.laLink == link then decision = owner.laDecision; break end
        local button = owner.button
        if button and button.laLink == link then decision = button.laDecision; break end
        owner = owner.GetParent and owner:GetParent()
    end
    -- The visible tooltip may include a restriction that GetHyperlink/BagItem
    -- did not expose. If confirmed, discard an earlier bag badge decision so
    -- neither the recommendation NOR any DE material rows can leak through.
    local visibleRestriction=LA.ObserveVisibleDisenchantRestriction
        and LA:ObserveVisibleDisenchantRestriction(link,data,tooltip)
    if visibleRestriction then
        local context=decision and decision.facts and decision.facts.context or {}
        decision=LA:Evaluate(link,context)
    end
    -- When the visible item tooltip explicitly says Warbound, it supplies
    -- instance-level transfer evidence even on a bank tooltip without a bag
    -- slot. Soulbound lines win and prevent this fallback.
    if TooltipWarbound(data,tooltip) then
        local prior=decision and decision.facts and decision.facts.context or {}
        if not prior.verifiedWarbound and not prior.isSoulbound then
            local ctx={}
            for k,v in pairs(prior) do ctx[k]=v end
            ctx.verifiedWarbound=true
            ctx.isBoundToAccount=true
            decision=LA:Evaluate(link,ctx)
        end
    end
    -- Bag snapshots can precede the Warbound tooltip text. Once a visible
    -- tooltip confirms the item's transferability, update the SAME item's
    -- badge as well as its tooltip; never perform any inventory action.
    if decision and owner then
        local button=owner
        for _=1,7 do
            if not button then break end
            if button.laLink==link and button.laDecision then
                if button.laDecision~=decision then LA:Paint(button,link,decision) end
                break
            end
            if button.button and button.button.laLink==link and button.button.laDecision then
                if button.button.laDecision~=decision then LA:Paint(button.button,link,decision) end
                break
            end
            button=button.GetParent and button:GetParent()
        end
    end
    -- Unparented tooltips may not have any bag-item binding context. Use the
    -- item's bind-on-pickup definition rather than treating absent context as
    -- evidence an item can be auctioned.
    decision = decision or LA:Evaluate(link, {})
    if not decision then return end
    return LA:AppendRecommendationTooltip(tooltip,decision)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, event, name)
    if event == "PLAYER_LOGIN" then
        HookBetterBags()
        if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
            and Enum and Enum.TooltipDataType then
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, TooltipItem)
        end
    elseif name == "BetterBags" then
        HookBetterBags()
    end
end)
