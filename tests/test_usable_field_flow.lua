CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
GetBuildInfo=function()return '12.1.5','123456','',120105 end
GetTime=function()return 100 end
local LL={}
for _,name in ipairs({'ItemDBRuntime.lua','ProfessionModels.lua','Database.lua','ConversionEngine.lua','Badges.lua'}) do
    assert(loadfile('LootLiquidator/'..name))('LootLiquidator',LL)
end
LL.db={tooltipDetail=3,source_legacy_enabled=false,source_personal_enabled=false,source_imported_enabled=false}
LL.GetOutputPrice=function()return 100 end
LL.MarkupColor=function()return ''end
LL.Money=function(_,n)return tostring(n)..' copper'end
LL.ProfessionProgression=function()return {}end
assert(LL:InitializeItemDB())
local option={name='Disenchant',inputCount=1,recipeID=13262}
local function copy(value)
    if type(value)~='table' then return value end
    local result={};for key,item in pairs(value) do result[key]=copy(item) end
    return result
end
local function same(actual,expected)
    if type(actual)~='table' or type(expected)~='table' then return actual==expected end
    for key,item in pairs(actual) do if not same(item,expected[key]) then return false end end
    for key in pairs(expected) do if actual[key]==nil then return false end end
    return true
end
local sourceRecord
for _,candidate in ipairs(LL._evidenceIndex['Disenchant:gear:1:3:armor']) do
    if candidate.recordID=='evidence:v3:Disenchant:gear:1:3:armor:x1' then sourceRecord=candidate;break end
end
assert(sourceRecord,'the shipped occurrence-only category study is present')
local sourceBefore=copy(sourceRecord)
local model=assert(LL:ComputeEvidenceModel({id=-1,expansionID=1,quality=3,classID=4},option,nil,1,{}))
local m=model.materials[1]
assert(math.abs(m.chance-1/268)<1e-12 and m.expectedQuantity==nil,
    'one observed hit in the shipped study gives a chance, not a supported unit count')
assert(LL:ValueProcessingModel(model,0,true)==nil)
local source=sourceRecord.materials[1]
assert(source.id==m.id and same(sourceRecord,sourceBefore),'evaluation preserves every source field')
assert(source.expectedQuantity.value==nil and source.expectedQuantity.status=='unknown','source field remains immutable')
local fish=assert(LL:ComputeEvidenceModel({id=199344,classID=7,expansionID=9},{name='Prospect',inputCount=5},nil,1,{}))
assert(fish.operationUnverified and LL:ValueProcessingModel(fish,0,true)>0,'known source means per input are usable without inventing a recipe batch')
for _,out in ipairs(fish.materials) do assert(out.chance==nil and out.minQuantity==nil,'unknown recipe batch cannot establish per-cast probability/range') end
local function field(v)return {value=v,status=v==nil and 'unknown' or 'measured',confidence=80}end
local function record(e,p,lo,hi)
    return {recordID='synthetic',sourceKey='itemdb',studyID='synthetic',source='synthetic',method='Prospect',
        inputItemID=1,inputCount=5,materials={{id=2,expectedQuantity=field(e),dropChance=field(p),minQuantity=field(lo),maxQuantity=field(hi)}}}
end
local function resolve(r,other)
    LL.ItemDB={schemaVersion=1,processing={r,other}};LL.LegacyDB=nil;assert(LL:InitializeItemDB())
    return LL:ComputeEvidenceModel({id=1},{name='Prospect',inputCount=5},nil,1,{})
