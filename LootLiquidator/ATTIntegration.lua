-- Standalone reviewed token catalog plus an optional ATT research fallback.
-- ATT has no stable external addon API; all calls are protected and bounded.
-- A confirmed appearance is collected from ANY source via Blizzard API.
local _, LL = ...
local tokenCache = {}
local failedCache = {} -- short session cooldown for misses, never persisted
local seenTokenIDs = {} -- unique item IDs seen in a bank, not its UI buttons
local seenTokenCount = 0
local forceScanIDs = {}
local MAX_SAVED_TOKENS = 600
local function TokenStore(self)
    if not self.db then return nil end
    if type(self.db.attRewardCache)~="table" then self.db.attRewardCache={} end
    return self.db.attRewardCache
end
local function ValidRewards(rewards)
    if type(rewards)~="table" or #rewards==0 or #rewards>50 then return false end
    for _,id in ipairs(rewards) do
        if type(id)~="number" or id<=0 or id%1~=0 then return false end
    end
    return true
end
local function SavedReward(self,id)
    local saved=self.db and self.db.attRewardCache
    local record=type(saved)=="table" and saved[tostring(id)] or nil
    if type(record)~="table" or not ValidRewards(record.rewards) then return nil end
    local copy={rewards={},kind=record.kind=="exchange" and "exchange" or "open",
        source=record.kind=="exchange" and "ATT possible exchange purchases (other costs may apply)"
            or "ATT possible reward list; drop rates unknown"}
    for i,v in ipairs(record.rewards) do copy.rewards[i]=v end
    return copy
end
local function SaveReward(self,id,data)
    local store=TokenStore(self)
    if not store or not ValidRewards(data.rewards) then return end
    local key=tostring(id)
    if store[key]==nil then
        local n=0
        for _ in pairs(store) do n=n+1 end
        -- Bound saved-variable size; no need to copy ATT's raw reward tree.
        if n>=MAX_SAVED_TOKENS then return end
    end
    local rewards={}
    for i,v in ipairs(data.rewards) do rewards[i]=v end
    store[key]={rewards=rewards,kind=data.kind,provenance=data.provenance,
        limitations=data.limitations,details=data.details,reviewStatus='UNREVIEWED_ATT'}
    return true
end

local function SafeNumber(n)
    return type(n)=="number" and not (issecretvalue and issecretvalue(n)) and n>0
end
-- Retail marks some use-only tier tokens with the special IGNORE inventory
-- type.  This is NOT an equipped slot; GetItemInfo returns it as-is.
local function NonEquippableSlot(slot)
    return slot==nil or slot=="" or slot=="INVTYPE_NON_EQUIP"
        or slot=="INVTYPE_NON_EQUIP_IGNORE"
end
local function EquippableSlot(slot)
    return type(slot)=="string" and slot~="" and not NonEquippableSlot(slot)
end
local function ATT()
    if C_AddOns and type(C_AddOns.IsAddOnLoaded)=="function" then
        local ok,yes=pcall(C_AddOns.IsAddOnLoaded,"AllTheThings")
        if ok and not yes then return nil end
    end
    local app=_G and (_G.AllTheThings or _G.ATTC)
    return type(app)=="table" and app or nil
end
function LL:ATTAvailable()
    return (not self.db or self.db.enableATTIntegration~=false) and ATT()~=nil
end

-- One account-wide collection resolver for normal gear AND ATT token rewards.
-- Retail 12.x GetAppearanceSourceInfo.isCollected works across class boundaries.
-- The legacy appearance-wide bit is retained as a fallback, never substitute
-- sourceIsCollected (owning one specific item source is NOT the same thing).
function LL:AppearanceCollectionState(link)
    local collection=C_TransmogCollection
    if not collection or type(collection.GetItemInfo)~="function" then return nil end
    local ok,_,sourceID=pcall(collection.GetItemInfo,link)
    if not ok or not SafeNumber(sourceID) then return nil end
    local newState,oldState
    if type(collection.GetAppearanceSourceInfo)=="function" then
        local good,info=pcall(collection.GetAppearanceSourceInfo,sourceID)
        if good and type(info)=="table" and type(info.isCollected)=="boolean" then
            newState=info.isCollected
        end
    end
    if type(collection.GetAppearanceInfoBySource)=="function" then
        local good,info=pcall(collection.GetAppearanceInfoBySource,sourceID)
        if good and type(info)=="table" and type(info.appearanceIsCollected)=="boolean" then
            oldState=info.appearanceIsCollected
        end
    end
    -- Avoid a false "missing" recommendation during temporary API disagreement:
    -- either affirmative account-wide signal means the appearance is owned.
    if newState==true or oldState==true then return true,sourceID end
    if newState==false or oldState==false then return false,sourceID end
    return nil,sourceID
end
local function AppearanceMissing(link)
    local collected,sourceID=LL:AppearanceCollectionState(link)
    if collected==nil then return nil,sourceID end
    return not collected,sourceID
end
local function RefreshMissing(data,now)
    if now-(data._appearanceAt or -100)<5 then return end
    local missing=false
    for _,id in ipairs(data.rewards) do
        if AppearanceMissing("item:"..id)==true then missing=true;break end
    end
    data.possibleMissingAppearance=missing
    data._appearanceAt=now
