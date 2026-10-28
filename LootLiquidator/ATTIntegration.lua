-- Optional ATT adapter. Never ships ATT's token catalog.
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
    store[key]={rewards=rewards,kind=data.kind}
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
    if self.db and self.db.enableATTIntegration==false then return nil end
    local app=ATT()
    if not app or not f or not SafeNumber(f.id) then return nil end
    -- Raw trade goods (ores, herbs and reagents) can be ATT ingredients for
    -- crafted gear. This does NOT make them redeemable armor tokens. Their
    -- exchange/crafting value belongs in the conversion engine instead.
    -- Also ignore any stale token snapshots saved for these reagents.
    if f.classID==7 and type(f.subClassID)=="number" then return nil end
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
    -- Opening/redrawing the Warbank must not launch uncached ATT database
    -- searches. The user can update once on demand (or hover a token).
    if f.context and f.context._LLFastBadge then return nil end
    if not forced and failedCache[f.id] and now-failedCache[f.id]<60 then return nil end
    -- A token may be opened with a spell OR exchanged for equipment.
    -- ATT indexes the latter in its reverse cost cache (itemIDAsCost).
    -- Only a verified, gear-producing relationship counts as a token.
    if type(app.SearchForField)~="function" then return nil end
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
    local items,seen={},{}
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
        if type(node)~="table" or depth>3 or #items>=50 then return end
        EquipID(node.itemID)
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
            if #items>=50 then break end
            local needsThis=false
            for _,cost in ipairs(node.cost or {}) do
                if type(cost)=="table" and cost[1]=="i" and cost[2]==f.id then
                    needsThis=true;break
                end
            end
            if needsThis then EquipID(node.itemID) end
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
    data._cachedAt=now
    data._appearanceAt=now
    tokenCache[f.id]=data
    failedCache[f.id]=nil
    SaveReward(self,f.id,data)
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
            group={slot=slot,ids={},rows={},looks={},classMasks={},collected=0,missing=0,unknown=0,count=0}
            grouped[slot]=group
        end
        local appearanceID,sourceID
        if collection and type(collection.GetItemInfo)=="function" then
            local ok,aid,sid=pcall(collection.GetItemInfo,"item:"..itemID)
            if ok and SafeNumber(aid) and SafeNumber(sid) then
                appearanceID,sourceID=aid,sid
            end
        end
        local state=self:AppearanceCollectionState("item:"..itemID)
        local mask=self.ItemClassMasks and self.ItemClassMasks[itemID]
        if type(mask)=="number" and mask>0 then
            group.classMasks[mask]=true
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
        group.classMasks=nil
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
        local appearance,source
        if collection and type(collection.GetItemInfo)=="function" then
            local ok,a,s=pcall(collection.GetItemInfo,"item:"..id)
            if ok then appearance,source=a,s end
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
        local ok,name,link,quality,level,required,className,subClass,stack,loc,icon,sellPrice=
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
-- Possible output's TSM Destroy is only a QUOTE, not the token's expected
-- value. Rank nothing from token quotes without verified odds and class rules.
function LL:TokenDEQuotes(f,token,enchanter)
    if not token or not enchanter then return nil end
    local out={}
    local fn=C_Item and C_Item.GetItemInfo or GetItemInfo
    if type(fn)~="function" then return nil end
    if not enchanter.class or not self.ItemPermitsClass
        or self:ItemPermitsClass(f.id,enchanter.class)==false then return nil end
    for _,id in ipairs(token.rewards) do
        -- ATT class sets cannot be disenchanted by an unrelated class. A
        -- checked alt must legally be able to redeem the actual reward.
        if self:ItemPermitsClass(id,enchanter.class)==true then
        local ok,_,_,quality,_,_,_,_,_,slot,_,_,class=pcall(fn,id)
        if ok and (class==2 or class==4) and quality and quality>=2 and quality<=4
            and type(slot)=="string" and slot~=""
            and not (self.ExternalDisenchantRestriction and self:ExternalDisenchantRestriction(id)) then
            local value=nil -- No aggregate TSM Destroy valuation for token rewards.
            if type(value)=="number" and value>0 then
                out[#out+1]={itemID=id,value=value*(1-(self.AHFeeRate and self:AHFeeRate() or 0))}
            end
        end
        end
    end
    table.sort(out,function(a,b)return a.value>b.value end)
    return #out>0 and out or nil
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

-- Manual on-demand update. The first bank draw NEVER runs these searches;
-- each unique observed ID is scanned once, at most one per timer callback.
function LL:StartATTCacheUpdate()
    if not self:ATTAvailable() then return false,"ATT is disabled or unavailable" end
    if self._attRefreshRunning then return false,"ATT cache update already running" end
    local candidates={}
    for id in pairs(seenTokenIDs) do candidates[id]=true end
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
