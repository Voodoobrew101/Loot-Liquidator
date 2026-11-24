local _, LA = ...
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
    button.laBetterBagsData=nil
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

-- All expensive recommendations remain accurate, but one lookup may
-- exceed an entire frame's budget by itself. A timer cannot interrupt a
-- running Lua lookup. Use bounded batches and resume on the next frame.
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
local function RememberBadgeDecision(fingerprint,decision,now)
    if not recentBadgeDecisions[fingerprint]then
        if recentBadgeCount>=400 then
            local oldestKey,oldestAt
            for key,entry in pairs(recentBadgeDecisions)do
                if now-entry.at>=30 then
                    recentBadgeDecisions[key]=nil;recentBadgeCount=recentBadgeCount-1
                elseif not oldestAt or entry.at<oldestAt then
                    oldestKey,oldestAt=key,entry.at
                end
            end
            if recentBadgeCount>=400 and oldestKey then
                recentBadgeDecisions[oldestKey]=nil;recentBadgeCount=recentBadgeCount-1
            end
        end
        recentBadgeCount=recentBadgeCount+1
    end
    recentBadgeDecisions[fingerprint]={result=decision,at=now}
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
            if (job.data and current~=job.link)
                or BadgeFingerprint(job.link,job.data,job.context)~=job.fingerprint then
                LA:ClearButton(button)
            elseif not button.IsVisible or button:IsVisible() then
                local t=BadgeTime()
                local ctx=job.data and GetContext(job.data) or job.context or {}
                ctx._LLFastBadge=true -- fast path for queued bag badges
                local previousFacts=button.laLink==job.link and button.laBadgeFingerprint==job.fingerprint
                    and button.laDecision and button.laDecision.facts or nil
                local decision=LA:Evaluate(job.link,ctx,previousFacts)
                LA:Paint(button,job.link,decision)
                local fingerprint=job.fingerprint
                button.laBadgeFingerprint=fingerprint
                if decision and not (decision.facts and decision.facts.itemInfoPending) then
                    RememberBadgeDecision(fingerprint,decision,GetTime and GetTime() or 0)
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
        -- Yield after the budget; an individual lookup cannot be interrupted.
        C_Timer.After(0,ProcessBadgeJobs)
    end
end
local function QueueBetterBagsBadge(button,link,data,context,force)
    if not button then return end
    if not link then
        pendingBadgeJobs[button]=nil
        LA:ClearButton(button)
        return
    end
    -- Keep the host's actual instance data for forced refreshes. Rebuilding an
    -- identity from decision.facts.context loses the GUID and can substitute
    -- derived binding flags, briefly hiding D on an unchanged item each cast.
    if data then button.laBetterBagsData=data end
    local fingerprint=BadgeFingerprint(link,data,context)
    local retryingItemInfo=button.laLink==link and button.laDecision
        and button.laDecision.facts and button.laDecision.facts.itemInfoPending
    -- Do not re-evaluate the same instance when BetterBags repaints a section.
    if not force and button.laLink==link and button.laDecision
        and button.laBadgeFingerprint==fingerprint and not pendingBadgeJobs[button] and not retryingItemInfo then
        perf.repeatSkips=perf.repeatSkips+1
        return
    end
    if not force and not retryingItemInfo then
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
        local previousFacts=button.laLink==link and button.laBadgeFingerprint==fingerprint
            and button.laDecision and button.laDecision.facts or nil
        LA:Paint(button,link,LA:Evaluate(link,ctx,previousFacts))
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
        button.laBetterBagsData=data
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

function LA:RequestBadgeRefresh(itemID,pendingOnly)
    -- Refresh already-painted buttons immediately without requiring bag sorts.
    -- The next bag update revalidates item contents and instance binding.
    for button in pairs(activeButtons) do
        -- Blizzard buttons are refreshed by QueueBlizzardBagRefresh().
        if not button.laBlizzardBag and not button.laGuildBank then
        local link=button.laLink
        local last=button.laDecision
        local data=button.laBetterBagsData
        local matches=not itemID or last and last.facts and last.facts.id==itemID
            and (not pendingOnly or last.facts.itemInfoPending)
        if matches and data then
            QueueBetterBagsBadge(button,data.itemInfo and data.itemInfo.itemLink,data,nil,true)
        elseif matches and link and last then
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
-- Loot Liquidator rows is changed; TSM's own tooltips remain untouched.
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
-- Sort a display copy; valuation models are cached and must retain their order.
local EMPTY={}
local tooltipSortFields={value='netExpectedValue',chance='chance',quantity='expectedQuantity'}
local tooltipMethodLetters={Disenchant='D',Mill='M',Prospect='P',Smelt='S'}
function LA:SortedTooltipMaterials(materials)
    local mode=self.db and self.db.tooltipOutputSort or 'value'
    if not tooltipSortFields[mode] and mode~='name' and mode~='database' then mode='value' end
    local result={}
    if mode=='database' then
        for i,material in ipairs(materials or EMPTY)do result[i]=material end
        return result
    end
    local positions,names={},mode=='name' and {} or nil
    local duplicates=false
    local info=C_Item and C_Item.GetItemInfo or GetItemInfo
    for i,m in ipairs(materials or EMPTY) do
        result[i]=m
        if positions[m]then duplicates=true end
        positions[m]=i
        if mode=='name' and type(info)=='function' then
            local ok,name=pcall(info,m.id)
            if ok and type(name)=='string' then names[m]=name:lower() end
        end
    end
    -- A caller can repeat the very same material object. Only that rare case
    -- needs per-occurrence wrappers to preserve its original tie order.
    if duplicates then for i,material in ipairs(result)do result[i]={material=material,index=i}end end
        table.sort(result,function(a,b)
            local am,bm=duplicates and a.material or a,duplicates and b.material or b
            local av,bv
            if mode=='name' then av,bv=names[am],names[bm]
            else
                av,bv=am[tooltipSortFields[mode]],bm[tooltipSortFields[mode]]
                if type(av)~='number' or av~=av then av=nil end
                if type(bv)~='number' or bv~=bv then bv=nil end
            end
            if av~=bv then
                if av==nil then return false end
                if bv==nil then return true end
                if mode=='name' then return av<bv end
                return av>bv
            end
            local ai,bi=am.id or 0,bm.id or 0
            if ai~=bi then return ai<bi end
            if duplicates then return a.index<b.index end
            return positions[am]<positions[bm]
        end)
    if duplicates then for i,row in ipairs(result)do result[i]=row.material end end
    return result
