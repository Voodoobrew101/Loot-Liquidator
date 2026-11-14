-- Gear tokens from ItemDB's token catalog (C4b3) plus the transmog
-- collection check. Live AllTheThings integration is retired; pinned ATT
-- Retail research may be compiled into the same ItemDB.tokenRewards catalog.
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
-- An uncollected item source must not hide a visual learned from another item.
-- Query all sources of this exact appearance without changing wardrobe filters;
-- class-filtered source lists can confirm ownership but cannot prove absence.
function LL:AppearanceCollectionState(link)
    local collection=C_TransmogCollection
    if not collection or type(collection.GetItemInfo)~="function" then return nil end
    local ok,appearanceID,sourceID=pcall(collection.GetItemInfo,link)
    if not ok then return nil end
    if not SafeNumber(sourceID) and not SafeNumber(appearanceID) then return nil end
    local function info(fn,id)
        if type(fn)~='function' or not SafeNumber(id) then return nil end
        local good,value=pcall(fn,id)
        if good and type(value)=='table' then return value end
    end
    local function boolean(value)
        return type(value)=='boolean' and not (issecretvalue and issecretvalue(value))
    end
    local function sameAppearance(value)
        return not SafeNumber(value) or not SafeNumber(appearanceID) or value==appearanceID
    end
    local newState,oldState
    local current=info(collection.GetAppearanceSourceInfo,sourceID)
    if current then
        if not SafeNumber(appearanceID) and SafeNumber(current.itemAppearanceID) then appearanceID=current.itemAppearanceID end
        if sameAppearance(current.itemAppearanceID) and boolean(current.isCollected) then newState=current.isCollected end
    end
    local legacy=info(collection.GetAppearanceInfoBySource,sourceID)
    if legacy then
        if not SafeNumber(appearanceID) and SafeNumber(legacy.appearanceID) then appearanceID=legacy.appearanceID end
        if sameAppearance(legacy.appearanceID) then
            if boolean(legacy.appearanceIsCollected) then oldState=legacy.appearanceIsCollected end
            -- An affirmative source is sufficient; a false source bit is not
            -- evidence that its shared appearance is absent.
            if boolean(legacy.sourceIsCollected) and legacy.sourceIsCollected then return true,sourceID,appearanceID end
        end
    end
    if newState==true or oldState==true then return true,sourceID,appearanceID end
    if SafeNumber(appearanceID) then
        if type(collection.GetAppearanceSources)=='function' then
            local good,sources=pcall(collection.GetAppearanceSources,appearanceID)
            if good and type(sources)=='table' then
                for _,source in ipairs(sources) do
                    if type(source)=='table' and sameAppearance(source.visualID)
                        and boolean(source.isCollected) and source.isCollected then return true,sourceID,appearanceID end
                end
            end
        end
        if type(collection.GetAllAppearanceSources)=='function' then
            local good,sources=pcall(collection.GetAllAppearanceSources,appearanceID)
            if good and type(sources)=='table' then
                local seen={}
                for _,id in ipairs(sources) do
                    if SafeNumber(id) and id~=sourceID and not seen[id] then
                        seen[id]=true
                        local source=info(collection.GetAppearanceSourceInfo,id)
                        if source and sameAppearance(source.itemAppearanceID)
                            and boolean(source.isCollected) and source.isCollected then return true,sourceID,appearanceID end
                        source=info(collection.GetAppearanceInfoBySource,id)
                        if source and sameAppearance(source.appearanceID)
                            and ((boolean(source.appearanceIsCollected) and source.appearanceIsCollected)
                                or (boolean(source.sourceIsCollected) and source.sourceIsCollected)) then return true,sourceID,appearanceID end
                        source=info(collection.GetSourceInfo,id)
                        if source and sameAppearance(source.visualID)
                            and boolean(source.isCollected) and source.isCollected then return true,sourceID,appearanceID end
                    end
                end
            end
        end
    end
    if newState==false or oldState==false then return false,sourceID,appearanceID end
    return nil,sourceID,appearanceID
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
        local link=LL.TokenRewardLink and LL:TokenRewardLink(data,id) or ("item:"..id)
        if AppearanceMissing(link)==true then missing=true;break end
    end
    data.possibleMissingAppearance=missing
    data._appearanceAt=now
