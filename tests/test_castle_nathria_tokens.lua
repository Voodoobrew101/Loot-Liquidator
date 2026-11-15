-- Castle Nathria tokens are Covenant exchanges with difficulty-specific appearances.
local function eq(actual,expected,message)
    assert(actual==expected,message..': '..tostring(actual)..' ~= '..tostring(expected))
end

CreateFrame=function() return {RegisterEvent=function()end,SetScript=function()end} end
GetBuildInfo=function() return '12.1.5','70783','',120105 end
GetTime=function() return 100 end
time=function() return 1000 end
UnitClass=function() return 'Warrior','WARRIOR',1 end
UnitLevel=function() return 90 end
GetMoney=function() return 0 end
SlashCmdList={}
WOW_PROJECT_ID=1;WOW_PROJECT_MAINLINE=1
wipe=function(t) for key in pairs(t) do t[key]=nil end return t end

local LL={db={}}
for _,file in ipairs({'ItemDBRuntime.lua','Core.lua','Professions.lua','ProfessionModels.lua',
    'Database.lua','WagoClassEligibility.lua','ConversionEngine.lua','Tokens.lua'}) do
    assert(loadfile('LootLiquidator/'..file))('LootLiquidator',LL)
end
LL.db={enabled=true,includeVerifiedAlts=true,showSoulboundVendorBadge=true,
    processingModes={},characters={['Main-Realm']={class='WARRIOR',level=90,professions={}}}}
LL.CharacterKey=function() return 'Main-Realm' end
LL.Price=function() return nil end
LL.ReportMissing=function() end
LL.ProfessionProgression=function() return {} end

local expectedCounts={8,8,43,43,43,43,8,8,43,43,43,43}
local function isToken(id) return id and id>=183888 and id<=183899 end
local function itemID(value)
    return tonumber(value) or tonumber(tostring(value):match('item:(%d+)'))
end
local function itemLink(id,context)
    local rawLink='item:'..id
    if context then rawLink=rawLink..':::::::::::'..context..':1:3524' end
    return '|cffa335ee|H'..rawLink..'|h[Item '..id..']|h|r'
end

local byID,rewardBySource,baseSourceByReward,mythicSourceByReward={},{},{},{}
for _,record in ipairs(LL.ItemDB.tokenRewards) do
    if isToken(record.tokenID) then
        assert(not byID[record.tokenID],'duplicate Castle Nathria token')
        byID[record.tokenID]=record
        for context,variants in pairs(record.rewardVariants) do
            for reward,sourceID in pairs(variants) do
                local rewardID=tonumber(reward)
                rewardBySource[sourceID]=rewardID
                if context=='6' or context=='85' then
                    mythicSourceByReward[rewardID]=sourceID
                elseif context=='3' or context=='82' then
                    baseSourceByReward[rewardID]=sourceID
                end
            end
        end
    end
end

C_Item={
    GetItemInfo=function(value)
        local id=itemID(value)
        if not id then return end
        local token=isToken(id)
        return 'Item '..id,value,4,70,50,token and 'Miscellaneous' or 'Weapon','',
            1,token and 'INVTYPE_NON_EQUIP' or 'INVTYPE_2HWEAPON',0,
            token and 50000 or 200000,token and 15 or 2,1,1,8
    end,
    GetItemInfoInstant=function(value)
        local id=itemID(value)
        local token=isToken(id)
        return id,token and 'Miscellaneous' or 'Weapon','',
            token and 'INVTYPE_NON_EQUIP' or 'INVTYPE_2HWEAPON',0,token and 15 or 2,1
    end,
    RequestLoadItemDataByID=function() end,
}

local activeCovenant=1
C_Covenants={GetActiveCovenantID=function() return activeCovenant end}
local missingSource,unknownSource
local nativeUsable=true
local function sourceInfo(sourceID)
    local rewardID=rewardBySource[sourceID]
    if not rewardID or sourceID==unknownSource then return nil end
    local context=mythicSourceByReward[rewardID]==sourceID and 6 or nil
    return {itemID=rewardID,itemAppearanceID=sourceID+200000,visualID=sourceID+200000,
        itemLink=itemLink(rewardID,context),isCollected=sourceID~=missingSource}
