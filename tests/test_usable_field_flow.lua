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
local model=assert(LL:ComputeEvidenceModel({id=-1,expansionID=1,quality=3,classID=4},option,nil,1,{}))
local m=model.materials[1]
assert(m.derivedMean and math.abs(m.expectedQuantity-1/268)<1e-12,'derive supported expectation before choosing an anchor')
assert(LL:ValueProcessingModel(model,0,true)>0)
local source=LL._evidenceIndex['Disenchant:gear:1:3:armor'][1].materials[1]
assert(source.expectedQuantity.value==nil and source.expectedQuantity.status=='unknown','source field remains immutable')
local fish=assert(LL:ComputeEvidenceModel({id=199344,classID=7,expansionID=9},{name='Prospect',inputCount=5},nil,1,{}))
assert(fish.operationUnverified and LL:ValueProcessingModel(fish,0,true)>0,'known source means per input are usable without inventing a recipe batch')
for _,out in ipairs(fish.materials) do assert(out.chance==nil and out.minQuantity==nil,'unknown recipe batch cannot establish per-cast probability/range') end
local function field(v)return {value=v,status=v==nil and 'unknown' or 'measured',confidence=80}end
local function record(e,p,lo,hi)
    return {recordID='synthetic',sourceKey='itemdb',studyID='synthetic',source='synthetic',method='Prospect',
        inputItemID=1,inputCount=5,materials={{id=2,expectedQuantity=field(e),dropChance=field(p),minQuantity=field(lo),maxQuantity=field(hi)}}}
end
local function resolve(r)
    LL.ItemDB={schemaVersion=1,processing={r}};LL.LegacyDB=nil;assert(LL:InitializeItemDB())
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
assert(text:find('chance unavailable',1,true) and text:find('yield unavailable',1,true) and text:find('40',1,true),text)
assert(not text:find('range ?',1,true),'field unknowns have explicit labels')
print('PASS: supported probability/range anchors, source immutability, per-input references, zero/unknown and field-level tooltip reasons')
