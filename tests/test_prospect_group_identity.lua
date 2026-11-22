-- Synthetic identities/prices test source grouping, not game drop claims.
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
GetBuildInfo=function()return '12.1.5','70961','',120105 end
GetTime=function()return 100 end
local LL={db={source_itemdb_enabled=true,source_reference_enabled=true,
    source_personal_enabled=false,source_imported_enabled=false,source_legacy_enabled=false}}
for _,file in ipairs({'Database.lua','ConversionEngine.lua'})do
    assert(loadfile('LootLiquidator/'..file))('LL',LL)
end
local function copy(t)if type(t)~='table'then return t end local o={}for k,v in pairs(t)do o[k]=copy(v)end return o end
local function field(v,c,status,n)return {value=v,confidence=c or 20,status=status or 'modeled',
    samples=n or 0,sampleSizeKnown=(n or 0)>0}end
local function output(id,ids,mean,p,confidence,status,samples)
    return {id=id,rankIDs=ids,expectedQuantity=field(mean,confidence,status,samples),
        dropChance=field(p,confidence,status,samples),minQuantity=field(1,confidence,status,samples),
        maxQuantity=field(3,confidence,status,samples)}
end
local function record(id,source,material,context)
    return {recordID=id,studyID=id,sourceKey=source,source=id,method='Prospect',inputItemID=5,inputCount=5,
        referenceContextID=context or 'identified-gems',fixedReference=true,materials={material}}
end
local group=record('a-strong-mixed-group','itemdb',output(11,{11,21},100,.9,100,'measured',100000),'group-context')
group.materials[1].minQuantity.value=100;group.materials[1].maxQuantity.value=200
local red=record('b-red-family','itemdb',output(11,{11,12},.4,.2,20))
local blue=record('c-blue-family','reference',output(21,{21,22},.8,.4,30))
blue.fallbackOnly=true
local native={items={[11]={name='Red',qualityFamilyID=1,qualityRank=1},[12]={name='Red',qualityFamilyID=1,qualityRank=2},
    [21]={name='Blue',qualityFamilyID=2,qualityRank=1},[22]={name='Blue',qualityFamilyID=2,qualityRank=2}}}
local prices={[11]=100,[12]=200,[21]=300,[22]=400}
LL.GetOutputPrice=function(_,id)return prices[id]end
local function resolve(records,method)
    LL.ItemDB={schemaVersion=1,professionProfiles=copy(native),processing=records}
    assert(LL:InitializeItemDB(),LL.itemDBError)
    return LL:ComputeEvidenceModel({id=5,classID=7,expansionID=9},
        {name=method or 'Prospect',inputCount=5},nil,1,{inputQuality=1})
end
local records={copy(group),copy(red),copy(blue)}
local model=assert(resolve(records))
assert(model.referenceContextID=='identified-gems','An enormous group count cannot win individual-gem anchor selection')
assert(#model.materials==2 and #model.groupedSourceQuantities==1)
assert(model.materials[1].id==11 and model.materials[1].expectedQuantity==.4)
assert(model.materials[2].id==21 and math.abs(model.materials[2].expectedQuantity-.8)<1e-12)
assert(model.materials[1].chance==.2 and model.materials[2].chance==.4,
    'Group occurrence, range and measured samples cannot leak into individual baseline fields')
assert(math.abs(LL:ValueProcessingModel(model,0,true)-56)<1e-9,'Value uses existing individual gem estimates once each')
local provenance=model.groupedSourceQuantities[1]
assert(provenance.expectedQuantity==100 and provenance.sourceExpectedQuantity==100
    and provenance.quantityBasis=='unallocated-gem-group-total' and provenance.status=='measured')
assert(provenance.recordID=='a-strong-mixed-group'and #provenance.outputItemIDs==2)
assert(records[1].materials[1].rankIDs[2]==21 and records[1].materials[1].expectedQuantity.value==100,
    'Source group observations remain immutable')

LL.db.source_reference_enabled=false
model=assert(resolve({copy(group),copy(red),copy(blue)}))
assert(#model.materials==2 and model.materials[2].id==21 and model.materials[2].expectedQuantity==nil
    and model.materials[2].chance==nil and model.materials[2].groupReference,
    'Disabling a fallback keeps a genuine gem identity visible without allocating the group total')
assert(math.abs(LL:ValueProcessingModel(model,0,true)-8)<1e-9 and model.partialPrice,
    'An uncovered gem contributes no invented value')

LL.db.source_reference_enabled=true
local exact=record('b-blue-exact','itemdb',output(21,nil,.3,.2,60))
model=assert(resolve({copy(group),copy(red),copy(blue),exact}))
assert(#model.materials==2 and model.materials[2].id==21 and model.materials[2].rankIDs==nil
    and math.abs(model.materials[2].expectedQuantity-.3)<1e-12,
    'An existing individual output is not duplicated by a pooled fallback')
assert(math.abs(LL:ValueProcessingModel(model,0,true)-26)<1e-9)

model=assert(resolve({copy(group)}))
assert(#model.materials==2 and model.unknownOutputs and model.confidenceUnscored)
for _,m in ipairs(model.materials)do
    assert(m.expectedQuantity==nil and m.chance==nil and m.minQuantity==nil and m.maxQuantity==nil)
end
assert(LL:ValueProcessingModel(model,0,true)==nil,'A group-only source has identities, not individual gem values')

local familyOnly=assert(resolve({copy(red)}))
assert(#familyOnly.materials==1 and not familyOnly.groupedSourceQuantities
    and familyOnly.materials[1].rankIDs[2]==12,'A genuine native quality family stays pooled')
local mill=copy(group);mill.method='Mill'
model=assert(resolve({mill},'Mill'))
assert(not model.groupedSourceQuantities and model.materials[1].expectedQuantity==100,
    'The Prospect correction does not change unrelated processing methods')
LL.db.source_itemdb_enabled=false;LL.db.source_reference_enabled=false
assert(resolve({copy(group),copy(red),copy(blue)})==nil,'Disabled group sources cannot create output rows')
print('PASS: mixed gem totals remain group provenance; independent native gem baselines price once, source/grade coverage and gates preserved')