end
C_TransmogCollection={
    GetItemInfo=function(link)
        local rewardID=itemID(link)
        local mythic=tostring(link):find(':::::::::::6:',1,true)
        local sourceID=(mythic and mythicSourceByReward or baseSourceByReward)[rewardID]
        if sourceID then return sourceID+200000,sourceID end
    end,
    GetAppearanceSourceInfo=sourceInfo,
    GetSourceInfo=sourceInfo,
    GetAppearanceInfoBySource=function(sourceID)
        local info=sourceInfo(sourceID)
        if info then
            return {appearanceID=info.itemAppearanceID,appearanceIsCollected=info.isCollected,
                sourceIsCollected=info.isCollected,appearanceIsUsable=nativeUsable}
        end
    end,
}

assert(LL:InitializeItemDB(),LL.itemDBError)
local warbound={verifiedWarbound=true,isBound=true,count=1}
for id=183888,183899 do
    local record=assert(byID[id],'missing Castle Nathria catalog record '..id)
    eq(#record.rewards,expectedCounts[id-183887],'reward count for '..id)
    eq(record.kind,'exchange','Covenant redemption for '..id)
    eq(record.costsComplete,false,'incomplete exchange economics for '..id)
    local context=id<183894 and 3 or 82
    local facts=assert(LL:GetItemFacts(itemLink(id,context),warbound))
    assert(LL:TokenInfo(facts),'token lookup for '..id)
end

local zenith=183890
local kyrianReward=184272
local normalSource,mythicSource=115589,115590
eq(byID[zenith].rewardVariants['3'][tostring(kyrianReward)],normalSource,'normal Kyrian reward source')
eq(byID[zenith].rewardVariants['6'][tostring(kyrianReward)],mythicSource,'Mythic Kyrian reward source')
eq(byID[zenith].rewardRequirements[tostring(kyrianReward)].covenantID,1,'Kyrian vendor requirement')

local function decide(context)
    LL:Invalidate()
    return assert(LL:Evaluate(itemLink(zenith,context),warbound))
end

missingSource=mythicSource
local result=decide(6)
eq(result.action,'T','eligible missing Mythic appearance is kept')
eq(result.transmogRecipient.rewardID,kyrianReward,'native source resolves the missing reward')
eq(result.transmogRecipient.current,true,'active Covenant qualifies the current character')
eq(result.vendor,50000,'guaranteed token vendor price is retained')
local cost=LL:TokenRedemptionCost(result.facts,result.tokenInfo,kyrianReward,true,'Main-Realm')
eq(cost.known,false,'collection check does not certify complete exchange costs')
eq(cost.available,false,'collection check does not recommend immediate liquidation')
local normalResult=assert(LL:Evaluate(itemLink(zenith,3),warbound))
eq(normalResult.action,'V','the collected normal appearance is distinct from Mythic in the same cache')

activeCovenant=4
eq(decide(6).action,'Q','uncollected Kyrian appearance requires review from another Covenant')
activeCovenant=0
eq(decide(6).action,'Q','missing appearance remains protected without an active Covenant')
activeCovenant=1
nativeUsable=false
eq(decide(6).action,'Q','missing weapon stays protected if the current class cannot use it')
nativeUsable=true
eq(decide().action,'Q','missing link context requires review')
eq(decide(999).action,'Q','unrecognized link context requires review')

missingSource=nil
unknownSource=mythicSource
eq(decide(6).action,'Q','unloaded exact appearance cannot certify vendoring')
unknownSource=nil
result=assert(LL:Evaluate(itemLink(zenith,6),warbound))
eq(result.action,'V','known collected appearances allow selling the token')
eq(result.tokenQuote.value,50000,'vendor quote uses the token price')
assert(not result.tokenQuote.piece,'higher equipment vendor prices do not leak into recommendations')

local highApogee=byID[183895]
local lfrSources=0
for _ in pairs(highApogee.rewardVariants['83']) do lfrSources=lfrSources+1 end
eq(lfrSources,6,'high-item-level Apogee LFR has six exact sources in ATT')
local incompleteResult=assert(LL:Evaluate(itemLink(183895,83),warbound))
eq(incompleteResult.action,'Q','partial variant evidence does not certify vendoring')

print('PASS: Castle Nathria token coverage, exact appearance difficulty, Covenant eligibility, and vendor protection')
