-- Ulduar Wayward and related Naxxramas Lost variants must reach the same
-- catalog/collection/tooltip path. Reproduce all nine supplied Wayward tooltips.
local checks=0
local function check(value,message) assert(value,message);checks=checks+1 end
local function eq(actual,expected,message)
    check(actual==expected,(message or '')..': '..tostring(actual)..' ~= '..tostring(expected))
end
CreateFrame=function() return {RegisterEvent=function()end,SetScript=function()end} end
GetBuildInfo=function() return '12.1.5','70783','',120105 end
GetTime=function() return 100 end
time=function() return 1000 end
UnitClass=function() return 'Druid','DRUID' end
local playerLevel,tokenRequiredLevel=90,1
UnitLevel=function() return playerLevel end
GetMoney=function() return 0 end
SlashCmdList={};WOW_PROJECT_ID=1;WOW_PROJECT_MAINLINE=1
wipe=function(t) for key in pairs(t) do t[key]=nil end return t end
local LL={db={}}
for _,name in ipairs({'ItemDBRuntime.lua','Core.lua','Professions.lua','ProfessionModels.lua',
    'Database.lua','WagoClassEligibility.lua','ConversionEngine.lua','Tokens.lua','Badges.lua'}) do
    assert(loadfile('LootLiquidator/'..name))('LootLiquidator',LL)
end
LL.db={enabled=true,tooltipDetail=3,includeVerifiedAlts=true,showSoulboundVendorBadge=true,
    processingModes={},characters={
        ['Main-Realm']={class='DRUID',level=90,professions={}},
        ['Hunter-Realm']={class='HUNTER',level=90,professions={}},
        ['Paladin-Realm']={class='PALADIN',level=90,professions={}}}}
LL.CharacterKey=function() return 'Main-Realm' end
LL.Price=function() return nil end
LL.ReportMissing=function() end
LL.ProfessionProgression=function() return {} end
LL.MarkupColor=function() return '' end
LL.Money=function(_,value) return tostring(value)..' copper' end
LL.GetOutputPrice=function() return nil end
local function itemID(value) return tonumber(value) or tonumber(tostring(value):match('item:(%d+)')) end
local function isToken(id)
    return id and ((id>=45632 and id<=45661) or (id>=40610 and id<=40639))
end
C_Item={GetItemInfo=function(value)
    local id=itemID(value)
    if not id then return end
    local token=isToken(id)
    return token and ('Tier token '..id) or ('Equipment '..id),'item:'..id,4,42,token and tokenRequiredLevel or 1,
        'Armor','Armor',1,token and 'INVTYPE_NON_EQUIP_IGNORE' or 'INVTYPE_HEAD',0,
        token and 50000 or 10000,token and 15 or 4,3,1,2
end,GetItemInfoInstant=function(value)
    local id=itemID(value);local token=isToken(id)
    return id,'Armor','Armor',token and 'INVTYPE_NON_EQUIP_IGNORE' or 'INVTYPE_HEAD',0,token and 15 or 4,3
end,GetItemCount=function() return 0 end,RequestLoadItemDataByID=function()end}
local missing,unknown
C_TransmogCollection={GetItemInfo=function(value)
    local id=itemID(value);return id,id
end,GetAppearanceSourceInfo=function(id)
    if id==unknown then return {} end
    return {itemAppearanceID=id,isCollected=id~=missing}
end}
check(LL:InitializeItemDB(),LL.itemDBError)
local byID={}
for _,record in ipairs(LL.ItemDB.tokenRewards) do
    if isToken(record.tokenID) then
        check(not byID[record.tokenID],'one active catalog entry per tier token')
        byID[record.tokenID]=record
    end
