-- Keeping a known missing appearance is separate from paying an exchange now.
-- Native 52026 relationships exercise the actual recipient/decision/tooltip path.
local checks=0
local function check(value,message) assert(value,message);checks=checks+1 end
local function eq(actual,expected,message)
    check(actual==expected,(message or '')..': '..tostring(actual)..' ~= '..tostring(expected))
end
local function clone(value)
    if type(value)~='table' then return value end
    local copy={} for key,v in pairs(value) do copy[key]=clone(v) end return copy
end
CreateFrame=function() return {RegisterEvent=function()end,SetScript=function()end} end
GetBuildInfo=function() return '12.1.5','70783','',120105 end
GetTime=function() return 100 end
time=function() return 1000 end
UnitClass=function() return 'Druid','DRUID' end
UnitLevel=function() return 90 end
GetMoney=function() return 0 end
SlashCmdList={};WOW_PROJECT_ID=1;WOW_PROJECT_MAINLINE=1
wipe=function(t) for key in pairs(t) do t[key]=nil end return t end
local LL={db={}}
for _,name in ipairs({'ItemDBRuntime.lua','Core.lua','Professions.lua','ProfessionModels.lua',
    'Database.lua','ConversionEngine.lua','Tokens.lua','Badges.lua'}) do
    assert(loadfile('LootLiquidator/'..name))('LootLiquidator',LL)
end
LL.db={enabled=true,tooltipDetail=3,includeVerifiedAlts=true,showSoulboundVendorBadge=true,
    processingModes={},characters={
        ['Main-Realm']={class='DRUID',level=90,professions={}},
        ['Hunter-Realm']={class='HUNTER',level=80,professions={}}}}
