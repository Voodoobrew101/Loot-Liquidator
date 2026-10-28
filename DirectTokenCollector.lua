-- Passive, research-only collector for DIRECT equipment-token rewards.
-- Does NOT depend on ATT, reverse-crafting graphs, TSM or external catalogs.
-- Never changes recommendations; observations require offline validation before
-- they are compiled into the one authoritative GameData.lua.
local _, LL = ...
local MAX_LINKS, PAGE_SIZE = 2400, 65
local function Number(n)
    if type(n) ~= "number" or (issecretvalue and issecretvalue(n))
        or n ~= math.floor(n) or n <= 0 then return nil end
    return n
end
local function ItemID(link)
    if type(link) ~= "string" or (issecretvalue and issecretvalue(link)) then return nil end
    return Number(tonumber(link:match("item:(%d+)")))
end
local function ItemClass(id)
    if not id or not C_Item or not C_Item.GetItemInfoInstant then return nil end
    local ok,_,_,_,_,_,classID=pcall(C_Item.GetItemInfoInstant,id)
    if ok and type(classID)=="number" then return classID end
    return nil
end
local function Equipment(id)
    local class=ItemClass(id)
    -- Weapon and Armor only. Never add ingredient -> crafted-gear links.
    return class==2 or class==4
end
local function TokenInput(id)
    local class=ItemClass(id)
    -- Conservative research filter: avoid ordinary ores, cloth, herbs,
    -- enchanting dusts and other Trade Goods used for crafting.
    return class~=nil and class~=7
end
local function Store(self)
    if not self.db or self.db.collectTokenResearch==false then return nil end
    if type(self.db.directTokenResearch)~="table" then
        self.db.directTokenResearch={version=1,records={},created=(time and time()) or 0}
    end
    local s=self.db.directTokenResearch
    if type(s.records)~="table" then s.records={} end
    return s.records
end
local function Count(t)
    local n=0;for _ in pairs(t) do n=n+1 end;return n
end
local function Record(self,kind,inputID,rewardID,inputQty,rewardQty,otherCosts,vendorID)
    local store=Store(self)
    if not store or not TokenInput(inputID) or not Equipment(rewardID) then return false end
    inputQty=Number(inputQty);rewardQty=Number(rewardQty)
    if not inputQty or not rewardQty then return false end
    local key=kind..":"..inputID..":"..rewardID..":"..inputQty..":"..rewardQty
    local record=store[key]
    if not record then
        if Count(store)>=MAX_LINKS then return false end
        record={kind=kind,inputID=inputID,rewardID=rewardID,
            inputQuantity=inputQty,rewardQuantity=rewardQty,
            firstSeen=(time and time()) or 0,seen=0,
            evidence="candidate_observed_in_client",verified=false}
        store[key]=record
    end
    record.seen=math.min(100000,(record.seen or 0)+1)
    record.lastSeen=(time and time()) or 0
    if type(otherCosts)=="string" then record.otherCosts=otherCosts:sub(1,250) end
    if Number(vendorID) then record.vendorID=vendorID end
    return true
end
function LL:RecordDirectTokenObservation(kind,inputID,rewardID,inputQty,rewardQty,otherCosts,vendorID)
    return Record(self,kind,inputID,rewardID,inputQty,rewardQty,otherCosts,vendorID)