end
model=assert(resolve(record(nil,.24,1,1)))
assert(math.abs(model.materials[1].expectedQuantity-.24)<1e-12 and math.abs(LL:ValueProcessingModel(model,0,true)-4.8)<1e-12,'P times yield once, divided by batch once')
model=assert(resolve(record(nil,0,1,1)))
assert(model.materials[1].expectedQuantity==0 and LL:ValueProcessingModel(model,0,true)==0,'supported zero is not unknown')
model=assert(resolve(record(2,nil,nil,nil)))
assert(LL:ValueProcessingModel(model,0,true)==40 and model.materials[1].chance==nil)
local tip={lines={}};function tip:AddLine(t)self.lines[#self.lines+1]=t end
function tip:AddDoubleLine(a,b)self.lines[#self.lines+1]=a..' | '..b end
LL:AppendRecommendationTooltip(tip,{action='P',count=5,facts={id=1,classID=7},conversionOptions={{name='Prospect',letter='P',value=40,yieldModel=model}}})
local text=table.concat(tip.lines,'\n')
assert(not text:find('chance unavailable',1,true) and not text:find('yield unavailable',1,true) and text:find('40',1,true),text)
assert(not text:find('range ?',1,true),'field unknowns have explicit labels')

local independent=record(2,.5,2,6)
independent.fieldSpecificEvidence=true
local rates=independent.materials[1]
rates.dropChance.samples=10
rates.expectedQuantity.samples=100
rates.expectedQuantity.independentConfidence=true
model=assert(resolve(independent))
m=model.materials[1]
assert(m.chanceConfidence==LL:RateConfidence(5,10) and m.confidence==80,
    'drop counts do not cap confidence in an independently measured mean')
LL.db.showMaterialConfidence=true
tip.lines={}
LL:AppendRecommendationTooltip(tip,{action='P',count=5,facts={id=1,classID=7},
    conversionOptions={{name='Prospect',letter='P',value=40,yieldModel=model}}})
text=table.concat(tip.lines,'\n')
assert(not text:find('quantity support',1,true) and text:find('50%',1,true) and text:find('40',1,true),
    'compact row preserves occurrence and price without per-field confidence clutter')
assert(m.chanceConfidence==LL:RateConfidence(5,10) and m.confidence==80,'presentation preserves separate confidence fields')

local separateCasts=record(.228,.229,1,1)
separateCasts.recordID='evidence:v3:Prospect:1:x5'
separateCasts.fieldSpecificEvidence=true
local observations=separateCasts.materials[1]
observations.dropChance.samples=4000
observations.dropChance.sampleSizeKnown=true
observations.expectedQuantity.samples=4040
observations.expectedQuantity.sampleSizeKnown=true
observations.samplingVariation=true
model=assert(resolve(separateCasts))
m=model.materials[1]
assert(math.abs(m.chance-.229)<1e-12 and math.abs(m.expectedQuantity-.228)<1e-12
    and m.samplingVariation and not m.inconsistentFields,'a small sampling gap retains both estimates')
assert(math.abs(LL:ValueProcessingModel(model,0,true)-4.56)<1e-12,'valuation uses the independently measured mean')
observations.samplingVariation=nil
assert(not LL:ValidateItemDB(LL.ItemDB),'an unmarked same-source mismatch still fails validation')
observations.samplingVariation=true
observations.expectedQuantity.value=.19
assert(not LL:ValidateItemDB(LL.ItemDB),'a mark cannot excuse a larger contradiction')

rates.dropChance={status='unknown',confidence=0,inferenceBlocked=true}
rates.heldDropChance={value=.25,status='measured',confidence=60,samples=20}
model=assert(resolve(independent))
assert(model.materials[1].chance==nil and LL:ValueProcessingModel(model,0,true)==40,
    'the measured mean can be valued without inventing chance from the range')
LL.db.showResearchDetails=true
tip.lines={}
LL:AppendRecommendationTooltip(tip,{action='P',count=5,facts={id=1,classID=7},
    conversionOptions={{name='Prospect',letter='P',value=40,yieldModel=model}}})
text=table.concat(tip.lines,'\n')
assert(not text:find('Conflicting source chance:',1,true)
    and text:find('50% |T134400:14:14:0:0|t Material 2 [2-6]',1,true),
    'the known mean/range yields only a canonical display estimate while rejected raw source chance stays held')
assert(model.materials[1].chance==nil and rates.heldDropChance.value==.25,'renderer cannot restore a held occurrence')
LL.db.showResearchDetails=false
rates.heldDropChance=nil

rates.dropChance={value=.5,status='measured',confidence=60,samples=20}
rates.expectedQuantity={status='unknown',confidence=0,inferenceBlocked=true}
model=assert(resolve(independent))
assert(model.materials[1].chance==.5 and model.materials[1].expectedQuantity==nil
    and LL:ValueProcessingModel(model,0,true)==nil,'occurrence-only evidence remains visible without a gold figure')

local rangeOnly=record(nil,nil,2,nil)
rangeOnly.fieldSpecificEvidence=true
model=assert(resolve(rangeOnly))
assert(model.materials[1].minQuantity==2 and model.materials[1].maxQuantity==nil
    and LL:ValueProcessingModel(model,0,true)==nil,'a single observed bound remains usable without a gold figure')

local exact=record(2,.5,2,6)
exact.fieldSpecificEvidence=true
exact.materials[1].expectedQuantity.samples=10
local larger=record(15,.9,1,20)
larger.recordID='larger';larger.studyID='larger'
larger.fieldSpecificEvidence=true;larger.inputCount=20
larger.materials[1].expectedQuantity.samples=400
model=assert(resolve(larger,exact))
assert(model.materials[1].chance==.5 and model.materials[1].expectedQuantity==2,
    'an exact batch takes precedence over a stronger different-batch distribution')
print('PASS: supported probability/range anchors, source immutability, per-input references, zero/unknown and field-level tooltip reasons')