end
function LL:StandaloneTokenInfo(f)
    if not f or not SafeNumber(f.id) or not NonEquippableSlot(f.equipLoc) then return nil end
    -- Parentheses keep only the build result; otherwise select also forwards
    -- the date string into tonumber's optional numeric-base argument.
    local build=GetBuildInfo and tonumber((select(2,GetBuildInfo())))
    for _,r in ipairs(self._tokenRewardIndex and self._tokenRewardIndex[f.id] or {}) do
        if WOW_PROJECT_ID~=nil and WOW_PROJECT_ID==WOW_PROJECT_MAINLINE
            and build and build>=r.patchStartBuild and build<=r.patchEndBuild and f.classID==r.inputClassID
            and self:ValidateTokenCatalog({r}) then
            local data=tokenCache[f.id]
            if not data or data._catalogRecord~=r or data._catalogBuild~=build then
                local rewards={} for i,id in ipairs(r.rewards) do rewards[i]=id end
                data={rewards=rewards,kind=r.kind,costs=r.costs,standalone=true,
                    recordID=r.recordID,_catalogRecord=r,_catalogBuild=build,
                    source='Loot Liquidator reviewed reward catalog (possible outcomes; probabilities unknown)'}
                tokenCache[f.id]=data
            end
            RefreshMissing(data,(GetTime and GetTime()) or 0)
            return data
        end
    end
end

function LL:UncollectedAppearance(f)
    -- Direct equipment appearances are a Blizzard feature, NOT an ATT feature.
    if not f or (f.classID~=2 and f.classID~=4) then return nil end
    if self.IsIgnoredAction and self:IsIgnoredAction(f.id,"T") then return nil end
    -- No source ID, no guess; e.g. generated gear tokens don't themselves
    -- have a wearable appearance.
    return AppearanceMissing(f.link)
end

