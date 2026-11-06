-- D1b step 2 end to end: fixture evidence -> tools/evidence_to_baselines.py ->
-- tools/compile_itemdb.lua -> the addon's own database code.
-- Usage: lua5.1 tests/test_evidence_baselines.lua <compiled fixture ItemDB file>
local compiled=assert(arg[1],'pass the compiled fixture ItemDB file')
local LL={}
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
GetBuildInfo=function()return '12.1.5','123456','Oct 29 2026',120105 end
GetTime=function()return 100 end
assert(loadfile(compiled))('LootLiquidator',LL)
for _,file in ipairs({'ProfessionModels.lua','Database.lua','ConversionEngine.lua'}) do
    assert(loadfile('LootLiquidator/'..file))('LootLiquidator',LL)
end
assert(not LL.itemDBError,LL.itemDBError)
assert(LL:ValidateItemDB(LL.ItemDB))
local passed=0
local function ok(cond,label) assert(cond,label);passed=passed+1 end
local record
for _,r in ipairs(LL.ItemDB.processing) do
    if r.recordID=='evidence:Prospect:990001:x5' then record=r end
end
ok(record and record.sourceKey=='itemdb' and record.inputItemID==990001 and record.inputCount==5,'fixture record compiled')
ok(LL.ItemDB.inputs[990001] and LL.ItemDB.inputs[990001].method=='Prospect','input registered as prospectable')
-- The Python confidence port and the addon's LL:RateConfidence agree.
for _,m in ipairs(record.materials) do
    local f=m.dropChance
    ok(f.confidence==LL:RateConfidence(f.value*f.samples,f.samples),'confidence port matches for '..m.id)
end
-- Nothing else changed: the real database has no evidence records yet.
local count=0
for _,r in ipairs(LL.ItemDB.processing) do if r.recordID:match('^evidence:') then count=count+1 end end
ok(count==3,'only the three fixture records are evidence records')
local units,published
for _,r in ipairs(LL.ItemDB.processing) do
    if r.inputItemID==990004 then units=r elseif r.inputItemID==990005 then published=r end
end
ok(units and units.recipeID==13262 and units.expansionID==11 and units.inputRarity==3 and units.inputClassID==4,
    'units-only operation identity survives the compiler')
ok(units.referenceContextID=='fixture-maxspec-study' and type(units.referenceConditions)=='table',
    'source distribution context survives the compiler')
ok(units.materials[1].expectedQuantity.value==.629 and units.materials[1].expectedQuantity.observedSamples==1000
    and units.materials[1].dropChance.status=='unknown','compiled unit mean has real n and unknown occurrence probability')
ok(published and published.inputQualityRank==1 and published.materials[1].expectedQuantity.value==13
    and published.materials[1].expectedQuantity.samples==0 and published.materials[1].expectedQuantity.priorWeight==10,
    'published unknown-n mean preserves provisional prior separately')
ok(#published.materials==1 and #published.materials[1].rankIDs==2,'family expectation appears once with two alternative quality IDs')
-- The addon values it through its normal path (same stubs as test_itemdb_metrics).
LL.db={source_itemdb_enabled=true,source_itemdb_weight=100,source_personal_enabled=false,
    source_legacy_enabled=false,processingModes={M=1,P=1,S=1}}
LL:MigrateEvidenceSettings()
LL.CanUseConversion=function()return true,nil,'Tester - Realm'end
LL.ProfessionForMethod=function(_,m)return ({Mill='Inscription',Prospect='Jewelcrafting',Smelt='Mining'})[m]end
LL.ProcessingPlayerConditions=function()return {skill=100,effectiveSkill=100}end
LL.EligibleDisenchant=function()return false end
LL.GetOutputPrice=function()return 100 end
LL.ProfessionProgression=function()return {}end
local options=LL:ConversionOptions({id=990001,classID=7,count=20})
ok(#options==1 and options[1].name=='Prospect' and options[1].inputCount==5,'one Prospect option from the evidence')
local model=assert(options[1].yieldModel)
local byID={}
for _,m in ipairs(model.materials) do byID[m.id]=m end
ok(math.abs(byID[990101].chance-41/210)<1e-6 and math.abs(byID[990101].expectedQuantity-.27)<1e-9,
    'chance = weighted drops / weighted casts; average from counted quantities')
ok(byID[990102].chance==1 and byID[990102].expectedQuantity==3,'always-drop output')
ok(byID[990103] and byID[990103].expectedQuantity==nil,'guessed output keeps an unknown average (partial, not invented)')
ok(type(model.confidence)=='number' and model.confidence>0,'the option gets a confidence')
print('EVIDENCE BASELINES (Lua): '..passed..' passed, 0 failed')
