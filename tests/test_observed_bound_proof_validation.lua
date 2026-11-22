-- Independent runtime checks: a narrow observed-bound provenance exception
-- cannot authorize ordinary, malformed, same-cohort or transformed conflicts.
local checks=0
local function check(value,message)assert(value,message);checks=checks+1 end
local function copy(value)
    if type(value)~='table'then return value end
    local out={}for key,child in pairs(value)do out[key]=copy(child)end return out
end
GetBuildInfo=function()return '12.1.5','70783','',120105 end
GetTime=function()return 100 end
local LL={db={},ItemDB={schemaVersion=1,processing={}}}
assert(loadfile('LootLiquidator/Database.lua'))('LL',LL)
assert(loadfile('LootLiquidator/ConversionEngine.lua'))('LL',LL)
LL:MigrateEvidenceSettings()
LL.GetOutputPrice=function()return 100 end
local meanID,boundID=string.rep('a',64),string.rep('b',64)
local function field(value)
    return {value=value,status='measured',confidence=80,samples=7,sampleSizeKnown=true}
end
local source={recordID='evidence:v3:Disenchant:41522:x1',studyID='audit',source='Independent fixture',
    sourceKey='itemdb',method='Disenchant',recipeID=13262,inputItemID=41522,inputCount=1,
    fieldSpecificEvidence=true,referenceConditions={},referenceContextID='audit',materials={{id=34054,
        expectedQuantity=field(3),dropChance=field(1),minQuantity=field(1),maxQuantity=field(2),
        observedBoundIndependence={version=1,field='maxQuantity',meanCohorts={meanID},boundCohorts={boundID}}}}}
source.materials[1].maxQuantity.basis='observed-sample'
local function valid(row)
    return LL:ValidateItemDB({schemaVersion=1,processing={row}})
end
check(valid(source),'A structurally valid disjoint measured-range exception is admitted')
local function rejected(change,message)
    local row=copy(source);local material=row.materials[1]
    change(row,material,material.observedBoundIndependence)
    local ok,accepted=pcall(valid,row)
    check(ok and accepted==false,message)
end
rejected(function(_,m)m.observedBoundIndependence=nil end,'Missing proof cannot bypass the ordinary contradiction')
rejected(function(_,m)m.samplingVariation=true end,'Two exception mechanisms cannot be combined')
for _,key in ipairs({'legacy','reference','imported'})do
    rejected(function(r)r.sourceKey=key end,'Only the typed V3 ItemDB path can carry this exception')
end
rejected(function(r)r.recordID='ordinary:source' end,'An ordinary source cannot forge the V3 scope')
rejected(function(r)r.fieldSpecificEvidence=false end,'Missing independent-field scope is rejected')
rejected(function(_,_,p)p.version=2 end,'Unknown proof version is rejected')
rejected(function(_,_,p)p.field='minQuantity' end,'Proof must name the actually violated bound')
rejected(function(_,_,p)p.allowConflict=true end,'Unknown proof switches are rejected')
rejected(function(_,_,p)p.meanCohorts={}end,'An empty mean cohort set proves nothing')
rejected(function(_,_,p)p.boundCohorts={}end,'An empty bound cohort set proves nothing')
rejected(function(_,_,p)p.meanCohorts={meanID,meanID}end,'Duplicate cohort IDs are rejected')
rejected(function(_,_,p)p.boundCohorts={meanID}end,'The same cohort must retain strict conflict validation')
rejected(function(_,_,p)p.boundCohorts={boundID,meanID}end,'Any cohort overlap invalidates independence')
rejected(function(_,_,p)p.meanCohorts={'not-a-digest'}end,'An untyped source label is not a cohort digest')
rejected(function(_,_,p)p.meanCohorts={string.rep('A',64)}end,'Noncanonical digest text is rejected')
rejected(function(_,_,p)p.meanCohorts={[1]=meanID,[3]=string.rep('c',64)}end,'Sparse provenance arrays are rejected')
rejected(function(_,_,p)p.meanCohorts.extra=meanID end,'Provenance arrays cannot carry hidden keys')
rejected(function(_,_,p)for i=1,257 do p.meanCohorts[i]=('%064x'):format(i)end end,'Oversized proof arrays are rejected')
for _,name in ipairs({'expectedQuantity','dropChance','maxQuantity'})do
    rejected(function(_,m)m[name].status='provisional'end,'Unmeasured fields cannot use the exception')
    rejected(function(_,m)m[name].samples=0 end,'Zero supporting samples cannot use the exception')
    rejected(function(_,m)m[name].sampleSizeKnown=false end,'Unknown sample size cannot use the exception')
end
rejected(function(_,m)m.maxQuantity.basis=nil end,'An untyped bound retains strict validation')
rejected(function(_,m)m.maxQuantity.basis='declared-hard-cap'end,'A declared cap retains strict validation')
rejected(function(_,m)m.maxQuantity.value=3 end,'A proof cannot attach when its stated conflict no longer exists')
rejected(function(_,m)m.dropChance.value=0 end,'Zero occurrence with positive mean is not exempted')
rejected(function(_,m)m.expectedQuantity.value=0 end,'Zero mean with positive occurrence is not exempted')
rejected(function(_,m,p)
    m.expectedQuantity.value=.5;m.minQuantity.value=2;m.minQuantity.basis='observed-sample';p.field='minQuantity'
end,'An observed lower-bound exception cannot bypass the intrinsic positive-unit minimum')

local function resolve(records)
    LL.ItemDB={schemaVersion=1,processing=records};check(LL:InitializeItemDB(),LL.itemDBError)
    return assert(LL:ComputeEvidenceModel({id=41522},{name='Disenchant',recipeID=13262,inputCount=1},nil,1,{}))
end
local model=resolve({source});local material=model.materials[1]
check(material.expectedQuantity==3 and material.chance==1 and material.minQuantity==1 and material.maxQuantity==2,
    'Recovered evidence retains its original mean, occurrence and sampled bounds')
check(material.observedBoundIndependence and not material.inconsistentFields,'Unchanged fusion retains narrow provenance')
check(LL:ValueProcessingModel(model,0,true,{id=41522})==300,'Recovered expectation remains priceable')
LL.ApplyGeneralProfessionModel=function(_,_,_,baseline)
    local out=copy(baseline);out.materials[1].expectedQuantity=4;out.materials[1].expectationTransformed=true;return out
end
model=resolve({source});material=model.materials[1]
check(material.expectedQuantity==4 and material.inconsistentFields and not material.observedBoundIndependence,
    'An expectation transform cannot inherit the original cross-cohort exception')
LL.ApplyGeneralProfessionModel=nil
local additional=copy(source)
additional.recordID='reference:other-mean';additional.studyID='other';additional.sourceKey='reference'
additional.fixedReference=true;additional.fieldSpecificEvidence=nil
additional.materials={{id=34054,expectedQuantity=field(5),dropChance={status='unknown',confidence=0},
    minQuantity={status='unknown',confidence=0},maxQuantity={status='unknown',confidence=0}}}
model=resolve({source,additional});material=model.materials[1]
check(material.expectedQuantity>3 and material.inconsistentFields and not material.observedBoundIndependence,
    'A changed blended mean cannot inherit one original contributor’s exception')
check(source.materials[1].expectedQuantity.value==3 and source.materials[1].maxQuantity.value==2,
    'Validation, fusion and transforms never rewrite the source receipt')
print('PASS: '..checks..' independent observed-bound proof scope, malformed marker, intrinsic contradiction and transform checks')