end

local function MaterialDisplay(self,materialID,pooledQuality)
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
        if ok and (type(value)=='number' and value==value and value>0 and value<=2147483647 and value%1==0
            or type(value)=='string' and value~='') then icon=value end
    end
    if not icon then
        local instant=C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
        if type(instant)=='function' then
            local ok,itemID,itemType,itemSubType,equipLoc,value=pcall(instant,materialID)
            if ok and (type(value)=='number' and value==value and value>0 and value<=2147483647 and value%1==0
                or type(value)=='string' and value~='') then icon=value end
        end
    end
    local prefix=("|T%s:14:14:0:0|t "):format(tostring(icon or 134400))
    -- Blizzard profession reagent quality is independent of ITEM_QUALITY_COLORS.
    -- It has its own small pip atlas, shown immediately after the item icon.
    -- Only use known rank-to-itemID mappings, never guess from item rarity.
    local rank=self.MaterialReagentRanks and self.MaterialReagentRanks[materialID]
    -- Retail exposes crafting reagent quality directly. Never infer it
    -- from the ID order or from ordinary green/blue/purple item rarity.
    local reagentInfo
    if C_TradeSkillUI and type(C_TradeSkillUI.GetItemReagentQualityInfo)=="function" then
        local ok,result=pcall(C_TradeSkillUI.GetItemReagentQualityInfo,materialID)
        if ok and type(result)=="table" then reagentInfo=result end
    end
    local nativeItems=self.ItemDB and self.ItemDB.professionProfiles and self.ItemDB.professionProfiles.items
    local nativeItem=nativeItems and nativeItems[materialID]
    if type(name)~='string' or name=='' then name=nativeItem and nativeItem.name end
    if type(name)~='string' or name=='' then name=nil end
    rank=rank or (reagentInfo and reagentInfo.quality) or (nativeItem and nativeItem.qualityRank)
    if type(rank)~='number' or rank~=rank or rank<1 or rank>5 or rank%1~=0 then rank=nil end
    if rank and not pooledQuality then
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
    return prefix..label,name,icon
end

local function finiteNonnegative(value)
    return type(value)=='number' and value==value and value>=0 and value<math.huge
end
local function positiveInteger(value)
    return finiteNonnegative(value) and value>0 and value<=2147483647 and value%1==0
end
local function tooltipQuantity(value)
    return finiteNonnegative(value) and value<=2147483647 and value%1==0
