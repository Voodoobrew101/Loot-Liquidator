-- Gear tokens from ItemDB's token catalog (C4b3) plus the transmog
-- collection check. C6: AllTheThings is no longer used in any way; every
-- token the addon recognises comes from ItemDB.tokenRewards.
-- A confirmed appearance is collected from ANY source via Blizzard API.
local _, LL = ...
local tokenCache = {}

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

-- One account-wide collection resolver for normal gear AND token rewards.
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
            and build and build>=r.patchStartBuild and build<=r.patchEndBuild
            and (r.inputClassID==nil or f.classID==r.inputClassID)
            and self:ValidateTokenCatalog({r}) then
            local data=tokenCache[f.id]
            if not data or data._catalogRecord~=r or data._catalogBuild~=build then
                local rewards={} for i,id in ipairs(r.rewards) do rewards[i]=id end
                local reviewed=r.independentReview=='APPROVED'
                data={rewards=rewards,kind=r.kind,costs=r.costs,standalone=true,
                    recordID=r.recordID,_catalogRecord=r,_catalogBuild=build,
                    catalogConfidence=r.confidence0to100,catalogReviewed=reviewed,
                    source=reviewed and 'Loot Liquidator reviewed reward catalog (possible outcomes; probabilities unknown)'
                        or 'Loot Liquidator research reward list, not yet reviewed (possible outcomes; probabilities unknown)'}
                tokenCache[f.id]=data
            end
            RefreshMissing(data,(GetTime and GetTime()) or 0)
            return data
        end
    end
end

-- C6: the one entry point for "is this a token, and what does it give".
function LL:TokenInfo(f)
    return self:StandaloneTokenInfo(f)
end

function LL:UncollectedAppearance(f)
    -- Direct equipment appearances come from Blizzard's collection API.
    if not f or (f.classID~=2 and f.classID~=4) then return nil end
    if self.IsIgnoredAction and self:IsIgnoredAction(f.id,"T") then return nil end
    -- No source ID, no guess; e.g. generated gear tokens don't themselves
    -- have a wearable appearance.
    return AppearanceMissing(f.link)
end

-- Compact, class-first presentation for multi-class raid and tier tokens.
-- ItemDB's token catalog is the source of items; DB2 allowable-class masks determine
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
function LL:TokenClassSummary(token)
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

-- The highest confirmed NPC sell price among the token's possible equipment
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

-- C4c (owner, session 12): a tier token never answers "?". Midnight tokens
-- show no sell price of their own, but the piece they open into has a game
-- sell price and is disenchantable (soulbound, so disenchanted by whoever
-- opens it). Value = this character's piece (class mask from ItemClassMasks);
-- when the class can't be matched, the CHEAPEST reward, never the best one.
function LL:TokenPieceQuote(f,token)
    if not token or type(token.rewards)~="table" or #token.rewards==0 then return nil end
    local info=C_Item and C_Item.GetItemInfo or GetItemInfo
    if type(info)~="function" then return nil end
    local class
    if UnitClass then local _,c=UnitClass("player"); class=c end
    local own,lowest
    for _,id in ipairs(token.rewards) do
        local ok,name,link,_,_,_,_,_,_,loc,_,sellPrice=pcall(info,id)
        if ok and type(sellPrice)=="number" and sellPrice>=0 and EquippableSlot(loc) then
            local quote={itemID=id,name=name,link=link or ("item:"..id),vendor=sellPrice}
            -- An exchange (curio) lets the player pick any of their pieces;
            -- an open token gives exactly one. Highest own piece covers both.
            if class and self.ItemPermitsClass and self:ItemPermitsClass(id,class)==true
                and (not own or sellPrice>own.vendor) then own=quote end
            if not lowest or sellPrice<lowest.vendor then lowest=quote end
        elseif C_Item and type(C_Item.RequestLoadItemDataByID)=="function" then
            pcall(C_Item.RequestLoadItemDataByID,id)
        end
    end
    local piece=own or lowest
    if not piece then return nil end
    piece.ownClass=own~=nil
    -- Disenchant value of the piece through the normal disenchant path, for
    -- this character's Enchanting. Any failure just leaves it out.
    if self.GetItemFacts and self.BestConversion then
        local ok,pf=pcall(self.GetItemFacts,self,piece.link,{count=1})
        if ok and type(pf)=="table" and pcall(self.BestConversion,self,pf) then
            for _,option in ipairs(pf.conversionOptions or {}) do
                if option.name=="Disenchant" and option.available
                    and type(option.value)=="number" and option.value>0 then
                    piece.disenchant=option.value
                    local model=option.yieldModel
                    piece.disenchantConfidence=model and (model.valueConfidence or model.confidence)
                    -- C4b3: an unreviewed token list can't be surer than its own confidence.
                    if type(token.catalogConfidence)=="number" and type(piece.disenchantConfidence)=="number" then
                        piece.disenchantConfidence=math.min(piece.disenchantConfidence,token.catalogConfidence)
                    end
                    break
                end
            end
        end
    end
    return piece
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

function LL:InvalidateTokenCache()
    for key in pairs(tokenCache) do tokenCache[key]=nil end
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