end
local function FlattenRewards(self,record,seen,depth)
    if depth>4 or seen[record.tokenID] then return {},{},true end
    seen[record.tokenID]=true
    local rewards,links,unknown,added={},{},false,{}
    for _,id in ipairs(record.rewards or {}) do
        local child
        for _,candidate in ipairs(self._tokenRewardIndex and self._tokenRewardIndex[id] or {}) do
            local build=GetBuildInfo and tonumber((select(2,GetBuildInfo())))
            if build and build>=candidate.patchStartBuild and build<=candidate.patchEndBuild then child=candidate;break end
        end
        if child then
            local sub,subLinks,incomplete=FlattenRewards(self,child,seen,depth+1)
            unknown=unknown or incomplete or child.kind=='exchange'
            for _,reward in ipairs(sub) do
                if not added[reward] then rewards[#rewards+1]=reward;added[reward]=true end
                links[tostring(reward)]=subLinks[tostring(reward)]
            end
        elseif not added[id] then rewards[#rewards+1]=id;added[id]=true end
        if record.rewardLinks and record.rewardLinks[tostring(id)] then links[tostring(id)]=record.rewardLinks[tostring(id)] end
    end
    seen[record.tokenID]=nil
    table.sort(rewards)
    return rewards,links,unknown
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
                local rewards,links,chainCostUnknown=FlattenRewards(self,r,{},0)
                local reviewed=r.independentReview=='APPROVED'
                data={rewards=rewards,kind=r.kind,costs=r.costs,standalone=true,
                    rewardLinks=links,rewardSelection=r.rewardSelection,costsComplete=r.costsComplete,
                    chainCostUnknown=chainCostUnknown,candidateRewards=r.candidateRewards,catalogNote=r.sourceAssumption,
                    rewardClassMasks=r.rewardClassMasks,rewardRequirements=r.rewardRequirements,
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
        local rewardLink=self:TokenRewardLink(token,id)
        local cls=SingleClassFromMask((self.ItemClassMasks and self.ItemClassMasks[id])
            or (token.rewardClassMasks and token.rewardClassMasks[tostring(id)]))
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
            local ok,n,l=pcall(info,rewardLink)
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
            local ok,a=pcall(collection.GetItemInfo,rewardLink)
            if ok then appearance=a end
        end
        local collected=self:AppearanceCollectionState(rewardLink)
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
        local rewardLink=self:TokenRewardLink(token,id)
        local ok,name,link,_,_,_,_,_,_,loc,_,sellPrice=
            pcall(info,rewardLink)
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

local function Number(n)
    return type(n)=='number' and not (issecretvalue and issecretvalue(n)) and n==n and n>=0 and n<math.huge
end
local function Read(fn,...)
    if type(fn)~='function' then return nil end
    local ok,n=pcall(fn,...)
    return ok and Number(n) and n or nil
end
local function CanDisenchantFor(self,current,character)
    if self.AltMethodEnabled and not self:AltMethodEnabled(character,'D') then return false end
    return (current and self.CurrentHasEnchanting and self:CurrentHasEnchanting())
        or (not current and self.AltProfessionEligible and self:AltProfessionEligible(character,'D')) or false
end
function LL:TokenCostItemValue(id,current,character)
    local info=C_Item and C_Item.GetItemInfo or GetItemInfo
    if type(info)=='function' then
        local ok,name,_,_,_,_,_,_,_,_,_,vendor,_,_,binding=pcall(info,id)
        if ok and name and (binding==1 or binding==4) then
            -- Bound equipment has an immediate liquidation opportunity cost;
            -- an AH quote for an unobtainable/untradeable template isn't it.
            local best=Number(vendor) and vendor or nil
            if self.GetItemFacts and self.EvaluateDisenchant and CanDisenchantFor(self,current,character) then
                local good,facts=pcall(self.GetItemFacts,self,'item:'..id,{count=1,isBound=true,isSoulbound=true})
                if good and facts then
                    local priced,estimate=pcall(self.EvaluateDisenchant,self,facts,character)
                    if priced and estimate and Number(estimate.value) then best=math.max(best or 0,estimate.value) end
                end
            end
            return best
        end
    end
    return self.GetOutputPrice and self:GetOutputPrice(id)
end

-- Costs are per redemption; all quotes below are per original token. Currency
-- balances prove ownership, never a made-up copper exchange rate. A priced but
-- unaffordable exchange is still informative and is not an available action.
function LL:TokenRedemptionCost(f,token,rewardID,current,character)
    if token.costsComplete==false or token.chainCostUnknown or token.candidateRewards then
        return {known=false,available=false,inputCount=1,reason=token.catalogNote or 'Complete redemption-chain costs not established'}
    end
    local result={known=true,available=true,value=0,inputCount=token.kind=='exchange' and 0 or 1}
    local char=self.db and self.db.characters and self.db.characters[character]
    local level=current and Read(UnitLevel,'player') or (char and char.level)
    -- Native use-level applies before opening too. Query the actual token
    -- variant instead of inferring a requirement from its tier or name.
    local info=C_Item and C_Item.GetItemInfo or GetItemInfo
    if type(info)=='function' then
        local ok,_,_,_,_,requiredLevel=pcall(info,f.link or f.id)
        if ok and Number(requiredLevel) and requiredLevel>1
            and (not Number(level) or level<requiredLevel) then
            result.available=false;result.reason='Token requires level '..tostring(requiredLevel)
        end
    end
    local requirement=token.rewardRequirements and token.rewardRequirements[tostring(rewardID)]
    if requirement then
        if requirement.unverified or (requirement.minimumLevel and (not Number(level) or level<requirement.minimumLevel)) then
            result.available=false;result.reason='Reward level, faction or inherited exchange requirements not verified for this character'
        end
    end
    if token.kind~='exchange' then return result end
    local costs=token.costs and token.costs[tostring(rewardID)]
    if type(costs)~='table' or #costs==0 then
        return {known=false,available=false,inputCount=1,reason='Exchange costs not established'}
    end
    local counts=C_Item and C_Item.GetItemCount or GetItemCount
    for _,cost in ipairs(costs) do
        local quantity=cost.quantity
        if not Number(quantity) or quantity<=0 then
            result.known=false;result.available=false;result.reason='Invalid exchange cost'
        elseif cost.kind=='item' and cost.id==f.id then
            result.inputCount=result.inputCount+quantity
        else
            local unit,balance
            if cost.kind=='money' then unit=1;balance=current and Read(GetMoney)
            elseif cost.kind=='item' then
                unit=self:TokenCostItemValue(cost.id,current,character)
                balance=current and Read(counts,cost.id,false,false)
            elseif cost.kind=='currency' then
                local api=C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo
                if current and type(api)=='function' then
                    local ok,info=pcall(api,cost.id)
                    if ok and type(info)=='table' and Number(info.quantity) then balance=info.quantity end
                end
            end
            if Number(unit) then result.value=result.value+unit*quantity
            else result.known=false;result.reason='Additional '..tostring(cost.kind)..' cost has no verified gold value' end
            if not balance or balance<quantity then
                result.available=false;result.reason=result.reason or (current and 'Additional exchange costs unavailable' or 'Alt exchange inventory not verified')
            end
        end
    end
    if result.inputCount<=0 then result.known=false;result.available=false;result.inputCount=1;result.reason='Token exchange quantity not established'
    elseif (f.count or 1)<result.inputCount then result.available=false;result.reason='Not enough tokens for one exchange' end
    return result
end

-- A collection recommendation means keep this token for a missing appearance.
-- It does not promise that its owner can pay the exchange costs immediately.
-- An unverified reward relationship or character requirement cannot certify a
-- look; unknown prices and additional chain costs do not make it disposable.
function LL:TokenAppearanceEligibility(token,rewardID,current,character)
    if token.candidateRewards then
        return false,token.catalogNote or 'Reward relationship not established'
    end
    local requirement=token.rewardRequirements and token.rewardRequirements[tostring(rewardID)]
    if requirement then
        local char=self.db and self.db.characters and self.db.characters[character]
        local level=current and Read(UnitLevel,'player') or (char and char.level)
        if requirement.unverified or (requirement.minimumLevel and (not Number(level) or level<requirement.minimumLevel)) then
            return false,'Reward level, faction or inherited exchange requirements not verified for this character'
        end
    end
    return true
end

function LL:TokenRewardPermitsClass(token,id,class)
    local allowed=self.ItemPermitsClass and self:ItemPermitsClass(id,class)
    if allowed~=nil then return allowed end
    local mask=token.rewardClassMasks and token.rewardClassMasks[tostring(id)]
    if type(mask)=='number' then
        for _,entry in ipairs(TOKEN_CLASSES) do
            if entry[2]==class then return math.floor(mask/2^(entry[1]-1))%2==1 end
        end
    end
end

function LL:TokenRewardLink(token,id)
    -- A recorded exact reward link can establish its variant. Never copy bonus
    -- IDs from a token to unrelated gear or pass an ID query off as that variant.
    local link=token.rewardLinks and token.rewardLinks[tostring(id)]
    if type(link)=='string' and tonumber(link:match('item:(%d+)'))==id then return link,true end
    return 'item:'..id,false
end

local function recipients(self,f)
    local key=self.CharacterKey and self:CharacterKey()
    local chars=self.db and self.db.characters or {}
    local class=chars[key] and chars[key].class
    if not class and UnitClass then local _,c=UnitClass('player');class=c end
    local out={{key=key or 'Current character',class=class,current=true}}
    if self.db and self.db.includeVerifiedAlts~=false and self.CanTransferToAlt and self:CanTransferToAlt(f) then
        local keys={}
        for name in pairs(chars) do if name~=key then keys[#keys+1]=name end end
        table.sort(keys)
        for _,name in ipairs(keys) do
            if chars[name].class and (not chars[name].altMethods or chars[name].altMethods.all~=false) then
                out[#out+1]={key=name,class=chars[name].class,current=false}
            end
        end
    end
    return out
end

function LL:TokenPieceQuote(f,token)
    if not token or type(token.rewards)~='table' or #token.rewards==0 then return nil end
    local info=C_Item and C_Item.GetItemInfo or GetItemInfo
    if type(info)~='function' then return nil end
    local people=recipients(self,f)
    local wanted,hasWanted={},false
    for _,who in ipairs(people) do
        if not self.ItemPermitsClass or self:ItemPermitsClass(f.id,who.class)~=false then
            for _,id in ipairs(token.rewards) do
                if self:TokenRewardPermitsClass(token,id,who.class)==true then wanted[id]=true;hasWanted=true end
            end
        end
    end
    local loaded,reference={},nil
    for _,id in ipairs(token.rewards) do
        if not hasWanted or wanted[id] then
        local query,exact=self:TokenRewardLink(token,id)
        local ok,name,link,_,_,_,_,_,_,loc,_,sell=pcall(info,query)
        if ok and name and EquippableSlot(loc) then
            local row={itemID=id,name=name,link=query,vendorGross=Number(sell) and sell or nil,variantVerified=exact}
            loaded[id]=row
            if row.vendorGross~=nil and (not reference or row.vendorGross<reference.vendorGross
                or (row.vendorGross==reference.vendorGross and id<reference.itemID)) then reference=row end
        elseif C_Item and type(C_Item.RequestLoadItemDataByID)=='function' then
            pcall(C_Item.RequestLoadItemDataByID,id)
        end
        end
    end
    local best
    for _,who in ipairs(people) do
        local allowed=self.ItemPermitsClass and who.class and self:ItemPermitsClass(f.id,who.class)
        local own,missing={},false
        if allowed~=false then
            for _,id in ipairs(token.rewards) do
                local permits=who.class and self:TokenRewardPermitsClass(token,id,who.class)
                if permits==true then
                    if loaded[id] then own[#own+1]=loaded[id] else missing=true end
                end
            end
        end
        local chosen,deChosen,informative,deComplete=nil,nil,nil,not missing
        for _,row in ipairs(own) do
            local cost=self:TokenRedemptionCost(f,token,row.itemID,who.current,who.key)
            if token.kind=='exchange' and self.AltMethodEnabled and not self:AltMethodEnabled(who.key,'X') then
                cost.available=false;cost.reason='Exchanges disabled for this character'
            end
            local quote={itemID=row.itemID,name=row.name,link=row.link,vendorGross=row.vendorGross,
                variantVerified=row.variantVerified,ownClass=true,current=who.current,character=who.key,
                cost=cost,reason=cost.reason,inputCount=cost.inputCount}
            informative=informative or quote
            if cost.known and row.vendorGross~=nil then quote.vendor=(row.vendorGross-cost.value)/cost.inputCount end
            local choice=token.kind=='exchange' or token.rewardSelection=='choice'
            if missing and not choice and not quote.reason then quote.reason='Some possible class rewards are still loading' end
            quote.vendorAvailable=quote.vendor~=nil and cost.available and (not missing or choice)
            -- Multiple same-class possibilities can be loot-spec-dependent.
            -- Without a verified choice use the least result, never the best.
            if quote.vendor~=nil and (not chosen or
                (choice and quote.vendorAvailable and not chosen.vendorAvailable) or
                ((not choice or quote.vendorAvailable==chosen.vendorAvailable) and
                    ((choice and quote.vendor>chosen.vendor) or (not choice and quote.vendor<chosen.vendor)))) then chosen=quote end
            if self.GetItemFacts and self.EvaluateDisenchant and cost.known then
                if CanDisenchantFor(self,who.current,who.key) then
                    -- The opener receives soulbound gear. Another enchanter
                    -- must never become eligible by mailing the redeemed item.
                    local ok,pf=pcall(self.GetItemFacts,self,row.link,{count=1,isBound=true,isSoulbound=true})
                    if ok and pf then
                        local good,estimate=pcall(self.EvaluateDisenchant,self,pf,who.key)
                        if good and estimate and Number(estimate.value) then
                            quote.disenchant=(estimate.value-cost.value)/cost.inputCount
                            quote.disenchantModel=estimate.yieldModel
                            local confidence=estimate.yieldModel and not estimate.yieldModel.confidenceUnscored
                                and (estimate.yieldModel.valueConfidence or estimate.yieldModel.confidence)
                            quote.disenchantConfidence=type(confidence)=='number' and math.min(confidence,token.catalogConfidence or confidence) or nil
                            quote.disenchantAvailable=cost.available and (not missing or choice)
                        end
                    end
                end
            end
            if quote.disenchant==nil then deComplete=false
            elseif not deChosen or (choice and quote.disenchantAvailable and not deChosen.disenchantAvailable)
                or ((not choice or quote.disenchantAvailable==deChosen.disenchantAvailable) and
                    ((choice and quote.disenchant>deChosen.disenchant) or (not choice and quote.disenchant<deChosen.disenchant))) then deChosen=quote end
        end
        if chosen or deChosen or informative then
            local piece=chosen or deChosen or informative
            if deChosen then
                -- Vendor and disenchant can favor different rewards. Preserve
                -- the complete DE quote so its identity, variant and costs stay
                -- attached to the value used by the recommendation/tooltip.
                local reward={}
                for k,v in pairs(deChosen) do reward[k]=v end
                if not reward.variantVerified then reward.variantNote='Base reward estimate; token difficulty/bonus variant not verified' end
                piece.disenchantReward=reward
                piece.disenchant=deChosen.disenchant;piece.disenchantModel=deChosen.disenchantModel
                piece.disenchantConfidence=deChosen.disenchantConfidence;piece.disenchantItemID=deChosen.itemID
                piece.disenchantAvailable=deChosen.disenchantAvailable and (token.kind=='exchange' or token.rewardSelection=='choice' or deComplete)
            end
            piece.partial=missing or nil
            local value=math.max(piece.vendorAvailable and piece.vendor or 0,piece.disenchantAvailable and piece.disenchant or 0)
            if not best or value>best._availableValue then piece._availableValue=value;best=piece end
        end
    end
    if best then
        if not best.variantVerified then best.variantNote='Base reward estimate; token difficulty/bonus variant not verified' end
        return best
    end
    -- Retain a known reference number even for an excluded/unknown class.
    -- It is displayed as information and cannot create an opening action.
    if reference then
        local cost=self:TokenRedemptionCost(f,token,reference.itemID,true)
        return {itemID=reference.itemID,name=reference.name,link=reference.link,vendorGross=reference.vendorGross,
            vendor=cost.known and (reference.vendorGross-cost.value)/cost.inputCount or nil,
            ownClass=false,vendorAvailable=false,disenchantAvailable=false,cost=cost,
            variantNote='Base reward estimate; token difficulty/bonus variant not verified',
            reason='No verified eligible reward for this character or a transferable enabled alt'}
    end
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
    for _,event in ipairs({'TRANSMOG_COLLECTION_UPDATED','TRANSMOG_COLLECTION_SOURCE_ADDED',
        'TRANSMOG_COLLECTION_SOURCE_REMOVED','TRANSMOG_COLLECTION_ITEM_UPDATE'}) do
        pcall(eventFrame.RegisterEvent,eventFrame,event)
    end
    eventFrame:SetScript("OnEvent",function()
        if LL.Invalidate then LL:Invalidate() end
    end)
end