-- ATT item groups may contain real nested reward objects OR merely cosmetic
-- symlinks. Only enumerate positively identifiable equipment rewards, and
-- never price a chance-based pool as though all results were guaranteed.
function LL:ATTTokenInfo(f)
    local standalone=self:StandaloneTokenInfo(f)
    if standalone and not forceScanIDs[f.id] then return standalone end
    if self.db and self.db.enableATTIntegration==false then return nil end
    if not f or not SafeNumber(f.id) then return nil end
    -- Raw trade goods (ores, herbs and reagents) can be ATT ingredients for
    -- crafted gear. This does NOT make them redeemable armor tokens. Their
    -- exchange/crafting value belongs in the conversion engine instead.
    -- Also ignore any stale token snapshots saved for these reagents.
    if f.classID==7 then return nil end
    -- Class-limited equipment TOKENS are not always ItemClass Armor/Misc.
    -- Retail also uses Quest (12) and Miscellaneous (15) for non-equippable
    -- tier marks. Let ATT's verified gear-producing cost/use relationship
    -- establish token status instead of excluding these item categories.
    -- Never mistake an actual equipped ring/trinket for a token.
    -- Do not gate by ItemClass: expansion-specific tier marks can be classified
    -- differently, and ATT's *verified* redemption relationship is the source
    -- of truth. Exclude equippable items so ordinary armor isn't misclassified.
    if not NonEquippableSlot(f.equipLoc) then return nil end
    local forced=forceScanIDs[f.id]==true
    local cached=not forced and tokenCache[f.id] or nil
    local now=(GetTime and GetTime()) or 0
    -- Reward RELATIONSHIPS don't expire when BetterBags sorts. Only the
    -- collection state needs refreshing. A manual update clears snapshots.
    if not cached and not forced then
        cached=SavedReward(self,f.id)
        if cached then tokenCache[f.id]=cached end
    end
    if cached then
        RefreshMissing(cached,now)
        return cached
    end
    -- Saved relationships and Blizzard collection queries work without ATT.
    -- Only an uncached live research lookup requires the external addon.
    local app=ATT()
    if not app then return nil end
    -- Opening/redrawing the Warbank must not launch uncached ATT database
    -- searches. The user can update once on demand (or hover a token).
    if f.context and f.context._LLFastBadge then return nil end
    if not forced and failedCache[f.id] and now-failedCache[f.id]<60 then return nil end
    -- A token may be opened with a spell OR exchanged for equipment.
    -- ATT indexes the latter in its reverse cost cache (itemIDAsCost).
    -- Only a verified, gear-producing relationship counts as a token.
    if type(app.SearchForField)~="function" then return nil end
    local scan={status='NO_MATCH_OR_UNRESOLVED',observed=(time and time()) or nil,
        source='AllTheThings',scope='requested-item-only'}
    if self.db then
        self.db.attResearchScans=self.db.attResearchScans or {}
        self.db.attResearchScans[tostring(f.id)]=scan
    end
    local spellFn=GetItemSpell
    local useItem=false
    if type(spellFn)=="function" then
        local ok,name=pcall(spellFn,f.link)
        useItem=ok and name~=nil
    end
    local purchaseGroups
    do
        local ok,groups=pcall(app.SearchForField,"itemIDAsCost",f.id)
        if ok and type(groups)=="table" and #groups>0 then purchaseGroups=groups end
        -- ATT uses separate caches internally. Its on-screen tooltip can
        -- locate a token even when the current search cache is empty.
        -- Try its read-only all-cache search, then raw cache, if available.
        if not purchaseGroups then
            for _,method in ipairs({"SearchForFieldInAllCaches","GetRawField"}) do
                local query=app[method]
                if type(query)=="function" then
                    local good,found=pcall(query,"itemIDAsCost",f.id)
                    if good and type(found)=="table" and #found>0 then
                        purchaseGroups=found
                        break
                    end
                end
            end
        end
    end
    -- ATT's displayed "Contains" section may be built from a hydrated item
    -- search result even when the reverse-cost cache is empty. In particular,
    -- GetItemSpell is NOT a reliable indicator of a tier token's reward graph.
    -- We still avoid expensive, full ATT tooltip searches for arbitrary junk:
    -- use the hydrated path only for items which have a use spell, an indexed
    -- exchange, or a class-restricted rare/epic template in our independent
    -- eligibility snapshot. The relationship itself must still be confirmed
    -- by ATT and produce real equippable item IDs.
    local classRestricted = self.ItemClassMasks and SafeNumber(self.ItemClassMasks[f.id])
    local hydratedCandidate = useItem or purchaseGroups or
        (classRestricted and type(f.quality)=="number" and f.quality>=3)
    if not hydratedCandidate then failedCache[f.id]=now;return nil end
    -- Do not negative-cache an empty ATT response: ATT can finish indexing
    -- or Blizzard can load reward-item metadata AFTER the first bag scan.
    local items,seen,details={},{},{}
    local limitations={ancestorRequirementsUnknown=true,probabilitiesUnknown=true}
    local function Metadata(node,query)
        if type(node)~='table' then return end
        if #details>=500 then limitations.metadataTruncated=true;return end
        local entry={query=query,itemID=node.itemID}
        -- Capture only plain source metadata. No ATT code, child trees,
        -- player collection state or derived numerical yield is copied.
        local function copy(value,depth)
            local kind=type(value)
            if kind=='string' or kind=='boolean' or kind=='number' then return value end
            if kind~='table' then return nil end
            if depth>4 then limitations.metadataTruncated=true;return nil end
            local out,n={},0
            for key,v in pairs(value) do
                n=n+1;if n>100 then limitations.metadataTruncated=true;break end
                if type(key)=='string' or type(key)=='number' then out[key]=copy(v,depth+1) end
            end
            return out
        end
        for _,key in ipairs({'cost','c','races','r','factionID','minReputation','questID','quests',
            'sourceQuests','requireSkill','spellID','lvl','u','b','q','f','s','crs'}) do
            entry[key]=copy(node[key],1)
        end
        details[#details+1]=entry
    end
    local function EquipID(id)
        if not SafeNumber(id) or id==f.id or seen[id] then return end
        local api=C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
        local slot,classID
        if type(api)=="function" then
            local ok,_,_,_,loc,_,cls=pcall(api,id)
            if ok then slot,classID=loc,cls end
        end
        -- GetItemInfoInstant may temporarily lack a category on a cold cache.
        -- A full GetItemInfo lookup is a safe second source, not a guess.
        if type(slot)~="string" or slot=="" or not classID then
            local full=C_Item and C_Item.GetItemInfo or GetItemInfo
            if type(full)=="function" then
                local ok,_,_,_,_,_,_,_,_,loc,_,_,cls=pcall(full,id)
                if ok then slot,classID=loc,cls end
            end
        end
        if (classID==2 or classID==4) and EquippableSlot(slot) then
            seen[id]=true;items[#items+1]=id
        elseif C_Item and type(C_Item.RequestLoadItemDataByID)=="function" then
            pcall(C_Item.RequestLoadItemDataByID,id)
        end
    end
    local function Collect(node,depth)
        if type(node)~="table" then return end
        if depth>3 then limitations.depthLimitReached=true;return end
        if #items>=50 then limitations.rewardLimitReached=true;return end
        EquipID(node.itemID)
        if seen[node.itemID] then Metadata(node,'itemID child/symbolic candidate') end
        for _,child in ipairs(node.g or {}) do Collect(child,depth+1) end
    end
    -- First inspect the raw item group whether or not GetItemSpell worked.
    -- An ATT item can contain its rewards without exposing an item-use spell.
    local found,groups=pcall(app.SearchForField,"itemID",f.id)
    if found and type(groups)=="table" then
        for _,node in ipairs(groups) do
            if type(node)=="table" and node.itemID==f.id then
                for _,child in ipairs(node.g or {}) do Collect(child,1) end
                if node.sym and type(app.ResolveSymbolicLink)=="function" then
                    local success,res=pcall(app.ResolveSymbolicLink,node)
                    if success and type(res)=="table" then
                        for _,child in ipairs(res) do Collect(child,1) end
                    end
                end
            end
        end
    end
    -- ATT's visible tooltip uses GetCachedSearchResults to merge and fill
    -- data from multiple sources before rendering its "Contains" children.
    -- Raw SearchForField groups can be empty even while that tooltip works.
    -- This is a guarded, read-only attempt to inspect that *same* item tree.
    if #items==0 and type(app.GetCachedSearchResults)=="function" then
        local ok,root=pcall(app.GetCachedSearchResults,
            app.SearchForField,"itemID",f.id,{ShortCache=true})
        if ok and type(root)=="table" and root.itemID==f.id then
            for _,child in ipairs(root.g or {}) do Collect(child,1) end
        end
    end
    -- An exchange/redeem token may require OTHER items as well. These are
    -- possible vendor purchases, not guaranteed outputs from opening it.
    if purchaseGroups then
        for _,node in ipairs(purchaseGroups) do
            if #items>=50 then limitations.rewardLimitReached=true;break end
            local needsThis=false
            for _,cost in ipairs(node.cost or {}) do
                if type(cost)=="table" and cost[1]=="i" and cost[2]==f.id then
                    needsThis=true;break
                end
            end
            if needsThis then
                EquipID(node.itemID)
                if seen[node.itemID] then Metadata(node,'itemIDAsCost') end
            end
        end
    end
    if #items==0 then
        -- A known ATT exchange can be missing its item metadata temporarily;
        -- retry as soon as the client loads it instead of treating it as a miss.
        if not purchaseGroups then failedCache[f.id]=now end
        return nil
    end
    local missing=false
    for _,id in ipairs(items) do
        local known=AppearanceMissing("item:"..id)
        if known==true then missing=true;break end
    end
    local data={rewards=items,possibleMissingAppearance=missing,
        kind=purchaseGroups and "exchange" or "open",
        source=purchaseGroups and "ATT possible exchange purchases (other costs may apply)"
            or "ATT possible reward list; drop rates unknown"}
    local version
    if C_AddOns and type(C_AddOns.GetAddOnMetadata)=='function' then
        local ok,v=pcall(C_AddOns.GetAddOnMetadata,'AllTheThings','Version');if ok then version=v end
    end
    data.provenance={source='AllTheThings',version=version or 'UNKNOWN',
        upstream='https://github.com/ATTWoWAddon/AllTheThings',
        clientBuild=GetBuildInfo and tostring(select(2,GetBuildInfo())) or 'UNKNOWN',observed=scan.observed}
    limitations.rewardLimitReached=limitations.rewardLimitReached or #items>=50
    data.limitations=limitations;data.details=details
    scan.status='FOUND_CANDIDATES';scan.limitations=limitations
    data._cachedAt=now
    data._appearanceAt=now
    tokenCache[f.id]=data
    failedCache[f.id]=nil
    if not SaveReward(self,f.id,data) then scan.status='CACHE_LIMIT_REACHED' end
    return data
end

-- One-shot diagnostics for reports of a missing compact token tooltip.
-- Never changes ATT or persists its datasets.
function LL:ATTTokenDiagnostics(id)
    local app=ATT()
    if not app then return "ATT not loaded or its addon table is unavailable" end
    if self.db and self.db.enableATTIntegration==false then
        return "ATT integration disabled in Loot Liquidator settings"
    end
    local results={}
    for _,method in ipairs({"SearchForField","SearchForFieldInAllCaches","GetRawField"}) do
        local fn=app[method]
        local count="unavailable"
        if type(fn)=="function" then
            local ok,groups=pcall(fn,"itemIDAsCost",id)
            count=ok and type(groups)=="table" and #groups or (ok and "none" or "error")
        end
        results[#results+1]=method.."="..tostring(count)
    end
    if type(app.SearchForField)=="function" then
        local ok,nodes=pcall(app.SearchForField,"itemID",id)
        local count=ok and type(nodes)=="table" and #nodes or (ok and "none" or "error")
        results[#results+1]="itemID="..tostring(count)
        if type(app.GetCachedSearchResults)=="function" then
            local good,root=pcall(app.GetCachedSearchResults,
                app.SearchForField,"itemID",id,{ShortCache=true})
            local descendants=good and type(root)=="table" and type(root.g)=="table"
                and #root.g or (good and 0 or "error")
            results[#results+1]="ATT hydrated children="..tostring(descendants)
        end
    end
    return table.concat(results,"; ")
end

-- Group the token's possible rewards by EQUIPMENT SLOT for readability.
-- Do not assume class variants share an appearance: only deduplicate if
-- Blizzard supplies the same itemAppearanceID. Collection is appearance-wide,
-- not dependent on whether this exact source was collected.
local SLOTS={
    INVTYPE_HEAD="Head",INVTYPE_SHOULDER="Shoulders",INVTYPE_CHEST="Chest",
    INVTYPE_ROBE="Chest",INVTYPE_HAND="Hands",INVTYPE_LEGS="Legs",
    INVTYPE_FEET="Feet",INVTYPE_WAIST="Waist",INVTYPE_WRIST="Wrist",
    INVTYPE_CLOAK="Back",INVTYPE_SHIELD="Shield",INVTYPE_WEAPON="Weapon",
    INVTYPE_2HWEAPON="Two-hand",INVTYPE_WEAPONMAINHAND="Main hand",
    INVTYPE_WEAPONOFFHAND="Off hand",INVTYPE_RANGED="Ranged"
}
local SLOT_ORDER={Head=1,Shoulders=2,Chest=3,Hands=4,Waist=5,Legs=6,Feet=7,Back=8}
function LL:ATTTokenSlotSummary(token)
    if not token or type(token.rewards)~="table" then return {} end
    local api=C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
    local nameAPI=C_Item and C_Item.GetItemInfo or GetItemInfo
    local iconAPI=C_Item and C_Item.GetItemIconByID or GetItemIcon
    local collection=C_TransmogCollection
    local grouped,commonPrefix,allClassMasks={},nil,{}
    for _,itemID in ipairs(token.rewards) do
        local slot,name,link,icon
        if type(api)=="function" then
            local ok,_,_,_,loc=pcall(api,itemID)
            if ok then slot=SLOTS[loc] or loc end
        end
        if type(nameAPI)=="function" then
            local ok,n,l=pcall(nameAPI,itemID)
            if ok then name,link=n,l end
        end
        if type(iconAPI)=="function" then
            local ok,i=pcall(iconAPI,itemID)
            if ok and (type(i)=="number" or type(i)=="string") then icon=i end
        end
        if not slot or slot=="" then slot="Other" end
        local lead=name and name:match("^(%S+)") or nil
        if lead then
            if commonPrefix==nil then commonPrefix=lead
            elseif commonPrefix~=false and commonPrefix~=lead then commonPrefix=false end
        end
        local group=grouped[slot]
        if not group then
            group={slot=slot,ids={},rows={},looks={},collected=0,missing=0,unknown=0,count=0}
            grouped[slot]=group
        end
        local appearanceID
        if collection and type(collection.GetItemInfo)=="function" then
            local ok,aid,sid=pcall(collection.GetItemInfo,"item:"..itemID)
            if ok and SafeNumber(aid) and SafeNumber(sid) then
                appearanceID=aid
            end
        end
        local state=self:AppearanceCollectionState("item:"..itemID)
        local mask=self.ItemClassMasks and self.ItemClassMasks[itemID]
        if type(mask)=="number" and mask>0 then
            allClassMasks[mask]=true
        end
        group.rows[#group.rows+1]={id=itemID,name=name or ("Item "..itemID),
            link=link,icon=icon,collected=state}
        -- Class variants can share an appearance. Count the visual once if
        -- Blizzard returns a real appearance ID; otherwise keep them distinct.
        local key=appearanceID and ("a"..appearanceID) or ("i"..itemID)
        if not group.looks[key] then
            group.looks[key]=true
            group.count=group.count+1
            if state==true then group.collected=group.collected+1
            elseif state==false then group.missing=group.missing+1
            else group.unknown=group.unknown+1 end
        end
        group.ids[#group.ids+1]=itemID
    end
    local result={}
    local classCount=0
    for _ in pairs(allClassMasks) do classCount=classCount+1 end
    for _,group in pairs(grouped) do
        -- If the token spans more than one class, summarize ALL of its
        -- slots consistently, even slots with only one cached class reward.
        -- For a single class show TSM-like individual spec pieces instead.
        -- Missing DB2 masks never justify assuming visual equivalence.
        group.multiClass=classCount>1
        group.title=(type(commonPrefix)=="string" and commonPrefix.." " or "")..group.slot
        group.looks=nil
        result[#result+1]=group
    end
    table.sort(result,function(a,b)
        local ai,bi=SLOT_ORDER[a.slot] or 99,SLOT_ORDER[b.slot] or 99
        return ai==bi and a.slot<b.slot or ai<bi
    end)
    return result
end

-- Compact, class-first presentation for multi-class raid and tier tokens.
-- ATT's reward graph is the source of items; DB2 allowable-class masks determine
-- which class set each reward belongs to. Never deduce class from an item name.
local TOKEN_CLASSES={
    {1,"WARRIOR","Warrior"},{2,"PALADIN","Paladin"},
    {3,"HUNTER","Hunter"},{4,"ROGUE","Rogue"},
    {5,"PRIEST","Priest"},{6,"DEATHKNIGHT","Death Knight"},
    {7,"SHAMAN","Shaman"},{8,"MAGE","Mage"},
    {9,"WARLOCK","Warlock"},{10,"MONK","Monk"},
    {11,"DRUID","Druid"},{12,"DEMONHUNTER","Demon Hunter"},
    {13,"EVOKER","Evoker"},
}
local SINGLE_REWARD_SUFFIXES={
    "Shoulderplates","Shoulderpads","Shoulderguards","Spaulders","Pauldrons",
    "Handguards","Gauntlets","Gloves","Greathelm","Headpiece","Headguard",
    "Legguards","Legplates","Leggings","Legwraps","Legguards","Legplates",
    "Chestguard","Chestplate","Robes","Tunic","Helmet","Helm","Cowl","Hood",
    "Breastplate","Battlegear","War-Kilt","Kilt","Robe","Mantle","Gloves",
    "Boots","Sabatons","Belt","Bracers","Wristguards"
}
local function SingleClassFromMask(mask)
    if type(mask)~="number" or mask<=0 then return nil end
    local only
    for _,cls in ipairs(TOKEN_CLASSES) do
        if math.floor(mask/(2^(cls[1]-1)))%2==1 then
            if only then return nil end
            only=cls
        end
    end
    return only
end
local function ClassSetName(rows)
    local names={}
    for _,row in ipairs(rows) do
        if type(row.name)=="string" and not row.name:match("^Item %d+$") then
            names[#names+1]=row.name
        end
    end
    if #names==0 then return "Equipment set" end
    local tokens={}
    for word in names[1]:gmatch("%S+") do tokens[#tokens+1]=word end
    for i=2,#names do
        local words={}
        for word in names[i]:gmatch("%S+") do words[#words+1]=word end
        local n=0
        while n<#tokens and tokens[n+1]==words[n+1] do n=n+1 end
        while #tokens>n do table.remove(tokens) end
    end
    if #names==1 or #tokens==0 then
        local name=names[1]
        for _,suffix in ipairs(SINGLE_REWARD_SUFFIXES) do
            if name:sub(-#suffix-1)==" "..suffix then
                return name:sub(1,-#suffix-2)
            end
        end
        return name
    end
    -- Never return a meaningless one-word prefix such as "Sanctified".
    if #tokens==1 then return names[1] end
    return table.concat(tokens," ")
end
function LL:ATTTokenClassSummary(token)
    if not token or type(token.rewards)~="table" then return {} end
    local groups,lookup={},{}
    local info=C_Item and C_Item.GetItemInfo or GetItemInfo
    local icons=C_Item and C_Item.GetItemIconByID or GetItemIcon
    local collection=C_TransmogCollection
    for _,id in ipairs(token.rewards) do
        local cls=SingleClassFromMask(self.ItemClassMasks and self.ItemClassMasks[id])
        local classKey=cls and cls[2] or "UNKNOWN"
        local group=lookup[classKey]
        if not group then
            group={class=classKey,className=cls and cls[3] or "Other",
                order=cls and cls[1] or 99,ids={},rows={},looks={},
                count=0,collected=0,missing=0,unknown=0}
            lookup[classKey]=group
            groups[#groups+1]=group
        end
        local name,link,icon
        if type(info)=="function" then
            local ok,n,l=pcall(info,id)
            if ok then name,link=n,l end
        end
        if not name and C_Item and type(C_Item.RequestLoadItemDataByID)=="function" then
            pcall(C_Item.RequestLoadItemDataByID,id)
        end
        if type(icons)=="function" then
            local ok,value=pcall(icons,id)
            if ok and (type(value)=="number" or type(value)=="string") then icon=value end
        end
        local appearance
        if collection and type(collection.GetItemInfo)=="function" then
            local ok,a=pcall(collection.GetItemInfo,"item:"..id)
            if ok then appearance=a end
        end
        local collected=self:AppearanceCollectionState("item:"..id)
        local row={id=id,name=name or "Reward loading",link=link,icon=icon,collected=collected}
        group.ids[#group.ids+1]=id
        group.rows[#group.rows+1]=row
        local key=(SafeNumber(appearance) and "a"..appearance) or ("i"..id)
        if group.looks[key]==nil then group.looks[key]=collected==true and 2 or (collected==false and 1 or 0)
        elseif collected==true then group.looks[key]=2 end
    end
    for _,group in ipairs(groups) do
        group.title=ClassSetName(group.rows)
        for _,status in pairs(group.looks) do
            group.count=group.count+1
            if status==2 then group.collected=group.collected+1
            elseif status==1 then group.missing=group.missing+1
            else group.unknown=group.unknown+1 end
        end
        group.looks=nil
    end
    table.sort(groups,function(a,b)
        return a.order==b.order and a.title<b.title or a.order<b.order
    end)
    return groups
end

-- The highest confirmed NPC sell price among ATT's possible equipment
-- redemptions.  This is a reward item's sell value, NOT the token's net
-- liquidation value: an exchange may consume other equipment or currency.
-- Unlike TSM market quotes, GetItemInfo's sellPrice is the real NPC price.
function LL:TokenBestVendorReward(token)
    if not token or type(token.rewards)~="table" then return nil end
    local info=C_Item and C_Item.GetItemInfo or GetItemInfo
    if type(info)~="function" then return nil end
    local best
    for _,id in ipairs(token.rewards) do
        local ok,name,link,_,_,_,_,_,_,loc,_,sellPrice=
            pcall(info,id)
        if ok and type(sellPrice)=="number" and sellPrice>=0
            and EquippableSlot(loc) then
            if not best or sellPrice>best.value or
                (sellPrice==best.value and id<best.itemID) then
                best={itemID=id,name=name,link=link,value=sellPrice}
            end
        elseif C_Item and type(C_Item.RequestLoadItemDataByID)=="function" then
            pcall(C_Item.RequestLoadItemDataByID,id)
        end
    end
    return best
end

-- Choose a character who is actually documented to have Enchanting and
-- its disenchant spell. Alt mailability is checked on THIS item instance.
-- Class is informative for class-dependent token rewards; no fabricated
-- cross-class ability is implied by merely having the profession.
function LL:TokenDisenchanter(f)
    if not self.db then return nil end
    local key=self.CharacterKey and self:CharacterKey() or nil
    local chars=self.db.characters or {}
    if self.CurrentHasEnchanting and self:CurrentHasEnchanting() then
        local char=chars[key] or {}
        local class=char.class
        if not class and UnitClass then local _,id=UnitClass("player"); class=id end
        return {name=key or "Current character",class=class,current=true}
    end
    if self.db.includeVerifiedAlts==false
        or not (self.CanTransferToAlt and self:CanTransferToAlt(f)) then return nil end
    for name,char in pairs(chars) do
        if name~=key and (not self.AltMethodEnabled or self:AltMethodEnabled(name,"D"))
            and char.professions and char.professions.Enchanting
            and char.spells and char.spells[13262]==true then
            return {name=name,class=char.class,current=false}
        end
    end
end
-- Retained compatibility hook; aggregate TSM Destroy never values token rewards.
function LL:TokenDEQuotes(f,token,enchanter)
    return nil
end

function LL:InvalidateATTCache()
    for key in pairs(tokenCache) do tokenCache[key]=nil end
    -- Unverified misses remain temporary, not a persistent denial.
end

function LL:RememberATTItem(link)
    local id=type(link)=="string" and tonumber(link:match("item:(%d+)"))
    if id and id>0 and not seenTokenIDs[id] and seenTokenCount<1800 then
        seenTokenIDs[id]=true
        seenTokenCount=seenTokenCount+1
    end
end

function LL:ATTCacheStatus()
    local n=0
    for _ in pairs((self.db and self.db.attRewardCache) or {}) do n=n+1 end
    return string.format("%d cached tokens; %d unique item IDs observed",n,seenTokenCount)
end

-- Manual research only. Capture the source identifiers needed to replace ATT's
-- location/difficulty/event/patch lines; never copy its code or player state.
function LL:HarvestATTItemMetadata(f)
    if not self.db or not f or not SafeNumber(f.id) or not self:ATTAvailable() then return false end
    local app=ATT()
    if not app or type(app.SearchForField)~='function' then return false end
    self.db.attItemResearch=self.db.attItemResearch or {}
    local store=self.db.attItemResearch
    if not store[tostring(f.id)] then
        local n=0;for _ in pairs(store) do n=n+1 end
        if n>=1200 then self.db.attItemResearchLimitReached=true;return false end
    end
    local record={itemID=f.id,contexts={},status='NO_MATCH_OR_UNRESOLVED',
        reviewStatus='UNREVIEWED_ATT',listComplete=false,observed=(time and time()) or nil,
        clientBuild=GetBuildInfo and tostring(select(2,GetBuildInfo())) or 'UNKNOWN'}
    if C_AddOns and type(C_AddOns.GetAddOnMetadata)=='function' then
        local ok,v=pcall(C_AddOns.GetAddOnMetadata,'AllTheThings','Version');if ok then record.attVersion=v end
    end
    local function copy(value,depth)
        local kind=type(value)
        if kind=='number' or kind=='boolean' or kind=='string' then return value end
        if kind~='table' then return nil end
        if depth>4 then record.metadataTruncated=true;return nil end
        local out,n={},0
        for key,v in pairs(value) do
            n=n+1;if n>100 then record.metadataTruncated=true;break end
            if type(key)=='string' or type(key)=='number' then out[key]=copy(v,depth+1) end
        end
        return out
    end
    local fields={'itemID','mapID','instanceID','difficultyID','encounterID','npcID','creatureID',
        'headerID','questID','achievementID','eventID','holidayID','factionID','minReputation',
        'sourceQuests','requireSkill','races','c','r','cost','timeline','awp','rwp','e','u','lvl','q','b','f','s','crs','name','text'}
    local ok,groups=pcall(app.SearchForField,'itemID',f.id)
    if ok and type(groups)=='table' then
        for index,node in ipairs(groups) do
            if index>8 then record.metadataTruncated=true;break end
            if type(node)=='table' and rawget(node,'itemID')==f.id then
                local path,seen={},{}
                while type(node)=='table' and not seen[node] do
                    if #path>=12 then record.metadataTruncated=true;break end
                    seen[node]=true
                    local context={}
                    for _,key in ipairs(fields) do context[key]=copy(rawget(node,key),1) end
                    path[#path+1]=context
                    node=rawget(node,'parent')
                end
                record.contexts[#record.contexts+1]=path
            end
        end
        if #record.contexts>0 then record.status='FOUND_SOURCE_CANDIDATES' end
    end
    local previous=store[tostring(f.id)]
    if record.status~='FOUND_SOURCE_CANDIDATES' and previous and previous.status=='FOUND_SOURCE_CANDIDATES' then
        previous.lastAttempt={status=record.status,observed=record.observed,clientBuild=record.clientBuild}
        return false -- temporary cache misses must not erase gathered source data
    end
    store[tostring(f.id)]=record
    return record.status=='FOUND_SOURCE_CANDIDATES'
end

-- Lossless plain-data export of gathered links, with explicit collection limits.
-- Empty/missing lookup results are unresolved, never proof that no reward exists.
local function JSON(value)
    local kind=type(value)
    if kind=='nil' then return 'null' end
    if kind=='boolean' then return value and 'true' or 'false' end
    if kind=='number' then return value==value and math.abs(value)<math.huge and tostring(value) or 'null' end
    if kind=='string' then
        return '"'..value:gsub('[%z\1-\31\\"]',function(char)
            if char=='"' then return '\\"' elseif char=='\\' then return '\\\\' end
            return ('\\u%04x'):format(char:byte())
        end)..'"'
    end
    if kind~='table' then return 'null' end
    local keys={} for key in pairs(value) do keys[#keys+1]=key end
    local array=#keys>0 and #keys==#value
    if array then for _,key in ipairs(keys) do if type(key)~='number' or key%1~=0 or key<1 or key>#value then array=false;break end end end
    local parts={}
    if array then
        for i=1,#value do parts[#parts+1]=JSON(value[i]) end
        return '['..table.concat(parts,',')..']'
    end
    table.sort(keys,function(a,b)return tostring(a)<tostring(b)end)
    for _,key in ipairs(keys) do parts[#parts+1]=JSON(tostring(key))..':'..JSON(value[key]) end
    return '{'..table.concat(parts,',')..'}'
end
function LL:ATTResearchStatus()
    local cached,reviewed,unresolved,capped,metadata=0,0,0,0,0
    for _,r in pairs(self.db and self.db.attRewardCache or {}) do
        cached=cached+1
        r=type(r)=='table' and r or {}
        if #(r.rewards or {})>=50 or (r.limitations and
            (r.limitations.rewardLimitReached or r.limitations.depthLimitReached or r.limitations.metadataTruncated)) then capped=capped+1 end
    end
    for _ in pairs(self.db and self.db.attItemResearch or {}) do metadata=metadata+1 end
    local build=GetBuildInfo and tonumber((select(2,GetBuildInfo())))
    for _,list in pairs(self._tokenRewardIndex or {}) do
        for _,r in ipairs(list) do if build and build>=r.patchStartBuild and build<=r.patchEndBuild then reviewed=reviewed+1 end end
    end
    for _,r in pairs(self.db and self.db.attResearchScans or {}) do if r.status~='FOUND_CANDIDATES' then unresolved=unresolved+1 end end
    return ('Standalone catalog: %d current-build tokens; ATT cache: %d candidates (%d capped); source metadata: %d items; unresolved scans: %d. Removal pending reviewed coverage; observed IDs are not a complete ATT universe.'):format(reviewed,cached,capped,metadata,unresolved)
end
function LL:ATTResearchExport(page)
    page=math.max(1,math.floor(tonumber(page) or 1))
    local cache=self.db and self.db.attRewardCache or {}
    local scans=self.db and self.db.attResearchScans or {}
    local ids,seen={},{}
    local metadata=self.db and self.db.attItemResearch or {}
    for _,dict in ipairs({cache,scans,metadata}) do
        for key in pairs(dict) do
            local id=tonumber(key)
            if SafeNumber(id) and id%1==0 and not seen[id] then seen[id]=true;ids[#ids+1]=id end
        end
    end
    table.sort(ids)
    local pages=math.max(1,math.ceil(#ids/20))
    if page>pages then return ('No page %d. Available pages: 1-%d.'):format(page,pages) end
    local rows={}
    for i=(page-1)*20+1,math.min(#ids,page*20) do
        local id=ids[i]
        local r=cache[tostring(id)] or cache[id] or {}
        r=type(r)=='table' and r or {}
        rows[#rows+1]=JSON({tokenID=id,kind=r.kind or 'unknown',rewards=r.rewards,
            details=r.details,provenance=r.provenance or {source='AllTheThings',version='UNKNOWN'},
            limitations=r.limitations or {legacyMetadataUnknown=true,rewardLimitReached=#(r.rewards or {})>=50},
            scan=scans[tostring(id)] or scans[id],itemMetadata=metadata[tostring(id)] or metadata[id],reviewStatus='UNREVIEWED_ATT'})
    end
    return '{"schemaVersion":"loot-liquidator.att-research/1","page":'..page..',"pages":'..pages..
        ',"totalTokens":'..#ids..',"scope":"observed/requested item IDs only","completeUniverse":false,'..
        '"automaticApproval":false,"itemMetadataLimitReached":'..JSON(self.db and self.db.attItemResearchLimitReached==true)..',"records":['..table.concat(rows,',')..']}'
end

-- Manual on-demand update. The first bank draw NEVER runs these searches;
-- each unique observed ID is scanned once, at most one per timer callback.
function LL:StartATTCacheUpdate()
    if not self:ATTAvailable() then return false,"ATT is disabled or unavailable" end
    if self._attRefreshRunning then return false,"ATT cache update already running" end
    local candidates={}
    for id in pairs(seenTokenIDs) do candidates[id]=true end
    for id in pairs(self.ResearchTokenCandidates or {}) do candidates[id]=true end
    -- Supplement BetterBags with Blizzard bag/bank IDs when available.
    if C_Container and type(C_Container.GetContainerNumSlots)=="function"
        and type(C_Container.GetContainerItemLink)=="function" then
        for bag=0,17 do
            local ok,n=pcall(C_Container.GetContainerNumSlots,bag)
            if ok and type(n)=="number" and n>0 and n<=200 then
                for slot=1,n do
                    local good,link=pcall(C_Container.GetContainerItemLink,bag,slot)
                    local id=good and type(link)=="string" and tonumber(link:match("item:(%d+)"))
                    if id then candidates[id]=true end
                end
            end
        end
    end
    -- Existing saved tokens are also refresh candidates, even if the Warbank
    -- was closed before the user pressed the button.
    for id in pairs((self.db and self.db.attRewardCache) or {}) do
        id=tonumber(id)
        if id then candidates[id]=true end
    end
    local ids={}
    for id in pairs(candidates) do ids[#ids+1]=id end
    table.sort(ids)
    if #ids==0 then return false,"No items seen yet. Open your bank once, then update." end
    self._attRefreshRunning=true
    self._attRefreshProgress=string.format("0/%d",#ids)
    if self.RefreshATTCacheUI then self:RefreshATTCacheUI() end
    local index,found=1,0
    local function announce(msg)
        if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
            DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffLoot Liquidator|r: "..msg)
        elseif print then print("Loot Liquidator: "..msg) end
    end
    local function step()
        if index>#ids then
            self._attRefreshRunning=false
            self._attRefreshProgress=nil
            if self.Invalidate then self:Invalidate() end
            if self.RefreshATTCacheUI then self:RefreshATTCacheUI() end
            announce(string.format("ATT cache update complete: %d tokens found among %d unique IDs",found,#ids))
            return
        end
        local id=ids[index];index=index+1
        -- Only candidates that can be tokens; equipped gear is irrelevant.
        local link="item:"..id
        local f=self.GetItemFacts and self:GetItemFacts(link,{})
        if f then self:HarvestATTItemMetadata(f) end
        if f and NonEquippableSlot(f.equipLoc) then
            -- Force a fresh query but keep any last-known-good snapshot if
            -- ATT has not finished indexing the item this session.
            forceScanIDs[id]=true
            failedCache[id]=nil
            local info=self:ATTTokenInfo(f)
            forceScanIDs[id]=nil
            if info then found=found+1 end
        end
        if index%25==0 then
            self._attRefreshProgress=string.format("%d/%d",index-1,#ids)
            if self.RefreshATTCacheUI then self:RefreshATTCacheUI() end
        end
        if index%50==0 then announce(string.format("Updating ATT cache: %d/%d IDs",index-1,#ids)) end
        if C_Timer and type(C_Timer.After)=="function" then
            C_Timer.After(0.04,step)
        else
            self._attRefreshRunning=false
            self._attRefreshProgress=nil
            if self.RefreshATTCacheUI then self:RefreshATTCacheUI() end
            announce("ATT cache update needs WoW timer support")
        end
    end
    announce(string.format("Updating ATT cache for %d unique item IDs (one search at a time)",#ids))
    if C_Timer and type(C_Timer.After)=="function" then C_Timer.After(0,step)
    else self._attRefreshRunning=false;self._attRefreshProgress=nil
        if self.RefreshATTCacheUI then self:RefreshATTCacheUI() end
        return false,"WoW timer unavailable" end
    return true,string.format("Started update for %d unique item IDs",#ids)
end

-- Appearance collection can change mid-session; discard token snapshots so
-- T badges don't linger after learning a visual from another item.
local eventFrame=CreateFrame and CreateFrame("Frame")
if eventFrame and eventFrame.RegisterEvent then
    pcall(eventFrame.RegisterEvent,eventFrame,"TRANSMOG_COLLECTION_UPDATED")
    eventFrame:SetScript("OnEvent",function()
        if LL.Invalidate then LL:Invalidate() end
    end)
end
