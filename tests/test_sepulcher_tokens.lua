-- The Mystic Helm Module can produce three classes' helmets across four raid difficulties.
local function eq(actual,expected,message)
    assert(actual==expected,message..': '..tostring(actual)..' ~= '..tostring(expected))
end

CreateFrame=function() return {RegisterEvent=function()end,SetScript=function()end} end
GetBuildInfo=function() return '12.1.5','70783','',120105 end
GetTime=function() return 100 end
time=function() return 1000 end
UnitClass=function() return 'Druid','DRUID',11 end
UnitLevel=function() return 90 end
GetMoney=function() return 0 end
SlashCmdList={}
WOW_PROJECT_ID=1;WOW_PROJECT_MAINLINE=1
wipe=function(t) for key in pairs(t) do t[key]=nil end return t end

local LL={}
for _,file in ipairs({'ItemDBRuntime.lua','Core.lua','Professions.lua','ProfessionModels.lua',
    'Database.lua','WagoClassEligibility.lua','ConversionEngine.lua','Tokens.lua'}) do
    assert(loadfile('LootLiquidator/'..file))('LootLiquidator',LL)
end
LL.db={enabled=true,includeVerifiedAlts=true,showSoulboundVendorBadge=true,
    processingModes={},characters={
        ['Main-Realm']={class='DRUID',level=90,professions={}},
        ['Alt-Realm']={class='HUNTER',level=90,professions={}},
    }}
LL.CharacterKey=function() return 'Main-Realm' end
LL.Price=function() return nil end
LL.ReportMissing=function() end
LL.ProfessionProgression=function() return {} end

local function isToken(id) return id and id>=191002 and id<=191021 end
local function itemID(value)
    return tonumber(value) or tonumber(tostring(value):match('item:(%d+)'))
end
local function itemLink(id,context)
    local raw='item:'..id
    if context then raw=raw..':::::::::::'..context..':1:3524' end
    return '|cffa335ee|H'..raw..'|h[Item '..id..']|h|r'
end

local records,bySource={},{}
for _,record in ipairs(LL.ItemDB.tokenRewards) do
    if isToken(record.tokenID) then
        assert(not records[record.tokenID],'duplicate Sepulcher token')
        records[record.tokenID]=record
        for context,rewards in pairs(record.rewardVariants) do
            for reward,source in pairs(rewards) do
                bySource[source]={reward=tonumber(reward),context=tonumber(context)}
            end
        end
    end
end

C_Item={
    GetItemInfo=function(value)
        local id=itemID(value)
        if not id then return end
        local token=isToken(id)
        return 'Item '..id,value,4,70,60,token and 'Miscellaneous' or 'Armor','',1,
            token and 'INVTYPE_NON_EQUIP' or 'INVTYPE_HEAD',0,token and 50000 or 200000,
            token and 15 or 4,1,1,8
    end,
    GetItemInfoInstant=function(value)
        local id=itemID(value)
        local token=isToken(id)
        return id,token and 'Miscellaneous' or 'Armor','',token and 'INVTYPE_NON_EQUIP' or 'INVTYPE_HEAD',
            0,token and 15 or 4,1
    end,
    RequestLoadItemDataByID=function() end,
}

local missingSource
local function sourceInfo(source)
    local entry=bySource[source]
    if not entry then return end
    return {itemAppearanceID=source+200000,itemLink=itemLink(entry.reward,entry.context),
        isCollected=source~=missingSource}
end
C_TransmogCollection={
    GetAppearanceSourceInfo=sourceInfo,
    GetAppearanceInfoBySource=function(source)
        local info=sourceInfo(source)
        if info then
            return {appearanceID=info.itemAppearanceID,appearanceIsCollected=info.isCollected,
                sourceIsCollected=info.isCollected,appearanceIsUsable=bySource[source].reward==188847}
        end
    end,
}

assert(LL:InitializeItemDB(),LL.itemDBError)
local warbound={verifiedWarbound=true,isBound=true,count=1}
for token=191002,191021 do
    local record=assert(records[token],'missing Sepulcher record '..token)
    eq(record.kind,'open','class set token is opened')
    eq(#record.rewards,3,'three class rewards per token')
    for _,context in ipairs({3,4,5,6}) do
        local info=assert(LL:TokenInfo({id=token,link=itemLink(token,context),equipLoc=''}))
        for _,reward in ipairs(record.rewards) do
            eq(info.rewardSources[tostring(reward)],record.rewardVariants[tostring(context)][tostring(reward)],
                'runtime source matches the item context')
        end
    end
end

local function decide(context,transfer)
    return assert(LL:Evaluate(itemLink(191002,context),transfer or warbound))
end
local druidSources={166069,166070,166071,166072}
for context=3,6 do
    eq(records[191002].rewardVariants[tostring(context)]['188847'],druidSources[context-2],
        'known Druid helm source')
end

missingSource=166072
LL:Invalidate()
local decision=decide(6)
eq(decision.action,'T','the missing Mythic Druid look is kept')
eq(decision.transmogRecipient.rewardID,188847,'selects the current class reward')
eq(decision.transmogRecipient.current,true,'current character qualifies')
for context=3,5 do
    eq(decide(context).action,'V','collected difficulties have independent cache entries')
end
eq(decide(6).action,'T','switching difficulties leaves the Mythic decision intact')
eq(decide().action,'Q','missing context leaves appearance selection unresolved')

missingSource=166114
LL:Invalidate()
decision=decide(6)
eq(decision.action,'T','a verified transferable token keeps the Hunter alt look')
eq(decision.transmogRecipient.rewardID,188859,'selects the documented Hunter reward')
eq(decision.transmogRecipient.name,'Alt-Realm','offline alt is chosen by its explicit class')
eq(decision.transmogRecipient.current,false,'current class cannot redeem Hunter equipment')
eq(decide(6,{isSoulbound=true,isBound=true,count=1}).action,'Q','binding prevents the alt recommendation')
LL.db.characters['Alt-Realm'].class='WARRIOR'
LL:Invalidate()
eq(decide(6).action,'Q','an excluded class cannot be recommended')

missingSource=nil
LL:Invalidate()
decision=decide(6)
eq(decision.action,'V','a complete, collected variant can be sold')
eq(decision.tokenQuote.value,50000,'vendor recommendation uses the token price')
assert(not decision.tokenQuote.piece,'redeemed equipment prices cannot substitute for the token price')
local cost=LL:TokenRedemptionCost(decision.facts,decision.tokenInfo,188847,true,'Main-Realm')
eq(cost.known,false,'unverified redemption valuation stays unknown')
eq(cost.available,false,'redemption is not recommended as liquidation')

print('PASS: all Sepulcher tokens, four appearance contexts, alt eligibility, and safe vendor behavior')
