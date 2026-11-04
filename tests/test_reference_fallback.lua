local LL={}
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
GetBuildInfo=function()return '12.1.5','123456','',120105 end
GetTime=function()return 100 end
for _,name in ipairs({'ItemDBRuntime.lua','ProfessionModels.lua','Database.lua','ConversionEngine.lua','Badges.lua'}) do
    assert(loadfile('LootLiquidator/'..name))('LootLiquidator',LL)
end
LL.db={tooltipDetail=3,showAverageQuantity=true,source_legacy_enabled=false,
    source_personal_enabled=false,source_imported_enabled=false}
LL:MigrateEvidenceSettings()
assert(LL:InitializeItemDB(),LL.itemDBError)
LL.GetOutputPrice=function()return 100 end -- synthetic copper prices
LL.ProcessingPlayerConditions=function()return {}end
LL.MarkupColor=function()return ''end
LL.Money=function(_,n)return tostring(n)..' copper'end
LL.ProfessionProgression=function()return {}end
local function resolve(id,expansion)
    return LL:ResolveEvidenceModel({id=id,classID=7,expansionID=expansion},
        {name='Mill',inputCount=5},nil,1)
end
-- This Legion herb had no source record in main despite stored TSM rates.
local herb=assert(resolve(124101,6))
assert(herb.referenceFallback and herb.provisional)
assert(LL:ValueProcessingModel(herb,0,true)>0)
LL:SetEvidenceSource('reference',false)
assert(not resolve(124101,6),'toggle must invalidate the cached fallback lookup')
LL:SetEvidenceSource('reference',true,0)
assert(not resolve(124101,6),'zero weight disables fallback')
LL:SetEvidenceSource('reference',true,10)
assert(resolve(124101,6),'restoring preference makes evidence usable again')
-- Real saved formulas, including zero-cache Tin rows, become base estimates.
local option={name='Prospect',inputCount=5}
LL:SetEvidenceSource('itemdb',false)
local thorium=assert(LL:ResolveEvidenceModel({id=237366,classID=7,expansionID=11},option,nil,1))
local value=LL:ValueProcessingModel(thorium,0,true)
assert(math.abs(value-50.8)<1e-9,'six calculator constants, no saved Resourcefulness bonus or cached zeros')
assert(#thorium.materials==7 and thorium.hasConditionalReferences,'unlock-only Diamond is informational and excluded from the total')
local conditional
for _,m in ipairs(thorium.materials)do if m.conditionalExpectedQuantity then conditional=m end end
assert(conditional and conditional.expectedQuantity==nil and math.abs(conditional.conditionalExpectedQuantity-.22)<1e-12)
LL.db.showResearchDetails=true -- This fixture inspects full fallback and conditional-source explanations.
local tip={lines={}}
function tip:AddLine(s)self.lines[#self.lines+1]=s end
function tip:AddDoubleLine(a,b)self.lines[#self.lines+1]=a..' | '..b end
LL:AppendRecommendationTooltip(tip,{action='P',count=5,facts={id=237366,classID=7},
    conversionOptions={{name='Prospect',letter='P',available=true,value=value,yieldModel=thorium}}})
local text=table.concat(tip.lines,'\n')
assert(text:find('0.150',1,true) and text:find('1.140',1,true),'calculator quantities reach actual formatter')
assert(text:find('Reference fallback',1,true),'provisional reference is labeled')
assert(text:find('conditional',1,true) and text:find('excluded from current value',1,true),'known conditional values remain visible without inventing eligibility')
LL:SetEvidenceSource('itemdb',true)
local primary=assert(LL:ResolveEvidenceModel({id=237366,classID=7,expansionID=11},option,nil,1))
assert(LL:ValueProcessingModel(primary,0,true)==52,'existing usable research is not replaced or added twice')
-- Cobalt's six impossible E=2.5 common-gem means are not blindly restored.
local cobalt
for _,r in ipairs(LL.ItemDB.processing) do if r.recordID=='reference:Prospect:36909:itemtsm' then cobalt=r end end
assert(cobalt and cobalt.materials[1].referenceOriginal.expectedQuantity==2.5)
assert(cobalt.materials[1].expectedQuantity.value==.235)
assert(cobalt.materials[1].expectedQuantity.status=='modeled')
local qualityPool
for _,r in ipairs(LL.ItemDB.processing) do
    if r.recordID=='reference:rank-pool:Mill:191462' then qualityPool=r end
end
assert(qualityPool and #qualityPool.materials==1)
local pooled=qualityPool.materials[1]
assert(#pooled.rankIDs==3 and math.abs(pooled.expectedQuantity.value-3.5)<1e-12,
    'explicit quality alternatives provide one conservative pool, not three additive yields')
assert(pooled.dropChance.value==nil and #pooled.referenceVariants==3)
-- Fill a primary field gap without diluting its existing expectation.
local function field(v)return {value=v,status=v==nil and 'unknown' or 'measured',confidence=80}end
local function record(key,e,p)
    return {recordID=key,sourceKey=key,studyID=key,source=key,method='Prospect',inputItemID=1,
        inputCount=5,fixedReference=true,fallbackOnly=key=='reference',materials={{id=2,
        expectedQuantity=field(e),dropChance=field(p),minQuantity=field(nil),maxQuantity=field(nil)}}}
end
LL.ItemDB={schemaVersion=1,processing={record('itemdb',3,nil),record('reference',9,.4)}}
LL.LegacyDB=nil;assert(LL:InitializeItemDB())
local model=assert(LL:ComputeEvidenceModel({id=1},option,nil,1,{}))
assert(model.materials[1].expectedQuantity==3,'reference must not change a supported primary mean')
assert(math.abs(model.materials[1].chance-.4)<1e-12,'reference fills the missing occurrence field')
assert(not LL:ComputeEvidenceModel({id=1},option,nil,2,{}),'personal-only excludes reference')
-- A family mean already prices all unknown-rank alternatives once.
LL.ItemDB.processing[1].materials[1].rankIDs={2,3}
LL.ItemDB.processing[2].materials[1].id=3
assert(LL:InitializeItemDB())
model=assert(LL:ComputeEvidenceModel({id=1},option,nil,1,{}))
assert(#model.materials==1 and model.materials[1].expectedQuantity==3)
LL.ItemDB.processing[1].materials[1].rankIDs=nil
LL.ItemDB.processing[2].materials[1].rankIDs={2,3}
assert(LL:InitializeItemDB())
model=assert(LL:ComputeEvidenceModel({id=1},option,nil,1,{}))
assert(#model.materials==1,'a fallback family cannot be added over an already priced exact rank')
LL.ItemDB.processing[1].materials[1].expectedQuantity=field(nil)
LL.ItemDB.processing[1].materials[1].dropChance=field(.25)
assert(LL:InitializeItemDB())
model=assert(LL:ComputeEvidenceModel({id=1},option,nil,1,{}))
assert(#model.materials==1 and model.materials[1].rankIDs and math.abs(model.materials[1].expectedQuantity-9)<1e-12)
assert(model.materials[1].rankReferences[1].chance==.25,
    'a usable family mean must retain separately labeled exact-rank occurrence data, without treating it as pooled P')
print('PASS: archived references and live-read calculator constants reach valuation/tooltip, source gates and primary/family isolation')