end
local function tooltipSame(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for key,value in pairs(a)do if not tooltipSame(value,b[key])then return false end end
    for key in pairs(b)do if a[key]==nil then return false end end
    return true
end
local function tooltipContextMatches(record,context,version,build,mechanicsApplied)
    if record.clientVersion and record.clientVersion~=version
        or record.targetBuild and tostring(record.targetBuild)~=tostring(build)
        or record.mechanicsSourceBuild and tostring(record.mechanicsSourceBuild)~=tostring(build) and not mechanicsApplied
        or record.patchStartBuild and (not tonumber(build) or tonumber(build)<record.patchStartBuild)then return false end
    local skill=context.skill or context.baseSkill or context.effectiveSkill
    if record.minimumRecipeSkill and (not finiteNonnegative(skill) or skill<record.minimumRecipeSkill)then return false end
    for key,value in pairs(record.referenceConditions or EMPTY)do if not tooltipSame(context[key],value)then return false end end
    return true
end
local function tooltipFamily(items,id)
    local item=items[id]
    if not item then return nil end
    if positiveInteger(item.qualityFamilyID)then return 'family:'..item.qualityFamilyID end
    if positiveInteger(item.modifiedCraftingReagentItemID)then return 'reagent:'..item.modifiedCraftingReagentItemID end
end
local function tooltipOneFamily(items,ids)
    local key
    for _,id in ipairs(ids or EMPTY)do
        local nextKey=tooltipFamily(items,id)
        if not nextKey or key and key~=nextKey then return nil end
        key=nextKey
    end
    return key
end
local function tooltipSameIDs(a,b)
    if type(a)~='table' or type(b)~='table' or #a~=#b or #a==0 then return false end
    for _,id in ipairs(a)do
        local found=false for _,other in ipairs(b)do if other==id then found=true;break end end
        if not found then return false end
    end
    return true
end
local function tooltipField(source,key)
    local value=source[key]
    if type(value)~='table' or value.status=='unknown' or value.status=='contradictory' then return nil,nil end
    return value.value,finiteNonnegative(value.confidence)and math.min(100,value.confidence)or 0
end
local function tooltipEstimatedEvidence()return{kind='display-estimate',confidence=0,displayOnly=true}end
local function ChanceText(chance)
    if not finiteNonnegative(chance) or chance>1 then return nil end
    if chance==0 then return '0%' end
    if chance>=1-1e-12 then return '100%' end
    if chance<.001 then return '<0.1%' end
    if chance>.999 then return '>99.9%' end
    return ('%.1f'):format(chance*100):gsub('%.0$','')..'%'
end
-- Complete display fields from already loaded baselines. Processing quantities,
-- values and the original evidence/model tables remain unchanged.
local function BaselineTooltipMaterialFields(self,material,model,option,facts)
    if type(material)~='table' or type(model)~='table' or type(option)~='table' or type(facts)~='table'
        or not positiveInteger(facts.id) or not positiveInteger(material.id)
        or material.structuralZero and material.probabilityBasis=='specialization-eligibility-zero'
        or material.conditionalExpectedQuantity~=nil and material.expectedQuantity==nil then return material end
    local needLo,needHi=not tooltipQuantity(material.minQuantity),not tooltipQuantity(material.maxQuantity)
    local needChance=not (finiteNonnegative(material.chance) and material.chance<=1)
    if not needLo and not needHi and not needChance then return material end
    local batch=model.inputCount or option.inputCount
    local records=self._evidenceIndex and self._evidenceIndex[tostring(option.name)..':'..tostring(facts.id)]
    if option.name=='Disenchant' and self.DisenchantCategoryKey and self._evidenceIndex then
        local key=self:DisenchantCategoryKey(facts)
        local category=key and self._evidenceIndex['Disenchant:'..key]
        if category then
            local combined={}
            for _,record in ipairs(records or {})do combined[#combined+1]=record end
            for _,record in ipairs(category)do
                local lo,hi=record.categoryItemLevelMin,record.categoryItemLevelMax
                if lo==nil or finiteNonnegative(facts.itemLevel) and facts.itemLevel>=lo and facts.itemLevel<=hi
                    or facts.itemLevel==nil and lo==1 and hi==999 then combined[#combined+1]=record end
            end
            records=combined
        end
    end
    if not positiveInteger(batch) then return material end
    if type(records)~='table' then
        if needLo or needHi then return material end
        records={} -- The selected model already supplies both quantity bounds.
    end
    local data=self.ItemDB and self.ItemDB.professionProfiles or EMPTY
    local items=data.items or EMPTY
    local inputRank=facts.reagentQuality or facts.inputQuality or (items[facts.id] and items[facts.id].qualityRank)
    local mode=option.dataMode or (self.ProcessingMethodMode and self:ProcessingMethodMode(option.letter or
        tooltipMethodLetters[option.name] or 'C'))
    local version,build
    if GetBuildInfo then version,build=GetBuildInfo() end
    local context=model.projectedContext or model.context or facts.context or EMPTY
    if type(material.rankIDs)=='table' and #material.rankIDs>1 and not tooltipOneFamily(items,material.rankIDs)then return material end
    local mean=material.expectedQuantity
    local function fits(p,lo,hi)
        return finiteNonnegative(p) and p<=1 and finiteNonnegative(mean) and mean>0
            and tooltipQuantity(lo) and lo>0 and tooltipQuantity(hi) and hi>=lo
            and mean+1e-9>=p*lo and mean<=p*hi+1e-9
    end
    local bestRange,bestChance
    local function consider(record,p,pc,lo,lc,hi,hc,kind,allowChance,allowMidpoint)
        local nextLo=needLo and lo or material.minQuantity
        local nextHi=needHi and hi or material.maxQuantity
        if tooltipQuantity(nextLo) and nextLo>0 and tooltipQuantity(nextHi) and nextHi>=nextLo then
            local confidence=math.min(needLo and (lc or 0) or 100,needHi and (hc or 0) or 100)
            local priority=kind=='baseline-family' and 1 or 2
            if (needLo or needHi) and (not bestRange or priority>bestRange.priority
                or priority==bestRange.priority and confidence>bestRange.confidence) then
                bestRange={lo=nextLo,hi=nextHi,lc=lc,hc=hc,confidence=confidence,recordID=record.recordID,kind=kind,allowMidpoint=allowMidpoint,priority=priority}
            end
            if needChance and allowChance and fits(p,nextLo,nextHi)
                and (not bestChance or (pc or 0)>bestChance.confidence) then
                bestChance={value=p,confidence=pc or 0,recordID=record.recordID,kind=kind}
            end
        end
    end
    for _,record in ipairs(records) do
        local conditions=record.researchConditions or EMPTY
        local enabled=self.EvidenceSourceWeight and self:EvidenceSourceWeight(record.sourceKey,mode)>0
        local matchesInput=record.inputItemID==facts.id or option.name=='Disenchant'
            and self.DisenchantCategoryKey and record.gearKey==self:DisenchantCategoryKey(facts)
        if enabled and matchesInput and record.method==option.name and record.inputCount==batch
            and not record.operationUnverified and record.quantityBasis~='per-input'
            and (not record.recipeID or not option.recipeID or record.recipeID==option.recipeID)
            and (not record.expansionID or record.expansionID==facts.expansionID
                or record.expansionID==0 and conditions.expansionIDKnown==false)
            and (not record.inputQualityRank or record.inputQualityRank==inputRank)
            and (not record.inputRarity or record.inputRarity==facts.quality)
            and (not record.inputClassID or record.inputClassID==facts.classID)
            and #(record.unresolvedResearchConditions or EMPTY)==0
            and tooltipContextMatches(record,context,version,build,model.mechanicsApplied)
            and not (type(conditions.eligibilityStatus)=='string' and conditions.eligibilityStatus:find('REQUIRES_',1,true)) then
            for _,source in ipairs(record.materials or EMPTY) do
                local targetPool=type(material.rankIDs)=='table' and #material.rankIDs>1
                local sourcePool=type(source.rankIDs)=='table' and #source.rankIDs>1
                local exactPool=targetPool and sourcePool and tooltipSameIDs(material.rankIDs,source.rankIDs)
                local exact=not targetPool and not sourcePool and source.id==material.id
                local sourceFamily=sourcePool and tooltipOneFamily(items,source.rankIDs) or tooltipFamily(items,source.id)
                local targetFamily=targetPool and tooltipOneFamily(items,material.rankIDs) or tooltipFamily(items,material.id)
                local qualityFamily=sourceFamily and sourceFamily==targetFamily
                local exactVariant=false
                if not targetPool and sourcePool and sourceFamily then
                    for _,variant in ipairs(source.referenceVariants or EMPTY) do if variant.id==material.id then exactVariant=true;break end end
                end
                if exact or exactPool or qualityFamily or exactVariant then
                    local p,pc=tooltipField(source,'dropChance')
                    local lo,lc=tooltipField(source,'minQuantity');local hi,hc=tooltipField(source,'maxQuantity')
                    local allowMidpoint=not (source.dropChance and source.dropChance.inferenceBlocked or source.heldDropChance)
                    if not source.conditionalReference or model.outputGate and model.outputGate.eligible==true then
                        consider(record,p,pc,lo,lc,hi,hc,exact and 'baseline' or exactPool and 'baseline-pool' or 'baseline-family',exact or exactPool,allowMidpoint)
                    end
                    local variants=source.referenceVariants
                    if type(variants)=='table' then
                        local confidence=select(2,tooltipField(source,'expectedQuantity')) or 0
                        for _,variant in ipairs(variants) do
                            if variant.id==material.id and (not variant.sourceQuality or variant.sourceQuality==inputRank)
                                and (not targetPool or exactPool) then
                                local pooledChance=not sourcePool
                                if exactPool then
                                    pooledChance=true
                                    for _,other in ipairs(variants) do
                                        if other.matRate~=variant.matRate or other.minAmount~=variant.minAmount or other.maxAmount~=variant.maxAmount then pooledChance=false;break end
                                    end
                                end
                                consider(record,variant.matRate,confidence,variant.minAmount,confidence,variant.maxAmount,confidence,
                                    'baseline-variant',pooledChance,allowMidpoint)
                            end
                        end
                    end
                end
            end
        end
    end
    local out,evidence
    local function copy()
        if not out then out={} for key,value in pairs(material) do out[key]=value end;evidence={};out.tooltipFieldEvidence=evidence end
        return out
    end
    if bestRange then
        if needLo then copy().minQuantity=bestRange.lo;evidence.minQuantity={recordID=bestRange.recordID,confidence=bestRange.lc or 0,kind=bestRange.kind} end
        if needHi then copy().maxQuantity=bestRange.hi;evidence.maxQuantity={recordID=bestRange.recordID,confidence=bestRange.hc or 0,kind=bestRange.kind} end
    end
    local lo,hi=(out or material).minQuantity,(out or material).maxQuantity
    if needChance then
        if bestChance and fits(bestChance.value,lo,hi) then
            copy().chance=bestChance.value;out.chanceConfidence=bestChance.confidence;evidence.chance=bestChance
        elseif (bestRange and bestRange.allowMidpoint or not needLo and not needHi) and self.FillChanceOrAverage
            and finiteNonnegative(mean) and mean>0 and tooltipQuantity(lo) and lo>0 and tooltipQuantity(hi) and hi>=lo then
            local p,_,filled=self:FillChanceOrAverage(nil,mean,lo,hi)
            if filled=='chance' and fits(p,lo,hi) then
                local confidence=math.min(material.confidence or model.confidence or 0,
                    evidence and evidence.minQuantity and evidence.minQuantity.confidence or 100,
                    evidence and evidence.maxQuantity and evidence.maxQuantity.confidence or 100)
                copy().chance=p;out.chanceConfidence=math.floor(confidence*(self.FILLED_CONFIDENCE_FACTOR or .5)+.5)
                evidence.chance={kind='midpoint',recordID=bestRange and bestRange.recordID,confidence=out.chanceConfidence}
            end
        end
    end
    return out or material
end
-- The owner permits best-effort presentation estimates. These copies are never
-- passed to valuation: actual means, prices, source fields and decisions stay put.
function LA:TooltipMaterialDisplayFields(material,model,option,facts)
    if type(material)~='table' or not positiveInteger(material.id) then return material end
    if material.structuralZero==true and material.probabilityBasis=='specialization-eligibility-zero' then return material end
    if material.communityPossibleOutput and material.expectedQuantity==nil then
        local unknown={}
        for key,value in pairs(material) do unknown[key]=value end
        unknown.tooltipUnknownChance=true;unknown.tooltipUnknownRange=true
        return unknown
    end
    local display=BaselineTooltipMaterialFields(self,material,model,option,facts)
    local chance,lo,hi=display.chance,display.minQuantity,display.maxQuantity
    local hasChance=finiteNonnegative(chance) and chance<=1
    local hasLo,hasHi=tooltipQuantity(lo),tooltipQuantity(hi)
    if hasChance and hasLo and hasHi and hi>=lo then return display end
    local out,evidence={},{}
    for key,value in pairs(display)do out[key]=value end
    for key,value in pairs(display.tooltipFieldEvidence or EMPTY)do evidence[key]=value end
    out.tooltipFieldEvidence=evidence
    local mean=finiteNonnegative(display.expectedQuantity) and display.expectedQuantity or nil
    if mean==nil and finiteNonnegative(display.conditionalExpectedQuantity) then mean=display.conditionalExpectedQuantity end
    local knownRange=hasLo and hasHi and hi>=lo
    local units=mean
    local guessLo,guessHi=0,0
    if units and units>0 or hasChance and chance>0 then
        local amount=math.min(units or 1,2147483647)
        guessLo=math.max(1,math.floor(amount));guessHi=math.max(guessLo,math.ceil(amount))
    end
    if not hasLo then lo=hasHi and math.min(hi,guessLo) or guessLo end
    if not hasHi then hi=math.max(lo,guessHi) end
    if hi<lo then lo,hi=hi,lo;hasLo,hasHi=false,false end
    if mean==nil and not hasChance and (not hasLo or not hasHi) then
        out.tooltipUnknownRange=true
        if not hasLo then evidence.minQuantity={kind='display-unknown',confidence=0,displayOnly=true}end
        if not hasHi then evidence.maxQuantity={kind='display-unknown',confidence=0,displayOnly=true}end
    else
        if not hasLo then out.minQuantity=lo;evidence.minQuantity=tooltipEstimatedEvidence()end
        if not hasHi then out.maxQuantity=hi;evidence.maxQuantity=tooltipEstimatedEvidence()end
    end
    if not hasChance then
        local p,average,filled
        if knownRange and mean and mean>0 and lo>0 and self.FillChanceOrAverage then
            p,average,filled=self:FillChanceOrAverage(nil,mean,lo,hi)
            if finiteNonnegative(p) and (mean+1e-9<p*lo or mean>p*hi+1e-9) then filled=nil end
        end
        out.chance=finiteNonnegative(p) and math.min(1,p) or mean and math.min(1,mean) or nil
        if mean==nil then out.tooltipUnknownChance=true end
        local support=display.confidence or model and model.confidence or 0
        if not finiteNonnegative(support) then support=0 end
        out.chanceConfidence=filled=='chance' and math.floor(math.min(100,support)*(self.FILLED_CONFIDENCE_FACTOR or .5)+.5) or 0
        evidence.chance={kind=filled=='chance' and 'midpoint' or mean==nil and 'display-unknown' or 'display-estimate',
            confidence=out.chanceConfidence,displayOnly=true}
    end
    return out
end
-- One material layout, including presentation estimates and pending metadata.
-- Gold uses actual valuation quantities and net quotes, never display estimates.
function LA:FormatTooltipMaterialRow(material,model,option,facts)
    if type(material)~='table' then return nil end
    material=self:TooltipMaterialDisplayFields(material,model,option,facts)
    -- A proven specialization lock has no possible output. Supply its display
    -- zero locally; a missing market quote alone never establishes this case.
    local eligibilityZero=material.structuralZero==true
        and material.probabilityBasis=='specialization-eligibility-zero'
    local amount=ChanceText(eligibilityZero and 0 or material.chance)
        or material.tooltipUnknownChance and '?%'
    local display=MaterialDisplay(self,material.id,
        type(material.rankIDs)=='table' and #material.rankIDs>1)
    local lo,hi=material.minQuantity,material.maxQuantity
    if eligibilityZero then lo,hi=0,0 end
    local range=''
    if finiteNonnegative(lo) and finiteNonnegative(hi)
        and lo<=2147483647 and hi<=2147483647 and lo%1==0 and hi%1==0 and hi>=lo then
        range=(self:MarkupColor(option and option.letter or 'D') or '')..
            (lo==hi and (' [%d]'):format(lo) or (' [%d-%d]'):format(lo,hi))
    elseif material.tooltipUnknownRange then
        range=' [?]'
    end
    local batch=model and model.inputCount or option and option.inputCount or 1
    local price=''
    local expectedValue=eligibilityZero and 0 or material.netExpectedValue
    if not finiteNonnegative(expectedValue) and finiteNonnegative(material.expectedQuantity) then
        if material.expectedQuantity==0 then expectedValue=0
        else
            local quote=material.netUnitPrice
            if not finiteNonnegative(quote) and self.GetMaterialPrice then quote=self:GetMaterialPrice(material) end
            if finiteNonnegative(quote) then expectedValue=material.expectedQuantity*quote end
        end
    end
    if positiveInteger(batch) and finiteNonnegative(expectedValue) then
        local ok,value=pcall(self.Money,self,expectedValue/batch)
        if ok and type(value)=='string' then price=value end
    end
    return '  '..(amount and amount..' ' or '')..display..range,price
end

function LA:AppendRecommendationTooltip(tooltip,decision)
    -- B3: tooltip level 0 = Off (badges still show).
    if not LA.db or (LA.db.tooltipDetail or 2)<=0 or not tooltip or not decision then return end
    local method=decision.method
    local names={A="Auction",V="Vendor",D="Disenchant",M="Mill",P="Prospect",
        S="Smelt",C=method or "Craft/refine",Q="Insufficient Data",T="Transmog"}
    local label=names[decision.action]
    local compactToken=decision.tokenInfo
        and type(LA.TokenClassSummary)=="function"
    local detail=LA.db.tooltipDetail or 2
    local showResearch=LA.db.showResearchDetails==true
    local f=decision.facts
    local vendorKnown=finiteNonnegative(decision.vendor)
        and (decision.vendor>0 or not f or not f.itemInfoPending or f.itemInfoFromSnapshot)
    if not decision.action and (detail<2 or #(decision.conversionOptions or {})==0)
        then return end
    local function two(left,right,letter)
        local color=LA:MarkupColor(letter)
        if tooltip.AddDoubleLine then
            tooltip:AddDoubleLine(color..left.."|r",right or "",1,1,1,1,1,1)
        else
            tooltip:AddLine(color..left.."|r"..(right and "  "..right or ""))
        end
    end
    local function valued(label,unit,letter)
        if unit==nil then return end
        -- All prices are per original item, like TSM. Repeating '(each)'
        -- beside every method obscures the actual value comparison.
        two(label,LA:Money(unit),letter)
    end
    if label then
        tooltip:AddLine("|cff66ccffLoot Liquidator:|r "..
            LA:MarkupColor(decision.action)..label.."|r")
    end
    if detail<2 then return end -- Recommendation is exactly the action header.
    -- For tokens the guaranteed price belongs directly below the action,
    -- as it does for ordinary disenchant/vendor recommendations.  Do not
    -- repeat it after class sets or confuse it with a redeemed reward's price.
    if compactToken
        and vendorKnown then
        two("Vendor token (guaranteed)",LA:Money(decision.vendor),"V")
    end
    -- C4c: what opening the token is worth (piece's sell price / disenchant).
    local piece=decision.tokenPiece
    if piece and detail>=2 then
        local pieceName=piece.name or ("Item "..piece.itemID)
        local opening=decision.tokenInfo and decision.tokenInfo.kind=='exchange' and 'Exchange' or 'Open'
        if type(piece.vendor)=="number" then
            local label=opening..", then vendor "..pieceName
            if piece.vendorAvailable==false then label='Reward vendor estimate: '..pieceName end
            two(label,piece.vendor<0 and (LA:Money(-piece.vendor)..' net loss') or LA:Money(piece.vendor),"V")
        elseif type(piece.vendorGross)=='number' then
            two('Reward vendor before exchange costs: '..pieceName,LA:Money(piece.vendorGross),'V')
        end
        if type(piece.disenchant)=="number" and piece.disenchant>0 then
            local reward=piece.disenchantReward or piece
            local rewardName=reward.name or ("Item "..reward.itemID)
            local conf=type(piece.disenchantConfidence)=="number"
                and (" (Confidence "..math.floor(piece.disenchantConfidence+.5).."%)") or ""
            two(opening..", then disenchant "..rewardName..conf..(piece.disenchantAvailable==false and ' (unavailable estimate)' or ''),LA:Money(piece.disenchant),"D")
            local cost=reward.cost
            if cost and cost.known and cost.value>0 and
                (not piece.cost or cost.value/cost.inputCount~=piece.cost.value/piece.cost.inputCount) then
                two('Additional exchange costs per token (disenchant reward)',LA:Money(cost.value/cost.inputCount),'D')
            end
            if reward~=piece and reward.variantNote and reward.variantNote~=piece.variantNote then
                tooltip:AddLine('Disenchant reward: '..reward.variantNote,.73,.72,.78,true)
            end
        end
        if piece.cost and piece.cost.known and piece.cost.value>0 then
            two('Additional exchange costs per token (vendor reward)',LA:Money(piece.cost.value/piece.cost.inputCount),'V')
        end
        if piece.reason then tooltip:AddLine(piece.reason,.95,.68,.35,true) end
        if piece.current==false then tooltip:AddLine('Reward on '..piece.character,.68,.82,1,true) end
        if piece.variantNote then tooltip:AddLine(piece.variantNote,.73,.72,.78,true) end
    elseif decision.tokenInfo and decision.action=='Q' and decision.why then
        tooltip:AddLine(decision.why,.95,.68,.35,true)
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
        do -- B3: the Auction row is part of the Alternatives level
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
        if detail>=3 and showResearch and decision.operationSimulation then
            tooltip:AddLine("TSM preview only: assign this operation in TSM to post with it",1,.63,.24,true)
        end
        local options=decision.conversionOptions or {}
        if LA.TooltipConversionOptions and f and f.id then
            options=LA:TooltipConversionOptions(f,options)
        end
        local choices={}
        for _,option in ipairs(options) do
            -- Filter before choosing a recipe so an unavailable alternative
            -- cannot conceal a usable option for the same method.
            local profession=option.profession or ({Disenchant="Enchanting",Mill="Inscription",Prospect="Jewelcrafting",Smelt="Mining"})[option.name]
            local selection=profession and LA.db.professionTooltipProfiles and LA.db.professionTooltipProfiles[profession]
            if option.name and selection~="@hide" and (option.available~=false or option.eligibleInput or selection=="@hypothetical") then
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
        local function PrepareMaterials(option,model,inputFacts)
            local list=model and model.materials
            if type(list)~='table' then return nil end
            local prepared,confidence={}
            for _,material in ipairs(list) do
                local display=LA:TooltipMaterialDisplayFields(material,model,option,inputFacts)
                prepared[#prepared+1]=display
                for _,field in pairs(display.tooltipFieldEvidence or {}) do
                    if finiteNonnegative(field.confidence) and field.confidence<=100 then
                        confidence=math.min(confidence or 100,field.confidence)
                    end
                end
            end
            return LA:SortedTooltipMaterials(prepared),confidence
        end
        local function ShowMaterials(option,model,list)
            if detail<3 then return end
            for _,m in ipairs(list or {}) do
                local left,amount=LA:FormatTooltipMaterialRow(m,model,option)
                if left then two(left,amount,option.letter or 'D') end
            end
        end
        for _,methodName in ipairs(methodOrder) do
            local option=choices[methodName]
            -- A sword cannot acquire unrelated Prospect/Smelt rows merely
            -- because a Force On profession switch is set.
            local isGear=f and (f.classID==2 or f.classID==4 or f.classID==19)
            if option and (not isGear or methodName=="Disenchant")
                then -- Unavailable options are an explicit display opt-in.
                -- Reuse the exact evaluated material model used to price this option.
                local model=option.yieldModel
                local hasMaterials=model and model.materials and #model.materials>0
                if option.value or hasMaterials or option.eligibleInput
                    or ((option.category=="destroy" or option.category=="research-operation") and
                        (methodName=="Mill" or methodName=="Prospect"))
                    or (methodName=="Disenchant"
                    and decision.disenchantEligible)
                    or methodName=="Smelt" then
                    local prepared,fieldConfidence=PrepareMaterials(option,model,f)
                    local confidence=model and (model.valueConfidence or model.confidence)
                    if fieldConfidence and finiteNonnegative(confidence) then confidence=math.min(confidence,fieldConfidence) end
                    local label=names[methodName] or methodName
                    local profileLabel=option.tooltipProfileLabel
                        or model and model.context and model.context.character or option.character
                        or (LA.CharacterKey and LA:CharacterKey())
                    if profileLabel=='Current character' then
                        profileLabel=LA.CharacterKey and LA:CharacterKey()
                    end
                    if profileLabel then label=label.." — "..profileLabel end
                    if finiteNonnegative(confidence) and confidence<=100 and not model.confidenceUnscored then
                        label=label..(' (Confidence %d%%)'):format(math.floor(confidence+.5))
                    end
                    local communityPartial=model and model.communityOutputCoverageUnknown and model.unknownOutputs
                    if communityPartial then label=label..' (partial estimate)' end
                    two(label,type(option.value)=='number' and LA:Money(option.value) or '',option.letter or 'D')
                    ShowMaterials(option,model,prepared)
                    if communityPartial then
                        tooltip:AddLine(model.communityOutputCoverageReason or 'Other possible outputs remain unknown; value includes known outputs only.',.95,.68,.35,true)
                    end
                end
            end
        end
        if piece and piece.disenchantModel then
            tooltip:AddLine('Redeemed reward disenchant outputs (per reward)',.68,.82,1,true)
            local option={name='Disenchant',letter='D',inputCount=1}
            ShowMaterials(option,piece.disenchantModel,PrepareMaterials(option,piece.disenchantModel,
                piece.facts or piece.disenchantFacts or {id=piece.itemID}))
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
        if vendorKnown and not compactToken then
            valued("Vendor",decision.vendor,"V")
        end
    end
    local token=decision.tokenInfo
    if compactToken then
        local groups=LA:TokenClassSummary(token)
        if #groups>0 then
            tooltip:AddLine(token.recordID and token.recordID:find('^att%-nathria%-')
                and "Covenant rewards" or (token.protectCollection and "Gear rewards" or "Class sets"),.68,.82,1,true)
            local bestRecipient
            for _,group in ipairs(groups) do
                -- A token reward belonging to another class is not necessarily
                -- usable by the current character or by an enabled alt.
                local recipient
                if group.missing>0 and LA.TokenTransmogRecipient then
                    local classToken={}
                    for key,value in pairs(token) do classToken[key]=value end
                    classToken.rewards=group.ids
                    recipient=LA:TokenTransmogRecipient(decision.facts,classToken)
                end
                local letter=recipient and "T" or
                    (group.unknown==0 and group.missing==0 and decision.vendor>0 and "V" or "Q")
                if recipient and not bestRecipient then bestRecipient=recipient end
                local actionColor=letter=="Q" and "|cffaaaaaa" or LA:MarkupColor(letter)
                local icon=group.class~="UNKNOWN" and LLClassIcon(group.class) or ""
                if group.class~="UNKNOWN" and icon=="" then
                    icon="["..(group.className or group.class or "Class").."] "
                end
                local status=("%d/%d"):format(group.collected,group.count)
                if group.unknown>0 then status=status.." (collection pending)" end
                local className=group.title
                if token.protectCollection and group.class=="UNKNOWN" then className="Equipment appearances"
                elseif className=="Equipment set" then className=(group.className or "Other").." equipment" end
                local left=("%s%s|r %s|cffa788dd%s|r"):format(
                    actionColor,letter=='Q' and 'Review' or letter,icon,className)
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
                local item=LLTokenRewardLabel(LA:TokenRewardLink(token,recipient.rewardID))
                if item then
                    local who=recipient.current and "current character"
                        or (recipient.displayName or "eligible alt")
                    -- Class icon comes from the eligible recipient or
                    -- from the token catalog's reward-to-class set relationship.
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
        if token.protectCollection and decision.action=="Q" and decision.why then
            tooltip:AddLine(decision.why,.72,.70,.76,true)
        end
        if token.merchantName and token.costsComplete and detail>=2 then
            tooltip:AddLine("Exchange one curio at "..token.merchantName,.72,.70,.76,true)
        elseif detail>=2 and showResearch and not token.costsComplete then
            tooltip:AddLine(token.kind=="exchange"
                and "Exchange may require additional items or currency"
                or "Reward quantities or chances not verified",.72,.70,.76,true)
        end
        -- The LAST rows compare actual redeemable equipment, never the
        -- guaranteed price of selling the token itself. Show the full item
        -- name rather than a slot abbreviation or an anonymous reward ID.
        local bestVendor=LA.TokenBestVendorReward and LA:TokenBestVendorReward(token)
        if bestVendor then
            two("Highest listed reward vendor (before costs): "..(LLTokenRewardLabel(bestVendor.itemID)
                or bestVendor.name or ("Item "..bestVendor.itemID)),
                LA:Money(bestVendor.value),"V")

        end
    elseif token then
        -- If the compact summary is deliberately off, preserve useful
        -- recommendations but do not create an unsolicited item dump.
        if token.kind=="exchange" and detail>=2 and showResearch then
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
    if not LA.db or (LA.db.tooltipDetail or 2)<=0 or not tooltip then return end
    -- Pawn parses its private scanner's lines as item stats. Keep our rows
    -- out of that scan, while allowing its explicitly anchored debug view.
    local pawnName=PawnPrivateTooltipName
    if type(pawnName)=="string" and _G and tooltip==_G[pawnName]
        and tooltip.GetAnchorType and tooltip:GetAnchorType()=="ANCHOR_NONE" then return end
    local link
    if TooltipUtil and TooltipUtil.GetDisplayedItem then
        local _, l = TooltipUtil.GetDisplayedItem(tooltip)
        link = l
    end
    if not link and tooltip.GetItem then
        local _,itemLink = tooltip:GetItem()
        link = itemLink
    end
    if not link and data and data.id then
        local fn = C_Item and C_Item.GetItemInfo or GetItemInfo
        if fn then
            local _,itemLink = fn(data.id)
            link = itemLink
        end
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
eventFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
eventFrame:SetScript("OnEvent", function(_, event, name, success)
    if event == "PLAYER_LOGIN" then
        HookBetterBags()
        if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
            and Enum and Enum.TooltipDataType then
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, TooltipItem)
        end
    elseif event=="GET_ITEM_INFO_RECEIVED" then
        if type(name)=="number" and success~=false then LA:RequestBadgeRefresh(name,true) end
    elseif name == "BetterBags" then
        HookBetterBags()
    end
end)
