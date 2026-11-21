-- Reviewed bag vectors quote owned items; native APIs alone grant use.
local checks=0
local function check(ok,why) assert(ok,why); checks=checks+1 end
local function near(a,b,why) check(type(a)=='number' and math.abs(a-b)<1e-8,why) end
local function copy(x)
    if type(x)~='table' then return x end
    local y={} for k,v in pairs(x) do y[k]=copy(v) end return y
end
local function same(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for k,v in pairs(a) do if not same(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end
local function field(value)
    return {status=value~=nil and 'modeled' or 'unknown',value=value,confidence=0,evidenceScore=20,
        samples=0,sampleSizeKnown=false,modelConfidenceCap=0,inferenceBlocked=value==nil}
end
local owned,spell,usable,selected=1,12345,true,true
CreateFrame=function() return {RegisterEvent=function() end,SetScript=function() end} end
GetTime=function() return 100 end
time=GetTime
GetBuildInfo=function() return '12.1.5','70961' end
GetItemCount=function() return owned end
C_Item={GetItemSpell=function() return 'Open reagent bag',spell end,
    IsUsableItem=function() return usable,false end}
UseContainerItem=function() error('a quote must never open a bag') end
UseItemByName=function() error('a quote must never use an item') end
local r={recordID='reviewed-use:260537:source-unknown',studyID='source-bag:fixture',sourceKey='reference',
    source='Fixture published bag contents, epoch unknown',method='Use',inputItemID=260537,inputCount=1,expansionID=11,
    reviewedBacklogModel=true,useReferenceOnly=true,reviewedPublishedPrior={policy='source-model-field'},
    fieldSpecificEvidence=true,samples=0,sampleSizeKnown=false,referenceContextID='bag:fixture:unknown-epoch',
    sourceReportedCounters={casts=1,totalQuantity=87},sourceEpoch='unknown',
    namedOutputs={{name='BS Plans: Murder Row Fishhook',economicPolicy='unpriced',quantityUnknown=true}},materials={}}
for _,x in ipairs({{243599,59,{243599,243600}},{243602,20,{243602,243603}},{243605,7,{243605,243606}},{251285,1}}) do
    r.materials[#r.materials+1]={id=x[1],rankIDs=x[3],expectedQuantity=field(x[2]),dropChance=field(nil),minQuantity=field(nil),maxQuantity=field(nil)}
end
local raw=copy(r)
local LL={db={characters={Player={professions={},recipes={}},Alt={professions={Enchanting=true},recipes={}}},
    processingModes={C=2},otherConversionDataMode=1,rateProfile=3,rateProfileCharacter='Alt'},
    ItemDB={schemaVersion=1,version='reviewed-use-fixture',processing={r}}}
for _,file in ipairs({'Professions.lua','Database.lua','Observations.lua','ConversionEngine.lua'}) do
    assert(loadfile('LootLiquidator/'..file))('LL',LL)
end
LL.CharacterKey=function() return 'Player' end
LL.ProcessingMethodMode=function(self,letter) return self.db.processingModes[letter] or 2 end
LL.AltMethodEnabled=function(_,who) return who=='Player' and selected or who=='Alt' end
LL.EligibleDisenchant=function() return false end
LL.GetManualProfessionProfile=function() error('container has no simulated profession') end
LL.GetCachedOperationInfo=function() error('item use has no profession recipe') end
LL.GetOutputPrice=function(_,id)
    if id==243599 then return 10,'fixture' elseif id==243600 then return 50,'fixture' end
    if id==243602 or id==243603 then return 100,'fixture' end
    if id==243605 or id==243606 then return 1000,'fixture' end
    if id==251285 then return 5,'fixture' end
end
local facts={id=260537,classID=15,expansionID=11,count=1,context={},link='item:260537'}
local function quote()
    for _,q in ipairs(LL:ConversionOptions(facts)) do if q.name=='Use' then return q end end
end
local q=assert(quote())
check(q.available and q.character=='Current character','native use available only on current character')
check(q.recipeID==nil and q.profession==nil,'container has no profession or learned recipe')
near(q.value,9595,'owned bag materials use existing conservative rank-pool prices')
check(q.partial and q.yieldModel.namedOutputs[1].name=='BS Plans: Murder Row Fishhook','unpriced named extra retained and partial')
check(q.confidence==0 and q.samples==0,'zero confidence and zero empirical samples')
check(LL:BestConversion(facts).name=='Use','native-available bag value can be compared')
check(q.vendorSupplyCost==0,'600Moxie never charged as copper on an owned item')
check(same(raw,r),'quote leaves source material/cast provenance unchanged')
spell=nil
q=assert(quote()); check(not q.available and q.value and not LL:BestConversion(facts),'source alone does not grant Use')
spell=12345; usable=false
q=assert(quote()); check(not q.available and not LL:BestConversion(facts),'native unusable wins')
usable=true; owned=0
q=assert(quote()); check(not q.available and not LL:BestConversion(facts),'tooltip count cannot fabricate ownership')
owned=1; facts.count=0
q=assert(quote()); check(not q.available and q.inputShort,'zero stack remains unavailable')
facts.count=1
LL.db.source_reference_enabled=false
q=assert(quote()); check(not q.available and q.value==nil and q.yieldModel==nil,'disabled reference leaks no quantities')
LL.db.source_reference_enabled=true; LL.db.source_reference_weight=0
q=assert(quote()); check(not q.available and q.value==nil,'zero reference weight respected')
LL.db.source_reference_weight=10; LL.db.otherConversionDataMode=2
q=assert(quote()); check(not q.available and q.value==nil,'personal-only refuses reference bag')
LL.db.otherConversionDataMode=1; LL.db.processingModes.C=3
check(quote()==nil,'Off suppresses item use')
LL.db.processingModes.C=4; selected=false
q=assert(quote()); check(not q.available and not LL:BestConversion(facts),'manual alt cannot borrow current access')
selected=true; LL.db.processingModes.C=2
facts.expansionID=10
check(quote()==nil,'source expansion remains exact')
facts.expansionID=11
r.useReferenceOnly=false; LL:InitializeItemDB(); check(quote()==nil,'unreviewed source does not create operation')
r.useReferenceOnly=true; LL:InitializeItemDB()
spell=nil; facts.context={bagID=0,slotID=1}
C_Container={GetContainerItemInfo=function() return {itemID=260537,hasLoot=true,stackCount=1,isLocked=false} end}
check(quote().available,'actual bag-slot openable flag supports no-spell container')
C_Container.GetContainerItemInfo=function() return {itemID=260537,hasLoot=true,stackCount=1,isLocked=true} end
check(not quote().available,'locked instance cannot be used')
C_Container.GetContainerItemInfo=function() return {itemID=260538,hasLoot=true,stackCount=1,isLocked=false} end
check(not quote().available,'stale bag identity cannot grant use')
C_Container=nil; facts.context={hasLoot=true}; C_Item.GetItemSpell=nil; C_Item.IsUsableItem=nil
check(not quote().available,'unverified hasLoot hint is not native proof')
C_Item.GetItemSpell=function() return 'Known fixed use',12345 end
C_Item.IsUsableItem=function() return true,false end
LL.Conversions={[260538]={{method='Use',inputCount=1,outputID=243599,outputCount=2,confidence='documented'}}}
facts.id=260538; facts.link='item:260538'
local fixed=assert(LL:BestConversion(facts))
near(fixed.value,20,'documented fixed Use keeps direct output ratio')
check(fixed.available and fixed.recipeID==nil and fixed.yieldModel==nil,'fixed Use not forced into profession model')
print('REVIEWED USE CONTAINER: '..checks..' checks passed')