end
local masks={274,69,1192}
local rewardOwner={}
for _,firstID in ipairs({40610,45632}) do
for id=firstID,firstID+29 do
    local record=byID[id]
    check(record,'tier catalog entry '..id)
    check(#record.rewards>0,'tier reward list '..id)
    eq(LL.ItemClassMasks[id],masks[(id-firstID)%3+1],'native class family '..id)
    for _,reward in ipairs(record.rewards) do
        check(not rewardOwner[reward],'different tier variants must retain distinct reward items '..reward)
        rewardOwner[reward]=id
    end
    for _,classID in ipairs({12,15}) do
        local token=LL:TokenInfo({id=id,classID=classID,equipLoc='INVTYPE_NON_EQUIP_IGNORE'})
        check(token and #token.rewards==#record.rewards,'standalone token lookup '..id..'/'..classID)
    end
    local token=assert(LL:TokenInfo({id=id,classID=15,equipLoc='INVTYPE_NON_EQUIP_IGNORE'}))
    local groups=LL:TokenClassSummary(token)
    eq(#groups,(id-firstID)%3==2 and 4 or 3,'native class-set group count '..id)
    local covered=0
    for _,group in ipairs(groups) do
        check(group.class~='UNKNOWN','tier class is resolved '..id)
        covered=covered+#group.ids
    end
    eq(covered,#record.rewards,'class summary retains every reward '..id)
end
end
local warbound={verifiedWarbound=true,isBound=true,count=1}
local function decide(id)
    LL:Invalidate();LL:InvalidateTokenCache()
    return assert(LL:Evaluate('item:'..id,warbound))
end
local function render(result)
    local tip={lines={}}
    function tip:AddLine(text) self.lines[#self.lines+1]=text end
    function tip:AddDoubleLine(left,right) self.lines[#self.lines+1]=left..' | '..right end
    LL:AppendRecommendationTooltip(tip,result)
    return table.concat(tip.lines,'\n')
end
for _,id in ipairs({45642,45657,45644,45648,45647,45638,45634,45659,45661,
    40610,40611,40612,40637,40638,40639}) do
    missing,unknown=nil,nil
    local allCollected=decide(id)
    check(allCollected.tokenInfo,'reported token reaches recommendation '..id)
    eq(allCollected.action,'V','collected reported token can be sold '..id)
    check(render(allCollected):find('Class sets',1,true),'reported tooltip shows class sets '..id)
    local wantedClass=LL.ItemClassMasks[id]==274 and 'PALADIN'
        or (LL.ItemClassMasks[id]==69 and 'HUNTER' or 'DRUID')
    for _,reward in ipairs(allCollected.tokenInfo.rewards) do
        if LL:TokenRewardPermitsClass(allCollected.tokenInfo,reward,wantedClass)==true then
            missing=reward;break
        end
    end
    check(missing,'a played class has a mapped reward '..id)
    local uncollected=decide(id)
    eq(uncollected.action,'T','known missing reported reward is retained '..id)
    eq(uncollected.transmogRecipient.rewardID,missing,'recipient uses the mapped missing reward '..id)
    check(render(uncollected):find('Class sets',1,true),'missing reported reward keeps class-set tooltip '..id)
    unknown=missing
    eq(decide(id).action,'V','unknown appearance does not become a missing reward '..id)
end
-- Keep a missing appearance for later, but do not claim a low-level character
-- can realize its opening value immediately.
tokenRequiredLevel=30
local facts={id=40612,link='item:40612'}
local token=assert(LL:TokenInfo({id=40612,classID=15,equipLoc=''}))
local reward=token.rewards[1]
playerLevel=29
local cost=LL:TokenRedemptionCost(facts,token,reward,true,'Main-Realm')
check(not cost.available and cost.reason:find('level 30',1,true),'native use-level blocks a low-level opener')
playerLevel=30
check(LL:TokenRedemptionCost(facts,token,reward,true,'Main-Realm').available,'native use-level boundary permits opening')
LL.db.characters['Hunter-Realm'].level=29
check(not LL:TokenRedemptionCost(facts,token,reward,false,'Hunter-Realm').available,'native use-level also applies to offline alts')
LL.db.characters['Hunter-Realm'].level=nil
check(not LL:TokenRedemptionCost(facts,token,reward,false,'Hunter-Realm').available,'unknown alt level does not prove immediate opening')
token.rewardRequirements={[tostring(reward)]={minimumLevel=31}}
check(not LL:TokenRedemptionCost(facts,token,reward,true,'Main-Realm').available,'catalog requirements apply before the open-token return')
print('PASS: '..checks..' Wayward/Lost family catalog, class summaries and native tooltip/collection assertions')