LL.CharacterKey=function() return 'Main-Realm' end
LL.Price=function() return nil end
LL.ReportMissing=function() end
LL.ProfessionProgression=function() return {} end
LL.MarkupColor=function() return '' end
LL.Money=function(_,value) return tostring(value)..' copper' end
LL.GetOutputPrice=function() return 20000 end
local tokenRecord
for _,record in ipairs(LL.ItemDB.tokenRewards) do if record.tokenID==52026 then tokenRecord=record end end
check(tokenRecord and tokenRecord.kind=='exchange','native Protector Mark exchange is shipped')
check(tokenRecord.costsComplete and #tokenRecord.rewards==30,'native class rewards and costs are retained')
local rewards={}
for _,id in ipairs(tokenRecord.rewards) do rewards[id]=true end
local function itemID(value) return tonumber(value) or tonumber(tostring(value):match('item:(%d+)')) end
local missing,unknown=51150,nil -- Native hunter head reward; other known rewards are already collected.
C_Item={GetItemInfo=function(value)
    local id=itemID(value)
    if not id then return end
    local token=id==52026
    return token and "Protector's Mark of Sanctification" or ('Equipment '..id),
        'item:'..id,4,200,1,'Armor','Mail',1,token and '' or 'INVTYPE_HEAD',0,
        token and 50000 or 100000,token and 15 or 4,3,1,2
end,GetItemInfoInstant=function(value)
    local id=itemID(value);local token=id==52026
    return id,'Armor','Mail',token and '' or 'INVTYPE_HEAD',0,token and 15 or 4,3
end,GetItemCount=function() return 0 end,RequestLoadItemDataByID=function()end}
C_CurrencyInfo={GetCurrencyInfo=function() return {quantity=0} end}
-- The collection resolver's API behavior has its own focused regressions.
-- Keep this fixture focused on collection priority versus redemption costs.
LL.AppearanceCollectionState=function(_,link)
    local id=itemID(link)
    if id==unknown then return nil end
    return id~=missing
end
check(LL:InitializeItemDB(),LL.itemDBError)
local warbound={verifiedWarbound=true,isBound=true,count=1}
local function decide(context)
    LL:Invalidate()
    return assert(LL:Evaluate('item:52026',context or warbound))
end
local function render(result)
    local tip={lines={}}
    function tip:AddLine(text) self.lines[#self.lines+1]=text end
    function tip:AddDoubleLine(left,right) self.lines[#self.lines+1]=left..' | '..right end
    LL:AppendRecommendationTooltip(tip,result)
    return table.concat(tip.lines,'\n')
end
local result=decide()
eq(result.action,'T','known missing hunter appearance wins over token vendor price')
eq(result.transmogRecipient.name,'Hunter-Realm')
eq(result.transmogRecipient.rewardID,51150)
eq(result.transmogRecipient.current,false)
check(not result.tokenPiece.vendorAvailable,'the keep decision does not make the exchange immediately available')
check(not result.tokenPiece.cost.available,'unknown alt inventory remains unavailable for economics')
check(result.tokenPiece.cost.reason:find('Alt exchange inventory not verified',1,true),'economic diagnostic remains intact')
check(render(result):find(result.transmogRecipient.displayName,1,true),
    'actual tooltip names the collection recipient')
missing=nil
eq(decide().action,'V','a fully known played-class appearance does not create T')
missing=51150;unknown=51150
eq(decide().action,'V','unknown collection status is not a missing appearance')
unknown=nil;missing=51190
eq(decide().action,'V','missing shaman appearance does not count an unplayed class')
missing=51150
LL.db.includeVerifiedAlts=false
eq(decide().action,'V','Include alts off remains authoritative')
LL.db.includeVerifiedAlts=true
for _,options in ipairs({{T=false},{X=false},{all=false}}) do
    LL.db.characters['Hunter-Realm'].altMethods=options
    eq(decide().action,'V','explicit recipient exclusions are preserved')
end
LL.db.characters['Hunter-Realm'].altMethods=nil
LL.db.processingModes.T=3
eq(decide().action,'V','global collecting-off suppresses T')
LL.db.processingModes.T=nil
LL.db.processingModes.X=3
eq(decide().action,'V','global exchange-off remains authoritative')
LL.db.processingModes.X=nil
eq(decide({isSoulbound=true,count=1}).action,'V','soulbound token cannot use another class alt')
eq(decide({isBoundToAccount=true,isBound=true,count=1}).action,'V','unverified account-bound hint does not prove transfer')
LL.ItemClassMasks={[52026]=1}
eq(decide().action,'V','explicit token class mask excludes the hunter')
LL.ItemClassMasks=nil
local requirements=tokenRecord.rewardRequirements['51150']
tokenRecord.rewardRequirements['51150']={minimumLevel=81}
eq(decide().action,'V','an explicit unmet reward level still blocks the recipient')
tokenRecord.rewardRequirements['51150']={minimumLevel=30,unverified=true}
eq(decide().action,'V','unsupported character requirements do not become certified collection access')
tokenRecord.rewardRequirements['51150']=requirements
LL.db.characters['Hunter-Realm'].level=nil
eq(decide().action,'V','unknown alt level cannot satisfy an explicit reward level')
LL.db.characters['Hunter-Realm'].level=30
eq(decide().action,'T','exact minimum reward level is eligible')
LL.db.characters['Hunter-Realm'].level=80
local costsComplete=tokenRecord.costsComplete
tokenRecord.costsComplete=false
result=decide()
eq(result.action,'T','unknown total exchange costs do not make a known missing look disposable')
check(not result.tokenPiece.vendorAvailable and not result.tokenPiece.cost.known,
    'unknown exchange value remains informational despite collection priority')
tokenRecord.costsComplete=costsComplete
local token=assert(LL:TokenInfo(assert(LL:GetItemFacts('item:52026',warbound))))
token.chainCostUnknown=true
eq(LL:TokenAppearanceEligibility(token,51150,false,'Hunter-Realm'),true,
    'unknown extra chain costs are separate from a known final appearance')
check(not LL:TokenRedemptionCost({id=52026,count=1},token,51150,false,'Hunter-Realm').available,
    'chain costs remain unavailable for a current economic action')
token.chainCostUnknown=nil;token.candidateRewards=true
eq(LL:TokenAppearanceEligibility(token,51150,false,'Hunter-Realm'),false,
    'an unestablished reward relationship cannot certify a missing collection reward')
token.candidateRewards=nil
-- An explicit reward-class false must not fall through an `or` to a true
-- global/template query from another source.
local classQuery=LL.ItemPermitsClass
local rewardQuery=LL.TokenRewardPermitsClass
LL.TokenRewardPermitsClass=function() return false end
LL.ItemPermitsClass=function() return true end
eq(LL:TokenTransmogRecipient(assert(LL:GetItemFacts('item:52026',warbound)),token),nil,
    'explicit reward exclusion cannot be replaced by another permissive class result')
LL.ItemPermitsClass=classQuery;LL.TokenRewardPermitsClass=rewardQuery
eq(decide().action,'T','restoring eligibility restores the native missing-look recommendation')
-- Compact class-set rows must narrow only the reward list. Dropping the parent
-- catalog's masks, variants or requirements either hides useful recipients or
-- incorrectly certifies a recipient excluded by that same catalog.
local probe=clone(decide().tokenInfo)
probe.rewardLinks={['51150']='item:51150:exactvariant'}
probe.rewardRequirements['51150']={minimumLevel=30,unverified=true}
probe.candidateRewards=false
local probeDecision=decide()
probeDecision.tokenInfo=probe;probeDecision.transmogRecipient=nil;probeDecision.action='V'
local originalRewards=table.concat(probe.rewards,',')
local originalRecipient=LL.TokenTransmogRecipient
local rowSeen=0
LL.TokenTransmogRecipient=function(self,facts,subset)
    local selected=false
    for _,id in ipairs(subset.rewards or {}) do if id==51150 then selected=true end end
    local recipient=originalRecipient(self,facts,subset)
    if selected then
        rowSeen=rowSeen+1
        check(subset~=probe and subset.rewards~=probe.rewards,'class row receives a narrowed copy')
        eq(subset.rewardClassMasks,probe.rewardClassMasks,'class row preserves reward class masks')
        eq(subset.rewardRequirements,probe.rewardRequirements,'class row preserves character requirements')
        eq(subset.rewardLinks,probe.rewardLinks,'class row preserves exact reward variants')
        eq(subset.candidateRewards,probe.candidateRewards,'class row preserves reward relationship status')
        eq(recipient,nil,'class row cannot bypass an unverified character requirement')
    end
    return recipient
end
render(probeDecision)
check(rowSeen>0,'native hunter class row consults collection eligibility')
eq(table.concat(probe.rewards,','),originalRewards,'class rendering does not mutate the parent reward list')
probe.rewardRequirements['51150']={minimumLevel=30};probe.candidateRewards=true
rowSeen=0
render(probeDecision)
check(rowSeen>0,'candidate reward state reaches the actual class-row path')
eq(table.concat(probe.rewards,','),originalRewards,'candidate rendering retains all native parent rewards')
LL.TokenTransmogRecipient=originalRecipient
print('PASS: '..checks..' native token collection priority, cost separation, recipient and preference assertions')