end
-- MERCHANT_SHOW / MERCHANT_UPDATE: One offered equipment item plus the actual
-- item-token cost in the Blizzard merchant window. Multiple costs are retained.
-- A listing is NOT proof of a successful purchase, class eligibility or an
-- unlocked appearance. These records never enter real-time valuations.
function LL:CollectMerchantTokenOffers()
    if not Store(self) or not GetMerchantNumItems or not GetMerchantItemLink
        or not GetMerchantItemCostInfo or not GetMerchantItemCostItem then return end
    local numOK,count=pcall(GetMerchantNumItems)
    if not numOK then return end
    if type(count)~="number" then return end
    local guid=UnitGUID and UnitGUID("npc")
    local vendorID=type(guid)=="string" and tonumber(guid:match("Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-%x+")) or nil
    for idx=1,math.min(200,count) do
        local linkOK,rewardLink=pcall(GetMerchantItemLink,idx)
        local rewardID=linkOK and ItemID(rewardLink) or nil
        if rewardID and Equipment(rewardID) then
            local info
            if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
                local ok,value=pcall(C_MerchantFrame.GetItemInfo,idx)
                if ok then info=value end
            end
            local rewardQty=info and Number(info.stackCount) or 1
            local countOK,total=pcall(GetMerchantItemCostInfo,idx)
            if not countOK then total=nil end
            if type(total)=="number" and total>0 and total<=20 then
                local tokens,other={},{}
                for ci=1,total do
                    local ok,_,amount,link,currencyName=pcall(GetMerchantItemCostItem,idx,ci)
                    if not ok then amount,link,currencyName=nil,nil,nil end
                    local costID=ItemID(link)
                    if costID and Number(amount) and TokenInput(costID) then
                        tokens[#tokens+1]={id=costID,quantity=amount}
                        other[#other+1]=tostring(costID).."x"..tostring(amount)
                    elseif costID then
                        other[#other+1]="non-token item "..costID.."x"..tostring(amount or "?")
                    elseif type(currencyName)=="string" then
                        other[#other+1]="currency:"..currencyName.."x"..tostring(amount or "?")
                    else
                        other[#other+1]="unknown cost x"..tostring(amount or "?")
                    end
                end
                local costs=table.concat(other,"; ")
                for _,token in ipairs(tokens) do
                    Record(self,"merchant_offer",token.id,rewardID,token.quantity,
                        rewardQty,costs,vendorID)
                end
            end
        end
    end
end
-- Some useable equipment containers open a standard loot window. Record only
-- when a SINGLE recently used, native hasLoot bag item can be associated with
-- the window; otherwise we skip, rather than guess an item relationship.
local pending=nil
function LL:TokenCollectorItemUsed(bag,slot)
    if not Store(self) or not C_Container or not C_Container.GetContainerItemInfo then return end
    local info=C_Container.GetContainerItemInfo(bag,slot)
    local id=info and Number(info.itemID)
    if info and info.hasLoot and id and TokenInput(id) then
        pending={id=id,at=(GetTime and GetTime()) or 0}
    else
        pending=nil
    end
end
function LL:CollectOpenTokenLoot()
    if not pending or not Store(self) or not GetLootSlotLink or not GetNumLootItems then return end
    local now=(GetTime and GetTime()) or 0
    if now-pending.at>3 or now<pending.at then pending=nil;return end
    local source=pending.id
    pending=nil -- A loot window may contribute at most one tentative source.
    local n=GetNumLootItems()
    if type(n)~="number" then return end
    for slot=1,math.min(n,40) do
        local rewardID=ItemID(GetLootSlotLink(slot))
        if rewardID and Equipment(rewardID) then
            local quantity=1
            if GetLootSlotInfo then
                local _,_,q=GetLootSlotInfo(slot)
                if Number(q) then quantity=q end
            end
            Record(self,"open_loot_window",source,rewardID,1,quantity,
                "Loot window after use; not a measured drop probability",nil)
        end
    end
end
function LL:TokenResearchStatus()
    local s=self.db and self.db.directTokenResearch
    local records=s and s.records or {}
    local merchants,opened,unique={},0,{}
    for _,r in pairs(records) do
        if r.kind=="merchant_offer" then merchants[r.inputID]=true
        else opened=opened+1 end
        unique[r.inputID]=true
    end
    return ("Direct token research: %d links, %d distinct input items, %d opened-loot links; observational only, not used for prices."):
        format(Count(records),Count(unique),opened)
end
function LL:TokenResearchExport(page)
    page=math.max(1,math.floor(tonumber(page) or 1))
    local saved=self.db and self.db.directTokenResearch
    local records=saved and saved.records or {}
    local keys={}
    for key in pairs(records) do keys[#keys+1]=key end
    table.sort(keys)
    local pages=math.max(1,math.ceil(#keys/PAGE_SIZE))
    if page>pages then return ("No page %d. Available pages: 1-%d."):format(page,pages) end
    local lines={"# Loot Liquidator DIRECT token research v1",
        "# Research candidate only; not validated reward table or drop probability",
        "# NO ATT; NO reverse ingredient/crafting relationships; no market prices",
        "# Separator: | ; observations are repeated merchant sightings, NOT successful purchases or drop samples",
        "# otherCosts lists the COMPLETE merchant cost display (may include the input token itself)",
        ("# Page %d of %d; total links %d"):format(page,pages,#keys),
        "kind|inputID|inputQty|rewardID|rewardQty|vendorID|otherCosts|observations|lastSeen"}
    for i=(page-1)*PAGE_SIZE+1,math.min(#keys,page*PAGE_SIZE) do
        local r=records[keys[i]]
        local costs=tostring(r.otherCosts or ""):gsub("[|\r\n]"," ")
        lines[#lines+1]=table.concat({r.kind,r.inputID,r.inputQuantity,r.rewardID,
            r.rewardQuantity,r.vendorID or "",costs,r.seen or 1,r.lastSeen or ""},"|")
    end
    return table.concat(lines,"\n")
end

-- One-time migration of the account's EXISTING ATT reward cache for offline
-- review. This does NOT query ATT, turn cached links into active token tables,
-- or accept crafting inputs. Records are flagged unverified; 50-entry lists
-- may be truncated by the legacy ATT scanner.
function LL:ImportLegacyTokenCandidates()
    local cache=self.db and self.db.attRewardCache
    if type(cache)~="table" then return 0,0 end
    local added,skipped=0,0
    for rawID,entry in pairs(cache) do
        local inputID=Number(tonumber(rawID))
        if inputID and TokenInput(inputID) and type(entry)=="table"
            and type(entry.rewards)=="table" then
            local kind=entry.kind=="exchange" and "att_exchange_candidate" or "att_open_candidate"
            local note=(#entry.rewards>=50)
                and "Unverified ATT cache; possible truncated list (50 cap)"
                or "Unverified ATT cache; relation or prerequisites unknown"
            for _,rewardID in ipairs(entry.rewards) do
                local store=Store(self)
                local key=kind..":"..inputID..":"..tostring(rewardID)..":1:1"
                if store and store[key] then
                    skipped=skipped+1
                elseif Record(self,kind,inputID,Number(rewardID),1,1,note,nil) then
                    added=added+1
                else skipped=skipped+1 end
            end
        elseif inputID then skipped=skipped+1 end
    end
    return added,skipped
end

local frame=CreateFrame("Frame")
frame:RegisterEvent("MERCHANT_SHOW")
frame:RegisterEvent("MERCHANT_UPDATE")
frame:RegisterEvent("LOOT_OPENED")
frame:SetScript("OnEvent",function(_,event)
    if event=="LOOT_OPENED" then pcall(LL.CollectOpenTokenLoot,LL)
    else pcall(LL.CollectMerchantTokenOffers,LL) end
end)
if C_Container and type(C_Container.UseContainerItem)=="function" and hooksecurefunc then
    hooksecurefunc(C_Container,"UseContainerItem",function(bag,slot)
        LL:TokenCollectorItemUsed(bag,slot)
    end)
end
